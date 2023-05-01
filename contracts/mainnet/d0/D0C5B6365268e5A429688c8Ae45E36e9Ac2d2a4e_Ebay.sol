// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./EbayLib.sol";

contract Ebay is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    enum Status {
        Initial, //待购买0
        Ordered, //被下单1
        Completed, //已完成2
        BuyerBreak, //买家毁约3
        SellerBreak, //卖家毁约4
        SellerCancelWithoutDuty, //卖家无责取消5
        BuyerLanchCancel, //买家发起取消6
        SellerLanchCancel, //卖家发起取消7
        SellerRejectCancel, //卖家拒绝取消8
        BuyerRejectCancel, //买家拒绝取消9
        ConsultCancelCompleted //协商取消完成10
    }

    struct Order {
        address seller; //卖家
        address buyer; //买家
        string name; // 物品名称
        uint256 price; //商品价格
        uint256 amount; //物品数量
        string description; //描述
        string img; //商品图片
        IERC20 token; //质押代币合约地址
        uint256 seller_pledge; //卖家实际质押数量，如果是白名单用户则是手续费
        uint256 buyer_pledge; //买家实际质押数量（至少得是商品总价）
        uint256 buyer_ex; // 买家超出商品总价质押部分（如果是白名单用户则是手续费）
        Status status; //订单状态
    }

    struct DateTime {
        uint256 createTimestamp; //订单创建时间
        uint256 finishedTimestamp; //订单完成时间
        uint256 cancelTimestamp; //订单取消时间
        uint256 placeTimestamp; //买家下单时间
        uint256 adminCancelTimestamp; //管理员强制取消时间
        uint256 adminConfirmTimestamp; //管理员强制确认时间
    }

    struct Contact {
        string seller; //卖家联系方式
        string buyer; //买家联系方式
    }
    mapping(address => bool) public whiteList;
    uint256 public buyerRate; //买家需要支付服务费率 使用整数表示
    uint256 public sellerRate; //卖家需要支付服务费率 使用整数表示
    uint256 public buyerIncRatio; //买家比卖家质押增量比例
    uint256 public sellerRatio = 10000; //卖家质押数量是商品总价的百分比/分母10000
    address public lockAddr;

    Order[] public orders;
    mapping(uint256 => DateTime) public dateTime;
    mapping(uint256 => Contact) contact;
    mapping(uint256 => mapping(address => bool)) isContact;
    mapping(address => uint256[]) public sellerList; //卖家订单
    mapping(address => uint256[]) public buyerList; //买家订单
    mapping(address => uint256) public total; //代币总质押数量

    event AddOrder(address indexed seller, uint256 indexed orderId); //创建订单事件
    event SetStatus(
        address indexed defaulter,
        uint256 indexed orderId,
        Status indexed status
    );
    event Confirm(address indexed defaulter, uint256 indexed orderId); //确认订单事件

    constructor(
        uint256 _buyerRate,
        uint256 _sellerRate,
        uint256 _buyerIncRatio,
        uint256 _sellerRatio,
        address _lockAddr
    ) {
        buyerRate = _buyerRate;
        sellerRate = _sellerRate;
        buyerIncRatio = _buyerIncRatio;
        lockAddr = _lockAddr;
        sellerRatio = _sellerRatio;
    }

    //计算卖家质押
    function calculateSellerPledge(
        uint256 price,
        uint256 amount
    ) public view returns (uint256 sellerPledge, uint256 sellerTxFee) {
        (sellerPledge, sellerTxFee) = EbayLib.calculateSellerPledge(
            price,
            amount,
            sellerRatio,
            sellerRate
        );
        if (isWhitelisted(_msgSender())) {
            sellerPledge = sellerTxFee;
        }
    }

    //计算买家质押
    function calculateBuyerTxFeeAndExcess(
        uint256 price,
        uint256 amount
    )
        public
        view
        returns (uint256 buyerTxFee, uint256 buyerExcess, uint256 buyerPledge)
    {
        (buyerTxFee, buyerExcess) = EbayLib.calculateBuyerTxFeeAndExcess(
            price,
            amount,
            buyerRate,
            buyerIncRatio
        );
        if (isWhitelisted(_msgSender())) {
            buyerExcess = buyerTxFee;
        }
        buyerPledge = buyerExcess.add(price.mul(amount));
    }

    //创建订单
    function addOrder(
        string memory _name,
        string memory _contactSeller,
        string memory _description,
        string memory _img,
        address _buyer,
        address _token,
        uint256 _price,
        uint256 _amount
    ) external {
        //1、卖家联系方式不能为空
        require(
            bytes(_contactSeller).length != 0,
            "Seller contact can not be null"
        );
        //2、验证代币合约是否有效
        require(EbayLib.verifyByAddress(_token) == 20, "Invalid contract");
        //3.质押数量

        (uint256 _seller_pledge, ) = calculateSellerPledge(_price, _amount);

        //4、将代币转入到合约地址
        IERC20(_token).transferFrom(
            _msgSender(),
            address(this),
            _seller_pledge
        );

        (, uint256 _buyer_ex, ) = calculateBuyerTxFeeAndExcess(_price, _amount);
        orders.push(
            Order({
                name: _name,
                seller: _msgSender(),
                buyer: _buyer,
                token: IERC20(_token),
                amount: _amount,
                seller_pledge: _seller_pledge,
                buyer_pledge: 0,
                buyer_ex: _buyer_ex,
                status: Status.Initial,
                description: _description,
                img: _img,
                price: _price
            })
        );
        uint256 _orderId = orders.length - 1;
        dateTime[_orderId].createTimestamp = block.timestamp;
        contact[_orderId].seller = _contactSeller;
        isContact[_orderId][_msgSender()] = true;
        total[_token] += _seller_pledge; //更新总质押代币数量
        sellerList[_msgSender()].push(_orderId);
        emit AddOrder(_msgSender(), _orderId);
    }

    //买家下单
    function place(uint256 _orderId, string memory _buyerContact) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验订单状态是否可以交易
        require(order.status == Status.Initial, "Order has expired");
        address _user = _msgSender();
        //3、校验订单是否指定买家
        require(
            order.buyer == address(0) || order.buyer == _user,
            "Non designated buyer"
        );
        //4、将订单更新为已下单状态
        order.status = Status.Ordered;
        if (isWhitelisted(_user)) {
            order.buyer_ex = order.price.mul(order.amount).mul(buyerRate);
        }
        uint256 _buyer_pledge = (order.price.mul(order.amount)).add(
            order.buyer_ex
        );
        //5、将代币转入到合约地址
        order.token.transferFrom(_user, address(this), _buyer_pledge);
        buyerList[_user].push(_orderId);
        total[address(order.token)] = total[address(order.token)].add(
            _buyer_pledge
        );
        buyerList[_user].push(_orderId);

        dateTime[_orderId].placeTimestamp = block.timestamp;
        order.buyer = _user;
        order.buyer_pledge = _buyer_pledge;
        contact[_orderId].buyer = _buyerContact;
        isContact[_orderId][_msgSender()] = true;
        emit SetStatus(_user, _orderId, Status.Ordered);
    }

    function cancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验订单状态是否可以取消
        address _user = _msgSender();
        require(order.seller == _user, "No permissions");
        require(order.status == Status.Initial, "Order status error");

        Status _status = Status.SellerCancelWithoutDuty;
        order.token.safeTransfer(order.seller, order.seller_pledge); // 转给卖家 卖家质押数量
        total[address(order.token)] = total[address(order.token)].sub(
            order.seller_pledge
        );
        //3、将订单更新为取消状态
        order.status = _status;
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_user, _orderId, _status);
    }

    //确认订单
    function confirm(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验订单的买家是否为调用者
        require(order.buyer == _msgSender(), "No permissions");
        //3、校验订单状态是否可以确认
        require(
            order.status == Status.Ordered ||
                order.status == Status.BuyerLanchCancel ||
                order.status == Status.SellerLanchCancel ||
                order.status == Status.SellerRejectCancel ||
                order.status == Status.BuyerRejectCancel,
            "Order cannot be confirmed"
        );
        //更新状态
        order.status = Status.Completed;
        (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCalculateRefunds(
                order.seller_pledge,
                order.buyer_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack); //转给卖家
        order.token.safeTransfer(order.buyer, buyerBack); //转给买家
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee)); //fee
        dateTime[_orderId].finishedTimestamp = block.timestamp;
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量

        emit Confirm(_msgSender(), _orderId);
    }

    //发起取消
    function launchCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验订单状态是否可以取消
        require(
            order.status == Status.Ordered ||
                order.status == Status.SellerRejectCancel ||
                order.status == Status.BuyerRejectCancel,
            "Order cannot be launched"
        );
        //3、校验调用合约者是否是买家 or 卖家
        require(
            order.buyer == _msgSender() || order.seller == _msgSender(),
            "No permissions"
        );
        Status _status = Status.BuyerLanchCancel; // 6 买家发起取消
        if (order.seller == _msgSender()) {
            _status = Status.SellerLanchCancel;
        }
        //4、将订单更新为发起取消状态
        order.status = _status;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //拒绝取消
    function rejectCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验订单状态是否可以取消
        require(
            order.status == Status.BuyerLanchCancel ||
                order.status == Status.SellerLanchCancel,
            "Order cannot be canceled"
        );
        Status _status = Status.BuyerRejectCancel;
        //3、校验调用合约者是否是买家 or 卖家
        require(
            order.buyer == _msgSender() || order.seller == _msgSender(),
            "No permissions"
        );
        if (
            order.buyer == _msgSender() && order.seller == _msgSender()
        ) {} else if (order.seller == _msgSender()) {
            //4、校验订单状态是否可以取消
            require(
                order.status == Status.BuyerLanchCancel,
                "Order cannot be canceled"
            );
            _status = Status.SellerRejectCancel;
        } else {
            //5、校验订单状态是否可以取消
            require(
                order.status == Status.SellerLanchCancel,
                "Order cannot be canceled"
            );
        }
        //6、将订单更新为拒绝取消状态
        order.status = _status;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //确认取消
    function confirmCancel(uint256 _orderId) external {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        //2、校验调用合约者是否是买家 or 卖家
        require(
            order.buyer == _msgSender() || order.seller == _msgSender(),
            "No permissions"
        );
        //默认协商取消完成
        Status _status = Status.ConsultCancelCompleted;
        if (
            order.seller == _msgSender() && order.buyer == _msgSender()
        ) {} else if (order.seller == _msgSender()) {
            //3、校验订单状态是否可以取消
            require(
                order.status == Status.BuyerLanchCancel,
                "Order cannot be canceled"
            );
        } else {
            //4、校验订单状态是否可以取消
            require(
                order.status == Status.SellerLanchCancel,
                "Order cannot be canceled"
            );
        }
        order.status = _status;
        (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCancelCalculateFeesAndRefunds(
                order.buyer_pledge,
                order.seller_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack);
        order.token.safeTransfer(order.buyer, buyerBack);
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //争议订单取消强制双方返还
    function adminCancel(uint256 _orderId) external onlyOwner {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        require(order.status != Status.Completed, "Status Completed");
        require(
            order.status != Status.ConsultCancelCompleted,
            "Status  ConsultCancelCompleted"
        );
        require(
            order.status != Status.SellerCancelWithoutDuty,
            "Status SellerCancelWithoutDuty"
        );
        require(order.status != Status.Initial, "Status Initial");

        //2、默认争议订单取消
        Status _status = Status.ConsultCancelCompleted;
        order.status = _status;

        (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCancelCalculateFeesAndRefunds(
                order.buyer_pledge,
                order.seller_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack);
        order.token.safeTransfer(order.buyer, buyerBack);
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].adminCancelTimestamp = block.timestamp;
        dateTime[_orderId].cancelTimestamp = block.timestamp;
        emit SetStatus(_msgSender(), _orderId, _status);
    }

    //争议订单强制确认
    function adminConfirm(uint256 _orderId) external onlyOwner {
        //1、校验订单是否存在
        Order storage order = orders[_orderId];
        validate(_orderId);
        require(order.status != Status.Initial, "Status Initial");
        require(
            order.status != Status.ConsultCancelCompleted,
            "Status ConsultCancelCompleted"
        );
        require(order.status != Status.Completed, "Status Completed");
        require(
            order.status != Status.SellerCancelWithoutDuty,
            "Status SellerCancelWithoutDuty"
        );

        //2、默认争议订单被确认
        //更新状态
        order.status = Status.Completed;

        (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        ) = EbayLib.confirmCalculateRefunds(
                order.seller_pledge,
                order.buyer_pledge,
                order.price,
                order.amount,
                buyerRate,
                sellerRate,
                order.buyer_ex
            );
        order.token.safeTransfer(order.seller, sellerBack); //转给卖家
        order.token.safeTransfer(order.buyer, buyerBack); //转给买家
        order.token.safeTransfer(lockAddr, sellerFee.add(buyerFee));
        dateTime[_orderId].finishedTimestamp = block.timestamp;
        total[address(order.token)] -= order.buyer_pledge + order.seller_pledge; //更新总质押代币数量
        dateTime[_orderId].adminConfirmTimestamp = block.timestamp;
        emit Confirm(_msgSender(), _orderId);
    }

    function getContact(
        uint256 _orderId
    ) external view returns (string memory _seller, string memory _buyer) {
        if (_msgSender() == owner()) {
            _seller = contact[_orderId].seller;
            _buyer = contact[_orderId].buyer;
        } else if (isContact[_orderId][_msgSender()] == true) {
            _seller = contact[_orderId].seller;
            _buyer = contact[_orderId].buyer;
        }
    }

    //set Rate
    function setRate(
        uint256 _buyerRate,
        uint256 _sellerRate,
        uint256 _buyerIncRatio,
        uint256 _sellerRatio
    ) external onlyOwner {
        buyerRate = _buyerRate;
        sellerRate = _sellerRate;
        buyerIncRatio = _buyerIncRatio;
        sellerRatio = _sellerRatio;
    }

    //set lockAddr
    function setLock(address _lockAddr) external onlyOwner {
        lockAddr = _lockAddr;
    }

    // 添加一个地址到白名单
    function addToWhitelist(address _address) public onlyOwner {
        require(_address != address(0), "address can not be 0");
        whiteList[_address] = true;
    }

    // 从白名单中删除一个地址
    function removeFromWhitelist(address _address) public onlyOwner {
        whiteList[_address] = false;
    }

    // 检查一个地址是否在白名单中
    function isWhitelisted(address _address) public view returns (bool) {
        return whiteList[_address];
    }

    function renounceOwnership() public pure override {}

    function validate(uint256 _orderId) internal view {
        require(_orderId < orders.length, "Order does not exist");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library EbayLib {
    using SafeMath for uint256;

    function calculateSellerPledge(
        uint256 price,
        uint256 amount,
        uint256 sellerRatio,
        uint256 sellerRate
    ) internal pure returns (uint256 sellerPledge, uint256 sellerTxFee) {
        sellerPledge = price.mul(amount).mul(sellerRatio).div(10000);
        sellerTxFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerTxFee) {
            sellerPledge = sellerTxFee;
        }
        return (sellerPledge, sellerTxFee);
    }

    function calculateBuyerTxFeeAndExcess(
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 buyerIncRatio
    ) internal pure returns (uint256 buyerTxFee, uint256 buyerExcess) {
        buyerTxFee = price.mul(amount).mul(buyerRate).div(10000);
        buyerExcess = price.mul(amount).mul(buyerIncRatio).div(10000);
        if (buyerTxFee > buyerExcess) {
            buyerExcess = buyerTxFee;
        }
        return (buyerTxFee, buyerExcess);
    }

    function confirmCalculateRefunds(
        uint256 sellerPledge,
        uint256 buyerPledge,
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 sellerRate,
        uint256 buyerEx
    )
        internal
        pure
        returns (
            uint256 sellerFee,
            uint256 buyerFee,
            uint256 sellerBack,
            uint256 buyerBack
        )
    {
        sellerFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerFee) {
            sellerFee = sellerPledge;
        }
        buyerFee = price.mul(amount).mul(buyerRate).div(10000);
        if (buyerEx < buyerFee) {
            buyerFee = buyerEx;
        }
        sellerBack = (sellerPledge + (price.mul(amount))).sub(sellerFee); // 返还卖家数量
        buyerBack = buyerPledge.sub(price.mul(amount)).sub(buyerFee); // 返还买家数量

        return (sellerFee, buyerFee, sellerBack, buyerBack);
    }

    function confirmCancelCalculateFeesAndRefunds(
        uint256 buyerPledge,
        uint256 sellerPledge,
        uint256 price,
        uint256 amount,
        uint256 buyerRate,
        uint256 sellerRate,
        uint256 buyerEx
    )
        internal
        pure
        returns (
            uint256 buyerFee,
            uint256 sellerFee,
            uint256 sellerBack,
            uint256 buyerBack
        )
    {
        buyerFee = price.mul(amount).mul(buyerRate).div(10000);
        if (buyerEx < buyerFee) {
            buyerFee = buyerEx;
        }
        sellerFee = price.mul(amount).mul(sellerRate).div(10000);
        if (sellerPledge < sellerFee) {
            sellerFee = sellerPledge;
        }
        sellerBack = sellerPledge.sub(sellerFee);
        buyerBack = buyerPledge.sub(buyerFee);

        return (buyerFee, sellerFee, sellerBack, buyerBack);
    }

    function verifyByAddress(
        address _address
    ) internal returns (uint256 contractType) {
        bytes memory ownerOfData = abi.encodeWithSignature(
            "ownerOf(uint256)",
            0
        );
        (, bytes memory returnOwnerOfData) = _address.call{value: 0}(
            ownerOfData
        );
        if (returnOwnerOfData.length > 0) {
            return 721;
        } else {
            bytes memory totalSupplyData = abi.encodeWithSignature(
                "totalSupply()"
            );
            (, bytes memory returnTotalSupplyData) = _address.call{value: 0}(
                totalSupplyData
            );
            if (returnTotalSupplyData.length > 0) {
                return 20;
            } else {
                return 1155;
            }
        }
    }
}