// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// Importing OpenZeppelin's IERC20 interface and Ownable contract for standard ERC20 functionality and ownership management
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// This contact is a replacement for the old Staking contract.
/// @dev This contract is meant to replace the existing Staking contract. It will include all the stakes from the old contract and will be marked as started with the same timestamp as the old contract
/// @title CatchStaking
contract CatchStaking is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public catchToken; /// the ERC20 token to be staked

    /// @dev Struct to hold information about each stake
    struct Stake {
        uint256 amount; /// Amount of tokens staked
        uint256 startTime; /// Timestamp when the stake starts
        uint256 endTime; /// Timestamp when the stake ends (unlocks)
        bool withdrawn; /// Flag to check if the stake has been withdrawn
    }

    // Role identifiers.
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // Role for staking management operations.

    /// Constants for reward calculations and staking mechanism
    uint256 private constant LOCK_PERIOD = 90 days; /// Minimum staking period
    uint256 private constant TOTAL_REWARD_ALLOCATION = 20_000_000 * 10 ** 18; /// Initial reward pool size of 20 million tokens with 18 decimal places
    uint256 private constant HALVING_PERIOD = 365 days; /// Period for reward halving. Every HALVING_PERIOD, the reward pool is halved. There will be 4 halvings.
    uint256 private constant REWARD_INTERVAL = 1 days;

    /// @dev Variables for tracking the state of the staking contract
    uint256 public totalStaked; /// Total amount of tokens staked
    uint256 public stakingStartTime; /// Timestamp of the start of staking
    uint256 public stakingEndTime; /// Timestamp when staking ends. Staking will run for 5 years.

    uint256 private constant MULTIPLIER = 1e18; /// Multiplier used for reward calculation precision
    uint256 public rewardIndexUpdatedAt; /// Last timestamp when the reward index was updated
    uint256 public rewardIndex; /// Current reward index for calculating user rewards

    /// Mappings for managing stakers, their stakes, and rewards
    mapping(address => uint256) public addressRewardIndex; /// @dev Tracks the reward index per stake for each staker. It is used to calculate the rewards for each staker.
    mapping(address => uint256) public earned; /// @dev After updating the reward index of a staker, the calculated rewards are stored in this mapping.

    uint256 public constant rewardBaseUnit =
        (TOTAL_REWARD_ALLOCATION * 16) / 31 / 365; /// @dev Base reward unit calculated from the initial allocation. It is used to calculate the staking rewards.

    mapping(address => Stake[]) public stakes; /// Mapping from staker address to their stakes

    /// @dev This parameter is mark the Staking contract as cancelled. It will allow the ADMIN to reclaim the remaining tokens in the reward pool. It will also allow the stakers to withdraw their stakes immediately.
    bool private stakingIsCanceled;

    /// Events for logging staking activities
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 stakeIndex
    );
    event Unstaked(address indexed user, uint256 amount, uint256 stakeIndex);
    event Claimed(address indexed user, uint256 reward);
    event StakingStarted(uint256 startTime, uint256 endTime);

    /// Modifiers to check staking conditions
    modifier stakingStarted() {
        require(isStakingStarted(), "Staking not yet started");
        _;
    }

    modifier stakingRunning() {
        require(isStakingRunning(), "Staking not running");
        _;
    }

    modifier stakingNotCanceled() {
        require(stakingIsCanceled == false, "Staking has been canceled");
        _;
    }

    /// Constructor to initialize the staking contract with the token address and set the contract creator as the admin
    constructor(address _catchToken) {
        require(_catchToken != address(0), "Token address cannot be zero");

        catchToken = IERC20(_catchToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
    }

    /// PRIVATE FUNCTIONS

    /// @dev Function to calculate the reward unit (which is then used to calculate rewards for individual stakers) at a given timestamp based on the time passed since the last reward index update and the halving period
    function _calculateRewardUnitAt(
        uint256 timestamp
    ) private view returns (uint256) {
        uint256 halvingPeriod = _getHalvingPeriodAt(timestamp);

        uint256 forTimePeriod = (
            timestamp > stakingEndTime ? stakingEndTime : timestamp
        ) - rewardIndexUpdatedAt;

        uint256 rewardUnitAt = ((rewardBaseUnit / (2 ** halvingPeriod)) *
            forTimePeriod) / REWARD_INTERVAL;

        return
            catchToken.balanceOf(address(this)) < rewardUnitAt
                ? catchToken.balanceOf(address(this))
                : rewardUnitAt;
    }

    /// Calculate the rewards for a specific stake based on the reward index and the stake's reward index.
    function _calculateRewardsForStake(
        address _address,
        uint256 stakeIndex,
        uint256 _rewardIndex
    ) private view returns (uint256) {
        /// If the stake is already withdrawn, return 0
        if (stakes[_address][stakeIndex].withdrawn == true) return 0;

        uint256 staked = stakes[_address][stakeIndex].amount;

        return
            (staked * (_rewardIndex - addressRewardIndex[_address])) /
            MULTIPLIER;
    }

    /// Update the earned mapping for a specific address and update it's reward index
    function _updateRewards(address account) private {
        uint256 _earned = earned[account];
        for (uint256 i = 0; i < stakes[account].length; i++) {
            _earned += _calculateRewardsForStake(account, i, rewardIndex);
        }
        addressRewardIndex[account] = rewardIndex;
        earned[account] = _earned;
    }

    /// Calculate the next halving time based on a given halving period (0 - 4)
    /// @return The timestamp of the next halving time
    function _getHalvingTimeAt(
        uint256 halvingPeriod
    ) private view returns (uint256) {
        return stakingStartTime + halvingPeriod * HALVING_PERIOD;
    }

    /// Calculate the reward index at a given timestamp
    function _calculateRewardIndex(
        uint256 timestamp
    ) private view returns (uint256) {
        uint256 rewardUnit = _calculateRewardUnitAt(timestamp);

        if (totalStaked == 0) {
            return rewardIndex;
        }

        return rewardIndex + (rewardUnit * MULTIPLIER) / totalStaked;
    }

    /// Update the reward index based at a given timestamp
    function _updateRewardIndex(uint256 timestamp) private {
        /// @dev If the halving period has changed since the last reward index update, update the reward index for each passed halving period
        if (
            _getHalvingPeriodAt(timestamp) >
            _getHalvingPeriodAt(rewardIndexUpdatedAt)
        ) {
            uint256 lastRewardIndexHalvingPeriod = _getHalvingPeriodAt(
                rewardIndexUpdatedAt
            );
            uint256 currentHalvingPeriod = _getHalvingPeriodAt(timestamp);

            for (
                uint256 i = lastRewardIndexHalvingPeriod;
                i < currentHalvingPeriod;
                i++
            ) {
                uint256 halvingTime = _getHalvingTimeAt(i + 1);

                rewardIndex = _calculateRewardIndex(halvingTime - 1);
                rewardIndexUpdatedAt = halvingTime - 1;
            }
        }

        rewardIndex = _calculateRewardIndex(timestamp);
        rewardIndexUpdatedAt = timestamp > stakingEndTime
            ? stakingEndTime
            : timestamp;
    }

    /// EXTERNAL VIEW FUNCTIONS

    /// Function to check if staking is currently running
    function isStakingRunning() public view returns (bool) {
        return
            stakingStartTime > 0 &&
            stakingStartTime <= block.timestamp &&
            stakingEndTime > block.timestamp &&
            stakingIsCanceled == false;
    }

    function isStakingStarted() public view returns (bool) {
        return stakingStartTime > 0 && stakingStartTime <= block.timestamp;
    }

    function getHalvingPeriod() public view returns (uint256) {
        return _getHalvingPeriodAt(block.timestamp);
    }

    /// Function to get the halving period at a given timestamp. 0 being the first year of staking contract running up to 4 being the fifth year.
    function _getHalvingPeriodAt(
        uint256 timestamp
    ) private view returns (uint256) {
        if (timestamp == 0) timestamp = block.timestamp;
        if (stakingStartTime == 0) return 0;
        if (timestamp > stakingEndTime) return 4;

        return (timestamp - stakingStartTime) / HALVING_PERIOD;
    }

    function getAddressStakeCount(
        address _address
    ) public view returns (uint256) {
        return stakes[_address].length;
    }

    function getAddressStakeByIndex(
        address _address,
        uint256 index
    ) external view returns (Stake memory) {
        require(index < stakes[_address].length, "Invalid index");
        return stakes[_address][index];
    }

    /// function for getting the total staked amount (sum of all unwithdrawn stakes) by an address
    function getStakedAmount(address _address) external view returns (uint256) {
        uint256 totalStakedByAddress = 0;
        for (uint256 i = 0; i < stakes[_address].length; i++) {
            if (stakes[_address][i].withdrawn == false) {
                totalStakedByAddress += stakes[_address][i].amount;
            }
        }
        return totalStakedByAddress;
    }

    /// Get the time remaining for a specific stake to unlock
    function getRemainingLockTime(
        address _address,
        uint256 stakeIndex
    ) external view returns (uint256) {
        require(stakeIndex < stakes[_address].length, "Stake does not exist");

        if (
            stakes[_address][stakeIndex].withdrawn == true ||
            stakes[_address][stakeIndex].endTime < block.timestamp
        ) return 0;
        uint256 remainingTime = stakes[_address][stakeIndex].endTime -
            block.timestamp;

        return remainingTime;
    }

    /// Get the amount of rewards claimable for all stakes by an address at the current timestamp
    function getClaimableRewards(
        address account
    ) external view stakingStarted returns (uint256) {
        uint256 rewardsEarned = earned[account];
        for (uint256 i = 0; i < stakes[account].length; i++) {
            rewardsEarned += _calculateRewardsForStake(
                account,
                i,
                _calculateRewardIndex(block.timestamp)
            );
        }

        return rewardsEarned;
    }

    /// EXTERNAL FUNCTIONS

    /// Function to start the staking contract. Can only be called once.
    /// @param startTimestamp The timestamp when staking should start. Will be same as in the old Staking contract which is being replaced.
    /// @param _rewardIndexUpdatedAt The timestamp which should be set as the last reward index update time. It will be the time just before the old contract was compromised / stopped.
    function startStaking(
        uint256 startTimestamp,
        uint256 _rewardIndexUpdatedAt
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakingStartTime == 0, "Staking already started");
        require(stakingIsCanceled == false, "Staking canceled");
        require(
            _rewardIndexUpdatedAt >= startTimestamp,
            "Invalid reward index update time"
        );
        require(startTimestamp > 0, "Invalid start timestamp");

        stakingStartTime = startTimestamp;
        stakingEndTime = stakingStartTime + 365 days * 5; /// 5 years
        rewardIndexUpdatedAt = _rewardIndexUpdatedAt;

        emit StakingStarted(stakingStartTime, stakingEndTime);
    }

    /// Function to stake tokens. The tokens will be transferred from the sender to the staking contract. The stake will be locked for LOCK_PERIOD time.
    function stake(uint256 _amount) external nonReentrant stakingRunning {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            catchToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );

        /// Update the global reward index
        _updateRewardIndex(block.timestamp);
        /// Compute the rewards earned by the staker between last time this function was called and now, and save that amount to the earned mapping.
        _updateRewards(msg.sender);

        // New stake
        stakes[msg.sender].push(
            Stake(
                _amount,
                block.timestamp,
                block.timestamp + LOCK_PERIOD,
                false
            )
        );

        totalStaked += _amount;

        emit Staked(
            msg.sender,
            _amount,
            block.timestamp,
            block.timestamp + LOCK_PERIOD,
            stakes[msg.sender].length - 1
        );
    }

    /// this function will withdraw all stakes belonging to the sender which are unlocked
    function unstake() external nonReentrant stakingStarted {
        _updateRewardIndex(block.timestamp);
        _updateRewards(msg.sender);

        uint256 withdrawableAmount = 0;

        for (uint256 i = 0; i < stakes[msg.sender].length; i++) {
            // Check if the stake is unlocked and has a balance
            if (
                (stakingIsCanceled == true ||
                    block.timestamp >= stakes[msg.sender][i].endTime) &&
                stakes[msg.sender][i].withdrawn == false
            ) {
                withdrawableAmount += stakes[msg.sender][i].amount;
                stakes[msg.sender][i].withdrawn = true; // Mark the stake as withdrawn
                emit Unstaked(msg.sender, stakes[msg.sender][i].amount, i);
            }
        }

        require(
            withdrawableAmount > 0,
            "No unlocked stake available for withdrawal"
        );

        totalStaked -= withdrawableAmount;

        catchToken.safeTransfer(msg.sender, withdrawableAmount);
    }

    /// Unstake a specific stake by index
    function unstakeByStakeIndex(
        uint256 stakeIndex
    ) external nonReentrant stakingStarted {
        _updateRewardIndex(block.timestamp);
        _updateRewards(msg.sender);

        require(stakeIndex < stakes[msg.sender].length, "Invalid stake index");
        Stake storage userStake = stakes[msg.sender][stakeIndex];
        require(
            stakingIsCanceled == true || block.timestamp >= userStake.endTime,
            "Stake is still locked"
        );
        require(userStake.withdrawn == false, "Stake already withdrawn");

        uint256 amount = userStake.amount;
        userStake.withdrawn = true;
        totalStaked -= amount;

        catchToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount, stakeIndex);
    }

    /// Claim the rewards for the sender
    function claim()
        external
        nonReentrant
        stakingNotCanceled
        stakingStarted
        returns (uint256)
    {
        _updateRewardIndex(block.timestamp);
        /// Compute the rewards earned by the staker between last time this function was called and now, and save that amount to the earned mapping.
        _updateRewards(msg.sender);

        uint256 reward = earned[msg.sender];
        require(reward > 0, "No rewards available for claim");

        earned[msg.sender] = 0;

        catchToken.safeTransfer(msg.sender, reward);
        emit Claimed(msg.sender, reward);

        return reward;
    }

    /**
     * @dev Allows the recovery of mistakenly sent ERC20 tokens (excluding the staking token).
     * @param recoveryTokenAddress The address of the token to recover.
     * @param tokenAmount The amount of tokens to recover.
     */
    function recoverTokens(
        address recoveryTokenAddress,
        uint256 tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (stakingIsCanceled == false) {
            require(
                recoveryTokenAddress != address(catchToken),
                "Cannot recover staking tokens."
            );
        }

        if (recoveryTokenAddress == address(catchToken)) {
            require(
                tokenAmount <=
                    IERC20(recoveryTokenAddress).balanceOf(address(this)) -
                        totalStaked,
                "Can not recover staked tokens."
            );
        }

        require(
            IERC20(recoveryTokenAddress).balanceOf(address(this)) >=
                tokenAmount,
            "Insufficient tokens for recovery."
        );
        IERC20(recoveryTokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    /// this function will allow the ADMIN to reclaim the remaining tokens in the reward pool. It will also allow the stakers to withdraw their stakes immediately.
    function cancelStaking() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakingIsCanceled == false, "Staking already canceled");
        stakingIsCanceled = true;
    }

    /**
     * @dev Sends back stakes to stakers in case staking is canceled.
     */
    function sendBackStakes(
        address[] calldata stakers
    ) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(stakingIsCanceled == true, "Staking not canceled");

        for (uint256 i = 0; i < stakers.length; i++) {
            for (uint256 j = 0; j < stakes[stakers[i]].length; j++) {
                if (stakes[stakers[i]][j].withdrawn == false) {
                    totalStaked -= stakes[stakers[i]][j].amount;
                    catchToken.safeTransfer(
                        stakers[i],
                        stakes[stakers[i]][j].amount
                    );
                    stakes[stakers[i]][j].withdrawn = true;
                }
            }
        }
    }

    /// This function will allow the ADMIN to set the earned rewards for initial stakers. It will be used to set the earned rewards for the stakers from the old contract which is being replaced.
    function setEarnedForInitialStakers(
        address[] calldata stakers,
        uint256[] calldata earneds
    ) external onlyRole(MANAGER_ROLE) {
        require(stakingIsCanceled == false, "Staking canceled");
        require(!isStakingStarted(), "Staking already started");

        require(stakers.length == earneds.length, "Array lengths do not match");

        for (uint i = 0; i < stakers.length; i++) {
            earned[stakers[i]] = earneds[i];
        }
    }

    /// This function will allow the ADMIN to add initial stakes for the stakers. It will be used to set the stakes for the stakers from the old contract which is being replaced.
    function addInitialStakes(
        address[] calldata stakers,
        uint256[] calldata amounts,
        uint256[] calldata startTimes
    ) external onlyRole(MANAGER_ROLE) {
        require(stakingIsCanceled == false, "Staking canceled");
        require(!isStakingStarted(), "Staking already started");

        require(
            stakers.length == amounts.length &&
                stakers.length == startTimes.length,
            "Array lengths do not match"
        );

        uint _totalStaked = 0;

        for (uint i = 0; i < stakers.length; i++) {
            address _address = stakers[i];

            stakes[_address].push(
                Stake(
                    amounts[i],
                    startTimes[i],
                    startTimes[i] + LOCK_PERIOD,
                    false
                )
            );

            _totalStaked += amounts[i];

            emit Staked(
                stakers[i],
                amounts[i],
                startTimes[i],
                startTimes[i] + LOCK_PERIOD,
                stakes[_address].length - 1
            );
        }

        totalStaked += _totalStaked;
    }
}