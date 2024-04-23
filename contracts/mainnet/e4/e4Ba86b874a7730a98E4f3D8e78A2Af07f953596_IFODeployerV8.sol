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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@openzeppelin-4.5.0/contracts/utils/math/SafeMath.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVeCake {
    function getUserInfo(address _user) external view returns (
        int128 amount,
        uint256 end,
        address cakePoolProxy,
        uint128 cakeAmount,
        uint48 lockEndTime,
        uint48 migrationTime,
        uint16 cakePoolType,
        uint16 withdrawFlag
    );

    function balanceOfAtTime(address _user, uint256 _timestamp) external view returns (uint256);
}

interface IIFODeployer {
    function currIFOAddress() external view returns (address);
}

interface IIFOInitializable {
    function endTimestamp() external view returns (uint256);
}

contract ICakeV3 is Ownable {
    using SafeMath for uint256;

    address public admin;

    address public immutable veCakeAddress;

    address public ifoDeployerAddress;

    uint256 public ratio;
    uint256 public constant RATION_PRECISION = 1000;

    uint256 public constant MIN_CEILING_DURATION = 1 weeks;

    event UpdateRatio(uint256 newRatio);
    event UpdateIfoDeployerAddress(address indexed newAddress);

    /**
     * @notice Constructor
     * @param _veCakeAddress: veCake contract
     */
    constructor(
        address _veCakeAddress
    ) public {
        veCakeAddress = _veCakeAddress;
        admin = owner();
        ratio = 1000;
    }

    /**
     * @notice calculate iCake credit per user.
     * @param _user: user address.
     * @param _endTime: user lock end time on veCake contract.
     */
    function getUserCreditWithTime(address _user, uint256 _endTime) external view returns (uint256) {
        require(_user != address(0), "getUserCredit: Invalid user address");

        // require the end time must be in the future
        // require(_endTime > block.timestamp, "end must be in future");
        // instead let's filter the time to current if too old
        if (_endTime <= block.timestamp){
            _endTime = block.timestamp;
        }

        return _sumUserCredit(_user, _endTime);
    }

    /**
     * @notice calculate iCake credit per user with Ifo address.
     * @param _user: user address.
     * @param _ifo: the ifo contract.
     */
    function getUserCreditWithIfoAddr(address _user, address _ifo) external view returns (uint256) {
        require(_user != address(0), "getUserCredit: Invalid user address");
        require(_ifo != address(0), "getUserCredit: Invalid ifo address");

        uint256 _endTime = IIFOInitializable(_ifo).endTimestamp();

        if (_endTime <= block.timestamp){
            _endTime = block.timestamp;
        }

        return _sumUserCredit(_user, _endTime);
    }

    /**
     * @notice calculate iCake credit per user for next ifo.
     * @param _user: user address.
     */
    function getUserCreditForNextIfo(address _user) external view returns (uint256) {
        require(_user != address(0), "getUserCredit: Invalid user address");

        address currIFOAddress = IIFODeployer(ifoDeployerAddress).currIFOAddress();

        uint256 _endTime = block.timestamp;
        if (currIFOAddress != address(0)) {
            _endTime = IIFOInitializable(currIFOAddress).endTimestamp();

            if (_endTime <= block.timestamp){
                _endTime = block.timestamp;
            }
        }

        return _sumUserCredit(_user, _endTime);
    }

    function getUserCredit(address _user) external view returns (uint256) {
        require(_user != address(0), "getUserCredit: Invalid user address");

        uint256 _endTime = IIFOInitializable(msg.sender).endTimestamp();

        return _sumUserCredit(_user, _endTime);
    }

    /**
     * @notice update ratio for iCake calculation.
     * @param _newRatio: new ratio
     */
    function updateRatio(uint256 _newRatio) external onlyOwner {
        require(_newRatio <= RATION_PRECISION, "updateRatio: Invalid ratio");
        require(ratio != _newRatio, "updateRatio: Ratio not changed");
        ratio = _newRatio;
        emit UpdateRatio(ratio);
    }

    /**
     * @notice update deployer address of IFO.
     * @param _newAddress: new deployer address
     */
    function updateIfoDeployerAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "updateIfoDeployerAddress: Address can not be empty");
        ifoDeployerAddress = _newAddress;
        emit UpdateIfoDeployerAddress(_newAddress);
    }

    /**
     * @notice get user and proxy credit from veCake contract and sum together
     * @param _user user's address
     * @param _endTime timestamp to calculate user's veCake amount
     */
    function _sumUserCredit(address _user, uint256 _endTime) internal view returns (uint256) {
        // get native
        uint256 veNative = IVeCake(veCakeAddress).balanceOfAtTime(_user, _endTime);

        // get proxy/migrated
        uint256 veMigrate = 0;
        ( , ,address cakePoolProxy, , , , , )  = IVeCake(veCakeAddress).getUserInfo(_user);
        if (cakePoolProxy != address(0)) {
            veMigrate = IVeCake(veCakeAddress).balanceOfAtTime(cakePoolProxy, _endTime);
        }

        return (veNative + veMigrate) * ratio / RATION_PRECISION;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/utils/SafeERC20.sol";

import "./IFOInitializableV8.sol";

/**
 * @title IFODeployerV8
 */
contract IFODeployerV8 is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_BUFFER_SECONDS = 86400 * 7; // (7 days on BSC)
    uint256 public constant MAX_BUFFER_SECONDS_VESTING = 86400 * 30; // (365 days on BSC)

    address public currIFOAddress;

    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);
    event NewIFOContract(address indexed ifoAddress);

    error LpTokenSameWithOfferingToken();
    error AdminAddressIsNull();
    error EndTimeTooFar();
    error StartTimeMustInferiorToEndTime();
    error StartTimeMustGreaterThanCurrentBlockTime();
    error VestingStartTimeMustGreaterThanEndTime();
    error VestingStartTimeTooFar();

    /**
     * @notice It creates the IFO contract and initializes the contract.
     * @dev It can only be called once.
     * @param _addresses: [0] lpToken [1] offeringToken [2] pancakeProfile [3] iCake [4] adminAddress [5] admissionProfile
     * @param _startAndEndTimestamps: [0] startTimestamp [1] endTimestamp
     * @param _maxPoolId: maximum id of pools, sometimes only public sale exist
     * @param _pointThreshold: threshold of user's point in pancake profile
     * @param _vestingStartTime: the start timestamp of vesting
     */
    function createIFO(
        address[] calldata _addresses,
        uint256[] calldata _startAndEndTimestamps,
        uint8 _maxPoolId,
        uint256 _pointThreshold,
        uint256 _vestingStartTime
    ) external onlyOwner {
        require(IERC20(_addresses[0]).totalSupply() >= 0);
        require(IERC20(_addresses[1]).totalSupply() >= 0);
        if (_addresses[0] == _addresses[1]) revert LpTokenSameWithOfferingToken();
        if (_addresses[4] == address(0)) revert AdminAddressIsNull();
        if (_startAndEndTimestamps[1] >= (block.timestamp + MAX_BUFFER_SECONDS)) revert EndTimeTooFar();
        if (_startAndEndTimestamps[0] >= _startAndEndTimestamps[1]) revert StartTimeMustInferiorToEndTime();
        if (_startAndEndTimestamps[0] <= block.timestamp) revert StartTimeMustGreaterThanCurrentBlockTime();
        if (_vestingStartTime != 0) {
            if (_vestingStartTime > _startAndEndTimestamps[1] + MAX_BUFFER_SECONDS_VESTING) revert VestingStartTimeTooFar();
        }

        bytes memory bytecode = type(IFOInitializableV8).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_addresses[0], _addresses[1], _startAndEndTimestamps[0]));
        address ifoAddress;

        assembly {
            ifoAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IFOInitializableV8(ifoAddress).initialize(
            _addresses,
            _startAndEndTimestamps,
            MAX_BUFFER_SECONDS,
            _maxPoolId,
            _pointThreshold,
            _vestingStartTime
        );

        if (currIFOAddress != ifoAddress) {
            currIFOAddress = ifoAddress;
        }

        emit NewIFOContract(ifoAddress);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IERC20(_tokenAddress).balanceOf(address(this));
        require(balanceToRecover > 0, "Operations: Balance must be > 0");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), balanceToRecover);

        emit AdminTokenRecovery(_tokenAddress, balanceToRecover);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin-4.5.0/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-4.5.0/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IIFOV8.sol";
