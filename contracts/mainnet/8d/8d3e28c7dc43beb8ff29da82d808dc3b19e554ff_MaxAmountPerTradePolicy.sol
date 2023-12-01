// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./PolicyBase.sol";

/// @title MaxAmountPerTradePolicy Contract
/// @notice A policy that restricts the amount of the max denomination asset that will invest in a single trade
contract MaxAmountPerTradePolicy is PolicyBase {
    event TradeSettingsSet(address _fundManager, uint256 maxAmountPerTrade);

    mapping(address => uint256) private fundManagerToMaxAmountPerTrade;

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
    /// @return canDisable_ True if the policy can be disableds
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
        return "TRADE_FACTOR";
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
        implementedHooks_[0] = IPolicyManager.PolicyHook.MaxAmountPerTrade;

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

    /// @notice Checks whether a particular condition passes the rule for a particular fund manager
    /// @param _fundManager The fund's address address
    /// @param _collateral collateral in usdc required to invest
    /// @return isValid_ True if the rule passes
    function passesRule(
        address _fundManager,
        uint256 _collateral
    ) public view returns (bool isValid_, bytes memory message) {
        uint256 maxAmountPerTrade = fundManagerToMaxAmountPerTrade[
            _fundManager
        ];

        if (_collateral <= maxAmountPerTrade)
            return (true, abi.encode(_collateral));
        else return (true, abi.encode(maxAmountPerTrade));
    }

    // /// @notice Apply the rule with the specified parameters of a PolicyHook
    // /// @param _fundManager The fund manager address
    // /// @param _encodedArgs Encoded args with which to validate the rule
    // /// @return isValid_ True if the rule passes
    // /// @return message reason for failure
    // /// @dev onlyPolicyManager validation not necessary, as state is not updated and no events are fired
    function validateRule(
        address _fundManager,
        IPolicyManager.PolicyHook,
        bytes calldata _encodedArgs
    ) external view override returns (bool isValid, bytes memory message_) {
        uint256 collateral = abi.decode(_encodedArgs, (uint256));
        return passesRule(_fundManager, collateral);
    }

    /// @dev Helper to set the policy settings for a fund
    /// @param _fundManager The fund's address address
    /// @param _encodedSettings Encoded settings to apply to a fund
    function __setTradeSettings(
        address _fundManager,
        bytes memory _encodedSettings
    ) private {
        uint256 maxAmountPerTrade = abi.decode(_encodedSettings, (uint256));

        fundManagerToMaxAmountPerTrade[_fundManager] = maxAmountPerTrade;

        emit TradeSettingsSet(_fundManager, maxAmountPerTrade);
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the min and max investment amount for a given fund
    /// @param _fundManager The address of the fund
    /// @return fundSettings_ The fund settings
    function getTradeSettings(
        address _fundManager
    ) external view override returns (bytes memory) {
        return abi.encode(fundManagerToMaxAmountPerTrade[_fundManager]);
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