// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {OwnableTrigger} from "./OwnableTrigger.sol";
import {TriggerMetadata} from "./structs/Triggers.sol";

contract OwnableTriggerFactory {
  /// @dev Emitted when the factory deploys a trigger.
  /// @param trigger The address at which the trigger was deployed.
  /// @param owner The owner of the trigger.
  /// @param name The human-readble name of the trigger.
  /// @param description A human-readable description of the trigger.
  /// @param logoURI The URI of a logo image to represent the trigger.
  /// For other attributes, see the docs for the params of `deployTrigger` in
  /// this contract.
  /// @param extraData Extra metadata for the trigger.
  event TriggerDeployed(
    address trigger, address indexed owner, string name, string description, string logoURI, string extraData
  );

  /// @notice Deploys a new OwnableTrigger contract with the supplied owner and deploy salt.
  /// @param _owner The owner of the trigger.
  /// @param _metadata The metadata of the trigger.
  /// @param _salt Used during deployment to compute the address of the new OwnableTrigger.
  function deployTrigger(address _owner, TriggerMetadata memory _metadata, bytes32 _salt)
    external
    returns (OwnableTrigger _trigger)
  {
    _trigger = new OwnableTrigger{salt: _salt}(_owner);
    emit TriggerDeployed(
      address(_trigger), _owner, _metadata.name, _metadata.description, _metadata.logoURI, _metadata.extraData
    );
  }

  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed. See `deployTrigger` for
  /// more information on parameters and their meaning.
  function computeTriggerAddress(address _owner, bytes32 _salt) external view returns (address _address) {
    // https://eips.ethereum.org/EIPS/eip-1014
    bytes32 _bytecodeHash = keccak256(bytes.concat(type(OwnableTrigger).creationCode, abi.encode(_owner)));
    bytes32 _data = keccak256(bytes.concat(bytes1(0xff), bytes20(address(this)), _salt, _bytecodeHash));
    _address = address(uint160(uint256(_data)));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {BaseTrigger} from "./abstract/BaseTrigger.sol";
import {Ownable} from "./lib/Ownable.sol";
import {TriggerState} from "./structs/StateEnums.sol";

contract OwnableTrigger is BaseTrigger, Ownable {
  /// @param _owner The address of the owner of the trigger, which is allowed to call `trigger()`.
  constructor(address _owner) Ownable(_owner) {
    _assertAddressNotZero(_owner);
  }

  /// @notice Callable by the owner to transition the state of the trigger to triggered.
  function trigger() external onlyOwner {
    _updateTriggerState(TriggerState.TRIGGERED);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct TriggerMetadata {
  // The name that should be used for safety modules that use the trigger.
  string name;
  // A human-readable description of the trigger.
  string description;
  // The URI of a logo image to represent the trigger.
  string logoURI;
  // Extra metadata for the trigger.
  string extraData;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ITrigger} from "../interfaces/ITrigger.sol";
import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev Core trigger interface and implementation. All triggers should inherit from this to ensure they conform
 * to the required trigger interface.
 */
abstract contract BaseTrigger is ITrigger {
  /// @notice Current trigger state.
  TriggerState public state;

  /// @dev Thrown when a state update results in an invalid state transition.
  error InvalidStateTransition();

  /// @dev Child contracts should use this function to handle Trigger state transitions.
  function _updateTriggerState(TriggerState _newState) internal returns (TriggerState) {
    if (!_isValidTriggerStateTransition(state, _newState)) revert InvalidStateTransition();
    state = _newState;
    emit TriggerStateUpdated(_newState);
    return _newState;
  }

  /// @dev Reimplement this function if different state transitions are needed.
  function _isValidTriggerStateTransition(TriggerState _oldState, TriggerState _newState)
    internal
    virtual
    returns (bool)
  {
    // | From / To | ACTIVE      | FROZEN      | PAUSED   | TRIGGERED |
    // | --------- | ----------- | ----------- | -------- | --------- |
    // | ACTIVE    | -           | true        | false    | true      |
    // | FROZEN    | true        | -           | false    | true      |
    // | PAUSED    | false       | false       | -        | false     | <-- PAUSED is a safety module-level state
    // | TRIGGERED | false       | false       | false    | -         | <-- TRIGGERED is a terminal state

    if (_oldState == TriggerState.TRIGGERED) return false;
    // If oldState == newState, return true since the safety module will convert that into a no-op.
    if (_oldState == _newState) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.FROZEN) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.ACTIVE) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.TRIGGERED) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.TRIGGERED) return true;
    return false;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {IOwnable} from "src/interfaces/IOwnable.sol";

/**
 * @dev Contract module providing owner functionality, intended to be used through inheritance.
 * @dev No modifiers are provided to reduce bloat from unused code (even though this should be removed by the
 * compiler), as the child contract may have more complex authentication requirements than just a modifier from
 * this contract.
 */
abstract contract Ownable is IOwnable {
  /// @notice Contract owner.
  address public owner;

  /// @notice The pending new owner.
  address public pendingOwner;

  /// @dev Emitted when the owner address is updated.
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /// @dev Emitted when the first step of the two step ownership transfer is executed.
  event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

  /// @dev Thrown when the caller is not authorized to perform the action.
  error Unauthorized();

  /// @dev Thrown when an invalid address is passed as a parameter.
  error InvalidAddress();

  /// @param _owner The contract owner.
  constructor(address _owner) {
    emit OwnershipTransferred(owner, _owner);
    owner = _owner;
  }

  /// @notice Callable by the pending owner to transfer ownership to them.
  /// @dev Updates the owner in storage to pendingOwner and resets the pending owner.
  function acceptOwnership() external {
    if (msg.sender != pendingOwner) revert Unauthorized();
    delete pendingOwner;
    address _oldOwner = owner;
    owner = msg.sender;
    emit OwnershipTransferred(_oldOwner, msg.sender);
  }

  /// @notice Starts the ownership transfer of the contract to a new account.
  /// Replaces the pending transfer if there is one.
  /// @param _newOwner The new owner of the contract.
  function transferOwnership(address _newOwner) external onlyOwner {
    _assertAddressNotZero(_newOwner);
    pendingOwner = _newOwner;
    emit OwnershipTransferStarted(owner, _newOwner);
  }

  /// @dev Revert if the address is the zero address.
  function _assertAddressNotZero(address _address) internal pure {
    if (_address == address(0)) revert InvalidAddress();
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev The minimal functions a trigger must implement to work with the Cozy Safety Module protocol.
 */
interface ITrigger {
  /// @dev Emitted when a trigger's state is updated.
  event TriggerStateUpdated(TriggerState indexed state);

  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOwnable {
  /// @notice Callable by the pending owner to transfer ownership to them.
  function acceptOwnership() external;

  /// @notice The current owner.
  function owner() external view returns (address);

  /// @notice Callable by the current owner to transfer ownership to a new account. The new owner must call
  /// acceptOwnership() to finalize the transfer.
  function transferOwnership(address newOwner_) external;
}