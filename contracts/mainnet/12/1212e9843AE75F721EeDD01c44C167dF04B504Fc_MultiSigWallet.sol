// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;


interface iMultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    error NotOwner(address owner); 
    error TxNotExists(address owner, uint256 txIndex);
    error TxExecuted(address owner, uint256 txIndex);
    error TxConfirmed(address owner, uint256 txIndex);
    error EmptyOwners();
    error InvalidRequiredConfirmations(uint256 required, uint256 ownersLength);
    error InvalidOwner(address owner);
    error NotUniqueOwner(address owner);
    error NotEnoughConfirmations(uint256 numConfirmations, uint256 numConfirmationsRequired);
    error TransactionCallFailed(address to, uint256 value, bytes data, bytes reason);
    error TxNotConfirmed(uint256 txIndex, address owner);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;
import "./interfaces/iMultiSigWallet.sol";


contract MultiSigWallet is iMultiSigWallet {
    address[] public owners;
    mapping (address => bool) public isOwner;
    uint256 public numConfirmationsRequired;
    // mapping from tx index => owner => bool
    mapping (uint256 => mapping (address => bool)) public isConfirmed;
    Transaction[] public transactions;

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotOwner(msg.sender);
        }
        _;
    }
    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) {
            revert TxNotExists(msg.sender, _txIndex);
        }
        _;
    }
    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) {
            revert TxExecuted(msg.sender, _txIndex);
        }
        _;
    }
    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) {
            revert TxConfirmed(msg.sender, _txIndex);
        }
        _;
    }

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        if (_owners.length == 0) {
            revert EmptyOwners();
        }
        if (_numConfirmationsRequired == 0 || _numConfirmationsRequired > _owners.length) {
            revert InvalidRequiredConfirmations(_numConfirmationsRequired, _owners.length);
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert InvalidOwner(owner);
            }
            if (isOwner[owner]) {
                revert NotUniqueOwner(owner);
            }

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(address _to, uint256 _value, bytes memory _data)
        public
        onlyOwner
    {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        }));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmedTransaction(uint256 _txIndex)
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

    function executeTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        if (transaction.numConfirmations < numConfirmationsRequired) {
            revert NotEnoughConfirmations(transaction.numConfirmations, numConfirmationsRequired);
        }

        transaction.executed = true;

        (bool success, bytes memory reason) = transaction.to.call{value: transaction.value}(transaction.data);
        if (!success) {
            revert TransactionCallFailed(transaction.to, transaction.value, transaction.data, reason);
        }
        
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        if (!isConfirmed[_txIndex][msg.sender]) {
            revert TxNotConfirmed(_txIndex, msg.sender);
        }

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(uint256 _txIndex)
        public
        view
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations)
    {
        Transaction memory transaction = transactions[_txIndex];
        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }

}