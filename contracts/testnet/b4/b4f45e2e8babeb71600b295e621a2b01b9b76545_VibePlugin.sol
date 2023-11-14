// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccountRegistry} from "./account/AccountRegistry.sol";
import {PluginRegistry} from "./plugin/PluginRegistry.sol";

contract VibePlugin is PluginRegistry, AccountRegistry {
    mapping(address => bool) public registered1;

    constructor() {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./interfaces/IERC6551Registry.sol";

contract AccountRegistry is IERC6551Registry {
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        assembly {
            // Memory Layout:
            // ----
            // 0x00   0xff                           (1 byte)
            // 0x01   registry (address)             (20 bytes)
            // 0x15   salt (bytes32)                 (32 bytes)
            // 0x35   Bytecode Hash (bytes32)        (32 bytes)
            // ----
            // 0x55   ERC-1167 Constructor + Header  (20 bytes)
            // 0x69   implementation (address)       (20 bytes)
            // 0x5D   ERC-1167 Footer                (15 bytes)
            // 0x8C   salt (uint256)                 (32 bytes)
            // 0xAC   chainId (uint256)              (32 bytes)
            // 0xCC   tokenContract (address)        (32 bytes)
            // 0xEC   tokenId (uint256)              (32 bytes)

            // Silence unused variable warnings
            pop(chainId)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore8(0x00, 0xff) // 0xFF
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytecode)
            mstore(0x01, shl(96, address())) // registry address
            mstore(0x15, salt) // salt

            // Compute account address
            let computed := keccak256(0x00, 0x55)

            // If the account has not yet been deployed
            if iszero(extcodesize(computed)) {
                // Deploy account contract
                let deployed := create2(0, 0x55, 0xb7, salt)

                // Revert if the deployment fails
                if iszero(deployed) {
                    mstore(0x00, 0x20188a59) // `AccountCreationFailed()`
                    revert(0x1c, 0x04)
                }

                // Store account address in memory before salt and chainId
                mstore(0x6c, deployed)

                // Emit the ERC6551AccountCreated event
                log4(
                    0x6c,
                    0x60,
                    // `ERC6551AccountCreated(address,address,bytes32,uint256,address,uint256)`
                    0x79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf88722,
                    implementation,
                    tokenContract,
                    tokenId
                )

                // Return the account address
                return(0x6c, 0x20)
            }

            // Otherwise, return the computed account address
            mstore(0x00, shr(96, shl(96, computed)))
            return(0x00, 0x20)
        }
    }

    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address)
    {
        assembly {
            // Silence unused variable warnings
            pop(chainId)
            pop(tokenContract)
            pop(tokenId)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore8(0x00, 0xff) // 0xFF
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytecode)
            mstore(0x01, shl(96, address())) // registry address
            mstore(0x15, salt) // salt

            // Store computed account address in memory
            mstore(0x00, shr(96, shl(96, keccak256(0x00, 0x55))))

            // Return computed account address
            return(0x00, 0x20)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IPluginRegistry} from "./interfaces/IPluginRegistry.sol";
import {IPlugin} from "./interfaces/IPlugin.sol";

contract PluginRegistry is IPluginRegistry {
    mapping(address => bool) public registered;
    mapping(address => bool) public approved;
    mapping(address => address[]) public pluginTo;
    mapping(address => address) public pluginFrom;

    function registration(address template) external payable {
        require(registered[template], "PluginRegistry: Plugin already registered.");
    }

    function createPlugin(address implementation, bytes32 salt, bytes calldata data)
        external
        payable
        returns (address pluginAddress)
    {
        require(approved[implementation], "PluginRegistry: Plugin not registered.");
        require(implementation != address(0), "PluginRegistry: Non-implementation.");
        bytes20 targetBytes = bytes20(implementation);

        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            pluginAddress := create2(0, clone, 0x37, salt)
        }

        pluginFrom[pluginAddress] = implementation;
        pluginTo[implementation].push(pluginAddress);

        IPlugin(pluginAddress).pluginInit{value: msg.value}(data);
        emit PluginCreated(implementation, pluginAddress, salt, msg.sender, data);
    }

    function pluginToCount(address masterPlugin) external view returns (uint256) {
        return pluginTo[masterPlugin].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IERC6551Registry {
    /**
     * @dev The registry MUST emit the ERC6551AccountCreated event upon successful account creation.
     */
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev The registry MUST revert with AccountCreationFailed error if the create2 operation fails.
     */
    error AccountCreationFailed();

    /**
     * @dev Creates a token bound account for a non-fungible token.
     *
     * If account has already been created, returns the account address without calling create2.
     *
     * Emits ERC6551AccountCreated event.
     *
     * @return account The address of the token bound account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    /**
     * @dev Returns the computed token bound account address for a non-fungible token.
     *
     * @return account The address of the token bound account
     */
    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address account);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPluginRegistry {
    /**
     * @dev The registry must emit the PluginCreated event upon successful plug-in creation.
     */
    event PluginCreated(address indexed implementation, address plugin, bytes32 salt, address installer, bytes data);

    /**
     * @dev The registry MUST revert with PluginCreationFailed error if the create/create2 operation fails
     */
    error PluginCreationFailed();

    /**
     * @dev Creates the plugin via master plugin contract.
     *
     * @return plugin The address of the plugin address
     */
    function createPlugin(address implementation, bytes32 salt, bytes calldata data)
        external
        payable
        returns (address plugin);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPlugin {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function pluginInit(bytes calldata data) external payable;
}