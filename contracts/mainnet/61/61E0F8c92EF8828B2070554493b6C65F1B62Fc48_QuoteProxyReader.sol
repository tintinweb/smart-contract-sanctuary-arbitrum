// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IQuoterV2 {
	struct QuoteOutput {
		uint256 usedAmount;
		uint256 returnedAmount;
		uint160 afterSqrtP;
		uint32 initializedTicksCrossed;
		uint256 gasEstimate;
	}

	function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
		external
		returns (QuoteOutput memory);

  struct QuoteExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint24 feeUnits;
    uint160 limitSqrtP;
	}
}

contract QuoteProxyReader {
    function quote(
        address quoteContract,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint24 feeUnits,
        uint160 limitSqrtP
    ) public returns (uint256) {
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams({
						tokenIn: tokenIn,
						tokenOut: tokenOut,
						amountIn: amountIn,
						feeUnits: feeUnits,
						limitSqrtP: limitSqrtP
				});

        IQuoterV2.QuoteOutput memory output = IQuoterV2(quoteContract).quoteExactInputSingle(params);
				require(output.usedAmount == amountIn, "usedAmount not equals to amountIn");

				return output.returnedAmount;
    }
}