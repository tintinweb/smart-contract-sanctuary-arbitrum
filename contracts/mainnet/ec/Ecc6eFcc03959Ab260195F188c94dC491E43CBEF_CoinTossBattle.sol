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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {PvPGame} from "./PvPGame.sol";

// import "hardhat/console.sol";

/// @title BetSwirl's Coin Toss battle game
/// @notice The game is played with a two-sided coin. The game's goal is to guess whether the lucky coin face will be Heads or Tails.
/// @author Romuald Hog
contract CoinTossBattle is PvPGame {
    /// @notice Coin Toss bet information struct.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin face.
    /// @dev Coin faces: true = Tails, false = Heads.
    struct CoinTossBattleBet {
        bool face;
        bool rolled;
    }

    /// @notice Maps bets IDs to CoinTossBattleBet struct.
    mapping(uint24 => CoinTossBattleBet) public coinTossBattleBets;

    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param player Address of the gamer.
    /// @param opponent Address of the opponent.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param face The chosen coin face.
    event PlaceBet(
        uint24 id,
        address indexed player,
        address opponent,
        address indexed token,
        uint256 amount,
        bool face
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param players Players addresses.
    /// @param winner Address of the winner.
    /// @param token Address of the token.
    /// @param betAmount The bet amount.
    /// @param face The chosen coin face.
    /// @param rolled The rolled coin face.
    /// @param payout The payout amount.
    event Roll(
        uint24 indexed id,
        address[] players,
        address winner,
        address indexed token,
        uint256 betAmount,
        bool face,
        bool rolled,
        uint256 payout
    );

    /// @notice Initialize the game base contract.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param store Address of the PvP Games Store.
    constructor(
        address chainlinkCoordinatorAddress,
        address store
    ) PvPGame(chainlinkCoordinatorAddress, store) {}

    function betMaxSeats(uint24) public pure override returns (uint256) {
        return 2;
    }

    function betMinSeats(uint24) public pure override returns (uint256) {
        return 2;
    }

    /// @notice Creates a new bet and stores the chosen coin face.
    /// @param face The chosen coin face.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    function wager(
        bool face,
        address token,
        uint256 tokenAmount,
        address opponent,
        bytes calldata nfts
    ) external payable whenNotPaused {
        address[] memory opponents;
        if (opponent != address(0)) {
            opponents = new address[](1);
            opponents[0] = opponent;
        } else {
            opponents = new address[](0);
        }

        Bet memory bet = _newBet(token, tokenAmount, opponents, nfts);

        coinTossBattleBets[bet.id].face = face;

        emit PlaceBet(
            bet.id,
            bet.seats[0],
            opponent,
            bet.token,
            bet.amount,
            face
        );
    }

    function joinGame(uint24 id) external payable {
        _joinGame(id, 1);
    }

    /// @notice Resolves the bet using the Chainlink randomness.
    /// @param requestId The bet ID.
    /// @param randomWords Random words list. Contains only one for this game.
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint24 id = _betsByVrfRequestId[requestId];
        CoinTossBattleBet storage coinTossBattleBet = coinTossBattleBets[id];
        Bet storage bet = bets[id];

        uint256 rolled = randomWords[0] % 2;

        bool[2] memory coinSides = [false, true];
        bool rolledCoinSide = coinSides[rolled];
        coinTossBattleBet.rolled = rolledCoinSide;
        address[] memory winners = new address[](1);
        winners[0] = rolledCoinSide == coinTossBattleBet.face
            ? bet.seats[0]
            : bet.seats[1];
        uint256 payout = _resolveBet(bet, winners, randomWords[0]);

        emit Roll(
            bet.id,
            bet.seats,
            winners[0],
            bet.token,
            bet.amount,
            coinTossBattleBet.face,
            rolledCoinSide,
            payout
        );
    }

    function getCoinTossBattleBet(
        uint24 id
    )
        external
        view
        returns (CoinTossBattleBet memory coinTossBattleBet, Bet memory bet)
    {
        return (coinTossBattleBets[id], bets[id]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPvPGamesStore {

    /// @notice Token's house edge allocations struct.
    /// The games house edge is split into several allocations.
    /// The allocated amounts stays in the controct until authorized parties withdraw. They are subtracted from the balance.
    /// @param dividend Rate to be allocated as staking rewards, on bet payout.
    /// @param treasury Rate to be allocated to the treasury, on bet payout.
    /// @param team Rate to be allocated to the team, on bet payout.
    /// @param dividendAmount The number of tokens to be sent as staking rewards.
    /// @param treasuryAmount The number of tokens to be sent to the treasury.
    /// @param teamAmount The number of tokens to be sent to the team.
    struct HouseEdgeSplit {
        uint16 dividend;
        uint16 treasury;
        uint16 team;
        uint16 initiator;
    }

    /// @notice Token struct.
    /// @param houseEdge House edge rate.
    /// @param pendingCount Number of pending bets.
    /// @param VRFFees Chainlink's VRF collected fees amount.
    struct Token {
        uint64 vrfSubId;
        HouseEdgeSplit houseEdgeSplit;
    }

    /// @notice Token's metadata struct. It contains additional information from the ERC20 token.
    /// @dev Only used on the `getTokens` getter for the front-end.
    /// @param decimals Number of token's decimals.
    /// @param tokenAddress Contract address of the token.
    /// @param name Name of the token.
    /// @param symbol Symbol of the token.
    /// @param token Token data.
    struct TokenMetadata {
        uint8 decimals;
        address tokenAddress;
        string name;
        string symbol;
        Token token;
    }

  function setHouseEdgeSplit(
        address token,
        uint16 dividend,
        uint16 treasury,
        uint16 team,
        uint16 initiator
    ) external;

  function addToken(address token) external;
  function setVRFSubId(address token, uint64 vrfSubId) external;
  function setTeamWallet(address teamWallet) external;
  function getTokenConfig(address token) external view returns (Token memory config);
  function getTreasuryAndTeamAddresses() external view returns (address, address);
  function getTokensAddresses() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import {IPvPGamesStore} from "./IPvPGamesStore.sol";

// import "hardhat/console.sol";

/// @title PvPGame base contract
/// @author BetSwirl.eth
/// @notice This should be parent contract of each games.
/// It defines all the games common functions and state variables.
/// @dev All rates are in basis point. Chainlink VRF v2 is used.
abstract contract PvPGame is
    Pausable,
    Multicall,
    VRFConsumerBaseV2,
    ReentrancyGuard,
    Ownable
{
    using SafeERC20 for IERC20;

    /// @notice Bet information struct.
    /// @param token Address of the token.
    /// @param resolved Whether the bet has been resolved.
    /// @param canceled Whether the bet has been canceled.
    /// @param id Bet ID.
    /// @param vrfRequestTimestamp Block timestamp of the VRF request used to refund in case.
    /// @param houseEdge House edge that'll be charged.
    /// @param opponents Addresses of the opponents.
    /// @param seats Players addresses of each seat.
    /// @param vrfRequestId Request ID generated by Chainlink VRF.
    /// @param amount The buy-in amount.
    /// @param payout The total paid amount, minus fees if applied.
    /// @param pot The current prize pool is the sum of all buy-ins from players.
    struct Bet {
        address token;
        bool resolved;
        bool canceled;
        uint24 id;
        uint32 vrfRequestTimestamp;
        uint16 houseEdge;
        address[] opponents;
        address[] seats;
        uint256 vrfRequestId;
        uint256 amount;
        uint256 payout;
        uint256 pot;
    }
    /// @notice stores the NFTs params
    struct NFTs {
        IERC721 nftContract;
        uint256[] tokenIds;
        address[] to;
    }

    /// @notice Maps bet ID -> NFTs struct.
    mapping(uint24 => NFTs[]) public betNFTs;

    /// @notice Maps bet ID -> NFT contract -> token ID for claimed NFTs
    mapping(uint24 => mapping(IERC721 => mapping(uint256 => bool)))
        public claimedNFTs;

    /// @notice Token's house edge allocations struct.
    /// The games house edge is split into several allocations.
    /// The allocated amounts stays in the contract until authorized parties withdraw.
    /// NB: The initiator allocation is stored on the `payouts` mapping.
    /// @param dividendAmount The number of tokens to be sent as staking rewards.
    /// @param treasuryAmount The number of tokens to be sent to the treasury.
    /// @param teamAmount The number of tokens to be sent to the team.
    struct HouseEdgeSplit {
        uint256 dividendAmount;
        uint256 treasuryAmount;
        uint256 teamAmount;
    }

    /// @notice Token struct.
    /// @param houseEdge House edge rate.
    /// @param VRFCallbackGasLimit How much gas is needed in the Chainlink VRF callback.
    /// @param houseEdgeSplit House edge allocations.
    struct Token {
        uint16 houseEdge;
        uint32 VRFCallbackGasLimit;
        HouseEdgeSplit houseEdgeSplit;
    }

    /// @notice Maps tokens addresses to token configuration.
    mapping(address => Token) public tokens;

    /// @notice Maximum number of NFTs per game.
    uint16 public maxNFTs;

    /// @notice Chainlink VRF configuration struct.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2 deployed contract.
    struct ChainlinkConfig {
        uint16 requestConfirmations;
        bytes32 keyHash;
        VRFCoordinatorV2Interface chainlinkCoordinator;
    }
    /// @notice Chainlink VRF configuration state.
    ChainlinkConfig private _chainlinkConfig;

    /// @notice The PvPGamesStore contract that contains the tokens configuration.
    IPvPGamesStore public pvpGamesStore;

    /// @notice Address allowed to harvest dividends.
    address public harvester;

    /// @notice Maps bets IDs to Bet information.
    mapping(uint24 => Bet) public bets;

    /// @notice Bet ID nonce.
    uint24 public betId = 1;

    /// @notice Maps VRF request IDs to bet ID.
    mapping(uint256 => uint24) internal _betsByVrfRequestId;

    /// @notice Maps user -> token -> amount for due payouts
    mapping(address => mapping(address => uint256)) public payouts;

    /// @notice maps bet id -> player address -> played
    mapping(uint24 => mapping(address => bool)) private _opponentPlayed;

    /// @notice Emitted after the max seats is set.
    event SetMaxNFTs(uint16 maxNFTs);

    /// @notice Emitted after the Chainlink config is set.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    event SetChainlinkConfig(uint16 requestConfirmations, bytes32 keyHash);

    /// @notice Emitted after the Chainlink callback gas limit is set for a token.
    /// @param token Address of the token.
    /// @param callbackGasLimit New Chainlink VRF callback gas limit.
    event SetVRFCallbackGasLimit(address token, uint32 callbackGasLimit);

    event AddNFTsPrize(
        uint24 indexed id,
        IERC721 nftContract,
        uint256[] tokenIds
    );
    event WonNFTs(uint24 indexed id, IERC721 nftContract, address[] winners);
    event ClaimedNFT(uint24 indexed id, IERC721 nftContract, uint256 tokenId);

    /// @notice Emitted after the bet amount is transfered to the user.
    /// @param id The bet ID.
    /// @param seats Address of the gamers.
    /// @param amount Number of tokens refunded.
    event BetRefunded(uint24 indexed id, address[] seats, uint256 amount);

    /// @notice Emitted after the bet is canceled.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param amount Number of tokens refunded.
    event BetCanceled(uint24 id, address user, uint256 amount);

    /// @notice Emitted after the bet is started.
    /// @param id The bet ID.
    event GameStarted(uint24 indexed id);

    /// @notice Emitted after a player joined seat(s)
    /// @param id The bet ID.
    /// @param player Address of the player.
    /// @param pot total played
    /// @param received Amount received
    /// @param seatsNumber Number of seats.
    event Joined(
        uint24 indexed id,
        address player,
        uint256 pot,
        uint256 received,
        uint16 seatsNumber
    );

    /// @notice Emitted after the house edge is set for a token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    event SetHouseEdge(address token, uint16 houseEdge);

    /// @notice Emitted when a new harvester is set.
    event HarvesterSet(address newHarvester);

    /// @notice Emitted after the token's treasury and team allocations are distributed.
    /// @param token Address of the token.
    /// @param treasuryAmount The number of tokens sent to the treasury.
    /// @param teamAmount The number of tokens sent to the team.
    event HouseEdgeDistribution(
        address token,
        uint256 treasuryAmount,
        uint256 teamAmount
    );

    /// @notice Emitted after the token's dividend allocation is distributed.
    /// @param token Address of the token.
    /// @param amount The number of tokens sent to the Harvester.
    event HarvestDividend(address token, uint256 amount);

    /// @notice Emitted after the token's house edge is allocated.
    /// @param token Address of the token.
    /// @param dividend The number of tokens allocated as staking rewards.
    /// @param treasury The number of tokens allocated to the treasury.
    /// @param team The number of tokens allocated to the team.
    event AllocateHouseEdgeAmount(
        address token,
        uint256 dividend,
        uint256 treasury,
        uint256 team,
        uint256 initiator
    );

    /// @notice Emitted after a player claimed his payouts.
    /// @param user Address of the token.
    /// @param token The number of tokens allocated as staking rewards.
    /// @param amount The number of tokens allocated to the treasury.
    event PayoutsClaimed(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /// @notice Bet provided doesn't exist or was already resolved.
    error NotPendingBet();

    /// @notice Bet isn't resolved yet.
    error NotFulfilled();

    /// @notice Token is not allowed.
    error ForbiddenToken();

    /// @notice Reverting error when sender isn't allowed.
    error AccessDenied();

    /// @notice Reverting error when provided address isn't valid.
    error InvalidAddress();

    /// @notice Bet amount isn't enough to accept bet.
    /// @param betAmount Bet amount.
    error WrongBetAmount(uint256 betAmount);

    /// @notice User isn't one of the defined bet opponents.
    /// @param user The unallowed opponent address.
    error InvalidOpponent(address user);

    /// @notice Wrong number of seat to launch the game.
    error WrongSeatsNumber();

    /// @notice The maximum of seats is reached
    error TooManySeats();

    /// @notice The maximum of NFTs is reached
    error TooManyNFTs();

    /// @notice Initialize contract's state variables and VRF Consumer.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param pvpGamesStoreAddress The PvPGamesStore address.
    constructor(
        address chainlinkCoordinatorAddress,
        address pvpGamesStoreAddress
    ) VRFConsumerBaseV2(chainlinkCoordinatorAddress) {
        if (
            chainlinkCoordinatorAddress == address(0) ||
            pvpGamesStoreAddress == address(0)
        ) {
            revert InvalidAddress();
        }
        pvpGamesStore = IPvPGamesStore(pvpGamesStoreAddress);
        _chainlinkConfig.chainlinkCoordinator = VRFCoordinatorV2Interface(
            chainlinkCoordinatorAddress
        );
    }

    function setMaxNFTs(uint16 _maxNFTs) external onlyOwner {
        maxNFTs = _maxNFTs;
        emit SetMaxNFTs(_maxNFTs);
    }

    function _transferNFTs(uint24 id, bytes memory nfts) private {
        (IERC721[] memory nftContracts, uint256[][] memory tokenIds) = abi
            .decode(nfts, (IERC721[], uint256[][]));
        uint256 NFTsCount;
        for (uint256 i = 0; i < nftContracts.length; i++) {
            IERC721 nftContract = nftContracts[i];
            uint256[] memory nftContractTokenIds = tokenIds[i];
            betNFTs[id].push();
            betNFTs[id][i].nftContract = nftContract;
            betNFTs[id][i].tokenIds = nftContractTokenIds;
            for (uint256 j = 0; j < nftContractTokenIds.length; j++) {
                nftContract.transferFrom(
                    msg.sender,
                    address(this),
                    nftContractTokenIds[j]
                );
                NFTsCount++;
                if (NFTsCount > maxNFTs) {
                    revert TooManyNFTs();
                }
            }
            emit AddNFTsPrize(id, nftContract, nftContractTokenIds);
        }
    }

    function getBetNFTs(uint24 id) external view returns (NFTs[] memory) {
        return betNFTs[id];
    }

    /// @notice Creates a new bet, transfer the ERC20 tokens to the contract.
    /// @param tokenAddress Address of the token.
    /// @param tokenAmount The number of tokens bet.
    /// @param opponents The defined opponents.
    /// @return A new Bet struct information.
    function _newBet(
        address tokenAddress,
        uint256 tokenAmount,
        address[] memory opponents,
        bytes memory nfts
    ) internal whenNotPaused nonReentrant returns (Bet memory) {
        uint16 houseEdge = tokens[tokenAddress].houseEdge;
        if (houseEdge == 0) {
            revert ForbiddenToken();
        }

        bool isGasToken = tokenAddress == address(0);
        uint256 betAmount = isGasToken ? msg.value : tokenAmount;

        uint256 received = betAmount;
        if (!isGasToken) {
            uint256 balanceBefore = IERC20(tokenAddress).balanceOf(
                address(this)
            );
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                betAmount
            );
            uint256 balanceAfter = IERC20(tokenAddress).balanceOf(
                address(this)
            );
            received = balanceAfter - balanceBefore;
        }

        // Create bet
        uint24 id = betId++;
        Bet memory newBet = Bet({
            resolved: false,
            canceled: false,
            opponents: opponents,
            seats: new address[](1),
            token: tokenAddress,
            id: id,
            vrfRequestId: 0,
            amount: betAmount,
            vrfRequestTimestamp: 0,
            payout: 0,
            pot: received,
            houseEdge: houseEdge
        });

        newBet.seats[0] = msg.sender;
        bets[id] = newBet;

        _transferNFTs(id, nfts);

        return newBet;
    }

    function betMinSeats(uint24 betId) public view virtual returns (uint256);

    function betMaxSeats(uint24 betId) public view virtual returns (uint256);

    function gameCanStart(uint24) public view virtual returns (bool) {
        return true;
    }

    function _joinGame(uint24 id, uint16 seatsNumber) internal nonReentrant {
        Bet storage bet = bets[id];
        uint256 _maxSeats = betMaxSeats(id);
        if (bet.resolved || bet.vrfRequestId != 0) {
            revert NotPendingBet();
        }
        uint256 seatsLength = bet.seats.length;
        if (seatsLength + seatsNumber > _maxSeats) {
            revert TooManySeats();
        }
        address user = msg.sender;

        address[] memory opponents = bet.opponents;
        uint256 opponentsLength = opponents.length;
        // Only check if player is in the opponent list if there is one.
        if (opponentsLength > 0) {
            bool included = false;
            for (uint256 i = 0; i < opponentsLength; i++) {
                if (opponents[i] == user) {
                    included = true;
                    break;
                }
            }
            if (!included) {
                revert InvalidOpponent(user);
            }
            if (!_opponentPlayed[id][user]) {
                _opponentPlayed[id][user] = true;
            }
        }

        address tokenAddress = bet.token;
        uint256 received = 0;
        if (tokenAddress == address(0)) {
            received = msg.value;
            if (received != bet.amount * seatsNumber) {
                revert WrongBetAmount(msg.value);
            }
        } else {
            uint256 balanceBefore = IERC20(tokenAddress).balanceOf(
                address(this)
            );
            IERC20(tokenAddress).safeTransferFrom(
                user,
                address(this),
                bet.amount * seatsNumber
            );
            uint256 balanceAfter = IERC20(tokenAddress).balanceOf(
                address(this)
            );
            received = balanceAfter - balanceBefore;
        }

        for (uint16 i = 0; i < seatsNumber; i++) {
            bet.seats.push(user);
        }
        seatsLength = bet.seats.length;

        bet.pot += received;

        if (
            seatsLength == _maxSeats ||
            (opponentsLength > 0 && _allOpponentsHavePlayed(id, opponents))
        ) {
            _launchGame(id);
        }
        emit Joined(id, user, bet.pot, received, seatsNumber);
    }

    function _allOpponentsHavePlayed(
        uint24 id,
        address[] memory opponents
    ) private view returns (bool) {
        for (uint256 i = 0; i < opponents.length; i++) {
            if (!_opponentPlayed[id][opponents[i]]) {
                return false;
            }
        }
        return true;
    }

    function _cleanOpponentsList(
        uint24 id,
        address[] memory opponents
    ) private {
        for (uint256 i = 0; i < opponents.length; i++) {
            delete _opponentPlayed[id][opponents[i]];
        }
    }

    function launchGame(uint24 id) external {
        Bet storage bet = bets[id];
        if (bet.seats.length < betMinSeats(id)) {
            revert WrongSeatsNumber();
        }
        if (bet.resolved || bet.vrfRequestId != 0) {
            revert NotPendingBet();
        }
        if (!gameCanStart(id)) {
            revert NotPendingBet();
        }
        _launchGame(id);
    }

    function _launchGame(uint24 id) private {
        Bet storage bet = bets[id];
        address tokenAddress = bet.token;
        IPvPGamesStore.Token memory token = pvpGamesStore.getTokenConfig(
            tokenAddress
        );

        uint256 requestId = _chainlinkConfig
            .chainlinkCoordinator
            .requestRandomWords(
                _chainlinkConfig.keyHash,
                token.vrfSubId,
                _chainlinkConfig.requestConfirmations,
                tokens[tokenAddress].VRFCallbackGasLimit,
                1
            );
        bet.vrfRequestId = requestId;
        bet.vrfRequestTimestamp = uint32(block.timestamp);
        _betsByVrfRequestId[requestId] = id;

        emit GameStarted(id);
    }

    function cancelBet(uint24 id) external {
        Bet storage bet = bets[id];
        if (bet.resolved || bet.id == 0) {
            revert NotPendingBet();
        } else if (bet.seats.length > 1) {
            revert NotFulfilled();
        } else if (bet.seats[0] != msg.sender && owner() != msg.sender) {
            revert AccessDenied();
        }

        bet.canceled = true;
        bet.resolved = true;
        bet.payout = bet.pot;

        if (bet.opponents.length > 0) _cleanOpponentsList(id, bet.opponents);

        address host = bet.seats[0];
        payouts[host][bet.token] += bet.payout;

        NFTs[] storage nfts = betNFTs[bet.id];
        for (uint256 i = 0; i < nfts.length; i++) {
            NFTs storage NFT = nfts[i];
            for (uint256 j = 0; j < NFT.tokenIds.length; j++) {
                NFT.to.push(host);
            }
        }

        emit BetCanceled(id, host, bet.payout);
    }

    function claimNFTs(uint24 _betId) external {
        NFTs[] memory nfts = betNFTs[_betId];
        for (uint256 i = 0; i < nfts.length; i++) {
            for (uint256 j = 0; j < nfts[i].tokenIds.length; j++) {
                claimNFT(_betId, i, j);
            }
        }
    }

    function claimNFT(uint24 _betId, uint256 nftIndex, uint256 tokenId) public {
        NFTs memory nft = betNFTs[_betId][nftIndex];
        if (!claimedNFTs[_betId][nft.nftContract][tokenId]) {
            claimedNFTs[_betId][nft.nftContract][tokenId] = true;
            nft.nftContract.transferFrom(
                address(this),
                nft.to[tokenId],
                nft.tokenIds[tokenId]
            );
            emit ClaimedNFT(_betId, nft.nftContract, tokenId);
        }
    }

    function claimAll(address user) external {
        address[] memory tokensList = pvpGamesStore.getTokensAddresses();
        for (uint256 i = 0; i < tokensList.length; i++) {
            claim(user, tokensList[i]);
        }
    }

    function claim(address user, address token) public {
        uint256 amount = payouts[user][token];
        if (amount > 0) {
            delete payouts[user][token];

            _safeTransfer(payable(user), token, amount);

            emit PayoutsClaimed(user, token, amount);
        }
    }

    /// @notice Refunds the bet to the user if the Chainlink VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint24 id) external {
        Bet storage bet = bets[id];
        if (
            bet.resolved || bet.vrfRequestTimestamp == 0 || bet.seats.length < 2
        ) {
            revert NotPendingBet();
        } else if (block.timestamp < bet.vrfRequestTimestamp + 60 * 60 * 24) {
            revert NotFulfilled();
        } else if (bet.seats[0] != msg.sender && owner() != msg.sender) {
            revert AccessDenied();
        }

        bet.resolved = true;
        bet.payout = bet.pot;

        if (bet.opponents.length > 0) _cleanOpponentsList(id, bet.opponents);

        // Refund players
        uint256 refundAmount = bet.pot / bet.seats.length;
        for (uint256 i = 0; i < bet.seats.length; i++) {
            payouts[bet.seats[i]][bet.token] += refundAmount;
        }

        address host = bet.seats[0];
        NFTs[] storage nfts = betNFTs[bet.id];
        for (uint256 i = 0; i < nfts.length; i++) {
            NFTs storage NFT = nfts[i];
            for (uint256 j = 0; j < NFT.tokenIds.length; j++) {
                NFT.to.push(host);
            }
        }

        emit BetRefunded(id, bet.seats, bet.payout);
    }

    /// @notice Resolves the bet based on the game child contract result.
    /// @param bet The Bet struct information.
    /// @param winners List of winning addresses
    /// @return The payout amount per winner.
    function _resolveBet(
        Bet storage bet,
        address[] memory winners,
        uint256 randomWord
    ) internal nonReentrant returns (uint256) {
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        }
        bet.resolved = true;

        address token = bet.token;
        uint256 payout = bet.pot;
        uint256 fee = (bet.houseEdge * payout) / 10000;
        payout -= fee;
        bet.payout = payout;

        _allocateHouseEdge(token, fee, payable(bet.seats[0]));

        if (bet.opponents.length > 0) {
            _cleanOpponentsList(bet.id, bet.opponents);
        }

        uint256 payoutPerWinner = payout / winners.length;
        for (uint256 i = 0; i < winners.length; i++) {
            payouts[winners[i]][token] += payoutPerWinner;
        }

        // Distribute NFTs
        NFTs[] storage nfts = betNFTs[bet.id];
        for (uint256 i = 0; i < nfts.length; i++) {
            NFTs storage NFT = nfts[i];
            for (uint256 j = 0; j < NFT.tokenIds.length; j++) {
                uint256 winnerIndex = uint256(
                    keccak256(abi.encode(randomWord, i, j))
                ) % bet.seats.length;
                NFT.to.push(bet.seats[winnerIndex]);
            }
            if (NFT.to.length != 0) {
                emit WonNFTs(bet.id, NFT.nftContract, NFT.to);
            }
        }

        return payout;
    }

    /// @notice Sets the game house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    /// @dev The house edge rate couldn't exceed 4%.
    function setHouseEdge(address token, uint16 houseEdge) external onlyOwner {
        tokens[token].houseEdge = houseEdge;
        emit SetHouseEdge(token, houseEdge);
    }

    /// @notice Sets the Chainlink VRF V2 configuration.
    /// @param callbackGasLimit How much gas is needed in the Chainlink VRF callback.
    function setVRFCallbackGasLimit(
        address token,
        uint32 callbackGasLimit
    ) external onlyOwner {
        tokens[token].VRFCallbackGasLimit = callbackGasLimit;
        emit SetVRFCallbackGasLimit(token, callbackGasLimit);
    }

    /// @notice Pauses the contract to disable new bets.
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Sets the Chainlink VRF V2 configuration.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    function setChainlinkConfig(
        uint16 requestConfirmations,
        bytes32 keyHash
    ) external onlyOwner {
        _chainlinkConfig.requestConfirmations = requestConfirmations;
        _chainlinkConfig.keyHash = keyHash;
        emit SetChainlinkConfig(requestConfirmations, keyHash);
    }

    /// @notice Returns the Chainlink VRF config.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2 deployed contract.
    function getChainlinkConfig()
        external
        view
        returns (
            uint16 requestConfirmations,
            bytes32 keyHash,
            VRFCoordinatorV2Interface chainlinkCoordinator
        )
    {
        return (
            _chainlinkConfig.requestConfirmations,
            _chainlinkConfig.keyHash,
            _chainlinkConfig.chainlinkCoordinator
        );
    }

    /// @notice Returns the bet with the seats list included
    /// @return bet The required bet
    function readBet(uint24 id) external view returns (Bet memory bet) {
        return bets[id];
    }

    /// @notice Allows to change the harvester address.
    /// @param newHarvester provides the new address to use.
    function setHarvester(address newHarvester) external onlyOwner {
        harvester = newHarvester;
        emit HarvesterSet(newHarvester);
    }

    /// @notice Harvests tokens dividends.
    function harvestDividends(address tokenAddress) external {
        if (msg.sender != harvester) revert AccessDenied();
        HouseEdgeSplit storage split = tokens[tokenAddress].houseEdgeSplit;
        uint256 dividendAmount = split.dividendAmount;
        if (dividendAmount != 0) {
            delete split.dividendAmount;
            _safeTransfer(harvester, tokenAddress, dividendAmount);
            emit HarvestDividend(tokenAddress, dividendAmount);
        }
    }

    /// @notice Splits the house edge fees and allocates them as dividends, the treasury, and team.
    /// @param token Address of the token.
    /// @param fees Bet amount and bet profit fees amount.
    function _allocateHouseEdge(
        address token,
        uint256 fees,
        address payable initiator
    ) private {
        IPvPGamesStore.HouseEdgeSplit
            memory tokenHouseEdgeConfig = pvpGamesStore
                .getTokenConfig(token)
                .houseEdgeSplit;
        HouseEdgeSplit storage tokenHouseEdge = tokens[token].houseEdgeSplit;

        uint256 treasuryAmount = (fees * tokenHouseEdgeConfig.treasury) / 10000;
        uint256 teamAmount = (fees * tokenHouseEdgeConfig.team) / 10000;
        uint256 initiatorAmount = (fees * tokenHouseEdgeConfig.initiator) /
            10000;
        uint256 dividendAmount = fees -
            initiatorAmount -
            teamAmount -
            treasuryAmount;

        if (teamAmount > 0) tokenHouseEdge.teamAmount += teamAmount;
        if (treasuryAmount > 0) tokenHouseEdge.treasuryAmount += treasuryAmount;
        if (dividendAmount > 0) tokenHouseEdge.dividendAmount += dividendAmount;

        if (initiatorAmount > 0) {
            payouts[initiator][token] += initiatorAmount;
        }

        emit AllocateHouseEdgeAmount(
            token,
            dividendAmount,
            treasuryAmount,
            teamAmount,
            initiatorAmount
        );
    }

    /// @notice Distributes the token's treasury and team allocations amounts.
    /// @param tokenAddress Address of the token.
    function withdrawHouseEdgeAmount(address tokenAddress) public {
        (address treasury, address teamWallet) = pvpGamesStore
            .getTreasuryAndTeamAddresses();
        HouseEdgeSplit storage tokenHouseEdge = tokens[tokenAddress]
            .houseEdgeSplit;
        uint256 treasuryAmount = tokenHouseEdge.treasuryAmount;
        uint256 teamAmount = tokenHouseEdge.teamAmount;
        if (treasuryAmount != 0) {
            delete tokenHouseEdge.treasuryAmount;
            _safeTransfer(treasury, tokenAddress, treasuryAmount);
        }
        if (teamAmount != 0) {
            delete tokenHouseEdge.teamAmount;
            _safeTransfer(teamWallet, tokenAddress, teamAmount);
        }
        if (treasuryAmount != 0 || teamAmount != 0) {
            emit HouseEdgeDistribution(
                tokenAddress,
                treasuryAmount,
                teamAmount
            );
        }
    }

    /// @notice Transfers a specific amount of token to an address.
    /// Uses native transfer or ERC20 transfer depending on the token.
    /// @dev The 0x address is considered the gas token.
    /// @param user Address of destination.
    /// @param token Address of the token.
    /// @param amount Number of tokens.
    function _safeTransfer(
        address user,
        address token,
        uint256 amount
    ) private {
        if (token == address(0)) {
            Address.sendValue(payable(user), amount);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }
    }
}