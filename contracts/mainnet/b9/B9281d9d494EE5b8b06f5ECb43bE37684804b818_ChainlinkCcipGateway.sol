// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Called by the Router to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution.
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the OffRampRouter
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
    bool strict; // See strict sequencing details below.
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title BalanceManagement
 * @notice Base contract for the withdrawal of tokens, except for reserved ones
 */
abstract contract BalanceManagement is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Override to add reserved token addresses
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view virtual returns (bool) {
        // The function returns false by default.
        // The explicit return statement is omitted to avoid the unused parameter warning.
        // See https://github.com/ethereum/solidity/issues/5295
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

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IERC165 } from '@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/utils/introspection/IERC165.sol';
import { IAny2EVMMessageReceiver } from '@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol';
import { IRouterClient } from '@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol';
import { Client } from '@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';
import { IActionDataStructures } from '../../interfaces/IActionDataStructures.sol';
import { IGateway } from '../interfaces/IGateway.sol';
import { IGatewayClient } from '../interfaces/IGatewayClient.sol';
import { IVariableBalanceRecords } from '../../interfaces/IVariableBalanceRecords.sol';
import { IVariableBalanceRecordsProvider } from '../../interfaces/IVariableBalanceRecordsProvider.sol';
import { GatewayBase } from '../GatewayBase.sol';
import { SystemVersionId } from '../../SystemVersionId.sol';
import { ZeroAddressError } from '../../Errors.sol';
import '../../helpers/AddressHelper.sol' as AddressHelper;
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title ChainlinkCcipGateway
 * @notice The contract implementing the cross-chain messaging logic specific to Chainlink CCIP
 */
