// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TransferKey} from "../libraries/LibTransferKey.sol";

enum DataTransferType {
    Wormhole,
    LayerZero
}

struct DataTransferInProtocol {
    uint16 networkId;
    DataTransferType dataTransferType;
    bytes payload;
}

struct DataTransferInArgs {
    DataTransferInProtocol protocol;
    TransferKey transferKey;
    bytes payload;
}

struct DataTransferOutArgs {
    DataTransferType dataTransferType;
    bytes payload;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibBytes} from "../libraries/LibBytes.sol";
import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibTransferKey, TransferKey} from "../libraries/LibTransferKey.sol";
import {LibLayerZero} from "./LibLayerZero.sol";
import {LibWormhole} from "./LibWormhole.sol";
import {DataTransferInArgs, DataTransferOutArgs, DataTransferType} from "./LibCommon.sol";

error InvalidDataTransferType();

library LibDataTransfer {
    using LibBytes for bytes;

    function getOriginalPayload(bytes memory extendedPayload) private pure returns (bytes memory) {
        return extendedPayload.slice(42, extendedPayload.length - 42);
    }

    function dataTransfer(DataTransferInArgs memory dataTransferInArgs) internal {
        bytes memory extendedPayload = LibTransferKey.encode(dataTransferInArgs.transferKey).concat(
            dataTransferInArgs.payload
        );

        if (dataTransferInArgs.protocol.dataTransferType == DataTransferType.Wormhole) {
            LibWormhole.dataTransfer(extendedPayload);
        } else if (dataTransferInArgs.protocol.dataTransferType == DataTransferType.LayerZero) {
            LibLayerZero.dataTransfer(extendedPayload, dataTransferInArgs.protocol);
        } else {
            revert InvalidDataTransferType();
        }
    }

    function getPayload(
        DataTransferOutArgs memory dataTransferOutArgs
    ) internal returns (TransferKey memory transferKey, bytes memory payload) {
        if (dataTransferOutArgs.dataTransferType == DataTransferType.Wormhole) {
            payload = LibWormhole.getPayload(dataTransferOutArgs.payload);
        } else if (dataTransferOutArgs.dataTransferType == DataTransferType.LayerZero) {
            payload = LibLayerZero.getPayload(dataTransferOutArgs.payload);
        } else {
            revert InvalidDataTransferType();
        }

        transferKey = LibTransferKey.decode(payload);
        payload = getOriginalPayload(payload);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILayerZero} from "../interfaces/layer-zero/ILayerZero.sol";
import {AppStorage, LayerZeroSettings, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";
import {LibTransferKey, TransferKey} from "../libraries/LibTransferKey.sol";
import {DataTransferInProtocol, DataTransferType} from "./LibCommon.sol";

struct LayerZeroDataTransferInData {
    uint256 gasLimit;
    uint256 fee;
}

error LayerZeroInvalidPayload();
error LayerZeroInvalidSender();
error LayerZeroSequenceHasPayload();

library LibLayerZero {
    event UpdateLayerZeroSettings(address indexed sender, LayerZeroSettings layerZeroSettings);

    function updateSettings(LayerZeroSettings memory layerZeroSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.layerZeroSettings = layerZeroSettings;

        emit UpdateLayerZeroSettings(msg.sender, layerZeroSettings);
    }

    event AddLayerZeroChainIds(address indexed sender, uint16[] networkIds, uint16[] chainIds);

    function addLayerZeroChainIds(uint16[] memory networkIds, uint16[] memory chainIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = networkIds.length;
        for (i = 0; i < l; ) {
            s.layerZeroChainIds[networkIds[i]] = chainIds[i];

            unchecked {
                i++;
            }
        }

        emit AddLayerZeroChainIds(msg.sender, networkIds, chainIds);
    }

    event AddLayerZeroNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addLayerZeroNetworkIds(uint16[] memory chainIds, uint16[] memory networkIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = chainIds.length;
        for (i = 0; i < l; ) {
            s.layerZeroNetworkIds[chainIds[i]] = networkIds[i];

            unchecked {
                i++;
            }
        }

        emit AddLayerZeroNetworkIds(msg.sender, chainIds, networkIds);
    }

    function decodeDataTransferInPayload(
        bytes memory dataTransferInPayload
    ) internal pure returns (LayerZeroDataTransferInData memory dataTransferInData) {
        assembly {
            mstore(dataTransferInData, mload(add(dataTransferInPayload, 32)))
            mstore(add(dataTransferInData, 32), mload(add(dataTransferInPayload, 64)))
        }
    }

    function encodeRemoteAndLocalAddresses(
        bytes32 remoteAddress,
        bytes32 localAddress
    ) private pure returns (bytes memory encodedRemoteAndLocalAddresses) {
        encodedRemoteAndLocalAddresses = new bytes(40);

        assembly {
            mstore(add(encodedRemoteAndLocalAddresses, 32), shl(96, remoteAddress))
            mstore(add(encodedRemoteAndLocalAddresses, 52), shl(96, localAddress))
        }
    }

    function dataTransfer(bytes memory payload, DataTransferInProtocol memory protocol) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        LayerZeroDataTransferInData memory dataTransferInData = decodeDataTransferInPayload(protocol.payload);

        bytes memory adapterParams = hex"00010000000000000000000000000000000000000000000000000000000000000000";

        assembly {
            mstore(add(adapterParams, 34), mload(dataTransferInData))
        }

        ILayerZero(s.layerZeroSettings.routerAddress).send{value: dataTransferInData.fee}(
            s.layerZeroChainIds[protocol.networkId],
            encodeRemoteAndLocalAddresses(
                s.magpieAggregatorAddresses[protocol.networkId],
                bytes32(uint256(uint160(address(this))))
            ),
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams
        );
    }

    function getPayload(bytes memory dataTransferOutPayload) internal returns (bytes memory extendedPayload) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        TransferKey memory transferKey = LibTransferKey.decode(dataTransferOutPayload);
        bytes memory srcAddress = encodeRemoteAndLocalAddresses(
            bytes32(uint256(uint160(address(this)))),
            s.magpieAggregatorAddresses[transferKey.networkId]
        );

        ILayerZero layerZero = ILayerZero(s.layerZeroSettings.routerAddress);

        if (layerZero.hasStoredPayload(s.layerZeroChainIds[transferKey.networkId], srcAddress)) {
            layerZero.retryPayload(s.layerZeroChainIds[transferKey.networkId], srcAddress, dataTransferOutPayload);
        }

        if (
            s.payloadHashes[uint16(DataTransferType.LayerZero)][transferKey.networkId][transferKey.senderAddress][
                transferKey.swapSequence
            ] == keccak256(dataTransferOutPayload)
        ) {
            extendedPayload = dataTransferOutPayload;
        } else {
            // Fallback
            extendedPayload = s.payloads[uint16(DataTransferType.LayerZero)][transferKey.networkId][
                transferKey.senderAddress
            ][transferKey.swapSequence];

            if (extendedPayload.length == 0) {
                revert LayerZeroInvalidPayload();
            }
        }
    }

    function registerPayload(TransferKey memory transferKey, bytes memory extendedPayload) private {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (
            s.payloadHashes[uint16(DataTransferType.LayerZero)][transferKey.networkId][transferKey.senderAddress][
                transferKey.swapSequence
            ] != bytes32(0)
        ) {
            revert LayerZeroSequenceHasPayload();
        }

        s.payloadHashes[uint16(DataTransferType.LayerZero)][transferKey.networkId][transferKey.senderAddress][
            transferKey.swapSequence
        ] = keccak256(extendedPayload);
    }

    event LzReceive(TransferKey transferKey, bytes payload);

    function lzReceive(
        uint16 senderChainId,
        bytes memory localAndRemoteAddresses,
        bytes memory extendedPayload
    ) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        bytes32 senderAddress;

        assembly {
            senderAddress := shr(96, mload(add(localAndRemoteAddresses, 32)))
        }

        TransferKey memory transferKey = LibTransferKey.decode(extendedPayload);

        LibTransferKey.validate(
            transferKey,
            TransferKey({
                networkId: s.layerZeroNetworkIds[senderChainId],
                senderAddress: senderAddress,
                swapSequence: transferKey.swapSequence
            })
        );

        registerPayload(transferKey, extendedPayload);

        emit LzReceive(transferKey, extendedPayload);
    }

    function enforce() internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        if (msg.sender != s.layerZeroSettings.routerAddress) {
            revert LayerZeroInvalidSender();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator, WormholeSettings} from "../libraries/LibMagpieAggregator.sol";
