pragma solidity >=0.8.19;
/**
 * @title Library for access related errors.
 */

library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

pragma solidity >=0.8.19;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE = keccak256(abi.encode("xyz.voltz.OwnableStorage"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

/**
 * @title Module for setting allowed periphery address.
 */
interface IPeripheryModule {

    /**
     * @dev Sets the approved periphery address, which can pe address 0 
     * in case no periphery is allowed. Msg.sender must me the Proxy owner.
     */
    function setPeriphery(address _peripheryAddress) external;
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

import "../storage/Periphery.sol";
import "../interfaces/IPeripheryModule.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";

/**
 * @title Module for setting the allowed periphery address.
 * @dev See IPeripheryModule.
 */
contract PeripheryModule is IPeripheryModule {

    /**
     * @inheritdoc IPeripheryModule
     */
    function setPeriphery(address _peripheryAddress) external override {
        OwnableStorage.onlyOwner();
        Periphery.setPeriphery(_peripheryAddress);
    }
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

/**
 * @title Object for storing appoved periphery address.
 */
library Periphery {

    struct Data {
        /**
         * @dev Periphery address.
         */
        address peripheryAddress;
    }

    /**
     * @dev Returns the account stored at the specified account id.
     */
    function load() internal pure returns (Data storage periphery) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.Periphery"));
        assembly {
            periphery.slot := s
        }
    }

    /**
     * @dev Sets the approved Periphery address.
     */
    function setPeriphery(address _peripheryAddress) internal {
        Data storage periphery = load();
        periphery.peripheryAddress = _peripheryAddress;
    }

    /**
     * @dev Checks if given address is the periphery address.
     */
    function isPeriphery(address _peripheryAddress) internal view returns (bool) {
        Data storage periphery = load();
        return _peripheryAddress == periphery.peripheryAddress;
    }
}