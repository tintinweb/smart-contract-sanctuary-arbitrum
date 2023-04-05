// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./canonical/arbitrum/IArbSys.sol";
import "./interfaces/IVeaInbox.sol";
import "./interfaces/IVeaOutbox.sol";

contract VeaInbox is IVeaInbox {

    /**
     * @dev Relayers watch for these events to construct merkle proofs to execute transactions on Gnosis Chain.
     * @param _to The address of the receiver.
     * @param _nonce The nonce of the message.
     * @param _data The data of the message.
     */
    event MessageSent(uint256 _nonce, address indexed _to, address indexed _msgSender, bytes _data);

    /**
     * The bridgers need to watch for these events and relay the
     * stateRoot on the FastBridgeReceiver.
     * @param epoch The epoch of the batch requested to send.
     * @param stateRoot The receiving domain encoded message data.
     */
    event SnapshotSaved(uint256 indexed epoch, bytes32 stateRoot);

    /**
     * @dev The event is emitted when messages are sent through the canonical arbiturm bridge.
     * @param epoch The epoch of the batch requested to send.
     * @param stateRoot The state root of batched messages.
     */
    event StaterootSent(uint256 indexed epoch, bytes32 stateRoot);

    IArbSys public constant ARB_SYS = IArbSys(address(100));
    uint256 public immutable epochPeriod; // Epochs mark the period between stateroot snapshots
    address public immutable receiver; // The receiver on ethereum.

    mapping(uint256 => bytes32) public stateRootSnapshots; // epoch => state root snapshot
    bytes32[64] public inbox;
    uint256 count; // max 2^64 messages

    /**
     * @dev Constructor.
     * @param _epochPeriod The duration between epochs.
     * @param _receiver The receiver on ethereum.
     */
    constructor(uint256 _epochPeriod, address _receiver) {
        epochPeriod = _epochPeriod;
        receiver = _receiver;
    }

    /**
     * @dev Sends the state root using Arbitrum's canonical bridge.
     */
    function sendStaterootSnapshot(uint256 _epochSnapshot) external virtual {
        uint256 epoch = block.timestamp / epochPeriod;
        require(_epochSnapshot <= epoch, "Epoch in the future.");
        bytes memory data = abi.encodeWithSelector(
            IChallengeResolver.resolveChallenge.selector,
            epoch,
            stateRootSnapshots[_epochSnapshot]
        );

        bytes32 ticketID = bytes32(ARB_SYS.sendTxToL1(receiver, data));

        emit StaterootSent(_epochSnapshot, ticketID);
    }

    /**
     * @dev Sends an arbitrary message to a receiving chain.
     * @param _to The address of the contract on the receiving chain which receives the calldata.
     * @param _data The message calldata, abi.encodeWithSelector(...)
     * @return msgId The message id, 1 indexed.
     */
    function sendMsg(address _to, bytes memory _data) external override returns (uint256) {
        uint256 oldCount = count;
        uint256 newCount = oldCount + 1;
        count = newCount;
        // Double Hash all leaves
        bytes32 leaf = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        oldCount, // zero indexed leaf in tree
                        msg.sender,
                        _to,
                        _data
                    )
                )
            )
        );

        uint256 hashBitField = (newCount ^ (oldCount)) & newCount;
        uint256 height;

        while ((hashBitField & 1) == 0) {
            bytes32 node = inbox[height];
            if (node > leaf)
                assembly {
                    // efficient hash
                    mstore(0x00, leaf)
                    mstore(0x20, node)
                    leaf := keccak256(0x00, 0x40)
                }
            else
                assembly {
                    // efficient hash
                    mstore(0x00, node)
                    mstore(0x20, leaf)
                    leaf := keccak256(0x00, 0x40)
                }
            unchecked {
                hashBitField /= 2;
                height++;
            }
        }
        inbox[height] = leaf;

        emit MessageSent(oldCount, _to, msg.sender, _data);

        return oldCount;
    }

    /**
     * Takes snapshot of state root.
     */
    function saveStateRootSnapshot() external {
        uint256 epoch = block.timestamp / epochPeriod;
        require(stateRootSnapshots[epoch] == bytes32(0), "Snapshot already taken for this epoch.");
        bytes32 stateRoot = getStateroot();
        stateRootSnapshots[epoch] = stateRoot;

        emit SnapshotSaved(epoch, stateRoot);
    }

    /**
     * @dev Gets the current state root.
     *  `O(log(n))` where `n` is the number of leaves.
     *  Note: Inlined from `merkle/MerkleTree.sol` for performance.
     */
    function getStateroot() internal view returns (bytes32 node) {
        uint256 size = count;
        uint256 height;
        bool isFirstHash = true;
        while (size > 0) {
            if ((size & 1) == 1) {
                // avoid redundant calculation
                if (isFirstHash) {
                    node = inbox[height];
                    isFirstHash = false;
                } else {
                    bytes32 hash = inbox[height];
                    // efficient hash
                    if (hash > node)
                        assembly {
                            mstore(0x00, node)
                            mstore(0x20, hash)
                            node := keccak256(0x00, 0x40)
                        }
                    else
                        assembly {
                            mstore(0x00, hash)
                            mstore(0x20, node)
                            node := keccak256(0x00, 0x40)
                        }
                }
            }
            unchecked {
                size /= 2;
                height++;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint256 amount);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IChallengeResolver {
    /**
     * Note: Access restricted to arbitrum canonical bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch to verify.
     * @param _stateRoot The true state root for the epoch.
     */
    function resolveChallenge(uint256 _epoch, bytes32 _stateRoot) external;
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IVeaInbox {
    /**
     * Note: Calls authenticated by receiving gateway checking the sender argument.
     * @dev Sends an arbitrary message to Ethereum.
     * @param _to The cross-domain contract address which receives the calldata.
     * @param _data The encoded message data.
     * @return index The index of the message in the inbox, needed to relay the message.
     */
    function sendMsg(address _to, bytes memory _data) external returns (uint256 index);
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./IChallengeResolver.sol";

interface IVeaOutbox is IChallengeResolver{
    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the epoch and relays the message.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _index The index of the message in the outbox.
     * @param _msgSender The sender of the message.
     * @param _to The cross-domain contract address which receives the calldata.
     * @param _message The data of the message.
     */
    function verifyAndRelayMessage(
        bytes32[] calldata _proof, 
        uint256 _index, 
        address _msgSender,
        address _to,
        bytes calldata _message) external;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the epoch and relays the message.
     * @return messageSender The address of the message sender.
     */
    function messageSender() external returns (address messageSender);
}