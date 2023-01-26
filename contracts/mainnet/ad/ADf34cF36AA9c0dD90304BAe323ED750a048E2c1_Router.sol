// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../core/interfaces/ISwapFactory.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/Math.sol";
import "../core/interfaces/ISwapPair.sol";

contract Router {
  struct route {
    address from;
    address to;
    bool stable;
  }

  address public immutable factory;
  IWETH public immutable weth;
  uint internal constant MINIMUM_LIQUIDITY = 10 ** 3;
  bytes32 immutable pairCodeHash;

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, "BaseV1Router: EXPIRED");
    _;
  }

  constructor(address _factory, address _weth) {
    require(_factory != address(0) && _weth != address(0), "Router: zero address provided in constructor");
    factory = _factory;
    pairCodeHash = ISwapFactory(_factory).pairCodeHash();
    weth = IWETH(_weth);
  }

  receive() external payable {
    assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
  }

  function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
    require(tokenA != tokenB, "BaseV1Router: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "BaseV1Router: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1, stable)),
              pairCodeHash // init code hash
            )
          )
        )
      )
    );
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, "BaseV1Router: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "BaseV1Router: INSUFFICIENT_LIQUIDITY");
    amountB = (amountA * reserveB) / reserveA;
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address tokenA, address tokenB, bool stable) public view returns (uint reserveA, uint reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1, ) = ISwapPair(pairFor(tokenA, tokenB, stable)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountOut(
    uint amountIn,
    address tokenIn,
    address tokenOut
  ) public view returns (uint amount, bool stable) {
    address pair = pairFor(tokenIn, tokenOut, true);
    uint amountStable;
    uint amountVolatile;
    if (ISwapFactory(factory).isPair(pair)) {
      amountStable = ISwapPair(pair).getAmountOut(amountIn, tokenIn);
    }
    pair = pairFor(tokenIn, tokenOut, false);
    if (ISwapFactory(factory).isPair(pair)) {
      amountVolatile = ISwapPair(pair).getAmountOut(amountIn, tokenIn);
    }
    return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
    require(routes.length >= 1, "BaseV1Router: INVALID_PATH");
    amounts = new uint[](routes.length + 1);
    amounts[0] = amountIn;
    for (uint i = 0; i < routes.length; i++) {
      address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable);
      if (ISwapFactory(factory).isPair(pair)) {
        amounts[i + 1] = ISwapPair(pair).getAmountOut(amounts[i], routes[i].from);
      }
    }
  }

  function isPair(address pair) external view returns (bool) {
    return ISwapFactory(factory).isPair(pair);
  }

  function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity) {
    // create the pair if it doesn't exist yet
    address _pair = ISwapFactory(factory).getPair(tokenA, tokenB, stable);
    (uint reserveA, uint reserveB) = (0, 0);
    uint _totalSupply = 0;
    if (_pair != address(0)) {
      _totalSupply = IERC20(_pair).totalSupply();
      (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
    }
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
      liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
    } else {
      uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
        liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
      } else {
        uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
        (amountA, amountB) = (amountAOptimal, amountBDesired);
        liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
      }
    }
  }

  function quoteRemoveLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity
  ) external view returns (uint amountA, uint amountB) {
    // create the pair if it doesn't exist yet
    address _pair = ISwapFactory(factory).getPair(tokenA, tokenB, stable);

    if (_pair == address(0)) {
      return (0, 0);
    }

    (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
    uint _totalSupply = IERC20(_pair).totalSupply();

    amountA = (liquidity * reserveA) / _totalSupply; // using balances ensures pro-rata distribution
    amountB = (liquidity * reserveB) / _totalSupply; // using balances ensures pro-rata distribution
  }

  function _addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin
  ) internal returns (uint amountA, uint amountB) {
    require(amountADesired >= amountAMin);
    require(amountBDesired >= amountBMin);
    // create the pair if it doesn't exist yet
    address _pair = ISwapFactory(factory).getPair(tokenA, tokenB, stable);
    if (_pair == address(0)) {
      _pair = ISwapFactory(factory).createPair(tokenA, tokenB, stable);
    }
    (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
      if (amountBOptimal <= amountBDesired) {
        require(amountBOptimal >= amountBMin, "BaseV1Router: INSUFFICIENT_B_AMOUNT");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
        assert(amountAOptimal <= amountADesired);
        require(amountAOptimal >= amountAMin, "BaseV1Router: INSUFFICIENT_A_AMOUNT");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = pairFor(tokenA, tokenB, stable);
    _safeTransferFrom(tokenA, msg.sender, pair, amountA);
    _safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = ISwapPair(pair).mint(to);
  }

  function addLiquidityETH(
    address token,
    bool stable,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
    (amountToken, amountETH) = _addLiquidity(
      token,
      address(weth),
      stable,
      amountTokenDesired,
      msg.value,
      amountTokenMin,
      amountETHMin
    );
    address pair = pairFor(token, address(weth), stable);
    _safeTransferFrom(token, msg.sender, pair, amountToken);
    weth.deposit{ value: amountETH }();
    assert(weth.transfer(pair, amountETH));
    liquidity = ISwapPair(pair).mint(to);
    // refund dust eth, if any
    if (msg.value > amountETH) _safeTransferETH(msg.sender, msg.value - amountETH);
  }

  // **** REMOVE LIQUIDITY ****
  function removeLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) public ensure(deadline) returns (uint amountA, uint amountB) {
    address pair = pairFor(tokenA, tokenB, stable);
    require(ISwapPair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
    (uint amount0, uint amount1) = ISwapPair(pair).burn(to);
    (address token0, ) = sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "BaseV1Router: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "BaseV1Router: INSUFFICIENT_B_AMOUNT");
  }

  function removeLiquidityETH(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
    (amountToken, amountETH) = removeLiquidity(
      token,
      address(weth),
      stable,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    _safeTransfer(token, to, amountToken);
    weth.withdraw(amountETH);
    _safeTransferETH(to, amountETH);
  }

  // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens)****
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) public ensure(deadline) returns (uint amountToken, uint amountETH) {
    (amountToken, amountETH) = removeLiquidity(
      token,
      address(weth),
      stable,
      liquidity,
      amountTokenMin,
      amountETHMin,
      address(this),
      deadline
    );
    _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
    weth.withdraw(amountETH);
    _safeTransferETH(to, amountETH);
  }

  function removeLiquidityETHWithPermit(
    address token,
    bool stable,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH) {
    address pair = pairFor(token, address(weth), stable);
    uint value = approveMax ? type(uint).max : liquidity;
    ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(token, stable, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }

  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, route[] memory routes, address _to) internal virtual {
    for (uint i = 0; i < routes.length; i++) {
      (address token0, ) = sortTokens(routes[i].from, routes[i].to);
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < routes.length - 1 ? pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      ISwapPair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSimple(
    uint amountIn,
    uint amountOutMin,
    address tokenFrom,
    address tokenTo,
    bool stable,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    route[] memory routes = new route[](1);
    routes[0].from = tokenFrom;
    routes[0].to = tokenTo;
    routes[0].stable = stable;
    require(
      ISwapFactory(factory).isPair(pairFor(routes[0].from, routes[0].to, routes[0].stable)),
      "Pair has not been created"
    );
    amounts = getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, to);
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    require(
      ISwapFactory(factory).isPair(pairFor(routes[0].from, routes[0].to, routes[0].stable)),
      "Pair has not been created"
    );
    amounts = getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, to);
  }

  function swapExactETHForTokens(
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external payable ensure(deadline) returns (uint[] memory amounts) {
    require(
      ISwapFactory(factory).isPair(pairFor(routes[0].from, routes[0].to, routes[0].stable)),
      "Pair has not been created"
    );
    require(routes[0].from == address(weth), "BaseV1Router: INVALID_PATH");
    amounts = getAmountsOut(msg.value, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    weth.deposit{ value: amounts[0] }();
    assert(weth.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
    _swap(amounts, routes, to);
  }

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    require(
      ISwapFactory(factory).isPair(pairFor(routes[0].from, routes[0].to, routes[0].stable)),
      "Pair has not been created"
    );
    require(routes[routes.length - 1].to == address(weth), "BaseV1Router: INVALID_PATH");
    amounts = getAmountsOut(amountIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, address(this));
    weth.withdraw(amounts[amounts.length - 1]);
    _safeTransferETH(to, amounts[amounts.length - 1]);
  }

  function UNSAFE_swapExactTokensForTokens(
    uint[] memory amounts,
    route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory) {
    require(
      ISwapFactory(factory).isPair(pairFor(routes[0].from, routes[0].to, routes[0].stable)),
      "Pair has not been created"
    );
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
    _swap(amounts, routes, to);
    return amounts;
  }

  function _safeTransferETH(address to, uint value) internal {
    (bool success, ) = to.call{ value: value }(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }

  function _safeTransfer(address token, address to, uint256 value) internal {
    require(token.code.length > 0);
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
    require(token.code.length > 0);
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))));
  }

  // **** SWAP (supporting fee-on-transfer tokens) ****
  function _swapSupportingFeeOnTransferTokens(route[] calldata routes, address _to) internal virtual {
    for (uint i; i < routes.length; i++) {
      (address input, address output) = (routes[i].from, routes[i].to);
      (address token0, ) = sortTokens(input, output);
      ISwapPair pair = ISwapPair(pairFor(routes[i].from, routes[i].to, routes[i].stable));
      uint amountInput;
      uint amountOutput;
      {
        // scope to avoid stack too deep errors
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint reserveInput, ) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        (amountOutput, ) = getAmountOut(amountInput, input, output);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < routes.length - 1 ? pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) {
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn);
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - (balanceBefore) >= amountOutMin,
      "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external payable ensure(deadline) {
    require(routes[0].from == address(weth), "BaseV1Router: INVALID_PATH");
    uint amountIn = msg.value;
    weth.deposit{ value: amountIn }();
    assert(weth.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn));
    uint balanceBefore = IERC20(routes[routes.length - 1].to).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(routes, to);
    require(
      IERC20(routes[routes.length - 1].to).balanceOf(to) - (balanceBefore) >= amountOutMin,
      "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT"
    );
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) {
    require(routes[routes.length - 1].to == address(weth), "BaseV1Router: INVALID_PATH");
    _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountIn);
    _swapSupportingFeeOnTransferTokens(routes, address(this));
    uint amountOut = IERC20(address(weth)).balanceOf(address(this));
    require(amountOut >= amountOutMin, "BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT");
    weth.withdraw(amountOut);
    _safeTransferETH(to, amountOut);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function fee(bool stable) external view returns (uint);
    function feeCollector() external view returns (address);
    function setFeeTier(bool stable, uint fee) external;
    function admin() external view returns (address);
    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title WETH9 Interface
