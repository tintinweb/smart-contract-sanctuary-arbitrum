// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

using { getStaticByteLength } for SchemaType global;

// WARNING: All enum changes MUST be mirrored for the other languages!
// WARNING: SchemaType methods use hardcoded enum indexes, review them after any changes to the enum
// TODO add and implement BYTES_ARRAY, STRING_ARRAY if they are needed (see https://github.com/latticexyz/mud/issues/447)
enum SchemaType {
  UINT8,
  UINT16,
  UINT24,
  UINT32,
  UINT40,
  UINT48,
  UINT56,
  UINT64,
  UINT72,
  UINT80,
  UINT88,
  UINT96,
  UINT104,
  UINT112,
  UINT120,
  UINT128,
  UINT136,
  UINT144,
  UINT152,
  UINT160,
  UINT168,
  UINT176,
  UINT184,
  UINT192,
  UINT200,
  UINT208,
  UINT216,
  UINT224,
  UINT232,
  UINT240,
  UINT248,
  UINT256,
  INT8,
  INT16,
  INT24,
  INT32,
  INT40,
  INT48,
  INT56,
  INT64,
  INT72,
  INT80,
  INT88,
  INT96,
  INT104,
  INT112,
  INT120,
  INT128,
  INT136,
  INT144,
  INT152,
  INT160,
  INT168,
  INT176,
  INT184,
  INT192,
  INT200,
  INT208,
  INT216,
  INT224,
  INT232,
  INT240,
  INT248,
  INT256,
  BYTES1,
  BYTES2,
  BYTES3,
  BYTES4,
  BYTES5,
  BYTES6,
  BYTES7,
  BYTES8,
  BYTES9,
  BYTES10,
  BYTES11,
  BYTES12,
  BYTES13,
  BYTES14,
  BYTES15,
  BYTES16,
  BYTES17,
  BYTES18,
  BYTES19,
  BYTES20,
  BYTES21,
  BYTES22,
  BYTES23,
  BYTES24,
  BYTES25,
  BYTES26,
  BYTES27,
  BYTES28,
  BYTES29,
  BYTES30,
  BYTES31,
  BYTES32,
  BOOL,
  ADDRESS,
  UINT8_ARRAY,
  UINT16_ARRAY,
  UINT24_ARRAY,
  UINT32_ARRAY,
  UINT40_ARRAY,
  UINT48_ARRAY,
  UINT56_ARRAY,
  UINT64_ARRAY,
  UINT72_ARRAY,
  UINT80_ARRAY,
  UINT88_ARRAY,
  UINT96_ARRAY,
  UINT104_ARRAY,
  UINT112_ARRAY,
  UINT120_ARRAY,
  UINT128_ARRAY,
  UINT136_ARRAY,
  UINT144_ARRAY,
  UINT152_ARRAY,
  UINT160_ARRAY,
  UINT168_ARRAY,
  UINT176_ARRAY,
  UINT184_ARRAY,
  UINT192_ARRAY,
  UINT200_ARRAY,
  UINT208_ARRAY,
  UINT216_ARRAY,
  UINT224_ARRAY,
  UINT232_ARRAY,
  UINT240_ARRAY,
  UINT248_ARRAY,
  UINT256_ARRAY,
  INT8_ARRAY,
  INT16_ARRAY,
  INT24_ARRAY,
  INT32_ARRAY,
  INT40_ARRAY,
  INT48_ARRAY,
  INT56_ARRAY,
  INT64_ARRAY,
  INT72_ARRAY,
  INT80_ARRAY,
  INT88_ARRAY,
  INT96_ARRAY,
  INT104_ARRAY,
  INT112_ARRAY,
  INT120_ARRAY,
  INT128_ARRAY,
  INT136_ARRAY,
  INT144_ARRAY,
  INT152_ARRAY,
  INT160_ARRAY,
  INT168_ARRAY,
  INT176_ARRAY,
  INT184_ARRAY,
  INT192_ARRAY,
  INT200_ARRAY,
  INT208_ARRAY,
  INT216_ARRAY,
  INT224_ARRAY,
  INT232_ARRAY,
  INT240_ARRAY,
  INT248_ARRAY,
  INT256_ARRAY,
  BYTES1_ARRAY,
  BYTES2_ARRAY,
  BYTES3_ARRAY,
  BYTES4_ARRAY,
  BYTES5_ARRAY,
  BYTES6_ARRAY,
  BYTES7_ARRAY,
  BYTES8_ARRAY,
  BYTES9_ARRAY,
  BYTES10_ARRAY,
  BYTES11_ARRAY,
  BYTES12_ARRAY,
  BYTES13_ARRAY,
  BYTES14_ARRAY,
  BYTES15_ARRAY,
  BYTES16_ARRAY,
  BYTES17_ARRAY,
  BYTES18_ARRAY,
  BYTES19_ARRAY,
  BYTES20_ARRAY,
  BYTES21_ARRAY,
  BYTES22_ARRAY,
  BYTES23_ARRAY,
  BYTES24_ARRAY,
  BYTES25_ARRAY,
  BYTES26_ARRAY,
  BYTES27_ARRAY,
  BYTES28_ARRAY,
  BYTES29_ARRAY,
  BYTES30_ARRAY,
  BYTES31_ARRAY,
  BYTES32_ARRAY,
  BOOL_ARRAY,
  ADDRESS_ARRAY,
  BYTES,
  STRING
}

/**
 * Get the length of the data for the given schema type
 * (Because Solidity doesn't support constant arrays, we need to use a function)
 */
