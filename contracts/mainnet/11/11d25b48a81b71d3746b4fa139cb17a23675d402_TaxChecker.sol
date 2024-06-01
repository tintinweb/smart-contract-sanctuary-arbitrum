/**
 *Submitted for verification at Arbiscan.io on 2024-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint256, uint256);
    function token0() external view returns (address);
}

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function WETH() external pure returns (address);
}

contract TaxChecker {
    address public owner;

    event EthIn(address from, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function getReserves(address pairAddr) public view returns (uint256, uint256, address) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        (uint256 res0, uint256 res1) = pair.getReserves();
        address token0 = pair.token0();
        return (res0, res1, token0);
    }

    function getBalance(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.balanceOf(address(this));
    }

    function getDecimals(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.decimals();
    }

    function buy(address routerAddr, address tokenAddr) internal returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddr;
        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 60);
        return amounts[1];
    }

    function sell(address routerAddr, address tokenAddr, uint256 amount) internal returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        ERC20 token = ERC20(tokenAddr);
        token.approve(routerAddr, amount);
        address[] memory path = new address[](2);
        path[0] = tokenAddr;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
        return address(this).balance;
    }

    function getExpectedTokens(address routerAddr, address pairAddr, address tokenAddr, uint256 value) public view returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        (uint256 res0, uint256 res1, address token0) = getReserves(pairAddr);
        uint256 resToken;
        uint256 resWeth;
        if (token0 == tokenAddr) {
            resToken = res0;
            resWeth = res1;
        } else {
            resToken = res1;
            resWeth = res0;
        }
        return router.getAmountOut(value, resWeth, resToken);
    }

    function getExpectedEth(address routerAddr, address pairAddr, address tokenAddr, uint256 value) public view returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        (uint256 res0, uint256 res1, address token0) = getReserves(pairAddr);
        uint256 resToken;
        uint256 resWeth;
        if (token0 == tokenAddr) {
            resToken = res0;
            resWeth = res1;
        } else {
            resToken = res1;
            resWeth = res0;
        }
        return router.getAmountOut(value, resToken, resWeth);
    }

    function getTokenTax(address routerAddr, address pairAddr, address tokenAddr) public payable returns (uint256[4] memory, int256[2] memory) {
        uint256 expectedTokens = getExpectedTokens(routerAddr, pairAddr, tokenAddr, msg.value);
        uint256 tokenBalanceBuy = buy(routerAddr, tokenAddr);
        int256 buyTax = (10**11) - ((int256(tokenBalanceBuy) * (10**11)) / int256(expectedTokens));

        uint256 expectedEth = getExpectedEth(routerAddr, pairAddr, tokenAddr, tokenBalanceBuy);
        uint256 ethBalance = sell(routerAddr, tokenAddr, tokenBalanceBuy);
        int256 sellTax = (10**11) - ((int256(ethBalance) * (10**11)) / int256(expectedEth));
        payable(owner).transfer(ethBalance);
        return ([tokenBalanceBuy, expectedTokens, ethBalance, expectedEth], [buyTax, sellTax]);
    }
    
    receive() external payable {
        emit EthIn(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit EthIn(msg.sender, msg.value);
    }
}