// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/**
 * @title NodeRegistry
 * @author Lifeworld
 */
contract NodeRegistry is INodeRegistry {

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /**
     * @dev Emit an event when a new node is registered
     *
     *      NodeIds provide targets for messaging strategies. To identify
     *      different types of nodes, you can emit a bytes32 hash upon its registration
     *
     * @param sender        Address of the account calling `register()`
     * @param schema        Schema to register node as
     * @param nodeId        NodeId registered in transaction
     * @param messages      Messages to send to node during registration
     */
    event Register(address indexed sender, bytes32 indexed schema, uint256 indexed nodeId, bytes[] messages);

    /**
     * @dev Emit an event when a new update is sent
     *
     *      Updates allow for the transmission of data to existing nodes
     *
     * @param sender        Address of the account calling `update()`
     * @param nodeId        Id of node to target
     * @param messages      Messages to send to node during update
     */
    event Update(address indexed sender, uint256 indexed nodeId, bytes[] messages);

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    uint256 public nodeCount;

    //////////////////////////////////////////////////
    // REGISTER
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function register(bytes32 schema, bytes[] calldata messages) external returns (uint256 nodeId) {
        // Increments nodeCount
        nodeId = ++nodeCount;
        emit Register(msg.sender, schema, nodeId, messages);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function registerBatch(bytes32[] calldata schemas, bytes[][] calldata messages) external returns (uint256[] memory nodeIds) {
        // Cache msg.sender
        address sender = msg.sender;
        // Create array to track nodeIds for return
        nodeIds = new uint256[](schemas.length);
        // Loop through data
        for (uint256 i; i < schemas.length; ++i) {
            // Copy nodeId to return variable
            nodeIds[i] = ++nodeCount;
            // Increments nodeCount
            emit Register(sender, schemas[i], nodeIds[i], messages[i]);
        }
    }

    //////////////////////////////////////////////////
    // UPDATE
    //////////////////////////////////////////////////

    /**
     * @inheritdoc INodeRegistry
     */
    function update(uint256 nodeId, bytes[] calldata messages) external {
        emit Update(msg.sender, nodeId, messages);
    }

    /**
     * @inheritdoc INodeRegistry
     */
    function updateBatch(uint256[] calldata nodeIds, bytes[][] calldata messages) external {
        // Cache msg.sender
        address sender = msg.sender; 
        // Loop through data                
        for (uint256 i; i < nodeIds.length; ++i) {
            // Emit Message event
            emit Update(sender, nodeIds[i], messages[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface INodeRegistry {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Tracks number of nodes registered
     */
    function nodeCount() external view returns (uint256);

    //////////////////////////////////////////////////
    // REGISTER
    //////////////////////////////////////////////////

    /**
     * @notice Initialize a new node by incrementing the nodeCount and emitting data
     *         in association with the initialization event
     * 
     * @dev Callable by anyone
     *
     * @param schema        Schema initialize node as
     * @param messages      Messages to send to initialized node
     */
    function register(bytes32 schema, bytes[] calldata messages) external returns (uint256);

    /**
     * @notice Batch version of `register`
     *
     * @dev Will revert messages.length < schemas.length !!
     *
     * @param schemas       Schemas to register nodes as
     * @param messages      Messages to send to registered nodes
     */
    function registerBatch(bytes32[] calldata schemas, bytes[][] calldata messages) external returns (uint256[] memory);

    //////////////////////////////////////////////////
    // UPDATE
    //////////////////////////////////////////////////

    /**
     * @notice Update a node by emitting data in association with a given nodeId
     *
     * @dev Callable by anyone
     *
     * @param nodeId        Id of node to target
     * @param messages      Messages to send to target node
     */
    function update(uint256 nodeId, bytes[] calldata messages) external;

    /**
     * @notice Batch version of `update`
     *
     * @dev Will revert messages.length < schemas.length !!
     *
     * @param nodeIds       Ids of nodes to target
     * @param messages      Messages to send to target nodes
     */
    function updateBatch(uint256[] calldata nodeIds, bytes[][] calldata messages) external;
}