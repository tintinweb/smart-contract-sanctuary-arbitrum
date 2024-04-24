// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/AccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControlEnumerable} from "./IAccessControlEnumerable.sol";
import {AccessControl} from "../AccessControl.sol";
import {EnumerableSet} from "../../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 role => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {AccessControl-_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override returns (bool) {
        bool granted = super._grantRole(role, account);
        if (granted) {
            _roleMembers[role].add(account);
        }
        return granted;
    }

    /**
     * @dev Overload {AccessControl-_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override returns (bool) {
        bool revoked = super._revokeRole(role, account);
        if (revoked) {
            _roleMembers[role].remove(account);
        }
        return revoked;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/extensions/IAccessControlEnumerable.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "../IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IDiceGame {
    enum Position {
        Low,
        High
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed;
    }

    struct DiceResult {
        uint256 rollAt;
        uint256 totalScore;
        uint256[] dices;
    }

    struct Round {
        uint256 epoch;
        uint256 startAt;
        uint256 lockAt;
        uint256 closeAt;
        uint256 roundId;
        uint256 totalAmount;
        uint256 lowAmount;
        uint256 numBetLow;
        uint256 highAmount;
        uint256 numBetHigh;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool requestedPriceFeed;
        DiceResult diceResult;
    }

    event BetLow(address indexed account, uint256 indexed epoch, uint256 amount);
    event BetHigh(address indexed account, uint256 indexed epoch, uint256 amount);
    event Claim(address indexed account, uint256 indexed epoch, uint256 amount);

    event StartRound(uint256 indexed epoch);
    event LockRound(uint256 indexed epoch);
    event EndRound(uint256 indexed epoch, uint256 indexed roundId, uint256 totalScore);

    event Pause(uint256 indexed epoch);
    event Unpause(uint256 indexed epoch);

    event RewardsCalculated(
        uint256 indexed epoch,
        uint256 rewardBaseCalAmount,
        uint256 rewardAmount,
        uint256 treasuryAmount,
        uint256 networkAmount
    );

    event TokenRecovery(address indexed token, uint256 amount);

    event NewOracle(address indexed oracle);
    event NewTreasury(address indexed treasury);
    event NewOracleUpdateAllowance(uint256 oracleUpdateAllowance);
    event NewProtocolFee(uint256 indexed epoch, uint256 protocolFee);
    event NewTreasuryFee(uint256 indexed epoch, uint256 treasuryFee);
    event NewMinBetAmount(uint256 indexed epoch, uint256 minBetAmount);
    event NewBufferAndIntervalSeconds(uint256 bufferSeconds, uint256 intervalSeconds);
    event NewAvailableRewardAmount(uint256 indexed epoch, uint256 amount);
    event NewRequireNFTAmount(uint256 indexed epoch, uint256 amount);
    event NewLimitProtocolAmount(uint256 indexed epoch, uint256 amount);
    event NewLimitTreasuryAmount(uint256 indexed epoch, uint256 amount);

    /**
     * @dev Error indicating that the function call is not allowed from a proxy contract.
     */
    error DiceGame__ProxyUnallowed();

    /**
     * @dev Error indicating that the round is not currently open for betting.
     */
    error DiceGame__RoundNotBettable();

    /**
     * @dev Error indicating that the amount bet is too low.
     */
    error DiceGame__BetAmountTooLow();

    /**
     * @dev Error indicating that the player has already placed a bet in the current round.
     */
    error DiceGame__AlreadyBet();

    /**
     * @dev Error indicating that the specified round has not yet started.
     * @param epoch Epoch number of the round.
     */
    error DiceGame__RoundNotStarted(uint256 epoch);

    /**
     * @dev Error indicating that the specified round has already ended.
     * @param epoch Epoch number of the round.
     */
    error DiceGame__RoundNotEnded(uint256 epoch);

    /**
     * @dev Error indicating that the player is not eligible to claim their winnings.
     */
    error DiceGame__NotEligibleForClaim();

    /**
     * @dev Error indicating that the player is not eligible for a refund.
     */
    error DiceGame__NotEligibleForRefund();

    /**
     * @dev Error indicating that the genesis start round has not been triggered yet.
     */
    error DiceGame__GenesisStartRoundNotTriggered();

    /**
     * @dev Error indicating that the genesis start round has already been triggered.
     */
    error DiceGame__GenesisStartRoundAlreadyTriggered();

    /**
     * @dev Error indicating that the genesis lock round has not been triggered.
     */
    error DiceGame__GenesisLockRoundNotTriggered();

    /**
     * @dev Error indicating that the genesis lock round has already been triggered.
     */
    error DiceGame__GenesisLockRoundAlreadyTriggered();

    /**
     * @dev Error indicating an attempt to recover tokens to an invalid address.
     */
    error DiceGame__InvalidRecoverToken();

    /**
     * @dev Error indicating that the round ended outside the buffer period.
     */
    error DiceGame__EndRoundOutsideBuffer();

    /**
     * @dev Error indicating that the round lock before the lock time period.
     */
    error DiceGame__LockRoundBeforeLockAt();

    /**
     * @dev Error indicating that the round locked outside the buffer period.
     */
    error DiceGame__LockRoundOutsideBuffer();

    /**
     * @dev Error indicating that rewards have already been calculated for the round.
     */
    error DiceGame__RewardsCalculated();

    /**
     * @dev Error indicating invalid buffer seconds.
     */
    error DiceGame__InvalidBufferSeconds();

    /**
     * @dev Error indicating a null address.
     */
    error DiceGame__NullAddress();

    /**
     * @dev Error indicating an invalid amount.
     * @param amount The invalid amount.
     */
    error DiceGame__InvalidAmount(uint256 amount);

    /**
     * @dev Error indicating that only NFT holders are allowed to perform the action.
     */
    error DiceGame__OnlyNFTHolder();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IERC20Burnable {
    function burn(uint256 value) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ITreasury {
    function gasFeeRelief() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibNativeTransfer} from "./LibNativeTransfer.sol";

type Currency is address;

using {eq as ==} for Currency global;
using LibCurrency for Currency global;

function eq(Currency self, Currency other) pure returns (bool) {
  return Currency.unwrap(self) == Currency.unwrap(other);
}

/**
 * @title LibCurrency
 * @dev A library for handling different currencies, including native (ETH) and ERC20 tokens.
 */
library LibCurrency {
  /**
   * @dev Emitted when native currency (ETH) is refunded.
   * @param to The address to which the refund is made.
   * @param amount The amount of native currency refunded.
   */
  event Refunded(address indexed to, uint256 amount);

  /**
   * @dev Error thrown when attempting to transfer zero amount.
   * @param currency The currency for which the transfer is attempted.
   */
  error TransferZeroAmount(Currency currency);

  /**
   * @dev Error thrown when attempting to receive zero amount.
   * @param currency The currency for which the receive is attempted.
   */
  error ReceiveZeroAmount(Currency currency);

  /**
   * @dev Error thrown when attempting to transfer insufficient amount.
   * @param currency The currency for which the transfer is attempted.
   */
  error InsufficientAmount(Currency currency);

  /**
   * @dev Error thrown when attempting to receive from an invalid address.
   * @param receiveFrom The address from which the receive is attempted.
   */
  error InvalidReceiveFrom(address receiveFrom);

  using SafeERC20 for IERC20Metadata;
  using LibNativeTransfer for address;

  // Constants
  uint8 private constant NATIVE_DECIMAL = 18;
  Currency internal constant NATIVE = Currency.wrap(address(0x0));

  /**
   * @dev Checks if a given currency is the native currency (ETH).
   * @param currency The currency to check.
   * @return True if the currency is native, false otherwise.
   */
  function isNative(Currency currency) internal pure returns (bool) {
    return currency == NATIVE;
  }

  /**
   * @dev Returns the unique key representing the currency.
   * @param currency The currency to get the key for.
   * @return The key for the currency.
   */
  function key(Currency currency) internal pure returns (uint256) {
    return uint160(Currency.unwrap(currency));
  }

  /**
   * @dev Returns the decimal precision of a given currency.
   * @param currency The currency to get the decimal precision for.
   * @return The decimal precision of the currency.
   */
  function decimal(Currency currency) internal view returns (uint8) {
    if (isNative(currency)) {
      return NATIVE_DECIMAL;
    } else {
      return IERC20Metadata(Currency.unwrap(currency)).decimals();
    }
  }

  /**
   * @dev Returns the balance of the current contract in a given currency.
   * @param currency The currency to check the balance for.
   * @return The balance of the current contract in the specified currency.
   */
  function selfBalance(Currency currency) internal view returns (uint256) {
    address self = address(this);
    if (isNative(currency)) {
      return self.balance;
    } else {
      return IERC20Metadata(Currency.unwrap(currency)).balanceOf(self);
    }
  }

  /**
   * @dev Transfers a given amount of a currency to a specified address.
   * @param currency The currency to transfer.
   * @param to The address to which the transfer is made.
   * @param amount The amount to transfer.
   */
  function transfer(Currency currency, address to, uint256 amount) internal {
    if (amount == 0) revert TransferZeroAmount(currency);
    if (isNative(currency)) {
      to.transfer(amount, gasleft());
    } else {
      IERC20Metadata(Currency.unwrap(currency)).safeTransfer(to, amount);
    }
  }

  /**
   * @dev Receives a given amount of a currency from a specified address.
   * @param currency The currency to receive.
   * @param from The address from which the receive is made.
   * @param amount The amount to receive.
   */
  function receiveFrom(Currency currency, address from, uint256 amount) internal {
    if (amount == 0) revert ReceiveZeroAmount(currency);
    if (isNative(currency)) {
      if (from != msg.sender) revert InvalidReceiveFrom(from);
      if (msg.value < amount) revert InsufficientAmount(NATIVE);

      uint256 refund = msg.value - amount;
      if (refund != 0) {
        from.transfer(refund, gasleft());
        emit Refunded(from, refund);
      }
    } else {
      IERC20Metadata(Currency.unwrap(currency)).transferFrom(from, address(this), amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library LibErrorHandler {
    /// @dev Reserves error definition to upload to signature database.
    error ExternalCallFailed(bytes4 msgSig, bytes4 callSig);

    /// @notice handle low level call revert if call failed,
    /// If extcall return empty bytes, reverts with custom error.
    /// @param status Status of external call
    /// @param callSig function signature of the calldata
    /// @param returnOrRevertData bytes result from external call
    function handleRevert(bool status, bytes4 callSig, bytes memory returnOrRevertData) internal pure {
        // Get the function signature of current context
        bytes4 msgSig = msg.sig;
        assembly ("memory-safe") {
            if iszero(status) {
                // Load the length of bytes array
                let revertLength := mload(returnOrRevertData)
                // Check if length != 0 => revert following reason from external call
                if iszero(iszero(revertLength)) {
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    revert(add(returnOrRevertData, 0x20), revertLength)
                }

                // Load free memory pointer
                let ptr := mload(0x40)
                // Store 4 bytes the function selector of ExternalCallFailed(msg.sig, callSig)
                // Equivalent to revert ExternalCallFailed(bytes4,bytes4)
                mstore(ptr, 0x49bf4104)
                // Store 4 bytes of msgSig parameter in the next slot
                mstore(add(ptr, 0x20), msgSig)
                // Store 4 bytes of callSig parameter in the next slot
                mstore(add(ptr, 0x40), callSig)
                // Revert 68 bytes of error starting from 0x1c
                revert(add(ptr, 0x1c), 0x44)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { LibErrorHandler } from "./LibErrorHandler.sol";

/**
 * @title NativeTransferHelper
 */
library LibNativeTransfer {
    using LibErrorHandler for bool;

    /**
     * @dev Transfers Native Coin and wraps result for the method caller to a recipient.
     */
    function transfer(address to, uint256 value, uint256 gasAmount) internal {
        (bool success, bytes memory returnOrRevertData) = trySendValue(to, value, gasAmount);
        success.handleRevert(bytes4(0x0), returnOrRevertData);
    }

    /**
     * @dev Unsafe send `amount` Native to the address `to`. If the sender's balance is insufficient,
     * the call does not revert.
     *
     * Note:
     * - Does not assert whether the balance of sender is sufficient.
     * - Does not assert whether the recipient accepts NATIVE.
     * - Consider using `ReentrancyGuard` before calling this function.
     *
     */
    function trySendValue(
        address to,
        uint256 value,
        uint256 gasAmount
    ) internal returns (bool success, bytes memory returnOrRevertData) {
        (success, returnOrRevertData) = to.call{ value: value, gas: gasAmount }("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

library LibRoles {
    bytes32 public constant SIGNER_ROLE = 0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    bytes32 public constant TREASURER_ROLE = 0x3496e2e73c4d42b75d702e60d9e48102720b8691234415963a5a857b86425d07;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20Burnable } from "./interfaces/IERC20Burnable.sol";
import { IDiceGame } from "./interfaces/IDiceGame.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";

import { Currency } from "./libraries/LibCurrency.sol";
import { LibRoles as Roles } from "./libraries/LibRoles.sol";

contract PampdaDiceGame is IDiceGame, Pausable, ReentrancyGuard, AccessControlEnumerable {
    Currency public currency;
    address public nftAddress;
    address public treasury;
    AggregatorV3Interface public oracle;

    bool public genesisLockOnce;
    bool public genesisStartOnce;

    uint256 public bufferSeconds;
    uint256 public intervalSeconds;

    uint256 public minBetAmount;
    uint256 public limitProtocolAmount;
    uint256 public limitTreasuryAmount;

    uint256 public treasuryFee;
    uint256 public treasuryAmount;

    uint256 public protocolFee;
    uint256 public protocolAmount;

    uint256 public currentEpoch;
    uint256 public oracleLatestRoundId;

    uint256 public requireAmount;
    uint256 public availableRewardAmount;

    uint256 public constant MAX_PERCENTAGE = 10_000; // 100%

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    mapping(uint256 => Round) public rounds;
    mapping(address => uint256[]) public userRounds;

    constructor(
        Currency currency_,
        address nftAddress_,
        address oracleAddress_,
        address treasury_,
        address adminAddress_,
        address operator_
    ) {
        protocolFee = 200;
        treasuryFee = 1800;
        requireAmount = 1;
        bufferSeconds = 180;
        intervalSeconds = 180;
        minBetAmount = 5_000 ether;
        limitProtocolAmount = 5_000_000 ether;
        limitTreasuryAmount = 100_000_000 ether;
        availableRewardAmount = 375_000 ether;

        currency = currency_;
        treasury = treasury_;
        nftAddress = nftAddress_;
        oracle = AggregatorV3Interface(oracleAddress_);

        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress_);
        _grantRole(Roles.TREASURER_ROLE, adminAddress_);
        _grantRole(Roles.OPERATOR_ROLE, operator_);
    }

    /**
     * @dev Modifier to allow only externally-owned accounts (EOAs) to call the function.
     * Reverts if the sender is a contract or not the transaction originator.
     */
    modifier onlyEOA() {
        address sender = _msgSender();
        if (_isContract(sender) || sender != tx.origin) {
            revert DiceGame__ProxyUnallowed();
        }
        _;
    }

    /**
     * @dev Modifier to allow only the NFT holder to call the function.
     * Reverts if the sender's balance of the specified NFT contract is less than the required amount.
     */
    modifier onlyNFTHolder() {
        address sender = _msgSender();
        if (IERC721(nftAddress).balanceOf(sender) < requireAmount) {
            revert DiceGame__OnlyNFTHolder();
        }
        _;
    }

    /**
     * @dev Retrieves information about the rounds participated in by the specified user.
     * @param user The address of the user for whom to retrieve round information.
     * @param cursor The cursor indicating the starting index of the rounds to retrieve.
     * @param size The number of rounds to retrieve from the cursor position.
     * @return An array of round IDs, an array of corresponding BetInfo structs, and the updated cursor position.
     */
    function getUserRounds(
        address user,
        uint256 cursor,
        uint256 size
    ) external view returns (uint256[] memory, BetInfo[] memory, uint256) {
        uint256 length = size;

        if (length > userRounds[user].length - cursor) {
            length = userRounds[user].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        BetInfo[] memory betInfo = new BetInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = userRounds[user][cursor + i];
            betInfo[i] = ledger[values[i]][user];
        }

        return (values, betInfo, cursor + length);
    }

    /**
     * @dev Retrieves the number of rounds in which the specified user has participated.
     * @param user The address of the user for whom to retrieve the number of rounds.
     * @return The number of rounds in which the user has participated.
     */
    function getUserRoundsLength(address user) external view returns (uint256) {
        return userRounds[user].length;
    }

    /**
     * @dev Checks if the specified user is eligible to claim rewards for the specified epoch.
     * @param epoch_ The epoch number for which to check claim eligibility.
     * @param user_ The address of the user for whom to check claim eligibility.
     * @return A boolean indicating whether the user is eligible to claim rewards for the specified epoch.
     */
    function claimable(uint256 epoch_, address user_) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch_][user_];
        Round memory round = rounds[epoch_];

        return (round.requestedPriceFeed &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((betInfo.position == Position.Low && _isLow(round.diceResult.totalScore)) ||
                (betInfo.position == Position.High && _isHigh(round.diceResult.totalScore))));
    }

    /**
     * @dev Checks if the specified user is eligible for a refund for the specified epoch.
     * @param epoch_ The epoch number for which to check refund eligibility.
     * @param user_ The address of the user for whom to check refund eligibility.
     * @return A boolean indicating whether the user is eligible for a refund for the specified epoch.
     */
    function refundable(uint256 epoch_, address user_) public view returns (bool) {
        BetInfo memory betInfo = ledger[epoch_][user_];
        Round memory round = rounds[epoch_];

        return (!round.requestedPriceFeed &&
            !betInfo.claimed &&
            block.timestamp > round.closeAt + bufferSeconds &&
            betInfo.amount != 0);
    }

    /**
     * @dev Allows the specified user to place a low bet for the specified epoch.
     * @param epoch_ The epoch number for which the user wants to place the bet.
     * @param amount_ The amount of the bet.
     */
    function betLow(uint256 epoch_, uint256 amount_) external whenNotPaused nonReentrant onlyEOA onlyNFTHolder {
        uint256 epoch = epoch_;
        uint256 amount = amount_;
        address sender = _msgSender();

        if (epoch != currentEpoch || !_bettable(epoch)) {
            revert DiceGame__RoundNotBettable();
        }
        if (amount < minBetAmount) {
            revert DiceGame__BetAmountTooLow();
        }
        if (ledger[epoch][sender].amount != 0) {
            revert DiceGame__AlreadyBet();
        }

        currency.receiveFrom(sender, amount);
        // Update round data
        Round storage round = rounds[epoch];
        round.totalAmount += amount;
        round.lowAmount += amount;
        round.numBetLow += 1;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][sender];
        betInfo.position = Position.Low;
        betInfo.amount = amount;
        userRounds[sender].push(epoch);

        emit BetLow(sender, epoch, amount);
    }

    /**
     * @dev Allows the specified user to place a high bet for the specified epoch.
     * @param epoch_ The epoch number for which the user wants to place the bet.
     * @param amount_ The amount of the bet.
     */
    function betHigh(uint256 epoch_, uint256 amount_) external whenNotPaused nonReentrant onlyEOA onlyNFTHolder {
        uint256 epoch = epoch_;
        uint256 amount = amount_;
        address sender = _msgSender();

        if (epoch != currentEpoch || !_bettable(epoch)) {
            revert DiceGame__RoundNotBettable();
        }
        if (amount < minBetAmount) {
            revert DiceGame__BetAmountTooLow();
        }
        if (ledger[epoch][sender].amount != 0) {
            revert DiceGame__AlreadyBet();
        }

        currency.receiveFrom(sender, amount);
        // Update round data
        Round storage round = rounds[epoch];
        round.totalAmount += amount;
        round.highAmount += amount;
        round.numBetHigh += 1;

        // Update user data
        BetInfo storage betInfo = ledger[epoch][sender];
        betInfo.position = Position.High;
        betInfo.amount = amount;
        userRounds[sender].push(epoch);

        emit BetHigh(sender, epoch, amount);
    }

    /**
     * @dev Allows the caller to claim rewards for multiple epochs.
     * @param epochs_ An array of epoch numbers for which the caller wants to claim rewards.
     */
    function claim(uint256[] calldata epochs_) external nonReentrant onlyEOA {
        uint256 epoch;
        uint256 reward;
        address sender = _msgSender();

        for (uint256 i; i < epochs_.length; ++i) {
            epoch = epochs_[i];
            uint256 addedReward = 0;

            if (rounds[epoch].startAt == 0) {
                revert DiceGame__RoundNotStarted(epoch);
            }
            if (block.timestamp <= rounds[epoch].closeAt) {
                revert DiceGame__RoundNotEnded(epoch);
            }

            if (rounds[epoch].requestedPriceFeed) {
                if (!claimable(epoch, sender)) {
                    revert DiceGame__NotEligibleForClaim();
                }
                Round memory round = rounds[epoch];
                addedReward = (ledger[epoch][sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            } else {
                if (!refundable(epoch, sender)) {
                    revert DiceGame__NotEligibleForRefund();
                }
                addedReward = ledger[epoch][sender].amount;
            }

            ledger[epoch][sender].claimed = true;
            reward += addedReward;

            emit Claim(sender, epoch, addedReward);
        }

        if (reward > 0) {
            currency.transfer(_msgSender(), reward);
        }
    }

    /**
     * @dev Executes a round of the game.
     */
    function executeRound() public whenNotPaused onlyRole(Roles.OPERATOR_ROLE) {
        if (!genesisStartOnce) {
            revert DiceGame__GenesisStartRoundNotTriggered();
        }
        if (!genesisLockOnce) {
            revert DiceGame__GenesisLockRoundNotTriggered();
        }

        (uint80 currentRoundId, int256 price) = _getPriceFromOracle();
        oracleLatestRoundId = uint256(currentRoundId);

        _safeLockRound(currentEpoch);
        _safeEndRound(currentEpoch - 1, currentRoundId, price);
        _calculateRewards(currentEpoch - 1);
        _burnTreasury();
        _transferProtocol();

        unchecked {
            currentEpoch = currentEpoch + 1;
        }
        _safeStartRound(currentEpoch);
    }

    /**
     * @dev Triggers lock the genesis round of the game.
     */
    function genesisLockRound() external whenNotPaused onlyRole(Roles.OPERATOR_ROLE) {
        if (!genesisStartOnce) {
            revert DiceGame__GenesisStartRoundNotTriggered();
        }
        if (genesisLockOnce) {
            revert DiceGame__GenesisLockRoundAlreadyTriggered();
        }

        _safeLockRound(currentEpoch);
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisLockOnce = true;
    }

    /**
     * @dev Triggers the genesis round of the game.
     */
    function genesisStartRound() external whenNotPaused onlyRole(Roles.OPERATOR_ROLE) {
        if (genesisStartOnce) {
            revert DiceGame__GenesisStartRoundAlreadyTriggered();
        }
        currentEpoch = currentEpoch + 1;
        _startRound(currentEpoch);
        genesisStartOnce = true;
        genesisLockOnce = false;
    }

    /**
     * @dev Pauses the game functionality.
     */
    function pause() external whenNotPaused onlyRole(Roles.OPERATOR_ROLE) {
        _pause();
        emit Pause(currentEpoch);
    }

    /**
     * @dev Resumes the game functionality.
     */
    function unpause() external whenPaused onlyRole(Roles.OPERATOR_ROLE) {
        genesisStartOnce = false;
        _unpause();
        emit Unpause(currentEpoch);
    }

    /**
     * @dev Allows the treasurer to recover tokens accidentally sent to the contract.
     * @param currency_ The address of the token to be recovered.
     * @param amount_ The amount of tokens to be recovered.
     */
    function recoverToken(Currency currency_, uint256 amount_) external onlyRole(Roles.TREASURER_ROLE) {
        if (currency_ == currency) {
            revert DiceGame__InvalidRecoverToken();
        }
        currency_.transfer(_msgSender(), amount_);
        emit TokenRecovery(Currency.unwrap(currency_), amount_);
    }

    /**
     * @dev Sets the buffer and interval seconds for the game.
     * @param bufferSeconds_ The duration in seconds to wait before ending a round after the scheduled end time.
     * @param intervalSeconds_ The duration in seconds between the end of one round and the start of the next.
     */
    function setBufferAndIntervalSeconds(
        uint256 bufferSeconds_,
        uint256 intervalSeconds_
    ) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (bufferSeconds_ > intervalSeconds_) {
            revert DiceGame__InvalidBufferSeconds();
        }
        bufferSeconds = bufferSeconds_;
        intervalSeconds = intervalSeconds_;
        emit NewBufferAndIntervalSeconds(bufferSeconds, intervalSeconds);
    }

    /**
     * @dev Sets the required NFT amount for participation in the game.
     * @param requireAmount_ The minimum required NFT amount for participation.
     */
    function setRequireNFTAmount(uint256 requireAmount_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        requireAmount = requireAmount_;
        emit NewRequireNFTAmount(currentEpoch, requireAmount_);
    }

    /**
     * @dev Sets the available reward amount for distribution.
     * @param availableRewardAmount_ The total amount of rewards available for distribution.
     */
    function setAvailableRewardAmount(uint256 availableRewardAmount_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        availableRewardAmount = availableRewardAmount_;
        emit NewAvailableRewardAmount(currentEpoch, availableRewardAmount_);
    }

    /**
     * @dev Sets the minimum bet amount allowed.
     * @param minBetAmount_ The new minimum bet amount.
     */
    function setMinBetAmount(uint256 minBetAmount_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        minBetAmount = minBetAmount_;
        emit NewMinBetAmount(currentEpoch, minBetAmount);
    }

    /**
     * @dev Sets the limit protocol amount allowed to transfer to treasury.
     * @param limitAmount_ The new limit protocol amount.
     */
    function setLimitProtocol(uint256 limitAmount_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        limitProtocolAmount = limitAmount_;
        emit NewLimitProtocolAmount(currentEpoch, limitAmount_);
    }

    /**
     * @dev Sets the limit treasury amount allowed to burn.
     * @param limitAmount_ The new limit treasury amount.
     */
    function setLimitTreasury(uint256 limitAmount_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        limitTreasuryAmount = limitAmount_;
        emit NewLimitTreasuryAmount(currentEpoch, limitAmount_);
    }

    /**
     * @dev Sets the oracle address for fetching price data.
     * @param oracle_ The address of the new oracle contract.
     */
    function setOracle(address oracle_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (oracle_ == address(0)) {
            revert DiceGame__NullAddress();
        }
        oracleLatestRoundId = 0;
        oracle = AggregatorV3Interface(oracle_);
        oracle.latestRoundData();

        emit NewOracle(oracle_);
    }

    /**
     * @dev Sets the new treasury.
     * @param treasury_ The new treasury address.
     */
    function setTreasury(address treasury_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = treasury_;
        emit NewTreasury(treasury_);
    }

    /**
     * @dev Sets the treasury fee percentage.
     * @param treasuryFee_ The new treasury fee percentage.
     */
    function setTreasuryFee(uint256 treasuryFee_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (treasuryFee_ > MAX_PERCENTAGE) {
            revert DiceGame__InvalidAmount(treasuryFee_);
        }
        treasuryFee = treasuryFee_;
        emit NewTreasuryFee(currentEpoch, treasuryFee);
    }

    /**
     * @dev Sets the network fee percentage.
     * @param protocolFee_ The new network fee percentage.
     */
    function setProtocolFee(uint256 protocolFee_) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        if (protocolFee_ > MAX_PERCENTAGE) {
            revert DiceGame__InvalidAmount(protocolFee_);
        }
        protocolFee = protocolFee_;
        emit NewProtocolFee(currentEpoch, protocolFee);
    }

    /**
     * @dev Calculates and sets the rewards for the specified epoch.
     * @param epoch_ The epoch for which rewards are to be calculated.
     */
    function _calculateRewards(uint256 epoch_) internal {
        uint256 epoch = epoch_;
        if (rounds[epoch].rewardBaseCalAmount != 0 || rounds[epoch].rewardAmount != 0) {
            revert DiceGame__RewardsCalculated();
        }

        Round storage round = rounds[epoch];
        uint256 protocolAmt;
        uint256 treasuryAmt;
        uint256 rewardAmount;
        uint256 rewardBaseCalAmount;

        if (_isLow(round.diceResult.totalScore)) {
            rewardBaseCalAmount = round.lowAmount;
            treasuryAmt = ((round.totalAmount - round.lowAmount) * treasuryFee) / 10_000;
            protocolAmt = ((round.totalAmount - round.lowAmount) * protocolFee) / 10_000;
            rewardAmount = round.totalAmount - treasuryAmt - protocolAmt;
        } else if (_isHigh(round.diceResult.totalScore)) {
            rewardBaseCalAmount = round.highAmount;
            treasuryAmt = ((round.totalAmount - round.highAmount) * treasuryFee) / 10_000;
            protocolAmt = ((round.totalAmount - round.highAmount) * protocolFee) / 10_000;
            rewardAmount = round.totalAmount - treasuryAmt - protocolAmt;
        }

        protocolAmount += protocolAmt;
        treasuryAmount += treasuryAmt;
        round.rewardAmount = rewardAmount;
        round.rewardBaseCalAmount = rewardBaseCalAmount;

        emit RewardsCalculated(epoch, rewardBaseCalAmount, rewardAmount, treasuryAmt, protocolAmt);
    }

    /**
     * @dev Safely ends the current round by updating its data and emitting an event.
     * @param epoch_ The epoch of the round to end.
     * @param roundId_ The ID of the round to end.
     * @param price_ The price obtained from the oracle for the round.
     */
    function _safeEndRound(uint256 epoch_, uint256 roundId_, int256 price_) internal {
        uint256 epoch = epoch_;

        if (rounds[epoch].closeAt == 0) {
            revert DiceGame__RoundNotStarted(epoch);
        }
        if (block.timestamp < rounds[epoch].closeAt) {
            revert DiceGame__RoundNotEnded(epoch);
        }
        if (block.timestamp > rounds[epoch].closeAt + bufferSeconds) {
            revert DiceGame__EndRoundOutsideBuffer();
        }

        (uint256 totalScore, uint256[] memory dices) = _rollDices(epoch, roundId_, price_);

        Round storage round = rounds[epoch];

        round.roundId = roundId_;
        round.requestedPriceFeed = true;
        round.diceResult = DiceResult({ rollAt: block.timestamp, totalScore: totalScore, dices: dices });

        emit EndRound(epoch, roundId_, totalScore);
    }

    /**
     * @dev Safely locks the current round by updating its data and emitting an event.
     * @param epoch_ The epoch of the round to end.
     */
    function _safeLockRound(uint256 epoch_) internal {
        uint256 epoch = epoch_;

        if (rounds[epoch].startAt == 0) {
            revert DiceGame__RoundNotStarted(epoch);
        }
        if (block.timestamp < rounds[epoch].lockAt) {
            revert DiceGame__LockRoundBeforeLockAt();
        }
        if (block.timestamp > rounds[epoch].lockAt + bufferSeconds) {
            revert DiceGame__LockRoundOutsideBuffer();
        }

        Round storage round = rounds[epoch];
        round.closeAt = block.timestamp + intervalSeconds;

        emit LockRound(epoch);
    }

    /**
     * @dev Safely starts the next round if conditions are met.
     * @param epoch_ The epoch of the round to start.
     */
    function _safeStartRound(uint256 epoch_) internal {
        uint256 epoch = epoch_;

        if (!genesisStartOnce) {
            revert DiceGame__GenesisStartRoundNotTriggered();
        }
        if (rounds[epoch - 2].closeAt == 0) {
            revert DiceGame__RoundNotStarted(epoch - 2);
        }
        if (block.timestamp < rounds[epoch - 2].closeAt) {
            revert DiceGame__RoundNotEnded(epoch - 2);
        }

        _startRound(epoch);
    }

    /**
     * @dev Starts a new round.
     * @param epoch_ The epoch of the round to start.
     */
    function _startRound(uint256 epoch_) internal {
        uint256 epoch = epoch_;

        Round storage round = rounds[epoch];
        round.epoch = epoch;
        round.startAt = block.timestamp;
        round.lockAt = block.timestamp + intervalSeconds;
        round.closeAt = block.timestamp + (2 * intervalSeconds);
        round.totalAmount = availableRewardAmount;

        if (epoch >= 2) {
            Round storage previousRound = rounds[epoch - 1];
            Round storage prePreviousRound = rounds[epoch - 2];
            if (
                (prePreviousRound.highAmount == 0 && prePreviousRound.lowAmount == 0) ||
                (_isLow(prePreviousRound.diceResult.totalScore) && prePreviousRound.lowAmount == 0) ||
                (_isHigh(prePreviousRound.diceResult.totalScore) && prePreviousRound.highAmount == 0)
            ) {
                previousRound.totalAmount += prePreviousRound.rewardAmount;
            }
        }

        emit StartRound(epoch);
    }

    /**
     * @dev Checks if a round is currently bettable.
     * @param epoch_ The epoch of the round to check.
     * @return A boolean indicating whether the round is bettable or not.
     */
    function _bettable(uint256 epoch_) internal view returns (bool) {
        return (rounds[epoch_].startAt != 0 &&
            rounds[epoch_].closeAt != 0 &&
            block.timestamp > rounds[epoch_].startAt &&
            block.timestamp < rounds[epoch_].closeAt);
    }

    function _burnTreasury() internal {
        if (treasuryAmount >= limitTreasuryAmount) {
            IERC20Burnable(Currency.unwrap(currency)).burn(treasuryAmount);
            treasuryAmount = 0;
        }
    }

    function _transferProtocol() internal {
        if (protocolAmount >= limitProtocolAmount) {
            currency.transfer(treasury, protocolAmount);
            ITreasury(treasury).gasFeeRelief();
            protocolAmount = 0;
        }
    }

    /**
     * @dev Simulates rolling three dice for the DiceGame game.
     * @param epoch_ The epoch of the round.
     * @param roundId_ The ID of the round.
     * @param price_ The price obtained from the oracle.
     * @return totalScore The total score obtained from rolling the dice.
     * @return dices An array containing the values of the three rolled dice.
     */
    function _rollDices(
        uint256 epoch_,
        uint256 roundId_,
        int256 price_
    ) internal view returns (uint256 totalScore, uint256[] memory dices) {
        dices = new uint256[](3);
        Round storage round = rounds[epoch_];

        uint256 numOfPlayer = round.numBetLow + round.numBetHigh;
        uint256 avgBetAmount = numOfPlayer == 0 ? 0 : round.totalAmount / numOfPlayer;

        uint256 seed = uint256(
            keccak256(
                abi.encode(
                    roundId_,
                    price_,
                    avgBetAmount,
                    block.coinbase,
                    block.gaslimit,
                    block.timestamp,
                    blockhash(block.number - 1),
                    blockhash(block.number - 2),
                    blockhash(block.number)
                )
            )
        );

        for (uint256 i; i < dices.length; ) {
            uint256 dice = (uint256(keccak256(abi.encode(seed, i))) % 6) + 1;
            dices[i] = dice;
            unchecked {
                totalScore += dice;
                ++i;
            }
        }
    }

    /**
     * @dev Checks if the total score falls within the "Low" range in the DiceGame game.
     * @param totalScore_ The total score obtained from rolling the dice.
     * @return isLow A boolean indicating whether the total score is in the "Low" range.
     */
    function _isLow(uint256 totalScore_) internal pure returns (bool isLow) {
        if (totalScore_ > 2 && totalScore_ < 11) {
            isLow = true;
        } else {
            isLow = false;
        }
    }

    /**
     * @dev Checks if the total score falls within the "High" range in the DiceGame game.
     * @param totalScore_ The total score obtained from rolling the dice.
     * @return isHigh A boolean indicating whether the total score is in the "High" range.
     */
    function _isHigh(uint256 totalScore_) internal pure returns (bool isHigh) {
        if (totalScore_ > 10 && totalScore_ < 19) {
            isHigh = true;
        } else {
            isHigh = false;
        }
    }

    /**
     * @dev Retrieves the latest round ID and price data from the Oracle.
     * @return roundId The latest round ID from the Oracle.
     * @return price The latest price data from the Oracle.
     */
    function _getPriceFromOracle() internal view returns (uint80, int256) {
        (uint80 roundId, int256 price, , , ) = oracle.latestRoundData();
        return (roundId, price);
    }

    /**
     * @dev Checks if the given address is a contract.
     * @param account The address to check.
     * @return isContract True if the address is a contract, false otherwise.
     */
    function _isContract(address account) internal view returns (bool isContract) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        isContract = size > 0;
    }
}