contract ChainlinkCcipGateway is
    SystemVersionId,
    GatewayBase,
    IAny2EVMMessageReceiver,
    IERC165,
    IActionDataStructures
{
    /**
     * @notice Chain ID pair structure
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    struct ChainIdPair {
        uint256 standardId;
        uint64 ccipId;
    }

    /**
     * @dev CCIP endpoint reference
     */
    IRouterClient public endpoint;

    /**
     * @dev Variable balance records contract reference for targetGasEstimate
     */
    IVariableBalanceRecords public variableBalanceRecords;

    /**
     * @dev Contract self-reference for targetGasEstimate
     */
    ChainlinkCcipGateway public self;

    /**
     * @dev The correspondence between standard EVM chain IDs and CCIP chain selectors
     */
    mapping(uint256 /*standardId*/ => uint64 /*ccipId*/) public standardToCcipChainId;

    /**
     * @dev The correspondence between CCIP chain selectors and standard EVM chain IDs
     */
    mapping(uint64 /*ccipId*/ => uint256 /*standardId*/) public ccipToStandardChainId;

    /**
     * @dev The default value of minimum target gas
     */
    uint256 public minTargetGasDefault;

    /**
     * @dev The custom values of minimum target gas by standard chain IDs
     */
    mapping(uint256 /*standardChainId*/ => DataStructures.OptionalValue /*minTargetGas*/)
        public minTargetGasCustom;

    /**
     * @dev The address of the processing fee collector
     */
    address public processingFeeCollector;

    address private constant ESTIMATOR_ADDRESS = 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa;
    uint64 private constant ESTIMATE_SOURCE_CCIP_CHAIN_ID =
        uint64(uint256(keccak256('Source - CCIP Chain ID')));
    uint256 private constant ESTIMATE_SOURCE_STANDARD_CHAIN_ID =
        uint256(keccak256('Source - EVM Chain ID'));
    bytes32 private constant ESTIMATE_CCIP_MESSAGE_ID = keccak256('CCIP Message ID');
    address private constant ESTIMATE_SOURCE_ADDRESS = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpointAddress The address of the cross-chain endpoint contract
     */
    event SetEndpoint(address indexed endpointAddress);

    /**
     * @notice Emitted when a chain ID pair is added or updated
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    event SetChainIdPair(uint256 indexed standardId, uint64 indexed ccipId);

    /**
     * @notice Emitted when a chain ID pair is removed
     * @param standardId The standard EVM chain ID
     * @param ccipId The CCIP chain selector
     */
    event RemoveChainIdPair(uint256 indexed standardId, uint64 indexed ccipId);

    /**
     * @notice Emitted when the default value of minimum target gas is set
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasDefault(uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is set
     * @param standardChainId The standard EVM chain ID
     * @param minTargetGas The value of minimum target gas
     */
    event SetMinTargetGasCustom(uint256 standardChainId, uint256 minTargetGas);

    /**
     * @notice Emitted when the custom value of minimum target gas is removed
     * @param standardChainId The standard EVM chain ID
     */
    event RemoveMinTargetGasCustom(uint256 standardChainId);

    /**
     * @notice Emitted when the address of the processing fee collector is set
     * @param processingFeeCollector The address of the processing fee collector
     */
    event SetProcessingFeeCollector(address indexed processingFeeCollector);

    /**
     * @notice Emitted when the result info value is returned from targetGasEstimate
     * @param isSuccess The status of the action execution
     * @param gasUsed The amount of gas used
     */
    error ResultInfo(bool isSuccess, uint256 gasUsed);

    /**
     * @notice Emitted when there is no registered CCIP chain selector matching the standard EVM chain ID
     */
    error CcipChainIdNotSetError();

    /**
     * @notice Emitted when the provided target gas value is not sufficient for the message processing
     */
    error MinTargetGasError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the message processing
     */
    error ProcessingFeeError();

    /**
     * @notice Emitted when the caller is not the CCIP endpoint
     */
    error OnlyEndpointError();

    /**
     * @notice Emitted when the caller is not the estimator account
     */
    error OnlyEstimatorError();

    /**
     * @dev Modifier to check if the caller is the CCIP endpoint
     */
    modifier onlyEndpointOrSelf() {
        if (msg.sender != address(endpoint) && msg.sender != address(this)) {
            revert OnlyEndpointError();
        }

        _;
    }

    /**
     * @dev Modifier to check if the caller is the estimator account
     */
    modifier onlyEstimator() {
        if (msg.sender != ESTIMATOR_ADDRESS) {
            revert OnlyEstimatorError();
        }

        _;
    }

    /**
     * @notice Deploys the ChainlinkCcipGateway contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and CCIP chain selectors
     * @param _minTargetGasDefault The default value of minimum target gas
     * @param _minTargetGasCustomData The custom values of minimum target gas by standard chain IDs
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _processingFeeCollector The initial address of the processing fee collector
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        uint256 _minTargetGasDefault,
        DataStructures.KeyToValue[] memory _minTargetGasCustomData,
        uint256 _targetGasReserve,
        address _processingFeeCollector,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.ccipId);
        }

        _setMinTargetGasDefault(_minTargetGasDefault);

        for (uint256 index; index < _minTargetGasCustomData.length; index++) {
            DataStructures.KeyToValue memory minTargetGasCustomEntry = _minTargetGasCustomData[
                index
            ];

            _setMinTargetGasCustom(minTargetGasCustomEntry.key, minTargetGasCustomEntry.value);
        }

        _setTargetGasReserve(_targetGasReserve);

        _setProcessingFeeCollector(_processingFeeCollector);

        _initEstimate();

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Sets the gateway client contract reference
     * @param _clientAddress The gateway client contract address
     */
    function setClient(address payable _clientAddress) external virtual override onlyManager {
        AddressHelper.requireContract(_clientAddress);

        client = IGatewayClient(_clientAddress);

        variableBalanceRecords = IVariableBalanceRecordsProvider(_clientAddress)
            .variableBalanceRecords();

        emit SetClient(_clientAddress);
    }

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpointAddress The address of the cross-chain endpoint contract
     */
    function setEndpoint(address _endpointAddress) external onlyManager {
        _setEndpoint(_endpointAddress);
    }

    /**
     * @notice Adds or updates registered chain ID pairs
     * @param _chainIdPairs The list of chain ID pairs
     */
    function setChainIdPairs(ChainIdPair[] calldata _chainIdPairs) external onlyManager {
        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair calldata chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.ccipId);
        }
    }

    /**
     * @notice Removes registered chain ID pairs
     * @param _standardChainIds The list of standard EVM chain IDs
     */
    function removeChainIdPairs(uint256[] calldata _standardChainIds) external onlyManager {
        for (uint256 index; index < _standardChainIds.length; index++) {
            uint256 standardId = _standardChainIds[index];

            _removeChainIdPair(standardId);
        }
    }

    /**
     * @notice Sets the default value of minimum target gas
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasDefault(uint256 _minTargetGas) external onlyManager {
        _setMinTargetGasDefault(_minTargetGas);
    }

    /**
     * @notice Sets the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @param _minTargetGas The value of minimum target gas
     */
    function setMinTargetGasCustom(
        uint256 _standardChainId,
        uint256 _minTargetGas
    ) external onlyManager {
        _setMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    /**
     * @notice Removes the custom value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     */
    function removeMinTargetGasCustom(uint256 _standardChainId) external onlyManager {
        _removeMinTargetGasCustom(_standardChainId);
    }

    /**
     * @notice Sets the address of the processing fee collector
     * @param _processingFeeCollector The address of the processing fee collector
     */
    function setProcessingFeeCollector(address _processingFeeCollector) external onlyManager {
        _setProcessingFeeCollector(_processingFeeCollector);
    }

    /**
     * @notice Send a cross-chain message
     * @dev The settings parameter contains ABI-encoded values (targetGas, processingFee)
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable onlyClient whenNotPaused {
        (address peerAddress, uint64 targetCcipChainId) = _checkPeer(_targetChainId);

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        // - - - Processing fee transfer - - -

        if (msg.value < processingFee) {
            revert ProcessingFeeError();
        }

        if (processingFee > 0 && processingFeeCollector != address(0)) {
            TransferHelper.safeTransferNative(processingFeeCollector, processingFee);
        }

        // - - -

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _createCcipMessage(
            peerAddress,
            _message,
            adapterParameters
        );

        // Send the message
        endpoint.ccipSend{ value: msg.value - processingFee }(targetCcipChainId, evm2AnyMessage);
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     * @param _message The structure containing the message data
     */
    function ccipReceive(
        Client.Any2EVMMessage memory _message
    ) external override nonReentrant onlyEndpointOrSelf {
        if (paused()) {
            emit TargetPausedFailure();

            return;
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return;
        }

        uint256 sourceStandardChainId = ccipToStandardChainId[_message.sourceChainSelector];

        address fromAddress = abi.decode(_message.sender, (address));

        bool condition = sourceStandardChainId != 0 &&
            fromAddress != address(0) &&
            fromAddress == peerMap[sourceStandardChainId];

        if (!condition) {
            emit TargetFromAddressFailure(sourceStandardChainId, fromAddress);

            return;
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            emit TargetGasReserveFailure(sourceStandardChainId);

            return;
        }

        try
            client.handleExecutionPayload{ gas: gasAllowed }(sourceStandardChainId, _message.data)
        {} catch {
            emit TargetExecutionFailure();
        }
    }

    /**
     * @notice Gas consumption estimate on the target chain
     * @param _targetMessage The content of the cross-chain message
     */
    function estimateTarget(
        TargetMessage calldata _targetMessage
    ) external onlyEstimator whenNotPaused {
        uint256 variableBalanceBefore = variableBalanceRecords.getAccountBalance(
            _targetMessage.targetRecipient,
            _targetMessage.vaultType
        );

        bytes memory payloadData = abi.encode(_targetMessage);

        Client.Any2EVMMessage memory ccipMessage = Client.Any2EVMMessage({
            messageId: ESTIMATE_CCIP_MESSAGE_ID,
            sourceChainSelector: ESTIMATE_SOURCE_CCIP_CHAIN_ID,
            sender: abi.encode(ESTIMATE_SOURCE_ADDRESS),
            data: payloadData,
            destTokenAmounts: new Client.EVMTokenAmount[](0)
        });

        uint256 gasBefore = gasleft();

        // - - - Target chain actions - - -

        self.ccipReceive(ccipMessage);

        // - - -

        uint256 gasUsed = gasBefore - gasleft();

        uint256 variableBalanceAfter = variableBalanceRecords.getAccountBalance(
            _targetMessage.targetRecipient,
            _targetMessage.vaultType
        );

        bool isSuccess = (variableBalanceAfter == variableBalanceBefore);

        revert ResultInfo(isSuccess, gasUsed);
    }

    /**
     * @notice Cross-chain message fee estimation
     * @dev The settings parameter contains ABI-encoded values (targetGas, processingFee)
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     * @return Message fee
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256) {
        (address peerAddress, uint64 targetCcipChainId) = _checkPeer(_targetChainId);

        (bytes memory adapterParameters, uint256 processingFee) = _checkSettings(
            _settings,
            _targetChainId
        );

        Client.EVM2AnyMessage memory ccipMessage = _createCcipMessage(
            peerAddress,
            _message,
            adapterParameters
        );

        uint256 endpointNativeFee = endpoint.getFee(targetCcipChainId, ccipMessage);

        return endpointNativeFee + processingFee;
    }

    /**
     * @notice IERC165 supports an interface ID
     * @param _interfaceId The interface ID to check
     * @return true if the interface ID is supported
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return
            _interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            _interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice The value of minimum target gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @return The value of minimum target gas
     */
    function minTargetGas(uint256 _standardChainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = minTargetGasCustom[_standardChainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        return minTargetGasDefault;
    }

    function _setEndpoint(address _endpointAddress) private {
        AddressHelper.requireContract(_endpointAddress);

        endpoint = IRouterClient(_endpointAddress);

        emit SetEndpoint(_endpointAddress);
    }

    function _setChainIdPair(uint256 _standardId, uint64 _ccipId) private {
        standardToCcipChainId[_standardId] = _ccipId;
        ccipToStandardChainId[_ccipId] = _standardId;

        emit SetChainIdPair(_standardId, _ccipId);
    }

    function _removeChainIdPair(uint256 _standardId) private {
        uint64 ccipId = standardToCcipChainId[_standardId];

        delete standardToCcipChainId[_standardId];
        delete ccipToStandardChainId[ccipId];

        emit RemoveChainIdPair(_standardId, ccipId);
    }

    function _setMinTargetGasDefault(uint256 _minTargetGas) private {
        minTargetGasDefault = _minTargetGas;

        emit SetMinTargetGasDefault(_minTargetGas);
    }

    function _setMinTargetGasCustom(uint256 _standardChainId, uint256 _minTargetGas) private {
        minTargetGasCustom[_standardChainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _minTargetGas
        });

        emit SetMinTargetGasCustom(_standardChainId, _minTargetGas);
    }

    function _removeMinTargetGasCustom(uint256 _standardChainId) private {
        delete minTargetGasCustom[_standardChainId];

        emit RemoveMinTargetGasCustom(_standardChainId);
    }

    function _setProcessingFeeCollector(address _processingFeeCollector) private {
        processingFeeCollector = _processingFeeCollector;

        emit SetProcessingFeeCollector(_processingFeeCollector);
    }

    function _checkPeer(
        uint256 _chainId
    ) private view returns (address peerAddress, uint64 ccipChainId) {
        peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        ccipChainId = standardToCcipChainId[_chainId];

        if (ccipChainId == 0) {
            revert CcipChainIdNotSetError();
        }
    }

    function _checkSettings(
        bytes calldata _settings,
        uint256 _targetChainId
    ) private view returns (bytes memory adapterParameters, uint256 processingFee) {
        uint256 targetGas;
        (targetGas, processingFee) = abi.decode(_settings, (uint256, uint256));

        uint256 minTargetGasValue = minTargetGas(_targetChainId);

        if (targetGas < minTargetGasValue) {
            revert MinTargetGasError();
        }

        adapterParameters = Client._argsToBytes(
            Client.EVMExtraArgsV1({ gasLimit: targetGas, strict: false })
        );
    }

    function _createCcipMessage(
        address _peerAddress,
        bytes calldata _message,
        bytes memory _adapterParameters
    ) private pure returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_peerAddress), // ABI-encoded receiver address
                data: _message,
                tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array indicating no tokens are being sent
                extraArgs: _adapterParameters,
                feeToken: address(0) // Native token
            });
    }

    function _initEstimate() private {
        self = this;

        peerMap[ESTIMATE_SOURCE_STANDARD_CHAIN_ID] = ESTIMATE_SOURCE_ADDRESS;
        ccipToStandardChainId[ESTIMATE_SOURCE_CCIP_CHAIN_ID] = ESTIMATE_SOURCE_STANDARD_CHAIN_ID;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IGateway } from './interfaces/IGateway.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { BalanceManagement } from '../BalanceManagement.sol';
