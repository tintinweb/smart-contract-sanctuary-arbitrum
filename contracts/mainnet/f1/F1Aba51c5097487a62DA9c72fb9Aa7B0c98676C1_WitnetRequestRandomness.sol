// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./WitnetRequestMalleableBase.sol";

contract WitnetRequestRandomness
    is
        WitnetRequestMalleableBase
{
    constructor() {
        _initialize(hex"0a0f120508021a01801a0210022202100b");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "../libs/Witnet.sol";

import "../patterns/Clonable.sol";
import "../patterns/Ownable.sol";
import "../patterns/Proxiable.sol";

abstract contract WitnetRequestMalleableBase
    is
        IWitnetRequest,
        Clonable,
        Ownable,
        Proxiable
{   
    using Witnet for *;

    event WitnessingParamsChanged(
        address indexed by,
        uint8 numWitnesses,
        uint8 minWitnessingConsensus,
        uint64 witnssingCollateral,
        uint64 witnessingReward,
        uint64 witnessingUnitaryFee
    );

    struct WitnetRequestMalleableBaseContext {
        /// Contract owner address.
        address owner;
        /// Immutable bytecode template.
        bytes template;
        /// Current request bytecode.
        bytes bytecode;
        /// Current request hash.
        bytes32 hash;
        /// Current request witnessing params.
        WitnetRequestWitnessingParams params;
    }

    struct WitnetRequestWitnessingParams {
        /// Number of witnesses required to be involved for solving this Witnet Data Request.
        uint8 numWitnesses;

        /// Threshold percentage for aborting resolution of a request if the witnessing nodes did not arrive to a broad consensus.
        uint8 minWitnessingConsensus;

        /// Amount of nanowits that a witness solving the request will be required to collateralize in the commitment transaction.
        uint64 witnessingCollateral;

        /// Amount of nanowits that every request-solving witness will be rewarded with.
        uint64 witnessingReward;

        /// Amount of nanowits that will be earned by Witnet miners for each each valid commit/reveal transaction they include in a block.
        uint64 witnessingUnitaryFee;
    }

    /// Returns current Witnet Data Request bytecode, encoded using Protocol Buffers.
    function bytecode() external view override returns (bytes memory) {
        return __storage().bytecode;
    }

    /// Returns SHA256 hash of current Witnet Data Request bytecode.
    function hash() external view override returns (bytes32) {
        return __storage().hash;
    }

    /// Sets amount of nanowits that a witness solving the request will be required to collateralize in the commitment transaction.
    function setWitnessingCollateral(uint64 _witnessingCollateral)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = __storage().params;
        _params.witnessingCollateral = _witnessingCollateral;
        _malleateBytecode(
            _params.numWitnesses,
            _params.minWitnessingConsensus,
            _witnessingCollateral,
            _params.witnessingReward,
            _params.witnessingUnitaryFee
        );
    }

    /// Specifies how much you want to pay for rewarding each of the Witnet nodes.
    /// @param _witnessingReward Amount of nanowits that every request-solving witness will be rewarded with.
    /// @param _witnessingUnitaryFee Amount of nanowits that will be earned by Witnet miners for each each valid 
    /// commit/reveal transaction they include in a block.
    function setWitnessingFees(uint64 _witnessingReward, uint64 _witnessingUnitaryFee)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = __storage().params;
        _params.witnessingReward = _witnessingReward;
        _params.witnessingUnitaryFee = _witnessingUnitaryFee;
        _malleateBytecode(
            _params.numWitnesses,
            _params.minWitnessingConsensus,
            _params.witnessingCollateral,
            _witnessingReward,
            _witnessingUnitaryFee
        );
    }

    /// Sets how many Witnet nodes will be "hired" for resolving the request.
    /// @param _numWitnesses Number of witnesses required to be involved for solving this Witnet Data Request.
    /// @param _minWitnessingConsensus Threshold percentage for aborting resolution of a request if the witnessing 
    /// nodes did not arrive to a broad consensus.
    function setWitnessingQuorum(uint8 _numWitnesses, uint8 _minWitnessingConsensus)
        public
        virtual
        onlyOwner
    {
        WitnetRequestWitnessingParams storage _params = __storage().params;
        _params.numWitnesses = _numWitnesses;
        _params.minWitnessingConsensus = _minWitnessingConsensus;
        _malleateBytecode(
            _numWitnesses,
            _minWitnessingConsensus,
            _params.witnessingCollateral,
            _params.witnessingReward,
            _params.witnessingUnitaryFee
        );
    }

    /// Returns immutable template bytecode: actual CBOR-encoded data request at the Witnet protocol
    /// level, including no witnessing parameters at all.
    function template()
        external view
        returns (bytes memory)
    {
        return __storage().template;
    }

    /// Returns total amount of nanowits that witnessing nodes will need to collateralize all together.
    function totalWitnessingCollateral()
        external view
        returns (uint128)
    {
        WitnetRequestWitnessingParams storage _params = __storage().params;
        return _params.numWitnesses * _params.witnessingCollateral;
    }

    /// Returns total amount of nanowits that will have to be paid in total for this request to be solved.
    function totalWitnessingFee()
        external view
        returns (uint128)
    {
        WitnetRequestWitnessingParams storage _params = __storage().params;
        return _params.numWitnesses * (2 * _params.witnessingUnitaryFee + _params.witnessingReward);
    }

    /// Returns witnessing parameters of current Witnet Data Request.
    function witnessingParams()
        external view
        returns (WitnetRequestWitnessingParams memory)
    {
        return __storage().params;
    }


    // ================================================================================================================
    // --- 'Clonable' extension ---------------------------------------------------------------------------------------

    /// Deploys and returns the address of a minimal proxy clone that replicates contract
    /// behaviour while using its own EVM storage.
    /// @dev This function should always provide a new address, no matter how many times 
    /// @dev is actually called from the same `msg.sender`.
    /// @dev Ownership of new clone is transferred to the caller.
    function clone()
        virtual public
        wasInitialized
        returns (WitnetRequestMalleableBase)
    {
        return _afterCloning(_clone());
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract 
    /// behaviour while using its own EVM storage.
    /// @dev This function uses the CREATE2 opcode and a `_salt` to deterministically deploy
    /// @dev the clone. Using the same `_salt` multiple time will revert, since
    /// @dev no contract can be deployed more than once at the same address.
    /// @dev Ownership of new clone is transferred to the caller.
    function cloneDeterministic(bytes32 _salt)
        virtual public
        wasInitialized
        returns (WitnetRequestMalleableBase)
    {
        return _afterCloning(_cloneDeterministic(_salt));
    }

    /// @notice Initializes a cloned instance. 
    /// @dev Every cloned instance can only get initialized once.
    function initializeClone(bytes memory _initData)
        virtual external
        initializer // => ensure a cloned instance can only be initialized once
        onlyDelegateCalls // => this method can only be called upon cloned instances
    {
        _initialize(_initData);
    }

    /// @notice Tells whether this instance has been initialized.
    function initialized()
        override 
        public view
        returns (bool)
    {
        return __storage().template.length > 0;
    }


    // ================================================================================================================
    // --- 'Ownable' overriden functions ------------------------------------------------------------------------------

    /// Returns the address of the current owner.
    function owner()
        public view
        virtual override
        returns (address)
    {
        return __storage().owner;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    function _transferOwnership(address newOwner)
        internal
        virtual override
    {
        address oldOwner = __storage().owner;
        __storage().owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


    // ================================================================================================================
    // --- 'Proxiable 'overriden functions ----------------------------------------------------------------------------

    /// @dev Complying with EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID()
        external pure
        virtual override
        returns (bytes32)
    {
        return (
            /* keccak256("io.witnet.requests.malleable") */
            0x851d0a92a3ad30295bef33afc69d6874779826b7789386b336e22621365ed2c2
        );
    }


    // ================================================================================================================
    // --- INTERNAL FUNCTIONS -----------------------------------------------------------------------------------------    

    function _afterCloning(address _newInstance)
        virtual internal
        returns (WitnetRequestMalleableBase)
    {
        WitnetRequestMalleableBase(_newInstance).initializeClone(__storage().template);
        Ownable(address(_newInstance)).transferOwnership(msg.sender);
        return WitnetRequestMalleableBase(_newInstance);
    }

    /// @dev Initializes witnessing params and template bytecode. 
    function _initialize(bytes memory _template)
        virtual internal
    {
        _transferOwnership(_msgSender());

        assert(_template.length > 0);
        __storage().template = _template;

        WitnetRequestWitnessingParams storage _params = __storage().params;
        _params.numWitnesses = 7;
        _params.minWitnessingConsensus = 51;
        _params.witnessingCollateral = 15 * 10 ** 9;  // 15 WIT
        _params.witnessingReward = 15 * 10 ** 7;      // 150 mWIT
        _params.witnessingUnitaryFee = 10 ** 7; // 10 mWIT
        
        _malleateBytecode(
            _params.numWitnesses,
            _params.minWitnessingConsensus,
            _params.witnessingCollateral,
            _params.witnessingReward,
            _params.witnessingUnitaryFee
        );
    }

    /// @dev Serializes new `bytecode` by combining immutable template with given parameters.
    function _malleateBytecode(
            uint8 _numWitnesses,
            uint8 _minWitnessingConsensus,
            uint64 _witnessingCollateral,
            uint64 _witnessingReward,
            uint64 _witnessingUnitaryFee
        )
        internal
        virtual
    {
        require(
            _witnessingReward > 0,
            "WitnetRequestMalleableBase: no reward"
        );
        require(
            _numWitnesses >= 1 && _numWitnesses <= 127,
            "WitnetRequestMalleableBase: number of witnesses out of range"
        );
        require(
            _minWitnessingConsensus >= 51 && _minWitnessingConsensus <= 99,
            "WitnetRequestMalleableBase: witnessing consensus out of range"
        );
        require(
            _witnessingCollateral >= 10 ** 9,
            "WitnetRequestMalleableBase: witness collateral below 1 WIT"
        );

        __storage().bytecode = abi.encodePacked(
            __storage().template,
            _uint64varint(bytes1(0x10), _witnessingReward),
            _uint8varint(bytes1(0x18), _numWitnesses),
            _uint64varint(0x20, _witnessingUnitaryFee),
            _uint8varint(0x28, _minWitnessingConsensus),
            _uint64varint(0x30, _witnessingCollateral)
        );
        __storage().hash = __storage().bytecode.hash();
        emit WitnessingParamsChanged(
            msg.sender,
            _numWitnesses,
            _minWitnessingConsensus,
            _witnessingCollateral,
            _witnessingReward,
            _witnessingUnitaryFee
        );
    }

    /// @dev Returns pointer to storage slot where State struct is located.
    function __storage()
        internal pure
        virtual
        returns (WitnetRequestMalleableBaseContext storage _ptr)
    {
        assembly {
            _ptr.slot :=
                /* keccak256("io.witnet.requests.malleable.context") */
                0x375930152e1d0d102998be6e496b0cee86c9ecd0efef01014ecff169b17dfba7
        }
    }

    /// @dev Encode uint64 into tagged varint.
    /// @dev See https://developers.google.com/protocol-buffers/docs/encoding#varints.
    /// @param t Tag
    /// @param n Number
    /// @return Marshaled bytes
    function _uint64varint(bytes1 t, uint64 n)
        internal pure
        returns (bytes memory)
    {
        // Count the number of groups of 7 bits
        // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
        uint64 tmp = n;
        uint64 numBytes = 2;
        while (tmp > 0x7F) {
            tmp = tmp >> 7;
            numBytes += 1;
        }
        bytes memory buf = new bytes(numBytes);
        tmp = n;
        buf[0] = t;
        for (uint64 i = 1; i < numBytes; i++) {
            // Set the first bit in the byte for each group of 7 bits
            buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
            tmp = tmp >> 7;
        }
        // Unset the first bit of the last byte
        buf[numBytes - 1] &= 0x7F;
        return buf;
    }

    /// @dev Encode uint8 into tagged varint.
    /// @param t Tag
    /// @param n Number
    /// @return Marshaled bytes
    function _uint8varint(bytes1 t, uint8 n)
        internal pure
        returns (bytes memory)
    {
        return _uint64varint(t, uint64(n));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Proxiable {
    /// @dev Complying with EIP-1822: Universal Upgradeable Proxy Standard (UUPS)
    /// @dev See https://eips.ethereum.org/EIPS/eip-1822.
    function proxiableUUID() virtual external view returns (bytes32);

    struct ProxiableSlot {
        address implementation;
        address proxy;
    }

    function __implementation() internal view returns (address) {
        return __proxiable().implementation;
    }

    function __proxy() internal view returns (address) {
        return __proxiable().proxy;
    }

    function __proxiable() internal pure returns (ProxiableSlot storage proxiable) {
        assembly {
            // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
            proxiable.slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./Initializable.sol";

abstract contract Clonable
    is
        Initializable
{
    address immutable internal _SELF = address(this);

    event Cloned(address indexed by, address indexed self, address indexed clone);

    modifier onlyDelegateCalls virtual {
        require(address(this) != _SELF, "Clonable: not a delegate call");
        _;
    }

    modifier wasInitialized {
        require(initialized(), "Clonable: not initialized");
        _;
    }

    /// @notice Tells whether this contract is a clone of `self()`
    function cloned()
        public view
        returns (bool)
    {
        return (
            address(this) != self()
        );
    }

    /// @notice Tells whether this instance has been initialized.
    function initialized() virtual public view returns (bool);

    /// @notice Contract address to which clones will be re-directed.
    function self() virtual public view returns (address) {
        return _SELF;
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract
    /// behaviour while using its own EVM storage.
    /// @dev This function should always provide a new address, no matter how many times 
    /// @dev is actually called from the same `msg.sender`.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _clone()
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE new instance:
            _instance := create(0, ptr, 0x37)
        }        
        require(_instance != address(0), "Clonable: CREATE failed");
        emit Cloned(msg.sender, self(), _instance);
    }

    /// @notice Returns minimal proxy's deploy bytecode.
    function _cloneBytecode()
        virtual internal view
        returns (bytes memory)
    {
        return abi.encodePacked(
            hex"3d602d80600a3d3981f3363d3d373d3d3d363d73",
            bytes20(self()),
            hex"5af43d82803e903d91602b57fd5bf3"
        );
    }

    /// @notice Returns mem pointer to minimal proxy's deploy bytecode.
    function _cloneBytecodePtr()
        virtual internal view
        returns (bytes memory ptr)
    {
        address _base = self();
        assembly {
            // ptr to free mem:
            ptr := mload(0x40)
            // begin minimal proxy construction bytecode:
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            // make minimal proxy delegate all calls to `self()`:
            mstore(add(ptr, 0x14), shl(0x60, _base))
            // end minimal proxy construction bytecode:
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
    }

    /// Deploys and returns the address of a minimal proxy clone that replicates contract 
    /// behaviour while using its own EVM storage.
    /// @dev This function uses the CREATE2 opcode and a `_salt` to deterministically deploy
    /// @dev the clone. Using the same `_salt` multiple times will revert, since
    /// @dev no contract can be deployed more than once at the same address.
    /// @dev See https://eips.ethereum.org/EIPS/eip-1167.
    /// @dev See https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/.
    function _cloneDeterministic(bytes32 _salt)
        internal
        returns (address _instance)
    {
        bytes memory ptr = _cloneBytecodePtr();
        assembly {
            // CREATE2 new instance:
            _instance := create2(0, ptr, 0x37, _salt)
        }
        require(_instance != address(0), "Clonable: CREATE2 failed");
        emit Cloned(msg.sender, self(), _instance);
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
/// 
/// TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
/// TODO: add support for Float64 (majorType = 7, additionalInformation = 27) 

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
    if (index >= _range) {
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
    withinRange(length, buffer.data.length - buffer.cursor)
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
    withinRange(buffer.cursor, buffer.data.length + 1)
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
    withinRange(offset + length, buffer.data.length + 1)
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
    withinRange(length, buffer.data.length - buffer.cursor + 1)
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
    withinRange(buffer.cursor + length, buffer.data.length + 1)
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
    // Get bits 1 to 5, then normalize to the [-14, 15] range so as to counterweight the IEEE 754 exponent bias
    int32 exponent = (int32(value & 0x7c00) >> 10) - 15;
    // Get bits 6 to 15
    int32 significand = int32(value & 0x03ff);
    // Add 1024 to the fraction if the exponent is 0
    if (exponent == 15) {
      significand |= 0x400;
    }
    // Compute `2 ^ exponent · (1 + fraction / 1024)`
    if (exponent >= 0) {
      result = (
        int32((int256(1 << uint256(int256(exponent)))
          * 10000
          * int256(uint256(int256(significand)) | 0x400)) >> 10)
      );
    } else {
      result = (int32(
        ((int256(uint256(int256(significand)) | 0x400) * 10000)
          / int256(1 << uint256(int256(- exponent))))
          >> 10
      ));
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
    withinRange(buffer.cursor + 1, buffer.data.length)
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
    withinRange(buffer.cursor + 3, buffer.data.length)
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
    withinRange(buffer.cursor + 7, buffer.data.length)
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
    withinRange(buffer.cursor + 15, buffer.data.length)
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
    withinRange(buffer.cursor + 31, buffer.data.length)
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

  /// @notice Replace bytecode indexed wildcards by correspondent string.
  /// @dev Wildcard format: "\#\", with # in ["0".."9"].
  /// @param input Bytes array containing strings.
  /// @param args String values for replacing existing indexed wildcards in input.
  function replace(bytes memory input, string[] memory args)
    internal pure
    returns (bytes memory output)
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
      return input;
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
      return input;
    }
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
    withinRange(offset, buffer.data.length + 1)
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

import "../interfaces/IWitnetRequest.sol";
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
        address addr;       // Address of the IWitnetRequest contract containing Witnet data request raw bytecode.
        bytes32 slaHash;    // Radon SLA hash of the Witnet data request.
        bytes32 radHash;    // Radon radHash of the Witnet data request.
        uint256 gasprice;   // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;     // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
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
        /// Script format errors =============================================================================================
            /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
            SourceScriptNotCBOR, 
            /// 0x02: The CBOR value decoded from a source script is not an Array.
            SourceScriptNotArray,
            /// 0x03: The Array value decoded form a source script is not a valid Data Request.
            SourceScriptNotRADON,
            /// Unallocated
            ScriptFormat0x04, ScriptFormat0x05, ScriptFormat0x06, ScriptFormat0x07, ScriptFormat0x08, ScriptFormat0x09,
            ScriptFormat0x0A, ScriptFormat0x0B, ScriptFormat0x0C, ScriptFormat0x0D, ScriptFormat0x0E, ScriptFormat0x0F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Complexity errors ================================================================================================
            /// 0x10: The request contains too many sources.
            RequestTooManySources,
            /// 0x11: The script contains too many calls.
            ScriptTooManyCalls,
            /// Unallocated
            Complexity0x12, Complexity0x13, Complexity0x14, Complexity0x15, Complexity0x16, Complexity0x17, Complexity0x18,
            Complexity0x19, Complexity0x1A, Complexity0x1B, Complexity0x1C, Complexity0x1D, Complexity0x1E, Complexity0x1F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Operator errors ===================================================================================================
            /// 0x20: The operator does not exist.
            UnsupportedOperator,
            /// Unallocated
            Operator0x21, Operator0x22, Operator0x23, Operator0x24, Operator0x25, Operator0x26, Operator0x27, Operator0x28,
            Operator0x29, Operator0x2A, Operator0x2B, Operator0x2C, Operator0x2D, Operator0x2E, Operator0x2F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Retrieval-specific errors =========================================================================================
            /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
            HTTP,
            /// 0x31: Retrieval of at least one of the sources timed out.
            RetrievalTimeout,
            /// Unallocated
            Retrieval0x32, Retrieval0x33, Retrieval0x34, Retrieval0x35, Retrieval0x36, Retrieval0x37, Retrieval0x38, 
            Retrieval0x39, Retrieval0x3A, Retrieval0x3B, Retrieval0x3C, Retrieval0x3D, Retrieval0x3E, Retrieval0x3F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Math errors =======================================================================================================
            /// 0x40: Math operator caused an underflow.
            Underflow,
            /// 0x41: Math operator caused an overflow.
            Overflow,
            /// 0x42: Tried to divide by zero.
            DivisionByZero,
            /// Unallocated
            Math0x43, Math0x44, Math0x45, Math0x46, Math0x47, Math0x48, Math0x49, 
            Math0x4A, Math0x4B, Math0x4C, Math0x4D, Math0x4E, Math0x4F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Other errors ======================================================================================================
            /// 0x50: Received zero reveals
            NoReveals,
            /// 0x51: Insufficient consensus in tally precondition clause
            InsufficientConsensus,
            /// 0x52: Received zero commits
            InsufficientCommits,
            /// 0x53: Generic error during tally execution
            TallyExecution,
            /// Unallocated
            OtherError0x54, OtherError0x55, OtherError0x56, OtherError0x57, OtherError0x58, OtherError0x59,
            OtherError0x5A, OtherError0x5B, OtherError0x5C, OtherError0x5D, OtherError0x5E, OtherError0x5F,
            /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
            MalformedReveal,
            /// Unallocated
            OtherError0x61, OtherError0x62, OtherError0x63, OtherError0x64, OtherError0x65, OtherError0x66,
            OtherError0x67, OtherError0x68, OtherError0x69, OtherError0x6A, OtherError0x6B, OtherError0x6C,
            OtherError0x6D, OtherError0x6E,OtherError0x6F,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Access errors =====================================================================================================
            /// 0x70: Tried to access a value from an index using an index that is out of bounds
            ArrayIndexOutOfBounds,
            /// 0x71: Tried to access a value from a map using a key that does not exist
            MapKeyNotFound,
            /// Unallocated
            OtherError0x72, OtherError0x73, OtherError0x74, OtherError0x75, OtherError0x76, OtherError0x77, OtherError0x78, 
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
        /// Bridge errors: errors that only belong in inter-client communication ==============================================
            /// 0xE0: Requests that cannot be parsed must always get this error as their result.
            /// However, this is not a valid result in a Tally transaction, because invalid requests
            /// are never included into blocks and therefore never get a Tally in response.
            BridgeMalformedRequest,
            /// 0xE1: Witnesses exceeds 100
            BridgePoorIncentives,
            /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
            /// amount of value that is unjustifiably high when compared with the reward they will be getting
            BridgeOversizedResult,
            /// Unallocated
            OtherError0xE3, OtherError0xE4, OtherError0xE5, OtherError0xE6, OtherError0xE7, OtherError0xE8, OtherError0xE9,
            OtherError0xEA, OtherError0xEB, OtherError0xEC, OtherError0xED, OtherError0xEE, OtherError0xEF, OtherError0xF0,
            OtherError0xF1, OtherError0xF2, OtherError0xF3, OtherError0xF4, OtherError0xF5, OtherError0xF6, OtherError0xF7,
            OtherError0xF8, OtherError0xF9, OtherError0xFA, OtherError0xFB, OtherError0xFC, OtherError0xFD, OtherError0xFE,
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }


    /// ===============================================================================================================
    /// --- 'Witnet.Result' helper methods ----------------------------------------------------------------------------

    modifier _isError(Result memory result) {
        require(!result.success, "Witnet: no actual errors");
        _;
    }

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
    /// --- 'bytes' helper methods ------------------------------------------------------------------------------------

    /// @dev Witnet function that computes the hash of a CBOR-encoded Data Request.
    function hash(bytes memory _bytecode) internal view returns (bytes32) {
        if (
            block.chainid != 1101           // Polygon zkEVM mainnet
                && block.chainid != 1442    // Polygon zkEVM testnet
        ) {
            return sha256(_bytecode);
        } else {
            return 0x0;
        }
    }

    /// @dev Transform given bytes into a Witnet.Result instance.
    /// @param bytecode Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory bytecode)
        internal pure
        returns (Witnet.Result memory)
    {
        WitnetCBOR.CBOR memory cborValue = WitnetCBOR.fromBytes(bytecode);
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
    /// --- 'uint8' helper methods ------------------------------------------------------------------------------------

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

pragma solidity >=0.7.0 <0.9.0;

/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    
    /// @notice A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// @notice a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// @notice Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}