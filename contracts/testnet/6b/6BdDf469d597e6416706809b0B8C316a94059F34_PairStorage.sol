// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./AccessControl.sol";

contract PairStorage {
    constructor(AccessControl _accessControl) {
        accessControl = _accessControl;
    }

    AccessControl immutable accessControl;

    mapping(bytes32 => address) public pairs;

    function getPair(bytes32 pair) public view returns (address) {
        return pairs[pair];
    }

    function addPair(bytes32 pair, address pairAddress) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to add a pair"
        );
        pairs[pair] = pairAddress;
    }

    function deletePair(bytes32 pair) public {
        require(
            accessControl.isAdmin(msg.sender),
            "PairStorage: must have admin role to delete a pair"
        );
        delete pairs[pair];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract AccessControl {
    // The constructor sets up the initial roles for the owner
    constructor() {
        _setupRole(OWNER, msg.sender);
    }

    // The available roles
    bytes32 public OWNER;
    bytes32 public ADMIN;
    bytes32 public USER;

    // Mapping of roles to addresses
    mapping(bytes32 => mapping(address => bool)) public roles;

    // Mapping of addresses to roles
    mapping(address => bytes32) public userRoles;

    // Mapping of addresses to whether they are blacklisted
    mapping(address => bool) public blacklist;

    // Modifier to restrict access to only owner account
    modifier onlyOwner() {
        require(
            _hasRole(OWNER, msg.sender),
            "AccessControl: must have owner role"
        );
        _;
    }

    // Modifier to restrict access to only admins
    modifier onlyAdmin() {
        require(
            _hasRole(ADMIN, msg.sender),
            "AccessControl: must have admin role"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            !isBlacklisted(msg.sender),
            "AccessControl: account is blacklisted"
        );
        _;
    }

    // Set up a role for an account
    function _setupRole(bytes32 role, address account) internal {
        roles[role][account] = true;
        userRoles[account] = role;
    }

    // Remove a role from an account
    function _removeRole(bytes32 role, address account) internal {
        roles[role][account] = false;
        userRoles[account] = bytes32(0);
    }

    // Check if an account has a specific role
    function _hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return roles[role][account];
    }

    // Add a user to the contract
    function addUser(address account) public notBlacklisted {
        _setupRole(USER, account);
    }

    // Remove a user from the contract
    function removeUser(address account) public onlyAdmin {
        blacklist[account] = true;
        _removeRole(USER, account);
    }

    // Adds an admin to the contract
    function addAdmin(address account) public onlyOwner {
        _setupRole(ADMIN, account);
    }

    // Removes an admin from the contract
    function removeAdmin(address account) public onlyOwner {
        _removeRole(ADMIN, account);
    }

    // Check if an account is a user
    function isUser(address account) public view returns (bool) {
        return _hasRole(USER, account);
    }

    // Check if an account is an admin
    function isAdmin(address account) public view returns (bool) {
        return _hasRole(ADMIN, account);
    }

    // check if an account is a owner
    function isOwner(address account) public view returns (bool) {
        return _hasRole(OWNER, account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
}