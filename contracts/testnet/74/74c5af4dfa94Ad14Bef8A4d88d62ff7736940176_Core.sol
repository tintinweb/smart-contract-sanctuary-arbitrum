// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
        _checkRole(role);
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
                        StringsUpgradeable.toHexString(account),
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
     * Emits a {TransferBatch} event.
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
     * Emits a {TransferSingle} event.
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
     * Emits a {TransferBatch} event.
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
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library CountersUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IACL} from "../interfaces/acl/IAcl.sol";

contract ACL is IACL, AccessControlUpgradeable {
  bytes32 public constant ACL_ADMIN = keccak256("ACL_ADMIN"); //Used to gate control to ACL contract

  string[] public allRoles; //All Roles that have been created
  mapping(string => bytes32) public rolesByName; // Map roles bytes32 representation by string name
  mapping(address => string[]) public rolesByAddress; // Map all roles an address holds
  mapping(string => address[]) public roleHolders; // Map role holders addresses by role name

  ///@dev checks to ensure that a role exists. Used before assigning the role to a person
  modifier roleExists(string memory role_) {
    require(_doesRoleExist(role_), "ACL: Role does not exist");
    _;
  }

  /**
   * @notice initialize function is used to set up the contract during deployment
   * @param admin_ is the input address of the admin for this contract
   */
  function initialize(address admin_) public initializer {
    __AccessControl_init();
    rolesByName["ACL_ADMIN"] = ACL_ADMIN;
    rolesByAddress[admin_].push("ACL_ADMIN");
    roleHolders["ACL_ADMIN"].push(admin_);
    allRoles.push("ACL_ADMIN");
    _grantRole(ACL_ADMIN, admin_);
  }

  /**
   * @notice Creates a role with all pertinent mappings
   * @param name_ The string representatation of the role
   * @param recipient_ The initial recipient of the role being created
   * @dev MUST pass in a recipient in order to utilize the OZ contract
   */
  function createRole(string memory name_, address recipient_) public onlyRole(ACL_ADMIN) {
    require(!_doesRoleExist(name_), "ACL: Role already exists");
    bytes32 role = keccak256(abi.encodePacked(name_));
    rolesByName[name_] = role;
    rolesByAddress[recipient_].push(name_);
    roleHolders[name_].push(recipient_);
    allRoles.push(name_);
    _grantRole(role, recipient_);
  }

  /**
   * @notice assigns pre-existing role to an individual
   * @param role_ The string representation of the role
   * @param recipient_ The person to receive the role
   */
  function assignRole(string memory role_, address recipient_) public roleExists(role_) onlyRole(ACL_ADMIN) {
    require(!hasRole(rolesByName[role_], recipient_), "ACL: User already holds role");
    rolesByAddress[recipient_].push(role_);
    roleHolders[role_].push(recipient_);
    _grantRole(rolesByName[role_], recipient_);
  }

  /**
   * @notice used to revoke a role from a user
   * @param role_ The string representation of the role being revoked
   * @param user_ The address of the user having role revoked
   */
  function revokeUserRole(string memory role_, address user_) public roleExists(role_) onlyRole(ACL_ADMIN) {
    require(hasRole(rolesByName[role_], user_), "ACL: User does not hold role");
    _revokeRole(rolesByName[role_], user_);
    address[] storage _holders = roleHolders[role_];
    string[] storage _userRoles = rolesByAddress[user_];
    for (uint256 i = 0; i < _holders.length; i++) {
      if (_holders[i] == user_) {
        _holders[i] = _holders[_holders.length - 1];
        _holders.pop();
      }
    }
    for (uint256 i = 0; i < _userRoles.length; i++) {
      /**
       * First check length of bytes representation, as it is more gas efficient. If they are the same length
       * then compare the values
       */
      if (bytes(_userRoles[i]).length == bytes(role_).length) {
        if (keccak256(abi.encodePacked(_userRoles[i])) == keccak256(abi.encodePacked(role_))) {
          _userRoles[i] = _userRoles[_userRoles.length - 1];
          _userRoles.pop();
        }
      }
    }
  }

  /**
   * @notice getAllRoleHolders is used to retrieve an array of all addresses who hold an input role
   * @param role_ is the string of the role in question
   * @return All role holders for a given role
   */
  function getAllRoleHolders(string memory role_) public view returns (address[] memory) {
    return roleHolders[role_];
  }

  /**
   * @notice getAllRoles is used to retrieve all of the availible roles
   * @return All roles that currently exist
   */
  function getAllRoles() public view returns (string[] memory) {
    return allRoles;
  }

  /**
   * @notice getAllRolesHeldByAddress is used to retrieve all of the roles assigned to an address
   * @param user_ is the address of the user in question
   * @return is an array of strings containing all of the roles that the input account has
   */
  function getAllRolesHeldByAddress(address user_) public view returns (string[] memory) {
    return rolesByAddress[user_];
  }

  /**
   * @notice _doesRoleExist is an internal function used to determine if an input role exists
   * @param role_ is the role in question
   * @return is a bool where true means that a role does exist while false means that it doesnt
   */
  function _doesRoleExist(string memory role_) internal view returns (bool) {
    if (rolesByName[role_] != 0x0) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice the follwoing three functions are override functions designed to revert unused Access Control functions that are not implemented in this design
   */

  function getRoleAdmin(bytes32) public pure override returns (bytes32) {
    revert("Not Implemented");
  }

  function revokeRole(bytes32, address) public pure override {
    revert("Not Implemented");
  }

  function renounceRole(bytes32, address) public pure override {
    revert("Not Implemented");
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ACL} from "../acl/Acl.sol";

contract ACLUser {
  /**
   * @notice BORROWER is assigned to the addresses of the borrowers or policy creators
   */
  bytes32 constant BORROWER = keccak256("BORROWER");

  /**
   * @notice MANAGER is assigned to the addresses of the protocol managers
   */
  bytes32 constant MANAGER = keccak256("MANAGER");

  /**
   * @notice Core is assigned to the address of the core contract
   */
  bytes32 constant CORE = keccak256("CORE");

  /**
   * @notice VAULTS_SALE is assigned to the address of the vault sale contract
   */
  bytes32 constant VAULTS_SALE = keccak256("VAULT_SALE");

  /**
   * @notice LOAN_BROKER is assigned to the address of the vault sale contract
   */
  bytes32 constant LOAN_BROKER = keccak256("LOAN_BROKER");

  /**
   * @notice AUTHORIZED is assigned to the address of the admin who can control emergency situations
   */
  bytes32 constant AUTHORIZED = keccak256("AUTHORIZED");

  /**
   * @notice  The Access Control List contract
   */
  ACL public aclContract;

  ///@dev Utilizes the ACL contract to limit access to particular functions
  modifier onlyBorrower() {
    require(aclContract.hasRole(BORROWER, msg.sender), "ACL: Caller Does Not Have Borrower Role");
    _;
  }

  ///@dev Utilizes the ACL contract to limit access to particular functions
  modifier onlyManager() {
    require(aclContract.hasRole(MANAGER, msg.sender), "ACL: Caller Does Not Have Manager Role");
    _;
  }

  ///@dev Ensures only the core contract can call a function
  modifier onlyCore() {
    require(aclContract.hasRole(CORE, msg.sender), "ACL: Not Core Contract");
    _;
  }

  ///@dev checks to ensure that a role exists. Used before assigning the role to a person
  modifier isCoreOrManager() {
    require(aclContract.hasRole(CORE, msg.sender) || aclContract.hasRole(MANAGER, msg.sender), "ACL: Is Not Core or Manager");
    _;
  }

  ///@dev checks to ensure that a role exists. Used before assigning the role to a person
  modifier isBaseLoanOrManager() {
    require(aclContract.hasRole(LOAN_BROKER, msg.sender) || aclContract.hasRole(MANAGER, msg.sender), "ACL: Is Not Manager Or Base Loan Broker");
    _;
  }

  ///@dev checks to ensure that a role exists. Used before assigning the role to a person
  modifier isCoreOrManagerOrBaseLoan() {
    require(aclContract.hasRole(CORE, msg.sender) || aclContract.hasRole(MANAGER, msg.sender) || aclContract.hasRole(LOAN_BROKER, msg.sender), "ACL: Is Not Core, Manager or Base Loan Broker");
    _;
  }

  ///@dev modifier to ensure a function can only be called by the vault sale contract
  modifier onlyVaultSaleContract() {
    require(aclContract.hasRole(VAULTS_SALE, msg.sender), "ACLs: Caller not vault sale contract");
    _;
  }

  ///@dev modifier to ensure a function can only be called by an authorized admin
  modifier onlyAuthorized() {
    require(aclContract.hasRole(AUTHORIZED, msg.sender), "Not Authorized");
    _;
  }

  modifier onlyVaultSaleOrManager(address _position) {
    require(
      aclContract.hasRole(VAULTS_SALE, msg.sender) || aclContract.hasRole(MANAGER, msg.sender) || aclContract.hasRole(LOAN_BROKER, msg.sender) || msg.sender == _position,
      "ACL: Is not Vault Sale or Manager"
    );
    _;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {IPortfolio} from "../interfaces/portfolio/IPortfolio.sol";
import {IBrokerage} from "../interfaces/brokerage/IBrokerage.sol";
import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {ClaimUpdater} from "../libraries/ClaimUpdater.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {ValidationLogic} from "../libraries/ValidationLogic.sol";

contract Brokerage is IBrokerage, ACLUser, ERC721Upgradeable, EmergencyModifier {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  ///@notice Counters used for loan id, claim Id and policy Id
  CountersUpgradeable.Counter private _currentLoanId;
  CountersUpgradeable.Counter private _currentPolicyId;
  CountersUpgradeable.Counter private _currentClaimId;

  ///@notice Array of all active policies
  Policy[] public activePolicies;

  ///@notice an array of all concrete managed loans
  uint256[] public concreteManagedLoans;

  ///@notice the address of the portfolio contract
  address portfolioAddress;

  ///@notice Array of a given loan tokens historical states
  mapping(uint256 => LoanInfo[]) history;

  ///@notice owners by loan ID
  mapping(uint256 => address) loanOwners;
  ///@notice Full loan info by a given loan ID
  mapping(uint256 => LoanInfo) tokenIdToLoanData;
  ///@notice Mapping of all policies held by user
  mapping(address => uint256[]) userToPolicyTokenIDs;
  ///@notice Mapping of all loans held by a user
  mapping(address => uint256[]) userToLoanTokenIDs;
  ///@notice Mapping of all loans held or managed by concrete (to be used after checkLoanHealth)
  mapping(uint256 => LoanInfo) loansManagedByConcrete;
  ///@notice maps a loan ID to a lender
  mapping(uint256 => string) loanToLender;

  modifier validateInternal(uint256 _amount, uint256 _tokenId) {
    require(_amount != 0, "ERR: Please provide valid amount");
    require(_tokenId != 0, "ERR: Invalid loan id");
    _;
  }

  /**
   * @notice the initialize function is used during the deployment and setup of this contract
   * @param _portfolio is the address of the portfolio contract
   * @param _baseUrl is a string representing the base URL for all Loan Tokens
   * @param _aclAddress is the address of the Access Control contract
   */
  function initialize(address _portfolio, string memory _baseUrl, address _aclAddress, address _emsAddress) external initializer {
    __ERC721_init("Concrete Loan Token", "CLT");
    aclContract = ACL(_aclAddress);
    emsContract = EmergencyStop(_emsAddress);
    portfolioAddress = _portfolio;
  }

  /**
   * @notice Creates and initializes a loan token for a given portfolio
   * @param _portfolioId The id of the portfolio being minted to
   * @param _loanData All the data needed to initialize the portfolio (See LoanInfo Struct)
   * @dev Only callable by policy admin address.
   */
  function mint(uint256 _portfolioId, bytes memory _loanData) external onlyManager emergencyStop returns (uint256) {
    require(_loanData.length > 0, "Brokerage cannot be blank");
    (address _loanHolder, uint256 _startDate, uint256 _LTV1, uint256 _LTV2, uint256 _LTV3, uint256 _lenderLTV, uint256 _suppliedAmount, address _collateralAddress, string memory _lender) = abi.decode(
      _loanData,
      (address, uint256, uint256, uint256, uint256, uint256, uint256, address, string)
    );
    _currentLoanId.increment();
    uint256 currentLoanId = _currentLoanId.current();
    LoanInfo storage loan = tokenIdToLoanData[currentLoanId];
    loan.loanHolder = _loanHolder;
    loan.portfolioId = _portfolioId;
    loan.loanId = currentLoanId;
    loan.startDate = _startDate;
    loan.LTV1 = _LTV1;
    loan.LTV2 = _LTV2;
    loan.LTV3 = _LTV3;
    loan.lenderLTV = _lenderLTV;
    loan.loanAmount = 0;
    loan.collateralBalance = _suppliedAmount;
    loan.collateralAddress = _collateralAddress;
    loan.loanStatus = LoanStatus.UNCOVERED;
    loanToLender[currentLoanId] = _lender;

    tokenIdToLoanData[currentLoanId] = loan;
    history[currentLoanId].push(loan);
    bytes memory data = abi.encode(_portfolioId, address(this), "Concrete Loan Token", "CLT", currentLoanId, true);

    _safeMint(portfolioAddress, currentLoanId, data);
    userToLoanTokenIDs[_loanHolder].push(currentLoanId);
    loanOwners[currentLoanId] = _loanHolder;
    emit LoanTokenCreated(currentLoanId, _startDate, _LTV1, _LTV2, _LTV3, _lenderLTV, LoanStatus.UNCOVERED, _collateralAddress);

    return currentLoanId;
  }

  /**
   * @notice Adds a policy to a given loan
   * @param _loanId The id number of the loan being updated
   * @param _policyData A bytes encoded Policy Struct
   * @dev Only callable by policy admin
   * @dev amounts need to be passed in as BN
   * @dev interest rate needs to be basis points
   */
  function addPolicyToLoan(uint256 _loanId, bytes memory _policyData) external onlyManager emergencyStop {
    (, uint256 _cancellationFee, uint256 _openingFee, uint256 _startDate, uint256 _endDate, uint256 _totalCreditOffered, uint256 _interestRate, uint256 _premium) = abi.decode(
      _policyData,
      (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    );
    _currentPolicyId.increment();
    uint256 currentPolicyId = _currentPolicyId.current();

    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan.loanStatus = LoanStatus.COVERED;
    Policy storage policy = loan.policyData;
    policy.policyId = currentPolicyId;
    policy.active = true;
    policy.cancellationFee = _cancellationFee;
    policy.premium = _premium;
    policy.policyStatus = PolicyStatus.OPEN;
    policy.policyUpdates.push(
      PolicyUpdate({openingFee: _openingFee, startDate: _startDate, endDate: _endDate, totalCreditOffered: _totalCreditOffered, availableCredit: _totalCreditOffered, interestRate: _interestRate})
    );
    loan.policyData = policy;
    activePolicies.push(policy);

    tokenIdToLoanData[_loanId] = loan;
    address holder = loan.loanHolder;
    userToPolicyTokenIDs[loan.loanHolder].push(currentPolicyId);
    history[_loanId].push(loan);
    emit PolicyCreated(
      _loanId,
      currentPolicyId,
      holder,
      true,
      _cancellationFee,
      _premium,
      PolicyStatus.OPEN,
      _openingFee,
      _startDate,
      _endDate,
      _totalCreditOffered,
      _totalCreditOffered,
      _interestRate
    );
  }



  /**
   * @notice Removes a policy from a given loan
   * @param _loanId The id of the loan being updated
   * @dev Only callable by policy admin
   */
  function removePolicyFromLoan(uint256 _loanId) public onlyManager emergencyStop {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan.loanStatus = LoanStatus.UNCOVERED;
    delete loan.policyData;
    history[_loanId].push(loan);
    emit RemovePolicyFromLoan(_loanId, LoanStatus.UNCOVERED);
  }

  /**
   * @notice updates a given loan to reflect that the loan is successfuly closed
   * @param _loanId The id of the loan being updated
   * @dev Only callable by policy admin
   */
  function successfullyCloseLoan(uint256 _loanId) external emergencyStop {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan.loanStatus = LoanStatus.SUCCESSFULLY_CLOSED;
    loan.currentLoanBalance = 0;
    Policy storage policyData = loan.policyData;
    uint256 policyId = loan.policyData.policyId;
    policyData.active = false;
    if (policyData.policyUpdates.length > 0) {
      policyData.policyUpdates[policyData.policyUpdates.length - 1].availableCredit = 0;
    }
    history[_loanId].push(loan);
    emit LoanClosed(_loanId, LoanStatus.SUCCESSFULLY_CLOSED, policyId);
  }

  /**
   * @notice a function that allows the core contract to create a claim
   * @param _loanId The id of the loan the claim is being made on
   * @param _claimData The struct of the claim being initiated
   * @dev only callable by core contract
   */
  function initiateClaim(uint256 _loanId, bytes memory _claimData) external onlyCore emergencyStop {
    require(_claimData.length > 0, "Brokerage cannot be blank");
    _currentClaimId.increment();
    uint256 currentClaimId = _currentClaimId.current();
    address _claimToken;
    uint256 _claimDate;
    uint256 _claimAmount;
    (_claimToken, _claimDate, _claimAmount) = abi.decode(_claimData, (address, uint256, uint256));
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    Policy storage policy = loan.policyData;
    policy.policyStatus = PolicyStatus.LTV2;
    loan.loanStatus = LoanStatus.CLAIM_INITIATED;
    policy.claims.push(
      Claim({
        claimToken: _claimToken,
        claimDate: block.timestamp,
        claimAmount: _claimAmount,
        claimId: currentClaimId,
        claimAPY: policy.policyUpdates[policy.policyUpdates.length - 1].interestRate,
        claimBalance: _claimAmount,
        claimRepaid: false
      })
    );
    uint256 APY = policy.policyUpdates[policy.policyUpdates.length - 1].interestRate;
    loan.policyData = policy;
    history[_loanId].push(loan);
    emit ClaimInitiated(_loanId, _claimToken, block.timestamp, _claimAmount, currentClaimId, APY, _claimAmount, false);
  }

  /**
   * @notice a function to allow the policy LTV status to be updated manually
   * @param _loanId The id of the loan being updated
   * @param _policyStatus the enum value of the policy status (see PolicyStatus in IBrokerage)
   */
  function updateLTVStatus(uint256 _loanId, PolicyStatus _policyStatus) external onlyCore emergencyStop {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan.policyData.policyStatus = _policyStatus;
    tokenIdToLoanData[_loanId] = loan;
    emit UpdateLTV(_loanId, _policyStatus);
  }

  /**
   * @notice allows a claim to be updated. Used when a portion of the claim loan is paid, or balance increases
   * @param _loanId The id of the loan with the claim that is to be updated
   * @param _amountPaid The new balance for the claim loan
   * @dev if the updated balance is 0 it changes claim to repaid status, otherwise updates the balance
   * @dev only callable by policy admin
   */
  function updateClaim(uint256 _loanId, uint256 _amountPaid) external onlyCore emergencyStop {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan = ClaimUpdater.updateClaim(loan, _amountPaid);
    tokenIdToLoanData[_loanId] = loan;
    history[_loanId].push(loan);
    Claim storage claim = loan.policyData.claims[loan.policyData.claims.length - 1];
    uint256 claimID = claim.claimId;
    emit ClaimUpdated(_loanId, _amountPaid, claimID);
  }

  /**
   * @notice allows a policy owner to cancel their loan
   * @param _loanId The id of the loan having the policy cancelled
   * @dev only callable by policy owner
   */
  function cancelPolicy(uint256 _loanId) external {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    _deletePolicyFromActivePolicies(loan.policyData.policyId);
    history[_loanId].push(loan);
    delete loan.policyData;
  }

  /**
   * @notice A function that allows a loan to be transferred to concrete (after LTV3 breach)
   * @param _loanId The id of the loan being transferred
   * @dev Access Controlled
   */
  function transferLoanToConcrete(uint256 _loanId, address _concreteTreasury, uint256 _vaultId) external onlyCore emergencyStop {
    LoanInfo storage loan = tokenIdToLoanData[_loanId];
    loan.policyData.policyStatus = PolicyStatus.LTV3;
    loan.loanStatus = LoanStatus.CONCRETE_MANAGED;
    loan.vaultId = _vaultId;
    loan.loanHolder = _concreteTreasury;
    _removeLoanFromUser(userToLoanTokenIDs[loan.loanHolder], loan.loanId, loan.loanHolder);
    userToLoanTokenIDs[_concreteTreasury].push(loan.loanId);
    loanOwners[loan.loanId] = _concreteTreasury;
    concreteManagedLoans.push(_loanId);
    _transfer(portfolioAddress, _concreteTreasury, loan.loanId);
  }

  /**
   * @notice updateLoanInfo is used to update an existing loans information
   * @param _loanId is the ID of the loan that is being updated
   * @param loanInfo is an input LoanInfo struct that contains the updated data for the loan
   */
  function updateLoanInfo(uint256 _loanId, LoanInfo calldata loanInfo) external emergencyStop {
    tokenIdToLoanData[_loanId] = loanInfo;
    emit LoanUpdated(_loanId, loanInfo);
  }

  /**
   * @notice Function that updates the borrow amount on a loan
   * @param _tokenId The loan id in which is being added to
   * @param _amount amount to add to loan
   */
  function addBorrowToLoan(uint256 _tokenId, uint256 _amount) external emergencyStop validateInternal(_amount, _tokenId) {
    LoanInfo storage loan = tokenIdToLoanData[_tokenId];
    loan.currentLoanBalance = _amount;
    tokenIdToLoanData[_tokenId] = loan;
    address debtToken = loan.debtTokenAddress;
    address owner = loan.loanHolder;
    emit AmountAddedToLoan(_tokenId, _amount, debtToken, owner);
  }

  //GETTERS

  /**
   * @notice Returns a LoanInfo Struct for a passed in loan ID
   * @param _loanId is the input loan id for the loan in question
   * @return is a LoanInfo struct
   */
  function getLoanInfoById(uint256 _loanId) external view returns (LoanInfo memory) {
    return tokenIdToLoanData[_loanId];
  }

  /**
   * @notice Returns a Policy Struct for a given loan ID
   * @param _loanId is the input loan id for the loan in question
   * @return is a Policy struct containing the policy information for the loan in question
   */
  function getPolicyInfoById(uint256 _loanId) external view returns (Policy memory) {
    return tokenIdToLoanData[_loanId].policyData;
  }

  /**
   * @notice Returns an array showing a loan's entire loan history
   * @param _loanId is the input loan id for the loan in question
   * @return is an array of LoanInfo structs representing the entire history of the loan in question
   */
  function getHistory(uint256 _loanId) external view returns (LoanInfo[] memory) {
    return history[_loanId];
  }

  /**
   * @notice Returns an array of all loans under concrete management
   * @return is an array containing the loan IDs of all concrete controlled loans
   */
  function getAllConcreteManagedLoans() external view returns (uint256[] memory) {
    return concreteManagedLoans;
  }

  //Internal Helper Functions
  /**
   * @notice function to find the index of a given value in an array
   * @param _value The value being checked against
   * @return The index of the value in the array
   */
  function _find(uint256 _value) internal view returns (uint256) {
    uint256 i = 0;
    while (activePolicies[i].policyId != _value) {
      i++;
    }
    return i;
  }

  /**
   * @notice Helper function to delete item from array and reduce the length of the array
   * @param _policyId The id of the policy being removed
   */
  function _deletePolicyFromActivePolicies(uint256 _policyId) internal {
    uint256 j = _find(_policyId);
    for (uint256 i = j; i < activePolicies.length; i++) {
      if (activePolicies.length > 1) {
        activePolicies[i] = activePolicies[i + 1];
      }
    }
    activePolicies.pop();
  }

  /**
   * @notice Helper function to remove loan from user array and reduce array length
   * @param _userLoans The array of all loans a user owns
   * @param _loanId The id of the loan being removed
   * @param _loanOwner The address of the loan owner
   */
  function _removeLoanFromUser(uint256[] storage _userLoans, uint256 _loanId, address _loanOwner) internal {
    for (uint256 i = 0; i < _userLoans.length; i++) {
      if (_userLoans[i] == _loanId && _userLoans.length > 1) {
        _userLoans[i] = _userLoans[i + 1];
      }
      _userLoans.pop();
      userToLoanTokenIDs[_loanOwner] = _userLoans;
    }
  }

  /**
   * @notice internal function to check if the caller is the policy holder
   * @param _loanId The loan id being checked
   * @dev used in modifier onlyPolicyHolder()
   */
  function _isLoanHolder(uint256 _loanId) internal view {
    LoanInfo memory loan = tokenIdToLoanData[_loanId];
    require(loan.loanHolder == msg.sender, "Loan: Not loan owner");
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ACL} from "../acl/Acl.sol";
import {RewardToken} from "../rewardTokens/RewardToken.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {ICore} from "../interfaces/core/ICore.sol";
import {IDex} from "../interfaces/dex/IDex.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IPortfolio} from "../interfaces/portfolio/IPortfolio.sol";
import {Factory} from "../factory/Factory.sol";
import {VaultSale} from "../vaultSale/VaultSale.sol";
import {IBrokerage} from "../interfaces/brokerage/IBrokerage.sol";
import {ILoanBroker} from "../interfaces/loanBroker/ILoanBroker.sol";
import {IVaultSale} from "../interfaces/vaultSale/IVaultSale.sol";
import {IPositionToken} from "../interfaces/positionToken/IPositionToken.sol";
import {BaseLoanBroker} from "../loanBroker/BaseLoanBroker.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH10} from "../interfaces/wETH/IWETH10.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {ValidationLogic} from "../libraries/ValidationLogic.sol";

/**
 * @title Core
 * @author Man-Jain
 * @notice The core contract is responsible for handling all the interactions between different components of the protocol.
 */

contract Core is ICore, ACLUser, Initializable, ReentrancyGuard, EmergencyModifier {
  /**
   * @notice mapping that tracks a number to lender to borrower
   */
  mapping(address => mapping(string => address)) public borrowerToLenderDeployed;

  /**
   * @notice  All the registered automation provider addresses with their name
   */
  mapping(string => address) public registeredAutomationProviderAddresses;

  /**
   * @notice  All the registered dexes addresses with their name
   */
  mapping(string => address) public registeredDexAddresses;

  /**
   *@notice portfolio token id's by sc wallet address
   */
  mapping(address => uint256) public portfolioIdsByAddress;

  ///@notice mapping that tracks all approved collateral types by lender name
  mapping(string => mapping(address => bool)) private _allowedCollateralType;

  ///@notice mapping that tracks approved lenders by name
  mapping(string => bool) public registeredLenders;

  ///@notice mapping that tracks lender markets by name
  mapping(string => address) public registeredLenderMarkets;

  /**
   * @notice  Address of the Vault manager contract
   */
  address public vaultManager;

  /**
   * @notice  Company Treasury Address
   */
  address public companyTreasury;

  /**
   * @notice  emsContract Address
   */
  address public emsContractAddress;

  /**
   * @notice address for wrapped ETH address OR relevant underlying blockchain equivalent
   */
  IWETH10 public wETHadd;

  /**
   * @notice  The default deadline for swap transactions
   */
  uint256 public swapDeadline;

  /**
   * @notice  The Proxy Factory Contract
   */
  Factory public proxyFactory;

  /**
   * @notice  The Base Loan Broker
   */
  BaseLoanBroker public baseLoanBroker;

  /**
   * @notice  The Portfolio Contract
   */
  IPortfolio public portfolio;

  /**
   * @notice  The Brokerage Contract
   */
  IBrokerage public brokerage;
  address public brokerageV;

  /**
   * @notice  The Vault Sale Contract
   */
  IVaultSale vaultSale;

  /**
   * @notice the initialized function is used during the deployment and setup of the contract
   * @param _vaultManager is the address of the vault manager contract
   * @param _companyTreasury is the address of the companyTreasury contract
   * @param _aclContract is the address of the Access Control contract
   * @param _portfolio is the address of the portfolio contract
   * @param _brokerage is the address of the brokerage contract
   * @param _proxyFactory is the address of the proxy factory contract
   * @param _wETHadd is the address of the network's wETH(or equivalent) contract
   * @param _baseLoanBroker is the address of the BaseLoanBroker contract
   * @param _vaultSale is the address of the Vault Sale contract
   * @param _deadline is a number representing the deadline time in seconds for DEX trades
   */
  function initialize(
    address _vaultManager,
    address _companyTreasury,
    address _aclContract,
    address _portfolio,
    address _brokerage,
    address _proxyFactory,
    address _wETHadd,
    address payable _baseLoanBroker,
    address _vaultSale,
    uint _deadline,
    address _emsAddress
  ) public initializer {
    aclContract = ACL(_aclContract);
    vaultManager = _vaultManager;
    companyTreasury = _companyTreasury;
    portfolio = IPortfolio(_portfolio);
    brokerage = IBrokerage(_brokerage);
    brokerageV = _brokerage;
    vaultSale = IVaultSale(_vaultSale);
    proxyFactory = Factory(_proxyFactory);
    emsContract = EmergencyStop(_emsAddress);
    emsContractAddress = _emsAddress;
    wETHadd = IWETH10(_wETHadd);
    swapDeadline = _deadline;
    baseLoanBroker = BaseLoanBroker(_baseLoanBroker);
  }

  /**
   * @notice Allows manager to create a new vault sale with retail vault contract
   * @param _liquidityCap The max amount of liquidity to be provided into vault
   * @param _maxYield The highest amount of yield offered to protectors
   * @param _minYield The lowest amount of yield offered to protectors
   * @param _riskFactor The calculated risk factor of the vault
   * @param _maturationTime How long until the position can be redeemed
   * @param _liquidityAsset The asset to be deposited
   */
  function createNewVaultSale(
    uint256 _liquidityCap,
    uint256 _maxYield,
    uint256 _minYield,
    uint24 _riskFactor,
    uint256 _maturationTime,
    address _liquidityAsset
  ) external onlyManager emergencyStop returns (uint256) {
    return vaultSale.createVaultSale(_liquidityCap, _maxYield, _minYield, _riskFactor, _maturationTime, _liquidityAsset);
  }

  /**
   * @notice function that allows user to withdraw protector funds
   * @param _params See IPositiontoken.CollectParams for info
   */
  function withdrawProtectorFunds(IPositionToken.CollectParams calldata _params) external emergencyStop {
    vaultSale.withdrawPositionFromVault(_params);
  }

  /**
   * @notice supply is called to give collateral to a lender.
   * @param _txData is encoded bytes containing loan platform specific params
   */
  function supply(string memory _lender, bytes calldata _txData, bytes calldata _loanData) external payable emergencyStop nonReentrant {
    ValidationLogic.validateSupply(_txData, _lender);
    ValidationLogic.validateLoanData(_loanData);
    ILoanBroker.SupplyData memory decodeData = abi.decode(_txData, (ILoanBroker.SupplyData));
    require(registeredLenders[_lender], "ERR: Lender not approved");
    require(_allowedCollateralType[_lender][decodeData.token], "ERR: Not an approved collateral type");
    if (msg.value != 0) {
      wETHadd.deposit{value: msg.value}();
      require(msg.value == decodeData.amount, "Supplied ETH amount does not match input encoded amount data");
      require(address(wETHadd) == decodeData.token, "Input token address does not match Wrapped ETH address");
    }
    if (portfolioIdsByAddress[decodeData.onBehalf] == 0) {
      createPortfolio(decodeData.onBehalf);
    }
    if (borrowerToLenderDeployed[decodeData.onBehalf][_lender] == address(0x0)) {
      bytes4 initializeSig = bytes4(keccak256("initialize(address,address,address,address)"));
      bytes memory data = abi.encodeWithSelector(initializeSig, address(aclContract), address(this), address(baseLoanBroker), address(emsContractAddress));
      BeaconProxy lenderProxy = proxyFactory.createProxy(data, _lender);
      borrowerToLenderDeployed[decodeData.onBehalf][_lender] = address(lenderProxy);

      emit LenderCreated(_lender, address(lenderProxy));
    }

    ILoanBroker lender = ILoanBroker(borrowerToLenderDeployed[decodeData.onBehalf][_lender]);

    IERC20 token = IERC20(decodeData.token);

    require(token.transferFrom(msg.sender, address(this), decodeData.amount), "ERR: Token transfer failed");
    token.approve(address(lender), decodeData.amount);

    lender.supplyCollateral(_txData, _loanData);
    uint256 portfolioId = getPortfolioId(decodeData.onBehalf);
    emit CollateralSupplied(
      decodeData.amount,
      decodeData.market,
      decodeData.onBehalf,
      decodeData.covered,
      decodeData.openingFeeAsset,
      decodeData.openingFeeAmount,
      decodeData.token,
      _lender,
      portfolioId
    );
  }

  /**
   * @notice borrow is called by user to borrow a debt token.
   * @param _policyData is encoded bytes containing a policy data struct
   * @param _txData is encoded bytes containing loan platform specific params
   */
  function borrow(string memory _lender, bytes calldata _policyData, bytes calldata _txData) external isCoreOrManager emergencyStop {
    ValidationLogic.validateBorrow(_txData, _lender);
    ValidationLogic.validatePolicyData(_policyData);
    ILoanBroker.BorrowData memory decodeData = abi.decode(_txData, (ILoanBroker.BorrowData));

    ILoanBroker lender = ILoanBroker(borrowerToLenderDeployed[decodeData.to][_lender]);
    require(address(lender) != address(0x0), "Lender contract does not exist");
    if (decodeData.openingFeeAsset != address(0x0) && decodeData.covered) {
      IERC20 openingFeeAsset = IERC20(decodeData.openingFeeAsset);
      //Able to disable since function is restricted to manager (only callable by protocol)
      //slither-disable-next-line arbitrary-send-erc20
      require(openingFeeAsset.transferFrom(decodeData.to, address(this), decodeData.openingFeeAmount), "ERC20 transfer Failed");
      openingFeeAsset.approve(address(lender), decodeData.openingFeeAmount);
    }

    lender.borrow(_txData, _policyData);
    emit DebtTokenBorrowed(
      decodeData.amount,
      decodeData.rateMode,
      decodeData.to,
      decodeData.covered,
      decodeData.openingFeeAmount,
      decodeData.openingFeeAsset,
      decodeData.prevBalance,
      decodeData.collateral,
      decodeData.token,
      decodeData.market,
      _lender
    );
  }

  /**
   * @notice function to add policy to existing loan
   * @param _loanId The loan id the policy is being added to
   * @param _policyData The data being used to build the policy
   * @param _openingFeeAsset The asset address being used to pay initialization fee
   */
  function addPolicyToLoan(uint256 _loanId, bytes memory _policyData, address _openingFeeAsset) external emergencyStop {
    (, , uint256 _openingFee, , , , , ) = abi.decode(_policyData, (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256));
    IERC20 openingFeeAsset = IERC20(_openingFeeAsset);
    require(openingFeeAsset.transferFrom(msg.sender, address(this), _openingFee), "ERC20 Transfer Failed");
    openingFeeAsset.approve(address(baseLoanBroker), _openingFee);
    baseLoanBroker.addPolicyToLoan(_loanId, _policyData, _openingFeeAsset);
  }

  /**
   * @notice function provided to allow cancellation of policy without penalty
   * @param _loanId The id of the loan having policy cancelled
   */
  function cancelPolicyNoPenalty(uint256 _loanId) external emergencyStop isCoreOrManagerOrBaseLoan {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    uint256 policyId = loanInfo.policyData.policyId;
    brokerage.removePolicyFromLoan(_loanId);
    emit PolicyCanceled(_loanId, policyId);
  }

  /**
   * @notice function to facilitate cancellation of a policy with penalty (cancellation fee)
   * @param _loanId the id of the loan having policy cancelled
   * @param _penaltyAsset the asset address to pay the cancellation fee with
   */
  function cancelPolicyWithPenalty(uint256 _loanId, address _penaltyAsset) external emergencyStop {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    IBrokerage.Policy memory policy = loanInfo.policyData;
    uint256 policyId = loanInfo.policyData.policyId;
    IERC20 asset = IERC20(_penaltyAsset);
    require(asset.transferFrom(msg.sender, address(this), policy.cancellationFee), "ERC20 Transfer Failed");
    asset.approve(address(baseLoanBroker), policy.cancellationFee);
    brokerage.removePolicyFromLoan(_loanId);
    emit PolicyCanceledFee(_loanId, _penaltyAsset, policyId);
  }

  /**
   * @notice withdraw is called by user to withdraw their collateral.
   * @param _txData is encoded bytes containing loan platform specific params
   */
  function withdraw(string memory _lender, bytes calldata _txData, uint256 _loanId) external emergencyStop {
    ValidationLogic.validateWithdraw(_lender, _txData, brokerageV, _loanId);
    ILoanBroker lender = ILoanBroker(borrowerToLenderDeployed[msg.sender][_lender]);
    ILoanBroker.WithdrawData memory decodeData = abi.decode(_txData, (ILoanBroker.WithdrawData));
    lender.withdrawCollateral(_txData);
    emit CollateralWitdrawn(decodeData.market, decodeData.token, decodeData.amount, decodeData.to, _lender, _loanId);
  }

  /**
   * @notice repay is called by user to repay their loan.
   * @param _txData is encoded bytes containing loan platform specific params
   */
  function repay(string memory _lender, bytes calldata _txData, uint256 _loanId) external emergencyStop {
    ValidationLogic.validatePayback(_lender, _txData, brokerageV, _loanId);
    ILoanBroker.PaybackData memory decodeData = abi.decode(_txData, (ILoanBroker.PaybackData));
    ILoanBroker lender = ILoanBroker(borrowerToLenderDeployed[decodeData.holder][_lender]);
    IERC20 token = IERC20(decodeData.token);
    require(token.transferFrom(msg.sender, address(this), decodeData.amount), "ERR: Token transfer Failed");
    token.approve(address(lender), decodeData.amount);
    lender.repayLoan(_txData);
    emit LoanPaid(decodeData.market, decodeData.token, decodeData.rateMode, decodeData.holder, decodeData.amount, decodeData.collateral, _lender, _loanId);
  }

  /**
   * @notice Create Portfolio for the user
   * @param _holder is the input address of the user
   */
  function createPortfolio(address _holder) internal emergencyStop {
    require(portfolioIdsByAddress[_holder] == 0, "User already has a portfolio issued to the given address");
    uint256 tokenId = portfolio.authorizedMint(address(_holder));
    portfolioIdsByAddress[address(_holder)] = tokenId;
  }

  /**
   * @notice Create OnBehlad Portfolio lets admins mint protfolios for the user
   * @param _holder is the input address of the user
   */
  function createOnBehalfPortfolio(address _holder) public onlyManager emergencyStop {
    require(portfolioIdsByAddress[_holder] == 0, "User already has a portfolio issued to the given address");
    uint256 tokenId = portfolio.authorizedMint(address(_holder));
    portfolioIdsByAddress[address(_holder)] = tokenId;
  }

  /**
   * @notice lets user deposit into a vault
   * @param _vaultId The id of the vault the user is depositing into
   * @param _depositParams Struct of params required for deposit (see IVaultSale)
   */
  function depositToVault(uint256 _vaultId, VaultSale.DepositParams calldata _depositParams) external emergencyStop {
    require(_vaultId > vaultSale.getCurrentVault(), "Core: Vault ID not valid");
    vaultSale.depositIntoVault(_vaultId, _depositParams);
  }

  /**
   * @notice Call BaseLoanBroker to update individual loans to show they are in breach of LTV1
   * @param _loanIds An array of loan IDs to be updated
   * @param _amount The total amount needed to be swapped
   * @param _collateral The address of the collateral token being swapped into
   */
  function logLTV1Breaches(uint256[] calldata _loanIds, uint256 _amount, address _collateral) external emergencyStop {
    for (uint256 i = 0; i < _loanIds.length; i++) {
      baseLoanBroker.handleLTV1Breached(_loanIds[i]);
    }
    baseLoanBroker.requestSwap(_amount, _collateral);
  }

  /**
   * @notice entry point to update a loan to that is in violation of LTV2.
   * @param _loanId The id of the loan being updated
   * @param _claimToken The token being used to bring loan back into healthy status (same as collateral)
   * @param _claimAmount How much the claim is for
   * @param _borrower Who has the loan out
   * @param _lender The string name of the lender used in the loan
   * @param _market The address of the lender marketplace
   */
  function logLTV2Breaches(uint256 _loanId, address _claimToken, uint256 _claimAmount, address _borrower, string memory _lender, address _market) external emergencyStop {
    ILoanBroker lender = ILoanBroker(borrowerToLenderDeployed[_borrower][_lender]);
    baseLoanBroker.handleLTV2Breached(_loanId, _claimToken, _claimAmount, address(lender), _market);
  }

  /**
   * @notice Allows a user to repay a claim loan
   * @param _loanId the id of the loan with claim to be paid
   * @param _paymentToken The asset being used to pay for the claim
   * @dev First calls updateClaim with a zero amount. This is to get the most up to date balance. This is necessary because the interest is calculated by the second. Therefore the calls all need to happen within the same block. IF we don't do this here, the user cannot get out ahead of the interest and the claim will never be paid off
   */
  function repayClaim(uint256 _loanId, address _paymentToken) external {
    brokerage.updateClaim(_loanId, 0);
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    uint256 amount = loanInfo.policyData.claims[loanInfo.policyData.claims.length - 1].claimBalance;
    uint256 claimId = loanInfo.policyData.claims[loanInfo.policyData.claims.length - 1].claimId;
    require(IERC20(_paymentToken).transferFrom(msg.sender, companyTreasury, amount), "ERR: Token transfer failed");
    baseLoanBroker.repayClaim(_loanId, amount);
    emit ClaimUpdate(amount, _loanId, claimId);
  }

  // Add update claim balance to core interface

  /**
   * @notice transferLoanToConcrete is used by the automation to transfer the ownership of a loan from a user to concrete
   * @param _loanId is the ID of the loan being transfered
   * @param _covered is a bool representing whether or not the input loan is covered
   */
  function transferLoanToConcrete(uint256 _loanId, bool _covered) external emergencyStop {
    baseLoanBroker.concreteTakeOverLoan(_loanId, companyTreasury, _covered);
  }

  /**
   * @notice Register a new lender protocol with the platform
   * @param _name The name of lender
   */
  function registerNewLender(string memory _name) external isCoreOrManager {
    registeredLenders[_name] = true;
    emit LenderAdded(_name);
  }

  /**
   * @notice De-Register a lender with the platform
   * @param _name The name of the lender being removed
   */
  function deRegisterLender(string memory _name) external isCoreOrManager {
    registeredLenders[_name] = false;
    emit LenderRemoved(_name);
  }

  function registerLenderMarket(string memory _name, address _markert) external isCoreOrManager {
    require(registeredLenders[_name], "ERR: Lender not approved");
    registeredLenderMarkets[_name] = _markert;
  }

  /**
   * @notice Register a new automation provider protocol with the platform
   * @param _name The provider name
   * @param _providerAddress The address of the provider
   */
  function registerNewAutomationProvider(string memory _name, address _providerAddress) external isCoreOrManager {}

  /**
   * @notice Register a new automation provider protocol with the platform
   * @param _name The dex name
   * @param _dexAddress The dex Address
   */
  function registerNewDEX(string memory _name, address _dexAddress) external isCoreOrManager emergencyStop {
    registeredDexAddresses[_name] = _dexAddress;
  }

  /**
   * @notice Public function which checks for the loan status and if policy can be claimed initiates the claim process.
   * @param _policyId The policy ID
   * @dev This is mainly to be called by the automation provider
   */
  function checkAndInitiateClaim(uint256 _policyId) external {}

  /**
   * @notice Set new company treasury
   * @param _newCompanyTreasury new treasury address
   */
  function setCompanyTreasury(address _newCompanyTreasury) external isCoreOrManager emergencyStop {
    companyTreasury = _newCompanyTreasury;
  }

  /**
   * @notice Set new Vault Manager address
   * @param _newVaultManagerAddress new vault manager address
   */
  function setVaultManager(address _newVaultManagerAddress) external isCoreOrManager emergencyStop {
    vaultManager = _newVaultManagerAddress;
  }

  /**
   * @notice getPortfolioId is used to retrieve a users portfolio
   * @param _holder the address of the user in question
   * @return is the portfolio ID for the user
   */
  function getPortfolioId(address _holder) public view returns (uint256) {
    return portfolioIdsByAddress[_holder];
  }

  function removeApprovedCollateralFromLender(string memory _lender, address _collateral) external {
    _allowedCollateralType[_lender][_collateral] = false;
    emit CollateralRemovedFromLender(_lender, _collateral);
  }

  function addApprovedCollateralToLender(string memory _lender, address _collateral) external {
    _allowedCollateralType[_lender][_collateral] = true;
    emit CollateralAddedToLender(_lender, _collateral);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {EmergencyStop} from "./EmergencyStop.sol";

contract EmergencyModifier {
  /**
   * @notice  The EmergencyStop contract
   */
  EmergencyStop public emsContract;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier emergencyStop() {
    require(!emsContract.paused(), "EMS: paused");
    _;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {ACL} from "../acl/Acl.sol";
import {IEmergencyStop} from "../interfaces/emergency/IEmergencyStop.sol";

contract EmergencyStop is IEmergencyStop, Initializable, ACLUser {
  bool private _paused;

  function initialize(address aclAddress_) public initializer {
    aclContract = ACL(aclAddress_);
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Throws if the contract is paused.
   */
  function _requireNotPaused() public view {
    require(!paused(), "EMS: paused");
  }

  /**
   * @dev Throws if the contract is not paused.
   */
  function _requirePaused() public view {
    require(paused(), "EMS: not paused");
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function masterSwitchOn() external virtual onlyAuthorized {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function masterSwitchOff() external virtual onlyAuthorized {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ACL} from "../acl/Acl.sol";
import {IUpgradableBeaconManager} from "../interfaces/upgradableBeaconManager/IUpgradableBeaconManager.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";

/**
 * @title Factoy
 * @author Josh-Jack
 * @notice The Factory contract will create proxy instances of all contracts
 */
contract Factory is Initializable, ACLUser, EmergencyModifier {
  /**
   * @notice  The upgradable beacon manager
   */
  address public upgradableBeaconManager;

  /**
   * @notice  The upgradable beacon
   */
  address public beacon;

  /**
   * @notice proxies maps the name of a proxy to the address array of the proxies addresses
   */
  mapping(string => address[]) proxies;

  ///@dev checks to ensure that the address is valid
  modifier isAddressValid(address address_) {
    require(address_ != address(0), "Must specify a valid address.");
    _;
  }

  /**
   * @notice The initialize function will act as a constructor to initialize this contract and the ACL contract.
   * @param _aclAddress is the address of the ACL contract.
   * @dev this initializes the upgradeable beacon that will hold the implementation address.
   */
  function initialize(address _aclAddress, address beaconManager_, address _emsAddress) public initializer isAddressValid(_aclAddress) isAddressValid(beaconManager_) {
    aclContract = ACL(_aclAddress);
    upgradableBeaconManager = beaconManager_;
    emsContract = EmergencyStop(_emsAddress);
  }

  /**
   * @notice Creates a proxy with the implementation as the root
   * @param _data is the initialize information needed to init contracts
   * @param _name  index name of where the proxy will be stored
   */
  function createProxy(bytes memory _data, string memory _name) external emergencyStop returns (BeaconProxy) {
    IUpgradableBeaconManager ubm = IUpgradableBeaconManager(upgradableBeaconManager);
    beacon = ubm.getBeacon(_name);
    BeaconProxy proxy = new BeaconProxy(address(beacon), _data);
    proxies[_name].push(address(proxy));
    return proxy;
  }

  /**
   * @notice getLatestProxyAddress returns the last proxy address of an input proxy name
   * @param name_ is the name of the proxy
   * @return is the last proxy's address
   */
  function getLatestProxyAddress(string memory name_) external view returns (address) {
    return proxies[name_][proxies[name_].length - 1];
  }
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IACL {
  function createRole(string memory name_, address recipient_) external;

  function assignRole(string memory role_, address recipient_) external;

  function revokeUserRole(string memory role_, address user_) external;

  function getAllRoleHolders(string memory role_) external view returns (address[] memory);

  function getAllRoles() external view returns (string[] memory);

  function getAllRolesHeldByAddress(address user_) external view returns (string[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBrokerage {
  //@notice Enum to be able to display the current loan status
  enum LoanStatus {
    COVERED,
    UNCOVERED,
    CLAIM_INITIATED,
    CONCRETE_MANAGED,
    SUCCESSFULLY_CLOSED,
    LIQUIDATED
  }

  enum PolicyStatus {
    OPEN,
    LTV1,
    LTV2,
    LTV3
  }

  //@notice The basic loan info
  struct LoanInfo {
    address loanHolder;
    uint256 portfolioId;
    uint256 loanId;
    uint256 vaultId;
    uint256 startDate;
    uint256 LTV1;
    uint256 LTV2;
    uint256 LTV3;
    uint256 lenderLTV;
    uint256 loanAmount;
    uint256 currentLoanBalance;
    uint256 collateralBalance;
    address debtTokenAddress;
    address collateralAddress;
    LoanStatus loanStatus;
    // UncoveredLoan[] uncoveredLoanData;
    Policy policyData;
  }

  //@notice Struct to track uncovered loan data (if needed)
  // struct UncoveredLoan {
  //   address loanHolder;
  // }

  //@notice Basic policy data
  struct Policy {
    uint256 policyId;
    bool active;
    uint256 cancellationFee;
    uint256 premium;
    PolicyStatus policyStatus;
    PolicyUpdate[] policyUpdates;
    Claim[] claims;
  }

  //@notice Struct holding most current (changeable) policy data
  struct PolicyUpdate {
    uint256 openingFee;
    uint256 startDate;
    uint256 endDate;
    uint256 totalCreditOffered;
    uint256 availableCredit;
    uint256 interestRate;
  }

  //@notice Struct holding claim info
  struct Claim {
    address claimToken;
    uint256 claimDate;
    uint256 claimAmount;
    uint256 claimId;
    uint256 claimAPY; // This is represented in basis points i.e. 10% == 1000
    uint256 claimBalance; // Needs to be passed from the frontend as BN
    bool claimRepaid;
  }

  event LoanTokenCreated(uint256 loanId, uint256 startDate, uint256 LTV1, uint256 LTV2, uint256 LTV3, uint256 lenderLTV, LoanStatus loanStatus, address collateralAddress);

  event PolicyCreated(uint256 loanId, uint256 policyId, address loanHolder, bool active, uint256 cancellationFee, uint256 premium, PolicyStatus policyStatus, uint256 openingFee, uint256 startDate, uint256 endDate, uint256 totalCreditOffered, uint256 availableCredit, uint256 interestRate);

  event ClaimInitiated(uint256 loanId, address claimToken, uint256 claimDate, uint256 claimAmount, uint256 claimId, uint256 claimAPY, uint256 claimBalance, bool claimRepaid);

  event ClaimUpdated(uint256 loanID, uint256 amountPaid, uint256 claimID);

  event RemovePolicyFromLoan(uint256 loanId, LoanStatus loanStatus);

  event LoanUpdated(uint256 loanId, LoanInfo loanInfo);

  event LoanClosed(uint256 loanId, LoanStatus loanstaus, uint256 policyId);

  event CheckComplete(uint256[] ltv1, uint256[] ltv2, uint256[] ltv3);

  event AmountAddedToLoan(uint256 loanId, uint256 amount,address debtToken, address owner);

  event UpdateLTV(uint256 loanId, PolicyStatus policyStaus);

  function mint(uint256 _portfolioId, bytes memory _loanData) external returns (uint256);

  function addPolicyToLoan(uint256 _loanId, bytes memory _policyData) external;

  function removePolicyFromLoan(uint256 _loanId) external;

  function successfullyCloseLoan(uint256 _loanId) external;

  function updateClaim(uint256 _loanId, uint256 _amountPaid) external;

  function cancelPolicy(uint256 _loanId) external;

  function getLoanInfoById(uint256 _loanId) external returns (LoanInfo memory);

  function getPolicyInfoById(uint256 _loanId) external returns (Policy memory);

  function transferLoanToConcrete(uint256 _loanId, address _concreteTreasury, uint256 _vaultId) external;

  function initiateClaim(uint256 _loanId, bytes memory _data) external;

  function updateLoanInfo(uint256 _tokenId, LoanInfo memory _loanInfo) external;

  function addBorrowToLoan(uint256 _tokenId, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

interface ICore {
  /** EVENTS */
  event LenderCreated(string _lenderName, address _lenderAddress);
  event ClaimUpdate(uint256 claimBalance, uint256 loanId, uint256 claimId);
  event PolicyCanceled(uint256 loanId, uint256 policyId);
  event PolicyCanceledFee(uint256 loanId, address feeToken, uint256 policyID);
  event LenderAdded(string _lenderName);
  event CollateralAddedToLender(string _lenderName, address _collateral);
  event LenderRemoved(string _lenderName);
  event CollateralRemovedFromLender(string _lenderName, address _collateral);
  event CollateralSupplied(uint256 amount, address market, address onBehalf, bool covered, address openingFeeAsset, uint256 openingFeeAmount, address collateral, string lenderName, uint256 portfolioId);
  event DebtTokenBorrowed(uint256 amount, uint256 rateMode, address to, bool covered, uint256 openingFeeAmount, address openingFeeAsset, bool prevBalance, address collateral, address token, address market, string lenderName);
  event LoanPaid(address market, address token, uint256 rateMode, address holder, uint256 amount, address collateral, string lenderName, uint256 loanID);
  event CollateralWitdrawn(address market, address token, uint256 amount, address to, string lenderName, uint256 loanId);

  function checkAndInitiateClaim(uint256 policyId) external;

  function companyTreasury() external view returns (address);

  function registerNewDEX(string memory name, address dexAddress) external;

  function setCompanyTreasury(address newCompanyTreasury) external;

  function setVaultManager(address newVaultManagerAddress) external;

  // function vaultManager() external view returns (address);

  function getPortfolioId(address _holder) external view returns (uint256);

  function registerNewLender(string memory _name) external;

  function createNewVaultSale(uint256 _liquidityCap, uint256 _maxYield, uint256 _minYield, uint24 _riskFactor, uint256 _maturationTime, address _liquidityAsset) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IDex {
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address inputAsset, address outputAsset, address to) external returns (uint amountOut);

  function swapExactETHForTokens(uint amountOutMin, address outputAsset, address to) external payable returns (uint amountOut);

  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address inputAsset, address to) external returns (uint amountOut);

  function getAssetPrice(uint amountIn, address inputAsset, address outputAsset) external returns (uint amountOut);

  function setProtocolAddress(address newAddress) external;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IEmergencyStop {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  function masterSwitchOn() external;

  function masterSwitchOff() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IBaseLoanBroker {
  event OpeningFee(uint256 amount);

  event Liquidation(uint256 loanId);

  event CollateralToBroker(uint256 _amount, address _collateralAddress, address _market);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface ILoanBroker {
  
  struct SupplyData {
    address token;
    uint256 amount;
    address market;
    address onBehalf;
    bool covered;
    uint256 openingFeeAmount;
    address openingFeeAsset;
  }

  struct BorrowData {
    address market;
    address token;
    uint256 amount;
    uint256 rateMode;
    address to;
    bool covered;
    uint256 openingFeeAmount;
    address openingFeeAsset;
    bool prevBalance;
    address collateral;
  }

  struct PaybackData {
    address market;
    address token;
    uint256 rateMode;
    address holder;
    uint256 amount;
    address collateral;
  }

  struct WithdrawData {
    address market;
    address token;
    uint256 amount;
    address to;
  }

  //Lender functions
  function supplyCollateral(bytes calldata _txData, bytes calldata _loanData) external payable;

  function concreteSupplyCollateral(address _token, uint256 _amount, address _market) external payable;

  function borrow(bytes calldata _txData, bytes calldata _policyData
 ) external payable;

  function withdrawCollateral(bytes calldata _txData
 ) external payable;

  function repayLoan(bytes calldata _txData) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;
import {IRewardCollectionToken} from "../rewardTokens/IRewardCollectionToken.sol";

interface IPortfolio {
  struct TransferRequest {
    uint256 requestId;
    address from;
    address to;
    uint256 tokenId;
    uint256 timestamp;
    uint256 cooldownComplete;
    bool executed;
  }

  event PortfolioMinted(address to, uint256 id);
  event TransferRequested(uint256 tokenId, TransferRequest request);
  event TransferExecuted(uint256 tokenId, TransferRequest request);
  event ForceTransfer(uint256 tokenId, address to);
  event PortfolioBurned(uint256 tokenId, uint256 timestamp);
  event PolicyAdded(uint256 tokenId, uint256 policy);

  function updateUrlBase(string memory newUrlBase_) external;

  function updateCooldownPeriod(uint256 time_) external;

  function authorizedMint(address to_) external returns (uint256);

  function authorizedBatchMint(address[] calldata recipients_) external;

  function initializeTransfer(uint256 tokenId_, address to_) external;

  function adminInitTransfer(uint256 tokenId_, address from_, address to_) external;

  function finalizeTransfer(uint256 tokenId_) external;

  function adminFinalizeTransfer(uint256 tokenId_) external;

  function forceTransfer(uint256 tokenId_, address to_) external;

  function burn(uint256 tokenId_) external;

  function tokenURI(uint256 tokenId_) external view returns (string memory);

  function getTransferRequests(uint256 tokenId_) external view returns (TransferRequest[] memory);

  function getRewardCollectionTokensForPortfolio(uint256 _portfolioId) external view returns (IRewardCollectionToken.Reward[] memory);

  function safeTransferFrom(address, address, uint256) external;

  function safeTransferFrom(address, address, uint256, bytes memory) external;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';



interface IPositionToken is IERC721Metadata {
    event MintPositionToken(uint256 tokenId, uint256 amount, uint256 vaultId, address recipient, address collateral, string collateralSymbol, uint256 yield, uint256 lockTime);
    event DepositIncreased(uint256 tokenId, uint256 amount, uint256 yeild);
    event Collect(uint256 tokenId, address recipient, uint256 amount);

    struct Position {
        uint256 vaultId;
        address vaultAddress;
        uint256 amount;
        address collateralToken;
        string collateralSymbol;
        uint256 yield;
        uint256 lockupTime;
    }

    struct MintParams {
        address collateralToken;
        string  collateralSymbol;
        address recipient;
        address vaultAddress;
        uint256 depositAmount;
        uint256 vaultId;
        uint256 yield;
        uint256 lockupTime;
    }

    struct IncreaseDepositParams {
        uint256 tokenId;
        uint256 amount;
        uint256 yield;
    }

    struct CollectParams {
        uint256 vaultId;
        address recipient;
        uint256 amount;
    }

    function positions(uint256 tokenId) external view returns (uint256, address, uint256, uint256, address, string memory);

    function mint(MintParams calldata params) external payable returns (uint256);

    function increaseDeposit(IncreaseDepositParams calldata params) external payable;

    function collect(CollectParams calldata params, uint256 _tokenId) external payable;

    function burn(uint256 _tokenId) external payable;

    function getPositionInfo(uint256 _tokenId) external view returns (Position memory);

    function getUserTokenId(address _user, uint256 _vaultId) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IRewardCollectionToken {
      error Disabled();
      struct Reward {
        address contractAddress;
        uint256 tokenId;
        string name;
    }

    ///@notice Struct that dictates the metadata structure for tokens
    struct Metadata {
        string name;
        string description;
        string external_url;
        string image;
        string thumb;
        string animation_url;
    }

    ///@notice Struct that dictates the Attribute structure for tokens
    struct Attribute {
        string trait_type;
        string value;
    }


    ///@notice Enum to facilitate updating metadata fields
    enum UpdateField {
        IMAGE,
        THUMB,
        EXTERNAL_URL,
        DESCRIPTION,
        ANIMATION_URL
      }
    
      ///@notice Enum to facilitate updating attributes
      enum UpdateType {
        ADD,
        REPLACE,
        REMOVE
      }
      event Minted(
        uint256 tokenID, 
        string name,
        string description,
        string external_url,
        string image,
        string thumb,
        string animation_url);
      event RewardAttributes(
        string trait_type,
        string value);
      function mint(uint256 _tokenId, uint256 _portfolioId) external returns (uint256);
      function createReward(Metadata memory _metadata, Attribute[] memory _attributes, uint256 _tokenId) external returns (uint256);
      function balance(uint256 _portfolioId, uint256 _tokenId ) external view returns (bool);
      function updateAttribute(uint256 _portfolioId, uint256 _tokenId, UpdateType _updateType, Attribute memory _attribute) external; 
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IRewardToken {
    ///@notice Struct that identifies what can be passed to portfolio contract
    struct Reward {
        address contractAddress;
        string name;
        string symbol;
        uint256 tokenId;
    }

    ///@notice Struct that dictates the metadata structure for tokens
    struct Metadata {
        string name;
        string description;
        string external_url;
        string image;
        string thumb;
        string animation_url;
    }

    ///@notice Struct that dictates the Attribute structure for tokens
    struct Attribute {
        string trait_type;
        string value;
    }

    ///@notice Enum to facilitate updating metadata fields
    enum UpdateField {
        IMAGE,
        THUMB,
        EXTERNAL_URL,
        DESCRIPTION,
        ANIMATION_URL
      }
    
      ///@notice Enum to facilitate updating attributes
      enum UpdateType {
        ADD,
        REPLACE,
        REMOVE
      }

    function mint(uint256 _portfolioId, string memory _rewardName, string memory _rewardSymbol,  Metadata calldata _baseMetadata,
    Attribute[] calldata baseAttributes_
) external returns (uint256);

    function replaceMetadata(uint256 _tokenId, Metadata memory _metadata) external;
    function replaceAttributes(uint256 _tokenId, Attribute[] memory _attributes) external;
    function updateMetadataValue(uint256 _tokenId, UpdateField _updateField, string memory _value) external;
    function updateAttribute(uint256 _tokenId, UpdateType _updateType, Attribute memory _attribute) external;
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function getAllTokenAttributes(uint256 _tokenId) external view returns (Attribute[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19;

interface IUpgradableBeaconManager {

      function getBeacon(string memory name_) external view returns(address);
      function deployUpgradeableBeacon(string memory name_, address implementation_) external;
      function upgrade(address newImplementation_, string memory name_) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMasterVault {
  event VaultBalance(address vault, uint256 amount, address token);
  event LoanAdded(uint256 loanID);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;

interface IVault {

    function addLoanToVault(uint256 _tokenId) external;
    function getIsLoanHeldInVault(uint256 _tokenId) external returns (bool);
}

// daily snapshot
//

//SPDX-License-Identifier: MIT
pragma solidity  0.8.19;
import {IPositionToken} from '../positionToken/IPositionToken.sol';

interface IVaultSale {
    ///@notice Event that fires when a user deposits into a vault
    event Deposited(address from, address vault, uint256 vaultId, uint256 amount, uint256 reward);

    ///@notice Event that is fired when a vault sale is started
    event VaultSaleCreated(
        uint256 vaultId,
        uint256 liquidityCap,
        uint256 maxYield,
        uint256 minYield,
        uint24 riskFactor,
        uint256 maturationTime
    );

    ///@notice Event that is fired when a vault sale ends
    event VaultSaleClosed(uint256 vaultId);

    ///@notice params to be passed in when a user deposits to a vault
    struct DepositParams {
        address collateralToken;
        address recipient;
        uint256 depositAmount;
        uint256 positiontokenId;
        string collateralSymbol;
    }

    ///@notice The pertinent info about a vault
    struct VaultInfo {
        uint256 vaultId;
        address vaultAddress;
        uint256 liquidityCap;
        uint256 totalDeposited;
        uint256 maxYield;
        uint256 minYield;
        uint24 riskFactor;
        uint256 maturationTime;
        uint256[] positionTokenIds;
    }

    function updatePositionTokenImplementation(address _updatedAddress) external;

    function depositIntoVault(uint256 _vaultId, DepositParams memory _depositParams) external;

    function createVaultSale(
        uint256 _liquidityCap,
        uint256 _maxYield,
        uint256 _minYield,
        uint24 _riskFactor,
        uint256 _maturationTime,
        address _liquidityAsset
    ) external returns (uint256);

    function withdrawPositionFromVault(IPositionToken.CollectParams calldata _params) external;

    function closeVaultSale(uint256 _vaultId) external;

    function getAvailableVaults() external view returns (VaultInfo[] memory);

    function getCurrentVault() external view returns (uint) ;
}

// SPDX-License-Identifier: MIT

pragma solidity  0.8.19;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity  0.8.19;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be `address(0)`.
     * - `spender` cannot be `address(0)`.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by EIP712.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity  0.8.19;


interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity  0.8.19;
import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity  0.8.19;

import "./IERC20.sol";
import "./IERC2612.sol";
import "./IERC3156FlashLender.sol";

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
interface IWETH10 is IERC20, IERC2612, IERC3156FlashLender {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CompoundInterestCalculator} from "./CompoundInterestCalculator.sol";
import {IBrokerage} from "../interfaces/brokerage/IBrokerage.sol";
import {Brokerage} from "../brokerage/Brokerage.sol";

/**
 * @title ClaimUpdater
 * @author Ryan Turner
 * @dev Makes necessary updates to Brokerage Policy Claim data
 */
library ClaimUpdater {
  /**
   * @notice allows a claim to be updated. Used when a portion of the claim loan is paid, or balance increases
   * @param _loan The id of the loan with the claim that is to be updated
   * @param _amountPaid The new balance for the claim loan
   * @dev if the updated balance is 0 it changes claim to repaid status, otherwise updates the balance
   * @dev only callable by policy admin
   */
  function updateClaim(IBrokerage.LoanInfo storage _loan, uint256 _amountPaid) internal returns (IBrokerage.LoanInfo storage) {
    IBrokerage.Policy storage _policy = _loan.policyData;
    _policy = calculateCompoundInterest(_policy);
    if (_amountPaid != 0) {
      _policy = handlePayment(_policy, _amountPaid);
      if (_amountPaid >= _policy.claims[_policy.claims.length - 1].claimBalance) {
        _policy.claims[_policy.claims.length - 1].claimRepaid = true;
      } else {
        _policy.claims[_policy.claims.length - 1].claimBalance = _policy.claims[_policy.claims.length - 1].claimBalance - _amountPaid;
      }
    }
    _loan.policyData = _policy;
    return _loan;
  }

  /**
   * @notice function that intakes a policy, calculates the updated principal and returns the policy
   * @param _policy The policy that has the claim to be updated
   * @return The updated policy to be saved
   */
  function calculateCompoundInterest(IBrokerage.Policy storage _policy) internal returns (IBrokerage.Policy storage) {
    IBrokerage.Claim storage claim = _policy.claims[_policy.claims.length - 1];
    claim.claimBalance = CompoundInterestCalculator.accrueInterest(claim.claimAmount, CompoundInterestCalculator.yearlyRateToRay(claim.claimAPY), block.timestamp - claim.claimDate);
    _policy.claims[_policy.claims.length - 1] = claim;
    return _policy;
  }

  /**
   * @notice Function that takes in a policy and updates the amount owed on the current claim
   * @param _policy The policy that has the claim to be updated
   * @param _amountPaid The amount to be taken off the principal amount
   */
  function handlePayment(IBrokerage.Policy storage _policy, uint256 _amountPaid) internal returns (IBrokerage.Policy storage) {
    IBrokerage.Claim storage claim = _policy.claims[_policy.claims.length - 1];
    claim.claimBalance = claim.claimBalance - (_amountPaid);
    _policy.claims[_policy.claims.length - 1] = claim;
    return _policy;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./DSMath.sol";

/**
 * @title CompoundInterestCalculator
 * @author Ryan Turner
 * @dev Uses DSMath's wad and ray math to implement (approximately)
 * @dev Allows for second by second updating of principle amount utilizing compounding interest
 * @dev Utilizes DSMath.sol
 */
library CompoundInterestCalculator {
  //// Fixed point scale factors
  // wei -> the base unit
  // wad -> wei * 10 ** 18. 1 ether = 1 wad, so 0.5 ether can be used
  //      to represent a decimal wad of 0.5
  // ray -> wei * 10 ** 27

  /**
   * @notice Function that converts from wad (10**18) to ray (10**27)
   * @param _wad The wad to be converted
   */
  function _wadToRay(uint _wad) internal pure returns (uint) {
    return DSMath.mul(_wad, 10 ** 9);
  }

  /**
   * @notice Function that converts from wei to ray (10**27)
   * @param _wei The value in wei to be converted
   */
  function _weiToRay(uint _wei) internal pure returns (uint) {
    return DSMath.mul(_wei, 10 ** 27);
  }

  /**
   * @notice Function that uses an approximation of continuously calculated compound interest
   * @dev discretely calculates second by second
   * @param _principal The current principal owed on the loan
   * @param _rate The interest rate represented in basis points
   * @param _age The time period that interest is to be accrued (represented in seconds)
   * @return The new principal as a wad. This is equal to original principal + interest accrued
   * @dev basis points are simply the interest rate * 10. Ex; 15% interest = 15 * 10 = 150. This is 150 basis points
   * @dev *
   *   1 + the effective interest rate per second, compounded every
   *   second. As an example:
   *   I want to accrue interest at a nominal rate (i) of 5.0% per year
   *   compounded continuously. (Effective Annual Rate of 5.127%).
   *   This is approximately equal to 5.0% per year compounded every
   *   second (to 8 decimal places, if max precision is essential,
   *   calculate nominal interest per year compounded every second from
   *   your desired effective annual rate). Effective Rate Per Second =
   *   Nominal Rate Per Second compounded every second = Nominal Rate
   *   Per Year compounded every second * conversion factor from years
   *   to seconds
   *   Effective Rate Per Second = 0.05 / (365 days/yr * 86400 sec/day) = 1.5854895991882 * 10 ** -9
   *   The value we want to send this function is
   *   1 * 10 ** 27 + Effective Rate Per Second * 10 ** 27
   *   = 1000000001585489599188229325
   *   This will return 5.1271096334354555 Dai on a 100 Dai principal
   *   over the course of one year (31536000 seconds)
   */
  function accrueInterest(uint _principal, uint _rate, uint _age) internal pure returns (uint) {
    // Changed from rmul to wmul. Returns decimalized value?
    return DSMath.rmul(_principal, DSMath.rpow(_rate, _age));
  }

  /**
   * @dev Takes in the desired nominal interest rate per year, compounded
   *   every second (this is approximately equal to nominal interest rate
   *   per year compounded continuously). Returns the ray value expected
   *   by the accrueInterest function
   * @param _rateWad A wad of the desired nominal interest rate per year,
   *   compounded continuously. Converting from ether to wei will effectively
   *   convert from a decimal value to a wad. So 5% rate = 0.05
   *   should be input as yearlyRateToRay( 0.05 ether )
   * @return 1 * 10 ** 27 + Effective Interest Rate Per Second * 10 ** 27
   */
  function yearlyRateToRay(uint _rateWad) internal pure returns (uint) {
    return DSMath.add(_wadToRay(1 ether), DSMath.rdiv(_wadToRay(_rateWad), _weiToRay(365 * 86400)));
  }
}

//SPDX-License-Identifier: GNU
// DSMath from DappHub -> https://github.com/dapphub/ds-math/blob/784079b72c4d782b022b3e893a7c5659aa35971a/src/math.sol

/// math.sol -- mixin for inline numerical wizardry
// More info on DSMath and fixed point arithmetic in Solidity:
// https://medium.com/dapphub/introducing-ds-math-an-innovative-safe-math-library-d58bc88313da

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.19;

library DSMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint x, uint y) internal pure returns (uint z) {
    return x <= y ? x : y;
  }

  function max(uint x, uint y) internal pure returns (uint z) {
    return x >= y ? x : y;
  }

  function imin(int x, int y) internal pure returns (int z) {
    return x <= y ? x : y;
  }

  function imax(int x, int y) internal pure returns (int z) {
    return x >= y ? x : y;
  }

  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint x, uint n) internal pure returns (uint z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {IRewardToken} from "../interfaces/rewardTokens/IRewardToken.sol";
import {IRewardCollectionToken} from "../interfaces/rewardTokens/IRewardCollectionToken.sol";

library MetadataGenerator {
  ///@notice Base string for metadata building
  string constant base = "data:application/json;base64,";

  /**
   * @notice Function that generates metadata given particular token Data and ouputs marketplace readable string
   * @param _tokenId The token ID being identified
   * @param _metadata The metadata assigned to the given token ID
   * @param _attributes The array of attributes assigned to token
   */
  function generateMetadata(uint256 _tokenId, IRewardToken.Metadata storage _metadata, IRewardToken.Attribute[] storage _attributes) internal view returns (string memory) {
    //Need to disabled due to quotes
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          base,
          Base64Upgradeable.encode(
            bytes(
              abi.encodePacked(
                '{"name": ',
                '"',
                _metadata.name,
                " #",
                StringsUpgradeable.toString(_tokenId),
                '", "description": "',
                _metadata.description,
                '", "image": "',
                _metadata.image,
                '", "thumb": "',
                _metadata.thumb,
                '", "external_url": "',
                _metadata.external_url,
                '", "animation_url": "',
                _metadata.animation_url,
                '", "attributes": ',
                "[",
                _generateAttributes(_attributes),
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function generateMetadata1155(uint256 _tokenId, IRewardCollectionToken.Metadata storage _metadata, IRewardCollectionToken.Attribute[] storage _attributes) internal view returns (string memory) {
    //Need to disabled due to quotes
    /* solhint-disable */
    return
      string(
        abi.encodePacked(
          base,
          Base64Upgradeable.encode(
            bytes(
              abi.encodePacked(
                '{"name": ',
                '"',
                _metadata.name,
                " #",
                StringsUpgradeable.toString(_tokenId),
                '", "description": "',
                _metadata.description,
                '", "image": "',
                _metadata.image,
                '", "thumb": "',
                _metadata.thumb,
                '", "external_url": "',
                _metadata.external_url,
                '", "animation_url": "',
                _metadata.animation_url,
                '", "attributes": ',
                "[",
                _generateAttributes1155(_attributes),
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  /**
   * @notice Helper function to turn array of attributes into marketplace readable string
   * @param _attributes The array of attributes being stringified
   * @return string value of attributes to be inserted into metadata
   */
  function _generateAttributes(IRewardToken.Attribute[] storage _attributes) internal view returns (string memory) {
    string memory str;
    for (uint256 i = 0; i < _attributes.length; i++) {
      str = string.concat(str, "{", '"trait_type": ', '"', _attributes[i].trait_type, '",', '"value": ', '"', _attributes[i].value, _createEnd(_attributes.length, i));
    }
    return str;
  }

  function _generateAttributes1155(IRewardCollectionToken.Attribute[] storage _attributes) internal view returns (string memory) {
    string memory str;
    for (uint256 i = 0; i < _attributes.length; i++) {
      str = string.concat(str, "{", '"trait_type": ', '"', _attributes[i].trait_type, '",', '"value": ', '"', _attributes[i].value, _createEnd(_attributes.length, i));
    }
    return str;
  }

  /**
   * @notice Helper function to create the end of the attribute string. Based on whether or not it is the end of the array
   * @param _length The length of the attribute array
   * @param _index The current index of the loop in _generateAttributes
   */
  function _createEnd(uint256 _length, uint256 _index) internal pure returns (string memory) {
    if (_length - 1 == _index) {
      return
        '"'
        "}";
    } else {
      return
        '"'
        "},";
    }
  }
  /* solhint-enable */
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ILoanBroker} from "../interfaces/loanBroker/ILoanBroker.sol";
import {IBrokerage} from "../interfaces/brokerage/IBrokerage.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {Brokerage} from "../brokerage/Brokerage.sol";
import {Portfolio} from "../portfolio/Portfolio.sol";

library ValidationLogic {
  function validateSupply(bytes calldata _txData, string memory _lender) internal view {
    ILoanBroker.SupplyData memory decodeData = abi.decode(_txData, (ILoanBroker.SupplyData));
    require(decodeData.amount > 0, "ERR: Amount must be greater than zero");
    require(decodeData.openingFeeAmount > 0, "ERR: Amount must be greater than zero");
    require(decodeData.onBehalf == msg.sender, "Supply Data onBehalf not the same as sender");
    require(decodeData.covered == true || decodeData.covered == false, "ERR: Invalid value for 'covered'");
    require(validateStr(_lender) == true, "ERR: Invalid lender name");
  }

  function validateBorrow(bytes calldata _txData, string memory _lender) internal pure {
    ILoanBroker.BorrowData memory decodeData = abi.decode(_txData, (ILoanBroker.BorrowData));
    require(decodeData.amount != 0, "ERR: Amount must be greater than zero");
    require(decodeData.to != address(0x0));
    require(decodeData.openingFeeAmount != 0, "ERR: Amount must be greater than zero");
    require(decodeData.openingFeeAsset != address(0x0), "ERR: Amount must be greater than zero");
    require(decodeData.collateral != address(0x0));
    require(validateStr(_lender) == true, "ERR: Invalid lender name");
  }

  function validateWithdraw(string memory _lender, bytes calldata _txData, address _brokerage, uint256 _loanId) internal {
    ILoanBroker.WithdrawData memory decodeData = abi.decode(_txData, (ILoanBroker.WithdrawData));
    require(decodeData.amount != 0, "ERR: Amount must be greater than zero");
    require(validateStr(_lender) == true, "ERR: Invalid lender name");

    IBrokerage.LoanInfo memory loanInfo = IBrokerage(_brokerage).getLoanInfoById(_loanId);
    require(msg.sender == loanInfo.loanHolder, "CORE: Caller not loan owner");
  }

  function validatePayback(string memory _lender, bytes calldata _txData, address _brokerage, uint256 _loanId) internal {
    ILoanBroker.PaybackData memory decodeData = abi.decode(_txData, (ILoanBroker.PaybackData));
    require(decodeData.amount != 0, "ERR: Amount must be greater than zero");
    require(decodeData.token != address(0x0), "ERR: Invalid token address");
    require(decodeData.collateral != address(0x0), "ERR: Invalid collateral token address");
    require(validateStr(_lender) == true, "ERR: Invalid lender name");
    IBrokerage.LoanInfo memory loanInfo = IBrokerage(_brokerage).getLoanInfoById(_loanId);
    if (loanInfo.policyData.claims.length > 0) {
      require(loanInfo.policyData.claims[loanInfo.policyData.claims.length - 1].claimBalance == 0, "ERR: Cannot payoff loan with active claim");
    }
    require(msg.sender == loanInfo.loanHolder, "CORE: Caller not loan owner");
    require(decodeData.amount <= loanInfo.currentLoanBalance, "ERR: Withdraw amount invalid");
  }

  function validateLoanData(bytes calldata _loanData) internal pure {
    (address loanHolder, uint256 startDate, uint256 LTV1, uint256 LTV2, uint256 LTV3, uint256 lenderLTV, uint256 suppliedAmount, address collateralAddress, string memory lender) = abi.decode(
      _loanData,
      (address, uint256, uint256, uint256, uint256, uint256, uint256, address, string)
    );

    require(loanHolder != address(0), "ERR: Invalid loan holder address");
    require(startDate != 0, "ERR: Invalid start date");
    require(LTV1 != 0, "ERR: Invalid LTV1");
    require(LTV2 != 0, "ERR: Invalid LTV2");
    require(LTV3 != 0, "ERR: Invalid LTV3");
    require(lenderLTV != 0, "ERR: Invalid lender LTV");
    require(suppliedAmount != 0, "ERR: Invalid supplied amount");
    require(collateralAddress != address(0), "ERR: Invalid collateral address");
    require(bytes(lender).length != 0, "ERR: Invalid lender");
  }

  function validatePolicyData(bytes calldata _policyData) internal pure {
    (uint256 cancellationFee, uint256 openingFee, uint256 startDate, uint256 endDate, uint256 totalCreditOffered, uint256 interestRate, uint256 premium) = abi.decode(
      _policyData,
      (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
    );

    require(cancellationFee != 0, "ERR: Invalid cancellation fee");
    require(openingFee != 0, "ERR: Invalid opening fee");
    require(startDate != 0, "ERR: Invalid start date");
    require(endDate != 0, "ERR: Invalid end date");
    require(totalCreditOffered != 0, "ERR: Invalid total credit offered");
    require(interestRate != 0, "ERR: Invalid interest rate");
    require(premium != 0, "ERR: Invalid premium");
  }

  // Master Vault
  function validateRequestPolicyFee(uint256 _amount) internal pure {
    require(_amount > 0, "ERR: Invalid request amount");
  }

  function validateSwap(uint256 _amount, address _collateralAddress) internal pure {
    require(_amount > 0, "ERR: Invalid swap amount");
    require(_collateralAddress != address(0x0), "ERR: Invalid collateral address");
  }

  function validateSendCollateral(address _to, uint256 _amount, address _collateral) internal pure {
    require(_to != address(0x0), "ERR: Invalid address");
    require(_amount > 0, "ERR: Invalid collateral send amount");
    require(_collateral != address(0x0), "ERR: Invalid collateral address");
  }

  function validateSendDebtTokens(address _to, uint256 _amount, address _debtTokenAddress) internal pure {
    require(_to != address(0x0), "ERR: Invalid address");
    require(_amount > 0, "ERR: Invalid collateral send amount");
    require(_debtTokenAddress != address(0x0), "ERR: Invalid collateral address");
  }

  function validateExecuteSwap() internal pure {}

  function validateStr(string memory str) public pure returns (bool) {
    bytes memory b = bytes(str);
    if (b.length > 8) return false;

    for (uint i; i < b.length; i++) {
      bytes1 char = b[i];

      if (
        (char >= 0x30 && char <= 0x39) && (char == 0x2E) //9-0 //.
      ) return false;
    }
    return true;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {RewardToken} from "../rewardTokens/RewardToken.sol";
import "../rewardTokens/RewardToken.sol";
import "../brokerage/Brokerage.sol";
import {ILoanBroker} from "../interfaces/loanBroker/ILoanBroker.sol";
import {IBaseLoanBroker} from "../interfaces/loanBroker/IBaseLoanBroker.sol";
import {IBrokerage} from "../interfaces/brokerage/IBrokerage.sol";
import {IVault} from "../interfaces/vaults/IVault.sol";
import {IRewardCollectionToken} from "../interfaces/rewardTokens/IRewardCollectionToken.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {MasterVault} from "../vaults/MasterVault.sol";

/**
 * Possible other functions needed:
 * pull funds from liquidation vault and transfer to treasury
 * Functions to handle closing a retail vault
 */

contract BaseLoanBroker is Initializable, ACLUser, EmergencyModifier, IBaseLoanBroker {
  address USDC_ADDRESS; // This is mutable, since the contract can be deployed on mult. chains
  address liquidationVault;
  uint256 constant liquidationVaultId = 2;

  /**
   * @notice Mapping of the roles and the function signatures they are allowed to call on certain addresses
   */
  mapping(bytes32 => mapping(address => mapping(bytes4 => bool))) public roleAllowedSignatures;

  /**
   * @notice Mapping of the whitelisted target contract addresses for lender implementations
   */
  mapping(address => bool) public whitelistedTargetAddresses;

  IBrokerage brokerage;
  MasterVault masterVault;
  IRewardCollectionToken reward;

  address __masterVault;

  /**
   * @notice initialize is used during the deployment and setup of this contract
   * @param _erc20 is the address of the USDC token
   * @param _brokerage is the address of the brokerage contract
   * @param _masterVault is the address of the master vault contract
   * @param _liquidationVault is the address of the liquidation vault contract
   */
  function initialize(
    address _erc20,
    address _brokerage,
    address payable _masterVault,
    address _liquidationVault,
    address _aclAddress,
    address _rewardFactory,
    address _emsAddress
  ) external initializer {
    brokerage = IBrokerage(_brokerage);
    masterVault = MasterVault(_masterVault);
    __masterVault = _masterVault;
    reward = IRewardCollectionToken(_rewardFactory);
    aclContract = ACL(_aclAddress);
    liquidationVault = _liquidationVault;
    emsContract = EmergencyStop(_emsAddress);
    USDC_ADDRESS = _erc20;
  }

  /**
   * @param _portfolioId The portfolio ID for the loan recipient
   * @param _mintData A bytes representation of the required mint data
   */
  function openLoan(uint256 _portfolioId, bytes memory _mintData) external emergencyStop returns (uint256) {
    require(_mintData.length > 0, "Loan Base cannot be blank");
    uint256 tokenId = brokerage.mint(_portfolioId, _mintData);
    bool userBalance = reward.balance(_portfolioId, 1);
    if (!userBalance) {
      reward.mint(1, _portfolioId);
    } else {
      IRewardCollectionToken.Attribute memory attribute = IRewardCollectionToken.Attribute("numberIssued", "1");
      reward.updateAttribute(_portfolioId, 1, IRewardCollectionToken.UpdateType.ADD, attribute);
    }

    return tokenId;
  }

  /**
   * @notice Function that adds a concrete policy to a given loan
   * @dev Mints a policy token
   * @dev transfers opening fee to the master vault
   * @param _loanId The id number of the loan being updated
   * @param _policyData A bytes representation of data required for mint in the brokerage contract
   * @param _openingFeeAsset The asset address of the currency being used for the opening fee (0x0 for eth)
   */
  function addPolicyToLoan(uint256 _loanId, bytes memory _policyData, address _openingFeeAsset) external emergencyStop {
    require(!aclContract.hasRole(BORROWER, msg.sender), "ACL: caller has to be an admin or the core");
    require(_policyData.length > 0, "Loan Base cannot be blank");
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    (, , uint256 _openingFee, , , , , ) = abi.decode(_policyData, (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256));
    brokerage.addPolicyToLoan(_loanId, _policyData);
    transferOpeningFee(_openingFee, _openingFeeAsset);
    IVault vault = IVault(__masterVault);
    vault.addLoanToVault(_loanId);
    bool userBalance = reward.balance(loanInfo.portfolioId, 2);
    if (!userBalance) {
      reward.mint(2, loanInfo.portfolioId);
    } else {
      IRewardCollectionToken.Attribute memory attribute = IRewardCollectionToken.Attribute("numberIssued", "1");
      reward.updateAttribute(loanInfo.portfolioId, 1, IRewardCollectionToken.UpdateType.ADD, attribute);
    }
  }

  /**
   * @notice Allows cancellation of policy with no penalty
   * @param _loanId The id of the loan having policy cancelled
   */
  function cancelPolicyNoPenalty(uint256 _loanId) external emergencyStop isCoreOrManager {
    brokerage.removePolicyFromLoan(_loanId);
  }

  /**
   * @notice Allows cancellation of policy with penalty (cancellation fee)
   * @param _loanId The id of the loan having policy cancelled
   * @param _asset The asset used to pay cancellation fee
   */
  function cancelPolicyWithPenalty(uint256 _loanId, address _asset) external emergencyStop isCoreOrManager {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    IBrokerage.Policy memory policy = loanInfo.policyData;
    transferOpeningFee(policy.cancellationFee, _asset);
    brokerage.removePolicyFromLoan(_loanId);
  }

  /**
   * @notice Function that takes the opening fee, converts the asset being used to pay fee to usdc and transfers to the master vault
   * @param _openingFee The amount being transferred
   * @param _openingFeeAsset the address of the currency being used for the opening fee (0x0 for eth)
   */
  function transferOpeningFee(uint256 _openingFee, address _openingFeeAsset) public emergencyStop {
    ERC20 usdc = ERC20(USDC_ADDRESS);
    if (_openingFeeAsset != address(USDC_ADDRESS)) {
      ERC20 asset = ERC20(_openingFeeAsset);
      bool success = asset.transferFrom(msg.sender, address(this), _openingFee);
      bool success1 = asset.transfer(address(masterVault), _openingFee);
      require(success, "Opening Fee Transfer Failed");
      require(success1, "Token Transfer to Master Vault Failed");
      requestSwap(_openingFee, _openingFeeAsset);
    } else {
      bool success = usdc.transfer(address(masterVault), _openingFee);
      require(success, "USDC Transfer Failed");
      emit OpeningFee(_openingFee);
    }
  }

  /**
   * @notice Function that allows concrete to take over a loan
   * @param _loanId The id number of the loan being updated
   * @param _concreteTreasury The address of the concrete treasury
   * @dev Pulls loan info from token id, transfers in opening fee from master vault, sends
   * @dev opening fee to liquidation vault and updates the loan info in brokerage contract
   */
  function concreteTakeOverLoan(uint256 _loanId, address _concreteTreasury, bool covered) external emergencyStop {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    ERC20 usdc = ERC20(USDC_ADDRESS);
    IVault vault = IVault(liquidationVault);
    if (covered) {
      uint256 openingFee = loanInfo.policyData.policyUpdates[loanInfo.policyData.policyUpdates.length - 1].openingFee;
      masterVault.requestPolicyFee(openingFee);
      usdc.approve(liquidationVault, openingFee);
      bool success = usdc.transfer(liquidationVault, openingFee);
      require(success, "USDC Transfer Failed");
    }
    vault.addLoanToVault(_loanId);

    brokerage.transferLoanToConcrete(_loanId, _concreteTreasury, liquidationVaultId);
    emit Liquidation(_loanId);
  }

  /**
   * @notice function that transfers a loan to a retail vault.
   * @param _loanId The id number of the loan being updated
   * @param _vaultAddress The address of the retail vault
   * @param _vaultId The id of the retail vault
   * @dev Makes necessary changes to the brokerage LoanInfo struct
   */
  function transferLoanToRetailVault(uint256 _loanId, address _vaultAddress, uint256 _vaultId) external emergencyStop isCoreOrManager {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    IVault vault = IVault(_vaultAddress);
    vault.addLoanToVault(_loanId);
    loanInfo.vaultId = _vaultId;
    brokerage.updateLoanInfo(_loanId, loanInfo);
  }

  /**
   * @notice Function that allows transfer of all policy fees to go into a retail vault
   * @dev To be called from backend after tallying the total of the policy fees of all loans being transferred to the retail vault
   * @param _vaultAddress The address of the retail vault receiving loans
   * @param _amount The total amount of all policy fees to be transferred
   */
  function transferAllPolicyFeesToRetailVault(address _vaultAddress, uint256 _amount) external emergencyStop isCoreOrManager {
    ERC20 usdc = ERC20(USDC_ADDRESS);
    masterVault.requestPolicyFee(_amount);
    bool success = usdc.transfer(_vaultAddress, _amount);
    require(success, "USDC Transfer Failed");
  }

  //LTV1 breach functions
  /**
   * @notice requests a swap from usdc to the needed collateral type from master vault
   * @dev Does not transfer funds
   * @dev This should be called from the backend once the total needed is tallied
   * @param _amount The total amount of collateral needed
   */
  function requestSwap(uint256 _amount, address _collateral) public emergencyStop {
    masterVault.executeSwap(_amount, _collateral);
  }

  /**
   * @notice Updates the individual token ID Loan Info struct in the brokerage contract
   * @param _tokenId The id of the portfolio to be updated
   */
  function handleLTV1Breached(uint256 _tokenId) external emergencyStop {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_tokenId);
    loanInfo.policyData.policyStatus = IBrokerage.PolicyStatus.LTV1;
    brokerage.updateLoanInfo(_tokenId, loanInfo);
  }

  //LTV2 breach functions

  /**
   * @notice Sends collateral to appropriate broker
   * @dev requests collateral from master vault to be forwarded to the individual lender
   * @param _lender The lender address
   * @param _amount How much to send to lender
   * @param _collateralAddress The address of the collateral being transferred
   */
  function moveCollateralToBroker(address _lender, uint256 _amount, address _collateralAddress, address _market) public emergencyStop {
    ERC20 token = ERC20(_collateralAddress);
    ILoanBroker lender = ILoanBroker(_lender);
    masterVault.sendCollateral(payable(address(this)), _amount, _collateralAddress);
    token.approve(address(_lender), _amount);
    lender.concreteSupplyCollateral(_collateralAddress, _amount, _market);
    emit CollateralToBroker(_amount, _collateralAddress, _market);
  }

  /**
   * @notice updates the brokerage contract to inform that a claim was made
   * @param _tokenId The individual portfolio token being updated
   * @param _claimToken The collateral type
   * @param _claimAmount The amount of the claim
   */
  function handleLTV2Breached(uint256 _tokenId, address _claimToken, uint256 _claimAmount, address _lender, address _market) external emergencyStop {
    moveCollateralToBroker(_lender, _claimAmount, _claimToken, _market);
    brokerage.initiateClaim(_tokenId, abi.encode(_claimToken, block.timestamp, _claimAmount));
  }

  /**
   * @notice Allows a user to repay a claim loan
   * @param _loanId the id of the loan with claim to be paid
   * @param _amountPaid How much is being paid on the claim
   */
  function repayClaim(uint256 _loanId, uint256 _amountPaid) external {
    brokerage.updateClaim(_loanId, _amountPaid);
  }

  /**
   * @notice Function that updates the borrow amount on a loan
   * @param _loanId The id of the loan being updated
   * @param _amount amount to add to loan
   */
  function addBorrowToLoan(uint256 _loanId, uint256 _amount) external emergencyStop {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    brokerage.addBorrowToLoan(_loanId, _amount);
    bool userBalance = reward.balance(loanInfo.portfolioId, 3);
    if (!userBalance) {
      reward.mint(3, loanInfo.portfolioId);
    } else {
      IRewardCollectionToken.Attribute memory attribute = IRewardCollectionToken.Attribute("numberIssued", "1");
      reward.updateAttribute(loanInfo.portfolioId, 1, IRewardCollectionToken.UpdateType.ADD, attribute);
    }

    loanInfo.currentLoanBalance += _amount;
    brokerage.updateLoanInfo(_loanId, loanInfo);
  }

  //Handle loan repayments and withdraw collateral
  /**
   * @notice allows users to repay their loan
   * @param _loanId The id number of the loan being updated
   * @param _amount How much is being paid towards the loan
   */
  function userRepayLoan(uint256 _loanId, uint256 _amount, uint256 _portfolioId) external emergencyStop {
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_loanId);
    if (loanInfo.policyData.claims.length > 0) {
      require(loanInfo.policyData.claims[loanInfo.policyData.claims.length - 1].claimBalance == 0, "ERR Cannot payoff loan with active claim");
    }
    bool userBalance = reward.balance(_portfolioId, 4);
    if (loanInfo.currentLoanBalance - _amount == 0) {
      brokerage.successfullyCloseLoan(_loanId);
      if (!userBalance) {
        reward.mint(4, _portfolioId);
      } else {
        IRewardCollectionToken.Attribute memory attribute = IRewardCollectionToken.Attribute("numberIssued", "1");
        reward.updateAttribute(_portfolioId, 1, IRewardCollectionToken.UpdateType.ADD, attribute);
      }
    } else {
      loanInfo.currentLoanBalance = loanInfo.currentLoanBalance - _amount;
      brokerage.updateLoanInfo(_loanId, loanInfo);
    }
  }

  /**
   * @notice Allows concrete to payoff a loan that they hold
   * @param _tokenId The id of the brokerage token
   */
  function concretePayoffLoan(uint256 _tokenId) external emergencyStop isCoreOrManager {
    IVault _liquidationVault = IVault(liquidationVault);
    IBrokerage.LoanInfo memory loanInfo = brokerage.getLoanInfoById(_tokenId);
    require(_liquidationVault.getIsLoanHeldInVault(_tokenId), "BaseLoanBroker: Loan not held by concrete");
    masterVault.sendDebtTokens(payable(address(this)), loanInfo.currentLoanBalance, loanInfo.debtTokenAddress);
    brokerage.successfullyCloseLoan(_tokenId);
  }

  /**
   * @notice Add function signature to the list of allowed signatures which can be called by the borrower via the lender broker contracts
   * @param _funcSig The function signature
   * @param _target The destination address for rule
   * @param _role Role of the tx initiator
   */
  function allowFunctionSignature(bytes4 _funcSig, address _target, bytes32 _role) external emergencyStop isCoreOrManager {
    roleAllowedSignatures[_role][_target][_funcSig] = true;
  }

  /**
   * @notice Add whitelisted target address which can be called by the borrower via the smart contract wallet without any restrictions
   * @param _target The destination address for rule
   */
  function addWhitelistedTargetAddresses(address _target) external emergencyStop isCoreOrManager {
    whitelistedTargetAddresses[_target] = true;
  }

  /**
   * @notice Get function signature from the list of allowed signatures which can be called by the borrower via the smart contract wallet
   * @param _funcSig The function signature
   * @param _target The destination address for rule
   * @param _role Role of the tx initiator
   */
  function isRoleAllowedSignature(bytes4 _funcSig, address _target, bytes32 _role) public view returns (bool) {
    return roleAllowedSignatures[_role][_target][_funcSig];
  }

  /**
   * @notice Get if target contract can be called by the borrower via the smart contract wallet
   * @param _target The destination address for rule
   */
  function isTargetContractWhitelisted(address _target) public view returns (bool) {
    return whitelistedTargetAddresses[_target];
  }

  /**
   * @notice the receive function is a standard solidity function needed inorder for this contract to receive ETH
   * @dev this fallback function is set to revert so that end users can't mistakenly send ETH to this contract
   */
  receive() external payable {
    revert();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {PortfolioBase} from "./PortfolioBase.sol";
import {IPortfolio} from "../interfaces/portfolio/IPortfolio.sol";
import {IRewardToken} from "../interfaces/rewardTokens/IRewardToken.sol";
import {IRewardCollectionToken} from "../interfaces/rewardTokens/IRewardCollectionToken.sol";
import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";

contract Portfolio is IPortfolio, PortfolioBase, ACLUser, ERC721HolderUpgradeable, ERC1155ReceiverUpgradeable, ERC1155HolderUpgradeable, EmergencyModifier {
  ///Time period of mandatory cooldown period for a transfer
  uint256 public cooldownPeriod;
  /// The urlbase, used for metadata related to portfolio
  string public urlBase;

  address public coreAddress;

  /// Maps a portfolio ID to an array of transfer requests
  mapping(uint256 => TransferRequest[]) public portfolioIdToTransferRequests;
  /// Maps a portfolio ID to an array of policy id's
  mapping(uint256 => uint256[]) public portfolioIdToLoanIds;

  mapping(uint256 => IRewardToken.Reward[]) public portfolioIdToRewardTokens;

  mapping(uint256 => IRewardCollectionToken.Reward[]) public portfolioIdToRewardCollectionTokens;

  function initialize(string memory urlBase_, address aclAddress_, address _emsAddress) public initializer {
    cooldownPeriod = 7 days;
    urlBase = urlBase_;
    __ERC1155Receiver_init();
    __ERC721Holder_init();
    __ERC721_init("Concrete Portfolio", "CPORT");
    aclContract = ACL(aclAddress_);
    emsContract = EmergencyStop(_emsAddress);
  }

  //Variable Updaters
  /**
   * @notice updateUrlBase used to update the base URL used to point at metadata
   * @param newUrlBase_ New URL to be used
   * @dev Access Controlled
   */
  function updateUrlBase(string memory newUrlBase_) external emergencyStop isCoreOrManager {
    urlBase = newUrlBase_;
  }

  /**
   * @notice updateCooldownPeriod used to updated the time requirement for a transfer
   * @param time_ The new time to be used for the cooldown period
   * @dev Access Controlled
   */
  function updateCooldownPeriod(uint256 time_) external emergencyStop isCoreOrManager {
    cooldownPeriod = time_;
  }

  //MINTING
  /**
   * @notice authorizedMint used to allow admin to mint portfolio
   * @param to_ The address portfolio to be minted to
   * @return tokenId of newly minted portfolio
   * @dev Access Controlled
   */
  function authorizedMint(address to_) external emergencyStop onlyCore returns (uint256) {
    require(balanceOf(to_) == 0, "PORTFOLIO: User already has a portfolio");
    _safeMint(to_);
    emit PortfolioMinted(to_, addressToId[to_]);
    return addressToId[to_];
  }

  /**
   * @notice authorizedBatchMint used to allow admin to batch mint portfolios
   * @param recipients_ An array of addresses to mint portfolios to
   * @dev Access Controlled
   */
  function authorizedBatchMint(address[] memory recipients_) external emergencyStop onlyCore {
    for (uint256 i = 0; i < recipients_.length; i++) {
      require(balanceOf(recipients_[i]) == 0, "PORTFOLIO: User already has a portfolio");
      _safeMint(recipients_[i]);
      emit PortfolioMinted(recipients_[i], addressToId[recipients_[i]]);
    }
  }

  //TRANSFERS
  /**
   * @notice initializeTransfer allows user to initiate a transfer request
   * @param tokenId_ The token ID of the portfolio to be transferred
   * @param to_ The address portfolio to be transferred to
   * @dev Requires requestor to be the portfolio owner
   */
  function initializeTransfer(uint256 tokenId_, address to_) external {
    require(_msgSender() == ownerOf(tokenId_), "PORTFOLIO: Caller not owner");
    TransferRequest memory request = TransferRequest({
      requestId: block.number,
      from: _msgSender(),
      to: to_,
      tokenId: tokenId_,
      timestamp: block.timestamp,
      cooldownComplete: block.timestamp + cooldownPeriod,
      executed: false
    });
    portfolioIdToTransferRequests[tokenId_].push(request);
    emit TransferRequested(tokenId_, request);
  }

  /**
   * @notice adminInitTransfer Allows an admin to initiate a portfolio transfer to new address
   * @param tokenId_ the id of the portfolio being transferred
   * @param from_ Address portfolio is being transferred from
   * @param to_ The address portfolio is being sent to
   * @dev Access Controlled
   */
  function adminInitTransfer(uint256 tokenId_, address from_, address to_) external emergencyStop isCoreOrManager {
    TransferRequest memory request = TransferRequest({
      requestId: block.number,
      from: from_,
      to: to_,
      tokenId: tokenId_,
      timestamp: block.timestamp,
      cooldownComplete: block.timestamp + cooldownPeriod,
      executed: false
    });
    portfolioIdToTransferRequests[tokenId_].push(request);
    emit TransferRequested(tokenId_, request);
  }

  /**
   * @notice finalizeTransfer Allows portfolio owner to request transfer being finalized
   * @param tokenId_ The id of the token being transferred
   * @dev All criteria for transfer must be met (including cooldown complete)
   * @dev Caller must be portfolio owner
   */
  function finalizeTransfer(uint256 tokenId_) external emergencyStop {
    require(_msgSender() == ownerOf(tokenId_), "PORTFOLIO: Caller not owner");
    TransferRequest storage request = portfolioIdToTransferRequests[tokenId_][portfolioIdToTransferRequests[tokenId_].length - 1];
    require(request.cooldownComplete <= block.timestamp, "Cooldown not complete");
    require(request.executed != true, "PORTFOLIO: Transfer already executed");
    _transferFrom(_msgSender(), request.to, request.tokenId);
    request.executed = true;
    emit TransferExecuted(tokenId_, request);
  }

  /**
   * @notice Allows an admin to finalize a transfer that was already instantiated
   * @param tokenId_ The id of the token being transfered
   * @dev Access Controlled
   * @dev Can only be used to finalize a transfer that meets all transfer requirements
   */
  function adminFinalizeTransfer(uint256 tokenId_) external emergencyStop isCoreOrManager {
    TransferRequest storage request = portfolioIdToTransferRequests[tokenId_][portfolioIdToTransferRequests[tokenId_].length - 1];
    require(request.cooldownComplete <= block.timestamp, "Cooldown not complete");
    require(request.executed != true, "PORTFOLIO: Transfer already executed");
    _transferFrom(request.from, request.to, request.tokenId);
    request.executed = true;
    emit TransferExecuted(tokenId_, request);
  }

  /**
   * @notice forceTransfer is used to allow admin to force transfer a portfolio
   * @notice Useful to reverse a malicious transfer
   * @notice Useful to speed up transfer process in the case of comprimised account keys, etc.
   * @param tokenId_ The id of the portfolio to be transferred
   * @param to_ The address of the portfolio is to be sent to
   * @dev Access Controlled
   */
  function forceTransfer(uint256 tokenId_, address to_) external emergencyStop isCoreOrManager {
    address from = idToAddress[tokenId_];
    TransferRequest storage request;
    if (portfolioIdToTransferRequests[tokenId_].length > 0) {
      request = portfolioIdToTransferRequests[tokenId_][portfolioIdToTransferRequests[tokenId_].length - 1];
      request.executed = true;
    }
    _transferFrom(from, to_, tokenId_);

    emit ForceTransfer(tokenId_, to_);
  }

  //BURN
  /**
   * @notice burn allows admin to burn a portfolio
   * @notice useful to burn portfolio of malicious actor
   * @param tokenId_ The id of the portfolio to be burned
   * @dev Access Controlled
   */
  function burn(uint256 tokenId_) external emergencyStop isCoreOrManager {
    _burn(tokenId_);
    emit PortfolioBurned(tokenId_, block.timestamp);
  }

  /**
   * @notice Function is mandatory override for ERC721 Receiver
   * @notice takes the data input and registers the loan ID in mapping
   */
  function onERC721Received(address, address, uint256, bytes memory data) public override returns (bytes4) {
    (uint256 portfolioId, address _contractAddress, string memory _name, string memory _symbol, uint256 _tokenId, bool loanToken) = abi.decode(data, (uint256, address, string, string, uint256, bool));
    if (loanToken) {
      portfolioIdToLoanIds[portfolioId].push(_tokenId);
      emit PolicyAdded(portfolioId, _tokenId);
    } else {
      IRewardToken.Reward memory reward = IRewardToken.Reward({contractAddress: _contractAddress, name: _name, symbol: _symbol, tokenId: _tokenId});
      portfolioIdToRewardTokens[portfolioId].push(reward);
    }
    return this.onERC721Received.selector;
  }

  /**
   * @notice Function is mandatory override for ERC1155 Receiver
   * @notice Takes set params and adds the token ID of the policy to the portfolio
   * @param data This data is decoded to be the portfolioId the policy is assigned to
   * @dev The remainder of the params are required for the function sig, but not utilized
   */
  function onERC1155Received(address, address, uint256, uint256, bytes memory data) public override(ERC1155HolderUpgradeable, IERC1155ReceiverUpgradeable) returns (bytes4) {
    (uint256 portfolioId_, address _contractAddress, uint256 _tokenId, string memory _name) = abi.decode(data, (uint256, address, uint256, string));
    IRewardCollectionToken.Reward memory reward = IRewardCollectionToken.Reward({contractAddress: _contractAddress, tokenId: _tokenId, name: _name});
    portfolioIdToRewardCollectionTokens[portfolioId_].push(reward);
    return this.onERC1155Received.selector;
  }

  ///@dev Params not utilized, Function not implemented
  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure override(ERC1155HolderUpgradeable, IERC1155ReceiverUpgradeable) returns (bytes4) {
    revert("Not Implemented");
  }

  //GETTERS

  function getRewardTokensForPortfolio(uint256 portfolioId_) public view returns (IRewardToken.Reward[] memory) {
    return portfolioIdToRewardTokens[portfolioId_];
  }

  function getRewardCollectionTokensForPortfolio(uint256 portfolioId_) public view returns (IRewardCollectionToken.Reward[] memory) {
    return portfolioIdToRewardCollectionTokens[portfolioId_];
  }

  /**
   * @notice Returns an array of policy ID's for a give portfolio ID
   * @param portfolioId_ The portfolio ID being looked up
   */
  function getLoanIdsForPortfolio(uint256 portfolioId_) public view returns (uint256[] memory) {
    return portfolioIdToLoanIds[portfolioId_];
  }

  /**
   * @notice required function to be able to display metadata on marketplaces
   * @param tokenId_ The token ID being looked up
   * @return string representation of URL
   */
  function tokenURI(uint256 tokenId_) public view override(ERC721Upgradeable, IPortfolio) returns (string memory) {
    require(_exists(tokenId_), "PORTFOLIO: Token ID does not exist");
    return string(abi.encodePacked(urlBase, StringsUpgradeable.toString(tokenId_)));
  }

  /**
   * @notice getTransferRequests allows lookup of all transfer request history for a given portfolio
   * @param tokenId_ The id of the portfolio being looked up
   */
  function getTransferRequests(uint256 tokenId_) external view returns (TransferRequest[] memory) {
    return portfolioIdToTransferRequests[tokenId_];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC1155ReceiverUpgradeable, PortfolioBase) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  ///@dev Override, Function not implemented
  function approve(address, uint256) public pure override(IERC721Upgradeable, ERC721Upgradeable) {
    revert("Approve Portfolio not implemented");
  }

  ///@dev Override Function not implemented
  function setApprovalForAll(address, bool) public pure override(IERC721Upgradeable, ERC721Upgradeable) {
    revert("PORTFOLIO: setApprovalForAll not implemented");
  }

  ///@dev Override Function not implemented
  function safeTransferFrom(address, address, uint256) public pure override(IERC721Upgradeable, ERC721Upgradeable, IPortfolio) {
    revert("PORTFOLIO: safeTransferFrom not implemented");
  }

  ///@dev Override Function not implemented
  function safeTransferFrom(address, address, uint256, bytes memory) public pure override(IERC721Upgradeable, ERC721Upgradeable, IPortfolio) {
    revert("PORTFOLIO: safeTransferFrom not implemented");
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract PortfolioBase is ERC165Upgradeable, IERC721Upgradeable, ERC721Upgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  CountersUpgradeable.Counter numberTokens;
  CountersUpgradeable.Counter tokenId;

  //Mapping to associate user address to token ID
  mapping(address => uint256) public addressToId;
  //Mapping to reverse associate token ID to user address
  mapping(uint256 => address) public idToAddress;

  //Internal Functions
  /**
   * @notice _burn function used by admin to burn a bad actors portfolio
   * @param id_ The id of the portfolio to be burned
   */
  function _burn(uint256 id_) internal override {
    address from = ownerOf(id_);
    numberTokens.decrement();
    delete idToAddress[id_];
    delete addressToId[from];
    emit Transfer(from, address(0x0), id_);
  }

  /**
   * @notice _safeMint function used to mint a new portfolio
   * @param to_ The address of the user receiving portfolio
   * @return id of newly minted portfolio
   */
  function _safeMint(address to_) internal returns (uint256) {
    require(to_ != address(0x0), "PORTFOLIO: Cannot mint to zero address");
    tokenId.increment();
    numberTokens.increment();
    _transferFrom(address(0x0), to_, tokenId.current());
    return tokenId.current();
  }

  /**
   * @notice _transferFrom used to transfer portfolio to new address.
   * @dev Must be used in accordance with strict transfer rules
   * @param from_ address portfolio is being transfered from
   * @param to_ Address portfolio to be transferred to
   * @param id_ The token ID for the portfolio being transfered
   */
  function _transferFrom(address from_, address to_, uint256 id_) internal {
    addressToId[from_] = 0x0;
    idToAddress[id_] = to_;
    addressToId[to_] = id_;
    emit Transfer(from_, to_, id_);
  }

  //GETTERS

  function getTokenIdForUser(address user_) public view returns (uint256) {
    return addressToId[user_];
  }

  /**
   * @notice _exists used to check the existance of a portfolio
   * @param id_ The id of the portfolio token being checked
   * @return bool (true if exists, false if not)
   */
  function _exists(uint256 id_) internal view override returns (bool) {
    return idToAddress[id_] != address(0x0);
  }

  ///Returns the current token ID
  function currentTokenId() public view returns (uint256) {
    return tokenId.current();
  }

  ///Returns the total number of portfolios in circulation
  function totalSupply() public view returns (uint256) {
    return numberTokens.current();
  }

  //Mandatory Overrides
  /**
   * @dev the following functions override ERC721 and IERC721 functions
   */
  function balanceOf(address user_) public view override(IERC721Upgradeable, ERC721Upgradeable) returns (uint256) {
    if (addressToId[user_] != 0) {
      return 1;
    } else {
      return 0;
    }
  }

  /**
   * @notice Allows getting an owner of a specific address
   * @param id_ The token ID being looked up
   * @dev overrides underlying ERC721
   */
  function ownerOf(uint256 id_) public view override(IERC721Upgradeable, ERC721Upgradeable) returns (address) {
    require(idToAddress[id_] != address(0x0), "PORTFOLIO: Portfolio does not exist");
    return idToAddress[id_];
  }

  /**
   * @notice Function here to act as override for underlying ERC721
   * @return zero address (function not implemented)
   * @dev ALWAYS returns a zero address
   */
  function getApproved(uint256) public pure override(IERC721Upgradeable, ERC721Upgradeable) returns (address) {
    return address(0x0);
  }

  /**
   * @notice override function not implemented in this contract
   * @dev overrides underlying ERC721
   */
  function isApprovedForAll(address, address) public pure override(IERC721Upgradeable, ERC721Upgradeable) returns (bool) {
    return false;
  }

  function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC165Upgradeable, IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
    return ERC165Upgradeable.supportsInterface(interfaceId_) || interfaceId_ == type(IERC721Upgradeable).interfaceId;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";

import {IRewardToken} from "../interfaces/rewardTokens/IRewardToken.sol";
import {MetadataGenerator} from "../libraries/MetadataGenerator.sol";

contract RewardToken is Initializable, IRewardToken, ACLUser, ERC721Upgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;

  ///@notice internal token Id Counter
  CountersUpgradeable.Counter private _tokenID;

  ///@notice address of portfolio contract (for tokens to be minted to)
  address public portfolioAddress;

  ///@notice The name of the reward token
  string public rewardName;

  ///@notice The reward token symbol
  string public rewardSymbol;

  ///@notice Maps reward token Id's to portfolio Id's
  mapping(uint256 => uint256) public rewardTokenToPortfolioId;

  ///@notice Maps token Id's to assigned attributes
  mapping(uint256 => Attribute[]) public tokenIdToAttributes;

  ///@notice Maps token Id's to assigned metadata values
  mapping(uint256 => Metadata) public tokenIdToMetadata;

  /**
   * @notice Standard Initializer
   * @param _name The name of the reward token
   * @param _symbol The symbol of the reward token
   * @param _aclAddress The address of the ACL contract
   * @param _portfolioAddress The address of the portfolio contract
   * @dev Assigns all pertinent values and initializes the ERC721
   */
  function initialize(string memory _name, string memory _symbol, address _aclAddress, address _portfolioAddress) public initializer {
    __ERC721_init(_name, _symbol);
    aclContract = ACL(_aclAddress);
    portfolioAddress = _portfolioAddress;
  }

  /**
   * @notice Function that allows minting of the reward tokens to a given portfolio ID
   * @dev Access Controlled
   * @dev This function will ALWAYS mint to the portfolio address, where the token is assigned to a given
   * portfolio ID
   * @param _portfolioId The portfolio ID of the recipient
   * @param _baseMetadata the baseline metadata for this reward
   * @param baseAttributes_ The baseline attributes for this reward
   */
  function mint(
    uint256 _portfolioId,
    string memory _rewardName,
    string memory _rewardSymbol,
    Metadata calldata _baseMetadata,
    Attribute[] calldata baseAttributes_
  ) external isCoreOrManagerOrBaseLoan returns (uint256) {
    _tokenID.increment();
    uint256 tokenId = _tokenID.current();
    bytes memory data = abi.encode(_portfolioId, address(this), _rewardName, _rewardSymbol, tokenId);
    _safeMint(portfolioAddress, tokenId, data);
    for (uint256 i = 0; i < baseAttributes_.length; i++) {
      tokenIdToAttributes[tokenId].push(baseAttributes_[i]);
    }
    tokenIdToMetadata[tokenId] = _baseMetadata;
    rewardTokenToPortfolioId[tokenId] = _portfolioId;
    return tokenId;
  }

  // Metadata memory metadata = abi.decode(_baseMetadata, (Metadata));
  /**
   * @notice Function that allows a tokens metadata to be completely replaced
   * @param _tokenId The token ID that is to be modified
   * @param _metadata The new metadata to be assigned to the token
   * @dev Requires the name and image values to not be empty
   */
  function replaceMetadata(uint256 _tokenId, Metadata memory _metadata) external isCoreOrManager {
    require(bytes(_metadata.name).length != 0 && bytes(_metadata.image).length != 0, "RewardToken: Cannot update with no name or image");
    tokenIdToMetadata[_tokenId] = _metadata;
  }

  /**
   * @notice Function that allows ALL attributes of a token to be replaced
   * @param _tokenId The token ID to be modified
   * @param _attributes The new attributes to be assigned to the token
   * @dev This will replace ALL attributes assigned to a token
   * @dev Access Controlled
   */
  function replaceAttributes(uint256 _tokenId, Attribute[] memory _attributes) external isCoreOrManager {
    require(_attributes.length > 0, "RewardToken: Cannot update with empty attribute array");
    delete tokenIdToAttributes[_tokenId];
    for (uint256 i = 0; i < _attributes.length; i++) {
      tokenIdToAttributes[_tokenId].push(_attributes[i]);
    }
  }

  /**
   * @notice Allows a tokens metadata fields to be independently modified
   * @param _tokenId The id of the token being modified
   * @param _updateField The field that is to be updated (See enum in IRewardToken)
   * @param _value The new metadata value to be inserted
   * @dev Access Controlled
   */
  function updateMetadataValue(uint256 _tokenId, UpdateField _updateField, string memory _value) external isCoreOrManager {
    Metadata storage metadata = tokenIdToMetadata[_tokenId];
    if (_updateField == UpdateField.IMAGE) {
      metadata.image = _value;
      return;
    }
    if (_updateField == UpdateField.DESCRIPTION) {
      metadata.description = _value;
      return;
    }
    if (_updateField == UpdateField.THUMB) {
      metadata.thumb = _value;
      return;
    }
    if (_updateField == UpdateField.EXTERNAL_URL) {
      metadata.external_url = _value;
      return;
    }
    if (_updateField == UpdateField.ANIMATION_URL) {
      metadata.animation_url = _value;
      return;
    }
    tokenIdToMetadata[_tokenId] = metadata;
    return;
  }

  /**
   * @notice Allows a particular tokens attributes to be modified
   * @notice can add, remove or replace an attribute
   * @param _tokenId The token being modified
   * @param _updateType The type of update being performed (see UpdateType in IRewardToken)
   * @param _attribute The attribute values being updated
   * @dev Access Controlled
   */
  function updateAttribute(uint256 _tokenId, UpdateType _updateType, Attribute memory _attribute) external isCoreOrManager {
    Attribute[] storage attributes = tokenIdToAttributes[_tokenId];
    if (_updateType == UpdateType.ADD) {
      return _addAttribute(_tokenId, attributes, _attribute);
    }
    if (_updateType == UpdateType.REMOVE) {
      return _removeAttribute(_tokenId, attributes, _attribute);
    }
    if (_updateType == UpdateType.REPLACE) {
      return _replaceAttribute(_tokenId, attributes, _attribute);
    }
  }

  /**
   * @notice Required function that returns market readable metadata
   * @param _tokenId The id of the token being looked up
   * @dev Typically this will point to a URL, however in this case it points to a library that that builds a readable metadata
   */
  function tokenURI(uint256 _tokenId) public view override(IRewardToken, ERC721Upgradeable) returns (string memory) {
    Metadata storage metadata = tokenIdToMetadata[_tokenId];
    Attribute[] storage attributes = tokenIdToAttributes[_tokenId];
    return MetadataGenerator.generateMetadata(_tokenId, metadata, attributes);
  }

  /**
   * @notice Function to return all of a given tokens attributes
   * @param _tokenId The token ID being looked up
   */
  function getAllTokenAttributes(uint256 _tokenId) public view returns (Attribute[] memory) {
    return tokenIdToAttributes[_tokenId];
  }

  /**
   * @notice Helper function that replaces a given attribute assigned to a token
   * @dev Looks up matching attribute and replaces the value
   * @param _tokenId The ID of the token being modified
   * @param _attributes An array of existing attributes already assigned to token
   * @param _replacement The replacement attribute
   * @dev NOTE: The replacement attribute MUST have an already existing trait_type
   */
  function _replaceAttribute(uint256 _tokenId, Attribute[] storage _attributes, Attribute memory _replacement) internal {
    for (uint256 i = 0; i < _attributes.length; i++) {
      if (_compareStrings(_attributes[i].trait_type, _replacement.trait_type)) {
        _attributes[i].value = _replacement.value;
      }
    }
    tokenIdToAttributes[_tokenId] = _attributes;
  }

  /**
   * @notice Function that removes a given attribute from attribute array of a token
   * @param _tokenId The token ID of the token being modified
   * @param _attributes The array of attributes already assigned to the token
   * @param _toBeRemoved The attribute to be removed
   * @dev Modifies array length
   * @dev _toBeRemoved MUST match existing trait_type on token
   */
  function _removeAttribute(uint256 _tokenId, Attribute[] storage _attributes, Attribute memory _toBeRemoved) internal {
    for (uint256 i = 0; i < _attributes.length; i++) {
      if (bytes(_attributes[i].trait_type).length == bytes(_toBeRemoved.trait_type).length) {
        if (_compareStrings(_attributes[i].trait_type, _toBeRemoved.trait_type)) {
          _attributes[i] = _attributes[_attributes.length - 1];
          _attributes.pop();
        }
      }
    }
    tokenIdToAttributes[_tokenId] = _attributes;
  }

  /**
   * @notice Helper function that adds an attribute to the attribute array of a token
   * @param _tokenId The token ID of the token being modified
   * @param _attributes the already assigned attributes for a token
   * @param _newAttribute The new attribute to be added to array
   */
  function _addAttribute(uint256 _tokenId, Attribute[] storage _attributes, Attribute memory _newAttribute) internal {
    _attributes.push(_newAttribute);
    tokenIdToAttributes[_tokenId] = _attributes;
  }

  /**
   * @notice Helper function to compare two strings
   * @param a The first string
   * @param b The second string
   * @return bool Whether or not the input strings are equivalent
   */
  function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

  /**
   * @notice Override function that prevents tokens from being transferred
   * @dev Overrides OpenZeppelin ERC721 transfer functions
   */
  function _beforeTokenTransfer(address from, address to, uint256, uint256) internal virtual override {
    require(from == address(0) || to == address(0), "Non-Transferrable Token");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract FractionalPower {
  uint256 constant MAX_VAL = type(uint256).max;

  uint8 internal constant MIN_PRECISION = 32;
  uint8 internal constant MAX_PRECISION = 127;

  uint256 internal constant FIXED_1 = 1 << MAX_PRECISION;
  uint256 internal constant FIXED_2 = 2 << MAX_PRECISION;

  // Auto-generated via 'PrintLn2ScalingFactors.py'
  uint256 internal constant LN2_NUMERATOR = 0x3f80fe03f80fe03f80fe03f80fe03f8;
  uint256 internal constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

  // Auto-generated via 'PrintOptimalThresholds.py'
  uint256 internal constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e4;
  uint256 internal constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

  uint256[MAX_PRECISION + 1] private maxExpArray;

  // /**
  //   * @dev Should be executed either during construction or after construction (if too large for the constructor)
  // */
  // function initExponentialCache() public virtual {
  //   initMaxExpArray();
  // }

  /**
   * @dev Compute (a / b) ^ (c / d)
   */
  function pow(uint256 a, uint256 b, uint256 c, uint256 d) public view returns (uint256, uint256) {
    unchecked {
      if (a >= b) return mulDivExp(mulDivLog(FIXED_1, a, b), c, d);
      (uint256 q, uint256 p) = mulDivExp(mulDivLog(FIXED_1, b, a), c, d);
      return (p, q);
    }
  }

  /**
   * @dev Compute log(x / FIXED_1) * FIXED_1
   */
  function fixedLog(uint256 x) internal pure returns (uint256) {
    unchecked {
      if (x < OPT_LOG_MAX_VAL) {
        return optimalLog(x);
      } else {
        return generalLog(x);
      }
    }
  }

  /**
   * @dev Compute e ^ (x / FIXED_1) * FIXED_1
   */
  function fixedExp(uint256 x) internal view returns (uint256, uint256) {
    unchecked {
      if (x < OPT_EXP_MAX_VAL) {
        return (optimalExp(x), 1 << MAX_PRECISION);
      } else {
        uint8 precision = findPosition(x);
        return (generalExp(x >> (MAX_PRECISION - precision), precision), 1 << precision);
      }
    }
  }

  /**
   * @dev Compute log(x / FIXED_1) * FIXED_1
   * This functions assumes that x >= FIXED_1, because the output would be negative otherwise
   */
  function generalLog(uint256 x) internal pure returns (uint256) {
    unchecked {
      uint256 res = 0;

      // if x >= 2, then we compute the integer part of log2(x), which is larger than 0
      if (x >= FIXED_2) {
        uint8 count = floorLog2(x / FIXED_1);
        x >>= count; // now x < 2
        res = count * FIXED_1;
      }

      // if x > 1, then we compute the fraction part of log2(x), which is larger than 0
      if (x > FIXED_1) {
        for (uint8 i = MAX_PRECISION; i > 0; --i) {
          x = (x * x) / FIXED_1; // now 1 < x < 4
          if (x >= FIXED_2) {
            x >>= 1; // now 1 < x < 2
            res += 1 << (i - 1);
          }
        }
      }

      return (res * LN2_NUMERATOR) / LN2_DENOMINATOR;
    }
  }

  /**
   * @dev Approximate e ^ x as (x ^ 0) / 0! + (x ^ 1) / 1! + ... + (x ^ n) / n!
   * Auto-generated via 'PrintFunctionGeneralExp.py'
   * Detailed description:
   * - This function returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy
   * - The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1"
   * - The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)"
   */
  function generalExp(uint256 x, uint8 precision) internal pure returns (uint256) {
    unchecked {
      uint256 xi = x;
      uint256 res = 0;

      xi = (xi * x) >> precision;
      res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
      xi = (xi * x) >> precision;
      res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
      xi = (xi * x) >> precision;
      res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
      xi = (xi * x) >> precision;
      res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
      xi = (xi * x) >> precision;
      res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
      xi = (xi * x) >> precision;
      res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
      xi = (xi * x) >> precision;
      res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
      xi = (xi * x) >> precision;
      res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
      xi = (xi * x) >> precision;
      res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
      xi = (xi * x) >> precision;
      res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
      xi = (xi * x) >> precision;
      res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
      xi = (xi * x) >> precision;
      res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
      xi = (xi * x) >> precision;
      res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
      xi = (xi * x) >> precision;
      res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
      xi = (xi * x) >> precision;
      res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

      return res / 0x688589cc0e9505e2f2fee5580000000 + x + (1 << precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }
  }

  /**
   * @dev Compute log(x / FIXED_1) * FIXED_1
   * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
   * Auto-generated via 'PrintFunctionOptimalLog.py'
   * Detailed description:
   * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
   * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
   * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
   * - The natural logarithm of the input is calculated by summing up the intermediate results above
   * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
   */
  function optimalLog(uint256 x) internal pure returns (uint256) {
    unchecked {
      uint256 res = 0;

      uint256 y;
      uint256 z;
      uint256 w;

      if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd9) {
        res += 0x40000000000000000000000000000000;
        x = (x * FIXED_1) / 0xd3094c70f034de4b96ff7d5b6f99fcd9;
      } // add 1 / 2^1
      if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a8) {
        res += 0x20000000000000000000000000000000;
        x = (x * FIXED_1) / 0xa45af1e1f40c333b3de1db4dd55f29a8;
      } // add 1 / 2^2
      if (x >= 0x910b022db7ae67ce76b441c27035c6a2) {
        res += 0x10000000000000000000000000000000;
        x = (x * FIXED_1) / 0x910b022db7ae67ce76b441c27035c6a2;
      } // add 1 / 2^3
      if (x >= 0x88415abbe9a76bead8d00cf112e4d4a9) {
        res += 0x08000000000000000000000000000000;
        x = (x * FIXED_1) / 0x88415abbe9a76bead8d00cf112e4d4a9;
      } // add 1 / 2^4
      if (x >= 0x84102b00893f64c705e841d5d4064bd4) {
        res += 0x04000000000000000000000000000000;
        x = (x * FIXED_1) / 0x84102b00893f64c705e841d5d4064bd4;
      } // add 1 / 2^5
      if (x >= 0x8204055aaef1c8bd5c3259f4822735a3) {
        res += 0x02000000000000000000000000000000;
        x = (x * FIXED_1) / 0x8204055aaef1c8bd5c3259f4822735a3;
      } // add 1 / 2^6
      if (x >= 0x810100ab00222d861931c15e39b44e9a) {
        res += 0x01000000000000000000000000000000;
        x = (x * FIXED_1) / 0x810100ab00222d861931c15e39b44e9a;
      } // add 1 / 2^7
      if (x >= 0x808040155aabbbe9451521693554f734) {
        res += 0x00800000000000000000000000000000;
        x = (x * FIXED_1) / 0x808040155aabbbe9451521693554f734;
      } // add 1 / 2^8

      z = y = x - FIXED_1;
      w = (y * y) / FIXED_1;
      res += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
      res += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
      res += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
      res += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
      res += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
      res += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
      res += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
      z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
      res += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16

      return res;
    }
  }

  /**
   * @dev Compute e ^ (x / FIXED_1) * FIXED_1
   * Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
   * Auto-generated via 'PrintFunctionOptimalExp.py'
   * Detailed description:
   * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
   * - The exponentiation of each binary exponent is given (pre-calculated)
   * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
   * - The exponentiation of the input is calculated by multiplying the intermediate results above
   * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
   */
  //slither-disable-start weak-prng
  function optimalExp(uint256 x) internal pure returns (uint256) {
    unchecked {
      uint256 res = 0;

      uint256 y;
      uint256 z;

      z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
      z = (z * y) / FIXED_1;
      res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
      z = (z * y) / FIXED_1;
      res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
      z = (z * y) / FIXED_1;
      res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
      z = (z * y) / FIXED_1;
      res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
      z = (z * y) / FIXED_1;
      res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
      z = (z * y) / FIXED_1;
      res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
      z = (z * y) / FIXED_1;
      res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
      z = (z * y) / FIXED_1;
      res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
      z = (z * y) / FIXED_1;
      res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
      z = (z * y) / FIXED_1;
      res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
      z = (z * y) / FIXED_1;
      res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
      res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

      if ((x & 0x010000000000000000000000000000000) != 0) res = (res * 0x1c3d6a24ed82218787d624d3e5eba95f9) / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
      if ((x & 0x020000000000000000000000000000000) != 0) res = (res * 0x18ebef9eac820ae8682b9793ac6d1e778) / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
      if ((x & 0x040000000000000000000000000000000) != 0) res = (res * 0x1368b2fc6f9609fe7aceb46aa619baed5) / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
      if ((x & 0x080000000000000000000000000000000) != 0) res = (res * 0x0bc5ab1b16779be3575bd8f0520a9f21e) / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
      if ((x & 0x100000000000000000000000000000000) != 0) res = (res * 0x0454aaa8efe072e7f6ddbab84b40a55c5) / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
      if ((x & 0x200000000000000000000000000000000) != 0) res = (res * 0x00960aadc109e7a3bf4578099615711d7) / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
      if ((x & 0x400000000000000000000000000000000) != 0) res = (res * 0x0002bf84208204f5977f9a8cf01fdc307) / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

      return res;
    }
  }

  //slither-disable-end weak-prng

  /**
   * @dev The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
   * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
   * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
   * This function supports the rational approximation of "(a / b) ^ (c / d)" via "e ^ (log(a / b) * c / d)".
   * The value of "log(a / b)" is represented with an integer slightly smaller than "log(a / b) * 2 ^ precision".
   * The larger "precision" is, the more accurately this value represents the real value.
   * However, the larger "precision" is, the more bits are required in order to store this value.
   * And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (a maximum value of "x").
   * This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
   * Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
   * This allows us to compute the result with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
   */
  function findPosition(uint256 x) internal view returns (uint8) {
    unchecked {
      uint8 lo = MIN_PRECISION;
      uint8 hi = MAX_PRECISION;

      while (lo + 1 < hi) {
        uint8 mid = (lo + hi) / 2;
        if (maxExpArray[mid] >= x) lo = mid;
        else hi = mid;
      }

      if (maxExpArray[hi] >= x) return hi;
      if (maxExpArray[lo] >= x) return lo;

      revert("findPosition: x > max");
    }
  }

  /**
   * @dev Initialize internal data structure
   * Auto-generated via 'PrintMaxExpArray.py'
   */
  function initExponentialCache() internal {
    //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
    //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
    //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
    //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
    //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
    //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
    //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
    //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
    //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
    //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
    //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
    //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
    //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
    //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
    //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
    //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
    //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
    //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
    //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
    //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
    //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
    //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
    //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
    //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
    //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
    //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
    //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
    //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
    //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
    //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
    //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
    //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
    maxExpArray[32] = 0x1c35fedd14ffffffffffffffffffffffff;
    maxExpArray[33] = 0x1b0ce43b323fffffffffffffffffffffff;
    maxExpArray[34] = 0x19f0028ec1ffffffffffffffffffffffff;
    maxExpArray[35] = 0x18ded91f0e7fffffffffffffffffffffff;
    maxExpArray[36] = 0x17d8ec7f0417ffffffffffffffffffffff;
    maxExpArray[37] = 0x16ddc6556cdbffffffffffffffffffffff;
    maxExpArray[38] = 0x15ecf52776a1ffffffffffffffffffffff;
    maxExpArray[39] = 0x15060c256cb2ffffffffffffffffffffff;
    maxExpArray[40] = 0x1428a2f98d72ffffffffffffffffffffff;
    maxExpArray[41] = 0x13545598e5c23fffffffffffffffffffff;
    maxExpArray[42] = 0x1288c4161ce1dfffffffffffffffffffff;
    maxExpArray[43] = 0x11c592761c666fffffffffffffffffffff;
    maxExpArray[44] = 0x110a688680a757ffffffffffffffffffff;
    maxExpArray[45] = 0x1056f1b5bedf77ffffffffffffffffffff;
    maxExpArray[46] = 0x0faadceceeff8bffffffffffffffffffff;
    maxExpArray[47] = 0x0f05dc6b27edadffffffffffffffffffff;
    maxExpArray[48] = 0x0e67a5a25da4107fffffffffffffffffff;
    maxExpArray[49] = 0x0dcff115b14eedffffffffffffffffffff;
    maxExpArray[50] = 0x0d3e7a392431239fffffffffffffffffff;
    maxExpArray[51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
    maxExpArray[52] = 0x0c2d415c3db974afffffffffffffffffff;
    maxExpArray[53] = 0x0bad03e7d883f69bffffffffffffffffff;
    maxExpArray[54] = 0x0b320d03b2c343d5ffffffffffffffffff;
    maxExpArray[55] = 0x0abc25204e02828dffffffffffffffffff;
    maxExpArray[56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
    maxExpArray[57] = 0x09deaf736ac1f569ffffffffffffffffff;
    maxExpArray[58] = 0x0976bd9952c7aa957fffffffffffffffff;
    maxExpArray[59] = 0x09131271922eaa606fffffffffffffffff;
    maxExpArray[60] = 0x08b380f3558668c46fffffffffffffffff;
    maxExpArray[61] = 0x0857ddf0117efa215bffffffffffffffff;
    maxExpArray[62] = 0x07ffffffffffffffffffffffffffffffff;
    maxExpArray[63] = 0x07abbf6f6abb9d087fffffffffffffffff;
    maxExpArray[64] = 0x075af62cbac95f7dfa7fffffffffffffff;
    maxExpArray[65] = 0x070d7fb7452e187ac13fffffffffffffff;
    maxExpArray[66] = 0x06c3390ecc8af379295fffffffffffffff;
    maxExpArray[67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
    maxExpArray[68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
    maxExpArray[69] = 0x05f63b1fc104dbd39587ffffffffffffff;
    maxExpArray[70] = 0x05b771955b36e12f7235ffffffffffffff;
    maxExpArray[71] = 0x057b3d49dda84556d6f6ffffffffffffff;
    maxExpArray[72] = 0x054183095b2c8ececf30ffffffffffffff;
    maxExpArray[73] = 0x050a28be635ca2b888f77fffffffffffff;
    maxExpArray[74] = 0x04d5156639708c9db33c3fffffffffffff;
    maxExpArray[75] = 0x04a23105873875bd52dfdfffffffffffff;
    maxExpArray[76] = 0x0471649d87199aa990756fffffffffffff;
    maxExpArray[77] = 0x04429a21a029d4c1457cfbffffffffffff;
    maxExpArray[78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
    maxExpArray[79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
    maxExpArray[80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
    maxExpArray[81] = 0x0399e96897690418f785257fffffffffff;
    maxExpArray[82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
    maxExpArray[83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
    maxExpArray[84] = 0x032cbfd4a7adc790560b3337ffffffffff;
    maxExpArray[85] = 0x030b50570f6e5d2acca94613ffffffffff;
    maxExpArray[86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
    maxExpArray[87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
    maxExpArray[88] = 0x02af09481380a0a35cf1ba02ffffffffff;
    maxExpArray[89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
    maxExpArray[90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
    maxExpArray[91] = 0x025daf6654b1eaa55fd64df5efffffffff;
    maxExpArray[92] = 0x0244c49c648baa98192dce88b7ffffffff;
    maxExpArray[93] = 0x022ce03cd5619a311b2471268bffffffff;
    maxExpArray[94] = 0x0215f77c045fbe885654a44a0fffffffff;
    maxExpArray[95] = 0x01ffffffffffffffffffffffffffffffff;
    maxExpArray[96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
    maxExpArray[97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
    maxExpArray[98] = 0x01c35fedd14b861eb0443f7f133fffffff;
    maxExpArray[99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
    maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
    maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
    maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
    maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
    maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
    maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
    maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
    maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
    maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
    maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
    maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
    maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
    maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
    maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
    maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
    maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
    maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
    maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
    maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
    maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
    maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
    maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
    maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
    maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
    maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
    maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
    maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
    maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
  }

  // auxiliary function
  function mulDivLog(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
    return fixedLog(mulDivF(x, y, z));
  }

  // auxiliary function
  function mulDivExp(uint256 x, uint256 y, uint256 z) private view returns (uint256, uint256) {
    return fixedExp(mulDivF(x, y, z));
  }

  /**
   * @dev Compute the largest integer smaller than or equal to the binary logarithm of `n`
   */
  function floorLog2(uint256 n) internal pure returns (uint8) {
    unchecked {
      uint8 res = 0;

      if (n < 256) {
        // at most 8 iterations
        while (n > 1) {
          n >>= 1;
          res += 1;
        }
      } else {
        // exactly 8 iterations
        for (uint8 s = 128; s > 0; s >>= 1) {
          if (n >= 1 << s) {
            n >>= s;
            res |= s;
          }
        }
      }

      return res;
    }
  }

  /**
   * @dev Compute the largest integer smaller than or equal to `x * y / z`
   */
  function mulDivF(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
    unchecked {
      (uint256 xyh, uint256 xyl) = mul512(x, y);
      if (xyh == 0) {
        // `x * y < 2 ^ 256`
        return xyl / z;
      }
      if (xyh < z) {
        // `x * y / z < 2 ^ 256`
        uint256 m = mulmod(x, y, z); // `m = x * y % z`
        (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`
        if (nh == 0) {
          // `n < 2 ^ 256`
          return nl / z;
        }
        uint256 p = (0 - z) & z; // `p` is the largest power of 2 which `z` is divisible by
        uint256 q = div512(nh, nl, p); // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
        uint256 r = inv256(z / p); // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
        return q * r; // `q * r = (n / p) * inverse(z / p) = n / z`
      }
      revert(); // `x * y / z >= 2 ^ 256`
    }
  }

  /**
   * @dev Compute the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
   */
  function div512(uint256 xh, uint256 xl, uint256 pow2n) private pure returns (uint256) {
    uint256 mult;
    unchecked {
      uint256 pow2nInv = ((0 - pow2n) / pow2n) + 1; // `1 << (256 - n)`
      mult = xh * pow2nInv;
      return mult | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
    }
  }

  /**
   * @dev Compute the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
   */
  function inv256(uint256 d) private pure returns (uint256) {
    unchecked {
      // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
      uint256 x = 1;
      for (uint256 i = 0; i < 8; ++i) x = x * (2 - (x * d)); // `x = x * (2 - x * d) mod 2 ^ 256`
      return x;
    }
  }

  /**
   * @dev Compute the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
   */
  function sub512(uint256 xh, uint256 xl, uint256 y) private pure returns (uint256, uint256) {
    unchecked {
      if (xl >= y) return (xh, xl - y);
      return (xh - 1, xl - y);
    }
  }

  /**
   * @dev Compute the value of `x * y`
   */
  function mul512(uint256 x, uint256 y) private pure returns (uint256, uint256) {
    unchecked {
      uint256 p = mulmod(x, y, MAX_VAL);
      uint256 q = x * y;
      if (p >= q) return (p - q, q);
      return ((p - q) - 1, q);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FractionalPower} from "./FractionalPower.sol";

contract VaultCurve is FractionalPower {
  uint24 internal constant RISK_DENOMINATOR = 100_000; //
  uint232 internal constant TOTAL_SHARES = 10 ** 18; // = unity in Ethereum

  struct Curve {
    uint256 requiredLiquidity; // how much liquidity is required to meet the liq target
    uint232 remainingShares;
    uint24 riskFactor; // a number between 0 and 100_000
  }

  Curve public curve;

  /**
   @dev initialize the curve with liquidity cap and risk factor and remaining shares
   @param liquidityCap the target liquidity of the vault.
   @param riskFactor a factor strictly between 0 and RISK_DENOMINATOR, the higher the more risk
   */
  function _initializeCurve(uint256 liquidityCap, uint24 riskFactor) internal {
    require(0 < riskFactor && riskFactor < RISK_DENOMINATOR, "Must have: 0 < risk < 1");
    curve.requiredLiquidity = liquidityCap;
    curve.riskFactor = riskFactor;
    curve.remainingShares = TOTAL_SHARES;
  }

  /**
   @dev computes the shares given the deposit and the current state of the curve.
   Relies on the Contract FractionalPower. Would be great to turn into a library.
   @param deposit the deposit into the vault.
   @return shares the amount of shares that the deposit has yielded.
   */
  function _calculateShares(uint256 deposit) internal view returns (uint256 shares) {
    // calculate power of ratios
    (uint256 p, uint256 q) = FractionalPower.pow(curve.requiredLiquidity, deposit, uint256(curve.riskFactor), uint256(RISK_DENOMINATOR));

    // calculate formula
    shares = mulDivF(mulDivF(deposit, p, q), uint256(curve.remainingShares), curve.requiredLiquidity);
  }

  /** 
    @dev updates the curve parameters given the deposit
    @dev This allows to exceed the liquidity target and thus also the total amount of shares. 
    @param deposit the deposit into the vault.
    @return shares the amount of shares that the deposit has yielded.
    */
  function _updateCurveAllowExceedTarget(uint256 deposit) internal returns (uint256 shares) {
    // calculate shares
    shares = _calculateShares(deposit);
    // update the curve
    if (deposit < curve.requiredLiquidity) {
      // shares guaranteed to be less or equal to remaining shares
      // when deposit is less than required liquidity, because of
      curve.requiredLiquidity = curve.requiredLiquidity - deposit;
      curve.remainingShares = curve.remainingShares - uint232(shares);
    } else {
      curve.requiredLiquidity = 0;
      curve.remainingShares = 0;
    }
  }

  /**
    @dev updates the curve parameters given the deposit
    @dev This prohibits exceeding the liquidity target and thus also the total amount of shares. 
    @param deposit the deposit into the vault.
    @return shares the amount of shares that the deposit has yielded.
    */
  function _updateCurveHardCap(uint deposit) internal returns (uint256 shares) {
    require(deposit <= curve.requiredLiquidity, "Must not exceed liquidity");
    // calculate shares
    shares = _calculateShares(deposit);
    // shares guaranteed to be less or equal to remaining shares
    // when deposit is less than required liquidity, because of
    curve.requiredLiquidity = curve.requiredLiquidity - deposit;
    curve.remainingShares = curve.remainingShares - uint232(shares);
  }

  /**
    @dev updates the curve parameters given the deposit
    @dev This only deposits up to the liquidity target and thus also the total amount of shares. 
    @param deposit the deposit into the vault.
    @return shares the amount of shares that the deposit has yielded.
    @return cappedDeposit the possibly corrected amount of deposit into the vault.
    */
  function _updateCurve(uint256 deposit) internal returns (uint256 shares, uint256 cappedDeposit) {
    // only deposit an amount that doesnt exceed the liquidity cap.
    if (deposit >= curve.requiredLiquidity) {
      cappedDeposit = curve.requiredLiquidity;
      shares = curve.remainingShares;
    } else {
      cappedDeposit = deposit;
      // calculate shares
      shares = _calculateShares(cappedDeposit);
    }
    // shares guaranteed to be less or equal to remaining shares
    // when deposit is less than required liquidity, because of
    curve.requiredLiquidity = curve.requiredLiquidity - cappedDeposit;
    curve.remainingShares = curve.remainingShares - uint232(shares);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {IDex} from "../interfaces/dex/IDex.sol";
import {IMasterVault} from "../interfaces/vaults/IMasterVault.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {ValidationLogic} from "../libraries/ValidationLogic.sol";

contract MasterVault is ACLUser, EmergencyModifier, ReentrancyGuard, IMasterVault {
  /**
   * @notice an array of all held loan ID for the master vault
   */
  uint256[] loans;

  /**
   * @notice address of the USDC contract
   */
  address usdcAddress;

  /**
   * @notice address of the wETH address
   */
  address wethAddress;

  /**
   * @notice instantiated USDC contract
   */
  ERC20 usdc;

  /**
   * @notice instantiated Dex contract
   */
  IDex dex;

  /**
   * @notice the constructor function is used during the deployment of this contract
   * @param _usdcAddress is the address of the USDC contract
   * @param _dex is the address of the DEX implementation contract
   * @param _wethAddress is the address of the wETH contract
   * @param _accessControl is the address of the Access Control contract
   */
  constructor(address _usdcAddress, address _dex, address _wethAddress, address _accessControl, address _emsAddress) {
    usdcAddress = _usdcAddress;
    usdc = ERC20(_usdcAddress);
    dex = IDex(_dex);
    wethAddress = _wethAddress;
    aclContract = ACL(_accessControl);
    emsContract = EmergencyStop(_emsAddress);
  }

  /**
   * @notice requestPolicyFee is used to transfer the USDC policy fee
   * @param _amount is the value amount of the fee
   */
  function requestPolicyFee(uint256 _amount) external emergencyStop isBaseLoanOrManager {
    ValidationLogic.validateRequestPolicyFee(_amount);
    bool success = usdc.transfer(msg.sender, _amount);
    require(success, "USDC Transfer Failed");
  }

  /**
   * @notice executeSwap is used to trigger a swap from an asset to wETH
   * @param _amount is the amount of asset being swapped
   * @param _collateralAddress is the address of the asset being swapped
   */
  function executeSwap(uint256 _amount, address _collateralAddress) external emergencyStop isBaseLoanOrManager {
    ValidationLogic.validateSwap(_amount, _collateralAddress);
    _executeSwap(_amount, false, _collateralAddress);
  }

  /**
   * @notice sendCollateral is used to transfer collateral to another address
   * @param _to is the address the collateral is being transfered to
   * @param _amount is the amount of collateral being transfered
   * @param _collateral is the address of the collateral being transfered
   */
  function sendCollateral(address payable _to, uint256 _amount, address _collateral) external emergencyStop nonReentrant isBaseLoanOrManager {
    ValidationLogic.validateSendCollateral(_to, _amount, _collateral);
    if (_collateral != usdcAddress) {
      ERC20 collateralToken = ERC20(_collateral);
      if (collateralToken.balanceOf(address(this)) >= _amount) {
        bool success = collateralToken.transfer(_to, _amount);
        require(success, "Token Transfer Failed");
      } else {
        _executeSwap(_amount - collateralToken.balanceOf(address(this)), false, _collateral);
        bool success = collateralToken.transfer(_to, _amount);
        require(success, "Token Transfer Failed");
      }
    } else {
      bool success = usdc.transfer(_to, _amount);
      require(success, "USDC Transfer Failed");
    }
  }

  /**
   * @notice sendDebtTokens is used to transfer the debt tokens to a different account
   * @param _to is the address the debt token is being transfered to
   * @param _amount is the amount of debt token being transfered
   * @param _debtTokenAddress is the address of the debt token being transfered
   */
  function sendDebtTokens(address payable _to, uint256 _amount, address _debtTokenAddress) external emergencyStop nonReentrant isBaseLoanOrManager {
    ValidationLogic.validateSendDebtTokens(_to, _amount, _debtTokenAddress);
    if (_debtTokenAddress == address(0x0)) {
      uint256 swappedAmount = _executeSwap(_amount, true, wethAddress);
      //Ok to send to _to, because _to is the address of the baseLoanBroker
      //slither-disable-next-line arbitrary-send-eth
      _to.transfer(swappedAmount);
    } else if (_debtTokenAddress != usdcAddress) {
      uint256 swappedAmount = _executeSwap(_amount, false, _debtTokenAddress);
      ERC20 token = ERC20(_debtTokenAddress);
      require(token.transfer(_to, swappedAmount), "Token transfer failed");
    } else {
      bool success = usdc.transfer(_to, _amount);
      require(success, "USDC Transfer Failed");
    }
  }

  function addLoanToVault(uint256 _loanID) external isBaseLoanOrManager emergencyStop {
    loans.push(_loanID);
    emit LoanAdded(_loanID);
  }

  /**
   * @notice getBalanceOfAsset is used to retrieve the amount of an asset held by this contract
   * @param _asset is the address of the asset in question
   * @return is the amount of asset this contract holds
   */
  function getBalanceOfAsset(address _asset) external returns (uint256) {
    ERC20 asset = ERC20(_asset);
    uint256 balance = asset.balanceOf(address(this));
    emit VaultBalance(address(this), balance, _asset);
    return balance;
  }

  /**
   * @notice _executeSwap is an internal function ised to execute a token swap
   * @param _amount is the amount being swapped
   * @param _eth is a bool representing if the asset being swapped is ETH
   * @param _targetToken is the address of the asset being swapped to
   * @return is the amount of target asset received
   */
  function _executeSwap(uint256 _amount, bool _eth, address _targetToken) internal returns (uint256) {
    if (_eth) {
      uint256 calculatedAmount = dex.getAssetPrice(_amount, usdcAddress, wethAddress);
      usdc.approve(address(dex), 50000);
      return dex.swapExactTokensForETH(_amount, calculatedAmount, usdcAddress, address(this));
    } else if (_targetToken != usdcAddress) {
      ERC20 asset = ERC20(_targetToken);
      uint256 calculatedAmount = dex.getAssetPrice(_amount, _targetToken, usdcAddress);
      asset.approve(address(dex), _amount);
      return dex.swapExactTokensForTokens(_amount, calculatedAmount, _targetToken, usdcAddress, address(this));
    } else {
      revert("Cannot swap USDC for USDC");
    }
  }

  /**
   * @notice receive is a standard solidity function needed to allow this contract to hold ETH
   * @dev this fallback function is set to revert so that end users can't mistakenly send ETH to this contract
   */
  receive() external payable {
    revert();
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPositionToken} from "../interfaces/positionToken/IPositionToken.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";
import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";

contract RetailVault is EmergencyModifier, ACLUser {
  /**
   * @notice an array of all held loan ID for a retail vault
   */
  uint256[] loans;

  /**
   * @notice an array containing the position token IDs of protectors for this vault
   */
  uint256[] protectors;

  /**
   * @notice the target total liquidity required for a retail vault
   */
  uint256 totalLiquidityRequired;

  /**
   * @notice the remaining amount of liquidity needed to meet the target liquidity amount
   */
  uint256 currentLiquidityRequired;

  /**
   * @notice the amount of liquidity currently held
   */
  uint256 liquidityHeld;

  /**
   * @notice the address of the master vault
   */
  address masterVault;

  /**
   * @notice the instantiated USDC contract
   */
  ERC20 usdc;

  /**
   * @notice the instantiated position token
   */
  IPositionToken positionToken;

  /**
   * @notice the constructor is used to setup this contract during deployment
   * @param _requiredLiquidity is the target liquidity amount for this vault
   * @param _usdcAddress is the address of the USDC token contract
   * @param _positionToken is the address of the position token contract
   */
  constructor(uint256 _requiredLiquidity, address _usdcAddress, address _positionToken, address _masterVault, address _aclAddress, address _emsAddress) {
    totalLiquidityRequired = _requiredLiquidity;
    currentLiquidityRequired = _requiredLiquidity;
    usdc = ERC20(_usdcAddress);
    positionToken = IPositionToken(_positionToken);
    masterVault = _masterVault;
    aclContract = ACL(_aclAddress);
    emsContract = EmergencyStop(_emsAddress);
  }

  /**
   * @notice depositLiquidity is used to deposit liquidity into the retail vault
   * @param _amount is the amount of liquidity being deposited
   */
  function depositLiquidity(uint256 _amount) external emergencyStop {
    liquidityHeld += _amount;
    currentLiquidityRequired -= liquidityHeld;
  }

  function addLoanToVault(uint256 _loanID) external emergencyStop {
    loans.push(_loanID);
  }

  /**
   * @notice transferToMasterVault is used to transfer liquidity to the master vault
   * @param _amount is the amount of liquidity being transfered
   */
  function transferToMasterVault(uint256 _amount) external emergencyStop {
    bool success = usdc.transfer(masterVault, _amount);
    require(success, "USDC Transfer Failed");
  }

  /**
   * @notice collectEarnings is used to transfer position earnins to a position token holder
   * @param _params is an input CollectionParams struct for a position token
   * @param _tokenId is the position token ID that the earnings are being collected on
   */
  function collectEarnings(IPositionToken.CollectParams calldata _params, uint256 _tokenId) external emergencyStop {
    (, , uint256 amount, , , ) = positionToken.positions(_tokenId);

    require(usdc.transfer(_params.recipient, amount), "ERR: Token transfer failed");
  }

  /**
   * @notice getLoansHeldInVault is used to retrieve the loan ID of the loans held in a retail vault
   * @return is an array containing the loan token ID of the loans held in a retail vault
   */
  function getLoansHeldInVault() external view returns (uint256[] memory) {
    return loans;
  }

  function getLiquidityHeldInVault() external view returns (uint256) {
    return liquidityHeld;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {VaultCurve} from "../utils/VaultCurve.sol";
import {IVaultSale} from "../interfaces/vaultSale/IVaultSale.sol";
import {IPositionToken} from "../interfaces/positionToken/IPositionToken.sol";
import {RetailVault} from "../vaults/RetailVault.sol";
import {ACL} from "../acl/Acl.sol";
import {ACLUser} from "../acl/AclUser.sol";
import {EmergencyModifier} from "../emergency/EmergencyModifier.sol";
import {EmergencyStop} from "../emergency/EmergencyStop.sol";

/**
 * @title VaultSale
 * @author Ryan Turner
 * @dev contract to handle the sale of vaults
 * @dev mints a position token when user deposits
 */

contract VaultSale is Initializable, IVaultSale, VaultCurve, ACLUser, EmergencyModifier {
  using Counters for Counters.Counter;

  Counters.Counter private currentVaultId;
  IPositionToken public positionToken;

  ///@notice Maps vault ID's to a vault info struct (see IVaultSale)
  mapping(uint256 => VaultInfo) vaultIdToInfo;

  mapping(uint256 => address payable) vaultIdToAddress;

  ///@notice convenience array for displaying all active vaults
  VaultInfo[] public allActiveVaults;

  address masterVault;
  address _aclContractAddress;
  address _emsContractAddress;

  function initialize(address _aclContract, address _positionToken, address _masterVault, address _emsAddress) public initializer {
    positionToken = IPositionToken(_positionToken);
    aclContract = ACL(_aclContract);
    _aclContractAddress = _aclContract;
    // need to initialize the cached parameters (otherwise cannot compute fractional exponents)
    currentVaultId.increment();
    masterVault = _masterVault;
    emsContract = EmergencyStop(_emsAddress);
    _emsContractAddress = _emsAddress;
  }

  function _initCache() public onlyManager {
    initExponentialCache();
  }

  /**
   * @notice Function that allows manager to update the position token implementation
   * @param _updatedAddress The new address for the position token
   * @dev Access Controlled
   * @dev Necessary because the position token is not upgradable
   */
  function updatePositionTokenImplementation(address _updatedAddress) external emergencyStop onlyManager {
    positionToken = IPositionToken(_updatedAddress);
  }

  /**
   * @notice Function that allows a user to deposit to a vault
   * @param _vaultId The id of the vault the user is depositing into
   * @param _depositParams Struct of params required for deposit (see IVaultSale)
   * @dev Calls position token to mint a new NFT
   */
  function depositIntoVault(uint256 _vaultId, DepositParams memory _depositParams) external emergencyStop {
    (uint256 yield, uint256 cappedDeposit) = VaultCurve._updateCurve(_depositParams.depositAmount);
    _depositParams.depositAmount = cappedDeposit;
    VaultInfo storage vault = vaultIdToInfo[_vaultId];
    if (_depositParams.positiontokenId == 0) {
      IPositionToken.MintParams memory _mintParams = IPositionToken.MintParams({
        collateralToken: _depositParams.collateralToken,
        collateralSymbol: _depositParams.collateralSymbol,
        recipient: _depositParams.recipient,
        vaultAddress: vault.vaultAddress,
        depositAmount: _depositParams.depositAmount,
        vaultId: _vaultId,
        yield: yield,
        lockupTime: vault.maturationTime
      });
      uint256 positionTokenId = positionToken.mint(_mintParams);
      vault.positionTokenIds.push(positionTokenId);
      vaultIdToInfo[_vaultId] = vault;
    } else {
      require(positionToken.ownerOf(_depositParams.positiontokenId) == _depositParams.recipient, "ERR: Not position token owner");
      IPositionToken.IncreaseDepositParams memory _params = IPositionToken.IncreaseDepositParams({tokenId: _depositParams.positiontokenId, amount: cappedDeposit, yield: yield});

      positionToken.increaseDeposit(_params);
    }

    //Handle deposit
    IERC20Upgradeable token = IERC20Upgradeable(_depositParams.collateralToken);
    RetailVault retailVault = RetailVault(vault.vaultAddress);
    retailVault.depositLiquidity(_depositParams.depositAmount);
    //Disabled due to _depositParams.recipient not being arbitrary
    //slither-disable-next-line arbitrary-send-erc20
    require(token.transferFrom(address(_depositParams.recipient), vault.vaultAddress, _depositParams.depositAmount), "USDC Transfer Failed");
    emit Deposited(msg.sender, vault.vaultAddress, _vaultId, _depositParams.depositAmount, yield);
  }

  /**
   * @notice function that allows manager to create a vault sale
   * @param _liquidityCap How much liquidity the vault needs to hold
   * @param _maxYield The max yield percentage
   * @param _minYield the minimum yield percentage
   * @param _maturationTime How long until the vault funds can be withdrawn
   * @param _riskFactor the risk strictly between 0 and RISK_DENOMINATOR (def in VaultCurve.sol)
   * @dev Access Controlled
   */
  function createVaultSale(
    uint256 _liquidityCap,
    uint256 _maxYield,
    uint256 _minYield,
    uint24 _riskFactor,
    uint256 _maturationTime,
    address _liquidityAsset
  ) external onlyCore emergencyStop returns (uint256) {
    uint256 _vaultId = currentVaultId.current();
    RetailVault retailVault = new RetailVault(_liquidityCap, _liquidityAsset, address(positionToken), masterVault, address(_aclContractAddress), address(_emsContractAddress));
    vaultIdToAddress[_vaultId] = payable(address(retailVault));
    VaultInfo storage vault = vaultIdToInfo[_vaultId];
    vault.vaultId = _vaultId;
    vault.liquidityCap = _liquidityCap;
    vault.maxYield = _maxYield;
    vault.minYield = _minYield;
    vault.maturationTime = block.timestamp + _maturationTime;
    vault.riskFactor = _riskFactor;
    vault.vaultAddress = address(retailVault);
    allActiveVaults.push(vault);
    vaultIdToInfo[_vaultId] = vault;

    VaultCurve._initializeCurve(vault.liquidityCap, _riskFactor);

    emit VaultSaleCreated(_vaultId, _liquidityCap, _maxYield, _minYield, _riskFactor, _maturationTime);
    currentVaultId.increment();
    return _vaultId;
  }

  function withdrawPositionFromVault(IPositionToken.CollectParams calldata _params) external emergencyStop {
    uint256 positionTokenId = positionToken.getUserTokenId(_params.recipient, _params.vaultId);
    VaultInfo memory vaultInfo = vaultIdToInfo[_params.vaultId];
    require(vaultInfo.maturationTime <= block.timestamp, "ERR: Cannot withdraw before lockup complete");
    RetailVault vault = RetailVault(vaultInfo.vaultAddress);
    vault.collectEarnings(_params, positionTokenId);
    positionToken.collect(_params, positionTokenId);
  }

  /**
   * @notice Function that allows a vault sale to be closed
   * @param _vaultId The id of the vault
   * @dev Access Controlled
   */
  function closeVaultSale(uint256 _vaultId) external emergencyStop {
    delete vaultIdToInfo[_vaultId];
    _deleteActiveVault(_vaultId);

    emit VaultSaleClosed(_vaultId);
  }

  //GETTERS
  /**
   * @notice function that returns array of all available vaults
   * @return array containing VaultInfo of all currently available vaults
   */
  function getAvailableVaults() external view returns (VaultInfo[] memory) {
    return allActiveVaults;
  }

  /**
   * @return Position token implementation address
   */
  function getPositionTokenImplementationAddress() external view returns (address) {
    return address(positionToken);
  }

  /**
   * @return vault address by ID
   */
  function getVaultAddress(uint256 _vaultId) external view returns (address) {
    return vaultIdToAddress[_vaultId];
  }

  /**
   * @return current vault ID
   */
  function getCurrentVault() external view returns (uint) {
    return currentVaultId.current();
  }

  //HELPER FUNCTIONS
  /**
   * @notice function to find the index of a given value in an array
   * @param _value The value being checked against
   * @return The index of the value in the array
   */
  function _find(uint256 _value) internal view returns (uint256) {
    uint256 i = 0;
    while (allActiveVaults[i].vaultId != _value) {
      i++;
    }
    return i;
  }

  /**
   * @notice Helper function to delete item from array and reduce the length of the array
   * @param _vaultId The id of the vault being removed
   */
  function _deleteActiveVault(uint256 _vaultId) internal {
    uint256 j = _find(_vaultId);
    allActiveVaults[j] = allActiveVaults[allActiveVaults.length - 1];
    allActiveVaults.pop();
  }
}