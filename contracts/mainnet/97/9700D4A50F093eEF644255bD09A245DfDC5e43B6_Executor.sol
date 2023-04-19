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
                        Strings.toHexString(uint160(account), 20),
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {GenerateCallData} from "../utils/generateCalldata.sol";

enum QueryType {
    TIMESTAMP,
    USER,
    ZERO,
    QUERY
}

// This object will allow the contract to query the parameter onChain
struct ParameterQuery {
    QueryType parameterType;
    bool isCachable;
    GetInfoCalldata queryCallData;
}

struct DirectoryMethodInfo {
    uint8 argc;
    bytes4 methodSelector;
    uint8[4] amountPositions;
    uint8[4] amountMinimumPositions;
}

struct CallInfo {
    address interactionAddress;
    address[] inputTokens;
    bytes callData;
    uint256 value;
}

struct GetInfoCalldata {
    bytes callData;
    uint8 position;
    Location location;
}

// We want to be able to get the location of the data query
enum Location {
    PoolAddress,
    InteractionAddress,
    QueryPoolAddress,
    QueryInteractionAddress
}

struct GetSpecificMethodInfo {
    GetInfoCalldata[] getInTokens;
    GetInfoCalldata[] getOutTokens;
}

struct TokenLengths {
    uint8 inTokens;
    uint8 outTokens;
}

struct SpecificMethodInfo {
    address interactionAddress;
    address[] inTokens;
    address[] outTokens;
}

struct ParameterQueryInput {
    ParameterQuery query;
    uint8 position;
}

struct ProtocolInput {
    DirectoryMethodInfo methodInfo;
    GetInfoCalldata[] inTokens;
    GetInfoCalldata[] outTokens;
    TokenLengths tokenLengths;
    address rawInteractionAddress;
    GetInfoCalldata interactionAddress;
    ParameterQueryInput[] parameterQuery;
}

uint256 constant BLOCK_TIME_DELTA = 300; // 5min delta

