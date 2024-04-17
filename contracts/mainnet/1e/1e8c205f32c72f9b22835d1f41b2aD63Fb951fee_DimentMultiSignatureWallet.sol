// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Errors
error OnlyOwners(address user);
error AlreadyOwner(address user);
error OwnerNotFound(address user);
error CallerIsNotItsSelf();
error TxNotExists(uint16 txId);
error TxNotConfirmed(uint16 txId);
error AlreadyExecuted(uint16 txId);
error AlreadyCorfirmed(uint16 txId);
error NullAdress();
error NotVaildRequirement();
error ZeroAddress();
error NotEnoughConfirmation();

contract DimentMultiSignatureWallet {
    event Received(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint16 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint16 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint16 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint16 indexed txIndex);

    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event RequirementChange(uint8 required);

    event ETHRemoved(address to);

    address[] private _owners;
    uint8 internal ownersCount;
    uint8 private constant _MAX_OWNER_COUNT = 50;

    mapping(address => bool) public isOwner;
    uint8 public numConfirmationsRequired;

    struct Transaction {
        uint256 value;
        bytes data;
        address to;
        uint8 executed;
        uint8 numConfirmations;
    }

    // mapping from tx index => owner => bool
    mapping(uint16 => mapping(address => bool)) public isConfirmed;

    // @dev transaction list
    Transaction[] public transactions;
    uint16 public transactionIndex;

    // @dev only owner modifier
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert OnlyOwners(msg.sender);
        }
        _;
    }

    // @dev check the owner not in the owner list modifier
    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner]) {
            revert AlreadyOwner(owner);
        }
        _;
    }

    // @dev check the owner is in the owner list modifier
    modifier ownerExists(address owner) {
        if (!isOwner[owner]) {
            revert OwnerNotFound(owner);
        }
        _;
    }

    // @dev check the wallet is caller of transactions, used for in call like owner functions
    modifier onlyWallet() {
        if (msg.sender != address(this)) {
            revert CallerIsNotItsSelf();
        }
        _;
    }

    // @dev check incoming id is in the transactions list range
    modifier txExists(uint16 _txIndex) {
        if (_txIndex >= transactions.length) {
            revert TxNotExists(_txIndex);
        }
        _;
    }

    // @dev check incoming id is not executed
    modifier notExecuted(uint16 _txIndex) {
        if (transactions[_txIndex].executed == 1) {
            revert AlreadyExecuted(_txIndex);
        }
        _;
    }

    // @dev check incoming id is not confirmed
    modifier notConfirmed(uint16 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) {
            revert AlreadyCorfirmed(_txIndex);
        }
        _;
    }

    // @dev check incoming address is not null
    modifier notNull(address _address) {
        if (_address != address(0)) {
            revert NullAdress();
        }
        _;
    }

    // @dev check requirements for owner and required wallets
    modifier validRequirement(uint8 ownerCount, uint8 _required) {
        if (
            ownerCount >= _MAX_OWNER_COUNT ||
            _required > ownerCount ||
            _required == 0 ||
            ownerCount == 0
        ) {
            revert NotVaildRequirement();
        }

        _;
    }

    /**
     * @dev constructor of contract
     * @param owners_ owners array
     * @param numConfirmationsRequired_ transaction confirmation required amount
     */
    //
    constructor(address[] memory owners_, uint8 numConfirmationsRequired_) {
        uint256 arrLength = owners_.length;
        if (arrLength == 0) {
            revert NotVaildRequirement();
        }

        if (
            numConfirmationsRequired_ == 0 ||
            numConfirmationsRequired_ > arrLength
        ) {
            revert NotVaildRequirement();
        }

        uint8 i;

        for (i = 0; i < arrLength; i++) {
            address owner = owners_[i];

            if (owner == address(0)) {
                revert ZeroAddress();
            }
            if (isOwner[owner]) {
                revert AlreadyOwner(owner);
            }

            isOwner[owner] = true;
            _owners.push(owner);
        }

        // set memory value to storage
        ownersCount = i;

        numConfirmationsRequired = numConfirmationsRequired_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value, address(this).balance);
    }

    /**
     * @dev add transaction to transaction list
     * @param to_ transaction will execute on this address
     * @param value_ amount ether we want to send
     * @param data_ transaction data that encoded
     */
    //
    function submitTransaction(
        address to_,
        uint256 value_,
        bytes memory data_
    ) external onlyOwner {
        uint16 txIndex = transactionIndex;

        // transaction index update
        transactionIndex++;

        transactions.push(
            Transaction({
                to: to_,
                value: value_,
                data: data_,
                executed: 0,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, to_, value_, data_);
    }

    /**
     * @dev owners can confirm transaction that the list that not confirmed and not executed yet
     * @param txIndex_ transaction id
     */
    function confirmTransaction(
        uint16 txIndex_
    )
        external
        onlyOwner
        txExists(txIndex_)
        notExecuted(txIndex_)
        notConfirmed(txIndex_)
    {
        Transaction storage transaction = transactions[txIndex_];
        transaction.numConfirmations += 1;
        isConfirmed[txIndex_][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, txIndex_);
    }

    /**
     * @dev owners can executed transaction that in the list and not executed yet
     * @param txIndex_ transaction id
     */
    //
    function executeTransaction(
        uint16 txIndex_
    ) external onlyOwner txExists(txIndex_) notExecuted(txIndex_) {
        Transaction storage transaction = transactions[txIndex_];

        if (transaction.numConfirmations < numConfirmationsRequired) {
            revert NotEnoughConfirmation();
        }

        transaction.executed = 1;

        emit ExecuteTransaction(msg.sender, txIndex_);

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx failed");
    }

    /**
     * @dev owners can revoke transaction that in the list and not executed
     * @param txIndex_ transaction id
     */
    //
    function revokeConfirmation(
        uint16 txIndex_
    ) external onlyOwner txExists(txIndex_) notExecuted(txIndex_) {
        Transaction storage transaction = transactions[txIndex_];

        if (!isConfirmed[txIndex_][msg.sender]) {
            revert TxNotConfirmed(txIndex_);
        }

        transaction.numConfirmations -= 1;
        isConfirmed[txIndex_][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, txIndex_);
    }

    /**
     * @dev get transaction count
     */
    //
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev get single transaction details
     * @param txIndex_ transaction id
     */
    //
    function getTransaction(
        uint16 txIndex_
    )
        external
        view
        returns (
            uint256 value,
            bytes memory data,
            address to,
            uint8 executed,
            uint8 numConfirmations
        )
    {
        Transaction memory transaction = transactions[txIndex_];

        return (
            transaction.value,
            transaction.data,
            transaction.to,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    /**
     * @dev add new owner buy calling itself
     * @param owner_ new owners address
     */
    //
    function addOwner(
        address owner_
    )
        external
        onlyWallet
        ownerDoesNotExist(owner_)
        notNull(owner_)
        validRequirement(ownersCount, numConfirmationsRequired)
    {
        isOwner[owner_] = true;
        _owners.push(owner_);
        ownersCount++;
        emit OwnerAdded(owner_);
    }

    /**
     * @dev replace old owner with the new owner buy calling itself
     * @param owner_ owner will remove
     * @param newOwner_ owner will replace
     */
    //
    function replaceOwner(
        address owner_,
        address newOwner_
    ) external onlyWallet ownerExists(owner_) ownerDoesNotExist(newOwner_) {
        for (uint8 i = 0; i < ownersCount; i++)
            if (_owners[i] == owner_) {
                _owners[i] = newOwner_;
                break;
            }
        isOwner[owner_] = false;
        isOwner[newOwner_] = true;
        emit OwnerRemoved(owner_);
        emit OwnerAdded(newOwner_);
    }

    /**
     * @dev remove the owner from the owners buy calling itself
     * @param owner_ address to remove
     */
    //
    function removeOwner(
        address owner_
    ) external onlyWallet ownerExists(owner_) {
        isOwner[owner_] = false;

        for (uint8 i = 0; i < ownersCount; i++)
            if (_owners[i] == owner_) {
                _owners[i] = _owners[ownersCount - 1];
                break;
            }

        _owners.pop();
        ownersCount--;

        if (numConfirmationsRequired > ownersCount) {
            changeRequirement(ownersCount);
        }

        emit OwnerRemoved(owner_);
    }

    /**
     * @dev add new owner buy calling itself
     * @param required_ amount for minimum confirmations
     */
    //
    function changeRequirement(
        uint8 required_
    ) public onlyWallet validRequirement(ownersCount, required_) {
        numConfirmationsRequired = required_;
        emit RequirementChange(required_);
    }

    /**
     * @dev remove native token from contract
     * @param to_ who will recive funds
     */
    function recoverETH(address payable to_) external onlyWallet {
        require(to_ != address(0), "ERC20: transfer to the zero address");
        require(address(this).balance > 0, "ERC20: zero native balance");

        emit ETHRemoved(to_);
        (bool sent, ) = to_.call{value: address(this).balance}("");
        require(sent, "ERC20: ETH_TX_FAIL on recover ETH");
    }
}