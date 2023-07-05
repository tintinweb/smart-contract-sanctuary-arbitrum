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

import "../storage/AccessPassConfiguration.sol";

/**
 * @title Module for configuring the access pass nft
 * @notice Allows the owner to configure the access pass nft
 */
interface IAccessPassConfigurationModule {

    /**
     * @notice Emitted when the access pass configuration is created or updated
     * @param config The object with the newly configured details.
     * @param blockTimestamp The current block timestamp.
     */
    event AccessPassConfigured(AccessPassConfiguration.Data config, uint256 blockTimestamp);


    /**
     * @notice Creates or updates the access pass configuration
     * @param config The AccessPassConfiguration object describing the new configuration.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the protocol.
     *
     * Emits a {AccessPassConfigured} event.
     *
     */
    function configureAccessPass(AccessPassConfiguration.Data memory config) external;


    /**
     * @notice Returns detailed information on protocol-wide risk configuration
     * @return config The configuration object describing the protocol-wide risk configuration
     */
    function getAccessPassConfiguration() external pure returns (AccessPassConfiguration.Data memory config);
}

/*
Licensed under the Voltz v2 License (the "License"); you
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/core/LICENSE
*/
pragma solidity >=0.8.19;

import "../interfaces/IAccessPassConfigurationModule.sol";
import "../storage/AccessPassConfiguration.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";

/**
 * @title Module for access pass nft configuration
 * @dev See IAccessPassConfigurationModule
*/
contract AccessPassConfigurationModule is IAccessPassConfigurationModule {

    /**
     * @inheritdoc IAccessPassConfigurationModule
     */
    function configureAccessPass(AccessPassConfiguration.Data memory config) external override {
        OwnableStorage.onlyOwner();
        AccessPassConfiguration.set(config);
        emit AccessPassConfigured(config, block.timestamp);
    }


    /**
     * @inheritdoc IAccessPassConfigurationModule
     */
    function getAccessPassConfiguration() external pure returns (AccessPassConfiguration.Data memory config) {
        return AccessPassConfiguration.load();
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
 * @title Tracks V2 Access Pass NFT and providers helpers to interact with it
 */
library AccessPassConfiguration {

    struct Data {
        address accessPassNFTAddress;
    }

    /**
     * @dev Loads the AccessPassConfiguration object.
     * @return config The AccessPassConfiguration object.
     */
    function load() internal pure returns (Data storage config) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.AccessPassConfiguration"));
        assembly {
            config.slot := s
        }
    }

     /**
     * @dev Sets the access pass configuration
     * @param config The AccessPassConfiguration object with access pass nft address
     */
    function set(Data memory config) internal {
        Data storage storedConfig = load();
        storedConfig.accessPassNFTAddress = config.accessPassNFTAddress;
    }

}