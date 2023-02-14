// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overridden in child contracts.
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
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// Mateline Contracts (Extendable1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interface/ERC/IERC2981Royalties.sol";
import "../utility/TransferHelper.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC1155PresetMinterPauser is 
    Context, 
    AccessControl, 
    ERC1155Burnable, 
    ERC1155Pausable, 
    ERC1155Supply, 
    IERC2981Royalties 
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // erc2981 royalty fee, /10000
    uint256 public _royalties;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri
    ) ERC1155(uri) {
        _name = name_;
        _symbol = symbol_;
        _royalties = 500; // 5%

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev As 1155 contract name for some dApp which read name from contract, See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev As 1155 contract symbol for some dApp which read symbol from contract, See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev update base token uri, See {IERC1155MetadataURI-uri}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function updateURI(string calldata newuri) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to update");
        _setURI(newuri);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // set royalties
    function setRoyalties(uint256 royalties) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role");
        _royalties = royalties;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (value * _royalties) / 10000;
    }

    // fetch royalty income
    function fetchIncome(address erc20) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role");

        uint256 amount = IERC20(erc20).balanceOf(address(this));
        if(amount > 0) {
            TransferHelper.safeTransfer(erc20, _msgSender(), amount);
        }
    }
    function fetchIncomeEth() external {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role");

        // send eth
        (bool sent, ) = _msgSender().call{value:address(this).balance}("");
        require(sent, "ERC1155PresetMinterPauser: transfer error");
    }
}

contract Extendable1155 is ERC1155PresetMinterPauser {
    
    bytes32 public constant DATA_ROLE = keccak256("DATA_ROLE");

    /**
    * @dev emit when token data section changed

    * @param id 1155 id which data has been changed
    * @param extendData data after change
    */
    event Extendable1155Modify(uint256 indexed id, bytes extendData);

    mapping(uint256=>bytes) _extendDatas;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri) ERC1155PresetMinterPauser(name_, symbol_, uri) 
    {
    }

    /**
    * @dev modify extend 1155 data, emit {Extendable1155Modify} event
    *
    * Requirements:
    * - caller must have general `DATA_ROLE`
    *
    * @param id 1155 id to modify extend data
    * @param extendData extend data in bytes, use a codec to encode or decode the bytes data outside
    */
    function modifyExtendData(
        uint256 id,
        bytes memory extendData
    ) external whenNotPaused {
        require(
            hasRole(DATA_ROLE, _msgSender()),
            "R6"
        );

        require(
            exists(id),
            "E4"
        );

        // modify extend data
        _extendDatas[id] = extendData;

        emit Extendable1155Modify(id, extendData);
    }

    /**
    * @dev get extend 1155 data 
    *
    * @param id 1155 id to get extend data
    * @return extend data in bytes, use a codec to encode or decode the bytes data outside
    */
    function getTokenExtendNftData(uint256 id)
        external
        view
        returns (bytes memory)
    {
        require(exists(id), "E6");

        return _extendDatas[id];
    }

}

// SPDX-License-Identifier: MIT
// Mateline Contracts (ExtendableNFT.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interface/ERC/IERC2981Royalties.sol";
import "../utility/TransferHelper.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControl,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable, 
    IERC2981Royalties
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string internal _baseTokenURI;

    // erc2981 royalty fee, /10000
    uint256 public _royalties;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _royalties = 500; // 5%

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev update base token uri.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function updateURI(string calldata baseTokenURI) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "M1");
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P1");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P2");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // set royalties
    function setRoyalties(uint256 royalties) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "M1");
        _royalties = royalties;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (value * _royalties) / 10000;
    }

    // fetch royalty income
    function fetchIncome(address erc20) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "M1");

        uint256 amount = IERC20(erc20).balanceOf(address(this));
        if(amount > 0) {
            TransferHelper.safeTransfer(erc20, _msgSender(), amount);
        }
    }
    function fetchIncomeEth() external {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role");

        // send eth
        (bool sent, ) = _msgSender().call{value:address(this).balance}("");
        require(sent, "ERC1155PresetMinterPauser: transfer error");
    }
}

/**
 * @dev Extension of {ERC721PresetMinterPauserAutoId} that allows token dynamic extend data section
 */
