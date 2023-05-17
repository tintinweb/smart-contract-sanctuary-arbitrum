// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IPermissionsFacet.sol";

contract PermissionsFacet is IPermissionsFacet {
    error Forbidden();

    uint8 public constant ADMIN_ROLE_MASK = 1 << 1;
    bytes32 internal constant STORAGE_POSITION = keccak256("mellow.contracts.permissions.storage");

    function contractStorage() internal pure returns (IPermissionsFacet.Storage storage ds) {
        bytes32 position = STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
    }

    function initializePermissionsFacet(address admin) external override {
        IPermissionsFacet.Storage storage ds = contractStorage();
        require(!ds.initialized, "Facet already initialized");
        ds.initialized = true;
        ds.userContractRoles[admin][address(this)] = ADMIN_ROLE_MASK;
    }

    function hasPermission(
        address user,
        address contractAddress,
        bytes4 signature
    ) public view override returns (bool) {
        IPermissionsFacet.Storage storage ds = contractStorage();
        if ((ADMIN_ROLE_MASK & ds.userContractRoles[user][address(this)]) > 0) {
            return true;
        }

        if (ds.isEveryoneAllowedToCall[contractAddress][signature]) {
            return true;
        }

        return (ds.userContractRoles[user][contractAddress] & ds.signatureRoles[signature]) != 0;
    }

    function requirePermission(address user, address contractAddress, bytes4 signature) external view override {
        if (!hasPermission(user, contractAddress, signature)) {
            revert Forbidden();
        }
    }

    modifier onlyAdmin() {
        IPermissionsFacet.Storage storage ds = contractStorage();
        if ((ds.userContractRoles[msg.sender][address(this)] & ADMIN_ROLE_MASK) == 0) {
            revert Forbidden();
        }
        _;
    }

    function setGeneralRole(address contractAddress, bytes4 signature, bool value) external override onlyAdmin {
        IPermissionsFacet.Storage storage ds = contractStorage();
        ds.isEveryoneAllowedToCall[contractAddress][signature] = value;
    }

    function grantUserContractRole(uint8 role, address user, address contractAddress) external override onlyAdmin {
        IPermissionsFacet.Storage storage ds = contractStorage();
        ds.userContractRoles[user][contractAddress] |= 1 << role;
    }

    function revokeUserContractRole(uint8 role, address user, address contractAddress) external override onlyAdmin {
        IPermissionsFacet.Storage storage ds = contractStorage();
        if (contractAddress == address(this) && (1 << role) == ADMIN_ROLE_MASK) {
            require(user == msg.sender, "User can revoke the admin role only from himself");
        }
        ds.userContractRoles[user][contractAddress] &= ~(1 << role);
    }

    function grantSignatureRole(uint8 role, bytes4 signature) external override onlyAdmin {
        IPermissionsFacet.Storage storage ds = contractStorage();
        ds.signatureRoles[signature] |= 1 << role;
    }

    function revokeSignatureRole(uint8 role, bytes4 signature) external override onlyAdmin {
        IPermissionsFacet.Storage storage ds = contractStorage();
        ds.signatureRoles[signature] &= ~(1 << role);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPermissionsFacet {
    struct Storage {
        bool initialized;
        mapping(address => mapping(address => uint256)) userContractRoles;
        mapping(bytes4 => uint256) signatureRoles;
        mapping(address => mapping(bytes4 => bool)) isEveryoneAllowedToCall;
    }

    function initializePermissionsFacet(address admin) external;

    function hasPermission(address user, address contractAddress, bytes4 signature) external view returns (bool);

    function requirePermission(address user, address contractAddress, bytes4 signature) external;

    function setGeneralRole(address contractAddress, bytes4 signature, bool value) external;

    function grantUserContractRole(uint8 role, address user, address contractAddress) external;

    function revokeUserContractRole(uint8 role, address user, address contractAddress) external;

    function grantSignatureRole(uint8 role, bytes4 signature) external;

    function revokeSignatureRole(uint8 role, bytes4 signature) external;
}