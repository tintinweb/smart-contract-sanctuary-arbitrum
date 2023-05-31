/**
 *Submitted for verification at Arbiscan on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Multicall {
    uint private am;

    struct Immutables {
        address t0;
        address t1;
        uint24 fee;
        address factory;
        bytes4 selector;
    }

    struct FlashRouteParams {
        uint amIn;
        uint amOut;
        address flashPool;
        bool direc;
        bytes[] callPath;
    }

    function uniswapV3FlashCallback(uint256 fee0,uint256 fee1,bytes calldata data) external {
        fee0 += am; fee1 += am;
        multicall(abi.decode(data, (bytes[])));
        if(fee0 > fee1){
            address token=IV3Pool(msg.sender).token0();
            IERC20(token).transfer(msg.sender,fee0);
            IERC20(token).transfer(tx.origin,am-fee0);
        }
        else{
            address token=IV3Pool(msg.sender).token1();
            IERC20(token).transfer(msg.sender,fee1);
            IERC20(token).transfer(tx.origin,am-fee1);
        }
    }

    function flashCallback(uint256 fee0,uint256 fee1,bytes calldata data) external {
        fee0 += am; fee1 += am;
        multicall(abi.decode(data, (bytes[])));
        if(fee0 > fee1){
            address token=IV3Pool(msg.sender).token0();
            IERC20(token).transfer(msg.sender,fee0);
            IERC20(token).transfer(tx.origin,am-fee0);
        }
        else{
            address token=IV3Pool(msg.sender).token1();
            IERC20(token).transfer(msg.sender,fee1);
            IERC20(token).transfer(tx.origin,am-fee1);
        }
    }

    function algebraFlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external{
        fee0 += am; fee1 += am;
        multicall(abi.decode(data, (bytes[])));
        if(fee0 > fee1){
            address token=IV3Pool(msg.sender).token0();
            IERC20(token).transfer(msg.sender,fee0);
            IERC20(token).transfer(tx.origin,am-fee0);
        }
        else{
            address token=IV3Pool(msg.sender).token1();
            IERC20(token).transfer(msg.sender,fee1);
            IERC20(token).transfer(tx.origin,am-fee1);
        }
    }

    function uniswapV3SwapCallback(int256 am0,int256 am1,bytes calldata) external {
        if (am0 > am1) {
            IERC20(IV3Pool(msg.sender).token0()).transfer(msg.sender,uint(am0));
            am = uint(-am1);
        } else {
            IERC20(IV3Pool(msg.sender).token1()).transfer(msg.sender,uint(am1));
            am = uint(-am0);
        }
    }

    function algebraSwapCallback(int256 am0,int256 am1,bytes calldata) external {
        if (am0 > am1) {
            IERC20(IV3Pool(msg.sender).token0()).transfer(msg.sender,uint(am0));
            am = uint(-am1);
        } else {
            IERC20(IV3Pool(msg.sender).token1()).transfer(msg.sender,uint(am1));
            am = uint(-am0);
        }
    }

    function swapCallback(int256 am0, int256 am1, bytes calldata) external {
        if (am0 > am1) {
            IERC20(IV3Pool(msg.sender).token0()).transfer(msg.sender,uint(am0));
            am = uint(-am1);
        } else {
            IERC20(IV3Pool(msg.sender).token1()).transfer(msg.sender,uint(am1));
            am = uint(-am0);
        }
    }

    function uniV2(address pool, bool direc) public {
        IERC20(direc ? IUniV2Pool(pool).token0() : IUniV2Pool(pool).token1()).transfer(pool, am);
        (uint112 reserve0, uint112 reserve1, ) = IUniV2Pool(pool).getReserves();
        am = (am * 997) / 1000;
        am = direc ? (am * reserve1) / (reserve0 + am) : (am * reserve0) / (reserve1 + am);
        IUniV2Pool(pool).swap(direc ? 0 : am,direc ? am : 0,address(this),"");
    }

    function algebraV3(address pool, bool direc) public {
        IUniV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function uniV3(address pool, bool direc) public {
        IUniV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function kyberV3(address pool, bool direc) public {
        IKyberV3Pool(pool).swap(address(this),int(am),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function flashRoute(FlashRouteParams calldata _route) public returns(uint amOut){
        am = _route.amIn;
        IV3Pool(_route.flashPool).flash(address(this),_route.direc ? am : 0,_route.direc ? 0 : am,abi.encode(_route.callPath));
        amOut=am;
        delete am;
    }

    function multicall(bytes[] memory callPath) public {
        for (uint8 i = 0; i < callPath.length; i++) {
            (bool success, ) = address(this).call(callPath[i]);
            require(success, "err");
        }
    }

    function uniV3Immutables(address pool)public view returns (Immutables memory){
        return Immutables(IPool(pool).token0(),IPool(pool).token1(),IUniV3Pool(pool).fee(),factory(pool),bytes4(keccak256("uniV3(address,bool)")));
    }

    function kyberV3Immutables(address pool)public view returns (Immutables memory){
        return Immutables(IPool(pool).token0(),IPool(pool).token1(),IKyberV3Pool(pool).swapFeeUnits() * 10,factory(pool),bytes4(keccak256("kyberV3(address,bool)")));
    }

    function uniV2Immutables(address pool)public view returns(Immutables memory){
        return Immutables(IPool(pool).token0(),IPool(pool).token1(),3000,factory(pool),bytes4(keccak256("uniV2(address,bool)")));
    }

    function algebraV3Immutables(address pool)public view returns (Immutables memory){
        (,,uint16 fee,,,,)=IAlgebraV3Pool(pool).globalState();
        return Immutables(IPool(pool).token0(),IPool(pool).token1(),fee,factory(pool),bytes4(keccak256("algebraV3(address,bool)")));
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
}

interface IAlgebraV3Pool is IV3Pool {
    function globalState() external view returns (uint160 price, int24 tick, uint16 feeZtO, uint16 feeOtZ, uint16 timepointIndex, uint8 communityFee, bool unlocked);
}

interface IKyberV3Pool is IV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function swapFeeUnits() external view returns (uint24);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}