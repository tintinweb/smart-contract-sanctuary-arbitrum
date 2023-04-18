/**
 *Submitted for verification at Arbiscan on 2023-04-18
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts/proxy/[email protected]



// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}


// File @openzeppelin/contracts/math/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity >=0.6.0 <0.8.0;



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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity >=0.6.0 <0.8.0;

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


// File @uniswap/v3-core/contracts/libraries/[email protected]


pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}


// File @uniswap/v3-core/contracts/libraries/[email protected]


pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}


// File contracts/interfaces/IHypervisor.sol


pragma solidity 0.7.6;
pragma abicoder v2;

interface IHypervisor {

  function deposit(
      uint256,
      uint256,
      address,
      address,
      uint256[4] memory minIn
  ) external returns (uint256);

  function withdraw(
    uint256,
    address,
    address,
    uint256[4] memory
  ) external returns (uint256, uint256);

  function compound() external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );

  function compound(uint256[4] memory inMin) external returns (

    uint128 baseToken0Owed,
    uint128 baseToken1Owed,
    uint128 limitToken0Owed,
    uint128 limitToken1Owed
  );


  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory minIn, 
    uint256[4] memory outMin
    ) external;

  function addBaseLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;

  function addLimitLiquidity(
    uint256 amount0, 
    uint256 amount1,
    uint256[2] memory minIn
  ) external;   

  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external returns (
    uint256 base0,
    uint256 base1
  );

  function pullLiquidity(
    uint256 shares,
    uint256[4] memory minAmounts 
  ) external returns(
      uint256 base0,
      uint256 base1,
      uint256 limit0,
      uint256 limit1
  );

  function addLiquidity(
      int24 tickLower,
      int24 tickUpper,
      uint256 amount0,
      uint256 amount1,
      uint256[2] memory inMin
  ) external;

  function currentTick() external view returns (int24 tick);
  
  function tickSpacing() external view returns (int24 spacing);

  function baseLower() external view returns (int24 tick);

  function baseUpper() external view returns (int24 tick);

  function limitLower() external view returns (int24 tick);

  function limitUpper() external view returns (int24 tick);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function deposit0Max() external view returns (uint256);

  function deposit1Max() external view returns (uint256);

  function balanceOf(address) external view returns (uint256);

  function approve(address, uint256) external returns (bool);

  function transferFrom(address, address, uint256) external returns (bool);

  function transfer(address, uint256) external returns (bool);

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
  
  function getBasePosition() external view returns (uint256 liquidity, uint256 total0, uint256 total1);

  function totalSupply() external view returns (uint256 );

  function setWhitelist(address _address) external;
  
  function setFee(uint8 newFee) external;
  
  function removeWhitelisted() external;

  function transferOwnership(address newOwner) external;

}


// File contracts/interfaces/IPositionRouter.sol


pragma solidity 0.7.6;


struct IncreasePositionRequest {
  address account;
  address[] path;
  address indexToken;
  uint256 amountIn;
  uint256 minOut;
  uint256 sizeDelta;
  bool isLong;
  uint256 acceptablePrice;
  uint256 executionFee;
  uint256 blockNumber;
  uint256 blockTime;
  bool hasCollateralInETH;
  address callbackTarget;
}

interface IPositionRouter { 
  function minExecutionFee() external view returns (uint256);
  function minTimeDelayPublic() external view returns (uint256);
  function maxGlobalLongSizes(address) external view returns (uint256);
  function maxGlobalShortSizes(address) external view returns (uint256);
  function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee,
    bytes32 _referralCode,
    address _callbackTarget
  ) external payable returns (bytes32);
  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH,
    address _callbackTarget
  ) external payable returns (bytes32);
  function increasePositionRequests(bytes32) external returns (IncreasePositionRequest calldata);
  function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
  function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}


// File contracts/interfaces/IPositionRouterCallbackReceiver.sol



pragma solidity 0.7.6;

interface IPositionRouterCallbackReceiver {
    function gmxPositionCallback(bytes32 positionKey, bool isExecuted, bool isIncrease) external;
}


// File contracts/interfaces/IRouter.sol



pragma solidity 0.7.6;

interface IRouter {
    function addPlugin(address _plugin) external;
    function approvePlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}


// File contracts/interfaces/IVaultUtils.sol



pragma solidity 0.7.6;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}


// File contracts/interfaces/IVault.sol



pragma solidity 0.7.6;

interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function liquidatePosition(address _account, address _collateralToken, address _indexToken, bool _isLong, address _feeReceiver) external;
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
    function positions(bytes32 positionKey) external view returns (uint256, uint256, uint256, uint256, uint256, int256, uint256);
    function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);
    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) external view returns (uint256);
}


// File contracts/Hedge.sol


pragma solidity 0.7.6;













/*
  If we aims Hedge uses several protocols like GMX, Aave, etc, I think it would be make each contract for each protocol,
  and Hedge keeps his own to be a pure `Vault` and has those contracts as strategy contracts. But for now, be simple.
*/


