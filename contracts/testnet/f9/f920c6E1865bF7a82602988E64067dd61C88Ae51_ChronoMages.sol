/**
 *Submitted for verification at arbiscan.io on 2022-02-19
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: contracts/Parents/ERC721A.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;









error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  using Address for address;
  using Strings for uint256;

  // Compiler will pack this into a single 256bit word.
  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
  }

  // Compiler will pack this into a single 256bit word.
  struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
  }

  // Compiler will pack the following
  // _currentIndex and _burnCounter into a single 256bit word.

  // The tokenId of the next token to be minted.
  uint128 internal _currentIndex;

  // The number of tokens burned.
  uint128 internal _burnCounter;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) internal _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than _currentIndex times
    unchecked {
      return _currentIndex - _burnCounter;
    }
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    uint256 numMintedSoFar = _currentIndex;
    uint256 tokenIdsIdx;

    // Counter overflow is impossible as the loop breaks when
    // uint256 i is equal to another uint256 numMintedSoFar.
    unchecked {
      for (uint256 i; i < numMintedSoFar; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (!ownership.burned) {
          if (tokenIdsIdx == index) {
            return i;
          }
          tokenIdsIdx++;
        }
      }
    }
    revert TokenIndexOutOfBounds();
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
    uint256 numMintedSoFar = _currentIndex;
    uint256 tokenIdsIdx;
    address currOwnershipAddr;

    // Counter overflow is impossible as the loop breaks when
    // uint256 i is equal to another uint256 numMintedSoFar.
    unchecked {
      for (uint256 i; i < numMintedSoFar; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          if (tokenIdsIdx == index) {
            return i;
          }
          tokenIdsIdx++;
        }
      }
    }

    // Execution should never reach this point.
    revert();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    if (owner == address(0)) revert MintedQueryForZeroAddress();
    return uint256(_addressData[owner].numberMinted);
  }

  function _numberBurned(address owner) internal view returns (uint256) {
    if (owner == address(0)) revert BurnedQueryForZeroAddress();
    return uint256(_addressData[owner].numberBurned);
  }

  /**
   * Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around in the collection over time.
   */
  function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    uint256 curr = tokenId;

    unchecked {
      if (curr < _currentIndex) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (!ownership.burned) {
          if (ownership.addr != address(0)) {
            return ownership;
          }
          // Invariant:
          // There will always be an ownership that has an address and is not burned
          // before an ownership that does not have an address and is not burned.
          // Hence, curr will not underflow.
          while (true) {
            curr--;
            ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
              return ownership;
            }
          }
        }
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
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
    _transfer(from, to, tokenId);
    if (!_checkOnERC721Received(from, to, tokenId, _data)) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < _currentIndex && !_ownerships[tokenId].burned;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    _mint(to, quantity, _data, true);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 quantity,
    bytes memory _data,
    bool safe
  ) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
    // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
    unchecked {
      _addressData[to].balance += uint64(quantity);
      _addressData[to].numberMinted += uint64(quantity);

      _ownerships[startTokenId].addr = to;
      _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

      uint256 updatedIndex = startTokenId;

      for (uint256 i; i < quantity; i++) {
        emit Transfer(address(0), to, updatedIndex);
        if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
          revert TransferToNonERC721ReceiverImplementer();
        }
        updatedIndex++;
      }

      _currentIndex = uint128(updatedIndex);
    }
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr || isApprovedForAll(prevOwnership.addr, _msgSender()) || getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
    unchecked {
      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;

      _ownerships[tokenId].addr = to;
      _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

      // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId < _currentIndex) {
          _ownerships[nextTokenId].addr = prevOwnership.addr;
          _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
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
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
    unchecked {
      _addressData[prevOwnership.addr].balance -= 1;
      _addressData[prevOwnership.addr].numberBurned += 1;

      // Keep track of who burned the token, and the timestamp of burning.
      _ownerships[tokenId].addr = prevOwnership.addr;
      _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
      _ownerships[tokenId].burned = true;

      // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId < _currentIndex) {
          _ownerships[nextTokenId].addr = prevOwnership.addr;
          _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(prevOwnership.addr, address(0), tokenId);
    _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
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
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert TransferToNonERC721ReceiverImplementer();
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   * And also called after one token has been burned.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// File: contracts/Parents/ERC721ABurnable.sol


// Creator: Chiru Labs

pragma solidity ^0.8.4;



/**
 * @title ERC721A Burnable Token
 * @dev ERC721A Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721ABurnable is Context, ERC721A {
  /**
   * @dev Burns `tokenId`. See {ERC721A-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr || isApprovedForAll(prevOwnership.addr, _msgSender()) || getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

    _burn(tokenId);
  }
}

// File: contracts/_ChronoMages.sol


// @author Kyle Stargarden
// Big thanks to OpenZeppelin, Forgotten Runes Wizards Cult and Azuki for making this possible!!!

pragma solidity ^0.8.2;





// interface for minting from Warp contract
interface WarpMint {
  function safeMint(address to) external;
}

// Edit contract name and filename just prior to launch
contract ChronoMages is ERC721A, ERC721ABurnable, AccessControl, ReentrancyGuard {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  // max number of ChronoMages that can be minted per call
  uint256 public constant maxMint = 50;

  /*************************
     MAPPING STRUCTS EVENTS
     *************************/

  // stores information required to complete a commit / reveal mint
  struct Ritual {
    // the amount of NFTs user is claiming
    uint256 amount;
    // the block.number which will be used to source entropy
    uint256 requiredBlock;
  }

  // Struct to store all required data to enable successful transformation
  struct Transformation {
    // tokenId of the ChronoMage who has walked into the Warp Rift
    uint256 tokenId;
    // the block number providing our entropy to decide the hapless ChronoMage's fate
    uint256 requiredBlock;
    // the bonus to transformation for holding onto a ChronoMage an amount of time
    uint256 timeBonus;
    // balance of the user when transformation begins
    uint256 balance;
    // total ChronoMages minted by user
    uint256 numberMinted;
    // total ChronoMages killed by user
    uint256 numberBurned;
  }

  // returns a ritual struct for a given wallet address
  mapping(address => Ritual) public _ritual;

  // mapping user address to Transformation struct
  mapping(address => Transformation) public _transformation;

  // emits Begin Ritual success for front-end consumption
  event BeginRitual(address indexed _to, uint256 indexed _amount, uint256 indexed _requiredBlock);

  // emits Finish Ritual success for front-end consumption
  event FinishRitual(uint256 indexed _startTokenId, uint256 indexed _endTokenId, uint256 indexed _batchHash);

  // emits BeginTransformation success for front-end consumption
  event BeginTransformation(address indexed _from, uint256 indexed _requiredBlock, uint256 indexed _timeBonus);

  // emits FinishTransformation event for front-end consumption
  event FinishTransformation(address indexed _to, uint256 indexed _tokenId, uint256 _roll);

  // emits a DeadMage transformation failure event for front-end consumption
  event DeadMage(address indexed _from, uint256 indexed tokenId);

  /*************************
     STATE VARIABLES
     *************************/

  // provenance can only be set one time - the transaction carries hex encoded image calldata!!!
  uint256 _provenance;

  // pauses minting when true
  bool _paused = true;

  // baseURI for accessing token metadata
  string private _baseTokenURI;

  // contract address for Transformation
  address public _warp;

  constructor() ERC721A("ChronoMages", "CHRONO") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
    _baseTokenURI = "https://chronomages.com/";
  }

  /*************************
     MODIFIERS
     *************************/

  // onlyRole also available
  // prevents all contracts from calling the minting functions
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract!");
    _;
  }

  // enforces that _pause is not enabled
  modifier notPaused() {
    require(!_paused, "Minting is paused!");
    _;
  }

  /*************************
     SALE LOGIC
     *************************/

  // public price is 0.02 ETH
  uint256 constant publicPrice = 2 * 10**16;

  // the address that withdraws will be sent to
  address _withdrawAddress;

  /*************************
     VIEW AND PURE FUNCTIONS
     *************************/

  // returns true if user has a pending ritual
  function isPendingRitual(address _to) public view returns (bool) {
    if (_ritual[_to].amount > 0) {
      return true;
    }
    return false;
  }

  // returns true if the ritual is ready to be finished
  function isRitualReady(address _to) public view returns (bool) {
    if (_ritual[_to].requiredBlock <= block.number && _ritual[_to].requiredBlock != 0) {
      return true;
    }
    return false;
  }

  // returns true if user has a pending transformation
  function isPendingTransformation(address _to) public view returns (bool) {
    if (_transformation[_to].requiredBlock > 0) {
      return true;
    }
    return false;
  }

  // returns true if the transformation is ready to be finished
  function isTransformationReady(address _to) public view returns (bool) {
    if (_transformation[_to].requiredBlock <= block.number && _transformation[_to].requiredBlock != 0) {
      return true;
    }
    return false;
  }

  // returns the current withdraw address
  function viewWithdrawAddress() public view returns (address) {
    return _withdrawAddress;
  }

  // returns the publicPrice
  function viewPrice() public pure returns (uint256) {
    return publicPrice;
  }

  // returns the base token URI, override requirement
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // returns the paused status
  function isPaused() public view returns (bool) {
    return _paused;
  }

  /*************************
     USER FUNCTIONS
     *************************/

  // so young and so full of promise
  function beginTransformation(address _from, uint256 tokenId) external callerIsUser notPaused {
    require(_transformation[_from].requiredBlock == 0, "Transformation already in progress!");
    require(_msgSender() == _from, "Only you can tinker with time itself!");
    Transformation memory transformation;
    transformation.tokenId = tokenId;
    transformation.requiredBlock = block.number + 5;
    transformation.timeBonus = block.timestamp - ownershipOf(tokenId).startTimestamp;
    transformation.balance = balanceOf(_from);
    transformation.numberMinted = _numberMinted(_from);
    transformation.numberBurned = _numberBurned(_from);
    _transformation[_from] = transformation;
    emit BeginTransformation(_from, transformation.requiredBlock, transformation.timeBonus);
    transferFrom(_from, address(this), tokenId);
  }

  // hapless mages shouldn't tinker with time itself
  function finishTransformation(address _to) external callerIsUser notPaused {
    require(_transformation[_to].requiredBlock <= block.number, "Transformation not ready!");
    require(_msgSender() == _to, "Only you can tinker with time itself!");
    Transformation memory transformation = _transformation[_to];
    delete _transformation[_to];
    bytes memory _blockHash = abi.encodePacked(blockhash(transformation.requiredBlock));
    uint256 _randomNumber = uint256(keccak256(_blockHash));
    uint256 _roll = _randomNumber % 12960000;
    uint256 _timeBonus = transformation.timeBonus;
    uint256 tokenId = transformation.tokenId;
    if (_timeBonus > 2592000) {
      _timeBonus = 2592000;
    }
    _roll = _roll + _timeBonus;
    if (_roll >= 11664000) {
      WarpMint(_warp).safeMint(_to);
      emit FinishTransformation(_to, tokenId, _roll);
    } else {
      burn(tokenId);
      emit DeadMage(_to, tokenId);
    }
  }

  function setWarpAddress(address warp) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _warp = warp;
  }

  // user commits to minting set amount of tokens by paying - and waiting for a blockhash in the future
  function beginRitual(address _to, uint256 _amount) external payable callerIsUser notPaused {
    require(_to != address(0), "Cannot mint to the zero address!");
    require(_amount > 0, "Amount cannot be zero!");
    require(_amount <= maxMint, "Cannot mint more than maxMint");
    require(_ritual[_to].amount == 0, "Ritual already in progress!");
    Ritual memory ritual;
    ritual.amount = _amount;
    ritual.requiredBlock = block.number + 5;
    _refundIfOver(publicPrice * _amount);
    _ritual[_to] = ritual;
    emit BeginRitual(_to, _amount, ritual.requiredBlock);
  }

  /* user mints their tokens - and emits a predetermined block's blockhash - this hash is used as a
  seed to generate all of the token's attributes in the given batch  */

  function finishRitual(address _to) external callerIsUser notPaused {
    require(_to != address(0), "Cannot mint to the zero address!");
    require(_ritual[_to].amount > 0, "You must begin the ritual!");
    require(block.number >= _ritual[_to].requiredBlock, "Must wait until the requiredBlock!");
    uint256 _amount = _ritual[_to].amount;
    bytes memory _blockHash = abi.encodePacked(blockhash(_ritual[_to].requiredBlock));
    uint256 _randomNumber = uint256(keccak256(_blockHash));
    delete _ritual[_to];
    uint256 _startTokenId = _currentIndex;
    uint256 _endTokenId = _currentIndex + _amount - 1;
    emit FinishRitual(_startTokenId, _endTokenId, _randomNumber);
    _safeMint(_to, _amount);
  }

  /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

  /* rescue function provides a safety net in case a user's ritual when an old blockhash is pruned
  DEFAULT_ADMIN can recover the blockhash off-chain and rescue a user's ritual */
  function rescue(address _to, bytes calldata _blockHash) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_to != address(0), "Cannot mint to the zero address!");
    require(_ritual[_to].amount > 0, "You must begin the ritual!");
    require(block.number >= _ritual[_to].requiredBlock, "Must wait until the requiredBlock!");
    uint256 _amount = _ritual[_to].amount;
    uint256 _randomNumber = uint256(keccak256(_blockHash));
    delete _ritual[_to];
    uint256 _startTokenId = _currentIndex;
    uint256 _endTokenId = _currentIndex + _amount - 1;
    emit FinishRitual(_startTokenId, _endTokenId, _randomNumber);
    _safeMint(_to, _amount);
  }

  function provenance(bytes calldata provenanceImage) public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_provenance == 0, "Provenance image already set!");
    _provenance = 1;
  }

  // allows setting the withdraw address
  function setWithdrawAddress(address withdrawAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _withdrawAddress = withdrawAddress;
  }

  // allows ADMIN to withdraw sale funds
  function withdrawAll() public onlyRole(DEFAULT_ADMIN_ROLE) {
    require(payable(viewWithdrawAddress()).send(address(this).balance));
  }

  // allows PAUSER_ROLE to toggle _paused flag
  function setPause(bool _setPaused) external onlyRole(PAUSER_ROLE) {
    _paused = _setPaused;
  }

  // allows DEFAULT_ADMIN_ROLE to rug the URI
  function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _baseTokenURI = baseURI;
  }

  // allows MINTER_ROLE contracts to mint NFTs
  function transmogrify(address _to, uint256 _amount) external nonReentrant onlyRole(MINTER_ROLE) {
    require(_to == address(0), "Cannot mint to the zero address!");
    require(_amount > 0, "Cannot mint zero NFTs");
    _safeMint(_to, _amount, "");
  }

  // allows DEFAULT_ADMIN to whitelist new contracts as MINTER_ROLE
  function newTransmogrify(address newContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, newContract);
  }

  /*************************
     PRIVATE / INTERNAL
     *************************/

  // verifies correct amount of ETH sent to contract and refunds if over
  function _refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  /*************************
     OVERRIDES
     *************************/

  // override required by Solidity
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}