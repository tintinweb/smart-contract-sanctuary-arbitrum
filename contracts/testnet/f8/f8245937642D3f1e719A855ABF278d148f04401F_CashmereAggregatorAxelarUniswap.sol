// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "../libraries/ReentrancyGuard.sol";
import { ICashmereAggregatorAxelar } from "../interfaces/ICashmereAggregatorAxelar.sol";
import { IBridgeAxelar } from "../interfaces/IBridgeAxelar.sol";
import { ICrossRouter } from "../interfaces/ICrossRouter.sol";
import { IWrappedNativeToken } from "../interfaces/IWrappedNativeToken.sol";
import { IUniswapV2Router02 } from "../interfaces/IUniswapV2Router02.sol";
import { IAsset } from "../interfaces/IAsset.sol";

contract CashmereAggregatorAxelarUniswap is ICashmereAggregatorAxelar, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant CONTINUE_EXECUTOR_ROLE = keccak256("CONTINUE_EXECUTOR_ROLE");
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    ICrossRouter private _assetRouter;

    IBridgeAxelar private _bridge;

    IUniswapV2Router02 private _uniswap;

    bool private _initialized;

    IWrappedNativeToken private _wrappedNativeToken;

    /*//////////////////////////////////////////////////////////////
                                MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 swapId => SentSwap swaps) private _sentSwaps;

    mapping(uint16 chainId => mapping(bytes32 swapId => bool continued)) private _receivedSwaps;

    mapping(uint16 chainId => AggregatorInfo aggregatorInfo) private _aggregatorInfos;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewPendingSwap(bytes32 id);
    event SwapContinued(bytes32 indexed id, address to);
    event AggregatorInfosUpdated();

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error AlreadyInitialized();
    error InvalidLwsGws();
    error InsufficientValue();
    error InvalidSender();

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL WRITE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() { }

    function initialize(
        ICrossRouter assetRouter,
        IBridgeAxelar bridge,
        IUniswapV2Router02 uniswap,
        IWrappedNativeToken wrappedNativeToken,
        address admin
    )
        external
    {
        if (_initialized) revert AlreadyInitialized();
        _assetRouter = assetRouter;
        _bridge = bridge;
        _uniswap = uniswap;
        _wrappedNativeToken = wrappedNativeToken;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _initialized = true;
    }

    function startSwap(SwapParams memory params) external payable {
        // Verify base param's
        if (params.lwsPoolId == 0 || params.hgsPoolId == 0) revert InvalidLwsGws();

        uint256 value = msg.value;
        IERC20 lwsToken = IERC20(IAsset(_assetRouter.getPool(params.lwsPoolId).poolAddress).token());

        // src -> lws
        IERC20 srcToken = params.srcToken;
        if (address(params.srcToken) == NATIVE_TOKEN) {
            if (params.srcAmount > value) revert InsufficientValue();
            value -= params.srcAmount;
            _wrappedNativeToken.deposit{ value: params.srcAmount }();
            srcToken = IERC20(_wrappedNativeToken);
        } else {
            srcToken.safeTransferFrom(msg.sender, address(this), params.srcAmount);
        }

        uint256 returnAmount;
        if (srcToken != lwsToken /*&& params.router1Inch != address(0)*/ ) {
            uint256 srcBefore = srcToken.balanceOf(address(this)) - params.srcAmount;
            uint256 lwsBefore = lwsToken.balanceOf(address(this));

            _approve(srcToken, address(_uniswap), params.srcAmount);

            //            (bool success, ) = params.router1Inch.call{ value: 0 }(params.data);
            //            require(success, "!inSuccess");
            _uniswapSwap(srcToken, lwsToken, params.srcAmount);
            uint256 unspentAmount = srcToken.balanceOf(address(this)) - srcBefore;
            returnAmount = lwsToken.balanceOf(address(this)) - lwsBefore;
            if (unspentAmount > 0) {
                srcToken.safeTransfer(msg.sender, unspentAmount);
            }
        } else {
            returnAmount = params.srcAmount;
        }

        // lws -> hgs
        _approve(lwsToken, address(_assetRouter), returnAmount);
        bytes memory payload = abi.encodePacked(params.dstToken, msg.sender);
        bytes32 swapId = _assetRouter.swap{ value: value }(
            ICrossRouter.SwapParams({
                srcPoolId: params.lwsPoolId,
                dstPoolId: params.hgsPoolId,
                dstChainId: params.dstChain,
                amount: returnAmount,
                minAmount: params.minHgsAmount,
                refundAddress: payable(msg.sender),
                to: _aggregatorInfos[params.dstChain].srcAggregatorAddress,
                payload: payload
            })
        );

        // Store our pending swap
        _sentSwaps[swapId] = SentSwap({
            id: swapId,
            lwsToken: lwsToken,
            lwsPoolId: params.lwsPoolId,
            hgsPoolId: params.hgsPoolId,
            dstToken: params.dstToken,
            dstChainId: params.dstChain,
            receiver: msg.sender,
            minHgsAmount: params.minHgsAmount
        });

        emit NewPendingSwap(swapId);
    }

    function finishSwap(
        uint16 srcChainId,
        uint16 hgsPoolId,
        uint256 amount,
        bytes32 swapId,
        address receiver,
        IERC20 dstToken
    )
        external
        onlyRole(CONTINUE_EXECUTOR_ROLE)
    {
        require(!_receivedSwaps[srcChainId][swapId], "already continued");

        // hgs -> dst
        bool isDstNative = address(dstToken) == NATIVE_TOKEN;
        if (isDstNative) {
            dstToken = IERC20(_wrappedNativeToken);
        }

        IERC20 hgsToken = IERC20(IAsset(_assetRouter.getPool(hgsPoolId).poolAddress).token());
        uint256 returnAmount;
        if (hgsToken != dstToken /*&& params.router1Inch != address(0)*/ ) {
            uint256 hgsBefore = hgsToken.balanceOf(address(this)) - amount;
            uint256 dstBefore = dstToken.balanceOf(address(this));

            _approve(hgsToken, address(_uniswap), amount);
            //            (bool success, ) = params.router1Inch.call{ value: 0 }(params.data);
            //            require(success, "!inSuccess");
            _uniswapSwap(hgsToken, dstToken, amount);
            uint256 unspentAmount = hgsToken.balanceOf(address(this)) - hgsBefore;
            returnAmount = dstToken.balanceOf(address(this)) - dstBefore;
            if (unspentAmount > 0) {
                hgsToken.safeTransfer(receiver, unspentAmount);
            }
        } else {
            returnAmount = amount;
        }

        // If we got a return amount, send it
        if (returnAmount > 0) {
            if (isDstNative) {
                _wrappedNativeToken.withdraw(returnAmount);
                payable(receiver).transfer(returnAmount);
            } else {
                dstToken.safeTransfer(receiver, returnAmount);
            }
        }
        _receivedSwaps[srcChainId][swapId] = true;
        emit SwapContinued(swapId, receiver);
    }

    function withdrawTokens(IERC20 token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(msg.sender, amount);
    }

    function setAggregatorInfos(AggregatorInfo[] calldata infos) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < infos.length; i++) {
            _aggregatorInfos[infos[i].l0ChainId] = infos[i];
        }
        emit AggregatorInfosUpdated();
    }

    function updateAssetRouter(ICrossRouter assetRouter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _assetRouter = assetRouter;
    }

    function updateBridge(IBridgeAxelar bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _bridge = bridge;
    }

    receive() external payable {
        if (msg.sender != address(_wrappedNativeToken)) revert InvalidSender();
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _approve(IERC20 token, address operator, uint256 amount) internal {
        token.safeApprove(operator, 0);
        token.safeApprove(operator, amount);
    }

    function _uniswapSwap(IERC20 fromToken, IERC20 toToken, uint256 fromAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(fromToken);
        path[1] = address(toToken);
        _uniswap.swapExactTokensForTokens(fromAmount, 0, path, address(this), block.timestamp + 1000);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getSentSwaps(bytes32 swapId) external view returns (SentSwap memory) {
        return _sentSwaps[swapId];
    }

    function getSwapReceived(uint16 chainId, bytes32 swapId) external view returns (bool) {
        return _receivedSwaps[chainId][swapId];
    }

    function getAggregatorInfos(uint16 chainId) external view returns (AggregatorInfo memory) {
        return _aggregatorInfos[chainId];
    }

    function getAssetRouter() external view returns (ICrossRouter) {
        return _assetRouter;
    }

    function getBridge() external view returns (IBridgeAxelar) {
        return _bridge;
    }

    function getUniswap() external view returns (IUniswapV2Router02) {
        return _uniswap;
    }

    function getInitialized() external view returns (bool) {
        return _initialized;
    }

    function getWrappedNativeToken() external view returns (IWrappedNativeToken) {
        return _wrappedNativeToken;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAsset {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function release(address to, uint256 amount) external;
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAxelarBridgeCallback {
    function finishSwap(
        uint16 srcChainId,
        uint16 hgsPoolId,
        uint256 amount,
        bytes32 swapId,
        address receiver,
        IERC20 dstToken
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ILayerZeroReceiver } from "./ILayerZeroReceiver.sol";
import { ILayerZeroEndpoint } from "./ILayerZeroEndpoint.sol";
import { ILayerZeroUserApplicationConfig } from "./ILayerZeroUserApplicationConfig.sol";
import { ICrossRouter } from "./ICrossRouter.sol";
import { Shared } from "./../libraries/Shared.sol";

/**
 * @title IBridge
 * @notice Interface for the Bridge contract.
 */
interface IBridge is Shared, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    /*//////////////////////////////////////////////////////////////
                           Events And Errors
    //////////////////////////////////////////////////////////////*/
    event MessageDispatched(
        uint16 indexed chainId, MESSAGE_TYPE indexed messageType, address indexed refundAddress, bytes payload
    );

    event MessageFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SwapMessageReceived(ICrossRouter.SwapMessage message);
    event LiquidityMessageReceived(ICrossRouter.LiquidityMessage message);

    error InsuficientFee(uint256);
    error NotLayerZero();
    error InsufficientAccess();
    error BridgeMismatch();
    error SliceOverflow();
    error SliceBoundsError();
    error InvalidOp();
    error InvalidEndpoint();
    error InvalidRouter();

    /**
     * @notice This function returns the version of the Bridge contract.
     * @return The version of the Bridge contract.
     */
    function VERSION() external returns (uint16);

    /**
     * @notice This function receives a message from Layer Zero.
     * @param srcChainId ID of the source chain.
     * @param srcAddress Address of the source chain.
     * @param payload Payload of the message.
     */
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64, bytes calldata payload) external;

    /**
     * @notice This function returns the next nonce for a destination chain.
     * @param dstChain ID of the destination chain.
     * @return nextNonce Next nonce value.
     */
    function nextNonce(uint16 dstChain) external view returns (uint256);

    /**
     * @notice This function returns the received swap message for a specific source chain and ID.
     * @param srcChainId Source chain ID.
     * @param id Swap message ID.
     * @return swapMessage The received swap message.
     */
    function getReceivedSwaps(uint16 srcChainId, bytes32 id) external view returns (ICrossRouter.SwapMessage memory);

    /**
     * @notice This function returns the received liquidity message for a specific source chain and ID.
     * @param srcChain Source chain ID.
     * @param id Liquidity message ID.
     * @return liquidityMessage The received liquidity message.
     */
    function getReceivedLiquidity(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        returns (ICrossRouter.LiquidityMessage memory);

    /**
     * @notice This function dispatches a message to a specific chain using the Layer Zero endpoint.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param refundAddress Address to receive refunds (if any).
     * @param payload Payload of the message.
     */
    function dispatchMessage(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        address payable refundAddress,
        bytes memory payload
    )
        external
        payable;

    /**
     * @notice This function returns the fee for sending a message on-chain.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param payload Payload of the message.
     * @return estimatedFee Estimated fee for sending the message.
     * @return gasAmount Forwarded gas amount for the message.
     */
    function quoteLayerZeroFee(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        bytes memory payload
    )
        external
        view
        returns (uint256, uint256);

    /**
     * @notice This function returns the router contract.
     * @return router The router contract.
     */
    function getRouter() external view returns (ICrossRouter);

    /**
     * @notice This function returns the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @return bridgeAddress The bridge address.
     */
    function getBridgeLookup(uint16 chainId) external view returns (bytes memory);

    /**
     * @notice This function returns the forwarded gas amount for a specific chain and message type.
     * @param chainId ID of the chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @return gasAmount The forwarded gas amount.
     */
    function getGasLookup(uint16 chainId, MESSAGE_TYPE messageType) external view returns (uint256);

    /**
     * @notice This function returns the failed message for a specific chain, bridge address, and nonce.
     * @param chainId ID of the chain.
     * @param bridgeAddress Bridge address in bytes format.
     * @param nonce Nonce of the message.
     * @return payload The payload of the failed message.
     */
    function getFailedMessages(
        uint16 chainId,
        bytes memory bridgeAddress,
        uint64 nonce
    )
        external
        view
        returns (bytes32);

    /**
     * @notice This function sets the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @param bridgeAddress Address of the bridge contract on the specified chain.
     */
    function setBridge(uint16 chainId, bytes calldata bridgeAddress) external;

    /**
     * @notice This function sets the router contract address.
     * @param newRouter Address of the new router contract.
     */
    function setRouter(ICrossRouter newRouter) external;

    /**
     * @notice This function sets the forwarded gas amount for a specific chain and message type.
     * @param chainId ID of the chain.
     * @param functionType Type of the message (Swap or Liquidity).
     * @param gasAmount Forwarded gas amount.
     */
    function setForwardedGas(uint16 chainId, MESSAGE_TYPE functionType, uint256 gasAmount) external;

    /**
     * @notice This function forces the resumption of message receiving on Layer Zero.
     * @param srcChainId ID of the source chain.
     * @param srcAddress Address of the source chain.
     */
    function forceResumeReceive(uint16 srcChainId, bytes calldata srcAddress) external;

    /**
     * @notice This function sets the configuration for a specific version, chain, and config type.
     * @param version Version of the configuration.
     * @param chainId ID of the chain.
     * @param configType Type of the configuration.
     * @param config Configuration data.
     */
    function setConfig(uint16 version, uint16 chainId, uint256 configType, bytes calldata config) external;

    /**
     * @notice This function sets the send version for Layer Zero.
     * @param version Version to set.
     */
    function setSendVersion(uint16 version) external;

    /**
     * @notice This function sets the receive version for Layer Zero.
     * @param version Version to set.
     */
    function setReceiveVersion(uint16 version) external;
    /**
     * @dev Returns the Layer Zero endpoint contract.
     * @notice This function returns the Layer Zero endpoint contract.
     * @return layerZeroEndpoint The Layer Zero endpoint contract.
     */
    function getLayerZeroEndpoint() external view returns (ILayerZeroEndpoint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ICrossRouter } from "./ICrossRouter.sol";
import { Shared } from "./../libraries/Shared.sol";

/**
 * @title IBridgeAxelar
 * @notice Interface for the Bridge contract.
 */
interface IBridgeAxelar is Shared {
    /*//////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    struct SwapPayloadData {
        IERC20 dstToken;
        address receiver;
    }

    /*//////////////////////////////////////////////////////////////
                           Events And Errors
    //////////////////////////////////////////////////////////////*/
    event MessageDispatched(
        uint16 indexed chainId, MESSAGE_TYPE indexed messageType, address indexed refundAddress, bytes payload
    );

    event MessageFailed(uint16 srcChainId, string srcAddress, bytes32 messageId, bytes payload);
    event SwapMessageReceived(ICrossRouter.SwapMessage message, bytes32 commandId);
    event LiquidityMessageReceived(ICrossRouter.LiquidityMessage message, bytes32 commandId);

    error InsuficientFee(uint256);
    error NotLayerZero();
    error InsufficientAccess();
    error BridgeMismatch();
    error SliceOverflow();
    error SliceBoundsError();
    error InvalidOp();
    error InvalidEndpoint();
    error InvalidRouter();
    error InvalidGasReceiver();
    error InvalidGateway();

    /**
     * @notice This function returns the version of the Bridge contract.
     * @return The version of the Bridge contract.
     */
    function VERSION() external returns (uint16);

    /**
     * @notice This function returns the received swap message for a specific source chain and ID.
     * @param srcChainId Source chain ID.
     * @param id Swap message ID.
     * @return swapMessage The received swap message.
     */
    function getReceivedSwaps(uint16 srcChainId, bytes32 id) external view returns (ICrossRouter.SwapMessage memory);

    /**
     * @notice This function returns the received liquidity message for a specific source chain and ID.
     * @param srcChain Source chain ID.
     * @param id Liquidity message ID.
     * @return liquidityMessage The received liquidity message.
     */
    function getReceivedLiquidity(
        uint16 srcChain,
        bytes32 id
    )
        external
        view
        returns (ICrossRouter.LiquidityMessage memory);

    /**
     * @notice This function dispatches a message to a specific chain using the Layer Zero endpoint.
     * @param chainId ID of the target chain.
     * @param messageType Type of the message (Swap or Liquidity).
     * @param refundAddress Address to receive refunds (if any).
     * @param payload Payload of the message.
     */
    function dispatchMessage(
        uint16 chainId,
        MESSAGE_TYPE messageType,
        address payable refundAddress,
        bytes memory payload
    )
        external
        payable;

    /**
     * @notice This function returns the router contract.
     * @return router The router contract.
     */
    function getRouter() external view returns (ICrossRouter);

    /**
     * @notice This function returns the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @return bridgeAddress The bridge address.
     */
    function getBridgeLookup(uint16 chainId) external view returns (string memory);

    /**
     * @notice This function returns the failed message for a specific chain, bridge address, and nonce.
     * @param commandId commandId of the message.
     * @return payloadHash The payload hash of the failed message.
     */
    function getFailedMessages(bytes32 commandId) external view returns (bytes32);

    /**
     * @notice This function sets the bridge address for a specific chain.
     * @param chainId ID of the chain.
     * @param bridgeAddress Address of the bridge contract on the specified chain.
     */
    function setBridge(uint16 chainId, string calldata bridgeAddress) external;

    /**
     * @notice This function sets the router contract address.
     * @param newRouter Address of the new router contract.
     */
    function setRouter(ICrossRouter newRouter) external;

    function addNativeGas(bytes32 txHash, uint256 logIndex, address refundAddress) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBridgeAxelar } from "../interfaces/IBridgeAxelar.sol";
import { ICrossRouter } from "../interfaces/ICrossRouter.sol";
import { IWrappedNativeToken } from "../interfaces/IWrappedNativeToken.sol";
import { IUniswapV2Router02 } from "../interfaces/IUniswapV2Router02.sol";
import "./IAxelarBridgeCallback.sol";

interface ICashmereAggregatorAxelar is IAxelarBridgeCallback {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct SentSwap {
        // First storage slot
        bytes32 id;
        // Second storage slot
        IERC20 lwsToken; // 20 bytes -> uint160
        uint16 lwsPoolId; // 4 bytes -> uint16
        uint16 hgsPoolId; // 4 bytes -> uint16 -> Remain 4 bytes free
        // Third storage slot
        IERC20 dstToken; // 20 bytes -> uint160
        uint16 dstChainId; // 4 bytes -> uint16 -> Remain 8 bytes free
        // Fourth storage slot
        address receiver; // 20 bytes -> uint160 -> Remain 10 bytes free
        // Fifth storage slot
        uint256 minHgsAmount;
    }

    struct SwapParams {
        IERC20 srcToken;
        uint256 srcAmount;
        address router1Inch;
        bytes data;
        uint16 lwsPoolId;
        uint16 hgsPoolId;
        IERC20 dstToken;
        uint16 dstChain;
        uint256 minHgsAmount;
    }

    struct ContinueSwapParams {
        uint16 srcChainId;
        bytes32 id;
        address router1Inch;
        bytes data;
    }

    struct AggregatorInfo {
        address srcAggregatorAddress;
        uint16 l0ChainId;
        uint256 chainId;
    }

    function initialize(
        ICrossRouter assetRouter,
        IBridgeAxelar bridge,
        IUniswapV2Router02 uniswap,
        IWrappedNativeToken wrappedNativeToken,
        address admin
    )
        external;

    function startSwap(SwapParams memory params) external payable;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function setAggregatorInfos(AggregatorInfo[] calldata infos) external;

    function updateAssetRouter(ICrossRouter assetRouter) external;

    function updateBridge(IBridgeAxelar bridge) external;

    function getSentSwaps(bytes32 swapId) external view returns (SentSwap memory);

    function getSwapReceived(uint16 chainId, bytes32 swapId) external view returns (bool);

    function getAggregatorInfos(uint16 chainId) external view returns (AggregatorInfo memory);

    function getAssetRouter() external view returns (ICrossRouter);

    function getBridge() external view returns (IBridgeAxelar);

    function getUniswap() external view returns (IUniswapV2Router02);

    function getInitialized() external view returns (bool);

    function getWrappedNativeToken() external view returns (IWrappedNativeToken);

    function finishSwap(
        uint16 srcChainId,
        uint16 hgsPoolId,
        uint256 amount,
        bytes32 swapId,
        address receiver,
        IERC20 dstToken
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Shared } from "../libraries/Shared.sol";
import { IBridge } from "./IBridge.sol";
import { ReentrancyGuard } from "../libraries/ReentrancyGuard.sol";

import { IFeeHandler } from "./IFeeHandler.sol";
import { ICrossRouter } from "./ICrossRouter.sol";
import { IAsset } from "./IAsset.sol";
import { IFeeCollectorV2 } from "./IFeeCollectorV2.sol";

interface ICrossRouter is Shared {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ChainPath {
        // Storage slot one
        bool active; // Mask: 0x0f
        uint16 srcPoolId; // Mask: 0xffff
        uint16 dstChainId; // Mask: 0xffff
        uint16 dstPoolId; // Mask: 0xffff
        uint16 weight; // Mask: 0xffff
        address poolAddress; // Mask: 0xffffffffffffffffffff Equivalent to uint160
        // Second storage slot
        uint256 bandwidth; // local bandwidth
        uint256 actualBandwidth; // local bandwidth
        uint256 kbp; // kbp = Known Bandwidth Proof dst bandwidth
        uint256 actualKbp; // kbp = Known Bandwidth Proof dst bandwidth
        uint256 vouchers;
        uint256 optimalDstBandwidth; // optimal dst bandwidth
    }

    struct SwapParams {
        uint16 srcPoolId; // Mask: 0xffff
        uint16 dstPoolId; // Mask: 0xffff
        uint16 dstChainId; // Mask: 0xffff  // Remain 208 bits
        address to;
        uint256 amount;
        uint256 minAmount;
        address payable refundAddress;
        bytes payload;
    }

    struct VoucherObject {
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bool swap;
    }

    struct PoolObject {
        uint16 poolId;
        address poolAddress;
        uint256 totalWeight;
        uint256 totalLiquidity;
        uint256 undistributedVouchers;
    }

    struct ChainData {
        uint16 srcPoolId;
        uint16 srcChainId;
        uint16 dstPoolId;
        uint16 dstChainId;
    }

    struct SwapMessage {
        uint16 srcChainId;
        uint16 srcPoolId;
        uint16 dstPoolId;
        address receiver;
        uint256 amount;
        uint256 fee;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bytes32 id;
        bytes payload;
    }

    struct ReceiveSwapMessage {
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint16 srcChainId;
        address receiver;
        uint256 amount;
        uint256 fee;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
    }

    struct LiquidityMessage {
        uint16 srcPoolId;
        uint16 dstPoolId;
        uint256 vouchers;
        uint256 optimalDstBandwidth;
        bytes32 id;
    }

    /**
     * @notice Swaps crosschain assets
     * @dev Cashmere is leveraging fragmented liquidity pools to crossswap assets. The slippage takes into account the
     * src bandwidth and dst bandwidth to calculate how many assets it should send. Fees will be calculated on src but
     * taken out of the dst chain.
     * @param swapParams The swap parameters
     *                       struct SwapParams {
     *                         uint16 srcPoolId;                   <= source pool id
     *                         uint16 dstPoolId;                   <= destination pool id
     *                         uint16 dstChainId;                  <= destination chain
     *                         address to;                         <= where to release the liquidity on dst
     *                         uint256 amount;                     <= the amount preferred for swap
     *                         uint256 minAmount;                  <= the minimum amount accepted for swap
     *                         address payable refundAddress;      <= refund cross-swap fee
     *                         bytes payload;                      <= payload to send to the destination chain
     *                     }
     * @return swapId The swap id
     */
    function swap(SwapParams memory swapParams) external payable returns (bytes32 swapId);

    /**
     * @notice Deposits liquidity to a pool
     * @dev The amount deposited will be wrapped to the pool asset and the user will receive the same amount of assets -
     * fees
     * @param to The address to receive the assets
     * @param poolId The pool id
     * @param amount The amount to deposit
     */
    function deposit(address to, uint16 poolId, uint256 amount) external;

    /**
     * @notice Redeems liquidity from a pool
     * @dev The amount redeemed will be unwrapped from the pool asset
     * @param to The address to receive the assets
     * @param poolId The pool id
     * @param amount The amount to redeem
     */
    function redeemLocal(address to, uint16 poolId, uint256 amount) external;

    /**
     * @notice Syncs a pool with the current liquidity distribution
     * @dev We have this function in case it needs to be triggered manually
     * @param poolId The pool id
     */
    function sync(uint16 poolId) external;

    /**
     * @notice Sends vouchers to the destination chain
     * @dev This function is called by the bridge contract when a voucher message is received
     * @param srcPoolId The source pool id
     * @param dstChainId The destination chain id
     * @param dstPoolId The destination chain id
     * @param refundAddress The refund address for cross-swap fee
     */
    function sendVouchers(
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        address payable refundAddress
    )
        external
        payable
        returns (bytes32 messageId);

    /**
     * @notice Called by the bridge when a swap message is received
     * @param srcPoolId The pool id of the source pool
     * @param dstPoolId The pool id of the destination pool
     * @param srcChainId The chain id of the source chain
     * @param to The address to receive the assets
     * @param amount The amount that needs to be received
     * @param fee The fee that it will be collected
     * @param vouchers The amount of vouchers that were sent from src and distributed to dst
     * @param optimalDstBandwidth The optimal bandwidth that should be received so we can sync it
     */
    function swapRemote(
        uint16 srcPoolId,
        uint16 dstPoolId,
        uint16 srcChainId,
        address to,
        uint256 amount,
        uint256 fee,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        uint256 srcActualKbp
    )
        external;

    /**
     * @notice Called by the bridge when vouchers are received
     * @param srcChainId The chain id of the source chain
     * @param srcPoolId The pool id of the source pool
     * @param dstPoolId The pool id of the destination pool
     * @param vouchers The amount of vouchers that were sent from src and distributed to dst
     * @param optimalDstBandwidth The optimal bandwidth that should be received so we can sync it
     * @param isSwap Whether or not the liquidity comes from a swap or not
     */
    function receiveVouchers(
        uint16 srcChainId,
        uint16 srcPoolId,
        uint16 dstPoolId,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        bool isSwap,
        uint256 srcActualKbp
    )
        external;

    /**
     * @notice Quotes a possible cross swap
     * @dev Check swap method for swapParams explanation
     * @param swapParams The swap parameters
     * @return amount The amount of tokens that would be received
     * @return fee The fee that would be paid
     */
    function quoteSwap(SwapParams calldata swapParams) external view returns (uint256 amount, uint256 fee);

    /**
     * @notice returns the effective path to move funds from A to B
     * @param dstChainId the destination chain id
     * @param amountToSimulate the amount to simulate to get the right path
     * @return effectivePath the effective path to move funds from A to B which represents poolId A and poolId B
     */
    function getEffectivePath(
        uint16 dstChainId,
        uint256 amountToSimulate
    )
        external
        view
        returns (uint16[2] memory effectivePath);

    function getChainPathPublic(
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId
    )
        external
        view
        returns (ChainPath memory path);

    function getPool(uint16 _poolId) external view returns (PoolObject memory);

    function poolIdsPerChain(uint16 chainId) external view returns (uint16[] memory);

    function getChainPathsLength(uint16 poolId) external view returns (uint256);

    function getPaths(uint16 _poolId) external view returns (ChainPath[] memory);

    function chainPathIndexLookup(bytes32 key) external view returns (uint256);

    function getFeeHandler() external view returns (IFeeHandler);

    function getFeeCollector() external view returns (IFeeCollectorV2);

    function getBridge() external view returns (IBridge);

    function getChainId() external view returns (uint16);

    function getBridgeVersion() external view returns (uint16);

    function getSyncDeviation() external view returns (uint256);

    function getNonce(uint16 chainId) external view returns (uint64);

    /*//////////////////////////////////////////////////////////////
                                EVENTS AND ERRORS
    //////////////////////////////////////////////////////////////*/
    event CrossChainSwapInitiated(
        address indexed sender,
        bytes32 id,
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        uint256 expectedAmount,
        uint256 actualAmount,
        uint256 fee,
        uint256 vouchers,
        uint256 optimalDstBandwidth,
        bytes payload
    );
    event CrossChainSwapPerformed(
        uint16 srcPoolId, uint16 dstPoolId, uint16 srcChainId, address to, uint256 amount, uint256 fee
    );
    event CrossChainLiquidityInitiated(
        address indexed sender,
        bytes32 id,
        uint16 srcPoolId,
        uint16 dstChainId,
        uint16 dstPoolId,
        uint256 vouchers,
        uint256 optimalDstBandwidth
    );
    event CrossChainLiquidityPerformed(LiquidityMessage message);
    event SendVouchers(uint16 dstChainId, uint16 dstPoolId, uint256 vouchers, uint256 optimalDstBandwidth);
    event VouchersReceived(uint16 chainId, uint16 srcPoolId, uint256 amount, uint256 optimalDstBandwidth);
    event SwapRemote(address to, uint256 amount, uint256 fee);
    event ChainPathUpdate(uint16 srcPoolId, uint16 dstChainId, uint16 dstPoolId, uint256 weight);
    event ChainActivated(uint16 srcPoolId, uint16 dstChainId, uint16 dstPoolId);
    event FeeHandlerUpdated(address oldFeeHandler, address newFeeHandler);
    event SyncDeviationUpdated(uint256 oldDeviation, uint256 newDeviation);
    event FeeCollected(uint256 fee);
    event AssetDeposited(address indexed to, uint16 poolId, uint256 amount);
    event AssetRedeemed(address indexed from, uint16 poolId, uint256 amount);
    event PoolSynced(uint16 poolId, uint256 distributedVouchers);
    event BridgeUpdated(IBridge oldBridge, IBridge newBridge);

    error InactiveChainPath();
    error ActiveChainPath();
    error UnknownChainPath();
    error InsufficientLiquidity();
    error SlippageTooHigh();
    error SrcBandwidthTooLow();
    error DstBandwidthTooLow();
    error ChainPathExists();
    error FeeLibraryZero();
    error SyncDeviationTooHigh();
    error NotEnoughLiquidity();
    error AmountZero();
    error UnknownPool();
    error MathOverflow();
    error InsufficientSrcLiquidity();
    error InsufficientDstLiquidity();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IAsset } from "./IAsset.sol";

interface IFeeCollectorV2 {
    function collectFees(IAsset asset_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ICrossRouter } from "./ICrossRouter.sol";

interface IFeeHandler {
    /**
     * @notice Apply slippage algorithm to an amount using bandwidth and optimal bandwidth of both src and dst
     * @param amount Amount we apply the slippage for
     * @param bandwidthSrc Bandwidth of the source pool
     * @param optimalBandwithDst Optimal bandwidth of the destination pool
     * @param bandwithDst Bandwidth of the destination pool
     * @param optimalBandwithSrc Optimal bandwidth of the source pool
     * @return actualAmount The amount after applying slippage
     * @return fee The fee amount
     */
    function applySlippage(
        uint256 amount,
        uint256 bandwidthSrc,
        uint256 optimalBandwithDst,
        uint256 bandwithDst,
        uint256 optimalBandwithSrc
    )
        external
        view
        returns (uint256 actualAmount, uint256 fee);

    /**
     * @notice Compute the compensation ratio for a given bandwidth and optimal bandwidth
     * @param bandwidth Bandwidth of a pool
     * @param optimalBandwidth Optimal bandwidth of a pool
     * @return compensationRatio The compensation ratio
     */
    function getCompensatioRatio(
        uint256 bandwidth,
        uint256 optimalBandwidth
    )
        external
        pure
        returns (uint256 compensationRatio);

    function swapFee() external view returns (uint256);

    function mintFee() external view returns (uint256);

    function burnFee() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the
    // additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. ie: pay for a specified destination gasAmount, or
    // receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    )
        external
        payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    )
        external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    )
        external
        view
        returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    )
        external
        view
        returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    )
        external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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
    )
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountToken, uint256 amountETH);

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
    )
        external
        returns (uint256 amountA, uint256 amountB);

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
    )
        external
        returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    )
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    )
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    )
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountETH);

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
    )
        external
        returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedNativeToken is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Reviewed reetrancy guard for better gas optimisation
 * @author @KONFeature
 * Based from solidity ReetrancyGuard :
 * https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/security/ReentrancyGuard.sol
 */
abstract contract ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Not entered function status
    uint256 private constant _NOT_ENTERED = 1;
    /// @dev Entered function status
    uint256 private constant _ENTERED = 2;

    /* -------------------------------------------------------------------------- */
    /*                                   Error's                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Error if function is reentrant
    error ReetrantCall();

    /// @dev 'bytes4(keccak256("ReetrantCall()"))'
    uint256 private constant _REETRANT_CALL_SELECTOR = 0x920856a0;

    /* -------------------------------------------------------------------------- */
    /*                                   Storage                                  */
    /* -------------------------------------------------------------------------- */

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
        assembly ("memory-safe") {
            // Check if not re entrant
            if eq(sload(_status.slot), _ENTERED) {
                mstore(0x00, _REETRANT_CALL_SELECTOR)
                revert(0x1c, 0x04)
            }

            // Any calls to nonReentrant after this point will fail
            sstore(_status.slot, _ENTERED)
        }
        _;
        // Reset the reentrant slot
        assembly ("memory-safe") {
            sstore(_status.slot, _NOT_ENTERED)
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           Internal view function                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface Shared {
    enum MESSAGE_TYPE {
        NONE,
        SWAP,
        ADD_LIQUIDITY
    }
}