// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity >0.6.12;

interface IBasisAsset {
    function mint(address recipient, uint amount) external;

    function burn(uint amount) external;

    function burnFrom(address from, uint amount) external;

    function isOperator() external returns (bool);

    function amIOperator() external view returns (bool);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.12;

interface IBoardroom {
    function totalSupply() external view returns (uint);

    function balanceOf(address _director) external view returns (uint);

    function earned(address _director) external view returns (uint);

    function canWithdraw(address _director) external view returns (bool);

    function canClaimReward(address _director) external view returns (bool);

    function epoch() external view returns (uint);

    function nextEpochPoint() external view returns (uint);

    function getArbiTenPrice() external view returns (uint);

    function setOperator(address _operator) external;

    function setReserveFund(address _reserveFund) external;

    function setStakeFee(uint _stakeFee) external;

    function setWithdrawFee(uint _withdrawFee) external;

    function setLockUp(uint _withdrawLockupEpochs, uint _rewardLockupEpochs) external;

    function stake(uint _amount) external;

    function withdraw(uint _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint _amount) external;

    function governanceRecoverUnsupported(address _token, uint _amount, address _to) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.12;

interface IOracle {
    function update() external;

    function consult(address _token, uint _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.12;
pragma experimental ABIEncoderV2;

interface IPool {
    function collateralArbiTenBalance() external view returns (uint);

    function migrate(address _new_pool) external;

    function getCollateralPrice() external view returns (uint);

    function netSupplyMinted() external view returns (uint);

    function getCollateralToken() external view returns (address);
}

pragma solidity >0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >0.6.12;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >0.6.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./interfaces/IPool.sol";


contract Treasury is ContractGuard {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    // TODO: CHANGE ME Update time
    uint public constant PERIOD = 8 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint public startTime;
    uint public epoch = 0;
    uint public epochSupplyContractionLeft = 0;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public ArbiTen;
    address public _10BOND;
    address public _10SHARE;

    address public boardroom;
    address public ArbiTenOracle;
    address public _10SHAREOracle;

    uint public boardroomWithdrawFee;
    uint public boardroomStakeFee;

    // price
    uint public ArbiTenPriceOne;
    uint public ArbiTenPriceCeiling;

    uint public seigniorageSaved;

    uint public ArbiTenSupplyTarget;

    uint public maxSupplyExpansionPercent;
    uint public minMaxSupplyExpansionPercent;
    uint public bondDepletionFloorPercent;
    uint public seigniorageExpansionFloorPercent;
    uint public maxSupplyContractionPercent;
    uint public maxDebtRatioPercent;

    // 21 first epochs (1 week) with 3.5% expansion regardless of ArbiTen price
    uint public bootstrapEpochs;
    uint public bootstrapSupplyExpansionPercent;

    /* =================== Added variables =================== */
    uint public previousEpochArbiTenPrice;
    uint public maxDiscountRate; // when purchasing bond
    uint public maxPremiumRate; // when redeeming bond
    uint public discountPercent;
    uint public premiumThreshold;
    uint public premiumPercent;
    uint public mintingFactorForPayingDebt; // print extra ArbiTen during debt phase

    // 45% for Stakers in boardroom (THIS)
    // 45% for DAO fund
    // 2% for DEV fund
    // 8% for INSURANCE fund
    address public daoFund;
    uint public daoFundSharedPercent;

    address public devFund;
    uint public devFundSharedPercent;

    address public insuranceFund;
    uint public insuranceFundSharedPercent;

    address public equityFund;
    uint public equityFundSharedPercent;

    // pools
    address[] public pools_array;
    mapping(address => bool) public pools;

    // fees
    uint public redemption_fee; // 6 decimals of precision
    uint public minting_fee; // 6 decimals of precision

    // collateral_ratio
    uint public last_refresh_cr_timestamp;
    uint public target_collateral_ratio; // 6 decimals of precision
    uint public effective_collateral_ratio; // 6 decimals of precision
    uint public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint public ratio_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint public price_target; // The price of ArbiTen at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint public price_band; // The bound above and below the price target at which the Collateral ratio is allowed to drop
    bool public collateral_ratio_paused = false; // during bootstraping phase, collateral_ratio will be fixed at 100%
    bool public using_effective_collateral_ratio = true; // toggle the effective collateral ratio usage
    uint private constant COLLATERAL_RATIO_MAX = 1e6;

    // Constants for various precisions
    uint private constant PRICE_PRECISION = 1e18;

    /* =================== Events =================== */

    event Initialized(address indexed executor, uint at);
    event BurnedBonds(address indexed from, uint bondAmount);
    event RedeemedBonds(address indexed from, uint ArbiTenAmount, uint bondAmount);
    event BoughtBonds(address indexed from, uint ArbiTenAmount, uint bondAmount);
    event TreasuryFunded(uint timestamp, uint seigniorage);
    event BoardroomFunded(uint timestamp, uint seigniorage);
    event DaoFundFunded(uint timestamp, uint seigniorage);
    event DevFundFunded(uint timestamp, uint seigniorage);
    event InsuranceFundFunded(uint timestamp, uint seigniorage);
    event EquityFundFunded(uint timestamp, uint seigniorage);
    event Seigniorage(uint epoch, uint twap, uint expansion);
    event TransactionExecuted(address indexed target, uint value, string signature, bytes data);

    constructor() public {
        operator = msg.sender;
    }


    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
        epochSupplyContractionLeft = (getArbiTenPrice() > ArbiTenPriceCeiling) ? 0 : getArbiTenCirculatingSupply().mul(maxSupplyContractionPercent).div(10000);
    }

    modifier checkOperator {
        require(
            IBasisAsset(ArbiTen).amIOperator() &&
                IBasisAsset(_10BOND).amIOperator() &&
                IBasisAsset(_10SHARE).amIOperator() &&
                IBasisAsset(boardroom).amIOperator(),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint) {
        return startTime.add(epoch.mul(PERIOD));
    }

    function info()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        return (getArbiTenUpdatedPrice(), get10SHAREPrice(), IERC20(ArbiTen).totalSupply(), target_collateral_ratio, effective_collateral_ratio, globalCollateralValue(), minting_fee, redemption_fee);
    }


    // Iterate through all pools and calculate all value of collateral in all pools globally
    function globalCollateralValue() public view returns (uint) {
        uint total_collateral_value = 0;
        for (uint i = 0; i < pools_array.length; i++) {
            // Exclude null addresses
            if (pools_array[i] != address(0)) {
                total_collateral_value = total_collateral_value.add(IPool(pools_array[i]).collateralArbiTenBalance());
            }
        }
        return total_collateral_value;
    }


    // Iterate through all pools and calculate all value of collateral in all pools globally
    function globalIronSupply() public view returns (uint) {
        uint total_ironArbiTen_minted_ = 0;
        for (uint i = 0; i < pools_array.length; i++) {
            // Exclude null addresses
            if (pools_array[i] != address(0)) {
                total_ironArbiTen_minted_ = total_ironArbiTen_minted_.add(IPool(pools_array[i]).netSupplyMinted());
            }
        }
        return total_ironArbiTen_minted_;
    }

    function calcEffectiveCollateralRatio() public view returns (uint) {
        if (!using_effective_collateral_ratio) {
            return target_collateral_ratio;
        }
        uint total_collateral_value = globalCollateralValue();
        uint total_supplyArbiTen = IERC20(ArbiTen).totalSupply();
        // We are pegged to 1/10 ETH
        uint ecr = total_collateral_value.mul(10).mul(COLLATERAL_RATIO_MAX).div(total_supplyArbiTen);
        if (ecr > COLLATERAL_RATIO_MAX) {
            return COLLATERAL_RATIO_MAX;
        }
        return ecr;
    }

    function refreshCollateralRatio() external {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        require(block.timestamp - last_refresh_cr_timestamp >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        uint currentArbiTen_price = getArbiTenPrice();

        // Step increments are 0.25% (upon genesis, changable by setRatioStep())
        if (currentArbiTen_price > price_target.add(price_band)) {
            // decrease collateral ratio
            if (target_collateral_ratio <= ratio_step) {
                // if within a step of 0, go to 0
                target_collateral_ratio = 0;
            } else {
                target_collateral_ratio = target_collateral_ratio.sub(ratio_step);
            }
        }
        // IRON price is below $0.1 - `price_band`. Need to increase `collateral_ratio`
        else if (currentArbiTen_price < price_target.sub(price_band)) {
            // increase collateral ratio
            if (target_collateral_ratio.add(ratio_step) >= COLLATERAL_RATIO_MAX) {
                target_collateral_ratio = COLLATERAL_RATIO_MAX; // cap collateral ratio at 1.000000
            } else {
                target_collateral_ratio = target_collateral_ratio.add(ratio_step);
            }
        }

        // If using ECR, then calcECR. If not, update ECR = TCR
        if (using_effective_collateral_ratio) {
            effective_collateral_ratio = calcEffectiveCollateralRatio();
        } else {
            effective_collateral_ratio = target_collateral_ratio;
        }

        last_refresh_cr_timestamp = block.timestamp;
    }

    // Check if the protocol is over- or under-collateralized, by how much
    function calcCollateralBalance() public view returns (uint _collateral_value, bool _exceeded) {
        uint total_collateral_value = globalCollateralValue();
        uint target_collateral_value = IERC20(ArbiTen).totalSupply().mul(target_collateral_ratio).div(COLLATERAL_RATIO_MAX);
        if (total_collateral_value >= target_collateral_value) {
            _collateral_value = total_collateral_value.sub(target_collateral_value);
            _exceeded = true;
        } else {
            _collateral_value = target_collateral_value.sub(total_collateral_value);
            _exceeded = false;
        }
    }

    function get10SHAREPrice() public view returns (uint _10SHAREPrice) {
        try IOracle(_10SHAREOracle).consult(_10SHARE, PRICE_PRECISION) returns (uint144 price) {
            return uint(price);
        } catch {
            revert("Treasury: failed to consult 10SHARE price from the oracle");
        }
    }

    // oracle
    function getArbiTenPrice() public view returns (uint ArbiTenPrice) {
        try IOracle(ArbiTenOracle).consult(ArbiTen, PRICE_PRECISION) returns (uint144 price) {
            return uint(price);
        } catch {
            revert("Treasury: failed to consult ArbiTen price from the oracle");
        }
    }

    function getArbiTenUpdatedPrice() public view returns (uint _ArbiTenPrice) {
        try IOracle(ArbiTenOracle).twap(ArbiTen, PRICE_PRECISION) returns (uint144 price) {
            return uint(price);
        } catch {
            revert("Treasury: failed to consult ArbiTen price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint) {
        return seigniorageSaved;
    }

    function getBurnableArbiTenLeft() public view returns (uint _burnableArbiTenLeft) {
        uint _ArbiTenPrice = getArbiTenPrice();
        if (_ArbiTenPrice <= ArbiTenPriceOne) {
            uint _ArbiTenSupply = getArbiTenCirculatingSupply();
            uint _bondMaxSupply = _ArbiTenSupply.mul(maxDebtRatioPercent).div(10000);
            uint _bondSupply = IERC20(_10BOND).totalSupply();
            if (_bondMaxSupply > _bondSupply) {
                uint _maxMintableBond = _bondMaxSupply.sub(_bondSupply);
                uint _rate = getBondDiscountRate();
                if (_rate > 0) {
                    uint _maxBurnableArbiTen = _maxMintableBond.mul(ArbiTenPriceOne).div(_rate);
                    _burnableArbiTenLeft = Math.min(epochSupplyContractionLeft, _maxBurnableArbiTen);
                }
            }
        }
    }

    function getRedeemableBonds() public view returns (uint _redeemableBonds) {
        uint _ArbiTenPrice = getArbiTenPrice();
        if (_ArbiTenPrice > ArbiTenPriceCeiling) {
            uint _totalArbiTen = IERC20(ArbiTen).balanceOf(address(this));
            uint _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalArbiTen.mul(ArbiTenPriceOne).div(_rate);
            }
        }
    }

    function getBondDiscountRate() public view returns (uint _rate) {
        uint _ArbiTenPrice = getArbiTenPrice();
        if (_ArbiTenPrice <= ArbiTenPriceOne) {
            if (discountPercent == 0) {
                // no discount
                _rate = ArbiTenPriceOne;
            } else {
                uint _bondAmount = ArbiTenPriceOne.mul(ArbiTenPriceOne).div(_ArbiTenPrice); // to burn 1 ArbiTen
                uint _discountAmount = _bondAmount.sub(ArbiTenPriceOne).mul(discountPercent).div(10000);
                _rate = ArbiTenPriceOne.add(_discountAmount);
                if (maxDiscountRate > 0 && _rate > maxDiscountRate) {
                    _rate = maxDiscountRate;
                }
            }
        }
    }

    function getBondPremiumRate() public view returns (uint _rate) {
        uint _ArbiTenPrice = getArbiTenPrice();
        if (_ArbiTenPrice > ArbiTenPriceCeiling) {
            uint _ArbiTenPricePremiumThreshold = ArbiTenPriceOne.mul(premiumThreshold).div(100);
            if (_ArbiTenPrice >= _ArbiTenPricePremiumThreshold) {
                //Price > 1.01
                uint _premiumAmount =  _ArbiTenPrice.sub(ArbiTenPriceOne).mul(premiumPercent).div(10000);
                _rate = ArbiTenPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = ArbiTenPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _ArbiTen,
        address __10BOND,
        address __10SHARE,
        address _ArbiTenOracle,
        address __10SHAREOracle,
        address _boardroom,
        uint _startTime
    ) public notInitialized onlyOperator {
        ArbiTen = _ArbiTen;
        _10BOND = __10BOND;
        _10SHARE = __10SHARE;
        ArbiTenOracle = _ArbiTenOracle;
        _10SHAREOracle = __10SHAREOracle;
        boardroom = _boardroom;
        startTime = _startTime;

        ArbiTenPriceOne = PRICE_PRECISION.div(10);
        ArbiTenPriceCeiling = ArbiTenPriceOne.mul(101).div(100);

        ArbiTenSupplyTarget = 1000000 ether;

        maxSupplyExpansionPercent = 100; // Upto 1.00% supply for expansion
        minMaxSupplyExpansionPercent = 10; // Minimum max of 0.1% supply for expansion


        boardroomWithdrawFee = 2; // 2% withdraw fee when under peg

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxSupplyContractionPercent = 300; // Upto 3.0% supply for contraction (to burn ArbiTen and mint 10BOND)
        maxDebtRatioPercent = 3500; // Upto 35% supply of 10BOND to purchase

        premiumThreshold = 101;
        premiumPercent = 5000;

        // First 24 epochs with 4.5% expansion
        bootstrapEpochs = 24;
        bootstrapSupplyExpansionPercent = 110;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(ArbiTen).balanceOf(address(this));

        initialized = true;

        // iron initialization
        ratio_step = 2500; // = 0.25% at 6 decimals of precision
        target_collateral_ratio = 1000000; // = 100% - fully collateralized at start
        effective_collateral_ratio = 1000000; // = 100% - fully collateralized at start
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = ArbiTenPriceOne; // = $0.1. (18 decimals of precision). Collateral ratio will adjust according to the $0.1 price target at genesis
        price_band = 500;
        redemption_fee = 4000;
        minting_fee = 4000;

        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setBoardroomWithdrawFee(uint _boardroomWithdrawFee) external onlyOperator {
        require(_boardroomWithdrawFee <= 20, "Max withdraw fee is 20%");
        boardroomWithdrawFee = _boardroomWithdrawFee;
    }

    function setBoardroomStakeFee(uint _boardroomStakeFee) external onlyOperator {
        require(_boardroomStakeFee <= 5, "Max stake fee is 5%");
        boardroomStakeFee = _boardroomStakeFee;
        IBoardroom(boardroom).setStakeFee(boardroomStakeFee);
    }

    function setArbiTenOracle(address _ArbiTenOracle) external onlyOperator {
        ArbiTenOracle = _ArbiTenOracle;
    }

    function setArbiTenPriceCeiling(uint _ArbiTenPriceCeiling) external onlyOperator {
        require(_ArbiTenPriceCeiling >= ArbiTenPriceOne && _ArbiTenPriceCeiling <= ArbiTenPriceOne.mul(120).div(100), "out of range"); // [$0.1, $0.12]
        ArbiTenPriceCeiling = _ArbiTenPriceCeiling;
    }

    function setMinMaxSupplyExpansionPercent(uint _minMaxSupplyExpansionPercent) external onlyOperator {
        require(_minMaxSupplyExpansionPercent <= 100, "_minMaxSupplyExpansionPercent: out of range"); // [0%, 1%]
        minMaxSupplyExpansionPercent = _minMaxSupplyExpansionPercent;
    }

    function setMaxSupplyExpansionPercent(uint _maxSupplyExpansionPercent) external onlyOperator {
        require(_maxSupplyExpansionPercent >= minMaxSupplyExpansionPercent && _maxSupplyExpansionPercent <= 1000, "_maxSupplyExpansionPercent: out of range"); // [minMax%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setBondDepletionFloorPercent(uint _bondDepletionFloorPercent) external onlyOperator {
        require(_bondDepletionFloorPercent >= 500 && _bondDepletionFloorPercent <= 10000, "out of range"); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxSupplyContractionPercent(uint _maxSupplyContractionPercent) external onlyOperator {
        require(_maxSupplyContractionPercent >= 100 && _maxSupplyContractionPercent <= 1500, "out of range"); // [0.1%, 15%]
        maxSupplyContractionPercent = _maxSupplyContractionPercent;
    }

    function setMaxDebtRatioPercent(uint _maxDebtRatioPercent) external onlyOperator {
        require(_maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000, "out of range"); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setBootstrap(uint _bootstrapEpochs, uint _bootstrapSupplyExpansionPercent) external onlyOperator {
        require(_bootstrapEpochs <= 90, "_bootstrapEpochs: out of range"); // <= 1 month
        require(_bootstrapSupplyExpansionPercent >= 100 && _bootstrapSupplyExpansionPercent <= 1000, "_bootstrapSupplyExpansionPercent: out of range"); // [1%, 10%]
        bootstrapEpochs = _bootstrapEpochs;
        bootstrapSupplyExpansionPercent = _bootstrapSupplyExpansionPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint _daoFundSharedPercent,
        address _devFund,
        uint _devFundSharedPercent,
        address _insuranceFund,
        uint _insuranceFundSharedPercent,
        address _equityFund,
        uint _equityFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 5000, "out of range"); // <= 50%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 5000, "out of range"); // <= 10%
        require(_insuranceFund != address(0), "zero");
        require(_insuranceFundSharedPercent <= 5000, "out of range"); // <= 50%
        require(_equityFund != address(0), "zero");
        require(_equityFundSharedPercent <= 5000, "out of range"); // <= 50%

        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;

        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;

        insuranceFund = _insuranceFund;
        insuranceFundSharedPercent = _insuranceFundSharedPercent;

        equityFund = _equityFund;
        equityFundSharedPercent = _equityFundSharedPercent;
    }

    function setMaxDiscountRate(uint _maxDiscountRate) external onlyOperator {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setDiscountPercent(uint _discountPercent) external onlyOperator {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint _premiumThreshold) external onlyOperator {
        require(_premiumThreshold >= ArbiTenPriceCeiling, "_premiumThreshold exceeds ArbiTenPriceCeiling");
        require(_premiumThreshold <= 150, "_premiumThreshold is higher than 1.5");
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    function setMintingFactorForPayingDebt(uint _mintingFactorForPayingDebt) external onlyOperator {
        require(_mintingFactorForPayingDebt >= 10000 && _mintingFactorForPayingDebt <= 20000, "_mintingFactorForPayingDebt: out of range"); // [100%, 200%]
        mintingFactorForPayingDebt = _mintingFactorForPayingDebt;
    }

    function setArbiTenSupplyTarget(uint _ArbiTenSupplyTarget) external onlyOperator {
        require(_ArbiTenSupplyTarget > getArbiTenCirculatingSupply(), "too small"); // >= current circulating supply
        ArbiTenSupplyTarget = _ArbiTenSupplyTarget;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    // Add new Pool
    function addPool(address pool_address) public onlyOperator {
        require(pools[pool_address] == false, "poolExisted");
        pools[pool_address] = true;
        pools_array.push(pool_address);
    }

    // Remove a pool
    function removePool(address pool_address) public onlyOperator {
        require(pools[pool_address] == true, "!pool");
        // Delete from the mapping
        delete pools[pool_address];
        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < pools_array.length; i++) {
            if (pools_array[i] == pool_address) {
                pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function _updateArbiTenPrice() internal {
        try IOracle(ArbiTenOracle).update() {} catch {}
    }

    function _update10SHAREPrice() internal {
        try IOracle(_10SHAREOracle).update() {} catch {}
    }

    function getArbiTenCirculatingSupply() public view returns (uint) {
        IERC20 ArbiTenErc20 = IERC20(ArbiTen);
        uint totalSupply = ArbiTenErc20.totalSupply();
        uint balanceExcluded = 0;
        for (uint8 entryId = 0; entryId < excludedFromTotalSupply.length; ++entryId) {
            balanceExcluded = balanceExcluded.add(ArbiTenErc20.balanceOf(excludedFromTotalSupply[entryId]));
        }
        uint totalCircSupply =  totalSupply.sub(balanceExcluded);
        uint totalIronSupply = globalIronSupply();
        if (totalCircSupply > totalIronSupply)
            return totalCircSupply.sub(totalIronSupply);
        return 0;
    }

    function buyBonds(uint _ArbiTenAmount, uint targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_ArbiTenAmount > 0, "Treasury: cannot purchase bonds with zero amount");

        uint ArbiTenPrice = getArbiTenPrice();
        require(ArbiTenPrice == targetPrice, "Treasury: ArbiTen price moved");
        require(
            ArbiTenPrice < ArbiTenPriceOne, // price < $0.1
            "Treasury: ArbiTenPrice not eligible for bond purchase"
        );

        require(_ArbiTenAmount <= epochSupplyContractionLeft, "Treasury: not enough bond left to purchase");

        uint _rate = getBondDiscountRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint _bondAmount = _ArbiTenAmount.mul(_rate).div(ArbiTenPriceOne);
        uint ArbiTenSupply = getArbiTenCirculatingSupply();
        uint newBondSupply = IERC20(_10BOND).totalSupply().add(_bondAmount);
        require(newBondSupply <= ArbiTenSupply.mul(maxDebtRatioPercent).div(10000), "over max debt ratio");

        IBasisAsset(ArbiTen).burnFrom(msg.sender, _ArbiTenAmount);
        IBasisAsset(_10BOND).mint(msg.sender, _bondAmount);

        epochSupplyContractionLeft = epochSupplyContractionLeft.sub(_ArbiTenAmount);
        
        //_updateArbiTenPrice();
        treasuryUpdates();

        emit BoughtBonds(msg.sender, _ArbiTenAmount, _bondAmount);
    }

    function redeemBonds(uint _bondAmount, uint targetPrice) external onlyOneBlock checkCondition checkOperator {
        require(_bondAmount > 0, "Treasury: cannot redeem bonds with zero amount");

        uint ArbiTenPrice = getArbiTenPrice();
        require(ArbiTenPrice == targetPrice, "Treasury: ArbiTen price moved");
        require(
            ArbiTenPrice > ArbiTenPriceCeiling, // price > $1.01
            "Treasury: ArbiTenPrice not eligible for bond purchase"
        );

        uint _rate = getBondPremiumRate();
        require(_rate > 0, "Treasury: invalid bond rate");

        uint _ArbiTenAmount = _bondAmount.mul(_rate).div(ArbiTenPriceOne);
        require(IERC20(ArbiTen).balanceOf(address(this)) >= _ArbiTenAmount, "Treasury: treasury has no more budget");

        seigniorageSaved = seigniorageSaved.sub(Math.min(seigniorageSaved, _ArbiTenAmount));

        IBasisAsset(_10BOND).burnFrom(msg.sender, _bondAmount);
        IERC20(ArbiTen).safeTransfer(msg.sender, _ArbiTenAmount);

        //_updateArbiTenPrice();
        treasuryUpdates();

        emit RedeemedBonds(msg.sender, _ArbiTenAmount, _bondAmount);
    }

    function _sendToBoardroom(uint _amount) internal {
        IBasisAsset(ArbiTen).mint(address(this), _amount);

        uint _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(ArbiTen).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(ArbiTen).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        uint _insuranceFundSharedAmount = 0;
        if (insuranceFundSharedPercent > 0) {
            _insuranceFundSharedAmount = _amount.mul(insuranceFundSharedPercent).div(10000);
            IERC20(ArbiTen).transfer(insuranceFund, _insuranceFundSharedAmount);
            emit InsuranceFundFunded(block.timestamp, _insuranceFundSharedAmount);
        }

        uint _equityFundSharedAmount = 0;
        if (equityFundSharedPercent > 0) {
            _equityFundSharedAmount = _amount.mul(equityFundSharedPercent).div(10000);
            IERC20(ArbiTen).transfer(equityFund, _equityFundSharedAmount);
            emit EquityFundFunded(block.timestamp, _equityFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount)
                            .sub(_insuranceFundSharedAmount).sub(_equityFundSharedAmount);

        IERC20(ArbiTen).safeApprove(boardroom, 0);
        IERC20(ArbiTen).safeApprove(boardroom, _amount);

        IBoardroom(boardroom).allocateSeigniorage(_amount);

        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint _ArbiTenSupply) internal returns (uint) {
        if (_ArbiTenSupply >= ArbiTenSupplyTarget) {
            ArbiTenSupplyTarget = ArbiTenSupplyTarget.mul(12500).div(10000); // +25%
            maxSupplyExpansionPercent = maxSupplyExpansionPercent.mul(9500).div(10000); // -5%
            if (maxSupplyExpansionPercent < minMaxSupplyExpansionPercent) {
                maxSupplyExpansionPercent = minMaxSupplyExpansionPercent; // min 0.1% by default
            }
        }
        return maxSupplyExpansionPercent;
    }

    function getArbiTenExpansionRate() public view returns (uint _rate) {
        if (epoch < bootstrapEpochs) { // 24 first epochs with 3.5% expansion
            _rate = bootstrapSupplyExpansionPercent;
        } else {
            uint _twap = getArbiTenPrice();
            if (_twap >= ArbiTenPriceCeiling) {
                uint _percentage = _twap.sub(ArbiTenPriceOne); // 1% = 1e3
                uint _mse = maxSupplyExpansionPercent.mul(1e13);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                _rate = _percentage.div(1e13);
            }
        }
    }

    function getArbiTenExpansionAmount() external view returns (uint) {
        uint ArbiTenSupply = getArbiTenCirculatingSupply().sub(seigniorageSaved);
        uint bondSupply = IERC20(_10BOND).totalSupply();
        uint _rate = getArbiTenExpansionRate();
        if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
            // saved enough to pay debt, mint as usual rate
            return ArbiTenSupply.mul(_rate).div(10000);
        } else {
            // have not saved enough to pay debt, mint more
            uint _seigniorage = ArbiTenSupply.mul(_rate).div(10000);
            return _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
        }
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        require(IBoardroom(boardroom).totalSupply() > 0, "cannot update if boardroom total supply is 0");
        _updateArbiTenPrice();
        _update10SHAREPrice();

        previousEpochArbiTenPrice = getArbiTenPrice();
        uint ArbiTenSupply = getArbiTenCirculatingSupply().sub(seigniorageSaved);
        if (epoch < bootstrapEpochs) {
            // 21 first epochs with 3.5% expansion
            _sendToBoardroom(ArbiTenSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
            emit Seigniorage(epoch, previousEpochArbiTenPrice, ArbiTenSupply.mul(bootstrapSupplyExpansionPercent).div(10000));
        } else {
            if (previousEpochArbiTenPrice >= ArbiTenPriceCeiling) {
                IBoardroom(boardroom).setWithdrawFee(0);
                // Expansion ($ArbiTen Price > 0.1 $eth): there is some seigniorage to be allocated
                uint bondSupply = IERC20(_10BOND).totalSupply();
                uint _percentage = previousEpochArbiTenPrice.sub(ArbiTenPriceOne);
                uint _savedForBond;
                uint _savedForBoardroom;
                uint _mse = _calculateMaxSupplyExpansionPercent(ArbiTenSupply).mul(1e13);
                if (_percentage > _mse) {
                    _percentage = _mse;
                }
                if (seigniorageSaved >= bondSupply.mul(bondDepletionFloorPercent).div(10000)) {
                    // saved enough to pay debt, mint as usual rate
                    _savedForBoardroom = ArbiTenSupply.mul(_percentage).div(ArbiTenPriceOne);
                } else {
                    // have not saved enough to pay debt, mint more
                    uint _seigniorage = ArbiTenSupply.mul(_percentage).div(ArbiTenPriceOne);
                    _savedForBoardroom = _seigniorage.mul(seigniorageExpansionFloorPercent).div(10000);
                    _savedForBond = _seigniorage.sub(_savedForBoardroom);
                    if (mintingFactorForPayingDebt > 0) {
                        _savedForBond = _savedForBond.mul(mintingFactorForPayingDebt).div(10000);
                    }
                }
                if (_savedForBoardroom > 0) {
                    _sendToBoardroom(_savedForBoardroom);
                }
                if (_savedForBond > 0) {
                    seigniorageSaved = seigniorageSaved.add(_savedForBond);
                    IBasisAsset(ArbiTen).mint(address(this), _savedForBond);
                    emit TreasuryFunded(block.timestamp, _savedForBond);
                }
                emit Seigniorage(epoch, previousEpochArbiTenPrice, _savedForBoardroom);
            } else {
                IBoardroom(boardroom).setWithdrawFee(boardroomWithdrawFee);
                emit Seigniorage(epoch, previousEpochArbiTenPrice, 0);
            }
        }
    }

    function treasuryUpdates() public {
        bool hasReverted = false;

        try this.allocateSeigniorage() {} catch {
            hasReverted = true;
        }
        if (hasReverted) {
            _updateArbiTenPrice();
            _update10SHAREPrice();
        }

        try this.refreshCollateralRatio() {} catch {}
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(ArbiTen), "ArbiTen");
        require(address(_token) != address(_10BOND), "_10BOND");
        require(address(_token) != address(_10SHARE), "share");
        _token.safeTransfer(_to, _amount);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetReserveFund(address _reserveFund) external onlyOperator {
        IBoardroom(boardroom).setReserveFund(_reserveFund);
    }

    function boardroomSetLockUp(uint _withdrawLockupEpochs, uint _rewardLockupEpochs) external onlyOperator {
        IBoardroom(boardroom).setLockUp(_withdrawLockupEpochs, _rewardLockupEpochs);
    }

    function boardroomAllocateSeigniorage(uint amount) external onlyOperator {
        IERC20(ArbiTen).safeApprove(boardroom, amount);
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(_token, _amount, _to);
    }

    function hasPool(address _address) external view returns (bool) {
        return pools[_address] == true;
    }

    function setRedemptionFee(uint _redemption_fee) public onlyOperator {
        require(_redemption_fee < 100000, "redemption fee too high");
        redemption_fee = _redemption_fee;
    }

    function setMintingFee(uint _minting_fee) public onlyOperator {
        require(_minting_fee < 100000, "minting fee too high");
        minting_fee = _minting_fee;
    }

    function setRatioStep(uint _ratio_step) public onlyOperator {
        ratio_step = _ratio_step;
    }

    function setPriceTarget(uint _price_target) public onlyOperator {
        price_target = _price_target;
    }

    function setRefreshCooldown(uint _refresh_cooldown) public onlyOperator {
        refresh_cooldown = _refresh_cooldown;
    }

    function setPriceBand(uint _price_band) external onlyOperator {
        price_band = _price_band;
    }

    function toggleCollateralRatio() public onlyOperator {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    function toggleEffectiveCollateralRatio() public onlyOperator {
        using_effective_collateral_ratio = !using_effective_collateral_ratio;
    }


    /* ========== EMERGENCY ========== */

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data
    ) public onlyOperator returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, string("Treasury::executeTransaction: Transaction execution reverted."));
        emit TransactionExecuted(target, value, signature, data);
        return returnData;
    }
}

pragma solidity >0.6.12;

contract ContractGuard {
    mapping(uint => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;

        _;
    }
}