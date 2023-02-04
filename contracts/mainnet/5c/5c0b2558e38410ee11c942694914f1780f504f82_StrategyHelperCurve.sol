// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IRouterUniV2} from "./interfaces/IRouterUniV2.sol";
import {IBalancerVault} from "./interfaces/IBalancerVault.sol";
import {IKyberRouter} from "./interfaces/IKyberRouter.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {Util} from "./Util.sol";
import {BytesLib} from "./vendor/BytesLib.sol";

interface IStrategyHelperVenue {
    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external;
}

contract StrategyHelper is Util {
    error UnknownPath();
    error UnknownOracle();

    struct Path {
        address venue;
        bytes path;
    }

    mapping(address => address) public oracles;
    mapping(address => mapping(address => Path)) public paths;

    event SetOracle(address indexed ast, address indexed oracle);
    event SetPath(address indexed ast0, address indexed ast1, address venue, bytes path);
    event FileAddress(bytes32 indexed what, address data);

    constructor() {
        exec[msg.sender] = true;
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") exec[data] = !exec[data];
        emit FileAddress(what, data);
    }

    function setOracle(address ast, address oracle) external auth {
        oracles[ast] = oracle;
        emit SetOracle(ast, oracle);
    }

    function setPath(address ast0, address ast1, address venue, bytes calldata path) external auth {
        Path storage p = paths[ast0][ast1];
        p.venue = venue;
        p.path = path;
        emit SetPath(ast0, ast1, venue, path);
    }

    function price(address ast) public view returns (uint256) {
        IOracle oracle = IOracle(oracles[ast]);
        if (address(oracle) == address(0)) revert UnknownOracle();
        return uint256(oracle.latestAnswer()) * 1e18 / (10 ** oracle.decimals());
    }

    function value(address ast, uint256 amt) public view returns (uint256) {
        return amt * price(ast) / (10 ** IERC20(ast).decimals());
    }

    function convert(address ast0, address ast1, uint256 amt) public view returns (uint256) {
        return value(ast0, amt) * (10 ** IERC20(ast1).decimals()) / price(ast1);
    }

    function swap(address ast0, address ast1, uint256 amt, uint256 slp, address to) external returns (uint256) {
        if (amt == 0) return 0;
        if (ast0 == ast1) {
          if (!IERC20(ast0).transferFrom(msg.sender, to, amt)) revert TransferFailed();
          return amt;
        }
        Path memory path = paths[ast0][ast1];
        if (path.venue == address(0)) revert UnknownPath();
        if (!IERC20(ast0).transferFrom(msg.sender, path.venue, amt)) revert TransferFailed();
        uint256 min = convert(ast0, ast1, amt) * (10000 - slp) / 10000;
        uint256 before = IERC20(ast1).balanceOf(to);
        IStrategyHelperVenue(path.venue).swap(ast0, path.path, amt, min, to);
        return IERC20(ast1).balanceOf(to) - before;
    }
}

contract StrategyHelperUniswapV2 {
    IRouterUniV2 router;

    constructor(address _router) {
        router = IRouterUniV2(_router);
    }

    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external {
        IERC20(ast).approve(address(router), amt);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amt,
            min, 
            parsePath(path),
            to,
            type(uint256).max
        );
    }

    function parsePath(bytes memory path) internal pure returns (address[] memory) {
        uint256 size = path.length / 20;
        address[] memory p = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            p[i] = address(uint160(bytes20(BytesLib.slice(path, i * 20, 20))));
        }
        return p;
    }
}

contract StrategyHelperUniswapV3 {
    ISwapRouter router;

    constructor(address _router) {
        router = ISwapRouter(_router);
    }

    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external {
        IERC20(ast).approve(address(router), amt);
        router.exactInput(ISwapRouter.ExactInputParams({
            path: path,
            recipient: to,
            deadline: type(uint256).max,
            amountIn: amt,
            amountOutMinimum: min
        }));
    }
}

