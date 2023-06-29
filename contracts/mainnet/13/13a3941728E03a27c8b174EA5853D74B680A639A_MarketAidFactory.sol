// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRubiconMarket {
    function cancel(uint256 id) external;

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        bool matching //match "close enough" orders?
    ) external returns (uint256);

    // Get best offer
    function getBestOffer(
        IERC20 sell_gem,
        IERC20 buy_gem
    ) external view returns (uint256);

    function getFeeBPS() external view returns (uint256);

    // get offer
    function getOffer(
        uint256 id
    ) external view returns (uint256, IERC20, uint256, IERC20);

    function sellAllAmount(
        IERC20 pay_gem,
        uint256 pay_amt,
        IERC20 buy_gem,
        uint256 min_fill_amount
    ) external returns (uint256 fill_amt);

    function buyAllAmount(
        IERC20 buy_gem,
        uint256 buy_amt,
        IERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill_amt);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.16;
pragma abicoder v2;

// import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

/// @author rubicon.eth
/// @notice A contract that permissions an admin at initialization to allow for batch-actions on Rubicon Market
/// @notice Helpful for high-frequency market-making in a gas-efficient fashion on Rubicon
/// @notice AMMs will be rekt

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "../interfaces/IRubiconMarket.sol";
import "../interfaces/ISwapRouter.sol";

