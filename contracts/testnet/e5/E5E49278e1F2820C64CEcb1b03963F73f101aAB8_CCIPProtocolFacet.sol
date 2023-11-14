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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

error AlreadyInitialized();
error CannotAuthoriseSelf();
error CannotBridgeToSameNetwork();
error ContractCallNotAllowed();
error CumulativeSlippageTooHigh(uint256 minAmount, uint256 receivedAmount);
error ExternalCallFailed();
error InformationMismatch();
error InsufficientBalance(uint256 required, uint256 balance);
error InvalidAmount();
error InvalidCallData();
error InvalidConfig();
error InvalidContract();
error InvalidDestinationChain();
error InvalidFallbackAddress();
error InvalidReceiver();
error InvalidSendingToken();
error NativeAssetNotSupported();
error NativeAssetTransferFailed();
error NoSwapDataProvided();
error NoSwapFromZeroBalance();
error NotAContract();
error NotInitialized();
error NoTransferToNullAddress();
error NullAddrIsNotAnERC20Token();
error NullAddrIsNotAValidSpender();
error OnlyContractOwner();
error RecoveryAddressCannotBeZero();
error ReentrancyError();
error TokenNotSupported();
error UnAuthorized();
error UnsupportedChainId(uint256 chainId);
error WithdrawFailed();
error ZeroAmount();
error ProtocolNotFound();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

import "../interfaces/INexa.sol";

import "../shared/Structs.sol";
import "../shared/Setters.sol";
import "../shared/Events.sol";

import "../libraries/LibInternalGetters.sol";

import "@openzeppelin/contracts/utils/Address.sol";

