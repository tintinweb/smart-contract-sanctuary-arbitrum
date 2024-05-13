// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import {LibZip} from "solady/src/utils/LibZip.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library
 * @notice Utilize contract bytecode as persistent storage for large chunks of script string data.
 *         V2 includes optional on-chain compression/decompression via solady LibZip.
 *         This library is intended to have an external deployed copy that is released in the future,
 *         and, as such, has been designed to support both updated V2 and V1 (versioned, with purging removed)
 *         reads as well as backwards-compatible reads for both a) the unversioned "V0" storage contracts
 *         which were deployed by the original version of this libary and b) contracts that were deployed
 *         using one of the SSTORE2 implementations referenced below.
 *         For these pre-V1 storage contracts (which themselves did not have any explicit versioning semantics)
 *         backwards-compatible reads are optimistic, and only expected to work for contracts actually
 *         deployed by the original version of this library – and may fail ungracefully if attempted to be
 *         used to read from other contracts.
 *         This library is split into two components, intended to be updated in tandem, and thus included
 *         here in the same source file. One component is an internal library that is intended to be embedded
 *         directly into other contracts and provides all _write_ functionality. The other is a public library
 *         that is intended to be deployed as a standalone contract and provides all _read_ functionality.
 *
 * @author Art Blocks Inc.
 * @author Modified from 0xSequence (https://github.com/0xsequence/sstore2/blob/master/contracts/SSTORE2.sol)
 * @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
 * @author Utilizes LibZip from solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibZip.sol)
 *
 * @dev Compared to the above two rerferenced libraries, this contracts-as-storage implementation makes a few
 *      notably different design decisions:
 *      - uses the `string` data type for input/output on reads, rather than speaking in bytes directly,
 *        with an exception for optionally compressed data which are input as bytes
 *      - stores the "writer" address (library user) in the deployed contract bytes, which is useful for
 *        on-chain introspection and provenance purposes
 *      - stores a very simple versioning string in the deployed contract bytes, which captures the version
 *        of the library that was used to deploy the storage contract and useful for supporting future
 *        compatibility management as this library evolves (e.g. in response to EOF v1 migration plans)
 *      - stores a bool indicating if the stored data are compressed.
 *      Also, given that much of this library is written in assembly, this library makes use of a slightly
 *      different convention (when compared to the rest of the Art Blocks smart contract repo) around
 *      pre-defining return values in some cases in order to simplify need to directly memory manage these
 *      return values.
 */

/**
 * @title Art Blocks Script Storage Library (Public, Reads)
 * @author Art Blocks Inc.
 * @notice The public library for reading from storage contracts. This library is intended to be deployed as a
 *         standalone contract, and provides all _read_ functionality.
 */
