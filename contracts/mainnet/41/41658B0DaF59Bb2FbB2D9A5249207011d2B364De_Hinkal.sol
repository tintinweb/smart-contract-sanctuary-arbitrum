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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./HinkalBase.sol";
import "./VerifierFacade.sol";
import "./types/IHinkal.sol";
import "./types/IExternalAction.sol";
import "./types/ITransactHook.sol";

///@title Hinkal Contract
///@notice Entrypoint for all Hinkal Transactions.
contract Hinkal is IHinkal, VerifierFacade, HinkalBase {
    mapping(uint256 => address) internal externalActionMap;

    constructor(
        IMerkle.MerkleConstructorArgs memory constructorArgs,
        address _hinkalHelper,
        address _accessToken,
        address _hinkalHelperManager
    )
        HinkalBase(
            constructorArgs,
            _hinkalHelper,
            _accessToken,
            _hinkalHelperManager
        )
    {}

    function registerExternalAction(
        uint256 externalActionId,
        address externalActionAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        externalActionMap[externalActionId] = externalActionAddress;
        emit ExternalActionRegistered(externalActionAddress);
    }

    ///@notice Stop allowing smart contract to be called by Hinkal.
    ///@param externalActionId Id of this contract
    function removeExternalAction(
        uint256 externalActionId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        address externalActionAddress = externalActionMap[externalActionId];
        delete externalActionMap[externalActionId];
        emit ExternalActionRemoved(externalActionAddress);
    }

    function transact(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) public payable nonReentrant {
        _transact(a, b, c, dimensions, circomData);
    }

    function transactWithExternalAction(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) public payable nonReentrant {
        require(circomData.externalActionId != 0, "externalAddress is missing");
        _transact(a, b, c, dimensions, circomData);
    }

    function transactWithHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) public payable nonReentrant {
        require(
            circomData.hookData.hookContract != address(0) ||
                circomData.hookData.preHookContract != address(0),
            "hookContract is missing"
        );
        _transact(a, b, c, dimensions, circomData);
    }

    function transactWithExternalActionAndHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) public payable nonReentrant {
        require(circomData.externalActionId != 0, "externalAddress is missing");

        require(
            circomData.hookData.hookContract != address(0) ||
                circomData.hookData.preHookContract != address(0),
            "hookContract is missing"
        );
        _transact(a, b, c, dimensions, circomData);
    }

    function _transact(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) internal {
        {
            uint256[] memory inputForCircom = hinkalHelper.performHinkalChecks(
                circomData,
                dimensions
            );
            require(
                verifyProof(
                    a,
                    b,
                    c,
                    inputForCircom,
                    buildVerifierId(dimensions, circomData.externalActionId)
                ),
                "Invalid Proof"
            );
            // Root Hash Validation
            require(
                rootHashExists(circomData.rootHashHinkal),
                "Hinkal Root Hash is Incorrect"
            );
            require(
                accessToken.checkForRootHash(
                    circomData.rootHashAccessToken,
                    msg.sender
                ),
                "Access Token Root Hash is Incorrect"
            );

            // if you are forking/develop a netork the next statement should be commented
            require(
                circomData.timeStamp > block.timestamp - 7 * 60 &&
                    circomData.timeStamp < block.timestamp + 7 * 60,
                "Timestamp provided does not align with current time"
            );
        }

        {
            // function variables to store commitments created on-chain
            UTXO[] memory utxoSet;

            if (circomData.hookData.preHookContract != address(0)) {
                IPreTransactHook transactHook = IPreTransactHook(
                    circomData.hookData.preHookContract
                );
                transactHook.preTransact(
                    circomData,
                    circomData.hookData.preHookMetadata
                );
            }

            uint256[] memory oldBalances = getBalancesForArray(
                circomData.erc20TokenAddresses,
                circomData.tokenIds
            );

            if (circomData.externalActionId == 0) {
                _internalTransact(circomData);
            } else {
                utxoSet = _internalRunExternalAction(circomData);
            }

            uint256[] memory newBalances = getBalancesForArray(
                circomData.erc20TokenAddresses,
                circomData.tokenIds
            );

            OnChainCommitment[]
                memory onChainCommitments = new OnChainCommitment[](
                    utxoSet.length
                );
            uint256 onChainCommitmentCounter = 0;
            for (uint64 i; i < circomData.erc20TokenAddresses.length; i++) {
                int256 balanceDif;

                if (circomData.erc20TokenAddresses[i] == address(0)) {
                    balanceDif =
                        int256(newBalances[i]) +
                        int256(msg.value) -
                        int256(oldBalances[i]);
                } else {
                    balanceDif =
                        int256(newBalances[i]) -
                        int256(oldBalances[i]);
                }
                // balance inequality to check that minimum amount of token is received
                require(
                    balanceDif >= circomData.amountChanges[i],
                    "Inbalance in token detected"
                );

                uint256 utxoAmount = 0;
                for (uint j = 0; j < utxoSet.length; j++) {
                    if (
                        utxoSet[j].erc20Address ==
                        circomData.erc20TokenAddresses[i]
                    ) {
                        utxoAmount = utxoSet[j].amount;
                        onChainCommitments[
                            onChainCommitmentCounter++
                        ] = createCommitment(utxoSet[j]);
                        break;
                    }
                }
                // balance equation to check that we create utxo equal exactly to balance increase
                require(
                    balanceDif ==
                        int256(utxoAmount) +
                            int256(identity(circomData.outCommitments[i][0])) *
                            circomData.amountChanges[i],
                    "Balance Diff Should be equal to sum of onchain and offchain created commitments"
                );
            }
            if (circomData.hookData.hookContract != address(0)) {
                ITransactHook transactHook = ITransactHook(
                    circomData.hookData.hookContract
                );
                transactHook.afterTransact(
                    circomData,
                    circomData.hookData.postHookMetadata
                );
            }

            insertNullifiers(circomData.inputNullifiers);

            insertCommitments(
                circomData.outCommitments,
                circomData.encryptedOutputs,
                onChainCommitments
            );
        }
    }

    ///@notice private internal function for transaction
    ///@param circomData circom dara
    function _internalTransact(CircomData calldata circomData) private {
        for (uint64 i = 0; i < circomData.erc20TokenAddresses.length; i++) {
            if (circomData.amountChanges[i] > 0) {
                require(
                    circomData.externalAddress == msg.sender,
                    "Deposit should come from the sender"
                );
                transferTokenFrom(
                    circomData.erc20TokenAddresses[i],
                    circomData.externalAddress,
                    address(this),
                    uint256(circomData.amountChanges[i]),
                    circomData.tokenIds[i]
                );
            } else if (circomData.amountChanges[i] < 0) {
                uint256 relayFee = 0;
                if (circomData.relay != address(0)) {
                    relayFee = hinkalHelper.calculateRelayFee(
                        uint256(-circomData.amountChanges[i]),
                        circomData.erc20TokenAddresses[i],
                        circomData.flatFees[i],
                        circomData.externalActionId
                    );
                    require(
                        relayFee <= uint256(-circomData.amountChanges[i]),
                        "Relay Fee is over withdraw amount"
                    );
                    if (circomData.tokenIds[i] == 0)
                        transferERC20TokenOrETH(
                            circomData.erc20TokenAddresses[i],
                            circomData.relay,
                            relayFee
                        );
                }
                transferToken(
                    circomData.erc20TokenAddresses[i],
                    circomData.externalAddress,
                    uint256(-circomData.amountChanges[i]) - relayFee,
                    circomData.tokenIds[i]
                );
            }
        }
    }

    ///@notice internal function to use Hinkal with external contracts.
    ///@param circomData circom data.
    function _internalRunExternalAction(
        CircomData calldata circomData
    ) internal returns (UTXO[] memory) {
        require(
            externalActionMap[circomData.externalActionId] ==
                circomData.externalAddress &&
                circomData.externalAddress != address(0),
            "Unknown externalAddress"
        );

        for (uint64 i = 0; i < circomData.erc20TokenAddresses.length; i++) {
            if (circomData.amountChanges[i] < 0) {
                transferToken(
                    circomData.erc20TokenAddresses[i],
                    circomData.externalAddress,
                    uint256(-circomData.amountChanges[i]),
                    circomData.tokenIds[i]
                );
            }
        }
        return
            IExternalAction(circomData.externalAddress).runAction(circomData);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./types/IHinkalBase.sol";
import "./types/IHinkalHelper.sol";
import "./types/ICrossChainAccessToken.sol";
import "./types/IMerkle.sol";
import "./Merkle.sol";
import "./OwnerHinkal.sol";
import "./Transferer.sol";
import "./types/CircomData.sol";

///@title Base class for Hinkal Contract
contract HinkalBase is
    IHinkalBase,
    Merkle,
    Transferer,
    AccessControl,
    ReentrancyGuard
{
    mapping(uint256 => bool) public nullifiers;
    IHinkalHelper public hinkalHelper;
    ICrossChainAccessToken public accessToken;

    bytes32 public constant HINKAL_HELPER_MANAGER =
        keccak256("HINKAL_HELPER_MANAGER");

    constructor(
        IMerkle.MerkleConstructorArgs memory constructorArgs,
        address _hinkalHelper,
        address _accessToken,
        address _hinkalHelperManager
    ) Merkle(constructorArgs) {
        hinkalHelper = IHinkalHelper(_hinkalHelper);
        accessToken = ICrossChainAccessToken(_accessToken);

        _setRoleAdmin(HINKAL_HELPER_MANAGER, HINKAL_HELPER_MANAGER);
        _grantRole(HINKAL_HELPER_MANAGER, _hinkalHelperManager);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    ///@notice set the hinkal helper.
    ///@dev See HinkalHelper contract
    ///@param _hinkalHelper ethereum address of hinkal helper contract
    function setHinkalHelper(
        address _hinkalHelper
    ) external onlyRole(HINKAL_HELPER_MANAGER) {
        hinkalHelper = IHinkalHelper(_hinkalHelper);
    }

    ///@notice set access token.
    ///@dev See Cross Chain Access Token contract
    ///@param _accessToken ethereum address of Cross Chain Access Token contract
    function setAccessToken(
        address _accessToken
    ) external onlyRole(HINKAL_HELPER_MANAGER) {
        accessToken = ICrossChainAccessToken(_accessToken);
    }

    function register(bytes calldata shieldedAddressHash) external {
        accessToken.registerCheck(msg.sender);
        emit Register(msg.sender, shieldedAddressHash);
    }

    ///@notice insert user commitments to merkle tree.
    function createCommitment(
        // TODO --> needs coverage?
        UTXO memory utxo
    ) internal view returns (OnChainCommitment memory) {
        uint256 commitment;
        if (utxo.tokenId > 0) {
            commitment = hash5(
                utxo.amount,
                uint256(uint160(utxo.erc20Address)),
                utxo.stealthAddressStructure.stealthAddress,
                utxo.timeStamp,
                utxo.tokenId
            );
        } else {
            commitment = hash4(
                utxo.amount,
                uint256(uint160(utxo.erc20Address)),
                utxo.stealthAddressStructure.stealthAddress,
                utxo.timeStamp
            );
        }

        OnChainCommitment memory onChainCommitment = OnChainCommitment({
            utxo: utxo,
            commitment: commitment
        });
        return onChainCommitment;
    }

    function insertCommitments(
        uint256[][] calldata outCommitments,
        bytes[][] calldata encryptedOutputs,
        OnChainCommitment[] memory onChainCommitments
    ) internal {
        // 1) Total Length of Commitments
        uint256 length = 0;
        for (uint16 i = 0; i < outCommitments.length; i++) {
            for (uint16 j = 0; j < outCommitments[i].length; j++) {
                length += identity(outCommitments[i][j]);
            }
        }
        length += onChainCommitments.length;

        if (length > 0) {
            // 2) Flattening leaves array
            uint256[] memory leaves = new uint256[](length);
            uint256 index = 0;
            for (uint16 i = 0; i < outCommitments.length; i++) {
                for (uint16 j = 0; j < outCommitments[i].length; j++) {
                    if (outCommitments[i][j] != 0)
                        leaves[index++] = outCommitments[i][j];
                }
            }
            for (uint16 i = 0; i < onChainCommitments.length; i++) {
                leaves[index++] = onChainCommitments[i].commitment;
            }

            // 3) Inserting Leaves
            uint256[] memory insertedIndexes = insertMany(leaves);

            // 4) Emitting Commitments/EncryptedOutputs
            index = 0;
            for (uint16 i = 0; i < encryptedOutputs.length; i++) {
                for (uint16 j = 0; j < encryptedOutputs[i].length; j++) {
                    if (outCommitments[i][j] != 0) {
                        emit NewCommitment(
                            leaves[index],
                            int256(insertedIndexes[index]),
                            encryptedOutputs[i][j]
                        );
                        index++;
                    }
                }
            }
            for (uint16 i = 0; i < onChainCommitments.length; i++) {
                emit NewCommitment(
                    leaves[index],
                    -1 * int256(insertedIndexes[index++]),
                    abi.encode(onChainCommitments[i].utxo)
                );
            }
        }
    }

    function insertNullifiers(uint256[][] calldata inputNullifiers) internal {
        for (uint256 i = 0; i < inputNullifiers.length; i++) {
            for (uint16 j = 0; j < inputNullifiers[i].length; j++) {
                if (inputNullifiers[i][j] == 0) continue;
                require(
                    !nullifiers[inputNullifiers[i][j]],
                    "Nullifier cannot be reused"
                );
                nullifiers[inputNullifiers[i][j]] = true;
                emit Nullified(inputNullifiers[i][j]);
            }
        }
    }

    function identity(uint256 value) internal pure returns (uint256) {
        return value > 0 ? 1 : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./types/IPoseidon2.sol";
import "./MerkleBase.sol";

///@title Hinkal Merkle Tree
contract Merkle is MerkleBase {
    constructor(
        MerkleConstructorArgs memory constructorArgs
    ) MerkleBase(constructorArgs) {}

    function outputGas(uint256 index, uint256[] memory gasUsed) internal view {
        gasUsed[index] = gasleft();
    }

    ///@notice insert a single new leaf to Merkle Tree
    ///@param leaf value to be inserted
    ///@return index index of node inserted
    function insert(uint256 leaf) internal override returns (uint256) {
        uint256 newIndex = ++m_index;
        uint256 currentNodeIndex = newIndex - 1;

        require(m_index <= uint256(2) ** LEVELS, "Tree is full.");

        uint256 fullCount = newIndex - MINIMUM_INDEX; // number of inserted leaves
        uint256 twoPower = logarithm2(fullCount); // number of tree levels to be updated, (e.g. if 9 => 4 levels should be updated)

        uint256 prevHash = leaf;

        insertOne(currentNodeIndex, twoPower, prevHash);

        roots[rootIndex] = tree[twoPower]; // adding root to roots mapping
        rootIndex = (rootIndex + 1) % MAX_ROOT_NUMBER;
        return newIndex - 1;
    }

    function insertMany(
        uint256[] memory leaves
    ) internal returns (uint256[] memory insertedIndexes) {
        m_index += uint128(leaves.length);
        uint256 newIndex = m_index;
        uint256 currentNodeIndex = newIndex - leaves.length;

        require(m_index <= uint256(2) ** LEVELS, "Tree is full.");

        insertedIndexes = new uint256[](leaves.length);
        for (uint256 i = 0; i < insertedIndexes.length; i++) {
            insertedIndexes[i] = currentNodeIndex + i;
        }

        uint256[][] memory sortedLeaves = sortInPairs(leaves, currentNodeIndex);

        uint256 fullCount = newIndex - MINIMUM_INDEX; // number of inserted leaves
        uint256 twoPower = logarithm2(fullCount); // number of tree levels to be updated, (e.g. if 9 => 4 levels should be updated)

        for (uint256 i = 0; i < sortedLeaves.length; i++) {
            if (sortedLeaves[i].length == 1)
                insertOne(currentNodeIndex++, twoPower, sortedLeaves[i][0]);
            else {
                insertTwo(
                    sortedLeaves[i][0],
                    sortedLeaves[i][1],
                    currentNodeIndex,
                    twoPower
                );
                currentNodeIndex += 2;
            }
        }

        roots[rootIndex] = tree[twoPower]; // adding root to roots mapping
        rootIndex = (rootIndex + 1) % MAX_ROOT_NUMBER;
    }

    ///@notice insert single value and update Merkle Tree
    ///@param currentNodeIndex Index of the last node before insertion
    ///@param twoPower Nodes in Merkle Tree that must be updated
    ///@param prevHash node to be inserted
    function insertOne(
        uint256 currentNodeIndex,
        uint256 twoPower,
        uint256 prevHash
    ) internal {
        for (uint256 i = 0; i <= twoPower; i++) {
            if (currentNodeIndex % 2 == 0 || currentNodeIndex == 1) {
                tree[i] = prevHash;
                if (i != twoPower) prevHash = hash2(prevHash, 0);
            } else {
                prevHash = hash2(tree[i], prevHash);
            }
            currentNodeIndex /= 2;
        }
    }

    function insertTwo(
        uint256 left,
        uint256 right,
        uint256 currentNodeIndex,
        uint256 twoPower
    ) internal {
        uint256 prevHash = hash2(left, right);
        currentNodeIndex /= 2; // we are starting from i = 1, so we need one iteration

        for (uint256 i = 1; i <= twoPower; i++) {
            if (currentNodeIndex % 2 == 0 || currentNodeIndex == 1) {
                tree[i] = prevHash;
                if (i != twoPower) prevHash = hash2(prevHash, 0);
            } else {
                prevHash = hash2(tree[i], prevHash);
            }
            currentNodeIndex /= 2;
        }
    }

    ///@notice Sort leaf nodes in pairs of left and right nodes.
    ///@param leaves leaves to be sorted
    ///@param currentNodeIndex Index of the last node to be inserted
    ///@return sortedLeaves leaves sorted in pairs of left and right
    function sortInPairs(
        uint256[] memory leaves,
        uint256 currentNodeIndex
    ) internal pure returns (uint256[][] memory sortedLeaves) {
        uint leavesLength = leaves.length;
        bool firstLeafIfRight = currentNodeIndex % 2 != 0;

        uint256 firstElement = firstLeafIfRight ? 1 : 0;
        uint256 netElements = leavesLength - firstElement;

        uint256 lengthWithoutFirst = (netElements % 2 == 0)
            ? netElements / 2
            : (netElements + 1) / 2;

        sortedLeaves = new uint256[][](firstElement + lengthWithoutFirst);

        if (firstLeafIfRight) {
            uint256[] memory first = new uint256[](1);
            first[0] = leaves[0];
            sortedLeaves[0] = first;
        }

        uint arrIndex = firstLeafIfRight ? 1 : 0;
        uint sortedArrayIndex = arrIndex;
        while (arrIndex < leavesLength) {
            uint256[] memory arr;
            if (arrIndex + 1 < leavesLength) {
                arr = new uint256[](2);
                arr[0] = leaves[arrIndex];
                arr[1] = leaves[++arrIndex];
            } else {
                arr = new uint256[](1);
                arr[0] = leaves[arrIndex];
            }
            sortedLeaves[sortedArrayIndex++] = arr;
            ++arrIndex;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./types/IPoseidon2.sol";
import "./types/IPoseidon4.sol";
import "./types/IPoseidon5.sol";
import "./types/IMerkle.sol";

abstract contract MerkleBase is IMerkle {
    using Math for uint256;

    // states
    mapping(uint256 => uint256) public tree;
    mapping(uint256 => uint256) roots;
    uint128 public m_index; // current index of the tree
    uint128 public rootIndex = 0;
    // constants
    uint128 immutable LEVELS; // deepness of tree
    uint128 constant MAX_ROOT_NUMBER = 25;
    uint256 immutable MINIMUM_INDEX;
    IPoseidon2 public immutable poseidon2; // hashing
    IPoseidon4 public immutable poseidon4; // hashing
    IPoseidon5 public immutable poseidon5;

    // please see deployment scripts to understand how to create and instance of Poseidon contract
    constructor(MerkleConstructorArgs memory constructorArgs) {
        LEVELS = constructorArgs.levels;
        m_index = uint128(2 ** (LEVELS - 1));
        MINIMUM_INDEX = 2 ** (LEVELS - 1);
        poseidon2 = IPoseidon2(constructorArgs.poseidon2);
        poseidon4 = IPoseidon4(constructorArgs.poseidon4);
        poseidon5 = IPoseidon5(constructorArgs.poseidon5);
    }

    function hash2(
        uint256 a,
        uint256 b
    ) public view returns (uint256 poseidonHash) {
        poseidonHash = poseidon2.poseidon([a, b]);
    }

    function hash4(
        uint256 a0,
        uint256 a1,
        uint256 a2,
        uint256 a3
    ) public view returns (uint256 poseidonHash) {
        poseidonHash = poseidon4.poseidon([a0, a1, a2, a3]);
    }

    function hash5(
        uint256 a0,
        uint256 a1,
        uint256 a2,
        uint256 a3,
        uint256 a4
    ) public view returns (uint256 poseidonHash) {
        poseidonHash = poseidon5.poseidon([a0, a1, a2, a3, a4]);
    }

    function insert(uint256 leaf) internal virtual returns (uint256);

    function getRootHash() public view returns (uint256) {
        return roots[rootIndex > 0 ? rootIndex - 1 : MAX_ROOT_NUMBER - 1];
    }

    function rootHashExists(uint256 _root) public view returns (bool) {
        uint256 i = rootIndex; // latest root hash
        do {
            if (i == 0) {
                i = MAX_ROOT_NUMBER;
            }
            i--;
            if (_root == roots[i]) {
                return true;
            }
        } while (i != rootIndex);
        return false;
    }

    ///@notice logarithm of x with base 2.
    ///@notice instead of rounding down, this function rounds up.
    ///@param x operand
    ///@return y logarithm base 2 of input
    function logarithm2(uint256 x) public pure returns (uint256 y) {
        y = Math.log2(x, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract OwnerHinkal is Ownable2Step {
    function renounceOwnership() public view override onlyOwner {
        revert("The Ownership cannot be renounced");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TransfererBase.sol";

contract Transferer is TransfererBase {
    using SafeERC20 for IERC20;

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function unsafeApproveERC20Token(
        address _erc20TokenAddress,
        address _to,
        uint256 _value
    ) internal {
        IERC20(_erc20TokenAddress).approve(_to, 0);
        IERC20(_erc20TokenAddress).approve(_to, _value);
    }

    function getERC20Allowance(
        address _erc20TokenAddress,
        address owner,
        address spender
    ) internal view returns (uint256) {
        IERC20 outToken = IERC20(_erc20TokenAddress);
        return outToken.allowance(owner, spender);
    }

    function approveERC721Token(
        address _erc20TokenAddress,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721(_erc20TokenAddress).approve(_to, _tokenId);
    }

    function approveToken(
        address _erc20TokenAddress,
        address _to,
        uint256 _tokenId,
        uint256 _value
    ) internal {
        if (_tokenId == 0) {
            unsafeApproveERC20Token(_erc20TokenAddress, _to, _value);
        } else {
            approveERC721Token(_erc20TokenAddress, _to, _tokenId);
        }
    }

    function transferETH(address _recepient, uint256 _value) internal {
        (bool success, ) = _recepient.call{value: _value}("");
        require(success, "Transfer Failed");
    }

    function transferERC20TokenFrom(
        address _erc20TokenAddress,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        IERC20(_erc20TokenAddress).safeTransferFrom(_from, _to, _value);
    }

    function transferNftFrom(
        address _erc20TokenAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721(_erc20TokenAddress).safeTransferFrom(_from, _to, _tokenId);
    }

    function transferERC20TokenOrETH(
        address _erc20TokenAddress,
        address _to,
        uint256 _value
    ) internal {
        if (_erc20TokenAddress == address(0)) {
            transferETH(_to, _value);
        } else {
            transferERC20Token(_erc20TokenAddress, _to, _value);
        }
    }

    function transferToken(
        address _erc20TokenAddress,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) internal {
        if (_tokenId == 0) {
            transferERC20TokenOrETH(_erc20TokenAddress, _to, _value);
        } else {
            transferNftFrom(_erc20TokenAddress, address(this), _to, _tokenId);
        }
    }

    function multiTransfer(
        address[] memory erc20TokenAddresses,
        address _to,
        uint256[] memory amounts
    ) internal returns (bool) {
        for (uint64 i = 0; i < erc20TokenAddresses.length; i++) {
            if (amounts[i] > 0)
                transferERC20TokenOrETH(
                    erc20TokenAddresses[i],
                    _to,
                    amounts[i]
                );
        }
        return true;
    }

    function transferERC20TokenFromOrCheckETH(
        address _contractAddress,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        if (_contractAddress == address(0)) {
            require(
                msg.value == _value,
                "msg.value doesn't match needed amount"
            );
            if (_to != address(this)) {
                transferETH(_to, _value);
            }
        } else {
            transferERC20TokenFrom(_contractAddress, _from, _to, _value);
        }
    }

    function transferTokenFrom(
        address _erc20TokenAddress,
        address _from,
        address _to,
        uint256 _value,
        uint256 _tokenId
    ) internal {
        if (_tokenId == 0) {
            transferERC20TokenFromOrCheckETH(
                _erc20TokenAddress,
                _from,
                _to,
                _value
            );
        } else {
            transferNftFrom(_erc20TokenAddress, _from, _to, _tokenId);
        }
    }

    function multiTransferFrom(
        address[] memory erc20TokenAddresses,
        address _from,
        address _to,
        uint256[] memory amounts
    ) internal returns (bool) {
        for (uint64 i = 0; i < erc20TokenAddresses.length; i++) {
            if (amounts[i] > 0) {
                transferERC20TokenFromOrCheckETH(
                    erc20TokenAddresses[i],
                    _from,
                    _to,
                    amounts[i]
                );
            }
        }
        return true;
    }

    function getERC20OrETHBalance(
        address _erc20TokenAddress
    ) internal view returns (uint256) {
        if (_erc20TokenAddress == address(0)) {
            return address(this).balance;
        } else {
            IERC20 outToken = IERC20(_erc20TokenAddress);
            return outToken.balanceOf(address(this));
        }
    }

    function getNftBalance(
        address _erc20TokenAddress,
        uint256 tokenId
    ) internal view returns (uint256) {
        IERC721 outToken = IERC721(_erc20TokenAddress);
        try outToken.ownerOf(tokenId) returns (address owner) {
            if (owner == address(this)) return 1;
            else return 0;
        } catch {
            return 0;
        }
    }

    function getBalancesForArrayMemory(
        address[] memory erc20TokenAddresses
    ) internal view returns (uint256[] memory balances) {
        balances = new uint256[](erc20TokenAddresses.length);
        for (uint64 i; i < erc20TokenAddresses.length; i++) {
            balances[i] = getERC20OrETHBalance(erc20TokenAddresses[i]);
        }
    }

    function getBalancesForArrayMemory(
        address[] memory erc20TokenAddresses,
        uint256[] memory tokenIds
    ) internal view returns (uint256[] memory balances) {
        balances = new uint256[](erc20TokenAddresses.length);
        for (uint64 i; i < erc20TokenAddresses.length; i++) {
            if (tokenIds[i] == 0) {
                balances[i] = getERC20OrETHBalance(erc20TokenAddresses[i]);
            } else {
                balances[i] = getNftBalance(
                    erc20TokenAddresses[i],
                    tokenIds[i]
                );
            }
        }
    }

    function getBalancesForArray(
        address[] calldata erc20TokenAddresses
    ) internal view returns (uint256[] memory balances) {
        balances = new uint256[](erc20TokenAddresses.length);
        for (uint64 i; i < erc20TokenAddresses.length; i++) {
            balances[i] = getERC20OrETHBalance(erc20TokenAddresses[i]);
        }
    }

    function getBalancesForArray(
        address[] calldata erc20TokenAddresses,
        uint256[] calldata tokenIds
    ) internal view returns (uint256[] memory balances) {
        balances = new uint256[](erc20TokenAddresses.length);
        for (uint64 i; i < erc20TokenAddresses.length; i++) {
            if (tokenIds[i] == 0) {
                balances[i] = getERC20OrETHBalance(erc20TokenAddresses[i]);
            } else {
                balances[i] = getNftBalance(
                    erc20TokenAddresses[i],
                    tokenIds[i]
                );
            }
        }
    }

    function sendToRelay(
        address relay,
        uint256 actualAmount,
        address erc20TokenAddress
    ) internal {
        if (relay != address(0) && actualAmount > 0) {
            transferERC20TokenOrETH(
                erc20TokenAddress,
                relay,
                uint256(actualAmount)
            );
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TransfererBase {
    using SafeERC20 for IERC20;

    function transferERC20Token(
        address _erc20TokenAddress,
        address _to,
        uint256 _value
    ) internal {
        IERC20(_erc20TokenAddress).safeTransfer(_to, _value);
    }

    function approveERC20Token(
        address _erc20TokenAddress,
        address _to,
        uint256 _value
    ) internal {
        IERC20(_erc20TokenAddress).safeApprove(_to, 0);
        IERC20(_erc20TokenAddress).safeApprove(_to, _value);
    }

    function approveUnlimited(
        address _erc20TokenAddress,
        address _to
    ) internal {
        if (IERC20(_erc20TokenAddress).allowance(address(this), _to) < type(uint256).max / 2) {
            IERC20(_erc20TokenAddress).safeApprove(_to, 0);
            IERC20(_erc20TokenAddress).safeApprove(_to, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

struct AxelarChainInfo{
    string destinationChain;
    string destinationAddress;
    uint256 messageFee;
}

struct AxelarCapsule{
    AxelarChainInfo[] chains;
    uint256 totalMessageFees;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "./StealthAddressStructure.sol";

uint256 constant CIRCOM_P = 21888242871839275222246405745257275088548364400416034343698204186575808495617; // https://docs.circom.io/circom-language/basic-operators/

struct CircomData {
    uint256 rootHashHinkal;
    address[] erc20TokenAddresses;
    uint256[] tokenIds;
    int256[] amountChanges;
    uint256[][] inputNullifiers;
    uint256[][] outCommitments;
    bytes[][] encryptedOutputs;
    uint256[] flatFees;
    uint256 timeStamp;
    StealthAddressStructure stealthAddressStructure;
    uint256 rootHashAccessToken;
    uint256 calldataHash;
    uint16 publicSignalCount;
    address relay;
    address externalAddress;
    uint256 externalActionId;
    bytes externalActionMetadata;
    HookData hookData;
}

struct HookData {
    address preHookContract;
    address hookContract;
    bytes preHookMetadata;
    bytes postHookMetadata;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

struct Dimensions {
    uint16 tokenNumber;
    uint16 nullifierAmount;
    uint16 outputAmount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./CircomData.sol";

interface ICircomDataBuilder {
    function getHashedCalldata(
        CircomData memory circomData
    ) external pure returns (uint256);

    function formInputForCircom(
        CircomData memory circomData
    ) external pure returns (uint256[] memory input);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./IMerkle.sol";
import "./AxelarInfo.sol";

struct SignatureData {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 accessKey;
    uint256 nonce;
}

struct AccessTokenWithAddress {
    uint256 accessToken;
    address ethAddress;
}

interface ICrossChainAccessToken is IMerkle {
    event NewAccessKeyAdded(
        uint256 accessKey,
        uint256 index,
        address senderAddress
    );
    event MintingFeeChanged(uint256 newMintingFee);
    event AccessKeyBlacklisted(uint256 blacklistedAccessKey);
    event AddressBlacklisted(address blacklistedAddress);
    event AddressRemovedFromBlacklist(address addressToRestore);
    event FundsWithdrawnFromAccessToken(uint256 amount);
    event AccessKeyMigrationReceived(uint256 accessKey, string sourceChain);
    event CrossChainAccessTokenRegistryChange(
        string sourceChain,
        address sourceAddress
    );

    struct CrossChainAccessTokenRegistryUpdate {
        string sourceChain;
        address sourceAddress;
    }

    function usedNonces(uint256) external view returns (bool);

    function addToken(SignatureData calldata signatureData) external payable;

    function blacklistAddresses(address) external view returns (bool);

    function setMintingFee(uint256 _mintingFee) external;

    function hasToken(uint256 accessKey) external view returns (bool);

    function blacklistAccessKey(uint256 accessKey, uint256 index) external;

    function blacklistAddress(address _address) external;

    function removeAddressFromBlacklist(address addressToRestore) external;

    function withdraw() external;

    function setAxelarGasService(address _gasService) external;

    function addTokenCrossChain(
        SignatureData calldata signatureData,
        AxelarCapsule calldata capsule
    ) external payable;

    function migrateAccessToken(
        AxelarCapsule calldata capsule,
        uint256 accessKey
    ) external payable;

    function registerCheck(address sender) external view;

    function checkForRootHash(
        uint256 rootHashAccessToken,
        address sender
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IERC20TokenRegistry {

    event RegistryStateChanged(bool isEnabled);
    event TokenAdded(address erc20Token);
    event TokenRemoved(address erc20Token);
    event TokenLimit(address erc20Token, uint256 tokenLimit);

    function tokenRegistry(address) external returns (bool);

    function tokenLimits(address) external returns (uint256);

    function enabled() external view returns (bool);

    function changeState(bool _enabled) external;

    function addERCToken(address erc20Token) external;

    function removeToken(address erc20Token) external;

    function tokenInRegistry(address erc20Token) external view returns (bool);

    function setTokenLimit(address _token, uint256 _tokenLimit) external;

    function getTokenLimit(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "./CircomData.sol";
import "./UTXO.sol";

interface IExternalAction {
    function runAction(
        CircomData calldata circomData
    ) external returns (UTXO[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "../types/Dimensions.sol";
import "../types/CircomData.sol";

interface IHinkal {
    event ExternalActionRegistered(address externalActionAddress);

    event ExternalActionRemoved(address externalActionAddress);

    struct ConstructorArgs {
        uint256 levels;
        address poseidon;
        address accessTokenAddress;
        address circomDataBuilderAddress;
        address erc20TokenRegistryAddress;
        address relayStoreAddress;
    }

    function transact(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithExternalAction(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;

    function transactWithExternalActionAndHook(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        Dimensions calldata dimensions,
        CircomData calldata circomData
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./IRelayStore.sol";
import "./UTXO.sol";

interface IHinkalBase {
    event Register(address ethereumAddress, bytes shieldedAddressHash);

    event NewCommitment(
        uint256 commitment,
        int256 index,
        bytes encryptedOutput
    );
    event Nullified(uint256 nullifier);

    event NewTransaction(
        address sender,
        uint256 timestamp,
        address erc20TokenAddress,
        int256 publicAmount
    );
    event NewUtxo(
        uint256 amount,
        address erc20Address,
        uint256 randomization,
        uint256 stealthAddress,
        uint256 timeStamp,
        uint256 tokenId
    );

    function setHinkalHelper(address _hinkalHelper) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./IRelayStore.sol";
import "./ICircomDataBuilder.sol";
import "./Dimensions.sol";
import "./IRelayStore.sol";
import "./IERC20TokenRegistry.sol";

interface IHinkalHelper is IRelayStore, IERC20TokenRegistry {
    function getRelayStore() external view returns (RelayEntry[] memory);

    function relayerIsValid(address relay) external view;

    function checkTokenRegistry(
        address[] calldata erc20TokenAddresses,
        int256[] calldata amountChanges
    ) external view;

    function performHinkalChecks(
        CircomData calldata circomData,
        Dimensions calldata dimensions
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IMerkle {

    struct MerkleConstructorArgs {
        uint128 levels;
        address poseidon2;
        address poseidon4;
        address poseidon5;
    }

    function hash2(uint256 a, uint256 b) external view returns (uint256);

    function getRootHash() external view returns (uint256);

    function rootHashExists(uint256 _root) external view returns (bool);

    function logarithm2(uint256 x) external pure returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface IPoseidon2 {
    function poseidon(uint256[2] memory input) external pure returns (uint256);

    function poseidon(bytes32[2] memory input) external pure returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface IPoseidon4 {
    function poseidon(uint256[4] memory input) external pure returns (uint256);

    function poseidon(bytes32[4] memory input) external pure returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface IPoseidon5 {
    function poseidon(uint256[5] memory input) external pure returns (uint256);

    function poseidon(bytes32[5] memory input) external pure returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct RelayEntry {
    address relayAddress;
    string url;
    uint256 priority;
}

interface IRelayStore {
    event RelayPercentageChanged(uint32 newRelayPercentage);
    event RelayPercentageExternalChanged(uint32 newRelayPercentage);
    event RelayAddedOrSet(address relayAddress, string url, uint256 priority);
    event RelayRemoved(address relayAddress);

    function getRelayPercentage(
        uint256 amount,
        address erc20Address
    ) external view returns (uint32);

    function setRelayPercentage(uint32 _relayPercentage) external;

    function getRelayPercentageExternal(
        uint256 amount,
        address erc20Address,
        uint256 externalActionId
    ) external view returns (uint32);

    function setRelayPercentageExternal(
        uint32 _relayPercentageExternal
    ) external;

    function isRelayInList(address relay) external view returns (bool);

    function getRelayStore() external view returns (RelayEntry[] memory);

    function removeRelay(address _relayAddress) external;

    function addOrSetRelay(
        address relayAddress,
        string memory url,
        uint256 priority
    ) external;

    function calculateRelayFee(
        uint256 balance,
        address tokenAddress,
        uint256 flatFee,
        uint256 externalActionId
    ) external view returns (uint256 relayFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

import "./CircomData.sol";

interface IPreTransactHook {
    function preTransact(
        CircomData calldata circomData,
        bytes calldata metadata
    ) external;
}

interface ITransactHook {
    function afterTransact(
        CircomData calldata circomData,
        bytes calldata metadata
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input,
        uint256 verifierId
    ) view external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import "./IVerifier.sol";
import "./Dimensions.sol";

interface IVerifierFacade {
    event VerifierRegistered(uint256 verifierId, address verifierAddress);
    event VerifierRemoved(uint256 verifierId);

    function registerVerifiers(
        uint256[] calldata verifierIds,
        address[] calldata verifierAddresses
    ) external;

    function removeVerifier(uint256 verifierId) external;

    function buildVerifierId(
        Dimensions calldata dimensions,
        uint256 externalActionId
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.6;

struct StealthAddressStructure {
    uint256 extraRandomization;
    uint256 stealthAddress;
    uint256 H0;
    uint256 H1;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "./StealthAddressStructure.sol";

struct UTXO {
    uint256 amount;
    address erc20Address;
    StealthAddressStructure stealthAddressStructure;
    uint256 timeStamp;
    uint256 tokenId;
}

struct OnChainCommitment {
    UTXO utxo;
    uint256 commitment;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "./OwnerHinkal.sol";
import "./types/Dimensions.sol";
import "./types/IVerifierFacade.sol";
import "./types/IVerifier.sol";

///@title A Facade pattern for zk proof Verifiers
contract VerifierFacade is IVerifierFacade, OwnerHinkal {
    mapping(uint256 => IVerifier) internal verifierMap;

    function registerVerifiers(
        uint256[] calldata verifierIds,
        address[] calldata verifierAddresses
    ) external onlyOwner {
        for (uint i = 0; i < verifierIds.length; i++) {
            verifierMap[verifierIds[i]] = IVerifier(verifierAddresses[i]);
            emit VerifierRegistered(verifierIds[i], verifierAddresses[i]);
        }
    }

    function removeVerifier(uint256 verifierId) external onlyOwner {
        delete verifierMap[verifierId];
        emit VerifierRemoved(verifierId);
    }

    function buildVerifierId(
        Dimensions calldata dimensions,
        uint256 externalActionId
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        dimensions.tokenNumber,
                        dimensions.nullifierAmount,
                        dimensions.outputAmount,
                        externalActionId
                    )
                )
            );
    }

    function verifyProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[] memory input,
        uint256 verifierId
    ) internal view returns (bool) {
        IVerifier verifier = verifierMap[verifierId];
        require(
            address(verifier) != address(0),
            "Cannot find appropriate verifier"
        );
        return verifier.verifyProof(a, b, c, input, verifierId);
    }
}