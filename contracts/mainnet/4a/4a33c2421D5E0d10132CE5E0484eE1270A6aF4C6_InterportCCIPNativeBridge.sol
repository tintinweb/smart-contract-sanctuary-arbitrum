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
  /// @return fee returns execution fee for the message
  /// delivery to destination chain, denominated in the feeToken specified in the message.
  /// @dev Reverts with appropriate reason upon invalid message.
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
  /// @dev Reverts with appropriate reason upon invalid message.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

interface IWrappedNative is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  /// @dev RMN depends on this struct, if changing, please notify the RMN maintainers.
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

  // If extraArgs is empty bytes, the default is 200k gas limit.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `to`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address to, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `from` to `to` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

import { IRouterClient } from '@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol';
import { Client } from '@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';
import { BalanceManagementMixin } from '../../../mixins/BalanceManagementMixin.sol';
import { Pausable } from '../../../Pausable.sol';
import { SystemVersionId } from '../../../SystemVersionId.sol';
import '../../../helpers/AddressHelper.sol' as AddressHelper;

/**
 * @title InterportCCIPBridgeCore
 * @notice The core logic of the cross-chain bridging with Chainlink CCIP
 */
abstract contract InterportCCIPBridgeCore is SystemVersionId, Pausable, BalanceManagementMixin {
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
     * @dev CCIP endpoint address
     */
    address public endpoint;

    /**
     * @dev The correspondence between standard EVM chain IDs and CCIP chain selectors
     */
    mapping(uint256 /*standardId*/ => uint64 /*ccipId*/) public standardToCcipChainId;

    /**
     * @dev The correspondence between CCIP chain selectors and standard EVM chain IDs
     */
    mapping(uint64 /*ccipId*/ => uint256 /*standardId*/) public ccipToStandardChainId;

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
     * @notice Emitted when there is no registered CCIP chain selector matching the standard EVM chain ID
     */
    error CcipChainIdNotSetError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the message processing
     */
    error SendValueError();

    /**
     * @notice Emitted when the caller is not the CCIP endpoint
     */
    error OnlyEndpointError();

    /**
     * @dev Modifier to check if the caller is the CCIP endpoint
     */
    modifier onlyEndpoint() {
        if (msg.sender != endpoint) {
            revert OnlyEndpointError();
        }

        _;
    }

    /**
     * @notice Initializes the contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and CCIP chain selectors
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        for (uint256 index; index < _chainIdPairs.length; index++) {
            ChainIdPair memory chainIdPair = _chainIdPairs[index];

            _setChainIdPair(chainIdPair.standardId, chainIdPair.ccipId);
        }

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice The standard "receive" function
     * @dev Is payable to allow receiving native token funds
     */
    receive() external payable {}

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

    function _ccipSend(
        uint64 _targetCcipChainId,
        Client.EVM2AnyMessage memory _ccipMessage,
        uint256 _ccipSendValue
    ) internal virtual returns (bytes32 ccipMessageId) {
        if (msg.value < _ccipSendValue) {
            revert SendValueError();
        }

        return
            IRouterClient(endpoint).ccipSend{ value: _ccipSendValue }(
                _targetCcipChainId,
                _ccipMessage
            );
    }

    function _setEndpoint(address _endpoint) internal virtual {
        AddressHelper.requireContract(_endpoint);

        endpoint = _endpoint;

        emit SetEndpoint(_endpoint);
    }

    function _setChainIdPair(uint256 _standardId, uint64 _ccipId) internal virtual {
        standardToCcipChainId[_standardId] = _ccipId;
        ccipToStandardChainId[_ccipId] = _standardId;

        emit SetChainIdPair(_standardId, _ccipId);
    }

    function _removeChainIdPair(uint256 _standardId) internal virtual {
        uint64 ccipId = standardToCcipChainId[_standardId];

        delete standardToCcipChainId[_standardId];
        delete ccipToStandardChainId[ccipId];

        emit RemoveChainIdPair(_standardId, ccipId);
    }

    function _checkChainId(uint256 _chainId) internal view virtual returns (uint64 ccipChainId) {
        ccipChainId = standardToCcipChainId[_chainId];

        if (ccipChainId == 0) {
            revert CcipChainIdNotSetError();
        }
    }

    function _ccipGetFee(
        uint64 _targetCcipChainId,
        Client.EVM2AnyMessage memory _ccipMessage
    ) internal view virtual returns (uint256 fee) {
        return IRouterClient(endpoint).getFee(_targetCcipChainId, _ccipMessage);
    }

    function _createCcipMessage(
        address _receiverAddress, // The receiver may be an EOA or a contract
        bytes memory _data,
        Client.EVMTokenAmount[] memory _tokenAmounts,
        uint256 _targetGasLimit
    ) internal pure virtual returns (Client.EVM2AnyMessage memory) {
        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(_receiverAddress), // ABI-encoded receiver address
                data: _data,
                tokenAmounts: _tokenAmounts,
                extraArgs: Client._argsToBytes(
                    Client.EVMExtraArgsV1({ gasLimit: _targetGasLimit })
                ),
                feeToken: address(0) // Native token
            });
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IERC165 } from '@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol';
import { IAny2EVMMessageReceiver } from '@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol';
import { IWrappedNative } from '@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IWrappedNative.sol';
import { Client } from '@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';
import { CrosschainPeerMixin } from '../../crosschain/mixins/CrosschainPeerMixin.sol';
import { InterportCCIPBridgeCore } from './core/InterportCCIPBridgeCore.sol';
import { TargetAppGasMixin } from '../../crosschain/mixins/TargetAppGasMixin.sol';
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title InterportCCIPNativeBridge
 * @notice The contract bridges the native network currency (regular and wrapped tokens) with Chainlink CCIP
 */
