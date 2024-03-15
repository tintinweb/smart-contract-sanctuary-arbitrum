// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;






library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }


    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }






    function muldiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {





        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }


        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }



        require(denominator > prod1);







        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }

        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }




        uint256 twos = (type(uint256).max - denominator + 1) & denominator;

        assembly {
            denominator := div(denominator, twos)
        }


        assembly {
            prod0 := div(prod0, twos)
        }



        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;






        uint256 inv = (3 * denominator) ^ 2;



        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256







        result = prod0 * inv;
        return result;
    }






    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = muldiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}
interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV3Pair {
    function slot0() external view returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
    );
    function liquidity() external view returns (uint128);
    function ticks(int24 tick) external view  returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
    );
    function tickBitmap(int16 wordPosition) external view returns (uint256);
    function positions(bytes32 key) external view returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
    );
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function tickSpacing() external view returns (int24);
    function maxLiquidityPerTick() external view returns (uint128);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface IPair {

    function amountIn(address output, uint _amountOut, address caller) external view returns (uint _amountIn);
    function amountOut(address input, uint _amountIn, address caller) external view returns (uint _amountOut);
    function swap(
        address to,
        address caller,
        address factory
    ) external returns (uint);
    function borrow(address to, uint _amountOut, bool isToken0, bytes calldata data) external;
    function getReserves() external view returns (
        uint112 _reserve0, 
        uint112 _reserve1, 
        uint32 _blockTimestampLast
    );
    function token0() external view returns (address);
    function token1() external view returns (address);
    function factory() external view returns (address);
}
interface IGenerator {
    struct Info {
        address owner;
        uint16 burnFee;
        address burnToken;
        uint16 teamFee;
        address teamAddress;
        uint16 lpFee;
        address referrer;
        uint16 referFee;
        uint16 labFee;
    }
    function factoryInfo(address) external view returns (Info memory);
    function FEE_DENOMINATOR() external view returns (uint16);
}
interface IFactory {
    function generator() external view returns (address);
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
        uint deadline,
        address f
    ) external;
}
contract ExternalRouter is IExternalRouter {

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    event FeeCollected(address indexed collected, address indexed token, uint amount, address indexed factory);
    struct SwapCallbackData {
        address payer;
        address tokenIn;
        address tokenOut;
        uint256 maxAmountIn;
    }

    bool private _swapping;

    modifier inSwap() {
        require(_swapping, "Router: must be in swap");
        _;
    }

    modifier swapping() {  
        _swapping = true;
        _;
        _swapping = false;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    IWETH public WETH;
    constructor(address _weth) {
        WETH = IWETH(_weth);
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external inSwap() { //ensure that we are in a swap currently before just sending stuff places.
        _v3Callback(amount0Delta, amount1Delta, data);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external inSwap() { //ensure that we are in a swap currently before just sending stuff places.
        _v3Callback(amount0Delta, amount1Delta, _data);
    }

    function solidlyV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external inSwap() {
        _v3Callback(amount0Delta, amount1Delta, data);
    }

    function ramsesV2SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external inSwap() { //ensure that we are in a swap currently before just sending stuff places.
        _v3Callback(amount0Delta, amount1Delta, data);
    }


    function _v3Callback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) internal {
        require(amount0Delta > 0 || amount1Delta > 0, "Invalid output"); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);
        require(data.maxAmountIn <= amountToPay, "Invalid input amount"); //ensure they are not trying to take more than we intended.
        assert(data.payer == address(this) || data.payer == tx.origin); //ensure that the payer is either us or the original caller.
        if (data.payer == address(this)) {
            safeTransfer(data.tokenIn, msg.sender, amountToPay);
        } else {
            safeTransferFrom(data.tokenIn, data.payer, msg.sender, amountToPay);
        }
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max));
        return int256(value);
    }

    function _swapV3(address pairAddress, address input, uint256 inputAmount, uint160 sqrtPriceLimitX96, uint256 minOutput, address to, address from) internal returns (uint256 outputAmount) { //exactInput
        IUniswapV3Pair pair = IUniswapV3Pair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        bool zeroForOne = token0 == input;
        int256 amount0;
        int256 amount1;
        address _input = input;
        uint256 _inputAmount = inputAmount;
        {
            (amount0, amount1) = pair.swap(
                to,
                zeroForOne,
                toInt256(_inputAmount),
                sqrtPriceLimitX96 == 0 ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1) : sqrtPriceLimitX96,
                abi.encode(SwapCallbackData(from, _input, zeroForOne ? token1 : token0, _inputAmount))
            );
        }
        outputAmount = uint256(-(zeroForOne ? amount1 : amount0));
        require(outputAmount >= minOutput, "S3:IO");
    }

    function _swapV2(
        address pairAddress,
        address input,
        uint256 inputAmount,
        uint256 minOutput,
        uint48 fee,
        address to,
        bool multihop,
        bool t
    ) internal returns (uint256 amountOutput) { //exactInput
        if (!multihop) safeTransferFrom(input, msg.sender, pairAddress, inputAmount);
        else if (t) safeTransfer(input, pairAddress, inputAmount);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address token0 = pair.token0();
        bool isInputToken0 = token0 == input;
        {
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            (uint256 reserveInput, uint256 reserveOutput) = isInputToken0  ? (reserve0, reserve1)  : (reserve1, reserve0);
            inputAmount = IERC20(input).balanceOf(pairAddress) - reserveInput;
            uint amountInMinusFee = inputAmount * (10000 - fee);
            uint256 numerator = amountInMinusFee * reserveOutput;
            uint256 denominator = reserveInput * 10000 + amountInMinusFee;
            amountOutput = numerator / denominator;
        }
        require(amountOutput >= minOutput, "S2:IO");
        (uint256 amount0Out, uint256 amount1Out) = isInputToken0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }


    function _swapLab(
        address pair,
        address input,
        uint256 inputAmount,
        uint256 minOutput,
        address to,
        bool multihop,
        bool t
    ) internal returns (uint256 amountOut) {
        if (!multihop) safeTransferFrom(input, msg.sender, pair, inputAmount);
        else if (t) safeTransfer(input, msg.sender, inputAmount);
        amountOut = IPair(pair).swap(to, msg.sender, address(this));
        require(amountOut >= minOutput, "S:IO");
    }

    function _takeFees(address input, uint256 amountIn, address f, bool owned) internal returns (uint256) {
        address generator = IFactory(f).generator();
        IGenerator gen = IGenerator(generator);
        IGenerator.Info memory fees = gen.factoryInfo(f);
        uint16 totalFee = fees.teamFee + fees.referFee + fees.labFee;
        if (totalFee > 0) {
            uint amountFee = Math.muldiv(amountIn, totalFee, gen.FEE_DENOMINATOR());
            amountIn -= amountFee;
            if (amountFee > 0) {
                uint256 amountTeam;
                if (fees.teamFee > 0) {
                    amountTeam = Math.muldiv(amountFee, fees.teamFee, totalFee);
                    if (!owned) safeTransferFrom(input, msg.sender, fees.teamAddress, amountTeam);
                    else safeTransfer(input, fees.teamAddress, amountTeam);
                    emit FeeCollected(fees.teamAddress, input, amountTeam, f);
                }
                uint256 amountRefer;
                if (fees.referFee > 0) {
                    amountRefer = Math.min(amountFee - amountTeam, Math.muldiv(amountFee, fees.referFee, totalFee));
                    if (amountRefer > 0) {
                        if (!owned) safeTransferFrom(input, msg.sender, fees.referrer, amountRefer);
                        else safeTransfer(input, fees.referrer, amountRefer);
                        emit FeeCollected(fees.referrer, input, amountRefer, f);
                    }
                }
                if (fees.labFee > 0) {
                    uint labAmount = amountFee - amountTeam - amountRefer;
                    if (labAmount > 0) {                       
                        address team = gen.factoryInfo(generator).teamAddress;
                        if (!owned) safeTransferFrom(input, msg.sender, team, labAmount);
                        else safeTransfer(input, team, labAmount);
                        emit FeeCollected(team, input, labAmount, generator);
                    }
                }
            }
        }
        return amountIn;
    }


    function _swap(
        uint256 inputAmount,
        SwapParameters[] memory swaps,
        address to,
        uint deadline,
        address f,
        bool owned
    ) internal swapping() ensure(deadline) {
        uint amountIn = _takeFees(swaps[0].input, inputAmount, f, owned);
        for (uint i; i < swaps.length; i++) {
            address _to = i == swaps.length - 1 ? to : (swaps[i+1].swapType != 2 ? swaps[i+1].pair : address(this));
            if (swaps[i].swapType == 1) {
                amountIn = _swapV2(swaps[i].pair, swaps[i].input, amountIn, swaps[i].minOutput, swaps[i].fee, _to, owned || i != 0, owned);
            } else if (swaps[i].swapType == 2) {
                amountIn = _swapV3(swaps[i].pair, swaps[i].input, amountIn, swaps[i].sqrtPriceLimitX96, swaps[i].minOutput, _to, (!owned && i == 0) ? msg.sender : address(this));
            } else {
                amountIn = _swapLab(swaps[i].pair, swaps[i].input, amountIn, swaps[i].minOutput, _to, owned || i != 0, owned);
            }
        }
    }

    function swapWithFees(
        uint256 inputAmount,
        SwapParameters[] memory swaps,
        address to,
        uint deadline,
        address f
    ) external  {
        _swap(inputAmount, swaps, to, deadline, f, false);
    }

    function swapWithBase(
        uint256 inputAmount,
        SwapParameters[] memory swaps,
        address to,
        uint deadline,
        address f,
        bool unwrap
    ) external payable {
        uint256 v = msg.value;
        IWETH weth = WETH;
        if (v > 0) {
            require(v >= inputAmount, "II"); 
            if (v > inputAmount) payable(msg.sender).transfer(v - inputAmount);
            weth.deposit{value: inputAmount}();
        }
        _swap(
            inputAmount,
            swaps,
            unwrap ? address(this) : to,
            deadline,
            f,
            v > 0
        );
        if (unwrap) {
            weth.withdraw(weth.balanceOf(address(this)));
            payable(to).transfer(address(this).balance);
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: transferFrom failed"
        );
    }

  function safeTransfer(
    address token,
    address to,
    uint256 value
) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::safeTransfer: transfer failed"
    );
  }
    
}