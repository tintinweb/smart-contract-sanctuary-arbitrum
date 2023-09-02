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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Arrays.sol";
import "../../../utils/Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minime/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./StorageSlot.sol";
import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    using StorageSlot for bytes32;

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        // We use assembly to calculate the storage slot of the element at index `pos` of the dynamic array `arr`
        // following https://docs.soliditylang.org/en/v0.8.17/internals/layout_in_storage.html#mappings-and-dynamic-arrays.

        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
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
            set._indexes[value] = set._values.length;
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
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
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

pragma solidity ^0.8.17;

// Base
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

// Utils
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./governance/Manageable.sol";

// Let's trigger the libs
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Interfaces
import "./interfaces/IBridgeConnectorHome.sol";
import "./interfaces/ISwapV2.sol";

/// @title Crate token
/** @notice This contract is an ERC4626 cross-chain vault that allows users to deposit assets
 *  and mint Crate tokens. The Crate tokens can be used to redeem the assets on the same chain.
 *  The funds deposited on the contract are themselves deposited on other protocols to generate yield.
 *  The revenue generated reflects on the token's share price, which represents the assets value per
 *  crate token.
 *
 *
 *  Withdraws are done locally, using an internal stableswap liquidity pool. When a user wants to
 *  redeem their tokens, a swap happens between the "virtual" asset in the pool and the actual asset,
 *  which is then sent to the user. This creates a buffer to process withdraws, without having to manage
 *  risky cross-chain interactions. If the pool is depleted, some negative slippage can appear for
 *  redeemers, but the contract will still be able to process withdraws and depositors will be rewarded
 *  for providing liquidity.
 *
 *
 *  The assets in the pool are rebalanced periodically, to ensure that the pool is always balanced. When
 *  this happens, the vault earns the positive slippage. Also, pool assets are not idle and are used to
 *  generate yield on other protocols, such as Aave.
 *  @dev Deposit/withdraw/Redeem functions can be overloaded to allow for slippage control.
 **/
