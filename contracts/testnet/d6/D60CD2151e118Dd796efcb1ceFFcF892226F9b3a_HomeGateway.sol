// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

interface IReceiverGateway {
    function veaOutbox() external view returns (address);

    function senderGateway() external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../inboxes/IVeaInbox.sol";

interface ISenderGateway {
    function veaInbox() external view returns (IVeaInbox);

    function receiverGateway() external view returns (address);
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

pragma solidity 0.8.18;

import "./IArbitrator.sol";

/// @title IArbitrable
/// Arbitrable interface. Note that this interface follows the ERC-792 standard.
/// When developing arbitrable contracts, we need to:
/// - Define the action taken when a ruling is received by the contract.
/// - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
interface IArbitrable {
    /// @dev To be raised when a ruling is given.
    /// @param _arbitrator The arbitrator giving the ruling.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev Give a ruling for a dispute. Must be called by the arbitrator.
    /// The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./IArbitrable.sol";

/// @title Arbitrator
/// Arbitrator interface that implements the new arbitration standard.
/// Unlike the ERC-792 this standard doesn't have anything related to appeals, so each arbitrator can implement an appeal system that suits it the most.
/// When developing arbitrator contracts we need to:
/// - Define the functions for dispute creation (createDispute). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
/// - Define the functions for cost display (arbitrationCost).
/// - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
interface IArbitrator {
    /// @dev To be emitted when a dispute is created.
    /// @param _disputeID ID of the dispute.
    /// @param _arbitrable The contract which created the dispute.
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /// @dev To be raised when a ruling is given.
    /// @param _arbitrable The arbitrable receiving the ruling.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling The ruling which was given.
    event Ruling(IArbitrable indexed _arbitrable, uint256 indexed _disputeID, uint256 _ruling);