library BytecodeStorageReader {
    // Define the set of known valid version strings that may be stored in the deployed storage contract bytecode
    // note: These are all intentionally exactly 32-bytes and are null-terminated. Null-termination is used due
    //       to this being the standard expected formatting in common web3 tooling such as ethers.js. Please see
    //       the following for additional context: https://docs.ethers.org/v5/api/utils/strings/#Bytes32String
    // Used for storage contracts that were deployed by an unknown source
    bytes32 public constant UNKNOWN_VERSION_STRING =
        "UNKNOWN_VERSION_STRING_________ ";
    // Pre-dates versioning string, so this doesn't actually exist in any deployed contracts,
    // but is useful for backwards-compatible semantics with original version of this library
    bytes32 public constant V0_VERSION_STRING =
        "BytecodeStorage_V0.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V1_VERSION_STRING =
        "BytecodeStorage_V1.0.0_________ ";
    // The first versioned storage contract, deployed by an updated version of this library
    bytes32 public constant V2_VERSION_STRING =
        "BytecodeStorage_V2.0.0_________ ";
    // The current version of this library.
    bytes32 public constant CURRENT_VERSION = V2_VERSION_STRING;

    //---------------------------------------------------------------------------------------------------------------//
    // Starting Index | Size | Ending Index | Description                                                            //
    //---------------------------------------------------------------------------------------------------------------//
    // 0              | N/A  | 0            |                                                                        //
    // 0              | 1    | 1            | single byte opcode for making the storage contract non-executable      //
    // 1              | 32   | 33           | the 32 byte slot used for storing a basic versioning string            //
    // 33             | 32   | 65           | the 32 bytes for storing the deploying contract's (0-padded) address   //
    // 65             | 1    | 66           | single byte indicating if the stored data are compressed               //
    //---------------------------------------------------------------------------------------------------------------//
    // Define the offset for where the "meta bytes" end, and the "data bytes" begin. Note that this is a manually
    // calculated value, and must be updated if the above table is changed. It is expected that tests will fail
    // loudly if these values are not updated in-step with eachother.
    uint256 private constant VERSION_OFFSET = 1;
    uint256 private constant ADDRESS_OFFSET = 33;
    uint256 private constant COMPRESSION_OFFSET = 65;
    uint256 private constant DATA_OFFSET = 66;

    // Define the set of known *historic* offset values for where the "meta bytes" end, and the "data bytes" begin.
    // SSTORE2 deployed storage contracts take the general format of:
    // concat(0x00, data)
    // note: this is true for both variants of the SSTORE2 library
    uint256 private constant SSTORE2_DATA_OFFSET = 1;
    // V0 deployed storage contracts take the general format of:
    // concat(gated-cleanup-logic, deployer-address, data)
    uint256 private constant V0_ADDRESS_OFFSET = 72;
    uint256 private constant V0_DATA_OFFSET = 104;
    // V1 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, data)
    uint256 private constant V1_ADDRESS_OFFSET = 33;
    uint256 private constant V1_DATA_OFFSET = 65;
    // V2 deployed storage contracts take the general format of:
    // concat(invalid opcode, version, deployer-address, compression-bool, data)
    uint256 private constant V2_ADDRESS_OFFSET = ADDRESS_OFFSET;
    uint256 private constant V2_DATA_OFFSET = DATA_OFFSET;

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Read a string from contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 or V2 format
     * @return data string read from contract bytecode
     * @dev This function performs input validation that the contract to read is in an expected format
     */
    function readFromBytecode(
        address _address
    ) public view returns (string memory data) {
        (
            uint256 dataOffset,
            bool isCompressed
        ) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        if (isCompressed) {
            return
                string(
                    LibZip.flzDecompress(
                        readBytesFromBytecode(_address, dataOffset)
                    )
                );
        } else {
            return string(readBytesFromBytecode(_address, dataOffset));
        }
    }

    /**
     * @notice Read the bytes from contract bytecode that was written to the EVM using SSTORE2
     * @param _address address of deployed contract with bytecode stored in the SSTORE2 format
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromSSTORE2Bytecode(
        address _address
    ) public view returns (bytes memory data) {
        return readBytesFromBytecode(_address, SSTORE2_DATA_OFFSET);
    }

    /**
     * @notice Read the bytes from contract bytecode, with an explicitly provided starting offset
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @param _offset offset to read from in contract bytecode, explicitly provided (not calculated)
     * @return data bytes read from contract bytecode
     * @dev This function performs no input validation on the provided contract,
     *      other than that there is content to read (but not that its a "storage contract")
     */
    function readBytesFromBytecode(
        address _address,
        uint256 _offset
    ) public view returns (bytes memory data) {
        // get the size of the bytecode
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < _offset
        if (bytecodeSize < _offset) {
            revert("ContractAsStorage: Read Error");
        }

        // handle case where address contains code >= dataOffset
        // decrement by dataOffset to account for header info
        uint256 size;
        unchecked {
            size = bytecodeSize - _offset;
        }

        assembly {
            // allocate free memory
            data := mload(0x40)
            // update free memory pointer
            // use and(x, not(0x1f) as cheaper equivalent to sub(x, mod(x, 0x20)).
            // adding 0x1f to size + logic above ensures the free memory pointer
            // remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length of data in first 32 bytes
            mstore(data, size)
            // copy code to memory, excluding the deployer-address
            extcodecopy(_address, add(data, 0x20), _offset, size)
        }
    }

    /**
     * @notice Get address for deployer for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return writerAddress address read from contract bytecode
     */
    function getWriterAddressForBytecode(
        address _address
    ) public view returns (address) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // the dataOffset for the bytecode
        uint256 addressOffset = _bytecodeAddressOffsetAt(_address);
        // handle case where address contains code < addressOffset + 32 (address takes a whole slot)
        if (bytecodeSize < (addressOffset + 32)) {
            revert("ContractAsStorage: Read Error");
        }

        assembly {
            // allocate free memory
            let writerAddress := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte address of the data contract writer to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like::
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                writerAddress,
                addressOffset,
                0x20 // full 32-bytes, as address is expected to be zero-padded
            )
            return(
                writerAddress,
                0x20 // return size is entire slot, as it is zero-padded
            )
        }
    }

    /**
     * @notice Get version for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version read from contract bytecode
     */
    function getLibraryVersionForBytecode(
        address _address
    ) public view returns (bytes32) {
        return _bytecodeVersionAt(_address);
    }

    /**
     * @notice Get if data are stored in compressed format for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0, V1, or V2 format
     * @return isCompressed boolean indicating if the stored data are compressed
     */
    function getIsCompressedForBytecode(
        address _address
    ) public view returns (bool) {
        (, bool isCompressed) = _bytecodeDataOffsetAndIsCompressedAt(_address);
        return isCompressed;
    }

    /**
     * Utility function to get the compressed form of a message string using solady LibZip's
     * flz compress algorithm.
     * The compressed message is returned as bytes, which may be used as the input to
     * the function `BytecodeStorageWriter.writeToBytecodeCompressed`.
     * @param _data string to be compressed
     * @return bytes compressed bytes
     */
    function getCompressed(
        string memory _data
    ) public pure returns (bytes memory) {
        return LibZip.flzCompress(bytes(_data));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the size of the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return size size of the bytecode code at `_address`
     */
    function _bytecodeSizeAt(
        address _address
    ) private view returns (uint256 size) {
        assembly {
            size := extcodesize(_address)
        }
        if (size == 0) {
            revert("ContractAsStorage: Read Error");
        }
    }

    /**
     * @notice Returns the offset of the data in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return dataOffset offset of data in bytecode if a known version, otherwise 0
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _bytecodeDataOffsetAndIsCompressedAt(
        address _address
    ) private view returns (uint256 dataOffset, bool isCompressed) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            dataOffset = V2_DATA_OFFSET;
            isCompressed = _isCompressedAt(_address, version);
        } else if (version == V1_VERSION_STRING) {
            dataOffset = V1_DATA_OFFSET;
            // isCompressed remains false, as V1 contracts do not support compression
        } else if (version == V0_VERSION_STRING) {
            dataOffset = V0_DATA_OFFSET;
            // isCompressed remains false, as V0 contracts do not support compression
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Returns the offset of the address in the bytecode at address `_address`
     * @param _address address that may or may not contain bytecode
     * @return addressOffset offset of address in bytecode if a known version, otherwise 0
     */
    function _bytecodeAddressOffsetAt(
        address _address
    ) private view returns (uint256 addressOffset) {
        bytes32 version = _bytecodeVersionAt(_address);
        if (version == V2_VERSION_STRING) {
            addressOffset = V2_ADDRESS_OFFSET;
        } else if (version == V1_VERSION_STRING) {
            addressOffset = V1_ADDRESS_OFFSET;
        } else if (version == V0_VERSION_STRING) {
            addressOffset = V0_ADDRESS_OFFSET;
        } else {
            // unknown version, revert
            revert("ContractAsStorage: Unsupported Version");
        }
    }

    /**
     * @notice Get version string for given contract bytecode
     * @param _address address of deployed contract with bytecode stored in the V0 or V1 format
     * @return version version string read from contract bytecode
     */
    function _bytecodeVersionAt(
        address _address
    ) private view returns (bytes32 version) {
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with the unknown version string
        if (bytecodeSize < (VERSION_OFFSET + 32)) {
            return UNKNOWN_VERSION_STRING;
        }

        assembly {
            // allocate free memory
            let versionString := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // copy the 32-byte version string of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | data |
            extcodecopy(
                _address,
                versionString,
                VERSION_OFFSET,
                0x20 // 32-byte version string
            )
            // note: must check against literal strings, as Yul does not allow for
            //       dynamic strings in switch statements.
            switch mload(versionString)
            case "BytecodeStorage_V2.0.0_________ " {
                version := V2_VERSION_STRING
            }
            case "BytecodeStorage_V1.0.0_________ " {
                version := V1_VERSION_STRING
            }
            case 0x2060486000396000513314601057fe5b60013614601957fe5b6000357fff0000 {
                // the v0 variant of this library pre-dates formal versioning w/ version strings,
                // so we check the first 32 bytes of the execution bytecode itself which
                // is static and known across all storage contracts deployed with the first version
                // of this library.
                version := V0_VERSION_STRING
            }
            default {
                version := UNKNOWN_VERSION_STRING
            }
        }
    }

    /**
     * @notice Get if stored data are compressed for given contract bytecode
     * @param _address address of deployed contract with bytecode stored
     * @param _version version string of the bytecode library used to deploy the contract at `_address`
     * @return isCompressed bool indicating if the stored data are compressed
     */
    function _isCompressedAt(
        address _address,
        bytes32 _version
    ) private view returns (bool isCompressed) {
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version == V0_VERSION_STRING || _version == V1_VERSION_STRING) {
            // V0 and V1 and unknown contracts do not support compression
            return false;
        }
        // @dev if branch no coverage - unreachable as used, remains for redundant safety
        if (_version != V2_VERSION_STRING) {
            // unsupported version, throw error
            revert("ContractAsStorage: Unsupported Version");
        }
        // get the size of the data
        uint256 bytecodeSize = _bytecodeSizeAt(_address);
        // handle case where address contains code < minimum expected version string size,
        // by returning early with false
        if (bytecodeSize < (COMPRESSION_OFFSET + 1)) {
            return false;
        }

        assembly {
            // allocate free memory
            let compressedByte := mload(0x40)
            // shift free memory pointer by one slot
            mstore(0x40, add(mload(0x40), 0x20))
            // zero out word at compressedByte (solidity does not guarantee zeroed memory beyond free memory pointer)
            mstore(compressedByte, 0x00)
            // copy the 1-byte compressed flag of the bytecode library to memory
            // note: this relies on the assumption noted at the top-level of
            //       this file that the storage layout for the deployed
            //       contracts-as-storage contract looks like:
            //       | invalid opcode | version-string (unless v0) | deployer-address (padded) | isCompressed | data |
            extcodecopy(
                _address,
                compressedByte,
                COMPRESSION_OFFSET,
                0x1 // 1-byte version string
            )
            // check if the compressed flag is set
            switch mload(compressedByte)
            case 0x00 {
                isCompressed := false
            }
            default {
                isCompressed := true
            }
        }
    }
}

