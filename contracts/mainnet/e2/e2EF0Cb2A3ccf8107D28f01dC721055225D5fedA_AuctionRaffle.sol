// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

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
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Config.sol";
import "./models/BidModel.sol";
import "./models/StateModel.sol";
import "./libs/MaxHeap.sol";
import "./libs/FeistelShuffleOptimised.sol";
import "./libs/VRFRequester.sol";
import "./verifier/IVerifier.sol";

/***
 * @title Auction & Raffle
 * @notice Draws winners using a mixed auction & raffle scheme.
 * @author TrueFi Engineering team
 */
contract AuctionRaffle is Ownable, Config, BidModel, StateModel, VRFRequester {
    using SafeERC20 for IERC20;
    using MaxHeap for uint256[];

    mapping(address => Bid) _bids; // bidder address -> Bid
    mapping(uint256 => address payable) _bidders; // bidderID -> bidder address
    uint256 _nextBidderID = 1;

    uint256[] _heap;
    uint256 _minKeyIndex;
    uint256 _minKeyValue = type(uint256).max;

    SettleState _settleState = SettleState.AWAITING_SETTLING;
    uint256[] _raffleParticipants;

    uint256[] _auctionWinners;

    bool _proceedsClaimed;

    uint256 public _randomSeed;

    /// @dev A new bid has been placed or an existing bid has been bumped
    event NewBid(address bidder, uint256 bidderID, uint256 bidAmount);

    /// @dev A bidder has been drawn as auction winner
    event NewAuctionWinner(uint256 bidderID);

    /// @dev Random number has been requested for the raffle
    event RandomNumberRequested(uint256 requestId);

    /// @dev Raffle winners have been drawn
    event RaffleWinnersDrawn(uint256 randomSeed);

    modifier onlyInState(State requiredState) {
        require(getState() == requiredState, "AuctionRaffle: is in invalid state");
        _;
    }

    modifier onlyExternalTransactions() {
        require(msg.sender == tx.origin, "AuctionRaffle: internal transactions are forbidden");
        _;
    }

    constructor(
        address initialOwner,
        ConfigParams memory configParams,
        VRFRequesterParams memory vrfRequesterParams
    ) Config(configParams) VRFRequester(vrfRequesterParams) Ownable() {
        if (initialOwner != msg.sender) {
            Ownable.transferOwnership(initialOwner);
        }
    }

    receive() external payable {
        revert("AuctionRaffle: contract accepts ether transfers only by bid method");
    }

    fallback() external payable {
        revert("AuctionRaffle: contract accepts ether transfers only by bid method");
    }

    /***
     * @notice Places a new bid.
     * @dev Assigns a unique bidderID to the sender address.
     * @param score The user's sybil resistance score
     * @param proof Attestation signature of the score
     */
    function bid(
        uint256 score,
        bytes calldata proof
    ) external payable onlyExternalTransactions onlyInState(State.BIDDING_OPEN) {
        IVerifier(_bidVerifier).verify(abi.encode(msg.sender, score), proof);
        Bid storage bidder = _bids[msg.sender];
        require(bidder.amount == 0, "AuctionRaffle: bid already exists");
        require(msg.value >= _reservePrice, "AuctionRaffle: bid amount is below reserve price");
        bidder.amount = msg.value;
        bidder.bidderID = _nextBidderID++;
        _bidders[bidder.bidderID] = payable(msg.sender);
        bidder.raffleParticipantIndex = uint240(_raffleParticipants.length);
        _raffleParticipants.push(bidder.bidderID);

        addBidToHeap(bidder.bidderID, bidder.amount);
        emit NewBid(msg.sender, bidder.bidderID, bidder.amount);
    }

    /***
     * @notice Bumps an existing bid.
     */
    function bump() external payable onlyExternalTransactions onlyInState(State.BIDDING_OPEN) {
        Bid storage bidder = _bids[msg.sender];
        require(bidder.amount != 0, "AuctionRaffle: bump nonexistent bid");
        require(msg.value >= _minBidIncrement, "AuctionRaffle: bid increment too low");
        uint256 oldAmount = bidder.amount;
        bidder.amount += msg.value;

        updateHeapBid(bidder.bidderID, oldAmount, bidder.amount);
        emit NewBid(msg.sender, bidder.bidderID, bidder.amount);
    }

    /**
     * @notice Draws auction winners and changes contract state to AUCTION_SETTLED.
     * @dev Removes highest bids from the heap, sets their WinType to AUCTION and adds them to _auctionWinners array.
     * Temporarily adds auction winner bidderIDs to a separate heap and then retrieves them in descending order.
     * This is done to efficiently remove auction winners from _raffleParticipants array as they no longer take part
     * in the raffle.
     */
    function settleAuction() external onlyInState(State.BIDDING_CLOSED) {
        _settleState = SettleState.AUCTION_SETTLED;
        uint256 biddersCount = getBiddersCount();
        uint256 raffleWinnersCount = _raffleWinnersCount;
        if (biddersCount <= raffleWinnersCount) {
            return;
        }

        uint256 auctionParticipantsCount = biddersCount - raffleWinnersCount;
        uint256 winnersLength = _auctionWinnersCount;
        if (auctionParticipantsCount < winnersLength) {
            winnersLength = auctionParticipantsCount;
        }

        for (uint256 i = 0; i < winnersLength; ++i) {
            uint256 key = _heap.removeMax();
            uint256 bidderID = extractBidderID(key);
            addAuctionWinner(bidderID);
        }

        delete _heap;
        delete _minKeyIndex;
        delete _minKeyValue;
    }

    /**
     * @notice Initiate raffle draw by requesting a random number from Chainlink VRF.
     */
    function settleRaffle() external onlyInState(State.AUCTION_SETTLED) returns (uint256) {
        uint256 reqId = _getRandomNumber();
        emit RandomNumberRequested(reqId);
        return reqId;
    }

    /**
     * @notice Draws raffle winners and changes contract state to RAFFLE_SETTLED. The first selected raffle winner
     * becomes the Golden Ticket winner.
     * @param randomSeed A single 256-bit random seed.
     */
    function _receiveRandomNumber(uint256 randomSeed) internal override onlyInState(State.AUCTION_SETTLED) {
        _settleState = SettleState.RAFFLE_SETTLED;
        _randomSeed = randomSeed;

        emit RaffleWinnersDrawn(randomSeed);
    }

    /**
     * @notice Allows a bidder to claim their funds after the raffle is settled.
     * Golden Ticket winner can withdraw the full bid amount.
     * Raffle winner can withdraw the bid amount minus `_reservePrice`.
     * Non-winning bidder can withdraw the full bid amount.
     * Auction winner pays the full bid amount and is not entitled to any withdrawal.
     */
    function claim(uint256 bidderID) external onlyInState(State.RAFFLE_SETTLED) {
        address payable bidderAddress = getBidderAddress(bidderID);
        Bid storage bidder = _bids[bidderAddress];
        require(!bidder.claimed, "AuctionRaffle: funds have already been claimed");
        require(!bidder.isAuctionWinner, "AuctionRaffle: auction winners cannot claim funds");
        bidder.claimed = true;

        WinType winType = getBidWinType(bidderID);
        uint256 claimAmount;
        if (winType == WinType.GOLDEN_TICKET || winType == WinType.LOSS) {
            claimAmount = bidder.amount;
        } else if (winType == WinType.RAFFLE) {
            claimAmount = bidder.amount - _reservePrice;
        }

        if (claimAmount > 0) {
            bidderAddress.transfer(claimAmount);
        }
    }

    /**
     * @notice Allows the owner to claim proceeds from the ticket sale after the raffle is settled.
     * Proceeds include:
     * sum of auction winner bid amounts,
     * `_reservePrice` paid by each raffle winner (except the Golden Ticket winner).
     */
    function claimProceeds() external onlyOwner onlyInState(State.RAFFLE_SETTLED) {
        require(!_proceedsClaimed, "AuctionRaffle: proceeds have already been claimed");
        _proceedsClaimed = true;

        uint256 biddersCount = getBiddersCount();
        if (biddersCount == 0) {
            return;
        }

        uint256 totalAmount = 0;

        uint256 auctionWinnersCount = _auctionWinners.length;
        for (uint256 i = 0; i < auctionWinnersCount; ++i) {
            address bidderAddress = _bidders[_auctionWinners[i]];
            totalAmount += _bids[bidderAddress].amount;
        }

        uint256 raffleWinnersCount = _raffleWinnersCount - 1;
        if (biddersCount <= raffleWinnersCount) {
            raffleWinnersCount = biddersCount - 1;
        }
        totalAmount += raffleWinnersCount * _reservePrice;

        payable(owner()).transfer(totalAmount);
    }

    /**
     * @notice Allows the owner to withdraw all funds left in the contract by the participants.
     * Callable only after the claiming window is closed.
     */
    function withdrawUnclaimedFunds() external onlyOwner onlyInState(State.CLAIMING_CLOSED) {
        uint256 unclaimedFunds = address(this).balance;
        payable(owner()).transfer(unclaimedFunds);
    }

    /**
     * @notice Allows the owner to retrieve any ERC-20 tokens that were sent to the contract by accident.
     * @param tokenAddress The address of an ERC-20 token contract.
     */
    function rescueTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "AuctionRaffle: no tokens for given address");
        token.safeTransfer(owner(), balance);
    }

    /// @return A list of raffle participants; including the winners (if settled)
    function getRaffleParticipants() external view returns (uint256[] memory) {
        return _raffleParticipants;
    }

    /// @return A list of auction winner bidder IDs.
    function getAuctionWinners() external view returns (uint256[] memory) {
        return _auctionWinners;
    }

    /// @return winners A list of raffle winner bidder IDs.
    function getRaffleWinners() external view onlyInState(State.RAFFLE_SETTLED) returns (uint256[] memory winners) {
        uint256 participantsCount = _raffleParticipants.length;
        uint256 raffleWinnersCount = _raffleWinnersCount;
        uint256 n = participantsCount < raffleWinnersCount ? participantsCount : raffleWinnersCount;
        uint256 randomSeed = _randomSeed;

        winners = new uint256[](n);
        for (uint256 i; i < n; ++i) {
            // Map inverse `i`th place winner -> original index
            uint256 winnerIndex = FeistelShuffleOptimised.deshuffle(i, participantsCount, randomSeed, 4);
            // Map original participant index -> bidder id
            uint256 winningBidderId = _raffleParticipants[winnerIndex];
            // Record winner in storage
            winners[i] = winningBidderId;
        }
    }

    function getBid(address bidder) external view returns (Bid memory) {
        Bid storage bid_ = _bids[bidder];
        require(bid_.bidderID != 0, "AuctionRaffle: no bid by given address");
        return bid_;
    }

    function getBidByID(uint256 bidderID) external view returns (Bid memory) {
        address bidder = getBidderAddress(bidderID);
        return _bids[bidder];
    }

    function getBidsWithAddresses() external view returns (BidWithAddress[] memory) {
        uint256 totalBids = getBiddersCount();

        BidWithAddress[] memory bids = new BidWithAddress[](totalBids);

        for (uint256 i = 1; i <= totalBids; ++i) {
            BidWithAddress memory bid_ = getBidWithAddress(i);
            bids[i - 1] = bid_;
        }

        return bids;
    }

    function getBidWithAddress(uint256 bidderID) public view returns (BidWithAddress memory) {
        address bidder = getBidderAddress(bidderID);
        Bid storage bid_ = _bids[bidder];

        BidWithAddress memory bidWithAddress = BidWithAddress({bidder: bidder, bid: bid_});

        return bidWithAddress;
    }

    /// @return Address of bidder account for given bidder ID.
    function getBidderAddress(uint256 bidderID) public view returns (address payable) {
        address payable bidderAddress = _bidders[bidderID];
        require(bidderAddress != address(0), "AuctionRaffle: bidder with given ID does not exist");
        return bidderAddress;
    }

    function getBiddersCount() public view returns (uint256) {
        return _nextBidderID - 1;
    }

    function getState() public view returns (State) {
        if (block.timestamp >= _claimingEndTime) {
            return State.CLAIMING_CLOSED;
        }
        if (_settleState == SettleState.RAFFLE_SETTLED) {
            return State.RAFFLE_SETTLED;
        }
        if (_settleState == SettleState.AUCTION_SETTLED) {
            return State.AUCTION_SETTLED;
        }
        if (block.timestamp >= _biddingEndTime) {
            return State.BIDDING_CLOSED;
        }
        if (block.timestamp >= _biddingStartTime) {
            return State.BIDDING_OPEN;
        }
        return State.AWAITING_BIDDING;
    }

    /**
     * @notice Adds a bid to the heap if it isn't full or the heap key is greater than `_minKeyValue`.
     * @dev Updates _minKeyIndex and _minKeyValue if needed.
     * @param bidderID Unique bidder ID
     * @param amount The bid amount
     */
    function addBidToHeap(uint256 bidderID, uint256 amount) private {
        bool isHeapFull = getBiddersCount() > _auctionWinnersCount; // bid() already incremented _nextBidderID
        uint256 key = getKey(bidderID, amount);
        uint256 minKeyValue = _minKeyValue;

        if (isHeapFull) {
            if (key <= minKeyValue) {
                return;
            }
            _heap.increaseKey(minKeyValue, key);
            updateMinKey();
        } else {
            _heap.insert(key);
            if (key <= minKeyValue) {
                _minKeyIndex = _heap.length - 1;
                _minKeyValue = key;
                return;
            }
            updateMinKey();
        }
    }

    /**
     * @notice Updates an existing bid or replaces an existing bid with a new one in the heap.
     * @dev Updates _minKeyIndex and _minKeyValue if needed.
     * @param bidderID Unique bidder ID
     * @param oldAmount Previous bid amount
     * @param newAmount New bid amount
     */
    function updateHeapBid(uint256 bidderID, uint256 oldAmount, uint256 newAmount) private {
        bool isHeapFull = getBiddersCount() >= _auctionWinnersCount;
        uint256 key = getKey(bidderID, newAmount);
        uint256 minKeyValue = _minKeyValue;

        bool shouldUpdateHeap = key > minKeyValue;
        if (isHeapFull && !shouldUpdateHeap) {
            return;
        }
        uint256 oldKey = getKey(bidderID, oldAmount);
        bool updatingMinKey = oldKey <= minKeyValue;
        if (updatingMinKey) {
            _heap.increaseKeyAt(_minKeyIndex, key);
            updateMinKey();
            return;
        }
        _heap.increaseKey(oldKey, key);
    }

    function updateMinKey() private {
        (_minKeyIndex, _minKeyValue) = _heap.findMin();
    }

    /**
     * Record auction winner, and additionally remove them from the raffle
     * participants list.
     * @param bidderID Unique bidder ID
     */
    function addAuctionWinner(uint256 bidderID) private {
        address bidderAddress = getBidderAddress(bidderID);
        _bids[bidderAddress].isAuctionWinner = true;
        _auctionWinners.push(bidderID);
        emit NewAuctionWinner(bidderID);
        removeRaffleParticipant(_bids[bidderAddress].raffleParticipantIndex);
    }

    /**
     * Determine the WinType of a bid, i.e. whether a bid is an auction winner,
     * a golden ticket winner, a raffle winner, or a loser.
     * @param bidderID Monotonically-increasing unique bidder identifier
     */
    function getBidWinType(uint256 bidderID) public view returns (WinType) {
        if (uint8(getState()) < uint8(State.AUCTION_SETTLED)) {
            return WinType.LOSS;
        }

        address bidderAddress = getBidderAddress(bidderID);
        Bid memory bid_ = _bids[bidderAddress];
        if (bid_.isAuctionWinner) {
            return WinType.AUCTION;
        }

        uint256 participantsCount = _raffleParticipants.length;
        uint256 raffleWinnersCount = _raffleWinnersCount;
        uint256 n = participantsCount < raffleWinnersCount ? participantsCount : raffleWinnersCount;
        // Map original index -> inverse `i`th place winner
        uint256 place = FeistelShuffleOptimised.shuffle(bid_.raffleParticipantIndex, participantsCount, _randomSeed, 4);
        if (place == 0) {
            return WinType.GOLDEN_TICKET;
        } else if (place < n) {
            return WinType.RAFFLE;
        } else {
            return WinType.LOSS;
        }
    }

    /**
     * @notice Removes a participant from _raffleParticipants array.
     * @dev Swaps _raffleParticipants[index] with the last one, then removes the last one.
     * @param index The index of raffle participant to remove
     */
    function removeRaffleParticipant(uint256 index) private {
        uint256 participantsLength = _raffleParticipants.length;
        require(index < participantsLength, "AuctionRaffle: invalid raffle participant index");
        uint256 lastBidderID = _raffleParticipants[participantsLength - 1];
        _raffleParticipants[index] = lastBidderID;
        _bids[_bidders[lastBidderID]].raffleParticipantIndex = uint240(index);
        _raffleParticipants.pop();
    }

    /**
     * @notice Calculates unique heap key based on bidder ID and bid amount. The key is designed so that higher bids
     * are assigned a higher key value. In case of a draw in bid amount, lower bidder ID gives a higher key value.
     * @dev The difference between `_bidderMask` and bidderID is stored in lower bits of the returned key.
     * Bid amount is stored in higher bits of the returned key.
     * @param bidderID Unique bidder ID
     * @param amount The bid amount
     * @return Unique heap key
     */
    function getKey(uint256 bidderID, uint256 amount) private pure returns (uint256) {
        return (amount << _bidderMaskLength) | (_bidderMask - bidderID);
    }

    /**
     * @notice Extracts bidder ID from a heap key
     * @param key Heap key
     * @return Extracted bidder ID
     */
    function extractBidderID(uint256 key) private pure returns (uint256) {
        return _bidderMask - (key & _bidderMask);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @dev Holds config values used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract Config {
    struct ConfigParams {
        uint256 biddingStartTime;
        uint256 biddingEndTime;
        uint256 claimingEndTime;
        uint256 auctionWinnersCount;
        uint256 raffleWinnersCount;
        uint256 reservePrice;
        uint256 minBidIncrement;
        address bidVerifier;
    }

    // The use of _randomMask and _bidderMask introduces an assumption on max number of participants: 2^32.
    // The use of _bidderMask also introduces an assumption on max bid amount: 2^224 wei.
    // Both of these values are fine for our use case.
    uint256 constant _randomMask = 0xffffffff;
    uint256 constant _randomMaskLength = 32;
    uint256 constant _winnersPerRandom = 256 / _randomMaskLength;
    uint256 constant _bidderMask = _randomMask;
    uint256 constant _bidderMaskLength = _randomMaskLength;

    uint256 immutable _biddingStartTime;
    uint256 immutable _biddingEndTime;
    uint256 immutable _claimingEndTime;
    uint256 immutable _auctionWinnersCount;
    uint256 immutable _raffleWinnersCount;
    uint256 immutable _reservePrice;
    uint256 immutable _minBidIncrement;

    address immutable _bidVerifier;

    constructor(ConfigParams memory params) {
        uint256 biddingStartTime_ = params.biddingStartTime;
        uint256 biddingEndTime_ = params.biddingEndTime;
        uint256 claimingEndTime_ = params.claimingEndTime;
        uint256 auctionWinnersCount_ = params.auctionWinnersCount;
        uint256 raffleWinnersCount_ = params.raffleWinnersCount;
        uint256 reservePrice_ = params.reservePrice;
        uint256 minBidIncrement_ = params.minBidIncrement;
        address bidVerifier_ = params.bidVerifier;

        require(auctionWinnersCount_ > 0, "Config: auction winners count must be greater than 0");
        require(raffleWinnersCount_ > 0, "Config: raffle winners count must be greater than 0");
        require(raffleWinnersCount_ % _winnersPerRandom == 0, "Config: invalid raffle winners count");
        require(biddingStartTime_ < biddingEndTime_, "Config: bidding start time must be before bidding end time");
        require(biddingEndTime_ < claimingEndTime_, "Config: bidding end time must be before claiming end time");
        require(reservePrice_ > 0, "Config: reserve price must be greater than 0");
        require(minBidIncrement_ > 0, "Config: min bid increment must be greater than 0");
        require(
            biddingEndTime_ - biddingStartTime_ >= 6 hours,
            "Config: bidding start time and bidding end time must be at least 6h apart"
        );
        require(
            claimingEndTime_ - biddingEndTime_ >= 6 hours,
            "Config: bidding end time and claiming end time must be at least 6h apart"
        );

        _biddingStartTime = biddingStartTime_;
        _biddingEndTime = biddingEndTime_;
        _claimingEndTime = claimingEndTime_;
        _auctionWinnersCount = auctionWinnersCount_;
        _raffleWinnersCount = raffleWinnersCount_;
        _reservePrice = reservePrice_;
        _minBidIncrement = minBidIncrement_;

        require(bidVerifier_ != address(0), "Config: invalid verifier");
        _bidVerifier = bidVerifier_;
    }

    function biddingStartTime() external view returns (uint256) {
        return _biddingStartTime;
    }

    function biddingEndTime() external view returns (uint256) {
        return _biddingEndTime;
    }

    function claimingEndTime() external view returns (uint256) {
        return _claimingEndTime;
    }

    function auctionWinnersCount() external view returns (uint256) {
        return _auctionWinnersCount;
    }

    function raffleWinnersCount() external view returns (uint256) {
        return _raffleWinnersCount;
    }

    function reservePrice() external view returns (uint256) {
        return _reservePrice;
    }

    function minBidIncrement() external view returns (uint256) {
        return _minBidIncrement;
    }

    function bidVerifier() external view returns (address) {
        return _bidVerifier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

/// @title FeistelShuffleOptimised
/// @author kevincharm
/// @notice Feistel shuffle implemented in Yul.
library FeistelShuffleOptimised {
    error InvalidInputs();

    /// @notice Compute a Feistel shuffle mapping for index `x`
    /// @param x index of element in the list
    /// @param domain Number of elements in the list
    /// @param seed Random seed; determines the permutation
    /// @param rounds Number of Feistel rounds to perform
    /// @return resulting shuffled index
    function shuffle(
        uint256 x,
        uint256 domain,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        // (domain != 0): domain must be non-zero (value of 1 also doesn't really make sense)
        // (xPrime < domain): index to be permuted must lie within the domain of [0, domain)
        // (rounds is even): we only handle even rounds to make the code simpler
        if (domain == 0 || x >= domain || rounds & 1 == 1) {
            revert InvalidInputs();
        }

        assembly {
            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)
                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if and(not(iszero(s)), 1) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(domain)
            let sqrtN := sqrt(domain)
            let nps
            switch eq(exp(sqrtN, 2), domain)
            case 1 {
                nps := domain
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Allocate scratch memory for inputs to keccak256
            let packed := mload(0x40)
            mstore(0x40, add(packed, 0x80)) // 128B
            // When calculating hashes for Feistel rounds, seed and domain
            // do not change. So we can set them here just once.
            mstore(add(packed, 0x40), seed)
            mstore(add(packed, 0x60), domain)
            // Loop until x < domain
            for {

            } 1 {

            } {
                let L := mod(x, h)
                let R := div(x, h)
                // Loop for desired number of rounds
                for {
                    let i := 0
                } lt(i, rounds) {
                    i := add(i, 1)
                } {
                    // Load R and i for next keccak256 round
                    mstore(packed, R)
                    mstore(add(packed, 0x20), i)
                    // roundHash <- keccak256([R, i, seed, domain])
                    let roundHash := keccak256(packed, 0x80)
                    // nextR <- (L + roundHash) % h
                    let nextR := mod(add(L, roundHash), h)
                    L := R
                    R := nextR
                }
                // x <- h * R + L
                x := add(mul(h, R), L)
                if lt(x, domain) {
                    break
                }
            }
        }
        return x;
    }

    /// @notice Compute the inverse Feistel shuffle mapping for the shuffled
    ///     index `xPrime`
    /// @param xPrime shuffled index of element in the list
    /// @param domain Number of elements in the list
    /// @param seed Random seed; determines the permutation
    /// @param rounds Number of Feistel rounds that was performed in the
    ///     original shuffle.
    /// @return resulting shuffled index
    function deshuffle(
        uint256 xPrime,
        uint256 domain,
        uint256 seed,
        uint256 rounds
    ) internal pure returns (uint256) {
        // (domain != 0): domain must be non-zero (value of 1 also doesn't really make sense)
        // (xPrime < domain): index to be permuted must lie within the domain of [0, domain)
        // (rounds is even): we only handle even rounds to make the code simpler
        if (domain == 0 || xPrime >= domain || rounds & 1 == 1) {
            revert InvalidInputs();
        }

        assembly {
            // Calculate sqrt(s) using Babylonian method
            function sqrt(s) -> z {
                switch gt(s, 3)
                // if (s > 3)
                case 1 {
                    z := s
                    let r := add(div(s, 2), 1)
                    for {

                    } lt(r, z) {

                    } {
                        z := r
                        r := div(add(div(s, r), r), 2)
                    }
                }
                default {
                    if and(not(iszero(s)), 1) {
                        // else if (s != 0)
                        z := 1
                    }
                }
            }

            // nps <- nextPerfectSquare(domain)
            let sqrtN := sqrt(domain)
            let nps
            switch eq(exp(sqrtN, 2), domain)
            case 1 {
                nps := domain
            }
            default {
                let sqrtN1 := add(sqrtN, 1)
                // pre-check for square overflow
                if gt(sqrtN1, sub(exp(2, 128), 1)) {
                    // overflow
                    revert(0, 0)
                }
                nps := exp(sqrtN1, 2)
            }
            // h <- sqrt(nps)
            let h := sqrt(nps)
            // Allocate scratch memory for inputs to keccak256
            let packed := mload(0x40)
            mstore(0x40, add(packed, 0x80)) // 128B
            // When calculating hashes for Feistel rounds, seed and domain
            // do not change. So we can set them here just once.
            mstore(add(packed, 0x40), seed)
            mstore(add(packed, 0x60), domain)
            // Loop until x < domain
            for {

            } 1 {

            } {
                let L := mod(xPrime, h)
                let R := div(xPrime, h)
                // Loop for desired number of rounds
                for {
                    let i := 0
                } lt(i, rounds) {
                    i := add(i, 1)
                } {
                    // Load L and i for next keccak256 round
                    mstore(packed, L)
                    mstore(add(packed, 0x20), sub(sub(rounds, i), 1))
                    // roundHash <- keccak256([L, rounds - i - 1, seed, domain])
                    // NB: extra arithmetic to avoid underflow
                    let roundHash := mod(keccak256(packed, 0x80), h)
                    // nextL <- (R - roundHash) % h
                    // NB: extra arithmetic to avoid underflow
                    let nextL := mod(sub(add(R, h), roundHash), h)
                    R := L
                    L := nextL
                }
                // x <- h * R + L
                xPrime := add(mul(h, R), L)
                if lt(xPrime, domain) {
                    break
                }
            }
        }
        return xPrime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @title Max Heap library
 * @notice Data structure used by the AuctionRaffle contract to store top bids.
 * It allows retrieving them in descending order on auction settlement.
 * @author TrueFi Engineering team
 */
library MaxHeap {
    function insert(uint256[] storage heap, uint256 key) internal {
        uint256 index = heap.length;
        heap.push(key);
        bubbleUp(heap, index, key);
    }

    function increaseKey(
        uint256[] storage heap,
        uint256 oldValue,
        uint256 newValue
    ) internal {
        uint256 index = findKey(heap, oldValue);
        increaseKeyAt(heap, index, newValue);
    }

    function increaseKeyAt(
        uint256[] storage heap,
        uint256 index,
        uint256 newValue
    ) internal {
        require(newValue > heap[index], "MaxHeap: new value must be bigger than old value");
        heap[index] = newValue;
        bubbleUp(heap, index, newValue);
    }

    function removeMax(uint256[] storage heap) internal returns (uint256 max) {
        require(heap.length > 0, "MaxHeap: cannot remove max element from empty heap");
        max = heap[0];
        heap[0] = heap[heap.length - 1];
        heap.pop();

        uint256 index = 0;
        while (true) {
            uint256 l = left(index);
            uint256 r = right(index);
            uint256 biggest = index;

            if (l < heap.length && heap[l] > heap[index]) {
                biggest = l;
            }
            if (r < heap.length && heap[r] > heap[biggest]) {
                biggest = r;
            }
            if (biggest == index) {
                break;
            }
            (heap[index], heap[biggest]) = (heap[biggest], heap[index]);
            index = biggest;
        }
        return max;
    }

    function bubbleUp(
        uint256[] storage heap,
        uint256 index,
        uint256 key
    ) internal {
        while (index > 0 && heap[parent(index)] < heap[index]) {
            (heap[parent(index)], heap[index]) = (key, heap[parent(index)]);
            index = parent(index);
        }
    }

    function findKey(uint256[] storage heap, uint256 value) internal view returns (uint256) {
        for (uint256 i = 0; i < heap.length; ++i) {
            if (heap[i] == value) {
                return i;
            }
        }
        revert("MaxHeap: key with given value not found");
    }

    function findMin(uint256[] storage heap) internal view returns (uint256 index, uint256 min) {
        uint256 heapLength = heap.length;
        require(heapLength > 0, "MaxHeap: cannot find minimum element on empty heap");

        uint256 n = heapLength / 2;
        min = heap[n];
        index = n;

        for (uint256 i = n + 1; i < heapLength; ++i) {
            uint256 element = heap[i];
            if (element < min) {
                min = element;
                index = i;
            }
        }
    }

    function parent(uint256 index) internal pure returns (uint256) {
        return (index - 1) / 2;
    }

    function left(uint256 index) internal pure returns (uint256) {
        return 2 * index + 1;
    }

    function right(uint256 index) internal pure returns (uint256) {
        return 2 * index + 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

/// @title VRFRequester
/// @notice Consume Chainlink's subscription-managed VRFv2 wrapper to return a
///     random number.
abstract contract VRFRequester is VRFConsumerBaseV2 {
    struct VRFRequesterParams {
        address vrfCoordinator;
        address linkToken;
        uint256 linkPremium;
        bytes32 gasLaneKeyHash;
        uint32 callbackGasLimit;
        uint16 minConfirmations;
        uint64 subId;
    }

    /// @notice VRF Coordinator (V2)
    /// @dev https://docs.chain.link/vrf/v2/subscription/supported-networks
    address public immutable vrfCoordinator;
    /// @notice LINK token (make sure it's the ERC-677 one)
    /// @dev PegSwap: https://pegswap.chain.link
    address public immutable linkToken;
    /// @notice LINK token unit
    uint256 public immutable juels;
    /// @dev VRF Coordinator LINK premium per request
    uint256 public immutable linkPremium;
    /// @notice Each gas lane has a different key hash; each gas lane
    ///     determines max gwei that will be used for the callback
    bytes32 public immutable gasLaneKeyHash;
    /// @notice Absolute gas limit for callbacks
    uint32 public immutable callbackGasLimit;
    /// @notice Minimum number of block confirmations before VRF fulfilment
    uint16 public immutable minConfirmations;
    /// @notice VRF subscription ID; created during deployment
    uint64 public subId;
    /// @notice Inflight requestId
    uint256 public requestId;

    constructor(VRFRequesterParams memory params) VRFConsumerBaseV2(params.vrfCoordinator) {
        vrfCoordinator = params.vrfCoordinator;
        linkToken = params.linkToken;
        juels = 10 ** LinkTokenInterface(params.linkToken).decimals();
        linkPremium = params.linkPremium;
        gasLaneKeyHash = params.gasLaneKeyHash;
        callbackGasLimit = params.callbackGasLimit;
        minConfirmations = params.minConfirmations;
        // NB: This contract must be added as a consumer to this subscription
        subId = params.subId;
    }

    /// @notice Update VRF subscription id
    /// @param newSubId New subscription id
    function _updateSubId(uint64 newSubId) internal {
        subId = newSubId;
    }

    /// @notice Request a random number
    function _getRandomNumber() internal returns (uint256) {
        require(requestId == 0, "Request already inflight");
        uint256 requestId_ = VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
            gasLaneKeyHash,
            subId,
            minConfirmations,
            callbackGasLimit,
            1
        );
        requestId = requestId_;
        return requestId_;
    }

    /// @notice Callback to receive a random number from the VRF fulfiller
    /// @dev Override this function
    /// @param randomNumber Random number
    function _receiveRandomNumber(uint256 randomNumber) internal virtual {}

    /// @notice Callback function used by VRF Coordinator
    /// @dev DO NOT OVERRIDE!
    function fulfillRandomWords(uint256 requestId_, uint256[] memory randomness) internal override {
        require(requestId_ == requestId, "Unexpected requestId");
        require(randomness.length > 0, "Unexpected empty randomness");
        requestId = 0;
        _receiveRandomNumber(randomness[0]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @dev Defines bid related data types used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract BidModel {
    struct Bid {
        uint256 bidderID;
        uint256 amount;
        bool isAuctionWinner;
        bool claimed;
        uint240 raffleParticipantIndex;
    }

    struct BidWithAddress {
        address bidder;
        Bid bid;
    }

    enum WinType {
        LOSS,
        GOLDEN_TICKET,
        AUCTION,
        RAFFLE
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/***
 * @dev Defines state enums used by AuctionRaffle contract.
 * @author TrueFi Engineering team
 */
abstract contract StateModel {
    // NB: This is ordered according to the expected sequence. Do not reorder!
    enum State {
        AWAITING_BIDDING,
        BIDDING_OPEN,
        BIDDING_CLOSED,
        AUCTION_SETTLED,
        RAFFLE_SETTLED,
        CLAIMING_CLOSED
    }

    enum SettleState {
        AWAITING_SETTLING,
        AUCTION_SETTLED,
        RAFFLE_SETTLED
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IVerifier {
    function verify(bytes memory payload, bytes memory proof) external;
}