contract Directory is GenerateCallData, AccessControl {
    address constant nativeToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// Here we want to get the mthod Info for each pool (different)
    // Mapping protocol name + method name to DirectoryMethodInfo
    mapping(string => mapping(string => DirectoryMethodInfo)) methods;

    // This object will allow to get the inTokens and outTokens for a poolAddress inside a certain protocol
    mapping(string => mapping(string => GetSpecificMethodInfo)) interactionTokens;
    mapping(string => mapping(string => TokenLengths)) tokenLengths;

    // Here we want to get the specific arguments for the called address (pool dependent)
    mapping(string => mapping(string => mapping(uint256 => ParameterQuery))) specificCallInfo;
    // The position in the argv array for that parameter
    mapping(string => mapping(string => uint8[])) specificCallInfoArgv;

    /// Here we want to get the interaction address from the pool address
    mapping(string => mapping(string => GetInfoCalldata)) interactionAddressInfo;
    mapping(string => mapping(string => address)) rawInteractionAddress;

    // We cache all the information we need from each call
    // The first call will cost something but the subsequent one will be much cheaper
    // For now, we only cache addresses
    // Keys are the following
    // (protocol, methoType, pool, infoId)
    mapping(string => mapping(string => mapping(bytes32 => bytes32))) public cachedInfo;

    function accessCache(string calldata protocol, string calldata methodType, bytes32 cacheKey)
        public
        view
        returns (bytes32 cache)
    {
        cache = cachedInfo[protocol][methodType][cacheKey];
    }

    function addressToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function bytes32ToAddress(bytes32 b) public pure returns (address) {
        return address(uint160(uint256(b)));
    }

    /* 
        MODIFIERS
    */

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// ============ Errors ============
    error NullCacheSet();
    error InvalidInteractionAddressConfig();
    error ProtocolNotRegistered();
    error InformationQueryFailed();

    /*
    constructor(bool setup){
    if(setup){
    // We start by saving the protocol info, for tests
     	setupYEARN();
     	setupVELODROME();
     	setupCURVE();
     	setupSTARGATE();
     }
    }
    */

    /* ******************************************* 	*/
    /*												*/
    /*  Admin only functions to add new protocols 	*/
    /*												*/
    /* ******************************************* 	*/

    /// @notice Registers a new protocol method in the directory
    /// @notice All the method information should be registered in a single call
    /// @notice This allows does not allow adding pool specific information
    ///
    /// @param protocol Designates the protocol that is being registered. E.g "velodrome/v0".
    ///        This is the main id of the registered method
    /// @param methodType Designates the method Type being integrated. E.g "deposit".
    ///        This is the secondary id of the registered method
    /// @param _input All the data that will be registered in the directory
    function registerMethod(string calldata protocol, string calldata methodType, ProtocolInput calldata _input)
        external
        onlyOwner
    {
        // Method Related Info
        methods[protocol][methodType] = _input.methodInfo;

        // In and Out tokens
        uint256 inTokenLength = _input.inTokens.length;
        delete interactionTokens[protocol][methodType].getInTokens;
        for (uint256 i; i < inTokenLength; ++i) {
            interactionTokens[protocol][methodType].getInTokens.push(_input.inTokens[i]);
        }
        uint256 outTokenLength = _input.outTokens.length;
        delete interactionTokens[protocol][methodType].getOutTokens;
        for (uint256 i; i < outTokenLength; ++i) {
            interactionTokens[protocol][methodType].getOutTokens.push(_input.outTokens[i]);
        }
        tokenLengths[protocol][methodType] = _input.tokenLengths;

        // Interaction Address
        rawInteractionAddress[protocol][methodType] = _input.rawInteractionAddress;
        interactionAddressInfo[protocol][methodType] = _input.interactionAddress;
        if (
            _input.interactionAddress.location == Location.InteractionAddress
                || _input.interactionAddress.location == Location.QueryInteractionAddress
        ) {
            revert InvalidInteractionAddressConfig();
        }

        // Other call arguments location
        uint256 parameterQueryLength = _input.parameterQuery.length;

        delete specificCallInfoArgv[protocol][methodType];
        for (uint256 i; i < parameterQueryLength; ++i) {
            specificCallInfo[protocol][methodType][i] = _input.parameterQuery[i].query;
            specificCallInfoArgv[protocol][methodType].push(_input.parameterQuery[i].position);
        }
    }

    function isMethodRegistered(string calldata protocol, string calldata methodType) public view returns (bool) {
        bytes4 methodSelector = methods[protocol][methodType].methodSelector;
        return methodSelector != bytes4(0);
    }

    /// @notice Registers a cache entry in the directory
    /// @notice This cache is pool specific and will be used instead of the queried information if present.
    ///	@dev Caching reduces gas usage for the following calls
    /// @param protocol Designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType Designates the method Type for which the information is registered e.g. "deposit"
    /// @param key The cache key that should be set
    /// 	Here are the different key types that can be used :
    /// 		- keccak256(abi.encode(poolAddress, "input",  uint256(n))) for the nth input token
    /// 		- keccak256(abi.encode(poolAddress, "output",  uint256(n))) for the nth output token
    ///			- keccak256(abi.encode(poolAddress, "interaction")) for the interaction address associated with the pool
    ///			- keccak256(abi.encode(poolAddress, "queries", uint256(n))) for the nth element in specificCallInfo
    /// @param value The cache value that should be set
    /// @dev Here are the two use cases for this function
    ///		1. Set a cache value so that no user bears the gas price associated with
    ///        getting the value and setting the cache
    ///		2. Register a pool specific value that is not queryable on chain (e.g. cirve investing addresses on ethereum)
    function setCache(string calldata protocol, string calldata methodType, bytes32 key, bytes32 value)
        external
        onlyOwner
    {
        if (value == bytes32(uint256(0))) revert NullCacheSet();
        cachedInfo[protocol][methodType][key] = value;
    }

    function resetCache(string calldata protocol, string calldata methodType, bytes32 key) external onlyOwner {
        cachedInfo[protocol][methodType][key] = bytes32(uint256(0));
    }

    /// @notice Queries the interaction address for a specific poolAddress
    /// @param poolAddress The poolAddress for which you want to query the interaction Address
    /// @param protocol designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType designates the method Type for which the information is registered e.g. "deposit"
    /// @dev To query the interaction address, this function :
    ///		1. Uses the cached value if any
    ///		2. Uses the interaction address registered with the protocol and methodType if any
    ///		3. Queries the interaction address using the GetInfoCalldata object associated with the protocol and method
    function _getInteractionAddress(address poolAddress, string calldata protocol, string calldata methodType)
        internal
        returns (address interactionAddress)
    {
        if (accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "interaction"))) != bytes32(0)) {
            interactionAddress =
                bytes32ToAddress(accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "interaction"))));
        } else {
            if (rawInteractionAddress[protocol][methodType] != address(0)) {
                interactionAddress = rawInteractionAddress[protocol][methodType];
            } else {
                interactionAddress =
                    bytes32ToAddress(_getInfo(poolAddress, address(0), interactionAddressInfo[protocol][methodType]));
            }
            cachedInfo[protocol][methodType][keccak256(abi.encode(poolAddress, "interaction"))] =
                addressToBytes32(interactionAddress);
        }
    }

    /// @notice Queries the input tokens for a specific poolAddress
    /// @param poolAddress The poolAddress for which you want to query the input tokens
    /// @param protocol Designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType Designates the method Type for the interaction e.g. "deposit"
    /// @dev To query the interaction address the contract, in order :
    ///		1. Uses the cached value if any
    ///		2. Queries the input tokens using the GetInfoCalldata objects associated with the protocol and method
    function getInputTokens(address poolAddress, string calldata protocol, string calldata methodType)
        public
        returns (address[] memory)
    {
        if (accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "input", uint256(0)))) != bytes32(0)) {
            address[] memory tokens = new address[](tokenLengths[protocol][methodType].inTokens);
            for (uint256 i; i < tokenLengths[protocol][methodType].inTokens; ++i) {
                tokens[i] =
                    bytes32ToAddress(accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "input", i))));
            }
            return tokens;
        }
        return
            getTokens(poolAddress, interactionTokens[protocol][methodType].getInTokens, protocol, methodType, "input");
    }

    /// @notice Queries the output tokens for a specific poolAddress
    /// @param poolAddress The poolAddress for which you want to query the output tokens
    /// @param protocol Designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType Designates the method Type for the interaction e.g. "deposit"
    /// @dev To query the output tokens, this function :
    ///		1. Uses the cached value if any
    ///		2. Queries the output tokens using the GetInfoCalldata objects associated with the protocol and method
    function getOutputTokens(address poolAddress, string calldata protocol, string calldata methodType)
        external
        returns (address[] memory)
    {
        if (accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "output", uint256(0)))) != bytes32(0)) {
            address[] memory tokens = new address[](tokenLengths[protocol][methodType].outTokens);
            for (uint256 i; i < tokenLengths[protocol][methodType].outTokens; ++i) {
                tokens[i] =
                    bytes32ToAddress(accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "output", i))));
            }
            return tokens;
        }
        return
            getTokens(poolAddress, interactionTokens[protocol][methodType].getOutTokens, protocol, methodType, "output");
    }

    function getTokens(
        address poolAddress,
        GetInfoCalldata[] memory getTokensInfo,
        string calldata protocol,
        string calldata methodType,
        string memory tokenType
    ) internal returns (address[] memory) {
        uint256 n = getTokensInfo.length;
        address[] memory tokens = new address[](n);
        address interactionAddress = address(0);

        for (uint256 i; i < n; ++i) {
            if (
                interactionAddress == address(0)
                    && (
                        getTokensInfo[i].location == Location.InteractionAddress
                            || getTokensInfo[i].location == Location.QueryInteractionAddress
                    )
            ) {
                interactionAddress = _getInteractionAddress(poolAddress, protocol, methodType);
            }
            bytes32 tokenBytes = _getInfo(poolAddress, interactionAddress, getTokensInfo[i]);
            tokens[i] = bytes32ToAddress(tokenBytes);
            cachedInfo[protocol][methodType][keccak256(abi.encode(poolAddress, tokenType, i))] = tokenBytes;
        }
        return tokens;
    }

    /// @notice Queries information on-chain using the directory data structure
    /// @param poolAddress The poolAddress for which you want to query data
    /// @param interactionAddress The interactionAddress of the pool for the current method
    /// @param info Information on how to query data from an address
    /// @dev Querying an info checks in order :
    /// 	1. If the location is Location.PoolAddress, it returns the poolAddress
    ///		2. If the location is Location.InteractionAddress, it returns the interactionAddress
    ///		3. Else, we conduct a full on-chain query to get the info result
    ///			a. We start by getting the queryAddress.
    ///				It's either the poolAddress/interactionAddress depending to Location
    ///			b. We call the read using the provided callData
    ///			c. We return the 32 bytes information at the info.position location.
    function _getInfo(address poolAddress, address interactionAddress, GetInfoCalldata memory info)
        internal
        returns (bytes32 data)
    {
        if (info.location == Location.PoolAddress) {
            return addressToBytes32(poolAddress);
        } else if (info.location == Location.InteractionAddress) {
            return addressToBytes32(interactionAddress);
        } else {
            address queryAddress;
            if (info.location == Location.QueryPoolAddress) {
                queryAddress = poolAddress;
            } else if (info.location == Location.QueryInteractionAddress) {
                queryAddress = interactionAddress;
            }

            (bool success, bytes memory result) = queryAddress.call(info.callData);

            uint256 tokenPosition = info.position;
            assembly {
                data := mload(add(result, mul(0x20, add(tokenPosition, 1))))
            }
            if (!success) revert InformationQueryFailed();
        }
    }

    /// @notice Fills the call argument array with the inputed amounts and minimumAmounts
    /// @param protocol designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType designates the method Type for which the information is registered e.g. "deposit"
    /// @param callInfo argument array that will be filled. Its length won't change.
    /// @param amounts Array of amounts that need to be provided to the interaction method.
    ///			This should have the same length as the methods[protocol][methodType].amountPositions
    /// @param amountsMinimum Array of minimum amounts that need to be provided to the interaction method.
    ///			This should have the same length as the methods[protocol][methodType].amountMinimumPositions
    function _fillAmountPositions(
        string calldata protocol,
        string calldata methodType,
        bytes32[] memory callInfo,
        uint256[] memory amounts,
        uint256[] memory amountsMinimum
    ) internal view returns (bytes32[] memory) {
        // We add the amount with their respective amountPositions and amountMinimumPositions
        // These array are the same length than the inTokens and are mandatory in the calldata
        uint256 amountPositionsLength = methods[protocol][methodType].amountPositions.length;
        for (uint256 i; i < amountPositionsLength; ++i) {
            if (methods[protocol][methodType].amountPositions[i] != type(uint8).max) {
                callInfo[methods[protocol][methodType].amountPositions[i]] = bytes32(amounts[i]);
            }
        }
        uint256 amountMinimumPositionsLength = methods[protocol][methodType].amountMinimumPositions.length;
        for (uint256 i; i < amountMinimumPositionsLength; ++i) {
            if (methods[protocol][methodType].amountMinimumPositions[i] != type(uint8).max) {
                callInfo[methods[protocol][methodType].amountMinimumPositions[i]] = bytes32(amountsMinimum[i]);
            }
        }
        return callInfo;
    }

    /// @notice Generates the method arguments that need to be queried (outside of amounts)
    /// @param protocol designates the protocol the pool belongs to. e.g "curve/v2"
    /// @param methodType designates the method Type for which the information is registered e.g. "deposit"
    /// @param poolAddress the address of the pool that is being interacted with
    /// @param callInfo argument array that will be filled with on-chain info. Its length won't change.
    /// @param receiver Address of the receiver of the operation if needed in the method arguments
    /// @dev This function can populate 3 types of data :
    ///		1. The current timestamp
    ///		2. The receiver of the interaction call
    ///		3. Any type of on-chain data, queryable with only one call from either
    /// 		a. The pool address
    ///			b. The interactionaddress
    ///			c. A raw address that only depends on the protocol and method type
    function generateOnChainArgs(
        string calldata protocol,
        string calldata methodType,
        address poolAddress,
        bytes32[] memory callInfo,
        address receiver
    ) internal returns (bytes32[] memory) {
        uint256 parameterQueryLength = specificCallInfoArgv[protocol][methodType].length;
        for (uint256 i; i < parameterQueryLength; ++i) {
            // First we try to get the call info from the cache

            bytes32 data;
            if (accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "queries", i))) != bytes32(0)) {
                data = accessCache(protocol, methodType, keccak256(abi.encode(poolAddress, "queries", i)));
                // We put it directly as bytes32 in our object
            } else {
                // If it's not in the cache, we load it as usual
                ParameterQuery memory parameterQuery = specificCallInfo[protocol][methodType][i];
                //We start by selecting the query type
                if (parameterQuery.parameterType == QueryType.TIMESTAMP) {
                    data = bytes32(block.timestamp + BLOCK_TIME_DELTA);
                } else if (parameterQuery.parameterType == QueryType.USER) {
                    data = addressToBytes32(receiver);
                } else if (parameterQuery.parameterType == QueryType.ZERO) {
                    data = bytes32(uint256(0));
                } else {
                    data = _getInfo(
                        poolAddress,
                        _getInteractionAddress(poolAddress, protocol, methodType),
                        parameterQuery.queryCallData
                    );
                    // We cache it if needed
                    if (parameterQuery.isCachable) {
                        cachedInfo[protocol][methodType][keccak256(abi.encode(poolAddress, "queries", i))] = data;
                    }
                }
            }
            callInfo[specificCallInfoArgv[protocol][methodType][i]] = data;
        }
        return callInfo;
    }

    /// @notice Generates address, calldata, value and input Tokens needed for interacting with a protocol.
    /// @notice This function allows protocols to integrate with multiple lending and AMM protocols with a
    ///         common contract interface
    /// @notice This aims at reducing dev time and simplify integration of different protocols
    /// @param poolAddress pool the user wants to interact with
    /// @param protocol protocol name the user wants to interact with. This protocol name should match information
    ///        that is stored in the contract
    /// @param methodType Type of operation the user wants to conduct on the protocol. e.g. "deposit"
    /// @param amounts Array of amounts that the user wants to provide to the protocol. e.g. In the case of
    ///        lending protocols, this array will have only one element
    /// @param amountsMinimum Array of minimum amounts the user wants to provide to the protocol (especially for AMMs)
    /// @param receiver Receiver of the interaction. This parameter is only used by the protocol that the user wants
    ///        to interact with
    function onChainAPI(
        address poolAddress,
        string calldata protocol,
        string calldata methodType,
        uint256[] memory amounts, // not changed to calldata, because there are too much local variables
        uint256[] memory amountsMinimum, // not changed to calldata, because there are too much local variables
        address receiver
    ) external returns (CallInfo memory callInfo) {
        //1. We get the method that is registered in the protocol
        callInfo.interactionAddress = _getInteractionAddress(poolAddress, protocol, methodType);
        if (callInfo.interactionAddress == address(0)) revert ProtocolNotRegistered();

        // 2. We need the inputTokens
        callInfo.inputTokens = getInputTokens(poolAddress, protocol, methodType);

        // 3. We need to generate the calldata
        // a. We need to know how much args there is
        bytes32[] memory callArgs = new bytes32[](methods[protocol][methodType].argc);
        {
            // b. We need to fill that array with the constant calldata (on-chain)
            callArgs = generateOnChainArgs(protocol, methodType, poolAddress, callArgs, receiver);
            // c. We need to fill that array with the amounts calldata (from arguments)
            callArgs = _fillAmountPositions(protocol, methodType, callArgs, amounts, amountsMinimum);
        }

        // 4. We need to make sure we send the right value in the transaction
        uint256 inputTokenLength = callInfo.inputTokens.length;
        for (uint256 i; i < inputTokenLength; ++i) {
            if (callInfo.inputTokens[i] == nativeToken) {
                callInfo.value += amounts[i];
            }
        }
        callInfo.callData = _generateCalldataFromBytes(methods[protocol][methodType].methodSelector, callArgs);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

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

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

/// @title Router for price estimation functionality
/// @notice Functions for getting the price of one token with respect to another using Uniswap V2
/// @dev This interface is only used for non critical elements of the protocol
interface IUniswapV2Router {
    /// @notice Given an input asset amount, returns the maximum output amount of the
    /// other asset (accounting for fees) given reserves.
    /// @param path Addresses of the pools used to get prices
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 swapAmount,
        uint256 minExpected,
        address[] calldata path,
        address receiver,
        uint256 swapDeadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {OutInformation, Operation} from "../utils/structs.sol";

abstract contract IExecutor {
    function execute(
        Operation[] memory routingCall, // Can't turn to calldata because of wrapper functions
        OutInformation memory outInformation // Can't turn to calldata because of wrapper functions
    ) public payable virtual;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {
    SwapOperation,
    SwapProtocol,
    InToken,
    InInformation,
    OutInformation,
    InteractionOperation,
    Operation,
    InteractionOperation,
    WrapperSelector,
    WrapperSelectorAMM,
    OneTokenSwapAMM
} from "../utils/structs.sol";
import {SwapHelper} from "../utils/swapHelper.sol";
import {GenerateCallData} from "../utils/generateCalldata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title  Executor
/// @author Valha Team - [email protected]
/// @notice Executor contract enabling the Router to execute the steps to perform the operations
contract Executor is SwapHelper, GenerateCallData {
    uint24 private constant UNISWAP_V3_FEE = 3000;

    /// ============ Constructor ============

    /// @notice Creates a new Router contract
    constructor() SwapHelper() {
        /* For faster testing */
        SwapProtocol[] memory _swapRouterTypes = new SwapProtocol[](3);
        address[] memory _swapRouterAddress = new address[](3);
        _swapRouterTypes[0] = SwapProtocol.UniswapV3;
        _swapRouterTypes[1] = SwapProtocol.OneInch;
        _swapRouterTypes[2] = SwapProtocol.ZeroX;
        _swapRouterAddress[0] = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _swapRouterAddress[1] = address(0x1111111254EEB25477B68fb85Ed929f73A960582);
        _swapRouterAddress[2] = address(0xDef1C0ded9bec7F1a1670819833240f027b25EfF);
        _registerSwaps(_swapRouterTypes, _swapRouterAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// ============ Errors ============
    error InteractionError();

    /// ============ Main Functions ============

    /// @notice Allows users to chain calls on-chain.
    /// @notice This function can chain swap and DeFi protocol interactions (deposit, redeem...)
    /// @dev    Requires user to approve contract.
    /// @param  routingCall contains all the swap and interaction information. This object is at the center of the contract's logic
    /// @param  outInformation contains all the tokens that will be sent back to the msg.sender after all interactions.
    function execute(
        Operation[] memory routingCall, // Can't turn to calldata because of wrapper functions
        OutInformation memory outInformation // Can't turn to calldata because of wrapper functions
    ) public payable {
        // We call all the interactions sequentially
        uint256 routingCallLength = routingCall.length;
        for (uint256 i; i < routingCallLength; ++i) {
            // We check which operation should be executed
            if (_isSwapOperation(routingCall[i])) {
                uint256 thisCallLength = routingCall[i].swap.length;
                for (uint256 j; j < thisCallLength; ++j) {
                    executeSwap(routingCall[i].swap[j]);
                }
            } else {
                uint256 thisCallLength = routingCall[i].interaction.length;
                for (uint256 j; j < thisCallLength; ++j) {
                    executeInteraction(routingCall[i].interaction[j]);
                }
            }
        }
        uint256 outTokenLength = outInformation.tokens.length;
        // We transfer the remaining tokens to the customer
        for (uint256 i; i < outTokenLength; ++i) {
            uint256 balance = _balanceOf(outInformation.tokens[i], address(this));
            _transferFromContract(outInformation.tokens[i], outInformation.to, balance);
        }
    }

    /// @notice Execute a swap operation
    /// @param  _swap contains all the information needed to execute the operation
    function executeSwap(SwapOperation memory _swap) internal {
        // Here we swap one asset for one other asset
        uint256 balance = thisBalanceOf(_swap.inToken);
        swap(_swap, min(balance, _swap.maxInAmount));
    }

    /// @notice Execute a DeFi operation
    /// @param  _interaction contains all the information needed to execute the operation
    function executeInteraction(InteractionOperation memory _interaction) internal {
        // We get all the inToken balances and change the inAmount of the call
        uint256 value;

        uint256 inTokenLength = _interaction.inTokens.length;
        for (uint256 i; i < inTokenLength; ++i) {
            uint256 balance = thisBalanceOf(_interaction.inTokens[i]);

            if (_interaction.amountPositions[i] != type(uint8).max) {
                _interaction.callArgs[_interaction.amountPositions[i]] = bytes32(balance);
            }

            if (_interaction.inTokens[i] == nativeToken) {
                value += balance;
            }
            _approveIfNecessary(_interaction.interactionAddress, _interaction.inTokens[i], balance);
        }

        bytes memory callData = _generateCalldataFromBytes(_interaction.methodSelector, _interaction.callArgs);

        (bool success,) = address(_interaction.interactionAddress).call{value: value}(callData);
        if (!success) revert InteractionError();
    }

    /// ============ Helpers Functions ============

    /// @notice Get the balance of a specific user of a specified token
    /// @param  _token address of the token to check the balance of
    /// @param  _user address of the user to check the balance of
    /// @return balance of the _user for the specific _contract
    function _balanceOf(address _token, address _user) internal view returns (uint256 balance) {
        if (_token == nativeToken) {
            balance = _user.balance;
        } else {
            balance = IERC20(_token).balanceOf(_user);
        }
    }

    /// @notice Get the balance of this contract of a specified token
    /// @param  _token address of the token to check the balance of
    /// @return balance of the router for the specific _token
    function thisBalanceOf(address _token) internal view returns (uint256 balance) {
        return _balanceOf(_token, address(this));
    }

    /// @notice     Get the minimum of two provided uint256 values
    /// @param      a uint256 value
    /// @param      b uint256 value
    /// @return     The minimum value between a and b
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    /// @dev Callback for receiving Ether when the calldata is empty
    /// Because the owner can remove funds from the contract, we allow depositing funds here
    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import {
    SwapOperation,
    SwapProtocol,
    InToken,
    InInformation,
    OutInformation,
    InteractionOperation,
    Operation,
    InteractionOperation,
    WrapperSelector,
    WrapperSelectorAMM,
    OneTokenSwapAMM
} from "../utils/structs.sol";
import {SwapHelper} from "../utils/swapHelper.sol";
import {GenerateCallData} from "../utils/generateCalldata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IExecutor} from "../Interfaces/IExecutor.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Helpers} from "../utils/helpers.sol";

/// @title  Router
/// @author Valha Team - [email protected]
/// @notice Router contract enabling to bundle Swap and DeFi interactions calls
contract Router is AccessControl, Helpers {
    uint24 private constant UNISWAP_V3_FEE = 3000;
    address constant nativeToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 constant MAX_FEE = 1e16; // 1e16
    uint256 constant FEE_UNITS = 1e18; // 1e18
    address payable referralSig;

    /// ============ Constructor ============

    // This need to be public so that it can be queried off_chain
    bytes32 public constant WHITELIST_ROLE = keccak256("WHITELIST_ROLE");

    // This stores the contract that will execute walls
    IExecutor executor;

    using SafeERC20 for IERC20;

    /// @notice Creates a new Router contract
    /// @param  _executor contract that will execute the sent calldata
    constructor(address _executor, address payable _referralSig) {
        referralSig = _referralSig;
        executor = IExecutor(_executor);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice modifier to let only whitelisted user to interact with the function
    modifier onlyWhitelist() {
        _checkRole(WHITELIST_ROLE);
        _;
    }

    /// ============ EVENTS ============

    event Referral(uint16 indexed referrer, uint80 fee);

    /// ============ Errors ============
    error InteractionError();
    error FeeToHigh();

    /// ============ Helpers ============
    function _transferTo(address token, uint256 amount, address to, uint80 fee, uint16 referral) internal {
        // 1.a
        if ((fee != 0) && referralSig != address(0)) {
            if (fee > MAX_FEE) revert FeeToHigh();
            uint256 feeAmount = (amount * fee) / FEE_UNITS;
            if (token != nativeToken) {
                _safeTransferFrom(token, msg.sender, referralSig, feeAmount);
            } else {
                referralSig.transfer(feeAmount);
            }
            emit Referral(referral, fee);
            amount -= feeAmount;
        }

        if (token != nativeToken) {
            _safeTransferFrom(token, msg.sender, to, amount);
        }
    }

    /// ============ Main Functions ============

    /// @notice Allows users to chain calls on-chain.
    /// @notice This function can chain swap and DeFi protocol interactions (deposit, redeem...)
    /// @dev    Requires user to approve contract.
    /// @dev    Dispatch the execution to the executor to avoid risk of hacks.
    /// @param  inInformation Information about the tokens used for initiating the call chain.
    ///         All the tokens in the object will be transferred to the contract if not native
    /// @param  routingCall contains all the swap and interaction information.
    ///         This object is at the center of the contract's logic
    /// @param  outInformation contains all the tokens that will be sent back to the msg.sender after all interactions.
    function multiRoute(
        InInformation memory inInformation, // Can't turn to calldata because of wrapper functions
        Operation[] memory routingCall, // Can't turn to calldata because of wrapper functions
        OutInformation memory outInformation // Can't turn to calldata because of wrapper functions
    ) public payable {
        // We transfer the tokens in the contract
        uint256 inTokenLength = inInformation.inTokens.length;
        for (uint256 i; i < inTokenLength; ++i) {
            _transferTo(
                inInformation.inTokens[i].tokenAddress,
                uint256(inInformation.inTokens[i].amount),
                address(executor),
                inInformation.fee,
                inInformation.referral
            );
        }

        if (outInformation.to == address(0)) {
            outInformation.to = msg.sender;
        }

        executor.execute(routingCall, outInformation);
    }

    /// ============ Helpers Functions ============

    /// @notice Get the balance of a specific user of a specified token
    /// @param  _token address of the token to check the balance of
    /// @param  _user address of the user to check the balance of
    /// @return balance of the _user for the specific _contract
    function _balanceOf(address _token, address _user) internal view returns (uint256 balance) {
        if (_token == nativeToken) {
            balance = _user.balance;
        } else {
            balance = IERC20(_token).balanceOf(_user);
        }
    }

    /// @notice Get the balance of this contract of a specified token
    /// @param  _token address of the token to check the balance of
    /// @return balance of the router for the specific _token
    function thisBalanceOf(address _token) internal view returns (uint256 balance) {
        return _balanceOf(_token, address(this));
    }

    /// @notice     Get the minimum of two provided uint256 values
    /// @param      a uint256 value
    /// @param      b uint256 value
    /// @return     The minimum value between a and b
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    /// @dev Callback for receiving Ether when the calldata is empty
    /// Because the owner can remove funds from the contract, we allow depositing funds here
    receive() external payable {}

    /// ================================================
    /// ================================================
    /// ================= L2 WRAPPERS ==================
    /// ================================================
    /// ================================================

    /// ============ l2Wrappers Functions ============

    /// @notice Allows a user to use multiRoute to deposit in a single token pool with fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_position_interaction Arguments for the selector, amount position
    ///         and interaction address in one bytes32
    ///    32 bits    8 bits        160 bits          56 bits
    /// | selector | position | interactionAddress | 0-padding |
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    ///      96 bits           160 bits
    /// |     amount      | tokenOutAddress |
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function deposit(
        bytes32 method_position_interaction,
        bytes32 amount_tokenOut,
        bytes32 referral_tokenIn,
        bytes32[] calldata callArgs
    ) external payable {
        InInformation memory inInfo;
        OutInformation memory outInfo;
        Operation[] memory args = new Operation[](1);
        address tokenIn;
        (tokenIn, inInfo, outInfo) = _decodeDepositParams(amount_tokenOut, referral_tokenIn);
        args[0] = _decodeInteractionOperation(method_position_interaction, tokenIn, callArgs);
        // call underlying multiRoute
        multiRoute(inInfo, args, outInfo);
    }

    /// @notice Allows a user to use multiRoute to swap and deposit in a single token pool with fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_position_interaction Arguments for the selector, amount position
    ///         and interaction address in one bytes32
    ///    32 bits    8 bits        160 bits          56 bits
    /// | selector | position | interactionAddress | 0-padding |
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    ///      96 bits           160 bits
    /// |     amount      | tokenOutAddress |
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  swapToken_min Arguments for the swap_token and amount minimum in one bytes32
    ///          96 bits               160 bits
    /// |     amountMinimum      |     swapToken     |
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function swapAndDeposit(
        bytes32 method_position_interaction,
        bytes32 amount_tokenOut,
        bytes32 referral_tokenIn,
        bytes32 swapToken_min,
        bytes32[] calldata callArgs
    ) external payable {
        address tokenIn;
        InInformation memory inInfo;
        Operation[] memory args = new Operation[](2);
        Operation memory argSwap;
        OutInformation memory outInfo;
        (tokenIn, inInfo, argSwap, outInfo) =
            _decodeSwapAndDepositParams(amount_tokenOut, referral_tokenIn, swapToken_min);
        args[0] = argSwap;
        args[1] = _decodeInteractionOperation(method_position_interaction, tokenIn, callArgs);
        // call underlying multiRoute
        multiRoute(inInfo, args, outInfo);
    }

    /// @notice Allows a user to use multiRoute to redeem and swap in a single token pool with fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_position_interaction Arguments for the selector, amount position
    ///         and interaction address in one bytes32
    ///    32 bits    8 bits        160 bits          56 bits
    /// | selector | position | interactionAddress | 0-padding |
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    ///      96 bits           160 bits
    /// |     amount      | tokenOutAddress |
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  swapToken_min Arguments for the swap_token and amount minimum in one bytes32
    ///          96 bits               160 bits
    /// |     amountMinimum      |     swapToken     |
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function redeemAndSwap(
        bytes32 method_position_interaction,
        bytes32 amount_tokenOut,
        bytes32 referral_tokenIn,
        bytes32 swapToken_min,
        bytes32[] calldata callArgs
    ) external payable {
        InInformation memory inInfo;
        Operation[] memory args = new Operation[](2);
        Operation memory argSwap;
        OutInformation memory outInfo;
        address tokenIn;
        (tokenIn, inInfo, argSwap, outInfo) =
            _decodeRedeemAndSwapParams(amount_tokenOut, referral_tokenIn, swapToken_min);
        args[0] = _decodeInteractionOperation(method_position_interaction, tokenIn, callArgs);
        args[1] = argSwap;
        multiRoute(inInfo, args, outInfo);
    }

    /// @notice Allows a user to use multiRoute to deposit in a two tokens pool with fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_interaction Arguments for the selector and interaction address in one bytes32
    ///    32 bits        160 bits          64 bits
    /// | selector |  interactionAddress | 0-padding |
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  tokensIn contains the tokens that the user needs to use to enter the pool
    /// @param  amountsIn contains the amounts that the user wants to use to enter the pool
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function depositAMM(
        bytes32 method_interaction,
        bytes32 referral_poolToken,
        uint8[4] calldata amountPositions,
        address[] calldata tokensIn,
        uint96[] calldata amountsIn,
        bytes32[] calldata callArgs
    ) external payable {
        InInformation memory inInfo;
        OutInformation memory outInfo;
        Operation[] memory args = new Operation[](1);
        (inInfo, outInfo) = _decodeDepositInOutParams(referral_poolToken, tokensIn, amountsIn);
        args[0] = _decodeDepositInteractionOperationAMM(method_interaction, amountPositions, tokensIn, callArgs);
        multiRoute(inInfo, args, outInfo);
    }

    /// @notice Allows a user to use multiRoute to deposit in a two tokens pool with only one token and fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_interaction Arguments for the selector and interaction address in one bytes32
    ///    32 bits        160 bits          64 bits
    /// | selector |  interactionAddress | 0-padding |
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  swap_in Arguments for the amount and swap_token_in in one bytes32
    ///      96 bits           160 bits
    /// |     amount      |   swapTokenIn |
    /// @param  swap_min Arguments for the minimum_amount and swap_token_out in one bytes32
    ///       96 bits               160 bits
    /// |  minimum_amount      | swapTokenOut |
    /// @param  amountPositions contains the positions of amounts value in _callArgs
    /// @param  tokensIn contains the tokens that the user needs to use to enter the pool
    /// @param  amountsIn contains the amounts that the user wants to use to enter the pool
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function swapAndDepositAMM(
        bytes32 method_interaction,
        bytes32 referral_poolToken,
        bytes32 swap_in,
        bytes32 swap_min,
        uint8[4] calldata amountPositions,
        address[] calldata tokensIn,
        uint96[] calldata amountsIn,
        bytes32[] calldata callArgs
    ) external payable {
        InInformation memory inInfo;
        Operation[] memory args = new Operation[](2);
        OutInformation memory outInfo;
        (inInfo, outInfo) = _decodeDepositInOutParams(referral_poolToken, tokensIn, amountsIn);
        args[0] = _decodeSwapOperationAMM(swap_in, swap_min);
        args[1] = _decodeDepositInteractionOperationAMM(method_interaction, amountPositions, tokensIn, callArgs);
        multiRoute(inInfo, args, outInfo);
    }

    /// @notice Allows a user to use multiRoute to redeem from a two tokens pool with only one token and fewer call
    /// arguments to reduce gas cost on l2
    /// @dev    Requires user to approve contract.
    /// @param  method_interaction Arguments for the selector and interaction address in one bytes32
    ///    32 bits        160 bits          64 bits
    /// | selector |  interactionAddress | 0-padding |
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    ///    16 bits             80 bits           160 bits
    /// | referral_id |    percentage_fee    | tokenInAddress |
    /// @param  swap_in Arguments for the amount and swap_token_in in one bytes32
    ///      96 bits           160 bits
    /// |     amount      |   swapTokenIn |
    /// @param  swap_min Arguments for the minimum_amount and swap_token_out in one bytes32
    ///       96 bits               160 bits
    /// |  minimum_amount      | swapTokenOut |
    /// @param  amount is the amount the user wants to redeem from the pool
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    function redeemAndSwapAMM(
        bytes32 method_interaction,
        bytes32 referral_poolToken,
        bytes32 swap_in,
        bytes32 swap_min,
        uint8[4] calldata amountPositions,
        uint96 amount,
        bytes32[] calldata callArgs
    ) external payable {
        InInformation memory inInfo;
        Operation[] memory args = new Operation[](2);
        OutInformation memory outInfo;

        (inInfo, outInfo) = _decodeRedeemInOutParams(referral_poolToken, swap_min, amount);
        args[0] =
            _decodeRedeemInteractionOperationAMM(method_interaction, referral_poolToken, amountPositions, callArgs);
        args[1] = _decodeSwapOperationAMM(swap_in, swap_min);
        multiRoute(inInfo, args, outInfo);
    }

    /// ============ Wrappers Internal Functions ============

    /// @notice Decodes compressed interaction params to standard Operation object
    /// @param  method_position_interaction Arguments for the selector, amount position
    ///         and interaction address in one bytes32
    /// @param  tokenIn token entering the router for this specified interaction
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    /// @return the Operation object to send to multiRoute function
    function _decodeInteractionOperation(
        bytes32 method_position_interaction,
        address tokenIn,
        bytes32[] calldata callArgs
    ) internal pure returns (Operation memory) {
        bytes4 methodSelector = bytes4(method_position_interaction);
        uint8 amountPosition;
        address interactionAddress;
        assembly {
            interactionAddress := and(shr(56, method_position_interaction), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amountPosition := and(shr(216, method_position_interaction), 0xFF)
        }
        Operation memory argDeposit;
        argDeposit.interaction = new InteractionOperation[](1);
        address[] memory addressesArray = new address[](1);
        addressesArray[0] = tokenIn;
        argDeposit.interaction[0] = InteractionOperation(
            callArgs, methodSelector, interactionAddress, [amountPosition, 0, 0, 0], addressesArray
        );
        return argDeposit;
    }

    /// @notice Decodes compressed deposit params to standard InInformation and OutInformation objects
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    /// @return the tokenIn, the InInformation object, the OutInformation object
    function _decodeDepositParams(bytes32 amount_tokenOut, bytes32 referral_tokenIn)
        internal
        pure
        returns (address, InInformation memory, OutInformation memory)
    {
        address tokenOut;
        uint96 amount;
        assembly {
            tokenOut := and(amount_tokenOut, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := and(shr(160, amount_tokenOut), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        address tokenIn;
        uint80 fee;
        uint16 referral;
        assembly {
            tokenIn := and(referral_tokenIn, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            fee := and(shr(160, referral_tokenIn), 0xFFFFFFFFFFFFFFFFFF)
            referral := and(shr(240, referral_tokenIn), 0xFFFF)
        }
        InInformation memory inInfo;
        inInfo.inTokens = new InToken[](1);
        inInfo.referral = referral;
        inInfo.fee = fee;
        inInfo.inTokens[0] = InToken(tokenIn, uint96(amount));

        OutInformation memory outInfo;
        outInfo.tokens = new address[](1);
        outInfo.tokens[0] = tokenOut;

        return (tokenIn, inInfo, outInfo);
    }

    /// @notice Decodes compressed SwapAndDeposit params to standard InInformation and OutInformation
    ///         objects and Operation object for the initial swap
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    /// @param  swapToken_min Arguments for the swap_token and amount minimum in one bytes32
    /// @return the tokenIn, the InInformation object, the Interaction object for swap, the OutInformation object
    function _decodeSwapAndDepositParams(bytes32 amount_tokenOut, bytes32 referral_tokenIn, bytes32 swapToken_min)
        internal
        pure
        returns (address, InInformation memory, Operation memory, OutInformation memory)
    {
        address tokenOut;
        uint96 amount;
        assembly {
            tokenOut := and(amount_tokenOut, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := and(shr(160, amount_tokenOut), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        address tokenIn;
        uint80 fee;
        uint16 referral;
        assembly {
            tokenIn := and(referral_tokenIn, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            fee := and(shr(160, referral_tokenIn), 0xFFFFFFFFFFFFFFFFFF)
            referral := and(shr(240, referral_tokenIn), 0xFFFF)
        }
        address swapToken;
        uint96 amountMin;
        assembly {
            swapToken := and(swapToken_min, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amountMin := and(shr(160, swapToken_min), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        InInformation memory inInfo;
        inInfo.inTokens = new InToken[](1);
        inInfo.referral = referral;
        inInfo.fee = fee;
        inInfo.inTokens[0] = InToken(swapToken, uint96(amount));

        Operation memory argSwap;
        argSwap.swap = new SwapOperation[](1);
        argSwap.swap[0] = (
            SwapOperation(
                swapToken, //address inToken;
                amount, //uint256 maxInAmount;
                tokenIn, //address outToken;
                amountMin, //uint256 minOutAmount;
                SwapProtocol.UniswapV3, //SwapProtocol protocol;
                abi.encode(uint24(3000)) //bytes args;
            )
        );

        OutInformation memory outInfo;
        outInfo.tokens = new address[](1);
        outInfo.tokens[0] = tokenOut;

        return (tokenIn, inInfo, argSwap, outInfo);
    }

    /// @notice Decodes compressed RedeemAndSwap params to standard InInformation and OutInformation
    ///         objects and Operation object for the final swap
    /// @param  amount_tokenOut Arguments for the amount and token_out in one bytes32
    /// @param  referral_tokenIn Arguments for the referral_id, fee and token_in in one bytes32
    /// @param  swapToken_min Arguments for the swap_token and amount minimum in one bytes32
    /// @return the tokenIn, the InInformation object, the Interaction object for swap, the OutInformation object
    function _decodeRedeemAndSwapParams(bytes32 amount_tokenOut, bytes32 referral_tokenIn, bytes32 swapToken_min)
        internal
        pure
        returns (address, InInformation memory, Operation memory, OutInformation memory)
    {
        address tokenOut;
        uint96 amount;
        assembly {
            tokenOut := and(amount_tokenOut, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amount := and(shr(160, amount_tokenOut), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        address tokenIn;
        uint80 fee;
        uint16 referral;
        assembly {
            tokenIn := and(referral_tokenIn, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            fee := and(shr(160, referral_tokenIn), 0xFFFFFFFFFFFFFFFFFF)
            referral := and(shr(240, referral_tokenIn), 0xFFFF)
        }
        address swapToken;
        uint96 amountMin;
        assembly {
            swapToken := and(swapToken_min, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amountMin := and(shr(160, swapToken_min), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        InInformation memory inInfo;
        inInfo.inTokens = new InToken[](1);
        inInfo.referral = referral;
        inInfo.fee = fee;
        inInfo.inTokens[0] = InToken(tokenIn, uint96(amount));

        Operation memory argSwap;
        argSwap.swap = new SwapOperation[](1);
        argSwap.swap[0] = (
            SwapOperation(
                tokenOut, type(uint256).max, swapToken, amountMin, SwapProtocol.UniswapV3, abi.encode(uint24(3000))
            )
        );

        OutInformation memory outInfo;
        outInfo.tokens = new address[](1);
        outInfo.tokens[0] = swapToken;

        return (tokenIn, inInfo, argSwap, outInfo);
    }

    /// @notice Decodes compressed Swap Operation params to standard Operation object for AMM
    /// @param  swap_in Arguments for the amount and swap_token_in in one bytes32
    /// @param  swap_min Arguments for the minimum_amount and swap_token_out in one bytes32
    /// @return the Operation object for the swap
    function _decodeSwapOperationAMM(bytes32 swap_in, bytes32 swap_min) internal pure returns (Operation memory) {
        address swapTokenIn;
        uint96 swapAmount;
        assembly {
            swapTokenIn := and(swap_in, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            swapAmount := and(shr(160, swap_in), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        address swapTokenOut;
        uint96 amountMin;
        assembly {
            swapTokenOut := and(swap_min, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            amountMin := and(shr(160, swap_min), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        Operation memory argSwap;
        argSwap.swap = new SwapOperation[](1);
        argSwap.swap[0] = (
            SwapOperation(
                swapTokenIn, swapAmount, swapTokenOut, amountMin, SwapProtocol.UniswapV3, abi.encode(uint24(3000))
            )
        );

        return argSwap;
    }

    /// @notice Decodes compressed Deposit params to standard InInformation and OutInformation for AMM
    ///         objects and Operation object for the final swap
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    /// @param  tokensIn contains the tokens that the user needs to use to enter the pool
    /// @param  amountsIn contains the amounts that the user wants to use to enter the pool
    /// @return the InInformation object and the OutInformation object
    function _decodeDepositInOutParams(
        bytes32 referral_poolToken,
        address[] calldata tokensIn,
        uint96[] calldata amountsIn
    ) internal pure returns (InInformation memory, OutInformation memory) {
        address poolToken;
        uint80 fee;
        uint16 referral;
        assembly {
            poolToken := and(referral_poolToken, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            fee := and(shr(160, referral_poolToken), 0xFFFFFFFFFFFFFFFFFF)
            referral := and(shr(240, referral_poolToken), 0xFFFF)
        }
        InInformation memory inInfo;
        inInfo.inTokens = new InToken[](tokensIn.length);
        for (uint256 i = 0; i < tokensIn.length; i++) {
            inInfo.inTokens[i] = InToken(tokensIn[i], amountsIn[i]);
        }
        inInfo.referral = referral;
        inInfo.fee = fee;

        OutInformation memory outInfo;
        outInfo.tokens = new address[](1);
        outInfo.tokens[0] = poolToken;

        return (inInfo, outInfo);
    }

    /// @notice Decodes compressed Deposit Operation params to standard Operation object for AMM
    /// @param  method_interaction Arguments for the selector and interaction address in one bytes32
    /// @param  amountPositions contains the positions of amounts value in _callArgs
    /// @param  tokensIn contains the tokens that the user needs to use to enter the pool
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    /// @return the Operation object for the deposit
    function _decodeDepositInteractionOperationAMM(
        bytes32 method_interaction,
        uint8[4] calldata amountPositions,
        address[] calldata tokensIn,
        bytes32[] calldata callArgs
    ) internal pure returns (Operation memory) {
        bytes4 methodSelector = bytes4(method_interaction);
        address interactionAddress;
        assembly {
            interactionAddress := and(shr(64, method_interaction), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        Operation memory arg;
        arg.interaction = new InteractionOperation[](1);
        arg.interaction[0] =
            (InteractionOperation(callArgs, methodSelector, interactionAddress, amountPositions, tokensIn));

        return arg;
    }

    /// @notice Decodes compressed Redeem params to standard InInformation and OutInformation for AMM
    ///         objects and Operation object for the final swap
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    /// @param  swap_min Arguments for the minimum_amount and swap_token_out in one bytes32
    /// @param  amount contains the amount that the user wants to redeem from the pool
    /// @return the InInformation object and the OutInformation object
    function _decodeRedeemInOutParams(bytes32 referral_poolToken, bytes32 swap_min, uint96 amount)
        internal
        pure
        returns (InInformation memory, OutInformation memory)
    {
        address poolToken;
        uint80 fee;
        uint16 referral;
        assembly {
            poolToken := and(referral_poolToken, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            fee := and(shr(160, referral_poolToken), 0xFFFFFFFFFFFFFFFFFF)
            referral := and(shr(240, referral_poolToken), 0xFFFF)
        }
        address swapTokenOut;
        assembly {
            swapTokenOut := and(swap_min, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        InInformation memory inInfo;
        inInfo.inTokens = new InToken[](1);
        inInfo.inTokens[0] = InToken(poolToken, amount);
        inInfo.referral = referral;
        inInfo.fee = fee;

        OutInformation memory outInfo;
        outInfo.tokens = new address[](1);
        outInfo.tokens[0] = swapTokenOut;

        return (inInfo, outInfo);
    }

    /// @notice Decodes compressed Redeem Operation params to standard Operation object for AMM
    /// @param  method_interaction Arguments for the selector and interaction address in one bytes32
    /// @param  referral_poolToken Arguments for the referral_id, fee and pool_token in one bytes32
    /// @param  amountPositions contains the positions of amounts value in _callArgs
    /// @param  callArgs contains the args in bytes32 necessary to execute the action on the underlying Protocol
    /// @return the Operation object for the redeem
    function _decodeRedeemInteractionOperationAMM(
        bytes32 method_interaction,
        bytes32 referral_poolToken,
        uint8[4] calldata amountPositions,
        bytes32[] calldata callArgs
    ) internal pure returns (Operation memory) {
        bytes4 methodSelector = bytes4(method_interaction);
        address interactionAddress;
        assembly {
            interactionAddress := and(shr(64, method_interaction), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
        address poolToken;
        assembly {
            poolToken := and(referral_poolToken, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        address[] memory addressesArray = new address[](1);
        addressesArray[0] = poolToken;
        Operation memory arg;
        arg.interaction = new InteractionOperation[](1);
        arg.interaction[0] =
            (InteractionOperation(callArgs, methodSelector, interactionAddress, amountPositions, addressesArray));

        return arg;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

///Methods
enum TYPES {
    ADDRESS, // 0
    UINT256, // 1
    STRING, // 2
    BYTES32, // 3
    BOOL, // 4
    ADDRESS_ARRAY, // 5
    UINT_ARRAY // 6
}

struct MethodInfo {
    address interactionAddress;
    uint256 argcArray;
    InputArguments[] argv;
    uint256[] amountPositions;
    bool hasAmountsArray;
    address[] inTokens;
    address[] outTokens;
    string methodName;
}

struct InputArguments {
    TYPES argType; // type array to consider (ex 0 == addressArguments)
    uint8 argv; // Position in type array
}

struct CallInfo {
    address[] addressArguments;
    uint256[] uintArguments;
    string[] stringArguments;
    bool[] boolArguments;
    bytes32[] bytes32Arguments;
    address[][] addressArrayArguments;
    uint256[][] uintArrayArguments;
}

contract GenerateCallData {
    /// @notice Generates the calldata needed to complete a call
    ///     This function generates the calldata for a contract interaction
    /// @param method 4 bytes method selector
    /// @param args. The arguments passed to the method. This array should be created following ABI specifications.
    ///     As this router and directory version only relies on non-array parameters, we accept arguments in bytes32 slots
    function _generateCalldataFromBytes(bytes4 method, bytes32[] memory args) internal pure returns (bytes memory) {
        /// calculate the position where static elements start in the bytes array, 32 + 4 as the function selector is bytes4
        uint256 offset = 36;
        uint256 n = args.length;
        /// calculate the size of the bytes array and allocate the bytes array -- 2
        uint256 bSize = 4 + n * 32;
        bytes memory result = new bytes(bSize);
        /// concat the function selector of the method at the first position of the bytes array -- 3
        bytes4 selector = method;
        assembly {
            mstore(add(result, 32), selector)
        }
        /// loop through all the arguments of the method to add them to the calldata
        for (uint256 i; i < n; ++i) {
            /// get the position of the arg in the method and the input arg in bytes32
            bytes32 arg = args[i];
            assembly {
                mstore(add(result, offset), arg)
            }
            /// offset to write the next bytes32 arg during the next loop
            offset += 32;
        }
        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Helpers {
    /// @dev We choose to not user OZ interface for gas optimisation purposes
    /// @dev This router doesn't need to be safe on token transfers as its storage nevers depends on transfer parameters
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

enum SwapProtocol {
    None, //0
    UniswapV3, //1
    OneInch, //2
    ZeroX //3
}

enum SwapLocation {
    NONE,
    BEFORE_ACTION,
    AFTER_ACTION
}

struct SwapOperation {
    address inToken;
    uint256 maxInAmount;
    address outToken;
    uint256 minOutAmount;
    SwapProtocol protocol;
    bytes args;
}

struct InteractionOperation {
    bytes32[] callArgs;
    bytes4 methodSelector;
    address interactionAddress;
    uint8[4] amountPositions; // Maximum 32 elements to keep it in one slot please
    address[] inTokens;
}

/// @notice An operation can either be a set of swaps or a set of protocol interactions.
/// @notice Those operations will always be treated sequentially, on after the other in the order in which they were provided
/// @notive However, the tokens that come out of an operation don't necessarily have to match the input tokens of the next operation.
/// @notice We chose to provide the swap or interaction operations as arrays, to avoid sending a lot of placeholder data.
/// @notice We do that, because in EVM execution, we CAN send an empty array, but we CAN'T send empty data.
/// @dev When using those arrays, feel free to compose your swaps and interaction however you like.
/// @dev The function will revert if swap and interaction are non-empty simultaneously
struct Operation {
    SwapOperation[] swap;
    InteractionOperation[] interaction;
}

// Compressed InInformation
struct InInformation {
    InToken[] inTokens;
    uint80 fee;
    uint16 referral;
}

// Exactly 1 storage slot maximum 1e28 amount
struct InToken {
    address tokenAddress;
    uint96 amount;
}

struct OutInformation {
    address to;
    address[] tokens;
}

struct WrapperSelector {
    bytes4 methodSelector;
    uint8 amountPosition;
    address interactionAddress;
    address tokenIn;
    uint96 amount;
    address tokenOut;
    uint16 referral;
    uint80 fee;
}

struct WrapperSelectorAMM {
    bytes4 methodSelector;
    address interactionAddress;
    address poolToken;
    uint16 referral;
    uint80 fee;
    uint8[4] amountPositions;
}

struct OneTokenSwapAMM {
    address swapTokenIn;
    uint96 swapAmount;
    address swapTokenOut;
    uint96 amountMin;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IUniswapV3Router, ExactInputSingleParams, ExactInputParams} from "../Interfaces/external/IUniswapRouter.sol";
import {
    SwapOperation,
    SwapProtocol,
    InToken,
    InInformation,
    OutInformation,
    InteractionOperation,
    Operation,
    InteractionOperation
} from "../utils/structs.sol";

abstract contract SwapHelper is AccessControl {
    address constant nativeToken = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    using SafeERC20 for IERC20;

    // Mapping of router type to router address
    mapping(SwapProtocol => address) swapRouters;

    /// ============ MODIFIERS ============

    modifier onlyOwner() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    /// ============ Errors ============
    error FeeToHigh();
    error OnlyOneOperationTypePer();
    error AtLeastOneOperationTypePer();
    error ProtocolNotSupported();
    error TokenSwapFailed();
    error TokenNotContract();
    error TransferFromFailed();

    /// ============ Admin Functions ============

    function removeTokens(address _to, address _token, bool _native) external onlyOwner {
        if (_native) {
            payable(_to).transfer(address(this).balance);
        } else {
            _safeTransferFrom(_token, address(this), _to, IERC20(_token).balanceOf(address(this)));
        }
    }

    function registerSwaps(SwapProtocol[] calldata _swapProtocols, address[] calldata _routers) external onlyOwner {
        uint256 n = _swapProtocols.length;
        for (uint256 i; i < n; ++i) {
            swapRouters[_swapProtocols[i]] = _routers[i];
        }
    }

    function _registerSwaps(SwapProtocol[] memory _swapProtocols, address[] memory _routers) internal {
        uint256 n = _swapProtocols.length;
        for (uint256 i; i < n; ++i) {
            swapRouters[_swapProtocols[i]] = _routers[i];
        }
    }

    /// ============ Internal Functions ============

    function _transferFromContract(address token, address to, uint256 amount) internal {
        // 1.a
        if (amount == 0) {
            return;
        }
        if (to == address(0)) {
            to = msg.sender;
        }
        if (token != nativeToken) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            payable(to).transfer(amount);
        }
    }

    function _isSwapOperation(Operation memory operation) internal pure returns (bool isSwap) {
        if (operation.swap.length != 0 && operation.interaction.length != 0) revert OnlyOneOperationTypePer();
        if (operation.swap.length == 0 && operation.interaction.length == 0) revert AtLeastOneOperationTypePer();

        if (operation.swap.length != 0) {
            return true;
        } else {
            return false;
        }
    }

    function _swapWithCalldata(SwapOperation memory _swap, uint256 amount)
        internal
        returns (bool success, uint256 swapAmount)
    {
        uint256 value;
        if (_swap.inToken == nativeToken) {
            value = amount;
        }
        bytes memory returnBytes;
        (success, returnBytes) = swapRouters[_swap.protocol].call{value: value}(_swap.args);
        swapAmount = abi.decode(returnBytes, (uint256));
    }

    function _swapUniswapV3(SwapOperation memory _swap, uint256 amount)
        internal
        returns (bool success, uint256 swapAmount)
    {
        ExactInputSingleParams memory params = ExactInputSingleParams({
            tokenIn: _swap.inToken,
            tokenOut: _swap.outToken,
            fee: abi.decode(_swap.args, (uint24)),
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: _swap.minOutAmount,
            sqrtPriceLimitX96: 0
        });

        uint256 value;
        if (_swap.inToken == nativeToken) {
            value = amount;
        }

        swapAmount = IUniswapV3Router(swapRouters[SwapProtocol.UniswapV3]).exactInputSingle{value: value}(params);

        success = true;
    }

    function swap(SwapOperation memory _swap, uint256 amount) internal returns (uint256 returnAmount) {
        bool success = true;
        address routerAddress = swapRouters[_swap.protocol];
        // If we have an ERC20 Token, we need to approve the contract that will execute the swap

        // We approve for the max amount once
        // This is similar to :
        // (https://github.com/AngleProtocol/angle-core/blob/53c9d93eb1adf4fda4be8bd5b2ea09f237a6b408/contracts/router/AngleRouter.sol#L1364)
        _approveIfNecessary(routerAddress, _swap.inToken, amount);

        if (_swap.protocol == SwapProtocol.UniswapV3) {
            // UniswapV3 swap can be done at any time
            (success, returnAmount) = _swapUniswapV3(_swap, amount);
        } else if (_swap.protocol == SwapProtocol.OneInch || _swap.protocol == SwapProtocol.ZeroX) {
            // OneInch and ZeroX swaps work in the same way
            (success, returnAmount) = _swapWithCalldata(_swap, amount);
        } else if (_swap.protocol == SwapProtocol.None) {
            // We don't do any swap here, hence an empty body
        } else {
            revert ProtocolNotSupported();
        }

        if (!success) revert TokenSwapFailed();
    }

    function _approveIfNecessary(address contractAddress, address token, uint256 amountMinimum) internal {
        if (token != nativeToken) {
            uint256 currentApproval = IERC20(token).allowance(address(this), contractAddress);
            if (currentApproval == 0) {
                IERC20(token).safeApprove(contractAddress, type(uint256).max);
            } else if (currentApproval < amountMinimum) {
                IERC20(token).safeIncreaseAllowance(contractAddress, type(uint256).max - currentApproval);
            }
        }
    }

    /// @dev We choose to not user OZ interface for gas optimisation purposes
    /// @dev This router doesn't need to be safe on token transfers as its storage nevers depends on transfer parameters
    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}