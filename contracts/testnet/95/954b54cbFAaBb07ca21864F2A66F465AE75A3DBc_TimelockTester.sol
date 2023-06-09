// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "../Timelock.sol";

contract TimelockTester is Timelock {
    modifier isValidDelay(uint256 _delay) override {
        _;
    }

    constructor(uint _delay) Timelock(_delay) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Timelock {
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data,
        uint eta
    );

    error Timelock__DelayMustExceedMininumDelay();
    error Timelock__DelayMustNotExceedMaximumDelay();
    error Timelock__TimelockOnly();
    error Timelock__PendingAdminOnly();
    error Timelock__AdminOnly();
    error Timelock__ETAMustSatisfyDelay();
    error Timelock__TxNoQueued();
    error Timelock__TxAlreadyQueued();
    error Timelock__TxStillLocked();
    error Timelock__TxExpired();
    error Timelock__TxReverted();

    string public constant NAME = "Timelock";

    uint public constant GRACE_PERIOD = 14 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 15 days;

    address public admin;
    address public pendingAdmin;
    uint public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    modifier isValidDelay(uint256 _delay) virtual {
        if (_delay < MINIMUM_DELAY) {
            revert Timelock__DelayMustExceedMininumDelay();
        }
        if (_delay > MAXIMUM_DELAY) {
            revert Timelock__DelayMustNotExceedMaximumDelay();
        }
        _;
    }

    modifier adminOnly() {
        if (msg.sender != admin) {
            revert Timelock__AdminOnly();
        }
        _;
    }

    constructor(uint _delay) isValidDelay(_delay) {
        admin = msg.sender;
        delay = _delay;
    }

    receive() external payable {}

    function setDelay(uint _delay) public isValidDelay(_delay) {
        if (msg.sender != address(this)) {
            revert Timelock__TimelockOnly();
        }
        delay = _delay;

        emit NewDelay(_delay);
    }

    function acceptAdmin() public {
        if (msg.sender != pendingAdmin) {
            revert Timelock__PendingAdminOnly();
        }
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        if (msg.sender != address(this)) {
            revert Timelock__TimelockOnly();
        }
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public adminOnly returns (bytes32) {
        if (
            eta < block.timestamp + delay ||
            eta > block.timestamp + delay + GRACE_PERIOD
        ) {
            revert Timelock__ETAMustSatisfyDelay();
        }

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        if (queuedTransactions[txHash]) {
            revert Timelock__TxAlreadyQueued();
        }
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public adminOnly {
        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        if (!queuedTransactions[txHash]) {
            revert Timelock__TxNoQueued();
        }
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data,
        uint eta
    ) public payable adminOnly returns (bytes memory) {
        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        if (!queuedTransactions[txHash]) {
            revert Timelock__TxNoQueued();
        }
        if (block.timestamp < eta) {
            revert Timelock__TxStillLocked();
        }
        if (block.timestamp > eta + GRACE_PERIOD) {
            revert Timelock__TxExpired();
        }

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // Execute the call
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        if (!success) {
            revert Timelock__TxReverted();
        }

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }
}