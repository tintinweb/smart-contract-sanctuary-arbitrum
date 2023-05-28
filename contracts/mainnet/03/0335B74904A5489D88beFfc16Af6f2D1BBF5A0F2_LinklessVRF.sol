// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

interface IRandomiserCallback {
    /// @notice Receive random words from a randomiser.
    /// @dev Ensure that proper access control is enforced on this function;
    ///     only the designated randomiser may call this function and the
    ///     requestId should be as expected from the randomness request.
    /// @param requestId The identifier for the original randomness request
    /// @param randomWords An arbitrary array of random numbers
    function receiveRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.18;

interface IRandomiserGen2 {
    function getRandomNumber(
        address callbackContract,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    ) external payable returns (uint256 requestId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title WETH9
interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get gas prices for a provided aggregator
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWeiWithAggregator(address aggregator)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /// @notice Get prices in ArbGas for the supplied aggregator
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGasWithAggregator(address aggregator)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Get prices in ArbGas. Assumes the callers preferred validator, or the default if caller doesn't have a preferred one.
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGas()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Get the gas accounting parameters. `gasPoolMax` is always zero, as the exponential pricing model has no such notion.
    /// @return (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Get the minimum gas price needed for a tx to succeed
    function getMinimumGasPrice() external view returns (uint256);

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);

    /// @notice Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns (uint64);

    /// @notice Deprecated -- Same as getL1BaseFeeEstimate()
    function getL1GasPriceEstimate() external view returns (uint256);

    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);

    /// @notice Get the backlogged amount of gas burnt in excess of the speed limit
    function getGasBacklog() external view returns (uint64);

    /// @notice Get how slowly ArbOS updates the L2 basefee in response to backlogged gas
    function getPricingInertia() external view returns (uint64);

    /// @notice Get the forgivable amount of backlogged gas ArbOS will ignore when raising the basefee
    function getGasBacklogTolerance() external view returns (uint64);

    /// @notice Returns the surplus of funds for L1 batch posting payments (may be negative).
    function getL1PricingSurplus() external view returns (int256);

    /// @notice Returns the base charge (in L1 gas) attributed to each data batch in the calldata pricer
    function getPerBatchGasCharge() external view returns (int64);

    /// @notice Returns the cost amortization cap in basis points
    function getAmortizedCostCapBips() external view returns (uint64);

    /// @notice Returns the available funds from L1 fees
    function getL1FeesAvailable() external view returns (uint256);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/** @title Interface for providing gas estimation for retryable auto-redeems and constructing outbox proofs
 *  @notice This contract doesn't exist on-chain. Instead it is a virtual interface accessible at
 *  0x00000000000000000000000000000000000000C8
 *  This is a cute trick to allow an Arbitrum node to provide data without us having to implement additional RPCs
 */
interface NodeInterface {
    /**
     * @notice Simulate the execution of a retryable ticket
     * @dev Use eth_estimateGas on this call to estimate gas usage of retryable ticket
     *      Since gas usage is not yet known, you may need to add extra deposit (e.g. 1e18 wei) during estimation
     * @param sender unaliased sender of the L1 and L2 transaction
     * @param deposit amount to deposit to sender in L2
     * @param to destination L2 contract address
     * @param l2CallValue call value for retryable L2 message
     * @param excessFeeRefundAddress gasLimit x maxFeePerGas - execution cost gets credited here on L2 balance
     * @param callValueRefundAddress l2Callvalue gets credited here on L2 if retryable txn times out or gets cancelled
     * @param data ABI encoded data of L2 message
     */
    function estimateRetryableTicket(
        address sender,
        uint256 deposit,
        address to,
        uint256 l2CallValue,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        bytes calldata data
    ) external;

    /**
     * @notice Constructs an outbox proof of an l2->l1 send's existence in the outbox accumulator.
     * @dev Use eth_call to call.
     * @param size the number of elements in the accumulator
     * @param leaf the position of the send in the accumulator
     * @return send the l2->l1 send's hash
     * @return root the root of the outbox accumulator
     * @return proof level-by-level branch hashes constituting a proof of the send's membership at the given size
     */
    function constructOutboxProof(uint64 size, uint64 leaf)
        external
        view
        returns (
            bytes32 send,
            bytes32 root,
            bytes32[] memory proof
        );

