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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: NONE

pragma solidity ^0.8.21;

interface ITokenStore {
  enum Option {
    Short,
    Long
  }
  enum Status {
    None,
    Opened,
    Closed
  }

  struct TokenConfig {
    bool defined;
    bytes32 pythId;
    uint256 total;
  }

  struct Stable {
    bool defined;
    uint256 total;
  }

  struct Milestone {
    bool defined;
    Status state;
    uint256 sPrice;
    uint256 lPrice;
    uint256 sold;
    uint256 supply;
  }

  struct Representative {
    bool defined;
    bool enabled;
    uint256 firstRepRate;
    uint256 secondRepRate;
  }

  function isSaleActive() external view returns (bool);
  function getMilestoneInfo(uint256 index_) external view returns (Milestone memory);
  function getCurrentMilestoneIndex() external view returns (uint256);
  function regularDepositLimit(address receiver_) external view returns (uint256);
  function maxDepositLimit(address receiver_) external view returns (uint256);
  function getMinimalDepositAmount() external view returns (uint256);
  function getRepresentative(address receiver_, address ambasador_) external view returns (address);
  function getRepresentativeRate(address ambasador_) external view returns (uint256, uint256);
  function getCurrentMilestonePrice(Option option_) external view returns (uint256);
  function getTreasury() external view returns (address);

  function balanceOf(uint256 round_, address user_) external view returns (uint256);
  function representativeBalanceOf(address asset_, address user_) external view returns (uint256);
  function getMilestoneAmount() external view returns (uint256);
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/ITokenStore.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

contract TokenStore is ITokenStore, ReentrancyGuard, AccessControl, Pausable {
  using SafeERC20 for IERC20;

  address internal constant tokenAddress = 0x8888888888888888888888888888888888888888;
  address internal constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint256 public constant MULTIPLIER = 1000000000000000000;
  uint256 public constant precision = 18;

  uint256 private _totalDepositAmount;

  IPyth private _pyth;
  bytes32 private _pythNativePriceFeedId;

  uint256 private _limit;
  uint256 private _totalSoldTokens;

  uint256 private _cRepRate = 50;
  uint256 private _tRepRate = 50;

  address private _treasury;
  Status private _saleStatus;

  Milestone[] private _milestone;
  uint256 private _currentMilestone;

  uint256 private _maxDepositAmount;
  uint256 private _minDepositAmount;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant VERIFIED_ROLE = keccak256("VERIFIED_ROLE");

  mapping(address => Stable) private _stables;
  mapping(address => uint256) private _userTotalBalances;
  mapping(address => mapping(uint256 => uint256)) private _milestoneBalances;
  mapping(address => bool) private _verified;
  mapping(address => Representative) private _reps;
  mapping(address => address) private _repsUsers;
  mapping(address => mapping(address => uint256)) private _repBalances;
  mapping(address => TokenConfig) private _tokenConfig;

  event DepositedToken(
    address indexed receiver,
    address indexed asset,
    address indexed representative,
    uint256 size,
    ITokenStore.Option option,
    uint256 tokensReleased,
    uint256 saleMilestone
  );

  event DepositedNative(
    address indexed receiver,
    address indexed representative,
    uint256 size,
    ITokenStore.Option indexed option,
    uint256 tokensReleased,
    uint256 saleMilestone
  );

  event Claimed(address indexed Representative, address indexed asset, uint256 amount);

  constructor(address treasury_, address[] memory stables_, address pyth_, bytes32 pythNativePriceFeedId_, address[] memory tokens, bytes32[] memory pythIds) {
    require(treasury_ != address(0), "TokenStore: zero bank address");
    require(
      pyth_ != address(0),
      "TokenStore: cant set zero addresses"
    );

    require(tokens.length == pythIds.length, "TokenStore: arrays lengths not equals");

    _treasury = treasury_;

    for (uint256 index = 0; index < stables_.length; index++) {
      require(stables_[index] != address(0), "TokenStore: cant set zero asset address");
      _stables[stables_[index]] = Stable({defined: true, total: 0});
    }
    
    for(uint256 i; i < tokens.length; i++) {
        _tokenConfig[tokens[i]] = TokenConfig({defined: true, pythId: pythIds[i], total:0 });
    }

    _pyth = IPyth(pyth_);
    _pythNativePriceFeedId = pythNativePriceFeedId_;

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(MANAGER_ROLE, _msgSender());
  }

  function getTreasury() external view returns (address) {
    return _treasury;
  }

  function getMaxDepositAmount() external view returns (uint256) {
    return _maxDepositAmount;
  }

  function getMinimalDepositAmount() external view returns (uint256) {
    return _minDepositAmount;
  }

  function getMilestoneAmount() external view returns (uint256) {
    return _milestone.length;
  }

  function getCurrentMilestoneIndex() external view returns (uint256) {
    return _currentMilestone;
  }

  function getMilestoneInfo(uint256 index_) external view returns (Milestone memory) {
    return _milestone[index_];
  }

  function getTotalSoldTokens() external view returns (uint256) {
    return _totalSoldTokens;
  }

  function balanceOf(uint256 milestone_, address user_) external view returns (uint256) {
    return _milestoneBalances[user_][milestone_];
  }

  function representativeBalanceOf(address asset_, address user_) external view returns (uint256) {
    return _repBalances[user_][asset_];
  }

  function regularDepositLimit(address user_) public view returns (uint256) {
    uint256 amount = _userTotalBalances[user_];
    uint256 limit = _limit;
    if (isVerified(user_)) {
      limit = _maxDepositAmount;
    }
    return amount < limit ? limit - amount : 0;
  }

  function maxDepositLimit(address user_) public view returns (uint256) {
    uint256 amount = _userTotalBalances[user_];
    return amount < _maxDepositAmount ? _maxDepositAmount - amount : 0;
  }

  function getLimit() external view returns (uint256) {
    return _limit;
  }

  function getRepresentativeRates() external view returns (uint256, uint256) {
    return (_cRepRate, _tRepRate);
  }

  function getRepresentative(address user_, address rep_) public view returns (address) {
    Representative memory rep = _reps[_repsUsers[user_]];
    if (rep.defined && rep.enabled) {
      return _repsUsers[user_];
    }
    rep = _reps[rep_];
    if (!rep.defined || rep.enabled) {
      return rep_;
    }
    return address(0);
  }

  function getRepresentativeRate(address rep_) public view returns (uint256, uint256) {
    Representative memory rep = _reps[rep_];
    if (rep.defined) {
      return (Math.max(rep.firstRepRate, _cRepRate), Math.max(rep.secondRepRate, _tRepRate));
    }
    return (_cRepRate, _tRepRate);
  }

  function isSaleActive() public view returns (bool) {
    return _saleStatus == Status.Opened;
  }

  function isSaleInactive() public view returns (bool) {
    return _saleStatus == Status.Closed;
  }

  function getCurrentMilestonePrice(Option option_) public view returns (uint256) {
    if (_milestone[_currentMilestone].state == Status.Opened) {
      return
        option_ == Option.Short ? _milestone[_currentMilestone].sPrice : _milestone[_currentMilestone].lPrice;
    }
    return 0;
  }

  function isVerified(address user_) public view returns (bool) {
    return _verified[user_];
  }

  function open() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_saleStatus == Status.None, "TokenStore: sale already started");

