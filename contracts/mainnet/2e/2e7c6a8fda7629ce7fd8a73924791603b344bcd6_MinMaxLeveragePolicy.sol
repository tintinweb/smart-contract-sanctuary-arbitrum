// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./PolicyBase.sol";

/// @title MinMaxLeveragePolicy Contract
/// @notice A policy that restricts the min and max leverage of the position
contract MinMaxLeveragePolicy is PolicyBase {
    event TradeSettingsSet(
        address indexed fundManager,
        uint256 minLeverage,
        uint256 maxLeverage
    );

    struct TradeSettings {
        uint256 minLeverage;
        uint256 maxLeverage;
    }

    mapping(address => TradeSettings) private fundManagerToTradeSettings;

    constructor(address _policyManager) PolicyBase(_policyManager) {}

    /// @notice Adds the initial policy settings for a fund
    /// @param _fundManager The fund's address address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function addTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
        __setTradeSettings(_fundManager, _encodedSettings);
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    function canDisable()
        external
        pure
        virtual
        override
        returns (bool canDisable_)
    {
        return true;
    }

    /// @notice Provides a constant string identifier for a policy
    /// @return identifier_ The identifer string
    function identifier()
        external
        pure
        override
        returns (string memory identifier_)
    {
        return "MIN_MAX_LEVERAGE";
    }

    /// @notice Gets the implemented PolicyHooks for a policy
    /// @return implementedHooks_ The implemented PolicyHooks
    function implementedHooks()
        external
        pure
        override
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_)
    {
        implementedHooks_ = new IPolicyManager.PolicyHook[](1);
        implementedHooks_[0] = IPolicyManager.PolicyHook.MinMaxLeverage;

        return implementedHooks_;
    }

    /// @notice Updates the policy settings for a fund
    /// @param _fundManager The fund's address address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function updateTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external override onlyPolicyManager {
        __setTradeSettings(_fundManager, _encodedSettings);
    }

    /// @notice Checks whether a particular condition passes the rule for a particular fund
    /// @param _fundManager The fund's address address
    /// @param _leverage The leverage taken by the master trader
    /// @return isValid_ True if the rule passes
    function passesRule(
        address _fundManager,
        uint256 _leverage
    ) public view returns (bool isValid_, bytes memory) {
        uint256 minLeverage = fundManagerToTradeSettings[_fundManager]
            .minLeverage;
        uint256 maxLeverage = fundManagerToTradeSettings[_fundManager]
            .maxLeverage;

        uint256 leverage = _leverage / 1e26;

        if (leverage <= minLeverage)
            return (true, abi.encode(minLeverage * 1e26));
        else if (leverage >= maxLeverage)
            return (true, abi.encode(maxLeverage * 1e26));
        else return (true, abi.encode(_leverage));
    }

    /// @notice Apply the rule with the specified parameters of a PolicyHook
    /// @param _fundManager The fund manager address
    /// @param _encodedArgs Encoded args with which to validate the rule
    /// @return isValid_ True if the rule passes
    /// @dev onlyPolicyManager validation not necessary, as state is not updated and no events are fired
    function validateRule(
        address _fundManager,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external view override returns (bool isValid_, bytes memory message) {
        uint256 leverage = __decodeMinMaxLeverageValidationData(_encodedArgs);

        return passesRule(_fundManager, leverage);
    }

    /// @dev Helper to set the policy settings for a fund
    /// @param _fundManager The fund's address address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function __setTradeSettings(
        address _fundManager,
        bytes memory _encodedSettings
    ) private {
        (uint256 minLeverage, uint256 maxLeverage) = abi.decode(
            _encodedSettings,
            (uint256, uint256)
        );

        require(
            minLeverage < maxLeverage,
            "__setTradeSettings: minLeverage must be less than maxLeverage"
        );

        fundManagerToTradeSettings[_fundManager].minLeverage = minLeverage;
        fundManagerToTradeSettings[_fundManager].maxLeverage = maxLeverage;

        emit TradeSettingsSet(_fundManager, minLeverage, maxLeverage);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the min and max investment amount for a given fund
    /// @param _fundManager The address of the fund
    /// @return tradeSettings_ The fund settings
    function getTradeSettings(
        address _fundManager
    ) external view returns (bytes memory tradeSettings_) {
        return
            abi.encode(
                fundManagerToTradeSettings[_fundManager].minLeverage,
                fundManagerToTradeSettings[_fundManager].maxLeverage
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";

import {IPolicy} from "./IPolicy.sol";

/// @title PolicyBase Contract
/// @notice Abstract base contract for all policies
abstract contract PolicyBase is IPolicy {
    address internal immutable POLICY_MANAGER;

    modifier onlyPolicyManager() {
        require(
            msg.sender == POLICY_MANAGER,
            "Only the PolicyManager can make this call"
        );
        _;
    }

    constructor(address _policyManager) {
        POLICY_MANAGER = _policyManager;
    }

    /// @notice Validates and initializes a policy as necessary prior to fund activation
    /// @dev Unimplemented by default, can be overridden by the policy
    function activateForTradeManager(address) external virtual {
        return;
    }

    /// @notice Whether or not the policy can be disabled
    /// @return canDisable_ True if the policy can be disabled
    /// @dev False by default, can be overridden by the policy
    function canDisable()
        external
        pure
        virtual
        override
        returns (bool canDisable_)
    {
        return false;
    }

    /// @notice Updates the policy settings for a fund
    /// @dev Disallowed by default, can be overridden by the policy
    function updateTradeSettings(address, bytes calldata) external virtual {
        revert("updateTradeSettings: Updates not allowed for this policy");
    }

    //////////////////////////////
    // VALIDATION DATA DECODING //
    //////////////////////////////

    /// @dev Helper to parse validation arguments from encoded data for min-max leverage policy hook
    function __decodeMinMaxLeverageValidationData(
        bytes memory _validationData
    ) internal pure returns (uint256) {
        return abi.decode(_validationData, (uint256));
    }

    /// @dev Helper to parse validation arguments from encoded data for pre trade policy hook
    function __decodePreTradeValidationData(
        bytes memory _validationData
    )
        internal
        pure
        returns (uint256 typeId_, bytes memory initializationData_)
    {
        return abi.decode(_validationData, (uint256, bytes));
    }

    /// @dev Helper to parse validation arguments from encoded data for max open positions policy hook
    function __decodeOpenPositionsValidationData(
        bytes memory _validationData
    ) internal pure returns (address externalPosition_) {
        return abi.decode(_validationData, (address));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `POLICY_MANAGER` variable value
    /// @return policyManager_ The `POLICY_MANAGER` variable value
    function getPolicyManager() external view returns (address policyManager_) {
        return POLICY_MANAGER;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/** @title PolicyManager Interface
    @notice Interface for the PolicyManager
*/
interface IPolicyManager {
    // When updating PolicyHook, also update these functions in PolicyManager:
    // 1. __getAllPolicyHooks()
    // 2. __policyHookRestrictsCurrentInvestorActions()
    enum PolicyHook {
        MinMaxLeverage,
        MaxOpenPositions,
        PreExecuteTrade,
        TradeFactor,
        MaxAmountPerTrade,
        MinAssetBalances,
        TrailingStopLoss,
        PostExecuteTrade
    }

    function validatePolicies(
        address,
        PolicyHook,
        bytes calldata
    ) external returns (bool, bytes memory);

    function setConfigForFund(
        address _fundManager,
        bytes calldata _configData
    ) external;

    function getEnabledPoliciesForFund(
        address
    ) external view returns (address[] memory);

    function fundManagerFactory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IPolicyManager} from "../Interfaces/IPolicyManager.sol";

interface IPolicy {
    function addTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function canDisable() external pure returns (bool canDisable_);

    function implementedHooks()
        external
        pure
        returns (IPolicyManager.PolicyHook[] memory implementedHooks_);

    function updateTradeSettings(
        address _fundManager,
        bytes calldata _encodedSettings
    ) external;

    function validateRule(
        address _fundManagers,
        IPolicyManager.PolicyHook _hook,
        bytes calldata _encodedArgs
    ) external returns (bool isValid_, bytes memory message);

    function getTradeSettings(
        address _fundManager
    ) external view returns (bytes memory);

    function identifier() external view returns (string memory);
}