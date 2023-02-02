// SPDX-License-Identifier: MIT

/**
 *  @authors: [@jaybuidl, @shotaronowhere, @hrishibhat]
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
     * @param _epoch The epoch for which the the claim was made.
     * @param _batchMerkleRoot The timestamp of the claim creation.
     */
    event ClaimReceived(uint256 indexed _epoch, bytes32 indexed _batchMerkleRoot);

    /**
     * @dev This event indicates that `sendSafeFallback()` should be called on the sending side.
     * @param _epoch The epoch associated with the challenged claim.
     */
    event ClaimChallenged(uint256 indexed _epoch);

    /**
     * @dev This events indicates that optimistic verification has succeeded. The messages are ready to be relayed.
     * @param _epoch The epoch associated with the batch.
     * @param _success The success of the optimistic verification.
     */
    event BatchVerified(uint256 indexed _epoch, bool _success);

    /**
     * @dev This event indicates that the batch has been received via the Safe Bridge.
     * @param _epoch The epoch associated with the batch.
     * @param _isBridgerHonest Whether the bridger made an honest claim.
     * @param _isChallengerHonest Whether the bridger made an honest challenge.
     */
    event BatchSafeVerified(uint256 indexed _epoch, bool _isBridgerHonest, bool _isChallengerHonest);

    /**
     * @dev This event indicates that the claim deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _bridger The recipient of the claim deposit.
     */
    event ClaimDepositWithdrawn(uint256 indexed _epoch, address indexed _bridger);

    /**
     * @dev This event indicates that the challenge deposit has been withdrawn.
     * @param _epoch The epoch associated with the batch.
     * @param _challenger The recipient of the challenge deposit.
     */
    event ChallengeDepositWithdrawn(uint256 indexed _epoch, address indexed _challenger);

    /**
     * @dev This event indicates that a message has been relayed for the batch in this `_epoch`.
     * @param _epoch The epoch associated with the batch.
     * @param _nonce The nonce of the message that was relayed.
     */
    event MessageRelayed(uint256 indexed _epoch, uint256 indexed _nonce);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * @dev Submit a claim about the `_batchMerkleRoot` for the latests completed Fast bridge epoch and submit a deposit. The `_batchMerkleRoot` should match the one on the sending side otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to claim.
     * @param _batchMerkleRoot The hash claimed for the ticket.
     */
    function claim(uint256 _epoch, bytes32 _batchMerkleRoot) external payable;

    /**
     * @dev Submit a challenge for the claim of the current epoch's Fast Bridge batch merkleroot state and submit a deposit. The `batchMerkleRoot` in the claim already made for the last finalized epoch should be different from the one on the sending side, otherwise the sender will lose his deposit.
     * @param _epoch The epoch of the claim to challenge.
     */
    function challenge(uint256 _epoch) external payable;

    /**
     * @dev Resolves the optimistic claim for '_epoch'.
     * @param _epoch The epoch of the optimistic claim.
     */
    function verifyBatch(uint256 _epoch) external;

    /**
     * @dev Verifies merkle proof for the given message and associated nonce for the most recent possible epoch and relays the message.
     * @param _epoch The epoch in which the message was batched by the bridge.
     * @param _proof The merkle proof to prove the membership of the message and nonce in the merkle tree for the epoch.
     * @param _message The data on the cross-domain chain for the message.
     */
    function verifyAndRelayMessage(
        uint256 _epoch,
        bytes32[] calldata _proof,
        bytes calldata _message
    ) external;

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
     * @param _epoch The epoch of the claim to request the challenge period.
     * @return start The start time of the challenge period.
     * @return end The end time of the challenge period.
     */
    function claimChallengePeriod(uint256 _epoch) external view returns (uint256 start, uint256 end);

    /**
     * @dev Returns the epoch period.
     */
    function epochPeriod() external view returns (uint256 epochPeriod);

    /**
     * @dev Returns the challenge period.
     */
    function challengePeriod() external view returns (uint256 challengePeriod);
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

interface IFastBridgeSender {
    // ************************************* //
    // *              Events               * //
    // ************************************* //

    /**
     * @dev The Fast Bridge participants need to watch for these events and relay the messageHash on the FastBridgeReceiverOnEthereum.
     * @param fastMessage The fast message data.
     * @param fastMessage The hash of the fast message data encoded with the nonce.
     */
    event MessageReceived(bytes fastMessage, bytes32 fastMessageHash);

    /**
     * @dev The event is emitted when messages are sent through the canonical bridge.
     * @param epoch The epoch of the batch requested to send.
     * @param canonicalBridgeMessageID The unique identifier of the safe message returned by the canonical bridge.
     */
    event SentSafe(uint256 indexed epoch, bytes32 canonicalBridgeMessageID);

    /**
     * The bridgers need to watch for these events and relay the
     * batchMerkleRoot on the FastBridgeReceiver.
     */
    event BatchOutgoing(uint256 indexed batchID, uint256 batchSize, uint256 epoch, bytes32 batchMerkleRoot);

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    /**
     * Note: Access must be restricted by the receiving gateway by checking the sender argument.
     * @dev Sends an arbitrary message across domain using the Fast Bridge.
     * @param _receiver The cross-domain contract address which receives the calldata.
     * @param _calldata The receiving domain encoded message data.
     */
    function sendFast(address _receiver, bytes memory _calldata) external;

    /**
     * Sends a batch of arbitrary message from one domain to another
     * via the fast bridge mechanism.
     */
    function sendBatch() external;

    /**
     * @dev Sends a markle root representing an arbitrary batch of messages across domain using the Safe Bridge, which relies on the chain's canonical bridge. It is unnecessary during normal operations but essential only in case of challenge.
     * @param _epoch block number of batch
     */
    function sendSafeFallback(uint256 _epoch) external payable;
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

import "./IFastBridgeReceiver.sol";

interface IReceiverGateway {
    function fastBridgeReceiver() external view returns (IFastBridgeReceiver);

    function senderChainID() external view returns (uint256);

    function senderGateway() external view returns (address);
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

import "./IFastBridgeSender.sol";

interface ISenderGateway {
    function fastBridgeSender() external view returns (IFastBridgeSender);

    function receiverChainID() external view returns (uint256);

    function receiverGateway() external view returns (address);
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

import "../../interfaces/IReceiverGateway.sol";

interface IReceiverGatewayMock is IReceiverGateway {
    /**
     * Receive the message from the sender gateway.
     */
    function receiveMessage(uint256 _data) external;
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

import "./IReceiverGatewayMock.sol";
import "../../interfaces/ISenderGateway.sol";

/**
 * Sender Gateway
 * Counterpart of `ReceiverGatewayMock`
 */
contract SenderGatewayMock is ISenderGateway {
    IFastBridgeSender public immutable fastBridgeSender;
    address public override receiverGateway;
    uint256 public immutable override receiverChainID;

    // @note - We can remove this as we are not using this.
    struct RelayedData {
        uint256 arbitrationCost;
        address relayer;
    }
    mapping(bytes32 => RelayedData) public disputeHashtoRelayedData;

    constructor(
        IFastBridgeSender _fastBridgeSender,
        address _receiverGateway,
        uint256 _receiverChainID
    ) {
        fastBridgeSender = _fastBridgeSender;
        receiverGateway = _receiverGateway;
        receiverChainID = _receiverChainID;
    }

    function sendFastMessage(uint256 _data) external {
        bytes4 methodSelector = IReceiverGatewayMock.receiveMessage.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, _data);

        fastBridgeSender.sendFast(receiverGateway, data);
    }
}