contract ExtendableNFT is ERC721PresetMinterPauserAutoId {
    
    bytes32 public constant DATA_ROLE = keccak256("DATA_ROLE");
    bytes32 public constant FREEZE_ROLE = keccak256("FREEZE_ROLE");

    /**
    * @dev emit when token has been freezed or unfreeze

    * @param tokenId freezed token id
    * @param freeze freezed or not
    */
    event NFTFreeze(uint256 indexed tokenId, bool freeze);
    
    /**
    * @dev emit when new data section created

    * @param extendName new data section name
    * @param nameBytes data section name after keccak256
    */
    event NFTExtendName(string extendName, bytes32 nameBytes);

    /**
    * @dev emit when token data section changed

    * @param tokenId tokenid which data has been changed
    * @param nameBytes data section name after keccak256
    * @param extendData data after change
    */
    event NFTExtendModify(uint256 indexed tokenId, bytes32 nameBytes, bytes extendData);

    // record of token already extended data section
    struct NFTExtendsNames{
        bytes32[]   NFTExtendDataNames; // array of data sectioin name after keccak256
    }

    // extend data mapping
    struct NFTExtendData {
        bool _exist;
        mapping(uint256 => bytes) ExtendDatas; // tokenid => data mapping
    }

    mapping(uint256 => bool) private _nftFreezed; // tokenid => is freezed
    mapping(uint256 => NFTExtendsNames) private _nftExtendNames; // tokenid => extended data sections
    mapping(bytes32 => NFTExtendData) private _nftExtendDataMap; // extend name => extend datas mapping

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        ERC721PresetMinterPauserAutoId(name, symbol, baseTokenURI) 
    {
    }

    /**
    * @dev freeze token, emit {NFTFreeze} event
    *
    * Requirements:
    * - caller must have `FREEZE_ROLE`
    *
    * @param tokenId token to freeze
    */
    function freeze(uint256 tokenId) external {
        require(hasRole(FREEZE_ROLE, _msgSender()), "R2");

        _nftFreezed[tokenId] = true;

        emit NFTFreeze(tokenId, true);
    }

    /**
    * @dev unfreeze token, emit {NFTFreeze} event
    *
    * Requirements:
    * - caller must have `FREEZE_ROLE`
    *
    * @param tokenId token to unfreeze
    */
    function unfreeze(uint256 tokenId) external {
        require(hasRole(FREEZE_ROLE, _msgSender()), "R3");

        delete _nftFreezed[tokenId];

        emit NFTFreeze(tokenId, false);
    }

    /**
    * @dev check token, return true if not freezed
    *
    * @param tokenId token to check
    * @return ture if token is not freezed
    */
    function notFreezed(uint256 tokenId) public view returns (bool) {
        return !_nftFreezed[tokenId];
    }

    /**
    * @dev check token, return true if it's freezed
    *
    * @param tokenId token to check
    * @return ture if token is freezed
    */
    function isFreezed(uint256 tokenId) public view returns (bool) {
        return _nftFreezed[tokenId];
    }

    /**
    * @dev check token, return true if it exists
    *
    * @param tokenId token to check
    * @return ture if token exists
    */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
    * @dev add new token data section, emit {NFTExtendName} event
    *
    * Requirements:
    * - caller must have `MINTER_ROLE`
    *
    * @param extendName string of new data section name
    */
    function extendNftData(string memory extendName) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "R5");

        bytes32 nameBytes = keccak256(bytes(extendName));
        NFTExtendData storage extendData = _nftExtendDataMap[nameBytes];
        extendData._exist = true;

        emit NFTExtendName(extendName, nameBytes);
    }

    /**
    * @dev add extend token data with specify 'extendName', emit {NFTExtendModify} event
    *
    * Requirements:
    * - caller must have general `DATA_ROLE` or `DATA_ROLE` with the specify `extendName`
    *
    * @param tokenId token to add extend data
    * @param extendName data section name in string
    * @param extendData extend data in bytes, use a codec to encode or decode the bytes data outside
    */
    function addTokenExtendNftData(
        uint256 tokenId,
        string memory extendName,
        bytes memory extendData
    ) external whenNotPaused {
        require(
            hasRole(DATA_ROLE, _msgSender()) ||
                hasRole(
                    keccak256(abi.encodePacked("DATA_ROLE", extendName)),
                    _msgSender()
                ),
            "R6"
        );

        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E1");
        require(!_tokenExtendNameExist(tokenId, nameBytes), "E2");

        // modify extend data
        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        extendDatas.ExtendDatas[tokenId] = extendData;

        // save token extend data names
        NFTExtendsNames storage nftData = _nftExtendNames[tokenId];
        nftData.NFTExtendDataNames.push(nameBytes);

        emit NFTExtendModify(tokenId, nameBytes, extendData);
    }

    /**
    * @dev modify extend token data with specify 'extendName', emit {NFTExtendModify} event
    *
    * Requirements:
    * - caller must have general `DATA_ROLE` or `DATA_ROLE` with the specify `extendName`
    *
    * @param tokenId token to modify extend data
    * @param extendName data section name in string
    * @param extendData extend data in bytes, use a codec to encode or decode the bytes data outside
    */
    function modifyTokenExtendNftData(
        uint256 tokenId,
        string memory extendName,
        bytes memory extendData
    ) external whenNotPaused {
        require(
            hasRole(DATA_ROLE, _msgSender()) ||
                hasRole(
                    keccak256(abi.encodePacked("DATA_ROLE", extendName)),
                    _msgSender()
                ),
            "R6"
        );

        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E4");
        require(_tokenExtendNameExist(tokenId, nameBytes), "E5");

        // modify extend data
        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        extendDatas.ExtendDatas[tokenId] = extendData;

        emit NFTExtendModify(tokenId, nameBytes, extendData);
    }

    /**
    * @dev get extend token data with specify 'extendName'
    *
    * @param tokenId token to get extend data
    * @param extendName data section name in string
    * @return extend data in bytes, use a codec to encode or decode the bytes data outside
    */
    function getTokenExtendNftData(uint256 tokenId, string memory extendName)
        external
        view
        returns (bytes memory)
    {
        bytes32 nameBytes = keccak256(bytes(extendName));
        require(_extendNameExist(nameBytes), "E6");

        NFTExtendData storage extendDatas = _nftExtendDataMap[nameBytes];
        return extendDatas.ExtendDatas[tokenId];
    }

    function _extendNameExist(bytes32 nameBytes) internal view returns (bool) {
        return _nftExtendDataMap[nameBytes]._exist;
    }
    function _tokenExtendNameExist(uint256 tokenId, bytes32 nameBytes) internal view returns(bool) {
        NFTExtendsNames memory nftData = _nftExtendNames[tokenId];
        for(uint i=0; i<nftData.NFTExtendDataNames.length; ++i){
            if(nftData.NFTExtendDataNames[i] == nameBytes){
                return true;
            }
        }
        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(notFreezed(tokenId), "F1");

        super._beforeTokenTransfer(from, to, tokenId);

        if (to == address(0)) {
            // delete token extend datas;
            NFTExtendsNames memory nftData = _nftExtendNames[tokenId];
            for(uint i = 0; i< nftData.NFTExtendDataNames.length; ++i){
                NFTExtendData storage extendData = _nftExtendDataMap[nftData.NFTExtendDataNames[i]];
                delete extendData.ExtendDatas[tokenId];
            }

            // delete token datas
            delete _nftExtendNames[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (HeroNFT.sol)

pragma solidity ^0.8.0;

import "./utility/ResetableCounters.sol";

import "./core/ExtendableNFT.sol";
import "./HeroNFTCodec.sol";

/**
 * @dev Extension of {ExtendableNFT} that with fixed token data struct
 */
contract HeroNFT is ExtendableNFT {
    using ResetableCounters for ResetableCounters.Counter;

    /**
    * @dev emit when new token has been minted, see {HeroNFTDataBase}
    *
    * @param to owner of new token
    * @param tokenId new token id
    * @param data token data see {HeroNFTDataBase}
    */
    event HeroNFTMint(address indexed to, uint256 indexed tokenId, HeroNFTDataBase data);

    ResetableCounters.Counter internal _tokenIdTracker;

    address public _codec;
    address public _attrSource;
    
    mapping(uint256 => HeroNFTDataBase) private _nftDatas; // token id => nft data stucture

    constructor(
        uint256 idStart,
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        ExtendableNFT(name, symbol, baseTokenURI)
    {
       _tokenIdTracker.reset(idStart);

        mint(_msgSender(), HeroNFTDataBase({
            fixedData:0,
            writeableData:0
        })); // mint first token to notify event scan
        
       _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
       _setupRole(DATA_ROLE, _msgSender());
    }

    function setAttrSource(address a) external {
        require(
            hasRole(DATA_ROLE, _msgSender()),
            "R1"
        );

        _attrSource = a;
    }
    function getAttrSource() external view returns(address a) {
        return _attrSource;
    }

    function setCodec(address c) external {
        require(
            hasRole(DATA_ROLE, _msgSender()),
            "R1"
        );

        _codec = c;
    }
    function getCodec() external view returns(address c) {
        return _codec;
    }

    /**
     * @dev Creates a new token for `to`, emit {HeroNFTMint}. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     *
     * @param to new token owner address
     * @param data token data see {HeroNFTDataBase}
     * @return new token id
     */
    function mint(address to, HeroNFTDataBase memory data) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        _nftDatas[curID] = data;

        emit HeroNFTMint(to, curID, data);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }

    /**
     * @dev Creates a new token for `to`, emit {HeroNFTMint}. Its token ID give by caller
     * (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     *
     * @param id new token id
     * @param to new token owner address
     * @param data token data see {HeroNFTDataBase}
     * @return new token id
     */
    function mintFixedID(
        uint256 id,
        address to,
        HeroNFTDataBase memory data
    ) public returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        require(!_exists(id), "RE");

        _mint(to, id);

        // Save token datas
        _nftDatas[id] = data;

        emit HeroNFTMint(to, id, data);

        return id;
    }

    /**
     * @dev modify token data
     *
     * @param tokenId token id
     * @param writeableData token data see {HeroNFTDataBase}
     */
    function modNftData(uint256 tokenId, uint256 writeableData) external {
        require(hasRole(DATA_ROLE, _msgSender()), "R1");

        _nftDatas[tokenId].writeableData = writeableData;
    }

    /**
     * @dev get token data
     *
     * @param tokenId token id
     * @param data token data see {HeroNFTDataBase}
     */
    function getNftData(uint256 tokenId) external view returns(HeroNFTDataBase memory data){
        require(_exists(tokenId), "T1");

        data = _nftDatas[tokenId];
    }

}

// SPDX-License-Identifier: MIT
// Mateline Contracts (HeroNFTCodec.sol)

pragma solidity ^0.8.0;

/**
 * @dev base struct of hero nft data
 */
struct HeroNFTDataBase
{
    uint256 fixedData;
    uint256 writeableData;
}

/**
 * @dev hero fixed nft data version 1
 */
struct HeroNFTFixedData_V1 {
    uint8 job;
    uint8 grade;

    uint16 minerAttr;
    uint16 battleAttr;
}

/**
 * @dev hero writeable nft data version 1
 */
struct HeroNFTWriteableData_V1 {
    uint8 starLevel;
    uint16 level;
    uint64 exp;
}


/**
 * @dev hero nft data codec interface
 */
interface IHeroNFTCodec_V1 {

    /**
    * @dev encode HeroNFTFixedData to HeroNFTDataBase
    * @param data input data of HeroNFTFixedData_V1
    * @return basedata output data of HeroNFTDataBase
    */
    function fromHeroNftFixedData(HeroNFTFixedData_V1 memory data) external pure returns (HeroNFTDataBase memory basedata);

    /**
    * @dev encode HeroNFTFixedData to HeroNFTDataBase
    * @param fdata input data of HeroNFTFixedData_V1
    * @param wdata input data of HeroNFTWriteableData_V1
    * @return basedata output data of HeroNFTDataBase
    */
    function fromHeroNftFixedAnWriteableData(HeroNFTFixedData_V1 memory fdata, HeroNFTWriteableData_V1 memory wdata) external pure returns (HeroNFTDataBase memory basedata);

    /**
    * @dev decode HeroNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroNFTFixedData_V1
    */
    function getHeroNftFixedData(HeroNFTDataBase memory data) external pure returns(HeroNFTFixedData_V1 memory hndata);

    /**
    * @dev decode HeroNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroNFTWriteableData_V1
    */
    function getHeroNftWriteableData(HeroNFTDataBase memory data) external pure returns(HeroNFTWriteableData_V1 memory hndata);

    /**
    * @dev get character id from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return characterId character id
    */
    function getCharacterId(HeroNFTDataBase memory data) external pure returns (uint16 characterId);
}

/**
 * @dev hero nft data codec v1 implement
 */
contract HeroNFTCodec_V1 is IHeroNFTCodec_V1 {

    function fromHeroNftFixedData(HeroNFTFixedData_V1 memory data)
        external
        pure
        override
        returns (HeroNFTDataBase memory basedata)
    {
        basedata.fixedData =
            uint256(data.job) |
            (uint256(data.grade) << 8) |
            (uint256(data.minerAttr) << (8 + 8)) |
            (uint256(data.battleAttr) << (8 + 8 + 16));

        basedata.writeableData = 0;
    }

    function fromHeroNftFixedAnWriteableData(HeroNFTFixedData_V1 memory fdata, HeroNFTWriteableData_V1 memory wdata) 
        external 
        pure 
        override 
        returns (HeroNFTDataBase memory basedata)
    {
        basedata.fixedData =
            uint256(fdata.job) |
            (uint256(fdata.grade) << 8) |
            (uint256(fdata.minerAttr) << (8 + 8)) |
            (uint256(fdata.battleAttr) << (8 + 8 + 16));

        basedata.writeableData = 
            (uint256(wdata.starLevel)) |
            (uint256(wdata.level << 8)) |
            (uint256(wdata.exp << (8 + 16)));
    }

    function getHeroNftFixedData(HeroNFTDataBase memory data)
        external
        pure
        override
        returns (HeroNFTFixedData_V1 memory hndata)
    {
        hndata.job = uint8(data.fixedData & 0xff);
        hndata.grade = uint8((data.fixedData >> 8) & 0xff);
        hndata.minerAttr = uint16((data.fixedData >> (8 + 8)) & 0xffff);
        hndata.battleAttr = uint16((data.fixedData >> (8 + 8 + 16)) & 0xffff);
    }

    function getHeroNftWriteableData(HeroNFTDataBase memory data) 
        external 
        pure 
        override 
        returns(HeroNFTWriteableData_V1 memory hndata)
    {
        hndata.starLevel = uint8(data.writeableData & 0xff);
        hndata.level = uint16((data.writeableData >> 8) & 0xffff);
        hndata.exp = uint64((data.writeableData >> 8 + 16) & 0xffffffffffffffff);
    }

    function getCharacterId(HeroNFTDataBase memory data) 
        external 
        pure 
        override
        returns (uint16 characterId) 
    {
        return uint16(data.fixedData & 0xffff); // job << 8 | grade;
    }
}

// SPDX-License-Identifier: MIT
// DreamIdol Contracts (HeroNFTMysteryBox.sol)

pragma solidity ^0.8.0;

import "./HeroNFTCodec.sol";
import "./HeroNFT.sol";
import "./mysterybox/MBRandomSourceBase.sol";
import "./mysterybox/MysteryBoxBase.sol";

contract HeroNFTMysteryBoxRandSource is 
    MBRandomSourceBase
{
    using RandomPoolLib for RandomPoolLib.RandomPool;

    HeroNFT public _heroNFTContract;
    
    constructor(address heroNftAddr)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        _heroNFTContract = HeroNFT(heroNftAddr);
    }

    function randomAndMint(uint256 r, uint32 mysteryTp, address to) virtual override external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "ownership error");

        uint32[] storage poolIDArray = _mbRandomSets[mysteryTp];

        require(poolIDArray.length == 17, "mb type config wrong");

        HeroNFTDataBase memory baseData = _getSingleRandHero(r, poolIDArray);

        // mint 
        uint256 newId = _heroNFTContract.mint(to, baseData);

        nfts = new MBContentMinterNftInfo[](1); // 1 nft
        sfts = new MBContentMinter1155Info[](0); // no sft

        nfts[0] = MBContentMinterNftInfo({
            addr : address(_heroNFTContract),
            tokenIds : new uint256[](1)
        });
        nfts[0].tokenIds[0] = newId;
    }

    function _getSingleRandHero(
        uint256 r,
        uint32[] storage poolIDArray
    ) internal view returns (HeroNFTDataBase memory baseData)
    {
        uint32 index = 0;
        
        NFTRandPool storage pool = _randPools[poolIDArray[0]]; // index 0 : job rand (1-10)
        require(pool.exist, "job pool not exist");
        uint8 job = uint8(pool.randPool.random(r));

        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[1]]; // index 1 : grade rand (1-5)
        require(pool.exist, "grade pool not exist");
        uint8 grade = uint8(pool.randPool.random(r));

        if(job <= 8){
            pool = _randPools[poolIDArray[1 + grade]]; // index 2-6 : job(1-8) mineAttr rand by grade
        }
        else{
            pool = _randPools[poolIDArray[6 + grade]]; // index 7-11 : job(9-10) mineAttr rand by grade
        }
        r = _rand.nextRand(++index, r);
        require(pool.exist, "mineAttr pool not exist");
        uint16 mineAttr = uint8(pool.randPool.random(r));

        pool = _randPools[poolIDArray[11 + grade]]; // index 12-16 : battleAttr rand by grade
        r = _rand.nextRand(++index, r);
        require(pool.exist, "battleAttr pool not exist");
        uint16 battleAttr = uint8(pool.randPool.random(r));

        HeroNFTFixedData_V1 memory fdata = HeroNFTFixedData_V1({
            job : job,
            grade : grade,
            minerAttr : mineAttr,
            battleAttr : battleAttr
        });

        HeroNFTWriteableData_V1 memory wdata = HeroNFTWriteableData_V1({
            starLevel: 0,
            level : 1,
            exp : 0
        });

        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(_heroNFTContract.getCodec());
        baseData = codec.fromHeroNftFixedAnWriteableData(fdata, wdata);
    }

    function batchRandomAndMint(uint256 r, uint32 mysteryTp, address to, uint8 batchCount) virtual override external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "ownership error");

        uint32[] storage poolIDArray = _mbRandomSets[mysteryTp];

        require(poolIDArray.length == 17, "mb type config wrong");

        nfts = new MBContentMinterNftInfo[](1); // 1 nft
        sfts = new MBContentMinter1155Info[](0); // no sft record

        nfts[0] = MBContentMinterNftInfo({
            addr : address(_heroNFTContract),
            tokenIds : new uint256[](batchCount)
        });

        for(uint8 i=0; i< batchCount; ++i)
        {
            r = _rand.nextRand(i, r);
            HeroNFTDataBase memory baseData = _getSingleRandHero(r, poolIDArray);

            // mint 
            uint256 newId = _heroNFTContract.mint(to, baseData);

            nfts[0].tokenIds[i] = newId;
        }
    }
}

