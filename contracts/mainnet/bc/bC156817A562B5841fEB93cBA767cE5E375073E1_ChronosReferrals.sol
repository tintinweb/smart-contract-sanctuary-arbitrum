/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

interface IChronosPair {
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
	function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
}

interface IChronosFactory {
	function isPair(address pair) external view returns (bool);
}

contract ChronosReferrals {

	/// @dev Chronos factory for checking if pair being used is a Chronos pair
	IChronosFactory constant CHRONOS_FACTORY =
		IChronosFactory(0xCe9240869391928253Ed9cc9Bcb8cb98CB5B0722);

	/// @dev Swap event logging for referral tracking
	event Swap(
		address indexed user, 
		uint256 amountIn,
		uint256 amountOut,
		address pair
	);

	/// @notice Performs a swap on a Chronos pair and emits an event for referrals
	/// @notice Assumes that the input amount has already been sent to the pair
	/// @param amountIn the input amount of the swap
	/// @param pair the address of the Chronos pair being used in the swap
	/// @param inputToken input token of the swap
	/// @param recipient the recipient of the swap (may be another contract)
	/// @param zeroForOne if token 0 is the input token
	function chronosSwap(
		uint256 amountIn, 
		address pair, 
		address inputToken,
		address recipient,
		bool zeroForOne
	) 
		external returns (uint256 amountOut)
	{
		require(CHRONOS_FACTORY.isPair(pair), "Not Chronos Pair");

      	amountOut = IChronosPair(pair).getAmountOut(amountIn, inputToken);

	    IChronosPair(pair).swap(
	      zeroForOne ? 0 : amountOut,
	      zeroForOne ? amountOut : 0,
	      recipient,
	      ""
	    );

	    emit Swap(
	    	tx.origin,
	    	amountIn,
	    	amountOut,
	    	pair
	    );
	}
}