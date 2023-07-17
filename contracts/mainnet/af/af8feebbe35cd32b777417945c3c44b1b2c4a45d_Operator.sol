// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";

/// @title Operator
/// @notice Contract to manage all the state variables for STFX and OZO
contract Operator {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(string => address) public addressValues;
    mapping(address => address) public traderAccount;
    mapping(address => bool) public whitelistedPlugins;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SetAddress(string adapter, address indexed addressValue);
    event SetAddresses(string[] adapter, address[] indexed addressValues);
    event SetPlugin(address indexed plugin, bool isWhitelisted);
    event SetPlugins(address[] indexed plugins, bool[] isWhitelisted);

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor() {
        addressValues["OWNER"] = msg.sender;
        emit SetAddress("OWNER", msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != addressValues["OWNER"]) revert Errors.NoAccess();
        _;
    }

    modifier onlyQ() {
        if (msg.sender != addressValues["Q"]) revert Errors.NoAccess();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the address of the trader's Account contract
    /// @param trader address of the trader
    /// @return address of the trader's Account contract
    function getTraderAccount(address trader) external view returns (address) {
        return traderAccount[trader];
    }

    /// @notice gettter to check if the address is a plugin or not
    /// @param plugin address of the plugin
    /// @return bool to check if the address is a plugin
    function getPlugin(address plugin) external view returns (bool) {
        return whitelistedPlugins[plugin];
    }

    /// @notice gettter to check if the addresses are a plugin or not
    /// @param plugins addresses of the plugins
    /// @return bool to check if the addresses are plugins
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory) {
        uint256 length = plugins.length;
        bool[] memory isPlugin = new bool[](length);
        uint256 i;
        for (; i < length;) {
            isPlugin[i] = whitelistedPlugins[plugins[i]];
            unchecked {
                ++i;
            }
        }
        return isPlugin;
    }

    /// @notice get the address of an adapter
    /// @param adapter name of the contract
    /// @return address of the adapter
    function getAddress(string calldata adapter) external view returns (address) {
        return addressValues[adapter];
    }

    /// @notice get the addresses of the given adapters
    /// @param adapters name of the contracts
    /// @return address of the adapter
    function getAddresses(string[] calldata adapters) external view returns (address[] memory) {
        uint256 length = adapters.length;
        address[] memory addresses = new address[](length);
        uint256 i;
        for (; i < length;) {
            addresses[i] = addressValues[adapters[i]];
            unchecked {
                ++i;
            }
        }
        return addresses;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice set a new plugin or update an existing plugin
    /// @dev can only be called by the `owner`
    /// @param plugin address of the plugin
    /// @param isPlugin bool to set if the address is a plugin or not
    function setPlugin(address plugin, bool isPlugin) external onlyOwner {
        _setPlugin(plugin, isPlugin);
        emit SetPlugin(plugin, isPlugin);
    }

    /// @notice set multiple new plugins or update existing plugins
    /// @dev can only be called by the `owner`
    /// @param plugins addresses of the plugin
    /// @param isPlugin bool to set if the addresses are a plugin or not
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external onlyOwner {
        if (plugins.length != isPlugin.length) revert Errors.LengthMismatch();
        uint256 i;
        for (; i < plugins.length;) {
            if (plugins[i] == address(0)) revert Errors.ZeroAddress();
            _setPlugin(plugins[i], isPlugin[i]);
            unchecked {
                ++i;
            }
        }
        emit SetPlugins(plugins, isPlugin);
    }

    /// @notice set a new adapter or update an existing adapter
    /// @dev can only be called by the `owner`
    /// @param adapter name of the adapter
    /// @param addr address of the adapter
    function setAddress(string calldata adapter, address addr) external onlyOwner {
        _setAddress(adapter, addr);
        emit SetAddress(adapter, addr);
    }

    /// @notice set multiple new adapters or update existing adapters
    /// @dev can only be called by the `owner`
    /// @param adapters name of the adapters
    /// @param addresses addresses of the adapters
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external onlyOwner {
        if (adapters.length != addresses.length) revert Errors.LengthMismatch();
        uint256 i;
        for (; i < adapters.length;) {
            if (addresses[i] == address(0)) revert Errors.ZeroAddress();
            _setAddress(adapters[i], addresses[i]);
            unchecked {
                ++i;
            }
        }
        emit SetAddresses(adapters, addresses);
    }

    /// @notice set the Account contract of a trader
    /// @dev can only be called by `Q` contract
    /// @param trader address of the trader
    /// @param account address of the account
    function setTraderAccount(address trader, address account) external onlyQ {
        traderAccount[trader] = account;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _setPlugin(address plugin, bool isPlugin) internal {
        if (plugin == address(0)) revert Errors.ZeroAddress();
        whitelistedPlugins[plugin] = isPlugin;
    }

    function _setAddress(string calldata adapter, address addr) internal {
        if (addr == address(0)) revert Errors.ZeroAddress();
        addressValues[adapter] = addr;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
}