// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./SafeBridgeSenderToEthereum.sol";
import "./interfaces/IFastBridgeSender.sol";
import "./interfaces/IFastBridgeReceiver.sol";

/**
 * Fast Bridge Sender to Ethereum from Arbitrum
 * Counterpart of `FastBridgeReceiverOnEthereum`
 */
contract FastBridgeSenderToEthereum is SafeBridgeSenderToEthereum, IFastBridgeSender {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    IFastBridgeReceiver public immutable fastBridgeReceiver; // The address of the Fast Bridge on Ethereum.

    uint256 public immutable genesis; // Marks the beginning of the first epoch.
    uint256 public immutable epochPeriod; // Epochs mark the period between potential batches of messages.

    bytes32[64] public batch; // merkle tree, supports 2^64 outbound messages
    uint256 public batchSize; // merkle tree leaf count
    mapping(uint256 => bytes32) public fastOutbox; // epoch => merkle root of batched messages

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * The bridgers need to watch for these events and relay the
     * batchMerkleRoot on the FastBridgeReceiverOnEthereum.
     */
    event SendBatch(uint256 indexed epoch, bytes32 indexed batchMerkleRoot);

    /**
     * @dev Constructor.
     * @param _fastBridgeReceiver The address of the Fast Bridge on Ethereum.
     * @param _genesis The immutable genesis state variable from the FastBridgeSeneder.
     */
    constructor(
        IFastBridgeReceiver _fastBridgeReceiver,
        uint256 _epochPeriod,
        uint256 _genesis
    ) SafeBridgeSenderToEthereum() {
        fastBridgeReceiver = _fastBridgeReceiver;
        epochPeriod = _epochPeriod;
        genesis = _genesis;
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Sends an arbitrary message to Ethereum using the Fast Bridge.
     * @param _receiver The address of the contract on Ethereum which receives the calldata.
     * @param _calldata The receiving domain encoded message data.
     */
    function sendFast(address _receiver, bytes memory _calldata) external override {
        bytes32 messageHash = _encode(_receiver, _calldata);
        insertInBatch(messageHash);
        emit MessageReceived(_receiver, _calldata, batchSize);
    }

    /**
     * Sends a batch of arbitrary message from one domain to another
     * via the fast bridge mechanism.
     */
    function sendBatch() public {
        uint256 epochFinalized = (block.timestamp - genesis) / epochPeriod;
        require(fastOutbox[epochFinalized] == 0, "Batch already sent for most recent finalized epoch.");
        require(batchSize > 0, "No messages to send.");

        bytes32 batchMerkleRoot = getBatchMerkleRoot();

        // set merkle root in outbox and reset merkle tree
        fastOutbox[epochFinalized] = batchMerkleRoot;
        batchSize = 0;

        emit SendBatch(epochFinalized, batchMerkleRoot);
    }

    /**
     * @dev Sends an arbitrary message to Ethereum using the Safe Bridge, which relies on Arbitrum's canonical bridge. It is unnecessary during normal operations but essential only in case of challenge.
     * @param _epoch The blocknumber of the batch
     */
    function sendSafeFallback(uint256 _epoch) external payable override {
        bytes32 batchMerkleRoot = fastOutbox[_epoch];

        // Safe Bridge message envelope
        bytes4 methodSelector = IFastBridgeReceiver.verifySafe.selector;
        bytes memory safeMessageData = abi.encodeWithSelector(methodSelector, _epoch, batchMerkleRoot);
        // TODO: how much ETH should be provided for bridging? add an ISafeBridgeSender.bridgingCost() if needed
        _sendSafe(address(fastBridgeReceiver), safeMessageData);
    }

    // ************************ //
    // *       Internal       * //
    // ************************ //

    function _encode(address _receiver, bytes memory _calldata) internal view returns (bytes32 messageHash) {
        // Encode the receiver address with the function signature + _msgSender as the first argument, then the rest of the args
        bytes4 functionSelector;
        bytes memory _args;
        assembly {
            functionSelector := mload(add(_calldata, 32))
            mstore(add(_calldata, 4), mload(_calldata))
            _args := add(_calldata, 4)
        }
        bytes memory messageData = abi.encodePacked(
            _receiver,
            abi.encodeWithSelector(functionSelector, msg.sender, _args)
        );

        // Compute the hash over the message header (current batchSize acts as a nonce) and body (data).
        messageHash = sha256(abi.encodePacked(messageData, batchSize));
    }

    // ************************************ //
    // *            MerkleTree            * //
    // ************************************ //

    // ************************************* //
    // *          State Modifiers          * //
    // ************************************* //

    /** @dev Append _messageHash leaf into merkle tree.
     *  `O(log(n))` where
     *  `n` is the number of leaves (batchSize).
     *  Note: Although each insertion is O(log(n)),
     *  Complexity of n insertions is O(n).
     *  @param _messageHash The leaf to insert in the merkle tree.
     */
    function insertInBatch(bytes32 _messageHash) internal {
        uint256 size = batchSize + 1;
        batchSize = size;
        uint256 hashBitField = (size ^ (size - 1)) & size;
        uint256 height;
        while ((hashBitField & 1) == 0) {
            bytes32 node = batch[height];
            if (node > _messageHash)
                assembly {
                    // effecient hash
                    mstore(0x00, _messageHash)
                    mstore(0x20, node)
                    _messageHash := keccak256(0x00, 0x40)
                }
            else
                assembly {
                    // effecient hash
                    mstore(0x00, node)
                    mstore(0x20, _messageHash)
                    _messageHash := keccak256(0x00, 0x40)
                }
            hashBitField /= 2;
            height = height + 1;
        }
        batch[height] = _messageHash;
    }

    /** @dev Gets the history of merkle roots in the outbox
     *  @param _epoch requested epoch outbox history.
     */
    function getBatchMerkleRootHistory(uint256 _epoch) public view returns (bytes32) {
        return fastOutbox[_epoch];
    }

    /** @dev Gets the merkle root for the current epoch batch
     *  `O(log(n))` where
     *  `n` is the current number of leaves (batchSize)
     */
    function getBatchMerkleRoot() public view returns (bytes32) {
        bytes32 node;
        uint256 size = batchSize;
        uint256 height = 0;
        bool isFirstHash = true;
        while (size > 0) {
            if ((size & 1) == 1) {
                // avoid redundant calculation
                if (isFirstHash) {
                    node = batch[height];
                    isFirstHash = false;
                } else {
                    bytes32 hash = batch[height];
                    // effecient hash
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
            size /= 2;
            height++;
        }
        return node;
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@shalzz, @jaybuidl]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

import "./interfaces/arbitrum/IArbSys.sol";
import "./interfaces/arbitrum/AddressAliasHelper.sol";

import "./interfaces/ISafeBridgeSender.sol";

/**
 * Safe Bridge Sender to Ethereum from Arbitrum
 * Counterpart of `SafeBridgeReceiverOnEthereum`
 */
contract SafeBridgeSenderToEthereum is ISafeBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    event L2ToL1TxCreated(uint256 indexed withdrawalId);

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    IArbSys public constant ARB_SYS = IArbSys(address(100));

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    function _sendSafe(address _receiver, bytes memory _calldata) internal override returns (uint256) {
        uint256 withdrawalId = ARB_SYS.sendTxToL1(_receiver, _calldata);

        emit L2ToL1TxCreated(withdrawalId);
        return withdrawalId;
    }
}

// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shalzz, @hrishibhat, @shotaronowhere]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.8.0;

interface IFastBridgeReceiver {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants watch for these events to decide if a challenge should be submitted.
     * @param _epoch The epoch in  the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev The Fast Bridge participants watch for these events to call `sendSafeFallback()` on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 _epoch);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     */
    function challenge() external payable;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     * @param _nonce The nonce (index in the merkle tree) to avoid replay.
     */
    function verifyProofAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message,
        uint256 _nonce
    ) external;

    /**
     * Note: Access restricted to the Safe Bridge.
     * @dev Resolves any challenge of the optimistic claim for '_epoch'.
     * @param _epoch The epoch associated with the _batchmerkleRoot.
     * @param _batchMerkleRoot The true batch merkle root for the epoch sent by the safe bridge.
     */
    function verifySafe(uint256 _epoch, bytes32 _batchMerkleRoot) external;

    /**
     * @dev Sends the deposit back to the Bridger if their claim is not successfully challenged. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
     * @param _epoch The epoch associated with the claim deposit to withraw.
     */
    function withdrawClaimDeposit(uint256 _epoch) external;

    /**
     * @dev Sends the deposit back to the Challenger if his challenge is successful. Includes a portion of the Bridger's deposit.
     * @param _epoch The epoch associated with the challenge deposit to withraw.
     */
    function withdrawChallengeDeposit(uint256 _epoch) external;

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Returns the `start` and `end` time of challenge period for this `epoch`.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function challengePeriod() external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epoch);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFastBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants need to watch for these events and relay the messageHash on the FastBridgeReceiverOnEthereum.
     * @param target The address of the cross-domain receiver of the message, generally the Foreign Gateway.
     * @param message The message data.
     * @param nonce The message nonce.
     */
    event MessageReceived(address target, bytes message, uint256 nonce);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * Note: Access must be restricted by the receiving contract.
     * Message is sent with the message sender address as the first argument.
     * @dev Sends an arbitrary message across domain using the Fast Bridge.
     * @param _receiver The cross-domain contract address which receives the calldata.
     * @param _calldata The receiving domain encoded message data.
     */
    function sendFast(address _receiver, bytes memory _calldata) external;

    /**
     * @dev Sends a markle root representing an arbitrary batch of messages across domain using the Safe Bridge, which relies on the chain's canonical bridge. It is unnecessary during normal operations but essential only in case of challenge.
     * @param _epoch block number of batch
     */
    function sendSafeFallback(uint256 _epoch) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ISafeBridgeSender {
    /**
     * Sends an arbitrary message from one domain to another.
     *
     * @param _receiver The L1 contract address who will receive the calldata
     * @param _calldata The L2 encoded message data.
     * @return Unique id to track the message request/transaction.
     */
    function _sendSafe(address _receiver, bytes memory _calldata) internal virtual returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.7.0;

library AddressAliasHelper {
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        l1Address = address(uint160(l2Address) - offset);
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