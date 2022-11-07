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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ISsovV3} from "../interfaces/ISsovV3.sol";
import {ISsovV3Viewer} from "../interfaces/ISsovV3Viewer.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

library SsovAdapter {
    using SafeERC20 for IERC20;

    ISsovV3Viewer constant viewer = ISsovV3Viewer(0x9abE93F7A70998f1836C2Ee0E21988Ca87072001);

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of Collateral to deposit.
     * @param _depositor The depositor contract
     * @return tokenId tokenId of the deposit.
     */
    function depositSSOV(ISsovV3 self, uint256 _strikeIndex, uint256 _amount, address _depositor)
        public
        returns (uint256 tokenId)
    {
        tokenId = self.deposit(_strikeIndex, _amount, _depositor);
        uint256 epoch = self.currentEpoch();
        emit SSOVDeposit(epoch, _strikeIndex, _amount, tokenId);
    }

    /**
     * Purchase Dopex option.
     * @param self Dopex SSOV contract.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of options to purchase.
     * @param _buyer Jones strategy contract.
     * @return Whether deposit was successful.
     */
    function purchaseOption(ISsovV3 self, uint256 _strikeIndex, uint256 _amount, address _buyer)
        public
        returns (bool)
    {
        (uint256 premium, uint256 totalFee) = self.purchase(_strikeIndex, _amount, _buyer);

        emit SSOVPurchase(
            self.currentEpoch(), _strikeIndex, _amount, premium, totalFee, address(self.collateralToken())
            );

        return true;
    }

    function _settleEpoch(
        ISsovV3 self,
        uint256 _epoch,
        IERC20 _strikeToken,
        address _caller,
        uint256 _strikePrice,
        uint256 _settlementPrice,
        uint256 _strikeIndex,
        uint256 _settlementCollateralExchangeRate
    ) private {
        uint256 strikeTokenBalance = _strikeToken.balanceOf(_caller);
        uint256 pnl =
            self.calculatePnl(_settlementPrice, _strikePrice, strikeTokenBalance, _settlementCollateralExchangeRate);
        if (strikeTokenBalance > 0 && pnl > 0) {
            _strikeToken.safeApprove(address(self), strikeTokenBalance);
            self.settle(_strikeIndex, strikeTokenBalance, _epoch, _caller);
        }
    }

    /**
     * Settles options from Dopex SSOV at the end of an epoch.
     * @param _caller the address settling the epoch
     * @param _epoch the epoch to settle
     * @param _strikes the strikes to settle
     * Returns bool to indicate if epoch settlement was successful.
     */
    function settleEpoch(ISsovV3 self, address _caller, uint256 _epoch, uint256[] memory _strikes)
        public
        returns (bool)
    {
        if (_strikes.length == 0) {
            return false;
        }

        ISsovV3.EpochData memory epochData = self.getEpochData(_epoch);
        uint256[] memory epochStrikes = epochData.strikes;
        uint256 price = epochData.settlementPrice;

        address[] memory strikeTokens = viewer.getEpochStrikeTokens(_epoch, self);
        for (uint256 i = 0; i < _strikes.length; i++) {
            uint256 index = _strikes[i];
            IERC20 strikeToken = IERC20(strikeTokens[index]);
            uint256 strikePrice = epochStrikes[index];
            _settleEpoch(
                self,
                _epoch,
                strikeToken,
                _caller,
                strikePrice,
                price,
                index,
                epochData.settlementCollateralExchangeRate
            );
        }
        return true;
    }

    function settleAllStrikesOnEpoch(ISsovV3 self, uint256 _epoch) public {
        ISsovV3.EpochData memory epochData = self.getEpochData(_epoch);
        uint256[] memory strikes = epochData.strikes;
        address[] memory strikeTokens = viewer.getEpochStrikeTokens(_epoch, self);

        for (uint256 i; i < strikes.length; i++) {
            _settleEpoch(
                self,
                _epoch,
                IERC20(strikeTokens[i]),
                address(this),
                strikes[i],
                epochData.settlementPrice,
                i,
                epochData.settlementCollateralExchangeRate
            );
        }
    }

    /**
     * Allows withdraw of all erc721 tokens ssov deposit for the given epoch and strikes.
     */
    function withdrawEpoch(ISsovV3 self, uint256 _epoch, uint256[] memory _strikes, address _caller) public {
        uint256[] memory tokenIds = viewer.walletOfOwner(_caller, self);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 epoch, uint256 strike,,,) = self.writePosition(tokenIds[i]);
            if (epoch == _epoch) {
                for (uint256 j = 0; j < _strikes.length; j++) {
                    if (strike == _strikes[j]) {
                        self.withdraw(tokenIds[i], _caller);
                    }
                }
            }
        }
    }

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposited Collateral Token amount
     * @param _tokenId token ID of the deposit
     */
    event SSOVDeposit(uint256 indexed _epoch, uint256 _strikeIndex, uint256 _amount, uint256 _tokenId);

    /**
     * emitted when new put/call from SSOV is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount put amount
     * @param _premium put/call premium
     * @param _totalFee put/call total fee
     */
    event SSOVPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );
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
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ISsovV3 is IERC721 {
    struct Addresses {
        address feeStrategy;
        address stakingStrategy;
        address optionPricing;
        address priceOracle;
        address volatilityOracle;
        address feeDistributor;
        address optionsTokenImplementation;
    }

    struct EpochData {
        bool expired;
        uint256 startTime;
        uint256 expiry;
        uint256 settlementPrice;
        uint256 totalCollateralBalance; // Premium + Deposits from all strikes
        uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
        uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
        uint256[] strikes;
        uint256[] totalRewardsCollected;
        uint256[] rewardDistributionRatios;
        address[] rewardTokensToDistribute;
    }

    struct EpochStrikeData {
        address strikeToken;
        uint256 totalCollateral;
        uint256 activeCollateral;
        uint256 totalPremiums;
        uint256 checkpointPointer;
        uint256[] rewardStoredForPremiums;
        uint256[] rewardDistributionRatiosForPremiums;
    }

    struct VaultCheckpoint {
        uint256 activeCollateral;
        uint256 totalCollateral;
        uint256 accruedPremium;
    }

    struct WritePosition {
        uint256 epoch;
        uint256 strike;
        uint256 collateralAmount;
        uint256 checkpointIndex;
        uint256[] rewardDistributionRatios;
    }

    function expire() external;

    function deposit(uint256 strikeIndex, uint256 amount, address user) external returns (uint256 tokenId);

    function purchase(uint256 strikeIndex, uint256 amount, address user)
        external
        returns (uint256 premium, uint256 totalFee);

    function settle(uint256 strikeIndex, uint256 amount, uint256 epoch, address to) external returns (uint256 pnl);

    function withdraw(uint256 tokenId, address to)
        external
        returns (uint256 collateralTokenWithdrawAmount, uint256[] memory rewardTokenWithdrawAmounts);

    function getUnderlyingPrice() external view returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function getVolatility(uint256 _strike) external view returns (uint256);

    function calculatePremium(uint256 _strike, uint256 _amount, uint256 _expiry)
        external
        view
        returns (uint256 premium);

    function calculatePnl(uint256 price, uint256 strike, uint256 amount, uint256 collateralExchangeRate)
        external
        pure
        returns (uint256);

    function calculatePurchaseFees(uint256 strike, uint256 amount) external view returns (uint256);

    function calculateSettlementFees(uint256 settlementPrice, uint256 pnl, uint256 amount)
        external
        view
        returns (uint256);

    function getEpochTimes(uint256 epoch) external view returns (uint256 start, uint256 end);

    function writePosition(uint256 tokenId)
        external
        view
        returns (
            uint256 epoch,
            uint256 strike,
            uint256 collateralAmount,
            uint256 checkpointIndex,
            uint256[] memory rewardDistributionRatios
        );

    function getEpochStrikeTokens(uint256 epoch) external view returns (address[] memory);

    function getEpochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function getLastVaultCheckpoint(uint256 epoch, uint256 strike) external view returns (VaultCheckpoint memory);

    function underlyingSymbol() external returns (string memory);

    function isPut() external view returns (bool);

    function addresses() external view returns (Addresses memory);

    function collateralToken() external view returns (IERC20);

    function currentEpoch() external view returns (uint256);

    function expireDelayTolerance() external returns (uint256);

    function collateralPrecision() external returns (uint256);

    function getEpochData(uint256 epoch) external view returns (EpochData memory);

    function epochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    // Dopex management only
    function expire(uint256 _settlementPrice, uint256 _settlementCollateralExchangeRate) external;

    function bootstrap(uint256[] memory strikes, uint256 expiry, string memory expirySymbol) external;

    function addToContractWhitelist(address _contract) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISsovV3} from "./ISsovV3.sol";

