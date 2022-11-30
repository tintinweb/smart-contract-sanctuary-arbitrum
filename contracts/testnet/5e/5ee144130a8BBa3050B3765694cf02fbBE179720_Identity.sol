// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./Proxy.sol";
import "./interface/IIdentity.sol";
import "./interface/IModuleManager.sol";
import "./utils/Address.sol";

contract Identity is IIdentity {
    using Address for address;

    address public owner;

    bool internal _isInitialized;
    IModuleManager internal _moduleManager;

    modifier onlyModule() {
        require(
            _moduleManager.isModuleEnabled(msg.sender),
            "I: caller must be an enabled module"
        );
        _;
    }

    function initialize(
        address initialOwner,
        address moduleManagerImpl,
        address[] calldata modules,
        address[] calldata delegateModules,
        bytes4[] calldata delegateMethodIDs
    ) external {
        require(!_isInitialized, "I: contract is already initialized");
        require(
            delegateModules.length == delegateMethodIDs.length,
            "I: delegate modules length and delegate method ids length do not match"
        );

        _isInitialized = true;

        IModuleManager initialModuleManager = IModuleManager(
            address(new Proxy(moduleManagerImpl))
        );

        initialModuleManager.initialize(address(this));

        for (uint256 i = 0; i < modules.length; i++) {
            initialModuleManager.enableModule(modules[i]);
        }
        for (uint256 j = 0; j < delegateModules.length; j++) {
            initialModuleManager.enableDelegation(
                delegateMethodIDs[j],
                delegateModules[j]
            );
        }

        _setOwner(initialOwner);
        _setModuleManager(address(initialModuleManager));
    }

    function setOwner(address newOwner) external override onlyModule {
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        require(
            newOwner != address(0),
            "I: owner must not be the zero address"
        );

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function moduleManager() external view override returns (address) {
        return address(_moduleManager);
    }

    function setModuleManager(address newModuleManager)
        external
        override
        onlyModule
    {
        _setModuleManager(newModuleManager);
    }

    function _setModuleManager(address newModuleManager) internal {
        require(
            newModuleManager.isContract(),
            "I: module manager must be an existing contract address"
        );

        address oldModuleManager = address(_moduleManager);
        _moduleManager = IModuleManager(newModuleManager);

        emit ModuleManagerSwitched(oldModuleManager, newModuleManager);
    }

    function isModuleEnabled(address module) external view returns (bool) {
        return _moduleManager.isModuleEnabled(module);
    }

    function getDelegate(bytes4 methodID) external view returns (address) {
        return _moduleManager.getDelegate(methodID);
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external override onlyModule returns (bytes memory) {
        require(
            to != address(0),
            "I: execution target must not be the zero address"
        );

        (bool success, bytes memory result) = to.call{value: value}(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit Executed(msg.sender, to, value, data);

        return result;
    }

    fallback() external payable {
        address module = _moduleManager.getDelegate(msg.sig);

        require(module != address(0), "I: unsupported method");

        _delegate(module);
    }

    receive() external payable {}

    function _delegate(address module) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := call(gas(), module, 0, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

interface IIdentity {
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    event ModuleManagerSwitched(
        address indexed oldModuleManager,
        address indexed newModuleManager
    );

    event Executed(
        address indexed module,
        address indexed to,
        uint256 value,
        bytes data
    );

    function owner() external view returns (address);

    function setOwner(address newOwner) external;

    function moduleManager() external view returns (address);

    function setModuleManager(address newModuleManager) external;

    function isModuleEnabled(address module) external view returns (bool);

    function getDelegate(bytes4 methodID) external view returns (address);

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bytes memory);
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

// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
pragma solidity 0.8.17;

import "./utils/Address.sol";

contract Proxy {
    using Address for address;

    address public immutable implementation;

    constructor(address impl) {
        require(
            impl.isContract(),
            "P: implementation must be an existing contract address"
        );

        implementation = impl;
    }

    fallback() external payable {
        _delegateCall(implementation);
    }

    receive() external payable {
        _delegateCall(implementation);
    }

    function _delegateCall(address impl) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
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