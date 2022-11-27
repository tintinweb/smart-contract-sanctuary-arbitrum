// File: contrax.sol

/*

 ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗ ██╗  ██╗
██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗╚██╗██╔╝
██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║ ╚███╔╝ 
██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║ ██╔██╗ 
╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║██╔╝ ██╗
 ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
                                                            
*/

/// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20Uniswap {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract Contrax {
    IUniswapV2Router01 public router;
    IUniswapV2Factory public factory;

    constructor(address _factory, address _router) {
        router = IUniswapV2Router01(_router);
        factory = IUniswapV2Factory(_factory);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function createLp(
        address _tokena,
        address _tokenb,
        uint256 amounta,
        uint256 amountb,
        uint256 amountamin,
        uint256 amountbmin
    ) public {
        IERC20Uniswap(_tokena).transferFrom(msg.sender, address(this), amounta);
        IERC20Uniswap(_tokenb).transferFrom(msg.sender, address(this), amountb);
        IERC20Uniswap(_tokena).approve(address(router), amounta);
        IERC20Uniswap(_tokenb).approve(address(router), amountb);
        address a = factory.getPair(_tokena, _tokenb);
        if (a == address(0)) {
            factory.createPair(_tokena, _tokenb);
            router.addLiquidity(
                _tokena,
                _tokenb,
                amounta,
                amountb,
                amountamin,
                amountbmin,
                msg.sender,
                block.timestamp + 1 minutes
            );
        } else {
            router.addLiquidity(
                _tokena,
                _tokenb,
                amounta,
                amountb,
                amountamin,
                amountbmin,
                msg.sender,
                block.timestamp + 1 minutes
            );
        }
    }
}