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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {RolesLibrary} from "./libraries/Roles.sol";

import {IFactory} from "./interfaces/IFactory.sol";
import {IUserAgent} from "./interfaces/IUserAgent.sol";
import {IRoles} from "./interfaces/IRoles.sol";

contract Factory is IFactory {
    address public immutable roles;
    address public immutable userAgentImplementation;

    // user => userAgent[]
    mapping(address => address[]) public userAgents;

    constructor(address roles_, address userAgentImplementation_) {
        require(roles_ != address(0), "Factory: zero roles");
        require(
            userAgentImplementation_ != address(0),
            "Factory: zero userAgentImplementation"
        );

        roles = roles_;
        userAgentImplementation = userAgentImplementation_;
    }

    function createUserAgent(address owner)
        external
        returns (address userAgent)
    {
        require(owner != address(0), "Factory: zero owner");

        bytes32 role = RolesLibrary.EXECUTOR_ROLE;
        require(
            IRoles(roles).hasRole(role, msg.sender) || msg.sender == owner,
            "Factory: unauthorized"
        );

        userAgent = Clones.clone(userAgentImplementation);
        userAgents[owner].push(userAgent);
        emit UserAgentCreated(owner, userAgent);

        IUserAgent(userAgent).initialize(owner);
    }

    function getUserAgentsSlice(
        address user,
        uint256 offset,
        uint256 length
    ) external view returns (address[] memory agents) {
        agents = new address[](length);

        for (uint256 i = 0; i < length; ) {
            agents[i] = userAgents[user][offset + i];

            unchecked {
                ++i;
            }
        }
    }

    function getUserAgentsLength(address user) external view returns (uint256) {
        return userAgents[user].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    event UserAgentCreated(address indexed user, address indexed userAgent);

    function roles() external view returns (address);

    function userAgentImplementation() external view returns (address);

    function userAgents(address user, uint256 index)
        external
        view
        returns (address);

    function createUserAgent(address owner) external returns (address);

    function getUserAgentsSlice(
        address user,
        uint256 offset,
        uint256 length
    ) external view returns (address[] memory agents);

    function getUserAgentsLength(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRoles is IAccessControl {
    function EXECUTOR_ROLE() external view returns (bytes32);

    function batchGrantRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;

    function batchRevokeRole(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC2771Context} from "./IERC2771Context.sol";

interface IUserAgent is IERC2771Context {
    function exchangeRouterGMX() external view returns (address);

    function roles() external view returns (address);

    function owner() external view returns (address);

    function initialize(address owner_) external;

    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RolesLibrary {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    bytes32 public constant DEFAULT_ADMIN_ROLE = bytes32(0x00);
}