contract HeroNFTMysteryBox is MysteryBoxBase
{    
    function getName() external virtual override returns(string memory)
    {
        return "Hero NFT Mystery Box";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (MBRandomSourceBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../utility/Random.sol";
import "../utility/RandomPoolLib.sol";

struct MBContentMinter1155Info {
    address addr;
    uint256[] tokenIds;
    uint256[] tokenValues;
}
struct MBContentMinterNftInfo {
    address addr;
    uint256[] tokenIds;
}

abstract contract MBRandomSourceBase is 
    Context, 
    AccessControl
{
    using RandomPoolLib for RandomPoolLib.RandomPool;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RANDOM_ROLE = keccak256("RANDOM_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct NFTRandPool{
        bool exist;
        RandomPoolLib.RandomPool randPool;
    }

    Random _rand;
    mapping(uint32 => NFTRandPool)    _randPools; // poolID => nft data random pools
    mapping(uint32 => uint32[])       _mbRandomSets; // mystery type => poolID array

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RANDOM_ROLE, _msgSender());
    }

    function setRandSource(address randAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()));

        _rand = Random(randAddr);
    }

    function getRandSource() external view returns(address) {
        // require(hasRole(MANAGER_ROLE, _msgSender()));
        return address(_rand);
    }
    function _addPool(uint32 poolID, RandomPoolLib.RandomSet[] memory randSetArray) internal {
        NFTRandPool storage rp = _randPools[poolID];

        rp.exist = true;
        for(uint i=0; i<randSetArray.length; ++i){
            rp.randPool.pool.push(randSetArray[i]);
        }

        rp.randPool.initRandomPool();
    }

    function addPool(uint32 poolID, RandomPoolLib.RandomSet[] memory randSetArray) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(!_randPools[poolID].exist,"rand pool already exist");

        _addPool(poolID, randSetArray);
    }

    function modifyPool(uint32 poolID, RandomPoolLib.RandomSet[] memory randSetArray) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(_randPools[poolID].exist,"rand pool not exist");

        NFTRandPool storage rp = _randPools[poolID];

        delete rp.randPool.pool;

        for(uint i=0; i<randSetArray.length; ++i){
            rp.randPool.pool.push(randSetArray[i]);
        }

        rp.randPool.initRandomPool();
    }

    function removePool(uint32 poolID) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        require(_randPools[poolID].exist, "rand pool not exist");

        delete _randPools[poolID];
    }

    function getPool(uint32 poolID) public view returns(NFTRandPool memory) {
        require(_randPools[poolID].exist, "rand pool not exist");

        return _randPools[poolID];
    }

    function hasPool(uint32 poolID) external view returns(bool){
          return (_randPools[poolID].exist);
    }

    function setRandomSet(uint32 mbTypeID, uint32[] calldata poolIds) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");
        delete _mbRandomSets[mbTypeID];
        uint32[] storage poolIDArray = _mbRandomSets[mbTypeID];
        for(uint i=0; i< poolIds.length; ++i){
            poolIDArray.push(poolIds[i]);
        }
    }
    function unsetRandomSet(uint32 mysteryTp) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not a manager");

        delete _mbRandomSets[mysteryTp];
    }
    function getRandomSet(uint32 mysteryTp) external view returns(uint32[] memory poolIds) {
        return _mbRandomSets[mysteryTp];
    }
    
    function randomAndMint(uint256 r, uint32 mysteryTp, address to) virtual external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts);

    function batchRandomAndMint(uint256 r, uint32 mysteryTp, address to, uint8 batchCount) virtual external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts);
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (MysteryBox1155.sol)

