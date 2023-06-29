// https://github.com/OffchainLabs/nitro-contracts/blob/08ac127e966fa87a4d5ba3d23cd3132b57701132/src/libraries/AddressAliasHelper.sol
// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../interfaces/outboxes/IVeaOutboxOnL2.sol";
import "../canonical/arbitrum/AddressAliasHelper.sol";

/// @dev Vea Outbox From Gnosis to Arbitrum.
/// Note: This contract is deployed on Arbitrum.
contract VeaOutboxGnosisToArb is IVeaOutboxOnL2 {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    address public immutable routerGnosisToArb; // The address of the router from Gnosis to Arbitrum on Ethereum.

    uint256 public immutable deposit; // The deposit in wei required to submit a claim or challenge
    uint256 internal immutable burn; // The amount of wei to burn. deposit / 2
    uint256 internal immutable depositPlusReward; // 2 * deposit - burn

    address internal constant BURN_ADDRESS = address(0); // address to send burned eth

    uint256 public immutable epochPeriod; // Epochs mark the period between potential snapshots.
    uint256 public immutable challengePeriod; // Claim challenge timewindow.
    uint256 public immutable timeoutEpochs; // The number of epochs without forward progress before the bridge is considered shutdown.

    uint256 public sequencerDelayLimit; // This is MaxTimeVariation.delaySeconds from the arbitrum sequencer inbox, it is the maximum seconds the sequencer can backdate L2 txns relative to the L1 clock.
    uint256 public sequencerFutureLimit; // This is MaxTimeVariation.futureSeconds from the arbitrum sequencer inbox, it is the maximum seconds the sequencer can futuredate L2 txns relative to the L1 clock.
    uint256 public timestampDelayUpdated; // The timestamp of the last sequencer delay update.
    uint256 public timestampFutureUpdated; // The timestamp of the last sequencer future update.

    bytes32 public stateRoot;
    uint256 public latestVerifiedEpoch;

    mapping(uint256 => Claim) public claims; // epoch => claim
    mapping(uint256 => address) public challengers; // epoch => challenger
    mapping(uint256 => bytes32) public relayed; // msgId/256 => packed replay bitmap, preferred over a simple boolean mapping to save 15k gas per message

    enum Party {
        None,
        Claimer,
        Challenger
    }

    struct Claim {
        bytes32 stateRoot;
        address claimer;
        uint32 timestamp;
        Party honest;
    }

    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /// @dev Watchers check this event to challenge fraud.
    /// @param _claimer The address of the claimer.
    /// @param _epoch The epoch associated with the claim.
    /// @param _stateRoot The state root of the claim.
    event Claimed(address indexed _claimer, uint256 _epoch, bytes32 _stateRoot);

    /// @dev This event indicates that `sendSnapshot(epoch)` should be called in the inbox.
    /// @param _epoch The epoch associated with the challenged claim.
    /// @param _challenger The address of the challenger.
    event Challenged(uint256 _epoch, address indexed _challenger);

    /// @dev This event indicates that a message has been relayed.
    /// @param _msgId The msgId of the message that was relayed.
    event MessageRelayed(uint64 _msgId);

    /// @dev This events indicates that verification has succeeded. The messages are ready to be relayed.
    /// @param _epoch The epoch that was verified.
    event Verified(uint256 _epoch);

    /// @dev This event indicates the sequencer limit updated.
    /// @param _newsequencerDelayLimit The new maxL2StateSyncDelay.
    event sequencerDelayLimitUpdateReceived(uint256 _newsequencerDelayLimit);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier OnlyBridgeRunning() {
        unchecked {
            require(block.timestamp / epochPeriod <= latestVerifiedEpoch + timeoutEpochs, "Bridge Shutdown.");
        }
        _;
    }

    modifier OnlyBridgeShutdown() {
        unchecked {
            require(block.timestamp / epochPeriod > latestVerifiedEpoch + timeoutEpochs, "Bridge Running.");
        }
        _;
    }

    /// @dev Constructor.
    /// Note: epochPeriod must match the VeaInboxGnosisToArb contract deployment on Arbitrum, since it's on a different chain, we can't read it and trust the deployer to set a correct value
    /// @param _deposit The deposit amount to submit a claim in wei.
    /// @param _epochPeriod The duration of each epoch.
    /// @param _challengePeriod The duration of the period allowing to challenge a claim.
    /// @param _timeoutEpochs The epochs before the bridge is considered shutdown.
    /// @param _routerGnosisToArb The address of the router on Ethereum that routes from Arbitrum to Ethereum.
    /// @param _sequencerDelayLimit The maximum delay in seconds that the Arbitrum sequencer can backdate transactions.
    /// @param _sequencerFutureLimit The maximum delay in seconds that the Arbitrum sequencer can futuredate transactions.
    constructor(
        uint256 _deposit,
        uint256 _epochPeriod,
        uint256 _challengePeriod,
        uint256 _timeoutEpochs,
        address _routerGnosisToArb,
        uint256 _sequencerDelayLimit,
        uint256 _sequencerFutureLimit
    ) {
        deposit = _deposit;
        epochPeriod = _epochPeriod;
        challengePeriod = _challengePeriod;
        timeoutEpochs = _timeoutEpochs;
        routerGnosisToArb = _routerGnosisToArb;
        sequencerDelayLimit = _sequencerDelayLimit;
        sequencerFutureLimit = _sequencerFutureLimit;

        // claimant and challenger are not sybil resistant
        // must burn half deposit to prevent zero cost griefing
        burn = _deposit / 2;
        depositPlusReward = 2 * _deposit - burn;

        latestVerifiedEpoch = block.timestamp / epochPeriod - 1;
    }

    // ************************************* //
    // *        Parameter Updates          * //
    // ************************************* //

    /// @dev Set the sequencerFutureLimit by reading from the Arbitrum Bridge
    /// @param _newSequencerFutureLimit The delaySeconds from the MaxTimeVariation struct in the Arbitrum Sequencer contract.
    /// @param _timestamp The timestamp of the message.
    function updateSequencerFutureLimit(uint256 _newSequencerFutureLimit, uint256 _timestamp) external {
        // Ethereum -> Arbitrum retryable ticket message authentication with the canonical Ethereum -> Arbitrum bridge.
        // example https://github.com/OffchainLabs/arbitrum-tutorials/blob/672b0b1e514f199133761daac000db954f0b5447/packages/greeter/contracts/arbitrum/GreeterL2.sol
        // docs https://developer.arbitrum.io/arbos/l1-to-l2-messaging#address-aliasing

        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(routerGnosisToArb), "Only L1 routerGnosisToArb.");

        require(timestampFutureUpdated < _timestamp, "Message is outdated.");

        if (sequencerFutureLimit != _newSequencerFutureLimit) {
            sequencerFutureLimit = _newSequencerFutureLimit;
            timestampFutureUpdated = _timestamp;
            emit sequencerDelayLimitUpdateReceived(_newSequencerFutureLimit);
        }
    }

    /// @dev Set the sequencerDelayLimit by reading from the Arbitrum Bridge
    /// @param _newSequencerDelayLimit The delaySeconds from the MaxTimeVariation struct in the Arbitrum Sequencer contract.
    /// @param _timestamp The timestamp of the message.
    function updateSequencerDelayLimit(uint256 _newSequencerDelayLimit, uint256 _timestamp) external {
        // Ethereum -> Arbitrum retryable ticket message authentication with the canonical Ethereum -> Arbitrum bridge.
        // example https://github.com/OffchainLabs/arbitrum-tutorials/blob/672b0b1e514f199133761daac000db954f0b5447/packages/greeter/contracts/arbitrum/GreeterL2.sol
        // docs https://developer.arbitrum.io/arbos/l1-to-l2-messaging#address-aliasing

        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(routerGnosisToArb), "Only L1 routerGnosisToArb.");

        require(timestampDelayUpdated < _timestamp, "Message is outdated.");

        if (sequencerDelayLimit != _newSequencerDelayLimit) {
            sequencerDelayLimit = _newSequencerDelayLimit;
            timestampDelayUpdated = _timestamp;
            emit sequencerDelayLimitUpdateReceived(_newSequencerDelayLimit);
        }
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Submit a claim about the _stateRoot at _epoch and submit a deposit.
    /// @param _epoch The epoch for which the claim is made.
    /// @param _stateRoot The state root to claim.
    function claim(uint256 _epoch, bytes32 _stateRoot) external payable virtual {
        require(msg.value >= deposit, "Insufficient claim deposit.");
        require(_epoch == block.timestamp / epochPeriod - 1, "Epoch is invalid.");

        require(_stateRoot != bytes32(0), "Invalid claim.");
        require(claims[_epoch].claimer == address(0), "Claim already made.");

        claims[_epoch] = Claim({
            stateRoot: _stateRoot,
            claimer: msg.sender,
            timestamp: uint32(block.timestamp),
            honest: Party.None
        });

        emit Claimed(msg.sender, _epoch, _stateRoot);

        // Refund overpayment.
        if (msg.value > deposit) {
            uint256 refund = msg.value - deposit;
            payable(msg.sender).send(refund); // User is responsible for accepting ETH.
        }
    }

    /// @dev Submit a challenge for the claim of the inbox state root snapshot taken at 'epoch'.
    /// @param _epoch The epoch of the claim to challenge.
    function challenge(uint256 _epoch) external payable virtual {
        require(challengers[_epoch] == address(0), "Claim already challenged.");
        require(claims[_epoch].claimer != address(0), "No claim for epoch.");
        require(msg.value >= deposit, "Insufficient challenge deposit.");

        challengers[_epoch] = msg.sender;

        emit Challenged(_epoch, msg.sender);

        // Refund overpayment.
        if (msg.value > deposit) {
            uint256 refund = msg.value - deposit;
            payable(msg.sender).send(refund); // User is responsible for accepting ETH.
        }
    }

    /// @dev Resolves the optimistic claim for '_epoch'.
    /// @param _epoch The epoch of the optimistic claim.
    function verifySnapshot(uint256 _epoch) external virtual OnlyBridgeRunning {
        uint256 claimTimestamp = uint256(claims[_epoch].timestamp);
        require(claimTimestamp > 0, "Invalid claim.");
        require(challengers[_epoch] == address(0), "Claim is challenged.");

        require(
            block.timestamp - claimTimestamp >= 2 * sequencerDelayLimit + sequencerFutureLimit + challengePeriod,
            "Claim must wait for sequencerDelay and challengePeriod."
        );

        if (_epoch > latestVerifiedEpoch) {
            latestVerifiedEpoch = _epoch;
            stateRoot = claims[_epoch].stateRoot;
            emit Verified(_epoch);
        }

        claims[_epoch].honest = Party.Claimer;
    }

    /// Note: Access restricted to AMB.
    /// @dev Resolves any challenge of the optimistic claim for '_epoch'.
    /// @param _epoch The epoch to verify.
    /// @param _stateRoot The true state root for the epoch.
    function resolveDisputedClaim(uint256 _epoch, bytes32 _stateRoot) external virtual OnlyBridgeRunning {
        // Ethereum -> Arbitrum retryable ticket message authentication with the canonical Ethereum -> Arbitrum bridge.
        // example https://github.com/OffchainLabs/arbitrum-tutorials/blob/672b0b1e514f199133761daac000db954f0b5447/packages/greeter/contracts/arbitrum/GreeterL2.sol
        // docs https://developer.arbitrum.io/arbos/l1-to-l2-messaging#address-aliasing

        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(routerGnosisToArb), "Only L1 routerGnosisToArb.");

        if (_epoch > latestVerifiedEpoch && _stateRoot != bytes32(0)) {
            latestVerifiedEpoch = _epoch;
            stateRoot = _stateRoot;
            emit Verified(_epoch);
        }

        bytes32 claimedStateRoot = claims[_epoch].stateRoot;

        if (claimedStateRoot != bytes32(0)) {
            if (claimedStateRoot == _stateRoot) {
                claims[_epoch].honest = Party.Claimer;
            } else if (challengers[_epoch] != address(0)) {
                claims[_epoch].honest = Party.Challenger;
            }
        }
    }

    /// @dev Verifies and relays the message. UNTRUSTED.
    /// @param _proof The merkle proof to prove the message.
    /// @param _msgId The zero based index of the message in the inbox.
    /// @param _to The address of the contract on Gnosis to call.
    /// @param _message The message encoded with header from VeaInbox.
    function sendMessage(bytes32[] memory _proof, uint64 _msgId, address _to, bytes memory _message) external {
        require(_proof.length < 64, "Proof too long.");

        bytes32 nodeHash = keccak256(abi.encodePacked(_msgId, _to, _message));

        // double hashed leaf
        // avoids second order preimage attacks
        // https://flawed.net.nz/2018/02/21/attacking-merkle-trees-with-a-second-preimage-attack/
        assembly {
            mstore(0x00, nodeHash)
            nodeHash := keccak256(0x00, 0x20)
        }

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                bytes32 proofElement = _proof[i];
                // sort sibling hashes as a convention for efficient proof validation
                if (proofElement > nodeHash)
                    assembly {
                        mstore(0x00, nodeHash)
                        mstore(0x20, proofElement)
                        nodeHash := keccak256(0x00, 0x40)
                    }
                else
                    assembly {
                        mstore(0x00, proofElement)
                        mstore(0x20, nodeHash)
                        nodeHash := keccak256(0x00, 0x40)
                    }
            }
        }

        require(stateRoot == nodeHash, "Invalid proof.");

        // msgId is the zero-based index of the message in the inbox.
        // msgId is also used as an index in the relayed bitmap to prevent replay.
        // Note: a bitmap is used instead of a simple boolean mapping to save 15k gas per message.

        uint256 relayIndex = _msgId >> 8;
        uint256 offset;

        unchecked {
            offset = _msgId % 256;
        }

        bytes32 replay = relayed[relayIndex];

        require(((replay >> offset) & bytes32(uint256(1))) == bytes32(0), "Message already relayed");
        relayed[relayIndex] = replay | bytes32(1 << offset);

        // UNTRUSTED.
        (bool success, ) = _to.call(_message);
        require(success, "Failed to call contract");

        emit MessageRelayed(_msgId);
    }

    /// @dev Sends the deposit back to the Claimer if successful. Includes a portion of the Challenger's deposit if unsuccessfully challenged.
    /// @param _epoch The epoch associated with the claim deposit to withraw.
    function withdrawClaimDeposit(uint256 _epoch) external virtual {
        require(claims[_epoch].honest == Party.Claimer, "Claim unsuccessful.");

        address claimer = claims[_epoch].claimer;

        delete claims[_epoch];

        if (challengers[_epoch] != address(0)) {
            payable(BURN_ADDRESS).send(burn);
            payable(claimer).send(depositPlusReward); // User is responsible for accepting ETH.
        } else {
            payable(claimer).send(deposit); // User is responsible for accepting ETH.
        }
    }

    /// @dev Sends the deposit back to the Challenger if successful. Includes a portion of the Bridger's deposit.
    /// @param _epoch The epoch associated with the challenge deposit to withraw.
    function withdrawChallengeDeposit(uint256 _epoch) external {
        require(claims[_epoch].honest == Party.Challenger, "Challenge unsuccessful.");

        address challenger = challengers[_epoch];

        delete claims[_epoch];
        delete challengers[_epoch];

        payable(BURN_ADDRESS).send(burn); // half burnt
        payable(challenger).send(depositPlusReward); // User is responsible for accepting ETH.
    }

    /// @dev When bridge is shutdown, no claim disputes can be resolved. This allows the claimer to withdraw their deposit.
    /// @param _epoch The epoch associated with the claim deposit to withraw.
    function withdrawClaimerEscapeHatch(uint256 _epoch) external OnlyBridgeShutdown {
        require(claims[_epoch].honest == Party.None, "Claim resolved.");

        address claimer = claims[_epoch].claimer;

        delete claims[_epoch];

        if (claimer != address(0)) {
            payable(claimer).send(deposit); // User is responsible for accepting ETH.
        }
    }

    /// @dev When bridge is shutdown, no claim disputes can be resolved. This allows the challenger to withdraw their deposit.
    /// @param _epoch The epoch associated with the claim deposit to withraw.
    function withdrawChallengerEscapeHatch(uint256 _epoch) external OnlyBridgeShutdown {
        require(claims[_epoch].honest == Party.None, "Claim resolved.");

        address challenger = challengers[_epoch];

        delete challengers[_epoch];

        if (challenger != address(0)) {
            payable(challenger).send(deposit); // User is responsible for accepting ETH.
        }
    }

    // ************************************* //
    // *           Pure / Views            * //
    // ************************************* //

    /// @dev Get the current epoch from the outbox's point of view using the Ethereum L1 clock.
    /// @return epoch The hash of the claim.
    function epochNow() external view returns (uint256 epoch) {
        epoch = block.timestamp / epochPeriod;
    }

    /// @dev Get the current epoch from the outbox's point of view using the Ethereum L1 clock.
    /// @return epoch The hash of the claim.
    function epochAt(uint256 timestamp) external view returns (uint256 epoch) {
        epoch = timestamp / epochPeriod;
    }
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

/// @dev Interface of the Vea Outbox on Optimistic Rollup L2s like Arbitrum, Optimism, Base, Specular where L2 storage is inexpensive compared to L1 calldata.
interface IVeaOutboxOnL2 {
    /// @dev Verifies and relays the message.
    /// Note: Gateways expect first argument of message call to be the inbox sender, used for authentication.
    /// @param _proof The merkle proof to prove the message.
    /// @param _msgId The zero based index of the message in the inbox.
    /// @param _to The address to send the message to.
    /// @param _message The message to relay.
    function sendMessage(bytes32[] calldata _proof, uint64 _msgId, address _to, bytes calldata _message) external;

    /// @dev Resolves any challenge of the optimistic claim for 'epoch' using the canonical bridge.
    /// Note: Access restricted to canonical bridge.
    /// @param _epoch The epoch to verify.
    /// @param _stateRoot The true state root for the epoch.
    function resolveDisputedClaim(uint256 _epoch, bytes32 _stateRoot) external;
}