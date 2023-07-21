// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2Factory {
    error IdenticalAddress();
    error ZeroAddress();
    error PairAlreadyExists();
    error OnlyFeeToSetter();

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2ERC20} from "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint;

    function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(rhs) / (2 ** 112);
    }

    function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(2 ** 112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
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

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Router01} from "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    error Expired();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error InvalidPath();
    error ExcessiveInputAmount();

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlHolder
 * @notice Interface created to store reference to the access control.
 */
interface IAccessControlHolder {
    /**
     * @notice Function returns reference to IAccessControl.
     * @return IAccessControl reference to access control.
     */
    function acl() external view returns (IAccessControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IChronosRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Router02} from "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../dex/core/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ILockdrop
 * @notice  The purpose of the Lockdrop contract is to provide liquidity to the newly created dex by collecting funds from users
 */
interface ILockdrop {
    error WrongAllocationState(
        AllocationState current,
        AllocationState expected
    );

    error TimestampsIncorrect();
    error PairAlreadyCreated();

    enum AllocationState {
        NOT_STARTED,
        ALLOCATION_ONGOING,
        ALLOCATION_FINISHED
    }

    /**
     * @notice Function allows the authorized wallet to add liquidity on SpartaDEX router.
     * @param router_ Address of SpartaDexRouter.
     * @param deadline_ Deadline by which liquidity should be added.
     */
    function addTargetLiquidity(
        IUniswapV2Router02 router_,
        uint256 deadline_
    ) external;

    /**
     * @notice Function returns the newly created SpartaDexRouter.
     * @return IUniswapV2Router02 Address of the router.
     */
    function spartaDexRouter() external view returns (IUniswapV2Router02);

    /**
     * @notice Function returns the timestamp of the lockdrop start.
     * @return uint256 Start timestamp.
     */
    function lockingStart() external view returns (uint256);

    /**
     * @notice Function returns the timestamp of the lockdrop end.
     * @return uint256 End Timestamp.
     */
    function lockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the timestamp of the unlocking period end.
     * @return uint256 The ending timestamp.
     */
    function unlockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the amount of the tokens that correspond to the provided liquidity on SpartaDex.
     * @return uint256 Amount of LP tokens.
     */
    function initialLpTokensBalance() external view returns (uint256);

    /**
     * @notice Function returns the total reward for the lockdrop.
     * @return uint256 Total amount of reward.
     */
    function totalReward() external view returns (uint256);

    /**
     * @notice Function returns the exchange pair address for the lockdrop.
     * @return IUniswapV2Pair Address of token created on the target DEX.
     */
    function exchangedPair() external view returns (address);

    /**
     * @notice Function returns the reward of the lockdrop
     * @return IERC20 Address
     *  of reward token.
     */
    function rewardToken() external view returns (IERC20);

    /**
     * @notice Function returns time from which funds can be withdrawn if migration has not taken place.
     * @return uint256 Migration start timestamp.
     */
    function migrationEndTimestamp() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Pair} from "../dex/core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import {ITokenVesting} from "../vesting/ITokenVesting.sol";
import {ILockdropPhase2} from "./ILockdropPhase2.sol";
import {ILockdropPhase1Helper} from "./ILockdropPhase1Helper.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct LockingToken {
    bool isChronos;
    bool isStable;
    address token;
    address router;
}

/**
 * @title ILockdropPhase1.
 * @notice The contract was created to collect liquidity from other decentralized uniswap v2 exchanges on the network, which will be delivered to the newly created dex.
 * Users who locate their funds for a certain period of time will receive new liquidity tokens on the new exchange in return, and receive a reward.
 */
interface ILockdropPhase1 {
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error ToEarlyAllocationState(LockdropState current, LockdropState atLeast);
    error SourceLiquidityAlreadyRemoved();
    error RewardRatesAlreadyCalculated();
    error TokenAllocationAlreadyTaken();
    error CannotUnlockTokensBeforeUnlockTime();
    error MaxRewardExceeded();
    error SpartaDexNotInitialized();
    error AllocationDoesNotExist();
    error AllocationCanceled();
    error NotEnoughToWithdraw();
    error OnlyLockdropPhase1ResolverAccess();
    error Phase2NotFinished();
    error NotDefinedExpirationTimestamp();
    error WrongExpirationTimestamps();
    error RewardNotCalculated();
    error CannotCalculateRewardForChunks();
    error AlreadyCalculated();
    error MaxLengthExceeded();
    error LockingTokenNotExists();
    error WalletDidNotTakePartInLockdrop();
    error CannotUnlock();
    error MinPercentage();

