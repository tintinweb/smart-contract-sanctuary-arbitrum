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

https://github.com/Voltz-Protocol/v2-core/blob/main/products/dated-irs/LICENSE
*/
pragma solidity >=0.8.19;

import "../storage/MarketConfiguration.sol";

/**
 * @title Module for configuring a market
 * @notice Allows the owner to configure the quote token of the given market
 */

interface IMarketConfigurationModule {
    /**
     * @notice Emitted when a market configuration is created or updated
     * @param config The object with the newly configured details.
     * @param blockTimestamp The current block timestamp.
     */
    event MarketConfigured(MarketConfiguration.Data config, uint256 blockTimestamp);

    /**
     * @notice Creates or updates the market configuration
     * @param config The MarketConfiguration object describing the new configuration.
     *
     * Requirements:
     *
     * - `msg.sender` must be the owner of the dated irs product.
     *
     * Emits a {MarketConfigured} event.
     *
     */
    function configureMarket(MarketConfiguration.Data memory config) external;

    /**
     * @notice Returns the market configuration
     * @return config The configuration object describing the market
     */
    function getMarketConfiguration(uint128 irsMarketId) external view returns (MarketConfiguration.Data memory config);
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/products/dated-irs/LICENSE
*/
pragma solidity >=0.8.19;

import "../interfaces/IMarketConfigurationModule.sol";
import "../storage/MarketConfiguration.sol";
import "@voltz-protocol/util-contracts/src/storage/OwnableStorage.sol";

/**
 * @title Module for configuring a market
 * @dev See IMarketConfigurationModule.
 */
contract MarketConfigurationModule is IMarketConfigurationModule {
    using MarketConfiguration for MarketConfiguration.Data;

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function configureMarket(MarketConfiguration.Data memory config) external {
        OwnableStorage.onlyOwner();

        MarketConfiguration.set(config);

        emit MarketConfigured(config, block.timestamp);
    }

    /**
     * @inheritdoc IMarketConfigurationModule
     */
    function getMarketConfiguration(uint128 irsMarketId) external pure returns (MarketConfiguration.Data memory config) {
        return MarketConfiguration.load(irsMarketId);
    }
}

/*
Licensed under the Voltz v2 License (the "License"); you 
may not use this file except in compliance with the License.
You may obtain a copy of the License at

https://github.com/Voltz-Protocol/v2-core/blob/main/products/dated-irs/LICENSE
*/
pragma solidity >=0.8.19;

// do we need this?
/**
 * @title Tracks configurations for dated irs markets
 */
library MarketConfiguration {
    error MarketAlreadyExists(uint128 marketId);

    struct Data {
        /**
         * @dev Id fo a given interest rate swap market
         */
        uint128 marketId;
        /**
         * @dev Address of the quote token.
         * @dev IRS contracts settle in the quote token
         * i.e. settlement cashflows and unrealized pnls are in quote token terms
         */
        address quoteToken;
    }

    /**
     * @dev Loads the MarketConfiguration object for the given dated irs market id
     * @param irsMarketId Id of the IRS market that we want to load the configurations for
     * @return datedIRSMarketConfig The CollateralConfiguration object.
     */
    function load(uint128 irsMarketId) internal pure returns (Data storage datedIRSMarketConfig) {
        bytes32 s = keccak256(abi.encode("xyz.voltz.MarketConfiguration", irsMarketId));
        assembly {
            datedIRSMarketConfig.slot := s
        }
    }

    /**
     * @dev Configures a dated interest rate swap market
     * @param config The MarketConfiguration object with all the settings for the irs market being configured.
     */
    function set(Data memory config) internal {
        // todo: replace this by custom error (e.g. ZERO_ADDRESS) (IR)
        require(config.quoteToken != address(0), "Invalid Market");

        Data storage storedConfig = load(config.marketId);

        if (storedConfig.quoteToken != address(0)) {
            revert MarketAlreadyExists(config.marketId);
        }

        storedConfig.marketId = config.marketId;
        storedConfig.quoteToken = config.quoteToken;
    }
}