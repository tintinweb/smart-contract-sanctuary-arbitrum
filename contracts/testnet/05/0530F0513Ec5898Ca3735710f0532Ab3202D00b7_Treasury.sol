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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IBoardroom {
    function balanceOf(address _member) external view returns (uint256);

    function earned(address _member) external view returns (uint256);

    function canWithdraw(address _member) external view returns (bool);

    function canClaimReward(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getNativePrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.17;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "contracts/libraries/Babylonian.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/libraries/Operator.sol";
import "contracts/libraries/ContractGuard.sol";
import "contracts/interfaces/IBasisAsset.sol";
import "contracts/interfaces/IOracle.sol";
import "contracts/interfaces/IBoardroom.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

interface IRandomizer {
  function request(uint256 callbackGasLimit) external returns (uint256);

  function request(
    uint256 callbackGasLimit,
    uint256 confirmations
  ) external returns (uint256);

  function clientWithdrawTo(address _to, uint256 _amount) external;
}

interface IShareRewardPool {
  function massUpdatePools(bool _check) external;
}

interface IERC20Taxable {
  function setTaxOffice(address _taxOffice) external;
}

contract Treasury is ContractGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========= CONSTANT VARIABLES ======== */

  uint256 public constant PERIOD = 6 hours;
  /* ========== CHAINLINK VARIABLES ========== */

  mapping(uint256 => uint256) public randRequests;
  mapping(uint256 => uint256) private randResults;
  mapping(uint256 => uint256) public epochPeriods;

  // VRFCoordinatorV2Interface private immutable COORDINATOR;
  uint256 private constant ROLL_IN_PROGRESS = 23451837;

  //uint64 private immutable s_subscriptionId;
  address vrfCoordinator;
  //bytes32 private immutable s_keyHash;
  //uint32 private immutable callbackGasLimit;
  bool public state = false;
  uint16 requestConfirmations = 5;
  address s_owner;
  uint32 numWords = 3;
  uint32 randmax = 9;
  uint32 randmin = 3;
  uint32 randmaxboost = 25;
  uint32 randminboost = 10;
  uint32 randmaxperiod = 3;
  uint32 randminperiod = 1;

  event RequestRandomnessFulfilled(
    bytes32 indexed requestId,
    uint256 randomness
  );

  /* ========== STATE VARIABLES ========== */

  // governance
  address public operator;

  // flags
  bool public initialized = false;

  // epoch
  uint256 public startTime;
  uint256 public epoch = 0;
  uint256 public epochSupplyContractionLeft = 0;

  //randomizer
  IRandomizer public randomizer =
    IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc); // 0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc goerli
  // exclusions from total supply
  uint256[] public epochArray = [6, 7, 8, 9];
  uint256[] public epochArray2 = [3, 4, 5];
  uint256 public randomSelector = 5;

  bool public randomSwitch = true;
  address[] public excludedFromTotalSupply;

  // core components
  address public native;
  address public bond;
  address public share;
  address public deadAddress = 0x000000000000000000000000000000000000dEaD;

  address public boardroom;

  address public nativeOracle;
  address public shareRewardPool;

  // price
  uint256 public nativePriceOne;
  uint256 public nativePriceCeiling;

  uint256 public seigniorageSaved;

  uint256[] public supplyTiers;
  uint256[] public maxExpansionTiers;

  uint256 public maxSupplyExpansionPercent;
  uint256 public bondDepletionFloorPercent = 10000;
  uint256 public seigniorageExpansionFloorPercent;
  uint256 public maxSupplyContractionPercent;
  uint256 public maxDebtRatioPercent = 4000; // Upto 40% supply of BOND to purchase

  // 28 first epochs (1 week) with 4.5% expansion regardless of NATIVE price
  uint256 public bootstrapEpochs = 0;
  uint256 public bootstrapSupplyExpansionPercent = 250;

  /* =================== Added variables =================== */
  uint256 public previousEpochNativePrice;
  uint256 public maxDiscountRate; // when purchasing bond
  uint256 public maxPremiumRate; // when redeeming bond
  uint256 public discountPercent;
  uint256 public premiumThreshold = 110;
  uint256 public premiumPercent = 7000;
  uint256 public mintingFactorForPayingDebt; // print extra NATIVE during debt phase
  uint256 public day_checker = 25;
  address public daoFund;
  uint256 public daoFundSharedPercent = 200;
  address public weeklyLottery;
  uint256 public weeklyLotteryPercent = 20;
  address public toBurn;
  uint256 public burnPercent = 60;

  address public devFund;
  uint256 public devFundSharedPercent = 90;

  /* =================== Events =================== */

  event Initialized(address indexed executor, uint256 at);
  event BurnedBonds(address indexed from, uint256 bondAmount);
  event RedeemedBonds(
    address indexed from,
    uint256 nativeAmount,
    uint256 bondAmount
  );
  event BoughtBonds(
    address indexed from,
    uint256 nativeAmount,
    uint256 bondAmount
  );
  event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
  event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
  event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
  event DevFundFunded(uint256 timestamp, uint256 seigniorage);
  event WeeklyLotteryFunded(uint256 timestamp, uint256 seigniorage);
  event SendToBurn(uint256 timestamp, uint256 seigniorage);

  event RandomnessFulfilled(
    uint256 requestId,
    uint256 timestamp,
    uint256 epoch
  );

  /* =================== Modifier =================== */

  modifier onlyOperator() {
    require(operator == msg.sender, "Treasury: caller is not the operator");
    _;
  }

  modifier checkCondition() {
    require(block.timestamp >= startTime, "Treasury: not started yet");

    _;
  }

  modifier checkEpoch() {
    require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

    _;

    epoch = epoch.add(1);
    requestRandomWords(epoch);
    epochSupplyContractionLeft = (getNativePrice() > nativePriceCeiling)
      ? 0
      : getNativeCirculatingSupply().mul(maxSupplyContractionPercent).div(
        10000
      );
  }

  modifier checkOperator() {
    require(
      IBasisAsset(native).operator() == address(this) &&
        IBasisAsset(bond).operator() == address(this) &&
        IBasisAsset(share).operator() == address(this) &&
        Operator(boardroom).operator() == address(this),
      "Treasury: need more permission"
    );

    _;
  }

  modifier notInitialized() {
    require(!initialized, "Treasury: already initialized");

    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  // epoch
  function nextEpochPoint() public view returns (uint256) {
    uint256 multiplierHr = 60 * 60;

    if (epochPeriods[epoch] != 0 && epoch > 1) {
      uint256 sthtoreturn = startTime.add((PERIOD.mul(1)));

      for (uint256 i = 1; i < epoch; i++) {
        sthtoreturn = sthtoreturn.add(epochPeriods[i].mul(multiplierHr));
      }

      return sthtoreturn;
    }

    return startTime.add(epoch.mul(PERIOD));
  }

  // oracle
  function getNativePrice() public view returns (uint256 nativePrice) {
    try IOracle(nativeOracle).consult(native, 1e18) returns (uint144 price) {
      return uint256(price);
    } catch {
      revert("Treasury: failed to consult native price from the oracle");
    }
  }

  function getNativeUpdatedPrice() public view returns (uint256 _nativePrice) {
    try IOracle(nativeOracle).twap(native, 1e18) returns (uint144 price) {
      return uint256(price);
    } catch {
      revert("Treasury: failed to consult native price from the oracle");
    }
  }

  // budget
  function getReserve() public view returns (uint256) {
    return seigniorageSaved;
  }

  function getBurnableNativeLeft()
    public
    view
    returns (uint256 _burnableNativeLeft)
  {
    uint256 _nativePrice = getNativePrice();
    if (_nativePrice <= nativePriceOne) {
      uint256 _nativeSupply = getNativeCirculatingSupply();
      uint256 _bondMaxSupply = _nativeSupply.mul(maxDebtRatioPercent).div(
        10000
      );
      uint256 _bondSupply = IERC20(bond).totalSupply();
      if (_bondMaxSupply > _bondSupply) {
        uint256 _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
        uint256 _maxBurnableNative = _maxMintableBond.mul(_nativePrice).div(
          1e18
        );
        _burnableNativeLeft = Math.min(
          epochSupplyContractionLeft,
          _maxBurnableNative
        );
      }
    }
  }

  function getRedeemableBonds() public view returns (uint256 _redeemableBonds) {
    uint256 _nativePrice = getNativePrice();
    if (_nativePrice > nativePriceCeiling) {
      uint256 _totalNative = IERC20(native).balanceOf(address(this));
      uint256 _rate = getBondPremiumRate();
      if (_rate > 0) {
        _redeemableBonds = _totalNative.mul(1e18).div(_rate);
      }
    }
  }

  function getBondDiscountRate() public view returns (uint256 _rate) {
    uint256 _nativePrice = getNativePrice();
    if (_nativePrice <= nativePriceOne) {
      if (discountPercent == 0) {
        // no discount
        _rate = nativePriceOne;
      } else {
        uint256 _bondAmount = nativePriceOne.mul(1e18).div(_nativePrice); // to burn 1 NATIVE
        uint256 _discountAmount = _bondAmount
          .sub(nativePriceOne)
          .mul(discountPercent)
          .div(10000);
        _rate = nativePriceOne.add(_discountAmount);
        if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
          _rate = maxDiscountRate;
        }
      }
    }
  }

  function getBondPremiumRate() public view returns (uint256 _rate) {
    uint256 _nativePrice = getNativePrice();
    if (_nativePrice > nativePriceCeiling) {
      uint256 _nativePricePremiumThreshold = nativePriceOne
        .mul(premiumThreshold)
        .div(100);
      if (_nativePrice >= _nativePricePremiumThreshold) {
        //Price > 1.10
        uint256 _premiumAmount = _nativePrice
          .sub(nativePriceOne)
          .mul(premiumPercent)
          .div(10000);
        _rate = nativePriceOne.add(_premiumAmount);
        if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
          _rate = maxPremiumRate;
        }
      } else {
        // no premium bonus
        _rate = nativePriceOne;
      }
    }
  }

  /* ========== GOVERNANCE ========== */

  function initialize(
    address _native,
    address _bond,
    address _share,
    address _nativeOracle,
    address _boardroom,
    address _genesis,
    uint256 _startTime,
    address _shareRewardPool
  ) public notInitialized {
    native = _native;
    bond = _bond;
    share = _share;
    nativeOracle = _nativeOracle;
    boardroom = _boardroom;

    startTime = _startTime;
    shareRewardPool = _shareRewardPool;
    excludedFromTotalSupply = [_genesis, deadAddress];

    nativePriceOne = 1700000000000000; // Set the peg to 0.001
    nativePriceCeiling = nativePriceOne.mul(101).div(100); // Set the ceiling 1% above peg.

    // Dynamic max expansion percent
    supplyTiers = [
      0 ether,
      37860 ether,
      80932 ether,
      121399 ether,
      243046 ether,
      796640 ether,
      1499249 ether,
      3333332 ether,
      6000000 ether
    ];
    maxExpansionTiers = [600, 500, 400, 300, 200, 150, 100, 50, 25];

    maxSupplyExpansionPercent = 1000; // Upto 10% supply for expansion

    bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
    seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
    maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn NATIVE and mint BOND)
    // Upto 40% supply of BOND to purchase

    // First 28 epochs with 2.5% expansion

    // set seigniorageSaved to it's balance
    seigniorageSaved = IERC20(native).balanceOf(address(this));

    initialized = true;
    operator = msg.sender;

    setExtraFunds(
      msg.sender,
      200,
      msg.sender,
      90,
      msg.sender,
      60,
      msg.sender,
      20
    );

    if (epochPeriods[epoch] == 0) {
      requestRandomWords(epoch);
    }

    emit Initialized(msg.sender, block.number);
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setBoardroom(address _boardroom) external onlyOperator {
    boardroom = _boardroom;
  }

  function setNativeOracle(address _nativeOracle) external onlyOperator {
    nativeOracle = _nativeOracle;
  }

  function setNativePriceCeiling(
    uint256 _nativePriceCeiling
  ) external onlyOperator {
    require(
      _nativePriceCeiling >= nativePriceOne &&
        _nativePriceCeiling <= nativePriceOne.mul(120).div(100),
      "out of range"
    ); // [$1.0, $1.2]
    nativePriceCeiling = _nativePriceCeiling;
  }

  function setMaxSupplyExpansionPercents(
    uint256 _maxSupplyExpansionPercent
  ) external onlyOperator {
    require(
      _maxSupplyExpansionPercent >= 10 && _maxSupplyExpansionPercent <= 1000,
      "_maxSupplyExpansionPercent: out of range"
    ); // [0.1%, 10%]
    maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
  }

  function setSupplyTiersEntry(
    uint8 _index,
    uint256 _value
  ) external onlyOperator returns (bool) {
    require(_index >= 0, "Index has to be higher than 0");
    require(_index < 9, "Index has to be lower than count of tiers");
    if (_index > 0) {
      require(_value > supplyTiers[_index - 1]);
    }
    if (_index < 8) {
      require(_value < supplyTiers[_index + 1]);
    }
    supplyTiers[_index] = _value;
    return true;
  }

  function setMaxExpansionTiersEntry(
    uint8 _index,
    uint256 _value
  ) external onlyOperator returns (bool) {
    require(_index >= 0, "Index has to be higher than 0");
    require(_index < 9, "Index has to be lower than count of tiers");
    require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
    maxExpansionTiers[_index] = _value;
    return true;
  }

  function setBondDepletionFloorPercent(
    uint256 _bondDepletionFloorPercent
  ) external onlyOperator {
    require(
      _bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000,
      "out of range"
    ); // [5%, 100%]
    bondDepletionFloorPercent = _bondDepletionFloorPercent;
  }

  function setMaxSupplyContractionPercent(
    uint256 _maxSupplyContractionPercent
  ) external onlyOperator {
    require(
      _maxSupplyContractionPercent >= 100 &&
        _maxSupplyContractionPercent <= 1500,
      "out of range"
    ); // [0.1%, 15%]
    maxSupplyContractionPercent = _maxSupplyContractionPercent;
  }

  function setMaxDebtRatioPercent(
    uint256 _maxDebtRatioPercent
  ) external onlyOperator {
    require(
      _maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000,
      "out of range"
    ); // [10%, 100%]
    maxDebtRatioPercent = _maxDebtRatioPercent;
  }

  function setBootstrap(
    uint256 _bootstrapEpochs,
    uint256 _bootstrapSupplyExpansionPercent
  ) external onlyOperator {
    require(_bootstrapEpochs <= 120, "_bootstrapEpochs: out of range"); // <= 1 month
    require(
      _bootstrapSupplyExpansionPercent >= 100 &&
        _bootstrapSupplyExpansionPercent <= 1000,
      "_bootstrapSupplyExpansionPercent: out of range"
    ); // [1%, 10%]
    bootstrapEpochs = _bootstrapEpochs;
    bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
  }

  function setExtraFunds(
    address _daoFund,
    uint256 _daoFundSharedPercent,
    address _devFund,
    uint256 _devFundSharedPercent,
    address _LotteryFund,
    uint256 _LotteryFundSharedPercent,
    address _toBurn,
    uint256 _toBurnSharedPercent
  ) public onlyOperator {
    require(_daoFund != address(0), "zero");
    require(_daoFundSharedPercent <= 2500, "out of range"); // <= 25%
    require(_devFund != address(0), "zero");
    require(_devFundSharedPercent <= 2000, "out of range"); // <= 20%
    require(
      _daoFundSharedPercent
        .add(_LotteryFundSharedPercent)
        .add(_toBurnSharedPercent)
        .add(devFundSharedPercent) <= 10000,
      "out of range"
    );
    daoFund = _daoFund;
    daoFundSharedPercent = _daoFundSharedPercent;
    devFund = _devFund;
    devFundSharedPercent = _devFundSharedPercent;
    weeklyLottery = _LotteryFund;
    weeklyLotteryPercent = _LotteryFundSharedPercent;
    toBurn = _toBurn;
    burnPercent = _toBurnSharedPercent;
  }

  function setMaxDiscountRate(uint256 _maxDiscountRate) external onlyOperator {
    maxDiscountRate = _maxDiscountRate;
  }

  function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
    maxPremiumRate = _maxPremiumRate;
  }

  function setDiscountPercent(uint256 _discountPercent) external onlyOperator {
    require(_discountPercent <= 20000, "_discountPercent is over 200%");
    discountPercent = _discountPercent;
  }

  function setPremiumThreshold(
    uint256 _premiumThreshold
  ) external onlyOperator {
    require(
      _premiumThreshold >= nativePriceCeiling,
      "_premiumThreshold exceeds nativePriceCeiling"
    );
    require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
    premiumThreshold = _premiumThreshold;
  }

  function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
    require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
    premiumPercent = _premiumPercent;
  }

  function setMintingFactorForPayingDebt(
    uint256 _mintingFactorForPayingDebt
  ) external onlyOperator {
    require(
      _mintingFactorForPayingDebt >= 10000 &&
        _mintingFactorForPayingDebt <= 20000,
      "_mintingFactorForPayingDebt: out of range"
    ); // [100%, 200%]
    mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
  }

  /* ========== MUTABLE FUNCTIONS ========== */

  function _updateNativePrice() internal {
    try IOracle(nativeOracle).update() {} catch {}
  }

  function getNativeCirculatingSupply() public view returns (uint256) {
    IERC20 nativeErc20 = IERC20(native);
    uint256 totalSupply = nativeErc20.totalSupply();
    uint256 balanceExcluded = 0;
    for (
      uint8 entryId = 0;
      entryId < excludedFromTotalSupply.length;
      ++entryId
    ) {
      balanceExcluded = balanceExcluded.add(
        nativeErc20.balanceOf(excludedFromTotalSupply[entryId])
      );
    }
    return totalSupply.sub(balanceExcluded);
  }

  function buyBonds(
    uint256 _nativeAmount,
    uint256 targetPrice
  ) external onlyOneBlock checkCondition checkOperator {
    require(
      _nativeAmount > 0,
      "Treasury: cannot purchase bonds with zero amount"
    );

    uint256 nativePrice = getNativePrice();
    require(nativePrice == targetPrice, "Treasury: NATIVE price moved");
    require(
      nativePrice < nativePriceOne, // price < $1
      "Treasury: nativePrice not eligible for bond purchase"
    );

    require(
      _nativeAmount <= epochSupplyContractionLeft,
      "Treasury: not enough bond left to purchase"
    );

    uint256 _rate = getBondDiscountRate();
    require(_rate > 0, "Treasury: invalid bond rate");

    uint256 _bondAmount = _nativeAmount.mul(_rate).div(1e18);
    uint256 nativeSupply = getNativeCirculatingSupply();
    uint256 newBondSupply = IERC20(bond).totalSupply().add(_bondAmount);
    require(
      newBondSupply <= nativeSupply.mul(maxDebtRatioPercent).div(10000),
      "over max debt ratio"
    );

    IBasisAsset(native).burnFrom(msg.sender, _nativeAmount);
    IBasisAsset(bond).mint(msg.sender, _bondAmount);

    epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_nativeAmount);
    _updateNativePrice();

    emit BoughtBonds(msg.sender, _nativeAmount, _bondAmount);
  }

  function redeemBonds(
    uint256 _bondAmount,
    uint256 targetPrice
  ) external onlyOneBlock checkCondition checkOperator {
    require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

    uint256 nativePrice = getNativePrice();
    require(nativePrice == targetPrice, "Treasury: NATIVE price moved");
    require(
      nativePrice > nativePriceCeiling, // price > $1.01
      "Treasury: nativePrice not eligible for bond sale"
    );

    uint256 _rate = getBondPremiumRate();
    require(_rate > 0, "Treasury: invalid bond rate");

    uint256 _nativeAmount = _bondAmount.mul(_rate).div(1e18);
    require(
      IERC20(native).balanceOf(address(this)) >= _nativeAmount,
      "Treasury: treasury has no more budget"
    );

    seigniorageSaved = seigniorageSaved.sub(
      Math.min(seigniorageSaved, _nativeAmount)
    );

    IBasisAsset(bond).burnFrom(msg.sender, _bondAmount);
    IERC20(native).safeTransfer(msg.sender, _nativeAmount);

    _updateNativePrice();

    emit RedeemedBonds(msg.sender, _nativeAmount, _bondAmount);
  }

  function _sendToBoardroom(uint256 _amount) internal {
    IBasisAsset(native).mint(address(this), _amount);

    uint256 _daoFundSharedAmount = 0;
    if (daoFundSharedPercent > 0) {
      _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
      IERC20(native).transfer(daoFund, _daoFundSharedAmount);
      emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
    }

    uint256 _devFundSharedAmount = 0;
    if (devFundSharedPercent > 0) {
      _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
      IERC20(native).transfer(devFund, _devFundSharedAmount);
      emit DevFundFunded(block.timestamp, _devFundSharedAmount);
    }
    uint256 _toWeeklyLotteryAmount = 0;
    if (weeklyLotteryPercent > 0) {
      _toWeeklyLotteryAmount = _amount.mul(weeklyLotteryPercent).div(10000);
      IERC20(native).transfer(weeklyLottery, _toWeeklyLotteryAmount);
      emit WeeklyLotteryFunded(block.timestamp, _toWeeklyLotteryAmount);
    }
    uint256 _toBurnAmount = 0;
    if (burnPercent > 0) {
      _toBurnAmount = _amount.mul(burnPercent).div(10000);
      IERC20(native).transfer(toBurn, _toBurnAmount);
      emit SendToBurn(block.timestamp, _toBurnAmount);
    }

    _amount = _amount
      .sub(_daoFundSharedAmount)
      .sub(_devFundSharedAmount)
      .sub(_toWeeklyLotteryAmount)
      .sub(_toBurnAmount);

    IERC20(native).safeApprove(boardroom, 0);
    IERC20(native).safeApprove(boardroom, _amount);
    IBoardroom(boardroom).allocateSeigniorage(_amount);
    emit BoardroomFunded(block.timestamp, _amount);
  }

  function _calculateMaxSupplyExpansionPercent(
    uint256 _nativeSupply
  ) internal returns (uint256) {
    for (uint8 tierId = 8; tierId >= 0; --tierId) {
      if (_nativeSupply >= supplyTiers[tierId]) {
        maxSupplyExpansionPercent = maxExpansionTiers[tierId];
        break;
      }
    }
    return maxSupplyExpansionPercent;
  }

  function allocateSeigniorage()
    external
    onlyOneBlock
    checkCondition
    checkEpoch
    checkOperator
  {
    _updateNativePrice();
    previousEpochNativePrice = getNativePrice();
    uint256 nativeSupply = getNativeCirculatingSupply().sub(seigniorageSaved);
    if (epoch < bootstrapEpochs) {
      // 28 first epochs with 4.5% expansion
      _sendToBoardroom(
        nativeSupply.mul(bootstrapSupplyExpansionPercent).div(10000)
      );
    } else {
      if (previousEpochNativePrice > nativePriceCeiling) {
        // Expansion ($NATIVE Price > 1 $MIM): there is some seigniorage to be allocated
        uint256 bondSupply = IERC20(bond).totalSupply();
        uint256 _percentage = previousEpochNativePrice.sub(nativePriceOne);
        uint256 _savedForBond;
        uint256 _savedForBoardroom;
        uint256 _mse = _calculateMaxSupplyExpansionPercent(nativeSupply).mul(
          1e14
        );
        if (_percentage > _mse) {
          _percentage = _mse;
        }
        if (
          seigniorageSaved >=
          bondSupply.mul(bondDepletionFloorPercent).div(10000)
        ) {
          // saved enough to pay debt, mint as usual rate
          _savedForBoardroom = nativeSupply.mul(_percentage).div(1e18);
        } else {
          // have not saved enough to pay debt, mint more
          uint256 _seigniorage = nativeSupply.mul(_percentage).div(1e18);
          _savedForBoardroom = _seigniorage
            .mul(seigniorageExpansionFloorPercent)
            .div(10000);
          _savedForBond = _seigniorage.sub(_savedForBoardroom);
          if (mintingFactorForPayingDebt > 0) {
            _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(
              10000
            );
          }
        }
        if (_savedForBoardroom > 0) {
          _sendToBoardroom(_savedForBoardroom);
        }
        if (_savedForBond > 0) {
          seigniorageSaved = seigniorageSaved.add(_savedForBond);
          IBasisAsset(native).mint(address(this), _savedForBond);
          emit TreasuryFunded(block.timestamp, _savedForBond);
        }
      }
    }
  }

  function boardroomSetOperator(address _operator) external onlyOperator {
    IBoardroom(boardroom).setOperator(_operator);
  }

  function boardroomSetLockUp(
    uint256 _withdrawLockupEpochs,
    uint256 _rewardLockupEpochs
  ) external onlyOperator {
    IBoardroom(boardroom).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
  }

  function boardroomAllocateSeigniorage(uint256 amount) external onlyOperator {
    IBoardroom(boardroom).allocateSeigniorage(amount);
  }

  //Epoch Period Randomization Function

  function requestRandomWords(uint256 _epoch) internal returns (uint256) {
    require(epochPeriods[_epoch] != ROLL_IN_PROGRESS, "In progress");
    if (randomSwitch) {
      uint256 requestId = randomizer.request(50000);

      randRequests[requestId] = _epoch;
      epochPeriods[_epoch] = ROLL_IN_PROGRESS;
      emit RequestRandomnessFulfilled(bytes32(requestId), numWords);
      return requestId;
    } else {
      epochPeriods[_epoch] = 6;
      return 0;
    }
  }

  function randomizerCallback(uint256 _id, bytes32 _value) external {
    //Callback can only be called by randomizer
    require(msg.sender == address(randomizer), "Caller not Randomizer");
    uint256 randVal = (uint256(_value) % 100);

    if (randVal > randomSelector) {
      epochPeriods[randRequests[_id]] = epochArray[uint256(_value) % 4];
    } else {
      epochPeriods[randRequests[_id]] = epochArray2[uint256(_value) % 3];
    }

    emit RandomnessFulfilled(_id, epoch, block.timestamp);
  }

  function setRandomSelector(uint256 _randomSelector) external onlyOperator {
    require(
      _randomSelector <= 100 && _randomSelector > 0,
      "Random Selector must be less than 100 AND greater than 0"
    );
    randomSelector = _randomSelector;
  }

  function setRandomSwitch(bool _randomSwitch) external onlyOperator {
    randomSwitch = _randomSwitch;
  }

  function setLevelTaxOffice(address _taxOffice) external onlyOperator {
    IERC20Taxable(native).setTaxOffice(_taxOffice);
  }

  function setLodgeTaxOffice(address _taxOffice) external onlyOperator {
    IERC20Taxable(share).setTaxOffice(_taxOffice);
  }

  function setEpochArray(uint256[] memory _epochArray) external onlyOperator {
    epochArray = _epochArray;
  }

  function setEpochArray2(uint256[] memory _epochArray2) external onlyOperator {
    epochArray2 = _epochArray2;
  }
}