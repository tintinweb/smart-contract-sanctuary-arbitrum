// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title LayerConnectors
 * @dev This contract serves as a registry for Connectors. It allows for the addition, updating, and removal of connectors.
 */

/**
 * @dev Interface for the LayerIndex contract to fetch the master address.
 */
interface IndexInterface {
    function master() external view returns (address);
}

/**
 * @dev Interface for the Connector to fetch its name.
 */
interface ConnectorInterface {
    function name() external view returns (string memory);
}

/**
 * @title Controllers
 * @dev This contract manages the chief controllers who have the authority to add, update, or remove connectors.
 */
contract Controllers {

    event LogController(address indexed addr, bool indexed isChief);

    // Address of the LayerIndex contract.
    address public immutable layerIndex;

    constructor(address _layerIndex) {
        layerIndex = _layerIndex;
    }

    // Mapping to check if an address is a chief.
    mapping(address => bool) public chief;
    // Mapping of connector names to their addresses.
    mapping(string => address) public connectors;

    /**
     * @dev Modifier to ensure the caller is a chief or the master of the LayerIndex.
     */
    modifier isChief {
        require(chief[msg.sender] || msg.sender == IndexInterface(layerIndex).master(), "not-an-chief");
        _;
    }

    /**
     * @dev Enables or disables a chief controller.
     * @param _chiefAddress Address of the chief to be toggled.
     */
    function toggleChief(address _chiefAddress) external {
        require(msg.sender == IndexInterface(layerIndex).master(), "toggleChief: not-master");
        chief[_chiefAddress] = !chief[_chiefAddress];
        emit LogController(_chiefAddress, chief[_chiefAddress]);
    }
}

/**
 * @title LayerConnectors
 * @dev Main contract for managing and interacting with connectors.
 */
contract LayerConnectors is Controllers {

    event LogConnectorAdded(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );
    event LogConnectorUpdated(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed oldConnector,
        address indexed newConnector
    );
    event LogConnectorRemoved(
        bytes32 indexed connectorNameHash,
        string connectorName,
        address indexed connector
    );

    constructor(address _layerIndex) public Controllers(_layerIndex) {}

    /**
     * @dev Adds new connectors to the registry.
     * @param _connectorNames Names of the connectors to be added.
     * @param _connectors Addresses of the connectors to be added.
     */
    function addConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external isChief {
        require(_connectorNames.length == _connectors.length, "addConnectors: not same length");
        for (uint i = 0; i < _connectors.length; i++) {
            require(connectors[_connectorNames[i]] == address(0), "addConnectors: _connectorName added already");
            require(_connectors[i] != address(0), "addConnectors: _connectors address not valid");
            ConnectorInterface(_connectors[i]).name(); // Verifying if connector has function name()
            connectors[_connectorNames[i]] = _connectors[i];
            emit LogConnectorAdded(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], _connectors[i]);
        }
    }

    /**
     * @dev Updates existing connectors in the registry.
     * @param _connectorNames Names of the connectors to be updated.
     * @param _connectors New addresses for the connectors.
     */
    function updateConnectors(string[] calldata _connectorNames, address[] calldata _connectors) external isChief {
        require(_connectorNames.length == _connectors.length, "updateConnectors: not same length");
        for (uint i = 0; i < _connectors.length; i++) {
            require(connectors[_connectorNames[i]] != address(0), "updateConnectors: _connectorName not added to update");
            require(_connectors[i] != address(0), "updateConnectors: _connector address is not valid");
            ConnectorInterface(_connectors[i]).name(); // Verifying if connector has function name()
            emit LogConnectorUpdated(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], connectors[_connectorNames[i]], _connectors[i]);
            connectors[_connectorNames[i]] = _connectors[i];
        }
    }

    /**
     * @dev Removes connectors from the registry.
     * @param _connectorNames Names of the connectors to be removed.
     */
    function removeConnectors(string[] calldata _connectorNames) external isChief {
        for (uint i = 0; i < _connectorNames.length; i++) {
            require(connectors[_connectorNames[i]] != address(0), "removeConnectors: _connectorName not added to update");
            emit LogConnectorRemoved(keccak256(abi.encodePacked(_connectorNames[i])), _connectorNames[i], connectors[_connectorNames[i]]);
            delete connectors[_connectorNames[i]];
        }
    }

    /**
     * @dev Checks if the provided connector names are registered and returns their addresses.
     * @param _connectorNames Names of the connectors to be checked.
     * @return isOk Boolean indicating if all connectors are registered.
     * @return _connectors Addresses of the checked connectors.
     */
    function isConnectors(string[] calldata _connectorNames) external view returns (bool isOk, address[] memory _connectors) {
        isOk = true;
        uint len = _connectorNames.length;
        _connectors = new address[](len);
        for (uint i = 0; i < _connectors.length; i++) {
            _connectors[i] = connectors[_connectorNames[i]];
            if (_connectors[i] == address(0)) {
                isOk = false;
                break;
            }
        }
    }
}