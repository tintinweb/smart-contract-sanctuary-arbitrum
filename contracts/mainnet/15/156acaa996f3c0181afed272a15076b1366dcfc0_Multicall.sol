/**
 *Submitted for verification at Arbiscan on 2023-06-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Multicall {
    uint private am;
    address[] private uniV2Factories;
    address[] private uniV3Factories = 
    [
        0x1F98431c8aD98523631AE4a59f267346ea31F984
    ];
    address[] private kyberV3Factories =
    [
        0xC7a590291e07B9fe9E64b86c58fD8fC764308C4A
    ];
    uint16[] private uniV3Fees=[100,500,3000,10000];
    uint16[] private kyberV3Fees=[8,40,1000];

    struct RouteParams {
        address tIn;
        address tOut;
        uint amIn;
        uint amOut;
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
        require(am>=route.amOut,"amOut");
        IERC20(route.tOut).transfer(msg.sender, am);
        amOut=am;
        delete am;
    }

    function multicall(bytes[] memory callPath) public {
        for (uint8 i = 0; i < callPath.length; i++) {
            (bool success, ) = address(this).call(callPath[i]);
            require(success, "err");
        }
    }

    function addAddress(address[] memory myArray, address newItem) private pure returns (address[] memory newArray) {
        newArray = new address[](myArray.length + 1);
        for (uint8 i = 0; i < myArray.length; i++) 
            newArray[i] = myArray[i];
        newArray[myArray.length] = newItem;
    }

    function addCall(bytes[] memory myArray, bytes memory newItem) private pure returns (bytes[] memory newArray) {
        newArray = new bytes[](myArray.length + 1);
        for (uint8 i = 0; i < myArray.length; i++)
            newArray[i] = myArray[i];
        newArray[myArray.length] = newItem;
    }

    function poolCall(address pool,bool direc) public pure returns (bytes memory){
        return abi.encodeWithSignature("uniV3(address,bool)", pool,direc);
    }

    function kyberV3PoolQuote(address pool, bool direc, uint256 amIn) public view returns (uint256 amOut) {
        (uint160 sqrtPriceX96, , , ) = IKyberV3Pool(pool).getPoolState();
        (uint128 liquidity,,) = IKyberV3Pool(pool).getLiquidityState();
        uint256 token0VirtualReserves = uint(liquidity)*uint(2**96) / uint(sqrtPriceX96);
        uint256 token1VirtualReserves = (uint(liquidity)*uint(sqrtPriceX96)) / uint(2**96);
        amIn = amIn - (amIn * 500) / 1e6;
        amOut = (amIn * (direc ? token1VirtualReserves : token0VirtualReserves)) / ((direc ? token0VirtualReserves : token1VirtualReserves) + amIn);
    }

    function uniV3PoolQuote(address pool, bool direc, uint256 amIn) public view returns (uint256 amOut) {
        (uint160 sqrtPriceX96, , , , , , ) = IUniV3Pool(pool).slot0();
        uint128 liquidity = IUniV3Pool(pool).liquidity();
        uint256 token0VirtualReserves = uint(liquidity)*uint(2**96) / uint(sqrtPriceX96);
        uint256 token1VirtualReserves = (uint(liquidity)*uint(sqrtPriceX96)) / uint(2**96);
        amIn = amIn - (amIn * 500) / 1e6;
        amOut = (amIn * (direc ? token1VirtualReserves : token0VirtualReserves)) / ((direc ? token0VirtualReserves : token1VirtualReserves) + amIn);
    } 

    function uniV2PoolQuote(address pool, bool direc, uint256 amIn) public view returns (uint256 amOut) {
       (uint112 reserve0, uint112 reserve1, ) = IUniV2Pool(pool).getReserves();
        amIn = (amIn * 997) / 1000;
        amOut = direc ? (amIn * reserve1) / (reserve0 + amIn) : (amIn * reserve0) / (reserve1 + amIn);
    }

    function getUniV3Pools(address tokenA,address tokenB) public view returns (address[] memory pools){
        for (uint8 f=0 ; f<uniV3Factories.length ; f++) {
            for (uint8 i=0 ; i<uniV3Fees.length ; i++) {
                address pool=IV3Factory(uniV3Factories[f]).getPool(tokenA, tokenB, uniV3Fees[i]);
                if(pool!=address(0)) pools = addAddress(pools,pool);
            }
        }
    }

    function getKyberV3Pools(address tokenA,address tokenB) public view returns (address[] memory pools){
        for (uint8 f=0 ; f<kyberV3Factories.length ; f++) {
            for (uint8 i=0 ; i<kyberV3Fees.length ; i++) {
                address pool=IV3Factory(kyberV3Factories[f]).getPool(tokenA, tokenB, kyberV3Fees[i]);
                if(pool!=address(0)) pools = addAddress(pools,pool);
            }
        }
    }

    function getUniV2Pools(address tokenA,address tokenB) public view returns (address[] memory pools){
        for (uint8 f=0 ; f<uniV2Factories.length ; f++) {
            address pool=IV2Factory(uniV2Factories[f]).getPair(tokenA, tokenB);
            if(pool!=address(0)) pools = addAddress(pools,pool);
        }
    }

    function findPool(address tIn, address tOut,uint amIn) public view returns (uint amOut, bytes memory call) {
        bool direc=tIn < tOut;
        //uniswapV3
        address[] memory pools = getUniV3Pools(tIn,tOut);
        for (uint8 p = 0; p < pools.length; p++) {
            uint _amOut = uniV3PoolQuote(pools[p], direc, amIn);
            if (_amOut > amOut)
                (amOut,call) = (_amOut,abi.encodeWithSignature("uniV3(address,bool)", pools[p],direc));
        }
        //kyberswapV3
        pools = getKyberV3Pools(tIn, tOut);
        for (uint8 p = 0; p < pools.length; p++) {
            uint _amOut = kyberV3PoolQuote(pools[p], direc, amIn);
            if (_amOut > amOut) 
                (amOut,call) = (_amOut,abi.encodeWithSignature("kyberV3(address,bool)", pools[p],direc));
        }
        //uniswapV2
        pools = getUniV2Pools(tIn, tOut);
        for (uint8 p = 0; p < pools.length; p++) {
            uint _amOut = uniV2PoolQuote(pools[p], direc, amIn);
            if (_amOut > amOut) 
                (amOut,call) = (_amOut,abi.encodeWithSignature("uniV2(address,bool)", pools[p],direc));
        }
    }

    function findRoute(address tIn, address tOut, uint amIn, uint8 depth,address[] calldata tokens) public view returns (uint amOut, bytes[] memory callPath) {
        amOut = amIn * ((tIn == tOut) ? 1 : 0);
        if (depth > 0) {
            depth--;
            for (uint8 t = 0; t < tokens.length; t++) {
                (uint amOutCon, bytes[] memory callPathCon) = findRoute(tIn, tokens[t], amIn, depth,tokens);
                if (amOutCon > 0) {
                    if(tokens[t] == tOut) (amOut,callPath)=(amOutCon,callPathCon);
                    else{
                        (uint _amOut,bytes memory call)=findPool(tokens[t], tOut,amOutCon);
                        if (_amOut > amOut)
                            (amOut,callPath) = (_amOut,addCall(callPathCon, call));
                    }
                }
            }
        }
    }
}

interface IV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
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
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
    function tickSpacing() external view returns (int24);
    function liquidity() external view returns (uint128);
}

interface IAlgebraV3Pool is IV3Pool {
    function globalState() external view returns (uint160 price, int24 tick, uint16 feeZtO, uint16 feeOtZ, uint16 timepointIndex, uint8 communityFee, bool unlocked);
    function swap(address recipient,bool zeroForOne,int256 amountSpecified,uint160 sqrtPriceLimitX96,bytes calldata data) external returns (int256 amount0, int256 amount1);
}

interface IKyberV3Pool is IV3Pool {
    function swap(address recipient,int256 swapQty,bool isToken0,uint160 limitSqrtP,bytes calldata data) external returns (int256 amount0, int256 amount1);
    function swapFeeUnits() external view returns (uint24);
    function getPoolState() external view returns (uint160 sqrtP,int24 currentTick,int24 nearestCurrentTick,bool locked);
    function tickDistance() external view returns (int24);
    function getLiquidityState() external view returns (uint128,uint128,uint128);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}