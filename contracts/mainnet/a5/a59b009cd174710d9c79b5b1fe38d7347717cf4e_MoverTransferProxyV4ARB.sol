/**
 *Submitted for verification at Arbiscan on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////////////////////////////////////////////
//     __/|      
//  __////  /|   This smart contract is part of Mover infrastructure
// |// //_///    https://viamover.com
//    |_/ //     [email protected]
//       |/
///////////////////////////////////////////////////////////////////////////

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// Interface to represent asset pool interactions
interface IAssetPoolV2 {
    function getBaseAsset() external view returns(address);

    // functions callable by HolyHand transfer proxy
    function depositOnBehalf(address beneficiary, uint256 amount) external;
    function depositOnBehalfDirect(address beneficiary, uint256 amount) external;
    function withdraw(address beneficiary, uint256 amount) external;

    // functions callable by HolyValor investment proxies
    // pool would transfer funds to HolyValor (returns actual amount, could be less than asked)
    function borrowToInvest(uint256 amount) external returns(uint256);
    // return invested body portion from HolyValor (pool will claim base assets from caller Valor)
    function returnInvested(uint256 amountCapitalBody) external;

    // functions callable by HolyRedeemer yield distributor
    function harvestYield(uint256 amount) external; // pool would transfer amount tokens from caller as it's profits
}


// Interface to represent middleware contract for swapping tokens
interface IExchangeProxy {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: HolyWing grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) external returns(uint256);
}


// Interface to represent middleware contract for swapping tokens
interface IExchangeProxyV2 {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: ExchangeProxy grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) payable external returns(uint256);

    function executeSwapDirect(address beneficiary, address tokenFrom, address tokenTo, uint256 amount, uint256 fee, bytes calldata data) payable external returns(uint256);
}


// Interface to represent Mover Transfer proxy
interface ITransferProxyV2 {
    function depositToPoolFromRelay(address _beneficiary, address _poolAddress, address _token, uint256 _amount) external;
}


abstract contract SafeAllowanceResetUpgradeable {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // this function exists due to OpenZeppelin quirks in safe allowance-changing methods
  // we don't want to set allowance by small chunks as it would cost more gas for users
  // and we don't want to set it to zero and then back to value (this makes no sense security-wise in single tx)
  // from the other side, using it through safeIncreaseAllowance could revery due to SafeMath overflow
  // Therefore, we calculate what amount we can increase allowance on to refill it to max uint256 value
  function resetAllowanceIfNeeded(IERC20Upgradeable _token, address _spender, uint256 _amount) internal {
    uint256 allowance = _token.allowance(address(this), _spender);
    if (allowance < _amount) {
      uint256 newAllowance = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      IERC20Upgradeable(_token).safeIncreaseAllowance(address(_spender), newAllowance.sub(allowance));
    }
  }
}


/*
    MoverTransferProxy is a transfer proxy contract for ERC20 and ETH transfers through Mover infrastructure
    (deposits/withdraws to/from savings products, swaps, etc.)
    - extract fees;
    - call token conversion if needed;
    - deposit/withdraw tokens into holder contracts;
    - non-custodial, not holding any funds;
    - fees are accumulated on this contract's balance (if fees are enabled);

    This contract is a single address that user grants allowance to on any ERC20 token for interacting with HH services.
    This contract could be upgraded in the future to provide subsidized transactions using bonuses from treasury.

    TODO: if token supports permit, provide ability to execute without separate approval call

    version additions:
    - direct deposits to pool (if no fees or conversions);
    - when swapping tokens direct return converted asset to sender (if no fees);
    - ETH support (non-wrapped ETH conversion for deposits and swaps);
    - emergencyTransfer can reclaim ETH
    - support for subsidized transaction execution;
    - bridged transactions support from relay;
    - strategy list fixes for redeem;
    - allowing to decrease of assets value (e.g. for stablecoin swap slippage);
*/
contract MoverTransferProxyV4ARB is AccessControlUpgradeable, SafeAllowanceResetUpgradeable, ITransferProxyV2 {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    uint256 private constant ALLOWANCE_SIZE =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    // token address for non-wrapped eth
    address private constant ETH_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to all deposits
    uint256 public depositFee;
    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to exchange operations with exchage proxy
    uint256 public exchangeFee;
    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to withdraw operations
    uint256 public withdrawFee;

    // exchange proxy/middleware
    IExchangeProxy private exchangeProxyContract;

    // redeemer yield distributor
    // NOTE: to keep overhead for users minimal, fees are not transferred
    // immediately, but left on this contract balance, yieldDistributor can reclaim them
    address private yieldDistributorAddress;

    event TokenSwap(
        address indexed tokenFrom,
        address indexed tokenTo,
        address sender,
        uint256 amountFrom,
        uint256 expectedMinimumReceived,
        uint256 amountReceived
    );

    event FeeChanged(string indexed name, uint256 value);

    event EmergencyTransfer(
        address indexed token,
        address indexed destination,
        uint256 amount
    );

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        depositFee = 0;
        exchangeFee = 0;
        withdrawFee = 0;
    }

    function setExchangeProxy(address _exchangeProxyContract) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        exchangeProxyContract = IExchangeProxy(_exchangeProxyContract);
    }

    function setYieldDistributor(
        address _tokenAddress,
        address _distributorAddress
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        yieldDistributorAddress = _distributorAddress;
        // only yield to be redistributed should be present on this contract in baseAsset (or other tokens if swap fees)
        // so no access to lp tokens for the funds invested
        resetAllowanceIfNeeded(
            IERC20Upgradeable(_tokenAddress),
            _distributorAddress,
            ALLOWANCE_SIZE
        );
    }

    // if the pool baseToken matches the token deposited, then no conversion is performed
    // and _expectedMininmumReceived/convertData should be zero/empty
    function depositToPool(
        address _poolAddress,
        address _token,
        uint256 _amount,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) public payable {
        depositToPoolOnBehalf(msg.sender, msg.sender, _poolAddress, _token, _amount, _expectedMinimumReceived, _convertData);
    }

    // relay contract address must have trusted executor privileges
    function depositToPoolFromRelay(
        address _beneficiary,
        address _poolAddress,
        address _token,
        uint256 _amount
    ) override public {
        depositToPoolOnBehalf(_beneficiary, msg.sender, _poolAddress, _token, _amount, 0, "");
    }

    function depositToPoolOnBehalf(
        address _beneficiary,
        address _fundSource,
        address _poolAddress,
        address _token,
        uint256 _amount,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) internal {
        IAssetPoolV2 assetPool = IAssetPoolV2(_poolAddress);
        IERC20Upgradeable poolToken = IERC20Upgradeable(assetPool.getBaseAsset());

        if (address(poolToken) == _token) {
            // no conversion is needed, allowance and balance checks performed in ERC20 token
            // and not here to not waste any gas fees

            if (depositFee == 0) {
                // use depositOnBehalfDirect function only for this flow to save gas as much as possible
                // (we have approval for this contract, so it can transfer funds to pool directly if
                // deposit fees are zero (otherwise we go with standard processing flow)

                // transfer directly to pool
                IERC20Upgradeable(_token).safeTransferFrom(
                    _fundSource,
                    _poolAddress,
                    _amount
                );

                // call pool function to process deposit (without transfer)
                assetPool.depositOnBehalfDirect(_beneficiary, _amount);
                return;
            }

            IERC20Upgradeable(_token).safeTransferFrom(_fundSource, address(this), _amount);

            // assetPool must have sufficient allowance (one-time for pool/token pair)
            resetAllowanceIfNeeded(poolToken, _poolAddress, _amount);

            // process deposit fees and deposit remainder
            uint256 feeAmount = _amount.mul(depositFee).div(1e18);
            assetPool.depositOnBehalf(_beneficiary, _amount.sub(feeAmount));
            return;
        }

        // conversion is required, perform swap through exchangeProxy
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20Upgradeable(_token).safeTransferFrom(
                _fundSource,
                address(exchangeProxyContract),
                _amount
            );
        }

        if (depositFee > 0) {
            // process exchange/deposit fees and route through transfer proxy
            uint256 amountReceived =
                IExchangeProxyV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                    address(this),
                    _token,
                    address(poolToken),
                    _amount,
                    exchangeFee,
                    _convertData
                );
            require(
                amountReceived >= _expectedMinimumReceived,
                "minimum swap amount not met"
            );
            uint256 feeAmount = amountReceived.mul(depositFee).div(1e18);
            amountReceived = amountReceived.sub(feeAmount);

            // exchange proxy must have sufficient allowance (one-time for pool/token pair)
            resetAllowanceIfNeeded(poolToken, _poolAddress, _amount);

            // perform actual deposit call
            assetPool.depositOnBehalf(_beneficiary, amountReceived);
        } else {
            // swap directly to asset pool address and execute direct deposit call
            uint256 amountReceived =
                IExchangeProxyV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                    _poolAddress,
                    _token,
                    address(poolToken),
                    _amount,
                    exchangeFee,
                    _convertData
                );
            require(
                amountReceived >= _expectedMinimumReceived,
                "minimum swap amount not met"
            );
            assetPool.depositOnBehalfDirect(_beneficiary, amountReceived);
        }
    }

    function withdrawFromPool(address _poolAddress, uint256 _amount) public {
        withdrawFromPoolOnBehalf(msg.sender, _poolAddress, _amount);
    }

    function withdrawFromPoolOnBehalf(address _beneficiary, address _poolAddress, uint256 _amount) internal {
        IAssetPoolV2 assetPool = IAssetPoolV2(_poolAddress);
        IERC20Upgradeable poolToken = IERC20Upgradeable(assetPool.getBaseAsset());
        uint256 amountBefore = poolToken.balanceOf(address(this));
        assetPool.withdraw(_beneficiary, _amount);
        uint256 withdrawnAmount =
            poolToken.balanceOf(address(this)).sub(amountBefore);

        // if amount is less than expected, transfer anyway what was actually received
        if (withdrawFee > 0) {
            // process withdraw fees
            uint256 feeAmount = withdrawnAmount.mul(withdrawFee).div(1e18);
            poolToken.safeTransfer(_beneficiary, withdrawnAmount.sub(feeAmount));
        } else {
            poolToken.safeTransfer(_beneficiary, withdrawnAmount);
        }
    }

    function setDepositFee(uint256 _depositFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        depositFee = _depositFee;
        emit FeeChanged("deposit", _depositFee);
    }

    function setExchangeFee(uint256 _exchangeFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        exchangeFee = _exchangeFee;
        emit FeeChanged("exchange", _exchangeFee);
    }

    function setWithdrawFee(uint256 _withdrawFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        withdrawFee = _withdrawFee;
        emit FeeChanged("withdraw", _withdrawFee);
    }

    function setTransferFee(uint256 _transferFee) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        transferFee = _transferFee;
        emit FeeChanged("transfer", _transferFee);
    }

    // token swap function (could be with fees but also can be subsidized later)
    // perform conversion through exchangeProxy
        function executeSwap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) public payable {
        executeSwapOnBehalf(msg.sender, _tokenFrom, _tokenTo, _amountFrom, _expectedMinimumReceived, _convertData);
    }

    function executeSwapOnBehalf(
        address _beneficiary,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _expectedMinimumReceived,
        bytes memory _convertData
    ) internal {
        require(_tokenFrom != _tokenTo, "same tokens provided");

        // swap with direct transfer to exchange proxy and it would transfer swapped token (or ETH) back to msg.sender
        if (_tokenFrom != ETH_TOKEN_ADDRESS) {
            IERC20Upgradeable(_tokenFrom).safeTransferFrom(
                _beneficiary,
                address(exchangeProxyContract),
                _amountFrom
            );
        }
        uint256 amountReceived =
            IExchangeProxyV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                _beneficiary,
                _tokenFrom,
                _tokenTo,
                _amountFrom,
                exchangeFee,
                _convertData
            );
        require(
            amountReceived >= _expectedMinimumReceived,
            "minimum swap amount not met"
        );
    }

    // payable fallback to receive ETH when swapping to raw ETH
    receive() external payable {}

    // this function is similar to emergencyTransfer, but relates to yield distribution
    // fees are not transferred immediately to save gas costs for user operations
    // so they accumulate on this contract address and can be claimed by redeemer
    // when appropriate. Anyway, no user funds should appear on this contract, it
    // only performs transfers, so such function has great power, but should be safe
    // It does not include approval, so may be used by redeemer to get fees from swaps
    // in different small token amounts
    function claimFees(address _token, uint256 _amount) public {
        require(
            msg.sender == yieldDistributorAddress,
            "yield distributor only"
        );
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
        } else {
            payable(msg.sender).sendValue(_amount);
        }
    }

    // all contracts that do not hold funds have this emergency function if someone occasionally
    // transfers ERC20 tokens directly to this contract
    // callable only by owner
    function emergencyTransfer(
        address _token,
        address _destination,
        uint256 _amount
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        if (_token != ETH_TOKEN_ADDRESS) {
            IERC20Upgradeable(_token).safeTransfer(_destination, _amount);
        } else {
            payable(_destination).sendValue(_amount);
        }
        emit EmergencyTransfer(_token, _destination, _amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    // SUBSIDIZED TRANSACTIONS
    ///////////////////////////////////////////////////////////////////////////
    // these should be callable only by trusted backend wallet
    // so that only signed by account and validated actions get executed and proper bonus amount
    // if spending bonus does not revert, account has enough bonus tokens
    // this contract must have EXECUTOR_ROLE set in Smart Treasury contract to call this

    bytes32 public constant TRUSTED_EXECUTION_ROLE = keccak256("TRUSTED_EXECUTION");  // trusted execution wallets

    // if greater than zero, this is a fractional amount (1e18 = 1.0) fee applied to transfer operations (that could also be subsidized)
    uint256 public transferFee;

    // subsidized sending of ERC20 token to another address
    function executeSendOnBehalf(address _beneficiary, address _token, address _destination, uint256 _amount, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        // perform transfer, assuming this contract has allowance
        if (transferFee == 0) {
            IERC20Upgradeable(_token).safeTransferFrom(_beneficiary, _destination, _amount);
        } else {
            uint256 feeAmount = _amount.mul(transferFee).div(1e18);
            IERC20Upgradeable(_token).safeTransferFrom(_beneficiary, address(this), _amount);
            IERC20Upgradeable(_token).safeTransfer(_destination, _amount.sub(feeAmount));
        }
    }

    // subsidized deposit of assets to pool
    function executeDepositOnBehalf(address _beneficiary, address _token, address _pool, uint256 _amount, uint256 _expectedMinimumReceived, bytes memory _convertData, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        // perform deposit, assuming this contract has allowance
        // TODO: check deposit on behalf with raw Eth! it's not supported but that it reverts;
        // TODO: check if swap would be executed properly;
        depositToPoolOnBehalf(_beneficiary, _beneficiary, _pool, _token, _amount, _expectedMinimumReceived, _convertData);
    }

    // subsidized withdraw of assets from pool
    function executeWithdrawOnBehalf(address _beneficiary, address _pool, uint256 _amount, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        withdrawFromPoolOnBehalf(_beneficiary, _pool, _amount);
    }
    
    // subsidized swap of ERC20 assets (also possible swap to raw Eth)
    function executeSwapOnBehalf(address _beneficiary, address _tokenFrom, address _tokenTo, uint256 _amountFrom, uint256 _expectedMinimumReceived, bytes memory _convertData, uint256 _bonus) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        // TODO: check deposit on behalf with raw Eth! it's not supported but that it reverts;
        executeSwapOnBehalf(_beneficiary, _tokenFrom, _tokenTo, _amountFrom, _expectedMinimumReceived, _convertData);
    }

    ///////////////////////////////////////////////////////////////////////////
    // BRIDGING TRANSACTIONS (AND SAVINGS+ BRIDGED WITHDRAW)
    ///////////////////////////////////////////////////////////////////////////
    event BridgeTx(address indexed beneficiary, address token, uint256 amount, address target, address relayTarget);

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(
                        add(tempBytes, lengthmod),
                        mul(0x20, iszero(lengthmod))
                    )
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(
                            add(
                                add(_bytes, lengthmod),
                                mul(0x20, iszero(lengthmod))
                            ),
                            _start
                        )
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    // 1. transfer asset to this contract (it should have permission as it's transfer proxy to avoid multiple approval points)
    // 2. check allowance from this contract to bridge tx recepient
    // 3. execute bridging transaction
    // 4. produce bridging event
    function bridgeAsset(address _token, uint256 _amount, bytes memory _bridgeTxData, address _relayTarget) public {
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        bridgeAssetDirect(_token, _amount, _bridgeTxData, _relayTarget);
    }

    function bridgeAssetDirect(address _token, uint256 _amount, bytes memory _bridgeTxData, address _relayTarget) internal {
        address targetAddress;
        bytes memory callData = slice(_bridgeTxData, 20, _bridgeTxData.length - 20);
        assembly {
            targetAddress := mload(add(_bridgeTxData, add(0x14, 0)))
        }

        // call method is very powerful, as it allows to call anything pretending to be the transfer proxy
        // (this matters for Mover asset pools)
        // security-wise it's whitelisted to bridge contract address only (may be expanded for different bridges)
        require(targetAddress == 0x37f9aE2e0Ea6742b9CAD5AbCfB6bBC3475b3862B, "unknown bridge");

        resetAllowanceIfNeeded(
            IERC20Upgradeable(_token),
            targetAddress,
            _amount
        );

        (bool success, ) = targetAddress.call(callData);
        require(success, "BRIDGE_CALL_FAILED");

        emit BridgeTx(msg.sender, _token, _amount, targetAddress, _relayTarget);
    }

    function swapBridgeAsset(address _tokenFrom, address _tokenTo, uint256 _amountFrom, uint256 _expectedMinimumReceived, bytes memory _convertData, bytes memory _bridgeTxData, address _relayTarget) public payable {
        require(_tokenFrom != _tokenTo, "same tokens provided");

        if (_tokenFrom != ETH_TOKEN_ADDRESS) {
            IERC20Upgradeable(_tokenFrom).safeTransferFrom(
                msg.sender,
                address(exchangeProxyContract),
                _amountFrom
            );
        }
        uint256 amountReceived =
            IExchangeProxyV2(address(exchangeProxyContract)).executeSwapDirect{value: msg.value}(
                address(this),
                _tokenFrom,
                _tokenTo,
                _amountFrom,
                exchangeFee,
                _convertData
            );
        require(
            amountReceived >= _expectedMinimumReceived,
            "minimum swap amount not met"
        );

        // modify part of bridgeTxData to reflect new amount
        // bridgeTxData
        // bytes   0..19 target contract address
        // bytes  20..23 function signature
        // bytes  24..183 bridge tx params
        // bytes 184..215 amount of target token to bridge
        // bytes 216..407 bridge tx params
        assembly {
            // first 32 bytes of 'bytes' is it's length, and after that it's contents
            // so offset is 32+184=216
            mstore(add(_bridgeTxData, 216), amountReceived)
        }

        bridgeAssetDirect(_tokenTo, amountReceived, _bridgeTxData, _relayTarget);
    }

    function withdrawAndBridgeAsset(address _beneficiary, address _poolAddress, uint256 _amount, bytes memory _bridgeTxData) public {
        require(hasRole(TRUSTED_EXECUTION_ROLE, msg.sender), "trusted executor only");

        IAssetPoolV2 assetPool = IAssetPoolV2(_poolAddress);
        address poolToken = assetPool.getBaseAsset();
        uint256 amountBefore = IERC20Upgradeable(poolToken).balanceOf(address(this));
        assetPool.withdraw(_beneficiary, _amount);
        uint256 withdrawnAmount = IERC20Upgradeable(poolToken).balanceOf(address(this)).sub(amountBefore);

        if (withdrawFee > 0) {
            // process withdraw fees
            // bridgetxdata must take this amount into account
            uint256 feeAmount = withdrawnAmount.mul(withdrawFee).div(1e18);
            bridgeAssetDirect(poolToken, withdrawnAmount.sub(feeAmount), _bridgeTxData, address(0));
        } else {
            bridgeAssetDirect(poolToken, withdrawnAmount, _bridgeTxData, address(0));
        }
    }
}