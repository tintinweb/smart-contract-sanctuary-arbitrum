// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

// Interfaces
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library Curve2PoolAdapter {
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    IUniswapV2Router02 constant sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

    /**
     * @notice Swaps a token for 2CRV
     * @param _inputToken The token to swap
     * @param _amount The token amount to swap
     * @param _stableToken The address of the stable token to swap the `_inputToken`
     * @param _minStableAmount The minimum output amount of `_stableToken`
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapTokenFor2Crv(
        IStableSwap self,
        address _inputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        address[] memory route = _swapTokenFor2CrvRoute(_inputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(_amount, _minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(self, _stableToken, stableOutput, _min2CrvAmount);

        emit SwapTokenFor2Crv(_amount, amountOut, _inputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForToken(
        IStableSwap self,
        address _outputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        uint256 stableAmount = swap2CrvForStable(self, _stableToken, _amount, _minStableAmount);

        address[] memory route = _swapStableForTokenRoute(_outputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(stableAmount, _minTokenAmount, route, _recipient, block.timestamp);

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(IStableSwap self, address _stableToken, uint256 _amount, uint256 _minStableAmount)
        public
        returns (uint256)
    {
        int128 stableIndex;

        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return self.remove_liquidity_one_coin(_amount, stableIndex, _minStableAmount);
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function swapStableFor2Crv(IStableSwap self, address _stableToken, uint256 _amount, uint256 _min2CrvAmount)
        public
        returns (uint256)
    {
        uint256[2] memory deposits;
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    function _swapStableForTokenRoute(address _outputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_outputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _stableToken;
            route[1] = _outputToken;
        } else {
            route = new address[](3);
            route[0] = _stableToken;
            route[1] = WETH;
            route[2] = _outputToken;
        }
        return route;
    }

    function _swapTokenFor2CrvRoute(address _inputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_inputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _inputToken;
            route[1] = _stableToken;
        } else {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = WETH;
            route[2] = _stableToken;
        }
        return route;
    }

    event Swap2CrvForToken(uint256 _amountIn, uint256 _amountOut, address _token);
    event SwapTokenFor2Crv(uint256 _amountIn, uint256 _amountOut, address _token);

    error INVALID_STABLE_TOKEN();
}

// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   ********************* 
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library SushiAdapter {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    ) public {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    ) public {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(self, IERC20(_token), _assetAmount, _recepient, deadline, _route);
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    function swapTokens(
        IUniswapV2Router02 self,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recepient
    ) external {
        self.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _recepient, block.timestamp);
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    ) private {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

interface I1inchAggregationRouterV4 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    event OrderFilledRFQ(bytes32 orderHash, uint256 makingAmount);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event Swapped(
        address sender,
        address srcToken,
        address dstToken,
        address dstReceiver,
        uint256 spentAmount,
        uint256 returnAmount
    );

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function LIMIT_ORDER_RFQ_TYPEHASH() external view returns (bytes32);

    function cancelOrderRFQ(uint256 orderInfo) external;

    function destroy() external;

    function fillOrderRFQ(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount
    ) external payable returns (uint256, uint256);

    function fillOrderRFQTo(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target
    ) external payable returns (uint256, uint256);

    function fillOrderRFQToWithPermit(
        LimitOrderProtocolRFQ.OrderRFQ memory order,
        bytes memory signature,
        uint256 makingAmount,
        uint256 takingAmount,
        address target,
        bytes memory permit
    ) external returns (uint256, uint256);

    function invalidatorForOrderRFQ(address maker, uint256 slot) external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function rescueFunds(address token, uint256 amount) external;

    function swap(address caller, SwapDescription memory desc, bytes memory data)
        external
        payable
        returns (uint256 returnAmount, uint256 gasLeft);

    function transferOwnership(address newOwner) external;

    function uniswapV3Swap(uint256 amount, uint256 minReturn, uint256[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes memory) external;

    function uniswapV3SwapTo(address recipient, uint256 amount, uint256 minReturn, uint256[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function uniswapV3SwapToWithPermit(
        address recipient,
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory pools,
        bytes memory permit
    ) external returns (uint256 returnAmount);

    function unoswap(address srcToken, uint256 amount, uint256 minReturn, bytes32[] memory pools)
        external
        payable
        returns (uint256 returnAmount);

    function unoswapWithPermit(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        bytes32[] memory pools,
        bytes memory permit
    ) external returns (uint256 returnAmount);

    receive() external payable;
}

interface LimitOrderProtocolRFQ {
    struct OrderRFQ {
        uint256 info;
        address makerAsset;
        address takerAsset;
        address maker;
        address allowedSender;
        uint256 makingAmount;
        uint256 takingAmount;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IFeeReceiver {
    function deposit(address _token, uint256 _amount) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {OneInchZapLib} from "../libraries/OneInchZapLib.sol";

interface ILPVault {
    enum VaultType {
        BULL,
        BEAR
    }

    enum UserStatus {
        NOT_ACTIVE,
        ACTIVE,
        EXITING,
        FLIPPING
    }

    // Token being deposited
    function depositToken() external view returns (IERC20);

    // Flag to see if any funds have been borrowed this epoch
    function borrowed() external view returns (bool);

    function cap() external view returns (uint256);

    function totalDeposited() external view returns (uint256);

    function getUserStatus(address _user) external view returns (UserStatus);

    function deposit(address _user, uint256 _amount) external;

    // ============================= Events ================================

    /**
     * @notice Emitted when a address deposits
     * @param _from The address that makes the deposit
     * @param _to The address that receives a balance
     * @param _amount The amount that was deposited
     */
    event Deposited(address indexed _from, address indexed _to, uint256 _amount);

    /**
     * @notice Emitted when a user cancels a deposit
     * @param _user The address that receives a balance
     * @param _amount The amount that was deposited
     */
    event CanceledDeposit(address indexed _user, uint256 _amount);

    /**
     * @notice Emitted when a user signals a vault flip
     * @param _user The address that requested the flip
     * @param _vault The vault that is fliping to
     */
    event Flipped(address indexed _user, address indexed _vault);

    /**
     * @notice Emitted when a user signals an exit
     * @param _user The address that requested the exit
     */
    event UserSignalExit(address indexed _user);

    /**
     * @notice Emitted when a user cancels a signal exit
     * @param _user The address that requested the exit
     */
    event UserCancelSignalExit(address indexed _user);

    /**
     * @notice Emitted when a user withdraws
     * @param _user The address that withdrew
     * @param _amount the amount sent out
     */
    event Withdrew(address indexed _user, uint256 _amount);

    /**
     * @notice Emitted when epoch ends
     * @param _epoch epoch that ended
     * @param _endBalance epoch end balance
     * @param _startBalance epoch start balance
     */
    event EpochEnded(uint256 indexed _epoch, uint256 _endBalance, uint256 _startBalance);

    /**
     * @notice Emitted when epoch starts
     * @param _epoch epoch started
     * @param _startBalance epoch start balance
     */
    event EpochStart(uint256 indexed _epoch, uint256 _startBalance);

    /**
     * @notice Emitted when a strategy borrows funds from the vault
     * @param _strategy address of the strategy
     * @param _amount the amount taken
     */
    event Borrowed(address indexed _strategy, uint256 _amount);

    /**
     * @notice Emitted when a strategy repays funds to the vault
     * @param _strategy address of the strategy
     * @param _amount the amount taken
     */
    event Repayed(address indexed _strategy, uint256 _amount);

    /**
     * @notice Emitted when someone updates the risk percentage
     * @param _governor governor that ran the update
     * @param _oldRate rate before the update
     * @param _newRate rate after the update
     */
    event RiskPercentageUpdated(address indexed _governor, uint256 _oldRate, uint256 _newRate);

    /**
     * @notice Emitted when the vault is paused
     * @param _governor governor that paused the vault
     * @param _epoch final epoch
     */
    event VaultPaused(address indexed _governor, uint256 indexed _epoch);

    // ============================= Errors ================================

    error STARTING_EPOCH_BEFORE_ENDING_LAST();
    error VAULT_PAUSED();
    error EMERGENCY_OFF_NOT_PAUSED();
    error EMERGENCY_AFTER_SIGNAL();
    error TERMINAL_EPOCH_NOT_REACHED();
    error USER_EXITING();
    error USER_FLIPPING();
    error ZERO_VALUE();
    error NON_WHITELISTED_FLIP();
    error NO_DEPOSITS_FOR_USER();
    error USER_ALREADY_EXITING();
    error EPOCH_ENDED();
    error CANNOT_WITHDRAW();
    error ALREADY_BORROWED();
    error ALREADY_WHITELISTED();
    error NOT_WHITELISTED();
    error OPERATION_IN_FUTURE();
    error DEPOSITED_THIS_EPOCH();
    error INVALID_SWAP();
    error TARGET_VAULT_FULL();
    error VAULT_FULL();
    error WRONG_VAULT_ARGS();
    error ACTION_FORBIDEN_IN_USER_STATE();
    error FORBIDDEN_SWAP_RECEIVER();
    error FORBIDDEN_SWAP_SOURCE();
    error FORBIDDEN_SWAP_DESTINATION();
    error HIGH_SLIPPAGE();
    error USER_EXITING_ON_FLIP_VAULT();
    error USER_FLIPPING_ON_FLIP_VAULT();

    // ============================= Structs ================================

    struct Flip {
        uint256 userPercentage;
        address destinationVault;
    }

    struct Epoch {
        uint256 startAmount;
        uint256 endAmount;
    }

    struct UserEpochs {
        uint256[] epochs;
        uint256 end;
        uint256 deposited;
        UserStatus status;
    }
}