contract StrategyHelperBalancer {
    IBalancerVault vault;

    constructor(address _vault) {
        vault = IBalancerVault(_vault);
    }

    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external {
        (address out, bytes32 poolId) = abi.decode(path, (address, bytes32));
        IERC20(ast).approve(address(vault), amt);
        vault.swap(
            IBalancerVault.SingleSwap({
                poolId: poolId,
                kind: 0,
                assetIn: ast,
                assetOut: out,
                amount: amt,
                userData: ""
            }),
            IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(to),
                toInternalBalance: false
            }),
            min,
            type(uint256).max
        );
    }
}

contract StrategyHelperKyber {
    IKyberRouter router;

    constructor(address _router) {
        router = IKyberRouter(_router);
    }

    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external {
        IERC20(ast).approve(address(router), amt);
        router.swapExactInput(IKyberRouter.ExactInputParams({
            path: path,
            recipient: to,
            deadline: type(uint256).max,
            amountIn: amt,
            minAmountOut: min
        }));
    }
}

contract StrategyHelperCurve {
    error UnderAmountMin();

    IWETH public weth;

    constructor(address _weth) {
        weth = IWETH(_weth);
    }

    receive() external payable {}

    function swap(address ast, bytes calldata path, uint256 amt, uint256 min, address to) external {
        address lastToken = ast;
        uint256 lastAmount = amt;
        (address[] memory pools, uint256[] memory coinsIn, uint256[] memory coinsOut) = abi.decode(
            path, (address[], uint256[], uint256[]));
        for (uint256 i = 0; i < pools.length; i++) {
            ICurvePool pool = ICurvePool(pools[i]);
            uint256 coinIn = coinsIn[i];
            uint256 coinOut = coinsOut[i];
            address tokenIn = pool.coins(coinIn);
            uint256 value = 0;
            if (tokenIn == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && lastToken == address(weth)) {
              weth.withdraw(lastAmount);
              value = lastAmount;
            } else {
              IERC20(tokenIn).approve(address(pool), lastAmount);
            }
            try pool.exchange{value: value}(coinIn, coinOut, lastAmount, 0) {} catch {
                pool.exchange{value: value}(
                    int128(uint128(coinIn)), int128(uint128(coinOut)), lastAmount, 0);
            }
            lastToken = pool.coins(coinOut);
            if (lastToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                lastToken = address(weth);
                weth.deposit{value: address(this).balance}();
            }
            lastAmount = IERC20(lastToken).balanceOf(address(this));
        }
        if (lastAmount < min) revert UnderAmountMin();
        IERC20(lastToken).transfer(to, lastAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from './interfaces/IERC20.sol';

contract Util {
    error Paused();
    error NoReentering();
    error Unauthorized();
    error TransferFailed();

    bool internal entered;
    bool public paused;
    mapping(address => bool) public exec;

    modifier loop() {
        if (entered) revert NoReentering();
        entered = true;
        _;
        entered = false;
    }

    modifier live() {
        if (paused) revert Paused();
        _;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // from OZ SignedMath
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            return uint256(n >= 0 ? n : -n);
        }
    }

    // from OZ Math
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 result = 1 << (log2(a) >> 1);
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) { value >>= 128; result += 128; }
            if (value >> 64 > 0) { value >>= 64; result += 64; }
            if (value >> 32 > 0) { value >>= 32; result += 32; }
            if (value >> 16 > 0) { value >>= 16; result += 16; }
            if (value >> 8 > 0) { value >>= 8; result += 8; }
            if (value >> 4 > 0) { value >>= 4; result += 4; }
            if (value >> 2 > 0) { value >>= 2; result += 2; }
            if (value >> 1 > 0) { result += 1; }
        }
        return result;
    }

    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 1e18;
        if (x == 0) return 0;
        require(x >> 255 == 0, "xoob");
        int256 x_int256 = int256(x);
        require(y < uint256(2**254) / 1e20, "yoob");
        int256 y_int256 = int256(y);
        int256 logx_times_y = _ln(x_int256) * y_int256 / 1e18;
        require(-41e18 <= logx_times_y && logx_times_y <= 130e18, "poob");
        return uint256(_exp(logx_times_y));
    }

    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    function _ln(int256 a) private pure returns (int256) {
        if (a < 1e18) return -_ln((1e18*1e18) / a);
        int256 sum = 0;
        if (a >= a0 * 1e18) { a /= a0; sum += x0; }
        if (a >= a1 * 1e18) { a /= a1; sum += x1; }
        sum *= 100;
        a *= 100;
        if (a >= a2) { a = (a * 1e20) / a2; sum += x2; }
        if (a >= a3) { a = (a * 1e20) / a3; sum += x3; }
        if (a >= a4) { a = (a * 1e20) / a4; sum += x4; }
        if (a >= a5) { a = (a * 1e20) / a5; sum += x5; }
        if (a >= a6) { a = (a * 1e20) / a6; sum += x6; }
        if (a >= a7) { a = (a * 1e20) / a7; sum += x7; }
        if (a >= a8) { a = (a * 1e20) / a8; sum += x8; }
        if (a >= a9) { a = (a * 1e20) / a9; sum += x9; }
        if (a >= a10) { a = (a * 1e20) / a10; sum += x10; }
        if (a >= a11) { a = (a * 1e20) / a11; sum += x11; }
        int256 z = ((a - 1e20) * 1e20) / (a + 1e20);
        int256 z_squared = (z * z) / 1e20;
        int256 num = z;
        int256 seriesSum = num;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 3;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 5;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 7;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 9;
        num = (num * z_squared) / 1e20;
        seriesSum += num / 11;
        seriesSum *= 2;
        return (sum + seriesSum) / 100;
    }

    function _exp(int256 x) internal pure returns (int256) {
        require(x >= -41e18 && x <= 130e18, "ie");
        if (x < 0) { return ((1e18 * 1e18) / _exp(-x)); }
        int256 firstAN;
        if (x >= x0) { x -= x0; firstAN = a0; }
        else if (x >= x1) { x -= x1; firstAN = a1; }
        else { firstAN = 1; }
        x *= 100;
        int256 product = 1e20;
        if (x >= x2) { x -= x2; product = (product * a2) / 1e20; }
        if (x >= x3) { x -= x3; product = (product * a3) / 1e20; }
        if (x >= x4) { x -= x4; product = (product * a4) / 1e20; }
        if (x >= x5) { x -= x5; product = (product * a5) / 1e20; }
        if (x >= x6) { x -= x6; product = (product * a6) / 1e20; }
        if (x >= x7) { x -= x7; product = (product * a7) / 1e20; }
        if (x >= x8) { x -= x8; product = (product * a8) / 1e20; }
        if (x >= x9) { x -= x9; product = (product * a9) / 1e20; }
        int256 seriesSum = 1e20;
        int256 term;
        term = x;
        seriesSum += term;
        term = ((term * x) / 1e20) / 2;
        seriesSum += term;
        term = ((term * x) / 1e20) / 3;
        seriesSum += term;
        term = ((term * x) / 1e20) / 4;
        seriesSum += term;
        term = ((term * x) / 1e20) / 5;
        seriesSum += term;
        term = ((term * x) / 1e20) / 6;
        seriesSum += term;
        term = ((term * x) / 1e20) / 7;
        seriesSum += term;
        term = ((term * x) / 1e20) / 8;
        seriesSum += term;
        term = ((term * x) / 1e20) / 9;
        seriesSum += term;
        term = ((term * x) / 1e20) / 10;
        seriesSum += term;
        term = ((term * x) / 1e20) / 11;
        seriesSum += term;
        term = ((term * x) / 1e20) / 12;
        seriesSum += term;
        return (((product * seriesSum) / 1e20) * firstAN) / 100;
    }

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function pullTo(IERC20 asset, address usr, address to, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transferFrom(usr, to, amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (amt == 0) return;
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }

    function emergencyForTesting(address target, uint256 value, bytes calldata data) external auth {
        target.call{value: value}(data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerVault {
    function getPoolTokens(bytes32) external view returns (address[] memory, uint256[] memory, uint256);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        uint8 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 minDy) external payable;
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IKyberRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    function swapExactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    function swapExactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRouterUniV2 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

pragma abicoder v2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.17;

library BytesLib {
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}