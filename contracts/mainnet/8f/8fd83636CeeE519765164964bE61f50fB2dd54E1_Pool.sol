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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.9.6) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 0x20)
            let dataPtr := data
            let endPtr := add(data, mload(data))

            // In some cases, the last iteration will read bytes after the end of the data. We cache the value, and
            // set it to zero to make sure no dirty bytes are read in that section.
            let afterPtr := add(endPtr, 0x20)
            let afterCache := mload(afterPtr)
            mstore(afterPtr, 0x00)

            // Run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 byte (24 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F to bitmask the least significant 6 bits.
                // Use this as an index into the lookup table, mload an entire word
                // so the desired character is in the least significant byte, and
                // mstore8 this least significant byte into the result and continue.

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // Reset the value that was cached
            mstore(afterPtr, afterCache)

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/// @notice Struct that store information about a battle position
struct BattlePosition {
    /// @param battleId The unique identifier of the battle position
    uint256 battleId;
    /// @param poolId is the poolId of the battle pool the position is part of
    uint256 poolId;
    /// @param amount is the wagered amount of the battle position
    uint256 amount;
    /// @param direction of the battle position
    uint256 direction;
    /// @param collection of the battle position
    address collection;
    /// @param openedBlock is the opening timestamp of the battle position
    uint256 openedBlock;
    /// @param feePaid are the fees paid on the battle position
    uint256 feePaid;
}

/**
 @title Battle is an ERC721 contract, that stores information about opened battle positions in the form of NFTs.
        Users can mint new battle positions by engaging with the Pool.sol contract, or by trading battle position NFTs via the Market.sol marketplace.
*/
/// @dev Owning a battle NFT holds the right to claim the payout that is associated with the battle position.
contract Battle is ERC721, Ownable {
    using Strings for uint256;
    using Strings for uint8;

    /// @notice This pool address governs the battle NFTs
    address public poolContract;

    /// @notice This mapping maps battleIds to URIs
    mapping(uint256 => string) internal _tokenURIs;

    /// @notice This mapping maps battleIds to BattlePosition structs
    mapping(uint256 => BattlePosition) public battleIdToBattlePosition;

    /// @notice Event emitted after a battle position has been entered
    event JuicyBattle_BattleEntered(
        address _owner,
        uint256 _direction,
        uint256 indexed _battleId,
        uint256 indexed _poolId,
        uint256 _openedBlock,
        uint256 _amount,
        uint256 _feePaid,
        uint256 _end
    );

    error TokenIdNotExistent(uint256 battleId);
    error OnlyPoolContract();

    /// @notice This modifier makes sure that only addresses the pool contract can access functions
    modifier onlyPoolContract() {
        if (msg.sender != poolContract) {
            revert OnlyPoolContract();
        }
        _;
    }

    /// @notice This modifier maker sure that the battleId exists
    modifier onlyExistingId(uint256 battleId) {
        if (!_exists(battleId)) {
            revert TokenIdNotExistent(battleId);
        }
        _;
    }

    constructor() ERC721("JuicyPosition", "JCP") {}

    /// @notice This function sets the pool contract once
    /// @dev This can't be changed in the future since battle and pool should be fused together forever
    /// @param _poolContract The address of the pool contract
    function setPoolContract(address _poolContract) public onlyOwner {
        if (_poolContract == address(0)) {
            revert("Pool contract cannot be the zero address");
        }
        if (poolContract != address(0)) {
            revert("Pool contract already set");
        }
        poolContract = _poolContract;
    }

    /// @notice This function mints a new battle position to the owner
    /// @dev Can only be called by the pool contract
    /// @param owner The owner of the battle NFT
    /// @param position The battle position that holds the information for the battle position
    function mint(address owner, uint256 end, BattlePosition calldata position) external onlyPoolContract {
        battleIdToBattlePosition[position.battleId] = position;
        _safeMint(owner, position.battleId);
        emit JuicyBattle_BattleEntered(
            owner,
            position.direction,
            position.battleId,
            position.poolId,
            position.openedBlock,
            position.amount,
            position.feePaid,
            end
        );
    }

    /// @dev This function is included to potentially support NFT marketplaces like Blur, opensea etc.
    /// @return The token URI of the NFT
    /// @param battleId of the NFT
    function getTokenURI(uint256 battleId) public view onlyExistingId(battleId) returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "JuicyPerp Battle Position #',
            battleId.toString(),
            '",',
            '"description": "This NFT represents a position in an NFT battle on juicyperp.xyz. Once the battle has concluded the owner can claim the rewards if he won or the NFT becomes worthless in case the battle was lost.",',
            '"image": "',
            _generateSvg(battleId),
            '"',
            "}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    /// @return The token URI of the NFT
    /// @param battleId of the battle NFT
    function tokenURI(uint256 battleId) public view virtual override returns (string memory) {
        return getTokenURI(battleId);
    }

    /// @notice Burn the a battle position NFT for id battleId
    /// @param battleId of the battle NFT to burn
    function burn(uint256 battleId) public onlyPoolContract {
        _burn(battleId);
    }

    /// @notice Getter poolId
    /// @param battleId the id of the battle NFT
    /// @return The poolId associated with the battleId
    function getPoolId(uint256 battleId) external view onlyExistingId(battleId) returns (uint256) {
        return battleIdToBattlePosition[battleId].poolId;
    }

    /// @notice Getter opened timestamp
    /// @param battleId the id of the battle NFT
    /// @return The opened timestamp associated with the battleId
    function getOpenedBlock(uint256 battleId) external view onlyExistingId(battleId) returns (uint256) {
        return battleIdToBattlePosition[battleId].openedBlock;
    }

    /// @notice Getter amount
    /// @param battleId the id of the battle NFT
    /// @return The wager amount associated with the battleId
    function getAmount(uint256 battleId) external view onlyExistingId(battleId) returns (uint256) {
        return battleIdToBattlePosition[battleId].amount;
    }

    /// @notice Getter direction
    /// @param battleId the id of the battle NFT
    /// @return The direction associated with the battleId
    function getDirection(uint256 battleId) external view onlyExistingId(battleId) returns (uint256) {
        return battleIdToBattlePosition[battleId].direction;
    }

    /// @notice Getter direction string
    /// @param battleId the id of the battle NFT
    /// @return The direction as string associated with the battleId
    function getDirectionString(uint256 battleId) external view onlyExistingId(battleId) returns (string memory) {
        return _directionToString(battleIdToBattlePosition[battleId].direction);
    }

    /// @notice Getter collection
    /// @param battleId the id of the battle NFT
    /// @return The collection associated with the battleId
    function getNftCollection(uint256 battleId) external view onlyExistingId(battleId) returns (address) {
        return battleIdToBattlePosition[battleId].collection;
    }

    /// @notice Getter battle position struct
    /// @param battleId the id of the battle NFT
    /// @return The battle struct with the battleId
    /// @dev battleId == battleId
    function getBattlePosition(
        uint256 battleId
    ) external view onlyExistingId(battleId) returns (BattlePosition memory) {
        return battleIdToBattlePosition[battleId];
    }

    /// @notice Turn direction into string
    /// @param direction which can be 0 or 1
    /// @return The direction as string representation
    function _directionToString(uint256 direction) internal pure returns (string memory) {
        if (direction == 0) {
            return "long";
        }
        if (direction == 1) {
            return "short";
        }
        return "error";
    }

    /// @notice Convert address to string
    /// @param x is the address that is converted to string
    /// @return The input address as string
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    /// @notice Convert byte to character
    /// @return c that is input as char
    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /// @return A simple SVG for the battle position NFT
    /// @param battleId of the NFT
    function _generateSvg(uint256 battleId) internal view returns (string memory) {
        BattlePosition memory position = battleIdToBattlePosition[battleId];

        /// @dev this is split up and then combined so the stack does not get too deep
        bytes memory svg1 = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 12px; }</style><rect width="100%" height="100%" fill="#FCBBE0" /><text x="50%" y="30%" class="base" dominant-baseline="middle" text-anchor="middle"> Position for Pool ',
            position.poolId.toString(),
            '</text><text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle"> Collection: ',
            toAsciiString(position.collection)
        );
        bytes memory svg2 = abi.encodePacked(
            '</text> <text x="50%" y="45%" class="base" dominant-baseline="middle" text-anchor="middle"> Amount: ',
            position.amount.toString(),
            '</text><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle"> Direction: ',
            _directionToString(position.direction)
        );

        bytes memory svg3 = abi.encodePacked(
            '</text><text x="50%" y="55%" class="base" dominant-baseline="middle" text-anchor="middle"> Opened Block: ',
            position.openedBlock.toString(),
            "</text></svg>"
        );

        bytes memory svg = abi.encodePacked(svg1, svg2, svg3);

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

