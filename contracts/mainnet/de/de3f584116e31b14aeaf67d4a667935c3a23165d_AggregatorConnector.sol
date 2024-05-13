// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ILiquidityConnector.sol";

struct AggregatorExtraData {
    bytes data;
}

contract AggregatorConnector is ILiquidityConnector {
    error AggregatorSwapFailed(bytes error);
    error NotImplemented();

    address public immutable router;

    constructor(address router_) {
        router = router_;
    }

    function addLiquidity(AddLiquidityData memory) external payable override {
        revert NotImplemented();
    }

    function removeLiquidity(RemoveLiquidityData memory)
        external
        pure
        override
    {
        revert NotImplemented();
    }

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable
        override
    {
        AggregatorExtraData memory extraData =
            abi.decode(swapData.extraData, (AggregatorExtraData));
        (bool success, bytes memory error) = router.call(extraData.data);
        if (!success) {
            revert AggregatorSwapFailed(error);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
}