// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OwnableOperable} from "./ownership/OwnableOperable.sol";

import {CCIPReceiver} from "@ccip/applications/CCIPReceiver.sol";
import {Client} from "@ccip/libraries/Client.sol";
import {IRouterClient} from "@ccip/interfaces/IRouterClient.sol";
import {IARM} from "@ccip/interfaces/IARM.sol";

import {IERC20, ICCIPRouter} from "./Interfaces.sol";

contract CrossChainLiquidityManager is OwnableOperable, CCIPReceiver {
    uint256 public traderate;

    uint256 public pendingFee;
    address public feeRecipient;

    bool internal initialized;

    mapping(bytes32 => bool) public messageProcessed;

    mapping(address => uint256) public pendingUserBalance;

    uint256 public additionalLiquidityNeeded;

    uint64 public immutable otherChainSelector;
    address public immutable otherChainLiquidityManager;

    address public constant token0 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant token1 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
 
    event FeeRecipientChanged(address oldRecipient, address newRecipient);
    event FeeCollected(address recipient, uint256 fee);
    event TradeRateChanged(uint256 oldRate, uint256 newRate);
    event PendingBalanceClaimed(address recipient, uint256 amount);
    event TransferInitiated(bytes32 messageId);
    event TransferCompleted(bytes32 messageId);
    event PendingBalanceUpdated(address recipient, uint256 balance);
    event LiquidityUpdated();

    error ETHTransferFailed();
    error NoFeeRecipientSet();
    error UnsupportedFromToken();
    error UnsupportedToToken();
    error SlippageError();
    error InvalidAmountIn();
    error CCIPRouterIsCursed();
    error InvalidSourceChainSelector();
    error CallerIsNotOtherChainLiquidityManager();
    error InsufficientLiquidity();
    error CCIPMessageReplay();
    error AlreadyInitialized();

    /**
     * @dev Reverts if CCIP's Risk Management contract (ARM) is cursed
     */
    modifier onlyIfNotCursed() {
        IARM arm = IARM(ICCIPRouter(this.getRouter()).getArmProxy());

        if (arm.isCursed()) {
            revert CCIPRouterIsCursed();
        }

        _;
    }

    modifier onlyOtherChainLiquidityManager(uint64 chainSelector, address sender) {
        if (chainSelector != otherChainSelector) {
            // Ensure it's from mainnet
            revert InvalidSourceChainSelector();
        }

        if (sender != otherChainLiquidityManager) {
            // Ensure it's from the other chain's pool manager
            revert CallerIsNotOtherChainLiquidityManager();
        }

        _;
    }

    constructor (address _l2Router, uint64 _otherChainSelector, address _otherChainLiquidityManager) CCIPReceiver(_l2Router) {
        // Make sure nobody owns the implementation
        _setOwner(address(0));

        otherChainSelector = _otherChainSelector;
        otherChainLiquidityManager = _otherChainLiquidityManager;
    }

    function initialize(address _feeRecipient, uint256 _traderate) external onlyOwner {
        if (initialized) {
            revert AlreadyInitialized();
        }
        initialized = false;
        _setFeeRecipient(_feeRecipient);
        _setTradeRate(_traderate);
    }

    function _setFeeRecipient(address _feeRecipient) internal {
        emit FeeRecipientChanged(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        _setFeeRecipient(_feeRecipient);
    }

    function _setTradeRate(uint256 _traderate) internal {
        // TODO: Set lower and upper bounds
        // Make sure it also accounts for CCIP and redemption fees
        emit TradeRateChanged(traderate, _traderate);
        traderate = _traderate;
    }

    function setTradeRate(uint256 _traderate) external onlyOperatorOrOwner {
        _setTradeRate(_traderate);
    }

    function _transferEth(address receiver, uint256 amount) internal {
        (bool success,) = receiver.call{value: amount}(new bytes(0));
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    function collectFees() external {
        address _recipient = feeRecipient;
        if (_recipient == address(0)) {
            revert NoFeeRecipientSet();
        }

        uint256 _fee = pendingFee;
        if (_fee > 0) {
            pendingFee = 0;
            _transferEth(_recipient, _fee);
            emit FeeCollected(_recipient, _fee);
        }
    }

    function swapExactTokensForTokens(
        address inToken,
        address outToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external payable returns (bytes32 messageId) {
        if (inToken != token0) {
            revert UnsupportedToToken();
        }

        if (outToken != token1) {
            revert UnsupportedToToken();
        }

        if (msg.value != amountIn) {
            revert InvalidAmountIn();
        }

        // TODO: Account for CCIP Fees
        uint256 amountOut = (traderate * amountIn) / 1 ether;

        if (amountOut < amountOutMin) {
            revert SlippageError();
        }

        // Calc profit (assuming 1:1 peg)
        uint256 estimatedFeeEarned = amountIn - amountOut;
        pendingFee += estimatedFeeEarned;

        // Build CCIP message
        IRouterClient router = IRouterClient(this.getRouter());

        bytes memory extraArgs = hex"";
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(otherChainLiquidityManager),
            data: abi.encode(to, amountOut),
            tokenAmounts: tokenAmounts,
            extraArgs: extraArgs,
            feeToken: address(0)
        });

        uint256 ccipFees = router.getFee(otherChainSelector, message);

        // TODO: ccipFee not accounted for
        // if (estimatedFeeEarned < ccipFees) {
        //     revert NonProfitableTrade();
        // }

        // Send message to other chain
        messageId = router.ccipSend{ value: ccipFees }(
            otherChainSelector,
            message
        );

        emit TransferInitiated(messageId);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        override
        onlyOtherChainLiquidityManager(
            message.sourceChainSelector,
            abi.decode(message.sender, (address))
        )
        onlyIfNotCursed
    {
        if (messageProcessed[message.messageId]) {
            revert CCIPMessageReplay();
        }
        messageProcessed[message.messageId] = true;

        (address recipient, uint256 amount) = abi.decode(message.data, (address, uint256));

        if (amount <= address(this).balance) {
            // Transfer if there's enough liquidity
            _transferEth(recipient, amount);
            emit TransferCompleted(message.messageId);
        } else {
            // Make it claimable if liquidity is insufficient
            uint256 currBalance = pendingUserBalance[recipient];
            pendingUserBalance[recipient] = currBalance + amount;
            additionalLiquidityNeeded += amount;
            emit PendingBalanceUpdated(recipient, currBalance + amount);
        }
    }

    function claimPendingBalance() external {
        uint256 amount = pendingUserBalance[msg.sender];

        if (amount > address(this).balance) {
            revert InsufficientLiquidity();
        }

        emit PendingBalanceClaimed(msg.sender, amount);
        pendingUserBalance[msg.sender] = 0;
        _transferEth(msg.sender, amount);
    }

    function addLiquidity() public payable {
        uint256 _liquidityNeeded = additionalLiquidityNeeded;
        // Accept all ETH sent to this address as liquidity
        if (_liquidityNeeded >= msg.value) {
            additionalLiquidityNeeded = _liquidityNeeded - msg.value;
        }  else if (_liquidityNeeded != 0) {
            additionalLiquidityNeeded = 0;
        }

        emit LiquidityUpdated();
    }

    receive() external payable {
        addLiquidity();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "./Ownable.sol";

contract OwnableOperable is Ownable {
    // keccak256(“eip1967.proxy.operator”) - 1, inspired by EIP 1967
    bytes32 internal constant OPERATOR_SLOT = 0x14cc265c8475c78633f4e341e72b9f4f0d55277c8def4ad52d79e69580f31482;

    event OperatorChanged(address previousAdmin, address newAdmin);

    constructor() {
        assert(OPERATOR_SLOT == bytes32(uint256(keccak256("eip1967.proxy.operator")) - 1));
    }

    function operator() external view returns (address) {
        return _operator();
    }

    function setOperator(address newOperator) external onlyOwner {
        _setOperator(newOperator);
    }

    function _operator() internal view returns (address operatorOut) {
        bytes32 position = OPERATOR_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            operatorOut := sload(position)
        }
    }

    function _setOperator(address newOperator) internal {
        emit OperatorChanged(_operator(), newOperator);
        bytes32 position = OPERATOR_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(position, newOperator)
        }
    }

    modifier onlyOperatorOrOwner() {
        require(
            msg.sender == _operator() || msg.sender == _owner(), "OSwap: Only operator or owner can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAny2EVMMessageReceiver} from "../interfaces/IAny2EVMMessageReceiver.sol";

import {Client} from "../libraries/Client.sol";

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/utils/introspection/IERC165.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
  address internal immutable i_ccipRouter;

  constructor(address router) {
    if (router == address(0)) revert InvalidRouter(address(0));
    i_ccipRouter = router;
  }

  /// @notice IERC165 supports an interfaceId
  /// @param interfaceId The interfaceId to check
  /// @return true if the interfaceId is supported
  /// @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
  /// e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
  /// This allows CCIP to check if ccipReceive is available before calling it.
  /// If this returns false or reverts, only tokens are transferred to the receiver.
  /// If this returns true, tokens are transferred and ccipReceive is called atomically.
  /// Additionally, if the receiver address does not have code associated with
  /// it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
    _ccipReceive(message);
  }

  /// @notice Override this function in your implementation.
  /// @param message Any2EVMMessage
  function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

  /////////////////////////////////////////////////////////////////////
  // Plumbing
  /////////////////////////////////////////////////////////////////////

  /// @notice Return the current router
  /// @return CCIP router address
  function getRouter() public view returns (address) {
    return address(i_ccipRouter);
  }

  error InvalidRouter(address router);

  /// @dev only calls from the set router are accepted.
  modifier onlyRouter() {
    if (msg.sender != address(i_ccipRouter)) revert InvalidRouter(msg.sender);
    _;
  }
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

/// @notice This interface contains the only ARM-related functions that might be used on-chain by other CCIP contracts.
interface IARM {
  /// @notice A Merkle root tagged with the address of the commit store contract it is destined for.
  struct TaggedRoot {
    address commitStore;
    bytes32 root;
  }

  /// @notice Callers MUST NOT cache the return value as a blessed tagged root could become unblessed.
  function isBlessed(TaggedRoot calldata taggedRoot) external view returns (bool);

  /// @notice When the ARM is "cursed", CCIP pauses until the curse is lifted.
  function isCursed() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
}

interface ICCIPRouter {
    function getArmProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract Ownable {
    // keccak256(“eip1967.proxy.admin”) - per EIP 1967
    bytes32 internal constant OWNER_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event AdminChanged(address previousAdmin, address newAdmin);

    constructor() {
        assert(OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setOwner(msg.sender);
    }

    function owner() external view returns (address) {
        return _owner();
    }

    function setOwner(address newOwner) external onlyOwner {
        _setOwner(newOwner);
    }

    function _owner() internal view returns (address ownerOut) {
        bytes32 position = OWNER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ownerOut := sload(position)
        }
    }

    function _setOwner(address newOwner) internal {
        emit AdminChanged(_owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(position, newOwner)
        }
    }

    function _onlyOwner() internal view {
        require(msg.sender == _owner(), "OSwap: Only owner can call this function.");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

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