// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ILiquidationSource, TpdaLiquidationPair } from "./TpdaLiquidationPair.sol";

/// @title TpdaLiquidationPairFactory
/// @author G9 Software Inc.
/// @notice Factory contract for deploying TpdaLiquidationPair contracts.
contract TpdaLiquidationPairFactory {
    /* ============ Events ============ */

    /// @notice Emitted when a new TpdaLiquidationPair is created
    /// @param pair The address of the new pair
    /// @param source The liquidation source that the pair is using
    /// @param tokenIn The input token for the pair
    /// @param tokenOut The output token for the pair
    /// @param targetAuctionPeriod The duration of auctions
    /// @param targetAuctionPrice The minimum auction size in output tokens
    /// @param smoothingFactor The 18 decimal smoothing fraction for the liquid balance
    event PairCreated(
        TpdaLiquidationPair indexed pair,
        ILiquidationSource source,
        address indexed tokenIn,
        address indexed tokenOut,
        uint64 targetAuctionPeriod,
        uint192 targetAuctionPrice,
        uint256 smoothingFactor
    );

    /* ============ Variables ============ */

    /// @notice Tracks an array of all pairs created by this factory
    TpdaLiquidationPair[] public allPairs;

    /* ============ Mappings ============ */

    /// @notice Mapping to verify if a TpdaLiquidationPair has been deployed via this factory.
    mapping(address pair => bool wasDeployed) public deployedPairs;

    /// @notice Creates a new TpdaLiquidationPair and registers it within the factory
    /// @param _source The liquidation source that the pair will use
    /// @param _tokenIn The input token for the pair
    /// @param _tokenOut The output token for the pair
    /// @param _targetAuctionPeriod The duration of auctions
    /// @param _targetAuctionPrice The initial auction price
    /// @param _smoothingFactor The degree of smoothing to apply to the available token balance
    /// @return The new liquidation pair
    function createPair(
        ILiquidationSource _source,
        address _tokenIn,
        address _tokenOut,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) external returns (TpdaLiquidationPair) {
        TpdaLiquidationPair _liquidationPair = new TpdaLiquidationPair(
            _source,
            _tokenIn,
            _tokenOut,
            _targetAuctionPeriod,
            _targetAuctionPrice,
            _smoothingFactor
        );

        allPairs.push(_liquidationPair);
        deployedPairs[address(_liquidationPair)] = true;

        emit PairCreated(
            _liquidationPair,
            _source,
            _tokenIn,
            _tokenOut,
            _targetAuctionPeriod,
            _targetAuctionPrice,
            _smoothingFactor
        );

        return _liquidationPair;
    }

    /// @notice Total number of TpdaLiquidationPair deployed by this factory.
    /// @return Number of TpdaLiquidationPair deployed by this factory.
    function totalPairs() external view returns (uint256) {
        return allPairs.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { ILiquidationSource } from "pt-v5-liquidator-interfaces/ILiquidationSource.sol";
import { ILiquidationPair } from "pt-v5-liquidator-interfaces/ILiquidationPair.sol";
import { IFlashSwapCallback } from "pt-v5-liquidator-interfaces/IFlashSwapCallback.sol";

/// @notice Thrown when the actual swap amount in exceeds the user defined maximum amount in
/// @param amountInMax The user-defined max amount in
/// @param amountIn The actual amount in
error SwapExceedsMax(uint256 amountInMax, uint256 amountIn);

/// @notice Thrown when the amount out requested is greater than the available balance
/// @param requested The amount requested to swap
/// @param available The amount available to swap
error InsufficientBalance(uint256 requested, uint256 available);

/// @notice Thrown when the receiver of the swap is the zero address
error ReceiverIsZero();

/// @notice Thrown when the smoothing parameter is 1 or greater
error SmoothingGteOne();

// The minimum auction price. This ensures the auction cannot get bricked to zero.
uint192 constant MIN_PRICE = 100;

/// @title Target Period Dutch Auction Liquidation Pair
/// @author G9 Software Inc.
/// @notice This contract sells one token for another at a target time interval. The pricing algorithm is designed
/// such that the price of the auction is inversely proportional to the time since the last auction.
/// auctionPrice = (targetAuctionPeriod / elapsedTimeSinceLastAuction) * lastAuctionPrice
contract TpdaLiquidationPair is ILiquidationPair {

    /// @notice Emitted when a swap is made
    /// @param sender The sender of the swap
    /// @param receiver The receiver of the swap
    /// @param amountOut The amount of tokens out
    /// @param amountInMax The maximum amount of tokens in
    /// @param amountIn The actual amount of tokens in
    /// @param flashSwapData The data used for the flash swap
    event SwappedExactAmountOut(
        address indexed sender,
        address indexed receiver,
        uint256 amountOut,
        uint256 amountInMax,
        uint256 amountIn,
        bytes flashSwapData
    );

    /// @notice The liquidation source
    ILiquidationSource public immutable source;

    /// @notice The target time interval between auctions
    uint256 public immutable targetAuctionPeriod;

    /// @notice The token that is being purchased
    IERC20 internal immutable _tokenIn;

    /// @notice The token that is being sold
    IERC20 internal immutable _tokenOut;

    /// @notice The degree of smoothing to apply to the available token balance
    uint256 public immutable smoothingFactor;    

    /// @notice The time at which the last auction occurred
    uint64 public lastAuctionAt;

    /// @notice The price of the last auction
    uint192 public lastAuctionPrice;

    /// @notice Constructors a new TpdaLiquidationPair
    /// @param _source The liquidation source
    /// @param __tokenIn The token that is being purchased by the source
    /// @param __tokenOut The token that is being sold by the source
    /// @param _targetAuctionPeriod The target time interval between auctions
    /// @param _targetAuctionPrice The first target price of the auction
    /// @param _smoothingFactor The degree of smoothing to apply to the available token balance
    constructor (
        ILiquidationSource _source,
        address __tokenIn,
        address __tokenOut,
        uint64 _targetAuctionPeriod,
        uint192 _targetAuctionPrice,
        uint256 _smoothingFactor
    ) {
        if (_smoothingFactor >= 1e18) {
            revert SmoothingGteOne();
        }

        source = _source;
        _tokenIn = IERC20(__tokenIn);
        _tokenOut = IERC20(__tokenOut);
        targetAuctionPeriod = _targetAuctionPeriod;
        smoothingFactor = _smoothingFactor;

        lastAuctionAt = uint64(block.timestamp);
        lastAuctionPrice = _targetAuctionPrice;
    }

    /// @inheritdoc ILiquidationPair
    function tokenIn() external view returns (address) {
        return address(_tokenIn);
    }

    /// @inheritdoc ILiquidationPair
    function tokenOut() external view returns (address) {
        return address(_tokenOut);
    }

    /// @inheritdoc ILiquidationPair
    function target() external returns (address) {
        return source.targetOf(address(_tokenIn));
    }

    /// @inheritdoc ILiquidationPair
    function maxAmountOut() external returns (uint256) {  
        return _availableBalance();
    }

    /// @inheritdoc ILiquidationPair
    function swapExactAmountOut(
        address _receiver,
        uint256 _amountOut,
        uint256 _amountInMax,
        bytes calldata _flashSwapData
    ) external returns (uint256) {
        if (_receiver == address(0)) {
            revert ReceiverIsZero();
        }

        uint192 swapAmountIn = _computePrice();

        if (swapAmountIn > _amountInMax) {
            revert SwapExceedsMax(_amountInMax, swapAmountIn);
        }

        lastAuctionAt = uint64(block.timestamp);
        lastAuctionPrice = swapAmountIn;

        uint256 availableOut = _availableBalance();
        if (_amountOut > availableOut) {
            revert InsufficientBalance(_amountOut, availableOut);
        }

        bytes memory transferTokensOutData = source.transferTokensOut(
            msg.sender,
            _receiver,
            address(_tokenOut),
            _amountOut
        );

        if (_flashSwapData.length > 0) {
            IFlashSwapCallback(_receiver).flashSwapCallback(
                msg.sender,
                swapAmountIn,
                _amountOut,
                _flashSwapData
            );
        }

        source.verifyTokensIn(address(_tokenIn), swapAmountIn, transferTokensOutData);

        emit SwappedExactAmountOut(msg.sender, _receiver, _amountOut, _amountInMax, swapAmountIn, _flashSwapData);

        return swapAmountIn;
    }

    /// @inheritdoc ILiquidationPair
    function computeExactAmountIn(uint256) external view returns (uint256) {
        return _computePrice();
    }

    /// @notice Computes the time at which the given auction price will occur
    /// @param price The price of the auction
    /// @return The timestamp at which the given price will occur
    function computeTimeForPrice(uint256 price) external view returns (uint256) {
        // p2/p1 = t/e => e = (t*p1)/p2
        return lastAuctionAt + (targetAuctionPeriod * lastAuctionPrice) / price;
    }

    /// @notice Computes the available balance of the tokens to be sold
    /// @return The available balance of the tokens
    function _availableBalance() internal returns (uint256) {
        return ((1e18 - smoothingFactor) * source.liquidatableBalanceOf(address(_tokenOut))) / 1e18;
    }

    /// @notice Computes the current auction price
    /// @return The current auction price
    function _computePrice() internal view returns (uint192) {
        uint256 elapsedTime = block.timestamp - lastAuctionAt;
        if (elapsedTime == 0) {
            return type(uint192).max;
        }
        uint192 price = uint192((targetAuctionPeriod * lastAuctionPrice) / elapsedTime);

        if (price < MIN_PRICE) {
            price = MIN_PRICE;
        }

        return price;
    }

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
pragma solidity ^0.8.0;

interface ILiquidationSource {

  /**
   * @notice Emitted when a new liquidation pair is set for the given `tokenOut`.
   * @param tokenOut The token being liquidated
   * @param liquidationPair The new liquidation pair for the token
   */
  event LiquidationPairSet(address indexed tokenOut, address indexed liquidationPair);

  /**
   * @notice Get the available amount of tokens that can be swapped.
   * @param tokenOut Address of the token to get available balance for
   * @return uint256 Available amount of `token`
   */
  function liquidatableBalanceOf(address tokenOut) external returns (uint256);

  /**
   * @notice Transfers tokens to the receiver
   * @param sender Address that triggered the liquidation
   * @param receiver Address of the account that will receive `tokenOut`
   * @param tokenOut Address of the token being bought
   * @param amountOut Amount of token being bought
   */
  function transferTokensOut(
    address sender,
    address receiver,
    address tokenOut,
    uint256 amountOut
  ) external returns (bytes memory);

  /**
   * @notice Verifies that tokens have been transferred in.
   * @param tokenIn Address of the token being sold
   * @param amountIn Amount of token being sold
   * @param transferTokensOutData Data returned by the corresponding transferTokensOut call
   */
  function verifyTokensIn(
    address tokenIn,
    uint256 amountIn,
    bytes calldata transferTokensOutData
  ) external;

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @param tokenIn Address of the token to get the target address for
   * @return address Address of the target
   */
  function targetOf(address tokenIn) external returns (address);

  /**
   * @notice Checks if a liquidation pair can be used to liquidate the given tokenOut from this source.
   * @param tokenOut The address of the token to liquidate
   * @param liquidationPair The address of the liquidation pair that is being checked
   * @return bool True if the liquidation pair can be used, false otherwise
   */
  function isLiquidationPair(address tokenOut, address liquidationPair) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ILiquidationSource } from "./ILiquidationSource.sol";

interface ILiquidationPair {

  /**
   * @notice The liquidation source that the pair is using.
   * @dev The source executes the actual token swap, while the pair handles the pricing.
   */
  function source() external returns (ILiquidationSource);

  /**
   * @notice Returns the token that is used to pay for auctions.
   * @return address of the token coming in
   */
  function tokenIn() external returns (address);

  /**
   * @notice Returns the token that is being auctioned.
   * @return address of the token coming out
   */
  function tokenOut() external returns (address);

  /**
   * @notice Get the address that will receive `tokenIn`.
   * @return Address of the target
   */
  function target() external returns (address);

  /**
   * @notice Gets the maximum amount of tokens that can be swapped out from the source.
   * @return The maximum amount of tokens that can be swapped out.
   */
  function maxAmountOut() external returns (uint256);

  /**
   * @notice Swaps the given amount of tokens out and ensures the amount of tokens in doesn't exceed the given maximum.
   * @dev The amount of tokens being swapped in must be sent to the target before calling this function.
   * @param _receiver The address to send the tokens to.
   * @param _amountOut The amount of tokens to receive out.
   * @param _amountInMax The maximum amount of tokens to send in.
   * @param _flashSwapData If non-zero, the _receiver is called with this data prior to
   * @return The amount of tokens sent in.
   */
  function swapExactAmountOut(
    address _receiver,
    uint256 _amountOut,
    uint256 _amountInMax,
    bytes calldata _flashSwapData
  ) external returns (uint256);

  /**
   * @notice Computes the exact amount of tokens to send in for the given amount of tokens to receive out.
   * @param _amountOut The amount of tokens to receive out.
   * @return The amount of tokens to send in.
   */
  function computeExactAmountIn(uint256 _amountOut) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Interface for the flash swap callback
interface IFlashSwapCallback {

    /// @notice Called on the token receiver by the LiquidationPair during a liquidation if the flashSwap data length is non-zero
    /// @param _sender The address that triggered the liquidation swap
    /// @param _amountOut The amount of tokens that were sent to the receiver
    /// @param _amountIn The amount of tokens expected to be sent to the target
    /// @param _flashSwapData The flash swap data that was passed into the swap function.
    function flashSwapCallback(
        address _sender,
        uint256 _amountIn,
        uint256 _amountOut,
        bytes calldata _flashSwapData
    ) external;
}