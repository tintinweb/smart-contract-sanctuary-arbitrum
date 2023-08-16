/**
 *Submitted for verification at Arbiscan on 2023-08-16
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// File: contracts/staking/interfaces/ISnapshottable.sol



pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/staking/Interpolating.sol




pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

contract Interpolating {
    using SafeMath for uint256;

    struct Interpolation {
        uint256 startOffset;
        uint256 endOffset;
        uint256 startScale;
        uint256 endScale;
    }
    uint256 public constant INTERPOLATION_DIVISOR = 1000000;


    function lerp(uint256 startOffset, uint256 endOffset, uint256 startScale, uint256 endScale, uint256 current) public pure returns (uint256) {
        if (endOffset <= startOffset) {
            // If the end is less than or equal to the start, then the value is always endValue.
            return endScale;
        }

        if (current <= startOffset) {
            // If the current value is less than or equal to the start, then the value is always startValue.
            return startScale;
        }

        if (current >= endOffset) {
            // If the current value is greater than or equal to the end, then the value is always endValue.
            return endScale;
        }

        uint256 range = endOffset.sub(startOffset);
        if (endScale > startScale) {
            // normal increasing value
            return current.sub(startOffset).mul(endScale.sub(startScale)).div(range).add(startScale);
        } else {
            // decreasing value requires different calculation
            return endOffset.sub(current).mul(startScale.sub(endScale)).div(range).add(endScale);
        }
    }

    function lerpValue(Interpolation memory data, uint256 current, uint256 value) public pure returns (uint256) {
        return lerp(data.startOffset, data.endOffset, data.startScale, data.endScale, current).mul(value).div(INTERPOLATION_DIVISOR);
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: contracts/staking/interfaces/IStaking.sol





pragma solidity ^0.8.0;


struct UserStake {
    uint256 amount;
    uint256 depositBlock;
    uint256 withdrawBlock;
    uint256 emergencyWithdrawalBlock;

    uint256 lastSnapshotBlockNumber;
}


interface IStaking is ISnapshottable {
    function getStake(address) external view returns (UserStake memory);
    function isPenaltyCollector(address) external view returns (bool);
    function token() external view returns (IERC20);
    function penalty() external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeFor(address account, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function emergencyWithdraw(uint256 amount) external;
    function changeOwner(address newOwner) external;
    function sendPenalty(address to) external returns (uint256);
    function setPenaltyCollector(address collector, bool status) external;
    function getVestedTokens(address user) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);
    function getWithdrawable(address user) external view returns (uint256);
    function getEmergencyWithdrawPenalty(address user) external view returns (uint256);
    function getVestedTokensPercentage(address user) external view returns (uint256);
    function getWithdrawablePercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyPercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyAmountReturned(address user, uint256 amount) external view returns (uint256);

    function getStakersCount() external view returns (uint256);
    function getStakers(uint256 idx) external view returns (address);
    function setStakers(address[] calldata _stakers) external;
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: contracts/staking/Staking.sol



pragma solidity 0.8.19;






//import { SafeERC20 } from '../libraries/SafeERC20.sol';




contract Staking is Ownable, Interpolating, IStaking {
    using SafeMath for uint256;

    // the amount of the tokens used for calculation may need to mature over time
    Interpolation public tokenVesting;
    // over time some of the tokens may be available for early withdrawal
    Interpolation public withdrawalVesting;
    // there may be a penalty for withdrawing everything early
    Interpolation public emergencyWithdrawPenalty;

    mapping(address => UserStake) public stakes;
    address[] public stakers;
    mapping(address => bool) public isPenaltyCollector;
    mapping(address => bool) public isSnapshotter;
    IERC20 public token;
    uint256 public penalty = 0;
    uint256 public minimumStakeToBeListed; // how much token is required to be listed in the stakers variable

    uint256[] public snapshotBlockNumbers;
    // blockNumber => address => amount
    mapping(uint256 => mapping(address => uint256)) public snapshots;
    // blockNumber => bool
    mapping(uint256 => bool) public snapshotExists;

    event Staked(address indexed account, uint256 amount, uint256 stakingTime);
    event Withdrawn(address indexed account, uint256 amount);
    event EmergencyWithdrawn(address indexed account, uint256 amount, uint256 penalty);

    constructor(IERC20 _token, uint256 vestingLength, uint256 _minimumStakeToBeListed) {
        require(address(_token) != address(0), "Token address cannot be 0x0");

        token = _token;
        minimumStakeToBeListed = _minimumStakeToBeListed;

        // by default emergency withdrawal penalty matures from 80% to 0%
        setEmergencyWithdrawPenalty(Interpolation(0, vestingLength, INTERPOLATION_DIVISOR.mul(8).div(10), 0));
        // by default withdrawals mature from 0% to 100%
        setWithdrawalVesting(Interpolation(0, vestingLength, 0, INTERPOLATION_DIVISOR));
        // by default calculation token amount is fully mature immediately
        setTokenVesting(Interpolation(0, 0, INTERPOLATION_DIVISOR, INTERPOLATION_DIVISOR));

        // eliminate the possibility of a real snapshot at idx 0
        snapshotBlockNumbers.push(0);
    }


    ///////////////////////////////////////
    // Core functionality
    ///////////////////////////////////////

    function getStake(address _account) public view override returns (UserStake memory) {
        return stakes[_account];
    }
    function stake(uint256 _amount) public {
        return _stake(msg.sender, msg.sender, _amount);
    }
    function stakeFor(address _account, uint256 _amount) public {
        return _stake(msg.sender, _account, _amount);
    }
    function _stake(address from, address account, uint256 amount) internal {
        require(amount > 0, "Amount must be greater than 0");

        _updateSnapshots(0, type(uint256).max, account);

        uint256 allowance = token.allowance(from, address(this));
        require(allowance >= amount, "Check the token allowance");

        UserStake memory userStake = stakes[account];
        uint256 preStakeAmount = userStake.amount;
        if (userStake.amount == 0) {
            // default case
            userStake.amount = amount;
            userStake.depositBlock = block.number;
            userStake.withdrawBlock = block.number;
            userStake.emergencyWithdrawalBlock = block.number;
        } else {
            // An attacker could potentially stake token into a target account and
            //  to mess with their emergency withdrawal ratios. If we normalize the
            //  deposit time and the emergency withdrawal settings are reasonable,
            //  the victim is not negatively affected and the attacker just loses
            //  funds.

            // lerp the blocks based on existing amount vs added amount
            userStake.depositBlock =             lerp(0, userStake.amount.add(amount), userStake.depositBlock,             block.number, userStake.amount);
            userStake.withdrawBlock =            lerp(0, userStake.amount.add(amount), userStake.withdrawBlock,            block.number, userStake.amount);
            userStake.emergencyWithdrawalBlock = lerp(0, userStake.amount.add(amount), userStake.emergencyWithdrawalBlock, block.number, userStake.amount);
            userStake.amount = userStake.amount.add(amount);
        }
        stakes[account] = userStake;

        emit Staked(account, amount, block.timestamp);

        SafeERC20.safeTransferFrom(token, from, address(this), amount);

        // to prevent dust attacks, only add user as staker if they cross the stake threshold
        if (preStakeAmount < minimumStakeToBeListed && userStake.amount >= minimumStakeToBeListed) {
            // make sure the user can't easily spam himself into the stakers list
            if (stakers.length < 3 || (stakers[stakers.length - 1] != account && stakers[stakers.length - 2] != account && stakers[stakers.length - 3] != account)) {
                stakers.push(account);
            }
        }
    }

    function updateSnapshots(uint256 startIdx, uint256 endIdx) external {
        _updateSnapshots(startIdx, endIdx, msg.sender);
    }
    function _updateSnapshots(uint256 startIdx, uint256 endIdx, address account) internal {
        if (snapshotBlockNumbers.length == 0) {
            return; // early abort
        }

        require(endIdx > startIdx, "endIdx must be greater than startIdx");
        uint256 lastSnapshotBlockNumber = stakes[account].lastSnapshotBlockNumber;
        uint256 lastBlockNumber = snapshotBlockNumbers[snapshotBlockNumbers.length - 1];

        if (stakes[account].amount == 0) {
            stakes[account].lastSnapshotBlockNumber = lastBlockNumber;
            return; // early abort
        }

        // iterate backwards through snapshots
        if (snapshotBlockNumbers.length < endIdx) {
            endIdx = uint256(snapshotBlockNumbers.length).sub(1);
        }
        for (uint256 i = endIdx;  i > startIdx;  --i) {
            uint256 blockNumber = snapshotBlockNumbers[i];

            if (lastSnapshotBlockNumber == blockNumber) {
                break; // done with user
            }

            // address => amount
            mapping(address => uint256) storage _snapshot = snapshots[blockNumber];

            // update the vested amount
            _snapshot[account] = _calculateVestedTokensAt(account, blockNumber);
        }

        // set user as updated
        stakes[account].lastSnapshotBlockNumber = lastBlockNumber;
    }
    function snapshot() external onlySnapshotter {
        if (!snapshotExists[block.number]) {
            snapshotBlockNumbers.push(block.number);
            snapshotExists[block.number] = true;
        }
    }

    function withdraw(uint256 _amount) external {
        _updateSnapshots(0, type(uint256).max, msg.sender);

        return _withdraw(msg.sender, _amount);
    }
    function _withdraw(address account, uint256 _amount) internal {
        require(_amount > 0, "Amount must be greater than 0");

        // cap to deal with frontend rounding errors
        UserStake memory userStake = stakes[account];
        if (userStake.amount < _amount) {
            _amount = userStake.amount;
        }

        uint256 withdrawableAmount = getWithdrawable(account);
        require(withdrawableAmount >= _amount, "Insufficient withdrawable balance");

        userStake.amount = userStake.amount.sub(_amount);
        userStake.withdrawBlock = lerp(0, withdrawableAmount, userStake.withdrawBlock, block.number, _amount);
        stakes[account] = userStake;

        emit Withdrawn(account, _amount);

        SafeERC20.safeTransfer(token, account, _amount);
    }

    function emergencyWithdraw(uint256 _amount) external {
        return _emergencyWithdraw(msg.sender, _amount);
    }
    function _emergencyWithdraw(address account, uint256 _amount) internal {
        require(_amount > 0, "Amount must be greater than 0");

        // cap to deal with frontend rounding errors
        UserStake memory userStake = stakes[account];
        if (userStake.amount < _amount) {
            _amount = userStake.amount;
        }

        // max out the normal withdrawable first out of respect for the user
        uint256 withdrawableAmount = getWithdrawable(account);
        if (withdrawableAmount > 0) {
            if (withdrawableAmount >= _amount) {
                return _withdraw(account, _amount);
            } else {
                _withdraw(account, withdrawableAmount);
                _amount = _amount.sub(withdrawableAmount);
            }
            // update data after the withdraw
            userStake = stakes[account];
        }

        // figure out the numbers for the emergency withdraw
        require(userStake.amount <= _amount, "Insufficient emergency-withdrawable balance");
        userStake.amount = userStake.amount.sub(_amount);
        uint256 returnedAmount = getEmergencyWithdrawPenaltyAmountReturned(account, _amount);
        uint256 _penalty = _amount.sub(returnedAmount);
        userStake.emergencyWithdrawalBlock = lerp(0, userStake.amount, userStake.emergencyWithdrawalBlock, block.number, _amount);

        // account for the penalty
        penalty = penalty.add(_penalty);
        stakes[account] = userStake;

        emit EmergencyWithdrawn(account, _amount, _penalty);

        SafeERC20.safeTransfer(token, account, returnedAmount);
    }


    ///////////////////////////////////////
    // Housekeeping
    ///////////////////////////////////////

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be 0x0");

        transferOwnership(_newOwner);
    }
    function setTokenVesting(Interpolation memory _value) public onlyOwner {
        tokenVesting = _value;
    }
    function setWithdrawalVesting(Interpolation memory _value) public onlyOwner {
        withdrawalVesting = _value;
    }
    function setEmergencyWithdrawPenalty(Interpolation memory _value) public onlyOwner {
        emergencyWithdrawPenalty = _value;
    }
    function sendPenalty(address to) external returns (uint256) {
        require(msg.sender == owner() || isPenaltyCollector[msg.sender], "Only owner or penalty collector can send penalty");

        uint256 _amount = penalty;
        penalty = 0;

        SafeERC20.safeTransfer(token, to, _amount);

        return _amount;
    }
    function setPenaltyCollector(address _collector, bool _status) external onlyOwner {
        isPenaltyCollector[_collector] = _status;
    }
    function setSnapshotter(address _snapshotter, bool _state) external onlyOwner {
        isSnapshotter[_snapshotter] = _state;
    }
    modifier onlySnapshotter() {
        require(isSnapshotter[msg.sender], "Only snapshotter can call this function");
        _;
    }
    function setMinimumStakeToBeListed(uint256 _minimumStakeToBeListed) external onlyOwner {
        minimumStakeToBeListed = _minimumStakeToBeListed;
    }
    function getStakersCount() external view returns (uint256) {
        return stakers.length;
    }
    function getStakers(uint256 idx) external view returns (address) {
        return stakers[idx];
    }
    function setStakers(address[] calldata _stakers) external onlyOwner {
        // reset-stakers function, for dust attack recovery
        stakers = _stakers;
    }


    ///////////////////////////////////////
    // View functions
    ///////////////////////////////////////

    function _calculateVestedTokensAt(address user, uint256 blockNumber) internal view returns (uint256) {
        if (blockNumber < stakes[user].depositBlock) {
            // ideally this should never happen but as a safety precaution..
            return 0;
        }

        return lerpValue(tokenVesting, blockNumber.sub(stakes[user].depositBlock), stakes[user].amount);
    }
    function getVestedTokens(address user) external view returns (uint256) {
        return _calculateVestedTokensAt(user, block.number);
    }
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256) {
        // try to look up snapshot directly and use that
        require(snapshotExists[blockNumber], "No snapshot exists for this block");
        // is the user snapshotted for this?
        if (stakes[user].lastSnapshotBlockNumber >= blockNumber) {
            // use the snapshot
            mapping(address => uint256) storage _snapshot = snapshots[blockNumber];
            return _snapshot[user];
        }

        // no snapshot so we calculate the snapshot as it would have been at that time in the past
        return _calculateVestedTokensAt(user, blockNumber);
    }
    function getWithdrawable(address user) public view returns (uint256) {
        return lerpValue(withdrawalVesting, block.number.sub(stakes[user].withdrawBlock), stakes[user].amount);
    }
    function getEmergencyWithdrawPenalty(address user) external view returns (uint256) {
        // account for allowed withdrawal
        uint256 _amount = stakes[user].amount;
        uint256 withdrawable = getWithdrawable(user);
        if (_amount <= withdrawable) {
            return 0;
        }
        _amount = _amount.sub(withdrawable);
        return lerpValue(emergencyWithdrawPenalty, block.number.sub(stakes[user].withdrawBlock), _amount);
    }
    function getVestedTokensPercentage(address user) external view returns (uint256) {
        return lerpValue(tokenVesting, block.number.sub(stakes[user].depositBlock), INTERPOLATION_DIVISOR);
    }
    function getWithdrawablePercentage(address user) public view returns (uint256) {
        return lerpValue(withdrawalVesting, block.number.sub(stakes[user].withdrawBlock), INTERPOLATION_DIVISOR);
    }
    function getEmergencyWithdrawPenaltyPercentage(address user) external view returns (uint256) {
        // We could account for allowed withdrawal here, but it is likely to cause confusion. It is accounted for elsewhere.
        uint rawValue = lerpValue(emergencyWithdrawPenalty, block.number.sub(stakes[user].withdrawBlock), INTERPOLATION_DIVISOR);
        return rawValue;

        // IGNORED: adjust for allowed withdrawal
        //return rawValue.mul(INTERPOLATION_DIVISOR.sub(getWithdrawablePercentage(user))).div(INTERPOLATION_DIVISOR);

    }
    function getEmergencyWithdrawPenaltyAmountReturned(address user, uint256 _amount) public view returns (uint256) {
        // account for allowed withdrawal
        uint256 withdrawable = getWithdrawable(user);
        if (_amount <= withdrawable) {
            return _amount;
        }
        _amount = _amount.sub(withdrawable);
        return _amount.sub(lerpValue(emergencyWithdrawPenalty, block.number.sub(stakes[user].withdrawBlock), _amount)).add(withdrawable);
    }
}