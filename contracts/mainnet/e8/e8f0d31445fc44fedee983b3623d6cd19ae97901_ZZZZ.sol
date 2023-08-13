//SPDX-License-Identifier: UNLICENSED
/*                              
                    CHAINTOOLS 2023. DEFI REIMAGINED

                                                               2023

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀            2021           ⣰⣾⣿⣶⡄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀2019⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀     ⠹⣿V4⡄⡷⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⠀⠀⠀⠀⠀⠀⠀⠀ ⣤⣾⣿⣷⣦⡀⠀⠀⠀⠀   ⣿⣿⡏⠁⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣿⣿⣿⣷⡀⠀⠀⠀⠀ ⢀⣿⣿⣿⣿⣿⠄⠀⠀⠀  ⣰⣿⣿⣧⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣾⣿⣿⣿⣿⣿⣿⡄⠀⠀ ⢀⣴⣿⣿⣿⠟⠛⠋⠀⠀⠀ ⢸⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣿⣿⣿⣿⣿⠟⠉⠉⠉⠁⢀⣴⣿⣿V3⣿⣿⠀⠀⠀⠀⠀  ⣾⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣾⣿⣿⣿⣿⣿⠛⠀⠀⠀⠀⠀ ⣾⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀ ⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀   
⠀⠀⠀        2017⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿V2⣿⣿⡿⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀ ⢹⣿ ⣿⣿⣿⣿⠙⢿⣆⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣴⣦⣤⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⠛⠿⠿⠶⠶⣶⠀  ⣿ ⢸⣿⣿⣿⣿⣆⠹⠇⠀⠀   
⠀⠀⠀⠀⠀⠀⢀⣠⣴⣿⣿⣿⣿⣷⡆⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⡇⠉⠛⢿⣷⡄⠀⠀⠀⢸⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀  ⠹⠇⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀   
⠀⠀⠀⠀⣠⣴⣿⣿V1⣿⣿⣿⡏⠛⠃⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣇⠀⠀⠘⠋⠁⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀  ⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀   
⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀ ⠸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀  ⠀⣿⣿⡟⢿⣿⣿⠀⠀⠀⠀   
⠀⢸⣿⣿⣿⣿⣿⠛⠉⠙⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀ ⢈⣿⣿⡟⢹⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⡿⠈⣿⣿⡟⠀⠀⠀⠀⠀  ⢸⣿⣿⠀⢸⣿⣿⠀⠀⠀⠀   
⠀⠀⠹⣿⣿⣿⣿⣷⡀⠀⠻⣿⣿⣿⣿⣶⣄⠀⠀⠀⢰⣿⣿⡟⠁⣾⣿⣿⠀⠀⠀⠀⠀⠀⢀⣶⣿⠟⠋⠀⢼⣿⣿⠃⠀⠀⠀⠀⠀  ⣿⣿⠁⠀⢹⣿⣿⠀⠀⠀⠀   
⠀⢀⣴⣿⡿⠋⢹⣿⡇⠀⠀⠈⠙⣿⣇⠙⣿⣷⠀⠀⢸⣿⡟⠀⠀⢻⣿⡏⠀⠀⠀⠀⠀⢀⣼⡿⠁⠀⠀⠀⠘⣿⣿⠀⠀⠀⠀⠀   ⢨⣿⡇⠀⠀⠀⣿⣿⠀⠀⠀⠀   
⣴⣿⡟⠉⠀⠀⣾⣿⡇⠀⠀⠀⠀⢈⣿⡄⠀⠉⠀⠀⣼⣿⡆⠀⠀⢸⣿⣷⠀⠀⠀⠀⢴⣿⣿⠀⠀⠀⠀⠀⠀⣿⣯⡀⠀⠀⠀⠀    ⢸⣿⣇⠀⠀⠀⢺⣿⡄⠀⠀⠀   
⠈⠻⠷⠄⠀⠀⣿⣿⣷⣤⣠⠀⠀⠈⠽⠷⠀⠀⠀⠸⠟⠛⠛⠒⠶⠸⣿⣿⣷⣦⣤⣄⠈⠻⠷⠄⠀⠀⠀⠾⠿⠿⣿⣶⣤⠀    ⠘⠛⠛⠛⠒⠀⠸⠿⠿⠦ 


Telegram: https://t.me/ChaintoolsOfficial
Website: https://www.chaintools.ai/
Whitepaper: https://chaintools-whitepaper.gitbook.io/
Twitter: https://twitter.com/ChaintoolsTech
dApp: https://www.chaintools.wtf/
*/

pragma solidity ^0.8.19;

// import "forge-std/console.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Router02 {
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external view returns (address);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IV3Pool {
    function liquidity() external view returns (uint128 Liq);

    struct Info {
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function initialize(uint160 sqrtPriceX96) external;

    function positions(
        bytes32 key
    ) external view returns (IV3Pool.Info memory liqInfo);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function slot0()
        external
        view
        returns (uint160, int24, uint16, uint16, uint16, uint8, bool);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes memory data
    ) external;

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function approve(address who, uint256 wad) external returns (bool);

    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
    function mint(address dst, uint256 wad) external;
    
    function balanceOf(address _owner) external view returns (uint256);
}

interface IQuoterV2 {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IV3Factory {
    function getPool(
        address token0,
        address token1,
        uint24 poolFee
    ) external view returns (address);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address);
}

