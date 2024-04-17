// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        return _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(operator != _msgSender(), "ERC721: approve to caller");

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
 * ```
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/IAbstractRewards.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract AbstractRewards is IAbstractRewards {
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;

/* ========  Constants  ======== */
  uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

  event PointsCorrectionUpdated(address indexed account, int256 points);

/* ========  Internal Function References  ======== */
  function(address) view returns (uint256) private immutable getSharesOf;
  function() view returns (uint256) private immutable getTotalShares;

/* ========  Storage  ======== */
  uint256 public pointsPerShare;
  mapping(address => int256) public pointsCorrection;
  mapping(address => uint256) public withdrawnRewards;

  constructor(
    function(address) view returns (uint256) getSharesOf_,
    function() view returns (uint256) getTotalShares_
  ) {
    getSharesOf = getSharesOf_;
    getTotalShares = getTotalShares_;
  }

/* ========  Public View Functions  ======== */
  /**
   * @dev Returns the total amount of rewards a given address is able to withdraw.
   * @param _account Address of a reward recipient
   * @return A uint256 representing the rewards `account` can withdraw
   */
  function withdrawableRewardsOf(address _account) public view override returns (uint256) {
    return cumulativeRewardsOf(_account) - withdrawnRewards[_account];
  }

  /**
   * @notice View the amount of rewards that an address has withdrawn.
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has withdrawn.
   */
  function withdrawnRewardsOf(address _account) public view override returns (uint256) {
    return withdrawnRewards[_account];
  }

  /**
   * @notice View the amount of rewards that an address has earned in total.
   * @dev accumulativeFundsOf(account) = withdrawableRewardsOf(account) + withdrawnRewardsOf(account)
   * = (pointsPerShare * balanceOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has earned in total.
   */
  function cumulativeRewardsOf(address _account) public view override returns (uint256) {
    return ((pointsPerShare * getSharesOf(_account)).toInt256() + pointsCorrection[_account]).toUint256() / POINTS_MULTIPLIER;
  }

/* ========  Dividend Utility Functions  ======== */

  /** 
   * @notice Distributes rewards to token holders.
   * @dev It reverts if the total shares is 0.
   * It emits the `RewardsDistributed` event if the amount to distribute is greater than 0.
   * About undistributed rewards:
   *   In each distribution, there is a small amount which does not get distributed,
   *   which is `(amount * POINTS_MULTIPLIER) % totalShares()`.
   *   With a well-chosen `POINTS_MULTIPLIER`, the amount of funds that are not getting
   *   distributed in a distribution can be less than 1 (base unit).
   */
  function _distributeRewards(uint256 _amount) internal {
    uint256 shares = getTotalShares();
    require(shares > 0, "AbstractRewards._distributeRewards: total share supply is zero");

    if (_amount > 0) {
      pointsPerShare = pointsPerShare + (_amount * POINTS_MULTIPLIER / shares);
      emit RewardsDistributed(msg.sender, _amount);
    }
  }

  /**
   * @notice Prepares collection of owed rewards
   * @dev It emits a `RewardsWithdrawn` event if the amount of withdrawn rewards is
   * greater than 0.
   */
  function _prepareCollect(address _account) internal returns (uint256) {
    require(_account != address(0), "AbstractRewards._prepareCollect: account cannot be zero address");

    uint256 _withdrawableDividend = withdrawableRewardsOf(_account);
    if (_withdrawableDividend > 0) {
      withdrawnRewards[_account] = withdrawnRewards[_account] + _withdrawableDividend;
      emit RewardsWithdrawn(_account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(address _from, address _to, uint256 _shares) internal {
    require(_from != address(0), "AbstractRewards._correctPointsForTransfer: address cannot be zero address");
    require(_to != address(0), "AbstractRewards._correctPointsForTransfer: address cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPointsForTransfer: shares cannot be zero");

    int256 _magCorrection = (pointsPerShare * _shares).toInt256();
    pointsCorrection[_from] = pointsCorrection[_from] + _magCorrection;
    pointsCorrection[_to] = pointsCorrection[_to] - _magCorrection;

    emit PointsCorrectionUpdated(_from, pointsCorrection[_from]);
    emit PointsCorrectionUpdated(_to, pointsCorrection[_to]);
  }

  /**
   * @dev Increases or decreases the points correction for `account` by
   * `shares*pointsPerShare`.
   */
  function _correctPoints(address _account, int256 _shares) internal {
    require(_account != address(0), "AbstractRewards._correctPoints: account cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPoints: shares cannot be zero");

    pointsCorrection[_account] = pointsCorrection[_account] + (_shares * (pointsPerShare.toInt256()));
    emit PointsCorrectionUpdated(_account, pointsCorrection[_account]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IBasePool.sol";
import "../interfaces/ITimeLockNonTransferablePool.sol";

import "./AbstractRewards.sol";
import "./TokenSaver.sol";

abstract contract BasePool is ERC20Votes, AbstractRewards, IBasePool, TokenSaver, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    IERC20 public immutable depositToken;
    IERC20 public immutable rewardToken;
    ITimeLockNonTransferablePool public immutable escrowPool;
    uint256 public immutable escrowPortion; // how much is escrowed 1e18 == 100%
    uint256 public immutable escrowDuration; // escrow duration in seconds

    event RewardsClaimed(
        address indexed _from,
        address indexed _receiver,
        uint256 _escrowedAmount,
        uint256 _nonEscrowedAmount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractRewards(balanceOf, totalSupply) {
        require(_escrowPortion <= 1e18, "BasePool.constructor: Cannot escrow more than 100%");
        require(_depositToken != address(0), "BasePool.constructor: Deposit token must be set");
        depositToken = IERC20(_depositToken);
        rewardToken = IERC20(_rewardToken);
        escrowPool = ITimeLockNonTransferablePool(_escrowPool);
        escrowPortion = _escrowPortion;
        escrowDuration = _escrowDuration;

        if (_rewardToken != address(0) && _escrowPool != address(0)) {
            IERC20(_rewardToken).safeApprove(_escrowPool, type(uint256).max);
        }
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
        super._mint(_account, _amount);
        _correctPoints(_account, -(_amount.toInt256()));
    }

    function _burn(address _account, uint256 _amount) internal virtual override {
        super._burn(_account, _amount);
        _correctPoints(_account, _amount.toInt256());
    }

    function _transfer(address _from, address _to, uint256 _value) internal virtual override {
        super._transfer(_from, _to, _value);
        _correctPointsForTransfer(_from, _to, _value);
    }

    function distributeRewards(uint256 _amount) external override nonReentrant {
        rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_amount);
    }

    function claimRewards(address _receiver) external {
        uint256 rewardAmount = _prepareCollect(_msgSender());
        uint256 escrowedRewardAmount = (rewardAmount * escrowPortion) / 1e18;
        uint256 nonEscrowedRewardAmount = rewardAmount - escrowedRewardAmount;

        if (escrowedRewardAmount != 0 && address(escrowPool) != address(0)) {
            escrowPool.deposit(escrowedRewardAmount, escrowDuration, _receiver);
        }

        // ignore dust
        if (nonEscrowedRewardAmount > 1) {
            rewardToken.safeTransfer(_receiver, nonEscrowedRewardAmount);
        }

        emit RewardsClaimed(_msgSender(), _receiver, escrowedRewardAmount, nonEscrowedRewardAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract TokenSaver is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant TOKEN_SAVER_ROLE = keccak256("TOKEN_SAVER_ROLE");

    event TokenSaved(address indexed by, address indexed receiver, address indexed token, uint256 amount);

    modifier onlyTokenSaver() {
        require(hasRole(TOKEN_SAVER_ROLE, _msgSender()), "TokenSaver.onlyTokenSaver: permission denied");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function saveToken(address _token, address _receiver, uint256 _amount) external onlyTokenSaver {
        IERC20(_token).safeTransfer(_receiver, _amount);
        emit TokenSaved(_msgSender(), _receiver, _token, _amount);
    }
}

pragma solidity 0.8.7;

import "./interfaces/ITimeLockNonTransferablePool.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/base/TokenSaver.sol";

contract BatchDeposit is TokenSaver {
    using SafeERC20 for IERC20;

    address public targetPool;
    address public targetToken;

    constructor(address _targetPool, address _targetToken) {
        targetPool = _targetPool;
        targetToken = _targetToken;

        IERC20(targetToken).approve(_targetPool, type(uint256).max);
    }

    function batchDeposit(
        uint256[] memory _amounts,
        uint256[] memory _durations,
        address[] memory _receivers
    ) external {
        require(
            _amounts.length == _durations.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchDeposit: amounts and durations length mismatch"
        );
        require(
            _amounts.length == _receivers.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchDeposit: amounts and receivers length mismatch"
        );

        uint256 sum = 0;

        for (uint256 i = 0; i < _amounts.length; i++) {
            sum += _amounts[i];
        }

        IERC20(targetToken).transferFrom(msg.sender, address(this), sum);

        for (uint256 i = 0; i < _receivers.length; i++) {
            ITimeLockNonTransferablePool(targetPool).deposit(_amounts[i], _durations[i], _receivers[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAbstractRewards {
	/**
	 * @dev Returns the total amount of rewards a given address is able to withdraw.
	 * @param account Address of a reward recipient
	 * @return A uint256 representing the rewards `account` can withdraw
	 */
	function withdrawableRewardsOf(address account) external view returns (uint256);

  /**
	 * @dev View the amount of funds that an address has withdrawn.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has withdrawn.
	 */
	function withdrawnRewardsOf(address account) external view returns (uint256);

	/**
	 * @dev View the amount of funds that an address has earned in total.
	 * accumulativeFundsOf(account) = withdrawableRewardsOf(account) + withdrawnRewardsOf(account)
	 * = (pointsPerShare * balanceOf(account) + pointsCorrection[account]) / POINTS_MULTIPLIER
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has earned in total.
	 */
	function cumulativeRewardsOf(address account) external view returns (uint256);

	/**
	 * @dev This event emits when new funds are distributed
	 * @param by the address of the sender who distributed funds
	 * @param rewardsDistributed the amount of funds received for distribution
	 */
	event RewardsDistributed(address indexed by, uint256 rewardsDistributed);

	/**
	 * @dev This event emits when distributed funds are withdrawn by a token holder.
	 * @param by the address of the receiver of funds
	 * @param fundsWithdrawn the amount of funds that were withdrawn
	 */
	event RewardsWithdrawn(address indexed by, uint256 fundsWithdrawn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBadgeManager {
    function getBadgeMultiplier(address _depositorAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IBasePool {
    function distributeRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITimeLockNonTransferablePool {
    function deposit(uint256 _amount, uint256 _duration, address _receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IBasePool.sol";
import "./base/TokenSaver.sol";

contract LiquidityMiningManager is TokenSaver {
    using SafeERC20 for IERC20;

    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    uint256 public MAX_POOL_COUNT = 10;

    IERC20 public immutable reward;
    address public rewardSource;
    uint256 public rewardPerSecond; //total reward amount per second
    uint256 public lastDistribution; //when rewards were last pushed
    uint256 public totalWeight;

    mapping(address => bool) public poolAdded;
    Pool[] public pools;

    struct Pool {
        IBasePool poolContract;
        uint256 weight;
    }

    modifier onlyGov() {
        require(hasRole(GOV_ROLE, _msgSender()), "LiquidityMiningManager.onlyGov: permission denied");
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()),
            "LiquidityMiningManager.onlyRewardDistributor: permission denied"
        );
        _;
    }

    event PoolAdded(address indexed pool, uint256 weight);
    event PoolRemoved(uint256 indexed poolId, address indexed pool);
    event WeightAdjusted(uint256 indexed poolId, address indexed pool, uint256 newWeight);
    event RewardsPerSecondSet(uint256 rewardsPerSecond);
    event RewardSourceSet(address rewardSource);
    event RewardsDistributed(address _from, uint256 indexed _amount);

    constructor(address _reward, address _rewardSource) {
        require(_reward != address(0), "LiquidityMiningManager.constructor: reward token must be set");
        require(_rewardSource != address(0), "LiquidityMiningManager.constructor: rewardSource address must be set");
        reward = IERC20(_reward);
        rewardSource = _rewardSource;
        emit RewardSourceSet(_rewardSource);
    }

    function addPool(address _poolContract, uint256 _weight) external onlyGov {
        distributeRewards();
        require(_poolContract != address(0), "LiquidityMiningManager.addPool: pool contract must be set");
        require(!poolAdded[_poolContract], "LiquidityMiningManager.addPool: Pool already added");
        require(pools.length < MAX_POOL_COUNT, "LiquidityMiningManager.addPool: Max amount of pools reached");
        // add pool
        pools.push(Pool({ poolContract: IBasePool(_poolContract), weight: _weight }));
        poolAdded[_poolContract] = true;

        // increase totalWeight
        totalWeight += _weight;

        // Approve max token amount
        reward.safeApprove(_poolContract, type(uint256).max);

        emit PoolAdded(_poolContract, _weight);
    }

    function removePool(uint256 _poolId) external onlyGov {
        distributeRewards();
        address poolAddress = address(pools[_poolId].poolContract);

        // decrease totalWeight
        totalWeight -= pools[_poolId].weight;

        // remove pool
        pools[_poolId] = pools[pools.length - 1];
        pools.pop();
        poolAdded[poolAddress] = false;

        // Approve 0 token amount
        reward.safeApprove(poolAddress, 0);

        emit PoolRemoved(_poolId, poolAddress);
    }

    function adjustWeight(uint256 _poolId, uint256 _newWeight) external onlyGov {
        distributeRewards();
        Pool storage pool = pools[_poolId];

        totalWeight -= pool.weight;
        totalWeight += _newWeight;

        pool.weight = _newWeight;

        emit WeightAdjusted(_poolId, address(pool.poolContract), _newWeight);
    }

    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyGov {
        distributeRewards();
        rewardPerSecond = _rewardPerSecond;

        emit RewardsPerSecondSet(_rewardPerSecond);
    }

    function updateRewardSource(address _rewardSource) external onlyGov {
        require(
            _rewardSource != address(0),
            "LiquidityMiningManager.updateRewardSource: rewardSource address must be set"
        );
        distributeRewards();
        rewardSource = _rewardSource;

        emit RewardSourceSet(_rewardSource);
    }

    function distributeRewards() public onlyRewardDistributor {
        uint256 timePassed = block.timestamp - lastDistribution;
        uint256 totalRewardAmount = rewardPerSecond * timePassed;

        lastDistribution = block.timestamp;

        // return if pool length == 0
        if (pools.length == 0) {
            return;
        }

        // return if accrued rewards == 0
        if (totalRewardAmount == 0) {
            return;
        }

        reward.safeTransferFrom(rewardSource, address(this), totalRewardAmount);

        for (uint256 i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            uint256 poolRewardAmount = (totalRewardAmount * pool.weight) / totalWeight;
            // Ignore tx failing to prevent a single pool from halting reward distribution
            address(pool.poolContract).call(
                abi.encodeWithSelector(pool.poolContract.distributeRewards.selector, poolRewardAmount)
            );
        }

        uint256 leftOverReward = reward.balanceOf(address(this));

        // send back excess but ignore dust
        if (leftOverReward > 1) {
            reward.safeTransfer(rewardSource, leftOverReward);
        }

        emit RewardsDistributed(_msgSender(), totalRewardAmount);
    }

    function getPools() external view returns (Pool[] memory result) {
        return pools;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/IAbstractMultiRewards.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev Based on: https://github.com/indexed-finance/dividends/blob/master/contracts/base/AbstractDividends.sol
 * Renamed dividends to rewards.
 * @dev (OLD) Many functions in this contract were taken from this repository:
 * https://github.com/atpar/funds-distribution-token/blob/master/contracts/FundsDistributionToken.sol
 * which is an example implementation of ERC 2222, the draft for which can be found at
 * https://github.com/atpar/funds-distribution-token/blob/master/EIP-DRAFT.md
 *
 * This contract has been substantially modified from the original and does not comply with ERC 2222.
 * Many functions were renamed as "rewards" rather than "funds" and the core functionality was separated
 * into this abstract contract which can be inherited by anything tracking ownership of reward shares.
 */
abstract contract AbstractMultiRewards is IAbstractMultiRewards {
  using SafeCast for uint128;
  using SafeCast for uint256;
  using SafeCast for int256;

/* ========  Constants  ======== */
  uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

  event PointsCorrectionUpdated(address indexed reward, address indexed account, int256 points);

/* ========  Internal Function References  ======== */
  function(address) view returns (uint256) private immutable getSharesOf;
  function() view returns (uint256) private immutable getTotalShares;

/* ========  Storage  ======== */
  mapping(address => uint256) public pointsPerShare; //reward token address => points per share
  mapping(address => mapping(address => int256)) public pointsCorrection; //reward token address => mapping(user address => pointsCorrection)
  mapping(address => mapping(address => uint256)) public withdrawnRewards; //reward token address => mapping(user address => withdrawnRewards)

  constructor(
    function(address) view returns (uint256) getSharesOf_,
    function() view returns (uint256) getTotalShares_
  ) {
    getSharesOf = getSharesOf_;
    getTotalShares = getTotalShares_;
  }

/* ========  Public View Functions  ======== */
  /**
   * @dev Returns the total amount of rewards a given address is able to withdraw.
   * @param _reward Address of the reward token
   * @param _account Address of a reward recipient
   * @return A uint256 representing the rewards `account` can withdraw
   */
  function withdrawableRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return cumulativeRewardsOf(_reward, _account) - withdrawnRewards[_reward][_account];
  }

  /**
   * @notice View the amount of rewards that an address has withdrawn.
   * @param _reward The address of the reward token.
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has withdrawn.
   */
  function withdrawnRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return withdrawnRewards[_reward][_account];
  }

  /**
   * @notice View the amount of rewards that an address has earned in total.
   * @dev accumulativeFundsOf(reward, account) = withdrawableRewardsOf(reward, account) + withdrawnRewardsOf(reward, account)
   * = (pointsPerShare[reward] * balanceOf(account) + pointsCorrection[reward][account]) / POINTS_MULTIPLIER
   * @param _reward The address of the reward token.
   * @param _account The address of a token holder.
   * @return The amount of rewards that `account` has earned in total.
   */
  function cumulativeRewardsOf(address _reward, address _account) public view override returns (uint256) {
    return ((pointsPerShare[_reward] * getSharesOf(_account)).toInt256() + pointsCorrection[_reward][_account]).toUint256() / POINTS_MULTIPLIER;
  }

/* ========  Dividend Utility Functions  ======== */

  /** 
   * @notice Distributes rewards to token holders.
   * @dev It reverts if the total shares is 0.
   * It emits the `RewardsDistributed` event if the amount to distribute is greater than 0.
   * About undistributed rewards:
   *   In each distribution, there is a small amount which does not get distributed,
   *   which is `(amount * POINTS_MULTIPLIER) % totalShares()`.
   *   With a well-chosen `POINTS_MULTIPLIER`, the amount of funds that are not getting
   *   distributed in a distribution can be less than 1 (base unit).
   */
  function _distributeRewards(address _reward, uint256 _amount) internal {
    require(_reward != address(0), "AbstractRewards._distributeRewards: reward cannot be zero address");

    uint256 shares = getTotalShares();
    require(shares > 0, "AbstractRewards._distributeRewards: total share supply is zero");

    if (_amount > 0) {
      pointsPerShare[_reward] = pointsPerShare[_reward] + (_amount * POINTS_MULTIPLIER / shares);
      emit RewardsDistributed(msg.sender, _reward,  _amount);
    }
  }

  /**
   * @notice Prepares collection of owed rewards
   * @dev It emits a `RewardsWithdrawn` event if the amount of withdrawn rewards is
   * greater than 0.
   */
  function _prepareCollect(address _reward, address _account) internal returns (uint256) {
    require(_reward != address(0), "AbstractRewards._prepareCollect: reward cannot be zero address");
    require(_account != address(0), "AbstractRewards._prepareCollect: account cannot be zero address");

    uint256 _withdrawableDividend = withdrawableRewardsOf(_reward, _account);
    if (_withdrawableDividend > 0) {
      withdrawnRewards[_reward][_account] = withdrawnRewards[_reward][_account] + _withdrawableDividend;
      emit RewardsWithdrawn(_reward, _account, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  function _correctPointsForTransfer(address _reward, address _from, address _to, uint256 _shares) internal {
    require(_reward != address(0), "AbstractRewards._correctPointsForTransfer: reward address cannot be zero address");
    require(_from != address(0), "AbstractRewards._correctPointsForTransfer: from address cannot be zero address");
    require(_to != address(0), "AbstractRewards._correctPointsForTransfer: to address cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPointsForTransfer: shares cannot be zero");

    int256 _magCorrection = (pointsPerShare[_reward] * _shares).toInt256();
    pointsCorrection[_reward][_from] = pointsCorrection[_reward][_from] + _magCorrection;
    pointsCorrection[_reward][_to] = pointsCorrection[_reward][_to] - _magCorrection;

    emit PointsCorrectionUpdated(_reward, _from, pointsCorrection[_reward][_from]);
    emit PointsCorrectionUpdated(_reward, _to, pointsCorrection[_reward][_to]);
  }

  /**
   * @dev Increases or decreases the points correction for `account` by
   * `shares*pointsPerShare[reward]`.
   */
  function _correctPoints(address _reward, address _account, int256 _shares) internal {
    require(_reward != address(0), "AbstractRewards._correctPoints: reward cannot be zero address");
    require(_account != address(0), "AbstractRewards._correctPoints: account cannot be zero address");
    require(_shares != 0, "AbstractRewards._correctPoints: shares cannot be zero");

    pointsCorrection[_reward][_account] = pointsCorrection[_reward][_account] + (_shares * (pointsPerShare[_reward].toInt256()));
    emit PointsCorrectionUpdated(_reward, _account, pointsCorrection[_reward][_account]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "contracts/multiRewards/interfaces/IMultiRewardsBasePool.sol";
import "contracts/interfaces/ITimeLockNonTransferablePool.sol";

import "contracts/multiRewards/base/AbstractMultiRewards.sol";
import "contracts/base/TokenSaver.sol";

abstract contract MultiRewardsBasePoolV2 is
    ERC20Votes,
    AbstractMultiRewards,
    IMultiRewardsBasePool,
    TokenSaver,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public immutable depositToken;

    address[] public rewardTokens;
    mapping(address => bool) public rewardTokensList;
    mapping(address => address) public escrowPools;
    mapping(address => uint256) public escrowPortions; // how much is escrowed 1e18 == 100%
    mapping(address => uint256) public escrowDurations; // escrow duration in seconds

    event RewardsClaimed(
        address indexed _reward,
        address indexed _from,
        address indexed _receiver,
        uint256 _escrowedAmount,
        uint256 _nonEscrowedAmount
    );
    event EscrowPoolUpdated(address indexed _reward, address _escrowPool);
    event EscrowPortionUpdated(address indexed _reward, uint256 _portion);
    event EscrowDurationUpdated(address indexed _reward, uint256 _duration);

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations
    ) ERC20Permit(_name) ERC20(_name, _symbol) AbstractMultiRewards(balanceOf, totalSupply) {
        require(_depositToken != address(0), "MultiRewardsBasePoolV2.constructor: Deposit token must be set");
        require(
            _rewardTokens.length == _escrowPools.length,
            "MultiRewardsBasePoolV2.constructor: reward tokens and escrow pools length mismatch"
        );
        require(
            _rewardTokens.length == _escrowPortions.length,
            "MultiRewardsBasePoolV2.constructor: reward tokens and escrow portions length mismatch"
        );
        require(
            _rewardTokens.length == _escrowDurations.length,
            "MultiRewardsBasePoolV2.constructor: reward tokens and escrow durations length mismatch"
        );

        depositToken = IERC20(_depositToken);

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            require(
                rewardToken != address(0),
                "MultiRewardsBasePoolV2.constructor: reward token cannot be zero address"
            );

            address escrowPool = _escrowPools[i];

            uint256 escrowPortion = _escrowPortions[i];
            require(escrowPortion <= 1e18, "MultiRewardsBasePoolV2.constructor: Cannot escrow more than 100%");

            uint256 escrowDuration = _escrowDurations[i];

            if (!rewardTokensList[rewardToken]) {
                rewardTokensList[rewardToken] = true;
                rewardTokens.push(rewardToken);
                escrowPools[rewardToken] = escrowPool;
                escrowPortions[rewardToken] = escrowPortion;
                escrowDurations[rewardToken] = escrowDuration;

                if (escrowPool != address(0)) {
                    IERC20(rewardToken).safeApprove(escrowPool, type(uint256).max);
                }
            }
        }

        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MultiRewardsBasePoolV2: only admin");
        _;
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
        super._mint(_account, _amount);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPoints(reward, _account, -(_amount.toInt256()));
        }
    }

    function _burn(address _account, uint256 _amount) internal virtual override {
        super._burn(_account, _amount);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPoints(reward, _account, _amount.toInt256());
        }
    }

    function _transfer(address _from, address _to, uint256 _value) internal virtual override {
        super._transfer(_from, _to, _value);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPointsForTransfer(reward, _from, _to, _value);
        }
    }

    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function addRewardToken(
        address _reward,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) external onlyAdmin {
        require(_reward != address(0), "MultiRewardsBasePoolV2.addRewardToken: reward token cannot be zero address");
        require(_escrowPortion <= 1e18, "MultiRewardsBasePoolV2.addRewardToken: Cannot escrow more than 100%");

        if (!rewardTokensList[_reward]) {
            rewardTokensList[_reward] = true;
            rewardTokens.push(_reward);
            escrowPools[_reward] = _escrowPool;
            escrowPortions[_reward] = _escrowPortion;
            escrowDurations[_reward] = _escrowDuration;

            if (_reward != address(0) && _escrowPool != address(0)) {
                IERC20(_reward).safeApprove(_escrowPool, type(uint256).max);
            }
        }
    }

    function updateRewardToken(
        address _reward,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) external onlyAdmin {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV2.updateRewardToken: reward token not in the list");
        require(_reward != address(0), "MultiRewardsBasePoolV2.updateRewardToken: reward token cannot be zero address");
        require(_escrowPortion <= 1e18, "MultiRewardsBasePoolV2.updateRewardToken: Cannot escrow more than 100%");

        if (escrowPools[_reward] != _escrowPool && _escrowPool != address(0)) {
            IERC20(_reward).safeApprove(_escrowPool, type(uint256).max);
        }
        escrowPools[_reward] = _escrowPool;
        escrowPortions[_reward] = _escrowPortion;
        escrowDurations[_reward] = _escrowDuration;
    }

    function distributeRewards(address _reward, uint256 _amount) external override nonReentrant {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV2.distributeRewards: reward token not in the list");

        IERC20(_reward).safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_reward, _amount);
    }

    function claimRewards(address _reward, address _receiver) public {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV2.claimRewards: reward token not in the list");

        uint256 rewardAmount = _prepareCollect(_reward, _msgSender());
        uint256 escrowedRewardAmount = (rewardAmount * escrowPortions[_reward]) / 1e18;
        uint256 nonEscrowedRewardAmount = rewardAmount - escrowedRewardAmount;

        ITimeLockNonTransferablePool escrowPool = ITimeLockNonTransferablePool(escrowPools[_reward]);
        if (escrowedRewardAmount != 0 && address(escrowPool) != address(0)) {
            escrowPool.deposit(escrowedRewardAmount, escrowDurations[_reward], _receiver);
        }

        // ignore dust
        if (nonEscrowedRewardAmount > 1) {
            IERC20(_reward).safeTransfer(_receiver, nonEscrowedRewardAmount);
        }

        emit RewardsClaimed(_reward, _msgSender(), _receiver, escrowedRewardAmount, nonEscrowedRewardAmount);
    }

    function claimAll(address _receiver) external {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            claimRewards(reward, _receiver);
        }
    }

    function updateEscrowPool(address _targetRewardToken, address _newEscrowPool) external onlyAdmin {
        require(_newEscrowPool != address(0), "MultiRewardsBasePoolV2.updateEscrowPool: escrowPool must be set");
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV2.updateEscrowPool: reward token not in the list"
        );

        address oldEscrowPool = escrowPools[_targetRewardToken];

        escrowPools[_targetRewardToken] = _newEscrowPool;
        if (_targetRewardToken != address(0) && _newEscrowPool != address(0)) {
            IERC20(_targetRewardToken).safeApprove(oldEscrowPool, 0);
            IERC20(_targetRewardToken).safeApprove(_newEscrowPool, type(uint256).max);
        }

        emit EscrowPoolUpdated(_targetRewardToken, _newEscrowPool);
    }

    function updateEscrowPortion(address _targetRewardToken, uint256 _newEscrowPortion) external onlyAdmin {
        // how much is escrowed 1e18 == 100%
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV2.updateEscrowPortion: reward token not in the list"
        );
        require(_newEscrowPortion <= 1e18, "MultiRewardsBasePoolV2.updateEscrowPortion: cannot escrow more than 100%");

        escrowPortions[_targetRewardToken] = _newEscrowPortion;

        emit EscrowPortionUpdated(_targetRewardToken, _newEscrowPortion);
    }

    function updateEscrowDuration(address _targetRewardToken, uint256 _newDuration) external onlyAdmin {
        // escrow duration in seconds
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV2.updateEscrowDuration: reward token not in the list"
        );

        escrowDurations[_targetRewardToken] = _newDuration;

        emit EscrowDurationUpdated(_targetRewardToken, _newDuration);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/multiRewards/interfaces/IMultiRewardsBasePool.sol";
import "contracts/base/TokenSaver.sol";

contract MultiRewardsLiquidityMiningManagerV2 is TokenSaver {
    using SafeERC20 for IERC20;

    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    uint256 public MAX_POOL_COUNT = 10;

    IERC20 public immutable reward;
    address public rewardSource;
    uint256 public rewardPerSecond; //total reward amount per second
    uint256 public lastDistribution; //when rewards were last pushed
    uint256 public totalWeight;

    uint256 public distributorIncentive; //incentive to distributor
    uint256 public platformFee; //possible fee to build treasury
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public treasury;

    mapping(address => bool) public poolAdded;
    Pool[] public pools;

    struct Pool {
        IMultiRewardsBasePool poolContract;
        uint256 weight;
    }

    modifier onlyGov() {
        require(hasRole(GOV_ROLE, _msgSender()), "MultiRewardsLiquidityMiningManagerV2.onlyGov: permission denied");
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()),
            "MultiRewardsLiquidityMiningManagerV2.onlyRewardDistributor: permission denied"
        );
        _;
    }

    modifier onlyFeeManager() {
        require(
            hasRole(FEE_MANAGER_ROLE, _msgSender()),
            "MultiRewardsLiquidityMiningManagerV2.onlyFeeManager: permission denied"
        );
        _;
    }

    event PoolAdded(address indexed _pool, uint256 _weight);
    event PoolRemoved(uint256 indexed _poolId, address indexed _pool);
    event WeightAdjusted(uint256 indexed _poolId, address indexed _pool, uint256 _newWeight);
    event RewardsPerSecondSet(uint256 _rewardsPerSecond);
    event RewardsDistributed(address indexed _from, uint256 _amount);

    event RewardTokenSet(address _reward);
    event RewardSourceSet(address _rewardSource);
    event DistributorIncentiveSet(uint256 _distributorIncentive);
    event PlatformFeeSet(uint256 _platformFee);
    event TreasurySet(address _treasury);
    event DistributorIncentiveIssued(address indexed _to, uint256 _distributorIncentiveAmount);
    event PlatformFeeIssued(address indexed _to, uint256 _platformFeeAmount);

    constructor(
        address _reward,
        address _rewardSource,
        uint256 _distributorIncentive,
        uint256 _platformFee,
        address _treasury
    ) {
        require(_reward != address(0), "MultiRewardsLiquidityMiningManagerV2.constructor: reward token must be set");
        require(
            _rewardSource != address(0),
            "MultiRewardsLiquidityMiningManagerV2.constructor: rewardSource must be set"
        );
        require(
            _distributorIncentive <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV2.constructor: distributorIncentive cannot be greater than 100%"
        );
        require(
            _platformFee <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV2.constructor: platformFee cannot be greater than 100%"
        );
        if (_platformFee > 0) {
            require(_treasury != address(0), "MultiRewardsLiquidityMiningManagerV2.constructor: treasury must be set");
        }

        reward = IERC20(_reward);
        rewardSource = _rewardSource;
        distributorIncentive = _distributorIncentive;
        platformFee = _platformFee;
        treasury = _treasury;

        emit RewardTokenSet(_reward);
        emit RewardSourceSet(_rewardSource);
        emit DistributorIncentiveSet(_distributorIncentive);
        emit PlatformFeeSet(_platformFee);
        emit TreasurySet(_treasury);
    }

    function setFees(uint256 _distributorIncentive, uint256 _platformFee) external onlyFeeManager {
        require(
            _distributorIncentive <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV2.setFees: distributorIncentive cannot be greater than 100%"
        );
        require(
            _platformFee <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV2.setFees: platformFee cannot be greater than 100%"
        );
        distributorIncentive = _distributorIncentive;
        if (_platformFee > 0) {
            require(treasury != address(0), "MultiRewardsLiquidityMiningManagerV2.setFees: treasury must be set");
        }

        platformFee = _platformFee;

        emit DistributorIncentiveSet(_distributorIncentive);
        emit PlatformFeeSet(_platformFee);
    }

    function setTreasury(address _treasury) external onlyFeeManager {
        treasury = _treasury;

        emit TreasurySet(_treasury);
    }

    function addPool(address _poolContract, uint256 _weight) external onlyGov {
        distributeRewards();
        require(_poolContract != address(0), "MultiRewardsLiquidityMiningManagerV2.addPool: pool contract must be set");
        require(!poolAdded[_poolContract], "MultiRewardsLiquidityMiningManagerV2.addPool: Pool already added");
        require(
            pools.length < MAX_POOL_COUNT,
            "MultiRewardsLiquidityMiningManagerV2.addPool: Max amount of pools reached"
        );
        // add pool
        pools.push(Pool({ poolContract: IMultiRewardsBasePool(_poolContract), weight: _weight }));
        poolAdded[_poolContract] = true;

        // increase totalWeight
        totalWeight += _weight;

        // Approve max token amount
        reward.safeApprove(_poolContract, type(uint256).max);

        emit PoolAdded(_poolContract, _weight);
    }

    function removePool(uint256 _poolId) external onlyGov {
        distributeRewards();
        address poolAddress = address(pools[_poolId].poolContract);

        // decrease totalWeight
        totalWeight -= pools[_poolId].weight;

        // remove pool
        pools[_poolId] = pools[pools.length - 1];
        pools.pop();
        poolAdded[poolAddress] = false;

        // Approve 0 token amount
        reward.safeApprove(poolAddress, 0);

        emit PoolRemoved(_poolId, poolAddress);
    }

    function adjustWeight(uint256 _poolId, uint256 _newWeight) external onlyGov {
        distributeRewards();
        Pool storage pool = pools[_poolId];

        totalWeight -= pool.weight;
        totalWeight += _newWeight;

        pool.weight = _newWeight;

        emit WeightAdjusted(_poolId, address(pool.poolContract), _newWeight);
    }

    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyGov {
        distributeRewards();
        rewardPerSecond = _rewardPerSecond;

        emit RewardsPerSecondSet(_rewardPerSecond);
    }

    function updateRewardSource(address _rewardSource) external onlyGov {
        require(
            _rewardSource != address(0),
            "MultiRewardsLiquidityMiningManagerV2.updateRewardSource: rewardSource address must be set"
        );
        distributeRewards();
        rewardSource = _rewardSource;
        emit RewardSourceSet(_rewardSource);
    }

    function distributeRewards() public onlyRewardDistributor {
        uint256 timePassed = block.timestamp - lastDistribution;
        uint256 totalRewardAmount = rewardPerSecond * timePassed;
        lastDistribution = block.timestamp;

        // return if pool length == 0
        if (pools.length == 0) {
            return;
        }

        // return if accrued rewards == 0
        if (totalRewardAmount == 0) {
            return;
        }

        uint256 platformFeeAmount = (totalRewardAmount * platformFee) / FEE_DENOMINATOR;
        uint256 distributorIncentiveAmount = (totalRewardAmount * distributorIncentive) / FEE_DENOMINATOR;

        reward.safeTransferFrom(
            rewardSource,
            address(this),
            totalRewardAmount + platformFeeAmount + distributorIncentiveAmount
        );

        for (uint256 i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            uint256 poolRewardAmount = (totalRewardAmount * pool.weight) / totalWeight;
            // Ignore tx failing to prevent a single pool from halting reward distribution
            address(pool.poolContract).call(
                abi.encodeWithSelector(pool.poolContract.distributeRewards.selector, address(reward), poolRewardAmount)
            );
        }

        if (treasury != address(0) && treasury != address(this) && platformFeeAmount > 0) {
            reward.safeTransfer(treasury, platformFeeAmount);
            emit PlatformFeeIssued(treasury, platformFeeAmount);
        }

        if (distributorIncentiveAmount > 0) {
            reward.safeTransfer(_msgSender(), distributorIncentiveAmount);
            emit DistributorIncentiveIssued(_msgSender(), distributorIncentiveAmount);
        }

        uint256 leftOverReward = reward.balanceOf(address(this));

        // send back excess but ignore dust
        if (leftOverReward > 1) {
            reward.safeTransfer(rewardSource, leftOverReward);
        }

        emit RewardsDistributed(_msgSender(), totalRewardAmount);
    }

    function getPools() external view returns (Pool[] memory result) {
        return pools;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "contracts/multiRewards/defi/base/MultiRewardsBasePoolV2.sol";
import "contracts/interfaces/ITimeLockNonTransferablePool.sol";

contract MultiRewardsTimeLockNonTransferablePoolV2 is MultiRewardsBasePoolV2, ITimeLockNonTransferablePool {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable maxBonus;
    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;
    uint256 public gracePeriod = 7 days;
    uint256 public kickRewardIncentive = 100;
    uint256 public constant DENOMINATOR = 10000;

    mapping(address => Deposit[]) public depositsOf;

    event GracePeriodUpdated(uint256 _gracePeriod);
    event KickRewardIncentiveUpdated(uint256 _kickRewardIncentive);

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations,
        uint256 _maxBonus,
        uint256 _minLockDuration,
        uint256 _maxLockDuration
    )
        MultiRewardsBasePoolV2(
            _name,
            _symbol,
            _depositToken,
            _rewardTokens,
            _escrowPools,
            _escrowPortions,
            _escrowDurations
        )
    {
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "MultiRewardsTimeLockNonTransferablePoolV2.constructor: min lock duration must be greater or equal to mininmum lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "MultiRewardsTimeLockNonTransferablePoolV2.constructor: max lock duration must be greater or equal to mininmum lock duration"
        );
        maxBonus = _maxBonus;
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
    }

    event Deposited(uint256 amount, uint256 duration, address indexed receiver, address indexed from);
    event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount);

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("NON_TRANSFERABLE");
    }

    function deposit(uint256 _amount, uint256 _duration, address _receiver) external override nonReentrant {
        _deposit(_msgSender(), _amount, _duration, _receiver, false);
    }

    function batchDeposit(
        uint256[] memory _amounts,
        uint256[] memory _durations,
        address[] memory _receivers
    ) external nonReentrant {
        require(
            _amounts.length == _durations.length,
            "MultiRewardsTimeLockNonTransferablePoolV2.batchDeposit: amounts and durations length mismatch"
        );
        require(
            _amounts.length == _receivers.length,
            "MultiRewardsTimeLockNonTransferablePoolV2.batchDeposit: amounts and receivers length mismatch"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            _deposit(_msgSender(), _amounts[i], _durations[i], _receivers[i], false);
        }
    }

    function _deposit(address _depositor, uint256 _amount, uint256 _duration, address _receiver, bool relock) internal {
        require(
            _receiver != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV2._deposit: receiver cannot be zero address"
        );
        require(_amount > 0, "MultiRewardsTimeLockNonTransferablePoolV2._deposit: cannot deposit 0");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        if (!relock) {
            depositToken.safeTransferFrom(_depositor, address(this), _amount);
        }

        depositsOf[_receiver].push(
            Deposit({
                amount: _amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        uint256 mintAmount = (_amount * getMultiplier(duration)) / 1e18;

        _mint(_receiver, mintAmount);
        emit Deposited(_amount, duration, _receiver, _depositor);
    }

    function withdraw(uint256 _depositId, address _receiver) external nonReentrant {
        require(
            _receiver != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV2.withdraw: receiver cannot be zero address"
        );
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];
        require(block.timestamp >= userDeposit.end, "MultiRewardsTimeLockNonTransferablePoolV2.withdraw: too soon");

        // No risk of wrapping around on casting to uint256 since deposit end always > deposit start and types are 64 bits
        uint256 shareAmount = (userDeposit.amount * getMultiplier(uint256(userDeposit.end - userDeposit.start))) / 1e18;

        // remove Deposit
        depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][depositsOf[_msgSender()].length - 1];
        depositsOf[_msgSender()].pop();

        // burn pool shares
        _burn(_msgSender(), shareAmount);

        // return tokens
        depositToken.safeTransfer(_receiver, userDeposit.amount);
        emit Withdrawn(_depositId, _receiver, _msgSender(), userDeposit.amount);
    }

    function kickExpiredDeposit(address _account, uint256 _depositId) external nonReentrant {
        _processExpiredDeposit(_account, _depositId, false, 0);
    }

    function processExpiredLock(uint256 _depositId, uint256 _duration) external nonReentrant {
        _processExpiredDeposit(msg.sender, _depositId, true, _duration);
    }

    function _processExpiredDeposit(address _account, uint256 _depositId, bool relock, uint256 _duration) internal {
        require(
            _account != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV2._processExpiredDeposit: account cannot be zero address"
        );
        Deposit memory userDeposit = depositsOf[_account][_depositId];
        require(
            block.timestamp >= userDeposit.end,
            "MultiRewardsTimeLockNonTransferablePoolV2._processExpiredDeposit: too soon"
        );

        uint256 returnAmount = userDeposit.amount;
        uint256 reward = 0;
        if (block.timestamp >= userDeposit.end + gracePeriod) {
            //penalty
            reward = (userDeposit.amount * kickRewardIncentive) / DENOMINATOR;
            returnAmount -= reward;
        }

        uint256 shareAmount = (userDeposit.amount * getMultiplier(uint256(userDeposit.end - userDeposit.start))) / 1e18;

        // remove Deposit
        depositsOf[_account][_depositId] = depositsOf[_account][depositsOf[_account].length - 1];
        depositsOf[_account].pop();

        // burn pool shares
        _burn(_account, shareAmount);

        if (relock) {
            _deposit(_msgSender(), returnAmount, _duration, _account, true);
        } else {
            depositToken.safeTransfer(_account, returnAmount);
        }

        if (reward > 0) {
            depositToken.safeTransfer(msg.sender, reward);
        }
    }

    function getMultiplier(uint256 _lockDuration) public view returns (uint256) {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    function getTotalDeposit(address _account) public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < depositsOf[_account].length; i++) {
            total += depositsOf[_account][i].amount;
        }

        return total;
    }

    function getDepositsOf(address _account) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(address _account) public view returns (uint256) {
        return depositsOf[_account].length;
    }

    function updateGracePeriod(uint256 _gracePeriod) external onlyAdmin {
        gracePeriod = _gracePeriod;
        emit GracePeriodUpdated(_gracePeriod);
    }

    function updateKickRewardIncentive(uint256 _kickRewardIncentive) external onlyAdmin {
        require(
            _kickRewardIncentive <= DENOMINATOR,
            "MultiRewardsTimeLockNonTransferablePoolV2.updateKickRewardIncentive: kick reward incentive cannot be greater than 100%"
        );
        kickRewardIncentive = _kickRewardIncentive;
        emit KickRewardIncentiveUpdated(_kickRewardIncentive);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/TimeLockNonTransferablePool.sol";
import "contracts/multiRewards/defi/MultiRewardsLiquidityMiningManagerV2.sol";
import "contracts/multiRewards/defi/MultiRewardsTimeLockNonTransferablePoolV2.sol";

/// @dev reader contract to easily fetch all relevant info for an account
contract MultiRewardsViewV2 {
    struct Data {
        uint256 pendingRewards;
        Pool[] pools;
        Pool escrowPool;
        uint256 totalWeight;
    }

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
        uint256 multiplier;
    }

    struct Pool {
        address poolAddress;
        uint256 totalPoolShares;
        address depositToken;
        uint256 accountPendingRewards;
        uint256 accountClaimedRewards;
        uint256 accountTotalDeposit;
        uint256 accountPoolShares;
        uint256 weight;
        Deposit[] deposits;
    }

    MultiRewardsLiquidityMiningManagerV2 public immutable liquidityMiningManager;
    TimeLockNonTransferablePool public immutable escrowPool;

    constructor(address _liquidityMiningManager, address _escrowPool) {
        liquidityMiningManager = MultiRewardsLiquidityMiningManagerV2(_liquidityMiningManager);
        escrowPool = TimeLockNonTransferablePool(_escrowPool);
    }

    function fetchData(address _account) external view returns (Data memory result) {
        uint256 rewardPerSecond = liquidityMiningManager.rewardPerSecond();
        uint256 lastDistribution = liquidityMiningManager.lastDistribution();
        uint256 pendingRewards = rewardPerSecond * (block.timestamp - lastDistribution);

        result.pendingRewards = pendingRewards;
        result.totalWeight = liquidityMiningManager.totalWeight();

        MultiRewardsLiquidityMiningManagerV2.Pool[] memory pools = liquidityMiningManager.getPools();

        result.pools = new Pool[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            MultiRewardsTimeLockNonTransferablePoolV2 poolContract = MultiRewardsTimeLockNonTransferablePoolV2(
                address(pools[i].poolContract)
            );
            address reward = address(liquidityMiningManager.reward());

            result.pools[i] = Pool({
                poolAddress: address(pools[i].poolContract),
                totalPoolShares: poolContract.totalSupply(),
                depositToken: address(poolContract.depositToken()),
                accountPendingRewards: poolContract.withdrawableRewardsOf(reward, _account),
                accountClaimedRewards: poolContract.withdrawnRewardsOf(reward, _account),
                accountTotalDeposit: poolContract.getTotalDeposit(_account),
                accountPoolShares: poolContract.balanceOf(_account),
                weight: pools[i].weight,
                deposits: new Deposit[](poolContract.getDepositsOfLength(_account))
            });

            MultiRewardsTimeLockNonTransferablePoolV2.Deposit[] memory deposits = poolContract.getDepositsOf(_account);

            for (uint256 j = 0; j < result.pools[i].deposits.length; j++) {
                MultiRewardsTimeLockNonTransferablePoolV2.Deposit memory deposit = deposits[j];
                result.pools[i].deposits[j] = Deposit({
                    amount: deposit.amount,
                    start: deposit.start,
                    end: deposit.end,
                    multiplier: poolContract.getMultiplier(deposit.end - deposit.start)
                });
            }
        }

        result.escrowPool = Pool({
            poolAddress: address(escrowPool),
            totalPoolShares: escrowPool.totalSupply(),
            depositToken: address(escrowPool.depositToken()),
            accountPendingRewards: escrowPool.withdrawableRewardsOf(_account),
            accountClaimedRewards: escrowPool.withdrawnRewardsOf(_account),
            accountTotalDeposit: escrowPool.getTotalDeposit(_account),
            accountPoolShares: escrowPool.balanceOf(_account),
            weight: 0,
            deposits: new Deposit[](escrowPool.getDepositsOfLength(_account))
        });

        TimeLockNonTransferablePool.Deposit[] memory deposits = escrowPool.getDepositsOf(_account);

        for (uint256 j = 0; j < result.escrowPool.deposits.length; j++) {
            TimeLockNonTransferablePool.Deposit memory deposit = deposits[j];
            result.escrowPool.deposits[j] = Deposit({
                amount: deposit.amount,
                start: deposit.start,
                end: deposit.end,
                multiplier: escrowPool.getMultiplier(deposit.end - deposit.start)
            });
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/multiRewards/defi/base/MultiRewardsBasePoolV2.sol";

contract TestMultiRewardsBasePoolV2 is MultiRewardsBasePoolV2 {

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations
    ) MultiRewardsBasePoolV2(_name, _symbol, _depositToken, _rewardTokens, _escrowPools, _escrowPortions, _escrowDurations) {
        // silence
    }
    function mint(address _receiver, uint256 _amount) external {
        _mint(_receiver, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract BadgeManager is AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => mapping(uint256 => uint256)) public badgesBoostedMapping; // badge address => id => boosted number (should divided by 1e18)
    mapping(address => mapping(uint256 => bool)) public inBadgesList; // badge address => id => bool

    BadgeData[] public badgesList;

    mapping(address => Delegation[]) public delegationsOfDelegate; // delegate => { owner, badge => { badge address, id } }
    mapping(address => mapping(address => mapping(uint256 => address))) public delegatedListByDelegate; // delegate => badge address => id => owner
    mapping(address => mapping(address => mapping(uint256 => address))) public delegatedListByOwner; //owner => badge address => id => delegator

    mapping(address => bool) public ineligibleList;

    bool public migrationIsOn;

    event BadgeAdded(address indexed _badgeAddress, uint256 _id, uint256 _boostedNumber);
    event BadgeUpdated(address indexed _badgeAddress, uint256 _id, uint256 _boostedNumber);
    event IneligibleListAdded(address indexed _address);
    event IneligibleListRemoved(address indexed _address);

    struct BadgeData {
        address contractAddress;
        uint256 tokenId;
    }

    struct Delegation {
        address owner;
        BadgeData badge;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function getBadgeMultiplier(address _depositorAddress) public view returns (uint256) {
        uint256 badgeMultiplier = 0;

        if (ineligibleList[_depositorAddress]) {
            return badgeMultiplier;
        }

        for (uint256 index = 0; index < delegationsOfDelegate[_depositorAddress].length; index++) {
            Delegation memory delegateBadge = delegationsOfDelegate[_depositorAddress][index];
            BadgeData memory badge = delegateBadge.badge;
            if (IERC1155(badge.contractAddress).balanceOf(delegateBadge.owner, badge.tokenId) > 0) {
                badgeMultiplier = badgeMultiplier + (badgesBoostedMapping[badge.contractAddress][badge.tokenId]);
            }
        }

        return badgeMultiplier;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "BadgeManager: only admin");
        _;
    }

    function delegateBadgeTo(address _badgeContract, uint256 _tokenId, address _delegate) external {
        require(inBadgesList[_badgeContract][_tokenId], "BadgeManager.delegateBadgeTo: invalid badge");

        require(
            IERC1155(_badgeContract).balanceOf(msg.sender, _tokenId) > 0,
            "BadgeManager.delegateBadgeTo: You do not own the badge"
        );

        require(
            delegatedListByOwner[msg.sender][_badgeContract][_tokenId] == address(0),
            "BadgeManager.delegateBadgeTo: already delegated"
        );

        require(
            delegatedListByDelegate[_delegate][_badgeContract][_tokenId] == address(0),
            "BadgeManager.delegateBadgeTo: delegate has already been delegated for the same badge"
        );

        delegationsOfDelegate[_delegate].push(
            Delegation({ owner: msg.sender, badge: BadgeData({ contractAddress: _badgeContract, tokenId: _tokenId }) })
        );

        delegatedListByOwner[msg.sender][_badgeContract][_tokenId] = _delegate;
        delegatedListByDelegate[_delegate][_badgeContract][_tokenId] = msg.sender;
    }

    function addBadge(address _badgeAddress, uint256 _id, uint256 _boostedNumber) external onlyAdmin {
        _addBadge(_badgeAddress, _id, _boostedNumber);
    }

    function batchAddBadges(
        address[] memory _badgeAddresses,
        uint256[] memory _ids,
        uint256[] memory _boostedNumbers
    ) external onlyAdmin {
        require(
            _badgeAddresses.length == _ids.length && _ids.length == _boostedNumbers.length,
            "BadgeManager.batchAddBadge: arrays length mismatch"
        );

        for (uint256 i = 0; i < _badgeAddresses.length; i++) {
            _addBadge(_badgeAddresses[i], _ids[i], _boostedNumbers[i]);
        }
    }

    function _addBadge(address _badgeAddress, uint256 _id, uint256 _boostedNumber) internal {
        require(
            !inBadgesList[_badgeAddress][_id],
            "BadgeManager._addBadge: already in badgelist, please try to update"
        );

        inBadgesList[_badgeAddress][_id] = true;
        badgesList.push(BadgeData({ contractAddress: _badgeAddress, tokenId: _id }));
        badgesBoostedMapping[_badgeAddress][_id] = _boostedNumber;
        emit BadgeAdded(_badgeAddress, _id, _boostedNumber);
    }

    function updateBadge(address _badgeAddress, uint256 _id, uint256 _boostedNumber) external onlyAdmin {
        _updateBadge(_badgeAddress, _id, _boostedNumber);
    }

    function batchUpdateBadges(
        address[] memory _badgeAddresses,
        uint256[] memory _ids,
        uint256[] memory _boostedNumbers
    ) external onlyAdmin {
        require(
            _badgeAddresses.length == _ids.length && _ids.length == _boostedNumbers.length,
            "BadgeManager.batchUpdateBadges: arrays length mismatch"
        );

        for (uint256 i = 0; i < _badgeAddresses.length; i++) {
            _updateBadge(_badgeAddresses[i], _ids[i], _boostedNumbers[i]);
        }
    }

    function _updateBadge(address _badgeAddress, uint256 _id, uint256 _boostedNumber) internal {
        require(
            inBadgesList[_badgeAddress][_id],
            "BadgeManager._updateBadge: badgeAddress not in badgeList, please try to add first"
        );

        badgesBoostedMapping[_badgeAddress][_id] = _boostedNumber;
        emit BadgeUpdated(_badgeAddress, _id, _boostedNumber);
    }

    function addIneligibleList(address _address) external onlyAdmin {
        require(
            !ineligibleList[_address],
            "BadgeManager.addIneligibleList: address already in ineligiblelist, please try to update"
        );
        ineligibleList[_address] = true;
        emit IneligibleListAdded(_address);
    }

    function removeIneligibleList(address _address) external onlyAdmin {
        require(
            ineligibleList[_address],
            "BadgeManager.removeIneligibleList: address not in ineligiblelist, please try to add first"
        );
        ineligibleList[_address] = false;
        emit IneligibleListRemoved(_address);
    }

    function getDelegationsOfDelegate(address _delegate) public view returns (Delegation[] memory) {
        return delegationsOfDelegate[_delegate];
    }

    function getDelegationsOfDelegateLength(address _delegate) public view returns (uint256) {
        return delegationsOfDelegate[_delegate].length;
    }

    function getDelegateByBadge(
        address _owner,
        address _badgeContract,
        uint256 _tokenId
    ) public view returns (address) {
        return delegatedListByOwner[_owner][_badgeContract][_tokenId];
    }

    function getDelegateByBadges(
        address[] memory _ownerAddresses,
        address[] memory _badgeContracts,
        uint256[] memory _tokenIds
    ) public view returns (address[] memory) {
        require(_badgeContracts.length == _tokenIds.length, "BadgeManager.getDelegateByBadges: arrays length mismatch");
        require(_ownerAddresses.length == _tokenIds.length, "BadgeManager.getDelegateByBadges: arrays length mismatch");

        address[] memory delegatedAddresses = new address[](_badgeContracts.length);
        for (uint256 i = 0; i < _badgeContracts.length; i++) {
            delegatedAddresses[i] = delegatedListByOwner[_ownerAddresses[i]][_badgeContracts[i]][_tokenIds[i]];
        }
        return delegatedAddresses;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "contracts/multiRewards/interfaces/IMultiRewardsBasePool.sol";
import "contracts/multiRewards/base/AbstractMultiRewards.sol";
import "contracts/interfaces/ITimeLockNonTransferablePool.sol";
import "contracts/base/TokenSaver.sol";

abstract contract MultiRewardsBasePoolV3 is
    ERC20,
    AbstractMultiRewards,
    IMultiRewardsBasePool,
    TokenSaver,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IERC20 public immutable depositToken;

    address[] public rewardTokens;
    mapping(address => bool) public rewardTokensList;
    mapping(address => address) public escrowPools;
    mapping(address => uint256) public escrowPortions; // how much is escrowed 1e18 == 100%
    mapping(address => uint256) public escrowDurations; // escrow duration in seconds

    mapping(address => uint256) public blacklistAmount;
    uint256 public totalBlacklistAmount;
    mapping(address => bool) public inBlacklist;

    event RewardsClaimed(
        address indexed _reward,
        address indexed _from,
        address indexed _receiver,
        uint256 _escrowedAmount,
        uint256 _nonEscrowedAmount
    );
    event EscrowPoolUpdated(address indexed _reward, address _escrowPool);
    event EscrowPortionUpdated(address indexed _reward, uint256 _portion);
    event EscrowDurationUpdated(address indexed _reward, uint256 _duration);

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations
    ) ERC20(_name, _symbol) AbstractMultiRewards(adjustedBalanceOf, adjustedTotalSupply) {
        require(_depositToken != address(0), "MultiRewardsBasePoolV3.constructor: Deposit token must be set");
        require(
            _rewardTokens.length == _escrowPools.length,
            "MultiRewardsBasePoolV3.constructor: reward tokens and escrow pools length mismatch"
        );
        require(
            _rewardTokens.length == _escrowPortions.length,
            "MultiRewardsBasePoolV3.constructor: reward tokens and escrow portions length mismatch"
        );
        require(
            _rewardTokens.length == _escrowDurations.length,
            "MultiRewardsBasePoolV3.constructor: reward tokens and escrow durations length mismatch"
        );

        depositToken = IERC20(_depositToken);

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            address rewardToken = _rewardTokens[i];
            require(
                rewardToken != address(0),
                "MultiRewardsBasePoolV3.constructor: reward token cannot be zero address"
            );

            address escrowPool = _escrowPools[i];

            uint256 escrowPortion = _escrowPortions[i];
            require(escrowPortion <= 1e18, "MultiRewardsBasePoolV3.constructor: Cannot escrow more than 100%");

            uint256 escrowDuration = _escrowDurations[i];

            if (!rewardTokensList[rewardToken]) {
                rewardTokensList[rewardToken] = true;
                rewardTokens.push(rewardToken);
                escrowPools[rewardToken] = escrowPool;
                escrowPortions[rewardToken] = escrowPortion;
                escrowDurations[rewardToken] = escrowDuration;

                if (escrowPool != address(0)) {
                    IERC20(rewardToken).safeApprove(escrowPool, type(uint256).max);
                }
            }
        }

        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    /// @dev A modifier which checks that the caller has the admin role.
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MultiRewardsBasePoolV3: only admin");
        _;
    }

    function _mint(address _account, uint256 _amount) internal virtual override {
        super._mint(_account, _amount);
        if (!inBlacklist[_account]) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                _correctPoints(reward, _account, -(_amount.toInt256()));
            }
        } else {
            blacklistAmount[_account] += _amount;
            totalBlacklistAmount += _amount;
        }
    }

    function _burn(address _account, uint256 _amount) internal virtual override {
        super._burn(_account, _amount);
        if (!inBlacklist[_account]) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                _correctPoints(reward, _account, _amount.toInt256());
            }
        } else {
            blacklistAmount[_account] -= _amount;
            totalBlacklistAmount -= _amount;
        }
    }

    function _transfer(address _from, address _to, uint256 _value) internal virtual override {
        require(
            !inBlacklist[_from],
            "MultiRewardsBasePoolV3._transfer: cannot transfer token to others if in blacklist"
        );
        require(
            !inBlacklist[_to],
            "MultiRewardsBasePoolV3._transfer: cannot receive token from others if in blacklist"
        );

        super._transfer(_from, _to, _value);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            _correctPointsForTransfer(reward, _from, _to, _value);
        }
    }

    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function addRewardToken(
        address _reward,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) external onlyAdmin {
        require(_reward != address(0), "MultiRewardsBasePoolV3.addRewardToken: reward token cannot be zero address");
        require(_escrowPortion <= 1e18, "MultiRewardsBasePoolV3.addRewardToken: Cannot escrow more than 100%");

        if (!rewardTokensList[_reward]) {
            rewardTokensList[_reward] = true;
            rewardTokens.push(_reward);
            escrowPools[_reward] = _escrowPool;
            escrowPortions[_reward] = _escrowPortion;
            escrowDurations[_reward] = _escrowDuration;

            if (_reward != address(0) && _escrowPool != address(0)) {
                IERC20(_reward).safeApprove(_escrowPool, type(uint256).max);
            }
        }
    }

    function updateRewardToken(
        address _reward,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) external onlyAdmin {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV3.updateRewardToken: reward token not in the list");
        require(_reward != address(0), "MultiRewardsBasePoolV3.updateRewardToken: reward token cannot be zero address");
        require(_escrowPortion <= 1e18, "MultiRewardsBasePoolV3.updateRewardToken: Cannot escrow more than 100%");

        if (escrowPools[_reward] != _escrowPool && _escrowPool != address(0)) {
            IERC20(_reward).safeApprove(_escrowPool, type(uint256).max);
        }
        escrowPools[_reward] = _escrowPool;
        escrowPortions[_reward] = _escrowPortion;
        escrowDurations[_reward] = _escrowDuration;
    }

    function distributeRewards(address _reward, uint256 _amount) external override nonReentrant {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV3.distributeRewards: reward token not in the list");

        IERC20(_reward).safeTransferFrom(_msgSender(), address(this), _amount);
        _distributeRewards(_reward, _amount);
    }

    function claimRewards(address _reward, address _receiver) public virtual {
        require(rewardTokensList[_reward], "MultiRewardsBasePoolV3.claimRewards: reward token not in the list");

        uint256 rewardAmount = _prepareCollect(_reward, _msgSender());
        uint256 escrowedRewardAmount = (rewardAmount * escrowPortions[_reward]) / 1e18;
        uint256 nonEscrowedRewardAmount = rewardAmount - escrowedRewardAmount;

        ITimeLockNonTransferablePool escrowPool = ITimeLockNonTransferablePool(escrowPools[_reward]);
        if (escrowedRewardAmount != 0 && address(escrowPool) != address(0)) {
            escrowPool.deposit(escrowedRewardAmount, escrowDurations[_reward], _receiver);
        }

        // ignore dust
        if (nonEscrowedRewardAmount > 1) {
            IERC20(_reward).safeTransfer(_receiver, nonEscrowedRewardAmount);
        }

        emit RewardsClaimed(_reward, _msgSender(), _receiver, escrowedRewardAmount, nonEscrowedRewardAmount);
    }

    function claimAll(address _receiver) public virtual {
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            address reward = rewardTokens[i];
            claimRewards(reward, _receiver);
        }
    }

    function updateEscrowPool(address _targetRewardToken, address _newEscrowPool) external onlyAdmin {
        require(_newEscrowPool != address(0), "MultiRewardsBasePoolV3.updateEscrowPool: escrowPool must be set");
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV3.updateEscrowPool: reward token not in the list"
        );

        address oldEscrowPool = escrowPools[_targetRewardToken];

        escrowPools[_targetRewardToken] = _newEscrowPool;
        if (_targetRewardToken != address(0) && _newEscrowPool != address(0)) {
            IERC20(_targetRewardToken).safeApprove(oldEscrowPool, 0);
            IERC20(_targetRewardToken).safeApprove(_newEscrowPool, type(uint256).max);
        }

        emit EscrowPoolUpdated(_targetRewardToken, _newEscrowPool);
    }

    function updateEscrowPortion(address _targetRewardToken, uint256 _newEscrowPortion) external onlyAdmin {
        // how much is escrowed 1e18 == 100%
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV3.updateEscrowPortion: reward token not in the list"
        );
        require(_newEscrowPortion <= 1e18, "MultiRewardsBasePoolV3.updateEscrowPortion: cannot escrow more than 100%");

        escrowPortions[_targetRewardToken] = _newEscrowPortion;

        emit EscrowPortionUpdated(_targetRewardToken, _newEscrowPortion);
    }

    function updateEscrowDuration(address _targetRewardToken, uint256 _newDuration) external onlyAdmin {
        // escrow duration in seconds
        require(
            rewardTokensList[_targetRewardToken],
            "MultiRewardsBasePoolV3.updateEscrowDuration: reward token not in the list"
        );

        escrowDurations[_targetRewardToken] = _newDuration;

        emit EscrowDurationUpdated(_targetRewardToken, _newDuration);
    }

    function addBlacklist(address _address) external onlyAdmin {
        require(
            !inBlacklist[_address],
            "MultiRewardsBasePoolV3.addBlacklist: already in blacklist, please try to update"
        );
        inBlacklist[_address] = true;
        blacklistAmount[_address] = super.balanceOf(_address);
        totalBlacklistAmount += super.balanceOf(_address);

        if (super.balanceOf(_address) > 0) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                _correctPoints(reward, _address, super.balanceOf(_address).toInt256());
            }
        }
    }

    function removeBlacklist(address _address) external onlyAdmin {
        require(
            inBlacklist[_address],
            "MultiRewardsBasePoolV3.removeBlacklist: address not in blacklist, please try to add first"
        );
        inBlacklist[_address] = false;

        if (blacklistAmount[_address] > 0) {
            for (uint256 i = 0; i < rewardTokens.length; i++) {
                address reward = rewardTokens[i];
                _correctPoints(reward, _address, -blacklistAmount[_address].toInt256());
            }
        }

        totalBlacklistAmount -= blacklistAmount[_address];
        blacklistAmount[_address] = 0;
    }

    function adjustedTotalSupply() public view returns (uint256) {
        return super.totalSupply() - totalBlacklistAmount;
    }

    function adjustedBalanceOf(address user) public view returns (uint256) {
        if (blacklistAmount[user] > 0) {
            return 0;
        } else {
            return super.balanceOf(user);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/multiRewards/interfaces/IMultiRewardsBasePool.sol";
import "contracts/base/TokenSaver.sol";

contract MultiRewardsLiquidityMiningManagerV3 is TokenSaver {
    using SafeERC20 for IERC20;

    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");
    bytes32 public constant REWARD_DISTRIBUTOR_ROLE = keccak256("REWARD_DISTRIBUTOR_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    uint256 public MAX_POOL_COUNT = 10;

    IERC20 public immutable reward;
    address public rewardSource;
    uint256 public rewardPerSecond; //total reward amount per second
    uint256 public lastDistribution; //when rewards were last pushed
    uint256 public totalWeight;

    uint256 public distributorIncentive; //incentive to distributor
    uint256 public platformFee; //possible fee to build treasury
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public treasury;

    mapping(address => bool) public poolAdded;
    Pool[] public pools;

    struct Pool {
        IMultiRewardsBasePool poolContract;
        uint256 weight;
    }

    modifier onlyGov() {
        require(hasRole(GOV_ROLE, _msgSender()), "MultiRewardsLiquidityMiningManagerV3.onlyGov: permission denied");
        _;
    }

    modifier onlyRewardDistributor() {
        require(
            hasRole(REWARD_DISTRIBUTOR_ROLE, _msgSender()),
            "MultiRewardsLiquidityMiningManagerV3.onlyRewardDistributor: permission denied"
        );
        _;
    }

    modifier onlyFeeManager() {
        require(
            hasRole(FEE_MANAGER_ROLE, _msgSender()),
            "MultiRewardsLiquidityMiningManagerV3.onlyFeeManager: permission denied"
        );
        _;
    }

    event PoolAdded(address indexed _pool, uint256 _weight);
    event PoolRemoved(uint256 indexed _poolId, address indexed _pool);
    event WeightAdjusted(uint256 indexed _poolId, address indexed _pool, uint256 _newWeight);
    event RewardsPerSecondSet(uint256 _rewardsPerSecond);
    event RewardsDistributed(address indexed _from, uint256 _amount);

    event RewardTokenSet(address _reward);
    event RewardSourceSet(address _rewardSource);
    event DistributorIncentiveSet(uint256 _distributorIncentive);
    event PlatformFeeSet(uint256 _platformFee);
    event TreasurySet(address _treasury);
    event DistributorIncentiveIssued(address indexed _to, uint256 _distributorIncentiveAmount);
    event PlatformFeeIssued(address indexed _to, uint256 _platformFeeAmount);

    constructor(
        address _reward,
        address _rewardSource,
        uint256 _distributorIncentive,
        uint256 _platformFee,
        address _treasury
    ) {
        require(_reward != address(0), "MultiRewardsLiquidityMiningManagerV3.constructor: reward token must be set");
        require(
            _rewardSource != address(0),
            "MultiRewardsLiquidityMiningManagerV3.constructor: rewardSource must be set"
        );
        require(
            _distributorIncentive <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV3.constructor: distributorIncentive cannot be greater than 100%"
        );
        require(
            _platformFee <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV3.constructor: platformFee cannot be greater than 100%"
        );
        if (_platformFee > 0) {
            require(_treasury != address(0), "MultiRewardsLiquidityMiningManagerV3.constructor: treasury must be set");
        }

        reward = IERC20(_reward);
        rewardSource = _rewardSource;
        distributorIncentive = _distributorIncentive;
        platformFee = _platformFee;
        treasury = _treasury;

        emit RewardTokenSet(_reward);
        emit RewardSourceSet(_rewardSource);
        emit DistributorIncentiveSet(_distributorIncentive);
        emit PlatformFeeSet(_platformFee);
        emit TreasurySet(_treasury);
    }

    function setFees(uint256 _distributorIncentive, uint256 _platformFee) external onlyFeeManager {
        require(
            _distributorIncentive <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV3.setFees: distributorIncentive cannot be greater than 100%"
        );
        require(
            _platformFee <= FEE_DENOMINATOR,
            "MultiRewardsLiquidityMiningManagerV3.setFees: platformFee cannot be greater than 100%"
        );
        distributorIncentive = _distributorIncentive;
        if (_platformFee > 0) {
            require(treasury != address(0), "MultiRewardsLiquidityMiningManagerV3.setFees: treasury must be set");
        }

        platformFee = _platformFee;

        emit DistributorIncentiveSet(_distributorIncentive);
        emit PlatformFeeSet(_platformFee);
    }

    function setTreasury(address _treasury) external onlyFeeManager {
        treasury = _treasury;

        emit TreasurySet(_treasury);
    }

    function addPool(address _poolContract, uint256 _weight) external onlyGov {
        distributeRewards();
        require(_poolContract != address(0), "MultiRewardsLiquidityMiningManagerV3.addPool: pool contract must be set");
        require(!poolAdded[_poolContract], "MultiRewardsLiquidityMiningManagerV3.addPool: Pool already added");
        require(
            pools.length < MAX_POOL_COUNT,
            "MultiRewardsLiquidityMiningManagerV3.addPool: Max amount of pools reached"
        );
        // add pool
        pools.push(Pool({ poolContract: IMultiRewardsBasePool(_poolContract), weight: _weight }));
        poolAdded[_poolContract] = true;

        // increase totalWeight
        totalWeight += _weight;

        // Approve max token amount
        reward.safeApprove(_poolContract, type(uint256).max);

        emit PoolAdded(_poolContract, _weight);
    }

    function removePool(uint256 _poolId) external onlyGov {
        distributeRewards();
        address poolAddress = address(pools[_poolId].poolContract);

        // decrease totalWeight
        totalWeight -= pools[_poolId].weight;

        // remove pool
        pools[_poolId] = pools[pools.length - 1];
        pools.pop();
        poolAdded[poolAddress] = false;

        // Approve 0 token amount
        reward.safeApprove(poolAddress, 0);

        emit PoolRemoved(_poolId, poolAddress);
    }

    function adjustWeight(uint256 _poolId, uint256 _newWeight) external onlyGov {
        distributeRewards();
        Pool storage pool = pools[_poolId];

        totalWeight -= pool.weight;
        totalWeight += _newWeight;

        pool.weight = _newWeight;

        emit WeightAdjusted(_poolId, address(pool.poolContract), _newWeight);
    }

    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyGov {
        distributeRewards();
        rewardPerSecond = _rewardPerSecond;

        emit RewardsPerSecondSet(_rewardPerSecond);
    }

    function updateRewardSource(address _rewardSource) external onlyGov {
        require(
            _rewardSource != address(0),
            "MultiRewardsLiquidityMiningManagerV3.updateRewardSource: rewardSource address must be set"
        );
        distributeRewards();
        rewardSource = _rewardSource;
        emit RewardSourceSet(_rewardSource);
    }

    function distributeRewards() public onlyRewardDistributor {
        uint256 timePassed = block.timestamp - lastDistribution;
        uint256 totalRewardAmount = rewardPerSecond * timePassed;
        lastDistribution = block.timestamp;

        // return if pool length == 0
        if (pools.length == 0) {
            return;
        }

        // return if accrued rewards == 0
        if (totalRewardAmount == 0) {
            return;
        }

        uint256 platformFeeAmount = (totalRewardAmount * platformFee) / FEE_DENOMINATOR;
        uint256 distributorIncentiveAmount = (totalRewardAmount * distributorIncentive) / FEE_DENOMINATOR;

        reward.safeTransferFrom(
            rewardSource,
            address(this),
            totalRewardAmount + platformFeeAmount + distributorIncentiveAmount
        );

        for (uint256 i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            uint256 poolRewardAmount = (totalRewardAmount * pool.weight) / totalWeight;
            // Ignore tx failing to prevent a single pool from halting reward distribution
            address(pool.poolContract).call(
                abi.encodeWithSelector(pool.poolContract.distributeRewards.selector, address(reward), poolRewardAmount)
            );
        }

        if (treasury != address(0) && treasury != address(this) && platformFeeAmount > 0) {
            reward.safeTransfer(treasury, platformFeeAmount);
            emit PlatformFeeIssued(treasury, platformFeeAmount);
        }

        if (distributorIncentiveAmount > 0) {
            reward.safeTransfer(_msgSender(), distributorIncentiveAmount);
            emit DistributorIncentiveIssued(_msgSender(), distributorIncentiveAmount);
        }

        uint256 leftOverReward = reward.balanceOf(address(this));

        // send back excess but ignore dust
        if (leftOverReward > 1) {
            reward.safeTransfer(rewardSource, leftOverReward);
        }

        emit RewardsDistributed(_msgSender(), totalRewardAmount);
    }

    function getPools() external view returns (Pool[] memory result) {
        return pools;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "contracts/multiRewards/gamefi/base/MultiRewardsBasePoolV3.sol";
import "contracts/interfaces/ITimeLockNonTransferablePool.sol";
import "contracts/interfaces/IBadgeManager.sol";

contract MultiRewardsTimeLockNonTransferablePoolV3 is MultiRewardsBasePoolV3, ITimeLockNonTransferablePool {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable maxBonus;
    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;
    uint256 public gracePeriod = 7 days;
    uint256 public kickRewardIncentive = 0;
    uint256 public constant DENOMINATOR = 10000;

    IBadgeManager public badgeManager;

    mapping(address => Deposit[]) public depositsOf;

    bool public migrationIsOn;

    event Deposited(uint256 amount, uint256 duration, address indexed receiver, address indexed from);
    event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount);
    event MigrationTurnOff(address by);
    event GracePeriodUpdated(uint256 _gracePeriod);
    event KickRewardIncentiveUpdated(uint256 _kickRewardIncentive);
    event BadgeManagerUpdated(address _badgeManager);

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
        uint256 shareAmount;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations,
        uint256 _maxBonus,
        uint256 _minLockDuration,
        uint256 _maxLockDuration,
        address _badgeManager
    )
        MultiRewardsBasePoolV3(
            _name,
            _symbol,
            _depositToken,
            _rewardTokens,
            _escrowPools,
            _escrowPortions,
            _escrowDurations
        )
    {
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "MultiRewardsTimeLockNonTransferablePoolV3.constructor: min lock duration must be greater or equal to mininmum lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "MultiRewardsTimeLockNonTransferablePoolV3.constructor: max lock duration must be greater or equal to mininmum lock duration"
        );
        require(
            _badgeManager != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3.constructor: badge manager cannot be zero address"
        );

        maxBonus = _maxBonus;
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;

        migrationIsOn = true;
        badgeManager = IBadgeManager(_badgeManager);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("NON_TRANSFERABLE");
    }

    function deposit(uint256 _amount, uint256 _duration, address _receiver) external override nonReentrant {
        _deposit(_msgSender(), _amount, _duration, _receiver, false);
    }

    function batchDeposit(
        uint256[] memory _amounts,
        uint256[] memory _durations,
        address[] memory _receivers
    ) external nonReentrant {
        require(
            _amounts.length == _durations.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchDeposit: amounts and durations length mismatch"
        );
        require(
            _amounts.length == _receivers.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchDeposit: amounts and receivers length mismatch"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            _deposit(_msgSender(), _amounts[i], _durations[i], _receivers[i], false);
        }
    }

    function _deposit(address _depositor, uint256 _amount, uint256 _duration, address _receiver, bool relock) internal {
        require(
            _receiver != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3._deposit: receiver cannot be zero address"
        );
        require(_amount > 0, "MultiRewardsTimeLockNonTransferablePoolV3._deposit: cannot deposit 0");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        if (!relock) {
            depositToken.safeTransferFrom(_depositor, address(this), _amount);
        }

        uint256 mintAmount = (_amount * getMultiplier(duration)) / 1e18;
        uint256 badgeBoostingAmount = (_amount * badgeManager.getBadgeMultiplier(_receiver)) / 1e18;
        uint256 shareAmount = mintAmount + badgeBoostingAmount;

        depositsOf[_receiver].push(
            Deposit({
                amount: _amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(duration),
                shareAmount: shareAmount
            })
        );

        _mint(_receiver, shareAmount);
        emit Deposited(_amount, duration, _receiver, _depositor);
    }

    function withdraw(uint256 _depositId, address _receiver) external nonReentrant {
        require(
            _receiver != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3.withdraw: receiver cannot be zero address"
        );
        require(
            _depositId < depositsOf[_msgSender()].length,
            "MultiRewardsTimeLockNonTransferablePoolV3.withdraw: Deposit does not exist"
        );
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];
        require(block.timestamp >= userDeposit.end, "MultiRewardsTimeLockNonTransferablePoolV3.withdraw: too soon");

        // remove Deposit
        depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][depositsOf[_msgSender()].length - 1];
        depositsOf[_msgSender()].pop();

        // burn pool shares
        _burn(_msgSender(), userDeposit.shareAmount);

        // return tokens
        depositToken.safeTransfer(_receiver, userDeposit.amount);
        emit Withdrawn(_depositId, _receiver, _msgSender(), userDeposit.amount);
    }

    function kickExpiredDeposit(address _account, uint256 _depositId) external nonReentrant {
        _processExpiredDeposit(_account, _depositId, false, 0);
    }

    function processExpiredLock(uint256 _depositId, uint256 _duration) external nonReentrant {
        _processExpiredDeposit(msg.sender, _depositId, true, _duration);
    }

    function _processExpiredDeposit(address _account, uint256 _depositId, bool relock, uint256 _duration) internal {
        require(
            _account != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3._processExpiredDeposit: account cannot be zero address"
        );
        Deposit memory userDeposit = depositsOf[_account][_depositId];

        require(
            block.timestamp >= userDeposit.end,
            "MultiRewardsTimeLockNonTransferablePoolV3._processExpiredDeposit: too soon"
        );

        uint256 returnAmount = userDeposit.amount;
        uint256 reward = 0;
        if (block.timestamp >= userDeposit.end + gracePeriod) {
            //penalty
            reward = (userDeposit.amount * kickRewardIncentive) / DENOMINATOR;
            returnAmount -= reward;
        }

        // remove Deposit
        depositsOf[_account][_depositId] = depositsOf[_account][depositsOf[_account].length - 1];
        depositsOf[_account].pop();

        // burn pool shares
        _burn(_account, userDeposit.shareAmount);

        if (relock) {
            _deposit(_msgSender(), returnAmount, _duration, _account, true);
        } else {
            depositToken.safeTransfer(_account, returnAmount);
        }

        if (reward > 0) {
            depositToken.safeTransfer(msg.sender, reward);
        }
    }

    function getMultiplier(uint256 _lockDuration) public view returns (uint256) {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    function getTotalDeposit(address _account) public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < depositsOf[_account].length; i++) {
            total += depositsOf[_account][i].amount;
        }

        return total;
    }

    function getDepositsOf(address _account) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(address _account) public view returns (uint256) {
        return depositsOf[_account].length;
    }

    //==================== ADMIN ONLY FUNCTIONS ====================
    function migrationDeposit(
        uint256 _amount,
        uint64 _start,
        uint64 _end,
        address _receiver
    ) public nonReentrant onlyAdmin {
        _migrationDeposit(_amount, _start, _end, _receiver);
    }

    function batchMigrationDeposit(
        uint256[] memory _amounts,
        uint64[] memory _starts,
        uint64[] memory _ends,
        address[] memory _receivers
    ) external nonReentrant onlyAdmin {
        require(
            _amounts.length == _starts.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchMigrationDeposit: amounts and starts length mismatch"
        );
        require(
            _amounts.length == _ends.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchMigrationDeposit: amounts and ends length mismatch"
        );
        require(
            _amounts.length == _receivers.length,
            "MultiRewardsTimeLockNonTransferablePoolV3.batchMigrationDeposit: amounts and receivers length mismatch"
        );

        for (uint256 i = 0; i < _receivers.length; i++) {
            _migrationDeposit(_amounts[i], _starts[i], _ends[i], _receivers[i]);
        }
    }

    function _migrationDeposit(uint256 _amount, uint64 _start, uint64 _end, address _receiver) internal {
        require(migrationIsOn, "MultiRewardsTimeLockNonTransferablePoolV3._migrationDeposit: only for migration");
        require(
            _receiver != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3._migrationDeposit: receiver cannot be zero address"
        );
        require(_amount > 0, "MultiRewardsTimeLockNonTransferablePoolV3._migrationDeposit: cannot deposit 0");
        require(_end > _start, "MultiRewardsTimeLockNonTransferablePoolV3._migrationDeposit: invalid duration");

        depositToken.safeTransferFrom(_msgSender(), address(this), _amount);

        uint256 duration = _end - _start;
        uint256 mintAmount = (_amount * getMultiplier(duration)) / 1e18;
        uint256 badgeBoostingAmount = (_amount * badgeManager.getBadgeMultiplier(_receiver)) / 1e18;
        uint256 shareAmount = mintAmount + badgeBoostingAmount;

        depositsOf[_receiver].push(Deposit({ amount: _amount, start: _start, end: _end, shareAmount: shareAmount }));

        _mint(_receiver, shareAmount);
        emit Deposited(_amount, duration, _receiver, _msgSender());
    }

    function turnOffMigration() public onlyAdmin {
        require(
            migrationIsOn,
            "MultiRewardsTimeLockNonTransferablePoolV3.turnOffMigration: migration already turned off"
        );
        migrationIsOn = false;
        emit MigrationTurnOff(_msgSender());
    }

    function updateGracePeriod(uint256 _gracePeriod) external onlyAdmin {
        gracePeriod = _gracePeriod;
        emit GracePeriodUpdated(_gracePeriod);
    }

    function updateKickRewardIncentive(uint256 _kickRewardIncentive) external onlyAdmin {
        require(
            _kickRewardIncentive <= DENOMINATOR,
            "MultiRewardsTimeLockNonTransferablePoolV3.updateKickRewardIncentive: kick reward incentive cannot be greater than 100%"
        );
        kickRewardIncentive = _kickRewardIncentive;
        emit KickRewardIncentiveUpdated(_kickRewardIncentive);
    }

    function updateBadgeManager(address _badgeManager) external onlyAdmin {
        require(
            _badgeManager != address(0),
            "MultiRewardsTimeLockNonTransferablePoolV3.updateBadgeManager: badge manager cannot be zero address"
        );
        badgeManager = IBadgeManager(_badgeManager);
        emit BadgeManagerUpdated(_badgeManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/TimeLockNonTransferablePool.sol";
import "contracts/multiRewards/gamefi/MultiRewardsLiquidityMiningManagerV3.sol";
import "contracts/multiRewards/gamefi/MultiRewardsTimeLockNonTransferablePoolV3.sol";

/// @dev reader contract to easily fetch all relevant info for an account
contract MultiRewardsViewV3 {
    struct Data {
        uint256 pendingRewards;
        Pool[] pools;
        Pool escrowPool;
        uint256 totalWeight;
    }

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
        uint256 multiplier;
    }

    struct Pool {
        address poolAddress;
        uint256 totalPoolShares;
        address depositToken;
        uint256 accountPendingRewards;
        uint256 accountClaimedRewards;
        uint256 accountTotalDeposit;
        uint256 accountPoolShares;
        uint256 weight;
        Deposit[] deposits;
    }

    MultiRewardsLiquidityMiningManagerV3 public immutable liquidityMiningManager;
    TimeLockNonTransferablePool public immutable escrowPool;

    constructor(address _liquidityMiningManager, address _escrowPool) {
        liquidityMiningManager = MultiRewardsLiquidityMiningManagerV3(_liquidityMiningManager);
        escrowPool = TimeLockNonTransferablePool(_escrowPool);
    }

    function fetchData(address _account) external view returns (Data memory result) {
        uint256 rewardPerSecond = liquidityMiningManager.rewardPerSecond();
        uint256 lastDistribution = liquidityMiningManager.lastDistribution();
        uint256 pendingRewards = rewardPerSecond * (block.timestamp - lastDistribution);

        result.pendingRewards = pendingRewards;
        result.totalWeight = liquidityMiningManager.totalWeight();

        MultiRewardsLiquidityMiningManagerV3.Pool[] memory pools = liquidityMiningManager.getPools();

        result.pools = new Pool[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            MultiRewardsTimeLockNonTransferablePoolV3 poolContract = MultiRewardsTimeLockNonTransferablePoolV3(
                address(pools[i].poolContract)
            );
            address reward = address(liquidityMiningManager.reward());

            result.pools[i] = Pool({
                poolAddress: address(pools[i].poolContract),
                totalPoolShares: poolContract.totalSupply(),
                depositToken: address(poolContract.depositToken()),
                accountPendingRewards: poolContract.withdrawableRewardsOf(reward, _account),
                accountClaimedRewards: poolContract.withdrawnRewardsOf(reward, _account),
                accountTotalDeposit: poolContract.getTotalDeposit(_account),
                accountPoolShares: poolContract.balanceOf(_account),
                weight: pools[i].weight,
                deposits: new Deposit[](poolContract.getDepositsOfLength(_account))
            });

            MultiRewardsTimeLockNonTransferablePoolV3.Deposit[] memory deposits = poolContract.getDepositsOf(_account);

            for (uint256 j = 0; j < result.pools[i].deposits.length; j++) {
                MultiRewardsTimeLockNonTransferablePoolV3.Deposit memory deposit = deposits[j];
                result.pools[i].deposits[j] = Deposit({
                    amount: deposit.amount,
                    start: deposit.start,
                    end: deposit.end,
                    multiplier: poolContract.getMultiplier(deposit.end - deposit.start)
                });
            }
        }

        result.escrowPool = Pool({
            poolAddress: address(escrowPool),
            totalPoolShares: escrowPool.totalSupply(),
            depositToken: address(escrowPool.depositToken()),
            accountPendingRewards: escrowPool.withdrawableRewardsOf(_account),
            accountClaimedRewards: escrowPool.withdrawnRewardsOf(_account),
            accountTotalDeposit: escrowPool.getTotalDeposit(_account),
            accountPoolShares: escrowPool.balanceOf(_account),
            weight: 0,
            deposits: new Deposit[](escrowPool.getDepositsOfLength(_account))
        });

        TimeLockNonTransferablePool.Deposit[] memory deposits = escrowPool.getDepositsOf(_account);

        for (uint256 j = 0; j < result.escrowPool.deposits.length; j++) {
            TimeLockNonTransferablePool.Deposit memory deposit = deposits[j];
            result.escrowPool.deposits[j] = Deposit({
                amount: deposit.amount,
                start: deposit.start,
                end: deposit.end,
                multiplier: escrowPool.getMultiplier(deposit.end - deposit.start)
            });
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/multiRewards/gamefi/base/MultiRewardsBasePoolV3.sol";

contract TestMultiRewardsBasePoolV3 is MultiRewardsBasePoolV3 {

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address[] memory _rewardTokens,
        address[] memory _escrowPools,
        uint256[] memory _escrowPortions,
        uint256[] memory _escrowDurations
    ) MultiRewardsBasePoolV3(_name, _symbol, _depositToken, _rewardTokens, _escrowPools, _escrowPortions, _escrowDurations) {
        // silence
    }
    function mint(address _receiver, uint256 _amount) external {
        _mint(_receiver, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAbstractMultiRewards {
	/**
	 * @dev Returns the total amount of rewards a given address is able to withdraw.
	 * @param reward Address of the reward token
	 * @param account Address of a reward recipient
	 * @return A uint256 representing the rewards `account` can withdraw
	 */
	function withdrawableRewardsOf(address reward, address account) external view returns (uint256);

  /**
	 * @dev View the amount of funds that an address has withdrawn.
	 * @param reward The address of the reward token.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has withdrawn.
	 */
	function withdrawnRewardsOf(address reward, address account) external view returns (uint256);

	/**
	 * @dev View the amount of funds that an address has earned in total.
	 * accumulativeFundsOf(reward, account) = withdrawableRewardsOf(reward, account) + withdrawnRewardsOf(reward, account)
	 * = (pointsPerShare * balanceOf(account) + pointsCorrection[reward][account]) / POINTS_MULTIPLIER
	 * @param reward The address of the reward token.
	 * @param account The address of a token holder.
	 * @return The amount of funds that `account` has earned in total.
	 */
	function cumulativeRewardsOf(address reward, address account) external view returns (uint256);

	/**
	 * @dev This event emits when new funds are distributed
	 * @param by the address of the sender who distributed funds
	 * @param reward the address of the reward token
	 * @param rewardsDistributed the amount of funds received for distribution
	 */
	event RewardsDistributed(address indexed by, address indexed reward, uint256 rewardsDistributed);

	/**
	 * @dev This event emits when distributed funds are withdrawn by a token holder.
	 * @param reward the address of the reward token
	 * @param by the address of the receiver of funds
	 * @param fundsWithdrawn the amount of funds that were withdrawn
	 */
	event RewardsWithdrawn(address indexed reward, address indexed by, uint256 fundsWithdrawn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
interface IMultiRewardsBasePool {
    function distributeRewards(address _reward, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract ERC721Saver is AccessControlEnumerable {
    bytes32 public constant TOKEN_SAVER_ROLE = keccak256("TOKEN_SAVER_ROLE");

    event ERC721Saved(address indexed by, address indexed receiver, address indexed token, uint256 tokenId);

    modifier onlyTokenSaver() {
        require(hasRole(TOKEN_SAVER_ROLE, _msgSender()), "ERC721Saver.onlyTokenSaver: permission denied");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function saveToken(address _token, address _receiver, uint256 _tokenId) external onlyTokenSaver {
        IERC721(_token).safeTransferFrom(address(this), _receiver, _tokenId);
        emit ERC721Saved(_msgSender(), _receiver, _token, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStakedERC721.sol";
import "./ERC721Saver.sol";

contract ERC721Staking is ReentrancyGuard, ERC721Saver {
    using Math for uint256;

    IERC721 public immutable nft;
    IStakedERC721 public immutable stakedNFT;

    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;

    event NFTStaked(address indexed staker, uint256 tokenId, uint256 duration);
    event NFTUnstaked(address indexed unstaker, uint256 tokenId);

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(
        address _nft,
        address _stakedNFT,
        uint256 _minLockDuration,
        uint256 _maxLockDuration
    ) {
        require(_nft != address(0), "ERC721Staking.constructor: nft cannot be zero address");
        require(_stakedNFT != address(0), "ERC721Staking.constructor: staked nft cannot be zero address");
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "ERC721Staking.constructor: min lock duration must be greater or equal to min lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "ERC721Staking.constructor: max lock duration must be greater or equal to min lock duration"
        );

        nft = IERC721(_nft);
        stakedNFT = IStakedERC721(_stakedNFT);
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
    }

    function stake(uint256 _tokenId, uint256 _duration) external nonReentrant {
        _stake(msg.sender, _tokenId, _duration);
    }

    function _stake(
        address _staker,
        uint256 _tokenId,
        uint256 _duration
    ) internal {
        // Wallet must own the token they are trying to stake
        require(nft.ownerOf(_tokenId) == _staker, "ERC721Staking.stake: You don't own this token!");

        require(block.timestamp + _duration <= type(uint64).max, "ERC721Staking.stake: duration too long");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        // Transfer the token from the wallet to the Smart contract
        nft.transferFrom(_staker, address(this), _tokenId);

        stakedNFT.safeMint(
            _staker,
            _tokenId,
            IStakedERC721.StakedInfo({
                start: uint64(block.timestamp),
                duration: duration,
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        emit NFTStaked(_staker, _tokenId, _duration);
    }

    function unstake(uint256 _tokenId) external nonReentrant {
        require(stakedNFT.ownerOf(_tokenId) == msg.sender, "ERC721Staking.unstake: You don't own this token!");
        nft.transferFrom(address(this), msg.sender, _tokenId);
        stakedNFT.burn(_tokenId);

        emit NFTUnstaked(msg.sender, _tokenId);
    }

    function batchStake(uint256[] memory _tokenIds, uint256[] memory _durations) external nonReentrant {
        require(
            _tokenIds.length == _durations.length,
            "ERC721Staking.batchStake: tokenIds and durations length mismatch"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 duration = _durations[i];
            _stake(msg.sender, tokenId, duration);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStakedERC721.sol";
import "./ERC721Saver.sol";
import "../interfaces/ITimeLockNonTransferablePool.sol";
import "../interfaces/IBasePool.sol";

contract ERC721StakingWithPoint is ReentrancyGuard, ERC721Saver, IBasePool, Ownable {
    using Math for uint256;

    uint128 public constant POINTS_MULTIPLIER = type(uint128).max;

    IERC721 public immutable nft;
    IStakedERC721 public immutable stakedNFT;

    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public immutable maxBonus;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;

    uint256 public totalStakedPower;
    mapping(address => uint256) public userStakedPower;
    uint256 public pointsPerShare;
    mapping(address => uint256) public withdrawnRewards;
    mapping(address => int256) public pointsCorrection;
    mapping(uint256 => uint16) public rarityMapping;

    IERC20 public immutable rewardToken;
    ITimeLockNonTransferablePool public immutable escrowPool;
    uint256 public immutable escrowPortion; // how much is escrowed 1e18 == 100%
    uint256 public immutable escrowDuration; // escrow duration in seconds

    event NFTStaked(address indexed staker, uint256 tokenId, uint256 duration);
    event NFTUnstaked(address indexed unstaker, uint256 tokenId);

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(
        address _nft,
        address _stakedNFT,
        uint256 _minLockDuration,
        uint256 _maxLockDuration,
        uint256 _maxBonus,
        address _rewardToken,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) {
        require(_nft != address(0), "ERC721StakingWithPoint.constructor: nft cannot be zero address");
        require(_stakedNFT != address(0), "ERC721StakingWithPoint.constructor: staked nft cannot be zero address");
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "ERC721StakingWithPoint.constructor: min lock duration must be greater or equal to min lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "ERC721StakingWithPoint.constructor: max lock duration must be greater or equal to min lock duration"
        );

        nft = IERC721(_nft);
        stakedNFT = IStakedERC721(_stakedNFT);
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
        maxBonus = _maxBonus;

        rewardToken = IERC20(_rewardToken);
        escrowPool = ITimeLockNonTransferablePool(_escrowPool);
        escrowPortion = _escrowPortion;
        escrowDuration = _escrowDuration;

        if (_rewardToken != address(0) && _escrowPool != address(0)) {
            IERC20(_rewardToken).approve(_escrowPool, type(uint256).max);
        }
    }

    // a onwer only function to batch set the rarity mapping, for key doent exist, it will create a new one, otherwise it will overwrite the existing one
    function batchSetRarityMapping(uint256[] memory _tokenIds, uint16[] memory _rarity) external onlyOwner {
        require(
            _tokenIds.length == _rarity.length,
            "ERC721StakingWithPoint.batchSetRarityMapping: tokenIds and rarity length mismatch"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            rarityMapping[_tokenIds[i]] = _rarity[i];
        }
    }

    function getRarityMultiplier(uint256 _tokenId) public view returns (uint16) {
        if (rarityMapping[_tokenId] == 0) {
            return 1;
        }

        return rarityMapping[_tokenId];
    }

    function stake(uint256 _tokenId, uint256 _duration) external nonReentrant {
        _stake(msg.sender, _tokenId, _duration);
    }

    function _stake(address _staker, uint256 _tokenId, uint256 _duration) internal {
        // Wallet must own the token they are trying to stake
        require(nft.ownerOf(_tokenId) == _staker, "ERC721StakingWithPoint.stake: You don't own this token!");

        require(block.timestamp + _duration <= type(uint64).max, "ERC721StakingWithPoint.stake: duration too long");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        // Transfer the token from the wallet to the Smart contract
        nft.transferFrom(_staker, address(this), _tokenId);

        stakedNFT.safeMint(
            _staker,
            _tokenId,
            IStakedERC721.StakedInfo({
                start: uint64(block.timestamp),
                duration: duration,
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        uint256 multiplier = getMultiplier(duration);
        uint16 rarityMultiplier = getRarityMultiplier(_tokenId);

        totalStakedPower += multiplier * rarityMultiplier;
        userStakedPower[_staker] += multiplier * rarityMultiplier;
        _correctPoints(_staker, -int256(multiplier * rarityMultiplier));

        emit NFTStaked(_staker, _tokenId, _duration);
    }

    function unstake(uint256 _tokenId) external nonReentrant {
        require(stakedNFT.ownerOf(_tokenId) == msg.sender, "ERC721StakingWithPoint.unstake: You don't own this token!");
        uint256 multiplier = getMultiplier(stakedNFT.stakedInfoOf(_tokenId).duration);
        uint256 rarityMultiplier = getRarityMultiplier(_tokenId);

        nft.transferFrom(address(this), msg.sender, _tokenId);
        stakedNFT.burn(_tokenId);

        totalStakedPower -= multiplier * rarityMultiplier;
        userStakedPower[msg.sender] -= multiplier * rarityMultiplier;
        _correctPoints(msg.sender, int256(multiplier * rarityMultiplier));

        emit NFTUnstaked(msg.sender, _tokenId);
    }

    function batchStake(uint256[] memory _tokenIds, uint256[] memory _durations) external nonReentrant {
        require(
            _tokenIds.length == _durations.length,
            "ERC721StakingWithPoint.batchStake: tokenIds and durations length mismatch"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 duration = _durations[i];
            _stake(msg.sender, tokenId, duration);
        }
    }

    function getMultiplier(uint256 _lockDuration) public view returns (uint256) {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    function distributeRewards(uint256 _amount) external override nonReentrant {
        rewardToken.transferFrom(_msgSender(), address(this), _amount);

        require(totalStakedPower > 0, "total share supply is zero");

        if (_amount > 0) {
            pointsPerShare = pointsPerShare + ((_amount * POINTS_MULTIPLIER) / totalStakedPower);
        }
    }

    function claimRewards(address _receiver) external {
        uint256 rewardAmount = _prepareCollect(_msgSender());
        uint256 escrowedRewardAmount = (rewardAmount * escrowPortion) / 1e18;
        uint256 nonEscrowedRewardAmount = rewardAmount - escrowedRewardAmount;

        if (escrowedRewardAmount != 0 && address(escrowPool) != address(0)) {
            escrowPool.deposit(escrowedRewardAmount, escrowDuration, _receiver);
        }

        // ignore dust
        if (nonEscrowedRewardAmount > 1) {
            rewardToken.transfer(_receiver, nonEscrowedRewardAmount);
        }
    }

    function _prepareCollect(address _account) internal returns (uint256) {
        require(_account != address(0), "AbstractRewards._prepareCollect: account cannot be zero address");

        uint256 _withdrawableDividend = withdrawableRewardsOf(_account);
        if (_withdrawableDividend > 0) {
            withdrawnRewards[_account] = withdrawnRewards[_account] + _withdrawableDividend;
        }
        return _withdrawableDividend;
    }

    function withdrawableRewardsOf(address _account) public view returns (uint256) {
        return cumulativeRewardsOf(_account) - withdrawnRewards[_account];
    }

    function withdrawnRewardsOf(address _account) public view returns (uint256) {
        return withdrawnRewards[_account];
    }

    function cumulativeRewardsOf(address _account) public view returns (uint256) {
        return
            uint256(int256(pointsPerShare * userStakedPower[_account]) + pointsCorrection[_account]) /
            POINTS_MULTIPLIER;
    }

    function _correctPoints(address _account, int256 _shares) internal {
        require(_account != address(0), "AbstractRewards._correctPoints: account cannot be zero address");
        require(_shares != 0, "AbstractRewards._correctPoints: shares cannot be zero");

        pointsCorrection[_account] = pointsCorrection[_account] + (_shares * (int256(pointsPerShare)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IStakedERC721 is IERC721 {
    function disableTransfer() external;
    function enableTransfer() external;
    function safeMint(address to, uint256 tokenId, StakedInfo memory stakedInfo) external;
    function burn(uint256 tokenId) external;
    function stakedInfoOf(uint256 _tokenId) external view returns (StakedInfo memory);

    struct StakedInfo {
        uint64 start;
        uint256 duration;
        uint64 end;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/IStakedERC721.sol";

contract StakedERC721 is IStakedERC721, ERC721Enumerable, AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    mapping(uint256 => StakedInfo) private _stakedInfos;

    bool private _transferrable;
    string private _baseTokenURI;

    event TransferrableUpdated(address updatedBy, bool transferrable);

    constructor(string memory name, string memory symbol, string memory baseTokenURI) 
        ERC721(
            string(abi.encodePacked("Staked", " ", name)), 
            string(abi.encodePacked("S", symbol))
        )
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI;
        _transferrable = false; //default non-transferrable
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "StakedERC721.onlyAdmin: permission denied");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "StakedERC721.onlyMinter: permission denied");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "StakedERC721.onlyBurner: permission denied");
        _;
    }

    function disableTransfer() external override onlyAdmin() {
        _transferrable = false;
        emit TransferrableUpdated(msg.sender, false);
    }

    function enableTransfer() external override onlyAdmin() {
       _transferrable = true;
       emit TransferrableUpdated(msg.sender, true);
    }

    function transferrable() public view virtual returns (bool) {
        return _transferrable;
    }

    function safeMint(address to, uint256 tokenId, StakedInfo memory stakedInfo) 
        public 
        override 
        onlyMinter
    {
        require(
            stakedInfo.end >= stakedInfo.start, 
            "StakedERC721.safeMint: StakedInfo.end must be greater than StakedInfo.start"
        );
        require(
            stakedInfo.duration > 0, 
            "StakedERC721.safeMint: StakedInfo.duration must be greater than 0"
        );
        _stakedInfos[tokenId] = stakedInfo;
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) 
        public 
        override 
        onlyBurner
    {
        StakedInfo storage stakedInfo = _stakedInfos[tokenId];
        require(block.timestamp >= stakedInfo.end, "StakedERC721.burn: Too soon.");
        delete _stakedInfos[tokenId];
        _burn(tokenId);
    }

    function stakedInfoOf(uint256 _tokenId) public view override returns (StakedInfo memory) {
        require(_exists(_tokenId), "StakedERC721.stakedInfoOf: stakedInfo query for the nonexistent token");
        return _stakedInfos[_tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        require(transferrable(), "StakedERC721._transfer: not transferrable");
        super._transfer(from, to, tokenId);
    }

    function setBaseURI(string memory baseTokenURI) external onlyAdmin {
        _baseTokenURI = baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IStakedERC721).interfaceId || super.supportsInterface(interfaceId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        //silence
    }

    function mint(address _receiver, uint256 _tokenId) external {
        _mint(_receiver, _tokenId);
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../base/BasePool.sol";

contract TestBasePool is BasePool {

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration
    ) BasePool(_name, _symbol, _depositToken, _rewardToken, _escrowPool, _escrowPortion, _escrowDuration) {
        // silence
    }
    function mint(address _receiver, uint256 _amount) external {
        _mint(_receiver, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155 {
  constructor() public ERC1155("https://test.com/{id}.json") {
    
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) public {
    _mint(account, id, amount, "");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        //silence
    }

    function mint(address _receiver, uint256 _amount) external {
        _mint(_receiver, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestFaucetToken is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        //silence
    }

    function drip() external {
        _mint(msg.sender, 1000000 ether);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./base/BasePool.sol";
import "./interfaces/ITimeLockNonTransferablePool.sol";

contract TimeLockNonTransferablePool is BasePool, ITimeLockNonTransferablePool {
    using Math for uint256;
    using SafeERC20 for IERC20;

    uint256 public immutable maxBonus;
    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;

    mapping(address => Deposit[]) public depositsOf;

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _depositToken,
        address _rewardToken,
        address _escrowPool,
        uint256 _escrowPortion,
        uint256 _escrowDuration,
        uint256 _maxBonus,
        uint256 _minLockDuration,
        uint256 _maxLockDuration
    ) BasePool(_name, _symbol, _depositToken, _rewardToken, _escrowPool, _escrowPortion, _escrowDuration) {
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "TimeLockNonTransferablePool.constructor: min lock duration must be greater or equal to mininmum lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "TimeLockNonTransferablePool.constructor: max lock duration must be greater or equal to mininmum lock duration"
        );
        maxBonus = _maxBonus;
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
    }

    event Deposited(uint256 amount, uint256 duration, address indexed receiver, address indexed from);
    event Withdrawn(uint256 indexed depositId, address indexed receiver, address indexed from, uint256 amount);

    function _transfer(address _from, address _to, uint256 _amount) internal override {
        revert("NON_TRANSFERABLE");
    }

    function deposit(uint256 _amount, uint256 _duration, address _receiver) external override nonReentrant {
        require(_receiver != address(0), "TimeLockNonTransferablePool.deposit: receiver cannot be zero address");
        require(_amount > 0, "TimeLockNonTransferablePool.deposit: cannot deposit 0");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        depositToken.safeTransferFrom(_msgSender(), address(this), _amount);

        depositsOf[_receiver].push(
            Deposit({
                amount: _amount,
                start: uint64(block.timestamp),
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        uint256 mintAmount = (_amount * getMultiplier(duration)) / 1e18;

        _mint(_receiver, mintAmount);
        emit Deposited(_amount, duration, _receiver, _msgSender());
    }

    function withdraw(uint256 _depositId, address _receiver) external nonReentrant {
        require(_receiver != address(0), "TimeLockNonTransferablePool.withdraw: receiver cannot be zero address");
        Deposit memory userDeposit = depositsOf[_msgSender()][_depositId];
        require(block.timestamp >= userDeposit.end, "TimeLockNonTransferablePool.withdraw: too soon");

        //                      No risk of wrapping around on casting to uint256 since deposit end always > deposit start and types are 64 bits
        uint256 shareAmount = (userDeposit.amount * getMultiplier(uint256(userDeposit.end - userDeposit.start))) / 1e18;

        // remove Deposit
        depositsOf[_msgSender()][_depositId] = depositsOf[_msgSender()][depositsOf[_msgSender()].length - 1];
        depositsOf[_msgSender()].pop();

        // burn pool shares
        _burn(_msgSender(), shareAmount);

        // return tokens
        depositToken.safeTransfer(_receiver, userDeposit.amount);
        emit Withdrawn(_depositId, _receiver, _msgSender(), userDeposit.amount);
    }

    function getMultiplier(uint256 _lockDuration) public view returns (uint256) {
        return 1e18 + ((maxBonus * _lockDuration) / maxLockDuration);
    }

    function getTotalDeposit(address _account) public view returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < depositsOf[_account].length; i++) {
            total += depositsOf[_account][i].amount;
        }

        return total;
    }

    function getDepositsOf(address _account) public view returns (Deposit[] memory) {
        return depositsOf[_account];
    }

    function getDepositsOfLength(address _account) public view returns (uint256) {
        return depositsOf[_account].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./LiquidityMiningManager.sol";
import "./TimeLockNonTransferablePool.sol";

/// @dev reader contract to easily fetch all relevant info for an account
contract View {
    struct Data {
        uint256 pendingRewards;
        Pool[] pools;
        Pool escrowPool;
        uint256 totalWeight;
    }

    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
        uint256 multiplier;
    }

    struct Pool {
        address poolAddress;
        uint256 totalPoolShares;
        address depositToken;
        uint256 accountPendingRewards;
        uint256 accountClaimedRewards;
        uint256 accountTotalDeposit;
        uint256 accountPoolShares;
        uint256 weight;
        Deposit[] deposits;
    }

    LiquidityMiningManager public immutable liquidityMiningManager;
    TimeLockNonTransferablePool public immutable escrowPool;

    constructor(address _liquidityMiningManager, address _escrowPool) {
        liquidityMiningManager = LiquidityMiningManager(_liquidityMiningManager);
        escrowPool = TimeLockNonTransferablePool(_escrowPool);
    }

    function fetchData(address _account) external view returns (Data memory result) {
        uint256 rewardPerSecond = liquidityMiningManager.rewardPerSecond();
        uint256 lastDistribution = liquidityMiningManager.lastDistribution();
        uint256 pendingRewards = rewardPerSecond * (block.timestamp - lastDistribution);

        result.pendingRewards = pendingRewards;
        result.totalWeight = liquidityMiningManager.totalWeight();

        LiquidityMiningManager.Pool[] memory pools = liquidityMiningManager.getPools();

        result.pools = new Pool[](pools.length);

        for (uint256 i = 0; i < pools.length; i++) {
            TimeLockNonTransferablePool poolContract = TimeLockNonTransferablePool(address(pools[i].poolContract));

            result.pools[i] = Pool({
                poolAddress: address(pools[i].poolContract),
                totalPoolShares: poolContract.totalSupply(),
                depositToken: address(poolContract.depositToken()),
                accountPendingRewards: poolContract.withdrawableRewardsOf(_account),
                accountClaimedRewards: poolContract.withdrawnRewardsOf(_account),
                accountTotalDeposit: poolContract.getTotalDeposit(_account),
                accountPoolShares: poolContract.balanceOf(_account),
                weight: pools[i].weight,
                deposits: new Deposit[](poolContract.getDepositsOfLength(_account))
            });

            TimeLockNonTransferablePool.Deposit[] memory deposits = poolContract.getDepositsOf(_account);

            for (uint256 j = 0; j < result.pools[i].deposits.length; j++) {
                TimeLockNonTransferablePool.Deposit memory deposit = deposits[j];
                result.pools[i].deposits[j] = Deposit({
                    amount: deposit.amount,
                    start: deposit.start,
                    end: deposit.end,
                    multiplier: poolContract.getMultiplier(deposit.end - deposit.start)
                });
            }
        }

        result.escrowPool = Pool({
            poolAddress: address(escrowPool),
            totalPoolShares: escrowPool.totalSupply(),
            depositToken: address(escrowPool.depositToken()),
            accountPendingRewards: escrowPool.withdrawableRewardsOf(_account),
            accountClaimedRewards: escrowPool.withdrawnRewardsOf(_account),
            accountTotalDeposit: escrowPool.getTotalDeposit(_account),
            accountPoolShares: escrowPool.balanceOf(_account),
            weight: 0,
            deposits: new Deposit[](escrowPool.getDepositsOfLength(_account))
        });

        TimeLockNonTransferablePool.Deposit[] memory deposits = escrowPool.getDepositsOf(_account);

        for (uint256 j = 0; j < result.escrowPool.deposits.length; j++) {
            TimeLockNonTransferablePool.Deposit memory deposit = deposits[j];
            result.escrowPool.deposits[j] = Deposit({
                amount: deposit.amount,
                start: deposit.start,
                end: deposit.end,
                multiplier: escrowPool.getMultiplier(deposit.end - deposit.start)
            });
        }
    }
}