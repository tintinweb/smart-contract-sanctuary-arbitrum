// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

library SwapRouterLib {
    uint256 private constant BASE = 10**18;

    /**
     * @notice Generate abi.encodePacked path for UniswapV3/PcsV3 multihop swap
     * @param tokens list of tokens
     * @param fees list of pool fees
     */
    function generateEncodedPathWithFee(
        address[] memory tokens,
        uint24[] memory fees
    ) public pure returns (bytes memory) {
        require(tokens.length == fees.length + 1, "SG3");

        bytes memory path = new bytes(0);

        for (uint256 i = 0; i < fees.length; i++) {
            path = abi.encodePacked(path, tokens[i], fees[i]);
        }

        path = abi.encodePacked(path, tokens[tokens.length - 1]);

        return path;
    }

    /**
     * @notice Generate abi.encodePacked path for QuickswapV3 multihop swap
     * @param tokens list of tokens
     */
    function generateEncodedPath(address[] memory tokens)
        public
        pure
        returns (bytes memory)
    {
        bytes memory path = new bytes(0);

        for (uint256 i = 0; i < tokens.length; i++) {
            path = abi.encodePacked(path, tokens[i]);
        }

        return path;
    }

    /**
     * @notice Calculate UniswapV3 price quote
     * @param tokenIn Address of token input
     * @param baseToken Base token of pool
     * @param price slot0 of pool
     * @return amountOut calculated result
     */
    function calcUniswapV3Quote(
        address tokenIn,
        address baseToken,
        uint160 price
    ) public pure returns (uint256 amountOut) {
        if (tokenIn == baseToken) {
            if (price > 10**29) {
                amountOut = ((price * 10**9) / 2**96)**2;
            } else {
                amountOut = (uint256(price)**2 * BASE) / (2**192);
            }
        } else {
            if (price > 10**35) {
                amountOut = ((2**96 * 10**9) / (price))**2;
            } else {
                amountOut = (2**192 * BASE) / (uint256(price)**2);
            }
        }
    }
}