interface IBearLPVault is ILPVault {
    function borrow(
        uint256[2] calldata _minTokenOutputs,
        uint256 _min2Crv,
        address _intermediateToken,
        OneInchZapLib.SwapParams[2] calldata _swapParams
    ) external returns (uint256[2] memory);

    function repay(
        uint256[2] calldata _minOutputs,
        uint256 _minLpTokens,
        address _intermediateToken,
        OneInchZapLib.SwapParams[2] calldata _swapParams
    ) external returns (uint256);
}

interface IBullLPVault is ILPVault {
    function borrow(uint256[2] calldata _minTokenOutputs) external returns (uint256);

    function repay(
        uint256 _minPairTokens,
        address[] calldata _inTokens,
        uint256[] calldata _inTokenAmounts,
        OneInchZapLib.SwapParams[] calldata _swapParams
    ) external returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStakingRewardsV3 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function earned(address account) external view returns (uint256 tokensEarned);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function claim() external;

    function exit() external;

    function addToContractWhitelist(address _contract) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Solmate functions
library FixedPointMath {
    // Source: https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) { revert(0, 0) }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    // Source: https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) { revert(0, 0) }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {SushiAdapter} from "../adapters/SushiAdapter.sol";
import {I1inchAggregationRouterV4} from "../interfaces/I1inchAggregationRouterV4.sol";
import {Babylonian} from "./Babylonian.sol";
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {Curve2PoolAdapter} from "../adapters/Curve2PoolAdapter.sol";

library OneInchZapLib {
    using Curve2PoolAdapter for IStableSwap;
    using SafeERC20 for IERC20;
    using SushiAdapter for IUniswapV2Router02;

    enum ZapType {
        ZAP_IN,
        ZAP_OUT
    }

    struct SwapParams {
        address caller;
        I1inchAggregationRouterV4.SwapDescription desc;
        bytes data;
    }

    struct ZapInIntermediateParams {
        SwapParams swapFromIntermediate;
        SwapParams toPairTokens;
        address pairAddress;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 minPairTokens;
    }

    struct ZapInParams {
        SwapParams toPairTokens;
        address pairAddress;
        uint256 token0Amount;
        uint256 token1Amount;
        uint256 minPairTokens;
    }

    IUniswapV2Router02 public constant sushiSwapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    IStableSwap public constant crv2 = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     */
    function zapInIntermediate(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _swapFromIntermediate,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens
    ) public returns (uint256) {
        address[2] memory pairTokens = [IUniswapV2Pair(_pairAddress).token0(), IUniswapV2Pair(_pairAddress).token1()];

        // The dest token should be one of the tokens on the pair
        if (
            (_toPairTokens.desc.dstToken != pairTokens[0] && _toPairTokens.desc.dstToken != pairTokens[1])
                || (
                    _swapFromIntermediate.desc.dstToken != pairTokens[0]
                        && _swapFromIntermediate.desc.dstToken != pairTokens[1]
                )
        ) {
            revert INVALID_DEST_TOKEN();
        }

        perform1InchSwap(self, _swapFromIntermediate);

        if (_toPairTokens.desc.srcToken != pairTokens[0] && _toPairTokens.desc.srcToken != pairTokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        uint256 swapped = zapIn(self, _toPairTokens, _pairAddress, _token0Amount, _token1Amount, _minPairTokens);

        return swapped;
    }

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     */
    function zapIn(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens
    ) public returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);

        address[2] memory tokens = [pair.token0(), pair.token1()];

        // Validate sources
        if (_toPairTokens.desc.srcToken != tokens[0] && _toPairTokens.desc.srcToken != tokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        // Validate dest
        if (_toPairTokens.desc.dstToken != tokens[0] && _toPairTokens.desc.dstToken != tokens[1]) {
            revert INVALID_DEST_TOKEN();
        }

        perform1InchSwap(self, _toPairTokens);

        uint256 lpBought = uniDeposit(pair.token0(), pair.token1(), _token0Amount, _token1Amount);

        if (lpBought < _minPairTokens) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pairAddress, ZapType.ZAP_IN, lpBought);

        return lpBought;
    }

    function zapInFrom2Crv(
        I1inchAggregationRouterV4 self,
        SwapParams calldata _swapFromStable,
        SwapParams calldata _toPairTokens,
        address _pairAddress,
        uint256 _starting2crv,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens,
        address _intermediateToken
    ) public returns (uint256) {
        // The intermediate token should be one of the stable coins on `2Crv`
        if (_intermediateToken != crv2.coins(0) && _intermediateToken != crv2.coins(1)) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }

        // Swaps 2crv for stable using 2crv contract
        crv2.swap2CrvForStable(_intermediateToken, _starting2crv, _swapFromStable.desc.amount);

        // Perform zapIn intermediate with the stable received
        return zapInIntermediate(
            self, _swapFromStable, _toPairTokens, _pairAddress, _token0Amount, _token1Amount, _minPairTokens
        );
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     */
    function zapOutToOneTokenFromPair(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        SwapParams calldata _tokenSwap
    ) public returns (uint256 tokenOutAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        // Swap anyone of the tokens to the other
        tokenOutAmount = perform1InchSwap(self, _tokenSwap);

        emit Zap(msg.sender, _pair, ZapType.ZAP_OUT, tokenOutAmount);
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     */
    function zapOutAnyToken(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        SwapParams calldata _token0Swap,
        SwapParams calldata _token1Swap
    ) public returns (uint256 tokenOutAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        // Swap token0 to output
        uint256 token0SwappedAmount = perform1InchSwap(self, _token0Swap);

        // Swap token1 to output
        uint256 token1SwappedAmount = perform1InchSwap(self, _token1Swap);

        tokenOutAmount = token0SwappedAmount + token1SwappedAmount;
        emit Zap(msg.sender, _pair, ZapType.ZAP_OUT, tokenOutAmount);
    }

    function zapOutTo2crv(
        I1inchAggregationRouterV4 self,
        address _pair,
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        uint256 _min2CrvAmount,
        address _intermediateToken,
        SwapParams calldata _token0Swap,
        SwapParams calldata _token1Swap
    ) public returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);

        address[2] memory pairTokens = [IUniswapV2Pair(_pair).token0(), IUniswapV2Pair(_pair).token1()];

        // Check source tokens
        if (_token0Swap.desc.srcToken != pairTokens[0] || _token1Swap.desc.srcToken != pairTokens[1]) {
            revert INVALID_SOURCE_TOKEN();
        }

        if (_token0Swap.desc.dstToken != _intermediateToken || _token1Swap.desc.dstToken != _intermediateToken) {
            revert INVALID_DEST_TOKEN();
        }

        if (_intermediateToken != crv2.coins(0) && _intermediateToken != crv2.coins(1)) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }

