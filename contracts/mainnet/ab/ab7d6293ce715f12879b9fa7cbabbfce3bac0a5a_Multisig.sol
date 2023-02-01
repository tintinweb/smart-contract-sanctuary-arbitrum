// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Multisig {
    struct Transaction {
        uint256 time;
        address target;
        uint256 value;
        bytes data;
        bool executed;
    }

    uint256 public transactionCount;
    uint256 public threshold;
    uint256 public delay;
    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(address => bool) public isProposer;
    mapping(address => bool) public isExecutor;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event SetThreshold(uint256 threshold);
    event SetDelay(uint256 delay);
    event SetProposer(address user, bool value);
    event SetExecuter(address user, bool value);
    event OwnerAdded(address indexed owner, uint256 threshold);
    event OwnerRemoved(address indexed owner, uint256 threshold);
    event TransactionAdded(uint256 indexed id, address indexed sender, address target, uint256 valu, bytes data);
    event TransactionConfirmed(uint256 indexed id, address indexed sender);
    event TransactionExecuted(uint256 indexed id, address indexed sender);
    event TransactionReverted(uint256 indexed id, address indexed sender, bytes err);
    event TransactionCancelled(uint256 indexed id, address indexed sender);

    constructor(address owner) {
        owners.push(owner);
        isOwner[owner] = true;
        threshold = 1;
    }

    fallback() external payable {}

    function setThreshold(uint256 _threshold) public {
        require(msg.sender == address(this), "not wallet");
        require(_threshold <= owners.length, "threshold too big");
        threshold = _threshold;
        emit SetThreshold(_threshold);
    }

    function setDelay(uint256 _delay) public {
        require(msg.sender == address(this), "not wallet");
        require(_delay <= 7 days, "delay too big");
        delay = _delay;
        emit SetDelay(_delay);
    }

    function addOwner(address owner, uint256 _threshold) public {
        require(msg.sender == address(this), "not wallet");
        require(!isOwner[owner], "owner exists");
        require(_threshold <= owners.length + 1, "threshold too big");
        threshold = _threshold;
        isOwner[owner] = true;
        owners.push(owner);
        emit OwnerAdded(owner, threshold);
    }

    function removeOwner(address owner, uint256 _threshold) public {
        require(msg.sender == address(this), "not wallet");
        require(isOwner[owner], "owner does not exist");
        require(_threshold <= owners.length - 1, "threshold too big");
        threshold = _threshold;
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }
        owners.pop();
        emit OwnerRemoved(owner, threshold);
    }

    function setProposer(address user, bool value) public {
        require(msg.sender == address(this), "not wallet");
        isProposer[user] = value;
        emit SetProposer(user, value);
    }

    function setExecuter(address user, bool value) public {
        require(msg.sender == address(this), "not wallet");
        isExecutor[user] = value;
        emit SetExecuter(user, value);
    }

    function add(address target, uint256 value, bytes calldata data) public returns (uint256) {
        require(isOwner[msg.sender] || isProposer[msg.sender], "unauthorized");
        uint256 id = transactionCount;
        transactions[id] =
            Transaction({time: block.timestamp, target: target, value: value, data: data, executed: false});
        transactionCount += 1;
        emit TransactionAdded(id, msg.sender, target, value, data);
        if (isOwner[msg.sender]) confirm(id, false);
        return id;
    }

    function confirm(uint256 id, bool _execute) public {
        require(isOwner[msg.sender], "unauthorized");
        require(!confirmations[id][msg.sender], "already confirmed");
        require(!transactions[id].executed, "already executed");
        confirmations[id][msg.sender] = true;
        emit TransactionConfirmed(id, msg.sender);
        if (_execute) execute(id);
    }

    function cancel(uint256 id) public {
        Transaction storage tx = transactions[id];
        require(isOwner[msg.sender], "unauthorized");
        require(block.timestamp > tx.time + (15 * 60), "before grace");
        require(!tx.executed, "already executed");
        tx.time = type(uint256).max;
        emit TransactionCancelled(id, msg.sender);
    }

    function execute(uint256 id) public {
        Transaction storage tx = transactions[id];
        (uint256 count,) = getInfo(id);
        require(isOwner[msg.sender] || isExecutor[msg.sender], "unauthorized");
        require(count >= threshold, "under threshold");
        require(block.timestamp >= tx.time + delay, "before delay");
        require(!tx.executed, "already executed");
        tx.executed = true;
        (bool success, bytes memory err) = tx.target.call{value: tx.value}(tx.data);
        if (!success) {
            emit TransactionReverted(id, msg.sender, err);
            revert("transaction reverted");
        }
        emit TransactionExecuted(id, msg.sender);
    }

    function getInfo(uint256 id) public view returns (uint256, bool[] memory) {
        uint256 count = 0;
        bool[] memory tmp = new bool[](owners.length);
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[id][owners[i]]) {
                count += 1;
                tmp[i] = true;
            }
        }
        return (count, tmp);
    }

    function getPage(uint256 start, uint256 end)
        public
        view
        returns (
            uint256[] memory time,
            address[] memory target,
            uint256[] memory value,
            bytes[] memory data,
            bool[] memory executed,
            uint256[] memory count
        )
    {
        time = new uint[](end - start);
        target = new address[](end - start);
        value = new uint[](end - start);
        data = new bytes[](end - start);
        executed = new bool[](end - start);
        count = new uint[](end - start);
        for (uint256 i = start; i < end; i++) {
            Transaction memory tx = transactions[i];
            (uint256 c,) = getInfo(i);
            time[i - start] = tx.time;
            target[i - start] = tx.target;
            value[i - start] = tx.value;
            data[i - start] = tx.data;
            executed[i - start] = tx.executed;
            count[i - start] = c;
        }
    }

    function getSummary() public view returns (uint256, uint256, uint256, uint256) {
        return (transactionCount, threshold, owners.length, delay);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }
}