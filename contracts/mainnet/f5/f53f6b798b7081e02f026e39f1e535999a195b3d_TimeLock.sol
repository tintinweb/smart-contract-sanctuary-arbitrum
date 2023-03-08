import {IVaultFactoryV2} from "./interfaces/IVaultFactoryV2.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// source: https://solidity-by-example.org/app/time-lock/

contract TimeLock {
    mapping(bytes32 => bool) public queued;

    address public policy;

    uint32 public constant MIN_DELAY = 3 days;
    uint32 public constant MAX_DELAY = 30 days;
    uint32 public constant GRACE_PERIOD = 14 days;

    /** @notice constructor
        @param _policy  address of the policy contract;
      */
    constructor(address _policy) {
        if (_policy == address(0)) {
            revert AddressZero();
        }
        policy = _policy;
    }

    /**
     * @dev leave params zero if not using them
     * @notice Queue a transaction
     * @param _target The target contract
     * @param _value The value to send to the function
     * @param _func The function to call
     * @param _data The data to pass to the function
     * @param _timestamp The timestamp to execute the transaction
     */
    function queue(
        address _target,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) external onlyOwner {
        //create tx id
        bytes32 txId = getTxId(
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );

        //check tx id unique
        if (queued[txId]) {
            revert AlreadyQueuedError(txId);
        }

        //check timestamp
        if (
            _timestamp < block.timestamp + MIN_DELAY ||
            _timestamp > block.timestamp + MAX_DELAY
        ) {
            revert TimestampNotInRangeError(block.timestamp, _timestamp);
        }

        //queue tx
        queued[txId] = true;

        emit Queue(
            txId,
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );
    }

    /**
     * @dev leave params zero if not using them
     * @notice Execute a Queued a transaction
     *  @param _target The target contract
     *  @param _value The value to send to the function
     *  @param _func The function to call
     *  @param _data The data to pass to the function
     *  @param _timestamp The timestamp after which to execute the transaction
     */
    function execute(
        address _target,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) external onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //check block.timestamp > timestamp
        if (block.timestamp < _timestamp) {
            revert TimestampNotPassedError(block.timestamp, _timestamp);
        }
        if (block.timestamp > _timestamp + GRACE_PERIOD) {
            revert TimestampExpiredError(
                block.timestamp,
                _timestamp + GRACE_PERIOD
            );
        }

        //delete tx from queue
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
        (bool ok, bytes memory res) = _target.call{value: _value}(data);
        if (!ok) {
            revert TxFailedError(_func);
        }
    

        emit Execute(
            txId,
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );
        
        return res;
    }

    /** @notice cancels the transaction
        *  @param _target The target contract
        *  @param _value The value to send to the function
        *  @param _func The function to call
        *  @param _data The data to pass to the function
        *  @param _timestamp The timestamp after which to execute the transaction
     */
    function cancel(
        address _target,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) external onlyOwner {
        bytes32 txId = getTxId(
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );

        //check tx id queued
        if (!queued[txId]) {
            revert NotQueuedError(txId);
        }

        //delete tx from queue
        queued[txId] = false;

        emit Delete(
            txId,
            _target,
            _value,
            _func,
            _data,
            _timestamp
        );
    }

    /** @notice get transaction id
        *  @param _target The target contract
        *  @param _func The function to call
        *  @param _value The value to send to the function
        *  @param _data The data to pass to the function
        *  @param _timestamp The timestamp after which to execute the transaction
        *  @return txId
     */
    function getTxId(
        address _target,
        uint256 _value,
        string calldata _func,
        bytes calldata _data,
        uint256 _timestamp
    ) public pure returns (bytes32 txId) {
        return
            keccak256(
                abi.encode(
                    _target,
                    _value,
                    _func,
                    _data,
                    _timestamp
                )
            );
    }

    /** @notice change owner
        *  @param _newOwner new owner
    */
    function changeOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) {
            revert AddressZero();
        }
        policy = _newOwner;
        emit ChangeOwner(_newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotOwner(address sender);
    error AlreadyQueuedError(bytes32 txId);
    error TimestampNotInRangeError(uint256 blocktimestamp, uint256 timestamp);
    error NotQueuedError(bytes32 txId);
    error TimestampNotPassedError(uint256 blocktimestamp, uint256 timestamp);
    error TimestampExpiredError(uint256 blocktimestamp, uint256 timestamp);
    error TxFailedError(string func);
    error AddressZero();

    
    /** @notice queues transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param value value to send to the function
        @param func function to call
        @param data data to pass to the function
        @param timestamp timestamp to execute the transaction
     */
    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint256 value,
        string func,
        bytes data,
        uint256 timestamp
    );

    /** @notice executes transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param value value to send to the function
        @param func function to call
        @param data data to pass to the function
        @param timestamp timestamp to execute the transaction
     */
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint256 value,
        string func,
        bytes data,
        uint256 timestamp
    );

    /** @notice deletes transaction when emitted
        @param txId unique id of the transaction
        @param target contract to call
        @param value value to send to the function
        @param func function to call
        @param data data to pass to the function
        @param timestamp timestamp to execute the transaction
     */
    event Delete(
        bytes32 indexed txId,
        address indexed target,
        uint256 value,
        string func,
        bytes data,
        uint256 timestamp
    );

    /** @notice only owner can call functions with this modifier
     */
    modifier onlyOwner() {
        if (msg.sender != policy) revert NotOwner(msg.sender);
        _;
    }

    /** @notice changes owner when emitted
        @param newOwner new owner
     */
    event ChangeOwner(address indexed newOwner);
}

pragma solidity 0.8.17;

interface IVaultFactoryV2 {
    function createNewMarket(
        uint256 fee,
        address token,
        address depeg,
        uint256 beginEpoch,
        uint256 endEpoch,
        address oracle,
        string memory name
    ) external returns (address);

    function getVaults(uint256) external view returns (address[2] memory);

    function getEpochFee(uint256) external view returns (uint16);

    function tokenToOracle(address token) external view returns (address);
}