pragma solidity ^0.8.0;

import "../core/Extendable1155.sol";

// 1155 id : combine with randomType(uint32) << 32 | mysteryType(uint32)
contract MysteryBox1155 is Extendable1155 {

    constructor(string memory uri) Extendable1155("MetaLine MysteryBox Semi-fungible Token", "MLMB", uri) {
        mint(_msgSender(), 0, 1, new bytes(0)); // mint first token to notify event scan
    }
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (MysteryBoxBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../utility/GasFeeCharger.sol";

import "./MysteryBox1155.sol";
import "./MBRandomSourceBase.sol";

abstract contract MysteryBoxBase is 
    Context, 
    Pausable, 
    AccessControl,
    IOracleRandComsumer
{
    using GasFeeCharger for GasFeeCharger.MethodExtraFees;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RAND_ROLE = keccak256("RAND_ROLE");

    event OracleOpenMysteryBox(uint256 oracleRequestId, uint256 indexed mbTokenId, address indexed owner);
    event OpenMysteryBox(address indexed owner, uint256 indexed mbTokenId, MBContentMinter1155Info[] sfts, MBContentMinterNftInfo[] nfts);

    event BatchOracleOpenMysteryBox(uint256 oracleRequestId, uint256 indexed mbTokenId, address indexed owner, uint8 batchCount);
    event BatchOpenMysteryBox(address indexed owner, uint256 indexed mbTokenId, MBContentMinter1155Info[] sfts, MBContentMinterNftInfo[] nfts);

    struct UserData{
        address owner;
        uint32 randomType;
        uint32 mysteryType;
        uint8 count;
        uint256 tokenId;
    }
    
    MysteryBox1155 public _mb1155;
    
    mapping(uint32=>address) _randomSources; // random type => random source
    mapping(uint256 => UserData) public _oracleUserData; // indexed by oracle request id

    // Method extra fee
    // For smart contract method which need extra transaction by other service, we define extra fee
    // extra fee charge by method call tx with `value` paramter, and send to target service wallet address
    GasFeeCharger.MethodExtraFees _methodExtraFees;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RAND_ROLE, _msgSender());
    }

    function getName() external virtual returns(string memory);

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MysteryBox: must have pauser role to pause");
        _pause();
    }
    
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "MysteryBox: must have pauser role to unpause");
        _unpause();
    }

    function setNftAddress(address nftAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBox: must have manager role to manage");
        _mb1155 = MysteryBox1155(nftAddr);
    }

    function getNftAddress() external view returns(address) {
        return address(_mb1155);
    }

    function setRandomSource(uint32 randomType, address randomSrc) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBox: must have manager role to manage");
        _randomSources[randomType] = randomSrc;
    }

    function getRandomSource(uint32 randomType) external view returns(address){
        return _randomSources[randomType];
    }

    /**
    * @dev set smart contract method invoke by transaction with extra fee
    *
    * Requirements:
    * - caller must have `MANAGER_ROLE`
    *
    * @param methodKey key of which method need extra fee
    * @param value extra fee value
    * @param target target address where extra fee goes to
    */
    function setMethodExtraFee(uint8 methodKey, uint256 value, address target) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "MysteryBox: must have manager role"
        );

        _methodExtraFees.setMethodExtraFee(methodKey, value, target);
    }

    /**
    * @dev cancel smart contract method invoke by transaction with extra fee
    *
    * Requirements:
    * - caller must have `MANAGER_ROLE`
    *
    * @param methodKey key of which method need cancel extra fee
    */
    function removeMethodExtraFee(uint8 methodKey) external {
        require(
            hasRole(MANAGER_ROLE, _msgSender()),
            "MysteryBox: must have manager role"
        );

        _methodExtraFees.removeMethodExtraFee(methodKey);
    }

    /**
    * @dev open mystery box, emit {OracleOpenMysteryBox}
    * call `oracleRand` in {Random} of address from `getRandSource` in {MBRandomSource}
    * send a oracle random request and emit {OracleRandRequest}
    *
    * Extrafees:
    * - `oracleOpenMysteryBox` call need charge extra fee for `fulfillRandom` in {Random} call by oracle service
    * - methodKey = 1, extra gas fee = 0.0013 with tx.value needed
    *
    * Requirements:
    * - caller must out side contract, not from contract
    * - caller must owner of `tokenId` in {MysteryBox1155}
    * - contract not paused
    *
    * @param tokenId token id of {MysteryBox1155}, if succeed, token will be burned
    */
    function oracleOpenMysteryBox(uint256 tokenId) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "MysteryBox: only for outside account");
        require(_mb1155.balanceOf(_msgSender(), tokenId) >= 1, "MysteryBox: insufficient mb");

        // check mb 1155 type
        uint32 randomType = (uint32)((tokenId >> 32) & 0xffffffff);
        address randSrcAddr = _randomSources[randomType];
        require(randSrcAddr != address(0), "MysteryBox: not a mystry box");
        
        address rndAddr = MBRandomSourceBase(randSrcAddr).getRandSource();
        require(rndAddr != address(0), "MysteryBox: rand address wrong");

        _methodExtraFees.chargeMethodExtraFee(1); // charge oracleOpenMysteryBox extra fee

        _mb1155.burn(_msgSender(), tokenId, 1);

        uint256 reqid = Random(rndAddr).oracleRand();

        UserData storage userData = _oracleUserData[reqid];
        userData.owner = _msgSender();
        userData.randomType = randomType;
        userData.mysteryType = (uint32)(tokenId & 0xffffffff);
        userData.tokenId = tokenId;
        userData.count = 1;
        
        emit OracleOpenMysteryBox(reqid, tokenId, _msgSender());
    }

    /**
    * @dev batch open mystery box, emit {BatchOracleOpenMysteryBox}
    * call `oracleRand` in {Random} of address from `getRandSource` in {MBRandomSource}
    * send a oracle random request and emit {OracleRandRequest}
    *
    * Extrafees:
    * - `batchOracleOpenMysteryBox` call need charge extra fee for `fulfillRandom` in {Random} call by oracle service
    * - methodKey = 2, extra gas fee = 0.0065 with tx.value needed
    *
    * Requirements:
    * - caller must out side contract, not from contract
    * - caller must owner of `tokenId` in {MysteryBox1155}
    * - contract not paused
    *
    * @param tokenId token id of {MysteryBox1155}, if succeed, token will be burned
    */
    function batchOracleOpenMysteryBox(uint256 tokenId, uint8 batchCount) external payable whenNotPaused {
        require(tx.origin == _msgSender(), "MysteryBox: only for outside account");
        require(batchCount <= 10, "MysteryBox: batch count overflow");
        require(_mb1155.balanceOf(_msgSender(), tokenId) >= batchCount, "MysteryBox: insufficient mb");

        // check mb 1155 type
        uint32 randomType = (uint32)((tokenId >> 32) & 0xffffffff);
        address randSrcAddr = _randomSources[randomType];
        require(randSrcAddr != address(0), "MysteryBox: not a mystry box");
        
        address rndAddr = MBRandomSourceBase(randSrcAddr).getRandSource();
        require(rndAddr != address(0), "MysteryBox: rand address wrong");

        _methodExtraFees.chargeMethodExtraFee(2); // charge batchOracleOpenMysteryBox extra fee

        _mb1155.burn(_msgSender(), tokenId, batchCount);
        
        uint256 reqid = Random(rndAddr).oracleRand();

        UserData storage userData = _oracleUserData[reqid];
        userData.owner = _msgSender();
        userData.randomType = randomType;
        userData.mysteryType = (uint32)(tokenId & 0xffffffff);
        userData.tokenId = tokenId;
        userData.count = batchCount;
        
        emit BatchOracleOpenMysteryBox(reqid, tokenId, _msgSender(), batchCount);
    }

    // call back from random contract which triger by service call {fulfillOracleRand} function
    function oracleRandResponse(uint256 reqid, uint256 randnum) override external {
        require(hasRole(RAND_ROLE, _msgSender()), "MysteryBox: must have rand role");

        UserData storage userData = _oracleUserData[reqid];

        require(userData.owner != address(0), "MysteryBox: nftdata owner not exist");

        address randSrcAddr = _randomSources[userData.randomType];
        require(randSrcAddr != address(0), "MysteryBox: not a mystry box");

        if(userData.count > 1) {

            (MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts) 
                = MBRandomSourceBase(randSrcAddr).batchRandomAndMint(randnum, userData.mysteryType, userData.owner, userData.count);

            emit BatchOpenMysteryBox(userData.owner, userData.tokenId, sfts, nfts);
        }
        else {
            (MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts) 
                = MBRandomSourceBase(randSrcAddr).randomAndMint(randnum, userData.mysteryType, userData.owner);

            emit OpenMysteryBox(userData.owner, userData.tokenId, sfts, nfts);
        }

        delete _oracleUserData[reqid];
    }
    
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (MysteryBoxShop.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

import "./MysteryBox1155.sol";

contract MysteryBoxShop is 
    Context, 
    Pausable, 
    AccessControl
{
    struct OnSaleMysterBox{
        // config data --------------------------------------------------------
        address mysteryBox1155Addr; // mystery box address
        uint256 mbTokenId; // mystery box token id

        address tokenAddr; // charge token addr, could be 20 or 1155
        uint256 tokenId; // =0 means 20 token, else 1155 token
        uint256 price; // price value

        bool isBurn; // = ture means charge token will be burned, else charge token save in this contract

        uint64 beginTime; // start sale timeStamp in seconds since unix epoch, =0 ignore this condition
        uint64 endTime; // end sale timeStamp in seconds since unix epoch, =0 ignore this condition

        uint64 renewTime; // how long in seconds for each renew
        uint256 renewCount; // how many count put on sale for each renew

        uint32 whitelistId; // = 0 means open sale, else will check if buyer address in white list
        address nftholderCheck; // = address(0) won't check, else will check if buyer hold some other nft

        uint32 perAddrLimit; // = 0 means no limit, else means each user address max buying count
    }

    struct OnSaleMysterBoxRunTime {
        // runtime data -------------------------------------------------------
        uint64 nextRenewTime; // after this timeStamp in seconds since unix epoch, will put at max [renewCount] on sale

        // config & runtime data ----------------------------------------------
        uint256 countLeft; // how many boxies left
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OPERATER_ROLE = keccak256("OPERATER_ROLE");

    event SetOnSaleMysterBox(string indexed pairName, OnSaleMysterBox saleConfig, OnSaleMysterBoxRunTime saleData);
    event UnsetOnSaleMysterBox(string indexed pairName, OnSaleMysterBox saleConfig, OnSaleMysterBoxRunTime saleData);
    event SetOnSaleMBCheckCondition(
        string indexed pairName, 
        uint256 price, 
        uint32 whitelistId, 
        address nftholderCheck, 
        uint32 perAddrLimit);
    event SetOnSaleMBCountleft(string indexed pairName, uint countLeft);
    event PerAddrBuyCountChange(string indexed pairName, address indexed userAddr, uint32 count);
    event BuyMysteryBox(address indexed userAddr, string indexed pairName, OnSaleMysterBox saleConfig, OnSaleMysterBoxRunTime saleData);
    event BatchBuyMysteryBox(address indexed userAddr, string indexed pairName, OnSaleMysterBox saleConfig, OnSaleMysterBoxRunTime saleData, uint256 count);

    mapping(string=>OnSaleMysterBox) public _onSaleMysterBoxes;
    mapping(string=>OnSaleMysterBoxRunTime) public _onSaleMysterBoxDatas;
    mapping(string=>mapping(address=>uint32)) public _perAddrBuyCount;
    address public _receiveIncomAddress;

    mapping(uint32=>mapping(address=>bool)) public _whitelists;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(OPERATER_ROLE, _msgSender());
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P1");
        _pause();
    }
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "P2");
        _unpause();
    }

    function addWitheList(uint32 wlId, address[] memory whitelist) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");

        mapping(address=>bool) storage wl = _whitelists[wlId];

        for(uint i=0; i< whitelist.length; ++i){
            wl[whitelist[i]] = true;
        }
    }

    function removeWhiteList(uint32 wlId, address[] memory whitelist) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");

        mapping(address=>bool) storage wl = _whitelists[wlId];

        for(uint i=0; i< whitelist.length; ++i){
            delete wl[whitelist[i]];
        }
    }

    function setOnSaleMysteryBox(string calldata pairName, OnSaleMysterBox memory saleConfig, OnSaleMysterBoxRunTime memory saleData) external whenNotPaused {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");

        if(saleConfig.renewTime > 0)
        {
            saleData.nextRenewTime = (uint64)(block.timestamp + saleConfig.renewTime);
        }

        _onSaleMysterBoxes[pairName] = saleConfig;
        _onSaleMysterBoxDatas[pairName] = saleData;

        emit SetOnSaleMysterBox(pairName, saleConfig, saleData);
    }

    function unsetOnSaleMysteryBox(string calldata pairName) external whenNotPaused {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");

        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        OnSaleMysterBoxRunTime storage onSalePairData = _onSaleMysterBoxDatas[pairName];

        emit UnsetOnSaleMysterBox(pairName, onSalePair, onSalePairData);

        delete _onSaleMysterBoxes[pairName];
        delete _onSaleMysterBoxDatas[pairName];
    }

    function setOnSaleMBCheckCondition(
        string calldata pairName, 
        uint256 price, 
        uint32 whitelistId, 
        address nftholderCheck, 
        uint32 perAddrLimit
    ) external {
        require(hasRole(OPERATER_ROLE, _msgSender()), "MysteryBoxShop: must have operater role");

        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];

        onSalePair.price = price;
        onSalePair.whitelistId = whitelistId;
        onSalePair.nftholderCheck = nftholderCheck;
        onSalePair.perAddrLimit = perAddrLimit;

        emit SetOnSaleMBCheckCondition(pairName, price, whitelistId, nftholderCheck, perAddrLimit);
    }

    function setOnSaleMBCountleft(string calldata pairName, uint countLeft) external {
        require(hasRole(OPERATER_ROLE, _msgSender()), "MysteryBoxShop: must have operater role");

        OnSaleMysterBoxRunTime storage onSalePairData = _onSaleMysterBoxDatas[pairName];

        onSalePairData.countLeft = countLeft;

        emit SetOnSaleMBCountleft(pairName, countLeft);
    }

    function setReceiveIncomeAddress(address incomAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");

        _receiveIncomAddress = incomAddr;
    }

    function _checkSellCondition(OnSaleMysterBox storage onSalePair, OnSaleMysterBoxRunTime storage onSalePairData) internal {
        if(onSalePair.beginTime > 0)
        {
            require(block.timestamp >= onSalePair.beginTime, "MysteryBoxShop: sale not begin");
        }
        if(onSalePair.endTime > 0)
        {
            require(block.timestamp <= onSalePair.endTime, "MysteryBoxShop: sale finished");
        }
        if(onSalePair.whitelistId > 0)
        {
            require(_whitelists[onSalePair.whitelistId][_msgSender()], "MysteryBoxShop: not in whitelist");
        }
        if(onSalePair.nftholderCheck != address(0))
        {
            require(IERC721(onSalePair.nftholderCheck).balanceOf(_msgSender()) > 0, "MysteryBoxShop: no authority");
        }

        if(onSalePair.renewTime > 0)
        {
            if(block.timestamp > onSalePairData.nextRenewTime)
            {
                onSalePairData.nextRenewTime = (uint64)(onSalePairData.nextRenewTime + onSalePair.renewTime * (1 + ((block.timestamp - onSalePairData.nextRenewTime) / onSalePair.renewTime)));
                onSalePairData.countLeft = onSalePair.renewCount;
            }
        }
    }

    function _chargeByDesiredCount(
        string calldata pairName, OnSaleMysterBox storage onSalePair, OnSaleMysterBoxRunTime storage onSalePairData, uint256 count) 
        internal returns (uint256 realCount)
    {

        realCount = count;
        if(realCount > onSalePairData.countLeft)
        {
            realCount = onSalePairData.countLeft;
        }

        if(onSalePair.perAddrLimit > 0)
        {
            uint32 buyCount = _perAddrBuyCount[pairName][_msgSender()];
            uint32 buyCountLeft = (onSalePair.perAddrLimit > buyCount)? (onSalePair.perAddrLimit - buyCount) : 0;
            if(buyCountLeft < realCount){
                realCount = buyCountLeft;
            }

            if(realCount > 0){
                buyCount += uint32(realCount);
                _perAddrBuyCount[pairName][_msgSender()] = buyCount;

                emit PerAddrBuyCountChange(pairName, _msgSender(), buyCount);
            }
        }

        require(realCount > 0, "MysteryBoxShop: insufficient mystery box");

        onSalePairData.countLeft -= realCount;

        if(onSalePair.price > 0){
            uint256 realPrice = onSalePair.price * realCount;

            if(onSalePair.tokenAddr == address(0)){
                require(msg.value >= realPrice, "MysteryBoxShop: insufficient value");

                // receive eth
                (bool sent, ) = _receiveIncomAddress.call{value:msg.value}("");
                require(sent, "MysteryBoxShop: transfer income error");
            }
            else if(onSalePair.tokenId > 0)
            {
                // 1155
                require(IERC1155(onSalePair.tokenAddr).balanceOf( _msgSender(), onSalePair.tokenId) >= realPrice , "MysteryBoxShop: erc1155 insufficient token");

                if(onSalePair.isBurn) {
                    // burn
                    ERC1155Burnable(onSalePair.tokenAddr).burn(_msgSender(), onSalePair.tokenId, realPrice);
                }
                else {
                    // charge
                    IERC1155(onSalePair.tokenAddr).safeTransferFrom(_msgSender(), address(this), onSalePair.tokenId, realPrice, "buy mb");
                }
            }
            else{
                // 20
                require(IERC20(onSalePair.tokenAddr).balanceOf(_msgSender()) >= realPrice , "MysteryBoxShop: erc20 insufficient token");

                if(onSalePair.isBurn) {
                    // burn
                    ERC20Burnable(onSalePair.tokenAddr).burnFrom(_msgSender(), realPrice);
                }
                else {
                    // charge
                    TransferHelper.safeTransferFrom(onSalePair.tokenAddr, _msgSender(), address(this), realPrice);
                }
            }
        }

    }

    function buyMysteryBox(string calldata pairName) external payable whenNotPaused {
        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        OnSaleMysterBoxRunTime storage onSalePairData = _onSaleMysterBoxDatas[pairName];
        require(address(onSalePair.mysteryBox1155Addr) != address(0), "MysteryBoxShop: mystery box not on sale");

        _checkSellCondition(onSalePair, onSalePairData);

        _chargeByDesiredCount(pairName, onSalePair, onSalePairData, 1);

        MysteryBox1155(onSalePair.mysteryBox1155Addr).mint(_msgSender(), onSalePair.mbTokenId, 1, "buy mb");

        emit BuyMysteryBox(_msgSender(), pairName, onSalePair, onSalePairData);
    }

    function batchBuyMysterBox(string calldata pairName, uint32 count) external payable whenNotPaused {

        OnSaleMysterBox storage onSalePair = _onSaleMysterBoxes[pairName];
        OnSaleMysterBoxRunTime storage onSalePairData = _onSaleMysterBoxDatas[pairName];
        require(address(onSalePair.mysteryBox1155Addr) != address(0), "MysteryBoxShop: mystery box not on sale");

        _checkSellCondition(onSalePair, onSalePairData);

        uint256 realCount = _chargeByDesiredCount(pairName, onSalePair, onSalePairData, count);

        MysteryBox1155(onSalePair.mysteryBox1155Addr).mint(_msgSender(), onSalePair.mbTokenId, realCount, "buy mb");

        emit BatchBuyMysteryBox(_msgSender(), pairName, onSalePair, onSalePairData, realCount);
    }

    function fetchIncome(address tokenAddr, uint256 value) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");
        IERC20 token = IERC20(tokenAddr);

        if(value <= 0){
            value = token.balanceOf(address(this));
        }

        require(value > 0, "MysteryBoxShop: zero value");

        TransferHelper.safeTransfer(tokenAddr, _receiveIncomAddress, value);
    }

    function fetchIncome1155(address tokenAddr, uint256 tokenId, uint256 value) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MysteryBoxShop: must have manager role to manage");
        IERC1155 token = IERC1155(tokenAddr);

        if(value <= 0){
            value = token.balanceOf(address(this), tokenId);
        }

        require(value > 0, "MysteryBoxShop: zero value");

        token.safeTransferFrom(address(this), _receiveIncomAddress, tokenId, value, "fetch income");
    }
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (GasFeeCharger.sol)