contract Crate is Pausable, ReentrancyGuard, Manageable, ERC20Snapshot {
	using SafeERC20 for IERC20;

	struct ChainData {
		uint256 debt;
		uint256 maxDeposit;
		address bridge;
	}

	struct Checkpoint {
		uint256 timestamp;
		uint256 sharePrice;
	}

	struct ElasticLiquidityPool {
		uint256 debt; // How much vAssets are accounted in the pool
		uint256 liquidity; // How much assets do we have when the pool is balanced
		ISwap swap; // Where is the pool
	}
	/*//////////////////////////////////////////////////////////////
                                 ERRORS
  //////////////////////////////////////////////////////////////*/

	error AmountTooHigh(uint256 maxAmount);
	error AmountZero();
	error CrateCantBeReceiver();
	error IncorrectShareAmount(uint256 shares);
	error IncorrectAssetAmount(uint256 assets);
	error ZeroAddress();
	error ChainError();
	error FeeError();
	error Unauthorized();
	error LiquidityPoolNotSet();
	error TransactionExpired();
	error NoFundsToRebalance();
	error MinAmountTooLow(uint256 minAmount);
	error IncorrectArrayLengths();
	error InsufficientFunds(uint256 availableFunds);

	/*//////////////////////////////////////////////////////////////
                                // SECTION EVENTS
  //////////////////////////////////////////////////////////////*/

	event Deposit(
		address indexed sender, // Who sent the USDC
		address indexed owner, // who received the crate tokens
		uint256 assets, // ex: amount of USDC sent
		uint256 shares // amount of crate tokens minted
	);
	event Withdraw(
		address indexed sender,
		address indexed receiver,
		address indexed owner,
		uint256 assets,
		uint256 shares
	);
	event ChainDebtUpdated(
		uint256 newChainDebt,
		uint256 oldChainDebt,
		uint256 chainId
	);
	event SharePriceUpdated(uint256 shareprice, uint256 timestamp);
	event TakeFees(
		uint256 gain,
		uint256 totalAssets,
		uint256 managementFee,
		uint256 performanceFee,
		uint256 sharesMinted,
		address indexed receiver
	);
	event NewFees(uint256 performance, uint256 management, uint256 withdraw);
	event LiquidityRebalanced(uint256 recovered, uint256 earned);
	event PoolMigrated(address indexed newPool, uint256 seedAmount);
	event LiquidityChanged(uint256 oldLiquidity, uint256 newLiquidity);
	event LiquidityPoolEnabled(bool enabled);
	event MigrationFailed();
	event ChainAdded(uint256 chainId, address bridge);
	event MaxDepositForChainSet(uint256 chainId, uint256 maxDeposit);
	event MaxTotalAssetsSet(uint256 maxTotalAssets);

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                        // SECTION VARIABLES
  //////////////////////////////////////////////////////////////*/
	uint256 public maxTotalAssets; // Max amount of assets in the vault
	uint256 public totalRemoteAssets; // Amount of assets on other chains (or farmed on local chain)
	uint256 public performanceFee; // 100% = 10000
	uint256 public managementFee; // 100% = 10000
	uint256 public withdrawFee; // 100% = 10000
	uint256 public anticipatedProfits; // The yield trickling down
	uint256 public lastUpdate; // Last time the unrealized gain was updated
	uint256[] public chainList; // List of chains that can be used

	// This allows us to do some bookeeping
	mapping(uint256 => ChainData) public chainData; // Chain data

	Checkpoint public checkpoint; // Used to compute fees
	ElasticLiquidityPool public liquidityPool; // The pool used to process withdraws

	uint8 private tokenDecimals; // The decimals of the token
	bool public liquidityPoolEnabled; // If the pool is enabled

	mapping(address => bool) public bridgeWhitelist; // BridgeConnectors that can be used

	IERC20 public asset; // The asset we are using

	uint256 private constant MAX_BPS = 10000; // 100%
	uint256 private constant MAX_PERF_FEE = 10000; // 100%
	uint256 private constant MAX_MGMT_FEE = 500; // 5%
	uint256 private constant MAX_WITHDRAW_FEE = 200; // 2%
	uint256 private constant MAX_UINT256 = type(uint256).max;
	uint256 private constant COOLDOWN = 2 days; // The cooldown period for realizating gains
	uint256 private constant MIN_AMOUNT_RATIO = 970; // 97% of the amount

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                            // SECTION CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/
	constructor(
		address _asset, // The asset we are using
		string memory _name, // The name of the token
		string memory _symbol, // The symbol of the token
		uint256 _performanceFee, // 100% = 10000
		uint256 _managementFee, // 100% = 10000
		uint256 _withdrawFee // 100% = 10000
	) ERC20(_name, _symbol) {
		if (_performanceFee > MAX_PERF_FEE) revert FeeError();
		if (_managementFee > MAX_MGMT_FEE) revert FeeError();
		if (_withdrawFee > MAX_WITHDRAW_FEE) revert FeeError();

		asset = IERC20(_asset);
		performanceFee = _performanceFee;
		managementFee = _managementFee;
		withdrawFee = _withdrawFee;
		tokenDecimals = IERC20Metadata(_asset).decimals();
		checkpoint = Checkpoint(block.timestamp, 10 ** tokenDecimals);
		_pause(); // We start paused
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                        // SECTION MODIFIERS
  //////////////////////////////////////////////////////////////*/
	/// @notice Checks if the sender is the bridge
	modifier onlyBridgeConnector() {
		if (bridgeWhitelist[msg.sender] == false) revert Unauthorized();
		_;
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                        // SECTION DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
	/// @dev If the liquidity pool is imbalanced, the user will get some positive slippage from replenishing it.
	/// @param _amount The amount of underlying tokens to deposit
	/// @param _receiver The address that will get the tokens
	//  @param _minShareAmount Minimum amount of shares to be minted, like slippage on Uniswap
	//  @param _deadline Transaction should revert if exectued after this deadline
	/// @return shares the amount of tokens minted to the _receiver
	function safeDeposit(
		uint256 _amount,
		address _receiver,
		uint256 _minShareAmount,
		uint256 _deadline
	) external returns (uint256 shares) {
		return _deposit(_amount, _receiver, _minShareAmount, _deadline);
	}

	/// @notice Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
	/// @dev If the liquidity pool is imbalanced, the user will get some positive slippage from replenishing it.
	/// @dev This version is here for ERC4626 compatibility and doesn't have slippage and deadline control
	/// @param _amount The amount of underlying tokens to deposit
	/// @param _receiver The address that will get the tokens
	/// @return shares the amount of tokens minted to the _receiver
	function deposit(
		uint256 _amount,
		address _receiver
	) external returns (uint256 shares) {
		return _deposit(_amount, _receiver, 0, block.timestamp);
	}

	/// @dev Pausing the contract should prevent depositing by setting maxDepositAmount
	/// to 0
	function _deposit(
		uint256 _amount,
		address _receiver,
		uint256 _minShareAmount,
		uint256 _deadline
	) internal nonReentrant returns (uint256 shares) {
		// Requires

		if (_receiver == address(this)) revert CrateCantBeReceiver();
		if (_amount == 0) revert AmountZero();
		if (_amount > maxDeposit(address(0)))
			revert AmountTooHigh(maxDeposit(_receiver));
		// We save totalAssets before transfering
		uint256 assetsAvailable = totalAssets();

		// Moving value
		asset.safeTransferFrom(msg.sender, address(this), _amount);
		// If we have a liquidity pool, we use it
		if (liquidityPoolEnabled) {
			ElasticLiquidityPool memory pool = liquidityPool;

			// If the pool is unbalanced, we get the amount to swap to rebalance it
			uint256 toSwap = _getAmountToSwap(_amount, pool);
			if (toSwap > 0) {
				uint256 swapped = pool.swap.swapAssetToVirtual(
					toSwap,
					_deadline
				);
				liquidityPool.debt += swapped;
				// We credit the bonus
				_amount = _amount + swapped - toSwap;
			}
		} else if (block.timestamp > _deadline) {
			revert TransactionExpired();
		} // We can now compute the amount of shares we'll mint
		uint256 supply = totalSupply();
		shares = supply == 0
			? _amount
			: Math.mulDiv(_amount, supply, assetsAvailable);

		if (shares == 0 || shares < _minShareAmount) {
			revert IncorrectShareAmount(shares);
		}

		// We mint crTokens
		_mint(_receiver, shares);
		emit Deposit(msg.sender, _receiver, _amount, shares);
	}

	/// @notice Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
	/// @dev Bear in mind that this function doesn't interact with the liquidity pool, so you may be
	/// missing some positive slippage if the pool is imbalanced.
	/// @param _shares the amount of tokens minted to the _receiver
	/// @param _receiver The address that will get the tokens
	/// @return assets The The amount of underlying tokens deposited
	function mint(
		uint256 _shares,
		address _receiver
	) external nonReentrant returns (uint256 assets) {
		assets = convertToAssets(_shares);

		// Requires
		if (assets == 0 || _shares == 0) revert AmountZero();
		if (assets > maxDeposit(_receiver))
			revert AmountTooHigh(maxDeposit(_receiver));
		if (_receiver == address(this)) revert CrateCantBeReceiver();

		// Moving value
		asset.safeTransferFrom(msg.sender, address(this), assets);
		_mint(_receiver, _shares);
		emit Deposit(msg.sender, _receiver, assets, _shares);
	}

	/// @notice Order a withdraw from the liquidity pool
	/// @dev Beware, there's no slippage control - you need to use the overloaded function if you want it
	/// @param _amount Amount of funds to pull (ex: 1000 USDC)
	/// @param _receiver Who will get the withdrawn assets
	/// @param _owner Whose crTokens we'll burn
	function withdraw(
		uint256 _amount,
		address _receiver,
		address _owner
	) external returns (uint256 shares) {
		// This represents the amount of crTokens that we're about to burn
		shares = previewWithdraw(_amount); // We take fees here
		_withdraw(_amount, shares, 0, block.timestamp, _receiver, _owner);
	}

	/// @notice Order a withdraw from the liquidity pool
	/// @dev Overloaded version with slippage control
	/// @param _amount Amount of funds to pull (ex: 1000 USDC)
	/// @param _receiver Who will get the withdrawn assets
	/// @param _owner Whose crTokens we'll burn
	function safeWithdraw(
		uint256 _amount,
		uint256 _minAmount,
		uint256 _deadline,
		address _receiver,
		address _owner
	) external returns (uint256 shares) {
		// This represents the amount of crTokens that we're about to burn
		shares = previewWithdraw(_amount); // We take fees here
		_withdraw(_amount, shares, _minAmount, _deadline, _receiver, _owner);
	}

	/// @notice Redeem crTokens for their underlying value
	/// @dev We do this to respect the ERC46626 interface
	/// Beware, there's no slippage control - you need to use the overloaded function if you want it
	/// @param _shares The amount of crTokens to redeem
	/// @param _receiver Who will get the withdrawn assets
	/// @param _owner Whose crTokens we'll burn
	function redeem(
		uint256 _shares,
		address _receiver,
		address _owner
	) external returns (uint256 assets) {
		return (
			_withdraw(
				(convertToAssets(_shares) * (MAX_BPS - withdrawFee)) / MAX_BPS, // We take fees here
				_shares,
				0,
				block.timestamp,
				_receiver,
				_owner
			)
		);
	}

	/// @notice Redeem crTokens for their underlying value
	/// @dev Overloaded version with slippage control
	/// @param _shares The amount of crTokens to redeem
	/// @param _minAmountOut The minimum amount of assets we'll accept
	/// @param _receiver Who will get the withdrawn assets
	/// @param _owner Whose crTokens we'll burn
	/// @return assets Amount of assets recovered
	function safeRedeem(
		uint256 _shares,
		uint256 _minAmountOut, // Min_amount
		uint256 _deadline,
		address _receiver,
		address _owner
	) external returns (uint256 assets) {
		return (
			_withdraw(
				(convertToAssets(_shares) * (MAX_BPS - withdrawFee)) / MAX_BPS, // We take fees here
				_shares, // _shares
				_minAmountOut,
				_deadline,
				_receiver, // _receiver
				_owner // _owner
			)
		);
	}

	/// @notice The vault takes a small fee to prevent share price updates arbitrages
	/// @dev Logic used to pull tokens from the router and process accounting
	/// @dev Fees should already have been taken into account
	function _withdraw(
		uint256 _amount,
		uint256 _shares,
		uint256 _minAmountOut,
		uint256 _deadline,
		address _receiver,
		address _owner
	) internal nonReentrant whenNotPaused returns (uint256 recovered) {
		if (_amount == 0 || _shares == 0) revert AmountZero();

		// We spend the allowance if the msg.sender isn't the receiver
		if (msg.sender != _owner) {
			_spendAllowance(_owner, msg.sender, _shares);
		}

		// Check for rounding error since we round down in previewRedeem.
		if (convertToAssets(_shares) == 0)
			revert IncorrectAssetAmount(convertToAssets(_shares));

		// We burn the tokens
		_burn(_owner, _shares);

		uint256 assetBal = asset.balanceOf(address(this));

		// If there are enough funds in the vault, we just send them
		if (assetBal > 0 && assetBal >= _amount) {
			recovered = _amount;
			asset.safeTransfer(_receiver, recovered);
			// If there aren't enough funds in the vault, we need to pull from the liquidity pool
		} else if (liquidityPoolEnabled) {
			// We first send the funds that we have
			if (assetBal > 0) {
				recovered = assetBal;
				asset.safeTransfer(_receiver, recovered);
			}

			uint256 toRecover = _amount - recovered;
			recovered += liquidityPool.swap.swapVirtualToAsset(
				toRecover,
				0, // Check is done after
				_deadline,
				_receiver
			);

			// We don't take into account the eventual slippage, since it will
			// be paid to the depositoors
			liquidityPool.debt -= Math.min(toRecover, liquidityPool.debt);
		} else {
			revert InsufficientFunds(assetBal);
		}

		if (_minAmountOut > 0 && recovered < _minAmountOut)
			revert IncorrectAssetAmount(recovered);

		emit Withdraw(msg.sender, _receiver, _owner, _amount, _shares);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                        // SECTION LIQUIDITY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

	// TODO: Should this function be whitelisted?
	/// @notice Rebalance the Liquidity pool using idle funds and liquid strats
	function rebalanceLiquidityPool()
		public
		whenNotPaused
		returns (uint256 earned)
	{
		// Reverts if we the LP is not enabled
		if (!liquidityPoolEnabled) revert LiquidityPoolNotSet();

		// We check if we have enough funds to rebalance
		uint256 toSwap = _getAmountToSwap(
			asset.balanceOf(address(this)),
			liquidityPool
		);

		if (toSwap == 0) revert NoFundsToRebalance();
		uint256 recovered = liquidityPool.swap.swapAssetToVirtual(
			toSwap,
			block.timestamp + 100
		);
		liquidityPool.debt += recovered;
		earned = recovered - Math.min(toSwap, recovered);

		emit LiquidityRebalanced(recovered, earned);
		emit SharePriceUpdated(sharePrice(), block.timestamp);
	}

	/// @notice Order a deposit to the different chains, which will move funds accordingly
	/// @dev Another call at the router level is needed to send the funds
	/// @param _amounts The amount to process. This allows to let a buffer for withdraws, if needed
	/// @param _minAmounts The minimum amount to accept for each chain
	/// @param _chainIds self-explanatory
	/// @param _msgValues value to send the call to the bridge, if needed
	/// @param _bridgeData data to send the call to the bridge, if needed
	function dispatchAssets(
		uint256[] calldata _amounts,
		uint256[] calldata _minAmounts,
		uint256[] calldata _chainIds,
		uint256[] calldata _msgValues,
		bytes[] calldata _bridgeData
	) external payable onlyKeeper {
		if (
			_amounts.length != _minAmounts.length ||
			_amounts.length != _chainIds.length ||
			_amounts.length != _msgValues.length ||
			_amounts.length != _bridgeData.length
		) revert IncorrectArrayLengths();

		for (uint256 i = 0; i < _amounts.length; i++) {
			ChainData memory data = chainData[_chainIds[i]];
			// checks
			if (_minAmounts[i] < (_amounts[i] * MIN_AMOUNT_RATIO) / 1000)
				revert MinAmountTooLow((_amounts[i] * MIN_AMOUNT_RATIO) / 1000); // prevents setting minAmount too low
			if (data.maxDeposit == 0) revert ChainError(); // Chain not active
			if (data.maxDeposit <= data.debt + _amounts[i])
				revert AmountTooHigh(data.maxDeposit); // No more funds can be sent to this chain

			chainData[_chainIds[i]].debt += _amounts[i];
			totalRemoteAssets += _amounts[i];
			asset.safeTransfer(data.bridge, _amounts[i]);
			if (block.chainid != _chainIds[i]) {
				IBridgeConnectorHome(data.bridge).bridgeFunds{
					value: _msgValues[i]
				}(_amounts[i], _chainIds[i], _minAmounts[i], _bridgeData[i]);
			}
		}
	}

	/// @notice Migrate from one liquidity pool to another
	/// @dev This allows you to earn the full positive slippage, if some is missing
	/// @dev Disable the liquidity pool by migrating it to address(0)
	/// @param _newPool Address of the new pool
	/// @param _seedAmount Amount of liquidity to add to the new pool
	function migrateLiquidityPool(
		address _newPool,
		uint256 _seedAmount
	) external onlyAdmin {
		ISwap swap = liquidityPool.swap;
		// If we already have a pool, we withdraw our funds from it
		if (address(swap) != address(0)) {
			try swap.migrate() {} catch {
				emit MigrationFailed();
			}
			// We remove the allowance
			asset.safeDecreaseAllowance(
				address(swap),
				asset.allowance(address(this), address(swap))
			);
		}

		// We set the new pool or disable the liquidity pool
		if (_newPool == address(0)) {
			liquidityPoolEnabled = false;
			liquidityPool.swap = ISwap(address(0));
			liquidityPool.debt = 0;
			liquidityPool.liquidity = 0;
			emit PoolMigrated(_newPool, 0);
			emit LiquidityPoolEnabled(false);
			return;
		}

		// Approving
		// https://github.com/code-423n4/2021-10-slingshot-findings/issues/81
		asset.safeIncreaseAllowance(address(_newPool), 0);
		asset.safeIncreaseAllowance(address(_newPool), MAX_UINT256);

		// We need to register the new liquidity
		liquidityPool.swap = ISwap(_newPool);

		// We can now add liquidity to it
		if (_seedAmount > 0) {
			ISwap(_newPool).addLiquidity(_seedAmount, block.timestamp + 100);
			liquidityPoolEnabled = true;
			liquidityPool.debt = _seedAmount;
			liquidityPool.liquidity = _seedAmount;
		} else {
			liquidityPoolEnabled = false;
		}

		emit PoolMigrated(_newPool, _seedAmount);
		emit LiquidityPoolEnabled(liquidityPoolEnabled);
	}

	/// @notice Increase the amount of liquidity in the pool
	/// @dev We must have enough idle liquidity to do it
	/// If that's not the case, pull liquid funds first
	/// @param _liquidityAdded Amount of liquidity to add to the pool
	function increaseLiquidity(uint256 _liquidityAdded) external onlyKeeper {
		uint256 oldLiquidity = liquidityPool.liquidity;
		liquidityPool.liquidity = oldLiquidity + _liquidityAdded;
		liquidityPool.debt += _liquidityAdded;

		// We add equal amounts of tokens
		// To avoid any slippage, rebalance first
		// Given that the pool floors calculations, it's not possible to rebalance 1:1
		// hence why we don't have a hard require on the pool being balanced
		liquidityPool.swap.addLiquidity(_liquidityAdded, block.timestamp);

		emit LiquidityChanged(oldLiquidity, oldLiquidity + _liquidityAdded);
	}

	/// @notice Decrease the amount of liquidity in the pool
	/// @param _liquidityRemoved Amount of liquidity to add to the pool
	function decreaseLiquidity(uint256 _liquidityRemoved) external onlyKeeper {
		// Rebalance first the pool to avoid any negative slippage
		uint256 lpBal = liquidityPool.swap.getVirtualLpBalance();
		uint256 assetBalBefore = asset.balanceOf(address(this));
		uint256 liquidityBefore = liquidityPool.liquidity;

		// we remove liquidity
		liquidityPool.liquidity -= _liquidityRemoved;
		// We specify the amount of LP that corresponds to the amount of liquidity removed
		liquidityPool.swap.removeLiquidity(
			(lpBal * _liquidityRemoved) / liquidityBefore,
			block.timestamp
		);
		// We update the book
		liquidityPool.debt -= (asset.balanceOf(address(this)) - assetBalBefore);
		emit LiquidityChanged(
			liquidityBefore,
			liquidityBefore - _liquidityRemoved
		);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                // SECTION ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice Linearization of the accrued gains
	/// @dev This is used to calculate the total assets under management
	/// @return The amount of gains that are not yet realized
	function unrealizedGains() public view returns (uint256) {
		return
			// Death by ternary
			lastUpdate + COOLDOWN < block.timestamp // If cooldown is over
				? 0 // all gains are realized
				: anticipatedProfits - // Otherwise, we calculate the gains
					((1e6 *
						(anticipatedProfits * (block.timestamp - lastUpdate))) /
						COOLDOWN) /
					1e6; // We scale by 1e6 to avoid rounding errors with low decimals
	}

	/// @notice Amount of assets under management
	/// @dev We consider each chain/pool as having "debt" to the crate
	/// @return The total amount of assets under management
	function totalAssets() public view returns (uint256) {
		return
			(asset.balanceOf(address(this)) +
				totalRemoteAssets +
				liquidityPool.debt) - unrealizedGains();
	}

	/// @notice Decimals of the crate token
	/// @return The number of decimals of the crate token
	function decimals() public view override returns (uint8) {
		return (tokenDecimals);
	}

	/// @notice The share price equal the amount of assets redeemable for one crate token
	/// @return The virtual price of the crate token
	function sharePrice() public view returns (uint256) {
		uint256 supply = totalSupply();

		return
			supply == 0
				? 10 ** decimals()
				: Math.mulDiv(totalAssets(), 10 ** decimals(), supply);
	}

	/// @notice Convert how much crate tokens you can get for your assets
	/// @param _assets Amount of assets to convert
	/// @return The amount of crate tokens you can get for your assets
	function convertToShares(uint256 _assets) public view returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
		// shares = assets * supply / totalDebt
		return
			supply == 0 ? _assets : Math.mulDiv(_assets, supply, totalAssets());
	}

	/// @notice Convert how much asset tokens you can get for your crate tokens
	/// @dev Bear in mind that some negative slippage may happen
	/// @param _shares amount of shares to covert
	/// @return The amount of asset tokens you can get for your crate tokens
	function convertToAssets(uint256 _shares) public view returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
		return
			supply == 0 ? _shares : Math.mulDiv(_shares, totalAssets(), supply);
	}

	function _getAmountToSwap(
		uint256 _assets,
		ElasticLiquidityPool memory pool
	) internal view returns (uint256 toSwap) {
		uint256 poolImbalance = pool.liquidity -
			Math.min(pool.swap.getAssetBalance(), pool.liquidity);

		// If there's an imbalance, we replenish the pool
		if (poolImbalance > 0) {
			return (Math.min(poolImbalance, _assets));
		}
	}

	/// @notice Convert how much crate tokens you can get for your assets
	/// @param _assets Amount of assets that we deposit
	/// @return shares Amount of share tokens that the user should receive
	function previewDeposit(
		uint256 _assets
	) external view returns (uint256 shares) {
		if (liquidityPoolEnabled) {
			ElasticLiquidityPool memory pool = liquidityPool;
			uint256 toSwap = _getAmountToSwap(_assets, pool);

			// If there's an imbalance, we replenish the pool
			if (toSwap > 0) {
				uint256 swapped = pool.swap.calculateAssetToVirtual(toSwap);
				// We credit the bonus
				_assets = _assets - toSwap + swapped;
			}
		}

		return convertToShares(_assets);
	}

	/// @notice Preview how much asset tokens the user has to pay to acquire x shares
	/// @param _shares Amount of shares that we acquire
	/// @return shares Amount of asset tokens that the user should pay
	function previewMint(uint256 _shares) public view returns (uint256) {
		return convertToAssets(_shares);
	}

	/// @notice Preview how much shares the user needs to burn to get asset tokens
	/// @dev You may get less asset tokens than you expect due to slippage
	/// @param _assets How much we want to get
	/// @return How many shares we need to burn
	function previewWithdraw(uint256 _assets) public view returns (uint256) {
		return convertToShares((_assets * MAX_BPS) / (MAX_BPS - withdrawFee));
	}

	/// @notice Preview how many asset tokens the user will get for x shares
	/// @param shares Amount of shares that we burn
	/// @return Amount of asset tokens that the user will get for x shares
	function previewRedeem(uint256 shares) public view returns (uint256) {
		uint256 vAssets = convertToAssets(shares);
		vAssets -= (vAssets * withdrawFee) / MAX_BPS;

		uint256 recovered = asset.balanceOf(address(this));
		if (liquidityPoolEnabled && recovered < vAssets) {
			return
				recovered +
				liquidityPool.swap.calculateVirtualToAsset(vAssets - recovered);
		}

		return asset.balanceOf(address(this)) >= vAssets ? vAssets : 0;
	}

	// @notice acknowledge the sending of funds and update debt book
	/// @param _chainId Id of the chain that sent the funds
	/// @param _amount Amount of funds sent
	function receiveBridgedFunds(
		uint256 _chainId,
		uint256 _amount
	) external onlyBridgeConnector {
		asset.safeTransferFrom(msg.sender, address(this), _amount);
		uint256 oldDebt = chainData[_chainId].debt;
		chainData[_chainId].debt -= Math.min(oldDebt, _amount);
		totalRemoteAssets -= Math.min(totalRemoteAssets, _amount);

		emit ChainDebtUpdated(chainData[_chainId].debt, oldDebt, _chainId);
		emit SharePriceUpdated(sharePrice(), block.timestamp);
	}

	/// @notice Update the debt book
	/// @param _chainId Id of the chain that had a debt update
	/// @param _newDebt New debt of the chain
	function updateChainDebt(
		uint256 _chainId,
		uint256 _newDebt
	) external onlyBridgeConnector {
		uint256 oldDebt = chainData[_chainId].debt;

		chainData[_chainId].debt = _newDebt;
		uint256 debtDiff = _newDebt - Math.min(_newDebt, oldDebt);
		if (debtDiff > 0) {
			// We update the anticipated profits
			anticipatedProfits = debtDiff + unrealizedGains();
			lastUpdate = block.timestamp;
		}

		totalRemoteAssets = totalRemoteAssets + _newDebt - oldDebt;

		emit ChainDebtUpdated(_newDebt, oldDebt, _chainId);
		emit SharePriceUpdated(sharePrice(), block.timestamp);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                     // SECTION DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

	/// @notice The maximum amount of assets that can be deposited
	/// @return The maximum amount of assets that can be deposited
	function maxDeposit(address) public view returns (uint256) {
		uint256 maxAUM = maxTotalAssets;
		return maxAUM - Math.min(totalAssets(), maxAUM);
	}

	/// @notice The maximum amount of shares that can be minted
	/// @return The maximum amount of shares that can be minted
	function maxMint(address) public view returns (uint256) {
		return convertToShares(maxDeposit(address(0)));
	}

	/// @notice The maximum amount of assets that can be withdrawn
	/// @return The maximum amount of assets that can be withdrawn
	function maxWithdraw(address _owner) external view returns (uint256) {
		return paused() ? 0 : convertToAssets(balanceOf(_owner));
	}

	/// @notice The maximum amount of shares that can be redeemed
	/// @return The maximum amount of shares that can be redeemed
	function maxRedeem(address _owner) external view returns (uint256) {
		return paused() ? 0 : balanceOf(_owner);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                              // SECTION FEES
    //////////////////////////////////////////////////////////////*/

	/// @notice Take fees from the vault
	/// @dev This function is called by the owner of the vault
	function takeFees() external onlyAdmin {
		(
			uint256 performanceFeeAmount,
			uint256 managementFeeAmount,
			uint256 gain
		) = computeFees();

		if (gain == 0) return;

		uint256 sharesMinted = convertToShares(
			performanceFeeAmount + managementFeeAmount
		);

		_mint(msg.sender, sharesMinted);
		checkpoint = Checkpoint(block.timestamp, sharePrice());

		emit TakeFees(
			gain,
			totalAssets(),
			managementFeeAmount,
			performanceFeeAmount,
			sharesMinted,
			msg.sender
		);
	}

	/// @notice Compute the fees that should be taken
	///  @dev The fees are computed based on the last checkpoint
	/// @dev Fees are computed in terms of % of the vault, then scaled to the total assets
	/// @return performanceFeeAmount The amount of performance fee
	/// @return managementFeeAmount The amount of management fee
	/// @return gain The gain of the vault since last checkpoint
	function computeFees()
		public
		view
		returns (
			uint256 performanceFeeAmount,
			uint256 managementFeeAmount,
			uint256 gain
		)
	{
		// We get the elapsed time since last time
		Checkpoint memory lastCheckpoint = checkpoint;
		uint256 duration = block.timestamp - lastCheckpoint.timestamp;
		if (duration == 0) return (0, 0, 0); // Can't call twice per block

		uint256 currentSharePrice = sharePrice();
		gain =
			Math.max(lastCheckpoint.sharePrice, currentSharePrice) -
			lastCheckpoint.sharePrice;

		if (gain == 0) return (0, 0, 0); // If the contract hasn't made any gains, we do not take fees

		uint256 currentTotalAssets = totalAssets();

		// We compute the fees relative to the sharePrice
		// For instance, if the management fee is 1%, and the sharePrice is 200,
		// the "relative" management fee is 2 after a year
		uint256 managementFeeRelative = (currentSharePrice *
			managementFee *
			duration) /
			MAX_BPS /
			365 days;

		// Same with performance fee
		uint256 performanceFeeRelative = (gain * performanceFee) / MAX_BPS;

		// This allows us to check if the gain is enough to cover the fees
		if (managementFeeRelative + performanceFeeRelative > gain) {
			managementFeeRelative = gain - performanceFeeRelative;
		}

		// We can now compute the fees in terms of assets
		performanceFeeAmount =
			(performanceFeeRelative * currentTotalAssets) /
			currentSharePrice;

		managementFeeAmount =
			(managementFeeRelative * currentTotalAssets) /
			currentSharePrice;

		return (performanceFeeAmount, managementFeeAmount, gain);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                            // SECTION SETTERS
    //////////////////////////////////////////////////////////////*/

	/// @notice Add a new chain to the vault or update one
	/// @param _chainId Id of the chain to add
	/// @param _maxDeposit Max amount of assets that can be deposited on that chain
	/// @param _bridgeAddress Address of the bridge connector
	/// @param _allocator Address of the remote allocator
	/// @param _remoteConnector Address of the remote connector
	/// @param _params Parameters to pass to the bridge connector
	function addChain(
		uint256 _chainId,
		uint256 _maxDeposit,
		address _bridgeAddress,
		address _allocator,
		address _remoteConnector,
		bytes calldata _params
	) external onlyAdmin {
		// if it's the local chain we don't need to setup a bridge
		if (block.chainid != _chainId)
			IBridgeConnectorHome(_bridgeAddress).addChain(
				_chainId,
				_allocator,
				_remoteConnector,
				_params
			);

		// IF the chain has not been added yet, we add it to the list
		if (chainData[_chainId].bridge == address(0)) chainList.push(_chainId);
		chainData[_chainId].maxDeposit = _maxDeposit;
		chainData[_chainId].bridge = _bridgeAddress;
		bridgeWhitelist[_bridgeAddress] = true;
		emit ChainAdded(_chainId, _bridgeAddress);
	}

	function enableLiquidityPool(
		bool _liquidityPoolEnabled
	) external onlyManager {
		liquidityPoolEnabled = _liquidityPoolEnabled;
		if (address(liquidityPool.swap) == address(0))
			revert LiquidityPoolNotSet();
		emit LiquidityPoolEnabled(liquidityPoolEnabled);
	}

	/// @notice Set the max deposit for a chain
	/// @param _maxDeposit Max amount of assets that can be deposited on that chain
	/// @param _chainId Id of the chain
	function setMaxDepositForChain(
		uint256 _maxDeposit,
		uint256 _chainId
	) external onlyManager {
		if (chainData[_chainId].bridge == address(0)) revert ChainError();
		chainData[_chainId].maxDeposit = _maxDeposit;
		emit MaxDepositForChainSet(_maxDeposit, _chainId);
	}

	/// @notice Set the max amount of total assets that can be deposited
	/// @dev There can be more assets than this, however if that's the case then
	/// no deposits are allowed
	/// @param _amount max amount of assets
	function setMaxTotalAssets(uint256 _amount) external onlyManager {
		// We need to unpause first the vault if it's paused
		// This prevents the vault to accept deposits but not withdraws
		if (maxTotalAssets == 0 && paused()) {
			revert();
		}
		// We seed the vault with some assets if it's empty
		maxTotalAssets = _amount;
		uint256 seedDeposit = 10 ** 8;
		if (totalSupply() == 0)
			_deposit(seedDeposit, msg.sender, seedDeposit, block.timestamp);
		emit MaxTotalAssetsSet(_amount);
	}

	/// @notice Set the fees
	/// @dev Maximum fees are registered as constants
	/// @param _performanceFee Fee on performance
	/// @param _managementFee Annual fee
	/// @param _withdrawFee Fee on withdraw, mainly to avoid MEV/arbs
	function setFees(
		uint256 _performanceFee,
		uint256 _managementFee,
		uint256 _withdrawFee
	) external onlyAdmin {
		// Safeguards
		if (
			_performanceFee > MAX_PERF_FEE ||
			_managementFee > MAX_MGMT_FEE ||
			_withdrawFee > MAX_WITHDRAW_FEE
		) revert FeeError(); // Fees are too high

		performanceFee = _performanceFee;
		managementFee = _managementFee;
		withdrawFee = _withdrawFee;
		emit NewFees(performanceFee, managementFee, withdrawFee);
	}

	// !SECTION

	/*//////////////////////////////////////////////////////////////
                            // SECTION UTILS
    //////////////////////////////////////////////////////////////*/

	receive() external payable {}

	/// @notice Pause the crate
	function pause() external onlyManager {
		_pause();
		// This prevents deposit
		maxTotalAssets = 0;
	}

	/// @notice Unpause the crate
	/// @dev We seed the crate with 1e8 tokens if it's empty
	function unpause() external onlyManager {
		_unpause();
	}

	/// @notice Take a snapshot of the crate balances
	function snapshot() external onlyManager returns (uint256 id) {
		id = _snapshot();
		emit Snapshot(id);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20Snapshot) {
		super._beforeTokenTransfer(from, to, amount);
	}

	/// @notice Rescue any ERC20 token that is stuck in the contract
	function rescueToken(address _token, bool _onlyETH) external onlyAdmin {
		// We send any trapped ETH
		payable(msg.sender).transfer(address(this).balance);

		if (_onlyETH) return;

		if (_token == address(asset)) revert();
		IERC20 tokenToRescue = IERC20(_token);
		tokenToRescue.transfer(
			msg.sender,
			tokenToRescue.balanceOf(address(this))
		);
	}

	/// @notice Estimate the cost of a deposit on a chain
	/// @param _chainIds Ids of the chains
	/// @param _amounts Amounts to deposit
	/// @return nativeCost Cost of the deposit in native token
	function estimateDispatchCost(
		uint256[] calldata _chainIds,
		uint256[] calldata _amounts
	) external view returns (uint256[] memory) {
		if (_amounts.length != _chainIds.length) {
			revert IncorrectArrayLengths();
		}
		uint256 length = _chainIds.length;
		uint256[] memory nativeCost = new uint256[](length);
		for (uint256 i; i < length; i++) {
			if (_chainIds[i] == block.chainid) continue;
			nativeCost[i] = IBridgeConnectorHome(chainData[_chainIds[i]].bridge)
				.estimateBridgeCost(_chainIds[i], _amounts[i]);
		}
		return (nativeCost);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Manageable is AccessControlEnumerable {
	struct Pending {
		address oldAdmin;
		address newAdmin;
		uint256 timestamp;
	}

	// The keeper role can be used to perform automated maintenance
	bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

	// The manager role can be used to perform manual maintenance
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	// The pending period is the time that the new admin has to wait to accept the role
	uint256 private constant PENDING_PERIOD = 2 days;
	// The grace period is the time that the grantee has to accept the role
	uint256 private constant GRACE_PERIOD = 7 days;

	Pending public pending;

	error AdminCantRenounce();
	error AdminRoleError();
	error GracePeriodElapsed(uint256 _GraceTimestamp);
	error PendingPeriodNotElapsed(uint256 _PendingTimestamp);
	error AccessControlBadConfirmation();

	constructor() {
		// We give the admin role to the account that deploys the contract
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		// We set the role hierarchy
		_setRoleAdmin(KEEPER_ROLE, DEFAULT_ADMIN_ROLE);
		_setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
	}

	/**
	 * @notice Check if an account has the keeper role
	 */
	modifier onlyKeeper() {
		_checkRole(KEEPER_ROLE, _msgSender());
		_;
	}

	/**
	 * @notice Check if an account has the manager role
	 */
	modifier onlyManager() {
		_checkRole(MANAGER_ROLE, _msgSender());
		_;
	}

	/**
	 * @notice Check if an account has the admin role
	 */
	modifier onlyAdmin() {
		_checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
		_;
	}

	/**
	 * @notice Grant a role to an account
	 *
	 * @dev If the role is admin, the account will have to accept the role
	 * The request will expire after PENDING_PERIOD has passed
	 */
	function grantRole(
		bytes32 role,
		address account
	)
		public
		override(AccessControl, IAccessControl)
		onlyRole(getRoleAdmin(role))
	{
		// If the role is admin, we need an additionnal step to accept the role
		if (role == DEFAULT_ADMIN_ROLE) {
			pending = Pending(msg.sender, account, block.timestamp);
		} else {
			_grantRole(role, account);
		}
	}

	/**
	 * @notice Revokes `role` from the calling account.
	 *
	 * @dev Roles are often managed via {grantRole} and {revokeRole}: this function's
	 * purpose is to provide a mechanism for accounts to lose their privileges
	 * if they are compromised (such as when a trusted device is misplaced).
	 *
	 * To avoid bricking the contract, admin role can't be renounced.
	 * If needed, the admin can grant the role to another account and then revoke the former.
	 */

	function renounceRole(
		bytes32 role,
		address callerConfirmation
	) public override(AccessControl, IAccessControl) {
		if (callerConfirmation != _msgSender())
			revert AccessControlBadConfirmation();
		if (role == DEFAULT_ADMIN_ROLE) revert AdminCantRenounce();

		_revokeRole(role, callerConfirmation);
	}

	/**
	 * @dev Revokes `role` from `account`.
	 *
	 * If `account` had been granted `role`, emits a {RoleRevoked} event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 * - admin role can't revoke itself
	 *
	 * May emit a {RoleRevoked} event.
	 */
	function revokeRole(
		bytes32 role,
		address account
	)
		public
		override(AccessControl, IAccessControl)
		onlyRole(getRoleAdmin(role))
	{
		if (role == DEFAULT_ADMIN_ROLE && account == msg.sender) {
			revert AdminCantRenounce();
		}

		_revokeRole(role, account);
	}

	/**
	 * @notice Accept an admin role and revoke the old admin
	 *
	 * @dev If the role is admin or manager, the account will have to accept the role
	 * The request will expire after PENDING_PERIOD + GRACE_PERIOD has passed
	 * Old admin will be revoked and new admin will be granted
	 */
	function acceptAdminRole() external {
		Pending memory request = pending;

		// Role has to be accepted by the new admin
		if (request.newAdmin != msg.sender) revert AdminRoleError();

		// Acceptance must be done before the grace period is over
		if (block.timestamp > request.timestamp + PENDING_PERIOD + GRACE_PERIOD)
			revert GracePeriodElapsed(
				request.timestamp + PENDING_PERIOD + GRACE_PERIOD
			);

		// Acceptance must be done after the pending period is over
		if (block.timestamp < request.timestamp + PENDING_PERIOD)
			revert PendingPeriodNotElapsed(request.timestamp + PENDING_PERIOD);
		// We revoke the old admin and grant the new one
		_revokeRole(DEFAULT_ADMIN_ROLE, request.oldAdmin);
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		delete pending;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeConnectorHome {
	function bridgeFunds(
		uint256 _amount,
		uint256 _chainId,
		uint256 _minAmount,
		bytes calldata _bridgeData
	) external payable;

	function estimateBridgeCost(
		uint256 _chainId,
		uint256 _amount
	) external view returns (uint256 gasEstimation);

	function addChain(
		uint256 _chainId,
		address _allocator,
		address _remoteConnector,
		bytes calldata _params
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISwap {
	struct Swap {
		// variables around the ramp management of A,
		// the amplification coefficient * n * (n - 1)
		// see https://www.curve.fi/stableswap-paper.pdf for details
		uint256 initialA;
		uint256 futureA;
		uint256 initialATime;
		uint256 futureATime;
		// fee calculation
		uint256 swapFee;
		uint256 adminFee;
		IERC20 lpToken;
		// contract references for all tokens being pooled
		IERC20[] pooledTokens;
		// multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS
		// for example, TBTC has 18 decimals, so the multiplier should be 1. WBTC
		// has 8, so the multiplier should be 10 ** 18 / 10 ** 8 => 10 ** 10
		uint256[] tokenPrecisionMultipliers;
		// the pool balance of each token, in the token's precision
		// the contract's actual token balance might differ
		uint256[] balances;
	}

	function swapStorage() external returns (Swap memory);

	function swapVirtualToAsset(
		uint256 _dx,
		uint256 _minDx,
		uint256 _deadline,
		address _receiver
	) external returns (uint256 dy);

	function swapAssetToVirtual(
		uint256 _dx,
		uint256 _deadline
	) external returns (uint256 dy);

	function addLiquidity(
		uint256 amount,
		uint256 deadline
	) external returns (uint256);

	function removeLiquidity(
		uint256 amount,
		uint256 deadline
	) external returns (uint256 recovered);

	function migrate() external;

	function getAssetBalance() external view returns (uint256);

	function getVirtualLpBalance() external view returns (uint256);

	function calculateSwap(
		uint8 tokenIndexFrom,
		uint8 tokenIndexTo,
		uint256 dx
	) external view returns (uint256);

	function calculateVirtualToAsset(
		uint256 dx
	) external view returns (uint256 dy);

	function calculateAssetToVirtual(
		uint256 dx
	) external view returns (uint256 dy);
}