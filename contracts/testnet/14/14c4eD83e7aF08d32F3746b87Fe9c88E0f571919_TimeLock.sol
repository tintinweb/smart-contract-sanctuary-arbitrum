// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TimeLock {
  error NotOwnerError();
  error AlreadyQueuedError(bytes32 txId);
  error TimestampNotInRangeError(uint blockTimestamp, uint timestamp);
  error NotQueuedError(bytes32 txId);
  error TimestampNotPassedError(uint blockTimestmap, uint timestamp);
  error TimestampExpiredError(uint blockTimestamp, uint expiresAt);
  error TxFailedError();

  event Queue(
    bytes32 indexed txId,
    address indexed target,
    string func,
    bytes data,
    uint timestamp
  );
  event Execute(
    bytes32 indexed txId,
    address indexed target,
    string func,
    bytes data,
    uint timestamp
  );
  event Cancel(bytes32 indexed txId);

  uint public constant MIN_DELAY = 24 hours; 
  uint public constant MAX_DELAY = 72 hours; 
  uint public constant GRACE_PERIOD = 24 hours; 

  address public owner;
  // tx id => queued
  mapping(bytes32 => bool) public queued;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert NotOwnerError();
    }
    _;
  }

  function changeOwner(
    address _target
  ) external onlyOwner {
    require(_target != address(0), "address zero");
    owner = _target;
  }

  function getTxId(
    address _target,
    string calldata _func,
    bytes calldata _data,
    uint _timestamp
  ) public pure returns (bytes32) {
    return keccak256(abi.encode(_target, _func, _data, _timestamp));
  }


  function queue(
    address _target,
    string calldata _func,
    bytes calldata _data,
    uint _timestamp
  ) external onlyOwner returns (bytes32 txId) {
    txId = getTxId(_target, _func, _data, _timestamp);
    if (queued[txId]) {
      revert AlreadyQueuedError(txId);
    }

    if (
      _timestamp < block.timestamp + MIN_DELAY ||
        _timestamp > block.timestamp + MAX_DELAY
    ) {
      revert TimestampNotInRangeError(block.timestamp, _timestamp);
    }

    queued[txId] = true;

    emit Queue(txId, _target, _func, _data, _timestamp);
  }

  function execute(
    address _target,
    string calldata _func,
    bytes calldata _data,
    uint _timestamp
  ) external onlyOwner returns (bytes memory) {
    bytes32 txId = getTxId(_target, _func, _data, _timestamp);
    if (!queued[txId]) {
      revert NotQueuedError(txId);
    }

    if (block.timestamp < _timestamp) {
      revert TimestampNotPassedError(block.timestamp, _timestamp);
    }
    if (block.timestamp > _timestamp + GRACE_PERIOD) {
      revert TimestampExpiredError(block.timestamp, _timestamp + GRACE_PERIOD);
    }

    queued[txId] = false;

    // prepare data
    bytes memory data;
    if (bytes(_func).length > 0) {
      // data = func selector + _data
      data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
    } else {
      // call fallback with data
      data = _data;
    }

    // call target
    (bool ok, bytes memory res) = _target.call(data);
    if (!ok) {
      revert TxFailedError();
    }

    emit Execute(txId, _target, _func, _data, _timestamp);

    return res;
  }

  function cancel(bytes32 _txId) external onlyOwner {
    if (!queued[_txId]) {
      revert NotQueuedError(_txId);
    }

    queued[_txId] = false;

    emit Cancel(_txId);
  }
}