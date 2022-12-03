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
import "../interface/IModuleRegistry.sol";
import "../utils/Address.sol";

contract ModuleRegistry is Ownable, IModuleRegistry {
    using Address for address;

    mapping(address => bool) internal _modules;

    function isModuleRegistered(address module)
        external
        view
        override
        returns (bool)
    {
        return _modules[module];
    }

    function registerModule(address module) external override onlyOwner {
        require(
            module.isContract(),
            "MR: module must be an existing contract address"
        );
        require(!_modules[module], "MR: module is already registered");

        _modules[module] = true;

        emit ModuleRegistered(module);
    }

    function deregisterModule(address module) external override onlyOwner {
        require(_modules[module], "MR: module is already deregistered");

        delete _modules[module];

        emit ModuleDeregistered(module);
    }
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