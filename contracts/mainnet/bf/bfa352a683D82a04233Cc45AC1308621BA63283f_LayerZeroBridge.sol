pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroUserApplicationConfig.sol";
import "./LayerZeroStorage.sol";
import "../zksync/ReentrancyGuard.sol";

/// @title LayerZero bridge implementation of non-blocking model
/// @dev if message is blocking we should call `retryPayload` of endpoint to retry
/// the reasons for message blocking may be:
/// * `_dstAddress` is not deployed to dst chain, and we can deploy LayerZeroBridge to dst chain to fix it.
/// * lzReceive cost more gas than `_gasLimit` that endpoint send, and user should call `retryMessage` to fix it.
/// * lzReceive reverted unexpected, and we can fix bug and deploy a new contract to fix it.
/// @author zk.link
contract LayerZeroBridge is ReentrancyGuard, LayerZeroStorage, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {

    // to avoid stack too deep
    struct LzBridgeParams {
        uint16 dstChainId; // the destination chainId
        address payable refundAddress; // native fees refund address if msg.value is too large
        address zroPaymentAddress; // if not zero user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
        bytes adapterParams; // see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    }

    modifier onlyEndpoint {
        require(msg.sender == address(endpoint), "Require endpoint");
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "Caller is not governor");
        _;
    }

    receive() external payable {
        // receive the refund eth from layerzero endpoint when send msg
    }

    /// @param _governor The network governor of zkLink protocol
    /// @param _zklink The zklink contract address
    /// @param _endpoint The LayerZero endpoint
    constructor(address _governor, IZkLink _zklink, ILayerZeroEndpoint _endpoint) {
        initializeReentrancyGuard();

        networkGovernor = _governor;
        zklink = _zklink;
        endpoint = _endpoint;
    }

    //---------------------------UserApplication config----------------------------------------
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyGovernor {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyGovernor {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyGovernor {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyGovernor {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /// @notice Set bridge destination
    /// @param dstChainId LayerZero chain id on other chains
    /// @param contractAddr LayerZeroBridge contract address on other chains
    function setDestination(uint16 dstChainId, bytes calldata contractAddr) external onlyGovernor {
        require(dstChainId != endpoint.getChainId(), "Invalid dstChainId");
        destinations[dstChainId] = contractAddr;
        emit UpdateDestination(dstChainId, contractAddr);
    }

    /// @notice Estimate bridge ZkLink Block fees
    /// @param lzChainId the destination chainId
    /// @param syncHash the sync hash of stored block
    /// @param progress the sync progress
    /// @param useZro if true user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
    /// @param adapterParams see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    function estimateZkLinkBlockBridgeFees(
        uint16 lzChainId,
        bytes32 syncHash,
        uint256 progress,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint nativeFee, uint zroFee) {
        bytes memory payload = buildZkLinkBlockBridgePayload(syncHash, progress);
        return endpoint.estimateFees(lzChainId, address(this), payload, useZro, adapterParams);
    }

    /// @notice Bridge ZkLink block to other chain
    /// @param storedBlockInfo the block proved but not executed at the current chain
    /// @param dstChainIds dst chains to bridge, empty array will be reverted
    /// @param refundAddress native fees refund address if msg.value is too large
    /// @param zroPaymentAddress if not zero user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
    /// @param adapterParams see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    function bridgeZkLinkBlock(
        IZkLink.StoredBlockInfo calldata storedBlockInfo,
        uint16[] memory dstChainIds,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) external nonReentrant payable {
        // ===Checks===
        require(dstChainIds.length > 0, "No dst chain");

        // ===Interactions===
        bytes32 syncHash = storedBlockInfo.syncHash;
        uint256 progress = zklink.getSynchronizedProgress(storedBlockInfo);

        uint256 originBalance = address(this).balance - msg.value; // underflow is impossible
        // before the last send, we send all balance of this contract and set refund address to this contract
        for (uint i = 0; i < dstChainIds.length - 1; ++i) { // overflow is impossible
            _bridgeZkLinkBlockProgress(syncHash, progress, dstChainIds[i], payable(address(this)), zroPaymentAddress, adapterParams, address(this).balance);
        }
        // for the last send, we send all left value exclude the origin balance of this contract and set refund address to `refundAddress`
        require(address(this).balance > originBalance, "Msg value is not enough for the last send");
        uint256 leftMsgValue = address(this).balance - originBalance; // underflow is impossible
        _bridgeZkLinkBlockProgress(syncHash, progress, dstChainIds[dstChainIds.length - 1], refundAddress, zroPaymentAddress, adapterParams, leftMsgValue);
    }

    function _bridgeZkLinkBlockProgress(
        bytes32 syncHash,
        uint256 progress,
        uint16 dstChainId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams,
        uint256 bridgeFee
    ) internal {
        // ===Checks===
        bytes memory trustedRemote = checkDstChainId(dstChainId);

        // endpoint will check `refundAddress`, `zroPaymentAddress` and `adapterParams`

        // ===Effects===
        uint64 nonce = endpoint.getOutboundNonce(dstChainId, address(this));
        emit SendSynchronizationProgress(dstChainId, nonce + 1, syncHash, progress);

        // ===Interactions===
        // send LayerZero message
        bytes memory path = abi.encodePacked(trustedRemote, address(this));
        bytes memory payload = buildZkLinkBlockBridgePayload(syncHash, progress);
        // solhint-disable-next-line check-send-result
        endpoint.send{value:bridgeFee}(dstChainId, path, payload, refundAddress, zroPaymentAddress, adapterParams);
    }

    /// @notice Receive the bytes payload from the source chain via LayerZero
    /// @dev lzReceive can only be called by endpoint
    /// @dev srcPath(in UltraLightNodeV2) = abi.encodePacked(srcAddress, dstAddress);
    function lzReceive(uint16 srcChainId, bytes calldata srcPath, uint64 nonce, bytes calldata payload) external override onlyEndpoint nonReentrant {
        // reject invalid src contract address
        bytes memory srcAddress = destinations[srcChainId];
        bytes memory path = abi.encodePacked(srcAddress, address(this));
        require(keccak256(path) == keccak256(srcPath), "Invalid src");

        // try-catch all errors/exceptions
        // solhint-disable-next-line no-empty-blocks
        try this.nonblockingLzReceive(srcChainId, srcAddress, nonce, payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[srcChainId][srcAddress][nonce] = keccak256(payload);
            emit MessageFailed(srcChainId, srcAddress, nonce, payload);
        }
    }

    function nonblockingLzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) public {
        // only internal transaction
        require(msg.sender == address(this), "Caller must be this bridge");
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    /// @notice Retry the failed message, payload hash must be exist
    function retryMessage(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external payable virtual nonReentrant {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId][srcAddress][nonce];
        require(payloadHash != bytes32(0), "No stored message");
        require(keccak256(payload) == payloadHash, "Invalid payload");
        // clear the stored message
        failedMessages[srcChainId][srcAddress][nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    function _nonblockingLzReceive(uint16 srcChainId, bytes calldata /**srcAddress**/, uint64 nonce, bytes calldata payload) internal {
        // unpack payload
        (bytes32 syncHash, uint256 progress) = abi.decode(payload, (bytes32, uint256));
        emit ReceiveSynchronizationProgress(srcChainId, nonce, syncHash, progress);
        zklink.receiveSynchronizationProgress(syncHash, progress);
    }

    function checkDstChainId(uint16 dstChainId) internal view returns (bytes memory trustedRemote) {
        trustedRemote = destinations[dstChainId];
        require(trustedRemote.length > 0, "Trust remote not exist");
    }

    function buildZkLinkBlockBridgePayload(bytes32 syncHash, uint256 progress) internal pure returns (bytes memory payload) {
        payload = abi.encode(syncHash, progress);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ILayerZeroEndpoint.sol";
import "../interfaces/IZkLink.sol";

/// @title LayerZero bridge storage
/// @author zk.link
/// @dev Do not initialize any variables of this contract
/// Do not break the alignment of contract storage
contract LayerZeroStorage {
    /// @notice ZkLink network governor
    address public networkGovernor;
    /// @notice zklink contract address
    IZkLink public zklink;
    /// @notice LayerZero endpoint that used to send and receive message
    ILayerZeroEndpoint public endpoint;
    /// @notice bridge contract address on other chains
    mapping(uint16 => bytes) public destinations;
    /// @notice failed message of lz non-blocking model
    /// @dev the struct of failedMessages is (srcChainId => srcAddress => nonce => payloadHash)
    /// srcChainId is the id of message source chain
    /// srcAddress is the trust remote address on the source chain who send message
    /// nonce is inbound message nonce
    /// payLoadHash is the keccak256 of message payload
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event UpdateDestination(uint16 indexed lzChainId, bytes destination);
    event MessageFailed(uint16 indexed srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SendSynchronizationProgress(uint16 indexed dstChainId, uint64 nonce, bytes32 syncHash, uint progress);
    event ReceiveSynchronizationProgress(uint16 indexed srcChainId, uint64 nonce, bytes32 syncHash, uint progress);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title ZkLink interface contract
/// @author zk.link
interface IZkLink {
    // stored block info of ZkLink
    struct StoredBlockInfo {
        uint32 blockNumber;
        uint64 priorityOperations;
        bytes32 pendingOnchainOperationsHash;
        uint256 timestamp;
        bytes32 stateHash;
        bytes32 commitment;
        bytes32 syncHash;
    }

    /// @notice Get synchronized progress of zkLink contract known on deployed chain
    function getSynchronizedProgress(StoredBlockInfo memory block) external view returns (uint256 progress);

    /// @notice Combine the `progress` of the other chains of a `syncHash` with self
    function receiveSynchronizationProgress(bytes32 syncHash, uint256 progress) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of double initialization
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}