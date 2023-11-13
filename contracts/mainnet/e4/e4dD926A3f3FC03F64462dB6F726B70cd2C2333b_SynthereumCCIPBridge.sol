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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IAny2EVMMessageReceiver} from '../../@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol';
import {Client} from '../../@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';
import {IERC165} from '../../@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IRouterClient} from '../../@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol';

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  IRouterClient internal i_router;

  constructor(address router) {
    _setRouter(router);
  }

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    require(msg.sender == address(i_router), 'Invalid router');
    _;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message)
    external
    virtual
    onlyRouter
  {
    _ccipReceive(message);
  }

  /// @notice Set the router
  /// @param router New router
  function _setRouter(address router) internal virtual {
    require(router != address(0), 'Invalid router');
    i_router = IRouterClient(router);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /// @notice Return the current router
  /// @return i_router address
  function getRouter() public view returns (address) {
    return address(i_router);
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  function supportsInterface(bytes4 interfaceId)
    public
    pure
    virtual
    returns (bool)
  {
    return
      interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {IMintableBurnableERC20} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {Client} from '../../../@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';

/**
 * @title Synthereum CCIP bridge interface containing the open functions
 */
interface ISynthereumCCIPBridge {
  /**
   * @notice Burn tokens on this chain and trigger CCIP bridge for receiving on the destination chain
   * @param _destinationChainSelector CCIP chain selector of the destination chain
   * @param _token Address of the synth token to bridge
   * @param _amount Amount to bridge
   * @param _recipient Address to which receive synth tokens on the destination chain
   * @param _feeToken Address of the token used to pay fees for bridging
   * @return messageId CCIP output message id
   * @return fees Amount of fees to be paid
   */
  function transferTokensToDestinationChain(
    uint64 _destinationChainSelector,
    address _token,
    uint256 _amount,
    address _recipient,
    address _feeToken
  ) external payable returns (bytes32 messageId, uint256 fees);

  /**
   * @notice Check if a token is whitelisted for a destination chain
   * @param _token Address of the token on this chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if token is whitelisted, otherwise false
   */
  function isTokenWhitelisted(address _token, uint64 _chainSelector)
    external
    view
    returns (bool);

  /**
   * @notice Check if endpoints are supported for a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if endpoints are supported, otherwise false
   */
  function isEndpointSupported(uint64 _chainSelector)
    external
    view
    returns (bool);

  /**
   * @notice Check if extra args are supported for a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if extra args are supported, otherwise false
   */
  function isExtraArgsSupported(uint64 _chainSelector)
    external
    view
    returns (bool);

  /**
   * @notice Check if the fee is free on the input destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if fee is flat, otherwise false
   */
  function isFeeFree(uint64 _chainSelector) external view returns (bool);

  /**
   * @notice Amount of bridged token (negative outbound bridge, positive inbound bridge) for every chain
   * @param _token Address of the token
   */
  function getTotalBridgedAmount(address _token) external view returns (int256);

  /**
   * @notice Amount of bridged token (negative outbound bridge, positive inbound bridge) for the input chain
   * @param _token Address of the token
   * @param _destChainSelector CCIP chain selector of the destination chain
   */
  function getChainBridgedAmount(address _token, uint64 _destChainSelector)
    external
    view
    returns (int256);

  /**
   * @notice Max amount of token to be bridged on input destination chain
   * @param _token Address of the token
   * @param _destChainSelector CCIP chain selector of the destination chain
   * @return Max amount to be bridged
   */
  function getMaxChainAmount(address _token, uint64 _destChainSelector)
    external
    view
    returns (uint256);

  /**
   * @notice Get the source endpoint for the input chain
   * @param _chainSelector CCIP chain selector of the source chain
   * @return srcEndpoint Source endpoint
   */
  function getSrcEndpoint(uint64 _chainSelector)
    external
    view
    returns (address srcEndpoint);

  /**
   * @notice Get the destination endpoint for the input chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return destEndpoint Destination endpoint
   */
  function getDestEndpoint(uint64 _chainSelector)
    external
    view
    returns (address destEndpoint);

  /**
   * @notice Get the extra-args for the input destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return args GasLimit and strict
   */
  function getExtraArgs(uint64 _chainSelector)
    external
    view
    returns (Client.EVMExtraArgsV1 memory args);

  /**
   * @notice Get the address of the mapped token with the input token on the input destination chain
   * @param _srcToken Address of the token
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return destToken Address of mapped token on the destination chain
   */
  function getMappedToken(address _srcToken, uint64 _chainSelector)
    external
    view
    returns (address destToken);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
  /**
   * @notice Burns a specific amount of the caller's tokens.
   * @dev This method should be permissioned to only allow designated parties to burn tokens.
   */
  function burn(uint256 value) external;

  /**
   * @notice Mints tokens and adds them to the balance of the `to` address.
   * @dev This method should be permissioned to only allow designated parties to mint tokens.
   */
  function mint(address to, uint256 value) external returns (bool);

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IMintableBurnableERC20} from '../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {ISynthereumCCIPBridge} from './interfaces/ICCIPBridge.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeCast} from '../../@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Context} from '../../@openzeppelin/contracts/utils/Context.sol';
import {ERC2771Context} from '../common/ERC2771Context.sol';
import {ReentrancyGuard} from '../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Client} from '../../@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol';
import {CCIPReceiver} from './CCIPReceiver.sol';
import {AccessControlEnumerable} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {StandardAccessControlEnumerable} from '../common/roles/StandardAccessControlEnumerable.sol';

/**
 * @title Synthereum CCIP bridge for moving synthetic assets cross-chain
 */
contract SynthereumCCIPBridge is
  ISynthereumCCIPBridge,
  ERC2771Context,
  ReentrancyGuard,
  StandardAccessControlEnumerable,
  CCIPReceiver
{
  using Address for address payable;
  using SafeERC20 for IERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using SafeCast for uint256;

  struct MessageEndpoints {
    address contractSender;
    address contractReceiver;
  }

  struct TransferTokensCache {
    address messageReceiver;
    int256 actualBridgedAmount;
    int256 amount;
    address msgSender;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------
  ISynthereumFinder public immutable synthereumFinder;

  mapping(uint64 => MessageEndpoints) internal endpoints;

  mapping(uint64 => Client.EVMExtraArgsV1) internal extraArgs;

  mapping(IMintableBurnableERC20 => mapping(uint64 => IMintableBurnableERC20))
    internal tokensMap;

  mapping(uint64 => bool) freeFee;

  mapping(IMintableBurnableERC20 => mapping(uint64 => int256)) chainBridgedAmount;

  mapping(IMintableBurnableERC20 => int256) totalBridgedAmount;

  mapping(IMintableBurnableERC20 => mapping(uint64 => uint256)) chainMaxAmount;

  //----------------------------------------
  // Events
  //----------------------------------------
  event EndpointsSet(
    uint64 indexed chainSelector,
    address messageSender,
    address messageReceiver
  );

  event EndpointsRemoved(uint64 indexed chainSelector);

  event ExtraArgsSet(
    uint64 indexed chainSelector,
    uint256 gasLimit,
    bool strict
  );

  event ExtraArgsRemoved(uint64 indexed chainSelector);

  event TokenMapped(
    IMintableBurnableERC20 indexed sourceToken,
    uint64 indexed chainSelector,
    IMintableBurnableERC20 indexed destinationToken
  );

  event TokenUnmapped(
    IMintableBurnableERC20 indexed sourceToken,
    uint64 indexed chainSelector
  );

  event MaxChainAmountSet(
    IMintableBurnableERC20 indexed sourceToken,
    uint64 indexed chainSelector,
    uint256 maxAmount
  );

  event MaxChainAmountRemoved(
    IMintableBurnableERC20 indexed sourceToken,
    uint64 indexed chainSelector
  );

  event FreeFeeSet(uint64 indexed chainSelector, bool indexed isFree);

  // Event emitted when the tokens are burned on the source chain and the message sent to ccipi
  event TransferInitiated(
    bytes32 indexed messageId,
    uint64 indexed destinationChainSelector,
    address destinationEndpoint,
    IMintableBurnableERC20 sourceToken,
    IMintableBurnableERC20 destinationToken,
    uint256 amount,
    address sender,
    address receiver,
    address feeToken,
    uint256 fees
  );

  // Event emitted when message is received from ccip and the tokens are minted on the destination chain
  event TransferCompleted(
    bytes32 indexed messageId,
    uint64 indexed sourceChainSelector,
    address sourceEndpoint,
    IMintableBurnableERC20 sourceToken,
    IMintableBurnableERC20 destinationToken,
    uint256 amount,
    address receiver
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Constructs the SynthereumCCIPBridge contract
   * @param _synthereumFinder Synthereum finder contract
   * @param _router Chainlink CCIP router
   * @param _roles Admin and Mainteiner roles
   */
  constructor(
    ISynthereumFinder _synthereumFinder,
    address _router,
    Roles memory _roles
  ) CCIPReceiver(_router) {
    synthereumFinder = _synthereumFinder;
    _setAdmin(_roles.admin);
    _setMaintainer(_roles.maintainer);
  }

  receive() external payable {}

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Set new router
   * @notice Only maintainer can call this function
   * @param _router Address of the new router
   */
  function setRouter(address _router) external onlyMaintainer {
    _setRouter(_router);
  }

  /**
   * @notice Set sender and receiver endpoint for a chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _msgSenderEndpoint Sender endpoint for the destination chain in input
   * @param _msgReceiverEndpoint Receiver endpoint for the destination chain in input
   */
  function setEndpoints(
    uint64 _chainSelector,
    address _msgSenderEndpoint,
    address _msgReceiverEndpoint
  ) external onlyMaintainer {
    require(i_router.isChainSupported(_chainSelector), 'Chain not supported');
    require(
      _msgSenderEndpoint != address(0) && _msgReceiverEndpoint != address(0),
      'Null input endpoint'
    );
    endpoints[_chainSelector] = MessageEndpoints(
      _msgSenderEndpoint,
      _msgReceiverEndpoint
    );
    emit EndpointsSet(_chainSelector, _msgSenderEndpoint, _msgReceiverEndpoint);
  }

  /**
   * @notice Remove sender and receiver endpoint for a chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   */
  function removeEndpoints(uint64 _chainSelector) external onlyMaintainer {
    require(
      endpoints[_chainSelector].contractSender != address(0) &&
        endpoints[_chainSelector].contractReceiver != address(0),
      'Endpoints not supported'
    );
    delete endpoints[_chainSelector];
    emit EndpointsRemoved(_chainSelector);
  }

  /**
   * @notice Set extra args for a chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector
   * @param _gasLimit CCIP gas limit for executing transaction by CCIP protocol on on the destination chain in input
   * @param _strict CCIP flag for stop the execution of the queue on the input chain in case of error
   */
  function setExtraArgs(
    uint64 _chainSelector,
    uint256 _gasLimit,
    bool _strict
  ) external onlyMaintainer {
    require(i_router.isChainSupported(_chainSelector), 'Chain not supported');
    require(_gasLimit != 0, 'Null gas input');
    extraArgs[_chainSelector] = Client.EVMExtraArgsV1(_gasLimit, _strict);
    emit ExtraArgsSet(_chainSelector, _gasLimit, _strict);
  }

  /**
   * @notice Remove extra args for a chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   */
  function removeExtraArgs(uint64 _chainSelector) external onlyMaintainer {
    require(extraArgs[_chainSelector].gasLimit != 0, 'Args not supported');
    delete extraArgs[_chainSelector];
    emit ExtraArgsRemoved(_chainSelector);
  }

  /**
   * @notice Map tokens between this chain and a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _srcTokens List of tokens on this chain
   * @param _destTokens List of tokens on the destination chain in input
   */
  function setMappedTokens(
    uint64 _chainSelector,
    IMintableBurnableERC20[] calldata _srcTokens,
    IMintableBurnableERC20[] calldata _destTokens
  ) external onlyMaintainer {
    require(i_router.isChainSupported(_chainSelector), 'Chain not supported');
    uint256 tokensNumber = _srcTokens.length;
    require(tokensNumber > 0, 'No tokens passed');
    require(
      tokensNumber == _destTokens.length,
      'Src and dest tokens do not match'
    );
    for (uint256 j = 0; j < tokensNumber; ) {
      require(
        address(_srcTokens[j]) != address(0) &&
          address(_destTokens[j]) != address(0),
        'Null token'
      );
      tokensMap[_srcTokens[j]][_chainSelector] = _destTokens[j];
      emit TokenMapped(_srcTokens[j], _chainSelector, _destTokens[j]);
      unchecked {
        j++;
      }
    }
  }

  /**
   * @notice Remove mapped tokens between this chain and a destination chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _srcTokens List of tokens on this chain to be removed
   */
  function removeMappedTokens(
    uint64 _chainSelector,
    IMintableBurnableERC20[] calldata _srcTokens
  ) external onlyMaintainer {
    uint256 tokensNumber = _srcTokens.length;
    require(tokensNumber > 0, 'No tokens passed');
    for (uint256 j = 0; j < tokensNumber; ) {
      require(
        address(tokensMap[_srcTokens[j]][_chainSelector]) != address(0),
        'Token not supported'
      );
      delete tokensMap[_srcTokens[j]][_chainSelector];
      emit TokenUnmapped(_srcTokens[j], _chainSelector);
      unchecked {
        j++;
      }
    }
  }

  /**
   * @notice Set max amount of a token that can be bridged on a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _srcTokens List of tokens on this chain
   * @param _amounts List of the max amounts
   */
  function setMaxChainAmount(
    uint64 _chainSelector,
    IMintableBurnableERC20[] calldata _srcTokens,
    uint256[] calldata _amounts
  ) external onlyMaintainer {
    require(i_router.isChainSupported(_chainSelector), 'Chain not supported');
    uint256 tokensNumber = _srcTokens.length;
    require(tokensNumber > 0, 'No tokens passed');
    require(
      tokensNumber == _amounts.length,
      'Src tokens and amounts do not match'
    );
    for (uint256 j = 0; j < tokensNumber; ) {
      require(address(_srcTokens[j]) != address(0), 'Null token');
      require(_amounts[j] > 0, 'Null amount');
      chainMaxAmount[_srcTokens[j]][_chainSelector] = _amounts[j];
      emit MaxChainAmountSet(_srcTokens[j], _chainSelector, _amounts[j]);
      unchecked {
        j++;
      }
    }
  }

  /**
   * @notice Remove  max amount of a token that can be bridged on a destination chain
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _srcTokens List of tokens on this chain whose max amount are removed
   */
  function removeMaxChainAmount(
    uint64 _chainSelector,
    IMintableBurnableERC20[] calldata _srcTokens
  ) external onlyMaintainer {
    uint256 tokensNumber = _srcTokens.length;
    require(tokensNumber > 0, 'No tokens passed');
    for (uint256 j = 0; j < tokensNumber; ) {
      require(
        chainMaxAmount[_srcTokens[j]][_chainSelector] != 0,
        'Max amount not set'
      );
      delete chainMaxAmount[_srcTokens[j]][_chainSelector];
      emit MaxChainAmountRemoved(_srcTokens[j], _chainSelector);
      unchecked {
        j++;
      }
    }
  }

  /**
   * @notice Set fee to free or not
   * @notice Only maintainer can call this function
   * @param _chainSelector CCIP chain selector of the destination chain
   * @param _isFree True if free, otherwise false
   */
  function setFreeFee(uint64 _chainSelector, bool _isFree)
    external
    onlyMaintainer
  {
    require(freeFee[_chainSelector] != _isFree, 'Free fee already set');
    freeFee[_chainSelector] = _isFree;
    emit FreeFeeSet(_chainSelector, _isFree);
  }

  /**
   * @notice Burn tokens on this chain and trigger CCIP bridge for receiving on the destination chain
   * @param _destinationChainSelector CCIP chain selector of the destination chain
   * @param _token Address of the synth token to bridge
   * @param _amount Amount to bridge
   * @param _recipient Address to which receive synth tokens on the destination chain
   * @param _feeToken Address of the token used to pay fees for bridging
   * @return messageId CCIP output message id
   * @return fees Amount of fees to be paid
   */
  function transferTokensToDestinationChain(
    uint64 _destinationChainSelector,
    address _token,
    uint256 _amount,
    address _recipient,
    address _feeToken
  ) external payable nonReentrant returns (bytes32 messageId, uint256 fees) {
    TransferTokensCache memory cache;
    cache.messageReceiver = getDestEndpoint(_destinationChainSelector);
    IMintableBurnableERC20 destToken = IMintableBurnableERC20(
      getMappedToken(_token, _destinationChainSelector)
    );

    cache.actualBridgedAmount = chainBridgedAmount[
      IMintableBurnableERC20(_token)
    ][_destinationChainSelector];
    cache.amount = _amount.toInt256();
    require(
      cache.amount - cache.actualBridgedAmount <=
        chainMaxAmount[IMintableBurnableERC20(_token)][
          _destinationChainSelector
        ].toInt256(),
      'Max bridged amount reached'
    );

    cache.msgSender = _msgSender();
    (messageId, fees) = _burnAndSendCCIPMessage(
      _destinationChainSelector,
      cache.messageReceiver,
      IMintableBurnableERC20(_token),
      destToken,
      _amount,
      cache.msgSender,
      _recipient,
      _feeToken
    );

    chainBridgedAmount[IMintableBurnableERC20(_token)][
      _destinationChainSelector
    ] = cache.actualBridgedAmount - cache.amount;
    totalBridgedAmount[IMintableBurnableERC20(_token)] -= cache.amount;

    // Emit an event with message details
    emit TransferInitiated(
      messageId,
      _destinationChainSelector,
      cache.messageReceiver,
      IMintableBurnableERC20(_token),
      destToken,
      _amount,
      cache.msgSender,
      _recipient,
      _feeToken,
      fees
    );
  }

  /**
   * @notice Withdraw deposited native tokens
   * @notice Only maintainer can call this function
   * @param _beneficiary Address used for receiving native tokens
   */
  function withdraw(address payable _beneficiary)
    external
    onlyMaintainer
    nonReentrant
  {
    // Retrieve the balance of this contract
    uint256 amount = address(this).balance;

    // Revert if there is nothing to withdraw
    require(amount > 0, 'Nothing to withdraw');

    // Attempt to send the funds, capturing the success status and discarding any return data
    _beneficiary.sendValue(amount);
  }

  /**
   * @notice Withdraw deposited ERC20 tokens
   * @notice Only maintainer can call this function
   * @param _token Address of the token to withdraw
   * @param _beneficiary Address used for receiving ERC20 tokens
   */
  function withdrawToken(address _token, address _beneficiary)
    external
    onlyMaintainer
    nonReentrant
  {
    // Retrieve the balance of this contract
    uint256 amount = IERC20(_token).balanceOf(address(this));

    // Revert if there is nothing to withdraw
    require(amount > 0, 'Nothing to withdraw');

    IERC20(_token).safeTransfer(_beneficiary, amount);
  }

  /**
   * @notice Check if a token is whitelisted for a destination chain
   * @param _token Address of the token on this chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if token is whitelisted, otherwise false
   */
  function isTokenWhitelisted(address _token, uint64 _chainSelector)
    external
    view
    returns (bool)
  {
    return
      address(tokensMap[IMintableBurnableERC20(_token)][_chainSelector]) !=
      address(0);
  }

  /**
   * @notice Check if endpoints are supported for a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if endpoints are supported, otherwise false
   */
  function isEndpointSupported(uint64 _chainSelector)
    external
    view
    returns (bool)
  {
    return
      endpoints[_chainSelector].contractSender != address(0) &&
      endpoints[_chainSelector].contractReceiver != address(0);
  }

  /**
   * @notice Check if extra args are supported for a destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if extra args are supported, otherwise false
   */
  function isExtraArgsSupported(uint64 _chainSelector)
    external
    view
    returns (bool)
  {
    return extraArgs[_chainSelector].gasLimit != 0;
  }

  /**
   * @notice Check if the fee is free on the input destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return True if fee is flat, otherwise false
   */
  function isFeeFree(uint64 _chainSelector) external view returns (bool) {
    return freeFee[_chainSelector];
  }

  /**
   * @notice Amount of bridged token (negative outbound bridge, positive inbound bridge) for every chain
   * @param _token Address of the token
   * @return Total bridged amount
   */
  function getTotalBridgedAmount(address _token)
    external
    view
    returns (int256)
  {
    return totalBridgedAmount[IMintableBurnableERC20(_token)];
  }

  /**
   * @notice Amount of bridged token (negative outbound bridge, positive inbound bridge) for the input chain
   * @param _token Address of the token
   * @param _destChainSelector CCIP chain selector of the destination chain
   * @return Bridged amount for the input chain
   */
  function getChainBridgedAmount(address _token, uint64 _destChainSelector)
    external
    view
    returns (int256)
  {
    return
      chainBridgedAmount[IMintableBurnableERC20(_token)][_destChainSelector];
  }

  /**
   * @notice Max amount of token to be bridged on input destination chain
   * @param _token Address of the token
   * @param _destChainSelector CCIP chain selector of the destination chain
   * @return Max amount to be bridged
   */
  function getMaxChainAmount(address _token, uint64 _destChainSelector)
    external
    view
    returns (uint256)
  {
    return chainMaxAmount[IMintableBurnableERC20(_token)][_destChainSelector];
  }

  /**
   * @notice Get the source endpoint for the input chain
   * @param _chainSelector CCIP chain selector of the source chain
   * @return srcEndpoint Source endpoint
   */
  function getSrcEndpoint(uint64 _chainSelector)
    public
    view
    returns (address srcEndpoint)
  {
    srcEndpoint = endpoints[_chainSelector].contractSender;
    require(srcEndpoint != address(0), 'Src endpoint not supported');
  }

  /**
   * @notice Get the destination endpoint for the input chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return destEndpoint Destination endpoint
   */
  function getDestEndpoint(uint64 _chainSelector)
    public
    view
    returns (address destEndpoint)
  {
    destEndpoint = endpoints[_chainSelector].contractReceiver;
    require(destEndpoint != address(0), 'Dest endpoint not supported');
  }

  /**
   * @notice Get the extra-args for the input destination chain
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return args GasLimit and strict
   */
  function getExtraArgs(uint64 _chainSelector)
    public
    view
    returns (Client.EVMExtraArgsV1 memory args)
  {
    args = extraArgs[_chainSelector];
    require(args.gasLimit != 0, 'Args not supported');
  }

  /**
   * @notice Get the address of the mapped token with the input token on the input destination chain
   * @param _srcToken Address of the token
   * @param _chainSelector CCIP chain selector of the destination chain
   * @return destToken Address of mapped token on the destination chain
   */
  function getMappedToken(address _srcToken, uint64 _chainSelector)
    public
    view
    returns (address destToken)
  {
    destToken = address(
      tokensMap[IMintableBurnableERC20(_srcToken)][_chainSelector]
    );
    require(address(destToken) != address(0), 'Token not supported');
  }

  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(CCIPReceiver, AccessControlEnumerable)
    returns (bool)
  {
    return CCIPReceiver.supportsInterface(interfaceId);
  }

  // called by the router for mint tokens on the destination chain
  function _ccipReceive(Client.Any2EVMMessage memory message)
    internal
    override
    nonReentrant
  {
    // decode cross chain message
    (
      IMintableBurnableERC20 srcToken,
      IMintableBurnableERC20 destToken,
      uint256 amount,
      address recipient
    ) = abi.decode(
      message.data,
      (IMintableBurnableERC20, IMintableBurnableERC20, uint256, address)
    );

    address srcEndpoint = getSrcEndpoint(message.sourceChainSelector);

    require(
      abi.decode(message.sender, (address)) == srcEndpoint,
      'Wrong src endpoint'
    );
    require(
      address(srcToken) ==
        address(
          getMappedToken(address(destToken), message.sourceChainSelector)
        ),
      'Wrong src token'
    );

    // mint token to recipient
    IMintableBurnableERC20(destToken).mint(recipient, amount);

    chainBridgedAmount[destToken][message.sourceChainSelector] += amount
      .toInt256();
    totalBridgedAmount[destToken] += amount.toInt256();

    emit TransferCompleted(
      message.messageId,
      message.sourceChainSelector,
      srcEndpoint,
      srcToken,
      destToken,
      amount,
      recipient
    );
  }

  // burn tokens and trigger bridge message on CCIP
  function _burnAndSendCCIPMessage(
    uint64 _destinationChainSelector,
    address _messageReceiver,
    IMintableBurnableERC20 _srcToken,
    IMintableBurnableERC20 _destToken,
    uint256 _amount,
    address _tokenSender,
    address _tokenRecipient,
    address _feeToken
  ) internal returns (bytes32 messageId, uint256 fees) {
    // burn jAsset
    _srcToken.safeTransferFrom(_tokenSender, address(this), _amount);
    _srcToken.burn(_amount);

    // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
    Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
      _destinationChainSelector,
      _messageReceiver,
      _srcToken,
      _destToken,
      _amount,
      _tokenRecipient,
      _feeToken
    );

    // Get the fee required to send the message
    fees = i_router.getFee(_destinationChainSelector, evm2AnyMessage);

    if (_feeToken != address(0)) {
      require(msg.value == 0, 'Native token sent');
      if (!freeFee[_destinationChainSelector]) {
        IERC20(_feeToken).safeTransferFrom(_tokenSender, address(this), fees);
      } else {
        require(
          IERC20(_feeToken).balanceOf(address(this)) >= fees,
          'Not enough balance'
        );
      }

      // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
      IERC20(_feeToken).safeApprove(address(i_router), fees);

      // Send the message through the router and store the returned message ID
      messageId = i_router.ccipSend(_destinationChainSelector, evm2AnyMessage);
    } else {
      // NATIVE TOKEN FEE
      if (!freeFee[_destinationChainSelector]) {
        require(msg.value >= fees, 'Not enough native fees sent');
        uint256 refundAmount = msg.value - fees;
        if (refundAmount > 0) {
          payable(_tokenSender).sendValue(refundAmount);
        }
      } else {
        require(address(this).balance >= fees, 'Not enough balance');
      }

      // Send the message through the router and store the returned message ID
      messageId = i_router.ccipSend{value: fees}(
        _destinationChainSelector,
        evm2AnyMessage
      );
    }
  }

  // build CCIP message to send to the destination chain
  function _buildCCIPMessage(
    uint64 _destinationChainSelector,
    address _messageReceiver,
    IMintableBurnableERC20 _srcToken,
    IMintableBurnableERC20 _destToken,
    uint256 _amount,
    address _tokenRecipient,
    address _feeToken
  ) internal view returns (Client.EVM2AnyMessage memory) {
    // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
    Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
      receiver: abi.encode(_messageReceiver),
      data: abi.encode(_srcToken, _destToken, _amount, _tokenRecipient),
      tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array as no tokens are transferred
      extraArgs: Client._argsToBytes(
        // Additional arguments, setting gas limit and non-strict sequencing mode
        getExtraArgs(_destinationChainSelector)
      ),
      feeToken: _feeToken
    });
    return evm2AnyMessage;
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant VaultRegistry = 'VaultRegistry';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
  bytes32 public constant CommissionReceiver = 'CommissionReceiver';
  bytes32 public constant BuybackProgramReceiver = 'BuybackProgramReceiver';
  bytes32 public constant LendingRewardsReceiver = 'LendingRewardsReceiver';
  bytes32 public constant JarvisToken = 'JarvisToken';
  bytes32 public constant DebtTokenFactory = 'DebtTokenFactory';
  bytes32 public constant VaultFactory = 'VaultFactory';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant CrossChainBridge = 'CrossChainBridge';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Context} from '../../@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool);

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {AccessControlEnumerable} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @dev Extension of {AccessControlEnumerable} that offer support for maintainer role.
 */
contract StandardAccessControlEnumerable is AccessControlEnumerable {
  struct Roles {
    address admin;
    address maintainer;
  }

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function _setAdmin(address _account) internal {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _account);
  }

  function _setMaintainer(address _account) internal {
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(MAINTAINER_ROLE, _account);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {AccessControlEnumerable} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}