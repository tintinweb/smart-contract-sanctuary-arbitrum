// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";
import {IRouterUniV2} from "./interfaces/IRouterUniV2.sol";
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

    constructor() {
        exec[msg.sender] = true;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from './interfaces/IERC20.sol';

contract Util {
    error Paused();
    error Unauthorized();
    error TransferFailed();

    bool public paused;
    mapping(address => bool) public exec;

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

    function pull(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function push(IERC20 asset, address usr, uint256 amt) internal {
        if (!asset.transfer(usr, amt)) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
pragma solidity 0.8.15;

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
pragma solidity 0.8.15;

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

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity 0.8.15;

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