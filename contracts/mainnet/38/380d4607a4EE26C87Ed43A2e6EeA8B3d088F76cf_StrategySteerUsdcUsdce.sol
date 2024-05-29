// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IController {
    function vaults(address) external view returns (address);

    function rewards() external view returns (address);

    function devfund() external view returns (address);

    function treasury() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function withdraw(address, uint256) external;

    function earn(address, uint256) external;

    // For Big Green Button:

    function setVault(address _token, address _vault) external;

    function approveStrategy(address _token, address _strategy) external;

    function revokeStrategy(address _token, address _strategy) external;

    function setStrategy(address _token, address _strategy) external;

    function setStrategist(address _strategist) external;

    function setGovernance(address _governance) external;

    function setTimelock(address _timelock) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISteerPeriphery {
  /**
    @param _vaultAddress	address	The address of the vault to deposit to
    @param amount0Desired	uint256	Max amount of token0 to deposit
    @param amount1Desired	uint256	Max amount of token1 to deposit
    @param amount0Min	    uint256	Revert if resulting amount0 is less than this
    @param amount1Min	    uint256	Revert if resulting amount1 is less than this
    @param to	            address	Recipient of shares
    */

  function deposit(
    address _vaultAddress,
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/erc20.sol";

interface ISushiMultiPositionLiquidityManager is IERC20 {
  /**
   * @dev Withdraws tokens in proportion to the vault's holdings.
   * @param shares Shares burned by sender
   * @param amount0Min Revert if resulting `amount0` is smaller than this
   * @param amount1Min Revert if resulting `amount1` is smaller than this
   * @param to Recipient of tokens
   * @return amount0 Amount of token0 sent to recipient
   * @return amount1 Amount of token1 sent to recipient
   */
  function withdraw(
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external returns (uint256 amount0, uint256 amount1);

  /// @dev Calculates the vault's total holdings of token0 and token1.
  ///      in other words, how much of each token the vault would hold if it withdrew
  ///      all its liquidity from Uniswap.
  ///      This function DOES NOT include fees earned since the last burn.
  ///      To include fees, first poke() and then call getTotalAmounts.
  ///      There's a function inside the periphery to do so.
  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

  function poke() external;

  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH); 

     function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

     function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;
pragma abicoder v2;

interface ISwapRouter {
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

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
  /// @notice Returns the amount out received for a given exact input swap without executing the swap
  /// @param path The path of the swap, i.e. each token pair and the pool fee
  /// @param amountIn The amount of the first token to swap
  /// @return amountOut The amount of the last token that would be received
  /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
  /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactInput(
    bytes memory path,
    uint256 amountIn
  )
    external
    returns (
      uint256 amountOut,
      uint160[] memory sqrtPriceX96AfterList,
      uint32[] memory initializedTicksCrossedList,
      uint256 gasEstimate
    );

  struct QuoteExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
  /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
  /// tokenIn The token being swapped in
  /// tokenOut The token being swapped out
  /// fee The fee of the token pool to consider for the pair
  /// amountIn The desired input amount
  /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
  /// @return amountOut The amount of `tokenOut` that would be received
  /// @return sqrtPriceX96After The sqrt price of the pool after the swap
  /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactInputSingle(
    QuoteExactInputSingleParams memory params
  )
    external
    returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

  /// @notice Returns the amount in required for a given exact output swap without executing the swap
  /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
  /// @param amountOut The amount of the last token to receive
  /// @return amountIn The amount of first token required to be paid
  /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
  /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactOutput(
    bytes memory path,
    uint256 amountOut
  )
    external
    returns (
      uint256 amountIn,
      uint160[] memory sqrtPriceX96AfterList,
      uint32[] memory initializedTicksCrossedList,
      uint256 gasEstimate
    );

  struct QuoteExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint256 amount;
    uint24 fee;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
  /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
  /// tokenIn The token being swapped in
  /// tokenOut The token being swapped out
  /// fee The fee of the token pool to consider for the pair
  /// amountOut The desired output amount
  /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
  /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
  /// @return sqrtPriceX96After The sqrt price of the pool after the swap
  /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
  /// @return gasEstimate The estimate of the gas that the swap consumes
  function quoteExactOutputSingle(
    QuoteExactOutputSingleParams memory params
  ) external returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../lib/erc20.sol";

interface IVault is IERC20 {
    function token() external view returns (address);
    
    function reward() external view returns (address);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getRatio() external view returns (uint256);

    function depositAll() external;
    
    function balance() external view returns (uint256);

    function deposit(uint256) external;

    function withdrawAll() external;

    function withdraw(uint256) external; 

    function earn() external;

    function decimals() external override view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface WETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function withdrawTo(address account, uint256 amount) external; 

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./safe-math.sol";
import "./context.sol";

// File: contracts/token/ERC20/IERC20.sol


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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: contracts/utils/Address.sol


/**
 * @dev Collection of functions related to the address type
 */
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./strategy-steer.sol";
import "../../interfaces/ISteerPeriphery.sol";
import "../../interfaces/vault.sol";
// Vault address for steer sushi USDC-USDC.e pool
//0x3eE813a6fCa2AaCAF0b7C72428fC5BC031B9BD65

abstract contract StrategySteerBase is StrategySteer {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IVault;

  address public sushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
  uint256 public constant minimumAmount = 1000;

  constructor(
    address _want,
    address _governance,
    address _strategist,
    address _controller,
    address _timelock
  ) StrategySteer(_want, _governance, _strategist, _controller, _timelock) {}

  // Declare a Harvest Event
  event Harvest(uint _timestamp, uint _value);

  function _swap(address, address, uint256) internal virtual;

  function harvest() public override onlyBenevolent {
    require(rewardToken != address(0), "!rewardToken");
    uint256 _reward = IERC20(rewardToken).balanceOf(address(this));
    require(_reward > 0, "!reward");
    uint256 _keepReward = _reward.mul(keepReward).div(keepMax);
    IERC20(rewardToken).safeTransfer(IController(controller).treasury(), _keepReward);

    _reward = IERC20(rewardToken).balanceOf(address(this));

    //get strategy steer vault tokens before balances
    uint256 beforeBal = IERC20(want).balanceOf(address(this));

    (address token0, address token1) = steerVaultTokens();

    (uint256 tokenInAmount0, uint256 tokenInAmount1) = calculateSteerVaultTokensRatio(_reward);

    uint256 tokenInAmount = tokenInAmount0 + tokenInAmount1;
    require(_reward >= minimumAmount, "Insignificant input amount");
    require(_reward >= tokenInAmount, "Insignificant token in amounts");

    if (rewardToken != token0 && rewardToken != token1) {
      _swap(rewardToken, token0, tokenInAmount0);
      _swap(rewardToken, token1, tokenInAmount1);
    } else {
      address tokenOut = token0;
      uint256 amountToSwap = tokenInAmount0;
      if (rewardToken == token0) {
        tokenOut = token1;
        amountToSwap = tokenInAmount1;
      }
      _swap(rewardToken, tokenOut, amountToSwap);
    }

    depositToSteerVault(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));

    //get strategy steer vault tokens after balances
    uint256 afterBal = IERC20(want).balanceOf(address(this));

    emit Harvest(block.timestamp, afterBal.sub(beforeBal));
  }

  function depositToSteerVault(uint256 _amount0, uint256 _amount1) public override {
    (address token0, address token1) = steerVaultTokens();

    //approve both tokens to Steer Periphery contract
    _approveTokenIfNeeded(token0, steerPeriphery);
    _approveTokenIfNeeded(token1, steerPeriphery);

    //deposit to Steer Periphery contract
    ISteerPeriphery(steerPeriphery).deposit(want, _amount0, _amount1, 0, 0, address(this));

    address[] memory tokens = new address[](2);
    tokens[0] = token0;
    tokens[1] = token1;

    _returnAssets(tokens);
  }

  function calculateSteerVaultTokensPrices() internal view returns (uint256 token0Price, uint256 token1Price) {
    (address token0, address token1) = steerVaultTokens();

    bool isToken0Stable = isStableToken(token0);
    bool isToken1Stable = isStableToken(token1);

    if (isToken0Stable) token0Price = 1 * PRECISION;
    if (isToken1Stable) token1Price = 1 * PRECISION;

    if (!isToken0Stable) {
      token0Price = getPrice(token0);
    }

    if (!isToken1Stable) {
      token1Price = getPrice(token1);
    }

    return (token0Price, token1Price);
  }

  function isStableToken(address token) internal view returns (bool) {
    for (uint256 i = 0; i < stableTokens.length; i++) {
      if (stableTokens[i] == token) return true;
    }
    return false;
  }

  function getPrice(address token) internal view returns (uint256) {
    if (token == weth) {
      return calculateTokenPriceInUsdc(weth, weth_Usdc_Pair);
    } else {
      (address token0, address token1) = steerVaultTokens();
      
      // get pair address from factory contract for weth and desired token
      address pair;
      if (token == token0) {
        pair = IUniswapV2Factory(sushiFactory).getPair(token0, weth);
        return calculateLpPriceInUsdc(token0, pair);
      }

      pair = IUniswapV2Factory(sushiFactory).getPair(token1, weth);
      return calculateLpPriceInUsdc(token1, pair);
    }
  }

  function calculateSteerVaultTokensRatio(uint256 _amountIn) internal view returns (uint256, uint256) {
    (address token0, address token1) = steerVaultTokens();
    (uint256 amount0, uint256 amount1) = getTotalAmounts();
    (uint256 token0Price, uint256 token1Price) = calculateSteerVaultTokensPrices();

    uint256 token0Value = ((token0Price * amount0) / (10 ** uint256(IERC20(token0).decimals()))) / PRECISION;
    uint256 token1Value = ((token1Price * amount1) / (10 ** uint256(IERC20(token1).decimals()))) / PRECISION;

    uint256 totalValue = token0Value + token1Value;
    uint256 token0Amount = (_amountIn * token0Value) / totalValue;
    uint256 token1Amount = _amountIn - token0Amount;

    return (token0Amount, token1Amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./strategy-steer-base.sol";
import "../../interfaces/uniswapv3.sol";
// Vault address for steer sushi USDC-USDC.e pool
//0x3eE813a6fCa2AaCAF0b7C72428fC5BC031B9BD65

contract StrategySteerUsdcUsdce is StrategySteerBase {
  constructor(
    address _governance,
    address _strategist,
    address _controller,
    address _timelock
  ) StrategySteerBase(0x3eE813a6fCa2AaCAF0b7C72428fC5BC031B9BD65, _governance, _strategist, _controller, _timelock) {}

  
  // Dex
  address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

  function _swap(address tokenIn, address tokenOut, uint256 amountIn) internal override {
    address[] memory path = new address[](2);
    path[0] = tokenIn;
    path[1] = tokenOut;

    _approveTokenIfNeeded(path[0], address(router));
    ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
      tokenIn: path[0],
      tokenOut: path[1],
      fee: getPoolFee(tokenIn, tokenOut),
      recipient: address(this),
      deadline: block.timestamp,
      amountIn: amountIn,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });
    ISwapRouter(address(router)).exactInputSingle(params);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../lib/erc20.sol";
import "../../interfaces/controller.sol";
import "../../lib/safe-math.sol";
import "../../interfaces/ISushiMultiPositionLiquidityManager.sol";
import "../../Utils/PriceCalculator.sol";
import "../../interfaces/weth.sol";

abstract contract StrategySteer is PriceCalculator {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  // tokenIn => tokenOut => poolFee
  mapping(address => mapping(address => uint24)) public poolFees;
  // Tokens
  address public want;
  address public feeDistributor = 0xAd86ef5fD2eBc25bb9Db41A1FE8d0f2a322c7839;

  address public steerPeriphery = 0x806c2240793b3738000fcb62C66BF462764B903F;
  ISushiMultiPositionLiquidityManager public steerVault;

  // Perfomance fees - start with 10%
  uint256 public performanceTreasuryFee = 1000;
  uint256 public constant performanceTreasuryMax = 10000;

  uint256 public performanceDevFee = 0;
  uint256 public constant performanceDevMax = 10000;

  // Withdrawal fee 0%
  // - 0% to treasury
  // - 0% to dev fund
  uint256 public withdrawalTreasuryFee = 0;
  uint256 public constant withdrawalTreasuryMax = 100000;

  uint256 public withdrawalDevFundFee = 0;
  uint256 public constant withdrawalDevFundMax = 100000;

  // How much tokens to keep? 10%
  uint256 public keep = 1000;
  uint256 public keepReward = 1000;
  uint256 public constant keepMax = 10000;

  address public controller;
  address public strategist;
  address public timelock;
  address public rewardToken;

  mapping(address => bool) public harvesters;

  constructor(
    address _want,
    address _governance,
    address _strategist,
    address _controller,
    address _timelock
  ) PriceCalculator(_governance) {
    require(_want != address(0));
    require(_governance != address(0));
    require(_strategist != address(0));
    require(_controller != address(0));
    require(_timelock != address(0));

    want = _want;
    governance = _governance;
    strategist = _strategist;
    controller = _controller;
    timelock = _timelock;

    steerVault = ISushiMultiPositionLiquidityManager(want);
  }

  // **** Modifiers **** //

  modifier onlyBenevolent() {
    require(harvesters[msg.sender] || msg.sender == governance || msg.sender == strategist);
    _;
  }

  function balanceOf() public view returns (uint256) {
    return IERC20(want).balanceOf(address(this));
  }

  // **** Setters **** //

  function whitelistHarvester(address _harvester) external {
    require(msg.sender == governance || msg.sender == strategist || harvesters[msg.sender], "not authorized");
    harvesters[_harvester] = true;
  }

  function revokeHarvester(address _harvester) external {
    require(msg.sender == governance || msg.sender == strategist, "not authorized");
    harvesters[_harvester] = false;
  }

  // **** Setters ****

  function setKeep(uint256 _keep) external {
    require(msg.sender == timelock, "!timelock");
    keep = _keep;
  }

  function setKeepReward(uint256 _keepReward) external {
    require(msg.sender == timelock, "!timelock");
    keepReward = _keepReward;
  }

  function setRewardToken(address _rewardToken) external {
    require(msg.sender == timelock || msg.sender == strategist, "!timelock");
    rewardToken = _rewardToken;
  }

  function setFeeDistributor(address _feeDistributor) external {
    require(msg.sender == governance, "not authorized");
    feeDistributor = _feeDistributor;
  }

  function setWithdrawalDevFundFee(uint256 _withdrawalDevFundFee) external {
    require(msg.sender == timelock, "!timelock");
    withdrawalDevFundFee = _withdrawalDevFundFee;
  }

  function setWithdrawalTreasuryFee(uint256 _withdrawalTreasuryFee) external {
    require(msg.sender == timelock, "!timelock");
    withdrawalTreasuryFee = _withdrawalTreasuryFee;
  }

  function setPerformanceDevFee(uint256 _performanceDevFee) external {
    require(msg.sender == timelock, "!timelock");
    performanceDevFee = _performanceDevFee;
  }

  function setPerformanceTreasuryFee(uint256 _performanceTreasuryFee) external {
    require(msg.sender == timelock, "!timelock");
    performanceTreasuryFee = _performanceTreasuryFee;
  }

  function setStrategist(address _strategist) external {
    require(msg.sender == governance, "!governance");
    strategist = _strategist;
  }

  function setGovernance(address _governance) external {
    require(msg.sender == governance, "!governance");
    governance = _governance;
  }

  function setTimelock(address _timelock) external {
    require(msg.sender == timelock, "!timelock");
    timelock = _timelock;
  }

  function setController(address _controller) external {
    require(msg.sender == timelock, "!timelock");
    controller = _controller;
  }

  function getPoolFee(address token0, address token1) public view returns (uint24) {
    uint24 fee = poolFees[token0][token1];
    require(fee > 0, "pool fee is not set");
    return fee;
  }

  function setPoolFees(address _token0, address _token1, uint24 _poolFee) external onlyGovernance {
    require(_poolFee > 0, "pool fee must be greater than 0");
    require(_token0 != address(0) && _token1 != address(0), "invalid address");

    poolFees[_token0][_token1] = _poolFee;
    // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
    poolFees[_token1][_token0] = _poolFee;
  }

  // Controller only function for creating additional rewards from dust
  function withdraw(IERC20 _asset) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    require(want != address(_asset), "want");
    balance = _asset.balanceOf(address(this));
    _asset.safeTransfer(controller, balance);
  }

  // Withdraw partial funds, normally used with a vault withdrawal

  function withdraw(uint256 _amount) external {
    require(msg.sender == controller, "!controller");
    require(balanceOf() >= _amount, "!balance");

    uint256 _feeDev = _amount.mul(withdrawalDevFundFee).div(withdrawalDevFundMax);
    IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);

    uint256 _feeTreasury = _amount.mul(withdrawalTreasuryFee).div(withdrawalTreasuryMax);
    IERC20(want).safeTransfer(IController(controller).treasury(), _feeTreasury);

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds

    IERC20(want).safeTransfer(_vault, _amount.sub(_feeDev).sub(_feeTreasury));
  }

  // Withdraw funds, used to swap between strategies
  function withdrawForSwap(uint256 _amount) external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    balance = balanceOf();
    require(balance >= _amount, "!balance");

    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault");
    IERC20(want).safeTransfer(_vault, _amount);
  }

  // Withdraw all funds, normally used when migrating strategies
  function withdrawAll() external returns (uint256 balance) {
    require(msg.sender == controller, "!controller");
    balance = balanceOf();
    address _vault = IController(controller).vaults(address(want));
    require(_vault != address(0), "!vault"); // additional protection so we don't burn the funds
    IERC20(want).safeTransfer(_vault, balance);
  }

  function harvest() public virtual;

  function depositToSteerVault(uint256 _amount0, uint256 _amount1) public virtual;

  function getTotalAmounts() public view returns (uint256, uint256) {
    return steerVault.getTotalAmounts();
  }

  function steerVaultTokens() public view returns (address, address) {
    return (steerVault.token0(), steerVault.token1());
  }

  //returns DUST
  function _returnAssets(address[] memory tokens) internal {
    uint256 balance;
    for (uint256 i; i < tokens.length; i++) {
      balance = IERC20(tokens[i]).balanceOf(address(this));
      if (balance > 0) {
        if (tokens[i] == weth) {
          WETH(weth).withdraw(balance);
          (bool success, ) = msg.sender.call{value: balance}(new bytes(0));
          require(success, "ETH transfer failed");
        } else {
          IERC20(tokens[i]).safeTransfer(msg.sender, balance);
        }
      }
    }
  }

  function _approveTokenIfNeeded(address token, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).safeApprove(spender, type(uint256).max);
    }
  }

  // **** Emergency functions ****

  function execute(address _target, bytes memory _data) public payable returns (bytes memory response) {
    require(msg.sender == timelock, "!timelock");
    require(_target != address(0), "!target");

    // call contract in current context
    assembly {
      let succeeded := delegatecall(sub(gas(), 5000), _target, add(_data, 0x20), mload(_data), 0, 0)
      let size := returndatasize()

      response := mload(0x40)
      mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(response, size)
      returndatacopy(add(response, 0x20), 0, size)

      switch iszero(succeeded)
      case 1 {
        // throw if delegatecall failed
        revert(add(response, 0x20), size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../lib/erc20.sol";

import "../interfaces/uniswapv2.sol";

contract PriceCalculator {
  using SafeERC20 for IERC20;
  address public governance;

  uint256 public constant PRECISION = 10_000_000;

  address public weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  //For arb weth/usdc
  address public weth_Usdc_Pair = 0x905dfCD5649217c42684f23958568e533C711Aa3;

  // Array of stable tokens
  address[] public stableTokens = [
    0xaf88d065e77c8cC2239327C5EDb3A432268e5831,
    0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9,
    0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8
  ];

  // Modifier to restrict access to governance only
  modifier onlyGovernance() {
    require(msg.sender == governance, "Caller is not the governance");
    _;
  }

  constructor(address _governance) {
    require(_governance != address(0));
    governance = _governance;
  }

  // set func to add stable tokens address in the array
  function setStableTokens(address _stableTokens) external onlyGovernance {
    stableTokens.push(_stableTokens);
  }

  function calculateTokenPriceInUsdc(address _token, address _pairAddress) public view returns (uint256) {
    IUniswapV2Pair _pair = IUniswapV2Pair(_pairAddress);
    (uint112 _reserve0, uint112 _reserve1, ) = _pair.getReserves();
    address token0 = _pair.token0();
    address token1 = _pair.token1();
    // Get token decimals
    uint8 token0Decimals = IERC20(token0).decimals();
    uint8 token1Decimals = IERC20(token1).decimals();

    // Check if the token of interest is token0 or token1 and calculate price accordingly
    if (_token == token0) {
      //check if token1 is in stable tokens array
      for (uint256 i = 0; i < stableTokens.length; i++) {
        if (stableTokens[i] == token1) {
          uint256 assetPrice = _getPrice(_reserve0, _reserve1, token0Decimals, token1Decimals);
          return assetPrice;
        }
      }
    } else if (_token == token1) {
      //check if token0 is in stable tokens array
      for (uint256 i = 0; i < stableTokens.length; i++) {
        if (stableTokens[i] == token0) {
          uint256 assetPrice = _getPrice(_reserve1, _reserve0, token1Decimals, token0Decimals);
          return assetPrice;
        }
      }
    }
    return 0;
  }

  // pair should be of WEth/LpToken eg weth/Sushi
  function calculateLpPriceInUsdc(address _lpToken, address _pairAddress) public view returns (uint256) {
    IUniswapV2Pair _pair = IUniswapV2Pair(_pairAddress);
    (uint112 _reserve0, uint112 _reserve1, ) = _pair.getReserves();
    address token0 = _pair.token0();
    address token1 = _pair.token1();
    uint8 token0Decimals = IERC20(token0).decimals();
    uint8 token1Decimals = IERC20(token1).decimals();
    //Calculate price of eth in usdc
    uint256 priceOfEthInUsdc = calculateTokenPriceInUsdc(weth, weth_Usdc_Pair);

    //Get price of lp in Eth
    uint256 lpPriceInEth;
    if (_lpToken == token0) {
      lpPriceInEth = _getPrice(_reserve0, _reserve1, token0Decimals, token1Decimals);
    } else {
      lpPriceInEth = _getPrice(_reserve1, _reserve0, token1Decimals, token0Decimals);
    }

    return (priceOfEthInUsdc * lpPriceInEth) / PRECISION;
  }

  function _getPrice(
    uint112 tokenReserve,
    uint112 priceInTokenReserve,
    uint8 tokenDecimals,
    uint8 priceInTokenDecimals
  ) private pure returns (uint256) {
    if (tokenDecimals > priceInTokenDecimals) {
      uint256 factor = 10 ** (tokenDecimals - priceInTokenDecimals);
      return ((priceInTokenReserve * factor) * PRECISION) / tokenReserve;
    } else if (tokenDecimals < priceInTokenDecimals) {
      uint256 factor = 10 ** (priceInTokenDecimals - tokenDecimals);
      return ((priceInTokenReserve) * PRECISION) / (tokenReserve * factor);
    } else {
      return ((priceInTokenReserve) * PRECISION) / tokenReserve;
    }
  }
}