    /**
     * @notice Finds the L1 batch containing a requested L2 block, reverting if none does.
     * Use eth_call to call.
     * Throws if block doesn't exist, or if block number is 0. Use eth_call
     * @param blockNum The L2 block being queried
     * @return batch The sequencer batch number containing the requested L2 block
     */
    function findBatchContainingBlock(uint64 blockNum)
        external
        view
        returns (uint64 batch);

    /**
     * @notice Gets the number of L1 confirmations of the sequencer batch producing the requested L2 block
     * This gets the number of L1 confirmations for the input message producing the L2 block,
     * which happens well before the L1 rollup contract confirms the L2 block.
     * Throws if block doesnt exist in the L2 chain.
     * @dev Use eth_call to call.
     * @param blockHash The hash of the L2 block being queried
     * @return confirmations The number of L1 confirmations the sequencer batch has. Returns 0 if block not yet included in an L1 batch.
     */
    function getL1Confirmations(bytes32 blockHash)
        external
        view
        returns (uint64 confirmations);

    /**
     * @notice Same as native gas estimation, but with additional info on the l1 costs.
     * @dev Use eth_call to call.
     * @param data the tx's calldata. Everything else like "From" and "Gas" are copied over
     * @param to the tx's "To" (ignored when contractCreation is true)
     * @param contractCreation whether "To" is omitted
     * @return gasEstimate an estimate of the total amount of gas needed for this tx
     * @return gasEstimateForL1 an estimate of the amount of gas needed for the l1 component of this tx
     * @return baseFee the l2 base fee
     * @return l1BaseFeeEstimate ArbOS's l1 estimate of the l1 base fee
     */
    function gasEstimateComponents(
        address to,
        bool contractCreation,
        bytes calldata data
    )
        external
        payable
        returns (
            uint64 gasEstimate,
            uint64 gasEstimateForL1,
            uint256 baseFee,
            uint256 l1BaseFeeEstimate
        );

    /**
     * @notice Estimates a transaction's l1 costs.
     * @dev Use eth_call to call.
     *      This method is similar to gasEstimateComponents, but doesn't include the l2 component
     *      so that the l1 component can be known even when the tx may fail.
     *      This method also doesn't pad the estimate as gas estimation normally does.
     *      If using this value to submit a transaction, we'd recommend first padding it by 10%.
     * @param data the tx's calldata. Everything else like "From" and "Gas" are copied over
     * @param to the tx's "To" (ignored when contractCreation is true)
     * @param contractCreation whether "To" is omitted
     * @return gasEstimateForL1 an estimate of the amount of gas needed for the l1 component of this tx
     * @return baseFee the l2 base fee
     * @return l1BaseFeeEstimate ArbOS's l1 estimate of the l1 base fee
     */
    function gasEstimateL1Component(
        address to,
        bool contractCreation,
        bytes calldata data
    )
        external
        payable
        returns (
            uint64 gasEstimateForL1,
            uint256 baseFee,
            uint256 l1BaseFeeEstimate
        );

    /**
     * @notice Returns the proof necessary to redeem a message
     * @param batchNum index of outbox entry (i.e., outgoing messages Merkle root) in array of outbox entries
     * @param index index of outgoing message in outbox entry
     * @return proof Merkle proof of message inclusion in outbox entry
     * @return path Merkle path to message
     * @return l2Sender sender if original message (i.e., caller of ArbSys.sendTxToL1)
     * @return l1Dest destination address for L1 contract call
     * @return l2Block l2 block number at which sendTxToL1 call was made
     * @return l1Block l1 block number at which sendTxToL1 call was made
     * @return timestamp l2 Timestamp at which sendTxToL1 call was made
     * @return amount value in L1 message in wei
     * @return calldataForL1 abi-encoded L1 message data
     */
    function legacyLookupMessageBatchProof(uint256 batchNum, uint64 index)
        external
        view
        returns (
            bytes32[] memory proof,
            uint256 path,
            address l2Sender,
            address l1Dest,
            uint256 l2Block,
            uint256 l1Block,
            uint256 timestamp,
            uint256 amount,
            bytes memory calldataForL1
        );

