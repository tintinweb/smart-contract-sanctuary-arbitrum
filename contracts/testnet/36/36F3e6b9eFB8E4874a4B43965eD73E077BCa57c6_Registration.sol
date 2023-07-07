// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IRegistration {
    // Status of participants to perform weather update operation on server
    enum LifecycleStatus {
        Unregistered,
        Registered,
        Resigned
    }

    // Event to emit participant registered. Added for go-lang server to listen and update DB
    event ParticipantRegistered(address indexed participant);
    // Event to emit participant resigned. Added for go-lang server to listen and update DB
    event ParticipantResigned(address indexed participant);

    // Getter methods

    /**
     * @notice Method used to get the status of passed ETH address
     * @param _participant Address of user to check for status
     */
    function participants(address _participant) external view returns (LifecycleStatus);

    // Setter methods

    /**
     * @notice Method used to register participant
     * @dev Caller of this method must be an unregistered user
     * @dev Caller status changes to registered
     * @dev ParticipantRegistered event gets emitted to perform required operation on server
     */
    function register() external;

    /**
     * @notice Method used to resign participant
     * @dev Caller of this method must be a registered user
     * @dev Caller status changes to resigned
     * @dev ParticipantResigned event gets emitted to perform required operation on server
     */
    function resign() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import { IRegistration } from "./IRegistration.sol";

/**
 * @title Registration Contract
 * @notice This contract is used to perform registration, and resign.
 * @dev Registered participants can call the server maximum once every 12 seconds to report the weather.
 */
contract Registration is IRegistration {
    // Stores participants status
    mapping(address => LifecycleStatus) public participants;

    /// @inheritdoc IRegistration
    function register() external virtual {
        require(participants[msg.sender] == LifecycleStatus.Unregistered, "Already registered or resigned");

        participants[msg.sender] = LifecycleStatus.Registered;
        emit ParticipantRegistered(msg.sender);
    }

    /// @inheritdoc IRegistration
    function resign() external virtual {
        require(participants[msg.sender] == LifecycleStatus.Registered, "Not registered");

        participants[msg.sender] = LifecycleStatus.Resigned;
        emit ParticipantResigned(msg.sender);
    }
}