    event LiquidityProvided(
        address indexed by,
        address pair,
        uint32 durationIndex,
        uint256 value,
        uint256 points
    );

    struct RemoveData {
        uint256 minPercentage0_;
        uint256 minPercentage1_;
        uint256 deadline_;
    }

    event RewardLockedOnLockdropPhase2(address indexed by, uint256 value);

    event RewardWithdrawn(address indexed by, uint256 amount);

    event RewardSentOnVesting(address indexed by, uint256 amount);

    event LiquidityUnlocked(
        address indexed by,
        uint256 indexed allocationIndex,
        uint256 value
    );

    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED,
        TOKENS_ALLOCATION_FINISHED,
        SOURCE_LIQUIDITY_EXCHANGED,
        TARGET_LIQUIDITY_PROVIDED,
        MIGRATION_END
    }

    struct UserAllocation {
        bool taken;
        address token;
        uint256 tokenIndex;
        uint32 unlockTimestampIndex;
        uint256 value;
        uint256 boost;
        uint256 points;
    }

    struct TokenParams {
        address tokenAToken;
        address tokenBToken;
        uint256 tokenAPrice;
        uint256 tokenBPrice;
    }

    struct ContractAddress {
        ILockdropPhase2 phase2;
        ITokenVesting vesting;
        IAccessControl acl;
        ILockdropPhase1Helper helper;
    }

    struct RewardParams {
        IERC20 rewardToken;
        uint256 rewardAmount;
    }

    /**
     * @notice Function allows users lock their LP tokens on the contract.
     * @param _tokenIndex Index of the tokens from the locking tokens array.
     * @param _value Amount of tokens the user wants to lock.
     * @param _lockingExpirationTimestampIndex Index of the duration of the locking.
     */
    function lock(
        uint256 _tokenIndex,
        uint256 _value,
        uint32 _lockingExpirationTimestampIndex
    ) external;

    /**
     * @notice Function allows the user to unlock his LP tokens right away.
     * @param _allocationIndex Index of the created Allocations.
     * @param _value Amount of the tokens a user wants to unlock.
     */
    function unlock(uint256 _allocationIndex, uint256 _value) external;

    /**
     * @notice Function allows the user to take the reward and send part of it to the vesting contract.
     */
    function getRewardAndSendOnVesting() external;

    /**
     * @notice Function allows the user to allocate part of his earned reward on the lockdrop phase 2.
     * @param _amount The amount of reward to be allocated.
     */
    function allocateRewardOnLockdropPhase2(uint256 _amount) external;

    /**
     * @notice Function calculates and stores total reward in chunks. Chunks are a number of allocations that will be used to calculate the reward.
     * @param _wallet The address of the wallet. .
     * @param _chunks The number of chunks .
     * @return uint256 Reward earned by wallet from the the given amount of chunks.
     */
    function calculateAndStoreTotalRewardInChunks(
        address _wallet,
        uint256 _chunks
    ) external returns (uint256);

    /**
     * @notice Function allows authorized user to remove liquidity on one of the locked tokens.
     * @param deadline_ Deadline of the transaction execution.
     */
    function removeSourceLiquidity(
        uint256 minPercentage0_,
        uint256 minPercentage1_,
        uint256 deadline_
    ) external;

    /**
     * @notice Function allows the user to withdraw exchanged tokens of the newly provided liquidity.
     * @param allocationsIds Ids of locking token allocations of a user.
     */
    function withdrawExchangedTokens(
        uint256[] calldata allocationsIds
    ) external;

    /**
     * @notice Function returns the current state of the Lockdrop.
     * @return LockdropState current state of the lockdrop.
     */
    function state() external view returns (LockdropState);

    /**
     * @notice Function calculates the total reward earned by the wallet.
     * @param _wallet Address of the wallet for which the total reward will be calculated.
     * @return uint256 Total reward earned by the wallet.
     */
    function calculateTotalReward(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function returns address of the vesting contract.
     * @return ITokenVesting Reference to the vesting implementation.
     */
    function vesting() external view returns (ITokenVesting);

    /**
     * @notice Function returns address if phase2 contract
     * @return ILockdropPhase2 Reference to the phase2 implementation.
     */
    function phase2() external view returns (ILockdropPhase2);

    /**
     * @notice Function returns the address of token A.
     * @return address The address of token A.
     */
    function tokenAAddress() external view returns (address);

    /**
     * @notice Function returns the address of token B.
     * @return address The address of token B.
     */
    function tokenBAddress() external view returns (address);

    /**
     * @notice Function returns token A price
     * @return Price of the token.
     */
    function tokenAPrice() external view returns (uint256);

    /**
     * @notice Function returns token B price
     * @return Price of the token.
     */
    function tokenBPrice() external view returns (uint256);

    /**
     * @notice Function returns addresses of the pairs users can lock on the contract and the pairs' routers.
     * @return LockingToken[] Array of pair addresses with their routers.
     */
    function getLockingTokens() external view returns (LockingToken[] memory);

    /**
     * @notice Function returns locking expiration timestamps supported by the contract.
     * @return uint256[] Locking expiration timestamps supported by the contract.
     */
    function getLockingExpirationTimestamps()
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Function returns total reward from the given allocation.
     * @param allocation Allocation from which the reward should be calculated.
     * @return uint256 Reward from allocations .
     */
    function calculateRewardFromAllocation(
        UserAllocation memory allocation
    ) external view returns (uint256);

    /**
     * @notice Function returns all allocations locked by the wallet.
     * @param _wallet Address of the wallet the allocation will be returned.
     * @return UserAllocation[] Allocations of user.
     */
    function getUserAllocations(
        address _wallet
    ) external view returns (UserAllocation[] memory);

    /**
     * @notice Function checks if the user has already calculated the reward.
     * @param _wallet address the wallet.
     * @return bool Indicates the reward calculation.
     */
    function isRewardCalculated(address _wallet) external view returns (bool);

    /**
     * @notice function calculates the reward from the allocations of the particular wallet.
     * @dev if the index is bigger than max count, the function reverts with AllocationDoesNotExist.
     * @param _wallet the address of the wallet.
     * @param _allocations array of the ids of allocations.
     * @return uint256 totalReward earned by wallet.
     */
    function calculateRewardFromAllocations(
        address _wallet,
        uint256[] calldata _allocations
    ) external view returns (uint256);

    /**
     * @notice Function used to calculate the price of one of the locking tokens.
     * @param _tokenIndex index of the token from the locking tokens array.
     * @return uint256 the price defined as the amount of ETH * 2**112.
     */
    function getLPTokenPrice(
        uint256 _tokenIndex
    ) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IUniswapV2Factory} from "../dex/core/interfaces/IUniswapV2Factory.sol";
