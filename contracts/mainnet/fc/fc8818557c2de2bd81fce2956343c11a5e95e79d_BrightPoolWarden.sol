// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./Errors.sol";

/**
 * @dev Warden contract to register and check values that should have been time locked.
 * All timelocks are set to 24 hours
 */
contract BrightPoolWarden {
    uint256 constant TIME_LOCK = 24 hours;

    /**
     * @dev Event emitted on change being scheduled
     */
    event ChangeScheduled(address indexed scheduler, string name, address value);
    /**
     * @dev Event emmitted on change being reverted
     */
    event ChangeReverted(address indexed scheduler, string name, address value);

    struct LockedValue {
        address value;
        address registrant;
        uint256 time;
    }

    mapping(address => mapping(string => LockedValue)) private _lockedValues;

    /**
     * @dev Method to set the change sequence for a registered value.
     *
     * @param to_ Address to change value to
     * @param name_ The name of the value that is a subject to change
     * @param registrant_ The address that is initialiting the call (or 0 address if this is irrelevant)
     *
     * @return True if value can be set immediately. False otherwise
     */
    function changeValue(address to_, string calldata name_, address registrant_) external returns (bool) {
        LockedValue storage lockedValue = _lockedValues[msg.sender][name_];
        if (to_ == lockedValue.value) {
            // slither-disable-next-line timestamp
            if (lockedValue.time < block.timestamp) {
                if (lockedValue.registrant != address(0) && lockedValue.registrant == registrant_) {
                    revert Restricted();
                }
                lockedValue.value = address(0);
                lockedValue.registrant = address(0);
                lockedValue.time = 0;
                return true;
            } else {
                revert Blocked();
            }
        } else {
            if (to_ == address(0)) {
                emit ChangeReverted(msg.sender, name_, lockedValue.value);
                lockedValue.value = address(0);
                lockedValue.registrant = address(0);
                lockedValue.time = 0;
            } else if (lockedValue.value != address(0)) {
                revert Blocked();
            } else {
                lockedValue.value = to_;
                lockedValue.registrant = registrant_;
                // slither-disable-next-line timestamp
                lockedValue.time = block.timestamp + TIME_LOCK;
                emit ChangeScheduled(msg.sender, name_, to_);
            }
        }
        return false;
    }

    /**
     * @dev The method to check currently awaiting value in the plan
     *
     * @param name_ The name of the value to be checked
     *
     * @return Value currently awaiting change
     */
    function awaitingValue(string calldata name_) external view returns (address) {
        return _lockedValues[msg.sender][name_].value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @dev Action restricted. Given account is not allowed to run it
 */
error Restricted();

/**
 * @dev Trying to set Zero Address to an attribute that cannot be 0
 */
error ZeroAddress();

/**
 * @dev Attribute already set and does not allow resetting
 */
error AlreadySet();

/**
 * @dev A cap has been exceeded - temporarily locked
 */
error CapExceeded();

/**
 * @dev A deadline has been wrongly set
 */
error WrongDeadline();

/**
 * @dev A kill switch is in play. Action restricted and temporarily frozen
 */
error KillSwitch();

/**
 * @dev A value cannot be zero
 */
error ZeroValue();

/**
 * @dev Value exceeded maximum allowed
 */
error TooBig();

/**
 * @dev Appointed item does not exist
 */
error NotExists();

/**
 * @dev Appointed item already exist
 */
error AlreadyExists();

/**
 * @dev Timed action has timed out
 */
error Timeout();

/**
 * @dev Insufficient funds to perform action
 */
error InsufficientFunds();

/**
 * @dev Wrong currency used
 */
error WrongCurrency();

/**
 * @dev Blocked action. For timing or other reasons
 */
error Blocked();

/**
 * @dev Suspended access
 */
error Suspended();

/**
 * @dev Nothing to claim
 */
error NothingToClaim();

/**
 * @dev Missing vesting tokens
 */
error MissingVestingTokens();