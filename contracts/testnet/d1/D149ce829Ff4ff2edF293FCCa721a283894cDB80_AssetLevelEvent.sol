/**
 *Submitted for verification at Arbiscan on 2023-08-15
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File src/types/EventTypes.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library EventTypes {
    /// -----------------------------------------------------------------------
    /// Types
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_PROTOCOL_LEVEL = 1;
    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_CUSTODY_LEVEL = 2;
    // solhint-disable-next-line
    uint8 constant EVENT_TYPE_ASSET_LEVEL = 3;

    // solhint-disable-next-line
    uint8 constant MIN_VALUE_TRIGGER = 1;

    /// -----------------------------------------------------------------------
    /// Storage Structure
    /// -----------------------------------------------------------------------

    struct Base {
        uint32 id;
        string name;
        string description;
        uint8 eventType;
    }

    struct MinValueTrigger {
        uint8 version;
        address asset;
        uint256 minValue;
        uint8 decimal;
    }
}

// File src/interface/IReferenceEvent.sol

pragma solidity ^0.8.17;

interface IReferenceEvent {
    function id() external view returns (uint32);

    function name() external view returns (string memory);

    function description() external view returns (string memory);

    function eventType() external view returns (uint8);

    function verifyTriggerSanity(
        bytes calldata trigger
    ) external view returns (bool);

    function verifyProofSanity(
        bytes calldata proof
    ) external view returns (bool);
}

// File src/event/BaseReferenceEvent.sol

pragma solidity ^0.8.17;

/// @title BaseReferenceEvent
/// @notice base contract for all events
abstract contract BaseReferenceEvent is IReferenceEvent {
    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------
    EventTypes.Base internal _base;

    constructor(
        uint32 id_,
        string memory name_,
        string memory description_,
        uint8 eventType_
    ) {
        _base.id = id_;
        _base.name = name_;
        _base.description = description_;
        _base.eventType = eventType_;
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function id() external view override returns (uint32) {
        return _base.id;
    }

    function name() external view override returns (string memory) {
        return _base.name;
    }

    function description() external view override returns (string memory) {
        return _base.description;
    }

    function eventType() external view override returns (uint8) {
        return _base.eventType;
    }

    function verifyTriggerSanity(
        bytes calldata trigger
    ) external view virtual override returns (bool) {}

    function verifyProofSanity(
        bytes calldata proof
    ) external view virtual override returns (bool);
}

// File src/interface/IAssetLevelEvent.sol

pragma solidity ^0.8.17;

interface IAssetLevelEvent {
    function getAssetAndTriggerValue(
        bytes calldata trigger
    )
        external
        view
        returns (bool isSuccess, address asset, uint256 value, uint8 decimal);

    function getRoundId(
        bytes calldata proof
    ) external pure returns (uint80 roundId);
}

// File src/interface/IReferenceEventFactory.sol

pragma solidity ^0.8.17;

interface IReferenceEventFactory {
    event AssetAdded(address indexed asset);

    event ReferenceEventCreated(
        uint256 indexed id,
        uint8 indexed eventType,
        address eventAddress,
        string name
    );

    function lastReferenceEventId() external view returns (uint32);

    function isAllowAsset(address asset) external view returns (bool);

    function getReferenceEventById(
        uint32 eventId
    ) external view returns (address);

    function assets() external view returns (address[] memory);
}

// File src/event/AssetLevelEvent.sol

pragma solidity ^0.8.17;

/// @title AssetLevelEvent
/// @notice contract define a reference event at asset level
contract AssetLevelEvent is BaseReferenceEvent, IAssetLevelEvent {
    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------
    IReferenceEventFactory internal immutable _eventFactory;

    constructor(
        uint32 id_,
        string memory name_,
        string memory description_,
        uint8 eventType_,
        address eventFactory_
    ) BaseReferenceEvent(id_, name_, description_, eventType_) {
        _eventFactory = IReferenceEventFactory(eventFactory_);
    }

    /// -----------------------------------------------------------------------
    /// View Functions
    /// -----------------------------------------------------------------------

    function verifyTriggerSanity(
        bytes calldata trigger
    ) external view override returns (bool isSuccess) {
        (isSuccess, , , ) = _parseTrigger(trigger);
    }

    /// @dev proof is a valid chainLink roundId
    function verifyProofSanity(
        bytes memory proof
    ) external pure override returns (bool isSuccess) {
        uint256 tempRoundId;
        assembly {
            tempRoundId := mload(add(proof, 0x20))
        }
        // tempRoundId must below 1 follow by 80 zero bit
        if (tempRoundId >= 1 << 80) {
            isSuccess = false;
        } else {
            isSuccess = true;
        }
    }

    function getAssetAndTriggerValue(
        bytes calldata trigger
    )
        external
        view
        returns (bool isSuccess, address asset, uint256 value, uint8 decimal)
    {
        (isSuccess, asset, value, decimal) = _parseTrigger(trigger);
    }

    function getRoundId(
        bytes memory proof
    ) external pure override returns (uint80 roundId) {
        assembly {
            roundId := mload(add(proof, 0x20))
        }
    }

    function encodeMinTriggerType(
        address asset,
        uint256 minValue,
        uint8 decimal
    ) external pure returns (bytes memory) {
        return
            abi.encode(
                EventTypes.MinValueTrigger({
                    version: EventTypes.MIN_VALUE_TRIGGER,
                    asset: asset,
                    minValue: minValue,
                    decimal: decimal
                })
            );
    }

    /// @dev each assetLevelEvent could have multiple trigger
    ///      no matter how the trigger is, it must be result in a asset and a triggerValue along with decimal
    ///      if value return from oracle is bellow or equal to triggerValue contract is default
    function _parseTrigger(
        bytes memory trigger
    )
        internal
        view
        returns (
            bool isSuccess,
            address asset,
            uint256 triggerValue,
            uint8 decimal
        )
    {
        isSuccess = false;

        uint8 version;
        // Extract version using inline assembly
        assembly {
            version := mload(add(trigger, 0x20))
        }
        if (version == EventTypes.MIN_VALUE_TRIGGER) {
            EventTypes.MinValueTrigger memory data = abi.decode(
                trigger,
                (EventTypes.MinValueTrigger)
            );
            if (!_eventFactory.isAllowAsset(data.asset)) {
                isSuccess = false;
            } else {
                asset = data.asset;
                decimal = data.decimal;
                triggerValue = data.minValue;
                isSuccess = true;
            }
        }
    }
}