/**
 *Submitted for verification at Arbiscan on 2023-04-14
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
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

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/StakeDualToken.sol


pragma solidity ^0.8.0;






interface ITracker {
    function burn(address _addr, uint256 _amount) external ;
    function mint(address _addr, uint256 _amount) external ;
}

contract StakingDual is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token ,uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amountRosx, uint256 amountERosx);
    event NewRewardPerSecond(uint256[] rewardPerSecond);
    event EmergencyRewardWithdraw(address indexed owner, uint256[]  aount);

    // Info of each user.
    struct UserInfo {
        uint256 amountRosx; // How many tokens the user has provided.
        uint256 amountERosx;
        uint256 lastDepositedTime;
        uint256 point;
        uint256 lock;
    }

    // Info of pool.
    struct PoolInfo {
        uint256 startTime;
        uint256 lastTimeReward; // Last time  that token distribution occurs.
        // uint256 accTokenPerShare; // Accumulated token per share, times 1e12.
        // uint256 tokenPerSecond; //  token tokens distribution per second.
        uint256 totalStakeRosx; // total amount staked on Pool
        uint256 totalStakeERosx;
        uint256 totalPoint;
        uint256 rewardEndTime; // The time when token distribution ends.
    }

    struct RewardInfo {
        IERC20 rwToken;
        uint256 tokenPerSecond; // Accumulated token per share, times 1e12.
        uint256 accTokenPerShare; //  token tokens distribution per second.
        //uint256 accTokenPerShareDebt;
    }

    struct PendingReward {
        uint256 rewardDebt;
        uint256 rewardPending;
    }

    RewardInfo[] public rewardInfo;
    IERC20 public immutable rosx;
    IERC20 public immutable eRosx;
    address public stakeTracker;
    // Info of pool.
    PoolInfo public poolInfo;
    // Info of user that stakes tokens.
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint256) public addrStake;
    mapping(address => mapping(IERC20 => PendingReward)) public rewardPending;
    mapping(address => bool) private permission;

    constructor(IERC20 _rosx, IERC20 _eRosx) {
        require(address(_rosx) != address(0), "zeroAddr");
        require(address(_eRosx) != address(0), "zeroAddr");
        rosx = _rosx;
        addrStake[address(_rosx)] = 1;
        eRosx = _eRosx;
        addrStake[address(_eRosx)] = 2;
    }

    modifier onlyPermission() {
        require(permission[msg.sender], "NOT_THE_PERMISSION");
        _;
    }

    // Create a new pool. Can only be called by the owner.
    function create(
        uint256 _startTime,
        uint256 _rewardEndTime
    ) public onlyOwner {
        poolInfo = 
            PoolInfo({
                startTime: _startTime,
                lastTimeReward: _startTime,
                totalStakeRosx: 0,
                totalStakeERosx: 0,
                totalPoint: 0,
                rewardEndTime: _rewardEndTime
            });
    }

    function addReward(IERC20 _rwToken,  uint256 _tokenPerSecond) public onlyOwner {
        updatePool(); 
        rewardInfo.push(RewardInfo ({
            rwToken: _rwToken,
            tokenPerSecond: _tokenPerSecond,
            accTokenPerShare: 0
        }));
    }

    /*
     * @notice Return reward multiplier over the given _from to _to time.
     * @param _from: time to start
     * @param _to: time to finish
     * @param _rewardEndTime: time end to reward
     */
    function _getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _rewardEndTime
    ) public pure returns (uint256) {
        if (_to <= _rewardEndTime) {
            return _to - _from;
        } else if (_from >= _rewardEndTime) {
            return 0;
        } else {
            return _rewardEndTime - _from;
        }
    }

    // View function to see pending token on frontend.
    function pendingToken(address _user, uint256  _indexRw) external view returns (uint256 pendind, uint256 time, uint256 share  , uint256 pending , uint256 shareAF, uint256 shareBF ) {
        uint256 lpSupply = poolInfo.totalStakeRosx.add(poolInfo.totalStakeERosx).add(poolInfo.totalPoint);
        uint256 accTokenPerShare = rewardInfo[_indexRw].accTokenPerShare;
        uint256 tokenReward;
        uint256 test = accTokenPerShare;
        if (block.timestamp > poolInfo.lastTimeReward && lpSupply != 0) {
            uint256 multiplier = _getMultiplier(poolInfo.lastTimeReward, block.timestamp, poolInfo.rewardEndTime);
            tokenReward = multiplier.mul(rewardInfo[_indexRw].tokenPerSecond);
            accTokenPerShare = accTokenPerShare.add((tokenReward.mul(1e12)).div(lpSupply));
        }
        PendingReward memory pendingReward = rewardPending[_user][rewardInfo[_indexRw].rwToken];
        UserInfo memory user = userInfo[_user];
        require(((user.amountRosx.add(user.amountERosx).add(user.point)).mul(accTokenPerShare).div(1e12)).sub(pendingReward.rewardDebt).add(pendingReward.rewardPending) > 0 , "falseiii");
        return (((user.amountRosx.add(user.amountERosx).add(user.point)).mul(accTokenPerShare).div(1e12)).sub(pendingReward.rewardDebt).add(pendingReward.rewardPending),  block.timestamp, accTokenPerShare , pendingReward.rewardPending, tokenReward.mul(1e12).div(lpSupply), test);
    }

    function compound(bool[] calldata _isClaim , bool[] calldata _isCompound) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountRosxBf = user.amountRosx;
        uint256 amountERosxBf = user.amountERosx;
        updatePool();
        for(uint i=0; i<rewardInfo.length; i++) {
            PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
            uint256 pending = ((amountRosxBf.add(amountERosxBf).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12).sub(pendingReward.rewardDebt);
            if(addrStake[address(rewardInfo[i].rwToken)] == 1 || addrStake[address(rewardInfo[i].rwToken)] == 2 ) {
                if(_isCompound[i]) {
                    user.lastDepositedTime = block.timestamp;
                    ITracker(stakeTracker).mint(address(msg.sender), pendingReward.rewardPending.add(pending));
                    if(addrStake[address(rewardInfo[i].rwToken)] == 1) {
                        user.amountRosx = user.amountRosx.add(pendingReward.rewardPending).add(pending);
                        pool.totalStakeRosx = pool.totalStakeRosx.add(pendingReward.rewardPending).add(pending);
                        emit Deposit(msg.sender, address(rosx), pendingReward.rewardPending.add(pending));
                        pendingReward.rewardPending = 0;
                    } else {
                        user.amountERosx = user.amountERosx.add(pendingReward.rewardPending).add(pending);
                        pool.totalStakeERosx = pool.totalStakeERosx.add(pendingReward.rewardPending).add(pending);
                        emit Deposit(msg.sender, address(eRosx), pendingReward.rewardPending.add(pending));
                        pendingReward.rewardPending = 0;
                    }
                } else if(_isClaim[i]) {
                    rewardInfo[i].rwToken.transfer(msg.sender, pendingReward.rewardPending.add(pending));
                    pendingReward.rewardPending = 0;
                    
                } else {
                    pendingReward.rewardPending =pendingReward.rewardPending.add(pending);
                }

            } else {
                if(_isClaim[i]) {
                    rewardInfo[i].rwToken.transfer(msg.sender, pendingReward.rewardPending.add(pending));
                    pendingReward.rewardPending = 0;
                } else {
                    pendingReward.rewardPending = pendingReward.rewardPending.add(pending);
                }
            }
        }

        for(uint i=0; i<rewardInfo.length; i++) {
            PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
            pendingReward.rewardDebt = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12);
        }
    }

    function getPoolInfo()
        public
        view
        returns (
            uint256 startTime,
            uint256 lastTimeReward,
            uint256 totalStakeRosx,
            uint256 totalStakeERosx,
            uint256 rewardEndTime
        )
    {
        return (
            poolInfo.startTime,
            poolInfo.lastTimeReward,
            poolInfo.totalStakeRosx,
            poolInfo.totalStakeERosx,
            poolInfo.rewardEndTime
        );
    }

    function getUserInfo( address _user)
        public
        view
        returns (
            uint256 amountRosx,
            uint256 amountERosx,
            uint256 lastDepositedTime,
            uint256 point,
            uint256 lockAmount
        )
    {
        return (
            userInfo[_user].amountRosx,
            userInfo[_user].amountERosx,
            userInfo[_user].lastDepositedTime,
            userInfo[_user].point,
            userInfo[_user].lock
        );
    }

    function getTime() public view returns (uint256 time) {
        return block.timestamp;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.timestamp <= pool.lastTimeReward) {
            return;
        }
        uint256 lpSupply = pool.totalStakeRosx.add(pool.totalStakeERosx).add(pool.totalPoint);
        if (lpSupply == 0) {
            pool.lastTimeReward = block.timestamp;
            for(uint i=0; i<rewardInfo.length; i++) {
                rewardInfo[i].accTokenPerShare = 0;
            }
            return;
        }
        uint256 multiplier = _getMultiplier(pool.lastTimeReward, block.timestamp, pool.rewardEndTime);
        for(uint i=0; i<rewardInfo.length; i++) {
            uint256 tokenReward = multiplier.mul(rewardInfo[i].tokenPerSecond);
            rewardInfo[i].accTokenPerShare = rewardInfo[i].accTokenPerShare.add((tokenReward.mul(1e12)).div(lpSupply));
        }
        pool.lastTimeReward = block.timestamp;
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param __index: index of pool 1: 
     * @param _amount: amount to deposit
     */
    function deposit(uint256 _amount, uint256 _index) public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amountRosx + user.amountERosx > 0) {
            for(uint i=0; i<rewardInfo.length; i++) {
                PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
                uint256 pending = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12).sub(pendingReward.rewardDebt);
                if (pending > 0) {
                    pendingReward.rewardPending = pendingReward.rewardPending.add(pending);
                }
                pendingReward.rewardDebt = ((user.amountRosx.add(user.amountERosx).add(user.point).add(_amount)).mul(rewardInfo[i].accTokenPerShare)).div(1e12);
            }
        }
        if (_amount > 0) {
            user.lastDepositedTime = block.timestamp;
            ITracker(stakeTracker).mint(address(msg.sender), _amount);
            if(_index == 1) {
                rosx.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amountRosx = user.amountRosx.add(_amount);
                pool.totalStakeRosx =  pool.totalStakeRosx.add(_amount);
                emit Deposit(msg.sender, address(rosx), _amount);
            } else {
                eRosx.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amountERosx = user.amountERosx.add(_amount);
                pool.totalStakeERosx = pool.totalStakeERosx.add(_amount);
                emit Deposit(msg.sender, address(eRosx), _amount);
            }
        }
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw
     */
    function withdraw(uint256 _amount, uint256 _index) public {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(_amount > 0, "withdraw: amount > 0");
        if (_index == 1) {
            require(user.amountRosx >= user.lock.add(_amount), "withdraw: amount not enough");
        } else {
            require(user.amountERosx >= _amount, "withdraw: amount not enough");
        }

        updatePool();
        for(uint i=0; i<rewardInfo.length; i++) {
            PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
            uint256 pending = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12).sub(pendingReward.rewardDebt);
            if (pending > 0) {
                pendingReward.rewardPending = pendingReward.rewardPending.add(pending);
            }
            pendingReward.rewardDebt = ((user.amountRosx.add(user.amountERosx).add(user.point).sub(_amount)).mul(rewardInfo[i].accTokenPerShare)).div(1e12);
        }

        ITracker(stakeTracker).burn(address(msg.sender), _amount);
        if (_index == 1) {
            rosx.safeTransfer(address(msg.sender), _amount);
            user.amountRosx = user.amountRosx.sub(_amount);
            pool.totalStakeRosx = pool.totalStakeRosx.sub(_amount);
            emit Withdraw(msg.sender, address(rosx), _amount);
        } else {
            eRosx.safeTransfer(address(msg.sender), _amount);
            user.amountERosx = user.amountERosx.sub(_amount);
            pool.totalStakeERosx = pool.totalStakeERosx.sub(_amount);
            emit Withdraw(msg.sender, address(eRosx), _amount);
        }
    }

    function claim(bool[] calldata _isClaim) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        for(uint i=0; i<rewardInfo.length; i++) {
            PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
            uint256 pending = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12).sub(pendingReward.rewardDebt);
            if(_isClaim[i]) {
                if (pendingReward.rewardPending.add(pending) > 0) { 
                    rewardInfo[i].rwToken.transfer(msg.sender, pendingReward.rewardPending.add(pending));
                    pendingReward.rewardPending = 0;
                }
            } else {
                pendingReward.rewardPending = pendingReward.rewardPending.add(pending);
            }
            pendingReward.rewardDebt = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12);
        }
    }

    /*
     * @notice Update reward per second, start time , endTime 
     * @dev Only callable by owner.
     * @param _startTime: start time reward pool
     * @param _endTime: end time reward pool
     * @param _rewardPerSecond: the reward per second
     */
    function updateReward(uint256 _startTime, uint256 _endTime, uint256[] calldata _rewardPerSeconds) external onlyOwner {
        require(block.timestamp >= poolInfo.rewardEndTime, "Time invalid");
        updatePool();

        poolInfo.startTime = _startTime;
        poolInfo.rewardEndTime = _endTime;
        poolInfo.lastTimeReward = _startTime;
        for(uint i=0; i<_rewardPerSeconds.length; i++) {
            rewardInfo[i].tokenPerSecond = _rewardPerSeconds[i];
        }
        emit NewRewardPerSecond(_rewardPerSeconds);
    }

    function updatePointUsers(address[] calldata _users, 
            uint256[] calldata _points, 
            uint256 _totalPoint) 
            external 
            onlyPermission 
    {
        updatePool();
        poolInfo.totalPoint = _totalPoint;
        for(uint i=0; i<_users.length; i++) {
            for(uint j=0; j<rewardInfo.length; j++) {
                UserInfo storage user = userInfo[msg.sender];
                PendingReward storage pendingReward = rewardPending[_users[i]][rewardInfo[j].rwToken];
                uint256 pending = ((user.amountRosx.add(user.amountERosx).add(user.point)).mul(rewardInfo[i].accTokenPerShare)).div(1e12).sub(pendingReward.rewardDebt);
                if (pending > 0) {
                    pendingReward.rewardPending =   pendingReward.rewardPending.add(pending);
                }
                pendingReward.rewardDebt = ((user.amountRosx.add(user.amountERosx).add(user.point).add(_points[i])).mul(rewardInfo[i].accTokenPerShare)).div(1e12);
                user.point = _points[i];
                user.lastDepositedTime = block.timestamp;
            }
        }
    }

    function lock(address _addr, uint256 _amount) external onlyPermission returns (bool) {
        UserInfo storage user = userInfo[_addr];
        if(user.lock + _amount <= user.amountRosx) {
             user.lock += _amount;
            return true;
        }
        return false;
    }

    function unLock(address _addr, uint256 _amount) external onlyPermission returns (bool) {
        UserInfo storage user = userInfo[_addr];
        if(user.lock >= _amount) {
            user.lock -= _amount;
            return true;
        }
        return false;
    }

    function setStakeTracker(address _addr) external onlyOwner {
        stakeTracker = _addr;
    }

    function setPermission(address _permission, bool _enabled) external onlyOwner {
        permission[_permission] = _enabled;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        poolInfo.rewardEndTime = block.timestamp;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256[] calldata _amount) external onlyOwner {
        for(uint i=0; i<_amount.length; i++) {
            rewardInfo[i].rwToken.transfer(address(msg.sender), _amount[i]);
        }
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {

        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];

        rosx.safeTransfer(address(msg.sender), (user.amountRosx -user.lock));
        eRosx.safeTransfer(address(msg.sender), user.amountERosx);

        ITracker(stakeTracker).burn(address(msg.sender), user.amountRosx - user.lock + user.amountERosx);

        
        pool.totalStakeRosx -= (user.amountRosx - user.lock);
        pool.totalStakeERosx -= user.amountERosx;

        emit EmergencyWithdraw(msg.sender, user.amountRosx -user.lock, user.amountERosx);

        pool.totalPoint -= user.point;
        user.amountRosx = user.lock;
        user.amountERosx = 0;
        user.point = 0;
        for(uint i=0; i<rewardInfo.length; i++) {
            PendingReward storage pendingReward = rewardPending[msg.sender][rewardInfo[i].rwToken];
            pendingReward.rewardDebt = 0;
            pendingReward.rewardPending = 0;
        }
    }
}