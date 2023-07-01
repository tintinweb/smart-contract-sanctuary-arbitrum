// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IDapp {
    function iReceive(
        string memory requestSender,
        bytes memory packet,
        string memory srcChainId
    ) external returns (bytes memory);

    function iAck(uint256 requestIdentifier, bool execFlags, bytes memory execData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function currentVersion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant CONSTANT_POWER_THRESHOLD = 2791728742;
}

// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.13;
import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";

contract TheRiotProtocolGeneral is IDapp {
    struct TransferSendRiotKeyParams {
        uint256 tokenId;
        address caller;
    }

    struct TransferReceiveRiotKeyParams {
        uint256 tokenId;
        address caller;
        bytes32 riotKey;
    }

    address private _owner;

    // Router Variables
    IGateway private gatewayContract;
    mapping(string => string) public ourContractOnChains;

    mapping(address => mapping(uint256 => bytes32)) private latestRiotKey;

    constructor(address gatewayAddress, string memory feePayerAddress) {
        _owner = msg.sender;
        gatewayContract = IGateway(gatewayAddress);
        gatewayContract.setDappMetadata(feePayerAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function.");
        _;
    }

    // Router Functions
    function setDappMetadata(string memory feePayerAddress) external onlyOwner {
        gatewayContract.setDappMetadata(feePayerAddress);
    }

    function setGateway(address gateway) external onlyOwner {
        gatewayContract = IGateway(gateway);
    }

    function setContractOnChain(string calldata chainId, string calldata contractAddress)
        external
        onlyOwner
    {
        ourContractOnChains[chainId] = contractAddress;
    }

    function transferCrossChain(
        string calldata destChainId,
        TransferSendRiotKeyParams memory transferParams,
        bytes calldata requestMetadata
    ) public payable {
        require(
            keccak256(abi.encodePacked(ourContractOnChains[destChainId])) !=
                keccak256(abi.encodePacked("")),
            "contract on dest not set"
        );
        transferParams.caller = msg.sender;
        bytes memory packet = abi.encode(transferParams);
        bytes memory requestPacket = abi.encode(ourContractOnChains[destChainId], packet);

        gatewayContract.iSend{value: msg.value}(
            1,
            0,
            string(""),
            destChainId,
            requestMetadata,
            requestPacket
        );
    }

    function getLatestRiotKey(uint256 tokenId) public view returns (bytes32) {
        return latestRiotKey[msg.sender][tokenId];
    }

    function iReceive(
        string memory, // requestSender,
        bytes memory,
        string memory
    ) external override returns (bytes memory) {
        require(msg.sender == address(gatewayContract), "only gateway");
        // DO NOTHING
    }

    function getRequestMetadata(
        uint64 destGasLimit,
        uint64 destGasPrice,
        uint64 ackGasLimit,
        uint64 ackGasPrice,
        uint128 relayerFees,
        uint8 ackType,
        bool isReadCall,
        bytes memory asmAddress
    ) public pure returns (bytes memory) {
        bytes memory requestMetadata = abi.encodePacked(
            destGasLimit,
            destGasPrice,
            ackGasLimit,
            ackGasPrice,
            relayerFees,
            ackType,
            isReadCall,
            asmAddress
        );
        return requestMetadata;
    }

    function iAck(
        uint256,
        bool execFlag,
        bytes memory execData
    ) external override {
        require(msg.sender == address(gatewayContract), "only gateway");
        TransferReceiveRiotKeyParams memory receivedData = abi.decode(
            execData,
            (TransferReceiveRiotKeyParams)
        );
        if (execFlag) {
            latestRiotKey[receivedData.caller][receivedData.tokenId] = receivedData.riotKey;
        } else {
            latestRiotKey[receivedData.caller][receivedData.tokenId] = bytes32(0);
        }
    }
}