import "./libraries/IFOLibV8.sol";
import "./utils/WhiteListV2.sol";
import "./interfaces/IPancakeProfile.sol";
import "./ICakeV3.sol";

/**
 * @title IFOInitializableV8
 */
contract IFOInitializableV8 is IIFOV8, ReentrancyGuard, Whitelist {
    using SafeERC20 for IERC20;

    // The address of the smart chef factory
    address private immutable IFO_FACTORY;

    // Whether it is initialized
    bool private isInitialized;

    // all the addresses
    // [0] lpToken [1] offeringToken [2] pancakeProfile [3] iCake [4] adminAddress [5] admissionProfile
    address[6] public addresses;

    // The timestamp when IFO starts
    uint256 public startTimestamp;

    // The timestamp when IFO ends
    uint256 public endTimestamp;

    // Max buffer seconds (for sanity checks)
    uint256 public MAX_BUFFER_SECONDS;

    // Max pool id (sometimes only public sale exist)
    uint8 public MAX_POOL_ID;

    // The minimum point special sale require
    uint256 public pointThreshold;

    // point config
    PointConfig public pointConfig;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 raisingAmountPool; // amount of tokens raised for the pool (in LP tokens)
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
        bool hasTax; // tax on the overflow (if any, it works with _calculateTaxOverflow)
        uint256 flatTaxRate; // new rate for flat tax
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
        uint256 sumTaxesOverflow; // total taxes collected (starts at 0, increases with each harvest if overflow)
        SaleType saleType; // previously bool checking if a sale is special(private), currently uint act as "sale type"
        // 0: public sale
        // 1: private sale
        // 2: basic sale
        VestingConfig vestingConfig;
    }

    // Array of PoolCharacteristics of size NUMBER_POOLS
    PoolCharacteristics[2] private _poolInformation;

    // Checks if user has claimed points
    mapping(address => bool) private _hasClaimedPoints;

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool; // How many tokens the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
    }

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // It maps user address to credit used amount
    mapping(address => uint256) public userCreditUsed;

    // It maps if nft token id was used
    mapping(uint256 => address) public tokenIdUsed;

    // It maps user address with NFT id
    mapping(address => uint256) public userNftTokenId;

    // vesting startTime, everyone will be started at same timestamp
    uint256 public vestingStartTime;

    // A flag for vesting is being revoked
    bool public vestingRevoked;

    // Struct that contains vesting schedule
    struct VestingSchedule {
        bool isVestingInitialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // pool id
        uint8 pid;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens has been released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    // Admin withdraw events
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

    // Create VestingSchedule event
    event CreateVestingSchedule(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

    // Event for new start & end timestamps
    event NewStartAndEndTimestamps(uint256 startTimestamp, uint256 endTimestamp);

    // Event with point parameters for IFO
    event PointParametersSet(uint256 campaignId, uint256 numberPoints, uint256 thresholdPoints);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint256 raisingAmountPool, uint8 pid);

    // Event when released new amount
    event Released(address indexed beneficiary, uint256 amount);

    // Event when revoked
    event Revoked();

    error PoolIdNotValid();
    error TokensNotDepositedProperly();
    error NotEnoughIFOCreditLeft();
    error NewAmountAboveUserLimit();
    error ProfileNotActive();
    error NotMeetAnyoneOfRequiredConditions();
    error NFTRequirementsMustBeMetForHarvest();
    error NFTUsedByAnotherAddressAlready();
    error NFTTokenIdNotSameAsRegistered();
    error CanNotBeLPToken();
    error CanNotBeOfferingToken();
    error VestingOnlyBeneficiaryOrOwnerCanRelease();
    error VestingNotEnoughToRelease();
    error VestingIsRevoked();
    error OnlyOwner();

    /**
     * @notice Constructor
     */
    constructor() public {
        IFO_FACTORY = msg.sender;
    }

    /**
     * @notice It initializes the contract
     * @dev It can only be called once.
     * @param _addresses: [0] lpToken [1] offeringToken [2] pancakeProfile [3] iCake [4] adminAddress [5] admissionProfile
     * @param _startAndEndTimestamps: [0] startTimestamp [1] endTimestamp
     * @param _maxBufferSeconds: maximum buffer of blocks from the current block number
     * @param _maxPoolId: maximum id of pools, sometimes only public sale exist
     * @param _pointThreshold: threshold of user's point in pancake profile
     * @param _vestingStartTime: the start timestamp of vesting
     */
    function initialize(
        address[] calldata _addresses,
        uint256[] calldata _startAndEndTimestamps,
        uint256 _maxBufferSeconds,
        uint8 _maxPoolId,
        uint256 _pointThreshold,
        uint256 _vestingStartTime
    ) public {
        // Check validation
        IFOLibV8.InitializePreCheck(
            isInitialized,
            IFO_FACTORY,
            _addresses.length,
            _startAndEndTimestamps.length,
            _maxPoolId
        );

        // Make this contract initialized
        isInitialized = true;

        if (_addresses[2] != address(0)) {
            IPancakeProfile(_addresses[2]).getTeamProfile(1);
        }

        if (_addresses[3] != address(0)) {
            ICakeV3(_addresses[3]).admin();
        }

        // [0] lpToken
        // [1] offeringToken
        // [2] pancakeProfile
        // [3] iCake
        // [4] adminAddress
        // [5] admissionProfile
        for (uint8 i = 0; i < _addresses.length; i++) {
            addresses[i] = _addresses[i];
        }

        startTimestamp = _startAndEndTimestamps[0];
        endTimestamp = _startAndEndTimestamps[1];
        MAX_BUFFER_SECONDS = _maxBufferSeconds;
        MAX_POOL_ID = _maxPoolId;
        pointThreshold = _pointThreshold;
        vestingStartTime = _vestingStartTime;

        // Transfer ownership to admin
        transferOwnership(_addresses[4]);
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _amount: the number of LP token used (18 decimals)
     * @param _pid: pool id
     */
    function depositPool(uint256 _amount, uint8 _pid) external override nonReentrant {
        // Checks whether the pool id is valid
        _checkPid(_pid);

        // Check validation
        IFOLibV8.DepositPoolPreCheck(
            _amount,
            addresses[2], // pancakeProfileAddress
            _poolInformation[_pid].saleType,
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].raisingAmountPool,
            startTimestamp,
            endTimestamp
        );

        // Verify tokens were deposited properly
        if (IERC20(addresses[1]).balanceOf(address(this)) < totalTokensOffered) {
            revert TokensNotDepositedProperly();
        }

        if (_poolInformation[_pid].saleType == SaleType.PUBLIC || _poolInformation[_pid].saleType == SaleType.BASIC) {
            // public and basic sales
            if (addresses[3] != address(0) && _poolInformation[_pid].saleType != SaleType.BASIC) {
                // getUserCredit from ICake contract when it is presented and not basic sales
                uint256 ifoCredit = ICakeV3(addresses[3]).getUserCredit(msg.sender);

                if (userCreditUsed[msg.sender] + _amount > ifoCredit) {
                    revert NotEnoughIFOCreditLeft();
                }
            }

            _deposit(_amount, _pid);

            // Updates Accumulative deposit lpTokens
            userCreditUsed[msg.sender] = userCreditUsed[msg.sender] + (_poolInformation[_pid].saleType == SaleType.PUBLIC ? _amount : 0);
        } else {
            // private sales
            if (addresses[2] != address(0)) {
                (
                    ,
                    uint256 profileNumberPoints,
                    ,
                    address profileAddress,
                    uint256 tokenId,
                    bool active
                ) = IPancakeProfile(addresses[2]).getUserProfile(msg.sender);

                if (!active) revert ProfileNotActive();

                if (!_isQualifiedPoints(profileNumberPoints) &&
                    !isQualifiedWhitelist(msg.sender) &&
                    !_isQualifiedNFT(msg.sender, profileAddress, tokenId)) {
                    revert NotMeetAnyoneOfRequiredConditions();
                }

                // Update tokenIdUsed
                if (!_isQualifiedPoints(profileNumberPoints) &&
                    !isQualifiedWhitelist(msg.sender) &&
                    profileAddress == addresses[5]) {
                    if (tokenIdUsed[tokenId] == address(0)) {
                        // update tokenIdUsed
                        tokenIdUsed[tokenId] = msg.sender;
                    } else {
                        if (tokenIdUsed[tokenId] != msg.sender) {
                            revert NFTUsedByAnotherAddressAlready();
                        }
                    }
                    if (userNftTokenId[msg.sender] == 0) {
                        // update userNftTokenId
                        userNftTokenId[msg.sender] = tokenId;
                    } else {
                        if (userNftTokenId[msg.sender] != tokenId) {
                            revert NFTTokenIdNotSameAsRegistered();
                        }
                    }
                }
            }

            _deposit(_amount, _pid);
        }
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external override nonReentrant {
        // Checks whether the pool id is valid
        _checkPid(_pid);

        // Check validation
        IFOLibV8.HarvestPoolPreCheck(
            endTimestamp,
            _userInfo[msg.sender][_pid].amountPool,
            _userInfo[msg.sender][_pid].claimedPool
        );

        if (userNftTokenId[msg.sender] != 0) {
            (, , , address profileAddress, uint256 tokenId, bool isActive) = IPancakeProfile(addresses[2])
                .getUserProfile(msg.sender);

            if (!isActive || profileAddress != addresses[5] || userNftTokenId[msg.sender] != tokenId) {
                revert NFTRequirementsMustBeMetForHarvest();
            }
        }

        // Claim points if possible
        _claimPoints(msg.sender);

        // Updates the harvest status
        _userInfo[msg.sender][_pid].claimedPool = true;

        // Updates the vesting startTime
        if (vestingStartTime == 0) {
            vestingStartTime = block.timestamp;
        }

        // Initialize the variables for offering, refunding user amounts, and tax amount
        (
            uint256 offeringTokenAmount,
            uint256 refundingTokenAmount,
            uint256 userTaxOverflow
        ) = _calculateOfferingAndRefundingAmountsPool(msg.sender, _pid);

        // Increment the sumTaxesOverflow
        if (userTaxOverflow > 0) {
            _poolInformation[_pid].sumTaxesOverflow = _poolInformation[_pid].sumTaxesOverflow + userTaxOverflow;
        }

        // Transfer these tokens back to the user if quantity > 0
        if (offeringTokenAmount > 0) {
            if (100 - _poolInformation[_pid].vestingConfig.percentage > 0) {
                uint256 amount = offeringTokenAmount * (100 - _poolInformation[_pid].vestingConfig.percentage) / 100;

                // Transfer the tokens at TGE
                IERC20(addresses[1]).safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, refundingTokenAmount, _pid);
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].vestingConfig.percentage > 0) {
                uint256 amount = offeringTokenAmount * _poolInformation[_pid].vestingConfig.percentage / 100;

                // Create VestingSchedule object
                _createVestingSchedule(msg.sender, _pid, amount);

                emit CreateVestingSchedule(msg.sender, amount, refundingTokenAmount, _pid);
            }
        }

        if (refundingTokenAmount > 0) {
            IERC20(addresses[0]).safeTransfer(msg.sender, refundingTokenAmount);
        }
    }

    /**
     * @notice It allows the admin to withdraw funds
     * @param _lpAmount: the number of LP token to withdraw (18 decimals)
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external override {
        _isOwner();
        // Check validation
        IFOLibV8.FinalWithdrawPreCheck(
            _lpAmount,
            IERC20(addresses[0]).balanceOf(address(this)),
            _offerAmount,
            IERC20(addresses[1]).balanceOf(address(this))
        );

        if (_lpAmount > 0) {
            IERC20(addresses[0]).safeTransfer(msg.sender, _lpAmount);
        }

        if (_offerAmount > 0) {
            IERC20(addresses[1]).safeTransfer(msg.sender, _offerAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external {
        _isOwner();

        if (_tokenAddress == addresses[0]) {
            revert CanNotBeLPToken();
        }
        if (_tokenAddress == addresses[1]) {
            revert CanNotBeOfferingToken();
        }

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It sets parameters for pool
     * @param _offeringAmountPool: offering amount (in tokens)
     * @param _raisingAmountPool: raising amount (in LP tokens)
     * @param _limitPerUserInLP: limit per user (in LP tokens)
     * @param _hasTax: if the pool has a tax
     * @param _flatTaxRate: flat tax rate
     * @param _pid: pool id
     * @param _saleType: // previously bool checking if a sale is special(private), currently uint act as "sale type"
        // 0: public sale
        // 1: private sale
        // 2: basic sale
     * @param _vestingConfig: vesting config parameters
     * @dev This function is only callable by admin.
     */
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        bool _hasTax,
        uint256 _flatTaxRate,
        uint8 _pid,
        SaleType _saleType,
        VestingConfig calldata _vestingConfig
    ) external override {
        _isOwner();

        // Checks whether the pool id is valid
        _checkPid(_pid);

        // Check validation
        IFOLibV8.SetPoolPreCheck(
            startTimestamp,
            _hasTax,
            _flatTaxRate,
            _vestingConfig.percentage,
            _vestingConfig.duration,
            _vestingConfig.slicePeriodSeconds
        );

        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].raisingAmountPool = _raisingAmountPool;
        _poolInformation[_pid].limitPerUserInLP = _limitPerUserInLP;
        _poolInformation[_pid].hasTax = _hasTax;
        _poolInformation[_pid].flatTaxRate = _flatTaxRate;
        _poolInformation[_pid].saleType = _saleType;
        _poolInformation[_pid].vestingConfig.percentage = _vestingConfig.percentage;
        _poolInformation[_pid].vestingConfig.cliff = _vestingConfig.cliff;
        _poolInformation[_pid].vestingConfig.duration = _vestingConfig.duration;
        _poolInformation[_pid].vestingConfig.slicePeriodSeconds = _vestingConfig.slicePeriodSeconds;

        uint256 tokensDistributedAcrossPools;

        for (uint8 i = 0; i <= MAX_POOL_ID; i++) {
            tokensDistributedAcrossPools = tokensDistributedAcrossPools + _poolInformation[i].offeringAmountPool;
        }

        // Update totalTokensOffered
        totalTokensOffered = tokensDistributedAcrossPools;

        emit PoolParametersSet(_offeringAmountPool, _raisingAmountPool, _pid);
    }

    /**
     * @notice It updates point parameters for the IFO.
     * @param _pointConfig: the point reward and requirement for user participate in IFO
     * @dev This function is only callable by admin.
     */
    function updatePointParameters(
        PointConfig calldata _pointConfig
    ) external override {
        _isOwner();

        // Check validation
        IFOLibV8.UpdatePointParametersPreCheck(
            endTimestamp
        );

        pointConfig.numberPoints = _pointConfig.numberPoints;
        pointConfig.campaignId = _pointConfig.campaignId;
        pointConfig.thresholdPoints = _pointConfig.thresholdPoints;

        emit PointParametersSet(_pointConfig.campaignId, _pointConfig.numberPoints, _pointConfig.thresholdPoints);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @param _startAndEndTimestamps: [0] startTimestamp [1] endTimestamp
     * @dev This function is only callable by admin.
     */
    function updateStartAndEndTimestamps(uint256[] calldata _startAndEndTimestamps) external {
        _isOwner();

        // Check validation
        IFOLibV8.UpdateStartAndEndTimestampsPreCheck(
            MAX_BUFFER_SECONDS,
            _startAndEndTimestamps.length,
            startTimestamp,
            _startAndEndTimestamps[0], // startTimestamp
            _startAndEndTimestamps[1]  // endTimestamp
        );

        startTimestamp = _startAndEndTimestamps[0];
        endTimestamp = _startAndEndTimestamps[1];

        emit NewStartAndEndTimestamps(_startAndEndTimestamps[0], _startAndEndTimestamps[1]);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: pool id
     * @return raisingAmountPool: amount of LP tokens raised (in LP tokens)
     * @return offeringAmountPool: amount of tokens offered for the pool (in offeringTokens)
     * @return limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
     * @return hasTax: tax on the overflow (if any, it works with _calculateTaxOverflow)
     * @return flatTaxRate: new rate of flat tax
     * @return totalAmountPool: total amount pool deposited (in LP tokens)
     * @return sumTaxesOverflow: total taxes collected (starts at 0, increases with each harvest if overflow)
     */
    function viewPoolInformation(uint256 _pid)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        bool,
        uint256,
        uint256,
        SaleType
    ) {
        return (
            _poolInformation[_pid].raisingAmountPool,
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].limitPerUserInLP,
            _poolInformation[_pid].hasTax,
            _poolInformation[_pid].totalAmountPool,
            _poolInformation[_pid].sumTaxesOverflow,
            _poolInformation[_pid].saleType
        );
    }

    /**
     * @notice It returns the pool vesting information
     * @param _pid: pool id
     * @return vestingPercentage: the percentage of vesting part, claimingPercentage + vestingPercentage should be 100
     * @return vestingCliff: the cliff of vesting
     * @return vestingDuration: the duration of vesting
     * @return vestingSlicePeriodSeconds: the slice period seconds of vesting
     */
    function viewPoolVestingInformation(uint256 _pid)
    external
    view
    override
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        return (
            _poolInformation[_pid].vestingConfig.percentage,
            _poolInformation[_pid].vestingConfig.cliff,
            _poolInformation[_pid].vestingConfig.duration,
            _poolInformation[_pid].vestingConfig.slicePeriodSeconds
        );
    }

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _pid: pool id
     * @return It returns the tax percentage
     */
    function viewPoolTaxRateOverflow(uint256 _pid) external view returns (uint256) {
        if (!_poolInformation[_pid].hasTax) {
            return 0;
        } else {
            if (_poolInformation[_pid].flatTaxRate > 0) {
                return _poolInformation[_pid].flatTaxRate;
            } else {
                return
                    _calculateTaxOverflow(
                    _poolInformation[_pid].totalAmountPool,
                    _poolInformation[_pid].raisingAmountPool
                );
            }
        }
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids) external view returns (uint256[] memory) {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user information
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserInfo(address _user, uint8[] calldata _pids)
    external
    view
    returns (uint256[] memory, bool[] memory) {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i <= MAX_POOL_ID; i++) {
            amountPools[i] = _userInfo[_user][i].amountPool;
            statusPools[i] = _userInfo[_user][i].claimedPool;
        }
        return (amountPools, statusPools);
    }

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
    external
    view
    returns (uint256[3][] memory) {
        uint256[3][] memory amountPools = new uint256[3][](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;
            uint256 userTaxAmountPool;

            if (_poolInformation[_pids[i]].raisingAmountPool > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool,
                    userTaxAmountPool
                ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
            }

            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool, userTaxAmountPool];
        }
        return amountPools;
    }

    /**
     * @notice Returns the vesting schedule information of a given holder and index
     * @return The vesting schedule object
     */
    function getVestingScheduleByAddressAndIndex(address _holder, uint256 _index)
    external
    view
    returns (VestingSchedule memory)
    {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(_holder, _index));
    }

    /**
     * @notice Returns the total amount of vesting schedules
     * @return The vesting schedule total amount
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    /**
     * @notice Release vested amount of offering tokens
     * @param _vestingScheduleId the vesting schedule identifier
     */
    function release(bytes32 _vestingScheduleId) external nonReentrant {
        // Check validation
        IFOLibV8.IsVestingInitializedPreCheck(
            vestingSchedules[_vestingScheduleId].isVestingInitialized
        );

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        if (!isBeneficiary && !isOwner) {
            revert VestingOnlyBeneficiaryOrOwnerCanRelease();
        }
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount <= 0) {
            revert VestingNotEnoughToRelease();
        }
        vestingSchedule.released = vestingSchedule.released + vestedAmount;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - vestedAmount;
        IERC20(addresses[1]).safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit Released(vestingSchedule.beneficiary, vestedAmount);
    }

    /**
     * @notice Revokes all the vesting schedules
     */
    function revoke() external {
        _isOwner();

        if (vestingRevoked) {
            revert VestingIsRevoked();
        }

        vestingRevoked = true;
        emit Revoked();
    }

    /**
     * @notice Returns the number of vesting schedules managed by the contract
     * @return The number of vesting count
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    /**
     * @notice Returns the vested amount of tokens for the given vesting schedule identifier
     * @return The number of vested count
     */
    function computeReleasableAmount(bytes32 _vestingScheduleId) public view returns (uint256) {
        // Check validation
        IFOLibV8.IsVestingInitializedPreCheck(
            vestingSchedules[_vestingScheduleId].isVestingInitialized
        );

        return _computeReleasableAmount(vestingSchedules[_vestingScheduleId]);
    }

    /**
     * @notice Returns the vesting schedule information of a given identifier
     * @return The vesting schedule object
     */
    function getVestingSchedule(bytes32 _vestingScheduleId) public view returns (VestingSchedule memory) {
        return vestingSchedules[_vestingScheduleId];
    }

    /**
     * @notice Returns the amount of offering token that can be withdrawn by the owner
     * @return The amount of offering token
     */
    function getWithdrawableOfferingTokenAmount() public view returns (uint256) {
        return IERC20(addresses[1]).balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @notice Computes the next vesting schedule identifier for a given holder address
     * @return The id string
     */
    function computeNextVestingScheduleIdForHolder(address _holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(_holder, holdersVestingCount[_holder]);
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an index
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndIndex(address _holder, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_holder, _index));
    }

    /**
     * @notice Computes the next vesting schedule identifier for an address and an pid
     * @return The id string
     */
    function computeVestingScheduleIdForAddressAndPid(address _holder, uint8 _pid) external view returns (bytes32) {
        // Checks whether the pool id is valid
        _checkPid(_pid);

        bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(_holder, 0);
        VestingSchedule memory vestingSchedule = vestingSchedules[vestingScheduleId];
        if (vestingSchedule.pid == _pid) {
            return vestingScheduleId;
        } else {
            return computeVestingScheduleIdForAddressAndIndex(_holder, 1);
        }
    }

    /**
     * @notice Computes the releasable amount of tokens for a vesting schedule
     * @return The amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        if (block.timestamp < vestingStartTime + _poolInformation[_vestingSchedule.pid].vestingConfig.cliff) {
            return 0;
        } else if (
            block.timestamp >= vestingStartTime + _poolInformation[_vestingSchedule.pid].vestingConfig.duration ||
            vestingRevoked
        ) {
            return _vestingSchedule.amountTotal - _vestingSchedule.released;
        } else {
            uint256 timeFromStart = block.timestamp - vestingStartTime;
            uint256 secondsPerSlice = _poolInformation[_vestingSchedule.pid].vestingConfig.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            uint256 vestedAmount = _vestingSchedule.amountTotal * vestedSeconds / _poolInformation[_vestingSchedule.pid].vestingConfig.duration;
            vestedAmount = vestedAmount - _vestingSchedule.released;
            return vestedAmount;
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _pid the pool id
     * @param _amount total amount of tokens to be released at the end of the vesting
     */
    function _createVestingSchedule(
        address _beneficiary,
        uint8 _pid,
        uint256 _amount
    ) internal {
        require(
            getWithdrawableOfferingTokenAmount() >= _amount,
            "can not create vesting schedule with sufficient tokens"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        require(vestingSchedules[vestingScheduleId].beneficiary == address(0), "vestingScheduleId is been created");
        vestingSchedules[vestingScheduleId] = VestingSchedule(true, _beneficiary, _pid, _amount, 0);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + _amount;
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;
    }

    /**
     * @notice It allows users to claim points
     * @param _user: user address
     */
    function _claimPoints(address _user) internal {
        if (addresses[2] != address(0)) {
            if (!_hasClaimedPoints[_user] && pointConfig.numberPoints > 0) {
                uint256 sumPools;
                for (uint8 i = 0; i <= MAX_POOL_ID; i++) {
                    sumPools = sumPools + _userInfo[msg.sender][i].amountPool;
                }
                if (sumPools > pointConfig.thresholdPoints) {
                    _hasClaimedPoints[_user] = true;
                    // Increase user points
                    IPancakeProfile(addresses[2]).increaseUserPoints(msg.sender, pointConfig.numberPoints, pointConfig.campaignId);
                }
            }
        }
    }

    /**
     * @notice It calculates the tax overflow given the raisingAmountPool and the totalAmountPool.
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @return It returns the tax percentage
     */
    function _calculateTaxOverflow(uint256 _totalAmountPool, uint256 _raisingAmountPool)
    internal
    pure
    returns (uint256)
    {
        uint256 ratioOverflow = _totalAmountPool / _raisingAmountPool;
        if (ratioOverflow >= 1500) {
            return 250000000; // 0.0125%
        } else if (ratioOverflow >= 1000) {
            return 500000000; // 0.05%
        } else if (ratioOverflow >= 500) {
            return 1000000000; // 0.1%
        } else if (ratioOverflow >= 250) {
            return 1250000000; // 0.125%
        } else if (ratioOverflow >= 100) {
            return 1500000000; // 0.15%
        } else if (ratioOverflow >= 50) {
            return 2500000000; // 0.25%
        } else {
            return 5000000000; // 0.5%
        }
    }

    /**
     * @notice It calculates the offering amount for a user and the number of LP tokens to transfer back.
     * @param _user: user address
     * @param _pid: pool id
     * @return {uint256, uint256, uint256} It returns the offering amount, the refunding amount (in LP tokens),
     * and the tax (if any, else 0)
     */
    function _calculateOfferingAndRefundingAmountsPool(address _user, uint8 _pid)
    internal
    view
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 userOfferingAmount;
        uint256 userRefundingAmount;
        uint256 taxAmount;

        if (_poolInformation[_pid].totalAmountPool > _poolInformation[_pid].raisingAmountPool) {
            // Calculate allocation for the user
            uint256 allocation = _getUserAllocationPool(_user, _pid);

            // Calculate the offering amount for the user based on the offeringAmount for the pool
            userOfferingAmount = _poolInformation[_pid].offeringAmountPool * allocation / 1e12;

            // Calculate the payAmount
            uint256 payAmount = _poolInformation[_pid].raisingAmountPool * allocation / 1e12;

            // Calculate the pre-tax refunding amount
            userRefundingAmount = _userInfo[_user][_pid].amountPool - payAmount;

            // Retrieve the tax rate
            if (_poolInformation[_pid].hasTax) {
                uint256 tax = _poolInformation[_pid].flatTaxRate;

                if (tax == 0) {
                    tax = _calculateTaxOverflow(
                        _poolInformation[_pid].totalAmountPool,
                        _poolInformation[_pid].raisingAmountPool
                    );
                }
                // Calculate the final taxAmount
                taxAmount = userRefundingAmount * tax / 1e12;

                // Adjust the refunding amount
                userRefundingAmount = userRefundingAmount - taxAmount;
            }
        } else {
            // _userInfo[_user] / (raisingAmount / offeringAmount)
            userOfferingAmount = _userInfo[_user][_pid].amountPool * _poolInformation[_pid].offeringAmountPool / _poolInformation[_pid].raisingAmountPool;
        }
        return (userOfferingAmount, userRefundingAmount, taxAmount);
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_pid > MAX_POOL_ID) {
            return 0;
        }

        if (_poolInformation[_pid].totalAmountPool > 0) {
            return _userInfo[_user][_pid].amountPool * 1e12 / _poolInformation[_pid].totalAmountPool;
        } else {
            return 0;
        }
    }

    function isQualifiedWhitelist(address _user) public view returns (bool) {
        return isWhitelisted(_user);
    }

    function isQualifiedPoints(address _user) external view returns (bool) {
        if (addresses[2] == address(0)) {
            return true;
        }
        if (!IPancakeProfile(addresses[2]).getUserStatus(_user)) {
            return false;
        }

        (, uint256 profileNumberPoints, , , , ) = IPancakeProfile(addresses[2]).getUserProfile(_user);
        return _isQualifiedPoints(profileNumberPoints);
    }

    function isQualifiedNFT(address _user) external view returns (bool) {
        if (addresses[2] == address(0)) {
            return true;
        }
        if (!IPancakeProfile(addresses[2]).getUserStatus(_user)) {
            return false;
        }

        (, , , address profileAddress, uint256 tokenId, ) = IPancakeProfile(addresses[2]).getUserProfile(
            _user
        );

        return _isQualifiedNFT(_user, profileAddress, tokenId);
    }

    function _isQualifiedPoints(uint256 profileNumberPoints) internal view returns (bool) {
        return (pointThreshold != 0 && profileNumberPoints >= pointThreshold);
    }

    function _isQualifiedNFT(
        address _user,
        address profileAddress,
        uint256 tokenId
    ) internal view returns (bool) {
        return (profileAddress == addresses[5] &&
            (tokenIdUsed[tokenId] == address(0) || tokenIdUsed[tokenId] == _user));
    }

    function _isOwner() internal view {
        if (owner() != msg.sender) revert OnlyOwner();
    }

    function _deposit(uint256 _amount, uint8 _pid) internal {
        // Transfers funds to this contract
        IERC20(addresses[0]).safeTransferFrom(msg.sender, address(this), _amount);

        // Update the user status
        _userInfo[msg.sender][_pid].amountPool = _userInfo[msg.sender][_pid].amountPool + _amount;

        // Check if the pool has a limit per user
        if (_poolInformation[_pid].limitPerUserInLP > 0) {
            // Checks whether the limit has been reached
            if (_userInfo[msg.sender][_pid].amountPool > _poolInformation[_pid].limitPerUserInLP) {
                revert NewAmountAboveUserLimit();
            }
        }

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool = _poolInformation[_pid].totalAmountPool + _amount;

        emit Deposit(msg.sender, _amount, _pid);
    }

    function _checkPid(uint8 _pid) internal view {
        if (_pid > MAX_POOL_ID) {
            revert PoolIdNotValid();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/** @title IIFOV8.
 * @notice It is an interface for IFOV8.sol
 */
interface IIFOV8 {
    enum SaleType {
        PUBLIC, //0
        PRIVATE, //1
        BASIC //2
    }

    struct VestingConfig {
        uint256 percentage;
        uint256 cliff;
        uint256 duration;
        uint256 slicePeriodSeconds;
    }

    struct PointConfig {
        uint256 campaignId;
        uint256 numberPoints;
        uint256 thresholdPoints;
    }

    function depositPool(uint256 _amount, uint8 _pid) external;

    function harvestPool(uint8 _pid) external;

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external;

    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _limitPerUserInLP,
        bool _hasTax,
        uint256 _flatTaxRate,
        uint8 _pid,
        SaleType _saleType,
        VestingConfig memory _vestingConfig
    ) external;

    function updatePointParameters(
        PointConfig memory _pointConfig
    ) external;

    function viewPoolInformation(uint256 _pid)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        bool,
        uint256,
        uint256,
        SaleType
    );

    function viewPoolVestingInformation(uint256 _pid)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256
    );

    function viewPoolTaxRateOverflow(uint256 _pid) external view returns (uint256);

    function viewUserAllocationPools(address _user, uint8[] calldata _pids) external view returns (uint256[] memory);

    function viewUserInfo(address _user, uint8[] calldata _pids)
    external
    view
    returns (uint256[] memory, bool[] memory);

    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
    external
    view
    returns (uint256[3][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IPancakeProfile {
    /**
     * @dev Check the user's profile for a given address
     */
    function getUserProfile(address _userAddress)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            bool
        );

    /**
     * @dev Check the user's status for a given address
     */
    function getUserStatus(address _userAddress) external view returns (bool);

    function getTeamProfile(uint256 _teamId)
    external
    view
    returns (
        string memory,
        string memory,
        uint256,
        uint256,
        bool
    );

    /**
     * @dev To increase the number of points for a user.
     * Callable only by point admins
     */
    function increaseUserPoints(
        address _userAddress,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IIFOV8.sol";
import "../interfaces/IPancakeProfile.sol";
import "../ICakeV3.sol";

library IFOLibV8 {

    error PoolIdNotValid();
    error EndTimeTooFar();
    error StartTimeMustInferiorToEndTime();
    error StartTimeMustGreaterThanCurrentBlockTime();
    error AlreadyInitialized();
    error NotFactory();
    error AddressesLengthNotCorrect();
    error StartAndEndTimestampsLengthNotCorrect();
    error ShouldNotLargerThanTheNumberOfPools();
    error MustHaveAnActiveProfile();
    error PoolNotSet();
    error TooEarly();
    error TooLate();
    error AmountMustExceedZero();
    error DidNotParticipate();
    error AlreadyHarvested();
    error NotEnoughLPTokens();
    error NotEnoughOfferingTokens();
    error IFOHasStarted();
    error IFOHasEnded();
    error FlatTaxRateMustBeLessThan1e12();
    error FlatTaxRateMustBe0WhenHasTaxIsFalse();
    error VestingPercentageShouldRangeIn0And100();
    error VestingDurationMustExceeds0();
    error VestingSlicePerSecondsMustBeExceeds1();
    error VestingSlicePerSecondsMustBeInteriorDuration();
    error VestingNotExist();

    function InitializePreCheck(
        bool isInitialized,
        address IFO_FACTORY,
        uint256 addresses_length,
        uint256 startAndEndTimestamps_length,
        uint8 maxPoolId
    ) internal view {
        if (isInitialized) {
            revert AlreadyInitialized();
        }

        if (msg.sender != IFO_FACTORY) {
            revert NotFactory();
        }

        if (addresses_length != 6) {
            revert AddressesLengthNotCorrect();
        }

        if (startAndEndTimestamps_length != 2) {
            revert StartAndEndTimestampsLengthNotCorrect();
        }

        if (maxPoolId >= 2) {
            revert ShouldNotLargerThanTheNumberOfPools();
        }
    }

    function DepositPoolPreCheck(
        uint256 amount,
        address pancakeProfileAddress,
        IIFOV8.SaleType saleType,
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal view {
        if (pancakeProfileAddress != address(0) && saleType != IIFOV8.SaleType.BASIC) {
            // Checks whether the user has an active profile when provided profile SC and not basic sale
            if (!IPancakeProfile(pancakeProfileAddress).getUserStatus(msg.sender)) {
                revert MustHaveAnActiveProfile();
            }
        }

        // Checks that pool was set
        if (offeringAmountPool == 0 || raisingAmountPool == 0) {
            revert PoolNotSet();
        }

        // Checks whether the timestamp is not too early
        if (block.timestamp <= startTimestamp) {
            revert TooEarly();
        }

        // Checks whether the timestamp is not too late
        if (block.timestamp > endTimestamp) {
            revert TooLate();
        }

        // Checks that the amount deposited is not inferior to 0
        if (amount == 0) {
            revert AmountMustExceedZero();
        }
    }

    function HarvestPoolPreCheck(
        uint256 endTimestamp,
        uint256 amountPool,
        bool claimedPool
    ) internal view {
        // Checks whether pool id is valid
        if (block.timestamp <= endTimestamp) {
            revert TooEarly();
        }

        // Checks whether the user has participated
        if (amountPool == 0) {
            revert DidNotParticipate();
        }

        // Checks whether the user has already harvested
        if (claimedPool) {
            revert AlreadyHarvested();
        }
    }

    function FinalWithdrawPreCheck(
        uint256 lpAmount,
        uint256 lpTokenBalanceOf,
        uint256 offerAmount,
        uint256 offeringTokenBalanceOf
    ) internal view {
        if (lpAmount > lpTokenBalanceOf) {
            revert NotEnoughLPTokens();
        }

        if (offerAmount > offeringTokenBalanceOf) {
            revert NotEnoughOfferingTokens();
        }
    }

    function SetPoolPreCheck(
        uint256 startTimestamp,
        bool hasTax,
        uint256 flatTaxRate,
        uint256 vestingPercentage,
        uint256 vestingDuration,
        uint256 vestingSlicePeriodSeconds
    ) internal view {
        if (block.timestamp >= startTimestamp) {
            revert IFOHasStarted();
        }

        if (flatTaxRate >= 1e12) {
            revert FlatTaxRateMustBeLessThan1e12();
        }

        if (vestingPercentage > 100) {
            revert VestingPercentageShouldRangeIn0And100();
        }

        if (vestingDuration == 0) {
            revert VestingDurationMustExceeds0();
        }

        if (vestingSlicePeriodSeconds < 1) {
            revert VestingSlicePerSecondsMustBeExceeds1();
        }

        if (vestingSlicePeriodSeconds > vestingDuration) {
            revert VestingSlicePerSecondsMustBeInteriorDuration();
        }

        if (!hasTax) {
            if (flatTaxRate != 0) {
                revert FlatTaxRateMustBe0WhenHasTaxIsFalse();
            }
        }
    }

    function UpdatePointParametersPreCheck(
        uint256 endTimestamp
    ) internal view {
        if (block.timestamp >= endTimestamp) {
            revert IFOHasEnded();
        }
    }

    function UpdateStartAndEndTimestampsPreCheck(
        uint256 MAX_BUFFER_SECONDS,
        uint256 startAndEndTimestamps_length,
        uint256 currentStartTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    ) internal view {
        if (startAndEndTimestamps_length != 2) {
            revert StartAndEndTimestampsLengthNotCorrect();
        }
        if (endTimestamp >= (block.timestamp + MAX_BUFFER_SECONDS)) revert EndTimeTooFar();
        if (block.timestamp >= currentStartTimestamp) revert IFOHasStarted();
        if (startTimestamp >= endTimestamp) revert StartTimeMustInferiorToEndTime();
        if (block.timestamp >= startTimestamp) revert StartTimeMustGreaterThanCurrentBlockTime();

    }

    function IsVestingInitializedPreCheck(bool isVestingInitialized) internal view {
        if (!isVestingInitialized) {
            revert VestingNotExist();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) private whitelist;

    event WhitelistedAddressAdded(address indexed _user);
    event WhitelistedAddressRemoved(address indexed _user);

    /**
     * @dev throws if user is not whitelisted.
     * @param _user address
     */
    modifier onlyIfWhitelisted(address _user) {
        require(whitelist[_user]);
        _;
    }

    /**
     * @dev add single address to whitelist
     */
    function addAddressToWhitelist(address _user) external onlyOwner {
        whitelist[_user] = true;
        emit WhitelistedAddressAdded(_user);
    }

    /**
     * @dev add addresses to whitelist
     */
    function addAddressesToWhitelist(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
            emit WhitelistedAddressAdded(_users[i]);
        }
    }

    /**
     * @dev remove single address from whitelist
     */
    function removeAddressFromWhitelist(address _user) external onlyOwner {
        whitelist[_user] = false;
        emit WhitelistedAddressRemoved(_user);
    }

    /**
     * @dev remove addresses from whitelist
     */
    function removeAddressesFromWhitelist(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = false;
            emit WhitelistedAddressRemoved(_users[i]);
        }
    }

    /**
     * @dev getter to determine if address is in whitelist
     */
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelist[_user];
    }
}