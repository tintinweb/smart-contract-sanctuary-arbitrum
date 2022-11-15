// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

interface IPoolProxy {
    function freezePool(bool freeze) external; 
}

contract ShellMultiSig {

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event QueueTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);
    event CancelTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    uint public delay;

    uint public constant GRACE_PERIOD = 60 * 60 * 3; // 3 hour grace period

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        uint executeTimestamp;
    }

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => bool) public queued;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not the owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "Tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "Tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "Tx already confirmed");
        _;
    }

    modifier notQueued(uint _txIndex) {
        require(!queued[_txIndex], "Tx already queued");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired, uint _delay) {
        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "Invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Owner cannot be the zero address");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        delay = _delay;
    }

    function freezePool(address pool) public onlyOwner {
        IPoolProxy(pool).freezePool(true);
    }

    function submitUnfreezePool(address pool) public onlyOwner { // Unfreezes are automatically queued so they can be executed with no delay
        uint txIndex = transactions.length;

        bytes memory _data = abi.encodeWithSignature("freezePool(bool)", false);

        transactions.push(
            Transaction({
                to: pool,
                value: 0,
                data: _data,
                executed: false,
                numConfirmations: 0,
                executeTimestamp: block.timestamp
            })
        );

        queued[txIndex] = true;

        emit SubmitTransaction(msg.sender, txIndex, pool, 0, _data);
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0,
                executeTimestamp: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function queueTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notQueued(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Tx does not have sufficient confirmations"
        );

        queued[_txIndex] = true;
        transaction.executeTimestamp = block.timestamp + delay;

        emit QueueTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Tx does not have sufficient confirmations"
        );
        require(queued[_txIndex], "Tx has not been queued");
        require (block.timestamp >= transaction.executeTimestamp, "Tx cannot be executed yet"); 
        require(block.timestamp <= transaction.executeTimestamp + GRACE_PERIOD, "Tx grace period has expired");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notQueued(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "Tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function cancelTransaction(uint _txIndex)
        public 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(queued[_txIndex], "Tx has not been queued");

        queued[_txIndex] = false;
        transaction.executeTimestamp = 0;

        for(uint i = 0; i < owners.length; i++)
            isConfirmed[_txIndex][owners[i]] = false;
        transaction.numConfirmations = 0;
        
        emit CancelTransaction(msg.sender, _txIndex);
    }


    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numConfirmations
        );
    }
}