import {IChronosRouter} from "./IChronosRouter.sol";
import {LockingToken} from "./ILockdropPhase1.sol";

/**
 * @title ILockdropPhase1Helper
 * @notice This contracts reduces the bytecode of the LockdropPhase1 contract.
 */

interface ILockdropPhase1Helper {
    error PairAlreadyCreated();

    /**
     * @notice Function created to remove liquidity on the dex.
     * @param  token Struct of token parameters.
     * @param  min0  Minial amount of token0.
     * @param  min1 Minimal amount of token1.
     * @param  deadline Deadline to exectue.
     */
    function removeLiquidity(
        LockingToken memory token,
        uint256 min0,
        uint256 min1,
        uint256 deadline
    ) external;

    /**
     * @notice Function returnes the price of the token
     * @param token LPtoken
     * @param tokenAAddress Address of A token.
     * @param tokenAPrice Amount of wei ETH * 2**112
     * @param tokenBPrice Amount of wei ETH * 2**112
     * @return uint256 Price.
     */
    function getPrice(
        address token,
        address tokenAAddress,
        uint256 tokenAPrice,
        uint256 tokenBPrice
    ) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20Decimals} from "../tokens/interfaces/IERC20Decimals.sol";
import {ILockdrop} from "./ILockdrop.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @title ILockdropPhase2
 * @notice  The goal of LockdropPhase2 is to collect SPARTA tokens and StableCoin, which will be used to create the corresponding pair on SpartaDex.
 */
interface ILockdropPhase2 is ILockdrop {
    error RewardAlreadyTaken();
    error CannotUnlock();
    error NothingToClaim();
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error OnlyLockdropPhase2ResolverAccess();
    error CannotAddLiquidity();

    event Locked(
        address indexed by,
        address indexed beneficiary,
        IERC20 indexed token,
        uint256 amount
    );

    event Unlocked(address indexed by, IERC20 indexed token, uint256 amount);

    event RewardWitdhrawn(address indexed wallet, uint256 amount);

