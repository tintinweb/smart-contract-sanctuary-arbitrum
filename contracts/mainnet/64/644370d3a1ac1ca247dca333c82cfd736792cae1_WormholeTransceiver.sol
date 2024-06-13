// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/libraries/BytesParsing.sol";
import "wormhole-solidity-sdk/interfaces/IWormhole.sol";

import "../../libraries/TransceiverHelpers.sol";
import "../../libraries/TransceiverStructs.sol";

import "../../interfaces/IWormholeTransceiver.sol";
import "../../interfaces/ISpecialRelayer.sol";
import "../../interfaces/INttManager.sol";

import "./WormholeTransceiverState.sol";

/// @title WormholeTransceiver
/// @author Wormhole Project Contributors.
/// @notice Transceiver implementation for Wormhole.
///
/// @dev This contract is responsible for sending and receiving NTT messages
///      that are authenticated through Wormhole Core.
///
/// @dev Messages can be delivered either via standard relaying or special relaying, or
///      manually via the core layer.
///
/// @dev Once a message is received, it is delivered to its corresponding
///      NttManager contract.
contract WormholeTransceiver is
    IWormholeTransceiver,
    IWormholeReceiver,
    WormholeTransceiverState
{
    using BytesParsing for bytes;

    string public constant WORMHOLE_TRANSCEIVER_VERSION = "0.1.0";

    constructor(
        address nttManager,
        address wormholeCoreBridge,
        address wormholeRelayerAddr,
        address specialRelayerAddr,
        uint8 _consistencyLevel,
        uint256 _gasLimit
    )
        WormholeTransceiverState(
            nttManager,
            wormholeCoreBridge,
            wormholeRelayerAddr,
            specialRelayerAddr,
            _consistencyLevel,
            _gasLimit
        )
    {}

    // ==================== External Interface ===============================================

    /// @inheritdoc IWormholeTransceiver
    function receiveMessage(bytes memory encodedMessage) external {
        uint16 sourceChainId;
        bytes memory payload;
        (sourceChainId, payload) = _verifyMessage(encodedMessage);

        // parse the encoded Transceiver payload
        TransceiverStructs.TransceiverMessage memory parsedTransceiverMessage;
        TransceiverStructs.NttManagerMessage memory parsedNttManagerMessage;
        (parsedTransceiverMessage, parsedNttManagerMessage) = TransceiverStructs
            .parseTransceiverAndNttManagerMessage(WH_TRANSCEIVER_PAYLOAD_PREFIX, payload);

        _deliverToNttManager(
            sourceChainId,
            parsedTransceiverMessage.sourceNttManagerAddress,
            parsedTransceiverMessage.recipientNttManagerAddress,
            parsedNttManagerMessage
        );
    }

    /// @inheritdoc IWormholeReceiver
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable onlyRelayer {
        if (getWormholePeer(sourceChain) != sourceAddress) {
            revert InvalidWormholePeer(sourceChain, sourceAddress);
        }

        // VAA replay protection:
        // - Note that this VAA is for the AR delivery, not for the raw message emitted by the source
        // - chain Transceiver contract. The VAAs received by this entrypoint are different than the
        // - VAA received by the receiveMessage entrypoint.
        if (isVAAConsumed(deliveryHash)) {
            revert TransferAlreadyCompleted(deliveryHash);
        }
        _setVAAConsumed(deliveryHash);

        // We don't honor additional messages in this handler.
        if (additionalMessages.length > 0) {
            revert UnexpectedAdditionalMessages();
        }

        // emit `ReceivedRelayedMessage` event
        emit ReceivedRelayedMessage(deliveryHash, sourceChain, sourceAddress);

        // parse the encoded Transceiver payload
        TransceiverStructs.TransceiverMessage memory parsedTransceiverMessage;
        TransceiverStructs.NttManagerMessage memory parsedNttManagerMessage;
        (parsedTransceiverMessage, parsedNttManagerMessage) = TransceiverStructs
            .parseTransceiverAndNttManagerMessage(WH_TRANSCEIVER_PAYLOAD_PREFIX, payload);

        _deliverToNttManager(
            sourceChain,
            parsedTransceiverMessage.sourceNttManagerAddress,
            parsedTransceiverMessage.recipientNttManagerAddress,
            parsedNttManagerMessage
        );
    }

    /// @inheritdoc IWormholeTransceiver
    function parseWormholeTransceiverInstruction(bytes memory encoded)
        public
        pure
        returns (WormholeTransceiverInstruction memory instruction)
    {
        // If the user doesn't pass in any transceiver instructions then the default is false
        if (encoded.length == 0) {
            instruction.shouldSkipRelayerSend = false;
            return instruction;
        }

        uint256 offset = 0;
        (instruction.shouldSkipRelayerSend, offset) = encoded.asBoolUnchecked(offset);
        encoded.checkLength(offset);
    }

    /// @inheritdoc IWormholeTransceiver
    function encodeWormholeTransceiverInstruction(WormholeTransceiverInstruction memory instruction)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(instruction.shouldSkipRelayerSend);
    }

    // ==================== Internal ========================================================

    function _quoteDeliveryPrice(
        uint16 targetChain,
        TransceiverStructs.TransceiverInstruction memory instruction
    ) internal view override returns (uint256 nativePriceQuote) {
        // Check the special instruction up front to see if we should skip sending via a relayer
        WormholeTransceiverInstruction memory weIns =
            parseWormholeTransceiverInstruction(instruction.payload);
        if (weIns.shouldSkipRelayerSend) {
            return wormhole.messageFee();
        }

        if (_checkInvalidRelayingConfig(targetChain)) {
            revert InvalidRelayingConfig(targetChain);
        }

        if (_shouldRelayViaStandardRelaying(targetChain)) {
            (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, gasLimit);
            return cost;
        } else if (isSpecialRelayingEnabled(targetChain)) {
            uint256 cost = specialRelayer.quoteDeliveryPrice(getNttManagerToken(), targetChain, 0);
            // We need to pay both the special relayer cost and the Wormhole message fee independently
            return cost + wormhole.messageFee();
        } else {
            return wormhole.messageFee();
        }
    }

    function _sendMessage(
        uint16 recipientChain,
        uint256 deliveryPayment,
        address caller,
        bytes32 recipientNttManagerAddress,
        bytes32 refundAddress,
        TransceiverStructs.TransceiverInstruction memory instruction,
        bytes memory nttManagerMessage
    ) internal override {
        TransceiverStructs.TransceiverMessage memory transceiverMessage;
        bytes memory encodedTransceiverPayload;
        bytes32 wormholeFormattedCaller = toWormholeFormat(caller);

        WormholeTransceiverInstruction memory weIns =
            parseWormholeTransceiverInstruction(instruction.payload);

        if (!weIns.shouldSkipRelayerSend && _shouldRelayViaStandardRelaying(recipientChain)) {
            // NOTE: standard relaying supports refunds. The amount to be refunded will be sent
            // to a refundAddress specified by the client on the destination chain.

            (transceiverMessage, encodedTransceiverPayload) = TransceiverStructs
                .buildAndEncodeTransceiverMessage(
                WH_TRANSCEIVER_PAYLOAD_PREFIX,
                wormholeFormattedCaller,
                recipientNttManagerAddress,
                nttManagerMessage,
                new bytes(0)
            );

            // push onto the stack again to avoid stack too deep error
            bytes32 refundRecipient = refundAddress;
            uint16 destinationChain = recipientChain;

            wormholeRelayer.sendPayloadToEvm{value: deliveryPayment}(
                destinationChain,
                fromWormholeFormat(getWormholePeer(destinationChain)),
                encodedTransceiverPayload,
                0,
                gasLimit,
                destinationChain,
                fromWormholeFormat(refundRecipient)
            );

            emit RelayingInfo(uint8(RelayingType.Standard), refundAddress, deliveryPayment);
        } else if (!weIns.shouldSkipRelayerSend && isSpecialRelayingEnabled(recipientChain)) {
            // This transceiver payload is used to signal whether the message should be
            // picked up by the special relayer or not:
            //  - It only affects the off-chain special relayer.
            //  - It is not used by the target NTT Manager contract.
            // Transceiver payload is prefixed with 1 byte representing the version of
            // the payload. The rest of the bytes are the -actual- payload data. In payload
            // v1, the payload data is a boolean representing whether the message should
            // be picked up by the special relayer or not.
            bytes memory transceiverPayload = abi.encodePacked(uint8(1), true);
            (transceiverMessage, encodedTransceiverPayload) = TransceiverStructs
                .buildAndEncodeTransceiverMessage(
                WH_TRANSCEIVER_PAYLOAD_PREFIX,
                wormholeFormattedCaller,
                recipientNttManagerAddress,
                nttManagerMessage,
                transceiverPayload
            );

            // push onto the stack again to avoid stack too deep error
            uint256 deliveryFee = deliveryPayment;
            uint16 destinationChain = recipientChain;

            uint256 wormholeFee = wormhole.messageFee();
            uint64 sequence = wormhole.publishMessage{value: wormholeFee}(
                0, encodedTransceiverPayload, consistencyLevel
            );
            specialRelayer.requestDelivery{value: deliveryFee - wormholeFee}(
                getNttManagerToken(), destinationChain, 0, sequence
            );

            // NOTE: specialized relaying does not currently support refunds. The zero address
            // is used as a placeholder for the refund address until support is added.
            emit RelayingInfo(uint8(RelayingType.Special), bytes32(0), deliveryFee);
        } else {
            (transceiverMessage, encodedTransceiverPayload) = TransceiverStructs
                .buildAndEncodeTransceiverMessage(
                WH_TRANSCEIVER_PAYLOAD_PREFIX,
                wormholeFormattedCaller,
                recipientNttManagerAddress,
                nttManagerMessage,
                new bytes(0)
            );

            wormhole.publishMessage{value: deliveryPayment}(
                0, encodedTransceiverPayload, consistencyLevel
            );

            // NOTE: manual relaying does not currently support refunds. The zero address
            // is used as refundAddress.
            emit RelayingInfo(uint8(RelayingType.Manual), bytes32(0), deliveryPayment);
        }

        emit SendTransceiverMessage(recipientChain, transceiverMessage);
    }

    function _verifyMessage(bytes memory encodedMessage) internal returns (uint16, bytes memory) {
        // verify VAA against Wormhole Core Bridge contract
        (IWormhole.VM memory vm, bool valid, string memory reason) =
            wormhole.parseAndVerifyVM(encodedMessage);

        // ensure that the VAA is valid
        if (!valid) {
            revert InvalidVaa(reason);
        }

        // ensure that the message came from a registered peer contract
        if (!_verifyBridgeVM(vm)) {
            revert InvalidWormholePeer(vm.emitterChainId, vm.emitterAddress);
        }

        // save the VAA hash in storage to protect against replay attacks.
        if (isVAAConsumed(vm.hash)) {
            revert TransferAlreadyCompleted(vm.hash);
        }
        _setVAAConsumed(vm.hash);

        // emit `ReceivedMessage` event
        emit ReceivedMessage(vm.hash, vm.emitterChainId, vm.emitterAddress, vm.sequence);

        return (vm.emitterChainId, vm.payload);
    }

    function _verifyBridgeVM(IWormhole.VM memory vm) internal view returns (bool) {
        checkFork(wormholeTransceiver_evmChainId);
        return getWormholePeer(vm.emitterChainId) == vm.emitterAddress;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./Chains.sol";
import "./Utils.sol";
import {Base} from "./Base.sol";
import {TokenBase, TokenReceiver, TokenSender} from "./TokenBase.sol";
import {CCTPBase, CCTPReceiver, CCTPSender} from "./CCTPBase.sol";
import {CCTPAndTokenBase, CCTPAndTokenReceiver, CCTPAndTokenSender} from "./CCTPAndTokenBase.sol";

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

library BytesParsing {
  uint256 private constant freeMemoryPtr = 0x40;
  uint256 private constant wordSize = 32;

  error OutOfBounds(uint256 offset, uint256 length);
  error LengthMismatch(uint256 encodedLength, uint256 expectedLength);
  error InvalidBoolVal(uint8 val);

  function checkBound(uint offset, uint length) internal pure {
    if (offset > length)
      revert OutOfBounds(offset, length);
  }

  function checkLength(bytes memory encoded, uint256 expected) internal pure {
    if (encoded.length != expected)
      revert LengthMismatch(encoded.length, expected);
  }

  function sliceUnchecked(
    bytes memory encoded,
    uint offset,
    uint length
  ) internal pure returns (bytes memory ret, uint nextOffset) {
    //bail early for degenerate case
    if (length == 0)
      return (new bytes(0), offset);

    assembly ("memory-safe") {
      nextOffset := add(offset, length)
      ret := mload(freeMemoryPtr)

      //Explanation on how we copy data here:
      //  The bytes type has the following layout in memory:
      //    [length: 32 bytes, data: length bytes]
      //  So if we allocate `bytes memory foo = new bytes(1);` then `foo` will be a pointer to 33
      //    bytes where the first 32 bytes contain the length and the last byte is the actual data.
      //  Since mload always loads 32 bytes of memory at once, we use our shift variable to align
      //    our reads so that our last read lines up exactly with the last 32 bytes of `encoded`.
      //  However this also means that if the length of `encoded` is not a multiple of 32 bytes, our
      //    first read will necessarily partly contain bytes from `encoded`'s 32 length bytes that
      //    will be written into the length part of our `ret` slice.
      //  We remedy this issue by writing the length of our `ret` slice at the end, thus
      //    overwritting those garbage bytes.
      let shift := and(length, 31) //equivalent to `mod(length, 32)` but 2 gas cheaper
      if iszero(shift) {
        shift := wordSize
      }

      let dest := add(ret, shift)
      let end := add(dest, length)
      for {
        let src := add(add(encoded, shift), offset)
      } lt(dest, end) {
        src := add(src, wordSize)
        dest := add(dest, wordSize)
      } {
        mstore(dest, mload(src))
      }

      mstore(ret, length)
      //When compiling with --via-ir then normally allocated memory (i.e. via new) will have 32 byte
      //  memory alignment and so we enforce the same memory alignment here.
      mstore(freeMemoryPtr, and(add(dest, 31), not(31)))
    }
  }

  function slice(
    bytes memory encoded,
    uint offset,
    uint length
  ) internal pure returns (bytes memory ret, uint nextOffset) {
    (ret, nextOffset) = sliceUnchecked(encoded, offset, length);
    checkBound(nextOffset, encoded.length);
  }

  function asAddressUnchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (address, uint) {
    (uint160 ret, uint nextOffset) = asUint160Unchecked(encoded, offset);
    return (address(ret), nextOffset);
  }

  function asAddress(
    bytes memory encoded,
    uint offset
  ) internal pure returns (address ret, uint nextOffset) {
    (ret, nextOffset) = asAddressUnchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBoolUnchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bool, uint) {
    (uint8 val, uint nextOffset) = asUint8Unchecked(encoded, offset);
    if (val & 0xfe != 0)
      revert InvalidBoolVal(val);

    uint cleanedVal = uint(val);
    bool ret;
    //skip 2x iszero opcode
    assembly ("memory-safe") {
      ret := cleanedVal
    }
    return (ret, nextOffset);
  }

  function asBool(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bool ret, uint nextOffset) {
    (ret, nextOffset) = asBoolUnchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

/* -------------------------------------------------------------------------------------------------
Remaining library code below was auto-generated by via the following js/node code:

for (let bytes = 1; bytes <= 32; ++bytes) {
  const bits = bytes*8;
  console.log(
`function asUint${bits}Unchecked(
  bytes memory encoded,
  uint offset
) internal pure returns (uint${bits} ret, uint nextOffset) {
  assembly ("memory-safe") {
    nextOffset := add(offset, ${bytes})
    ret := mload(add(encoded, nextOffset))
  }
  return (ret, nextOffset);
}

function asUint${bits}(
  bytes memory encoded,
  uint offset
) internal pure returns (uint${bits} ret, uint nextOffset) {
  (ret, nextOffset) = asUint${bits}Unchecked(encoded, offset);
  checkBound(nextOffset, encoded.length);
}

function asBytes${bytes}Unchecked(
  bytes memory encoded,
  uint offset
) internal pure returns (bytes${bytes}, uint) {
  (uint${bits} ret, uint nextOffset) = asUint${bits}Unchecked(encoded, offset);
  return (bytes${bytes}(ret), nextOffset);
}

function asBytes${bytes}(
  bytes memory encoded,
  uint offset
) internal pure returns (bytes${bytes}, uint) {
  (uint${bits} ret, uint nextOffset) = asUint${bits}(encoded, offset);
  return (bytes${bytes}(ret), nextOffset);
}
`
  );
}
------------------------------------------------------------------------------------------------- */

  function asUint8Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint8 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 1)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint8(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint8 ret, uint nextOffset) {
    (ret, nextOffset) = asUint8Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes1Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes1, uint) {
    (uint8 ret, uint nextOffset) = asUint8Unchecked(encoded, offset);
    return (bytes1(ret), nextOffset);
  }

  function asBytes1(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes1, uint) {
    (uint8 ret, uint nextOffset) = asUint8(encoded, offset);
    return (bytes1(ret), nextOffset);
  }

  function asUint16Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint16 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 2)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint16(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint16 ret, uint nextOffset) {
    (ret, nextOffset) = asUint16Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes2Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes2, uint) {
    (uint16 ret, uint nextOffset) = asUint16Unchecked(encoded, offset);
    return (bytes2(ret), nextOffset);
  }

  function asBytes2(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes2, uint) {
    (uint16 ret, uint nextOffset) = asUint16(encoded, offset);
    return (bytes2(ret), nextOffset);
  }

  function asUint24Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint24 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 3)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint24(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint24 ret, uint nextOffset) {
    (ret, nextOffset) = asUint24Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes3Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes3, uint) {
    (uint24 ret, uint nextOffset) = asUint24Unchecked(encoded, offset);
    return (bytes3(ret), nextOffset);
  }

  function asBytes3(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes3, uint) {
    (uint24 ret, uint nextOffset) = asUint24(encoded, offset);
    return (bytes3(ret), nextOffset);
  }

  function asUint32Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint32 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 4)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint32(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint32 ret, uint nextOffset) {
    (ret, nextOffset) = asUint32Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes4Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes4, uint) {
    (uint32 ret, uint nextOffset) = asUint32Unchecked(encoded, offset);
    return (bytes4(ret), nextOffset);
  }

  function asBytes4(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes4, uint) {
    (uint32 ret, uint nextOffset) = asUint32(encoded, offset);
    return (bytes4(ret), nextOffset);
  }

  function asUint40Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint40 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 5)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint40(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint40 ret, uint nextOffset) {
    (ret, nextOffset) = asUint40Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes5Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes5, uint) {
    (uint40 ret, uint nextOffset) = asUint40Unchecked(encoded, offset);
    return (bytes5(ret), nextOffset);
  }

  function asBytes5(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes5, uint) {
    (uint40 ret, uint nextOffset) = asUint40(encoded, offset);
    return (bytes5(ret), nextOffset);
  }

  function asUint48Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint48 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 6)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint48(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint48 ret, uint nextOffset) {
    (ret, nextOffset) = asUint48Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes6Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes6, uint) {
    (uint48 ret, uint nextOffset) = asUint48Unchecked(encoded, offset);
    return (bytes6(ret), nextOffset);
  }

  function asBytes6(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes6, uint) {
    (uint48 ret, uint nextOffset) = asUint48(encoded, offset);
    return (bytes6(ret), nextOffset);
  }

  function asUint56Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint56 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 7)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint56(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint56 ret, uint nextOffset) {
    (ret, nextOffset) = asUint56Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes7Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes7, uint) {
    (uint56 ret, uint nextOffset) = asUint56Unchecked(encoded, offset);
    return (bytes7(ret), nextOffset);
  }

  function asBytes7(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes7, uint) {
    (uint56 ret, uint nextOffset) = asUint56(encoded, offset);
    return (bytes7(ret), nextOffset);
  }

  function asUint64Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint64 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 8)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint64(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint64 ret, uint nextOffset) {
    (ret, nextOffset) = asUint64Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes8Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes8, uint) {
    (uint64 ret, uint nextOffset) = asUint64Unchecked(encoded, offset);
    return (bytes8(ret), nextOffset);
  }

  function asBytes8(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes8, uint) {
    (uint64 ret, uint nextOffset) = asUint64(encoded, offset);
    return (bytes8(ret), nextOffset);
  }

  function asUint72Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint72 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 9)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint72(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint72 ret, uint nextOffset) {
    (ret, nextOffset) = asUint72Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes9Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes9, uint) {
    (uint72 ret, uint nextOffset) = asUint72Unchecked(encoded, offset);
    return (bytes9(ret), nextOffset);
  }

  function asBytes9(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes9, uint) {
    (uint72 ret, uint nextOffset) = asUint72(encoded, offset);
    return (bytes9(ret), nextOffset);
  }

  function asUint80Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint80 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 10)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint80(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint80 ret, uint nextOffset) {
    (ret, nextOffset) = asUint80Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes10Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes10, uint) {
    (uint80 ret, uint nextOffset) = asUint80Unchecked(encoded, offset);
    return (bytes10(ret), nextOffset);
  }

  function asBytes10(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes10, uint) {
    (uint80 ret, uint nextOffset) = asUint80(encoded, offset);
    return (bytes10(ret), nextOffset);
  }

  function asUint88Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint88 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 11)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint88(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint88 ret, uint nextOffset) {
    (ret, nextOffset) = asUint88Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes11Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes11, uint) {
    (uint88 ret, uint nextOffset) = asUint88Unchecked(encoded, offset);
    return (bytes11(ret), nextOffset);
  }

  function asBytes11(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes11, uint) {
    (uint88 ret, uint nextOffset) = asUint88(encoded, offset);
    return (bytes11(ret), nextOffset);
  }

  function asUint96Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint96 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 12)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint96(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint96 ret, uint nextOffset) {
    (ret, nextOffset) = asUint96Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes12Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes12, uint) {
    (uint96 ret, uint nextOffset) = asUint96Unchecked(encoded, offset);
    return (bytes12(ret), nextOffset);
  }

  function asBytes12(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes12, uint) {
    (uint96 ret, uint nextOffset) = asUint96(encoded, offset);
    return (bytes12(ret), nextOffset);
  }

  function asUint104Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint104 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 13)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint104(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint104 ret, uint nextOffset) {
    (ret, nextOffset) = asUint104Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes13Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes13, uint) {
    (uint104 ret, uint nextOffset) = asUint104Unchecked(encoded, offset);
    return (bytes13(ret), nextOffset);
  }

  function asBytes13(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes13, uint) {
    (uint104 ret, uint nextOffset) = asUint104(encoded, offset);
    return (bytes13(ret), nextOffset);
  }

  function asUint112Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint112 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 14)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint112(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint112 ret, uint nextOffset) {
    (ret, nextOffset) = asUint112Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes14Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes14, uint) {
    (uint112 ret, uint nextOffset) = asUint112Unchecked(encoded, offset);
    return (bytes14(ret), nextOffset);
  }

  function asBytes14(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes14, uint) {
    (uint112 ret, uint nextOffset) = asUint112(encoded, offset);
    return (bytes14(ret), nextOffset);
  }

  function asUint120Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint120 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 15)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint120(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint120 ret, uint nextOffset) {
    (ret, nextOffset) = asUint120Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes15Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes15, uint) {
    (uint120 ret, uint nextOffset) = asUint120Unchecked(encoded, offset);
    return (bytes15(ret), nextOffset);
  }

  function asBytes15(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes15, uint) {
    (uint120 ret, uint nextOffset) = asUint120(encoded, offset);
    return (bytes15(ret), nextOffset);
  }

  function asUint128Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint128 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 16)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint128(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint128 ret, uint nextOffset) {
    (ret, nextOffset) = asUint128Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes16Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes16, uint) {
    (uint128 ret, uint nextOffset) = asUint128Unchecked(encoded, offset);
    return (bytes16(ret), nextOffset);
  }

  function asBytes16(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes16, uint) {
    (uint128 ret, uint nextOffset) = asUint128(encoded, offset);
    return (bytes16(ret), nextOffset);
  }

  function asUint136Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint136 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 17)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint136(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint136 ret, uint nextOffset) {
    (ret, nextOffset) = asUint136Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes17Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes17, uint) {
    (uint136 ret, uint nextOffset) = asUint136Unchecked(encoded, offset);
    return (bytes17(ret), nextOffset);
  }

  function asBytes17(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes17, uint) {
    (uint136 ret, uint nextOffset) = asUint136(encoded, offset);
    return (bytes17(ret), nextOffset);
  }

  function asUint144Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint144 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 18)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint144(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint144 ret, uint nextOffset) {
    (ret, nextOffset) = asUint144Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes18Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes18, uint) {
    (uint144 ret, uint nextOffset) = asUint144Unchecked(encoded, offset);
    return (bytes18(ret), nextOffset);
  }

  function asBytes18(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes18, uint) {
    (uint144 ret, uint nextOffset) = asUint144(encoded, offset);
    return (bytes18(ret), nextOffset);
  }

  function asUint152Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint152 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 19)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint152(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint152 ret, uint nextOffset) {
    (ret, nextOffset) = asUint152Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes19Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes19, uint) {
    (uint152 ret, uint nextOffset) = asUint152Unchecked(encoded, offset);
    return (bytes19(ret), nextOffset);
  }

  function asBytes19(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes19, uint) {
    (uint152 ret, uint nextOffset) = asUint152(encoded, offset);
    return (bytes19(ret), nextOffset);
  }

  function asUint160Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint160 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 20)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint160(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint160 ret, uint nextOffset) {
    (ret, nextOffset) = asUint160Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes20Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes20, uint) {
    (uint160 ret, uint nextOffset) = asUint160Unchecked(encoded, offset);
    return (bytes20(ret), nextOffset);
  }

  function asBytes20(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes20, uint) {
    (uint160 ret, uint nextOffset) = asUint160(encoded, offset);
    return (bytes20(ret), nextOffset);
  }

  function asUint168Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint168 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 21)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint168(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint168 ret, uint nextOffset) {
    (ret, nextOffset) = asUint168Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes21Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes21, uint) {
    (uint168 ret, uint nextOffset) = asUint168Unchecked(encoded, offset);
    return (bytes21(ret), nextOffset);
  }

  function asBytes21(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes21, uint) {
    (uint168 ret, uint nextOffset) = asUint168(encoded, offset);
    return (bytes21(ret), nextOffset);
  }

  function asUint176Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint176 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 22)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint176(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint176 ret, uint nextOffset) {
    (ret, nextOffset) = asUint176Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes22Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes22, uint) {
    (uint176 ret, uint nextOffset) = asUint176Unchecked(encoded, offset);
    return (bytes22(ret), nextOffset);
  }

  function asBytes22(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes22, uint) {
    (uint176 ret, uint nextOffset) = asUint176(encoded, offset);
    return (bytes22(ret), nextOffset);
  }

  function asUint184Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint184 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 23)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint184(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint184 ret, uint nextOffset) {
    (ret, nextOffset) = asUint184Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes23Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes23, uint) {
    (uint184 ret, uint nextOffset) = asUint184Unchecked(encoded, offset);
    return (bytes23(ret), nextOffset);
  }

  function asBytes23(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes23, uint) {
    (uint184 ret, uint nextOffset) = asUint184(encoded, offset);
    return (bytes23(ret), nextOffset);
  }

  function asUint192Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint192 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 24)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint192(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint192 ret, uint nextOffset) {
    (ret, nextOffset) = asUint192Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes24Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes24, uint) {
    (uint192 ret, uint nextOffset) = asUint192Unchecked(encoded, offset);
    return (bytes24(ret), nextOffset);
  }

  function asBytes24(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes24, uint) {
    (uint192 ret, uint nextOffset) = asUint192(encoded, offset);
    return (bytes24(ret), nextOffset);
  }

  function asUint200Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint200 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 25)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint200(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint200 ret, uint nextOffset) {
    (ret, nextOffset) = asUint200Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes25Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes25, uint) {
    (uint200 ret, uint nextOffset) = asUint200Unchecked(encoded, offset);
    return (bytes25(ret), nextOffset);
  }

  function asBytes25(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes25, uint) {
    (uint200 ret, uint nextOffset) = asUint200(encoded, offset);
    return (bytes25(ret), nextOffset);
  }

  function asUint208Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint208 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 26)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint208(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint208 ret, uint nextOffset) {
    (ret, nextOffset) = asUint208Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes26Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes26, uint) {
    (uint208 ret, uint nextOffset) = asUint208Unchecked(encoded, offset);
    return (bytes26(ret), nextOffset);
  }

  function asBytes26(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes26, uint) {
    (uint208 ret, uint nextOffset) = asUint208(encoded, offset);
    return (bytes26(ret), nextOffset);
  }

  function asUint216Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint216 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 27)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint216(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint216 ret, uint nextOffset) {
    (ret, nextOffset) = asUint216Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes27Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes27, uint) {
    (uint216 ret, uint nextOffset) = asUint216Unchecked(encoded, offset);
    return (bytes27(ret), nextOffset);
  }

  function asBytes27(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes27, uint) {
    (uint216 ret, uint nextOffset) = asUint216(encoded, offset);
    return (bytes27(ret), nextOffset);
  }

  function asUint224Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint224 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 28)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint224(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint224 ret, uint nextOffset) {
    (ret, nextOffset) = asUint224Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes28Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes28, uint) {
    (uint224 ret, uint nextOffset) = asUint224Unchecked(encoded, offset);
    return (bytes28(ret), nextOffset);
  }

  function asBytes28(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes28, uint) {
    (uint224 ret, uint nextOffset) = asUint224(encoded, offset);
    return (bytes28(ret), nextOffset);
  }

  function asUint232Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint232 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 29)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint232(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint232 ret, uint nextOffset) {
    (ret, nextOffset) = asUint232Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes29Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes29, uint) {
    (uint232 ret, uint nextOffset) = asUint232Unchecked(encoded, offset);
    return (bytes29(ret), nextOffset);
  }

  function asBytes29(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes29, uint) {
    (uint232 ret, uint nextOffset) = asUint232(encoded, offset);
    return (bytes29(ret), nextOffset);
  }

  function asUint240Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint240 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 30)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint240(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint240 ret, uint nextOffset) {
    (ret, nextOffset) = asUint240Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes30Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes30, uint) {
    (uint240 ret, uint nextOffset) = asUint240Unchecked(encoded, offset);
    return (bytes30(ret), nextOffset);
  }

  function asBytes30(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes30, uint) {
    (uint240 ret, uint nextOffset) = asUint240(encoded, offset);
    return (bytes30(ret), nextOffset);
  }

  function asUint248Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint248 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 31)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint248(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint248 ret, uint nextOffset) {
    (ret, nextOffset) = asUint248Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes31Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes31, uint) {
    (uint248 ret, uint nextOffset) = asUint248Unchecked(encoded, offset);
    return (bytes31(ret), nextOffset);
  }

  function asBytes31(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes31, uint) {
    (uint248 ret, uint nextOffset) = asUint248(encoded, offset);
    return (bytes31(ret), nextOffset);
  }

  function asUint256Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint256 ret, uint nextOffset) {
    assembly ("memory-safe") {
      nextOffset := add(offset, 32)
      ret := mload(add(encoded, nextOffset))
    }
    return (ret, nextOffset);
  }

  function asUint256(
    bytes memory encoded,
    uint offset
  ) internal pure returns (uint256 ret, uint nextOffset) {
    (ret, nextOffset) = asUint256Unchecked(encoded, offset);
    checkBound(nextOffset, encoded.length);
  }

  function asBytes32Unchecked(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes32, uint) {
    (uint256 ret, uint nextOffset) = asUint256Unchecked(encoded, offset);
    return (bytes32(ret), nextOffset);
  }

  function asBytes32(
    bytes memory encoded,
    uint offset
  ) internal pure returns (bytes32, uint) {
    (uint256 ret, uint nextOffset) = asUint256(encoded, offset);
    return (bytes32(ret), nextOffset);
  }
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

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

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(
        address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel
    );
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
        external
        payable
        returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet)
        external
        pure
        returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint256 numGuardians) external pure returns (uint256 numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade)
        external
        pure
        returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId)
        external
        pure
        returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