    // @notice Returns the first block produced using the Nitro codebase
    // @dev returns 0 for chains like Nova that don't contain classic blocks
    // @return number the block number
    function nitroGenesisBlock() external pure returns (uint256 number);
}

// SPDX-License-Identifier: MIT
/**
    The MIT License (MIT)

    Copyright (c) 2018 SmartContract ChainLink, Ltd.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
*/

pragma solidity ^0.8;

abstract contract TypeAndVersion {
    function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IRandomiserGen2} from "../interfaces/IRandomiserGen2.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {Authorised} from "../vendor/Authorised.sol";
import {IWETH9} from "../interfaces/IWETH9.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRandomiserCallback} from "../interfaces/IRandomiserCallback.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {L2GasUtil} from "../vendor/L2GasUtil.sol";

/// @title LinklessVRF
/// @author kevincharm
/// @notice Make VRF requests using ETH instead of LINK.
/// @dev Contract should charge a multiple of the total request cost. This fee
///     acts as a buffer for volatility in ETH/LINK & gasprice. Whatever is
///     left unused is taken as profit.
/// @dev Preload the subscription past the low watermark!
/// @dev The gaslane is hardcoded.
contract LinklessVRF is
    IRandomiserGen2,
    TypeAndVersion,
    Authorised,
    VRFConsumerBaseV2
{
    /// --- VRF SHIT ---
    /// @notice Max gas used to verify VRF proofs; always 200k according to:
    ///     https://docs.chain.link/vrf/v2/subscription#minimum-subscription-balance
    uint256 public constant MAX_VERIFICATION_GAS = 200_000;
    /// @notice Extra gas overhead for fulfilling randomness
    uint256 public constant FULFILMENT_OVERHEAD_GAS = 30_000;
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
    /// @notice Max gas price for gas lane used in gasLaneKeyHash
    /// @dev This is used purely for gas estimation
    uint256 public immutable gasLaneMaxWei;
    /// @notice Max gas limit supported by the coordinator
    uint256 public immutable absoluteMaxGasLimit;
    /// @notice VRF subscription ID; created during deployment
    uint64 public subId;

    /// --- PRICE FEED SHIT ---
    /// @notice Period until a feed is considered stale
    /// @dev Check heartbeat parameters on data.chain.link
    uint256 public constant MAX_AGE = 60 minutes;
    /// @notice Internal prices shall be scaled according to this constant
    uint256 public constant EXP_SCALE = 10**8;
    /// @notice LINK/USD chainlink price feed
    address public immutable feedLINKUSD;
    /// @notice ETH/USD chainlink price feed
    address public immutable feedETHUSD;

    /// --- UNISWAMP ---
    /// @notice WETH address used in UniV3 pool
    address public immutable weth;
    /// @notice UniV3 swap router (NB: SwapRouter v1!)
    address public immutable swapRouter;
    /// @notice UniV3 LINK/ETH pool fee
    uint24 public immutable uniV3PoolFee;

    /// --- THE PROTOCOL ---
    /// @notice Protocol fee per request.
    /// @dev Protocol fee also acts as a buffer against gas price volatility.
    ///     In volatile conditions, if actual fulfillment tx costs more gas,
    ///     protocol gets less profit (or potentially loses money).
    uint256 public immutable protocolFeeBps;
    /// @notice requestId => contract to callback
    /// @dev contract must implement IRandomiserCallback
    mapping(uint256 => address) public callbackTargets;
    /// @notice Minimum period between rebalances
    uint256 public constant REBALANCE_INTERVAL = 6 hours;
    /// @notice Last recorded rebalance operation
    uint256 public lastRebalancedAt;

    event RandomnessRequested(
        uint256 indexed requestId,
        uint256 fulfilmentCostPaid,
        uint256 protocolFeePaid
    );
    event RandomnessFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event Rebalanced(
        uint64 oldSubId,
        uint64 newSubId,
        int256 linkBalanceDelta,
        int256 ethBalanceDelta
    );
    event SubscriptionRenewed(uint64 oldSubId, uint64 newSubId);
    event Withdrawn(address token, address recipient, uint256 amount);

    error InvalidFeedConfig(address feed, uint8 decimals);
    error InvalidFeedAnswer(
        int256 price,
        uint256 latestRoundId,
        uint256 updatedAt
    );
    error InsufficientFeePayment(
        uint32 callbackGasLimit,
        uint256 amountOffered,
        uint256 amountRequired
    );
    error RebalanceNotAvailable();
    error TransferFailed();
    error AbsoluteMaxGasLimitExceeded(
        uint256 callbackGasLimit,
        uint256 absoluteMaxGasLimit
    );

    struct RandomiserInitOpts {
        address vrfCoordinator;
        address linkToken;
        uint256 linkPremium;
        bytes32 gasLaneKeyHash;
        uint256 gasLaneMaxWei;
        uint256 absoluteMaxGasLimit;
        address feedLINKUSD;
        address feedETHUSD;
        address weth;
        address swapRouter;
        uint24 uniV3PoolFee;
        uint256 protocolFeeBps;
    }

    constructor(RandomiserInitOpts memory opts)
        VRFConsumerBaseV2(opts.vrfCoordinator)
    {
        vrfCoordinator = opts.vrfCoordinator;
        linkToken = opts.linkToken;
        juels = 10**LinkTokenInterface(opts.linkToken).decimals();
        linkPremium = opts.linkPremium;
        gasLaneKeyHash = opts.gasLaneKeyHash;
        gasLaneMaxWei = opts.gasLaneMaxWei;
        absoluteMaxGasLimit = opts.absoluteMaxGasLimit;

        feedLINKUSD = opts.feedLINKUSD;
        feedETHUSD = opts.feedETHUSD;
        weth = opts.weth;
        swapRouter = opts.swapRouter;
        uniV3PoolFee = opts.uniV3PoolFee;

        protocolFeeBps = opts.protocolFeeBps;

        // Create new subscription on the coordinator & add self as consumer
        subId = VRFCoordinatorV2Interface(opts.vrfCoordinator)
            .createSubscription();
        VRFCoordinatorV2Interface(opts.vrfCoordinator).addConsumer(
            subId,
            address(this)
        );
    }

    function typeAndVersion()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "LinklessVRF 1.2.0";
    }

