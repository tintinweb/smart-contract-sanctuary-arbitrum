// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "O: caller must be the owner");
        _;
    }

    constructor() {
        _setOwner(msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "O: new owner must not be the zero address"
        );

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./base/Ownable.sol";
import "../interface/IModuleManager.sol";
import "../interface/IModuleRegistry.sol";
import "../utils/Address.sol";

contract ModuleManager is Ownable, IModuleManager {
    using Address for address;

    bool internal _isInitialized;
    IModuleRegistry internal immutable _registry;

    mapping(address => bool) internal _modules;
    mapping(bytes4 => address) internal _delegates;

    constructor(address registry) {
        require(
            registry.isContract(),
            "MM: registry must be an existing contract address"
        );

        _isInitialized = true;
        _registry = IModuleRegistry(registry);
    }

    function initialize(address initialOwner) external {
        require(!_isInitialized, "MM: contract is already initialized");

        _isInitialized = true;

        _setOwner(initialOwner);
    }

    function isModuleEnabled(address module)
        external
        view
        override
        returns (bool)
    {
        return _modules[module];
    }

    function enableModule(address module) external override onlyOwner {
        require(!_modules[module], "MM: module is already enabled");
        require(
            _registry.isModuleRegistered(module),
            "MM: module must be registered"
        );

        _modules[module] = true;

        emit ModuleEnabled(module);
    }

    function disableModule(address module) external override onlyOwner {
        require(_modules[module], "MM: module is already disabled");

        delete _modules[module];

        emit ModuleDisabled(module);
    }

    function getDelegate(bytes4 methodID)
        external
        view
        override
        returns (address)
    {
        return _delegates[methodID];
    }

    function enableDelegation(bytes4 methodID, address module)
        external
        override
        onlyOwner
    {
        require(
            _delegates[methodID] != module,
            "MM: delegation is already enabled"
        );
        require(_modules[module], "MM: module must be enabled");

        _delegates[methodID] = module;

        emit DelegationEnabled(methodID, module);
    }

    function disableDelegation(bytes4 methodID) external override onlyOwner {
        require(
            _delegates[methodID] != address(0),
            "MM: delegation is already disabled"
        );

        delete _delegates[methodID];

        emit DelegationDisabled(methodID);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IModuleManager {
    event ModuleEnabled(address indexed module);

    event ModuleDisabled(address indexed module);

    event DelegationEnabled(bytes4 indexed methodID, address indexed module);

    event DelegationDisabled(bytes4 indexed methodID);

    function initialize(address initialOwner) external;

    function isModuleEnabled(address module) external view returns (bool);

    function enableModule(address module) external;

    function disableModule(address module) external;

    function getDelegate(bytes4 methodID) external view returns (address);

    function enableDelegation(bytes4 methodID, address module) external;

    function disableDelegation(bytes4 methodID) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IModuleRegistry {
    event ModuleRegistered(address indexed module);

    event ModuleDeregistered(address indexed module);

    function isModuleRegistered(address module) external view returns (bool);

    function registerModule(address module) external;

    function deregisterModule(address module) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

library Address {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(addr)
        }

        return size > 0;
    }
}