        // Remove liquidity from pair
        _removeLiquidity(pair, _amount, _token0PairAmount, _token1PairAmount);

        uint256 stableAmount = perform1InchSwap(self, _token0Swap) + perform1InchSwap(self, _token1Swap);

        // Swap to 2crv
        IERC20(_intermediateToken).approve(address(crv2), stableAmount);

        return crv2.swapStableFor2Crv(_token0Swap.desc.dstToken, stableAmount, _min2CrvAmount);
    }

    function perform1InchSwap(I1inchAggregationRouterV4 self, SwapParams calldata _swap) public returns (uint256) {
        IERC20(_swap.desc.srcToken).safeApprove(address(self), _swap.desc.amount);
        (uint256 returnAmount,) = self.swap(_swap.caller, _swap.desc, _swap.data);
        IERC20(_swap.desc.srcToken).safeApprove(address(self), 0);

        return returnAmount;
    }

    /**
     * Removes liquidity from Sushi.
     */
    function _removeLiquidity(IUniswapV2Pair _pair, uint256 _amount, uint256 _minToken0Amount, uint256 _minToken1Amount)
        private
        returns (uint256 amountA, uint256 amountB)
    {
        _approveToken(address(_pair), address(sushiSwapRouter), _amount);
        return sushiSwapRouter.removeLiquidity(
            _pair.token0(), _pair.token1(), _amount, _minToken0Amount, _minToken1Amount, address(this), deadline
        );
    }

    /**
     * Adds liquidity to Sushi.
     */
    function uniDeposit(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired)
        public
        returns (uint256)
    {
        _approveToken(_tokenA, address(sushiSwapRouter), _amountADesired);
        _approveToken(_tokenB, address(sushiSwapRouter), _amountBDesired);

        (,, uint256 lp) = sushiSwapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            _amountADesired,
            _amountBDesired,
            1, // amountAMin - no need to worry about front-running since we handle that in main Zap
            1, // amountBMin - no need to worry about front-running since we handle that in main Zap
            address(this), // to
            deadline // deadline
        );

        return lp;
    }

    function _approveToken(address _token, address _spender) internal {
        IERC20 token = IERC20(_token);
        if (token.allowance(address(this), _spender) > 0) {
            return;
        } else {
            token.safeApprove(_spender, type(uint256).max);
        }
    }

    function _approveToken(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    /* ========== EVENTS ========== */
    /**
     * Emits when zapping in/out.
     * @param _sender sender performing zap action.
     * @param _pool address of the pool pair.
     * @param _type type of action (ie zap in or out).
     * @param _amount output amount after zap (pair amount for Zap In, output token amount for Zap Out)
     */
    event Zap(address indexed _sender, address indexed _pool, ZapType _type, uint256 _amount);

    /* ========== ERRORS ========== */
    error ERROR_SWAPPING_TOKENS();
    error ADDRESS_IS_ZERO();
    error HIGH_SLIPPAGE();
    error INVALID_INTERMEDIATE_TOKEN();
    error INVALID_SOURCE_TOKEN();
    error INVALID_DEST_TOKEN();
    error NON_EXISTANCE_PAIR();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    LPVault,
    FixedPointMath,
    OneInchZapLib,
    I1inchAggregationRouterV4,
    SafeERC20,
    IERC20,
    IUniswapV2Pair
} from "./LPVault.sol";
import {IUniswapV2Router01} from "../../interfaces/IUniswapV2Router01.sol";

