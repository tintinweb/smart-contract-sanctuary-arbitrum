// SPDX-License-Identifier: MIT

/**
 *
 * @title ArrngConsumer.sol. Use arrng
 *
 * @author arrng https://arrng.xyz/
 * v1.0.0
 *
 */

import {IArrngConsumer} from "./IArrngConsumer.sol";
import {IArrngController} from "./IArrngController.sol";

pragma solidity 0.8.19;

abstract contract ArrngConsumer is IArrngConsumer {
  IArrngController constant arrngController = 
    IArrngController(0x8888881FA4b02bd6A5628BB34463Cc2570888888);

  /**
   * @dev constructor
   */
  constructor() {}

  /**
   *
   * @dev fulfillRandomWords: Do something with the RNG
   *
   * @param requestId: unique ID for this request
   * @param randomWords: array of random integers requested
   *
   */
  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal virtual;

  /**
   *
   * @dev yarrrr: receive RNG
   *
   * @param skirmishID_: unique ID for this request
   * @param barrelONum_: array of random integers requested
   *
   */
  function yarrrr(
    uint256 skirmishID_,
    uint256[] calldata barrelONum_
  ) external payable {
    require(msg.sender == address(arrngController), "BelayThatOfficersOnly");
    fulfillRandomWords(skirmishID_, barrelONum_);
  }
}

// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngConsumer.sol. Use arrng
 *
 * @author arrng https://arrng.xyz/
 * v1.0.0
 *
 */

pragma solidity 0.8.19;

interface IArrngConsumer {
  /**
   *
   * @dev avast: receive RNG
   *
   * @param skirmishID_: unique ID for this request
   * @param barrelORum_: array of random integers requested
   *
   */
  function yarrrr(
    uint256 skirmishID_,
    uint256[] memory barrelORum_
  ) external payable;
}

// SPDX-License-Identifier: MIT

/**
 *
 * @title IArrngController.sol. Interface for the arrngController.
 *
 * @author arrng https://arrng.xyz/
 * v1.0.0
 *
 */

pragma solidity 0.8.19;