interface ISsovV3Viewer {
    function getEpochStrikeTokens(uint256 epoch, ISsovV3 ssov) external view returns (address[] memory strikeTokens);

    function walletOfOwner(address owner, ISsovV3 ssov) external view returns (uint256[] memory tokenIds);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router01} from "../interfaces/IUniswapV2Router01.sol";
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {ISsovV3} from "../interfaces/ISsovV3.sol";
import {I1inchAggregationRouterV4} from "../interfaces/I1inchAggregationRouterV4.sol";
import {OneInchZapLib} from "./OneInchZapLib.sol";

library LPStrategyLib {
    // Represents 100%
    uint256 public constant basePercentage = 1e12;

    // Arbitrum sushi router
    IUniswapV2Router01 constant swapRouter = IUniswapV2Router01(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    // Arbitrum curve stable swap (2Crv)
    IStableSwap constant stableSwap = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    I1inchAggregationRouterV4 constant oneInch =
        I1inchAggregationRouterV4(payable(0x1111111254fb6c44bAC0beD2854e76F90643097d));

    struct StrikePerformance {
        // Strike index
        uint256 index;
        // Strike price
        uint256 strike;
        // Distance to ITM
        uint256 delta;
        // `true` if in the money, `false` otherwise
        bool itm;
    }

    // To prevent Stack too deep error
    struct BuyOptionsInput {
        // Ssov contract
        ISsovV3 ssov;
        // Ssov epoch
        uint256 ssovEpoch;
        // Ssov epoch expiry
        uint256 ssovExpiry;
        // Amount of collateral available
        uint256 collateralBalance;
        // The % collateral to use to buy options
        uint256[] collateralPercentages;
        // The % limits of collateral that can be used
        uint256[] limits;
        // The % of puts bought so far
        uint256[] used;
        // The expected order of strikes
        uint256[] strikesOrderMatch;
        // If `true` it will ignore the strikes that are ITM
        bool ignoreITM;
    }

    // To prevent Stack too deep error
    struct SwapAndBuyOptionsInput {
        // Ssov contract
        ISsovV3 ssov;
        // The token that we want to sell to buy calls
        IERC20 tokenToSwap;
        // Ssov epoch
        uint256 ssovEpoch;
        // Ssov epoch expiry
        uint256 ssovExpiry;
        // Amount of collateral available
        uint256 collateralBalance;
        // The amount of tokens available to swap
        uint256 tokenToSwapBalance;
        // The % of tokens to sell per strikes. Strike order should follow `strikesOrderMatch`
        uint256[] collateralPercentages;
        // The % of `tokenToSwap` balance to swap. It applies to `tokenToSwapBalance`
        uint256 swapPercentage;
        // 1Inch swap configuration
        OneInchZapLib.SwapParams swapParams;
        // The % limits of swaps per strike per strike. Strike order should follow the SSOV strike order
        uint256[] limits;
        // The % of swapps so far per strike. Strike order should follow the SSOV strike order
        uint256[] used;
        // The expected order of strikes
        uint256[] strikesOrderMatch;
        // The % limit of swapped tokens
        uint256 swapLimit;
        // The % of tokens that have been used for swaps
        uint256 usedForSwaps;
        // If `true` it will ignore the strikes that are ITM
        bool ignoreITM;
    }

    /**
     * @notice Buys a % of puts according to strategy limits
     * @return The updated % of options bought
     */
    function buyOptions(BuyOptionsInput memory _input) public returns (uint256, uint256[] memory) {
        if (_input.collateralPercentages.length > _input.limits.length) {
            revert InvalidNumberOfPercentages();
        }

        // Nothing to do
        if (_input.collateralBalance == 0 || block.timestamp >= _input.ssovExpiry) {
            // Since we didn't buy anything we just return the current % of buys
            return (0, _input.used);
        }

        IERC20 collateral = _input.ssov.collateralToken();

        // Approve so we can use `2Crv` to buy options
        collateral.approve(address(_input.ssov), type(uint256).max);

        // Get the ssov epoch strikes
        StrikePerformance[] memory strikes = getSortedStrikes(_input.ssov, _input.ssovEpoch);

        if (strikes.length > _input.collateralPercentages.length) {
            revert InvalidNumberOfPercentages();
        }

        uint256 spent;
        uint256 percentageIndex;

        for (uint256 i; i < strikes.length; i++) {
            if (_input.ignoreITM == true && strikes[i].itm == true) {
                continue;
            }

            if (_input.collateralPercentages[percentageIndex] == 0) {
                percentageIndex++;
                continue;
            }

            uint256 strikeIndex = strikes[i].index;
            // Check that the order of strikes is the one expected by the caller
            if (_input.strikesOrderMatch[i] != strikeIndex) {
                revert InvalidStrikeOrder(_input.strikesOrderMatch[i], strikeIndex);
            }

            if (
                _input.used[percentageIndex] + _input.collateralPercentages[percentageIndex]
                    > _input.limits[percentageIndex]
            ) {
                percentageIndex++;
                continue;
            }

            uint256 availableCollateral =
                (_input.collateralBalance * _input.collateralPercentages[percentageIndex]) / basePercentage;

            // Estimate the amount of options we can buy with `availableCollateral`
            uint256 optionsToBuy =
                _estimateOptionsPerToken(_input.ssov, availableCollateral, strikes[i].strike, _input.ssovExpiry);

            // Purchase the options
            // NOTE: This will fail if there is not enough liquidity
            (uint256 premium, uint256 fee) = _input.ssov.purchase(strikeIndex, optionsToBuy, address(this));

            // Update buy percentages
            _input.used[percentageIndex] += _input.collateralPercentages[percentageIndex];
            spent = premium + fee;
            percentageIndex++;
        }

        // Reset approvals
        collateral.approve(address(_input.ssov), 0);

        // Return the updated % of options bought
        return (spent, _input.used);
    }

    /**
     * @notice Swaps a % of tokens to buy calls using strategy limits
     * @return The updated % of swapped tokens
     */
    function swapAndBuyOptions(SwapAndBuyOptionsInput memory _input)
        external
        returns (uint256, uint256, uint256[] memory)
    {
        uint256 collateralFromSwap;
        // Swap
        if (_input.swapParams.desc.amount > 0 && _input.swapPercentage + _input.usedForSwaps <= _input.swapLimit) {
            _input.tokenToSwap.approve(address(oneInch), _input.swapParams.desc.amount);
            (collateralFromSwap,) =
                oneInch.swap(_input.swapParams.caller, _input.swapParams.desc, _input.swapParams.data);

            _input.usedForSwaps += _input.swapPercentage;
        }

        // Buy options
        (uint256 spent, uint256[] memory used) = buyOptions(
            BuyOptionsInput(
                _input.ssov,
                _input.ssovEpoch,
                _input.ssovExpiry,
                _input.collateralBalance,
                _input.collateralPercentages,
                _input.limits,
                _input.used,
                _input.strikesOrderMatch,
                _input.ignoreITM
            )
        );

        return (spent, _input.usedForSwaps, used);
    }

    /**
     * @notice Rerturns the `_ssov` `_ssovEpoch` strikes ordered by their distance to the underlying
     * asset price
     * @param _ssov The SSOV contract
     * @param _ssovEpoch The epoch we want to get the strikes on `_ssov`
     */
    function getSortedStrikes(ISsovV3 _ssov, uint256 _ssovEpoch) public view returns (StrikePerformance[] memory) {
        uint256 currentPrice = _ssov.getUnderlyingPrice();
        uint256[] memory strikes = _ssov.getEpochData(_ssovEpoch).strikes;
        bool isPut = _ssov.isPut();

        uint256 delta;
        bool itm;

        StrikePerformance[] memory performances = new StrikePerformance[](
            strikes.length
        );

        for (uint256 i; i < strikes.length; i++) {
            delta = strikes[i] > currentPrice ? strikes[i] - currentPrice : currentPrice - strikes[i];
            itm = isPut ? strikes[i] > currentPrice : currentPrice > strikes[i];
            performances[i] = StrikePerformance(i, strikes[i], delta, itm);
        }

        _sortPerformances(performances, int256(0), int256(performances.length - 1));

        return performances;
    }

    /**
     * @notice Estimates the amount of options that can be buy with `_tokenAmount`
     * @param _ssov The ssov contract
     * @param _tokenAmount The amount of tokens
     * @param _strike The strike to calculate
     * @param _expiry The ssov epoch expiry
     */
    function _estimateOptionsPerToken(ISsovV3 _ssov, uint256 _tokenAmount, uint256 _strike, uint256 _expiry)
        private
        view
        returns (uint256)
    {
        // The amount of tokens used to buy an amount of options is
        // the premium + purchase fee.
        // We calculate those values using `precision` as the amount.
        // Knowing how many tokens that cost we can estimate how many
        // Options we can buy using `_tokenAmount`
        uint256 precision = 10000e18;

        uint256 premiumPerOption = _ssov.calculatePremium(_strike, precision, _expiry);
        uint256 feePerOption = _ssov.calculatePurchaseFees(_strike, precision);

        uint256 pricePerOption = premiumPerOption + feePerOption;

        return (_tokenAmount * precision) / pricePerOption;
    }

    /**
     * @notice Sorts `_strikes` using quick sort
     * @param _strikes The array of strikes to sort
     * @param _left The lower index of the `_strikes` array
     * @param _right The higher index of the `_strikes` array
     */
    function _sortPerformances(StrikePerformance[] memory _strikes, int256 _left, int256 _right) internal view {
        int256 i = _left;
        int256 j = _right;

        uint256 pivot = _strikes[uint256(_left + (_right - _left) / 2)].delta;

        while (i < j) {
            while (_strikes[uint256(i)].delta < pivot) {
                i++;
            }
            while (pivot < _strikes[uint256(j)].delta) {
                j--;
            }

            if (i <= j) {
                (_strikes[uint256(i)], _strikes[uint256(j)]) = (_strikes[uint256(j)], _strikes[uint256(i)]);
                i++;
                j--;
            }
        }

        if (_left < j) {
            _sortPerformances(_strikes, _left, j);
        }

        if (i < _right) {
            _sortPerformances(_strikes, i, _right);
        }
    }

    error InvalidAmountOfMinimumOutputs();
    error InvalidNumberOfPercentages();
    error InvalidStrikeOrder(uint256 expected, uint256 actual);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {SushiAdapter} from "../adapters/SushiAdapter.sol";
import {Babylonian} from "./Babylonian.sol";

library ZapLib {
    using SafeERC20 for IERC20;
    using SushiAdapter for IUniswapV2Router02;

    enum ZapType {
        ZAP_IN,
        ZAP_OUT
    }

    IUniswapV2Factory public constant sushiSwapFactoryAddress =
        IUniswapV2Factory(0xc35DADB65012eC5796536bD9864eD8773aBc74C4);

    IUniswapV2Router02 public constant sushiSwapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address public constant wethTokenAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
     * @param _fromToken The ERC20 token used
     * @param _pair The Sushiswap pair address
     * @param _amount The amount of fromToken to invest
     * @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
     * @param _intermediateToken intermediate token to swap to (must be one of the tokens in `_pair`) if `_fromToken` is not part of a pair token. Can be zero address if swap is not necessary.
     * @return Amount of LP bought
     */
    function ZapIn(
        address _fromToken,
        address _pair,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _intermediateToken
    ) external returns (uint256) {
        _checkZeroAddress(_fromToken);
        _checkZeroAddress(_pair);

        uint256 lpBought = _performZapIn(_fromToken, _pair, _amount, _intermediateToken);

        if (lpBought < _minPoolTokens) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pair, ZapType.ZAP_IN, lpBought);

        return lpBought;
    }

    /**
     * @notice Removes liquidity from Sushiswap pools and swaps pair tokens to `_tokenOut`.
     * @param _pair The pair token to remove liquidity from
     * @param _tokenOut The ERC20 token to zap out to
     * @param _amount The amount of liquidity to remove
     * @param _minOut Minimum amount of `_tokenOut` whne zapping out
     * @return _tokenOutAmount Amount of zap out token
     */
    function ZapOut(address _pair, address _tokenOut, uint256 _amount, uint256 _minOut)
        public
        returns (uint256 _tokenOutAmount)
    {
        _checkZeroAddress(_tokenOut);
        _checkZeroAddress(_pair);

        _tokenOutAmount = _performZapOut(_pair, _tokenOut, _amount);

        if (_tokenOutAmount < _minOut) {
            revert HIGH_SLIPPAGE();
        }

        emit Zap(msg.sender, _pair, ZapType.ZAP_IN, _tokenOutAmount);
    }

    /**
     * @notice Quotes zap in amount for adding liquidity pair from `_inputToken`.
     * @param _inputToken The input token used for zapping in
     * @param _pairAddress The pair address to add liquidity to
     * @param _amount The amount of liquidity to calculate output
     * @param _intermediateToken Intermidate token that will be swapped out
     *
     * Returns estimation of amount of pair tokens that will be available when zapping in.
     */
    function quoteZapIn(address _inputToken, address _pairAddress, uint256 _amount, address _intermediateToken)
        public
        view
        returns (uint256)
    {
        // This function has 4 steps:
        // 1. Set intermediate token
        // 2. Calculate intermediate token amount: `_amount` if swap isn't required, otherwise calculate swap output from swapping `_inputToken` to `_intermediateToken`.
        // 3. Get amountA and amountB quote for swapping `_intermediateToken` to `_pairAddress` pair
        // 4. Get quote for liquidity

        uint256 intermediateAmt;
        address intermediateToken;
        (address _tokenA, address _tokenB) = _getPairTokens(_pairAddress);

        // 1. Set intermediate token
        if (_inputToken != _tokenA && _inputToken != _tokenB) {
            _validateIntermediateToken(_intermediateToken, _tokenA, _tokenB);

            // swap is required:
            // 2. Calculate intermediate token amount: `_amount` if swap isn't required, otherwise calculate swap output from swapping `_inputToken` to `_intermediateToken`.
            address[] memory path = _getSushiPath(_inputToken, _intermediateToken);
            intermediateAmt = sushiSwapRouter.getAmountsOut(_amount, path)[path.length - 1];
            intermediateToken = _intermediateToken;
        } else {
            intermediateToken = _inputToken;
            intermediateAmt = _amount;
        }

        // 3. Get amountA and amountB quote for swapping `_intermediateToken` to `_pairAddress` pair
        (uint256 tokenABought, uint256 tokenBBought) =
            _quoteSwapIntermediate(intermediateToken, _tokenA, _tokenB, intermediateAmt);

        // 4. Get quote for liquidity
        return _quoteLiquidity(_tokenA, _tokenB, tokenABought, tokenBBought);
    }

    /**
     * @notice Quotes zap out amount for removing liquidity `_pair`.
     * @param _pair The address of the pair to remove liquidity from.
     * @param _tokenOut The address of the output token to calculate zap out.
     * @param _amount Amount of liquidity to calculate zap out.
     *
     * Returns the estimation of amount of `_tokenOut` that will be available when zapping out.
     */
    function quoteZapOut(address _pair, address _tokenOut, uint256 _amount) public view returns (uint256) {
        (address tokenA, address tokenB) = _getPairTokens(_pair);

        // estimate amounts out from removing liquidity
        (uint256 amountA, uint256 amountB) = _quoteRemoveLiquidity(_pair, _amount);

        uint256 tokenOutAmount = 0;

        // Calculate swap amount from liquidity pair tokenA to token out.
        if (tokenA != _tokenOut) {
            tokenOutAmount += _calculateSwapOut(tokenA, _tokenOut, amountA);
        } else {
            tokenOutAmount += amountA;
        }

        // Calculate swap amount from liquidity pair tokenB to token out.
        if (tokenB != _tokenOut) {
            tokenOutAmount += _calculateSwapOut(tokenB, _tokenOut, amountB);
        } else {
            tokenOutAmount += amountB;
        }
        return tokenOutAmount;
    }

    /**
     * Validates `_intermediateToken` to ensure that it is not address 0 and is equal to one of the token pairs `_tokenA` or `_tokenB`.
     *
     * Note reverts if pair was not found.
     */
    function _validateIntermediateToken(address _intermediateToken, address _tokenA, address _tokenB) private pure {
        if (_intermediateToken == address(0) || (_intermediateToken != _tokenA && _intermediateToken != _tokenB)) {
            revert INVALID_INTERMEDIATE_TOKEN();
        }
    }

    /**
     * 1. Swaps `_fromToken` to `_intermediateToken` (if necessary)
     * 2. Swaps portion of `_intermediateToken` to the other token pair.
     * 3. Adds liquidity to pair on SushiSwap.
     */
    function _performZapIn(address _fromToken, address _pairAddress, uint256 _amount, address _intermediateToken)
        internal
        returns (uint256)
    {
        uint256 intermediateAmt;
        address intermediateToken;
        (address tokenA, address tokenB) = _getPairTokens(_pairAddress);

        if (_fromToken != tokenA && _fromToken != tokenB) {
            // swap to intermediate
            _validateIntermediateToken(_intermediateToken, tokenA, tokenB);
            intermediateAmt = _token2Token(_fromToken, _intermediateToken, _amount);
            intermediateToken = _intermediateToken;
        } else {
            intermediateToken = _fromToken;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 tokenABought, uint256 tokenBBought) =
            _swapIntermediate(intermediateToken, tokenA, tokenB, intermediateAmt);

        return _uniDeposit(tokenA, tokenB, tokenABought, tokenBBought);
    }

    /**
     * 1. Removes `_pair` liquidity from SushiSwap.
     * 2. Swaps liquidity pair tokens to `_tokenOut`.
     */
    function _performZapOut(address _pair, address _tokenOut, uint256 _amount) private returns (uint256) {
        (address tokenA, address tokenB) = _getPairTokens(_pair);
        (uint256 amountA, uint256 amountB) = _removeLiquidity(_pair, tokenA, tokenB, _amount);

        uint256 tokenOutAmount = 0;

        // Swaps token A from liq pair for output token
        if (tokenA != _tokenOut) {
            tokenOutAmount += _token2Token(tokenA, _tokenOut, amountA);
        } else {
            tokenOutAmount += amountA;
        }

        // Swaps token B from liq pair for output token
        if (tokenB != _tokenOut) {
            tokenOutAmount += _token2Token(tokenB, _tokenOut, amountB);
        } else {
            tokenOutAmount += amountB;
        }

        return tokenOutAmount;
    }

    /**
     * Returns the min of the two input numbers.
     */
    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    /**
     * Simulates adding liquidity to `_tokenA`/`_tokenB` pair on SushiSwap.
     *
     * Logic is derived from `_addLiquidity` (`UniswapV2Router02.sol`) and `mint` (`UniswapV2Pair.sol`)
     * to simulate addition of liquidity.
     */
    function _quoteLiquidity(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired)
        internal
        view
        returns (uint256)
    {
        uint256 amountA;
        uint256 amountB;
        IUniswapV2Pair pair = _getPair(_tokenA, _tokenB);
        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (_amountADesired, _amountBDesired);
        } else {
            uint256 amountBOptimal = sushiSwapRouter.quote(_amountADesired, reserveA, reserveB);
            if (amountBOptimal <= _amountBDesired) {
                (amountA, amountB) = (_amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = sushiSwapRouter.quote(_amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, _amountBDesired);
            }
        }

        return _min((amountA * pair.totalSupply()) / reserveA, (amountB * pair.totalSupply()) / reserveB);
    }

    /**
     * Simulates removing liquidity from `_pair` for `_amount` on SushiSwap.
     */
    function _quoteRemoveLiquidity(address _pair, uint256 _amount)
        private
        view
        returns (uint256 _amountA, uint256 _amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        address tokenA = pair.token0();
        address tokenB = pair.token1();
        uint256 balance0 = IERC20(tokenA).balanceOf(_pair);
        uint256 balance1 = IERC20(tokenB).balanceOf(_pair);

        uint256 _totalSupply = pair.totalSupply();
        _amountA = (_amount * balance0) / _totalSupply;
        _amountB = (_amount * balance1) / _totalSupply;
    }

    /**
     * Returns the addresses of Sushi pair tokens for the given `_pairAddress`.
     */
    function _getPairTokens(address _pairAddress) private view returns (address, address) {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        return (uniPair.token0(), uniPair.token1());
    }

    /**
     * Helper that returns the Sushi pair address for the given pair tokens `_tokenA` and `_tokenB`.
     */
    function _getPair(address _tokenA, address _tokenB) private view returns (IUniswapV2Pair) {
        IUniswapV2Pair pair = IUniswapV2Pair(sushiSwapFactoryAddress.getPair(_tokenA, _tokenB));
        if (address(pair) == address(0)) {
            revert NON_EXISTANCE_PAIR();
        }
        return pair;
    }

    /**
     * Removes liquidity from Sushi.
     */
    function _removeLiquidity(address _pair, address _tokenA, address _tokenB, uint256 _amount)
        private
        returns (uint256 amountA, uint256 amountB)
    {
        _approveToken(_pair, address(sushiSwapRouter), _amount);
        return sushiSwapRouter.removeLiquidity(_tokenA, _tokenB, _amount, 1, 1, address(this), deadline);
    }

    /**
     * Adds liquidity to Sushi.
     */
    function _uniDeposit(address _tokenA, address _tokenB, uint256 _amountADesired, uint256 _amountBDesired)
        private
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

    /**
     * Swaps `_inputToken` to pair tokens `_tokenPairA`/`_tokenPairB` for the `_amount`.
     * @return _amountA the amount of `_tokenPairA` bought.
     * @return _amountB the amount of `_tokenPairB` bought.
     */
    function _swapIntermediate(address _inputToken, address _tokenPairA, address _tokenPairB, uint256 _amount)
        internal
        returns (uint256 _amountA, uint256 _amountB)
    {
        IUniswapV2Pair pair = _getPair(_tokenPairA, _tokenPairB);
        (uint256 resA, uint256 resB,) = pair.getReserves();
        if (_inputToken == _tokenPairA) {
            uint256 amountToSwap = _calculateSwapInAmount(resA, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) {
                amountToSwap = _amount / 2;
            }
            _amountB = _token2Token(_inputToken, _tokenPairB, amountToSwap);
            _amountA = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = _calculateSwapInAmount(resB, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) {
                amountToSwap = _amount / 2;
            }
            _amountA = _token2Token(_inputToken, _tokenPairA, amountToSwap);
            _amountB = _amount - amountToSwap;
        }
    }

    /**
     * Simulates swap of `_inputToken` to pair tokens `_tokenPairA`/`_tokenPairB` for the `_amount`.
     * @return _amountA quote amount of `_tokenPairA`
     * @return _amountB quote amount of `_tokenPairB`
     */
    function _quoteSwapIntermediate(address _inputToken, address _tokenPairA, address _tokenPairB, uint256 _amount)
        internal
        view
        returns (uint256 _amountA, uint256 _amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(sushiSwapFactoryAddress.getPair(_tokenPairA, _tokenPairB));
        (uint256 resA, uint256 resB,) = pair.getReserves();

        if (_inputToken == _tokenPairA) {
            uint256 amountToSwap = _calculateSwapInAmount(resA, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) {
                amountToSwap = _amount / 2;
            }
            _amountB = _calculateSwapOut(_inputToken, _tokenPairB, amountToSwap);
            _amountA = _amount - amountToSwap;
        } else {
            uint256 amountToSwap = _calculateSwapInAmount(resB, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) {
                amountToSwap = _amount / 2;
            }
            _amountA = _calculateSwapOut(_inputToken, _tokenPairA, amountToSwap);
            _amountB = _amount - amountToSwap;
        }
    }

    /**
     * Calculates the amounts out from swapping `_tokenA` to `_tokenB` for the given `_amount`.
     */
    function _calculateSwapOut(address _tokenA, address _tokenB, uint256 _amount)
        private
        view
        returns (uint256 _amountOut)
    {
        address[] memory path = _getSushiPath(_tokenA, _tokenB);
        // `getAmountsOut` will return same size array as path, and we only care about the
        // last element which will give us the swap out amount we are looking for
        uint256[] memory amountsOut = sushiSwapRouter.getAmountsOut(_amount, path);
        return amountsOut[path.length - 1];
    }

    /**
     * Helper that reverts if `_addr` is zero.
     */
    function _checkZeroAddress(address _addr) private pure {
        if (_addr == address(0)) {
            revert ADDRESS_IS_ZERO();
        }
    }

    /**
     * Returns the appropriate swap path for Sushi swap.
     */
    function _getSushiPath(address _fromToken, address _toToken) internal pure returns (address[] memory) {
        address[] memory path;
        if (_fromToken == wethTokenAddress || _toToken == wethTokenAddress) {
            path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;
        } else {
            path = new address[](3);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            path[2] = _toToken;
        }
        return path;
    }

    /**
     * Computes the amount of intermediate tokens to swap for adding liquidity.
     */
    function _calculateSwapInAmount(uint256 _reserveIn, uint256 _userIn) internal pure returns (uint256) {
        return (Babylonian.sqrt(_reserveIn * ((_userIn * 3988000) + (_reserveIn * 3988009))) - (_reserveIn * 1997))
            / 1994;
    }

    /**
     * @notice This function is used to swap ERC20 <> ERC20
     * @param _source The token address to swap from.
     * @param _destination The token address to swap to.
     * @param _amount The amount of tokens to swap
     * @return _tokenBought The quantity of tokens bought
     */
    function _token2Token(address _source, address _destination, uint256 _amount)
        internal
        returns (uint256 _tokenBought)
    {
        if (_source == _destination) {
            return _amount;
        }

        _approveToken(_source, address(sushiSwapRouter), _amount);

        address[] memory path = _getSushiPath(_source, _destination);
        uint256[] memory amountsOut =
            sushiSwapRouter.swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
        _tokenBought = amountsOut[path.length - 1];

        if (_tokenBought == 0) {
            revert ERROR_SWAPPING_TOKENS();
        }
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
    error NON_EXISTANCE_PAIR();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    JonesLPStrategy,
    LPStrategyLib,
    IUniswapV2Pair,
    I1inchAggregationRouterV4,
    ISsovV3,
    SsovAdapter,
    IERC20,
    OneInchZapLib
} from "./JonesLPStrategy.sol";
import {IBullLPVault} from "../interfaces/ILPVault.sol";

contract JonesLPBullStrategy is JonesLPStrategy {
    using SsovAdapter for ISsovV3;

    /**
     * @param _name The name of the strategy
     * @param _oneInch The 1Inch router contract
     * @param _primarySsov The Ssov related to the primary token
     * @param _secondarySsov The Ssov related to the secondary token
     * @param _primaryToken The primary token on the LP pair
     * @param _secondaryToken The secondary token on the LP pair
     * @param _governor The owner of the contract
     * @param _manager The address allowed to configure the strat and run manual functions
     * @param _keeper The address of the bot that will run the strategy
     */
    constructor(
        bytes32 _name,
        I1inchAggregationRouterV4 _oneInch,
        ISsovV3 _primarySsov,
        ISsovV3 _secondarySsov,
        IERC20 _primaryToken,
        IERC20 _secondaryToken,
        address _governor,
        address _manager,
        address _keeper
    )
        JonesLPStrategy(
            _name,
            _oneInch,
            _primarySsov,
            _secondarySsov,
            _primaryToken,
            _secondaryToken,
            _governor,
            _manager,
            _keeper
        )
    {}

    /**
     * @notice Inits the strategy by borrowing and taking snapshots
     */
    function initStrategy(uint256[2] calldata _minTokenOutputs) external onlyRole(KEEPER) {
        if (initialTime != 0) {
            revert StrategyAlreadyInitialized();
        }

        _borrow(_minTokenOutputs);

        _afterInit(primary.balanceOf(address(this)), secondary.balanceOf(address(this)));
    }

    /**
     * @notice Executes the configured strategy
     * @param _input Struct that includes:
     * _useForPrimary % of collateral to use to buy  primary options
     * _useForSecondary % of collateral to use to buy secondary options
     * _primaryStrikesOrder The expected order of primary strikes
     * _secondaryStrikesOrder The expected order of secondary strikes
     */
    function execute(StageExecutionInputs memory _input, OneInchZapLib.SwapParams memory _swapParams)
        external
        onlyRole(KEEPER)
    {
        if (initialTime == 0) {
            revert StrategyNotInitialized();
        }

        _notExpired();

        Stage[4] memory currentStages = stages;
        Stage memory currentStage;
        uint256 currentStageIndex;

        // Select the current stage
        for (uint256 i; i < currentStages.length; i++) {
            currentStage = currentStages[i];
            currentStageIndex = i;

            if (block.timestamp > initialTime + currentStage.duration) {
                // Stage already expired
                continue;
            }

            break;
        }

        if (_input.expectedStageIndex != currentStageIndex) {
            revert ExecutingUnexpectedStage(_input.expectedStageIndex, currentStageIndex);
        }

        IERC20 _primary = primary;
        IERC20 _secondary = secondary;

        if (_swapParams.desc.srcToken != address(_secondary) || _swapParams.desc.dstToken != address(_primary)) {
            revert InvalidSwap();
        }

        if (_swapParams.desc.dstReceiver != address(this)) {
            revert InvalidSwapReceiver();
        }

        uint256[2] memory balances = [primaryBalanceSnapshot, secondaryBalanceSnapshot];

        if (balances[1] > 0) {
            // Buy `secondary` calls and get the new bought percentages
            (, currentStage.usedForSecondary) = LPStrategyLib.buyOptions(
                LPStrategyLib.BuyOptionsInput(
                    secondarySsov,
                    secondarySsovEpoch,
                    secondarySsovEpochExpiry,
                    balances[1],
                    _input.useForSecondary,
                    currentStage.limitsForSecondary,
                    currentStage.usedForSecondary,
                    _input.secondaryStrikesOrder,
                    _input.ignoreITM
                )
            );
        }

        if (balances[0] > 0 || balances[1] > 0) {
            // Swap `secondary` for `primary` and buy `primary` calls
            (, currentStage.usedForSwaps, currentStage.usedForPrimary) = LPStrategyLib.swapAndBuyOptions(
                LPStrategyLib.SwapAndBuyOptionsInput(
                    primarySsov,
                    _secondary,
                    primarySsovEpoch,
                    primarySsovEpochExpiry,
                    balances[0],
                    balances[1],
                    _input.useForPrimary,
                    (_swapParams.desc.amount * basePercentage) / balances[1],
                    _swapParams,
                    currentStage.limitsForPrimary,
                    currentStage.usedForPrimary,
                    _input.primaryStrikesOrder,
                    currentStage.limitForSwaps,
                    currentStage.usedForSwaps,
                    _input.ignoreITM
                )
            );
        }

        _afterExecution(currentStageIndex, currentStage);
    }

    function settle(
        uint256 _minPairTokens,
        address[] calldata _inTokens,
        OneInchZapLib.SwapParams[] calldata _swapParams
    ) external onlyRole(KEEPER) {
        if (block.timestamp < primarySsovEpochExpiry || block.timestamp < secondarySsovEpochExpiry) {
            revert SettleBeforeExpiry();
        }

        primarySsov.settleAllStrikesOnEpoch(primarySsovEpoch);
        secondarySsov.settleAllStrikesOnEpoch(secondarySsovEpoch);

        uint256[] memory inTokenAmounts = new uint256[](_inTokens.length);

        for (uint256 i; i < _inTokens.length; i++) {
            inTokenAmounts[i] = IERC20(_inTokens[i]).balanceOf(address(this));
        }

        _repay(_minPairTokens, _inTokens, inTokenAmounts, _swapParams);

        _afterSettlement();
    }

    function borrow(uint256[2] calldata _minTokenOutputs) external onlyRole(MANAGER) {
        _borrow(_minTokenOutputs);
    }

    function repay(
        uint256 _minPairTokens,
        address[] calldata _inTokens,
        uint256[] calldata _inTokenAmounts,
        OneInchZapLib.SwapParams[] calldata _swapParams
    ) external onlyRole(MANAGER) {
        _repay(_minPairTokens, _inTokens, _inTokenAmounts, _swapParams);
    }

    function _borrow(uint256[2] calldata _minTokenOutputs) private {
        IBullLPVault lpVault = IBullLPVault(vault);
        if (!lpVault.borrowed()) {
            uint256 borrowed = lpVault.borrow(_minTokenOutputs);

            initialBalanceSnapshot = borrowed;
        }
    }

    function _repay(
        uint256 _minPairTokens,
        address[] memory _inTokens,
        uint256[] memory _inTokenAmounts,
        OneInchZapLib.SwapParams[] calldata _swapParams
    ) private {
        IBullLPVault lpVault = IBullLPVault(vault);

        for (uint256 i; i < _inTokens.length; i++) {
            IERC20(_inTokens[i]).approve(address(lpVault), _inTokenAmounts[i]);
        }

        lpVault.repay(_minPairTokens, _inTokens, _inTokenAmounts, _swapParams);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ILPVault} from "../interfaces/ILPVault.sol";
import {SsovAdapter} from "../adapters/SsovAdapter.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {I1inchAggregationRouterV4} from "../interfaces/I1inchAggregationRouterV4.sol";
import {ISsovV3} from "../interfaces/ISsovV3.sol";
import {LPStrategyLib} from "../libraries/LPStrategyLib.sol";
import {OneInchZapLib} from "../libraries/OneInchZapLib.sol";
import {ZapLib} from "../libraries/ZapLib.sol";

abstract contract JonesLPStrategy is AccessControl {
    using SsovAdapter for ISsovV3;
    using OneInchZapLib for I1inchAggregationRouterV4;

    // Represents 100%
    // We are going to store the value that we have on the LP lib
    // to make the bot logic easier
    uint256 public immutable basePercentage;
    // Roles

    // Role used to execute the strategy
    bytes32 public constant KEEPER = bytes32("KEEPER");
    // Role used to configure the strategy
    // and execute manual functions
    bytes32 public constant MANAGER = bytes32("MANAGER");
    // Role used to manage keepers and managers
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    // Struct used to configure the strategy limits and timeframes
    struct StageConfigInput {
        // The % limits of how much collateral can be used to buy primary options
        uint256[] limitsForPrimary;
        // The % limits of how much collateral can be used to buy secondary options
        uint256[] limitsForSecondary;
        // The max % of tokens that can be swapped
        uint256 limitForSwaps;
        // The duration of the stage in seconds. Relative to `initialTime`
        uint256 duration;
    }

    // Struct used to keep track of stages executions
    struct Stage {
        // The % limits of how much collateral can be used to buy primary options
        uint256[] limitsForPrimary;
        // The % of collateral used to buy primary options
        uint256[] usedForPrimary;
        // The % limits of how much collateral can be used to buy secondary options
        uint256[] limitsForSecondary;
        // The % of collateral used to buy secondary options
        uint256[] usedForSecondary;
        // The max % of tokens that can be swapped
        uint256 limitForSwaps;
        // The % of tokens used for swaps
        uint256 usedForSwaps;
        // The duration of the stage in seconds. Relative to `initialTime`
        uint256 duration;
    }

    // To prevent Stack too deep error
    struct StageExecutionInputs {
        // The index of the stage that should be executed
        uint256 expectedStageIndex;
        // The % of primary that can be used to buy options. Each entry represents a strike sorted
        // by "closest-to-itm"
        uint256[] useForPrimary;
        // The % of secondary that can be used to buy options. Each entry represents a strike sorted
        // by "closest-to-itm"
        uint256[] useForSecondary;
        // The expected order of primary strikes sorted by "closest-to-itm"
        uint256[] primaryStrikesOrder;
        // The expected order of secondary strikes sorted by "closest-to-itm"
        uint256[] secondaryStrikesOrder;
        // Whether to include or exclude strikes that are ITM at the moment of execution
        bool ignoreITM;
    }

    // When the strategy starts
    uint256 public initialTime;
    // The initial LP balance borrowed from the vault
    uint256 public initialBalanceSnapshot;
    // Holds a snapshot of the initial collateral that can be used by the primary token
    uint256 public primaryBalanceSnapshot;
    // Holds a snapshot of the initial collateral that can be used by the secondary token
    uint256 public secondaryBalanceSnapshot;

    // The vault that holds LP tokens
    address public vault;

    // The LP token borrowed from the vault
    IERC20 public depositToken;

    // The primary token on the LP
    IERC20 public primary;
    // The secondary token on the LP (will be swapped for primary)
    IERC20 public secondary;

    // The 4 stages
    Stage[4] public stages;

    // The primary Ssov (related to primary token)
    ISsovV3 public primarySsov;
    // The primary Ssov (related to secondary token)
    ISsovV3 public secondarySsov;

    // The primary Ssov epoch
    uint256 public primarySsovEpoch;
    // When the primary Ssov epoch expires
    uint256 public primarySsovEpochExpiry;
    // The secondary Ssov epoch
    uint256 public secondarySsovEpoch;
    // When the secondary Ssov epoch expires
    uint256 public secondarySsovEpochExpiry;

    // One inch router
    I1inchAggregationRouterV4 public oneInch;

    // Pair key  => `true` if the token can be swapped
    mapping(bytes32 => bool) public allowedToSwap;

    // Token address => `true` if the token can be zapped
    mapping(address => bool) public allowedToZap;

    // The name of the strategy
    bytes32 public name;

    bytes32 private _lastPrimarySsovCursor;
    bytes32 private _lastSecondarySsovCursor;

    /**
     * @param _name The name of the strategy
     * @param _oneInch The 1Inch contract address
     * @param _primarySsov The Ssov related to the primary token
     * @param _secondarySsov The Ssov related to the secondary token
     * @param _primaryToken The primary token on the LP pair
     * @param _secondaryToken The secondary token on the LP pair
     * @param _governor The owner of the contract
     * @param _manager The address allowed to configure the strat and run manual functions
     * @param _keeper The address of the bot that will run the strategy
     */
    constructor(
        bytes32 _name,
        I1inchAggregationRouterV4 _oneInch,
        ISsovV3 _primarySsov,
        ISsovV3 _secondarySsov,
        IERC20 _primaryToken,
        IERC20 _secondaryToken,
        address _governor,
        address _manager,
        address _keeper
    ) {
        _isValidAddress(address(_oneInch));
        _isValidAddress(address(_primarySsov));
        _isValidAddress(address(_secondarySsov));
        _isValidAddress(address(_primaryToken));
        _isValidAddress(address(_secondaryToken));
        _isValidAddress(_governor);
        _isValidAddress(_manager);
        _isValidAddress(_keeper);

        name = _name;
        oneInch = _oneInch;

        // 100%
        basePercentage = LPStrategyLib.basePercentage;

        primarySsov = _primarySsov;
        secondarySsov = _secondarySsov;

        address primaryToken = address(_primaryToken);
        address secondaryToken = address(_secondaryToken);

        _setWhitelistPair(primaryToken, secondaryToken, true);

        allowedToZap[primaryToken] = true;
        allowedToZap[secondaryToken] = true;

        primary = _primaryToken;
        secondary = _secondaryToken;

        primarySsovEpochExpiry = type(uint256).max;
        secondarySsovEpochExpiry = type(uint256).max;

        // Access control
        _grantRole(GOVERNOR, _governor);
        _grantRole(MANAGER, _manager);
        _grantRole(KEEPER, _keeper);
    }

    /**
     * @notice Returns the current stages
     */
    function getStages() external view returns (Stage[4] memory) {
        return stages;
    }

    /**
     * @notice Returns the current stage at index `_index`
     * @param _index The index of the stage
     */
    function getStage(uint256 _index) external view returns (Stage memory) {
        return stages[_index];
    }

    /**
     * @notice Returns the timestamps for each stage expiration
     */
    function getStageExpirations() external view returns (uint256[4] memory) {
        uint256[4] memory expirations;

        Stage[4] memory currentStages = stages;
        uint256 referenceTime = initialTime;

        for (uint256 i; i < currentStages.length; i++) {
            expirations[i] = referenceTime + currentStages[i].duration;
        }

        return expirations;
    }

    /**
     * @notice Returns the strikes from the primary ssov sorted by the distance to be in the money
     */
    function getSortedPrimaryStrikes() public view returns (LPStrategyLib.StrikePerformance[] memory) {
        return LPStrategyLib.getSortedStrikes(primarySsov, primarySsovEpoch);
    }

    /**
     * @notice Returns the strikes from the secondary ssov sorted by the distance to be in the money
     */
    function getSortedSecondaryStrikes() public view returns (LPStrategyLib.StrikePerformance[] memory) {
        return LPStrategyLib.getSortedStrikes(secondarySsov, secondarySsovEpoch);
    }

    /**
     * @notice Returns the pair key generated by `_token0` and `_token1`
     * @param _token0 The address of the first token
     * @param _token1 The address of the second token
     */
    function getPairKey(address _token0, address _token1) public pure returns (bytes32) {
        // Create a pair key using the xor between the two token addresses
        return bytes32(uint256(bytes32(bytes20(_token0))) ^ uint256(bytes32(bytes20(_token1))));
    }

    /**
     * @notice Configures all the execution stages
     * @dev It overrides the current configuration
     * @param _stagesConfig The limits and timeframes for all stages
     */
    function configureMultipleStages(StageConfigInput[4] memory _stagesConfig) external returns (Stage[] memory) {
        Stage[] memory configuredStages = new Stage[](4);

        for (uint256 i; i < _stagesConfig.length; i++) {
            configuredStages[i] = configureSingleStage(_stagesConfig[i], i);
        }

        return configuredStages;
    }

    /**
     * @notice Configures a single stage
     * @dev It overrides the current configuration
     * @param _stageConfig The limits and timeframes for the stage at `_index`
     * @param _index The index of the stage to configure
     */
    function configureSingleStage(StageConfigInput memory _stageConfig, uint256 _index)
        public
        onlyRole(MANAGER)
        returns (Stage memory)
    {
        Stage memory stage = stages[_index];

        // Update the configurable variables of the stage
        // to avoid overriding `usedForPrimary ` and `usedForSecondary`
        stage.limitsForPrimary = _stageConfig.limitsForPrimary;
        stage.limitsForSecondary = _stageConfig.limitsForSecondary;
        stage.limitForSwaps = _stageConfig.limitForSwaps;
        stage.duration = _stageConfig.duration;

        // Update the storage with the new configuration
        stages[_index] = stage;

        emit StageConfigured(
            _index, _stageConfig.limitsForPrimary, _stageConfig.limitsForSecondary, _stageConfig.duration
            );

        return stage;
    }

    /**
     * @notice zaps out `_amount` of `depositToken` to an allowed token
     */
    function zapOut(
        uint256 _amount,
        uint256 _token0PairAmount,
        uint256 _token1PairAmount,
        OneInchZapLib.SwapParams calldata _tokenSwap
    ) external onlyRole(MANAGER) returns (uint256) {
        _canBeZapped(_tokenSwap.desc.srcToken);
        _canBeZapped(_tokenSwap.desc.dstToken);

        if (_tokenSwap.desc.dstReceiver != address(this)) {
            revert InvalidSwapReceiver();
        }

        uint256 amountOut = oneInch.zapOutToOneTokenFromPair(
            address(depositToken), _amount, _token0PairAmount, _token1PairAmount, _tokenSwap
        );

        emit ManualZap(msg.sender, ZapLib.ZapType.ZAP_OUT, _tokenSwap.desc.dstToken, _amount, amountOut);

        return amountOut;
    }

    /**
     * @notice zaps in `_amount` of allowed tokens to `depositToken`
     */
    function zapIn(
        OneInchZapLib.SwapParams calldata _toPairTokens,
        uint256 _token0Amount,
        uint256 _token1Amount,
        uint256 _minPairTokens
    ) external onlyRole(MANAGER) returns (uint256) {
        _canBeZapped(_toPairTokens.desc.srcToken);
        _canBeZapped(_toPairTokens.desc.dstToken);

        if (_toPairTokens.desc.dstReceiver != address(this)) {
            revert InvalidSwapReceiver();
        }

        uint256 amountOut =
            oneInch.zapIn(_toPairTokens, address(depositToken), _token0Amount, _token1Amount, _minPairTokens);

        emit ManualZap(
            msg.sender, ZapLib.ZapType.ZAP_IN, _toPairTokens.desc.srcToken, _toPairTokens.desc.amount, amountOut
            );

        return amountOut;
    }

    /**
     * @notice Swaps allowed tokens using 1Inch
     */
    function swap(OneInchZapLib.SwapParams calldata _swapParams) external onlyRole(MANAGER) returns (uint256) {
        _canBeSwapped(_swapParams.desc.srcToken, _swapParams.desc.dstToken);

        if (_swapParams.desc.dstReceiver != address(this)) {
            revert InvalidSwapReceiver();
        }

        IERC20(_swapParams.desc.srcToken).approve(address(oneInch), _swapParams.desc.amount);
        (uint256 output,) = oneInch.swap(_swapParams.caller, _swapParams.desc, _swapParams.data);

        emit ManualSwap(
            msg.sender, _swapParams.desc.srcToken, _swapParams.desc.dstToken, _swapParams.desc.amount, output
            );

        return output;
    }

    /**
     * @notice Purchases `_amount` of `_ssov` options on `_strikeIndex` strike
     * @param _ssov The Ssov where the options are going to be purchased
     * @param _strikeIndex The index of the strike to buy
     * @param _amount The amount of options to purchase
     */
    function purchaseOption(ISsovV3 _ssov, uint256 _strikeIndex, uint256 _amount) public onlyRole(MANAGER) {
        if (_ssov != primarySsov && _ssov != secondarySsov) {
            revert SsovNotSupported();
        }

        IERC20 token = _ssov.collateralToken();

        token.approve(address(_ssov), type(uint256).max);

        _ssov.purchaseOption(_strikeIndex, _amount, address(this));

        token.approve(address(_ssov), 0);

        emit ManualOptionPurchase(msg.sender, address(_ssov), _strikeIndex, _amount);
    }

    /**
     * @notice Settles `_ssovEpoch` on `_ssov` using `_ssovStrikes`
     * @param _ssov The Ssov to settle
     * @param _ssovEpoch The epoch to settle
     * @param _ssovStrikes The strikes to settle
     */
    function settleEpoch(ISsovV3 _ssov, uint256 _ssovEpoch, uint256[] memory _ssovStrikes) public onlyRole(MANAGER) {
        if (_ssov != primarySsov && _ssov != secondarySsov) {
            revert SsovNotSupported();
        }

        _ssov.settleEpoch(address(this), _ssovEpoch, _ssovStrikes);

        emit ManualEpochSettlement(msg.sender, address(_ssov), _ssovEpoch, _ssovStrikes);
    }

    /**
     * @notice Grants the `GOVERNOR` role to `_newGovernor` while it revokes it from the caller
     * @param _newGovernor The address that will be granted with the `GOVERNOR` role
     */
    function transferOwnership(address _newGovernor) external onlyRole(GOVERNOR) {
        _isValidAddress(_newGovernor);

        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit OwnershipTrasnferred(msg.sender, _newGovernor);
    }

    /**
     * @notice Grants the `MANAGER` role to `_newManager`
     * @param _newManager The address that will be granted with the `MANAGER` role
     */
    function addManager(address _newManager) external onlyRole(GOVERNOR) {
        _isValidAddress(_newManager);

        _grantRole(MANAGER, _newManager);

        emit ManagerAdded(msg.sender, _newManager);
    }

    /**
     * @notice Revokes the `MANAGER` role from `_manager`
     * @param _manager The address that will be revoked
     */
    function removeManager(address _manager) external onlyRole(GOVERNOR) {
        _revokeRole(MANAGER, _manager);

        emit ManagerRemoved(msg.sender, _manager);
    }

    /**
     * @notice Grants the `KEEPER` role to `_newKeeper`
     * @param _newKeeper The address that will be granted with the `KEEPER` role
     */
    function addKeeper(address _newKeeper) external onlyRole(GOVERNOR) {
        _isValidAddress(_newKeeper);

        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(msg.sender, _newKeeper);
    }

    /**
     * @notice Revokes the `KEEPER` role from `_keeper`
     * @param _keeper The address that will be revoked
     */
    function removeKeeper(address _keeper) external onlyRole(GOVERNOR) {
        _revokeRole(KEEPER, _keeper);

        emit KeeperRemoved(msg.sender, _keeper);
    }

    /**
     * @notice Enables the swap between `_token0` and `_token1`
     * @dev This will also enables the swap between `_token1` and `_token0`
     * @param _token0 The address of the first asset
     * @param _token1 The address of the second asset
     */
    function enablePairSwap(address _token0, address _token1) external onlyRole(GOVERNOR) returns (bytes32) {
        bytes32 key = _setWhitelistPair(_token0, _token1, true);

        emit PairSwapEnabled(msg.sender, _token0, _token1, key);

        return key;
    }

    /**
     * @notice Disables the swap between `_token0` and `_token1`
     * @dev This will also disable the swap between `_token1` and `_token0`
     * @param _token0 The address of the first asset
     * @param _token1 The address of the second asset
     */
    function disablePairSwap(address _token0, address _token1) external onlyRole(GOVERNOR) returns (bytes32) {
        bytes32 key = _setWhitelistPair(_token0, _token1, false);

        emit PairSwapDisabled(msg.sender, _token0, _token1, key);

        return key;
    }

    /**
     * @notice Allows to zap `_token` for `depositToken`
     * @param _token The address of the asset
     */
    function enableTokenZap(address _token) external onlyRole(GOVERNOR) {
        allowedToZap[_token] = true;

        emit ZapEnabled(msg.sender, _token);
    }

    /**
     * @notice Disables zapping `_token` for `depositToken`
     * @param _token The address of the asset
     */
    function disableTokenZap(address _token) external onlyRole(GOVERNOR) {
        allowedToZap[_token] = false;

        emit ZapDisabled(msg.sender, _token);
    }

    /**
     * @notice Sets the vault and deposit token address
     * @param _newVault the address of the vault
     */
    function setVault(address _newVault) external onlyRole(GOVERNOR) {
        _isValidAddress(_newVault);

        vault = _newVault;
        depositToken = ILPVault(_newVault).depositToken();
    }

    /**
     * @notice Sets the address for the primary ssov
     * @param _primarySsov the new ssov address
     */
    function setPrimarySsov(address _primarySsov) external onlyRole(GOVERNOR) {
        _isValidAddress(_primarySsov);

        primarySsov = ISsovV3(_primarySsov);
    }

    /**
     * @notice Sets the address for the secondary ssov
     * @param _secondarySsov the new ssov address
     */
    function setSecondarySsov(address _secondarySsov) external onlyRole(GOVERNOR) {
        _isValidAddress(_secondarySsov);

        secondarySsov = ISsovV3(_secondarySsov);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative)
        external
        onlyRole(GOVERNOR)
    {
        _isValidAddress(_to);

        for (uint256 i; i < _assets.length; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            // No need to transfer
            if (assetBalance == 0) {
                continue;
            }

            // Transfer the ERC20 tokens
            asset.transfer(_to, assetBalance);
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            payable(_to).transfer(nativeBalance);
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /**
     * @notice To enable/disable swaps between `_token0` and `_token1`
     * @param _token0 The address of the first asset
     * @param _token1 The address of the second asset
     * @param _enable `true` to enable swaps, `false` to disable
     */
    function _setWhitelistPair(address _token0, address _token1, bool _enable) internal returns (bytes32) {
        bytes32 key = getPairKey(_token0, _token1);

        allowedToSwap[key] = _enable;

        return key;
    }

    /**
     * @notice Reverts if `_input` cannot be swapped to `_output`
     * @param _input The input token
     * @param _output The output token
     */
    function _canBeSwapped(address _input, address _output) internal view {
        bytes32 key = getPairKey(_input, _output);

        // 0 means that _input = _ouput
        if (key == bytes32(0)) {
            revert InvalidSwap();
        }

        if (!allowedToSwap[key]) {
            revert SwapIsNotAllowed();
        }
    }

    /**
     * @notice Reverts if `_input` cannot be zapped
     * @param _input The input token
     */
    function _canBeZapped(address _input) internal view {
        if (!allowedToZap[_input]) {
            revert ZapIsNotAllowed();
        }
    }

    /**
     * @notice Reverts if `_addr` is `address(0)`
     */
    function _isValidAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert InvalidAddress();
        }
    }

    /**
     * @notice Reverts if the strategy already expired according to the configured stages
     */
    function _notExpired() internal view {
        uint256 expiration = initialTime + stages[3].duration;

        if (block.timestamp > expiration) {
            revert StrategyAlreadyExpired();
        }
    }

    /**
     * @notice Executed after the strategy is settled
     */
    function _afterSettlement() internal virtual {
        emit Settlement(initialBalanceSnapshot);

        // Reset the state
        initialTime = 0;
        initialBalanceSnapshot = 0;
        primaryBalanceSnapshot = 0;
        secondaryBalanceSnapshot = 0;
        primarySsovEpoch = 0;
        secondarySsovEpoch = 0;
        primarySsovEpochExpiry = type(uint256).max;
        secondarySsovEpochExpiry = type(uint256).max;

        Stage[4] storage currentStages = stages;

        // Reset stages state but keep configuration
        for (uint256 i; i < currentStages.length; i++) {
            delete stages[i].usedForPrimary;
            delete stages[i].usedForSecondary;
            stages[i].usedForSwaps = 0;
        }
    }

    /**
     * @notice Takes a snapshot of the initial time and Ssov data
     */
    function _afterInit(uint256 _primaryBalanceSnapshot, uint256 _secondaryBalanceSnapshot) internal {
        // Set the initial time used as reference for stage expiration
        initialTime = block.timestamp;

        ISsovV3 ssov = primarySsov;
        uint256 ssovEpoch = ssov.currentEpoch();

        // Snapshot ssov epochs and expirations
        primarySsovEpoch = ssovEpoch;

        if (keccak256(abi.encodePacked(address(ssov), ssovEpoch)) == _lastPrimarySsovCursor) {
            revert InitOnSameSsovEpoch();
        }

        ISsovV3.EpochData memory primaryEpochData = ssov.getEpochData(ssovEpoch);
        primarySsovEpochExpiry = primaryEpochData.expiry;
        uint256[] memory primaryStrikes = primaryEpochData.strikes;
        _lastPrimarySsovCursor = keccak256(abi.encodePacked(address(ssov), ssovEpoch));

        ssov = secondarySsov;
        ssovEpoch = ssov.currentEpoch();

        if (keccak256(abi.encodePacked(address(ssov), ssovEpoch)) == _lastSecondarySsovCursor) {
            revert InitOnSameSsovEpoch();
        }

        secondarySsovEpoch = ssovEpoch;
        ISsovV3.EpochData memory secondaryEpochData = ssov.getEpochData(ssovEpoch);
        secondarySsovEpochExpiry = secondaryEpochData.expiry;
        uint256[] memory secondaryStrikes = secondaryEpochData.strikes;
        _lastSecondarySsovCursor = keccak256(abi.encodePacked(address(ssov), ssovEpoch));

        for (uint256 i; i < stages.length; i++) {
            stages[i].usedForSecondary = new uint256[](secondaryStrikes.length);
            stages[i].usedForPrimary = new uint256[](primaryStrikes.length);
        }

        primaryBalanceSnapshot = _primaryBalanceSnapshot;
        secondaryBalanceSnapshot = _secondaryBalanceSnapshot;
    }

    /**
     * @notice Executed after a stage execution
     * @param _stageIndex The stage that was executed
     */
    function _afterExecution(uint256 _stageIndex, Stage memory _stage) internal {
        // Snapshot the % of `secondary` options bought
        // And the % of assets swapped to buy `primary` options
        stages[_stageIndex].usedForSecondary = _stage.usedForSecondary;
        stages[_stageIndex].usedForPrimary = _stage.usedForPrimary;
        stages[_stageIndex].usedForSwaps = _stage.usedForSwaps;

        emit Execution(_stageIndex, _stage.usedForSecondary, _stage.usedForPrimary);
    }

    event Settlement(uint256 initialBalance);
    event Execution(uint256 indexed stage, uint256[] usedForSecondary, uint256[] usedForPrimary);
    event StageConfigured(
        uint256 indexed stage, uint256[] limitsForPrimary, uint256[] limitsForSecondary, uint256 duration
    );

    event ManualBorrow(address indexed caller, uint256 borrowed);
    event ManualRepay(address indexed caller, uint256 repaid);
    event ManualZap(
        address indexed caller, ZapLib.ZapType indexed zapType, address indexed input, uint256 amount, uint256 amountOut
    );
    event ManualSwap(
        address indexed caller, address indexed input, address indexed output, uint256 amount, uint256 amountOut
    );
    event ManualOptionPurchase(
        address indexed caller, address indexed ssov, uint256 indexed strikeIndex, uint256 amount
    );
    event ManualEpochSettlement(address indexed caller, address indexed ssov, uint256 indexed epoch, uint256[] strikes);

    event OwnershipTrasnferred(address indexed oldGovernor, address indexed newGovernor);
    event ManagerAdded(address indexed caller, address indexed newManager);
    event ManagerRemoved(address indexed caller, address indexed removedManager);
    event KeeperAdded(address indexed caller, address indexed newKeeper);
    event KeeperRemoved(address indexed caller, address indexed removedKeeper);
    event PairSwapEnabled(address indexed calller, address indexed token0, address indexed token1, bytes32 pairKey);
    event ZapEnabled(address indexed caller, address indexed token);
    event ZapDisabled(address indexed caller, address indexed token);
    event PairSwapDisabled(address indexed caller, address indexed token0, address indexed token1, bytes32 pairKey);
    event EmergencyWithdrawal(
        address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalance
    );

    error StrategyAlreadyInitialized();
    error StrategyNotInitialized();
    error AboveSwapLimit();
    error SettleBeforeExpiry();
    error SwapIsNotAllowed();
    error InvalidSwap();
    error ZapIsNotAllowed();
    error SsovNotSupported();
    error InvalidAddress();
    error StrategyAlreadyExpired();
    error ExecutingUnexpectedStage(uint256 expected, uint256 actual);
    error InvalidSwapReceiver();
    error InitOnSameSsovEpoch();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {JonesLPBullStrategy, I1inchAggregationRouterV4, ISsovV3, IERC20} from "../JonesLPBullStrategy.sol";

contract JonesRdpxEthBullStrategy is JonesLPBullStrategy {
    constructor(
        address _oneInchRouter,
        address _ethSsovV3,
        address _rdpxSsovV3,
        address _weth,
        address _rdpx,
        address _owner,
        address _manager,
        address _keeperBot
    )
        JonesLPBullStrategy(
            "JonesRdpxEthBullStrategy",
            I1inchAggregationRouterV4(payable(_oneInchRouter)), // 1Inch router
            ISsovV3(_ethSsovV3), // Primary weekly Ssov ETH
            ISsovV3(_rdpxSsovV3), // Primary weekly Ssov RDPX
            IERC20(_weth), // WETH
            IERC20(_rdpx), // RDPX
            _owner, // Governor: Jones Multisig
            _manager, // Strats: Jones Multisig
            _keeperBot // Bot
        )
    {}
}