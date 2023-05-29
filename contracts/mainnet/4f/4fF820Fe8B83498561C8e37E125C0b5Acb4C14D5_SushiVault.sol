// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
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
        // else z = 0
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IMiniChefV2 {
    function userInfo(
        uint256 _pid,
        address _user
    ) external view returns (uint256, uint256);

    function pendingSushi(
        uint256 _pid,
        address _user
    ) external view returns (uint256);

    function deposit(uint256 pid, uint256 amount, address to) external;

    function withdraw(uint256 pid, uint256 amount, address to) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function rewarder(uint256 poolId) external returns(address);

    function poolInfo(uint256 poolId) external returns(uint256,uint256,uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IRewarder {
    function rewardToken() external returns(address);
}



        //covert r0,r1 to t0  //route r0 to t0, route r1 to t0
        //handle single asset liquidity
        //(reward0, reward1, tok0,tok1)
        //(reward0== tok0/tok1, reward1 == token0/token1)    
        //S1
        //r0/r1 = t0/t1
        //convert r1 to r0 //route r0 to r1
        //handle single asset liquidity

        //S2
        //
        //r0 & r1 = t0 & t1;
        //r0>r1  convert r0: r1 //route r0 to r1
        //handle single asset liquidity

        
        // if(sushiBal>0){
        //     IUniswapV2Router02(router).swapExactTokensForTokens(
        //         sushiBal,
        //         0,
        //         route0,
        //         address(this),
        //         block.timestamp
        //     );   
        // }
        // if(rewardBal>0) {
        //     IUniswapV2Router02(router).swapExactTokensForTokens(
        //         rewardBal,
        //         0,
        //         route1,
        //         address(this),
        //         block.timestamp
        //     );
        // }

        // (uint112 res0,, ) = IUniswapV2Pair(asset).getReserves();

        // uint256 amountToSwap = _calculateSwapInAmount(res0,IERC20(lpToken0).balanceOf(address(this)));
        // address [] memory path = new address[](2);
        // path[0] = IUniswapV2Pair(asset).token0();
        // path[1] = IUniswapV2Pair(asset).token1();
        // IUniswapV2Router02(router).swapExactTokensForTokens(
        //     amountToSwap,
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp
        // );
        // uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
        // uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
        // IERC20(lpToken0).approve(router, lp0Bal);
        // IERC20(lpToken1).approve(router, lp1Bal);
        // (, ,lpAmount) = IUniswapV2Router02(router).addLiquidity(
        //     lpToken0,
        //     lpToken1,
        //     lp0Bal,
        //     lp1Bal,
        //     1,
        //     1,
        //     address(this),
        //     block.timestamp
        // );

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IVault {
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );

    event Fees(uint256 t0,uint256 t1);

    function deposit(uint256 amount, address receiver) external;

    function withdraw(
        uint256 amount,
        address receiver
    ) external returns (uint256 shares);

    function harvest() external;

    function pauseAndWithdraw() external;

    function unpauseAndDeposit() external;

    function emergencyExit(uint256 amount, address receiver) external;

    function changeAllowance(address token, address to) external;

    function pauseVault() external;

    function unpauseVault() external;

    function asset() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../interfaces/sushi/IMiniChefV2.sol";
import "../interfaces/sushi/IRewarder.sol";
import "../interfaces/vault/IVault.sol";
import "./vaultToken/ERC20.sol";


contract SushiVault is IVault, ERC20, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 public constant FEE = 250;
    uint256 public constant REMAINING_AMOUNT = 9500;
    address public constant miniChef =
        0xF4d73326C13a4Fc5FD7A064217e12780e9Bd62c3;
    address public constant router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public constant sushi = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;
    address public constant treasury0 =
        0x723a2e7E926A8AFc5871B8962728Cb464f698A54;
    address public constant treasury1 =
        0x723a2e7E926A8AFc5871B8962728Cb464f698A54;
    address public immutable override asset;
    address public immutable factory;
    uint256 public immutable poolId;
    address[] public route;

    constructor(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint256 _poolId,
        address[] memory _route,
        address[] memory _approveToken,
        address _factory
    ) public ERC20(_name, _symbol, 18) {
        _pause();
        asset = _asset;

        poolId = _poolId;

        route = _route;

        factory = _factory;

        IERC20(_asset).safeApprove(miniChef, uint256(type(uint256).max));
        for (uint256 i; i < _approveToken.length; ++i) {
            IERC20(_approveToken[i]).safeApprove(
                router,
                uint256(type(uint256).max)
            );
        }
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "!Factory");
        _;
    }

    function deposit(
        uint256 amount,
        address receiver
    ) external override whenNotPaused {
        require(amount > 0, "Zero Amount");
        address _miniChef = miniChef;
        uint256 _poolId = poolId;
        address _asset = asset;
        uint256 shares = calculateShareAmount(amount, _miniChef, _poolId);
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), amount);
        IMiniChefV2(_miniChef).deposit(_poolId, amount, address(this));
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, amount, shares);
    }

    function withdraw(
        uint256 amount,
        address receiver
    ) external override returns (uint256 shares) {
        require(amount > 0, "ZA");
        address _miniChef = miniChef;
        uint256 _poolId = poolId;
        shares = calculateWithdrawShare(amount, _miniChef, _poolId);
        require(shares > 0, "Zero Shares");
        IMiniChefV2(_miniChef).withdrawAndHarvest(
            _poolId,
            shares,
            address(this)
        );
        _handleReward(_miniChef, _poolId, receiver);
        IERC20(asset).safeTransfer(
            receiver,
            IERC20(asset).balanceOf(address(this))
        );
        _burn(msg.sender, amount);
        emit Withdraw(msg.sender, receiver, amount, shares);
    }

    function harvest() external override {
        address _miniChef = miniChef;
        uint256 _poolId = poolId;
        address _asset = asset;
        address reward = IMiniChefV2(_miniChef).rewarder(_poolId);
        IMiniChefV2(_miniChef).harvest(_poolId, address(this));
        uint256 amount = reward == address(0) //ETH-DAI   ETH-SUSHI ETH-MAGIC MAGIC-SUSHI
            ? _handleSushiToken(_asset)
            : _handleRewardToken(_asset, IRewarder(reward).rewardToken());
        IMiniChefV2(_miniChef).deposit(_poolId, amount, address(this));
    }

    function pauseAndWithdraw() external override whenNotPaused onlyFactory {
        _pause();
        IMiniChefV2(miniChef).emergencyWithdraw(poolId, address(this));
    }

    function unpauseAndDeposit() external override whenPaused onlyFactory {
        _unpause();
        address _miniChef = miniChef;
        address _asset = asset;
        IMiniChefV2(_miniChef).deposit(
            poolId,
            IERC20(_asset).balanceOf(address(this)),
            address(this)
        );
    }

    function emergencyExit(
        uint256 amount,
        address receiver
    ) external override whenPaused {
        address _asset = asset;
        uint256 assetAmount = IERC20(_asset).balanceOf(address(this));
        require(assetAmount > 0, "Zero Asset Amount");
        require(amount > 0, "Zero Amount");
        uint256 shares = amount.mul(totalSupply).div(assetAmount);
        _burn(msg.sender, amount);
        IERC20(_asset).safeTransfer(receiver, shares);
        emit Withdraw(msg.sender, receiver, amount, shares);
    }

    function pauseVault() external override onlyFactory {
        _pause();
    }

    function unpauseVault() external override onlyFactory {
        _unpause();
    }

    function changeAllowance(
        address token,
        address to
    ) external override onlyFactory {
        IERC20(token).allowance(address(this), to) == 0
            ? IERC20(token).safeApprove(to, uint256(type(uint256).max))
            : IERC20(token).safeApprove(to, 0);
    }

    function _handleReward(
        address _miniChef,
        uint256 _poolId,
        address receiver
    ) internal {
        address rewardToken;
        uint256 rewardBal;
        uint256 sushiBal;
        if (IMiniChefV2(_miniChef).rewarder(_poolId) != address(0)) {
            rewardToken = IRewarder(IMiniChefV2(_miniChef).rewarder(_poolId))
                .rewardToken();
            rewardBal = IERC20(rewardToken).balanceOf(address(this));
            sushiBal = IERC20(sushi).balanceOf(address(this));
            if (rewardBal > 0 && sushiBal > 0) {
                _swap(sushiBal, route, router);
                IERC20(rewardToken).safeTransfer(
                    receiver,
                    _chargeFees(rewardToken, rewardBal)
                );
            } else if (rewardBal > 0) {
                IERC20(rewardToken).safeTransfer(
                    receiver,
                    _chargeFees(rewardToken, rewardBal)
                );
            }
        }
        sushiBal = IERC20(sushi).balanceOf(address(this));
        if (sushiBal > 0) {
            IERC20(sushi).safeTransfer(receiver, _chargeFees(sushi, sushiBal));
        }
    }

    function _handleSushiToken(address _asset) internal returns (uint256) {
        address _sushi = sushi;
        address _router = router;
        address lpToken0 = IUniswapV2Pair(_asset).token0();
        address lpToken1 = IUniswapV2Pair(_asset).token1();
        require(
            IERC20(_sushi).balanceOf(address(this)) > 0,
            "Zero Harvest Amount"
        );

        if (_sushi != lpToken0 && _sushi != lpToken1) {
            //and sushi not match with anyone of token in LP ETH-DAI
            _swap(IERC20(_sushi).balanceOf(address(this)), route, _router); //route sushi-to-lp1/lp0
        }
        _arrangeAddliquidityObject(
            _asset,
            route.length > 0 ? route[route.length - 1] : _sushi, //route[route.length - 1],//or sushi
            lpToken0,
            lpToken1,
            _router
        );
        return _addLiquidity(lpToken0, lpToken1, _router);
    }

    function _handleRewardToken(
        address _asset,
        address reward
    ) internal returns (uint256) {
        address _sushi = sushi;
        address _router = router;
        address lpToken0 = IUniswapV2Pair(_asset).token0();
        address lpToken1 = IUniswapV2Pair(_asset).token1();
        uint256 sushiBal = IERC20(_sushi).balanceOf(address(this));
        if (sushiBal > 0) {
            _swap(sushiBal, route, _router); //convert sushi to reward token
        } else {
            require(
                IERC20(reward).balanceOf(address(this)) > 0,
                "Zero Harvest Amount"
            );
        }
        _arrangeAddliquidityObject(_asset, reward, lpToken0, lpToken1, _router);
        return _addLiquidity(lpToken0, lpToken1, _router);
    }

    function _arrangeAddliquidityObject(
        address _asset,
        address token,
        address lpToken0,
        address lpToken1,
        address _router
    ) internal {
        (uint112 res0, uint112 res1, ) = IUniswapV2Pair(_asset).getReserves();
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = token == lpToken0 ? lpToken1 : lpToken0;
        lpToken0 == token
            ? _swap(
                _calculateSwapInAmount(
                    res0,
                    _chargeFees(token, IERC20(token).balanceOf(address(this)))
                ),
                path,
                _router
            )
            : _swap(
                _calculateSwapInAmount(
                    res1,
                    _chargeFees(token, IERC20(token).balanceOf(address(this)))
                ),
                path,
                _router
            );
    }

    function _swap(
        uint256 amount,
        address[] memory _route,
        address _router
    ) internal {
        IUniswapV2Router02(_router).swapExactTokensForTokens(
            amount,
            0,
            _route,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(
        address lpToken0,
        address lpToken1,
        address _router
    ) internal returns (uint256 lpAmount) {
        uint256 token0Bal = IERC20(lpToken0).balanceOf(address(this));
        uint256 token1Bal = IERC20(lpToken1).balanceOf(address(this));
        if (token0Bal > 0 && token1Bal > 0) {
            (, , lpAmount) = IUniswapV2Router02(_router).addLiquidity(
                lpToken0,
                lpToken1,
                token0Bal,
                token1Bal,
                1,
                1,
                address(this),
                block.timestamp
            );
            uint256 lp0Bal = IERC20(lpToken0).balanceOf(address(this));
            uint256 lp1Bal = IERC20(lpToken1).balanceOf(address(this));
            if (lp0Bal > 0) {
                IERC20(lpToken0).safeTransfer(treasury0, lp0Bal);
            }
            if (lp1Bal > 0) {
                IERC20(lpToken1).safeTransfer(treasury1, lp1Bal);
            }
        } else {
            revert("Not Enough Amount");
        }
    }

    function _chargeFees(
        address token,
        uint256 amount
    ) internal returns (uint256) {
        (uint256 t0, uint256 t1, uint256 remainingAmount) = calculate(amount);
        IERC20(token).safeTransfer(treasury0, t0);
        IERC20(token).safeTransfer(treasury1, t1);
        emit Fees(t0,t1);
        return remainingAmount;
    }

    function calculateShareAmount(
        uint256 amount,
        address _miniChef,
        uint256 _poolId
    ) public view returns (uint256) {
        uint256 supply = totalSupply;
        (uint256 _amount, ) = IMiniChefV2(_miniChef).userInfo(
            _poolId,
            address(this)
        );
        return supply == 0 ? amount : (amount.mul(supply)).div(_amount);
    }

    function calculateWithdrawShare(
        uint256 amount,
        address _miniChef,
        uint256 _poolId
    ) public view returns (uint256) {
        (uint256 _amount, ) = IMiniChefV2(_miniChef).userInfo(
            _poolId,
            address(this)
        );
        return amount.mul(totalSupply).div(_amount);
    }

    function calculate(
        uint256 amount
    ) internal pure returns (uint256, uint256, uint256) {
        require((amount * FEE) >= 10_000);
        return (
            (amount * FEE) / 10_000,
            (amount * FEE) / 10_000,
            (amount * REMAINING_AMOUNT) / 10_000
        );
    }

    function _calculateSwapInAmount(
        uint256 reserveIn,
        uint256 amount
    ) internal pure returns (uint256) {
        return
            Babylonian
                .sqrt(
                    reserveIn.mul(amount.mul(3988000) + reserveIn.mul(3988009))
                )
                .sub(reserveIn.mul(1997)) / 1994;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        INITIAL_CHAIN_ID = chainId;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        balanceOf[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");
        address recoveredAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "INVALID_SIGNER"
        );

        allowance[recoveredAddress][spender] = value;

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            chainId == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    chainId,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}