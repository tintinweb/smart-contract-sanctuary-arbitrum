// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract RwaxTimelock {
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 12 hours;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    modifier onlyTimelock() {
        _validateTimelock();
        _;
    }

    modifier onlyAdmin() {
        _validateAdmin();
        _;
    }

    constructor(address _admin, uint256 _delay) {
        if (_delay < MINIMUM_DELAY || delay > MAXIMUM_DELAY) {
            revert ValueNotInRange(_delay, MINIMUM_DELAY, MAXIMUM_DELAY);
        }
        admin = _admin;
        delay = _delay;
    }

    function setDelay(uint256 _delay) public onlyTimelock {
        if (_delay < MINIMUM_DELAY || _delay > MAXIMUM_DELAY) {
            revert ValueNotInRange(_delay, MINIMUM_DELAY, MAXIMUM_DELAY);
        }
        delay = _delay;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        if (msg.sender != pendingAdmin) {
            revert OnlyPendingAdminAllowed(msg.sender);
        }
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public onlyTimelock {
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        public
        onlyAdmin
        returns (bytes32)
    {
        if (eta < _getBlockTimestamp() + delay) {
            revert EstimatedExecutionTimeNotSatisfyDelay();
        }

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        public
        onlyAdmin
    {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        public
        payable
        onlyAdmin
        returns (bytes memory)
    {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        if (!queuedTransactions[txHash]) {
            revert TransactionNotEnqueued();
        }
        uint256 _now = _getBlockTimestamp();
        if (_now < eta) {
            revert TransactionLocked(txHash);
        }
        if (_now > eta + GRACE_PERIOD) {
            revert TransactionStaled(txHash);
        }

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // Execute the call
        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        if (!success) {
            revert TransactionExecutionReverted(txHash);
        }

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function _getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function _validateTimelock() internal view {
        if (msg.sender != address(this)) revert OnlyTimelockAllowed(msg.sender);
    }

    function _validateAdmin() internal view {
        if (msg.sender != admin) revert OnlyAdminAllowed(msg.sender);
    }

    // ========= ERRORS ========
    error OnlyTimelockAllowed(address sender);
    error OnlyAdminAllowed(address sender);
    error OnlyPendingAdminAllowed(address sender);
    error ValueNotInRange(uint256 value, uint256 min, uint256 max);
    error EstimatedExecutionTimeNotSatisfyDelay();
    error TransactionNotEnqueued();
    error TransactionLocked(bytes32 txHash);
    error TransactionStaled(bytes32 txHash);
    error TransactionExecutionReverted(bytes32 txHash);

    // ========= EVENTS ========
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta
    );
}