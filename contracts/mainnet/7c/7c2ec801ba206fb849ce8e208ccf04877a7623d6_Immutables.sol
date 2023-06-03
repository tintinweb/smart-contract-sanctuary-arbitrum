/**
 *Submitted for verification at Arbiscan on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Immutables {

    struct V3Pool {
        address t0;
        address t1;
        uint24 fee;
        address factory;
        int24 tickSpacing;
        bytes4 selector;
    }

    struct V2Pool {
        address t0;
        address t1;
        uint24 fee;
        address factory;
        bytes4 selector;
    }

    function uniV3(address pool)public view returns (V3Pool memory){
        return V3Pool(IPool(pool).token0(),IPool(pool).token1(),IUniV3Pool(pool).fee(),factory(pool),IUniV3Pool(pool).tickSpacing(),bytes4(keccak256("uniV3(address,bool)")));
    }

    function kyberV3(address pool)public view returns (V3Pool memory){
        return V3Pool(IPool(pool).token0(),IPool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits() * 10,factory(pool),IKyberV3Pool(pool).tickDistance(),bytes4(keccak256("kyberV3(address,bool)")));
    }

    function uniV2(address pool)public view returns(V2Pool memory){
        return V2Pool(IPool(pool).token0(),IPool(pool).token1(),3000,factory(pool),bytes4(keccak256("uniV2(address,bool)")));
    }

    function algebraV3(address pool)public view returns (V3Pool memory){
        return V3Pool(IPool(pool).token0(),IPool(pool).token1(),1000000,factory(pool),IAlgebraV3Pool(pool).tickSpacing(),bytes4(keccak256("algebraV3(address,bool)")));
    }

    function factory(address pool)public view returns (address){
        return IPool(pool).factory();
    }
}

interface IPool {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IV3Pool is IPool {
    function flash(address recipient,uint256 amount0,uint256 amount1,bytes calldata data) external;
}

interface IUniV2Pool is IPool {
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function getReserves()external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniV3Pool is IV3Pool {
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
}

interface IAlgebraV3Pool is IV3Pool {
    function tickSpacing() external view returns (int24);
}

interface IKyberV3Pool is IV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function swapFeeUnits() external view returns (uint24);
    function tickDistance() external view returns (int24);
}