/// @title PricingService is an interface that defines the functionality a pricing service should hold
interface IPricingService {
    /// @notice Returns the price of a specific asset identified by an address
    /// @return The price of the requested asset
    function getLatestPrice(address, bytes[] calldata) external payable returns (int256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {PricingRouter} from "./PricingRouter.sol";
import {Battle} from "./Battle.sol";
import {BattlePosition} from "./Battle.sol";

/// @title Pool manages everything from battle pool creation, payouts, fee management, and the minting of new battle position NFTs.
contract Pool is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Pay-in time of a battle pool
    mapping(address => uint256) public PAY_IN_DURATION;
    /// @notice Duration of a battle pool
    mapping(address => uint256) public BATTLE_DURATION;

    /// @notice Whitelist for the available collections to battle on in community owned battles
    mapping(address => bool) public whitelistedCollections;
    /// @notice Whitelist for the available token contracts for community owned battles
    mapping(address => bool) public whitelistedTokens;
    /// @notice Whitelist for users that are eligible to place battles
    mapping(address => bool) public whitelistedUsers;

    /// @notice uint flag that manages whether a user whitelist is active
    /// @dev 0 means no whitelist is active, 1 means a whitelist is active managed by whitelistedUsers mapping, and 2 means that no user is whitelisted and no battles can be entered
    uint256 public whiteListMode = 1;

    /// @notice Whitelist for the available collections to battle on in perpetual battles
    mapping(address => bool) public availableCollections;
    /// @notice Bool flag whether the market maker incentive is active for a certain collection
    mapping(address => bool) public marketMakerIncentive;

    /// @notice Timestamp when a duration change should come into effect
    /// @dev This is set in the update collection template and is done to not change pool durations while in the middle of an active pool
    mapping(address => uint256) public durationChangeBlock;
    /// @notice The next battle duration that should come into affect
    mapping(address => uint256) public nextBattleDuration;
    /// @notice The next battle pay in time that should come into affect
    mapping(address => uint256) public nextBattlePayIn;
    /// @notice The next market maker incentive in time that should come into affect for collection
    mapping(address => bool) public nextMarketMakerIncentive;
    /// @notice  Bool flag if there will be a duration change in the next pool cycle
    mapping(address => bool) public durationChange;

    /// @notice Mapping from fee index to Fee structure
    mapping(uint256 => FeeStructure) public feeIndexToFee;
    /// @notice Mapping from poolId to feeIndex
    mapping(uint256 => uint256) public poolIdToFeeIndex;

    /// @notice Contract of the battles
    Battle public immutable battleContract;
    /// @notice Price router contract
    PricingRouter public immutable priceRouter;

    /// @notice Mapping of poolId to BattlePool
    mapping(uint256 => BattlePool) public poolIdToPool;
    /// @notice Mapping of poolId to token contract
    mapping(uint256 => address) public poolIdToTokenContract;
    /// @notice Mapping of poolId to market maker incentive bool flag
    mapping(uint256 => bool) public poolIdToMarketMakerIncentive;
    /// @notice Mapping of startBlock and NFT collection address exists to poolID
    mapping(uint256 => mapping(address => uint256)) public characteristicsToPoolId;
    /// @notice Mapping the poolId to the fee modifier
    mapping(uint256 => uint256) public poolIdToPoolFeeModify;

    /// @notice Mapping that stores the collected fees for an address and a specific token contract
    /// @dev Fees can be collected for multiple ERC20 tokens
    mapping(address => mapping(address => uint256)) private feesForPoolOwner;

    /// @notice Global poolId counter
    /// @dev Increments once a new pool is created
    uint256 private _poolId = 1;

    /// @notice Global battleId counter
    /// @dev Increments once a new battle is created
    uint256 private _battleId = 1;

    /// @notice Global feeIndex counter
    /// @dev Increments once a new fee structure is created
    uint256 private _feeIndex = 1;

    /// @notice The admins address
    /// @dev This is set at the constructor
    address private immutable SUPER_ADMIN_ADDRESS;
    /// @notice The super admin role
    bytes32 private constant SUPER_ADMIN = keccak256("SUPER");
    /// @notice The owner role
    bytes32 private constant OWNER = keccak256("OWNER");
    /// @notice The pool creator role
    /// @dev Addresses with this role can create pools
    bytes32 private constant POOL_CREATOR = keccak256("POOL_CREATOR");
    /// @notice The role that is able to whitelist trader wallets
    /// @dev Addresses with this role can whitelist trader wallets
    bytes32 private constant WHITE_LISTER = keccak256("WHITE_LISTER");
    /// @notice The minimum wager amount
    uint256 private constant MIN_AMOUNT = 10000;
    /// @notice 100% in BIPs
    uint256 private constant TEN_THOUSAND_BIPS = 10000;

    /// @notice The Standard WETH address of the contract
    address private immutable WETH_CONTRACT;

    /// @notice Struct that represents a battle position
    struct BattlePool {
        /// @param collection is the underlying collection (eg. NFT collection) the battle pool
        address collection;
        /// @param closed status of the pool
        bool closed;
        /// @param payInDuration of the pool
        uint256 payInDuration;
        /// @param strike price of the pool => Will be set after the pay in time has elapsed
        int256 strike;
        /// @param start is the timestamp of the start of the pool
        uint256 start;
        /// @param end is the timestamp of the end of the pool
        uint256 end;
        /// @param shortCollateral is the amount of liquidity on the short side of the pool
        uint256 shortCollateral;
        /// @param longCollateral is the amount of liquidity on the long side of the pool
        uint256 longCollateral;
        /// @param makerCollateral is the amount of liquidity that qualifies for market maker benefits
        uint256 makerCollateral;
        /// @param takerFees is the amount of fees accrued in the pool
        uint256 takerFees;
        /// @param liquidationPrice is the price at which the pool is resolved after it ends
        int256 liquidationPrice;
        /// @param owner is the owner of the pool
        address owner;
    }

    /// @notice Struct that represents a Fee structure
    struct FeeStructure {
        /// @param feeComp1 is the fee in BIP at the end of the pay in time
        uint256 feeComp1;
        /// @param feeComp2 is the fee in BIP at the last 10% of the pay in time
        uint256 feeComp2;
        /// @param feeComp3 is the fee in BIP at the beginning of the pay in time
        uint256 feeComp3;
        /// @param marketMakerSplit is the market maker fee split in BIP
        uint256 marketMakerSplit;
        /// @notice Cutoff ratio for market makers
        /// @dev If a user makes a paying at the first 10% of a pools pay in time they are eligible for market making incentives
        uint256 marketMakerCutoff;
    }

    /// @notice Event published, when a new battle pool has been created
    event JuicyBattle_PoolCreated(
        uint256 indexed _poolId,
        address indexed _collection,
        uint256 _end,
        uint256 _start,
        uint256 _payInDuration,
        address _poolOwner,
        address _tokenContract,
        uint256 _feeModifier,
        bool _marketMakerIncentive
    );

    /// @notice Event published, when a new battle position has been claimed
    event JuicyBattle_BattleClaimed(uint256 indexed _battleId, uint256 _amount, address from);

    /// @notice Event published, when a new the strike price of a battle pool has been updated
    event JuicyBattle_StrikeUpdated(uint256 indexed _poolId, int256 _strike);

    /// @notice Event published, when a new the strike price of a battle pool has been liquidated
    event JuicyBattle_PoolLiquidated(uint256 indexed _poolId, int256 _liquidationPrice);

    /// @notice Event published, when the base fee of the protocol changes
    event JuicyBattle_ChangedBaseFee(
        uint256 _feeIndex,
        uint256 _feeComp1,
        uint256 _feeComp2,
        uint256 _feeComp3,
        uint256 _marketMakerSplit,
        uint256 _marketMakerCutoff
    );

    /// @notice Event published, when a collection template was updated
    event JuicyBattle_CollectionTemplateUpdated(
        address indexed collection,
        uint256 payInDuration,
        uint256 duration,
        bool marketMakerIncentive
    );

    /// @notice Event published, when a user gets whitelisted
    event JuicyBattle_UserWhitelistedStatusChanged(address _user, bool _status);
    /// @notice Event published, when a token gets whitelisted
    event JuicyBattle_TokenWhitelistedStatusChanged(address _token, bool _status);
    /// @notice Event published, when a collection gets whitelisted
    event JuicyBattle_CollectionWhitelistedStatusChanged(address _collection, bool _status);
    /// @notice Event published, when the whitelist mode changed
    event JuicyBattle_WhitelistedModeChanged(uint256 _mode);

    /// @notice error thrown when trying to renounce role
    error NoRoleRenounce();
    /// @notice error thrown when input value is too high
    error ValueTooHigh(string message);
    /// @notice error thrown when input value is too low
    error ValueTooLow(string message);
    /// @notice error thrown when input is invalid
    error InvalidInput(string message);
    /// @notice error thrown when asset / token is not available
    error NotAvailable(string message);
    /// @notice error thrown a pool does not exist
    error PoolDoesNotExist();
    /// @notice error thrown when an action is not allowed
    error ActionNotAllowed(string message);
    /// @notice error thrown when request expired
    error ExpiredRequest();

    constructor(address _priceRouter, address _wethAddress, address _battleContract, address _superAdminAddress) {
        priceRouter = PricingRouter(_priceRouter);
        WETH_CONTRACT = _wethAddress;
        battleContract = Battle(_battleContract);

        /// @dev Set the super admin address
        SUPER_ADMIN_ADDRESS = _superAdminAddress;
        /// @dev Set default fee structure
        feeIndexToFee[_feeIndex] = FeeStructure(550, 350, 200, 5000, 1000);
        /// @dev create and assign roles
        /// @dev super admin will be a multisig address
        _grantRole(SUPER_ADMIN, _superAdminAddress);
        _grantRole(OWNER, msg.sender);

        _setRoleAdmin(OWNER, SUPER_ADMIN);
        _setRoleAdmin(POOL_CREATOR, OWNER);
        _setRoleAdmin(WHITE_LISTER, OWNER);
    }

    /// @dev Override the `renounceRole` to prevent role renunciation
    /// @dev This is added so the hardcoded super admin can't lose its role
    function renounceRole(bytes32 /*role*/, address /*account*/) public pure override {
        revert NoRoleRenounce();
    }

    /// @notice Returns the start timestamp of the next battle pool
    /// @dev The start block is not the beginning of the pay in time of the battle pool, but the start of the "locked" period. The pay in phase happens before the start block.
    /// @param collection The collection whose start block is requested
    function getNextStartBatchBlock(address collection) public view returns (uint256) {
        return block.timestamp + (PAY_IN_DURATION[collection] - (block.timestamp % PAY_IN_DURATION[collection]));
    }

    /// @notice Returns the current floor price from the price router
    /// @param collection The collection whose price is requested
    /// @param priceUpdateData Update data for pyth oracle
    function getPriceOfCollection(
        address collection,
        bytes[] calldata priceUpdateData
    ) public payable returns (int256) {
        return priceRouter.getLatestPrice{value: msg.value}(collection, priceUpdateData);
    }

    /// @notice Sets new default fee components and market maker fee split
    /// @dev This is new fee structure is activated once a new pool is created in the contract
    /// @param comp1 The fee at the beginning of the pay in period (in BIPs)
    /// @param comp2 The fee at 90% of the pay in period (in BIPs)
    /// @param comp3 The fee at the end of the pay in period (in BIPs)
    /// @param marketMakerSplitBIP The fee split market makers receive (in BIPs)
    function setFeeComponents(
        uint256 comp1,
        uint256 comp2,
        uint256 comp3,
        uint256 marketMakerSplitBIP,
        uint256 marketMakerCutoff
    ) external onlyRole(OWNER) {
        if (!(comp1 > comp2 && comp2 > comp3)) {
            revert ValueTooHigh("Components have to be in descending order");
        }
        if (comp1 > 2000) {
            revert ValueTooHigh("Component1 can't be higher than 20%");
        }
        if (marketMakerSplitBIP > TEN_THOUSAND_BIPS) {
            revert ValueTooHigh("Split can't be bigger than 10000 BIP!");
        }
        if (marketMakerCutoff > 5000) {
            revert ValueTooHigh("Cutoff can't be bigger than 50% of pay-in time");
        }
        _feeIndex++;
        feeIndexToFee[_feeIndex] = FeeStructure(comp1, comp2, comp3, marketMakerSplitBIP, marketMakerCutoff);
        emit JuicyBattle_ChangedBaseFee(_feeIndex, comp1, comp2, comp3, marketMakerSplitBIP, marketMakerCutoff);
    }

    /// @notice Add or update a collection template for the perpetually opening battle pools
    /// @dev Collections that are registered as templates open up perpetually every payInDuration
    /// @dev If a template for this collection already exists, the pay in and duration can be modified
    /// @param collection The collection the template is about
    /// @param payInDuration The desired duration of the pay in time (in seconds)
    /// @param payInMultiple The desired multiple of the pay in time, that will determine the duration of the pool
    /// @param _marketMakerIncentive The bool whether market makers shall be incentivized in this pool or not.
    function updateCollectionTemplate(
        address collection,
        uint256 payInDuration,
        uint256 payInMultiple,
        bool _marketMakerIncentive
    ) external onlyRole(OWNER) {
        if (payInDuration < 10) {
            revert ValueTooLow("Pay in time must be greater equal to 10");
        }
        if (payInMultiple == 0) {
            revert ValueTooLow("Pay in multiple must be greater 0");
        }
        if (!availableCollections[collection]) {
            /// @dev Add new collection if template has not been set before
            availableCollections[collection] = true;
            BATTLE_DURATION[collection] = payInDuration * payInMultiple;
            PAY_IN_DURATION[collection] = payInDuration;
            marketMakerIncentive[collection] = _marketMakerIncentive;
        } else {
            /// @dev Register a new duration / pay in time scheme for template => Will update when "old" pay in window closes
            durationChange[collection] = true;
            nextBattleDuration[collection] = payInDuration * payInMultiple;
            nextBattlePayIn[collection] = payInDuration;
            nextMarketMakerIncentive[collection] = _marketMakerIncentive;
            /// @dev Timestamp when duration change should be activated
            durationChangeBlock[collection] = getNextStartBatchBlock(collection);
        }
        emit JuicyBattle_CollectionTemplateUpdated(
            collection,
            payInDuration,
            payInDuration * payInMultiple,
            _marketMakerIncentive
        );
    }

    /// @notice This function removes a template for a perpetually opening battle
    /// @param collection The collection whose template shall be removed
    function removeCollectionTemplate(address collection) external onlyRole(OWNER) {
        availableCollections[collection] = false;
        durationChange[collection] = false;
        nextBattleDuration[collection] = 0;
        nextMarketMakerIncentive[collection] = false;
        nextBattlePayIn[collection] = 0;
    }

    /// @notice This function adds or removes collections from the whitelist
    /// @param collection is the collection / asses for which the whitelist is modified
    /// @param status is the bool flag for the whitelist
    function setCollectionWhitelist(address collection, bool status) external onlyRole(OWNER) {
        whitelistedCollections[collection] = status;
        emit JuicyBattle_CollectionWhitelistedStatusChanged(collection, status);
    }

    /// @notice This function adds or removes token contracts from the whitelist
    /// @param token is the token contract for which the whitelist is modified
    /// @param status is the bool flag for the whitelist
    function setTokenWhitelist(address token, bool status) external onlyRole(OWNER) {
        whitelistedTokens[token] = status;
        emit JuicyBattle_TokenWhitelistedStatusChanged(token, status);
    }

    /// @notice This function adds or removes token contracts from the whitelist
    /// @param user is the user for which the whitelist is modified
    /// @param status is the bool flag for the whitelist
    function setUserWhitelist(address user, bool status) external onlyRole(WHITE_LISTER) {
        whitelistedUsers[user] = status;
        emit JuicyBattle_UserWhitelistedStatusChanged(user, status);
    }

    /// @notice This function sets the whitelist active flag that manages whether a user whitelist is active
    /// @param mode is the whitelist mode (0 is inactive, 1 is active, 2 is nobody is whitelisted)
    function setUserWhitelistMode(uint256 mode) external onlyRole(OWNER) {
        if (mode > 2) {
            revert("Mode can only be 0, 1, 2");
        }
        whiteListMode = mode;
        emit JuicyBattle_WhitelistedModeChanged(mode);
    }

    /// @notice This function creates a new pool. Can only be called by a wallet with the pool creator role
    /// @param collection The collection for which the pool is created
    /// @param tokenContract The currency of the pool
    /// @param start The start timestamp of the pool
    /// @param duration The duration of the pool in seconds
    /// @param payInDuration The pay in of the pool in seconds
    /// @param feeMod The fee modifier of the pool
    /// @param _marketMakerIncentive The bool whether market makers shall be incentivized in this pool or not.
    function createPool(
        address collection,
        address tokenContract,
        uint256 start,
        uint256 duration,
        uint256 payInDuration,
        uint256 feeMod,
        bool _marketMakerIncentive
    ) external onlyRole(POOL_CREATOR) returns (uint256) {
        if (!whitelistedCollections[collection]) {
            revert NotAvailable("Collection is not whitelisted!");
        }
        if (!whitelistedTokens[tokenContract]) {
            revert NotAvailable("Token contract is not whitelisted!");
        }
        return
            _createPool(
                collection,
                tokenContract,
                start,
                duration,
                payInDuration,
                msg.sender,
                feeMod,
                _marketMakerIncentive
            );
    }

    /// @notice Enter a battle into a specific pool with poolId
    /// @param poolId The pool that is entered
    /// @param amount The desired wager amount
    /// @param direction The direction of the battle entry (0=LONG; 1=SHORT)
    /// @param priceUpdateData Update data for pyth oracle
    function enterBattle(
        uint256 poolId,
        uint256 amount,
        uint256 direction,
        bytes[] calldata priceUpdateData
    ) public payable nonReentrant {
        /// @dev check if user is whitelisted to enter a battle
        if (whiteListMode == 2 || (whiteListMode == 1 && !whitelistedUsers[msg.sender])) {
            revert("You are not whitelisted");
        }
        /// @dev check if battle has minimum wager amount
        if (amount < MIN_AMOUNT) {
            revert ValueTooLow("Amount has to be at least one gwei");
        }
        /// @dev Direction can only be 1 or 0 (1=SHORT; 0=LONG)
        if (direction > 1) {
            revert InvalidInput("Direction can only be 1 or 0");
        }
        BattlePool memory pool = poolIdToPool[poolId];
        /// @dev Check if pool exists
        if (!poolExists(poolId)) {
            revert PoolDoesNotExist();
        }
        /// @dev Check if pay in is open already
        if (pool.start - pool.payInDuration > block.timestamp) {
            revert ActionNotAllowed("Pay-in time has not started yet!");
        }
        /// @dev Check if the start has not passed yet
        if (block.timestamp >= pool.start) {
            revert ActionNotAllowed("Battle already started");
        }

        /// @dev the fees paid for the battle
        uint256 feePaid = 0;
        uint256 feeIndex = poolIdToFeeIndex[poolId];
        FeeStructure memory feeStructure = feeIndexToFee[feeIndex];
        /// @dev Register the collateral as market maker collateral if it falls in the market maker time frame
        if (
            poolIdToMarketMakerIncentive[poolId] &&
            block.timestamp <
            pool.start - pool.payInDuration + (pool.payInDuration * feeStructure.marketMakerCutoff) / TEN_THOUSAND_BIPS
        ) {
            poolIdToPool[poolId].makerCollateral += amount;
        } else {
            /// @dev Calculate the fee the battle opener has to pay and add it to the taker fee counter of the pool => Only if not in the market maker time slot
            uint256 fee = returnFee(
                pool.start,
                block.timestamp,
                pool.payInDuration,
                poolIdToPoolFeeModify[poolId],
                feeIndex
            );
            feePaid = (amount * fee) / TEN_THOUSAND_BIPS;
            poolIdToPool[poolId].takerFees += feePaid;
        }

        /// @dev Update battle strike price
        if (pool.strike == 0) {
            /// @dev Fetch current price from the price router
            int256 currentPrice = getPriceOfCollection(pool.collection, priceUpdateData);
            poolIdToPool[poolId].strike = currentPrice;
            emit JuicyBattle_StrikeUpdated(poolId, currentPrice);
        }

        /// @dev Here the liquidly (net of fees) of the newly created BattlePosition is added to the BattlePool.
        if (direction == 0) {
            poolIdToPool[poolId].longCollateral += amount - feePaid;
        } else {
            poolIdToPool[poolId].shortCollateral += amount - feePaid;
        }

        /// @dev safe the current battleId in memory
        uint256 newBattleId = _battleId;

        /// @dev Incrementing the battle_id counter.
        _battleId++;

        /// @dev Transfer amount in pool specific token
        IERC20(poolIdToTokenContract[poolId]).safeTransferFrom(msg.sender, address(this), amount);

        /// @dev Mint the battle to the battle owner
        battleContract.mint(
            msg.sender,
            pool.end,
            BattlePosition(newBattleId, poolId, amount, direction, pool.collection, block.timestamp, feePaid)
        );
    }

    /// @notice With this function a caller enters in a collection battle, that is "perpetually" opening every PAY_IN_DURATION blocks
    /// @param collection The collection that is battled
    /// @param amount The desired wager amount
    /// @param direction The direction of the battle entry (0=LONG; 1=SHORT)
    /// @param validUntil Timestamp until the transaction needs to be executed the latest before it reverts
    /// @param priceUpdateData Update data for pyth oracle
    function enterBattleForCollection(
        address collection,
        uint256 amount,
        uint256 direction,
        uint256 validUntil,
        bytes[] calldata priceUpdateData
    ) external payable {
        /// @dev check if user is whitelisted to enter a battle
        if (whiteListMode == 2 || (whiteListMode == 1 && !whitelistedUsers[msg.sender])) {
            revert("You are not whitelisted");
        }
        /// @dev revert when validUntil expired
        if (validUntil < block.timestamp) {
            revert ExpiredRequest();
        }
        /// @dev Verify that collection is available for battling
        if (!availableCollections[collection]) {
            revert NotAvailable("This collection is not available for battling!");
        }
        if (amount < MIN_AMOUNT) {
            revert ValueTooLow("Amount has to be at least one gwei");
        }
        /// @dev Direction can only be 1 or 0 (1=SHORT; 0=LONG)
        if (direction > 1) {
            revert InvalidInput("Direction can only be 1 or 0");
        }
        /// @dev Start timestamp of the battle
        uint256 nextStartBlock = getNextStartBatchBlock(collection);
        /// @dev Get poolId of the battle pool (as identified by start block and collection)
        uint256 poolId = characteristicsToPoolId[nextStartBlock][collection];
        if (poolId == 0) {
            /**
          * @dev  If an duration change is intended, the change is triggered here
                  => This is always triggered by the first person who enters a battle in the new cycle
        */
            if (durationChange[collection] && durationChangeBlock[collection] <= block.timestamp) {
                nextStartBlock = triggerDurationChange(collection);
            }
            poolId = _createPerpetualPool(collection, nextStartBlock);
            /**
          * @dev  The pool_id is stored in a mapping that maps the start block of the battle and the NFT collection to the id. 
                  This is possible, because start block and NFT collection are alway unique for every BattlePool created.
        */
            characteristicsToPoolId[nextStartBlock][collection] = poolId;
        }
        /// @dev Enter battle for the poolId
        enterBattle(poolId, amount, direction, priceUpdateData);
    }

    /// @notice This function liquidates a BattlePool.
    /// @dev Liquidating means, the liquidation price is set, that determine the payouts of the BattlePositions in the BattlePool.
    /// @dev The liquidation function can be called by anyone, after the BattlePools end block has been reached.
    /// @param poolId The pool that should be liquidated
    /// @param priceUpdateData Update data for pyth oracle
    function liquidatePool(uint256 poolId, bytes[] calldata priceUpdateData) external payable nonReentrant {
        /// @dev Make sure that the BattlePool exists.
        if (!poolExists(poolId)) {
            revert PoolDoesNotExist();
        }
        BattlePool memory pool = poolIdToPool[poolId];
        /// @dev Make sure that the BattlePool reached the end block.
        if (pool.end > block.timestamp) {
            revert ActionNotAllowed("BattlePool is has not expired yet!");
        }
        /// @dev Make sure that the BattlePool has not already been liquidated.
        if (pool.closed != false) {
            revert ActionNotAllowed("Liquidation price is already set");
        }

        /// @dev Attempt to set the liquidation price
        /// @dev If the call reverts because of data staleness, the liquidation price is set to the pool strike, which means users get their wagers refunded
        int256 liquidationPrice;
        try priceRouter.getLatestPrice{value: msg.value}(pool.collection, priceUpdateData) returns (int256 price) {
            liquidationPrice = price;
        } catch Error(string memory reason) {
            if (keccak256(bytes(reason)) == keccak256(bytes("FloorStale"))) {
                liquidationPrice = pool.strike;
            } else {
                revert(reason);
            }
        }
        pool.liquidationPrice = liquidationPrice;

        /// @dev Set the status of the BattlePool as closed.
        pool.closed = true;
        /// @dev Write the updated pool back to storage in a single operation
        poolIdToPool[poolId] = pool;
        /// @dev Transfer the pool owners fee share to the owners fee counter
        uint256 marketMakerSplit = feeIndexToFee[poolIdToFeeIndex[poolId]].marketMakerSplit;
        address poolTokenAddress = poolIdToTokenContract[poolId];

        if (pool.makerCollateral > 0) {
            uint256 marketMakerFeeShare = (pool.takerFees * marketMakerSplit) / TEN_THOUSAND_BIPS;
            feesForPoolOwner[pool.owner][poolTokenAddress] += pool.takerFees - marketMakerFeeShare;
        } else {
            /// @dev If there where no market makers active transfer all fees to pool owner account
            feesForPoolOwner[pool.owner][poolTokenAddress] += pool.takerFees;
        }
        emit JuicyBattle_PoolLiquidated(poolId, liquidationPrice);
    }

    /// @notice This function lets the caller withdraw the payout from one or multiple owned BattlePositions
    /// @param battleIds Array of battleIds that shall be claimed
    function claimPayout(uint256[] calldata battleIds) external nonReentrant {
        /// @dev Iterate over all battleIds in battleIds
        for (uint256 i = 0; i < battleIds.length; i++) {
            uint256 battleId = battleIds[i];
            if (battleContract.ownerOf(battleId) != msg.sender) {
                revert ActionNotAllowed("You are not the battle owner!");
            }
            BattlePosition memory battlePosition = battleContract.getBattlePosition(battleId);
            BattlePool memory pool = poolIdToPool[battlePosition.poolId];
            FeeStructure memory feeStructure = feeIndexToFee[poolIdToFeeIndex[battlePosition.poolId]];
            /// @dev Check if the corresponding BattlePool has been liquidated before
            if (pool.closed != true) {
                revert ActionNotAllowed("Pool is still open!");
            }
            uint256 claimAmount = 0;
            /// @dev Check if position was market maker eligible
            bool marketMaker = poolIdToMarketMakerIncentive[battlePosition.poolId] &&
                battlePosition.openedBlock <
                pool.start -
                    pool.payInDuration +
                    (pool.payInDuration * feeStructure.marketMakerCutoff) /
                    TEN_THOUSAND_BIPS;
            /// @dev Calculate the battle amount that is net of fees
            uint256 battleAmountNetOfFees = battlePosition.amount - battlePosition.feePaid;
            /// @dev This if-statement is true, when the BattlePosition is "in the money"
            if (
                (battlePosition.direction == 1 && (pool.liquidationPrice < pool.strike)) ||
                (battlePosition.direction == 0 && (pool.liquidationPrice > pool.strike))
            ) {
                /**
           @dev The profit share of a BattlePosition is calculated from the whole liquidity of the BattlePool,
                divided by the liquidity on the winning side times the liquidity provided by the BattlePosition.
          */
                if (battlePosition.direction == 0) {
                    claimAmount =
                        ((pool.longCollateral + pool.shortCollateral) * battleAmountNetOfFees) /
                        pool.longCollateral;
                } else {
                    claimAmount =
                        ((pool.longCollateral + pool.shortCollateral) * battleAmountNetOfFees) /
                        pool.shortCollateral;
                }
            } else if (pool.longCollateral == 0 && battlePosition.direction == 1) {
                /**
           @dev If there is no liquidity on the LONG side of the BattlePool and the BattlePosition owner chose SHORT,
                the liquidity is transferred back regardless of the price movement.
          */
                claimAmount = battleAmountNetOfFees;
            } else if (pool.shortCollateral == 0 && battlePosition.direction == 0) {
                /**
           @dev If there is no liquidity on the SHORT side of the BattlePool and the BattlePosition owner chose LONG,
                the liquidity is transferred back regardless of the price movement.
          */
                claimAmount = battleAmountNetOfFees;
            } else if (pool.liquidationPrice == pool.strike) {
                /**
           @dev If the price did not move during the battle time frame (current floor = strike price),
                the liquidity is transferred back.
          */
                claimAmount = battleAmountNetOfFees;
            }
            /// @dev Add market maker reward to claim amount, if eligible
            if (marketMaker && pool.takerFees > 0) {
                //// @dev The fee gets distributed according to the fee sharing split
                uint256 marketMakerClaim = (battlePosition.amount * pool.takerFees) / pool.makerCollateral;
                claimAmount += (marketMakerClaim * feeStructure.marketMakerSplit) / TEN_THOUSAND_BIPS;
            }
            /// @dev Burn the battlePosition NFT
            battleContract.burn(battleId);
            emit JuicyBattle_BattleClaimed(battleId, claimAmount, msg.sender);
            /// @dev Transfer the claim amount to the BattlePosition's owner.
            IERC20(poolIdToTokenContract[battlePosition.poolId]).safeTransfer(msg.sender, claimAmount);
        }
    }

    /// @notice This function calculates the dynamic fee based on pay-in time
    /**
     @dev The function that approximates that fee is a combination of two linear functions
          (the first function handling 90% of the pay-in time and a second one handling the last 10% of the pay-in time => the last 10% the fee increases over time are steeper).
          The function of the first linear formula includes feeComponent3 (the BIP that is payed from the start),
          feeComponent2 (the BIP that is payed at 90% completion of the pay-in period), and the duration of the whole pay-in time.
          The function of the second linear formula includes feeComponent2,
          feeComponent1 (the BIP that is payed at the end of the pay-in time), and the duration of the whole pay-in time.
    */
    /// @return The fee rate in BIPs
    /// @param start The timestamp when the pool starts
    /// @param opened The timestamp when the battle was entered
    /// @param payInDuration The duration of the pay in period of the pool
    /// @param modify The fee modifier that raises the fee curve (in BIP)
    /// @param feeIndex Index pointing to the base fee structure
    function returnFee(
        uint256 start,
        uint256 opened,
        uint256 payInDuration,
        uint256 modify,
        uint256 feeIndex
    ) public view returns (uint256) {
        uint payinTimeLeft = start - opened;
        FeeStructure memory fee = feeIndexToFee[feeIndex];
        if (payinTimeLeft > payInDuration / 10) {
            /// @dev Formula: l\left(x\right)\ =\ b-\frac{\left(c-b-\frac{\left(c\cdot10\cdot x\right)}{d}+\frac{\left(b\cdot10\cdot x\right)}{d}\right)}{9}
            uint256 firstTerm = (fee.feeComp3 * 10 * payinTimeLeft) / payInDuration;
            uint256 secondTerm = (fee.feeComp2 * 10 * payinTimeLeft) / payInDuration;
            int256 thirdTerm = (int256(fee.feeComp3) - int256(fee.feeComp2) - int256(firstTerm) + int256(secondTerm));
            int256 result = int256(fee.feeComp2) - (thirdTerm / 9) + int256(modify);
            return uint256(result);
        } else {
            /// @dev Formula: k\left(x\right)\ =\ a+\frac{\left(\left(b\cdot10\cdot x\right)-\left(a\cdot10\cdot x\right)\right)}{d}
            uint256 firstTerm = (fee.feeComp2 * 10 * payinTimeLeft);
            uint256 secondTerm = (fee.feeComp1 * 10 * payinTimeLeft);
            int256 thirdTerm = int256(firstTerm) - int256(secondTerm);
            if (-thirdTerm >= int256(payInDuration)) {
                int256 result = int256(fee.feeComp1) + thirdTerm / int256(payInDuration) + int256(modify);
                return uint256(result);
            } else {
                int256 result = int256(fee.feeComp1) + int256(modify);
                return uint256(result);
            }
        }
    }

    /// @notice Withdraw all accrued fees for a token to the pool owner wallet
    /// @param tokenContract The token that shall be withdrawn
    function withdrawFees(address tokenContract) external nonReentrant {
        uint256 amount = feesForPoolOwner[msg.sender][tokenContract];
        if (amount == 0) {
            revert ValueTooLow("No fees accrued!");
        }
        feesForPoolOwner[msg.sender][tokenContract] = 0;
        IERC20(tokenContract).safeTransfer(msg.sender, amount);
    }

    /// @notice Getter pool collection
    /// @param poolId The poolId of the pool
    /// @return Collection address of the pool
    function getPoolCollection(uint256 poolId) external view returns (address) {
        return poolIdToPool[poolId].collection;
    }

    /// @notice Getter pool strike
    /// @param poolId The poolId of the pool
    /// @return Strike price of the pool
    function getPoolStrike(uint256 poolId) external view returns (int256) {
        return poolIdToPool[poolId].strike;
    }

    /// @notice Getter pool start
    /// @param poolId The poolId of the pool
    /// @return The start timestamp of the pool
    function getPoolStart(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].start;
    }

