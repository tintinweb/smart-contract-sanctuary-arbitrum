// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @dev Interface for interacting with a Timelock
 */
interface ITimelock {
    /// @notice Event emitted when a pending admin accepts admin position
    event NewAdmin(address indexed newAdmin);

    /// @notice Event emitted when new pending admin is set by the timelock
    event NewPendingAdmin(address indexed newPendingAdmin);

    /// @notice Event emitted when Timelock sets new delay value
    event NewDelay(uint indexed newDelay);

    /// @notice Event emitted when admin cancels an enqueued transaction
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    /// @notice Event emitted when admin executes an enqueued transaction
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);

    /// @notice Event emitted when admin enqueues a transaction
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    /// @notice The length of time, once the delay has passed, in which a transaction can be executed before it becomes stale
    function GRACE_PERIOD() virtual external view returns (uint);

    /// @notice The minimum value that the `delay` variable can be set to
    function MINIMUM_DELAY() virtual external view returns (uint);

    /// @notice The maximum value that the `delay` variable can be set to
    function MAXIMUM_DELAY() virtual external view returns (uint);

    /// @notice Address that has admin privileges
    function admin() virtual external view returns (address);

    /// @notice The address that may become the new admin by calling `acceptAdmin()`
    function pendingAdmin() virtual external view returns (address);

    /**
     * @notice Set the pending admin
     * @param pendingAdmin_ New pending admin address
     */
    function setPendingAdmin(address pendingAdmin_) virtual external;

    /**
     * @notice Accept the position of admin (if caller is the current pendingAdmin)
     */
    function acceptAdmin() virtual external;

    /// @notice Duration that a transaction must be queued before it can be executed
    function delay() virtual external view returns (uint);

    /**
     * @notice Set the delay value
     * @param delay New delay value
     */
    function setDelay(uint delay) virtual external;

    /// @notice Mapping of transaction hashes to whether that transaction is currently enqueued
    function queuedTransactions(bytes32 txHash) virtual external returns (bool);

    /**
     * @notice Enque a transaction
     * @param target Address that the transaction is targeted at
     * @param value Value to send to target address
     * @param signature Function signature to call on target address
     * @param data Calldata for function called on target address
     * @param eta Timestamp of when the transaction can be executed
     * @return txHash of the enqueued transaction
     */
    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external returns (bytes32);

    /**
     * @notice Cancel an enqueued transaction
     * @param target Address that the transaction is targeted at
     * @param value Value of the transaction to cancel
     * @param signature Function signature of the transaction to cancel
     * @param data Calldata for the transaction to cancel
     * @param eta Timestamp of the transaction to cancel
     */
    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external;

    /**
     * @notice Execute an enqueued transaction
     * @param target Target address of the transaction to execute
     * @param value Value of the transaction to execute
     * @param signature Function signature of the transaction to execute
     * @param data Calldata for the transaction to execute
     * @param eta Timestamp of the transaction to execute
     * @return bytes returned from executing transaction
     */
    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) virtual external payable returns (bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

import "../ITimelock.sol";

contract Timelock is ITimelock {
    uint public immutable GRACE_PERIOD;
    uint public immutable MINIMUM_DELAY;
    uint public immutable MAXIMUM_DELAY;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping (bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint delay_, uint gracePeriod_, uint minimumDelay_, uint maxiumumDelay_) public {
        require(delay_ >= minimumDelay_, "Timelock::constructor: Delay must exceed minimum delay.");
        require(delay_ <= maxiumumDelay_, "Timelock::setDelay: Delay must not exceed maximum delay.");

        GRACE_PERIOD = gracePeriod_;
        MINIMUM_DELAY = minimumDelay_;
        MAXIMUM_DELAY = maxiumumDelay_;

        admin = admin_;
        delay = delay_;
    }

    fallback() external payable { }

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay: Call must come from Timelock.");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin: Call must come from pendingAdmin.");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin: Call must come from Timelock.");
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= (getBlockTimestamp() + delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= (eta + GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }
}