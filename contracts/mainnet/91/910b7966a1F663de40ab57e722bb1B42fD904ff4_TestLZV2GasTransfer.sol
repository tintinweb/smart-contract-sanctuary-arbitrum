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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Pausable } from '@openzeppelin/contracts/security/Pausable.sol';
import { ITokenBalance } from '../interfaces/ITokenBalance.sol';
import '../helpers/TransferHelper.sol' as TransferHelper;
import '../Constants.sol' as Constants;

/**
 * @title OwnerManageable
 * @notice OwnerManageable contract
 */
contract OwnerManageable is Ownable, Pausable {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Performs the token cleanup
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     */
    function cleanup(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, address(this).balance);
        } else {
            TransferHelper.safeTransfer(
                _tokenAddress,
                msg.sender,
                ITokenBalance(_tokenAddress).balanceOf(address(this))
            );
        }
    }

    /**
     * @notice Performs the token cleanup using the provided amount
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanupWithAmount(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function _initOwner(address _owner) internal {
        if (_owner != _msgSender() && _owner != address(0)) {
            _transferOwnership(_owner);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

/**
 * @dev The default token decimals value
 */
uint256 constant DECIMALS_DEFAULT = 18;

/**
 * @dev The maximum uint256 value for swap amount limit settings
 */
uint256 constant INFINITY = type(uint256).max;

/**
 * @dev The default limit of account list size
 */
uint256 constant LIST_SIZE_LIMIT_DEFAULT = 100;

/**
 * @dev The limit of swap router list size
 */
uint256 constant LIST_SIZE_LIMIT_ROUTERS = 200;

/**
 * @dev The factor for percentage settings. Example: 100 is 0.1%
 */
uint256 constant MILLIPERCENT_FACTOR = 100_000;

/**
 * @dev The de facto standard address to denote the native token
 */
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ILayerZeroEndpointV2, MessagingFee, MessagingParams, Origin } from '@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol';
import { OwnerManageable } from '../access/OwnerManageable.sol';
import { SystemVersionId } from '../SystemVersionId.sol';
import '../helpers/AddressHelper.sol' as AddressHelper;

/**
 * @title TestLZV2GasTransfer
 * @notice Test contract
 */