    /// @dev Create a dispute. Must be called by the arbitrable contract.
    /// Must pay at least arbitrationCost(_extraData).
    /// @param _choices Amount of choices the arbitrator can make in this dispute.
    /// @param _extraData Can be used to give additional info on the dispute to be created.
    /// @return disputeID ID of the dispute created.
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /// @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
    /// @param _extraData Can be used to give additional info on the dispute to be created.
    /// @return cost Required cost of arbitration.
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../arbitration/IArbitrator.sol";

/// @title IMetaEvidence
/// ERC-1497: Evidence Standard excluding evidence emission as it will be handled by the arbitrator.
interface IMetaEvidence {
    /// @dev To be emitted when meta-evidence is submitted.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /// @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
    /// @param _arbitrator The arbitrator of the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere, @shalzz]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../arbitration/IArbitrator.sol";
import "./interfaces/IForeignGateway.sol";
import "./interfaces/IHomeGateway.sol";

/// Home Gateway
/// Counterpart of `ForeignGateway`
contract HomeGateway is IHomeGateway {
    // ************************************* //
    // *         Enums / Structs           * //
    // ************************************* //

    struct RelayedData {
        uint256 arbitrationCost;
        address relayer;
    }

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    address public governor;
    IArbitrator public arbitrator;
    IVeaInbox public veaInbox;
    address public override receiverGateway;
    uint256 public immutable receiverChainID;
    mapping(uint256 => bytes32) public disputeIDtoHash;
    mapping(bytes32 => uint256) public disputeHashtoID;
    mapping(bytes32 => RelayedData) public disputeHashtoRelayedData;

    constructor(
        address _governor,
        IArbitrator _arbitrator,
        IVeaInbox _veaInbox,
        address _receiverGateway,
        uint256 _receiverChainID
    ) {
        governor = _governor;
        arbitrator = _arbitrator;
        veaInbox = _veaInbox;
        receiverGateway = _receiverGateway;
        receiverChainID = _receiverChainID;

        emit MetaEvidence(0, "BRIDGE");
    }

    // ************************************* //
    // *           Governance              * //
    // ************************************* //

    /// @dev Changes the governor.
    /// @param _governor The address of the new governor.
    function changeGovernor(address _governor) external {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        governor = _governor;
    }

    /// @dev Changes the arbitrator.
    /// @param _arbitrator The address of the new arbitrator.
    function changeArbitrator(IArbitrator _arbitrator) external {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        arbitrator = _arbitrator;
    }

    /// @dev Changes the vea inbox, useful to increase the claim deposit.
    /// @param _veaInbox The address of the new vea inbox.
    function changeVea(IVeaInbox _veaInbox) external {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        veaInbox = _veaInbox;
    }

    /// @dev Changes the receiver gateway.
    /// @param _receiverGateway The address of the new receiver gateway.
    function changeReceiverGateway(address _receiverGateway) external {
        require(governor == msg.sender, "Access not allowed: Governor only.");
        receiverGateway = _receiverGateway;
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Provide the same parameters as on the foreignChain while creating a dispute. Providing incorrect parameters will create a different hash than on the foreignChain and will not affect the actual dispute/arbitrable's ruling.
    /// @param _foreignChainID foreignChainId
    /// @param _foreignBlockHash foreignBlockHash
    /// @param _foreignDisputeID foreignDisputeID
    /// @param _choices number of ruling choices
    /// @param _extraData extraData
    /// @param _arbitrable arbitrable
    function relayCreateDispute(
        uint256 _foreignChainID,
        bytes32 _foreignBlockHash,
        uint256 _foreignDisputeID,
        uint256 _choices,
        bytes calldata _extraData,
        address _arbitrable
    ) external payable override {
        bytes32 disputeHash = keccak256(
            abi.encodePacked(
                _foreignChainID,
                _foreignBlockHash,
                "createDispute",
                _foreignDisputeID,
                _choices,
                _extraData,
                _arbitrable
            )
        );
        RelayedData storage relayedData = disputeHashtoRelayedData[disputeHash];
        require(relayedData.relayer == address(0), "Dispute already relayed");

        // TODO: will mostly be replaced by the actual arbitrationCost paid on the foreignChain.
        relayedData.arbitrationCost = arbitrator.arbitrationCost(_extraData);
        require(msg.value >= relayedData.arbitrationCost, "Not enough arbitration cost paid");

        uint256 disputeID = arbitrator.createDispute{value: msg.value}(_choices, _extraData);
        disputeIDtoHash[disputeID] = disputeHash;
        disputeHashtoID[disputeHash] = disputeID;
        relayedData.relayer = msg.sender;

        emit Dispute(arbitrator, disputeID, 0, 0);
    }

    /// @dev Give a ruling for a dispute. Must be called by the arbitrator.
    /// The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
    function rule(uint256 _disputeID, uint256 _ruling) external override {
        require(msg.sender == address(arbitrator), "Only Arbitrator");

        bytes32 disputeHash = disputeIDtoHash[_disputeID];
        RelayedData memory relayedData = disputeHashtoRelayedData[disputeHash];

        // The first parameter of relayRule() `_messageSender` is missing from the encoding below
        // because Vea takes care of inserting it for security reasons.
        bytes4 methodSelector = IForeignGateway.relayRule.selector;
        bytes memory data = abi.encode(disputeHash, _ruling, relayedData.relayer);
        veaInbox.sendMessage(receiverGateway, methodSelector, data);
    }

    /// @dev Looks up the local home disputeID for a disputeHash. For cross-chain Evidence standard.
    /// @param _disputeHash dispute hash
    function disputeHashToHomeID(bytes32 _disputeHash) external view override returns (uint256) {
        return disputeHashtoID[_disputeHash];
    }
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere, @shalzz]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../../arbitration/IArbitrator.sol";
import "@kleros/vea-contracts/src/interfaces/gateways/IReceiverGateway.sol";

interface IForeignGateway is IArbitrator, IReceiverGateway {
    /// Relay the rule call from the home gateway to the arbitrable.
    function relayRule(address _messageSender, bytes32 _disputeHash, uint256 _ruling, address _forwarder) external;

    function withdrawFees(bytes32 _disputeHash) external;

    // For cross-chain Evidence standard
    function disputeHashToForeignID(bytes32 _disputeHash) external view returns (uint256);

    function createDisputeERC20(
        uint256 _choices,
        bytes calldata _extraData,
        uint256 _amount
    ) external returns (uint256 disputeID);
}

// SPDX-License-Identifier: MIT

/// @custom:authors: [@jaybuidl, @shotaronowhere, @shalzz]
/// @custom:reviewers: []
/// @custom:auditors: []
/// @custom:bounties: []
/// @custom:deployments: []

pragma solidity 0.8.18;

import "../../arbitration/IArbitrable.sol";
import "../../evidence/IMetaEvidence.sol";
import "@kleros/vea-contracts/src/interfaces/gateways/ISenderGateway.sol";

interface IHomeGateway is IArbitrable, IMetaEvidence, ISenderGateway {
    /// @dev Provide the same parameters as on the foreignChain while creating a dispute. Providing incorrect parameters will create a different hash than on the foreignChain and will not affect the actual dispute/arbitrable's ruling.
    /// @param _foreignChainID foreignChainId
    /// @param _foreignBlockHash foreignBlockHash
    /// @param _foreignDisputeID foreignDisputeID
    /// @param _choices number of ruling choices
    /// @param _extraData extraData
    /// @param _arbitrable arbitrable
    function relayCreateDispute(
        uint256 _foreignChainID,
        bytes32 _foreignBlockHash,
        uint256 _foreignDisputeID,
        uint256 _choices,
        bytes calldata _extraData,
        address _arbitrable
    ) external payable;

    /// @dev Looks up the local home disputeID for a disputeHash. For cross-chain Evidence standard.
    /// @param _disputeHash dispute hash
    function disputeHashToHomeID(bytes32 _disputeHash) external view returns (uint256);
}