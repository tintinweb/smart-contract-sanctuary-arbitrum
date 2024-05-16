// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { Error } from "src/libraries/Error.sol";
import { AMBMessage } from "src/types/DataTypes.sol";
import { IMailbox } from "src/vendor/hyperlane/IMailbox.sol";
import { IMessageRecipient } from "src/vendor/hyperlane/IMessageRecipient.sol";
import { IInterchainGasPaymaster } from "src/vendor/hyperlane/IInterchainGasPaymaster.sol";
import { StandardHookMetadata } from "src/vendor/hyperlane/StandardHookMetadata.sol";

/// @title HyperlaneImplementation
/// @dev Allows state registries to use Hyperlane v3 for crosschain communication
/// @author Zeropoint Labs
contract HyperlaneImplementation is IAmbImplementation, IMessageRecipient {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;

    mapping(uint64 => uint32) public ambChainId;
    mapping(uint32 => uint64) public superChainId;
    mapping(uint32 => address) public authorizedImpl;
    mapping(bytes32 => bool) public processedMessages;
    mapping(bytes32 => bool) public ambProtect;

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event MailboxAdded(address indexed _newMailbox);
    event GasPayMasterAdded(address indexed _igp);

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    modifier onlyValidStateRegistry() {
        if (!superRegistry.isValidStateRegistry(msg.sender)) {
            revert Error.NOT_STATE_REGISTRY();
        }
        _;
    }

    modifier onlyMailbox() {
        if (msg.sender != address(mailbox)) {
            revert Error.CALLER_NOT_MAILBOX();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) {
        superRegistry = superRegistry_;
    }

    //////////////////////////////////////////////////////////////
    //                         CONFIG                            //
    //////////////////////////////////////////////////////////////

    /// @dev allows protocol admin to configure hyperlane mailbox and gas paymaster
    /// @param mailbox_ is the address of hyperlane mailbox
    /// @param igp_ is the address of hyperlane gas paymaster
    function setHyperlaneConfig(IMailbox mailbox_, IInterchainGasPaymaster igp_) external onlyProtocolAdmin {
        if (address(mailbox_) == address(0) || address(igp_) == address(0)) revert Error.ZERO_ADDRESS();
        mailbox = mailbox_;
        igp = igp_;

        emit MailboxAdded(address(mailbox_));
        emit GasPayMasterAdded(address(igp_));
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAmbImplementation
    function estimateFees(
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        view
        override
        returns (uint256 fees)
    {
        uint32 domain = ambChainId[dstChainId_];

        if (domain == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        fees = mailbox.quoteDispatch(
            domain, _castAddr(authorizedImpl[domain]), message_, _generateHookMetadata(extraData_, msg.sender)
        );
    }

    /// @inheritdoc IAmbImplementation
    function generateExtraData(uint256 gasLimit) external pure override returns (bytes memory extraData) {
        /// @notice encoded dst gas limit
        extraData = abi.encode(gasLimit);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAmbImplementation
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable
        virtual
        override
        onlyValidStateRegistry
    {
        uint32 domain = ambChainId[dstChainId_];

        if (domain == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        mailbox.dispatch{ value: msg.value }(
            domain, _castAddr(authorizedImpl[domain]), message_, _generateHookMetadata(extraData_, srcSender_)
        );
    }

    /// @inheritdoc IAmbImplementation
    function retryPayload(bytes memory data_) external payable override {
        (bytes32 messageId, uint32 destinationDomain, uint256 gasAmount) = abi.decode(data_, (bytes32, uint32, uint256));
        uint256 fees = igp.quoteGasPayment(destinationDomain, gasAmount);

        if (msg.value < fees) {
            revert Error.INVALID_RETRY_FEE();
        }

        /// refunds any excess msg.value to msg.sender
        igp.payForGas{ value: msg.value }(messageId, destinationDomain, gasAmount, msg.sender);
    }

    /// @dev allows protocol admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param ambChainId_ is the identifier of the chain given by the AMB
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setChainId(uint64 superChainId_, uint32 ambChainId_) external onlyProtocolAdmin {
        if (superChainId_ == 0 || ambChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        // @dev  reset old mappings
        uint64 oldSuperChainId = superChainId[ambChainId_];
        uint32 oldAmbChainId = ambChainId[superChainId_];

        if (oldSuperChainId != 0) {
            delete ambChainId[oldSuperChainId];
        }

        if (oldAmbChainId != 0) {
            delete superChainId[oldAmbChainId];
        }

        ambChainId[superChainId_] = ambChainId_;
        superChainId[ambChainId_] = superChainId_;

        emit ChainAdded(superChainId_);
    }

    /// @dev allows protocol admin to set receiver implementation on a new chain id
    /// @param domain_ is the identifier of the destination chain within hyperlane
    /// @param authorizedImpl_ is the implementation of the hyperlane message bridge on the specified destination
    /// NOTE: cannot be defined in an interface as types vary for each message bridge (amb)
    function setReceiver(uint32 domain_, address authorizedImpl_) external onlyProtocolAdmin {
        if (domain_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        if (authorizedImpl_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        authorizedImpl[domain_] = authorizedImpl_;

        emit AuthorizedImplAdded(domain_, authorizedImpl_);
    }

    /// @inheritdoc IMessageRecipient
    function handle(uint32 origin_, bytes32 sender_, bytes calldata body_) external payable override onlyMailbox {
        /// @dev 1. validate caller
        /// @dev 2. validate src chain sender
        /// @dev 3. validate message uniqueness

        if (sender_ != _castAddr(authorizedImpl[origin_])) {
            revert Error.INVALID_SRC_SENDER();
        }

        bytes32 hash = keccak256(body_);

        if (processedMessages[hash]) {
            revert Error.DUPLICATE_PAYLOAD();
        }

        processedMessages[hash] = true;

        /// @dev decoding payload
        AMBMessage memory decoded = abi.decode(body_, (AMBMessage));

        /// NOTE: experimental split of registry contracts
        (,,, uint8 registryId,,) = decoded.txInfo.decodeTxInfo();
        IBaseStateRegistry targetRegistry = IBaseStateRegistry(superRegistry.getStateRegistry(registryId));

        uint64 origin = superChainId[origin_];

        if (origin == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        _ambProtect(decoded);
        targetRegistry.receivePayload(origin, body_);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev casts an address to bytes32
    /// @param addr_ is the address to be casted
    /// @return a bytes32 casted variable of the address passed in params
    function _castAddr(address addr_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr_)));
    }

    /// @dev casts superform extraData to hyperlane hook metadata
    function _generateHookMetadata(
        bytes memory extraData_,
        address srcSender_
    )
        internal
        pure
        returns (bytes memory hookMetaData)
    {
        if (extraData_.length != 0) {
            // extra data is encoded gas limit on dst chain
            uint256 gasLimit = abi.decode(extraData_, (uint256));
            hookMetaData = StandardHookMetadata.formatMetadata(gasLimit, srcSender_);
        }
    }

    /// @dev prevents the same AMB from delivery a payload and its proof
    /// @dev is an additional protection against malicious ambs
    function _ambProtect(AMBMessage memory _message) internal {
        bytes32 proof;

        /// @dev amb protect
        if (_message.params.length != 32) {
            (, bytes memory payloadBody) = abi.decode(_message.params, (uint8[], bytes));
            proof = AMBMessage(_message.txInfo, payloadBody).computeProof();
        } else {
            proof = abi.decode(_message.params, (bytes32));
        }

        if (ambProtect[proof]) revert MALICIOUS_DELIVERY();
        ambProtect[proof] = true;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IAmbImplementation
/// @dev Interface for arbitrary message bridge (AMB) implementations
/// @author ZeroPoint Labs
interface IAmbImplementation {
     //////////////////////////////////////////////////////////////
    //                      AMB  ERRORS                         //
    //////////////////////////////////////////////////////////////

    /// @dev thrown if same amb tries to deliver a payload and proof
    error MALICIOUS_DELIVERY();

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    event ChainAdded(uint64 indexed superChainId);
    event AuthorizedImplAdded(uint64 indexed superChainId, address indexed authImpl);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the gas fees estimation in native tokens
    /// @notice not all AMBs will have on-chain estimation for which this function will return 0
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message
    /// @param extraData_ is any amb-specific information
    /// @return fees is the native_tokens to be sent along the transaction
    function estimateFees(
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        view
        returns (uint256 fees);

    /// @dev returns the extra data for the given gas request
    /// @param gasLimit is the amount of gas limit in wei to override
    /// @return extraData is the bytes encoded extra data
    /// NOTE: this process is unique to the message bridge
    function generateExtraData(uint256 gasLimit) external pure returns (bytes memory extraData);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows state registry to send message via implementation.
    /// @param srcSender_ is the caller (used for gas refunds)
    /// @param dstChainId_ is the identifier of the destination chain
    /// @param message_ is the cross-chain message to be sent
    /// @param extraData_ is message amb specific override information
    function dispatchPayload(
        address srcSender_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows for the permissionless calling of the retry mechanism for encoded data
    /// @param data_ is the encoded retry data (different per AMB implementation)
    function retryPayload(bytes memory data_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { PayloadState } from "src/types/DataTypes.sol";

/// @title IBaseStateRegistry
/// @dev Interface for BaseStateRegistry
/// @author ZeroPoint Labs
interface IBaseStateRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when a cross-chain payload is received in the state registry
    event PayloadReceived(uint64 indexed srcChainId, uint64 indexed dstChainId, uint256 indexed payloadId);

    /// @dev is emitted when a cross-chain proof is received in the state registry
    /// NOTE: comes handy if quorum required is more than 0
    event ProofReceived(bytes32 indexed proof);

    /// @dev is emitted when a payload id gets updated
    event PayloadUpdated(uint256 indexed payloadId);

    /// @dev is emitted when a payload id gets processed
    event PayloadProcessed(uint256 indexed payloadId);

    /// @dev is emitted when the super registry address is updated
    event SuperRegistryUpdated(address indexed superRegistry);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev allows users to read the total payloads received by the registry
    function payloadsCount() external view returns (uint256);

    /// @dev allows user to read the payload state
    /// uint256 payloadId_ is the unique payload identifier allocated on the destination chain
    function payloadTracking(uint256 payloadId_) external view returns (PayloadState payloadState_);

    /// @dev allows users to read the bytes payload_ stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadBody_ the crosschain data received
    function payloadBody(uint256 payloadId_) external view returns (bytes memory payloadBody_);

    /// @dev allows users to read the uint256 payloadHeader stored per payloadId_
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return payloadHeader_ the crosschain header received
    function payloadHeader(uint256 payloadId_) external view returns (uint256 payloadHeader_);

    /// @dev allows users to read the ambs that delivered the payload id
    /// @param payloadId_ is the unique payload identifier allocated on the destination chain
    /// @return ambIds_ is the identifier of ambs that delivered the message and proof
    function getMessageAMB(uint256 payloadId_) external view returns (uint8[] memory ambIds_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev allows core contracts to send payload to a destination chain.
    /// @param srcSender_ is the caller of the function (used for gas refunds).
    /// @param ambIds_ is the identifier of the arbitrary message bridge to be used
    /// @param dstChainId_ is the internal chainId used throughout the protocol
    /// @param message_ is the crosschain payload to be sent
    /// @param extraData_ defines all the message bridge related overrides
    /// NOTE: dstChainId_ is mapped to message bridge's destination id inside it's implementation contract
    /// NOTE: ambIds_ are superform assigned unique identifier for arbitrary message bridges
    function dispatchPayload(
        address srcSender_,
        uint8[] memory ambIds_,
        uint64 dstChainId_,
        bytes memory message_,
        bytes memory extraData_
    )
        external
        payable;

    /// @dev allows state registry to receive messages from message bridge implementations
    /// @param srcChainId_ is the superform chainId from which the payload is dispatched/sent
    /// @param message_ is the crosschain payload received
    /// NOTE: Only {IMPLEMENTATION_CONTRACT} role can call this function.
    function receivePayload(uint64 srcChainId_, bytes memory message_) external;

    /// @dev allows privileged actors to process cross-chain payloads
    /// @param payloadId_ is the identifier of the cross-chain payload
    /// NOTE: Only {CORE_STATE_REGISTRY_PROCESSOR_ROLE} role can call this function
    /// NOTE: this should handle reverting the state on source chain in-case of failure
    /// (or) can implement scenario based reverting like in coreStateRegistry
    function processPayload(uint256 payloadId_) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IAccessControl } from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

/// @title ISuperRBAC
/// @dev Interface for SuperRBAC
/// @author Zeropoint Labs
interface ISuperRBAC is IAccessControl {

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    struct InitialRoleSetup {
        address admin;
        address emergencyAdmin;
        address paymentAdmin;
        address csrProcessor;
        address tlProcessor;
        address brProcessor;
        address csrUpdater;
        address srcVaaRelayer;
        address dstSwapper;
        address csrRescuer;
        address csrDisputer;
    }

    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev is emitted when superRegistry is set
    event SuperRegistrySet(address indexed superRegistry);

    /// @dev is emitted when an admin is set for a role
    event RoleAdminSet(bytes32 role, bytes32 adminRole);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the id of the protocol admin role
    function PROTOCOL_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the emergency admin role
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the payment admin role
    function PAYMENT_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcaster role
    function BROADCASTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor role
    function CORE_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the timelock state registry processor role
    function TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry processor role
    function BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater role
    function CORE_STATE_REGISTRY_UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the dst swapper role
    function DST_SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescuer role
    function CORE_STATE_REGISTRY_RESCUER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry rescue disputer role
    function CORE_STATE_REGISTRY_DISPUTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of wormhole vaa relayer role
    function WORMHOLE_VAA_RELAYER_ROLE() external view returns (bytes32);

    /// @dev returns whether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev updates the super registry address
    function setSuperRegistry(address superRegistry_) external;

    /// @dev configures a new role in superForm
    /// @param role_ the role to set
    /// @param adminRole_ the admin role to set as admin
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external;

    /// @dev revokes the role_ from superRegistryAddressId_ on all chains
    /// @param role_ the role to revoke
    /// @param extraData_ amb config if broadcasting is required
    /// @param superRegistryAddressId_ the super registry address id
    function revokeRoleSuperBroadcast(
        bytes32 role_,
        bytes memory extraData_,
        bytes32 superRegistryAddressId_
    )
        external
        payable;

    /// @dev allows sync of global roles from different chains using broadcast registry
    /// @notice may not work for all roles
    function stateSyncBroadcast(bytes memory data_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ISuperRegistry
/// @dev Interface for SuperRegistry
/// @author Zeropoint Labs
interface ISuperRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when permit2 is set.
    event SetPermit2(address indexed permit2);

    /// @dev is emitted when an address is set.
    event AddressUpdated(
        bytes32 indexed protocolAddressId, uint64 indexed chainId, address indexed oldAddress, address newAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 indexed ambId_, address indexed ambAddress_, bool indexed isBroadcastAMB_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 indexed registryId_, address indexed registryAddress_);

    /// @dev is emitted when a new delay is configured.
    event SetDelay(uint256 indexed oldDelay_, uint256 indexed newDelay_);

    /// @dev is emitted when a new vault limit is configured
    event SetVaultLimitPerDestination(uint64 indexed chainId_, uint256 indexed vaultLimit_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev gets the deposit rescue delay
    function delay() external view returns (uint256);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the superform router module
    function SUPERFORM_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry module
    function TIMELOCK_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry module
    function BROADCAST_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the payload helper module
    function PAYLOAD_HELPER() external view returns (bytes32);

    /// @dev returns the id of the dst swapper keeper
    function DST_SWAPPER() external view returns (bytes32);

    /// @dev returns the id of the emergency queue
    function EMERGENCY_QUEUE() external view returns (bytes32);

    /// @dev returns the id of the superform receiver
    function SUPERFORM_RECEIVER() external view returns (bytes32);

    /// @dev returns the id of the payment admin keeper
    function PAYMENT_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor keeper
    function CORE_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the broadcast registry processor keeper
    function BROADCAST_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry processor keeper
    function TIMELOCK_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_UPDATER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_RESCUER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_DISPUTER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function DST_SWAPPER_PROCESSOR() external view returns (bytes32);

    /// @dev gets the address of a contract on current chain
    /// @param id_ is the id of the contract
    function getAddress(bytes32 id_) external view returns (address);

    /// @dev gets the address of a contract on a target chain
    /// @param id_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view returns (address);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);

    /// @dev gets the id of the amb
    /// @param ambAddress_ is the address of an amb
    /// @return ambId_ is the identifier of an amb
    function getAmbId(address ambAddress_) external view returns (uint8 ambId_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev gets the safe vault limit
    /// @param chainId_ is the id of the remote chain
    /// @return vaultLimitPerDestination_ is the safe number of vaults to deposit
    /// without hitting out of gas error
    function getVaultLimitPerDestination(uint64 chainId_) external view returns (uint256 vaultLimitPerDestination_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid broadcast amb implementation
    /// @param ambAddress_ is the address of the broadcast amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidBroadcastAmbImpl(address ambAddress_) external view returns (bool valid_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev sets the deposit rescue delay
    /// @param delay_ the delay in seconds before the deposit rescue can be finalized
    function setDelay(uint256 delay_) external;

    /// @dev sets the permit2 address
    /// @param permit2_ the address of the permit2 contract
    function setPermit2(address permit2_) external;

    /// @dev sets the safe vault limit
    /// @param chainId_ is the remote chain identifier
    /// @param vaultLimit_ is the max limit of vaults per transaction
    function setVaultLimitPerDestination(uint64 chainId_, uint256 vaultLimit_) external;

    /// @dev sets new addresses on specific chains.
    /// @param ids_ are the identifiers of the address on that chain
    /// @param newAddresses_  are the new addresses on that chain
    /// @param chainIds_ are the chain ids of that chain
    function batchSetAddress(
        bytes32[] calldata ids_,
        address[] calldata newAddresses_,
        uint64[] calldata chainIds_
    )
        external;

    /// @dev sets a new address on a specific chain.
    /// @param id_ the identifier of the address on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param bridgeId_         represents the bridge unique identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param ambId_         represents the bridge unique identifier.
    /// @param ambAddress_    represents the bridge address.
    /// @param isBroadcastAMB_ represents whether the amb implementation supports broadcasting
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param registryId_    represents the state registry's unique identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { Error } from "src/libraries/Error.sol";

library DataLib {
    function packTxInfo(
        uint8 txType_,
        uint8 callbackType_,
        uint8 multi_,
        uint8 registryId_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        pure
        returns (uint256 txInfo)
    {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 8;
        txInfo |= uint256(multi_) << 16;
        txInfo |= uint256(registryId_) << 24;
        txInfo |= uint256(uint160(srcSender_)) << 32;
        txInfo |= uint256(srcChainId_) << 192;
    }

    function decodeTxInfo(uint256 txInfo_)
        internal
        pure
        returns (uint8 txType, uint8 callbackType, uint8 multi, uint8 registryId, address srcSender, uint64 srcChainId)
    {
        txType = uint8(txInfo_);
        callbackType = uint8(txInfo_ >> 8);
        multi = uint8(txInfo_ >> 16);
        registryId = uint8(txInfo_ >> 24);
        srcSender = address(uint160(txInfo_ >> 32));
        srcChainId = uint64(txInfo_ >> 192);
    }

    /// @dev returns the vault-form-chain pair of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        internal
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_)
    {
        superform_ = address(uint160(superformId_));
        formImplementationId_ = uint32(superformId_ >> 160);
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superformIds_  array of superforms
    /// @return superforms_ are the address of the vaults
    function getSuperforms(uint256[] memory superformIds_) internal pure returns (address[] memory superforms_) {
        uint256 len = superformIds_.length;
        superforms_ = new address[](len);

        for (uint256 i; i < len; ++i) {
            (superforms_[i],,) = getSuperform(superformIds_[i]);
        }
    }

    /// @dev returns the destination chain of a given superform
    /// @param superformId_ is the id of the superform
    /// @return chainId_ is the chain id
    function getDestinationChain(uint256 superformId_) internal pure returns (uint64 chainId_) {
        chainId_ = uint64(superformId_ >> 192);

        if (chainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }
    }

    /// @dev generates the superformId
    /// @param superform_ is the address of the superform
    /// @param formImplementationId_ is the type of the form
    /// @param chainId_ is the chain id on which the superform is deployed
    function packSuperform(
        address superform_,
        uint32 formImplementationId_,
        uint64 chainId_
    )
        internal
        pure
        returns (uint256 superformId_)
    {
        superformId_ = uint256(uint160(superform_));
        superformId_ |= uint256(formImplementationId_) << 160;
        superformId_ |= uint256(chainId_) << 192;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AMBMessage } from "src/types/DataTypes.sol";

/// @dev generates proof for amb message and bytes encoded message
library ProofLib {
    function computeProof(AMBMessage memory message_) internal pure returns (bytes32) {
        return keccak256(abi.encode(message_));
    }

    function computeProofBytes(AMBMessage memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(message_)));
    }

    function computeProof(bytes memory message_) internal pure returns (bytes32) {
        return keccak256(message_);
    }

    function computeProofBytes(bytes memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(message_));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library Error {
    //////////////////////////////////////////////////////////////
    //                  CONFIGURATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown in protocol setup

    /// @dev thrown if chain id exceeds max(uint64)
    error BLOCK_CHAIN_ID_OUT_OF_BOUNDS();

    /// @dev thrown if not possible to revoke a role in broadcasting
    error CANNOT_REVOKE_NON_BROADCASTABLE_ROLES();

    /// @dev thrown if not possible to revoke last admin
    error CANNOT_REVOKE_LAST_ADMIN();

    /// @dev thrown if trying to set again pseudo immutables in super registry
    error DISABLED();

    /// @dev thrown if rescue delay is not yet set for a chain
    error DELAY_NOT_SET();

    /// @dev thrown if get native token price estimate in paymentHelper is 0
    error INVALID_NATIVE_TOKEN_PRICE();

    /// @dev thrown if wormhole refund chain id is not set
    error REFUND_CHAIN_ID_NOT_SET();

    /// @dev thrown if wormhole relayer is not set
    error RELAYER_NOT_SET();

    /// @dev thrown if a role to be revoked is not assigned
    error ROLE_NOT_ASSIGNED();

    //////////////////////////////////////////////////////////////
    //                  AUTHORIZATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if functions cannot be called

    /// COMMON AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if caller is not address(this), internal call
    error INVALID_INTERNAL_CALL();

    /// @dev thrown if msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not an allowed broadcaster
    error NOT_ALLOWED_BROADCASTER();

    /// @dev thrown if msg.sender is not broadcast amb implementation
    error NOT_BROADCAST_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not broadcast state registry
    error NOT_BROADCAST_REGISTRY();

    /// @dev thrown if msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev thrown if msg.sender is not emergency queue
    error NOT_EMERGENCY_QUEUE();

    /// @dev thrown if msg.sender is not minter
    error NOT_MINTER();

    /// @dev thrown if msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY_ROLE();

    /// @dev thrown if msg.sender is not paymaster
    error NOT_PAYMASTER();

    /// @dev thrown if msg.sender is not payment admin
    error NOT_PAYMENT_ADMIN();

    /// @dev thrown if msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev thrown if msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if msg.sender is not superform router
    error NOT_SUPERFORM_ROUTER();

    /// @dev thrown if msg.sender is not a superform
    error NOT_SUPERFORM();

    /// @dev thrown if msg.sender is not superform factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if msg.sender is not timelock form
    error NOT_TIMELOCK_SUPERFORM();

    /// @dev thrown if msg.sender is not timelock state registry
    error NOT_TIMELOCK_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not user or disputer
    error NOT_VALID_DISPUTER();

    /// @dev thrown if the msg.sender is not privileged caller
    error NOT_PRIVILEGED_CALLER(bytes32 role);

    /// STATE REGISTRY AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev layerzero adapter specific error, thrown if caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev hyperlane adapter specific error, thrown if caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev wormhole relayer specific error, thrown if caller not wormhole relayer
    error CALLER_NOT_RELAYER();

    /// @dev thrown if src chain sender is not valid
    error INVALID_SRC_SENDER();

    //////////////////////////////////////////////////////////////
    //                  INPUT VALIDATION ERRORS                 //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if input variables are not valid

    /// COMMON INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if there is an array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @dev thrown if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev error thrown when msg value should be zero in certain payable functions
    error MSG_VALUE_NOT_ZERO();

    /// @dev thrown if amb ids length is 0
    error ZERO_AMB_ID_LENGTH();

    /// @dev thrown if address input is address 0
    error ZERO_ADDRESS();

    /// @dev thrown if amount input is 0
    error ZERO_AMOUNT();

    /// @dev thrown if final token is address 0
    error ZERO_FINAL_TOKEN();

    /// @dev thrown if value input is 0
    error ZERO_INPUT_VALUE();

    /// SUPERFORM ROUTER INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev thrown if receiver address is not set
    error RECEIVER_ADDRESS_NOT_SET();

    /// SUPERFORM FACTORY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev thrown if a form is not form interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev error thrown if form implementation address already exists
    error FORM_IMPLEMENTATION_ALREADY_EXISTS();

    /// @dev error thrown if form implementation id already exists
    error FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();

    /// @dev thrown if a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev thrown if form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev thrown if superform not on factory
    error SUPERFORM_ID_NONEXISTENT();

    /// @dev thrown if same vault and form implementation is used to create new superform
    error VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();

    /// FORM INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if in case of no txData, if liqData.token != vault.asset()
    /// in case of txData, if token output of swap != vault.asset()
    error DIFFERENT_TOKENS();

    /// @dev thrown if the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown if the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// LIQUIDITY BRIDGE INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if route id is blacklisted in socket
    error BLACKLISTED_ROUTE_ID();

    /// @dev thrown if route id is not blacklisted in socket
    error NOT_BLACKLISTED_ROUTE_ID();

    /// @dev error thrown when txData selector of lifi bridge is a blacklisted selector
    error BLACKLISTED_SELECTOR();

    /// @dev error thrown when txData selector of lifi bridge is not a blacklisted selector
    error NOT_BLACKLISTED_SELECTOR();

    /// @dev thrown if a certain action of the user is not allowed given the txData provided
    error INVALID_ACTION();

    /// @dev thrown if in deposits, the liqDstChainId doesn't match the stateReq dstChainId
    error INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

    /// @dev thrown if index is invalid
    error INVALID_INDEX();

    /// @dev thrown if the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown if the validation of bridge txData fails due to a destination call present
    error INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

    /// @dev thrown if the validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown if the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /// @dev thrown if txData is not present (in case of xChain actions)
    error NO_TXDATA_PRESENT();

    /// STATE REGISTRY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if payload is being updated with tx data length different than liq data length
    error DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();

    /// @dev thrown if keeper update final token is different than the vault underlying
    error INVALID_UPDATE_FINAL_TOKEN();

    /// @dev thrown if broadcast finality for wormhole is invalid
    error INVALID_BROADCAST_FINALITY();

    /// @dev thrown if amb id is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev thrown if chain id involved in xchain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev thrown if payload update amount isn't equal to dst swapper amount
    error INVALID_DST_SWAP_AMOUNT();

    /// @dev thrown if message amb and proof amb are the same
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if order of proof AMBs is incorrect, either duplicated or not incrementing
    error INVALID_PROOF_BRIDGE_IDS();

    /// @dev thrown if rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /// @dev thrown if delay is invalid
    error INVALID_TIMELOCK_DELAY();

    /// @dev thrown if amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if slippage is outside of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// SUPERPOSITION INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev thrown if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

    //////////////////////////////////////////////////////////////
    //                  EXECUTION ERRORS                        //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown due to function execution logic

    /// COMMON EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the swap in a direct deposit resulted in insufficient tokens
    error DIRECT_DEPOSIT_SWAP_FAILED();

    /// @dev thrown if payload is not unique
    error DUPLICATE_PAYLOAD();

    /// @dev thrown if native tokens fail to be sent to superform contracts
    error FAILED_TO_SEND_NATIVE();

    /// @dev thrown if allowance is not correct to deposit
    error INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();

    /// @dev thrown if contract has insufficient balance for operations
    error INSUFFICIENT_BALANCE();

    /// @dev thrown if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /// @dev thrown if payload cannot be decoded
    error INVALID_PAYLOAD();

    /// @dev thrown if payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /// @dev thrown if payload type is invalid
    error INVALID_PAYLOAD_TYPE();

    /// LIQUIDITY BRIDGE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if we try to decode the final swap output token in a xChain liquidity bridging action
    error CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();

    /// @dev thrown if liquidity bridge fails for erc20 or native tokens
    error FAILED_TO_EXECUTE_TXDATA(address token);

    /// @dev thrown if asset being used for deposit mismatches in multivault deposits
    error INVALID_DEPOSIT_TOKEN();

    /// STATE REGISTRY EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown if withdrawal tx data cannot be updated
    error CANNOT_UPDATE_WITHDRAW_TX_DATA();

    /// @dev thrown if rescue passed dispute deadline
    error DISPUTE_TIME_ELAPSED();

    /// @dev thrown if message failed to reach the specified level of quorum needed
    error INSUFFICIENT_QUORUM();

    /// @dev thrown if broadcast payload is invalid
    error INVALID_BROADCAST_PAYLOAD();

    /// @dev thrown if broadcast fee is invalid
    error INVALID_BROADCAST_FEE();

    /// @dev thrown if retry fees is less than required
    error INVALID_RETRY_FEE();

    /// @dev thrown if broadcast message type is wrong
    error INVALID_MESSAGE_TYPE();

    /// @dev thrown if payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if a state registry id is 0
    error INVALID_REGISTRY_ID();

    /// @dev thrown if a form state registry id is 0
    error INVALID_FORM_REGISTRY_ID();

    /// @dev thrown if trying to finalize the payload but the withdraw is still locked
    error LOCKED();

    /// @dev thrown if payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev thrown if payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if rescue is still in timelocked state
    error RESCUE_LOCKED();

    /// @dev thrown if rescue is already proposed
    error RESCUE_ALREADY_PROPOSED();

    /// @dev thrown if payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// DST SWAPPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if process dst swap is tried for processed payload id
    error DST_SWAP_ALREADY_PROCESSED();

    /// @dev thrown if indices have duplicates
    error DUPLICATE_INDEX();

    /// @dev thrown if failed dst swap is already updated
    error FAILED_DST_SWAP_ALREADY_UPDATED();

    /// @dev thrown if indices are out of bounds
    error INDEX_OUT_OF_BOUNDS();

    /// @dev thrown if failed swap token amount is 0
    error INVALID_DST_SWAPPER_FAILED_SWAP();

    /// @dev thrown if failed swap token amount is not 0 and if token balance is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE();

    /// @dev thrown if failed swap token amount is not 0 and if native amount is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE();

    /// @dev forbid xChain deposits with destination swaps without interim token set (for user protection)
    error INVALID_INTERIM_TOKEN();

    /// @dev thrown if dst swap output is less than minimum expected
    error INVALID_SWAP_OUTPUT();

    /// FORM EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if try to forward 4626 share from the superform
    error CANNOT_FORWARD_4646_TOKEN();

    /// @dev thrown in KYCDAO form if no KYC token is present
    error NO_VALID_KYC_TOKEN();

    /// @dev thrown in forms where a certain functionality is not allowed or implemented
    error NOT_IMPLEMENTED();

    /// @dev thrown if form implementation is PAUSED, users cannot perform any action
    error PAUSED();

    /// @dev thrown if shares != deposit output or assets != redeem output when minting SuperPositions
    error VAULT_IMPLEMENTATION_FAILED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TOKEN_NOT_UPDATED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TX_DATA_NOT_UPDATED();

    /// @dev thrown when redeeming from vault yields zero collateral
    error WITHDRAW_ZERO_COLLATERAL();

    /// PAYMENT HELPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if chainlink is reporting an improper price
    error CHAINLINK_MALFUNCTION();

    /// @dev thrown if chainlink is reporting an incomplete round
    error CHAINLINK_INCOMPLETE_ROUND();

    /// @dev thrown if feed decimals is not 8
    error CHAINLINK_UNSUPPORTED_DECIMAL();

    /// EMERGENCY QUEUE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if emergency withdraw is not queued
    error EMERGENCY_WITHDRAW_NOT_QUEUED();

    /// @dev thrown if emergency withdraw is already processed
    error EMERGENCY_WITHDRAW_PROCESSED_ALREADY();

    /// SUPERPOSITION EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if uri cannot be updated
    error DYNAMIC_URI_FROZEN();

    /// @dev thrown if tx history is not found while state sync
    error TX_HISTORY_NOT_FOUND();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @dev contains all the common struct and enums used for data communication between chains.

/// @dev There are two transaction types in Superform Protocol
enum TransactionType {
    DEPOSIT,
    WITHDRAW
}

/// @dev Message types can be INIT, RETURN (for successful Deposits) and FAIL (for failed withdraws)
enum CallbackType {
    INIT,
    RETURN,
    FAIL
}

/// @dev Payloads are stored, updated (deposits) or processed (finalized)
enum PayloadState {
    STORED,
    UPDATED,
    PROCESSED
}

/// @dev contains all the common struct used for interchain token transfers.
struct LiqRequest {
    /// @dev generated data
    bytes txData;
    /// @dev input token for deposits, desired output token on target liqDstChainId for withdraws. Must be set for
    /// txData to be updated on destination for withdraws
    address token;
    /// @dev intermediary token on destination. Relevant for xChain deposits where a destination swap is needed for
    /// validation purposes
    address interimToken;
    /// @dev what bridge to use to move tokens
    uint8 bridgeId;
    /// @dev dstChainId = liqDstchainId for deposits. For withdraws it is the target chain id for where the underlying
    /// is to be delivered
    uint64 liqDstChainId;
    /// @dev currently this amount is used as msg.value in the txData call.
    uint256 nativeAmount;
}

/// @dev main struct that holds required multi vault data for an action
struct MultiVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256[] superformIds;
    uint256[] amounts; // on deposits, amount of token to deposit on dst, on withdrawals, superpositions to burn
    uint256[] outputAmounts; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256[] maxSlippages;
    LiqRequest[] liqRequests; // if length = 1; amount = sum(amounts) | else  amounts must match the amounts being sent
    bytes permit2data;
    bool[] hasDstSwaps;
    bool[] retain4626s; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev main struct that holds required single vault data for an action
struct SingleVaultSFData {
    // superformids must have same destination. Can have different underlyings
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount; // on deposits, amount of shares to receive, on withdrawals, amount of assets to receive
    uint256 maxSlippage;
    LiqRequest liqRequest; // if length = 1; amount = sum(amounts)| else  amounts must match the amounts being sent
    bytes permit2data;
    bool hasDstSwap;
    bool retain4626; // if true, we don't mint SuperPositions, and send the 4626 back to the user instead
    address receiverAddress;
    /// this address must always be an EOA otherwise funds may be lost
    address receiverAddressSP;
    /// this address can be a EOA or a contract that implements onERC1155Receiver. must always be set for deposits
    bytes extraFormData; // extraFormData
}

/// @dev overarching struct for multiDst requests with multi vaults
struct MultiDstMultiVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    MultiVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with multi vaults
struct SingleXChainMultiVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    MultiVaultSFData superformsData;
}

/// @dev overarching struct for multiDst requests with single vaults
struct MultiDstSingleVaultStateReq {
    uint8[][] ambIds;
    uint64[] dstChainIds;
    SingleVaultSFData[] superformsData;
}

/// @dev overarching struct for single cross chain requests with single vaults
struct SingleXChainSingleVaultStateReq {
    uint8[] ambIds;
    uint64 dstChainId;
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with single vaults
struct SingleDirectSingleVaultStateReq {
    SingleVaultSFData superformData;
}

/// @dev overarching struct for single direct chain requests with multi vaults
struct SingleDirectMultiVaultStateReq {
    MultiVaultSFData superformData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
/// @dev realize that receiverAddressSP is not passed, only needed on source chain to mint
struct InitMultiVaultData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
    uint256[] outputAmounts;
    uint256[] maxSlippages;
    LiqRequest[] liqData;
    bool[] hasDstSwaps;
    bool[] retain4626s;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for SuperRouter with re-arranged data for the message (contains the payloadId)
struct InitSingleVaultData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
    uint256 outputAmount;
    uint256 maxSlippage;
    LiqRequest liqData;
    bool hasDstSwap;
    bool retain4626;
    address receiverAddress;
    bytes extraFormData;
}

/// @dev struct for Emergency Queue
struct QueuedWithdrawal {
    address receiverAddress;
    uint256 superformId;
    uint256 amount;
    uint256 srcPayloadId;
    bool isProcessed;
}

/// @dev all statuses of the timelock payload
enum TimelockStatus {
    UNAVAILABLE,
    PENDING,
    PROCESSED
}

/// @dev holds information about the timelock payload
struct TimelockPayload {
    uint8 isXChain;
    uint64 srcChainId;
    uint256 lockedTill;
    InitSingleVaultData data;
    TimelockStatus status;
}

/// @dev struct that contains the type of transaction, callback flags and other identification, as well as the vaults
/// data in params
struct AMBMessage {
    uint256 txInfo; // tight packing of  TransactionType txType,  CallbackType flag  if multi/single vault, registry id,
        // srcSender and srcChainId
    bytes params; // decoding txInfo will point to the right datatype of params. Refer PayloadHelper.sol
}

/// @dev struct that contains the information required for broadcasting changes
struct BroadcastMessage {
    bytes target;
    bytes32 messageType;
    bytes message;
}

/// @dev struct that contains info on returned data from destination
struct ReturnMultiData {
    uint256 payloadId;
    uint256[] superformIds;
    uint256[] amounts;
}

/// @dev struct that contains info on returned data from destination
struct ReturnSingleData {
    uint256 payloadId;
    uint256 superformId;
    uint256 amount;
}

/// @dev struct that contains the data on the fees to pay to the AMBs
struct AMBExtraData {
    uint256[] gasPerAMB;
    bytes[] extraDataPerAMB;
}

/// @dev struct that contains the data on the fees to pay to the AMBs on broadcasts
struct BroadCastAMBExtraData {
    uint256[] gasPerDst;
    bytes[] extraDataPerDst;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/// @dev imported from
/// https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/v3/solidity/contracts/interfaces/hooks/IPostDispatchHook.sol
interface IPostDispatchHook {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        MERKLE_TREE,
        INTERCHAIN_GAS_PAYMASTER,
        FALLBACK_ROUTING,
        ID_AUTH_ISM,
        PAUSABLE,
        PROTOCOL_FEE
    }

    /**
     * @notice Returns an enum that represents the type of hook
     */
    function hookType() external view returns (uint8);

    /**
     * @notice Returns whether the hook supports metadata
     * @param metadata metadata
     * @return Whether the hook supports metadata
     */
    function supportsMetadata(bytes calldata metadata) external view returns (bool);

    /**
     * @notice Post action after a message is dispatched via the Mailbox
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     */
    function postDispatch(bytes calldata metadata, bytes calldata message) external payable;

    /**
     * @notice Compute the payment required by the postDispatch call
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     * @return Quoted payment for the postDispatch call
     */
    function quoteDispatch(bytes calldata metadata, bytes calldata message) external view returns (uint256);
}

/// @dev imported from
/// https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/v3/solidity/contracts/interfaces/IInterchainSecurityModule.sol
interface IInterchainSecurityModule {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        LEGACY_MULTISIG,
        MERKLE_ROOT_MULTISIG,
        MESSAGE_ID_MULTISIG,
        NULL, // used with relayer carrying no metadata
        CCIP_READ
    }

    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message) external returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule() external view returns (IInterchainSecurityModule);
}

/// @dev imported from
/// https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/v3/solidity/contracts/interfaces/IMailbox.sol
interface IMailbox {
    // ============ Events ============
    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param sender The address that dispatched the message
     * @param destination The destination domain of the message
     * @param recipient The message recipient address on `destination`
     * @param message Raw bytes of message
     */
    event Dispatch(address indexed sender, uint32 indexed destination, bytes32 indexed recipient, bytes message);

    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param messageId The unique message identifier
     */
    event DispatchId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is processed
     * @param messageId The unique message identifier
     */
    event ProcessId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is delivered
     * @param origin The origin domain of the message
     * @param sender The message sender address on `origin`
     * @param recipient The address that handled the message
     */
    event Process(uint32 indexed origin, bytes32 indexed sender, address indexed recipient);

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function defaultIsm() external view returns (IInterchainSecurityModule);

    function defaultHook() external view returns (IPostDispatchHook);

    function latestDispatchedId() external view returns (bytes32);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    )
        external
        payable
        returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    )
        external
        view
        returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata defaultHookMetadata
    )
        external
        payable
        returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata defaultHookMetadata
    )
        external
        view
        returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    )
        external
        payable
        returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    )
        external
        view
        returns (uint256 fee);

    function process(bytes calldata metadata, bytes calldata message) external payable;

    function recipientIsm(address recipient) external view returns (IInterchainSecurityModule module);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/// @dev is imported from
/// (https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IMessageRecipient.sol)
interface IMessageRecipient {
    /// @param _origin Domain ID of the chain from which the message came
    /// @param _sender Address of the message sender on the origin chain as bytes32
    /// @param _message Raw bytes content of message body
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/// @dev is imported from
/// (https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IInterchainGasPaymaster.sol)
interface IInterchainGasPaymaster {
    /// @notice Emitted when a payment is made for a message's gas costs.
    /// @param messageId The ID of the message to pay for.
    /// @param gasAmount The amount of destination gas paid for.
    /// @param payment The amount of native tokens paid.
    event GasPayment(bytes32 indexed messageId, uint256 gasAmount, uint256 payment);

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    )
        external
        payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

/// @dev is imported from
/// (https://v3.hyperlane.xyz/docs/reference/libraries/hookmetadata)
library StandardHookMetadata {
    uint8 private constant VARIANT_OFFSET = 0;
    uint8 private constant MSG_VALUE_OFFSET = 2;
    uint8 private constant GAS_LIMIT_OFFSET = 34;
    uint8 private constant REFUND_ADDRESS_OFFSET = 66;
    uint256 private constant MIN_METADATA_LENGTH = 86;

    uint16 public constant VARIANT = 1;

    /**
     * @notice Returns the variant of the metadata.
     * @param _metadata ABI encoded global hook metadata.
     * @return variant of the metadata as uint8.
     */
    function variant(bytes calldata _metadata) internal pure returns (uint16) {
        if (_metadata.length < VARIANT_OFFSET + 2) return 0;
        return uint16(bytes2(_metadata[VARIANT_OFFSET:VARIANT_OFFSET + 2]));
    }

    /**
     * @notice Returns the specified value for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback value.
     * @return Value for the message as uint256.
     */
    function msgValue(bytes calldata _metadata, uint256 _default) internal pure returns (uint256) {
        if (_metadata.length < MSG_VALUE_OFFSET + 32) return _default;
        return uint256(bytes32(_metadata[MSG_VALUE_OFFSET:MSG_VALUE_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified gas limit for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback gas limit.
     * @return Gas limit for the message as uint256.
     */
    function gasLimit(bytes calldata _metadata, uint256 _default) internal pure returns (uint256) {
        if (_metadata.length < GAS_LIMIT_OFFSET + 32) return _default;
        return uint256(bytes32(_metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified refund address for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback refund address.
     * @return Refund address for the message as address.
     */
    function refundAddress(bytes calldata _metadata, address _default) internal pure returns (address) {
        if (_metadata.length < REFUND_ADDRESS_OFFSET + 20) return _default;
        return address(bytes20(_metadata[REFUND_ADDRESS_OFFSET:REFUND_ADDRESS_OFFSET + 20]));
    }

    /**
     * @notice Returns the specified refund address for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @return Refund address for the message as address.
     */
    function getCustomMetadata(bytes calldata _metadata) internal pure returns (bytes calldata) {
        if (_metadata.length < MIN_METADATA_LENGTH) return _metadata[0:0];
        return _metadata[MIN_METADATA_LENGTH:];
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _msgValue msg.value for the message.
     * @param _gasLimit Gas limit for the message.
     * @param _refundAddress Refund address for the message.
     * @param _customMetadata Additional metadata to include in the global hook metadata.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(
        uint256 _msgValue,
        uint256 _gasLimit,
        address _refundAddress,
        bytes memory _customMetadata
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(VARIANT, _msgValue, _gasLimit, _refundAddress, _customMetadata);
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _msgValue msg.value for the message.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(uint256 _msgValue) internal view returns (bytes memory) {
        return formatMetadata(_msgValue, uint256(0), msg.sender, "");
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _gasLimit Gas limit for the message.
     * @param _refundAddress Refund address for the message.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(uint256 _gasLimit, address _refundAddress) internal pure returns (bytes memory) {
        return formatMetadata(uint256(0), _gasLimit, _refundAddress, "");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}