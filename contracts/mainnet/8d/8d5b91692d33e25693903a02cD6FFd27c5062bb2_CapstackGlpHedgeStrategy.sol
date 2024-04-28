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
        for (uint256 i = 0; i < _tokens.length; i++) {
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
pragma solidity 0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ISwapRouter } from "../interfaces/ISwapRouter.sol";
import { ICamelotRouter } from "../interfaces/ICamelotRouter.sol";
import { IQuoter } from "../interfaces/IQuoter.sol";
import { Access } from "./Access.sol";
import { Aggregator } from "./Aggregator.sol";

abstract contract Swapper is Aggregator {
    using SafeERC20 for IERC20;

    mapping(bytes32 => bytes) public pathMap;
    address public constant UNIV3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public currentRouter = UNIV3_ROUTER;

    event RouterChanged(address indexed caller, address oldRouter, address newRouter);
    event PathChanged(address indexed caller, bytes32 tag, bytes oldPath, bytes newPath);

    function setRouter(address _router) external onlyRole(GUARDIAN_ROLE) {
        address oldRouter = currentRouter;
        currentRouter = _router;
        emit RouterChanged(msg.sender, oldRouter, _router);
    }

    function setPath(
        address _from,
        address _to,
        address _router,
        bytes calldata _path
    ) external onlyRole(GUARDIAN_ROLE) {
        _setPath(_from, _to, _router, _path);
    }

    function genPathTag(address _from, address _to, address _router) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_from, _to, _router));
    }

    function _setPath(address _from, address _to, address _router, bytes memory _path) internal {
        bytes32 tag = genPathTag(_from, _to, _router);
        bytes memory _oldPath = pathMap[tag];
        pathMap[tag] = _path;
        emit PathChanged(msg.sender, tag, _oldPath, _path);
    }

    function _swap(uint256 _amountIn, address _from, address _to, uint256 minReceive) internal returns (uint256) {
        bytes memory _path = pathMap[genPathTag(_from, _to, currentRouter)];
        return _uniswapV3Base(_from, _amountIn, minReceive, _path);
    }

    function _swapOut(uint256 _amountOut, address _out, address _from, uint256 maxIn) internal returns (uint256) {
        // _out is the first token in the path
        bytes memory _path = pathMap[genPathTag(_out, _from, currentRouter)];
        return _uniswapV3ExactOut(_from, _amountOut, maxIn, _path);
    }

    /// @dev Helper function to swap given a uni v3 path and an {_amount}.
    function _uniswapV3Base(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _minOut,
        bytes memory _path
    ) internal returns (uint256 amountOut) {
        if (_amountIn > 0) {
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _minOut
            });
            IERC20(_tokenIn).safeIncreaseAllowance(currentRouter, _amountIn);
            amountOut = ISwapRouter(currentRouter).exactInput(params);
        }
    }

    function _uniswapV3ExactOut(
        address _tokenIn,
        uint256 _amountOut,
        uint256 _maxIn,
        bytes memory _path
    ) internal returns (uint256 amountOut) {
        if (_amountOut > 0) {
            ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: _amountOut,
                amountInMaximum: _maxIn
            });
            IERC20(_tokenIn).safeApprove(currentRouter, _maxIn);
            amountOut = ISwapRouter(currentRouter).exactOutput(params);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IBalVault } from "./interfaces/IBalVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BalFlashLoanHelper {
    using SafeERC20 for IERC20;

    IBalVault private constant balVault = IBalVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    bool private awaitingFlash = false;

    function makeBalFlashLoan(address _token, uint256 _amount, bytes memory userData) internal {
        uint256 liquidity = balTokenAvailable(_token);
        if (_amount > liquidity) {
            _amount = liquidity;
        }
        address[] memory tokens = new address[](1);
        tokens[0] = _token;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        awaitingFlash = true;
        balVault.flashLoan(address(this), tokens, amounts, userData);
        awaitingFlash = false;
    }

    function balTokenAvailable(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(balVault));
    }

    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal virtual;

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        // Prevent evil flashloans
        require(awaitingFlash);
        require(msg.sender == address(balVault));

        IERC20 token = IERC20(tokens[0]);
        uint256 repayAmount = amounts[0] + feeAmounts[0];
        _flashLoanLogic(userData, repayAmount);
        // Repay
        token.safeTransfer(address(balVault), repayAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBalVault {
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ICErc20, ICToken } from "../interfaces/ICErc20.sol";
import { ICEther } from "../interfaces/ICEther.sol";
import { IComptroller, IPriceOracle } from "../interfaces/IComptroller.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { Access } from "../common/Access.sol";
import { Swapper } from "../common/Swapper.sol";
import { Aggregator } from "../common/Aggregator.sol";
import { BalFlashLoanHelper } from "../flashloan/BalFlashLoanHelper.sol";
import { IGLPLens } from "./interfaces/IGLPLens.sol";
import { IPlvGLPHelper } from "./interfaces/IPlvGLPHelper.sol";

/// @title A Hedge strategy for GLP
/// @author capstack
/// @notice This contract use Lodestar to hedge
/// @dev This a strategy for a single user
// Split swapper
contract CapstackGlpHedgeStrategy is Swapper, BalFlashLoanHelper {
    using SafeERC20 for IERC20;

    error InvalidDrift();
    error InvalidThreshold();
    error InvalidMaxDebtRatio();
    error InvalidSlippage();
    error InvalidHedgeBias();
    error InvalidMultiplier();
    error ZeroAmount();
    error DebtRatioTooHigh();

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed caller, address want, uint256 tokenAmount, uint256 timestamp);
    event Claim(address indexed caller, uint256 rewardAmount);
    event HedgeAction(bool isHedge, uint256 brrowAmount, uint256 collateralAmount);
    event Rebalance(
        address indexed caller,
        uint256 lastWeight,
        uint256 currentWeight,
        uint256 currentDerivedWeight,
        uint256 lastAmount,
        uint256 currentAmount,
        uint256 timestamp
    );
    event SwapToken(address indexed caller, address indexed token, uint256 amount);

    event DriftChanged(
        address indexed caller,
        uint256 oldDrift,
        uint256 newDrift,
        uint256 oldAmount,
        uint256 newAmount
    );

    event ExitWeightChanged(
        address indexed caller,
        uint256 oldExit,
        uint256 newExit,
        uint256 oldAlert,
        uint256 newAlert
    );
    event MaxDebtRatioChanged(address indexed caller, uint256 oldDebtRatio, uint256 newDebtRatio);
    event HedgeBiasChanged(address indexed caller, uint256 oldBias, uint256 newBias);
    event MultiplierChanged(address indexed caller, uint256 oldMultiplier, uint256 newMultiplier);
    event ThresholdChanged(address indexed caller, uint256 oldTreshold, uint256 newTreshold);
    event SlippageChanged(address indexed caller, uint256 oldSlippage, uint256 newSlippage);
    event GlpLensChanged(address indexed caller, address oldLens, address newLens);
    event PlvGlpHelperChanged(address indexed caller, address oldPlvGlpHelper, address newPlvGlpHelper);
    event BorrowAndCollateralTokensChanged(
        address indexed caller,
        address oldBorrowToken,
        address newBorrowToken,
        address oldCollateralToken,
        address newCollateralToken
    );
    event RewardChanged(address indexed caller, address[] newRewards);

    struct Hedge {
        uint256 weight;
        uint256 amount;
        uint256 timestamp;
    }

    struct LocalPosition {
        uint256 plvGlpFactor;
        uint256 collateralFactor;
        uint256 plvGlpPrice;
        uint256 collateralTokenPrice;
        uint256 borrowTokenPrice;
        uint256 totalCollateralValue;
        uint256 borrowValue;
    }
    uint256 public constant PERCENT_DIVISOR = 10_000;
    uint256 public constant BASE_PRECISION = 1e18;
    address public constant weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant plvGLP = 0x5326E71Ff593Ecc2CF7AcaE5Fe57582D6e74CFF1;
    IComptroller public constant comptroller = IComptroller(0xa86DD95c210dd186Fa7639F93E4177E97d057576);

    address public collateralToken;
    address public borrowToken;

    // underlying => cToken
    mapping(address => address) public cTokenMap;
    address[] public rewards;

    /// @dev Last hedge data
    Hedge public lastHedge;

    /// @notice BPS
    uint256 public hedgeAmountDrift = 250;

    /// @notice hedge asset amount
    uint256 public fixedHedgeAmountDrift = 1_000_000;

    /// @notice BASE_PRECISION: 0 < hedgeBias < 10 perceent 4.5%
    uint256 public hedgeBias = (450 * BASE_PRECISION) / PERCENT_DIVISOR;

    uint256 public hedgeMultiplier = 10;

    /// @notice BASE_PRECISION 2.5%
    uint256 public rebalanceThreshold = (250 * BASE_PRECISION) / PERCENT_DIVISOR;

    /// @notice BASE_PRECISION 90%
    uint256 public maxDebtRatio = 0.9 ether;

    /// @notice BPS 0.5%
    uint256 public slippage = 50;

    /// @dev get glp pool data
    IGLPLens public glpLens;

    /// @dev mint token to plvGlp
    IPlvGLPHelper public plvGlpHelper;

    uint256 public exitWeight = 0.68 ether;

    uint256 public alertWeight = 0.6 ether;

    constructor(
        address _admin,
        address _guardian,
        address _keeper,
        address _glpLens,
        address _plvGlpHelper,
        address _borrowToken,
        address _borrowLtoken,
        address _collateralToken,
        address _collateralLtoken,
        address[] memory _rewards
    ) Access(_admin) Aggregator(_rewards) {
        glpLens = IGLPLens(_glpLens);
        plvGlpHelper = IPlvGLPHelper(_plvGlpHelper);
        rewards = _rewards;
        _grantRole(GUARDIAN_ROLE, _guardian);
        _grantRole(KEEPER_ROLE, _guardian);
        _grantRole(KEEPER_ROLE, _keeper);

        // Tokens
        address lPlvGlp = 0xeA0a73c17323d1a9457D722F10E7baB22dc0cB83;
        borrowToken = _borrowToken;
        collateralToken = _collateralToken;

        // Set ltoken
        cTokenMap[plvGLP] = lPlvGlp;
        cTokenMap[_borrowToken] = _borrowLtoken;
        cTokenMap[_collateralToken] = _collateralLtoken;

        // Approve tokens
        IERC20(plvGLP).approve(lPlvGlp, type(uint256).max);
        IERC20(plvGLP).approve(address(plvGlpHelper), type(uint256).max);
        IERC20(_borrowToken).approve(_borrowLtoken, type(uint256).max);
        IERC20(_collateralToken).approve(_collateralLtoken, type(uint256).max);

        // Enter markets
        address[] memory _markets = new address[](3);
        _markets[0] = lPlvGlp;
        _markets[1] = _borrowLtoken;
        _markets[2] = _collateralLtoken;
        comptroller.enterMarkets(_markets);

        // set Swap path
        uint24 uniV3PoolFee = 500;
        bytes memory _swapPath = abi.encodePacked(_borrowToken, uniV3PoolFee, _collateralToken);
        _setPath(_borrowToken, _collateralToken, UNIV3_ROUTER, _swapPath);
        _swapPath = abi.encodePacked(_collateralToken, uniV3PoolFee, _borrowToken);
        _setPath(_collateralToken, _borrowToken, UNIV3_ROUTER, _swapPath);
    }

    function depositAll() external {
        deposit(IERC20(plvGLP).balanceOf(msg.sender));
    }

    function deposit(uint256 _amount) public onlyRole(GUARDIAN_ROLE) whenNotPaused {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        IERC20(plvGLP).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit();
    }

    function deposit(address _token, uint256 _amount) public onlyRole(GUARDIAN_ROLE) whenNotPaused {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(plvGlpHelper), _amount);
        plvGlpHelper.mintPlvGlp(_token, _amount, 1);
        _deposit();
    }

    function withdrawAll() external onlyRole(ADMIN_ROLE) {
        address _borrowToken = borrowToken;
        address _collateralToken = collateralToken;
        _flashRepayAll(_borrowToken);
        uint256 plvGlpAmount = _tokenBalance(plvGLP);
        _transferTokens(plvGLP, msg.sender, plvGlpAmount);
        uint256 cBal = _tokenBalance(_collateralToken);
        _transferTokens(_collateralToken, msg.sender, cBal);
    }

    function withdrawAllToToken(address _token) external onlyRole(ADMIN_ROLE) {
        address _borrowToken = borrowToken;
        address _collateralToken = collateralToken;
        _flashRepayAll(_borrowToken);
        uint256 plvGlpAmount = _tokenBalance(plvGLP);
        plvGlpHelper.redeemPlvGlpToToken(_token, plvGlpAmount, 1);
        uint256 tBal = _tokenBalance(_token);
        _transferTokens(_token, msg.sender, tBal);
        uint256 cBal = _tokenBalance(_collateralToken);
        _transferTokens(_collateralToken, msg.sender, cBal);
    }

    function withdraw(uint256 _amount) public onlyRole(ADMIN_ROLE) {
        if (_amount == 0) {
            revert ZeroAmount();
        }
        uint256 plvGlpAmount = _tokenBalance(plvGLP);
        if (_amount <= plvGlpAmount) {
            _transferTokens(plvGLP, msg.sender, _amount);
            return;
        }
        uint256 plvGlpSupply = _getSupply(plvGLP);
        uint256 remainSupply = plvGlpSupply > _amount ? plvGlpSupply - _amount : 0;
        (uint256 currentWeight, uint256 derivedWeight) = getWeight();
        (uint256 hedgeTarget, , ) = calcHedgeAmount(remainSupply, derivedWeight);
        uint256 borrowAmount = _getBorrow(borrowToken);
        _rebalance(hedgeTarget, borrowAmount);
        _updateHedge(currentWeight, derivedWeight);
        if (remainSupply == 0) {
            _redeemAll(plvGLP);
        } else {
            _redeem(plvGLP, _amount);
        }
        plvGlpAmount = _tokenBalance(plvGLP);
        _transferTokens(plvGLP, msg.sender, plvGlpAmount);
    }

    /**
     * @dev Withdraw Ethers to admin
     */
    function withdrawEthers() external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{ value: balance }("");
        assert(success);
    }

    /**
     * @dev Withdraw ERC20 token to admin
     */
    function withdrawTokens(IERC20 token) external onlyRole(ADMIN_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function harvest(OneInchData[] calldata _data) external onlyRole(KEEPER_ROLE) whenNotPaused {
        (bool shouldReb, bool shouldHedge) = shouldRebalance();
        // Swap rewards
        uint256 length = _data.length;
        for (uint256 i = 0; i < length; ++i) {
            OneInchData calldata swapData = _data[i];
            uint256 tokenBal = IERC20(swapData.token).balanceOf(address(this));
            if (tokenBal > 0) {
                _1inchSwap(swapData.data);
                emit SwapToken(msg.sender, swapData.token, tokenBal);
            }
        }

        address _borrowToken = borrowToken;
        address _collateralToken = collateralToken;
        // Meet dehedge
        if (shouldReb && !shouldHedge) {
            uint256 borrowTokenBal = _tokenBalance(_borrowToken);
            emit Harvest(msg.sender, _borrowToken, borrowTokenBal, block.timestamp);
            if (borrowTokenBal > 0) {
                _repay(borrowTokenBal);
            }
        } else {
            uint256 collateralTokenBal = _tokenBalance(_collateralToken);
            emit Harvest(msg.sender, _collateralToken, collateralTokenBal, block.timestamp);
            if (collateralTokenBal > 0) {
                _supply(_collateralToken, collateralTokenBal);
            }
        }

        if (shouldReb) {
            _rebalance();
        }
    }

    /**
     * @dev Claim rewards without swapping
     */
    function claim() external onlyRole(KEEPER_ROLE) returns (uint256 rewardAmount) {
        rewardAmount = _claimRewards();
        emit Claim(msg.sender, rewardAmount);
    }

    function panic() external onlyRole(KEEPER_ROLE) {
        _flashRepayAll(borrowToken);
        _pause();
    }

    function setBorrowAndCollateralTokens(
        address _borrowToken,
        address _borrowLtoken,
        address _collateralToken,
        address _collateralLtoken
    ) external onlyRole(ADMIN_ROLE) {
        address oldBorrowToken = borrowToken;
        address oldCollateralToken = collateralToken;
        // repay
        _flashRepayAll(oldBorrowToken);
        // change tokens
        borrowToken = _borrowToken;
        collateralToken = _collateralToken;
        cTokenMap[_borrowToken] = _borrowLtoken;
        cTokenMap[_collateralToken] = _collateralLtoken;
        // approve tokens
        IERC20(_borrowToken).approve(_borrowLtoken, type(uint256).max);
        IERC20(_collateralToken).approve(_collateralLtoken, type(uint256).max);

        // Enter markets
        address[] memory _markets = new address[](2);
        _markets[0] = _borrowLtoken;
        _markets[1] = _collateralLtoken;
        comptroller.enterMarkets(_markets);
        // redeposit
        _deposit();
        emit BorrowAndCollateralTokensChanged(
            msg.sender,
            oldBorrowToken,
            _borrowToken,
            oldCollateralToken,
            _collateralToken
        );
    }

    function setLens(address _lens) external onlyRole(ADMIN_ROLE) {
        address oldLens = address(glpLens);
        glpLens = IGLPLens(_lens);
        emit GlpLensChanged(msg.sender, oldLens, _lens);
    }

    function setPlvGlpHelper(address _plvGlpHelper) external onlyRole(ADMIN_ROLE) {
        address oldPlvGlpHelper = address(plvGlpHelper);
        plvGlpHelper = IPlvGLPHelper(_plvGlpHelper);
        emit PlvGlpHelperChanged(msg.sender, oldPlvGlpHelper, _plvGlpHelper);
    }

    function setRewards(address[] calldata _rewards) external onlyRole(GUARDIAN_ROLE) {
        rewards = _rewards;
        emit RewardChanged(msg.sender, _rewards);
    }

    function setRebalanceThreshold(uint256 _threshold) external onlyRole(GUARDIAN_ROLE) {
        if (_threshold > BASE_PRECISION) revert InvalidThreshold();
        uint256 oldThreshold = rebalanceThreshold;
        rebalanceThreshold = _threshold;
        emit ThresholdChanged(msg.sender, oldThreshold, _threshold);
    }

    function setHedgeBias(uint256 _bias) external onlyRole(GUARDIAN_ROLE) {
        // 10% and percision is 1e18
        if (_bias > 0.1 ether) revert InvalidHedgeBias();
        uint256 oldBias = hedgeBias;
        hedgeBias = _bias;
        emit HedgeBiasChanged(msg.sender, oldBias, _bias);
    }

    function setHedgeMultiplier(uint256 _multiplier) external onlyRole(GUARDIAN_ROLE) {
        if (_multiplier > 25) revert InvalidMultiplier();
        uint256 oldMultiplier = hedgeMultiplier;
        hedgeMultiplier = _multiplier;
        emit MultiplierChanged(msg.sender, oldMultiplier, _multiplier);
    }

    function setHedgeAmountDrift(uint256 _driftBp, uint256 _fixed) external onlyRole(GUARDIAN_ROLE) {
        if (_driftBp > PERCENT_DIVISOR) revert InvalidDrift();
        uint256 oldDrift = hedgeAmountDrift;
        hedgeAmountDrift = _driftBp;
        uint256 oldFixedAmount = fixedHedgeAmountDrift;
        fixedHedgeAmountDrift = _fixed;
        emit DriftChanged(msg.sender, oldDrift, _driftBp, oldFixedAmount, _fixed);
    }

    function setExitWeight(uint256 _exitWeight, uint256 _alertWeight) external onlyRole(GUARDIAN_ROLE) {
        uint256 oldExit = exitWeight;
        exitWeight = _exitWeight;
        uint256 oldAlert = alertWeight;
        alertWeight = _alertWeight;
        emit ExitWeightChanged(msg.sender, oldExit, _exitWeight, oldAlert, _alertWeight);
    }

    function setMaxDebtRatio(uint256 _debtRatio) external onlyRole(GUARDIAN_ROLE) {
        // 95% and percision is 1e18
        if (_debtRatio > 0.95 ether) revert InvalidMaxDebtRatio();
        uint256 oldRatio = maxDebtRatio;
        maxDebtRatio = _debtRatio;
        emit MaxDebtRatioChanged(msg.sender, oldRatio, _debtRatio);
    }

    function setSlippage(uint256 _slippage) external onlyRole(GUARDIAN_ROLE) {
        if (_slippage > PERCENT_DIVISOR) revert InvalidSlippage();
        uint256 oldSlippage = slippage;
        slippage = _slippage;
        emit SlippageChanged(msg.sender, oldSlippage, _slippage);
    }

    function getWeight() public view returns (uint256 currentWeight, uint256 derivedWeight) {
        (currentWeight, , ) = glpLens.getExposureWeight(borrowToken);
        uint256 multipler = BASE_PRECISION - hedgeBias;
        uint256 baseWeight = (currentWeight * multipler) / BASE_PRECISION;
        uint256 biasWeight = (hedgeBias * hedgeBias * hedgeMultiplier) / BASE_PRECISION;
        derivedWeight = baseWeight + biasWeight;
    }

    /**
     * @dev claculate hedge amount by given plvGlpAmount
     */
    function calcHedgeAmount(
        uint256 plvGlpAmount,
        uint256 targetWeight
    ) public view returns (uint256 hedgeAmount, uint256 plvGlpPrice, uint256 borrowTokenPrice) {
        if (plvGlpAmount == 0 || targetWeight == 0) {
            return (0, 0, 0);
        }
        plvGlpPrice = _getPriceInEth(plvGLP);
        borrowTokenPrice = _getPriceInEth(borrowToken);
        // borrowTokenAmount = plvGlp_MV * weight / borrow_token_price
        hedgeAmount = (((plvGlpAmount * plvGlpPrice) / BASE_PRECISION) * targetWeight) / borrowTokenPrice;
    }

    function getCurrentPosition()
        public
        view
        returns (uint256 plvGlpBalance, uint256 collateralBalance, uint256 borrowBalance)
    {
        ICToken lplvGlp = ICToken(cTokenMap[plvGLP]);
        ICToken lb = ICToken(cTokenMap[borrowToken]);
        ICToken lc = ICToken(cTokenMap[collateralToken]);

        (, uint256 lplvGlpBalance, , uint256 exchangeRate) = lplvGlp.getAccountSnapshot(address(this));

        plvGlpBalance = (lplvGlpBalance * exchangeRate) / BASE_PRECISION;
        (, uint256 lcBalance, , uint256 lcExchangeRate) = lc.getAccountSnapshot(address(this));
        collateralBalance = (lcBalance * lcExchangeRate) / BASE_PRECISION;
        (, , borrowBalance, ) = lb.getAccountSnapshot(address(this));
    }

    function getDebtRatio() public view returns (uint256 debtRatio) {
        (uint256 plvGlpBal, uint256 cBal, uint256 borrowBal) = getCurrentPosition();
        debtRatio = _calcDebtRatio(plvGlpBal, cBal, borrowBal);
    }

    function getRewards() public view returns (address[] memory) {
        return rewards;
    }

    function getAum() public view returns (uint256 aum) {
        (uint256 plvGlpBal, uint256 cBal, uint256 borrowBal) = getCurrentPosition();
        uint256 plvGlpBalFree = _tokenBalance(plvGLP);
        uint256 plvValue = (plvGlpBalFree + plvGlpBal) * _getPriceInEth(plvGLP);
        uint256 cValue = cBal * _getPriceInEth(collateralToken);
        uint256 borrowValue = borrowBal * _getPriceInEth(borrowToken);
        uint256 aumInEth = (plvValue + cValue - borrowValue) / BASE_PRECISION;
        uint256 ethUsdPriceE30 = (glpLens.getTokenPrice(weth, false) + glpLens.getTokenPrice(weth, true)) / 2;
        aum = (aumInEth * ethUsdPriceE30) / 1e30;
    }

    function shouldRebalance() public view returns (bool rebalance, bool hedge) {
        rebalance = false;
        (uint256 currentWeight, uint256 derivedWeight) = getWeight();
        uint256 lastWeight = lastHedge.weight;
        (uint256 plvGlpBal, , uint256 borrowBal) = getCurrentPosition();
        (uint256 hedgeTarget, , ) = calcHedgeAmount(plvGlpBal, derivedWeight);
        hedge = _shouldHedge(hedgeTarget, borrowBal);
        if (hedge || _shouldDeHedge(hedgeTarget, borrowBal)) {
            rebalance = true;
        }
        uint256 diff = currentWeight > lastWeight ? currentWeight - lastWeight : lastWeight - currentWeight;
        if (diff > rebalanceThreshold) {
            rebalance = true;
        }
    }

    function shouldExit() external view returns (uint256) {
        uint256 signal = 0;
        // 1. debt ratio is too high
        uint256 cDebtRatio = getDebtRatio();
        if (cDebtRatio > maxDebtRatio) {
            signal = 1;
            return signal;
        }

        // 2. GLP risk token weight is too high;
        (uint256 currentWeight, , ) = glpLens.getExposureWeight(borrowToken);
        if (currentWeight >= exitWeight) {
            signal = 2;
            return signal;
        }

        // 3. alertWeight < currentWeight
        if (currentWeight > alertWeight) {
            signal = 3;
            return signal;
        }
        return signal;
    }

    function _deposit() internal {
        uint256 plvGlpAmount = _tokenBalance(plvGLP);
        if (plvGlpAmount > 0) {
            ICErc20 lplvGlp = ICErc20(cTokenMap[plvGLP]);
            lplvGlp.mint(plvGlpAmount);
            emit Deposit(msg.sender, plvGlpAmount);
        }
        _rebalance();
    }

    function _rebalance() internal {
        uint256 borrowAmount = _getBorrow(borrowToken);
        uint256 plvGlpAmount = _getSupply(plvGLP);
        (uint256 currentWeight, uint256 derivedWeight) = getWeight();
        (uint256 hedgeTarget, , ) = calcHedgeAmount(plvGlpAmount, derivedWeight);
        _rebalance(hedgeTarget, borrowAmount);
        _updateHedge(currentWeight, derivedWeight);
    }

    function _rebalance(uint256 _hedgeTarget, uint256 _currentBorrowAmount) internal {
        if (_shouldHedge(_hedgeTarget, _currentBorrowAmount)) {
            _hedge(_hedgeTarget - _currentBorrowAmount);
        } else if (_shouldDeHedge(_hedgeTarget, _currentBorrowAmount)) {
            _reduceHedge(_hedgeTarget, _currentBorrowAmount);
        }
    }

    function _hedge(uint256 _amount) internal {
        address _collateralToken = collateralToken;
        address _borrowToken = borrowToken;
        // borrow
        _borrow(_amount);

        // swap debt to collateral
        if (_borrowToken == weth) {
            IWETH(weth).deposit{ value: address(this).balance }();
        }
        uint256 amountIn = _tokenBalance(_borrowToken);
        _swap(amountIn, _borrowToken, _collateralToken, 0);

        // supply collateral
        uint256 collateralTokenBal = _tokenBalance(_collateralToken);
        _supply(_collateralToken, collateralTokenBal);
        emit HedgeAction(true, _amount, collateralTokenBal);
    }

    function _reduceHedge(uint256 _hedgeTarget, uint256 _totalBorrowAmount) internal {
        uint256 repayAmount = _totalBorrowAmount - _hedgeTarget;
        // redeem collateral and swap to debt token
        uint256 collateralTokenOut = _redeemCollateralToRepay(repayAmount, false);

        // repay debt
        uint256 borrowTokenBal = _tokenBalance(borrowToken);
        repayAmount = borrowTokenBal > _totalBorrowAmount ? _totalBorrowAmount : borrowTokenBal;
        _repay(repayAmount);
        emit HedgeAction(false, borrowTokenBal, collateralTokenOut);
    }

    function _shouldHedge(uint256 _hedgeTarget, uint256 _borrowAmount) internal view returns (bool) {
        _borrowAmount = _borrowAmount + _calcHedgeDrift(_borrowAmount);
        if (_hedgeTarget > _borrowAmount) {
            return true;
        }
        return false;
    }

    function _shouldDeHedge(uint256 _hedgeTarget, uint256 _borrowAmount) internal view returns (bool) {
        if (_hedgeTarget == 0 && _borrowAmount > 0) {
            return true;
        }
        _hedgeTarget = _hedgeTarget + _calcHedgeDrift(_hedgeTarget);
        if (_hedgeTarget < _borrowAmount) {
            return true;
        }
        return false;
    }

    function _calcHedgeDrift(uint256 _hedgeAmount) internal view returns (uint256 diff) {
        uint256 hedgeDiffAmount = (_hedgeAmount * hedgeAmountDrift) / PERCENT_DIVISOR;
        diff = hedgeDiffAmount < fixedHedgeAmountDrift ? hedgeDiffAmount : fixedHedgeAmountDrift;
    }

    function _calcDebtRatio(
        uint256 plvGLPAmount,
        uint256 collateralAmount,
        uint256 borrowAmount
    ) internal view returns (uint256 debtRatio) {
        address _collateralToken = collateralToken;
        address _borrowToken = borrowToken;
        if (borrowAmount == 0) {
            return 0;
        }
        LocalPosition memory _localP = LocalPosition(0, 0, 0, 0, 0, 0, 0);
        _localP.plvGlpFactor = _getCollateralFactor(plvGLP);
        _localP.collateralFactor = _getCollateralFactor(_collateralToken);
        _localP.plvGlpPrice = _getPriceInEth(plvGLP);
        _localP.collateralTokenPrice = _getPriceInEth(_collateralToken);
        _localP.borrowTokenPrice = _getPriceInEth(_borrowToken);

        _localP.totalCollateralValue =
            (((plvGLPAmount * _localP.plvGlpPrice) / BASE_PRECISION) * _localP.plvGlpFactor) /
            BASE_PRECISION +
            (((collateralAmount * _localP.collateralTokenPrice) / BASE_PRECISION) * _localP.collateralFactor) /
            BASE_PRECISION;

        _localP.borrowValue = (borrowAmount * _localP.borrowTokenPrice);

        debtRatio = _localP.borrowValue / _localP.totalCollateralValue;
    }

    function _updateHedge(uint256 _weight, uint256 _derivedWeight) internal {
        uint256 oldWeight = lastHedge.weight;
        uint256 oldAmount = lastHedge.amount;
        uint256 _amount = _getBorrow(borrowToken);
        lastHedge.weight = _weight;
        lastHedge.amount = _amount;
        lastHedge.timestamp = block.timestamp;
        emit Rebalance(msg.sender, oldWeight, _weight, _derivedWeight, oldAmount, _amount, block.timestamp);
    }

    function _tokenBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function _transferTokens(address _token, address _to, uint256 _amount) internal {
        if (_amount > 0) {
            IERC20(_token).transfer(_to, _amount);
        }
    }

    /*********************************************Flashloan functions****************************************************/
    function _flashLoanLogic(bytes memory _data, uint256 _repayAmount) internal override {
        (uint256 requiredAmount, uint256 operation) = abi.decode(_data, (uint256, uint256));
        // repay
        if (operation == 0) {
            _repay(requiredAmount);
            _redeemCollateralToRepay(_repayAmount, true);
        }
    }

    function _redeemCollateralToRepay(uint256 _repayAmount, bool _isFlashRepayAll) internal returns (uint256) {
        address _collateralToken = collateralToken;
        address _borrowToken = borrowToken;
        // calc collateral amount to swap
        uint256 tokenAmountIn = glpLens.quoteTokenOut(_collateralToken, _borrowToken, _repayAmount);
        // swap more
        tokenAmountIn = (tokenAmountIn * (PERCENT_DIVISOR + slippage)) / PERCENT_DIVISOR;
        uint256 collateralTokenBal = _getSupply(_collateralToken);
        if (tokenAmountIn > collateralTokenBal) {
            tokenAmountIn = collateralTokenBal;
        }

        if (_isFlashRepayAll) {
            _redeemAll(plvGLP);
            _redeemAll(_collateralToken);
        } else {
            _redeem(_collateralToken, tokenAmountIn);
        }

        // swap collateral to debt token
        if (_collateralToken == weth) {
            IWETH(weth).deposit{ value: address(this).balance }();
        }
        collateralTokenBal = _tokenBalance(_collateralToken);
        tokenAmountIn = collateralTokenBal > tokenAmountIn ? tokenAmountIn : collateralTokenBal;
        _swap(tokenAmountIn, _collateralToken, _borrowToken, 0);

        uint256 debtTokenAmount = _tokenBalance(_borrowToken);
        if (debtTokenAmount < _repayAmount) {
            uint256 moreRequiredAmount = _repayAmount - debtTokenAmount;
            bool shouldRedeemFromLode = _isFlashRepayAll ? false : true;
            _redeemPlvGlpToToken(_borrowToken, moreRequiredAmount, shouldRedeemFromLode);
        }
        return collateralTokenBal;
    }

    function _flashRepayAll(address _borrowToken) internal {
        uint256 borrowAmount = _getBorrow(_borrowToken);
        if (borrowAmount > 0) {
            bytes memory data = abi.encode(borrowAmount, uint256(0));
            makeBalFlashLoan(_borrowToken, borrowAmount, data);
            (uint256 currentWeight, uint256 derivedWeight) = getWeight();
            _updateHedge(currentWeight, derivedWeight);
        }
    }

    function _redeemPlvGlpToToken(address _token, uint256 _amount, bool _redeemFromLode) internal {
        uint256 plvGlpAmount = glpLens.tokenToPlvGlpMin(_amount, _token);
        // redeem more
        plvGlpAmount = (plvGlpAmount * (PERCENT_DIVISOR + slippage)) / PERCENT_DIVISOR;
        if (_redeemFromLode) {
            _redeem(plvGLP, plvGlpAmount);
        }
        plvGlpHelper.redeemPlvGlpToToken(_token, plvGlpAmount, _amount);
    }

    /*********************************************Lodestar functions****************************************************/
    function _getCollateralFactor(address _token) internal view returns (uint256 collateralFactorMantissa) {
        (, collateralFactorMantissa, ) = comptroller.markets(cTokenMap[_token]);
    }

    /**
     * @dev Returns the accurate current position.
     */
    function _getSupply(address _underlying) internal returns (uint256 supplied) {
        // balanceOfUnderlying is a write function
        supplied = ICToken(cTokenMap[_underlying]).balanceOfUnderlying(address(this));
    }

    function _getBorrow(address _underlying) internal returns (uint256 borrowed) {
        // borrowBalanceCurrent is a write function
        borrowed = ICToken(cTokenMap[_underlying]).borrowBalanceCurrent(address(this));
    }

    function _borrow(uint256 _amount) internal {
        ICErc20 ltoken = ICErc20(cTokenMap[borrowToken]);
        ltoken.borrow(_amount);
    }

    function _repay(uint256 _amount) internal {
        if (borrowToken == weth) {
            IWETH(weth).withdraw(_amount);
            ICEther lether = ICEther(cTokenMap[borrowToken]);
            lether.repayBorrow{ value: _amount }();
        } else {
            ICErc20 ltoken = ICErc20(cTokenMap[borrowToken]);
            ltoken.repayBorrow(_amount);
        }
    }

    function _supply(address _underlying, uint256 _amount) internal {
        if (_underlying == weth) {
            IWETH(weth).withdraw(_amount);
            ICEther lether = ICEther(cTokenMap[_underlying]);
            lether.mint{ value: _amount }();
        } else {
            ICErc20 ltoken = ICErc20(cTokenMap[_underlying]);
            ltoken.mint(_amount);
        }
    }

    function _redeem(address _underlying, uint256 _amount) internal {
        ICErc20 ltoken = ICErc20(cTokenMap[_underlying]);
        ltoken.redeemUnderlying(_amount);
    }

    function _redeemAll(address _underlying) internal {
        ICErc20 ltoken = ICErc20(cTokenMap[_underlying]);
        uint256 shares = _tokenBalance(address(ltoken));
        ltoken.redeem(shares);
    }

    function _getPriceInEth(address _underlying) internal view returns (uint256 priceInEth) {
        priceInEth = IPriceOracle(comptroller.oracle()).getUnderlyingPrice(ICToken(cTokenMap[_underlying]));
    }

    function _claimRewards() internal returns (uint256 rewardAmount) {
        uint256 initBal = _tokenBalance(rewards[0]);
        ICToken[] memory tokens = new ICToken[](3);
        tokens[0] = ICToken(cTokenMap[plvGLP]);
        tokens[1] = ICToken(cTokenMap[collateralToken]);
        tokens[2] = ICToken(cTokenMap[borrowToken]);

        IComptroller(comptroller).claimComp(address(this), tokens);
        uint256 newBal = _tokenBalance(rewards[0]);
        rewardAmount = newBal - initBal;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGLPLens {
    function getExposureWeight(
        address riskToken
    ) external view returns (uint256 riskTokenWeight, uint256 totalUsdgExposure, uint256 adjustedUsdgSupply);

    function quoteTokenOut(
        address _sellToken,
        address _wantToken,
        uint256 _wantAmount
    ) external view returns (uint256 sellTokenAmount);

    function tokenToPlvGlpMin(uint256 _amount, address _token) external view returns (uint256);

    function getTokenPrice(address _token, bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPlvGLPHelper {
    function mintPlvGlp(address _token, uint256 _amount, uint256 _minGlp) external returns (uint256);

    function redeemPlvGlpToToken(address _token, uint256 _plvGlpAmount, uint256 _minRecive) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICamelotRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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

interface ICEther is ICToken {
    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable returns (uint256);

    function liquidateBorrow(address borrower, ICToken cTokenCollateral) external payable returns (uint256);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}