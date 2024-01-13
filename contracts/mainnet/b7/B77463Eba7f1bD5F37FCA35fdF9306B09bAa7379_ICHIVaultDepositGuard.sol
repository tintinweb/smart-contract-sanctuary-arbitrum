// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

    constructor () {
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;

import { IICHIVaultDepositGuard } from "./interfaces/IICHIVaultDepositGuard.sol";
import { IICHIVaultFactory } from "./interfaces/IICHIVaultFactory.sol";
import { IICHIVault } from "./interfaces/IICHIVault.sol";
import { IWRAPPED_NATIVE } from "./interfaces/IWRAPPED_NATIVE.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ICHIVaultDepositGuard is IICHIVaultDepositGuard, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable override ICHIVaultFactory;
    address public immutable override WRAPPED_NATIVE;

    address private constant NULL_ADDRESS = address(0);

    /// @notice Constructs the IICHIVaultDepositGuard contract.
    /// @param _ICHIVaultFactory The address of the ICHIVaultFactory.
    constructor(address _ICHIVaultFactory, address _WRAPPED_NATIVE) {
        require(_ICHIVaultFactory != NULL_ADDRESS, "DG.constructor: zero address");
        ICHIVaultFactory = _ICHIVaultFactory;
        WRAPPED_NATIVE = _WRAPPED_NATIVE;
        emit Deployed(_ICHIVaultFactory, _WRAPPED_NATIVE);
    }

    receive() external payable {
        assert(msg.sender == WRAPPED_NATIVE); // only accept ETH via fallback from the WRAPPED_NATIVE contract
    }

    /// @inheritdoc IICHIVaultDepositGuard
    function forwardDepositToICHIVault(
        address vault,
        address vaultDeployer,
        address token,
        uint256 amount,
        uint256 minimumProceeds,
        address to
    ) external override nonReentrant returns (uint256 vaultTokens) {
        vaultTokens = _forwardDeposit(vault, vaultDeployer, token, amount, minimumProceeds, to, false);
    }

    /// @inheritdoc IICHIVaultDepositGuard
    function forwardNativeDepositToICHIVault(
        address vault,
        address vaultDeployer,
        uint256 minimumProceeds,
        address to
    ) external payable override nonReentrant returns (uint256 vaultTokens) {
        uint256 nativeAmount = msg.value;
        IWRAPPED_NATIVE(WRAPPED_NATIVE).deposit{ value: nativeAmount }();

        vaultTokens = _forwardDeposit(vault, vaultDeployer, WRAPPED_NATIVE, nativeAmount, minimumProceeds, to, true);
    }

    /// @inheritdoc IICHIVaultDepositGuard
    function forwardWithdrawFromICHIVault(
        address vault,
        address vaultDeployer,
        uint256 shares,
        address to,
        uint256 minAmount0,
        uint256 minAmount1
    ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _forwardWithdraw(vault, vaultDeployer, shares, to, minAmount0, minAmount1, false);
    }

    /// @inheritdoc IICHIVaultDepositGuard
    function forwardNativeWithdrawFromICHIVault(
        address vault,
        address vaultDeployer,
        uint256 shares,
        address to,
        uint256 minAmount0,
        uint256 minAmount1
    ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = _forwardWithdraw(vault, vaultDeployer, shares, to, minAmount0, minAmount1, true);
    }

    /// @inheritdoc IICHIVaultDepositGuard
    function vaultKey(
        address vaultDeployer,
        address token0,
        address token1,
        uint24 fee,
        bool allowToken0,
        bool allowToken1
    ) public view override returns (bytes32 key) {
        key = IICHIVaultFactory(ICHIVaultFactory).genKey(vaultDeployer, token0, token1, fee, allowToken0, allowToken1);
    }

    function _forwardDeposit(
        address vault,
        address vaultDeployer,
        address token,
        uint256 amount,
        uint256 minimumProceeds,
        address to,
        bool depositNative
    ) private returns (uint256 vaultTokens) {
        _validateRecipient(to);
        (IICHIVault ichiVault, address token0, address token1) = _validateVault(vault, vaultDeployer, depositNative);

        require(token == token0 || token == token1, "Invalid token");

        if (token == token0) {
            require(ichiVault.allowToken0(), "Token0 deposits not allowed");
        } else {
            require(ichiVault.allowToken1(), "Token1 deposits not allowed");
        }

        // if deposit is a native deposit then we don't need to transfer WRAPPED_NATIVE
        // since this contract receives WRAPPED_NATIVE amount on successful WRAPPED_NATIVE#deposit
        if (!depositNative) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        IERC20(token).safeIncreaseAllowance(vault, amount);

        uint256 token0Amount = token == token0 ? amount : 0;
        uint256 token1Amount = token == token1 ? amount : 0;

        vaultTokens = ichiVault.deposit(token0Amount, token1Amount, to);
        require(vaultTokens >= minimumProceeds, "Slippage too great. Try again.");

        emit DepositForwarded(msg.sender, vault, token, amount, vaultTokens, to);
    }

    function _forwardWithdraw(
        address vault,
        address vaultDeployer,
        uint256 shares,
        address to,
        uint256 minAmount0,
        uint256 minAmount1,
        bool withdrawNative
    ) private returns (uint256 amount0, uint256 amount1) {
        _validateRecipient(to);
        (IICHIVault ichiVault, address token0, address token1) = _validateVault(vault, vaultDeployer, withdrawNative);

        // - sender must grant the guard an allowance for the vault share token
        // - the guard can then transfer those share tokens to itself
        // - the guard then approves the vault an allowance in order to burn shares and withdraw from the vault
        IERC20(vault).safeTransferFrom(msg.sender, address(this), shares);

        if (withdrawNative) {
            // the vault temporarily custodies the withdrawn amounts
            (amount0, amount1) = ichiVault.withdraw(shares, address(this));
            if (token0 == WRAPPED_NATIVE) {
                IWRAPPED_NATIVE(WRAPPED_NATIVE).withdraw(amount0);
                payable(to).transfer(amount0);
                IERC20(token1).safeTransfer(to, amount1);
            } else {
                IWRAPPED_NATIVE(WRAPPED_NATIVE).withdraw(amount1);
                payable(to).transfer(amount1);
                IERC20(token0).safeTransfer(to, amount0);
            }
        } else {
            (amount0, amount1) = ichiVault.withdraw(shares, to);
        }

        require(amount0 >= minAmount0 && amount1 >= minAmount1, "Insufficient out");
    }

    function _validateRecipient(address to) private {
        require(to != NULL_ADDRESS, "Invalid to");
    }

    function _validateVault(
        address vault,
        address vaultDeployer,
        bool validateNative
    ) private returns (IICHIVault ichiVault, address token0, address token1) {
        ichiVault = IICHIVault(vault);

        token0 = ichiVault.token0();
        token1 = ichiVault.token1();

        if (validateNative) {
            require(token0 == WRAPPED_NATIVE || token1 == WRAPPED_NATIVE, "Native vault");
        }

        bytes32 factoryVaultKey = vaultKey(
            vaultDeployer,
            token0,
            token1,
            ichiVault.fee(),
            ichiVault.allowToken0(),
            ichiVault.allowToken1()
        );

        require(IICHIVaultFactory(ICHIVaultFactory).getICHIVault(factoryVaultKey) == vault, "Invalid vault");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IICHIVault is IERC20 {
    function ichiVaultFactory() external view returns (address);

    function pool() external view returns (address);

    function token0() external view returns (address);

    function allowToken0() external view returns (bool);

    function token1() external view returns (address);

    function allowToken1() external view returns (bool);

    function fee() external view returns (uint24);

    function tickSpacing() external view returns (int24);

    function affiliate() external view returns (address);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function deposit0Max() external view returns (uint256);

    function deposit1Max() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);

    function hysteresis() external view returns (uint256);

    function getTotalAmounts() external view returns (uint256, uint256);

    function deposit(uint256, uint256, address) external returns (uint256);

    function withdraw(uint256, address) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        int256 swapQuantity
    ) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function setAffiliate(address _affiliate) external;

    event DeployICHIVault(
        address indexed sender,
        address indexed pool,
        bool allowToken0,
        bool allowToken1,
        address owner,
        uint256 twapPeriod
    );

    event SetTwapPeriod(address sender, uint32 newTwapPeriod);

    event Deposit(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

    event Withdraw(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event MaxTotalSupply(address indexed sender, uint256 maxTotalSupply);

    event Hysteresis(address indexed sender, uint256 hysteresis);

    event DepositMax(address indexed sender, uint256 deposit0Max, uint256 deposit1Max);

    event Affiliate(address indexed sender, address affiliate);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

interface IICHIVaultDepositGuard {

    /// @notice Emitted when the contract is deployed.
    /// @param _ICHIVaultFactory Address of the ICHIVaultFactory.
    /// @param _WETH Address of the Wrapped ETH token.
    event Deployed(address _ICHIVaultFactory, address _WETH);

    /// @notice Emitted when a deposit is forwarded to an ICHIVault.
    /// @param sender The address initiating the deposit.
    /// @param vault The ICHIVault receiving the deposit.
    /// @param token The token being deposited.
    /// @param amount The amount of the token being deposited.
    /// @param shares The amount of shares issued in the vault as a result of the deposit.
    /// @param to The address receiving the vault shares.
    event DepositForwarded(
        address indexed sender,
        address indexed vault,
        address indexed token,
        uint256 amount,
        uint256 shares,
        address to
    );

    /// @notice Retrieves the address of the ICHIVaultFactory.
    /// @return Address of the ICHIVaultFactory.
    function ICHIVaultFactory() external view returns (address);

    /// @notice Retrieves the address of the Wrapped Native Token (e.g., WETH).
    /// @return Address of the Wrapped Native Token.
    function WRAPPED_NATIVE() external view returns (address);

    /// @notice Forwards a deposit to the specified ICHIVault after input validation.
    /// @dev Emits a DepositForwarded event upon success.
    /// @param vault The address of the ICHIVault to deposit into.
    /// @param vaultDeployer The address of the vault deployer.
    /// @param token The address of the token being deposited.
    /// @param amount The amount of the token being deposited.
    /// @param minimumProceeds The minimum amount of vault tokens to be received.
    /// @param to The address to receive the vault tokens.
    /// @return vaultTokens The number of vault tokens received.
    function forwardDepositToICHIVault(
        address vault,
        address vaultDeployer,
        address token,
        uint256 amount,
        uint256 minimumProceeds,
        address to
    ) external returns (uint256 vaultTokens);

    /// @notice Forwards a native currency (e.g., ETH) deposit to an ICHIVault.
    /// @dev Converts the native currency to Wrapped Native Token before deposit.
    /// @param vault The address of the ICHIVault to deposit into.
    /// @param vaultDeployer The address of the vault deployer.
    /// @param minimumProceeds The minimum amount of vault tokens to be received.
    /// @param to The address to receive the vault tokens.
    /// @return vaultTokens The number of vault tokens received.
    function forwardNativeDepositToICHIVault(
        address vault,
        address vaultDeployer,
        uint256 minimumProceeds,
        address to
    ) external payable returns (uint256 vaultTokens);

    /// @notice Forwards a request to withdraw from an ICHIVault.
    /// @param vault The address of the ICHIVault to withdraw from.
    /// @param vaultDeployer The address of the vault deployer.
    /// @param shares The amount of shares to withdraw.
    /// @param to The address to receive the withdrawn tokens.
    /// @param minAmount0 The minimum amount of token0 expected to receive.
    /// @param minAmount1 The minimum amount of token1 expected to receive.
    /// @return amount0 The amount of token0 received.
    /// @return amount1 The amount of token1 received.
    function forwardWithdrawFromICHIVault(
        address vault,
        address vaultDeployer,
        uint256 shares,
        address to,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Forwards a request to withdraw native currency from an ICHIVault.
    /// @dev Converts the Wrapped Native Tokens back to native currency on withdrawal.
    /// @param vault The address of the ICHIVault to withdraw from.
    /// @param vaultDeployer The address of the vault deployer.
    /// @param shares The amount of shares to withdraw.
    /// @param to The address to receive the withdrawn native currency.
    /// @param minAmount0 The minimum amount of token0 expected to receive.
    /// @param minAmount1 The minimum amount of token1 expected to receive.
    /// @return amount0 The amount of token0 received.
    /// @return amount1 The amount of token1 received.
    function forwardNativeWithdrawFromICHIVault(
        address vault,
        address vaultDeployer,
        uint256 shares,
        address to,
        uint256 minAmount0,
        uint256 minAmount1
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Computes the unique key for a vault based on given parameters.
    /// @param vaultDeployer The address of the vault deployer.
    /// @param token0 The address of the first token in the vault.
    /// @param token1 The address of the second token in the vault.
    /// @param fee The fee associated with the vault.
    /// @param allowToken0 Boolean indicating if token0 is allowed in the vault.
    /// @param allowToken1 Boolean indicating if token1 is allowed in the vault.
    /// @return key The computed unique key for the vault.
    function vaultKey(
        address vaultDeployer,
        address token0,
        address token1,
        uint24 fee,
        bool allowToken0,
        bool allowToken1
    ) external view returns (bytes32 key);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

interface IICHIVaultFactory {
    event FeeRecipient(address indexed sender, address feeRecipient);

    event BaseFee(address indexed sender, uint256 baseFee);

    event BaseFeeSplit(address indexed sender, uint256 baseFeeSplit);

    event DeployICHIVaultFactory(address indexed sender, address uniswapV3Factory);

    event ICHIVaultCreated(
        address indexed sender,
        address ichiVault,
        address tokenA,
        bool allowTokenA,
        address tokenB,
        bool allowTokenB,
        uint24 fee,
        uint256 count
    );

    function getICHIVault(bytes32 vaultKey) external view returns (address);

    function uniswapV3Factory() external view returns (address);

    function feeRecipient() external view returns (address);

    function baseFee() external view returns (uint256);

    function baseFeeSplit() external view returns (uint256);

    function setFeeRecipient(address _feeRecipient) external;

    function setBaseFee(uint256 _baseFee) external;

    function setBaseFeeSplit(uint256 _baseFeeSplit) external;

    function createICHIVault(
        address tokenA,
        bool allowTokenA,
        address tokenB,
        bool allowTokenB,
        uint24 fee
    ) external returns (address ichiVault);

    function genKey(
        address deployer,
        address token0,
        address token1,
        uint24 fee,
        bool allowToken0,
        bool allowToken1
    ) external pure returns (bytes32 key);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWRAPPED_NATIVE {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}