    _saleStatus = Status.Opened;
  }

  function close() external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(isSaleActive(), "TokenStore: sale not started");

    _saleStatus = Status.Closed;
  }

  function toggleAllowedTokens(address[] calldata tokens, bytes32[] calldata pythIds, bool[] calldata statuses) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tokens.length == pythIds.length || tokens.length == statuses.length, "TokenStore: arrays lengths not equals");

    for(uint256 i; i < tokens.length; i++) {
      _tokenConfig[tokens[i]] = TokenConfig({defined: statuses[i], pythId: pythIds[i], total:0 });
    }
  }

  function getAllowedToken(address token_) external view returns(TokenConfig memory) {
    return _tokenConfig[token_];
  }

  function setMilestone(
    uint256 sPrice_,
    uint256 lPrice_,
    uint256 supply_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSaleInactive(), "TokenStore: sale closed");

    _milestone.push(
      Milestone({
        defined: true,
        state: Status.None,
        sPrice: sPrice_,
        lPrice: lPrice_,
        sold: 0,
        supply: supply_
      })
    );
  }

  function setRepresentativeRate(
    uint256 firstRepRate_,
    uint256 secondRepRate_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSaleInactive(), "TokenStore: sale closed");
    require(firstRepRate_ <= 1000, "TokenStore: cant set first rate more then 100%");
    require(secondRepRate_ <= 1000, "TokenStore: cant set second rate more then 100%");

    _cRepRate = firstRepRate_;
    _tRepRate = secondRepRate_;
  }

  function setupRepresentatives(
    address[] calldata reps_,
    uint256[] calldata firstRepRates_,
    uint256[] calldata secondRepRates_
  ) external onlyRole(MANAGER_ROLE) {
    require(!isSaleInactive(), "TokenStore: sale closed");
    require(
      reps_.length == firstRepRates_.length && reps_.length == secondRepRates_.length,
      "TokenStore: invalid arrays length setup"
    );

    for (uint256 index = 0; index < reps_.length; index++) {
      _reps[reps_[index]] = Representative({
        defined: true,
        enabled: true,
        firstRepRate: firstRepRates_[index],
        secondRepRate: secondRepRates_[index]
      });
    }
  }

  function updateMilestonePrice(
    uint256 index_,
    uint256 sPrice_,
    uint256 lPrice_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSaleInactive(), "TokenStore: sale closed");
    require(_milestone[index_].defined, "TokenStore: Milestone should be defined");
    require(_milestone[index_].state == Status.None, "TokenStore: Milestone should not be started");

    _milestone[index_].sPrice = sPrice_;
    _milestone[index_].lPrice = lPrice_;
  }

  function updateMilestoneSupply(
    uint256 index_,
    uint256 supply_
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(!isSaleInactive(), "TokenStore: sale closed");
    require(_milestone[index_].defined, "TokenStore: Milestone should be defined");
    require(_milestone[index_].state != Status.Closed, "TokenStore: Milestone should not be closed");
    require(
      _milestone[index_].sold < supply_,
      "TokenStore: new supply must be bigger then sold tokens"
    );

    _milestone[index_].supply = supply_;
  }

  function start(uint256 index_) external onlyRole(MANAGER_ROLE) {
    require(isSaleActive(), "TokenStore: sale not active");
    require(_milestone[index_].defined, "TokenStore: Milestone should be defined");
    require(_milestone[index_].state == Status.None, "TokenStore: Milestone should not be used");

    if (_milestone[_currentMilestone].state == Status.Opened) {
      _milestone[_currentMilestone].state = Status.Closed;
    }
    _milestone[index_].state = Status.Opened;
    _currentMilestone = index_;
  }

  function finishMilestone(uint256 index_) external onlyRole(MANAGER_ROLE) {
    require(_milestone[index_].defined, "TokenStore: Milestone should be defined");
    require(_milestone[index_].state == Status.Opened, "TokenStore: Milestone should be active");

    _milestone[index_].state = Status.Closed;
  }

  function setVerified(address user_, bool value_) external onlyRole(MANAGER_ROLE) {
    _verified[user_] = value_;
  }

  function setVerifiedBatch(
    address[] calldata users_,
    bool[] calldata values_
  ) external onlyRole(MANAGER_ROLE) {
    require(users_.length == values_.length, "TokenStore: invalid arrays length setup");

    for (uint256 index = 0; index < users_.length; index++) {
      _verified[users_[index]] = values_[index];
    }
  }

  function setMaxDepositAmount(uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount_ <= 10000000000000000000000000, "TokenStore: value is too big");
    require(amount_ >= _minDepositAmount, "TokenStore: value is too small");

    _maxDepositAmount = amount_;
  }

  function setMinDepositAmount(uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount_ >= 100000000000000000, "TokenStore: value is too small");
    require(amount_ <= _maxDepositAmount, "TokenStore: value is too big");

    _minDepositAmount = amount_;
  }

  function setLimit(uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount_ >= _minDepositAmount && amount_ <= _maxDepositAmount, "TokenStore: invalid value");

    _limit = amount_;
  }

  function setTreasury(address treasury_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(treasury_ != address(0), "TokenStore: zero bank address");

    _treasury = treasury_;
  }

  function _processPayment(
    address user_,
    address asset_,
    uint256 amount_,
    uint256 sold_,
    address rep_,
    uint256 fReward_,
    uint256 sReward_
  ) private {
    _userTotalBalances[user_] = _userTotalBalances[user_] + amount_;
    _totalSoldTokens = _totalSoldTokens + sold_;
    _milestone[_currentMilestone].sold = _milestone[_currentMilestone].sold + sold_;
    _milestoneBalances[user_][_currentMilestone] = _milestoneBalances[user_][_currentMilestone] + sold_;

    if (rep_ != address(0)) {
      if (!_reps[rep_].defined) {
        _reps[rep_].defined = true;
        _reps[rep_].enabled = true;
      }
      _repBalances[rep_][asset_] += fReward_;
      _repBalances[rep_][tokenAddress] += sReward_;
      _repsUsers[user_] = rep_;
    }
  }

  function enableRepresentative(address rep_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_reps[rep_].defined, "TokenStore: Representative not defined");
    require(!_reps[rep_].enabled, "TokenStore: Representative already enabled");

    _reps[rep_].enabled = true;
  }

  function disableRepresentative(address rep_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_reps[rep_].defined, "TokenStore: Representative not defined");
    require(_reps[rep_].enabled, "TokenStore: Representative already disabled");

    _reps[rep_].enabled = false;
  }

  function claimRepresentativeRewards(address[] calldata assets_) external nonReentrant {
    address rep = _msgSender();

    require(assets_.length > 0, "TokenStore: no stables to process");
    require(_reps[rep].defined, "TokenStore: Representative not defined");
    require(_reps[rep].enabled, "TokenStore: Representative not enabled");

    for (uint256 i = 0; i < assets_.length; i++) {
      address token = assets_[i];
      uint256 balance = _repBalances[rep][token];
      if (balance == 0) {
        continue;
      }

      _repBalances[rep][token] = 0;
      if (token == ethAddress) {
        (bool success, ) = rep.call{value: balance}("");
        require(success, "TokenStore: native claim error");
      } else {
        IERC20(token).safeTransfer(rep, balance);
      }

      emit Claimed(rep, token, balance);
    }
  }

  function recoverNative() external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 balance = address(this).balance;
    _msgSender().call{value: balance}("");
  }

  function recoverErc20(address asset_, uint256 amount_) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20(asset_).safeTransfer(_msgSender(), amount_);
  }

  receive() external payable {}
  
  // coin seller
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function depositCollateral(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address representative_
  ) external nonReentrant {
    _deposit(asset_, amount_, option_, _msgSender(), representative_, false);
  }

  function depositCollateralFor(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address receiver_,
    address representative_
  ) external nonReentrant onlyRole(VERIFIED_ROLE) {
    _deposit(asset_, amount_, option_, receiver_, representative_, true);
  }

  function depositToken(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address representative_
  ) external nonReentrant {
    _depositToken(asset_, amount_, option_, _msgSender(), representative_, false);
  }

  function depositTokenFor(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address receiver_,
    address representative_
  ) external nonReentrant onlyRole(VERIFIED_ROLE) {
    _depositToken(asset_, amount_, option_, receiver_, representative_, true);
  }

  function isStableSupported(address asset_) external view returns (bool) {
    return _stables[asset_].defined;
  }

  function getDepositedByToken(address asset_) external view returns (uint256) {
    return _stables[asset_].total;
  }

  function _deposit(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address receiver_,
    address representative_,
    bool isVerified_
  ) internal whenNotPaused {
    require(receiver_ != address(0), "TokenStore: receiver is zero");
    require(receiver_ != representative_, "TokenStore: self-referring is disabled");
    require(amount_ > 0, "TokenStore: amount is zero");
    require(_stables[asset_].defined, "TokenStore: asset is not allowed");
    require(isSaleActive(), "TokenStore: sale is already closed");

    ITokenStore.Milestone memory milestone = _milestone[_currentMilestone];

    require(
      milestone.state == ITokenStore.Status.Opened,
      "TokenStore: milestone is not active"
    );
    require(
      milestone.supply >= milestone.sold + _getSold(asset_, amount_, option_),
      "TokenStore: milestone allocation exceed"
    );

    uint256 decimals = IERC20Metadata(asset_).decimals();
    uint256 funds = (amount_ * MULTIPLIER) / (10 ** decimals);

    uint256 limit = isVerified_
      ? maxDepositLimit(receiver_)
      : regularDepositLimit(receiver_);

    require(
      funds >= _minDepositAmount,
      "TokenStore: deposit amount is too small"
    );
    require(funds <= limit, "TokenStore: deposit amount is too big");

    (address rep, uint256 fTokenFunds, uint256 sTokenFunds) = _getRepresentative(
      receiver_,
      asset_,
      representative_,
      option_,
      amount_
    );
    _process(_msgSender(), asset_, amount_, fTokenFunds);

    _stables[asset_].total = _stables[asset_].total + amount_;
    uint256 sold = _getSold(asset_, amount_, option_);
    uint256 investment = (amount_ * MULTIPLIER) / (10 ** decimals);
    _processPayment(
      receiver_,
      asset_,
      investment,
      sold,
      representative_,
      fTokenFunds,
      sTokenFunds
    );

    emit DepositedToken(
      receiver_,
      asset_,
      rep,
      amount_,
      option_,
      sold,
      _currentMilestone
    );
  }

  function _depositToken(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_,
    address receiver_,
    address representative_,
    bool isVerified_
  ) internal whenNotPaused {
    require(receiver_ != address(0), "TokenStore: receiver is zero");
    require(receiver_ != representative_, "TokenStore: self-referring is disabled");
    require(amount_ > 0, "TokenStore: amount is zero");
    require(_tokenConfig[asset_].defined, "TokenStore: token is not configured");
    require(isSaleActive(), "TokenStore: sale is already closed");

    ITokenStore.Milestone memory milestone = _milestone[_currentMilestone];

    require(
      milestone.state == ITokenStore.Status.Opened,
      "TokenStore: milestone is not active"
    );
    require(
      milestone.supply >= milestone.sold + _getSoldTokens(asset_, amount_, option_),
      "TokenStore: milestone allocation exceed"
    );


    PythStructs.Price memory priceInfo = _pyth.getPrice(_pythNativePriceFeedId);
    uint256 price = uint256(uint64(priceInfo.price));

    uint256 tokenDecimals = IERC20Metadata(asset_).decimals();
    uint8 priceDecimals = uint8(uint32(-1 * priceInfo.expo));

    uint256 funds = (amount_ * price * MULTIPLIER) / (10 ** (priceDecimals + tokenDecimals));

    uint256 limit = isVerified_
      ? maxDepositLimit(receiver_)
      : regularDepositLimit(receiver_);

    require(
      funds >= _minDepositAmount,
      "TokenStore: deposit amount is too small"
    );
    require(funds <= limit, "TokenStore: deposit amount is too big");

    (address rep, uint256 fTokenFunds, uint256 sTokenFunds) = _getRepresentativeToken(
      receiver_,
      asset_,
      representative_,
      option_,
      amount_
    );
    _process(_msgSender(), asset_, amount_, fTokenFunds);

    _tokenConfig[asset_].total += amount_;
    uint256 sold = _getSoldTokens(asset_, amount_, option_);

    _processPayment(
      receiver_,
      asset_,
      funds,
      sold,
      representative_,
      fTokenFunds,
      sTokenFunds
    );

    emit DepositedToken(
      receiver_,
      asset_,
      rep,
      amount_,
      option_,
      sold,
      _currentMilestone
    );
  }

  function _process(address receiver_, address asset_, uint256 amount_, uint256 reward_) internal {
    address treasury = _treasury;
    IERC20(asset_).safeTransferFrom(receiver_, treasury, amount_ - reward_);
    if (reward_ > 0) {
      IERC20(asset_).safeTransferFrom(receiver_, address(this), reward_);
    }
  }

  function _getRepresentative(
    address receiver_,
    address asset_,
    address representative_,
    ITokenStore.Option option_,
    uint256 amount_
  ) internal view returns (address, uint256, uint256) {
    address representative = getRepresentative(receiver_, representative_);
    if (representative == address(0)) {
      return (representative, 0, 0);
    }
    (uint256 fReward_, uint256 secondaryReward_) = getRepresentativeRate(representative);
    uint256 fTokenFunds = (amount_ * fReward_) / 1000;
    uint256 sTokenFunds = (amount_ * secondaryReward_) / 1000;
    uint256 sTokenSold = _getSold(asset_, sTokenFunds, option_);

    return (representative, fTokenFunds, sTokenSold);
  }


  function _getRepresentativeToken(
    address receiver_,
    address asset_,
    address representative_,
    ITokenStore.Option option_,
    uint256 amount_
  ) internal view returns (address, uint256, uint256) {
    address representative = getRepresentative(receiver_, representative_);
    if (representative == address(0)) {
      return (representative, 0, 0);
    }
    (uint256 fReward_, uint256 secondaryReward_) = getRepresentativeRate(representative);
    uint256 fTokenFunds = (amount_ * fReward_) / 1000;
    uint256 sTokenFunds = (amount_ * secondaryReward_) / 1000;
    uint256 sTokenSold = _getSoldTokens(asset_, sTokenFunds, option_);

    return (representative, fTokenFunds, sTokenSold);
  }

  function _getSold(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_
  ) internal view returns (uint256) {
    uint8 decimals = IERC20Metadata(asset_).decimals();
    return
      ((amount_ * 10 ** precision * MULTIPLIER) / 10 ** decimals) /
      getCurrentMilestonePrice(option_);
  }

  function _getSoldTokens(
    address asset_,
    uint256 amount_,
    ITokenStore.Option option_
  ) internal view returns (uint256) {
    PythStructs.Price memory priceInfo = _pyth.getPrice(_tokenConfig[asset_].pythId);
    uint256 price = uint256(uint64(priceInfo.price));
    uint8 priceDecimals = uint8(uint32(-1 * priceInfo.expo));

    return (amount_ * price * MULTIPLIER) / getCurrentMilestonePrice(option_) / (10 ** priceDecimals);
  }

  function depositNative(
    ITokenStore.Option option_,
    address representative_
  ) external payable nonReentrant {
    _deposit(option_, _msgSender(), representative_, false);
  }

  function depositNativeFor(
    ITokenStore.Option option_,
    address receiver_,
    address representative_
  ) external payable onlyRole(VERIFIED_ROLE) nonReentrant {
    _deposit(option_, receiver_, representative_, true);
  }

  function getTotalDepositAmount() external view returns (uint256) {
    return _totalDepositAmount;
  }

  function _deposit(
    ITokenStore.Option option_,
    address receiver_,
    address representative_,
    bool isVerified_
  ) internal whenNotPaused {
    uint256 amount = msg.value;

    require(receiver_ != address(0), "TokenStore: receiver is zero");
    require(receiver_ != representative_, "TokenStore: self-referring is disabled");
    require(amount > 0, "TokenStore: amount is zero");
    require(isSaleActive(), "TokenStore: sale is already closed");

    ITokenStore.Milestone memory milestone = _milestone[_currentMilestone];

    require(
      milestone.state == ITokenStore.Status.Opened,
      "TokenStore: milestone is not active"
    );
    require(
      milestone.supply >= milestone.sold + _getSold(amount, option_),
      "TokenStore: milestone allocation exceed"
    );

    PythStructs.Price memory priceInfo = _pyth.getPrice(_pythNativePriceFeedId);
    uint8 decimals = uint8(uint32(-1 * priceInfo.expo));
    uint256 price = uint256(uint64(priceInfo.price));

    uint256 funds = (amount * price * MULTIPLIER) / (10 ** (precision + decimals));
    uint256 limit = isVerified_
      ? maxDepositLimit(receiver_)
      : regularDepositLimit(receiver_);

    require(
      funds >= _minDepositAmount,
      "TokenStore: deposit amount is too small"
    );
    require(funds <= limit, "TokenStore: deposit amount is too big");

    (address representative, uint256 coinFunds, uint256 tokenFunds) = _getRepresentative(
      receiver_,
      representative_,
      option_,
      amount
    );
    _process(amount, coinFunds);

    _totalDepositAmount = _totalDepositAmount + amount;
    uint256 sold = _getSold(amount, option_);
    uint256 investment = (amount * price * MULTIPLIER) / (10 ** (precision + decimals));
    _processPayment(
      receiver_,
      ethAddress,
      investment,
      sold,
      representative,
      coinFunds,
      tokenFunds
    );

    emit DepositedNative(
      receiver_,
      representative,
      amount,
      option_,
      sold,
      _currentMilestone
    );
  }

  function _process(uint256 amount_, uint256 reward_) internal {
    address treasury = _treasury;
    (bool success, ) = treasury.call{value: amount_ - reward_}("");
    require(success, "TokenStore: transfer is not processed");
  }

  function _getRepresentative(
    address receiver_,
    address representative_,
    ITokenStore.Option option_,
    uint256 amount_
  ) internal view returns (address, uint256, uint256) {
    address representative = getRepresentative(receiver_, representative_);
    if (representative == address(0)) {
      return (representative, 0, 0);
    }
    (uint256 fRate, uint256 sRate) = getRepresentativeRate(representative);
    uint256 coinFunds = (amount_ * fRate) / 1000;
    uint256 tokenFunds = (amount_ * sRate) / 1000;
    uint256 tokenSold = _getSold(tokenFunds, option_);

    return (representative, coinFunds, tokenSold);
  }

  function _getSold(
    uint256 amount_,
    ITokenStore.Option option_
  ) internal view returns (uint256) {
    PythStructs.Price memory priceInfo = _pyth.getPrice(_pythNativePriceFeedId);
    uint8 decimals = uint8(uint32(-1 * priceInfo.expo));
    uint256 price = uint256(uint64(priceInfo.price));

    return
      (amount_ * price * MULTIPLIER) / getCurrentMilestonePrice(option_) / (10 ** decimals);
  }
}