contract CCIPProtocolFacet is IAny2EVMMessageReceiver, Events, Setters {
    using Address for address;

    /**
     * @dev To transfer tokens to other chains.
     */
    function ccipSend(
        Structs.ProtocolPayload memory sendPayload,
        Structs.MessagingProtocol memory protocol,
        uint256 gasLimit
    ) external payable returns (bool sent) {
        require(msg.sender == address(this), "Invalid CCIP Send");

        Structs.MessagingProtocol memory destChainProtocol = LibInternalGetters
            .getChainProtocolInfo(sendPayload.destChain, protocol.id);

        address destRoutingEngine = LibInternalGetters.bytesToAddress(
            LibInternalGetters.routingEngineContracts(sendPayload.destChain)
        );
        if (LibInternalGetters.bytesToAddress(protocol.endPoint).isContract()) {
            uint256 fee = IRouterClient(LibInternalGetters.bytesToAddress(protocol.endPoint))
                .getFee(
                    uint64(destChainProtocol.protocolChainId),
                    Client.EVM2AnyMessage({
                        receiver: abi.encode(destRoutingEngine),
                        data: abi.encode(sendPayload),
                        tokenAmounts: new Client.EVMTokenAmount[](0),
                        extraArgs: Client._argsToBytes(
                            Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
                        ),
                        feeToken: address(0)
                    })
                );

            require(msg.value >= fee, "Not enough fee provided to publish message");

            if (msg.value > fee) {
                (bool success, bytes memory data) = payable(
                    LibInternalGetters.bytesToAddress(sendPayload.refundAddress)
                ).call{value: msg.value - fee}("");
            }

            IRouterClient(LibInternalGetters.bytesToAddress(protocol.endPoint)).ccipSend{
                value: fee
            }(
                uint64(destChainProtocol.protocolChainId),
                Client.EVM2AnyMessage({
                    receiver: abi.encode(destRoutingEngine),
                    data: abi.encode(sendPayload),
                    tokenAmounts: new Client.EVMTokenAmount[](0),
                    extraArgs: Client._argsToBytes(
                        Client.EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
                    ),
                    feeToken: address(0)
                })
            );

            emit protocolSendEvent(
                LibInternalGetters.bytesToAddress(sendPayload.payloadSender),
                sendPayload.protocolId,
                LibInternalGetters.bytesToAddress(sendPayload.srcEngineAddress),
                sendPayload.srcChain,
                LibInternalGetters.bytesToAddress(sendPayload.destEngineAddress),
                sendPayload.destChain,
                payable(LibInternalGetters.bytesToAddress(sendPayload.refundAddress)),
                LibInternalGetters.bytesToAddress(sendPayload.destContractAddress),
                sendPayload.payload
            );

            sent = true;
        } else {
            revert();
        }
    } // end of function

    /**
     * @dev To receive tokens from another chain.
     */
    function ccipReceive(Client.Any2EVMMessage memory message) external override {
        Structs.ProtocolPayload memory receivePayload = abi.decode(
            message.data,
            (Structs.ProtocolPayload)
        );

        Structs.MessagingProtocol memory destChainProtocol = LibInternalGetters
            .getChainProtocolInfo(LibInternalGetters.getBlockchainId(), receivePayload.protocolId);
        require(
            msg.sender == LibInternalGetters.bytesToAddress(destChainProtocol.endPoint),
            "Invalid CCIP Router"
        );

        address srcRoutingEngine = abi.decode(message.sender, (address));
        require(
            srcRoutingEngine == address(this) ||
                LibInternalGetters.routingEngineContracts(receivePayload.srcChain) ==
                LibInternalGetters.addressToBytes(srcRoutingEngine),
            "Invalid Routing Engine"
        );

        require(
            receivePayload.destChain == LibInternalGetters.getBlockchainId(),
            "Invalid target Chain"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                message.messageId,
                message.data,
                message.sourceChainSelector,
                message.sender
            )
        );

        require(!LibInternalGetters.isTransferCompleted(hash), "Transfer already completed");
        Setters.setTransferCompleted(hash);

        address contractAddress = LibInternalGetters.bytesToAddress(
            receivePayload.destContractAddress
        );
        if (contractAddress.isContract()) {
            try
                INexa(contractAddress).nexaReceive(
                    receivePayload.payloadSender,
                    receivePayload.srcChain,
                    receivePayload.payload,
                    hash
                )
            {
                emit protocolReceiveEvent(
                    LibInternalGetters.bytesToAddress(receivePayload.payloadSender),
                    receivePayload.protocolId,
                    LibInternalGetters.bytesToAddress(receivePayload.srcEngineAddress),
                    receivePayload.srcChain,
                    LibInternalGetters.bytesToAddress(receivePayload.destEngineAddress),
                    receivePayload.destChain,
                    payable(LibInternalGetters.bytesToAddress(receivePayload.refundAddress)),
                    LibInternalGetters.bytesToAddress(receivePayload.destContractAddress),
                    receivePayload.payload
                );
            } catch {
                emit errorProtocolReceiveEvent(
                    LibInternalGetters.bytesToAddress(receivePayload.payloadSender),
                    receivePayload.protocolId,
                    LibInternalGetters.bytesToAddress(receivePayload.srcEngineAddress),
                    receivePayload.srcChain,
                    LibInternalGetters.bytesToAddress(receivePayload.destEngineAddress),
                    receivePayload.destChain,
                    payable(LibInternalGetters.bytesToAddress(receivePayload.refundAddress)),
                    LibInternalGetters.bytesToAddress(receivePayload.destContractAddress),
                    receivePayload.payload
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
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
pragma solidity ^0.8.4;

interface INexa {
    function nexaReceive(bytes32 payloadSender, uint256 srcChain, bytes memory payload, bytes32 deliveryHash) external;  
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();

    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    // -------------------------

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) revert SliceOverflow();
        if (_bytes.length < _start + _length) revert SliceOutOfBounds();

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address) {
        if (_bytes.length < _start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    /// Copied from OpenZeppelin's `Strings.sol` utility library.
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/8335676b0e99944eef6a742e16dcd9ff6e68e609/contracts/utils/Strings.sol
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibUtil } from "../libraries/LibUtil.sol";
import { OnlyContractOwner } from "../errors/GenericErrors.sol";
import "../shared/Structs.sol";

/// Implementation of EIP-2535 Diamond Standard
/// https://eips.ethereum.org/EIPS/eip-2535
library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    // Diamond specific errors
    error IncorrectFacetCutAction();
    error NoSelectorsInFace();
    error FunctionAlreadyExists();
    error FacetAddressIsZero();
    error FacetAddressIsNotZero();
    error FacetContainsNoCode();
    error FunctionDoesNotExist();
    error FunctionIsImmutable();
    error InitZeroButCalldataNotEmpty();
    error CalldataEmptyButInitNotZero();
    error InitReverted();
    // ----------------

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

        address contractOwner;
        
        uint256 blockchainId;
        // Mapping of all the protocols on each chain
        mapping(uint256 => mapping(uint256 => Structs.MessagingProtocol)) chainProtocol;
        // Mapping of all the protocols
        mapping(uint256 => Structs.MessagingProtocol) protocols;
        // Mapping of all blockchains
        mapping(uint256 => Structs.BlockchainInfo) blockchains;
        // Mapping of routing engine contracts on other chains
        mapping(uint256 => bytes32) routingEngineImplementations;
        // Mapping of consumed token transfers
        mapping(bytes32 => bool) completedTransfers;
        bool isInitialized;
        mapping(bytes => bool) signaturesUsed;
	}

    function initializeDiamond(address _contractOwner) internal {
		DiamondStorage storage ds = diamondStorage();
		ds.contractOwner = _contractOwner;
	}
	
    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (msg.sender != diamondStorage().contractOwner)
            revert OnlyContractOwner();
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert IncorrectFacetCutAction();
            }
            unchecked {
                ++facetIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (!LibUtil.isZeroAddress(oldFacetAddress)) {
                revert FunctionAlreadyExists();
            }
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsZero();
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert FunctionAlreadyExists();
            }
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            unchecked {
                ++selectorPosition;
                ++selectorIndex;
            }
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsInFace();
        }
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (!LibUtil.isZeroAddress(_facetAddress)) {
            revert FacetAddressIsNotZero();
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;

        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked {
                ++selectorIndex;
            }
        }
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (LibUtil.isZeroAddress(_facetAddress)) {
            revert FunctionDoesNotExist();
        }
        // an immutable function is a function defined directly in a relayer
        if (_facetAddress == address(this)) {
            revert FunctionIsImmutable();
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (LibUtil.isZeroAddress(_init)) {
            if (_calldata.length != 0) {
                revert InitZeroButCalldataNotEmpty();
            }
        } else {
            if (_calldata.length == 0) {
                revert CalldataEmptyButInitNotZero();
            }
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitReverted();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert FacetContainsNoCode();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibDiamond.sol";
import { IAny2EVMMessageReceiver } from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

library LibInternalGetters {
    /**
     * @dev Get if a transfer is completed
     */
    function isTransferCompleted(bytes32 uniqueTransferId) internal view returns (bool) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.completedTransfers[uniqueTransferId];
    }

    /**
     * @dev Get protocol info for other registered chains
     */
    function getChainProtocolInfo(
        uint256 blockchainId,
        uint256 protocolId
    ) internal view returns (Structs.MessagingProtocol memory) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.chainProtocol[blockchainId][protocolId];
    }

    /**
     * @dev Get current chain protocol info
     */
    function getProtocolInfo(
        uint256 protocolId
    ) internal view returns (Structs.MessagingProtocol memory) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.protocols[protocolId];
    }

    /**
     * @dev Get blockchain info for other registered chains
     */
    function getBlockchainInfo(
        uint256 blockchainId
    ) internal view returns (Structs.BlockchainInfo memory) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.blockchains[blockchainId];
    }

    /**
     * @dev Get current chain blockchain id
     */
    function getBlockchainId() internal view returns (uint256) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.blockchainId;
    }

    /**
     * @dev Get CCIP Interface Id
     */
    function getCCIPInterface() internal pure returns (bytes4){
		return type(IAny2EVMMessageReceiver).interfaceId;
	}

    /**
     * @dev Get routing engine contract address for other registered chains
     */
    function routingEngineContracts(uint256 blockchainId) internal view returns (bytes32) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.routingEngineImplementations[blockchainId];
    }

    /**
     * @dev Get if routing engine initialized
     */
    function isInitialized() internal view returns (bool) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.isInitialized;
    }

    /**
     * @dev Get if a protocol is enabled
     */
    function isEnabled(uint256 protocolId) internal view returns (bool) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.protocols[protocolId].isEnabled;
    }

    /**
     * @dev Get if signature used
     */
    function isSignatureUsed(bytes memory signature) internal view returns (bool) {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        return diamondStorage.signaturesUsed[signature];
    }

    function bytesToAddress(bytes32 b) internal pure returns (address) {
        require(bytes12(b) == 0, "invalid EVM address");
        return address(uint160(uint256(b)));
    }

    function addressToBytes(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function stringToAddress(string memory _address) internal pure returns (address) {
        string memory cleanAddress = remove0xPrefix(_address);
        bytes20 _addressBytes = parseHexStringToBytes20(cleanAddress);
        return address(_addressBytes);
    }

    function remove0xPrefix(string memory _hexString) internal pure returns (string memory) {
        if (
            bytes(_hexString).length >= 2 &&
            bytes(_hexString)[0] == "0" &&
            (bytes(_hexString)[1] == "x" || bytes(_hexString)[1] == "X")
        ) {
            return substring(_hexString, 2, bytes(_hexString).length);
        }
        return _hexString;
    }

    function substring(
        string memory _str,
        uint256 _start,
        uint256 _end
    ) internal pure returns (string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _result = new bytes(_end - _start);
        for (uint256 i = _start; i < _end; i++) {
            _result[i - _start] = _strBytes[i];
        }
        return string(_result);
    }

    function parseHexStringToBytes20(string memory _hexString) internal pure returns (bytes20) {
        bytes memory _bytesString = bytes(_hexString);
        uint160 _parsedBytes = 0;
        for (uint256 i = 0; i < _bytesString.length; i += 2) {
            _parsedBytes *= 256;
            uint8 _byteValue = parseByteToUint8(_bytesString[i]);
            _byteValue *= 16;
            _byteValue += parseByteToUint8(_bytesString[i + 1]);
            _parsedBytes += _byteValue;
        }
        return bytes20(_parsedBytes);
    }

    function parseByteToUint8(bytes1 _byte) internal pure returns (uint8) {
        if (uint8(_byte) >= 48 && uint8(_byte) <= 57) {
            return uint8(_byte) - 48;
        } else if (uint8(_byte) >= 65 && uint8(_byte) <= 70) {
            return uint8(_byte) - 55;
        } else if (uint8(_byte) >= 97 && uint8(_byte) <= 102) {
            return uint8(_byte) - 87;
        } else {
            revert(string(abi.encodePacked("Invalid byte value: ", _byte)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibBytes.sol";

library LibUtil {
    using LibBytes for bytes;

    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) return "Transaction reverted silently";
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }

    /// @notice Determines whether the given address is the zero address
    /// @param addr The address to verify
    /// @return Boolean indicating if the address is the zero address
    function isZeroAddress(address addr) internal pure returns (bool) {
        return addr == address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Structs.sol";

contract Events{
    event protocolSendEvent(
        address indexed payloadSender,
        uint256 indexed protocolId,
        address srcEngineAddress,
        uint256 srcChain,
        address destEngineAddress,
        uint256 destChain,
        address refundAddress,
        address indexed destContractAddress,
        bytes payload
    );
    
    event protocolReceiveEvent(
        address indexed payloadSender,
        uint256 indexed protocolId,
        address srcEngineAddress,
        uint256 srcChain,
        address destEngineAddress,
        uint256 destChain,
        address refundAddress,
        address indexed destContractAddress,
        bytes payload
    );

    event errorProtocolReceiveEvent(
        address indexed payloadSender,
        uint256 indexed protocolId,
        address srcEngineAddress,
        uint256 srcChain,
        address destEngineAddress,
        uint256 destChain,
        address refundAddress,
        address indexed destContractAddress,
        bytes payload
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import "./Structs.sol";

contract Setters {
    /** 
     * @dev Set transfer completed
    */
    function setTransferCompleted(bytes32 uniqueTransferId) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.completedTransfers[uniqueTransferId] = true;
    }

    /** 
     * @dev Set protocol info for other registered chains
    */
    function setChainProtocolInfo(uint256 blockchainId, uint256 protocolId, Structs.MessagingProtocol calldata protocol) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.chainProtocol[blockchainId][protocolId] = protocol;
    }

    /**
     * @dev Set current chain blockchain id 
    */
    function setBlockchainId(uint256 blockchainId) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.blockchainId = blockchainId;
    }

    /** 
     * @dev Set routing engine contract address for other registered chains 
    */
    function setRoutingEngineImplementation(uint256 blockchainId, bytes32 tokenContract) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.routingEngineImplementations[blockchainId] = tokenContract;
    }

    /** 
     * @dev Set current chain protocol info
    */
    function setProtocolInfo(Structs.MessagingProtocol calldata protocol) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.protocols[protocol.id] = protocol;
    }

    /**
     * @dev Set current chain multiple protocols info
    */
    function setProtocolsInfo(Structs.MessagingProtocol[] calldata protocols) internal {
        for (uint256 i = 0; i < protocols.length; i++) {
            setProtocolInfo(protocols[i]);
        }
    }

    /**
     * @dev Set blockchain info for other registered chains
    */
    function setBlockchainInfo(Structs.BlockchainInfo calldata blockchain) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.blockchains[blockchain.id] = blockchain;
    }

    /**
     * @dev Set multiple blockchains info for other registered chains
    */
    function setBlockchainsInfo(Structs.BlockchainInfo[] calldata blockchains) internal {
        for (uint256 i = 0; i < blockchains.length; i++) {
            setBlockchainInfo(blockchains[i]);
        }
    }

    /** 
     * @dev Set routing engine initialized
    */
    function setIsInitialized() internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.isInitialized = true;
    }

    /** 
     * @dev Set protocol enabled status
    */
    function setIsEnabled(uint256 protocolId, bool protocolStatus) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.protocols[protocolId].isEnabled = protocolStatus;
    }

    /** 
     * @dev Set signature used
    */
    function setSignatureUsed(bytes memory signature) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.signaturesUsed[signature] = true;
    }

    function setInterface(bytes4 interfaceId, bool status) internal {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        diamondStorage.supportedInterfaces[interfaceId] = status;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Structs {

    struct MessagingProtocol {
        // Conventional messaging protocol id
        uint256 id;
        // Blockchain name for Axelar protocol
        string axelarBlockchainName;
        // Gateway/Endpoint/Router/Relayer address for a protocol
        bytes32 endPoint;
        // Chain id for a protocol
        uint256 protocolChainId;
        // Gas service address for Axelar protocol 
        bytes32 gasService;
        // Protocol enable status
        bool isEnabled;
    }

    struct BlockchainInfo {
        // Conventional blockchain id
        uint256 id;
        // Blockchain name
        string name;
    }

    struct ProtocolPayload {
        // Caller of the RoutingEngine
        bytes32 payloadSender;
        // Protocol id of the protocol used
        uint256 protocolId;
        // Address of the engine. Left-zero-padded if shorter than 32 bytes
        bytes32 srcEngineAddress;
        // Chain ID of the source routing engine
        uint256 srcChain;
        // Destination engine address
        bytes32 destEngineAddress;
        // Chain ID of the destination routing engine
        uint256 destChain;
        // Refund address for any extra fees paid
        bytes32 refundAddress;
        // Destination contract address that implements INexa nexaReceive
        bytes32 destContractAddress;
        // Sending payload
        bytes payload; 
    }

    struct SignatureVerification {
        // Address of custodian the user has delegated to sign transaction on behalf of
        address custodian;
        // Timestamp the transaction will be valid till
        uint256 validTill;
        // Signed Signature
        bytes signature;
    }

}