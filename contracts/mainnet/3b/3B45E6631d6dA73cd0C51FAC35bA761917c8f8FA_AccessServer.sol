// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/utils/structs/EnumerableSet.sol";
import "contracts/utils/Strings.sol";

import "contracts/access/AccessConstants.sol";
import "contracts/access/AccessEventsErrors.sol";
import "contracts/access/IAccessServer.sol";
import "contracts/access/ViciOwnable.sol";

/**
 * @title Access Server
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev This contract serves as a centralized repository for managing
 * role-based access and OFAC sanctions compliance.
 * @dev Accounts can be granted roles globally across all client contracts,
 * or may be granted roles for individual client contracts.
 * @dev Client contracts register by calling `register()`.
 * @dev Client contracts SHOULD refer to this contract via the IAccessServer
 * interface.
 */
contract AccessServer is ViciOwnable, IAccessServer {
    using Strings for string;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct ResourcePolicy {
        address owner;
        mapping(bytes32 => EnumerableSet.AddressSet) roleMembers;
        mapping(bytes32 => RoleData) roles;
    }

    address internal constant GLOBAL_RESOURCE = address(0);

    ChainalysisSanctionsList public sanctionsList;
    mapping(address => ResourcePolicy) managedResources;
    EnumerableSet.AddressSet administrators;

    /* ################################################################
     * Initialization
     * ##############################################################*/

    function initialize() public virtual initializer {
        __AccessServer_init();
    }

    function __AccessServer_init() internal onlyInitializing {
        __Ownable_init_unchained();
        __AccessServer_init_unchained();
    }

    function __AccessServer_init_unchained() internal onlyInitializing {
        _setRoleAdmin(GLOBAL_RESOURCE, BANNED, MODERATOR);
    }

    /* ################################################################
     * Modifiers / Rule Enforcement
     * ##############################################################*/

    /**
     * @dev Reverts if the caller is not a registered resource.
     */
    modifier registeredResource() {
        require(isRegistered(_msgSender()), "AccessServer: not registered");
        _;
    }

    /**
     * @dev Reverts if the caller is not an administrator of this AccessServer.
     */
    modifier onlyAdministrator() {
        require(
            isAdministrator(_msgSender()),
            "AccessServer: caller is not admin"
        );
        _;
    }

    /**
     * @dev Throws if the account is not the resource's owner.
     */
    function enforceIsOwner(
        address resource,
        address account
    ) public view virtual override {
        if (account != getResourceOwner(resource)) {
            revert OwnableUnauthorizedAccount(account);
        }
    }

    /**
     * @dev Throws if the account is not the calling resource's owner.
     */
    function enforceIsMyOwner(address account) public view virtual override {
        if (account != getResourceOwner(_msgSender())) {
            revert OwnableUnauthorizedAccount(account);
        }
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the resource.
     */
    function enforceIsModerator(
        address resource,
        address account
    ) public view virtual override {
        if (
            account != getResourceOwner(resource) &&
            !hasRole(resource, MODERATOR, account)
        ) {
            revert AccessControlUnauthorizedAccount(account, MODERATOR);
        }
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the calling resource.
     */
    function enforceIsMyModerator(
        address account
    ) public view virtual override {
        enforceIsModerator(_msgSender(), account);
    }

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * resource
     */
    function enforceIsNotBanned(
        address resource,
        address account
    ) public view virtual override {
        enforceIsNotSanctioned(account);
        if(isBanned(resource, account)) {
            revert BannedAccount(account);
        }
    }

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * calling resource
     */
    function enforceIsNotBannedForMe(
        address account
    ) public view virtual override {
        enforceIsNotBanned(_msgSender(), account);
    }

    /**
     * @dev Reverts the account is on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(
        address account
    ) public view virtual override {
        if(isSanctioned(account)) {
            revert OFACSanctionedAccount(account);
        }
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the resource.
     */
    function enforceOwnerOrRole(
        address resource,
        bytes32 role,
        address account
    ) public view virtual override {
        if (account != getResourceOwner(resource)) {
            checkRole(resource, role, account);
        }
    }

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the calling resource.
     */
    function enforceOwnerOrRoleForMe(
        bytes32 role,
        address account
    ) public view virtual override {
        enforceOwnerOrRole(_msgSender(), role, account);
    }

    /* ################################################################
     * Administration
     * ##############################################################*/

    /**
     * @dev Returns `true` if `admin` is an administrator of this AccessServer.
     */
    function isAdministrator(
        address admin
    ) public view virtual override returns (bool) {
        return administrators.contains(admin);
    }

    /**
     * @dev Adds `admin` as an administrator of this AccessServer.
     */
    function addAdministrator(address admin) public virtual override onlyOwner {
        require(!isAdministrator(admin), "AccessServer: already admin");
        administrators.add(admin);
        emit AdminAddition(admin);
    }

    /**
     * @dev Removes `admin` as an administrator of this AccessServer.
     */
    function removeAdministrator(address admin) public virtual override {
        require(
            _msgSender() == owner() || _msgSender() == admin,
            "AccessServer: caller is not owner or self"
        );
        administrators.remove(admin);
        emit AdminRemoval(admin);
    }

    /**
     * @dev Returns the number of administrators of this AccessServer.
     * @dev Use with `getAdminAt()` to enumerate.
     */
    function getAdminCount() public view virtual override returns (uint256) {
        return administrators.length();
    }

    /**
     * @dev Returns the administrator at the index.
     * @dev Use with `getAdminCount()` to enumerate.
     */
    function getAdminAt(
        uint256 index
    ) public view virtual override returns (address) {
        return administrators.at(index);
    }

    /**
     * @dev Returns the list of administrators
     */
    function getAdmins()
        public
        view
        virtual
        override
        returns (address[] memory)
    {
        return administrators.values();
    }

    /**
     * @dev Sets the Chainalysis sanctions oracle.
     * @dev setting this to the zero address disables sanctions compliance.
     * @dev Don't disable sanctions compliance unless there is some problem
     * with the sanctions oracle.
     */
    function setSanctionsList(
        ChainalysisSanctionsList _sanctionsList
    ) public virtual override onlyOwner {
        sanctionsList = _sanctionsList;
    }

    /**
     * @dev Returns `true` if `account` is under OFAC sanctions.
     * @dev Returns `false` if sanctions compliance is disabled.
     */
    function isSanctioned(
        address account
    ) public view virtual override returns (bool) {
        return (address(sanctionsList) != address(0) &&
            sanctionsList.isSanctioned(account));
    }

    /* ################################################################
     * Registration / Ownership
     * ##############################################################*/

    /**
     * @dev Registers the calling resource and sets the resource owner.
     * @dev Grants the default administrator role for the resource to the
     * resource owner.
     *
     * Requirements:
     * - caller SHOULD be a contract
     * - caller MUST NOT be already registered
     * - `owner` MUST NOT be the zero address
     * - `owner` MUST NOT be globally banned
     * - `owner` MUST NOT be under OFAC sanctions
     */
    function register(address owner) public virtual override {
        // require(
        //     Address.isContract(_msgSender()),
        //     "AccessServer: must be contract"
        // );
        ResourcePolicy storage policy = managedResources[_msgSender()];
        require(policy.owner == address(0), "AccessServer: already registered");
        _setResourceOwner(_msgSender(), owner);
        emit ResourceRegistration(_msgSender());
    }

    /**
     * @dev Returns `true` if `resource` is registered.
     */
    function isRegistered(
        address resource
    ) public view virtual override returns (bool) {
        return managedResources[resource].owner != address(0);
    }

    /**
     * @dev Returns the owner of `resource`.
     */
    function getResourceOwner(
        address resource
    ) public view virtual override returns (address) {
        return managedResources[resource].owner;
    }

    /**
     * @dev Returns the owner of the calling resource.
     */
    function getMyOwner() public view virtual override returns (address) {
        return getResourceOwner(_msgSender());
    }

    /**
     * @dev Sets the owner for the calling resource.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` MUST be the current owner
     * - `newOwner` MUST NOT be the zero address
     * - `newOwner` MUST NOT be globally banned
     * - `newOwner` MUST NOT be banned by the calling resource
     * - `newOwner` MUST NOT be under OFAC sanctions
     * - `newOwner` MUST NOT be the current owner
     */
    function setMyOwner(
        address operator,
        address newOwner
    ) public virtual override registeredResource {
        enforceIsOwner(_msgSender(), operator);
        if(newOwner == getMyOwner()) {
            revert OwnableInvalidOwner(newOwner);
        }
        _setResourceOwner(_msgSender(), newOwner);
    }

    function _setResourceOwner(
        address resource,
        address newOwner
    ) internal virtual {
        if(newOwner == address(0)) {
            revert OwnableInvalidOwner(newOwner);
        }
        enforceIsNotBanned(resource, newOwner);
        managedResources[resource].owner = newOwner;
        _do_grant_role(resource, DEFAULT_ADMIN, newOwner);
    }

    /* ################################################################
     * Role Administration
     * ##############################################################*/

    /**
     * @dev Returns the admin role that controls `role` by default for all
     * resources. See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getGlobalRoleAdmin(
        bytes32 role
    ) public view virtual override returns (bytes32) {
        return _getRoleAdmin(GLOBAL_RESOURCE, role);
    }

    /**
     * @dev Returns the admin role that controls `role` for a resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdminForResource(
        address resource,
        bytes32 role
    ) public view virtual override returns (bytes32) {
        bytes32 roleAdmin = _getRoleAdmin(resource, role);
        if (roleAdmin == DEFAULT_ADMIN) {
            return getGlobalRoleAdmin(role);
        }

        return roleAdmin;
    }

    /**
     * @dev Returns the admin role that controls `role` for the calling resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMyRoleAdmin(
        bytes32 role
    ) public view virtual override returns (bytes32) {
        return getRoleAdminForResource(_msgSender(), role);
    }

    function _getRoleAdmin(
        address resource,
        bytes32 role
    ) internal view returns (bytes32) {
        return managedResources[resource].roles[role].adminRole;
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on as default all
     * resources.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function setGlobalRoleAdmin(
        bytes32 role,
        bytes32 adminRole
    ) public virtual override onlyAdministrator {
        bytes32 previousAdminRole = _getRoleAdmin(GLOBAL_RESOURCE, role);
        _setRoleAdmin(GLOBAL_RESOURCE, role, adminRole);
        emit GlobalRoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on the calling resource.
     * @dev There is no set roleAdminForResource vs setRoleAdminForMe.
     * @dev Resources must manage their own role admins or use the global
     * defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     */
    function setRoleAdmin(
        address operator,
        bytes32 role,
        bytes32 adminRole
    ) public virtual override registeredResource {
        enforceOwnerOrRole(_msgSender(), DEFAULT_ADMIN, operator);
        _setRoleAdmin(_msgSender(), role, adminRole);
    }

    function _setRoleAdmin(
        address resource,
        bytes32 role,
        bytes32 adminRole
    ) internal virtual {
        managedResources[resource].roles[role].adminRole = adminRole;
    }

    /* ################################################################
     * Checking Role Membership
     * ##############################################################*/

    /**
     * @dev Returns `true` if `account` has been granted `role` as default for
     * all resources.
     */
    function hasGlobalRole(
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        return hasLocalRole(GLOBAL_RESOURCE, role, account);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * `resource`.
     */
    function hasRole(
        address resource,
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        return (hasGlobalRole(role, account) ||
            hasLocalRole(resource, role, account));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role` for `resource`.
     */
    function hasLocalRole(
        address resource,
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        return managedResources[resource].roles[role].members[account];
    }

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * the calling resource.
     */
    function hasRoleForMe(
        bytes32 role,
        address account
    ) public view virtual override returns (bool) {
        return hasRole(_msgSender(), role, account);
    }

    /**
     * @dev Returns `true` if account` is banned globally or from `resource`.
     */
    function isBanned(
        address resource,
        address account
    ) public view virtual override returns (bool) {
        return hasRole(resource, BANNED, account);
    }

    /**
     * @dev Returns `true` if account` is banned globally or from the calling
     * resource.
     */
    function isBannedForMe(
        address account
    ) public view virtual override returns (bool) {
        return hasRole(_msgSender(), BANNED, account);
    }

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * `resource`.
     */
    function checkRole(
        address resource,
        bytes32 role,
        address account
    ) public view virtual override {
        if (!hasRole(resource, role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * the calling resource.
     */
    function checkRoleForMe(
        bytes32 role,
        address account
    ) public view virtual override {
        checkRole(_msgSender(), role, account);
    }

    /* ################################################################
     * Granting Roles
     * ##############################################################*/

    /**
     * @dev Grants `role` to `account` as default for all resources.
     * @dev Warning: This function can do silly things like applying a global
     * ban to a resource owner.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     * - If `role` is not BANNED, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantGlobalRole(
        bytes32 role,
        address account
    ) public virtual override onlyAdministrator {
        if (role != BANNED) {
            enforceIsNotBanned(GLOBAL_RESOURCE, account);
        }
        if (!hasGlobalRole(role, account)) {
            _do_grant_role(GLOBAL_RESOURCE, role, account);
            emit GlobalRoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Grants `role` to `account` for the calling resource as `operator`.
     * @dev There is no set grantRoleForResource vs grantRoleForMe.
     * @dev Resources must manage their own roles or use the global defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `grantRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - If `role` is BANNED, `account` MUST NOT be the resource
     *   owner. You can't ban the owner.
     * - If `role` is not BANNED, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantRole(
        address operator,
        bytes32 role,
        address account
    ) public virtual override registeredResource {
        _grantRole(_msgSender(), operator, role, account);
    }

    function _grantRole(
        address resource,
        address operator,
        bytes32 role,
        address account
    ) internal virtual {
        enforceIsNotBanned(resource, operator);
        if (role == BANNED) {
            enforceIsModerator(resource, operator);
            require(
                account != getResourceOwner(resource),
                "AccessControl: ban owner"
            );
        } else {
            enforceIsNotBanned(resource, account);
            if (operator != getResourceOwner(resource)) {
                checkRole(
                    resource,
                    getRoleAdminForResource(resource, role),
                    operator
                );
            }
        }

        _do_grant_role(resource, role, account);
    }

    function _do_grant_role(
        address resource,
        bytes32 role,
        address account
    ) internal virtual {
        if (!hasRole(resource, role, account)) {
            managedResources[resource].roles[role].members[account] = true;
            managedResources[resource].roleMembers[role].add(account);
        }
    }

    /* ################################################################
     * Revoking / Renouncing Roles
     * ##############################################################*/

    /**
     * @dev Revokes `role` as default for all resources from `account`.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function revokeGlobalRole(
        bytes32 role,
        address account
    ) public virtual override onlyAdministrator {
        _do_revoke_role(GLOBAL_RESOURCE, role, account);
        emit GlobalRoleRevoked(role, account, _msgSender());
    }

    /**
     * @dev Revokes `role` from `account` for the calling resource as
     * `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `revokeRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - if `role` is DEFAULT_ADMIN, `account` MUST NOT be the calling
     *   resource's owner. The admin role cannot be revoked from the owner.
     */
    function revokeRole(
        address operator,
        bytes32 role,
        address account
    ) public virtual override registeredResource {
        enforceIsNotBanned(_msgSender(), operator);
        require(
            role != DEFAULT_ADMIN || account != getResourceOwner(_msgSender()),
            "AccessControl: revoke admin from owner"
        );

        if (role == BANNED) {
            enforceIsModerator(_msgSender(), operator);
        } else {
            enforceOwnerOrRole(
                _msgSender(),
                getRoleAdminForResource(_msgSender(), role),
                operator
            );
        }

        _do_revoke_role(_msgSender(), role, account);
    }

    /**
     * @dev Remove the default role for yourself. You will still have the role
     * for any resources where it was granted individually.
     *
     * Requirements:
     * - caller MUST have the role they are renouncing at the global level.
     * - `role` MUST NOT be BANNED. You can't unban yourself.
     */
    function renounceRoleGlobally(bytes32 role) public virtual override {
        require(role != BANNED, "AccessControl: self unban");
        _do_revoke_role(GLOBAL_RESOURCE, role, _msgSender());
        emit GlobalRoleRevoked(role, _msgSender(), _msgSender());
    }

    /**
     * @dev Renounces `role` for the calling resource as `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `renounceRole()` on the
     *    calling resource.
     * - `operator` MUST have the role they are renouncing on the calling
     *   resource.
     * - if `role` is DEFAULT_ADMIN, `operator` MUST NOT be the calling
     *   resource's owner. The owner cannot renounce the admin role.
     * - `role` MUST NOT be BANNED. You can't unban yourself.
     */
    function renounceRole(
        address operator,
        bytes32 role
    ) public virtual override registeredResource {
        require(
            role != DEFAULT_ADMIN || operator != getResourceOwner(_msgSender()),
            "AccessControl: owner renounce admin"
        );
        require(role != BANNED, "AccessControl: self unban");
        _do_revoke_role(_msgSender(), role, operator);
    }

    function _do_revoke_role(
        address resource,
        bytes32 role,
        address account
    ) internal virtual {
        checkRole(_msgSender(), role, account);
        require(
            resource == GLOBAL_RESOURCE ||
                hasLocalRole(resource, role, account),
            "AccessServer: role must be removed globally"
        );
        managedResources[resource].roles[role].members[account] = false;
        managedResources[resource].roleMembers[role].remove(account);
    }

    /* ################################################################
     * Enumerating Role Members
     * ##############################################################*/

    /**
     * @dev Returns the number of accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMember()` to enumerate.
     */
    function getGlobalRoleMemberCount(
        bytes32 role
    ) public view virtual override returns (uint256) {
        return _getRoleMemberCount(GLOBAL_RESOURCE, role);
    }

    /**
     * @dev Returns one of the accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getGlobalRoleMemberCount(role)`
     */
    function getGlobalRoleMember(
        bytes32 role,
        uint256 index
    ) public view virtual override returns (address) {
        return managedResources[GLOBAL_RESOURCE].roleMembers[role].at(index);
    }

    /**
     * @dev Returns the list of accounts that have `role` set at the global
     * level.
     */
    function getGlobalRoleMembers(
        bytes32 role
    ) public view virtual override returns (address[] memory) {
        return managedResources[GLOBAL_RESOURCE].roleMembers[role].values();
    }

    /**
     * @dev Returns the number of accounts that have `role` set globally or for
     * `resource`.
     * @dev Use with `getRoleMember()` to enumerate.
     */
    function getRoleMemberCount(
        address resource,
        bytes32 role
    ) public view virtual override returns (uint256) {
        return _getRoleMemberCount(resource, role);
    }

    /**
     * @dev Returns one of the accounts that have `role` set globally or for
     * `resource`.
     * @dev If a role has global and local members, the global members
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getRoleMemberCount(role)`
     */
    function getRoleMember(
        address resource,
        bytes32 role,
        uint256 index
    ) public view virtual override returns (address) {
        return _getRoleMemberForResourceAtIndex(resource, role, index);
    }

    /**
     * @dev Returns the number of accounts that have `role` set globally or for
     * the calling resource.
     * @dev Use with `getMyRoleMember()` to enumerate.
     */
    function getMyRoleMemberCount(
        bytes32 role
    ) public view virtual override returns (uint256) {
        return _getMemberCountForResource(_msgSender(), role);
    }

    /**
     * @dev Returns one of the accounts that have `role` set globally or for
     * the calling resource.
     * @dev If a role has global and local members, the global members
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getMyRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getMyRoleMemberCount(role)`
     */
    function getMyRoleMember(
        bytes32 role,
        uint256 index
    ) public view virtual override returns (address) {
        return _getRoleMemberForResourceAtIndex(_msgSender(), role, index);
    }

    function _getMemberCountForResource(
        address resource,
        bytes32 role
    ) internal view virtual returns (uint256) {
        return
            getGlobalRoleMemberCount(role) +
            _getRoleMemberCount(resource, role);
    }

    function _getRoleMemberForResourceAtIndex(
        address resource,
        bytes32 role,
        uint256 index
    ) internal view virtual returns (address) {
        uint256 globalCount = getGlobalRoleMemberCount(role);
        if (index < globalCount) {
            return getGlobalRoleMember(role, index);
        }

        return
            managedResources[resource].roleMembers[role].at(
                index - globalCount
            );
    }

    function _getRoleMemberCount(
        address resource,
        bytes32 role
    ) internal view virtual returns (uint256) {
        return managedResources[resource].roleMembers[role].length();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "contracts/utils/math/Math.sol";
import {SignedMath} from "contracts/utils/math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant DEFAULT_ADMIN = 0x00;
bytes32 constant BANNED = "banned";
bytes32 constant MODERATOR = "moderator";
bytes32 constant ANY_ROLE = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
bytes32 constant BRIDGE_CONTRACT = keccak256("BRIDGE_CONTRACT");
bytes32 constant BRIDGE_ROLE_MGR = keccak256("BRIDGE_ROLE_MGR");
bytes32 constant CREATOR_ROLE_NAME = "creator";
bytes32 constant CUSTOMER_SERVICE = "Customer Service";
bytes32 constant MINTER_ROLE_NAME = "minter";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.24;

interface AccessEventsErrors {
    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);


    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    error BannedAccount(address account);

    error OFACSanctionedAccount(address account);

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    /**
     * @notice Emitted when a new administrator is added.
     */
    event AdminAddition(address indexed admin);

    /**
     * @notice Emitted when an administrator is removed.
     */
    event AdminRemoval(address indexed admin);

    /**
     * @notice Emitted when a resource is registered.
     */
    event ResourceRegistration(address indexed resource);

    /**
     * @notice Emitted when `newAdminRole` is set globally as ``role``'s admin
     * role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {GlobalRoleAdminChanged} not being emitted signaling this.
     */
    event GlobalRoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @notice Emitted when `account` is granted `role` globally.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event GlobalRoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Emitted when `account` is revoked `role` globally.
     * @notice `account` will still have `role` where it was granted
     * specifically for any resources
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event GlobalRoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ChainalysisSanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

/**
 * @title Access Server Interface
 * @notice (c) 2023 ViciNFT https://vicinft.com/
 * @author Josh Davis <[email protected]>
 *
 * @dev Interface for the AccessServer.
 * @dev AccessServer client contracts SHOULD refer to the server contract via
 * this interface.
 */
interface IAccessServer {

    /* ################################################################
     * Modifiers / Rule Enforcement
     * ##############################################################*/

    /**
     * @dev Throws if the account is not the resource's owner.
     */
    function enforceIsOwner(address resource, address account) external view;

    /**
     * @dev Throws if the account is not the calling resource's owner.
     */
    function enforceIsMyOwner(address account) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the resource.
     */
    function enforceIsModerator(address resource, address account)
        external
        view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the moderator role for the calling resource.
     */
    function enforceIsMyModerator(address account) external view;

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * resource
     */
    function enforceIsNotBanned(address resource, address account)
        external
        view;

    /**
     * @dev Reverts if the account is under OFAC sanctions or is banned for the
     * calling resource
     */
    function enforceIsNotBannedForMe(address account) external view;

    /**
     * @dev Reverts the account is on the OFAC sanctions list.
     */
    function enforceIsNotSanctioned(address account) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the resource.
     */
    function enforceOwnerOrRole(
        address resource,
        bytes32 role,
        address account
    ) external view;

    /**
     * @dev Reverts if the account is not the resource owner or doesn't have
     * the required role for the calling resource.
     */
    function enforceOwnerOrRoleForMe(bytes32 role, address account)
        external
        view;

    /* ################################################################
     * Administration
     * ##############################################################*/

    /**
     * @dev Returns `true` if `admin` is an administrator of this AccessServer.
     */
    function isAdministrator(address admin) external view returns (bool);

    /**
     * @dev Adds `admin` as an administrator of this AccessServer.
     */
    function addAdministrator(address admin) external;

    /**
     * @dev Removes `admin` as an administrator of this AccessServer.
     */
    function removeAdministrator(address admin) external;

    /**
     * @dev Returns the number of administrators of this AccessServer.
     * @dev Use with `getAdminAt()` to enumerate.
     */
    function getAdminCount() external view returns (uint256);

    /**
     * @dev Returns the administrator at the index.
     * @dev Use with `getAdminCount()` to enumerate.
     */
    function getAdminAt(uint256 index) external view returns (address);

    /**
     * @dev Returns the list of administrators
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev returns the Chainalysis sanctions oracle.
     */
    function sanctionsList() external view returns (ChainalysisSanctionsList);

    /**
     * @dev Sets the Chainalysis sanctions oracle.
     * @dev setting this to the zero address disables sanctions compliance.
     * @dev Don't disable sanctions compliance unless there is some problem
     * with the sanctions oracle.
     */
    function setSanctionsList(ChainalysisSanctionsList _sanctionsList) external;

    /**
     * @dev Returns `true` if `account` is under OFAC sanctions.
     * @dev Returns `false` if sanctions compliance is disabled.
     */
    function isSanctioned(address account) external view returns (bool);

    /* ################################################################
     * Registration / Ownership
     * ##############################################################*/

    /**
     * @dev Registers the calling resource and sets the resource owner.
     * @dev Grants the default administrator role for the resource to the
     * resource owner.
     *
     * Requirements:
     * - caller SHOULD be a contract
     * - caller MUST NOT be already registered
     * - `owner` MUST NOT be the zero address
     * - `owner` MUST NOT be globally banned
     * - `owner` MUST NOT be under OFAC sanctions
     */
    function register(address owner) external;

    /**
     * @dev Returns `true` if `resource` is registered.
     */
    function isRegistered(address resource) external view returns (bool);

    /**
     * @dev Returns the owner of `resource`.
     */
    function getResourceOwner(address resource) external view returns (address);

    /**
     * @dev Returns the owner of the calling resource.
     */
    function getMyOwner() external view returns (address);

    /**
     * @dev Sets the owner for the calling resource.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` MUST be the current owner
     * - `newOwner` MUST NOT be the zero address
     * - `newOwner` MUST NOT be globally banned
     * - `newOwner` MUST NOT be banned by the calling resource
     * - `newOwner` MUST NOT be under OFAC sanctions
     * - `newOwner` MUST NOT be the current owner
     */
    function setMyOwner(address operator, address newOwner) external;

    /* ################################################################
     * Role Administration
     * ##############################################################*/

    /**
     * @dev Returns the admin role that controls `role` by default for all
     * resources. See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getGlobalRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Returns the admin role that controls `role` for a resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdminForResource(address resource, bytes32 role)
        external
        view
        returns (bytes32);

    /**
     * @dev Returns the admin role that controls `role` for the calling resource.
     * See {grantRole} and {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getMyRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on as default all
     * resources.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function setGlobalRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @dev Sets `adminRole` as ``role``'s admin role on the calling resource.
     * @dev There is no set roleAdminForResource vs setRoleAdminForMe.
     * @dev Resources must manage their own role admins or use the global
     * defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     */
    function setRoleAdmin(
        address operator,
        bytes32 role,
        bytes32 adminRole
    ) external;

    /* ################################################################
     * Checking Role Membership
     * ##############################################################*/

    /**
     * @dev Returns `true` if `account` has been granted `role` as default for
     * all resources.
     */
    function hasGlobalRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * `resource`.
     */
    function hasRole(
        address resource,
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` for `resource`.
     */
    function hasLocalRole(
        address resource,
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @dev Returns `true` if `account` has been granted `role` globally or for
     * the calling resource.
     */
    function hasRoleForMe(bytes32 role, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if account` is banned globally or from `resource`.
     */
    function isBanned(address resource, address account)
        external
        view
        returns (bool);

    /**
     * @dev Returns `true` if account` is banned globally or from the calling
     * resource.
     */
    function isBannedForMe(address account) external view returns (bool);

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * `resource`.
     */
    function checkRole(
        address resource,
        bytes32 role,
        address account
    ) external view;

    /**
     * @dev Reverts if `account` has not been granted `role` globally or for
     * the calling resource.
     */
    function checkRoleForMe(bytes32 role, address account) external view;

    /* ################################################################
     * Granting Roles
     * ##############################################################*/

    /**
     * @dev Grants `role` to `account` as default for all resources.
     * @dev Warning: This function can do silly things like applying a global
     * ban to a resource owner.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     * - If `role` is not BANNED_ROLE_NAME, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantGlobalRole(bytes32 role, address account) external;

    /**
     * @dev Grants `role` to `account` for the calling resource as `operator`.
     * @dev There is no set grantRoleForResource vs grantRoleForMe.
     * @dev Resources must manage their own roles or use the global defaults.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `grantRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - If `role` is BANNED_ROLE_NAME, `account` MUST NOT be the resource
     *   owner. You can't ban the owner.
     * - If `role` is not BANNED_ROLE_NAME, `account` MUST NOT be banned or
     *   under OFAC sanctions. Roles cannot be granted to such accounts.
     */
    function grantRole(
        address operator,
        bytes32 role,
        address account
    ) external;

    /* ################################################################
     * Revoking / Renouncing Roles
     * ##############################################################*/

    /**
     * @dev Revokes `role` as default for all resources from `account`.
     *
     * Requirements:
     * - caller MUST be an an administrator of this AccessServer
     */
    function revokeGlobalRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account` for the calling resource as
     * `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `revokeRole()` on the
     *    calling resource.
     * - `operator` MUST be the resource owner or have the role admin role
     *    for `role` on the calling resource.
     * - if `role` is DEFAULT_ADMIN_ROLE, `account` MUST NOT be the calling
     *   resource's owner. The admin role cannot be revoked from the owner.
     */
    function revokeRole(
        address operator,
        bytes32 role,
        address account
    ) external;

    /**
     * @dev Remove the default role for yourself. You will still have the role
     * for any resources where it was granted individually.
     *
     * Requirements:
     * - caller MUST have the role they are renouncing at the global level.
     * - `role` MUST NOT be BANNED_ROLE_NAME. You can't unban yourself.
     */
    function renounceRoleGlobally(bytes32 role) external;

    /**
     * @dev Renounces `role` for the calling resource as `operator`.
     *
     * Requirements:
     * - caller MUST be a registered resource
     * - `operator` SHOULD be the account that called `renounceRole()` on the
     *    calling resource.
     * - `operator` MUST have the role they are renouncing on the calling
     *   resource.
     * - if `role` is DEFAULT_ADMIN_ROLE, `operator` MUST NOT be the calling
     *   resource's owner. The owner cannot renounce the admin role.
     * - `role` MUST NOT be BANNED_ROLE_NAME. You can't unban yourself.
     */
    function renounceRole(address operator, bytes32 role) external;

    /* ################################################################
     * Enumerating Role Members
     * ##############################################################*/

    /**
     * @dev Returns the number of accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMember()` to enumerate.
     */
    function getGlobalRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set at the global
     * level.
     * @dev Use with `getGlobalRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getGlobalRoleMemberCount(role)`
     */
    function getGlobalRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the list of accounts that have `role` set at the global
     * level.
     */
    function getGlobalRoleMembers(bytes32 role) external view returns (address[] memory);

    /**
     * @dev Returns the number of accounts that have `role` set globally or for 
     * `resource`.
     * @dev Use with `getRoleMember()` to enumerate.
     */
    function getRoleMemberCount(address resource, bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set globally or for 
     * `resource`. 
     * @dev If a role has global and local members, the global members 
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be 
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getRoleMemberCount(role)`
     */
    function getRoleMember(
        address resource,
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role` set globally or for 
     * the calling resource.
     * @dev Use with `getMyRoleMember()` to enumerate.
     */
    function getMyRoleMemberCount(bytes32 role) external view returns (uint256);

    /**
     * @dev Returns one of the accounts that have `role` set globally or for 
     * the calling resource.
     * @dev If a role has global and local members, the global members 
     * will be returned first.
     * @dev If a user has the role globally and locally, the same user will be 
     * returned at two different indexes.
     * @dev If you only want locally assigned role members, start the index at
     * `getGlobalRoleMemberCount(role)`.
     * @dev Use with `getMyRoleMemberCount()` to enumerate.
     *
     * Requirements:
     * `index` MUST be >= 0 and < `getMyRoleMemberCount(role)`
     */
    function getMyRoleMember(bytes32 role, uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.24;

import "contracts/common/ViciContext.sol";
import "contracts/access/AccessEventsErrors.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's OwnableUpgradeable, 
 * moved here, renamed, and modified to use our Context and Initializable 
 * contracts so we don't have to deal with incompatibilities between OZ's
 * contracts and contracts-upgradeable packages.
 */
abstract contract ViciOwnable is ViciContext, AccessEventsErrors {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
        if(owner() != _msgSender()) revert OwnableUnauthorizedAccount(_msgSender());
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
        if(newOwner == address(0)) {
            revert OwnableInvalidOwner(newOwner);
        }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.24;
import "contracts/common/ViciInitializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 *
 * @dev This contract is a direct copy of OpenZeppelin's ContextUpgradeable, 
 * moved here, renamed, and modified to use our Initializable interface so we 
 * don't have to deal with incompatibilities between OZ'` contracts and 
 * contracts-upgradeable `
 */
abstract contract ViciContext is ViciInitializable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.24;

import "contracts/lib/ViciAddressUtils.sol";

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
 *
 * @dev This contract is a direct copy of OpenZeppelin's InitializableUpgradeable,
 * moved here, renamed, and modified to use our AddressUtils library so we
 * don't have to deal with incompatibilities between OZ'` contracts and
 * contracts-upgradeable `
 */
abstract contract ViciInitializable {
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
            (isTopLevelCall && _initialized < 1) ||
                (!ViciAddressUtils.isContract(address(this)) && _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.24;

/**
 * @dev Collection of functions related to the address type
 *
 * @dev This contract is a direct copy of OpenZeppelin's AddressUpgradeable, 
 * moved here and renamed so we don't have to deal with incompatibilities 
 * between OZ'` contracts and contracts-upgradeable `
 */
library ViciAddressUtils {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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