import { Pausable } from '../Pausable.sol';
import { TargetGasReserve } from './TargetGasReserve.sol';
import { ZeroAddressError } from '../Errors.sol';
import '../helpers/AddressHelper.sol' as AddressHelper;
import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title GatewayBase
 * @notice Base contract that implements the cross-chain gateway logic
 */
abstract contract GatewayBase is
    Pausable,
    ReentrancyGuard,
    TargetGasReserve,
    BalanceManagement,
    IGateway
{
    /**
     * @dev Gateway client contract reference
     */
    IGatewayClient public client;

    /**
     * @dev Registered peer gateway addresses by the chain ID
     */
    mapping(uint256 /*peerChainId*/ => address /*peerAddress*/) public peerMap;

    /**
     * @dev Registered peer gateway chain IDs
     */
    uint256[] public peerChainIdList;

    /**
     * @dev Registered peer gateway chain ID indices
     */
    mapping(uint256 /*peerChainId*/ => DataStructures.OptionalValue /*peerChainIdIndex*/)
        public peerChainIdIndexMap;

    /**
     * @notice Emitted when the gateway client contract reference is set
     * @param clientAddress The gateway client contract address
     */
    event SetClient(address indexed clientAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is added or updated
     * @param chainId The chain ID of the registered peer gateway
     * @param peerAddress The address of the registered peer gateway contract
     */
    event SetPeer(uint256 indexed chainId, address indexed peerAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is removed
     * @param chainId The chain ID of the registered peer gateway
     */
    event RemovePeer(uint256 indexed chainId);

    /**
     * @notice Emitted when the target chain gateway is paused
     */
    event TargetPausedFailure();

    /**
     * @notice Emitted when the target chain gateway client contract is not set
     */
    event TargetClientNotSetFailure();

    /**
     * @notice Emitted when the message source address does not match the registered peer gateway on the target chain
     * @param sourceChainId The ID of the message source chain
     * @param fromAddress The address of the message source
     */
    event TargetFromAddressFailure(uint256 indexed sourceChainId, address indexed fromAddress);

    /**
     * @notice Emitted when the gas reserve on the target chain does not allow further action processing
     * @param sourceChainId The ID of the message source chain
     */
    event TargetGasReserveFailure(uint256 indexed sourceChainId);

    /**
     * @notice Emitted when the gateway client execution on the target chain fails
     */
    event TargetExecutionFailure();

    /**
     * @notice Emitted when the caller is not the gateway client contract
     */
    error OnlyClientError();

    /**
     * @notice Emitted when the peer config address for the current chain does not match the current contract
     */
    error PeerAddressMismatchError();

    /**
     * @notice Emitted when the peer gateway address for the specified chain is not set
     */
    error PeerNotSetError();

    /**
     * @notice Emitted when the chain ID is not set
     */
    error ZeroChainIdError();

    /**
     * @dev Modifier to check if the caller is the gateway client contract
     */
    modifier onlyClient() {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    /**
     * @notice Sets the gateway client contract reference
     * @param _clientAddress The gateway client contract address
     */
    function setClient(address payable _clientAddress) external virtual onlyManager {
        AddressHelper.requireContract(_clientAddress);

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    /**
     * @notice Adds or updates registered peer gateways
     * @param _peers Chain IDs and addresses of peer gateways
     */
    function setPeers(
        DataStructures.KeyToAddressValue[] calldata _peers
    ) external virtual onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow the same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    /**
     * @notice Removes registered peer gateways
     * @param _chainIds Peer gateway chain IDs
     */
    function removePeers(uint256[] calldata _chainIds) external virtual onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow the same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
    }

    /**
     * @notice Getter of the peer gateway count
     * @return The peer gateway count
     */
    function peerCount() external view virtual returns (uint256) {
        return peerChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of the peer gateway chain IDs
     * @return The complete list of the peer gateway chain IDs
     */
    function fullPeerChainIdList() external view virtual returns (uint256[] memory) {
        return peerChainIdList;
    }

    function _setPeer(uint256 _chainId, address _peerAddress) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        DataStructures.combinedMapSet(
            peerMap,
            peerChainIdList,
            peerChainIdIndexMap,
            _chainId,
            _peerAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        DataStructures.combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function _checkPeerAddress(uint256 _chainId) internal virtual returns (address) {
        address peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        return peerAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGateway
 * @notice Cross-chain gateway interface
 */
interface IGateway {
    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGatewayClient
 * @notice Cross-chain gateway client interface
 */
interface IGatewayClient {
    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;

    /**
     * @notice The standard "receive" function
     */
    receive() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from '../roles/ManagerRole.sol';

/**
 * @title TargetGasReserve
 * @notice Base contract that implements the gas reserve logic for the target chain actions
 */
abstract contract TargetGasReserve is ManagerRole {
    /**
     * @dev The target chain gas reserve value
     */
    uint256 public targetGasReserve;

    /**
     * @notice Emitted when the target chain gas reserve value is set
     * @param gasReserve The target chain gas reserve value
     */
    event SetTargetGasReserve(uint256 gasReserve);

    /**
     * @notice Sets the target chain gas reserve value
     * @param _gasReserve The target chain gas reserve value
     */
    function setTargetGasReserve(uint256 _gasReserve) external onlyManager {
        _setTargetGasReserve(_gasReserve);
    }

    function _setTargetGasReserve(uint256 _gasReserve) internal virtual {
        targetGasReserve = _gasReserve;

        emit SetTargetGasReserve(_gasReserve);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Optional value structure
 * @dev Is used in mappings to allow zero values
 * @param isSet Value presence flag
 * @param value Numeric value
 */
struct OptionalValue {
    bool isSet;
    uint256 value;
}

/**
 * @notice Key-to-value structure
 * @dev Is used as an array parameter item to perform multiple key-value settings
 * @param key Numeric key
 * @param value Numeric value
 */
struct KeyToValue {
    uint256 key;
    uint256 value;
}

/**
 * @notice Key-to-value structure for address values
 * @dev Is used as an array parameter item to perform multiple key-value settings with address values
 * @param key Numeric key
 * @param value Address value
 */
struct KeyToAddressValue {
    uint256 key;
    address value;
}

/**
 * @notice Address-to-flag structure
 * @dev Is used as an array parameter item to perform multiple settings
 * @param account Account address
 * @param flag Flag value
 */
struct AccountToFlag {
    address account;
    bool flag;
}

/**
 * @notice Emitted when a list exceeds the size limit
 */
error ListSizeLimitError();

/**
 * @notice Sets or updates a value in a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @param _value The address value
 * @param _sizeLimit The map and list size limit
 * @return isNewKey True if the key was just added, otherwise false
 */
function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value,
    uint256 _sizeLimit
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key, _sizeLimit);
    }

    _map[_key] = _value;
}

/**
 * @notice Removes a value from a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @return isChanged True if the combined map was changed, otherwise false
 */
function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

/**
 * @notice Adds a value to a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds a value to a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds or removes a value to/from a unique address value list (a list with value index mapping)
 * @dev The list size limit is checked on items adding only
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _flag The value inclusion flag
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag,
    uint256 _sizeLimit
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value, _sizeLimit)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an attempt to burn a token fails
 */
error TokenBurnError();

/**
 * @notice Emitted when an attempt to mint a token fails
 */
error TokenMintError();

/**
 * @notice Emitted when a zero address is specified where it is not allowed
 */
error ZeroAddressError();

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
 * @notice Function to check if the available gas matches the specified gas reserve value
 * @param _gasReserve Gas reserve value
 * @return hasGasReserve Flag of gas reserve availability
 * @return gasAllowed The remaining gas quantity taking the reserve into account
 */
function checkGasReserve(
    uint256 _gasReserve
) view returns (bool hasGasReserve, uint256 gasAllowed) {
    uint256 gasLeft = gasleft();

    hasGasReserve = gasLeft >= _gasReserve;
    gasAllowed = hasGasReserve ? gasLeft - _gasReserve : 0;
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
 * @title IActionDataStructures
 * @notice Action data structure declarations
 */
interface IActionDataStructures {
    /**
     * @notice Single-chain action data structure
     * @param fromTokenAddress The address of the input token
     * @param toTokenAddress The address of the output token
     * @param swapInfo The data for the single-chain swap
     * @param recipient The address of the recipient
     */
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    /**
     * @notice Cross-chain action data structure
     * @param gatewayType The numeric type of the cross-chain gateway
     * @param vaultType The numeric type of the vault
     * @param sourceTokenAddress The address of the input token on the source chain
     * @param sourceSwapInfo The data for the source chain swap
     * @param targetChainId The action target chain ID
     * @param targetTokenAddress The address of the output token on the destination chain
     * @param targetSwapInfoOptions The list of data options for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewaySettings The gateway-specific settings data
     */
    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
        bytes gatewaySettings;
    }

    /**
     * @notice Token swap data structure
     * @param fromAmount The quantity of the token
     * @param routerType The numeric type of the swap router
     * @param routerData The data for the swap router call
     */
    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    /**
     * @notice Cross-chain message data structure
     * @param actionId The unique identifier of the cross-chain action
     * @param sourceSender The address of the sender on the source chain
     * @param vaultType The numeric type of the vault
     * @param targetTokenAddress The address of the output token on the target chain
     * @param targetSwapInfo The data for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     */
    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
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
 * @title IVariableBalanceRecords
 * @notice Variable balance records interface
 */
interface IVariableBalanceRecords {
    /**
     * @notice Increases the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     * @param _amount The amount by which to increase the variable balance
     */
    function increaseBalance(address _account, uint256 _vaultType, uint256 _amount) external;

    /**
     * @notice Clears the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function clearBalance(address _account, uint256 _vaultType) external;

    /**
     * @notice Getter of the variable balance by the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function getAccountBalance(
        address _account,
        uint256 _vaultType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IVariableBalanceRecords } from './IVariableBalanceRecords.sol';

/**
 * @title IVariableBalanceRecordsProvider
 * @notice The variable balance records provider interface
 */
interface IVariableBalanceRecordsProvider {
    /**
     * @notice Getter of the variable balance records contract reference
     * @return The variable balance records contract reference
     */
    function variableBalanceRecords() external returns (IVariableBalanceRecords);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

/**
 * @title Pausable
 * @notice Base contract that implements the emergency pause mechanism
 */
abstract contract Pausable is PausableBase, ManagerRole {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

/**
 * @title ManagerRole
 * @notice Base contract that implements the Manager role.
 * The manager role is a high-permission role for core team members only.
 * Managers can set vaults and routers addresses, fees, cross-chain protocols,
 * and other parameters for Interchain (cross-chain) swaps and single-network swaps.
 * Please note, the manager role is unique for every contract,
 * hence different addresses may be assigned as managers for different contracts.
 */
abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    /**
     * @notice Emitted when the Manager role status for the account is updated
     * @param account The account address
     * @param value The Manager role status flag
     */
    event SetManager(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the Manager role status for the account is renounced
     * @param account The account address
     */
    event RenounceManagerRole(address indexed account);

    /**
     * @notice Emitted when the caller is not a Manager role bearer
     */
    error OnlyManagerError();

    /**
     * @dev Modifier to check if the caller is a Manager role bearer
     */
    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    /**
     * @notice Updates the Manager role status for the account
     * @param _account The account address
     * @param _value The Manager role status flag
     */
    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    /**
     * @notice Renounces the Manager role
     */
    function renounceManagerRole() external onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    /**
     * @notice Getter of the Manager role bearer count
     * @return The Manager role bearer count
     */
    function managerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Manager role bearers
     * @return The complete list of the Manager role bearers
     */
    function fullManagerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Manager role bearer status
     * @param _account The account address
     */
    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title RoleBearers
 * @notice Base contract that implements role-based access control
 * @dev A custom implementation providing full role bearer lists
 */
abstract contract RoleBearers {
    mapping(bytes32 /*roleKey*/ => address[] /*roleBearers*/) private roleBearerTable;
    mapping(bytes32 /*roleKey*/ => mapping(address /*account*/ => DataStructures.OptionalValue /*status*/))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
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