contract Hedge is IERC20, Context, IPositionRouterCallbackReceiver, Initializable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  struct PositionInfo {
    address collateralToken;
    address indexToken;
    bool isLong;
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    uint256  realisedPnl;
    bool isPositivePnl;
    uint256 lastIncreasedTime;
  }

  struct PositionKeyInfo {        //  positionKey = keccak256(abi.encodePacked(_account=address(this), _collateralToken, _indexToken, _isLong)
    address collateralToken;
    address indexToken;
    bool isLong;
  }

  struct PositionRequestQueue {
    bytes32 requestKey;                 //  requestKey generated by PositionRouter contract of GMX
    address caller;                     //  caller of position request
    bool isWithdrawal;                  //  there may be a liquidate action. in that case, we can't use boolean type to check action type
    address beneficiary;                //  receipient of withdraw action. necessary if `isDeposit` is false
    uint256 amount;                     //  share token amount, would be used in withdraw action. necessary if `isDeposit` is false
  }

  // ERC20 standard variables
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  address private _manager;
  bytes32 private _referralCode;

  // Vault variables
  uint256 public constant PRECISION = 1e36;
  uint256 public constant BASIS_POINTS_DIVISOR = 10000;
  uint256 public hedgeFactor; // 2 = 50% pricipal, 10 = 10% prinicpal required, etc
  IHypervisor public lp; // hypervisor contract
  IERC20 public hedgeToken; // token0 or token1 of hypervisor contract
  IVault public gmxVault;
  address public positionRouter;
  address public gmxRouter;

  uint256 totalAssets;                //  total lp value in terms of token1
  uint256 hedgeTokenBalance;          //  current hedge token balance in this contract
  bytes32[] public positions;         //  positionKey is generated based on `collateralToken`, `indexToken`, `account` and `isLong`.
                                      //   so positions array length can't be large. this is why chosed type as array rather than mapping.
  mapping(bytes32 => PositionKeyInfo) public positionKeyInfo;
  
  //  if balance is not enough when withdrawing, `withdraw` function create position.
  //   so withdrawing action can't be done in one transaction. 
  //   register withdraw amount and address to this variable to reference in the callback function
  //   of execute position action called by GMX keeper 
  PositionRequestQueue public queue;
  bool _isLock;

  event GmxPositionCallbackCalled(
    bytes32 positionKey,
    bool isExecuted,
    bool isIncrease
  );

  modifier onlyManager() {
    require(msg.sender == _manager, "not manager");
    _;
  }

  // we will lock the contract from the moment we create position to the moment we get the callback from GMX keeper for security
  modifier lock() {
    require(_isLock == false, "locked");
    _;
  }

  /**
   * @notice
   *  `hedgeToken` can be ETH, WETH, BTC, LINK, UNI, USDC, USDT, DAI, FRAX.
   *  if we want another token, need to use external DEX to swap.
   * @param lpAddress hypervisor address
   * @param _hedgeToken token address to be used as hedge
   */
  function initialize(
    address lpAddress,
    address _hedgeToken,
    bytes32 _code
  ) external initializer {
    lp = IHypervisor(lpAddress);
    require(lp.token0() == _hedgeToken || lp.token1() == _hedgeToken, "invalid hedge token");
    hedgeToken = IERC20(_hedgeToken);
    gmxVault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    gmxRouter = address(0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064);
    positionRouter = address(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
    hedgeFactor = 10;
    _referralCode = _code;
    
    _manager = msg.sender;
    
    _name = "HedgeVault";
    _symbol = "HVT";
    _decimals = 18;

    //  approve gmx address
    IRouter(gmxRouter).approvePlugin(positionRouter);
    hedgeToken.safeApprove(gmxRouter, uint256(-1));
    hedgeToken.safeApprove(positionRouter, uint256(-1));
  }

  /////////////////////////////////
  /// ERC20 standard functions  ///
  /////////////////////////////////

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

  function decimals() public view returns (uint8) {
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
  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * Requirements:
   *
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for ``sender``'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal { }

  //  need payable to receive ETH when opening position
  receive() external payable {}

  // lp value changes whenever swap made in uniswap. so even if two users provided same lp amount, but at different time,
  //  they should deposit different amount of hedge token. currently, we issues share token amount based on lp value
  //  and when user withdrawing lp token, hedge token amount(10% of lp value) would be different from deposit moment.
  function deposit(uint256 lpAmount) external lock returns (uint256) {
    uint256 principal = lpAmount.mul(getLpValueInToken1()).div(PRECISION); // get lp value of lpAmount in terms of token1
    uint256 requiredHedge = principal.div(hedgeFactor); // get value of hedge token required in terms of token1
    require(requiredHedge > 0, "too small amount");

    uint256 hedgeAmount = requiredHedge; // get hedge amount
    if (lp.token0() == address(hedgeToken)) {
      hedgeAmount = getPriceToken1InToken0().mul(requiredHedge).div(PRECISION);
    }

    lp.transferFrom(msg.sender, address(this), lpAmount);
    hedgeToken.safeTransferFrom(msg.sender, address(this), hedgeAmount);
    
    hedgeTokenBalance = hedgeTokenBalance.add(hedgeAmount);

    _mint(msg.sender, lpAmount);
    return lpAmount;
  }

  /**
   * @notice
   *  create increase position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't open position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param indexToken the address of token to long / short
   * @param collateralToken the address of token to be used as collateral. 
   *  in long position, `collateralToken` should the same as `indexToken`.
   *  in short position, `collateralToken` should be stable coin.
   * @param amountIn: the amount of tokenIn you want to deposit as collateral
   * @param minOut: the min amount of collateralToken to swap for
   * @param sizeDelta: the USD value of the change in position size. decimals is 30
   * @param isLong: if long, true or false
   */
  function createIncreasePosition(
    address indexToken,
    address collateralToken,
    uint256 amountIn,
    uint256 minOut,
    uint256 sizeDelta,
    bool isLong
  ) external payable onlyManager lock {
    if (isLong == true) {
      require(indexToken == collateralToken, "invalid collateralToken");
    }
    require(msg.value >= IPositionRouter(positionRouter).minExecutionFee(), "too low execution fee");
    require(
      sizeDelta > gmxVault.tokenToUsdMin(address(hedgeToken), amountIn),
      "too low leverage"
    );
    require(
      sizeDelta.div(gmxVault.tokenToUsdMin(address(hedgeToken), amountIn)) < gmxVault.maxLeverage().div(BASIS_POINTS_DIVISOR),
      "exceed max leverage"
    );
    // check available amounts to open positions
    _checkPool(isLong, indexToken, collateralToken, sizeDelta);

    /* code to check minimum open position amount in the case of first opening */
    
    address[] memory path;
    if (address(hedgeToken) == collateralToken) {
      path = new address[](1);
      path[0] = address(hedgeToken);
    } else {
      path = new address[](2);
      path[0] = address(hedgeToken);
      path[1] = collateralToken;
    }
    
    uint256 acceptablePrice = gmxVault.getMinPrice(indexToken);
    bytes32 requestKey = IPositionRouter(positionRouter).createIncreasePosition{value: msg.value}(
      path,
      indexToken,
      amountIn,
      minOut,       // it's better to provide minimum output token amount from a caller rather than calculate here
      sizeDelta,    // we can set sizeDelta based on leverage value. need to decide which one is preferred
      isLong,
      acceptablePrice,   // current ETH mark price, check which is more efficient between minPrice and maxPrice
      msg.value,
      _referralCode,
      address(this)
    );

    //  update state variables
    _isLock = true;
    queue.caller = msg.sender;
    queue.requestKey = requestKey;

    bool exists = false;
    bytes32 positionKey = keccak256(abi.encodePacked(
      address(this),
      collateralToken,
      indexToken,
      isLong
    ));
    for (uint8 i = 0; i < positions.length; i++) {
      if (positions[i] == positionKey) {
        exists = true;
        break;
      }
    }
    if (exists == false) {
      positions.push(positionKey);
      positionKeyInfo[positionKey] = PositionKeyInfo(
        collateralToken,
        indexToken,
        isLong
      );
    }
  }

  /**
   * @notice
   *  create decrease position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't close position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param indexToken the address of token to long / short
   * @param collateralToken the address of token to be used as collateral. 
   *  in long position, `collateralToken` should the same as `indexToken`.
   *  in short position, `collateralToken` should be stable coin.
   * @param collateralDelta: the amount of collateral in USD value to withdraw
   * @param sizeDelta: the USD value of the change in position size. decimals is 30
   * @param isLong: if long, true or false
   * @param minOut: the min output token amount you would receive
   */
  function createDecreasePosition(
    address indexToken,
    address collateralToken,
    uint256 collateralDelta,
    uint256 sizeDelta,
    bool isLong,
    uint256 minOut
  ) external payable onlyManager lock {
    if (isLong == true) {
      require(indexToken == collateralToken, "invalid collateralToken");
    }
    require(msg.value >= IPositionRouter(positionRouter).minExecutionFee(), "too low execution fee");
    // require(
    //   sizeDelta > collateralDelta,
    //   "too low leverage"
    // );
    // require(
    //   sizeDelta.div(gmxVault.tokenToUsdMin(address(hedgeToken), amountIn)) < gmxVault.maxLeverage().div(BASIS_POINTS_DIVISOR),
    //   "exceed max leverage"
    // );

    address[] memory path;
    if (address(hedgeToken) == collateralToken) {
      path = new address[](1);
      path[0] = address(hedgeToken);
    } else {
      path = new address[](2);
      path[0] = collateralToken;
      path[1] = address(hedgeToken);
    }
    
    uint256 acceptablePrice = gmxVault.getMinPrice(indexToken);
    bytes32 requestKey = IPositionRouter(positionRouter).createDecreasePosition{value: msg.value}(
      path,
      indexToken,
      collateralDelta,
      sizeDelta,
      isLong,
      address(this),
      acceptablePrice,
      minOut,
      msg.value,
      false,
      address(this)
    );

    //  update state variables
    _isLock = true;
    queue.caller = msg.sender;
    queue.requestKey = requestKey;

    bool exists = false;
    bytes32 positionKey = keccak256(abi.encodePacked(
      address(this),
      collateralToken,
      indexToken,
      isLong
    ));
    for (uint8 i = 0; i < positions.length; i++) {
      if (positions[i] == positionKey) {
        exists = true;
        break;
      }
    }
    if (exists == false) {
      positions.push(positionKey);
      positionKeyInfo[positionKey] = PositionKeyInfo(
        collateralToken,
        indexToken,
        isLong
      );
    }
  }

  /**
   * @notice
   *  this function is generally not used because GMX has a keeper and the keeper detects
   *   `createIncreasePosition` action of `PositionRouter` contract and triggers position execution actions.
   *  But GMX docs says keeper may miss orders by accident,
   *   in that case, needs to trigger execution manually.
   */
  function triggerExecutePositionRequest(bytes32 requestKey, bool isOpen) external onlyManager {
    // Manual execution is possible `minTimeDelayPublic` seconds later after position created.
    uint256 minTimeDelayPublic = IPositionRouter(positionRouter).minTimeDelayPublic();
    IncreasePositionRequest memory request = IPositionRouter(positionRouter).increasePositionRequests(requestKey);
    require(request.blockTime.add(minTimeDelayPublic) <= block.timestamp, "delay");

    if (isOpen) {
      IPositionRouter(positionRouter).executeIncreasePosition(requestKey, address(this));
    } else {
      IPositionRouter(positionRouter).executeDecreasePosition(requestKey, address(this));
    }
    _isLock = false;
  }

  /**
   * @notice
   *  this function is a callback of execute position action from GMX Position Router
   *  can be used for several purpose in the future
   */
  function gmxPositionCallback(bytes32 requestKey, bool isExecuted, bool isIncrease) override external {
    require(msg.sender == address(positionRouter), "invalid caller");
    require(queue.requestKey == requestKey, "invalid request callback");

    _isLock = false;
    if (isExecuted) {
      // update balance of hedge token
      hedgeTokenBalance = hedgeToken.balanceOf(address(this));

      if (queue.isWithdrawal) {
        uint256 hedgeAmount = _estimatedTotalHedgeAmount();
        uint256 required = hedgeAmount.mul(queue.amount).div(totalSupply());
        if (hedgeTokenBalance >= required) {
          try this.withdraw(queue.beneficiary, queue.amount) {} catch {}    // check reentry
        }
      }
    }
    delete queue;

    emit GmxPositionCallbackCalled(requestKey, isExecuted, isIncrease);
  }

  function withdraw(address receipient, uint256 amount) public lock {
    require(receipient != address(0), "zero address");
    // get estimated total hedgeAmount(balance + GMX liquidity)
    uint256 hedgeAmount = _estimatedTotalHedgeAmount();
    uint256 required = hedgeAmount.mul(amount).div(totalSupply());
    if (hedgeTokenBalance >= required) {
      hedgeToken.safeTransfer(msg.sender, required);
      hedgeTokenBalance = hedgeTokenBalance.sub(required);
      lp.transfer(msg.sender, amount);
      _burn(msg.sender, amount);
      return;
    }
    
    //  need to check more
    queue.caller = msg.sender;
    queue.beneficiary = receipient;
    queue.isWithdrawal = true;
    queue.amount = amount;
    _isLock = true;     //  need to check about conflict with callback
    // if we don't have enough balance, need to withdraw from GMX
    uint256 amountToWithdraw = required.sub(hedgeTokenBalance);
    // we need to withdraw hedge token by iterating the opened positions until `amountToWithdraw` amount of token
    for (uint8 i = 0; i < positions.length; i++) {
      if (amountToWithdraw == 0) break;
      bytes32 positionKey = positions[i];
      (uint256 size, , , , , , ) = gmxVault.positions(positionKey);
      
      PositionKeyInfo memory pkInfo = positionKeyInfo[positionKey];

      address[] memory path;
      if (pkInfo.collateralToken == address(hedgeToken)) {
        path = new address[](1);
        path[0] = address(hedgeToken);
      } else {
        path = new address[](2);
        path[0] = pkInfo.collateralToken;
        path[1] = address(hedgeToken);
      }
      uint256 price = pkInfo.isLong ?
        gmxVault.getMaxPrice(pkInfo.indexToken) :
        gmxVault.getMinPrice(pkInfo.indexToken);
      uint256 executionFee = IPositionRouter(positionRouter).minExecutionFee();
      uint256 estimatedHedgeAmount = _estimatedHedgeAmount(positionKey);
      uint256 sizeDelta;
      uint256 collateralDelta;
      if (amountToWithdraw > estimatedHedgeAmount) {
        sizeDelta = size;
        collateralDelta = gmxVault.tokenToUsdMin(address(hedgeToken), estimatedHedgeAmount);
        amountToWithdraw = amountToWithdraw.sub(estimatedHedgeAmount);
      } else {
        //  may need to consider fee deduction
        sizeDelta = amountToWithdraw.mul(size).div(estimatedHedgeAmount);   //  amountToWithdraw * size / netValue
        collateralDelta = gmxVault.tokenToUsdMin(address(hedgeToken), amountToWithdraw);
        amountToWithdraw = 0;
      }
      bytes32 requestKey = IPositionRouter(positionRouter).createDecreasePosition(
        path,
        pkInfo.indexToken,
        collateralDelta,
        sizeDelta,
        pkInfo.isLong,
        address(this),
        price,
        0,    //    need to check again
        executionFee,
        false,
        address(this)
      );
      queue.requestKey = requestKey;
    }
    // need to consider about liquidate option as well in the future
  }

  /**
   * @notice
   *  check the description of `_estimatedTotalHedgeAmount`
   */
  function estimatedTotalHedgeAmount() external view returns (uint256) {
    return _estimatedTotalHedgeAmount();
  }

  function getPriceToken1InToken0() public view returns (uint256) {
    uint256 priceToken0InToken1 = getPriceToken0InToken1();
    require(priceToken0InToken1 != 0, "pool unstable");
    return PRECISION.mul(PRECISION).div(priceToken0InToken1);
  }

  function getPriceToken0InToken1() public view returns (uint256) {
    uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(lp.currentTick());
    uint256 price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), PRECISION, 2**(96 * 2));
    return price;
  }

  function getLpValueInToken1() public view returns(uint256) {
    (uint256 token0, uint256 token1) = lp.getTotalAmounts();
    uint256 totalValue = token0.mul(getPriceToken0InToken1()).add(token1.mul(PRECISION));
    return totalValue.div(lp.totalSupply());
  }

  function getPositionInfo(bytes32 positionKey) external view returns (PositionInfo memory) {
    (
      uint256 size,
      uint256 collateral,
      uint256 averagePrice,
      uint256 entryFundingRate,
      uint256 reserveAmount,
      int256 realisedPnl,
      uint256 lastIncreasedTime
    ) = gmxVault.positions(positionKey);
    
    PositionKeyInfo memory pkInfo = positionKeyInfo[positionKey];
    
    return PositionInfo({
      collateralToken: pkInfo.collateralToken,
      indexToken: pkInfo.indexToken,
      isLong: pkInfo.isLong,
      size: size,
      collateral: collateral,
      averagePrice: averagePrice,
      entryFundingRate: entryFundingRate,
      reserveAmount: reserveAmount,
      realisedPnl: realisedPnl > 0 ? uint256(realisedPnl) : uint256(-realisedPnl),
      isPositivePnl: realisedPnl >= 0,
      lastIncreasedTime: lastIncreasedTime
  });
  }

  function manager() external view returns (address) {
    return _manager;
  }

  function referralCode() external view returns (bytes32) {
    return _referralCode;
  }

  function isLock() external view returns (bool) {
    return _isLock;
  }

  function setHedgeFactor(uint256 _hedgeFactor) external onlyManager {
    require(_hedgeFactor != 0, "zero value");
    hedgeFactor = _hedgeFactor;
  }

  function setReferralCode(bytes32 _code) external onlyManager {
    _referralCode = _code;
  }

  function setLock(bool locked) external onlyManager {
    _isLock = locked;
  }
  
  //////////////////////////////
  ////  Internal Functions  ////
  //////////////////////////////

  /**
   * @notice
   *  check available liquidity before create positions
   */
  function _checkPool(bool isLong, address indexToken, address collateralToken, uint256 sizeDelta) internal view {
    if (isLong) {
      uint256 availableTokens = gmxVault.poolAmounts(indexToken).sub(gmxVault.reservedAmounts(indexToken));
      require(sizeDelta < gmxVault.tokenToUsdMin(indexToken, availableTokens), "max longs exceeded");
      
      uint256 maxGlobalLongSize = IPositionRouter(positionRouter).maxGlobalLongSizes(indexToken);
      if (maxGlobalLongSize != 0) {
        require(
          gmxVault.guaranteedUsd(indexToken).add(sizeDelta) < maxGlobalLongSize,
          "max longs exceeded"
        );
      }
    } else {
      uint256 availableTokens = gmxVault.poolAmounts(collateralToken).sub(gmxVault.reservedAmounts(collateralToken));
      require(sizeDelta < gmxVault.tokenToUsdMin(collateralToken, availableTokens), "max longs exceeded");

      uint256 maxGlobalShortSize = IPositionRouter(positionRouter).maxGlobalShortSizes(indexToken);
      if (maxGlobalShortSize != 0) {
        require(
          gmxVault.globalShortSizes(indexToken).add(sizeDelta) < maxGlobalShortSize,
          "max shorts exceeded"
        );
      }
    } 
  }

  /**
   * @notice
   *  calculate the total potential hedge token amount.
   *  `current balance` + `GMX balance`
   */
  function _estimatedTotalHedgeAmount() internal view returns (uint256) {
    uint256 hedgeAmount = hedgeTokenBalance;
    for (uint8 i = 0; i < positions.length; i++) {
      hedgeAmount = hedgeAmount.add(_estimatedHedgeAmount(positions[i]));
    }
    return hedgeAmount;
  }

  function _estimatedHedgeAmount(bytes32 positionKey) internal view returns (uint256) {
    (uint256 size, uint256 collateral, , uint256 entryFundingRate, , int256 realisedPnl,) = gmxVault.positions(positionKey);

    uint256 cumulativeFundingRate = gmxVault.cumulativeFundingRates(positionKeyInfo[positionKey].indexToken);
    uint256 borrowFee = size.mul(cumulativeFundingRate.sub(entryFundingRate).div(1e6));
    uint256 closeFee = size.mul(gmxVault.marginFeeBasisPoints()).div(BASIS_POINTS_DIVISOR);
    uint256 openFee = closeFee;
    uint256 netValue;
    if (realisedPnl > 0) {
      netValue = collateral.add(uint256(realisedPnl)).sub(openFee).sub(borrowFee).sub(closeFee);
    } else {
      netValue = collateral.sub(uint256(-realisedPnl)).sub(openFee).sub(borrowFee).sub(closeFee);
    }
    
    uint256 hedgeAmount = gmxVault.usdToTokenMin(address(hedgeToken), netValue);

    return hedgeAmount;
  }

}