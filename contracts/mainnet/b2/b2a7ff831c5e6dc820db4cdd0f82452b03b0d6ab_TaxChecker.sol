/**
 *Submitted for verification at Arbiscan.io on 2024-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                    ███████╗██████╗  ██████╗██████╗  ██████╗                         
                    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔═████╗                        
                    █████╗  ██████╔╝██║      █████╔╝██║██╔██║                        
                    ██╔══╝  ██╔══██╗██║     ██╔═══╝ ████╔╝██║                        
                    ███████╗██║  ██║╚██████╗███████╗╚██████╔╝                        
                    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝                         
                                                                                     
████████╗ █████╗ ██╗  ██╗     ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗ 
╚══██╔══╝██╔══██╗╚██╗██╔╝    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
   ██║   ███████║ ╚███╔╝     ██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
   ██║   ██╔══██║ ██╔██╗     ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
   ██║   ██║  ██║██╔╝ ██╗    ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                                     
                                                        ██╗   ██╗██████╗     ██████╗ 
                                                        ██║   ██║╚════██╗   ██╔═████╗
                                                        ██║   ██║ █████╔╝   ██║██╔██║
                                                        ╚██╗ ██╔╝██╔═══╝    ████╔╝██║
                                                         ╚████╔╝ ███████╗██╗╚██████╔╝
                                                          ╚═══╝  ╚══════╝╚═╝ ╚═════╝ 
                                                                                     
                                                          JRCRYPTODEV
                                                          t.me/jrcryptodev
*/


interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint256, uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
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

    function getReserves(address pairAddr) public view returns (uint256, uint256, address, address) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        (uint256 res0, uint256 res1) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();
        return (res0, res1, token0, token1);
    }

    function getBalance(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.balanceOf(address(this));
    }

    function getDecimals(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.decimals();
    }

    function buy(address routerAddr, address pairAddr, address tokenAddr) internal returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        address[] memory path;
        address WETH = router.WETH();
        (, , address token0, address token1) = getReserves(pairAddr);

        if (token0 == WETH || token1 == WETH) {
            // Path is ETH -> Token
            path = new address[](2);
            path[0] = WETH;
            path[1] = tokenAddr;
        } else {
            // Path is ETH -> WETH -> Token
            path = new address[](3);
            path[0] = WETH;
            path[1] = token0 == WETH ? token1 : token0;
            path[2] = tokenAddr;
        }

        uint256[] memory amounts = router.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 60);
        return amounts[amounts.length - 1];
    }

    function sell(address routerAddr, address pairAddr, address tokenAddr, uint256 amount) internal returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        ERC20 token = ERC20(tokenAddr);
        token.approve(routerAddr, amount);
        address[] memory path;
        address WETH = router.WETH();
        (, , address token0, address token1) = getReserves(pairAddr);

        if (token0 == WETH || token1 == WETH) {
            // Path is Token -> ETH
            path = new address[](2);
            path[0] = tokenAddr;
            path[1] = WETH;
        } else {
            // Path is Token -> WETH -> ETH
            path = new address[](3);
            path[0] = tokenAddr;
            path[1] = token0 == WETH ? token1 : token0;
            path[2] = WETH;
        }

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 60);
        return address(this).balance;
    }

    function getExpectedTokens(address routerAddr, address pairAddr, address tokenAddr, uint256 value) public view returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        (uint256 res0, uint256 res1, address token0, ) = getReserves(pairAddr);
        uint256 resToken;
        uint256 resWeth = 0;
        address WETH = router.WETH();

        if (token0 == tokenAddr) {
            resToken = res0;
        } else {
            resToken = res1;
        }

        if (token0 == WETH) {
            resWeth = res0;
        } else if (resWeth == 0) {
            resWeth = res1;
        }

        if (resWeth == 0) {
            // If no direct WETH pair, get intermediate reserves
            uint256 resIntermediary;
            (, resIntermediary, , ) = getReserves(pairAddr);
            return router.getAmountOut(value, resIntermediary, resToken);
        }

        return router.getAmountOut(value, resWeth, resToken);
    }

    function getExpectedEth(address routerAddr, address pairAddr, address tokenAddr, uint256 value) public view returns (uint256) {
        IUniswapV2Router router = IUniswapV2Router(routerAddr);
        (uint256 res0, uint256 res1, address token0, ) = getReserves(pairAddr);
        uint256 resToken;
        uint256 resWeth = 0;
        address WETH = router.WETH();

        if (token0 == tokenAddr) {
            resToken = res0;
        } else {
            resToken = res1;
        }

        if (token0 == WETH) {
            resWeth = res0;
        } else if (resWeth == 0) {
            resWeth = res1;
        }

        if (resWeth == 0) {
            // If no direct WETH pair, get intermediate reserves
            uint256 resIntermediary;
            (, resIntermediary, , ) = getReserves(pairAddr);
            return router.getAmountOut(value, resToken, resIntermediary);
        }

        return router.getAmountOut(value, resToken, resWeth);
    }

    function getTokenTax(address routerAddr, address pairAddr, address tokenAddr) public payable returns (uint256, uint256, uint256, uint256, int256, int256) {
        uint256 expectedTokens = getExpectedTokens(routerAddr, pairAddr, tokenAddr, msg.value);
        uint256 tokenBalanceBuy = buy(routerAddr, pairAddr, tokenAddr);
        int256 buyTax = (10**11) - ((int256(tokenBalanceBuy) * (10**11)) / int256(expectedTokens));

        uint256 expectedEth = getExpectedEth(routerAddr, pairAddr, tokenAddr, tokenBalanceBuy);
        uint256 ethBalance = sell(routerAddr, pairAddr, tokenAddr, tokenBalanceBuy);
        int256 sellTax = (10**11) - ((int256(ethBalance) * (10**11)) / int256(expectedEth));
        payable(owner).transfer(ethBalance);
        return (tokenBalanceBuy, expectedTokens, ethBalance, expectedEth, buyTax, sellTax);
    }
    
    receive() external payable {
        emit EthIn(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit EthIn(msg.sender, msg.value);
    }
}