pragma solidity ^0.8.0;

library GasFeeCharger {

    struct MethodWithExrtraFee {
        address target;
        uint256 value;
    }

    struct MethodExtraFees {
        mapping(uint8=>MethodWithExrtraFee) extraFees;
    }

    function setMethodExtraFee(MethodExtraFees storage extraFees, uint8 methodKey, uint256 value, address target) internal {
        MethodWithExrtraFee storage fee = extraFees.extraFees[methodKey];
        fee.value = value;
        fee.target = target;
    }

    function removeMethodExtraFee(MethodExtraFees storage extraFees, uint8 methodKey) internal {
        delete extraFees.extraFees[methodKey];
    }

    function chargeMethodExtraFee(MethodExtraFees storage extraFees, uint8 methodKey)  internal returns(bool) {
        MethodWithExrtraFee storage fee = extraFees.extraFees[methodKey];
        if(fee.target == address(0)){
            return true; // no need charge fee
        }

        require(msg.value >= fee.value, "msg fee not enough");

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = fee.target.call{value: msg.value}("");
        require(sent, "Trans fee err");

        return sent;
    }
    
}

// SPDX-License-Identifier: MIT
// Mateline Contracts (Random.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IOracleRandComsumer {
    function oracleRandResponse(uint256 reqid, uint256 randnum) external;
}

