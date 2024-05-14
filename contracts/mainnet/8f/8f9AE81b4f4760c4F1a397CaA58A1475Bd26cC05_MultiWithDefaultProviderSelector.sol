//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface IProviderSelector {
    /**
     * @dev Used to make sure the function is only called by the teleport contract.
     */
    error OnlyTeleportCalls();

    function isValidProvider(address provider) external returns (bool);

    function getProvider(
        uint8 targetChainId_,
        bytes calldata transmissionReceiver_,
        bytes32 dAppId_,
        bytes calldata payload_
    ) external view returns (address);

    function config(bytes calldata configData) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import {IProviderSelector} from "./interfaces/IProviderSelector.sol";

contract MultiWithDefaultProviderSelector is IProviderSelector {
    // The list of configured providers
    address private _currentProvider;

    // The teleport address
    address public immutable TELEPORT_ADDRESS;

    mapping(address => bool) public validProviders;

    /**
     * @dev Emitted when a new provider is added.
     * @param provider The address of the added provider.
     */
    event ProviderAdded(address provider);
    /**
     * @dev Emitted when a provider is removed from the contract.
     * @param provider The address of the removed provider.
     */
    event ProviderRemoved(address provider);

    /**
     * @dev Emitted when the default provider is updated in the contract.
     * @param provider The address of the new default provider.
     */
    event DefaultProviderUpdated(address provider);

    //
    /**
     * @dev Used to make sure the router address is not the zero address.
     */
    error ZeroAddressProvider();

    /**
     * @dev Used to make sure the teleport address is not the zero address.
     */
    error ZeroAddressTeleport();

    /**
     * @dev Used to make sure that the provider exists.
     */
    error ProviderNotFound();

    /**
     * @dev Modifier to restrict access to functions only to the Teleport facet.
     */
    modifier onlyTeleport() {
        if (msg.sender != TELEPORT_ADDRESS) revert OnlyTeleportCalls();
        _;
    }

    // Constructor with the initial provider to be used and the teleport address
    constructor(address initialProvider, address teleportAddress_) {
        if (initialProvider == address(0)) revert ZeroAddressProvider();

        if (teleportAddress_ == address(0)) revert ZeroAddressTeleport();

        _currentProvider = initialProvider;
        TELEPORT_ADDRESS = teleportAddress_;

        validProviders[initialProvider] = true;
    }

    /**
     * @dev Checks if a given address is a valid provider.
     * @param provider The address of the provider to check.
     * @return A boolean indicating whether the provider is valid or not.
     */
    function isValidProvider(address provider) external view override returns (bool) {
        return validProviders[provider];
    }

    function currentProviderAddress() external view returns (address) {
        return _currentProvider;
    }

    /**
     * @dev Returns the address of the current provider.
     * @return The address of the current provider.
     */
    function getProvider(uint8, bytes calldata, bytes32, bytes calldata) external view override returns (address) {
        return _currentProvider;
    }

    /**
     * @dev Configures the providers info.
     * @param configData The configuration data.
     * - It should be encoded using the abi.encode function.
     * - The data should be a struct of type ConfigCallParamsV2.
     * - The struct should contain the following fields:
     * - - action: The action to be performed. It can be AddProvider, RemoveProvider or UpdateDefaultProvider.
     * - - providerAddress: The address of the provider.
     * @notice The function can only be called by the teleport contract.
     */
    function config(bytes calldata configData) external override onlyTeleport {
        ConfigCallParamsV2 memory params = _decodeConfigParams(configData);

        if (params.action == Action.AddProvider) {
            _addProvider(params.providerAddress);
        } else if (params.action == Action.RemoveProvider) {
            _removeProvider(params.providerAddress);
        } else if (params.action == Action.SetDefaultProvider) {
            // Set the new provider.
            // We specifically don't check if the provider is the zero address, as we want to be able to remove the default provider.
            // The previous default provider will still be kept as a valid provider, to remove it, a separate call with a removeProvider is needed.
            _currentProvider = params.providerAddress;
            if (params.providerAddress != address(0) && !validProviders[params.providerAddress]) {
                _addProvider(params.providerAddress);
            }
            emit DefaultProviderUpdated(params.providerAddress);
        }
    }

    /**
     * @dev Decodes bytes received from the teleport config call.
     * @param configData The data to decode.
     * @return params The decoded params.
     */
    function _decodeConfigParams(bytes memory configData) internal pure returns (ConfigCallParamsV2 memory params) {
        params = abi.decode(configData, (ConfigCallParamsV2));
    }

    function _addProvider(address provider) internal {
        if (provider == address(0)) revert ZeroAddressProvider();
        validProviders[provider] = true;
        emit ProviderAdded(provider);
    }

    function _removeProvider(address provider) internal {
        if (provider == address(0)) revert ZeroAddressProvider();
        if (!validProviders[provider]) revert ProviderNotFound();

        validProviders[provider] = false;
        emit ProviderRemoved(provider);

        if (provider == _currentProvider) {
            _currentProvider = address(0);
            emit DefaultProviderUpdated(address(0));
        }
    }

    enum Action {
        AddProvider,
        RemoveProvider,
        SetDefaultProvider
    }

    /**
     * @dev Struct representing the configuration call parameters version 1 of the ProviderSelector contract.
     */
    struct ConfigCallParamsV2 {
        Action action;
        address providerAddress;
    }
}