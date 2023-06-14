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
pragma solidity 0.8.15;
import "./PairsStorageInterface.sol";
import "./StorageInterface.sol";
import "./CallbacksInterface.sol";

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) external returns (uint256);

    function getPrice(
        OrderType,
        bytes[] calldata,
        StorageInterface.Trade memory
    ) external returns (uint, uint256);

    function fulfill(uint256 orderId, uint256 price) external;

    function pairsStorage() external view returns (PairsStorageInterface);

    function tokenPriceUSDT() external returns (uint);

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) external returns (uint256);

    function linkFee(uint, uint) external view returns (uint);

    function orders(uint) external view returns (uint, OrderType, uint, bool);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    function getPairForIndex(
        uint256 _pairIndex
    ) external view returns (string memory, string memory);

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface CallbacksInterface {
    struct AggregatorAnswer {
        uint orderId;
        uint256 price;
        uint spreadP;
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeOpenOrderCallback(AggregatorAnswer memory) external;

    function executeCloseOrderCallback(AggregatorAnswer memory) external;

    function updateSlCallback(AggregatorAnswer memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IVester {
    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(
        address _account
    ) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function transferredCumulativeRewards(
        address _account
    ) external view returns (uint256);

    function cumulativeRewardDeductions(
        address _account
    ) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function depositForAccount(
        address _creditor,
        address _sender,
        uint256 _amount
    ) external returns (uint256);

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external;

    function setTransferredcumulativeRewards(
        address _account,
        uint256 _amount
    ) external;

    function setCumulativeRewardDeductions(
        address _account,
        uint256 _amount
    ) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(
        address _account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface LimitOrdersInterface {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterface.LimitOrder order;
    }
    //MOMENTUM = STOP
    //REVERSAL = LIMIT
    //LEGACY = MARKET
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairInfoInterface {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (USDT)
    ) external returns (uint); // 1e18 (USDT)

    function getAccFundingFeesLong(uint pairIndex) external view returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairsStorageInterface {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairSpreadP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupMaxCollateral(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUSDT(uint) external view returns (uint);

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint);

    function incr() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PoolInterface {
    function increaseAccTokens(uint) external;
}

// SPDX-License-Identifier: MITUSDT
pragma solidity 0.8.15;
import "./TokenInterface.sol";
import "./AggregatorInterfaceV6_2.sol";
import "./UniswapRouterInterfaceV5.sol";
import "./VaultInterface.sol";
import "./PoolInterface.sol";

interface StorageInterface {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal; // 1e18
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUSDT; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (USDT or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256);
    
    function gov() external view returns (address);

    function dev() external view returns (address);

    function USDT() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function linkErc677() external view returns (TokenInterface);

    function tokenUSDTRouter() external view returns (UniswapRouterInterfaceV5);

    function tempTradeStatus(address _trader,uint256 _pairIndex,uint256 _index) external view returns (bool);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (VaultInterface);

    function pool() external view returns (PoolInterface);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUSDT(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function tradeTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function positionSizeTokenDynamic(uint, uint) external view returns (uint);

    function maxSlP() external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingLimitOrder(PendingLimitOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function currentPercentProfit(
        uint,
        uint,
        bool,
        uint
    ) external view returns (int);

    function reqID_pendingLimitOrder(
        uint
    ) external view returns (PendingLimitOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingLimitOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint) external;

    function getLeverageUnlocked(address) external view returns (uint);

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function maxOpenLimitOrdersPerPair() external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function maxTradesPerBlock() external view returns (uint);

    function tradesPerBlock(uint) external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function maxGainP() external view returns (uint);

    function defaultLeverageUnlocked() external view returns (uint);

    function openInterestUSDT(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function traders(address) external view returns (Trader memory);

    function keeperForOrder(uint256) external view returns (address);

    function accPerOiOpen(
        address,
        uint,
        uint
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface TokenInterface {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface UniswapRouterInterfaceV5 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface VaultInterface {
    function sendUSDTToTrader(address, uint) external;

    function receiveUSDTFromTrader(address, uint, uint, bool) external;

    function currentBalanceUSDT() external view returns (uint);

    function distributeRewardUSDT(uint, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";
import "./interfaces/IVester.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITradingVault {
    function deposit(uint _amount, address _user) external;
}

contract NarwhalPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contracts & Addresses
    StorageInterface public immutable storageT;
    address public USDT;
    address public narToken;
    address public esToken;
    address public govFund;
    address public Vester;
    address public TradingVault;
    uint256 public MAX_INT = 2 ** 256 - 1;

    address public pendingGovFund;
    // Pool variables for NAR
    uint256 public accTokensPernarToken;
    uint256 public accUSDTPernarToken;
    uint256 public totalDeposited;
    uint256 public totalUSDTRewardsIncrement;

    // Mappings
    mapping(address => UserNwxRecords) public usernarrecords;
    mapping(address => bool) public allowedContracts;
    mapping(address => uint256) public cumulativeRewards;
    mapping(address => uint256) public averageStakedAmounts;
    mapping(address => mapping(address => uint256)) public depositBalances;
    mapping(address => uint256) public stakedAmounts;
    mapping(address => bool) public isTokenWhitelisted;
    mapping(address => uint256) public totalDepositedForToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 365 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    //Change back to 72 hours !!
    uint public withdrawTimelock = 1 minutes; // time
    bool public withdrawTimelockEnabled = false;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    struct UserNwxRecords {
        uint256 narDebtUSDT;
        uint256 amountInLockup;
        uint256 narLocked;
        uint256 esnarLocked;
        uint256 depositTimestamp;
    }

    // Pool stats
    uint256 public rewardsToken; // 1e18
    uint256 public rewardsUSDT; // usdtDecimals

    // Events
    event AddressUpdated(string name, address a);
    event ContractAllowed(address a, bool allowed);
    event RewardsDurationSet(uint256 rewardsDuration);
    event RewardsSet(uint256 rewards);

    constructor(address _tradingStorage, StorageInterface _storageT) {
        require(_tradingStorage != address(0), "ADDRESS_0");
        allowedContracts[_tradingStorage] = true;
        govFund = msg.sender;
        storageT = _storageT;
    }

    // GOV => UPDATE VARIABLES & MANAGE PAIRS

    // 0. Modifiers
    modifier onlyGov() {
        require(msg.sender == govFund, "GOV_ONLY");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // ONLY FOR DECIMAL 18 tokens
    function setTokenWhitelisted(address _token, bool _status) external onlyGov {
        require(_token == narToken || _token == esToken, "Invalid token");
        isTokenWhitelisted[_token] = _status;
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyGov {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        require(_rewardsDuration >= 183 days && _rewardsDuration <= 730 days, "Out of range");
        rewardsDuration = _rewardsDuration;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsDurationSet(_rewardsDuration);
    }

    function notifyRewardAmount(uint256 reward) external onlyGov updateReward(address(0)) {
        
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        IERC20(address(esToken)).safeTransferFrom(msg.sender, address(this), reward);
        uint balance = IERC20(address(esToken)).balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsSet(reward);
    }

    // Set addresses
    function setPendingGovFund(address _govFund) external onlyGov {
        require(_govFund != address(0), "ADDRESS_0");
        pendingGovFund = _govFund;
    }

    function confirmGovFund() external onlyGov {
        govFund = pendingGovFund;
        emit AddressUpdated("govFund", govFund);
    }

    function setVester(address _vester) external onlyGov {
        require(_vester != address(0), "ADDRESS_0");
        Vester = _vester;
        emit AddressUpdated("Vester", _vester);
    }

    function setEsToken(address _esToken) external onlyGov {
        require(address(_esToken) != address(0), "ADDRESS_0");
        esToken = _esToken;
        emit AddressUpdated("estoken", address(_esToken));
    }

    function setNARToken(address _narToken) external onlyGov {
        require(address(_narToken) != address(0), "ADDRESS_0");
        narToken = _narToken;
        emit AddressUpdated("nextoken", address(_narToken));
    }

    function setUSDT(address _USDT) external onlyGov {
        require(_USDT != address(0), "ADDRESS_0");
        USDT = _USDT;
        emit AddressUpdated("token", _USDT);
    }

    function setWithdrawTimelock(uint _withdrawTimelock) external onlyGov {
        require(_withdrawTimelock > 1 days, "Should be above 1 day");
        withdrawTimelock = _withdrawTimelock;
    }
    
    function setWithdrawTimelockEnabled() external onlyGov {
        withdrawTimelockEnabled = !withdrawTimelockEnabled;
    }

    function setTradingVault(address _tradingVault) external onlyGov {
        require(address(_tradingVault) != address(0), "ADDRESS_0");
        TradingVault = _tradingVault;
        emit AddressUpdated("token", address(_tradingVault));
    }

    function addAllowedContract(address c) external onlyGov {
        require(c != address(0), "ADDRESS_0");
        allowedContracts[c] = true;
        emit ContractAllowed(c, true);
    }

    function removeAllowedContract(address c) external onlyGov {
        require(c != address(0), "ADDRESS_0");
        allowedContracts[c] = false;
        emit ContractAllowed(c, false);
    }

    function increaseAccTokens(uint256 _amount) external {
        require(allowedContracts[msg.sender], "ONLY_ALLOWED_CONTRACTS");
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), _amount);

        if (totalDeposited > 0) {
            accUSDTPernarToken += (_amount * 1e18) / totalDeposited;
            totalUSDTRewardsIncrement += _amount;
        }
    }

    function totalSupply() external view returns (uint256) {
        return totalDeposited;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 stakedToken = userTotalBalance(account);
        return stakedToken;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalDeposited == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalDeposited)
            );
    }

    function earned(address account) public view returns (uint256) {
        uint256 stakedToken = userTotalBalance(account);
        return stakedToken.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getUserTokenBalance(
        address _account
    ) external view returns (uint256) {
        return (stakedAmounts[_account]);
    }

    function getReservedAmount(address _account) external view returns (uint256) {
        UserNwxRecords storage unar = usernarrecords[_account];
        return (unar.amountInLockup);
    }

    function pendingRewardUSDTNARStake(
        address _account
    ) public view returns (uint) {
        if (totalDeposited == 0) {
            return 0;
        }
        UserNwxRecords storage unar = usernarrecords[_account];
        uint256 stakedToken = userTotalBalance(_account);
        uint256 pendings = (stakedToken * accUSDTPernarToken) /
            1e18 -
            unar.narDebtUSDT;
        return (pendings);
    }

    function getUserNARInfo(
        address _account
    ) external view returns (uint256, uint256) {
        UserNwxRecords storage unar = usernarrecords[_account];
        uint256 totalUserDeposited = stakedAmounts[_account];
        return (totalUserDeposited, unar.narDebtUSDT);
    }

    function _lockNAR(address _account, uint256 _amount) external {
        require(msg.sender == Vester, "Not the vesting contract");
        UserNwxRecords storage unar = usernarrecords[_account];
        stakedAmounts[_account] = stakedAmounts[_account].sub(_amount);
        unar.amountInLockup = unar.amountInLockup.add(_amount);

        uint256 amountDiv2 = _amount.div(2);
        uint256 narStaked = depositBalances[_account][address(narToken)];
        uint256 esnarStaked = depositBalances[_account][address(esToken)];

        if (amountDiv2 <= narStaked && amountDiv2 <= esnarStaked) {
            unar.narLocked += amountDiv2;
            unar.esnarLocked += amountDiv2;
        } else if (
            amountDiv2 <= narStaked &&
            amountDiv2 > esnarStaked &&
            _amount <= narStaked
        ) {
            unar.narLocked += _amount;
        } else if (
            amountDiv2 > narStaked &&
            amountDiv2 <= esnarStaked &&
            _amount <= esnarStaked
        ) {
            unar.esnarLocked += _amount;
        } else if (narStaked > esnarStaked && esnarStaked != 0) {
            unar.esnarLocked += _amount.sub(narStaked);
            unar.narLocked += _amount.sub(unar.esnarLocked);
        } else if (esnarStaked > narStaked && narStaked != 0) {
            unar.narLocked += _amount.sub(esnarStaked);
            unar.esnarLocked += _amount.sub(unar.narLocked);
        } else {
            revert("Adjust your staking balance");
        }
    }

    function _unLockNAR(address _account, uint256 _amount) external {
        require(msg.sender == Vester, "Not the vesting contract");
        UserNwxRecords storage unar = usernarrecords[_account];
        unar.amountInLockup = unar.amountInLockup.sub(_amount);
        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        unar.narLocked = 0;
        unar.esnarLocked = 0;
    }

    // Harvest rewards
    function harvest(bool _compound) public updateReward(msg.sender) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint256 narRewards;
        uint256 USDTRewardsNAR;

        if (totalDeposited > 0) {
            (narRewards, USDTRewardsNAR) = _harvest();
        }

        uint256 pendingTokens = narRewards;
        uint256 pendingUSDTTotal = USDTRewardsNAR;

        if (pendingTokens > 0) {
            rewards[msg.sender] = 0;
            uint256 nextCumulativeReward = cumulativeRewards[msg.sender].add(
                pendingTokens
            );
            averageStakedAmounts[msg.sender] = averageStakedAmounts[msg.sender]
                .mul(cumulativeRewards[msg.sender])
                .div(nextCumulativeReward)
                .add(stakedAmounts[msg.sender].add(unar.amountInLockup))
                .mul((pendingTokens))
                .div(nextCumulativeReward);
            cumulativeRewards[msg.sender] = nextCumulativeReward;

            if (!_compound) {
                IERC20(esToken).safeTransfer(msg.sender, pendingTokens);
            } else {
                stakedAmounts[msg.sender] += pendingTokens;
                totalDeposited += pendingTokens;
                totalDepositedForToken[address(esToken)] += pendingTokens;

                uint256 stakedToken = userTotalBalance(msg.sender);
                unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
                if (withdrawTimelockEnabled) {
                    unar.depositTimestamp = block.timestamp;
                }
                depositBalances[msg.sender][address(esToken)] += pendingTokens;
            }

        }

        if (pendingUSDTTotal > 0) {
            if (_compound) {
                IERC20(USDT).approve(TradingVault, pendingUSDTTotal);
                ITradingVault(TradingVault).deposit(
                    pendingUSDTTotal,
                    msg.sender
                );
            } else {
                IERC20(USDT).safeTransfer(msg.sender, pendingUSDTTotal);
            }
        }
    }

    function _harvest() internal returns (uint256, uint256) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint pendingES = rewards[msg.sender];
        uint pendingUSDT = pendingRewardUSDTNARStake(msg.sender);

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
        rewardsUSDT += pendingUSDT;
        rewardsToken += pendingES;

        return (pendingES, pendingUSDT);
    }

    /**@notice Stakes the specified amount of tokens
    @param amount The amount of tokens to be staked
    @param _tokenAddress The address of the token being staked
    @dev Only users with whitelisted tokens can stake ONLY FOR DECIMAL 18 TOKENS
    /** */
    function stake(uint amount, address _tokenAddress) external nonReentrant updateReward(msg.sender) {
        require(isTokenWhitelisted[_tokenAddress], "Token not whitelisted");
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        harvest(false);
        IERC20(address(_tokenAddress)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        totalDeposited += amount;
        totalDepositedForToken[_tokenAddress] += amount;
        stakedAmounts[msg.sender] += amount;

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
        if (withdrawTimelockEnabled) {
            unar.depositTimestamp = block.timestamp;
        }

        depositBalances[msg.sender][_tokenAddress] += amount;
    }

    /**

    @notice Unstake amount of _tokenAddress
    @param amount The amount of tokens to be unstaked
    @param _tokenAddress The address of the tokens to be unstaked
    @dev This function allows a user to unstake their tokens
    */
    function unstake(uint amount, address _tokenAddress) external nonReentrant updateReward(msg.sender) {
        require(isTokenWhitelisted[_tokenAddress], "Token not whitelisted");
        require(
            amount <= depositBalances[msg.sender][_tokenAddress],
            "AMOUNT_TOO_BIG"
        );
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        
        if (withdrawTimelockEnabled) {
            require(block.timestamp >= unar.depositTimestamp + withdrawTimelock,"TOO_EARLY");
        }

        harvest(false);
        uint256 am;
        uint256 availToWithdraw;
        bool lockup = false;
        if (unar.amountInLockup > 0) {
            (availToWithdraw, lockup) = userAvailToWithdraw(
                msg.sender,
                _tokenAddress
            );
        } else {
            availToWithdraw = depositBalances[msg.sender][_tokenAddress];
        }
        if (lockup) {
            require(amount <= availToWithdraw, "Amount too high");
            require(availToWithdraw != 0, "Nothing to withdraw");
            am = amount;
        } else {
            require(
                amount <= depositBalances[msg.sender][_tokenAddress],
                "Amount too high"
            );
            require(availToWithdraw != 0, "Nothing to withdraw");
            am = amount;
        }

        totalDeposited -= am;
        totalDepositedForToken[_tokenAddress] -= am;
        stakedAmounts[msg.sender] -= am;

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;

        depositBalances[msg.sender][_tokenAddress] -= am;

        IERC20(_tokenAddress).safeTransfer(msg.sender, am);
    }

    /**
    @notice Check the available amount that a user can withdraw
    @param _user The address of the user
    @param _tokenAddress The address of the narToken to check
    @return The amount of tokens available to withdraw and a boolean indicating if the amount is locked up
    @dev This function checks if a user has any nar/es/Tokens locked up, and if so, how many are available to withdraw
    */
    function userAvailToWithdraw(
        address _user,
        address _tokenAddress
    ) public view returns (uint256, bool) {
        UserNwxRecords storage unar = usernarrecords[_user];

        uint256 narStaked = depositBalances[_user][address(narToken)];
        uint256 esnarStaked = depositBalances[_user][address(esToken)];

        uint256 availToWithdraw;
        if (stakedAmounts[_user] == 0) {
            availToWithdraw = 0;
        } else if (
            unar.narLocked > 0 && _tokenAddress == address(narToken)
        ) {
            availToWithdraw = narStaked.sub(unar.narLocked);
        } else if (
            unar.esnarLocked > 0 && _tokenAddress == address(esToken)
        ) {
            availToWithdraw = esnarStaked.sub(unar.esnarLocked);
        }

        return (availToWithdraw, true);
    }

    /**
    @notice Check the total balance of a user's staked nar/es/Tokens
    @param _user The address of the user
    @return The total amount of nar/es/Tokens staked by the user
    @dev This function returns the total amount of nar/es/Tokens staked by the user, including any locked up tokens
    */
    function userTotalBalance(address _user) public view returns (uint256) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint256 staked;
        if (unar.amountInLockup > 0) {
            staked = unar.amountInLockup.add(stakedAmounts[_user]);
        } else {
            staked = stakedAmounts[_user];
        }
        return staked;
    }
}