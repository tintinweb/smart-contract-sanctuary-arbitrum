/**
 *Submitted for verification at Arbiscan on 2023-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Multicall {
    uint private am;
    address private v3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    struct RouteParams {
        uint amIn;
        uint amOut;
        address tIn;
        address tOut;
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

    function uniV3(address pool, bool direc) public {
        IUniV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function algebraV3(address pool, bool direc) public {
        IAlgebraV3Pool(pool).swap(address(this),direc,int(am),direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function kyberV3(address pool, bool direc) public {
        IKyberV3Pool(pool).swap(address(this),int(am),direc,direc ? 4295128740 : 1461446703485210103287273052203988822378723970341,"");
    }

    function flashRoute(RouteParams calldata route,address flashPool) public returns(uint amOut){
        am = route.amIn;
        bool tIn_t0=IV3Pool(flashPool).token0()==route.tIn;
        IV3Pool(flashPool).flash(address(this),tIn_t0 ? am : 0,tIn_t0 ? 0 : am,abi.encode(route.callPath));
        amOut=am;
        delete am;
    }

    function fundsRoute(RouteParams calldata route)public returns(uint amOut){
        IERC20(route.tIn).transferFrom(msg.sender, address(this), route.amIn);
        am = route.amIn;
        multicall(route.callPath);
        require(am>=amOut,"amOut");
        IERC20(route.tIn).transfer(msg.sender, am);
        amOut=am;
        delete am;
    }

    function multicall(bytes[] memory callPath) public {
        for (uint8 i = 0; i < callPath.length; i++) {
            (bool success, ) = address(this).call(callPath[i]);
            require(success, "err");
        }
    }

    function getPools(address tokenA,address tokenB) public view returns (address[] memory pools){
        uint16[4] memory fees=[100,500,3000,10000];
        for (uint8 i=0 ; i<fees.length ; i++) {
            address pool = IV3Factory(v3Factory).getPool(tokenA, tokenB, fees[i]);
            if (pool != address(0))
                pools=addAddress(pools,pool);
        }
    }

    function poolQuote(address pool, bool direc, uint256 amIn) public view returns (uint256 amOut) {
        uint256 poolIn = amIn - (amIn * IUniV3Pool(pool).fee()) / 1e6;
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = IUniV3Pool(pool).slot0();
        int24 spacing = IUniV3Pool(pool).tickSpacing();
        int24 tickL = (tick / spacing) * spacing;
        int24 tickU = tickL + spacing;
        uint128 liquidity = IUniV3Pool(pool).liquidity();
        uint256 token0VirtualReserves = liquidity / (sqrtPriceX96 * sqrtPriceX96);
        uint256 token1VirtualReserves = liquidity * (sqrtPriceX96 * sqrtPriceX96);
        uint256 token1RealReserves = (liquidity * ((10001 ** uint256(int256(tickL))) / 10000)) - token1VirtualReserves;
        uint256 token0RealReserves = (liquidity / ((10001 ** uint256(int256(tickU))) / 10000)) - token0VirtualReserves;
        amOut = (poolIn * (direc ? token1VirtualReserves : token0VirtualReserves)) / ((direc ? token0VirtualReserves : token1VirtualReserves) + poolIn);
        if ((direc ? token1RealReserves : token0RealReserves) < amOut)
            amOut = (direc ? token1RealReserves : token0RealReserves);
    }

    function addAddress(address[] memory myArray, address newItem) private pure returns (address[] memory newArray) {
        newArray = new address[](myArray.length + 1);
        for (uint i = 0; i < myArray.length; i++) 
            newArray[i] = myArray[i];
        newArray[myArray.length - 1] = newItem;
    }

    function addCall(bytes[] memory myArray, bytes memory newItem) private pure returns (bytes[] memory newArray) {
        newArray = new bytes[](myArray.length + 1);
        for (uint i = 0; i < myArray.length; i++)
            newArray[i] = myArray[i];
        newArray[myArray.length - 1] = newItem;
    }

    function poolCall(address pool,bool direc) private pure returns (bytes memory){
        return abi.encodeWithSignature("uniV3(address,bool)", pool,direc);
    }

    function getRoute(RouteParams memory route,uint8 d,address[] calldata tokens) public view returns (RouteParams memory) {
        route.amOut = route.amIn * ((route.tIn == route.tOut) ? 1 : 0);
        while (d-- > 0) {
            for (uint256 i = 0; i < tokens.length; i++) {
                RouteParams memory rCon = getRoute(RouteParams(route.amIn,route.amOut,route.tIn,tokens[i],route.callPath), d , tokens);
                if(rCon.amOut > 0){
                    address[] memory poolsConOut=getPools(rCon.tOut,route.tOut);
                    for (uint256 j = 0; j < poolsConOut.length; j++) {
                        uint256 amOut = poolQuote(poolsConOut[j], rCon.tOut<route.tOut, rCon.amOut);
                        if (amOut > route.amOut) {
                            route.amOut = amOut;
                            route.callPath=addCall(rCon.callPath,poolCall(poolsConOut[j],rCon.tOut<route.tOut));
                        }
                    }
                }
            }
        }
        return route;
    }
}

interface IV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IPool {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IV3Pool is IPool {
    function flash(address recipient,uint256 amount0,uint256 amount1,bytes calldata data) external;
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
    function tickSpacing(
  ) external view returns (int24);
  function liquidity(
  ) external view returns (uint128);
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
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
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