    receive() external payable {
        // Do nothing. This contract will be receiving ETH from unwrapping WETH.
    }

    /// @notice Get latest feed price, checking correct configuration and that
    ///     the price is fresh.
    /// @param feed_ Address of AggregatorV2V3Interface price feed
    function getLatestFeedPrice(address feed_)
        internal
        view
        returns (uint256 price, uint8 decimals)
    {
        AggregatorV2V3Interface feed = AggregatorV2V3Interface(feed_);
        decimals = feed.decimals();
        if (decimals == 0) {
            revert InvalidFeedConfig(feedLINKUSD, decimals);
        }
        (uint80 roundId, int256 answer, , uint256 updatedAt, ) = feed
            .latestRoundData();
        if (answer <= 0 || ((block.timestamp - updatedAt) > MAX_AGE)) {
            revert InvalidFeedAnswer(answer, roundId, updatedAt);
        }
        return (uint256(answer), decimals);
    }

    /// @notice Get LINK/USD
    function getLINKUSD()
        internal
        view
        returns (uint256 price, uint8 decimals)
    {
        return getLatestFeedPrice(feedLINKUSD);
    }

    /// @notice get ETH/USD
    function getETHUSD() internal view returns (uint256 price, uint8 decimals) {
        return getLatestFeedPrice(feedETHUSD);
    }

    /// @notice Compute ETH/LINK price
    /// @return ETHLINK price upscaled to EXP_SCALE
    function getETHLINK() internal view returns (uint256) {
        (uint256 priceETHUSD, uint8 decETHUSD) = getETHUSD();
        (uint256 priceLINKUSD, uint8 decLINKUSD) = getLINKUSD();

        // Assumptions: price > 0, decimals > 0
        return
            (EXP_SCALE * priceETHUSD * (10**decLINKUSD)) /
            (priceLINKUSD * (10**decETHUSD));
    }

