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

// File: @uniswap/lib/contracts/libraries/Babylonian.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../../lib/safe-math.sol";
import "../../../lib/erc20.sol";
import "../../../lib/square-root.sol";
import "../../../interfaces/weth.sol";
import "../../../interfaces/vault.sol";
import "../../../interfaces/uniswapv3.sol";
import "../../../interfaces/ISteerPeriphery.sol";
import "../../../interfaces/ISushiMultiPositionLiquidityManager.sol";

contract SteerZapperBase {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IVault;

  address public router = 0xE592427A0AEce92De3Edee1F18E0157C05861564; // uniswap V3 router
  address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public steerPeriphery = 0x806c2240793b3738000fcb62C66BF462764B903F;
  address public governance;

  // Define a mapping to store whether an address is whitelisted or not
  mapping(address => bool) public whitelistedVaults;
  // tokenIn => tokenOut => poolFee
  mapping(address => mapping(address => uint24)) public poolFees;

  uint256 public constant minimumAmount = 1000;

  constructor(
    address _governance,
    address[] memory _vaults,
    address[] memory _token0,
    address[] memory _token1,
    uint24[] memory _poolFee
  ) {
    // Safety checks to ensure WETH token address`
    WETH(weth).deposit{value: 0}();
    WETH(weth).withdraw(0);
    governance = _governance;

    require(
      _token0.length == _poolFee.length && _token1.length == _poolFee.length,
      "token and pool fee length must be equal"
    );

    for (uint i = 0; i < _vaults.length; i++) {
      whitelistedVaults[_vaults[i]] = true;
    }

    for (uint i = 0; i < _poolFee.length; i++) {
      poolFees[_token0[i]][_token1[i]] = _poolFee[i];
      // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
      poolFees[_token1[i]][_token0[i]] = _poolFee[i];
    }
  }

  receive() external payable {
    assert(msg.sender == weth);
  }

  // **** Modifiers **** //

  // Modifier to restrict access to whitelisted vaults only
  modifier onlyWhitelistedVaults(address vault) {
    require(whitelistedVaults[vault], "Vault is not whitelisted");
    _;
  }

  // Modifier to restrict access to governance only
  modifier onlyGovernance() {
    require(msg.sender == governance, "Caller is not the governance");
    _;
  }

  function getPoolFee(address token0, address token1) public view returns (uint24) {
    uint24 fee = poolFees[token0][token1];
    require(fee > 0, "pool fee is not set");
    return fee;
  }

  // Function to add a vault to the whitelist
  function addToWhitelist(address _vault) external onlyGovernance {
    whitelistedVaults[_vault] = true;
  }

  function setPoolFees(address _token0, address _token1, uint24 _poolFee) external onlyGovernance {
    require(_poolFee > 0, "pool fee must be greater than 0");
    require(_token0 != address(0) && _token1 != address(0), "invalid address");

    poolFees[_token0][_token1] = _poolFee;
    // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
    poolFees[_token1][_token0] = _poolFee;
  }

  // Function to remove a vault from the whitelist
  function removeFromWhitelist(address _vault) external onlyGovernance {
    whitelistedVaults[_vault] = false;
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

  function deposit(
    IVault vault,
    uint256 amount0,
    uint256 amount1,
    uint256 amountOutMin
  ) public onlyWhitelistedVaults(address(vault)) {
    (address token0, address token1) = steerVaultTokens(vault);

    //Deposit tokens to steer vault tokens
    //approve both tokens to Steer Periphery contract
    _approveTokenIfNeeded(token0, steerPeriphery);
    _approveTokenIfNeeded(token1, steerPeriphery);

    //get steer vault from local vault
    address _steerVault = vault.token();
    //deposit to Steer Periphery contract
    ISteerPeriphery(steerPeriphery).deposit(_steerVault, amount0, amount1, 0, 0, address(this));

    //get steer vault balance
    uint256 balance = IERC20(_steerVault).balanceOf(address(this));
    //depoist steer vault shares to local vault

    _approveTokenIfNeeded(_steerVault, address(vault));

    vault.deposit(balance);

    uint256 vaultBalance = vault.balanceOf(address(this));

    require(vaultBalance >= amountOutMin, "Insignificant amountOutMin");

    //return vault tokens to user
    IERC20(address(vault)).safeTransfer(msg.sender, vaultBalance);

    address[] memory tokens = new address[](2);
    tokens[0] = token0;
    tokens[1] = token1;

    _returnAssets(tokens);
  }

  function _swap(address tokenIn, address tokenOut, uint256 amountIn) private {
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

  function zapInETH(
    IVault vault,
    uint256 tokenAmountOutMin,
    address tokenIn,
    uint256 tokenInAmount0,
    uint256 tokenInAmount1
  ) external payable onlyWhitelistedVaults(address(vault)) {
    uint256 tokenInAmount = tokenInAmount0 + tokenInAmount1;
    require(msg.value >= minimumAmount, "Insignificant input amount");
    require(msg.value >= tokenInAmount, "Insignificant token in amounts");

    WETH(weth).deposit{value: msg.value}();

    (address token0, address token1) = steerVaultTokens(vault);

    if (tokenIn != token0 && tokenIn != token1) {
      _swap(weth, token0, tokenInAmount0);
      _swap(weth, token1, tokenInAmount1);
    } else {
      address tokenOut = token0;
      uint256 amountToSwap = tokenInAmount0;
      if (tokenIn == token0) {
        tokenOut = token1;
        amountToSwap = tokenInAmount1;
      }
      _swap(weth, tokenOut, amountToSwap);
    }

    deposit(vault, IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), tokenAmountOutMin);
  }

  function zapIn(
    IVault vault,
    uint256 tokenAmountOutMin,
    address tokenIn,
    uint256 tokenInAmount0,
    uint256 tokenInAmount1
  ) external onlyWhitelistedVaults(address(vault)) {
    uint256 tokenInAmount = tokenInAmount0 + tokenInAmount1;
    require(tokenInAmount >= minimumAmount, "Insignificant input amount");
    require(IERC20(tokenIn).allowance(msg.sender, address(this)) >= tokenInAmount, "Input token is not approved");

    // transfer token
    IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);

    (address token0, address token1) = steerVaultTokens(vault);

    //Note : tokenIn pair must exist withsteerVaultTokens
    if (token0 != tokenIn && token1 != tokenIn) {
      _swap(tokenIn, token0, tokenInAmount0);
      _swap(tokenIn, token1, tokenInAmount1);
    } else {
      address tokenOut = token0;
      uint256 amountToSwap = tokenInAmount0;
      if (tokenIn == token0) {
        tokenOut = token1;
        amountToSwap = tokenInAmount1;
      }
      _swap(tokenIn, tokenOut, amountToSwap);
    }

    deposit(vault, IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), tokenAmountOutMin);
  }

  function zapOutAndSwap(
    IVault vault,
    uint256 withdrawAmount,
    address desiredToken,
    uint256 desiredTokenOutMin
  ) public onlyWhitelistedVaults(address(vault)) {
    vault.safeTransferFrom(msg.sender, address(this), withdrawAmount);

    ISushiMultiPositionLiquidityManager steerVault = ISushiMultiPositionLiquidityManager(vault.token());

    vault.withdraw(withdrawAmount);
    //get steer vault tokens
    uint256 steerVaultTokenBal = steerVault.balanceOf(address(this));

    (uint256 amount0, uint256 amount1) = steerVault.withdraw(steerVaultTokenBal, 0, 0, address(this));
    (address token0, address token1) = steerVaultTokens(vault);

    // Swapping
    if (token0 != desiredToken) {
      _swap(token0, desiredToken, amount0);
    }

    if (token1 != desiredToken) {
      _swap(token1, desiredToken, amount1);
    }

    address[] memory path = new address[](3);
    path[0] = token0;
    path[1] = token1;
    path[2] = desiredToken;

    require(IERC20(desiredToken).balanceOf(address(this)) >= desiredTokenOutMin, "Insignificant desiredTokenOutMin");

    _returnAssets(path);
  }

  function zapOutAndSwapEth(
    IVault vault,
    uint256 withdrawAmount,
    uint256 desiredTokenOutMin
  ) public onlyWhitelistedVaults(address(vault)) {
    vault.safeTransferFrom(msg.sender, address(this), withdrawAmount);

    ISushiMultiPositionLiquidityManager steerVault = ISushiMultiPositionLiquidityManager(vault.token());

    vault.withdraw(withdrawAmount);
    //get steer vault tokens
    uint256 steerVaultTokenBal = steerVault.balanceOf(address(this));

    (uint256 amount0, uint256 amount1) = steerVault.withdraw(steerVaultTokenBal, 0, 0, address(this));

    (address token0, address token1) = steerVaultTokens(vault);

    // Swapping
    if (token0 != weth) {
      _swap(token0, weth, amount0);
    }

    if (token1 != weth) {
      _swap(token1, weth, amount1);
    }

    address[] memory path = new address[](3);
    path[0] = token0;
    path[1] = token1;
    path[2] = weth;

    require(IERC20(weth).balanceOf(address(this)) >= desiredTokenOutMin, "Insignificant desiredTokenOutMin");

    _returnAssets(path);
  }

  function getTotalAmounts(IVault vault) public view returns (uint256, uint256) {
    return ISushiMultiPositionLiquidityManager(vault.token()).getTotalAmounts();
  }

  function steerVaultTokens(IVault vault) public view returns (address, address) {
    return (
      ISushiMultiPositionLiquidityManager(vault.token()).token0(),
      ISushiMultiPositionLiquidityManager(vault.token()).token1()
    );
  }

  function _approveTokenIfNeeded(address token, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) == 0) {
      IERC20(token).safeApprove(spender, type(uint256).max);
    }
  }
}