interface INonfungiblePositionManager {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool approved) external;

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function factory() external view returns (address);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata mp
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata dl
    ) external returns (uint256 amount0, uint256 amount1);

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IRouterV3 {
    function factory() external view returns (address);

    function WETH9() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external returns (uint256 amountIn);

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// // Credits: https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol
// library TickMath {
//     /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
//     int24 internal constant MIN_TICK = -887272;
//     /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
//     int24 internal constant MAX_TICK = 887272;

//     /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
//     uint160 internal constant MIN_SQRT_RATIO = 4295128739;
//     /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
//     uint160 internal constant MAX_SQRT_RATIO =
//         1461446703485210103287273052203988822378723970342;

//     /// @notice Calculates sqrt(1.0001^tick) * 2^96
//     /// @dev Throws if |tick| > max tick
//     /// @param tick The input tick for the above formula
//     /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
//     /// at the given tick
//     function getSqrtRatioAtTick(
//         int24 tick
//     ) external pure returns (uint160 sqrtPriceX96) {
//         uint256 absTick = tick < 0
//             ? uint256(-int256(tick))
//             : uint256(int256(tick));
//         require(absTick <= uint256(int256(MAX_TICK)), "T");

//         uint256 ratio = absTick & 0x1 != 0
//             ? 0xfffcb933bd6fad37aa2d162d1a594001
//             : 0x100000000000000000000000000000000;
//         if (absTick & 0x2 != 0)
//             ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
//         if (absTick & 0x4 != 0)
//             ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
//         if (absTick & 0x8 != 0)
//             ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
//         if (absTick & 0x10 != 0)
//             ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
//         if (absTick & 0x20 != 0)
//             ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
//         if (absTick & 0x40 != 0)
//             ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
//         if (absTick & 0x80 != 0)
//             ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
//         if (absTick & 0x100 != 0)
//             ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
//         if (absTick & 0x200 != 0)
//             ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
//         if (absTick & 0x400 != 0)
//             ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
//         if (absTick & 0x800 != 0)
//             ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
//         if (absTick & 0x1000 != 0)
//             ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
//         if (absTick & 0x2000 != 0)
//             ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
//         if (absTick & 0x4000 != 0)
//             ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
//         if (absTick & 0x8000 != 0)
//             ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
//         if (absTick & 0x10000 != 0)
//             ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
//         if (absTick & 0x20000 != 0)
//             ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
//         if (absTick & 0x40000 != 0)
//             ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
//         if (absTick & 0x80000 != 0)
//             ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

//         if (tick > 0) ratio = type(uint256).max / ratio;

//         // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
//         // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
//         // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
//         sqrtPriceX96 = uint160(
//             (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
//         );
//     }
// }

interface YieldVault {
    function getDeviation(
        uint256 amountIn,
        uint256 startTickDeviation
    ) external view returns (uint256 adjusted);

    function getCurrentTick() external view returns (int24 cTick);

    function getStartTickDeviation(
        int24 currentTick
    ) external view returns (uint256 perc);

    function findPoolFee(
        address token0,
        address token1
    ) external view returns (uint24 poolFee);

    function getPosition(
        uint256 tokenId
    ) external view returns (address token0, address token1, uint128 liquidity);

    function getTickDistance(
        uint256 flag
    ) external view returns (int24 tickDistance);

    function findApprovalToken(
        address pool
    ) external view returns (address token);

    function findApprovalToken(
        address token0,
        address token1
    ) external view returns (address token);

    function buyback(
        uint256 flag,
        uint128 internalWETHAmt,
        uint128 internalCTLSAmt,
        address to,
        uint256 id
    ) external returns (uint256 t0, uint256 t1);

    function keeper() external view returns(address);
}

interface YieldBooster {
    function preventFragmentations(address pool) external; 
}
interface TickMaths {
    function getSqrtRatioAtTick(
        int24 tick
    ) external pure returns (uint160 sqrtPriceX96);
}
contract ZZZZ is Context, IERC20, IERC20Metadata {
    INonfungiblePositionManager internal immutable positionManager;
    YieldBooster internal YIELD_BOOSTER;
    YieldVault internal YIELD_VAULT;
    TickMaths internal immutable TickMath;
    address internal immutable uniswapV3Pool;
    address internal immutable multiSig;
    address internal immutable WETH;
    address internal immutable v3Router;
    address internal immutable apest;

    uint256 public immutable MAX_SUPPLY;
    uint256 internal _totalSupply;

    uint8 internal tokenomicsOn;
    uint32 internal startStamp;
    uint32 internal lastRewardStamp;
    uint80 internal issuanceRate;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal isTaxExcluded;
    mapping(address => bool) internal badPool;

    mapping(address => address) internal upperRef;
    mapping(address => uint256) internal sandwichLock;

    event zapIn(
        address indexed from,
        uint256 tokenId,
        uint256 flag,
        uint256 amtETHIn,
        uint256 amtTokensIn
    );

    //Can be fetched using pool event flash(0,0, rewardLPETH, rewardLPTOKEN);
    // event rewardLPETH(uint256 amtETHIn);
    // event rewardLPTOKEN(uint256 amtTokenIn);
    event referralPaid(address indexed from, address indexed to, uint256 amt);

    error MinMax();
    error ZeroAddress();
    error Auth();
    error Sando();

    //old -> new token migration
    // function completeMigration(
    //     address[] calldata addressList,
    //     uint256[] calldata tokenAmounts
    // ) external payable {
    //     require(addressList.length == tokenAmounts.length);
    //     require(startStamp == 0, "already_complete");
    //     if (msg.sender != apest) revert Auth();
    //     uint256 size = uint256(addressList.length);

    //     for (uint256 i; i < size; ) {
    //         unchecked {
    //             address adr = addressList[i];
    //             uint256 amt = tokenAmounts[i];
    //             _totalSupply += amt;
    //             _balances[adr] = amt;
    //             emit Transfer(address(0), adr, amt);
    //             ++i;
    //         }
    //     }
    // }
    constructor(
        address _apest,
        address _tickMaths
        //migration
        // address[] memory addressList,
        // uint256[] memory tokenAmounts
    ) {
        // require(addressList.length == tokenAmounts.length, "L");
        // uint256 size = uint256(addressList.length);
        // for (uint256 i; i < size; ) {
        //     unchecked {
        //         address adr = addressList[i];
        //         uint256 amt = tokenAmounts[i];
        //         _totalSupply += amt;
        //         _balances[adr] = amt;
        //         emit Transfer(address(0), adr, amt);
        //         ++i;
        //     }
        // }
        
        TickMath = TickMaths(_tickMaths);
        // MAX_SUPPLY = 11_000_000e18;
        // _totalSupply = 11_000_000e18;
        multiSig = 0xb0Df68E0bf4F54D06A4a448735D2a3d7D97A2222;
        apest = _apest;
        tokenomicsOn = 1;
        issuanceRate = 10e18;
        v3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        // router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // WETH = IRouterV3(v3Router).WETH9();
        WETH = 0x0877fD90eD6CD35c7C0472b69F190B8C9aF0B53b;
        positionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );

        uniswapV3Pool = IV3Factory(positionManager.factory()).createPool(
            WETH,
            address(this),
            10000
        );

        require(IV3Pool(uniswapV3Pool).token0() == WETH, "token0pool0");
        //TODO:: CHANGE FOR LP
        //CHANGE START TICK
        uint256 forLiquidityBootstrap = 1_000_000e18;
        _balances[0x0000000000000000000000000000000000C0FFEE] = forLiquidityBootstrap;
        _totalSupply += forLiquidityBootstrap;
        emit Transfer(
            address(0),
            address(0x0000000000000000000000000000000000C0FFEE),
            forLiquidityBootstrap
        );

        uint256 forMigration = 6_200_000e18;
        //Initial supply
        _totalSupply += forMigration;//TODO:: MIGRATION TOTAL AMOUNT
        _balances[apest] += forMigration;
        emit Transfer(address(0), address(apest), forMigration);

        uint256 forLp = 600_000e18;
        _totalSupply += forLp;
        _balances[address(this)] += forLp;
        emit Transfer(address(0), address(this), forLp);

        uint256 forMarketing = 800_000e18;
        _totalSupply += forMarketing;
        _balances[multiSig] += forMarketing;
        emit Transfer(
            address(0),
            multiSig,
            forMarketing
        );

        int24 startTick = 98870;
        IV3Pool(uniswapV3Pool).initialize(
            TickMath.getSqrtRatioAtTick(startTick)
        );
        IERC20(WETH).approve(address(positionManager), type(uint256).max);
        IERC20(WETH).approve(v3Router, type(uint256).max);

        _allowances[address(this)][v3Router] = type(uint256).max;
        _allowances[address(this)][address(positionManager)] = type(uint256)
            .max;

        isTaxExcluded[v3Router] = true;
        isTaxExcluded[multiSig] = true;
        isTaxExcluded[address(this)] = true;
        MAX_SUPPLY = _totalSupply + 200_000e18;
    }

    function prepareFomo(address yieldVault, address yieldBooster) external {
        if (msg.sender != apest) revert Auth();
        if (startStamp != 0) revert MinMax();

        //Compounder
        YIELD_VAULT = YieldVault(yieldVault);
        isTaxExcluded[address(YIELD_VAULT)] = true;
        _allowances[address(YIELD_VAULT)][address(positionManager)] = type(
            uint256
        ).max;
        _allowances[address(YIELD_VAULT)][address(v3Router)] = type(uint256)
            .max;
        //Yield Booster
        YIELD_BOOSTER = YieldBooster(payable(yieldBooster));

        _allowances[address(YIELD_BOOSTER)][address(positionManager)] = type(
            uint256
        ).max;

        isTaxExcluded[address(YIELD_BOOSTER)] = true;
        _totalSupply += 200_000e18;
        _balances[address(YIELD_BOOSTER)] += 200_000e18;
        emit Transfer(address(0), address(YIELD_BOOSTER), 200_000e18);

        YIELD_BOOSTER.preventFragmentations(address(0));
    }

    receive() external payable {}

    function preparePool() external payable {
        if (msg.sender != apest) revert Auth();
        startStamp = uint32(block.timestamp);

        // int24 startTick = 98870;
        int24 tick = 98870;
        uint256 forLp = 600_000e18;
        tick = (tick / 200) * 200;
        uint256 a0;
        uint256 a1;
        // IWETH(WETH).deposit{value: msg.value}();
        IWETH(WETH).mint(address(this), 22e18);
        (, , a0, a1) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: WETH,
                token1: address(this),
                fee: 10000,
                tickLower: tick - 420000,
                tickUpper: tick + 420000,
                // amount0Desired: msg.value - 1e7,
                amount0Desired: 22e18 - 1e7,
                amount1Desired: forLp,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        IRouterV3(v3Router).exactInputSingle(
            IRouterV3.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: address(this),
                fee: 10000,
                recipient: multiSig,
                deadline: block.timestamp,
                amountIn: 1e7 - 1,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        positionManager.setApprovalForAll(address(YIELD_VAULT), true);

        uint256 leftOver2 = forLp - a1;
        uint256 leftOver = IERC20(WETH).balanceOf(address(this));

        if (leftOver != 0) {
            IERC20(WETH).transfer(multiSig, leftOver - 1);
        }

        _basicTransfer(address(this), multiSig, leftOver2);
        // console.log(leftOver2/1e18, "leftover2");
        startStamp = 0;
        // triggerOnApproval = 1;
    }

    function openTrading() external {
        startStamp = uint32(block.timestamp);
        lastRewardStamp = uint32(block.timestamp);
    }

    function name() public view virtual override returns (string memory) {
        return "test";
    }

    function symbol() public view virtual override returns (string memory) {
        return "test";
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _approve(from, spender, _allowances[from][spender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        unchecked {
            _balances[recipient] += amount;
        }
        if (
            sender != address(YIELD_BOOSTER) &&
            recipient != address(YIELD_BOOSTER) &&
            recipient != address(positionManager)
        ) emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) revert ZeroAddress();
        if (spender == address(0)) revert ZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function multiTransfer(address[] calldata to, uint256[] calldata amounts) external {
        uint size = to.length;
        require(size == amounts.length, "Length");
        for(uint i; i < size;) {
            unchecked {
                _basicTransfer(msg.sender, to[i], amounts[i]);
                ++i;
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        //determine trader
        address trader = sender == uniswapV3Pool ? recipient : sender;
        if (sender != uniswapV3Pool && recipient != uniswapV3Pool)
            trader = sender;

        if (startStamp == 0) {
            revert MinMax();
        }

        if (
            recipient == uniswapV3Pool ||
            recipient == address(positionManager) ||
            isTaxExcluded[sender] ||
            isTaxExcluded[recipient]
        ) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (
            trader != address(this) &&
            trader != address(YIELD_BOOSTER) &&
            trader != address(positionManager) &&
            trader != address(YIELD_VAULT)
        ) {
            //One Block Delay [Sandwich Protection]
            if (sandwichLock[trader] < block.number) {
                sandwichLock[trader] = block.number + 1;
            } else {
                revert Sando();
            }
        }

        if (tokenomicsOn != 0) {
            if (amount < 1e8 || amount > 2_000_000e18) revert MinMax();
        } else {
            return _basicTransfer(sender, recipient, amount);
        }

        //Normal Transfer
        if (
            sender != uniswapV3Pool &&
            sender != address(positionManager) &&
            recipient != uniswapV3Pool
        ) {
            if (badPool[recipient]) revert Auth();
            try this.swapBack() {} catch {}
            return _basicTransfer(sender, recipient, amount);
        }

        unchecked {
            if (sender != uniswapV3Pool) {
                try this.swapBack() {} catch {}
            }
        }

        _balances[sender] -= amount;

        //Tax & Final transfer amounts
        unchecked {
            uint256 tFee = amount / 20;
            
            if (
                //Only first 10 minutes
                block.timestamp < startStamp + 10 minutes
            ) {
                //Sniper bots funding lp rewards
                tFee *= 2;
            }

            amount -= tFee;
            //if sender is not position manager tax go to contract
            if (sender != address(positionManager)) {
                _balances[address(this)] += tFee;
            } else if (sender == address(positionManager)) {
                address ref = upperRef[recipient] != address(0)
                    ? upperRef[recipient]
                    : multiSig;
                uint256 rFee0 = tFee / 5;
                _balances[ref] += rFee0;
                tFee -= rFee0;

                _balances[address(YIELD_BOOSTER)] += tFee;

                emit Transfer(recipient, ref, tFee);
                emit referralPaid(recipient, ref, rFee0);
            }

            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapBack() public {
        unchecked {
            uint256 fullAmount = _balances[address(this)];
            if (fullAmount < _totalSupply / 2000) {
                return;
            }

            if (
                msg.sender != address(this) &&
                msg.sender != address(YIELD_VAULT) &&
                msg.sender != address(YIELD_BOOSTER)
            ) revert Auth();
            //0.20% max per swap
            uint256 maxSwap = _totalSupply / 500;

            if (fullAmount > maxSwap) {
                fullAmount = maxSwap;
            }

            IRouterV3(v3Router).exactInputSingle(
                IRouterV3.ExactInputSingleParams({
                    tokenIn: address(this),
                    tokenOut: WETH,
                    fee: 10000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: fullAmount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        }
    }

    function sendLPRewards() internal {
        unchecked {
            address sendToken = WETH;
            assembly {
                let bal := balance(address())
                if gt(bal, 1000000000000) {
                    let inputMem := mload(0x40)
                    mstore(inputMem, 0xd0e30db)
                    pop(call(gas(), sendToken, bal, inputMem, 0x4, 0, 0))
                }
            }
            uint256 fin = IERC20(WETH).balanceOf(address(this)) - 1;
            address toMsig = multiSig;
            address toPool = uniswapV3Pool;
            assembly {
                if gt(fin, 1000000000000) {
                    let inputMem := mload(0x40)
                    mstore(
                        inputMem,
                        0xa9059cbb00000000000000000000000000000000000000000000000000000000
                    )
                    mstore(add(inputMem, 0x04), toMsig)
                    mstore(add(inputMem, 0x24), div(mul(fin, 65), 100))
                    pop(call(gas(), sendToken, 0, inputMem, 0x44, 0, 0))
                    mstore(
                        inputMem,
                        0xa9059cbb00000000000000000000000000000000000000000000000000000000
                    )
                    mstore(add(inputMem, 0x04), toPool)
                    mstore(add(inputMem, 0x24), div(mul(fin, 35), 100))
                    pop(call(gas(), sendToken, 0, inputMem, 0x44, 0, 0))
                }
            }
        }
    }

    function flashReward() external {
        if (
            msg.sender != address(this) &&
            msg.sender != address(YIELD_VAULT) &&
            msg.sender != address(multiSig) &&
            msg.sender != address(YIELD_BOOSTER)
        ) revert Auth();
        if (IV3Pool(uniswapV3Pool).liquidity() != 0) {
            IV3Pool(uniswapV3Pool).flash(address(this), 0, 0, "");
        }
    }

    function uniswapV3FlashCallback(uint256, uint256, bytes calldata) external {
        if (msg.sender != uniswapV3Pool) revert Auth();
        uint256 secondsPassed = block.timestamp - lastRewardStamp;
        if (secondsPassed > 30 minutes) {
            sendLPRewards();
            lastRewardStamp = uint32(block.timestamp);

            if (issuanceRate == 0) return;

            uint256 pending = (secondsPassed / 60) * issuanceRate;
            if (
                _balances[0x0000000000000000000000000000000000C0FFEE] >= pending
            ) {
                unchecked {
                    _balances[
                        0x0000000000000000000000000000000000C0FFEE
                    ] -= pending;
                    _balances[uniswapV3Pool] += pending;
                    emit Transfer(
                        0x0000000000000000000000000000000000C0FFEE,
                        uniswapV3Pool,
                        pending
                    );
                }
            }
        }
    }

    function _collectLPRewards(
        uint256 tokenId
    ) internal returns (uint256 c0, uint256 c1) {
        (c0, c1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }

    function _decreasePosition(
        uint256 tokenId,
        uint128 liquidity
    ) internal returns (uint256 a0, uint256 a1) {
        positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        (a0, a1) = _collectLPRewards(tokenId);
    }

    function _swapV3(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint256 amountIn,
        uint256 minOut
    ) internal returns (uint256 out) {
        if (tokenIn != WETH && tokenIn != address(this)) {
            tokenIn.call(
                abi.encodeWithSelector(
                    IERC20.approve.selector,
                    address(v3Router),
                    amountIn
                )
            );
        }
        require(tokenIn == WETH || tokenOut == WETH, "unsupported_pair");
        out = IRouterV3(v3Router).exactInputSingle(
            IRouterV3.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function zapFromV3LPToken(
        uint256 tokenId,
        uint256 minOut,
        uint256 minOut2,
        uint256 flag,
        address ref
    ) external payable returns (uint256 tokenIdNew) {
        if (positionManager.ownerOf(tokenId) != msg.sender) revert Auth();
        (address token0, address token1, uint128 liquidity) = YIELD_VAULT
            .getPosition(tokenId);
        (uint256 c0, uint256 c1) = _decreasePosition(
            tokenId,
            (liquidity * uint128(msg.value)) / 100
        );

        uint256 gotOut = _swapV3(
            token0 == WETH ? token1 : token0,
            WETH,
            YIELD_VAULT.findPoolFee(token0, token1),
            token0 == WETH ? c1 : c0,
            minOut
        );

        uint256 totalWETH = token0 == WETH ? c0 + gotOut : c1 + gotOut;
        address _weth = WETH;
        assembly {
            let inputMem := mload(0x40)
            mstore(
                inputMem,
                0x2e1a7d4d00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(inputMem, 0x04), totalWETH)
            pop(call(gas(), _weth, 0, inputMem, 0x24, 0, 0))
        }

        return
            this.zapFromETH{value: totalWETH}(minOut2, msg.sender, flag, ref);
    }

    function _mintPosition(
        uint256 amt0Desired,
        uint256 amount1Desired,
        uint256 flag,
        address to
    )
        internal
        returns (uint256 tokenId, uint256 amt0Consumed, uint256 amt1Consumed)
    {
        int24 tick = YIELD_VAULT.getCurrentTick();
        int24 tickDist = YieldVault(YIELD_VAULT).getTickDistance(flag);
        (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: WETH,
                token1: address(this),
                fee: 10000,
                tickLower: tick - tickDist < int24(-887000)
                    ? int24(-887000)
                    : tick - tickDist,
                tickUpper: tick + tickDist > int24(887000)
                    ? int24(887000)
                    : tick + tickDist,
                amount0Desired: amt0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: to,
                deadline: block.timestamp
            })
        );
    }

    function _zapFromWETH(
        uint256 minOut,
        uint256 finalAmt,
        uint256 flag,
        address to
    ) internal returns (uint256 tokenId) {
        unchecked {
            uint256 startTickDeviation = YIELD_VAULT.getStartTickDeviation(
                YIELD_VAULT.getCurrentTick()
            );

            uint256 gotTokens;

            uint256 deviationAmt = YIELD_VAULT.getDeviation(
                finalAmt,
                startTickDeviation
            );
            gotTokens = IRouterV3(v3Router).exactInputSingle(
                IRouterV3.ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: address(this),
                    fee: 10000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: deviationAmt,
                    amountOutMinimum: minOut,
                    sqrtPriceLimitX96: 0
                })
            );
            finalAmt -= deviationAmt;
            uint256 a1Out;
            (tokenId, deviationAmt, a1Out) = _mintPosition(
                finalAmt,
                gotTokens,
                flag,
                to
            );

            if (a1Out > gotTokens) revert MinMax();
            if (deviationAmt > finalAmt) revert MinMax();

            address sendToken = WETH;
            assembly {
                let refundAmtWETH := sub(finalAmt, deviationAmt)
                if gt(refundAmtWETH, 100000000000000) {
                    let inputMem := mload(0x40)
                    mstore(
                        inputMem,
                        0xa9059cbb00000000000000000000000000000000000000000000000000000000
                    )
                    mstore(add(inputMem, 0x04), to)
                    mstore(add(inputMem, 0x24), sub(finalAmt, deviationAmt))
                    pop(call(gas(), sendToken, 0, inputMem, 0x44, 0, 0))
                }
            }

            if (gotTokens - a1Out >= 1e18)
                _basicTransfer(address(this), to, gotTokens - a1Out);

            emit zapIn(to, tokenId, flag, deviationAmt, gotTokens);
        }
    }

    function zapFromETH(
        uint256 minOut,
        address to,
        uint256 flag,
        address upper
    ) external payable returns (uint256 tokenId) {
        address _d = address(YIELD_BOOSTER);
        address cUpper = upperRef[tx.origin];
        //handle referrals
        {
            if (
                upper != tx.origin &&
                cUpper == address(0) &&
                upper != address(0)
            ) {
                upperRef[tx.origin] = upper;
            }
            if (upperRef[tx.origin] == address(0)) {
                cUpper = _d;
            } else {
                cUpper = upperRef[tx.origin];
            }
        }

        unchecked {
            uint256 finalAmt = msg.value;
            uint256 forReferral = finalAmt / 100; //1%
            finalAmt -= (forReferral * 3); //3% taxx
            address sendToken = WETH;
            assembly {
                if eq(_d, cUpper) {
                    pop(call(10000, _d, mul(forReferral, 3), "", 0, 0, 0))
                }

                if not(eq(_d, cUpper)) {
                    pop(call(gas(), _d, mul(forReferral, 2), "", 0, 0, 0))
                    pop(call(7000, cUpper, forReferral, "", 0, 0, 0))
                }

                let inputMem := mload(0x40)
                //wrap eth
                mstore(inputMem, 0xd0e30db)
                pop(call(gas(), sendToken, finalAmt, inputMem, 0x4, 0, 0))
            }

            emit referralPaid(to, cUpper, forReferral);
            return _zapFromWETH(minOut, finalAmt, flag, to);
        }
    }

    //Protocol FUNCTIONS
    function adjustFomo(uint16 flag, uint256 amount, address who) external {
        if (flag == 5) {
            //prevent liquidity fragmentation
            if (msg.sender != address(YIELD_BOOSTER)) revert Auth();
            require(IV3Pool(who).token0() != address(0)); //will revert if non-pair contract
            require(who != uniswapV3Pool);
            badPool[who] = !badPool[who];
        } else {
            if (msg.sender != multiSig) revert Auth();

            if (flag == 0) {
                //Shutdown tokenomics [emergency only!]
                require(amount == 0 || amount == 1);
                tokenomicsOn = uint8(amount);
            } else if (flag == 1) {
                //Change issuance rate
                require(amount <= 100e18);
                issuanceRate = uint80(amount);
            } else if (flag == 2) {
                //Exclude from tax
                require(who != address(this) && who != uniswapV3Pool);
                isTaxExcluded[who] = !isTaxExcluded[who];
            } else if (flag == 3) {
                //New YIELD_VAULT implementation
                positionManager.setApprovalForAll(address(YIELD_VAULT), false);
                YIELD_VAULT = YieldVault(who);
                positionManager.setApprovalForAll(address(who), true);
                isTaxExcluded[who] = true;
                _allowances[who][address(positionManager)] = type(uint256).max;
            } else if (flag == 4) {
                //Unlock LP
                require(block.timestamp >= startStamp + (1 days * 30 * 4));
                positionManager.transferFrom(address(this), multiSig, amount);
            } else if (flag == 5) {
                YIELD_BOOSTER = YieldBooster(who);
                isTaxExcluded[who] = true;
            }
        }
    }

    //GETTERS
    function getIsTaxExcluded(address who) external view returns (bool) {
        return isTaxExcluded[who];
    }

    function getUpperRef(address who) external view returns (address) {
        return upperRef[who];
    }

    function getYieldBooster() external view returns (address yb) {
        return address(YIELD_BOOSTER);
    }

    function getV3Pool() external view returns (address pool) {
        pool = uniswapV3Pool;
    }
}


// contract YieldVault {
//     struct Pending {
//         uint128 amount0;
//         uint128 amount1;
//     }

//     INonfungiblePositionManager internal immutable positionManager;

//     address internal immutable quoter;
//     address internal immutable CTLS;
//     address internal immutable WETH;
//     address internal immutable multiSig;
//     address internal immutable v3Router;
//     address internal immutable uniswapV3Pool;
//     address public keeper;
//     uint256 internal minCompAmtETH = 2e17;

//     mapping(uint256 => Pending) internal balances;
//     mapping(address => uint128) internal refBalances;

//     error Auth();
//     error Max0();
//     error Max1();

//     event referralPaid(
//         address indexed from,
//         address indexed to,
//         uint256 amount
//     );
//     event Compounded(uint256 indexed tokenId, uint256 c0, uint256 c1);
//     event ShiftedPosition(
//         uint256 indexed tokenIdOld,
//         uint256 indexed tokenIdNew,
//         uint256 flag,
//         uint256 t0,
//         uint256 t1
//     );
//     event BoughtBack(uint256 indexed flag, uint256 a0, uint256 a1);
//     event limitOrderCreated(
//         address indexed who,
//         uint256 tokenId,
//         uint256 flag,
//         uint256 amount0Or1,
//         bool isWETH
//     );

//     constructor(
//         address _CTLS,
//         address _keeper,
//         address _uniPool,
//         address _dev
//     ) {
//         positionManager = INonfungiblePositionManager(
//             0xC36442b4a4522E871399CD717aBDD847Ab11FE88
//         );
//         CTLS = _CTLS;
//         v3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
//         WETH = IRouterV3(v3Router).WETH9();
//         IERC20(WETH).approve(address(positionManager), type(uint256).max);

//         quoter = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
//         keeper = _keeper;
//         multiSig = _dev;
//         IERC20(WETH).approve(address(v3Router), type(uint256).max);

//         uniswapV3Pool = _uniPool;
//     }

//     //CallStatic
//     function filterReady(
//         uint256[] calldata tokenIds,
//         uint256 minAmount0,
//         uint256 minAmount1
//     )
//         external
//         returns (
//             uint256[] memory readyToComp,
//             uint256[] memory amt0,
//             uint256[] memory amt1,
//             uint256 gasSpent,
//             uint256 txCostInETH
//         )
//     {
//         if (msg.sender != keeper) revert Auth();
//         unchecked {
//             try ctls(payable(CTLS)).swapBack() {} catch {}
//             try ctls(payable(CTLS)).flashReward() {} catch {}

//             uint256 startGas = gasleft();
//             uint256 tokenIdsL = tokenIds.length;
//             readyToComp = new uint256[](tokenIdsL);
//             amt0 = new uint256[](tokenIdsL);
//             amt1 = new uint256[](tokenIdsL);
//             for (uint256 i; i < tokenIdsL; ) {
//                 uint256 tokenId = tokenIds[i];
//                 address tokenOwner = positionManager.ownerOf(tokenId);
//                 if (tokenId != 0) {
//                     try
//                         positionManager.collect(
//                             INonfungiblePositionManager.CollectParams({
//                                 tokenId: tokenId,
//                                 recipient: address(this),
//                                 amount0Max: type(uint128).max,
//                                 amount1Max: type(uint128).max
//                             })
//                         )
//                     returns (uint256 claimed0, uint256 claimed1) {
//                         Pending memory pen = balances[tokenId];
//                         // //console.log(claimed0, "collected0");balances
//                         // //console.log(claimed1, "collected1");
//                         //Compound Tax + Token Tax (10% TOTAL) [5% in WETH] [5% in TOKENS]

//                         refBalances[
//                             ctls(payable(CTLS)).getUpperRef(tokenOwner)
//                         ] = uint128(claimed0 / 100);
//                         balances[1].amount0 += uint128(claimed0 / 20);
//                         balances[1].amount1 += uint128(claimed1 / 20);
//                         claimed0 -= (claimed0 / 20) + (claimed0 / 100);
//                         claimed1 -= claimed1 / 20;
//                         //Referral Tax [1%]
//                         // claimed0 -= uint128(claimed0 / 100);

//                         // //console.log(
//                         //     ctls(payable(CTLS)).getUpperRef(tokenOwner),
//                         //     "Get-upper-ref"
//                         // );
//                         // //console.log(tokenOwner, "owner-?-ref");

//                         //Determine Referral

//                         // //console.log(
//                         //     refBalances[
//                         //         ctls(payable(CTLS)).getUpperRef(
//                         //             tokenOwner
//                         //         )
//                         //     ],
//                         //     "PENDING-REF"
//                         // );

//                         //Add Pending Earned Referral Rewards into Personal Pending Rewards
//                         pen.amount0 +=
//                             uint128(claimed0) +
//                             refBalances[tokenOwner];
//                         pen.amount1 += uint128(claimed1);

//                         //Reset pending referal
//                         refBalances[tokenOwner] = 0;
//                         // //console.log(claimed0, "CLAIMED_0");
//                         // //console.log(claimed1, "CLAIMED_1");
//                         if (claimed0 > minAmount0 && claimed1 > minAmount1) {
//                             readyToComp[i] = tokenId;
//                             amt0[i] = claimed0;
//                             amt1[i] = claimed1;
//                         }

//                         balances[tokenId] = pen;
//                     } catch {}
//                 }

//                 ++i;
//             }

//             gasSpent = startGas - gasleft();
//             txCostInETH = tx.gasprice * gasSpent;
//         }
//     }

//     function unite(
//         uint256[] calldata tokenIds
//     )
//         external
//         returns (uint256[] memory reverting, uint256 pFee0, uint256 pFee1)
//     {
//         if (msg.sender != keeper) revert Auth();
//         unchecked {
//             try ctls(payable(CTLS)).swapBack() {} catch {}
//             try ctls(payable(CTLS)).flashReward() {} catch {}

//             uint256 tokenIdsL = tokenIds.length;
//             reverting = new uint256[](tokenIds.length);
//             for (uint256 i; i < tokenIdsL; ) {
//                 uint256 tokenId = tokenIds[i];
//                 address tokenOwner = positionManager.ownerOf(tokenId);
//                 try
//                     positionManager.collect(
//                         INonfungiblePositionManager.CollectParams({
//                             tokenId: tokenId,
//                             recipient: address(this),
//                             amount0Max: type(uint128).max,
//                             amount1Max: type(uint128).max
//                         })
//                     )
//                 returns (uint256 claimed0, uint256 claimed1) {
//                     Pending memory pen = balances[tokenId];
//                     // //console.log(claimed0, "collected0");balances
//                     // //console.log(claimed1, "collected1");

//                     //Compound Tax + Token Tax (10% TOTAL) [5% in WETH] [5% in TOKENS]
//                     pFee0 = claimed0 / 20;
//                     pFee1 = claimed1 / 20;
//                     uint256 rFee0 = claimed0 / 100;

//                     claimed0 -= (pFee0 + rFee0);
//                     claimed1 -= pFee1;

//                     balances[1].amount0 += uint128(pFee0);
//                     balances[1].amount1 += uint128(pFee1);

//                     //Referral Tax [1%]

//                     // //console.log(
//                     //     ctls(payable(CTLS)).getUpperRef(tokenOwner),
//                     //     "Get-upper-ref"
//                     // );
//                     // //console.log(tokenOwner, "owner-?-ref");

//                     //Determine Referal
//                     refBalances[
//                         ctls(payable(CTLS)).getUpperRef(tokenOwner)
//                     ] = uint128(rFee0);
//                     // //console.log(
//                     //     refBalances[
//                     //         ctls(payable(CTLS)).getUpperRef(tokenOwner)
//                     //     ],
//                     //     "PENDING-REF"
//                     // );

//                     //Add Pending Earned Referral Rewards into Personal Pending Rewards
//                     pen.amount0 += uint128(claimed0) + refBalances[tokenOwner];
//                     pen.amount1 += uint128(claimed1);

//                     //Reset pending referal
//                     refBalances[tokenOwner] = 0;

//                     // //console.log(pen.amount0, "amt0Stor");
//                     // //console.log(pen.amount1, "amt1Stor");
//                     // //console.log(tokenId, "TOKEN_IDE");

//                     if (claimed0 != 0 && claimed1 != 0) {
//                         try this.increaseLiq(tokenId, pen) {} catch {
//                             //CallStatic catch reverting -> exclude from call
//                             //If revert during real call, update balances to sync referral rewards
//                             // //console.log("Failed_to_collected", tokenId);
//                             // //console.log("Failed_to_collected", tokenId);
//                             // //console.log("Failed_to_collected", tokenId);
//                             // //console.log("Failed_to_collected", tokenId);
//                             balances[tokenId] = pen;
//                             reverting[i] = tokenId;
//                         }

//                         // //console.log(balances[tokenId].amount0, "amt0Stor_after");
//                         // //console.log(balances[tokenId].amount1, "amt1Stor_after");
//                         // //console.log( "--------------");
//                     } else {
//                         reverting[i] = tokenId;
//                         balances[tokenId] = pen;
//                     }
//                     // else {
//                     //     revert("insufficient_tokens");
//                     // }
//                 } catch {
//                     reverting[i] = tokenId;
//                 }

//                 ++i;
//             }
//         }
//     }

//     function increaseLiq(
//         uint256 tokenId,
//         Pending memory pen
//     ) external returns (uint256 collected0, uint256 collected1) {
//         if (msg.sender != address(this)) revert Auth();
//         // uint bal0Bef = IERC20(WETH).balanceOf(address(this));
//         // uint bal1Bef = IERC20(CTLS).balanceOf(address(this));
//         // //console.log(bal0Bef, "balOfThis_before_AddLiq");
//         // //console.log(bal1Bef, "balOfThis_before_AddLiq");
//         (, collected0, collected1) = positionManager.increaseLiquidity(
//             INonfungiblePositionManager.IncreaseLiquidityParams({
//                 tokenId: tokenId,
//                 amount0Desired: pen.amount0,
//                 amount1Desired: pen.amount1,
//                 amount0Min: 0,
//                 amount1Min: 0,
//                 deadline: block.timestamp
//             })
//         );
//         // uint bal0Aft = IERC20(WETH).balanceOf(address(this));
//         // uint bal1Aft = IERC20(CTLS).balanceOf(address(this));
//         // //console.log(bal0Aft, "balOfThis_After_AddLiq");
//         // //console.log(bal1Aft, "balOfThis_After_AddLiq");

//         // //console.log(bal0Bef - bal0Aft, "DIFF");
//         // //console.log(collected0, "increase0");
//         // //console.log(bal1Bef - bal1Aft, "DIFF");
//         // //console.log(collected1, "increased1");
//         // require(bal0Bef - bal0Aft == collected0, "increased0");
//         // require(bal1Bef - bal1Aft == collected1, "increased1");
//         // //console.log(IERC20(CTLS).balanceOf(address(this)) - collected1, "DIFFERENCE");
//         // require(IERC20(WETH).balanceOf(address(this)) > collected0, "DIFFERECE_0");
//         // require(IERC20(CTLS).balanceOf(address(this)) > collected1, "DIFFERECE_1");
//         //    require(collected0 <= pen.amount0, "max0");
//         //    require(collected1 <= pen.amount1, "max1");
//         // if (collected0 > pen.amount0 && collected0 > IERC20(WETH).balanceOf(address(this))) revert Max0();
//         // if (collected1 > pen.amount1 && collected1 > IERC20(CTLS).balanceOf(address(this))) revert Max1();
//         if (
//             collected0 > pen.amount0 &&
//             collected0 > IERC20(WETH).balanceOf(address(this))
//         ) revert Max0();
//         if (
//             collected1 > pen.amount1 &&
//             collected1 > IERC20(CTLS).balanceOf(address(this))
//         ) revert Max1();
//         // //console.log(collected0, "collected_0");
//         // //console.log(collected1, "collected_1");
//         balances[tokenId].amount0 = (pen.amount0 - uint128(collected0));
//         balances[tokenId].amount1 = (pen.amount1 - uint128(collected1));
//         emit Compounded(tokenId, collected0, collected1);
//         // //console.log("Collected");
//         // //console.log("afterAdd");
//     }

//     function withdraw_yield(
//         uint256 tokenId,
//         uint128 amount0,
//         uint128 amount1
//     ) public {
//         address tokenOwner = positionManager.ownerOf(tokenId);
//         // //console.log(tokenOwner, msg.sender, "OWNER-SENDER");
//         // require(tokenOwner == msg.sender, "");
//         // //console.log(multiSig, "multiSig?!");
//         if (tokenId == 1) tokenOwner = multiSig;
//         if (tokenOwner != msg.sender) revert Auth();

//         // //console.log(tokenId, "ID");
//         // //console.log(amount0, "Amount0");
//         // //console.log(amount1, "Amount1");
//         // //console.log(balances[tokenId].amount0, "balance_internal_0");
//         // //console.log(balances[tokenId].amount1, "balance_internal_0");
//         unchecked {
//             if (amount0 == 0 && amount1 == 0) {
//                 amount0 = balances[tokenId].amount0;
//                 amount1 = balances[tokenId].amount1;
//                 balances[tokenId].amount0 = 0;
//                 balances[tokenId].amount1 = 0;
//                 IERC20(WETH).transfer(tokenOwner, amount0);
//                 IERC20(CTLS).transfer(tokenOwner, amount1);
//             } else if (amount0 != 0 && amount1 != 0) {
//                 if (amount0 > balances[tokenId].amount0) revert Max0();
//                 if (amount1 > balances[tokenId].amount1) revert Max1();
//                 balances[tokenId].amount0 -= amount0;
//                 balances[tokenId].amount1 -= amount1;

//                 IERC20(WETH).transfer(tokenOwner, amount0);
//                 IERC20(CTLS).transfer(tokenOwner, amount1);
//             } else if (amount0 == 0 && amount1 != 0) {
//                 if (amount1 > balances[tokenId].amount1) revert Max1();
//                 balances[tokenId].amount1 -= amount1;
//                 IERC20(CTLS).transfer(tokenOwner, amount1);
//             } else if (amount0 != 0 && amount1 == 0) {
//                 if (amount0 > balances[tokenId].amount0) revert Max0();
//                 balances[tokenId].amount0 -= amount0;
//                 IERC20(WETH).transfer(tokenOwner, amount0);
//             }
//         }
//         // //console.log("after-after");
//         // //console.log(IERC20(WETH).balanceOf(address(this)), "balOfThis");
//         // //console.log(IERC20(CTLS).balanceOf(address(this)), "balOfThis");
//         // //console.log("after-after");
//     }

//     function withdraw_yield_many(
//         uint256[] calldata tokenIds,
//         uint128[] calldata amt0,
//         uint128[] calldata amt1
//     ) external {
//         unchecked {
//             uint256 size = tokenIds.length;
//             require(size == amt0.length && size == amt1.length, "L");
//             for (uint256 i; i < size; ) {
//                 withdraw_yield(tokenIds[i], amt0[i], amt1[i]);

//                 ++i;
//             }
//         }
//     }

//     function withdraw_referral_rewards(uint128 amount0) external {
//         // //console.log(msg.sender, "SENDER");
//         // //console.log(refBalances[msg.sender], "amt0Internal");
//         unchecked {
//             if (amount0 == 0) {
//                 amount0 = refBalances[msg.sender];
//                 refBalances[msg.sender] = 0;
//                 IERC20(WETH).transfer(msg.sender, amount0);
//             } else if (amount0 != 0) {
//                 if (amount0 > refBalances[msg.sender]) revert Max0();
//                 refBalances[msg.sender] -= amount0;
//                 IERC20(WETH).transfer(msg.sender, amount0);
//             }
//             // //console.log("after-WW-REF");
//             // //console.log(
//             //     IERC20(WETH).balanceOf(address(this)),
//             //     "balOfThis-ww-ref"
//             // );
//             // //console.log(
//             //     refBalances[msg.sender],
//             //     "REF_BALANCE-MAPPING-ww-ref"
//             // );
//             // //console.log("after-WW-REF");
//         }
//     }

//     //PROTOCOL LP
//     function buyback(
//         uint256 flag,
//         uint128 internalWETHAmt,
//         uint128 internalTokenAmt,
//         address to,
//         uint256 id
//     ) external returns (uint256 t0, uint256 t1) {
//         if (tx.origin != keeper && msg.sender != multiSig) revert Auth();

//         // for (uint256 i; i < ids.length; ) {
//         (t0, t1) = positionManager.collect(
//             INonfungiblePositionManager.CollectParams({
//                 tokenId: id,
//                 recipient: address(this),
//                 amount0Max: type(uint128).max,
//                 amount1Max: type(uint128).max
//             })
//         );
//         // //console.log(claimedTokens, "Claimed Tokens");
//         // //console.log(claimedWETH, "Claimed Weth");
//         // //console.log(flag, "ID");
//         if (
//             t0 > 1e15 ||
//             (balances[1].amount0 >= internalWETHAmt &&
//                 balances[1].amount1 >= internalTokenAmt)
//         ) {
//             unchecked {
//                 balances[1].amount0 += uint128(t0);
//                 balances[1].amount1 += uint128(t1);

//                 if (internalWETHAmt > balances[1].amount0) revert Max0();
//                 if (internalTokenAmt > balances[1].amount1) revert Max1();

//                 balances[1].amount0 -= internalWETHAmt;
//                 balances[1].amount1 -= internalTokenAmt;
//             }

//             if (internalTokenAmt != 0)
//                 IERC20(CTLS).transfer(multiSig, internalTokenAmt);

//             if (flag == 0) {
//                 try ctls(payable(CTLS)).flashReward() {} catch {} //lp reward only
//             } else if (flag == 1) {
//                 //buyback only
//                 uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
//                     IRouterV3.ExactInputSingleParams({
//                         tokenIn: WETH,
//                         tokenOut: CTLS,
//                         fee: 10000,
//                         recipient: to,
//                         deadline: block.timestamp,
//                         amountIn: internalWETHAmt, //flush all balance
//                         amountOutMinimum: 0,
//                         sqrtPriceLimitX96: 0
//                     })
//                 );
//                 emit BoughtBack(flag, internalWETHAmt, gotTokens);
//             } else if (flag == 2) {
//                 //buyback+lp reward
//                 IRouterV3(v3Router).exactInputSingle(
//                     IRouterV3.ExactInputSingleParams({
//                         tokenIn: WETH,
//                         tokenOut: CTLS,
//                         fee: 10000,
//                         recipient: to,
//                         deadline: block.timestamp,
//                         amountIn: internalWETHAmt / 2, //flush all balance
//                         amountOutMinimum: 0,
//                         sqrtPriceLimitX96: 0
//                     })
//                 );

//                 uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
//                     IRouterV3.ExactInputSingleParams({
//                         tokenIn: WETH,
//                         tokenOut: CTLS,
//                         fee: 10000,
//                         recipient: ctls(payable(CTLS)).getYieldBooster(),
//                         deadline: block.timestamp,
//                         amountIn: (internalWETHAmt - (internalWETHAmt / 2)),
//                         amountOutMinimum: 0,
//                         sqrtPriceLimitX96: 0
//                     })
//                 );
//                 emit BoughtBack(flag, internalWETHAmt, gotTokens);
//                 // claimedTokens += gotFromBuy;
//                 try ctls(payable(CTLS)).flashReward() {} catch {}
//             } else if (flag == 3) {
//                 //buyback + swapback + send rewards
//                 uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
//                     IRouterV3.ExactInputSingleParams({
//                         tokenIn: WETH,
//                         tokenOut: CTLS,
//                         fee: 10000,
//                         recipient: to,
//                         deadline: block.timestamp,
//                         amountIn: internalWETHAmt,
//                         amountOutMinimum: 0,
//                         sqrtPriceLimitX96: 0
//                     })
//                 );
//                 emit BoughtBack(flag, internalWETHAmt, gotTokens);
//                 try ctls(payable(CTLS)).swapBack() {} catch {}
//                 try ctls(payable(CTLS)).flashReward() {} catch {}
//             }
//         } else {
//             revert("c_n_e");
//         }
//     }

//     function _collectLPRewards(
//         uint256 tokenId
//     ) internal returns (uint128 c0, uint128 c1) {
//         (uint256 c0u, uint256 c1u) = positionManager.collect(
//             INonfungiblePositionManager.CollectParams({
//                 tokenId: tokenId,
//                 recipient: address(this),
//                 amount0Max: type(uint128).max,
//                 amount1Max: type(uint128).max
//             })
//         );

//         c0 = uint128(c0u);
//         c1 = uint128(c1u);
//     }

//     function _decreasePosition(
//         uint256 tokenId,
//         uint128 liquidity
//     ) internal returns (uint128 a0, uint128 a1) {
//         positionManager.decreaseLiquidity(
//             INonfungiblePositionManager.DecreaseLiquidityParams({
//                 tokenId: tokenId,
//                 liquidity: liquidity,
//                 amount0Min: 0,
//                 amount1Min: 0,
//                 deadline: block.timestamp
//             })
//         );

//         (a0, a1) = _collectLPRewards(tokenId);

//         // //console.log(a0, "usdcRemoved_lp_rew");
//         // //console.log(a1, "tokenRemoved_lp_rew");
//     }

//     function shiftPosition(
//         uint256 tokenId,
//         uint256 flag,
//         uint256 min0Out,
//         uint256 min1Out
//     ) external returns (uint256 newTokenId, uint256 min0, uint256 min1) {
//         address tokenOwner = positionManager.ownerOf(tokenId);
//         if (msg.sender != tokenOwner) revert Auth();
//         (, , uint128 liq) = this.getPosition(tokenId);
//         (uint128 WETHRemoved, uint128 tokensRemoved) = _decreasePosition(
//             tokenId,
//             liq
//         );

//         // //console.log(uint256(int256(-tick)), "CURRENT-TICK");
//         if (WETHRemoved > 1e6 && tokensRemoved >= 10e18) {
//             // //console.log(claimed0, "collected0");balances
//             // //console.log(claimed1, "collected1");

//             //Token Tax (3% TOTAL) [1.5% in WETH] [1.5% in TOKENS]
//             // uint128 pFee0 = WETHRemoved / 50;
//             // uint128 pFee1 = tokensRemoved / 50;
//             unchecked {
//                 // 15 / 100 = 15
//                 // 15 / 1000 = 1,5
//                 liq = WETHRemoved / 100;
//                 balances[1].amount0 += liq;
//                 balances[1].amount1 += tokensRemoved / 100;

//                 WETHRemoved -= liq * 2;
//                 tokensRemoved -= tokensRemoved / 100;

//                 //Referral 1%
//                 // WETHRemoved -= liq;
//             }

//             // //console.log(
//             //     ctls(payable(CTLS)).getUpperRef(tokenOwner),
//             //     "Get-upper-ref"
//             // );
//             // //console.log(tokenOwner, "owner-?-re  f");
//             {
//                 address upper = ctls(payable(CTLS)).getUpperRef(tokenOwner);
//                 upper == address(0)
//                     ? balances[1].amount0 += liq
//                     : refBalances[upper] += liq;
//                 //Determine Referal
//                 // refBalances[upper] = liq;
//                 // //console.log(
//                 //     refBalances[
//                 //         ctls(payable(CTLS)).getUpperRef(tokenOwner)
//                 //     ],
//                 //     "PENDING-REF"
//                 // );
//                 emit referralPaid(
//                     tokenOwner,
//                     upper == address(0) ? multiSig : upper,
//                     liq
//                 );
//             }

//             (newTokenId, min0, min1) = _mintPosition(
//                 WETHRemoved,
//                 tokensRemoved,
//                 flag,
//                 msg.sender,
//                 false,
//                 min0Out,
//                 min1Out
//             );

//             if (min0 > WETHRemoved) revert Max0();
//             if (min1 > tokensRemoved) revert Max1();
//             // require(a0 < WETHRemoved, "a0 > WETHRemoved");
//             // require(a1 < tokensRemoved, "a1 > tokensRemoved");
//             // //console.log(uint128(WETHRemoved - min0), "LEFTOVER-0");
//             // //console.log(uint128(tokensRemoved - min1), "LEFTOVER-1");
//             //leftovers
//             balances[newTokenId].amount0 += uint128(WETHRemoved - min0);
//             balances[newTokenId].amount1 += uint128(tokensRemoved - min1);

//             emit ShiftedPosition(tokenId, newTokenId, flag, min0, min1);
//             // IERC20(WETH).transfer(tokenOwner, WETHRemoved - min0);
//             // IERC20(CTLS).transfer(tokenOwner, tokensRemoved - min1);
//         } else {
//             revert("no_limit_orders");
//         }
//     }

//     function createLimitOrderPosition(
//         uint128 amount0Or1,
//         uint256 flag,
//         bool isToken0,
//         uint256 min0Or1Out
//     ) external returns (uint256 newTokenId, uint256 min0, uint256 min1) {
//         isToken0
//             ? IERC20(WETH).transferFrom(msg.sender, address(this), amount0Or1)
//             : IERC20(CTLS).transferFrom(msg.sender, address(this), amount0Or1);
//         unchecked {
//             uint128 pFee = amount0Or1 / 25;
//             uint128 rFee0 = amount0Or1 / 100;
//             amount0Or1 -= (pFee + rFee0);

//             isToken0
//                 ? balances[1].amount0 += pFee
//                 : balances[1].amount1 += pFee;

//             address upper = ctls(payable(CTLS)).getUpperRef(msg.sender);
//             //Determine Referal
//             upper == address(0)
//                 ? balances[1].amount0 += rFee0
//                 : refBalances[upper] += rFee0;
//             // //console.log(
//             //     refBalances[
//             //         ctls(payable(CTLS)).getUpperRef(tokenOwner)
//             //     ],
//             //     "PENDING-REF"
//             // );
//             emit referralPaid(
//                 msg.sender,
//                 upper == address(0) ? multiSig : upper,
//                 rFee0
//             );
//         }

//         (newTokenId, min0, min1) = _mintPosition(
//             isToken0 ? amount0Or1 : 0,
//             isToken0 ? 0 : amount0Or1,
//             flag,
//             msg.sender,
//             true,
//             isToken0 ? min0Or1Out : 0,
//             isToken0 ? 0 : min0Or1Out
//         );
//         // {
//         if (isToken0) {
//             _sendRefunds(amount0Or1 - min0, 0);
//         } else {
//             _sendRefunds(0, amount0Or1 - min1);
//         }
//         // }

//         // isToken0
//         //     ? IERC20(WETH).transfer(msg.sender, amount0Or1 - min0)
//         //     : IERC20(CTLS).transfer(msg.sender, amount0Or1 - min1);
//         emit limitOrderCreated(
//             msg.sender,
//             newTokenId,
//             flag,
//             isToken0 ? min0 : min1,
//             isToken0
//         );
//     }

//     function _sendRefunds(uint amount0, uint amount1) internal {
//         if (amount0 != 0) IERC20(WETH).transfer(msg.sender, amount0);
//         if (amount1 >= 1e15) IERC20(CTLS).transfer(msg.sender, amount1);
//     }

//     function createNomralPosition(
//         uint128 amount0,
//         uint128 amount1,
//         uint256 flag,
//         uint256 min0,
//         uint256 min1
//     )
//         external
//         returns (uint256 tokenId, uint256 amt0Consumed, uint256 amt1Consumed)
//     {
//         IERC20(WETH).transferFrom(msg.sender, address(this), amount0);
//         IERC20(CTLS).transferFrom(msg.sender, address(this), amount1);
//         {
//             uint128 pFee0 = amount0 / 50;
//             uint128 pFee1 = amount1 / 50;
//             uint128 rFee0 = amount0 / 100;
//             balances[1].amount0 += pFee0;
//             balances[1].amount1 += pFee1;

//             amount0 -= (pFee0 + rFee0);
//             amount1 -= pFee1;
//             //Referral Tax [0.5%]
//             // amount0 -= rFee0;
//             address upper = ctls(payable(CTLS)).getUpperRef(msg.sender);
//             upper == address(0)
//                 ? balances[1].amount0 += rFee0
//                 : refBalances[upper] += rFee0;
//             // //console.log(
//             //     refBalances[
//             //         ctls(payable(CTLS)).getUpperRef(tokenOwner)
//             //     ],
//             //     "PENDING-REF"
//             // );
//             emit referralPaid(
//                 msg.sender,
//                 upper == address(0) ? multiSig : upper,
//                 rFee0
//             );

//             (tokenId, amt0Consumed, amt1Consumed) = _mintPosition(
//                 amount0,
//                 amount1,
//                 flag,
//                 msg.sender,
//                 false,
//                 min0,
//                 min1
//             );

//             IERC20(WETH).transfer(msg.sender, amount0 - amt0Consumed);
//             IERC20(CTLS).transfer(msg.sender, amount1 - amt1Consumed);
//         }
//     }

//     function _mintPosition(
//         uint256 amt0Desired,
//         uint256 amt1Desired,
//         uint256 flag,
//         address to,
//         bool isLimit,
//         uint min0,
//         uint min1
//     )
//         internal
//         returns (uint256 tokenId, uint256 amt0Consumed, uint256 amt1Consumed)
//     {
//         int24 tick = this.getCurrentTick();
//         int24 tickDist = this.getTickDistance(flag);

//         if (!isLimit) {
//             (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
//                 INonfungiblePositionManager.MintParams({
//                     token0: WETH,
//                     token1: CTLS,
//                     fee: 10000,
//                     tickLower: tick - tickDist < int24(-887000)
//                         ? int24(-887000)
//                         : tick - tickDist,
//                     tickUpper: tick + tickDist > int24(887000)
//                         ? int24(887000)
//                         : tick + tickDist,
//                     amount0Desired: amt0Desired,
//                     amount1Desired: amt1Desired,
//                     amount0Min: min0,
//                     amount1Min: min1,
//                     recipient: to,
//                     deadline: block.timestamp
//                 })
//             );
//         } else {
//             // bool isToken0 = amt0Desired != 0;
//             // if (isToken0) {
//             //     require(amt1Desired == 0, "?");
//             // }
//             (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
//                 INonfungiblePositionManager.MintParams({
//                     token0: WETH,
//                     token1: CTLS,
//                     fee: 10000,
//                     tickLower: amt0Desired == 0 ? tick - tickDist : tick,
//                     tickUpper: amt0Desired == 0 ? tick : tick + tickDist,
//                     amount0Desired: amt0Desired,
//                     amount1Desired: amt1Desired,
//                     amount0Min: min0,
//                     amount1Min: min1,
//                     recipient: to,
//                     deadline: block.timestamp
//                 })
//             );
//         }

//         // //console.log(a0, "ACTUAL-POSITION-SIZE-0");
//         // //console.log(a1, "ACTUAL-POSITION-SIZE-1");

//         // //console.log(a0 / 1e18, "1e18_ACTUAL-POSITION-SIZE-0");
//         // //console.log(a1 / 1e18, "1e18_ACTUAL-POSITION-SIZE-1");
//     }

//     //GETTERS
//     function balanceOf(
//         uint256 tokenId
//     ) external view returns (uint128 balance0, uint128 balance1) {
//         balance0 = balances[tokenId].amount0;
//         balance1 = balances[tokenId].amount1;
//     }

//     function balanceOfReferal(
//         address who
//     ) external view returns (uint128 amount0) {
//         return refBalances[who];
//     }

//     function balanceOfMany(
//         uint256[] calldata tokenIds
//     )
//         external
//         view
//         returns (
//             uint128 balance0Total,
//             uint128 balance1Total,
//             uint256[] memory returnTokenIds,
//             uint128[] memory balances0,
//             uint128[] memory balances1
//         )
//     {
//         uint256 size = tokenIds.length;
//         balances0 = new uint128[](size);
//         balances1 = new uint128[](size);

//         unchecked {
//             for (uint256 i; i < size; ++i) {
//                 uint256 tokenId = tokenIds[i];
//                 uint128 bal0 = balances[tokenId].amount0;
//                 uint128 bal1 = balances[tokenId].amount1;

//                 balance0Total += bal0;
//                 balance1Total += bal1;

//                 balances0[i] = bal0;
//                 balances1[i] = bal1;
//             }
//         }

//         returnTokenIds = tokenIds;
//     }

//     function findPoolFee(
//         address token0,
//         address token1
//     ) public view returns (uint24 poolFee) {
//         address factory = IRouterV3(v3Router).factory();
//         uint128 highestLiq;
//         try IV3Factory(factory).getPool(token0, token1, 100) returns (
//             address pool100
//         ) {
//             // //console.log(pool100, "pool100");
//             if (pool100 != address(0)) {
//                 try IV3Pool(pool100).liquidity() returns (uint128 liq) {
//                     // //console.log("temp3");
//                     if (liq > highestLiq) {
//                         poolFee = 100;
//                         highestLiq = liq;
//                     }
//                 } catch {}
//             }
//         } catch {}
//         // //console.log(highestLiq, "HIGHEST LIQ 1");
//         try IV3Factory(factory).getPool(token0, token1, 500) returns (
//             address pool500
//         ) {
//             if (pool500 != address(0)) {
//                 try IV3Pool(pool500).liquidity() returns (uint128 liq) {
//                     // //console.log("temp3");
//                     if (liq > highestLiq) {
//                         poolFee = 500;
//                         highestLiq = liq;
//                     }
//                 } catch {}
//             }
//         } catch {}
//         // //console.log(highestLiq, "HIGHEST LIQ 2");
//         try IV3Factory(factory).getPool(token0, token1, 3000) returns (
//             address pool3000
//         ) {
//             if (pool3000 != address(0)) {
//                 try IV3Pool(pool3000).liquidity() returns (uint128 liq) {
//                     // //console.log("temp3");
//                     if (liq > highestLiq) {
//                         poolFee = 3000;
//                         highestLiq = liq;
//                     }
//                 } catch {}
//             }
//         } catch {}
//         // //console.log(highestLiq, "HIGHEST LIQ 3");

//         try IV3Factory(factory).getPool(token0, token1, 10000) returns (
//             address pool10000
//         ) {
//             if (pool10000 != address(0)) {
//                 try IV3Pool(pool10000).liquidity() returns (uint128 liq) {
//                     // //console.log("temp3");
//                     if (liq > highestLiq) {
//                         poolFee = 10000;
//                         highestLiq = liq;
//                     }
//                 } catch {}
//             }
//         } catch {}

//         // //console.log(highestLiq, "HIGHEST LIQ 4");
//     }

//     function getPosition(
//         uint256 tokenId
//     )
//         external
//         view
//         returns (address token0, address token1, uint128 liquidity)
//     {
//         (, , token0, token1, , , , liquidity, , , , ) = positionManager
//             .positions(tokenId);
//     }

//     function getDeviation(
//         uint256 amountIn,
//         uint256 startTickDeviation
//     ) external pure returns (uint256 adjusted) {
//         // //console.log(startTickDeviation, "DEVIATION%%%%%%");
//         adjusted = (amountIn * (10000 + startTickDeviation)) / 20000;
//     }

//     function getStartTickDeviation(
//         int24 currentTick
//     ) external pure returns (uint256 perc) {
//         int24 startTickDeviation;

//         if (currentTick > -106400) {
//             startTickDeviation = currentTick + -106400;
//         } else {
//             startTickDeviation = -106400 + currentTick;
//         }
//         //abs
//         if (startTickDeviation < 0) {
//             startTickDeviation = -startTickDeviation;
//         }
//         // //console.log(uint256(int256(currentTick)), "CURRENT_TICK");
//         // //console.log(uint256(int256(startTickDeviation)), "DEVIATION");
//         perc = (uint256(int256(startTickDeviation)) * 75) / 107400;
//     }

//     function getCurrentTick() external view returns (int24 cTick) {
//         (, cTick, , , , , ) = IV3Pool(uniswapV3Pool).slot0();
//         cTick = (cTick / 200) * 200;
//     }

//     function getTickDistance(
//         uint256 flag
//     ) external pure returns (int24 tickDistance) {
//         if (flag == 0) {
//             //default
//             tickDistance = 30000;
//         } else if (flag == 1) {
//             tickDistance = 20000;
//         } else if (flag == 2) {
//             tickDistance = 10000;
//         } else if (flag == 3) {
//             tickDistance = 5000;
//         } else if (flag == 4) {
//             tickDistance = 2000;
//         } else {
//             revert("invalid_flag");
//         }
//     }

//     function findApprovalToken(
//         address pool
//     ) external view returns (address token) {
//         return
//             this.findApprovalToken(
//                 IV3Pool(pool).token0(),
//                 IV3Pool(pool).token1()
//             );
//     }

//     function findApprovalToken(
//         address token0,
//         address token1
//     ) external view returns (address token) {
//         require(token0 == WETH || token1 == WETH, "Not WETH Pair");
//         token = token0 == WETH ? token1 : token0;
//         if (token == CTLS || token == WETH) {
//             token = address(0);
//         }
//     }
// }

// contract QueryHelper {
//     INonfungiblePositionManager internal immutable
//     positionManager = INonfungiblePositionManager(
//             0xC36442b4a4522E871399CD717aBDD847Ab11FE88
//         );
//     function getManyPosition(
//         uint[] calldata tokenId
//     )
//         external
//         view
//         returns (
//             address[] memory token0,
//             address[] memory token1,
//             uint128[] memory liquidity,
//             int24[] memory lower,
//             int24[] memory upper,
//             uint24[] memory fee,
//             uint256[] memory amount0,
//             uint256[] memory amount1
//         )
//     {
//         token0 = new address[](tokenId.length);
//         token1 = new address[](tokenId.length);
//         liquidity = new uint128[](tokenId.length);
//         unchecked {
//             for (uint i; i < tokenId.length; ++i) {
//                 (
//                     ,
//                     ,
//                     token0[i],
//                     token1[i],
//                     fee[i],
//                     lower[i],
//                     upper[i],
//                     liquidity[i],
//                     ,
//                     ,
//                     ,

//                 ) = positionManager.positions(tokenId[i]);
//                 (, int24 cTick, , , , , ) = IV3Pool(IV3Factory(positionManager.factory()).getPool(token0[i], token1[i], fee[i])).slot0();
//                 (amount0[i], amount1[i]) = LiquidityAmounts
//                     .getAmountsForLiquidity(
//                         TickMath.getSqrtRatioAtTick(cTick),
//                         TickMath.getSqrtRatioAtTick(lower[i]),
//                         TickMath.getSqrtRatioAtTick(upper[i]),
//                         liquidity[i]
//                     );
//             }
//         }
//     }
// }

// function zapFromV2LPToken(
//     address fromToken,
//     uint256 amountIn,
//     uint128 minOut,
//     uint128 minOut2,
//     uint256 flag,
//     address ref
// ) external returns (uint256 tokenId) {
//     fromToken.call(
//         abi.encodeWithSelector(
//             IERC20.transferFrom.selector,
//             msg.sender,
//             fromToken,
//             amountIn
//         )
//     );

//     bool isToken0Weth = IV2Pair(fromToken).token0() == WETH;

//     (uint256 removed0, uint256 removed1) = IV2Pair(fromToken).burn(
//         address(this)
//     );
//     uint256 bef = address(this).balance;
//     uint256 finalAmt = isToken0Weth ? removed0 : removed1;
//     address _weth = WETH;

//     //withdraw weth
//     assembly {
//         let inputMem := mload(0x40)
//         mstore(
//             inputMem,
//             0x2e1a7d4d00000000000000000000000000000000000000000000000000000000
//         )
//         mstore(add(inputMem, 0x04), finalAmt)
//         pop(call(gas(), _weth, 0, inputMem, 0x24, 0, 0))
//     }
//     finalAmt = isToken0Weth ? removed1 : removed0;
//     _weth = IV3Pool(fromToken).token0();
//     address approvalToken = YIELD_VAULT.findApprovalToken(fromToken);
//     if (approvalToken != address(0)) {
//         approvalToken.call(
//             abi.encodeWithSelector(
//                 IERC20.approve.selector,
//                 address(router),
//                 amountIn
//             )
//         );
//     }

//     address[] memory path2 = new address[](2);
//     path2[0] = approvalToken;
//     path2[1] = WETH;
//     router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//         finalAmt,
//         minOut,
//         path2,
//         address(this),
//         block.timestamp
//     );

//     tokenId = this.zapFromETH{value: address(this).balance - bef}(
//         minOut2,
//         msg.sender,
//         flag,
//         ref
//     );
// }
// function zapFromToken(
//     address fromToken,
//     uint256 amountIn,
//     uint256 minOut,
//     uint256 minOut2,
//     bool isV2,
//     uint24 poolFee,
//     uint256 flag,
//     address ref
// ) external returns (uint256 tokenId) {
//     address _weth = WETH;

//     if (fromToken == WETH) {
//         fromToken.call(
//             abi.encodeWithSelector(
//                 IERC20.transferFrom.selector,
//                 msg.sender,
//                 address(this),
//                 amountIn
//             )
//         );
//         assembly {
//             let inputMem := mload(0x40)
//             mstore(
//                 inputMem,
//                 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000
//             )
//             mstore(add(inputMem, 0x04), amountIn)
//             pop(call(gas(), _weth, 0, inputMem, 0x24, 0, 0))
//         }
//         return
//             this.zapFromETH{value: amountIn}(
//                 minOut2,
//                 msg.sender,
//                 flag,
//                 ref
//             );
//     }

//     fromToken.call(
//         abi.encodeWithSelector(
//             IERC20.transferFrom.selector,
//             msg.sender,
//             address(this),
//             amountIn
//         )
//     );

//     if (isV2) {
//         if (fromToken != address(this) && fromToken != WETH) {
//             fromToken.call(
//                 abi.encodeWithSelector(
//                     IERC20.approve.selector,
//                     address(router),
//                     amountIn
//                 )
//             );
//         }
//         uint256 bef = address(this).balance;
//         address[] memory path2 = new address[](2);
//         path2[0] = fromToken;
//         path2[1] = WETH;
//         router.swapExactTokensForETHSupportingFeeOnTransferTokens(
//             amountIn,
//             minOut,
//             path2,
//             address(this),
//             block.timestamp
//         );
//         return
//             this.zapFromETH{value: address(this).balance - bef}(
//                 minOut2,
//                 msg.sender,
//                 flag,
//                 ref
//             );
//     } else {
//         if (fromToken != address(this) && fromToken != WETH) {
//             fromToken.call(
//                 abi.encodeWithSelector(
//                     IERC20.approve.selector,
//                     v3Router,
//                     amountIn
//                 )
//             );
//         }
//         uint256 gotOut = IRouterV3(v3Router).exactInputSingle(
//             IRouterV3.ExactInputSingleParams({
//                 tokenIn: fromToken,
//                 tokenOut: WETH,
//                 fee: poolFee,
//                 recipient: address(this),
//                 deadline: block.timestamp,
//                 amountIn: amountIn,
//                 amountOutMinimum: minOut,
//                 sqrtPriceLimitX96: 0
//             })
//         );
//         assembly {
//             let inputMem := mload(0x40)
//             mstore(
//                 inputMem,
//                 0x2e1a7d4d00000000000000000000000000000000000000000000000000000000
//             )
//             mstore(add(inputMem, 0x04), gotOut)
//             pop(call(gas(), _weth, 0, inputMem, 0x24, 0, 0))
//         }
//         return
//             this.zapFromETH{value: gotOut}(minOut2, msg.sender, flag, ref);
//     }
// }