    /// @notice Compute LINK/ETH price
    /// @return LINKETH price upscaled to EXP_SCALE
    function getLINKETH() internal view returns (uint256) {
        (uint256 priceETHUSD, uint8 decETHUSD) = getETHUSD();
        (uint256 priceLINKUSD, uint8 decLINKUSD) = getLINKUSD();

        // Assumptions: price > 0, decimals > 0
        return
            (EXP_SCALE * priceLINKUSD * (10**decETHUSD)) /
            (priceETHUSD * (10**decLINKUSD));
    }

    /// @notice Compute the max request gas cost (in wei) by taking the
    ///     maximums defined in this VRF coordinator's configuration. This
    ///     serves as the *low watermark* level for subscription balance.
    /// @dev See:
    ///     https://docs.chain.link/vrf/v2/subscription#minimum-subscription-balance
    /// @return Maximum gas that could possibly consumed by a request.
    function maxRequestGasCost() public view returns (uint256) {
        return
            gasLaneMaxWei *
            (MAX_VERIFICATION_GAS +
                FULFILMENT_OVERHEAD_GAS +
                absoluteMaxGasLimit);
    }

    /// @notice Estimate how much ETH is necessary to fulfill a request
    /// @param callbackGasLimit Gas limit for callback
    /// @return Amount of wei required for VRF request
    function estimateFulfilmentCostETH(uint32 callbackGasLimit)
        internal
        view
        returns (uint256)
    {
        uint256 linkPremiumETH = (linkPremium * getLINKETH()) / EXP_SCALE;
        uint256 requestGasCostETH = L2GasUtil.getGasPrice() *
            (MAX_VERIFICATION_GAS + FULFILMENT_OVERHEAD_GAS + callbackGasLimit);
        // NB: Hardcoded estimate of 512B of tx calldata (real avg ~260B)
        uint256 l1GasFee = L2GasUtil.estimateTxL1GasFees(512);
        return requestGasCostETH + linkPremiumETH + l1GasFee;
    }

    /// @notice Total request cost including protocol fee, in ETH (wei)
    /// @param callbackGasLimit Gas limit to use for the callback function
    /// @return totalRequestCostETH Amount of wei required to request a random
    ///     number from this protocol.
    /// @return fulfilmentCostETH Amount of estimated wei required to complete
    ///     the VRF call.
    function _computeTotalRequestCostETH(uint32 callbackGasLimit)
        internal
        view
        returns (uint256 totalRequestCostETH, uint256 fulfilmentCostETH)
    {
        fulfilmentCostETH = estimateFulfilmentCostETH(callbackGasLimit);
        uint256 protocolFee = (fulfilmentCostETH * protocolFeeBps) / 10000;
        totalRequestCostETH = fulfilmentCostETH + protocolFee;
    }

    /// @notice Total request cost including protocol fee, in ETH (wei)
    /// @param callbackGasLimit Gas limit to use for the callback function
    /// @return Amount of wei required to request a random number from this
    ///     protocol.
    function computeTotalRequestCostETH(uint32 callbackGasLimit)
        public
        view
        returns (uint256)
    {
        (uint256 totalRequestCostETH, ) = _computeTotalRequestCostETH(
            callbackGasLimit
        );
        return totalRequestCostETH;
    }

    /// @notice Swap LINK to ETH via Uniswap V3, using a Chainlink feed to
    ///     calculate the rate, and asserts a maximum amount of slippage.
    /// @param linkAmount Amount of ETH to swap
    /// @return Amount of ETH received
    function swapLINKToETH(uint256 linkAmount, uint16 maxSlippageBps)
        internal
        returns (uint256)
    {
        // Get rate for ETH->LINK using feed
        uint256 amountETHAtRate = (linkAmount * EXP_SCALE) / getETHLINK();
        uint256 maxSlippageDelta = (amountETHAtRate * maxSlippageBps) / 10000;
        // Minimum ETH output taking into account max allowable slippage
        uint256 amountOutMinimum = amountETHAtRate - maxSlippageDelta;

        // Approve LINK to SwapRouter
        LinkTokenInterface(linkToken).approve(swapRouter, linkAmount);

        // Swap ETH->LINK
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: linkToken,
                tokenOut: weth,
                fee: uniV3PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: linkAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(params);

        // Unwrap WETH->ETH
        IWETH9(weth).withdraw(amountOut);

        return amountOut;
    }

