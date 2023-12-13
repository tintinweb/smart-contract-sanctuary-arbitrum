// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public override initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../upgradability/ReentrancyGuardUpgradeable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is ReentrancyGuardUpgradeable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public virtual initializer {
    _setStorage(_store);
    ReentrancyGuardUpgradeable.initialize();
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IDividendsV2 {
    function harvestAllDividends() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IXGrailTokenUsage.sol";

interface IXGrail is IERC20 {
  struct XGrailBalance {
    uint256 allocatedAmount; // Amount of xGRAIL allocated to a Usage
    uint256 redeemingAmount; // Total amount of xGRAIL currently being redeemed
  }
  struct RedeemInfo {
    uint256 grailAmount; // GRAIL amount to receive when vesting has ended
    uint256 xGrailAmount; // xGRAIL amount to redeem
    uint256 endTime;
    IXGrailTokenUsage dividendsAddress;
    uint256 dividendsAllocation; // Share of redeeming xGRAIL to allocate to the Dividends Usage contract
  }
  function getXGrailBalance(address user) external view returns (XGrailBalance calldata);
  function getGrailByVestingDuration(uint256 amount, uint256 duration) external view returns (uint256);
  function getUserRedeemsLength(address user) external view returns (uint256);
  function getUserRedeem(address user, uint256 index) external view returns (RedeemInfo calldata);
  function getUsageApproval(address user, address usageAddress) external view returns (uint256);
  function getUsageAllocation(address user, address usageAddress) external view returns (uint256);
  function dividendsAddress() external view returns (address);
  function usagesDeallocationFee(address allocation) external view returns (uint256);
  function grailToken() external view returns (address);
  function minRedeemDuration() external view returns (uint256);

  function approveUsage(address usage, uint256 amount) external;
  function convert(uint256 amount) external;
  function convertTo(uint256 amount, address to) external;
  function redeem(uint256 amount, uint256 duration) external;
  function finalizeRedeem(uint256 redeemIndex) external;
  function updateRedeemDividendsAddress(uint256 redeemIndex) external;
  function cancelRedeem(uint256 redeemIndex) external;
  function allocate(address usage, uint256 amount, bytes calldata usageData) external;
  function deallocate(address usage, uint256 amount, bytes calldata usageData) external;

  function updateTransferWhitelist(address account, bool add) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IXGrailTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IYieldBooster {
  function deallocateAllFromPool(address userAddress, uint256 tokenId) external;
  function getMultiplier(address poolAddress, uint256 maxBoostMultiplier, uint256 amount, uint256 totalPoolSupply, uint256 allocatedAmount) external view returns (uint256);
  function getExpectedMultiplier(uint256 maxBoostMultiplier, uint256 lpAmount, uint256 totalLpSupply, uint256 userAllocation, uint256 poolTotalAllocation) external view returns (uint256);
  function getUserTotalAllocation(address user) external view returns (uint256);
  function getPoolTotalAllocation(address pool) external view returns (uint256);
  function getUserPositionAllocation(address user, address pool, uint256 tokenId) external view returns(uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;

interface IHypervisor {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getTotalAmounts() external view returns(uint256, uint256);
  function withdraw(uint256 shares, address to, address from, uint256[4] calldata minAmounts) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


interface IController {

    // ========================= Events =========================

    event QueueProfitSharingChange(uint profitSharingNumerator, uint validAtTimestamp);
    event ConfirmProfitSharingChange(uint profitSharingNumerator);

    event QueueStrategistFeeChange(uint strategistFeeNumerator, uint validAtTimestamp);
    event ConfirmStrategistFeeChange(uint strategistFeeNumerator);

    event QueuePlatformFeeChange(uint platformFeeNumerator, uint validAtTimestamp);
    event ConfirmPlatformFeeChange(uint platformFeeNumerator);

    event QueueNextImplementationDelay(uint implementationDelay, uint validAtTimestamp);
    event ConfirmNextImplementationDelay(uint implementationDelay);

    event AddedStakingContract(address indexed stakingContract);
    event RemovedStakingContract(address indexed stakingContract);

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ==================== Functions ====================

    /**
     * An EOA can safely interact with the system no matter what. If you're using Metamask, you're using an EOA. Only
     * smart contracts may be affected by this grey list. This contract will not be able to ban any EOA from the system
     * even if an EOA is being added to the greyList, he/she will still be able to interact with the whole system as if
     * nothing happened. Only smart contracts will be affected by being added to the greyList. This grey list is only
     * used in VaultV3.sol, see the code there for reference
     */
    function greyList(address _target) external view returns (bool);

    function addressWhiteList(address _target) external view returns (bool);

    function codeWhiteList(address _target) external view returns (bool);

    function addToWhitelist(address _target) external;

    function addCodeToWhitelist(address _target) external;

    function store() external view returns (address);

    function governance() external view returns (address);

    function doHardWork(address _vault) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    /**
     * @return The targeted profit token to convert all-non-compounding rewards to. Defaults to WETH.
     */
    function targetToken() external view returns (address);

    function setTargetToken(address _targetToken) external;

    function profitSharingReceiver() external view returns (address);

    function setProfitSharingReceiver(address _profitSharingReceiver) external;

    function protocolFeeReceiver() external view returns (address);

    function setProtocolFeeReceiver(address _protocolFeeReceiver) external;

    function rewardForwarder() external view returns (address);

    function setRewardForwarder(address _rewardForwarder) external;

    function universalLiquidator() external view returns (address);

    function setUniversalLiquidator(address _universalLiquidator) external;

    function dolomiteYieldFarmingRouter() external view returns (address);

    function setDolomiteYieldFarmingRouter(address _value) external;

    function nextImplementationDelay() external view returns (uint256);

    function profitSharingNumerator() external view returns (uint256);

    function strategistFeeNumerator() external view returns (uint256);

    function platformFeeNumerator() external view returns (uint256);

    function feeDenominator() external view returns (uint256);

    function setProfitSharingNumerator(uint _profitSharingNumerator) external;

    function confirmSetProfitSharingNumerator() external;

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) external;

    function confirmSetStrategistFeeNumerator() external;

    function setPlatformFeeNumerator(uint _platformFeeNumerator) external;

    function confirmSetPlatformFeeNumerator() external;

    function setNextImplementationDelay(uint256 _nextImplementationDelay) external;

    function confirmNextImplementationDelay() external;

    function nextProfitSharingNumerator() external view returns (uint256);

    function nextProfitSharingNumeratorTimestamp() external view returns (uint256);

    function nextStrategistFeeNumerator() external view returns (uint256);

    function nextStrategistFeeNumeratorTimestamp() external view returns (uint256);

    function nextPlatformFeeNumerator() external view returns (uint256);

    function nextPlatformFeeNumeratorTimestamp() external view returns (uint256);

    function tempNextImplementationDelay() external view returns (uint256);

    function tempNextImplementationDelayTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;


/**
 * @dev A routing contract that is responsible for taking the harvested gains and routing them into FARM and additional
 *      buyback tokens for the corresponding strategy
 */
interface IRewardForwarder {

    function store() external view returns (address);

    function governance() external view returns (address);

    /**
     * @dev This function sends converted `_buybackTokens` to `msg.sender`. The returned amounts will match the
     *      `amounts` return value. The fee amounts are converted to the profit sharing token and sent to the proper
     *      addresses (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @param _buybackTokens    the output tokens that `_buyBackAmounts` should be swapped to (outputToken)
     * @param _buybackAmounts   the amounts of `_token` that will be bought into more `_buybackTokens` token
     * @return amounts The amounts that were purchased of _buybackTokens
     */
    function notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] calldata _buybackTokens,
        uint256[] calldata _buybackAmounts
    ) external returns (uint[] memory amounts);

    /**
     * @dev This function converts the fee amounts to the profit sharing token and sends them to the proper addresses
     *      (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     */
    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IUniversalLiquidator {
    event Swap(
        address indexed sellToken,
        address indexed buyToken,
        address indexed receiver,
        address initiator,
        uint256 sellAmount,
        uint256 minBuyAmount
    );

    function swap(
        address _sellToken,
        address _buyToken,
        uint256 _sellAmount,
        uint256 _minBuyAmount,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVault {

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) external;

    function balanceOf(address _holder) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function underlyingUnit() external view returns (uint);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function announceStrategyUpdate(address _strategy) external;

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external;

    function deposit(uint256 _amount) external;
    function deposit(uint256 _amount, address _receiver) external;

    function depositFor(uint256 _amount, address _holder) external;

    function withdrawAll() external;

    function withdraw(uint256 _numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address _holder) view external returns (uint256);

    /**
     * The total amount available to be deposited from this vault into the strategy, while adhering to the
     * `vaultFractionToInvestNumerator` and `vaultFractionToInvestDenominator` rules
     */
    function availableToInvestOut() external view returns (uint256);

    /**
     * This should be callable only by the controller (by the hard worker) or by governance
     */
    function doHardWork() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../inheritance/ControllableInit.sol";
import "../interface/IController.sol";
import "../interface/IRewardForwarder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BaseUpgradeableStrategy is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    address _strategist
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    _setStrategist(_strategist);
    _setSell(true);
    _setSellFloor(0);
    _setPausedInvesting(false);
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  // ========================= Internal & Private Functions =========================

  // ==================== Functionality ====================

  /**
    * @dev Same as `_notifyProfitAndBuybackInRewardToken` but does not perform a compounding buyback. Just takes fees
    *      instead.
    */
  function _notifyProfitInRewardToken(
      address _rewardToken,
      uint256 _rewardBalance
  ) internal {
      if (_rewardBalance > 100) {
          uint _feeDenominator = feeDenominator();
          uint256 strategistFee = _rewardBalance.mul(strategistFeeNumerator()).div(_feeDenominator);
          uint256 platformFee = _rewardBalance.mul(platformFeeNumerator()).div(_feeDenominator);
          uint256 profitSharingFee = _rewardBalance.mul(profitSharingNumerator()).div(_feeDenominator);

          address strategyFeeRecipient = strategist();
          address platformFeeRecipient = IController(controller()).governance();

          emit ProfitLogInReward(
              _rewardToken,
              _rewardBalance,
              profitSharingFee,
              block.timestamp
          );
          emit PlatformFeeLogInReward(
              platformFeeRecipient,
              _rewardToken,
              _rewardBalance,
              platformFee,
              block.timestamp
          );
          emit StrategistFeeLogInReward(
              strategyFeeRecipient,
              _rewardToken,
              _rewardBalance,
              strategistFee,
              block.timestamp
          );

          address rewardForwarder = IController(controller()).rewardForwarder();
          IERC20(_rewardToken).safeApprove(rewardForwarder, 0);
          IERC20(_rewardToken).safeApprove(rewardForwarder, _rewardBalance);

          // Distribute/send the fees
          IRewardForwarder(rewardForwarder).notifyFee(
              _rewardToken,
              profitSharingFee,
              strategistFee,
              platformFee
          );
      } else {
          emit ProfitLogInReward(_rewardToken, 0, 0, block.timestamp);
          emit PlatformFeeLogInReward(IController(controller()).governance(), _rewardToken, 0, 0, block.timestamp);
          emit StrategistFeeLogInReward(strategist(), _rewardToken, 0, 0, block.timestamp);
      }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "../interface/IController.sol";
import "../inheritance/ControllableInit.sol";

contract BaseUpgradeableStrategyStorage is ControllableInit {

  event ProfitsNotCollected(
      address indexed rewardToken,
      bool sell,
      bool floor
  );
  event ProfitLogInReward(
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event ProfitAndBuybackLog(
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event PlatformFeeLogInReward(
      address indexed treasury,
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );
  event StrategistFeeLogInReward(
      address indexed strategist,
      address indexed rewardToken,
      uint256 profitAmount,
      uint256 feeAmount,
      uint256 timestamp
  );

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_TOKENS_SLOT = 0x45418d9b5c2787ae64acbffccad43f2b487c1a16e24385aa9d2b059f9d1d163c;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  bytes32 internal constant _STRATEGIST_SLOT = 0x6a7b588c950d46e2de3db2f157e5e0e4f29054c8d60f17bf0c30352e223a458d;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_TOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardTokens")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

    assert(_STRATEGIST_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.strategist")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public virtual view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setRewardTokens(address[] memory _rewardTokens) internal {
    setAddressArray(_REWARD_TOKENS_SLOT, _rewardTokens);
  }

  function isRewardToken(address _token) public view returns (bool) {
    return _isAddressInList(_token, rewardTokens());
  }

  function rewardTokens() public view returns (address[] memory) {
    return getAddressArray(_REWARD_TOKENS_SLOT);
  }

  function _isAddressInList(address _searchValue, address[] memory _list) internal pure returns (bool) {
    for (uint i = 0; i < _list.length; i++) {
      if (_list[i] == _searchValue) {
        return true;
      }
    }
    return false;
  }

  function _setStrategist(address _strategist) internal {
    setAddress(_STRATEGIST_SLOT, _strategist);
  }

  function strategist() public view returns (address) {
    return getAddress(_STRATEGIST_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public virtual view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return IController(controller()).profitSharingNumerator();
  }

  function platformFeeNumerator() public view returns (uint256) {
    return IController(controller()).platformFeeNumerator();
  }

  function strategistFeeNumerator() public view returns (uint256) {
    return IController(controller()).strategistFeeNumerator();
  }

  function feeDenominator() public view returns (uint256) {
    return IController(controller()).feeDenominator();
  }

  function universalLiquidator() public view returns (address) {
    return IController(controller()).universalLiquidator();
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

    function nextImplementationDelay() public view returns (uint256) {
        return IController(controller()).nextImplementationDelay();
    }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

      function setUint256Array(bytes32 slot, uint256[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setUint256(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function setAddressArray(bytes32 slot, address[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setAddress(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }


    function getUint256Array(bytes32 slot) internal view returns (uint[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new uint[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getUint256(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddressArray(bytes32 slot) internal view returns (address[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new address[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getAddress(bytes32(uint(slot) + 1 + i));
        }
    }

    function setBytes32(bytes32 slot, bytes32 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
        sstore(slot, _value)
        }
    }

    function getBytes32(bytes32 slot) internal view returns (bytes32 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
        str := sload(slot)
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * Same old `ReentrancyGuard`, but can be used by upgradable contracts
 */
contract ReentrancyGuardUpgradeable is Initializable {

    bytes32 internal constant _NOT_ENTERED_SLOT = 0x62ae7bf2df4e95c187ea09c8c47c3fc3d9abc36298f5b5b6c5e2e7b4b291fe25;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_getNotEntered(_NOT_ENTERED_SLOT), "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(_NOT_ENTERED_SLOT, false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    constructor() public {
        assert(_NOT_ENTERED_SLOT == bytes32(uint256(keccak256("eip1967.reentrancyGuard.notEntered")) - 1));
    }

    function initialize() public initializer {
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    function _getNotEntered(bytes32 slot) private view returns (bool) {
        uint str;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
        return str == 1;
    }

    function _setNotEntered(bytes32 slot, bool _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../base/interface/IVault.sol";
import "../../base/upgradability/BaseUpgradeableStrategy.sol";
import "../../base/interface/camelot/IXGrail.sol";
import "../../base/interface/camelot/IDividendsV2.sol";
import "../../base/interface/camelot/IYieldBooster.sol";
import "../../base/interface/IUniversalLiquidator.sol";
import "../../base/interface/gamma/IHypervisor.sol";

contract XGrailStrategyV2 is BaseUpgradeableStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TargetAllocation {
        address allocationAddress; // Address to allocate too
        uint256 weight;            // Weight of allocation (in BPS)
        bytes data;                // Bytes to send in the usageData field
    }

    struct CurrentAllocation {
        address allocationAddress; // Address to allocate too
        uint256 amount;            // Amount of allocation in xGrail
        bytes data;                // Bytes to send in the usageData field
    }

    address public constant weth = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public constant harvestMSIG = address(0xf3D1A027E858976634F81B7c41B09A05A46EdA21);
    address public constant camelotRouter = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    bytes32 internal constant _YIELD_BOOSTER_SLOT = 0xbec2ddcc523ceccf38b524de8ba8b3f9263c108934a48e6c1382566b16a326d2;
    bytes32 internal constant _ALLOCATION_WHITELIST_SLOT = 0x0a5b0b20c401b06b37b537c3cab830e5993f53887001d5bcca3f1a84420b9ac4;

    CurrentAllocation[] public currentAllocations;
    TargetAllocation[] public allocationTargets;
    address[] public rewardTokens;
    mapping(address => bool) internal isLp;

    modifier onlyAllocationWhitelist() {
        require(_isAddressInList(msg.sender, allocationWhitelist()),
        "Caller has to be whitelisted");
        _;
    }

    constructor() public BaseUpgradeableStrategy() {
        assert(_YIELD_BOOSTER_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.yieldBooster")) - 1));
        assert(_ALLOCATION_WHITELIST_SLOT == bytes32(uint256(keccak256("eip1967.vaultStorage.allocationWhitelist")) - 1));
    }

    function initializeBaseStrategy(
        address _storage,
        address _underlying,
        address _vault,
        address _grail,
        address _yieldBooster
    ) public initializer {

        BaseUpgradeableStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            IXGrail(_underlying).dividendsAddress(),
            _grail,
            harvestMSIG
        );

        setAddress(_YIELD_BOOSTER_SLOT, _yieldBooster);
        address[] memory whitelist = new address[](3);
        whitelist[0] = governance();
        whitelist[1] = harvestMSIG;
        whitelist[2] = address(0x6a74649aCFD7822ae8Fb78463a9f2192752E5Aa2);
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, whitelist);
    }

    function yieldBooster() public view returns(address) {
        return getAddress(_YIELD_BOOSTER_SLOT);
    }

    function setYieldBooster(address _target) public onlyGovernance {
        setAddress(_YIELD_BOOSTER_SLOT, _target);
    }

    function allocationWhitelist() public view returns(address[] memory) {
        return getAddressArray(_ALLOCATION_WHITELIST_SLOT);
    }

    function setAllocationWhitelist(address[] memory _allocationWhitelist) public onlyGovernance {
        setAddressArray(_ALLOCATION_WHITELIST_SLOT, _allocationWhitelist);
    }

    function depositArbCheck() external pure returns(bool) {
        return true;
    }

    function dividendsAddress() public view returns(address) {
        return IXGrail(underlying()).dividendsAddress();
    }

    function _liquidateRewards(uint256 _xGrailAmount) internal {
        address _rewardToken = rewardToken();
        address _universalLiquidator = universalLiquidator();
        for (uint256 i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance == 0) {
                continue;
            }
            if (isLp[token]) {
                address token0 = IHypervisor(token).token0();
                address token1 = IHypervisor(token).token1();
                uint256[4] memory minAmounts = [uint(0), uint(0), uint(0), uint(0)];
                IHypervisor(token).withdraw(balance, address(this), address(this), minAmounts);
                uint256 balance0 = IERC20(token0).balanceOf(address(this));
                if (token0 != _rewardToken){
                    IERC20(token0).safeApprove(_universalLiquidator, 0);
                    IERC20(token0).safeApprove(_universalLiquidator, balance0);
                    IUniversalLiquidator(_universalLiquidator).swap(token0, _rewardToken, balance0, 1, address(this));
                }
                uint256 balance1 = IERC20(token1).balanceOf(address(this));
                if (token1 != _rewardToken){
                    IERC20(token1).safeApprove(_universalLiquidator, 0);
                    IERC20(token1).safeApprove(_universalLiquidator, balance1);
                    IUniversalLiquidator(_universalLiquidator).swap(token1, _rewardToken, balance1, 1, address(this));
                }
            } else {
                if (token != _rewardToken){
                    IERC20(token).safeApprove(_universalLiquidator, 0);
                    IERC20(token).safeApprove(_universalLiquidator, balance);
                    IUniversalLiquidator(_universalLiquidator).swap(token, _rewardToken, balance, 1, address(this));
                }
            }
        }

        uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (rewardBalance < 1e12){
            return;
        }
        _notifyProfitInRewardToken(_rewardToken, rewardBalance.add(_xGrailAmount));
        uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
            return;
        }

        _depositGrail(remainingRewardBalance);
    }

    function _depositGrail(uint256 amount) internal {
        address _rewardToken = rewardToken();
        address _underlying = underlying();
        IERC20(_rewardToken).safeApprove(_underlying, 0);
        IERC20(_rewardToken).safeApprove(_underlying, amount);
        IXGrail(_underlying).convert(amount);
    }

    function getCurrentAllocation(address allocationAddress, bytes memory data) public view returns(uint256) {
        if (allocationAddress == dividendsAddress()) {
            return IXGrail(underlying()).getUsageAllocation(address(this), allocationAddress);
        } else if (allocationAddress == yieldBooster()) {
            (address poolAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
            return IYieldBooster(yieldBooster()).getUserPositionAllocation(address(this), poolAddress, tokenId);
        }
    }

    function xGrailBalanceAllocated() view public returns (IXGrail.XGrailBalance memory) {
        return IXGrail(underlying()).getXGrailBalance(address(this));
    }

    function investedUnderlyingBalance() view public returns (uint256) {
        return xGrailBalanceAllocated().allocatedAmount.add(IERC20(underlying()).balanceOf(address(this)));
    }

    function doHardWork() external onlyNotPausedInvesting restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _liquidateRewards(claimedXGrail);
        rebalanceAllocations();
    }

    function rebalanceAllocations() public onlyNotPausedInvesting restricted {
        uint256 maxLength = currentAllocations.length.add(allocationTargets.length);
        address[] memory increaseAddresses = new address[](maxLength);
        uint256[] memory increaseAmounts = new uint256[](maxLength);
        bytes[] memory increaseDatas = new bytes[](maxLength);
        address[] memory decreaseAddresses = new address[](maxLength);
        uint256[] memory decreaseAmounts = new uint256[](maxLength);
        bytes[] memory decreaseDatas = new bytes[](maxLength);
        uint256 nDecrease = 0;
        uint256 nIncrease = 0;

        for (uint256 i; i < currentAllocations.length; i++) {  //Check if we have current allocations that are not in the targets
            address allocationAddress = currentAllocations[i].allocationAddress;
            bytes memory data = currentAllocations[i].data;
            bool isTarget = false;
            for (uint256 j; j < allocationTargets.length; j++) {
                address targetAddress = allocationTargets[j].allocationAddress;
                bytes memory targetData = allocationTargets[j].data;
                if (targetAddress == allocationAddress && keccak256(targetData) == keccak256(data)) {
                    isTarget = true;
                    break;
                }
            }
            if (!isTarget) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAllocations[i].amount;
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            }
        }

        uint256 nAllocations = 0;
        for (uint256 i; i < allocationTargets.length; i++) {           //Split target allocations into increases and decreases
            address allocationAddress = allocationTargets[i].allocationAddress;
            bytes memory data = allocationTargets[i].data;
            uint256 currentAmount = getCurrentAllocation(allocationAddress, data);
            uint256 targetAmount = investedUnderlyingBalance().mul(allocationTargets[i].weight).div(10000);
            if (currentAmount > targetAmount) {
                decreaseAddresses[nDecrease] = allocationAddress;
                decreaseAmounts[nDecrease] = currentAmount.sub(targetAmount);
                decreaseDatas[nDecrease] = data;
                nDecrease += 1;
            } else if (targetAmount > currentAmount) {
                increaseAddresses[nIncrease] = allocationAddress;
                increaseAmounts[nIncrease] = targetAmount.sub(currentAmount);
                increaseDatas[nIncrease] = data;
                nIncrease += 1;
            } else {    //No change in amount, store to current positions
                CurrentAllocation memory newAllocation;
                newAllocation.allocationAddress = allocationAddress;
                newAllocation.amount = targetAmount;
                newAllocation.data = data;
                if (nAllocations >= currentAllocations.length) {
                    currentAllocations.push(newAllocation);
                } else {
                    currentAllocations[nAllocations] = newAllocation;
                }
                nAllocations += 1;
            }
        }

        for (uint256 i; i < nDecrease; i++) {        //First handle decreases to free up xGrail for increases
            uint256 currentAllocation = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
            if (currentAllocation > 0){
                IXGrail(underlying()).deallocate(decreaseAddresses[i], Math.min(decreaseAmounts[i], currentAllocation), decreaseDatas[i]);
                if (getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]) > 0){
                    CurrentAllocation memory newAllocation;
                    newAllocation.allocationAddress = decreaseAddresses[i];
                    newAllocation.amount = getCurrentAllocation(decreaseAddresses[i], decreaseDatas[i]);
                    newAllocation.data = decreaseDatas[i];
                    if (nAllocations >= currentAllocations.length) {
                        currentAllocations.push(newAllocation);
                    } else {
                        currentAllocations[nAllocations] = newAllocation;
                    }
                    nAllocations += 1;
                }
            }
        }

        for (uint256 i; i < nIncrease; i++) {        //Now handle increases
            address _underlying = underlying();
            uint256 _amount = Math.min(increaseAmounts[i], IERC20(_underlying).balanceOf(address(this)));
            IXGrail(_underlying).approveUsage(increaseAddresses[i], _amount);
            IXGrail(_underlying).allocate(increaseAddresses[i], _amount, increaseDatas[i]);
            CurrentAllocation memory newAllocation;
            newAllocation.allocationAddress = increaseAddresses[i];
            newAllocation.amount = getCurrentAllocation(increaseAddresses[i], increaseDatas[i]);
            newAllocation.data = increaseDatas[i];
            if (nAllocations >= currentAllocations.length) {
                currentAllocations.push(newAllocation);
            } else {
                currentAllocations[nAllocations] = newAllocation;
            }
            nAllocations += 1;
        }

        if (currentAllocations.length > nAllocations) {
            for (uint256 i; i < (currentAllocations.length).sub(nAllocations); i++) {
                currentAllocations.pop();
            }
        }
    }

    function setAllocationTargets(
        address[] memory addresses,
        uint256[] memory weights,
        address[] memory poolAddresses,
        uint256[] memory tokenIds
    ) external onlyAllocationWhitelist {
        require(addresses.length == weights.length, "Array mismatch");
        require(addresses.length == poolAddresses.length, "Array mismatch");
        require(addresses.length == tokenIds.length, "Array mismatch");
        uint256 totalWeight = 0;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == dividendsAddress()) {
                require(weights[i] >= 5000, "Dividend weight");
            }
            TargetAllocation memory newAllocation;
            newAllocation.allocationAddress = addresses[i];
            newAllocation.weight = weights[i];
            if (addresses[i] == dividendsAddress()) {
                newAllocation.data = new bytes(0);
            } else {
                newAllocation.data = abi.encode(poolAddresses[i], tokenIds[i]);
            }
            if (i >= allocationTargets.length) {
                allocationTargets.push(newAllocation);
            } else {
                allocationTargets[i] = newAllocation;
            }
            totalWeight = totalWeight.add(weights[i]);
        }

        require(totalWeight == 10000, "Total weight");

        if (allocationTargets.length > addresses.length) {
            for (uint256 i; i < (allocationTargets.length).sub(addresses.length); i++) {
                allocationTargets.pop();
            }
        }
    }

    function _deallocateAll() internal {
        for (uint256 i; i < currentAllocations.length; i++) {
            if (getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data) > 0) {
                IXGrail(underlying()).deallocate(
                    currentAllocations[i].allocationAddress,
                    getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data),
                    currentAllocations[i].data
                );
            }
        }
        for (uint256 i; i < currentAllocations.length; i++) {
            currentAllocations.pop();
        }
    }

    function _deallocatePartial(uint256 amount) internal {
        uint256 balanceBefore = IERC20(underlying()).balanceOf(address(this));
        uint256 toDeallocate = amount;
        for (uint256 i; i < currentAllocations.length; i++) {
            IXGrail(underlying()).deallocate(
                currentAllocations[i].allocationAddress,
                Math.min(currentAllocations[i].amount, toDeallocate.mul(101).div(100)),
                currentAllocations[i].data
            );
            currentAllocations[i].amount = getCurrentAllocation(currentAllocations[i].allocationAddress, currentAllocations[i].data);

            uint256 balanceNew = IERC20(underlying()).balanceOf(address(this));
            uint256 balanceChange = balanceNew.sub(balanceBefore);
            balanceBefore = balanceNew;
            if (balanceChange >= toDeallocate) {
                return;
            } else {
                toDeallocate = toDeallocate.sub(balanceChange);
            }
        }
    }

    function withdrawAllToVault() public restricted {
        address _underlying = underlying();
        uint256 balanceBefore = IERC20(_underlying).balanceOf(address(this));
        IDividendsV2(dividendsAddress()).harvestAllDividends();
        uint256 claimedXGrail = IERC20(_underlying).balanceOf(address(this)).sub(balanceBefore);
        _deallocateAll();
        _liquidateRewards(claimedXGrail);
        IERC20(_underlying).safeTransfer(vault(), IERC20(_underlying).balanceOf(address(this)));
    }

    function withdrawToVault(uint256 _amount) public restricted {
        // Typically there wouldn't be any amount here
        // however, it is possible because of the emergencyExit
        address _underlying = underlying();
        uint256 entireBalance = IERC20(_underlying).balanceOf(address(this));

        if(_amount > entireBalance){
            // While we have the check above, we still using SafeMath below
            // for the peace of mind (in case something gets changed in between)
            uint256 needToWithdraw = _amount.sub(entireBalance);
            uint256 toWithdraw = Math.min(xGrailBalanceAllocated().allocatedAmount, needToWithdraw);
            _deallocatePartial(toWithdraw);
        }
        IERC20(_underlying).safeTransfer(vault(), _amount);
        rebalanceAllocations();
    }

    function emergencyExit() public onlyGovernance {
        _deallocateAll();
        _setPausedInvesting(true);
    }

    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }


    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function salvage(address recipient, address token, uint256 amount) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    function finalizeUpgrade() external onlyGovernance {
        address ethUsdc = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
        rewardTokens = [ethUsdc];
        isLp[ethUsdc] = true;
        _finalizeUpgrade();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./XGrailStrategyV2.sol";

contract XGrailStrategyV2Mainnet_XGrail is XGrailStrategyV2 {

  constructor() public {}

  function initializeStrategy(
    address _storage,
    address _vault
  ) public initializer {
    address underlying = address(0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b);
    address grail = address(0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8);
    address yieldBooster = address(0xD27c373950E7466C53e5Cd6eE3F70b240dC0B1B1);
    address ethUsdc = address(0xd7Ef5Ac7fd4AAA7994F3bc1D273eAb1d1013530E);
    XGrailStrategyV2.initializeBaseStrategy(
      _storage,
      underlying,
      _vault,
      grail,
      yieldBooster
    );
    rewardTokens = [ethUsdc];
    isLp[ethUsdc] = true;
    TargetAllocation memory initialAllocation;
    initialAllocation.allocationAddress = dividendsAddress();
    initialAllocation.weight = 10000;
    initialAllocation.data = new bytes(0);
    allocationTargets.push(initialAllocation);
  }
}