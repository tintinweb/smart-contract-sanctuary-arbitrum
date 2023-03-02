/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

// File: @openzeppelin/contracts/access/IAccessControl.sol

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

// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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

// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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

// File: contracts/TransferHelper.sol


pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts/FactoryIdo.sol


pragma solidity 0.8.15;





contract FactoryIdo is AccessControl, ReentrancyGuard {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    uint256 public constant BASE = 1e12;
    uint256 private MAX_UINT = 2**128 - 1;

    Ido[] public idos;
    mapping(uint256 => IdoParam) public idoParams;
    mapping(uint256 => VestingInfo) public vestingInfo;
    mapping(uint256 => WeightsInfo) public weightsInfo;
    // match idoId and investor to payed, bought and claimed amounts
    mapping(uint256 => mapping(address => Investment)) public investments;
    // save all bools: [0] for withWeights,
    // [1] for vesting, [2] for add liq
    uint256[][3] private bools;

    struct Ido {
        address owner;
        address projectToken;
        uint128 price;
        uint128 sellStart;
        uint128 sellEnd;
        uint128 softcap;
        uint128 hardcap;
        uint128 decimals;
    }

    struct IdoParam {
        uint128 totalRaised;
        uint128 totalBought;
    }

    struct VestingInfo {
        uint128 startUnlockPercent; // * BASE
        uint128 unlockPercent;
        uint256 unlockStepTime;
    }

    struct Investment {
        uint256 payed;
        uint256 bought;
        uint256 claimed;
    }

    struct WeightsInfo {
        uint256 totalWeights;
        bytes32 merkleRoot;
    }

    modifier onlyInvestors(uint256 idoId) {
        require(investments[idoId][_msgSender()].payed > 0, "Only investors");
        _;
    }

    modifier onlyIdoOwner(uint256 idoId) {
        require(idos[idoId].owner == _msgSender(), "Only ido owner");
        _;
    }

    modifier existIdo(uint256 idoId) {
        require(idoId < idos.length, "Wrong Id");
        _;
    }

    event AddIdo(uint256 idoId, uint256 sellStart);
    event StartSell(uint256 idoId);
    event Invest(
        uint256 idoId,
        address user,
        uint256 bought,
        uint256 totalBought
    );
    event LiquidityAdded(
        uint256 idoId,
        uint256 totalBought,
        uint256 totalRaised
    );
    event Claim(uint256 idoId, uint256 amount);

    constructor(address _owner, address signer) {
        require(_owner != address(0) && signer != address(0), "Zero address");
        _grantRole(0x0, _owner);
        _grantRole(SIGNER_ROLE, signer);
        bools[0].push(0);
        bools[1].push(0);
        bools[2].push(0);
    }

    /**
     * @notice create new ido with input params
     * @param _ido - struct with params
     * owner - address of project owner
     * projectToken - address of project token
     * price - cost for 1 token in wei
     * sellStart - timestamp of sell start, must be more then now + 4 days
     * sellEnd - timestamp of sell end, must be more then sellStart
     * softcap - num of project tokens to buy to apply ido
     * hardcap - max num of project tokens
     * decimals - 10^decimals of project token
     * @param withWeights if ido with weights = true, else false
     * @param vesting - if ido with vesting then true, else false
     * @param vestingParams - [] if vesting = false, else
     * [ firtUnlockPers - percent of amount to unlock after sell end * BASE
     *   unlockPers - percent of amount to unlock after each step * BASE
     *   unlockStepTime - step time in seconds]
     */
    function addIdo(
        Ido calldata _ido,
        bool withWeights,
        bool vesting,
        uint128[] calldata vestingParams
    ) external onlyRole(SIGNER_ROLE) {
        require(
            _ido.sellStart >= block.timestamp + 2 minutes,
            "Too early sell start"
        );
        require(_ido.sellStart < _ido.sellEnd, "Wrong sell end");
        require(_ido.softcap > 0, "Zero softcap");
        require(_ido.softcap < _ido.hardcap, "Softcap excess hardcap");
        require(_ido.price > 0, "Zero price");
        require(
            _ido.owner != address(0) && _ido.projectToken != address(0),
            "Zero address"
        );
        require(_ido.decimals > 0, "Zero decimals");
        uint256 idoId = idos.length;
        idos.push(_ido);
        if (withWeights) {
            setBool(idoId, 0);
        }
        if (vesting) {
            setBool(idoId, 1);
            require(vestingParams.length == 3, "Wrong vesing params");
            vestingInfo[idoId] = VestingInfo(
                vestingParams[0],
                vestingParams[1],
                vestingParams[2]
            );
        }
        emit AddIdo(idoId, _ido.sellStart);
    }

    /**
     * @notice allow backend delete ido if admin delete it,
     * can delete ido only if registration/sell not started yet
     * @param idoId - index of ido in idos
     */
    function deleteIdo(uint256 idoId) external onlyRole(0x0) existIdo(idoId) {
        require(idos[idoId].sellStart > block.timestamp, "Ido already started");
        delete idos[idoId];
        delete vestingInfo[idoId];
        delete idoParams[idoId];
    }

    /**
     * @notice allow admin set whitelist/regstrated users and their weights
     * @param idoId - index of ido in idos
     * @param _merkleRoot - root of merkle tree of registred/whitelisted users
     * @param totalWeight - sum of weights of registred/whitelisted users
     */
    function startSell(
        uint256 idoId,
        bytes32 _merkleRoot,
        uint256 totalWeight
    ) external onlyRole(SIGNER_ROLE) existIdo(idoId) {
        require(readBool(idoId, 0), "Without weights");
        Ido memory ido = idos[idoId];
        require(
            ido.sellEnd > block.timestamp &&
                block.timestamp >= ido.sellStart - 5 minutes,
            "Wrong time"
        );
        require(weightsInfo[idoId].totalWeights == 0, "Already started");
        weightsInfo[idoId] = WeightsInfo(totalWeight, _merkleRoot);
        emit StartSell(idoId);
    }

    /**
     * @notice allow whitelist/regstrated users to buy projectToken,
     * check that total bought amount not excess their weighted part
     * @param idoId - index of ido in idos
     * @param weight - weight of user that seved in tree * 10
     * @param proof - proof that this user registred/whitelist to this ido
     */
    function invest(
        uint256 idoId,
        uint256 weight,
        bytes32[] calldata proof
    ) external payable existIdo(idoId) {
        require(msg.value > 0 && msg.value <= MAX_UINT, "Zero amount");
        Ido memory ido = idos[idoId];
        require(
            ido.sellStart <= block.timestamp && block.timestamp < ido.sellEnd,
            "Not sell time"
        );
        bool weights = readBool(idoId, 0);
        if (weights) {
            require(
                MerkleProof.verify(
                    proof,
                    weightsInfo[idoId].merkleRoot,
                    keccak256(abi.encodePacked(_msgSender(), weight))
                ),
                "Only registred/whitelist investors"
            );
        }
        IdoParam storage addedParams = idoParams[idoId];
        uint256 amount = (msg.value * ido.decimals) / ido.price;
        require(amount > 0 && amount <= MAX_UINT, "Zero bought amount");
        Investment storage investment = investments[idoId][_msgSender()];
        investment.payed += msg.value;
        investment.bought += amount;
        if (weights) {
            require(
                investment.bought <=
                    (weight * ido.hardcap) / weightsInfo[idoId].totalWeights,
                "Total amount excess weight part"
            );
        }
        addedParams.totalRaised += uint128(msg.value);
        addedParams.totalBought += uint128(amount);
        require(addedParams.totalBought <= ido.hardcap, "Hardcap exceded");
        emit Invest(idoId, _msgSender(), amount, addedParams.totalBought);
    }

    /**
     * @notice allow ido owner add liquidity of project tokens
     * if softcap was earned, tokens must be approved for ido.totalBought
     * @param idoId - index of ido in idos
     * @dev set addLiq flag to true (bools[3])
     */
    function addLiquidity(uint256 idoId)
        external
        existIdo(idoId)
        onlyIdoOwner(idoId)
        nonReentrant
    {
        IdoParam memory addedParams = idoParams[idoId];
        require(
            block.timestamp >= idos[idoId].sellEnd &&
                idos[idoId].softcap <= addedParams.totalBought &&
                !readBool(idoId, 2),
            "Add liquidity not available"
        );
        setBool(idoId, 2);
        TransferHelper.safeTransferFrom(
            idos[idoId].projectToken,
            _msgSender(),
            address(this),
            addedParams.totalBought
        );
        (bool success, ) = payable(_msgSender()).call{
            value: addedParams.totalRaised
        }("");
        require(success, "Rised funds not transfer");
        emit LiquidityAdded(
            idoId,
            addedParams.totalBought,
            addedParams.totalRaised
        );
    }

    /**
     * @notice allow investors claim their project tokens if softcap was earned
     * @param idoId - index of ido in idos
     */
    function claimTokens(uint256 idoId)
        external
        existIdo(idoId)
        onlyInvestors(idoId)
        nonReentrant
    {
        require(
            idos[idoId].sellEnd <= block.timestamp &&
                idos[idoId].softcap <= idoParams[idoId].totalBought &&
                readBool(idoId, 2),
            "Claim tokens not available"
        );
        if (readBool(idoId, 1)) {
            _claimTokensVesting(idoId);
        } else {
            _claimTokens(idoId);
        }
    }

    /**
     * @notice allow investors claim their cro if softcap wasn't earned
     * @param idoId - index of ido in idos
     */
    function withdrawInvestment(uint256 idoId)
        external
        existIdo(idoId)
        onlyInvestors(idoId)
        nonReentrant
    {
        require(
            idos[idoId].sellEnd <= block.timestamp &&
                idos[idoId].softcap > idoParams[idoId].totalBought,
            "Withdraw investment not available"
        );
        uint256 amount = investments[idoId][_msgSender()].payed;
        delete investments[idoId][_msgSender()];
        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "CRO not transfer");
        emit Claim(idoId, amount);
    }

    /**
     * @notice return totalBought for idoIds
     * @param idoIds array of idoId
     * @return array with totalBought for each idoId
     */
    function getBoughts(uint256[] calldata idoIds)
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = idoIds.length;
        uint256[] memory totalBoughts = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            totalBoughts[i] = idoParams[idoIds[i]].totalBought;
            unchecked {
                ++i;
            }
        }
        return totalBoughts;
    }

    /**
     * @notice return true if liq added, else return false
     * @param idoId - index of ido in idos
     */
    function isLiqAdded(uint256 idoId) external view returns (bool) {
        return readBool(idoId, 2);
    }

    /**
     * @notice func that return token amount, that can be claimed right now
     * @param user - address of investor
     * @return amounts array with token amounts for investor
     * amounts[0] - total bought token amount
     * amounts[1] - how many tokens he/she can claim now
     * amounts[2] - how many tokens he/she already claimed
     */
    function getClaimAmount(uint256 idoId, address user)
        external
        view
        returns (uint256[3] memory amounts)
    {
        amounts[0] = investments[idoId][user].bought;
        amounts[2] = investments[idoId][user].claimed;
        if (!readBool(idoId, 2)) {
            amounts[1] = 0;
            return amounts;
        }
        if (!readBool(idoId, 1)) {
            amounts[1] = amounts[0];
        } else {
            VestingInfo memory vest = vestingInfo[idoId];
            uint256 withdraw = (amounts[0] *
                (vest.startUnlockPercent +
                    ((block.timestamp - idos[idoId].sellEnd) /
                        vest.unlockStepTime) *
                    vest.unlockPercent)) / BASE;
            if (withdraw >= amounts[0]) {
                amounts[1] = amounts[0] - amounts[2];
            } else {
                amounts[1] = withdraw - amounts[2];
            }
        }
    }

    /**
     * @notice this called if withdraw withount vesting
     * just transfer all bought project tokens to investor
     */
    function _claimTokens(uint256 idoId) internal {
        uint256 amount = investments[idoId][_msgSender()].bought;
        delete investments[idoId][_msgSender()];
        if (amount > 0) {
            TransferHelper.safeTransfer(
                idos[idoId].projectToken,
                _msgSender(),
                amount
            );
        }
        emit Claim(idoId, amount);
    }

    /**
     * @notice this called if withdraw with vesting
     */
    function _claimTokensVesting(uint256 idoId) internal {
        VestingInfo memory vest = vestingInfo[idoId];
        uint256 claimed = investments[idoId][_msgSender()].claimed;
        uint256 bought = investments[idoId][_msgSender()].bought;
        uint256 withdraw = (bought *
            (vest.startUnlockPercent +
                ((block.timestamp - idos[idoId].sellEnd) /
                    vest.unlockStepTime) *
                vest.unlockPercent)) / BASE;
        if (withdraw >= bought) {
            delete investments[idoId][_msgSender()];
            withdraw = bought - claimed;
            if (withdraw > 0) {
                TransferHelper.safeTransfer(
                    idos[idoId].projectToken,
                    _msgSender(),
                    withdraw
                );
            }
        } else {
            withdraw -= claimed;
            require(withdraw > 0, "Nothing to withdraw yet");
            investments[idoId][_msgSender()].claimed += withdraw;
            TransferHelper.safeTransfer(
                idos[idoId].projectToken,
                _msgSender(),
                withdraw
            );
        }
        emit Claim(idoId, withdraw);
    }

    /**
     * @notice func for set bite in true
     */
    function setBool(uint256 index, uint256 pos) internal {
        uint256 div = index / 255;
        uint256 mod = index % 255;
        if (div > bools[pos].length - 1) {
            bools[pos].push(0);
        }
        bools[pos][div] = bools[pos][div] | (1 << mod);
    }

    /**
     * @notice func for read is bite true or false
     */
    function readBool(uint256 index, uint256 pos) internal view returns (bool) {
        uint256 div = index / 255;
        uint256 mod = index % 255;
        if (div > bools[pos].length - 1) {
            return false;
        }
        return (bools[pos][div] & (1 << mod)) > 0;
    }
}