interface IArrngController {
  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomWords: request 1 to n uint256 integers
   * requestRandomWords is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomWords(
    uint256 numberOfNumbers_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you can
   * call it without explicitly declaring a refund address, with the
   * refund being paid to the tx.origin for this call.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestRandomNumbersInRange: request 1 to n integers within
   * a given range (e.g. 1 to 10,000)
   * requestRandomNumbersInRange is overloaded. In this instance you must
   * specify the refund address for unused native token.
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestRandomNumbersInRange(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_
  ) external payable returns (uint256 uniqueID_);

  /**
   *
   * @dev requestWithMethod: public method to allow calls specifying the
   * arrng method, allowing functionality to be extensible without
   * requiring a new controller contract
   *
   * @param numberOfNumbers_: the amount of numbers to request
   * @param minValue_: the min of the range
   * @param maxValue_: the max of the range
   * @param refundAddress_: the address for refund of native token
   *
   * @return uniqueID_ : unique ID for this request
   */
  function requestWithMethod(
    uint256 numberOfNumbers_,
    uint256 minValue_,
    uint256 maxValue_,
    address refundAddress_,
    uint32 method_
  ) external payable returns (uint256 uniqueID_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title DropFactory.sol - Core contract for metadrop NFT drop creation.
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice This contract performs the following roles:
 * - Storage of drop data that has been submitted to metadrop for approval.
 *   This information is held in hash format, and compared with sent data
 *   to create the drop.
 * - Drop creation. This factory will create the required NFT contracts for
 *   an approved drop using the approved confirmation.
 * - Platform Utilities. This contract holds core platform data accessed by other
 *   on-chain elements of the metadrop ecosystem. For example, VRF functionality.
 *
 */

pragma solidity 0.8.19;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {ArrngConsumer} from "@arrng/contracts/ArrngConsumer.sol";
import {IDropFactory} from "./IDropFactory.sol";
import {Ownable} from "../Global/OZ/Ownable.sol";
import {SafeERC20, IERC20} from "../Global/OZ/SafeERC20.sol";
import {INFTByMetadrop} from "../NFT/INFTByMetadrop.sol";
import {IPrimarySaleModule} from "../PrimarySaleModules/IPrimarySaleModule.sol";
import {IPrimaryVestingByMetadrop} from "../PrimaryVesting/IPrimaryVestingByMetadrop.sol";
import {IPublicMintByMetadrop} from "../PrimarySaleModules/PublicMint/IPublicMintByMetadrop.sol";
import {IListMintByMetadrop} from "../PrimarySaleModules/ListMint/IListMintByMetadrop.sol";
import {IAuctionByMetadrop} from "../PrimarySaleModules/Auction/IAuctionByMetadrop.sol";
import {IRoyaltyPaymentSplitterByMetadrop} from "../RoyaltyPaymentSplitter/IRoyaltyPaymentSplitterByMetadrop.sol";
import {AuthorityModel} from "../Global/AuthorityModel.sol";
import {IPausable} from "../Global/IPausable.sol";

/**
 *
 * @dev Inheritance details:
 *      IDropFactory            Interface definition for the metadrop drop factory
 *      Ownable                 OZ ownable implementation - provided for backwards compatibility
 *                              with any infra that assumes a project owner.
 *      AccessControl           OZ access control implementation - used for authority control
 *      VRFConsumerBaseV2       This contract will call chainlink VRF on behalf of deployed NFT
 *                              contracts, relaying the returned result to the NFT contract
 *
 */

contract DropFactory is
  IDropFactory,
  Ownable,
  AuthorityModel,
  VRFConsumerBaseV2,
  ArrngConsumer
{
  using Address for address;
  using Clones for address payable;
  using SafeERC20 for IERC20;

  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint32 public constant MAX_NUM_WORDS = 500;

  // The number of days that must have passed before the details for a drop held on chain can be deleted.
  uint32 public dropExpiryInDays;

  // Pause should not be allowed indefinitely
  uint8 public pauseCutOffInDays;

  // VRF mode
  // 0 = chainlink
  // 1 = aarng
  uint8 public vrfMode;

  // Address for all platform fee payments
  address private platformTreasury;

  // Metadrop trusted oracle address
  address public metadropOracleAddress;

  // Fee for drop submission (default is zero)
  uint256 public dropFeeETH;

  // The oracle signed message validity period:
  uint256 public messageValidityInMinutes = 15;

  // Chainlink config
  VRFCoordinatorV2Interface public immutable vrfCoordinatorInterface;
  uint64 public vrfSubscriptionId;
  bytes32 public vrfKeyHash;
  uint32 public vrfCallbackGasLimit;
  uint16 public vrfRequestConfirmations;
  uint32 public vrfNumWords;

  // Array of templates:
  // Note that this means that templates can be updated as the metadrop NFT evolves.
  // Using a new one will mean that all drops from that point forward will use the new contract template.
  // All deployed NFT contracts are NOT upgradeable and will continue to use the contract as deployed
  // At the time of drop.

  Template[] public contractTemplates;

  // Map the dropId to the Drop object
  //   struct DropApproval {
  //   DropStatus status;
  //   uint32 lastChangedDate;
  //   address dropOwnerAddress;
  //   bytes32 configHash;
  // }
  mapping(string => DropApproval) private dropDetailsByDropId;

  // Map to store deployed NFT addresses:
  mapping(address => bool) public deployedNFTContracts;

  // Mappings to store VRF request IDs:
  mapping(uint256 => address) public addressForChainlinkVRFRequestId;
  mapping(uint256 => address) public addressForArrngVRFRequestId;

  /** ====================================================================================================================
   *                                                    CONSTRUCTOR
   * =====================================================================================================================

  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_                                     The address that can add and remove user authority roles. Will
   *                                                        also be added as the first platform admin.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_                                 The address(es) for the platform admin(s)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param reviewAdmins_                                   The address(es) for the review admin(s)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_                               The address of the platform treasury. This will be used on
   *                                                        primary vesting for the platform share of funds and on the
   *                                                        royalty payment splitter for the platform share.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCoordinator_                                 The address of the VRF coordinator
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_             The VRF key hash to determine the gas channel to use for VRF calls (i.e. the max gas
   *                                you are willing to supply on the VRF call)
   *                                - Mainnet 200 gwei: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
   *                                - Goerli 150 gwei 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_      The subscription ID that chainlink tokens are consumed from for VRF calls
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_  The address of the metadrop oracle signer
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialTemplateAddresses_     An array of intiial template addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialTemplateDescriptions_  An array of initial template descriptions
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address superAdmin_,
    address[] memory platformAdmins_,
    address[] memory reviewAdmins_,
    address platformTreasury_,
    address vrfCoordinator_,
    bytes32 vrfKeyHash_,
    uint64 vrfSubscriptionId_,
    address metadropOracleAddress_,
    address payable[] memory initialTemplateAddresses_,
    string[] memory initialTemplateDescriptions_
  ) VRFConsumerBaseV2(vrfCoordinator_) {
    // The initial instance owner is set as the Ownable owner on all cloned contracts:
    if (superAdmin_ == address(0)) {
      _revert(SuperAdminCannotBeAddressZero.selector);
    }

    // superAdmin can grant and revoke all other roles. This address MUST be secured.
    // For the duration of this constructor only the super admin is the deployer.
    // This is so the deployer can set initial authorities.
    // We set to the configured super admin address at the end of the constructor.
    superAdmin = _msgSender();
    // Grant platform admin to the deployer for the duration of the constructor:
    grantPlatformAdmin(_msgSender());

    grantPlatformAdmin(superAdmin_);
    grantReviewAdmin(superAdmin_);

    for (uint256 i = 0; i < platformAdmins_.length; i++) {
      grantPlatformAdmin(platformAdmins_[i]);
    }

    for (uint256 i = 0; i < reviewAdmins_.length; i++) {
      grantReviewAdmin(reviewAdmins_[i]);
    }

    // Set platform treasury:
    if (platformTreasury_ == address(0)) {
      _revert(PlatformTreasuryCannotBeAddressZero.selector);
    }
    platformTreasury = platformTreasury_;

    // Set default chainlink VRF details
    if (vrfCoordinator_ == address(0)) {
      _revert(VRFCoordinatorCannotBeAddressZero.selector);
    }
    vrfCoordinatorInterface = VRFCoordinatorV2Interface(vrfCoordinator_);
    vrfKeyHash = vrfKeyHash_;
    vrfSubscriptionId = vrfSubscriptionId_;
    vrfCallbackGasLimit = 150000;
    vrfRequestConfirmations = 3;
    vrfNumWords = 1;

    pauseCutOffInDays = 90;

    if (metadropOracleAddress_ == address(0)) {
      _revert(MetadropOracleCannotBeAddressZero.selector);
    }
    metadropOracleAddress = metadropOracleAddress_;

    _loadInitialTemplates(
      initialTemplateAddresses_,
      initialTemplateDescriptions_
    );

    // Revoke platform admin status of the deployer and transfer superAdmin
    // and ownable owner to the superAdmin_:
    revokePlatformAdmin(_msgSender());
    transferSuperAdmin(superAdmin_);
    _transferOwnership(superAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _loadInitialTemplates  Load initial templates as part of the constructor
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialTemplateAddresses_     An array of template addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param initialTemplateDescriptions_  An array of template descriptions
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _loadInitialTemplates(
    address payable[] memory initialTemplateAddresses_,
    string[] memory initialTemplateDescriptions_
  ) internal {
    if (
      initialTemplateAddresses_.length != initialTemplateDescriptions_.length
    ) {
      _revert(ListLengthMismatch.selector);
    }

    for (uint256 i = 0; i < initialTemplateAddresses_.length; i++) {
      addTemplate(
        initialTemplateAddresses_[i],
        initialTemplateDescriptions_[i]
      );
    }
  }

  /** ====================================================================================================================
   *                                                      GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_)
  {
    return (platformTreasury);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string calldata dropId_
  ) external view returns (DropApproval memory dropDetails_) {
    return (dropDetailsByDropId[dropId_]);
  }

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFMode    Set VRF source to chainlink (0) or arrng (1)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfMode_    The VRF mode.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFMode(uint8 vrfMode_) public onlyPlatformAdmin {
    if (vrfMode_ > 1) {
      _revert(UnrecognisedVRFMode.selector);
    }
    vrfMode = vrfMode_;
    emit VRFModeSet(vrfMode_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(
    uint64 vrfSubscriptionId_
  ) public onlyPlatformAdmin {
    vrfSubscriptionId = vrfSubscriptionId_;
    emit VRFSubscriptionIdSet(vrfSubscriptionId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external onlyPlatformAdmin {
    vrfKeyHash = vrfKeyHash_;
    emit VRFKeyHashSet(vrfKeyHash_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(
    uint32 vrfCallbackGasLimit_
  ) external onlyPlatformAdmin {
    vrfCallbackGasLimit = vrfCallbackGasLimit_;
    emit VRFCallbackGasLimitSet(vrfCallbackGasLimit_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(
    uint16 vrfRequestConfirmations_
  ) external onlyPlatformAdmin {
    if (vrfRequestConfirmations_ > MAX_REQUEST_CONFIRMATIONS) {
      _revert(ValueExceedsMaximum.selector);
    }
    vrfRequestConfirmations = vrfRequestConfirmations_;
    emit VRFRequestConfirmationsSet(vrfRequestConfirmations_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external onlyPlatformAdmin {
    if (vrfNumWords_ > MAX_NUM_WORDS) {
      _revert(ValueExceedsMaximum.selector);
    }
    vrfNumWords = vrfNumWords_;
    emit VRFNumWordsSet(vrfNumWords_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(
    address metadropOracleAddress_
  ) external onlyPlatformAdmin {
    if (metadropOracleAddress_ == address(0)) {
      _revert(MetadropOracleCannotBeAddressZero.selector);
    }
    metadropOracleAddress = metadropOracleAddress_;
    emit MetadropOracleAddressSet(metadropOracleAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInMinutes  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInMinutes_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInMinutes(
    uint256 messageValidityInMinutes_
  ) external onlyPlatformAdmin {
    messageValidityInMinutes = messageValidityInMinutes_;
    emit MessageValidityInMinutesSet(messageValidityInMinutes_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setPauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPauseCutOffInDays(
    uint8 pauseCutOffInDays_
  ) external onlyPlatformAdmin {
    pauseCutOffInDays = pauseCutOffInDays_;

    emit PauseCutOffInDaysSet(pauseCutOffInDays_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external onlyPlatformAdmin {
    uint256 oldDropFee = dropFeeETH;
    dropFeeETH = fee_;
    emit SubmissionFeeETHUpdated(oldDropFee, fee_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the super
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(
    address platformTreasury_
  ) external onlySuperAdmin {
    if (platformTreasury_ == address(0)) {
      _revert(PlatformTreasuryCannotBeAddressZero.selector);
    }
    platformTreasury = platformTreasury_;

    emit PlatformTreasurySet(platformTreasury_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(
    uint32 dropExpiryInDays_
  ) external onlyPlatformAdmin {
    dropExpiryInDays = dropExpiryInDays_;

    emit DropExpiryInDaysSet(dropExpiryInDays_);
  }

  /** ====================================================================================================================
   *                                                  MODULE MAINTENANCE
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawETHFromModules   A withdraw function to allow ETH to be withdrawn from n modules to the
   *                                          treasury address set on the factory (this contract)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETHFromModules(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).transferETHBalanceToTreasury(
        platformTreasury
      );
    }
    emit ModuleETHBalancesTransferred(moduleAddresses_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawERC20FromModules   A withdraw function to allow ERC20s to be withdrawn from n modules to the
   *                                            treasury address set on the modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenContract_         The token contract for withdrawal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20FromModules(
    address[] calldata moduleAddresses_,
    address tokenContract_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).transferERC20BalanceToTreasury(
        platformTreasury,
        IERC20(tokenContract_)
      );
    }
    emit ModuleERC20BalancesTransferred(moduleAddresses_, tokenContract_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseTimesOnModules   Update the phase start and/or end on the provided module(s). Note that
   *                                             sending a 0 means you are NOT updating that time.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param startTimes_            An array of start times
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endTimes_              An array of end times
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseTimesOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata startTimes_,
    uint256[] calldata endTimes_
  ) external onlyPlatformAdmin {
    if (
      moduleAddresses_.length != startTimes_.length ||
      startTimes_.length != endTimes_.length
    ) {
      _revert(ListLengthMismatch.selector);
    }
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      if (startTimes_[i] != 0) {
        IPrimarySaleModule(moduleAddresses_[i]).setPhaseStart(
          uint32(startTimes_[i])
        );
      }
      if (endTimes_[i] != 0) {
        IPrimarySaleModule(moduleAddresses_[i]).setPhaseEnd(
          uint32(endTimes_[i])
        );
      }
    }
    emit ModulePhaseTimesUpdated(moduleAddresses_, startTimes_, endTimes_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseMaxSupplyOnModules   Update the phase max supply on the provided module(s)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupplys_            An array of max supply integers
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseMaxSupplyOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata maxSupplys_
  ) external onlyPlatformAdmin {
    if (moduleAddresses_.length != maxSupplys_.length) {
      _revert(ListLengthMismatch.selector);
    }
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setPhaseMaxSupply(
        uint24(maxSupplys_[i])
      );
    }
    emit ModulePhaseMaxSupplysUpdated(moduleAddresses_, maxSupplys_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateMetadropOracleAddressOnModules   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_  The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMetadropOracleAddressOnModules(
    address[] calldata moduleAddresses_,
    address metadropOracleAddress_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setMetadropOracleAddress(
        metadropOracleAddress_
      );
    }
    emit ModuleOracleAddressUpdated(moduleAddresses_, metadropOracleAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateAntiSybilOffOnModules     Allow platform admin to turn off anti-sybil protection on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAntiSybilOffOnModules(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setAntiSybilOff();
    }
    emit ModuleAntiSybilOff(moduleAddresses_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateAntiSybilOnOnModules     Allow platform admin to turn on anti-sybil protection on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAntiSybilOnOnModules(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setAntiSybilOn();
    }
    emit ModuleAntiSybilOn(moduleAddresses_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOffOnModules     Allow platform admin to turn off EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOffOnModules(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setEPSOff();
    }
    emit ModuleEPSOff(moduleAddresses_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOnOnModules     Allow platform admin to turn on EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOnOnModules(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPrimarySaleModule(moduleAddresses_[i]).setEPSOn();
    }
    emit ModuleEPSOn(moduleAddresses_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updatePublicMintPriceOnModules  Update the price per NFT for the specified drops
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPublicMintPrices_    An array of the new price per mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePublicMintPriceOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata newPublicMintPrices_
  ) external onlyPlatformAdmin {
    if (moduleAddresses_.length != newPublicMintPrices_.length) {
      _revert(ListLengthMismatch.selector);
    }
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPublicMintByMetadrop(moduleAddresses_[i]).updatePublicMintPrice(
        newPublicMintPrices_[i]
      );
    }
    emit ModulePublicMintPricesUpdated(moduleAddresses_, newPublicMintPrices_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updateMerkleRootsOnModules  Set the merkleroot on the specified modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoots_           An array of the bytes32 merkle roots to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMerkleRootsOnModules(
    address[] calldata moduleAddresses_,
    bytes32[] calldata merkleRoots_
  ) external onlyPlatformAdmin {
    if (moduleAddresses_.length != merkleRoots_.length) {
      _revert(ListLengthMismatch.selector);
    }
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IListMintByMetadrop(moduleAddresses_[i]).setList(merkleRoots_[i]);
    }
    emit ModuleMerkleRootsUpdated(moduleAddresses_, merkleRoots_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) pauseDeployedContract   Call pause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function pauseDeployedContract(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPausable(moduleAddresses_[i]).pause();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) unpauseDeployedContract   Call unpause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function unpauseDeployedContract(
    address[] calldata moduleAddresses_
  ) external onlyPlatformAdmin {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      IPausable(moduleAddresses_[i]).unpause();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) updateAuctionFinalFloorDetails   set final auction floor details
   *
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param module_                                      An single module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionFloorPrice_                        The floor price at the end of the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionAboveFloorBidQuantity_             Items above the floor price
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionLastFloorPosition_                 The last floor position for the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionRunningTotalAtLastFloorPosition_   Running total at the last floor position
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAuctionFinalFloorDetails(
    address module_,
    uint80 endAuctionFloorPrice_,
    uint56 endAuctionAboveFloorBidQuantity_,
    uint56 endAuctionLastFloorPosition_,
    uint56 endAuctionRunningTotalAtLastFloorPosition_
  ) external onlyPlatformAdmin {
    IAuctionByMetadrop(module_).setAuctionFinalFloorDetails(
      endAuctionFloorPrice_,
      endAuctionAboveFloorBidQuantity_,
      endAuctionLastFloorPosition_,
      endAuctionRunningTotalAtLastFloorPosition_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) auxCall      Make a previously undefined external call
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param value_                 The value for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data_                  The data for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param txGas_                 The gas for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function auxCall(
    address[] calldata moduleAddresses_,
    uint256 value_,
    bytes memory data_,
    uint256 txGas_
  ) external onlyPlatformAdmin returns (bool success) {
    for (uint256 i = 0; i < moduleAddresses_.length; i++) {
      address to = moduleAddresses_[i];
      assembly {
        success := call(
          txGas_,
          to,
          value_,
          add(data_, 0x20),
          mload(data_),
          0,
          0
        )
      }
      if (!success) {
        revert AuxCallFailed(moduleAddresses_, value_, data_, txGas_);
      }
    }
    emit AuxCallSucceeded(moduleAddresses_, value_, data_, txGas_);
  }

  /** ====================================================================================================================
   *                                                 FACTORY BALANCES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external onlyPlatformAdmin {
    (bool success, ) = platformTreasury.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(
    IERC20 token_,
    uint256 amount_
  ) external onlyPlatformAdmin {
    token_.safeTransfer(platformTreasury, amount_);
  }

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external payable {
    // Can only be called by a deployed collection:
    if (deployedNFTContracts[msg.sender] = true) {
      if (vrfMode == 0) {
        // Chainlink
        addressForChainlinkVRFRequestId[
          vrfCoordinatorInterface.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            vrfRequestConfirmations,
            vrfCallbackGasLimit,
            vrfNumWords
          )
        ] = msg.sender;
      } else {
        // aarng
        addressForArrngVRFRequestId[
          arrngController.requestRandomWords{value: msg.value}(vrfNumWords)
        ] = msg.sender;
      }
    } else {
      _revert(MetadropModulesOnly.selector);
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 / arrng oracle with randomness. We then forward
   * this to the requesting contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_    The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) internal override(ArrngConsumer, VRFConsumerBaseV2) {
    if (_msgSender() == address(arrngController)) {
      INFTByMetadrop(addressForArrngVRFRequestId[requestId_])
        .fulfillRandomWords(requestId_, randomWords_);
    } else {
      INFTByMetadrop(addressForChainlinkVRFRequestId[requestId_])
        .fulfillRandomWords(requestId_, randomWords_);
    }
  }

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string memory templateDescription_
  ) public onlyPlatformAdmin {
    if (address(contractAddress_) == address(0)) {
      _revert(TemplateCannotBeAddressZero.selector);
    }

    uint256 nextTemplateNumber = contractTemplates.length;
    contractTemplates.push(
      Template(
        TemplateStatus.live,
        uint16(nextTemplateNumber),
        uint32(block.timestamp),
        contractAddress_,
        templateDescription_
      )
    );

    emit TemplateAdded(
      TemplateStatus.live,
      nextTemplateNumber,
      block.timestamp,
      contractAddress_,
      templateDescription_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) updateTemplate  Update an existing contract in the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateId_                   The Id of the existing template that we are updating
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be the new template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateTemplate(
    uint256 templateId_,
    address payable contractAddress_
  ) public onlyPlatformAdmin {
    if (contractTemplates[templateId_].templateAddress == address(0)) {
      _revert(TemplateNotFound.selector);
    }
    address oldTemplateAddress = contractTemplates[templateId_].templateAddress;
    contractTemplates[templateId_].templateAddress = contractAddress_;
    emit TemplateUpdated(templateId_, oldTemplateAddress, contractAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(
    uint16 templateNumber_
  ) external onlyPlatformAdmin {
    contractTemplates[templateNumber_].status = TemplateStatus.terminated;

    emit TemplateTerminated(templateNumber_);
  }

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(
    string calldata dropId_
  ) external onlyReviewAdmin {
    // Drop ID must exist:
    require(
      dropDetailsByDropId[dropId_].lastChangedDate != 0,
      "Drop Review: drop ID does not exist"
    );

    // Last changed date must be the expiry period in the past (or greater)
    require(
      dropDetailsByDropId[dropId_].lastChangedDate <
        (block.timestamp - (dropExpiryInDays * 1 days)),
      "Drop Review: drop ID does not exist"
    );

    delete dropDetailsByDropId[dropId_];

    emit DropDetailsDeleted(dropId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string calldata dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external onlyReviewAdmin {
    if (projectOwner_ == address(0)) {
      _revert(ProjectOwnerCannotBeAddressZero.selector);
    }
    dropDetailsByDropId[dropId_] = DropApproval(
      DropStatus.approved,
      uint32(block.timestamp),
      projectOwner_,
      dropConfigHash_
    );

    emit DropApproved(dropId_, projectOwner_, dropConfigHash_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[2] calldata collectionURIs_
  ) external payable {
    // Check the fee:
    require(msg.value == dropFeeETH, "Incorrect ETH payment");

    // Get the details from storage:
    DropApproval memory currentDrop = dropDetailsByDropId[dropId_];

    // We can only proceed if this drop is set to 'approved'
    require(
      currentDrop.status == DropStatus.approved,
      "Drop creation: must be approved"
    );

    // We can only proceed if this is being called by the project owner:
    require(
      currentDrop.dropOwnerAddress == msg.sender,
      "Drop creation: must be submitted by project owner"
    );

    dropDetailsByDropId[dropId_].status = DropStatus.deployed;

    // We can only proceed if the hash of the passed configuration matches that stored
    // on chain from the project approval
    require(
      configHashMatches(
        dropId_,
        nftModule_,
        primarySaleModulesConfig_,
        royaltyPaymentSplitterModule_,
        salesPageHash_,
        customNftAddress_
      ),
      "Drop creation: passed config does not match approved"
    );

    // ---------------------------------------------
    //
    // ROYALTY
    //
    // ---------------------------------------------

    // Create the royalty payment splitter contract clone instance:
    RoyaltyDetails memory royaltyInfo = _createRoyaltyPaymentSplitterContract(
      royaltyPaymentSplitterModule_
    );

    // ---------------------------------------------
    //
    // PRIMARY SALE MODULES
    //
    // ---------------------------------------------
    //

    // Array to hold addresses of created primary sale modules:
    PrimarySaleModuleInstance[]
      memory primarySaleModuleInstances = new PrimarySaleModuleInstance[](
        primarySaleModulesConfig_.length
      );

    // Iterate over the received primary sale modules, instansiate and initialise:
    for (uint256 i = 0; i < primarySaleModulesConfig_.length; i++) {
      primarySaleModuleInstances[i].instanceAddress = payable(
        contractTemplates[primarySaleModulesConfig_[i].templateId]
          .templateAddress
      ).clone();

      primarySaleModuleInstances[i].instanceDescription = contractTemplates[
        primarySaleModulesConfig_[i].templateId
      ].templateDescription;

      // Initialise storage data:
      _initialisePrimarySaleModule(
        primarySaleModuleInstances[i].instanceAddress,
        primarySaleModulesConfig_[i].configData,
        i + 1
      );
    }

    // ---------------------------------------------
    //
    // NFT
    //
    // ---------------------------------------------
    //

    // Create the NFT clone instance:
    address newNFTInstance = _createNFTContract(
      primarySaleModuleInstances,
      nftModule_,
      royaltyInfo,
      customNftAddress_,
      collectionURIs_
    );

    // Iterate over the primary sale modules, and add the NFT address
    for (uint256 i = 0; i < primarySaleModuleInstances.length; i++) {
      IPrimarySaleModule(primarySaleModuleInstances[i].instanceAddress)
        .setNFTAddress(newNFTInstance);
    }

    emit DropDeployed(
      dropId_,
      newNFTInstance,
      primarySaleModuleInstances,
      royaltyInfo.newRoyaltyPaymentSplitterInstance
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _initialisePrimarySaleModule  Load initial values to a sale module
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param instanceAddress_           The module to be initialised
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_                The configuration data for this module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_                   The ID of this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialisePrimarySaleModule(
    address instanceAddress_,
    bytes calldata configData_,
    uint256 phaseId_
  ) internal {
    IPrimarySaleModule(instanceAddress_).initialisePrimarySaleModule(
      configData_,
      pauseCutOffInDays,
      metadropOracleAddress,
      messageValidityInMinutes,
      phaseId_
    );
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _createRoyaltyPaymentSplitterContract  Create the royalty payment splitter.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyModule_     The configuration data for the royalty module
   * ---------------------------------------------------------------------------------------------------------------------
   * @return royaltyInfo_   The contract address for the splitter and the decoded royalty from sales in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _createRoyaltyPaymentSplitterContract(
    RoyaltySplitterModuleConfig calldata royaltyModule_
  ) internal returns (RoyaltyDetails memory royaltyInfo_) {
    // Template 65535 indicates this module is not required
    if (royaltyModule_.templateId == type(uint16).max) {
      royaltyInfo_.newRoyaltyPaymentSplitterInstance = address(0);
      royaltyInfo_.royaltyFromSalesInBasisPoints = 0;
      return (royaltyInfo_);
    }

    address payable targetRoyaltySplitterTemplate = contractTemplates[
      royaltyModule_.templateId
    ].templateAddress;

    // Create the clone vesting contract:
    address newRoyaltySplitterInstance = targetRoyaltySplitterTemplate.clone();

    uint96 royaltyFromSalesInBasisPoints = IRoyaltyPaymentSplitterByMetadrop(
      payable(newRoyaltySplitterInstance)
    ).initialiseRoyaltyPaymentSplitter(royaltyModule_, platformTreasury);

    royaltyInfo_.newRoyaltyPaymentSplitterInstance = newRoyaltySplitterInstance;
    royaltyInfo_.royaltyFromSalesInBasisPoints = royaltyFromSalesInBasisPoints;

    return (royaltyInfo_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) _createNFTContract  Create the NFT contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_          An array of primary sale module addresses for this NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                   Configuration details for the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyInfo_                 Royalty details
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_            The custom NFT address if there is one. If we are not using a metadrop template
   *                                     this function will return this address (keeping the process identical for custom
   *                                     and standard drops)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_              An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * @return nftContract_                The address of the deployed NFT contract clone
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _createNFTContract(
    PrimarySaleModuleInstance[] memory primarySaleModules_,
    NFTModuleConfig memory nftModule_,
    RoyaltyDetails memory royaltyInfo_,
    address customNftAddress_,
    string[2] calldata collectionURIs_
  ) internal returns (address nftContract_) {
    // Template type(uint16).max indicates this module is not required
    if (nftModule_.templateId == type(uint16).max) {
      return (customNftAddress_);
    }

    address newNFTInstance = contractTemplates[nftModule_.templateId]
      .templateAddress
      .clone();

    // Initialise storage data:
    INFTByMetadrop(newNFTInstance).initialiseNFT(
      msg.sender,
      primarySaleModules_,
      nftModule_,
      royaltyInfo_,
      collectionURIs_,
      pauseCutOffInDays
    );
    return newNFTInstance;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) public view returns (bool matches_) {
    // Create the hash of the passed data for comparison:
    bytes32 passedConfigHash = createConfigHash(
      dropId_,
      nftModule_,
      primarySaleModulesConfig_,
      royaltyPaymentSplitterModule_,
      salesPageHash_,
      customNftAddress_
    );
    // Must equal the stored hash:
    return (passedConfigHash == dropDetailsByDropId[dropId_].configHash);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) public pure returns (bytes32 configHash_) {
    // Hash the primary sales module data
    for (uint256 i = 0; i < primarySaleModulesConfig_.length; i++) {
      configHash_ = keccak256(
        abi.encodePacked(
          configHash_,
          primarySaleModulesConfig_[i].templateId,
          primarySaleModulesConfig_[i].configData
        )
      );
    }

    configHash_ = keccak256(
      // Hash remaining items:
      abi.encodePacked(
        configHash_,
        dropId_,
        nftModule_.templateId,
        nftModule_.configData,
        nftModule_.vestingData,
        royaltyPaymentSplitterModule_.templateId,
        royaltyPaymentSplitterModule_.configData,
        salesPageHash_,
        customNftAddress_
      )
    );

    return (configHash_);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IDropFactory is IConfigStructures, IErrors {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */

  event DefaultMetadropPrimaryShareBasisPointsSet(
    uint256 defaultPrimaryFeeBasisPoints
  );
  event DefaultMetadropRoyaltyBasisPointsSet(
    uint256 defaultMetadropRoyaltyBasisPoints
  );
  event PrimaryFeeOverrideByDropSet(string dropId, uint256 percentage);
  event RoyaltyBasisPointsOverrideByDropSet(
    string dropId,
    uint256 royaltyBasisPoints
  );
  event PlatformTreasurySet(address platformTreasury);
  event TemplateAdded(
    TemplateStatus status,
    uint256 templateNumber,
    uint256 loadedDate,
    address templateAddress,
    string templateDescription
  );
  event TemplateUpdated(
    uint256 templateNumber,
    address oldTemplateAddress,
    address newTemplateAddress
  );
  event TemplateTerminated(uint16 templateNumber);
  event DropApproved(
    string indexed dropId,
    address indexed dropOwner,
    bytes32 dropHash
  );
  event DropDetailsDeleted(string indexed dropId);
  event DropExpiryInDaysSet(uint32 expiryInDays);
  event PauseCutOffInDaysSet(uint8 cutOffInDays);
  event SubmissionFeeETHUpdated(uint256 oldFee, uint256 newFee);
  event DropDeployed(
    string dropId,
    address nftInstance,
    PrimarySaleModuleInstance[],
    address royaltySplitterInstance
  );
  event VRFModeSet(uint8 mode);
  event VRFSubscriptionIdSet(uint64 vrfSubscriptionId_);
  event VRFKeyHashSet(bytes32 vrfKeyHash);
  event VRFCallbackGasLimitSet(uint32 vrfCallbackGasLimit);
  event VRFRequestConfirmationsSet(uint16 vrfRequestConfirmations);
  event VRFNumWordsSet(uint32 vrfNumWords);
  event MetadropOracleAddressSet(address metadropOracleAddress);
  event MessageValidityInMinutesSet(uint256 messageValidityInMinutes);
  event ModuleETHBalancesTransferred(address[] modules);
  event ModuleERC20BalancesTransferred(
    address[] modules,
    address erc20Contract
  );
  event ModulePhaseTimesUpdated(
    address[] modules,
    uint256[] startTimes,
    uint256[] endTimes
  );
  event ModulePhaseMaxSupplysUpdated(address[] modules, uint256[] maxSupplys);
  event ModuleOracleAddressUpdated(address[] modules, address oracle);
  event ModuleAntiSybilOff(address[] modules);
  event ModuleAntiSybilOn(address[] modules);
  event ModuleEPSOff(address[] modules);
  event ModuleEPSOn(address[] modules);
  event ModulePublicMintPricesUpdated(
    address[] modules,
    uint256[] publicMintPrice
  );
  event ModuleMerkleRootsUpdated(address[] modules, bytes32[] merkleRoot);
  event AuxCallSucceeded(
    address[] modules,
    uint256 value,
    bytes data,
    uint256 txGas
  );

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ====================================================================================================================
   *                                                      GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string calldata dropId_
  ) external view returns (DropApproval memory dropDetails_);

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFMode    Set VRF source to chainlink (0) or arrng (1)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfMode_    The VRF mode.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFMode(uint8 vrfMode_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInMinutes  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInMinutes_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInMinutes(
    uint256 messageValidityInMinutes_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setPauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPauseCutOffInDays(uint8 pauseCutOffInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the super
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(uint32 dropExpiryInDays_) external;

  /** ====================================================================================================================
   *                                                  MODULE MAINTENANCE
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawETHFromModules   A withdraw function to allow ETH to be withdrawn from n modules to the
   *                                          treasury address set on the factory (this contract)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETHFromModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) withdrawERC20FromModules   A withdraw function to allow ERC20s to be withdrawn from n modules to the
   *                                            treasury address set on the modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenContract_         The token contract for withdrawal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20FromModules(
    address[] calldata moduleAddresses_,
    address tokenContract_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseTimesOnModules   Update the phase start and/or end on the provided module(s). Note that
   *                                             sending a 0 means you are NOT updating that time.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param startTimes_            An array of start times
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endTimes_              An array of end times
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseTimesOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata startTimes_,
    uint256[] calldata endTimes_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updatePhaseMaxSupplyOnModules   Update the phase max supply on the provided module(s)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupplys_            An array of max supply integers
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePhaseMaxSupplyOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata maxSupplys_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateMetadropOracleAddressOnModules   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_  The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMetadropOracleAddressOnModules(
    address[] calldata moduleAddresses_,
    address metadropOracleAddress_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateAntiSybilOffOnModules     Allow platform admin to turn off anti-sybil protection on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAntiSybilOffOnModules(
    address[] calldata moduleAddresses_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateAntiSybilOnOnModules     Allow platform admin to turn on anti-sybil protection on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAntiSybilOnOnModules(
    address[] calldata moduleAddresses_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOffOnModules     Allow platform admin to turn off EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOffOnModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) updateEPSOnOnModules     Allow platform admin to turn on EPS on modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateEPSOnOnModules(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updatePublicMintPriceOnModules  Update the price per NFT for the specified drops
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_        An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPublicMintPrices_    An array of the new price per mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePublicMintPriceOnModules(
    address[] calldata moduleAddresses_,
    uint256[] calldata newPublicMintPrices_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->MODULES
   * @dev (function) updateMerkleRootsOnModules  Set the merkleroot on the specified modules
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoots_           An array of the bytes32 merkle roots to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateMerkleRootsOnModules(
    address[] calldata moduleAddresses_,
    bytes32[] calldata merkleRoots_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) pauseDeployedContract   Call pause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function pauseDeployedContract(address[] calldata moduleAddresses_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) unpauseDeployedContract   Call unpause on deployed contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function unpauseDeployedContract(
    address[] calldata moduleAddresses_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) updateAuctionFinalFloorDetails   set final auction floor details
   *
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param module_                                      An single module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionFloorPrice_                        The floor price at the end of the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionAboveFloorBidQuantity_             Items above the floor price
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionLastFloorPosition_                 The last floor position for the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionRunningTotalAtLastFloorPosition_   Running total at the last floor position
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateAuctionFinalFloorDetails(
    address module_,
    uint80 endAuctionFloorPrice_,
    uint56 endAuctionAboveFloorBidQuantity_,
    uint56 endAuctionLastFloorPosition_,
    uint56 endAuctionRunningTotalAtLastFloorPosition_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->MODULES
   * @dev (function) auxCall      Make a previously undefined external call
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param moduleAddresses_       An array of module addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param value_                 The value for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data_                  The data for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param txGas_                 The gas for the auxilliary call
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function auxCall(
    address[] calldata moduleAddresses_,
    uint256 value_,
    bytes memory data_,
    uint256 txGas_
  ) external returns (bool success);

  /** ====================================================================================================================
   *                                                 FACTORY BALANCES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external payable;

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string calldata templateDescription_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) updateTemplate  Update an existing contract in the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateId_                   The Id of the existing template that we are updating
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be the new template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updateTemplate(
    uint256 templateId_,
    address payable contractAddress_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(uint16 templateNumber_) external;

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(string calldata dropId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string calldata dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[2] calldata collectionURIs_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external view returns (bool matches_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string calldata dropId_,
    NFTModuleConfig calldata nftModule_,
    PrimarySaleModuleConfig[] calldata primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig calldata royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external pure returns (bytes32 configHash_);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title AuthorityModel.sol. Library for global authority components
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

/**
 *
 * @dev Inheritance details:
 *      EnumerableSet           OZ enumerable mapping sets
 *      IErrors                 Interface for platform error definitions
 *
 */

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IErrors} from "./IErrors.sol";
import {Revert} from "./Revert.sol";

contract AuthorityModel is IErrors, Revert {
  using EnumerableSet for EnumerableSet.AddressSet;

  // Address for the factory:
  address public factory;

  // The super admin can grant and revoke roles
  address public superAdmin;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _platformAdmins;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _reviewAdmins;

  event SuperAdminTransferred(address oldSuperAdmin, address newSuperAdmin);
  event PlatformAdminAdded(address platformAdmin);
  event ReviewAdminAdded(address reviewAdmin);
  event PlatformAdminRevoked(address platformAdmin);
  event ReviewAdminRevoked(address reviewAdmin);

  /** ====================================================================================================================
   *                                                       MODIFIERS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlySuperAdmin. The associated action can only be taken by the super admin (an address with the
   * default admin role).
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlySuperAdmin() {
    if (!isSuperAdmin(msg.sender)) revert CallerIsNotSuperAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdmin() {
    if (!isPlatformAdmin(msg.sender))
      revert CallerIsNotPlatformAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyReviewAdmin. The associated action can only be taken by an address with the
   * review admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyReviewAdmin() {
    if (!isReviewAdmin(msg.sender)) revert CallerIsNotReviewAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformAdmins   Getter for the enumerable list of platform admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformAdmins_  A list of platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformAdmins()
    public
    view
    returns (address[] memory platformAdmins_)
  {
    return (_platformAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getReviewAdmins   Getter for the enumerable list of review admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return reviewAdmins_  A list of review admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getReviewAdmins()
    public
    view
    returns (address[] memory reviewAdmins_)
  {
    return (_reviewAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) isSuperAdmin   check if an address is the super admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function isSuperAdmin(address queryAddress_) public view returns (bool) {
    return (superAdmin == queryAddress_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) isPlatformAdmin   check if an address is a platform admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function isPlatformAdmin(address queryAddress_) public view returns (bool) {
    return (_platformAdmins.contains(queryAddress_));
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) isReviewAdmin   check if an address is a review admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function isReviewAdmin(address queryAddress_) public view returns (bool) {
    return (_reviewAdmins.contains(queryAddress_));
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantPlatformAdmin  Allows the super user Default Admin to add an address to the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_              The address of the new platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantPlatformAdmin(address newPlatformAdmin_) public onlySuperAdmin {
    if (newPlatformAdmin_ == address(0)) {
      _revert(PlatformAdminCannotBeAddressZero.selector);
    }
    // Add this to the enumerated list:
    _platformAdmins.add(newPlatformAdmin_);
    emit PlatformAdminAdded(newPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantReviewAdmin  Allows the super user Default Admin to add an address to the review admin group.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newReviewAdmin_              The address of the new review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantReviewAdmin(address newReviewAdmin_) public onlySuperAdmin {
    if (newReviewAdmin_ == address(0)) {
      _revert(ReviewAdminCannotBeAddressZero.selector);
    }
    // Add this to the enumerated list:
    _reviewAdmins.add(newReviewAdmin_);
    emit ReviewAdminAdded(newReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokePlatformAdmin  Allows the super user Default Admin to revoke from the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldPlatformAdmin_              The address of the old platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokePlatformAdmin(
    address oldPlatformAdmin_
  ) public onlySuperAdmin {
    // Remove this from the enumerated list:
    _platformAdmins.remove(oldPlatformAdmin_);
    emit PlatformAdminRevoked(oldPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeReviewAdmin  Allows the super user Default Admin to revoke an address to the review admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldReviewAdmin_              The address of the old review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokeReviewAdmin(address oldReviewAdmin_) public onlySuperAdmin {
    // Remove this from the enumerated list:
    _reviewAdmins.remove(oldReviewAdmin_);
    emit ReviewAdminRevoked(oldReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferSuperAdmin  Allows the super user Default Admin to transfer this right to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newSuperAdmin_              The address of the new default admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferSuperAdmin(address newSuperAdmin_) public onlySuperAdmin {
    address oldSuperAdmin = superAdmin;
    // Update storage of this address:
    superAdmin = newSuperAdmin_;
    emit SuperAdminTransferred(oldSuperAdmin, newSuperAdmin_);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IConfigStructures.sol. Interface for common config structures used accross the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IConfigStructures {
  enum DropStatus {
    approved,
    deployed,
    cancelled
  }

  enum TemplateStatus {
    live,
    terminated
  }

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PrimarySaleModuleInstance {
    address instanceAddress;
    string instanceDescription;
  }

  struct NFTModuleConfig {
    uint256 templateId;
    bytes configData;
    bytes vestingData;
  }

  struct PrimarySaleModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct ProjectBeneficiary {
    address payable payeeAddress;
    uint256 payeeShares;
  }

  struct VestingConfig {
    uint256 start;
    uint256 projectUpFrontShare;
    uint256 projectVestedShare;
    uint256 vestingPeriodInDays;
    uint256 vestingCliff;
    ProjectBeneficiary[] projectPayees;
  }

  struct RoyaltySplitterModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModules {
    InLifeModuleConfig[] modules;
  }

  struct NFTConfig {
    uint256 supply;
    string name;
    string symbol;
    bytes32 positionProof;
    bool includePriorPhasesInMintTracking;
  }

  struct DropApproval {
    DropStatus status;
    uint32 lastChangedDate;
    address dropOwnerAddress;
    bytes32 configHash;
  }

  struct Template {
    TemplateStatus status;
    uint16 templateNumber;
    uint32 loadedDate;
    address payable templateAddress;
    string templateDescription;
  }

  struct RoyaltyDetails {
    address newRoyaltyPaymentSplitterInstance;
    uint96 royaltyFromSalesInBasisPoints;
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IErrors.sol. Interface for error definitions used across the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IErrors {
  enum BondingCurveErrorType {
    OK, //                                                  No error
    INVALID_NUMITEMS, //                                    The numItem value is 0
    SPOT_PRICE_OVERFLOW //                                  The updated spot price doesn't fit into 128 bits
  }

  error AdapterParamsMustBeEmpty(); //                      The adapter parameters on this LZ call must be empty.

  error AddressAlreadySet(); //                             The address being set can only be set once, and is already non-0.

  error AlreadyInitialised(); //                            The contract is already initialised: it cannot be initialised twice!

  error ApprovalCallerNotOwnerNorApproved(); //             The caller must own the token or be an approved operator.

  error ApprovalQueryForNonexistentToken(); //              The token does not exist.

  error AuctionStatusIsNotEnded(); //                       Throw if the action required the auction to be closed, and it isn't.

  error AuctionStatusIsNotOpen(); //                        Throw if the action requires the auction to be open, and it isn't.

  error AuxCallFailed(
    address[] modules,
    uint256 value,
    bytes data,
    uint256 txGas
  ); //                                                     An auxilliary call from the drop factory failed.

  error BalanceQueryForZeroAddress(); //                    Cannot query the balance for the zero address.

  error BidMustBeBelowTheFloorWhenReducingQuantity(); //    Only bids that are below the floor can reduce the quantity of the bid.

  error BidMustBeBelowTheFloorForRefundDuringAuction(); //  Only bids that are below the floor can be refunded during the auction.

  error BondingCurveError(BondingCurveErrorType error); //  An error of the type specified has occured in bonding curve processing.

  error CallerIsNotFactory(); //                            The caller of this function must match the factory address in storage.

  error CallerIsNotFactoryOrProjectOwner(); //              The caller of this function must match the factory address OR project owner address.

  error CallerIsNotTheOwner(); //                           The caller is not the owner of this contract.

  error CallerMustBeLzApp(); //                             The caller must be an LZ application.

  error CallerIsNotPlatformAdmin(address caller); //        The caller of this function must be part of the platformAdmin group.

  error CallerIsNotSuperAdmin(address caller); //           The caller of this function must match the superAdmin address in storage.

  error CallerIsNotReviewAdmin(address caller); //          The caller of this function must be part of the reviewAdmin group.

  error CannotSetNewOwnerToTheZeroAddress(); //             You can't set the owner of this contract to the zero address (address(0)).

  error CannotSetToZeroAddress(); //                        The corresponding address cannot be set to the zero address (address(0)).

  error CollectionAlreadyRevealed(); //                     The collection is already revealed; you cannot call reveal again.

  error ContractIsPaused(); //                              The call requires the contract to be unpaused, and it is paused.

  error ContractIsNotPaused(); //                           The call required the contract to be paused, and it is NOT paused.

  error DecreasedAllowanceBelowZero(); //                   The request would decrease the allowance below zero, and that is not allowed.

  error DestinationIsNotTrustedSource(); //                 The destination that is being called through LZ has not been set as trusted.

  error GasLimitIsTooLow(); //                              The gas limit for the LayerZero call is too low.

  error IncorrectConfirmationValue(); //                    You need to enter the right confirmation value to call this funtion (usually 69420).

  error IncorrectPayment(); //                              The function call did not include passing the correct payment.

  error InvalidAdapterParams(); //                          The current adapter params for LayerZero on this contract won't work :(.

  error InvalidAddress(); //                                An address being processed in the function is not valid.

  error InvalidEndpointCaller(); //                         The calling address is not a valid LZ endpoint. The LZ endpoint was set at contract creation
  //                                                        and cannot be altered after. Check the address LZ endpoint address on the contract.

  error InvalidMinGas(); //                                 The minimum gas setting for LZ in invalid.

  error InvalidOracleSignature(); //                        The signature provided with the contract call is not valid, either in format or signer.

  error InvalidPayload(); //                                The LZ payload is invalid

  error InvalidReceiver(); //                               The address used as a target for funds is not valid.

  error InvalidSourceSendingContract(); //                  The LZ message is being related from a source contract on another chain that is NOT trusted.

  error InvalidTotalShares(); //                            Total shares must equal 100 percent in basis points.

  error ListLengthMismatch(); //                            Two or more lists were compared and they did not match length.

  error NoTrustedPathRecord(); //                           LZ needs a trusted path record for this to work. What's that, you ask?

  error MaxBidQuantityIs255(); //                           Validation: as we use a uint8 array to track bid positions the max bid quantity is 255.

  error MaxPublicMintAllowanceExceeded(
    uint256 requested,
    uint256 alreadyMinted,
    uint256 maxAllowance
  ); //                                                     The calling address has requested a quantity that would exceed the max allowance.

  error MetadataIsLocked(); //                              The metadata on this contract is locked; it cannot be altered!

  error MetadropFactoryOnlyOncePerReveal(); //              This function can only be called (a) by the factory and, (b) just one time!

  error MetadropModulesOnly(); //                           Can only be called from a metadrop contract.

  error MetadropOracleCannotBeAddressZero(); //             The metadrop Oracle cannot be the zero address (address(0)).

  error MinGasLimitNotSet(); //                             The minimum gas limit for LayerZero has not been set.

  error MintERC2309QuantityExceedsLimit(); //               The `quantity` minted with ERC2309 exceeds the safety limit.

  error MintingIsClosedForever(); //                        Minting is, as the error suggests, so over (and locked forever).

  error MintToZeroAddress(); //                             Cannot mint to the zero address.

  error MintZeroQuantity(); //                              The quantity of tokens minted must be more than zero.

  error NoPaymentDue(); //                                  No payment is due for this address.

  error NoRefundForCaller(); //                             Error thrown when the calling address has no refund owed.

  error NoStoredMessage(); //                               There is no stored message matching the passed parameters.

  error OperationDidNotSucceed(); //                        The operation failed (vague much?).

  error OracleSignatureHasExpired(); //                     A signature has been provided but it is too old.

  error OwnershipNotInitializedForExtraData(); //           The `extraData` cannot be set on an uninitialized ownership slot.

  error OwnerQueryForNonexistentToken(); //                 The token does not exist.

  error ParametersDoNotMatchSignedMessage(); //             The parameters passed with the signed message do not match the message itself.

  error PauseCutOffHasPassed(); //                          The time period in which we can pause has passed; this contract can no longer be paused.

  error PaymentMustCoverPerMintFee(); //                    The payment passed must at least cover the per mint fee for the quantity requested.

  error PermitDidNotSucceed(); //                           The safeERC20 permit failed.

  error PlatformAdminCannotBeAddressZero(); //              We cannot use the zero address (address(0)) as a platformAdmin.

  error PlatformTreasuryCannotBeAddressZero(); //           The treasury address cannot be set to the zero address.

  error ProjectOwnerCannotBeAddressZero(); //               The project owner has to be a non zero address.

  error ProofInvalid(); //                                  The provided proof is not valid with the provided arguments.

  error QuantityExceedsRemainingCollectionSupply(); //      The requested quantity would breach the collection supply.

  error QuantityExceedsRemainingPhaseSupply(); //           The requested quantity would breach the phase supply.

  error QuantityExceedsMaxPossibleCollectionSupply(); //    The requested quantity would breach the maximum trackable supply

  error ReferralIdAlreadyUsed(); //                         This referral ID has already been used; they are one use only.

  error RequestingMoreThanRemainingAllocation(
    uint256 previouslyMinted,
    uint256 requested,
    uint256 remainingAllocation
  ); //                                                     Number of tokens requested for this mint exceeds the remaining allocation (taking the
  //                                                        original allocation from the list and deducting minted tokens).

  error ReviewAdminCannotBeAddressZero(); //                We cannot use the zero address (address(0)) as a platformAdmin.

  error RoyaltyFeeWillExceedSalePrice(); //                 The ERC2981 royalty specified will exceed the sale price.

  error ShareTotalCannotBeZero(); //                        The total of all the shares cannot be nothing.

  error SliceOutOfBounds(); //                              The bytes slice operation was out of bounds.

  error SliceOverflow(); //                                 The bytes slice operation overlowed.

  error SuperAdminCannotBeAddressZero(); //                 The superAdmin cannot be the sero address (address(0)).

  error TemplateCannotBeAddressZero(); //                   The address for a template cannot be address zero (address(0)).

  error TemplateNotFound(); //                              There is no template that matches the passed template Id.

  error ThisMintIsClosed(); //                              It's over (well, this mint is, anyway).

  error TotalSharesMustMatchDenominator(); //               The total of all shares must equal the denominator value.

  error TransferCallerNotOwnerNorApproved(); //             The caller must own the token or be an approved operator.

  error TransferFailed(); //                                The transfer has, you may be surprised to learn, failed.

  error TransferFromIncorrectOwner(); //                    The token must be owned by `from`.

  error TransferToNonERC721ReceiverImplementer(); //        Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.

  error TransferToZeroAddress(); //                         Cannot transfer to the zero address.

  error UnrecognisedVRFMode(); //                           Currently supported VRF modes are 0: chainlink and 1: arrng

  error URIQueryForNonexistentToken(); //                   The token does not exist.

  error ValueExceedsMaximum(); //                           The value sent exceeds the maximum allowed (super useful explanation huh?).

  error VRFCoordinatorCannotBeAddressZero(); //             The VRF coordinator cannot be the zero address (address(0)).
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IPausable.sol. Interface for common external implementation of Pausable.sol
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IPausable {
  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) pause    Allow platform admin to pause
   * _____________________________________________________________________________________________________________________
   */
  function pause() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) unpause    Allow platform admin to unpause
   * _____________________________________________________________________________________________________________________
   */
  function unpause() external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.19;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IErrors} from "../IErrors.sol";
import {Revert} from "../Revert.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is IErrors, Revert, Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {}

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    if (owner() != _msgSender()) {
      _revert(CallerIsNotTheOwner.selector);
    }
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby disabling any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    if (newOwner == address(0)) {
      _revert(CannotSetNewOwnerToTheZeroAddress.selector);
    }
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)
// Metadrop based on OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IErrors} from "../IErrors.sol";

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
    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
  }

  /**
   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
   * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
   */
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      token,
      abi.encodeCall(token.transferFrom, (from, to, value))
    );
  }

  /**
   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 oldAllowance = token.allowance(address(this), spender);
    forceApprove(token, spender, oldAllowance + value);
  }

  /**
   * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful.
   */
  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      if (oldAllowance < value) {
        revert IErrors.DecreasedAllowanceBelowZero();
      }
      forceApprove(token, spender, oldAllowance - value);
    }
  }

  /**
   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
   * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
   * 0 before setting it to a non-zero value.
   */
  function forceApprove(IERC20 token, address spender, uint256 value) internal {
    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

    if (!_callOptionalReturnBool(token, approvalCall)) {
      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
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
    if (nonceAfter != (nonceBefore + 1)) {
      revert IErrors.PermitDidNotSucceed();
    }
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

    bytes memory returndata = address(token).functionCall(data, "call fail");
    if ((returndata.length != 0) && !abi.decode(returndata, (bool))) {
      revert IErrors.OperationDidNotSucceed();
    }
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   *
   * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
   */
  function _callOptionalReturnBool(
    IERC20 token,
    bytes memory data
  ) private returns (bool) {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
    // and not revert is the subcall reverts.

    (bool success, bytes memory returndata) = address(token).call(data);
    return
      success &&
      (returndata.length == 0 || abi.decode(returndata, (bool))) &&
      address(token).code.length > 0;
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title Revert.sol. For efficient reverts
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

abstract contract Revert {
  /**
   * @dev For more efficient reverts.
   */
  function _revert(bytes4 errorSelector) internal pure {
    assembly {
      mstore(0x00, errorSelector)
      revert(0x00, 0x04)
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title INFTByMetadrop.sol. Interface for metadrop NFT standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IPausable} from "../Global/IPausable.sol";

interface INFTByMetadrop is IConfigStructures, IPausable {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event Revealed();
  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);
  event PositionProofSet(bytes32 positionProof);
  event MetadropMint(
    address indexed allowanceAddress,
    address indexed recipientAddress,
    address callerAddress,
    address primarySaleModuleAddress,
    uint256 unitPrice,
    uint256[] tokenIds
  );

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_       The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_ The primary sale modules for this drop. These are the contract addresses that are
   *                            authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * ---------------------------------------------------------------------------------------------------------------------

   * ---------------------------------------------------------------------------------------------------------------------
   * ---------------------------------------------------------------------------------------------------------------------

   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    //NFTModuleConfig calldata nftModule_,
    RoyaltyDetails memory royaltyInfo_,
    // address royaltyPaymentSplitter_,
    // uint96 totalRoyaltyPercentage_,
    string[2] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
    //VestingModuleConfig calldata vestingModule_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_);

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view returns (uint256 totalSupply_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() external view returns (uint256 totalUnminted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view returns (uint256 totalMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view returns (uint256 totalBurned_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) phaseMintCount  Number of tokens minted for the queried phase
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseQuantityMinted_   The total minting for this phase
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintCount(
    uint256 index_
  ) external view returns (uint256 phaseQuantityMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[0]   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_[1]    The URI when revealed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(string[] calldata uris_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->MINT CONTROL
   * @dev (function) setOverrideMintDuration  Allow project owner to override the original mint duration
   *
   * @notice Enter confirmation value to confirm that you are overriding
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmationValue_  Confirmation value
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setOverrideMintDuration(
    uint256 confirmationValue_,
    bool isOverriden_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner to set minting complete
   *
   * @notice Enter confirmation value to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmationValue_  Confirmation value
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    uint256 confirmationValue_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * @notice Enter confirmation value to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmationValue_  Confirmation value
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(uint256 confirmationValue_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param uris_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection(
    string[] calldata uris_) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(address recipient_, uint96 fraction_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_   The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_        The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    uint256 phaseId_,
    uint256 phaseMintLimit_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IAuctionByMetadrop.sol. Interface for metadrop auction primary sale module
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IConfigStructures} from "../../Global/IConfigStructures.sol";

interface IAuctionByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    STRUCTS and ENUMS
   * =====================================================================================================================
   */
  // Bid Status:
  enum Status {
    notYetOpen,
    open,
    finished,
    unknown
  }

  // Struct for module configuration
  struct AuctionConfig {
    uint256 phaseMaxSupply;
    uint256 phaseStart;
    uint256 phaseEnd;
    uint256 metadropPerMintFee;
    uint256 metadropPrimaryShareInBasisPoints;
    uint256 minUnitPrice;
    uint256 maxUnitPrice;
    uint256 minQuantity;
    uint256 maxQuantity;
    uint256 minBidIncrement;
  }

  // Object for bids:
  struct Bid {
    uint112 unitPrice;
    uint112 quantity;
    uint32 levelPosition;
  }
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */

  // Event emitted at the end of the auction:
  event AuctionEnded();

  // Event emitted when a bid is placed:
  event BidPlaced(
    address indexed bidder,
    //uint256 bidIndex,
    uint256 unitPrice,
    uint256 quantity,
    uint256 balance
  );

  // Event emitted when a refund is issued. Note that a refund could be during the
  // auction for a bid below the floor price or after the completion of the auction.
  // Bidders are entitled to a refund when:
  // - They have not won any items (refund = total bid amount)
  // - They have won some of the items the bid on (refund = total bid amount for
  //   items that were not won + diff floor to bid amount for won items)
  // - They won items above the floor price (refund = total bid amount - quantity of
  //   bid multiplied by the end floor price)
  //
  // Users can mint and refund from the second the auction completed.
  event RefundIssued(address indexed refundRecipient, uint256 refundAmount);

  event AuctionFinalFloorDetailsSet(
    uint80 endAuctionFloorPrice,
    uint56 endAuctionAboveFloorBidQuantity,
    uint56 endAuctionLastFloorPosition,
    uint56 endAuctionRunningTotalAtLastFloorPosition
  );

  /** ====================================================================================================================
   *                                                     FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->WORKFLOW
   * @dev (function) auctionStatus  returns the status of the auction
   *                                  - notYetOpen: auction hasn't started yet
   *                                  - open: auction is currently active
   *                                  - finished: auction has ended
   *                                  - unknown: theoretically impossible
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return auctionStatus_        The status of the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function auctionStatus() external view returns (Status auctionStatus_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->WORKFLOW
   * @dev (function) endAuction  External function that can be called to execute _endAuction
   *                             when the block.timestamp exceeds the auction end time (i.e. the auction is over).
   * _____________________________________________________________________________________________________________________
   */
  function endAuction() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) getBid    Returns the bid data for the passed address.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param bidder_             The bidder being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bid_               Bid details for the bidder
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getBid(address bidder_) external view returns (Bid memory bid_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) getFloorLevel    returns the floor price for the give level and the array of values in the
   *                                  floor tracker for that level
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param index_             The bidder being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return levelPrice_       The price at the queried level index
   * ---------------------------------------------------------------------------------------------------------------------
   * @return levelArray_       Array of values in the floor tracker at this level
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getFloorLevel(
    uint256 index_
  ) external view returns (uint256 levelPrice_, uint8[] memory levelArray_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) placeBid     When a bidder places a bid or updates their existing bid, they will use this function.
   *                                - total value can never be lowered
   *                                - unit price can never be lowered
   *                                - quantity can be raised
   *                                - if the bid is below the floor quantity can be lowered, but only if unit price
   *                                  is raised to meet or exceed previous total price
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantity_             The quantity of items the bid is for
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_            The unit price for each item bid upon
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function placeBid(uint256 quantity_, uint256 unitPrice_) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) bidIsBelowFloor     Returns if a bid is below the floor (or not)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param bidAmount_            The unit price for each item bid upon
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bidIsBelowFloor_     The bid IS below the floor
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function bidIsBelowFloor(
    uint256 bidAmount_
  ) external view returns (bool bidIsBelowFloor_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) getAuctionFloor     Return the auction floor and the quantity of bids that are above the floor.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return theFloor_                Current bid floor
   * ---------------------------------------------------------------------------------------------------------------------
   * @return aboveFloorBidQuantity_   Number of items above the floor
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getAuctionFloor()
    external
    view
    returns (uint80 theFloor_, uint56 aboveFloorBidQuantity_);

  /**
   *
   * @dev recordAuctionFinalFloorDetails: persist the final floor values to storage
   * so they can be read rather than calculated for all subsequent processing
   *
   */
  function recordAuctionFinalFloorDetails() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->AUCTION
   * @dev (function) setAuctionFinalFloorDetails   allow the setting of final auction floor details by the Owner.
   *
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionFloorPrice_                         The floor price at the end of the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionAboveFloorBidQuantity_             Items above the floor price
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionLastFloorPosition_                  The last floor position for the auction
   * ---------------------------------------------------------------------------------------------------------------------
   * @param endAuctionRunningTotalAtLastFloorPosition_   Running total at the last floor position
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setAuctionFinalFloorDetails(
    uint80 endAuctionFloorPrice_,
    uint56 endAuctionAboveFloorBidQuantity_,
    uint56 endAuctionLastFloorPosition_,
    uint56 endAuctionRunningTotalAtLastFloorPosition_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) refundAndMint   external function call to allow bidders to claim refunds and mint tokens
   *
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_              The recipient of NFTs for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function refundAndMint(address recipient_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) refund   External function call to allow bidders to claim refunds. Note that this can be
   *                          called DURING the auction but cannot be called AFTER the action. After the auction has ended
   *                          all claims go through refundAndMint. No mint will occur for losing bids, but this keeps the
   *                          post-auction refund and claim process in one function
   * _____________________________________________________________________________________________________________________
   */
  function refund() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) getBidDetails     Get details of a bid including the winning quantity.
   *                                   during the auction the winning quantity will be at that point in time (as bids
   *                                   may move into losing positions as a result of subsequent bids).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param bidder_                    The bidder being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getBidDetails(
    address bidder_
  )
    external
    view
    returns (uint256 quantity, uint256 unitPrice, uint256 winningAllocation);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) auctionSupply     The supply for this auction (derived from the associated NFT contract
   *
   * _____________________________________________________________________________________________________________________
   */
  function auctionSupply() external view returns (uint32);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IPrimarySaleModule.sol. Interface for base primary sale module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IPausable} from "../Global/IPausable.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IPrimarySaleModule is IErrors, IConfigStructures, IPausable {
  /** ====================================================================================================================
   *                                                       EVENTS
   * =====================================================================================================================
   */
  event TreasuryAddressUpdated(address oldTreasury, address newTreasury);

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialisePrimarySaleModule  Defined here and must be overriden in child contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param configData_               The drop specific configuration for this module. This is decoded and used to set
   *                                  configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutoffInDays_        The maximum number of days after drop deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_    The trusted metadrop signer. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_ The validity period of a signed message. This is used with anti-bot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseId_                  The ID of this phase, used for tracking supply
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialisePrimarySaleModule(
    bytes calldata configData_,
    uint256 pauseCutoffInDays_,
    address metadropOracleAddress_,
    uint256 messageValidityInSeconds_,
    uint256 phaseId_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) getPhaseStartAndEnd  Get the start and end times for this phase
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseStart_             The phase start time
   * ---------------------------------------------------------------------------------------------------------------------
   * @return phaseEnd_               The phase end time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPhaseStartAndEnd()
    external
    view
    returns (uint256 phaseStart_, uint256 phaseEnd_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseStart  Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseStart_             The phase start time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseStart(uint32 phaseStart_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseEnd    Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseEnd_               The phase end time
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseEnd(uint32 phaseEnd_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) setPhaseMaxSupply     Set the phase start for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param phaseMaxSupply_                The phase supply
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPhaseMaxSupply(uint24 phaseMaxSupply_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) setNFTAddress    Set the NFT contract for this drop
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftContract_           The deployed NFT contract
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setNFTAddress(address nftContract_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->SETUP
   * @dev (function) phaseMintStatus    The status of the deployed primary sale module
   * _____________________________________________________________________________________________________________________
   */
  function phaseMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferETHBalanceToTreasury        A transfer function to allow  all ETH to be withdrawn
   *                                                     to vesting.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param treasury_           The treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferETHBalanceToTreasury(address treasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) transferERC20BalanceToTreasury     A transfer function to allow ERC20s to be withdrawn to the
   *                                             treasury.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param treasury_          The treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_             The token to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferERC20BalanceToTreasury(
    address treasury_,
    IERC20 token_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setMetadropOracleAddress   Allow platform admin to update trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_         The new metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn off anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setAntiSybilOff     Allow platform admin to turn ON anti-sybil protection
   * _____________________________________________________________________________________________________________________
   */
  function setAntiSybilOn() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn off EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOff() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) setEPSOff    Allow platform admin to turn ON EPS
   * _____________________________________________________________________________________________________________________
   */
  function setEPSOn() external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IListMintByMetadrop.sol. Interface for metadrop list mint primary sale module
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IConfigStructures} from "../../Global/IConfigStructures.sol";

interface IListMintByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                  STRUCTS and ENUMS
   * =====================================================================================================================
   */
  // Enumerate the results from our allocation check.
  //   - invalidListType: the list type doesn't exist.
  //   - hasAllocation: congrats, you have an allocation on this list.
  //   - invalidProof: the data passed is not the right leaf on the tree.
  //   - allocationExhausted: you had an allocation, but you've minted it already.
  enum AllocationCheck {
    invalidListType,
    hasAllocation,
    invalidProof,
    allocationExhausted
  }

  // Configuation options for this primary sale module.
  struct ListMintConfig {
    uint256 phaseMaxSupply;
    uint256 phaseStart;
    uint256 phaseEnd;
    uint256 metadropPerMintFee;
    uint256 metadropPrimaryShareInBasisPoints;
    bytes32 allowlist;
  }

  /** ====================================================================================================================
   *                                                    EVENTS
   * =====================================================================================================================
   */

  // Event issued when the merkle root is set.
  event MerkleRootSet(bytes32 merkleRoot);

  /** ====================================================================================================================
   *                                                   FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) listMintStatus  View of list mint status
   *
   * _____________________________________________________________________________________________________________________
   */
  function listMintStatus() external view returns (MintStatus status);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->LISTS
   * @dev (function) setList  Set the merkleroot
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param merkleRoot_        The bytes32 merkle root to set
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setList(bytes32 merkleRoot_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) listMint  Mint using the list
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              Position of the entry in the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets
         * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_      The timestamp of the signed message
   * ---------------------------------------------------------------------------------------------------------------------
   
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be checked as part of
   *                               antibot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageSignature_      The signed message from the backend oracle signer for validation as part of anti-bot
   *                               protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function listMint(
    uint256 position_,
    uint256 quantityEligible_,
    uint256 quantityToMint_,
    uint256 unitPrice_,
    bytes32[] calldata proof_,
    address recipient_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_,
    bytes calldata messageSignature_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) merkleListValid  Eligibility check for the merkleroot controlled minting. This can be called from
   * front-end (for example to control screen components that indicate if the connected address is eligible) as well as
   * from within the contract.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param addressToCheck_        The address we are checking
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              The position of the item in the allowlist
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param paymentValid_          If the payment is valid
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function merkleListValid(
    address addressToCheck_,
    uint256 position_,
    uint256 quantityEligible_,
    bytes32[] calldata proof_,
    uint256 unitPrice_,
    bool paymentValid_
  ) external view returns (bool success, address allowanceAddress);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) checkAllocation   Eligibility check for all lists. Will return a count of remaining allocation
   * (if any) and a status code.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param position_              Position of the entry in the list
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityEligible_      How many NFTs the caller is eligible to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The individual unit price of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param proof_                 The calculated proof to check passed details for the caller
   * ---------------------------------------------------------------------------------------------------------------------
   * @param addressToCheck_        The address we are checking for an allocation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function checkAllocation(
    uint256 position_,
    uint256 quantityEligible_,
    uint256 unitPrice_,
    bytes32[] calldata proof_,
    address addressToCheck_
  ) external view returns (uint256 allocation, AllocationCheck statusCode);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IPublicMintByMetadrop.sol. Interface for metadrop public mint primary sale module
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IConfigStructures} from "../../Global/IConfigStructures.sol";

interface IPublicMintByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    STRUCTS and ENUMS
   * =====================================================================================================================
   */
  // Configuation options for this primary sale module.
  struct PublicMintConfig {
    uint256 phaseMaxSupply;
    uint256 phaseStart;
    uint256 phaseEnd;
    uint256 metadropPerMintFee;
    uint256 metadropPrimaryShareInBasisPoints;
    uint256 publicPrice;
    uint256 maxPublicQuantity;
  }

  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */

  event PublicMintPriceUpdated(uint256 oldPrice, uint256 newPrice);

  /** ====================================================================================================================
   *                                                       FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) publicMintStatus  View of public mint status
   * _____________________________________________________________________________________________________________________
   */
  /**
   *
   * @dev publicMintStatus: View of public mint status
   *
   */
  function publicMintStatus() external view returns (MintStatus);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->SETUP
   * @dev (function) updatePublicMintPrice  Update the price per NFT for this drop (platform admin only)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPublicMintPrice_             The new price per mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function updatePublicMintPrice(uint256 newPublicMintPrice_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) publicMint  Public minting of tokens according to set config.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The number of NFTs being minted in this call
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageTimeStamp_      The timestamp of the signed message
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageHash_           The message hash signed by the trusted oracle signer. This will be checked as part of
   *                               antibot protection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageSignature_      The signed message from the backend oracle signer for validation as part of anti-bot
   *                               protection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function publicMint(
    uint256 quantityToMint_,
    address recipient_,
    uint256 messageTimeStamp_,
    bytes32 messageHash_,
    bytes calldata messageSignature_
  ) external payable;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IPrimaryVestingByMetadrop.sol. Interface for base primary vesting module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";
import {IErrors} from "../Global/IErrors.sol";

interface IPrimaryVestingByMetadrop is IErrors, IConfigStructures {
  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */
  event PayeeAdded(
    address account,
    uint256 shares,
    uint256 vestingPeriodInDays
  );
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /** ====================================================================================================================
   *                                                      FUNCTIONS
   * =====================================================================================================================
   */

  /**
   * @dev Getter for the total shares held by payees.
   */
  function sharesTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are vested.
   */
  function sharesProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of shares held by the project that are upfront.
   */
  function sharesProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function releasedETHTotal() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project vested.
   */
  function releasedETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of ETH release for the project upfront.
   */
  function releasedETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
   * contract.
   */
  function releasedERC20Total(IERC20 token) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project vested. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of `token` tokens already released to the project upfront. `token` should be the address of an
   * IERC20 contract.
   */
  function releasedERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for project address
   */
  function projectAddresses()
    external
    view
    returns (ProjectBeneficiary[] memory);

  /**
   * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountEth(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Calculates the amount of tokens that has already vested. Default implementation is a linear vesting curve.
   */
  function vestedAmountERC20(
    uint256 balance,
    uint256 timestamp
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable Ether.
   */
  function releasableETHProjectVested() external view returns (uint256);

  /**
   * @dev Getter for the amount of the project's upfront releasable Ether.
   */
  function releasableETHProjectUpfront() external view returns (uint256);

  /**
   * @dev Getter for the amount of project's vested releasable `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectVested(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Getter for the amount of project's releasable upfront `token` tokens. `token` should be the address of an
   * IERC20 contract.
   */
  function releasableERC20ProjectUpfront(
    IERC20 token
  ) external view returns (uint256);

  /**
   * @dev Triggers a transfer to the project of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function releaseProjectETH(uint256 gasLimit_) external;

  /**
   * @dev Triggers a transfer to the project of the amount of `token` tokens they are owed, according to their
   * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
   * contract.
   */
  function releaseProjectERC20(IERC20 token) external;
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.0.0)

/**
 *
 * @title IRoyaltyPaymentSplitterByMetadrop.sol. Interface for royalty module contract
 *
 * @author metadrop https://metadrop.com/
 *
 */
pragma solidity 0.8.19;

import {IERC20} from "../Global/OZ/SafeERC20.sol";
import {IConfigStructures} from "../Global/IConfigStructures.sol";

interface IRoyaltyPaymentSplitterByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                    ENUMS AND STRUCTS
   * =====================================================================================================================
   */
  struct RoyaltyPaymentSplitterConfig {
    address[] projectRoyaltyAddresses;
    uint256[] projectRoyaltySharesInBasisPoints;
    uint256 royaltyFromSalesInBasisPoints;
    uint256 metadropShareOfRoyaltiesInBasisPoints;
  }

  /** ====================================================================================================================
   *                                                        EVENTS
   * =====================================================================================================================
   */
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  /** ====================================================================================================================
   *                                                       FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseRoyaltyPaymentSplitter  Initialise data on the royalty contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyModule_                        Configuration object for this instance of vesting
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_                     The address for payments to the platform
   * ---------------------------------------------------------------------------------------------------------------------
   * @return royaltyFromSalesInBasisPoints_       The royalty share from sales in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseRoyaltyPaymentSplitter(
    RoyaltySplitterModuleConfig calldata royaltyModule_,
    address platformTreasury_
  ) external returns (uint96 royaltyFromSalesInBasisPoints_);
}