contract TestLZV2GasTransfer is SystemVersionId, OwnerManageable {
    /**
     * @notice Gas transfer parameter data structure
     * @param remoteEid The remote endpoint identifier
     * @param recipient The address of the gas transfer recipient
     * @param amount Gas transfer amount
     * @param settings Gas transfer settings
     */
    struct GasTransferItem {
        uint16 remoteEid;
        address recipient;
        uint128 amount;
        bytes settings;
    }

    /**
     * @notice Endpoint data item structure
     * @param lzValue The endpoint call value
     * @param messagingParams The endpoint messaging parameters
     */
    struct EndpointDataItem {
        uint256 lzValue;
        MessagingParams messagingParams;
    }

    /**
     * @dev The cross-chain endpoint contract reference
     */
    ILayerZeroEndpointV2 public endpoint;

    string public unique = '0001'; // TODO cleanup

    bytes private constant LZ_PAYLOAD_NONE = '';
    uint128 private minDstAppGas;
    uint256 private minReserve;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpoint The cross-chain endpoint contract reference
     */
    event SetEndpoint(ILayerZeroEndpointV2 indexed endpoint);

    /**
     * @notice Emitted when the delegate address is set
     * @param delegate The delegate address
     */
    event SetDelegate(address indexed delegate);

    event TestLzReceive(); // TODO cleanup

    /**
     * @notice Emitted when the parameter validation results in an error
     */
    error ValidationError();

    /**
     * @notice Initializes the contract
     * @param _endpoint The cross-chain endpoint contract address
     * @param _validation The initial validation data
     * @param _owner The address of the initial owner of the contract
     */
    constructor(ILayerZeroEndpointV2 _endpoint, bytes memory _validation, address _owner) {
        _setEndpoint(_endpoint);
        _setValidation(_validation);

        _initOwner(_owner);
        _setDelegate(_owner);
    }

    /**
     * @notice The standard "receive" function
     */
    receive() external payable {}

    /**
     * @notice Performs a gas transfer action
     * @param _parameters Gas transfer parameters
     */
    function gasTransfer(GasTransferItem[] calldata _parameters) external payable whenNotPaused {
        (EndpointDataItem[] memory endpointData, ) = _getEndpointData(_parameters, true);

        for (uint256 index = 0; index < endpointData.length; index++) {
            EndpointDataItem memory endpointDataItem = endpointData[index];

            endpoint.send{ value: endpointDataItem.lzValue }(
                endpointDataItem.messagingParams,
                address(this)
            );
        }
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     */
    function lzReceive(Origin calldata, bytes32, bytes calldata, address, bytes calldata) external {
        emit TestLzReceive(); // TODO cleanup
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpoint The cross-chain endpoint contract reference
     */
    function setEndpoint(ILayerZeroEndpointV2 _endpoint) external onlyOwner {
        _setEndpoint(_endpoint);
    }

    /**
     * @notice Sets the validation data
     * @param _validation The validation data
     */
    function setValidation(bytes memory _validation) external onlyOwner {
        _setValidation(_validation);
    }

    /**
     * @notice Sets the delegate address
     * @param _delegate The delegate address
     */
    function setDelegate(address _delegate) external onlyOwner {
        _setDelegate(_delegate);
    }

    /**
     * @notice Checks if the path initialization is allowed based on the provided origin
     * @dev _origin The origin information containing the source endpoint and sender address
     * @return Whether the path has been initialized
     */
    function allowInitializePath(Origin calldata /*_origin*/) public pure returns (bool) {
        return true;
    }

    /**
     * @notice Retrieves the next nonce for a given source endpoint and sender address
     * @dev _srcEid The source endpoint ID
     * @dev _sender The sender address
     * @return nonce The next nonce
     */
    function nextNonce(uint32 /*_srcEid*/, bytes32 /*_sender*/) public pure returns (uint64 nonce) {
        return 0;
    }

    /**
     * @notice Source chain tx value estimation
     * @param _parameters Gas transfer parameters
     * @return lzValue The source chain tx value
     */
    function estimateSourceValue(
        GasTransferItem[] calldata _parameters
    ) external view returns (uint256 lzValue) {
        (, lzValue) = _getEndpointData(_parameters, false);
    }

    function _setEndpoint(ILayerZeroEndpointV2 _endpoint) private {
        AddressHelper.requireContract(address(_endpoint));

        endpoint = _endpoint;

        emit SetEndpoint(_endpoint);
    }

    function _setValidation(bytes memory _validation) private {
        (minDstAppGas, minReserve) = abi.decode(_validation, (uint128, uint256));
    }

    function _setDelegate(address _delegate) private {
        endpoint.setDelegate(_delegate);

        emit SetDelegate(_delegate);
    }

    function _getEndpointData(
        GasTransferItem[] calldata _parameters,
        bool _validate
    ) private view returns (EndpointDataItem[] memory endpointData, uint256 lzValue) {
        endpointData = new EndpointDataItem[](_parameters.length);

        for (uint256 index; index < _parameters.length; index++) {
            GasTransferItem calldata gasTransferItem = _parameters[index];

            (address dstApp, uint128 dstAppGas, bytes memory lzOptions) = _decodeParameters(
                gasTransferItem
            );

            if (_validate && (dstAppGas < minDstAppGas)) {
                revert ValidationError();
            }

            MessagingParams memory itemMessagingParams = MessagingParams(
                gasTransferItem.remoteEid,
                _addressToBytes32(dstApp),
                LZ_PAYLOAD_NONE,
                lzOptions,
                false
            );

            MessagingFee memory lzMessagingFee = endpoint.quote(itemMessagingParams, address(this));

            uint256 itemLzValue = lzMessagingFee.nativeFee;
            lzValue += itemLzValue;

            endpointData[index] = EndpointDataItem({
                lzValue: itemLzValue,
                messagingParams: itemMessagingParams
            });
        }

        if (_validate && (minReserve * _parameters.length + lzValue > msg.value)) {
            revert ValidationError();
        }
    }

    function _decodeParameters(
        GasTransferItem calldata _parameters
    ) private view returns (address dstApp, uint128 dstAppGas, bytes memory lzOptions) {
        (dstApp, dstAppGas) = abi.decode(_parameters.settings, (address, uint128));

        lzOptions = _prepareOptions(
            dstAppGas,
            _parameters.amount,
            _parameters.recipient == address(0) ? msg.sender : _parameters.recipient
        );
    }

    function _prepareOptions(
        uint128 _dstAppGas,
        uint128 _dstNativeDropAmount,
        address _dstNativeDropRecipient
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                // options type
                uint16(3), // TYPE_3
                // executor LZ receive option
                uint8(1), // WORKER_ID
                uint16(17), // option length in bytes: (optionType -> 1) + (uint128 -> 16)
                uint8(1), // OPTION_TYPE_LZRECEIVE
                _dstAppGas,
                // executor native drop option
                uint8(1), // WORKER_ID
                uint16(49), // option length in bytes: (optionType -> 1) + (uint128 -> 16) + (bytes32 -> 32)
                uint8(2), // OPTION_TYPE_NATIVE_DROP
                _dstNativeDropAmount,
                _addressToBytes32(_dstNativeDropRecipient)
            );
    }

    function _addressToBytes32(address _address) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

/**
 * @notice Emitted when the account is not a contract
 * @param account The account address
 */
error NonContractAddressError(address account);

/**
 * @notice Function to check if the account is a contract
 * @return The account contract status flag
 */
function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

/**
 * @notice Function to require an account to be a contract
 */
function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

/**
 * @notice Function to require an account to be a contract or a zero address
 */
function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

/**
 * @title ITokenBalance
 * @notice Token balance interface
 */
interface ITokenBalance {
    /**
     * @notice Getter of the token balance by the account
     * @param _account The account address
     * @return Token balance
     */
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Initial'));
}