error InvalidFork(uint256 evmChainId, uint256 blockChainId);

function checkFork(uint256 evmChainId) view {
    if (isFork(evmChainId)) {
        revert InvalidFork(evmChainId, block.chainid);
    }
}

function isFork(uint256 evmChainId) view returns (bool) {
    return evmChainId != block.chainid;
}

function min(uint256 a, uint256 b) pure returns (uint256) {
    return a < b ? a : b;
}

// @dev Count the number of set bits in a uint64
function countSetBits(uint64 x) pure returns (uint8 count) {
    while (x != 0) {
        x &= x - 1;
        count++;
    }

    return count;
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "wormhole-solidity-sdk/libraries/BytesParsing.sol";
import "./TrimmedAmount.sol";

library TransceiverStructs {
    using BytesParsing for bytes;
    using TrimmedAmountLib for TrimmedAmount;

    /// @notice Error thrown when the payload length exceeds the allowed maximum.
    /// @dev Selector 0xa3419691.
    /// @param size The size of the payload.
    error PayloadTooLong(uint256 size);

    /// @notice Error thrown when the prefix of an encoded message
    ///         does not match the expected value.
    /// @dev Selector 0x56d2569d.
    /// @param prefix The prefix that was found in the encoded message.
    error IncorrectPrefix(bytes4 prefix);

    /// @notice Error thrown when the transceiver instructions aren't
    ///         encoded with strictly increasing indices
    /// @dev Selector 0x0555a4b9.
    /// @param lastIndex Last parsed instruction index
    /// @param instructionIndex The instruction index that was unordered
    error UnorderedInstructions(uint256 lastIndex, uint256 instructionIndex);

    /// @notice Error thrown when a transceiver instruction index
    ///         is greater than the number of registered transceivers
    /// @dev We index from 0 so if providedIndex == numTransceivers then we're out-of-bounds too
    /// @dev Selector 0x689f5016.
    /// @param providedIndex The index specified in the instruction
    /// @param numTransceivers The number of registered transceivers
    error InvalidInstructionIndex(uint256 providedIndex, uint256 numTransceivers);

    /// @dev Prefix for all NativeTokenTransfer payloads
    ///      This is 0x99'N''T''T'
    bytes4 constant NTT_PREFIX = 0x994E5454;

    /// @dev Message emitted and received by the nttManager contract.
    ///      The wire format is as follows:
    ///      - id - 32 bytes
    ///      - sender - 32 bytes
    ///      - payloadLength - 2 bytes
    ///      - payload - `payloadLength` bytes
    struct NttManagerMessage {
        /// @notice unique message identifier
        /// @dev This is incrementally assigned on EVM chains, but this is not
        /// guaranteed on other runtimes.
        bytes32 id;
        /// @notice original message sender address.
        bytes32 sender;
        /// @notice payload that corresponds to the type.
        bytes payload;
    }

    function nttManagerMessageDigest(
        uint16 sourceChainId,
        NttManagerMessage memory m
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sourceChainId, encodeNttManagerMessage(m)));
    }

    function encodeNttManagerMessage(NttManagerMessage memory m)
        public
        pure
        returns (bytes memory encoded)
    {
        if (m.payload.length > type(uint16).max) {
            revert PayloadTooLong(m.payload.length);
        }
        uint16 payloadLength = uint16(m.payload.length);
        return abi.encodePacked(m.id, m.sender, payloadLength, m.payload);
    }

    /// @notice Parse a NttManagerMessage.
    /// @param encoded The byte array corresponding to the encoded message
    /// @return nttManagerMessage The parsed NttManagerMessage struct.
    function parseNttManagerMessage(bytes memory encoded)
        public
        pure
        returns (NttManagerMessage memory nttManagerMessage)
    {
        uint256 offset = 0;
        (nttManagerMessage.id, offset) = encoded.asBytes32Unchecked(offset);
        (nttManagerMessage.sender, offset) = encoded.asBytes32Unchecked(offset);
        uint256 payloadLength;
        (payloadLength, offset) = encoded.asUint16Unchecked(offset);
        (nttManagerMessage.payload, offset) = encoded.sliceUnchecked(offset, payloadLength);
        encoded.checkLength(offset);
    }

    /// @dev Native Token Transfer payload.
    ///      The wire format is as follows:
    ///      - NTT_PREFIX - 4 bytes
    ///      - numDecimals - 1 byte
    ///      - amount - 8 bytes
    ///      - sourceToken - 32 bytes
    ///      - to - 32 bytes
    ///      - toChain - 2 bytes
    struct NativeTokenTransfer {
        /// @notice Amount being transferred (big-endian u64 and u8 for decimals)
        TrimmedAmount amount;
        /// @notice Source chain token address.
        bytes32 sourceToken;
        /// @notice Address of the recipient.
        bytes32 to;
        /// @notice Chain ID of the recipient
        uint16 toChain;
    }

    function encodeNativeTokenTransfer(NativeTokenTransfer memory m)
        public
        pure
        returns (bytes memory encoded)
    {
        // The `amount` and `decimals` fields are encoded in reverse order compared to how they are declared in the
        // `TrimmedAmount` type. This is consistent with the Rust NTT implementation.
        TrimmedAmount transferAmount = m.amount;
        return abi.encodePacked(
            NTT_PREFIX,
            transferAmount.getDecimals(),
            transferAmount.getAmount(),
            m.sourceToken,
            m.to,
            m.toChain
        );
    }

    /// @dev Parse a NativeTokenTransfer.
    /// @param encoded The byte array corresponding to the encoded message
    /// @return nativeTokenTransfer The parsed NativeTokenTransfer struct.
    function parseNativeTokenTransfer(bytes memory encoded)
        public
        pure
        returns (NativeTokenTransfer memory nativeTokenTransfer)
    {
        uint256 offset = 0;
        bytes4 prefix;
        (prefix, offset) = encoded.asBytes4Unchecked(offset);
        if (prefix != NTT_PREFIX) {
            revert IncorrectPrefix(prefix);
        }

        // The `amount` and `decimals` fields are parsed in reverse order compared to how they are declared in the
        // `TrimmedAmount` struct. This is consistent with the Rust NTT implementation.
        uint8 numDecimals;
        (numDecimals, offset) = encoded.asUint8Unchecked(offset);
        uint64 amount;
        (amount, offset) = encoded.asUint64Unchecked(offset);
        nativeTokenTransfer.amount = packTrimmedAmount(amount, numDecimals);

        (nativeTokenTransfer.sourceToken, offset) = encoded.asBytes32Unchecked(offset);
        (nativeTokenTransfer.to, offset) = encoded.asBytes32Unchecked(offset);
        (nativeTokenTransfer.toChain, offset) = encoded.asUint16Unchecked(offset);
        encoded.checkLength(offset);
    }

    /// @dev Message emitted by Transceiver implementations.
    ///      Each message includes an Transceiver-specified 4-byte prefix.
    ///      The wire format is as follows:
    ///      - prefix - 4 bytes
    ///      - sourceNttManagerAddress - 32 bytes
    ///      - recipientNttManagerAddress - 32 bytes
    ///      - nttManagerPayloadLength - 2 bytes
    ///      - nttManagerPayload - `nttManagerPayloadLength` bytes
    ///      - transceiverPayloadLength - 2 bytes
    ///      - transceiverPayload - `transceiverPayloadLength` bytes
    struct TransceiverMessage {
        /// @notice Address of the NttManager contract that emitted this message.
        bytes32 sourceNttManagerAddress;
        /// @notice Address of the NttManager contract that receives this message.
        bytes32 recipientNttManagerAddress;
        /// @notice Payload provided to the Transceiver contract by the NttManager contract.
        bytes nttManagerPayload;
        /// @notice Optional payload that the transceiver can encode and use for its own message passing purposes.
        bytes transceiverPayload;
    }

    // @notice Encodes an Transceiver message for communication between the
    //         NttManager and the Transceiver.
    // @param m The TransceiverMessage struct containing the message details.
    // @return encoded The byte array corresponding to the encoded message.
    // @custom:throw PayloadTooLong if the length of transceiverId, nttManagerPayload,
    //         or transceiverPayload exceeds the allowed maximum.
    function encodeTransceiverMessage(
        bytes4 prefix,
        TransceiverMessage memory m
    ) public pure returns (bytes memory encoded) {
        if (m.nttManagerPayload.length > type(uint16).max) {
            revert PayloadTooLong(m.nttManagerPayload.length);
        }
        uint16 nttManagerPayloadLength = uint16(m.nttManagerPayload.length);

        if (m.transceiverPayload.length > type(uint16).max) {
            revert PayloadTooLong(m.transceiverPayload.length);
        }
        uint16 transceiverPayloadLength = uint16(m.transceiverPayload.length);

        return abi.encodePacked(
            prefix,
            m.sourceNttManagerAddress,
            m.recipientNttManagerAddress,
            nttManagerPayloadLength,
            m.nttManagerPayload,
            transceiverPayloadLength,
            m.transceiverPayload
        );
    }

    function buildAndEncodeTransceiverMessage(
        bytes4 prefix,
        bytes32 sourceNttManagerAddress,
        bytes32 recipientNttManagerAddress,
        bytes memory nttManagerMessage,
        bytes memory transceiverPayload
    ) public pure returns (TransceiverMessage memory, bytes memory) {
        TransceiverMessage memory transceiverMessage = TransceiverMessage({
            sourceNttManagerAddress: sourceNttManagerAddress,
            recipientNttManagerAddress: recipientNttManagerAddress,
            nttManagerPayload: nttManagerMessage,
            transceiverPayload: transceiverPayload
        });
        bytes memory encoded = encodeTransceiverMessage(prefix, transceiverMessage);
        return (transceiverMessage, encoded);
    }

    /// @dev Parses an encoded message and extracts information into an TransceiverMessage struct.
    /// @param encoded The encoded bytes containing information about the TransceiverMessage.
    /// @return transceiverMessage The parsed TransceiverMessage struct.
    /// @custom:throw IncorrectPrefix if the prefix of the encoded message does not
    ///         match the expected prefix.
    function parseTransceiverMessage(
        bytes4 expectedPrefix,
        bytes memory encoded
    ) internal pure returns (TransceiverMessage memory transceiverMessage) {
        uint256 offset = 0;
        bytes4 prefix;

        (prefix, offset) = encoded.asBytes4Unchecked(offset);

        if (prefix != expectedPrefix) {
            revert IncorrectPrefix(prefix);
        }

        (transceiverMessage.sourceNttManagerAddress, offset) = encoded.asBytes32Unchecked(offset);
        (transceiverMessage.recipientNttManagerAddress, offset) = encoded.asBytes32Unchecked(offset);
        uint16 nttManagerPayloadLength;
        (nttManagerPayloadLength, offset) = encoded.asUint16Unchecked(offset);
        (transceiverMessage.nttManagerPayload, offset) =
            encoded.sliceUnchecked(offset, nttManagerPayloadLength);
        uint16 transceiverPayloadLength;
        (transceiverPayloadLength, offset) = encoded.asUint16Unchecked(offset);
        (transceiverMessage.transceiverPayload, offset) =
            encoded.sliceUnchecked(offset, transceiverPayloadLength);

        // Check if the entire byte array has been processed
        encoded.checkLength(offset);
    }

    /// @dev Parses the payload of an Transceiver message and returns
    ///      the parsed NttManagerMessage struct.
    /// @param expectedPrefix The prefix that should be encoded in the nttManager message.
    /// @param payload The payload sent across the wire.
    function parseTransceiverAndNttManagerMessage(
        bytes4 expectedPrefix,
        bytes memory payload
    ) public pure returns (TransceiverMessage memory, NttManagerMessage memory) {
        // parse the encoded message payload from the Transceiver
        TransceiverMessage memory parsedTransceiverMessage =
            parseTransceiverMessage(expectedPrefix, payload);

        // parse the encoded message payload from the NttManager
        NttManagerMessage memory parsedNttManagerMessage =
            parseNttManagerMessage(parsedTransceiverMessage.nttManagerPayload);

        return (parsedTransceiverMessage, parsedNttManagerMessage);
    }

    /// @dev Variable-length transceiver-specific instruction that can be passed by the caller to the nttManager.
    ///      The index field refers to the index of the registeredTransceiver that this instruction should be passed to.
    ///      The serialization format is:
    ///      - index - 1 byte
    ///      - payloadLength - 1 byte
    ///      - payload - `payloadLength` bytes
    struct TransceiverInstruction {
        uint8 index;
        bytes payload;
    }

    function encodeTransceiverInstruction(TransceiverInstruction memory instruction)
        public
        pure
        returns (bytes memory)
    {
        if (instruction.payload.length > type(uint8).max) {
            revert PayloadTooLong(instruction.payload.length);
        }
        uint8 payloadLength = uint8(instruction.payload.length);
        return abi.encodePacked(instruction.index, payloadLength, instruction.payload);
    }

    function parseTransceiverInstructionUnchecked(
        bytes memory encoded,
        uint256 offset
    ) public pure returns (TransceiverInstruction memory instruction, uint256 nextOffset) {
        (instruction.index, nextOffset) = encoded.asUint8Unchecked(offset);
        uint8 instructionLength;
        (instructionLength, nextOffset) = encoded.asUint8Unchecked(nextOffset);
        (instruction.payload, nextOffset) = encoded.sliceUnchecked(nextOffset, instructionLength);
    }

    function parseTransceiverInstructionChecked(bytes memory encoded)
        public
        pure
        returns (TransceiverInstruction memory instruction)
    {
        uint256 offset = 0;
        (instruction, offset) = parseTransceiverInstructionUnchecked(encoded, offset);
        encoded.checkLength(offset);
    }

    /// @dev Encode an array of multiple variable-length transceiver-specific instructions.
    ///      The serialization format is:
    ///      - instructionsLength - 1 byte
    ///      - `instructionsLength` number of serialized `TransceiverInstruction` types.
    function encodeTransceiverInstructions(TransceiverInstruction[] memory instructions)
        public
        pure
        returns (bytes memory)
    {
        if (instructions.length > type(uint8).max) {
            revert PayloadTooLong(instructions.length);
        }
        uint256 instructionsLength = instructions.length;

        bytes memory encoded;
        for (uint256 i = 0; i < instructionsLength; i++) {
            bytes memory innerEncoded = encodeTransceiverInstruction(instructions[i]);
            encoded = bytes.concat(encoded, innerEncoded);
        }
        return abi.encodePacked(uint8(instructionsLength), encoded);
    }

    function parseTransceiverInstructions(
        bytes memory encoded,
        uint256 numRegisteredTransceivers
    ) public pure returns (TransceiverInstruction[] memory) {
        uint256 offset = 0;
        uint256 instructionsLength;
        (instructionsLength, offset) = encoded.asUint8Unchecked(offset);

        // We allocate an array with the length of the number of registered transceivers
        // This gives us the flexibility to not have to pass instructions for transceivers that
        // don't need them
        TransceiverInstruction[] memory instructions =
            new TransceiverInstruction[](numRegisteredTransceivers);

        uint256 lastIndex = 0;
        for (uint256 i = 0; i < instructionsLength; i++) {
            TransceiverInstruction memory instruction;
            (instruction, offset) = parseTransceiverInstructionUnchecked(encoded, offset);

            uint8 instructionIndex = instruction.index;

            // The instructions passed in have to be strictly increasing in terms of transceiver index
            if (i != 0 && instructionIndex <= lastIndex) {
                revert UnorderedInstructions(lastIndex, instructionIndex);
            }

            // Instruction index is out of bounds
            if (instructionIndex >= numRegisteredTransceivers) {
                revert InvalidInstructionIndex(instructionIndex, numRegisteredTransceivers);
            }

            lastIndex = instructionIndex;

            instructions[instructionIndex] = instruction;
        }

        encoded.checkLength(offset);

        return instructions;
    }

    struct TransceiverInit {
        bytes4 transceiverIdentifier;
        bytes32 nttManagerAddress;
        uint8 nttManagerMode;
        bytes32 tokenAddress;
        uint8 tokenDecimals;
    }

    function encodeTransceiverInit(TransceiverInit memory init)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            init.transceiverIdentifier,
            init.nttManagerAddress,
            init.nttManagerMode,
            init.tokenAddress,
            init.tokenDecimals
        );
    }

    function decodeTransceiverInit(bytes memory encoded)
        public
        pure
        returns (TransceiverInit memory init)
    {
        uint256 offset = 0;
        (init.transceiverIdentifier, offset) = encoded.asBytes4Unchecked(offset);
        (init.nttManagerAddress, offset) = encoded.asBytes32Unchecked(offset);
        (init.nttManagerMode, offset) = encoded.asUint8Unchecked(offset);
        (init.tokenAddress, offset) = encoded.asBytes32Unchecked(offset);
        (init.tokenDecimals, offset) = encoded.asUint8Unchecked(offset);
        encoded.checkLength(offset);
    }

    struct TransceiverRegistration {
        bytes4 transceiverIdentifier;
        uint16 transceiverChainId;
        bytes32 transceiverAddress;
    }

    function encodeTransceiverRegistration(TransceiverRegistration memory registration)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            registration.transceiverIdentifier,
            registration.transceiverChainId,
            registration.transceiverAddress
        );
    }

    function decodeTransceiverRegistration(bytes memory encoded)
        public
        pure
        returns (TransceiverRegistration memory registration)
    {
        uint256 offset = 0;
        (registration.transceiverIdentifier, offset) = encoded.asBytes4Unchecked(offset);
        (registration.transceiverChainId, offset) = encoded.asUint16Unchecked(offset);
        (registration.transceiverAddress, offset) = encoded.asBytes32Unchecked(offset);
        encoded.checkLength(offset);
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "../libraries/TransceiverStructs.sol";

import "./IWormholeTransceiverState.sol";

interface IWormholeTransceiver is IWormholeTransceiverState {
    /// @notice The instruction for the WormholeTransceiver contract
    ///         to skip delivery via the relayer.
    struct WormholeTransceiverInstruction {
        bool shouldSkipRelayerSend;
    }

    /// @notice Emitted when a relayed message is received.
    /// @dev Topic0
    ///      0xf557dbbb087662f52c815f6c7ee350628a37a51eae9608ff840d996b65f87475
    /// @param digest The digest of the message.
    /// @param emitterChainId The chain ID of the emitter.
    /// @param emitterAddress The address of the emitter.
    event ReceivedRelayedMessage(bytes32 digest, uint16 emitterChainId, bytes32 emitterAddress);

    /// @notice Emitted when a message is received.
    /// @dev Topic0
    ///     0xf6fc529540981400dc64edf649eb5e2e0eb5812a27f8c81bac2c1d317e71a5f0.
    /// @param digest The digest of the message.
    /// @param emitterChainId The chain ID of the emitter.
    /// @param emitterAddress The address of the emitter.
    /// @param sequence The sequence of the message.
    event ReceivedMessage(
        bytes32 digest, uint16 emitterChainId, bytes32 emitterAddress, uint64 sequence
    );

    /// @notice Emitted when a message is sent from the transceiver.
    /// @dev Topic0
    ///      0x53b3e029c5ead7bffc739118953883859d30b1aaa086e0dca4d0a1c99cd9c3f5.
    /// @param recipientChain The chain ID of the recipient.
    /// @param message The message.
    event SendTransceiverMessage(
        uint16 recipientChain, TransceiverStructs.TransceiverMessage message
    );

    /// @notice Error when the relaying configuration is invalid. (e.g. chainId is not registered)
    /// @dev Selector: 0x9449a36c.
    /// @param chainId The chain ID that is invalid.
    error InvalidRelayingConfig(uint16 chainId);

    /// @notice Error when the peer transceiver is invalid.
    /// @dev Selector: 0x79b1ce56.
    /// @param chainId The chain ID of the peer.
    /// @param peerAddress The address of the invalid peer.
    error InvalidWormholePeer(uint16 chainId, bytes32 peerAddress);

    /// @notice Error when the VAA has already been consumed.
    /// @dev Selector: 0x406e719e.
    /// @param vaaHash The hash of the VAA.
    error TransferAlreadyCompleted(bytes32 vaaHash);

    /// @notice Receive an attested message from the verification layer.
    ///         This function should verify the `encodedVm` and then deliver the attestation
    /// to the transceiver NttManager contract.
    /// @param encodedMessage The attested message.
    function receiveMessage(bytes memory encodedMessage) external;

    /// @notice Parses the encoded instruction and returns the instruction struct.
    ///         This instruction is specific to the WormholeTransceiver contract.
    /// @param encoded The encoded instruction.
    /// @return instruction The parsed `WormholeTransceiverInstruction`.
    function parseWormholeTransceiverInstruction(bytes memory encoded)
        external
        pure
        returns (WormholeTransceiverInstruction memory instruction);

    /// @notice Encodes the `WormholeTransceiverInstruction` into a byte array.
    /// @param instruction The `WormholeTransceiverInstruction` to encode.
    /// @return encoded The encoded instruction.
    function encodeWormholeTransceiverInstruction(WormholeTransceiverInstruction memory instruction)
        external
        pure
        returns (bytes memory);
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

interface ISpecialRelayer {
    function quoteDeliveryPrice(
        address sourceContract,
        uint16 targetChain,
        uint256 additionalValue
    ) external view returns (uint256 nativePriceQuote);

    function requestDelivery(
        address sourceContract,
        uint16 targetChain,
        uint256 additionalValue,
        uint64 sequence
    ) external payable;
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "../libraries/TrimmedAmount.sol";
import "../libraries/TransceiverStructs.sol";

import "./IManagerBase.sol";

interface INttManager is IManagerBase {
    /// @dev The peer on another chain.
    struct NttManagerPeer {
        bytes32 peerAddress;
        uint8 tokenDecimals;
    }

    /// @notice Emitted when a message is sent from the nttManager.
    /// @dev Topic0
    ///      0x9cc8ade41ef46b98ba8bcad8c6bfa643934e6b84d3ce066cd38b5f0813bb2ae5.
    /// @param recipient The recipient of the message.
    /// @param refundAddress The address on the destination chain to which the
    ///                      refund of unused gas will be paid
    /// @param amount The amount transferred.
    /// @param fee The amount of ether sent along with the tx to cover the delivery fee.
    /// @param recipientChain The chain ID of the recipient.
    /// @param msgSequence The unique sequence ID of the message.
    event TransferSent(
        bytes32 recipient,
        bytes32 refundAddress,
        uint256 amount,
        uint256 fee,
        uint16 recipientChain,
        uint64 msgSequence
    );

    /// @notice Emitted when the peer contract is updated.
    /// @dev Topic0
    ///      0x1456404e7f41f35c3daac941bb50bad417a66275c3040061b4287d787719599d.
    /// @param chainId_ The chain ID of the peer contract.
    /// @param oldPeerContract The old peer contract address.
    /// @param oldPeerDecimals The old peer contract decimals.
    /// @param peerContract The new peer contract address.
    /// @param peerDecimals The new peer contract decimals.
    event PeerUpdated(
        uint16 indexed chainId_,
        bytes32 oldPeerContract,
        uint8 oldPeerDecimals,
        bytes32 peerContract,
        uint8 peerDecimals
    );

    /// @notice Emitted when a transfer has been redeemed
    ///         (either minted or unlocked on the recipient chain).
    /// @dev Topic0
    ///      0x504e6efe18ab9eed10dc6501a417f5b12a2f7f2b1593aed9b89f9bce3cf29a91.
    /// @param digest The digest of the message.
    event TransferRedeemed(bytes32 indexed digest);

    /// @notice Emitted when an outbound transfer has been cancelled
    /// @dev Topic0
    ///      0xf80e572ae1b63e2449629b6c7d783add85c36473926f216077f17ee002bcfd07.
    /// @param sequence The sequence number being cancelled
    /// @param recipient The canceller and recipient of the funds
    /// @param amount The amount of the transfer being cancelled
    event OutboundTransferCancelled(uint256 sequence, address recipient, uint256 amount);

    /// @notice The transfer has some dust.
    /// @dev Selector 0x71f0634a
    /// @dev This is a security measure to prevent users from losing funds.
    ///      This is the result of trimming the amount and then untrimming it.
    /// @param  amount The amount to transfer.
    error TransferAmountHasDust(uint256 amount, uint256 dust);

    /// @notice The mode is invalid. It is neither in LOCKING or BURNING mode.
    /// @dev Selector 0x66001a89
    /// @param mode The mode.
    error InvalidMode(uint8 mode);

    /// @notice Error when trying to execute a message on an unintended target chain.
    /// @dev Selector 0x3dcb204a.
    /// @param targetChain The target chain.
    /// @param thisChain The current chain.
    error InvalidTargetChain(uint16 targetChain, uint16 thisChain);

    /// @notice Error when the transfer amount is zero.
    /// @dev Selector 0x9993626a.
    error ZeroAmount();

    /// @notice Error when the recipient is invalid.
    /// @dev Selector 0x9c8d2cd2.
    error InvalidRecipient();

    /// @notice Error when the recipient is invalid.
    /// @dev Selector 0xe2fe2726.
    error InvalidRefundAddress();

    /// @notice Error when the amount burned is different than the balance difference,
    ///         since NTT does not support burn fees.
    /// @dev Selector 0x02156a8f.
    /// @param burnAmount The amount burned.
    /// @param balanceDiff The balance after burning.
    error BurnAmountDifferentThanBalanceDiff(uint256 burnAmount, uint256 balanceDiff);

    /// @notice The caller is not the deployer.
    error UnexpectedDeployer(address expectedOwner, address owner);

    /// @notice Peer for the chain does not match the configuration.
    /// @param chainId ChainId of the source chain.
    /// @param peerAddress Address of the peer nttManager contract.
    error InvalidPeer(uint16 chainId, bytes32 peerAddress);

    /// @notice Peer chain ID cannot be zero.
    error InvalidPeerChainIdZero();

    /// @notice Peer cannot be the zero address.
    error InvalidPeerZeroAddress();

    /// @notice Peer cannot have zero decimals.
    error InvalidPeerDecimals();

    /// @notice Staticcall reverted
    /// @dev Selector 0x1222cd83
    error StaticcallFailed();

    /// @notice Error when someone other than the original sender tries to cancel a queued outbound transfer.
    /// @dev Selector 0xceb40a85.
    /// @param canceller The address trying to cancel the transfer.
    /// @param sender The original sender that initiated the transfer that was queued.
    error CancellerNotSender(address canceller, address sender);

    /// @notice An unexpected msg.value was passed with the call
    /// @dev Selector 0xbd28e889.
    error UnexpectedMsgValue();

    /// @notice Peer cannot be on the same chain
    /// @dev Selector 0x20371f2a.
    error InvalidPeerSameChainId();

    /// @notice Transfer a given amount to a recipient on a given chain. This function is called
    ///         by the user to send the token cross-chain. This function will either lock or burn the
    ///         sender's tokens. Finally, this function will call into registered `Endpoint` contracts
    ///         to send a message with the incrementing sequence number and the token transfer payload.
    /// @param amount The amount to transfer.
    /// @param recipientChain The chain ID for the destination.
    /// @param recipient The recipient address.
    function transfer(
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient
    ) external payable returns (uint64 msgId);

    /// @notice Transfer a given amount to a recipient on a given chain. This function is called
    ///         by the user to send the token cross-chain. This function will either lock or burn the
    ///         sender's tokens. Finally, this function will call into registered `Endpoint` contracts
    ///         to send a message with the incrementing sequence number and the token transfer payload.
    /// @dev Transfers are queued if the outbound limit is hit and must be completed by the client.
    /// @param amount The amount to transfer.
    /// @param recipientChain The chain ID for the destination.
    /// @param recipient The recipient address.
    /// @param refundAddress The address to which a refund for unussed gas is issued on the recipient chain.
    /// @param shouldQueue Whether the transfer should be queued if the outbound limit is hit.
    /// @param encodedInstructions Additional instructions to be forwarded to the recipient chain.
    function transfer(
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        bytes32 refundAddress,
        bool shouldQueue,
        bytes memory encodedInstructions
    ) external payable returns (uint64 msgId);

    /// @notice Complete an outbound transfer that's been queued.
    /// @dev This method is called by the client to complete an outbound transfer that's been queued.
    /// @param queueSequence The sequence of the message in the queue.
    /// @return msgSequence The sequence of the message.
    function completeOutboundQueuedTransfer(uint64 queueSequence)
        external
        payable
        returns (uint64 msgSequence);

    /// @notice Cancels an outbound transfer that's been queued.
    /// @dev This method is called by the client to cancel an outbound transfer that's been queued.
    /// @param queueSequence The sequence of the message in the queue.
    function cancelOutboundQueuedTransfer(uint64 queueSequence) external;

    /// @notice Complete an inbound queued transfer.
    /// @param digest The digest of the message to complete.
    function completeInboundQueuedTransfer(bytes32 digest) external;

    /// @notice Called by an Endpoint contract to deliver a verified attestation.
    /// @dev This function enforces attestation threshold and replay logic for messages. Once all
    ///      validations are complete, this function calls `executeMsg` to execute the command specified
    ///      by the message.
    /// @param sourceChainId The chain id of the sender.
    /// @param sourceNttManagerAddress The address of the sender's nttManager contract.
    /// @param payload The VAA payload.
    function attestationReceived(
        uint16 sourceChainId,
        bytes32 sourceNttManagerAddress,
        TransceiverStructs.NttManagerMessage memory payload
    ) external;

    /// @notice Called after a message has been sufficiently verified to execute
    ///         the command in the message. This function will decode the payload
    ///         as an NttManagerMessage to extract the sequence, msgType, and other parameters.
    /// @dev This function is exposed as a fallback for when an `Transceiver` is deregistered
    ///      when a message is in flight.
    /// @param sourceChainId The chain id of the sender.
    /// @param sourceNttManagerAddress The address of the sender's nttManager contract.
    /// @param message The message to execute.
    function executeMsg(
        uint16 sourceChainId,
        bytes32 sourceNttManagerAddress,
        TransceiverStructs.NttManagerMessage memory message
    ) external;

    /// @notice Returns the number of decimals of the token managed by the NttManager.
    /// @return decimals The number of decimals of the token.
    function tokenDecimals() external view returns (uint8);

    /// @notice Returns registered peer contract for a given chain.
    /// @param chainId_ chain ID.
    function getPeer(uint16 chainId_) external view returns (NttManagerPeer memory);

    /// @notice Sets the corresponding peer.
    /// @dev The nttManager that executes the message sets the source nttManager as the peer.
    /// @param peerChainId The chain ID of the peer.
    /// @param peerContract The address of the peer nttManager contract.
    /// @param decimals The number of decimals of the token on the peer chain.
    /// @param inboundLimit The inbound rate limit for the peer chain id
    function setPeer(
        uint16 peerChainId,
        bytes32 peerContract,
        uint8 decimals,
        uint256 inboundLimit
    ) external;

    /// @notice Sets the outbound transfer limit for a given chain.
    /// @dev This method can only be executed by the `owner`.
    /// @param limit The new outbound limit.
    function setOutboundLimit(uint256 limit) external;

    /// @notice Sets the inbound transfer limit for a given chain.
    /// @dev This method can only be executed by the `owner`.
    /// @param limit The new limit.
    /// @param chainId The chain to set the limit for.
    function setInboundLimit(uint256 limit, uint16 chainId) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "wormhole-solidity-sdk/WormholeRelayerSDK.sol";
import "wormhole-solidity-sdk/libraries/BytesParsing.sol";
import "wormhole-solidity-sdk/interfaces/IWormhole.sol";

import "../../libraries/TransceiverHelpers.sol";
import "../../libraries/BooleanFlag.sol";
import "../../libraries/TransceiverStructs.sol";

import "../../interfaces/IWormholeTransceiver.sol";
import "../../interfaces/IWormholeTransceiverState.sol";
import "../../interfaces/ISpecialRelayer.sol";
import "../../interfaces/INttManager.sol";

import "../Transceiver.sol";

abstract contract WormholeTransceiverState is IWormholeTransceiverState, Transceiver {
    using BytesParsing for bytes;
    using BooleanFlagLib for bool;
    using BooleanFlagLib for BooleanFlag;

    // ==================== Immutables ===============================================
    uint8 public immutable consistencyLevel;
    IWormhole public immutable wormhole;
    IWormholeRelayer public immutable wormholeRelayer;
    ISpecialRelayer public immutable specialRelayer;
    uint256 immutable wormholeTransceiver_evmChainId;
    uint256 public immutable gasLimit;

    // ==================== Constants ================================================

    /// @dev Prefix for all TransceiverMessage payloads
    ///      This is 0x99'E''W''H'
    /// @notice Magic string (constant value set by messaging provider) that idenfies the payload as an transceiver-emitted payload.
    ///         Note that this is not a security critical field. It's meant to be used by messaging providers to identify which messages are Transceiver-related.
    bytes4 constant WH_TRANSCEIVER_PAYLOAD_PREFIX = 0x9945FF10;

    /// @dev Prefix for all Wormhole transceiver initialisation payloads
    ///      This is bytes4(keccak256("WormholeTransceiverInit"))
    bytes4 constant WH_TRANSCEIVER_INIT_PREFIX = 0x9c23bd3b;

    /// @dev Prefix for all Wormhole peer registration payloads
    ///      This is bytes4(keccak256("WormholePeerRegistration"))
    bytes4 constant WH_PEER_REGISTRATION_PREFIX = 0x18fc67c2;

    constructor(
        address nttManager,
        address wormholeCoreBridge,
        address wormholeRelayerAddr,
        address specialRelayerAddr,
        uint8 _consistencyLevel,
        uint256 _gasLimit
    ) Transceiver(nttManager) {
        wormhole = IWormhole(wormholeCoreBridge);
        wormholeRelayer = IWormholeRelayer(wormholeRelayerAddr);
        specialRelayer = ISpecialRelayer(specialRelayerAddr);
        wormholeTransceiver_evmChainId = block.chainid;
        consistencyLevel = _consistencyLevel;
        gasLimit = _gasLimit;
    }

    enum RelayingType {
        Standard,
        Special,
        Manual
    }

    function _initialize() internal override {
        super._initialize();
        _initializeTransceiver();
    }

    function _initializeTransceiver() internal {
        TransceiverStructs.TransceiverInit memory init = TransceiverStructs.TransceiverInit({
            transceiverIdentifier: WH_TRANSCEIVER_INIT_PREFIX,
            nttManagerAddress: toWormholeFormat(nttManager),
            nttManagerMode: INttManager(nttManager).getMode(),
            tokenAddress: toWormholeFormat(nttManagerToken),
            tokenDecimals: INttManager(nttManager).tokenDecimals()
        });
        wormhole.publishMessage{value: msg.value}(
            0, TransceiverStructs.encodeTransceiverInit(init), consistencyLevel
        );
    }

    function _checkImmutables() internal view override {
        super._checkImmutables();
        assert(this.wormhole() == wormhole);
        assert(this.wormholeRelayer() == wormholeRelayer);
        assert(this.specialRelayer() == specialRelayer);
        assert(this.consistencyLevel() == consistencyLevel);
    }

    // =============== Storage ===============================================

    bytes32 private constant WORMHOLE_CONSUMED_VAAS_SLOT =
        bytes32(uint256(keccak256("whTransceiver.consumedVAAs")) - 1);

    bytes32 private constant WORMHOLE_PEERS_SLOT =
        bytes32(uint256(keccak256("whTransceiver.peers")) - 1);

    bytes32 private constant WORMHOLE_RELAYING_ENABLED_CHAINS_SLOT =
        bytes32(uint256(keccak256("whTransceiver.relayingEnabledChains")) - 1);

    bytes32 private constant SPECIAL_RELAYING_ENABLED_CHAINS_SLOT =
        bytes32(uint256(keccak256("whTransceiver.specialRelayingEnabledChains")) - 1);

    bytes32 private constant WORMHOLE_EVM_CHAIN_IDS =
        bytes32(uint256(keccak256("whTransceiver.evmChainIds")) - 1);

    // =============== Storage Setters/Getters ========================================

    function _getWormholeConsumedVAAsStorage()
        internal
        pure
        returns (mapping(bytes32 => bool) storage $)
    {
        uint256 slot = uint256(WORMHOLE_CONSUMED_VAAS_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _getWormholePeersStorage()
        internal
        pure
        returns (mapping(uint16 => bytes32) storage $)
    {
        uint256 slot = uint256(WORMHOLE_PEERS_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _getWormholeRelayingEnabledChainsStorage()
        internal
        pure
        returns (mapping(uint16 => BooleanFlag) storage $)
    {
        uint256 slot = uint256(WORMHOLE_RELAYING_ENABLED_CHAINS_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _getSpecialRelayingEnabledChainsStorage()
        internal
        pure
        returns (mapping(uint16 => BooleanFlag) storage $)
    {
        uint256 slot = uint256(SPECIAL_RELAYING_ENABLED_CHAINS_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _getWormholeEvmChainIdsStorage()
        internal
        pure
        returns (mapping(uint16 => BooleanFlag) storage $)
    {
        uint256 slot = uint256(WORMHOLE_EVM_CHAIN_IDS);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    // =============== Public Getters ======================================================

    /// @inheritdoc IWormholeTransceiverState
    function isVAAConsumed(bytes32 hash) public view returns (bool) {
        return _getWormholeConsumedVAAsStorage()[hash];
    }

    /// @inheritdoc IWormholeTransceiverState
    function getWormholePeer(uint16 chainId) public view returns (bytes32) {
        return _getWormholePeersStorage()[chainId];
    }

    /// @inheritdoc IWormholeTransceiverState
    function isWormholeRelayingEnabled(uint16 chainId) public view returns (bool) {
        return _getWormholeRelayingEnabledChainsStorage()[chainId].toBool();
    }

    /// @inheritdoc IWormholeTransceiverState
    function isSpecialRelayingEnabled(uint16 chainId) public view returns (bool) {
        return _getSpecialRelayingEnabledChainsStorage()[chainId].toBool();
    }

    /// @inheritdoc IWormholeTransceiverState
    function isWormholeEvmChain(uint16 chainId) public view returns (bool) {
        return _getWormholeEvmChainIdsStorage()[chainId].toBool();
    }

    // =============== Admin ===============================================================

    /// @inheritdoc IWormholeTransceiverState
    function setWormholePeer(uint16 peerChainId, bytes32 peerContract) external payable onlyOwner {
        if (peerChainId == 0) {
            revert InvalidWormholeChainIdZero();
        }
        if (peerContract == bytes32(0)) {
            revert InvalidWormholePeerZeroAddress();
        }

        bytes32 oldPeerContract = _getWormholePeersStorage()[peerChainId];

        // We don't want to allow updating a peer since this adds complexity in the accountant
        // If the owner makes a mistake with peer registration they should deploy a new Wormhole
        // transceiver and register this new transceiver with the NttManager
        if (oldPeerContract != bytes32(0)) {
            revert PeerAlreadySet(peerChainId, oldPeerContract);
        }

        _getWormholePeersStorage()[peerChainId] = peerContract;

        // Publish a message for this transceiver registration
        TransceiverStructs.TransceiverRegistration memory registration = TransceiverStructs
            .TransceiverRegistration({
            transceiverIdentifier: WH_PEER_REGISTRATION_PREFIX,
            transceiverChainId: peerChainId,
            transceiverAddress: peerContract
        });
        wormhole.publishMessage{value: msg.value}(
            0, TransceiverStructs.encodeTransceiverRegistration(registration), consistencyLevel
        );

        emit SetWormholePeer(peerChainId, peerContract);
    }

    /// @inheritdoc IWormholeTransceiverState
    function setIsWormholeEvmChain(uint16 chainId, bool isEvm) external onlyOwner {
        if (chainId == 0) {
            revert InvalidWormholeChainIdZero();
        }
        _getWormholeEvmChainIdsStorage()[chainId] = isEvm.toWord();

        emit SetIsWormholeEvmChain(chainId, isEvm);
    }

    /// @inheritdoc IWormholeTransceiverState
    function setIsWormholeRelayingEnabled(uint16 chainId, bool isEnabled) external onlyOwner {
        if (chainId == 0) {
            revert InvalidWormholeChainIdZero();
        }
        _getWormholeRelayingEnabledChainsStorage()[chainId] = isEnabled.toWord();

        emit SetIsWormholeRelayingEnabled(chainId, isEnabled);
    }

    /// @inheritdoc IWormholeTransceiverState
    function setIsSpecialRelayingEnabled(uint16 chainId, bool isEnabled) external onlyOwner {
        if (chainId == 0) {
            revert InvalidWormholeChainIdZero();
        }
        _getSpecialRelayingEnabledChainsStorage()[chainId] = isEnabled.toWord();

        emit SetIsSpecialRelayingEnabled(chainId, isEnabled);
    }

    // ============= Internal ===============================================================

    function _checkInvalidRelayingConfig(uint16 chainId) internal view returns (bool) {
        return isWormholeRelayingEnabled(chainId) && !isWormholeEvmChain(chainId);
    }

    function _shouldRelayViaStandardRelaying(uint16 chainId) internal view returns (bool) {
        return isWormholeRelayingEnabled(chainId) && isWormholeEvmChain(chainId);
    }

    function _setVAAConsumed(bytes32 hash) internal {
        _getWormholeConsumedVAAsStorage()[hash] = true;
    }

    // =============== MODIFIERS ===============================================

    modifier onlyRelayer() {
        if (msg.sender != address(wormholeRelayer)) {
            revert CallerNotRelayer(msg.sender);
        }
        _;
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which can receive Wormhole messages.
 */
interface IWormholeReceiver {
    /**
     * @notice When a `send` is performed with this contract as the target, this function will be
     *     invoked by the WormholeRelayer contract
     *
     * NOTE: This function should be restricted such that only the Wormhole Relayer contract can call it.
     *
     * We also recommend that this function checks that `sourceChain` and `sourceAddress` are indeed who
     *       you expect to have requested the calling of `send` on the source chain
     *
     * The invocation of this function corresponding to the `send` request will have msg.value equal
     *   to the receiverValue specified in the send request.
     *
     * If the invocation of this function reverts or exceeds the gas limit
     *   specified by the send requester, this delivery will result in a `ReceiverFailure`.
     *
     * @param payload - an arbitrary message which was included in the delivery by the
     *     requester. This message's signature will already have been verified (as long as msg.sender is the Wormhole Relayer contract)
     * @param additionalMessages - Additional messages which were requested to be included in this delivery.
     *      Note: There are no contract-level guarantees that the messages in this array are what was requested
     *      so **you should verify any sensitive information given here!**
     *
     *      For example, if a 'VaaKey' was specified on the source chain, then MAKE SURE the corresponding message here
     *      has valid signatures (by calling `parseAndVerifyVM(message)` on the Wormhole core contract)
     *
     *      This field can be used to perform and relay TokenBridge or CCTP transfers, and there are example
     *      usages of this at
     *         https://github.com/wormhole-foundation/hello-token
     *         https://github.com/wormhole-foundation/hello-cctp
     *
     * @param sourceAddress - the (wormhole format) address on the sending chain which requested
     *     this delivery.
     * @param sourceChain - the wormhole chain ID where this delivery was requested.
     * @param deliveryHash - the VAA hash of the deliveryVAA.
     *
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @title WormholeRelayer
 * @author
 * @notice This project allows developers to build cross-chain applications powered by Wormhole without needing to
 * write and run their own relaying infrastructure
 *
 * We implement the IWormholeRelayer interface that allows users to request a delivery provider to relay a payload (and/or additional messages)
 * to a chain and address of their choice.
 */

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId Wormhole chain ID of the chain where this VAA was emitted from
 * @custom:member emitterAddress Address of the emitter of the VAA, in Wormhole bytes32 format
 * @custom:member sequence Sequence number of the VAA
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

// 0-127 are reserved for standardized KeyTypes, 128-255 are for custom use
uint8 constant VAA_KEY_TYPE = 1;

struct MessageKey {
    uint8 keyType; // 0-127 are reserved for standardized KeyTypes, 128-255 are for custom use
    bytes encodedKey;
}

interface IWormholeRelayerBase {
    event SendEvent(
        uint64 indexed sequence,
        uint256 deliveryQuote,
        uint256 paymentForExtraReceiverValue
    );

    function getRegisteredWormholeRelayerContract(
        uint16 chainId
    ) external view returns (bytes32);

    /**
     * @notice Returns true if a delivery has been attempted for the given deliveryHash
     * Note: invalid deliveries where the tx reverts are not considered attempted
     */
    function deliveryAttempted(
        bytes32 deliveryHash
    ) external view returns (bool attempted);

    /**
     * @notice block number at which a delivery was successfully executed
     */
    function deliverySuccessBlock(
        bytes32 deliveryHash
    ) external view returns (uint256 blockNumber);

    /**
     * @notice block number of the latest attempt to execute a delivery that failed
     */
    function deliveryFailureBlock(
        bytes32 deliveryHash
    ) external view returns (uint256 blockNumber);
}

/**
 * @title IWormholeRelayerSend
 * @notice The interface to request deliveries
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {
    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendVaasToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and external messages specified by `messageKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * Note: MessageKeys can specify wormhole messages (VaaKeys) or other types of messages (ex. USDC CCTP attestations). Ensure the selected
     * DeliveryProvider supports all the MessageKey.keyType values specified or it will not be delivered!
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param messageKeys Additional messagess to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * Note: MessageKeys can specify wormhole messages (VaaKeys) or other types of messages (ex. USDC CCTP attestations). Ensure the selected
     * DeliveryProvider supports all the MessageKey.keyType values specified or it will not be delivered!
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param messageKeys Additional messagess to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     * (e.g. with a different delivery provider)
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     * @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     */
    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     *
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, newReceiverValue, newEncodedExecutionParameters, newDeliveryProviderAddress)
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newEncodedExecutionParameters new encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using the default delivery provider
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified.
     *         Note: This value can be overridden by the delivery provider on the target chain. The returned value here should be considered to be a
     *         promise by the delivery provider of the amount of refund per gas unused that will be returned to the refundAddress at the target chain.
     *         If a delivery provider decides to override, this will be visible as part of the emitted Delivery event on the target chain.
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit
    )
        external
        view
        returns (
            uint256 nativePriceQuote,
            uint256 targetChainRefundPerGasUnused
        );

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     *         Note: This value can be overridden by the delivery provider on the target chain. The returned value here should be considered to be a
     *         promise by the delivery provider of the amount of refund per gas unused that will be returned to the refundAddress at the target chain.
     *         If a delivery provider decides to override, this will be visible as part of the emitted Delivery event on the target chain.
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    )
        external
        view
        returns (
            uint256 nativePriceQuote,
            uint256 targetChainRefundPerGasUnused
        );

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return encodedExecutionInfo encoded information on how the delivery will be executed
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` and `targetChainRefundPerGasUnused`
     *             (which is the amount of target chain currency that will be refunded per unit of gas unused,
     *              if a refundAddress is specified)
     */
    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    )
        external
        view
        returns (uint256 nativePriceQuote, bytes memory encodedExecutionInfo);

    /**
     * @notice Returns the (extra) amount of target chain currency that `targetAddress`
     * will be called with, if the `paymentForExtraReceiverValue` field is set to `currentChainAmount`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param currentChainAmount The value that `paymentForExtraReceiverValue` will be set to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return targetChainAmount The amount such that if `targetAddress` will be called with `msg.value` equal to
     *         receiverValue + targetChainAmount
     */
    function quoteNativeForChain(
        uint16 targetChain,
        uint256 currentChainAmount,
        address deliveryProviderAddress
    ) external view returns (uint256 targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider()
        external
        view
        returns (address deliveryProvider);
}

/**
 * @title IWormholeRelayerDelivery
 * @notice The interface to execute deliveries. Only relevant for Delivery Providers
 */
interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH,
        NO_REFUND_REQUESTED
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary, or if the default code path is used where no refund is requested (NO_REFUND_REQUESTED)
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        uint256 gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The delivery provider calls `deliver` to relay messages as described by one delivery instruction
     *
     * The delivery provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)
     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to `delivery provider's quoted delivery price` + `paymentForExtraReceiverValue`
error InvalidMsgValue(uint256 msgValue, uint256 totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(
    address relayer,
    uint16 chainId
);
error DeliveryProviderCannotReceivePayment();
error DeliveryProviderDoesNotSupportMessageKeyType(uint8 keyType);

//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);
error TooManyMessageKeys(uint256 numMessageKeys);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error MessageKeysLengthDoesNotMatchMessagesLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a 'refund per unit of gas unused' that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the delivery provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(uint256 msgValue, uint256 minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

// In the wormhole wire format, 0 indicates that a message is for any destination chain
uint16 constant CHAIN_ID_UNSET = 0;
uint16 constant CHAIN_ID_SOLANA = 1;
uint16 constant CHAIN_ID_ETHEREUM = 2;
uint16 constant CHAIN_ID_TERRA = 3;
uint16 constant CHAIN_ID_BSC = 4;
uint16 constant CHAIN_ID_POLYGON = 5;
uint16 constant CHAIN_ID_AVALANCHE = 6;
uint16 constant CHAIN_ID_OASIS = 7;
uint16 constant CHAIN_ID_ALGORAND = 8;
uint16 constant CHAIN_ID_AURORA = 9;
uint16 constant CHAIN_ID_FANTOM = 10;
uint16 constant CHAIN_ID_KARURA = 11;
uint16 constant CHAIN_ID_ACALA = 12;
uint16 constant CHAIN_ID_KLAYTN = 13;
uint16 constant CHAIN_ID_CELO = 14;
uint16 constant CHAIN_ID_NEAR = 15;
uint16 constant CHAIN_ID_MOONBEAM = 16;
uint16 constant CHAIN_ID_NEON = 17;
uint16 constant CHAIN_ID_TERRA2 = 18;
uint16 constant CHAIN_ID_INJECTIVE = 19;
uint16 constant CHAIN_ID_OSMOSIS = 20;
uint16 constant CHAIN_ID_SUI = 21;
uint16 constant CHAIN_ID_APTOS = 22;
uint16 constant CHAIN_ID_ARBITRUM = 23;
uint16 constant CHAIN_ID_OPTIMISM = 24;
uint16 constant CHAIN_ID_GNOSIS = 25;
uint16 constant CHAIN_ID_PYTHNET = 26;
uint16 constant CHAIN_ID_XPLA = 28;
uint16 constant CHAIN_ID_BTC = 29;
uint16 constant CHAIN_ID_BASE = 30;
uint16 constant CHAIN_ID_SEI = 32;
uint16 constant CHAIN_ID_ROOTSTOCK = 33;
uint16 constant CHAIN_ID_SCROLL = 34;
uint16 constant CHAIN_ID_MANTLE = 35;
uint16 constant CHAIN_ID_WORMCHAIN = 3104;
uint16 constant CHAIN_ID_COSMOSHUB = 4000;
uint16 constant CHAIN_ID_EVMOS = 4001;
uint16 constant CHAIN_ID_KUJIRA = 4002;
uint16 constant CHAIN_ID_NEUTRON = 4003;
uint16 constant CHAIN_ID_CELESTIA = 4004;
uint16 constant CHAIN_ID_SEPOLIA = 10002;
uint16 constant CHAIN_ID_ARBITRUM_SEPOLIA = 10003;
uint16 constant CHAIN_ID_BASE_SEPOLIA = 10004;
uint16 constant CHAIN_ID_OPTIMISM_SEPOLIA = 10005;

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeRelayer.sol";

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0) {
        revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/IWormhole.sol";
import "./Utils.sol";

abstract contract Base {
    IWormholeRelayer public immutable wormholeRelayer;
    IWormhole public immutable wormhole;

    address registrationOwner;
    mapping(uint16 => bytes32) registeredSenders;

    constructor(address _wormholeRelayer, address _wormhole) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        wormhole = IWormhole(_wormhole);
        registrationOwner = msg.sender;
    }

    modifier onlyWormholeRelayer() {
        require(
            msg.sender == address(wormholeRelayer),
            "Msg.sender is not Wormhole Relayer"
        );
        _;
    }

    modifier isRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) {
        require(
            registeredSenders[sourceChain] == sourceAddress,
            "Not registered sender"
        );
        _;
    }

    /**
     * Sets the registered address for 'sourceChain' to 'sourceAddress'
     * So that for messages from 'sourceChain', only ones from 'sourceAddress' are valid
     *
     * Assumes only one sender per chain is valid
     * Sender is the address that called 'send' on the Wormhole Relayer contract on the source chain)
     */
    function setRegisteredSender(
        uint16 sourceChain,
        bytes32 sourceAddress
    ) public {
        require(
            msg.sender == registrationOwner,
            "Not allowed to set registered sender"
        );
        registeredSenders[sourceChain] = sourceAddress;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/ITokenBridge.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {Base} from "./WormholeRelayerSDK.sol";

import "./Utils.sol";

abstract contract TokenBase is Base {
    ITokenBridge public immutable tokenBridge;

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole
    ) Base(_wormholeRelayer, _wormhole) {
        tokenBridge = ITokenBridge(_tokenBridge);
    }
}

abstract contract TokenSender is TokenBase {
    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     *
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (VaaKey memory) {
        return
            transferTokens(
                token,
                amount,
                targetChain,
                targetAddress,
                bytes("")
            );
    }

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer.
     * A payload can be included in the transfer vaa. By including a payload here instead of the deliveryVaa,
     * fewer trust assumptions are placed on the WormholeRelayer contract.
     *
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress,
        bytes memory payload
    ) internal returns (VaaKey memory) {
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokensWithPayload{
            value: wormhole.messageFee()
        }(
            token,
            amount,
            targetChain,
            toWormholeFormat(targetAddress),
            0,
            payload
        );
        return
            VaaKey({
                emitterAddress: toWormholeFormat(address(tokenBridge)),
                chainId: wormhole.chainId(),
                sequence: sequence
            });
    }

    // Publishes a wormhole message representing a 'TokenBridge' transfer of 'amount' of 'token'
    // and requests a delivery of the transfer along with 'payload' to 'targetAddress' on 'targetChain'
    //
    // The second step is done by publishing a wormhole message representing a request
    // to call 'receiveWormholeMessages' on the address 'targetAddress' on chain 'targetChain'
    // with the payload 'payload'
    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                payload,
                receiverValue,
                gasLimit,
                vaaKeys
            );
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount,
        uint16 refundChain,
        address refundAddress
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                payload,
                receiverValue,
                gasLimit,
                vaaKeys,
                refundChain,
                refundAddress
            );
    }
}

abstract contract TokenReceiver is TokenBase {
    struct TokenReceived {
        bytes32 tokenHomeAddress;
        uint16 tokenHomeChain;
        address tokenAddress; // wrapped address if tokenHomeChain !== this chain, else tokenHomeAddress (in evm address format)
        uint256 amount;
        uint256 amountNormalized; // if decimals > 8, normalized to 8 decimal places
    }

    function getDecimals(
        address tokenAddress
    ) internal view returns (uint8 decimals) {
        // query decimals
        (, bytes memory queriedDecimals) = address(tokenAddress).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        decimals = abi.decode(queriedDecimals, (uint8));
    }

    function getTokenAddressOnThisChain(
        uint16 tokenHomeChain,
        bytes32 tokenHomeAddress
    ) internal view returns (address tokenAddressOnThisChain) {
        return
            tokenHomeChain == wormhole.chainId()
                ? fromWormholeFormat(tokenHomeAddress)
                : tokenBridge.wrappedAsset(tokenHomeChain, tokenHomeAddress);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable {
        TokenReceived[] memory receivedTokens = new TokenReceived[](
            additionalVaas.length
        );

        for (uint256 i = 0; i < additionalVaas.length; ++i) {
            IWormhole.VM memory parsed = wormhole.parseVM(additionalVaas[i]);
            require(
                parsed.emitterAddress ==
                    tokenBridge.bridgeContracts(parsed.emitterChainId),
                "Not a Token Bridge VAA"
            );
            ITokenBridge.TransferWithPayload memory transfer = tokenBridge
                .parseTransferWithPayload(parsed.payload);
            require(
                transfer.to == toWormholeFormat(address(this)) &&
                    transfer.toChain == wormhole.chainId(),
                "Token was not sent to this address"
            );

            tokenBridge.completeTransferWithPayload(additionalVaas[i]);

            address thisChainTokenAddress = getTokenAddressOnThisChain(
                transfer.tokenChain,
                transfer.tokenAddress
            );
            uint8 decimals = getDecimals(thisChainTokenAddress);
            uint256 denormalizedAmount = transfer.amount;
            if (decimals > 8)
                denormalizedAmount *= uint256(10) ** (decimals - 8);

            receivedTokens[i] = TokenReceived({
                tokenHomeAddress: transfer.tokenAddress,
                tokenHomeChain: transfer.tokenChain,
                tokenAddress: thisChainTokenAddress,
                amount: denormalizedAmount,
                amountNormalized: transfer.amount
            });
        }

        // call into overriden method
        receivePayloadAndTokens(
            payload,
            receivedTokens,
            sourceAddress,
            sourceChain,
            deliveryHash
        );
    }

    // Implement this function to handle in-bound deliveries that include a TokenBridge transfer
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import "./interfaces/CCTPInterfaces/ITokenMessenger.sol";
import "./interfaces/CCTPInterfaces/IMessageTransmitter.sol";

import "./Utils.sol";
import "./Base.sol";

library CCTPMessageLib {
    // The second standardized key type is a CCTP Key
    // representing a CCTP transfer of USDC
    // (on the IWormholeRelayer interface)

    // Note - the default delivery provider only will relay CCTP transfers that were sent
    // in the same transaction that this message was emitted!
    // (This will always be the case if 'CCTPSender' is used)

    uint8 constant CCTP_KEY_TYPE = 2;

    // encoded using abi.encodePacked(domain, nonce)
    struct CCTPKey {
        uint32 domain;
        uint64 nonce;
    }

    // encoded using abi.encode(message, signature)
    struct CCTPMessage {
        bytes message;
        bytes signature;
    }
}

abstract contract CCTPBase is Base {
    ITokenMessenger immutable circleTokenMessenger;
    IMessageTransmitter immutable circleMessageTransmitter;
    address immutable USDC;
    address cctpConfigurationOwner;

    constructor(
        address _wormholeRelayer,
        address _wormhole,
        address _circleMessageTransmitter,
        address _circleTokenMessenger,
        address _USDC
    ) Base(_wormholeRelayer, _wormhole) {
        circleTokenMessenger = ITokenMessenger(_circleTokenMessenger);
        circleMessageTransmitter = IMessageTransmitter(
            _circleMessageTransmitter
        );
        USDC = _USDC;
        cctpConfigurationOwner = msg.sender;
    }
}

abstract contract CCTPSender is CCTPBase {
    uint8 internal constant CONSISTENCY_LEVEL_FINALIZED = 15;

    using CCTPMessageLib for *;

    mapping(uint16 => uint32) public chainIdToCCTPDomain;

    /**
     * Sets the CCTP Domain corresponding to chain 'chain' to be 'cctpDomain'
     * So that transfers of USDC to chain 'chain' use the target CCTP domain 'cctpDomain'
     *
     * This action can only be performed by 'cctpConfigurationOwner', who is set to be the deployer
     *
     * Currently, cctp domains are:
     * Ethereum: Wormhole chain id 2, cctp domain 0
     * Avalanche: Wormhole chain id 6, cctp domain 1
     * Optimism: Wormhole chain id 24, cctp domain 2
     * Arbitrum: Wormhole chain id 23, cctp domain 3
     * Base: Wormhole chain id 30, cctp domain 6
     *
     * These can be set via:
     * setCCTPDomain(2, 0);
     * setCCTPDomain(6, 1);
     * setCCTPDomain(24, 2);
     * setCCTPDomain(23, 3);
     * setCCTPDomain(30, 6);
     */
    function setCCTPDomain(uint16 chain, uint32 cctpDomain) public {
        require(
            msg.sender == cctpConfigurationOwner,
            "Not allowed to set CCTP Domain"
        );
        chainIdToCCTPDomain[chain] = cctpDomain;
    }

    function getCCTPDomain(uint16 chain) internal view returns (uint32) {
        return chainIdToCCTPDomain[chain];
    }

    /**
     * transferUSDC wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves the Circle TokenMessenger contract to spend 'amount' of USDC
     * - calls Circle's 'depositForBurnWithCaller'
     * - returns key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this requires that only the targetAddress can redeem transfers.
     *
     */

    function transferUSDC(
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (MessageKey memory) {
        IERC20(USDC).approve(address(circleTokenMessenger), amount);
        bytes32 targetAddressBytes32 = addressToBytes32CCTP(targetAddress);
        uint64 nonce = circleTokenMessenger.depositForBurnWithCaller(
            amount,
            getCCTPDomain(targetChain),
            targetAddressBytes32,
            USDC,
            targetAddressBytes32
        );
        return
            MessageKey(
                CCTPMessageLib.CCTP_KEY_TYPE,
                abi.encodePacked(getCCTPDomain(wormhole.chainId()), nonce)
            );
    }

    // Publishes a CCTP transfer of 'amount' of USDC
    // and requests a delivery of the transfer along with 'payload' to 'targetAddress' on 'targetChain'
    //
    // The second step is done by publishing a wormhole message representing a request
    // to call 'receiveWormholeMessages' on the address 'targetAddress' on chain 'targetChain'
    // with the payload 'abi.encode(amount, payload)'
    // (and we encode the amount so it can be checked on the target chain)
    function sendUSDCWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint256 amount
    ) internal returns (uint64 sequence) {
        MessageKey[] memory messageKeys = new MessageKey[](1);
        messageKeys[0] = transferUSDC(amount, targetChain, targetAddress);

        bytes memory userPayload = abi.encode(amount, payload);
        address defaultDeliveryProvider = wormholeRelayer
            .getDefaultDeliveryProvider();

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );

        sequence = wormholeRelayer.sendToEvm{value: cost}(
            targetChain,
            targetAddress,
            userPayload,
            receiverValue,
            0,
            gasLimit,
            targetChain,
            address(0x0),
            defaultDeliveryProvider,
            messageKeys,
            CONSISTENCY_LEVEL_FINALIZED
        );
    }

    function addressToBytes32CCTP(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

abstract contract CCTPReceiver is CCTPBase {
    function redeemUSDC(
        bytes memory cctpMessage
    ) internal returns (uint256 amount) {
        (bytes memory message, bytes memory signature) = abi.decode(
            cctpMessage,
            (bytes, bytes)
        );
        uint256 beforeBalance = IERC20(USDC).balanceOf(address(this));
        circleMessageTransmitter.receiveMessage(message, signature);
        return IERC20(USDC).balanceOf(address(this)) - beforeBalance;
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable {
        // Currently, 'sendUSDCWithPayloadToEVM' only sends one CCTP transfer
        // That can be modified if the integrator desires to send multiple CCTP transfers
        // in which case the following code would have to be modified to support
        // redeeming these multiple transfers and checking that their 'amount's are accurate
        require(
            additionalMessages.length <= 1,
            "CCTP: At most one Message is supported"
        );

        uint256 amountUSDCReceived;
        if (additionalMessages.length == 1) {
            amountUSDCReceived = redeemUSDC(additionalMessages[0]);
        }

        (uint256 amount, bytes memory userPayload) = abi.decode(
            payload,
            (uint256, bytes)
        );

        // Check that the correct amount was received
        // It is important to verify that the 'USDC' sent in by the relayer is the same amount
        // that the sender sent in on the source chain
        require(amount == amountUSDCReceived, "Wrong amount received");

        receivePayloadAndUSDC(
            userPayload,
            amountUSDCReceived,
            sourceAddress,
            sourceChain,
            deliveryHash
        );
    }

    // Implement this function to handle in-bound deliveries that include a CCTP transfer
    function receivePayloadAndUSDC(
        bytes memory payload,
        uint256 amountUSDCReceived,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.13;

import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/ITokenBridge.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import "./interfaces/CCTPInterfaces/ITokenMessenger.sol";
import "./interfaces/CCTPInterfaces/IMessageTransmitter.sol";

import "./Utils.sol";
import "./TokenBase.sol";
import "./CCTPBase.sol";

abstract contract CCTPAndTokenBase is CCTPBase {
    ITokenBridge public immutable tokenBridge;

    enum Transfer {
        TOKEN_BRIDGE,
        CCTP
    }

    constructor(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole,
        address _circleMessageTransmitter,
        address _circleTokenMessenger,
        address _USDC
    )
        CCTPBase(
            _wormholeRelayer,
            _wormhole,
            _circleMessageTransmitter,
            _circleTokenMessenger,
            _USDC
        )
    {
        tokenBridge = ITokenBridge(_tokenBridge);
    }
}

abstract contract CCTPAndTokenSender is CCTPAndTokenBase {
    // CCTP Sender functions, taken from "./CCTPBase.sol"

    uint8 internal constant CONSISTENCY_LEVEL_FINALIZED = 15;

    using CCTPMessageLib for *;

    mapping(uint16 => uint32) public chainIdToCCTPDomain;

    /**
     * Sets the CCTP Domain corresponding to chain 'chain' to be 'cctpDomain'
     * So that transfers of USDC to chain 'chain' use the target CCTP domain 'cctpDomain'
     *
     * This action can only be performed by 'cctpConfigurationOwner', who is set to be the deployer
     *
     * Currently, cctp domains are:
     * Ethereum: Wormhole chain id 2, cctp domain 0
     * Avalanche: Wormhole chain id 6, cctp domain 1
     * Optimism: Wormhole chain id 24, cctp domain 2
     * Arbitrum: Wormhole chain id 23, cctp domain 3
     * Base: Wormhole chain id 30, cctp domain 6
     *
     * These can be set via:
     * setCCTPDomain(2, 0);
     * setCCTPDomain(6, 1);
     * setCCTPDomain(24, 2);
     * setCCTPDomain(23, 3);
     * setCCTPDomain(30, 6);
     */
    function setCCTPDomain(uint16 chain, uint32 cctpDomain) public {
        require(
            msg.sender == cctpConfigurationOwner,
            "Not allowed to set CCTP Domain"
        );
        chainIdToCCTPDomain[chain] = cctpDomain;
    }

    function getCCTPDomain(uint16 chain) internal view returns (uint32) {
        return chainIdToCCTPDomain[chain];
    }

    /**
     * transferUSDC wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves the Circle TokenMessenger contract to spend 'amount' of USDC
     * - calls Circle's 'depositForBurnWithCaller'
     * - returns key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this requires that only the targetAddress can redeem transfers.
     *
     */

    function transferUSDC(
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (MessageKey memory) {
        IERC20(USDC).approve(address(circleTokenMessenger), amount);
        bytes32 targetAddressBytes32 = addressToBytes32CCTP(targetAddress);
        uint64 nonce = circleTokenMessenger.depositForBurnWithCaller(
            amount,
            getCCTPDomain(targetChain),
            targetAddressBytes32,
            USDC,
            targetAddressBytes32
        );
        return
            MessageKey(
                CCTPMessageLib.CCTP_KEY_TYPE,
                abi.encodePacked(getCCTPDomain(wormhole.chainId()), nonce)
            );
    }

    // Publishes a CCTP transfer of 'amount' of USDC
    // and requests a delivery of the transfer along with 'payload' to 'targetAddress' on 'targetChain'
    //
    // The second step is done by publishing a wormhole message representing a request
    // to call 'receiveWormholeMessages' on the address 'targetAddress' on chain 'targetChain'
    // with the payload 'abi.encode(Transfer.CCTP, amount, payload)'
    // (we encode a Transfer enum to distinguish this from a TokenBridge transfer)
    // (and we encode the amount so it can be checked on the target chain)
    function sendUSDCWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint256 amount
    ) internal returns (uint64 sequence) {
        MessageKey[] memory messageKeys = new MessageKey[](1);
        messageKeys[0] = transferUSDC(amount, targetChain, targetAddress);

        bytes memory userPayload = abi.encode(Transfer.CCTP, amount, payload);
        address defaultDeliveryProvider = wormholeRelayer
            .getDefaultDeliveryProvider();

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );

        sequence = wormholeRelayer.sendToEvm{value: cost}(
            targetChain,
            targetAddress,
            userPayload,
            receiverValue,
            0,
            gasLimit,
            targetChain,
            address(0x0),
            defaultDeliveryProvider,
            messageKeys,
            CONSISTENCY_LEVEL_FINALIZED
        );
    }

    function addressToBytes32CCTP(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    // TokenBridge Sender functions, taken from "./TokenBase.sol"

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     *
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (VaaKey memory) {
        return
            transferTokens(
                token,
                amount,
                targetChain,
                targetAddress,
                bytes("")
            );
    }

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer.
     * A payload can be included in the transfer vaa. By including a payload here instead of the deliveryVaa,
     * fewer trust assumptions are placed on the WormholeRelayer contract.
     *
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress,
        bytes memory payload
    ) internal returns (VaaKey memory) {
        IERC20(token).approve(address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokensWithPayload{
            value: wormhole.messageFee()
        }(
            token,
            amount,
            targetChain,
            toWormholeFormat(targetAddress),
            0,
            payload
        );
        return
            VaaKey({
                emitterAddress: toWormholeFormat(address(tokenBridge)),
                chainId: wormhole.chainId(),
                sequence: sequence
            });
    }

    // Publishes a wormhole message representing a 'TokenBridge' transfer of 'amount' of 'token'
    // and requests a delivery of the transfer along with 'payload' to 'targetAddress' on 'targetChain'
    //
    // The second step is done by publishing a wormhole message representing a request
    // to call 'receiveWormholeMessages' on the address 'targetAddress' on chain 'targetChain'
    // with the payload 'abi.encode(Transfer.TOKEN_BRIDGE, payload)'
    // (we encode a Transfer enum to distinguish this from a CCTP transfer)
    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                abi.encode(Transfer.TOKEN_BRIDGE, payload),
                receiverValue,
                gasLimit,
                vaaKeys
            );
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount,
        uint16 refundChain,
        address refundAddress
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                abi.encode(Transfer.TOKEN_BRIDGE, payload),
                receiverValue,
                gasLimit,
                vaaKeys,
                refundChain,
                refundAddress
            );
    }
}

abstract contract CCTPAndTokenReceiver is CCTPAndTokenBase {
    function redeemUSDC(
        bytes memory cctpMessage
    ) internal returns (uint256 amount) {
        (bytes memory message, bytes memory signature) = abi.decode(
            cctpMessage,
            (bytes, bytes)
        );
        uint256 beforeBalance = IERC20(USDC).balanceOf(address(this));
        circleMessageTransmitter.receiveMessage(message, signature);
        return IERC20(USDC).balanceOf(address(this)) - beforeBalance;
    }

    struct TokenReceived {
        bytes32 tokenHomeAddress;
        uint16 tokenHomeChain;
        address tokenAddress; // wrapped address if tokenHomeChain !== this chain, else tokenHomeAddress (in evm address format)
        uint256 amount;
        uint256 amountNormalized; // if decimals > 8, normalized to 8 decimal places
    }

    function getDecimals(
        address tokenAddress
    ) internal view returns (uint8 decimals) {
        // query decimals
        (, bytes memory queriedDecimals) = address(tokenAddress).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        decimals = abi.decode(queriedDecimals, (uint8));
    }

    function getTokenAddressOnThisChain(
        uint16 tokenHomeChain,
        bytes32 tokenHomeAddress
    ) internal view returns (address tokenAddressOnThisChain) {
        return
            tokenHomeChain == wormhole.chainId()
                ? fromWormholeFormat(tokenHomeAddress)
                : tokenBridge.wrappedAsset(tokenHomeChain, tokenHomeAddress);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable {
        Transfer transferType = abi.decode(payload, (Transfer));
        if (transferType == Transfer.TOKEN_BRIDGE) {
            TokenReceived[] memory receivedTokens = new TokenReceived[](
                additionalMessages.length
            );

            for (uint256 i = 0; i < additionalMessages.length; ++i) {
                IWormhole.VM memory parsed = wormhole.parseVM(
                    additionalMessages[i]
                );
                require(
                    parsed.emitterAddress ==
                        tokenBridge.bridgeContracts(parsed.emitterChainId),
                    "Not a Token Bridge VAA"
                );
                ITokenBridge.TransferWithPayload memory transfer = tokenBridge
                    .parseTransferWithPayload(parsed.payload);
                require(
                    transfer.to == toWormholeFormat(address(this)) &&
                        transfer.toChain == wormhole.chainId(),
                    "Token was not sent to this address"
                );

                tokenBridge.completeTransferWithPayload(additionalMessages[i]);

                address thisChainTokenAddress = getTokenAddressOnThisChain(
                    transfer.tokenChain,
                    transfer.tokenAddress
                );
                uint8 decimals = getDecimals(thisChainTokenAddress);
                uint256 denormalizedAmount = transfer.amount;
                if (decimals > 8)
                    denormalizedAmount *= uint256(10) ** (decimals - 8);

                receivedTokens[i] = TokenReceived({
                    tokenHomeAddress: transfer.tokenAddress,
                    tokenHomeChain: transfer.tokenChain,
                    tokenAddress: thisChainTokenAddress,
                    amount: denormalizedAmount,
                    amountNormalized: transfer.amount
                });
            }

            (, bytes memory userPayload) = abi.decode(
                payload,
                (Transfer, bytes)
            );

            // call into overriden method
            receivePayloadAndTokens(
                userPayload,
                receivedTokens,
                sourceAddress,
                sourceChain,
                deliveryHash
            );
        } else if (transferType == Transfer.CCTP) {
            // Currently, 'sendUSDCWithPayloadToEVM' only sends one CCTP transfer
            // That can be modified if the integrator desires to send multiple CCTP transfers
            // in which case the following code would have to be modified to support
            // redeeming these multiple transfers and checking that their 'amount's are accurate
            require(
                additionalMessages.length <= 1,
                "CCTP: At most one Message is supported"
            );

            uint256 amountUSDCReceived;
            if (additionalMessages.length == 1) {
                amountUSDCReceived = redeemUSDC(additionalMessages[0]);
            }

            (, uint256 amount, bytes memory userPayload) = abi.decode(
                payload,
                (Transfer, uint256, bytes)
            );

            // Check that the correct amount was received
            // It is important to verify that the 'USDC' sent in by the relayer is the same amount
            // that the sender sent in on the source chain
            require(amount == amountUSDCReceived, "Wrong amount received");

            receivePayloadAndUSDC(
                userPayload,
                amountUSDCReceived,
                sourceAddress,
                sourceChain,
                deliveryHash
            );
        } else {
            revert("Invalid transfer type");
        }
    }

    // Implement this function to handle in-bound deliveries that include a CCTP transfer
    function receivePayloadAndUSDC(
        bytes memory payload,
        uint256 amountUSDCReceived,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}

    // Implement this function to handle in-bound deliveries that include a TokenBridge transfer
    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache 2
/// @dev TrimmedAmount is a utility library to handle token amounts with different decimals
pragma solidity >=0.8.8 <0.9.0;

import "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

/// @dev TrimmedAmount is a bit-packed representation of a token amount and its decimals.
/// @dev 64 bits: [0 - 64] amount
/// @dev 8 bits: [64 - 72] decimals
type TrimmedAmount is uint72;

using {gt as >, lt as <, sub as -, add as +, eq as ==, min, unwrap} for TrimmedAmount global;

function minUint8(uint8 a, uint8 b) pure returns (uint8) {
    return a < b ? a : b;
}

/// @notice Error when the decimals of two TrimmedAmounts are not equal
/// @dev Selector. b9cdb6c2
/// @param decimals the decimals of the first TrimmedAmount
/// @param decimalsOther the decimals of the second TrimmedAmount
error NumberOfDecimalsNotEqual(uint8 decimals, uint8 decimalsOther);

uint8 constant TRIMMED_DECIMALS = 8;

function unwrap(TrimmedAmount a) pure returns (uint72) {
    return TrimmedAmount.unwrap(a);
}

function packTrimmedAmount(uint64 amt, uint8 decimals) pure returns (TrimmedAmount) {
    // cast to u72 first to prevent overflow
    uint72 amount = uint72(amt);
    uint72 dec = uint72(decimals);

    // shift the amount to the left 8 bits
    amount <<= 8;

    return TrimmedAmount.wrap(amount | dec);
}

function eq(TrimmedAmount a, TrimmedAmount b) pure returns (bool) {
    return TrimmedAmountLib.getAmount(a) == TrimmedAmountLib.getAmount(b)
        && TrimmedAmountLib.getDecimals(a) == TrimmedAmountLib.getDecimals(b);
}

function checkDecimals(TrimmedAmount a, TrimmedAmount b) pure {
    uint8 aDecimals = TrimmedAmountLib.getDecimals(a);
    uint8 bDecimals = TrimmedAmountLib.getDecimals(b);
    if (aDecimals != bDecimals) {
        revert NumberOfDecimalsNotEqual(aDecimals, bDecimals);
    }
}

function gt(TrimmedAmount a, TrimmedAmount b) pure returns (bool) {
    checkDecimals(a, b);

    return TrimmedAmountLib.getAmount(a) > TrimmedAmountLib.getAmount(b);
}

function lt(TrimmedAmount a, TrimmedAmount b) pure returns (bool) {
    checkDecimals(a, b);

    return TrimmedAmountLib.getAmount(a) < TrimmedAmountLib.getAmount(b);
}

function sub(TrimmedAmount a, TrimmedAmount b) pure returns (TrimmedAmount) {
    checkDecimals(a, b);

    return packTrimmedAmount(
        TrimmedAmountLib.getAmount(a) - TrimmedAmountLib.getAmount(b),
        TrimmedAmountLib.getDecimals(a)
    );
}

function add(TrimmedAmount a, TrimmedAmount b) pure returns (TrimmedAmount) {
    checkDecimals(a, b);

    return packTrimmedAmount(
        TrimmedAmountLib.getAmount(a) + TrimmedAmountLib.getAmount(b),
        TrimmedAmountLib.getDecimals(b)
    );
}

function min(TrimmedAmount a, TrimmedAmount b) pure returns (TrimmedAmount) {
    checkDecimals(a, b);

    return TrimmedAmountLib.getAmount(a) < TrimmedAmountLib.getAmount(b) ? a : b;
}

library TrimmedAmountLib {
    /// @notice Error when the amount to be trimmed is greater than u64MAX.
    /// @dev Selector 0x08083b2a.
    /// @param amount The amount to be trimmed.
    error AmountTooLarge(uint256 amount);

    function getAmount(TrimmedAmount a) internal pure returns (uint64) {
        // Extract the raw integer value from TrimmedAmount
        uint72 rawValue = TrimmedAmount.unwrap(a);

        // Right shift to keep only the higher 64 bits
        uint64 result = uint64(rawValue >> 8);
        return result;
    }

    function getDecimals(TrimmedAmount a) internal pure returns (uint8) {
        return uint8(TrimmedAmount.unwrap(a) & 0xFF);
    }

    function isNull(TrimmedAmount a) internal pure returns (bool) {
        return (getAmount(a) == 0 && getDecimals(a) == 0);
    }

    function saturatingAdd(
        TrimmedAmount a,
        TrimmedAmount b
    ) internal pure returns (TrimmedAmount) {
        checkDecimals(a, b);

        uint256 saturatedSum;
        uint64 aAmount = getAmount(a);
        uint64 bAmount = getAmount(b);
        unchecked {
            saturatedSum = uint256(aAmount) + uint256(bAmount);
            saturatedSum = saturatedSum > type(uint64).max ? type(uint64).max : saturatedSum;
        }

        return packTrimmedAmount(SafeCast.toUint64(saturatedSum), getDecimals(a));
    }

    /// @dev scale the amount from original decimals to target decimals (base 10)
    function scale(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        }

        if (fromDecimals > toDecimals) {
            return amount / (10 ** (fromDecimals - toDecimals));
        } else {
            return amount * (10 ** (toDecimals - fromDecimals));
        }
    }

    function shift(TrimmedAmount amount, uint8 toDecimals) internal pure returns (TrimmedAmount) {
        uint8 actualToDecimals = minUint8(TRIMMED_DECIMALS, toDecimals);
        return packTrimmedAmount(
            SafeCast.toUint64(scale(getAmount(amount), getDecimals(amount), actualToDecimals)),
            actualToDecimals
        );
    }

    function max(uint8 decimals) internal pure returns (TrimmedAmount) {
        uint8 actualDecimals = minUint8(TRIMMED_DECIMALS, decimals);
        return packTrimmedAmount(type(uint64).max, actualDecimals);
    }

    /// @dev trim the amount to target decimals.
    ///      The actual resulting decimals is the minimum of TRIMMED_DECIMALS,
    ///      fromDecimals, and toDecimals. This ensures that no dust is
    ///      destroyed on either side of the transfer.
    /// @param amt the amount to be trimmed
    /// @param fromDecimals the original decimals of the amount
    /// @param toDecimals the target decimals of the amount
    /// @return TrimmedAmount uint72 value type bit-packed with decimals
    function trim(
        uint256 amt,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (TrimmedAmount) {
        uint8 actualToDecimals = minUint8(minUint8(TRIMMED_DECIMALS, fromDecimals), toDecimals);
        uint256 amountScaled = scale(amt, fromDecimals, actualToDecimals);

        // NOTE: amt after trimming must fit into uint64 (that's the point of
        // trimming, as Solana only supports uint64 for token amts)
        return packTrimmedAmount(SafeCast.toUint64(amountScaled), actualToDecimals);
    }

    function untrim(TrimmedAmount amt, uint8 toDecimals) internal pure returns (uint256) {
        uint256 deNorm = uint256(getAmount(amt));
        uint8 fromDecimals = getDecimals(amt);
        uint256 amountScaled = scale(deNorm, fromDecimals, toDecimals);

        return amountScaled;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "../libraries/TransceiverStructs.sol";

interface IWormholeTransceiverState {
    /// @notice Emitted when a message is sent from the transceiver.
    /// @dev Topic0
    ///      0xc3192e083c87c556db539f071d8a298869f487e951327b5616a6f85ae3da958e.
    /// @param relayingType The type of relaying.
    /// @param deliveryPayment The amount of ether sent along with the tx to cover the delivery fee.
    event RelayingInfo(uint8 relayingType, bytes32 refundAddress, uint256 deliveryPayment);

    /// @notice Emitted when a peer transceiver is set.
    /// @dev Topic0
    ///      0xa559263ee060c7a2560843b3a064ff0376c9753ae3e2449b595a3b615d326466.
    /// @param chainId The chain ID of the peer.
    /// @param peerContract The address of the peer contract.
    event SetWormholePeer(uint16 chainId, bytes32 peerContract);

    /// @notice Emitted when relaying is enabled for the given chain.
    /// @dev Topic0
    ///      0x528b18a533e892b5401d1fb63597275df9d2bb45b13e7695c3147cd07b9746c3.
    /// @param chainId The chain ID to set.
    /// @param isRelayingEnabled A boolean indicating whether relaying is enabled.
    event SetIsWormholeRelayingEnabled(uint16 chainId, bool isRelayingEnabled);

    /// @notice Emitted when special relaying is enabled for the given chain.
    /// @dev Topic0
    ///      0x0fe301480713b2c2072ee91b3bcfcbf2c0014f0447c89046f020f0f80727003c.
    /// @param chainId The chain ID to set.
    event SetIsSpecialRelayingEnabled(uint16 chainId, bool isRelayingEnabled);

    /// @notice Emitted when the chain is EVM compatible.
    /// @dev Topic0
    ///      0x50bbeb4e180e8f9e429f6ef6b53496616c747fe502441c4f423d5fc9ec958d9c.
    /// @param chainId The chain ID to set.
    /// @param isEvm A boolean indicating whether relaying is enabled.
    event SetIsWormholeEvmChain(uint16 chainId, bool isEvm);

    /// @notice Additonal messages are not allowed.
    /// @dev Selector: 0xc504ea29.
    error UnexpectedAdditionalMessages();

    /// @notice Error if the VAA is invalid.
    /// @dev Selector: 0x8ee2e336.
    /// @param reason The reason the VAA is invalid.
    error InvalidVaa(string reason);

    /// @notice Error if the peer has already been set.
    /// @dev Selector: 0xb55eeae9.
    /// @param chainId The chain ID of the peer.
    /// @param peerAddress The address of the peer.
    error PeerAlreadySet(uint16 chainId, bytes32 peerAddress);

    /// @notice Error the peer contract cannot be the zero address.
    /// @dev Selector: 0x26e0c7de.
    error InvalidWormholePeerZeroAddress();

    /// @notice The chain ID cannot be zero.
    /// @dev Selector: 0x3dd98b24.
    error InvalidWormholeChainIdZero();

    /// @notice The caller is not the relayer.
    /// @dev Selector: 0x1c269589.
    /// @param caller The caller.
    error CallerNotRelayer(address caller);

    /// @notice Get the corresponding Transceiver contract on other chains that have been registered
    /// via governance. This design should be extendable to other chains, so each Transceiver would
    /// be potentially concerned with Transceivers on multiple other chains.
    /// @dev that peers are registered under Wormhole chain ID values.
    /// @param chainId The Wormhole chain ID of the peer to get.
    /// @return peerContract The address of the peer contract on the given chain.
    function getWormholePeer(uint16 chainId) external view returns (bytes32);

    /// @notice Returns a boolean indicating whether the given VAA hash has been consumed.
    /// @param hash The VAA hash to check.
    function isVAAConsumed(bytes32 hash) external view returns (bool);

    /// @notice Returns a boolean indicating whether Wormhole relaying is enabled for the given chain.
    /// @param chainId The Wormhole chain ID to check.
    function isWormholeRelayingEnabled(uint16 chainId) external view returns (bool);

    /// @notice Returns a boolean indicating whether special relaying is enabled for the given chain.
    /// @param chainId The Wormhole chain ID to check.
    function isSpecialRelayingEnabled(uint16 chainId) external view returns (bool);

    /// @notice Returns a boolean indicating whether the given chain is EVM compatible.
    /// @param chainId The Wormhole chain ID to check.
    function isWormholeEvmChain(uint16 chainId) external view returns (bool);

    /// @notice Set the Wormhole peer contract for the given chain.
    /// @dev This function is only callable by the `owner`.
    /// @param chainId The Wormhole chain ID of the peer to set.
    /// @param peerContract The address of the peer contract on the given chain.
    function setWormholePeer(uint16 chainId, bytes32 peerContract) external payable;

    /// @notice Set whether the chain is EVM compatible.
    /// @dev This function is only callable by the `owner`.
    /// @param chainId The Wormhole chain ID to set.
    /// @param isEvm A boolean indicating whether the chain is an EVM chain.
    function setIsWormholeEvmChain(uint16 chainId, bool isEvm) external;

    /// @notice Set whether Wormhole relaying is enabled for the given chain.
    /// @dev This function is only callable by the `owner`.
    /// @param chainId The Wormhole chain ID to set.
    /// @param isRelayingEnabled A boolean indicating whether relaying is enabled.
    function setIsWormholeRelayingEnabled(uint16 chainId, bool isRelayingEnabled) external;

    /// @notice Set whether special relaying is enabled for the given chain.
    /// @dev This function is only callable by the `owner`.
    /// @param chainId The Wormhole chain ID to set.
    /// @param isRelayingEnabled A boolean indicating whether special relaying is enabled.
    function setIsSpecialRelayingEnabled(uint16 chainId, bool isRelayingEnabled) external;
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "../libraries/TransceiverStructs.sol";

interface IManagerBase {
    /// @notice The mode is either LOCKING or BURNING. In LOCKING mode, the NttManager locks the
    ///         tokens of the sender and mints an equivalent amount on the target chain. In BURNING
    ///         mode, the NttManager burns the tokens of the sender and mints an equivalent amount
    ///         on the target chain.LOCKING mode preserves the total supply of the tokens.
    enum Mode {
        LOCKING,
        BURNING
    }

    /// @notice Information about attestations for a given message.
    /// @dev The fields are as follows:
    ///      - executed: whether the message has been executed.
    ///      - attested: bitmap of transceivers that have attested to this message.
    ///                  (NOTE: might contain disabled transceivers)
    struct AttestationInfo {
        bool executed;
        uint64 attestedTransceivers;
    }

    struct _Sequence {
        uint64 num;
    }

    struct _Threshold {
        uint8 num;
    }

    /// @notice Emitted when a message has been attested to.
    /// @dev Topic0
    ///      0x35a2101eaac94b493e0dfca061f9a7f087913fde8678e7cde0aca9897edba0e5.
    /// @param digest The digest of the message.
    /// @param transceiver The address of the transceiver.
    /// @param index The index of the transceiver in the bitmap.
    event MessageAttestedTo(bytes32 digest, address transceiver, uint8 index);

    /// @notice Emmitted when the threshold required transceivers is changed.
    /// @dev Topic0
    ///      0x2a855b929b9a53c6fb5b5ed248b27e502b709c088e036a5aa17620c8fc5085a9.
    /// @param oldThreshold The old threshold.
    /// @param threshold The new threshold.
    event ThresholdChanged(uint8 oldThreshold, uint8 threshold);

    /// @notice Emitted when an transceiver is removed from the nttManager.
    /// @dev Topic0
    ///      0xc6289e62021fd0421276d06677862d6b328d9764cdd4490ca5ac78b173f25883.
    /// @param transceiver The address of the transceiver.
    /// @param transceiversNum The current number of transceivers.
    /// @param threshold The current threshold of transceivers.
    event TransceiverAdded(address transceiver, uint256 transceiversNum, uint8 threshold);

    /// @notice Emitted when an transceiver is removed from the nttManager.
    /// @dev Topic0
    ///     0x638e631f34d9501a3ff0295873b29f50d0207b5400bf0e48b9b34719e6b1a39e.
    /// @param transceiver The address of the transceiver.
    /// @param threshold The current threshold of transceivers.
    event TransceiverRemoved(address transceiver, uint8 threshold);

    /// @notice payment for a transfer is too low.
    /// @param requiredPayment The required payment.
    /// @param providedPayment The provided payment.
    error DeliveryPaymentTooLow(uint256 requiredPayment, uint256 providedPayment);

    /// @notice Error when the refund to the sender fails.
    /// @dev Selector 0x2ca23714.
    /// @param refundAmount The refund amount.
    error RefundFailed(uint256 refundAmount);

    /// @notice The number of thresholds should not be zero.
    error ZeroThreshold();

    error RetrievedIncorrectRegisteredTransceivers(uint256 retrieved, uint256 registered);

    /// @notice The threshold for transceiver attestations is too high.
    /// @param threshold The threshold.
    /// @param transceivers The number of transceivers.
    error ThresholdTooHigh(uint256 threshold, uint256 transceivers);

    /// @notice Error when the tranceiver already attested to the message.
    ///         To ensure the client does not continue to initiate calls to the attestationReceived function.
    /// @dev Selector 0x2113894.
    /// @param nttManagerMessageHash The hash of the message.
    error TransceiverAlreadyAttestedToMessage(bytes32 nttManagerMessageHash);

    /// @notice Error when the message is not approved.
    /// @dev Selector 0x451c4fb0.
    /// @param msgHash The hash of the message.
    error MessageNotApproved(bytes32 msgHash);

    /// @notice Emitted when a message has already been executed to
    ///         notify client of against retries.
    /// @dev Topic0
    ///      0x4069dff8c9df7e38d2867c0910bd96fd61787695e5380281148c04932d02bef2.
    /// @param sourceNttManager The address of the source nttManager.
    /// @param msgHash The keccak-256 hash of the message.
    event MessageAlreadyExecuted(bytes32 indexed sourceNttManager, bytes32 indexed msgHash);

    /// @notice There are no transceivers enabled with the Manager
    /// @dev Selector 0x69cf632a
    error NoEnabledTransceivers();

    /// @notice Error when the manager doesn't have a peer registered for the destination chain
    /// @dev Selector 0x3af256bc.
    /// @param chainId The target chain id
    error PeerNotRegistered(uint16 chainId);

    /// @notice Fetch the delivery price for a given recipient chain transfer.
    /// @param recipientChain The chain ID of the transfer destination.
    /// @param transceiverInstructions The transceiver specific instructions for quoting and sending
    /// @return - The delivery prices associated with each enabled endpoint and the total price.
    function quoteDeliveryPrice(
        uint16 recipientChain,
        bytes memory transceiverInstructions
    ) external view returns (uint256[] memory, uint256);

    /// @notice Sets the threshold for the number of attestations required for a message
    /// to be considered valid.
    /// @param threshold The new threshold.
    /// @dev This method can only be executed by the `owner`.
    function setThreshold(uint8 threshold) external;

    /// @notice Sets the transceiver for the given chain.
    /// @param transceiver The address of the transceiver.
    /// @dev This method can only be executed by the `owner`.
    function setTransceiver(address transceiver) external;

    /// @notice Removes the transceiver for the given chain.
    /// @param transceiver The address of the transceiver.
    /// @dev This method can only be executed by the `owner`.
    function removeTransceiver(address transceiver) external;

    /// @notice Checks if a message has been approved. The message should have at least
    /// the minimum threshold of attestations from distinct endpoints.
    /// @param digest The digest of the message.
    /// @return - Boolean indicating if message has been approved.
    function isMessageApproved(bytes32 digest) external view returns (bool);

    /// @notice Checks if a message has been executed.
    /// @param digest The digest of the message.
    /// @return - Boolean indicating if message has been executed.
    function isMessageExecuted(bytes32 digest) external view returns (bool);

    /// @notice Returns the next message sequence.
    function nextMessageSequence() external view returns (uint64);

    /// @notice Upgrades to a new manager implementation.
    /// @dev This is upgraded via a proxy, and can only be executed
    /// by the `owner`.
    /// @param newImplementation The address of the new implementation.
    function upgrade(address newImplementation) external;

    /// @notice Pauses the manager.
    function pause() external;

    /// @notice Returns the mode (locking or burning) of the NttManager.
    /// @return mode A uint8 corresponding to the mode
    function getMode() external view returns (uint8);

    /// @notice Returns the number of Transceivers that must attest to a msgId for
    /// it to be considered valid and acted upon.
    function getThreshold() external view returns (uint8);

    /// @notice Returns a boolean indicating if the transceiver has attested to the message.
    function transceiverAttestedToMessage(
        bytes32 digest,
        uint8 index
    ) external view returns (bool);

    /// @notice Returns the number of attestations for a given message.
    function messageAttestations(bytes32 digest) external view returns (uint8 count);

    /// @notice Returns of the address of the token managed by this contract.
    function token() external view returns (address);

    /// @notice Returns the chain ID.
    function chainId() external view returns (uint16);
}

// SPDX-License-Identifier: Apache 2

pragma solidity >=0.8.8 <0.9.0;

/// @dev A boolean flag represented as a uint256 (the native EVM word size)
/// This is more gas efficient when setting and clearing the flag
type BooleanFlag is uint256;

library BooleanFlagLib {
    /// @notice Error when boolean flag is not 0 or 1
    /// @dev Selector: 0x837017c0.
    /// @param value The value of the boolean flag
    error InvalidBoolValue(BooleanFlag value);

    uint256 constant FALSE = 0;
    uint256 constant TRUE = 1;

    function isSet(BooleanFlag value) internal pure returns (bool) {
        return BooleanFlag.unwrap(value) == TRUE;
    }

    function toBool(BooleanFlag value) internal pure returns (bool) {
        if (BooleanFlag.unwrap(value) == 0) return false;
        if (BooleanFlag.unwrap(value) == 1) return true;

        revert InvalidBoolValue(value);
    }

    function toWord(bool value) internal pure returns (BooleanFlag) {
        if (value) {
            return BooleanFlag.wrap(TRUE);
        } else {
            return BooleanFlag.wrap(FALSE);
        }
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "wormhole-solidity-sdk/Utils.sol";

import "../libraries/TransceiverStructs.sol";
import "../libraries/PausableOwnable.sol";
import "../libraries/external/ReentrancyGuardUpgradeable.sol";
import "../libraries/Implementation.sol";

import "../interfaces/INttManager.sol";
import "../interfaces/ITransceiver.sol";

/// @title Transceiver
/// @author Wormhole Project Contributors.
/// @notice This contract is a base contract for Transceivers.
/// @dev The Transceiver provides basic functionality for transmitting / receiving NTT messages.
///      The contract supports pausing via an admin or owner and is upgradable.
///
/// @dev The interface for receiving messages is not enforced by this contract.
///      Instead, inheriting contracts should implement their own receiving logic,
///      based on the verification model and serde logic associated with message handling.
abstract contract Transceiver is
    ITransceiver,
    PausableOwnable,
    ReentrancyGuardUpgradeable,
    Implementation
{
    /// @dev updating bridgeNttManager requires a new Transceiver deployment.
    /// Projects should implement their own governance to remove the old Transceiver
    /// contract address and then add the new one.
    address public immutable nttManager;
    address public immutable nttManagerToken;
    address immutable deployer;

    constructor(address _nttManager) {
        nttManager = _nttManager;
        nttManagerToken = INttManager(nttManager).token();
        deployer = msg.sender;
    }

    /// =============== MODIFIERS ===============================================

    modifier onlyNttManager() {
        if (msg.sender != nttManager) {
            revert CallerNotNttManager(msg.sender);
        }
        _;
    }

    /// =============== ADMIN ===============================================

    function _initialize() internal virtual override {
        // check if the owner is the deployer of this contract
        if (msg.sender != deployer) {
            revert UnexpectedDeployer(deployer, msg.sender);
        }

        __ReentrancyGuard_init();
        // owner of the transceiver is set to the owner of the nttManager
        __PausedOwnable_init(msg.sender, getNttManagerOwner());
    }

    /// @dev transfer the ownership of the transceiver to a new address
    /// the nttManager should be able to update transceiver ownership.
    function transferTransceiverOwnership(address newOwner) external onlyNttManager {
        _transferOwnership(newOwner);
    }

    function upgrade(address newImplementation) external onlyOwner {
        _upgrade(newImplementation);
    }

    function _migrate() internal virtual override {}

    // @define This method checks that the the referecnes to the nttManager and its corresponding function
    // are correct When new immutable variables are added, this function should be updated.
    function _checkImmutables() internal view virtual override {
        assert(this.nttManager() == nttManager);
        assert(this.nttManagerToken() == nttManagerToken);
    }

    /// =============== GETTERS & SETTERS ===============================================

    function getNttManagerOwner() public view returns (address) {
        return IOwnableUpgradeable(nttManager).owner();
    }

    function getNttManagerToken() public view virtual returns (address) {
        return nttManagerToken;
    }

    /// =============== TRANSCEIVING LOGIC ===============================================

    /// @inheritdoc ITransceiver
    function quoteDeliveryPrice(
        uint16 targetChain,
        TransceiverStructs.TransceiverInstruction memory instruction
    ) external view returns (uint256) {
        return _quoteDeliveryPrice(targetChain, instruction);
    }

    /// @inheritdoc ITransceiver
    function sendMessage(
        uint16 recipientChain,
        TransceiverStructs.TransceiverInstruction memory instruction,
        bytes memory nttManagerMessage,
        bytes32 recipientNttManagerAddress,
        bytes32 refundAddress
    ) external payable nonReentrant onlyNttManager {
        _sendMessage(
            recipientChain,
            msg.value,
            msg.sender,
            recipientNttManagerAddress,
            refundAddress,
            instruction,
            nttManagerMessage
        );
    }

    /// ============================= INTERNAL =========================================

    function _sendMessage(
        uint16 recipientChain,
        uint256 deliveryPayment,
        address caller,
        bytes32 recipientNttManagerAddress,
        bytes32 refundAddress,
        TransceiverStructs.TransceiverInstruction memory transceiverInstruction,
        bytes memory nttManagerMessage
    ) internal virtual;

    // @define This method is called by the BridgeNttManager contract to send a cross-chain message.
    // @reverts if:
    //     - `recipientNttManagerAddress` does not match the address of this manager contract
    function _deliverToNttManager(
        uint16 sourceChainId,
        bytes32 sourceNttManagerAddress,
        bytes32 recipientNttManagerAddress,
        TransceiverStructs.NttManagerMessage memory payload
    ) internal virtual {
        if (recipientNttManagerAddress != toWormholeFormat(nttManager)) {
            revert UnexpectedRecipientNttManagerAddress(
                toWormholeFormat(nttManager), recipientNttManagerAddress
            );
        }
        INttManager(nttManager).attestationReceived(sourceChainId, sourceNttManagerAddress, payload);
    }

    function _quoteDeliveryPrice(
        uint16 targetChain,
        TransceiverStructs.TransceiverInstruction memory transceiverInstruction
    ) internal view virtual returns (uint256);
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./IWormhole.sol";

interface ITokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    function _parseTransferCommon(bytes memory encoded) external pure returns (Transfer memory transfer);

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce)
        external
        payable
        returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload)
        external
        payable
        returns (uint64 sequence);

    function transferTokens(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(TransferWithPayload memory transfer)
        external
        pure
        returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded)
        external
        pure
        returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(bytes memory encoded) external pure returns (RegisterChain memory chain);

    function parseUpgrade(bytes memory encoded) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(bytes memory encodedRecoverChainId)
        external
        pure
        returns (RecoverChainId memory rci);
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

pragma solidity ^0.8.0;

interface ITokenMessenger {
   /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `destinationCaller`.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param amount amount of tokens to burn
     * @param destinationDomain destination domain
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param destinationCaller caller on the destination domain, as bytes32
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce);
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

import "./IRelayer.sol";
import "./IReceiver.sol";

/**
 * @title IMessageTransmitter
 * @notice Interface for message transmitters, which both relay and receive messages.
 */
interface IMessageTransmitter is IRelayer, IReceiver {

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity >=0.8.8 <0.9.0;

import "./PausableUpgradeable.sol";
import "./external/OwnableUpgradeable.sol";

abstract contract PausableOwnable is PausableUpgradeable, OwnableUpgradeable {
    /*
     * @dev Modifier to allow only the Pauser and the Owner to access pausing functionality
     */
    modifier onlyOwnerOrPauser() {
        _checkOwnerOrPauser(owner());
        _;
    }

    /*
     * @dev Modifier to allow only the Pauser to access some functionality
     */
    function _checkOwnerOrPauser(address owner) internal view {
        if (pauser() != msg.sender && owner != msg.sender) {
            revert InvalidPauser(msg.sender);
        }
    }

    function __PausedOwnable_init(address initialPauser, address owner) internal onlyInitializing {
        __Paused_init(initialPauser);
        __Ownable_init(owner);
    }

    /**
     * @dev Transfers the ability to pause to a new account (`newPauser`).
     */
    function transferPauserCapability(address newPauser) public virtual onlyOwnerOrPauser {
        PauserStorage storage $ = _getPauserStorage();
        address oldPauser = $._pauser;
        $._pauser = newPauser;
        emit PauserTransferred(oldPauser, newPauser);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.19;

import {Initializable} from "./Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    /// @custom:storage-location erc7201:openzeppelin.storage.ReentrancyGuard
    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
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
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        $._status = ENTERED;
    }

    function _nonReentrantAfter() private {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        $._status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        return $._status == ENTERED;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "./external/Initializable.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/// @dev This contract should be used as a base contract for implementation contracts
///      that are used with ERC1967Proxy.
///      It ensures that the contract cannot be initialized directly, only through
///      the proxy (by disabling initializers in the constructor).
///      It also exposes a migrate function that is called during upgrades.
abstract contract Implementation is Initializable, ERC1967Upgrade {
    address immutable _this;

    error OnlyDelegateCall();
    error NotMigrating();

    constructor() {
        _disableInitializers();
        _this = address(this);
    }

    modifier onlyDelegateCall() {
        _checkDelegateCall();
        _;
    }

    struct _Migrating {
        bool isMigrating;
    }

    struct _Bool {
        bool value;
    }

    bytes32 private constant MIGRATING_SLOT = bytes32(uint256(keccak256("ntt.migrating")) - 1);

    bytes32 private constant MIGRATES_IMMUTABLES_SLOT =
        bytes32(uint256(keccak256("ntt.migratesImmutables")) - 1);

    function _getMigratingStorage() private pure returns (_Migrating storage $) {
        uint256 slot = uint256(MIGRATING_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _getMigratesImmutablesStorage() internal pure returns (_Bool storage $) {
        uint256 slot = uint256(MIGRATES_IMMUTABLES_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _checkDelegateCall() internal view {
        if (address(this) == _this) {
            revert OnlyDelegateCall();
        }
    }

    function initialize() external payable onlyDelegateCall initializer {
        _initialize();
    }

    function migrate() external onlyDelegateCall reinitializer(_getInitializedVersion() + 1) {
        // NOTE: we add the reinitializer() modifier so that onlyInitializing
        // functions can be called inside
        if (!_getMigratingStorage().isMigrating) {
            revert NotMigrating();
        }
        _migrate();
    }

    function _migrate() internal virtual;

    function _initialize() internal virtual;

    function _checkImmutables() internal view virtual;

    function _upgrade(address newImplementation) internal {
        _checkDelegateCall();
        _upgradeTo(newImplementation);

        _Migrating storage _migrating = _getMigratingStorage();
        assert(!_migrating.isMigrating);
        _migrating.isMigrating = true;

        this.migrate();
        if (!this.getMigratesImmutables()) {
            _checkImmutables();
        }
        _setMigratesImmutables(false);

        _migrating.isMigrating = false;
    }

    function getMigratesImmutables() public view returns (bool) {
        return _getMigratesImmutablesStorage().value;
    }

    function _setMigratesImmutables(bool value) internal {
        _getMigratesImmutablesStorage().value = value;
    }
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import "../libraries/TransceiverStructs.sol";

interface ITransceiver {
    /// @notice The caller is not the deployer.
    /// @dev Selector: 0xc68a0e42.
    /// @param deployer The address of the deployer.
    /// @param caller The address of the caller.
    error UnexpectedDeployer(address deployer, address caller);

    /// @notice The caller is not the NttManager.
    /// @dev Selector: 0xc5aa6153.
    /// @param caller The address of the caller.
    error CallerNotNttManager(address caller);

    /// @notice Error when trying renounce transceiver ownership.
    ///         Ensures the owner of the transceiver is in sync with
    ///         the owner of the NttManager.
    /// @dev Selector: 0x66791dd6.
    /// @param currentOwner he current owner of the transceiver.
    error CannotRenounceTransceiverOwnership(address currentOwner);

    /// @notice Error when trying to transfer transceiver ownership.
    /// @dev Selector: 0x306239eb.
    /// @param currentOwner The current owner of the transceiver.
    /// @param newOwner The new owner of the transceiver.
    error CannotTransferTransceiverOwnership(address currentOwner, address newOwner);

    /// @notice Error when the recipient NttManager address is not the
    ///         corresponding manager of the transceiver.
    /// @dev Selector: 0x73bdd322.
    /// @param recipientNttManagerAddress The address of the recipient NttManager.
    /// @param expectedRecipientNttManagerAddress The expected address of the recipient NttManager.
    error UnexpectedRecipientNttManagerAddress(
        bytes32 recipientNttManagerAddress, bytes32 expectedRecipientNttManagerAddress
    );

    /// @notice Fetch the delivery price for a given recipient chain transfer.
    /// @param recipientChain The Wormhole chain ID of the target chain.
    /// @param instruction An additional Instruction provided by the Transceiver to be
    ///        executed on the recipient chain.
    /// @return deliveryPrice The cost of delivering a message to the recipient chain,
    ///         in this chain's native token.
    function quoteDeliveryPrice(
        uint16 recipientChain,
        TransceiverStructs.TransceiverInstruction memory instruction
    ) external view returns (uint256);

    /// @dev Send a message to another chain.
    /// @param recipientChain The Wormhole chain ID of the recipient.
    /// @param instruction An additional Instruction provided by the Transceiver to be
    /// executed on the recipient chain.
    /// @param nttManagerMessage A message to be sent to the nttManager on the recipient chain.
    function sendMessage(
        uint16 recipientChain,
        TransceiverStructs.TransceiverInstruction memory instruction,
        bytes memory nttManagerMessage,
        bytes32 recipientNttManagerAddress,
        bytes32 refundAddress
    ) external payable;

    /// @notice Upgrades the transceiver to a new implementation.
    function upgrade(address newImplementation) external;

    /// @notice Transfers the ownership of the transceiver to a new address.
    function transferTransceiverOwnership(address newOwner) external;
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

/**
 * @title IRelayer
 * @notice Sends messages from source domain to destination domain
 */
interface IRelayer {
    /**
     * @notice Sends an outgoing message from the source domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody
    ) external returns (uint64);

    /**
     * @notice Sends an outgoing message from the source domain, with a specified caller on the
     * destination domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * sendMessage() should be preferred for use cases where a specific destination caller is not required.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param destinationCaller caller on the destination domain, as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);

    /**
     * @notice Replace a message with a new message body and/or destination caller.
     * @dev The `originalAttestation` must be a valid attestation of `originalMessage`.
     * @param originalMessage original message to replace
     * @param originalAttestation attestation of `originalMessage`
     * @param newMessageBody new message body of replaced message
     * @param newDestinationCaller the new destination caller
     */
    function replaceMessage(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes calldata newMessageBody,
        bytes32 newDestinationCaller
    ) external;
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

/**
 * @title IReceiver
 * @notice Receives messages on destination chain and forwards them to IMessageDestinationHandler
 */
interface IReceiver {
    /**
     * @notice Receives an incoming message, validating the header and passing
     * the body to application-specific handler.
     * @param message The message raw bytes
     * @param signature The message signature
     * @return success bool, true if successful
     */
    function receiveMessage(bytes calldata message, bytes calldata signature)
        external
        returns (bool success);
}

// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

/**
 * @dev Contact Module that allows children to implement logic to pause and unpause the contract.
 * This is based on the OpenZeppelin Pausable contract but makes use of deterministic storage slots
 * and the EVM native word size to optimize gas costs.
 *
 * The `whenPaused` and `whenNotPaused` modifiers are used to
 * execute code based on the current state of the contract.
 *
 */
import {Initializable} from "./external/Initializable.sol";

abstract contract PausableUpgradeable is Initializable {
    /*
     * @custom:storage-location erc7201:openzeppelin.storage.Pausable.
     * @dev Storage slot with the pauser account, this is managed by the `PauserStorage` struct
    */
    struct PauserStorage {
        address _pauser;
    }

    // @dev Storage slot with the pause flag, this is managed by the `PauseStorage` struct
    struct PauseStorage {
        uint256 _pauseFlag;
    }

    /// NOTE: use uint256 to save on gas because it is the native word size of the EVM
    /// it is cheaper than using a bool because modifying a boolean value requires an extra SLOAD
    uint256 private constant NOT_PAUSED = 1;
    uint256 private constant PAUSED = 2;

    event PauserTransferred(address indexed oldPauser, address indexed newPauser);

    /**
     * @dev Contract is not paused, functionality is unblocked
     */
    error RequireContractIsNotPaused();
    /**
     * @dev Contract state is paused, blocking
     */
    error RequireContractIsPaused();

    /**
     * @dev the pauser is not a valid pauser account (e.g. `address(0)`)
     */
    error InvalidPauser(address account);

    // @dev Emitted when the contract is paused
    event Paused(bool paused);
    event NotPaused(bool notPaused);

    bytes32 private constant PAUSE_SLOT = bytes32(uint256(keccak256("Pause.pauseFlag")) - 1);
    bytes32 private constant PAUSER_ROLE_SLOT = bytes32(uint256(keccak256("Pause.pauseRole")) - 1);

    function _getPauserStorage() internal pure returns (PauserStorage storage $) {
        uint256 slot = uint256(PAUSER_ROLE_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    /**
     * @dev Returns the current pauser account address.
     */
    function pauser() public view returns (address) {
        return _getPauserStorage()._pauser;
    }

    function _getPauseStorage() private pure returns (PauseStorage storage $) {
        uint256 slot = uint256(PAUSE_SLOT);
        assembly ("memory-safe") {
            $.slot := slot
        }
    }

    function _setPauseStorage(uint256 pauseFlag) internal {
        _getPauseStorage()._pauseFlag = pauseFlag;
    }

    function __Paused_init(address initialPauser) internal onlyInitializing {
        __Paused_init_unchained(initialPauser);
    }

    function __Paused_init_unchained(address initialPauser) internal onlyInitializing {
        // set pause flag to false initially
        PauseStorage storage $ = _getPauseStorage();
        $._pauseFlag = NOT_PAUSED;

        // set the initial pauser
        PauserStorage storage $_role = _getPauserStorage();
        $_role._pauser = initialPauser;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     * Calling a function when this flag is set to `PAUSED` will cause the transaction to revert.
     */
    modifier whenNotPaused() {
        if (isPaused()) {
            revert RequireContractIsNotPaused();
        }
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     * Calling a function when this flag is set to `PAUSED` will cause the transaction to revert.
     */
    modifier whenPaused() {
        if (!isPaused()) {
            revert RequireContractIsPaused();
        }
        _;
    }

    /*
     * @dev Modifier to allow only the Pauser to access pausing functionality
     */
    modifier onlyPauser() {
        _checkPauser();
        _;
    }

    /*
     * @dev Modifier to allow only the Pauser to access some functionality
     */
    function _checkPauser() internal view {
        if (pauser() != msg.sender) {
            revert InvalidPauser(msg.sender);
        }
    }

    /**
     * @dev pauses the function and emits the `Paused` event
     */
    function _pause() internal virtual whenNotPaused {
        // this can only be set to PAUSED when the state is NOTPAUSED
        _setPauseStorage(PAUSED);
        emit Paused(true);
    }

    /**
     * @dev unpauses the function
     */
    function _unpause() internal virtual whenPaused {
        // this can only be set to NOTPAUSED when the state is PAUSED
        _setPauseStorage(NOT_PAUSED);
        emit NotPaused(false);
    }

    /**
     * @dev Returns true if the method is paused, and false otherwise.
     */
    function isPaused() public view returns (bool) {
        PauseStorage storage $ = _getPauseStorage();
        return $._pauseFlag == PAUSED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

// COPIED FROM OPENZEPPELIN v5.0.1
// COPIED TO CHANGE SOLC FROM ^0.8.20 TO ^0.8.19

pragma solidity ^0.8.19;

import {ContextUpgradeable} from "./ContextUpgradeable.sol";
import {Initializable} from "./Initializable.sol";
import "../../interfaces/IOwnableUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable, IOwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation =
        0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

// COPIED FROM OPENZEPPELIN v5.0.1
// COPIED TO CHANGE SOLC FROM ^0.8.20 TO ^0.8.19

pragma solidity ^0.8.19;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

// COPIED FROM OPENZEPPELIN v5.0.1
// COPIED TO CHANGE SOLC FROM ^0.8.20 TO ^0.8.19

pragma solidity ^0.8.19;

import {Initializable} from "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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

// SPDX-License-Identifier: Apache 2
//
pragma solidity >=0.8.8 <0.9.0;

interface IOwnableUpgradeable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}