/**
 * @title Art Blocks Script Storage Library (Internal, Writes)
 * @author Art Blocks Inc.
 * @notice The internal library for writing to storage contracts. This library is intended to be deployed
 *         within library client contracts that use this library to perform _write_ operations on storage.
 */
library BytecodeStorageWriter {
    /*//////////////////////////////////////////////////////////////
                           WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Write a string to contract bytecode
     * @param _data string to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecode(
        string memory _data
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"00",
            // uploaded data (stored as bytecode) comes last
            _data
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }

    /**
     * @notice Write a string to contract bytecode, input as compressed bytes from solady LibZip
     * @param _dataCompressed compressed bytes to be written to contract. No input validation is performed on this parameter.
     * @return address_ address of deployed contract with bytecode stored in the V2 format
     */
    function writeToBytecodeCompressed(
        bytes memory _dataCompressed
    ) internal returns (address address_) {
        // prefix bytecode with
        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // a.) creation code returns all code in the contract except for the first 11 (0B in hex) bytes, as these 11
            //     bytes are the creation code itself which we do not want to store in the deployed storage contract result
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x60_0B            | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xF3    |  0xF3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (11 bytes)
            hex"60_0B_59_81_38_03_80_92_59_39_F3",
            //---------------------------------------------------------------------------------------------------------------//
            // b.) ensure that the deployed storage contract is non-executeable (first opcode is the `invalid` opcode)
            //---------------------------------------------------------------------------------------------------------------//
            //---------------------------------------------------------------------------------------------------------------//
            // 0xFE    |  0xFE               | INVALID      |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"FE",
            //---------------------------------------------------------------------------------------------------------------//
            // c.) store the version string, which is already represented as a 32-byte value
            //---------------------------------------------------------------------------------------------------------------//
            // (32 bytes)
            BytecodeStorageReader.CURRENT_VERSION,
            //---------------------------------------------------------------------------------------------------------------//
            // d.) store the deploying-contract's address with 0-padding to fit a 20-byte address into a 32-byte slot
            //---------------------------------------------------------------------------------------------------------------//
            // (12 bytes)
            hex"00_00_00_00_00_00_00_00_00_00_00_00",
            // (20 bytes)
            address(this),
            //---------------------------------------------------------------------------------------------------------------//
            // e.) store the bool indicating if the data is compressed. true for this function.
            //---------------------------------------------------------------------------------------------------------------//
            // (1 byte)
            hex"01",
            // uploaded compressed data (stored as bytecode) comes last
            _dataCompressed
        );

        assembly {
            // deploy a new contract with the generated creation code.
            // start 32 bytes into creationCode to avoid copying the byte length.
            address_ := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        // address must be non-zero if contract was deployed successfully
        require(address_ != address(0), "ContractAsStorage: Write Error");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for compressing and decompressing bytes.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibZip.sol)
/// @author Calldata compression by clabby (https://github.com/clabby/op-kompressor)
/// @author FastLZ by ariya (https://github.com/ariya/FastLZ)
///
/// @dev Note:
/// The accompanying solady.js library includes implementations of
/// FastLZ and calldata operations for convenience.
library LibZip {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     FAST LZ OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // LZ77 implementation based on FastLZ.
    // Equivalent to level 1 compression and decompression at the following commit:
    // https://github.com/ariya/FastLZ/commit/344eb4025f9ae866ebf7a2ec48850f7113a97a42
    // Decompression is backwards compatible.

    /// @dev Returns the compressed `data`.
    function flzCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function ms8(d_, v_) -> _d {
                mstore8(d_, v_)
                _d := add(d_, 1)
            }
            function u24(p_) -> _u {
                _u := mload(p_)
                _u := or(shl(16, byte(2, _u)), or(shl(8, byte(1, _u)), byte(0, _u)))
            }
            function cmp(p_, q_, e_) -> _l {
                for { e_ := sub(e_, q_) } lt(_l, e_) { _l := add(_l, 1) } {
                    e_ := mul(iszero(byte(0, xor(mload(add(p_, _l)), mload(add(q_, _l))))), e_)
                }
            }
            function literals(runs_, src_, dest_) -> _o {
                for { _o := dest_ } iszero(lt(runs_, 0x20)) { runs_ := sub(runs_, 0x20) } {
                    mstore(ms8(_o, 31), mload(src_))
                    _o := add(_o, 0x21)
                    src_ := add(src_, 0x20)
                }
                if iszero(runs_) { leave }
                mstore(ms8(_o, sub(runs_, 1)), mload(src_))
                _o := add(1, add(_o, runs_))
            }
            function mt(l_, d_, o_) -> _o {
                for { d_ := sub(d_, 1) } iszero(lt(l_, 263)) { l_ := sub(l_, 262) } {
                    o_ := ms8(ms8(ms8(o_, add(224, shr(8, d_))), 253), and(0xff, d_))
                }
                if iszero(lt(l_, 7)) {
                    _o := ms8(ms8(ms8(o_, add(224, shr(8, d_))), sub(l_, 7)), and(0xff, d_))
                    leave
                }
                _o := ms8(ms8(o_, add(shl(5, l_), shr(8, d_))), and(0xff, d_))
            }
            function setHash(i_, v_) {
                let p_ := add(mload(0x40), shl(2, i_))
                mstore(p_, xor(mload(p_), shl(224, xor(shr(224, mload(p_)), v_))))
            }
            function getHash(i_) -> _h {
                _h := shr(224, mload(add(mload(0x40), shl(2, i_))))
            }
            function hash(v_) -> _r {
                _r := and(shr(19, mul(2654435769, v_)), 0x1fff)
            }
            function setNextHash(ip_, ipStart_) -> _ip {
                setHash(hash(u24(ip_)), sub(ip_, ipStart_))
                _ip := add(ip_, 1)
            }
            result := mload(0x40)
            codecopy(result, codesize(), 0x8000) // Zeroize the hashmap.
            let op := add(result, 0x8000)
            let a := add(data, 0x20)
            let ipStart := a
            let ipLimit := sub(add(ipStart, mload(data)), 13)
            for { let ip := add(2, a) } lt(ip, ipLimit) {} {
                let r := 0
                let d := 0
                for {} 1 {} {
                    let s := u24(ip)
                    let h := hash(s)
                    r := add(ipStart, getHash(h))
                    setHash(h, sub(ip, ipStart))
                    d := sub(ip, r)
                    if iszero(lt(ip, ipLimit)) { break }
                    ip := add(ip, 1)
                    if iszero(gt(d, 0x1fff)) { if eq(s, u24(r)) { break } }
                }
                if iszero(lt(ip, ipLimit)) { break }
                ip := sub(ip, 1)
                if gt(ip, a) { op := literals(sub(ip, a), a, op) }
                let l := cmp(add(r, 3), add(ip, 3), add(ipLimit, 9))
                op := mt(l, d, op)
                ip := setNextHash(setNextHash(add(ip, l), ipStart), ipStart)
                a := ip
            }
            // Copy the result to compact the memory, overwriting the hashmap.
            let end := sub(literals(sub(add(ipStart, mload(data)), a), a, op), 0x7fe0)
            let o := add(result, 0x20)
            mstore(result, sub(end, o)) // Store the length.
            for {} iszero(gt(o, end)) { o := add(o, 0x20) } { mstore(o, mload(add(o, 0x7fe0))) }
            mstore(end, 0) // Zeroize the slot after the string.
            mstore(0x40, add(end, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function flzDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let op := add(result, 0x20)
            let end := add(add(data, 0x20), mload(data))
            for { data := add(data, 0x20) } lt(data, end) {} {
                let w := mload(data)
                let c := byte(0, w)
                let t := shr(5, c)
                if iszero(t) {
                    mstore(op, mload(add(data, 1)))
                    data := add(data, add(2, c))
                    op := add(op, add(1, c))
                    continue
                }
                for {
                    let g := eq(t, 7)
                    let l := add(2, xor(t, mul(g, xor(t, add(7, byte(1, w)))))) // M
                    let s := add(add(shl(8, and(0x1f, c)), byte(add(1, g), w)), 1) // R
                    let r := sub(op, s)
                    let f := xor(s, mul(gt(s, 0x20), xor(s, 0x20)))
                    let j := 0
                } 1 {} {
                    mstore(add(op, j), mload(add(r, j)))
                    j := add(j, f)
                    if lt(j, l) { continue }
                    data := add(data, add(2, g))
                    op := add(op, l)
                    break
                }
            }
            mstore(result, sub(op, add(result, 0x20))) // Store the length.
            mstore(op, 0) // Zeroize the slot after the string.
            mstore(0x40, add(op, 0x20)) // Allocate the memory.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    CALLDATA OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Calldata compression and decompression using selective run length encoding:
    // - Sequences of 0x00 (up to 128 consecutive).
    // - Sequences of 0xff (up to 32 consecutive).
    //
    // A run length encoded block consists of two bytes:
    // (0) 0x00
    // (1) A control byte with the following bit layout:
    //     - [7]     `0: 0x00, 1: 0xff`.
    //     - [0..6]  `runLength - 1`.
    //
    // The first 4 bytes are bitwise negated so that the compressed calldata
    // can be dispatched into the `fallback` and `receive` functions.

    /// @dev Returns the compressed `data`.
    function cdCompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            function rle(v_, o_, d_) -> _o, _d {
                mstore(o_, shl(240, or(and(0xff, add(d_, 0xff)), and(0x80, v_))))
                _o := add(o_, 2)
            }
            result := mload(0x40)
            let o := add(result, 0x20)
            let z := 0 // Number of consecutive 0x00.
            let y := 0 // Number of consecutive 0xff.
            for { let end := add(data, mload(data)) } iszero(eq(data, end)) {} {
                data := add(data, 1)
                let c := byte(31, mload(data))
                if iszero(c) {
                    if y { o, y := rle(0xff, o, y) }
                    z := add(z, 1)
                    if eq(z, 0x80) { o, z := rle(0x00, o, 0x80) }
                    continue
                }
                if eq(c, 0xff) {
                    if z { o, z := rle(0x00, o, z) }
                    y := add(y, 1)
                    if eq(y, 0x20) { o, y := rle(0xff, o, 0x20) }
                    continue
                }
                if y { o, y := rle(0xff, o, y) }
                if z { o, z := rle(0x00, o, z) }
                mstore8(o, c)
                o := add(o, 1)
            }
            if y { o, y := rle(0xff, o, y) }
            if z { o, z := rle(0x00, o, z) }
            // Bitwise negate the first 4 bytes.
            mstore(add(result, 4), not(mload(add(result, 4))))
            mstore(result, sub(o, add(result, 0x20))) // Store the length.
            mstore(o, 0) // Zeroize the slot after the string.
            mstore(0x40, add(o, 0x20)) // Allocate the memory.
        }
    }

    /// @dev Returns the decompressed `data`.
    function cdDecompress(bytes memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(data) {
                result := mload(0x40)
                let o := add(result, 0x20)
                let s := add(data, 4)
                let v := mload(s)
                let end := add(data, mload(data))
                mstore(s, not(v)) // Bitwise negate the first 4 bytes.
                for {} lt(data, end) {} {
                    data := add(data, 1)
                    let c := byte(31, mload(data))
                    if iszero(c) {
                        data := add(data, 1)
                        let d := byte(31, mload(data))
                        // Fill with either 0xff or 0x00.
                        mstore(o, not(0))
                        if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                        o := add(o, add(and(d, 0x7f), 1))
                        continue
                    }
                    mstore8(o, c)
                    o := add(o, 1)
                }
                mstore(s, v) // Restore the first 4 bytes.
                mstore(result, sub(o, add(result, 0x20))) // Store the length.
                mstore(o, 0) // Zeroize the slot after the string.
                mstore(0x40, add(o, 0x20)) // Allocate the memory.
            }
        }
    }

    /// @dev To be called in the `fallback` function.
    /// ```
    ///     fallback() external payable { LibZip.cdFallback(); }
    ///     receive() external payable {} // Silence compiler warning to add a `receive` function.
    /// ```
    /// For efficiency, this function will directly return the results, terminating the context.
    /// If called internally, it must be called at the end of the function.
    function cdFallback() internal {
        assembly {
            if iszero(calldatasize()) { return(calldatasize(), calldatasize()) }
            let o := 0
            let f := not(3) // For negating the first 4 bytes.
            for { let i := 0 } lt(i, calldatasize()) {} {
                let c := byte(0, xor(add(i, f), calldataload(i)))
                i := add(i, 1)
                if iszero(c) {
                    let d := byte(0, xor(add(i, f), calldataload(i)))
                    i := add(i, 1)
                    // Fill with either 0xff or 0x00.
                    mstore(o, not(0))
                    if iszero(gt(d, 0x7f)) { codecopy(o, codesize(), add(d, 1)) }
                    o := add(o, add(and(d, 0x7f), 1))
                    continue
                }
                mstore8(o, c)
                o := add(o, 1)
            }
            let success := delegatecall(gas(), address(), 0x00, o, codesize(), 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(success) { revert(0x00, returndatasize()) }
            return(0x00, returndatasize())
        }
    }
}