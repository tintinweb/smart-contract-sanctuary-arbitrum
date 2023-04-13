/**
 *Submitted for verification at Arbiscan on 2023-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
library Address {
  /**
   * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize/address.code.length, which returns 0
    // for contracts in construction, since the code is only stored at the end
    // of the constructor execution.

    return account.code.length > 0;
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint value
  ) internal {
    uint newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

}
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
}

interface IPair {

  // Structure to capture time period obervations every 30 minutes, used for local oracles
  struct Observation {
    uint timestamp;
    uint reserve0Cumulative;
    uint reserve1Cumulative;
  }

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

  function burn(address to) external returns (uint amount0, uint amount1);

  function mint(address to) external returns (uint liquidity);

  function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

  function getAmountOut(uint, address) external view returns (uint);

  function claimFees() external returns (uint, uint);

  function tokens() external view returns (address, address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function stable() external view returns (bool);

  function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}
interface IWAVAX {
  function name() external view returns (string memory);

  function approve(address guy, uint256 wad) external returns (bool);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);

  function withdraw(uint256 wad) external;

  function decimals() external view returns (uint8);

  function balanceOf(address) external view returns (uint256);

  function symbol() external view returns (string memory);

  function transfer(address dst, uint256 wad) external returns (bool);

  function deposit() external payable;

  function allowance(address, address) external view returns (uint256);

}
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}
contract AMMRouter{
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  struct Route {
    address pair;
    bool AMM;
  }

  IWAVAX public immutable wavax;
 
  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'AMMRouter: EXPIRED');
    _;
  }

  constructor(address _wavax) {
    wavax = IWAVAX(_wavax);
  }

  receive() external payable {
    // only accept AVAX via fallback from the WAVAX contract
    require(msg.sender == address(wavax), "AMMRouter: NOT_WAVAX");
  }

  function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
    return _sortTokens(tokenA, tokenB);
  }

  function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'AMMRouter: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'AMMRouter: ZERO_ADDRESS');
  }

  function getOtherToken(address pair, address token) internal view returns (address otherToken) {
    address token0 = IPair(pair).token0();
    address token1 = IPair(pair).token1();
    otherToken = token0 == token ? token1 : token0;
  }

  

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountOut(uint amountIn, address tokenIn, address pair, bool AMM) external view returns (uint amount) {
    _getAmountOut(amountIn, tokenIn, pair, AMM);
  }
  function _getAmountOut(uint amountIn, address tokenIn, address pair, bool AMM) internal view returns (uint amount) {
    if (AMM) {
      amount = IPair(pair).getAmountOut(amountIn, tokenIn);
    }else{
      amount = _getAmountOut0(amountIn, tokenIn, pair);
    }
  }
  function _getAmountOut0(uint amountIn, address tokenIn, address pair) internal view returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        (uint reserve0, uint reserve1,) = IPair(pair).getReserves();
        require(reserve0 > 0 && reserve1 > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        address token0 = IPair(pair).token0();
        (uint reserveIn, uint reserveOut) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
  

  /// @dev Performs chained getAmountOut calculations on any number of pairs.
  function getAmountsOut(uint amountIn, address tokenIn, Route[] memory routes) external view returns (uint[] memory amounts) {
    return _getAmountsOut(amountIn, tokenIn, routes);
  }

  function _getAmountsOut(uint amountIn, address _tokenIn, Route[] memory routes) internal view returns (uint[] memory amounts) {
    require(routes.length >= 1, 'AMMRouter: INVALID_PATH');
    amounts = new uint[](routes.length + 1);
    amounts[0] = amountIn;
    address tokenIn = _tokenIn;
    for (uint i = 0; i < routes.length; i++) {
      address pair = routes[i].pair;
      amounts[i + 1] = _getAmountOut(amounts[i], tokenIn, pair, routes[i].AMM);
      tokenIn = getOtherToken(pair, tokenIn);
    }
  }


  // **** SWAP ****
  // requires the initial amount to have already been sent to the first pair
  function _swap(uint[] memory amounts, address _tokenIn, Route[] memory routes, address _to) internal virtual {
    address tokenIn = _tokenIn;
    for (uint i = 0; i < routes.length; i++) {
      address token0 = IPair(routes[i].pair).token0();
      uint amountOut = amounts[i + 1];
      (uint amount0Out, uint amount1Out) = tokenIn == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < routes.length - 1 ? routes[i + 1].pair : _to;
      IPair(routes[i].pair).swap(
        amount0Out, amount1Out, to, new bytes(0)
      );
      tokenIn = getOtherToken(routes[i].pair, tokenIn);
    }
  }

  function _swapSupportingFeeOnTransferTokens(address _tokenIn, Route[] memory routes, address _to) internal virtual {
    address input = _tokenIn;
    for (uint i = 0; i < routes.length; i++) {
      //(address input, address output) = (routes[i].from, routes[i].to);
      IPair pair = IPair(routes[i].pair);
      address token0 = pair.token0();
      uint amountInput;
      uint amountOutput;
      {// scope to avoid stack too deep errors
        (uint reserve0, uint reserve1,) = pair.getReserves();
        uint reserveInput = input == token0 ? reserve0 : reserve1;
        amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
        //(amountOutput,) = getAmountOut(amountInput, input, output, stable);
        amountOutput = _getAmountOut(amountInput, input, address(pair), routes[i].AMM);
      }
      (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
      address to = i < routes.length - 1 ? routes[i + 1].pair : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
      input = getOtherToken(address(pair),input);
    }
  }

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address tokenIn,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) returns (uint[] memory amounts) {
    amounts = _getAmountsOut(amountIn, tokenIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(tokenIn).safeTransferFrom(
      msg.sender, routes[0].pair, amounts[0]
    );
    _swap(amounts, tokenIn, routes, to);
  }

  function swapExactAVAXForTokens(uint amountOutMin, address tokenIn, Route[] calldata routes, address to, uint deadline)
  external
  payable
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(tokenIn == address(wavax), 'AMMRouter: INVALID_PATH');
    amounts = _getAmountsOut(msg.value, tokenIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wavax.deposit{value : amounts[0]}();
    assert(wavax.transfer(routes[0].pair, amounts[0]));
    _swap(amounts, tokenIn, routes, to);
  }

  function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address tokenIn, Route[] calldata routes, address to, uint deadline)
  external
  ensure(deadline)
  returns (uint[] memory amounts)
  {
    require(IPair(routes[routes.length - 1].pair).token0() == address(wavax)
    || IPair(routes[routes.length - 1].pair).token1() == address(wavax), 'AMMRouter: INVALID_PATH');
    amounts = _getAmountsOut(amountIn, tokenIn, routes);
    require(amounts[amounts.length - 1] >= amountOutMin, 'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    IERC20(tokenIn).safeTransferFrom(
      msg.sender, routes[0].pair, amounts[0]
    );
    _swap(amounts, tokenIn, routes, address(this));
    wavax.withdraw(amounts[amounts.length - 1]);
    _safeTransferAVAX(to, amounts[amounts.length - 1]);
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address tokenIn,
    address tokenOut,
    Route[] calldata routes,
    address to,
    uint deadline
  ) external ensure(deadline) {
    IERC20(tokenIn).safeTransferFrom(
      msg.sender,
      routes[0].pair,
      amountIn
    );
    uint balanceBefore = IERC20(tokenOut).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(tokenIn, routes, to);
    require(
      IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
      'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address tokenIn,
    address tokenOut,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  payable
  ensure(deadline)
  {
    require(tokenIn == address(wavax), 'AMMRouter: INVALID_PATH');
    uint amountIn = msg.value;
    wavax.deposit{value : amountIn}();
    assert(wavax.transfer(routes[0].pair, amountIn));
    uint balanceBefore = IERC20(tokenOut).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(tokenIn, routes, to);
    require(
      IERC20(tokenOut).balanceOf(to) - balanceBefore >= amountOutMin,
      'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    );
  }

  function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address tokenIn,
    address tokenOut,
    Route[] calldata routes,
    address to,
    uint deadline
  )
  external
  ensure(deadline)
  {
    require(tokenOut == address(wavax), 'AMMRouter: INVALID_PATH');
    IERC20(tokenIn).safeTransferFrom(
      msg.sender, routes[0].pair, amountIn
    );
    _swapSupportingFeeOnTransferTokens(tokenIn, routes, address(this));
    uint amountOut = IERC20(address(wavax)).balanceOf(address(this));
    require(amountOut >= amountOutMin, 'AMMRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    wavax.withdraw(amountOut);
    _safeTransferAVAX(to, amountOut);
  }


  function _safeTransferAVAX(address to, uint value) internal {
    (bool success,) = to.call{value : value}(new bytes(0));
    require(success, 'AMMRouter: AVAX_TRANSFER_FAILED');
  }
}