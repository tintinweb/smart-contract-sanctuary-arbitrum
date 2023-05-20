/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


interface ISwapPair {

    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
}

interface IERC20 {
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface ISwapFactory {
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);

}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract LiquidityHelperARBV2 {

    address public immutable factory;
    address public immutable weth;
    constructor(address factory_, address weth_){
        factory = factory_;
        weth = weth_;
    }

    function addWithSyncToken(address tokenA, address tokenB, uint256 priceA, uint256 priceB, uint256 liqA, uint256 liqB) external {
        syncPrice(tokenA, tokenB, priceA, priceB);
        addLiquidity(tokenA, tokenB, liqA, liqB);
    }

    function addWithSyncEth(address tokenA, uint256 priceA, uint256 priceB, uint256 liqA, uint256 liqB) payable external {
        require(msg.value >= (priceB + liqB), "ethNotEnough");
        IWETH(weth).deposit{value: msg.value}();
        syncPriceThis(tokenA, priceA, priceB);

        addLiquidity(tokenA, weth, liqA, liqB);
        uint256 left = IERC20(weth).balanceOf(address(this));
        if(left >0) {
            IWETH(weth).withdraw(left);
            TransferHelper.safeTransferETH(msg.sender, left);
        }

    }

    function syncPrice(address tokenA, address tokenB, uint256 amountA, uint256 amountB) public {
        // create the pair if it doesn't exist yet
        if (ISwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISwapFactory(factory).createPair(tokenA, tokenB);
        }
        address pair = pairFor(tokenA, tokenB);

        uint256 balA = IERC20(tokenA).balanceOf(pair);
        uint256 balB = IERC20(tokenB).balanceOf(pair);
        require(amountA >= balA, "notLessBalA");
        require(amountB >= balB, "notLessBalB");
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA-balA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB-balB);
        // first sync price
        ISwapPair(pair).sync();
    }

    function syncPriceEth(address tokenA, uint256 amountA) payable public {
        // create the pair if it doesn't exist yet
        if (ISwapFactory(factory).getPair(tokenA, weth) == address(0)) {
            ISwapFactory(factory).createPair(tokenA, weth);
        }
        address pair = pairFor(tokenA, weth);
        uint256 balA = IERC20(tokenA).balanceOf(pair);
        uint256 balB = IERC20(weth).balanceOf(pair);
        require(amountA >= balA, "notLessBalA");
        require(msg.value >= balB, "notLessBalB");
        uint256 amountETH = msg.value - balB;
        
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA - balA);
        IWETH(weth).deposit{value: amountETH}();
        IWETH(weth).transfer(pair, amountETH);
        // first sync price
        ISwapPair(pair).sync();
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function syncPriceThis(address tokenA, uint256 amountA, uint256 amountB) internal {
        // create the pair if it doesn't exist yet
        if (ISwapFactory(factory).getPair(tokenA, weth) == address(0)) {
            ISwapFactory(factory).createPair(tokenA, weth);
        }
        address pair = pairFor(tokenA, weth);

        uint256 balA = IERC20(tokenA).balanceOf(pair);
        uint256 balB = IERC20(weth).balanceOf(pair);
        require(amountA >= balA, "notLessBalA");
        require(amountB >= balB, "notLessBalB");
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA - balA);
        IERC20(weth).transfer(pair, amountB - balB);
        // first sync price
        ISwapPair(pair).sync();
    }



    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    ) public returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pair = pairFor(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISwapPair(pair).mint(msg.sender);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

        // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SwapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SwapLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SwapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SwapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                ISwapFactory(factory).pairCodeHash() // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISwapPair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SwapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'SwapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SwapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
}