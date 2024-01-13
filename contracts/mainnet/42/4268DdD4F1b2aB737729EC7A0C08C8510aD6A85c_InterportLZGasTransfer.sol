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

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

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

/**
 * @title ILayerZeroEndpoint
 * @notice LayerZero endpoint interface
 */
interface ILayerZeroEndpoint {
    /**
     * @notice Send a cross-chain message
     * @param _dstChainId The destination chain identifier
     * @param _destination Remote address concatenated with local address packed into 40 bytes
     * @param _payload The message content
     * @param _refundAddress Refund the additional amount to this address
     * @param _zroPaymentAddress The address of the ZRO token holder who would pay for the transaction
     * @param _adapterParam Parameters for the adapter service
     */
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParam
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _dstChainId The destination chain identifier
     * @param _userApplication The application address on the source chain
     * @param _payload The message content
     * @param _payInZRO If false, the user application pays the protocol fee in the native token
     * @param _adapterParam Parameters for the adapter service
     * @return nativeFee The native token fee for the message
     * @return zroFee The ZRO token fee for the message
     */
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ILayerZeroRelayer
 * @notice LayerZero relayer interface
 */
interface ILayerZeroRelayer {
    /**
     * @notice Destination config lookup
     * @param _chainId The chain identifier
     * @param _outboundProofType The type of the outbound proof
     * @return dstNativeAmtCap The native token amount cap on the destination chain
     * @return baseGas The base gas value
     * @return gasPerByte The gas value per byte
     */
    function dstConfigLookup(
        uint16 _chainId,
        uint16 _outboundProofType
    ) external view returns (uint128 dstNativeAmtCap, uint64 baseGas, uint64 gasPerByte);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ILayerZeroResumeReceive
 * @notice LayerZero queue unblocking interface
 */
interface ILayerZeroResumeReceive {
    /**
     * @notice Unblocks the LayerZero message queue
     * @param _srcChainId The source chain identifier
     * @param _srcAddress Remote address concatenated with local address packed into 40 bytes
     */
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ILayerZeroEndpoint } from '../crosschain/layerzero/interfaces/ILayerZeroEndpoint.sol';
import { ILayerZeroRelayer } from '../crosschain/layerzero/interfaces/ILayerZeroRelayer.sol';
import { ILayerZeroResumeReceive } from '../crosschain/layerzero/interfaces/ILayerZeroResumeReceive.sol';
import { OwnerManageable } from '../access/OwnerManageable.sol';
import { SystemVersionId } from '../SystemVersionId.sol';
import '../helpers/AddressHelper.sol' as AddressHelper;

/**
 * @title InterportLZGasTransfer
 * @notice Gas transfer contract
 */
contract InterportLZGasTransfer is SystemVersionId, OwnerManageable {
    /**
     * @notice Gas transfer parameter data structure
     * @param lzChainId LayerZero-specific chain identifier
     * @param recipient The address of the gas transfer recipient
     * @param amount Gas transfer amount
     * @param settings Gas transfer settings
     */
    struct GasTransferParameters {
        uint16 lzChainId;
        address recipient;
        uint256 amount;
        bytes settings;
    }

    /**
     * @dev The address of the cross-chain endpoint
     */
    address public lzEndpoint;

    /**
     * @dev The address of the cross-chain relayer
     */
    address public lzRelayer;

    uint16 private constant LZ_ADAPTER_PARAMETERS_VERSION = 2;
    bytes private constant LZ_PAYLOAD_NONE = '';
    uint256 private minDstGas;
    uint256 private minReserve;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpoint The cross-chain endpoint contract address
     */
    event SetEndpoint(address indexed endpoint);

    /**
     * @notice Emitted when the cross-chain relayer contract reference is set
     * @param relayer The cross-chain relayer contract address
     */
    event SetRelayer(address indexed relayer);

    /**
     * @notice Emitted when the parameter validation results in an error
     */
    error ValidationError();

    /**
     * @notice Initializes the InterportLZGasTransfer contract
     * @param _lzEndpoint The cross-chain endpoint contract address
     * @param _lzRelayer The cross-chain relayer contract address
     * @param _validation The initial validation data
     * @param _owner The address of the initial owner of the contract
     */
    constructor(address _lzEndpoint, address _lzRelayer, bytes memory _validation, address _owner) {
        _setEndpoint(_lzEndpoint);
        _setRelayer(_lzRelayer);
        _setValidation(_validation);

        _initOwner(_owner);
    }

    /**
     * @notice The standard "receive" function
     */
    receive() external payable {}

    /**
     * @notice Performs a gas transfer action
     * @param _parameters Gas transfer parameters
     */
    function gasTransfer(
        GasTransferParameters calldata _parameters
    ) external payable whenNotPaused {
        (uint256 lzValue, address dstApp, bytes memory lzAdapterParameters) = _getEndpointData(
            _parameters,
            true
        );

        ILayerZeroEndpoint(lzEndpoint).send{ value: lzValue }(
            _parameters.lzChainId,
            abi.encodePacked(dstApp, address(this)),
            LZ_PAYLOAD_NONE,
            payable(this),
            address(0),
            lzAdapterParameters
        );
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     */
    function lzReceive(uint16, bytes calldata, uint64, bytes calldata) external {}

    /**
     * @notice Unblocks the cross-chain message queue
     * @param _lzSourceChainId The source chain identifier (LayerZero-specific)
     * @param _sourceApp The source chain app address
     */
    function resumeReceive(uint16 _lzSourceChainId, address _sourceApp) external {
        ILayerZeroResumeReceive(lzEndpoint).forceResumeReceive(
            _lzSourceChainId,
            abi.encodePacked(_sourceApp, address(this))
        );
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _lzEndpoint The cross-chain endpoint contract address
     */
    function setEndpoint(address _lzEndpoint) external onlyOwner {
        _setEndpoint(_lzEndpoint);
    }

    /**
     * @notice Sets the cross-chain relayer contract reference
     * @param _lzRelayer The cross-chain relayer contract address
     */
    function setRelayer(address _lzRelayer) external onlyOwner {
        _setRelayer(_lzRelayer);
    }

    /**
     * @notice Sets the validation data
     * @param _validation The validation data
     */
    function setValidation(bytes memory _validation) external onlyOwner {
        _setValidation(_validation);
    }

    /**
     * @notice Source chain tx value estimation
     * @param _parameters Gas transfer parameters
     * @return lzValue The source chain tx value
     */
    function estimateSourceValue(
        GasTransferParameters calldata _parameters
    ) external view returns (uint256 lzValue) {
        (lzValue, , ) = _getEndpointData(_parameters, false);
    }

    /**
     * @notice The native token amount cap on the destination chains
     * @param _lzChainIds The destination chain identifier array (LayerZero-specific)
     * @return The native token amount cap on the destination chains
     */
    function destinationAmountCap(
        uint16[] calldata _lzChainIds
    ) external view returns (uint128[] memory) {
        uint128[] memory result = new uint128[](_lzChainIds.length);

        uint16 lzChainId;
        uint16 outboundProofType;
        uint128 cap;

        address sendLibrary = SendLibraryProvider(lzEndpoint).getSendLibraryAddress(address(this));

        for (uint256 index; index < _lzChainIds.length; index++) {
            lzChainId = _lzChainIds[index];
            outboundProofType = AppConfigProvider(sendLibrary)
                .getAppConfig(lzChainId, address(this))
                .outboundProofType;

            (cap, , ) = ILayerZeroRelayer(lzRelayer).dstConfigLookup(lzChainId, outboundProofType);

            result[index] = cap;
        }

        return result;
    }

    function _setEndpoint(address _lzEndpoint) private {
        AddressHelper.requireContract(_lzEndpoint);

        lzEndpoint = _lzEndpoint;

        emit SetEndpoint(_lzEndpoint);
    }

    function _setRelayer(address _lzRelayer) private {
        AddressHelper.requireContract(_lzRelayer);

        lzRelayer = _lzRelayer;

        emit SetRelayer(_lzRelayer);
    }

    function _setValidation(bytes memory _validation) private {
        (minDstGas, minReserve) = abi.decode(_validation, (uint256, uint256));
    }

    function _getEndpointData(
        GasTransferParameters calldata _parameters,
        bool _validate
    ) private view returns (uint256 lzValue, address dstApp, bytes memory lzAdapterParameters) {
        uint256 dstGas;

        (dstApp, dstGas, lzAdapterParameters) = _decodeParameters(_parameters);

        (lzValue, ) = ILayerZeroEndpoint(lzEndpoint).estimateFees(
            _parameters.lzChainId,
            address(this),
            LZ_PAYLOAD_NONE,
            false,
            lzAdapterParameters
        );

        if (_validate && (dstGas < minDstGas || lzValue + minReserve > msg.value)) {
            revert ValidationError();
        }
    }

    function _decodeParameters(
        GasTransferParameters calldata _parameters
    ) private view returns (address dstApp, uint256 dstGas, bytes memory lzAdapterParameters) {
        (dstApp, dstGas) = abi.decode(_parameters.settings, (address, uint256));

        lzAdapterParameters = abi.encodePacked(
            LZ_ADAPTER_PARAMETERS_VERSION,
            dstGas,
            _parameters.amount,
            _parameters.recipient == address(0) ? msg.sender : _parameters.recipient
        );
    }
}

interface SendLibraryProvider {
    function getSendLibraryAddress(
        address _userApplication
    ) external view returns (address sendLibraryAddress);
}

interface AppConfigProvider {
    struct ApplicationConfiguration {
        uint16 inboundProofLibraryVersion;
        uint64 inboundBlockConfirmations;
        address relayer;
        uint16 outboundProofType;
        uint64 outboundBlockConfirmations;
        address oracle;
    }

    function getAppConfig(
        uint16 _remoteChainId,
        address _userApplicationAddress
    ) external view returns (ApplicationConfiguration memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

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