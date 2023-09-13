// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library CalldataBytesLib {
    function toU8(bytes calldata _bytes, uint _start) internal pure returns (uint8) {
        return uint8(_bytes[_start]);
    }

    function toU16(bytes calldata _bytes, uint _start) internal pure returns (uint16) {
        unchecked {
            uint end = _start + 2;
            return uint16(bytes2(_bytes[_start:end]));
        }
    }

    function toU32(bytes calldata _bytes, uint _start) internal pure returns (uint32) {
        unchecked {
            uint end = _start + 4;
            return uint32(bytes4(_bytes[_start:end]));
        }
    }

    function toU64(bytes calldata _bytes, uint _start) internal pure returns (uint64) {
        unchecked {
            uint end = _start + 8;
            return uint64(bytes8(_bytes[_start:end]));
        }
    }

    function toU128(bytes calldata _bytes, uint _start) internal pure returns (uint128) {
        unchecked {
            uint end = _start + 16;
            return uint128(bytes16(_bytes[_start:end]));
        }
    }

    function toU256(bytes calldata _bytes, uint _start) internal pure returns (uint256) {
        unchecked {
            uint end = _start + 32;
            return uint256(bytes32(_bytes[_start:end]));
        }
    }

    function toAddr(bytes calldata _bytes, uint _start) internal pure returns (address) {
        unchecked {
            uint end = _start + 20;
            return address(bytes20(_bytes[_start:end]));
        }
    }

    function toB32(bytes calldata _bytes, uint _start) internal pure returns (bytes32) {
        unchecked {
            uint end = _start + 32;
            return bytes32(_bytes[_start:end]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // Invalid Argument (http: 400)
    string internal constant INVALID_ARGUMENT = "LZ10000";
    string internal constant ONLY_REGISTERED = "LZ10001";
    string internal constant ONLY_REGISTERED_OR_DEFAULT = "LZ10002";
    string internal constant INVALID_AMOUNT = "LZ10003";
    string internal constant INVALID_NONCE = "LZ10004";
    string internal constant SAME_VALUE = "LZ10005";
    string internal constant UNSORTED = "LZ10006";
    string internal constant INVALID_VERSION = "LZ10007";
    string internal constant INVALID_EID = "LZ10008";
    string internal constant INVALID_SIZE = "LZ10009";
    string internal constant ONLY_NON_DEFAULT = "LZ10010";
    string internal constant INVALID_VERIFIERS = "LZ10011";
    string internal constant INVALID_WORKER_ID = "LZ10012";
    string internal constant DUPLICATED_OPTION = "LZ10013";
    string internal constant INVALID_LEGACY_OPTION = "LZ10014";
    string internal constant INVALID_VERIFIER_OPTION = "LZ10015";
    string internal constant INVALID_WORKER_OPTIONS = "LZ10016";
    string internal constant INVALID_EXECUTOR_OPTION = "LZ10017";
    string internal constant INVALID_ADDRESS = "LZ10018";

    // Out of Range (http: 400)
    string internal constant OUT_OF_RANGE = "LZ20000";

    // Invalid State (http: 400)
    string internal constant INVALID_STATE = "LZ30000";
    string internal constant SEND_REENTRANCY = "LZ30001";
    string internal constant RECEIVE_REENTRANCY = "LZ30002";
    string internal constant COMPOSE_REENTRANCY = "LZ30003";

    // Permission Denied (http: 403)
    string internal constant PERMISSION_DENIED = "LZ50000";

    // Not Found (http: 404)
    string internal constant NOT_FOUND = "LZ60000";

    // Already Exists (http: 409)
    string internal constant ALREADY_EXISTS = "LZ80000";

    // Not Implemented (http: 501)
    string internal constant NOT_IMPLEMENTED = "LZC0000";
    string internal constant UNSUPPORTED_INTERFACE = "LZC0001";
    string internal constant UNSUPPORTED_OPTION_TYPE = "LZC0002";

    // Unavailable (http: 503)
    string internal constant UNAVAILABLE = "LZD0000";
    string internal constant NATIVE_COIN_UNAVAILABLE = "LZD0001";
    string internal constant TOKEN_UNAVAILABLE = "LZD0002";
    string internal constant DEFAULT_LIBRARY_UNAVAILABLE = "LZD0003";
    string internal constant VERIFIERS_UNAVAILABLE = "LZD0004";
}

// SPDX-License-Identifier: BUSL-1.1

// modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/BitMaps.sol
pragma solidity ^0.8.19;

library BitMaps {
    type BitMap256 is uint;

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap256 bitmap, uint8 index) internal pure returns (bool) {
        uint256 mask = 1 << index;
        return BitMap256.unwrap(bitmap) & mask != 0;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap256 bitmap, uint8 index) internal pure returns (BitMap256) {
        uint256 mask = 1 << index;
        return BitMap256.wrap(BitMap256.unwrap(bitmap) | mask);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroPriceFeed {
    /**
     * @dev
     * priceRatio: (USD price of 1 unit of remote native token in unit of local native token) * PRICE_RATIO_DENOMINATOR
     */

    struct Price {
        uint128 priceRatio; // float value * 10 ^ 20, decimal awared. for aptos to evm, the basis would be (10^18 / 10^8) * 10 ^20 = 10 ^ 30.
        uint64 gasPriceInUnit; // for evm, it is in wei, for aptos, it is in octas.
        uint32 gasPerByte;
    }

    struct UpdatePrice {
        uint32 eid;
        Price price;
    }

    /**
     * @dev
     *    ArbGasInfo.go:GetPricesInArbGas
     *
     */
    struct ArbitrumPriceExt {
        uint64 gasPerL2Tx; // L2 overhead
        uint32 gasPerL1CallDataByte;
    }

    struct UpdatePriceExt {
        uint32 eid;
        Price price;
        ArbitrumPriceExt extend;
    }

    function nativeTokenPriceUSD() external view returns (uint128);

    function getFee(uint32 _dstEid, uint _callDataSize, uint _gas) external view returns (uint);

    function getPrice(uint32 _dstEid) external view returns (Price memory);

    function getPriceRatioDenominator() external view returns (uint128);

    function estimateFeeByEid(
        uint32 _dstEid,
        uint _callDataSize,
        uint _gas
    ) external view returns (uint fee, uint128 priceRatio, uint128 priceRatioDenominator, uint128 nativePriceUSD);

    function estimateFeeOnSend(
        uint32 _dstEid,
        uint _callDataSize,
        uint _gas
    ) external payable returns (uint fee, uint128 priceRatio, uint128 priceRatioDenominator, uint128 nativePriceUSD);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface IWorker {
    event SetWorkerLib(address workerLib);
    event SetPriceFeed(address priceFeed);
    event SetDefaultMultiplierBps(uint16 multiplierBps);
    event Withdraw(address lib, address to, uint amount);

    function setPriceFeed(address _priceFeed) external;

    function priceFeed() external view returns (address);

    function setDefaultMultiplierBps(uint16 _multiplierBps) external;

    function defaultMultiplierBps() external view returns (uint16);

    function withdrawFee(address _lib, address _to, uint _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/BitMaps.sol";

import "../interfaces/ILayerZeroPriceFeed.sol";
import "./interfaces/IVerifier.sol";
import "./interfaces/IVerifierFeeLib.sol";
import "./libs/VerifierOptions.sol";

contract VerifierFeeLib is IVerifierFeeLib {
    using BitMaps for BitMaps.BitMap256;
    using VerifierOptions for bytes;

    uint16 internal constant EXECUTE_FIXED_BYTES = 68; // encoded: funcSigHash + params -> 4  + (32 * 2)
    uint16 internal constant SIGNATURE_RAW_BYTES = 65; // not encoded
    // callData(updateHash) = 132 (4 + 32 * 4), padded to 32 = 160 and encoded as bytes with an 64 byte overhead = 224
    uint16 internal constant UPDATE_HASH_BYTES = 224;
    uint internal constant NATIVE_DECIMALS_RATE = 1e18;

    // ========================= External =========================

    /// @dev get fee function that can change state. e.g. paying priceFeed
    /// @param _params fee params
    /// @param _dstConfig dst config
    /// @param //_options options
    function getFeeOnSend(
        FeeParams memory _params,
        IVerifier.DstConfig memory _dstConfig,
        bytes memory /* _options */
    ) external payable returns (uint) {
        uint callDataSize = _getCallDataSize(_params.quorum);

        // for future versions where priceFeed charges a fee
        //        uint priceFeedFee = ILayerZeroPriceFeed(_params.priceFeed).getFee(_params.dstEid, callDataSize, _dstConfig.gas);
        //        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeOnSend{
        //            value: priceFeedFee
        //        }(_params.dstEid, callDataSize, _dstConfig.gas);

        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeOnSend(
            _params.dstEid,
            callDataSize,
            _dstConfig.gas
        );

        return
            _applyPremium(
                fee,
                _dstConfig.multiplierBps,
                _params.defaultMultiplierBps,
                _dstConfig.floorMarginUSD,
                nativePriceUSD
            );
    }

    // ========================= View =========================

    /// @dev get fee view function
    /// @param _params fee params
    /// @param _dstConfig dst config
    /// @param //_options options
    function getFee(
        FeeParams calldata _params,
        IVerifier.DstConfig calldata _dstConfig,
        bytes calldata /* _options */
    ) external view returns (uint) {
        uint callDataSize = _getCallDataSize(_params.quorum);
        (uint fee, , , uint128 nativePriceUSD) = ILayerZeroPriceFeed(_params.priceFeed).estimateFeeByEid(
            _params.dstEid,
            callDataSize,
            _dstConfig.gas
        );
        return
            _applyPremium(
                fee,
                _dstConfig.multiplierBps,
                _params.defaultMultiplierBps,
                _dstConfig.floorMarginUSD,
                nativePriceUSD
            );
    }

    // ========================= Internal =========================

    function _getCallDataSize(uint _quorum) internal pure returns (uint) {
        uint totalSignatureBytes = _quorum * SIGNATURE_RAW_BYTES;
        if (totalSignatureBytes % 32 != 0) {
            totalSignatureBytes = totalSignatureBytes - (totalSignatureBytes % 32) + 32;
        }
        // getFee should charge on execute(updateHash)
        // totalSignatureBytesPadded also has 64 overhead for bytes
        return uint(EXECUTE_FIXED_BYTES) + UPDATE_HASH_BYTES + totalSignatureBytes + 64;
    }

    function _applyPremium(
        uint _fee,
        uint16 _bps,
        uint16 _defaultBps,
        uint128 _marginUSD,
        uint128 _nativePriceUSD
    ) internal pure returns (uint) {
        uint16 multiplierBps = _bps == 0 ? _defaultBps : _bps;

        uint feeWithMultiplier = (_fee * multiplierBps) / 10000;
        if (_nativePriceUSD == 0 || _marginUSD == 0) {
            return feeWithMultiplier;
        }

        uint feeWithFloorMargin = _fee + (_marginUSD * NATIVE_DECIMALS_RATE) / _nativePriceUSD;

        return feeWithFloorMargin > feeWithMultiplier ? feeWithFloorMargin : feeWithMultiplier;
    }

    // todo: add to getFee and getFeeOnSend
    function _decodeVerifierOptions(bytes calldata _options) internal pure returns (uint totalFee) {
        BitMaps.BitMap256 bitmap;
        uint cursor;

        while (cursor < _options.length) {
            (uint8 optionType, , uint newCursor) = _options.nextVerifierOption(cursor);
            cursor = newCursor;

            // check if option type is duplicated
            require(!bitmap.get(optionType), Errors.DUPLICATED_OPTION);
            bitmap = bitmap.set(optionType);

            if (optionType == VerifierOptions.OPTION_TYPE_PRECRIME) {
                totalFee += 100; //todo: confirm fee
            } else {
                revert("VerifierFeeLib: invalid option type");
            }
        }
        require(cursor == _options.length, Errors.INVALID_VERIFIER_OPTION);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

interface ILayerZeroVerifier {
    struct AssignJobParam {
        uint32 dstEid;
        bytes packetHeader;
        bytes32 payloadHash;
        uint64 confirmations;
        address sender;
    }

    // @notice query price and assign jobs at the same time
    // @param _dstEid - the destination endpoint identifier
    // @param _packetHeader - version + nonce + path
    // @param _payloadHash - hash of guid + message
    // @param _confirmations - block confirmation delay before relaying blocks
    // @param _sender - the source sending contract address
    // @param _options - options
    function assignJob(AssignJobParam calldata _param, bytes calldata _options) external payable returns (uint fee);

    // @notice query the verifier fee for relaying block information to the destination chain
    // @param _dstEid the destination endpoint identifier
    // @param _confirmations - block confirmation delay before relaying blocks
    // @param _sender - the source sending contract address
    // @param _options - options
    function getFee(
        uint32 _dstEid,
        uint64 _confirmations,
        address _sender,
        bytes calldata _options
    ) external view returns (uint fee);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "../../interfaces/IWorker.sol";
import "./ILayerZeroVerifier.sol";

interface IVerifier is IWorker, ILayerZeroVerifier {
    struct DstConfigParam {
        uint32 dstEid;
        uint64 gas;
        uint16 multiplierBps;
        uint128 floorMarginUSD;
    }

    struct DstConfig {
        uint64 gas;
        uint16 multiplierBps;
        uint128 floorMarginUSD; // uses priceFeed PRICE_RATIO_DENOMINATOR
    }

    event SetDstConfig(DstConfigParam[] params);

    function dstConfig(uint32 _dstEid) external view returns (uint64, uint16, uint128);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./IVerifier.sol";

interface IVerifierFeeLib {
    struct FeeParams {
        address priceFeed;
        uint32 dstEid;
        uint64 confirmations;
        address sender;
        uint64 quorum;
        uint16 defaultMultiplierBps;
    }

    function getFeeOnSend(
        FeeParams memory _params,
        IVerifier.DstConfig memory _dstConfig,
        bytes memory _options
    ) external payable returns (uint fee);

    function getFee(
        FeeParams calldata _params,
        IVerifier.DstConfig calldata _dstConfig,
        bytes calldata _options
    ) external view returns (uint fee);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/messagelib/libs/BitMaps.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/Errors.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/libs/CalldataBytesLib.sol";

library VerifierOptions {
    using BitMaps for BitMaps.BitMap256;
    using CalldataBytesLib for bytes;
    using BytesLib for bytes;

    uint8 internal constant WORKER_ID = 2;
    uint8 internal constant OPTION_TYPE_PRECRIME = 1;

    /// @dev group verifier options by its idx
    /// @param _options [verifier_id][verifier_option][verifier_id][verifier_option]...
    ///        verifier_option = [option_size][verifier_idx][option_type][option]
    ///        option_size = len(verifier_idx) + len(option_type) + len(option)
    ///        verifier_id: uint8, verifier_idx: uint8, option_size: uint16, option_type: uint8, option: bytes
    /// @return verifierOptions the grouped options, still share the same format of _options
    /// @return verifierIndices the verifier indices
    function groupVerifierOptionsByIdx(
        bytes memory _options
    ) internal pure returns (bytes[] memory verifierOptions, uint8[] memory verifierIndices) {
        if (_options.length == 0) return (verifierOptions, verifierIndices);

        uint8 numVerifiers = getNumVerifiers(_options);

        // if there is only 1 verifier, we can just return the whole options
        if (numVerifiers == 1) {
            verifierOptions = new bytes[](1);
            verifierOptions[0] = _options;

            verifierIndices = new uint8[](1);
            verifierIndices[0] = _options.toUint8(3); // verifier idx
            return (verifierOptions, verifierIndices);
        }

        // otherwise, we need to group the options by verifier_idx
        verifierIndices = new uint8[](numVerifiers);
        verifierOptions = new bytes[](numVerifiers);
        unchecked {
            uint cursor;
            uint start;
            uint8 lastVerifierIdx = 255; // 255 is an invalid verifier_idx

            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                // optionLength asserted in getNumVerifiers (skip check)
                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;

                // verifierIdx asserted in getNumVerifiers (skip check)
                uint8 verifierIdx = _options.toUint8(cursor);

                // verifierIdx must equal to the lastVerifierIdx for the first option
                // so it is always skipped in the first option
                // this operation slices out options whenever the scan finds a different lastVerifierIdx
                if (lastVerifierIdx == 255) {
                    lastVerifierIdx = verifierIdx;
                } else if (verifierIdx != lastVerifierIdx) {
                    uint len = cursor - start - 3; // 3 is for worker_id and option_length
                    bytes memory opt = _options.slice(start, len);
                    _insertVerifierOptions(verifierOptions, verifierIndices, lastVerifierIdx, opt);

                    // reset the start and lastVerifierIdx
                    start += len;
                    lastVerifierIdx = verifierIdx;
                }

                cursor += optionLength;
            }

            // skip check the cursor here because the cursor is asserted in getNumVerifiers
            // if we have reached the end of the options, we need to process the last verifier
            uint size = cursor - start;
            bytes memory op = _options.slice(start, size);
            _insertVerifierOptions(verifierOptions, verifierIndices, lastVerifierIdx, op);

            // revert verifierIndices to start from 0
            for (uint8 i = 0; i < numVerifiers; ++i) {
                --verifierIndices[i];
            }
        }
    }

    function _insertVerifierOptions(
        bytes[] memory _verifierOptions,
        uint8[] memory _verifierIndices,
        uint8 _verifierIdx,
        bytes memory _newOptions
    ) internal pure {
        unchecked {
            // verifierIdx starts from 0 but default value of verifierIndices is 0,
            // so we tell if the slot is empty by adding 1 to verifierIdx
            require(_verifierIdx < 255, Errors.INVALID_VERIFIERS);
            uint8 verifierIdxAdj = _verifierIdx + 1;

            for (uint8 j = 0; j < _verifierIndices.length; ++j) {
                uint8 index = _verifierIndices[j];
                if (verifierIdxAdj == index) {
                    _verifierOptions[j] = abi.encodePacked(_verifierOptions[j], _newOptions);
                    break;
                } else if (index == 0) {
                    // empty slot, that means it is the first time we see this verifier
                    _verifierIndices[j] = verifierIdxAdj;
                    _verifierOptions[j] = _newOptions;
                    break;
                }
            }
        }
    }

    /// @dev get the number of unique verifiers
    /// @param _options the format is the same as groupVerifierOptionsByIdx
    function getNumVerifiers(bytes memory _options) internal pure returns (uint8 numVerifiers) {
        uint cursor;
        BitMaps.BitMap256 bitmap;

        // find number of unique verifier_idx
        unchecked {
            while (cursor < _options.length) {
                ++cursor; // skip worker_id

                uint16 optionLength = _options.toUint16(cursor);
                cursor += 2;
                require(optionLength >= 2, Errors.INVALID_VERIFIER_OPTION); // at least 1 byte for verifier_idx and 1 byte for option_type

                uint8 verifierIdx = _options.toUint8(cursor);

                // if verifierIdx is not set, increment numVerifiers
                // max num of verifiers is 255, 255 is an invalid verifier_idx
                require(verifierIdx < 255, Errors.INVALID_VERIFIERS);
                if (!bitmap.get(verifierIdx)) {
                    ++numVerifiers;
                    bitmap = bitmap.set(verifierIdx);
                }

                cursor += optionLength;
            }
        }
        require(cursor == _options.length, Errors.INVALID_VERIFIER_OPTION);
    }

    /// @dev decode the next verifier option from _options starting from the specified cursor
    /// @param _options the format is the same as groupVerifierOptionsByIdx
    /// @param _cursor the cursor to start decoding
    /// @return optionType the type of the option
    /// @return option the option
    /// @return cursor the cursor to start decoding the next option
    function nextVerifierOption(
        bytes calldata _options,
        uint _cursor
    ) internal pure returns (uint8 optionType, bytes calldata option, uint cursor) {
        unchecked {
            // skip worker id
            cursor = _cursor + 1;

            // read option size
            uint16 size = _options.toU16(cursor);
            cursor += 2;

            // read option type
            optionType = _options.toU8(cursor + 1); // skip verifier_idx

            // startCursor and endCursor are used to slice the option from _options
            uint startCursor = cursor + 2; // skip option type and verifier_idx
            uint endCursor = cursor + size;
            option = _options[startCursor:endCursor];
            cursor += size;
        }
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