contract BullLPVault is LPVault {
    using OneInchZapLib for I1inchAggregationRouterV4;
    using FixedPointMath for uint256;

    IUniswapV2Router01 private _sushiSwap;

    constructor(
        address _depositToken,
        address _storage,
        string memory _name,
        uint256 _riskPercentage,
        uint256 _feePercentage,
        address _feeReceiver,
        address payable _router,
        uint256 _cap,
        address _farm
    ) LPVault(_depositToken, _storage, _name, _riskPercentage, _feePercentage, _feeReceiver, _router, _cap, _farm) {
        vaultType = VaultType.BULL;
        _sushiSwap = OneInchZapLib.sushiSwapRouter;
    }

    /**
     * @notice Used for the strategy contract to borrow from the vault. Only a % of the vault tokens
     * can be borrowed. The borrowed amount is split and the underlying tokens are transferred to
     * the strategy
     * @param _minTokenOutputs The minimum amount of underlying tokens to receive when removing
     * liquidity
     */
    function borrow(uint256[2] calldata _minTokenOutputs) external onlyRole(STRATEGY) returns (uint256) {
        if (paused) {
            revert VAULT_PAUSED();
        }
        // Can only borrow once per epoch
        if (borrowed) {
            revert ALREADY_BORROWED();
        }

        IUniswapV2Pair pair = IUniswapV2Pair(address(depositToken));

        uint256 tokenBalance = pair.balanceOf(address(this));

        uint256 amount = (tokenBalance + _getStakedAmount()).mulDivDown(riskPercentage, ACCURACY);

        if (tokenBalance < amount) {
            _unstake(amount - tokenBalance);
        }

        borrowed = true;

        address[2] memory tokens = [pair.token0(), pair.token1()];

        pair.approve(address(_sushiSwap), amount);
        _sushiSwap.removeLiquidity(
            tokens[0], tokens[1], amount, _minTokenOutputs[0], _minTokenOutputs[1], address(this), block.timestamp
        );

        for (uint256 i; i < tokens.length; i++) {
            IERC20(tokens[i]).transfer(msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
        }

        emit Borrowed(msg.sender, amount);

        return amount;
    }

    /**
     * @notice Used for the strategy contract to repay the LP tokens that were borrowed. The
     * underlying pair tokens get trasnferred to the vault contract and then zapped in
     */
    function repay(
        uint256 _minPairTokens,
        address[] calldata _inTokens,
        uint256[] calldata _inTokenAmounts,
        OneInchZapLib.SwapParams[] calldata _swapParams
    ) external onlyRole(STRATEGY) returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(address(depositToken));

        // Get all input tokens
        for (uint256 i; i < _inTokens.length; i++) {
            IERC20(_inTokens[i]).transferFrom(msg.sender, address(this), _inTokenAmounts[i]);
        }

        // Perform all the swaps
        for (uint256 i; i < _swapParams.length; i++) {
            OneInchZapLib.SwapParams memory swap = _swapParams[i];
            if (swap.desc.dstReceiver != address(this)) {
                revert FORBIDDEN_SWAP_RECEIVER();
            }
            if (swap.desc.dstToken != pair.token0() && swap.desc.dstToken != pair.token1()) {
                revert FORBIDDEN_SWAP_DESTINATION();
            }
            router.perform1InchSwap(swap);
        }

        // Deposit as LP tokens
        uint256 actualLpTokens = OneInchZapLib.uniDeposit(
            pair.token0(),
            pair.token1(),
            IERC20(pair.token0()).balanceOf(address(this)),
            IERC20(pair.token1()).balanceOf(address(this))
        );

        if (actualLpTokens < _minPairTokens) {
            revert HIGH_SLIPPAGE();
        }

        emit Repayed(msg.sender, actualLpTokens);

        return actualLpTokens;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Libs
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {FixedPointMath} from "../../libraries/FixedPointMath.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {OneInchZapLib} from "../../libraries/OneInchZapLib.sol";

// Interfaces
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {UserLPStorage} from "./UserLPStorage.sol";
import {IUniswapV2Pair} from "../../interfaces/IUniswapV2Pair.sol";
import {IFeeReceiver} from "../../interfaces/IFeeReceiver.sol";
import {I1inchAggregationRouterV4} from "../../interfaces/I1inchAggregationRouterV4.sol";
import {IStakingRewardsV3} from "../../interfaces/IStakingRewardsV3.sol";
import {ILPVault} from "../../interfaces/ILPVault.sol";

abstract contract LPVault is ILPVault, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using FixedPointMath for uint256;
    using OneInchZapLib for I1inchAggregationRouterV4;

    uint256 public constant ACCURACY = 1e12;

    // Role for the keeper used to call the vault methods
    bytes32 public constant KEEPER = keccak256("KEEPER_ROLE");

    // Role for the governor to enact emergency and management methods
    bytes32 public constant GOVERNOR = keccak256("GOVERNOR_ROLE");

    // Role for the strategy contract to pull funds from the vault
    bytes32 public constant STRATEGY = keccak256("STRATEGY_ROLE");

    // Token being deposited
    IERC20 public depositToken;

    // Token Storage contract for unusable tokens
    UserLPStorage public lpStorage;

    // Vault name because all contracts deserve names
    string public name;

    VaultType public vaultType;

    // Epoch data
    Epoch[] public epochs;

    // Current epoch number
    uint256 public epoch;

    // Max cap for the current epoch
    uint256 public cap;

    // Current cap
    uint256 public totalDeposited;

    // Mapping user => user data
    mapping(address => UserEpochs) public userEpochs;

    // Mapping user => (epoch => amount)
    mapping(address => mapping(uint256 => uint256)) public userDepositPerEpoch;

    // Risk % (12 decimals) used to the define the percentage vaults can borrow each epoch
    uint256 public riskPercentage;

    // Flag to see if any funds have been borrowed this epoch
    bool public borrowed;

    // Percentage of vault ownership leaving in the next epoch
    uint256 private exitingPercentage;

    // Percentage of vault ownership fliping to another vault
    uint256 private flipingPercentage;

    // Percentage of each user fliping to another vault next epoch
    mapping(address => Flip) public flipUserInfo;

    // Users fliping next epoch
    address[] private usersFliping;

    // Paused for security reasons
    bool public paused;

    // Vault end epoch (only present if paused)
    uint256 public finalEpoch;

    // Epoch ended
    bool public epochEnded;

    ILPVault public flipVault;

    // Fee (12 decimals)
    uint256 public feePercentage;

    // Fee recever contract
    IFeeReceiver public feeReceiver;

    // 1Inch router for auto compounding
    I1inchAggregationRouterV4 internal router;

    // Staking rewards
    IStakingRewardsV3 public farm;

    constructor(
        address _depositToken,
        address _storage,
        string memory _name,
        uint256 _riskPercentage,
        uint256 _feePercentage,
        address _feeReceiver,
        address payable _router,
        uint256 _cap,
        address _farm
    ) {
        if (
            _depositToken == address(0) || _storage == address(0) || _feeReceiver == address(0) || _router == address(0)
                || _farm == address(0) || _cap == 0 || _riskPercentage == 0
        ) {
            revert WRONG_VAULT_ARGS();
        }
        epochs.push(Epoch(0, 0));
        depositToken = IERC20(_depositToken);
        lpStorage = UserLPStorage(_storage);
        name = _name;
        borrowed = false;
        paused = false;
        epochEnded = false;
        riskPercentage = _riskPercentage;
        feePercentage = _feePercentage;
        feeReceiver = IFeeReceiver(_feeReceiver);
        router = I1inchAggregationRouterV4(_router);
        cap = _cap;
        farm = IStakingRewardsV3(_farm);
        depositToken.safeApprove(_storage, type(uint256).max);
        depositToken.safeApprove(_farm, type(uint256).max);
        _grantRole(KEEPER, msg.sender);
        _grantRole(GOVERNOR, msg.sender);
    }

    // ============================= View Functions =====================

    function getUserStatus(address _user) external view returns (UserStatus) {
        return userEpochs[_user].status;
    }

    /**
     * Returns the working balance in this vault ( unused + staked)
     */
    function workingBalance() external view returns (uint256) {
        return depositToken.balanceOf(address(this)) + _getStakedAmount();
    }

    /**
     * Represents the amount the user earned so far + the deposits this epoch.
     * @param _user user to see the balanceOf.
     */
    function balanceOf(address _user) public view returns (uint256) {
        uint256 rewardsSoFar = 0;
        uint256 currentEpoch = epoch;
        uint256 depositsThisEpoch = userDepositPerEpoch[_user][currentEpoch + 1]; // Deposits are stored in next epoch
        Flip memory userFlip = flipUserInfo[_user];

        // If the user triggered the flip this is the only way to calculate his balance
        if (userFlip.userPercentage != 0) {
            Epoch memory currentEpochData = epochs[currentEpoch];
            uint256 totalAmount = epochEnded ? currentEpochData.endAmount : currentEpochData.startAmount;
            rewardsSoFar = totalAmount.mulDivDown(userFlip.userPercentage, ACCURACY);
        }
        // If the user has not signaled flip we must do different calculations
        else {
            // If epoch == 0 then there are no profits to be calculated only deposits
            if (currentEpoch != 0) {
                // If we are in a closed epoch we already have the final data for this epoch
                // But If we are in an open epoch we give the scenario where PnL for this epoch is 0 (because we still dont know if we are going to have profits)
                uint256 targetEpoch = epochEnded || currentEpoch == 0 ? currentEpoch : (currentEpoch - 1);
                rewardsSoFar = calculateRewardsAtEndOfEpoch(_user, targetEpoch);
            }
            if (!epochEnded) {
                depositsThisEpoch += userDepositPerEpoch[_user][currentEpoch]; // We have to account for the deposits the user made last epoch that are now being used
            }
        }
        return rewardsSoFar + depositsThisEpoch;
    }

    /**
     * @notice Calculates the amount deposited by the user so far (ignores rewards or losses)
     * @param _user user address
     */
    function deposited(address _user) public view returns (uint256) {
        return userEpochs[_user].deposited;
    }

    /**
     * @notice Calculates the amount of tokens the user owns at the start of the epoch
     * @param _user the user address
     * @param _epoch the epoch we want to calculate the rewards to
     */
    function calculateRewardsAtStartOfEpoch(address _user, uint256 _epoch) public view returns (uint256) {
        if (_epoch > epoch) {
            revert OPERATION_IN_FUTURE();
        }

        uint256 rewards = 0;
        UserEpochs memory userEpochData = userEpochs[_user];

        // We must only calculate the rewards until the signal exit
        uint256 lastEpoch = userEpochData.end != 0 ? userEpochData.end : _epoch;
        lastEpoch = lastEpoch < _epoch ? lastEpoch : _epoch;
        // No rewards for the future

        // Only if user actually deposited something
        if (userEpochData.epochs.length != 0) {
            for (uint256 currEpoch = userEpochData.epochs[0]; currEpoch <= lastEpoch; currEpoch++) {
                // If the user deposited to this epoch we must accomulate the deposits with the rewards already received
                uint256 userDepositsOnEpoch = userDepositPerEpoch[_user][currEpoch];
                rewards += userDepositsOnEpoch;

                // Only acommulate for other epochs
                if (currEpoch < lastEpoch) {
                    // The rewards are now based on the ratio of this epoch
                    Epoch memory epochData = epochs[currEpoch];
                    rewards = rewards.mulDivDown(epochData.endAmount, epochData.startAmount);
                }
            }
        }

        return rewards;
    }

    /**
     * @notice Calculates the amount of tokens the user owns at the end of the epoch
     * @param _user the user address
     * @param _epoch the epoch we want to calculate the rewards to
     */
    function calculateRewardsAtEndOfEpoch(address _user, uint256 _epoch) public view returns (uint256) {
        uint256 currentEpoch = epoch;

        if (_epoch > currentEpoch) {
            revert OPERATION_IN_FUTURE();
        }

        uint256 rewards = 0;
        UserEpochs memory userEpochData = userEpochs[_user];

        // We must only calculate the rewards until the signal exit
        uint256 lastEpoch = userEpochData.end != 0 ? userEpochData.end : _epoch;
        lastEpoch = lastEpoch < _epoch ? lastEpoch : _epoch;
        // No rewards for the future
        if (_epoch < currentEpoch || (_epoch == currentEpoch && epochEnded)) {
            // Only if user actually deposited something
            if (userEpochData.epochs.length != 0) {
                for (uint256 currEpoch = userEpochData.epochs[0]; currEpoch <= lastEpoch; currEpoch++) {
                    // If the user deposited to this epoch we must accomulate the deposits with the rewards already received
                    uint256 userDepositedThisEpoch = userDepositPerEpoch[_user][currEpoch];
                    rewards += userDepositedThisEpoch;

                    // The rewards are now based on the ratio of this epoch
                    Epoch memory epochData = epochs[currEpoch];
                    rewards = rewards.mulDivDown(epochData.endAmount, epochData.startAmount);
                }
            }
        }

        return rewards;
    }

    // ============================= User Functions =====================

    /**
     * @notice Deposits the given value to the users balance
     * @param _user the user to deposits funds to (can be != msg.sender)
     * @param _value the value being deposited
     */
    function deposit(address _user, uint256 _value) external nonReentrant {
        UserEpochs memory userEpochData = userEpochs[_user];
        uint256 currentEpoch = epoch;

        if (paused) {
            revert VAULT_PAUSED();
        }

        if (userEpochData.status == UserStatus.EXITING) {
            revert USER_EXITING();
        }

        if (userEpochData.status == UserStatus.FLIPPING) {
            revert USER_FLIPPING();
        }

        if (_value == 0 || _user == address(0)) {
            revert ZERO_VALUE();
        }

        if (totalDeposited + _value > cap && msg.sender != address(flipVault)) {
            revert VAULT_FULL();
        }

        depositToken.safeTransferFrom(msg.sender, address(this), _value);
        lpStorage.storeDeposit(_value);

        // If this is the first deposit this epoch
        uint256 userEpochDeposit = userDepositPerEpoch[_user][currentEpoch + 1];
        if (userEpochDeposit == 0) {
            userEpochs[_user].epochs.push(currentEpoch + 1);
        }
        // Update the deposited amount for the given epoch
        userDepositPerEpoch[_user][currentEpoch + 1] = userEpochDeposit + _value;
        userEpochs[_user].deposited += _value;
        userEpochs[_user].status = UserStatus.ACTIVE;
        totalDeposited += _value;

        emit Deposited(msg.sender, _user, _value);
    }

    function cancelDeposit() external nonReentrant {
        uint256 currentEpoch = epoch;
        uint256 amountDeposited = userDepositPerEpoch[msg.sender][currentEpoch + 1];
        if (paused) {
            revert VAULT_PAUSED();
        }
        if (epochEnded) {
            revert EPOCH_ENDED();
        }
        if (amountDeposited == 0) {
            revert ACTION_FORBIDEN_IN_USER_STATE();
        }

        userDepositPerEpoch[msg.sender][currentEpoch + 1] = 0;
        totalDeposited -= amountDeposited;
        userEpochs[msg.sender].deposited -= amountDeposited;

        lpStorage.refundDeposit(msg.sender, amountDeposited);
        emit CanceledDeposit(msg.sender, amountDeposited);
    }

    /**
     * @notice Signal flip to another vault for msg.sender (flip auto done at start of next epoch)
     */
    function signalFlip() external nonReentrant {
        ILPVault destination = flipVault;

        UserStatus destinationUserStatus = flipVault.getUserStatus(msg.sender);

        if (destinationUserStatus == UserStatus.EXITING) {
            revert USER_EXITING_ON_FLIP_VAULT();
        }

        if (destinationUserStatus == UserStatus.FLIPPING) {
            revert USER_FLIPPING_ON_FLIP_VAULT();
        }

        UserEpochs memory userEpochData = userEpochs[msg.sender];
        uint256 currentEpoch = epoch;

        if (paused) {
            revert VAULT_PAUSED();
        }

        if (userEpochData.epochs.length == 0) {
            revert NO_DEPOSITS_FOR_USER();
        }

        // User already exiting the vault
        if (userEpochData.status == UserStatus.EXITING) {
            revert USER_EXITING();
        }

        // User already flipping
        if (userEpochData.status == UserStatus.FLIPPING) {
            revert USER_FLIPPING();
        }

        // Estimate just to check if it will overflow the destination vault
        uint256 userAmountEstimate = calculateRewardsAtStartOfEpoch(msg.sender, currentEpoch);
        uint256 currentDestDeposits = destination.totalDeposited();
        if (currentDestDeposits != 0 && currentDestDeposits + userAmountEstimate > destination.cap()) {
            revert TARGET_VAULT_FULL();
        }

        uint256 userFlipingPercentage = _calculateUserPercentage(msg.sender);

        // Increment fliping percentage
        flipingPercentage += userFlipingPercentage;

        // Add users fliping data
        usersFliping.push(msg.sender);
        flipUserInfo[msg.sender] = Flip(userFlipingPercentage, address(destination));

        uint256 currentEpochDeposit = userDepositPerEpoch[msg.sender][currentEpoch + 1];

        UserStatus currentUserStatus = UserStatus.FLIPPING;

        // Send user deposits this epoch to the fliping vault now
        if (currentEpochDeposit != 0) {
            lpStorage.depositToVault(currentEpochDeposit);
            destination.deposit(msg.sender, currentEpochDeposit);
            currentUserStatus = UserStatus.NOT_ACTIVE;
        }

        // Update leaving deposits
        totalDeposited -= userEpochs[msg.sender].deposited;

        // Deletes the user data to avoid double withdraws
        _deleteUserData(msg.sender);

        userEpochs[msg.sender].status = currentUserStatus;

        emit Flipped(msg.sender, address(destination));
    }

    /**
     * @notice Signal exit for the msg.sender, user will be able to withdraw next epoch.
     */
    function signalExit() external nonReentrant {
        if (flipVault.getUserStatus(msg.sender) == UserStatus.FLIPPING) {
            revert USER_FLIPPING_ON_FLIP_VAULT();
        }

        UserEpochs memory userEpochData = userEpochs[msg.sender];

        if (paused) {
            revert VAULT_PAUSED();
        }

        // User will have to wait to exit, cant leave now, wait for next epoch (can cancel and then signal exit)
        if (userDepositPerEpoch[msg.sender][epoch + 1] != 0) {
            revert DEPOSITED_THIS_EPOCH();
        }

        // User already exiting the vault
        if (userEpochData.status == UserStatus.EXITING) {
            revert USER_EXITING();
        }

        // User already flipping
        if (userEpochData.status == UserStatus.FLIPPING) {
            revert USER_FLIPPING();
        }

        uint256 userExitPercentage = _calculateUserPercentage(msg.sender);
        exitingPercentage += userExitPercentage;

        userEpochs[msg.sender].end = epoch;
        userEpochs[msg.sender].status = UserStatus.EXITING;
        totalDeposited -= userEpochs[msg.sender].deposited;

        emit UserSignalExit(msg.sender);
    }

    /**
     * @notice Allows user to cancel a signal exit done this epoch
     */
    function cancelSignalExit() external nonReentrant {
        UserEpochs memory userEpochData = userEpochs[msg.sender];

        if (paused) {
            revert VAULT_PAUSED();
        }

        if (epochEnded) {
            revert EPOCH_ENDED();
        }

        if (userEpochData.status != UserStatus.EXITING) {
            revert ACTION_FORBIDEN_IN_USER_STATE();
        }

        uint256 userExitPercentage = _calculateUserPercentage(msg.sender);
        exitingPercentage -= userExitPercentage;

        userEpochs[msg.sender].end = 0;
        userEpochs[msg.sender].status = UserStatus.ACTIVE;
        totalDeposited += userEpochs[msg.sender].deposited;

        emit UserCancelSignalExit(msg.sender);
    }

    /**
     * @notice withdraw's user's tokens fom the vault and sends it to the user.
     */
    function withdraw() external nonReentrant {
        UserEpochs memory userEpochData = userEpochs[msg.sender];
        if (userEpochData.epochs.length == 0 || userEpochData.end >= epoch) {
            revert CANNOT_WITHDRAW();
        }
        // Calculate total rewards for every lock
        uint256 rewards = calculateRewardsAtEndOfEpoch(msg.sender, userEpochData.end);

        // Deletes the user data to avoid double withdraws
        _deleteUserData(msg.sender);

        // Transfer tokens out to the user
        lpStorage.refundCustomer(msg.sender, rewards);

        emit Withdrew(msg.sender, rewards);
    }

    // ============================= KEEPER Functions =====================

    /**
     * @notice closes the current epoch.
     * Before closing the profits for the epoch, it harvests and Zaps farming rewards
     * And after those calculations are done it deposits in behalf of the users to their respective flip vaults
     * @param _intermediateZapSwaps zaping arguments for tokens that are NOT part of the base pair
     * @param _directZapSwaps zaping arguments for tokens that are part of the base pair
     */
    function endEpoch(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) external onlyRole(KEEPER) nonReentrant {
        uint256 currentEpoch = epoch;
        uint256 endingEpoch = finalEpoch;
        if (epochEnded) {
            revert EPOCH_ENDED();
        }
        if (endingEpoch != 0 && currentEpoch == endingEpoch) {
            revert VAULT_PAUSED();
        }

        // Harvests from farm before doing any maths
        _harvestAndZap(_intermediateZapSwaps, _directZapSwaps);

        // Get balance of unused LP
        uint256 unused = depositToken.balanceOf(address(this));

        // Get the amount at the end of the epoch
        uint256 endBalance = unused + _getStakedAmount();

        // Calculate profit for fees (only charge fee on profit)
        Epoch memory currentEpochData = epochs[currentEpoch];
        uint256 profit = currentEpochData.startAmount > endBalance ? 0 : endBalance - currentEpochData.startAmount;

        // Div down because we are nice
        uint256 fees = feePercentage > 0 || profit > 0 ? profit.mulDivDown(feePercentage, ACCURACY) : 0;

        // Handle fees
        if (fees > 0) {
            if (fees > unused) {
                _unstake(fees - unused);
            }
            depositToken.safeApprove(address(feeReceiver), fees);
            feeReceiver.deposit(address(depositToken), fees);
            endBalance -= fees;
        }

        // Update storage
        currentEpochData.endAmount = endBalance;
        epochs[currentEpoch] = currentEpochData;

        if (flipingPercentage != 0) {
            // Diving up to avoid not having enough funds, whatever is left unused is later staked
            uint256 flipingAmount = flipingPercentage.mulDivUp(endBalance, ACCURACY);

            if (flipingAmount != 0) {
                unused = depositToken.balanceOf(address(this));
                // If we dont have enough balance we will need to unstake what we need to refund
                if (flipingAmount > unused) {
                    _unstake(flipingAmount - unused);
                }
            }

            // Flip all users to their respective vaults
            address[] memory usersFlipingList = usersFliping;
            for (uint256 i = 0; i < usersFlipingList.length; i++) {
                _flipUser(usersFlipingList[i]);
            }
            delete usersFliping;
            flipingPercentage = 0;
        }

        epochEnded = true;

        emit EpochEnded(currentEpoch, currentEpochData.endAmount, currentEpochData.startAmount);
    }

    /**
     * @notice Starts a new epoch.
     * Before starting a new epoch it calculates the amount of users wanting to exit and sends their balance to the storage contract
     * After increasing the epoch number it pulls in the balance from the storage contract and calculates the next epoch start amount.
     * @param _intermediateZapSwaps zaping arguments for tokens that are NOT part of the base pair (only required to be non empty when its paused)
     * @param _directZapSwaps zaping arguments for tokens that are part of the base pair (onlu required to be non empty when its paused)
     */
    function startEpoch(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) external onlyRole(KEEPER) nonReentrant {
        uint256 currentEpoch = epoch;
        uint256 endingEpoch = finalEpoch;
        if (!epochEnded) {
            revert STARTING_EPOCH_BEFORE_ENDING_LAST();
        }
        if (endingEpoch != 0 && currentEpoch == endingEpoch) {
            revert VAULT_PAUSED();
        }

        // Get the amount at the end of the epoch
        uint256 endBalance = epochs[currentEpoch].endAmount;

        // Add the exited funds to the unusable balance (dividing up to avoid any issues)
        uint256 unusableExited = exitingPercentage.mulDivUp(endBalance, ACCURACY);

        // Get balance of unused LP
        uint256 unused = depositToken.balanceOf(address(this));

        // Send unusable to lpStorage
        if (unusableExited != 0) {
            // If we dont have enough balance we will need to unstake what we need to refund
            if (unusableExited > unused) {
                _unstake(unusableExited - unused);
            }

            lpStorage.storeRefund(unusableExited);
        }

        // Start new Epoch
        epoch = currentEpoch + 1;

        // Get the deposited last epoch
        lpStorage.depositToVault();

        // Calculate starting balance for this epoch
        uint256 starting = depositToken.balanceOf(address(this)) + _getStakedAmount();

        // Everyone already exited to storage
        exitingPercentage = 0;

        // Update new epoch data
        epochs.push(Epoch(starting, 0));

        // If it is paused we dont want to stake, we want to unstake everything
        if (paused) {
            _exitFarm(_intermediateZapSwaps, _directZapSwaps);
        }
        // If its not paused resume normal course
        else {
            // Funds never stop
            _stakeUnused();
        }

        borrowed = false;
        epochEnded = false;

        emit EpochStart(currentEpoch, starting);
    }

    /**
     * @notice Auto compounds all the farming rewards.
     * @param _intermediateZapSwaps zaping arguments for tokens that are NOT part of the base pair
     * @param _directZapSwaps zaping arguments for tokens that are part of the base pair
     * @dev only KEEPER
     */
    function autoCompound(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) external onlyRole(KEEPER) returns (uint256) {
        uint256 earned = _harvestAndZap(_intermediateZapSwaps, _directZapSwaps);
        _stakeUnused();
        return earned;
    }

    // ============================= Strategy Functions =====================

    /**
     * @notice this function can be called by a strategy to request the funds to apply.
     * It only sends the risk percentage to the strategy, never more, nor less.
     * @dev This function can only be called once every epoch
     * @dev This is the default borrow function that sends in LP tokens, some vaults might have specific implementations
     */
    function borrowLP() external onlyRole(STRATEGY) {
        if (paused) {
            revert VAULT_PAUSED();
        }
        // Can only borrow once per epoch
        if (borrowed) {
            revert ALREADY_BORROWED();
        }
        uint256 tokenBalance = depositToken.balanceOf(address(this));
        uint256 amount = (tokenBalance + _getStakedAmount()).mulDivDown(riskPercentage, ACCURACY);
        if (tokenBalance < amount) {
            _unstake(amount - tokenBalance);
        }
        borrowed = true;
        depositToken.safeTransfer(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    // ============================= Management =============================

    /**
     * @notice Updates the Farm address and stakes all the balance in there
     * @param _farm new farm to deposit to
     * @dev only GOVERNOR
     */
    function updateFarm(address _farm) external onlyRole(GOVERNOR) {
        IStakingRewardsV3 currentFarm = farm;
        currentFarm.exit();
        depositToken.safeApprove(address(currentFarm), 0);
        farm = IStakingRewardsV3(_farm);
        depositToken.safeApprove(_farm, type(uint256).max);
        _stakeUnused();
    }

    /**
     * @notice Allows governor to set the fee percentage (0 means no fees).
     * @param _feePercentage the fee percentage with 12 decimals
     * @dev only GOVERNOR
     */
    function setFeePercentage(uint256 _feePercentage) external onlyRole(GOVERNOR) {
        feePercentage = _feePercentage;
    }

    /**
     * @notice Allows governor to set the fee receiver contract.
     * @param _feeReceiver the fee receiver address
     * @dev only GOVERNOR
     */
    function setFeeReceiver(address _feeReceiver) external onlyRole(GOVERNOR) {
        depositToken.safeApprove(address(feeReceiver), 0);
        feeReceiver = IFeeReceiver(_feeReceiver);
    }

    /**
     * @notice Allows governor to set the risk percentage
     * @param _riskPercentage risk percentage with 12 decimals
     * @dev only GOVERNOR
     */
    function setRiskPercentage(uint256 _riskPercentage) external onlyRole(GOVERNOR) {
        if (riskPercentage == 0) {
            revert ZERO_VALUE();
        }
        uint256 oldRisk = riskPercentage;
        riskPercentage = _riskPercentage;
        emit RiskPercentageUpdated(msg.sender, oldRisk, _riskPercentage);
    }

    /**
     * @notice Updates the current vault cap
     * @param _newCap the new vault cap
     * @dev only GOVERNOR
     */
    function setVaultCap(uint256 _newCap) external onlyRole(GOVERNOR) {
        cap = _newCap;
    }

    function setFlipVault(address _vault) external onlyRole(GOVERNOR) {
        flipVault = ILPVault(_vault);
    }

    /**
     * @notice Allows governor to provide the STRATEGY role to a strategy contract
     * @param _strat strategy address
     * @dev only GOVERNOR
     */
    function addStrategy(address _strat) external onlyRole(GOVERNOR) {
        _grantRole(STRATEGY, _strat);
    }

    /**
     * @notice Allows governor to remove the strategy STRATEGY role from a strategy contract
     * @param _strat strategy address
     * @dev only GOVERNOR
     */
    function removeStrategy(address _strat) external onlyRole(GOVERNOR) {
        _revokeRole(STRATEGY, _strat);
    }

    /**
     * @notice Allows governor to provide the KEEPER role to any address (usually a BOT)
     * @param _keeper keeper address
     * @dev only GOVERNOR
     */
    function addKeeper(address _keeper) external onlyRole(GOVERNOR) {
        _grantRole(KEEPER, _keeper);
    }

    /**
     * @notice Allows governor to remove the KEEPER from any address
     * @param _keeper keeper address
     * @dev only GOVERNOR
     */
    function removeKeeper(address _keeper) external onlyRole(GOVERNOR) {
        _revokeRole(KEEPER, _keeper);
    }

    /**
     * @notice Transfer the governor role to another address
     * @param _newGovernor The new governor address
     * @dev Will revoke the governor role from `msg.sender`. `_newGovernor` cannot be the zero
     * address
     */
    function transferGovernor(address _newGovernor) external onlyRole(GOVERNOR) {
        if (_newGovernor == address(0)) {
            revert ZERO_VALUE();
        }

        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);
    }

    // ============================= Migration/Emergency Functions =====================

    /**
     * @notice Allows governor to stop the vault
     * Stoping means the vault will no longer accept deposits and will allow all users to exit on the next epoch
     * @dev only GOVERNOR and only for emergencies
     */
    function stopVault() external onlyRole(GOVERNOR) {
        if (paused) {
            revert VAULT_PAUSED();
        }
        paused = true;
        finalEpoch = epoch + 1;
        emit VaultPaused(msg.sender, finalEpoch);
    }

    /**
     * Allows users to withdraw when an emergency is in place.
     * Only for the ones that did not signal before
     */
    function emergencyWithdraw() external nonReentrant {
        UserEpochs memory userEpochData = userEpochs[msg.sender];
        if (!paused) {
            revert EMERGENCY_OFF_NOT_PAUSED();
        }
        if (userEpochData.epochs.length == 0) {
            revert NO_DEPOSITS_FOR_USER();
        }
        if (epoch < finalEpoch) {
            revert TERMINAL_EPOCH_NOT_REACHED();
        }
        if (userEpochData.end != 0) {
            revert EMERGENCY_AFTER_SIGNAL();
        }

        // Calculate total rewards at the start of this epoch
        uint256 rewards = calculateRewardsAtStartOfEpoch(msg.sender, finalEpoch);

        totalDeposited -= userEpochData.deposited;

        // Deletes the user data to avoid double withdraws
        _deleteUserData(msg.sender);

        // Transfer tokens out to the user
        depositToken.safeTransfer(msg.sender, rewards);
        emit Withdrew(msg.sender, rewards);
    }

    /**
     * @notice Zaps the rewards to LP tokens just in case there is some emergency.
     * @param _intermediateZapSwaps zaping arguments for tokens that are NOT part of the base pair
     * @param _directZapSwaps zaping arguments for tokens that are part of the base pair
     * @dev only KEEPER
     */
    function zapToken(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) external onlyRole(KEEPER) returns (uint256) {
        return _zap(_intermediateZapSwaps, _directZapSwaps);
    }

    // ============================= Internal Functions ================================

    function _calculateUserPercentage(address _user) internal view returns (uint256) {
        uint256 userPercentage = 0;
        uint256 currentEpoch = epoch;
        Epoch memory epochData = epochs[currentEpoch];
        // If it ended now we can use the new data
        if (epochEnded) {
            // This calculates the amount the user is owed
            uint256 owedAmount = calculateRewardsAtEndOfEpoch(_user, currentEpoch);
            // Using the owed amount to calculate the percentage the user owns
            userPercentage = epochData.endAmount == 0 ? 0 : owedAmount.mulDivDown(ACCURACY, epochData.endAmount);
        }
        // If epoch not ended yet we must use data from last epoch
        else {
            // This calculates the amount the user owned on the vault at the end of last epoch
            uint256 owedAmount = calculateRewardsAtStartOfEpoch(_user, currentEpoch);
            // Considering the amount the user owned at the end of the last epoch we calculate the % he owns at the start of this epoch
            // So we know what percentage he will own at the end of the epoch (because percentages owned dont change mid epochs)
            userPercentage = epochData.startAmount == 0 ? 0 : owedAmount.mulDivDown(ACCURACY, epochData.startAmount);
        }
        return userPercentage;
    }

    function _deleteUserData(address _user) internal {
        // Deletes the user data to avoid double withdraws
        for (uint256 i = 0; i < userEpochs[_user].epochs.length; i++) {
            delete userDepositPerEpoch[_user][userEpochs[_user].epochs[i]];
        }
        delete userEpochs[_user];
    }

    function _flipUser(address _user) internal {
        Flip memory userFlip = flipUserInfo[_user];
        uint256 userAmount = epochs[epoch].endAmount.mulDivDown(userFlip.userPercentage, ACCURACY);

        if (userAmount != 0) {
            depositToken.approve(userFlip.destinationVault, userAmount);
            LPVault(userFlip.destinationVault).deposit(_user, userAmount);
        }

        delete flipUserInfo[_user];

        userEpochs[_user].status = UserStatus.NOT_ACTIVE;
    }

    function _stakeUnused() internal {
        uint256 unused = depositToken.balanceOf(address(this));
        if (unused > 0) {
            farm.stake(unused);
        }
    }

    function _unstake(uint256 _value) internal {
        farm.unstake(_value);
    }

    function _exitFarm(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) internal {
        farm.exit();
        _harvestAndZap(_intermediateZapSwaps, _directZapSwaps);
    }

    function _harvestAndZap(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) internal returns (uint256) {
        _harvest();
        uint256 zapped = _zap(_intermediateZapSwaps, _directZapSwaps);
        return zapped;
    }

    function _harvest() internal {
        farm.claim();
    }

    function _getStakedAmount() internal view returns (uint256) {
        return farm.balanceOf(address(this));
    }

    function _zap(
        OneInchZapLib.ZapInIntermediateParams[] calldata _intermediateZapSwaps,
        OneInchZapLib.ZapInParams[] calldata _directZapSwaps
    ) internal returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _intermediateZapSwaps.length; i++) {
            _validateDesc(_intermediateZapSwaps[i].swapFromIntermediate.desc);
            _validateDesc(_intermediateZapSwaps[i].toPairTokens.desc);
            uint256 rewardBalance =
                IERC20(_intermediateZapSwaps[i].swapFromIntermediate.desc.srcToken).balanceOf(address(this));
            if (rewardBalance > 0) {
                total += router.zapInIntermediate(
                    _intermediateZapSwaps[i].swapFromIntermediate,
                    _intermediateZapSwaps[i].toPairTokens,
                    address(depositToken),
                    _intermediateZapSwaps[i].token0Amount,
                    _intermediateZapSwaps[i].token1Amount,
                    _intermediateZapSwaps[i].minPairTokens
                );
            }
        }
        for (uint256 i = 0; i < _directZapSwaps.length; i++) {
            _validateDesc(_directZapSwaps[i].toPairTokens.desc);
            uint256 rewardBalance = IERC20(_directZapSwaps[i].toPairTokens.desc.srcToken).balanceOf(address(this));
            if (rewardBalance > 0) {
                total += router.zapIn(
                    _directZapSwaps[i].toPairTokens,
                    address(depositToken),
                    _directZapSwaps[i].token0Amount,
                    _directZapSwaps[i].token1Amount,
                    _directZapSwaps[i].minPairTokens
                );
            }
        }
        return total;
    }

    /**
     * Anti-rugginator 3000.
     */
    function _validateDesc(I1inchAggregationRouterV4.SwapDescription memory desc) internal view {
        if (desc.dstReceiver != address(this) || desc.minReturnAmount == 0) {
            revert INVALID_SWAP();
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Libs
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

// Interfaces
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * Olds unused user funds from LP vault.
 */
contract UserLPStorage is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public unusedDeposited;

    uint256 public unusedExited;

    IERC20 public lpToken;

    address public vault;

    constructor(address _lpToken) {
        lpToken = IERC20(_lpToken);
    }

    /**
     * Set vault that does the operations
     * @param _vault vault
     */
    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    /**
     * Stores amount when the user signaled exit
     * @param _value amount to store
     */
    function storeRefund(uint256 _value) public nonReentrant onlyVault {
        unusedExited += _value;
        lpToken.safeTransferFrom(vault, address(this), _value);
        emit StoredRefund(msg.sender, _value);
    }

    /**
     * Called when the user claims an exit.
     * @param _to user address
     * @param _value value sent to user
     */
    function refundCustomer(address _to, uint256 _value) public nonReentrant onlyVault {
        if (_value > unusedExited) {
            revert NOT_ENOUGH_BALANCE();
        }
        unusedExited -= _value;
        lpToken.safeTransfer(_to, _value);
        emit Refunded(msg.sender, _value, _to);
    }

    /**
     * Called when a user cancels a deposit.
     * @param _to user address
     * @param _value value sent to user
     */
    function refundDeposit(address _to, uint256 _value) public nonReentrant onlyVault {
        if (_value > unusedDeposited) {
            revert NOT_ENOUGH_BALANCE();
        }
        unusedDeposited -= _value;
        lpToken.safeTransfer(_to, _value);
        emit RefundedDeposit(msg.sender, _value, _to);
    }

    /**
     * Stores a user deposit before the funds are used next epoch.
     * @param _value value stored
     */
    function storeDeposit(uint256 _value) public nonReentrant onlyVault {
        unusedDeposited += _value;
        lpToken.safeTransferFrom(vault, address(this), _value);
        emit StoredDeposit(msg.sender, _value);
    }

    /**
     * Sends all stored unused deposits to the vault (refunds are not sent)
     */
    function depositToVault() public nonReentrant onlyVault {
        if (unusedDeposited != 0) {
            lpToken.safeTransfer(vault, unusedDeposited);
            emit DepositToVault(msg.sender, unusedDeposited);
        }
        unusedDeposited = 0;
    }

    /**
     * Sends a specific amount of deposits to the vault (refunds are not sent)
     * @param _value amount to send
     */
    function depositToVault(uint256 _value) public nonReentrant onlyVault {
        if (_value > unusedDeposited) {
            revert NOT_ENOUGH_BALANCE();
        }
        lpToken.safeTransfer(vault, _value);
        unusedDeposited -= _value;
        emit DepositToVault(msg.sender, _value);
    }

    function emergencyWithdraw(address _to) public onlyOwner {
        uint256 value = lpToken.balanceOf(address(this));
        lpToken.safeTransfer(_to, value);
    }

    // ============================== Events ==============================

    /**
     * @notice Emmited when a refund is stored in this contract
     * @param _vault vault that stored
     * @param _value value that was stored
     */
    event StoredRefund(address _vault, uint256 _value);

    /**
     * @notice Emmited when a deposit is stored in this contract
     * @param _vault vault that stored
     * @param _value value that was stored
     */
    event StoredDeposit(address _vault, uint256 _value);

    /**
     * @notice Emmited when a claim is sent to the user
     * @param _vault vault that stored
     * @param _value value that was stored
     * @param _user user that received the funds
     */
    event Refunded(address _vault, uint256 _value, address _user);

    /**
     * @notice Emmited when a deposit for a future epoch is sent to the user
     * @param _vault vault that stored
     * @param _value value that was stored
     * @param _user user that received the funds
     */
    event RefundedDeposit(address _vault, uint256 _value, address _user);

    /**
     * @notice Emmited when the vault requests funds for next epoch
     * @param _vault vault that stored
     * @param _value value that was stored
     */
    event DepositToVault(address _vault, uint256 _value);

    // ============================== Modifiers ==============================

    modifier onlyVault() {
        if (msg.sender != vault) {
            revert Only_Vault();
        }
        _;
    }

    // ============================== Erors ==============================

    error Only_Vault(); // Only vault
    error NOT_ENOUGH_BALANCE();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {BullLPVault} from "../BullLPVault.sol";

contract DpxEthBullVault is BullLPVault {
    constructor(
        address _lpToken,
        address _storageAddress,
        uint256 _riskPercentage,
        uint256 _feePercentage,
        address _feeReceiver,
        address _oneInchRouter,
        uint256 _vaultCap,
        address _DPXETHFarm
    )
        BullLPVault(
            _lpToken, // Dpx-Eth LP Token
            _storageAddress, // Storage address
            "JonesDpxEthBullVault",
            _riskPercentage, // Risk percentage (1e12 = 100%)
            _feePercentage, // Fee percentage (1e12 = 100%)
            _feeReceiver, // Fee receiver
            payable(_oneInchRouter), // 1Inch router
            _vaultCap, // Cap
            _DPXETHFarm // Dpx-Eth Farm
        )
    {}
}