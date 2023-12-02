// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./utils/WhiteList.sol";

interface IERC20DetailedBytes is IERC20 {
	function name() external view returns (bytes32);

	function symbol() external view returns (bytes32);

	function decimals() external view returns (uint8);
}

/**
 * @title TestSale
 */
contract TestSale is ReentrancyGuard, Whitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Number of pools
    uint8 public constant NUMBER_POOLS = 10;

    // Precision
    uint256 public constant PRECISION = 1E18;

    // Offering token decimal
    uint256 public constant OFFERING_DECIMALS = 18;

    // It checks if token is accepted for payment
    mapping(address => bool) public isPaymentToken;
    address[] public allPaymentTokens;

    // It maps the payment token address to price feed address
    mapping(address => address) public priceFeed;
    address public ethPriceFeed;

    // It maps the payment token address to decimal
    mapping(address => uint8) public paymentTokenDecimal;

    // It checks if token is stable coin
    mapping(address => bool) public isStableToken;
    address[] public allStableTokens;

    // The offering token
    IERC20 public offeringToken;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Array of PoolCharacteristics of size NUMBER_POOLS
    PoolCharacteristics[NUMBER_POOLS] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    // Struct that contains each pool characteristics
    struct PoolCharacteristics {
        uint256 startTime; // The block timestamp when pool starts
        uint256 endTime; // The block timestamp when pool ends
        uint256 offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 soldAmountPool; // amount of tokens sold in the pool (in offeringTokens, additional precision is applied)
        uint256 minBuyAmount; // min amount of tokens user can buy for every purchase (if 0, it is ignored)
        uint256 limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
        uint256 totalAmountPool; // total amount pool deposited (in USD, decimal is 18)
        uint256 shortVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 longVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 shortVestingDuration; // Short vesting duration
        uint256 longVestingDuration; // Long vesting duration
        uint256 shortPrice; // token price for short purchase (in USD, decimal is 18)
        uint256 longPrice; // token price for long purchase (in USD, decimal is 18)
        uint256 vestingCliff; // Vesting cliff
        uint256 vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    // Struct that contains each user information for both pools
    struct UserInfo {
        uint256 amountPool; // How many USD the user has provided for pool
        bool claimedPool; // Whether the user has claimed (default: false) for pool
        uint256 shortAmount; // Amount of tokens user bought in short vesting price (additional precision is applied)
        uint256 longAmount; // Amount of tokens user bought in long vesting price (additional precision is applied)
    }

    enum VestingPlan { Short, Long }

    // vesting startTime, everyone will be started at same timestamp. pid => startTime
    mapping(uint256 => uint256) public vestingStartTime;

    // A flag for vesting is being revoked
    bool public vestingRevoked;

    // Struct that contains vesting schedule
    struct VestingSchedule {
        bool isVestingInitialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // pool id
        uint8 pid;
        // vesting plan
        VestingPlan vestingPlan;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens has been released
        uint256 released;
    }

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    mapping(uint8 => bool) public isWhitelistSale;

    bool public harvestAllowed;

    // Admin withdraw events
    event AdminWithdraw(uint256 amountOfferingToken, uint256 ethAmount, address[] tokens, uint256[] amounts);

    // Admin recovers token
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, address token, uint256 amount, uint256 usdAmount, uint256 boughtAmount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint8 indexed pid);

    // Create VestingSchedule event
    event CreateVestingSchedule(address indexed user, uint256 offeringAmount, uint8 indexed pid);

    // Event when parameters are set for one of the pools
    event PoolParametersSet(uint256 offeringAmountPool, uint8 pid);

    // Event when released new amount
    event Released(address indexed beneficiary, uint256 amount);

    // Event when revoked
    event Revoked();

    // Event when payment token added
    event PaymentTokenAdded(address token, address feed, uint8 decimal);

    // Event when payment token revoked
    event PaymentTokenRevoked(address token);

    // Event when stable token added
    event StableTokenAdded(address token, uint8 decimal);

    // Event when stable token revoked
    event StableTokenRevoked(address token);

    // Event when whitelist sale status flipped
    event WhitelistSaleFlipped(uint8 pid, bool current);

    // Event when harvest enabled status flipped
    event HarvestAllowedFlipped(bool current);

    // Event when offering token is set
    event OfferingTokenSet(address tokenAddress);

    // Modifier to prevent contracts to participate
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    // Modifier to check payment method
    modifier checkPayment(address token) {
        if (token != address(0)) {
            require(
                (
                    isStableToken[token] ||
                    (isPaymentToken[token] && priceFeed[token] != address(0))
                ) &&
                paymentTokenDecimal[token] > 0,
                "invalid token"
            );
        } else {
            require(ethPriceFeed != address(0), "price feed not set");
        }
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    /**
     * @notice Constructor
     */
    constructor(address _ethPriceFeed) public {
        (, int256 price, , , ) = AggregatorV3Interface(_ethPriceFeed).latestRoundData();
        require(price > 0, "invalid price feed");

        ethPriceFeed = _ethPriceFeed;
    }

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _pid: pool id
     * @param _token: payment token
     * @param _amount: the number of payment token being deposited
     * @param _minUsdAmount: minimum USD amount that must be converted from deposit token not to revert
     * @param _plan: vesting plan
     * @param _deadline: unix timestamp after which the transaction will revert
     */
    function depositPool(uint8 _pid, address _token, uint256 _amount, uint256 _minUsdAmount, VestingPlan _plan, uint256 _deadline) external payable nonReentrant notContract ensure(_deadline) {
        // Checks whether the pool id is valid
        require(_pid < NUMBER_POOLS, "Deposit: Non valid pool id");

        // Checks that pool was set
        require(_poolInformation[_pid].offeringAmountPool > 0, "Deposit: Pool not set");

        // Checks whether the block timestamp is not too early
        require(block.timestamp > _poolInformation[_pid].startTime, "Deposit: Too early");

        // Checks whether the block timestamp is not too late
        require(block.timestamp < _poolInformation[_pid].endTime, "Deposit: Too late");

        if(_token == address(0)) {
            _amount = msg.value;
        }
        // Checks that the amount deposited is not inferior to 0
        require(_amount > 0, "Deposit: Amount must be > 0");

        require(
            !isWhitelistSale[_pid] || _isQualifiedWhitelist(msg.sender),
            "Deposit: Must be whitelisted"
        );

        if (_token != address(0)) {
            // Transfers funds to this contract
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        (uint256 usdAmount, uint256 offeringAmount) = computeAmounts(_token, _amount, _pid, _plan);
        require(usdAmount >= _minUsdAmount, 'Deposit: Insufficient USD amount');
        require(offeringAmount >= _poolInformation[_pid].minBuyAmount.mul(PRECISION), 'Deposit: too small');
        // Update the user status
        _userInfo[msg.sender][_pid].amountPool = _userInfo[msg.sender][_pid].amountPool.add(usdAmount);
        if (_plan == VestingPlan.Short) {
            _userInfo[msg.sender][_pid].shortAmount = _userInfo[msg.sender][_pid].shortAmount.add(offeringAmount);
        } else if (_plan == VestingPlan.Long) {
            _userInfo[msg.sender][_pid].longAmount = _userInfo[msg.sender][_pid].longAmount.add(offeringAmount);
        }

        // Check if the pool has a limit per user
        if (_poolInformation[_pid].limitPerUserInLP > 0) {
            // Checks whether the limit has been reached
            require(
                _userInfo[msg.sender][_pid].amountPool <= _poolInformation[_pid].limitPerUserInLP,
                "Deposit: New amount above user limit"
            );
        }

        // Updates the totalAmount for pool
        _poolInformation[_pid].totalAmountPool = _poolInformation[_pid].totalAmountPool.add(usdAmount);
        _poolInformation[_pid].soldAmountPool = _poolInformation[_pid].soldAmountPool.add(offeringAmount);
        require(
            _poolInformation[_pid].soldAmountPool <= _poolInformation[_pid].offeringAmountPool.mul(PRECISION),
            "Deposit: Exceed pool offering amount"
        );

        emit Deposit(msg.sender, _token, _amount, usdAmount, offeringAmount, _pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     */
    function harvestPool(uint8 _pid) external nonReentrant notContract {
        require(harvestAllowed, "Harvest: Not allowed");
        // Checks whether it is too early to harvest
        require(block.timestamp > _poolInformation[_pid].endTime, "Harvest: Too early");

        // Checks whether pool id is valid
        require(_pid < NUMBER_POOLS, "Harvest: Non valid pool id");

        // Checks whether the user has participated
        require(_userInfo[msg.sender][_pid].amountPool > 0, "Harvest: Did not participate");

        // Checks whether the user has already harvested
        require(!_userInfo[msg.sender][_pid].claimedPool, "Harvest: Already done");

        // Updates the harvest status
        _userInfo[msg.sender][_pid].claimedPool = true;

        // Updates the vesting startTime
        if (vestingStartTime[_pid] == 0) {
            vestingStartTime[_pid] = block.timestamp;
        }

        // Transfer these tokens back to the user if quantity > 0
        if (_userInfo[msg.sender][_pid].shortAmount > 0) {
            if (100 - _poolInformation[_pid].shortVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].shortAmount.mul(100 - _poolInformation[_pid].shortVestingPercentage).div(100).div(PRECISION);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, _pid);
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].shortVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].shortAmount.mul(_poolInformation[_pid].shortVestingPercentage).div(100).div(PRECISION);

                // Create VestingSchedule object
                _createVestingSchedule(msg.sender, _pid, VestingPlan.Short, amount);

                emit CreateVestingSchedule(msg.sender, amount, _pid);
            }
        }

        if (_userInfo[msg.sender][_pid].longAmount > 0) {
            if (100 - _poolInformation[_pid].longVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].longAmount.mul(100 - _poolInformation[_pid].longVestingPercentage).div(100).div(PRECISION);

                // Transfer the tokens at TGE
                offeringToken.safeTransfer(msg.sender, amount);

                emit Harvest(msg.sender, amount, _pid);
            }
            // If this pool is Vesting modal, create a VestingSchedule for each user
            if (_poolInformation[_pid].longVestingPercentage > 0) {
                uint256 amount = _userInfo[msg.sender][_pid].longAmount.mul(_poolInformation[_pid].longVestingPercentage).div(100).div(PRECISION);

                // Create VestingSchedule object
                _createVestingSchedule(msg.sender, _pid, VestingPlan.Long, amount);

                emit CreateVestingSchedule(msg.sender, amount, _pid);
            }
        }
    }

    /**
     * @notice It allows the admin to withdraw funds
     * @param _tokens: payment token addresses
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by admin.
     */
    function finalWithdraw(address[] calldata _tokens, uint256 _offerAmount) external onlyOwner {
        if (_offerAmount > 0) {
            offeringToken.safeTransfer(msg.sender, _offerAmount);
        }

        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);

        uint256[] memory _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = IERC20(_tokens[i]).balanceOf(address(this));
            if (_amounts[i] > 0) {
                IERC20(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
            }
        }

        emit AdminWithdraw(_offerAmount, ethBalance, _tokens, _amounts);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw (18 decimals)
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(!isPaymentToken[_tokenAddress] && !isStableToken[_tokenAddress], "Recover: Cannot be payment token");
        require(_tokenAddress != address(offeringToken), "Recover: Cannot be offering token");

        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
     * @notice It allows the admin to set offering token before sale start
     * @param _tokenAddress: the address of offering token
     * @dev This function is only callable by admin.
     */
    function setOfferingToken(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "OfferingToken: Zero address");
        require(address(offeringToken) == address(0), "OfferingToken: already set");

        offeringToken = IERC20(_tokenAddress);

        emit OfferingTokenSet(_tokenAddress);
    }

    struct PoolSetParams {
        uint8 _pid; // pool id
        uint256 _startTime; // The block timestamp when pool starts
        uint256 _endTime; // The block timestamp when pool ends
        uint256 _offeringAmountPool; // amount of tokens offered for the pool (in offeringTokens)
        uint256 _minBuyAmount; // min amount of tokens user can buy for every purchase (if 0, it is ignored)
        uint256 _limitPerUserInLP; // limit of tokens per user (if 0, it is ignored)
        uint256 _shortVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 _longVestingPercentage; // 60 means 0.6, rest part such as 100-60=40 means 0.4 is claimingPercentage
        uint256 _shortVestingDuration; // Short vesting duration
        uint256 _longVestingDuration; // Long vesting duration
        uint256 _shortPrice; // token price for short purchase (in USD, decimal is 18)
        uint256 _longPrice; // token price for long purchase (in USD, decimal is 18)
        uint256 _vestingCliff; // Vesting cliff
        uint256 _vestingSlicePeriodSeconds; // Vesting slice period seconds
    }

    /**
     * @notice It sets parameters for pool
     * @param _poolSetParams: pool set param
     * @dev This function is only callable by admin.
     */
    function setPool(
        PoolSetParams memory _poolSetParams
    ) external onlyOwner {
        require(_poolSetParams._pid < NUMBER_POOLS, "Operations: Pool does not exist");
        require(
            _poolSetParams._shortVestingPercentage >= 0 && _poolSetParams._shortVestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(
            _poolSetParams._longVestingPercentage >= 0 && _poolSetParams._longVestingPercentage <= 100,
            "Operations: vesting percentage should exceeds 0 and interior 100"
        );
        require(_poolSetParams._shortVestingDuration > 0, "duration must exceeds 0");
        require(_poolSetParams._longVestingDuration > 0, "duration must exceeds 0");
        require(_poolSetParams._vestingSlicePeriodSeconds >= 1, "slicePeriodSeconds must be exceeds 1");
        require(_poolSetParams._vestingSlicePeriodSeconds <= _poolSetParams._shortVestingDuration && _poolSetParams._vestingSlicePeriodSeconds <= _poolSetParams._longVestingDuration, "slicePeriodSeconds must be interior duration");

        uint8 _pid = _poolSetParams._pid;
        _poolInformation[_pid].startTime = _poolSetParams._startTime;
        _poolInformation[_pid].endTime = _poolSetParams._endTime;
        _poolInformation[_pid].offeringAmountPool = _poolSetParams._offeringAmountPool;
        _poolInformation[_pid].minBuyAmount = _poolSetParams._minBuyAmount;
        _poolInformation[_pid].limitPerUserInLP = _poolSetParams._limitPerUserInLP;
        _poolInformation[_pid].shortVestingPercentage = _poolSetParams._shortVestingPercentage;
        _poolInformation[_pid].longVestingPercentage = _poolSetParams._longVestingPercentage;
        _poolInformation[_pid].shortVestingDuration = _poolSetParams._shortVestingDuration;
        _poolInformation[_pid].longVestingDuration = _poolSetParams._longVestingDuration;
        _poolInformation[_pid].shortPrice = _poolSetParams._shortPrice;
        _poolInformation[_pid].longPrice = _poolSetParams._longPrice;
        _poolInformation[_pid].vestingCliff = _poolSetParams._vestingCliff;
        _poolInformation[_pid].vestingSlicePeriodSeconds = _poolSetParams._vestingSlicePeriodSeconds;

        uint256 tokensDistributedAcrossPools;

        for (uint8 i = 0; i < NUMBER_POOLS; i++) {
            tokensDistributedAcrossPools = tokensDistributedAcrossPools.add(_poolInformation[i].offeringAmountPool);
        }

        // Update totalTokensOffered
        totalTokensOffered = tokensDistributedAcrossPools;

        emit PoolParametersSet(_poolSetParams._offeringAmountPool, _pid);
    }

    /**
     * @notice It returns the pool information
     * @param _pid: pool id
     */
    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (PoolCharacteristics memory)
    {
        return _poolInformation[_pid];
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
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
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        bool[] memory statusPools = new bool[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            amountPools[i] = _userInfo[_user][_pids[i]].amountPool;
            statusPools[i] = _userInfo[_user][_pids[i]].claimedPool;
        }
        return (amountPools, statusPools);
    }

    struct BoughtTokens {
        uint256 short;
        uint256 long;
    }

    /**
     * @notice External view function to see user offering amounts for pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (BoughtTokens[] memory)
    {
        BoughtTokens[] memory amountPools = new BoughtTokens[](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            if (_poolInformation[_pids[i]].soldAmountPool > 0) {
                amountPools[i].short = _userInfo[_user][_pids[i]].shortAmount;
                amountPools[i].long = _userInfo[_user][_pids[i]].longAmount;
            }
        }
        return amountPools;
    }

    /**
     * @notice Returns the number of vesting schedules associated to a beneficiary
     * @return The number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    /**
     * @notice Returns the vesting schedule id at the given index
     * @return The vesting schedule id
     */
    function getVestingScheduleIdAtIndex(uint256 _index) external view returns (bytes32) {
        require(_index < getVestingSchedulesCount(), "index out of bounds");
        return vestingSchedulesIds[_index];
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
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "only the beneficiary and owner can release vested tokens");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount > 0, "no vested tokens to release");
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(vestedAmount);
        offeringToken.safeTransfer(vestingSchedule.beneficiary, vestedAmount);

        emit Released(vestingSchedule.beneficiary, vestedAmount);
    }

    /**
     * @notice Revokes all the vesting schedules
     */
    function revoke() external onlyOwner {
        require(!vestingRevoked, "vesting is revoked");

        vestingRevoked = true;

        emit Revoked();
    }

    /**
     * @notice Add payment token
     */
    function addPaymentToken(address _token, address _feed, uint8 _decimal) external onlyOwner {
        require(!isPaymentToken[_token], "already added");
        require(_feed != address(0), "invalid feed address");
        require(_decimal == IERC20DetailedBytes(_token).decimals(), "incorrect decimal");

        (, int256 price, , , ) = AggregatorV3Interface(_feed).latestRoundData();
        require(price > 0, "invalid price feed");

        isPaymentToken[_token] = true;
        allPaymentTokens.push(_token);
        priceFeed[_token] = _feed;
        paymentTokenDecimal[_token] = _decimal;

        emit PaymentTokenAdded(_token, _feed, _decimal);
    }

    /**
     * @notice Revoke payment token
     */
    function revokePaymentToken(address _token) external onlyOwner {
        require(isPaymentToken[_token], "not added");

        isPaymentToken[_token] = false;

        uint256 index = allPaymentTokens.length;
        for (uint256 i = 0; i < allPaymentTokens.length; i++) {
            if (allPaymentTokens[i] == _token) {
                index = i;
                break;
            }
        }
        require(index != allPaymentTokens.length, "token doesn't exist");

        allPaymentTokens[index] = allPaymentTokens[allPaymentTokens.length - 1];
        allPaymentTokens.pop();
        delete paymentTokenDecimal[_token];
        delete priceFeed[_token];

        emit PaymentTokenRevoked(_token);
    }

    /**
     * @notice Add stable token
     */
    function addStableToken(address _token, uint8 _decimal) external onlyOwner {
        require(!isStableToken[_token], "already added");
        require(_decimal == IERC20DetailedBytes(_token).decimals(), "incorrect decimal");

        isStableToken[_token] = true;
        allStableTokens.push(_token);
        paymentTokenDecimal[_token] = _decimal;

        emit StableTokenAdded(_token, _decimal);
    }

    /**
     * @notice Revoke stable token
     */
    function revokeStableToken(address _token) external onlyOwner {
        require(isStableToken[_token], "not added");

        isStableToken[_token] = false;

        uint256 index = allStableTokens.length;
        for (uint256 i = 0; i < allStableTokens.length; i++) {
            if (allStableTokens[i] == _token) {
                index = i;
                break;
            }
        }
        require(index != allStableTokens.length, "token doesn't exist");

        allStableTokens[index] = allStableTokens[allStableTokens.length - 1];
        allStableTokens.pop();
        delete paymentTokenDecimal[_token];

        emit StableTokenRevoked(_token);
    }

    /**
     * @notice Flip whitelist sale status
     */
    function flipWhitelistSaleStatus(uint8 _pid) external onlyOwner {
        isWhitelistSale[_pid] = !isWhitelistSale[_pid];

        emit WhitelistSaleFlipped(_pid, isWhitelistSale[_pid]);
    }

    /**
     * @notice Flip harvestAllowed status
     */
    function flipHarvestAllowedStatus() external onlyOwner {
        harvestAllowed = !harvestAllowed;

        emit HarvestAllowedFlipped(harvestAllowed);
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
        require(vestingSchedules[_vestingScheduleId].isVestingInitialized == true, "vesting schedule is not exist");

        VestingSchedule memory vestingSchedule = vestingSchedules[_vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
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
        return offeringToken.balanceOf(address(this)).sub(vestingSchedulesTotalAmount);
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
    function computeVestingScheduleIdForAddressAndPid(address _holder, uint256 _pid, VestingPlan _plan) external view returns (bytes32) {
        require(_pid < NUMBER_POOLS, "ComputeVestingScheduleId: Non valid pool id");

        for (uint8 i = 0; i < NUMBER_POOLS * 2; i++) {
            bytes32 vestingScheduleId = computeVestingScheduleIdForAddressAndIndex(_holder, i);
            VestingSchedule memory vestingSchedule = vestingSchedules[vestingScheduleId];
            if (vestingSchedule.isVestingInitialized == true && vestingSchedule.pid == _pid && vestingSchedule.vestingPlan == _plan) {
                return vestingScheduleId;
            }
        }

        return computeNextVestingScheduleIdForHolder(_holder);
    }

    /**
     * @notice Get current Time
     */
    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Computes the releasable amount of tokens for a vesting schedule
     * @return The amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory _vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (currentTime < vestingStartTime[_vestingSchedule.pid] + _poolInformation[_vestingSchedule.pid].vestingCliff) {
            return 0;
        } else if (
            (_vestingSchedule.vestingPlan == VestingPlan.Short && currentTime >= vestingStartTime[_vestingSchedule.pid].add(_poolInformation[_vestingSchedule.pid].shortVestingDuration)) ||
            (_vestingSchedule.vestingPlan == VestingPlan.Long && currentTime >= vestingStartTime[_vestingSchedule.pid].add(_poolInformation[_vestingSchedule.pid].longVestingDuration)) ||
            vestingRevoked
        ) {
            return _vestingSchedule.amountTotal.sub(_vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingStartTime[_vestingSchedule.pid]);
            uint256 secondsPerSlice = _poolInformation[_vestingSchedule.pid].vestingSlicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = _vestingSchedule.amountTotal.mul(vestedSeconds).div(
                _vestingSchedule.vestingPlan == VestingPlan.Short ? _poolInformation[_vestingSchedule.pid].shortVestingDuration : _poolInformation[_vestingSchedule.pid].longVestingDuration
            );
            vestedAmount = vestedAmount.sub(_vestingSchedule.released);
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
        VestingPlan _plan,
        uint256 _amount
    ) internal {
        require(
            getWithdrawableOfferingTokenAmount() >= _amount,
            "can not create vesting schedule with sufficient tokens"
        );

        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(_beneficiary);
        require(vestingSchedules[vestingScheduleId].beneficiary == address(0), "vestingScheduleId is been created");
        vestingSchedules[vestingScheduleId] = VestingSchedule(true, _beneficiary, _pid, _plan, _amount, 0);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[_beneficiary]++;
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return _userInfo[_user][_pid].amountPool.mul(1e12).div(_poolInformation[_pid].totalAmountPool);
        } else {
            return 0;
        }
    }

    /**
     * @notice Check if an address is a contract
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function isQualifiedWhitelist(address _user) external view returns (bool) {
        return isWhitelisted(_user);
    }

    function _isQualifiedWhitelist(address _user) internal view returns (bool) {
        return isWhitelisted(_user);
    }

    /**
     * @notice Computes the USD amount and offering token amount from token amount
     * @return usdAmount USD amount
     * @return offeringAmount offering amount
     */
    function computeAmounts(address token, uint256 amount, uint8 pid, VestingPlan plan) public view checkPayment(token) returns (uint256 usdAmount, uint256 offeringAmount) {
        uint256 tokenDecimal = token == address(0) ? 18 : uint256(paymentTokenDecimal[token]);

        if (isStableToken[token]) {
            usdAmount = amount.mul(PRECISION).div(10 ** tokenDecimal);    
        } else {
            address feed = token == address(0) ? ethPriceFeed : priceFeed[token];
            (, int256 price, , , ) = AggregatorV3Interface(feed).latestRoundData();
            require(price > 0, "ChainlinkPriceFeed: invalid price");
            uint256 priceDecimal = uint256(AggregatorV3Interface(feed).decimals());

            usdAmount = amount.mul(uint256(price)).mul(PRECISION).div(10 ** (priceDecimal + tokenDecimal));
        }

        require(_poolInformation[pid].offeringAmountPool > 0, "Deposit: Pool not set");
        uint256 offeringTokenPrice = plan == VestingPlan.Short ? _poolInformation[pid].shortPrice : _poolInformation[pid].longPrice;
        offeringAmount = usdAmount.mul(10 ** OFFERING_DECIMALS).mul(PRECISION).div(offeringTokenPrice);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

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