    /// @notice Getter pool end
    /// @param poolId The poolId of the pool
    /// @return The end timestamp of the pool
    function getPoolEnd(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].end;
    }

    /// @notice Getter pool short collateral
    /// @param poolId The poolId of the pool
    /// @return The short collateral of the pool
    function getPoolShortCollateral(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].shortCollateral;
    }

    /// @notice Getter pool long strike
    /// @param poolId The poolId of the pool
    /// @return The long collateral of the pool
    function getPoolLongCollateral(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].longCollateral;
    }

    /// @notice Getter pool maker collateral
    /// @param poolId The poolId of the pool
    /// @return The market maker collateral of the pool
    function getPoolMakerCollateral(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].makerCollateral;
    }

    /// @notice Getter pool taker fees
    /// @param poolId The poolId of the pool
    /// @return The taker fees of the pool
    function getPoolTakerFees(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].takerFees;
    }

    /// @notice Getter pool liquidation price
    /// @param poolId The poolId of the pool
    /// @return The liquidation price of the pool
    function getPoolLiquidationPrice(uint256 poolId) external view returns (int256) {
        return poolIdToPool[poolId].liquidationPrice;
    }

    /// @notice Getter pool closed status
    /// @param poolId The poolId of the pool
    /// @return The closed state of the pool
    function getPoolClosed(uint256 poolId) external view returns (bool) {
        return poolIdToPool[poolId].closed;
    }

    /// @notice Getter pool payin duration
    /// @param poolId The poolId of the pool
    /// @return The pay in duration of the pool
    function getPoolPayInDuration(uint256 poolId) external view returns (uint256) {
        return poolIdToPool[poolId].payInDuration;
    }

    /// @notice Getter pool owner
    /// @param poolId The poolId of the pool
    /// @return The owner of the pool
    function getPoolOwner(uint256 poolId) external view returns (address) {
        return poolIdToPool[poolId].owner;
    }

    /// @notice Getter pool token contract
    /// @param poolId The poolId of the pool
    /// @return The token contract of the pool
    function getPoolTokenContract(uint256 poolId) external view returns (address) {
        return poolIdToTokenContract[poolId];
    }

    /// @notice Getter pool fee modifier
    /// @param poolId The poolId of the pool
    /// @return The fee modifier of the pool
    function getPoolFeeModify(uint256 poolId) external view returns (uint256) {
        return poolIdToPoolFeeModify[poolId];
    }

    /// @notice Return the collected fees of an account for a specific token contract
    /// @param account address that accrued fess
    /// @param token token contract in which fees accrued
    /// @return Fees for account and token contract
    function getCollectedFees(address account, address token) external view returns (uint256) {
        return feesForPoolOwner[account][token];
    }

    function _createPerpetualPool(address collection, uint256 nextStartBlock) internal returns (uint256) {
        return
            _createPool(
                collection,
                WETH_CONTRACT,
                nextStartBlock,
                BATTLE_DURATION[collection],
                PAY_IN_DURATION[collection],
                SUPER_ADMIN_ADDRESS,
                0,
                marketMakerIncentive[collection]
            );
    }

    /// @notice This internal function creates a new pool.
    /// @param collection The collection for which the pool is created
    /// @param tokenContract The currency of the pool
    /// @param start The start timestamp of the pool
    /// @param duration The duration of the pool in seconds
    /// @param payInDuration The pay in of the pool in seconds
    /// @param feeMod The fee modifier of the pool
    /// @param _marketMakerIncentive The bool whether market makers shall be incentivized in this pool or not.
    /// @return The poolId of the newly created pool
    function _createPool(
        address collection,
        address tokenContract,
        uint256 start,
        uint256 duration,
        uint256 payInDuration,
        address owner,
        uint256 feeMod,
        bool _marketMakerIncentive
    ) internal returns (uint256) {
        if (start <= block.timestamp) {
            revert ValueTooLow("Cannot start a pool in the past");
        }
        if (duration < 10) {
            revert ValueTooLow("Duration must be larger than 10");
        }
        if (payInDuration < 10) {
            revert ValueTooLow("Pay in duration must be larger than 10");
        }
        /// @dev FeeMod can not be bigger than 10%!
        if (feeMod > 100) {
            revert ValueTooHigh("Fee modifier must lager equal than 0 and smaller equal 100");
        }

        // Store the new pool in storage
        BattlePool storage pool = poolIdToPool[_poolId];
        pool.collection = collection;
        pool.start = start;
        pool.end = start + duration;
        pool.liquidationPrice = 0;
        pool.closed = false;
        pool.payInDuration = payInDuration;
        pool.owner = owner;

        // Link the token contract to the poolId
        poolIdToTokenContract[_poolId] = tokenContract;
        // Link the feeIndex to the poolId
        poolIdToFeeIndex[_poolId] = _feeIndex;
        // Store the fee modifier in the mapping
        poolIdToPoolFeeModify[_poolId] = feeMod;
        // Store the market maker incentive in the mapping
        poolIdToMarketMakerIncentive[_poolId] = _marketMakerIncentive;

        emit JuicyBattle_PoolCreated(
            _poolId,
            collection,
            start + duration,
            start,
            payInDuration,
            owner,
            tokenContract,
            feeMod,
            _marketMakerIncentive
        );
        // Increment the global _poolId counter
        _poolId++;
        // return the poolId that was just set
        return _poolId - 1;
    }

    /// @return If a pool for id exists
    /// @param poolId The poolId of the pool
    function poolExists(uint256 poolId) internal view returns (bool) {
        return poolIdToPool[poolId].end != 0;
    }

    /// @notice Execute the duration change for a collection
    /// @param collection The collection for which the Duration change shall be triggered
    /// @return The start block associated with the new duration
    function triggerDurationChange(address collection) internal returns (uint256) {
        PAY_IN_DURATION[collection] = nextBattlePayIn[collection];
        BATTLE_DURATION[collection] = nextBattleDuration[collection];
        marketMakerIncentive[collection] = nextMarketMakerIncentive[collection];
        durationChange[collection] = false;
        return getNextStartBatchBlock(collection);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IPricingService} from "./IPricingService.sol";

