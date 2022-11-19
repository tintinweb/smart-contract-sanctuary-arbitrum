// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "../core/interfaces/ISwapPair.sol";
import "../core/interfaces/ISwapFactory.sol";
import "../periphery/interfaces/IWETH.sol";
import "../periphery/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add stable pools

interface IUniswapV2Factory {
  function pairCodeHash() external pure returns (bytes32);
}

interface ISwapRouter {
  function pairFor(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (address pair);

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 amountA,
    uint256 amountB,
    uint256 amountMinA,
    uint256 amountMinB,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 a,
      uint256 b,
      uint256 l
    );

  function getReserves(
    address tokenA,
    address tokenB,
    bool stable
  ) external view returns (uint256 reserveA, uint256 reserveB);

  function quoteLiquidity(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
}

interface IZap {
  function zapIn(
    address _token,
    uint256 _amount,
    address _pool,
    uint256 _minPoolTokens,
    bytes memory _swapData,
    address to
  ) external payable returns (uint256 poolTokens);
}

contract Migrate {
  //using SafeMath for uint256;

  address public immutable router;
  address public immutable zap;
  address public immutable factory;
  address public immutable sushiFactory;

  constructor(
    address _sushiFactory,
    address _router,
    address _zap,
    address _factory
  ) {
    router = _router;
    zap = _zap;
    factory = _factory;
    sushiFactory = _sushiFactory;
  }

  function migratePair(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 liquidityOut,
    uint256 minPoolTokens,
    uint256 deadline,
    address to
  ) public returns (uint256 finalPoolTokens) {
    address pair = ISwapRouter(router).pairFor(tokenA, tokenB, stable);
    (uint256 amountA, uint256 amountB) = removeLiquidity(tokenA, tokenB, liquidityOut, 0, 0);

    (uint256 pooledAmountA, uint256 pooledAmountB, uint256 liquidity) = addLiquidity(
      tokenA,
      tokenB,
      stable,
      amountA,
      amountB,
      to,
      deadline
    );

    finalPoolTokens += liquidity;

    if (amountA > pooledAmountA) {
      IERC20(tokenA).approve(zap, amountA - pooledAmountA);
      finalPoolTokens += IZap(zap).zapIn(tokenA, amountA - pooledAmountA, pair, 0, new bytes(0), to);
    }

    if (amountB > pooledAmountB) {
      IERC20(tokenB).approve(zap, amountB - pooledAmountB);
      finalPoolTokens += IZap(zap).zapIn(tokenB, amountB - pooledAmountB, pair, 0, new bytes(0), to);
    }

    require(finalPoolTokens >= minPoolTokens, "Insufficient LP migrated");

    return finalPoolTokens;
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairForOldRouter(address tokenA, address tokenB) internal view returns (address pair) {
    (address token0, address token1) = ISwapRouter(router).sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              sushiFactory,
              keccak256(abi.encodePacked(token0, token1)),
              IUniswapV2Factory(sushiFactory).pairCodeHash() // init code hash
            )
          )
        )
      )
    );
  }

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin
  ) internal returns (uint256 amountA, uint256 amountB) {
    IUniswapV2Pair pair = IUniswapV2Pair(pairForOldRouter(tokenA, tokenB));
    pair.transferFrom(msg.sender, address(pair), liquidity);
    (uint256 amount0, uint256 amount1) = pair.burn(address(this));
    (address token0, ) = ISwapRouter(router).sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require(amountA >= amountAMin, "Xcalibur: INSUFFICIENT_A_AMOUNT");
    require(amountB >= amountBMin, "Xcalibur: INSUFFICIENT_B_AMOUNT");
  }

  function addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 amountADesired,
    uint256 amountBDesired,
    address to,
    uint256 deadline
  )
    internal
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    )
  {
    require(deadline >= block.timestamp, "BaseV1Router: EXPIRED");
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired);
    address pair = ISwapRouter(router).pairFor(tokenA, tokenB, stable);
    IERC20(tokenA).transfer(pair, amountA);
    IERC20(tokenB).transfer(pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
  }

  function _addLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint256 amountADesired,
    uint256 amountBDesired
  ) internal returns (uint256 amountA, uint256 amountB) {
    // create the pair if it doesn't exist yet
    address _pair = ISwapFactory(factory).getPair(tokenA, tokenB, stable);
    if (_pair == address(0)) {
      _pair = ISwapFactory(factory).createPair(tokenA, tokenB, stable);
    }
    (uint256 reserveA, uint256 reserveB) = ISwapRouter(router).getReserves(tokenA, tokenB, stable);
    if (reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
      if (amountBOptimal <= amountBDesired) {
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
        assert(amountAOptimal <= amountADesired);
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

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

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
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