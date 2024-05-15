// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../WitnetRequestBytecodes.sol";
import "../libs/WitnetV2.sol";

/// @title Witnet Request Board base data model library
/// @author The Witnet Foundation.
library WitnetOracleDataLib {  

    using WitnetV2 for WitnetV2.Request;

    bytes32 internal constant _WITNET_ORACLE_DATA_SLOTHASH =
        /* keccak256("io.witnet.boards.data") */
        0xf595240b351bc8f951c2f53b26f4e78c32cb62122cf76c19b7fdda7d4968e183;

    struct Storage {
        uint256 nonce;
        mapping (uint => WitnetV2.Query) queries;
        mapping (address => bool) reporters;
    }

    // ================================================================================================================
    // --- Internal functions -----------------------------------------------------------------------------------------

    /// Returns storage pointer to contents of 'WitnetBoardState' struct.
    function data() internal pure returns (Storage storage _ptr)
    {
        assembly {
            _ptr.slot := _WITNET_ORACLE_DATA_SLOTHASH
        }
    }

    function isReporter(address addr) internal view returns (bool) {
        return data().reporters[addr];
    }

    /// Gets query storage by query id.
    function seekQuery(uint256 _queryId) internal view returns (WitnetV2.Query storage) {
      return data().queries[_queryId];
    }

    /// Gets the Witnet.Request part of a given query.
    function seekQueryRequest(uint256 _queryId) internal view returns (WitnetV2.Request storage) {
        return data().queries[_queryId].request;
    }   

    /// Gets the Witnet.Result part of a given query.
    function seekQueryResponse(uint256 _queryId) internal view returns (WitnetV2.Response storage) {
        return data().queries[_queryId].response;
    }

    function seekQueryStatus(uint256 queryId) internal view returns (WitnetV2.QueryStatus) {
        WitnetV2.Query storage __query = data().queries[queryId];
        if (__query.response.resultTimestamp != 0) {
            if (block.number >= __query.response.finality) {
                return WitnetV2.QueryStatus.Finalized;
            } else {
                return WitnetV2.QueryStatus.Reported;
            }
        } else if (__query.request.requester != address(0)) {
            return WitnetV2.QueryStatus.Posted;
        } else {
            return WitnetV2.QueryStatus.Unknown;
        }
    }

    function seekQueryResponseStatus(uint256 queryId) internal view returns (WitnetV2.ResponseStatus) {
        WitnetV2.QueryStatus _queryStatus = seekQueryStatus(queryId);
        if (_queryStatus == WitnetV2.QueryStatus.Finalized) {
            bytes storage __cborValues = data().queries[queryId].response.resultCborBytes;
            if (__cborValues.length > 0) {
                // determine whether stored result is an error by peeking the first byte
                return (__cborValues[0] == bytes1(0xd8)
                    ? WitnetV2.ResponseStatus.Error 
                    : WitnetV2.ResponseStatus.Ready
                );
            } else {
                // the result is final but delivered to the requesting address
                return WitnetV2.ResponseStatus.Delivered;
            }
        } else if (_queryStatus == WitnetV2.QueryStatus.Posted) {
            return WitnetV2.ResponseStatus.Awaiting;
        } else if (_queryStatus == WitnetV2.QueryStatus.Reported) {
            return WitnetV2.ResponseStatus.Finalizing;
        } else {
            return WitnetV2.ResponseStatus.Void;
        }
    }

    // ================================================================================================================
    // --- Public functions -------------------------------------------------------------------------------------------

    function extractWitnetDataRequests(WitnetRequestBytecodes registry, uint256[] calldata queryIds)
        public view
        returns (bytes[] memory bytecodes)
    {
        bytecodes = new bytes[](queryIds.length);
        for (uint _ix = 0; _ix < queryIds.length; _ix ++) {
            if (seekQueryStatus(queryIds[_ix]) != WitnetV2.QueryStatus.Unknown) {
                WitnetV2.Request storage __request = data().queries[queryIds[_ix]].request;
                if (__request.witnetRAD != bytes32(0)) {
                    bytecodes[_ix] = registry.bytecodeOf(
                        __request.witnetRAD,
                        __request.witnetSLA
                    );
                } else {
                    bytecodes[_ix] = registry.bytecodeOf(
                        __request.witnetBytecode,
                        __request.witnetSLA 
                    );
                }
            }
        }
    }

    function notInStatusRevertMessage(WitnetV2.QueryStatus self) public pure returns (string memory) {
        if (self == WitnetV2.QueryStatus.Posted) {
            return "query not in Posted status";
        } else if (self == WitnetV2.QueryStatus.Reported) {
            return "query not in Reported status";
        } else if (self == WitnetV2.QueryStatus.Finalized) {
            return "query not in Finalized status";
        } else {
            return "bad mood";
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Witnet.sol";

library WitnetV2 {

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Finalized
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        address requester;              // EVM address from which the request was posted.
        uint24  gasCallback;            // Max callback gas limit upon response, if a callback is required.
        uint72  evmReward;              // EVM amount in wei eventually to be paid to the legit result reporter.
        bytes   witnetBytecode;         // Optional: Witnet Data Request bytecode to be solved by the Witnet blockchain.
        bytes32 witnetRAD;              // Optional: Previously verified hash of the Witnet Data Request to be solved.
        WitnetV2.RadonSLA witnetSLA;    // Minimum Service-Level parameters to be committed by the Witnet blockchain. 
    }

    /// Response metadata and result as resolved by the Witnet blockchain.
    struct Response {
        address reporter;               // EVM address from which the Data Request result was reported.
        uint64  finality;               // EVM block number at which the reported data will be considered to be finalized.
        uint32  resultTimestamp;        // Unix timestamp (seconds) at which the data request was resolved in the Witnet blockchain.
        bytes32 resultTallyHash;        // Unique hash of the commit/reveal act in the Witnet blockchain that resolved the data request.
        bytes   resultCborBytes;        // CBOR-encode result to the request, as resolved in the Witnet blockchain.
    }

    /// Response status from a requester's point of view.
    enum ResponseStatus {
        Void,
        Awaiting,
        Ready,
        Error,
        Finalizing,
        Delivered
    }

    struct RadonSLA {
        /// @notice Number of nodes in the Witnet blockchain that will take part in solving the data request. 
        uint8   committeeSize;
        
        /// @notice Fee in $nanoWIT paid to every node in the Witnet blockchain involved in solving the data request.
        /// @dev Witnet nodes participating as witnesses will have to stake as collateral 100x this amount.
        uint64  witnessingFeeNanoWit;
    }

    
    /// ===============================================================================================================
    /// --- 'WitnetV2.RadonSLA' helper methods ------------------------------------------------------------------------

    function equalOrGreaterThan(RadonSLA memory a, RadonSLA memory b) 
        internal pure returns (bool)
    {
        return (a.committeeSize >= b.committeeSize);
    }
     
    function isValid(RadonSLA calldata sla) internal pure returns (bool) {
        return (
            sla.witnessingFeeNanoWit > 0 
                && sla.committeeSize > 0 && sla.committeeSize <= 127
                // v1.7.x requires witnessing collateral to be greater or equal to 20 WIT:
                && sla.witnessingFeeNanoWit * 100 >= 20 * 10 ** 9 
        );
    }

    function toV1(RadonSLA memory self) internal pure returns (Witnet.RadonSLA memory) {
        return Witnet.RadonSLA({
            numWitnesses: self.committeeSize,
            minConsensusPercentage: 51,
            witnessReward: self.witnessingFeeNanoWit,
            witnessCollateral: self.witnessingFeeNanoWit * 100,
            minerCommitRevealFee: self.witnessingFeeNanoWit / self.committeeSize
        });
    }

    function nanoWitTotalFee(RadonSLA storage self) internal view returns (uint64) {
        return self.witnessingFeeNanoWit * (self.committeeSize + 3);
    }


    /// ===============================================================================================================
    /// --- P-RNG generators ------------------------------------------------------------------------------------------

    /// Generates a pseudo-random uint32 number uniformly distributed within the range `[0 .. range)`, based on
    /// the given `nonce` and `seed` values. 
    function randomUniformUint32(uint32 range, uint256 nonce, bytes32 seed)
        internal pure 
        returns (uint32) 
    {
        uint256 _number = uint256(
            keccak256(
                abi.encode(seed, nonce)
            )
        ) & uint256(2 ** 224 - 1);
        return uint32((_number * range) >> 224);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./WitnetBuffer.sol";

/// @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
/// @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
/// the gas cost of decoding them into a useful native type.
/// @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
/// @author The Witnet Foundation.

library WitnetCBOR {

  using WitnetBuffer for WitnetBuffer.Buffer;
  using WitnetCBOR for WitnetCBOR.CBOR;

  /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
  struct CBOR {
      WitnetBuffer.Buffer buffer;
      uint8 initialByte;
      uint8 majorType;
      uint8 additionalInformation;
      uint64 len;
      uint64 tag;
  }

  uint8 internal constant MAJOR_TYPE_INT = 0;
  uint8 internal constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 internal constant MAJOR_TYPE_BYTES = 2;
  uint8 internal constant MAJOR_TYPE_STRING = 3;
  uint8 internal constant MAJOR_TYPE_ARRAY = 4;
  uint8 internal constant MAJOR_TYPE_MAP = 5;
  uint8 internal constant MAJOR_TYPE_TAG = 6;
  uint8 internal constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint64 internal constant UINT64_MAX = type(uint64).max;
  
  error EmptyArray();
  error InvalidLengthEncoding(uint length);
  error UnexpectedMajorType(uint read, uint expected);
  error UnsupportedPrimitive(uint primitive);
  error UnsupportedMajorType(uint unexpected);  

  modifier isMajorType(
      WitnetCBOR.CBOR memory cbor,
      uint8 expected
  ) {
    if (cbor.majorType != expected) {
      revert UnexpectedMajorType(cbor.majorType, expected);
    }
    _;
  }

  modifier notEmpty(WitnetBuffer.Buffer memory buffer) {
    if (buffer.data.length == 0) {
      revert WitnetBuffer.EmptyBuffer();
    }
    _;
  }

  function eof(CBOR memory cbor)
    internal pure
    returns (bool)
  {
    return cbor.buffer.cursor >= cbor.buffer.data.length;
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is the main factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param bytecode Raw bytes representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBytes(bytes memory bytecode)
    internal pure
    returns (CBOR memory)
  {
    WitnetBuffer.Buffer memory buffer = WitnetBuffer.Buffer(bytecode, 0);
    return fromBuffer(buffer);
  }

  /// @notice Decode a CBOR structure from raw bytes.
  /// @dev This is an alternate factory for CBOR instances, which can be later decoded into native EVM types.
  /// @param buffer A Buffer structure representing a CBOR-encoded value.
  /// @return A `CBOR` instance containing a partially decoded value.
  function fromBuffer(WitnetBuffer.Buffer memory buffer)
    internal pure
    notEmpty(buffer)
    returns (CBOR memory)
  {
    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 tag = UINT64_MAX;
    uint256 len;
    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = buffer.readUint8();
      len ++;
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;
      // Early CBOR tag parsing.
      if (majorType == MAJOR_TYPE_TAG) {
        uint _cursor = buffer.cursor;
        tag = readLength(buffer, additionalInformation);
        len += buffer.cursor - _cursor;
      } else {
        isTagged = false;
      }
    }
    if (majorType > MAJOR_TYPE_CONTENT_FREE) {
      revert UnsupportedMajorType(majorType);
    }
    return CBOR(
      buffer,
      initialByte,
      majorType,
      additionalInformation,
      uint64(len),
      tag
    );
  }

  function fork(WitnetCBOR.CBOR memory self)
    internal pure
    returns (WitnetCBOR.CBOR memory)
  {
    return CBOR({
      buffer: self.buffer.fork(),
      initialByte: self.initialByte,
      majorType: self.majorType,
      additionalInformation: self.additionalInformation,
      len: self.len,
      tag: self.tag
    });
  }

  function settle(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (!self.eof()) {
      return fromBuffer(self.buffer);
    } else {
      return self;
    }
  }

  function skip(CBOR memory self)
      internal pure
      returns (WitnetCBOR.CBOR memory)
  {
    if (
      self.majorType == MAJOR_TYPE_INT
        || self.majorType == MAJOR_TYPE_NEGATIVE_INT
        || (
          self.majorType == MAJOR_TYPE_CONTENT_FREE 
            && self.additionalInformation >= 25
            && self.additionalInformation <= 27
        )
    ) {
      self.buffer.cursor += self.peekLength();
    } else if (
        self.majorType == MAJOR_TYPE_STRING
          || self.majorType == MAJOR_TYPE_BYTES
    ) {
      uint64 len = readLength(self.buffer, self.additionalInformation);
      self.buffer.cursor += len;
    } else if (
      self.majorType == MAJOR_TYPE_ARRAY
        || self.majorType == MAJOR_TYPE_MAP
    ) { 
      self.len = readLength(self.buffer, self.additionalInformation);      
    } else if (
       self.majorType != MAJOR_TYPE_CONTENT_FREE
        || (
          self.additionalInformation != 20
            && self.additionalInformation != 21
        )
    ) {
      revert("WitnetCBOR.skip: unsupported major type");
    }
    return self;
  }

  function peekLength(CBOR memory self)
    internal pure
    returns (uint64)
  {
    if (self.additionalInformation < 24) {
      return 0;
    } else if (self.additionalInformation < 28) {
      return uint64(1 << (self.additionalInformation - 24));
    } else {
      revert InvalidLengthEncoding(self.additionalInformation);
    }
  }

  function readArray(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_ARRAY)
    returns (CBOR[] memory items)
  {
    // read array's length and move self cursor forward to the first array element:
    uint64 len = readLength(self.buffer, self.additionalInformation);
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (self.majorType == MAJOR_TYPE_ARRAY) {
        CBOR[] memory _subitems = self.readArray();
        // move forward to the first element after inner array:
        self = _subitems[_subitems.length - 1];
      } else if (self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = self.readMap();
        // move forward to the first element after inner map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  function readMap(CBOR memory self)
    internal pure
    isMajorType(self, MAJOR_TYPE_MAP)
    returns (CBOR[] memory items)
  {
    // read number of items within the map and move self cursor forward to the first inner element:
    uint64 len = readLength(self.buffer, self.additionalInformation) * 2;
    items = new CBOR[](len + 1);
    for (uint ix = 0; ix < len; ix ++) {
      // settle next element in the array:
      self = self.settle();
      // fork it and added to the list of items to be returned:
      items[ix] = self.fork();
      if (ix % 2 == 0 && self.majorType != MAJOR_TYPE_STRING) {
        revert UnexpectedMajorType(self.majorType, MAJOR_TYPE_STRING);
      } else if (self.majorType == MAJOR_TYPE_ARRAY || self.majorType == MAJOR_TYPE_MAP) {
        CBOR[] memory _subitems = (self.majorType == MAJOR_TYPE_ARRAY
            ? self.readArray()
            : self.readMap()
        );
        // move forward to the first element after inner array or map:
        self = _subitems[_subitems.length - 1];
      } else {
        // move forward to the next element:
        self.skip();
      }
    }
    // return self cursor as extra item at the end of the list,
    // as to optimize recursion when jumping over nested arrays:
    items[len] = self;
  }

  /// Reads the length of the settle CBOR item from a buffer, consuming a different number of bytes depending on the
  /// value of the `additionalInformation` argument.
  function readLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 additionalInformation
    ) 
    internal pure
    returns (uint64)
  {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert InvalidLengthEncoding(additionalInformation);
  }

  /// @notice Read a `CBOR` structure into a native `bool` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as a `bool` value.
  function readBool(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (bool)
  {
    if (cbor.additionalInformation == 20) {
      return false;
    } else if (cbor.additionalInformation == 21) {
      return true;
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `bytes` value.
  /// @param cbor An instance of `CBOR`.
  /// @return output The value represented by the input, as a `bytes` value.   
  function readBytes(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_BYTES)
    returns (bytes memory output)
  {
    cbor.len = readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
    if (cbor.len == UINT32_MAX) {
      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 length = uint32(_readIndefiniteStringLength(
        cbor.buffer,
        cbor.majorType
      ));
      if (length < UINT32_MAX) {
        output = abi.encodePacked(cbor.buffer.read(length));
        length = uint32(_readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        ));
        if (length < UINT32_MAX) {
          output = abi.encodePacked(
            output,
            cbor.buffer.read(length)
          );
        }
      }
    } else {
      return cbor.buffer.read(uint32(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed16` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
  /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readFloat16(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int32)
  {
    if (cbor.additionalInformation == 25) {
      return cbor.buffer.readFloat16();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed32` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 9 decimal orders so as to get a fixed precision of 9 decimal positions, which should be OK for most `fixed64`
  /// use cases. In other words, the output of this method is 10^9 times the actual value, encoded into an `int`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int` value.
  function readFloat32(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int)
  {
    if (cbor.additionalInformation == 26) {
      return cbor.buffer.readFloat32();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a `fixed64` value.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 15 decimal orders so as to get a fixed precision of 15 decimal positions, which should be OK for most `fixed64`
  /// use cases. In other words, the output of this method is 10^15 times the actual value, encoded into an `int`.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int` value.
  function readFloat64(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_CONTENT_FREE)
    returns (int)
  {
    if (cbor.additionalInformation == 27) {
      return cbor.buffer.readFloat64();
    } else {
      revert UnsupportedPrimitive(cbor.additionalInformation);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128[]` value whose inner values follow the same convention 
  /// @notice as explained in `decodeFixed16`.
  /// @param cbor An instance of `CBOR`.
  function readFloat16Array(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int32[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new int32[](length);
      for (uint64 i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[i] = readFloat16(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int128` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `int128` value.
  function readInt(CBOR memory cbor)
    internal pure
    returns (int)
  {
    if (cbor.majorType == 1) {
      uint64 _value = readLength(
        cbor.buffer,
        cbor.additionalInformation
      );
      return int(-1) - int(uint(_value));
    } else if (cbor.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int(readUint(cbor));
    }
    else {
      revert UnexpectedMajorType(cbor.majorType, 1);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `int[]` value.
  /// @param cbor instance of `CBOR`.
  /// @return array The value represented by the input, as an `int[]` value.
  function readIntArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (int[] memory array)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      array = new int[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        array[i] = readInt(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string` value.
  /// @param cbor An instance of `CBOR`.
  /// @return text The value represented by the input, as a `string` value.
  function readString(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_STRING)
    returns (string memory text)
  {
    cbor.len = readLength(cbor.buffer, cbor.additionalInformation);
    if (cbor.len == UINT64_MAX) {
      bool _done;
      while (!_done) {
        uint64 length = _readIndefiniteStringLength(
          cbor.buffer,
          cbor.majorType
        );
        if (length < UINT64_MAX) {
          text = string(abi.encodePacked(
            text,
            cbor.buffer.readText(length / 4)
          ));
        } else {
          _done = true;
        }
      }
    } else {
      return string(cbor.buffer.readText(cbor.len));
    }
  }

  /// @notice Decode a `CBOR` structure into a native `string[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return strings The value represented by the input, as an `string[]` value.
  function readStringArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (string[] memory strings)
  {
    uint length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      strings = new string[](length);
      for (uint i = 0; i < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        strings[i] = readString(item);
        unchecked {
          i ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }

  /// @notice Decode a `CBOR` structure into a native `uint64` value.
  /// @param cbor An instance of `CBOR`.
  /// @return The value represented by the input, as an `uint64` value.
  function readUint(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_INT)
    returns (uint)
  {
    return readLength(
      cbor.buffer,
      cbor.additionalInformation
    );
  }

  /// @notice Decode a `CBOR` structure into a native `uint64[]` value.
  /// @param cbor An instance of `CBOR`.
  /// @return values The value represented by the input, as an `uint64[]` value.
  function readUintArray(CBOR memory cbor)
    internal pure
    isMajorType(cbor, MAJOR_TYPE_ARRAY)
    returns (uint[] memory values)
  {
    uint64 length = readLength(cbor.buffer, cbor.additionalInformation);
    if (length < UINT64_MAX) {
      values = new uint[](length);
      for (uint ix = 0; ix < length; ) {
        CBOR memory item = fromBuffer(cbor.buffer);
        values[ix] = readUint(item);
        unchecked {
          ix ++;
        }
      }
    } else {
      revert InvalidLengthEncoding(length);
    }
  }  

  /// Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  /// as many bytes as specified by the first byte.
  function _readIndefiniteStringLength(
      WitnetBuffer.Buffer memory buffer,
      uint8 majorType
    )
    private pure
    returns (uint64 len)
  {
    uint8 initialByte = buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    len = readLength(
      buffer,
      initialByte & 0x1f
    );
    if (len >= UINT64_MAX) {
      revert InvalidLengthEncoding(len);
    } else if (majorType != (initialByte >> 5)) {
      revert UnexpectedMajorType((initialByte >> 5), majorType);
    }
  }
 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/// @title A convenient wrapper around the `bytes memory` type that exposes a buffer-like interface
/// @notice The buffer has an inner cursor that tracks the final offset of every read, i.e. any subsequent read will
/// start with the byte that goes right after the last one in the previous read.
/// @dev `uint32` is used here for `cursor` because `uint16` would only enable seeking up to 8KB, which could in some
/// theoretical use cases be exceeded. Conversely, `uint32` supports up to 512MB, which cannot credibly be exceeded.
/// @author The Witnet Foundation.
library WitnetBuffer {

  error EmptyBuffer();
  error IndexOutOfBounds(uint index, uint range);
  error MissingArgs(uint expected, uint given);

  /// Iterable bytes buffer.
  struct Buffer {
      bytes data;
      uint cursor;
  }

  // Ensures we access an existing index in an array
  modifier withinRange(uint index, uint _range) {
    if (index > _range) {
      revert IndexOutOfBounds(index, _range);
    }
    _;
  }

  /// @notice Concatenate undefinite number of bytes chunks.
  /// @dev Faster than looping on `abi.encodePacked(output, _buffs[ix])`.
  function concat(bytes[] memory _buffs)
    internal pure
    returns (bytes memory output)
  {
    unchecked {
      uint destinationPointer;
      uint destinationLength;
      assembly {
        // get safe scratch location
        output := mload(0x40)
        // set starting destination pointer
        destinationPointer := add(output, 32)
      }      
      for (uint ix = 1; ix <= _buffs.length; ix ++) {  
        uint source;
        uint sourceLength;
        uint sourcePointer;        
        assembly {
          // load source length pointer
          source := mload(add(_buffs, mul(ix, 32)))
          // load source length
          sourceLength := mload(source)
          // sets source memory pointer
          sourcePointer := add(source, 32)
        }
        memcpy(
          destinationPointer,
          sourcePointer,
          sourceLength
        );
        assembly {          
          // increase total destination length
          destinationLength := add(destinationLength, sourceLength)
          // sets destination memory pointer
          destinationPointer := add(destinationPointer, sourceLength)
        }
      }
      assembly {
        // protect output bytes
        mstore(output, destinationLength)
        // set final output length
        mstore(0x40, add(mload(0x40), add(destinationLength, 32)))
      }
    }
  }

  function fork(WitnetBuffer.Buffer memory buffer)
    internal pure
    returns (WitnetBuffer.Buffer memory)
  {
    return Buffer(
      buffer.data,
      buffer.cursor
    );
  }

  function mutate(
      WitnetBuffer.Buffer memory buffer,
      uint length,
      bytes memory pokes
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor + 1)
  {
    bytes[] memory parts = new bytes[](3);
    parts[0] = peek(
      buffer,
      0,
      buffer.cursor
    );
    parts[1] = pokes;
    parts[2] = peek(
      buffer,
      buffer.cursor + length,
      buffer.data.length - buffer.cursor - length
    );
    buffer.data = concat(parts);
  }

  /// @notice Read and consume the next byte from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @return The next byte in the buffer counting from the cursor position.
  function next(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (bytes1)
  {
    // Return the byte at the position marked by the cursor and advance the cursor all at once
    return buffer.data[buffer.cursor ++];
  }

  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint offset,
      uint length
    )
    internal pure
    withinRange(offset + length, buffer.data.length)
    returns (bytes memory)
  {
    bytes memory data = buffer.data;
    bytes memory peeks = new bytes(length);
    uint destinationPointer;
    uint sourcePointer;
    assembly {
      destinationPointer := add(peeks, 32)
      sourcePointer := add(add(data, 32), offset)
    }
    memcpy(
      destinationPointer,
      sourcePointer,
      length
    );
    return peeks;
  }

  // @notice Extract bytes array from buffer starting from current cursor.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to peek from the Buffer.
  // solium-disable-next-line security/no-assign-params
  function peek(
      WitnetBuffer.Buffer memory buffer,
      uint length
    )
    internal pure
    withinRange(length, buffer.data.length - buffer.cursor)
    returns (bytes memory)
  {
    return peek(
      buffer,
      buffer.cursor,
      length
    );
  }

  /// @notice Read and consume a certain amount of bytes from the buffer.
  /// @param buffer An instance of `Buffer`.
  /// @param length How many bytes to read and consume from the buffer.
  /// @return output A `bytes memory` containing the first `length` bytes from the buffer, counting from the cursor position.
  function read(Buffer memory buffer, uint length)
    internal pure
    withinRange(buffer.cursor + length, buffer.data.length)
    returns (bytes memory output)
  {
    // Create a new `bytes memory destination` value
    output = new bytes(length);
    // Early return in case that bytes length is 0
    if (length > 0) {
      bytes memory input = buffer.data;
      uint offset = buffer.cursor;
      // Get raw pointers for source and destination
      uint sourcePointer;
      uint destinationPointer;
      assembly {
        sourcePointer := add(add(input, 32), offset)
        destinationPointer := add(output, 32)
      }
      // Copy `length` bytes from source to destination
      memcpy(
        destinationPointer,
        sourcePointer,
        length
      );
      // Move the cursor forward by `length` bytes
      seek(
        buffer,
        length,
        true
      );
    }
  }
  
  /// @notice Read and consume the next 2 bytes from the buffer as an IEEE 754-2008 floating point number enclosed in an
  /// `int32`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `float16`
  /// use cases. In other words, the integer output of this method is 10,000 times the actual value. The input bytes are
  /// expected to follow the 16-bit base-2 format (a.k.a. `binary16`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readFloat16(Buffer memory buffer)
    internal pure
    returns (int32 result)
  {
    uint32 value = readUint16(buffer);
    // Get bit at position 0
    uint32 sign = value & 0x8000;
    // Get bits 1 to 5, then normalize to the [-15, 16] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(value & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 fraction = int32(value & 0x03ff);
    // Add 2^10 to the fraction if exponent is not -15
    if (exponent != -15) {
      fraction |= 0x400;
    } else if (exponent == 16) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat16: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = int32(int(
        int(1 << uint256(int256(exponent)))
          * 10000
          * fraction
      ) >> 10);
    } else {
      result = int32(int(
        int(fraction)
          * 10000
          / int(1 << uint(int(- exponent)))
      ) >> 10);
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  /// @notice Consume the next 4 bytes from the buffer as an IEEE 754-2008 floating point number enclosed into an `int`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 9 decimal orders so as to get a fixed precision of 9 decimal positions, which should be OK for most `float32`
  /// use cases. In other words, the integer output of this method is 10^9 times the actual value. The input bytes are
  /// expected to follow the 64-bit base-2 format (a.k.a. `binary32`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int` value of the next 8 bytes in the buffer counting from the cursor position.
  function readFloat32(Buffer memory buffer)
    internal pure
    returns (int result)
  {
    uint value = readUint32(buffer);
    // Get bit at position 0
    uint sign = value & 0x80000000;
    // Get bits 1 to 8, then normalize to the [-127, 128] range so as to counterweight the IEEE 754 exponent bias
    int exponent = (int(value & 0x7f800000) >> 23) - 127;
    // Get bits 9 to 31
    int fraction = int(value & 0x007fffff);
    // Add 2^23 to the fraction if exponent is not -127
    if (exponent != -127) {
      fraction |= 0x800000;
    } else if (exponent == 128) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat32: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 2^23)`
    if (exponent >= 0) {
      result = (
        int(1 << uint(exponent))
          * (10 ** 9)
          * fraction
      ) >> 23;
    } else {
      result = (
        fraction 
          * (10 ** 9)
          / int(1 << uint(-exponent)) 
      ) >> 23;
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  /// @notice Consume the next 8 bytes from the buffer as an IEEE 754-2008 floating point number enclosed into an `int`.
  /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
  /// by 15 decimal orders so as to get a fixed precision of 15 decimal positions, which should be OK for most `float64`
  /// use cases. In other words, the integer output of this method is 10^15 times the actual value. The input bytes are
  /// expected to follow the 64-bit base-2 format (a.k.a. `binary64`) in the IEEE 754-2008 standard.
  /// @param buffer An instance of `Buffer`.
  /// @return result The `int` value of the next 8 bytes in the buffer counting from the cursor position.
  function readFloat64(Buffer memory buffer)
    internal pure
    returns (int result)
  {
    uint value = readUint64(buffer);
    // Get bit at position 0
    uint sign = value & 0x8000000000000000;
    // Get bits 1 to 12, then normalize to the [-1023, 1024] range so as to counterweight the IEEE 754 exponent bias
    int exponent = (int(value & 0x7ff0000000000000) >> 52) - 1023;
    // Get bits 6 to 15
    int fraction = int(value & 0x000fffffffffffff);
    // Add 2^52 to the fraction if exponent is not -1023
    if (exponent != -1023) {
      fraction |= 0x10000000000000;
    } else if (exponent == 1024) {
      revert(
        string(abi.encodePacked(
          "WitnetBuffer.readFloat64: ",
          sign != 0 ? "negative" : hex"",
          " infinity"
        ))
      );
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = (
        int(1 << uint(exponent))
          * (10 ** 15)
          * fraction
      ) >> 52;
    } else {
      result = (
        fraction 
          * (10 ** 15)
          / int(1 << uint(-exponent)) 
      ) >> 52;
    }
    // Make the result negative if the sign bit is not 0
    if (sign != 0) {
      result *= -1;
    }
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  /// but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(
      WitnetBuffer.Buffer memory buffer,
      uint64 length
    )
    internal pure
    returns (bytes memory text)
  {
    text = new bytes(length);
    unchecked {
      for (uint64 index = 0; index < length; index ++) {
        uint8 char = readUint8(buffer);
        if (char & 0x80 != 0) {
          if (char < 0xe0) {
            char = (char & 0x1f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 1;
          } else if (char < 0xf0) {
            char  = (char & 0x0f) << 12
              | (readUint8(buffer) & 0x3f) << 6
              | (readUint8(buffer) & 0x3f);
            length -= 2;
          } else {
            char = (char & 0x0f) << 18
              | (readUint8(buffer) & 0x3f) << 12
              | (readUint8(buffer) & 0x3f) << 6  
              | (readUint8(buffer) & 0x3f);
            length -= 3;
          }
        }
        text[index] = bytes1(char);
      }
      // Adjust text to actual length:
      assembly {
        mstore(text, length)
      }
    }
  }

  /// @notice Read and consume the next byte from the buffer as an `uint8`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint8` value of the next byte in the buffer counting from the cursor position.
  function readUint8(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor, buffer.data.length)
    returns (uint8 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 1), offset))
    }
    buffer.cursor ++;
  }

  /// @notice Read and consume the next 2 bytes from the buffer as an `uint16`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint16` value of the next 2 bytes in the buffer counting from the cursor position.
  function readUint16(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 2, buffer.data.length)
    returns (uint16 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 2), offset))
    }
    buffer.cursor += 2;
  }

  /// @notice Read and consume the next 4 bytes from the buffer as an `uint32`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint32` value of the next 4 bytes in the buffer counting from the cursor position.
  function readUint32(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 4, buffer.data.length)
    returns (uint32 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 4), offset))
    }
    buffer.cursor += 4;
  }

  /// @notice Read and consume the next 8 bytes from the buffer as an `uint64`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint64` value of the next 8 bytes in the buffer counting from the cursor position.
  function readUint64(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 8, buffer.data.length)
    returns (uint64 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 8), offset))
    }
    buffer.cursor += 8;
  }

  /// @notice Read and consume the next 16 bytes from the buffer as an `uint128`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint128` value of the next 16 bytes in the buffer counting from the cursor position.
  function readUint128(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 16, buffer.data.length)
    returns (uint128 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 16), offset))
    }
    buffer.cursor += 16;
  }

  /// @notice Read and consume the next 32 bytes from the buffer as an `uint256`.
  /// @param buffer An instance of `Buffer`.
  /// @return value The `uint256` value of the next 32 bytes in the buffer counting from the cursor position.
  function readUint256(Buffer memory buffer)
    internal pure
    withinRange(buffer.cursor + 32, buffer.data.length)
    returns (uint256 value)
  {
    bytes memory data = buffer.data;
    uint offset = buffer.cursor;
    assembly {
      value := mload(add(add(data, 32), offset))
    }
    buffer.cursor += 32;
  }

  /// @notice Count number of required parameters for given bytes arrays
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param count Highest wildcard index found, plus 1.
  function argsCountOf(bytes memory input)
    internal pure
    returns (uint8 count)
  {
    if (input.length < 3) {
      return 0;
    }
    unchecked {
      uint ix = 0; 
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          uint8 ax = uint8(uint8(input[ix + 1]) - uint8(bytes1("0")) + 1);
          if (ax > count) {
            count = ax;
          }
          ix += 3;
        } else {
          ix ++;
        }
      }
    }
  }

  /// @notice Replace bytecode indexed wildcards by correspondent substrings.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param args Array of substring values for replacing indexed wildcards.
  /// @return output Resulting bytes array after replacing all wildcards.
  /// @return hits Total number of replaced wildcards.
  function replace(bytes memory input, string[] memory args)
    internal pure
    returns (bytes memory output, uint hits)
  {
    uint ix = 0; uint lix = 0;
    uint inputLength;
    uint inputPointer;
    uint outputLength;
    uint outputPointer;    
    uint source;
    uint sourceLength;
    uint sourcePointer;

    if (input.length < 3) {
      return (input, 0);
    }
    
    assembly {
      // set starting input pointer
      inputPointer := add(input, 32)
      // get safe output location
      output := mload(0x40)
      // set starting output pointer
      outputPointer := add(output, 32)
    }         

    unchecked {
      uint length = input.length - 2;
      for (; ix < length; ) {
        if (
          input[ix] == bytes1("\\")
            && input[ix + 2] == bytes1("\\")
            && input[ix + 1] >= bytes1("0")
            && input[ix + 1] <= bytes1("9")
        ) {
          inputLength = (ix - lix);
          if (ix > lix) {
            memcpy(
              outputPointer,
              inputPointer,
              inputLength
            );
            inputPointer += inputLength + 3;
            outputPointer += inputLength;
          } else {
            inputPointer += 3;
          }
          uint ax = uint(uint8(input[ix + 1]) - uint8(bytes1("0")));
          if (ax >= args.length) {
            revert MissingArgs(ax + 1, args.length);
          }
          assembly {
            source := mload(add(args, mul(32, add(ax, 1))))
            sourceLength := mload(source)
            sourcePointer := add(source, 32)      
          }        
          memcpy(
            outputPointer,
            sourcePointer,
            sourceLength
          );
          outputLength += inputLength + sourceLength;
          outputPointer += sourceLength;
          ix += 3;
          lix = ix;
          hits ++;
        } else {
          ix ++;
        }
      }
      ix = input.length;    
    }
    if (outputLength > 0) {
      if (ix > lix ) {
        memcpy(
          outputPointer,
          inputPointer,
          ix - lix
        );
        outputLength += (ix - lix);
      }
      assembly {
        // set final output length
        mstore(output, outputLength)
        // protect output bytes
        mstore(0x40, add(mload(0x40), add(outputLength, 32)))
      }
    }
    else {
      return (input, 0);
    }
  }

  /// @notice Replace string indexed wildcards by correspondent substrings.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input String potentially containing wildcards.
  /// @param args Array of substring values for replacing indexed wildcards.
  /// @return output Resulting string after replacing all wildcards.
  function replace(string memory input, string[] memory args)
    internal pure
    returns (string memory)
  {
    (bytes memory _outputBytes, ) = replace(bytes(input), args);
    return string(_outputBytes);
  }

  /// @notice Move the inner cursor of the buffer to a relative or absolute position.
  /// @param buffer An instance of `Buffer`.
  /// @param offset How many bytes to move the cursor forward.
  /// @param relative Whether to count `offset` from the last position of the cursor (`true`) or the beginning of the
  /// buffer (`true`).
  /// @return The final position of the cursor (will equal `offset` if `relative` is `false`).
  // solium-disable-next-line security/no-assign-params
  function seek(
      Buffer memory buffer,
      uint offset,
      bool relative
    )
    internal pure
    withinRange(offset, buffer.data.length)
    returns (uint)
  {
    // Deal with relative offsets
    if (relative) {
      offset += buffer.cursor;
    }
    buffer.cursor = offset;
    return offset;
  }

  /// @notice Move the inner cursor a number of bytes forward.
  /// @dev This is a simple wrapper around the relative offset case of `seek()`.
  /// @param buffer An instance of `Buffer`.
  /// @param relativeOffset How many bytes to move the cursor forward.
  /// @return The final position of the cursor.
  function seek(
      Buffer memory buffer,
      uint relativeOffset
    )
    internal pure
    returns (uint)
  {
    return seek(
      buffer,
      relativeOffset,
      true
    );
  }

  /// @notice Copy bytes from one memory address into another.
  /// @dev This function was borrowed from Nick Johnson's `solidity-stringutils` lib, and reproduced here under the terms
  /// of [Apache License 2.0](https://github.com/Arachnid/solidity-stringutils/blob/master/LICENSE).
  /// @param dest Address of the destination memory.
  /// @param src Address to the source memory.
  /// @param len How many bytes to copy.
  // solium-disable-next-line security/no-assign-params
  function memcpy(
      uint dest,
      uint src,
      uint len
    )
    private pure
  {
    unchecked {
      // Copy word-length chunks while possible
      for (; len >= 32; len -= 32) {
        assembly {
          mstore(dest, mload(src))
        }
        dest += 32;
        src += 32;
      }
      if (len > 0) {
        // Copy remaining bytes
        uint _mask = 256 ** (32 - len) - 1;
        assembly {
          let srcpart := and(mload(src), not(_mask))
          let destpart := and(mload(dest), _mask)
          mstore(dest, or(destpart, srcpart))
        }
      }
    }
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./WitnetCBOR.sol";

library Witnet {

    using WitnetBuffer for WitnetBuffer.Buffer;
    using WitnetCBOR for WitnetCBOR.CBOR;
    using WitnetCBOR for WitnetCBOR.CBOR[];

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
        address from;      // Address from which the request was posted.
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        address addr;       // Address of the (deprecated) IWitnetRequest contract containing Witnet data request raw bytecode.
        bytes32 slaHash;    // Radon SLA hash of the Witnet data request.
        bytes32 radHash;    // Radon radHash of the Witnet data request.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing the Witnet-provided response metadata and CBOR-encoded result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        WitnetCBOR.CBOR value;  // Resulting value, in CBOR-serialized bytes.
    }

    /// Final query's result status from a requester's point of view.
    enum ResultStatus {
        Void,
        Awaiting,
        Ready,
        Error
    }

    /// Data struct describing an error when trying to fetch a Witnet-provided result to a Data Request.
    struct ResultError {
        ResultErrorCodes code;
        string reason;
    }

    enum ResultErrorCodes {
        /// 0x00: Unknown error. Something went really bad!
        Unknown, 
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Source-specific format error sub-codes ============================================================================
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR, 
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// 0x04: The request body of at least one data source was not properly formated.
        SourceRequestBody,
        /// 0x05: The request headers of at least one data source was not properly formated.
        SourceRequestHeaders,
        /// 0x06: The request URL of at least one data source was not properly formated.
        SourceRequestURL,
        /// Unallocated
        SourceFormat0x07, SourceFormat0x08, SourceFormat0x09, SourceFormat0x0A, SourceFormat0x0B, SourceFormat0x0C,
        SourceFormat0x0D, SourceFormat0x0E, SourceFormat0x0F, 
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Complexity error sub-codes ========================================================================================
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12, Complexity0x13, Complexity0x14, Complexity0x15, Complexity0x16, Complexity0x17, Complexity0x18,
        Complexity0x19, Complexity0x1A, Complexity0x1B, Complexity0x1C, Complexity0x1D, Complexity0x1E, Complexity0x1F,

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Lack of support error sub-codes ===================================================================================
        /// 0x20: Some Radon operator code was found that is not supported (1+ args).
        UnsupportedOperator,
        /// 0x21: Some Radon filter opcode is not currently supported (1+ args).
        UnsupportedFilter,
        /// 0x22: Some Radon request type is not currently supported (1+ args).
        UnsupportedHashFunction,
        /// 0x23: Some Radon reducer opcode is not currently supported (1+ args)
        UnsupportedReducer,
        /// 0x24: Some Radon hash function is not currently supported (1+ args).
        UnsupportedRequestType, 
        /// 0x25: Some Radon encoding function is not currently supported (1+ args).
        UnsupportedEncodingFunction,
        /// Unallocated
        Operator0x26, Operator0x27, 
        /// 0x28: Wrong number (or type) of arguments were passed to some Radon operator.
        WrongArguments,
        /// Unallocated
        Operator0x29, Operator0x2A, Operator0x2B, Operator0x2C, Operator0x2D, Operator0x2E, Operator0x2F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Retrieve-specific circumstantial error sub-codes ================================================================================
        /// 0x30: A majority of data sources returned an HTTP status code other than 200 (1+ args):
        HttpErrors,
        /// 0x31: A majority of data sources timed out:
        RetrievalsTimeout,
        /// Unallocated
        RetrieveCircumstance0x32, RetrieveCircumstance0x33, RetrieveCircumstance0x34, RetrieveCircumstance0x35,
        RetrieveCircumstance0x36, RetrieveCircumstance0x37, RetrieveCircumstance0x38, RetrieveCircumstance0x39,
        RetrieveCircumstance0x3A, RetrieveCircumstance0x3B, RetrieveCircumstance0x3C, RetrieveCircumstance0x3D,
        RetrieveCircumstance0x3E, RetrieveCircumstance0x3F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Scripting-specific runtime error sub-code =========================================================================
        /// 0x40: Math operator caused an underflow.
        MathUnderflow,
        /// 0x41: Math operator caused an overflow.
        MathOverflow,
        /// 0x42: Math operator tried to divide by zero.
        MathDivisionByZero,            
        /// 0x43:Wrong input to subscript call.
        WrongSubscriptInput,
        /// 0x44: Value cannot be extracted from input binary buffer.
        BufferIsNotValue,
        /// 0x45: Value cannot be decoded from expected type.
        Decode,
        /// 0x46: Unexpected empty array.
        EmptyArray,
        /// 0x47: Value cannot be encoded to expected type.
        Encode,
        /// 0x48: Failed to filter input values (1+ args).
        Filter,
        /// 0x49: Failed to hash input value.
        Hash,
        /// 0x4A: Mismatching array ranks.
        MismatchingArrays,
        /// 0x4B: Failed to process non-homogenous array.
        NonHomegeneousArray,
        /// 0x4C: Failed to parse syntax of some input value, or argument.
        Parse,
        /// 0x4E: Parsing logic limits were exceeded.
        ParseOverflow,
        /// 0x4F: Unallocated
        ScriptError0x4F,
    
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Actual first-order result error codes =============================================================================
        /// 0x50: Not enough reveals were received in due time:
        InsufficientReveals,
        /// 0x51: No actual reveal majority was reached on tally stage:
        InsufficientMajority,
        /// 0x52: Not enough commits were received before tally stage:
        InsufficientCommits,
        /// 0x53: Generic error during tally execution (to be deprecated after WIP #0028)
        TallyExecution,
        /// 0x54: A majority of data sources could either be temporarily unresponsive or failing to report the requested data:
        CircumstantialFailure,
        /// 0x55: At least one data source is inconsistent when queried through multiple transports at once:
        InconsistentSources,
        /// 0x56: Any one of the (multiple) Retrieve, Aggregate or Tally scripts were badly formated:
        MalformedDataRequest,
        /// 0x57: Values returned from a majority of data sources don't match the expected schema:
        MalformedResponses,
        /// Unallocated:    
        OtherError0x58, OtherError0x59, OtherError0x5A, OtherError0x5B, OtherError0x5C, OtherError0x5D, OtherError0x5E, 
        /// 0x5F: Size of serialized tally result exceeds allowance:
        OversizedTallyResult,

        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Inter-stage runtime error sub-codes ===============================================================================
        /// 0x60: Data aggregation reveals could not get decoded on the tally stage:
        MalformedReveals,
        /// 0x61: The result to data aggregation could not get encoded:
        EncodeReveals,  
        /// 0x62: A mode tie ocurred when calculating some mode value on the aggregation or the tally stage:
        ModeTie, 
        /// Unallocated:
        OtherError0x63, OtherError0x64, OtherError0x65, OtherError0x66, OtherError0x67, OtherError0x68, OtherError0x69, 
        OtherError0x6A, OtherError0x6B, OtherError0x6C, OtherError0x6D, OtherError0x6E, OtherError0x6F,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Runtime access error sub-codes ====================================================================================
        /// 0x70: Tried to access a value from an array using an index that is out of bounds (1+ args):
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist (1+ args):
        MapKeyNotFound,
        /// 0X72: Tried to extract value from a map using a JSON Path that returns no values (+1 args):
        JsonPathNotFound,
        /// Unallocated:
        OtherError0x73, OtherError0x74, OtherError0x75, OtherError0x76, OtherError0x77, OtherError0x78, 
        OtherError0x79, OtherError0x7A, OtherError0x7B, OtherError0x7C, OtherError0x7D, OtherError0x7E, OtherError0x7F, 
        OtherError0x80, OtherError0x81, OtherError0x82, OtherError0x83, OtherError0x84, OtherError0x85, OtherError0x86, 
        OtherError0x87, OtherError0x88, OtherError0x89, OtherError0x8A, OtherError0x8B, OtherError0x8C, OtherError0x8D, 
        OtherError0x8E, OtherError0x8F, OtherError0x90, OtherError0x91, OtherError0x92, OtherError0x93, OtherError0x94, 
        OtherError0x95, OtherError0x96, OtherError0x97, OtherError0x98, OtherError0x99, OtherError0x9A, OtherError0x9B,
        OtherError0x9C, OtherError0x9D, OtherError0x9E, OtherError0x9F, OtherError0xA0, OtherError0xA1, OtherError0xA2, 
        OtherError0xA3, OtherError0xA4, OtherError0xA5, OtherError0xA6, OtherError0xA7, OtherError0xA8, OtherError0xA9, 
        OtherError0xAA, OtherError0xAB, OtherError0xAC, OtherError0xAD, OtherError0xAE, OtherError0xAF, OtherError0xB0,
        OtherError0xB1, OtherError0xB2, OtherError0xB3, OtherError0xB4, OtherError0xB5, OtherError0xB6, OtherError0xB7,
        OtherError0xB8, OtherError0xB9, OtherError0xBA, OtherError0xBB, OtherError0xBC, OtherError0xBD, OtherError0xBE,
        OtherError0xBF, OtherError0xC0, OtherError0xC1, OtherError0xC2, OtherError0xC3, OtherError0xC4, OtherError0xC5,
        OtherError0xC6, OtherError0xC7, OtherError0xC8, OtherError0xC9, OtherError0xCA, OtherError0xCB, OtherError0xCC,
        OtherError0xCD, OtherError0xCE, OtherError0xCF, OtherError0xD0, OtherError0xD1, OtherError0xD2, OtherError0xD3,
        OtherError0xD4, OtherError0xD5, OtherError0xD6, OtherError0xD7, OtherError0xD8, OtherError0xD9, OtherError0xDA,
        OtherError0xDB, OtherError0xDC, OtherError0xDD, OtherError0xDE, OtherError0xDF,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Inter-client generic error codes ==================================================================================
        /// Data requests that cannot be relayed into the Witnet blockchain should be reported
        /// with one of these errors. 
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        BridgeMalformedDataRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedTallyResult,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Unallocated =======================================================================================================
        OtherError0xE3, OtherError0xE4, OtherError0xE5, OtherError0xE6, OtherError0xE7, OtherError0xE8, OtherError0xE9,
        OtherError0xEA, OtherError0xEB, OtherError0xEC, OtherError0xED, OtherError0xEE, OtherError0xEF, OtherError0xF0,
        OtherError0xF1, OtherError0xF2, OtherError0xF3, OtherError0xF4, OtherError0xF5, OtherError0xF6, OtherError0xF7,
        OtherError0xF8, OtherError0xF9, OtherError0xFA, OtherError0xFB, OtherError0xFC, OtherError0xFD, OtherError0xFE,
        
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// 0xFF: Some tally error is not intercepted but it should (0+ args)
        UnhandledIntercept
    }

    function isCircumstantial(ResultErrorCodes self) internal pure returns (bool) {
        return (self == ResultErrorCodes.CircumstantialFailure);
    }

    function lackOfConsensus(ResultErrorCodes self) internal pure returns (bool) {
        return (
            self == ResultErrorCodes.InsufficientCommits
                || self == ResultErrorCodes.InsufficientMajority
                || self == ResultErrorCodes.InsufficientReveals
        );
    }

    function isRetriable(ResultErrorCodes self) internal pure returns (bool) {
        return (
            lackOfConsensus(self)
                || isCircumstantial(self)
                || poorIncentives(self)
        );
    }

    function poorIncentives(ResultErrorCodes self) internal pure returns (bool) {
        return (
            self == ResultErrorCodes.OversizedTallyResult
                || self == ResultErrorCodes.InsufficientCommits
                || self == ResultErrorCodes.BridgePoorIncentives
                || self == ResultErrorCodes.BridgeOversizedTallyResult
        );
    }
    

    /// Possible Radon data request methods that can be used within a Radon Retrieval. 
    enum RadonDataRequestMethods {
        /* 0 */ Unknown,
        /* 1 */ HttpGet,
        /* 2 */ RNG,
        /* 3 */ HttpPost,
        /* 4 */ HttpHead
    }

    /// Possible types either processed by Witnet Radon Scripts or included within results to Witnet Data Requests.
    enum RadonDataTypes {
        /* 0x00 */ Any, 
        /* 0x01 */ Array,
        /* 0x02 */ Bool,
        /* 0x03 */ Bytes,
        /* 0x04 */ Integer,
        /* 0x05 */ Float,
        /* 0x06 */ Map,
        /* 0x07 */ String,
        Unused0x08, Unused0x09, Unused0x0A, Unused0x0B,
        Unused0x0C, Unused0x0D, Unused0x0E, Unused0x0F,
        /* 0x10 */ Same,
        /* 0x11 */ Inner,
        /* 0x12 */ Match,
        /* 0x13 */ Subscript
    }

    /// Structure defining some data filtering that can be applied at the Aggregation or the Tally stages
    /// within a Witnet Data Request resolution workflow.
    struct RadonFilter {
        RadonFilterOpcodes opcode;
        bytes args;
    }

    /// Filtering methods currently supported on the Witnet blockchain. 
    enum RadonFilterOpcodes {
        /* 0x00 */ Reserved0x00, //GreaterThan,
        /* 0x01 */ Reserved0x01, //LessThan,
        /* 0x02 */ Reserved0x02, //Equals,
        /* 0x03 */ Reserved0x03, //AbsoluteDeviation,
        /* 0x04 */ Reserved0x04, //RelativeDeviation
        /* 0x05 */ StandardDeviation,
        /* 0x06 */ Reserved0x06, //Top,
        /* 0x07 */ Reserved0x07, //Bottom,
        /* 0x08 */ Mode,
        /* 0x09 */ Reserved0x09  //LessOrEqualThan
    }

    /// Structure defining the array of filters and reducting function to be applied at either the Aggregation
    /// or the Tally stages within a Witnet Data Request resolution workflow.
    struct RadonReducer {
        RadonReducerOpcodes opcode;
        RadonFilter[] filters;
    }

    /// Reducting functions currently supported on the Witnet blockchain.
    enum RadonReducerOpcodes {
        /* 0x00 */ Reserved0x00, //Minimum,
        /* 0x01 */ Reserved0x01, //Maximum,
        /* 0x02 */ Mode,
        /* 0x03 */ AverageMean,
        /* 0x04 */ Reserved0x04, //AverageMeanWeighted,
        /* 0x05 */ AverageMedian,
        /* 0x06 */ Reserved0x06, //AverageMedianWeighted,
        /* 0x07 */ StandardDeviation,
        /* 0x08 */ Reserved0x08, //AverageDeviation,
        /* 0x09 */ Reserved0x09, //MedianDeviation,
        /* 0x0A */ Reserved0x10, //MaximumDeviation,
        /* 0x0B */ ConcatenateAndHash
    }

    /// Structure containing all the parameters that fully describe a Witnet Radon Retrieval within a Witnet Data Request.
    struct RadonRetrieval {
        uint8 argsCount;
        RadonDataRequestMethods method;
        RadonDataTypes resultDataType;
        string url;
        string body;
        string[2][] headers;
        bytes script;
    }

    /// Structure containing the Retrieve-Attestation-Delivery parts of a Witnet Data Request.
    struct RadonRAD {
        RadonRetrieval[] retrieve;
        RadonReducer aggregate;
        RadonReducer tally;
    }

    /// Structure containing the Service Level Aggreement parameters of a Witnet Data Request.
    struct RadonSLA {
        uint8 numWitnesses;
        uint8 minConsensusPercentage;
        uint64 witnessReward;
        uint64 witnessCollateral;
        uint64 minerCommitRevealFee;
    }


    /// ===============================================================================================================
    /// --- 'uint*' helper methods ------------------------------------------------------------------------------------

    /// @notice Convert a `uint8` into a 2 characters long `string` representing its two less significant hexadecimal values.
    function toHexString(uint8 _u)
        internal pure
        returns (string memory)
    {
        bytes memory b2 = new bytes(2);
        uint8 d0 = uint8(_u / 16) + 48;
        uint8 d1 = uint8(_u % 16) + 48;
        if (d0 > 57)
            d0 += 7;
        if (d1 > 57)
            d1 += 7;
        b2[0] = bytes1(d0);
        b2[1] = bytes1(d1);
        return string(b2);
    }

    /// @notice Convert a `uint8` into a 1, 2 or 3 characters long `string` representing its.
    /// three less significant decimal values.
    function toString(uint8 _u)
        internal pure
        returns (string memory)
    {
        if (_u < 10) {
            bytes memory b1 = new bytes(1);
            b1[0] = bytes1(uint8(_u) + 48);
            return string(b1);
        } else if (_u < 100) {
            bytes memory b2 = new bytes(2);
            b2[0] = bytes1(uint8(_u / 10) + 48);
            b2[1] = bytes1(uint8(_u % 10) + 48);
            return string(b2);
        } else {
            bytes memory b3 = new bytes(3);
            b3[0] = bytes1(uint8(_u / 100) + 48);
            b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
            b3[2] = bytes1(uint8(_u % 10) + 48);
            return string(b3);
        }
    }

    /// @notice Convert a `uint` into a string` representing its value.
    function toString(uint v)
        internal pure 
        returns (string memory)
    {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        do {
            uint8 remainder = uint8(v % 10);
            v = v / 10;
            reversed[i ++] = bytes1(48 + remainder);
        } while (v != 0);
        bytes memory buf = new bytes(i);
        for (uint j = 1; j <= i; j ++) {
            buf[j - 1] = reversed[i - j];
        }
        return string(buf);
    }


    /// ===============================================================================================================
    /// --- 'bytes' helper methods ------------------------------------------------------------------------------------

    /// @dev Transform given bytes into a Witnet.Result instance.
    /// @param cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function toWitnetResult(bytes memory cborBytes)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(cborBytes);
        return _resultFromCborValue(cborValue);
    }

    function toAddress(bytes memory _value) internal pure returns (address) {
        return address(toBytes20(_value));
    }

    function toBytes4(bytes memory _value) internal pure returns (bytes4) {
        return bytes4(toFixedBytes(_value, 4));
    }
    
    function toBytes20(bytes memory _value) internal pure returns (bytes20) {
        return bytes20(toFixedBytes(_value, 20));
    }
    
    function toBytes32(bytes memory _value) internal pure returns (bytes32) {
        return toFixedBytes(_value, 32);
    }

    function toFixedBytes(bytes memory _value, uint8 _numBytes)
        internal pure
        returns (bytes32 _bytes32)
    {
        assert(_numBytes <= 32);
        unchecked {
            uint _len = _value.length > _numBytes ? _numBytes : _value.length;
            for (uint _i = 0; _i < _len; _i ++) {
                _bytes32 |= bytes32(_value[_i] & 0xff) >> (_i * 8);
            }
        }
    }


    /// ===============================================================================================================
    /// --- 'string' helper methods -----------------------------------------------------------------------------------

    function toLowerCase(string memory str)
        internal pure
        returns (string memory)
    {
        bytes memory lowered = new bytes(bytes(str).length);
        unchecked {
            for (uint i = 0; i < lowered.length; i ++) {
                uint8 char = uint8(bytes(str)[i]);
                if (char >= 65 && char <= 90) {
                    lowered[i] = bytes1(char + 32);
                } else {
                    lowered[i] = bytes1(char);
                }
            }
        }
        return string(lowered);
    }

    /// @notice Converts bytes32 into string.
    function toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(_toStringLength(_bytes32));
        for (uint _i = 0; _i < _bytes.length;) {
            _bytes[_i] = _bytes32[_i];
            unchecked {
                _i ++;
            }
        }
        return string(_bytes);
    }

    function tryUint(string memory str)
        internal pure
        returns (uint res, bool)
    {
        unchecked {
            for (uint256 i = 0; i < bytes(str).length; i++) {
                if (
                    (uint8(bytes(str)[i]) - 48) < 0
                        || (uint8(bytes(str)[i]) - 48) > 9
                ) {
                    return (0, false);
                }
                res += (uint8(bytes(str)[i]) - 48) * 10 ** (bytes(str).length - i - 1);
            }
            return (res, true);
        }
    }
    

    /// ===============================================================================================================
    /// --- 'Witnet.Result' helper methods ----------------------------------------------------------------------------

    modifier _isReady(Result memory result) {
        require(result.success, "Witnet: tried to decode value from errored result.");
        _;
    }

    /// @dev Decode an address from the Witnet.Result's CBOR value.
    function asAddress(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (address)
    {
        if (result.value.majorType == uint8(WitnetCBOR.MAJOR_TYPE_BYTES)) {
            return toAddress(result.value.readBytes());
        } else {
            // TODO
            revert("WitnetLib: reading address from string not yet supported.");
        }
    }

    /// @dev Decode a `bool` value from the Witnet.Result's CBOR value.
    function asBool(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bool)
    {
        return result.value.readBool();
    }

    /// @dev Decode a `bytes` value from the Witnet.Result's CBOR value.
    function asBytes(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(bytes memory)
    {
        return result.value.readBytes();
    }

    /// @dev Decode a `bytes4` value from the Witnet.Result's CBOR value.
    function asBytes4(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes4)
    {
        return toBytes4(asBytes(result));
    }

    /// @dev Decode a `bytes32` value from the Witnet.Result's CBOR value.
    function asBytes32(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (bytes32)
    {
        return toBytes32(asBytes(result));
    }

    /// @notice Returns the Witnet.Result's unread CBOR value.
    function asCborValue(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR memory)
    {
        return result.value;
    }

    /// @notice Decode array of CBOR values from the Witnet.Result's CBOR value. 
    function asCborArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (WitnetCBOR.CBOR[] memory)
    {
        return result.value.readArray();
    }

    /// @dev Decode a fixed16 (half-precision) numeric value from the Witnet.Result's CBOR value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    function asFixed16(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32)
    {
        return result.value.readFloat16();
    }

    /// @dev Decode an array of fixed16 values from the Witnet.Result's CBOR value.
    function asFixed16Array(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int32[] memory)
    {
        return result.value.readFloat16Array();
    }

    /// @dev Decode an `int64` value from the Witnet.Result's CBOR value.
    function asInt(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int)
    {
        return result.value.readInt();
    }

    /// @dev Decode an array of integer numeric values from a Witnet.Result as an `int[]` array.
    /// @param result An instance of Witnet.Result.
    /// @return The `int[]` decoded from the Witnet.Result.
    function asIntArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (int[] memory)
    {
        return result.value.readIntArray();
    }

    /// @dev Decode a `string` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asText(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns(string memory)
    {
        return result.value.readString();
    }

    /// @dev Decode an array of strings from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asTextArray(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (string[] memory)
    {
        return result.value.readStringArray();
    }

    /// @dev Decode a `uint64` value from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint` decoded from the Witnet.Result.
    function asUint(Witnet.Result memory result)
        internal pure
        _isReady(result)
        returns (uint)
    {
        return result.value.readUint();
    }

    /// @dev Decode an array of `uint64` values from the Witnet.Result's CBOR value.
    /// @param result An instance of Witnet.Result.
    /// @return The `uint[]` decoded from the Witnet.Result.
    function asUintArray(Witnet.Result memory result)
        internal pure
        returns (uint[] memory)
    {
        return result.value.readUintArray();
    }


    /// ===============================================================================================================
    /// --- Witnet library private methods ----------------------------------------------------------------------------

    /// @dev Decode a CBOR value into a Witnet.Result instance.
    function _resultFromCborValue(WitnetCBOR.CBOR memory cbor)
        private pure
        returns (Witnet.Result memory)    
    {
        // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
        // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
        bool success = cbor.tag != 39;
        return Witnet.Result(success, cbor);
    }

    /// @dev Calculate length of string-equivalent to given bytes32.
    function _toStringLength(bytes32 _bytes32)
        private pure
        returns (uint _length)
    {
        for (; _length < 32; ) {
            if (_bytes32[_length] == 0) {
                break;
            }
            unchecked {
                _length ++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libs/WitnetV2.sol";

interface IWitnetRequestBytecodes {

    error UnknownRadonRetrieval(bytes32 hash);
    error UnknownRadonReducer(bytes32 hash);
    error UnknownRadonRequest(bytes32 hash);

    event NewDataProvider(uint256 index);
    event NewRadonRetrievalHash(bytes32 hash);
    event NewRadonReducerHash(bytes32 hash);
    event NewRadHash(bytes32 hash);

    function bytecodeOf(bytes32 radHash) external view returns (bytes memory);
    function bytecodeOf(bytes32 radHash, WitnetV2.RadonSLA calldata sla) external view returns (bytes memory);
    function bytecodeOf(bytes calldata radBytecode, WitnetV2.RadonSLA calldata sla) external view returns (bytes memory);
    
    function hashOf(bytes calldata) external view returns (bytes32);

    function lookupDataProvider(uint256 index) external view returns (string memory, uint);
    function lookupDataProviderIndex(string calldata authority) external view returns (uint);
    function lookupDataProviderSources(uint256 index, uint256 offset, uint256 length) external view returns (bytes32[] memory);

    function lookupRadonReducer(bytes32 hash) external view returns (Witnet.RadonReducer memory);
    
    function lookupRadonRetrieval(bytes32 hash) external view returns (Witnet.RadonRetrieval memory);
    function lookupRadonRetrievalArgsCount(bytes32 hash) external view returns (uint8);
    function lookupRadonRetrievalResultDataType(bytes32 hash) external view returns (Witnet.RadonDataTypes);
    
    function lookupRadonRequestAggregator(bytes32 radHash) external view returns (Witnet.RadonReducer memory);
    function lookupRadonRequestResultMaxSize(bytes32 radHash) external view returns (uint16);
    function lookupRadonRequestResultDataType(bytes32 radHash) external view returns (Witnet.RadonDataTypes);
    function lookupRadonRequestSources(bytes32 radHash) external view returns (bytes32[] memory);
    function lookupRadonRequestSourcesCount(bytes32 radHash) external view returns (uint);
    function lookupRadonRequestTally(bytes32 radHash) external view returns (Witnet.RadonReducer memory);
        
    function verifyRadonRetrieval(
            Witnet.RadonDataRequestMethods requestMethod,
            string calldata requestURL,
            string calldata requestBody,
            string[2][] calldata requestHeaders,
            bytes calldata requestRadonScript
        ) external returns (bytes32 hash);
    
    function verifyRadonReducer(Witnet.RadonReducer calldata reducer)
        external returns (bytes32 hash);
    
    function verifyRadonRequest(
            bytes32[] calldata sources,
            bytes32 aggregator,
            bytes32 tally,
            uint16 resultMaxSize,
            string[][] calldata args
        ) external returns (bytes32 radHash);

    function totalDataProviders() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IWitnetRequestBytecodes.sol";

abstract contract WitnetRequestBytecodes
    is
        IWitnetRequestBytecodes
{
    function class() virtual external view returns (string memory) {
        return type(WitnetRequestBytecodes).name;
    }   
    function specs() virtual external view returns (bytes4);
}