/// @author Ricsson W. Ngo
interface IWETH is IERC20 {
    /* ===== UPDATE ===== */

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library Math {
    
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ISwapPair {
  function transferFrom(
    address src,
    address dst,
    uint256 amount
  ) external returns (bool);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function mint(address to) external returns (uint256 liquidity);

  function getReserves()
    external
    view
    returns (
      uint112 _reserve0,
      uint112 _reserve1,
      uint32 _blockTimestampLast
    );

  function getAmountOut(uint256, address) external view returns (uint256);

  function claimFees() external returns (uint256, uint256);

  function tokens() external view returns (address, address);

  function claimable0(address _account) external view returns (uint256);

  function claimable1(address _account) external view returns (uint256);

  function index0() external view returns (uint256);

  function index1() external view returns (uint256);

  function balanceOf(address _account) external view returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);

  function reserve0() external view returns (uint256);

  function reserve1() external view returns (uint256);

  function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);

  function currentCumulativePrices()
    external
    view
    returns (
      uint256 reserve0Cumulative,
      uint256 reserve1Cumulative,
      uint256 blockTimestamp
    );

  function sample(
    address tokenIn,
    uint256 amountIn,
    uint256 points,
    uint256 window
  ) external view returns (uint256[] memory);

  function quote(
    address tokenIn,
    uint256 amountIn,
    uint256 granularity
  ) external view returns (uint256 amountOut);

  function stable() external view returns (bool);

  function skim(address to) external;
}