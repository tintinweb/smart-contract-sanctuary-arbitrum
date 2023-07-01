// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../canonical/arbitrum/IArbSys.sol";
import "../interfaces/inboxes/IVeaInbox.sol";
import "../interfaces/routers/IRouterToGnosis.sol";

/// @dev Vea Inbox From Arbitrum to Gnosis.
/// Note: This contract is deployed on the Arbitrum.
contract VeaInboxArbToGnosis is IVeaInbox {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    // Arbitrum precompile ArbSys for L2->L1 messaging: https://developer.arbitrum.io/arbos/precompiles#arbsys
    IArbSys internal constant ARB_SYS = IArbSys(address(100));

    uint256 public immutable epochPeriod; // Epochs mark the period between potential snapshots.
    address public immutable routerArbToGnosis; // The router on ethereum.

    mapping(uint256 => bytes32) public snapshots; // epoch => state root snapshot

    // Inbox represents minimum data availability to maintain incremental merkle tree.
    // Supports a max of 2^64 - 1 messages. See merkle tree docs for details how inbox manages state.

    bytes32[64] internal inbox; // stores minimal set of complete subtree roots of the merkle tree to increment.
    uint64 public count; // count of messages in the merkle tree

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /// @dev Relayers watch for these events to construct merkle proofs to execute transactions on Gnosis.
    /// @param _nodeData The data to create leaves in the merkle tree. abi.encodePacked(msgId, to, message), outbox relays to.call(message).
    event MessageSent(bytes _nodeData);

    /// The bridgers can watch this event to claim the stateRoot on the veaOutbox.
    /// @param _snapshot The snapshot of the merkle tree state root.
    /// @param _epoch The epoch of the snapshot.
    /// @param _count The count of messages in the merkle tree.
    event SnapshotSaved(bytes32 _snapshot, uint256 _epoch, uint64 _count);

    /// @dev The event is emitted when a snapshot is sent through the canonical arbitrum bridge.
    /// @param _epochSent The epoch of the snapshot.
    /// @param _ticketId The ticketId of the L2->L1 message.
    event SnapshotSent(uint256 indexed _epochSent, bytes32 _ticketId);

    /// @dev Constructor.
    /// Note: epochPeriod must match the VeaOutboxArbToGnosis contract deployment on Gnosis, since it's on a different chain, we can't read it and trust the deployer to set a correct value
    /// @param _epochPeriod The duration in seconds between epochs.
    /// @param _routerArbToGnosis The router on Ethereum that routes from Arbitrum to Gnosis.
    constructor(uint256 _epochPeriod, address _routerArbToGnosis) {
        epochPeriod = _epochPeriod;
        routerArbToGnosis = _routerArbToGnosis;
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Sends an arbitrary message to Gnosis.
    ///      `O(log(count))` where count is the number of messages already sent.
    ///      Amortized cost is constant.
    /// Note: See docs for details how inbox manages merkle tree state.
    /// @param _to The address of the contract on the receiving chain which receives the calldata.
    /// @param _fnSelector The function selector of the receiving contract.
    /// @param _data The message calldata, abi.encode(param1, param2, ...)
    /// @return msgId The zero based index of the message in the inbox.
    function sendMessage(address _to, bytes4 _fnSelector, bytes memory _data) external override returns (uint64) {
        uint64 oldCount = count;

        // Given arbitrum's speed limit of 7 million gas / second, it would take atleast 8 million years of full blocks to overflow.
        // It *should* be impossible to overflow, but we check to be safe when appending to the tree.
        require(oldCount < type(uint64).max, "Inbox is full.");

        bytes memory nodeData = abi.encodePacked(
            oldCount,
            _to,
            // _data is abi.encode(param1, param2, ...), we need to encode it again to get the correct leaf data
            abi.encodePacked( // equivalent to abi.encodeWithSelector(fnSelector, msg.sender, param1, param2, ...)
                _fnSelector,
                bytes32(uint256(uint160(msg.sender))), // big endian padded encoding of msg.sender, simulating abi.encodeWithSelector
                _data
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

    /// @dev Saves snapshot of state root. Snapshots can be saved a maximum of once per epoch.
    ///      `O(log(count))` where count number of messages in the inbox.
    /// Note: See merkle tree docs for details how inbox manages state.
    function saveSnapshot() external {
        uint256 epoch;
        bytes32 stateRoot;

        unchecked {
            epoch = block.timestamp / epochPeriod;

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

        emit SnapshotSaved(stateRoot, epoch, count);
    }

    /// @dev Helper function to calculate merkle tree interior nodes by sorting and concatenating and hashing a pair of children nodes, left and right.
    /// Note: EVM scratch space is used to efficiently calculate hashes.
    /// @param _left The left hash.
    /// @param _right The right hash.
    /// @return parent The parent hash.
    function sortConcatAndHash(bytes32 _left, bytes32 _right) internal pure returns (bytes32 parent) {
        // sort sibling hashes as a convention for efficient proof validation
        if (_left < _right) {
            // efficient hash using EVM scratch space
            assembly {
                mstore(0x00, _left)
                mstore(0x20, _right)
                parent := keccak256(0x00, 0x40)
            }
        } else {
            assembly {
                mstore(0x00, _right)
                mstore(0x20, _left)
                parent := keccak256(0x00, 0x40)
            }
        }
    }

    /// @dev Sends the state root snapshot using Arbitrum's canonical bridge.
    /// @param _epoch The epoch of the snapshot requested to send.
    /// @param _gasLimit The gas limit for the AMB transaction on Gnosis.
    /// @param _claim The claim associated with the epoch.
    function sendSnapshot(uint256 _epoch, uint256 _gasLimit, Claim memory _claim) external virtual {
        unchecked {
            require(_epoch < block.timestamp / epochPeriod, "Can only send past epoch snapshot.");
        }

        bytes memory data = abi.encodeCall(IRouterToGnosis.route, (_epoch, snapshots[_epoch], _gasLimit, _claim));

        // Arbitrum -> Ethereum message with native bridge
        // docs: https://developer.arbitrum.io/for-devs/cross-chain-messsaging#arbitrum-to-ethereum-messaging
        // example: https://github.com/OffchainLabs/arbitrum-tutorials/blob/2c1b7d2db8f36efa496e35b561864c0f94123a5f/packages/greeter/contracts/arbitrum/GreeterL2.sol#L25
        bytes32 ticketID = bytes32(ARB_SYS.sendTxToL1(routerArbToGnosis, data));

        emit SnapshotSent(_epoch, ticketID);
    }

    // ************************************* //
    // *           Pure / Views            * //
    // ************************************* //

    /// @dev Get the current epoch from the inbox's point of view using the Arbitrum L2 clock.
    /// @return epoch The epoch associated with the current inbox block.timestamp
    function epochNow() external view returns (uint256 epoch) {
        epoch = block.timestamp / epochPeriod;
    }

    /// @dev Get the most recent epoch for which snapshots are finalized.
    /// @return epoch The epoch associated with the current inbox block.timestamp
    function epochFinalized() external view returns (uint256 epoch) {
        epoch = block.timestamp / epochPeriod - 1;
    }

    /// @dev Get the epoch from the inbox's point of view using timestamp.
    /// @param _timestamp The timestamp to calculate the epoch from.
    /// @return epoch The calculated epoch.
    function epochAt(uint256 _timestamp) external view returns (uint256 epoch) {
        epoch = _timestamp / epochPeriod;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// https://developer.arbitrum.io/arbos/precompiles#arbsys
// https://github.com/OffchainLabs/nitro-contracts/blob/39ea5a163afc637e2706d9be29cf7a289c300d00/src/precompiles/ArbSys.sol
// https://arbiscan.io/address/0x0000000000000000000000000000000000000064#code
// interface is pruned for relevant function stubs

pragma solidity 0.8.18;

///@title System level functionality
///@notice For use by contracts to interact with core L2-specific functionality.
///Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
interface IArbSys {
    /// @notice Send a transaction to L1
    /// @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
    /// to a contract address without any code (as enforced by the Bridge contract).
    /// @param destination recipient address on L1
    /// @param data (optional) calldata for L1 contract call
    /// @return a unique identifier for this L2-to-L1 transaction.
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

interface IVeaInbox {
    /// @dev Sends an arbitrary message to receiving chain.
    /// Note: Calls authenticated by receiving gateway checking the sender argument.
    /// @param _to The cross-domain contract address which receives the calldata.
    /// @param _fnSelection The function selector of the receiving contract.
    /// @param _data The message calldata, abi.encode(...)
    /// @return msgId The index of the message in the inbox, as a message Id, needed to relay the message.
    function sendMessage(address _to, bytes4 _fnSelection, bytes memory _data) external returns (uint64 msgId);

    /// @dev Snapshots can be saved a maximum of once per epoch.
    ///      Saves snapshot of state root.
    ///      `O(log(count))` where count number of messages in the inbox.
    function saveSnapshot() external;
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../types/VeaClaim.sol";

/// @dev Interface of the Vea Router which routes messages to Gnosis through the AMB.
/// @dev eg. L2 on Ethereum -> Ethereum (L1) -> Gnosis (L1), the IRouterToL1 will be deployed on Ethereum (L1) routing messages to Gnosis (L1).
interface IRouterToGnosis {
    /// @dev Routes state root snapshots through intermediary chains to the final destination L1 chain.
    /// Note: Access restricted to canonical sending-chain bridge.
    /// @param _epoch The epoch to verify.
    /// @param _stateRoot The true state root for the epoch.
    /// @param _gasLimit The gas limit for the AMB message.
    /// @param _claim The claim associated with the epoch.
    function route(uint256 _epoch, bytes32 _stateRoot, uint256 _gasLimit, Claim memory _claim) external;
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

enum Party {
    None,
    Claimer,
    Challenger
}

struct Claim {
    bytes32 stateRoot;
    address claimer;
    uint32 timestampClaimed;
    uint32 timestampVerification;
    uint32 blocknumberVerification;
    Party honest;
    address challenger;
}