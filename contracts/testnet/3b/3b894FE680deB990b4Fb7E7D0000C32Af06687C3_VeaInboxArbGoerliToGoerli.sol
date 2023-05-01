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
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.18;

interface IVeaInbox {
    /**
     * Note: Calls authenticated by receiving gateway checking the sender argument.
     * @dev Sends an arbitrary message to Ethereum.
     * @param to The cross-domain contract address which receives the calldata.
     * @param fnSelection The function selector of the receiving contract.
     * @param data The message calldata, abi.encode(...)
     * @return msgId The index of the message in the inbox, as a message Id, needed to relay the message.
     */
    function sendMessage(address to, bytes4 fnSelection, bytes memory data) external returns (uint64 msgId);

    /**
     * Saves snapshot of state root.
     * `O(log(count))` where count number of messages in the inbox.
     * @dev Snapshots can be saved a maximum of once per epoch.
     */
    function saveSnapshot() external;
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.18;

import "../../canonical/arbitrum/IArbSys.sol";
import "../../interfaces/IVeaInbox.sol";
import "./interfaces/IVeaOutboxArbGoerliToGoerli.sol";

/**
 * Vea Bridge Inbox From Arbitrum to Ethereum.
 */
contract VeaInboxArbGoerliToGoerli is IVeaInbox {
    /**
     * @dev Relayers watch for these events to construct merkle proofs to execute transactions on Ethereum.
     * @param nodeData The data to create leaves in the merkle tree. abi.encodePacked(msgId, to, data), outbox relays to.call(data)
     */
    event MessageSent(bytes nodeData);

    /**
     * The bridgers can watch this event to claim the stateRoot on the veaOutbox.
     * @param count The count of messages in the merkle tree
     */
    event SnapshotSaved(uint256 count);

    /**
     * @dev The event is emitted when a snapshot through the canonical arbiturm bridge.
     * @param epochSent The epoch of the snapshot.
     * @param ticketId The ticketId of the L2->L1 message.
     */
    event SnapshotSent(uint256 indexed epochSent, bytes32 ticketId);

    IArbSys public constant ARB_SYS = IArbSys(address(100));

    uint256 public immutable epochPeriod; // Epochs mark the period between stateroot snapshots
    address public immutable veaOutbox; // The vea outbox on ethereum.

    mapping(uint256 => bytes32) public snapshots; // epoch => state root snapshot

    // inbox represents minimum data availability to maintain incremental merkle tree.
    // supports a max of 2^64 - 1 messages and will *never* overflow, see parameter docs.

    bytes32[64] public inbox; // stores minimal set of complete subtree roots of the merkle tree to increment.
    uint256 public count; // count of messages in the merkle tree

    /**
     * @dev Constructor.
     * @param _epochPeriod The duration in seconds between epochs.
     * @param _veaOutbox The veaOutbox on ethereum.
     */
    constructor(uint256 _epochPeriod, address _veaOutbox) {
        epochPeriod = _epochPeriod;
        veaOutbox = _veaOutbox;
    }

    /**
     * @dev Sends an arbitrary message to a receiving chain.
     * `O(log(count))` where count is the number of messages already sent.
     * Note: Amortized cost is O(1).
     * @param to The address of the contract on the receiving chain which receives the calldata.
     * @param fnSelector The function selector of the receiving contract.
     * @param data The message calldata, abi.encode(param1, param2, ...)
     * @return msgId The zero based index of the message in the inbox.
     */
    function sendMessage(address to, bytes4 fnSelector, bytes memory data) external override returns (uint64) {
        uint256 oldCount = count;

        bytes memory nodeData = abi.encodePacked(
            uint64(oldCount),
            to,
            // data for outbox relay
            abi.encodePacked( // abi.encodeWithSelector(fnSelector, msg.sender, data)
                fnSelector,
                bytes32(uint256(uint160(msg.sender))), // big endian padded encoding of msg.sender, simulating abi.encodeWithSelector
                data
            )
        );

        // single hashed leaf
        bytes32 newInboxNode = keccak256(nodeData);

        // double hashed leaf
        // avoids second order preimage attacks
        // https://flawed.net.nz/2018/02/21/attacking-merkle-trees-with-a-second-preimage-attack/
        assembly {
            // efficient hash using EVM scratch space
            mstore(0x00, newInboxNode)
            newInboxNode := keccak256(0x00, 0x20)
        }

        // increment merkle tree calculating minimal number of hashes
        unchecked {
            uint256 height;

            // x = oldCount + 1; acts as a bit mask to determine if a hash is needed
            // note: x is always non-zero, and x is bit shifted to the right each loop
            // hence this loop will always terminate in a maximum of log_2(oldCount + 1) iterations
            for (uint256 x = oldCount + 1; x & 1 == 0; x = x >> 1) {
                bytes32 oldInboxNode = inbox[height];
                // sort sibling hashes as a convention for efficient proof validation
                newInboxNode = sortConcatAndHash(oldInboxNode, newInboxNode);
                height++;
            }

            inbox[height] = newInboxNode;

            // finally increment count
            count = oldCount + 1;
        }

        emit MessageSent(nodeData);

        // old count is the zero indexed leaf position in the tree, acts as a msgId
        // gateways should index these msgIds to later relay proofs
        return uint64(oldCount);
    }

    /**
     * Saves snapshot of state root.
     * `O(log(count))` where count number of messages in the inbox.
     * @dev Snapshots can be saved a maximum of once per epoch.
     */
    function saveSnapshot() external {
        uint256 epoch;
        bytes32 stateRoot;

        unchecked {
            epoch = block.timestamp / epochPeriod;

            require(snapshots[epoch] == bytes32(0), "Snapshot already taken for this epoch.");

            // calculate the current root of the incremental merkle tree encoded in the inbox

            uint256 height;

            // x acts as a bit mask to determine if the hash stored in the inbox contributes to the root
            uint256 x;

            // x is bit shifted to the right each loop, hence this loop will always terminate in a maximum of log_2(count) iterations
            for (x = count; x > 0; x = x >> 1) {
                if ((x & 1) == 1) {
                    // first hash is special case
                    // inbox stores the root of complete subtrees
                    // eg if count = 4 = 0b100, then the first complete subtree is inbox[2]
                    // inbox = [H(m_3), H(H(m_1),H(m_2)) H(H(H(m_1),H(m_2)),H(H(m_3),H(m_4)))], we read inbox[2] directly

                    stateRoot = inbox[height];
                    break;
                }
                height++;
            }

            for (x = x >> 1; x > 0; x = x >> 1) {
                height++;
                if ((x & 1) == 1) {
                    bytes32 inboxHash = inbox[height];
                    // sort sibling hashes as a convention for efficient proof validation
                    stateRoot = sortConcatAndHash(inboxHash, stateRoot);
                }
            }
        }

        snapshots[epoch] = stateRoot;

        emit SnapshotSaved(count);
    }

    /**
     * @dev Helper function to calculate merkle tree interior nodes by sorting and concatenating and hashing sibling hashes.
     * note: EVM scratch space is used to efficiently calculate hashes.
     * @param child_1 The first sibling hash.
     * @param child_2 The second sibling hash.
     * @return parent The parent hash.
     */
    function sortConcatAndHash(bytes32 child_1, bytes32 child_2) internal pure returns (bytes32 parent) {
        // sort sibling hashes as a convention for efficient proof validation
        // efficient hash using EVM scratch space
        if (child_1 > child_2) {
            assembly {
                mstore(0x00, child_2)
                mstore(0x20, child_1)
                parent := keccak256(0x00, 0x40)
            }
        } else {
            assembly {
                mstore(0x00, child_1)
                mstore(0x20, child_2)
                parent := keccak256(0x00, 0x40)
            }
        }
    }

    /**
     * @dev Sends the state root snapshot using Arbitrum's canonical bridge.
     * @param epochSend The epoch of the snapshot requested to send.
     */
    function sendSnapshot(uint256 epochSend, IVeaOutboxArbGoerliToGoerli.Claim memory claim) external virtual {
        unchecked {
            require(epochSend < block.timestamp / epochPeriod, "Can only send past epoch snapshot.");
        }

        bytes memory data = abi.encodeCall(
            IVeaOutboxArbGoerliToGoerli.resolveDisputedClaim,
            (
                epochSend,
                snapshots[epochSend],
                claim
            )
        );

        bytes32 ticketID = bytes32(ARB_SYS.sendTxToL1(veaOutbox, data));

        emit SnapshotSent(epochSend, ticketID);
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.18;

interface IVeaOutboxArbGoerliToGoerli {
    enum Party {
        None,
        Claimer,
        Challenger
    }

    struct Claim {
        bytes32 stateRoot;
        address claimer;
        uint32 timestamp;
        uint32 blocknumber;
        Party honest;
        address challenger;
    }

    /**
     * Note: Gateways expect first argument of message call to be the inbox sender, used for authenitcation.
     * @dev Verifies and relays the message.
     * @param proof The merkle proof to prove the message.
     * @param msgId The zero based index of the message in the inbox.
     * @param to The address to send the message to.
     * @param message The message to relay.
     */
    function sendMessage(bytes32[] calldata proof, uint64 msgId, address to, bytes calldata message) external;

    /**
     * Note: Access restricted to canonical bridge.
     * @dev Resolves any challenge of the optimistic claim for 'epoch' using the canonical bridge.
     * @param epoch The epoch to verify.
     * @param stateRoot The true state root for the epoch.
     */
    function resolveDisputedClaim(uint256 epoch, bytes32 stateRoot, Claim memory claim) external;
}