    /// @notice Swap ETH to LINK via Uniswap V3, using a Chainlink feed to
    ///     calculate the rate, and asserts a maximum amount of slippage.
    /// @param ethAmount Amount of ETH to swap
    /// @return Amount of LINK received
    function swapETHToLINK(uint256 ethAmount, uint16 maxSlippageBps)
        internal
        returns (uint256)
    {
        // Get rate for ETH->LINK using feed
        uint256 amountLINKAtRate = (ethAmount * EXP_SCALE) / getLINKETH();
        uint256 maxSlippageDelta = (amountLINKAtRate * maxSlippageBps) / 10000;
        // Minimum LINK output taking into account max allowable slippage
        uint256 amountOutMinimum = amountLINKAtRate - maxSlippageDelta;

        // Wrap ETH->WETH & approve amount for UniV3 swap router
        IWETH9(weth).deposit{value: ethAmount}();
        IWETH9(weth).approve(swapRouter, ethAmount);

        // Swap ETH->LINK
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: weth,
                tokenOut: linkToken,
                fee: uniV3PoolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: ethAmount,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
        return ISwapRouter(swapRouter).exactInputSingle(params);
    }

    /// @notice Request a random number
    /// @param callbackContract Target contract to callback
    /// @param callbackGasLimit Maximum amount of gas that can be consumed by
    ///     the callback function
    /// @param minConfirmations Number of block confirmations to wait before
    ///     the VRF request can be fulfilled
    /// @return requestId Request ID from VRF Coordinator
    function getRandomNumber(
        address callbackContract,
        uint32 callbackGasLimit,
        uint16 minConfirmations
    ) public payable override returns (uint256 requestId) {
        if (callbackGasLimit > absoluteMaxGasLimit) {
            revert AbsoluteMaxGasLimitExceeded(
                callbackGasLimit,
                absoluteMaxGasLimit
            );
        }
        // Assert payment is enough
        (
            uint256 totalRequestCostETH,
            uint256 fulfilmentCostETH
        ) = _computeTotalRequestCostETH(callbackGasLimit);
        if (msg.value < totalRequestCostETH) {
            revert InsufficientFeePayment(
                callbackGasLimit,
                msg.value,
                totalRequestCostETH
            );
        }

        // Check if sub balance is below the low watermark
        uint64 subId_ = subId;
        (uint96 balance, , , ) = VRFCoordinatorV2Interface(vrfCoordinator)
            .getSubscription(subId);
        if (balance < maxRequestGasCost()) {
            // Subscription needs to be topped up
            uint256 amountLINKReceived = swapETHToLINK(
                fulfilmentCostETH,
                75 /** NB: Hardcoded -0.75% max slippage */
            );
            // Fund subscription with swapped LINK
            LinkTokenInterface(linkToken).transferAndCall(
                vrfCoordinator,
                amountLINKReceived,
                abi.encode(subId_)
            );
        }

        // Finally, make the VRF request
        requestId = VRFCoordinatorV2Interface(vrfCoordinator)
            .requestRandomWords(
                gasLaneKeyHash,
                subId_,
                minConfirmations,
                callbackGasLimit,
                1
            );
        callbackTargets[requestId] = callbackContract;
        emit RandomnessRequested(
            requestId,
            fulfilmentCostETH,
            totalRequestCostETH - fulfilmentCostETH
        );
    }

    /// @notice Callback function used by VRF Coordinator
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        address target = callbackTargets[requestId];
        delete callbackTargets[requestId];

