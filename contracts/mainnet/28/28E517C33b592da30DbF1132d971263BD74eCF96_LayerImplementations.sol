// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for the Index contract.
interface IndexInterface {
    /// @notice Get the master address from the Index contract.
    /// @return The address of the master.
    function master() external view returns (address);
}

/// @title Contract for setting up default and specific function implementations.
contract Setup {
    /// @notice The default implementation address.
    address public defaultImplementation;

    mapping (bytes4 => address) internal sigImplementations;

    mapping (address => bytes4[]) internal implementationSigs;
}

/// @title Contract for managing and updating function implementations.
contract Implementations is Setup {
    /// @notice Event emitted when the default implementation is set.
    event LogSetDefaultImplementation(address indexed oldImplementation, address indexed newImplementation);
    
    /// @notice Event emitted when a new implementation is added.
    event LogAddImplementation(address indexed implementation, bytes4[] sigs);
    
    /// @notice Event emitted when an implementation is removed.
    event LogRemoveImplementation(address indexed implementation, bytes4[] sigs);

    /// @notice The Index contract interface.
    IndexInterface immutable public layerIndex;

    /// @param _layerIndex The address of the Index contract.
    constructor(address _layerIndex) {
        layerIndex = IndexInterface(_layerIndex);
    }

    /// @notice Modifier to check if the caller is the master address.
    modifier isMaster() {
        require(msg.sender == layerIndex.master(), "Implementations: not-master");
        _;
    }

    /// @notice Set the default implementation address.
    /// @param _defaultImplementation The address of the new default implementation.
    function setDefaultImplementation(address _defaultImplementation) external isMaster {
        require(_defaultImplementation != address(0), "Implementations: _defaultImplementation address not valid");
        require(_defaultImplementation != defaultImplementation, "Implementations: _defaultImplementation cannot be same");
        emit LogSetDefaultImplementation(defaultImplementation, _defaultImplementation);
        defaultImplementation = _defaultImplementation;
    }

    /// @notice Add a new implementation.
    /// @param _implementation The address of the new implementation.
    /// @param _sigs The function signatures that should use this implementation.
    function addImplementation(address _implementation, bytes4[] calldata _sigs) external isMaster {
        require(_implementation != address(0), "Implementations: _implementation not valid.");
        require(implementationSigs[_implementation].length == 0, "Implementations: _implementation already added.");
        for (uint i = 0; i < _sigs.length; i++) {
            bytes4 _sig = _sigs[i];
            require(sigImplementations[_sig] == address(0), "Implementations: _sig already added");
            sigImplementations[_sig] = _implementation;
        }
        implementationSigs[_implementation] = _sigs;
        emit LogAddImplementation(_implementation, _sigs);
    }

    /// @notice Remove an implementation.
    /// @param _implementation The address of the implementation to remove.
    function removeImplementation(address _implementation) external isMaster {
        require(_implementation != address(0), "Implementations: _implementation not valid.");
        require(implementationSigs[_implementation].length != 0, "Implementations: _implementation not found.");
        bytes4[] memory sigs = implementationSigs[_implementation];
        for (uint i = 0; i < sigs.length; i++) {
            bytes4 sig = sigs[i];
            delete sigImplementations[sig];
        }
        delete implementationSigs[_implementation];
        emit LogRemoveImplementation(_implementation, sigs);
    }
}

/// @title Contract for querying function implementations.
contract LayerImplementations is Implementations {
    /// @param _layerIndex The address of the Index contract.
    constructor(address _layerIndex) public Implementations(_layerIndex) {}

    /// @notice Get the implementation address for a function signature.
    /// @param _sig The function signature to query.
    /// @return The address of the implementation.
    function getImplementation(bytes4 _sig) external view returns (address) {
        address _implementation = sigImplementations[_sig];
        return _implementation == address(0) ? defaultImplementation : _implementation;
    }

    /// @notice Get all function signatures for a given implementation address.
    /// @param _impl The implementation address to query.
    /// @return An array of function signatures.
    function getImplementationSigs(address _impl) external view returns (bytes4[] memory) {
        return implementationSigs[_impl];
    }

    /// @notice Get the implementation address for a given function signature.
    /// @param _sig The function signature to query.
    /// @return The address of the implementation.
    function getSigImplementation(bytes4 _sig) external view returns (address) {
        return sigImplementations[_sig];
    }
}