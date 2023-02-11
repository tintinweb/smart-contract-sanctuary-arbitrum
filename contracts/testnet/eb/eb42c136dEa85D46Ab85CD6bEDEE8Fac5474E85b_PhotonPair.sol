// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './Tick.sol';
import './TickBitmap.sol';
import './TickMath.sol';
import './ABDKMath64x64.sol';
import './IERC20Minimal.sol';
import './IUniswapV2Router02.sol';
import './IWETH.sol';
import './PhotonRouter.sol';


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
		// On the first call to nonReentrant, _notEntered will be true
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
	/// @dev The original address of this contract
	address private immutable original;

	constructor() {
		// Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
		// In other words, this variable won't change when it's checked at runtime.
		original = address(this);
	}

	/// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
	///     and the use of immutable means the address bytes are copied in every place the modifier is used.
	function checkNotDelegateCall() private view {
		require(address(this) == original);
	}

	/// @notice Prevents delegatecall into the modified method
	modifier noDelegateCall() {
		checkNotDelegateCall();
		_;
	}
}

/// Pair contract for Photon Protocol
contract PhotonPair is ReentrancyGuard, NoDelegateCall {

	using Tick for mapping(int24 => Tick.Info);
	using TickBitmap for mapping(int16 => uint256);

	/// Immutables
	address public immutable router;
	address public immutable tokenX;
	address public immutable tokenY;
	uint256 public immutable tickMode;

	/// Protocol fee (only applies to tokenX) - protocolFee / 10000 is the fee ratio
	uint256 public protocolFee;
	uint256 public feeTokenXAmountAccumulated;
	uint256 public swapFeeTokenXAmountAt;
	address public tokenXPairedAddress; //address tokenX is paired with (usually WETH)

	/// Current order ID
	uint256 public ORDER_ID;

	/// Order indexed state
	struct Order {
		address maker;
		int24 tick;
		uint128 tickMultiplier; //multiplier of tick at order creation
		uint256 tokenXAmount;
		uint256 creationTimestamp;
	}

	/// Slot0
	int24 public lowestTick;

	/// Maps tick index to info
	mapping(int24 => Tick.Info) public ticks;

	/// Tick bitmap
	mapping(int16 => uint256) public tickBitmap;

	/// Maps orderId to order
	mapping(uint256 => Order) orderIdMapping;

	/// Maps wallet to list of orderIds
	mapping(address => uint256[]) public orderIdsByMaker;

	/// Modifier to allow only router to make a call
	modifier onlyRouter() {
		require(msg.sender == router);
		_;
	}

	/// Modifier to allow only router owner to make a call
	modifier onlyRouterOwner() {
		require(msg.sender == PhotonRouter(router).owner());
		_;
	}

	/// Transfer failed error
	error TransferFailed();


	/// Constructooor
	constructor(address _router, address _tokenX, address _tokenY, uint256 _tickMode) {
		router = _router;
		tokenX = _tokenX;
		tokenY = _tokenY;
		tickMode = _tickMode;
	}


	/// @dev Get the contract's balance of token
	/// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
	/// check
	function tokenBalance(address token) private view returns (uint256) {
		(bool success, bytes memory data) = token.staticcall(
			abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this))
		);
		require(success && data.length >= 32);
		return abi.decode(data, (uint256));
	}

	/// @dev Get all orderIds for maker
	function getOrderIdsByMaker(address maker) external view returns (uint256[] memory) {
		return orderIdsByMaker[maker];
	}

	/// @dev Get tick info for tick
	function getTickInfo(int24 tick) external view returns (Tick.Info memory) {
		return ticks[tick];
	}

	/// @dev Get tick bitmap for word corresponding to tick
	function getTickBitmap(int24 tick) external view returns (uint256) {
		return tickBitmap[int16(tick >> 8)];
	}

	/// @dev Get order info for orderId
	function getOrderInfo(uint256 orderId) external view returns (Order memory) {
		return orderIdMapping[orderId];
	}

	/// @dev Gets tokenYAmount required for exact tokenXAmount
	/// @param tokenXAmount the exact amount of tokenX desired
	function getExactTokenYForTokenX(uint256 tokenXAmount) external view returns (uint256 tokenYAmountRequired) {
		require(tokenXAmount > 0);
		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		while (tokenXAmount > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			if (initialized) {
				(uint256 requiredTokenYAmount, uint256 usedTokenXAmount) = ticks.simulateExecute(currTick, tickModeForPair, tokenXAmount);
				tokenXAmount -= usedTokenXAmount;
				tokenYAmountRequired += requiredTokenYAmount;
			}

			if (tokenXAmount > 0) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}
	}

	/// @dev Gets expected tokenXAmount for exact tokenYAmount
	/// @param tokenYAmount the exact amount of tokenY desired
	function getExactTokenXForTokenY(uint256 tokenYAmount) external view returns (uint256 tokenXAmountOut) {
		require(tokenYAmount > 0);
		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		while (tokenYAmount > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			if (initialized) {
				(uint256 requiredTokenXAmount, uint256 usedTokenYAmount) = ticks.simulateExecuteWithTokenY(currTick, tickModeForPair, tokenYAmount);
				tokenYAmount -= usedTokenYAmount;
				tokenXAmountOut += requiredTokenXAmount;
			}

			if (tokenYAmount > 0) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}
	}



	/// @dev Create limit order at tick
	function createLimitOrder(uint256 tokenXAmount, int24 tick, address maker) external nonReentrant noDelegateCall onlyRouter returns (uint256 orderId) {
		//create order
		orderId = ++ORDER_ID;
		orderIdsByMaker[maker].push(orderId);

		//update tickInfo for tick and flip tick if necessary
		(bool flipped, uint128 tickMultiplier) = ticks.update(tick, tokenXAmount, false);
		if (flipped) tickBitmap.initializeTick(tick);
		orderIdMapping[orderId] = Order({
			maker: maker,
			tick: tick,
			tokenXAmount: tokenXAmount,
			creationTimestamp: block.timestamp,
			tickMultiplier: tickMultiplier
		});

		//update lowestTick
		if (lowestTick > tick || ticks[lowestTick].tokenXAmount == 0) lowestTick = tick;
	}


	/// @dev Swaps tokenY for exact tokenX, ensuring tokenYAmount required doesn't exceed maxTokenYAmount
	/// @param tokenXAmount the exact amount of tokenX desired
	/// @param maxTokenYAmount the maximum tokenY amount to be spent
	function swapTokenYForExactTokenX(uint256 tokenXAmount, uint256 maxTokenYAmount, address maker) external nonReentrant noDelegateCall onlyRouter {
		require(tokenXAmount > 0 && maxTokenYAmount > 0);

		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		uint256 tokenYAmountAccumulated;
		uint256 tokenXAmountRemaining = tokenXAmount;
		while (tokenXAmountRemaining > 0 && tokenYAmountAccumulated < maxTokenYAmount) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			bool flipped;
			if (initialized) {
				(bool currFlipped, uint256 requiredTokenYAmount, uint256 usedTokenXAmount) = ticks.execute(currTick, tickModeForPair, tokenXAmountRemaining);
				flipped = currFlipped;
				tokenXAmountRemaining -= usedTokenXAmount;
				tokenYAmountAccumulated += requiredTokenYAmount;
			}

			// if (flipped) tickBitmap.resetTick(currTick); //an unecessary SSTORE, since a tick thats initialized in bitmap but not in storage wont make any changes.

			if (tokenXAmountRemaining > 0 || flipped) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}

		//check to make sure desired tokenXAmount is met and tokenYAmountAccumulated doesn't exceed maxTokenYAmount
		require(tokenYAmountAccumulated <= maxTokenYAmount);

		//take protocol fees, transfer tokenXAmount and refund tokenY if necessary
		uint256 currProtocolFeeTokenX = protocolFee;
		if (currProtocolFeeTokenX != 0) {
			uint256 tokenXFeeAmount = tokenXAmount * currProtocolFeeTokenX / 10000;
			tokenXAmount -= tokenXFeeAmount;
			feeTokenXAmountAccumulated += tokenXFeeAmount;
			//TODO: if feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt, swap tokenX for protocol token and burn protocol token.
			if (feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt) {
				swapFeeAndBurn();
			}
		}
		if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmount)) revert TransferFailed();
		if (tokenYAmountAccumulated < maxTokenYAmount) {
			if (!IERC20Minimal(tokenY).transfer(maker, maxTokenYAmount - tokenYAmountAccumulated)) revert TransferFailed();
		}

		//update lowestTick
		lowestTick = currTick;
	}


	/// @dev Swaps exact tokenY for tokenX, ensuring tokenXAmount is atleast minTokenXAmount
	/// @param tokenYAmount the exact amount of tokenY desired
	/// @param minTokenXAmount the minimum tokenX amount to be received
	function swapExactTokenYForTokenX(uint256 tokenYAmount, uint256 minTokenXAmount, address maker) external nonReentrant noDelegateCall onlyRouter {
		require(tokenYAmount > 0);

		int24 currTick = lowestTick;
		uint256 tickModeForPair = tickMode;
		bool initialized = true; //assume tick at slot0 is initialized

		// NOTE: while loop will run forever if there isn't enough liquidity to satisfy order, causing an error!
		uint256 tokenXAmountAccumulated;
		uint256 tokenYAmountRemaining = tokenYAmount;
		while (tokenYAmountRemaining > 0) {
			//only executing if initialized saves an unnecessary SLOAD in tick.execute(). If not initialized we simply proceed to next initialized tick.
			bool flipped;
			if (initialized) {
				(bool currFlipped, uint256 requiredTokenXAmount, uint256 usedTokenYAmount) = ticks.executeWithTokenY(currTick, tickModeForPair, tokenYAmountRemaining);
				flipped = currFlipped;
				tokenYAmountRemaining -= usedTokenYAmount;
				tokenXAmountAccumulated += requiredTokenXAmount;
			}

			// if (flipped) tickBitmap.resetTick(currTick); //an unecessary SSTORE, since a tick thats initialized in bitmap but not in storage wont make any changes.

			if (tokenYAmountRemaining > 0 || flipped) {
				(currTick, initialized) = tickBitmap.nextInitializedTickWithinOneWord(currTick + 1);
			}
		}

		//check to make sure desired tokenXAmount is met and tokenXAmountAccumulated is at least minTokenXAmount
		require(tokenXAmountAccumulated >= minTokenXAmount);

		//take protocol fees, transfer tokenXAmountAccumulated
		uint256 currProtocolFeeTokenX = protocolFee;
		if (currProtocolFeeTokenX != 0) {
			uint256 tokenXFeeAmount = tokenXAmountAccumulated * currProtocolFeeTokenX / 10000;
			tokenXAmountAccumulated -= tokenXFeeAmount;
			feeTokenXAmountAccumulated += tokenXFeeAmount;
			//TODO: if feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt, swap tokenX for protocol token and burn protocol token.
			if (feeTokenXAmountAccumulated >= swapFeeTokenXAmountAt) {
				swapFeeAndBurn();
			}
		}
		if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmountAccumulated)) revert TransferFailed();

		//update lowestTick
		lowestTick = currTick;
	}

	/// @dev Withdraws (fully) order specified by orderId
	/// @param orderId the orderId to withdraw
	function withdraw(uint256 orderId, address maker) external nonReentrant noDelegateCall onlyRouter {
		//TODO: withdraw order
		Order memory order = orderIdMapping[orderId];
		require(maker == order.maker);

		int24 tick = order.tick;
		Tick.Info storage tickInfo = ticks[tick];

		uint256 tokenXAmountWithdrawable;
		uint256 tokenYAmountWithdrawable;
		if (!tickInfo.initialized || tickInfo.lastInitializationTimestamp > order.creationTimestamp) {
			//tick has been executed
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount);
		} else if (tickInfo.multiplier != order.tickMultiplier) {
			//tick has been partially executed since order creation
			int128 netMultiplier;
			if (order.tickMultiplier != 0) {
				netMultiplier = ABDKMath64x64.div(int128(tickInfo.multiplier), int128(order.tickMultiplier));
			} else {
				netMultiplier = int128(tickInfo.multiplier);
			}
			tokenXAmountWithdrawable = ABDKMath64x64.mulu(netMultiplier, order.tokenXAmount);
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount - tokenXAmountWithdrawable);
		} else {
			//tick has not been executed since order creation
			tokenXAmountWithdrawable = order.tokenXAmount;
		}

		//token transfers and update tick and tickBitmap if necessary
		if (tokenXAmountWithdrawable > 0) {
			if (!IERC20Minimal(tokenX).transfer(maker, tokenXAmountWithdrawable)) revert TransferFailed();
			(bool flipped,) = ticks.update(tick, tokenXAmountWithdrawable, true);
			if (flipped) {
				tickBitmap.resetTick(tick);
			}
		}
		if (tokenYAmountWithdrawable > 0) {
			uint256 tokenYBalance = tokenBalance(tokenY);
			if (tokenYAmountWithdrawable > tokenYBalance) tokenYAmountWithdrawable = tokenYBalance; //naively handle tick.multiplier rounding error
			if (!IERC20Minimal(tokenY).transfer(maker, tokenYAmountWithdrawable)) revert TransferFailed();
		}

		//delete order
		delete orderIdMapping[orderId];
	}

	/// @dev Gets tokenX and tokenY amounts withdrawable for given orderId
	/// @param orderId the orderId
	function getWithdrawableTokenAmounts(uint256 orderId) external view returns (uint256 tokenXAmountWithdrawable, uint256 tokenYAmountWithdrawable) {
		//TODO: withdraw order
		Order memory order = orderIdMapping[orderId];

		int24 tick = order.tick;
		Tick.Info storage tickInfo = ticks[tick];

		if (!tickInfo.initialized || tickInfo.lastInitializationTimestamp > order.creationTimestamp) {
			//tick has been executed
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount);
		} else if (tickInfo.multiplier != order.tickMultiplier) {
			//tick has been partially executed
			int128 netMultiplier;
			if (order.tickMultiplier != 0) {
				netMultiplier = ABDKMath64x64.div(int128(tickInfo.multiplier), int128(order.tickMultiplier));
			} else {
				netMultiplier = int128(tickInfo.multiplier);
			}
			tokenXAmountWithdrawable = ABDKMath64x64.mulu(netMultiplier, order.tokenXAmount);
			tokenYAmountWithdrawable = TickMath.getOutputTokenYAmount(tick, tickMode, order.tokenXAmount - tokenXAmountWithdrawable);
		} else {
			//tick has not been executed
			tokenXAmountWithdrawable = order.tokenXAmount;
		}
	}

	///@dev Swaps fee tokenX and burn native token
	function swapFeeAndBurn() internal {
		//load fee amount
		uint256 feeAmount = feeTokenXAmountAccumulated;

		//execute swap
		if (tokenXPairedAddress != address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8)) {
			address[] memory path = new address[](4);
			path[0] = tokenX;
			path[1] = tokenXPairedAddress;
			path[2] = address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8); // native token is paired with DAI
			path[3] = address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F); // native token (TODO: change)

			// approves uniswap router to spend tokenX
			IERC20Minimal(tokenX).approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), feeAmount);

			IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				feeAmount,
				0, // accept any amount
				path,
				address(this),
				block.timestamp
			);
		} else {
			address[] memory path = new address[](3);
			path[0] = tokenX;
			path[1] = address(0x9c7de7DF49c102b133D17b40195947E0fb1784c8); // tokenX is paired with DAI
			path[2] = address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F); // native token (TODO: change)

			// approves uniswap router to spend tokenX
			IERC20Minimal(tokenX).approve(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), feeAmount);

			IUniswapV2Router02(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).swapExactTokensForTokensSupportingFeeOnTransferTokens(
				feeAmount,
				0, // accept any amount
				path,
				address(this),
				block.timestamp
			);
		}

		//burn native token
		IERC20Minimal(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)).transfer(address(0xdead), tokenBalance(address(0x6C54F2D5167d7b42d809c5A84D936C38c7c25d0F)));
	}

	/// @dev Sets protocol fee (only callable by router owner)
	function setProtocolFees(
		uint256 newProtocolFee,
		uint256 newSwapFeeTokenXAmountAt,
		address newTokenXPairedAddress
	) external onlyRouterOwner {
		protocolFee = newProtocolFee;
		swapFeeTokenXAmountAt = newSwapFeeTokenXAmountAt;
		tokenXPairedAddress = newTokenXPairedAddress;
	}

}