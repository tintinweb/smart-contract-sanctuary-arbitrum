/**
 *Submitted for verification at Arbiscan on 2022-10-02
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]
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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

 // OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

 // OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

 // OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;




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
        _checkRole(role, _msgSender());
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File contracts/ClansClasses/Control.sol

 pragma solidity 0.8.7;

abstract contract Control is AccessControl {
    bytes32 public constant SHOGUN_OWNER_ROLE = keccak256("SHOGUN_OWNER_ROLE");

    modifier onlyOwner() {
        require(hasRole(SHOGUN_OWNER_ROLE, _msgSender()), "MinterControl: not a SHOGUN_OWNER_ROLE");
        _;
    }

    constructor() {
        _setRoleAdmin(SHOGUN_OWNER_ROLE, SHOGUN_OWNER_ROLE);
        _setupRole(SHOGUN_OWNER_ROLE, _msgSender());
    }

    function grantOwner(address _owner) external {
        grantRole(SHOGUN_OWNER_ROLE, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return hasRole(SHOGUN_OWNER_ROLE, _owner);
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]

 // OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

 // OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File contracts/MinterControl.sol

 pragma solidity 0.8.7;

abstract contract MinterControl is AccessControl {
    bytes32 public constant SHOGUN_OWNER_ROLE = keccak256("SHOGUN_OWNER_ROLE");
    bytes32 public constant SHOGUN_MINTER_ROLE = keccak256("SHOGUN_MINTER_ROLE");

    modifier onlyOwner() {
        require(hasRole(SHOGUN_OWNER_ROLE, _msgSender()), "MinterControl: not a SHOGUN_OWNER_ROLE");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterControl: not a SHOGUN_MINTER_ROLE");
        _;
    }

    constructor() {
        _setRoleAdmin(SHOGUN_OWNER_ROLE, SHOGUN_OWNER_ROLE);
        _setRoleAdmin(SHOGUN_MINTER_ROLE, SHOGUN_OWNER_ROLE);

        _setupRole(SHOGUN_OWNER_ROLE, _msgSender());
    }

    function grantMinter(address _minter) external {
        grantRole(SHOGUN_MINTER_ROLE, _minter);
    }

    function grantMinterMass(address[] memory minters) external {
      for(uint i = 0; i < minters.length; i++) {
          grantRole(SHOGUN_MINTER_ROLE, minters[i]);
      }
    }

    function removeMinter(address _minter) external {
      revokeRole(SHOGUN_MINTER_ROLE, _minter);
    }

    function isMinter(address _minter) public view returns (bool) {
        return hasRole(SHOGUN_MINTER_ROLE, _minter);
    }

    function grantOwner(address _owner) external {
        grantRole(SHOGUN_OWNER_ROLE, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return hasRole(SHOGUN_OWNER_ROLE, _owner);
    }
}


// File contracts/Shogun.sol

 pragma solidity 0.8.7;





contract Shogun is MinterControl, ERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 private constant nftsNumber = 13422;
    uint256 private constant nftsWhitelistNumber = 10000;

    mapping(address => bool) internal wlMinted;

    mapping(uint256 => bool) internal frozenShogun;


    Counters.Counter private _tokenIdCounter;
    string public baseURI;

    event ShogunMint(address to, uint256 tokenId);

    constructor() ERC721("Shogun War", "Shogun") {
      _tokenIdCounter._value = 1;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function safeMint(address to) public onlyOwner {
        _mint(to);
    }

    function mintReserves(address to) public onlyOwner {
      for(uint i = 10000; i < 13423; i++) {
        _mintReserve(to, i);
      }
    }

    function mintReserve(address to, uint256 tokenId) public onlyOwner {
      require(tokenId > nftsWhitelistNumber, "Tokens number to mint must exceed number of public tokens");
      _mintReserve(to, tokenId);
    }

    function mint() external onlyMinter {
        require(wlMinted[msg.sender] == false, "You already used your whitelist mint pass");
        require(balanceOf(msg.sender) < 1, "You can only mint 1 NFT per whitelisted address");
        _mint(msg.sender);
        wlMinted[msg.sender] = true;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Shogun: URI query for nonexistent token");
        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(
                baseURI,
                _tokenId.toString()
            ))
            : "";
    }

    function _mintReserve(address _to, uint256 _tokenId) internal {
        emit ShogunMint(_to, _tokenId);
        _safeMint(_to, _tokenId);
    }

    function _mint(address _to) internal {
        uint256 _tokenId;
        _tokenId = _tokenIdCounter.current();
        require(_tokenIdCounter.current() <= nftsWhitelistNumber, "Token number to mint exceeds number of whitelist tokens");
        _tokenIdCounter.increment();
        emit ShogunMint(_to, _tokenId);
        _safeMint(_to, _tokenId);
    }

    function freezeTransfer(uint256 _tokenId) external onlyOwner {
      frozenShogun[_tokenId] = true;
    }

    function unfreezeTransfer(uint256 _tokenId) external onlyOwner {
      frozenShogun[_tokenId] = false;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        require(frozenShogun[_tokenId] == false, "Shogun: Shogun is still busy, finish your assignment before transferring.");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // ADMIN


    function setBaseURI(string memory _baseURItoSet) external onlyOwner {
        baseURI = _baseURItoSet;
    }
}


// File @openzeppelin/contracts/access/[email protected]

 // OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/TrainingGround.sol

 pragma solidity 0.8.7;


contract TrainingGround is Ownable {

    // shogun training duration
    uint256 public constant trainingDuration = 30 days;

    // amount of shoguns training
    uint256 public shogunTraining;

    // shogun NFT
    Shogun public shogun;

    // training tracking
    mapping(uint256 => uint256) public timestampJoined;
    mapping(uint256 => uint256) public timestampFinished;

    // Shogun trained
    mapping(uint256 => bool) public shogunTrained;

    uint256[] public shogunsTrained;


    event JoinTraining(uint256 tokenId, uint256 timestampJoined, uint256 timestampFinished);
    event FinishTraining(uint256 tokenId);
    event ShogunSet(address shogun);

    modifier onlyShogunOwner(uint256 _tokenId) {
        require(shogun.ownerOf(_tokenId) == msg.sender, "Training: only owner can send to training");
        _;
    }

    modifier onlyUntrainedShogun(uint256 _tokenId) {
        require(shogunTrained[_tokenId] == false, "Training: Shogun already trained");
        _;
    }

    modifier atTraining(uint256 _tokenId, bool expectedAtTraining) {
        require(isAtTraining(_tokenId) == expectedAtTraining, "Training: wrong training attendance");
        _;
    }

    modifier updateTotalTraining(bool isJoining) {
        isJoining ? shogunTraining++ : shogunTraining--;
        _;
    }

    modifier isTrainingFinished(uint256 _tokenId) {
        require(block.timestamp > timestampFinished[_tokenId], "Training: Your shogun is not ready to leave training yet");
        _;
    }

    function totalTraining() public view returns (uint256) {
        return shogunTraining;
    }

    function trainingFinishedDate(uint256 _tokenId) public view returns (uint256) {
        return timestampFinished[_tokenId];
    }

    function isTrained(uint256 _tokenId) public view returns (bool) {
        return shogunTrained[_tokenId];
    }

    function isAtTraining(uint256 _tokenId) public view returns (bool) {
        return timestampJoined[_tokenId] > 0;
    }

    function getTrainedShoguns() public view returns (uint256[] memory) {
        return shogunsTrained;
    }

    function join(uint256 _tokenId)
        external
        onlyShogunOwner(_tokenId)
        atTraining(_tokenId, false)
        onlyUntrainedShogun(_tokenId)
        updateTotalTraining(true)
    {
        timestampJoined[_tokenId] = block.timestamp;
        timestampFinished[_tokenId] = block.timestamp + trainingDuration;
        shogun.freezeTransfer(_tokenId);
        emit JoinTraining(_tokenId, timestampJoined[_tokenId], timestampFinished[_tokenId]);
    }

    function drop(uint256 _tokenId)
        external
        onlyShogunOwner(_tokenId)
        atTraining(_tokenId, true)
        isTrainingFinished(_tokenId)
        updateTotalTraining(false)
    {
        shogun.unfreezeTransfer(_tokenId);
        shogunTrained[_tokenId] = true;
        timestampJoined[_tokenId] = 0;
        shogunsTrained.push(_tokenId);
        emit FinishTraining(_tokenId);
    }

    // ADMIN

    function setShogun(address _shogun) external onlyOwner {
        shogun = Shogun(_shogun);
        emit ShogunSet(_shogun);
    }

    function forceDrop(uint256 _tokenId)
        external
        onlyOwner
        updateTotalTraining(false)
    {
        shogun.unfreezeTransfer(_tokenId);
        shogunTrained[_tokenId] = true;
        timestampJoined[_tokenId] = 0;
        shogunsTrained.push(_tokenId);
        emit FinishTraining(_tokenId);
    }
}


// File contracts/Land.sol

 pragma solidity 0.8.7;







contract Land is MinterControl, ERC721Enumerable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    uint256 public landMaxLevel;

    mapping(uint256 => bool) public landIssued;
    mapping(uint256 => uint256) public landLevels;
    mapping(uint256 => bool) internal landFrozen;

    TrainingGround public trainingGround;
    Shogun public shogun;

    event LandMint(address indexed to, uint256 tokenId);
    event TrainingGroundSet(address trainingGround);
    event ShogunSet(address shogun);

    event LandUpgrade(uint256 indexed tokenId, uint256 availableLevel);
    event LandMaxLevel(uint256 landMaxLevel);


    constructor() ERC721("Shogun War Land", "ShogunWarLand") {
      _tokenIdCounter._value = 1;
    }


    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function mint(uint256[] memory shogunIds) external {
        require(shogunIds.length > 0, "Must provide at least one Shogun Id");
        require(shogun.balanceOf(msg.sender) > 0, "Wallet address does not hold a Shogun");

        for(uint256 i = 0; i < shogunIds.length; i++) {
          require(shogun.ownerOf(shogunIds[i]) == msg.sender, "You do not own one of the shoguns");
          require(trainingGround.isTrained(shogunIds[i]), "Shogun not trained, cannot claim land");
          require(!landIssued[shogunIds[i]], "This shogun has already claimed their land");
          landIssued[shogunIds[i]] = true;
          _mint(msg.sender);
        }
    }

    function safeMint(address to) public onlyOwner {
        _mint(to);
    }

    function _mint(address _to) internal {
        uint256 _tokenId;
        _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        landLevels[_tokenId] = 1;
        _safeMint(_to, _tokenId);
        emit LandMint(_to, _tokenId);
    }


    function freezeTransfer(uint256 _tokenId) external onlyOwner {
      landFrozen[_tokenId] = true;
    }

    function unfreezeTransfer(uint256 _tokenId) external onlyOwner {
      landFrozen[_tokenId] = false;
    }

    function setLandLevel(uint256 _tokenId, uint256 level) external onlyOwner {
      landLevels[_tokenId] = level;
    }

    function landLevel(uint256 _tokenId) public view returns (uint256) {
        return landLevels[_tokenId];
    }

    function isLandIssued(uint256 _tokenId) public view returns (bool) {
        return landIssued[_tokenId];
    }

    function isLandFrozen(uint256 _tokenId) public view returns (bool) {
        return landFrozen[_tokenId];
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        require(landFrozen[_tokenId] == false, "Land is still in use");
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) { // set up api URL to return golden ticket metadata
        require(_exists(_tokenId), "URI query for nonexistent token");
        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(
                baseURI,
                _tokenId.toString()
            ))
            : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // ADMIN

    function setTrainingGround(address _trainingGround) external onlyOwner {
        trainingGround = TrainingGround(_trainingGround);
        emit TrainingGroundSet(_trainingGround);
    }

    function setShogun(address _shogun) external onlyOwner {
        shogun = Shogun(_shogun);
        emit ShogunSet(_shogun);
    }

    function setBaseURI(string memory _baseURItoSet) external onlyOwner {
        baseURI = _baseURItoSet;
    }

    function setMaxLevel(uint256 _landMaxLevel) external onlyOwner {
        landMaxLevel = _landMaxLevel;
        emit LandMaxLevel(_landMaxLevel);
    }
}


// File contracts/ClansClasses/Clans.sol

 pragma solidity 0.8.7;

contract Clans is Control {

    mapping(uint256 => string) public shogunClan;
    mapping(string => uint256) public clanMembers;

    event JoinClan(uint256 tokenId, string clan);
    event LeaveClan(uint256 tokenId, string clan);

    function testStr(string memory str) public pure returns (bool) {
      bytes memory b = bytes(str);
      if (b.length <= 2) return true;
      return false;
    }

    function setShogunClan(uint256 tokenId, string memory clan) external onlyOwner {
          require(testStr(shogunClan[tokenId]), "Cannot assign clan, remove clan first");
          shogunClan[tokenId] = clan;
          clanMembers[clan]++;
          emit JoinClan(tokenId, clan);
    }

    function removeShogunClan(uint256 tokenId) external onlyOwner {
        require(!testStr(shogunClan[tokenId]), "Cannot remove clan, no clan assigned");
        clanMembers[shogunClan[tokenId]]--;
        emit LeaveClan(tokenId, shogunClan[tokenId]);
        shogunClan[tokenId] = "na";
    }

    function checkShogunClan(uint256 tokenId) public view returns (string memory) {
        return shogunClan[tokenId];
    }

    function checkClanMembers(string memory clan) public view returns (uint256) {
        return clanMembers[clan];
    }
}


// File contracts/ClansClasses/Classes.sol

 pragma solidity 0.8.7;

contract Classes is Control {

    mapping(uint256 => string) public shogunClass;
    mapping(string => uint256) public classMembers;

    event JoinClass(uint256 tokenId, string class);
    event LeaveClass(uint256 tokenId, string class);

    function testStr(string memory str) public pure returns (bool) {
      bytes memory b = bytes(str);
      if (b.length <= 2) return true;
      return false;
    }

    function setShogunClass(uint256 tokenId, string memory class) external onlyOwner {
          require(testStr(shogunClass[tokenId]), "Cannot assign class, remove class first");
          shogunClass[tokenId] = class;
          classMembers[class]++;
          emit JoinClass(tokenId, class);
    }

    function removeShogunClass(uint256 tokenId) external onlyOwner {
        require(!testStr(shogunClass[tokenId]), "Cannot remove class, no class assigned");
        classMembers[shogunClass[tokenId]]--;
        shogunClass[tokenId] = "na";
        emit LeaveClass(tokenId, shogunClass[tokenId]);
    }

    function checkShogunClass(uint256 tokenId) public view returns (string memory) {
        return shogunClass[tokenId];
    }

    function checkClassMembers(string memory class) public view returns (uint256) {
        return classMembers[class];
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

 // OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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


// File contracts/Staking/Staking.sol

 pragma solidity 0.8.7;






contract Staking is Control {
    address public rewardToken;

    // reward rates
    uint256 public shogunDailyRewardRate;
    uint256 public landDailyRewardRate;

    // to-do make updatable
    uint256 public unstakeDuration;

    uint256 public totalShogunStaked;
    uint256 public totalLandStaked;

    uint256 public shogunUnstaking;

    // clans options + ronin
    string[] public clanOptions;

    Shogun public shogun;
    Land public land;
    TrainingGround public trainingGround;
    Classes public classes;
    Clans public clans;

    event ShogunSet(address shogun);
    event LandSet(address land);
    event ClassesSet(address classes);
    event ClansSet(address clans);
    event TrainingGroundSet(address trainingGround);

    event LandClanSet(uint256 token, string clan);

    event Stake(uint256 landId, uint256[] shogunIds);
    event StartUnstake(uint256 landId, uint256[] shogunIds);
    event Unstake(uint256 landId, uint256[] shogunIds);

    // tracking if a shogun is staked and what land it's staked to
    mapping(uint256 => bool) public shogunStaked;
    mapping(uint256 => uint256) public shogunStakedToLand;

    // tracking what land is staked + the clan of the land
    // track how many shogun are on a specific piece of land
    mapping(uint256 => bool) public landStaked;
    mapping(uint256 => string) public landClan;
    mapping(uint256 => uint256) public shogunOnLand;

    // land earned rewards + last updated time
    mapping(uint256 => uint256) public landEarnedReward;
    mapping(uint256 => uint256) public landEarnedRewardLastUpdated;

    // unstake tracking
    mapping(uint256 => uint256) public timestampUnstaked;
    mapping(uint256 => uint256) public timestampFinished;


    // -----------------------------------
    // ----Reward calculator functions----
    // -----------------------------------

    function addRewards(uint256 landId, uint256[] memory shogunIds) internal {
      // update currening earnings before adding shogun
      updateEarned(landId);

      // add the new shoguns on the land
      shogunOnLand[landId] += shogunIds.length;
    }

    function removeRewards(uint256 landId, uint256[] memory shogunIds) internal {
      // update currening earnings before adding shogun
      updateEarned(landId);

      // remove the shoguns on the land
      shogunOnLand[landId] -= shogunIds.length;
    }

    function updateEarned(uint256 landId) internal {
      if (landEarnedRewardLastUpdated[landId] == 0) {
        landEarnedRewardLastUpdated[landId] = block.timestamp;
      } else {
        // time staked since last earninings update
        uint256 timeStakedSeconds = block.timestamp - landEarnedRewardLastUpdated[landId];

        // calculate daily rewards
        uint256 shogunRewards = shogunOnLand[landId] * shogunDailyRewardRate;

        // PREVENT LAND FROM MAKING REWARDS WHEN SHOGUNONLAND == 0
        uint256 landRewards;

        if (shogunOnLand[landId] > 0) {
          landRewards = land.landLevel(landId) * landDailyRewardRate;
        } else {
          landRewards = 0;
        }

        uint256 dailyReward = shogunRewards + landRewards;

        // calculate rewards for time period
        uint256 unfriendlyNumber = dailyReward * 1e18;
        uint256 landRewardPerSecond = (unfriendlyNumber / 86400);
        uint256 newRewards = timeStakedSeconds * landRewardPerSecond;
        landEarnedRewardLastUpdated[landId] = block.timestamp;
        landEarnedReward[landId] = landEarnedReward[landId] + newRewards;
      }
    }

    // -----------------------------------
    // ----------Util functions----------
    // -----------------------------------

    function testStr(string memory str) public pure returns (bool) {
      bytes memory b = bytes(str);
      if (b.length <= 2) return true;
      return false;
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // -----------------------------------
    // ----------User functions----------
    // -----------------------------------

    function stake(uint256 landId, uint256[] memory shogunIds) external {
        require(land.ownerOf(landId) == msg.sender, "You do not own this Land");
        require(landStaked[landId], "Select a clan for the land before staking shogun");
        require(shogunIds.length > 0, "Must provide at least one Shogun Id");
        require(shogun.balanceOf(msg.sender) > 0, "Wallet address does not hold a Shogun");

        for(uint256 i = 0; i < shogunIds.length; i++) {
          // check if owned
          require(shogun.ownerOf(shogunIds[i]) == msg.sender, "You do not own one of the shoguns");

          // check if already staked
          require(!shogunStaked[shogunIds[i]], "One of the shoguns is already staked");

          // check if trained
          require(trainingGround.isTrained(shogunIds[i]), "One of the shoguns need to be trained before it can be staked");

          // check if they have a class
          require(!testStr(classes.checkShogunClass(shogunIds[i])), "One of the shoguns needs to join a class before it can be staked");

          // check if they have a clan and if it matches the land's clan
          if (testStr(clans.checkShogunClan(shogunIds[i]))) {
            require(compareStrings(landClan[landId], clanOptions[2]), "One of the shoguns is not in the same clan as the land");
          } else {
            require(compareStrings(clans.checkShogunClan(shogunIds[i]), landClan[landId]), "One of the shoguns is not in the same clan as the land");
          }

          // freezeeee
          shogun.freezeTransfer(shogunIds[i]);

          // set shogunId staked
          shogunStaked[shogunIds[i]] = true;

          // set shogunId as assigned to landId
          shogunStakedToLand[shogunIds[i]] = landId;

          // increase total staked counter
          totalShogunStaked++;
        }
        addRewards(landId, shogunIds);
        emit Stake(landId, shogunIds);
    }

    function totalUnstaking() public view returns (uint256) {
        return shogunUnstaking;
    }

    // shogun Id
    function unstakingFinishedDate(uint256 _tokenId) public view returns (uint256) {
        return timestampFinished[_tokenId];
    }

    // shogun Id
    function isUnstaked(uint256 _tokenId) public view returns (bool) {
        return timestampUnstaked[_tokenId] > 0;
    }

    function startUnstake(uint256 landId, uint256[] memory shogunIds) external {
        // check if land is already frozen
        // if not then freeze and increase counter
        require(land.ownerOf(landId) == msg.sender, "You do not own this Land");
        require(landStaked[landId], "This land is not staked");
        require(shogunIds.length > 0, "Must provide at least one Shogun Id");
        require(shogun.balanceOf(msg.sender) > 0, "Wallet address does not hold a Shogun");

        for(uint256 i = 0; i < shogunIds.length; i++) {
          require(shogun.ownerOf(shogunIds[i]) == msg.sender, "You do not own one of the shoguns");
          require(shogunStaked[shogunIds[i]], "One of the shoguns is not staked");
          require(isUnstaked(shogunIds[i]) == false, "Already unstaking");
          shogunUnstaking++;
          timestampUnstaked[shogunIds[i]] = block.timestamp;
          timestampFinished[shogunIds[i]] = block.timestamp + unstakeDuration;
        }
        removeRewards(landId, shogunIds);
        emit StartUnstake(landId, shogunIds);
    }

    function unstake(uint256 landId, uint256[] memory shogunIds) external {
        // check if land is already frozen
        // if not then freeze and increase counter
        require(land.ownerOf(landId) == msg.sender, "You do not own this Land");
        require(landStaked[landId], "This land is not staked");
        require(shogunIds.length > 0, "Must provide at least one Shogun Id");
        require(shogun.balanceOf(msg.sender) > 0, "Wallet address does not hold a Shogun");

        for(uint256 i = 0; i < shogunIds.length; i++) {
          require(shogun.ownerOf(shogunIds[i]) == msg.sender, "You do not own one of the shoguns");
          require(shogunStaked[shogunIds[i]], "One of the shoguns is not staked");

          require(isUnstaked(shogunIds[i]) == true, "Not unstaking");

          require(block.timestamp > timestampFinished[shogunIds[i]], "Your Shogun is not ready to be unstaked yet.");

          shogun.unfreezeTransfer(shogunIds[i]);
          shogunStaked[shogunIds[i]] = false;
          shogunStakedToLand[shogunIds[i]] = 0;
          totalShogunStaked--;
          timestampUnstaked[shogunIds[i]] = 0;
          shogunUnstaking--;
        }
        emit Unstake(landId, shogunIds);
    }

    function setLandClan(uint256 tokenId, uint256 clanId) external {
      require(!landStaked[tokenId], "Land already has clan");
      require(clanId < clanOptions.length, "Invalid clan ID");
      require(land.ownerOf(tokenId) == msg.sender, "You do not own this Land");
      land.freezeTransfer(tokenId);
      totalLandStaked++;
      landStaked[tokenId] = true;
      landClan[tokenId] = clanOptions[clanId];
      emit LandClanSet(tokenId, clanOptions[clanId]);
    }

    function unsetLandClan(uint256 tokenId) external {
      require(landStaked[tokenId], "Land has no clan");
      require(land.ownerOf(tokenId) == msg.sender, "You do not own this Land");
      require(shogunOnLand[tokenId] == 0, "Cannot remove clan from land while shogun are still staked");
      land.unfreezeTransfer(tokenId);
      totalLandStaked--;
      landStaked[tokenId] = false;
      landClan[tokenId] = "na";
      emit LandClanSet(tokenId, "na");
    }

    // -----------------------------------
    // ----------Reward functions---------
    // -----------------------------------

    function claimReward(uint256 landId) external  {
        require(land.ownerOf(landId) == msg.sender, "You do not own this Land");
        updateEarned(landId);
        uint256 rewardAmt = landEarnedReward[landId];
        landEarnedReward[landId] = 0;
        IERC20(rewardToken).transfer(msg.sender, rewardAmt);
    }

    function getLandDailyReward(uint256 landId) public view returns (uint256 dailyRewards) {
      // calculate daily rewards
      uint256 shogunRewards = shogunOnLand[landId] * shogunDailyRewardRate;

      // PREVENT LAND FROM MAKING REWARDS WHEN SHOGUNONLAND == 0
      uint256 landRewards;

      if (shogunOnLand[landId] > 0) {
        landRewards = land.landLevel(landId) * landDailyRewardRate;
      } else {
        landRewards = 0;
      }

      uint256 dailyReward = shogunRewards + landRewards;

      return dailyReward;
    }

    function getCurrentConfirmedRewards(uint256 landId) public view returns (uint256 reward) {
      return landEarnedReward[landId];
    }

    function getCurrentConfirmedRewardsLastUpdated(uint256 landId) public view returns (uint256 lastUpdated) {
      return landEarnedRewardLastUpdated[landId];
    }


    // -----------------------------------
    // ----------Admin functions----------
    // -----------------------------------

    // admin control
    function forceUnstake(uint256 landId, uint256[] memory shogunIds) external onlyOwner {
      for(uint256 i = 0; i < shogunIds.length; i++) {
        shogun.unfreezeTransfer(shogunIds[i]);
        shogunStaked[shogunIds[i]] = false;
        shogunStakedToLand[shogunIds[i]] = 0;
        totalShogunStaked--;
        timestampUnstaked[shogunIds[i]] = 0;
        shogunUnstaking--;
      }
      emit Unstake(landId, shogunIds);
    }

    // configs
    function setClanOptions(string[] memory _clanOptions) external onlyOwner {
        clanOptions = _clanOptions;
    }

    function setRewardToken(address tokenAddress) external onlyOwner {
        rewardToken = tokenAddress;
    }

    function setUnstakeDuration(uint256 duration) external onlyOwner {
        unstakeDuration = duration;
    }

    function setShogunDailyRewardRate(uint256 shogunDailyReward) external onlyOwner {
        shogunDailyRewardRate = shogunDailyReward;
    }

    function setLandDailyRewardRate(uint256 landDailyReward) external onlyOwner {
        landDailyRewardRate = landDailyReward;
    }

    // external contracts
    function setShogun(address _shogun) external onlyOwner {
        shogun = Shogun(_shogun);
        emit ShogunSet(_shogun);
    }

    function setLand(address _land) external onlyOwner {
        land = Land(_land);
        emit LandSet(_land);
    }

    function setTrainingGround(address _trainingGround) external onlyOwner {
        trainingGround = TrainingGround(_trainingGround);
        emit TrainingGroundSet(_trainingGround);
    }

    function setClasses(address _classes) external onlyOwner {
        classes = Classes(_classes);
        emit ClassesSet(_classes);
    }

    function setClans(address _clans) external onlyOwner {
        clans = Clans(_clans);
        emit ClansSet(_clans);
    }
}


// File contracts/Staking/QuickUnstake.sol

 pragma solidity 0.8.7;




contract QuickUnstake is Control {

    Shogun public shogun;
    Land public land;
    Staking public staking;

    function quickUnstake(uint256 landId, uint256[] memory shogunIds) external {

        for(uint256 i = 0; i < shogunIds.length; i++) {
          require(shogun.ownerOf(shogunIds[i]) == msg.sender, "You do not own one of the shoguns");
        }

        require(land.ownerOf(landId) == msg.sender, "You do not own this Shogun");

        staking.forceUnstake(landId, shogunIds);

    }

    // configs
    function setStaking(address _staking) external onlyOwner {
        staking = Staking(_staking);
    }

    function setShogun(address _shogun) external onlyOwner {
        shogun = Shogun(_shogun);
    }

    function setLand(address _land) external onlyOwner {
        land = Land(_land);
    }
}