contract MarketAid is Multicall {
    /// *** Libraries ***
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20 for IERC20;

    /// *** Storage Variables ***

    /// @notice admin
    address public admin;

    /// @notice The Rubicon Market that all market activity is pointed towards
    address public RubiconMarketAddress;

    /// @dev The id of the last StrategistTrade made by any strategist on this contract
    /// @dev This value is globally unique, and increments with every trade
    uint256 internal last_stratTrade_id;

    /// @notice Unique id => StrategistTrade created in market-making calls via placeMarketMakingTrades
    mapping(uint256 => StrategistTrade) public strategistTrades;

    /// @notice Map a strategist to their outstanding order IDs
    mapping(address => mapping(address => mapping(address => uint256[])))
        public outOffersByStrategist;

    /// @notice A mapping of approved strategists to access Pools liquidity
    mapping(address => bool) public approvedStrategists;

    /// @notice Re-entrancy gaurd
    bool locked;

    /// @notice Approve a unique operator who can call a kill-switch to block any OUTFLOWS (excluding withdrawal) while allowing cancels and INFLOWS
    address public killSwitchOperator;

    /// @notice Kill switch status
    bool public killed;

    /// *** Structs ***

    struct order {
        uint256 pay_amt;
        IERC20 pay_gem;
        uint256 buy_amt;
        IERC20 buy_gem;
    }

    struct StrategistTrade {
        uint256 askId;
        uint256 askPayAmt;
        address askAsset;
        uint256 bidId;
        uint256 bidPayAmt;
        address bidAsset;
        address strategist;
        uint256 timestamp;
    }

    /// *** Events ***

    /// @notice Log a new market-making trade placed by a strategist, resulting in a StrategistTrade
    event LogStrategistTrade(
        uint256 strategistTradeID,
        bytes32 askId,
        bytes32 bidId,
        address askAsset,
        address bidAsset,
        uint256 timestamp,
        address strategist
    );

    /// @notice Logs the cancellation of a StrategistTrade
    event LogScrubbedStratTrade(
        uint256 strategistIDScrubbed,
        uint256 assetFill,
        address assetAddress,
        uint256 quoteFill,
        address quoteAddress
    );

    /// @notice Log when an admin wants to pull all ERC20s back to their wallet
    event LogAdminPullFunds(
        address admin,
        address asset,
        uint256 amountOfReward,
        uint256 timestamp
    );

    /// @notice Log when a strategist places a batch market making order
    event LogBatchMarketMakingTrades(address strategist, uint256[] trades);

    /// @notice Log when a strategist requotes an offer
    event LogRequote(
        address strategist,
        uint256 scrubbedOfferID,
        uint256 newOfferID
    );

    /// @notice Log when a strategist batch requotes offers
    event LogBatchRequoteOffers(address strategist, uint256[] scrubbedOfferIDs);

    /// @notice Used for PNL tracking and to track inflows and outflows
    event LogBookUpdate(
        address adminCaller,
        address token,
        int amountChanged,
        uint timestamp
    );

    event LogAtomicArbitrage(
        address indexed caller,
        address indexed assetSold,
        address indexed assetReceived,
        uint256 amountSold,
        uint256 profit,
        uint24 uniPoolFee,
        bool isBuyRubiconFirst,
        uint256 timestamp
    );

    // this is a function to deal with any external swapping of tokens that may occur outside of the market
    // note, this should include any fees that are paid as a part of the swap
    event LogExternalSwap(
        address indexed caller,
        address indexed assetSold,
        address indexed assetReceived,
        uint256 amountSold,
        uint256 amountReceived,
        address venue
    );

    /// *** External Functions ***

    /// @dev native constructor, use initialization above INSTEAD of this constructor, to make this contract "proxy-safe"
    /// @dev Non-proxy safe native constructor for trustless handoff via createMarketAidInstance()
    constructor(address market, address _admin) {
        admin = _admin;
        RubiconMarketAddress = market;
        require(admin != address(0) && RubiconMarketAddress != address(0));
        approvedStrategists[admin] = true;

        /// @dev Approve self for batchBox functionality
        // approvedStrategists[address(this)] = true;
        killed = false;
    }

    /// *** Modifiers ***

    /// @notice Only the admin assigned at initialization may access these sensitive functions
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    /// @notice Only approved strategists can access state mutating functions
    modifier onlyApprovedStrategist() {
        // Admin approves strategists directly on this contract
        require(
            isApprovedStrategist(msg.sender) == true,
            "you are not an approved strategist"
        );
        _;
    }

    /// @notice A function to check whether or not an address is an approved strategist
    function isApprovedStrategist(
        address wouldBeStrategist
    ) public view returns (bool) {
        if (approvedStrategists[wouldBeStrategist] == true) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev Reentrancy gaurd
    modifier beGoneReentrantScum() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    // ** Admin **

    /// @notice Admin-only function to approve a new permissioned strategist
    function approveStrategist(address strategist) public onlyAdmin {
        require(strategist != address(0), "strategist is zero address");
        approvedStrategists[strategist] = true;
    }

    /// @notice Admin-only function to remove a permissioned strategist
    function removeStrategist(address strategist) external onlyAdmin {
        approvedStrategists[strategist] = false;
    }

    /// @notice Admin-only function to assign a kill-switch operator
    function assignKillSwitchOperator(address kso) external onlyAdmin {
        require(kso != address(0), "kill swithcer is zero address");
        killSwitchOperator = kso;
    }

    // *** Kill Switch Funtionality ***
    modifier KillSwitchOperatorOnly() {
        require(
            killSwitchOperator != address(0) &&
                msg.sender == killSwitchOperator,
            "you are not the kso or not assigned"
        );
        _;
    }

    function flipKillSwitchOn() external KillSwitchOperatorOnly {
        killed = true;
    }

    function flipKillSwitchOn(
        address strategistToBailOut,
        address asset,
        address quote
    ) external KillSwitchOperatorOnly {
        killed = true;

        /// @dev also wipe the book for a given strategist optionaly
        uint[] memory data = getOutstandingStrategistTrades(
            asset,
            quote,
            strategistToBailOut
        );
        for (uint i = 0; i < data.length; i++) {
            handleStratOrderAtID(data[i]);
        }
    }

    function flipKillSwitchOff() external {
        require(msg.sender == killSwitchOperator || msg.sender == admin);
        killed = false;
    }

    modifier blockIfKillSwitchIsFlipped() {
        require(!killed, "The switch has been flipped");
        _;
    }

    // *** Internal Functions ***

    /// @notice Internal function to provide the next unique StrategistTrade ID
    function _next_id() internal returns (uint256) {
        last_stratTrade_id++;
        return last_stratTrade_id;
    }

    /// @notice This function results in the removal of the Strategist Trade (bid and/or ask on Rubicon Market) from the books and it being deleted from the contract
    /// @dev The local array of strategist IDs that exists for any given strategist [query via getOutstandingStrategistTrades()] acts as an acitve RAM for outstanding strategist trades
    /// @dev Cancels outstanding orders and manages outstanding Strategist Trades memory accordingly
    function handleStratOrderAtID(uint256 id) internal {
        StrategistTrade memory info = strategistTrades[id];
        address _asset = info.askAsset;
        address _quote = info.bidAsset;

        order memory offer1 = getOfferInfo(info.askId); //ask
        order memory offer2 = getOfferInfo(info.bidId); //bid
        uint256 askDelta = info.askPayAmt.sub(offer1.pay_amt);
        uint256 bidDelta = info.bidPayAmt.sub(offer2.pay_amt);

        // NO ACCOUNTING BUT DO CANCEL THE ORDERS
        // if real
        address _RubiconMarketAddress = RubiconMarketAddress;
        if (info.askId != 0) {
            // if delta > 0 - delta is fill => handle any amount of fill here
            if (askDelta > 0) {
                // not a full fill
                if (askDelta != info.askPayAmt) {
                    IRubiconMarket(_RubiconMarketAddress).cancel(info.askId);
                }
            }
            // otherwise didn't fill so cancel
            else {
                IRubiconMarket(_RubiconMarketAddress).cancel(info.askId);
            }
        }

        // if real
        if (info.bidId != 0) {
            // if delta > 0 - delta is fill => handle any amount of fill here
            if (bidDelta > 0) {
                // not a full fill
                if (bidDelta != info.bidPayAmt) {
                    IRubiconMarket(_RubiconMarketAddress).cancel(info.bidId);
                }
            }
            // otherwise didn't fill so cancel
            else {
                IRubiconMarket(_RubiconMarketAddress).cancel(info.bidId);
            }
        }

        // Delete the order from outOffersByStrategist
        uint256 target = getIndexFromElement(
            id,
            outOffersByStrategist[_asset][_quote][info.strategist]
        );
        uint256[] storage current = outOffersByStrategist[_asset][_quote][
            info.strategist
        ];
        current[target] = current[current.length - 1];
        current.pop(); // Assign the last value to the value we want to delete and pop, best way to do this in solc AFAIK

        emit LogScrubbedStratTrade(id, askDelta, _asset, bidDelta, _quote);
    }

    /// @notice Get information about a Rubicon Market offer and return it as an order
    function getOfferInfo(uint256 id) internal view returns (order memory) {
        (
            uint256 ask_amt,
            IERC20 ask_gem,
            uint256 bid_amt,
            IERC20 bid_gem
        ) = IRubiconMarket(RubiconMarketAddress).getOffer(id);
        order memory offerInfo = order(ask_amt, ask_gem, bid_amt, bid_gem);
        return offerInfo;
    }

    /// @notice A function that returns the index of a uid from an array
    /// @dev uid *must* be in array for the purposes of this contract to *enforce outstanding trades per strategist are tracked correctly* - strategist can only cancel a valid offer
    function getIndexFromElement(
        uint256 uid,
        uint256[] storage array
    ) internal view returns (uint256 _index) {
        bool assigned = false;
        for (uint256 index = 0; index < array.length; index++) {
            if (uid == array[index]) {
                _index = index;
                assigned = true;
                return _index;
            }
        }
        require(assigned, "Didnt Find that element in live list, cannot scrub");
    }

    /// @dev function for infinite approvals of Rubicon Market
    function approveAssetOnMarket(
        address toApprove
    ) private beGoneReentrantScum {
        require(
            RubiconMarketAddress != address(this) &&
                RubiconMarketAddress != address(0),
            "Market Aid not initialized"
        );
        // Approve exchange
        IERC20(toApprove).safeApprove(RubiconMarketAddress, 2 ** 256 - 1);
    }

    /// @notice Low-level gaurd to ensure the market-maker does not trade with themselves
    /// @dev Take a single order pair, BID and ASK and make sure they don't fill with themselves
    function selfTradeProtection(
        uint256 askNum,
        uint256 askDen,
        uint256 bidNum,
        uint256 bidDen
    ) internal pure {
        require(
            // Pure case
            (askDen * bidDen > bidNum * askNum) ||
                /// @dev note that if one order is zero then self-trade is not possible
                (askDen == 0 && askNum == 0) ||
                (bidNum == 0 && bidDen == 0),
            "The trades must not match with self"
        );
    }

    // *** External Functions - Only Approved Strategists ***

    /// @notice Key entry point for strategists to place market-making trades on the Rubicon Order Book
    /// @dev note that this assumes the ERC-20s are sitting on this contract; this is helpful as all fill is returned to this contract from RubiconMarket.sol
    function placeMarketMakingTrades(
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256 askNumerator, // Quote / Asset
        uint256 askDenominator, // Asset / Quote
        uint256 bidNumerator, // size in ASSET
        uint256 bidDenominator, // size in QUOTES
        address recipient
    )
        public
        onlyApprovedStrategist
        blockIfKillSwitchIsFlipped
        returns (uint256 id)
    {
        // Require at least one order is non-zero
        require(
            (askNumerator > 0 && askDenominator > 0) ||
                (bidNumerator > 0 && bidDenominator > 0),
            "one order must be non-zero"
        );

        // *** Low-Level Self Trade Protection ***
        selfTradeProtection(
            askNumerator,
            askDenominator,
            bidNumerator,
            bidDenominator
        );

        address _underlyingAsset = tokenPair[0];
        address _underlyingQuote = tokenPair[1];
        address _RubiconMarketAddress = RubiconMarketAddress;

        // Calculate new bid and/or ask
        order memory ask = order(
            askNumerator,
            IERC20(_underlyingAsset),
            askDenominator,
            IERC20(_underlyingQuote)
        );
        order memory bid = order(
            bidNumerator,
            IERC20(_underlyingQuote),
            bidDenominator,
            IERC20(_underlyingAsset)
        );

        require(
            IERC20(ask.pay_gem).balanceOf(address(this)) > ask.pay_amt &&
                IERC20(bid.pay_gem).balanceOf(address(this)) > bid.pay_amt,
            "Not enough ERC20s to market make this call"
        );

        address input = address(ask.pay_gem);
        if (
            IERC20(input).allowance(address(this), _RubiconMarketAddress) <=
            ask.pay_amt
        ) {
            approveAssetOnMarket(input);
        }
        address _input = address(bid.pay_gem);
        if (
            IERC20(_input).allowance(address(this), _RubiconMarketAddress) <=
            bid.pay_amt
        ) {
            approveAssetOnMarket(_input);
        }

        uint256 newAskID;
        uint256 newBidID;
        // We know one is nonzero, If both orders are non-zero
        if (
            (askNumerator > 0 && askDenominator > 0) &&
            (bidNumerator > 0 && bidDenominator > 0)
        ) {
            // // Place new bid and/or ask
            newAskID = IRubiconMarket(_RubiconMarketAddress).offer(
                ask.pay_amt,
                ask.pay_gem,
                ask.buy_amt,
                ask.buy_gem,
                0,
                true
            );
            newBidID = IRubiconMarket(_RubiconMarketAddress).offer(
                bid.pay_amt,
                bid.pay_gem,
                bid.buy_amt,
                bid.buy_gem,
                0,
                true
            );
        } else if (askNumerator > 0 && askDenominator > 0) {
            newAskID = IRubiconMarket(_RubiconMarketAddress).offer(
                ask.pay_amt,
                ask.pay_gem,
                ask.buy_amt,
                ask.buy_gem,
                0,
                true
            );
        } else {
            newBidID = IRubiconMarket(_RubiconMarketAddress).offer(
                bid.pay_amt,
                bid.pay_gem,
                bid.buy_amt,
                bid.buy_gem,
                0,
                true
            );
        }

        // Strategist trade is recorded so they can get paid and the trade is logged for time
        StrategistTrade memory outgoing = StrategistTrade(
            newAskID,
            ask.pay_amt,
            _underlyingAsset,
            newBidID,
            bid.pay_amt,
            _underlyingQuote,
            recipient,
            block.timestamp
        );

        // Give each trade a unique id for easy handling by strategists
        id = _next_id();
        strategistTrades[id] = outgoing;
        // Allow strategists to easily call a list of their outstanding offers
        outOffersByStrategist[_underlyingAsset][_underlyingQuote][recipient]
            .push(id);

        emit LogStrategistTrade(
            id,
            bytes32(outgoing.askId),
            bytes32(outgoing.bidId),
            outgoing.askAsset,
            outgoing.bidAsset,
            block.timestamp,
            outgoing.strategist
        );
    }

    function placeMarketMakingTrades(
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256 askNumerator, // Quote / Asset
        uint256 askDenominator, // Asset / Quote
        uint256 bidNumerator, // size in ASSET
        uint256 bidDenominator // size in QUOTES
    ) public returns (uint256 id) {
        return
            placeMarketMakingTrades(
                tokenPair,
                askNumerator,
                askDenominator,
                bidNumerator,
                bidDenominator,
                msg.sender
            );
    }

    /// @notice A function to batch together many placeMarketMakingTrades() in a single transaction
    /// @dev this can be used to make an entire liquidity curve in a single transaction
    function batchMarketMakingTrades(
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256[] memory askNumerators, // Quote / Asset
        uint256[] memory askDenominators, // Asset / Quote
        uint256[] memory bidNumerators, // size in ASSET
        uint256[] memory bidDenominators, // size in QUOTES
        address recipient
    ) public onlyApprovedStrategist blockIfKillSwitchIsFlipped {
        /// Note: probably a redundant onlyApprovedStrategistCall?
        require(
            askNumerators.length == askDenominators.length &&
                askDenominators.length == bidNumerators.length &&
                bidNumerators.length == bidDenominators.length,
            "not all order lengths match"
        );
        uint256 quantity = askNumerators.length;

        uint256[] memory trades = new uint256[](quantity);

        for (uint256 index = 0; index < quantity; index++) {
            uint256 id = placeMarketMakingTrades(
                tokenPair,
                askNumerators[index],
                askDenominators[index],
                bidNumerators[index],
                bidDenominators[index],
                recipient
            );
            trades[index] = id;
        }
        emit LogBatchMarketMakingTrades(recipient, (trades));
    }

    function batchMarketMakingTrades(
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256[] memory askNumerators, // Quote / Asset
        uint256[] memory askDenominators, // Asset / Quote
        uint256[] memory bidNumerators, // size in ASSET
        uint256[] memory bidDenominators // size in QUOTES
    ) public {
        return
            batchMarketMakingTrades(
                tokenPair,
                askNumerators,
                askDenominators,
                bidNumerators,
                bidDenominators,
                msg.sender
            );
    }

    /// @notice A function to requote an outstanding order and replace it with a new Strategist Trade
    /// @dev Note that this function will create a new unique id for the requote'd ID due to the low-level functionality
    function requote(
        uint256 id,
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256 askNumerator, // Quote / Asset
        uint256 askDenominator, // Asset / Quote
        uint256 bidNumerator, // size in ASSET
        uint256 bidDenominator, // size in QUOTES
        address recipient
    ) public onlyApprovedStrategist blockIfKillSwitchIsFlipped {
        // 1. Scrub strat trade
        scrubStrategistTrade(id);

        // 2. Place another
        uint256 newOfferID = placeMarketMakingTrades(
            tokenPair,
            askNumerator,
            askDenominator,
            bidNumerator,
            bidDenominator,
            recipient
        );

        emit LogRequote(recipient, id, (newOfferID));
    }

    function requote(
        uint256 id,
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256 askNumerator, // Quote / Asset
        uint256 askDenominator, // Asset / Quote
        uint256 bidNumerator, // size in ASSET
        uint256 bidDenominator
    ) public {
        return
            requote(
                id,
                tokenPair,
                askNumerator,
                askDenominator,
                bidNumerator,
                bidDenominator,
                msg.sender
            );
    }

    /// @notice A function to batch together many requote() calls in a single transaction
    /// @dev Ids and input are indexed through to execute requotes
    /// @dev this can be used to update an entire liquidity curve in a single transaction
    function batchRequoteOffers(
        uint256[] memory ids,
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256[] memory askNumerators, // Quote / Asset
        uint256[] memory askDenominators, // Asset / Quote
        uint256[] memory bidNumerators, // size in ASSET
        uint256[] memory bidDenominators, // size in QUOTES
        address recipient
    ) public onlyApprovedStrategist blockIfKillSwitchIsFlipped {
        require(
            askNumerators.length == askDenominators.length &&
                askDenominators.length == bidNumerators.length &&
                bidNumerators.length == bidDenominators.length &&
                ids.length == askNumerators.length,
            "not all input lengths match"
        );

        // Scrub the orders
        scrubStrategistTrades(ids);

        // Then Batch market make
        batchMarketMakingTrades(
            tokenPair,
            askNumerators,
            askDenominators,
            bidNumerators,
            bidDenominators,
            recipient
        );

        emit LogBatchRequoteOffers(recipient, ids);
    }

    function batchRequoteOffers(
        uint256[] memory ids,
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256[] memory askNumerators, // Quote / Asset
        uint256[] memory askDenominators, // Asset / Quote
        uint256[] memory bidNumerators, // size in ASSET
        uint256[] memory bidDenominators // size in QUOTES
    ) public {
        return
            batchRequoteOffers(
                ids,
                tokenPair,
                askNumerators,
                askDenominators,
                bidNumerators,
                bidDenominators,
                msg.sender
            );
    }

    /// @dev function to requote all the outstanding offers for msg.sender
    /// @dev this can be used to update an entire liquidity curve in a single transaction
    function batchRequoteAllOffers(
        address[2] memory tokenPair, // ASSET, Then Quote
        uint256[] memory askNumerators, // Quote / Asset
        uint256[] memory askDenominators, // Asset / Quote
        uint256[] memory bidNumerators, // size in ASSET
        uint256[] memory bidDenominators // size in QUOTES
    ) external {
        uint[] memory stratIds = getOutstandingStrategistTrades(
            tokenPair[0],
            tokenPair[1],
            msg.sender
        );
        return
            batchRequoteOffers(
                stratIds,
                tokenPair,
                askNumerators,
                askDenominators,
                bidNumerators,
                bidDenominators
            );
    }

    /// @notice Cancel an outstanding strategist offers and return funds to LPs while logging fills
    function scrubStrategistTrade(uint256 id) public {
        require(
            msg.sender == strategistTrades[id].strategist ||
                msg.sender == killSwitchOperator ||
                msg.sender == address(this) ||
                isApprovedStrategist(msg.sender) == true,
            "you are not the strategist that made this order"
        );
        handleStratOrderAtID(id);
    }

    /// @notice Batch scrub outstanding strategist trades and return funds here
    /// @dev this can be used to wipe an entire liquidity curve in a single transaction
    function scrubStrategistTrades(
        uint256[] memory ids
    ) public onlyApprovedStrategist {
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _id = ids[index];
            scrubStrategistTrade(_id);
        }
    }

    function adminRebalanceFunds(
        address assetToSell,
        uint256 amountToSell,
        address assetToTarget
    ) external onlyAdmin returns (uint256 fill_amt) {
        // Market order in one direction to rebalance for market-making
        return
            IRubiconMarket(RubiconMarketAddress).sellAllAmount(
                IERC20(assetToSell),
                amountToSell,
                IERC20(assetToTarget),
                0
            );
    }

    /// @dev This contract may be needed to approve external targets - e.g. use of strategistRebalanceFunds()
    function adminMaxApproveTarget(
        address target,
        address token
    ) external onlyAdmin {
        // Market order in one direction to rebalance for market-making
        IERC20(token).approve(target, type(uint256).max);
    }

    function adminPullAllFunds(address[] memory erc20s) external onlyAdmin {
        address _admin = admin;
        require(_admin != address(0));
        for (uint i = 0; i < erc20s.length; i++) {
            uint amount = IERC20(erc20s[i]).balanceOf(address(this));
            IERC20(erc20s[i]).transfer(_admin, amount);
            emit LogAdminPullFunds(_admin, erc20s[i], amount, block.timestamp);
        }
    }

    /// @notice Best entry point to deposit funds as a market-maker because it enables subgraph fueled PNL tracking
    /// @dev make sure to approve this contract to pull your funds too
    function adminDepositToBook(
        address[] memory erc20s,
        uint[] calldata amounts
    ) external onlyAdmin {
        address _admin = admin;
        require(_admin != address(0) && erc20s.length == amounts.length);
        for (uint i = 0; i < erc20s.length; i++) {
            uint amount = amounts[i];
            IERC20(erc20s[i]).transferFrom(msg.sender, address(this), amount);
            emit LogBookUpdate(
                msg.sender,
                erc20s[i],
                int(amount),
                block.timestamp
            );
        }
    }

    /// @notice Best entry point to deposit funds as a market-maker because it enables subgraph fueled PNL tracking
    function adminWithdrawFromBook(
        address[] memory erc20s,
        uint[] calldata amounts
    ) external onlyAdmin {
        address _admin = admin;
        require(_admin != address(0) && erc20s.length == amounts.length);
        for (uint i = 0; i < erc20s.length; i++) {
            uint amount = amounts[i];
            IERC20(erc20s[i]).transfer(_admin, amount);
            emit LogBookUpdate(
                _admin,
                erc20s[i],
                int(amount) * -1,
                block.timestamp
            );
        }
    }

    /// @dev Market order in one direction to tap an external venue for arbitrage or rebalancing - e.g. UNI here
    function strategistRebalanceFunds(
        address assetToSell,
        uint256 amountToSell,
        address assetToTarget,
        uint24 poolFee //** new variable */
    ) public onlyApprovedStrategist returns (uint256 amountOut) {
        // *** ability to target AMM for rebalancing the book ***
        ISwapRouter swapRouter = ISwapRouter(
            address(0xE592427A0AEce92De3Edee1F18E0157C05861564)
        );
        if (
            IERC20(assetToSell).allowance(address(this), address(swapRouter)) <=
            amountToSell
        ) {
            IERC20(assetToSell).approve(address(swapRouter), amountToSell);
        }
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: assetToSell,
                tokenOut: assetToTarget,
                fee: poolFee,
                recipient: address(this), //keep funds here
                deadline: block.timestamp,
                amountIn: amountToSell,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
        // uni is fee inclusive so we do not need to add in the fee here
        emit LogExternalSwap(
            msg.sender,
            assetToSell,
            assetToTarget,
            amountToSell,
            amountOut,
            address(0xE592427A0AEce92De3Edee1F18E0157C05861564)
        );

        // Return the `amountOut` if the external call is successful
        return amountOut;
    }

    /// @notice Atomic arbitrage between Rubicon and UNI - Rubicon then UNI
    /// @dev Safely fails and does not break execution via try/catch if the arb is not profitable
    /// @dev Uses sellAllAmount on Rubicon with amountToSell and then takes that fill and uses strategistRebalanceFunds for the UNI side of the arb
    function _executeArbitrage0(
        address assetToSell,
        uint256 amountToSell,
        address assetToTarget,
        uint24 poolFee //** new variable */
    ) private returns (uint profit) {
        // Rubicon Leg of the trade
        uint256 fill_amt;
        address _RubiconMarketAddress = RubiconMarketAddress;

        /// @dev approval calls should be done via adminMaxApproveTarget() to avoid reverts
        // IERC20(assetToSell).approve(_RubiconMarketAddress, amountToSell);
        fill_amt = IRubiconMarket(_RubiconMarketAddress).sellAllAmount(
            IERC20(assetToSell),
            amountToSell,
            IERC20(assetToTarget),
            0
        );

        // UNI Leg of the trade
        uint256 amountOut = strategistRebalanceFunds(
            assetToTarget,
            fill_amt,
            assetToSell,
            poolFee
        );

        // If amountOut is greater than amountToSell, then we have a profit and we can return it
        require(amountOut > amountToSell, "Arbitrage not profitable");
        return amountOut - amountToSell;
    }

    function _executeArbitrage1(
        address assetToSell,
        uint256 amountToSell,
        address assetToTarget,
        uint24 poolFee //** new variable */
    ) private returns (uint profit) {
        // UNI Leg of the trade
        uint256 fill_amt = strategistRebalanceFunds(
            assetToSell,
            amountToSell,
            assetToTarget,
            poolFee
        );

        // Rubicon Leg of the trade
        uint256 amountOut = 0;
        address _RubiconMarketAddress = RubiconMarketAddress;
        /// @dev approval calls should be done via adminMaxApproveTarget() to avoid reverts
        // IERC20(assetToTarget).approve(_RubiconMarketAddress, fill_amt); // Add approve function for the asset being sold
        amountOut = IRubiconMarket(_RubiconMarketAddress).sellAllAmount(
            IERC20(assetToTarget),
            fill_amt,
            IERC20(assetToSell),
            0
        );

        // If amountOut is greater than amountToSell, then we have a profit and we can return it
        require(amountOut > amountToSell, "Arbitrage not profitable");
        return amountOut - amountToSell;
    }

    /// @notice Atomic arbitrage between Rubicon and UNI
    /// @dev Safely fails and does not break execution via try/catch if the arb is not profitable
    function captureAtomicArbOrPass(
        address assetToSell,
        uint256 amountToSell,
        address assetToTarget,
        uint24 poolFee, //** new variable */
        bool isBuyRubiconFirst
    ) public onlyApprovedStrategist {
        uint arbProfitIfAny;
        if (isBuyRubiconFirst) {
            arbProfitIfAny = _executeArbitrage0(
                assetToSell,
                amountToSell,
                assetToTarget,
                poolFee
            );
        } else {
            arbProfitIfAny = _executeArbitrage1(
                assetToSell,
                amountToSell,
                assetToTarget,
                poolFee
            );
        }

        // If we have a profit, then we can emit the event
        if (arbProfitIfAny > 0) {
            emit LogAtomicArbitrage(
                msg.sender,
                assetToSell,
                assetToTarget,
                amountToSell,
                arbProfitIfAny,
                poolFee,
                isBuyRubiconFirst,
                block.timestamp
            );
        }
    }

    /// @notice External entrypoint to batch together any arbitrary transactions calling public functions on this contract
    /// @dev notice that this address must be an approved strategist for this functionality to work
    function batchBox(
        bytes[] memory data
    )
        external
        blockIfKillSwitchIsFlipped
        onlyApprovedStrategist
        returns (bytes[] memory results)
    {
        results = this.multicall(data);
    }

    /// *** View Functions ***

    /// @notice The goal of this function is to enable a means to retrieve all outstanding orders a strategist has live in the books
    /// @dev This is helpful to manage orders as well as track all strategist orders (like their RAM of StratTrade IDs) and place any would-be constraints on strategists
    function getOutstandingStrategistTrades(
        address asset,
        address quote,
        address strategist
    ) public view returns (uint256[] memory) {
        // Could make onlyApprovedStrategist for stealth mode optionally 😎
        return outOffersByStrategist[asset][quote][strategist];
    }

    /// @notice returns the total amount of ERC20s (quote and asset) that the strategist has
    ///             in SUM on this contract AND the market place.
    function getStrategistTotalLiquidity(
        address asset,
        address quote,
        address strategist
    )
        public
        view
        returns (uint256 quoteWeiAmount, uint256 assetWeiAmount, bool status)
    {
        require(RubiconMarketAddress != address(0), "bad market address");
        uint256 quoteLocalBalance = IERC20(quote).balanceOf(address(this));
        uint256 assetLocalBalance = IERC20(asset).balanceOf(address(this));

        uint256[] memory stratBook = getOutstandingStrategistTrades(
            asset,
            quote,
            strategist
        );

        uint256 quoteOnChainBalance = 0;
        uint256 assetOnChainBalance = 0;
        if (stratBook.length > 0) {
            for (uint256 index = 0; index < stratBook.length; index++) {
                StrategistTrade memory info = strategistTrades[
                    stratBook[index]
                ];

                // Get ERC20 balances of this strategist on the books
                (uint256 quoteOnChainOrderValue, , , ) = IRubiconMarket(
                    RubiconMarketAddress
                ).getOffer(info.bidId);
                (
                    uint256 assetOnChainOrderValue, // Stack too deep so only sanity check on quote below
                    ,
                    ,

                ) = IRubiconMarket(RubiconMarketAddress).getOffer(info.askId);

                quoteOnChainBalance += quoteOnChainOrderValue;
                assetOnChainBalance += assetOnChainOrderValue;
            }
        }

        if (quoteOnChainBalance > 0 || assetOnChainBalance > 0) {
            status = true;
        }

        quoteWeiAmount = quoteLocalBalance + quoteOnChainBalance;
        assetWeiAmount = assetLocalBalance + assetOnChainBalance;
    }

    // Define a struct to hold the order details (uint256, ERC20, uint256, ERC20)
    struct MarketOffer {
        uint relevantStratTradeId;
        uint256 bidPay;
        uint256 bidBuy;
        uint256 askPay;
        uint256 askBuy;
    }

    /// @notice View function that gets a strategist's outOffersByStrategist, then loops through them and queries the market for the order details via getOffer
    /// @dev This will return the order details for all orders a strategist has live in the books - their on-chain book with all relevant data
    function getStrategistBookWithPriceData(
        address asset,
        address quote,
        address strategist
    ) public view returns (MarketOffer[] memory ordersOnBook) {
        uint256[] memory stratBook = getOutstandingStrategistTrades(
            asset,
            quote,
            strategist
        );

        if (stratBook.length > 0) {
            ordersOnBook = new MarketOffer[](stratBook.length);

            for (uint256 index = 0; index < stratBook.length; index++) {
                StrategistTrade memory info = strategistTrades[
                    stratBook[index]
                ];

                // Get ERC20 balances of this strategist on the books
                (uint256 _bidPay, , uint256 _bidBuy, ) = IRubiconMarket(
                    RubiconMarketAddress
                ).getOffer(info.bidId);
                (uint256 _askPay, , uint256 _askBuy, ) = IRubiconMarket(
                    RubiconMarketAddress
                ).getOffer(info.askId);

                ordersOnBook[index] = MarketOffer({
                    relevantStratTradeId: stratBook[index],
                    bidPay: _bidPay,
                    bidBuy: _bidBuy,
                    askPay: _askPay,
                    askBuy: _askBuy
                });
            }
        }

        return ordersOnBook;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./MarketAid.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice A contract that allows users to easily spawn a Market Aid instance that is permissioned to them and pointed at the relevant Rubicon Market
/// @dev notice this contract can be proxy-wrapped to allow for the upgradeability of future MarketAid's deployed - users can spawn multiple versions all stored in getUserMarketAid
contract MarketAidFactory is ReentrancyGuard {
    address public admin;
    address public rubiconMarket;

    mapping(address => address[]) public userMarketAids;

    bool public initialized;

    event NotifyMarketAidSpawn(address newInstance);

    modifier proxySafeConstructorLike() {
        require(!initialized);
        _;
        require(initialized == true);
    }

    function initialize(address market)
        external
        nonReentrant
        proxySafeConstructorLike
    {
        admin = msg.sender;
        rubiconMarket = market;
        initialized = true;
    }

    /// @notice user can call this function, and easily create a MarketAid instance admin'd to them
    function createMarketAidInstance() external nonReentrant returns (address) {
        /// @dev Note that the caller of createMarketAidInstance() gets spawned an instance of Market Aid they can use
        /// @dev Assigns the admin of the new instance to msg.sender
        MarketAid freshSpawn = new MarketAid(rubiconMarket, msg.sender);

        address _newMarketAidAddy = address(freshSpawn);
        require(_newMarketAidAddy != address(0));

        userMarketAids[msg.sender].push(_newMarketAidAddy);

        emit NotifyMarketAidSpawn(_newMarketAidAddy);

        require(freshSpawn.admin() == msg.sender);

        return _newMarketAidAddy;
    }

    function getUserMarketAids(address user)
        external
        view
        returns (address[] memory)
    {
        return userMarketAids[user];
    }
}