        IRandomiserCallback(target).receiveRandomWords(requestId, randomWords);
        emit RandomnessFulfilled(requestId, randomWords);
    }

    /// @notice Get params that determine if a rebalance is possible.
    ///     NB: Does NOT take into account LINK balance on this contract; only
    ///     takes into account the subscription LINK balance.
    /// @dev Keeper function
    function isRebalanceAvailable()
        public
        view
        returns (
            bool isAvailable,
            uint256 subLINKBalance,
            uint256 lowWatermarkLINK,
            uint256 lowWatermarkETH
        )
    {
        (subLINKBalance, , , ) = VRFCoordinatorV2Interface(vrfCoordinator)
            .getSubscription(subId);
        lowWatermarkETH = maxRequestGasCost();
        lowWatermarkLINK = (lowWatermarkETH * EXP_SCALE) / getLINKETH();

        bool hasRebalanceIntervalElapsed = block.timestamp - lastRebalancedAt >=
            REBALANCE_INTERVAL;
        bool needsRebalance = (subLINKBalance > 2 * lowWatermarkLINK) ||
            ((subLINKBalance < lowWatermarkLINK) &&
                (address(this).balance >= lowWatermarkETH));
        isAvailable = hasRebalanceIntervalElapsed && needsRebalance;
    }

    /// @notice Perform upkeep by cancelling the subscription iff sub balance
    ///     is above the low watermark. By cancelling the sub, LINK is
    ///     returned to this contract. This contract will then buy ETH with
    ///     excess LINK. A new subscription is then created to replace the
    ///     existing subscription.
    /// @dev Keeper function
    function rebalance() public {
        (
            bool isAvailable,
            uint256 subLINKBalance,
            uint256 lowWatermarkLINK,
            uint256 lowWatermarkETH
        ) = isRebalanceAvailable();
        if (!isAvailable) {
            revert RebalanceNotAvailable();
        }
        lastRebalancedAt = block.timestamp;

        if (subLINKBalance > 2 * lowWatermarkLINK) {
            // Case 0: Excess LINK can be swapped to ETH.
            uint64 oldSubId = subId;
            VRFCoordinatorV2Interface coord = VRFCoordinatorV2Interface(
                vrfCoordinator
            );
            // Cancel subscription and receive LINK refund to this contract
            coord.cancelSubscription(oldSubId, address(this));
            // Create new subscription
            uint64 newSubId = coord.createSubscription();
            coord.addConsumer(newSubId, address(this));
            subId = newSubId;
            emit SubscriptionRenewed(oldSubId, newSubId);
            // Fund the new subscription upto the low watermark
            LinkTokenInterface(linkToken).transferAndCall(
                vrfCoordinator,
                lowWatermarkLINK,
                abi.encode(newSubId)
            );
            // Dump any LINK that's left in the contract
            uint256 ownLINKBalance = LinkTokenInterface(linkToken).balanceOf(
                address(this)
            );
            uint256 receivedETH = swapLINKToETH(
                ownLINKBalance,
                75 /** NB: Hardcoded -0.75% max slippage */
            );
            emit Rebalanced(
                oldSubId,
                newSubId,
                -int256(ownLINKBalance),
                int256(receivedETH)
            );
        } else if (subLINKBalance < lowWatermarkLINK) {
            // NB: (address(this).balance >= lowWatermarkETH) is true here
            // Case 1: Sub balance is below the watermark, so we need to swap
            // ETH to LINK, if there is ETH balance available.
            // Swap ETH to LINK with available balance
            uint256 receivedLINK = swapETHToLINK(
                lowWatermarkETH,
                75 /** NB: Hardcoded -0.75% max slippage */
            );
            // Fund the subscription with received LINK
            uint64 currentSubId = subId;
            LinkTokenInterface(linkToken).transferAndCall(
                vrfCoordinator,
                receivedLINK,
                abi.encode(currentSubId)
            );
            emit Rebalanced(
                currentSubId,
                currentSubId,
                int256(receivedLINK),
                -int256(lowWatermarkETH)
            );
        } else {
            // This branch should not be reachable
            revert("Logic error");
        }
    }

    /// @notice Cancel a subscription to receive a refund; then create a new
    ///     one and add self as consumer.
    /// @dev This is here in case we need to manually withdraw LINK to TWAP;
    ///     which may be necessary if a `rebalance()` would move the Uniswap
    ///     pool price so much that it becomes impossible to execute with the
    ///     hardcoded max slippage.
    function renewSubscription()
        external
        onlyAuthorised
        returns (uint64 oldSubId, uint64 newSubId)
    {
        VRFCoordinatorV2Interface coord = VRFCoordinatorV2Interface(
            vrfCoordinator
        );
        oldSubId = subId;
        coord.cancelSubscription(oldSubId, address(this));
        newSubId = coord.createSubscription();
        subId = newSubId;
        coord.addConsumer(newSubId, address(this));
        emit SubscriptionRenewed(oldSubId, newSubId);
    }

    /// @notice Fund the subscription managed by this contract. This is not
    ///     actually *needed* since we should be able to arbitrarily fund any
    ///     subscription, but is here for convenience. The required LINK amount
    ///     must be already in this contract's balance.
    /// @param amount Amount of LINK to fund the subscription with. This amount
    ///     of LINK must already be in the contract balance.
    function fundSubscription(uint256 amount) external {
        if (amount == 0) {
            amount = LinkTokenInterface(linkToken).balanceOf(address(this));
        }
        LinkTokenInterface(linkToken).transferAndCall(
            vrfCoordinator,
            amount,
            abi.encode(subId)
        );
    }

    /// @notice Withdraw ERC-20 tokens
    /// @param token Address of ERC-20
    /// @param amount Amount to withdraw, withdraws entire balance if 0
    function withdrawERC20(address token, uint256 amount)
        external
        onlyAuthorised
    {
        if (amount == 0) {
            amount = IERC20(token).balanceOf(address(this));
        }
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawn(token, msg.sender, amount);
    }

    /// @notice Withdraw ETH
    /// @param amount Amount to withdraw, withdraws entire balance if 0
    function withdrawETH(uint256 amount) external onlyAuthorised {
        if (amount == 0) {
            amount = address(this).balance;
        }
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();
        emit Withdrawn(
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            msg.sender,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

/// @title Authorised
/// @notice Restrict functions to whitelisted admins with the `onlyAdmin`
///     modifier. Deployer of contract is automatically added as an admin.
contract Authorised {
    /// @notice Whitelisted admins
    mapping(address => bool) public isAuthorised;

    error NotAuthorised(address culprit);

    constructor() {
        isAuthorised[msg.sender] = true;
    }

    /// @notice Restrict function to whitelisted admins only
    modifier onlyAuthorised() {
        if (!isAuthorised[msg.sender]) {
            revert NotAuthorised(msg.sender);
        }
        _;
    }

    /// @notice Set authorisation of a specific account
    /// @param toggle `true` to authorise account as an admin
    function authorise(address guy, bool toggle) public onlyAuthorised {
        isAuthorised[guy] = toggle;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ArbGasInfo} from "../interfaces/nitro/ArbGasInfo.sol";
import {NodeInterface} from "../interfaces/nitro/NodeInterface.sol";

/// @title L2GasUtil
/// @notice Helper to estimate total gas costs when performing transactions on
///     supported L2 networks.
library L2GasUtil {
    uint256 public constant ARB1_CHAIN_ID = 0xa4b1;
    ArbGasInfo public constant ARB_GAS_INFO = ArbGasInfo(address(0x6c));

    /// @notice Return the price, in wei, to be paid to the L2 per gas unit.
    function getGasPrice() internal view returns (uint256) {
        if (block.chainid == ARB1_CHAIN_ID) {
            (
                ,
                ,
                ,
                ,
                ,
                /** base */
                /** congestion */
                uint256 totalGasPrice
            ) = ARB_GAS_INFO.getPricesInWei();
            return totalGasPrice;
        }

        return tx.gasprice;
    }

    /// @notice Estimate the L1 gas fees to be paid by a transaction with a
    ///     specific calldata byte length, if being called on an L2.
    /// @param txDataByteLen Length, in bytes, of tx calldata that will be
    ///     posted to L1
    function estimateTxL1GasFees(uint256 txDataByteLen)
        internal
        view
        returns (uint256)
    {
        if (block.chainid == ARB1_CHAIN_ID) {
            (, uint256 weiPerL1CalldataByte, , , , ) = ARB_GAS_INFO
                .getPricesInWei();
            return weiPerL1CalldataByte * (140 + txDataByteLen);
        }

        return 0;
    }

    /// @notice Return share of L1 gas fee payable by this tx if on an L2,
    ///     otherwise returns 0
    function getCurrentTxL1GasFees() internal view returns (uint256) {
        if (block.chainid == ARB1_CHAIN_ID) {
            return ARB_GAS_INFO.getCurrentTxL1GasFees();
        }

        return 0;
    }
}