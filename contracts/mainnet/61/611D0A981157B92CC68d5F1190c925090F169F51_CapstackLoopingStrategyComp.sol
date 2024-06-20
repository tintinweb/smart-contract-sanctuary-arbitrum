// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
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
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

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
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

import { ICErc20, ICToken } from "./interfaces/ICErc20.sol";
import { IComptroller } from "./interfaces/IComptroller.sol";
import { Aggregator } from "./common/Aggregator.sol";
import { Access } from "./common/Access.sol";

/**
 * @dev This strategy will deposit and leverage a token on compoundV2(fork) to maximize yield by farming reward tokens
 */
contract CapstackLoopingStrategyComp is Aggregator {
    using SafeERC20 for IERC20;

    /**
     * {PERCENT_DIVISOR} - 10000.
     * {COMPOUND_MANTISSA} - The unit used by the Compound protocol
     * {LTV_SAFETY_ZONE} - We will only go up to 98% of max allowed LTV for {targetLTV}
     */
    uint256 public constant PERCENT_DIVISOR = 10_000;
    uint256 public constant COMPOUND_MANTISSA = 1e18;
    uint256 public constant LTV_SAFETY_ZONE = 0.98 * 1e18;

    /**
     * @dev Third Party Contracts:
     * {want} - The vault token the strategy is maximizing
     * {cWant} - The Share of the want token market
     * {comptroller} - Contract to enter markets and to claim reward tokens
     * {rewards} - reward token array, Used to swap to want
     */
    address public want;
    ICErc20 public cWant;
    address public comptroller;
    address[] public rewards;

    /**
     * @dev Strategy variables
     * {targetLTV} - The target loan to value for the strategy where 1 ether = 100%
     * {allowedLTVDrift} - How much the strategy can deviate from the target ltv where 0.01 ether = 1%
     * {balanceOfPool} - The total balance deposited into Pool (supplied - borrowed)
     * {borrowDepth} - The maximum amount of loops used to leverage and deleverage
     * {minWantToLeverage} - The minimum amount of want to leverage in a loop
     * {ltvScaleOfSafeCollateralFactor} - Scale value of ltv for deleveraging check(function: shouldDeleverage). 1 PERCENT_DIVISOR == 100%
     * {principalScaleOfSafeLiquidity} - Scale value of principal ( the principal: balanceOf() ) for deleveraging check( liquidity > principal * principalScaleOfSafeLiquidity / PERCENT_DIVISOR). 1 PERCENT_DIVISOR == 100%
     * {principalScaleOfSafeSupply} - Scale value of principal ( the principal: balanceOf() ) for deleveraging check( totalSupply > principal * principalScaleOfSafeSupply / PERCENT_DIVISOR). 1 PERCENT_DIVISOR == 100%     */
    uint256 public targetLTV;
    uint256 public allowedLTVDrift = 0.01 * 1e18;
    uint256 public balanceOfPool;
    uint256 public borrowDepth = 12;
    uint256 public minWantToLeverage = 100;
    uint256 public maxBorrowDepth = 15;
    uint256 public ltvScaleOfSafeCollateralFactor = PERCENT_DIVISOR;
    uint256 public principalScaleOfSafeLiquidity = 2 * 10_000;
    uint256 public principalScaleOfSafeSupply = 5 * 10_000;

    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Harvest(
        address indexed caller,
        uint256 wantAmount,
        uint256 supply,
        uint256 borrow,
        uint256 newSupply,
        uint256 newBorrow,
        uint256 timestamp
    );
    event Claim(address indexed caller, uint256 rewardAmount);
    event SwapToken(address indexed caller, address indexed token, uint256 amount);
    event CurrentLtvChanged(address indexed caller, uint256 oldLtv, uint256 currentLtv);
    event TargetLtvChanged(address indexed caller, uint256 newLtv);
    event DriftChanged(address indexed caller, uint256 newDrift);
    event BorrowDepthChanged(address indexed caller, uint256 newBorrowDepth);
    event MinWantChanged(address indexed caller, uint256 newMinWant);
    event RewardChanged(address indexed caller, address[] newRewards);
    event LtvScaleOfSafeCollateralFactorChanged(address indexed caller, uint256 newScale);
    event PrincipalScaleOfSafeLiquidityChanged(address indexed caller, uint256 newScale);
    event PrincipalScaleOfSafeSupplyChanged(address indexed caller, uint256 newScale);
    event BorrowRateOffsetChanged(address indexed caller, int256 newOffset);

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     */
    constructor(
        address _admin,
        address[] memory _guardians,
        address[] memory _keepers,
        address[] memory _rewards,
        address _cWant,
        uint256 _targetLTV
    ) Access(_admin) Aggregator(_rewards) {
        uint256 length = _guardians.length;
        for (uint256 i = 0; i < length; ++i) {
            _grantRole(GUARDIAN_ROLE, _guardians[i]);
            _grantRole(KEEPER_ROLE, _guardians[i]);
        }
        length = _keepers.length;
        for (uint256 i = 0; i < length; ++i) {
            _grantRole(KEEPER_ROLE, _keepers[i]);
        }

        cWant = ICErc20(_cWant);
        comptroller = cWant.comptroller();
        want = cWant.underlying();
        targetLTV = _targetLTV;
        rewards = _rewards;
        // Enter markets and Approve token
        address[] memory markets = new address[](1);
        markets[0] = _cWant;
        IComptroller(comptroller).enterMarkets(markets);
        IERC20(want).approve(address(cWant), type(uint256).max);
    }

    /**
     * @dev Helper modifier for functions that need to update the internal balance at the end of their execution.
     */
    modifier doUpdateBalance() {
        _;
        updateBalance();
    }

    /**
     * @dev A helper function to call deposit() with all the sender's funds.
     */
    function depositAll() external {
        deposit(IERC20(want).balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public onlyRole(GUARDIAN_ROLE) whenNotPaused {
        require(_amount != 0, "please provide amount");
        IERC20(want).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit();
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Withdraws all funds and sents them back to the admin.
     */
    function withdrawAll() external onlyRole(ADMIN_ROLE) doUpdateBalance {
        updateBalance();
        uint256 cWantBalance = balanceOfcWant();
        if (cWantBalance > 1 && balanceOfPool > minWantToLeverage) {
            _deleverage(type(uint256).max);
            _withdrawUnderlying(balanceOfPool);
        }
        uint256 length = rewards.length;
        for (uint256 i = 0; i < length; ++i) {
            address _reward = rewards[0];
            uint256 bal = IERC20(_reward).balanceOf(address(this));
            IERC20(_reward).safeTransfer(msg.sender, bal);
        }

        uint256 wantBalance = balanceOfWant();
        if (wantBalance == 0) {
            return;
        }
        IERC20(want).safeTransfer(msg.sender, wantBalance);
        emit Withdrawal(msg.sender, wantBalance);
    }

    /**
     * @dev Withdraws funds and sents them back to the admin.
     * It withdraws {want} from Pool
     */
    function withdraw(uint256 _withdrawAmount) external onlyRole(ADMIN_ROLE) {
        require(balanceOf() > 0, "no want assets");
        uint256 wantBalance = balanceOfWant();
        if (_withdrawAmount <= wantBalance) {
            IERC20(want).safeTransfer(msg.sender, _withdrawAmount);
            emit Withdrawal(msg.sender, _withdrawAmount);
            return;
        }
        uint256 finalWithdrawAmount = _withdrawFromPool(_withdrawAmount);
        emit Withdrawal(msg.sender, finalWithdrawAmount);
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * @notice Assumes the deposit will take care of the TVL rebalancing.
     * 1. Call claim() function at first
     * 2. Swaps rewards for {want}
     * 3. Deposits.
     */
    function harvest(
        OneInchData[] calldata _data
    ) external onlyRole(KEEPER_ROLE) whenNotPaused returns (uint256 wantAmount) {
        (uint256 oldSupply, uint256 oldBorrow) = _getSupplyAndBorrow();
        uint256 initWantBal = balanceOfWant();
        uint256 length = _data.length;
        for (uint256 i = 0; i < length; ++i) {
            OneInchData calldata swapData = _data[i];
            uint256 tokenBal = IERC20(swapData.token).balanceOf(address(this));
            if (tokenBal > 0) {
                _1inchSwap(swapData.data);
                emit SwapToken(msg.sender, swapData.token, tokenBal);
            }
        }
        uint256 newWantBal = balanceOfWant();
        wantAmount = newWantBal - initWantBal;

        _deposit();
        (uint256 newSupply, uint256 newBorrow) = _getSupplyAndBorrow();
        emit Harvest(msg.sender, wantAmount, oldSupply, oldBorrow, newSupply, newBorrow, block.timestamp);
    }

    function swap(OneInchData[] calldata _data) external onlyRole(KEEPER_ROLE) whenNotPaused {
        uint256 length = _data.length;
        for (uint256 i = 0; i < length; ++i) {
            OneInchData calldata swapData = _data[i];
            uint256 tokenBal = IERC20(swapData.token).balanceOf(address(this));
            if (tokenBal > 0) {
                _1inchSwap(swapData.data);
                emit SwapToken(msg.sender, swapData.token, tokenBal);
            }
        }
    }

    /**
     * @dev Claim rewards without swapping
     */
    function claim() external onlyRole(KEEPER_ROLE) returns (uint256 rewardWantAmount) {
        rewardWantAmount = _claimRewards();
        emit Claim(msg.sender, rewardWantAmount);
    }

    /**
     * @dev Levers the strategy up to the targetLTV
     */
    function leverMax() external onlyRole(GUARDIAN_ROLE) doUpdateBalance {
        _leverMax();
    }

    /**
     * @dev For a given withdraw amount, delever to zero
     */
    function leverDownToZero() external {
        leverDown(type(uint256).max);
        targetLTV = 0;
        emit TargetLtvChanged(msg.sender, 0);
    }

    /**
     * @dev For a given withdraw amount, delever to a borrow level
     */
    function leverDown(uint256 _withdrawAmount) public onlyRole(GUARDIAN_ROLE) doUpdateBalance {
        _deleverage(_withdrawAmount);
        uint256 newLtv = _calculateLTV();
        targetLTV = newLtv;
        emit TargetLtvChanged(msg.sender, newLtv);
    }

    /**
     * @dev Withdraw ERC20 token to admin
     */
    function withdrawTokens(IERC20 token) external onlyRole(ADMIN_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev Emergency function to deleverage in case regular deleveraging breaks
     */
    function manualDeleverage(uint256 amount) external onlyRole(GUARDIAN_ROLE) doUpdateBalance {
        _redeem(amount);
        _repay(amount);
    }

    /**
     * @dev Emergency function to deleverage in case regular deleveraging breaks
     */
    function manualReleaseWant(uint256 amount) external onlyRole(ADMIN_ROLE) doUpdateBalance {
        _redeem(amount);
    }

    /**
     * @dev Withdraws all funds leaving rewards behind.
     *      Keeper and roles with higher privilege can panic.
     */
    function panic() external onlyRole(KEEPER_ROLE) doUpdateBalance {
        _deleverage(type(uint256).max);
        _withdrawUnderlying(balanceOfPool);
        _pause();
    }

    /**
     * @dev Pauses the strat. Deposits become disabled but users can still
     *      withdraw. Guardian and roles with higher privilege can pause.
     */
    function pause() external override onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the strat. Opens up deposits again and invokes deposit().
     *      Admin and roles with higher privilege can unpause.
     */
    function unpause() external override onlyRole(ADMIN_ROLE) {
        _unpause();
        _deposit();
    }

    /**
     * @dev Sets a new LTV for leveraging.
     * Should be in units of 1e18
     */
    function setTargetLtv(uint256 _ltv) external onlyRole(GUARDIAN_ROLE) {
        uint256 collateralFactorMantissa = _getCollateralFactor();
        require(collateralFactorMantissa > _ltv + allowedLTVDrift, "targetLtv is too high");
        require(_ltv <= (collateralFactorMantissa * LTV_SAFETY_ZONE) / COMPOUND_MANTISSA, "targetLtv is too high");
        targetLTV = _ltv;
        emit TargetLtvChanged(msg.sender, _ltv);
    }

    /**
     * @dev Sets a new allowed LTV drift
     * Should be in units of 1e18
     */
    function setAllowedLtvDrift(uint256 _drift) external onlyRole(GUARDIAN_ROLE) {
        uint256 collateralFactorMantissa = _getCollateralFactor();
        require(collateralFactorMantissa > targetLTV + _drift, "drift is too large");
        allowedLTVDrift = _drift;
        emit DriftChanged(msg.sender, _drift);
    }

    /**
     * @dev Sets a new borrow depth (how many loops for leveraging+deleveraging)
     */
    function setBorrowDepth(uint8 _borrowDepth) external onlyRole(GUARDIAN_ROLE) {
        require(_borrowDepth <= maxBorrowDepth, "borrowDepth is too large");
        borrowDepth = _borrowDepth;
        emit BorrowDepthChanged(msg.sender, _borrowDepth);
    }

    /**
     * @dev Sets the minimum want to leverage/deleverage (loop) for
     */
    function setMinWantToLeverage(uint256 _minWantToLeverage) external onlyRole(GUARDIAN_ROLE) {
        minWantToLeverage = _minWantToLeverage;
        emit MinWantChanged(msg.sender, _minWantToLeverage);
    }

    /**
     * @dev Sets the ltvScaleOfSafeCollateralFactor for to check whether the scaled ltv is less than collateral factor.
     * 1 PERCENT_DIVISOR == 100%
     */
    function setLtvScaleOfSafeCollateralFactor(uint256 _value) external onlyRole(GUARDIAN_ROLE) {
        ltvScaleOfSafeCollateralFactor = _value;
        emit LtvScaleOfSafeCollateralFactorChanged(msg.sender, _value);
    }

    /**
     * @dev Sets the principalScaleOfSafeSupply for to check whether the pool totalSupply is sufficient.
     * 1 PERCENT_DIVISOR == 100%
     */
    function setPrincipalScaleOfSafeSupply(uint256 _value) external onlyRole(GUARDIAN_ROLE) {
        principalScaleOfSafeSupply = _value;
        emit PrincipalScaleOfSafeLiquidityChanged(msg.sender, _value);
    }

    /**
     * @dev Sets the principalScaleOfSafeLiquidity for to check whether the liquidity is sufficient.
     * 1 PERCENT_DIVISOR == 100%
     */
    function setPrincipalScaleOfSafeLiquidity(uint256 _value) external onlyRole(GUARDIAN_ROLE) {
        principalScaleOfSafeLiquidity = _value;
        emit PrincipalScaleOfSafeLiquidityChanged(msg.sender, _value);
    }

    function setRewards(address[] calldata _rewards) external onlyRole(GUARDIAN_ROLE) {
        delete rewards;
        rewards = _rewards;
        emit RewardChanged(msg.sender, _rewards);
    }

    /**
     * @dev Check deleveraging condtions, if deleveraging is not required then return 0.
     * return 1: ltv * ltvScaleOfSafeCollateralFactor >= collateral factor
     * return 2: ltv > targetLTV + allowedLTVDrift
     * return 3: liquidity < balanceOf() * principalScaleOfSafeLiquidity ( liquidity: cWant.getCash() - cWant.totalReserves() )
     * return 4: supply < balanceOf() * principalScaleOfSafeSupply ( supply: (cWant.totalSupply() * _getExchangeRateStored()) / COMPOUND_MANTISSA )
     *
     */
    function shouldDeleverage() external view virtual returns (uint256 resultCode) {
        uint256 collateralFactorMantissa = _getCollateralFactor();
        uint256 _ltv = calculateLTV();
        //result code 1: check ltv with collateral factor
        resultCode = (_ltv * ltvScaleOfSafeCollateralFactor) / PERCENT_DIVISOR >= collateralFactorMantissa ? 1 : 0;
        //result code 2: check ltv with target ltv
        if (resultCode == 0) {
            resultCode = _shouldDeleverage(_ltv) ? 2 : 0;
        }

        uint256 liquidity = cWant.getCash() - cWant.totalReserves();
        //result code 3: check liquidity of the principals
        uint256 principals = balanceOf();
        if (resultCode == 0) {
            resultCode = liquidity < (principals * principalScaleOfSafeLiquidity) / PERCENT_DIVISOR ? 3 : 0;
        }
        //result code 4: checks on sufficient supply
        if (resultCode == 0) {
            uint256 totalSupply = (cWant.totalSupply() * _getExchangeRateStored()) / COMPOUND_MANTISSA;
            resultCode = totalSupply < (principals * principalScaleOfSafeSupply) / PERCENT_DIVISOR ? 4 : 0;
        }
    }

    /**
     * @dev Updates the balance. This is the state changing version so it sets
     * balanceOfPool to the latest value.
     */
    function updateBalance() public {
        // balanceOfUnderlying and borrowBalanceCurrent are write functions
        uint256 supplyBalance = cWant.balanceOfUnderlying(address(this));
        uint256 borrowBalance = cWant.borrowBalanceCurrent(address(this));
        balanceOfPool = supplyBalance - borrowBalance;
    }

    /**
     * @dev Calculates the LTV using existing exchange rate,
     * depends on the cWant being updated to be accurate.
     * Does not update in order provide a view function for LTV.
     */
    function calculateLTV() public view returns (uint256 ltv) {
        (, uint256 cWantBalance, uint256 borrowed, uint256 exchangeRate) = cWant.getAccountSnapshot(address(this));

        uint256 supplied = (cWantBalance * exchangeRate) / COMPOUND_MANTISSA;

        if (supplied == 0 || borrowed == 0) {
            return 0;
        }

        ltv = (COMPOUND_MANTISSA * borrowed) / supplied;
    }

    /**
     * @dev Calculates the total amount of {want} held by the strategy
     * which is the balance of want + the total amount supplied to pool.
     */
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool;
    }

    /**
     * @dev Calculates the balance of want held directly by the strategy
     */
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    /**
     * @dev Calculates the balance of want held directly by the strategy
     */
    function balanceOfcWant() public view returns (uint256) {
        return cWant.balanceOf(address(this));
    }

    /**
     * @dev Returns the current position in Pool. Does not accrue interest
     * so might not be accurate, but the cWant is usually updated.
     */
    function getCurrentPosition() public view returns (uint256 supplied, uint256 borrowed) {
        (, uint256 cWantBalance, uint256 borrowBalance, uint256 exchangeRate) = cWant.getAccountSnapshot(address(this));
        borrowed = borrowBalance;

        supplied = (cWantBalance * exchangeRate) / COMPOUND_MANTISSA;
    }

    function getRewards() public view returns (address[] memory) {
        return rewards;
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone supplied in the strategy's vault contract.
     * It supplies want to farm rewrd
     */
    function _deposit() internal doUpdateBalance {
        uint256 wantBalance = balanceOfWant();
        if (wantBalance > 0) {
            _supply(wantBalance);
        }
        uint256 _ltv = _calculateLTV();

        if (_shouldLeverage(_ltv)) {
            _leverMax();
        } else if (_shouldDeleverage(_ltv)) {
            _deleverage(0);
        }
    }

    /**
     * @dev Withdraws funds and sents them back to the user.
     * It withdraws {want} from Pool
     */
    function _withdrawFromPool(uint256 _withdrawAmount) internal doUpdateBalance returns (uint256 finalWithdrawAmount) {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        uint256 _ltv = _calculateLTVAfterWithdraw(_withdrawAmount, supplied, borrowed);
        uint256 realSupply = supplied - borrowed;
        if (_withdrawAmount > realSupply) {
            _withdrawAmount = realSupply;
        }
        if (_shouldLeverage(_ltv)) {
            // Strategy is underleveraged so can withdraw underlying directly
            finalWithdrawAmount = _withdrawUnderlyingToUser(_withdrawAmount);
            _leverMax();
        } else if (_shouldDeleverage(_ltv)) {
            _deleverage(_withdrawAmount);
            // Strategy has deleveraged to the point where it can withdraw underlying
            finalWithdrawAmount = _withdrawUnderlyingToUser(_withdrawAmount);
        } else {
            // LTV is in the acceptable range so the underlying can be withdrawn directly
            finalWithdrawAmount = _withdrawUnderlyingToUser(_withdrawAmount);
        }
    }

    /**
     * @dev Withdraws want to the user by redeeming the underlying
     */
    function _withdrawUnderlyingToUser(uint256 _withdrawAmount) internal returns (uint256 finalWithdrawAmount) {
        uint256 initWithdrawAmount = _withdrawAmount;
        _withdrawUnderlying(_withdrawAmount);
        uint256 bal = balanceOfWant();
        finalWithdrawAmount = bal < initWithdrawAmount ? bal : initWithdrawAmount;
        IERC20(want).safeTransfer(msg.sender, finalWithdrawAmount);
    }

    /**
     * @dev Levers the strategy up to the targetLTV
     */
    function _leverMax() internal {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        uint oldLtv = _calculateLTV();
        uint256 realSupply = supplied - borrowed;
        uint256 newBorrow = _getMaxBorrowFromSupplied(realSupply, targetLTV);
        uint256 totalAmountToBorrow = newBorrow - borrowed;

        for (uint8 i = 0; totalAmountToBorrow > minWantToLeverage && i < borrowDepth; i++) {
            totalAmountToBorrow = totalAmountToBorrow - _leverUpStep(totalAmountToBorrow);
        }
        uint256 currentLtv = _calculateLTV();
        emit CurrentLtvChanged(msg.sender, oldLtv, currentLtv);
    }

    /**
     * @dev Does one step of leveraging
     */
    function _leverUpStep(uint256 _withdrawAmount) internal returns (uint256) {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        uint256 collateralFactorMantissa = _getCollateralFactor();
        uint256 canBorrow = (supplied * collateralFactorMantissa) / COMPOUND_MANTISSA;

        canBorrow -= borrowed;

        if (canBorrow < _withdrawAmount) {
            _withdrawAmount = canBorrow;
        }
        uint minWant = minWantToLeverage;
        if (_withdrawAmount > minWant) {
            // borrow available amount
            _withdrawAmount -= minWant;
            _borrow(_withdrawAmount);

            // deposit available want as collateral
            uint256 wantBalance = balanceOfWant();
            // IERC20(want).safeIncreaseAllowance(address(cWant), wantBalance);
            _supply(wantBalance);
        }

        return _withdrawAmount;
    }

    /**
     * @dev Returns if the strategy should leverage with the given ltv level
     */
    function _shouldLeverage(uint256 _ltv) internal view returns (bool) {
        if (targetLTV >= allowedLTVDrift && _ltv < targetLTV - allowedLTVDrift) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns if the strategy should deleverage with the given ltv level
     */
    function _shouldDeleverage(uint256 _ltv) internal view returns (bool) {
        if (_ltv > targetLTV + allowedLTVDrift) {
            return true;
        }
        return false;
    }

    /**
     * @dev This is the state changing calculation of LTV that is more accurate
     * to be used internally.
     */
    function _calculateLTV() internal returns (uint256 ltv) {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        if (supplied == 0 || borrowed == 0) {
            return 0;
        }
        ltv = (COMPOUND_MANTISSA * borrowed) / supplied;
    }

    /**
     * @dev Withdraws want to the strat by redeeming the underlying
     */
    function _withdrawUnderlying(uint256 _withdrawAmount) internal {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        uint256 realSupplied = supplied - borrowed;

        if (realSupplied == 0) {
            return;
        }

        if (_withdrawAmount > realSupplied) {
            _withdrawAmount = realSupplied;
        }

        uint256 tempColla = targetLTV + allowedLTVDrift;
        if (tempColla == 0) {
            tempColla = 1e15; // 0.001 * 1e18. lower we have issues
        }

        uint256 reservedAmount = 0;
        reservedAmount = (borrowed * COMPOUND_MANTISSA) / tempColla;
        if (supplied >= reservedAmount) {
            uint256 redeemable = supplied - reservedAmount;
            uint256 balance = balanceOfcWant();
            if (balance > 1) {
                if (redeemable < _withdrawAmount) {
                    _withdrawAmount = redeemable;
                }
            }
        }
        _redeem(_withdrawAmount);
    }

    /**
     * @dev For a given withdraw amount, figures out the new borrow with the current supply
     * that will maintain the target LTV
     */
    function _getDesiredBorrow(uint256 _withdrawAmount) internal returns (uint256 position) {
        //we want to use statechanging for safety
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();

        //When we unwind we end up with the difference between borrow and supply
        uint256 unwoundSupplied = supplied - borrowed;

        //we want to see how close to collateral target we are.
        //So we take our unwound supplied and add or remove the _withdrawAmount we are are adding/removing.
        //This gives us our desired future undwoundDeposit (desired supply)

        uint256 desiredSupply = 0;
        if (_withdrawAmount > unwoundSupplied) {
            _withdrawAmount = unwoundSupplied;
        }
        desiredSupply = unwoundSupplied - _withdrawAmount;

        //(ds *c)/(1-c)
        uint256 num = desiredSupply * targetLTV;
        uint256 den = COMPOUND_MANTISSA - targetLTV;

        uint256 desiredBorrow = num / den;
        if (desiredBorrow > 1e5) {
            //stop us going right up to the wire
            desiredBorrow = desiredBorrow - 1e5;
        }

        position = borrowed - desiredBorrow;
    }

    /**
     * @dev For a given withdraw amount, delever to a borrow level
     * that will maintain the target LTV
     */
    function _deleverage(uint256 _withdrawAmount) internal {
        uint256 oldLtv = _calculateLTV();

        uint256 totalRepayAmount = _getDesiredBorrow(_withdrawAmount);

        //If there is no deficit we dont need to adjust position
        //if the position change is tiny do nothing
        if (totalRepayAmount > minWantToLeverage) {
            for (uint256 i = 0; totalRepayAmount > minWantToLeverage && i < borrowDepth; i++) {
                totalRepayAmount = totalRepayAmount - _leverDownStep(totalRepayAmount);
            }
        }
        uint256 currentLtv = _calculateLTV();
        emit CurrentLtvChanged(msg.sender, oldLtv, currentLtv);
    }

    /**
     * @dev Deleverages one step
     */
    function _leverDownStep(uint256 maxDeleverage) internal returns (uint256 deleveragedAmount) {
        (uint256 supplied, uint256 borrowed) = _getSupplyAndBorrow();
        uint256 collateralFactorMantissa = _getCollateralFactor();

        deleveragedAmount = _calcMaxAllowedDeleverageAmount(supplied, borrowed, collateralFactorMantissa);

        if (deleveragedAmount >= borrowed) {
            deleveragedAmount = borrowed;
        }
        if (deleveragedAmount >= maxDeleverage) {
            deleveragedAmount = maxDeleverage;
        }
        uint256 exchangeRateStored = _getExchangeRateStored();
        //redeemTokens = redeemAmountIn * 1e18 / exchangeRate. must be more than 0
        //a rounding error means we need another small addition
        uint minWant = minWantToLeverage;
        if (deleveragedAmount * COMPOUND_MANTISSA >= exchangeRateStored && deleveragedAmount > minWant) {
            deleveragedAmount -= minWant; // Amount can be slightly off for tokens with less decimals (USDC), so redeem a bit less
            _redeem(deleveragedAmount);
            //our borrow has been increased by no more than maxDeleverage
            _repay(deleveragedAmount);
        }
    }

    /**
     * @dev Gets the maximum amount allowed to be borrowed for a given collateral factor and amount supplied
     */
    function _getMaxBorrowFromSupplied(uint256 wantSupplied, uint256 collateralFactor) internal pure returns (uint256) {
        return ((wantSupplied * collateralFactor) / (COMPOUND_MANTISSA - collateralFactor));
    }

    /**
     * @dev Calculates what the LTV will be after withdrawing
     */
    function _calculateLTVAfterWithdraw(
        uint256 _withdrawAmount,
        uint256 supplied,
        uint256 borrowed
    ) internal pure returns (uint256 ltv) {
        uint256 realSupplied = supplied - borrowed;
        if (realSupplied <= _withdrawAmount) {
            return type(uint256).max;
        }
        supplied = supplied - _withdrawAmount;
        ltv = (COMPOUND_MANTISSA * borrowed) / supplied;
    }

    function _calcMaxAllowedDeleverageAmount(
        uint256 supplied,
        uint256 borrowed,
        uint256 collateralFactorMantissa
    ) internal pure returns (uint256) {
        uint256 minAllowedSupply = 0;
        //collat ration should never be 0. if it is something is very wrong... but just incase
        if (collateralFactorMantissa != 0) {
            minAllowedSupply = (borrowed * COMPOUND_MANTISSA) / collateralFactorMantissa;
        }

        return supplied - minAllowedSupply;
    }

    /************************ Override Functions ****************************/

    /**
     * @dev supply want to cWant market.
     */
    function _supply(uint256 amount) internal virtual returns (uint256 err) {
        err = cWant.mint(amount);
        require(err == 0, "Supply failed");
    }

    /**
     * @dev borrow want from cWant market.
     */
    function _borrow(uint256 amount) internal virtual returns (uint256 err) {
        err = cWant.borrow(amount);
        require(err == 0, "Borrow failed");
    }

    /**
     * @dev repay debt to cWant market.
     */
    function _repay(uint256 amount) internal virtual returns (uint256 err) {
        err = cWant.repayBorrow(amount);
        require(err == 0, "Repay failed");
    }

    /**
     * @dev Burn cWant and redeem underlying.
     */
    function _redeem(uint256 amount) internal virtual returns (uint256 err) {
        err = cWant.redeemUnderlying(amount);
        require(err == 0, "Redeem failed");
    }

    /**
     * @dev Returns the accurate current position.
     */
    function _getSupplyAndBorrow() internal virtual returns (uint256 supplied, uint256 borrowed) {
        // balanceOfUnderlying is a write function
        supplied = cWant.balanceOfUnderlying(address(this));
        borrowed = cWant.borrowBalanceStored(address(this));
    }

    /**
     * @dev Returns the collateralFactorMantissa of want.
     */
    function _getCollateralFactor() internal view virtual returns (uint256 collateralFactorMantissa) {
        (, collateralFactorMantissa, ) = IComptroller(comptroller).markets(address(cWant));
    }

    /**
     * @dev Returns the exchangeRateStored of cWant.
     */
    function _getExchangeRateStored() internal view virtual returns (uint256 exchangeRateStoredMantissa) {
        return cWant.exchangeRateStored();
    }

    /**
     * @dev Core harvest function.
     * Get rewards from markets entered
     */
    function _claimRewards() internal virtual returns (uint256 rewardAmount) {
        address reward = rewards[0];
        uint256 initBal = IERC20(reward).balanceOf(address(this));
        ICToken[] memory tokens = new ICToken[](1);
        tokens[0] = cWant;
        IComptroller(comptroller).claimComp(address(this), tokens);
        uint256 newBal = IERC20(reward).balanceOf(address(this));
        rewardAmount = newBal - initBal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";

contract Access is AccessControl, Pausable {
    /**
     * {KEEPER_ROLE} - Stricly permissioned trustless access for off-chain programs or third party keepers.
     * {GUARDIAN_ROLE} - Role conferred to authors of the strategy, allows for tweaking non-critical params and emergency measures such as pausing and panicking.
     * {ADMIN}- Role can withdraw assets.
     * {DEFAULT_ADMIN_ROLE} (in-built access control role) This role would have the ability to grant any other roles.
     */
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    constructor(address _admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
        _grantRole(GUARDIAN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
    }

    function pause() external virtual onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    function unpause() external virtual onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IOneInchRouterV5 } from "./interfaces/IOneInchRouterV5.sol";
import { Access } from "./Access.sol";

abstract contract Aggregator is Access {
    using SafeERC20 for IERC20;
    using Address for address;

    error InvalidRecipient();
    error InvalidSelector();

    struct OneInchData {
        address token;
        bytes data;
    }

    constructor(address[] memory _tokens) {
        for (uint256 i = 0; i < _tokens.length; ++i) {
            IERC20(_tokens[i]).approve(oneInchRouter, type(uint256).max);
        }
    }

    address public oneInchRouter = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    event OneInchRouterChanged(address indexed caller, address oldRouter, address newRouter);

    function setOneInchRouter(address _router) external onlyRole(ADMIN_ROLE) {
        address oldRouter = oneInchRouter;
        oneInchRouter = _router;
        emit OneInchRouterChanged(msg.sender, oldRouter, _router);
    }

    function approveToken(address _token, uint256 _allowance) external onlyRole(ADMIN_ROLE) {
        IERC20(_token).approve(oneInchRouter, _allowance);
    }

    function _1inchSwap(bytes calldata _data) internal virtual {
        bytes4 selector = bytes4(_data[:4]);
        if (selector == IOneInchRouterV5.swap.selector) {
            (, IOneInchRouterV5.SwapDescription memory desc, , ) = abi.decode(
                _data[4:],
                (address, IOneInchRouterV5.SwapDescription, bytes, bytes)
            );
            _checkRecipient(desc.dstReceiver);
        } else if (
            selector != IOneInchRouterV5.uniswapV3Swap.selector && selector != IOneInchRouterV5.unoswap.selector
        ) {
            revert InvalidSelector();
        }
        oneInchRouter.functionCall(_data);
    }

    function _checkRecipient(address _recipient) internal view {
        if (_recipient != address(this)) {
            revert InvalidRecipient();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IOneInchRouterV5 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        address,
        SwapDescription calldata _desc,
        bytes calldata,
        bytes calldata
    ) external returns (uint256 returnAmount, uint256 spentAmount);

    //already restrict recipient must be msg.sender in 1inch contract
    function unoswap(
        address _srcToken,
        uint256,
        uint256,
        uint256[] calldata pools
    ) external returns (uint256 returnAmount);

    function unoswapTo(
        address recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external returns (uint256 returnAmount);

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] calldata pools) external;

    function uniswapV3SwapTo(
        address recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external returns (uint256 returnAmount);

    // Safe is the taker.
    struct Order {
        uint256 salt;
        address makerAsset; // For safe to buy
        address takerAsset; // For safe to sell
        address maker;
        address receiver; // Where to send takerAsset, default zero means sending to maker.
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
        uint256 offsets;
        bytes interactions; // concat(makerAssetData, takerAssetData, getMakingAmount, getTakingAmount, predicate, permit, preIntercation, postInteraction)
    }

    function fillOrder(
        Order calldata order,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount
    ) external returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    function fillOrderTo(
        Order calldata order_,
        bytes calldata signature,
        bytes calldata interaction,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 skipPermitAndThresholdAmount,
        address target
    ) external returns (uint256 actualMakingAmount, uint256 actualTakingAmount, bytes32 orderHash);

    struct OrderRFQ {
        uint256 info; // lowest 64 bits is the order id, next 64 bits is the expiration timestamp
        address makerAsset;
        address takerAsset;
        address maker;
        address allowedSender; // equals to Zero address on public orders
        uint256 makingAmount;
        uint256 takingAmount;
    }

    function fillOrderRFQ(
        OrderRFQ calldata order,
        bytes calldata signature,
        uint256 flagsAndAmount
    ) external returns (uint256 /* filledMakingAmount */, uint256 /* filledTakingAmount */, bytes32 /* orderHash */);

    function fillOrderRFQTo(
        OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target
    ) external payable returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

    function fillOrderRFQCompact(
        OrderRFQ calldata order,
        bytes32 r,
        bytes32 vs,
        uint256 flagsAndAmount
    ) external returns (uint256 filledMakingAmount, uint256 filledTakingAmount, bytes32 orderHash);

    function clipperSwap(
        address clipperExchange,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external returns (uint256 returnAmount);

    function clipperSwapTo(
        address clipperExchange,
        address recipient,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external returns (uint256 returnAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICToken.sol";

interface ICErc20 is ICToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ICToken cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function comptroller() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICToken.sol";

interface IComptroller {
    function oracle() external view returns (address);

    function compAccrued(address user) external view returns (uint256 amount);

    function claimComp(address holder, ICToken[] memory _scTokens) external;

    function claimComp(address holder) external;

    function enterMarkets(address[] memory _scTokens) external;

    function pendingComptrollerImplementation() external view returns (address implementation);

    function markets(address ctoken) external view returns (bool, uint256, bool);

    function compSpeeds(address ctoken) external view returns (uint256); // will be deprecated

    function compBorrowSpeeds(address ctoken) external view returns (uint256);

    function compSupplySpeeds(address ctoken) external view returns (uint256);

    function borrowCaps(address cToken) external view returns (uint256);

    function supplyCaps(address cToken) external view returns (uint256);

    function rewardDistributor() external view returns (address);
}

interface IPriceOracle {
    function getUnderlyingPrice(ICToken cToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./InterestRateModel.sol";

interface ICToken {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface InterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256, uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}