/**
 * @dev A random source contract provids `seedRand`, `sealedRand` and `oracleRand` methods
 */
contract Random is Context, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // an auto increased number by each _seedRand call
    uint32 _nonce;

    // an auto increased number by each setSealed call
    uint32 _sealedNonce;

    // an random seed set by manager
    uint256 _randomSeed;

    // an auto increased number by each oracleRand call
    uint256 _orcacleReqIDSeed;

    // sealed random seed data structure
    struct RandomSeed {
        uint32 sealedNonce;
        uint256 sealedNumber;
        uint256 seed;
        uint256 h1;
    }

    mapping(uint256 => RandomSeed) _sealedRandom; // _encodeSealedKey(addr) => sealed random seed data structure
    mapping(uint256 => address) _oracleRandRequests; // oracle rand request id => caller address

    /**
    * @dev emit when `oracleRand` called

    * @param reqid oracle rand request id
    * @param requestAddress caller address
    */
    event OracleRandRequest(uint256 reqid, address indexed requestAddress);

    /**
    * @dev emit when `fulfillOracleRand` called

    * @param reqid oracle rand request id
    * @param randnum random number feed to request caller
    * @param requestAddress `oracleRand` requrest caller address
    */
    event OracleRandResponse(uint256 reqid, uint256 randnum, address indexed requestAddress);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(ORACLE_ROLE, _msgSender());
    }

    /**
    * @dev check address is sealed, usually call by contract to check user seal status
    *
    * @param addr user addr
    * @return ture if user is sealed
    */
    function isSealed(address addr) external view returns (bool) {
        return _isSealedDirect(_encodeSealedKey(addr));
    }

    /**
    * @dev set random seed
    *
    * Requirements:
    * - caller must have `MANAGER_ROLE`
    *
    * @param s random seed
    */
    function setRandomSeed(uint256 s) external {
        require(hasRole(MANAGER_ROLE, _msgSender()),"not manager");

        _randomSeed = s;
    }

    /**
    * @dev set user sealed, usually call by contract to seal a user
    * this function will `_encodeSealedKey` by tx.orgin and `_msgSender`
    * if success call this function, then user can call `sealedRand`
    */
    function setSealed() external {

        require(block.number >= 100,"block is too small");
        
        uint256 sealedKey = _encodeSealedKey(tx.origin);
       
        require(!_isSealedDirect(sealedKey),"should not sealed");

        _sealedNonce++;

        RandomSeed storage rs = _sealedRandom[sealedKey];

        rs.sealedNumber = block.number + 1;
        rs.sealedNonce = _sealedNonce;
        rs.seed = _randomSeed;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(block.number, block.timestamp, _sealedNonce)
            )
        );
        uint32 n1 = uint32(seed % 100);
        rs.h1 = uint256(blockhash(block.number - n1));
    }

    /**
    * @dev seal rand and get a random number
    *
    * Requirements:
    * - caller must call `setSealed` first
    *
    * @return ret random number
    */
    function sealedRand() external returns (uint256 ret) {
        return _sealedRand();
    }

    /**
    * @dev input a seed and get a random number depends on seed
    *
    * @param inputSeed random seed
    * @return ret random number depends on seed
    */
    function seedRand(uint256 inputSeed) external returns (uint256 ret) {
        return _seedRand(inputSeed);
    }

    /**
    * @dev start an oracle rand, emit {OracleRandRequest}, call by contract
    * oracle service wait on {OracleRandRequest} event and call `fulfillOracleRand`
    *
    * Requirements:
    * - caller must implements `oracleRandResponse` of {IOracleRandComsumer}
    *
    * @return reqid is request id of oracle rand request
    */
    function oracleRand() external returns (uint256) {
        _orcacleReqIDSeed = _orcacleReqIDSeed + 1;
        uint256 reqid = _orcacleReqIDSeed;
        //console.log("[sol]reqid=",reqid);
        _oracleRandRequests[reqid] = _msgSender();

        emit OracleRandRequest(reqid, _msgSender());

        return reqid;
    }

    /**
    * @dev fulfill an oracle rand, emit {OracleRandResponse}
    * call by oracle when it get {OracleRandRequest}, feed with an random number
    *
    * Requirements:
    * - caller must have `ORACLE_ROLE`
    *
    * @param reqid request id of oracle rand request
    * @param randnum random number feed by oracle
    * @return rand number
    */
    function fulfillOracleRand(uint256 reqid, uint256 randnum) external returns (uint256 rand) {
        require(hasRole(ORACLE_ROLE, _msgSender()),"need oracle role");
        require(_oracleRandRequests[reqid] != address(0),"reqid not exist");

        rand = _seedRand(randnum);
        IOracleRandComsumer comsumer = IOracleRandComsumer(_oracleRandRequests[reqid]);
        comsumer.oracleRandResponse(reqid, rand);

        delete _oracleRandRequests[reqid];

        emit OracleRandResponse(reqid, rand, address(comsumer));

        return rand;
    }

    /**
    * @dev input index and random number, return with new random number depends on input
    * use chain blockhash as random array, we can fetch many random number with a seed in one transaction
    *
    * @param index a number increased by caller, make sure that we don't get same outcome
    * @param randomNum random number as seed
    * @return ret is new rand number
    */
    function nextRand(uint32 index, uint256 randomNum) external view returns(uint256 ret){
        uint256 n1 = (randomNum + index) % block.number;
        uint256 h1 = uint256(blockhash(n1));

        return uint256(
            keccak256(
                abi.encodePacked(index, n1, h1)
            )
        );
    }

    function _seedRand(uint256 inputSeed) internal returns (uint256 ret) {
        require(block.number >= 1000,"block.number need >=1000");

        uint256 seed = uint256(
            keccak256(abi.encodePacked(block.number, block.timestamp, inputSeed))
        );

        uint32 n1 = uint32(seed % 100);
            
        uint32 n2 = uint32(seed % 1000);

        uint256 h1 = uint256(blockhash(block.number - n1));
  
        uint256 h2 = uint256(blockhash(block.number - n2));

        _nonce++;
        uint256 v = uint256(
            keccak256(abi.encodePacked(_randomSeed, h1, h2, _nonce))
        );

        return v;
    }

    // addr usually be tx.origin
    function _encodeSealedKey(address addr) internal view returns (uint256 key) {
        return uint256(
            keccak256(
                abi.encodePacked(addr, _msgSender())
            )
        );
    }

    function _sealedRand() internal returns (uint256 ret) {
    
        uint256 sealedKey = _encodeSealedKey(tx.origin);
        bool v = _isSealedDirect(sealedKey);
        require(v == true,"should sealed");

        RandomSeed storage rs = _sealedRandom[sealedKey];

        uint256 h2 = uint256(blockhash(rs.sealedNumber));
        ret = uint256(
            keccak256(
                abi.encodePacked(
                    rs.seed,
                    rs.h1,
                    h2,
                    block.difficulty,
                    rs.sealedNonce
                )
            )
        );

        delete _sealedRandom[sealedKey];

        return ret;
    }

    function _isSealedDirect(uint256 sealedKey) internal view returns (bool){
        return _sealedRandom[sealedKey].sealedNumber != 0;
    }

}