    event TokensClaimed(address indexed wallet, uint256 amount);

    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED,
        TOKENS_ALLOCATION_FINISHED,
        TOKENS_EXCHANGED,
        MIGRATION_END
    }

    /**
     * @notice Function allows user to lock the certain amount of SPARTA tokens.
     * @param _amount Amount of tokens to lock.
     * @param _wallet Address of the wallet to which the blocked tokens will be assigned.
     */
    function lockSparta(uint256 _amount, address _wallet) external;

    /**
     * @notice Function allows user to lock the certain amount of StableCoin tokens.
     * @param _amount Amount of tokens to lock.
     */
    function lockStable(uint256 _amount) external;

    /**
     * @notice Function allows user to unlock already allocated StableCoin.
     * @param _amount  Amount of tokens the user want to unlock.
     */
    function unlockStable(uint256 _amount) external;

    /**
     * @notice Function allows user to unlock already allocated Sparta.
     * @param _amount  Amount of tokens the user want to unlock.
     */
    function unlockSparta(uint256 _amount) external;

    /**
     * @notice Function returns the amount of SPARTA tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated SPARTA.
     * @return uint256 Number of SPARTA tokens locked on the contract.
     */
    function walletSpartaLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function returns the amount of Stable tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated Stable.
     * @return uint256 Amount of locked Stable coins.
     */
    function walletStableLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function allows the user to take the corresponding amount of SPARTA/StableCoin LP token from the contract.
     */
    function claimTokens() external;

    /**
     * @notice Function allows the user to withdraw the earned reward.
     */
    function getReward() external;

    /**
     * @notice Function calculates the amount of sparta the user will get after staking particular amount of tokens.
     * @param  stableAmount Amount of StableCoin tokens.
     * @return uint256 Reward corresponding to the number of StableCoin tokens.
     */
    function calculateRewardForStable(
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the amount of sparta a user will get after staking particular amount of tokens.
     * @param  spartaAmount Amount of SPARTA tokens.
     * @return uint256 Reward corresponding to the number of SPARTA tokens.
     */
    function calculateRewardForSparta(
        uint256 spartaAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the reward for the given amounts of the SPARTA and the StableCoin tokens.
     * @param spartaAmount Amount of SPARTA tokens.
     * @param stableAmount Amount of StableCoin tokens.
     * @return uint256 Total reward corresponding to the amount of SPARTA and the amount of STABLE tokens.
     */
    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function returns the total reward earned by the wallet.
     * @param wallet_ Address of the wallet whose reward we want to calculate.
     * @return uint256 Total reward earned by the wallet.
     */
    function calculateReward(address wallet_) external view returns (uint256);

    /**
     * @notice Function returns the current state of the lockdrop.
     * @return LockdropState State of the lockdrop.
     */
    function state() external view returns (LockdropState);

    /**
     * @notice Function calculates the amount of SPARTA/StableCoin LP tokens the user can get after providing liquidity on the SPARTA dex.
     * @param _wallet Address of the wallet of the user for whom we want to check the amount of the reward.
     * @return uint256 Amount of SPARTA/StableCoin LP tokens corresponding to the wallet.
     */
    function availableToClaim(address _wallet) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {ILockdropPhase1, LockingToken, IUniswapV2Pair, IUniswapV2Router02} from "./ILockdropPhase1.sol";
import {IUniswapV2Factory} from "../dex/core/interfaces/IUniswapV2Factory.sol";
import {IChronosRouter} from "./IChronosRouter.sol";
import {ILockdropPhase1Helper} from "./ILockdropPhase1Helper.sol";
import {HomoraMath, SafeMath} from "../dex/libs/HomarMath.sol";
import {IAccessControlHolder, IAccessControl} from "../IAccessControlHolder.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LockdropPhase1Helper
 * Implementation of ILockdropPhase1Helper
 */

contract LockdropPhase1Helper is ILockdropPhase1Helper, IAccessControlHolder {
    using SafeERC20 for IERC20;
    using HomoraMath for uint256;
    using SafeMath for uint256;

    bytes32 public constant LOCKDROP = keccak256("LOCKDROP");
    error OnyLockdrop();

    IAccessControl public immutable override acl;

    /**
     * @notice Checks the sender gas LOCKDROP role.
     * @dev Reverts with OnloLockdrop if the sender does not have role.
     */
    modifier onlyLockdrop() {
        if (!acl.hasRole(LOCKDROP, msg.sender)) {
            revert OnyLockdrop();
        }
        _;
    }

    constructor(IAccessControl acl_) {
        acl = acl_;
    }

    /**
     * @inheritdoc ILockdropPhase1Helper
     */
    function removeLiquidity(
        LockingToken memory token,
        uint256 min0,
        uint256 min1,
        uint256 deadline
    ) external onlyLockdrop {
        IUniswapV2Pair pair = IUniswapV2Pair(token.token);
        uint256 balance = pair.balanceOf(address(this));
        address token0 = pair.token0();
        address token1 = pair.token1();
        IERC20(token.token).forceApprove(token.router, balance);

        if (token.isChronos) {
            _removeOnChronos(
                token,
                token0,
                token1,
                balance,
                min0,
                min1,
                msg.sender,
                deadline
            );
        } else {
            _remove(
                token,
                token0,
                token1,
                balance,
                min0,
                min1,
                msg.sender,
                deadline
            );
        }
    }

    /**
     * @notice Function removes liquidity on chronos type of dex.
     * @param token LP token.
     * @param token0 Token0 of the pair.
     * @param token1 Token1 of the pair.
     * @param balance Balance of token.
     * @param min0 Minimal amount of token0.
     * @param min1 Minimal amount of token1.
     * @param to Address where tokens should go.
     * @param deadline Deadline to execute.
     */
    function _removeOnChronos(
        LockingToken memory token,
        address token0,
        address token1,
        uint256 balance,
        uint256 min0,
        uint256 min1,
        address to,
        uint256 deadline
    ) internal {
        IChronosRouter(token.router).removeLiquidity(
            token0,
            token1,
            token.isStable,
            balance,
            min0,
            min1,
            to,
            deadline
        );
    }

    /**
     * @notice Function removes liquidity on chronos type of dex.
     * @param token LP token.
     * @param token0 Token0 of the pair.
     * @param token1 Token1 of the pair.
     * @param balance Balance of token.
     * @param min0 Minimal amount of token0.
     * @param min1 Minimal amount of token1.
     * @param to Address where tokens should go.
     * @param deadline Deadline to execute.
     */
    function _remove(
        LockingToken memory token,
        address token0,
        address token1,
        uint256 balance,
        uint256 min0,
        uint256 min1,
        address to,
        uint256 deadline
    ) internal {
        IUniswapV2Router02(token.router).removeLiquidity(
            token0,
            token1,
            balance,
            min0,
            min1,
            to,
            deadline
        );
    }

    /**
     * @notice Function returns price of the the LP token.
     * @param token LPToken.
     * @param tokenAAddress Address of token A.
     * @param tokenAPrice  Amount of wei ETH * 2**112.
     * @param tokenBPrice Amount of wei ETH * 2**112.
     * @return uint256 Price in wei ETH * 2**112.
     */
    function getPrice(
        address token,
        address tokenAAddress,
        uint256 tokenAPrice,
        uint256 tokenBPrice
    ) external view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        uint256 totalSupply = pair.totalSupply();
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 px0, uint256 px1) = pair.token0() == tokenAAddress
            ? (tokenAPrice, tokenBPrice)
            : (tokenBPrice, tokenAPrice);

        uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply);
        return
            sqrtK
                .mul(2)
                .mul(HomoraMath.sqrt(px0))
                .div(2 ** 56)
                .mul(HomoraMath.sqrt(px1))
                .div(2 ** 56);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ITokenVesting.
 * @notice This is an interface for token vesting. It includes functionalities for adding vesting schedules and claiming vested tokens.
 */
interface ITokenVesting {
    error InvalidScheduleID();
    error VestingNotStarted();
    error AllTokensClaimed();
    error OnlyVestingManagerAccess();
    error MaxSchedules();

    event VestingAdded(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 startTime,
        uint256 endTime,
        uint256 amount
    );

    event TokenWithdrawn(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 value
    );

    struct Vesting {
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    /**
     * @notice Adds a vesting schedule for a beneficiary.
     * @param beneficiary Address of the beneficiary.
     * @param startTime Start time of the vesting schedule.
     * @param duration Duration of the vesting schedule.
     * @param amount Total amount of tokens to be vested.
     */
    function addVesting(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    ) external;

    /**
     * @notice Allows a beneficiary to claim vested tokens.
     * @param scheduleIds Array of identifiers for the vesting schedules.
     */
    function claim(uint256[] calldata scheduleIds) external payable;
}