import {LibTransferKey, TransferKey} from "../libraries/LibTransferKey.sol";
import {IWormholeCore} from "../interfaces/wormhole/IWormholeCore.sol";

library LibWormhole {
    event UpdateWormholeSettings(address indexed sender, WormholeSettings wormholeSettings);

    function updateSettings(WormholeSettings memory wormholeSettings) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.wormholeSettings = wormholeSettings;

        emit UpdateWormholeSettings(msg.sender, wormholeSettings);
    }

    event AddWormholeNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addWormholeNetworkIds(uint16[] memory chainIds, uint16[] memory networkIds) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint256 i;
        uint256 l = chainIds.length;
        for (i = 0; i < l; ) {
            s.wormholeNetworkIds[chainIds[i]] = networkIds[i];

            unchecked {
                i++;
            }
        }

        emit AddWormholeNetworkIds(msg.sender, chainIds, networkIds);
    }

    function dataTransfer(bytes memory payload) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        uint64 wormholeCoreSequence = IWormholeCore(s.wormholeSettings.bridgeAddress).publishMessage(
            uint32(block.timestamp % 2**32),
            payload,
            s.wormholeSettings.consistencyLevel
        );

        s.wormholeCoreSequences[s.swapSequence] = wormholeCoreSequence;
    }

    function getCoreSequence(uint64 swapSequence) internal view returns (uint64) {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        return s.wormholeCoreSequences[swapSequence];
    }

    function getPayload(bytes memory dataTransferOutPayload) internal view returns (bytes memory extendedPayload) {
        AppStorage storage s = LibMagpieAggregator.getStorage();
        (IWormholeCore.VM memory vm, bool valid, string memory reason) = IWormholeCore(s.wormholeSettings.bridgeAddress)
            .parseAndVerifyVM(dataTransferOutPayload);
        require(valid, reason);

        TransferKey memory transferKey = LibTransferKey.decode(vm.payload);

        LibTransferKey.validate(
            transferKey,
            TransferKey({
                networkId: s.wormholeNetworkIds[vm.emitterChainId],
                senderAddress: vm.emitterAddress,
                swapSequence: transferKey.swapSequence
            })
        );

        extendedPayload = vm.payload;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {DelegatedCallType, LibGuard} from "../../libraries/LibGuard.sol";
import {AppStorage, LayerZeroSettings, WormholeSettings} from "../../libraries/LibMagpieAggregator.sol";
import {LibDataTransfer} from "../LibDataTransfer.sol";
import {LibLayerZero} from "../LibLayerZero.sol";
import {LibWormhole} from "../LibWormhole.sol";
import {IDataTransfer} from "../interfaces/IDataTransfer.sol";
import {DataTransferInArgs, DataTransferOutArgs, TransferKey} from "../LibCommon.sol";

contract DataTransferFacet is IDataTransfer {
    AppStorage internal s;

    function updateLayerZeroSettings(LayerZeroSettings calldata layerZeroSettings) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.updateSettings(layerZeroSettings);
    }

    function addLayerZeroChainIds(uint16[] calldata networkIds, uint16[] calldata chainIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.addLayerZeroChainIds(networkIds, chainIds);
    }

    function addLayerZeroNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibLayerZero.addLayerZeroNetworkIds(chainIds, networkIds);
    }

    function updateWormholeSettings(WormholeSettings calldata wormholeSettings) external override {
        LibDiamond.enforceIsContractOwner();
        LibWormhole.updateSettings(wormholeSettings);
    }

    function addWormholeNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external override {
        LibDiamond.enforceIsContractOwner();
        LibWormhole.addWormholeNetworkIds(chainIds, networkIds);
    }

    function getWormholeCoreSequence(uint64 transferKeyCoreSequence) external view returns (uint64) {
        return LibWormhole.getCoreSequence(transferKeyCoreSequence);
    }

    function lzReceive(
        uint16 senderChainId,
        bytes calldata localAndRemoteAddresses,
        uint64,
        bytes calldata extendedPayload
    ) external override {
        LibLayerZero.enforce();
        LibLayerZero.lzReceive(senderChainId, localAndRemoteAddresses, extendedPayload);
    }

    function dataTransferIn(DataTransferInArgs calldata dataTransferInArgs) external payable override {
        LibGuard.enforceDelegatedCallGuard(DelegatedCallType.DataTransferIn);
        LibDataTransfer.dataTransfer(dataTransferInArgs);
    }

    function dataTransferOut(
        DataTransferOutArgs calldata dataTransferOutArgs
    ) external payable override returns (TransferKey memory, bytes memory) {
        LibGuard.enforceDelegatedCallGuard(DelegatedCallType.DataTransferOut);
        return LibDataTransfer.getPayload(dataTransferOutArgs);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {LayerZeroSettings, WormholeSettings} from "../../libraries/LibMagpieAggregator.sol";
import {DataTransferInArgs, DataTransferOutArgs, TransferKey} from "../LibCommon.sol";

interface IDataTransfer {
    event UpdateLayerZeroSettings(address indexed sender, LayerZeroSettings layerZeroSettings);

    function updateLayerZeroSettings(LayerZeroSettings calldata layerZeroSettings) external;

    event AddLayerZeroChainIds(address indexed sender, uint16[] networkIds, uint16[] chainIds);

    function addLayerZeroChainIds(uint16[] calldata networkIds, uint16[] calldata chainIds) external;

    event AddLayerZeroNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addLayerZeroNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external;

    event UpdateWormholeSettings(address indexed sender, WormholeSettings wormholeSettings);

    function updateWormholeSettings(WormholeSettings calldata wormholeSettings) external;

    event AddWormholeNetworkIds(address indexed sender, uint16[] chainIds, uint16[] networkIds);

    function addWormholeNetworkIds(uint16[] calldata chainIds, uint16[] calldata networkIds) external;

    function getWormholeCoreSequence(uint64 transferKeyCoreSequence) external view returns (uint64);

    event LzReceive(TransferKey transferKey, bytes payload);

    function lzReceive(
        uint16 senderChainId,
        bytes calldata senderAddress,
        uint64 nonce,
        bytes calldata extendedPayload
    ) external;

    function dataTransferIn(DataTransferInArgs calldata dataTransferInArgs) external payable;

    function dataTransferOut(
        DataTransferOutArgs calldata dataTransferOutArgs
    ) external payable returns (TransferKey memory, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILayerZero {
    function send(
        uint16 _dstChainId,
        bytes calldata _remoteAndLocalAddresses,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    function estimateFees(
        uint16 _dstChainId, //destination layerZero ChainId
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWormholeCore {
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(
        bytes calldata encodedVM
    ) external view returns (IWormholeCore.VM memory vm, bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error AddressOutOfBounds();

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        if (self.length < start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 20), start))
        }

        return tempAddress;
    }

    function slice(
        bytes memory self,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function concat(bytes memory self, bytes memory postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(self)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(self, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(add(add(end, iszero(add(length, mload(self)))), 31), not(31)))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieAggregator} from "../libraries/LibMagpieAggregator.sol";

error ReentrantCall();
error InvalidDelegatedCall();

enum DelegatedCallType {
    BridgeIn,
    BridgeOut,
    DataTransferIn,
    DataTransferOut
}

library LibGuard {
    function enforcePreGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.guarded) {
            revert ReentrantCall();
        }

        s.guarded = true;
    }

    function enforcePostGuard() internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.guarded = false;
    }

    function enforceDelegatedCallPreGuard(DelegatedCallType delegatedCallType) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (s.delegatedCalls[uint8(delegatedCallType)]) {
            revert ReentrantCall();
        }

        s.delegatedCalls[uint8(delegatedCallType)] = true;
    }

    function enforceDelegatedCallGuard(DelegatedCallType delegatedCallType) internal view {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        if (!s.delegatedCalls[uint8(delegatedCallType)]) {
            revert InvalidDelegatedCall();
        }
    }

    function enforceDelegatedCallPostGuard(DelegatedCallType delegatedCallType) internal {
        AppStorage storage s = LibMagpieAggregator.getStorage();

        s.delegatedCalls[uint8(delegatedCallType)] = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    bytes4 selector;
    address addr;
}

struct WormholeBridgeSettings {
    address bridgeAddress;
}

struct StargateSettings {
    address routerAddress;
}

struct WormholeSettings {
    address bridgeAddress;
    uint8 consistencyLevel;
}

struct LayerZeroSettings {
    address routerAddress;
}

struct CelerBridgeSettings {
    address messageBusAddress;
}

struct AppStorage {
    address weth;
    uint16 networkId;
    mapping(uint16 => bytes32) magpieAggregatorAddresses;
    mapping(address => uint256) deposits;
    mapping(address => mapping(address => uint256)) depositsByUser;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => bool))) usedTransferKeys;
    uint64 swapSequence;
    // Pausable
    bool paused;
    // Reentrancy Guard
    bool guarded;
    // Amm
    mapping(uint16 => Amm) amms;
    // Curve Amm
    CurveSettings curveSettings;
    // Data Transfer
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes)))) payloads;
    // Stargate Bridge
    StargateSettings stargateSettings;
    mapping(uint16 => bytes32) magpieStargateBridgeAddresses;
    // Wormhole Bridge
    WormholeBridgeSettings wormholeBridgeSettings;
    mapping(uint64 => uint64) wormholeTokenSequences;
    // Wormhole Data Transfer
    WormholeSettings wormholeSettings;
    mapping(uint16 => uint16) wormholeNetworkIds;
    mapping(uint64 => uint64) wormholeCoreSequences;
    // LayerZero Data Transfer
    LayerZeroSettings layerZeroSettings;
    mapping(uint16 => uint16) layerZeroChainIds;
    mapping(uint16 => uint16) layerZeroNetworkIds;
    address magpieRouterAddress;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) stargateDeposits;
    mapping(uint8 => bool) delegatedCalls;
    // Celer Bridge
    CelerBridgeSettings celerBridgeSettings;
    mapping(uint16 => uint64) celerChainIds;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) celerDeposits;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => address))) celerRefundAddresses;
    mapping(uint16 => bytes32) magpieCelerBridgeAddresses;
    mapping(uint16 => mapping(uint16 => mapping(bytes32 => mapping(uint64 => bytes32)))) payloadHashes;
    mapping(uint16 => bytes32) magpieStargateBridgeV2Addresses;
}

library LibMagpieAggregator {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct TransferKey {
    uint16 networkId;
    bytes32 senderAddress;
    uint64 swapSequence;
}

error InvalidTransferKey();

library LibTransferKey {
    function encode(TransferKey memory transferKey) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(42);

        assembly {
            mstore(add(payload, 32), shl(240, mload(transferKey)))
            mstore(add(payload, 34), mload(add(transferKey, 32)))
            mstore(add(payload, 66), shl(192, mload(add(transferKey, 64))))
        }

        return payload;
    }

    function decode(bytes memory payload) internal pure returns (TransferKey memory transferKey) {
        assembly {
            mstore(transferKey, shr(240, mload(add(payload, 32))))
            mstore(add(transferKey, 32), mload(add(payload, 34)))
            mstore(add(transferKey, 64), shr(192, mload(add(payload, 66))))
        }
    }

    function validate(TransferKey memory self, TransferKey memory transferKey) internal pure {
        if (
            self.networkId != transferKey.networkId ||
            self.senderAddress != transferKey.senderAddress ||
            self.swapSequence != transferKey.swapSequence
        ) {
            revert InvalidTransferKey();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}