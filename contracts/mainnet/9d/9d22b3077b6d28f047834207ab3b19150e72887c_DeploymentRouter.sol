// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;


interface ISafe {
    function enableModule(address _module) external;
}

// Interface for the Factory contract.
interface IFactory {
    // Declares a function to deploy a new signer instance.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @param _modules: An array of module addresses to enable for the safe.
    // @return bool: Returns true if deployment is successful.
    function deploy(bytes32 _hash, uint256 _x, uint256 _y, address[] calldata _modules) external returns (bool);
}

/// @title AddModulesLib
contract DeploymentRouter{
    // Immutable address of the Factory contract.
    address public immutable factoryProxy;

    // Constructor to set the Factory contract's address.
    // @param _factory: The address of the Factory contract.
    constructor(address _factoryProxy) {
        factoryProxy = _factoryProxy;
    }
    
    function setupSafe(bytes32 _hash, uint256 _x, uint256 _y, address[] calldata _modules) public returns (bool) {
        // Deploys a new signer instance.
        return _deploySigner(_hash, _x, _y, _modules);
    }

    // Function to deploy a signer through the Factory contract.
    // This allows external contracts or addresses to request signer deployments.
    // @param _hash: A unique identifier for the signer.
    // @param _x: X-coordinate of the public key.
    // @param _y: Y-coordinate of the public key.
    // @param _modules: An array of module addresses to enable for the safe.
    // @return bool: Returns true if deployment is successful.
    function _deploySigner(bytes32 _hash, uint256 _x, uint256 _y, address[] memory _modules) internal returns (bool) {
        // Calls the deploy function of the Factory contract.
        // Enables the modules.
        _enableModules(_modules);
        return IFactory(factoryProxy).deploy(_hash, _x, _y, _modules);
    }

    function _enableModules(address[] memory _modules) internal { 
        for (uint256 i = _modules.length; i > 0; i--) {
            // This call will only work properly if used via a delegatecall
            // from the Safe contract.
            ISafe(address(this)).enableModule(_modules[i - 1]);
        }
    }
}