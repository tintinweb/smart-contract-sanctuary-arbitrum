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
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      */

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
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      */

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

abstract contract Governable is AccessControl {
    bytes32 public constant GOVERNOR = bytes32("GOVERNOR");

    constructor(address _governor) {
        _grantRole(GOVERNOR, _governor);
    }

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function updateGovernor(address _newGovernor) external onlyGovernor {
        _revokeRole(GOVERNOR, msg.sender);
        _grantRole(GOVERNOR, _newGovernor);

        emit GovernorUpdated(msg.sender, _newGovernor);
    }

    function _onlyGovernor() private view {
        if (!hasRole(GOVERNOR, msg.sender)) {
            revert CallerIsNotGovernor();
        }
    }

    event GovernorUpdated(address _oldGovernor, address _newGovernor);

    error CallerIsNotGovernor();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IIncentiveReceiver} from "../interfaces/IIncentiveReceiver.sol";
import {OneInchZapLib} from "src/libraries/OneInchZapLib.sol";
import {I1inchAggregationRouterV4} from "src/interfaces/I1inchAggregationRouterV4.sol";
import {Keepable, Governable} from "./Keepable.sol";

contract IncentiveReceiver is IIncentiveReceiver, Keepable {
    using OneInchZapLib for I1inchAggregationRouterV4;

    I1inchAggregationRouterV4 internal router;

    // Registry of allowed depositors
    mapping(address => bool) public depositors;

    // Registry of allowed tokens
    mapping(address => bool) public destinationTokens;

    /**
     * @param _governor The address of the owner of this contract
     */
    constructor(address _governor, address payable _router) Governable(_governor) {
        router = I1inchAggregationRouterV4(_router);
    }

    /**
     * @notice To enforce only allowed depositors to deposit funds
     */
    modifier onlyDepositors() {
        if (!depositors[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    /**
     * @notice Used by depositors to deposit incentives
     * @param _token the address of the asset to be deposited
     * @param _amount the amount of `_token` to deposit
     */
    function deposit(address _token, uint256 _amount) external onlyDepositors {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _token, _amount);
    }

    /**
     * @notice Used to register new depositors
     * @param _depositor the address of the new depositor
     */
    function addDepositor(address _depositor) external onlyGovernor {
        _isValidAddress(_depositor);

        depositors[_depositor] = true;

        emit DepositorAdded(msg.sender, _depositor);
    }

    function addToken(address _token) external onlyGovernor {
        _isValidAddress(_token);

        destinationTokens[_token] = true;

        emit TokenAdded(msg.sender, _token);
    }

    /**
     * @notice Used to remove depositors
     * @param _depositor the address of the depositor to remove
     */
    function removeDepositor(address _depositor) external onlyGovernor {
        depositors[_depositor] = false;

        emit DepositorRemoved(msg.sender, _depositor);
    }

    function removeToken(address _token) external onlyGovernor {
        destinationTokens[_token] = false;

        emit TokenRemoved(msg.sender, _token);
    }

    function updateRouter(address payable _router) external onlyGovernor {
        _isValidAddress(_router);

        address oldRouter = address(router);

        router = I1inchAggregationRouterV4(_router);

        emit UpdateRouter(oldRouter, _router);
    }

    function swap(OneInchZapLib.SwapParams calldata _swapParams) external onlyKeeper {
        _isWhitelisted(_swapParams.desc.dstToken);

        OneInchZapLib.SwapParams memory swap = _swapParams;
        if (swap.desc.dstReceiver != address(this)) {
            revert InvalidReceiver();
        }

        router.perform1InchSwap(swap);
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function withdraw(address _to, address[] memory _assets, bool _withdrawNative) external onlyGovernor {
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

        emit Withdrawal(msg.sender, _to, _assets, _withdrawNative);
    }

    function _isValidAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
    }

    function _isWhitelisted(address _token) internal view {
        if (!destinationTokens[_token]) {
            revert NotWhitelisted();
        }
    }

    /**
     * @notice Emitted when a depositor deposits incentives
     * @param depositor the contract that deposited
     * @param token the address of the asset that was deposited
     * @param amount the amount of `token` that was deposited
     */
    event Deposit(address indexed depositor, address indexed token, uint256 amount);

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorAdded(address indexed owner, address indexed depositor);
    event TokenAdded(address indexed owner, address indexed token);
    event UpdateRouter(address indexed oldAddress, address indexed newAddress);

    /**
     * @notice Emitted when a new depositor is registered
     * @param owner the current owner of this contract
     * @param depositor the address of the new depositor
     */
    event DepositorRemoved(address indexed owner, address indexed depositor);
    event TokenRemoved(address indexed owner, address indexed depositor);

    event Withdrawal(address owner, address receiver, address[] assets, bool includeNative);

    error NotAuthorized();
    error InvalidAddress();
    error NotWhitelisted();
    error InvalidReceiver();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Governable} from "./Governable.sol";

abstract contract Keepable is Governable {
    bytes32 public constant KEEPER = bytes32("KEEPER");

    modifier onlyKeeper() {
        if (!hasRole(KEEPER, msg.sender)) {
            revert CallerIsNotKeeper();
        }

        _;
    }

    function addKeeper(address _newKeeper) external onlyGovernor {
        _grantRole(KEEPER, _newKeeper);

        emit KeeperAdded(_newKeeper);
    }

    function removeKeeper(address _operator) external onlyGovernor {
        _revokeRole(KEEPER, _operator);

        emit KeeperRemoved(_operator);
    }

    event KeeperAdded(address _newKeeper);
    event KeeperRemoved(address _operator);

    error CallerIsNotKeeper();
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

interface IIncentiveReceiver {
    function deposit(address _token, uint256 _amount) external;

    function addDepositor(address _depositor) external;
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