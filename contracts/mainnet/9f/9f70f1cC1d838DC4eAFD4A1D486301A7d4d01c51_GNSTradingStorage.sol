// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
pragma solidity 0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IGNSAddressStore.sol";

/**
 * @dev Proxy base for the diamond and its facet contracts to store addresses and manage access control
 */
abstract contract GNSAddressStore is Initializable, IGNSAddressStore {
    AddressStore private addressStore;

    /// @inheritdoc IGNSAddressStore
    function initialize(address _rolesManager) external initializer {
        if (_rolesManager == address(0)) {
            revert IGeneralErrors.InitError();
        }

        _setRole(_rolesManager, Role.ROLES_MANAGER, true);
    }

    // Addresses

    /// @inheritdoc IGNSAddressStore
    function getAddresses() external view returns (Addresses memory) {
        return addressStore.globalAddresses;
    }

    // Roles

    /// @inheritdoc IGNSAddressStore
    function hasRole(address _account, Role _role) public view returns (bool) {
        return addressStore.accessControl[_account][_role];
    }

    /**
     * @dev Update role for account
     * @param _account account to update
     * @param _role role to set
     * @param _value true if allowed, false if not
     */
    function _setRole(address _account, Role _role, bool _value) internal {
        addressStore.accessControl[_account][_role] = _value;
        emit AccessControlUpdated(_account, _role, _value);
    }

    /// @inheritdoc IGNSAddressStore
    function setRoles(
        address[] calldata _accounts,
        Role[] calldata _roles,
        bool[] calldata _values
    ) external onlyRole(Role.ROLES_MANAGER) {
        if (_accounts.length != _roles.length || _accounts.length != _values.length) {
            revert IGeneralErrors.InvalidInputLength();
        }

        for (uint256 i = 0; i < _accounts.length; ++i) {
            if (_roles[i] == Role.ROLES_MANAGER && _accounts[i] == msg.sender) {
                revert NotAllowed();
            }

            _setRole(_accounts[i], _roles[i], _values[i]);
        }
    }

    /**
     * @dev Reverts if caller does not have role
     * @param _role role to enforce
     */
    function _enforceRole(Role _role) internal view {
        if (!hasRole(msg.sender, _role)) {
            revert WrongAccess();
        }
    }

    /**
     * @dev Reverts if caller does not have role
     */
    modifier onlyRole(Role _role) {
        _enforceRole(_role);
        _;
    }

    /**
     * @dev Reverts if caller isn't this same contract (facets calling other facets)
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert WrongAccess();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../abstract/GNSAddressStore.sol";

import "../../interfaces/libraries/ITradingStorageUtils.sol";

import "../../libraries/TradingStorageUtils.sol";
import "../../libraries/ArrayGetters.sol";

/**
 * @dev Facet #5: Trading storage
 */
contract GNSTradingStorage is GNSAddressStore, ITradingStorageUtils {
    // Initialization

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ITradingStorageUtils
    function initializeTradingStorage(
        address _gns,
        address _gnsStaking,
        address[] memory _collaterals,
        address[] memory _gTokens
    ) external reinitializer(6) {
        TradingStorageUtils.initializeTradingStorage(_gns, _gnsStaking, _collaterals, _gTokens);
    }

    // Management Setters

    /// @inheritdoc ITradingStorageUtils
    function updateTradingActivated(TradingActivated _activated) external onlyRole(Role.GOV) {
        TradingStorageUtils.updateTradingActivated(_activated);
    }

    /// @inheritdoc ITradingStorageUtils
    function addCollateral(address _collateral, address _gToken) external onlyRole(Role.GOV) {
        TradingStorageUtils.addCollateral(_collateral, _gToken);
    }

    /// @inheritdoc ITradingStorageUtils
    function toggleCollateralActiveState(uint8 _collateralIndex) external onlyRole(Role.GOV) {
        TradingStorageUtils.toggleCollateralActiveState(_collateralIndex);
    }

    function updateGToken(address _collateral, address _gToken) external onlyRole(Role.GOV) {
        TradingStorageUtils.updateGToken(_collateral, _gToken);
    }

    // Interactions

    /// @inheritdoc ITradingStorageUtils
    function storeTrade(
        Trade memory _trade,
        TradeInfo memory _tradeInfo
    ) external virtual onlySelf returns (Trade memory) {
        return TradingStorageUtils.storeTrade(_trade, _tradeInfo);
    }

    /// @inheritdoc ITradingStorageUtils
    function updateTradeCollateralAmount(
        ITradingStorage.Id memory _tradeId,
        uint120 _collateralAmount
    ) external virtual onlySelf {
        TradingStorageUtils.updateTradeCollateralAmount(_tradeId, _collateralAmount);
    }

    /// @inheritdoc ITradingStorageUtils
    function updateTradePosition(
        ITradingStorage.Id memory _tradeId,
        uint120 _collateralAmount,
        uint24 _leverage,
        uint64 _openPrice
    ) external virtual onlySelf {
        TradingStorageUtils.updateTradePosition(_tradeId, _collateralAmount, _leverage, _openPrice);
    }

    /// @inheritdoc ITradingStorageUtils
    function updateOpenOrderDetails(
        ITradingStorage.Id memory _tradeId,
        uint64 _openPrice,
        uint64 _tp,
        uint64 _sl,
        uint16 _maxSlippageP
    ) external virtual onlySelf {
        TradingStorageUtils.updateOpenOrderDetails(_tradeId, _openPrice, _tp, _sl, _maxSlippageP);
    }

    /// @inheritdoc ITradingStorageUtils
    function updateTradeTp(Id memory _tradeId, uint64 _newTp) external virtual onlySelf {
        TradingStorageUtils.updateTradeTp(_tradeId, _newTp);
    }

    /// @inheritdoc ITradingStorageUtils
    function updateTradeSl(Id memory _tradeId, uint64 _newSl) external virtual onlySelf {
        TradingStorageUtils.updateTradeSl(_tradeId, _newSl);
    }

    /// @inheritdoc ITradingStorageUtils
    function closeTrade(Id memory _tradeId) external virtual onlySelf {
        TradingStorageUtils.closeTrade(_tradeId);
    }

    /// @inheritdoc ITradingStorageUtils
    function storePendingOrder(
        PendingOrder memory _pendingOrder
    ) external virtual onlySelf returns (PendingOrder memory) {
        return TradingStorageUtils.storePendingOrder(_pendingOrder);
    }

    /// @inheritdoc ITradingStorageUtils
    function closePendingOrder(Id memory _orderId) external virtual onlySelf {
        TradingStorageUtils.closePendingOrder(_orderId);
    }

    // Getters

    /// @inheritdoc ITradingStorageUtils
    function getCollateral(uint8 _index) external view returns (Collateral memory) {
        return TradingStorageUtils.getCollateral(_index);
    }

    /// @inheritdoc ITradingStorageUtils
    function isCollateralActive(uint8 _index) external view returns (bool) {
        return TradingStorageUtils.isCollateralActive(_index);
    }

    /// @inheritdoc ITradingStorageUtils
    function isCollateralListed(uint8 _index) external view returns (bool) {
        return TradingStorageUtils.isCollateralListed(_index);
    }

    /// @inheritdoc ITradingStorageUtils
    function getCollateralsCount() external view returns (uint8) {
        return TradingStorageUtils.getCollateralsCount();
    }

    /// @inheritdoc ITradingStorageUtils
    function getCollaterals() external view returns (Collateral[] memory) {
        return TradingStorageUtils.getCollaterals();
    }

    /// @inheritdoc ITradingStorageUtils
    function getCollateralIndex(address _collateral) external view returns (uint8) {
        return TradingStorageUtils.getCollateralIndex(_collateral);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTradingActivated() external view returns (TradingActivated) {
        return TradingStorageUtils.getTradingActivated();
    }

    /// @inheritdoc ITradingStorageUtils
    function getTraderStored(address _trader) external view returns (bool) {
        return TradingStorageUtils.getTraderStored(_trader);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTraders(uint32 _offset, uint32 _limit) external view returns (address[] memory) {
        return ArrayGetters.getTraders(_offset, _limit);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTrade(address _trader, uint32 _index) external view returns (Trade memory) {
        return TradingStorageUtils.getTrade(_trader, _index);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTrades(address _trader) external view returns (Trade[] memory) {
        return ArrayGetters.getTrades(_trader);
    }

    /// @inheritdoc ITradingStorageUtils
    function getAllTrades(uint256 _offset, uint256 _limit) external view returns (Trade[] memory) {
        return ArrayGetters.getAllTrades(_offset, _limit);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTradeInfo(address _trader, uint32 _index) external view returns (TradeInfo memory) {
        return TradingStorageUtils.getTradeInfo(_trader, _index);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTradeInfos(address _trader) external view returns (TradeInfo[] memory) {
        return ArrayGetters.getTradeInfos(_trader);
    }

    /// @inheritdoc ITradingStorageUtils
    function getAllTradeInfos(uint256 _offset, uint256 _limit) external view returns (TradeInfo[] memory) {
        return ArrayGetters.getAllTradeInfos(_offset, _limit);
    }

    /// @inheritdoc ITradingStorageUtils
    function getPendingOrder(Id memory _orderId) external view returns (PendingOrder memory) {
        return TradingStorageUtils.getPendingOrder(_orderId);
    }

    /// @inheritdoc ITradingStorageUtils
    function getPendingOrders(address _user) external view returns (PendingOrder[] memory) {
        return ArrayGetters.getPendingOrders(_user);
    }

    /// @inheritdoc ITradingStorageUtils
    function getAllPendingOrders(uint256 _offset, uint256 _limit) external view returns (PendingOrder[] memory) {
        return ArrayGetters.getAllPendingOrders(_offset, _limit);
    }

    /// @inheritdoc ITradingStorageUtils
    function getTradePendingOrderBlock(
        Id memory _tradeId,
        PendingOrderType _orderType
    ) external view returns (uint256) {
        return TradingStorageUtils.getTradePendingOrderBlock(_tradeId, _orderType);
    }

    /// @inheritdoc ITradingStorageUtils
    function getCounters(address _trader, CounterType _type) external view returns (Counter memory) {
        return TradingStorageUtils.getCounters(_trader, _type);
    }

    /// @inheritdoc ITradingStorageUtils
    function getGToken(uint8 _collateralIndex) external view returns (address) {
        return TradingStorageUtils.getGToken(_collateralIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for Arbitrum special l2 functions
 */
interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for Chainlink feeds
 */
interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface for ERC20 tokens
 */
interface IERC20 is IERC20Metadata {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function hasRole(bytes32, address) external view returns (bool);

    function deposit() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for errors potentially used in all libraries (general names)
 */
interface IGeneralErrors {
    error InitError();
    error InvalidAddresses();
    error InvalidInputLength();
    error InvalidCollateralIndex();
    error WrongParams();
    error WrongLength();
    error WrongOrder();
    error WrongIndex();
    error BlockOrder();
    error Overflow();
    error ZeroAddress();
    error ZeroValue();
    error AlreadyExists();
    error DoesntExist();
    error Paused();
    error BelowMin();
    error AboveMax();
    error NotAuthorized();
    error WrongTradeType();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./types/IAddressStore.sol";
import "./IGeneralErrors.sol";

/**
 * @dev Interface for AddressStoreUtils library
 */
interface IGNSAddressStore is IAddressStore, IGeneralErrors {
    /**
     * @dev Initializes address store facet
     * @param _rolesManager roles manager address
     */
    function initialize(address _rolesManager) external;

    /**
     * @dev Returns addresses current values
     */
    function getAddresses() external view returns (Addresses memory);

    /**
     * @dev Returns whether an account has been granted a particular role
     * @param _account account address to check
     * @param _role role to check
     */
    function hasRole(address _account, Role _role) external view returns (bool);

    /**
     * @dev Updates access control for a list of accounts
     * @param _accounts accounts addresses to update
     * @param _roles corresponding roles to update
     * @param _values corresponding new values to set
     */
    function setRoles(address[] calldata _accounts, Role[] calldata _roles, bool[] calldata _values) external;

    /**
     * @dev Emitted when addresses are updated
     * @param addresses new addresses values
     */
    event AddressesUpdated(Addresses addresses);

    /**
     * @dev Emitted when access control is updated for an account
     * @param target account address to update
     * @param role role to update
     * @param access whether role is granted or revoked
     */
    event AccessControlUpdated(address target, Role role, bool access);

    error NotAllowed();
    error WrongAccess();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IGNSAddressStore.sol";
import "./IGNSDiamondCut.sol";
import "./IGNSDiamondLoupe.sol";
import "./types/ITypes.sol";

/**
 * @dev the non-expanded interface for multi-collat diamond, only contains types/structs/enums
 */

interface IGNSDiamond is IGNSAddressStore, IGNSDiamondCut, IGNSDiamondLoupe, ITypes {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./types/IDiamondStorage.sol";

/**
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Gains Network
 * @dev Based on EIP-2535: Diamonds (https://eips.ethereum.org/EIPS/eip-2535)
 * @dev Follows diamond-3 implementation (https://github.com/mudgen/diamond-3-hardhat/)
 * @dev One of the diamond standard interfaces, used for diamond management.
 */
interface IGNSDiamondCut is IDiamondStorage {
    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments _calldata is executed with delegatecall on _init
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    /**
     * @dev Emitted when function selectors of a facet of the diamond is added, replaced, or removed
     * @param _diamondCut Contains the update data (facet addresses, action, function selectors)
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata Function call to execute after the diamond cut
     */
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
    error InvalidFacetCutAction();
    error NotContract();
    error NotFound();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Gains Network
 * @dev Based on EIP-2535: Diamonds (https://eips.ethereum.org/EIPS/eip-2535)
 * @dev Follows diamond-3 implementation (https://github.com/mudgen/diamond-3-hardhat/)
 * @dev One of the diamond standard interfaces, used to inspect the diamond like a magnifying glass.
 */
interface IGNSDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IGNSDiamond.sol";
import "./libraries/IPairsStorageUtils.sol";
import "./libraries/IReferralsUtils.sol";
import "./libraries/IFeeTiersUtils.sol";
import "./libraries/IPriceImpactUtils.sol";
import "./libraries/ITradingStorageUtils.sol";
import "./libraries/ITriggerRewardsUtils.sol";
import "./libraries/ITradingInteractionsUtils.sol";
import "./libraries/ITradingCallbacksUtils.sol";
import "./libraries/IBorrowingFeesUtils.sol";
import "./libraries/IPriceAggregatorUtils.sol";

/**
 * @dev Expanded version of multi-collat diamond that includes events and function signatures
 * Technically this interface is virtual since the diamond doesn't directly implement these functions.
 * It only forwards the calls to the facet contracts using delegatecall.
 */
interface IGNSMultiCollatDiamond is
    IGNSDiamond,
    IPairsStorageUtils,
    IReferralsUtils,
    IFeeTiersUtils,
    IPriceImpactUtils,
    ITradingStorageUtils,
    ITriggerRewardsUtils,
    ITradingInteractionsUtils,
    ITradingCallbacksUtils,
    IBorrowingFeesUtils,
    IPriceAggregatorUtils
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for GNSStaking contract
 */
interface IGNSStaking {
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    struct RewardState {
        uint128 accRewardPerGns; // 1e18
        uint128 precisionDelta;
    }

    struct RewardInfo {
        uint128 debtToken; // 1e18
        uint128 __placeholder;
    }

    struct UnlockSchedule {
        uint128 totalGns; // 1e18
        uint128 claimedGns; // 1e18
        uint128 debtDai; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
        uint16 __placeholder;
    }

    struct UnlockScheduleInput {
        uint128 totalGns; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
    }

    enum UnlockType {
        LINEAR,
        CLIFF
    }

    function owner() external view returns (address);

    function distributeReward(address _rewardToken, uint256 _amountToken) external;

    function createUnlockSchedule(UnlockScheduleInput calldata _schedule, address _staker) external;

    event UnlockManagerUpdated(address indexed manager, bool authorized);

    event DaiHarvested(address indexed staker, uint128 amountDai);

    event RewardHarvested(address indexed staker, address indexed token, uint128 amountToken);
    event RewardHarvestedFromUnlock(
        address indexed staker,
        address indexed token,
        bool isOldDai,
        uint256[] ids,
        uint128 amountToken
    );
    event RewardDistributed(address indexed token, uint256 amount);

    event GnsStaked(address indexed staker, uint128 amountGns);
    event GnsUnstaked(address indexed staker, uint128 amountGns);
    event GnsClaimed(address indexed staker, uint256[] ids, uint128 amountGns);

    event UnlockScheduled(address indexed staker, uint256 indexed index, UnlockSchedule schedule);
    event UnlockScheduleRevoked(address indexed staker, uint256 indexed index);

    event RewardTokenAdded(address token, uint256 index, uint128 precisionDelta);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for GToken contract
 */
interface IGToken {
    struct GnsPriceProvider {
        address addr;
        bytes signature;
    }

    struct LockedDeposit {
        address owner;
        uint256 shares; // collateralConfig.precision
        uint256 assetsDeposited; // collateralConfig.precision
        uint256 assetsDiscount; // collateralConfig.precision
        uint256 atTimestamp; // timestamp
        uint256 lockDuration; // timestamp
    }

    struct ContractAddresses {
        address asset;
        address owner; // 2-week timelock contract
        address manager; // 3-day timelock contract
        address admin; // bypasses timelock, access to emergency functions
        address gnsToken;
        address lockedDepositNft;
        address pnlHandler;
        address openTradesPnlFeed;
        GnsPriceProvider gnsPriceProvider;
    }

    struct Meta {
        string name;
        string symbol;
    }

    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint256);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl
    ) external returns (uint256);

    function getLockedDeposit(uint256 depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    event ManagerUpdated(address newValue);
    event AdminUpdated(address newValue);
    event PnlHandlerUpdated(address newValue);
    event OpenTradesPnlFeedUpdated(address newValue);
    event GnsPriceProviderUpdated(GnsPriceProvider newValue);
    event WithdrawLockThresholdsPUpdated(uint256[2] newValue);
    event MaxAccOpenPnlDeltaUpdated(uint256 newValue);
    event MaxDailyAccPnlDeltaUpdated(uint256 newValue);
    event MaxSupplyIncreaseDailyPUpdated(uint256 newValue);
    event LossesBurnPUpdated(uint256 newValue);
    event MaxGnsSupplyMintDailyPUpdated(uint256 newValue);
    event MaxDiscountPUpdated(uint256 newValue);
    event MaxDiscountThresholdPUpdated(uint256 newValue);

    event CurrentMaxSupplyUpdated(uint256 newValue);
    event DailyAccPnlDeltaReset();
    event ShareToAssetsPriceUpdated(uint256 newValue);
    event OpenTradesPnlFeedCallFailed();

    event WithdrawRequested(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );
    event WithdrawCanceled(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );

    event DepositLocked(address indexed sender, address indexed owner, uint256 depositId, LockedDeposit d);
    event DepositUnlocked(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositId,
        LockedDeposit d
    );

    event RewardDistributed(address indexed sender, uint256 assets);

    event AssetsSent(address indexed sender, address indexed receiver, uint256 assets);
    event AssetsReceived(address indexed sender, address indexed user, uint256 assets, uint256 assetsLessDeplete);

    event Depleted(address indexed sender, uint256 assets, uint256 amountGns);
    event Refilled(address indexed sender, uint256 assets, uint256 amountGns);

    event AccPnlPerTokenUsedUpdated(
        address indexed sender,
        uint256 indexed newEpoch,
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl,
        uint256 newEpochPositiveOpenPnl,
        int256 newAccPnlPerTokenUsed
    );

    error OnlyManager();
    error OnlyTradingPnlHandler();
    error OnlyPnlFeed();
    error AddressZero();
    error PriceZero();
    error ValueZero();
    error BytesZero();
    error NoActiveDiscount();
    error BelowMin();
    error AboveMax();
    error WrongValue();
    error WrongValues();
    error GnsPriceCallFailed();
    error GnsTokenPriceZero();
    error PendingWithdrawal();
    error EndOfEpoch();
    error NotAllowed();
    error NoDiscount();
    error NotUnlocked();
    error NotEnoughAssets();
    error MaxDailyPnl();
    error NotUnderCollateralized();
    error AboveInflationLimit();

    // Ownable
    error OwnableInvalidOwner(address owner);

    // ERC4626
    error ERC4626ExceededMaxDeposit();
    error ERC4626ExceededMaxMint();
    error ERC4626ExceededMaxWithdraw();
    error ERC4626ExceededMaxRedeem();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Generic interface for liquidity pool methods for fetching observations (to calculate TWAP) and other basic information
 */
interface ILiquidityPool {
    /**
     * @dev AlgebraPool V1.9 equivalent of Uniswap V3 `observe` function
     * See https://github.com/cryptoalgebra/AlgebraV1.9/blob/main/src/core/contracts/interfaces/pool/IAlgebraPoolDerivedState.sol for more information
     */
    function getTimepoints(
        uint32[] calldata secondsAgos
    )
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    /**
     * @dev Uniswap V3 `observe` function
     * See `https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol` for more information
     */
    function observe(
        uint32[] calldata secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /**
     * @notice The first of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token0() external view returns (address);

    /**
     * @notice The second of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IBorrowingFees.sol";

/**
 * @dev Interface for GNSBorrowingFees facet (inherits types and also contains functions, events, and custom errors)
 */
interface IBorrowingFeesUtils is IBorrowingFees {
    /**
     * @dev Updates borrowing pair params of a pair
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _value new value
     */
    function setBorrowingPairParams(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        BorrowingPairParams calldata _value
    ) external;

    /**
     * @dev Updates borrowing pair params of multiple pairs
     * @param _collateralIndex index of the collateral
     * @param _indices indices of the pairs
     * @param _values new values
     */
    function setBorrowingPairParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        BorrowingPairParams[] calldata _values
    ) external;

    /**
     * @dev Updates borrowing group params of a group
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _value new value
     */
    function setBorrowingGroupParams(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        BorrowingGroupParams calldata _value
    ) external;

    /**
     * @dev Updates borrowing group params of multiple groups
     * @param _collateralIndex index of the collateral
     * @param _indices indices of the groups
     * @param _values new values
     */
    function setBorrowingGroupParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        BorrowingGroupParams[] calldata _values
    ) external;

    /**
     * @dev Callback after a trade is opened/closed to store pending borrowing fees and adjust open interests
     * @param _collateralIndex index of the collateral
     * @param _trader address of the trader
     * @param _pairIndex index of the pair
     * @param _index index of the trade
     * @param _positionSizeCollateral position size of the trade in collateral tokens
     * @param _open true if trade has been opened, false if trade has been closed
     * @param _long true if trade is long, false if trade is short
     */
    function handleTradeBorrowingCallback(
        uint8 _collateralIndex,
        address _trader,
        uint16 _pairIndex,
        uint32 _index,
        uint256 _positionSizeCollateral,
        bool _open,
        bool _long
    ) external;

    /**
     * @dev Resets a trade borrowing fee to 0 (useful when new trade opened or when partial trade executed)
     * @param _collateralIndex index of the collateral
     * @param _trader address of the trader
     * @param _pairIndex index of the pair
     * @param _index index of the trade
     * @param _long true if trade is long, false if trade is short
     */
    function resetTradeBorrowingFees(
        uint8 _collateralIndex,
        address _trader,
        uint16 _pairIndex,
        uint32 _index,
        bool _long
    ) external;

    /**
     * @dev Returns the pending acc borrowing fees for a pair on both sides
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _currentBlock current block number
     * @return accFeeLong new pair acc borrowing fee on long side
     * @return accFeeShort new pair acc borrowing fee on short side
     * @return pairAccFeeDelta  pair acc borrowing fee delta (for side that changed)
     */
    function getBorrowingPairPendingAccFees(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _currentBlock
    ) external view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 pairAccFeeDelta);

    /**
     * @dev Returns the pending acc borrowing fees for a borrowing group on both sides
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _currentBlock current block number
     * @return accFeeLong new group acc borrowing fee on long side
     * @return accFeeShort new group acc borrowing fee on short side
     * @return groupAccFeeDelta  group acc borrowing fee delta (for side that changed)
     */
    function getBorrowingGroupPendingAccFees(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        uint256 _currentBlock
    ) external view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 groupAccFeeDelta);

    /**
     * @dev Returns the borrowing fee for a trade
     * @param _input input data (collateralIndex, trader, pairIndex, index, long, collateral, leverage)
     * @return feeAmountCollateral borrowing fee (collateral precision)
     */
    function getTradeBorrowingFee(BorrowingFeeInput memory _input) external view returns (uint256 feeAmountCollateral);

    /**
     * @dev Returns the liquidation price for a trade
     * @param _input input data (collateralIndex, trader, pairIndex, index, openPrice, long, collateral, leverage)
     */
    function getTradeLiquidationPrice(LiqPriceInput calldata _input) external view returns (uint256);

    /**
     * @dev Returns the open interests for a pair
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @return longOi open interest on long side
     * @return shortOi open interest on short side
     */
    function getPairOisCollateral(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) external view returns (uint256 longOi, uint256 shortOi);

    /**
     * @dev Returns the borrowing group index for a pair
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @return groupIndex borrowing group index
     */
    function getBorrowingPairGroupIndex(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) external view returns (uint16 groupIndex);

    /**
     * @dev Returns the open interest in collateral tokens for a pair on one side
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _long true if long side
     */
    function getPairOiCollateral(uint8 _collateralIndex, uint16 _pairIndex, bool _long) external view returns (uint256);

    /**
     * @dev Returns whether a trade is within the max group borrowing open interest
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _long true if long side
     * @param _positionSizeCollateral position size of the trade in collateral tokens
     */
    function withinMaxBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long,
        uint256 _positionSizeCollateral
    ) external view returns (bool);

    /**
     * @dev Returns a borrowing group's data
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     */
    function getBorrowingGroup(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) external view returns (BorrowingData memory group);

    /**
     * @dev Returns a borrowing group's oi data
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     */
    function getBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) external view returns (OpenInterest memory group);

    /**
     * @dev Returns a borrowing pair's data
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     */
    function getBorrowingPair(uint8 _collateralIndex, uint16 _pairIndex) external view returns (BorrowingData memory);

    /**
     * @dev Returns a borrowing pair's oi data
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     */
    function getBorrowingPairOi(uint8 _collateralIndex, uint16 _pairIndex) external view returns (OpenInterest memory);

    /**
     * @dev Returns a borrowing pair's oi data
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     */
    function getBorrowingPairGroups(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) external view returns (BorrowingPairGroup[] memory);

    /**
     * @dev Returns all borrowing pairs' borrowing data, oi data, and pair groups data
     * @param _collateralIndex index of the collateral
     */
    function getAllBorrowingPairs(
        uint8 _collateralIndex
    ) external view returns (BorrowingData[] memory, OpenInterest[] memory, BorrowingPairGroup[][] memory);

    /**
     * @dev Returns borrowing groups' data and oi data
     * @param _collateralIndex index of the collateral
     * @param _indices indices of the groups
     */
    function getBorrowingGroups(
        uint8 _collateralIndex,
        uint16[] calldata _indices
    ) external view returns (BorrowingData[] memory, OpenInterest[] memory);

    /**
     * @dev Returns borrowing groups' data
     * @param _collateralIndex index of the collateral
     * @param _trader address of trader
     * @param _index index of trade
     */
    function getBorrowingInitialAccFees(
        uint8 _collateralIndex,
        address _trader,
        uint32 _index
    ) external view returns (BorrowingInitialAccFees memory);

    /**
     * @dev Returns the max open interest for a pair
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     */
    function getPairMaxOi(uint8 _collateralIndex, uint16 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns the max open interest in collateral tokens for a pair
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     */
    function getPairMaxOiCollateral(uint8 _collateralIndex, uint16 _pairIndex) external view returns (uint256);

    /**
     * @dev Emitted when a pair's borrowing params is updated
     * @param pairIndex index of the pair
     * @param groupIndex index of its new group
     * @param feePerBlock new fee per block
     * @param feeExponent new fee exponent
     * @param maxOi new max open interest
     */
    event BorrowingPairParamsUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed pairIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint48 feeExponent,
        uint72 maxOi
    );

    /**
     * @dev Emitted when a pair's borrowing group has been updated
     * @param pairIndex index of the pair
     * @param prevGroupIndex previous borrowing group index
     * @param newGroupIndex new borrowing group index
     */
    event BorrowingPairGroupUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed pairIndex,
        uint16 prevGroupIndex,
        uint16 newGroupIndex
    );

    /**
     * @dev Emitted when a group's borrowing params is updated
     * @param groupIndex index of the group
     * @param feePerBlock new fee per block
     * @param maxOi new max open interest
     * @param feeExponent new fee exponent
     */
    event BorrowingGroupUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint72 maxOi,
        uint48 feeExponent
    );

    /**
     * @dev Emitted when a trade's initial acc borrowing fees are stored
     * @param trader address of the trader
     * @param pairIndex index of the pair
     * @param index index of the trade
     * @param initialPairAccFee initial pair acc fee (for the side of the trade)
     * @param initialGroupAccFee initial group acc fee (for the side of the trade)
     */
    event BorrowingInitialAccFeesStored(
        uint8 indexed collateralIndex,
        address indexed trader,
        uint16 indexed pairIndex,
        uint32 index,
        bool long,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );

    /**
     * @dev Emitted when a trade is executed and borrowing callback is handled
     * @param trader address of the trader
     * @param pairIndex index of the pair
     * @param index index of the trade
     * @param open true if trade has been opened, false if trade has been closed
     * @param long true if trade is long, false if trade is short
     * @param positionSizeCollateral position size of the trade in collateral tokens
     */
    event TradeBorrowingCallbackHandled(
        uint8 indexed collateralIndex,
        address indexed trader,
        uint16 indexed pairIndex,
        uint32 index,
        bool open,
        bool long,
        uint256 positionSizeCollateral
    );

    /**
     * @dev Emitted when a pair's borrowing acc fees are updated
     * @param pairIndex index of the pair
     * @param currentBlock current block number
     * @param accFeeLong new pair acc borrowing fee on long side
     * @param accFeeShort new pair acc borrowing fee on short side
     */
    event BorrowingPairAccFeesUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed pairIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort
    );

    /**
     * @dev Emitted when a group's borrowing acc fees are updated
     * @param groupIndex index of the borrowing group
     * @param currentBlock current block number
     * @param accFeeLong new group acc borrowing fee on long side
     * @param accFeeShort new group acc borrowing fee on short side
     */
    event BorrowingGroupAccFeesUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed groupIndex,
        uint256 currentBlock,
        uint64 accFeeLong,
        uint64 accFeeShort
    );

    /**
     * @dev Emitted when a borrowing pair's open interests are updated
     * @param pairIndex index of the pair
     * @param long true if long side
     * @param increase true if open interest is increased, false if decreased
     * @param delta change in open interest in collateral tokens (1e10 precision)
     * @param newOiLong new open interest on long side
     * @param newOiShort new open interest on short side
     */
    event BorrowingPairOiUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed pairIndex,
        bool long,
        bool increase,
        uint72 delta,
        uint72 newOiLong,
        uint72 newOiShort
    );

    /**
     * @dev Emitted when a borrowing group's open interests are updated
     * @param groupIndex index of the borrowing group
     * @param long true if long side
     * @param increase true if open interest is increased, false if decreased
     * @param delta change in open interest in collateral tokens (1e10 precision)
     * @param newOiLong new open interest on long side
     * @param newOiShort new open interest on short side
     */
    event BorrowingGroupOiUpdated(
        uint8 indexed collateralIndex,
        uint16 indexed groupIndex,
        bool long,
        bool increase,
        uint72 delta,
        uint72 newOiLong,
        uint72 newOiShort
    );

    error BorrowingZeroGroup();
    error BorrowingWrongExponent();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IFeeTiers.sol";

/**
 * @dev Interface for GNSFeeTiers facet (inherits types and also contains functions, events, and custom errors)
 */
interface IFeeTiersUtils is IFeeTiers {
    /**
     *
     * @param _groupIndices group indices (pairs storage fee index) to initialize
     * @param _groupVolumeMultipliers corresponding group volume multipliers (1e3)
     * @param _feeTiersIndices fee tiers indices to initialize
     * @param _feeTiers fee tiers values to initialize (feeMultiplier, pointsThreshold)
     */
    function initializeFeeTiers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers,
        uint256[] calldata _feeTiersIndices,
        IFeeTiersUtils.FeeTier[] calldata _feeTiers
    ) external;

    /**
     * @dev Updates groups volume multipliers
     * @param _groupIndices indices of groups to update
     * @param _groupVolumeMultipliers corresponding new volume multipliers (1e3)
     */
    function setGroupVolumeMultipliers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers
    ) external;

    /**
     * @dev Updates fee tiers
     * @param _feeTiersIndices indices of fee tiers to update
     * @param _feeTiers new fee tiers values (feeMultiplier, pointsThreshold)
     */
    function setFeeTiers(uint256[] calldata _feeTiersIndices, IFeeTiersUtils.FeeTier[] calldata _feeTiers) external;

    /**
     * @dev Increases daily points from a new trade, re-calculate trailing points, and cache daily fee tier for a trader.
     * @param _trader trader address
     * @param _volumeUsd trading volume in USD (1e18)
     * @param _pairIndex pair index
     */
    function updateTraderPoints(address _trader, uint256 _volumeUsd, uint256 _pairIndex) external;

    /**
     * @dev Returns fee amount after applying the trader's active fee tier multiplier
     * @param _trader address of trader
     * @param _normalFeeAmountCollateral base fee amount (collateral precision)
     */
    function calculateFeeAmount(address _trader, uint256 _normalFeeAmountCollateral) external view returns (uint256);

    /**
     * Returns the current number of active fee tiers
     */
    function getFeeTiersCount() external view returns (uint256);

    /**
     * @dev Returns a fee tier's details (feeMultiplier, pointsThreshold)
     * @param _feeTierIndex fee tier index
     */
    function getFeeTier(uint256 _feeTierIndex) external view returns (IFeeTiersUtils.FeeTier memory);

    /**
     * @dev Returns a group's volume multiplier
     * @param _groupIndex group index (pairs storage fee index)
     */
    function getGroupVolumeMultiplier(uint256 _groupIndex) external view returns (uint256);

    /**
     * @dev Returns a trader's info (lastDayUpdated, trailingPoints)
     * @param _trader trader address
     */
    function getFeeTiersTraderInfo(address _trader) external view returns (IFeeTiersUtils.TraderInfo memory);

    /**
     * @dev Returns a trader's daily fee tier info (feeMultiplierCache, points)
     * @param _trader trader address
     * @param _day day
     */
    function getFeeTiersTraderDailyInfo(
        address _trader,
        uint32 _day
    ) external view returns (IFeeTiersUtils.TraderDailyInfo memory);

    /**
     * @dev Emitted when group volume multipliers are updated
     * @param groupIndices indices of updated groups
     * @param groupVolumeMultipliers new corresponding volume multipliers (1e3)
     */
    event GroupVolumeMultipliersUpdated(uint256[] groupIndices, uint256[] groupVolumeMultipliers);

    /**
     * @dev Emitted when fee tiers are updated
     * @param feeTiersIndices indices of updated fee tiers
     * @param feeTiers new corresponding fee tiers values (feeMultiplier, pointsThreshold)
     */
    event FeeTiersUpdated(uint256[] feeTiersIndices, IFeeTiersUtils.FeeTier[] feeTiers);

    /**
     * @dev Emitted when a trader's daily points are updated
     * @param trader trader address
     * @param day day
     * @param points points added (1e18 precision)
     */
    event TraderDailyPointsIncreased(address indexed trader, uint32 indexed day, uint224 points);

    /**
     * @dev Emitted when a trader info is updated for the first time
     * @param trader address of trader
     * @param day day
     */
    event TraderInfoFirstUpdate(address indexed trader, uint32 day);

    /**
     * @dev Emitted when a trader's trailing points are updated
     * @param trader trader address
     * @param fromDay from day
     * @param toDay to day
     * @param expiredPoints expired points amount (1e18 precision)
     */
    event TraderTrailingPointsExpired(address indexed trader, uint32 fromDay, uint32 toDay, uint224 expiredPoints);

    /**
     * @dev Emitted when a trader's info is updated
     * @param trader address of trader
     * @param traderInfo new trader info value (lastDayUpdated, trailingPoints)
     */
    event TraderInfoUpdated(address indexed trader, IFeeTiersUtils.TraderInfo traderInfo);

    /**
     * @dev Emitted when a trader's cached fee multiplier is updated (this is the one used in fee calculations)
     * @param trader address of trader
     * @param day day
     * @param feeMultiplier new fee multiplier (1e3 precision)
     */
    event TraderFeeMultiplierCached(address indexed trader, uint32 indexed day, uint32 feeMultiplier);

    error WrongFeeTier();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IPairsStorage.sol";

/**
 * @dev Interface for GNSPairsStorage facet (inherits types and also contains functions, events, and custom errors)
 */
interface IPairsStorageUtils is IPairsStorage {
    /**
     * @dev Adds new trading pairs
     * @param _pairs pairs to add
     */
    function addPairs(Pair[] calldata _pairs) external;

    /**
     * @dev Updates trading pairs
     * @param _pairIndices indices of pairs
     * @param _pairs new pairs values
     */
    function updatePairs(uint256[] calldata _pairIndices, Pair[] calldata _pairs) external;

    /**
     * @dev Adds new pair groups
     * @param _groups groups to add
     */
    function addGroups(Group[] calldata _groups) external;

    /**
     * @dev Updates pair groups
     * @param _ids indices of groups
     * @param _groups new groups values
     */
    function updateGroups(uint256[] calldata _ids, Group[] calldata _groups) external;

    /**
     * @dev Adds new pair fees groups
     * @param _fees fees to add
     */
    function addFees(Fee[] calldata _fees) external;

    /**
     * @dev Updates pair fees groups
     * @param _ids indices of fees
     * @param _fees new fees values
     */
    function updateFees(uint256[] calldata _ids, Fee[] calldata _fees) external;

    /**
     * @dev Updates pair custom max leverages (if unset group default is used)
     * @param _indices indices of pairs
     * @param _values new custom max leverages
     */
    function setPairCustomMaxLeverages(uint256[] calldata _indices, uint256[] calldata _values) external;

    /**
     * @dev Returns data needed by price aggregator when doing a new price request
     * @param _pairIndex index of pair
     * @return from pair from (eg. BTC)
     * @return to pair to (eg. USD)
     */
    function pairJob(uint256 _pairIndex) external view returns (string memory from, string memory to);

    /**
     * @dev Returns whether a pair is listed
     * @param _from pair from (eg. BTC)
     * @param _to pair to (eg. USD)
     */
    function isPairListed(string calldata _from, string calldata _to) external view returns (bool);

    /**
     * @dev Returns whether a pair index is listed
     * @param _pairIndex index of pair to check
     */
    function isPairIndexListed(uint256 _pairIndex) external view returns (bool);

    /**
     * @dev Returns a pair's details
     * @param _index index of pair
     */
    function pairs(uint256 _index) external view returns (Pair memory);

    /**
     * @dev Returns number of listed pairs
     */
    function pairsCount() external view returns (uint256);

    /**
     * @dev Returns a pair's spread % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairSpreadP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's min leverage
     * @param _pairIndex index of pair
     */
    function pairMinLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's open fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairOpenFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's close fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairCloseFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's oracle fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairOracleFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's trigger order fee % (1e10 precision)
     * @param _pairIndex index of pair
     */
    function pairTriggerOrderFeeP(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's min leverage position in USD (1e18 precision)
     * @param _pairIndex index of pair
     */
    function pairMinPositionSizeUsd(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's minimum trading fee in USD (1e18 precision)
     * @param _pairIndex index of pair
     */
    function pairMinFeeUsd(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a group details
     * @param _index index of group
     */
    function groups(uint256 _index) external view returns (Group memory);

    /**
     * @dev Returns number of listed groups
     */
    function groupsCount() external view returns (uint256);

    /**
     * @dev Returns a fee group details
     * @param _index index of fee group
     */
    function fees(uint256 _index) external view returns (Fee memory);

    /**
     * @dev Returns number of listed fee groups
     */
    function feesCount() external view returns (uint256);

    /**
     * @dev Returns a pair's details, group and fee group
     * @param _index index of pair
     */
    function pairsBackend(uint256 _index) external view returns (Pair memory, Group memory, Fee memory);

    /**
     * @dev Returns a pair's active max leverage (custom if set, otherwise group default)
     * @param _pairIndex index of pair
     */
    function pairMaxLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns a pair's custom max leverage (0 if not set)
     * @param _pairIndex index of pair
     */
    function pairCustomMaxLeverage(uint256 _pairIndex) external view returns (uint256);

    /**
     * @dev Returns all listed pairs custom max leverages
     */
    function getAllPairsRestrictedMaxLeverage() external view returns (uint256[] memory);

    /**
     * @dev Emitted when a new pair is listed
     * @param index index of pair
     * @param from pair from (eg. BTC)
     * @param to pair to (eg. USD)
     */
    event PairAdded(uint256 index, string from, string to);

    /**
     * @dev Emitted when a pair is updated
     * @param index index of pair
     */
    event PairUpdated(uint256 index);

    /**
     * @dev Emitted when a pair's custom max leverage is updated
     * @param index index of pair
     * @param maxLeverage new max leverage
     */
    event PairCustomMaxLeverageUpdated(uint256 indexed index, uint256 maxLeverage);

    /**
     * @dev Emitted when a new group is added
     * @param index index of group
     * @param name name of group
     */
    event GroupAdded(uint256 index, string name);

    /**
     * @dev Emitted when a group is updated
     * @param index index of group
     */
    event GroupUpdated(uint256 index);

    /**
     * @dev Emitted when a new fee group is added
     * @param index index of fee group
     * @param name name of fee group
     */
    event FeeAdded(uint256 index, string name);

    /**
     * @dev Emitted when a fee group is updated
     * @param index index of fee group
     */
    event FeeUpdated(uint256 index);

    error PairNotListed();
    error GroupNotListed();
    error FeeNotListed();
    error WrongLeverages();
    error WrongFees();
    error PairAlreadyListed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Chainlink} from "@chainlink/contracts/src/v0.8/Chainlink.sol";

import "../types/IPriceAggregator.sol";
import "../types/ITradingStorage.sol";
import "../types/ITradingCallbacks.sol";

/**
 * @dev Interface for GNSPriceAggregator facet (inherits types and also contains functions, events, and custom errors)
 */
interface IPriceAggregatorUtils is IPriceAggregator {
    /**
     * @dev Initializes price aggregator facet
     * @param _linkToken LINK token address
     * @param _linkUsdPriceFeed LINK/USD price feed address
     * @param _twapInterval TWAP interval (seconds)
     * @param _minAnswers answers count at which a trade is executed with median
     * @param _oracles chainlink oracle addresses
     * @param _jobIds chainlink job ids (market/lookback)
     * @param _collateralIndices collateral indices
     * @param _gnsCollateralLiquidityPools corresponding GNS/collateral liquidity pool values
     * @param _collateralUsdPriceFeeds corresponding collateral/USD chainlink price feeds
     */
    function initializePriceAggregator(
        address _linkToken,
        IChainlinkFeed _linkUsdPriceFeed,
        uint24 _twapInterval,
        uint8 _minAnswers,
        address[] memory _oracles,
        bytes32[2] memory _jobIds,
        uint8[] calldata _collateralIndices,
        LiquidityPoolInput[] memory _gnsCollateralLiquidityPools,
        IChainlinkFeed[] memory _collateralUsdPriceFeeds
    ) external;

    /**
     * @dev Updates LINK/USD chainlink price feed
     * @param _value new value
     */
    function updateLinkUsdPriceFeed(IChainlinkFeed _value) external;

    /**
     * @dev Updates collateral/USD chainlink price feed
     * @param _collateralIndex collateral index
     * @param _value new value
     */
    function updateCollateralUsdPriceFeed(uint8 _collateralIndex, IChainlinkFeed _value) external;

    /**
     * @dev Updates collateral/GNS liquidity pool
     * @param _collateralIndex collateral index
     * @param _liquidityPoolInput new values
     */
    function updateCollateralGnsLiquidityPool(
        uint8 _collateralIndex,
        LiquidityPoolInput calldata _liquidityPoolInput
    ) external;

    /**
     * @dev Updates TWAP interval
     * @param _twapInterval new value (seconds)
     */
    function updateTwapInterval(uint24 _twapInterval) external;

    /**
     * @dev Updates minimum answers count
     * @param _value new value
     */
    function updateMinAnswers(uint8 _value) external;

    /**
     * @dev Adds an oracle
     * @param _a new value
     */
    function addOracle(address _a) external;

    /**
     * @dev Replaces an oracle
     * @param _index oracle index
     * @param _a new value
     */
    function replaceOracle(uint256 _index, address _a) external;

    /**
     * @dev Removes an oracle
     * @param _index oracle index
     */
    function removeOracle(uint256 _index) external;

    /**
     * @dev Updates market job id
     * @param _jobId new value
     */
    function setMarketJobId(bytes32 _jobId) external;

    /**
     * @dev Updates lookback job id
     * @param _jobId new value
     */
    function setLimitJobId(bytes32 _jobId) external;

    /**
     * @dev Requests price from oracles
     * @param _collateralIndex collateral index
     * @param _pairIndex pair index
     * @param _orderId order id
     * @param _orderType order type
     * @param _positionSizeCollateral position size (collateral precision)
     * @param _fromBlock block number from which to start fetching prices (for lookbacks)
     */
    function getPrice(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        ITradingStorage.Id memory _orderId,
        ITradingStorage.PendingOrderType _orderType,
        uint256 _positionSizeCollateral,
        uint256 _fromBlock
    ) external;

    /**
     * @dev Fulfills price request, called by chainlink oracles
     * @param _requestId request id
     * @param _priceData price data
     */
    function fulfill(bytes32 _requestId, uint256 _priceData) external;

    /**
     * @dev Claims back LINK tokens, called by gov fund
     */
    function claimBackLink() external;

    /**
     * @dev Returns LINK fee for price request
     * @param _collateralIndex collateral index
     * @param _pairIndex pair index
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     */
    function getLinkFee(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _positionSizeCollateral
    ) external view returns (uint256);

    /**
     * @dev Returns collateral/USD price
     * @param _collateralIndex index of collateral
     */
    function getCollateralPriceUsd(uint8 _collateralIndex) external view returns (uint256);

    /**
     * @dev Returns USD normalized value from collateral value
     * @param _collateralIndex index of collateral
     * @param _collateralValue collateral value (collateral precision)
     */
    function getUsdNormalizedValue(uint8 _collateralIndex, uint256 _collateralValue) external view returns (uint256);

    /**
     * @dev Returns collateral value (collateral precision) from USD normalized value
     * @param _collateralIndex index of collateral
     * @param _normalizedValue normalized value (1e18 USD)
     */
    function getCollateralFromUsdNormalizedValue(
        uint8 _collateralIndex,
        uint256 _normalizedValue
    ) external view returns (uint256);

    /**
     * @dev Returns GNS/USD price based on GNS/collateral price
     * @param _collateralIndex index of collateral
     */
    function getGnsPriceUsd(uint8 _collateralIndex) external view returns (uint256);

    /**
     * @dev Returns GNS/USD price based on GNS/collateral price
     * @param _collateralIndex index of collateral
     * @param _gnsPriceCollateral GNS/collateral price (1e10)
     */
    function getGnsPriceUsd(uint8 _collateralIndex, uint256 _gnsPriceCollateral) external view returns (uint256);

    /**
     * @dev Returns GNS/collateral price
     * @param _collateralIndex index of collateral
     */
    function getGnsPriceCollateralIndex(uint8 _collateralIndex) external view returns (uint256);

    /**
     * @dev Returns GNS/collateral price
     * @param _collateral address of the collateral
     */
    function getGnsPriceCollateralAddress(address _collateral) external view returns (uint256);

    /**
     * @dev Returns the link/usd price feed address
     */
    function getLinkUsdPriceFeed() external view returns (IChainlinkFeed);

    /**
     * @dev Returns the twap interval in seconds
     */
    function getTwapInterval() external view returns (uint24);

    /**
     * @dev Returns the minimum answers to execute an order and take the median
     */
    function getMinAnswers() external view returns (uint8);

    /**
     * @dev Returns the market job id
     */
    function getMarketJobId() external view returns (bytes32);

    /**
     * @dev Returns the limit job id
     */
    function getLimitJobId() external view returns (bytes32);

    /**
     * @dev Returns a specific oracle
     * @param _index index of the oracle
     */
    function getOracle(uint256 _index) external view returns (address);

    /**
     * @dev Returns all oracles
     */
    function getOracles() external view returns (address[] memory);

    /**
     * @dev Returns collateral/gns liquidity pool info
     * @param _collateralIndex index of collateral
     */
    function getCollateralGnsLiquidityPool(uint8 _collateralIndex) external view returns (LiquidityPoolInfo memory);

    /**
     * @dev Returns collateral/usd chainlink price feed
     * @param _collateralIndex index of collateral
     */
    function getCollateralUsdPriceFeed(uint8 _collateralIndex) external view returns (IChainlinkFeed);

    /**
     * @dev Returns order data
     * @param _requestId index of collateral
     */
    function getPriceAggregatorOrder(bytes32 _requestId) external view returns (Order memory);

    /**
     * @dev Returns order data
     * @param _orderId order id
     */
    function getPriceAggregatorOrderAnswers(
        ITradingStorage.Id calldata _orderId
    ) external view returns (OrderAnswer[] memory);

    /**
     * @dev Returns chainlink token address
     */
    function getChainlinkToken() external view returns (address);

    /**
     * @dev Returns requestCount (used by ChainlinkClientUtils)
     */
    function getRequestCount() external view returns (uint256);

    /**
     * @dev Returns pendingRequests mapping entry (used by ChainlinkClientUtils)
     */
    function getPendingRequest(bytes32 _id) external view returns (address);

    /**
     * @dev Emitted when LINK/USD price feed is updated
     * @param value new value
     */
    event LinkUsdPriceFeedUpdated(address value);

    /**
     * @dev Emitted when collateral/USD price feed is updated
     * @param collateralIndex collateral index
     * @param value new value
     */
    event CollateralUsdPriceFeedUpdated(uint8 collateralIndex, address value);

    /**
     * @dev Emitted when collateral/GNS Uniswap V3 pool is updated
     * @param collateralIndex collateral index
     * @param newValue new value
     */
    event CollateralGnsLiquidityPoolUpdated(uint8 collateralIndex, LiquidityPoolInfo newValue);

    /**
     * @dev Emitted when TWAP interval is updated
     * @param newValue new value
     */
    event TwapIntervalUpdated(uint32 newValue);

    /**
     * @dev Emitted when minimum answers count is updated
     * @param value new value
     */
    event MinAnswersUpdated(uint8 value);

    /**
     * @dev Emitted when an oracle is added
     * @param index new oracle index
     * @param value value
     */
    event OracleAdded(uint256 index, address value);

    /**
     * @dev Emitted when an oracle is replaced
     * @param index oracle index
     * @param oldOracle old value
     * @param newOracle new value
     */
    event OracleReplaced(uint256 index, address oldOracle, address newOracle);

    /**
     * @dev Emitted when an oracle is removed
     * @param index oracle index
     * @param oldOracle old value
     */
    event OracleRemoved(uint256 index, address oldOracle);

    /**
     * @dev Emitted when market job id is updated
     * @param index index
     * @param jobId new value
     */
    event JobIdUpdated(uint256 index, bytes32 jobId);

    /**
     * @dev Emitted when a chainlink request is created
     * @param request link request details
     */
    event LinkRequestCreated(Chainlink.Request request);

    /**
     * @dev Emitted when a price is requested to the oracles
     * @param collateralIndex collateral index
     * @param pendingOrderId pending order id
     * @param orderType order type (market open/market close/limit open/stop open/etc.)
     * @param pairIndex trading pair index
     * @param job chainlink job id (market/lookback)
     * @param nodesCount amount of nodes to fetch prices from
     * @param linkFeePerNode link fee distributed per node (1e18 precision)
     * @param fromBlock block number from which to start fetching prices (for lookbacks)
     * @param isLookback true if lookback
     */
    event PriceRequested(
        uint8 collateralIndex,
        ITradingStorage.Id pendingOrderId,
        ITradingStorage.PendingOrderType indexed orderType,
        uint256 indexed pairIndex,
        bytes32 indexed job,
        uint256 nodesCount,
        uint256 linkFeePerNode,
        uint256 fromBlock,
        bool isLookback
    );

    /**
     * @dev Emitted when a trading callback is called from the price aggregator
     * @param a aggregator answer data
     * @param orderType order type
     */
    event TradingCallbackExecuted(ITradingCallbacks.AggregatorAnswer a, ITradingStorage.PendingOrderType orderType);

    /**
     * @dev Emitted when a price is received from the oracles
     * @param orderId pending order id
     * @param pairIndex trading pair index
     * @param request chainlink request id
     * @param priceData OrderAnswer compressed into uint256
     * @param isLookback true if lookback
     * @param usedInMedian false if order already executed because min answers count was already reached
     */
    event PriceReceived(
        ITradingStorage.Id orderId,
        uint16 indexed pairIndex,
        bytes32 request,
        uint256 priceData,
        bool isLookback,
        bool usedInMedian
    );

    /**
     * @dev Emitted when LINK tokens are claimed back by gov fund
     * @param amountLink amount of LINK tokens claimed back
     */
    event LinkClaimedBack(uint256 amountLink);

    error TransferAndCallToOracleFailed();
    error SourceNotOracleOfRequest();
    error RequestAlreadyPending();
    error OracleAlreadyListed();
    error InvalidCandle();
    error WrongCollateralUsdDecimals();
    error InvalidPoolType();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IPriceImpact.sol";

/**
 * @dev Interface for GNSPriceImpact facet (inherits types and also contains functions, events, and custom errors)
 */
interface IPriceImpactUtils is IPriceImpact {
    /**
     * @dev Initializes price impact facet
     * @param _windowsDuration windows duration (seconds)
     * @param _windowsCount windows count
     */
    function initializePriceImpact(uint48 _windowsDuration, uint48 _windowsCount) external;

    /**
     * @dev Updates price impact windows count
     * @param _newWindowsCount new windows count
     */
    function setPriceImpactWindowsCount(uint48 _newWindowsCount) external;

    /**
     * @dev Updates price impact windows duration
     * @param _newWindowsDuration new windows duration (seconds)
     */
    function setPriceImpactWindowsDuration(uint48 _newWindowsDuration) external;

    /**
     * @dev Updates pairs 1% depths above and below
     * @param _indices indices of pairs
     * @param _depthsAboveUsd depths above the price in USD
     * @param _depthsBelowUsd depths below the price in USD
     */
    function setPairDepths(
        uint256[] calldata _indices,
        uint128[] calldata _depthsAboveUsd,
        uint128[] calldata _depthsBelowUsd
    ) external;

    /**
     * @dev Adds open interest to current window
     * @param _trader trader address
     * @param _index trade index
     * @param _oiDeltaCollateral open interest to add (collateral precision)
     */
    function addPriceImpactOpenInterest(address _trader, uint32 _index, uint256 _oiDeltaCollateral) external;

    /**
     * @dev Removes open interest from trade last OI update window
     * @param _trader trader address
     * @param _index trade index
     * @param _oiDeltaCollateral open interest to remove (collateral precision)
     */
    function removePriceImpactOpenInterest(address _trader, uint32 _index, uint256 _oiDeltaCollateral) external;

    /**
     * @dev Returns last OI delta in USD for a trade (1e18 precision)
     * @param _trader trader address
     * @param _index trade index
     */
    function getTradeLastWindowOiUsd(address _trader, uint32 _index) external view returns (uint128);

    /**
     * @dev Returns active open interest used in price impact calculation for a pair and side (long/short)
     * @param _pairIndex index of pair
     * @param _long true for long, false for short
     */
    function getPriceImpactOi(uint256 _pairIndex, bool _long) external view returns (uint256 activeOi);

    /**
     * @dev Returns price impact % (1e10 precision) and price after impact (1e10 precision) for a trade
     * @param _openPrice open price (1e10 precision)
     * @param _pairIndex index of pair
     * @param _long true for long, false for short
     * @param _tradeOpenInterestUsd open interest of trade in USD (1e18 precision)
     */
    function getTradePriceImpact(
        uint256 _openPrice,
        uint256 _pairIndex,
        bool _long,
        uint256 _tradeOpenInterestUsd
    ) external view returns (uint256 priceImpactP, uint256 priceAfterImpact);

    /**
     * @dev Returns a pair's depths above and below the price
     * @param _pairIndex index of pair
     */
    function getPairDepth(uint256 _pairIndex) external view returns (PairDepth memory);

    /**
     * @dev Returns current price impact windows settings
     */
    function getOiWindowsSettings() external view returns (OiWindowsSettings memory);

    /**
     * @dev Returns OI window details (long/short OI)
     * @param _windowsDuration windows duration (seconds)
     * @param _pairIndex index of pair
     * @param _windowId id of window
     */
    function getOiWindow(
        uint48 _windowsDuration,
        uint256 _pairIndex,
        uint256 _windowId
    ) external view returns (PairOi memory);

    /**
     * @dev Returns multiple OI windows details (long/short OI)
     * @param _windowsDuration windows duration (seconds)
     * @param _pairIndex index of pair
     * @param _windowIds ids of windows
     */
    function getOiWindows(
        uint48 _windowsDuration,
        uint256 _pairIndex,
        uint256[] calldata _windowIds
    ) external view returns (PairOi[] memory);

    /**
     * @dev Returns depths above and below the price for multiple pairs
     * @param _indices indices of pairs
     */
    function getPairDepths(uint256[] calldata _indices) external view returns (PairDepth[] memory);

    /**
     * @dev Returns trade price impact info struct
     * @param _trader trader address
     * @param _index trade index
     */
    function getTradePriceImpactInfo(
        address _trader,
        uint32 _index
    ) external view returns (IPriceImpact.TradePriceImpactInfo memory);

    /**
     * @dev Triggered when OiWindowsSettings is initialized (once)
     * @param windowsDuration duration of each window (seconds)
     * @param windowsCount number of windows
     */
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration, uint48 indexed windowsCount);

    /**
     * @dev Triggered when OiWindowsSettings.windowsCount is updated
     * @param windowsCount new number of windows
     */
    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);

    /**
     * @dev Triggered when OiWindowsSettings.windowsDuration is updated
     * @param windowsDuration new duration of each window (seconds)
     */
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OI is added to a window.
     * @param oiWindowUpdate OI window update details (windowsDuration, pairIndex, windowId, etc.)
     * @param isPartial true if partial add
     */
    event PriceImpactOpenInterestAdded(IPriceImpact.OiWindowUpdate oiWindowUpdate, bool isPartial);

    /**
     * @dev Triggered when OI is (tentatively) removed from a window.
     * @param oiWindowUpdate OI window update details (windowsDuration, pairIndex, windowId, etc.)
     * @param notOutdated true if the OI is not outdated
     */
    event PriceImpactOpenInterestRemoved(IPriceImpact.OiWindowUpdate oiWindowUpdate, bool notOutdated);

    /**
     * @dev Triggered when multiple pairs' OI are transferred to a new window (when updating windows duration).
     * @param pairsCount number of pairs
     * @param prevCurrentWindowId previous current window ID corresponding to previous window duration
     * @param prevEarliestWindowId previous earliest window ID corresponding to previous window duration
     * @param newCurrentWindowId new current window ID corresponding to new window duration
     */
    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );

    /**
     * @dev Triggered when a pair's OI is transferred to a new window.
     * @param pairIndex index of the pair
     * @param totalPairOi total USD long/short OI of the pair (1e18 precision)
     */
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, IPriceImpact.PairOi totalPairOi);

    /**
     * @dev Triggered when a pair's depth is updated.
     * @param pairIndex index of the pair
     * @param valueAboveUsd new USD depth above the price
     * @param valueBelowUsd new USD depth below the price
     */
    event OnePercentDepthUpdated(uint256 indexed pairIndex, uint128 valueAboveUsd, uint128 valueBelowUsd);

    error WrongWindowsDuration();
    error WrongWindowsCount();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IReferrals.sol";

/**
 * @dev Interface for GNSReferrals facet (inherits types and also contains functions, events, and custom errors)
 */
interface IReferralsUtils is IReferrals {
    /**
     *
     * @param _allyFeeP % of total referral fee going to ally
     * @param _startReferrerFeeP initial % of total referral fee earned when zero volume referred
     * @param _openFeeP % of open fee going to referral fee
     * @param _targetVolumeUsd usd opening volume to refer to reach 100% of referral fee
     */
    function initializeReferrals(
        uint256 _allyFeeP,
        uint256 _startReferrerFeeP,
        uint256 _openFeeP,
        uint256 _targetVolumeUsd
    ) external;

    /**
     * @dev Updates allyFeeP
     * @param _value new ally fee %
     */
    function updateAllyFeeP(uint256 _value) external;

    /**
     * @dev Updates startReferrerFeeP
     * @param _value new start referrer fee %
     */
    function updateStartReferrerFeeP(uint256 _value) external;

    /**
     * @dev Updates openFeeP
     * @param _value new open fee %
     */
    function updateReferralsOpenFeeP(uint256 _value) external;

    /**
     * @dev Updates targetVolumeUsd
     * @param _value new target volume in usd
     */
    function updateReferralsTargetVolumeUsd(uint256 _value) external;

    /**
     * @dev Whitelists ally addresses
     * @param _allies array of ally addresses
     */
    function whitelistAllies(address[] calldata _allies) external;

    /**
     * @dev Unwhitelists ally addresses
     * @param _allies array of ally addresses
     */
    function unwhitelistAllies(address[] calldata _allies) external;

    /**
     * @dev Whitelists referrer addresses
     * @param _referrers array of referrer addresses
     * @param _allies array of corresponding ally addresses
     */
    function whitelistReferrers(address[] calldata _referrers, address[] calldata _allies) external;

    /**
     * @dev Unwhitelists referrer addresses
     * @param _referrers array of referrer addresses
     */
    function unwhitelistReferrers(address[] calldata _referrers) external;

    /**
     * @dev Registers potential referrer for trader (only works if trader wasn't referred yet by someone else)
     * @param _trader trader address
     * @param _referral referrer address
     */
    function registerPotentialReferrer(address _trader, address _referral) external;

    /**
     * @dev Distributes ally and referrer rewards
     * @param _trader trader address
     * @param _volumeUsd trading volume in usd (1e18 precision)
     * @param _pairOpenFeeP pair open fee in % (1e10 precision)
     * @param _gnsPriceUsd token price in usd (1e10 precision)
     * @return USD value of distributed reward (referrer + ally)
     */
    function distributeReferralReward(
        address _trader,
        uint256 _volumeUsd, // 1e18
        uint256 _pairOpenFeeP,
        uint256 _gnsPriceUsd // 1e10
    ) external returns (uint256);

    /**
     * @dev Claims pending GNS ally rewards of caller
     */
    function claimAllyRewards() external;

    /**
     * @dev Claims pending GNS referrer rewards of caller
     */
    function claimReferrerRewards() external;

    /**
     * @dev Returns referrer fee % of trade position size
     * @param _pairOpenFeeP pair open fee in % (1e10 precision)
     * @param _volumeReferredUsd referred trading volume in usd (1e18 precision)
     */
    function getReferrerFeeP(uint256 _pairOpenFeeP, uint256 _volumeReferredUsd) external view returns (uint256);

    /**
     * @dev Returns last referrer of trader (whether referrer active or not)
     * @param _trader address of trader
     */
    function getTraderLastReferrer(address _trader) external view returns (address);

    /**
     * @dev Returns active referrer of trader
     * @param _trader address of trader
     */
    function getTraderActiveReferrer(address _trader) external view returns (address);

    /**
     * @dev Returns referrers referred by ally
     * @param _ally address of ally
     */
    function getReferrersReferred(address _ally) external view returns (address[] memory);

    /**
     * @dev Returns traders referred by referrer
     * @param _referrer address of referrer
     */
    function getTradersReferred(address _referrer) external view returns (address[] memory);

    /**
     * @dev Returns ally fee % of total referral fee
     */
    function getReferralsAllyFeeP() external view returns (uint256);

    /**
     * @dev Returns start referrer fee % of total referral fee when zero volume was referred
     */
    function getReferralsStartReferrerFeeP() external view returns (uint256);

    /**
     * @dev Returns % of opening fee going to referral fee
     */
    function getReferralsOpenFeeP() external view returns (uint256);

    /**
     * @dev Returns target volume in usd to reach 100% of referral fee
     */
    function getReferralsTargetVolumeUsd() external view returns (uint256);

    /**
     * @dev Returns ally details
     * @param _ally address of ally
     */
    function getAllyDetails(address _ally) external view returns (AllyDetails memory);

    /**
     * @dev Returns referrer details
     * @param _referrer address of referrer
     */
    function getReferrerDetails(address _referrer) external view returns (ReferrerDetails memory);

    /**
     * @dev Emitted when allyFeeP is updated
     * @param value new ally fee %
     */
    event UpdatedAllyFeeP(uint256 value);

    /**
     * @dev Emitted when startReferrerFeeP is updated
     * @param value new start referrer fee %
     */
    event UpdatedStartReferrerFeeP(uint256 value);

    /**
     * @dev Emitted when openFeeP is updated
     * @param value new open fee %
     */
    event UpdatedOpenFeeP(uint256 value);

    /**
     * @dev Emitted when targetVolumeUsd is updated
     * @param value new target volume in usd
     */
    event UpdatedTargetVolumeUsd(uint256 value);

    /**
     * @dev Emitted when an ally is whitelisted
     * @param ally ally address
     */
    event AllyWhitelisted(address indexed ally);

    /**
     * @dev Emitted when an ally is unwhitelisted
     * @param ally ally address
     */
    event AllyUnwhitelisted(address indexed ally);

    /**
     * @dev Emitted when a referrer is whitelisted
     * @param referrer referrer address
     * @param ally ally address
     */
    event ReferrerWhitelisted(address indexed referrer, address indexed ally);

    /**
     * @dev Emitted when a referrer is unwhitelisted
     * @param referrer referrer address
     */
    event ReferrerUnwhitelisted(address indexed referrer);

    /**
     * @dev Emitted when a trader has a new active referrer
     */
    event ReferrerRegistered(address indexed trader, address indexed referrer);

    /**
     * @dev Emitted when ally rewards are distributed for a trade
     * @param ally address of ally
     * @param trader address of trader
     * @param volumeUsd trade volume in usd (1e18 precision)
     * @param amountGns amount of GNS reward (1e18 precision)
     * @param amountValueUsd USD value of GNS reward (1e18 precision)
     */
    event AllyRewardDistributed(
        address indexed ally,
        address indexed trader,
        uint256 volumeUsd,
        uint256 amountGns,
        uint256 amountValueUsd
    );

    /**
     * @dev Emitted when referrer rewards are distributed for a trade
     * @param referrer address of referrer
     * @param trader address of trader
     * @param volumeUsd trade volume in usd (1e18 precision)
     * @param amountGns amount of GNS reward (1e18 precision)
     * @param amountValueUsd USD value of GNS reward (1e18 precision)
     */
    event ReferrerRewardDistributed(
        address indexed referrer,
        address indexed trader,
        uint256 volumeUsd,
        uint256 amountGns,
        uint256 amountValueUsd
    );

    /**
     * @dev Emitted when an ally claims his pending rewards
     * @param ally address of ally
     * @param amountGns GNS pending rewards amount
     */
    event AllyRewardsClaimed(address indexed ally, uint256 amountGns);

    /**
     * @dev Emitted when a referrer claims his pending rewards
     * @param referrer address of referrer
     * @param amountGns GNS pending rewards amount
     */
    event ReferrerRewardsClaimed(address indexed referrer, uint256 amountGns);

    error NoPendingRewards();
    error AlreadyActive();
    error AlreadyInactive();
    error AllyNotActive();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITradingCallbacks.sol";
import "../libraries/IUpdateLeverageUtils.sol";
import "../libraries/IUpdatePositionSizeUtils.sol";
import "../libraries/ITradingCommonUtils.sol";

/**
 * @dev Interface for GNSTradingCallbacks facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITradingCallbacksUtils is
    ITradingCallbacks,
    IUpdateLeverageUtils,
    IUpdatePositionSizeUtils,
    ITradingCommonUtils
{
    /**
     *
     * @param _vaultClosingFeeP the % of closing fee going to vault
     */
    function initializeCallbacks(uint8 _vaultClosingFeeP) external;

    /**
     * @dev Update the % of closing fee going to vault
     * @param _valueP the % of closing fee going to vault
     */
    function updateVaultClosingFeeP(uint8 _valueP) external;

    /**
     * @dev Claim the pending gov fees for all collaterals
     */
    function claimPendingGovFees() external;

    /**
     * @dev Executes a pending open trade market order
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function openTradeMarketCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending close trade market order
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function closeTradeMarketCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending open trigger order (for limit/stop orders)
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function executeTriggerOpenOrderCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending close trigger order (for tp/sl/liq orders)
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function executeTriggerCloseOrderCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending update leverage order
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function updateLeverageCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending increase position size market order
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function increasePositionSizeMarketCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending decrease position size market order
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function decreasePositionSizeMarketCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Returns the current vaultClosingFeeP value (%)
     */
    function getVaultClosingFeeP() external view returns (uint8);

    /**
     * @dev Returns the current pending gov fees for a collateral index (collateral precision)
     */
    function getPendingGovFeesCollateral(uint8 _collateralIndex) external view returns (uint256);

    /**
     * @dev Emitted when vaultClosingFeeP is updated
     * @param valueP the % of closing fee going to vault
     */
    event VaultClosingFeePUpdated(uint8 valueP);

    /**
     * @dev Emitted when gov fees are claimed for a collateral
     * @param collateralIndex the collateral index
     * @param amountCollateral the amount of fees claimed (collateral precision)
     */
    event PendingGovFeesClaimed(uint8 collateralIndex, uint256 amountCollateral);

    /**
     * @dev Emitted when a market order is executed (open/close)
     * @param orderId the id of the corrsponding pending market order
     * @param t the trade object
     * @param open true for a market open order, false for a market close order
     * @param price the price at which the trade was executed (1e10 precision)
     * @param priceImpactP the price impact in percentage (1e10 precision)
     * @param percentProfit the profit in percentage (1e10 precision)
     * @param amountSentToTrader the final amount of collateral sent to the trader
     * @param collateralPriceUsd the price of the collateral in USD (1e8 precision)
     */
    event MarketExecuted(
        ITradingStorage.Id orderId,
        ITradingStorage.Trade t,
        bool open,
        uint64 price,
        uint256 priceImpactP,
        int256 percentProfit, // before fees
        uint256 amountSentToTrader,
        uint256 collateralPriceUsd // 1e8
    );

    /**
     * @dev Emitted when a limit/stop order is executed
     * @param orderId the id of the corresponding pending trigger order
     * @param t the trade object
     * @param triggerCaller the address that triggered the limit order
     * @param orderType the type of the pending order
     * @param price the price at which the trade was executed (1e10 precision)
     * @param priceImpactP the price impact in percentage (1e10 precision)
     * @param percentProfit the profit in percentage (1e10 precision)
     * @param amountSentToTrader the final amount of collateral sent to the trader
     * @param collateralPriceUsd the price of the collateral in USD (1e8 precision)
     * @param exactExecution true if guaranteed execution was used
     */
    event LimitExecuted(
        ITradingStorage.Id orderId,
        ITradingStorage.Trade t,
        address indexed triggerCaller,
        ITradingStorage.PendingOrderType orderType,
        uint256 price,
        uint256 priceImpactP,
        int256 percentProfit,
        uint256 amountSentToTrader,
        uint256 collateralPriceUsd, // 1e8
        bool exactExecution
    );

    /**
     * @dev Emitted when a pending market open order is canceled
     * @param orderId order id of the pending market open order
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param cancelReason reason for the cancelation
     */
    event MarketOpenCanceled(
        ITradingStorage.Id orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        CancelReason cancelReason
    );

    /**
     * @dev Emitted when a pending market close order is canceled
     * @param orderId order id of the pending market close order
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param index index of the trade for trader
     * @param cancelReason reason for the cancelation
     */
    event MarketCloseCanceled(
        ITradingStorage.Id orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        CancelReason cancelReason
    );

    /**
     * @dev Emitted when a pending trigger order is canceled
     * @param orderId order id of the pending trigger order
     * @param triggerCaller address of the trigger caller
     * @param orderType type of the pending trigger order
     * @param cancelReason reason for the cancelation
     */
    event TriggerOrderCanceled(
        ITradingStorage.Id orderId,
        address indexed triggerCaller,
        ITradingStorage.PendingOrderType orderType,
        CancelReason cancelReason
    );

    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event BorrowingFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for TradingCommonUtils library
 */
interface ITradingCommonUtils {
    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event GovFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event ReferralFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event GnsStakingFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event TriggerFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

    /**
     *
     * @param trader address of the trader
     * @param collateralIndex index of the collateral
     * @param amountCollateral amount charged (collateral precision)
     */
    event GTokenFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITradingInteractions.sol";
import "../types/ITradingStorage.sol";
import "../libraries/IUpdateLeverageUtils.sol";
import "../libraries/IUpdatePositionSizeUtils.sol";

/**
 * @dev Interface for GNSTradingInteractions facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITradingInteractionsUtils is ITradingInteractions, IUpdateLeverageUtils, IUpdatePositionSizeUtils {
    /**
     * @dev Initializes the trading facet
     * @param _marketOrdersTimeoutBlocks The number of blocks after which a market order is considered timed out
     */
    function initializeTrading(uint16 _marketOrdersTimeoutBlocks, address[] memory _usersByPassTriggerLink) external;

    /**
     * @dev Updates marketOrdersTimeoutBlocks
     * @param _valueBlocks blocks after which a market order times out
     */
    function updateMarketOrdersTimeoutBlocks(uint16 _valueBlocks) external;

    /**
     * @dev Updates the users that can bypass the link cost of triggerOrder
     * @param _users array of addresses that can bypass the link cost of triggerOrder
     * @param _shouldByPass whether each user should bypass the link cost
     */
    function updateByPassTriggerLink(address[] memory _users, bool[] memory _shouldByPass) external;

    /**
     * @dev Sets _delegate as the new delegate of caller (can call delegatedAction)
     * @param _delegate the new delegate address
     */
    function setTradingDelegate(address _delegate) external;

    /**
     * @dev Removes the delegate of caller (can't call delegatedAction)
     */
    function removeTradingDelegate() external;

    /**
     * @dev Caller executes a trading action on behalf of _trader using delegatecall
     * @param _trader the trader address to execute the trading action for
     * @param _callData the data to be executed (open trade/close trade, etc.)
     */
    function delegatedTradingAction(address _trader, bytes calldata _callData) external returns (bytes memory);

    /**
     * @dev Opens a new trade/limit order/stop order
     * @param _trade the trade to be opened
     * @param _maxSlippageP the maximum allowed slippage % when open the trade (1e3 precision)
     * @param _referrer the address of the referrer (can only be set once for a trader)
     */
    function openTrade(ITradingStorage.Trade memory _trade, uint16 _maxSlippageP, address _referrer) external;

    /**
     * @dev Wraps native token and opens a new trade/limit order/stop order
     * @param _trade the trade to be opened
     * @param _maxSlippageP the maximum allowed slippage % when open the trade (1e3 precision)
     * @param _referrer the address of the referrer (can only be set once for a trader)
     */
    function openTradeNative(
        ITradingStorage.Trade memory _trade,
        uint16 _maxSlippageP,
        address _referrer
    ) external payable;

    /**
     * @dev Closes an open trade (market order) for caller
     * @param _index the index of the trade of caller
     */
    function closeTradeMarket(uint32 _index) external;

    /**
     * @dev Updates an existing limit/stop order for caller
     * @param _index index of limit/stop order of caller
     * @param _triggerPrice new trigger price of limit/stop order (1e10 precision)
     * @param _tp new tp of limit/stop order (1e10 precision)
     * @param _sl new sl of limit/stop order (1e10 precision)
     * @param _maxSlippageP new max slippage % of limit/stop order (1e3 precision)
     */
    function updateOpenOrder(
        uint32 _index,
        uint64 _triggerPrice,
        uint64 _tp,
        uint64 _sl,
        uint16 _maxSlippageP
    ) external;

    /**
     * @dev Cancels an open limit/stop order for caller
     * @param _index index of limit/stop order of caller
     */
    function cancelOpenOrder(uint32 _index) external;

    /**
     * @dev Updates the tp of an open trade for caller
     * @param _index index of open trade of caller
     * @param _newTp new tp of open trade (1e10 precision)
     */
    function updateTp(uint32 _index, uint64 _newTp) external;

    /**
     * @dev Updates the sl of an open trade for caller
     * @param _index index of open trade of caller
     * @param _newSl new sl of open trade (1e10 precision)
     */
    function updateSl(uint32 _index, uint64 _newSl) external;

    /**
     * @dev Initiates a new trigger order (for tp/sl/liq/limit/stop orders)
     * @param _packed the packed data of the trigger order (orderType, trader, index)
     */
    function triggerOrder(uint256 _packed) external;

    /**
     * @dev Safety function in case oracles don't answer in time, allows caller to cancel a pending order and if relevant claim back any stuck collateral
     * @dev Only allowed for MARKET_OPEN, MARKET_CLOSE, UPDATE_LEVERAGE, MARKET_PARTIAL_OPEN, and MARKET_PARTIAL_CLOSE orders
     * @param _orderIndex the id of the pending order to cancel
     */
    function cancelOrderAfterTimeout(uint32 _orderIndex) external;

    /**
     * @dev Update trade leverage
     * @param _index index of trade
     * @param _newLeverage new leverage (1e3)
     */
    function updateLeverage(uint32 _index, uint24 _newLeverage) external;

    /**
     * @dev Increase trade position size
     * @param _index index of trade
     * @param _collateralDelta collateral to add (collateral precision)
     * @param _leverageDelta partial trade leverage (1e3)
     * @param _expectedPrice expected price of execution (1e10 precision)
     * @param _maxSlippageP max slippage % (1e3)
     */
    function increasePositionSize(
        uint32 _index,
        uint120 _collateralDelta,
        uint24 _leverageDelta,
        uint64 _expectedPrice,
        uint16 _maxSlippageP
    ) external;

    /**
     * @dev Decrease trade position size
     * @param _index index of trade
     * @param _collateralDelta collateral to remove (collateral precision)
     * @param _leverageDelta leverage to reduce by (1e3)
     */
    function decreasePositionSize(uint32 _index, uint120 _collateralDelta, uint24 _leverageDelta) external;

    /**
     * @dev Returns the wrapped native token or address(0) if the current chain, or the wrapped token, is not supported.
     */
    function getWrappedNativeToken() external view returns (address);

    /**
     * @dev Returns true if the token is the wrapped native token for the current chain, where supported.
     * @param _token token address
     */
    function isWrappedNativeToken(address _token) external view returns (bool);

    /**
     * @dev Returns the address a trader delegates his trading actions to
     * @param _trader address of the trader
     */
    function getTradingDelegate(address _trader) external view returns (address);

    /**
     * @dev Returns the current marketOrdersTimeoutBlocks value
     */
    function getMarketOrdersTimeoutBlocks() external view returns (uint16);

    /**
     * @dev Returns whether a user bypasses trigger link costs
     * @param _user address of the user
     */
    function getByPassTriggerLink(address _user) external view returns (bool);

    /**
     * @dev Emitted when marketOrdersTimeoutBlocks is updated
     * @param newValueBlocks the new value of marketOrdersTimeoutBlocks
     */
    event MarketOrdersTimeoutBlocksUpdated(uint256 newValueBlocks);

    /**
     * @dev Emitted when a user is allowed/disallowed to bypass the link cost of triggerOrder
     * @param user address of the user
     * @param bypass whether the user can bypass the link cost of triggerOrder
     */
    event ByPassTriggerLinkUpdated(address indexed user, bool bypass);

    /**
     * @dev Emitted when a market order is initiated
     * @param orderId price aggregator order id of the pending market order
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param open whether the market order is for opening or closing a trade
     */
    event MarketOrderInitiated(ITradingStorage.Id orderId, address indexed trader, uint16 indexed pairIndex, bool open);

    /**
     * @dev Emitted when a new limit/stop order is placed
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param index index of the open limit order for caller
     */
    event OpenOrderPlaced(address indexed trader, uint16 indexed pairIndex, uint32 index);

    /**
     *
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param index index of the open limit/stop order for caller
     * @param newPrice new trigger price (1e10 precision)
     * @param newTp new tp (1e10 precision)
     * @param newSl new sl (1e10 precision)
     * @param maxSlippageP new max slippage % (1e3 precision)
     */
    event OpenLimitUpdated(
        address indexed trader,
        uint16 indexed pairIndex,
        uint32 index,
        uint64 newPrice,
        uint64 newTp,
        uint64 newSl,
        uint64 maxSlippageP
    );

    /**
     * @dev Emitted when a limit/stop order is canceled (collateral sent back to trader)
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param index index of the open limit/stop order for caller
     */
    event OpenLimitCanceled(address indexed trader, uint16 indexed pairIndex, uint32 index);

    /**
     * @dev Emitted when a trigger order is initiated (tp/sl/liq/limit/stop orders)
     * @param orderId price aggregator order id of the pending trigger order
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param byPassesLinkCost whether the caller bypasses the link cost
     */
    event TriggerOrderInitiated(
        ITradingStorage.Id orderId,
        address indexed trader,
        uint16 indexed pairIndex,
        bool byPassesLinkCost
    );

    /**
     * @dev Emitted when a pending market order is canceled due to timeout
     * @param pendingOrderId id of the pending order
     * @param pairIndex index of the trading pair
     */
    event ChainlinkCallbackTimeout(ITradingStorage.Id pendingOrderId, uint256 indexed pairIndex);

    /**
     * @dev Emitted when a pending market order is canceled due to timeout and new closeTradeMarket() call failed
     * @param trader address of the trader
     * @param pairIndex index of the trading pair
     * @param index index of the open trade for caller
     */
    event CouldNotCloseTrade(address indexed trader, uint16 indexed pairIndex, uint32 index);

    /**
     * @dev Emitted when a native token is wrapped
     * @param trader address of the trader
     * @param nativeTokenAmount amount of native token wrapped
     */
    event NativeTokenWrapped(address indexed trader, uint256 nativeTokenAmount);

    error NotWrappedNativeToken();
    error DelegateNotApproved();
    error PriceZero();
    error AboveExposureLimits();
    error CollateralNotActive();
    error PriceImpactTooHigh();
    error NoTrade();
    error NoOrder();
    error WrongOrderType();
    error AlreadyBeingMarketClosed();
    error ConflictingPendingOrder(ITradingStorage.PendingOrderType);
    error WrongLeverage();
    error WrongTp();
    error WrongSl();
    error WaitTimeout();
    error PendingTrigger();
    error NoSl();
    error NoTp();
    error NotYourOrder();
    error DelegatedActionNotAllowed();
    error InsufficientCollateral();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITradingStorage.sol";

/**
 * @dev Interface for GNSTradingStorage facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITradingStorageUtils is ITradingStorage {
    /**
     * @dev Initializes the trading storage facet
     * @param _gns address of the gns token
     * @param _gnsStaking address of the gns staking contract
     */
    function initializeTradingStorage(
        address _gns,
        address _gnsStaking,
        address[] memory _collaterals,
        address[] memory _gTokens
    ) external;

    /**
     * @dev Updates the trading activated state
     * @param _activated the new trading activated state
     */
    function updateTradingActivated(TradingActivated _activated) external;

    /**
     * @dev Adds a new supported collateral
     * @param _collateral the address of the collateral
     * @param _gToken the gToken contract of the collateral
     */
    function addCollateral(address _collateral, address _gToken) external;

    /**
     * @dev Toggles the active state of a supported collateral
     * @param _collateralIndex index of the collateral
     */
    function toggleCollateralActiveState(uint8 _collateralIndex) external;

    /**
     * @dev Updates the contracts of a supported collateral trading stack
     * @param _collateral address of the collateral
     * @param _gToken the gToken contract of the collateral
     */
    function updateGToken(address _collateral, address _gToken) external;

    /**
     * @dev Stores a new trade (trade/limit/stop)
     * @param _trade trade to be stored
     * @param _tradeInfo trade info to be stored
     */
    function storeTrade(Trade memory _trade, TradeInfo memory _tradeInfo) external returns (Trade memory);

    /**
     * @dev Updates an open trade collateral
     * @param _tradeId id of updated trade
     * @param _collateralAmount new collateral amount value (collateral precision)
     */
    function updateTradeCollateralAmount(Id memory _tradeId, uint120 _collateralAmount) external;

    /**
     * @dev Updates an open trade collateral
     * @param _tradeId id of updated trade
     * @param _collateralAmount new collateral amount value (collateral precision)
     * @param _leverage new leverage value
     * @param _openPrice new open price value
     */
    function updateTradePosition(
        Id memory _tradeId,
        uint120 _collateralAmount,
        uint24 _leverage,
        uint64 _openPrice
    ) external;

    /**
     * @dev Updates an open order details (limit/stop)
     * @param _tradeId id of updated trade
     * @param _openPrice new open price (1e10)
     * @param _tp new take profit price (1e10)
     * @param _sl new stop loss price (1e10)
     * @param _maxSlippageP new max slippage % value (1e3)
     */
    function updateOpenOrderDetails(
        Id memory _tradeId,
        uint64 _openPrice,
        uint64 _tp,
        uint64 _sl,
        uint16 _maxSlippageP
    ) external;

    /**
     * @dev Updates the take profit of an open trade
     * @param _tradeId the trade id
     * @param _newTp the new take profit (1e10 precision)
     */
    function updateTradeTp(Id memory _tradeId, uint64 _newTp) external;

    /**
     * @dev Updates the stop loss of an open trade
     * @param _tradeId the trade id
     * @param _newSl the new sl (1e10 precision)
     */
    function updateTradeSl(Id memory _tradeId, uint64 _newSl) external;

    /**
     * @dev Marks an open trade/limit/stop as closed
     * @param _tradeId the trade id
     */
    function closeTrade(Id memory _tradeId) external;

    /**
     * @dev Stores a new pending order
     * @param _pendingOrder the pending order to be stored
     */
    function storePendingOrder(PendingOrder memory _pendingOrder) external returns (PendingOrder memory);

    /**
     * @dev Closes a pending order
     * @param _orderId the id of the pending order to be closed
     */
    function closePendingOrder(Id memory _orderId) external;

    /**
     * @dev Returns collateral data by index
     * @param _index the index of the supported collateral
     */
    function getCollateral(uint8 _index) external view returns (Collateral memory);

    /**
     * @dev Returns whether can open new trades with a collateral
     * @param _index the index of the collateral to check
     */
    function isCollateralActive(uint8 _index) external view returns (bool);

    /**
     * @dev Returns whether a collateral has been listed
     * @param _index the index of the collateral to check
     */
    function isCollateralListed(uint8 _index) external view returns (bool);

    /**
     * @dev Returns the number of supported collaterals
     */
    function getCollateralsCount() external view returns (uint8);

    /**
     * @dev Returns the supported collaterals
     */
    function getCollaterals() external view returns (Collateral[] memory);

    /**
     * @dev Returns the index of a supported collateral
     * @param _collateral the address of the collateral
     */
    function getCollateralIndex(address _collateral) external view returns (uint8);

    /**
     * @dev Returns the trading activated state
     */
    function getTradingActivated() external view returns (TradingActivated);

    /**
     * @dev Returns whether a trader is stored in the traders array
     * @param _trader trader to check
     */
    function getTraderStored(address _trader) external view returns (bool);

    /**
     * @dev Returns all traders that have open trades using a pagination system
     * @param _offset start index in the traders array
     * @param _limit end index in the traders array
     */
    function getTraders(uint32 _offset, uint32 _limit) external view returns (address[] memory);

    /**
     * @dev Returns open trade/limit/stop order
     * @param _trader address of the trader
     * @param _index index of the trade for trader
     */
    function getTrade(address _trader, uint32 _index) external view returns (Trade memory);

    /**
     * @dev Returns all open trades/limit/stop orders for a trader
     * @param _trader address of the trader
     */
    function getTrades(address _trader) external view returns (Trade[] memory);

    /**
     * @dev Returns all trade/limit/stop orders using a pagination system
     * @param _offset index of first trade to return
     * @param _limit index of last trade to return
     */
    function getAllTrades(uint256 _offset, uint256 _limit) external view returns (Trade[] memory);

    /**
     * @dev Returns trade info of an open trade/limit/stop order
     * @param _trader address of the trader
     * @param _index index of the trade for trader
     */
    function getTradeInfo(address _trader, uint32 _index) external view returns (TradeInfo memory);

    /**
     * @dev Returns all trade infos of open trade/limit/stop orders for a trader
     * @param _trader address of the trader
     */
    function getTradeInfos(address _trader) external view returns (TradeInfo[] memory);

    /**
     * @dev Returns all trade infos of open trade/limit/stop orders using a pagination system
     * @param _offset index of first tradeInfo to return
     * @param _limit index of last tradeInfo to return
     */
    function getAllTradeInfos(uint256 _offset, uint256 _limit) external view returns (TradeInfo[] memory);

    /**
     * @dev Returns a pending ordeer
     * @param _orderId id of the pending order
     */
    function getPendingOrder(Id memory _orderId) external view returns (PendingOrder memory);

    /**
     * @dev Returns all pending orders for a trader
     * @param _user address of the trader
     */
    function getPendingOrders(address _user) external view returns (PendingOrder[] memory);

    /**
     * @dev Returns all pending orders using a pagination system
     * @param _offset index of first pendingOrder to return
     * @param _limit index of last pendingOrder to return
     */
    function getAllPendingOrders(uint256 _offset, uint256 _limit) external view returns (PendingOrder[] memory);

    /**
     * @dev Returns the block number of the pending order for a trade (0 = doesn't exist)
     * @param _tradeId id of the trade
     * @param _orderType pending order type to check
     */
    function getTradePendingOrderBlock(Id memory _tradeId, PendingOrderType _orderType) external view returns (uint256);

    /**
     * @dev Returns the counters of a trader (currentIndex / open count for trades/tradeInfos and pendingOrders mappings)
     * @param _trader address of the trader
     * @param _type the counter type (trade/pending order)
     */
    function getCounters(address _trader, CounterType _type) external view returns (Counter memory);

    /**
     * @dev Returns the address of the gToken for a collateral stack
     * @param _collateralIndex the index of the supported collateral
     */
    function getGToken(uint8 _collateralIndex) external view returns (address);

    /**
     * @dev Emitted when the trading activated state is updated
     * @param activated the new trading activated state
     */
    event TradingActivatedUpdated(TradingActivated activated);

    /**
     * @dev Emitted when a new supported collateral is added
     * @param collateral the address of the collateral
     * @param index the index of the supported collateral
     * @param gToken the gToken contract of the collateral
     */
    event CollateralAdded(address collateral, uint8 index, address gToken);

    /**
     * @dev Emitted when an existing supported collateral active state is updated
     * @param index the index of the supported collateral
     * @param isActive the new active state
     */
    event CollateralUpdated(uint8 indexed index, bool isActive);

    /**
     * @dev Emitted when an existing supported collateral is disabled (can still close trades but not open new ones)
     * @param index the index of the supported collateral
     */
    event CollateralDisabled(uint8 index);

    /**
     * @dev Emitted when the contracts of a supported collateral trading stack are updated
     * @param collateral the address of the collateral
     * @param index the index of the supported collateral
     * @param gToken the gToken contract of the collateral
     */
    event GTokenUpdated(address collateral, uint8 index, address gToken);

    /**
     * @dev Emitted when a new trade is stored
     * @param trade the trade stored
     * @param tradeInfo the trade info stored
     */
    event TradeStored(Trade trade, TradeInfo tradeInfo);

    /**
     * @dev Emitted when an open trade collateral is updated
     * @param tradeId id of the updated trade
     * @param collateralAmount new collateral value (collateral precision)
     */
    event TradeCollateralUpdated(Id tradeId, uint120 collateralAmount);

    /**
     * @dev Emitted when an open trade collateral is updated
     * @param tradeId id of the updated trade
     * @param collateralAmount new collateral value (collateral precision)
     * @param leverage new leverage value if present
     * @param openPrice new open price value if present
     */
    event TradePositionUpdated(
        Id tradeId,
        uint120 collateralAmount,
        uint24 leverage,
        uint64 openPrice,
        uint64 newTp,
        uint64 newSl
    );

    /**
     * @dev Emitted when an existing trade/limit order/stop order is updated
     * @param tradeId id of the updated trade
     * @param openPrice new open price value (1e10)
     * @param tp new take profit value (1e10)
     * @param sl new stop loss value (1e10)
     * @param maxSlippageP new max slippage % value (1e3)
     */
    event OpenOrderDetailsUpdated(Id tradeId, uint64 openPrice, uint64 tp, uint64 sl, uint16 maxSlippageP);

    /**
     * @dev Emitted when the take profit of an open trade is updated
     * @param tradeId the trade id
     * @param newTp the new take profit (1e10 precision)
     */
    event TradeTpUpdated(Id tradeId, uint64 newTp);

    /**
     * @dev Emitted when the stop loss of an open trade is updated
     * @param tradeId the trade id
     * @param newSl the new sl (1e10 precision)
     */
    event TradeSlUpdated(Id tradeId, uint64 newSl);

    /**
     * @dev Emitted when an open trade is closed
     * @param tradeId the trade id
     */
    event TradeClosed(Id tradeId);

    /**
     * @dev Emitted when a new pending order is stored
     * @param pendingOrder the pending order stored
     */
    event PendingOrderStored(PendingOrder pendingOrder);

    /**
     * @dev Emitted when a pending order is closed
     * @param orderId the id of the pending order closed
     */
    event PendingOrderClosed(Id orderId);

    error MissingCollaterals();
    error CollateralAlreadyActive();
    error CollateralAlreadyDisabled();
    error TradePositionSizeZero();
    error TradeOpenPriceZero();
    error TradePairNotListed();
    error TradeTpInvalid();
    error TradeSlInvalid();
    error MaxSlippageZero();
    error TradeInfoCollateralPriceUsdZero();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITriggerRewards.sol";

/**
 * @dev Interface for GNSTriggerRewards facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITriggerRewardsUtils is ITriggerRewards {
    /**
     *
     * @dev Initializes parameters for trigger rewards facet
     * @param _timeoutBlocks blocks after which a trigger times out
     */
    function initializeTriggerRewards(uint16 _timeoutBlocks) external;

    /**
     *
     * @dev Updates the blocks after which a trigger times out
     * @param _timeoutBlocks blocks after which a trigger times out
     */
    function updateTriggerTimeoutBlocks(uint16 _timeoutBlocks) external;

    /**
     *
     * @dev Distributes GNS rewards to oracles for a specific trigger
     * @param _rewardGns total GNS reward to be distributed among oracles
     */
    function distributeTriggerReward(uint256 _rewardGns) external;

    /**
     * @dev Claims pending GNS trigger rewards for the caller
     * @param _oracle address of the oracle
     */
    function claimPendingTriggerRewards(address _oracle) external;

    /**
     *
     * @dev Returns current triggerTimeoutBlocks value
     */
    function getTriggerTimeoutBlocks() external view returns (uint16);

    /**
     *
     * @dev Checks if an order is active (exists and has not timed out)
     * @param _orderBlock block number of the order
     */
    function hasActiveOrder(uint256 _orderBlock) external view returns (bool);

    /**
     *
     * @dev Returns the pending GNS trigger rewards for an oracle
     * @param _oracle address of the oracle
     */
    function getTriggerPendingRewardsGns(address _oracle) external view returns (uint256);

    /**
     *
     * @dev Emitted when timeoutBlocks is updated
     * @param timeoutBlocks blocks after which a trigger times out
     */
    event TriggerTimeoutBlocksUpdated(uint16 timeoutBlocks);

    /**
     *
     * @dev Emitted when trigger rewards are distributed for a specific order
     * @param rewardsPerOracleGns reward in GNS distributed per oracle
     * @param oraclesCount number of oracles rewarded
     */
    event TriggerRewarded(uint256 rewardsPerOracleGns, uint256 oraclesCount);

    /**
     *
     * @dev Emitted when pending GNS trigger rewards are claimed by an oracle
     * @param oracle address of the oracle
     * @param rewardsGns GNS rewards claimed
     */
    event TriggerRewardsClaimed(address oracle, uint256 rewardsGns);

    error TimeoutBlocksZero();
    error NoPendingTriggerRewards();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IUpdateLeverage.sol";
import "../types/ITradingStorage.sol";
import "../types/ITradingCallbacks.sol";

/**
 * @dev Interface for leverage updates
 */
interface IUpdateLeverageUtils is IUpdateLeverage {
    /**
     * @param orderId request order id
     * @param trader address of trader
     * @param pairIndex index of pair
     * @param index index of trade
     * @param isIncrease true if increase leverage, false if decrease
     * @param newLeverage new leverage value (1e3)
     */
    event LeverageUpdateInitiated(
        ITradingStorage.Id orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool isIncrease,
        uint256 newLeverage
    );

    /**
     * @param orderId request order id
     * @param isIncrease true if leverage increased, false if decreased
     * @param cancelReason cancel reason (executed if none)
     * @param collateralIndex collateral index
     * @param trader address of trader
     * @param pairIndex index of pair
     * @param index index of trade
     * @param marketPrice current market price (1e10)
     * @param collateralDelta collateral delta (collateral precision)
     * @param values useful values (new collateral, new leverage, liq price, gov fee collateral)
     */
    event LeverageUpdateExecuted(
        ITradingStorage.Id orderId,
        bool isIncrease,
        ITradingCallbacks.CancelReason cancelReason,
        uint8 indexed collateralIndex,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 marketPrice,
        uint256 collateralDelta,
        IUpdateLeverage.UpdateLeverageValues values
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IUpdatePositionSize.sol";
import "../types/ITradingStorage.sol";
import "../types/ITradingCallbacks.sol";

/**
 * @dev Interface for position size updates
 */
interface IUpdatePositionSizeUtils is IUpdatePositionSize {
    /**
     * @param orderId request order id
     * @param trader address of the trader
     * @param pairIndex index of the pair
     * @param index index of user trades
     * @param isIncrease true if increase position size, false if decrease
     * @param collateralDelta collateral delta (collateral precision)
     * @param leverageDelta leverage delta (1e3)
     */
    event PositionSizeUpdateInitiated(
        ITradingStorage.Id orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool isIncrease,
        uint256 collateralDelta,
        uint256 leverageDelta
    );

    /**
     * @param orderId request order id
     * @param cancelReason cancel reason if canceled or none if executed
     * @param collateralIndex collateral index
     * @param trader address of trader
     * @param pairIndex index of pair
     * @param index index of trade
     * @param marketPrice market price (1e10)
     * @param collateralDelta collateral delta (collateral precision)
     * @param leverageDelta leverage delta (1e3)
     * @param values important values (new open price, new leverage, new collateral, etc.)
     */
    event PositionSizeIncreaseExecuted(
        ITradingStorage.Id orderId,
        ITradingCallbacks.CancelReason cancelReason,
        uint8 indexed collateralIndex,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 marketPrice,
        uint256 collateralDelta,
        uint256 leverageDelta,
        IUpdatePositionSize.IncreasePositionSizeValues values
    );

    /**
     * @param orderId request order id
     * @param cancelReason cancel reason if canceled or none if executed
     * @param collateralIndex collateral index
     * @param trader address of trader
     * @param pairIndex index of pair
     * @param index index of trade
     * @param marketPrice market price (1e10)
     * @param collateralDelta collateral delta (collateral precision)
     * @param leverageDelta leverage delta (1e3)
     * @param values important values (pnl, new leverage, new collateral, etc.)
     */
    event PositionSizeDecreaseExecuted(
        ITradingStorage.Id orderId,
        ITradingCallbacks.CancelReason cancelReason,
        uint8 indexed collateralIndex,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 marketPrice,
        uint256 collateralDelta,
        uint256 leverageDelta,
        IUpdatePositionSize.DecreasePositionSizeValues values
    );

    error InvalidIncreasePositionSizeInput();
    error InvalidDecreasePositionSizeInput();
    error NewPositionSizeSmaller();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for BlockManager_Mock contract (test helper)
 */
interface IBlockManager_Mock {
    function getBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSAddressStore facet
 */
interface IAddressStore {
    enum Role {
        ROLES_MANAGER, // timelock
        GOV,
        MANAGER
    }

    struct Addresses {
        address gns;
        address gnsStaking;
    }

    struct AddressStore {
        uint256 __deprecated; // previously globalAddresses (gns token only, 1 slot)
        mapping(address => mapping(Role => bool)) accessControl;
        Addresses globalAddresses;
        uint256[8] __gap1; // gap for global addresses
        // insert new storage here
        uint256[38] __gap2; // gap for rest of diamond storage
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSBorrowingFees facet
 */
interface IBorrowingFees {
    struct BorrowingFeesStorage {
        mapping(uint8 => mapping(uint16 => BorrowingData)) pairs;
        mapping(uint8 => mapping(uint16 => BorrowingPairGroup[])) pairGroups;
        mapping(uint8 => mapping(uint16 => OpenInterest)) pairOis;
        mapping(uint8 => mapping(uint16 => BorrowingData)) groups;
        mapping(uint8 => mapping(uint16 => OpenInterest)) groupOis;
        mapping(uint8 => mapping(address => mapping(uint32 => BorrowingInitialAccFees))) initialAccFees;
        uint256[44] __gap;
    }

    struct BorrowingData {
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint48 feeExponent;
    }

    struct BorrowingPairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; // 1e10 (%)
        uint64 initialAccFeeShort; // 1e10 (%)
        uint64 prevGroupAccFeeLong; // 1e10 (%)
        uint64 prevGroupAccFeeShort; // 1e10 (%)
        uint64 pairAccFeeLong; // 1e10 (%)
        uint64 pairAccFeeShort; // 1e10 (%)
        uint64 __placeholder; // might be useful later
    }

    struct OpenInterest {
        uint72 long; // 1e10 (collateral)
        uint72 short; // 1e10 (collateral)
        uint72 max; // 1e10 (collateral)
        uint40 __placeholder; // might be useful later
    }

    struct BorrowingInitialAccFees {
        uint64 accPairFee; // 1e10 (%)
        uint64 accGroupFee; // 1e10 (%)
        uint48 block;
        uint80 __placeholder; // might be useful later
    }

    struct BorrowingPairParams {
        uint16 groupIndex;
        uint32 feePerBlock; // 1e10 (%)
        uint48 feeExponent;
        uint72 maxOi;
    }

    struct BorrowingGroupParams {
        uint32 feePerBlock; // 1e10 (%)
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }

    struct BorrowingFeeInput {
        uint8 collateralIndex;
        address trader;
        uint16 pairIndex;
        uint32 index;
        bool long;
        uint256 collateral; // 1e18 | 1e6 (collateral)
        uint256 leverage; // 1e3
    }

    struct LiqPriceInput {
        uint8 collateralIndex;
        address trader;
        uint16 pairIndex;
        uint32 index;
        uint64 openPrice; // 1e10
        bool long;
        uint256 collateral; // 1e18 | 1e6 (collateral)
        uint256 leverage; // 1e3
        bool useBorrowingFees;
    }

    struct PendingBorrowingAccFeesInput {
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint256 oiLong; // 1e18 | 1e6
        uint256 oiShort; // 1e18 | 1e6
        uint32 feePerBlock; // 1e10
        uint256 currentBlock;
        uint256 accLastUpdatedBlock;
        uint72 maxOi; // 1e10
        uint48 feeExponent;
        uint128 collateralPrecision;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @author Gains Network
 * @dev Based on EIP-2535: Diamonds (https://eips.ethereum.org/EIPS/eip-2535)
 * @dev Follows diamond-3 implementation (https://github.com/mudgen/diamond-3-hardhat/)
 * @dev Contains the types used in the diamond management contracts.
 */
interface IDiamondStorage {
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        address[47] __gap;
    }

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE,
        NOP
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSFeeTiers facet
 */
interface IFeeTiers {
    struct FeeTiersStorage {
        FeeTier[8] feeTiers;
        mapping(uint256 => uint256) groupVolumeMultipliers; // groupIndex (pairs storage) => multiplier (1e3)
        mapping(address => TraderInfo) traderInfos; // trader => TraderInfo
        mapping(address => mapping(uint32 => TraderDailyInfo)) traderDailyInfos; // trader => day => TraderDailyInfo
        uint256[39] __gap;
    }

    struct FeeTier {
        uint32 feeMultiplier; // 1e3
        uint32 pointsThreshold;
    }

    struct TraderInfo {
        uint32 lastDayUpdated;
        uint224 trailingPoints; // 1e18
    }

    struct TraderDailyInfo {
        uint32 feeMultiplierCache; // 1e3
        uint224 points; // 1e18
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSPairsStorage facet
 */
interface IPairsStorage {
    struct PairsStorage {
        mapping(uint256 => Pair) pairs;
        mapping(uint256 => Group) groups;
        mapping(uint256 => Fee) fees;
        mapping(string => mapping(string => bool)) isPairListed;
        mapping(uint256 => uint256) pairCustomMaxLeverage; // 0 decimal precision
        uint256 currentOrderId; /// @custom:deprecated
        uint256 pairsCount;
        uint256 groupsCount;
        uint256 feesCount;
        uint256[41] __gap;
    }

    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } /// @custom:deprecated
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } /// @custom:deprecated

    struct Pair {
        string from;
        string to;
        Feed feed; /// @custom:deprecated
        uint256 spreadP; // 1e10
        uint256 groupIndex;
        uint256 feeIndex;
    }

    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage; // 0 decimal precision
        uint256 maxLeverage; // 0 decimal precision
    }
    struct Fee {
        string name;
        uint256 openFeeP; // 1e10 (% of position size)
        uint256 closeFeeP; // 1e10 (% of position size)
        uint256 oracleFeeP; // 1e10 (% of position size)
        uint256 triggerOrderFeeP; // 1e10 (% of position size)
        uint256 minPositionSizeUsd; // 1e18 (collateral x leverage, useful for min fee)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "./ITradingStorage.sol";
import "../IChainlinkFeed.sol";
import "../ILiquidityPool.sol";

/**
 * @dev Contains the types for the GNSPriceAggregator facet
 */
interface IPriceAggregator {
    struct PriceAggregatorStorage {
        // slot 1
        IChainlinkFeed linkUsdPriceFeed; // 160 bits
        uint24 twapInterval; // 24 bits
        uint8 minAnswers; // 8 bits
        bytes32[2] jobIds; // 64 bits
        // slot 2, 3, 4, 5, 6
        address[] oracles;
        mapping(uint8 => LiquidityPoolInfo) collateralGnsLiquidityPools;
        mapping(uint8 => IChainlinkFeed) collateralUsdPriceFeed;
        mapping(bytes32 => Order) orders;
        mapping(address => mapping(uint32 => OrderAnswer[])) orderAnswers;
        // Chainlink Client (slots 7, 8, 9)
        LinkTokenInterface linkErc677; // 160 bits
        uint96 __placeholder; // 96 bits
        uint256 requestCount; // 256 bits
        mapping(bytes32 => address) pendingRequests;
        uint256[41] __gap;
    }

    struct LiquidityPoolInfo {
        ILiquidityPool pool; // 160 bits
        bool isGnsToken0InLp; // 8 bits
        PoolType poolType; // 8 bits
        uint80 __placeholder; // 80 bits
    }

    struct Order {
        address user; // 160 bits
        uint32 index; // 32 bits
        ITradingStorage.PendingOrderType orderType; // 8 bits
        uint16 pairIndex; // 16 bits
        bool isLookback; // 8 bits
        uint32 __placeholder; // 32 bits
    }

    struct OrderAnswer {
        uint64 open;
        uint64 high;
        uint64 low;
        uint64 ts;
    }

    struct LiquidityPoolInput {
        ILiquidityPool pool;
        PoolType poolType;
    }

    enum PoolType {
        UNISWAP_V3,
        ALGEBRA_v1_9
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSPriceImpact facet
 */
interface IPriceImpact {
    struct PriceImpactStorage {
        OiWindowsSettings oiWindowsSettings;
        mapping(uint48 => mapping(uint256 => mapping(uint256 => PairOi))) windows; // duration => pairIndex => windowId => Oi
        mapping(uint256 => PairDepth) pairDepths; // pairIndex => depth (USD)
        mapping(address => mapping(uint32 => TradePriceImpactInfo)) tradePriceImpactInfos;
        uint256[46] __gap;
    }

    struct OiWindowsSettings {
        uint48 startTs;
        uint48 windowsDuration;
        uint48 windowsCount;
    }

    struct PairOi {
        uint128 oiLongUsd; // 1e18 USD
        uint128 oiShortUsd; // 1e18 USD
    }

    struct OiWindowUpdate {
        address trader;
        uint32 index;
        uint48 windowsDuration;
        uint256 pairIndex;
        uint256 windowId;
        bool long;
        uint128 openInterestUsd; // 1e18 USD
    }

    struct PairDepth {
        uint128 onePercentDepthAboveUsd; // USD
        uint128 onePercentDepthBelowUsd; // USD
    }

    struct TradePriceImpactInfo {
        uint128 lastWindowOiUsd; // 1e18 USD
        uint128 __placeholder;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSReferrals facet
 */
interface IReferrals {
    struct ReferralsStorage {
        mapping(address => AllyDetails) allyDetails;
        mapping(address => ReferrerDetails) referrerDetails;
        mapping(address => address) referrerByTrader;
        uint256 allyFeeP; // % (of referrer fees going to allies, eg. 10)
        uint256 startReferrerFeeP; // % (of referrer fee when 0 volume referred, eg. 75)
        uint256 openFeeP; // % (of opening fee used for referral system, eg. 33)
        uint256 targetVolumeUsd; // USD (to reach maximum referral system fee, eg. 1e8)
        uint256[43] __gap;
    }

    struct AllyDetails {
        address[] referrersReferred;
        uint256 volumeReferredUsd; // 1e18
        uint256 pendingRewardsGns; // 1e18
        uint256 totalRewardsGns; // 1e18
        uint256 totalRewardsValueUsd; // 1e18
        bool active;
    }

    struct ReferrerDetails {
        address ally;
        address[] tradersReferred;
        uint256 volumeReferredUsd; // 1e18
        uint256 pendingRewardsGns; // 1e18
        uint256 totalRewardsGns; // 1e18
        uint256 totalRewardsValueUsd; // 1e18
        bool active;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITradingStorage.sol";

/**
 * @dev Contains the types for the GNSTradingCallbacks facet
 */
interface ITradingCallbacks {
    struct TradingCallbacksStorage {
        uint8 vaultClosingFeeP;
        uint248 __placeholder;
        mapping(uint8 => uint256) pendingGovFees; // collateralIndex => pending gov fee (collateral)
        uint256[48] __gap;
    }

    enum CancelReason {
        NONE,
        PAUSED, // deprecated
        MARKET_CLOSED,
        SLIPPAGE,
        TP_REACHED,
        SL_REACHED,
        EXPOSURE_LIMITS,
        PRICE_IMPACT,
        MAX_LEVERAGE,
        NO_TRADE,
        WRONG_TRADE, // deprecated
        NOT_HIT,
        LIQ_REACHED
    }

    struct AggregatorAnswer {
        ITradingStorage.Id orderId;
        uint256 spreadP;
        uint64 price;
        uint64 open;
        uint64 high;
        uint64 low;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint256 positionSizeCollateral;
        uint256 gnsPriceCollateral;
        int256 profitP;
        uint256 executionPrice;
        uint256 liqPrice;
        uint256 amountSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
        uint128 collateralPrecisionDelta;
        uint256 collateralPriceUsd;
        bool exactExecution;
        uint256 closingFeeCollateral;
        uint256 triggerFeeCollateral;
        uint256 collateralLeftInStorage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSTradingInteractions facet
 */
interface ITradingInteractions {
    struct TradingInteractionsStorage {
        address senderOverride; // 160 bits
        uint16 marketOrdersTimeoutBlocks; // 16 bits
        uint80 __placeholder;
        mapping(address => address) delegations;
        mapping(address => bool) byPassTriggerLink;
        uint256[47] __gap;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSTradingStorage facet
 */
interface ITradingStorage {
    struct TradingStorage {
        TradingActivated tradingActivated; // 8 bits
        uint8 lastCollateralIndex; // 8 bits
        uint240 __placeholder; // 240 bits
        mapping(uint8 => Collateral) collaterals;
        mapping(uint8 => address) gTokens;
        mapping(address => uint8) collateralIndex;
        mapping(address => mapping(uint32 => Trade)) trades;
        mapping(address => mapping(uint32 => TradeInfo)) tradeInfos;
        mapping(address => mapping(uint32 => mapping(PendingOrderType => uint256))) tradePendingOrderBlock;
        mapping(address => mapping(uint32 => PendingOrder)) pendingOrders;
        mapping(address => mapping(CounterType => Counter)) userCounters;
        address[] traders;
        mapping(address => bool) traderStored;
        uint256[39] __gap;
    }

    enum PendingOrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        STOP_OPEN,
        TP_CLOSE,
        SL_CLOSE,
        LIQ_CLOSE,
        UPDATE_LEVERAGE,
        MARKET_PARTIAL_OPEN,
        MARKET_PARTIAL_CLOSE
    }

    enum CounterType {
        TRADE,
        PENDING_ORDER
    }

    enum TradeType {
        TRADE,
        LIMIT,
        STOP
    }

    enum TradingActivated {
        ACTIVATED,
        CLOSE_ONLY,
        PAUSED
    }

    struct Collateral {
        // slot 1
        address collateral; // 160 bits
        bool isActive; // 8 bits
        uint88 __placeholder; // 88 bits
        // slot 2
        uint128 precision;
        uint128 precisionDelta;
    }

    struct Id {
        address user; // 160 bits
        uint32 index; // max: 4,294,967,295
    }

    struct Trade {
        // slot 1
        address user; // 160 bits
        uint32 index; // max: 4,294,967,295
        uint16 pairIndex; // max: 65,535
        uint24 leverage; // 1e3; max: 16,777.215
        bool long; // 8 bits
        bool isOpen; // 8 bits
        uint8 collateralIndex; // max: 255
        // slot 2
        TradeType tradeType; // 8 bits
        uint120 collateralAmount; // 1e18; max: 3.402e+38
        uint64 openPrice; // 1e10; max: 1.8e19
        uint64 tp; // 1e10; max: 1.8e19
        // slot 3 (192 bits left)
        uint64 sl; // 1e10; max: 1.8e19
        uint192 __placeholder;
    }

    struct TradeInfo {
        uint32 createdBlock;
        uint32 tpLastUpdatedBlock;
        uint32 slLastUpdatedBlock;
        uint16 maxSlippageP; // 1e3 (%)
        uint48 lastOiUpdateTs;
        uint48 collateralPriceUsd; // 1e8 collateral price at trade open
        uint48 __placeholder;
    }

    struct PendingOrder {
        // slots 1-3
        Trade trade;
        // slot 4
        address user; // 160 bits
        uint32 index; // max: 4,294,967,295
        bool isOpen; // 8 bits
        PendingOrderType orderType; // 8 bits
        uint32 createdBlock; // max: 4,294,967,295
        uint16 maxSlippageP; // 1e3 (%), max: 65.535%
    }

    struct Counter {
        uint32 currentIndex;
        uint32 openCount;
        uint192 __placeholder;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Contains the types for the GNSTriggerRewards facet
 */
interface ITriggerRewards {
    struct TriggerRewardsStorage {
        uint16 triggerTimeoutBlocks; // 16 bits
        uint240 __placeholder; // 240 bits
        mapping(address => uint256) pendingRewardsGns;
        uint256[48] __gap;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./IDiamondStorage.sol";
import "./IPairsStorage.sol";
import "./IReferrals.sol";
import "./IFeeTiers.sol";
import "./IPriceImpact.sol";
import "./ITradingStorage.sol";
import "./ITriggerRewards.sol";
import "./ITradingInteractions.sol";
import "./ITradingCallbacks.sol";
import "./IBorrowingFees.sol";
import "./IPriceAggregator.sol";

/**
 * @dev Contains the types of all diamond facets
 */
interface ITypes is
    IDiamondStorage,
    IPairsStorage,
    IReferrals,
    IFeeTiers,
    IPriceImpact,
    ITradingStorage,
    ITriggerRewards,
    ITradingInteractions,
    ITradingCallbacks,
    IBorrowingFees,
    IPriceAggregator
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 *
 * @dev Interface for leverage updates types
 */
interface IUpdateLeverage {
    /// @dev Update leverage input values
    struct UpdateLeverageInput {
        address user;
        uint32 index;
        uint24 newLeverage;
    }

    /// @dev Useful values for increase leverage callback
    struct UpdateLeverageValues {
        uint256 newLeverage;
        uint256 newCollateralAmount;
        uint256 liqPrice;
        uint256 govFeeCollateral;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 *
 * @dev Interface for position size updates types
 */
interface IUpdatePositionSize {
    /// @dev Request decrease position input values
    struct DecreasePositionSizeInput {
        address user;
        uint32 index;
        uint120 collateralDelta;
        uint24 leverageDelta;
    }

    /// @dev Request increase position input values
    struct IncreasePositionSizeInput {
        address user;
        uint32 index;
        uint120 collateralDelta;
        uint24 leverageDelta;
        uint64 expectedPrice;
        uint16 maxSlippageP;
    }

    /// @dev Useful values for decrease position size callback
    struct DecreasePositionSizeValues {
        uint256 positionSizeCollateralDelta;
        uint256 existingPositionSizeCollateral;
        uint256 existingLiqPrice;
        int256 existingPnlCollateral;
        uint256 borrowingFeeCollateral;
        uint256 vaultFeeCollateral;
        uint256 gnsStakingFeeCollateral;
        int256 availableCollateralInDiamond;
        int256 collateralSentToTrader;
        uint120 newCollateralAmount;
        uint24 newLeverage;
    }

    /// @dev Useful values for increase position size callback
    struct IncreasePositionSizeValues {
        uint256 positionSizeCollateralDelta;
        uint256 existingPositionSizeCollateral;
        uint256 newPositionSizeCollateral;
        uint256 newCollateralAmount;
        uint256 newLeverage;
        uint256 priceAfterImpact;
        int256 existingPnlCollateral;
        uint256 newOpenPrice;
        uint256 borrowingFeeCollateral;
        uint256 openingFeesCollateral;
        uint256 existingLiqPrice;
        uint256 newLiqPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/types/IAddressStore.sol";

import "./StorageUtils.sol";

/**
 *
 * @dev GNSAddressStore facet internal library
 */
library AddressStoreUtils {
    /**
     * @dev Returns storage slot to use when fetching addresses
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_ADDRESSES_SLOT;
    }

    /**
     * @dev Returns storage pointer for Addresses struct in global diamond contract, at defined slot
     */
    function getAddresses() internal pure returns (IAddressStore.Addresses storage s) {
        uint256 storageSlot = _getSlot();
        assembly {
            s.slot := storageSlot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./TradingStorageUtils.sol";

/**
 * @dev External library for array getters to save bytecode size in facet libraries
 */

library ArrayGetters {
    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTraders(uint32 _offset, uint32 _limit) public view returns (address[] memory) {
        ITradingStorage.TradingStorage storage s = TradingStorageUtils._getStorage();

        if (s.traders.length == 0) return new address[](0);

        uint256 lastIndex = s.traders.length - 1;
        _limit = _limit == 0 || _limit > lastIndex ? uint32(lastIndex) : _limit;

        address[] memory traders = new address[](_limit - _offset + 1);

        uint32 currentIndex;
        for (uint32 i = _offset; i <= _limit; ++i) {
            address trader = s.traders[i];
            if (
                s.userCounters[trader][ITradingStorage.CounterType.TRADE].openCount > 0 ||
                s.userCounters[trader][ITradingStorage.CounterType.PENDING_ORDER].openCount > 0
            ) {
                traders[currentIndex++] = trader;
            }
        }

        return traders;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTrades(address _trader) public view returns (ITradingStorage.Trade[] memory) {
        ITradingStorage.TradingStorage storage s = TradingStorageUtils._getStorage();
        ITradingStorage.Counter memory traderCounter = s.userCounters[_trader][ITradingStorage.CounterType.TRADE];
        ITradingStorage.Trade[] memory trades = new ITradingStorage.Trade[](traderCounter.openCount);

        uint32 currentIndex;
        for (uint32 i; i < traderCounter.currentIndex; ++i) {
            ITradingStorage.Trade memory trade = s.trades[_trader][i];
            if (trade.isOpen) {
                trades[currentIndex++] = trade;
            }
        }

        return trades;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getAllTrades(uint256 _offset, uint256 _limit) external view returns (ITradingStorage.Trade[] memory) {
        // Fetch all traders with open trades (no pagination, return size is not an issue here)
        address[] memory traders = getTraders(0, 0);

        uint256 currentTradeIndex; // current global trade index
        uint256 currentArrayIndex; // current index in returned trades array

        ITradingStorage.Trade[] memory trades = new ITradingStorage.Trade[](_limit - _offset + 1);

        // Fetch all trades for each trader
        for (uint256 i; i < traders.length; ++i) {
            ITradingStorage.Trade[] memory traderTrades = getTrades(traders[i]);

            // Add trader trades to final trades array only if within _offset and _limit
            for (uint256 j; j < traderTrades.length; ++j) {
                if (currentTradeIndex >= _offset && currentTradeIndex <= _limit) {
                    trades[currentArrayIndex++] = traderTrades[j];
                }
                currentTradeIndex++;
            }
        }

        return trades;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTradeInfos(address _trader) public view returns (ITradingStorage.TradeInfo[] memory) {
        ITradingStorage.TradingStorage storage s = TradingStorageUtils._getStorage();
        ITradingStorage.Counter memory traderCounter = s.userCounters[_trader][ITradingStorage.CounterType.TRADE];
        ITradingStorage.TradeInfo[] memory tradeInfos = new ITradingStorage.TradeInfo[](traderCounter.openCount);

        uint32 currentIndex;
        for (uint32 i; i < traderCounter.currentIndex; ++i) {
            if (s.trades[_trader][i].isOpen) {
                tradeInfos[currentIndex++] = s.tradeInfos[_trader][i];
            }
        }

        return tradeInfos;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getAllTradeInfos(
        uint256 _offset,
        uint256 _limit
    ) external view returns (ITradingStorage.TradeInfo[] memory) {
        // Fetch all traders with open trades (no pagination, return size is not an issue here)
        address[] memory traders = getTraders(0, 0);

        uint256 currentTradeIndex; // current global trade index
        uint256 currentArrayIndex; // current index in returned trades array

        ITradingStorage.TradeInfo[] memory tradesInfos = new ITradingStorage.TradeInfo[](_limit - _offset + 1);

        // Fetch all trades for each trader
        for (uint256 i; i < traders.length; ++i) {
            ITradingStorage.TradeInfo[] memory traderTradesInfos = getTradeInfos(traders[i]);

            // Add trader trades to final trades array only if within _offset and _limit
            for (uint256 j; j < traderTradesInfos.length; ++j) {
                if (currentTradeIndex >= _offset && currentTradeIndex <= _limit) {
                    tradesInfos[currentArrayIndex++] = traderTradesInfos[j];
                }
                currentTradeIndex++;
            }
        }

        return tradesInfos;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getPendingOrders(address _trader) public view returns (ITradingStorage.PendingOrder[] memory) {
        ITradingStorage.TradingStorage storage s = TradingStorageUtils._getStorage();
        ITradingStorage.Counter memory traderCounter = s.userCounters[_trader][
            ITradingStorage.CounterType.PENDING_ORDER
        ];
        ITradingStorage.PendingOrder[] memory pendingOrders = new ITradingStorage.PendingOrder[](
            traderCounter.openCount
        );

        uint32 currentIndex;
        for (uint32 i; i < traderCounter.currentIndex; ++i) {
            if (s.pendingOrders[_trader][i].isOpen) {
                pendingOrders[currentIndex++] = s.pendingOrders[_trader][i];
            }
        }

        return pendingOrders;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getAllPendingOrders(
        uint256 _offset,
        uint256 _limit
    ) external view returns (ITradingStorage.PendingOrder[] memory) {
        // Fetch all traders with open trades (no pagination, return size is not an issue here)
        address[] memory traders = getTraders(0, 0);

        uint256 currentPendingOrderIndex; // current global pending order index
        uint256 currentArrayIndex; // current index in returned pending orders array

        ITradingStorage.PendingOrder[] memory pendingOrders = new ITradingStorage.PendingOrder[](_limit - _offset + 1);

        // Fetch all trades for each trader
        for (uint256 i; i < traders.length; ++i) {
            ITradingStorage.PendingOrder[] memory traderPendingOrders = getPendingOrders(traders[i]);

            // Add trader trades to final trades array only if within _offset and _limit
            for (uint256 j; j < traderPendingOrders.length; ++j) {
                if (currentPendingOrderIndex >= _offset && currentPendingOrderIndex <= _limit) {
                    pendingOrders[currentArrayIndex++] = traderPendingOrders[j];
                }
                currentPendingOrderIndex++;
            }
        }

        return pendingOrders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IArbSys.sol";
import "../interfaces/mock/IBlockManager_Mock.sol";

/**
 * @dev Chain helpers internal library
 */
library ChainUtils {
    // Supported chains
    uint256 internal constant ARBITRUM_MAINNET = 42161;
    uint256 internal constant ARBITRUM_SEPOLIA = 421614;
    uint256 internal constant POLYGON_MAINNET = 137;
    uint256 internal constant TESTNET = 31337;

    // Wrapped native tokens
    address private constant ARBITRUM_MAINNET_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private constant ARBITRUM_SEPOLIA_WETH = 0x980B62Da83eFf3D4576C647993b0c1D7faf17c73;
    address private constant POLYGON_MAINNET_WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    IArbSys private constant ARB_SYS = IArbSys(address(100));

    error Overflow();

    /**
     * @dev Returns the current block number (l2 block for arbitrum)
     */
    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_SEPOLIA) {
            return ARB_SYS.arbBlockNumber();
        }

        if (block.chainid == TESTNET) {
            return IBlockManager_Mock(address(420)).getBlockNumber();
        }

        return block.number;
    }

    /**
     * @dev Returns blockNumber converted to uint48
     * @param blockNumber block number to convert
     */
    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        if (blockNumber > type(uint48).max) revert Overflow();
        return uint48(blockNumber);
    }

    /**
     * @dev Returns the wrapped native token address for the current chain
     */
    function getWrappedNativeToken() internal view returns (address) {
        if (block.chainid == ARBITRUM_MAINNET) {
            return ARBITRUM_MAINNET_WETH;
        }

        if (block.chainid == POLYGON_MAINNET) {
            return POLYGON_MAINNET_WMATIC;
        }

        if (block.chainid == ARBITRUM_SEPOLIA) {
            return ARBITRUM_SEPOLIA_WETH;
        }

        if (block.chainid == TESTNET) {
            return address(421);
        }

        return address(0);
    }

    /**
     * @dev Returns whether a token is the wrapped native token for the current chain
     * @param _token token address to check
     */
    function isWrappedNativeToken(address _token) internal view returns (bool) {
        return _token != address(0) && _token == getWrappedNativeToken();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IERC20.sol";

/**
 * @dev Collaterals decimal precision internal library
 */
library CollateralUtils {
    struct CollateralConfig {
        uint128 precision;
        uint128 precisionDelta;
    }

    /**
     * @dev Calculates `precision` (10^decimals) and `precisionDelta` (precision difference
     * between 18 decimals and `token` decimals) of a given IERC20 `token`
     *
     * Notice: not compatible with tokens with more than 18 decimals
     *
     * @param   _token collateral token address
     */
    function getCollateralConfig(address _token) internal view returns (CollateralConfig memory _meta) {
        uint256 _decimals = uint256(IERC20(_token).decimals());

        _meta.precision = uint128(10 ** _decimals);
        _meta.precisionDelta = uint128(10 ** (18 - _decimals));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/types/ITradingStorage.sol";

/**
 *
 * @dev Internal library for important constants commonly used in many places
 */
library ConstantsUtils {
    uint256 internal constant P_10 = 1e10; // 10 decimals (DO NOT UPDATE)
    uint256 internal constant MAX_SL_P = 75; // -75% PNL
    uint256 internal constant MAX_PNL_P = 900; // 900% PnL (10x)
    uint256 internal constant LIQ_THRESHOLD_P = 90; // -90% pnl
    uint256 internal constant MAX_OPEN_NEGATIVE_PNL_P = 40 * 1e10; // -40% pnl

    function getMarketOrderTypes() internal pure returns (ITradingStorage.PendingOrderType[5] memory) {
        return [
            ITradingStorage.PendingOrderType.MARKET_OPEN,
            ITradingStorage.PendingOrderType.MARKET_CLOSE,
            ITradingStorage.PendingOrderType.UPDATE_LEVERAGE,
            ITradingStorage.PendingOrderType.MARKET_PARTIAL_OPEN,
            ITradingStorage.PendingOrderType.MARKET_PARTIAL_CLOSE
        ];
    }

    /**
     * @dev Returns pending order type (market open/limit open/stop open) for a trade type (trade/limit/stop)
     * @param _tradeType the trade type
     */
    function getPendingOpenOrderType(
        ITradingStorage.TradeType _tradeType
    ) internal pure returns (ITradingStorage.PendingOrderType) {
        return
            _tradeType == ITradingStorage.TradeType.TRADE
                ? ITradingStorage.PendingOrderType.MARKET_OPEN
                : _tradeType == ITradingStorage.TradeType.LIMIT
                ? ITradingStorage.PendingOrderType.LIMIT_OPEN
                : ITradingStorage.PendingOrderType.STOP_OPEN;
    }

    /**
     * @dev Returns true if order type is market
     * @param _orderType order type
     */
    function isOrderTypeMarket(ITradingStorage.PendingOrderType _orderType) internal pure returns (bool) {
        ITradingStorage.PendingOrderType[5] memory marketOrderTypes = ConstantsUtils.getMarketOrderTypes();
        for (uint256 i; i < marketOrderTypes.length; ++i) {
            if (_orderType == marketOrderTypes[i]) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 *
 * @dev Internal library to manage storage slots of GNSMultiCollatDiamond contract diamond storage structs.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant GLOBAL_ADDRESSES_SLOT = 3;
    uint256 internal constant GLOBAL_PAIRS_STORAGE_SLOT = 51;
    uint256 internal constant GLOBAL_REFERRALS_SLOT = 101;
    uint256 internal constant GLOBAL_FEE_TIERS_SLOT = 151;
    uint256 internal constant GLOBAL_PRICE_IMPACT_SLOT = 201;
    uint256 internal constant GLOBAL_DIAMOND_SLOT = 251;
    uint256 internal constant GLOBAL_TRADING_STORAGE_SLOT = 301;
    uint256 internal constant GLOBAL_TRIGGER_REWARDS_SLOT = 351;
    uint256 internal constant GLOBAL_TRADING_SLOT = 401;
    uint256 internal constant GLOBAL_TRADING_CALLBACKS_SLOT = 451;
    uint256 internal constant GLOBAL_BORROWING_FEES_SLOT = 501;
    uint256 internal constant GLOBAL_PRICE_AGGREGATOR_SLOT = 551;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IGNSMultiCollatDiamond.sol";
import "../interfaces/IGToken.sol";
import "../interfaces/IGNSStaking.sol";
import "../interfaces/IERC20.sol";

import "./StorageUtils.sol";
import "./AddressStoreUtils.sol";
import "./TradingCommonUtils.sol";
import "./updateLeverage/UpdateLeverageLifecycles.sol";
import "./updatePositionSize/UpdatePositionSizeLifecycles.sol";

/**
 * @dev GNSTradingCallbacks facet internal library
 */
library TradingCallbacksUtils {
    /**
     * @dev Modifier to only allow trading action when trading is activated (= revert if not activated)
     */
    modifier tradingActivated() {
        if (_getMultiCollatDiamond().getTradingActivated() != ITradingStorage.TradingActivated.ACTIVATED)
            revert IGeneralErrors.Paused();
        _;
    }

    /**
     * @dev Modifier to only allow trading action when trading is activated or close only (= revert if paused)
     */
    modifier tradingActivatedOrCloseOnly() {
        if (_getMultiCollatDiamond().getTradingActivated() == ITradingStorage.TradingActivated.PAUSED)
            revert IGeneralErrors.Paused();
        _;
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function initializeCallbacks(uint8 _vaultClosingFeeP) internal {
        updateVaultClosingFeeP(_vaultClosingFeeP);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function updateVaultClosingFeeP(uint8 _valueP) internal {
        if (_valueP > 100) revert IGeneralErrors.AboveMax();

        _getStorage().vaultClosingFeeP = _valueP;

        emit ITradingCallbacksUtils.VaultClosingFeePUpdated(_valueP);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function claimPendingGovFees() internal {
        uint8 collateralsCount = _getMultiCollatDiamond().getCollateralsCount();
        for (uint8 i = 1; i <= collateralsCount; ++i) {
            uint256 feesAmountCollateral = _getStorage().pendingGovFees[i];

            if (feesAmountCollateral > 0) {
                _getStorage().pendingGovFees[i] = 0;

                TradingCommonUtils.transferCollateralTo(i, msg.sender, feesAmountCollateral);

                emit ITradingCallbacksUtils.PendingGovFeesClaimed(i, feesAmountCollateral);
            }
        }
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function openTradeMarketCallback(ITradingCallbacks.AggregatorAnswer memory _a) internal tradingActivated {
        ITradingStorage.PendingOrder memory o = _getPendingOrder(_a.orderId);

        if (!o.isOpen) return;

        ITradingStorage.Trade memory t = o.trade;

        (uint256 priceImpactP, uint256 priceAfterImpact, ITradingCallbacks.CancelReason cancelReason) = _openTradePrep(
            t,
            _a.price,
            _a.price,
            _a.spreadP,
            o.maxSlippageP
        );

        t.openPrice = uint64(priceAfterImpact);

        if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
            t = _registerTrade(t, o);

            emit ITradingCallbacksUtils.MarketExecuted(
                _a.orderId,
                t,
                true,
                t.openPrice,
                priceImpactP,
                0,
                0,
                _getCollateralPriceUsd(t.collateralIndex)
            );
        } else {
            // Gov fee to pay for oracle cost
            TradingCommonUtils.updateFeeTierPoints(t.collateralIndex, t.user, t.pairIndex, 0);
            uint256 govFees = TradingCommonUtils.distributeGovFeeCollateral(
                t.collateralIndex,
                t.user,
                t.pairIndex,
                TradingCommonUtils.getMinPositionSizeCollateral(t.collateralIndex, t.pairIndex) / 2, // use min fee / 2
                0
            );
            TradingCommonUtils.transferCollateralTo(t.collateralIndex, t.user, t.collateralAmount - govFees);

            emit ITradingCallbacksUtils.MarketOpenCanceled(_a.orderId, t.user, t.pairIndex, cancelReason);
        }

        _getMultiCollatDiamond().closePendingOrder(_a.orderId);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function closeTradeMarketCallback(
        ITradingCallbacks.AggregatorAnswer memory _a
    ) internal tradingActivatedOrCloseOnly {
        ITradingStorage.PendingOrder memory o = _getPendingOrder(_a.orderId);

        if (!o.isOpen) return;

        ITradingStorage.Trade memory t = _getTrade(o.trade.user, o.trade.index);

        ITradingCallbacks.CancelReason cancelReason = !t.isOpen
            ? ITradingCallbacks.CancelReason.NO_TRADE
            : (_a.price == 0 ? ITradingCallbacks.CancelReason.MARKET_CLOSED : ITradingCallbacks.CancelReason.NONE);

        if (cancelReason != ITradingCallbacks.CancelReason.NO_TRADE) {
            ITradingCallbacks.Values memory v;

            if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
                v.profitP = TradingCommonUtils.getPnlPercent(t.openPrice, _a.price, t.long, t.leverage);

                v.amountSentToTrader = _unregisterTrade(t, v.profitP, o.orderType);

                emit ITradingCallbacksUtils.MarketExecuted(
                    _a.orderId,
                    t,
                    false,
                    _a.price,
                    0,
                    v.profitP,
                    v.amountSentToTrader,
                    _getCollateralPriceUsd(t.collateralIndex)
                );
            } else {
                // Charge gov fee
                TradingCommonUtils.updateFeeTierPoints(t.collateralIndex, t.user, t.pairIndex, 0);
                uint256 govFee = TradingCommonUtils.distributeGovFeeCollateral(
                    t.collateralIndex,
                    t.user,
                    t.pairIndex,
                    TradingCommonUtils.getMinPositionSizeCollateral(t.collateralIndex, t.pairIndex) / 2, // use min fee / 2
                    0
                );

                // Deduct from trade collateral
                _getMultiCollatDiamond().updateTradeCollateralAmount(
                    ITradingStorage.Id({user: t.user, index: t.index}),
                    t.collateralAmount - uint120(govFee)
                );
            }
        }

        if (cancelReason != ITradingCallbacks.CancelReason.NONE) {
            emit ITradingCallbacksUtils.MarketCloseCanceled(_a.orderId, t.user, t.pairIndex, t.index, cancelReason);
        }

        _getMultiCollatDiamond().closePendingOrder(_a.orderId);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function executeTriggerOpenOrderCallback(ITradingCallbacks.AggregatorAnswer memory _a) internal tradingActivated {
        ITradingStorage.PendingOrder memory o = _getPendingOrder(_a.orderId);

        if (!o.isOpen) return;

        ITradingStorage.Trade memory t = _getTrade(o.trade.user, o.trade.index);

        ITradingCallbacks.CancelReason cancelReason = !t.isOpen
            ? ITradingCallbacks.CancelReason.NO_TRADE
            : ITradingCallbacks.CancelReason.NONE;

        if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
            cancelReason = (_a.high >= t.openPrice && _a.low <= t.openPrice)
                ? ITradingCallbacks.CancelReason.NONE
                : ITradingCallbacks.CancelReason.NOT_HIT;

            (
                uint256 priceImpactP,
                uint256 priceAfterImpact,
                ITradingCallbacks.CancelReason _cancelReason
            ) = _openTradePrep(
                    t,
                    cancelReason == ITradingCallbacks.CancelReason.NONE ? t.openPrice : _a.open,
                    _a.open,
                    _a.spreadP,
                    _getMultiCollatDiamond().getTradeInfo(t.user, t.index).maxSlippageP
                );

            bool exactExecution = cancelReason == ITradingCallbacks.CancelReason.NONE;

            cancelReason = !exactExecution &&
                (
                    t.tradeType == ITradingStorage.TradeType.STOP
                        ? (t.long ? _a.open < t.openPrice : _a.open > t.openPrice)
                        : (t.long ? _a.open > t.openPrice : _a.open < t.openPrice)
                )
                ? ITradingCallbacks.CancelReason.NOT_HIT
                : _cancelReason;

            if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
                // Unregister open order
                _getMultiCollatDiamond().closeTrade(ITradingStorage.Id({user: t.user, index: t.index}));

                // Store trade
                t.openPrice = uint64(priceAfterImpact);
                t.tradeType = ITradingStorage.TradeType.TRADE;
                t = _registerTrade(t, o);

                emit ITradingCallbacksUtils.LimitExecuted(
                    _a.orderId,
                    t,
                    o.user,
                    o.orderType,
                    t.openPrice,
                    priceImpactP,
                    0,
                    0,
                    _getCollateralPriceUsd(t.collateralIndex),
                    exactExecution
                );
            }
        }

        if (cancelReason != ITradingCallbacks.CancelReason.NONE) {
            emit ITradingCallbacksUtils.TriggerOrderCanceled(_a.orderId, o.user, o.orderType, cancelReason);
        }

        _getMultiCollatDiamond().closePendingOrder(_a.orderId);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function executeTriggerCloseOrderCallback(
        ITradingCallbacks.AggregatorAnswer memory _a
    ) internal tradingActivatedOrCloseOnly {
        ITradingStorage.PendingOrder memory o = _getPendingOrder(_a.orderId);

        if (!o.isOpen) return;

        ITradingStorage.Trade memory t = _getTrade(o.trade.user, o.trade.index);

        ITradingCallbacks.CancelReason cancelReason = _a.open == 0
            ? ITradingCallbacks.CancelReason.MARKET_CLOSED
            : (!t.isOpen ? ITradingCallbacks.CancelReason.NO_TRADE : ITradingCallbacks.CancelReason.NONE);

        if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
            ITradingCallbacks.Values memory v;

            if (o.orderType == ITradingStorage.PendingOrderType.LIQ_CLOSE) {
                v.liqPrice = TradingCommonUtils.getTradeLiquidationPrice(t, true);
            }

            uint256 triggerPrice = o.orderType == ITradingStorage.PendingOrderType.TP_CLOSE
                ? t.tp
                : (o.orderType == ITradingStorage.PendingOrderType.SL_CLOSE ? t.sl : v.liqPrice);

            v.exactExecution = triggerPrice > 0 && _a.low <= triggerPrice && _a.high >= triggerPrice;
            v.executionPrice = v.exactExecution ? triggerPrice : _a.open;

            cancelReason = (v.exactExecution ||
                (o.orderType == ITradingStorage.PendingOrderType.LIQ_CLOSE &&
                    (t.long ? _a.open <= v.liqPrice : _a.open >= v.liqPrice)) ||
                (o.orderType == ITradingStorage.PendingOrderType.TP_CLOSE &&
                    t.tp > 0 &&
                    (t.long ? _a.open >= t.tp : _a.open <= t.tp)) ||
                (o.orderType == ITradingStorage.PendingOrderType.SL_CLOSE &&
                    t.sl > 0 &&
                    (t.long ? _a.open <= t.sl : _a.open >= t.sl)))
                ? ITradingCallbacks.CancelReason.NONE
                : ITradingCallbacks.CancelReason.NOT_HIT;

            // If can be triggered
            if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
                v.profitP = TradingCommonUtils.getPnlPercent(t.openPrice, uint64(v.executionPrice), t.long, t.leverage);

                v.amountSentToTrader = _unregisterTrade(t, v.profitP, o.orderType);

                emit ITradingCallbacksUtils.LimitExecuted(
                    _a.orderId,
                    t,
                    o.user,
                    o.orderType,
                    v.executionPrice,
                    0,
                    v.profitP,
                    v.amountSentToTrader,
                    _getCollateralPriceUsd(t.collateralIndex),
                    v.exactExecution
                );
            }
        }

        if (cancelReason != ITradingCallbacks.CancelReason.NONE) {
            emit ITradingCallbacksUtils.TriggerOrderCanceled(_a.orderId, o.user, o.orderType, cancelReason);
        }

        _getMultiCollatDiamond().closePendingOrder(_a.orderId);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function updateLeverageCallback(ITradingCallbacks.AggregatorAnswer memory _a) internal tradingActivated {
        ITradingStorage.PendingOrder memory order = _getMultiCollatDiamond().getPendingOrder(_a.orderId);

        if (!order.isOpen) return;

        UpdateLeverageLifecycles.executeUpdateLeverage(order, _a);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function increasePositionSizeMarketCallback(
        ITradingCallbacks.AggregatorAnswer memory _a
    ) internal tradingActivated {
        ITradingStorage.PendingOrder memory order = _getMultiCollatDiamond().getPendingOrder(_a.orderId);

        if (!order.isOpen) return;

        UpdatePositionSizeLifecycles.executeIncreasePositionSizeMarket(order, _a);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function decreasePositionSizeMarketCallback(
        ITradingCallbacks.AggregatorAnswer memory _a
    ) internal tradingActivatedOrCloseOnly {
        ITradingStorage.PendingOrder memory order = _getMultiCollatDiamond().getPendingOrder(_a.orderId);

        if (!order.isOpen) return;

        UpdatePositionSizeLifecycles.executeDecreasePositionSizeMarket(order, _a);
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function getVaultClosingFeeP() internal view returns (uint8) {
        return _getStorage().vaultClosingFeeP;
    }

    /**
     * @dev Check ITradingCallbacksUtils interface for documentation
     */
    function getPendingGovFeesCollateral(uint8 _collateralIndex) internal view returns (uint256) {
        return _getStorage().pendingGovFees[_collateralIndex];
    }

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_TRADING_CALLBACKS_SLOT;
    }

    /**
     * @dev Returns storage pointer for storage struct in diamond contract, at defined slot
     */
    function _getStorage() internal pure returns (ITradingCallbacks.TradingCallbacksStorage storage s) {
        uint256 storageSlot = _getSlot();
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }

    /**
     * @dev Registers a trade in storage, and handles all fees and rewards
     * @param _trade Trade to register
     * @param _pendingOrder Corresponding pending order
     * @return Final registered trade
     */
    function _registerTrade(
        ITradingStorage.Trade memory _trade,
        ITradingStorage.PendingOrder memory _pendingOrder
    ) internal returns (ITradingStorage.Trade memory) {
        // 1. Deduct gov fee, GNS staking fee (previously dev fee), Market/Limit fee
        _trade.collateralAmount -= TradingCommonUtils.processOpeningFees(
            _trade,
            TradingCommonUtils.getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage),
            _pendingOrder.orderType
        );

        // 2. Store final trade in storage contract
        ITradingStorage.TradeInfo memory tradeInfo;
        _trade = _getMultiCollatDiamond().storeTrade(_trade, tradeInfo);

        return _trade;
    }

    /**
     * @dev Unregisters a trade from storage, and handles all fees and rewards
     * @param _trade Trade to unregister
     * @param _profitP Profit percentage (1e10)
     * @param _orderType pending order type
     * @return tradeValueCollateral Amount of collateral sent to trader, collateral + pnl (collateral precision)
     */
    function _unregisterTrade(
        ITradingStorage.Trade memory _trade,
        int256 _profitP,
        ITradingStorage.PendingOrderType _orderType
    ) internal returns (uint256 tradeValueCollateral) {
        // 1. Process closing fees, fill 'v' with closing/trigger fees and collateral left in storage, to avoid stack too deep
        ITradingCallbacks.Values memory v = TradingCommonUtils.processClosingFees(
            _trade,
            TradingCommonUtils.getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage),
            _orderType
        );

        // 2. Calculate borrowing fee and net trade value (with pnl and after all closing/holding fees)
        uint256 borrowingFeeCollateral;
        (tradeValueCollateral, borrowingFeeCollateral) = TradingCommonUtils.getTradeValueCollateral(
            _trade,
            _profitP,
            v.closingFeeCollateral + v.triggerFeeCollateral,
            _getMultiCollatDiamond().getCollateral(_trade.collateralIndex).precisionDelta,
            _orderType
        );

        // 3. Take collateral from vault if winning trade or send collateral to vault if losing trade
        TradingCommonUtils.handleTradePnl(
            _trade,
            int256(tradeValueCollateral),
            int256(v.collateralLeftInStorage),
            borrowingFeeCollateral
        );

        // 4. Unregister trade from storage
        _getMultiCollatDiamond().closeTrade(ITradingStorage.Id({user: _trade.user, index: _trade.index}));
    }

    /**
     * @dev Makes pre-trade checks: price impact, if trade should be cancelled based on parameters like: PnL, leverage, slippage, etc.
     * @param _trade trade input
     * @param _executionPrice execution price (1e10 precision)
     * @param _marketPrice market price (1e10 precision)
     * @param _spreadP spread % (1e10 precision)
     * @param _maxSlippageP max slippage % (1e3 precision)
     */
    function _openTradePrep(
        ITradingStorage.Trade memory _trade,
        uint256 _executionPrice,
        uint256 _marketPrice,
        uint256 _spreadP,
        uint256 _maxSlippageP
    )
        internal
        view
        returns (uint256 priceImpactP, uint256 priceAfterImpact, ITradingCallbacks.CancelReason cancelReason)
    {
        uint256 positionSizeCollateral = TradingCommonUtils.getPositionSizeCollateral(
            _trade.collateralAmount,
            _trade.leverage
        );

        (priceImpactP, priceAfterImpact) = _getMultiCollatDiamond().getTradePriceImpact(
            TradingCommonUtils.getMarketExecutionPrice(_executionPrice, _spreadP, _trade.long),
            _trade.pairIndex,
            _trade.long,
            _getMultiCollatDiamond().getUsdNormalizedValue(_trade.collateralIndex, positionSizeCollateral)
        );

        uint256 maxSlippage = (uint256(_trade.openPrice) * _maxSlippageP) / 100 / 1e3;

        cancelReason = _marketPrice == 0
            ? ITradingCallbacks.CancelReason.MARKET_CLOSED
            : (
                (
                    _trade.long
                        ? priceAfterImpact > _trade.openPrice + maxSlippage
                        : priceAfterImpact < _trade.openPrice - maxSlippage
                )
                    ? ITradingCallbacks.CancelReason.SLIPPAGE
                    : (_trade.tp > 0 && (_trade.long ? priceAfterImpact >= _trade.tp : priceAfterImpact <= _trade.tp))
                    ? ITradingCallbacks.CancelReason.TP_REACHED
                    : (_trade.sl > 0 && (_trade.long ? _executionPrice <= _trade.sl : _executionPrice >= _trade.sl))
                    ? ITradingCallbacks.CancelReason.SL_REACHED
                    : !TradingCommonUtils.isWithinExposureLimits(
                        _trade.collateralIndex,
                        _trade.pairIndex,
                        _trade.long,
                        positionSizeCollateral
                    )
                    ? ITradingCallbacks.CancelReason.EXPOSURE_LIMITS
                    : (priceImpactP * _trade.leverage) / 1e3 > ConstantsUtils.MAX_OPEN_NEGATIVE_PNL_P
                    ? ITradingCallbacks.CancelReason.PRICE_IMPACT
                    : _trade.leverage > _getMultiCollatDiamond().pairMaxLeverage(_trade.pairIndex) * 1e3
                    ? ITradingCallbacks.CancelReason.MAX_LEVERAGE
                    : ITradingCallbacks.CancelReason.NONE
            );
    }

    /**
     * @dev Returns pending order from storage
     * @param _orderId Order ID
     * @return Pending order
     */
    function _getPendingOrder(
        ITradingStorage.Id memory _orderId
    ) internal view returns (ITradingStorage.PendingOrder memory) {
        return _getMultiCollatDiamond().getPendingOrder(_orderId);
    }

    /**
     * @dev Returns collateral price in USD
     * @param _collateralIndex Collateral index
     * @return Collateral price in USD
     */
    function _getCollateralPriceUsd(uint8 _collateralIndex) internal view returns (uint256) {
        return _getMultiCollatDiamond().getCollateralPriceUsd(_collateralIndex);
    }

    /**
     * @dev Returns trade from storage
     * @param _trader Trader address
     * @param _index Trade index
     * @return Trade
     */
    function _getTrade(address _trader, uint32 _index) internal view returns (ITradingStorage.Trade memory) {
        return _getMultiCollatDiamond().getTrade(_trader, _index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IGToken.sol";
import "../interfaces/IGNSMultiCollatDiamond.sol";
import "../interfaces/IGNSStaking.sol";
import "../interfaces/IERC20.sol";

import "./ConstantsUtils.sol";
import "./AddressStoreUtils.sol";
import "./TradingCallbacksUtils.sol";

/**
 * @dev External library for helper functions commonly used in many places
 */
library TradingCommonUtils {
    using SafeERC20 for IERC20;

    // Pure functions

    /**
     * @dev Returns the current percent profit of a trade (1e10 precision)
     * @param _openPrice trade open price (1e10 precision)
     * @param _currentPrice trade current price (1e10 precision)
     * @param _long true for long, false for short
     * @param _leverage trade leverage (1e3 precision)
     */
    function getPnlPercent(
        uint64 _openPrice,
        uint64 _currentPrice,
        bool _long,
        uint24 _leverage
    ) public pure returns (int256 p) {
        int256 pricePrecision = int256(ConstantsUtils.P_10);
        int256 maxPnlP = int256(ConstantsUtils.MAX_PNL_P) * pricePrecision;
        int256 minPnlP = -100 * int256(ConstantsUtils.P_10);

        int256 openPrice = int256(uint256(_openPrice));
        int256 currentPrice = int256(uint256(_currentPrice));
        int256 leverage = int256(uint256(_leverage));

        p = _openPrice > 0
            ? ((_long ? currentPrice - openPrice : openPrice - currentPrice) * 100 * pricePrecision * leverage) /
                openPrice /
                1e3
            : int256(0);

        p = p > maxPnlP ? maxPnlP : p < minPnlP ? minPnlP : p;
    }

    /**
     * @dev Returns position size of trade in collateral tokens (avoids overflow from uint120 collateralAmount)
     * @param _collateralAmount collateral of trade
     * @param _leverage leverage of trade (1e3)
     */
    function getPositionSizeCollateral(uint120 _collateralAmount, uint24 _leverage) public pure returns (uint256) {
        return (uint256(_collateralAmount) * _leverage) / 1e3;
    }

    /**
     * @dev Calculates market execution price for a trade (1e10 precision)
     * @param _price price of the asset (1e10)
     * @param _spreadP spread percentage (1e10)
     * @param _long true if long, false if short
     */
    function getMarketExecutionPrice(uint256 _price, uint256 _spreadP, bool _long) external pure returns (uint256) {
        uint256 priceDiff = (_price * _spreadP) / 100 / ConstantsUtils.P_10;
        return _long ? _price + priceDiff : _price - priceDiff;
    }

    /**
     * @dev Converts collateral value to USD (1e18 precision)
     * @param _collateralAmount amount of collateral (collateral precision)
     * @param _collateralPrecisionDelta precision delta of collateral (10^18/10^decimals)
     * @param _collateralPriceUsd price of collateral in USD (1e8)
     */
    function convertCollateralToUsd(
        uint256 _collateralAmount,
        uint128 _collateralPrecisionDelta,
        uint256 _collateralPriceUsd
    ) public pure returns (uint256) {
        return (_collateralAmount * _collateralPrecisionDelta * _collateralPriceUsd) / 1e8;
    }

    /**
     * @dev Converts collateral value to GNS (1e18 precision)
     * @param _collateralAmount amount of collateral (collateral precision)
     * @param _collateralPrecisionDelta precision delta of collateral (10^18/10^decimals)
     * @param _gnsPriceCollateral price of GNS in collateral (1e10)
     */
    function convertCollateralToGns(
        uint256 _collateralAmount,
        uint128 _collateralPrecisionDelta,
        uint256 _gnsPriceCollateral
    ) public pure returns (uint256) {
        return ((_collateralAmount * _collateralPrecisionDelta * ConstantsUtils.P_10) / _gnsPriceCollateral);
    }

    /**
     * @dev Calculates trade value (useful when closing a trade)
     * @param _collateral amount of collateral (collateral precision)
     * @param _percentProfit profit percentage (1e10)
     * @param _borrowingFeeCollateral borrowing fee in collateral tokens (collateral precision)
     * @param _closingFeeCollateral closing fee in collateral tokens (collateral precision)
     * @param _collateralPrecisionDelta precision delta of collateral (10^18/10^decimals)
     * @param _orderType corresponding pending order type
     */
    function getTradeValuePure(
        uint256 _collateral,
        int256 _percentProfit,
        uint256 _borrowingFeeCollateral,
        uint256 _closingFeeCollateral,
        uint128 _collateralPrecisionDelta,
        ITradingStorage.PendingOrderType _orderType
    ) public pure returns (uint256) {
        if (_orderType == ITradingStorage.PendingOrderType.LIQ_CLOSE) return 0;

        int256 precisionDelta = int256(uint256(_collateralPrecisionDelta));

        // Multiply collateral by precisionDelta so we don't lose precision for low decimals
        int256 value = (int256(_collateral) *
            precisionDelta +
            (int256(_collateral) * precisionDelta * _percentProfit) /
            int256(ConstantsUtils.P_10) /
            100) /
            precisionDelta -
            int256(_borrowingFeeCollateral) -
            int256(_closingFeeCollateral);

        int256 collateralLiqThreshold = (int256(_collateral) * int256(100 - ConstantsUtils.LIQ_THRESHOLD_P)) / 100;

        return value > collateralLiqThreshold ? uint256(value) : 0;
    }

    // View functions

    /**
     * @dev Returns position size of trade in collateral tokens (avoids overflow from uint120 collateralAmount)
     * @param _collateralIndex collateral index
     * @param _pairIndex pair index
     */
    function getMinPositionSizeCollateral(uint8 _collateralIndex, uint256 _pairIndex) public view returns (uint256) {
        return
            _getMultiCollatDiamond().getCollateralFromUsdNormalizedValue(
                _collateralIndex,
                _getMultiCollatDiamond().pairMinPositionSizeUsd(_pairIndex)
            );
    }

    /**
     * @dev Returns position size to use when charging fees
     * @param _collateralIndex collateral index
     * @param _pairIndex pair index
     * @param _positionSizeCollateral trade position size in collateral tokens (collateral precision)
     */
    function getPositionSizeCollateralBasis(
        uint8 _collateralIndex,
        uint256 _pairIndex,
        uint256 _positionSizeCollateral
    ) public view returns (uint256) {
        uint256 minPositionSizeCollateral = getMinPositionSizeCollateral(_collateralIndex, _pairIndex);
        return
            _positionSizeCollateral > minPositionSizeCollateral ? _positionSizeCollateral : minPositionSizeCollateral;
    }

    /**
     * @dev Checks if total position size is not higher than maximum allowed open interest for a pair
     * @param _collateralIndex index of collateral
     * @param _pairIndex index of pair
     * @param _long true if long, false if short
     * @param _positionSizeCollateralDelta position size delta in collateral tokens (collateral precision)
     */
    function isWithinExposureLimits(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long,
        uint256 _positionSizeCollateralDelta
    ) external view returns (bool) {
        return
            _getMultiCollatDiamond().getPairOiCollateral(_collateralIndex, _pairIndex, _long) +
                _positionSizeCollateralDelta <=
            _getMultiCollatDiamond().getPairMaxOiCollateral(_collateralIndex, _pairIndex) &&
            _getMultiCollatDiamond().withinMaxBorrowingGroupOi(
                _collateralIndex,
                _pairIndex,
                _long,
                _positionSizeCollateralDelta
            );
    }

    /**
     * @dev Convenient wrapper to return trade borrowing fee in collateral tokens (collateral precision)
     * @param _trade trade input
     */
    function getTradeBorrowingFeeCollateral(ITradingStorage.Trade memory _trade) public view returns (uint256) {
        return
            _getMultiCollatDiamond().getTradeBorrowingFee(
                IBorrowingFees.BorrowingFeeInput(
                    _trade.collateralIndex,
                    _trade.user,
                    _trade.pairIndex,
                    _trade.index,
                    _trade.long,
                    _trade.collateralAmount,
                    _trade.leverage
                )
            );
    }

    /**
     * @dev Convenient wrapper to return trade liquidation price (1e10)
     * @param _trade trade input
     */
    function getTradeLiquidationPrice(
        ITradingStorage.Trade memory _trade,
        bool _useBorrowingFees
    ) public view returns (uint256) {
        return
            _getMultiCollatDiamond().getTradeLiquidationPrice(
                IBorrowingFees.LiqPriceInput(
                    _trade.collateralIndex,
                    _trade.user,
                    _trade.pairIndex,
                    _trade.index,
                    _trade.openPrice,
                    _trade.long,
                    _trade.collateralAmount,
                    _trade.leverage,
                    _useBorrowingFees
                )
            );
    }

    /**
     * @dev Returns trade value and borrowing fee in collateral tokens
     * @param _trade trade data
     * @param _percentProfit profit percentage (1e10)
     * @param _closingFeesCollateral closing fees in collateral tokens (collateral precision)
     * @param _collateralPrecisionDelta precision delta of collateral (10^18/10^decimals)
     * @param _orderType corresponding pending order type
     */
    function getTradeValueCollateral(
        ITradingStorage.Trade memory _trade,
        int256 _percentProfit,
        uint256 _closingFeesCollateral,
        uint128 _collateralPrecisionDelta,
        ITradingStorage.PendingOrderType _orderType
    ) external view returns (uint256 valueCollateral, uint256 borrowingFeesCollateral) {
        borrowingFeesCollateral = getTradeBorrowingFeeCollateral(_trade);

        valueCollateral = getTradeValuePure(
            _trade.collateralAmount,
            _percentProfit,
            borrowingFeesCollateral,
            _closingFeesCollateral,
            _collateralPrecisionDelta,
            _orderType
        );
    }

    /**
     * @dev Returns gov fee amount in collateral tokens
     * @param _trader address of trader
     * @param _pairIndex index of pair
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     */
    function getGovFeeCollateral(
        address _trader,
        uint32 _pairIndex,
        uint256 _positionSizeCollateral
    ) public view returns (uint256) {
        return
            _getMultiCollatDiamond().calculateFeeAmount(
                _trader,
                (_positionSizeCollateral * _getMultiCollatDiamond().pairOpenFeeP(_pairIndex)) /
                    ConstantsUtils.P_10 /
                    100
            );
    }

    /**
     * @dev Returns vault and gns staking fees in collateral tokens
     * @param _closingFeeCollateral closing fee in collateral tokens (collateral precision)
     * @param _triggerFeeCollateral trigger fee in collateral tokens (collateral precision)
     * @param _orderType corresponding order type
     */
    function getClosingFeesCollateral(
        uint256 _closingFeeCollateral,
        uint256 _triggerFeeCollateral,
        ITradingStorage.PendingOrderType _orderType
    ) public view returns (uint256 vaultClosingFeeCollateral, uint256 gnsStakingFeeCollateral) {
        uint256 vaultClosingFeeP = uint256(TradingCallbacksUtils._getStorage().vaultClosingFeeP);
        vaultClosingFeeCollateral = (_closingFeeCollateral * vaultClosingFeeP) / 100;

        gnsStakingFeeCollateral =
            (ConstantsUtils.isOrderTypeMarket(_orderType) ? _triggerFeeCollateral : (_triggerFeeCollateral * 8) / 10) +
            (_closingFeeCollateral * (100 - vaultClosingFeeP)) /
            100;
    }

    /**
     * @dev Reverts if user initiated any kind of pending market order on his trade
     * @param _user trade user
     * @param _index trade index
     */
    function revertIfTradeHasPendingMarketOrder(address _user, uint32 _index) public view {
        ITradingStorage.PendingOrderType[5] memory pendingOrderTypes = ConstantsUtils.getMarketOrderTypes();
        ITradingStorage.Id memory tradeId = ITradingStorage.Id(_user, _index);

        for (uint256 i; i < pendingOrderTypes.length; ++i) {
            ITradingStorage.PendingOrderType orderType = pendingOrderTypes[i];

            if (_getMultiCollatDiamond().getTradePendingOrderBlock(tradeId, orderType) > 0)
                revert ITradingInteractionsUtils.ConflictingPendingOrder(orderType);
        }
    }

    /**
     * @dev Returns gToken contract for a collateral index
     * @param _collateralIndex collateral index
     */
    function getGToken(uint8 _collateralIndex) public view returns (IGToken) {
        return IGToken(_getMultiCollatDiamond().getGToken(_collateralIndex));
    }

    // Transfers

    /**
     * @dev Transfers collateral from trader
     * @param _collateralIndex index of the collateral
     * @param _from sending address
     * @param _amountCollateral amount of collateral to receive (collateral precision)
     */
    function transferCollateralFrom(uint8 _collateralIndex, address _from, uint256 _amountCollateral) public {
        if (_amountCollateral > 0) {
            IERC20(_getMultiCollatDiamond().getCollateral(_collateralIndex).collateral).safeTransferFrom(
                _from,
                address(this),
                _amountCollateral
            );
        }
    }

    /**
     * @dev Transfers collateral to trader
     * @param _collateralIndex index of the collateral
     * @param _to receiving address
     * @param _amountCollateral amount of collateral to transfer (collateral precision)
     */
    function transferCollateralTo(uint8 _collateralIndex, address _to, uint256 _amountCollateral) public {
        if (_amountCollateral > 0) {
            IERC20(_getMultiCollatDiamond().getCollateral(_collateralIndex).collateral).safeTransfer(
                _to,
                _amountCollateral
            );
        }
    }

    /**
     * @dev Sends collateral to gToken vault for negative pnl
     * @param _collateralIndex collateral index
     * @param _amountCollateral amount of collateral to send to vault (collateral precision)
     * @param _trader trader address
     */
    function sendCollateralToVault(uint8 _collateralIndex, uint256 _amountCollateral, address _trader) public {
        getGToken(_collateralIndex).receiveAssets(_amountCollateral, _trader);
    }

    /**
     * @dev Handles pnl transfers when (fully or partially) closing a trade
     * @param _trade trade struct
     * @param _collateralSentToTrader total amount to send to trader (collateral precision)
     * @param _availableCollateralInDiamond part of _collateralSentToTrader available in diamond balance (collateral precision)
     */
    function handleTradePnl(
        ITradingStorage.Trade memory _trade,
        int256 _collateralSentToTrader,
        int256 _availableCollateralInDiamond,
        uint256 _borrowingFeeCollateral
    ) external returns (uint256 traderDebt) {
        if (_collateralSentToTrader > _availableCollateralInDiamond) {
            getGToken(_trade.collateralIndex).sendAssets(
                uint256(_collateralSentToTrader - _availableCollateralInDiamond),
                _trade.user
            );
            if (_availableCollateralInDiamond >= 0) {
                transferCollateralTo(_trade.collateralIndex, _trade.user, uint256(_availableCollateralInDiamond));
            } else {
                traderDebt = uint256(-_availableCollateralInDiamond);
            }
        } else {
            getGToken(_trade.collateralIndex).receiveAssets(
                uint256(_availableCollateralInDiamond - _collateralSentToTrader),
                _trade.user
            );
            if (_collateralSentToTrader >= 0) {
                transferCollateralTo(_trade.collateralIndex, _trade.user, uint256(_collateralSentToTrader));
            } else {
                traderDebt = uint256(-_collateralSentToTrader);
            }
        }

        emit ITradingCallbacksUtils.BorrowingFeeCharged(_trade.user, _trade.collateralIndex, _borrowingFeeCollateral);
    }

    // Fees

    /**
     * @dev Updates a trader's fee tiers points based on his trade size
     * @param _collateralIndex collateral index
     * @param _trader address of trader
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     * @param _pairIndex index of pair
     */
    function updateFeeTierPoints(
        uint8 _collateralIndex,
        address _trader,
        uint256 _pairIndex,
        uint256 _positionSizeCollateral
    ) public {
        uint256 usdNormalizedPositionSize = _getMultiCollatDiamond().getUsdNormalizedValue(
            _collateralIndex,
            _positionSizeCollateral
        );
        _getMultiCollatDiamond().updateTraderPoints(_trader, usdNormalizedPositionSize, _pairIndex);
    }

    /**
     * @dev Distributes fee to gToken vault
     * @param _collateralIndex index of collateral
     * @param _trader address of trader
     * @param _valueCollateral fee in collateral tokens (collateral precision)
     */
    function distributeVaultFeeCollateral(uint8 _collateralIndex, address _trader, uint256 _valueCollateral) public {
        getGToken(_collateralIndex).distributeReward(_valueCollateral);
        emit ITradingCommonUtils.GTokenFeeCharged(_trader, _collateralIndex, _valueCollateral);
    }

    /**
     * @dev Calculates gov fee amount, charges it, and returns the amount charged (collateral precision)
     * @param _collateralIndex index of collateral
     * @param _trader address of trader
     * @param _pairIndex index of pair
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     * @param _referralFeesCollateral referral fees in collateral tokens (collateral precision)
     */
    function distributeGovFeeCollateral(
        uint8 _collateralIndex,
        address _trader,
        uint32 _pairIndex,
        uint256 _positionSizeCollateral,
        uint256 _referralFeesCollateral
    ) public returns (uint256 govFeeCollateral) {
        govFeeCollateral = getGovFeeCollateral(_trader, _pairIndex, _positionSizeCollateral) - _referralFeesCollateral;
        distributeExactGovFeeCollateral(_collateralIndex, _trader, govFeeCollateral);
    }

    /**
     * @dev Distributes gov fees exact amount
     * @param _collateralIndex index of collateral
     * @param _trader address of trader
     * @param _govFeeCollateral position size in collateral tokens (collateral precision)
     */
    function distributeExactGovFeeCollateral(
        uint8 _collateralIndex,
        address _trader,
        uint256 _govFeeCollateral
    ) public {
        TradingCallbacksUtils._getStorage().pendingGovFees[_collateralIndex] += _govFeeCollateral;
        emit ITradingCommonUtils.GovFeeCharged(_trader, _collateralIndex, _govFeeCollateral);
    }

    /**
     * @dev Distributes GNS staking fee
     * @param _collateralIndex collateral index
     * @param _trader trader address
     * @param _amountCollateral amount of collateral tokens to distribute (collateral precision)
     */
    function distributeGnsStakingFeeCollateral(
        uint8 _collateralIndex,
        address _trader,
        uint256 _amountCollateral
    ) public {
        IGNSStaking(AddressStoreUtils.getAddresses().gnsStaking).distributeReward(
            _getMultiCollatDiamond().getCollateral(_collateralIndex).collateral,
            _amountCollateral
        );
        emit ITradingCommonUtils.GnsStakingFeeCharged(_trader, _collateralIndex, _amountCollateral);
    }

    /**
     * @dev Distributes trigger fee in GNS tokens
     * @param _trader address of trader
     * @param _collateralIndex index of collateral
     * @param _triggerFeeCollateral trigger fee in collateral tokens (collateral precision)
     * @param _gnsPriceCollateral gns/collateral price (1e10 precision)
     * @param _collateralPrecisionDelta collateral precision delta (10^18/10^decimals)
     */
    function distributeTriggerFeeGns(
        address _trader,
        uint8 _collateralIndex,
        uint256 _triggerFeeCollateral,
        uint256 _gnsPriceCollateral,
        uint128 _collateralPrecisionDelta
    ) public {
        uint256 triggerFeeGns = convertCollateralToGns(
            _triggerFeeCollateral,
            _collateralPrecisionDelta,
            _gnsPriceCollateral
        );
        _getMultiCollatDiamond().distributeTriggerReward(triggerFeeGns);

        emit ITradingCommonUtils.TriggerFeeCharged(_trader, _collateralIndex, _triggerFeeCollateral);
    }

    /**
     * @dev Distributes opening fees for trade and returns the total fees charged in collateral tokens
     * @param _trade trade struct
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     * @param _orderType trade order type
     */
    function processOpeningFees(
        ITradingStorage.Trade memory _trade,
        uint256 _positionSizeCollateral,
        ITradingStorage.PendingOrderType _orderType
    ) external returns (uint120 totalFeesCollateral) {
        ITradingCallbacks.Values memory v;
        v.collateralPrecisionDelta = _getMultiCollatDiamond().getCollateral(_trade.collateralIndex).precisionDelta;
        v.gnsPriceCollateral = _getMultiCollatDiamond().getGnsPriceCollateralIndex(_trade.collateralIndex);
        v.positionSizeCollateral = getPositionSizeCollateralBasis(
            _trade.collateralIndex,
            _trade.pairIndex,
            _positionSizeCollateral
        ); // Charge fees on max(min position size, trade position size)

        // 1. Before charging any fee, re-calculate current trader fee tier cache
        updateFeeTierPoints(_trade.collateralIndex, _trade.user, _trade.pairIndex, _positionSizeCollateral);

        // 2. Charge referral fee (if applicable) and send collateral amount to vault
        if (_getMultiCollatDiamond().getTraderActiveReferrer(_trade.user) != address(0)) {
            v.reward1 = distributeReferralFeeCollateral(
                _trade.collateralIndex,
                _trade.user,
                _getMultiCollatDiamond().calculateFeeAmount(_trade.user, v.positionSizeCollateral), // apply fee tiers here to v.positionSizeCollateral itself to make correct calculations inside referrals
                _getMultiCollatDiamond().pairOpenFeeP(_trade.pairIndex),
                v.gnsPriceCollateral
            );

            sendCollateralToVault(_trade.collateralIndex, v.reward1, _trade.user);
            totalFeesCollateral += uint120(v.reward1);

            emit ITradingCommonUtils.ReferralFeeCharged(_trade.user, _trade.collateralIndex, v.reward1);
        }

        // 3. Calculate gov fee (- referral fee if applicable)
        uint256 govFeeCollateral = distributeGovFeeCollateral(
            _trade.collateralIndex,
            _trade.user,
            _trade.pairIndex,
            v.positionSizeCollateral,
            v.reward1 / 2 // half of referral fee taken from gov fee, other half from GNS staking fee
        );

        // 4. Calculate Market/Limit fee
        v.reward2 = _getMultiCollatDiamond().calculateFeeAmount(
            _trade.user,
            (v.positionSizeCollateral * _getMultiCollatDiamond().pairTriggerOrderFeeP(_trade.pairIndex)) /
                100 /
                ConstantsUtils.P_10
        );

        // 5. Deduct gov fee, GNS staking fee (previously dev fee), Market/Limit fee
        totalFeesCollateral += 2 * uint120(govFeeCollateral) + uint120(v.reward2);

        // 6. Distribute Oracle fee and send collateral amount to vault if applicable
        if (!ConstantsUtils.isOrderTypeMarket(_orderType)) {
            v.reward3 = (v.reward2 * 2) / 10; // 20% of limit fees
            sendCollateralToVault(_trade.collateralIndex, v.reward3, _trade.user);

            distributeTriggerFeeGns(
                _trade.user,
                _trade.collateralIndex,
                v.reward3,
                v.gnsPriceCollateral,
                v.collateralPrecisionDelta
            );
        }

        // 7. Distribute GNS staking fee (previous dev fee + market/limit fee - oracle reward)
        distributeGnsStakingFeeCollateral(
            _trade.collateralIndex,
            _trade.user,
            govFeeCollateral + v.reward2 - v.reward3
        );
    }

    /**
     * @dev Distributes closing fees for trade (not used for partials, only full closes)
     * @param _trade trade struct
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     * @param _orderType trade order type
     */
    function processClosingFees(
        ITradingStorage.Trade memory _trade,
        uint256 _positionSizeCollateral,
        ITradingStorage.PendingOrderType _orderType
    ) external returns (ITradingCallbacks.Values memory values) {
        // 1. Calculate closing fees
        values.positionSizeCollateral = getPositionSizeCollateralBasis(
            _trade.collateralIndex,
            _trade.pairIndex,
            _positionSizeCollateral
        ); // Charge fees on max(min position size, trade position size)

        values.closingFeeCollateral = _orderType != ITradingStorage.PendingOrderType.LIQ_CLOSE
            ? (values.positionSizeCollateral * _getMultiCollatDiamond().pairCloseFeeP(_trade.pairIndex)) /
                100 /
                ConstantsUtils.P_10
            : (_trade.collateralAmount * 5) / 100;

        values.triggerFeeCollateral = _orderType != ITradingStorage.PendingOrderType.LIQ_CLOSE
            ? (values.positionSizeCollateral * _getMultiCollatDiamond().pairTriggerOrderFeeP(_trade.pairIndex)) /
                100 /
                ConstantsUtils.P_10
            : values.closingFeeCollateral;

        // 2. Re-calculate current trader fee tier and apply it to closing fees
        updateFeeTierPoints(_trade.collateralIndex, _trade.user, _trade.pairIndex, _positionSizeCollateral);
        if (_orderType != ITradingStorage.PendingOrderType.LIQ_CLOSE) {
            values.closingFeeCollateral = _getMultiCollatDiamond().calculateFeeAmount(
                _trade.user,
                values.closingFeeCollateral
            );
            values.triggerFeeCollateral = _getMultiCollatDiamond().calculateFeeAmount(
                _trade.user,
                values.triggerFeeCollateral
            );
        }

        // 3. Calculate vault fee and GNS staking fee
        (values.reward2, values.reward3) = getClosingFeesCollateral(
            values.closingFeeCollateral,
            values.triggerFeeCollateral,
            _orderType
        );

        // 4. If trade collateral is enough to pay min fee, distribute closing fees (otherwise charged as negative PnL)
        values.collateralLeftInStorage = _trade.collateralAmount;

        if (values.collateralLeftInStorage >= values.reward3 + values.reward2) {
            distributeVaultFeeCollateral(_trade.collateralIndex, _trade.user, values.reward2);
            distributeGnsStakingFeeCollateral(_trade.collateralIndex, _trade.user, values.reward3);

            if (!ConstantsUtils.isOrderTypeMarket(_orderType)) {
                values.gnsPriceCollateral = _getMultiCollatDiamond().getGnsPriceCollateralIndex(_trade.collateralIndex);

                distributeTriggerFeeGns(
                    _trade.user,
                    _trade.collateralIndex,
                    (values.triggerFeeCollateral * 2) / 10,
                    values.gnsPriceCollateral,
                    _getMultiCollatDiamond().getCollateral(_trade.collateralIndex).precisionDelta
                );
            }

            values.collateralLeftInStorage -= values.reward3 + values.reward2;
        }
    }

    /**
     * @dev Distributes referral rewards and returns the amount charged in collateral tokens
     * @param _collateralIndex collateral index
     * @param _trader address of trader
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     * @param _pairOpenFeeP pair open fee percentage (1e10 precision)
     * @param _gnsPriceCollateral gns/collateral price (1e10 precision)
     */
    function distributeReferralFeeCollateral(
        uint8 _collateralIndex,
        address _trader,
        uint256 _positionSizeCollateral, // collateralPrecision
        uint256 _pairOpenFeeP,
        uint256 _gnsPriceCollateral
    ) public returns (uint256 rewardCollateral) {
        return
            _getMultiCollatDiamond().getCollateralFromUsdNormalizedValue(
                _collateralIndex,
                _getMultiCollatDiamond().distributeReferralReward(
                    _trader,
                    _getMultiCollatDiamond().getUsdNormalizedValue(_collateralIndex, _positionSizeCollateral),
                    _pairOpenFeeP,
                    _getMultiCollatDiamond().getGnsPriceUsd(_collateralIndex, _gnsPriceCollateral)
                )
            );
    }

    // Open interests

    /**
     * @dev Add open interest to the protocol (any amount)
     * @dev CAREFUL: this will reset the trade's borrowing fees to 0
     * @param _trade trade struct
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     */
    function addOiCollateral(ITradingStorage.Trade memory _trade, uint256 _positionSizeCollateral) public {
        _getMultiCollatDiamond().handleTradeBorrowingCallback(
            _trade.collateralIndex,
            _trade.user,
            _trade.pairIndex,
            _trade.index,
            _positionSizeCollateral,
            true,
            _trade.long
        );
        _getMultiCollatDiamond().addPriceImpactOpenInterest(_trade.user, _trade.index, _positionSizeCollateral);
    }

    /**
     * @dev Add trade position size OI to the protocol (for new trades)
     * @dev CAREFUL: this will reset the trade's borrowing fees to 0
     * @param _trade trade struct
     */
    function addTradeOiCollateral(ITradingStorage.Trade memory _trade) external {
        addOiCollateral(_trade, getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage));
    }

    /**
     * @dev Remove open interest from the protocol (any amount)
     * @param _trade trade struct
     * @param _positionSizeCollateral position size in collateral tokens (collateral precision)
     */
    function removeOiCollateral(ITradingStorage.Trade memory _trade, uint256 _positionSizeCollateral) public {
        _getMultiCollatDiamond().handleTradeBorrowingCallback(
            _trade.collateralIndex,
            _trade.user,
            _trade.pairIndex,
            _trade.index,
            _positionSizeCollateral,
            false,
            _trade.long
        );
        _getMultiCollatDiamond().removePriceImpactOpenInterest(_trade.user, _trade.index, _positionSizeCollateral);
    }

    /**
     * @dev Remove trade position size OI from the protocol (for full close)
     * @param _trade trade struct
     */
    function removeTradeOiCollateral(ITradingStorage.Trade memory _trade) external {
        removeOiCollateral(_trade, getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage));
    }

    /**
     * @dev Handles OI delta for an existing trade (for trade updates)
     * @param _trade trade struct
     * @param _newPositionSizeCollateral new position size in collateral tokens (collateral precision)
     */
    function handleOiDelta(ITradingStorage.Trade memory _trade, uint256 _newPositionSizeCollateral) external {
        uint256 existingPositionSizeCollateral = getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage);

        if (_newPositionSizeCollateral > existingPositionSizeCollateral) {
            addOiCollateral(_trade, _newPositionSizeCollateral - existingPositionSizeCollateral);
        } else if (_newPositionSizeCollateral < existingPositionSizeCollateral) {
            removeOiCollateral(_trade, existingPositionSizeCollateral - _newPositionSizeCollateral);
        }
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() public view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IGNSMultiCollatDiamond.sol";

import "./StorageUtils.sol";
import "./AddressStoreUtils.sol";
import "./CollateralUtils.sol";
import "./ChainUtils.sol";
import "./TradingCommonUtils.sol";
import "./ConstantsUtils.sol";

/**
 * @dev GNSTradingStorage facet external library
 */

library TradingStorageUtils {
    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function initializeTradingStorage(
        address _gns,
        address _gnsStaking,
        address[] memory _collaterals,
        address[] memory _gTokens
    ) external {
        if (_gns == address(0) || _gnsStaking == address(0)) revert IGeneralErrors.ZeroAddress();

        if (_collaterals.length < 3) revert ITradingStorageUtils.MissingCollaterals();
        if (_collaterals.length != _gTokens.length) revert IGeneralErrors.WrongLength();

        // Set addresses
        IGNSAddressStore.Addresses storage addresses = AddressStoreUtils.getAddresses();
        addresses.gns = _gns;
        addresses.gnsStaking = _gnsStaking;

        emit IGNSAddressStore.AddressesUpdated(addresses);

        // Add collaterals
        for (uint256 i; i < _collaterals.length; ++i) {
            addCollateral(_collaterals[i], _gTokens[i]);
        }

        // Trading is paused by default for state copy
        updateTradingActivated(ITradingStorage.TradingActivated.PAUSED);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateTradingActivated(ITradingStorage.TradingActivated _activated) public {
        _getStorage().tradingActivated = _activated;

        emit ITradingStorageUtils.TradingActivatedUpdated(_activated);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function addCollateral(address _collateral, address _gToken) public {
        ITradingStorage.TradingStorage storage s = _getStorage();
        address staking = AddressStoreUtils.getAddresses().gnsStaking;

        if (s.collateralIndex[_collateral] != 0) revert IGeneralErrors.AlreadyExists();
        if (_collateral == address(0) || _gToken == address(0)) revert IGeneralErrors.ZeroAddress();

        CollateralUtils.CollateralConfig memory collateralConfig = CollateralUtils.getCollateralConfig(_collateral);

        uint8 index = ++s.lastCollateralIndex;

        s.collaterals[index] = ITradingStorage.Collateral({
            collateral: _collateral,
            isActive: true,
            __placeholder: 0,
            precision: collateralConfig.precision,
            precisionDelta: collateralConfig.precisionDelta
        });
        s.gTokens[index] = _gToken;

        s.collateralIndex[_collateral] = index;

        // Setup Staking and GToken approvals
        IERC20 collateral = IERC20(_collateral);
        collateral.approve(_gToken, type(uint256).max);
        collateral.approve(staking, type(uint256).max);

        emit ITradingStorageUtils.CollateralAdded(_collateral, index, _gToken);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function toggleCollateralActiveState(uint8 _collateralIndex) external {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Collateral storage collateral = s.collaterals[_collateralIndex];

        if (collateral.precision == 0) revert IGeneralErrors.DoesntExist();

        bool toggled = !collateral.isActive;
        collateral.isActive = toggled;

        emit ITradingStorageUtils.CollateralUpdated(_collateralIndex, toggled);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateGToken(address _collateral, address _gToken) external {
        ITradingStorage.TradingStorage storage s = _getStorage();

        uint8 index = s.collateralIndex[_collateral];

        if (index == 0) revert IGeneralErrors.DoesntExist();
        if (_gToken == address(0)) revert IGeneralErrors.ZeroAddress();

        // Revoke old vault and approve new vault
        IERC20 collateral = IERC20(_collateral);
        collateral.approve(s.gTokens[index], 0);
        collateral.approve(_gToken, type(uint256).max);

        s.gTokens[index] = _gToken;

        emit ITradingStorageUtils.GTokenUpdated(_collateral, index, _gToken);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function storeTrade(
        ITradingStorage.Trade memory _trade,
        ITradingStorage.TradeInfo memory _tradeInfo
    ) external returns (ITradingStorage.Trade memory) {
        ITradingStorage.TradingStorage storage s = _getStorage();

        _validateTrade(_trade);

        if (_trade.tradeType != ITradingStorage.TradeType.TRADE && _tradeInfo.maxSlippageP == 0)
            revert ITradingStorageUtils.MaxSlippageZero();

        ITradingStorage.Counter memory counter = s.userCounters[_trade.user][ITradingStorage.CounterType.TRADE];

        _trade.index = counter.currentIndex;
        _trade.isOpen = true;
        _trade.tp = _limitTpDistance(_trade.openPrice, _trade.leverage, _trade.tp, _trade.long);
        _trade.sl = _limitSlDistance(_trade.openPrice, _trade.leverage, _trade.sl, _trade.long);

        _tradeInfo.createdBlock = uint32(ChainUtils.getBlockNumber());
        _tradeInfo.tpLastUpdatedBlock = _tradeInfo.createdBlock;
        _tradeInfo.slLastUpdatedBlock = _tradeInfo.createdBlock;
        _tradeInfo.lastOiUpdateTs = 0; // ensure isPartial = false for addPriceImpactOpenInterest

        counter.currentIndex++;
        counter.openCount++;

        s.trades[_trade.user][_trade.index] = _trade;
        s.tradeInfos[_trade.user][_trade.index] = _tradeInfo;
        s.userCounters[_trade.user][ITradingStorage.CounterType.TRADE] = counter;

        if (!s.traderStored[_trade.user]) {
            s.traders.push(_trade.user);
            s.traderStored[_trade.user] = true;
        }

        if (_trade.tradeType == ITradingStorage.TradeType.TRADE) TradingCommonUtils.addTradeOiCollateral(_trade);

        emit ITradingStorageUtils.TradeStored(_trade, _tradeInfo);

        return _trade;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateTradeCollateralAmount(ITradingStorage.Id memory _tradeId, uint120 _collateralAmount) external {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];
        ITradingStorage.TradeInfo storage i = s.tradeInfos[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();
        if (t.tradeType != ITradingStorage.TradeType.TRADE) revert IGeneralErrors.WrongTradeType();
        if (_collateralAmount == 0) revert ITradingStorageUtils.TradePositionSizeZero();

        TradingCommonUtils.handleOiDelta(
            t,
            TradingCommonUtils.getPositionSizeCollateral(_collateralAmount, t.leverage)
        );

        t.collateralAmount = _collateralAmount;
        i.createdBlock = uint32(ChainUtils.getBlockNumber());

        emit ITradingStorageUtils.TradeCollateralUpdated(_tradeId, _collateralAmount);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateTradePosition(
        ITradingStorage.Id memory _tradeId,
        uint120 _collateralAmount,
        uint24 _leverage,
        uint64 _openPrice
    ) external {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];
        ITradingStorage.TradeInfo storage i = s.tradeInfos[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();
        if (t.tradeType != ITradingStorage.TradeType.TRADE) revert IGeneralErrors.WrongTradeType();
        if (_collateralAmount * _leverage == 0) revert ITradingStorageUtils.TradePositionSizeZero();
        if (_openPrice == 0) revert ITradingStorageUtils.TradeOpenPriceZero();

        TradingCommonUtils.handleOiDelta(t, TradingCommonUtils.getPositionSizeCollateral(_collateralAmount, _leverage));

        t.collateralAmount = _collateralAmount;
        t.leverage = _leverage;
        t.openPrice = _openPrice;
        t.tp = _limitTpDistance(t.openPrice, t.leverage, t.tp, t.long);
        t.sl = _limitSlDistance(t.openPrice, t.leverage, t.sl, t.long);

        uint32 blockNumber = uint32(ChainUtils.getBlockNumber());
        i.createdBlock = blockNumber;
        i.tpLastUpdatedBlock = blockNumber;
        i.slLastUpdatedBlock = blockNumber;

        emit ITradingStorageUtils.TradePositionUpdated(
            _tradeId,
            _collateralAmount,
            t.leverage,
            t.openPrice,
            t.tp,
            t.sl
        );
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateOpenOrderDetails(
        ITradingStorage.Id memory _tradeId,
        uint64 _openPrice,
        uint64 _tp,
        uint64 _sl,
        uint16 _maxSlippageP
    ) external {
        ITradingStorage.TradingStorage storage s = _getStorage();

        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];
        ITradingStorage.TradeInfo memory i = s.tradeInfos[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();
        if (t.tradeType == ITradingStorage.TradeType.TRADE) revert IGeneralErrors.WrongTradeType();
        if (_openPrice == 0) revert ITradingStorageUtils.TradeOpenPriceZero();
        if (_tp > 0 && (t.long ? _tp <= _openPrice : _tp >= _openPrice)) revert ITradingStorageUtils.TradeTpInvalid();
        if (_sl > 0 && (t.long ? _sl >= _openPrice : _sl <= _openPrice)) revert ITradingStorageUtils.TradeSlInvalid();
        if (_maxSlippageP == 0) revert ITradingStorageUtils.MaxSlippageZero();

        _tp = _limitTpDistance(_openPrice, t.leverage, _tp, t.long);
        _sl = _limitSlDistance(_openPrice, t.leverage, _sl, t.long);

        t.openPrice = _openPrice;
        t.tp = _tp;
        t.sl = _sl;

        i.maxSlippageP = _maxSlippageP;
        i.createdBlock = uint32(ChainUtils.getBlockNumber());
        i.tpLastUpdatedBlock = i.createdBlock;
        i.slLastUpdatedBlock = i.createdBlock;

        s.tradeInfos[_tradeId.user][_tradeId.index] = i;

        emit ITradingStorageUtils.OpenOrderDetailsUpdated(_tradeId, _openPrice, _tp, _sl, _maxSlippageP);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateTradeTp(ITradingStorage.Id memory _tradeId, uint64 _newTp) external {
        ITradingStorage.TradingStorage storage s = _getStorage();

        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];
        ITradingStorage.TradeInfo storage i = s.tradeInfos[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();
        if (t.tradeType != ITradingStorage.TradeType.TRADE) revert IGeneralErrors.WrongTradeType();

        _newTp = _limitTpDistance(t.openPrice, t.leverage, _newTp, t.long);

        t.tp = _newTp;
        i.tpLastUpdatedBlock = uint32(ChainUtils.getBlockNumber());

        emit ITradingStorageUtils.TradeTpUpdated(_tradeId, _newTp);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function updateTradeSl(ITradingStorage.Id memory _tradeId, uint64 _newSl) external {
        ITradingStorage.TradingStorage storage s = _getStorage();

        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];
        ITradingStorage.TradeInfo storage i = s.tradeInfos[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();
        if (t.tradeType != ITradingStorage.TradeType.TRADE) revert IGeneralErrors.WrongTradeType();

        _newSl = _limitSlDistance(t.openPrice, t.leverage, _newSl, t.long);

        t.sl = _newSl;
        i.slLastUpdatedBlock = uint32(ChainUtils.getBlockNumber());

        emit ITradingStorageUtils.TradeSlUpdated(_tradeId, _newSl);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function closeTrade(ITradingStorage.Id memory _tradeId) external {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Trade storage t = s.trades[_tradeId.user][_tradeId.index];

        if (!t.isOpen) revert IGeneralErrors.DoesntExist();

        t.isOpen = false;
        s.userCounters[_tradeId.user][ITradingStorage.CounterType.TRADE].openCount--;

        if (t.tradeType == ITradingStorage.TradeType.TRADE) TradingCommonUtils.removeTradeOiCollateral(t);

        emit ITradingStorageUtils.TradeClosed(_tradeId);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function storePendingOrder(
        ITradingStorage.PendingOrder memory _pendingOrder
    ) external returns (ITradingStorage.PendingOrder memory) {
        if (_pendingOrder.user == address(0)) revert IGeneralErrors.ZeroAddress();

        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Trade storage t = s.trades[_pendingOrder.trade.user][_pendingOrder.trade.index];

        if (_pendingOrder.orderType == ITradingStorage.PendingOrderType.MARKET_OPEN) {
            _validateTrade(_pendingOrder.trade);

            if (_pendingOrder.maxSlippageP == 0) revert ITradingStorageUtils.MaxSlippageZero();
        } else {
            if (!t.isOpen) revert IGeneralErrors.DoesntExist();

            if (
                _pendingOrder.orderType == ITradingStorage.PendingOrderType.LIMIT_OPEN
                    ? t.tradeType != ITradingStorage.TradeType.LIMIT
                    : _pendingOrder.orderType == ITradingStorage.PendingOrderType.STOP_OPEN
                    ? t.tradeType != ITradingStorage.TradeType.STOP
                    : t.tradeType != ITradingStorage.TradeType.TRADE
            ) revert IGeneralErrors.WrongTradeType();

            if (_pendingOrder.orderType == ITradingStorage.PendingOrderType.SL_CLOSE && t.sl == 0)
                revert ITradingInteractionsUtils.NoSl();

            if (_pendingOrder.orderType == ITradingStorage.PendingOrderType.TP_CLOSE && t.tp == 0)
                revert ITradingInteractionsUtils.NoTp();
        }

        uint256 blockNumber = ChainUtils.getBlockNumber();
        ITradingStorage.Counter memory counter = s.userCounters[_pendingOrder.user][
            ITradingStorage.CounterType.PENDING_ORDER
        ];

        _pendingOrder.index = counter.currentIndex;
        _pendingOrder.isOpen = true;
        _pendingOrder.createdBlock = uint32(blockNumber);

        counter.currentIndex++;
        counter.openCount++;

        s.pendingOrders[_pendingOrder.user][_pendingOrder.index] = _pendingOrder;
        s.userCounters[_pendingOrder.user][ITradingStorage.CounterType.PENDING_ORDER] = counter;

        if (_pendingOrder.orderType != ITradingStorage.PendingOrderType.MARKET_OPEN) {
            s.tradePendingOrderBlock[_pendingOrder.trade.user][_pendingOrder.trade.index][
                _pendingOrder.orderType
            ] = blockNumber;
        }

        if (!s.traderStored[_pendingOrder.user]) {
            s.traders.push(_pendingOrder.user);
            s.traderStored[_pendingOrder.user] = true;
        }

        emit ITradingStorageUtils.PendingOrderStored(_pendingOrder);

        return _pendingOrder;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function closePendingOrder(ITradingStorage.Id memory _orderId) external {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.PendingOrder storage pendingOrder = s.pendingOrders[_orderId.user][_orderId.index];

        if (!pendingOrder.isOpen) revert IGeneralErrors.DoesntExist();

        pendingOrder.isOpen = false;
        s.userCounters[_orderId.user][ITradingStorage.CounterType.PENDING_ORDER].openCount--;

        if (pendingOrder.orderType != ITradingStorage.PendingOrderType.MARKET_OPEN) {
            delete s.tradePendingOrderBlock[pendingOrder.trade.user][pendingOrder.trade.index][pendingOrder.orderType];
        }

        emit ITradingStorageUtils.PendingOrderClosed(_orderId);
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getCollateral(uint8 _index) external view returns (ITradingStorage.Collateral memory) {
        return _getStorage().collaterals[_index];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function isCollateralActive(uint8 _index) public view returns (bool) {
        return _getStorage().collaterals[_index].isActive;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function isCollateralListed(uint8 _index) external view returns (bool) {
        return _getStorage().collaterals[_index].precision > 0;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getCollateralsCount() external view returns (uint8) {
        return _getStorage().lastCollateralIndex;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getCollaterals() external view returns (ITradingStorage.Collateral[] memory) {
        ITradingStorage.TradingStorage storage s = _getStorage();
        ITradingStorage.Collateral[] memory collaterals = new ITradingStorage.Collateral[](s.lastCollateralIndex);

        for (uint8 i = 1; i <= s.lastCollateralIndex; ++i) {
            collaterals[i - 1] = s.collaterals[i];
        }

        return collaterals;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getCollateralIndex(address _collateral) external view returns (uint8) {
        return _getStorage().collateralIndex[_collateral];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTradingActivated() external view returns (ITradingStorage.TradingActivated) {
        return _getStorage().tradingActivated;
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTraderStored(address _trader) external view returns (bool) {
        return _getStorage().traderStored[_trader];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTrade(address _trader, uint32 _index) external view returns (ITradingStorage.Trade memory) {
        return _getStorage().trades[_trader][_index];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTradeInfo(address _trader, uint32 _index) external view returns (ITradingStorage.TradeInfo memory) {
        return _getStorage().tradeInfos[_trader][_index];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getPendingOrder(
        ITradingStorage.Id memory _orderId
    ) external view returns (ITradingStorage.PendingOrder memory) {
        return _getStorage().pendingOrders[_orderId.user][_orderId.index];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getTradePendingOrderBlock(
        ITradingStorage.Id memory _tradeId,
        ITradingStorage.PendingOrderType _orderType
    ) external view returns (uint256) {
        return _getStorage().tradePendingOrderBlock[_tradeId.user][_tradeId.index][_orderType];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getCounters(
        address _trader,
        ITradingStorage.CounterType _type
    ) external view returns (ITradingStorage.Counter memory) {
        return _getStorage().userCounters[_trader][_type];
    }

    /**
     * @dev Check ITradingStorageUtils interface for documentation
     */
    function getGToken(uint8 _collateralIndex) external view returns (address) {
        return _getStorage().gTokens[_collateralIndex];
    }

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_TRADING_STORAGE_SLOT;
    }

    /**
     * @dev Returns storage pointer for storage struct in diamond contract, at defined slot
     */
    function _getStorage() internal pure returns (ITradingStorage.TradingStorage storage s) {
        uint256 storageSlot = _getSlot();
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }

    /**
     * @dev Limits take profit price distance for long/short based on '_openPrice', '_tp, '_leverage' and sets an automatic TP if '_tp' is zero.
     * @param _openPrice trade open price (1e10 precision)
     * @param _leverage trade leverage (1e3 precision)
     * @param _tp trade take profit price (1e10 precision)
     * @param _long trade direction
     */
    function _limitTpDistance(
        uint64 _openPrice,
        uint24 _leverage,
        uint64 _tp,
        bool _long
    ) public pure returns (uint64) {
        if (
            _tp == 0 ||
            TradingCommonUtils.getPnlPercent(_openPrice, _tp, _long, _leverage) ==
            int256(ConstantsUtils.MAX_PNL_P) * int256(ConstantsUtils.P_10)
        ) {
            uint256 openPrice = uint256(_openPrice);
            uint256 tpDiff = (openPrice * ConstantsUtils.MAX_PNL_P * 1e3) / _leverage / 100;
            uint256 newTp = _long ? openPrice + tpDiff : (tpDiff <= openPrice ? openPrice - tpDiff : 0);
            uint64 maxTp = type(uint64).max;
            return newTp > maxTp ? maxTp : uint64(newTp);
        }

        return _tp;
    }

    /**
     * @dev Limits stop loss price distance for long/short based on '_openPrice', '_sl, '_leverage'.
     * @param _openPrice trade open price (1e10 precision)
     * @param _leverage trade leverage (1e3 precision)
     * @param _sl trade stop loss price (1e10 precision)
     * @param _long trade direction
     */
    function _limitSlDistance(
        uint64 _openPrice,
        uint24 _leverage,
        uint64 _sl,
        bool _long
    ) public pure returns (uint64) {
        if (
            _sl > 0 &&
            TradingCommonUtils.getPnlPercent(_openPrice, _sl, _long, _leverage) <
            int256(ConstantsUtils.MAX_SL_P) * int256(ConstantsUtils.P_10) * -1
        ) {
            uint256 openPrice = uint256(_openPrice);
            uint256 slDiff = (openPrice * ConstantsUtils.MAX_SL_P * 1e3) / _leverage / 100;
            uint256 newSl = _long ? openPrice - slDiff : openPrice + slDiff;

            // Here an overflow (for shorts) is actually impossible because _sl is uint64
            // And the new stop loss is always closer (= lower for shorts) than the _sl input

            return uint64(newSl);
        }

        return _sl;
    }

    /**
     * @dev Validation for trade struct (used by storeTrade and storePendingOrder for market open orders)
     * @param _trade trade struct to validate
     */
    function _validateTrade(ITradingStorage.Trade memory _trade) internal view {
        if (_trade.user == address(0)) revert IGeneralErrors.ZeroAddress();

        if (!_getMultiCollatDiamond().isPairIndexListed(_trade.pairIndex))
            revert ITradingStorageUtils.TradePairNotListed();

        if (TradingCommonUtils.getPositionSizeCollateral(_trade.collateralAmount, _trade.leverage) == 0)
            revert ITradingStorageUtils.TradePositionSizeZero();

        if (!isCollateralActive(_trade.collateralIndex)) revert IGeneralErrors.InvalidCollateralIndex();

        if (_trade.openPrice == 0) revert ITradingStorageUtils.TradeOpenPriceZero();

        if (_trade.tp != 0 && (_trade.long ? _trade.tp <= _trade.openPrice : _trade.tp >= _trade.openPrice))
            revert ITradingStorageUtils.TradeTpInvalid();

        if (_trade.sl != 0 && (_trade.long ? _trade.sl >= _trade.openPrice : _trade.sl <= _trade.openPrice))
            revert ITradingStorageUtils.TradeSlInvalid();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../interfaces/IGNSMultiCollatDiamond.sol";

import "../TradingCommonUtils.sol";

/**
 *
 * @dev This is an external library for leverage update lifecycles
 * @dev Used by GNSTrading and GNSTradingCallbacks facets
 */
library UpdateLeverageLifecycles {
    /**
     * @dev Initiate update leverage order, done in 2 steps because need to cancel if liquidation price reached
     * @param _input request decrease leverage input
     */
    function requestUpdateLeverage(IUpdateLeverageUtils.UpdateLeverageInput memory _input) external {
        // 1. Request validation
        (ITradingStorage.Trade memory trade, bool isIncrease, uint256 collateralDelta) = _validateRequest(_input);

        // 2. If decrease leverage, transfer collateral delta to diamond
        if (!isIncrease) TradingCommonUtils.transferCollateralFrom(trade.collateralIndex, trade.user, collateralDelta);

        // 3. Create pending order and make price aggregator request
        ITradingStorage.Id memory orderId = _initiateRequest(trade, _input.newLeverage, collateralDelta);

        emit IUpdateLeverageUtils.LeverageUpdateInitiated(
            orderId,
            _input.user,
            trade.pairIndex,
            _input.index,
            isIncrease,
            _input.newLeverage
        );
    }

    /**
     * @dev Execute update leverage callback
     * @param _order pending order struct
     * @param _answer price aggregator request answer
     */
    function executeUpdateLeverage(
        ITradingStorage.PendingOrder memory _order,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) external {
        // 1. Prepare values
        ITradingStorage.Trade memory pendingTrade = _order.trade;
        ITradingStorage.Trade memory existingTrade = _getMultiCollatDiamond().getTrade(
            pendingTrade.user,
            pendingTrade.index
        );
        bool isIncrease = pendingTrade.leverage > existingTrade.leverage;

        // 2. Refresh trader fee tier cache
        TradingCommonUtils.updateFeeTierPoints(
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            0
        );

        // 3. Prepare useful values
        IUpdateLeverageUtils.UpdateLeverageValues memory values = _prepareCallbackValues(
            existingTrade,
            pendingTrade,
            isIncrease
        );

        // 4. Callback validation
        ITradingCallbacks.CancelReason cancelReason = _validateCallback(existingTrade, values, _answer);

        // 5. If trade exists, charge gov fee and update trade
        if (cancelReason != ITradingCallbacks.CancelReason.NO_TRADE) {
            // 5.1 Distribute gov fee
            TradingCommonUtils.distributeExactGovFeeCollateral(
                existingTrade.collateralIndex,
                existingTrade.user,
                values.govFeeCollateral // use min fee / 2
            );

            // 5.2 Handle callback (update trade in storage, remove gov fee OI, handle collateral delta transfers)
            _handleCallback(existingTrade, pendingTrade, values, cancelReason, isIncrease);
        }

        // 6. Close pending update leverage order
        _getMultiCollatDiamond().closePendingOrder(_answer.orderId);

        emit IUpdateLeverageUtils.LeverageUpdateExecuted(
            _answer.orderId,
            isIncrease,
            cancelReason,
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            existingTrade.index,
            _answer.price,
            pendingTrade.collateralAmount,
            values
        );
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }

    /**
     * @dev Returns new trade collateral amount based on new leverage (collateral precision)
     * @param _existingCollateralAmount existing trade collateral amount (collateral precision)
     * @param _existingLeverage existing trade leverage (1e3)
     * @param _newLeverage new trade leverage (1e3)
     */
    function _getNewCollateralAmount(
        uint256 _existingCollateralAmount,
        uint256 _existingLeverage,
        uint256 _newLeverage
    ) internal pure returns (uint120) {
        return uint120((_existingCollateralAmount * _existingLeverage) / _newLeverage);
    }

    /**
     * @dev Fetches trade, does validation for update leverage request, and returns useful data
     * @param _input request input struct
     */
    function _validateRequest(
        IUpdateLeverageUtils.UpdateLeverageInput memory _input
    ) internal view returns (ITradingStorage.Trade memory trade, bool isIncrease, uint256 collateralDelta) {
        trade = _getMultiCollatDiamond().getTrade(_input.user, _input.index);
        isIncrease = _input.newLeverage > trade.leverage;

        // 1. Check trade exists
        if (!trade.isOpen) revert IGeneralErrors.DoesntExist();

        // 2. Revert if any market order (market close, increase leverage, partial open, partial close) already exists for trade
        TradingCommonUtils.revertIfTradeHasPendingMarketOrder(_input.user, _input.index);

        // 3. Revert if collateral not active
        if (!_getMultiCollatDiamond().isCollateralActive(trade.collateralIndex))
            revert IGeneralErrors.InvalidCollateralIndex();

        // 4. Validate leverage update
        if (
            _input.newLeverage == trade.leverage ||
            (
                isIncrease
                    ? _input.newLeverage > _getMultiCollatDiamond().pairMaxLeverage(trade.pairIndex) * 1e3
                    : _input.newLeverage < _getMultiCollatDiamond().pairMinLeverage(trade.pairIndex) * 1e3
            )
        ) revert ITradingInteractionsUtils.WrongLeverage();

        // 5. Check trade remaining collateral is enough to pay gov fee
        uint256 govFeeCollateral = TradingCommonUtils.getGovFeeCollateral(
            trade.user,
            trade.pairIndex,
            TradingCommonUtils.getMinPositionSizeCollateral(trade.collateralIndex, trade.pairIndex) / 2
        );
        uint256 newCollateralAmount = _getNewCollateralAmount(
            trade.collateralAmount,
            trade.leverage,
            _input.newLeverage
        );
        collateralDelta = isIncrease
            ? trade.collateralAmount - newCollateralAmount
            : newCollateralAmount - trade.collateralAmount;

        if (newCollateralAmount <= govFeeCollateral) revert ITradingInteractionsUtils.InsufficientCollateral();
    }

    /**
     * @dev Stores pending update leverage order and makes price aggregator request
     * @param _trade trade struct
     * @param _newLeverage new leverage (1e3)
     * @param _collateralDelta trade collateral delta (collateral precision)
     */
    function _initiateRequest(
        ITradingStorage.Trade memory _trade,
        uint24 _newLeverage,
        uint256 _collateralDelta
    ) internal returns (ITradingStorage.Id memory orderId) {
        // 1. Store pending order
        ITradingStorage.Trade memory pendingOrderTrade;
        pendingOrderTrade.user = _trade.user;
        pendingOrderTrade.index = _trade.index;
        pendingOrderTrade.leverage = _newLeverage;
        pendingOrderTrade.collateralAmount = uint120(_collateralDelta);

        ITradingStorage.PendingOrder memory pendingOrder;
        pendingOrder.trade = pendingOrderTrade;
        pendingOrder.user = _trade.user;
        pendingOrder.orderType = ITradingStorage.PendingOrderType.UPDATE_LEVERAGE;

        pendingOrder = _getMultiCollatDiamond().storePendingOrder(pendingOrder);
        orderId = ITradingStorage.Id(pendingOrder.user, pendingOrder.index);

        // 2. Request price
        _getMultiCollatDiamond().getPrice(
            _trade.collateralIndex,
            _trade.pairIndex,
            orderId,
            pendingOrder.orderType,
            TradingCommonUtils.getMinPositionSizeCollateral(_trade.collateralIndex, _trade.pairIndex) / 2,
            0
        );
    }

    /**
     * @dev Calculates values for callback
     * @param _existingTrade existing trade struct
     * @param _pendingTrade pending trade struct
     * @param _isIncrease true if increase leverage, false if decrease leverage
     */
    function _prepareCallbackValues(
        ITradingStorage.Trade memory _existingTrade,
        ITradingStorage.Trade memory _pendingTrade,
        bool _isIncrease
    ) internal view returns (IUpdateLeverageUtils.UpdateLeverageValues memory values) {
        if (_existingTrade.isOpen == false) return values;

        values.newLeverage = _pendingTrade.leverage;
        values.govFeeCollateral = TradingCommonUtils.getGovFeeCollateral(
            _existingTrade.user,
            _existingTrade.pairIndex,
            TradingCommonUtils.getMinPositionSizeCollateral(_existingTrade.collateralIndex, _existingTrade.pairIndex) /
                2 // use min fee / 2
        );
        values.newCollateralAmount =
            (
                _isIncrease
                    ? _existingTrade.collateralAmount - _pendingTrade.collateralAmount
                    : _existingTrade.collateralAmount + _pendingTrade.collateralAmount
            ) -
            values.govFeeCollateral;
        values.liqPrice = _getMultiCollatDiamond().getTradeLiquidationPrice(
            IBorrowingFees.LiqPriceInput(
                _existingTrade.collateralIndex,
                _existingTrade.user,
                _existingTrade.pairIndex,
                _existingTrade.index,
                _existingTrade.openPrice,
                _existingTrade.long,
                _isIncrease ? values.newCollateralAmount : _existingTrade.collateralAmount,
                _isIncrease ? values.newLeverage : _existingTrade.leverage,
                true
            )
        ); // for increase leverage we calculate new trade liquidation price and for decrease leverage we calculate existing trade liquidation price
    }

    /**
     * @dev Validates callback, and returns corresponding cancel reason
     * @param _existingTrade existing trade struct
     * @param _values pre-calculated useful values
     * @param _answer price aggregator answer
     */
    function _validateCallback(
        ITradingStorage.Trade memory _existingTrade,
        IUpdateLeverage.UpdateLeverageValues memory _values,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) internal view returns (ITradingCallbacks.CancelReason) {
        return
            !_existingTrade.isOpen ? ITradingCallbacks.CancelReason.NO_TRADE : _answer.price == 0
                ? ITradingCallbacks.CancelReason.MARKET_CLOSED
                : (_existingTrade.long ? _answer.price <= _values.liqPrice : _answer.price >= _values.liqPrice)
                ? ITradingCallbacks.CancelReason.LIQ_REACHED
                : _values.newLeverage > _getMultiCollatDiamond().pairMaxLeverage(_existingTrade.pairIndex) * 1e3
                ? ITradingCallbacks.CancelReason.MAX_LEVERAGE
                : ITradingCallbacks.CancelReason.NONE;
    }

    /**
     * @dev Handles trade update, removes gov fee OI, and transfers collateral delta (for both successful and failed requests)
     * @param _trade trade struct
     * @param _pendingTrade pending trade struct
     * @param _values pre-calculated useful values
     * @param _cancelReason cancel reason
     * @param _isIncrease true if increase leverage, false if decrease leverage
     */
    function _handleCallback(
        ITradingStorage.Trade memory _trade,
        ITradingStorage.Trade memory _pendingTrade,
        IUpdateLeverageUtils.UpdateLeverageValues memory _values,
        ITradingCallbacks.CancelReason _cancelReason,
        bool _isIncrease
    ) internal {
        // 1. Request successful
        if (_cancelReason == ITradingCallbacks.CancelReason.NONE) {
            // 1. Request successful
            // 1.1 Update trade collateral (- gov fee) and leverage, openPrice stays the same
            _getMultiCollatDiamond().updateTradePosition(
                ITradingStorage.Id(_trade.user, _trade.index),
                uint120(_values.newCollateralAmount),
                uint24(_values.newLeverage),
                _trade.openPrice
            );

            // 1.2 If leverage increase, transfer collateral delta to trader
            if (_isIncrease)
                TradingCommonUtils.transferCollateralTo(
                    _trade.collateralIndex,
                    _trade.user,
                    _pendingTrade.collateralAmount
                );
        } else {
            // 2. Request canceled
            // 2.1 Remove gov fee from trade collateral
            _getMultiCollatDiamond().updateTradeCollateralAmount(
                ITradingStorage.Id(_trade.user, _trade.index),
                _trade.collateralAmount - uint120(_values.govFeeCollateral)
            );
            // 2.2 If leverage decrease, send back collateral delta to trader
            if (!_isIncrease)
                TradingCommonUtils.transferCollateralTo(
                    _trade.collateralIndex,
                    _trade.user,
                    _pendingTrade.collateralAmount
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../interfaces/IGNSMultiCollatDiamond.sol";
import "../../interfaces/IERC20.sol";

import "../ConstantsUtils.sol";
import "../TradingCommonUtils.sol";

/**
 *
 * @dev This is an internal utils library for position size decreases
 * @dev Used by UpdatePositionSizeLifecycles internal library
 */
library DecreasePositionSizeUtils {
    /**
     * @dev Validates decrease position size request
     *
     * @dev Possible inputs: collateral delta > 0 and leverage delta = 0 (decrease collateral by collateral delta)
     *                       collateral delta = 0 and leverage delta > 0 (decrease leverage by leverage delta)
     *
     *  @param _trade trade of request
     *  @param _input input values
     */
    function validateRequest(
        ITradingStorage.Trade memory _trade,
        IUpdatePositionSizeUtils.DecreasePositionSizeInput memory _input
    ) internal view returns (uint256 positionSizeCollateralDelta) {
        // 1. Revert if both collateral and leverage are zero or if both are non-zero
        if (
            (_input.collateralDelta == 0 && _input.leverageDelta == 0) ||
            (_input.collateralDelta > 0 && _input.leverageDelta > 0)
        ) revert IUpdatePositionSizeUtils.InvalidDecreasePositionSizeInput();

        // 2. If we update the leverage, check new leverage is above the minimum
        bool isLeverageUpdate = _input.leverageDelta > 0;
        if (
            isLeverageUpdate &&
            _trade.leverage - _input.leverageDelta < _getMultiCollatDiamond().pairMinLeverage(_trade.pairIndex) * 1e3
        ) revert ITradingInteractionsUtils.WrongLeverage();

        // 3. Make sure new trade collateral is enough to pay borrowing fees and closing fees
        positionSizeCollateralDelta = TradingCommonUtils.getPositionSizeCollateral(
            isLeverageUpdate ? _trade.collateralAmount : _input.collateralDelta,
            isLeverageUpdate ? _input.leverageDelta : _trade.leverage
        );

        uint256 newCollateralAmount = _trade.collateralAmount - _input.collateralDelta;
        uint256 borrowingFeeCollateral = TradingCommonUtils.getTradeBorrowingFeeCollateral(_trade);
        uint256 closingFeesCollateral = ((_getMultiCollatDiamond().pairCloseFeeP(_trade.pairIndex) +
            _getMultiCollatDiamond().pairTriggerOrderFeeP(_trade.pairIndex)) *
            TradingCommonUtils.getPositionSizeCollateralBasis(
                _trade.collateralIndex,
                _trade.pairIndex,
                positionSizeCollateralDelta
            )) /
            ConstantsUtils.P_10 /
            100;

        if (newCollateralAmount <= borrowingFeeCollateral + closingFeesCollateral)
            revert ITradingInteractionsUtils.InsufficientCollateral();
    }

    /**
     * @dev Calculates values for callback
     * @param _existingTrade existing trade data
     * @param _partialTrade partial trade data
     * @param _answer price aggregator answer
     */
    function prepareCallbackValues(
        ITradingStorage.Trade memory _existingTrade,
        ITradingStorage.Trade memory _partialTrade,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) internal view returns (IUpdatePositionSizeUtils.DecreasePositionSizeValues memory values) {
        // 1. Calculate position size delta and existing position size
        bool isLeverageUpdate = _partialTrade.leverage > 0;
        values.positionSizeCollateralDelta = TradingCommonUtils.getPositionSizeCollateral(
            isLeverageUpdate ? _existingTrade.collateralAmount : _partialTrade.collateralAmount,
            isLeverageUpdate ? _partialTrade.leverage : _existingTrade.leverage
        );
        values.existingPositionSizeCollateral = TradingCommonUtils.getPositionSizeCollateral(
            _existingTrade.collateralAmount,
            _existingTrade.leverage
        );

        // 2. Calculate existing trade liquidation price
        values.existingLiqPrice = TradingCommonUtils.getTradeLiquidationPrice(_existingTrade, true);

        // 3. Calculate existing trade pnl
        values.existingPnlCollateral =
            (TradingCommonUtils.getPnlPercent(
                _existingTrade.openPrice,
                _answer.price,
                _existingTrade.long,
                _existingTrade.leverage
            ) * int256(uint256(_existingTrade.collateralAmount))) /
            100 /
            int256(ConstantsUtils.P_10);

        // 4. Calculate existing trade borrowing fee
        values.borrowingFeeCollateral = TradingCommonUtils.getTradeBorrowingFeeCollateral(_existingTrade);

        // 5. Calculate partial trade closing fees

        // 5.1 Apply fee tiers
        uint256 pairCloseFeeP = _getMultiCollatDiamond().calculateFeeAmount(
            _existingTrade.user,
            _getMultiCollatDiamond().pairCloseFeeP(_existingTrade.pairIndex)
        );
        uint256 pairTriggerFeeP = _getMultiCollatDiamond().calculateFeeAmount(
            _existingTrade.user,
            _getMultiCollatDiamond().pairTriggerOrderFeeP(_existingTrade.pairIndex)
        );

        // 5.2 Calculate closing fees on on max(positionSizeCollateralDelta, minPositionSizeCollateral)
        uint256 feePositionSizeCollateralBasis = TradingCommonUtils.getPositionSizeCollateralBasis(
            _existingTrade.collateralIndex,
            _existingTrade.pairIndex,
            values.positionSizeCollateralDelta
        );
        (values.vaultFeeCollateral, values.gnsStakingFeeCollateral) = TradingCommonUtils.getClosingFeesCollateral(
            (feePositionSizeCollateralBasis * pairCloseFeeP) / 100 / ConstantsUtils.P_10,
            (feePositionSizeCollateralBasis * pairTriggerFeeP) / 100 / ConstantsUtils.P_10,
            ITradingStorage.PendingOrderType.MARKET_PARTIAL_CLOSE
        );

        // 6. Calculate final collateral delta
        // Collateral delta = value to send to trader after position size is decreased
        int256 partialTradePnlCollateral = (values.existingPnlCollateral * int256(values.positionSizeCollateralDelta)) /
            int256(values.existingPositionSizeCollateral);

        values.availableCollateralInDiamond =
            int256(uint256(_partialTrade.collateralAmount)) -
            int256(values.vaultFeeCollateral) -
            int256(values.gnsStakingFeeCollateral);

        values.collateralSentToTrader =
            values.availableCollateralInDiamond +
            partialTradePnlCollateral -
            int256(values.borrowingFeeCollateral);

        // 7. Calculate new collateral amount and leverage
        values.newCollateralAmount = _existingTrade.collateralAmount - _partialTrade.collateralAmount;
        values.newLeverage = _existingTrade.leverage - _partialTrade.leverage;
    }

    /**
     * @dev Validates callback, and returns corresponding cancel reason
     * @param _values pre-calculated useful values
     */
    function validateCallback(
        ITradingStorage.Trade memory _existingTrade,
        IUpdatePositionSizeUtils.DecreasePositionSizeValues memory _values,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) internal pure returns (ITradingCallbacks.CancelReason) {
        return
            (
                _existingTrade.long
                    ? _answer.price <= _values.existingLiqPrice
                    : _answer.price >= _values.existingLiqPrice
            )
                ? ITradingCallbacks.CancelReason.LIQ_REACHED
                : ITradingCallbacks.CancelReason.NONE;
    }

    /**
     * @dev Updates trade (for successful request)
     * @param _existingTrade existing trade data
     * @param _values pre-calculated useful values
     */
    function updateTradeSuccess(
        ITradingStorage.Trade memory _existingTrade,
        IUpdatePositionSizeUtils.DecreasePositionSizeValues memory _values
    ) internal {
        // 1. Handle collateral/pnl transfers
        uint256 traderDebt = TradingCommonUtils.handleTradePnl(
            _existingTrade,
            _values.collateralSentToTrader,
            _values.availableCollateralInDiamond,
            _values.borrowingFeeCollateral
        );
        _values.newCollateralAmount -= uint120(traderDebt); // eg. when fees > partial collateral

        // 2. Update trade in storage
        _getMultiCollatDiamond().updateTradePosition(
            ITradingStorage.Id(_existingTrade.user, _existingTrade.index),
            _values.newCollateralAmount,
            _values.newLeverage,
            _existingTrade.openPrice // open price stays the same
        );

        // 3. Reset trade borrowing fee to zero
        _getMultiCollatDiamond().resetTradeBorrowingFees(
            _existingTrade.collateralIndex,
            _existingTrade.user,
            _existingTrade.pairIndex,
            _existingTrade.index,
            _existingTrade.long
        );
    }

    /**
     * @dev Handles callback canceled case (for failed request)
     * @param _existingTrade trade to update
     * @param _cancelReason cancel reason
     */
    function handleCanceled(
        ITradingStorage.Trade memory _existingTrade,
        ITradingCallbacks.CancelReason _cancelReason
    ) internal {
        if (_cancelReason != ITradingCallbacks.CancelReason.NO_TRADE) {
            // 1. Distribute gov fee
            uint256 govFeeCollateral = TradingCommonUtils.distributeGovFeeCollateral(
                _existingTrade.collateralIndex,
                _existingTrade.user,
                _existingTrade.pairIndex,
                TradingCommonUtils.getMinPositionSizeCollateral(
                    _existingTrade.collateralIndex,
                    _existingTrade.pairIndex
                ) / 2, // use min fee / 2
                0
            );

            // 2. Charge gov fee to trade
            _getMultiCollatDiamond().updateTradeCollateralAmount(
                ITradingStorage.Id(_existingTrade.user, _existingTrade.index),
                _existingTrade.collateralAmount - uint120(govFeeCollateral)
            );
        }
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../interfaces/IGNSMultiCollatDiamond.sol";
import "../../interfaces/IERC20.sol";

import "../ConstantsUtils.sol";
import "../TradingCommonUtils.sol";

/**
 *
 * @dev This is an internal utils library for position size increases
 * @dev Used by UpdatePositionSizeLifecycles internal library
 */
library IncreasePositionSizeUtils {
    /**
     * @dev Validates increase position request.
     *
     * @dev Possible inputs: collateral delta > 0 and leverage delta > 0 (increase position size by collateral delta * leverage delta)
     *                       collateral delta = 0 and leverage delta > 0 (increase trade leverage by leverage delta)
     *
     * @param _trade trade of request
     * @param _input input values
     */
    function validateRequest(
        ITradingStorage.Trade memory _trade,
        IUpdatePositionSizeUtils.IncreasePositionSizeInput memory _input
    ) internal view returns (uint256 positionSizeCollateralDelta) {
        // 1. Zero values checks
        if (_input.leverageDelta == 0 || _input.expectedPrice == 0 || _input.maxSlippageP == 0)
            revert IUpdatePositionSizeUtils.InvalidIncreasePositionSizeInput();

        // 2. Revert if new leverage is below min leverage or above max leverage
        bool isLeverageUpdate = _input.collateralDelta == 0;
        {
            uint24 leverageToValidate = isLeverageUpdate
                ? _trade.leverage + _input.leverageDelta
                : _input.leverageDelta;
            if (
                leverageToValidate > _getMultiCollatDiamond().pairMaxLeverage(_trade.pairIndex) * 1e3 ||
                leverageToValidate < _getMultiCollatDiamond().pairMinLeverage(_trade.pairIndex) * 1e3
            ) revert ITradingInteractionsUtils.WrongLeverage();
        }

        // 3. Make sure new position size is bigger than existing one after paying borrowing and opening fees
        positionSizeCollateralDelta = TradingCommonUtils.getPositionSizeCollateral(
            isLeverageUpdate ? _trade.collateralAmount : _input.collateralDelta,
            _input.leverageDelta
        );
        uint256 existingPositionSizeCollateral = TradingCommonUtils.getPositionSizeCollateral(
            _trade.collateralAmount,
            _trade.leverage
        );
        uint256 newCollateralAmount = _trade.collateralAmount + _input.collateralDelta;
        uint256 newLeverage = isLeverageUpdate
            ? _trade.leverage + _input.leverageDelta
            : ((existingPositionSizeCollateral + positionSizeCollateralDelta) * 1e3) / newCollateralAmount;
        {
            uint256 borrowingFeeCollateral = TradingCommonUtils.getTradeBorrowingFeeCollateral(_trade);
            uint256 openingFeesCollateral = ((_getMultiCollatDiamond().pairOpenFeeP(_trade.pairIndex) *
                2 +
                _getMultiCollatDiamond().pairTriggerOrderFeeP(_trade.pairIndex)) *
                TradingCommonUtils.getPositionSizeCollateralBasis(
                    _trade.collateralIndex,
                    _trade.pairIndex,
                    positionSizeCollateralDelta
                )) /
                ConstantsUtils.P_10 /
                100;

            uint256 newPositionSizeCollateral = existingPositionSizeCollateral +
                positionSizeCollateralDelta -
                ((borrowingFeeCollateral + openingFeesCollateral) * newLeverage) /
                1e3;

            if (newPositionSizeCollateral <= existingPositionSizeCollateral)
                revert IUpdatePositionSizeUtils.NewPositionSizeSmaller();
        }

        // 4. Make sure trade stays within exposure limits
        if (
            !TradingCommonUtils.isWithinExposureLimits(
                _trade.collateralIndex,
                _trade.pairIndex,
                _trade.long,
                positionSizeCollateralDelta
            )
        ) revert ITradingInteractionsUtils.AboveExposureLimits();
    }

    /**
     * @dev Calculates values for callback
     * @param _existingTrade existing trade data
     * @param _partialTrade partial trade data
     * @param _answer price aggregator answer
     */
    function prepareCallbackValues(
        ITradingStorage.Trade memory _existingTrade,
        ITradingStorage.Trade memory _partialTrade,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) internal view returns (IUpdatePositionSizeUtils.IncreasePositionSizeValues memory values) {
        bool isLeverageUpdate = _partialTrade.collateralAmount == 0;

        // 1. Calculate position size values
        values.positionSizeCollateralDelta = TradingCommonUtils.getPositionSizeCollateral(
            isLeverageUpdate ? _existingTrade.collateralAmount : _partialTrade.collateralAmount,
            _partialTrade.leverage
        );
        values.existingPositionSizeCollateral = TradingCommonUtils.getPositionSizeCollateral(
            _existingTrade.collateralAmount,
            _existingTrade.leverage
        );
        values.newPositionSizeCollateral = values.existingPositionSizeCollateral + values.positionSizeCollateralDelta;

        // 2. Calculate new collateral amount and leverage
        values.newCollateralAmount = _existingTrade.collateralAmount + _partialTrade.collateralAmount;
        values.newLeverage = isLeverageUpdate
            ? _existingTrade.leverage + _partialTrade.leverage
            : (values.newPositionSizeCollateral * 1e3) / values.newCollateralAmount;

        // 3. Calculate price impact values
        (, values.priceAfterImpact) = _getMultiCollatDiamond().getTradePriceImpact(
            TradingCommonUtils.getMarketExecutionPrice(_answer.price, _answer.spreadP, _existingTrade.long),
            _existingTrade.pairIndex,
            _existingTrade.long,
            _getMultiCollatDiamond().getUsdNormalizedValue(
                _existingTrade.collateralIndex,
                values.positionSizeCollateralDelta
            )
        );

        // 4. Calculate existing trade pnl
        values.existingPnlCollateral =
            (TradingCommonUtils.getPnlPercent(
                _existingTrade.openPrice,
                _answer.price,
                _existingTrade.long,
                _existingTrade.leverage
            ) * int256(uint256(_existingTrade.collateralAmount))) /
            100 /
            int256(ConstantsUtils.P_10);

        // 5. Calculate existing trade borrowing fee
        values.borrowingFeeCollateral = TradingCommonUtils.getTradeBorrowingFeeCollateral(_existingTrade);

        // 6. Calculate partial trade opening fees

        // 6.1 Apply fee tiers
        uint256 pairOpenFeeP = _getMultiCollatDiamond().calculateFeeAmount(
            _existingTrade.user,
            _getMultiCollatDiamond().pairOpenFeeP(_existingTrade.pairIndex)
        );
        uint256 pairTriggerFeeP = _getMultiCollatDiamond().calculateFeeAmount(
            _existingTrade.user,
            _getMultiCollatDiamond().pairTriggerOrderFeeP(_existingTrade.pairIndex)
        );

        // 6.2 Calculate opening fees on on max(positionSizeCollateralDelta, minPositionSizeCollateral)
        values.openingFeesCollateral =
            ((pairOpenFeeP * 2 + pairTriggerFeeP) *
                TradingCommonUtils.getPositionSizeCollateralBasis(
                    _existingTrade.collateralIndex,
                    _existingTrade.pairIndex,
                    values.positionSizeCollateralDelta
                )) /
            100 /
            ConstantsUtils.P_10;

        // 7. Charge opening fees and borrowing fees on new trade collateral amount
        values.newCollateralAmount -= values.borrowingFeeCollateral + values.openingFeesCollateral;

        // 8. Calculate new open price

        // existingPositionSizeCollateral + existingPnlCollateral can never be negative
        // Because minimum value for existingPnlCollateral is -100% of trade collateral
        uint256 positionSizePlusPnlCollateral = values.existingPnlCollateral < 0
            ? values.existingPositionSizeCollateral - uint256(values.existingPnlCollateral * -1)
            : values.existingPositionSizeCollateral + uint256(values.existingPnlCollateral);

        values.newOpenPrice =
            (positionSizePlusPnlCollateral *
                uint256(_existingTrade.openPrice) +
                values.positionSizeCollateralDelta *
                values.priceAfterImpact) /
            (positionSizePlusPnlCollateral + values.positionSizeCollateralDelta);

        // 8. Calculate existing and new liq price
        values.existingLiqPrice = TradingCommonUtils.getTradeLiquidationPrice(_existingTrade, true);
        values.newLiqPrice = _getMultiCollatDiamond().getTradeLiquidationPrice(
            IBorrowingFees.LiqPriceInput(
                _existingTrade.collateralIndex,
                _existingTrade.user,
                _existingTrade.pairIndex,
                _existingTrade.index,
                uint64(values.newOpenPrice),
                _existingTrade.long,
                values.newCollateralAmount,
                values.newLeverage,
                false
            )
        );
    }

    /**
     * @dev Validates callback, and returns corresponding cancel reason
     * @param _existingTrade existing trade data
     * @param _values pre-calculated useful values
     * @param _expectedPrice user expected price before callback (1e10)
     * @param _maxSlippageP maximum slippage percentage from expected price (1e3)
     */
    function validateCallback(
        ITradingStorage.Trade memory _existingTrade,
        IUpdatePositionSizeUtils.IncreasePositionSizeValues memory _values,
        ITradingCallbacks.AggregatorAnswer memory _answer,
        uint256 _expectedPrice,
        uint256 _maxSlippageP
    ) internal view returns (ITradingCallbacks.CancelReason cancelReason) {
        uint256 maxSlippage = (uint256(_expectedPrice) * _maxSlippageP) / 100 / 1e3;

        cancelReason = (
            _existingTrade.long
                ? _values.priceAfterImpact > _expectedPrice + maxSlippage
                : _values.priceAfterImpact < _expectedPrice - maxSlippage
        )
            ? ITradingCallbacks.CancelReason.SLIPPAGE // 1. Check price after impact is within slippage limits
            : _existingTrade.tp > 0 &&
                (_existingTrade.long ? _answer.price >= _existingTrade.tp : _answer.price <= _existingTrade.tp)
            ? ITradingCallbacks.CancelReason.TP_REACHED // 2. Check TP has not been reached
            : _existingTrade.sl > 0 &&
                (_existingTrade.long ? _answer.price <= _existingTrade.sl : _answer.price >= _existingTrade.sl)
            ? ITradingCallbacks.CancelReason.SL_REACHED // 3. Check SL has not been reached
            : (
                _existingTrade.long
                    ? (_answer.price <= _values.existingLiqPrice || _answer.price <= _values.newLiqPrice)
                    : (_answer.price >= _values.existingLiqPrice || _answer.price >= _values.newLiqPrice)
            )
            ? ITradingCallbacks.CancelReason.LIQ_REACHED // 4. Check current and new LIQ price not reached
            : !TradingCommonUtils.isWithinExposureLimits(
                _existingTrade.collateralIndex,
                _existingTrade.pairIndex,
                _existingTrade.long,
                _values.positionSizeCollateralDelta
            )
            ? ITradingCallbacks.CancelReason.EXPOSURE_LIMITS // 5. Check trade still within exposure limits
            : _values.newLeverage > _getMultiCollatDiamond().pairMaxLeverage(_existingTrade.pairIndex) * 1e3
            ? ITradingCallbacks.CancelReason.MAX_LEVERAGE
            : ITradingCallbacks.CancelReason.NONE;
    }

    /**
     * @dev Updates trade (for successful request)
     * @param _existingTrade existing trade data
     * @param _values pre-calculated useful values
     */
    function updateTradeSuccess(
        ITradingStorage.Trade memory _existingTrade,
        IUpdatePositionSizeUtils.IncreasePositionSizeValues memory _values
    ) internal {
        // 1. Send borrowing fee to vault
        TradingCommonUtils.handleTradePnl(
            _existingTrade,
            0, // collateralSentToTrader = 0
            int256(_values.borrowingFeeCollateral),
            _values.borrowingFeeCollateral
        );

        // 2. Update trade in storage
        _getMultiCollatDiamond().updateTradePosition(
            ITradingStorage.Id(_existingTrade.user, _existingTrade.index),
            uint120(_values.newCollateralAmount),
            uint24(_values.newLeverage),
            uint64(_values.newOpenPrice)
        );

        // 3. Reset trade borrowing fees to zero
        _getMultiCollatDiamond().resetTradeBorrowingFees(
            _existingTrade.collateralIndex,
            _existingTrade.user,
            _existingTrade.pairIndex,
            _existingTrade.index,
            _existingTrade.long
        );
    }

    /**
     * @dev Handles callback canceled case (for failed request)
     * @param _existingTrade existing trade data
     * @param _partialTrade partial trade data
     * @param _cancelReason cancel reason
     */
    function handleCanceled(
        ITradingStorage.Trade memory _existingTrade,
        ITradingStorage.Trade memory _partialTrade,
        ITradingCallbacks.CancelReason _cancelReason
    ) internal {
        // 1. Charge gov fee on trade (if trade exists)
        if (_cancelReason != ITradingCallbacks.CancelReason.NO_TRADE) {
            // 1.1 Distribute gov fee
            uint256 govFeeCollateral = TradingCommonUtils.distributeGovFeeCollateral(
                _existingTrade.collateralIndex,
                _existingTrade.user,
                _existingTrade.pairIndex,
                TradingCommonUtils.getMinPositionSizeCollateral(
                    _existingTrade.collateralIndex,
                    _existingTrade.pairIndex
                ) / 2, // use min fee / 2
                0
            );

            // 1.3 Charge gov fee to trade
            _getMultiCollatDiamond().updateTradeCollateralAmount(
                ITradingStorage.Id(_existingTrade.user, _existingTrade.index),
                _existingTrade.collateralAmount - uint120(govFeeCollateral)
            );
        }

        // 2. Send back partial collateral to trader
        TradingCommonUtils.transferCollateralTo(
            _existingTrade.collateralIndex,
            _existingTrade.user,
            _partialTrade.collateralAmount
        );
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../../interfaces/IGNSMultiCollatDiamond.sol";

import "./IncreasePositionSizeUtils.sol";
import "./DecreasePositionSizeUtils.sol";

import "../ChainUtils.sol";
import "../ConstantsUtils.sol";
import "../TradingCommonUtils.sol";

/**
 *
 * @dev This is an external library for position size updates lifecycles
 * @dev Used by GNSTrading and GNSTradingCallbacks facets
 */
library UpdatePositionSizeLifecycles {
    /**
     * @dev Initiate increase position size order, done in 2 steps because position size changes
     * @param _input request increase position size input struct
     */
    function requestIncreasePositionSize(IUpdatePositionSizeUtils.IncreasePositionSizeInput memory _input) external {
        // 1. Base validation
        ITradingStorage.Trade memory trade = _baseValidateRequest(_input.user, _input.index);

        // 2. Increase position size validation
        uint256 positionSizeCollateralDelta = IncreasePositionSizeUtils.validateRequest(trade, _input);

        // 3. Transfer collateral delta from trader to diamond contract (nothing transferred for leverage update)
        TradingCommonUtils.transferCollateralFrom(trade.collateralIndex, _input.user, _input.collateralDelta);

        // 4. Create pending order and make price aggregator request
        ITradingStorage.Id memory orderId = _initiateRequest(
            trade,
            true,
            _input.collateralDelta,
            _input.leverageDelta,
            positionSizeCollateralDelta,
            _input.expectedPrice,
            _input.maxSlippageP
        );

        emit IUpdatePositionSizeUtils.PositionSizeUpdateInitiated(
            orderId,
            trade.user,
            trade.pairIndex,
            trade.index,
            true,
            _input.collateralDelta,
            _input.leverageDelta
        );
    }

    /**
     * @dev Initiate decrease position size order, done in 2 steps because position size changes
     * @param _input request decrease position size input struct
     */
    function requestDecreasePositionSize(IUpdatePositionSizeUtils.DecreasePositionSizeInput memory _input) external {
        // 1. Base validation
        ITradingStorage.Trade memory trade = _baseValidateRequest(_input.user, _input.index);

        // 2. Decrease position size validation
        uint256 positionSizeCollateralDelta = DecreasePositionSizeUtils.validateRequest(trade, _input);

        // 3. Store pending order and make price aggregator request
        ITradingStorage.Id memory orderId = _initiateRequest(
            trade,
            false,
            _input.collateralDelta,
            _input.leverageDelta,
            positionSizeCollateralDelta,
            0,
            0
        );

        emit IUpdatePositionSizeUtils.PositionSizeUpdateInitiated(
            orderId,
            trade.user,
            trade.pairIndex,
            trade.index,
            false,
            _input.collateralDelta,
            _input.leverageDelta
        );
    }

    /**
     * @dev Execute increase position size market callback
     * @param _order corresponding pending order
     * @param _answer price aggregator answer
     */
    function executeIncreasePositionSizeMarket(
        ITradingStorage.PendingOrder memory _order,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) external {
        // 1. Prepare vars
        ITradingStorage.Trade memory partialTrade = _order.trade;
        ITradingStorage.Trade memory existingTrade = _getMultiCollatDiamond().getTrade(
            partialTrade.user,
            partialTrade.index
        );
        IUpdatePositionSizeUtils.IncreasePositionSizeValues memory values;

        // 2. Refresh trader fee tier cache
        TradingCommonUtils.updateFeeTierPoints(
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            0
        );

        // 3. Base validation (trade open, market open)
        ITradingCallbacks.CancelReason cancelReason = _validateBaseFulfillment(existingTrade, _answer);

        // 4. If passes base validation, validate further
        if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
            // 4.1 Prepare useful values (position size delta, pnl, fees, new open price, etc.)
            values = IncreasePositionSizeUtils.prepareCallbackValues(existingTrade, partialTrade, _answer);

            // 4.2 Further validation
            cancelReason = IncreasePositionSizeUtils.validateCallback(
                existingTrade,
                values,
                _answer,
                partialTrade.openPrice,
                _order.maxSlippageP
            );

            // 5. If passes further validation, execute callback
            if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
                // 5.1 Update trade collateral / leverage / open price in storage, and reset trade borrowing fees
                IncreasePositionSizeUtils.updateTradeSuccess(existingTrade, values);

                // 5.2 Distribute opening fees and store fee tier points for position size delta
                TradingCommonUtils.processOpeningFees(
                    existingTrade,
                    values.positionSizeCollateralDelta,
                    _order.orderType
                );
            }
        }

        // 6. If didn't pass validation, charge gov fee (if trade exists) and return partial collateral (if any)
        if (cancelReason != ITradingCallbacks.CancelReason.NONE)
            IncreasePositionSizeUtils.handleCanceled(existingTrade, partialTrade, cancelReason);

        // 7. Close pending increase position size order
        _getMultiCollatDiamond().closePendingOrder(_answer.orderId);

        emit IUpdatePositionSizeUtils.PositionSizeIncreaseExecuted(
            _answer.orderId,
            cancelReason,
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            existingTrade.index,
            _answer.price,
            partialTrade.collateralAmount,
            partialTrade.leverage,
            values
        );
    }

    /**
     * @dev Execute decrease position size market callback
     * @param _order corresponding pending order
     * @param _answer price aggregator answer
     */
    function executeDecreasePositionSizeMarket(
        ITradingStorage.PendingOrder memory _order,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) external {
        // 1. Prepare vars
        ITradingStorage.Trade memory partialTrade = _order.trade;
        ITradingStorage.Trade memory existingTrade = _getMultiCollatDiamond().getTrade(
            partialTrade.user,
            partialTrade.index
        );
        IUpdatePositionSizeUtils.DecreasePositionSizeValues memory values;

        // 2. Refresh trader fee tier cache
        TradingCommonUtils.updateFeeTierPoints(
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            0
        );

        // 3. Base validation (trade open, market open)
        ITradingCallbacks.CancelReason cancelReason = _validateBaseFulfillment(existingTrade, _answer);

        // 4. If passes base validation, validate further
        if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
            // 4.1 Prepare useful values (position size delta, closing fees, borrowing fees, etc.)
            values = DecreasePositionSizeUtils.prepareCallbackValues(existingTrade, partialTrade, _answer);

            // 4.2 Further validation
            cancelReason = DecreasePositionSizeUtils.validateCallback(existingTrade, values, _answer);

            // 5. If passes further validation, execute callback
            if (cancelReason == ITradingCallbacks.CancelReason.NONE) {
                // 5.1 Send collateral delta (partial trade value - fees) if positive or remove from trade collateral if negative
                // Then update trade collateral / leverage in storage, and reset trade borrowing fees
                DecreasePositionSizeUtils.updateTradeSuccess(existingTrade, values);

                // 5.2 Distribute closing fees
                TradingCommonUtils.distributeGnsStakingFeeCollateral(
                    existingTrade.collateralIndex,
                    existingTrade.user,
                    values.gnsStakingFeeCollateral
                );
                TradingCommonUtils.distributeVaultFeeCollateral(
                    existingTrade.collateralIndex,
                    existingTrade.user,
                    values.vaultFeeCollateral
                );

                // 5.3 Store trader fee tier points for position size delta
                TradingCommonUtils.updateFeeTierPoints(
                    existingTrade.collateralIndex,
                    existingTrade.user,
                    existingTrade.pairIndex,
                    values.positionSizeCollateralDelta
                );
            }
        }

        // 6. If didn't pass validation and trade exists, charge gov fee and remove corresponding OI
        if (cancelReason != ITradingCallbacks.CancelReason.NONE)
            DecreasePositionSizeUtils.handleCanceled(existingTrade, cancelReason);

        // 7. Close pending decrease position size order
        _getMultiCollatDiamond().closePendingOrder(_answer.orderId);

        emit IUpdatePositionSizeUtils.PositionSizeDecreaseExecuted(
            _answer.orderId,
            cancelReason,
            existingTrade.collateralIndex,
            existingTrade.user,
            existingTrade.pairIndex,
            existingTrade.index,
            _answer.price,
            partialTrade.collateralAmount,
            partialTrade.leverage,
            values
        );
    }

    /**
     * @dev Returns current address as multi-collateral diamond interface to call other facets functions.
     */
    function _getMultiCollatDiamond() internal view returns (IGNSMultiCollatDiamond) {
        return IGNSMultiCollatDiamond(address(this));
    }

    /**
     * @dev Basic validation for increase/decrease position size request
     * @param _trader trader address
     * @param _index trade index
     */
    function _baseValidateRequest(
        address _trader,
        uint32 _index
    ) internal view returns (ITradingStorage.Trade memory trade) {
        trade = _getMultiCollatDiamond().getTrade(_trader, _index);

        // 1. Check trade exists
        if (!trade.isOpen) revert IGeneralErrors.DoesntExist();

        // 2. Revert if any market order (market close, increase leverage, partial open, partial close) already exists for trade
        TradingCommonUtils.revertIfTradeHasPendingMarketOrder(_trader, _index);

        // 3. Revert if collateral not active
        if (!_getMultiCollatDiamond().isCollateralActive(trade.collateralIndex))
            revert IGeneralErrors.InvalidCollateralIndex();
    }

    /**
     * @dev Creates pending order, makes price aggregator request, and returns corresponding pending order id
     * @param _trade trade to update
     * @param _isIncrease whether is increase or decrease position size order
     * @param _collateralAmount partial trade collateral amount (collateral precision)
     * @param _leverage partial trade leverage (1e3)
     * @param _positionSizeCollateralDelta position size delta in collateral tokens (collateral precision)
     * @param _expectedPrice reference price for max slippage check (1e10), only useful for increase position size
     * @param _maxSlippageP max slippage % (1e3), only useful for increase position size
     */
    function _initiateRequest(
        ITradingStorage.Trade memory _trade,
        bool _isIncrease,
        uint120 _collateralAmount,
        uint24 _leverage,
        uint256 _positionSizeCollateralDelta,
        uint64 _expectedPrice,
        uint16 _maxSlippageP
    ) internal returns (ITradingStorage.Id memory orderId) {
        // 1. Initialize partial trade
        ITradingStorage.Trade memory pendingOrderTrade;
        pendingOrderTrade.user = _trade.user;
        pendingOrderTrade.index = _trade.index;
        pendingOrderTrade.collateralAmount = _collateralAmount;
        pendingOrderTrade.leverage = _leverage;
        pendingOrderTrade.openPrice = _expectedPrice; // useful for max slippage checks

        // 2. Store pending order
        ITradingStorage.PendingOrder memory pendingOrder;
        pendingOrder.trade = pendingOrderTrade;
        pendingOrder.user = _trade.user;
        pendingOrder.orderType = _isIncrease
            ? ITradingStorage.PendingOrderType.MARKET_PARTIAL_OPEN
            : ITradingStorage.PendingOrderType.MARKET_PARTIAL_CLOSE;
        pendingOrder.maxSlippageP = _maxSlippageP;

        pendingOrder = _getMultiCollatDiamond().storePendingOrder(pendingOrder);
        orderId = ITradingStorage.Id(pendingOrder.user, pendingOrder.index);

        // 3. Make price aggregator request
        _getMultiCollatDiamond().getPrice(
            _trade.collateralIndex,
            _trade.pairIndex,
            orderId,
            pendingOrder.orderType,
            _positionSizeCollateralDelta,
            0
        );
    }

    /**
     * @dev Basic validation for callbacks, returns corresponding cancel reason
     * @param _trade trade struct
     * @param _answer price aggegator answer
     */
    function _validateBaseFulfillment(
        ITradingStorage.Trade memory _trade,
        ITradingCallbacks.AggregatorAnswer memory _answer
    ) internal pure returns (ITradingCallbacks.CancelReason) {
        return
            !_trade.isOpen ? ITradingCallbacks.CancelReason.NO_TRADE : _answer.price == 0
                ? ITradingCallbacks.CancelReason.MARKET_CLOSED
                : ITradingCallbacks.CancelReason.NONE;
    }
}