// SPDX-License-Identifier: MIT
// Mateline Contracts (RandomPoolLib.sol)

pragma solidity ^0.8.0;

import "./Random.sol";

/**
 * @dev Random pool that allow user random in different rate section
 */
library RandomPoolLib {

    // random set with rate and range
    struct RandomSet {
        uint32 rate;
        uint rangMin;
        uint rangMax;
    }

    // random pool with an array of random set
    struct RandomPool {
        uint32 totalRate;
        RandomSet[] pool;
    }

    // initialize a random pool
    function initRandomPool(RandomPool storage pool) external {
        for(uint i=0; i< pool.pool.length; ++i){
            pool.totalRate += pool.pool[i].rate;
        }

        require(pool.totalRate > 0);
    }

    // use and randomNum to fetch a random result in the random set array
    function random(RandomPool storage pool, uint256 r) external view returns(uint ret) {
        require(pool.totalRate > 0);

        uint32 rate = uint32((r>>224) % pool.totalRate);
        uint32 curRate = 0;
        for(uint i=0; i<pool.pool.length; ++i){
            curRate += pool.pool[i].rate;
            if(rate > curRate){
                continue;
            }

            return randBetween(pool.pool[i].rangMin, pool.pool[i].rangMax, r);
        }
    }

    // input r and min,max, return a number between [min, max] with r
    function randBetween(
        uint256 min,
        uint256 max,
        uint256 r
    ) public pure returns (uint256 ret) {
        if(min >= max) {
            return min;
        }

        uint256 rang = (max+1) - min;
        return uint256(min + (r % rang));
    }
}

// SPDX-License-Identifier: MIT
// Override from OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title ResetableCounters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library ResetableCounters {
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

    function reset(Counter storage counter, uint256 v) internal {
        counter._value = v;
    }
}

// contracts/TransferHelper.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}