function getStaticByteLength(SchemaType schemaType) pure returns (uint256) {
  uint256 index = uint8(schemaType);

  if (index < 97) {
    // SchemaType enum elements are cyclically ordered for optimal static length lookup
    // indexes: 00-31, 32-63, 64-95, 96, 97, ...
    // lengths: 01-32, 01-32, 01-32, 01, 20, (the rest are 0s)
    unchecked {
      return (index & 31) + 1;
    }
  } else if (schemaType == SchemaType.ADDRESS) {
    return 20;
  } else {
    // Return 0 for all dynamic types
    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Bytes
 * @notice Utility functions for bytes.
 */
library Bytes {
  /**
   * @dev Converts a `bytes` memory blob to a single `bytes32` memory value, starting at the given byte offset.
   * @param input The `bytes` blob to read from.
   * @param offset The byte offset at which to start reading.
   * @return output The `bytes32` value.
   */
  function toBytes32(bytes memory input, uint256 offset) internal pure returns (bytes32 output) {
    assembly {
      // input is a pointer to the start of the bytes array
      // in memory, the first 32 bytes are the length of the array
      // so we add 32 to the pointer to get to the start of the data
      // then we add the start offset to get to the start of the desired word
      output := mload(add(input, add(0x20, offset)))
    }
  }

  /************************************************************************
   *
   *    UTILS
   *
   ************************************************************************/

  /**
   * @dev Compares two bytes blobs for equality.
   * @param a First bytes blob.
   * @param b Second bytes blob.
   * @return True if the two bytes blobs are equal, false otherwise.
   */
  function equals(bytes memory a, bytes memory b) internal pure returns (bool) {
    if (a.length != b.length) {
      return false;
    }
    return keccak256(a) == keccak256(b);
  }

  /**
   * @dev Sets the length of a bytes blob in memory.
   * This function does not resize the memory allocation; it only changes the length
   * field, which affects operations that access the length property.
   * @param input The bytes blob to modify.
   * @param length The new length to set.
   * @return Reference to the input bytes blob with modified length.
   */
  function setLength(bytes memory input, uint256 length) internal pure returns (bytes memory) {
    assembly {
      mstore(input, length)
    }
    return input;
  }

  /************************************************************************
   *
   *    SET
   *
   ************************************************************************/

  /**
   * @dev Sets a specific byte in a bytes32 value.
   * @param input The bytes32 data in which a specific byte is to be altered.
   * @param index The position of the byte to be altered. Index starts from the left.
   * @param overwrite The new byte value to be set at the specified index.
   * @return output The modified bytes32 data with the new byte value at the specified index.
   */
  function setBytes1(bytes32 input, uint256 index, bytes1 overwrite) internal pure returns (bytes32 output) {
    bytes1 mask = 0xff;
    assembly {
      mask := shr(mul(8, index), mask) // create a mask by shifting 0xff right by index bytes
      output := and(input, not(mask)) // zero out the byte at index
      output := or(output, shr(mul(8, index), overwrite)) // set the byte at index
    }
    return output;
  }

  /**
   * @dev Sets a specific 2-byte sequence in a bytes32 variable.
   * @param input The bytes32 data in which a specific 2-byte sequence is to be altered.
   * @param index The position of the 2-byte sequence to be altered. Index starts from the left.
   * @param overwrite The new 2-byte value to be set at the specified index.
   * @return output The modified bytes32 data with the new 2-byte value at the specified index.
   */
  function setBytes2(bytes32 input, uint256 index, bytes2 overwrite) internal pure returns (bytes32 output) {
    bytes2 mask = 0xffff;
    assembly {
      mask := shr(mul(8, index), mask) // create a mask by shifting 0xffff right by index bytes
      output := and(input, not(mask)) // zero out the byte at index
      output := or(output, shr(mul(8, index), overwrite)) // set the byte at index
    }
    return output;
  }

  /**
   * @dev Sets a specific 4-byte sequence in a bytes32 variable.
   * @param input The bytes32 data in which a specific 4-byte sequence is to be altered.
   * @param index The position of the 4-byte sequence to be altered. Index starts from the left.
   * @param overwrite The new 4-byte value to be set at the specified index.
   * @return output The modified bytes32 data with the new 4-byte value at the specified index.
   */
  function setBytes4(bytes32 input, uint256 index, bytes4 overwrite) internal pure returns (bytes32 output) {
    bytes4 mask = 0xffffffff;
    assembly {
      mask := shr(mul(8, index), mask) // create a mask by shifting 0xffffffff right by index bytes
      output := and(input, not(mask)) // zero out the byte at index
      output := or(output, shr(mul(8, index), overwrite)) // set the byte at index
    }
    return output;
  }

  /**
   * @dev Sets a specific 4-byte sequence in a bytes blob at a given index.
   * @param input The bytes blob in which a specific 4-byte sequence is to be altered.
   * @param index The position within the bytes blob to start altering the 4-byte sequence. Index starts from the left.
   * @param overwrite The new 4-byte value to be set at the specified index.
   * @return The modified bytes blob with the new 4-byte value at the specified index.
   */
  function setBytes4(bytes memory input, uint256 index, bytes4 overwrite) internal pure returns (bytes memory) {
    bytes4 mask = 0xffffffff;
    assembly {
      let value := mload(add(add(input, 0x20), index)) // load 32 bytes from input starting at offset
      value := and(value, not(mask)) // zero out the first 4 bytes
      value := or(value, overwrite) // set the bytes at the offset
      mstore(add(add(input, 0x20), index), value) // store the new value
    }
    return input;
  }

  /**
   * @dev Sets a specific 5-byte sequence in a bytes32 variable.
   * @param input The bytes32 data in which a specific 5-byte sequence is to be altered.
   * @param index The position of the 5-byte sequence to be altered. Index starts from the left.
   * @param overwrite The new 5-byte value to be set at the specified index.
   * @return output The modified bytes32 data with the new 5-byte value at the specified index.
   */
  function setBytes5(bytes32 input, uint256 index, bytes5 overwrite) internal pure returns (bytes32 output) {
    bytes5 mask = bytes5(type(uint40).max);
    assembly {
      mask := shr(mul(8, index), mask) // create a mask by shifting 0xff...ff right by index bytes
      output := and(input, not(mask)) // zero out the byte at index
      output := or(output, shr(mul(8, index), overwrite)) // set the byte at index
    }
    return output;
  }

  /**
   * @dev Sets a specific 7-byte sequence in a bytes32 variable.
   * @param input The bytes32 data in which a specific 7-byte sequence is to be altered.
   * @param index The position of the 7-byte sequence to be altered. Index starts from the left.
   * @param overwrite The new 7-byte value to be set at the specified index.
   * @return output The modified bytes32 data with the new 7-byte value at the specified index.
   */
  function setBytes7(bytes32 input, uint256 index, bytes7 overwrite) internal pure returns (bytes32 output) {
    bytes7 mask = bytes7(type(uint56).max);
    assembly {
      mask := shr(mul(8, index), mask) // create a mask by shifting 0xff...ff right by index bytes
      output := and(input, not(mask)) // zero out the byte at index
      output := or(output, shr(mul(8, index), overwrite)) // set the byte at index
    }
    return output;
  }

  /************************************************************************
   *
   *    SLICE
   *
   ************************************************************************/

  /**
   * @dev Extracts a single byte from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a byte is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes1 value from the specified position in the bytes blob.
   */
  function slice1(bytes memory data, uint256 start) internal pure returns (bytes1) {
    bytes1 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a single byte from a bytes32 value starting at a specific position.
   * @param data The bytes32 value from which a byte is to be extracted.
   * @param start The starting position within the bytes32 value for extraction.
   * @return The extracted bytes1 value from the specified position in the bytes32 value.
   */
  function slice1(bytes32 data, uint256 start) internal pure returns (bytes1) {
    bytes1 output;
    assembly {
      output := shl(mul(8, start), data)
    }
    return output;
  }

  /**
   * @dev Extracts a 2-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 2-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes2 value from the specified position in the bytes blob.
   */
  function slice2(bytes memory data, uint256 start) internal pure returns (bytes2) {
    bytes2 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 2-byte sequence from a bytes32 value starting at a specific position.
   * @param data The bytes32 value from which a 2-byte sequence is to be extracted.
   * @param start The starting position within the bytes32 value for extraction.
   * @return The extracted bytes2 value from the specified position in the bytes32 value.
   */
  function slice2(bytes32 data, uint256 start) internal pure returns (bytes2) {
    bytes2 output;
    assembly {
      output := shl(mul(8, start), data)
    }
    return output;
  }

  /**
   * @dev Extracts a 3-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 3-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes3 value from the specified position in the bytes blob.
   */
  function slice3(bytes memory data, uint256 start) internal pure returns (bytes3) {
    bytes3 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 4-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 4-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes4 value from the specified position in the bytes blob.
   */
  function slice4(bytes memory data, uint256 start) internal pure returns (bytes4) {
    bytes4 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 4-byte sequence from a bytes32 value starting at a specific position.
   * @param data The bytes32 value from which a 4-byte sequence is to be extracted.
   * @param start The starting position within the bytes32 value for extraction.
   * @return The extracted bytes4 value from the specified position in the bytes32 value.
   */
  function slice4(bytes32 data, uint256 start) internal pure returns (bytes4) {
    bytes2 output;
    assembly {
      output := shl(mul(8, start), data)
    }
    return output;
  }

  /**
   * @dev Extracts a 5-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 5-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes5 value from the specified position in the bytes blob.
   */
  function slice5(bytes memory data, uint256 start) internal pure returns (bytes5) {
    bytes5 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 5-byte sequence from a bytes32 value starting at a specific position.
   * @param data The bytes32 value from which a 5-byte sequence is to be extracted.
   * @param start The starting position within the bytes32 value for extraction.
   * @return The extracted bytes5 value from the specified position in the bytes32 value.
   */
  function slice5(bytes32 data, uint256 start) internal pure returns (bytes5) {
    bytes5 output;
    assembly {
      output := shl(mul(8, start), data)
    }
    return output;
  }

  /**
   * @dev Extracts a 6-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 6-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes6 value from the specified position in the bytes blob.
   */
  function slice6(bytes memory data, uint256 start) internal pure returns (bytes6) {
    bytes6 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 7-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 7-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes7 value from the specified position in the bytes blob.
   */
  function slice7(bytes memory data, uint256 start) internal pure returns (bytes7) {
    bytes7 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 8-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 8-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes8 value from the specified position in the bytes blob.
   */
  function slice8(bytes memory data, uint256 start) internal pure returns (bytes8) {
    bytes8 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 9-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 9-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes9 value from the specified position in the bytes blob.
   */
  function slice9(bytes memory data, uint256 start) internal pure returns (bytes9) {
    bytes9 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 10-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 10-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes10 value from the specified position in the bytes blob.
   */
  function slice10(bytes memory data, uint256 start) internal pure returns (bytes10) {
    bytes10 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 11-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 11-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes11 value from the specified position in the bytes blob.
   */
  function slice11(bytes memory data, uint256 start) internal pure returns (bytes11) {
    bytes11 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 12-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 12-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes12 value from the specified position in the bytes blob.
   */
  function slice12(bytes memory data, uint256 start) internal pure returns (bytes12) {
    bytes12 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 13-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 13-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes13 value from the specified position in the bytes blob.
   */
  function slice13(bytes memory data, uint256 start) internal pure returns (bytes13) {
    bytes13 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 14-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 14-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes14 value from the specified position in the bytes blob.
   */
  function slice14(bytes memory data, uint256 start) internal pure returns (bytes14) {
    bytes14 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 15-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 15-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes15 value from the specified position in the bytes blob.
   */
  function slice15(bytes memory data, uint256 start) internal pure returns (bytes15) {
    bytes15 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 16-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 16-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes16 value from the specified position in the bytes blob.
   */
  function slice16(bytes memory data, uint256 start) internal pure returns (bytes16) {
    bytes16 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 17-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 17-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes17 value from the specified position in the bytes blob.
   */
  function slice17(bytes memory data, uint256 start) internal pure returns (bytes17) {
    bytes17 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 18-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 18-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes18 value from the specified position in the bytes blob.
   */
  function slice18(bytes memory data, uint256 start) internal pure returns (bytes18) {
    bytes18 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 19-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 19-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes19 value from the specified position in the bytes blob.
   */
  function slice19(bytes memory data, uint256 start) internal pure returns (bytes19) {
    bytes19 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 20-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 20-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes20 value from the specified position in the bytes blob.
   */
  function slice20(bytes memory data, uint256 start) internal pure returns (bytes20) {
    bytes20 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 21-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 21-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes21 value from the specified position in the bytes blob.
   */
  function slice21(bytes memory data, uint256 start) internal pure returns (bytes21) {
    bytes21 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 22-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 22-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes22 value from the specified position in the bytes blob.
   */
  function slice22(bytes memory data, uint256 start) internal pure returns (bytes22) {
    bytes22 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 23-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 23-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes23 value from the specified position in the bytes blob.
   */
  function slice23(bytes memory data, uint256 start) internal pure returns (bytes23) {
    bytes23 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 24-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 24-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes24 value from the specified position in the bytes blob.
   */
  function slice24(bytes memory data, uint256 start) internal pure returns (bytes24) {
    bytes24 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 25-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 25-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes25 value from the specified position in the bytes blob.
   */
  function slice25(bytes memory data, uint256 start) internal pure returns (bytes25) {
    bytes25 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 26-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 26-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes26 value from the specified position in the bytes blob.
   */
  function slice26(bytes memory data, uint256 start) internal pure returns (bytes26) {
    bytes26 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 27-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 27-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes27 value from the specified position in the bytes blob.
   */
  function slice27(bytes memory data, uint256 start) internal pure returns (bytes27) {
    bytes27 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 28-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 28-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes28 value from the specified position in the bytes blob.
   */
  function slice28(bytes memory data, uint256 start) internal pure returns (bytes28) {
    bytes28 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 29-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 29-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes29 value from the specified position in the bytes blob.
   */
  function slice29(bytes memory data, uint256 start) internal pure returns (bytes29) {
    bytes29 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 30-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 30-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes30 value from the specified position in the bytes blob.
   */
  function slice30(bytes memory data, uint256 start) internal pure returns (bytes30) {
    bytes30 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 31-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 31-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes31 value from the specified position in the bytes blob.
   */
  function slice31(bytes memory data, uint256 start) internal pure returns (bytes31) {
    bytes31 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }

  /**
   * @dev Extracts a 32-byte sequence from a bytes blob starting at a specific position.
   * @param data The bytes blob from which a 32-byte sequence is to be extracted.
   * @param start The starting position within the bytes blob for extraction.
   * @return The extracted bytes32 value from the specified position in the bytes blob.
   */
  function slice32(bytes memory data, uint256 start) internal pure returns (bytes32) {
    bytes32 output;
    assembly {
      output := mload(add(add(data, 0x20), start))
    }
    return output;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { StoreHooks, StoreHooksTableId } from "./tables/StoreHooks.sol";
import { Tables, TablesData, TablesTableId } from "./tables/Tables.sol";
import { ResourceIds, ResourceIdsTableId } from "./tables/ResourceIds.sol";
import { Hooks } from "./tables/Hooks.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "../../IStore.sol";
import { StoreSwitch } from "../../StoreSwitch.sol";
import { StoreCore } from "../../StoreCore.sol";
import { Bytes } from "../../Bytes.sol";
import { Memory } from "../../Memory.sol";
import { SliceLib } from "../../Slice.sol";
import { EncodeArray } from "../../tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "../../FieldLayout.sol";
import { Schema, SchemaLib } from "../../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../../PackedCounter.sol";
import { ResourceId } from "../../ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "../../storeResourceTypes.sol";

// Import user types
import { ResourceId } from "./../../ResourceId.sol";

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0000000100000000000000000000000000000000000000000000000000000000
);

library Hooks {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](1);
    _valueSchema[0] = SchemaType.BYTES21_ARRAY;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "resourceId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "hooks";
  }

  /**
   * @notice Register the table with its config.
   */
  function register(ResourceId _tableId) internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register(ResourceId _tableId) internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get hooks.
   */
  function getHooks(ResourceId _tableId, ResourceId resourceId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function _getHooks(ResourceId _tableId, ResourceId resourceId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function get(ResourceId _tableId, ResourceId resourceId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function _get(ResourceId _tableId, ResourceId resourceId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Set hooks.
   */
  function setHooks(ResourceId _tableId, ResourceId resourceId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function _setHooks(ResourceId _tableId, ResourceId resourceId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function set(ResourceId _tableId, ResourceId resourceId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function _set(ResourceId _tableId, ResourceId resourceId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Get the length of hooks.
   */
  function lengthHooks(ResourceId _tableId, ResourceId resourceId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function _lengthHooks(ResourceId _tableId, ResourceId resourceId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function length(ResourceId _tableId, ResourceId resourceId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function _length(ResourceId _tableId, ResourceId resourceId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemHooks(ResourceId _tableId, ResourceId resourceId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemHooks(ResourceId _tableId, ResourceId resourceId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(ResourceId _tableId, ResourceId resourceId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItem(ResourceId _tableId, ResourceId resourceId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Push an element to hooks.
   */
  function pushHooks(ResourceId _tableId, ResourceId resourceId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function _pushHooks(ResourceId _tableId, ResourceId resourceId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function push(ResourceId _tableId, ResourceId resourceId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function _push(ResourceId _tableId, ResourceId resourceId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from hooks.
   */
  function popHooks(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function _popHooks(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function pop(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function _pop(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function updateHooks(ResourceId _tableId, ResourceId resourceId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function _updateHooks(ResourceId _tableId, ResourceId resourceId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function update(ResourceId _tableId, ResourceId resourceId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function _update(ResourceId _tableId, ResourceId resourceId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(ResourceId _tableId, ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes21[] memory hooks) internal pure returns (PackedCounter _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = PackedCounterLib.pack(hooks.length * 21);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes21[] memory hooks) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((hooks)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(bytes21[] memory hooks) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData;
    PackedCounter _encodedLengths = encodeLengths(hooks);
    bytes memory _dynamicData = encodeDynamic(hooks);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(ResourceId resourceId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "../../IStore.sol";
import { StoreSwitch } from "../../StoreSwitch.sol";
import { StoreCore } from "../../StoreCore.sol";
import { Bytes } from "../../Bytes.sol";
import { Memory } from "../../Memory.sol";
import { SliceLib } from "../../Slice.sol";
import { EncodeArray } from "../../tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "../../FieldLayout.sol";
import { Schema, SchemaLib } from "../../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../../PackedCounter.sol";
import { ResourceId } from "../../ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "../../storeResourceTypes.sol";

// Import user types
import { ResourceId } from "./../../ResourceId.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14("store"), bytes16("ResourceIds")))
);
ResourceId constant ResourceIdsTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0001010001000000000000000000000000000000000000000000000000000000
);

library ResourceIds {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](1);
    _valueSchema[0] = SchemaType.BOOL;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "resourceId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "exists";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get exists.
   */
  function getExists(ResourceId resourceId) internal view returns (bool exists) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get exists.
   */
  function _getExists(ResourceId resourceId) internal view returns (bool exists) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get exists.
   */
  function get(ResourceId resourceId) internal view returns (bool exists) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Get exists.
   */
  function _get(ResourceId resourceId) internal view returns (bool exists) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (_toBool(uint8(bytes1(_blob))));
  }

  /**
   * @notice Set exists.
   */
  function setExists(ResourceId resourceId, bool exists) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((exists)), _fieldLayout);
  }

  /**
   * @notice Set exists.
   */
  function _setExists(ResourceId resourceId, bool exists) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((exists)), _fieldLayout);
  }

  /**
   * @notice Set exists.
   */
  function set(ResourceId resourceId, bool exists) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((exists)), _fieldLayout);
  }

  /**
   * @notice Set exists.
   */
  function _set(ResourceId resourceId, bool exists) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((exists)), _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(ResourceId resourceId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(bool exists) internal pure returns (bytes memory) {
    return abi.encodePacked(exists);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(bool exists) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(exists);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(ResourceId resourceId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(resourceId);

    return _keyTuple;
  }
}

/**
 * @notice Cast a value to a bool.
 * @dev Boolean values are encoded as uint8 (1 = true, 0 = false), but Solidity doesn't allow casting between uint8 and bool.
 * @param value The uint8 value to convert.
 * @return result The boolean value.
 */
function _toBool(uint8 value) pure returns (bool result) {
  assembly {
    result := value
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "../../IStore.sol";
import { StoreSwitch } from "../../StoreSwitch.sol";
import { StoreCore } from "../../StoreCore.sol";
import { Bytes } from "../../Bytes.sol";
import { Memory } from "../../Memory.sol";
import { SliceLib } from "../../Slice.sol";
import { EncodeArray } from "../../tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "../../FieldLayout.sol";
import { Schema, SchemaLib } from "../../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../../PackedCounter.sol";
import { ResourceId } from "../../ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "../../storeResourceTypes.sol";

// Import user types
import { ResourceId } from "./../../ResourceId.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14("store"), bytes16("StoreHooks")))
);
ResourceId constant StoreHooksTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0000000100000000000000000000000000000000000000000000000000000000
);

library StoreHooks {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](1);
    _valueSchema[0] = SchemaType.BYTES21_ARRAY;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "tableId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "hooks";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get hooks.
   */
  function getHooks(ResourceId tableId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function _getHooks(ResourceId tableId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function get(ResourceId tableId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Get hooks.
   */
  function _get(ResourceId tableId) internal view returns (bytes21[] memory hooks) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (SliceLib.getSubslice(_blob, 0, _blob.length).decodeArray_bytes21());
  }

  /**
   * @notice Set hooks.
   */
  function setHooks(ResourceId tableId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function _setHooks(ResourceId tableId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function set(ResourceId tableId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Set hooks.
   */
  function _set(ResourceId tableId, bytes21[] memory hooks) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, EncodeArray.encode((hooks)));
  }

  /**
   * @notice Get the length of hooks.
   */
  function lengthHooks(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function _lengthHooks(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function length(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get the length of hooks.
   */
  function _length(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 21;
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemHooks(ResourceId tableId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemHooks(ResourceId tableId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItem(ResourceId tableId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Get an item of hooks.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItem(ResourceId tableId, uint256 _index) internal view returns (bytes21) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 21, (_index + 1) * 21);
      return (bytes21(_blob));
    }
  }

  /**
   * @notice Push an element to hooks.
   */
  function pushHooks(ResourceId tableId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function _pushHooks(ResourceId tableId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function push(ResourceId tableId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Push an element to hooks.
   */
  function _push(ResourceId tableId, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, abi.encodePacked((_element)));
  }

  /**
   * @notice Pop an element from hooks.
   */
  function popHooks(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function _popHooks(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function pop(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Pop an element from hooks.
   */
  function _pop(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 21);
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function updateHooks(ResourceId tableId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function _updateHooks(ResourceId tableId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function update(ResourceId tableId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update an element of hooks at `_index`.
   */
  function _update(ResourceId tableId, uint256 _index, bytes21 _element) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = abi.encodePacked((_element));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 21), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(bytes21[] memory hooks) internal pure returns (PackedCounter _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = PackedCounterLib.pack(hooks.length * 21);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(bytes21[] memory hooks) internal pure returns (bytes memory) {
    return abi.encodePacked(EncodeArray.encode((hooks)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(bytes21[] memory hooks) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData;
    PackedCounter _encodedLengths = encodeLengths(hooks);
    bytes memory _dynamicData = encodeDynamic(hooks);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(ResourceId tableId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "../../IStore.sol";
import { StoreSwitch } from "../../StoreSwitch.sol";
import { StoreCore } from "../../StoreCore.sol";
import { Bytes } from "../../Bytes.sol";
import { Memory } from "../../Memory.sol";
import { SliceLib } from "../../Slice.sol";
import { EncodeArray } from "../../tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "../../FieldLayout.sol";
import { Schema, SchemaLib } from "../../Schema.sol";
import { PackedCounter, PackedCounterLib } from "../../PackedCounter.sol";
import { ResourceId } from "../../ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "../../storeResourceTypes.sol";

// Import user types
import { ResourceId } from "./../../ResourceId.sol";
import { FieldLayout } from "./../../FieldLayout.sol";
import { Schema } from "./../../Schema.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14("store"), bytes16("Tables")))
);
ResourceId constant TablesTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0060030220202000000000000000000000000000000000000000000000000000
);

struct TablesData {
  FieldLayout fieldLayout;
  Schema keySchema;
  Schema valueSchema;
  bytes abiEncodedKeyNames;
  bytes abiEncodedFieldNames;
}

library Tables {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](5);
    _valueSchema[0] = SchemaType.BYTES32;
    _valueSchema[1] = SchemaType.BYTES32;
    _valueSchema[2] = SchemaType.BYTES32;
    _valueSchema[3] = SchemaType.BYTES;
    _valueSchema[4] = SchemaType.BYTES;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "tableId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](5);
    fieldNames[0] = "fieldLayout";
    fieldNames[1] = "keySchema";
    fieldNames[2] = "valueSchema";
    fieldNames[3] = "abiEncodedKeyNames";
    fieldNames[4] = "abiEncodedFieldNames";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get fieldLayout.
   */
  function getFieldLayout(ResourceId tableId) internal view returns (FieldLayout fieldLayout) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return FieldLayout.wrap(bytes32(_blob));
  }

  /**
   * @notice Get fieldLayout.
   */
  function _getFieldLayout(ResourceId tableId) internal view returns (FieldLayout fieldLayout) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return FieldLayout.wrap(bytes32(_blob));
  }

  /**
   * @notice Set fieldLayout.
   */
  function setFieldLayout(ResourceId tableId, FieldLayout fieldLayout) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(FieldLayout.unwrap(fieldLayout)), _fieldLayout);
  }

  /**
   * @notice Set fieldLayout.
   */
  function _setFieldLayout(ResourceId tableId, FieldLayout fieldLayout) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked(FieldLayout.unwrap(fieldLayout)), _fieldLayout);
  }

  /**
   * @notice Get keySchema.
   */
  function getKeySchema(ResourceId tableId) internal view returns (Schema keySchema) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return Schema.wrap(bytes32(_blob));
  }

  /**
   * @notice Get keySchema.
   */
  function _getKeySchema(ResourceId tableId) internal view returns (Schema keySchema) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return Schema.wrap(bytes32(_blob));
  }

  /**
   * @notice Set keySchema.
   */
  function setKeySchema(ResourceId tableId, Schema keySchema) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(Schema.unwrap(keySchema)), _fieldLayout);
  }

  /**
   * @notice Set keySchema.
   */
  function _setKeySchema(ResourceId tableId, Schema keySchema) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked(Schema.unwrap(keySchema)), _fieldLayout);
  }

  /**
   * @notice Get valueSchema.
   */
  function getValueSchema(ResourceId tableId) internal view returns (Schema valueSchema) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return Schema.wrap(bytes32(_blob));
  }

  /**
   * @notice Get valueSchema.
   */
  function _getValueSchema(ResourceId tableId) internal view returns (Schema valueSchema) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return Schema.wrap(bytes32(_blob));
  }

  /**
   * @notice Set valueSchema.
   */
  function setValueSchema(ResourceId tableId, Schema valueSchema) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked(Schema.unwrap(valueSchema)), _fieldLayout);
  }

  /**
   * @notice Set valueSchema.
   */
  function _setValueSchema(ResourceId tableId, Schema valueSchema) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked(Schema.unwrap(valueSchema)), _fieldLayout);
  }

  /**
   * @notice Get abiEncodedKeyNames.
   */
  function getAbiEncodedKeyNames(ResourceId tableId) internal view returns (bytes memory abiEncodedKeyNames) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 0);
    return (bytes(_blob));
  }

  /**
   * @notice Get abiEncodedKeyNames.
   */
  function _getAbiEncodedKeyNames(ResourceId tableId) internal view returns (bytes memory abiEncodedKeyNames) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 0);
    return (bytes(_blob));
  }

  /**
   * @notice Set abiEncodedKeyNames.
   */
  function setAbiEncodedKeyNames(ResourceId tableId, bytes memory abiEncodedKeyNames) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 0, bytes((abiEncodedKeyNames)));
  }

  /**
   * @notice Set abiEncodedKeyNames.
   */
  function _setAbiEncodedKeyNames(ResourceId tableId, bytes memory abiEncodedKeyNames) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 0, bytes((abiEncodedKeyNames)));
  }

  /**
   * @notice Get the length of abiEncodedKeyNames.
   */
  function lengthAbiEncodedKeyNames(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of abiEncodedKeyNames.
   */
  function _lengthAbiEncodedKeyNames(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 0);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get an item of abiEncodedKeyNames.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemAbiEncodedKeyNames(ResourceId tableId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Get an item of abiEncodedKeyNames.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemAbiEncodedKeyNames(ResourceId tableId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 0, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Push a slice to abiEncodedKeyNames.
   */
  function pushAbiEncodedKeyNames(ResourceId tableId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Push a slice to abiEncodedKeyNames.
   */
  function _pushAbiEncodedKeyNames(ResourceId tableId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 0, bytes((_slice)));
  }

  /**
   * @notice Pop a slice from abiEncodedKeyNames.
   */
  function popAbiEncodedKeyNames(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Pop a slice from abiEncodedKeyNames.
   */
  function _popAbiEncodedKeyNames(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 0, 1);
  }

  /**
   * @notice Update a slice of abiEncodedKeyNames at `_index`.
   */
  function updateAbiEncodedKeyNames(ResourceId tableId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update a slice of abiEncodedKeyNames at `_index`.
   */
  function _updateAbiEncodedKeyNames(ResourceId tableId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 0, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get abiEncodedFieldNames.
   */
  function getAbiEncodedFieldNames(ResourceId tableId) internal view returns (bytes memory abiEncodedFieldNames) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreSwitch.getDynamicField(_tableId, _keyTuple, 1);
    return (bytes(_blob));
  }

  /**
   * @notice Get abiEncodedFieldNames.
   */
  function _getAbiEncodedFieldNames(ResourceId tableId) internal view returns (bytes memory abiEncodedFieldNames) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    bytes memory _blob = StoreCore.getDynamicField(_tableId, _keyTuple, 1);
    return (bytes(_blob));
  }

  /**
   * @notice Set abiEncodedFieldNames.
   */
  function setAbiEncodedFieldNames(ResourceId tableId, bytes memory abiEncodedFieldNames) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setDynamicField(_tableId, _keyTuple, 1, bytes((abiEncodedFieldNames)));
  }

  /**
   * @notice Set abiEncodedFieldNames.
   */
  function _setAbiEncodedFieldNames(ResourceId tableId, bytes memory abiEncodedFieldNames) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setDynamicField(_tableId, _keyTuple, 1, bytes((abiEncodedFieldNames)));
  }

  /**
   * @notice Get the length of abiEncodedFieldNames.
   */
  function lengthAbiEncodedFieldNames(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreSwitch.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get the length of abiEncodedFieldNames.
   */
  function _lengthAbiEncodedFieldNames(ResourceId tableId) internal view returns (uint256) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    uint256 _byteLength = StoreCore.getDynamicFieldLength(_tableId, _keyTuple, 1);
    unchecked {
      return _byteLength / 1;
    }
  }

  /**
   * @notice Get an item of abiEncodedFieldNames.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function getItemAbiEncodedFieldNames(ResourceId tableId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreSwitch.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Get an item of abiEncodedFieldNames.
   * @dev Reverts with Store_IndexOutOfBounds if `_index` is out of bounds for the array.
   */
  function _getItemAbiEncodedFieldNames(ResourceId tableId, uint256 _index) internal view returns (bytes memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _blob = StoreCore.getDynamicFieldSlice(_tableId, _keyTuple, 1, _index * 1, (_index + 1) * 1);
      return (bytes(_blob));
    }
  }

  /**
   * @notice Push a slice to abiEncodedFieldNames.
   */
  function pushAbiEncodedFieldNames(ResourceId tableId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.pushToDynamicField(_tableId, _keyTuple, 1, bytes((_slice)));
  }

  /**
   * @notice Push a slice to abiEncodedFieldNames.
   */
  function _pushAbiEncodedFieldNames(ResourceId tableId, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.pushToDynamicField(_tableId, _keyTuple, 1, bytes((_slice)));
  }

  /**
   * @notice Pop a slice from abiEncodedFieldNames.
   */
  function popAbiEncodedFieldNames(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.popFromDynamicField(_tableId, _keyTuple, 1, 1);
  }

  /**
   * @notice Pop a slice from abiEncodedFieldNames.
   */
  function _popAbiEncodedFieldNames(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.popFromDynamicField(_tableId, _keyTuple, 1, 1);
  }

  /**
   * @notice Update a slice of abiEncodedFieldNames at `_index`.
   */
  function updateAbiEncodedFieldNames(ResourceId tableId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreSwitch.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Update a slice of abiEncodedFieldNames at `_index`.
   */
  function _updateAbiEncodedFieldNames(ResourceId tableId, uint256 _index, bytes memory _slice) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    unchecked {
      bytes memory _encoded = bytes((_slice));
      StoreCore.spliceDynamicData(_tableId, _keyTuple, 1, uint40(_index * 1), uint40(_encoded.length), _encoded);
    }
  }

  /**
   * @notice Get the full data.
   */
  function get(ResourceId tableId) internal view returns (TablesData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(ResourceId tableId) internal view returns (TablesData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(
    ResourceId tableId,
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    bytes memory abiEncodedKeyNames,
    bytes memory abiEncodedFieldNames
  ) internal {
    bytes memory _staticData = encodeStatic(fieldLayout, keySchema, valueSchema);

    PackedCounter _encodedLengths = encodeLengths(abiEncodedKeyNames, abiEncodedFieldNames);
    bytes memory _dynamicData = encodeDynamic(abiEncodedKeyNames, abiEncodedFieldNames);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(
    ResourceId tableId,
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    bytes memory abiEncodedKeyNames,
    bytes memory abiEncodedFieldNames
  ) internal {
    bytes memory _staticData = encodeStatic(fieldLayout, keySchema, valueSchema);

    PackedCounter _encodedLengths = encodeLengths(abiEncodedKeyNames, abiEncodedFieldNames);
    bytes memory _dynamicData = encodeDynamic(abiEncodedKeyNames, abiEncodedFieldNames);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(ResourceId tableId, TablesData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.fieldLayout, _table.keySchema, _table.valueSchema);

    PackedCounter _encodedLengths = encodeLengths(_table.abiEncodedKeyNames, _table.abiEncodedFieldNames);
    bytes memory _dynamicData = encodeDynamic(_table.abiEncodedKeyNames, _table.abiEncodedFieldNames);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(ResourceId tableId, TablesData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.fieldLayout, _table.keySchema, _table.valueSchema);

    PackedCounter _encodedLengths = encodeLengths(_table.abiEncodedKeyNames, _table.abiEncodedFieldNames);
    bytes memory _dynamicData = encodeDynamic(_table.abiEncodedKeyNames, _table.abiEncodedFieldNames);

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(
    bytes memory _blob
  ) internal pure returns (FieldLayout fieldLayout, Schema keySchema, Schema valueSchema) {
    fieldLayout = FieldLayout.wrap(Bytes.slice32(_blob, 0));

    keySchema = Schema.wrap(Bytes.slice32(_blob, 32));

    valueSchema = Schema.wrap(Bytes.slice32(_blob, 64));
  }

  /**
   * @notice Decode the tightly packed blob of dynamic data using the encoded lengths.
   */
  function decodeDynamic(
    PackedCounter _encodedLengths,
    bytes memory _blob
  ) internal pure returns (bytes memory abiEncodedKeyNames, bytes memory abiEncodedFieldNames) {
    uint256 _start;
    uint256 _end;
    unchecked {
      _end = _encodedLengths.atIndex(0);
    }
    abiEncodedKeyNames = (bytes(SliceLib.getSubslice(_blob, _start, _end).toBytes()));

    _start = _end;
    unchecked {
      _end += _encodedLengths.atIndex(1);
    }
    abiEncodedFieldNames = (bytes(SliceLib.getSubslice(_blob, _start, _end).toBytes()));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   * @param _encodedLengths Encoded lengths of dynamic fields.
   * @param _dynamicData Tightly packed dynamic fields.
   */
  function decode(
    bytes memory _staticData,
    PackedCounter _encodedLengths,
    bytes memory _dynamicData
  ) internal pure returns (TablesData memory _table) {
    (_table.fieldLayout, _table.keySchema, _table.valueSchema) = decodeStatic(_staticData);

    (_table.abiEncodedKeyNames, _table.abiEncodedFieldNames) = decodeDynamic(_encodedLengths, _dynamicData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(ResourceId tableId) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(fieldLayout, keySchema, valueSchema);
  }

  /**
   * @notice Tightly pack dynamic data lengths using this table's schema.
   * @return _encodedLengths The lengths of the dynamic fields (packed into a single bytes32 value).
   */
  function encodeLengths(
    bytes memory abiEncodedKeyNames,
    bytes memory abiEncodedFieldNames
  ) internal pure returns (PackedCounter _encodedLengths) {
    // Lengths are effectively checked during copy by 2**40 bytes exceeding gas limits
    unchecked {
      _encodedLengths = PackedCounterLib.pack(bytes(abiEncodedKeyNames).length, bytes(abiEncodedFieldNames).length);
    }
  }

  /**
   * @notice Tightly pack dynamic (variable length) data using this table's schema.
   * @return The dynamic data, encoded into a sequence of bytes.
   */
  function encodeDynamic(
    bytes memory abiEncodedKeyNames,
    bytes memory abiEncodedFieldNames
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(bytes((abiEncodedKeyNames)), bytes((abiEncodedFieldNames)));
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    bytes memory abiEncodedKeyNames,
    bytes memory abiEncodedFieldNames
  ) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(fieldLayout, keySchema, valueSchema);

    PackedCounter _encodedLengths = encodeLengths(abiEncodedKeyNames, abiEncodedFieldNames);
    bytes memory _dynamicData = encodeDynamic(abiEncodedKeyNames, abiEncodedFieldNames);

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(ResourceId tableId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = ResourceId.unwrap(tableId);

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Shared Constants for EVM and Schema Handling
 * @dev This file provides constants for better handling of EVM and Schema related functionalities.
 */

/* Shared constants */

/// @dev Represents the total byte length of an EVM word.
uint256 constant WORD_SIZE = 32;

/// @dev Represents the index of the last byte in an EVM word.
uint256 constant WORD_LAST_INDEX = 31;

/// @dev Represents the conversion constant from byte to bits.
uint256 constant BYTE_TO_BITS = 8;

/// @dev Represents the maximum number of fields a Schema can handle.
uint256 constant MAX_TOTAL_FIELDS = 28;

/// @dev Represents the maximum number of static fields in a FieldLayout.
uint256 constant MAX_STATIC_FIELDS = 28;

/// @dev Represents the maximum number of dynamic fields that can be packed in a PackedCounter.
uint256 constant MAX_DYNAMIC_FIELDS = 5;

/**
 * @title LayoutOffsets Library
 * @notice This library provides constant offsets for FieldLayout and Schema metadata.
 * @dev FieldLayout and Schema utilize the same offset values for metadata.
 */
library LayoutOffsets {
  /// @notice Represents the total length offset within the EVM word.
  uint256 internal constant TOTAL_LENGTH = (WORD_SIZE - 2) * BYTE_TO_BITS;

  /// @notice Represents the number of static fields offset within the EVM word.
  uint256 internal constant NUM_STATIC_FIELDS = (WORD_SIZE - 2 - 1) * BYTE_TO_BITS;

  /// @notice Represents the number of dynamic fields offset within the EVM word.
  uint256 internal constant NUM_DYNAMIC_FIELDS = (WORD_SIZE - 2 - 1 - 1) * BYTE_TO_BITS;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { WORD_SIZE, WORD_LAST_INDEX, BYTE_TO_BITS, MAX_TOTAL_FIELDS, MAX_DYNAMIC_FIELDS, LayoutOffsets } from "./constants.sol";

/**
 * @title FieldLayout
 * @dev Represents a field layout encoded into a single bytes32.
 * From left to right, the bytes are laid out as follows:
 * - 2 bytes for total length of all static fields
 * - 1 byte for number of static size fields
 * - 1 byte for number of dynamic size fields
 * - 28 bytes for 28 static field lengths
 * (MAX_DYNAMIC_FIELDS allows PackedCounter to pack the dynamic lengths into 1 word)
 */
type FieldLayout is bytes32;

// When importing FieldLayout, attach FieldLayoutInstance to it
using FieldLayoutInstance for FieldLayout global;

/**
 * @title FieldLayoutLib
 * @dev A library for handling field layout encoding into a single bytes32.
 * It provides a function to encode static and dynamic fields and ensure
 * various constraints regarding the length and size of the fields.
 */
library FieldLayoutLib {
  error FieldLayoutLib_InvalidLength(uint256 length);
  error FieldLayoutLib_StaticLengthIsZero();
  error FieldLayoutLib_StaticLengthDoesNotFitInAWord();

  /**
   * @notice Encodes the given field layout into a single bytes32.
   * @dev Ensures various constraints on the length and size of the fields.
   * Reverts if total fields, static field length, or static byte length exceed allowed limits.
   * @param _staticFields An array of static field lengths.
   * @param numDynamicFields The number of dynamic fields.
   * @return A FieldLayout structure containing the encoded field layout.
   */
  function encode(uint256[] memory _staticFields, uint256 numDynamicFields) internal pure returns (FieldLayout) {
    uint256 fieldLayout;
    uint256 totalLength;
    uint256 totalFields = _staticFields.length + numDynamicFields;
    if (totalFields > MAX_TOTAL_FIELDS) revert FieldLayoutLib_InvalidLength(totalFields);
    if (numDynamicFields > MAX_DYNAMIC_FIELDS) revert FieldLayoutLib_InvalidLength(numDynamicFields);

    // Compute the total static length and store the field lengths in the encoded fieldLayout
    for (uint256 i = 0; i < _staticFields.length; ) {
      uint256 staticByteLength = _staticFields[i];
      if (staticByteLength == 0) {
        revert FieldLayoutLib_StaticLengthIsZero();
      } else if (staticByteLength > WORD_SIZE) {
        revert FieldLayoutLib_StaticLengthDoesNotFitInAWord();
      }

      unchecked {
        // (safe because 28 (max _staticFields.length) * 32 (max static length) < 2**16)
        totalLength += staticByteLength;
        // Sequentially store lengths after the first 4 bytes (which are reserved for total length and field numbers)
        // (safe because of the initial _staticFields.length check)
        fieldLayout |= uint256(_staticFields[i]) << ((WORD_LAST_INDEX - 4 - i) * BYTE_TO_BITS);
        i++;
      }
    }

    // Store total static length in the first 2 bytes,
    // number of static fields in the 3rd byte,
    // number of dynamic fields in the 4th byte
    // (optimizer can handle this, no need for unchecked or single-line assignment)
    fieldLayout |= totalLength << LayoutOffsets.TOTAL_LENGTH;
    fieldLayout |= _staticFields.length << LayoutOffsets.NUM_STATIC_FIELDS;
    fieldLayout |= numDynamicFields << LayoutOffsets.NUM_DYNAMIC_FIELDS;

    return FieldLayout.wrap(bytes32(fieldLayout));
  }
}

/**
 * @title FieldLayoutInstance
 * @dev Provides instance functions for obtaining information from an encoded FieldLayout.
 */
library FieldLayoutInstance {
  /**
   * @notice Get the static byte length at the given index from the field layout.
   * @param fieldLayout The FieldLayout to extract the byte length from.
   * @param index The field index to get the static byte length from.
   * @return The static byte length at the specified index.
   */
  function atIndex(FieldLayout fieldLayout, uint256 index) internal pure returns (uint256) {
    unchecked {
      return uint8(uint256(fieldLayout.unwrap()) >> ((WORD_LAST_INDEX - 4 - index) * BYTE_TO_BITS));
    }
  }

  /**
   * @notice Get the total static byte length for the given field layout.
   * @param fieldLayout The FieldLayout to extract the total static byte length from.
   * @return The total static byte length.
   */
  function staticDataLength(FieldLayout fieldLayout) internal pure returns (uint256) {
    return uint256(FieldLayout.unwrap(fieldLayout)) >> LayoutOffsets.TOTAL_LENGTH;
  }

  /**
   * @notice Get the number of static fields for the field layout.
   * @param fieldLayout The FieldLayout to extract the number of static fields from.
   * @return The number of static fields.
   */
  function numStaticFields(FieldLayout fieldLayout) internal pure returns (uint256) {
    return uint8(uint256(fieldLayout.unwrap()) >> LayoutOffsets.NUM_STATIC_FIELDS);
  }

  /**
   * @notice Get the number of dynamic length fields for the field layout.
   * @param fieldLayout The FieldLayout to extract the number of dynamic fields from.
   * @return The number of dynamic length fields.
   */
  function numDynamicFields(FieldLayout fieldLayout) internal pure returns (uint256) {
    return uint8(uint256(fieldLayout.unwrap()) >> LayoutOffsets.NUM_DYNAMIC_FIELDS);
  }

  /**
   * @notice Get the total number of fields for the field layout.
   * @param fieldLayout The FieldLayout to extract the total number of fields from.
   * @return The total number of fields.
   */
  function numFields(FieldLayout fieldLayout) internal pure returns (uint256) {
    unchecked {
      return
        uint8(uint256(fieldLayout.unwrap()) >> LayoutOffsets.NUM_STATIC_FIELDS) +
        uint8(uint256(fieldLayout.unwrap()) >> LayoutOffsets.NUM_DYNAMIC_FIELDS);
    }
  }

  /**
   * @notice Check if the field layout is empty.
   * @param fieldLayout The FieldLayout to check.
   * @return True if the field layout is empty, false otherwise.
   */
  function isEmpty(FieldLayout fieldLayout) internal pure returns (bool) {
    return FieldLayout.unwrap(fieldLayout) == bytes32(0);
  }

  /**
   * @notice Validate the field layout with various checks on the length and size of the fields.
   * @dev Reverts if total fields, static field length, or static byte length exceed allowed limits.
   * @param fieldLayout The FieldLayout to validate.
   * @param allowEmpty A flag to determine if empty field layouts are allowed.
   */
  function validate(FieldLayout fieldLayout, bool allowEmpty) internal pure {
    // FieldLayout must not be empty
    if (!allowEmpty && fieldLayout.isEmpty()) revert FieldLayoutLib.FieldLayoutLib_InvalidLength(0);

    // FieldLayout must have no more than MAX_DYNAMIC_FIELDS
    uint256 _numDynamicFields = fieldLayout.numDynamicFields();
    if (_numDynamicFields > MAX_DYNAMIC_FIELDS) revert FieldLayoutLib.FieldLayoutLib_InvalidLength(_numDynamicFields);

    uint256 _numStaticFields = fieldLayout.numStaticFields();
    // FieldLayout must not have more than MAX_TOTAL_FIELDS in total
    uint256 _numTotalFields = _numStaticFields + _numDynamicFields;
    if (_numTotalFields > MAX_TOTAL_FIELDS) revert FieldLayoutLib.FieldLayoutLib_InvalidLength(_numTotalFields);

    // Static lengths must be valid
    for (uint256 i; i < _numStaticFields; ) {
      uint256 staticByteLength = fieldLayout.atIndex(i);
      if (staticByteLength == 0) {
        revert FieldLayoutLib.FieldLayoutLib_StaticLengthIsZero();
      } else if (staticByteLength > WORD_SIZE) {
        revert FieldLayoutLib.FieldLayoutLib_StaticLengthDoesNotFitInAWord();
      }
      unchecked {
        i++;
      }
    }
  }

  /**
   * @notice Unwrap the field layout to obtain the raw bytes32 representation.
   * @param fieldLayout The FieldLayout to unwrap.
   * @return The unwrapped bytes32 representation of the FieldLayout.
   */
  function unwrap(FieldLayout fieldLayout) internal pure returns (bytes32) {
    return FieldLayout.unwrap(fieldLayout);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Hooks } from "./codegen/tables/Hooks.sol";
import { ResourceId } from "./ResourceId.sol";

// 20 bytes address, 1 byte bitmap of enabled hooks
type Hook is bytes21;

using HookInstance for Hook global;

/**
 * @title HookLib
 * @dev Library for encoding hooks and filtering hooks from a list by address.
 */
library HookLib {
  /**
   * @notice Packs the bitmap of enabled hooks with the hook address into a Hook value (bytes21).
   * @dev The hook address is stored in the leftmost 20 bytes, and the bitmap is stored in the rightmost byte.
   * @param hookAddress The address of the hook.
   * @param encodedHooks The encoded hooks in a bitmap.
   * @return A Hook type with packed hook address and bitmap.
   */
  function encode(address hookAddress, uint8 encodedHooks) internal pure returns (Hook) {
    // Move the address to the leftmost 20 bytes and the bitmap to the rightmost byte
    return Hook.wrap(bytes21(bytes20(hookAddress)) | bytes21(uint168(encodedHooks)));
  }

  /**
   * @notice Filter a hook from the hook list by its address.
   * @dev This function writes the updated hook list to the table in place.
   * @param hookTableId The resource ID of the hook table.
   * @param tableWithHooks The resource ID of the table with hooks to filter.
   * @param hookAddressToRemove The address of the hook to remove.
   */
  function filterListByAddress(
    ResourceId hookTableId,
    ResourceId tableWithHooks,
    address hookAddressToRemove
  ) internal {
    bytes21[] memory currentHooks = Hooks._get(hookTableId, tableWithHooks);

    // Initialize the new hooks array with the same length because we don't know if the hook is registered yet
    bytes21[] memory newHooks = new bytes21[](currentHooks.length);

    // Filter the array of current hooks
    uint256 newHooksIndex;
    unchecked {
      for (uint256 currentHooksIndex; currentHooksIndex < currentHooks.length; currentHooksIndex++) {
        if (Hook.wrap(currentHooks[currentHooksIndex]).getAddress() != address(hookAddressToRemove)) {
          newHooks[newHooksIndex] = currentHooks[currentHooksIndex];
          newHooksIndex++;
        }
      }
    }

    // Set the new hooks table length in place
    // (Note: this does not update the free memory pointer)
    assembly {
      mstore(newHooks, newHooksIndex)
    }

    // Set the new hooks table
    Hooks._set(hookTableId, tableWithHooks, newHooks);
  }
}

/**
 * @title HookInstance
 * @dev Library for interacting with Hook instances.
 **/
library HookInstance {
  /**
   * @notice Check if the given hook types are enabled in the hook.
   * @dev We check multiple hook types at once by using a bitmap.
   * @param self The Hook instance to check.
   * @param hookTypes A bitmap of hook types to check.
   * @return True if the hook types are enabled, false otherwise.
   */
  function isEnabled(Hook self, uint8 hookTypes) internal pure returns (bool) {
    return (getBitmap(self) & hookTypes) == hookTypes;
  }

  /**
   * @notice Get the address from the hook.
   * @dev The address is stored in the leftmost 20 bytes.
   * @param self The Hook instance to get the address from.
   * @return The address contained in the Hook instance.
   */
  function getAddress(Hook self) internal pure returns (address) {
    // Extract the address from the leftmost 20 bytes
    return address(bytes20(Hook.unwrap(self)));
  }

  /**
   * @notice Get the bitmap from the hook.
   * @dev The bitmap is stored in the rightmost byte.
   * @param self The Hook instance to get the bitmap from.
   * @return The bitmap contained in the Hook instance.
   */
  function getBitmap(Hook self) internal pure returns (uint8) {
    // Extract the bitmap from the rightmost bytes
    return uint8(uint168(Hook.unwrap(self)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

bytes4 constant ERC165_INTERFACE_ID = IERC165.supportsInterface.selector;

// See https://eips.ethereum.org/EIPS/eip-165
interface IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param interfaceID The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   * @return `true` if the contract implements `interfaceID` and
   * `interfaceID` is not 0xffffffff, `false` otherwise
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IStoreErrors } from "./IStoreErrors.sol";
import { IStoreData } from "./IStoreData.sol";
import { IStoreRegistration } from "./IStoreRegistration.sol";

interface IStore is IStoreData, IStoreRegistration, IStoreErrors {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IStoreRead } from "./IStoreRead.sol";
import { IStoreWrite } from "./IStoreWrite.sol";

/**
 * @title IStoreData
 * @notice The IStoreData interface includes methods for reading and writing table values.
 * @dev These methods are frequently invoked during runtime, so it is essential to prioritize optimizing their gas cost.
 */
interface IStoreData is IStoreRead, IStoreWrite {
  /**
   * @notice Emitted when the store is initialized.
   * @param storeVersion The version of the Store contract.
   */
  event HelloStore(bytes32 indexed storeVersion);

  /**
   * @notice Returns the version of the Store contract.
   * @return version The version of the Store contract.
   */
  function storeVersion() external view returns (bytes32 version);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "./ResourceId.sol";

interface IStoreErrors {
  // Errors include a stringified version of the tableId for easier debugging if cleartext tableIds are used
  error Store_TableAlreadyExists(ResourceId tableId, string tableIdString);
  error Store_TableNotFound(ResourceId tableId, string tableIdString);
  error Store_InvalidResourceType(bytes2 expected, ResourceId resourceId, string resourceIdString);

  error Store_InvalidDynamicDataLength(uint256 expected, uint256 received);
  error Store_IndexOutOfBounds(uint256 length, uint256 accessedIndex);
  error Store_InvalidKeyNamesLength(uint256 expected, uint256 received);
  error Store_InvalidFieldNamesLength(uint256 expected, uint256 received);
  error Store_InvalidValueSchemaLength(uint256 expected, uint256 received);
  error Store_InvalidSplice(uint40 startWithinField, uint40 deleteCount, uint40 fieldLength);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { ResourceId } from "./ResourceId.sol";
import { PackedCounter } from "./PackedCounter.sol";

interface IStoreEvents {
  /**
   * @notice Emitted when a new record is set in the store.
   * @param tableId The ID of the table where the record is set.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   */
  event Store_SetRecord(
    ResourceId indexed tableId,
    bytes32[] keyTuple,
    bytes staticData,
    PackedCounter encodedLengths,
    bytes dynamicData
  );

  /**
   * @notice Emitted when static data in the store is spliced.
   * @dev In static data, data is always overwritten starting at the start position,
   * so the total length of the data remains the same and no data is shifted.
   * @param tableId The ID of the table where the data is spliced.
   * @param keyTuple An array representing the key for the record.
   * @param start The start position in bytes for the splice operation.
   * @param data The data to write to the static data of the record at the start byte.
   */
  event Store_SpliceStaticData(ResourceId indexed tableId, bytes32[] keyTuple, uint48 start, bytes data);

  /**
   * @notice Emitted when dynamic data in the store is spliced.
   * @param tableId The ID of the table where the data is spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param start The start position in bytes for the splice operation.
   * @param deleteCount The number of bytes to delete in the splice operation.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param data The data to insert into the dynamic data of the record at the start byte.
   */
  event Store_SpliceDynamicData(
    ResourceId indexed tableId,
    bytes32[] keyTuple,
    uint48 start,
    uint40 deleteCount,
    PackedCounter encodedLengths,
    bytes data
  );

  /**
   * @notice Emitted when a record is deleted from the store.
   * @param tableId The ID of the table where the record is deleted.
   * @param keyTuple An array representing the composite key for the record.
   */
  event Store_DeleteRecord(ResourceId indexed tableId, bytes32[] keyTuple);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { FieldLayout } from "./FieldLayout.sol";
import { IERC165, ERC165_INTERFACE_ID } from "./IERC165.sol";
import { PackedCounter } from "./PackedCounter.sol";
import { ResourceId } from "./ResourceId.sol";

// ERC-165 Interface ID (see https://eips.ethereum.org/EIPS/eip-165)
bytes4 constant STORE_HOOK_INTERFACE_ID = IStoreHook.onBeforeSetRecord.selector ^
  IStoreHook.onAfterSetRecord.selector ^
  IStoreHook.onBeforeSpliceStaticData.selector ^
  IStoreHook.onAfterSpliceStaticData.selector ^
  IStoreHook.onBeforeSpliceDynamicData.selector ^
  IStoreHook.onAfterSpliceDynamicData.selector ^
  IStoreHook.onBeforeDeleteRecord.selector ^
  IStoreHook.onAfterDeleteRecord.selector ^
  ERC165_INTERFACE_ID;

interface IStoreHook is IERC165 {
  /// @notice Error emitted when a function is not implemented.
  error StoreHook_NotImplemented();

  /**
   * @notice Called before setting a record in the store.
   * @param tableId The ID of the table where the record is to be set.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   * @param fieldLayout The layout of the field, see FieldLayout.sol.
   */
  function onBeforeSetRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    bytes memory staticData,
    PackedCounter encodedLengths,
    bytes memory dynamicData,
    FieldLayout fieldLayout
  ) external;

  /**
   * @notice Called after setting a record in the store.
   * @param tableId The ID of the table where the record was set.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   * @param fieldLayout The layout of the field, see FieldLayout.sol.
   */
  function onAfterSetRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    bytes memory staticData,
    PackedCounter encodedLengths,
    bytes memory dynamicData,
    FieldLayout fieldLayout
  ) external;

  /**
   * @notice Called before splicing static data in the store.
   * @dev Splice operations in static data always overwrite data starting at the start position,
   * so the total length of the data remains the same and no data is shifted.
   * @param tableId The ID of the table where the data is to be spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param start The start byte position for splicing.
   * @param data The data to be written to the static data of the record at the start byte.
   */
  function onBeforeSpliceStaticData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint48 start,
    bytes memory data
  ) external;

  /**
   * @notice Called after splicing static data in the store.
   * @dev Splice operations in static data always overwrite data starting at the start position,
   * so the total length of the data remains the same and no data is shifted.
   * @param tableId The ID of the table where the data was spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param start The start byte position for splicing.
   * @param data The data written to the static data of the record at the start byte.
   */
  function onAfterSpliceStaticData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint48 start,
    bytes memory data
  ) external;

  /**
   * @notice Called before splicing dynamic data in the store.
   * @dev Splice operations in dynamic data always reach the end of the dynamic data
   * to avoid shifting data after the inserted or deleted data.
   * @param tableId The ID of the table where the data is to be spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field.
   * @param startWithinField The start byte position within the field for splicing.
   * @param deleteCount The number of bytes to delete in the dynamic data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param data The data to be inserted into the dynamic data of the record at the start byte.
   */
  function onBeforeSpliceDynamicData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    PackedCounter encodedLengths,
    bytes memory data
  ) external;

  /**
   * @notice Called after splicing dynamic data in the store.
   * @dev Splice operations in dynamic data always reach the end of the dynamic data
   * to avoid shifting data after the inserted or deleted data.
   * @param tableId The ID of the table where the data was spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field.
   * @param startWithinField The start byte position within the field for splicing.
   * @param deleteCount The number of bytes deleted in the dynamic data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param data The data inserted into the dynamic data of the record at the start byte.
   */
  function onAfterSpliceDynamicData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    PackedCounter encodedLengths,
    bytes memory data
  ) external;

  /**
   * @notice Called before deleting a record from the store.
   * @param tableId The ID of the table where the record is to be deleted.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldLayout The layout of the field, see FieldLayout.sol.
   */
  function onBeforeDeleteRecord(ResourceId tableId, bytes32[] memory keyTuple, FieldLayout fieldLayout) external;

  /**
   * @notice Called after deleting a record from the store.
   * @param tableId The ID of the table where the record was deleted.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldLayout The layout of the field, see FieldLayout.sol.
   */
  function onAfterDeleteRecord(ResourceId tableId, bytes32[] memory keyTuple, FieldLayout fieldLayout) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { PackedCounter } from "./PackedCounter.sol";
import { FieldLayout } from "./FieldLayout.sol";
import { Schema } from "./Schema.sol";
import { ResourceId } from "./ResourceId.sol";

interface IStoreRead {
  function getFieldLayout(ResourceId tableId) external view returns (FieldLayout fieldLayout);

  function getValueSchema(ResourceId tableId) external view returns (Schema valueSchema);

  function getKeySchema(ResourceId tableId) external view returns (Schema keySchema);

  /**
   * Get full record (all fields, static and dynamic data) for the given tableId and key tuple, loading the field layout from storage
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] calldata keyTuple
  ) external view returns (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData);

  /**
   * Get full record (all fields, static and dynamic data) for the given tableId and key tuple, with the given field layout
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    FieldLayout fieldLayout
  ) external view returns (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData);

  /**
   * Get a single field from the given tableId and key tuple, loading the field layout from storage
   */
  function getField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex
  ) external view returns (bytes memory data);

  /**
   * Get a single field from the given tableId and key tuple, with the given field layout
   */
  function getField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) external view returns (bytes memory data);

  /**
   * Get a single static field from the given tableId and key tuple, with the given value field layout.
   * Note: the field value is left-aligned in the returned bytes32, the rest of the word is not zeroed out.
   * Consumers are expected to truncate the returned value as needed.
   */
  function getStaticField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) external view returns (bytes32);

  /**
   * Get a single dynamic field from the given tableId and key tuple at the given dynamic field index.
   * (Dynamic field index = field index - number of static fields)
   */
  function getDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) external view returns (bytes memory);

  /**
   * Get the byte length of a single field from the given tableId and key tuple, loading the field layout from storage
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex
  ) external view returns (uint256);

  /**
   * Get the byte length of a single field from the given tableId and key tuple, with the given value field layout
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) external view returns (uint256);

  /**
   * Get the byte length of a single dynamic field from the given tableId and key tuple
   */
  function getDynamicFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) external view returns (uint256);

  /**
   * Get a byte slice (including start, excluding end) of a single dynamic field from the given tableId and key tuple, with the given value field layout.
   * The slice is unchecked and will return invalid data if `start`:`end` overflow.
   */
  function getDynamicFieldSlice(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint256 start,
    uint256 end
  ) external view returns (bytes memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { FieldLayout } from "./FieldLayout.sol";
import { Schema } from "./Schema.sol";
import { IStoreHook } from "./IStoreHook.sol";
import { ResourceId } from "./ResourceId.sol";

/**
 * The IStoreRegistration interface includes methods for managing table field layouts,
 * metadata, and hooks, which are usually called once in the setup phase of an application,
 * making them less performance critical than the  methods.
 */
interface IStoreRegistration {
  function registerTable(
    ResourceId tableId,
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    string[] calldata keyNames,
    string[] calldata fieldNames
  ) external;

  // Register hook to be called when a record or field is set or deleted
  function registerStoreHook(ResourceId tableId, IStoreHook hookAddress, uint8 enabledHooksBitmap) external;

  // Unregister a hook for the given tableId
  function unregisterStoreHook(ResourceId tableId, IStoreHook hookAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IStoreEvents } from "./IStoreEvents.sol";
import { PackedCounter } from "./PackedCounter.sol";
import { FieldLayout } from "./FieldLayout.sol";
import { ResourceId } from "./ResourceId.sol";

interface IStoreWrite is IStoreEvents {
  // Set full record (including full dynamic data)
  function setRecord(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    bytes calldata staticData,
    PackedCounter encodedLengths,
    bytes calldata dynamicData
  ) external;

  // Splice data in the static part of the record
  function spliceStaticData(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint48 start,
    bytes calldata data
  ) external;

  // Splice data in the dynamic part of the record
  function spliceDynamicData(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    bytes calldata data
  ) external;

  // Set partial data at field index
  function setField(ResourceId tableId, bytes32[] calldata keyTuple, uint8 fieldIndex, bytes calldata data) external;

  // Set partial data at field index
  function setField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    bytes calldata data,
    FieldLayout fieldLayout
  ) external;

  function setStaticField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 fieldIndex,
    bytes calldata data,
    FieldLayout fieldLayout
  ) external;

  function setDynamicField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 dynamicFieldIndex,
    bytes calldata data
  ) external;

  // Push encoded items to the dynamic field at field index
  function pushToDynamicField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 dynamicFieldIndex,
    bytes calldata dataToPush
  ) external;

  // Pop byte length from the dynamic field at field index
  function popFromDynamicField(
    ResourceId tableId,
    bytes32[] calldata keyTuple,
    uint8 dynamicFieldIndex,
    uint256 byteLengthToPop
  ) external;

  // Set full record (including full dynamic data)
  function deleteRecord(ResourceId tableId, bytes32[] memory keyTuple) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Byte Mask Utility
 * @notice Utility functions to manage bytes in memory.
 * @dev Adapted from https://github.com/dk1a/solidity-stringutils/blob/main/src/utils/mem.sol#L149-L167
 */

/**
 * @notice Computes a left-aligned byte mask based on the provided byte length.
 * @dev The mask is used to extract a specified number of leftmost bytes.
 *      For byte lengths greater than or equal to 32, it returns the max value of type(uint256).
 *      Examples:
 *          length 0:   0x000000...000000
 *          length 1:   0xff0000...000000
 *          length 2:   0xffff00...000000
 *          ...
 *          length 30:  0xffffff...ff0000
 *          length 31:  0xffffff...ffff00
 *          length 32+: 0xffffff...ffffff
 * @param byteLength The number of leftmost bytes to be masked.
 * @return mask A left-aligned byte mask corresponding to the specified byte length.
 */
function leftMask(uint256 byteLength) pure returns (uint256 mask) {
  unchecked {
    return ~(type(uint256).max >> (byteLength * 8));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { leftMask } from "./leftMask.sol";

/**
 * @title Memory Operations
 * @notice A library for performing low-level memory operations.
 * @dev This library provides low-level memory operations with safety checks.
 */
library Memory {
  /**
   * @notice Gets the actual data pointer of dynamic arrays.
   * @dev In dynamic arrays, the first word stores the length of the data, after which comes the actual data.
   * Example: 0x40 0x01 0x02
   *          ^len ^data
   * @param data The dynamic bytes data from which to get the pointer.
   * @return memoryPointer The pointer to the actual data (skipping the length).
   */
  function dataPointer(bytes memory data) internal pure returns (uint256 memoryPointer) {
    assembly {
      memoryPointer := add(data, 0x20)
    }
  }

  /**
   * @notice Copies memory from one location to another.
   * @dev Safely copies memory in chunks of 32 bytes, then handles any residual bytes.
   * @param fromPointer The memory location to copy from.
   * @param toPointer The memory location to copy to.
   * @param length The number of bytes to copy.
   */
  function copy(uint256 fromPointer, uint256 toPointer, uint256 length) internal pure {
    // Copy 32-byte chunks
    while (length >= 32) {
      /// @solidity memory-safe-assembly
      assembly {
        mstore(toPointer, mload(fromPointer))
      }
      // Safe because total addition will be <= length (ptr+len is implicitly safe)
      unchecked {
        toPointer += 32;
        fromPointer += 32;
        length -= 32;
      }
    }
    if (length == 0) return;

    // Copy the 0-31 length tail
    uint256 mask = leftMask(length);
    /// @solidity memory-safe-assembly
    assembly {
      mstore(
        toPointer,
        or(
          // store the left part
          and(mload(fromPointer), mask),
          // preserve the right part
          and(mload(toPointer), not(mask))
        )
      )
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title PackedCounter Type Definition
 * @dev Describes how the packed counter is structured.
 * - 0x00-0x06 The least significant 7 bytes (uint56) represent the total byte length of dynamic (variable length) data.
 * - 0x07-0xB The next five bytes (uint40) represent the length of the first dynamic field.
 * - 0x0C-0x10 Followed by the length of the second dynamic field
 * - 0x11-0x15 Length of the third dynamic field
 * - 0x16-0x1A Length of fourth dynamic field
 * - 0x1B-0x1F Length of fifth dynamic field
 */
type PackedCounter is bytes32;

using PackedCounterInstance for PackedCounter global;

// Constants for packed counter handling:

// Number of bits for the 7-byte accumulator
uint256 constant ACC_BITS = 7 * 8;
// Number of bits for the 5-byte sections
uint256 constant VAL_BITS = 5 * 8;
// Maximum value of a 5-byte section
uint256 constant MAX_VAL = type(uint40).max;

/**
 * @title PackedCounter Library
 * @notice Static functions for handling PackedCounter type.
 * @dev Provides utility functions to pack values into a PackedCounter.
 * The caller must ensure that the value arguments are <= MAX_VAL.
 */
library PackedCounterLib {
  /**
   * @notice Packs a single value into a PackedCounter.
   * @dev Encodes the given value 'a' into the structure of a PackedCounter. The packed counter's accumulator
   * will be set to 'a', and the first value slot of the PackedCounter will also be set to 'a'.
   * @param a The length of the first dynamic field's data.
   * @return The resulting PackedCounter containing the encoded value.
   */
  function pack(uint256 a) internal pure returns (PackedCounter) {
    uint256 packedCounter;
    unchecked {
      packedCounter = a;
      packedCounter |= (uint256(a) << (ACC_BITS + VAL_BITS * 0));
    }
    return PackedCounter.wrap(bytes32(packedCounter));
  }

  /**
   * @notice Packs a single value into a PackedCounter.
   * @dev Encodes the given values 'a'-'b' into the structure of a PackedCounter.
   * @param a The length of the first dynamic field's data.
   * @param b The length of the second dynamic field's data.
   * @return The resulting PackedCounter containing the encoded values.
   */
  function pack(uint256 a, uint256 b) internal pure returns (PackedCounter) {
    uint256 packedCounter;
    unchecked {
      packedCounter = a + b;
      packedCounter |= (uint256(a) << (ACC_BITS + VAL_BITS * 0));
      packedCounter |= (uint256(b) << (ACC_BITS + VAL_BITS * 1));
    }
    return PackedCounter.wrap(bytes32(packedCounter));
  }

  /**
   * @notice Packs a single value into a PackedCounter.
   * @dev Encodes the given values 'a'-'c' into the structure of a PackedCounter.
   * @param a The length of the first dynamic field's data.
   * @param b The length of the second dynamic field's data.
   * @param c The length of the third dynamic field's data.
   * @return The resulting PackedCounter containing the encoded values.
   */
  function pack(uint256 a, uint256 b, uint256 c) internal pure returns (PackedCounter) {
    uint256 packedCounter;
    unchecked {
      packedCounter = a + b + c;
      packedCounter |= (uint256(a) << (ACC_BITS + VAL_BITS * 0));
      packedCounter |= (uint256(b) << (ACC_BITS + VAL_BITS * 1));
      packedCounter |= (uint256(c) << (ACC_BITS + VAL_BITS * 2));
    }
    return PackedCounter.wrap(bytes32(packedCounter));
  }

  /**
   * @notice Packs a single value into a PackedCounter.
   * @dev Encodes the given values 'a'-'d' into the structure of a PackedCounter.
   * @param a The length of the first dynamic field's data.
   * @param b The length of the second dynamic field's data.
   * @param c The length of the third dynamic field's data.
   * @param d The length of the fourth dynamic field's data.
   * @return The resulting PackedCounter containing the encoded values.
   */
  function pack(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (PackedCounter) {
    uint256 packedCounter;
    unchecked {
      packedCounter = a + b + c + d;
      packedCounter |= (uint256(a) << (ACC_BITS + VAL_BITS * 0));
      packedCounter |= (uint256(b) << (ACC_BITS + VAL_BITS * 1));
      packedCounter |= (uint256(c) << (ACC_BITS + VAL_BITS * 2));
      packedCounter |= (uint256(d) << (ACC_BITS + VAL_BITS * 3));
    }
    return PackedCounter.wrap(bytes32(packedCounter));
  }

  /**
   * @notice Packs a single value into a PackedCounter.
   * @dev Encodes the given values 'a'-'e' into the structure of a PackedCounter.
   * @param a The length of the first dynamic field's data.
   * @param b The length of the second dynamic field's data.
   * @param c The length of the third dynamic field's data.
   * @param d The length of the fourth dynamic field's data.
   * @param e The length of the fourth dynamic field's data.
   * @return The resulting PackedCounter containing the encoded values.
   */
  function pack(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) internal pure returns (PackedCounter) {
    uint256 packedCounter;
    unchecked {
      packedCounter = a + b + c + d + e;
      packedCounter |= (uint256(a) << (ACC_BITS + VAL_BITS * 0));
      packedCounter |= (uint256(b) << (ACC_BITS + VAL_BITS * 1));
      packedCounter |= (uint256(c) << (ACC_BITS + VAL_BITS * 2));
      packedCounter |= (uint256(d) << (ACC_BITS + VAL_BITS * 3));
      packedCounter |= (uint256(e) << (ACC_BITS + VAL_BITS * 4));
    }
    return PackedCounter.wrap(bytes32(packedCounter));
  }
}

/**
 * @title PackedCounter Instance Library
 * @notice Instance functions for handling a PackedCounter.
 * @dev Offers decoding, extracting, and setting functionalities for a PackedCounter.
 */
library PackedCounterInstance {
  error PackedCounter_InvalidLength(uint256 length);

  /**
   * @notice Decode the accumulated counter from a PackedCounter.
   * @dev Extracts the right-most 7 bytes of a PackedCounter.
   * @param packedCounter The packed counter to decode.
   * @return The accumulated value from the PackedCounter.
   */
  function total(PackedCounter packedCounter) internal pure returns (uint256) {
    return uint56(uint256(PackedCounter.unwrap(packedCounter)));
  }

  /**
   * @notice Decode the dynamic field size at a specific index from a PackedCounter.
   * @dev Extracts value right-to-left, with 5 bytes per dynamic field after the right-most 7 bytes.
   * @param packedCounter The packed counter to decode.
   * @param index The index to retrieve.
   * @return The value at the given index from the PackedCounter.
   */
  function atIndex(PackedCounter packedCounter, uint8 index) internal pure returns (uint256) {
    unchecked {
      return uint40(uint256(PackedCounter.unwrap(packedCounter) >> (ACC_BITS + VAL_BITS * index)));
    }
  }

  /**
   * @notice Set a counter at a specific index in a PackedCounter.
   * @dev Updates a value at a specific index and updates the accumulator field.
   * @param packedCounter The packed counter to modify.
   * @param index The index to set.
   * @param newValueAtIndex The new value to set at the given index.
   * @return The modified PackedCounter.
   */
  function setAtIndex(
    PackedCounter packedCounter,
    uint8 index,
    uint256 newValueAtIndex
  ) internal pure returns (PackedCounter) {
    if (newValueAtIndex > MAX_VAL) {
      revert PackedCounter_InvalidLength(newValueAtIndex);
    }

    uint256 rawPackedCounter = uint256(PackedCounter.unwrap(packedCounter));

    // Get current lengths (total and at index)
    uint256 accumulator = total(packedCounter);
    uint256 currentValueAtIndex = atIndex(packedCounter, index);

    // Compute the difference and update the total value
    unchecked {
      if (newValueAtIndex >= currentValueAtIndex) {
        accumulator += newValueAtIndex - currentValueAtIndex;
      } else {
        accumulator -= currentValueAtIndex - newValueAtIndex;
      }
    }

    // Set the new accumulated value and value at index
    // (7 bytes total length, 5 bytes per dynamic field)
    uint256 offset;
    unchecked {
      offset = ACC_BITS + VAL_BITS * index;
    }
    // Bitmask with 1s at the 5 bytes that form the value slot at the given index
    uint256 mask = uint256(type(uint40).max) << offset;

    // First set the last 7 bytes to 0, then set them to the new length
    rawPackedCounter = (rawPackedCounter & ~uint256(type(uint56).max)) | accumulator;

    // Zero out the value slot at the given index, then set the new value
    rawPackedCounter = (rawPackedCounter & ~mask) | ((newValueAtIndex << offset) & mask);

    return PackedCounter.wrap(bytes32(rawPackedCounter));
  }

  /**
   * @notice Unwrap a PackedCounter to its raw bytes32 representation.
   * @param packedCounter The packed counter to unwrap.
   * @return The raw bytes32 value of the PackedCounter.
   */
  function unwrap(PackedCounter packedCounter) internal pure returns (bytes32) {
    return PackedCounter.unwrap(packedCounter);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title ResourceId type definition and related utilities
 * @dev A ResourceId is a bytes32 data structure that consists of a
 * type and a name
 */
type ResourceId is bytes32;

/// @dev Number of bits reserved for the type in the ResourceId.
uint256 constant TYPE_BITS = 2 * 8;
/// @dev Number of bits reserved for the name in the ResourceId.
uint256 constant NAME_BITS = 32 * 8 - TYPE_BITS;

/// @dev Bitmask to extract the type from the ResourceId.
bytes32 constant TYPE_MASK = bytes32(hex"ffff");

/**
 * @title ResourceIdLib Library
 * @dev Provides functions to encode data into the ResourceId
 */
library ResourceIdLib {
  /**
   * @notice Encodes given typeId and name into a ResourceId.
   * @param typeId The type identifier to be encoded. Must be 2 bytes.
   * @param name The name to be encoded. Must be 30 bytes.
   * @return A ResourceId containing the encoded typeId and name.
   */
  function encode(bytes2 typeId, bytes30 name) internal pure returns (ResourceId) {
    return ResourceId.wrap(bytes32(typeId) | (bytes32(name) >> TYPE_BITS));
  }
}

/**
 * @title ResourceIdInstance Library
 * @dev Provides functions to extract data from a ResourceId.
 */
library ResourceIdInstance {
  /**
   * @notice Extracts the type identifier from a given ResourceId.
   * @param resourceId The ResourceId from which the type identifier should be extracted.
   * @return The extracted 2-byte type identifier.
   */
  function getType(ResourceId resourceId) internal pure returns (bytes2) {
    return bytes2(ResourceId.unwrap(resourceId));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

import { WORD_LAST_INDEX, BYTE_TO_BITS, MAX_TOTAL_FIELDS, MAX_DYNAMIC_FIELDS, LayoutOffsets } from "./constants.sol";

/**
 * @title Schema handling in Lattice
 * @dev Defines and handles the encoding/decoding of Schemas which describe the layout of data structures.
 * 2 bytes length of all the static (in size) fields in the schema
 * 1 byte for number of static size fields
 * 1 byte for number of dynamic size fields
 * 28 bytes for 28 schema types (MAX_DYNAMIC_FIELDS allows us to pack the lengths into 1 word)
 */
type Schema is bytes32;

using SchemaInstance for Schema global;

/**
 * @dev Static utility functions for handling Schemas.
 */
library SchemaLib {
  /// @dev Error raised when the provided schema has an invalid length.
  error SchemaLib_InvalidLength(uint256 length);

  /// @dev Error raised when a static type is placed after a dynamic type in a schema.
  error SchemaLib_StaticTypeAfterDynamicType();

  /**
   * @notice Encodes a given schema into a single bytes32.
   * @param _schema The list of SchemaTypes that constitute the schema.
   * @return The encoded Schema.
   */
  function encode(SchemaType[] memory _schema) internal pure returns (Schema) {
    if (_schema.length > MAX_TOTAL_FIELDS) revert SchemaLib_InvalidLength(_schema.length);
    uint256 schema;
    uint256 totalLength;
    uint256 dynamicFields;

    // Compute the length of the schema and the number of static fields
    // and store the schema types in the encoded schema
    for (uint256 i = 0; i < _schema.length; ) {
      uint256 staticByteLength = _schema[i].getStaticByteLength();

      if (staticByteLength == 0) {
        // Increase the dynamic field count if the field is dynamic
        // (safe because of the initial _schema.length check)
        unchecked {
          dynamicFields++;
        }
      } else if (dynamicFields > 0) {
        // Revert if we have seen a dynamic field before, but now we see a static field
        revert SchemaLib_StaticTypeAfterDynamicType();
      }

      unchecked {
        // (safe because 28 (max _schema.length) * 32 (max static length) < 2**16)
        totalLength += staticByteLength;
        // Sequentially store schema types after the first 4 bytes (which are reserved for length and field numbers)
        // (safe because of the initial _schema.length check)
        schema |= uint256(_schema[i]) << ((WORD_LAST_INDEX - 4 - i) * BYTE_TO_BITS);
        i++;
      }
    }

    // Require MAX_DYNAMIC_FIELDS
    if (dynamicFields > MAX_DYNAMIC_FIELDS) revert SchemaLib_InvalidLength(dynamicFields);

    // Get the static field count
    uint256 staticFields;
    unchecked {
      staticFields = _schema.length - dynamicFields;
    }

    // Store total static length in the first 2 bytes,
    // number of static fields in the 3rd byte,
    // number of dynamic fields in the 4th byte
    // (optimizer can handle this, no need for unchecked or single-line assignment)
    schema |= totalLength << LayoutOffsets.TOTAL_LENGTH;
    schema |= staticFields << LayoutOffsets.NUM_STATIC_FIELDS;
    schema |= dynamicFields << LayoutOffsets.NUM_DYNAMIC_FIELDS;

    return Schema.wrap(bytes32(schema));
  }
}

/**
 * @dev Instance utility functions for handling a Schema instance.
 */
library SchemaInstance {
  /**
   * @notice Get the length of static data for the given schema.
   * @param schema The schema to inspect.
   * @return The static data length.
   */
  function staticDataLength(Schema schema) internal pure returns (uint256) {
    return uint256(Schema.unwrap(schema)) >> LayoutOffsets.TOTAL_LENGTH;
  }

  /**
   * @notice Get the SchemaType at a given index in the schema.
   * @param schema The schema to inspect.
   * @param index The index of the SchemaType to retrieve.
   * @return The SchemaType at the given index.
   */
  function atIndex(Schema schema, uint256 index) internal pure returns (SchemaType) {
    unchecked {
      return SchemaType(uint8(uint256(schema.unwrap()) >> ((WORD_LAST_INDEX - 4 - index) * 8)));
    }
  }

  /**
   * @notice Get the number of static (fixed length) fields in the schema.
   * @param schema The schema to inspect.
   * @return The number of static fields.
   */
  function numStaticFields(Schema schema) internal pure returns (uint256) {
    return uint8(uint256(schema.unwrap()) >> LayoutOffsets.NUM_STATIC_FIELDS);
  }

  /**
   * @notice Get the number of dynamic length fields in the schema.
   * @param schema The schema to inspect.
   * @return The number of dynamic length fields.
   */
  function numDynamicFields(Schema schema) internal pure returns (uint256) {
    return uint8(uint256(schema.unwrap()) >> LayoutOffsets.NUM_DYNAMIC_FIELDS);
  }

  /**
   * @notice Get the total number of fields in the schema.
   * @param schema The schema to inspect.
   * @return The total number of fields.
   */
  function numFields(Schema schema) internal pure returns (uint256) {
    unchecked {
      return
        uint8(uint256(schema.unwrap()) >> LayoutOffsets.NUM_STATIC_FIELDS) +
        uint8(uint256(schema.unwrap()) >> LayoutOffsets.NUM_DYNAMIC_FIELDS);
    }
  }

  /**
   * @notice Checks if the provided schema is empty.
   * @param schema The schema to check.
   * @return true if the schema is empty, false otherwise.
   */
  function isEmpty(Schema schema) internal pure returns (bool) {
    return Schema.unwrap(schema) == bytes32(0);
  }

  /**
   * @notice Validates the given schema.
   * @param schema The schema to validate.
   * @param allowEmpty Determines if an empty schema is valid or not.
   */
  function validate(Schema schema, bool allowEmpty) internal pure {
    // Schema must not be empty
    if (!allowEmpty && schema.isEmpty()) revert SchemaLib.SchemaLib_InvalidLength(0);

    // Schema must have no more than MAX_DYNAMIC_FIELDS
    uint256 _numDynamicFields = schema.numDynamicFields();
    if (_numDynamicFields > MAX_DYNAMIC_FIELDS) revert SchemaLib.SchemaLib_InvalidLength(_numDynamicFields);

    uint256 _numStaticFields = schema.numStaticFields();
    // Schema must not have more than MAX_TOTAL_FIELDS in total
    uint256 _numTotalFields = _numStaticFields + _numDynamicFields;
    if (_numTotalFields > MAX_TOTAL_FIELDS) revert SchemaLib.SchemaLib_InvalidLength(_numTotalFields);

    // No static field can be after a dynamic field
    uint256 countStaticFields;
    uint256 countDynamicFields;
    for (uint256 i; i < _numTotalFields; ) {
      if (schema.atIndex(i).getStaticByteLength() > 0) {
        // Static field in dynamic part
        if (i >= _numStaticFields) revert SchemaLib.SchemaLib_StaticTypeAfterDynamicType();
        unchecked {
          countStaticFields++;
        }
      } else {
        // Dynamic field in static part
        if (i < _numStaticFields) revert SchemaLib.SchemaLib_StaticTypeAfterDynamicType();
        unchecked {
          countDynamicFields++;
        }
      }
      unchecked {
        i++;
      }
    }

    // Number of static fields must match
    if (countStaticFields != _numStaticFields) revert SchemaLib.SchemaLib_InvalidLength(countStaticFields);

    // Number of dynamic fields must match
    if (countDynamicFields != _numDynamicFields) revert SchemaLib.SchemaLib_InvalidLength(countDynamicFields);
  }

  /**
   * @notice Unwraps the schema to its underlying bytes32 representation.
   * @param schema The schema to unwrap.
   * @return The bytes32 representation of the schema.
   */
  function unwrap(Schema schema) internal pure returns (bytes32) {
    return Schema.unwrap(schema);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Memory } from "./Memory.sol";
import { DecodeSlice } from "./tightcoder/DecodeSlice.sol";

// Acknowledgements:
// Based on @dk1a's Slice.sol library (https://github.com/dk1a/solidity-stringutils/blob/main/src/Slice.sol)

// First 16 bytes are the pointer to the data, followed by 16 bytes of data length.
type Slice is uint256;

using SliceInstance for Slice global;
using DecodeSlice for Slice global;

/**
 * @title Static functions for Slice
 */
library SliceLib {
  error Slice_OutOfBounds(bytes data, uint256 start, uint256 end);

  uint256 constant MASK_LEN = uint256(type(uint128).max);
  uint256 constant MASK_PTR = uint256(type(uint128).max) << 128;

  /**
   * @notice Converts a bytes array to a slice (without copying data)
   * @param data The bytes array to be converted
   * @return A new Slice representing the bytes array
   */
  function fromBytes(bytes memory data) internal pure returns (Slice) {
    uint256 _pointer;
    assembly {
      _pointer := add(data, 0x20) // pointer to first data byte
    }

    // Pointer is stored in upper 128 bits, length is stored in lower 128 bits
    return Slice.wrap((_pointer << 128) | (data.length & MASK_LEN));
  }

  /**
   * @notice Subslice a bytes array using the given start index until the end of the array (without copying data)
   * @param data The bytes array to subslice
   * @param start The start index for the subslice
   * @return A new Slice representing the subslice
   */
  function getSubslice(bytes memory data, uint256 start) internal pure returns (Slice) {
    return getSubslice(data, start, data.length);
  }

  /**
   * @notice Subslice a bytes array using the given indexes (without copying data)
   * @dev The start index is inclusive, the end index is exclusive
   * @param data The bytes array to subslice
   * @param start The start index for the subslice
   * @param end The end index for the subslice
   * @return A new Slice representing the subslice
   */
  function getSubslice(bytes memory data, uint256 start, uint256 end) internal pure returns (Slice) {
    // TODO this check helps catch bugs and can eventually be removed
    if (!(start <= end && end <= data.length)) revert Slice_OutOfBounds(data, start, end);

    uint256 _pointer;
    assembly {
      _pointer := add(data, 0x20) // pointer to first data byte
    }

    _pointer += start;
    uint256 _len = end - start;

    // Pointer is stored in upper 128 bits, length is stored in lower 128 bits
    return Slice.wrap((_pointer << 128) | (_len & MASK_LEN));
  }
}

/**
 * @title Instance functions for Slice
 */
library SliceInstance {
  /**
   * @notice Returns the pointer to the start of a slice
   * @param self The slice whose pointer needs to be fetched
   * @return The pointer to the start of the slice
   */
  function pointer(Slice self) internal pure returns (uint256) {
    return Slice.unwrap(self) >> 128;
  }

  /**
   * @notice Returns the slice length in bytes
   * @param self The slice whose length needs to be fetched
   * @return The length of the slice
   */
  function length(Slice self) internal pure returns (uint256) {
    return Slice.unwrap(self) & SliceLib.MASK_LEN;
  }

  /**
   * @notice Converts a Slice to bytes
   * @dev This function internally manages the conversion of a slice into a bytes format.
   * @param self The Slice to be converted to bytes.
   * @return data The bytes representation of the provided Slice.
   */
  function toBytes(Slice self) internal pure returns (bytes memory data) {
    uint256 fromPointer = pointer(self);
    uint256 _length = length(self);

    // Allocate a new bytes array and get the pointer to it
    data = new bytes(_length);
    uint256 toPointer;
    assembly {
      toPointer := add(data, 32)
    }
    // Copy the slice contents to the array
    Memory.copy(fromPointer, toPointer, _length);
  }

  /**
   * @notice Converts a Slice to bytes32
   * @dev This function converts a slice into a fixed-length bytes32. Uses inline assembly for the conversion.
   * @param self The Slice to be converted to bytes32.
   * @return result The bytes32 representation of the provided Slice.
   */
  function toBytes32(Slice self) internal pure returns (bytes32 result) {
    uint256 memoryPointer = self.pointer();
    /// @solidity memory-safe-assembly
    assembly {
      result := mload(memoryPointer)
    }
    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { leftMask } from "./leftMask.sol";
import { Memory } from "./Memory.sol";

/**
 * @title Storage Library
 * @dev Provides functions for low-level storage manipulation, including storing and retrieving bytes.
 */
library Storage {
  /**
   * @notice Store a single word of data at a specific storage pointer.
   * @param storagePointer The location to store the data.
   * @param data The 32-byte word of data to store.
   */
  function store(uint256 storagePointer, bytes32 data) internal {
    assembly {
      sstore(storagePointer, data)
    }
  }

  /**
   * @notice Store bytes of data at a specific storage pointer and offset.
   * @param storagePointer The base storage location.
   * @param offset Offset within the storage location.
   * @param data Bytes to store.
   */
  function store(uint256 storagePointer, uint256 offset, bytes memory data) internal {
    store(storagePointer, offset, Memory.dataPointer(data), data.length);
  }

  /**
   * @notice Stores raw bytes to storage at a given pointer, offset, and length, keeping the rest of the word intact.
   * @param storagePointer The base storage location.
   * @param offset Offset within the storage location.
   * @param memoryPointer Pointer to the start of the data in memory.
   * @param length Length of the data in bytes.
   */
  function store(uint256 storagePointer, uint256 offset, uint256 memoryPointer, uint256 length) internal {
    if (offset > 0) {
      // Support offsets that are greater than 32 bytes by incrementing the storagePointer and decrementing the offset
      if (offset >= 32) {
        unchecked {
          storagePointer += offset / 32;
          offset %= 32;
        }
      }

      // For the first word, if there is an offset, apply a mask to beginning
      if (offset > 0) {
        // Get the word's remaining length after the offset
        uint256 wordRemainder;
        // (safe because of `offset %= 32` at the start)
        unchecked {
          wordRemainder = 32 - offset;
        }

        uint256 mask = leftMask(length);
        /// @solidity memory-safe-assembly
        assembly {
          // Load data from memory and offset it to match storage
          let bitOffset := mul(offset, 8)
          mask := shr(bitOffset, mask)
          let offsetData := shr(bitOffset, mload(memoryPointer))

          sstore(
            storagePointer,
            or(
              // Store the middle part
              and(offsetData, mask),
              // Preserve the surrounding parts
              and(sload(storagePointer), not(mask))
            )
          )
        }
        // Return if done
        if (length <= wordRemainder) return;

        // Advance pointers
        // (safe because of `length <= wordRemainder` earlier)
        unchecked {
          storagePointer += 1;
          memoryPointer += wordRemainder;
          length -= wordRemainder;
        }
      }
    }

    // Store full words
    while (length >= 32) {
      /// @solidity memory-safe-assembly
      assembly {
        sstore(storagePointer, mload(memoryPointer))
      }
      unchecked {
        storagePointer += 1;
        memoryPointer += 32;
        length -= 32;
      }
    }

    // For the last partial word, apply a mask to the end
    if (length > 0) {
      uint256 mask = leftMask(length);
      /// @solidity memory-safe-assembly
      assembly {
        sstore(
          storagePointer,
          or(
            // store the left part
            and(mload(memoryPointer), mask),
            // preserve the right part
            and(sload(storagePointer), not(mask))
          )
        )
      }
    }
  }

  /**
   * @notice Set multiple storage locations to zero.
   * @param storagePointer The starting storage location.
   * @param length The number of storage locations to set to zero.
   */
  function zero(uint256 storagePointer, uint256 length) internal {
    // Ceil division to round up to the nearest word
    uint256 limit = storagePointer + (length + 31) / 32;
    while (storagePointer < limit) {
      /// @solidity memory-safe-assembly
      assembly {
        sstore(storagePointer, 0)
        storagePointer := add(storagePointer, 1)
      }
    }
  }

  /**
   * @notice Load a single word of data from a specific storage pointer.
   * @param storagePointer The location to load the data from.
   * @return word The loaded 32-byte word of data.
   */
  function load(uint256 storagePointer) internal view returns (bytes32 word) {
    assembly {
      word := sload(storagePointer)
    }
  }

  /**
   * @notice Load raw bytes from storage at a given pointer, offset, and length.
   * @param storagePointer The base storage location.
   * @param length Length of the data in bytes.
   * @param offset Offset within the storage location.
   * @return result The loaded bytes of data.
   */
  function load(uint256 storagePointer, uint256 length, uint256 offset) internal view returns (bytes memory result) {
    uint256 memoryPointer;
    /// @solidity memory-safe-assembly
    assembly {
      // Solidity's YulUtilFunctions::roundUpFunction
      function round_up_to_mul_of_32(value) -> _result {
        _result := and(add(value, 31), not(31))
      }

      // Allocate memory
      result := mload(0x40)
      memoryPointer := add(result, 0x20)
      mstore(0x40, round_up_to_mul_of_32(add(memoryPointer, length)))
      // Store length
      mstore(result, length)
    }
    load(storagePointer, length, offset, memoryPointer);
    return result;
  }

  /**
   * @notice Append raw bytes from storage at a given pointer, offset, and length to a specific memory pointer.
   * @param storagePointer The base storage location.
   * @param length Length of the data in bytes.
   * @param offset Offset within the storage location.
   * @param memoryPointer Pointer to the location in memory to append the data.
   */
  function load(uint256 storagePointer, uint256 length, uint256 offset, uint256 memoryPointer) internal view {
    if (offset > 0) {
      // Support offsets that are greater than 32 bytes by incrementing the storagePointer and decrementing the offset
      if (offset >= 32) {
        unchecked {
          storagePointer += offset / 32;
          offset %= 32;
        }
      }

      // For the first word, if there is an offset, apply a mask to beginning
      if (offset > 0) {
        // Get the word's remaining length after the offset
        uint256 wordRemainder;
        // (safe because of `offset %= 32` at the start)
        unchecked {
          wordRemainder = 32 - offset;
        }

        uint256 mask = leftMask(wordRemainder);
        /// @solidity memory-safe-assembly
        assembly {
          // Load data from storage and offset it to match memory
          let offsetData := shl(mul(offset, 8), sload(storagePointer))

          mstore(
            memoryPointer,
            or(
              // store the middle part
              and(offsetData, mask),
              // preserve the surrounding parts
              and(mload(memoryPointer), not(mask))
            )
          )
        }
        // Return if done
        if (length <= wordRemainder) return;

        // Advance pointers
        // (safe because of `length <= wordRemainder` earlier)
        unchecked {
          storagePointer += 1;
          memoryPointer += wordRemainder;
          length -= wordRemainder;
        }
      }
    }

    // Load full words
    while (length >= 32) {
      /// @solidity memory-safe-assembly
      assembly {
        mstore(memoryPointer, sload(storagePointer))
      }
      unchecked {
        storagePointer += 1;
        memoryPointer += 32;
        length -= 32;
      }
    }

    // For the last partial word, apply a mask to the end
    if (length > 0) {
      uint256 mask = leftMask(length);
      /// @solidity memory-safe-assembly
      assembly {
        mstore(
          memoryPointer,
          or(
            // store the left part
            and(sload(storagePointer), mask),
            // preserve the right part
            and(mload(memoryPointer), not(mask))
          )
        )
      }
    }
  }

  /**
   * @notice Load up to 32 bytes from storage at a given pointer and offset.
   * @dev Since fields are tightly packed, they can span more than one slot.
   * Since the they're max 32 bytes, they can span at most 2 slots.
   * @param storagePointer The base storage location.
   * @param length Length of the data in bytes.
   * @param offset Offset within the storage location.
   * @return result The loaded bytes, left-aligned bytes. Bytes beyond the length are zeroed.
   */
  function loadField(uint256 storagePointer, uint256 length, uint256 offset) internal view returns (bytes32 result) {
    if (offset >= 32) {
      unchecked {
        storagePointer += offset / 32;
        offset %= 32;
      }
    }

    // Extra data past length is not truncated
    // This assumes that the caller will handle the overflow bits appropriately
    assembly {
      result := shl(mul(offset, 8), sload(storagePointer))
    }

    uint256 wordRemainder;
    // (safe because of `offset %= 32` at the start)
    unchecked {
      wordRemainder = 32 - offset;
    }

    // Read from the next slot if field spans 2 slots
    if (length > wordRemainder) {
      assembly {
        result := or(result, shr(mul(wordRemainder, 8), sload(add(storagePointer, 1))))
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { STORE_VERSION } from "./version.sol";
import { Bytes } from "./Bytes.sol";
import { Storage } from "./Storage.sol";
import { Memory } from "./Memory.sol";
import { FieldLayout, FieldLayoutLib } from "./FieldLayout.sol";
import { Schema, SchemaLib } from "./Schema.sol";
import { PackedCounter } from "./PackedCounter.sol";
import { Slice, SliceLib } from "./Slice.sol";
import { StoreHooks, Tables, TablesTableId, ResourceIds, StoreHooksTableId } from "./codegen/index.sol";
import { _fieldLayout as TablesTableFieldLayout } from "./codegen/tables/Tables.sol";
import { IStoreErrors } from "./IStoreErrors.sol";
import { IStoreHook } from "./IStoreHook.sol";
import { StoreSwitch } from "./StoreSwitch.sol";
import { Hook, HookLib } from "./Hook.sol";
import { BEFORE_SET_RECORD, AFTER_SET_RECORD, BEFORE_SPLICE_STATIC_DATA, AFTER_SPLICE_STATIC_DATA, BEFORE_SPLICE_DYNAMIC_DATA, AFTER_SPLICE_DYNAMIC_DATA, BEFORE_DELETE_RECORD, AFTER_DELETE_RECORD } from "./storeHookTypes.sol";
import { ResourceId, ResourceIdInstance } from "./ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "./storeResourceTypes.sol";

/**
 * @title StoreCore Library
 * @notice This library includes implementations for all IStore methods and events related to the store actions.
 */
library StoreCore {
  using ResourceIdInstance for ResourceId;
  /**
   * @notice Emitted when a new record is set in the store.
   * @param tableId The ID of the table where the record is set.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   */
  event Store_SetRecord(
    ResourceId indexed tableId,
    bytes32[] keyTuple,
    bytes staticData,
    PackedCounter encodedLengths,
    bytes dynamicData
  );

  /**
   * @notice Emitted when static data in the store is spliced.
   * @dev In static data, data is always overwritten starting at the start position,
   * so the total length of the data remains the same and no data is shifted.
   * @param tableId The ID of the table where the data is spliced.
   * @param keyTuple An array representing the key for the record.
   * @param start The start position in bytes for the splice operation.
   * @param data The data to write to the static data of the record at the start byte.
   */
  event Store_SpliceStaticData(ResourceId indexed tableId, bytes32[] keyTuple, uint48 start, bytes data);

  /**
   * @notice Emitted when dynamic data in the store is spliced.
   * @param tableId The ID of the table where the data is spliced.
   * @param keyTuple An array representing the composite key for the record.
   * @param start The start position in bytes for the splice operation.
   * @param deleteCount The number of bytes to delete in the splice operation.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param data The data to insert into the dynamic data of the record at the start byte.
   */
  event Store_SpliceDynamicData(
    ResourceId indexed tableId,
    bytes32[] keyTuple,
    uint48 start,
    uint40 deleteCount,
    PackedCounter encodedLengths,
    bytes data
  );

  /**
   * @notice Emitted when a record is deleted from the store.
   * @param tableId The ID of the table where the record is deleted.
   * @param keyTuple An array representing the composite key for the record.
   */
  event Store_DeleteRecord(ResourceId indexed tableId, bytes32[] keyTuple);

  /**
   * @notice Initialize the store address in StoreSwitch.
   * @dev Consumers must call this function in their constructor.
   * StoreSwitch uses the storeAddress to decide where to write data to.
   * If StoreSwitch is called in the context of a Store contract (storeAddress == address(this)),
   * StoreSwitch uses internal methods to write data instead of external calls.
   */
  function initialize() internal {
    StoreSwitch.setStoreAddress(address(this));
  }

  /**
   * @notice Register core tables in the store.
   * @dev Consumers must call this function in their constructor before setting
   * any table data to allow indexers to decode table events.
   */
  function registerCoreTables() internal {
    // Register core tables
    Tables.register();
    StoreHooks.register();
    ResourceIds.register();
  }

  /************************************************************************
   *
   *    SCHEMA
   *
   ************************************************************************/

  /**
   * @notice Get the field layout for the given table ID.
   * @param tableId The ID of the table for which to get the field layout.
   * @return The field layout for the given table ID.
   */
  function getFieldLayout(ResourceId tableId) internal view returns (FieldLayout) {
    // Explicit check for the Tables table to solve the bootstraping issue
    // of the Tables table not having a field layout before it is registered
    // since the field layout is stored in the Tables table.
    if (ResourceId.unwrap(tableId) == ResourceId.unwrap(TablesTableId)) {
      return TablesTableFieldLayout;
    }
    return
      FieldLayout.wrap(
        Storage.loadField({
          storagePointer: StoreCoreInternal._getStaticDataLocation(TablesTableId, ResourceId.unwrap(tableId)),
          length: 32,
          offset: 0
        })
      );
  }

  /**
   * @notice Get the key schema for the given table ID.
   * @dev Reverts if the table ID is not registered.
   * @param tableId The ID of the table for which to get the key schema.
   * @return keySchema The key schema for the given table ID.
   */
  function getKeySchema(ResourceId tableId) internal view returns (Schema keySchema) {
    keySchema = Tables._getKeySchema(tableId);
    // key schemas can be empty for singleton tables, so we can't depend on key schema for table check
    if (!ResourceIds._getExists(tableId)) {
      revert IStoreErrors.Store_TableNotFound(tableId, string(abi.encodePacked(tableId)));
    }
  }

  /**
   * @notice Get the value schema for the given table ID.
   * @dev Reverts if the table ID is not registered.
   * @param tableId The ID of the table for which to get the value schema.
   * @return valueSchema The value schema for the given table ID.
   */
  function getValueSchema(ResourceId tableId) internal view returns (Schema valueSchema) {
    valueSchema = Tables._getValueSchema(tableId);
    if (valueSchema.isEmpty()) {
      revert IStoreErrors.Store_TableNotFound(tableId, string(abi.encodePacked(tableId)));
    }
  }

  /**
   * @notice Register a new table with the given configuration.
   * @dev This method reverts if
   * - The table ID is not of type RESOURCE_TABLE or RESOURCE_OFFCHAIN_TABLE.
   * - The field layout is invalid.
   * - The key schema is invalid.
   * - The value schema is invalid.
   * - The number of key names does not match the number of key schema types.
   * - The number of field names does not match the number of field layout fields.
   * @param tableId The ID of the table to register.
   * @param fieldLayout The field layout of the table.
   * @param keySchema The key schema of the table.
   * @param valueSchema The value schema of the table.
   * @param keyNames The names of the keys in the table.
   * @param fieldNames The names of the fields in the table.
   */
  function registerTable(
    ResourceId tableId,
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    string[] memory keyNames,
    string[] memory fieldNames
  ) internal {
    // Verify the table ID is of type RESOURCE_TABLE
    if (tableId.getType() != RESOURCE_TABLE && tableId.getType() != RESOURCE_OFFCHAIN_TABLE) {
      revert IStoreErrors.Store_InvalidResourceType(RESOURCE_TABLE, tableId, string(abi.encodePacked(tableId)));
    }

    // Verify the field layout is valid
    fieldLayout.validate({ allowEmpty: false });

    // Verify the schema is valid
    keySchema.validate({ allowEmpty: true });
    valueSchema.validate({ allowEmpty: false });

    // Verify the number of key names matches the number of key schema types
    if (keyNames.length != keySchema.numFields()) {
      revert IStoreErrors.Store_InvalidKeyNamesLength(keySchema.numFields(), keyNames.length);
    }

    // Verify the number of value names
    if (fieldNames.length != fieldLayout.numFields()) {
      revert IStoreErrors.Store_InvalidFieldNamesLength(fieldLayout.numFields(), fieldNames.length);
    }

    // Verify the number of value schema types
    if (valueSchema.numFields() != fieldLayout.numFields()) {
      revert IStoreErrors.Store_InvalidValueSchemaLength(fieldLayout.numFields(), valueSchema.numFields());
    }

    // Verify there is no resource with this ID yet
    if (ResourceIds._getExists(tableId)) {
      revert IStoreErrors.Store_TableAlreadyExists(tableId, string(abi.encodePacked(tableId)));
    }

    // Register the table metadata
    Tables._set(tableId, fieldLayout, keySchema, valueSchema, abi.encode(keyNames), abi.encode(fieldNames));

    // Register the table ID
    ResourceIds._setExists(tableId, true);
  }

  /************************************************************************
   *
   *    REGISTER HOOKS
   *
   ************************************************************************/

  /**
   * @notice Register hooks to be called when a record or field is set or deleted.
   * @dev This method reverts for all resource IDs other than tables.
   * Hooks are not supported for offchain tables.
   * @param tableId The ID of the table to register the hook for.
   * @param hookAddress The address of the hook contract to register.
   * @param enabledHooksBitmap The bitmap of enabled hooks.
   */
  function registerStoreHook(ResourceId tableId, IStoreHook hookAddress, uint8 enabledHooksBitmap) internal {
    // Hooks are only supported for tables, not for offchain tables
    if (tableId.getType() != RESOURCE_TABLE) {
      revert IStoreErrors.Store_InvalidResourceType(RESOURCE_TABLE, tableId, string(abi.encodePacked(tableId)));
    }

    StoreHooks.push(tableId, Hook.unwrap(HookLib.encode(address(hookAddress), enabledHooksBitmap)));
  }

  /**
   * @notice Unregister a hook from the given table ID.
   * @param tableId The ID of the table to unregister the hook from.
   * @param hookAddress The address of the hook to unregister.
   */
  function unregisterStoreHook(ResourceId tableId, IStoreHook hookAddress) internal {
    HookLib.filterListByAddress(StoreHooksTableId, tableId, address(hookAddress));
  }

  /************************************************************************
   *
   *    SET DATA
   *
   ************************************************************************/

  /**
   * @notice Set a full record for the given table ID and key tuple.
   * @dev Calling this method emits a Store_SetRecord event.
   * This method internally calls another overload of setRecord by fetching the field layout for the given table ID.
   * If the field layout is available to the caller, it is recommended to use the other overload to avoid an additional storage read.
   * @param tableId The ID of the table to set the record for.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   */
  function setRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    bytes memory staticData,
    PackedCounter encodedLengths,
    bytes memory dynamicData
  ) internal {
    setRecord(tableId, keyTuple, staticData, encodedLengths, dynamicData, getFieldLayout(tableId));
  }

  /**
   * @notice Set a full data record for the given table ID, key tuple, and field layout.
   * @dev For onchain tables, the method emits a `Store_SetRecord` event, updates the data in storage,
   * calls `onBeforeSetRecord` hooks before actually modifying the state, and calls `onAfterSetRecord`
   * hooks after modifying the state. For offchain tables, the method returns early after emitting the
   * event without calling hooks or modifying the state.
   * @param tableId The ID of the table to set the record for.
   * @param keyTuple An array representing the composite key for the record.
   * @param staticData The static data of the record.
   * @param encodedLengths The encoded lengths of the dynamic data of the record.
   * @param dynamicData The dynamic data of the record.
   * @param fieldLayout The field layout for the record.
   */
  function setRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    bytes memory staticData,
    PackedCounter encodedLengths,
    bytes memory dynamicData,
    FieldLayout fieldLayout
  ) internal {
    // Emit event to notify indexers
    emit Store_SetRecord(tableId, keyTuple, staticData, encodedLengths, dynamicData);

    // Early return if the table is an offchain table
    if (tableId.getType() != RESOURCE_TABLE) {
      return;
    }

    // Call onBeforeSetRecord hooks (before actually modifying the state, so observers have access to the previous state if needed)
    bytes21[] memory hooks = StoreHooks._get(tableId);
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(BEFORE_SET_RECORD)) {
        IStoreHook(hook.getAddress()).onBeforeSetRecord(
          tableId,
          keyTuple,
          staticData,
          encodedLengths,
          dynamicData,
          fieldLayout
        );
      }
    }

    // Store the static data at the static data location
    uint256 staticDataLocation = StoreCoreInternal._getStaticDataLocation(tableId, keyTuple);
    uint256 memoryPointer = Memory.dataPointer(staticData);
    Storage.store({
      storagePointer: staticDataLocation,
      offset: 0,
      memoryPointer: memoryPointer,
      length: staticData.length
    });

    // Set the dynamic data if there are dynamic fields
    if (fieldLayout.numDynamicFields() > 0) {
      // Store the dynamic data length at the dynamic data length location
      uint256 dynamicDataLengthLocation = StoreCoreInternal._getDynamicDataLengthLocation(tableId, keyTuple);
      Storage.store({ storagePointer: dynamicDataLengthLocation, data: encodedLengths.unwrap() });

      // Move the memory pointer to the start of the dynamic data
      memoryPointer = Memory.dataPointer(dynamicData);

      // For every dynamic element, slice off the dynamic data and store it at the dynamic location
      uint256 dynamicDataLocation;
      uint256 dynamicDataLength;
      for (uint8 i; i < fieldLayout.numDynamicFields(); ) {
        dynamicDataLocation = StoreCoreInternal._getDynamicDataLocation(tableId, keyTuple, i);
        dynamicDataLength = encodedLengths.atIndex(i);
        Storage.store({
          storagePointer: dynamicDataLocation,
          offset: 0,
          memoryPointer: memoryPointer,
          length: dynamicDataLength
        });
        memoryPointer += dynamicDataLength; // move the memory pointer to the start of the next dynamic data
        unchecked {
          i++;
        }
      }
    }

    // Call onAfterSetRecord hooks (after modifying the state)
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(AFTER_SET_RECORD)) {
        IStoreHook(hook.getAddress()).onAfterSetRecord(
          tableId,
          keyTuple,
          staticData,
          encodedLengths,
          dynamicData,
          fieldLayout
        );
      }
    }
  }

  /**
   * @notice Splice the static data for the given table ID and key tuple.
   * @dev This method emits a `Store_SpliceStaticData` event, updates the data in storage, and calls
   * `onBeforeSpliceStaticData` and `onAfterSpliceStaticData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to splice the static data for.
   * @param keyTuple An array representing the composite key for the record.
   * @param start The start position in bytes for the splice operation.
   * @param data The data to write to the static data of the record at the start byte.
   */
  function spliceStaticData(ResourceId tableId, bytes32[] memory keyTuple, uint48 start, bytes memory data) internal {
    uint256 location = StoreCoreInternal._getStaticDataLocation(tableId, keyTuple);

    // Emit event to notify offchain indexers
    emit StoreCore.Store_SpliceStaticData({ tableId: tableId, keyTuple: keyTuple, start: start, data: data });

    // Early return if the table is an offchain table
    if (tableId.getType() != RESOURCE_TABLE) {
      return;
    }

    // Call onBeforeSpliceStaticData hooks (before actually modifying the state, so observers have access to the previous state if needed)
    bytes21[] memory hooks = StoreHooks._get(tableId);
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(BEFORE_SPLICE_STATIC_DATA)) {
        IStoreHook(hook.getAddress()).onBeforeSpliceStaticData({
          tableId: tableId,
          keyTuple: keyTuple,
          start: start,
          data: data
        });
      }
    }

    // Store the provided value in storage
    Storage.store({ storagePointer: location, offset: start, data: data });

    // Call onAfterSpliceStaticData hooks
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(AFTER_SPLICE_STATIC_DATA)) {
        IStoreHook(hook.getAddress()).onAfterSpliceStaticData({
          tableId: tableId,
          keyTuple: keyTuple,
          start: start,
          data: data
        });
      }
    }
  }

  /**
   * @notice Splice the dynamic data for the given table ID, key tuple, and dynamic field index.
   * @dev This method emits a `Store_SpliceDynamicData` event, updates the data in storage, and calls
   * `onBeforeSpliceDynamicData` and `onAfterSpliceDynamicData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to splice the dynamic data for.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to splice. (Dynamic field index = field index - number of static fields)
   * @param startWithinField The start position within the field for the splice operation.
   * @param deleteCount The number of bytes to delete in the splice operation.
   * @param data The data to insert into the dynamic data of the record at the start byte.
   */
  function spliceDynamicData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    bytes memory data
  ) internal {
    StoreCoreInternal._spliceDynamicData({
      tableId: tableId,
      keyTuple: keyTuple,
      dynamicFieldIndex: dynamicFieldIndex,
      startWithinField: startWithinField,
      deleteCount: deleteCount,
      data: data,
      previousEncodedLengths: StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple)
    });
  }

  /**
   * @notice Set data for a field at the given index in a table with the given tableId, key tuple, and value field layout.
   * @dev This method internally calls another overload of setField by fetching the field layout for the given table ID.
   * If the field layout is available to the caller, it is recommended to use the other overload to avoid an additional storage read.
   * This function emits a `Store_SpliceStaticData` or `Store_SpliceDynamicData` event and calls the corresponding hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to set the field for.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the field.
   */
  function setField(ResourceId tableId, bytes32[] memory keyTuple, uint8 fieldIndex, bytes memory data) internal {
    setField(tableId, keyTuple, fieldIndex, data, getFieldLayout(tableId));
  }

  /**
   * @notice Set data for a field at the given index in a table with the given tableId, key tuple, and value field layout.
   * @dev This method internally calls to `setStaticField` or `setDynamicField` based on the field index and layout.
   * Calling `setStaticField` or `setDynamicField` directly is recommended if the caller is aware of the field layout.
   * This function emits a `Store_SpliceStaticData` or `Store_SpliceDynamicData` event, updates the data in storage,
   * and calls the corresponding hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to set the field for.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the field.
   * @param fieldLayout The field layout for the record.
   */
  function setField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    bytes memory data,
    FieldLayout fieldLayout
  ) internal {
    if (fieldIndex < fieldLayout.numStaticFields()) {
      setStaticField(tableId, keyTuple, fieldIndex, data, fieldLayout);
    } else {
      setDynamicField(tableId, keyTuple, fieldIndex - uint8(fieldLayout.numStaticFields()), data);
    }
  }

  /**
   * @notice Set a static field for the given table ID, key tuple, field index, and field layout.
   * @dev This method emits a `Store_SpliceStaticData` event, updates the data in storage and calls the
   * `onBeforeSpliceStaticData` and `onAfterSpliceStaticData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to set the static field for.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the static field.
   * @param fieldLayout The field layout for the record.
   */
  function setStaticField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    bytes memory data,
    FieldLayout fieldLayout
  ) internal {
    spliceStaticData({
      tableId: tableId,
      keyTuple: keyTuple,
      start: uint48(StoreCoreInternal._getStaticDataOffset(fieldLayout, fieldIndex)),
      data: data
    });
  }

  /**
   * @notice Set a dynamic field for the given table ID, key tuple, and dynamic field index.
   * @dev This method emits a `Store_SpliceDynamicData` event, updates the data in storage and calls the
   * `onBeforeSpliceDynamicaData` and `onAfterSpliceDynamicData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to set the dynamic field for.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to set. (Dynamic field index = field index - number of static fields).
   * @param data The data to set for the dynamic field.
   */
  function setDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    bytes memory data
  ) internal {
    // Load the previous length of the field to set from storage to compute how much data to delete
    PackedCounter previousEncodedLengths = StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple);
    uint40 previousFieldLength = uint40(previousEncodedLengths.atIndex(dynamicFieldIndex));

    StoreCoreInternal._spliceDynamicData({
      tableId: tableId,
      keyTuple: keyTuple,
      dynamicFieldIndex: dynamicFieldIndex,
      startWithinField: 0,
      deleteCount: previousFieldLength,
      data: data,
      previousEncodedLengths: previousEncodedLengths
    });
  }

  /**
   * @notice Delete a record for the given table ID and key tuple.
   * @dev This method internally calls another overload of deleteRecord by fetching the field layout for the given table ID.
   * This method deletes static data and sets the dynamic data length to 0, but does not
   * actually modify the dynamic data. It emits a `Store_DeleteRecord` event and emits the
   * `onBeforeDeleteRecord` and `onAfterDeleteRecord` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to delete the record from.
   * @param keyTuple An array representing the composite key for the record.
   */
  function deleteRecord(ResourceId tableId, bytes32[] memory keyTuple) internal {
    deleteRecord(tableId, keyTuple, getFieldLayout(tableId));
  }

  /**
   * @notice Delete a record for the given table ID and key tuple.
   * @dev This method deletes static data and sets the dynamic data length to 0, but does not
   * actually modify the dynamic data. It emits a `Store_DeleteRecord` event and emits the
   * `onBeforeDeleteRecord` and `onAfterDeleteRecord` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to delete the record from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldLayout The field layout for the record.
   */
  function deleteRecord(ResourceId tableId, bytes32[] memory keyTuple, FieldLayout fieldLayout) internal {
    // Emit event to notify indexers
    emit Store_DeleteRecord(tableId, keyTuple);

    // Early return if the table is an offchain table
    if (tableId.getType() != RESOURCE_TABLE) {
      return;
    }

    // Call onBeforeDeleteRecord hooks (before actually modifying the state, so observers have access to the previous state if needed)
    bytes21[] memory hooks = StoreHooks._get(tableId);
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(BEFORE_DELETE_RECORD)) {
        IStoreHook(hook.getAddress()).onBeforeDeleteRecord(tableId, keyTuple, fieldLayout);
      }
    }

    // Delete static data
    uint256 staticDataLocation = StoreCoreInternal._getStaticDataLocation(tableId, keyTuple);
    Storage.store({ storagePointer: staticDataLocation, offset: 0, data: new bytes(fieldLayout.staticDataLength()) });

    // If there are dynamic fields, set the dynamic data length to 0.
    // We don't need to delete the dynamic data because it will be overwritten when a new record is set.
    if (fieldLayout.numDynamicFields() > 0) {
      uint256 dynamicDataLengthLocation = StoreCoreInternal._getDynamicDataLengthLocation(tableId, keyTuple);
      Storage.zero({ storagePointer: dynamicDataLengthLocation, length: 32 });
    }

    // Call onAfterDeleteRecord hooks
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(AFTER_DELETE_RECORD)) {
        IStoreHook(hook.getAddress()).onAfterDeleteRecord(tableId, keyTuple, fieldLayout);
      }
    }
  }

  /**
   * @notice Push data to a field at the dynamic field index in a table with the given table ID and key tuple.
   * @dev This method emits a `Store_SpliceDynamicData` event, updates the data in storage and calls the
   * `onBeforeSpliceDynamicData` and `onAfterSpliceDynamicData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to push data to the dynamic field.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to push data to.
   * @param dataToPush The data to push to the dynamic field.
   */
  function pushToDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    bytes memory dataToPush
  ) internal {
    // Load the previous length of the field to set from storage to compute where to start to push
    PackedCounter previousEncodedLengths = StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple);
    uint40 previousFieldLength = uint40(previousEncodedLengths.atIndex(dynamicFieldIndex));

    // Splice the dynamic data
    StoreCoreInternal._spliceDynamicData({
      tableId: tableId,
      keyTuple: keyTuple,
      dynamicFieldIndex: dynamicFieldIndex,
      startWithinField: uint40(previousFieldLength),
      deleteCount: 0,
      data: dataToPush,
      previousEncodedLengths: previousEncodedLengths
    });
  }

  /**
   * @notice Pop data from a field at the dynamic field index in a table with the given table ID and key tuple.
   * @dev This method emits a `Store_SpliceDynamicData` event, updates the data in storage and calls the
   * `onBeforeSpliceDynamicData` and `onAfterSpliceDynamicData` hooks.
   * For offchain tables, it returns early after emitting the event.
   * @param tableId The ID of the table to pop data from the dynamic field.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to pop data from.
   * @param byteLengthToPop The byte length to pop from the dynamic field.
   */
  function popFromDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint256 byteLengthToPop
  ) internal {
    // Load the previous length of the field to set from storage to compute where to start to push
    PackedCounter previousEncodedLengths = StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple);
    uint40 previousFieldLength = uint40(previousEncodedLengths.atIndex(dynamicFieldIndex));

    // Splice the dynamic data
    StoreCoreInternal._spliceDynamicData({
      tableId: tableId,
      keyTuple: keyTuple,
      dynamicFieldIndex: dynamicFieldIndex,
      startWithinField: uint40(previousFieldLength - byteLengthToPop),
      deleteCount: uint40(byteLengthToPop),
      data: new bytes(0),
      previousEncodedLengths: previousEncodedLengths
    });
  }

  /************************************************************************
   *
   *    GET DATA
   *
   ************************************************************************/

  /**
   * @notice Get the full record (all fields, static and dynamic data) for the given table ID and key tuple.
   * @dev This function internally calls another overload of `getRecord`, loading the field layout from storage.
   * If the field layout is available to the caller, it is recommended to use the other overload to avoid an additional storage read.
   * @param tableId The ID of the table to get the record from.
   * @param keyTuple An array representing the composite key for the record.
   * @return staticData The static data of the record.
   * @return encodedLengths The encoded lengths of the dynamic data of the record.
   * @return dynamicData The dynamic data of the record.
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple
  ) internal view returns (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData) {
    return getRecord(tableId, keyTuple, getFieldLayout(tableId));
  }

  /**
   * @notice Get the full record (all fields, static and dynamic data) for the given table ID and key tuple, with the given field layout.
   * @param tableId The ID of the table to get the record from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldLayout The field layout for the record.
   * @return staticData The static data of the record.
   * @return encodedLengths The encoded lengths of the dynamic data of the record.
   * @return dynamicData The dynamic data of the record.
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    FieldLayout fieldLayout
  ) internal view returns (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData) {
    // Get the static data length
    uint256 staticLength = fieldLayout.staticDataLength();

    // Load the static data from storage
    staticData = StoreCoreInternal._getStaticData(tableId, keyTuple, staticLength);

    // Load the dynamic data if there are dynamic fields
    uint256 numDynamicFields = fieldLayout.numDynamicFields();
    if (numDynamicFields > 0) {
      // Load the encoded dynamic data length
      encodedLengths = StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple);

      // Append dynamic data
      dynamicData = new bytes(encodedLengths.total());
      uint256 memoryPointer = Memory.dataPointer(dynamicData);

      for (uint8 i; i < numDynamicFields; i++) {
        uint256 dynamicDataLocation = StoreCoreInternal._getDynamicDataLocation(tableId, keyTuple, i);
        uint256 length = encodedLengths.atIndex(i);
        Storage.load({ storagePointer: dynamicDataLocation, length: length, offset: 0, memoryPointer: memoryPointer });
        // Advance memoryPointer by the length of this dynamic field
        memoryPointer += length;
      }
    }
  }

  /**
   * @notice Get a single field from the given table ID and key tuple.
   * @dev This function internally calls another overload of `getField`, loading the field layout from storage.
   * @param tableId The ID of the table to get the field from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get.
   * @return The data of the field.
   */
  function getField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex
  ) internal view returns (bytes memory) {
    return getField(tableId, keyTuple, fieldIndex, getFieldLayout(tableId));
  }

  /**
   * @notice Get a single field from the given table ID and key tuple, with the given field layout.
   * @param tableId The ID of the table to get the field from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get.
   * @param fieldLayout The field layout for the record.
   * @return The data of the field.
   */
  function getField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (bytes memory) {
    if (fieldIndex < fieldLayout.numStaticFields()) {
      return StoreCoreInternal._getStaticFieldBytes(tableId, keyTuple, fieldIndex, fieldLayout);
    } else {
      return getDynamicField(tableId, keyTuple, fieldIndex - uint8(fieldLayout.numStaticFields()));
    }
  }

  /**
   * @notice Get a single static field from the given table ID and key tuple, with the given value field layout.
   * @dev The field value is left-aligned in the returned bytes32, the rest of the word is not zeroed out.
   * Consumers are expected to truncate the returned value as needed.
   * @param tableId The ID of the table to get the static field from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get.
   * @param fieldLayout The field layout for the record.
   * @return The data of the static field.
   */
  function getStaticField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (bytes32) {
    // Get the length, storage location and offset of the static field
    // and load the data from storage
    return
      Storage.loadField({
        storagePointer: StoreCoreInternal._getStaticDataLocation(tableId, keyTuple),
        length: fieldLayout.atIndex(fieldIndex),
        offset: StoreCoreInternal._getStaticDataOffset(fieldLayout, fieldIndex)
      });
  }

  /**
   * @notice Get a single dynamic field from the given table ID and key tuple.
   * @param tableId The ID of the table to get the dynamic field from.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to get, relative to the start of the dynamic fields.
   * (Dynamic field index = field index - number of static fields)
   * @return The data of the dynamic field.
   */
  function getDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) internal view returns (bytes memory) {
    // Get the storage location of the dynamic field
    // and load the data from storage
    return
      Storage.load({
        storagePointer: StoreCoreInternal._getDynamicDataLocation(tableId, keyTuple, dynamicFieldIndex),
        length: StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple).atIndex(dynamicFieldIndex),
        offset: 0
      });
  }

  /**
   * @notice Get the byte length of a single field from the given table ID and key tuple.
   * @dev This function internally calls another overload of `getFieldLength`, loading the field layout from storage.
   * If the field layout is available to the caller, it is recommended to use the other overload to avoid an additional storage read.
   * @param tableId The ID of the table to get the field length from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get the length for.
   * @return The byte length of the field.
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex
  ) internal view returns (uint256) {
    return getFieldLength(tableId, keyTuple, fieldIndex, getFieldLayout(tableId));
  }

  /**
   * @notice Get the byte length of a single field from the given table ID and key tuple.
   * @param tableId The ID of the table to get the field length from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get the length for.
   * @param fieldLayout The field layout for the record.
   * @return The byte length of the field.
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (uint256) {
    uint8 numStaticFields = uint8(fieldLayout.numStaticFields());
    if (fieldIndex < numStaticFields) {
      return fieldLayout.atIndex(fieldIndex);
    } else {
      return getDynamicFieldLength(tableId, keyTuple, fieldIndex - numStaticFields);
    }
  }

  /**
   * @notice Get the byte length of a single dynamic field from the given table ID and key tuple.
   * @param tableId The ID of the table to get the dynamic field length from.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to get the length for, relative to the start of the dynamic fields.
   * (Dynamic field index = field index - number of static fields)
   * @return The byte length of the dynamic field.
   */
  function getDynamicFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) internal view returns (uint256) {
    return StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple).atIndex(dynamicFieldIndex);
  }

  /**
   * @notice Get a byte slice (including start, excluding end) of a single dynamic field from the given table ID and key tuple.
   * @param tableId The ID of the table to get the dynamic field slice from.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to get the slice from, relative to the start of the dynamic fields.
   * (Dynamic field index = field index - number of static fields)
   * @param start The start index within the dynamic field for the slice operation (inclusive).
   * @param end The end index within the dynamic field for the slice operation (exclusive).
   * @return The byte slice of the dynamic field.
   */
  function getDynamicFieldSlice(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint256 start,
    uint256 end
  ) internal view returns (bytes memory) {
    // Verify the accessed data is within the bounds of the dynamic field.
    // This is necessary because we don't delete the dynamic data when a record is deleted,
    // but only decrease its length.
    PackedCounter encodedLengths = StoreCoreInternal._loadEncodedDynamicDataLength(tableId, keyTuple);
    uint256 fieldLength = encodedLengths.atIndex(dynamicFieldIndex);
    if (start >= fieldLength || end > fieldLength) {
      revert IStoreErrors.Store_IndexOutOfBounds(fieldLength, start >= fieldLength ? start : end - 1);
    }

    // Get the length and storage location of the dynamic field
    uint256 location = StoreCoreInternal._getDynamicDataLocation(tableId, keyTuple, dynamicFieldIndex);

    return Storage.load({ storagePointer: location, length: end - start, offset: start });
  }
}

/**
 * @title StoreCoreInternal
 * @dev This library contains internal functions used by StoreCore.
 * They are not intended to be used directly by consumers of StoreCore.
 */
library StoreCoreInternal {
  using ResourceIdInstance for ResourceId;

  bytes32 internal constant SLOT = keccak256("mud.store");
  bytes32 internal constant DYNMAIC_DATA_SLOT = keccak256("mud.store.dynamicData");
  bytes32 internal constant DYNAMIC_DATA_LENGTH_SLOT = keccak256("mud.store.dynamicDataLength");

  /************************************************************************
   *
   *    SET DATA
   *
   ************************************************************************/

  /**
   * @notice Splice dynamic data in the store.
   * @dev This function checks various conditions to ensure the operation is valid.
   * It emits a `Store_SpliceDynamicData` event, calls `onBeforeSpliceDynamicData` hooks before actually modifying the storage,
   * and calls `onAfterSpliceDynamicData` hooks after modifying the storage.
   * It reverts with `Store_InvalidResourceType` if the table ID is not a table.
   * (Splicing dynamic data is not supported for offchain tables, as it requires reading the previous encoded lengths from storage.)
   * It reverts with `Store_InvalidSplice` if the splice total length of the field is changed but the splice is not at the end of the field.
   * It reverts with `Store_IndexOutOfBounds` if the start index is larger than the previous length of the field.
   * @param tableId The ID of the table to splice dynamic data.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to splice data, relative to the start of the dynamic fields.
   * (Dynamic field index = field index - number of static fields)
   * @param startWithinField The start index within the field for the splice operation.
   * @param deleteCount The number of bytes to delete in the splice operation.
   * @param data The data to insert into the dynamic data of the record at the start byte.
   * @param previousEncodedLengths The previous encoded lengths of the dynamic data of the record.
   */
  function _spliceDynamicData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    bytes memory data,
    PackedCounter previousEncodedLengths
  ) internal {
    // Splicing dynamic data is not supported for offchain tables, because it
    // requires reading the previous encoded lengths from storage
    if (tableId.getType() != RESOURCE_TABLE) {
      revert IStoreErrors.Store_InvalidResourceType(RESOURCE_TABLE, tableId, string(abi.encodePacked(tableId)));
    }

    uint256 previousFieldLength = previousEncodedLengths.atIndex(dynamicFieldIndex);
    uint256 updatedFieldLength = previousFieldLength - deleteCount + data.length;

    // If the total length of the field is changed, the data has to be appended/removed at the end of the field.
    // Otherwise offchain indexers would shift the data after inserted data, while onchain the data is truncated at the end.
    if (previousFieldLength != updatedFieldLength && startWithinField + deleteCount != previousFieldLength) {
      revert IStoreErrors.Store_InvalidSplice(startWithinField, deleteCount, uint40(previousFieldLength));
    }

    // The start index can't be larger than the previous length of the field
    if (startWithinField > previousFieldLength) {
      revert IStoreErrors.Store_IndexOutOfBounds(previousFieldLength, startWithinField);
    }

    // Update the encoded length
    PackedCounter updatedEncodedLengths = previousEncodedLengths.setAtIndex(dynamicFieldIndex, updatedFieldLength);

    {
      // Compute start index for the splice
      uint256 start = startWithinField;
      unchecked {
        // (safe because it's a few uint40 values, which can't overflow uint48)
        for (uint8 i; i < dynamicFieldIndex; i++) {
          start += previousEncodedLengths.atIndex(i);
        }
      }

      // Emit event to notify offchain indexers
      emit StoreCore.Store_SpliceDynamicData({
        tableId: tableId,
        keyTuple: keyTuple,
        start: uint48(start),
        deleteCount: deleteCount,
        encodedLengths: updatedEncodedLengths,
        data: data
      });
    }

    // Call onBeforeSpliceDynamicData hooks (before actually modifying the state, so observers have access to the previous state if needed)
    bytes21[] memory hooks = StoreHooks._get(tableId);
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(BEFORE_SPLICE_DYNAMIC_DATA)) {
        IStoreHook(hook.getAddress()).onBeforeSpliceDynamicData({
          tableId: tableId,
          keyTuple: keyTuple,
          dynamicFieldIndex: dynamicFieldIndex,
          startWithinField: startWithinField,
          deleteCount: deleteCount,
          encodedLengths: updatedEncodedLengths,
          data: data
        });
      }
    }

    // Store the updated encoded lengths in storage
    if (previousFieldLength != updatedFieldLength) {
      uint256 dynamicSchemaLengthSlot = _getDynamicDataLengthLocation(tableId, keyTuple);
      Storage.store({ storagePointer: dynamicSchemaLengthSlot, data: updatedEncodedLengths.unwrap() });
    }

    // Store the provided value in storage
    {
      uint256 dynamicDataLocation = _getDynamicDataLocation(tableId, keyTuple, dynamicFieldIndex);
      Storage.store({ storagePointer: dynamicDataLocation, offset: startWithinField, data: data });
    }

    // Call onAfterSpliceDynamicData hooks
    for (uint256 i; i < hooks.length; i++) {
      Hook hook = Hook.wrap(hooks[i]);
      if (hook.isEnabled(AFTER_SPLICE_DYNAMIC_DATA)) {
        IStoreHook(hook.getAddress()).onAfterSpliceDynamicData({
          tableId: tableId,
          keyTuple: keyTuple,
          dynamicFieldIndex: dynamicFieldIndex,
          startWithinField: startWithinField,
          deleteCount: deleteCount,
          encodedLengths: updatedEncodedLengths,
          data: data
        });
      }
    }
  }

  /************************************************************************
   *
   *    GET DATA
   *
   ************************************************************************/

  /**
   * @notice Get full static data for the given table ID and key tuple, with the given length in bytes.
   * @param tableId The ID of the table to get the static data from.
   * @param keyTuple An array representing the composite key for the record.
   * @param length The length of the static data to retrieve.
   * @return The full static data of the specified length.
   */
  function _getStaticData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint256 length
  ) internal view returns (bytes memory) {
    if (length == 0) return "";

    // Load the data from storage
    uint256 location = _getStaticDataLocation(tableId, keyTuple);
    return Storage.load({ storagePointer: location, length: length, offset: 0 });
  }

  /**
   * @notice Get a single static field from the given table ID and key tuple, with the given value field layout.
   * @param tableId The ID of the table to get the static field from.
   * @param keyTuple An array representing the composite key for the record.
   * @param fieldIndex The index of the field to get.
   * @param fieldLayout The field layout for the record.
   * @return The static field data as dynamic bytes in the size of the field.
   */
  function _getStaticFieldBytes(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (bytes memory) {
    // Get the length, storage location and offset of the static field
    // and load the data from storage
    return
      Storage.load({
        storagePointer: _getStaticDataLocation(tableId, keyTuple),
        length: fieldLayout.atIndex(fieldIndex),
        offset: _getStaticDataOffset(fieldLayout, fieldIndex)
      });
  }

  /************************************************************************
   *
   *    HELPER FUNCTIONS
   *
   ************************************************************************/

  /////////////////////////////////////////////////////////////////////////
  //    STATIC DATA
  /////////////////////////////////////////////////////////////////////////

  /**
   * @notice Compute the storage location based on table ID and key tuple.
   * @param tableId The ID of the table.
   * @param keyTuple An array representing the composite key for the record.
   * @return The computed storage location based on table ID and key tuple.
   */
  function _getStaticDataLocation(ResourceId tableId, bytes32[] memory keyTuple) internal pure returns (uint256) {
    return uint256(SLOT ^ keccak256(abi.encodePacked(tableId, keyTuple)));
  }

  /**
   * @notice Compute the storage location based on table ID and a single key.
   * @param tableId The ID of the table.
   * @param key The single key for the record.
   * @return The computed storage location based on table ID and key.
   */
  function _getStaticDataLocation(ResourceId tableId, bytes32 key) internal pure returns (uint256) {
    // keccak256(abi.encodePacked(tableId, key)) is equivalent to keccak256(abi.encodePacked(tableId, [key]))
    return uint256(SLOT ^ keccak256(abi.encodePacked(tableId, key)));
  }

  /**
   * @notice Get storage offset for the given value field layout and index.
   * @param fieldLayout The field layout for the record.
   * @param fieldIndex The index of the field to get the offset for.
   * @return The storage offset for the specified field layout and index.
   */
  function _getStaticDataOffset(FieldLayout fieldLayout, uint8 fieldIndex) internal pure returns (uint256) {
    uint256 offset = 0;
    for (uint256 i; i < fieldIndex; i++) {
      offset += fieldLayout.atIndex(i);
    }
    return offset;
  }

  /////////////////////////////////////////////////////////////////////////
  //    DYNAMIC DATA
  /////////////////////////////////////////////////////////////////////////

  /**
   * @notice Compute the storage location based on table ID, key tuple, and dynamic field index.
   * @param tableId The ID of the table.
   * @param keyTuple An array representing the composite key for the record.
   * @param dynamicFieldIndex The index of the dynamic field, relative to the start of the dynamic fields.
   * (Dynamic field index = field index - number of static fields)
   * @return The computed storage location based on table ID, key tuple, and dynamic field index.
   */
  function _getDynamicDataLocation(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) internal pure returns (uint256) {
    return uint256(DYNMAIC_DATA_SLOT ^ bytes1(dynamicFieldIndex) ^ keccak256(abi.encodePacked(tableId, keyTuple)));
  }

  /**
   * @notice Compute the storage location for the length of the dynamic data based on table ID and key tuple.
   * @param tableId The ID of the table.
   * @param keyTuple An array representing the composite key for the record.
   * @return The computed storage location for the length of the dynamic data based on table ID and key tuple.
   */
  function _getDynamicDataLengthLocation(
    ResourceId tableId,
    bytes32[] memory keyTuple
  ) internal pure returns (uint256) {
    return uint256(DYNAMIC_DATA_LENGTH_SLOT ^ keccak256(abi.encodePacked(tableId, keyTuple)));
  }

  /**
   * @notice Load the encoded dynamic data length from storage for the given table ID and key tuple.
   * @param tableId The ID of the table.
   * @param keyTuple An array representing the composite key for the record.
   * @return The loaded encoded dynamic data length from storage for the given table ID and key tuple.
   */
  function _loadEncodedDynamicDataLength(
    ResourceId tableId,
    bytes32[] memory keyTuple
  ) internal view returns (PackedCounter) {
    // Load dynamic data length from storage
    return PackedCounter.wrap(Storage.load({ storagePointer: _getDynamicDataLengthLocation(tableId, keyTuple) }));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Store Hook Flags
 * @notice Constants for enabling store hooks.
 * @dev These bitmaps can be used to enable selected store hooks. They can be combined with a bitwise OR (`|`).
 */

/// @dev Flag to enable the `onBeforeSetRecord` hook.
uint8 constant BEFORE_SET_RECORD = 1 << 0;

/// @dev Flag to enable the `afterSetRecord` hook.
uint8 constant AFTER_SET_RECORD = 1 << 1;

/// @dev Flag to enable the `beforeSpliceStaticData` hook.
uint8 constant BEFORE_SPLICE_STATIC_DATA = 1 << 2;

/// @dev Flag to enable the `afterSpliceStaticData` hook.
uint8 constant AFTER_SPLICE_STATIC_DATA = 1 << 3;

/// @dev Flag to enable the `beforeSpliceDynamicData` hook.
uint8 constant BEFORE_SPLICE_DYNAMIC_DATA = 1 << 4;

/// @dev Flag to enable the `afterSpliceDynamicData` hook.
uint8 constant AFTER_SPLICE_DYNAMIC_DATA = 1 << 5;

/// @dev Flag to enable the `beforeDeleteRecord` hook.
uint8 constant BEFORE_DELETE_RECORD = 1 << 6;

/// @dev Flag to enable the `afterDeleteRecord` hook.
uint8 constant AFTER_DELETE_RECORD = 1 << 7;

/// @dev Bitmap to enable all hooks.
uint8 constant ALL = BEFORE_SET_RECORD |
  AFTER_SET_RECORD |
  BEFORE_SPLICE_STATIC_DATA |
  AFTER_SPLICE_STATIC_DATA |
  BEFORE_SPLICE_DYNAMIC_DATA |
  AFTER_SPLICE_DYNAMIC_DATA |
  BEFORE_DELETE_RECORD |
  AFTER_DELETE_RECORD;

/// @dev Bitmap to enable all "before" hooks.
uint8 constant BEFORE_ALL = BEFORE_SET_RECORD |
  BEFORE_SPLICE_STATIC_DATA |
  BEFORE_SPLICE_DYNAMIC_DATA |
  BEFORE_DELETE_RECORD;

/// @dev Bitmap to enable all "after" hooks.
uint8 constant AFTER_ALL = AFTER_SET_RECORD |
  AFTER_SPLICE_STATIC_DATA |
  AFTER_SPLICE_DYNAMIC_DATA |
  AFTER_DELETE_RECORD;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Resource Identifiers
 * @notice Constants representing unique identifiers for different resource types.
 * @dev These identifiers can be used to distinguish between various resource types.
 */

/// @dev Identifier for a resource table.
bytes2 constant RESOURCE_TABLE = "tb";

/// @dev Identifier for an offchain resource table.
bytes2 constant RESOURCE_OFFCHAIN_TABLE = "ot";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IStore } from "./IStore.sol";
import { PackedCounter } from "../src/PackedCounter.sol";
import { IStoreHook } from "./IStoreHook.sol";
import { StoreCore } from "./StoreCore.sol";
import { Schema } from "./Schema.sol";
import { FieldLayout } from "./FieldLayout.sol";
import { PackedCounter } from "./PackedCounter.sol";
import { ResourceId } from "./ResourceId.sol";

/**
 * @title StoreSwitch Library
 * @notice This library serves as an interface switch to interact with the store,
 *         either by directing calls to itself or to a designated external store.
 * @dev The primary purpose is to abstract the storage details, such that the
 *      calling function doesn't need to know if it's interacting with its own
 *      storage or with an external contract's storage.
 */
library StoreSwitch {
  /// @dev Internal constant representing the storage slot used by the library.
  bytes32 private constant STORAGE_SLOT = keccak256("mud.store.storage.StoreSwitch");

  /**
   * @dev Represents the layout of the storage slot (currently just the address)
   */
  struct StorageSlotLayout {
    address storeAddress; // Address of the external store (or self).
  }

  /**
   * @notice Gets the storage layout.
   * @return layout The current storage layout.
   */
  function _layout() private pure returns (StorageSlotLayout storage layout) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      layout.slot := slot
    }
  }

  /**
   * @notice Fetch the store address to be used for data operations.
   * If _storeAddress is zero, it means that it's uninitialized and
   * therefore it's the default (msg.sender).
   * @return Address of the store, or `msg.sender` if uninitialized.
   */
  function getStoreAddress() internal view returns (address) {
    address _storeAddress = _layout().storeAddress;
    if (_storeAddress == address(0)) {
      return msg.sender;
    } else {
      return _storeAddress;
    }
  }

  /**
   * @notice Set the store address for subsequent operations.
   * @dev If it stays uninitialized, StoreSwitch falls back to calling store methods on msg.sender.
   * @param _storeAddress The address of the external store contract.
   */
  function setStoreAddress(address _storeAddress) internal {
    _layout().storeAddress = _storeAddress;
  }

  /**
   * @notice Register a store hook for a particular table.
   * @param tableId Unique identifier of the table.
   * @param hookAddress Address of the hook contract.
   * @param enabledHooksBitmap Bitmap representing the hooks which this contract overrides.
   */
  function registerStoreHook(ResourceId tableId, IStoreHook hookAddress, uint8 enabledHooksBitmap) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.registerStoreHook(tableId, hookAddress, enabledHooksBitmap);
    } else {
      IStore(_storeAddress).registerStoreHook(tableId, hookAddress, enabledHooksBitmap);
    }
  }

  /**
   * @notice Unregister a previously registered store hook.
   * @param tableId Unique identifier of the table.
   * @param hookAddress Address of the hook contract to be unregistered.
   */
  function unregisterStoreHook(ResourceId tableId, IStoreHook hookAddress) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.unregisterStoreHook(tableId, hookAddress);
    } else {
      IStore(_storeAddress).unregisterStoreHook(tableId, hookAddress);
    }
  }

  /**
   * @dev Fetches the field layout for a specified table.
   * @param tableId The ID of the table for which to retrieve the field layout.
   * @return fieldLayout The layout of the fields in the specified table.
   */
  function getFieldLayout(ResourceId tableId) internal view returns (FieldLayout fieldLayout) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      fieldLayout = StoreCore.getFieldLayout(tableId);
    } else {
      fieldLayout = IStore(_storeAddress).getFieldLayout(tableId);
    }
  }

  /**
   * @dev Retrieves the value schema for a specified table.
   * @param tableId The ID of the table for which to retrieve the value schema.
   * @return valueSchema The schema for values in the specified table.
   */
  function getValueSchema(ResourceId tableId) internal view returns (Schema valueSchema) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      valueSchema = StoreCore.getValueSchema(tableId);
    } else {
      valueSchema = IStore(_storeAddress).getValueSchema(tableId);
    }
  }

  /**
   * @dev Retrieves the key schema for a specified table.
   * @param tableId The ID of the table for which to retrieve the key schema.
   * @return keySchema The schema for keys in the specified table.
   */
  function getKeySchema(ResourceId tableId) internal view returns (Schema keySchema) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      keySchema = StoreCore.getKeySchema(tableId);
    } else {
      keySchema = IStore(_storeAddress).getKeySchema(tableId);
    }
  }

  /**
   * @dev Registers a table with specified configurations.
   * @param tableId The ID of the table to register.
   * @param fieldLayout The layout of the fields for the table.
   * @param keySchema The schema for keys in the table.
   * @param valueSchema The schema for values in the table.
   * @param keyNames Names of keys in the table.
   * @param fieldNames Names of fields in the table.
   */
  function registerTable(
    ResourceId tableId,
    FieldLayout fieldLayout,
    Schema keySchema,
    Schema valueSchema,
    string[] memory keyNames,
    string[] memory fieldNames
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.registerTable(tableId, fieldLayout, keySchema, valueSchema, keyNames, fieldNames);
    } else {
      IStore(_storeAddress).registerTable(tableId, fieldLayout, keySchema, valueSchema, keyNames, fieldNames);
    }
  }

  /**
   * @dev Sets a record in the store.
   * @param tableId The table's ID.
   * @param keyTuple Array of key values.
   * @param staticData Fixed-length fields data.
   * @param encodedLengths Encoded lengths for dynamic data.
   * @param dynamicData Dynamic-length fields data.
   */
  function setRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    bytes memory staticData,
    PackedCounter encodedLengths,
    bytes memory dynamicData
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.setRecord(tableId, keyTuple, staticData, encodedLengths, dynamicData);
    } else {
      IStore(_storeAddress).setRecord(tableId, keyTuple, staticData, encodedLengths, dynamicData);
    }
  }

  /**
   * @dev Splices the static (fixed length) data for a given table ID and key tuple, starting at a specific point.
   * @param tableId The ID of the resource table.
   * @param keyTuple An array of bytes32 keys identifying the data record.
   * @param start The position to begin splicing.
   * @param data The data to splice into the record.
   */
  function spliceStaticData(ResourceId tableId, bytes32[] memory keyTuple, uint48 start, bytes memory data) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.spliceStaticData(tableId, keyTuple, start, data);
    } else {
      IStore(_storeAddress).spliceStaticData(tableId, keyTuple, start, data);
    }
  }

  /**
   * @dev Splices the dynamic data for a given table ID, key tuple, and dynamic field index.
   * @param tableId The ID of the resource table.
   * @param keyTuple An array of bytes32 keys identifying the data record.
   * @param dynamicFieldIndex The index of the dynamic field to splice.
   * @param startWithinField The position within the dynamic field to start splicing.
   * @param deleteCount The number of bytes to delete starting from the splice point.
   * @param data The data to splice into the dynamic field.
   */
  function spliceDynamicData(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint40 startWithinField,
    uint40 deleteCount,
    bytes memory data
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.spliceDynamicData(tableId, keyTuple, dynamicFieldIndex, startWithinField, deleteCount, data);
    } else {
      IStore(_storeAddress).spliceDynamicData(
        tableId,
        keyTuple,
        dynamicFieldIndex,
        startWithinField,
        deleteCount,
        data
      );
    }
  }

  /**
   * @dev Sets the data for a specific field in a record identified by table ID and key tuple.
   * @param tableId The ID of the resource table.
   * @param keyTuple An array of bytes32 keys identifying the data record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the field.
   */
  function setField(ResourceId tableId, bytes32[] memory keyTuple, uint8 fieldIndex, bytes memory data) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.setField(tableId, keyTuple, fieldIndex, data);
    } else {
      IStore(_storeAddress).setField(tableId, keyTuple, fieldIndex, data);
    }
  }

  /**
   * @dev Sets the data for a specific field in a record, considering a specific field layout.
   * @param tableId The ID of the resource table.
   * @param keyTuple An array of bytes32 keys identifying the data record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the field.
   * @param fieldLayout The layout structure of the field.
   */
  function setField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    bytes memory data,
    FieldLayout fieldLayout
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.setField(tableId, keyTuple, fieldIndex, data, fieldLayout);
    } else {
      IStore(_storeAddress).setField(tableId, keyTuple, fieldIndex, data, fieldLayout);
    }
  }

  /**
   * @dev Sets the data for a specific static (fixed length) field in a record, considering a specific field layout.
   * @param tableId The ID of the resource table.
   * @param keyTuple An array of bytes32 keys identifying the data record.
   * @param fieldIndex The index of the field to set.
   * @param data The data to set for the field.
   * @param fieldLayout The layout structure of the field.
   */
  function setStaticField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    bytes memory data,
    FieldLayout fieldLayout
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.setStaticField(tableId, keyTuple, fieldIndex, data, fieldLayout);
    } else {
      IStore(_storeAddress).setStaticField(tableId, keyTuple, fieldIndex, data, fieldLayout);
    }
  }

  /**
   * @dev Sets the value of a specific dynamic (variable-length) field in a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to set.
   * @param data The data to set for the field.
   */
  function setDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    bytes memory data
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.setDynamicField(tableId, keyTuple, dynamicFieldIndex, data);
    } else {
      IStore(_storeAddress).setDynamicField(tableId, keyTuple, dynamicFieldIndex, data);
    }
  }

  /**
   * @dev Appends data to a specific dynamic (variable length) field of a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field.
   * @param dataToPush The data to append to the field.
   */
  function pushToDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    bytes memory dataToPush
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.pushToDynamicField(tableId, keyTuple, dynamicFieldIndex, dataToPush);
    } else {
      IStore(_storeAddress).pushToDynamicField(tableId, keyTuple, dynamicFieldIndex, dataToPush);
    }
  }

  /**
   * @dev Removes data from the end of a specific dynamic (variable length) field of a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field.
   * @param byteLengthToPop The number of bytes to remove from the end of the field.
   */
  function popFromDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint256 byteLengthToPop
  ) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.popFromDynamicField(tableId, keyTuple, dynamicFieldIndex, byteLengthToPop);
    } else {
      IStore(_storeAddress).popFromDynamicField(tableId, keyTuple, dynamicFieldIndex, byteLengthToPop);
    }
  }

  /**
   * @dev Deletes a record from a table.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   */
  function deleteRecord(ResourceId tableId, bytes32[] memory keyTuple) internal {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      StoreCore.deleteRecord(tableId, keyTuple);
    } else {
      IStore(_storeAddress).deleteRecord(tableId, keyTuple);
    }
  }

  /**
   * @dev Retrieves a record from a table.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @return staticData The static data of the record.
   * @return encodedLengths Encoded lengths of dynamic data.
   * @return dynamicData The dynamic data of the record.
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple
  ) internal view returns (bytes memory, PackedCounter, bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getRecord(tableId, keyTuple);
    } else {
      return IStore(_storeAddress).getRecord(tableId, keyTuple);
    }
  }

  /**
   * @dev Retrieves a record from a table with a specific layout.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldLayout The layout of the fields in the record.
   * @return staticData The static data of the record.
   * @return encodedLengths Encoded lengths of dynamic data.
   * @return dynamicData The dynamic data of the record.
   */
  function getRecord(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    FieldLayout fieldLayout
  ) internal view returns (bytes memory, PackedCounter, bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getRecord(tableId, keyTuple, fieldLayout);
    } else {
      return IStore(_storeAddress).getRecord(tableId, keyTuple, fieldLayout);
    }
  }

  /**
   * @dev Retrieves a specific field from a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field to retrieve.
   * @return Returns the data of the specified field.
   */
  function getField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex
  ) internal view returns (bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getField(tableId, keyTuple, fieldIndex);
    } else {
      return IStore(_storeAddress).getField(tableId, keyTuple, fieldIndex);
    }
  }

  /**
   * @dev Retrieves a specific field from a record with a given layout.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field to retrieve.
   * @param fieldLayout The layout of the field being retrieved.
   * @return Returns the data of the specified field.
   */
  function getField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getField(tableId, keyTuple, fieldIndex, fieldLayout);
    } else {
      return IStore(_storeAddress).getField(tableId, keyTuple, fieldIndex, fieldLayout);
    }
  }

  /**
   * @dev Retrieves a specific static (fixed length) field from a record with a given layout.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the static field to retrieve.
   * @param fieldLayout The layout of the static field being retrieved.
   * @return Returns the data of the specified static field.
   */
  function getStaticField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (bytes32) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getStaticField(tableId, keyTuple, fieldIndex, fieldLayout);
    } else {
      return IStore(_storeAddress).getStaticField(tableId, keyTuple, fieldIndex, fieldLayout);
    }
  }

  /**
   * @dev Retrieves a specific dynamic (variable length) field from a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field to retrieve.
   * @return Returns the data of the specified dynamic field.
   */
  function getDynamicField(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) internal view returns (bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getDynamicField(tableId, keyTuple, dynamicFieldIndex);
    } else {
      return IStore(_storeAddress).getDynamicField(tableId, keyTuple, dynamicFieldIndex);
    }
  }

  /**
   * @dev Retrieves the length of a specific field in a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field whose length is to be retrieved.
   * @return Returns the length of the specified field.
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex
  ) internal view returns (uint256) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getFieldLength(tableId, keyTuple, fieldIndex);
    } else {
      return IStore(_storeAddress).getFieldLength(tableId, keyTuple, fieldIndex);
    }
  }

  /**
   * @dev Retrieves the length of a specific field in a record with a given layout.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param fieldIndex The index of the field whose length is to be retrieved.
   * @param fieldLayout The layout of the field whose length is to be retrieved.
   * @return Returns the length of the specified field.
   */
  function getFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 fieldIndex,
    FieldLayout fieldLayout
  ) internal view returns (uint256) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getFieldLength(tableId, keyTuple, fieldIndex, fieldLayout);
    } else {
      return IStore(_storeAddress).getFieldLength(tableId, keyTuple, fieldIndex, fieldLayout);
    }
  }

  /**
   * @dev Retrieves the length of a specific dynamic (variable length) field in a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field whose length is to be retrieved.
   * @return Returns the length of the specified dynamic field.
   */
  function getDynamicFieldLength(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex
  ) internal view returns (uint256) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getDynamicFieldLength(tableId, keyTuple, dynamicFieldIndex);
    } else {
      return IStore(_storeAddress).getDynamicFieldLength(tableId, keyTuple, dynamicFieldIndex);
    }
  }

  /**
   * @dev Retrieves a slice of a dynamic (variable length) field from a record.
   * @param tableId The ID of the table to which the record belongs.
   * @param keyTuple An array representing the key for the record.
   * @param dynamicFieldIndex The index of the dynamic field from which to get the slice.
   * @param start The starting index of the slice.
   * @param end The ending index of the slice.
   * @return Returns the sliced data from the specified dynamic field.
   */
  function getDynamicFieldSlice(
    ResourceId tableId,
    bytes32[] memory keyTuple,
    uint8 dynamicFieldIndex,
    uint256 start,
    uint256 end
  ) internal view returns (bytes memory) {
    address _storeAddress = getStoreAddress();
    if (_storeAddress == address(this)) {
      return StoreCore.getDynamicFieldSlice(tableId, keyTuple, dynamicFieldIndex, start, end);
    } else {
      return IStore(_storeAddress).getDynamicFieldSlice(tableId, keyTuple, dynamicFieldIndex, start, end);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */
import { TightCoder } from "./TightCoder.sol";
import { Slice } from "../Slice.sol";

/**
 * @title DecodeSlice Library
 * @notice A library for decoding slices of data into specific data types.
 * @dev This library provides functions for decoding slices into arrays of basic uint types.
 */
library DecodeSlice {
  /**
   * @notice Decodes a slice into an array of uint8.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint8.
   */
  function decodeArray_uint8(Slice _input) internal pure returns (uint8[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 1, 248);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint16.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint16.
   */
  function decodeArray_uint16(Slice _input) internal pure returns (uint16[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 2, 240);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint24.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint24.
   */
  function decodeArray_uint24(Slice _input) internal pure returns (uint24[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 3, 232);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint32.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint32.
   */
  function decodeArray_uint32(Slice _input) internal pure returns (uint32[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 4, 224);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint40.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint40.
   */
  function decodeArray_uint40(Slice _input) internal pure returns (uint40[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 5, 216);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint48.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint48.
   */
  function decodeArray_uint48(Slice _input) internal pure returns (uint48[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 6, 208);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint56.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint56.
   */
  function decodeArray_uint56(Slice _input) internal pure returns (uint56[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 7, 200);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint64.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint64.
   */
  function decodeArray_uint64(Slice _input) internal pure returns (uint64[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 8, 192);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint72.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint72.
   */
  function decodeArray_uint72(Slice _input) internal pure returns (uint72[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 9, 184);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint80.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint80.
   */
  function decodeArray_uint80(Slice _input) internal pure returns (uint80[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 10, 176);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint88.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint88.
   */
  function decodeArray_uint88(Slice _input) internal pure returns (uint88[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 11, 168);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint96.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint96.
   */
  function decodeArray_uint96(Slice _input) internal pure returns (uint96[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 12, 160);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint104.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint104.
   */
  function decodeArray_uint104(Slice _input) internal pure returns (uint104[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 13, 152);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint112.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint112.
   */
  function decodeArray_uint112(Slice _input) internal pure returns (uint112[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 14, 144);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint120.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint120.
   */
  function decodeArray_uint120(Slice _input) internal pure returns (uint120[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 15, 136);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint128.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint128.
   */
  function decodeArray_uint128(Slice _input) internal pure returns (uint128[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 16, 128);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint136.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint136.
   */
  function decodeArray_uint136(Slice _input) internal pure returns (uint136[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 17, 120);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint144.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint144.
   */
  function decodeArray_uint144(Slice _input) internal pure returns (uint144[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 18, 112);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint152.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint152.
   */
  function decodeArray_uint152(Slice _input) internal pure returns (uint152[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 19, 104);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint160.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint160.
   */
  function decodeArray_uint160(Slice _input) internal pure returns (uint160[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 20, 96);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint168.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint168.
   */
  function decodeArray_uint168(Slice _input) internal pure returns (uint168[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 21, 88);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint176.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint176.
   */
  function decodeArray_uint176(Slice _input) internal pure returns (uint176[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 22, 80);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint184.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint184.
   */
  function decodeArray_uint184(Slice _input) internal pure returns (uint184[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 23, 72);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint192.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint192.
   */
  function decodeArray_uint192(Slice _input) internal pure returns (uint192[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 24, 64);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint200.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint200.
   */
  function decodeArray_uint200(Slice _input) internal pure returns (uint200[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 25, 56);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint208.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint208.
   */
  function decodeArray_uint208(Slice _input) internal pure returns (uint208[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 26, 48);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint216.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint216.
   */
  function decodeArray_uint216(Slice _input) internal pure returns (uint216[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 27, 40);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint224.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint224.
   */
  function decodeArray_uint224(Slice _input) internal pure returns (uint224[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 28, 32);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint232.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint232.
   */
  function decodeArray_uint232(Slice _input) internal pure returns (uint232[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 29, 24);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint240.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint240.
   */
  function decodeArray_uint240(Slice _input) internal pure returns (uint240[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 30, 16);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint248.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint248.
   */
  function decodeArray_uint248(Slice _input) internal pure returns (uint248[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 31, 8);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of uint256.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of uint256.
   */
  function decodeArray_uint256(Slice _input) internal pure returns (uint256[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 32, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int8.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int8.
   */
  function decodeArray_int8(Slice _input) internal pure returns (int8[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 1, 248);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int16.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int16.
   */
  function decodeArray_int16(Slice _input) internal pure returns (int16[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 2, 240);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int24.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int24.
   */
  function decodeArray_int24(Slice _input) internal pure returns (int24[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 3, 232);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int32.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int32.
   */
  function decodeArray_int32(Slice _input) internal pure returns (int32[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 4, 224);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int40.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int40.
   */
  function decodeArray_int40(Slice _input) internal pure returns (int40[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 5, 216);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int48.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int48.
   */
  function decodeArray_int48(Slice _input) internal pure returns (int48[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 6, 208);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int56.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int56.
   */
  function decodeArray_int56(Slice _input) internal pure returns (int56[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 7, 200);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int64.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int64.
   */
  function decodeArray_int64(Slice _input) internal pure returns (int64[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 8, 192);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int72.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int72.
   */
  function decodeArray_int72(Slice _input) internal pure returns (int72[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 9, 184);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int80.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int80.
   */
  function decodeArray_int80(Slice _input) internal pure returns (int80[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 10, 176);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int88.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int88.
   */
  function decodeArray_int88(Slice _input) internal pure returns (int88[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 11, 168);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int96.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int96.
   */
  function decodeArray_int96(Slice _input) internal pure returns (int96[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 12, 160);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int104.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int104.
   */
  function decodeArray_int104(Slice _input) internal pure returns (int104[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 13, 152);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int112.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int112.
   */
  function decodeArray_int112(Slice _input) internal pure returns (int112[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 14, 144);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int120.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int120.
   */
  function decodeArray_int120(Slice _input) internal pure returns (int120[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 15, 136);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int128.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int128.
   */
  function decodeArray_int128(Slice _input) internal pure returns (int128[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 16, 128);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int136.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int136.
   */
  function decodeArray_int136(Slice _input) internal pure returns (int136[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 17, 120);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int144.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int144.
   */
  function decodeArray_int144(Slice _input) internal pure returns (int144[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 18, 112);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int152.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int152.
   */
  function decodeArray_int152(Slice _input) internal pure returns (int152[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 19, 104);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int160.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int160.
   */
  function decodeArray_int160(Slice _input) internal pure returns (int160[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 20, 96);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int168.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int168.
   */
  function decodeArray_int168(Slice _input) internal pure returns (int168[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 21, 88);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int176.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int176.
   */
  function decodeArray_int176(Slice _input) internal pure returns (int176[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 22, 80);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int184.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int184.
   */
  function decodeArray_int184(Slice _input) internal pure returns (int184[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 23, 72);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int192.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int192.
   */
  function decodeArray_int192(Slice _input) internal pure returns (int192[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 24, 64);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int200.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int200.
   */
  function decodeArray_int200(Slice _input) internal pure returns (int200[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 25, 56);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int208.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int208.
   */
  function decodeArray_int208(Slice _input) internal pure returns (int208[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 26, 48);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int216.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int216.
   */
  function decodeArray_int216(Slice _input) internal pure returns (int216[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 27, 40);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int224.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int224.
   */
  function decodeArray_int224(Slice _input) internal pure returns (int224[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 28, 32);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int232.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int232.
   */
  function decodeArray_int232(Slice _input) internal pure returns (int232[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 29, 24);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int240.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int240.
   */
  function decodeArray_int240(Slice _input) internal pure returns (int240[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 30, 16);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int248.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int248.
   */
  function decodeArray_int248(Slice _input) internal pure returns (int248[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 31, 8);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of int256.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of int256.
   */
  function decodeArray_int256(Slice _input) internal pure returns (int256[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 32, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes1.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes1.
   */
  function decodeArray_bytes1(Slice _input) internal pure returns (bytes1[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 1, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes2.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes2.
   */
  function decodeArray_bytes2(Slice _input) internal pure returns (bytes2[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 2, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes3.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes3.
   */
  function decodeArray_bytes3(Slice _input) internal pure returns (bytes3[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 3, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes4.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes4.
   */
  function decodeArray_bytes4(Slice _input) internal pure returns (bytes4[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 4, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes5.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes5.
   */
  function decodeArray_bytes5(Slice _input) internal pure returns (bytes5[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 5, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes6.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes6.
   */
  function decodeArray_bytes6(Slice _input) internal pure returns (bytes6[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 6, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes7.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes7.
   */
  function decodeArray_bytes7(Slice _input) internal pure returns (bytes7[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 7, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes8.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes8.
   */
  function decodeArray_bytes8(Slice _input) internal pure returns (bytes8[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 8, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes9.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes9.
   */
  function decodeArray_bytes9(Slice _input) internal pure returns (bytes9[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 9, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes10.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes10.
   */
  function decodeArray_bytes10(Slice _input) internal pure returns (bytes10[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 10, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes11.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes11.
   */
  function decodeArray_bytes11(Slice _input) internal pure returns (bytes11[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 11, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes12.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes12.
   */
  function decodeArray_bytes12(Slice _input) internal pure returns (bytes12[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 12, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes13.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes13.
   */
  function decodeArray_bytes13(Slice _input) internal pure returns (bytes13[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 13, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes14.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes14.
   */
  function decodeArray_bytes14(Slice _input) internal pure returns (bytes14[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 14, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes15.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes15.
   */
  function decodeArray_bytes15(Slice _input) internal pure returns (bytes15[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 15, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes16.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes16.
   */
  function decodeArray_bytes16(Slice _input) internal pure returns (bytes16[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 16, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes17.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes17.
   */
  function decodeArray_bytes17(Slice _input) internal pure returns (bytes17[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 17, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes18.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes18.
   */
  function decodeArray_bytes18(Slice _input) internal pure returns (bytes18[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 18, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes19.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes19.
   */
  function decodeArray_bytes19(Slice _input) internal pure returns (bytes19[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 19, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes20.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes20.
   */
  function decodeArray_bytes20(Slice _input) internal pure returns (bytes20[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 20, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes21.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes21.
   */
  function decodeArray_bytes21(Slice _input) internal pure returns (bytes21[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 21, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes22.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes22.
   */
  function decodeArray_bytes22(Slice _input) internal pure returns (bytes22[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 22, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes23.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes23.
   */
  function decodeArray_bytes23(Slice _input) internal pure returns (bytes23[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 23, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes24.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes24.
   */
  function decodeArray_bytes24(Slice _input) internal pure returns (bytes24[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 24, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes25.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes25.
   */
  function decodeArray_bytes25(Slice _input) internal pure returns (bytes25[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 25, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes26.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes26.
   */
  function decodeArray_bytes26(Slice _input) internal pure returns (bytes26[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 26, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes27.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes27.
   */
  function decodeArray_bytes27(Slice _input) internal pure returns (bytes27[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 27, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes28.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes28.
   */
  function decodeArray_bytes28(Slice _input) internal pure returns (bytes28[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 28, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes29.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes29.
   */
  function decodeArray_bytes29(Slice _input) internal pure returns (bytes29[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 29, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes30.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes30.
   */
  function decodeArray_bytes30(Slice _input) internal pure returns (bytes30[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 30, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes31.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes31.
   */
  function decodeArray_bytes31(Slice _input) internal pure returns (bytes31[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 31, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bytes32.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bytes32.
   */
  function decodeArray_bytes32(Slice _input) internal pure returns (bytes32[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 32, 0);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of bool.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of bool.
   */
  function decodeArray_bool(Slice _input) internal pure returns (bool[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 1, 248);
    assembly {
      _output := _genericArray
    }
  }

  /**
   * @notice Decodes a slice into an array of address.
   * @dev Uses TightCoder for initial decoding, and then assembly for memory conversion.
   * @param _input The slice to decode.
   * @return _output The decoded array of address.
   */
  function decodeArray_address(Slice _input) internal pure returns (address[] memory _output) {
    bytes32[] memory _genericArray = TightCoder.decode(_input, 20, 96);
    assembly {
      _output := _genericArray
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */
import { TightCoder } from "./TightCoder.sol";

/**
 * @title EncodeArray
 * @dev This library provides utilities for encoding arrays into tightly packed bytes representations.
 */
library EncodeArray {
  /**
   * @notice Encodes an array of uint8 into a tightly packed bytes representation.
   * @param _input The array of uint8 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint8[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 1, 248);
  }

  /**
   * @notice Encodes an array of uint16 into a tightly packed bytes representation.
   * @param _input The array of uint16 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint16[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 2, 240);
  }

  /**
   * @notice Encodes an array of uint24 into a tightly packed bytes representation.
   * @param _input The array of uint24 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint24[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 3, 232);
  }

  /**
   * @notice Encodes an array of uint32 into a tightly packed bytes representation.
   * @param _input The array of uint32 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint32[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 4, 224);
  }

  /**
   * @notice Encodes an array of uint40 into a tightly packed bytes representation.
   * @param _input The array of uint40 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint40[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 5, 216);
  }

  /**
   * @notice Encodes an array of uint48 into a tightly packed bytes representation.
   * @param _input The array of uint48 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint48[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 6, 208);
  }

  /**
   * @notice Encodes an array of uint56 into a tightly packed bytes representation.
   * @param _input The array of uint56 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint56[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 7, 200);
  }

  /**
   * @notice Encodes an array of uint64 into a tightly packed bytes representation.
   * @param _input The array of uint64 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint64[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 8, 192);
  }

  /**
   * @notice Encodes an array of uint72 into a tightly packed bytes representation.
   * @param _input The array of uint72 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint72[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 9, 184);
  }

  /**
   * @notice Encodes an array of uint80 into a tightly packed bytes representation.
   * @param _input The array of uint80 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint80[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 10, 176);
  }

  /**
   * @notice Encodes an array of uint88 into a tightly packed bytes representation.
   * @param _input The array of uint88 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint88[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 11, 168);
  }

  /**
   * @notice Encodes an array of uint96 into a tightly packed bytes representation.
   * @param _input The array of uint96 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint96[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 12, 160);
  }

  /**
   * @notice Encodes an array of uint104 into a tightly packed bytes representation.
   * @param _input The array of uint104 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint104[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 13, 152);
  }

  /**
   * @notice Encodes an array of uint112 into a tightly packed bytes representation.
   * @param _input The array of uint112 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint112[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 14, 144);
  }

  /**
   * @notice Encodes an array of uint120 into a tightly packed bytes representation.
   * @param _input The array of uint120 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint120[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 15, 136);
  }

  /**
   * @notice Encodes an array of uint128 into a tightly packed bytes representation.
   * @param _input The array of uint128 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint128[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 16, 128);
  }

  /**
   * @notice Encodes an array of uint136 into a tightly packed bytes representation.
   * @param _input The array of uint136 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint136[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 17, 120);
  }

  /**
   * @notice Encodes an array of uint144 into a tightly packed bytes representation.
   * @param _input The array of uint144 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint144[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 18, 112);
  }

  /**
   * @notice Encodes an array of uint152 into a tightly packed bytes representation.
   * @param _input The array of uint152 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint152[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 19, 104);
  }

  /**
   * @notice Encodes an array of uint160 into a tightly packed bytes representation.
   * @param _input The array of uint160 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint160[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 20, 96);
  }

  /**
   * @notice Encodes an array of uint168 into a tightly packed bytes representation.
   * @param _input The array of uint168 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint168[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 21, 88);
  }

  /**
   * @notice Encodes an array of uint176 into a tightly packed bytes representation.
   * @param _input The array of uint176 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint176[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 22, 80);
  }

  /**
   * @notice Encodes an array of uint184 into a tightly packed bytes representation.
   * @param _input The array of uint184 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint184[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 23, 72);
  }

  /**
   * @notice Encodes an array of uint192 into a tightly packed bytes representation.
   * @param _input The array of uint192 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint192[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 24, 64);
  }

  /**
   * @notice Encodes an array of uint200 into a tightly packed bytes representation.
   * @param _input The array of uint200 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint200[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 25, 56);
  }

  /**
   * @notice Encodes an array of uint208 into a tightly packed bytes representation.
   * @param _input The array of uint208 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint208[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 26, 48);
  }

  /**
   * @notice Encodes an array of uint216 into a tightly packed bytes representation.
   * @param _input The array of uint216 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint216[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 27, 40);
  }

  /**
   * @notice Encodes an array of uint224 into a tightly packed bytes representation.
   * @param _input The array of uint224 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint224[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 28, 32);
  }

  /**
   * @notice Encodes an array of uint232 into a tightly packed bytes representation.
   * @param _input The array of uint232 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint232[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 29, 24);
  }

  /**
   * @notice Encodes an array of uint240 into a tightly packed bytes representation.
   * @param _input The array of uint240 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint240[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 30, 16);
  }

  /**
   * @notice Encodes an array of uint248 into a tightly packed bytes representation.
   * @param _input The array of uint248 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint248[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 31, 8);
  }

  /**
   * @notice Encodes an array of uint256 into a tightly packed bytes representation.
   * @param _input The array of uint256 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(uint256[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 32, 0);
  }

  /**
   * @notice Encodes an array of int8 into a tightly packed bytes representation.
   * @param _input The array of int8 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int8[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 1, 248);
  }

  /**
   * @notice Encodes an array of int16 into a tightly packed bytes representation.
   * @param _input The array of int16 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int16[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 2, 240);
  }

  /**
   * @notice Encodes an array of int24 into a tightly packed bytes representation.
   * @param _input The array of int24 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int24[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 3, 232);
  }

  /**
   * @notice Encodes an array of int32 into a tightly packed bytes representation.
   * @param _input The array of int32 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int32[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 4, 224);
  }

  /**
   * @notice Encodes an array of int40 into a tightly packed bytes representation.
   * @param _input The array of int40 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int40[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 5, 216);
  }

  /**
   * @notice Encodes an array of int48 into a tightly packed bytes representation.
   * @param _input The array of int48 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int48[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 6, 208);
  }

  /**
   * @notice Encodes an array of int56 into a tightly packed bytes representation.
   * @param _input The array of int56 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int56[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 7, 200);
  }

  /**
   * @notice Encodes an array of int64 into a tightly packed bytes representation.
   * @param _input The array of int64 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int64[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 8, 192);
  }

  /**
   * @notice Encodes an array of int72 into a tightly packed bytes representation.
   * @param _input The array of int72 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int72[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 9, 184);
  }

  /**
   * @notice Encodes an array of int80 into a tightly packed bytes representation.
   * @param _input The array of int80 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int80[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 10, 176);
  }

  /**
   * @notice Encodes an array of int88 into a tightly packed bytes representation.
   * @param _input The array of int88 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int88[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 11, 168);
  }

  /**
   * @notice Encodes an array of int96 into a tightly packed bytes representation.
   * @param _input The array of int96 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int96[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 12, 160);
  }

  /**
   * @notice Encodes an array of int104 into a tightly packed bytes representation.
   * @param _input The array of int104 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int104[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 13, 152);
  }

  /**
   * @notice Encodes an array of int112 into a tightly packed bytes representation.
   * @param _input The array of int112 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int112[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 14, 144);
  }

  /**
   * @notice Encodes an array of int120 into a tightly packed bytes representation.
   * @param _input The array of int120 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int120[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 15, 136);
  }

  /**
   * @notice Encodes an array of int128 into a tightly packed bytes representation.
   * @param _input The array of int128 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int128[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 16, 128);
  }

  /**
   * @notice Encodes an array of int136 into a tightly packed bytes representation.
   * @param _input The array of int136 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int136[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 17, 120);
  }

  /**
   * @notice Encodes an array of int144 into a tightly packed bytes representation.
   * @param _input The array of int144 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int144[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 18, 112);
  }

  /**
   * @notice Encodes an array of int152 into a tightly packed bytes representation.
   * @param _input The array of int152 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int152[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 19, 104);
  }

  /**
   * @notice Encodes an array of int160 into a tightly packed bytes representation.
   * @param _input The array of int160 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int160[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 20, 96);
  }

  /**
   * @notice Encodes an array of int168 into a tightly packed bytes representation.
   * @param _input The array of int168 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int168[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 21, 88);
  }

  /**
   * @notice Encodes an array of int176 into a tightly packed bytes representation.
   * @param _input The array of int176 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int176[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 22, 80);
  }

  /**
   * @notice Encodes an array of int184 into a tightly packed bytes representation.
   * @param _input The array of int184 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int184[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 23, 72);
  }

  /**
   * @notice Encodes an array of int192 into a tightly packed bytes representation.
   * @param _input The array of int192 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int192[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 24, 64);
  }

  /**
   * @notice Encodes an array of int200 into a tightly packed bytes representation.
   * @param _input The array of int200 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int200[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 25, 56);
  }

  /**
   * @notice Encodes an array of int208 into a tightly packed bytes representation.
   * @param _input The array of int208 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int208[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 26, 48);
  }

  /**
   * @notice Encodes an array of int216 into a tightly packed bytes representation.
   * @param _input The array of int216 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int216[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 27, 40);
  }

  /**
   * @notice Encodes an array of int224 into a tightly packed bytes representation.
   * @param _input The array of int224 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int224[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 28, 32);
  }

  /**
   * @notice Encodes an array of int232 into a tightly packed bytes representation.
   * @param _input The array of int232 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int232[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 29, 24);
  }

  /**
   * @notice Encodes an array of int240 into a tightly packed bytes representation.
   * @param _input The array of int240 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int240[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 30, 16);
  }

  /**
   * @notice Encodes an array of int248 into a tightly packed bytes representation.
   * @param _input The array of int248 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int248[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 31, 8);
  }

  /**
   * @notice Encodes an array of int256 into a tightly packed bytes representation.
   * @param _input The array of int256 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(int256[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 32, 0);
  }

  /**
   * @notice Encodes an array of bytes1 into a tightly packed bytes representation.
   * @param _input The array of bytes1 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes1[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 1, 0);
  }

  /**
   * @notice Encodes an array of bytes2 into a tightly packed bytes representation.
   * @param _input The array of bytes2 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes2[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 2, 0);
  }

  /**
   * @notice Encodes an array of bytes3 into a tightly packed bytes representation.
   * @param _input The array of bytes3 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes3[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 3, 0);
  }

  /**
   * @notice Encodes an array of bytes4 into a tightly packed bytes representation.
   * @param _input The array of bytes4 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes4[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 4, 0);
  }

  /**
   * @notice Encodes an array of bytes5 into a tightly packed bytes representation.
   * @param _input The array of bytes5 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes5[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 5, 0);
  }

  /**
   * @notice Encodes an array of bytes6 into a tightly packed bytes representation.
   * @param _input The array of bytes6 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes6[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 6, 0);
  }

  /**
   * @notice Encodes an array of bytes7 into a tightly packed bytes representation.
   * @param _input The array of bytes7 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes7[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 7, 0);
  }

  /**
   * @notice Encodes an array of bytes8 into a tightly packed bytes representation.
   * @param _input The array of bytes8 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes8[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 8, 0);
  }

  /**
   * @notice Encodes an array of bytes9 into a tightly packed bytes representation.
   * @param _input The array of bytes9 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes9[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 9, 0);
  }

  /**
   * @notice Encodes an array of bytes10 into a tightly packed bytes representation.
   * @param _input The array of bytes10 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes10[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 10, 0);
  }

  /**
   * @notice Encodes an array of bytes11 into a tightly packed bytes representation.
   * @param _input The array of bytes11 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes11[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 11, 0);
  }

  /**
   * @notice Encodes an array of bytes12 into a tightly packed bytes representation.
   * @param _input The array of bytes12 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes12[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 12, 0);
  }

  /**
   * @notice Encodes an array of bytes13 into a tightly packed bytes representation.
   * @param _input The array of bytes13 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes13[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 13, 0);
  }

  /**
   * @notice Encodes an array of bytes14 into a tightly packed bytes representation.
   * @param _input The array of bytes14 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes14[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 14, 0);
  }

  /**
   * @notice Encodes an array of bytes15 into a tightly packed bytes representation.
   * @param _input The array of bytes15 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes15[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 15, 0);
  }

  /**
   * @notice Encodes an array of bytes16 into a tightly packed bytes representation.
   * @param _input The array of bytes16 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes16[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 16, 0);
  }

  /**
   * @notice Encodes an array of bytes17 into a tightly packed bytes representation.
   * @param _input The array of bytes17 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes17[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 17, 0);
  }

  /**
   * @notice Encodes an array of bytes18 into a tightly packed bytes representation.
   * @param _input The array of bytes18 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes18[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 18, 0);
  }

  /**
   * @notice Encodes an array of bytes19 into a tightly packed bytes representation.
   * @param _input The array of bytes19 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes19[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 19, 0);
  }

  /**
   * @notice Encodes an array of bytes20 into a tightly packed bytes representation.
   * @param _input The array of bytes20 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes20[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 20, 0);
  }

  /**
   * @notice Encodes an array of bytes21 into a tightly packed bytes representation.
   * @param _input The array of bytes21 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes21[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 21, 0);
  }

  /**
   * @notice Encodes an array of bytes22 into a tightly packed bytes representation.
   * @param _input The array of bytes22 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes22[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 22, 0);
  }

  /**
   * @notice Encodes an array of bytes23 into a tightly packed bytes representation.
   * @param _input The array of bytes23 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes23[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 23, 0);
  }

  /**
   * @notice Encodes an array of bytes24 into a tightly packed bytes representation.
   * @param _input The array of bytes24 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes24[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 24, 0);
  }

  /**
   * @notice Encodes an array of bytes25 into a tightly packed bytes representation.
   * @param _input The array of bytes25 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes25[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 25, 0);
  }

  /**
   * @notice Encodes an array of bytes26 into a tightly packed bytes representation.
   * @param _input The array of bytes26 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes26[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 26, 0);
  }

  /**
   * @notice Encodes an array of bytes27 into a tightly packed bytes representation.
   * @param _input The array of bytes27 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes27[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 27, 0);
  }

  /**
   * @notice Encodes an array of bytes28 into a tightly packed bytes representation.
   * @param _input The array of bytes28 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes28[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 28, 0);
  }

  /**
   * @notice Encodes an array of bytes29 into a tightly packed bytes representation.
   * @param _input The array of bytes29 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes29[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 29, 0);
  }

  /**
   * @notice Encodes an array of bytes30 into a tightly packed bytes representation.
   * @param _input The array of bytes30 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes30[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 30, 0);
  }

  /**
   * @notice Encodes an array of bytes31 into a tightly packed bytes representation.
   * @param _input The array of bytes31 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes31[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 31, 0);
  }

  /**
   * @notice Encodes an array of bytes32 into a tightly packed bytes representation.
   * @param _input The array of bytes32 values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bytes32[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 32, 0);
  }

  /**
   * @notice Encodes an array of bool into a tightly packed bytes representation.
   * @param _input The array of bool values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(bool[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 1, 248);
  }

  /**
   * @notice Encodes an array of address into a tightly packed bytes representation.
   * @param _input The array of address values to be encoded.
   * @return The resulting tightly packed bytes representation of the input array.
   */
  function encode(address[] memory _input) internal pure returns (bytes memory) {
    bytes32[] memory _genericArray;
    assembly {
      _genericArray := _input
    }
    return TightCoder.encode(_genericArray, 20, 96);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { Slice, SliceLib } from "../Slice.sol";

/**
 * @title TightCoder
 * @dev Provides low-level generic implementations of tight encoding and decoding for arrays.
 * This is consistent with Solidity's internal tight encoding for array data in storage.
 */
library TightCoder {
  /**
   * @dev Copies the array to a new bytes array, tightly packing its elements.
   * @param array The array to encode.
   * @param elementSize The size of each element in bytes.
   * @param leftPaddingBits The number of bits to pad on the left for each element.
   * @return data A tightly packed byte array.
   * @notice elementSize and leftPaddingBits must be correctly provided by the caller based on the array's element type.
   */
  function encode(
    bytes32[] memory array,
    uint256 elementSize,
    uint256 leftPaddingBits
  ) internal pure returns (bytes memory data) {
    uint256 arrayLength = array.length;
    uint256 packedLength = array.length * elementSize;

    // Manual memory allocation is cheaper and removes the issue of memory corruption at the tail
    /// @solidity memory-safe-assembly
    assembly {
      // Solidity's YulUtilFunctions::roundUpFunction
      function round_up_to_mul_of_32(value) -> _result {
        _result := and(add(value, 31), not(31))
      }

      // Allocate memory
      data := mload(0x40)
      let packedPointer := add(data, 0x20)
      mstore(0x40, round_up_to_mul_of_32(add(packedPointer, packedLength)))
      // Store length
      mstore(data, packedLength)

      for {
        let i := 0
        // Skip array length
        let arrayPointer := add(array, 0x20)
      } lt(i, arrayLength) {
        // Loop until we reach the end of the array
        i := add(i, 1)
        // Increment array pointer by one word
        arrayPointer := add(arrayPointer, 0x20)
        // Increment packed pointer by one element size
        packedPointer := add(packedPointer, elementSize)
      } {
        // Pack one array element
        mstore(packedPointer, shl(leftPaddingBits, mload(arrayPointer)))
      }
    }
  }

  /**
   * @notice Decodes a tightly packed byte slice into a bytes32 array.
   * @param packedSlice The tightly packed data to be decoded.
   * @param elementSize The size of each element in bytes.
   * @param leftPaddingBits The number of padding bits on the left side of each element.
   * @dev elementSize and leftPaddingBits must be correctly provided based on the desired output array's element type.
   * @return array The resulting array of bytes32 elements from decoding the packed slice.
   */
  function decode(
    Slice packedSlice,
    uint256 elementSize,
    uint256 leftPaddingBits
  ) internal pure returns (bytes32[] memory array) {
    uint256 packedPointer = packedSlice.pointer();
    uint256 packedLength = packedSlice.length();
    // Array length (number of elements)
    uint256 arrayLength;
    unchecked {
      arrayLength = packedLength / elementSize;
    }

    /// @solidity memory-safe-assembly
    assembly {
      // Allocate memory
      array := mload(0x40)
      let arrayPointer := add(array, 0x20)
      mstore(0x40, add(arrayPointer, mul(arrayLength, 32)))
      // Store length
      mstore(array, arrayLength)

      for {
        let i := 0
      } lt(i, arrayLength) {
        // Loop until we reach the end of the array
        i := add(i, 1)
        // Increment array pointer by one word
        arrayPointer := add(arrayPointer, 0x20)
        // Increment packed pointer by one element size
        packedPointer := add(packedPointer, elementSize)
      } {
        // Unpack one array element
        mstore(arrayPointer, shr(leftPaddingBits, mload(packedPointer)))
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Store Versioning
 * @notice Contains a constant representing the version of the store.
 */

/// @dev Identifier for the current store version.
bytes32 constant STORE_VERSION = "1.0.0-unaudited";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @dev Calculation for ERC-165 interface ID for the `supportsInterface` function.
 */
bytes4 constant ERC165_INTERFACE_ID = IERC165.supportsInterface.selector;

/**
 * @title IERC165
 * @dev Interface for the ERC-165 standard as described in the EIP-165.
 * Allows for contracts to be checked for their support of an interface.
 * See: https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
  /**
   * @notice Query if a contract implements an interface.
   * @dev Interface identification is specified in ERC-165.
   * This function uses less than 30,000 gas.
   * @param interfaceID The interface identifier, as specified in ERC-165.
   * @return True if the contract implements `interfaceID` and
   * `interfaceID` is not 0xffffffff, false otherwise.
   */
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { IERC165, ERC165_INTERFACE_ID } from "./IERC165.sol";

/**
 * @dev World Context Consumer Interface
 * This interface defines the functions a contract needs to consume the world context.
 * It includes helper functions to retrieve the message sender, value, and world address.
 * Additionally, it integrates with the ERC-165 standard for interface detection.
 */

bytes4 constant WORLD_CONTEXT_CONSUMER_INTERFACE_ID = IWorldContextConsumer._msgSender.selector ^
  IWorldContextConsumer._msgValue.selector ^
  IWorldContextConsumer._world.selector ^
  ERC165_INTERFACE_ID;

/**
 * @title WorldContextConsumer - Extracting trusted context values from appended calldata.
 * @notice This contract is designed to extract trusted context values (like msg.sender and msg.value)
 * from the appended calldata. It provides mechanisms similar to EIP-2771 (https://eips.ethereum.org/EIPS/eip-2771),
 * but allowing any contract to be the trusted forwarder.
 * @dev This contract should only be used for contracts without their own storage, like Systems.
 */
interface IWorldContextConsumer is IERC165 {
  /**
   * @notice Extract the `msg.sender` from the context appended to the calldata.
   * @return The address of the `msg.sender` that called the World contract
   * before the World routed the call to the WorldContextConsumer contract.
   */
  function _msgSender() external view returns (address);

  /**
   * @notice Extract the `msg.value` from the context appended to the calldata.
   * @return The `msg.value` in the call to the World contract before the World routed the
   * call to the WorldContextConsumer contract.
   */
  function _msgValue() external view returns (uint256);

  /**
   * @notice Get the address of the World contract that routed the call to this WorldContextConsumer.
   * @return The address of the World contract that routed the call to this WorldContextConsumer.
   */
  function _world() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/**
 * @title Raw Bytes Reverter
 * @notice Utility function to revert transactions with raw bytes.
 * @dev This can be especially useful when reverting with a message obtained from a low-level call or a pre-encoded error.
 */

/**
 * @notice Reverts the transaction using the provided raw bytes as the revert reason.
 * @dev Uses assembly to perform the revert operation with the raw bytes.
 * @param reason The raw bytes revert reason.
 */
function revertWithBytes(bytes memory reason) pure {
  assembly {
    // reason+32 is a pointer to the error message, mload(reason) is the length of the error message
    revert(add(reason, 0x20), mload(reason))
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { WorldContextConsumer } from "./WorldContext.sol";

/**
 * @title System
 * @dev The System contract currently acts as an alias for `WorldContextConsumer`.
 * This structure is chosen for potential extensions in the future, where default functionality might be added to the System.
 */

contract System is WorldContextConsumer {
  // Currently, no additional functionality is added. Future enhancements can be introduced here.
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { revertWithBytes } from "./revertWithBytes.sol";
import { ERC165_INTERFACE_ID } from "./IERC165.sol";
import { IWorldContextConsumer, WORLD_CONTEXT_CONSUMER_INTERFACE_ID } from "./IWorldContextConsumer.sol";

// The context size is 20 bytes for msg.sender, and 32 bytes for msg.value
uint256 constant CONTEXT_BYTES = 20 + 32;

/**
 * @title WorldContextConsumer - Extracting trusted context values from appended calldata.
 * @notice This contract is designed to extract trusted context values (like msg.sender and msg.value)
 * from the appended calldata. It provides mechanisms similar to EIP-2771 (https://eips.ethereum.org/EIPS/eip-2771),
 * but allowing any contract to be the trusted forwarder.
 * @dev This contract should only be used for contracts without their own storage, like Systems.
 */
abstract contract WorldContextConsumer is IWorldContextConsumer {
  /**
   * @notice Extract the `msg.sender` from the context appended to the calldata.
   * @return sender The `msg.sender` in the call to the World contract before the World routed the
   * call to the WorldContextConsumer contract.
   */
  function _msgSender() public view returns (address sender) {
    return WorldContextConsumerLib._msgSender();
  }

  /**
   * @notice Extract the `msg.value` from the context appended to the calldata.
   * @return value The `msg.value` in the call to the World contract before the World routed the
   * call to the WorldContextConsumer contract.
   */
  function _msgValue() public pure returns (uint256 value) {
    return WorldContextConsumerLib._msgValue();
  }

  /**
   * @notice Get the address of the World contract that routed the call to this WorldContextConsumer.
   * @return The address of the World contract that routed the call to this WorldContextConsumer.
   */
  function _world() public view returns (address) {
    return StoreSwitch.getStoreAddress();
  }

  /**
   * @notice Checks if an interface is supported by the contract.
   * using ERC-165 supportsInterface (see https://eips.ethereum.org/EIPS/eip-165)
   * @param interfaceId The ID of the interface in question.
   * @return True if the interface is supported, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return interfaceId == WORLD_CONTEXT_CONSUMER_INTERFACE_ID || interfaceId == ERC165_INTERFACE_ID;
  }
}

library WorldContextConsumerLib {
  /**
   * @notice Extract the `msg.sender` from the context appended to the calldata.
   * @return sender The `msg.sender` in the call to the World contract before the World routed the
   * call to the WorldContextConsumer contract.
   */
  function _msgSender() internal view returns (address sender) {
    assembly {
      // Load 32 bytes from calldata at position calldatasize() - context size,
      // then shift left 96 bits (to right-align the address)
      // 96 = 256 - 20 * 8
      sender := shr(96, calldataload(sub(calldatasize(), CONTEXT_BYTES)))
    }
    if (sender == address(0)) sender = msg.sender;
  }

  /**
   * @notice Extract the `msg.value` from the context appended to the calldata.
   * @return value The `msg.value` in the call to the World contract before the World routed the
   * call to the WorldContextConsumer contract.
   */
  function _msgValue() internal pure returns (uint256 value) {
    assembly {
      // Load 32 bytes from calldata at position calldatasize() - 32 bytes,
      value := calldataload(sub(calldatasize(), 32))
    }
  }

  /**
   * @notice Get the address of the World contract that routed the call to this WorldContextConsumer.
   * @return The address of the World contract that routed the call to this WorldContextConsumer.
   */
  function _world() internal view returns (address) {
    return StoreSwitch.getStoreAddress();
  }
}

/**
 * @title WorldContextProviderLib - Utility functions to call contracts with context values appended to calldata.
 * @notice This library provides functions to make calls or delegatecalls to other contracts,
 * appending the context values (like msg.sender and msg.value) to the calldata for WorldContextConsumer to consume.
 */
library WorldContextProviderLib {
  /**
   * @notice Appends context values to the given calldata.
   * @param callData The original calldata.
   * @param msgSender The address of the transaction sender.
   * @param msgValue The amount of ether sent with the original transaction.
   * @return The new calldata with context values appended.
   */
  function appendContext(
    bytes memory callData,
    address msgSender,
    uint256 msgValue
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(callData, msgSender, msgValue);
  }

  /**
   * @notice Makes a call to the target contract with context values appended to the calldata.
   * @param msgSender The address of the transaction sender.
   * @param msgValue The amount of ether sent with the original transaction.
   * @param target The address of the contract to call.
   * @param callData The calldata for the call.
   * @return success A boolean indicating whether the call was successful or not.
   * @return data The abi encoded return data from the call.
   */
  function callWithContext(
    address msgSender,
    uint256 msgValue,
    address target,
    bytes memory callData
  ) internal returns (bool success, bytes memory data) {
    (success, data) = target.call{ value: 0 }(
      appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
  }

  /**
   * @notice Makes a delegatecall to the target contract with context values appended to the calldata.
   * @param msgSender The address of the transaction sender.
   * @param msgValue The amount of ether sent with the original transaction.
   * @param target The address of the contract to call.
   * @param callData The calldata for the call.
   * @return success A boolean indicating whether the call was successful or not.
   * @return data The abi encoded return data from the call.
   */
  function delegatecallWithContext(
    address msgSender,
    uint256 msgValue,
    address target,
    bytes memory callData
  ) internal returns (bool success, bytes memory data) {
    (success, data) = target.delegatecall(
      appendContext({ callData: callData, msgSender: msgSender, msgValue: msgValue })
    );
  }

  /**
   * @notice Makes a call to the target contract with context values appended to the calldata.
   * @dev Revert in the case of failure.
   * @param msgSender The address of the transaction sender.
   * @param msgValue The amount of ether sent with the original transaction.
   * @param target The address of the contract to call.
   * @param callData The calldata for the call.
   * @return data The abi encoded return data from the call.
   */
  function callWithContextOrRevert(
    address msgSender,
    uint256 msgValue,
    address target,
    bytes memory callData
  ) internal returns (bytes memory data) {
    (bool success, bytes memory _data) = callWithContext({
      msgSender: msgSender,
      msgValue: msgValue,
      target: target,
      callData: callData
    });
    if (!success) revertWithBytes(_data);
    return _data;
  }

  /**
   * @notice Makes a delegatecall to the target contract with context values appended to the calldata.
   * @dev Revert in the case of failure.
   * @param msgSender The address of the transaction sender.
   * @param msgValue The amount of ether sent with the original transaction.
   * @param target The address of the contract to call.
   * @param callData The calldata for the call.
   * @return data The abi encoded return data from the call.
   */
  function delegatecallWithContextOrRevert(
    address msgSender,
    uint256 msgValue,
    address target,
    bytes memory callData
  ) internal returns (bytes memory data) {
    (bool success, bytes memory _data) = delegatecallWithContext({
      msgSender: msgSender,
      msgValue: msgValue,
      target: target,
      callData: callData
    });
    if (!success) revertWithBytes(_data);
    return _data;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

import { Bullets, BulletsTableId } from "./tables/Bullets.sol";
import { PlayerPosition, PlayerPositionData, PlayerPositionTableId } from "./tables/PlayerPosition.sol";
import { Ethers, EthersData, EthersTableId } from "./tables/Ethers.sol";
import { EthersArrangement, EthersArrangementData, EthersArrangementTableId } from "./tables/EthersArrangement.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema, SchemaLib } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter, PackedCounterLib } from "@latticexyz/store/src/PackedCounter.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14(""), bytes16("Bullets")))
);
ResourceId constant BulletsTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0020010020000000000000000000000000000000000000000000000000000000
);

library Bullets {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](1);
    _valueSchema[0] = SchemaType.UINT256;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "key";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](1);
    fieldNames[0] = "value";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get value.
   */
  function getValue(bytes32 key) internal view returns (uint256 value) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get value.
   */
  function _getValue(bytes32 key) internal view returns (uint256 value) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get value.
   */
  function get(bytes32 key) internal view returns (uint256 value) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get value.
   */
  function _get(bytes32 key) internal view returns (uint256 value) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set value.
   */
  function setValue(bytes32 key, uint256 value) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((value)), _fieldLayout);
  }

  /**
   * @notice Set value.
   */
  function _setValue(bytes32 key, uint256 value) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((value)), _fieldLayout);
  }

  /**
   * @notice Set value.
   */
  function set(bytes32 key, uint256 value) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((value)), _fieldLayout);
  }

  /**
   * @notice Set value.
   */
  function _set(bytes32 key, uint256 value) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((value)), _fieldLayout);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(uint256 value) internal pure returns (bytes memory) {
    return abi.encodePacked(value);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(uint256 value) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(value);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 key) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema, SchemaLib } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter, PackedCounterLib } from "@latticexyz/store/src/PackedCounter.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14(""), bytes16("Ethers")))
);
ResourceId constant EthersTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0040020020200000000000000000000000000000000000000000000000000000
);

struct EthersData {
  uint256 amount;
  uint256 wreckedAmount;
}

library Ethers {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](2);
    _valueSchema[0] = SchemaType.UINT256;
    _valueSchema[1] = SchemaType.UINT256;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "key";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](2);
    fieldNames[0] = "amount";
    fieldNames[1] = "wreckedAmount";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get amount.
   */
  function getAmount(bytes32 key) internal view returns (uint256 amount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get amount.
   */
  function _getAmount(bytes32 key) internal view returns (uint256 amount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set amount.
   */
  function setAmount(bytes32 key, uint256 amount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((amount)), _fieldLayout);
  }

  /**
   * @notice Set amount.
   */
  function _setAmount(bytes32 key, uint256 amount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((amount)), _fieldLayout);
  }

  /**
   * @notice Get wreckedAmount.
   */
  function getWreckedAmount(bytes32 key) internal view returns (uint256 wreckedAmount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Get wreckedAmount.
   */
  function _getWreckedAmount(bytes32 key) internal view returns (uint256 wreckedAmount) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (uint256(bytes32(_blob)));
  }

  /**
   * @notice Set wreckedAmount.
   */
  function setWreckedAmount(bytes32 key, uint256 wreckedAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((wreckedAmount)), _fieldLayout);
  }

  /**
   * @notice Set wreckedAmount.
   */
  function _setWreckedAmount(bytes32 key, uint256 wreckedAmount) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((wreckedAmount)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(bytes32 key) internal view returns (EthersData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(bytes32 key) internal view returns (EthersData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(bytes32 key, uint256 amount, uint256 wreckedAmount) internal {
    bytes memory _staticData = encodeStatic(amount, wreckedAmount);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(bytes32 key, uint256 amount, uint256 wreckedAmount) internal {
    bytes memory _staticData = encodeStatic(amount, wreckedAmount);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 key, EthersData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.amount, _table.wreckedAmount);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 key, EthersData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.amount, _table.wreckedAmount);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (uint256 amount, uint256 wreckedAmount) {
    amount = (uint256(Bytes.slice32(_blob, 0)));

    wreckedAmount = (uint256(Bytes.slice32(_blob, 32)));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    PackedCounter,
    bytes memory
  ) internal pure returns (EthersData memory _table) {
    (_table.amount, _table.wreckedAmount) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(uint256 amount, uint256 wreckedAmount) internal pure returns (bytes memory) {
    return abi.encodePacked(amount, wreckedAmount);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(
    uint256 amount,
    uint256 wreckedAmount
  ) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(amount, wreckedAmount);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 key) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema, SchemaLib } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter, PackedCounterLib } from "@latticexyz/store/src/PackedCounter.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14(""), bytes16("EthersArrangemen")))
);
ResourceId constant EthersArrangementTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0060030020202000000000000000000000000000000000000000000000000000
);

struct EthersArrangementData {
  int256 x;
  int256 y;
  int256 z;
}

library EthersArrangement {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](2);
    _keySchema[0] = SchemaType.BYTES32;
    _keySchema[1] = SchemaType.UINT256;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](3);
    _valueSchema[0] = SchemaType.INT256;
    _valueSchema[1] = SchemaType.INT256;
    _valueSchema[2] = SchemaType.INT256;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](2);
    keyNames[0] = "entityId";
    keyNames[1] = "etherId";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](3);
    fieldNames[0] = "x";
    fieldNames[1] = "y";
    fieldNames[2] = "z";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get x.
   */
  function getX(bytes32 entityId, uint256 etherId) internal view returns (int256 x) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get x.
   */
  function _getX(bytes32 entityId, uint256 etherId) internal view returns (int256 x) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set x.
   */
  function setX(bytes32 entityId, uint256 etherId, int256 x) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((x)), _fieldLayout);
  }

  /**
   * @notice Set x.
   */
  function _setX(bytes32 entityId, uint256 etherId, int256 x) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((x)), _fieldLayout);
  }

  /**
   * @notice Get y.
   */
  function getY(bytes32 entityId, uint256 etherId) internal view returns (int256 y) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get y.
   */
  function _getY(bytes32 entityId, uint256 etherId) internal view returns (int256 y) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set y.
   */
  function setY(bytes32 entityId, uint256 etherId, int256 y) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((y)), _fieldLayout);
  }

  /**
   * @notice Set y.
   */
  function _setY(bytes32 entityId, uint256 etherId, int256 y) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((y)), _fieldLayout);
  }

  /**
   * @notice Get z.
   */
  function getZ(bytes32 entityId, uint256 etherId) internal view returns (int256 z) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get z.
   */
  function _getZ(bytes32 entityId, uint256 etherId) internal view returns (int256 z) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set z.
   */
  function setZ(bytes32 entityId, uint256 etherId, int256 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((z)), _fieldLayout);
  }

  /**
   * @notice Set z.
   */
  function _setZ(bytes32 entityId, uint256 etherId, int256 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((z)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(bytes32 entityId, uint256 etherId) internal view returns (EthersArrangementData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(bytes32 entityId, uint256 etherId) internal view returns (EthersArrangementData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(bytes32 entityId, uint256 etherId, int256 x, int256 y, int256 z) internal {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(bytes32 entityId, uint256 etherId, int256 x, int256 y, int256 z) internal {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 entityId, uint256 etherId, EthersArrangementData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.x, _table.y, _table.z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 entityId, uint256 etherId, EthersArrangementData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.x, _table.y, _table.z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (int256 x, int256 y, int256 z) {
    x = (int256(uint256(Bytes.slice32(_blob, 0))));

    y = (int256(uint256(Bytes.slice32(_blob, 32))));

    z = (int256(uint256(Bytes.slice32(_blob, 64))));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    PackedCounter,
    bytes memory
  ) internal pure returns (EthersArrangementData memory _table) {
    (_table.x, _table.y, _table.z) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 entityId, uint256 etherId) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 entityId, uint256 etherId) internal {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(int256 x, int256 y, int256 z) internal pure returns (bytes memory) {
    return abi.encodePacked(x, y, z);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(int256 x, int256 y, int256 z) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 entityId, uint256 etherId) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](2);
    _keyTuple[0] = entityId;
    _keyTuple[1] = bytes32(uint256(etherId));

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;

/* Autogenerated file. Do not edit manually. */

// Import schema type
import { SchemaType } from "@latticexyz/schema-type/src/solidity/SchemaType.sol";

// Import store internals
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { StoreCore } from "@latticexyz/store/src/StoreCore.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Memory } from "@latticexyz/store/src/Memory.sol";
import { SliceLib } from "@latticexyz/store/src/Slice.sol";
import { EncodeArray } from "@latticexyz/store/src/tightcoder/EncodeArray.sol";
import { FieldLayout, FieldLayoutLib } from "@latticexyz/store/src/FieldLayout.sol";
import { Schema, SchemaLib } from "@latticexyz/store/src/Schema.sol";
import { PackedCounter, PackedCounterLib } from "@latticexyz/store/src/PackedCounter.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { RESOURCE_TABLE, RESOURCE_OFFCHAIN_TABLE } from "@latticexyz/store/src/storeResourceTypes.sol";

ResourceId constant _tableId = ResourceId.wrap(
  bytes32(abi.encodePacked(RESOURCE_TABLE, bytes14(""), bytes16("PlayerPosition")))
);
ResourceId constant PlayerPositionTableId = _tableId;

FieldLayout constant _fieldLayout = FieldLayout.wrap(
  0x0060030020202000000000000000000000000000000000000000000000000000
);

struct PlayerPositionData {
  int256 x;
  int256 y;
  int256 z;
}

library PlayerPosition {
  /**
   * @notice Get the table values' field layout.
   * @return _fieldLayout The field layout for the table.
   */
  function getFieldLayout() internal pure returns (FieldLayout) {
    return _fieldLayout;
  }

  /**
   * @notice Get the table's key schema.
   * @return _keySchema The key schema for the table.
   */
  function getKeySchema() internal pure returns (Schema) {
    SchemaType[] memory _keySchema = new SchemaType[](1);
    _keySchema[0] = SchemaType.BYTES32;

    return SchemaLib.encode(_keySchema);
  }

  /**
   * @notice Get the table's value schema.
   * @return _valueSchema The value schema for the table.
   */
  function getValueSchema() internal pure returns (Schema) {
    SchemaType[] memory _valueSchema = new SchemaType[](3);
    _valueSchema[0] = SchemaType.INT256;
    _valueSchema[1] = SchemaType.INT256;
    _valueSchema[2] = SchemaType.INT256;

    return SchemaLib.encode(_valueSchema);
  }

  /**
   * @notice Get the table's key field names.
   * @return keyNames An array of strings with the names of key fields.
   */
  function getKeyNames() internal pure returns (string[] memory keyNames) {
    keyNames = new string[](1);
    keyNames[0] = "key";
  }

  /**
   * @notice Get the table's value field names.
   * @return fieldNames An array of strings with the names of value fields.
   */
  function getFieldNames() internal pure returns (string[] memory fieldNames) {
    fieldNames = new string[](3);
    fieldNames[0] = "x";
    fieldNames[1] = "y";
    fieldNames[2] = "z";
  }

  /**
   * @notice Register the table with its config.
   */
  function register() internal {
    StoreSwitch.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Register the table with its config.
   */
  function _register() internal {
    StoreCore.registerTable(_tableId, _fieldLayout, getKeySchema(), getValueSchema(), getKeyNames(), getFieldNames());
  }

  /**
   * @notice Get x.
   */
  function getX(bytes32 key) internal view returns (int256 x) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get x.
   */
  function _getX(bytes32 key) internal view returns (int256 x) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 0, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set x.
   */
  function setX(bytes32 key, int256 x) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((x)), _fieldLayout);
  }

  /**
   * @notice Set x.
   */
  function _setX(bytes32 key, int256 x) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 0, abi.encodePacked((x)), _fieldLayout);
  }

  /**
   * @notice Get y.
   */
  function getY(bytes32 key) internal view returns (int256 y) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get y.
   */
  function _getY(bytes32 key) internal view returns (int256 y) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 1, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set y.
   */
  function setY(bytes32 key, int256 y) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((y)), _fieldLayout);
  }

  /**
   * @notice Set y.
   */
  function _setY(bytes32 key, int256 y) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 1, abi.encodePacked((y)), _fieldLayout);
  }

  /**
   * @notice Get z.
   */
  function getZ(bytes32 key) internal view returns (int256 z) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreSwitch.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Get z.
   */
  function _getZ(bytes32 key) internal view returns (int256 z) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    bytes32 _blob = StoreCore.getStaticField(_tableId, _keyTuple, 2, _fieldLayout);
    return (int256(uint256(bytes32(_blob))));
  }

  /**
   * @notice Set z.
   */
  function setZ(bytes32 key, int256 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((z)), _fieldLayout);
  }

  /**
   * @notice Set z.
   */
  function _setZ(bytes32 key, int256 z) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setStaticField(_tableId, _keyTuple, 2, abi.encodePacked((z)), _fieldLayout);
  }

  /**
   * @notice Get the full data.
   */
  function get(bytes32 key) internal view returns (PlayerPositionData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreSwitch.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Get the full data.
   */
  function _get(bytes32 key) internal view returns (PlayerPositionData memory _table) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    (bytes memory _staticData, PackedCounter _encodedLengths, bytes memory _dynamicData) = StoreCore.getRecord(
      _tableId,
      _keyTuple,
      _fieldLayout
    );
    return decode(_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function set(bytes32 key, int256 x, int256 y, int256 z) internal {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using individual values.
   */
  function _set(bytes32 key, int256 x, int256 y, int256 z) internal {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function set(bytes32 key, PlayerPositionData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.x, _table.y, _table.z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Set the full data using the data struct.
   */
  function _set(bytes32 key, PlayerPositionData memory _table) internal {
    bytes memory _staticData = encodeStatic(_table.x, _table.y, _table.z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.setRecord(_tableId, _keyTuple, _staticData, _encodedLengths, _dynamicData, _fieldLayout);
  }

  /**
   * @notice Decode the tightly packed blob of static data using this table's field layout.
   */
  function decodeStatic(bytes memory _blob) internal pure returns (int256 x, int256 y, int256 z) {
    x = (int256(uint256(Bytes.slice32(_blob, 0))));

    y = (int256(uint256(Bytes.slice32(_blob, 32))));

    z = (int256(uint256(Bytes.slice32(_blob, 64))));
  }

  /**
   * @notice Decode the tightly packed blobs using this table's field layout.
   * @param _staticData Tightly packed static fields.
   *
   *
   */
  function decode(
    bytes memory _staticData,
    PackedCounter,
    bytes memory
  ) internal pure returns (PlayerPositionData memory _table) {
    (_table.x, _table.y, _table.z) = decodeStatic(_staticData);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreSwitch.deleteRecord(_tableId, _keyTuple);
  }

  /**
   * @notice Delete all data for given keys.
   */
  function _deleteRecord(bytes32 key) internal {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    StoreCore.deleteRecord(_tableId, _keyTuple, _fieldLayout);
  }

  /**
   * @notice Tightly pack static (fixed length) data using this table's schema.
   * @return The static data, encoded into a sequence of bytes.
   */
  function encodeStatic(int256 x, int256 y, int256 z) internal pure returns (bytes memory) {
    return abi.encodePacked(x, y, z);
  }

  /**
   * @notice Encode all of a record's fields.
   * @return The static (fixed length) data, encoded into a sequence of bytes.
   * @return The lengths of the dynamic fields (packed into a single bytes32 value).
   * @return The dyanmic (variable length) data, encoded into a sequence of bytes.
   */
  function encode(int256 x, int256 y, int256 z) internal pure returns (bytes memory, PackedCounter, bytes memory) {
    bytes memory _staticData = encodeStatic(x, y, z);

    PackedCounter _encodedLengths;
    bytes memory _dynamicData;

    return (_staticData, _encodedLengths, _dynamicData);
  }

  /**
   * @notice Encode keys as a bytes32 array using this table's field layout.
   */
  function encodeKeyTuple(bytes32 key) internal pure returns (bytes32[] memory) {
    bytes32[] memory _keyTuple = new bytes32[](1);
    _keyTuple[0] = key;

    return _keyTuple;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

struct Position {
    int256 x;
    int256 y;
    int256 z;
}

struct PlayerStats {
    uint256 bullets;
    Position currentPosition;
    uint256 ethersAmount;
    mapping(uint256 => Position) ethersPosition;
    uint256 wreckedEthers;
}

struct PlayerStatsResponse {
    uint256 bullets;
    Position currentPosition;
    uint256 ethersAmount;
    Position[] ethersPosition;
    uint256[] ethersId;
    uint256 wreckedEthers;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.21;
import {System} from "@latticexyz/world/src/System.sol";
import {PlayerPosition, PlayerPositionData, Bullets, Ethers, EthersData, EthersArrangement, EthersArrangementData} from "../codegen/index.sol";
import {Position, PlayerStats, PlayerStatsResponse} from "../interfaces/Types.sol";

contract GameSystem is System {
    uint public bulletPrice = 0.001 ether;

    function start(int256[3][] calldata ethersPosition_) external {
        bytes32 entityId = bytes32(uint256(uint160((_msgSender()))));

        EthersData memory ethers = Ethers.get(entityId);
        require(ethers.amount <= ethers.wreckedAmount, "Game is not over");

        uint amount = ethersPosition_.length;
        Ethers.setAmount(entityId, amount);

        for (uint i = 0; i < amount; ) {
            EthersArrangement.set(
                entityId,
                i,
                EthersArrangementData({x: ethersPosition_[i][0], y: ethersPosition_[i][1], z: ethersPosition_[i][2]})
            );

            unchecked {
                ++i;
            }
        }
    }

    function buyBullets(uint amount_) external payable {
        require(amount_ * bulletPrice <= msg.value, "Not enough funds");

        bytes32 entityId = bytes32(uint256(uint160((_msgSender()))));

        uint256 bullets = Bullets.get(entityId);
        Bullets.set(entityId, bullets + amount_);
    }

    function getGameData() external view returns (PlayerStatsResponse memory) {
        bytes32 entityId = bytes32(uint256(uint160((_msgSender()))));

        EthersData memory ethers = Ethers.get(entityId);

        uint liveEthersAmount = ethers.amount - ethers.wreckedAmount;
        Position[] memory ethersPositionArray = new Position[](liveEthersAmount);
        uint[] memory ethersIdArray = new uint[](liveEthersAmount);
        uint pushId;

        for (uint i = 0; i < ethers.amount && pushId < liveEthersAmount; ) {
            if (
                EthersArrangement.get(entityId, i).x != 0 &&
                EthersArrangement.get(entityId, i).y != 0 &&
                EthersArrangement.get(entityId, i).z != 0
            ) {
                ethersPositionArray[pushId] = Position({
                    x: EthersArrangement.get(entityId, i).x,
                    y: EthersArrangement.get(entityId, i).y,
                    z: EthersArrangement.get(entityId, i).z
                });
                ethersIdArray[pushId] = i;

                unchecked {
                    ++pushId;
                }
            }

            unchecked {
                ++i;
            }
        }

        return
            PlayerStatsResponse({
                bullets: Bullets.get(entityId),
                currentPosition: Position({
                    x: PlayerPosition.get(entityId).x,
                    y: PlayerPosition.get(entityId).y,
                    z: PlayerPosition.get(entityId).z
                }),
                ethersAmount: ethers.amount,
                ethersPosition: ethersPositionArray,
                ethersId: ethersIdArray,
                wreckedEthers: ethers.wreckedAmount
            });
    }

    function registerAction(
        uint[] calldata removeEtherIds_,
        uint shotBulletsAmount_,
        Position calldata newPlayerPosition_
    ) external {
        bytes32 entityId = bytes32(uint256(uint160((_msgSender()))));

        if (shotBulletsAmount_ > 0) {
            uint256 bullets = Bullets.get(entityId);
            require(bullets >= shotBulletsAmount_, "No more bullets");

            Bullets.set(entityId, bullets - shotBulletsAmount_);
        }

        if (removeEtherIds_.length > 0) {
            uint256 wreckedAmount = removeEtherIds_.length;

            EthersData memory ethers = Ethers.get(entityId);
            require(ethers.amount >= ethers.wreckedAmount + wreckedAmount, "No more ethers");

            Ethers.setWreckedAmount(entityId, ethers.wreckedAmount + wreckedAmount);

            for (uint i = 0; i < wreckedAmount; ) {
                EthersArrangement.set(entityId, i, EthersArrangementData(0, 0, 0));

                unchecked {
                    ++i;
                }
            }
        }

        if (newPlayerPosition_.x != 0 && newPlayerPosition_.y != 0 && newPlayerPosition_.z != 0) {
            PlayerPosition.set(entityId, newPlayerPosition_.x, newPlayerPosition_.y, newPlayerPosition_.z);
        }
    }
}