/// @title This is a proxy contract that guides a pricing request to the correct Pricing service contract
contract PricingRouter is AccessControl {
    /// @notice This mapping maps an assets address to the right PricingService contract address
    mapping(address => address) public routing;

    /// @notice The super admin role
    bytes32 private constant SUPER_ADMIN = keccak256("SUPER");
    /// @notice The owner role
    bytes32 private constant OWNER = keccak256("OWNER");

    /// @notice Event that gets emitted once the routing changes
    event JuicyBattle_RoutingChanged(address collection, address pricingService);

    /// @notice error thrown when trying to renounce role
    error NoRoleRenounce();

    constructor(address _superAdminAddress) {
        _grantRole(SUPER_ADMIN, _superAdminAddress);
        _grantRole(OWNER, msg.sender);

        _setRoleAdmin(OWNER, SUPER_ADMIN);
    }

    /// @dev Override the `renounceRole` to prevent role renunciation
    /// @dev This is added so the hardcoded super admin can't lose its role
    function renounceRole(bytes32 /*role*/, address /*account*/) public pure override {
        revert NoRoleRenounce();
    }

    /// @notice This sets the Pricing Service contract address for a collection / asset
    /// @param collection is the address of the asset
    /// @param pricingServiceAddress is the contract address of the Pricing service that holds information about the asset
    function setRouteForCollection(address collection, address pricingServiceAddress) external onlyRole(OWNER) {
        routing[collection] = pricingServiceAddress;
        emit JuicyBattle_RoutingChanged(collection, pricingServiceAddress);
    }

    /// @notice This function returns the Pricing Service contract address for a collection / asset
    /// @param collection is the address of the asset
    /// @return The Pricing Service contract address
    function getRouteForCollection(address collection) external view returns (address) {
        return routing[collection];
    }

    /// @notice This function returns the latest price for an asset stored in the Pricing Service
    /// @param collection is the address of the asset
    /// @return The most recent price
    /// @param priceUpdateData Update data for pyth oracle
    function getLatestPrice(address collection, bytes[] calldata priceUpdateData) external payable returns (int256) {
        int256 price = IPricingService(routing[collection]).getLatestPrice{value: msg.value}(
            collection,
            priceUpdateData
        );
        if (price == 0) {
            revert("No price available");
        }
        return price;
    }
}