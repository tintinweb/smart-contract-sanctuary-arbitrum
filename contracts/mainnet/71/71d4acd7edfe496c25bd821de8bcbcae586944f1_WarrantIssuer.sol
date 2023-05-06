// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// Metaline Contracts (CapedERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CappedERC20 is 
    Context,
    ERC20Burnable
{
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 cap_
    ) ERC20(name_, symbol_)
    {
        _mint(_msgSender(), cap_);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Extendable1155.sol)

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
// Metaline Contracts (ExtendableNFT.sol)

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
    * @param freezeRef freezed ref count
    */
    event NFTFreeze(uint256 indexed tokenId, int32 freezeRef);
    
    /**
    * @dev emit when new data section created

    * @param extendName new data section name
    * @param nameBytes data section name after keccak256
    */
    event NFTExtendName(string extendName, bytes32 nameBytes);

    /**
    * @dev emit when token data section changed

    * @param tokenId tokenid which data has been changed
    * @param extendName data section name
    * @param extendData data after change
    */
    event NFTExtendModify(uint256 indexed tokenId, string extendName, bytes extendData);

    // record of token already extended data section
    struct NFTExtendsNames{
        bytes32[]   NFTExtendDataNames; // array of data sectioin name after keccak256
    }

    // extend data mapping
    struct NFTExtendData {
        bool _exist;
        mapping(uint256 => bytes) ExtendDatas; // tokenid => data mapping
    }

    mapping(uint256 => int32) private _nftFreezed; // tokenid => freezed ref
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

        _nftFreezed[tokenId]++;

        emit NFTFreeze(tokenId, _nftFreezed[tokenId]);
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

        --_nftFreezed[tokenId];
        if(_nftFreezed[tokenId] <= 0){
            delete _nftFreezed[tokenId];
        }

        emit NFTFreeze(tokenId, _nftFreezed[tokenId]);
    }

    /**
    * @dev check token, return true if not freezed
    *
    * @param tokenId token to check
    * @return ture if token is not freezed
    */
    function notFreezed(uint256 tokenId) public view returns (bool) {
        return _nftFreezed[tokenId] <= 0;
    }

    /**
    * @dev check token, return true if it's freezed
    *
    * @param tokenId token to check
    * @return ture if token is freezed
    */
    function isFreezed(uint256 tokenId) public view returns (bool) {
        return _nftFreezed[tokenId] > 0;
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

        emit NFTExtendModify(tokenId, extendName, extendData);
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

        emit NFTExtendModify(tokenId, extendName, extendData);
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
// Metaline Contracts (IRandom.sol)

pragma solidity ^0.8.0;

interface IOracleRandComsumer {
    function oracleRandResponse(uint256 reqid, uint256 randnum) external;
}

/**
 * @dev A random source contract provids `seedRand`, `sealedRand` and `oracleRand` methods
 */
interface IRandom {
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


    /**
    * @dev check address is sealed, usually call by contract to check user seal status
    *
    * @param addr user addr
    * @return ture if user is sealed
    */
    function isSealed(address addr) external view returns (bool);

    /**
    * @dev set random seed
    *
    * Requirements:
    * - caller must have `MANAGER_ROLE`
    *
    * @param s random seed
    */
    function setRandomSeed(uint256 s) external;

    /**
    * @dev set user sealed, usually call by contract to seal a user
    * this function will `_encodeSealedKey` by tx.orgin and `_msgSender`
    * if success call this function, then user can call `sealedRand`
    */
    function setSealed() external;

    /**
    * @dev seal rand and get a random number
    *
    * Requirements:
    * - caller must call `setSealed` first
    *
    * @return ret random number
    */
    function sealedRand() external returns (uint256 ret);

    /**
    * @dev input a seed and get a random number depends on seed
    *
    * @param inputSeed random seed
    * @return ret random number depends on seed
    */
    function seedRand(uint256 inputSeed) external returns (uint256 ret);

    /**
    * @dev start an oracle rand, emit {OracleRandRequest}, call by contract
    * oracle service wait on {OracleRandRequest} event and call `fulfillOracleRand`
    *
    * Requirements:
    * - caller must implements `oracleRandResponse` of {IOracleRandComsumer}
    *
    * @return reqid is request id of oracle rand request
    */
    function oracleRand() external returns (uint256);

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
    function fulfillOracleRand(uint256 reqid, uint256 randnum) external returns (uint256 rand);

    /**
    * @dev input index and random number, return with new random number depends on input
    * use chain blockhash as random array, we can fetch many random number with a seed in one transaction
    *
    * @param index a number increased by caller, make sure that we don't get same outcome
    * @param randomNum random number as seed
    * @return ret is new rand number
    */
    function nextRand(uint32 index, uint256 randomNum) external view returns(uint256 ret);
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Expedition.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../MTT.sol";
import "../MTTGold.sol";
import "../nft/HeroNFT.sol";
import "../nft/WarrantNFT.sol";
import "../nft/ShipNFT.sol";
import "../nft/HeroNFTCodec.sol";
import "../nft/NFTAttrSource.sol";

import "./MTTMinePool.sol";

contract Expedition is
    Context,
    Pausable,
    AccessControl,
    IERC721Receiver
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event SetHeroExpedTeam(address indexed userAddr, uint16 indexed portID, uint256 teamHashRate, uint256[] heroNftIDs);
    event UnsetHeroExpedTeam(address indexed userAddr, uint16 indexed portID, uint256 teamHashRate, uint256[] heroNftIDs);

    event SetShipExpedTeam(address indexed userAddr, uint16 portID, uint256 teamHashRate, ExpeditionShip[] expedShips);
    event UnsetShipExpedTeam(address indexed userAddr, uint16 portID, uint256 teamHashRate, ExpeditionShip[] expedShips);

    event OutputMTT(uint256 value, ExpeditionPoolData poolData);
    event StartExpedition(address indexed userAddr, ExpeditionTeamData teamData, ExpeditionPoolData poolData);
    event FetchExpeditionMTT(address indexed userAddr, uint256 value, ExpeditionTeamData teamData, ExpeditionPoolData poolData);

    struct ExpeditionPoolConf {
        uint256 minHashRate; // expedition team minimum hashrate require
        uint256 maxHashRate; // expedition team maximum hashrate allowed

        uint256 minBlockInterval; // each expedition spend bocklInterval time, 
        uint256 goldPerHashrate; // allow input gold by 1 hashrate when expedition blocks = minBlockInterval, 18 decimal
        
        uint256 maxMTTPerGold; // limit max mtt output per gold, 8 decimals, mtt = gold * mttpergold/100000000

        uint256 minMTTPerBlock; // min MTT output per block, no matter how many hashrate in this pool
        uint256 maxMTTPerBlock; // max MTT output per block, even more than maxOutputhashRate hashrate in this pool
        uint256 maxOutputhashRate; // MTT output = min(maxMTTPerBlock, max(minMTTPerBlock, maxMTTPerBlock*totalHashRate/maxOutputhashRate))
    }

    struct ExpeditionTeamData {
        uint256 inputGoldLeft;
        uint256 expedLastFetchBlock;
        uint256 goldPerBlock;
        uint256 expedEndBlock;
    }
    struct ExpeditionPoolData {
        uint256 totalHashRate; // all team hashrate
        uint256 totalOutputMTT; // total output MTT
        uint256 totalInputGold; // total input gold
        uint256 currentOutputMTT; // current output mtt
        uint256 currentInputGold; // current input gold

        uint256 currentMTTPerBlock; // current mtt output per block
        uint256 lastOutputBlock; // last output mtt block number
    }

    struct ExpeditionShip {
        uint256 shipNFTID;
        uint256[] heroNFTIDs;
    }
    struct ShipExpeditionTeam {
        uint256 teamHashRate;
        ExpeditionShip[] ships;

        ExpeditionTeamData teamData;
    }

    struct HeroExpeditionTeam {
        uint256 teamHashRate; // all nft hashrate
        uint256[] heroNFTIDs; // hero nfts, 0 must be hero nft

        ExpeditionTeamData teamData;
    }

    struct PortHeroExpedPool {
        ExpeditionPoolData poolData;
        ExpeditionPoolConf poolConf; 
        mapping(address=>HeroExpeditionTeam) expedHeros; // user addr => hero expedition team
    }

    struct PortShipExpedPool {
        ExpeditionPoolData poolData;
        ExpeditionPoolConf poolConf; 
        mapping(address=>ShipExpeditionTeam) expedShips; // user addr => ship expedition team
    }

    address public _warrantNFTAddr;
    address public _heroNFTAddr;
    address public _shipNFTAddr;
    address public _MTTGoldAddr;
    address public _MTTAddr;
    address public _MTTMinePoolAddr;

    mapping(uint16=>PortHeroExpedPool) public _heroExpeditions;
    mapping(uint16=>PortShipExpedPool) public _shipExpeditions;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Expedition: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Expedition: must have pauser role to unpause"
        );
        _unpause();
    }

    function init(
        address warrantNFTAddr,
        address heroNFTAddr,
        address shipNFTAddr,
        address MTTAddr,
        address MTTGoldAddr,
        address MTTMinePoolAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Expedition: must have manager role");

        _warrantNFTAddr = warrantNFTAddr;
        _heroNFTAddr = heroNFTAddr;
        _shipNFTAddr = shipNFTAddr;
        _MTTAddr = MTTAddr;
        _MTTGoldAddr = MTTGoldAddr;
        _MTTMinePoolAddr = MTTMinePoolAddr;
    }

    function setPortHeroExpedConf(uint16 portID, ExpeditionPoolConf memory conf) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Expedition: must have manager role");

        _heroExpeditions[portID].poolConf = conf;
    }
    function setPortShipExpedConf(uint16 portID, ExpeditionPoolConf memory conf) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Expedition: must have manager role");

        _shipExpeditions[portID].poolConf = conf;
    }

    function getHeroExpedData(uint16 portID, address userAddr) external view returns (HeroExpeditionTeam memory) {
        return _heroExpeditions[portID].expedHeros[userAddr];
    }
    function getShipExpedData(uint16 portID, address userAddr) external view returns (ShipExpeditionTeam memory) {
        return _shipExpeditions[portID].expedShips[userAddr];
    }

    function setHeroExpedTeam(uint16 portID, uint256[] memory heroNftIDs) external {

        PortHeroExpedPool storage phep = _heroExpeditions[portID];
        require(phep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        require(heroNftIDs.length > 0, "Expedition: team hero must >0");

        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());
        NFTAttrSource_V1 attSrc = NFTAttrSource_V1(HeroNFT(_heroNFTAddr).getAttrSource());

        uint256 teamHashRate = 0;
        uint8 leadGrade = 0;
        for(uint i=0; i<heroNftIDs.length; ++i){
            require(HeroNFT(_heroNFTAddr).ownerOf(heroNftIDs[i]) == _msgSender(), "Expedition: not your hero or pet");

            HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(heroNftIDs[i]);

            if(i==0){
                // must be hero nft
                require(hdb.nftType == 1, "Expedition: team leader must be hero"); 
            }

            if(hdb.nftType == 1) { // hero 
                HeroNFTFixedData_V1 memory hndata = codec.getHeroNftFixedData(hdb);
                HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);

                if(i==0){
                    leadGrade = hndata.grade;
                    require(wdata.starLevel+1 >= heroNftIDs.length, "Expedition: team leader star level must >= team hero count"); 
                }
                else {
                    require(hndata.grade <= leadGrade, "Expedition: team member grade must <= leader grade");
                }

                HeroNFTMinerAttr memory hmattr = attSrc.getHeroMinerAttr(hndata.minerAttr, wdata.starLevel);
                teamHashRate += hmattr.hashRate;
            } 
            else if(hdb.nftType == 2) { // pet
                HeroPetNFTFixedData_V1 memory hndata = codec.getHeroPetNftFixedData(hdb);
                
                HeroNFTMinerAttr memory hmattr = attSrc.getHeroMinerAttr(hndata.minerAttr, 1);
                teamHashRate += hmattr.hashRate;
            }
            else {
                revert("Expedition: nft type error");
            }

            // transfer hero into pool
            HeroNFT(_heroNFTAddr).safeTransferFrom(_msgSender(), address(this), heroNftIDs[i]);
        }

        require(teamHashRate > phep.poolConf.minHashRate, "Expedition: team hashrate not enough");
        require(teamHashRate <= phep.poolConf.maxHashRate, "Expedition: team hashrate overflow");

        phep.expedHeros[_msgSender()] = HeroExpeditionTeam({
            teamHashRate:teamHashRate,
            heroNFTIDs:heroNftIDs,
            teamData:ExpeditionTeamData({
                inputGoldLeft:0,
                expedLastFetchBlock:0,
                goldPerBlock:0,
                expedEndBlock:0
            })
        });
        
        // output mtt
        _outputMTT(phep.poolData);

        // add pool total hashrate
        phep.poolData.totalHashRate += teamHashRate;
        
        // recalc output mtt per block
        _calcOutputMTTPerBlock(phep.poolConf, phep.poolData);

        emit SetHeroExpedTeam(_msgSender(), portID, teamHashRate, heroNftIDs);
    }

    function unsetHeroExpedTeam(uint16 portID) external {
        
        PortHeroExpedPool storage phep = _heroExpeditions[portID];
        require(phep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        HeroExpeditionTeam storage team = phep.expedHeros[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");

        for(uint i=0; i<team.heroNFTIDs.length; ++i){
            // send back hero
            HeroNFT(_heroNFTAddr).safeTransferFrom(address(this), _msgSender(), team.heroNFTIDs[i]);
        }

        require(phep.poolData.totalHashRate >= team.teamHashRate, "Expedition: total hashrate underflow");
        
        // output mtt
        _outputMTT(phep.poolData);
        
        // sub pool total hashrate
        phep.poolData.totalHashRate -= team.teamHashRate;
        
        // recalc output mtt per block
        _calcOutputMTTPerBlock(phep.poolConf, phep.poolData);

        emit UnsetHeroExpedTeam(_msgSender(), portID, team.teamHashRate, team.heroNFTIDs);

        delete phep.expedHeros[_msgSender()];
    }

    function setShipExpedTeam(uint16 portID, ExpeditionShip[] memory expedShips) external {

        PortShipExpedPool storage psep = _shipExpeditions[portID];
        require(psep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");

        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());
        NFTAttrSource_V1 attSrc = NFTAttrSource_V1(HeroNFT(_heroNFTAddr).getAttrSource());
        NFTAttrSource_V1 sattSrc = NFTAttrSource_V1(ShipNFT(_shipNFTAddr).getAttrSource());

        ShipExpeditionTeam storage shipet = psep.expedShips[_msgSender()];
        uint8 flagShipGrade = 0;
        for(uint j=0; j< expedShips.length; ++j){
            require(ShipNFT(_shipNFTAddr).ownerOf(expedShips[j].shipNFTID) == _msgSender(), "Expedition: not your ship");

            ShipNFTData memory sd = ShipNFT(_shipNFTAddr).getNftData(expedShips[j].shipNFTID);
            ShipNFTMinerAttr memory smattr = sattSrc.getShipMinerAttr(sd.minerAttr, sd.level);
            require(smattr.maxSailer >= expedShips[j].heroNFTIDs.length);
            shipet.teamHashRate += smattr.hashRate;

            require(sd.shipType == 1, "Expedition: not cargo ship");

            if(j==0){
                require((sd.level / 10)+1 >= expedShips.length, "Expedition: flag ship level/10 must >= team ships count");
                flagShipGrade = sd.grade;
            }
            else {
                require(sd.grade <= flagShipGrade, "Expedition: flag ship grade must >= team ship grade");
            }

            // transfer ship into pool
            ShipNFT(_shipNFTAddr).safeTransferFrom(_msgSender(), address(this), expedShips[j].shipNFTID);

            for(uint i=0; i<expedShips[j].heroNFTIDs.length; ++i){
                require(HeroNFT(_heroNFTAddr).ownerOf(expedShips[j].heroNFTIDs[i]) == _msgSender(), "Expedition: not your hero or pet");

                HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(expedShips[j].heroNFTIDs[i]);

                if(i==0){
                    // must be hero nft
                    require(hdb.nftType == 1, "Expedition: captain must be hero"); 
                }

                if(hdb.nftType == 1) { // hero 
                    HeroNFTFixedData_V1 memory hndata = codec.getHeroNftFixedData(hdb);
                    HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);

                    HeroNFTMinerAttr memory hmattr = attSrc.getHeroMinerAttr(hndata.minerAttr, wdata.starLevel);
                    shipet.teamHashRate += hmattr.hashRate;
                } 
                else if(hdb.nftType == 2) { // pet
                    HeroPetNFTFixedData_V1 memory hndata = codec.getHeroPetNftFixedData(hdb);
                    
                    HeroNFTMinerAttr memory hmattr = attSrc.getHeroMinerAttr(hndata.minerAttr, 1);
                    shipet.teamHashRate += hmattr.hashRate;
                }
                else {
                    revert("Expedition: nft type error");
                }

                // transfer hero into pool
                HeroNFT(_heroNFTAddr).safeTransferFrom(_msgSender(), address(this), expedShips[j].heroNFTIDs[i]);
            }

            shipet.ships.push(expedShips[j]);
        }

        require(shipet.teamHashRate > psep.poolConf.minHashRate, "Expedition: team hashrate not enough");
        require(shipet.teamHashRate <= psep.poolConf.maxHashRate, "Expedition: team hashrate overflow");

        shipet.teamData = ExpeditionTeamData({
            inputGoldLeft:0,
            expedLastFetchBlock:0,
            goldPerBlock:0,
            expedEndBlock:0
        });
        
        // output mtt
        _outputMTT(psep.poolData);

        // add pool total hashrate
        psep.poolData.totalHashRate += shipet.teamHashRate;
        
        // recalc output mtt per block
        _calcOutputMTTPerBlock(psep.poolConf, psep.poolData);

        emit SetShipExpedTeam(_msgSender(), portID, shipet.teamHashRate, expedShips);
    }
    function unsetShipExpedTeam(uint16 portID) external {
        PortShipExpedPool storage psep = _shipExpeditions[portID];
        require(psep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        ShipExpeditionTeam storage team = psep.expedShips[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");

        for(uint j=0; j<team.ships.length; ++j){
            // send back ship
            ShipNFT(_shipNFTAddr).safeTransferFrom(address(this), _msgSender(), team.ships[j].shipNFTID);

            for(uint i=0; i<team.ships[j].heroNFTIDs.length; ++i){
                // send back hero
                HeroNFT(_heroNFTAddr).safeTransferFrom(address(this), _msgSender(), team.ships[j].heroNFTIDs[i]);
            }
        }

        require(psep.poolData.totalHashRate >= team.teamHashRate, "Expedition: total hashrate underflow");

        // output mtt
        _outputMTT(psep.poolData);

        // sub pool total hashrate
        psep.poolData.totalHashRate -= team.teamHashRate;

        // recalc output mtt per block
        _calcOutputMTTPerBlock(psep.poolConf, psep.poolData);

        emit UnsetShipExpedTeam(_msgSender(), portID, team.teamHashRate, team.ships);

        delete psep.expedShips[_msgSender()];
    }

    function _calcOutputMTTPerBlock(
        ExpeditionPoolConf storage conf,
        ExpeditionPoolData storage poolData
    ) internal {
        poolData.currentMTTPerBlock = conf.maxMTTPerBlock * poolData.totalHashRate / conf.maxOutputhashRate;
        if(poolData.currentMTTPerBlock < conf.minMTTPerBlock) {
            poolData.currentMTTPerBlock = conf.minMTTPerBlock;
        }
        else if(poolData.currentMTTPerBlock > conf.maxMTTPerBlock) {
            poolData.currentMTTPerBlock = conf.maxMTTPerBlock;
        }
    }

    function _outputMTT(
        ExpeditionPoolData storage poolData
    ) internal {
        if(poolData.lastOutputBlock == 0){
            poolData.lastOutputBlock = block.number;
            return;
        }
        if(poolData.totalHashRate == 0){
            poolData.lastOutputBlock = block.number;
            return;
        }
        if(poolData.lastOutputBlock >= block.number){
            return;
        }

        uint256 mttoutput = poolData.currentMTTPerBlock * (block.number - poolData.lastOutputBlock);
        poolData.lastOutputBlock = block.number;

        poolData.currentOutputMTT += mttoutput;
        poolData.totalOutputMTT += mttoutput;

        emit OutputMTT(mttoutput, poolData);
    }

    function _startExped(
        uint256 inputGold,
        uint256 blockInterval,
        uint256 teamHashRate,
        ExpeditionPoolConf storage conf,
        ExpeditionTeamData storage teamData, 
        ExpeditionPoolData storage poolData
    ) internal {
        require(teamData.expedEndBlock < block.number, "Expedition: previous expedition not finish");

        require(blockInterval >= conf.minBlockInterval, "Expedition: block interval error");
        require(inputGold <= conf.goldPerHashrate*teamHashRate*blockInterval/conf.minBlockInterval, "Expedition: input gold error");

        // burn gold
        MTTGold(_MTTGoldAddr).burnFrom(_msgSender(), inputGold);

        teamData.inputGoldLeft += inputGold;
        teamData.expedLastFetchBlock = block.number;
        teamData.goldPerBlock = inputGold / blockInterval;
        teamData.expedEndBlock = block.number + blockInterval;

        poolData.totalInputGold += inputGold;
        poolData.currentInputGold += inputGold;

        emit StartExpedition(_msgSender(), teamData, poolData);
    }

    function _fetchExpedMTT(
        ExpeditionPoolConf storage conf,
        ExpeditionTeamData storage teamData, 
        ExpeditionPoolData storage poolData
    ) internal {
        require(teamData.inputGoldLeft > 0, "Expedition: insufficient input gold");
        require(teamData.expedLastFetchBlock < block.number, "Expedition: wait some blocks");

        uint256 goldCost = teamData.goldPerBlock * (block.number - teamData.expedLastFetchBlock);
        teamData.expedLastFetchBlock = block.number;

        if(goldCost > teamData.inputGoldLeft){
            goldCost = teamData.inputGoldLeft;
            teamData.inputGoldLeft = 0;
        }
        else {
            teamData.inputGoldLeft -= goldCost;
        }

        require(poolData.currentInputGold >= goldCost, "Expedition: gold underflow");

        uint256 value = poolData.currentOutputMTT * goldCost / poolData.currentInputGold;
        uint256 maxMTT = goldCost * conf.maxMTTPerGold / 10**8;
        if(value > maxMTT) {
            value = maxMTT;
        }

        MTTMinePool(_MTTMinePoolAddr).send(_msgSender(), value, "expedition");

        poolData.currentOutputMTT -= value;
        poolData.currentInputGold -= goldCost;

        emit FetchExpeditionMTT(_msgSender(), value, teamData, poolData);
    }

    function startHeroExped(uint16 portID, uint256 inputGold, uint256 blockInterval) external {
        PortHeroExpedPool storage phep = _heroExpeditions[portID];
        require(phep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        HeroExpeditionTeam storage team = phep.expedHeros[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");
    
        _startExped(inputGold, blockInterval, team.teamHashRate, phep.poolConf, team.teamData, phep.poolData);
    }
    function startShipExped(uint16 portID, uint256 inputGold, uint256 blockInterval) external {
        PortShipExpedPool storage psep = _shipExpeditions[portID];
        require(psep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        ShipExpeditionTeam storage team = psep.expedShips[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");
        
        _startExped(inputGold, blockInterval, team.teamHashRate, psep.poolConf, team.teamData, psep.poolData);
    }

    function fetchHeroExpedMTT(uint16 portID) external {
        PortHeroExpedPool storage phep = _heroExpeditions[portID];
        require(phep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        HeroExpeditionTeam storage team = phep.expedHeros[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");
    
        // output mtt
        _outputMTT(phep.poolData);

        _fetchExpedMTT(phep.poolConf, team.teamData, phep.poolData);
    }
    function fetchShipExpedMTT(uint16 portID) external {
        PortShipExpedPool storage psep = _shipExpeditions[portID];
        require(psep.poolConf.minMTTPerBlock > 0, "Expedition: port expedition config not exist");
        
        ShipExpeditionTeam storage team = psep.expedShips[_msgSender()];
        require(team.teamHashRate > 0, "Expedition: team not exist");
        
        // output mtt
        _outputMTT(psep.poolData);

        _fetchExpedMTT(psep.poolConf, team.teamData, psep.poolData);
    }

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
    ) external override pure returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (GameService.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../MTT.sol";
import "../MTTGold.sol";
import "../nft/HeroNFT.sol";
import "../nft/ShipNFT.sol";
import "../nft/WarrantNFT.sol";

import "../utility/Crypto.sol";
import "../utility/TransferHelper.sol";

contract GameService is
    Context,
    Pausable,
    AccessControl 
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event BindHeroNFTUsage(address indexed userAddr, uint256 indexed heroNFTID, string usage);
    event UnbindHeroNFTUsage(address indexed userAddr, uint256 indexed heroNFTID, string usage);
    event BindShipNFT(address indexed userAddr, uint256 indexed shipNFTID);
    event UnbindShipNFT(address indexed userAddr, uint256 indexed shipNFTID);
    event BindWarrant(address indexed userAddr, uint256 indexed warrantNFTID);
    event UnbindWarrant(address indexed userAddr, uint256 indexed warrantNFTID);
    
    address public _heroNFTAddr;
    address public _shipNFTAddr;
    address public _warrantNFTAddr;
    address public _MTTAddr;
    address public _MTTGoldAddr;

    mapping(uint256=>bytes32) public _heroNFTUsage; // nftid => usage
    mapping(uint256=>bool) public _shipNFTBind; // nftid => is bind

    mapping(address=>mapping(uint32=>uint256)) public _bindWarrant; // user address => port id => warrant id

//    address public _serviceAddr;
//    mapping(address=>uint64) public _userOpSignatureSeed; // user address => signature seed

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(SERVICE_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "GameService: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "GameService: must have pauser role to unpause"
        );
        _unpause();
    }
    
    function init(
//        address serviceAddr,
        address heroNFTAddr,
        address shipNFTAddr,
        address warrantNFTAddr,
        address MTTAddr,
        address MTTGoldAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "GameService: must have manager role");

//        _serviceAddr = serviceAddr;
        _heroNFTAddr = heroNFTAddr;
        _shipNFTAddr = shipNFTAddr;
        _warrantNFTAddr = warrantNFTAddr;
        _MTTAddr = MTTAddr;
        _MTTGoldAddr = MTTGoldAddr;
    }

    function bindHeroNFTUsage(uint256 heroNFTID, string calldata usage) external whenNotPaused {
        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == _msgSender(), "GameService: ownership error");
        require(_heroNFTUsage[heroNFTID] == bytes32(0), "GameService: already binded");

        HeroNFT(_heroNFTAddr).freeze(heroNFTID);

        _heroNFTUsage[heroNFTID] = keccak256(abi.encodePacked(usage));

        emit BindHeroNFTUsage(_msgSender(), heroNFTID, usage);
    }

    function unbindHeroNFTUsage(
        uint256 heroNFTID, 
        string calldata usage,
        address userAddr
        //bytes calldata serviceSignature
        ) external whenNotPaused
    {
        require(hasRole(SERVICE_ROLE, _msgSender()), "GameService: must have service role");

        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == userAddr, "GameService: ownership error");
        require(_heroNFTUsage[heroNFTID] != bytes32(0), "GameService: nft usage not exist");

        // uint64 sigSeed = _userOpSignatureSeed[_msgSender()];
        // _userOpSignatureSeed[_msgSender()] = sigSeed + 1;

        // require(Crypto.verifySignature(abi.encodePacked("unbind", _msgSender(), heroNFTID, sigSeed), serviceSignature, _serviceAddr), "GameService: wrong signature");

        HeroNFT(_heroNFTAddr).unfreeze(heroNFTID);
        delete _heroNFTUsage[heroNFTID];

        emit UnbindHeroNFTUsage(userAddr, heroNFTID, usage);
    }
    
    function bindShipNFT(uint256 shipNFTID) external whenNotPaused {
        require(HeroNFT(_shipNFTAddr).ownerOf(shipNFTID) == _msgSender(), "GameService: ownership error");
        require(!_shipNFTBind[shipNFTID], "GameService: already binded");

        ShipNFT(_shipNFTAddr).freeze(shipNFTID);

        _shipNFTBind[shipNFTID] = true;

        emit BindShipNFT(_msgSender(), shipNFTID);
    }

    function unbindShipNFT(
        uint256 shipNFTID,
        uint16 portID,
        address userAddr
    ) external whenNotPaused
    {
        require(hasRole(SERVICE_ROLE, _msgSender()), "GameService: must have service role");

        require(ShipNFT(_shipNFTAddr).ownerOf(shipNFTID) == userAddr, "GameService: ownership error");
        require(_shipNFTBind[shipNFTID], "GameService: nft not bind");

        ShipNFT(_shipNFTAddr).modNftPort(shipNFTID, portID);
        
        ShipNFT(_shipNFTAddr).unfreeze(shipNFTID);
        delete _shipNFTBind[shipNFTID];

        emit UnbindShipNFT(userAddr, shipNFTID);
    }
    
    function bindWarrant(uint256 warrantNFTID) external whenNotPaused {
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == _msgSender(), "GameService: ownership error");

        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        require(_bindWarrant[_msgSender()][wdata.portID] == 0, "GameService: already bind");

        // bind
        _bindWarrant[_msgSender()][wdata.portID] = warrantNFTID;
        WarrantNFT(_warrantNFTAddr).freeze(warrantNFTID);

        emit BindWarrant(_msgSender(), warrantNFTID);
    }

    function unbindWarrant(
        uint256 warrantNFTID, 
        address userAddr
    ) external whenNotPaused{
        require(hasRole(SERVICE_ROLE, _msgSender()), "GameService: must have service role");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == userAddr, "GameService: ownership error");

        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        require(_bindWarrant[userAddr][wdata.portID] == warrantNFTID, "GameService: warrant bind addr error");

        // unbind
        WarrantNFT(_warrantNFTAddr).unfreeze(warrantNFTID);
        delete _bindWarrant[userAddr][wdata.portID];

        emit UnbindWarrant(userAddr, warrantNFTID);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (HeroPetTrain.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../utility/OracleCharger.sol";

import "../nft/WarrantNFT.sol";
import "../nft/HeroNFT.sol";
import "../nft/HeroNFTCodec.sol";

import "../MTTGold.sol";

contract HeroPetTrain is
    Context,
    Pausable,
    AccessControl 
{
    using OracleCharger for OracleCharger.OracleChargerStruct;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");

    event StartUpgrade_HeroOrPet(address indexed userAddr, uint256 indexed heroNFTID, uint256 indexed warrantNFTID, uint16 nextLevel, uint32 finishTime);
    event FinishUpgrade_HeroOrPet(address indexed userAddr, uint256 indexed heroNFTID, uint16 newLevel);
    
    event StartUpStarLv_Hero(address indexed userAddr, uint256 indexed heroNFTID, uint256 indexed warrantNFTID, uint16 nextStarLevel, uint32 finishTime);
    event FinishUpStarLv_Hero(address indexed userAddr, uint256 indexed heroNFTID, uint16 newStarLevel);
    
    struct HeroPetUpgradeConf {
        uint256 goldPrice; // upgrade cost gold price, 18 decimal
        uint32 timeCost; // upgrade cost time, in second
        uint16 portIDRequire; // train port id require
    }
    struct HeroPetUpgarding {
        uint16 nextLevel; // new level
        uint32 finishTime; //  finish time, unix timestamp in second
    }

    struct HeroUpStarLevelConf {
        uint256 usdPrice; // upgrade cost usd price, 18 decimal
        uint32 timeCost; // upgrade cost time, in second
        uint16 heroLevelRequire; // hero level require
        uint16 portIDRequire; // train port id require
    }
    struct HeroStarLvUping {
        uint8 nextStarLevel; // new star level
        uint32 finishTime; //  finish time, unix timestamp in second
    }

    OracleCharger.OracleChargerStruct public _oracleCharger;

    address public _warrantNFTAddr;
    address public _heroNFTAddr;
    address public _MTTGoldAddr;
    
    mapping(uint16=>mapping(uint8=>mapping(uint16=>HeroPetUpgradeConf))) public _heropetUpgradeConfs; // nfttype => job/petId => level => upgrade config
    mapping(uint256=>HeroPetUpgarding) public _upgradingHeroPets; // hero/pet nft id => upgrading data
    
    mapping(uint8=>mapping(uint16=>HeroUpStarLevelConf)) public _heroStarLvUpConfs; // job => level => star level up config
    mapping(uint256=>HeroStarLvUping) public _upingStarLvHeros; // hero nft id => star level uping data

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(SERVICE_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "HeroPetTrain: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "HeroPetTrain: must have pauser role to unpause"
        );
        _unpause();
    }
    
    function setTPOracleAddr(address tpOracleAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _oracleCharger.setTPOracleAddr(tpOracleAddr);
    }

    function setReceiveIncomeAddr(address incomeAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _oracleCharger.setReceiveIncomeAddr(incomeAddr);
    }

    // maximumUSDPrice = 0: no limit
    // minimumUSDPrice = 0: no limit
    function addChargeToken(
        string memory tokenName, 
        address tokenAddr, 
        uint256 maximumUSDPrice, 
        uint256 minimumUSDPrice
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _oracleCharger.addChargeToken(tokenName, tokenAddr, maximumUSDPrice, minimumUSDPrice);
    }

    function removeChargeToken(string memory tokenName) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _oracleCharger.removeChargeToken(tokenName);
    }

    function init(
        address warrantNFTAddr,
        address heroNFTAddr,
        address MTTGoldAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _warrantNFTAddr = warrantNFTAddr;
        _heroNFTAddr = heroNFTAddr;
        _MTTGoldAddr = MTTGoldAddr;
    }
    
    function setUpgradeConf(uint16 nftType, uint8 joborpetid, uint16[] memory levels, HeroPetUpgradeConf[] memory confs) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");
        require(levels.length == confs.length, "HeroPetTrain: input error");

        for(uint i= 0; i< levels.length; ++i){
            _heropetUpgradeConfs[nftType][joborpetid][levels[i]] = confs[i];
        }
    }
    function clearUpgradeConf(uint16 nftType, uint8 joborpetid, uint16[] memory levels) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        for(uint i= 0; i< levels.length; ++i){
            delete _heropetUpgradeConfs[nftType][joborpetid][levels[i]];
        }
    }
    
    function setStarLvUpConf(uint8 job, uint16 level, HeroUpStarLevelConf memory conf) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        _heroStarLvUpConfs[job][level] = conf;
    }
    function clearStarLvUpConf(uint8 job, uint16 level) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "HeroPetTrain: must have manager role");

        delete _heroStarLvUpConfs[job][level];
    }
    
    function startUpgrade_HeroOrPet(
        uint256 heroNFTID,
        uint256 goldPrice,
        uint256 warrantNFTID
    ) external whenNotPaused {
        require(_upgradingHeroPets[heroNFTID].nextLevel == 0, "HeroPetTrain: hero or pet is upgrading");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == _msgSender(), "HeroPetTrain: warrant ownership error");
        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == _msgSender(), "HeroPetTrain: not your hero or pet");
        // TO DO : check freeze?

        HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(heroNFTID);
        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());

        uint16 level;
        HeroPetUpgradeConf memory upConf;
        if(hdb.nftType == 1) { // hero 
            HeroNFTFixedData_V1 memory hndata = codec.getHeroNftFixedData(hdb);
            HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);

            level = wdata.level;
            upConf = _heropetUpgradeConfs[hdb.nftType][hndata.job][level];
        } 
        else if(hdb.nftType == 2) { // pet
            HeroPetNFTFixedData_V1 memory hndata = codec.getHeroPetNftFixedData(hdb);
            HeroPetNFTWriteableData_V1 memory wdata = codec.getHeroPetNftWriteableData(hdb);
            
            level = wdata.level;
            upConf = _heropetUpgradeConfs[hdb.nftType][hndata.petId][level];
        }
        else {
            revert("HeroPetTrain: nft type error");
        }

        require(upConf.goldPrice > 0, "HeroPetTrain: hero or pet upgrade config not exist");
        require(upConf.goldPrice <= goldPrice, "HeroPetTrain: price error");
        
        // get warrant nft data
        WarrantNFTData memory wadata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        require(wadata.portID == upConf.portIDRequire, "HeroPetTrain: portID wrong");

        // burn gold
        MTTGold(_MTTGoldAddr).burnFrom(_msgSender(), upConf.goldPrice);

        HeroPetUpgarding memory upd = HeroPetUpgarding({
            nextLevel:level+1,
            finishTime:uint32(block.timestamp) + upConf.timeCost
        });
        _upgradingHeroPets[heroNFTID] = upd;

        emit StartUpgrade_HeroOrPet(_msgSender(), heroNFTID, warrantNFTID, upd.nextLevel, upd.finishTime);
    }

    function finishUpgrade_HeroOrPet(
        uint256 heroNFTID
    ) external whenNotPaused {
        
        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == _msgSender(), "HeroPetTrain: not your hero or pet");
        // TO DO : check freeze?

        HeroPetUpgarding storage upd = _upgradingHeroPets[heroNFTID];
        require(upd.nextLevel > 0, "HeroPetTrain: hero or pet is not upgrading");
        require(upd.finishTime <= uint32(block.timestamp), "HeroPetTrain: hero or pet upgrade not finish yet");

        HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(heroNFTID);
        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());

        uint256 writeableData;
        if(hdb.nftType == 1) { // hero 
            HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);
            wdata.level = upd.nextLevel;

            writeableData = codec.toHeroNftWriteableData(wdata);
        } 
        else if(hdb.nftType == 2) { // pet
            HeroPetNFTWriteableData_V1 memory wdata = codec.getHeroPetNftWriteableData(hdb);
            wdata.level = upd.nextLevel;
            
            writeableData = codec.toHeroPetNftWriteableData(wdata);
        }
        else {
            revert("HeroPetTrain: nft type error");
        }
        
        HeroNFT(_heroNFTAddr).modNftData(heroNFTID, writeableData);

        emit FinishUpgrade_HeroOrPet(_msgSender(), heroNFTID, upd.nextLevel);

        delete _upgradingHeroPets[heroNFTID];
    }

    function startUpStarLv_Hero(
        uint256 heroNFTID,
        uint256 usdPrice,
        string memory tokenName,
        uint256 warrantNFTID
    ) external payable whenNotPaused {
        require(_upingStarLvHeros[heroNFTID].nextStarLevel == 0, "HeroPetTrain: hero is upgrading");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == _msgSender(), "HeroPetTrain: warrant ownership error");
        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == _msgSender(), "HeroPetTrain: not your hero");
        // TO DO : check freeze?

        HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(heroNFTID);
        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());

        require(hdb.nftType == 1, "HeroPetTrain: not hero nft"); // hero

        HeroNFTFixedData_V1 memory hndata = codec.getHeroNftFixedData(hdb);
        HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);

        HeroUpStarLevelConf memory upConf = _heroStarLvUpConfs[hndata.job][wdata.starLevel];
        
        require(wdata.level >= upConf.heroLevelRequire, "HeroPetTrain: hero level not enough");

        require(upConf.usdPrice > 0, "HeroPetTrain: hero upgrade config not exist");
        require(upConf.usdPrice <= usdPrice, "HeroPetTrain: price error");
        
        // get warrant nft data
        WarrantNFTData memory wadata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        require(wadata.portID == upConf.portIDRequire, "HeroPetTrain: portID wrong");

        // charge
        _oracleCharger.charge(tokenName, upConf.usdPrice);

        HeroStarLvUping memory upd = HeroStarLvUping({
            nextStarLevel:wdata.starLevel+1,
            finishTime:uint32(block.timestamp) + upConf.timeCost
        });
        _upingStarLvHeros[heroNFTID] = upd;

        emit StartUpStarLv_Hero(_msgSender(), heroNFTID, warrantNFTID, upd.nextStarLevel, upd.finishTime);
    }

    function finishUpStarLv_Hero(
        uint256 heroNFTID
    ) external whenNotPaused {
        
        require(HeroNFT(_heroNFTAddr).ownerOf(heroNFTID) == _msgSender(), "HeroPetTrain: not your hero");
        // TO DO : check freeze?

        HeroStarLvUping storage upd = _upingStarLvHeros[heroNFTID];
        require(upd.nextStarLevel > 0, "HeroPetTrain: hero is not upgrading");
        require(upd.finishTime <= uint32(block.timestamp), "HeroPetTrain: hero upgrade not finish yet");

        HeroNFTDataBase memory hdb = HeroNFT(_heroNFTAddr).getNftData(heroNFTID);
        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(HeroNFT(_heroNFTAddr).getCodec());
        
        require(hdb.nftType == 1, "HeroPetTrain: not hero nft"); // hero

        HeroNFTWriteableData_V1 memory wdata = codec.getHeroNftWriteableData(hdb);
        wdata.starLevel = upd.nextStarLevel;

        uint256 writeableData = codec.toHeroNftWriteableData(wdata);
        
        HeroNFT(_heroNFTAddr).modNftData(heroNFTID, writeableData);

        delete _upingStarLvHeros[heroNFTID];

        emit FinishUpStarLv_Hero(_msgSender(), heroNFTID, wdata.starLevel);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Expedition.sol)