contract InterportCCIPNativeBridge is
    InterportCCIPBridgeCore,
    CrosschainPeerMixin,
    TargetAppGasMixin,
    ReentrancyGuard,
    IAny2EVMMessageReceiver,
    IERC165
{
    /**
     * @notice The "bridgeNative" action parameters
     * @param targetChainId The message target chain ID (EVM)
     * @param targetRecipient The address of the recipient on the target chain
     * @param amount The token amount
     * @param targetAppGas The target app execution gas
     */
    struct NativeBridgeAction {
        uint256 targetChainId;
        address targetRecipient;
        uint256 amount;
        uint256 targetAppGas;
    }

    /**
     * @notice The "bridgeNative" conversion flag structure
     * @param fromWrapped The source chain token conversion flag
     * @param toWrapped The target chain token conversion flag
     */
    struct NativeBridgeFlags {
        bool fromWrapped;
        bool toWrapped;
    }

    /**
     * @notice Cross-chain message data structure
     * @param actionId The unique identifier of the cross-chain action
     * @param sourceSender The address of the sender on the source chain
     * @param toWrapped The target chain token conversion flag
     * @param targetRecipient The address of the recipient on the target chain
     */
    struct NativeBridgeMessage {
        uint256 actionId;
        address sourceSender;
        bool toWrapped;
        address targetRecipient;
    }

    /**
     * @dev The native transfer gas limit
     */
    uint256 public nativeTransferGasLimit;

    uint256 private lastActionId = block.chainid * 1e10 + 55555 ** 2;

    /**
     * @notice Native bridge action source event
     * @param actionId The ID of the action
     * @param targetChainId The ID of the target chain
     * @param sourceSender The address of the user on the source chain
     * @param targetRecipient The address of the recipient on the target chain
     * @param fromWrapped The source chain token conversion flag
     * @param toWrapped The target chain token conversion flag
     * @param amount The amount of the asset used for the action
     * @param reserve The reserve amount
     * @param ccipMessageId The CCIP message ID
     * @param timestamp The timestamp of the action (in seconds)
     */
    event NativeBridgeActionSource(
        uint256 indexed actionId,
        uint256 targetChainId,
        address indexed sourceSender,
        address targetRecipient,
        bool fromWrapped,
        bool toWrapped,
        uint256 amount,
        uint256 reserve,
        bytes32 indexed ccipMessageId,
        uint256 timestamp
    );

    /**
     * @notice Native bridge action target event
     * @param actionId The ID of the action
     * @param sourceChainId The ID of the source chain
     * @param toWrapped The target chain token conversion flag
     * @param defaultWrapped The default conversion flag
     * @param timestamp The timestamp of the action (in seconds)
     */
    event NativeBridgeActionTarget(
        uint256 indexed actionId,
        uint256 indexed sourceChainId,
        bool toWrapped,
        bool defaultWrapped,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the target chain app is paused
     */
    event TargetPausedFailure();

    /**
     * @notice Emitted when the message source address does not match the registered peer app on the target chain
     * @param sourceChainId The ID of the message source chain
     * @param fromAddress The address of the message source
     */
    event TargetFromAddressFailure(uint256 indexed sourceChainId, address indexed fromAddress);

    /**
     * @notice Emitted when the message token list is not valid
     */
    event TargetTokenListFailure();

    /**
     * @notice Emitted when the native transfer gas limit is set
     * @param nativeTransferGasLimit The native transfer gas limit
     */
    event SetNativeTransferGasLimit(uint256 nativeTransferGasLimit);

    /**
     * @notice Initializes the contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _chainIdPairs The correspondence between standard EVM chain IDs and CCIP chain selectors
     * @param _minTargetAppGasDefault The default value of minimum target app gas
     * @param _minTargetAppGasCustomData The custom values of minimum target app gas by standard chain IDs
     * @param _nativeTransferGasLimit The gas limit for the native transfer
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ChainIdPair[] memory _chainIdPairs,
        uint256 _minTargetAppGasDefault,
        DataStructures.KeyToValue[] memory _minTargetAppGasCustomData,
        uint256 _nativeTransferGasLimit,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    )
        InterportCCIPBridgeCore(
            _endpointAddress,
            _chainIdPairs,
            _owner,
            _managers,
            _addOwnerToManagers
        )
        TargetAppGasMixin(_minTargetAppGasDefault, _minTargetAppGasCustomData)
    {
        _setNativeTransferGasLimit(_nativeTransferGasLimit);
    }

    /**
     * @notice Cross-chain bridging of the native token (both regular and wrapped)
     * @param _action The action parameters
     * @param _flags The action flags
     * @param _ccipSendValue The CCIP processing value
     */
    function bridgeNative(
        NativeBridgeAction calldata _action,
        NativeBridgeFlags calldata _flags,
        uint256 _ccipSendValue
    )
        external
        payable
        whenNotPaused
        nonReentrant
        returns (uint256 actionId, bytes32 ccipMessageId)
    {
        uint64 targetCcipChainId = _checkChainId(_action.targetChainId);
        address peerAddress = _checkPeerAddress(_action.targetChainId);

        _checkTargetAppGas(_action.targetChainId, _action.targetAppGas);

        lastActionId++;
        actionId = lastActionId;

        address wrappedNativeToken = _getWrappedNative();

        if (_flags.fromWrapped) {
            TransferHelper.safeTransferFrom(
                wrappedNativeToken,
                msg.sender,
                address(this),
                _action.amount
            );
        } else {
            IWrappedNative(wrappedNativeToken).deposit{ value: _action.amount }();
        }

        TransferHelper.safeApprove(wrappedNativeToken, endpoint, _action.amount);

        {
            bytes memory bridgeMessageData = abi.encode(
                NativeBridgeMessage({
                    actionId: actionId,
                    sourceSender: msg.sender,
                    toWrapped: _flags.toWrapped,
                    targetRecipient: _action.targetRecipient == address(0)
                        ? msg.sender
                        : _action.targetRecipient
                })
            );

            // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
            Client.EVM2AnyMessage memory ccipMessage = _createCcipMessage(
                peerAddress,
                bridgeMessageData,
                _createTokenAmounts(wrappedNativeToken, _action.amount),
                _action.targetAppGas
            );

            // Send the message
            ccipMessageId = _ccipSend(targetCcipChainId, ccipMessage, _ccipSendValue);
        }

        TransferHelper.safeApprove(wrappedNativeToken, endpoint, 0);

        emit NativeBridgeActionSource(
            actionId,
            _action.targetChainId,
            msg.sender,
            _action.targetRecipient,
            _flags.fromWrapped,
            _flags.toWrapped,
            _action.amount,
            msg.value - _ccipSendValue,
            ccipMessageId,
            block.timestamp
        );
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain endpoint
     * @param _message The structure containing the message data
     */
    function ccipReceive(
        Client.Any2EVMMessage calldata _message
    ) external override nonReentrant onlyEndpoint {
        if (paused()) {
            emit TargetPausedFailure();

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

        address wrappedNativeToken = _getWrappedNative();

        if (
            _message.destTokenAmounts.length != 1 ||
            _message.destTokenAmounts[0].token != wrappedNativeToken
        ) {
            emit TargetTokenListFailure();

            return;
        }

        NativeBridgeMessage memory bridgeMessage = abi.decode(_message.data, (NativeBridgeMessage));

        uint256 tokenAmount = _message.destTokenAmounts[0].amount;

        bool defaultWrapped;

        if (bridgeMessage.toWrapped) {
            TransferHelper.safeTransfer(
                wrappedNativeToken,
                bridgeMessage.targetRecipient,
                tokenAmount
            );
        } else {
            IWrappedNative(wrappedNativeToken).withdraw(tokenAmount);

            uint256 gasLimit = (nativeTransferGasLimit == 0)
                ? type(uint256).max
                : nativeTransferGasLimit;

            (bool success, ) = payable(bridgeMessage.targetRecipient).call{
                value: tokenAmount,
                gas: gasLimit
            }('');

            if (!success) {
                // Send WETH to the recipient address

                IWrappedNative(wrappedNativeToken).deposit{ value: tokenAmount }();

                TransferHelper.safeTransfer(
                    wrappedNativeToken,
                    bridgeMessage.targetRecipient,
                    tokenAmount
                );

                defaultWrapped = true;
            }
        }

        emit NativeBridgeActionTarget(
            bridgeMessage.actionId,
            sourceStandardChainId,
            bridgeMessage.toWrapped,
            defaultWrapped,
            block.timestamp
        );
    }

    /**
     * @notice Sets the native transfer gas limit
     * @param _nativeTransferGasLimit The native transfer gas limit
     */
    function setNativeTransferGasLimit(uint256 _nativeTransferGasLimit) external onlyManager {
        _setNativeTransferGasLimit(_nativeTransferGasLimit);
    }

    /**
     * @notice Cross-chain message fee estimation
     * @param _action The action parameters
     * @return Message fee
     */
    function messageFee(NativeBridgeAction calldata _action) external view returns (uint256) {
        uint64 targetCcipChainId = _checkChainId(_action.targetChainId);
        address peerAddress = _checkPeerAddress(_action.targetChainId);

        _checkTargetAppGas(_action.targetChainId, _action.targetAppGas);

        bytes memory bridgeMessageData = abi.encode(
            NativeBridgeMessage({
                actionId: lastActionId + 1, // estimate only
                sourceSender: msg.sender,
                toWrapped: true, // estimate only
                targetRecipient: _action.targetRecipient == address(0)
                    ? msg.sender
                    : _action.targetRecipient
            })
        );

        Client.EVM2AnyMessage memory ccipMessage = _createCcipMessage(
            peerAddress,
            bridgeMessageData,
            _createTokenAmounts(_getWrappedNative(), _action.amount),
            _action.targetAppGas
        );

        return _ccipGetFee(targetCcipChainId, ccipMessage);
    }

    /**
     * @notice The interface support query
     * @param _interfaceId The interface identifier (ERC-165)
     * @return The interface support flag
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return
            _interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            _interfaceId == type(IERC165).interfaceId;
    }

    function _setNativeTransferGasLimit(uint256 _nativeTransferGasLimit) private {
        nativeTransferGasLimit = _nativeTransferGasLimit;

        emit SetNativeTransferGasLimit(_nativeTransferGasLimit);
    }

    function _getWrappedNative() private view returns (address) {
        return IEndpointWrappedNative(endpoint).getWrappedNative();
    }

    function _createTokenAmounts(
        address _wrappedNativeToken,
        uint256 _amount
    ) private pure returns (Client.EVMTokenAmount[] memory) {
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);

        tokenAmounts[0] = Client.EVMTokenAmount({ token: _wrappedNativeToken, amount: _amount });

        return tokenAmounts;
    }
}

interface IEndpointWrappedNative {
    function getWrappedNative() external view returns (address);
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

import { ManagerRole } from '../../roles/ManagerRole.sol';
import { ZeroAddressError } from '../../Errors.sol';
import '../../Constants.sol' as Constants;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title CrosschainPeerMixin
 * @notice The cross-chain peer mix-in logic
 */
abstract contract CrosschainPeerMixin is ManagerRole {
    /**
     * @dev Registered peer app addresses by the chain ID
     */
    mapping(uint256 /*peerChainId*/ => address /*peerAddress*/) public peerMap;

    /**
     * @dev Registered peer app chain IDs
     */
    uint256[] public peerChainIdList;

    /**
     * @dev Registered peer app chain ID indices
     */
    mapping(uint256 /*peerChainId*/ => DataStructures.OptionalValue /*peerChainIdIndex*/)
        public peerChainIdIndexMap;

    /**
     * @notice Emitted when a registered peer app contract address is added or updated
     * @param chainId The chain ID of the registered peer app
     * @param peerAddress The address of the registered peer app contract
     */
    event SetPeer(uint256 indexed chainId, address indexed peerAddress);

    /**
     * @notice Emitted when a registered peer app contract address is removed
     * @param chainId The chain ID of the registered peer app
     */
    event RemovePeer(uint256 indexed chainId);

    /**
     * @notice Emitted when the peer config address for the current chain does not match the current contract
     */
    error PeerAddressMismatchError();

    /**
     * @notice Emitted when the peer app address for the specified chain is not set
     */
    error PeerNotSetError();

    /**
     * @notice Emitted when the chain ID is not set
     */
    error ZeroChainIdError();

    /**
     * @notice Adds or updates registered peer apps
     * @param _peers Chain IDs and addresses of peer apps
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
     * @notice Removes registered peer apps
     * @param _chainIds Peer app chain IDs
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
     * @notice Getter of the peer app count
     * @return The peer app count
     */
    function peerCount() external view virtual returns (uint256) {
        return peerChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of the peer app chain IDs
     * @return The complete list of the peer app chain IDs
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

    function _checkPeerAddress(uint256 _chainId) internal view virtual returns (address) {
        address peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        return peerAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from '../../roles/ManagerRole.sol';
import '../../DataStructures.sol' as DataStructures;

/**
 * @title TargetAppGasCore
 * @notice The target app gas mix-in logic
 */
abstract contract TargetAppGasMixin is ManagerRole {
    /**
     * @dev The default value of minimum target app gas
     */
    uint256 public minTargetAppGasDefault;

    /**
     * @dev The custom values of minimum target app gas by standard chain IDs
     */
    mapping(uint256 /*standardChainId*/ => DataStructures.OptionalValue /*minTargetAppGas*/)
        public minTargetAppGasCustom;

    /**
     * @notice Emitted when the default value of minimum target app gas is set
     * @param minTargetAppGas The value of minimum target app gas
     */
    event SetMinTargetAppGasDefault(uint256 minTargetAppGas);

    /**
     * @notice Emitted when the custom value of minimum target app gas is set
     * @param standardChainId The standard EVM chain ID
     * @param minTargetAppGas The value of minimum target app gas
     */
    event SetMinTargetAppGasCustom(uint256 standardChainId, uint256 minTargetAppGas);

    /**
     * @notice Emitted when the custom value of minimum target app gas is removed
     * @param standardChainId The standard EVM chain ID
     */
    event RemoveMinTargetAppGasCustom(uint256 standardChainId);

    /**
     * @notice Emitted when the provided target app gas value is not sufficient for the message processing
     */
    error MinTargetAppGasError();

    /**
     * @notice Initializes the contract
     * @param _minTargetAppGasDefault The default value of minimum target app gas
     * @param _minTargetAppGasCustomData The custom values of minimum target app gas by standard chain IDs
     */
    constructor(
        uint256 _minTargetAppGasDefault,
        DataStructures.KeyToValue[] memory _minTargetAppGasCustomData
    ) {
        _setMinTargetAppGasDefault(_minTargetAppGasDefault);

        for (uint256 index; index < _minTargetAppGasCustomData.length; index++) {
            DataStructures.KeyToValue
                memory minTargetAppGasCustomEntry = _minTargetAppGasCustomData[index];

            _setMinTargetAppGasCustom(
                minTargetAppGasCustomEntry.key,
                minTargetAppGasCustomEntry.value
            );
        }
    }

    /**
     * @notice Sets the default value of minimum target app gas
     * @param _minTargetAppGas The value of minimum target app gas
     */
    function setMinTargetAppGasDefault(uint256 _minTargetAppGas) external virtual onlyManager {
        _setMinTargetAppGasDefault(_minTargetAppGas);
    }

    /**
     * @notice Sets the custom value of minimum target app gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @param _minTargetAppGas The value of minimum target app gas
     */
    function setMinTargetAppGasCustom(
        uint256 _standardChainId,
        uint256 _minTargetAppGas
    ) external virtual onlyManager {
        _setMinTargetAppGasCustom(_standardChainId, _minTargetAppGas);
    }

    /**
     * @notice Removes the custom value of minimum target app gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     */
    function removeMinTargetAppGasCustom(uint256 _standardChainId) external virtual onlyManager {
        _removeMinTargetAppGasCustom(_standardChainId);
    }

    /**
     * @notice The value of minimum target app gas by the standard chain ID
     * @param _standardChainId The standard EVM ID of the target chain
     * @return The value of minimum target app gas
     */
    function minTargetAppGas(uint256 _standardChainId) public view virtual returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = minTargetAppGasCustom[
            _standardChainId
        ];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        return minTargetAppGasDefault;
    }

    function _setMinTargetAppGasDefault(uint256 _minTargetAppGas) internal virtual {
        minTargetAppGasDefault = _minTargetAppGas;

        emit SetMinTargetAppGasDefault(_minTargetAppGas);
    }

    function _setMinTargetAppGasCustom(
        uint256 _standardChainId,
        uint256 _minTargetAppGas
    ) internal virtual {
        minTargetAppGasCustom[_standardChainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _minTargetAppGas
        });

        emit SetMinTargetAppGasCustom(_standardChainId, _minTargetAppGas);
    }

    function _removeMinTargetAppGasCustom(uint256 _standardChainId) internal virtual {
        delete minTargetAppGasCustom[_standardChainId];

        emit RemoveMinTargetAppGasCustom(_standardChainId);
    }

    function _checkTargetAppGas(
        uint256 _targetChainId,
        uint256 _targetAppGas
    ) internal view virtual {
        if (_targetAppGas < minTargetAppGas(_targetChainId)) {
            revert MinTargetAppGasError();
        }
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

import { ITokenBalance } from '../interfaces/ITokenBalance.sol';
import { ManagerRole } from '../roles/ManagerRole.sol';
import '../helpers/TransferHelper.sol' as TransferHelper;
import '../Constants.sol' as Constants;

/**
 * @title BalanceManagementMixin
 * @notice The balance management mix-in logic
 */
abstract contract BalanceManagementMixin is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the token cleanup
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _to The token transfer recipient address
     */
    function cleanup(address _tokenAddress, address _to) external virtual onlyManager {
        _cleanupWithAmount(_tokenAddress, _to, tokenBalance(_tokenAddress));
    }

    /**
     * @notice Performs the token cleanup using the provided amount
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _to The token transfer recipient address
     * @param _tokenAmount The amount of the token
     */
    function cleanupWithAmount(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) external virtual onlyManager {
        _cleanupWithAmount(_tokenAddress, _to, _tokenAmount);
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view virtual returns (uint256) {
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

    function _cleanupWithAmount(
        address _tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) internal virtual {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(_to, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, _to, _tokenAmount);
        }
    }
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