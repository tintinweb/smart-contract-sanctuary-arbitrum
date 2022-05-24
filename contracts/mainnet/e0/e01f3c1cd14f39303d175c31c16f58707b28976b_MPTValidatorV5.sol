// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IValidationLibraryHelper.sol";
import "./LayerZeroPacket.sol";
import "./PacketDecoder.sol";
import "./UltraLightNodeEVMDecoder.sol";

interface IUltraLightNode {
    struct BlockData {
        uint confirmations;
        bytes32 data;
    }

    struct ApplicationConfiguration {
        uint16 inboundProofLibraryVersion;
        uint64 inboundBlockConfirmations;
        address relayer;
        uint16 outboundProofType;
        uint64 outboundBlockConfirmations;
        address oracle;
    }

    function getAppConfig(uint16 _chainId, address userApplicationAddress) external view returns (ApplicationConfiguration memory);
    function getBlockHeaderData(address _oracle, uint16 _remoteChainId, bytes32 _lookupHash) external view returns (BlockData memory blockData);
}

interface IStargate {
    // Stargate objects for abi encoding / decoding
    struct SwapObj {
        uint256 amount;
        uint256 eqFee;
        uint256 eqReward;
        uint256 lpFee;
        uint256 protocolFee;
        uint256 lkbRemove;
    }

    struct CreditObj {
        uint256 credits;
        uint256 idealBalance;
    }
}