pragma solidity >=0.8.0 <=0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../MTT.sol";

import "../utility/TransferHelper.sol";

contract MTTMinePool is
    Context,
    AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    event MTTMinePoolSend(address indexed userAddr, address indexed caller, uint256 value, bytes reason);

    uint256 public immutable MTT_PER_BLOCK; 

    MTT public MTTContract;

    uint256 public MTT_TOTAL_OUTPUT;

    uint256 public MTT_LIQUIDITY;
    uint256 public MTT_LAST_OUTPUT_BLOCK;

    constructor(
        address _MTTAddr,
        uint256 _perblock
    ) {
        require(_perblock > 0, "MTTMinePool: mtt per block must >0");

        MTTContract = MTT(_MTTAddr);

        MTT_PER_BLOCK = _perblock;
        MTT_LAST_OUTPUT_BLOCK = block.number;
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function _output() internal {
        if(MTT_LAST_OUTPUT_BLOCK >= block.number){
            return;
        }

        uint256 output = (block.number - MTT_LAST_OUTPUT_BLOCK) * MTT_PER_BLOCK;
        MTT_LAST_OUTPUT_BLOCK = block.number;
        MTT_LIQUIDITY += output;
        MTT_TOTAL_OUTPUT += output;
    }

    function send(address userAddr, uint256 value, bytes memory reason) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "MTTMinePool: must have minter role");

        _output();

        require(MTT_LIQUIDITY >= value, "MTTMinePool: short of liquidity");
        require(MTTContract.balanceOf(address(this)) >= value, "MTTMinePool: insufficient MTT");

        MTT_LIQUIDITY -= value;
        TransferHelper.safeTransfer(address(MTTContract), userAddr, value);

        emit MTTMinePoolSend(userAddr, _msgSender(), value, reason);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (OffOnChainBridge.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../MTT.sol";
import "../MTTGold.sol";
import "../nft/WarrantNFT.sol";

import "../utility/TransferHelper.sol";
import "../utility/OracleCharger.sol";

contract OffOnChainBridge is
    Context,
    Pausable,
    AccessControl 
{
    using OracleCharger for OracleCharger.OracleChargerStruct;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    event Off2OnChain_MTTGold(address userAddr, uint256 goldValue);
    event On2OffChain_MTTGold(address userAddr, uint256 goldValue);
    
    OracleCharger.OracleChargerStruct public _oracleCharger;
    
    address public _warrantNFTAddr;
    address public _MTTAddr;
    address public _MTTGoldAddr;

    mapping(uint16=>mapping(uint16=>uint256)) public _shopGoldMaxGen; // port id => shop level => max gold generate per second (18 decimal)
    mapping(uint256=>uint32) public _lastWarrantGenGoldTm; // warrant id => last generate gold time, unix timestamp in second

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(SERVICE_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "OffOnChainBridge: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "OffOnChainBridge: must have pauser role to unpause"
        );
        _unpause();
    }
    
    function setTPOracleAddr(address tpOracleAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _oracleCharger.setTPOracleAddr(tpOracleAddr);
    }

    function setReceiveIncomeAddr(address incomeAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _oracleCharger.setReceiveIncomeAddr(incomeAddr);
    }

    // maximumUSDPrice = 0: no limit
    // minimumUSDPrice = 0: no limit
    function addChargeToken(
        string memory tokenName, 
        address tokenAddr, 
        uint256 maximumUSDPrice, 
        uint256 minimumUSDPrice
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _oracleCharger.addChargeToken(tokenName, tokenAddr, maximumUSDPrice, minimumUSDPrice);
    }

    function removeChargeToken(string memory tokenName) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _oracleCharger.removeChargeToken(tokenName);
    }
    
    function init(
        address warrantNFTAddr,
        address MTTAddr,
        address MTTGoldAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _warrantNFTAddr = warrantNFTAddr;
        _MTTAddr = MTTAddr;
        _MTTGoldAddr = MTTGoldAddr;
    }

    // maxGoldGen: 18 decimal
    function setShopGoldMaxGen(uint16 portID, uint16 shopLv, uint256 maxGoldGenPerSec) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "OffOnChainBridge: must have manager role");

        _shopGoldMaxGen[portID][shopLv] = maxGoldGenPerSec;
    }

    function mint_MTTGold(
        address userAddr, 
        uint256 goldValue, 
        uint256 warrantNFTID
    ) external whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "OffOnChainBridge: must have minter role");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == userAddr, "OffOnChainBridge: warrant ownership error");
        require(goldValue > 0, "OffOnChainBridge: parameter error");

        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);

        uint32 lasttm = _lastWarrantGenGoldTm[warrantNFTID];
        if(lasttm == 0){
            lasttm = wdata.createTm;
        }
        require(block.timestamp > lasttm, "OffOnChainBridge: time error");

        // calc max gold gen
        uint256 maxGoldGenPerSec = _shopGoldMaxGen[wdata.portID][wdata.shopLv];
        uint256 maxGoldGen = maxGoldGenPerSec * (block.timestamp - lasttm);
        require(maxGoldGen >= goldValue, "OffOnChainBridge: gold value overflow");

        _lastWarrantGenGoldTm[warrantNFTID] = uint32(block.timestamp);

        MTTGold(_MTTGoldAddr).mint(userAddr, goldValue);
    }

    function off2onChain_MTTGold(address userAddr, uint256 goldValue) external whenNotPaused {
        require(hasRole(SERVICE_ROLE, _msgSender()), "OffOnChainBridge: must have service role");
        require(MTTGold(_MTTGoldAddr).balanceOf(address(this)) >= goldValue, "OffOnChainBridge: insufficient MTTGold");

        TransferHelper.safeTransferFrom(_MTTGoldAddr, address(this), userAddr, goldValue);
        
        emit Off2OnChain_MTTGold(userAddr, goldValue);
    }

    function on2offChain_MTTGold(uint256 goldValue) external whenNotPaused {
        require(MTTGold(_MTTGoldAddr).balanceOf(address(_msgSender())) >= goldValue, "OffOnChainBridge: insufficient MTTGold");

        TransferHelper.safeTransferFrom(_MTTGoldAddr, _msgSender(), address(this), goldValue);

        emit On2OffChain_MTTGold(_msgSender(), goldValue);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Shipyard.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../utility/OracleCharger.sol";

import "../nft/WarrantNFT.sol";
import "../nft/ShipNFT.sol";

contract Shipyard is
    Context,
    Pausable,
    AccessControl 
{
    using OracleCharger for OracleCharger.OracleChargerStruct;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    event StartUpgrade_Ship(address indexed userAddr, uint256 indexed shipNFTID, uint256 indexed warrantNFTID, uint16 nextLevel, uint32 finishTime);
    event FinishUpgrade_Ship(address indexed userAddr, uint256 indexed shipNFTID, uint16 newLevel);

    struct ShipUpgradeConf {
        uint256 usdPrice; // upgrade cost usd price, 18 decimal
        uint32 timeCost; // upgrade cost time, in second
        uint16 portIDRequire; // shipyard port id require
        uint16 shipyardLvRequire; // require shipyard level
    }
    struct ShipUpgarding {
        uint16 nextLevel; // new level
        uint32 finishTime; //  finish time, unix timestamp in second
    }

    OracleCharger.OracleChargerStruct public _oracleCharger;

    address public _warrantNFTAddr;
    address public _shipNFTAddr;

    mapping(uint16=>mapping(uint16=>uint24[])) public _buildabelShips; // port id => shipyard level => array of mintable ships (shipType<<16 | shipTypeID)
    mapping(uint24=>mapping(uint16=>ShipUpgradeConf)) public _shipUpgradeConfs; // (shipType<<16 | shipTypeID) => ship level => upgrade config
    mapping(uint256=>ShipUpgarding) public _upgradingShips; // ship nft id => upgrading data

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(SERVICE_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Shipyard: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Shipyard: must have pauser role to unpause"
        );
        _unpause();
    }
    
    function setTPOracleAddr(address tpOracleAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _oracleCharger.setTPOracleAddr(tpOracleAddr);
    }

    function setReceiveIncomeAddr(address incomeAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _oracleCharger.setReceiveIncomeAddr(incomeAddr);
    }

    // maximumUSDPrice = 0: no limit
    // minimumUSDPrice = 0: no limit
    function addChargeToken(
        string memory tokenName, 
        address tokenAddr, 
        uint256 maximumUSDPrice, 
        uint256 minimumUSDPrice
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _oracleCharger.addChargeToken(tokenName, tokenAddr, maximumUSDPrice, minimumUSDPrice);
    }

    function removeChargeToken(string memory tokenName) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _oracleCharger.removeChargeToken(tokenName);
    }

    function init(
        address warrantNFTAddr,
        address shipNFTAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _warrantNFTAddr = warrantNFTAddr;
        _shipNFTAddr = shipNFTAddr;
    }

    function setBuildableShips(uint16 portID, uint8 shipyardLv, uint24[] memory buildableShipArray) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        _buildabelShips[portID][shipyardLv] = buildableShipArray;
    }
    function clearBuildableShips(uint16 portID, uint8 shipyardLv) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        delete _buildabelShips[portID][shipyardLv];
    }
    function setUpgradeConf(uint8 shipType, uint16 shipTypeID, uint16[] memory shipLevels, ShipUpgradeConf[] memory confs) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");
        require(shipLevels.length == confs.length, "Shipyard: input error");

        for(uint i=0; i< shipLevels.length; ++i){
            _shipUpgradeConfs[(uint24(shipType)<<16 | shipTypeID)][shipLevels[i]] = confs[i];
        }
    }
    function clearUpgradeConf(uint8 shipType, uint16 shipTypeID, uint16[] memory shipLevels) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Shipyard: must have manager role");

        for(uint i = 0; i< shipLevels.length; ++i){
            delete _shipUpgradeConfs[(uint24(shipType)<<16 | shipTypeID)][shipLevels[i]];
        }
    }

    function mint_Ship(
        address userAddr, 
        uint8 shipType, 
        uint16 shipTypeID,
        uint8 grade,
        uint32 minerAttr,
        uint32 battleAttr,
        uint256 warrantNFTID
    ) external whenNotPaused {
        require(hasRole(MINTER_ROLE, _msgSender()), "Shipyard: must have minter role");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == userAddr, "Shipyard: warrant ownership error");

        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);

        uint24 shipID = (uint24(shipType)<<16 | shipTypeID);
        uint24[] storage shipArray = _buildabelShips[wdata.portID][wdata.shipyardLv];
        uint i=0;
        for(; i< shipArray.length; ++i){
            if(shipID == shipArray[i]){
                break;
            }
        }

        require(i < shipArray.length, "Shipyard: ship not buildable");

        ShipNFT(_shipNFTAddr).mint(userAddr, ShipNFTData({
            shipType:shipType,
            shipTypeID:shipTypeID,
            grade:grade,
            minerAttr:minerAttr,
            battleAttr:battleAttr,
            level:1,
            portID:wdata.portID
        }));
    }

    function startUpgrade_Ship(
        uint256 shipNFTID,
        uint256 usdPrice,
        string memory tokenName,
        uint256 warrantNFTID
    ) external payable whenNotPaused {
        require(_upgradingShips[shipNFTID].nextLevel == 0, "Shipyard: ship is upgrading");
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == _msgSender(), "Shipyard: warrant ownership error");
        require(ShipNFT(_shipNFTAddr).ownerOf(shipNFTID) == _msgSender(), "Shipyard: not your ship");

        ShipNFTData memory shipdata = ShipNFT(_shipNFTAddr).getNftData(shipNFTID);

        uint24 shipID = (uint24(shipdata.shipType)<<16 | shipdata.shipTypeID);

        ShipUpgradeConf storage upConf = _shipUpgradeConfs[shipID][shipdata.level];
        require(upConf.usdPrice > 0, "Shipyard: ship upgrade config not exist");
        require(upConf.usdPrice <= usdPrice, "Shipyard: price error");
        
        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        require(wdata.portID == upConf.portIDRequire, "Shipyard: portID wrong");
        require(wdata.shipyardLv >= upConf.shipyardLvRequire, "Shipyard: shipyard level require");

        _oracleCharger.charge(tokenName, upConf.usdPrice);

        ShipUpgarding memory upd = ShipUpgarding({
            nextLevel:shipdata.level+1,
            finishTime:uint32(block.timestamp) + upConf.timeCost
        });
        _upgradingShips[shipNFTID] = upd;

        emit StartUpgrade_Ship(_msgSender(), shipNFTID, warrantNFTID, upd.nextLevel, upd.finishTime);
    }

    function finishUpgrade_Ship(
        uint256 shipNFTID
    ) external whenNotPaused {
        require(ShipNFT(_shipNFTAddr).ownerOf(shipNFTID) == _msgSender(), "Shipyard: not your ship");

        ShipUpgarding storage upd = _upgradingShips[shipNFTID];
        require(upd.nextLevel > 0, "Shipyard: ship is not upgrading");
        require(upd.finishTime <= uint32(block.timestamp), "Shipyard: ship upgrade not finish yet");

        ShipNFTData memory shipdata = ShipNFT(_shipNFTAddr).getNftData(shipNFTID);

        shipdata.level = upd.nextLevel;

        ShipNFT(_shipNFTAddr).modNftData(shipNFTID, shipdata);

        delete _upgradingShips[shipNFTID];

        emit FinishUpgrade_Ship(_msgSender(), shipNFTID, shipdata.level);
    }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (WarrantIssuer.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../utility/OracleCharger.sol";

import "../nft/WarrantNFT.sol";

contract WarrantIssuer is
    Context,
    Pausable,
    AccessControl 
{
    using OracleCharger for OracleCharger.OracleChargerStruct;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    OracleCharger.OracleChargerStruct public _oracleCharger;

    address public _warrantNFTAddr;

    mapping(uint16=>uint256) public _warrantPrices; // port id => usd price
    mapping(uint16=>mapping(uint8=>mapping(uint16=>uint256))) _warrantUpgradePrice; // port id => upgrade type => level => usd price

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "WarrantIssuer: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "WarrantIssuer: must have pauser role to unpause"
        );
        _unpause();
    }
    
    function setTPOracleAddr(address tpOracleAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _oracleCharger.setTPOracleAddr(tpOracleAddr);
    }

    function setReceiveIncomeAddr(address incomeAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _oracleCharger.setReceiveIncomeAddr(incomeAddr);
    }

    // maximumUSDPrice = 0: no limit
    // minimumUSDPrice = 0: no limit
    function addChargeToken(
        string memory tokenName, 
        address tokenAddr, 
        uint256 maximumUSDPrice, 
        uint256 minimumUSDPrice
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _oracleCharger.addChargeToken(tokenName, tokenAddr, maximumUSDPrice, minimumUSDPrice);
    }

    function removeChargeToken(string memory tokenName) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _oracleCharger.removeChargeToken(tokenName);
    }

    function init(
        address warrantNFTAddr
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _warrantNFTAddr = warrantNFTAddr;
    }

    // usdPrice: 18 decimal
    function setWarrantPrice(uint16 portID, uint256 usdPrice) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _warrantPrices[portID] = usdPrice;
    }
    // usdPrice: 18 decimal
    function setWarrantUpgradePrice(uint16 portID, uint8 upgradeType, uint16 level, uint256 usdPrice) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        _warrantUpgradePrice[portID][upgradeType][level] = usdPrice;
    }
    function clearWarrantUpgradePrice(uint16 portID, uint8 upgradeType, uint16 level) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "WarrantIssuer: must have manager role");

        delete _warrantUpgradePrice[portID][upgradeType][level];
    }

    function mint_MTTWarrant(uint16 portID, uint256 usdPrice, string memory tokenName) external payable whenNotPaused {
        uint256 _usdPrice = _warrantPrices[portID];
        require(_usdPrice > 0, "WarrantIssuer: port not exist");
        require(_usdPrice <= usdPrice, "WarrantIssuer: price parameter error");

        _oracleCharger.charge(tokenName, _usdPrice);

        WarrantNFT(_warrantNFTAddr).mint(_msgSender(), WarrantNFTData({
            portID:portID,
            storehouseLv:1,
            factoryLv:1,
            shopLv:1,
            shipyardLv:0,
            createTm:uint32(block.timestamp)
        }));
    }

    function upgrade_MTTWarrant(
        uint256 warrantNFTID,
        uint8 upgradeType,
        uint256 usdPrice,
        string memory tokenName
    ) external payable whenNotPaused{
        require(WarrantNFT(_warrantNFTAddr).ownerOf(warrantNFTID) == _msgSender(), "WarrantIssuer: ownership error");

        // get warrant nft data
        WarrantNFTData memory wdata = WarrantNFT(_warrantNFTAddr).getNftData(warrantNFTID);
        uint256 _usdPrice = 0;

        mapping(uint8=>mapping(uint16=>uint256)) storage upPrices = _warrantUpgradePrice[wdata.portID];

        if(upgradeType == 1) { // upgrade storehouse
            _usdPrice = upPrices[upgradeType][wdata.storehouseLv];
            ++wdata.storehouseLv;
        }
        else if(upgradeType == 2) { // upgrade factory
            _usdPrice = upPrices[upgradeType][wdata.factoryLv];
            ++wdata.factoryLv;
        }
        else if(upgradeType == 3) { // upgrade shop
            _usdPrice = upPrices[upgradeType][wdata.shopLv];
            ++wdata.shopLv;
        }
        else if(upgradeType == 4) { // upgrade shipyard
            _usdPrice = upPrices[upgradeType][wdata.shipyardLv];
            ++wdata.shipyardLv;
        }
        
        require(_usdPrice > 0 && _usdPrice <= usdPrice, "WarrantIssuer: price error");

        _oracleCharger.charge(tokenName, _usdPrice);

        WarrantNFT(_warrantNFTAddr).modNftData(warrantNFTID, wdata);
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
// Metaline Contracts (MTT.sol)

pragma solidity ^0.8.0;

import "./core/CappedERC20.sol";

// Metaline Token
contract MTT is CappedERC20 {

    constructor()
        CappedERC20("MetaLine Token", "MTT", 300000000000000000000000000)
    {

    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (CapedERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MTTGold is 
    Context, 
    ERC20Burnable
{
    bool public _sealed;
    address public _bridgeAddr;
    address public _owner;
    
    constructor(address bridgeAddr) 
        ERC20("MetaLine Gold", "MTG") 
    {
        _bridgeAddr = bridgeAddr;
        _owner = _msgSender();
        _sealed = false;
    }

    // seal it when bridge contract is stable
    function changeBridgeAddr(address bridgeAddr, bool isSealed) external {
        require(!_sealed, "MTTGold: sealed");
        require(_msgSender() == _owner, "MTTGold: must be owner");
        _bridgeAddr = bridgeAddr;
        _sealed = isSealed;
    }

    function mint(address toAddr, uint256 value) external {
        require(_msgSender() == _bridgeAddr, "MTTGold: must have minter role");
        _mint(toAddr, value);
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (DirectMysteryBox.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../utility/TransferHelper.sol";
import "../utility/GasFeeCharger.sol";

import "./MBRandomSourceBase.sol";

contract DirectMysteryBox is 
    Context,
    Pausable,
    AccessControl,
    IOracleRandComsumer
{
    using GasFeeCharger for GasFeeCharger.MethodExtraFees;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant RAND_ROLE = keccak256("RAND_ROLE");

    event SetOnSaleDirectMB(uint32 indexed directMBID, DirectOnSaleMB saleConfig, DirectOnSaleMBRunTime saleData);

    event DirectMBOpen(address indexed useAddr, uint32 indexed directMBID);
    event DirectMBGetResult(address indexed useAddr, uint32 indexed directMBID, MBContentMinter1155Info[] sfts, MBContentMinterNftInfo[] nfts);

    event DirectMBBatchOpen(address indexed useAddr, uint32 indexed directMBID, uint256 batchCount);
    event DirectMBBatchGetResult(address indexed useAddr, uint32 indexed directMBID, MBContentMinter1155Info[] sfts, MBContentMinterNftInfo[] nfts);

    struct DirectMBOpenRecord {
        address userAddr;
        uint32 directMBID;
        uint8 batchCount;
    }

    struct DirectOnSaleMB {
        address randsource; // mystery box address
        uint32 mysteryType; // mystery type

        address tokenAddr; // charge token addr, could be 20 or 1155
        uint256 tokenId; // =0 means 20 token, else 1155 token
        uint256 price; // price value

        uint64 beginTime; // start sale timeStamp in seconds since unix epoch, =0 ignore this condition
        uint64 endTime; // end sale timeStamp in seconds since unix epoch, =0 ignore this condition

        uint64 renewTime; // how long in seconds for each renew
        uint256 renewCount; // how many count put on sale for each renew
    }
    
    struct DirectOnSaleMBRunTime {
        // runtime data -------------------------------------------------------
        uint64 nextRenewTime; // after this timeStamp in seconds since unix epoch, will put at max [renewCount] on sale

        // config & runtime data ----------------------------------------------
        uint256 countLeft; // how many boxies left
    }

    mapping(uint256=>DirectMBOpenRecord) public _openedRecord; // indexed by oracleRand request id
    mapping(uint32=>DirectOnSaleMB) public _onsaleMB; // indexed by directMBID
    mapping(uint32=>DirectOnSaleMBRunTime) public _onsaleMBDatas; // indexed by directMBID
    
    address public _receiveIncomAddress;

    // Method extra fee
    // For smart contract method which need extra transaction by other service, we define extra fee
    // extra fee charge by method call tx with `value` paramter, and send to target service wallet address
    GasFeeCharger.MethodExtraFees _methodExtraFees;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Metaline: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RAND_ROLE, _msgSender());
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "DirectMysteryBox: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "DirectMysteryBox: must have pauser role to unpause"
        );
        _unpause();
    }

    function setOnSaleDirectMB(uint32 directMBID, DirectOnSaleMB memory saleConfig, DirectOnSaleMBRunTime memory saleData) external whenNotPaused {
        require(hasRole(MANAGER_ROLE, _msgSender()), "DirectMysteryBox: must have manager role to manage");

        if(saleConfig.renewTime > 0)
        {
            saleData.nextRenewTime = (uint64)(block.timestamp + saleConfig.renewTime);
        }

        _onsaleMB[directMBID] = saleConfig;
        _onsaleMBDatas[directMBID] = saleData;

        emit SetOnSaleDirectMB(directMBID, saleConfig, saleData);
    }

    function setReceiveIncomeAddress(address incomAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "DirectMysteryBox: must have manager role to manage");

        _receiveIncomAddress = incomAddr;
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
            "DirectMysteryBox: must have manager role"
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
            "DirectMysteryBox: must have manager role"
        );

        _methodExtraFees.removeMethodExtraFee(methodKey);
    }
    
    function _checkSellCondition(DirectOnSaleMB storage onSalePair, DirectOnSaleMBRunTime storage onSalePairData) internal {
        if(onSalePair.beginTime > 0)
        {
            require(block.timestamp >= onSalePair.beginTime, "DirectMysteryBox: sale not begin");
        }
        if(onSalePair.endTime > 0)
        {
            require(block.timestamp <= onSalePair.endTime, "DirectMysteryBox: sale finished");
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

    
    function _chargeByDesiredCount(DirectOnSaleMB storage onSalePair, DirectOnSaleMBRunTime storage onSalePairData, uint256 count, uint256 gasfee) 
        internal returns (uint256 realCount)
    {
        realCount = count;
        if(realCount > onSalePairData.countLeft)
        {
            realCount = onSalePairData.countLeft;
        }

        require(realCount > 0, "DirectMysteryBox: insufficient mystery box");

        onSalePairData.countLeft -= realCount;

        if(onSalePair.price > 0){
            uint256 realPrice = onSalePair.price * realCount;

            if(realPrice > 0){
                if(onSalePair.tokenAddr == address(0)){
                    uint256 valueLeft = msg.value - gasfee;
                    require(valueLeft >= realPrice, "DirectMysteryBox: insufficient value");

                    // receive eth
                    (bool sent, ) = _receiveIncomAddress.call{value:realPrice}("");
                    require(sent, "DirectMysteryBox: transfer income error");
                    if(valueLeft > realPrice){
                        (sent, ) = msg.sender.call{value:(valueLeft - realPrice)}(""); // send back
                        require(sent, "MysteryBoxShop: transfer income error");
                    }
                }
                else if(onSalePair.tokenId > 0)
                {
                    // 1155
                    require(IERC1155(onSalePair.tokenAddr).balanceOf( _msgSender(), onSalePair.tokenId) >= realPrice , "DirectMysteryBox: erc1155 insufficient token");
                    IERC1155(onSalePair.tokenAddr).safeTransferFrom(_msgSender(), _receiveIncomAddress, onSalePair.tokenId, realPrice, "direct mb");
                }
                else{
                    // 20
                    require(IERC20(onSalePair.tokenAddr).balanceOf(_msgSender()) >= realPrice , "DirectMysteryBox: erc20 insufficient token");
                    TransferHelper.safeTransferFrom(onSalePair.tokenAddr, _msgSender(), _receiveIncomAddress, realPrice);
                }
            }
        }

    }

    function openMB(uint32 directMBID) external payable lock whenNotPaused {
        require(tx.origin == _msgSender(), "DirectMysteryBox: only for outside account");
        require(_receiveIncomAddress != address(0), "DirectMysteryBox: receive income address not set");
        
        DirectOnSaleMB storage onSalePair = _onsaleMB[directMBID];
        DirectOnSaleMBRunTime storage onSalePairData = _onsaleMBDatas[directMBID];
        require(address(onSalePair.randsource) != address(0), "DirectMysteryBox: mystery box not on sale");

        address rndAddr = MBRandomSourceBase(onSalePair.randsource).getRandSource();
        require(rndAddr != address(0), "DirectMysteryBox: rand address wrong");

        uint256 gasfee = _methodExtraFees.chargeMethodExtraFee(1); // charge openMB extra fee
        
        _checkSellCondition(onSalePair, onSalePairData);
        _chargeByDesiredCount(onSalePair, onSalePairData, 1, gasfee);

        // request random number
        uint256 reqid = IRandom(rndAddr).oracleRand();

        DirectMBOpenRecord storage openRec = _openedRecord[reqid];
        openRec.directMBID = directMBID;
        openRec.userAddr = _msgSender();
        openRec.batchCount = 0;

        // emit direct mb open event
        emit DirectMBOpen(_msgSender(), directMBID);
    }

    function batchOpenMB(uint32 directMBID, uint8 batchCount) external payable lock whenNotPaused {
        require(tx.origin == _msgSender(), "DirectMysteryBox: only for outside account");
        require(_receiveIncomAddress != address(0), "DirectMysteryBox: receive income address not set");
        
        DirectOnSaleMB storage onSalePair = _onsaleMB[directMBID];
        DirectOnSaleMBRunTime storage onSalePairData = _onsaleMBDatas[directMBID];
        require(address(onSalePair.randsource) != address(0), "DirectMysteryBox: mystery box not on sale");

        require(batchCount >0 && batchCount <= 50, "DirectMysteryBox: batch open count must <= 50");

        address rndAddr = MBRandomSourceBase(onSalePair.randsource).getRandSource();
        require(rndAddr != address(0), "DirectMysteryBox: rand address wrong");

        uint256 gasfee = _methodExtraFees.chargeMethodExtraFee(2); // charge batchOpenMB extra fee

        _checkSellCondition(onSalePair, onSalePairData);
        _chargeByDesiredCount(onSalePair, onSalePairData, batchCount, gasfee);

        // request random number
        uint256 reqid = IRandom(rndAddr).oracleRand();

        DirectMBOpenRecord storage openRec = _openedRecord[reqid];
        openRec.directMBID = directMBID;
        openRec.userAddr = _msgSender();
        openRec.batchCount = batchCount;

        // emit direct mb open event
        emit DirectMBBatchOpen(_msgSender(), directMBID, batchCount);
    }

    // get rand number, real open mystery box
    function oracleRandResponse(uint256 reqid, uint256 randnum) override external {
        require(hasRole(RAND_ROLE, _msgSender()), "DirectMysteryBox: must have rand role");

        DirectMBOpenRecord storage openRec = _openedRecord[reqid];
        
        DirectOnSaleMB storage onSalePair = _onsaleMB[openRec.directMBID];
        require(address(onSalePair.randsource) != address(0), "DirectMysteryBox: mystery box not on sale");

        address rndAddr = MBRandomSourceBase(onSalePair.randsource).getRandSource();
        require(rndAddr != address(0), "DirectMysteryBox: rand address wrong");

        require(openRec.userAddr != address(0), "DirectMysteryBox: user address wrong");

        if(openRec.batchCount > 0){
            (MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts) 
                = MBRandomSourceBase(onSalePair.randsource).batchRandomAndMint(randnum, onSalePair.mysteryType, openRec.userAddr, openRec.batchCount);

            emit DirectMBBatchGetResult(openRec.userAddr, openRec.directMBID, sfts, nfts);
        }
        else {
            (MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts) 
                = MBRandomSourceBase(onSalePair.randsource).randomAndMint(randnum, onSalePair.mysteryType, openRec.userAddr);

            emit DirectMBGetResult(openRec.userAddr, openRec.directMBID, sfts, nfts);
        }
        
        delete _openedRecord[reqid];
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (MBRandomSourceBase.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../core/IRandom.sol";
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

    IRandom _rand;
    mapping(uint32 => NFTRandPool)    _randPools; // poolID => nft data random pools
    mapping(uint32 => uint32[])       _mbRandomSets; // mystery type => poolID array

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(RANDOM_ROLE, _msgSender());
    }

    function setRandSource(address randAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()));

        _rand = IRandom(randAddr);
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
// Metaline Contracts (MysteryBox1155.sol)

pragma solidity ^0.8.0;

import "../core/Extendable1155.sol";

// 1155 id : combine with randomType(uint32) << 32 | mysteryType(uint32)
contract MysteryBox1155 is Extendable1155 {

    constructor(string memory uri) Extendable1155("MetaLine MysteryBox Semi-fungible Token", "MLMB", uri) {
        mint(_msgSender(), 0, 1, new bytes(0)); // mint first token to notify event scan
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (MysteryBoxBase.sol)

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

        uint256 reqid = IRandom(rndAddr).oracleRand();

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
        
        uint256 reqid = IRandom(rndAddr).oracleRand();

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
// Metaline Contracts (HeroNFT.sol)

pragma solidity ^0.8.0;

import "../utility/ResetableCounters.sol";
import "../core/ExtendableNFT.sol";

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

    /**
    * @dev emit when token data modified
    *
    * @param tokenId token id
    * @param writeableData token data see {HeroNFTDataBase}
    */
    event HeroNFTModified(uint256 indexed tokenId, uint256 writeableData);

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

        // mint(_msgSender(), HeroNFTDataBase({
        //     nftType:0,
        //     fixedData:0,
        //     writeableData:0
        // })); // mint first token to notify event scan
        
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

        emit HeroNFTModified(tokenId, writeableData);
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
// Metaline Contracts (HeroNFTCodec.sol)

pragma solidity ^0.8.0;

/**
 * @dev base struct of hero nft data
 */
struct HeroNFTDataBase
{
    uint8 mintType; // = 0 normal mint, = 1: genesis mint
    uint16 nftType; // = 1: hero nft, = 2: pet nft
    uint232 fixedData;
    uint256 writeableData;
}

/**
 * @dev hero fixed nft data version 1
 */
struct HeroNFTFixedData_V1 {
    uint8 job;
    uint8 grade;

    uint32 minerAttr;
    uint32 battleAttr;
}

/**
 * @dev hero pet fixed nft data version 1
 */
struct HeroPetNFTFixedData_V1 {
    uint8 petId;
    uint8 avatar_slot_1_2;
    uint8 avatar_slot_3_4;
    uint8 avatar_slot_5_6;

    uint32 minerAttr;
    uint32 battleAttr;
}

/**
 * @dev hero writeable nft data version 1
 */
struct HeroNFTWriteableData_V1 {
    uint8 starLevel;
    uint16 level;
}

/**
 * @dev hero writeable nft data version 1
 */
struct HeroPetNFTWriteableData_V1 {
    uint16 level;
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
    * @dev encode HeroNFTPetFixedData to HeroNFTDataBase
    * @param data input data of HeroPetNFTFixedData_V1
    * @return basedata output data of HeroNFTDataBase
    */
    function fromHeroPetNftFixedData(HeroPetNFTFixedData_V1 memory data) external pure returns (HeroNFTDataBase memory basedata);

    /**
    * @dev encode HeroNFTFixedData to HeroNFTDataBase
    * @param fdata input data of HeroNFTFixedData_V1
    * @param wdata input data of HeroNFTWriteableData_V1
    * @return basedata output data of HeroNFTDataBase
    */
    function fromHeroNftFixedAnWriteableData(HeroNFTFixedData_V1 memory fdata, HeroNFTWriteableData_V1 memory wdata) external pure returns (HeroNFTDataBase memory basedata);

    /**
    * @dev encode HeroNFTFixedData to HeroNFTDataBase
    * @param fdata input data of HeroPetNFTFixedData_V1
    * @param wdata input data of HeroPetNFTWriteableData_V1
    * @return basedata output data of HeroNFTDataBase
    */
    function fromHeroPetNftFixedAnWriteableData(HeroPetNFTFixedData_V1 memory fdata, HeroPetNFTWriteableData_V1 memory wdata) external pure returns (HeroNFTDataBase memory basedata);

    /**
    * @dev decode HeroNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroNFTFixedData_V1
    */
    function getHeroNftFixedData(HeroNFTDataBase memory data) external pure returns(HeroNFTFixedData_V1 memory hndata);

    /**
    * @dev decode HeroPetNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroPetNFTFixedData_V1
    */
    function getHeroPetNftFixedData(HeroNFTDataBase memory data) external pure returns(HeroPetNFTFixedData_V1 memory hndata);

    /**
    * @dev encode HeroNFTData to HeroNFTDataBase writeable
    * @param hndata input data of HeroNFTWriteableData_V1
    * @return wdata output data of HeroNFTDataBase writeable
    */
    function toHeroNftWriteableData(HeroNFTWriteableData_V1 memory hndata) external pure returns(uint256 wdata);
    
    /**
    * @dev encode HeroPetNFTData to HeroNFTDataBase writeable
    * @param hndata input data of HeroPetNFTWriteableData_V1
    * @return wdata output data of HeroNFTDataBase writeable
    */
    function toHeroPetNftWriteableData(HeroPetNFTWriteableData_V1 memory hndata) external pure returns(uint256 wdata);

    /**
    * @dev decode HeroNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroNFTWriteableData_V1
    */
    function getHeroNftWriteableData(HeroNFTDataBase memory data) external pure returns(HeroNFTWriteableData_V1 memory hndata);
    
    /**
    * @dev decode HeroPetNFTData from HeroNFTDataBase
    * @param data input data of HeroNFTDataBase
    * @return hndata output data of HeroPetNFTWriteableData_V1
    */
    function getHeroPetNftWriteableData(HeroNFTDataBase memory data) external pure returns(HeroPetNFTWriteableData_V1 memory hndata);

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
            uint232(data.job) |
            (uint232(data.grade) << 8) |
            (uint232(data.minerAttr) << (8 + 8)) |
            (uint232(data.battleAttr) << (8 + 8 + 32));

        basedata.nftType = 1;
        //basedata.mintType = 0;
        //basedata.writeableData = 0;
    }
    
    function fromHeroPetNftFixedData(HeroPetNFTFixedData_V1 memory data)
        external
        pure
        override
        returns (HeroNFTDataBase memory basedata)
    {
        basedata.fixedData =
            uint232(data.petId) |
            (uint232(data.avatar_slot_1_2) << 8) |
            (uint232(data.avatar_slot_3_4) << (8 + 8)) |
            (uint232(data.avatar_slot_5_6) << (8 + 8 + 8)) |
            (uint232(data.minerAttr) << (8 + 8 + 8 + 8)) |
            (uint232(data.battleAttr) << (8 + 8 + 8 + 8 + 32));

        basedata.nftType = 2;
        //basedata.mintType = 0;
        //basedata.writeableData = 0;
    }

    function fromHeroNftFixedAnWriteableData(HeroNFTFixedData_V1 memory fdata, HeroNFTWriteableData_V1 memory wdata) 
        external 
        pure 
        override 
        returns (HeroNFTDataBase memory basedata)
    {
        basedata.fixedData =
            uint232(fdata.job) |
            (uint232(fdata.grade) << 8) |
            (uint232(fdata.minerAttr) << (8 + 8)) |
            (uint232(fdata.battleAttr) << (8 + 8 + 32));

        basedata.writeableData = 
            (uint256(wdata.starLevel)) |
            (uint256(wdata.level << 8));
            
        //basedata.mintType = 0;
        basedata.nftType = 1;
    }
    
    function fromHeroPetNftFixedAnWriteableData(HeroPetNFTFixedData_V1 memory fdata, HeroPetNFTWriteableData_V1 memory wdata) 
        external 
        pure
        override 
        returns (HeroNFTDataBase memory basedata) 
    {
        basedata.fixedData =
            uint232(fdata.petId) |
            (uint232(fdata.avatar_slot_1_2) << 8) |
            (uint232(fdata.avatar_slot_3_4) << (8 + 8)) |
            (uint232(fdata.avatar_slot_5_6) << (8 + 8 + 8)) |
            (uint232(fdata.minerAttr) << (8 + 8 + 8 + 8)) |
            (uint232(fdata.battleAttr) << (8 + 8 + 8 + 8 + 32));

        basedata.writeableData = 
            (uint256(wdata.level));
            
        //basedata.mintType = 0;
        basedata.nftType = 2;
    }

    function getHeroNftFixedData(HeroNFTDataBase memory data)
        external
        pure
        override
        returns (HeroNFTFixedData_V1 memory hndata)
    {
        hndata.job = uint8(data.fixedData & 0xff);
        hndata.grade = uint8((data.fixedData >> 8) & 0xff);
        hndata.minerAttr = uint32((data.fixedData >> (8 + 8)) & 0xffffffff);
        hndata.battleAttr = uint32((data.fixedData >> (8 + 8 + 32)) & 0xffffffff);
    }

    function getHeroPetNftFixedData(HeroNFTDataBase memory data)
        external
        pure
        override
        returns (HeroPetNFTFixedData_V1 memory hndata)
    {
        hndata.petId = uint8(data.fixedData & 0xff);
        hndata.avatar_slot_1_2 = uint8((data.fixedData >> 8) & 0xff);
        hndata.avatar_slot_3_4 = uint8((data.fixedData >> (8 + 8)) & 0xff);
        hndata.avatar_slot_5_6 = uint8((data.fixedData >> (8 + 8 + 8)) & 0xff);
        hndata.minerAttr = uint32((data.fixedData >> (8 + 8 + 8 + 8)) & 0xffffffff);
        hndata.battleAttr = uint16((data.fixedData >> (8 + 8 + 8 + 8 + 32)) & 0xffffffff);
    }
    
    function toHeroNftWriteableData(HeroNFTWriteableData_V1 memory hndata) 
        external 
        pure 
        override 
        returns(uint256 wdata) 
    {
        return
            (uint256(hndata.starLevel)) |
            (uint256(hndata.level << 8));
    }
    
    function toHeroPetNftWriteableData(HeroPetNFTWriteableData_V1 memory hndata) 
        external 
        pure 
        override 
        returns(uint256 wdata) 
    {
        return
            (uint256(hndata.level));
    }

    function getHeroNftWriteableData(HeroNFTDataBase memory data) 
        external 
        pure 
        override 
        returns(HeroNFTWriteableData_V1 memory hndata)
    {
        hndata.starLevel = uint8(data.writeableData & 0xff);
        hndata.level = uint16((data.writeableData >> 8) & 0xffff);
    }
    
    function getHeroPetNftWriteableData(HeroNFTDataBase memory data) 
        external 
        pure 
        override 
        returns(HeroPetNFTWriteableData_V1 memory hndata)
    {
        hndata.level = uint16(data.writeableData & 0xffff);
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

import "../mysterybox/MysteryBoxBase.sol";

contract HeroNFTMysteryBox is MysteryBoxBase
{    
    function getName() external virtual override returns(string memory)
    {
        return "Hero NFT Mystery Box";
    }
}

// SPDX-License-Identifier: MIT
// DreamIdol Contracts (HeroNFTMysteryBox.sol)

pragma solidity ^0.8.0;

import "../mysterybox/MBRandomSourceBase.sol";

import "./HeroNFTCodec.sol";
import "./HeroNFT.sol";

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

        require(poolIDArray.length == 33, "mb type config wrong");

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
        
        NFTRandPool storage pool = _randPools[poolIDArray[0]]; // index 0 : job rand (1-15)
        require(pool.exist, "job pool not exist");
        uint8 job = uint8(pool.randPool.random(r));

        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[1]]; // index 1 : grade rand (1-10)
        require(pool.exist, "grade pool not exist");
        uint8 grade = uint8(pool.randPool.random(r));

        if(job <= 2){
            pool = _randPools[poolIDArray[1 + grade]]; // index 2-11 : job(1-2) mineAttr rand by grade 
        }
        else{
            pool = _randPools[poolIDArray[11 + grade]]; // index 12-21 : job(3-15) mineAttr rand by grade
        }
        r = _rand.nextRand(++index, r);
        require(pool.exist, "mineAttr pool not exist");
        uint16 mineAttr = uint8(pool.randPool.random(r));

        pool = _randPools[poolIDArray[21 + grade]]; // index 22-31 : battleAttr rand by grade
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
            level : 1
        });

        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(_heroNFTContract.getCodec());
        baseData = codec.fromHeroNftFixedAnWriteableData(fdata, wdata);
        baseData.mintType = uint8(poolIDArray[32]); // index 32 : mint type
    }

    function batchRandomAndMint(uint256 r, uint32 mysteryTp, address to, uint8 batchCount) virtual override external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "ownership error");

        uint32[] storage poolIDArray = _mbRandomSets[mysteryTp];

        require(poolIDArray.length == 33, "mb type config wrong");

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

// SPDX-License-Identifier: MIT
// DreamIdol Contracts (HeroNFTMysteryBox.sol)

pragma solidity ^0.8.0;

import "../mysterybox/MBRandomSourceBase.sol";

import "./HeroNFTCodec.sol";
import "./HeroNFT.sol";

contract HeroPetNFTMysteryBoxRandSource is 
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

        require(poolIDArray.length == 10, "mb type config wrong");

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
        
        NFTRandPool storage pool = _randPools[poolIDArray[0]]; // index 0 : petId rand (1-5)
        require(pool.exist, "job pool not exist");
        uint8 petId = uint8(pool.randPool.random(r));

        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[1]]; // index 1 : avatar slot 1 rand (1-10)
        require(pool.exist, "grade pool not exist");
        uint8 avatar_slot_1_2 = uint8(pool.randPool.random(r)) << 4;
        
        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[2]]; // index 2 : avatar slot 2 rand (1-10)
        require(pool.exist, "grade pool not exist");
        avatar_slot_1_2 |= uint8(pool.randPool.random(r));
        
        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[3]]; // index 3 : avatar slot 3 rand (1-10)
        require(pool.exist, "grade pool not exist");
        uint8 avatar_slot_3_4 = uint8(pool.randPool.random(r)) << 4;
        
        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[4]]; // index 4 : avatar slot 4 rand (1-10)
        require(pool.exist, "grade pool not exist");
        avatar_slot_3_4 |= uint8(pool.randPool.random(r));
        
        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[5]]; // index 5 : avatar slot 5 rand (1-10)
        require(pool.exist, "grade pool not exist");
        uint8 avatar_slot_5_6 = uint8(pool.randPool.random(r)) << 4;
        
        r = _rand.nextRand(++index, r);
        pool = _randPools[poolIDArray[6]]; // index 6 : avatar slot 6 rand (1-10)
        require(pool.exist, "grade pool not exist");
        avatar_slot_5_6 |= uint8(pool.randPool.random(r));

        pool = _randPools[poolIDArray[7]]; // index 7 : mineAttr rand
        r = _rand.nextRand(++index, r);
        require(pool.exist, "mineAttr pool not exist");
        uint16 mineAttr = uint8(pool.randPool.random(r));

        pool = _randPools[poolIDArray[8]]; // index 8 : battleAttr rand
        r = _rand.nextRand(++index, r);
        require(pool.exist, "battleAttr pool not exist");
        uint16 battleAttr = uint8(pool.randPool.random(r));

        HeroPetNFTFixedData_V1 memory fdata = HeroPetNFTFixedData_V1({
            petId : petId,
            avatar_slot_1_2 : avatar_slot_1_2,
            avatar_slot_3_4 : avatar_slot_3_4,
            avatar_slot_5_6 : avatar_slot_5_6,
            minerAttr : mineAttr,
            battleAttr : battleAttr
        });

        HeroPetNFTWriteableData_V1 memory wdata = HeroPetNFTWriteableData_V1({
            level:1
        });

        IHeroNFTCodec_V1 codec = IHeroNFTCodec_V1(_heroNFTContract.getCodec());
        baseData = codec.fromHeroPetNftFixedAnWriteableData(fdata, wdata);
        baseData.mintType = uint8(poolIDArray[9]); // index 9 : mint type
    }

    function batchRandomAndMint(uint256 r, uint32 mysteryTp, address to, uint8 batchCount) virtual override external 
        returns(MBContentMinter1155Info[] memory sfts, MBContentMinterNftInfo[] memory nfts)
    {
        require(hasRole(MINTER_ROLE, _msgSender()), "ownership error");

        uint32[] storage poolIDArray = _mbRandomSets[mysteryTp];

        require(poolIDArray.length == 10, "mb type config wrong");

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

// SPDX-License-Identifier: MIT
// Metaline Contracts (HeroNFTAttrSource.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

 /**
  * @dev hero nft miner attribute
  */
 struct HeroNFTMinerAttr {
     uint32 produceRate;
     uint32 minerRate;
     uint32 shopRate;
     uint16 sailerSpeedPer;
     uint16 sailerLoadPer;
     uint16 sailerRangePer;
     uint32 hashRate;
 }

 /**
  * @dev hero nft battle attribute
  */
 struct HeroNFTBattleAttr { 
     uint32 attack;
     uint32 defense;
     uint32 hitpoint;
     uint16 miss;
     uint16 doge;
     uint16 critical;
     uint16 decritical;
     uint16 speed;
 }
 
 /**
  * @dev ship nft miner attribute
  */
 struct ShipNFTMinerAttr {
    uint16 speed;
    uint32 maxLoad;
    uint32 maxRange;
    uint32 foodPerMile;
    uint8 maxSailer;
    uint32 hashRate;
    
    // TO DO : add attr
 }

 /**
  * @dev ship nft battle attribute
  */
 struct ShipNFTBattleAttr { 
    uint32 attack;
    uint32 defense;
    uint32 hitpoint;
    uint16 miss;
    uint16 doge;
    uint16 critical;
    uint16 decritical;
    uint16 speed;
    uint8 maxSailer;

    // TO DO : add attr
 }

/**
 * @dev nft attribute source contract
 */
contract NFTAttrSource_V1 is
    Context,
    AccessControl
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    mapping(uint32=>HeroNFTMinerAttr) public _heroMineAttrs;
    mapping(uint32=>HeroNFTBattleAttr) public _heroBattleAttrs;

    mapping(uint32=>ShipNFTMinerAttr) public _shipMineAttrs;
    mapping(uint32=>ShipNFTBattleAttr) public _shipBattleAttrs;

    uint16 public _heroMineFactor;
    uint16 public _heroBattleFactor;
    uint16 public _shipMineFactor;
    uint16 public _shipBattleFactor;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
    }

    // attr = attr * (1 + factor / 10000) 
    function setLevelUpFactor(
        uint16 heroMineFactor, 
        uint16 heroBattleFactor, 
        uint16 shipMineFactor, 
        uint16 shipBattleFactor
    ) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "NFTAttrSource_V1: must have manager role to manage");

        _heroMineFactor = heroMineFactor;
        _heroBattleFactor = heroBattleFactor;
        _shipMineFactor = shipMineFactor;
        _shipBattleFactor = shipBattleFactor;

    }

    /**
    * @dev get hero or pet miner attribute by mineAttr
    * @param mineAttr miner attribtue id
    * @param starLevel hero star level, if nft is pet, startLevel always = 1
    * @return data output data of HeroNFTMinerAttr
    */
    function getHeroMinerAttr(uint32 mineAttr, uint16 starLevel) external view returns (HeroNFTMinerAttr memory data)
    {
        data = _heroMineAttrs[mineAttr];
        data.produceRate = uint32(data.produceRate + uint64(data.produceRate) * starLevel * _heroMineFactor / 10000);
        data.minerRate = uint32(data.minerRate + uint64(data.minerRate) * starLevel * _heroMineFactor / 10000);
        data.shopRate = uint32(data.shopRate + uint64(data.shopRate) * starLevel * _heroMineFactor / 10000);
        data.sailerSpeedPer = uint16(data.sailerSpeedPer + uint64(data.sailerSpeedPer) * starLevel * _heroMineFactor / 10000);
        data.sailerLoadPer = uint16(data.sailerLoadPer + uint64(data.sailerLoadPer) * starLevel * _heroMineFactor / 10000);
        data.sailerRangePer = uint16(data.sailerRangePer + uint64(data.sailerRangePer) * starLevel * _heroMineFactor / 10000);
        data.hashRate = uint32(data.hashRate + uint64(data.hashRate) * starLevel * _heroMineFactor / 10000);
    }

    /**
    * @dev get hero or pet battle attribute by battleAttr
    * @param battleAttr battle attribtue id
    * @param level hero or pet nft level
    * @return data output data of HeroNFTBattleAttr
    */
    function getHeroBattleAttr(uint32 battleAttr, uint16 level) external view returns (HeroNFTBattleAttr memory data)
    {
        data = _heroBattleAttrs[battleAttr];
        data.attack = uint32(data.attack + uint64(data.attack) * level * _heroBattleFactor / 10000);
        data.defense = uint32(data.defense + uint64(data.defense) * level * _heroBattleFactor / 10000);
        data.hitpoint = uint32(data.hitpoint + uint64(data.hitpoint) * level * _heroBattleFactor / 10000);
        data.miss = uint16(data.miss + uint64(data.miss * level) * _heroBattleFactor / 10000);
        data.doge = uint16(data.doge + uint64(data.doge * level) * _heroBattleFactor / 10000);
        data.critical = uint16(data.critical + uint64(data.critical) * level * _heroBattleFactor / 10000);
        data.decritical = uint16(data.decritical + uint64(data.decritical) * level * _heroBattleFactor / 10000);
        data.speed = uint16(data.speed + uint64(data.speed) * level * _heroBattleFactor / 10000);
    }

    /**
    * @dev set hero or pet miner attributes
    * @param mineAttrs mine attribute ids
    * @param datas input data array of HeroNFTMinerAttr
    */
    function setHeroMinerAttr(uint32[] memory mineAttrs, HeroNFTMinerAttr[] memory datas) external
    {
        require(mineAttrs.length == datas.length, "NFTAttrSource_V1: parameter error");
        require(hasRole(MANAGER_ROLE, _msgSender()), "NFTAttrSource_V1: must have manager role to manage");

        for(uint i=0; i< mineAttrs.length; ++i){
            _heroMineAttrs[mineAttrs[i]] = datas[i];
        }
    }

    /**
    * @dev set hero or pet battle attributes
    * @param battleAttrs battle attribute ids
    * @param datas input data array of HeroNFTBattleAttr
    */
    function setHeroBattleAttr(uint32[] memory battleAttrs, HeroNFTBattleAttr[] memory datas) external
    {
        require(battleAttrs.length == datas.length, "NFTAttrSource_V1: parameter error");
        require(hasRole(MANAGER_ROLE, _msgSender()), "NFTAttrSource_V1: must have manager role to manage");

        for(uint i=0; i< battleAttrs.length; ++i){
            _heroBattleAttrs[battleAttrs[i]] = datas[i];
        }
    }
    
    /**
    * @dev get ship miner attribute by mineAttr
    * @param mineAttr miner attribtue id
    * @param level ship nft level
    * @return data output data of ShipNFTMinerAttr
    */
    function getShipMinerAttr(uint32 mineAttr, uint16 level) external view returns (ShipNFTMinerAttr memory data)
    {
        data = _shipMineAttrs[mineAttr];
        
        data.speed = uint16(data.speed + uint64(data.speed) * level * _shipMineFactor / 10000);
        data.maxLoad = uint32(data.maxLoad + uint64(data.maxLoad) * level * _shipMineFactor / 10000);
        data.maxRange = uint32(data.maxRange + uint64(data.maxRange) * level * _shipMineFactor / 10000);
        data.foodPerMile = uint32(data.foodPerMile + uint64(data.foodPerMile) * level * _shipMineFactor / 10000);
        data.maxSailer = uint8(data.maxSailer + uint64(data.maxSailer) * level * _shipMineFactor / 10000);
        data.hashRate = uint32(data.hashRate + uint64(data.hashRate) * level * _shipMineFactor / 10000);
    }

    /**
    * @dev get ship battle attribute by battleAttr
    * @param battleAttr battle attribtue id
    * @param level ship nft level
    * @return data output data of ShipNFTBattleAttr
    */
    function getShipBattleAttr(uint32 battleAttr, uint16 level) external view returns (ShipNFTBattleAttr memory data)
    {
        data = _shipBattleAttrs[battleAttr];
        data.attack = uint32(data.attack + uint64(data.attack) * level * _shipBattleFactor / 10000);
        data.defense = uint32(data.defense + uint64(data.defense) * level * _shipBattleFactor / 10000);
        data.hitpoint = uint32(data.hitpoint + uint64(data.hitpoint) * level * _shipBattleFactor / 10000);
        data.miss = uint16(data.miss + uint64(data.miss * level) * _shipBattleFactor / 10000);
        data.doge = uint16(data.doge + uint64(data.doge * level) * _shipBattleFactor / 10000);
        data.critical = uint16(data.critical + uint64(data.critical) * level * _shipBattleFactor / 10000);
        data.decritical = uint16(data.decritical + uint64(data.decritical) * level * _shipBattleFactor / 10000);
        data.speed = uint16(data.speed + uint64(data.speed) * level * _shipBattleFactor / 10000);
        data.maxSailer = uint8(data.maxSailer + uint64(data.maxSailer) * level * _shipBattleFactor / 10000);
    }

    /**
    * @dev set ship miner attributes
    * @param mineAttrs mine attribute ids
    * @param datas input data array of ShipNFTMinerAttr
    */
    function setShipMinerAttr(uint32[] memory mineAttrs, ShipNFTMinerAttr[] memory datas) external
    {
        require(mineAttrs.length == datas.length, "NFTAttrSource_V1: parameter error");
        require(hasRole(MANAGER_ROLE, _msgSender()), "NFTAttrSource_V1: must have manager role to manage");

        for(uint i=0; i< mineAttrs.length; ++i){
            _shipMineAttrs[mineAttrs[i]] = datas[i];
        }
    }

    /**
    * @dev set ship battle attributes
    * @param battleAttrs battle attribute ids
    * @param datas input data array of ShipNFTBattleAttr
    */
    function setShipBattleAttr(uint32[] memory battleAttrs, ShipNFTBattleAttr[] memory datas) external
    {
        require(battleAttrs.length == datas.length, "NFTAttrSource_V1: parameter error");
        require(hasRole(MANAGER_ROLE, _msgSender()), "NFTAttrSource_V1: must have manager role to manage");

        for(uint i=0; i< battleAttrs.length; ++i){
            _shipBattleAttrs[battleAttrs[i]] = datas[i];
        }
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (ShipNFT.sol)

pragma solidity ^0.8.0;

import "../utility/ResetableCounters.sol";
import "../core/ExtendableNFT.sol";

struct ShipNFTData {
    uint8 shipType; // = 1 transport ship, = 2 battle ship
    uint16 shipTypeID; // ship id
    uint8 grade; // ship grade
    
    uint32 minerAttr; 
    uint32 battleAttr;

    uint16 level;
    uint16 portID;
}

/**
 * @dev Extension of {ExtendableNFT} that with fixed token data struct
 */
contract ShipNFT is ExtendableNFT {
    using ResetableCounters for ResetableCounters.Counter;

    /**
    * @dev emit when new token has been minted, see {ShipNFTData}
    *
    * @param to owner of new token
    * @param tokenId new token id
    * @param data token data see {ShipNFTData}
    */
    event ShipNFTMint(address indexed to, uint256 indexed tokenId, ShipNFTData data);
    
    /**
    * @dev emit when token data modified
    *
    * @param tokenId token id
    * @param data token data see {ShipNFTData}
    */
    event ShipNFTModified(uint256 indexed tokenId, ShipNFTData data);
    
    event ShipNFTPortModified(uint256 indexed tokenId, uint16 portID);

    ResetableCounters.Counter internal _tokenIdTracker;
    
    address public _attrSource;
    
    mapping(uint256 => ShipNFTData) private _nftDatas; // token id => nft data stucture

    constructor(
        uint256 idStart,
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        ExtendableNFT(name, symbol, baseTokenURI)
    {
       _tokenIdTracker.reset(idStart);

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

    /**
     * @dev Creates a new token for `to`, emit {ShipNFTMint}. Its token ID will be automatically
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
     * @param data token data see {ShipNFTData}
     * @return new token id
     */
    function mint(address to, ShipNFTData memory data) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        _nftDatas[curID] = data;

        emit ShipNFTMint(to, curID, data);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }

    /**
     * @dev Creates a new token for `to`, emit {ShipNFTMint}. Its token ID give by caller
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
     * @param data token data see {ShipNFTData}
     * @return new token id
     */
    function mintFixedID(
        uint256 id,
        address to,
        ShipNFTData memory data
    ) public returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        require(!_exists(id), "RE");

        _mint(to, id);

        // Save token datas
        _nftDatas[id] = data;

        emit ShipNFTMint(to, id, data);

        return id;
    }

    /**
     * @dev modify token data
     *
     * @param tokenId token id
     * @param data token data see {ShipNFTData}
     */
    function modNftData(uint256 tokenId, ShipNFTData memory data) external {
        require(hasRole(DATA_ROLE, _msgSender()), "R1");

        ShipNFTData storage wdata = _nftDatas[tokenId];
        wdata.level = data.level;
        wdata.portID = data.portID;

        emit ShipNFTModified(tokenId, wdata);
    }
    function modNftPort(uint256 tokenId, uint16 portID) external {
        require(hasRole(DATA_ROLE, _msgSender()), "R1");

        ShipNFTData storage wdata = _nftDatas[tokenId];
        wdata.portID = portID;

        emit ShipNFTPortModified(tokenId, portID);
    }


    /**
     * @dev get token data
     *
     * @param tokenId token id
     * @param data token data see {ShipNFTData}
     */
    function getNftData(uint256 tokenId) external view returns(ShipNFTData memory data){
        require(_exists(tokenId), "T1");

        data = _nftDatas[tokenId];
    }

}

// SPDX-License-Identifier: MIT
// Metaline Contracts (WarrantNFT.sol)

pragma solidity ^0.8.0;

import "../utility/ResetableCounters.sol";
import "../core/ExtendableNFT.sol";

struct WarrantNFTData {
    uint32 createTm;
    uint16 portID;
    uint16 storehouseLv;
    uint16 factoryLv;
    uint16 shopLv;
    uint16 shipyardLv;
}

/**
 * @dev Extension of {ExtendableNFT} that with fixed token data struct
 */
contract WarrantNFT is ExtendableNFT {
    using ResetableCounters for ResetableCounters.Counter;

    /**
    * @dev emit when new token has been minted, see {WarrantNFTData}
    *
    * @param to owner of new token
    * @param tokenId new token id
    * @param data token data see {WarrantNFTData}
    */
    event WarrantNFTMint(address indexed to, uint256 indexed tokenId, WarrantNFTData data);
    
    /**
    * @dev emit when token data modified
    *
    * @param tokenId token id
    * @param data token data see {WarrantNFTData}
    */
    event WarrantNFTModified(uint256 indexed tokenId, WarrantNFTData data);

    ResetableCounters.Counter internal _tokenIdTracker;
    
    mapping(uint256 => WarrantNFTData) private _nftDatas; // token id => nft data stucture

    constructor(
        uint256 idStart,
        string memory name,
        string memory symbol,
        string memory baseTokenURI) 
        ExtendableNFT(name, symbol, baseTokenURI)
    {
       _tokenIdTracker.reset(idStart);

       _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
       _setupRole(DATA_ROLE, _msgSender());
    }

    /**
     * @dev Creates a new token for `to`, emit {WarrantNFTMint}. Its token ID will be automatically
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
     * @param data token data see {WarrantNFTData}
     * @return new token id
     */
    function mint(address to, WarrantNFTData memory data) public returns(uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        uint256 curID = _tokenIdTracker.current();

        _mint(to, curID);

        // Save token datas
        _nftDatas[curID] = data;

        emit WarrantNFTMint(to, curID, data);

        // increase token id
        _tokenIdTracker.increment();

        return curID;
    }

    /**
     * @dev Creates a new token for `to`, emit {WarrantNFTMint}. Its token ID give by caller
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
     * @param data token data see {WarrantNFTData}
     * @return new token id
     */
    function mintFixedID(
        uint256 id,
        address to,
        WarrantNFTData memory data
    ) public returns (uint256) {
        require(hasRole(MINTER_ROLE, _msgSender()), "R1");

        require(!_exists(id), "RE");

        _mint(to, id);

        // Save token datas
        _nftDatas[id] = data;

        emit WarrantNFTMint(to, id, data);

        return id;
    }

    /**
     * @dev modify token data
     *
     * @param tokenId token id
     * @param data token data see {WarrantNFTData}
     */
    function modNftData(uint256 tokenId, WarrantNFTData memory data) external {
        require(hasRole(DATA_ROLE, _msgSender()), "R1");

        WarrantNFTData storage wdata = _nftDatas[tokenId];
        if(wdata.storehouseLv != data.storehouseLv) {
            wdata.storehouseLv = data.storehouseLv;
        }
        if(wdata.factoryLv != data.factoryLv){
            wdata.factoryLv = data.factoryLv;
        }
        if(wdata.shopLv != data.shopLv){
            wdata.shopLv = data.shopLv;
        }
        if(wdata.shipyardLv != data.shipyardLv){
            wdata.shipyardLv = data.shipyardLv;
        }

        emit WarrantNFTModified(tokenId, wdata);
    }

    /**
     * @dev get token data
     *
     * @param tokenId token id
     * @param data token data see {WarrantNFTData}
     */
    function getNftData(uint256 tokenId) external view returns(WarrantNFTData memory data){
        require(_exists(tokenId), "T1");

        data = _nftDatas[tokenId];
    }

}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Crypto.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Crypto {
    using ECDSA for bytes32;
    
    function verifySignature(bytes memory data, bytes memory signature, address account) external pure returns (bool) {
        return keccak256(data)
            .toEthSignedMessageHash()
            .recover(signature) == account;
    }
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (GasFeeCharger.sol)

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

    function chargeMethodExtraFee(MethodExtraFees storage extraFees, uint8 methodKey)  internal returns(uint256) {
        MethodWithExrtraFee storage fee = extraFees.extraFees[methodKey];
        if(fee.target == address(0)){
            return 0; // no need charge fee
        }

        require(msg.value >= fee.value, "msg fee not enough");

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, ) = fee.target.call{value: fee.value}("");
        require(sent, "Trans fee err");

        return fee.value;
    }
    
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (OracleCharger.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./TransferHelper.sol";

interface TokenPriceOracle {
    // returns 8 decimal usd price, token usd value = token count * retvalue / 100000000;
    function getERC20TokenUSDPrice(address tokenAddr) external returns(uint256);
}

library OracleCharger {

    struct ChargeTokenSet {
        uint8 decimals;
        address tokenAddr;
        uint256 maximumUSDPrice;
        uint256 minimumUSDPrice;
    }

    struct OracleChargerStruct {
        uint locked;
        address tokenPriceOracleAddr;
        address receiveIncomeAddr;
        mapping(string=>ChargeTokenSet) chargeTokens;
    }
    
    modifier lock(OracleChargerStruct storage charger) {
        require(charger.locked == 0, 'OracleCharger: LOCKED');
        charger.locked = 1;
        _;
        charger.locked = 0;
    }

    function setTPOracleAddr(OracleChargerStruct storage charger, address tpOracleAddr) internal {
        charger.tokenPriceOracleAddr = tpOracleAddr;
    }

    function setReceiveIncomeAddr(OracleChargerStruct storage charger, address incomeAddr) internal {
        charger.receiveIncomeAddr = incomeAddr;
    }

    function addChargeToken(
        OracleChargerStruct storage charger, 
        string memory tokenName, 
        address tokenAddr, 
        uint256 maximumUSDPrice, 
        uint256 minimumUSDPrice
        ) internal 
    {
        uint8 decimals = 18;
        if(tokenAddr != address(0)){
            decimals = ERC20(tokenAddr).decimals();
        }

        charger.chargeTokens[tokenName] = ChargeTokenSet({
            decimals:decimals,
            tokenAddr:tokenAddr,
            maximumUSDPrice:maximumUSDPrice,
            minimumUSDPrice:minimumUSDPrice
        });
    }

    function removeChargeToken(OracleChargerStruct storage charger, string memory tokenName) internal {
        delete charger.chargeTokens[tokenName];
    }

    function charge(OracleChargerStruct storage charger, string memory tokenName, uint256 usdValue) internal lock(charger) {
        require(charger.receiveIncomeAddr != address(0), "income addr not set");

        ChargeTokenSet storage tokenSet = charger.chargeTokens[tokenName];
        require(tokenSet.decimals > 0, "token not set");

        // get eth usd price
        uint256 tokenUSDPrice = TokenPriceOracle(charger.tokenPriceOracleAddr).getERC20TokenUSDPrice(tokenSet.tokenAddr);
        if(tokenSet.minimumUSDPrice > 0 && tokenUSDPrice < tokenSet.minimumUSDPrice) {
            tokenUSDPrice = tokenSet.minimumUSDPrice;
        }
        if(tokenSet.maximumUSDPrice > 0 && tokenUSDPrice > tokenSet.maximumUSDPrice) {
            tokenUSDPrice = tokenSet.maximumUSDPrice;
        }
        uint256 tokenCost = usdValue * 10**tokenSet.decimals / tokenUSDPrice;

        if(tokenSet.tokenAddr == address(0)){
            // charge eth
            require(msg.value >= tokenCost, "insufficient eth");
            (bool sent, ) = charger.receiveIncomeAddr.call{value: tokenCost}("");
            require(sent, "Trans fee err");
            if(msg.value > tokenCost){
                // send back
                (sent, ) = msg.sender.call{value: (msg.value - tokenCost)}("");
                require(sent, "Trans fee err");
            }
        }
        else {
            // charge erc20

            require(IERC20(tokenSet.tokenAddr).balanceOf(msg.sender) >= tokenCost, "insufficient token");

            TransferHelper.safeTransferFrom(tokenSet.tokenAddr, msg.sender, charger.receiveIncomeAddr, tokenCost);
        }
    }
    
}

// SPDX-License-Identifier: MIT
// Metaline Contracts (Random.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./RandomArb.sol";

contract Random is RandomArb {

}

// SPDX-License-Identifier: MIT
// Metaline Contracts (RandomArb.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interface/Arbitrum/ArbSys.sol";
import "../core/IRandom.sol";

/**
 * @dev A random source contract provids `seedRand`, `sealedRand` and `oracleRand` methods
 */
contract RandomArb is Context, AccessControl, IRandom {
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

        uint256 blockNum = ArbSys(address(100)).arbBlockNumber();
        require(blockNum > 256,"block is too small");
        
        uint256 sealedKey = _encodeSealedKey(tx.origin);
       
        require(!_isSealedDirect(sealedKey),"should not sealed");

        _sealedNonce++;

        RandomSeed storage rs = _sealedRandom[sealedKey];

        rs.sealedNumber = blockNum + 1;
        rs.sealedNonce = _sealedNonce;
        rs.seed = _randomSeed;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(blockNum, block.timestamp, _sealedNonce)
            )
        );
        uint32 n1 = uint32(seed % 256);
        rs.h1 = uint256(ArbSys(address(100)).arbBlockHash(blockNum - n1));
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
        uint256 blockNum = ArbSys(address(100)).arbBlockNumber();
        require(blockNum > 256,"block is too small");

        uint256 n1 = (randomNum + index) % 256;
        uint256 h1 = uint256(ArbSys(address(100)).arbBlockHash(blockNum - n1 - 1));

        return uint256(
            keccak256(
                abi.encodePacked(index, n1, h1)
            )
        );
    }

    function _seedRand(uint256 inputSeed) internal returns (uint256 ret) {
        uint256 blockNum = ArbSys(address(100)).arbBlockNumber();
        require(blockNum > 256,"block is too small");

        uint256 seed = uint256(
            keccak256(abi.encodePacked(blockNum, block.timestamp, inputSeed))
        );

        uint32 n1 = uint32(seed % 256);

        uint256 h1 = uint256(ArbSys(address(100)).arbBlockHash(blockNum - n1));

        _nonce++;
        uint256 v = uint256(
            keccak256(abi.encodePacked(_randomSeed, n1, h1, _nonce))
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

        uint256 h2 = uint256(ArbSys(address(100)).arbBlockHash(rs.sealedNumber));
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
// Metaline Contracts (Random.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../core/IRandom.sol";

/**
 * @dev A random source contract provids `seedRand`, `sealedRand` and `oracleRand` methods
 */
contract RandomEvm is Context, AccessControl, IRandom {
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
// Metaline Contracts (RandomPoolLib.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./OracleCharger.sol";

interface IUniswapV2Pair_Like {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV3Pool_Like {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function liquidity() external view returns (uint128);
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick, uint16 observationIndex, uint16 observationCardinality, uint16 observationCardinalityNext, uint8 feeProtocol, bool unlocked);
}

contract TokenPrices is 
    Context,
    AccessControl,
    TokenPriceOracle 
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint8 public constant DefiPoolType_UniswapV2 = 1;
    uint8 public constant DefiPoolType_UniswapV3 = 2;
    
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    struct DefiPoolConf {
        uint8 poolType;
        uint8 tokenIndex;
        address poolAddr;
    }

    mapping(address=>AggregatorV3Interface) public _chainLinkFeeds;
    mapping(address=>DefiPoolConf) public _defiPools;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MANAGER_ROLE, _msgSender());
    }

    /**
     * (ETH)Arbitrum Goerli Testnet : 0x62CAe0FA2da220f43a51F86Db2EDb36DcA9A5A08
     * (ETH)Arbitrum One : 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612
     */
    function setChainLinkTokenPriceSource(address tokenAddr, address feedAddr) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MTTMinePool: must have manager role");

        _chainLinkFeeds[tokenAddr] = AggregatorV3Interface(feedAddr);
    }
    
    function setDefiPoolSource(address tokenAddr, DefiPoolConf memory defiPoolSource) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "MTTMinePool: must have manager role");

        _defiPools[tokenAddr] = defiPoolSource;
    }

    /**
     * Returns the latest price.
     */
    function getERC20TokenUSDPrice(address tokenAddr) public override view returns (uint256) {

        if(address(_chainLinkFeeds[tokenAddr]) != address(0)){

            // prettier-ignore
            (
                /* uint80 roundID */,
                int price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = _chainLinkFeeds[tokenAddr].latestRoundData();
            require(price > 0, "price error");

            return uint256(price);
        }

        DefiPoolConf storage defiPool = _defiPools[tokenAddr];
        if(defiPool.poolType != 0){

            // get price from defi pool
            if(defiPool.poolType == DefiPoolType_UniswapV2) {
                if(defiPool.tokenIndex == 0){
                    return _univ2_getTokenPrice_0(defiPool.poolAddr, 1*(10**ERC20(tokenAddr).decimals()));
                }
                else {
                    return _univ2_getTokenPrice_1(defiPool.poolAddr, 1*(10**ERC20(tokenAddr).decimals()));
                }
            }
            else if(defiPool.poolType == DefiPoolType_UniswapV3){
                if(defiPool.tokenIndex == 0){
                    return _univ3_getTokenPrice_0(defiPool.poolAddr, 1*(10**ERC20(tokenAddr).decimals()));
                }
                else {
                    return _univ3_getTokenPrice_1(defiPool.poolAddr, 1*(10**ERC20(tokenAddr).decimals()));
                }
            }
            else {
                revert("defiPool.poolType not exist"); 
            }

            // // for Debug ...
            // return 9000000; // 0.09 u
        }

        revert("token price source not set");
    }

    function _sync_usdprice_decimals8(uint256 price, uint8 decimals) internal pure returns(uint256 ret) {

        if(decimals < 8){
            ret = price * (10**(8 - decimals));
        }
        else if(decimals > 8){
            ret = price / (10**(decimals - 8));
        }
        else {
            ret = price;
        }

        return ret;
    }

    // uniswap v2 get token price ---------------------------------------------
    // calculate price based on pair reserves
    function _univ2_getTokenPrice_0(address pairAddress, uint256 amount) internal view returns(uint256)
    {
        IUniswapV2Pair_Like pair = IUniswapV2Pair_Like(pairAddress);
        //ERC20 token1 = ERC20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        //uint res0 = Res0*(10**token1.decimals());
        uint256 ret = ((amount*Res0)/Res1); // return amount of token0 needed to buy token1

        return _sync_usdprice_decimals8(ret, ERC20(pair.token0()).decimals());
    }
    function _univ2_getTokenPrice_1(address pairAddress, uint amount) internal view returns(uint256)
    {
        IUniswapV2Pair_Like pair = IUniswapV2Pair_Like(pairAddress);
        //ERC20 token0 = ERC20(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();

        // decimals
        //uint res1 = Res1*(10**token0.decimals());
        uint256 ret = ((amount*Res1)/Res0); // return amount of token1 needed to buy token0
        
        return _sync_usdprice_decimals8(ret, ERC20(pair.token1()).decimals());
    }

    // uniswap v2 get token price ---------------------------------------------
    // calculate price based on pair reserves
    function _univ3_getTokenPrice_0(address pairAddress, uint amount) public view returns (uint256) {
        IUniswapV3Pool_Like pool = IUniswapV3Pool_Like(pairAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 Res0 = pool.liquidity() * Q96 / sqrtPriceX96;
        uint256 Res1 = pool.liquidity() * sqrtPriceX96 / Q96;

        uint256 ret = (amount*Res0) / Res1;
        
        return _sync_usdprice_decimals8(ret, ERC20(pool.token0()).decimals());
    }
    function _univ3_getTokenPrice_1(address pairAddress, uint amount) public view returns (uint256) {
        IUniswapV3Pool_Like pool = IUniswapV3Pool_Like(pairAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 Res0 = pool.liquidity() * Q96 / sqrtPriceX96;
        uint256 Res1 = pool.liquidity() * sqrtPriceX96 / Q96;

        uint256 ret = (amount*Res1) / Res0;
        
        return _sync_usdprice_decimals8(ret, ERC20(pool.token1()).decimals());
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