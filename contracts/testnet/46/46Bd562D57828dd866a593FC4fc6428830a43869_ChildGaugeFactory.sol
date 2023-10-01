// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function _checkGasLimit(uint16 _dstChainId, uint16 _type, bytes memory _adapterParams, uint _extraGas) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16 _version, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external onlyOwner {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external onlyOwner {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft(), 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload, bytes memory _reason) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
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

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "./interfaces/IChildGauge.sol";
import "./interfaces/IAnyCallProxy.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract ChildGaugeFactory is ReentrancyGuard, AccessControl, Ownable2Step {
    event Minted(address indexed recipient, address gauge, uint256 minted);
    event GaugeCreated(address indexed lpAddr, address indexed poolGauge, uint);
    event SetPermit2Address(address oldAddress, address newAddress);
    event SetGaugeOwner(address);
    event SetOperator(address);
    event SetGaugeImplementation(address);
    event UpdateMirrored(address indexed _gauge, bool _mirrored);
    event DeployedGauge(address indexed _implementation, address indexed _lpToken, address indexed _deployer, bytes32 _salt, address _gauge);
    event UpdateImplementation(address _oldImplementation, address _newImplementation);
    event UpdateVotingEscrow(address _oldVotingEscrow, address _newVotingEscrow);
    event UpdateCallProxy(address _oldCallProxy, address _newCallProxy);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 internal constant _WEEK = 86400 * 7;

    address public ltToken;
    address public votingEscrow;

    address public callProxy;
    uint256 public chainId;
    uint16 public mainChainId;

    uint256 public getGaugeCount;
    mapping(uint256 => address) public getGauge;
    mapping(address => address) public getGaugeFromLpToken;
    mapping(address => uint256) public gaugeData;

    // user -> gauge -> value
    mapping(address => mapping(address => uint256)) public minted;

    // constructor requires the LayerZero endpoint for this chain
    constructor(address _ltToken, uint16 _mainChainId, address _callProxy){

        ltToken = _ltToken;
        mainChainId = _mainChainId;
        callProxy = _callProxy;
    }

    function _psuedoMint(address _gauge, address _user) internal {
        uint256 _gaugeData = gaugeData[_gauge];
        require(_gaugeData != 0);

        // is_mirrored and  lastRequest != this week
        if ((_gaugeData & 2) != 0 && (_gaugeData >> 2 / _WEEK != block.timestamp / _WEEK)) {
            // cross-chain call
            bytes memory _data = abi.encodeWithSignature("transmit_emissions(address)", _gauge);
            IAnyCallProxy(callProxy).anyCall(address(0), address(this), _data, mainChainId, bytes(""));
            // update last request time
            gaugeData[_gauge] = block.timestamp << 2 + 3;
        }
        IChildGauge(_gauge).userCheckpoint(_user);
        uint256 totalMint = IChildGauge(_gauge).integrateFraction(_user);
        uint256 toMint = totalMint - minted[_user][_gauge];
        if (toMint > 0) {
            minted[_user][_gauge] = totalMint;
            // transfer tokens to user
            TransferHelper.doTransferOut(ltToken, _user, toMint);
            emit Minted(_user, _gauge, toMint);
        }
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param _gauge `LiquidityGauge` address to get mintable amount from
     */
    function mint(address _gauge) external nonReentrant {
        _psuedoMint(_gauge, msg.sender);
    }

    /***
     * @notice Mint everything which belongs to `msg.sender` across multiple gauges
     * @param _gauges List of `LiquidityGauge` addresses
     */
    function mintMany(address[] memory _gauges) external nonReentrant {
        require(_gauges.length < 50);
        for (uint256 i = 0; i < _gauges.length; i++) {
            address _gauge = _gauges[i];
            if (_gauge == address(0)) {
                continue;
            }
            _psuedoMint(_gauge, msg.sender);
        }
    }

    function deployGauge(address implementation, address _lpToken, bytes32 _salt, uint16 _chainId) external onlyRole(OPERATOR_ROLE) returns (address gauge) {
        if (getGaugeFromLpToken[_lpToken] != address(0)) {
            require(msg.sender == owner(), "only owner");
        }

        uint256 _gaugeData = 1;
        gauge = Clones.cloneDeterministic(implementation, keccak256(abi.encodePacked(_chainId, msg.sender, _salt)));
        IChildGauge(gauge).initialize(_lpToken);

        if (msg.sender == callProxy) {
            _gaugeData += 2;
            emit UpdateMirrored(gauge, true);
            // issue a call to the root chain to deploy a root gauge
            bytes memory _data = abi.encodeWithSignature("deployGauge(address,uint16,address,bytes32)", implementation, _chainId, ltToken, _salt);
            IAnyCallProxy(callProxy).anyCall(address(0), address(this), _data, mainChainId, bytes(""));
        }
        gaugeData[gauge] = _gaugeData;
        uint256 idx = getGaugeCount;
        getGauge[idx] = gauge;
        getGaugeCount = idx + 1;
        getGaugeFromLpToken[_lpToken] = gauge;

        emit DeployedGauge(implementation, _lpToken, msg.sender, _salt, gauge);
        return gauge;
    }

    /***
     * @notice Update the voting escrow contract
     */
    function setVotingEscrow(address _votingEscrow) external onlyOwner {
        emit UpdateVotingEscrow(votingEscrow, _votingEscrow);
        votingEscrow = _votingEscrow;
    }

    /***
     * @notice  Set the mirrored bit of the gauge data for `_gauge`
     * @param _gauge The gauge of interest
     * @param _mirrored  Boolean deteremining whether to set the mirrored bit to True/False
     */
    function setMirrored(address _gauge, bool _mirrored) external onlyRole(OPERATOR_ROLE) {
        uint256 _gaugeData = gaugeData[_gauge];
        require(_gaugeData != 0);
        _gaugeData = ((_gaugeData >> 2) << 2) + 1;
        if (_mirrored) {
            _gaugeData += 2;
        }
        gaugeData[_gauge] = _gaugeData;
        emit UpdateMirrored(_gauge, _mirrored);
    }

    function isValidGauge(address _gauge) external view returns (bool) {
        return gaugeData[_gauge] != 0;
    }

    /***
     * @notice Query whether the gauge is mirrored on Ethereum mainnet
     * @param _gauge The address of the gauge of interest
     */
    function isMirrored(address _gauge) external view returns (bool) {
        return (gaugeData[_gauge] & 2) != 0;
    }

    /***
     * @notice Query the timestamp of the last cross chain request for emissions
     * @param _gauge The address of the gauge of interest
     */
    function lastRequest(address _gauge) external view returns (uint256) {
        return gaugeData[_gauge] >> 2;
    }

    /***
 * @notice Set the address of the call proxy used
     */
    function setCallProxy(address _callProxy) external onlyOwner {
        require(_callProxy != address(0), "CE000");
        emit UpdateCallProxy(callProxy, _callProxy);
        callProxy = _callProxy;
    }


    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/interfaces/ILayerZeroEndpoint.sol";

interface IAnyCallProxy {


    function estimateFees(address _to, bytes calldata _data, uint16 _toChainID, bytes calldata _adapterParam) external view returns (uint nativeFee);

    function anyCall(address _paymentAddress, address _to, bytes calldata _data, uint16 _toChainID, bytes calldata _adapterParams) external payable;

}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IChildGauge {
    function initialize(address _lpToken) external;
    function userCheckpoint(address _addr) external returns (bool);
    function integrateFraction(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPermit2 {
    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IPermit2.sol";

library TransferHelper {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(to);
        safeTransferFrom(token, from, to, amount);
        uint256 balanceAfter = token.balanceOf(to);
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= amount);
        return actualAmount;
    }

    /**
     * @dev transfer with permit2
     */
    function doTransferIn(
        address permit2Address,
        address tokenAddress,
        uint256 _value,
        address from,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal returns (uint256) {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: tokenAddress, amount: _value}),
            nonce: nonce,
            deadline: deadline
        });
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: _value
        });
        // Read from storage once
        IERC20 token = IERC20(permit.permitted.token);
        uint256 balanceBefore = token.balanceOf(transferDetails.to);
        if (nonce == 0 && deadline == 0) {
            safeTransferFrom(token, from, transferDetails.to, transferDetails.requestedAmount);
        } else {
            IPermit2(permit2Address).permitTransferFrom(permit, transferDetails, from, signature);
        }
        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(permit.permitted.token).balanceOf(address(this));
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= transferDetails.requestedAmount);
        
        return actualAmount;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferOut(address tokenAddress, address to, uint256 amount) internal returns(uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(to);
        safeTransfer(token, to, amount);
        uint256 balanceAfter = token.balanceOf(to);
        uint256 actualAmount = balanceAfter - balanceBefore;
        assert(actualAmount <= amount);
        return actualAmount;
    }

    function doApprove(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeApprove(token, to, amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}