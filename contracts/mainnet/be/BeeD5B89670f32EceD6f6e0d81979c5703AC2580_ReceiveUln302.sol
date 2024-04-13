// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

/// @dev simply a container of endpoint address and local eid
abstract contract MessageLibBase {
    address internal immutable endpoint;
    uint32 internal immutable localEid;

    error LZ_MessageLib_OnlyEndpoint();

    modifier onlyEndpoint() {
        if (endpoint != msg.sender) revert LZ_MessageLib_OnlyEndpoint();
        _;
    }

    constructor(address _endpoint, uint32 _localEid) {
        endpoint = _endpoint;
        localEid = _localEid;
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import { ILayerZeroEndpointV2, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { IMessageLib, MessageLibType } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLib.sol";
import { PacketV1Codec } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

import { MessageLibBase } from "./MessageLibBase.sol";

/// @dev receive-side message library base contract on endpoint v2.
/// it does not have the complication as the one of endpoint v1, such as nonce, executor whitelist, etc.
abstract contract ReceiveLibBaseE2 is MessageLibBase, ERC165, IMessageLib {
    using PacketV1Codec for bytes;

    constructor(address _endpoint) MessageLibBase(_endpoint, ILayerZeroEndpointV2(_endpoint).eid()) {}

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return _interfaceId == type(IMessageLib).interfaceId || super.supportsInterface(_interfaceId);
    }

    function messageLibType() external pure virtual override returns (MessageLibType) {
        return MessageLibType.Receive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @dev should be implemented by the ReceiveUln302 contract and future ReceiveUln contracts on EndpointV2
interface IReceiveUlnE2 {
    /// @notice for each dvn to verify the payload
    /// @dev this function signature 0x0223536e
    function verify(bytes calldata _packetHeader, bytes32 _payloadHash, uint64 _confirmations) external;

    /// @notice verify the payload at endpoint, will check if all DVNs verified
    function commitVerification(bytes calldata _packetHeader, bytes32 _payloadHash) external;
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { PacketV1Codec } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";

import { UlnBase, UlnConfig } from "./UlnBase.sol";

struct Verification {
    bool submitted;
    uint64 confirmations;
}

/// @dev includes the utility functions for checking ULN states and logics
abstract contract ReceiveUlnBase is UlnBase {
    using PacketV1Codec for bytes;

    mapping(bytes32 headerHash => mapping(bytes32 payloadHash => mapping(address dvn => Verification)))
        public hashLookup;

    event PayloadVerified(address dvn, bytes header, uint256 confirmations, bytes32 proofHash);

    error LZ_ULN_InvalidPacketHeader();
    error LZ_ULN_InvalidPacketVersion();
    error LZ_ULN_InvalidEid();
    error LZ_ULN_Verifying();

    // ============================ External ===================================
    function verifiable(
        UlnConfig memory _config,
        bytes32 _headerHash,
        bytes32 _payloadHash
    ) external view returns (bool) {
        return _checkVerifiable(_config, _headerHash, _payloadHash);
    }

    function assertHeader(bytes calldata _packetHeader, uint32 _localEid) external pure {
        _assertHeader(_packetHeader, _localEid);
    }

    // ============================ Internal ===================================
    /// @dev per DVN signing function
    function _verify(bytes calldata _packetHeader, bytes32 _payloadHash, uint64 _confirmations) internal {
        hashLookup[keccak256(_packetHeader)][_payloadHash][msg.sender] = Verification(true, _confirmations);
        emit PayloadVerified(msg.sender, _packetHeader, _confirmations, _payloadHash);
    }

    function _verified(
        address _dvn,
        bytes32 _headerHash,
        bytes32 _payloadHash,
        uint64 _requiredConfirmation
    ) internal view returns (bool verified) {
        Verification memory verification = hashLookup[_headerHash][_payloadHash][_dvn];
        // return true if the dvn has signed enough confirmations
        verified = verification.submitted && verification.confirmations >= _requiredConfirmation;
    }

    function _verifyAndReclaimStorage(UlnConfig memory _config, bytes32 _headerHash, bytes32 _payloadHash) internal {
        if (!_checkVerifiable(_config, _headerHash, _payloadHash)) {
            revert LZ_ULN_Verifying();
        }

        // iterate the required DVNs
        if (_config.requiredDVNCount > 0) {
            for (uint8 i = 0; i < _config.requiredDVNCount; ++i) {
                delete hashLookup[_headerHash][_payloadHash][_config.requiredDVNs[i]];
            }
        }

        // iterate the optional DVNs
        if (_config.optionalDVNCount > 0) {
            for (uint8 i = 0; i < _config.optionalDVNCount; ++i) {
                delete hashLookup[_headerHash][_payloadHash][_config.optionalDVNs[i]];
            }
        }
    }

    function _assertHeader(bytes calldata _packetHeader, uint32 _localEid) internal pure {
        // assert packet header is of right size 81
        if (_packetHeader.length != 81) revert LZ_ULN_InvalidPacketHeader();
        // assert packet header version is the same as ULN
        if (_packetHeader.version() != PacketV1Codec.PACKET_VERSION) revert LZ_ULN_InvalidPacketVersion();
        // assert the packet is for this endpoint
        if (_packetHeader.dstEid() != _localEid) revert LZ_ULN_InvalidEid();
    }

    /// @dev for verifiable view function
    /// @dev checks if this verification is ready to be committed to the endpoint
    function _checkVerifiable(
        UlnConfig memory _config,
        bytes32 _headerHash,
        bytes32 _payloadHash
    ) internal view returns (bool) {
        // iterate the required DVNs
        if (_config.requiredDVNCount > 0) {
            for (uint8 i = 0; i < _config.requiredDVNCount; ++i) {
                if (!_verified(_config.requiredDVNs[i], _headerHash, _payloadHash, _config.confirmations)) {
                    // return if any of the required DVNs haven't signed
                    return false;
                }
            }
            if (_config.optionalDVNCount == 0) {
                // returns early if all required DVNs have signed and there are no optional DVNs
                return true;
            }
        }

        // then it must require optional validations
        uint8 threshold = _config.optionalDVNThreshold;
        for (uint8 i = 0; i < _config.optionalDVNCount; ++i) {
            if (_verified(_config.optionalDVNs[i], _headerHash, _payloadHash, _config.confirmations)) {
                // increment the optional count if the optional DVN has signed
                threshold--;
                if (threshold == 0) {
                    // early return if the optional threshold has hit
                    return true;
                }
            }
        }

        // return false as a catch-all
        return false;
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { PacketV1Codec } from "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/PacketV1Codec.sol";
import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { ILayerZeroEndpointV2, Origin } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { IReceiveUlnE2 } from "../interfaces/IReceiveUlnE2.sol";
import { ReceiveUlnBase } from "../ReceiveUlnBase.sol";
import { ReceiveLibBaseE2 } from "../../ReceiveLibBaseE2.sol";
import { UlnConfig } from "../UlnBase.sol";

/// @dev This is a gluing contract. It simply parses the requests and forward to the super.impl() accordingly.
/// @dev In this case, it combines the logic of ReceiveUlnBase and ReceiveLibBaseE2
contract ReceiveUln302 is IReceiveUlnE2, ReceiveUlnBase, ReceiveLibBaseE2 {
    using PacketV1Codec for bytes;

    /// @dev CONFIG_TYPE_ULN=2 here to align with SendUln302/ReceiveUln302/ReceiveUln301
    uint32 internal constant CONFIG_TYPE_ULN = 2;

    error LZ_ULN_InvalidConfigType(uint32 configType);

    constructor(address _endpoint) ReceiveLibBaseE2(_endpoint) {}

    function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
        return _interfaceId == type(IReceiveUlnE2).interfaceId || super.supportsInterface(_interfaceId);
    }

    // ============================ OnlyEndpoint ===================================

    // only the ULN config on the receive side
    function setConfig(address _oapp, SetConfigParam[] calldata _params) external override onlyEndpoint {
        for (uint256 i = 0; i < _params.length; i++) {
            SetConfigParam calldata param = _params[i];
            _assertSupportedEid(param.eid);
            if (param.configType == CONFIG_TYPE_ULN) {
                _setUlnConfig(param.eid, _oapp, abi.decode(param.config, (UlnConfig)));
            } else {
                revert LZ_ULN_InvalidConfigType(param.configType);
            }
        }
    }

    // ============================ External ===================================

    /// @dev dont need to check endpoint verifiable here to save gas, as it will reverts if not verifiable.
    function commitVerification(bytes calldata _packetHeader, bytes32 _payloadHash) external {
        _assertHeader(_packetHeader, localEid);

        // cache these values to save gas
        address receiver = _packetHeader.receiverB20();
        uint32 srcEid = _packetHeader.srcEid();

        UlnConfig memory config = getUlnConfig(receiver, srcEid);
        _verifyAndReclaimStorage(config, keccak256(_packetHeader), _payloadHash);

        Origin memory origin = Origin(srcEid, _packetHeader.sender(), _packetHeader.nonce());
        // endpoint will revert if nonce <= lazyInboundNonce
        ILayerZeroEndpointV2(endpoint).verify(origin, receiver, _payloadHash);
    }

    /// @dev for dvn to verify the payload
    function verify(bytes calldata _packetHeader, bytes32 _payloadHash, uint64 _confirmations) external {
        _verify(_packetHeader, _payloadHash, _confirmations);
    }

    // ============================ View ===================================

    function getConfig(uint32 _eid, address _oapp, uint32 _configType) external view override returns (bytes memory) {
        if (_configType == CONFIG_TYPE_ULN) {
            return abi.encode(getUlnConfig(_oapp, _eid));
        } else {
            revert LZ_ULN_InvalidConfigType(_configType);
        }
    }

    function isSupportedEid(uint32 _eid) external view override returns (bool) {
        return _isSupportedEid(_eid);
    }

    function version() external pure override returns (uint64 major, uint8 minor, uint8 endpointVersion) {
        return (3, 0, 2);
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// the formal properties are documented in the setter functions
struct UlnConfig {
    uint64 confirmations;
    // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
    uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
    uint8 optionalDVNThreshold; // (0, optionalDVNCount]
    address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
    address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
}

struct SetDefaultUlnConfigParam {
    uint32 eid;
    UlnConfig config;
}

/// @dev includes the utility functions for checking ULN states and logics
abstract contract UlnBase is Ownable {
    address private constant DEFAULT_CONFIG = address(0);
    // reserved values for
    uint8 internal constant DEFAULT = 0;
    uint8 internal constant NIL_DVN_COUNT = type(uint8).max;
    uint64 internal constant NIL_CONFIRMATIONS = type(uint64).max;
    // 127 to prevent total number of DVNs (127 * 2) exceeding uint8.max (255)
    // by limiting the total size, it would help constraint the design of DVNOptions
    uint8 private constant MAX_COUNT = (type(uint8).max - 1) / 2;

    mapping(address oapp => mapping(uint32 eid => UlnConfig)) internal ulnConfigs;

    error LZ_ULN_Unsorted();
    error LZ_ULN_InvalidRequiredDVNCount();
    error LZ_ULN_InvalidOptionalDVNCount();
    error LZ_ULN_AtLeastOneDVN();
    error LZ_ULN_InvalidOptionalDVNThreshold();
    error LZ_ULN_InvalidConfirmations();
    error LZ_ULN_UnsupportedEid(uint32 eid);

    event DefaultUlnConfigsSet(SetDefaultUlnConfigParam[] params);
    event UlnConfigSet(address oapp, uint32 eid, UlnConfig config);

    // ============================ OnlyOwner ===================================

    /// @dev about the DEFAULT ULN config
    /// 1) its values are all LITERAL (e.g. 0 is 0). whereas in the oapp ULN config, 0 (default value) points to the default ULN config
    ///     this design enables the oapp to point to DEFAULT config without explicitly setting the config
    /// 2) its configuration is more restrictive than the oapp ULN config that
    ///     a) it must not use NIL value, where NIL is used only by oapps to indicate the LITERAL 0
    ///     b) it must have at least one DVN
    function setDefaultUlnConfigs(SetDefaultUlnConfigParam[] calldata _params) external onlyOwner {
        for (uint256 i = 0; i < _params.length; ++i) {
            SetDefaultUlnConfigParam calldata param = _params[i];

            // 2.a must not use NIL
            if (param.config.requiredDVNCount == NIL_DVN_COUNT) revert LZ_ULN_InvalidRequiredDVNCount();
            if (param.config.optionalDVNCount == NIL_DVN_COUNT) revert LZ_ULN_InvalidOptionalDVNCount();
            if (param.config.confirmations == NIL_CONFIRMATIONS) revert LZ_ULN_InvalidConfirmations();

            // 2.b must have at least one dvn
            _assertAtLeastOneDVN(param.config);

            _setConfig(DEFAULT_CONFIG, param.eid, param.config);
        }
        emit DefaultUlnConfigsSet(_params);
    }

    // ============================ View ===================================
    // @dev assuming most oapps use default, we get default as memory and custom as storage to save gas
    function getUlnConfig(address _oapp, uint32 _remoteEid) public view returns (UlnConfig memory rtnConfig) {
        UlnConfig storage defaultConfig = ulnConfigs[DEFAULT_CONFIG][_remoteEid];
        UlnConfig storage customConfig = ulnConfigs[_oapp][_remoteEid];

        // if confirmations is 0, use default
        uint64 confirmations = customConfig.confirmations;
        if (confirmations == DEFAULT) {
            rtnConfig.confirmations = defaultConfig.confirmations;
        } else if (confirmations != NIL_CONFIRMATIONS) {
            // if confirmations is uint64.max, no block confirmations required
            rtnConfig.confirmations = confirmations;
        } // else do nothing, rtnConfig.confirmation is 0

        if (customConfig.requiredDVNCount == DEFAULT) {
            if (defaultConfig.requiredDVNCount > 0) {
                // copy only if count > 0. save gas
                rtnConfig.requiredDVNs = defaultConfig.requiredDVNs;
                rtnConfig.requiredDVNCount = defaultConfig.requiredDVNCount;
            } // else, do nothing
        } else {
            if (customConfig.requiredDVNCount != NIL_DVN_COUNT) {
                rtnConfig.requiredDVNs = customConfig.requiredDVNs;
                rtnConfig.requiredDVNCount = customConfig.requiredDVNCount;
            } // else, do nothing
        }

        if (customConfig.optionalDVNCount == DEFAULT) {
            if (defaultConfig.optionalDVNCount > 0) {
                // copy only if count > 0. save gas
                rtnConfig.optionalDVNs = defaultConfig.optionalDVNs;
                rtnConfig.optionalDVNCount = defaultConfig.optionalDVNCount;
                rtnConfig.optionalDVNThreshold = defaultConfig.optionalDVNThreshold;
            }
        } else {
            if (customConfig.optionalDVNCount != NIL_DVN_COUNT) {
                rtnConfig.optionalDVNs = customConfig.optionalDVNs;
                rtnConfig.optionalDVNCount = customConfig.optionalDVNCount;
                rtnConfig.optionalDVNThreshold = customConfig.optionalDVNThreshold;
            }
        }

        // the final value must have at least one dvn
        // it is possible that some default config result into 0 dvns
        _assertAtLeastOneDVN(rtnConfig);
    }

    /// @dev Get the uln config without the default config for the given remoteEid.
    function getAppUlnConfig(address _oapp, uint32 _remoteEid) external view returns (UlnConfig memory) {
        return ulnConfigs[_oapp][_remoteEid];
    }

    // ============================ Internal ===================================
    function _setUlnConfig(uint32 _remoteEid, address _oapp, UlnConfig memory _param) internal {
        _setConfig(_oapp, _remoteEid, _param);

        // get ULN config again as a catch all to ensure the config is valid
        getUlnConfig(_oapp, _remoteEid);
        emit UlnConfigSet(_oapp, _remoteEid, _param);
    }

    /// @dev a supported Eid must have a valid default uln config, which has at least one dvn
    function _isSupportedEid(uint32 _remoteEid) internal view returns (bool) {
        UlnConfig storage defaultConfig = ulnConfigs[DEFAULT_CONFIG][_remoteEid];
        return defaultConfig.requiredDVNCount > 0 || defaultConfig.optionalDVNThreshold > 0;
    }

    function _assertSupportedEid(uint32 _remoteEid) internal view {
        if (!_isSupportedEid(_remoteEid)) revert LZ_ULN_UnsupportedEid(_remoteEid);
    }

    // ============================ Private ===================================

    function _assertAtLeastOneDVN(UlnConfig memory _config) private pure {
        if (_config.requiredDVNCount == 0 && _config.optionalDVNThreshold == 0) revert LZ_ULN_AtLeastOneDVN();
    }

    /// @dev this private function is used in both setDefaultUlnConfigs and setUlnConfig
    function _setConfig(address _oapp, uint32 _eid, UlnConfig memory _param) private {
        // @dev required dvns
        // if dvnCount == NONE, dvns list must be empty
        // if dvnCount == DEFAULT, dvn list must be empty
        // otherwise, dvnList.length == dvnCount and assert the list is valid
        if (_param.requiredDVNCount == NIL_DVN_COUNT || _param.requiredDVNCount == DEFAULT) {
            if (_param.requiredDVNs.length != 0) revert LZ_ULN_InvalidRequiredDVNCount();
        } else {
            if (_param.requiredDVNs.length != _param.requiredDVNCount || _param.requiredDVNCount > MAX_COUNT)
                revert LZ_ULN_InvalidRequiredDVNCount();
            _assertNoDuplicates(_param.requiredDVNs);
        }

        // @dev optional dvns
        // if optionalDVNCount == NONE, optionalDVNs list must be empty and threshold must be 0
        // if optionalDVNCount == DEFAULT, optionalDVNs list must be empty and threshold must be 0
        // otherwise, optionalDVNs.length == optionalDVNCount, threshold > 0 && threshold <= optionalDVNCount and assert the list is valid

        // example use case: an oapp uses the DEFAULT 'required' but
        //     a) use a custom 1/1 dvn (practically a required dvn), or
        //     b) use a custom 2/3 dvn
        if (_param.optionalDVNCount == NIL_DVN_COUNT || _param.optionalDVNCount == DEFAULT) {
            if (_param.optionalDVNs.length != 0) revert LZ_ULN_InvalidOptionalDVNCount();
            if (_param.optionalDVNThreshold != 0) revert LZ_ULN_InvalidOptionalDVNThreshold();
        } else {
            if (_param.optionalDVNs.length != _param.optionalDVNCount || _param.optionalDVNCount > MAX_COUNT)
                revert LZ_ULN_InvalidOptionalDVNCount();
            if (_param.optionalDVNThreshold == 0 || _param.optionalDVNThreshold > _param.optionalDVNCount)
                revert LZ_ULN_InvalidOptionalDVNThreshold();
            _assertNoDuplicates(_param.optionalDVNs);
        }
        // don't assert valid count here, as it needs to be validated along side default config

        ulnConfigs[_oapp][_eid] = _param;
    }

    function _assertNoDuplicates(address[] memory _dvns) private pure {
        address lastDVN = address(0);
        for (uint256 i = 0; i < _dvns.length; i++) {
            address dvn = _dvns[i];
            if (dvn <= lastDVN) revert LZ_ULN_Unsorted(); // to ensure no duplicates
            lastDVN = dvn;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IMessageLibManager } from "./IMessageLibManager.sol";
import { IMessagingComposer } from "./IMessagingComposer.sol";
import { IMessagingChannel } from "./IMessagingChannel.sol";
import { IMessagingContext } from "./IMessagingContext.sol";

struct MessagingParams {
    uint32 dstEid;
    bytes32 receiver;
    bytes message;
    bytes options;
    bool payInLzToken;
}

struct MessagingReceipt {
    bytes32 guid;
    uint64 nonce;
    MessagingFee fee;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

struct Origin {
    uint32 srcEid;
    bytes32 sender;
    uint64 nonce;
}

interface ILayerZeroEndpointV2 is IMessageLibManager, IMessagingComposer, IMessagingChannel, IMessagingContext {
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    event PacketVerified(Origin origin, address receiver, bytes32 payloadHash);

    event PacketDelivered(Origin origin, address receiver);

    event LzReceiveAlert(
        address indexed receiver,
        address indexed executor,
        Origin origin,
        bytes32 guid,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    event LzTokenSet(address token);

    event DelegateSet(address sender, address delegate);

    function quote(MessagingParams calldata _params, address _sender) external view returns (MessagingFee memory);

    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    function verify(Origin calldata _origin, address _receiver, bytes32 _payloadHash) external;

    function verifiable(Origin calldata _origin, address _receiver) external view returns (bool);

    function initializable(Origin calldata _origin, address _receiver) external view returns (bool);

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    // oapp can burn messages partially by calling this function with its own business logic if messages are verified in order
    function clear(address _oapp, Origin calldata _origin, bytes32 _guid, bytes calldata _message) external;

    function setLzToken(address _lzToken) external;

    function lzToken() external view returns (address);

    function nativeToken() external view returns (address);

    function setDelegate(address _delegate) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { SetConfigParam } from "./IMessageLibManager.sol";

enum MessageLibType {
    Send,
    Receive,
    SendAndReceive
}

interface IMessageLib is IERC165 {
    function setConfig(address _oapp, SetConfigParam[] calldata _config) external;

    function getConfig(uint32 _eid, address _oapp, uint32 _configType) external view returns (bytes memory config);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    // message libs of same major version are compatible
    function version() external view returns (uint64 major, uint8 minor, uint8 endpointVersion);

    function messageLibType() external view returns (MessageLibType);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

struct SetConfigParam {
    uint32 eid;
    uint32 configType;
    bytes config;
}

interface IMessageLibManager {
    struct Timeout {
        address lib;
        uint256 expiry;
    }

    event LibraryRegistered(address newLib);
    event DefaultSendLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibrarySet(uint32 eid, address newLib);
    event DefaultReceiveLibraryTimeoutSet(uint32 eid, address oldLib, uint256 expiry);
    event SendLibrarySet(address sender, uint32 eid, address newLib);
    event ReceiveLibrarySet(address receiver, uint32 eid, address newLib);
    event ReceiveLibraryTimeoutSet(address receiver, uint32 eid, address oldLib, uint256 timeout);

    function registerLibrary(address _lib) external;

    function isRegisteredLibrary(address _lib) external view returns (bool);

    function getRegisteredLibraries() external view returns (address[] memory);

    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    function defaultSendLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibrary(uint32 _eid, address _newLib, uint256 _timeout) external;

    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    function setDefaultReceiveLibraryTimeout(uint32 _eid, address _lib, uint256 _expiry) external;

    function defaultReceiveLibraryTimeout(uint32 _eid) external view returns (address lib, uint256 expiry);

    function isSupportedEid(uint32 _eid) external view returns (bool);

    function isValidReceiveLibrary(address _receiver, uint32 _eid, address _lib) external view returns (bool);

    /// ------------------- OApp interfaces -------------------
    function setSendLibrary(address _oapp, uint32 _eid, address _newLib) external;

    function getSendLibrary(address _sender, uint32 _eid) external view returns (address lib);

    function isDefaultSendLibrary(address _sender, uint32 _eid) external view returns (bool);

    function setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod) external;

    function getReceiveLibrary(address _receiver, uint32 _eid) external view returns (address lib, bool isDefault);

    function setReceiveLibraryTimeout(address _oapp, uint32 _eid, address _lib, uint256 _gracePeriod) external;

    function receiveLibraryTimeout(address _receiver, uint32 _eid) external view returns (address lib, uint256 expiry);

    function setConfig(address _oapp, address _lib, SetConfigParam[] calldata _params) external;

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingChannel {
    event InboundNonceSkipped(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce);
    event PacketNilified(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);
    event PacketBurnt(uint32 srcEid, bytes32 sender, address receiver, uint64 nonce, bytes32 payloadHash);

    function eid() external view returns (uint32);

    // this is an emergency function if a message cannot be verified for some reasons
    // required to provide _nextNonce to avoid race condition
    function skip(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce) external;

    function nilify(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function burn(address _oapp, uint32 _srcEid, bytes32 _sender, uint64 _nonce, bytes32 _payloadHash) external;

    function nextGuid(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (bytes32);

    function inboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);

    function outboundNonce(address _sender, uint32 _dstEid, bytes32 _receiver) external view returns (uint64);

    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    function lazyInboundNonce(address _receiver, uint32 _srcEid, bytes32 _sender) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingComposer {
    event ComposeSent(address from, address to, bytes32 guid, uint16 index, bytes message);
    event ComposeDelivered(address from, address to, bytes32 guid, uint16 index);
    event LzComposeAlert(
        address indexed from,
        address indexed to,
        address indexed executor,
        bytes32 guid,
        uint16 index,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash);

    function sendCompose(address _to, bytes32 _guid, uint16 _index, bytes calldata _message) external;

    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IMessagingContext {
    function isSendingMessage() external view returns (bool);

    function getSendContext() external view returns (uint32 dstEid, address sender);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import { MessagingFee } from "./ILayerZeroEndpointV2.sol";
import { IMessageLib } from "./IMessageLib.sol";

struct Packet {
    uint64 nonce;
    uint32 srcEid;
    address sender;
    uint32 dstEid;
    bytes32 receiver;
    bytes32 guid;
    bytes message;
}

interface ISendLib is IMessageLib {
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    function quote(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    function setTreasury(address _treasury) external;

    function withdrawFee(address _to, uint256 _amount) external;

    function withdrawLzTokenFee(address _lzToken, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

library AddressCast {
    error AddressCast_InvalidSizeForAddress();
    error AddressCast_InvalidAddress();

    function toBytes32(bytes calldata _addressBytes) internal pure returns (bytes32 result) {
        if (_addressBytes.length > 32) revert AddressCast_InvalidAddress();
        result = bytes32(_addressBytes);
        unchecked {
            uint256 offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    function toBytes32(address _address) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    function toBytes(bytes32 _addressBytes32, uint256 _size) internal pure returns (bytes memory result) {
        if (_size == 0 || _size > 32) revert AddressCast_InvalidSizeForAddress();
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    function toAddress(bytes32 _addressBytes32) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }

    function toAddress(bytes calldata _addressBytes) internal pure returns (address result) {
        if (_addressBytes.length != 20) revert AddressCast_InvalidAddress();
        result = address(bytes20(_addressBytes));
    }
}

// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import { Packet } from "../../interfaces/ISendLib.sol";
import { AddressCast } from "../../libs/AddressCast.sol";

library PacketV1Codec {
    using AddressCast for address;
    using AddressCast for bytes32;

    uint8 internal constant PACKET_VERSION = 1;

    // header (version + nonce + path)
    // version
    uint256 private constant PACKET_VERSION_OFFSET = 0;
    //    nonce
    uint256 private constant NONCE_OFFSET = 1;
    //    path
    uint256 private constant SRC_EID_OFFSET = 9;
    uint256 private constant SENDER_OFFSET = 13;
    uint256 private constant DST_EID_OFFSET = 45;
    uint256 private constant RECEIVER_OFFSET = 49;
    // payload (guid + message)
    uint256 private constant GUID_OFFSET = 81; // keccak256(nonce + path)
    uint256 private constant MESSAGE_OFFSET = 113;

    function encode(Packet memory _packet) internal pure returns (bytes memory encodedPacket) {
        encodedPacket = abi.encodePacked(
            PACKET_VERSION,
            _packet.nonce,
            _packet.srcEid,
            _packet.sender.toBytes32(),
            _packet.dstEid,
            _packet.receiver,
            _packet.guid,
            _packet.message
        );
    }

    function encodePacketHeader(Packet memory _packet) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                PACKET_VERSION,
                _packet.nonce,
                _packet.srcEid,
                _packet.sender.toBytes32(),
                _packet.dstEid,
                _packet.receiver
            );
    }

    function encodePayload(Packet memory _packet) internal pure returns (bytes memory) {
        return abi.encodePacked(_packet.guid, _packet.message);
    }

    function header(bytes calldata _packet) internal pure returns (bytes calldata) {
        return _packet[0:GUID_OFFSET];
    }

    function version(bytes calldata _packet) internal pure returns (uint8) {
        return uint8(bytes1(_packet[PACKET_VERSION_OFFSET:NONCE_OFFSET]));
    }

    function nonce(bytes calldata _packet) internal pure returns (uint64) {
        return uint64(bytes8(_packet[NONCE_OFFSET:SRC_EID_OFFSET]));
    }

    function srcEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[SRC_EID_OFFSET:SENDER_OFFSET]));
    }

    function sender(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[SENDER_OFFSET:DST_EID_OFFSET]);
    }

    function senderAddressB20(bytes calldata _packet) internal pure returns (address) {
        return sender(_packet).toAddress();
    }

    function dstEid(bytes calldata _packet) internal pure returns (uint32) {
        return uint32(bytes4(_packet[DST_EID_OFFSET:RECEIVER_OFFSET]));
    }

    function receiver(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[RECEIVER_OFFSET:GUID_OFFSET]);
    }

    function receiverB20(bytes calldata _packet) internal pure returns (address) {
        return receiver(_packet).toAddress();
    }

    function guid(bytes calldata _packet) internal pure returns (bytes32) {
        return bytes32(_packet[GUID_OFFSET:MESSAGE_OFFSET]);
    }

    function message(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[MESSAGE_OFFSET:]);
    }

    function payload(bytes calldata _packet) internal pure returns (bytes calldata) {
        return bytes(_packet[GUID_OFFSET:]);
    }

    function payloadHash(bytes calldata _packet) internal pure returns (bytes32) {
        return keccak256(payload(_packet));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}