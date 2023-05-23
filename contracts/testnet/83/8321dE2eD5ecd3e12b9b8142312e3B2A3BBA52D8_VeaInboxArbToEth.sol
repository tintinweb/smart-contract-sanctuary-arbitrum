// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.18;

import "../canonical/arbitrum/IArbSys.sol";
import "../interfaces/inboxes/IVeaInbox.sol";
import "../interfaces/outboxes/IVeaOutboxOnL1.sol";

/**
 * Vea Inbox From Arbitrum to Ethereum.
 * Note: This contract is deployed on Arbitrum.
 */
contract VeaInboxArbToEth is IVeaInbox {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    // Arbitrum precompile ArbSys, used for L2->L1 messaging.
    // docs: https://developer.arbitrum.io/arbos/precompiles#arbsys
    IArbSys internal constant ARB_SYS = IArbSys(address(100));

    uint256 public immutable epochPeriod; // Epochs mark the period between potential snapshots.
    address public immutable veaOutboxArbToEth; // The vea outbox on ethereum.

    mapping(uint256 => bytes32) public snapshots; // epoch => state root snapshot

    // Inbox represents minimum data availability to maintain incremental merkle tree.
    // Supports a max of 2^64 - 1 messages. See merkle.md more details on inbox data management.

    bytes32[64] public inbox; // stores minimal set of complete subtree roots of the merkle tree to increment.
    uint64 public count; // count of messages in the merkle tree

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev Relayers watch for these events to construct merkle proofs to execute transactions on Ethereum.
     * @param nodeData The data to create leaves in the merkle tree. abi.encodePacked(msgId, to, message), outbox relays to.call(message).
     */
    event MessageSent(bytes nodeData);

    /**
     * The bridgers can watch this event to claim the stateRoot on the veaOutbox.
     * @param count The count of messages in the merkle tree.
     */
    event SnapshotSaved(uint64 count);

    /**
     * @dev The event is emitted when a snapshot is sent through the canonical arbitrum bridge.
     * @param epochSent The epoch of the snapshot.
     * @param ticketId The ticketId of the L2->L1 message.
     */
    event SnapshotSent(uint256 indexed epochSent, bytes32 ticketId);

    /**
     * @dev Constructor.
     * Note: epochPeriod must match the VeaOutboxArbToEth contract deployment on Ethereum, since it's on a different chain, we can't read it and trust the deployer to set a correct value
     * @param _epochPeriod The duration in seconds between epochs.
     * @param _veaOutboxArbToEth The veaOutbox on ethereum.
     */
    constructor(uint256 _epochPeriod, address _veaOutboxArbToEth) {
        epochPeriod = _epochPeriod;
        veaOutboxArbToEth = _veaOutboxArbToEth;

        // epochPeriod should never be set this small, but we check non-zero value as a sanity check to avoid division by zero
        require(_epochPeriod > 0, "Epoch period must be greater than 0.");
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Sends an arbitrary message to Ethereum.
     * `O(log(count))` where count is the number of messages already sent.
     * Amortized cost is constant.
     * Note: See merkle tree docs for details how inbox manages state.
     * @param to The address of the contract on the receiving chain which receives the calldata.
     * @param fnSelector The function selector of the receiving contract.
     * @param data The message calldata, abi.encode(param1, param2, ...)
     * @return msgId The zero based index of the message in the inbox.
     */
    function sendMessage(address to, bytes4 fnSelector, bytes memory data) external override returns (uint64) {
        uint64 oldCount = count;

        // Given arbitrum's speed limit of 7 million gas / second, it would take atleast 8 million years of full blocks to overflow.
        // It *should* be impossible to overflow, but we check to be safe when appending to the tree.
        require(oldCount < type(uint64).max, "Inbox is full.");

        bytes memory nodeData = abi.encodePacked(
            oldCount,
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
            for (uint64 x = oldCount + 1; x & 1 == 0; x = x >> 1) {
                // sort sibling hashes as a convention for efficient proof validation
                newInboxNode = sortConcatAndHash(inbox[height], newInboxNode);
                height++;
            }

            inbox[height] = newInboxNode;

            // finally increment count
            count = oldCount + 1;
        }

        emit MessageSent(nodeData);

        // old count is the zero indexed leaf position in the tree, acts as a msgId
        // gateways should index these msgIds to later relay proofs
        return oldCount;
    }

    /**
     * @dev Saves snapshot of state root. Snapshots can be saved a maximum of once per epoch.
     * `O(log(count))` where count number of messages in the inbox.
     * Note: See merkle tree docs for details how inbox manages state.
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
            for (x = uint256(count); x > 0; x = x >> 1) {
                if ((x & 1) == 1) {
                    // first hash is special case
                    // inbox stores the root of complete subtrees
                    // eg if count = 4 = 0b100, then the first complete subtree is inbox[2]
                    // inbox = [H(3), H(1,2), H(1,4)], we read inbox[2] directly

                    stateRoot = inbox[height];
                    break;
                }
                height++;
            }

            // after the first hash, we can calculate the root incrementally
            for (x = x >> 1; x > 0; x = x >> 1) {
                height++;
                if ((x & 1) == 1) {
                    // sort sibling hashes as a convention for efficient proof validation
                    stateRoot = sortConcatAndHash(inbox[height], stateRoot);
                }
            }
        }

        snapshots[epoch] = stateRoot;

        emit SnapshotSaved(count);
    }

    /**
     * @dev Helper function to calculate merkle tree interior nodes by sorting and concatenating and hashing a pair of children nodes, left and right.
     * note: EVM scratch space is used to efficiently calculate hashes.
     * @param left The left hash.
     * @param right The right hash.
     * @return parent The parent hash.
     */
    function sortConcatAndHash(bytes32 left, bytes32 right) internal pure returns (bytes32 parent) {
        // sort sibling hashes as a convention for efficient proof validation
        if (left < right) {
            // efficient hash using EVM scratch space
            assembly {
                mstore(0x00, left)
                mstore(0x20, right)
                parent := keccak256(0x00, 0x40)
            }
        } else {
            assembly {
                mstore(0x00, right)
                mstore(0x20, left)
                parent := keccak256(0x00, 0x40)
            }
        }
    }

    /**
     * @dev Sends the state root snapshot using Arbitrum's canonical bridge.
     * @param epoch The epoch of the snapshot requested to send.
     * @param claim The claim associated with the epoch.
     */
    function sendSnapshot(uint256 epoch, Claim memory claim) external virtual {
        unchecked {
            require(epoch < block.timestamp / epochPeriod, "Can only send past epoch snapshot.");
        }

        bytes memory data = abi.encodeCall(IVeaOutboxOnL1.resolveDisputedClaim, (epoch, snapshots[epoch], claim));

        // Arbitrum -> Ethereum message with native bridge
        // docs: https://developer.arbitrum.io/for-devs/cross-chain-messsaging#arbitrum-to-ethereum-messaging
        // example: https://github.com/OffchainLabs/arbitrum-tutorials/blob/2c1b7d2db8f36efa496e35b561864c0f94123a5f/packages/greeter/contracts/arbitrum/GreeterL2.sol#L25
        bytes32 ticketID = bytes32(ARB_SYS.sendTxToL1(veaOutboxArbToEth, data));

        emit SnapshotSent(epoch, ticketID);
    }
}

// https://developer.arbitrum.io/arbos/precompiles#arbsys
// https://github.com/OffchainLabs/nitro-contracts/blob/39ea5a163afc637e2706d9be29cf7a289c300d00/src/precompiles/ArbSys.sol
// https://arbiscan.io/address/0x0000000000000000000000000000000000000064#code
// interface is pruned for relevant function stubs

pragma solidity 0.8.18;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface IArbSys {
    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);
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
     * @dev Sends an arbitrary message to receiving chain.
     * Note: Calls authenticated by receiving gateway checking the sender argument.
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

import "../types/VeaClaim.sol";

/**
 * @dev Interface of the Vea Outbox on L1 chains like Ethereum, Gnosis, Polygon POS where storage is expensive.
 */
interface IVeaOutboxOnL1 {
    /**
     * Note: Gateways expect first argument of message call to be the arbitrum message sender, used for authentication.
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
     * @param claim The claim associated with the epoch.
     */
    function resolveDisputedClaim(uint256 epoch, bytes32 stateRoot, Claim memory claim) external;
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