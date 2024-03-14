// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWETH {
    function approve(address guy, uint256 wad) external returns (bool);
    function withdraw(uint) external;
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
interface IERC20 {
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IExternalRouter {
    struct SwapParameters {
        address pair;
        address input;
        uint48 fee;
        uint160 sqrtPriceLimitX96;
        uint256 minOutput;
        int8 swapType;
    }

    function swapWithFees(
        uint256 inputAmount,
        SwapParameters[] memory swaps,
        address to,
        uint256 deadline,
        address f
    ) external ;
}

contract BaseSwapper {
    address public WETH;
    address public externalRouter;

    constructor(address weth, address _externalRouter) {
        WETH = weth;
        externalRouter = _externalRouter;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function baseSwapper(
        uint256 amountIn,
        bytes calldata swapCalls,
        address to,
        uint256 deadline,
        address factory,
        bool unwrap
    ) external payable {
        uint256 v = msg.value;
        IExternalRouter.SwapParameters[] memory calls = abi.decode(
            swapCalls,
            (IExternalRouter.SwapParameters[])
        );
        IWETH weth = IWETH(WETH);
        if (v > 0) {
            if (v > amountIn) payable(msg.sender).transfer(v - amountIn);
            weth.deposit{value: amountIn}();
            weth.approve(externalRouter, weth.balanceOf(address(this)));
        } else {
            IERC20 input = IERC20(calls[0].input);
            input.transferFrom(msg.sender, address(this), amountIn);
            input.approve(externalRouter, input.balanceOf(address(this)));
        }
        IExternalRouter(externalRouter).swapWithFees(
            amountIn,
            calls,
            unwrap ? address(this) : to,
            deadline,
            factory
        );
        if (unwrap) {
            weth.withdraw(weth.balanceOf(address(this)));
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}