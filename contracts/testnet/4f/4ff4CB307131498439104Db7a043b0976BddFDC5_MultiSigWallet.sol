// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract MultiSigWallet {
    uint public constant MAX_OWNER_COUNT = 50;

    event Deposit(address indexed sender, uint value);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequirementChanged(uint required);
    event TransactionSubmitted(uint indexed transactionId);
    event TransactionConfirmed(
        address indexed owner,
        uint indexed transactionId
    );
    event TransactionRevoked(address indexed owner, uint indexed transactionId);
    event TransactionExecuted(uint indexed transactionId, bool success);

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;

    modifier onlyWallet() {
        require(msg.sender == address(this), "Not called by the wallet");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner], "Owner already exists");
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner], "Owner does not exist");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(
            transactions[transactionId].destination != address(0),
            "Transaction does not exist"
        );
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(
            confirmations[transactionId][owner],
            "Transaction not confirmed by owner"
        );
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(
            !confirmations[transactionId][owner],
            "Transaction already confirmed by owner"
        );
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(
            !transactions[transactionId].executed,
            "Transaction already executed"
        );
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0), "Address cannot be null");
        _;
    }

    modifier validRequirement(uint ownerCount, uint _required) {
        require(
            ownerCount <= MAX_OWNER_COUNT &&
                _required <= ownerCount &&
                _required != 0 &&
                ownerCount != 0,
            "Invalid requirement"
        );
        _;
    }

    constructor(
        address[] memory _owners,
        uint _required
    ) validRequirement(_owners.length, _required) {
        for (uint i = 0; i < _owners.length; i++) {
            require(
                !isOwner[_owners[i]] && _owners[i] != address(0),
                "Invalid owner"
            );
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

    function addOwner(
        address owner
    )
        external
        onlyWallet
        ownerDoesNotExist(owner)
        notNull(owner)
        validRequirement(owners.length + 1, required)
    {
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAdded(owner);
    }

    function removeOwner(address owner) external onlyWallet ownerExists(owner) {
        isOwner[owner] = false;
        for (uint i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        if (required > owners.length) {
            changeRequirement(owners.length);
        }
        emit OwnerRemoved(owner);
    }

    function replaceOwner(
        address owner,
        address newOwner
    ) external onlyWallet ownerExists(owner) ownerDoesNotExist(newOwner) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoved(owner);
        emit OwnerAdded(newOwner);
    }

    function changeRequirement(
        uint _required
    ) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChanged(_required);
    }

    function submitTransaction(
        address destination,
        uint value,
        bytes calldata data
    ) external returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

    function confirmTransaction(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit TransactionConfirmed(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    function revokeConfirmation(
        uint transactionId
    )
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit TransactionRevoked(msg.sender, transactionId);
    }

    function executeTransaction(
        uint transactionId
    ) public notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage tx = transactions[transactionId];
            tx.executed = true;
            (bool success, ) = tx.destination.call{value: tx.value}(
                bytes(tx.data)
            );
            emit TransactionExecuted(transactionId, success);
        }
    }

 
    function isConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    function addTransaction(
        address destination,
        uint value,
        bytes memory data
    ) internal notNull(destination) returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit TransactionSubmitted(transactionId);
    }

    function getConfirmationCount(
        uint transactionId
    ) external view returns (uint count) {
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

    function getTransactionCount(
        bool pending,
        bool executed
    ) external view returns (uint count) {
        for (uint i = 0; i < transactionCount; i++) {
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                count += 1;
            }
        }
    }

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getConfirmations(
        uint transactionId
    ) external view returns (address[] memory _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }
        _confirmations = new address[](count);
        for (uint i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }

    function getTransactionIds(
        uint from,
        uint to,
        bool pending,
        bool executed
    ) external view returns (uint[] memory _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        for (uint i = 0; i < transactionCount; i++) {
            if (
                (pending && !transactions[i].executed) ||
                (executed && transactions[i].executed)
            ) {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        }
        _transactionIds = new uint[](to - from);
        for (uint i = from; i < to; i++) {
            _transactionIds[i - from] = transactionIdsTemp[i];
        }
    }
}