contract MPTValidatorV5 is ILayerZeroValidationLibrary, IValidationLibraryHelper {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;
    using PacketDecoder for bytes;

    uint8 public utilsVersion = 3;
    bytes32 public constant PACKET_SIGNATURE = 0xe8d23d927749ec8e512eb885679c2977d57068839d8cca1a85685dbbea0648f6;

    address immutable public stargateBridgeAddress;
    address immutable public stgTokenAddress;
    address immutable public relayerAddress;
    uint16 immutable public localChainId;
    IUltraLightNode immutable public uln;

    constructor (address _stargateBridgeAddress, address _stgTokenAddress, uint16 _localChainId, address _ulnAddress, address _relayerAddress) {
        stargateBridgeAddress = _stargateBridgeAddress;
        stgTokenAddress = _stgTokenAddress;
        localChainId = _localChainId;
        uln = IUltraLightNode(_ulnAddress);
        relayerAddress = _relayerAddress;
    }

    function validateProof(bytes32 _receiptsRoot, bytes calldata _transactionProof, uint _remoteAddressSize) external view override returns (LayerZeroPacket.Packet memory) {
        require(_remoteAddressSize > 0, "ProofLib: invalid address size");

        (uint16 remoteChainId, bytes32 blockHash, bytes[] memory proof, uint[] memory receiptSlotIndex, uint logIndex) = abi.decode(_transactionProof, (uint16, bytes32, bytes[], uint[], uint));

        ULNLog memory log = _getVerifiedLog(_receiptsRoot, receiptSlotIndex, logIndex, proof);
        require(log.topicZeroSig == PACKET_SIGNATURE, "ProofLib: packet not recognized"); //data

        LayerZeroPacket.Packet memory packet = log.data.getPacket(remoteChainId, _remoteAddressSize, log.contractAddress);

        _assertMessagePath(packet, blockHash, _receiptsRoot);

        if (packet.dstAddress == stargateBridgeAddress) packet.payload = _secureStgPayload(packet.payload);

        if (packet.dstAddress == stgTokenAddress) packet.payload = _secureStgTokenPayload(packet.payload);

        return packet;
    }

    function _assertMessagePath(LayerZeroPacket.Packet memory packet, bytes32 blockHash, bytes32 receiptsRoot) internal view {
        require(packet.dstChainId == localChainId, "ProofLib: invalid destination chain ID");

        IUltraLightNode.ApplicationConfiguration memory appConfig = uln.getAppConfig(packet.srcChainId, packet.dstAddress);
        IUltraLightNode.BlockData memory blockData = uln.getBlockHeaderData(appConfig.oracle, packet.srcChainId, blockHash);
        require(appConfig.relayer == relayerAddress, "ProofLib: invalid relayer");

        require(blockData.data == receiptsRoot, "ProofLib: invalid receipt root");

        require(blockData.confirmations >= appConfig.inboundBlockConfirmations, "ProofLib: not enough block confirmations");
    }

    function _secureStgTokenPayload(bytes memory _payload) internal pure returns (bytes memory) {
        (bytes memory toAddressBytes, uint256 qty) = abi.decode(_payload, (bytes, uint256));

        address toAddress = address(0);
        if (toAddressBytes.length > 0) {
            assembly { toAddress := mload(add(toAddressBytes, 20))}
        }

        if (toAddress == address(0)) {
            address deadAddress = address(0x000000000000000000000000000000000000dEaD);
            bytes memory newToAddressBytes = abi.encodePacked(deadAddress);
            return abi.encode(newToAddressBytes, qty);
        }

        // default to return the original payload
        return _payload;
    }

    function _secureStgPayload(bytes memory _payload) internal view returns (bytes memory) {
        // functionType is uint8 even though the encoding will take up the side of uint256
        uint8 functionType;
        assembly { functionType := mload(add(_payload, 32)) }

        // TYPE_SWAP_REMOTE == 1 && only if the payload has a payload
        // only swapRemote inside of stargate can call sgReceive on an user supplied to address
        // thus we do not care about the other type functions even if the toAddress is overly long.
        if (functionType == 1) {
            // decode the _payload with its types
            (
                ,
                uint256 srcPoolId,
                uint256 dstPoolId,
                uint256 dstGasForCall,
                IStargate.CreditObj memory c,
                IStargate.SwapObj memory s,
                bytes memory toAddressBytes,
                bytes memory contractCallPayload
            ) = abi.decode(_payload, (uint8, uint256, uint256, uint256, IStargate.CreditObj, IStargate.SwapObj, bytes, bytes));

            // if contractCallPayload.length > 0 need to check if the to address is a contract or not
            if (contractCallPayload.length > 0) {
                // otherwise, need to check if the payload can be delivered to the toAddress
                address toAddress = address(0);
                if (toAddressBytes.length > 0) {
                    assembly { toAddress := mload(add(toAddressBytes, 20)) }
                }

                // check if the toAddress is a contract. We are not concerned about addresses that pretend to be wallets. because worst case we just delete their payload if being malicious
                // we can guarantee that if a size > 0, then the contract is definitely a contract address in this context
                uint size;
                assembly { size := extcodesize(toAddress) }

                if (size == 0) {
                    // size == 0 indicates its not a contract, payload wont be delivered
                    // secure the _payload to make sure funds can be delivered to the toAddress
                    bytes memory newToAddressBytes = abi.encodePacked(toAddress);
                    bytes memory securePayload = abi.encode(functionType, srcPoolId, dstPoolId, dstGasForCall, c, s, newToAddressBytes, bytes(""));
                    return securePayload;
                }
            }
        }

        // default to return the original payload
        return _payload;
    }

    function secureStgTokenPayload(bytes memory _payload) external pure returns(bytes memory) {
        return _secureStgTokenPayload(_payload);
    }

    function secureStgPayload(bytes memory _payload) external view returns(bytes memory) {
        return _secureStgPayload(_payload);
    }

    function _getVerifiedLog(bytes32 hashRoot, uint[] memory paths, uint logIndex, bytes[] memory proof) internal pure returns(ULNLog memory) {
        require(paths.length == proof.length, "ProofLib: invalid proof size");
        require(proof.length >0, "ProofLib: proof size must > 0");
        RLPDecode.RLPItem memory item;
        bytes memory proofBytes;

        for (uint i = 0; i < proof.length; i++) {
            proofBytes = proof[i];
            require(hashRoot == keccak256(proofBytes), "ProofLib: invalid hashlink");
            item = RLPDecode.toRlpItem(proofBytes).safeGetItemByIndex(paths[i]);
            if (i < proof.length - 1) hashRoot = bytes32(item.toUint());
        }

        // burning status + gasUsed + logBloom
        RLPDecode.RLPItem memory logItem = item.typeOffset().safeGetItemByIndex(3);
        RLPDecode.Iterator memory it =  logItem.safeGetItemByIndex(logIndex).iterator();
        ULNLog memory log;
        log.contractAddress = bytes32(it.next().toUint());
        log.topicZeroSig = bytes32(it.next().safeGetItemByIndex(0).toUint());
        log.data = it.next().toBytes();

        return log;
    }

    function getUtilsVersion() external override view returns(uint8) {
        return utilsVersion;
    }

    function getVerifyLog(bytes32 hashRoot, uint[] memory receiptSlotIndex, uint logIndex, bytes[] memory proof) external override pure returns(ULNLog memory){
        return _getVerifiedLog(hashRoot, receiptSlotIndex, logIndex, proof);
    }

    function getPacket(bytes memory data, uint16 srcChain, uint sizeOfSrcAddress, bytes32 ulnAddress) external override pure returns(LayerZeroPacket.Packet memory){
        return data.getPacket(srcChain, sizeOfSrcAddress, ulnAddress);
    }

    // profiling and test
    function assertMessagePath(LayerZeroPacket.Packet memory packet, bytes32 blockHash, bytes32 receiptsRoot) external view {
        _assertMessagePath(packet, blockHash, receiptsRoot);
    }
}