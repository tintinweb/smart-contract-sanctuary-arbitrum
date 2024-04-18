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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/IGNSAddressStore.sol";

/**
 * @custom:version 8
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

import "../../interfaces/libraries/IBorrowingFeesUtils.sol";

import "../../libraries/BorrowingFeesUtils.sol";

/**
 * @custom:version 8
 * @dev Facet #9: Borrowing Fees and open interests
 */
contract GNSBorrowingFees is GNSAddressStore, IBorrowingFeesUtils {
    // Initialization

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Management Setters

    /// @inheritdoc IBorrowingFeesUtils
    function setBorrowingPairParams(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        BorrowingPairParams calldata _value
    ) external onlyRole(Role.MANAGER) {
        BorrowingFeesUtils.setBorrowingPairParams(_collateralIndex, _pairIndex, _value);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function setBorrowingPairParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        BorrowingPairParams[] calldata _values
    ) external onlyRole(Role.MANAGER) {
        BorrowingFeesUtils.setBorrowingPairParamsArray(_collateralIndex, _indices, _values);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function setBorrowingGroupParams(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        BorrowingGroupParams calldata _value
    ) external onlyRole(Role.MANAGER) {
        BorrowingFeesUtils.setBorrowingGroupParams(_collateralIndex, _groupIndex, _value);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function setBorrowingGroupParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        BorrowingGroupParams[] calldata _values
    ) external onlyRole(Role.MANAGER) {
        BorrowingFeesUtils.setBorrowingGroupParamsArray(_collateralIndex, _indices, _values);
    }

    // Interactions

    /// @inheritdoc IBorrowingFeesUtils
    function handleTradeBorrowingCallback(
        uint8 _collateralIndex,
        address _trader,
        uint16 _pairIndex,
        uint32 _index,
        uint256 _positionSizeCollateral,
        bool _open,
        bool _long
    ) external virtual onlySelf {
        BorrowingFeesUtils.handleTradeBorrowingCallback(
            _collateralIndex,
            _trader,
            _pairIndex,
            _index,
            _positionSizeCollateral,
            _open,
            _long
        );
    }

    // Getters

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingPairPendingAccFees(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 pairAccFeeDelta) {
        return BorrowingFeesUtils.getBorrowingPairPendingAccFees(_collateralIndex, _pairIndex, _currentBlock);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingGroupPendingAccFees(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        uint256 _currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 groupAccFeeDelta) {
        return BorrowingFeesUtils.getBorrowingGroupPendingAccFees(_collateralIndex, _groupIndex, _currentBlock);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getTradeBorrowingFee(BorrowingFeeInput memory _input) public view returns (uint256 feeAmountCollateral) {
        return BorrowingFeesUtils.getTradeBorrowingFee(_input);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getTradeLiquidationPrice(LiqPriceInput calldata _input) external view returns (uint256) {
        return BorrowingFeesUtils.getTradeLiquidationPrice(_input);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getPairOisCollateral(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) public view returns (uint256 longOi, uint256 shortOi) {
        return BorrowingFeesUtils.getPairOisCollateral(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingPairGroupIndex(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) public view returns (uint16 groupIndex) {
        return BorrowingFeesUtils.getBorrowingPairGroupIndex(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getPairOiCollateral(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long
    ) external view returns (uint256) {
        return BorrowingFeesUtils.getPairOiCollateral(_collateralIndex, _pairIndex, _long);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function withinMaxBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long,
        uint256 _positionSizeCollateral
    ) external view returns (bool) {
        return
            BorrowingFeesUtils.withinMaxBorrowingGroupOi(_collateralIndex, _pairIndex, _long, _positionSizeCollateral);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingGroup(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) external view returns (BorrowingData memory) {
        return BorrowingFeesUtils.getBorrowingGroup(_collateralIndex, _groupIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) external view returns (OpenInterest memory) {
        return BorrowingFeesUtils.getBorrowingGroupOi(_collateralIndex, _groupIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingPair(uint8 _collateralIndex, uint16 _pairIndex) external view returns (BorrowingData memory) {
        return BorrowingFeesUtils.getBorrowingPair(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingPairOi(uint8 _collateralIndex, uint16 _pairIndex) external view returns (OpenInterest memory) {
        return BorrowingFeesUtils.getBorrowingPairOi(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingPairGroups(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) external view returns (BorrowingPairGroup[] memory) {
        return BorrowingFeesUtils.getBorrowingPairGroups(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getAllBorrowingPairs(
        uint8 _collateralIndex
    ) external view returns (BorrowingData[] memory, OpenInterest[] memory, BorrowingPairGroup[][] memory) {
        return BorrowingFeesUtils.getAllBorrowingPairs(_collateralIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingGroups(
        uint8 _collateralIndex,
        uint16[] calldata _indices
    ) external view returns (BorrowingData[] memory, OpenInterest[] memory) {
        return BorrowingFeesUtils.getBorrowingGroups(_collateralIndex, _indices);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getBorrowingInitialAccFees(
        uint8 _collateralIndex,
        address _trader,
        uint32 _index
    ) external view returns (BorrowingInitialAccFees memory) {
        return BorrowingFeesUtils.getBorrowingInitialAccFees(_collateralIndex, _trader, _index);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getPairMaxOi(uint8 _collateralIndex, uint16 _pairIndex) external view returns (uint256) {
        return BorrowingFeesUtils.getPairMaxOi(_collateralIndex, _pairIndex);
    }

    /// @inheritdoc IBorrowingFeesUtils
    function getPairMaxOiCollateral(uint8 _collateralIndex, uint16 _pairIndex) external view returns (uint256) {
        return BorrowingFeesUtils.getPairMaxOiCollateral(_collateralIndex, _pairIndex);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 6.3.2
 * @dev Interface for Arbitrum special l2 functions
 */
interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 5
 * @dev Interface for Chainlink feeds
 */
interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
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
 * @custom:version 8
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
 * @custom:version 8
 * @dev the non-expanded interface for multi-collat diamond, only contains types/structs/enums
 */

interface IGNSDiamond is IGNSAddressStore, IGNSDiamondCut, IGNSDiamondLoupe, ITypes {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./types/IDiamondStorage.sol";

/**
 * @custom:version 8
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
 * @custom:version 8
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
 * @custom:version 8
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

import "../types/IBorrowingFees.sol";

/**
 * @custom:version 8
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
 * @custom:version 8
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
 * @custom:version 8
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
 * @custom:version 8
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
     * @param _gnsCollateralUniV3Pools corresponding GNS/collateral Uniswap V3 pools addresses
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
        IUniswapV3Pool[] memory _gnsCollateralUniV3Pools,
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
     * @dev Updates collateral/GNS Uniswap V3 pool
     * @param _collateralIndex collateral index
     * @param _uniV3Pool new value
     */
    function updateCollateralGnsUniV3Pool(uint8 _collateralIndex, IUniswapV3Pool _uniV3Pool) external;

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
     * @dev Returns collateral/gns uni v3 pool info
     * @param _collateralIndex index of collateral
     */
    function getCollateralGnsUniV3Pool(uint8 _collateralIndex) external view returns (UniV3PoolInfo memory);

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
    event CollateralGnsUniV3PoolUpdated(uint8 collateralIndex, UniV3PoolInfo newValue);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/IPriceImpact.sol";

/**
 * @custom:version 8
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
     * @dev Adds open interest to a window
     * @param _openInterestUsd open interest of trade in USD (1e18 precision)
     * @param _pairIndex index of pair
     * @param _long true for long, false for short
     */
    function addPriceImpactOpenInterest(uint256 _openInterestUsd, uint256 _pairIndex, bool _long) external;

    /**
     * @dev Removes open interest from a window
     * @param _openInterestUsd open interest of trade in USD (1e18 precision)
     * @param _pairIndex index of pair
     * @param _long true for long, false for short
     * @param _addTs timestamp of when the trade open interest was added (to remove from same window)
     */
    function removePriceImpactOpenInterest(
        uint256 _openInterestUsd, // 1e18 USD
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external;

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
     */
    event PriceImpactOpenInterestAdded(IPriceImpact.OiWindowUpdate oiWindowUpdate);

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
 * @custom:version 8
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

/**
 * @custom:version 8
 * @dev Interface for GNSTradingCallbacks facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITradingCallbacksUtils is ITradingCallbacks {
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
     * @dev Executes a pending open trigger order callback (for limit/stop orders)
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function executeTriggerOpenOrderCallback(AggregatorAnswer memory _a) external;

    /**
     * @dev Executes a pending close trigger order callback (for tp/sl/liq orders)
     * @param _a the price aggregator answer (order id, price, etc.)
     */
    function executeTriggerCloseOrderCallback(AggregatorAnswer memory _a) external;

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
    event TriggerFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

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
    event GTokenFeeCharged(address indexed trader, uint8 indexed collateralIndex, uint256 amountCollateral);

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

import "../types/ITradingInteractions.sol";
import "../types/ITradingStorage.sol";

/**
 * @custom:version 8
 * @dev Interface for GNSTradingInteractions facet (inherits types and also contains functions, events, and custom errors)
 */
interface ITradingInteractionsUtils is ITradingInteractions {
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
     * @dev Safety function in case oracles don't answer in time, allows caller to claim back the collateral of a pending open market order
     * @param _orderId the id of the pending open market order to be canceled
     */
    function openTradeMarketTimeout(ITradingStorage.Id memory _orderId) external;

    /**
     * @dev Safety function in case oracles don't answer in time, allows caller to initiate another market close order for the same open trade
     * @param _orderId the id of the pending close market order to be canceled
     */
    function closeTradeMarketTimeout(ITradingStorage.Id memory _orderId) external;

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
    error AbovePairMaxOi();
    error AboveGroupMaxOi();
    error CollateralNotActive();
    error BelowMinPositionSizeUsd();
    error PriceImpactTooHigh();
    error NoTrade();
    error NoOrder();
    error WrongOrderType();
    error AlreadyBeingMarketClosed();
    error WrongLeverage();
    error WrongTp();
    error WrongSl();
    error WaitTimeout();
    error PendingTrigger();
    error NoSl();
    error NoTp();
    error NotYourOrder();
    error DelegatedActionNotAllowed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../types/ITradingStorage.sol";

/**
 * @custom:version 8
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
     * @dev Pure function that returns the pending order type (market open/limit open/stop open) for a trade type (trade/limit/stop)
     * @param _tradeType the trade type
     */
    function getPendingOpenOrderType(TradeType _tradeType) external pure returns (PendingOrderType);

    /**
     * @dev Returns the address of the gToken for a collateral stack
     * @param _collateralIndex the index of the supported collateral
     */
    function getGToken(uint8 _collateralIndex) external view returns (address);

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
    ) external pure returns (int256);

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
 * @custom:version 8
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

/**
 * @custom:version 8
 * @dev Interface for BlockManager_Mock contract (test helper)
 */
interface IBlockManager_Mock {
    function getBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
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
 * @custom:version 8
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
        uint24 leverage; // 1e3
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
 * @custom:version 8
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
 * @custom:version 8
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
        uint256 spreadP; // PRECISION
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
        uint256 openFeeP; // PRECISION (% of position size)
        uint256 closeFeeP; // PRECISION (% of position size)
        uint256 oracleFeeP; // PRECISION (% of position size)
        uint256 triggerOrderFeeP; // PRECISION (% of position size)
        uint256 minPositionSizeUsd; // 1e18 (collateral x leverage, useful for min fee)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "./ITradingStorage.sol";
import "../IChainlinkFeed.sol";

/**
 * @custom:version 8
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
        mapping(uint8 => UniV3PoolInfo) collateralGnsUniV3Pools;
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

    struct UniV3PoolInfo {
        IUniswapV3Pool pool; // 160 bits
        bool isGnsToken0InLp; // 8 bits
        uint88 __placeholder; // 88 bits
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
 * @dev Contains the types for the GNSPriceImpact facet
 */
interface IPriceImpact {
    struct PriceImpactStorage {
        OiWindowsSettings oiWindowsSettings;
        mapping(uint48 => mapping(uint256 => mapping(uint256 => PairOi))) windows; // duration => pairIndex => windowId => Oi
        mapping(uint256 => PairDepth) pairDepths; // pairIndex => depth (USD)
        uint256[47] __gap;
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
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
 * @custom:version 8
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
        NOT_HIT
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
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @custom:version 8
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
 * @custom:version 8
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
        LIQ_CLOSE
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
 * @custom:version 8
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

import "../interfaces/IGNSMultiCollatDiamond.sol";

import "./StorageUtils.sol";
import "./ChainUtils.sol";

/**
 * @custom:version 8
 *
 * @dev GNSBorrowingFees facet internal library
 */
library BorrowingFeesUtils {
    uint256 internal constant LIQ_THRESHOLD_P = 90; // -90% pnl
    uint256 internal constant P_1 = 1e10;

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function setBorrowingPairParams(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        IBorrowingFees.BorrowingPairParams calldata _value
    ) internal validCollateralIndex(_collateralIndex) {
        _setBorrowingPairParams(_collateralIndex, _pairIndex, _value);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function setBorrowingPairParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        IBorrowingFees.BorrowingPairParams[] calldata _values
    ) internal validCollateralIndex(_collateralIndex) {
        uint256 len = _indices.length;
        if (len != _values.length) {
            revert IGeneralErrors.WrongLength();
        }

        for (uint256 i; i < len; ++i) {
            _setBorrowingPairParams(_collateralIndex, _indices[i], _values[i]);
        }
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function setBorrowingGroupParams(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        IBorrowingFees.BorrowingGroupParams calldata _value
    ) internal validCollateralIndex(_collateralIndex) {
        _setBorrowingGroupParams(_collateralIndex, _groupIndex, _value);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function setBorrowingGroupParamsArray(
        uint8 _collateralIndex,
        uint16[] calldata _indices,
        IBorrowingFees.BorrowingGroupParams[] calldata _values
    ) internal validCollateralIndex(_collateralIndex) {
        uint256 len = _indices.length;
        if (len != _values.length) {
            revert IGeneralErrors.WrongLength();
        }

        for (uint256 i; i < len; ++i) {
            _setBorrowingGroupParams(_collateralIndex, _indices[i], _values[i]);
        }
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function handleTradeBorrowingCallback(
        uint8 _collateralIndex,
        address _trader,
        uint16 _pairIndex,
        uint32 _index,
        uint256 _positionSizeCollateral,
        bool _open,
        bool _long
    ) internal validCollateralIndex(_collateralIndex) {
        (uint64 pairAccFeeLong, uint64 pairAccFeeShort) = _setPairPendingAccFees(
            _collateralIndex,
            _pairIndex,
            ChainUtils.getBlockNumber()
        );
        (uint64 groupAccFeeLong, uint64 groupAccFeeShort) = _setGroupPendingAccFees(
            _collateralIndex,
            getBorrowingPairGroupIndex(_collateralIndex, _pairIndex),
            ChainUtils.getBlockNumber()
        );

        _updatePairOi(_collateralIndex, _pairIndex, _long, _open, _positionSizeCollateral);

        _updateGroupOi(
            _collateralIndex,
            getBorrowingPairGroupIndex(_collateralIndex, _pairIndex),
            _long,
            _open,
            _positionSizeCollateral
        );

        if (_open) {
            IBorrowingFees.BorrowingInitialAccFees memory initialFees = IBorrowingFees.BorrowingInitialAccFees(
                _long ? pairAccFeeLong : pairAccFeeShort,
                _long ? groupAccFeeLong : groupAccFeeShort,
                ChainUtils.getUint48BlockNumber(ChainUtils.getBlockNumber()),
                0 // placeholder
            );

            _getStorage().initialAccFees[_collateralIndex][_trader][_index] = initialFees;

            emit IBorrowingFeesUtils.BorrowingInitialAccFeesStored(
                _collateralIndex,
                _trader,
                _pairIndex,
                _index,
                initialFees.accPairFee,
                initialFees.accGroupFee
            );
        }

        emit IBorrowingFeesUtils.TradeBorrowingCallbackHandled(
            _collateralIndex,
            _trader,
            _pairIndex,
            _index,
            _open,
            _long,
            _positionSizeCollateral
        );
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingPairPendingAccFees(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _currentBlock
    ) internal view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 pairAccFeeDelta) {
        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();
        IBorrowingFees.BorrowingData memory pair = s.pairs[_collateralIndex][_pairIndex];

        (uint256 pairOiLong, uint256 pairOiShort) = getPairOisCollateral(_collateralIndex, _pairIndex);

        (accFeeLong, accFeeShort, pairAccFeeDelta) = _getBorrowingPendingAccFees(
            IBorrowingFees.PendingBorrowingAccFeesInput(
                pair.accFeeLong,
                pair.accFeeShort,
                pairOiLong,
                pairOiShort,
                pair.feePerBlock,
                _currentBlock,
                pair.accLastUpdatedBlock,
                s.pairOis[_collateralIndex][_pairIndex].max,
                pair.feeExponent,
                _getMultiCollatDiamond().getCollateral(_collateralIndex).precision
            )
        );
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingGroupPendingAccFees(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        uint256 _currentBlock
    ) internal view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 groupAccFeeDelta) {
        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();

        IBorrowingFees.BorrowingData memory group = s.groups[_collateralIndex][_groupIndex];
        IBorrowingFees.OpenInterest memory groupOi = s.groupOis[_collateralIndex][_groupIndex];

        uint128 collateralPrecision = _getMultiCollatDiamond().getCollateral(_collateralIndex).precision;

        (accFeeLong, accFeeShort, groupAccFeeDelta) = _getBorrowingPendingAccFees(
            IBorrowingFees.PendingBorrowingAccFeesInput(
                group.accFeeLong,
                group.accFeeShort,
                (uint256(groupOi.long) * collateralPrecision) / P_1,
                (uint256(groupOi.short) * collateralPrecision) / P_1,
                group.feePerBlock,
                _currentBlock,
                group.accLastUpdatedBlock,
                groupOi.max,
                group.feeExponent,
                collateralPrecision
            )
        );
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getTradeBorrowingFee(
        IBorrowingFees.BorrowingFeeInput memory _input
    ) internal view returns (uint256 feeAmountCollateral) {
        IBorrowingFees.BorrowingInitialAccFees memory initialFees = _getStorage().initialAccFees[
            _input.collateralIndex
        ][_input.trader][_input.index];
        IBorrowingFees.BorrowingPairGroup[] memory pairGroups = _getStorage().pairGroups[_input.collateralIndex][
            _input.pairIndex
        ];

        IBorrowingFees.BorrowingPairGroup memory firstPairGroup;
        if (pairGroups.length > 0) {
            firstPairGroup = pairGroups[0];
        }

        uint256 borrowingFeeP; // 1e10 %

        // If pair has had no group after trade was opened, initialize with pair borrowing fee
        if (pairGroups.length == 0 || firstPairGroup.block > initialFees.block) {
            borrowingFeeP = ((
                pairGroups.length == 0
                    ? _getBorrowingPairPendingAccFee(
                        _input.collateralIndex,
                        _input.pairIndex,
                        ChainUtils.getBlockNumber(),
                        _input.long
                    )
                    : (_input.long ? firstPairGroup.pairAccFeeLong : firstPairGroup.pairAccFeeShort)
            ) - initialFees.accPairFee);
        }

        // Sum of max(pair fee, group fee) for all groups the pair was in while trade was open
        for (uint256 i = pairGroups.length; i > 0; --i) {
            (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) = _getBorrowingPairGroupAccFeesDeltas(
                _input.collateralIndex,
                i - 1,
                pairGroups,
                initialFees,
                _input.pairIndex,
                _input.long,
                ChainUtils.getBlockNumber()
            );

            borrowingFeeP += (deltaGroup > deltaPair ? deltaGroup : deltaPair);

            // Exit loop at first group before trade was open
            if (beforeTradeOpen) break;
        }

        feeAmountCollateral = (_input.collateral * _input.leverage * borrowingFeeP) / 1e3 / P_1 / 100; // collateral precision
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getTradeLiquidationPrice(IBorrowingFees.LiqPriceInput calldata _input) internal view returns (uint256) {
        return
            _getTradeLiquidationPrice(
                _input.openPrice,
                _input.long,
                _input.collateral,
                _input.leverage,
                getTradeBorrowingFee(
                    IBorrowingFees.BorrowingFeeInput(
                        _input.collateralIndex,
                        _input.trader,
                        _input.pairIndex,
                        _input.index,
                        _input.long,
                        _input.collateral,
                        _input.leverage
                    )
                ),
                _getMultiCollatDiamond().getCollateral(_input.collateralIndex).precisionDelta
            );
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getPairOisCollateral(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) internal view returns (uint256 longOiCollateral, uint256 shortOiCollateral) {
        IBorrowingFees.OpenInterest storage pairOi = _getStorage().pairOis[_collateralIndex][_pairIndex];
        ITradingStorageUtils.Collateral memory collateralConfig = _getMultiCollatDiamond().getCollateral(
            _collateralIndex
        );
        return ((pairOi.long * collateralConfig.precision) / P_1, (pairOi.short * collateralConfig.precision) / P_1);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingPairGroupIndex(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) internal view returns (uint16 groupIndex) {
        IBorrowingFees.BorrowingPairGroup[] memory pairGroups = _getStorage().pairGroups[_collateralIndex][_pairIndex];
        return pairGroups.length == 0 ? 0 : pairGroups[pairGroups.length - 1].groupIndex;
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getPairOiCollateral(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long
    ) internal view returns (uint256) {
        (uint256 longOiCollateral, uint256 shortOiCollateral) = getPairOisCollateral(_collateralIndex, _pairIndex);
        return _long ? longOiCollateral : shortOiCollateral;
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function withinMaxBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long,
        uint256 _positionSizeCollateral
    ) internal view returns (bool) {
        IBorrowingFees.OpenInterest memory groupOi = _getStorage().groupOis[_collateralIndex][
            getBorrowingPairGroupIndex(_collateralIndex, _pairIndex)
        ];

        return
            (groupOi.max == 0) ||
            ((_long ? groupOi.long : groupOi.short) +
                (_positionSizeCollateral * P_1) /
                _getMultiCollatDiamond().getCollateral(_collateralIndex).precision <=
                groupOi.max);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingGroup(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) internal view returns (IBorrowingFees.BorrowingData memory) {
        return _getStorage().groups[_collateralIndex][_groupIndex];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingGroupOi(
        uint8 _collateralIndex,
        uint16 _groupIndex
    ) internal view returns (IBorrowingFees.OpenInterest memory) {
        return _getStorage().groupOis[_collateralIndex][_groupIndex];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingPair(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) internal view returns (IBorrowingFees.BorrowingData memory) {
        return _getStorage().pairs[_collateralIndex][_pairIndex];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingPairOi(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) internal view returns (IBorrowingFees.OpenInterest memory) {
        return _getStorage().pairOis[_collateralIndex][_pairIndex];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingPairGroups(
        uint8 _collateralIndex,
        uint16 _pairIndex
    ) internal view returns (IBorrowingFees.BorrowingPairGroup[] memory) {
        return _getStorage().pairGroups[_collateralIndex][_pairIndex];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getAllBorrowingPairs(
        uint8 _collateralIndex
    )
        internal
        view
        returns (
            IBorrowingFees.BorrowingData[] memory,
            IBorrowingFees.OpenInterest[] memory,
            IBorrowingFees.BorrowingPairGroup[][] memory
        )
    {
        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();

        uint16 len = uint16(_getMultiCollatDiamond().pairsCount());
        IBorrowingFees.BorrowingData[] memory pairs = new IBorrowingFees.BorrowingData[](len);
        IBorrowingFees.OpenInterest[] memory pairOi = new IBorrowingFees.OpenInterest[](len);
        IBorrowingFees.BorrowingPairGroup[][] memory pairGroups = new IBorrowingFees.BorrowingPairGroup[][](len);

        for (uint16 i; i < len; ++i) {
            pairs[i] = s.pairs[_collateralIndex][i];
            pairOi[i] = s.pairOis[_collateralIndex][i];
            pairGroups[i] = s.pairGroups[_collateralIndex][i];
        }

        return (pairs, pairOi, pairGroups);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingGroups(
        uint8 _collateralIndex,
        uint16[] calldata _indices
    ) internal view returns (IBorrowingFees.BorrowingData[] memory, IBorrowingFees.OpenInterest[] memory) {
        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();

        uint256 len = _indices.length;
        IBorrowingFees.BorrowingData[] memory groups = new IBorrowingFees.BorrowingData[](len);
        IBorrowingFees.OpenInterest[] memory groupOis = new IBorrowingFees.OpenInterest[](len);

        for (uint256 i; i < len; ++i) {
            groups[i] = s.groups[_collateralIndex][_indices[i]];
            groupOis[i] = s.groupOis[_collateralIndex][_indices[i]];
        }

        return (groups, groupOis);
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getBorrowingInitialAccFees(
        uint8 _collateralIndex,
        address _trader,
        uint32 _index
    ) internal view returns (IBorrowingFees.BorrowingInitialAccFees memory) {
        return _getStorage().initialAccFees[_collateralIndex][_trader][_index];
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getPairMaxOi(uint8 _collateralIndex, uint16 _pairIndex) internal view returns (uint256) {
        return _getStorage().pairOis[_collateralIndex][_pairIndex].max;
    }

    /**
     * @dev Check IBorrowingFeesUtils interface for documentation
     */
    function getPairMaxOiCollateral(uint8 _collateralIndex, uint16 _pairIndex) internal view returns (uint256) {
        return
            (uint256(_getMultiCollatDiamond().getCollateral(_collateralIndex).precision) *
                _getStorage().pairOis[_collateralIndex][_pairIndex].max) / P_1;
    }

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function _getSlot() internal pure returns (uint256) {
        return StorageUtils.GLOBAL_BORROWING_FEES_SLOT;
    }

    /**
     * @dev Returns storage pointer for storage struct in diamond contract, at defined slot
     */
    function _getStorage() internal pure returns (IBorrowingFees.BorrowingFeesStorage storage s) {
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
     * @dev Reverts if collateral index is not valid
     */
    modifier validCollateralIndex(uint8 _collateralIndex) {
        if (!_getMultiCollatDiamond().isCollateralListed(_collateralIndex)) {
            revert IGeneralErrors.InvalidCollateralIndex();
        }
        _;
    }

    /**
     * @dev Returns pending acc borrowing fee for a pair on one side only
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _currentBlock current block number
     * @param _long true if long side
     * @return accFee new pair acc borrowing fee
     */
    function _getBorrowingPairPendingAccFee(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _currentBlock,
        bool _long
    ) internal view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getBorrowingPairPendingAccFees(
            _collateralIndex,
            _pairIndex,
            _currentBlock
        );
        return _long ? accFeeLong : accFeeShort;
    }

    /**
     * @dev Returns pending acc borrowing fee for a borrowing group on one side only
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _currentBlock current block number
     * @param _long true if long side
     * @return accFee new group acc borrowing fee
     */
    function _getBorrowingGroupPendingAccFee(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        uint256 _currentBlock,
        bool _long
    ) internal view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getBorrowingGroupPendingAccFees(
            _collateralIndex,
            _groupIndex,
            _currentBlock
        );
        return _long ? accFeeLong : accFeeShort;
    }

    /**
     * @dev Pure function that returns the new acc borrowing fees and delta between two blocks (for pairs and groups)
     * @param _input input data (last acc fees, OIs, fee per block, current block, etc.)
     * @return newAccFeeLong new acc borrowing fee on long side
     * @return newAccFeeShort new acc borrowing fee on short side
     * @return delta delta with current acc borrowing fee (for side that changed)
     */
    function _getBorrowingPendingAccFees(
        IBorrowingFees.PendingBorrowingAccFeesInput memory _input
    ) internal pure returns (uint64 newAccFeeLong, uint64 newAccFeeShort, uint64 delta) {
        if (_input.currentBlock < _input.accLastUpdatedBlock) {
            revert IGeneralErrors.BlockOrder();
        }

        bool moreShorts = _input.oiLong < _input.oiShort;
        uint256 netOi = moreShorts ? _input.oiShort - _input.oiLong : _input.oiLong - _input.oiShort;

        uint256 _delta = _input.maxOi > 0 && _input.feeExponent > 0
            ? ((_input.currentBlock - _input.accLastUpdatedBlock) *
                _input.feePerBlock *
                ((netOi * 1e10) / _input.maxOi) ** _input.feeExponent) /
                (uint256(_input.collateralPrecision) ** _input.feeExponent)
            : 0; // 1e10 (%)

        if (_delta > type(uint64).max) {
            revert IGeneralErrors.Overflow();
        }
        delta = uint64(_delta);

        newAccFeeLong = moreShorts ? _input.accFeeLong : _input.accFeeLong + delta;
        newAccFeeShort = moreShorts ? _input.accFeeShort + delta : _input.accFeeShort;
    }

    /**
     * @dev Pure function that returns the liquidation price for a trade (1e10 precision)
     * @param _openPrice trade open price (1e10 precision)
     * @param _long true if long, false if short
     * @param _collateral trade collateral (collateral precision)
     * @param _leverage trade leverage (1e3 precision)
     * @param _borrowingFeeCollateral borrowing fee amount (collateral precision)
     * @param _collateralPrecisionDelta collateral precision delta (10^18/10^decimals)
     */
    function _getTradeLiquidationPrice(
        uint256 _openPrice,
        bool _long,
        uint256 _collateral,
        uint256 _leverage,
        uint256 _borrowingFeeCollateral,
        uint128 _collateralPrecisionDelta
    ) internal pure returns (uint256) {
        uint256 precisionDeltaUint = uint256(_collateralPrecisionDelta);

        int256 openPriceInt = int256(_openPrice);
        int256 collateralLiqNegativePnlInt = int256((_collateral * LIQ_THRESHOLD_P * precisionDeltaUint * 1e3) / 100); // 1e18 * 1e3
        int256 borrowingFeeInt = int256(_borrowingFeeCollateral * precisionDeltaUint * 1e3); // 1e18 * 1e3

        // PRECISION
        int256 liqPriceDistance = (openPriceInt * (collateralLiqNegativePnlInt - borrowingFeeInt)) / // 1e10 * 1e18 * 1e3
            int256(_collateral) /
            int256(_leverage) /
            int256(precisionDeltaUint); // 1e10

        int256 liqPrice = _long ? openPriceInt - liqPriceDistance : openPriceInt + liqPriceDistance; // 1e10

        return liqPrice > 0 ? uint256(liqPrice) : 0; // 1e10
    }

    /**
     * @dev Function to set borrowing pair params
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _value new pair params
     */
    function _setBorrowingPairParams(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        IBorrowingFees.BorrowingPairParams calldata _value
    ) internal {
        if (_value.feeExponent < 1 || _value.feeExponent > 3) {
            revert IBorrowingFeesUtils.BorrowingWrongExponent();
        }

        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();
        IBorrowingFees.BorrowingData storage p = s.pairs[_collateralIndex][_pairIndex];

        uint16 prevGroupIndex = getBorrowingPairGroupIndex(_collateralIndex, _pairIndex);
        uint256 currentBlock = ChainUtils.getBlockNumber();

        _setPairPendingAccFees(_collateralIndex, _pairIndex, currentBlock);

        if (_value.groupIndex != prevGroupIndex) {
            _setGroupPendingAccFees(_collateralIndex, prevGroupIndex, currentBlock);
            _setGroupPendingAccFees(_collateralIndex, _value.groupIndex, currentBlock);

            (uint256 oiLong, uint256 oiShort) = getPairOisCollateral(_collateralIndex, _pairIndex);

            // Only remove OI from old group if old group is not 0
            _updateGroupOi(_collateralIndex, prevGroupIndex, true, false, oiLong);
            _updateGroupOi(_collateralIndex, prevGroupIndex, false, false, oiShort);

            // Add OI to new group if it's not group 0 (even if old group is 0)
            // So when we assign a pair to a group, it takes into account its OI
            // And group 0 OI will always be 0 but it doesn't matter since it's not used
            _updateGroupOi(_collateralIndex, _value.groupIndex, true, true, oiLong);
            _updateGroupOi(_collateralIndex, _value.groupIndex, false, true, oiShort);

            IBorrowingFees.BorrowingData memory newGroup = s.groups[_collateralIndex][_value.groupIndex];
            IBorrowingFees.BorrowingData memory prevGroup = s.groups[_collateralIndex][prevGroupIndex];

            s.pairGroups[_collateralIndex][_pairIndex].push(
                IBorrowingFees.BorrowingPairGroup(
                    _value.groupIndex,
                    ChainUtils.getUint48BlockNumber(currentBlock),
                    newGroup.accFeeLong,
                    newGroup.accFeeShort,
                    prevGroup.accFeeLong,
                    prevGroup.accFeeShort,
                    p.accFeeLong,
                    p.accFeeShort,
                    0 // placeholder
                )
            );

            emit IBorrowingFeesUtils.BorrowingPairGroupUpdated(
                _collateralIndex,
                _pairIndex,
                prevGroupIndex,
                _value.groupIndex
            );
        }

        p.feePerBlock = _value.feePerBlock;
        p.feeExponent = _value.feeExponent;
        s.pairOis[_collateralIndex][_pairIndex].max = _value.maxOi;

        emit IBorrowingFeesUtils.BorrowingPairParamsUpdated(
            _collateralIndex,
            _pairIndex,
            _value.groupIndex,
            _value.feePerBlock,
            _value.feeExponent,
            _value.maxOi
        );
    }

    /**
     * @dev Function to set borrowing group params
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _value new group params
     */
    function _setBorrowingGroupParams(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        IBorrowingFees.BorrowingGroupParams calldata _value
    ) internal {
        if (_groupIndex == 0) {
            revert IBorrowingFeesUtils.BorrowingZeroGroup();
        }
        if (_value.feeExponent < 1 || _value.feeExponent > 3) {
            revert IBorrowingFeesUtils.BorrowingWrongExponent();
        }

        _setGroupPendingAccFees(_collateralIndex, _groupIndex, ChainUtils.getBlockNumber());

        IBorrowingFees.BorrowingFeesStorage storage s = _getStorage();
        IBorrowingFees.BorrowingData storage group = s.groups[_collateralIndex][_groupIndex];

        group.feePerBlock = _value.feePerBlock;
        group.feeExponent = _value.feeExponent;
        s.groupOis[_collateralIndex][_groupIndex].max = _value.maxOi;

        emit IBorrowingFeesUtils.BorrowingGroupUpdated(
            _collateralIndex,
            _groupIndex,
            _value.feePerBlock,
            _value.maxOi,
            _value.feeExponent
        );
    }

    /**
     * @dev Function to update a borrowing pair/group open interest
     * @param _oiStorage open interest storage reference
     * @param _long true if long, false if short
     * @param _increase true if increase, false if decrease
     * @param _amountCollateral amount of collateral to increase/decrease (collateral precision)
     * @param _collateralPrecision collateral precision (10^decimals)
     * @return newOiLong new long open interest (1e10)
     * @return newOiShort new short open interest (1e10)
     * @return delta difference between new and current open interest (1e10)
     */
    function _updateOi(
        IBorrowingFees.OpenInterest storage _oiStorage,
        bool _long,
        bool _increase,
        uint256 _amountCollateral,
        uint128 _collateralPrecision
    ) internal returns (uint72 newOiLong, uint72 newOiShort, uint72 delta) {
        _amountCollateral = (_amountCollateral * P_1) / _collateralPrecision; // 1e10

        if (_amountCollateral > type(uint72).max) {
            revert IGeneralErrors.Overflow();
        }

        delta = uint72(_amountCollateral);

        IBorrowingFees.OpenInterest memory oi = _oiStorage;

        if (_long) {
            oi.long = _increase ? oi.long + delta : delta > oi.long ? 0 : oi.long - delta;
            _oiStorage.long = oi.long;
        } else {
            oi.short = _increase ? oi.short + delta : delta > oi.short ? 0 : oi.short - delta;
            _oiStorage.short = oi.short;
        }

        return (oi.long, oi.short, delta);
    }

    /**
     * @dev Function to update a borrowing group's open interest
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the borrowing group
     * @param _long true if long, false if short
     * @param _increase true if increase, false if decrease
     * @param _amountCollateral amount of collateral to increase/decrease (collateral precision)
     */
    function _updatePairOi(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        bool _long,
        bool _increase,
        uint256 _amountCollateral
    ) internal {
        (uint72 newOiLong, uint72 newOiShort, uint72 delta) = _updateOi(
            _getStorage().pairOis[_collateralIndex][_pairIndex],
            _long,
            _increase,
            _amountCollateral,
            _getMultiCollatDiamond().getCollateral(_collateralIndex).precision
        );

        emit IBorrowingFeesUtils.BorrowingPairOiUpdated(
            _collateralIndex,
            _pairIndex,
            _long,
            _increase,
            delta,
            newOiLong,
            newOiShort
        );
    }

    /**
     * @dev Function to update a borrowing group's open interest
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _long true if long, false if short
     * @param _increase true if increase, false if decrease
     * @param _amountCollateral amount of collateral to increase/decrease (collateral precision)
     */
    function _updateGroupOi(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        bool _long,
        bool _increase,
        uint256 _amountCollateral
    ) internal {
        if (_groupIndex > 0) {
            (uint72 newOiLong, uint72 newOiShort, uint72 delta) = _updateOi(
                _getStorage().groupOis[_collateralIndex][_groupIndex],
                _long,
                _increase,
                _amountCollateral,
                _getMultiCollatDiamond().getCollateral(_collateralIndex).precision
            );

            emit IBorrowingFeesUtils.BorrowingGroupOiUpdated(
                _collateralIndex,
                _groupIndex,
                _long,
                _increase,
                delta,
                newOiLong,
                newOiShort
            );
        }
    }

    /**
     * @dev Calculates the borrowing group and pair acc fees deltas for a trade between pair group at index _i and next one
     * @param _collateralIndex index of the collateral
     * @param _i index of the borrowing pair group
     * @param _pairGroups all pair's historical borrowing groups
     * @param _initialFees trade initial borrowing fees
     * @param _pairIndex index of the pair
     * @param _long true if long, false if short
     * @param _currentBlock current block number
     * @return deltaGroup difference between new and current group acc borrowing fee
     * @return deltaPair difference between new and current pair acc borrowing fee
     * @return beforeTradeOpen true if pair group was set before trade was opened
     */
    function _getBorrowingPairGroupAccFeesDeltas(
        uint8 _collateralIndex,
        uint256 _i,
        IBorrowingFees.BorrowingPairGroup[] memory _pairGroups,
        IBorrowingFees.BorrowingInitialAccFees memory _initialFees,
        uint16 _pairIndex,
        bool _long,
        uint256 _currentBlock
    ) internal view returns (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) {
        IBorrowingFees.BorrowingPairGroup memory group = _pairGroups[_i];

        beforeTradeOpen = group.block < _initialFees.block;

        if (_i == _pairGroups.length - 1) {
            // Last active group
            deltaGroup = _getBorrowingGroupPendingAccFee(_collateralIndex, group.groupIndex, _currentBlock, _long);
            deltaPair = _getBorrowingPairPendingAccFee(_collateralIndex, _pairIndex, _currentBlock, _long);
        } else {
            // Previous groups
            IBorrowingFees.BorrowingPairGroup memory nextGroup = _pairGroups[_i + 1];

            // If it's not the first group to be before the trade was opened then fee is 0
            if (beforeTradeOpen && nextGroup.block <= _initialFees.block) {
                return (0, 0, beforeTradeOpen);
            }

            deltaGroup = _long ? nextGroup.prevGroupAccFeeLong : nextGroup.prevGroupAccFeeShort;
            deltaPair = _long ? nextGroup.pairAccFeeLong : nextGroup.pairAccFeeShort;
        }

        if (beforeTradeOpen) {
            deltaGroup -= _initialFees.accGroupFee;
            deltaPair -= _initialFees.accPairFee;
        } else {
            deltaGroup -= (_long ? group.initialAccFeeLong : group.initialAccFeeShort);
            deltaPair -= (_long ? group.pairAccFeeLong : group.pairAccFeeShort);
        }
    }

    /**
     *
     * @param _collateralIndex index of the collateral
     * @param _pairIndex index of the pair
     * @param _currentBlock current block number
     * @return accFeeLong new pair acc borrowing fee on long side (1e10 precision)
     * @return accFeeShort new pair acc borrowing fee on short side (1e10 precision)
     */
    function _setPairPendingAccFees(
        uint8 _collateralIndex,
        uint16 _pairIndex,
        uint256 _currentBlock
    ) internal returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getBorrowingPairPendingAccFees(_collateralIndex, _pairIndex, _currentBlock);

        IBorrowingFees.BorrowingData storage pair = _getStorage().pairs[_collateralIndex][_pairIndex];

        (pair.accFeeLong, pair.accFeeShort) = (accFeeLong, accFeeShort);
        pair.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(_currentBlock);

        emit IBorrowingFeesUtils.BorrowingPairAccFeesUpdated(
            _collateralIndex,
            _pairIndex,
            _currentBlock,
            pair.accFeeLong,
            pair.accFeeShort
        );
    }

    /**
     *
     * @param _collateralIndex index of the collateral
     * @param _groupIndex index of the borrowing group
     * @param _currentBlock current block number
     * @return accFeeLong new group acc borrowing fee on long side (1e10 precision)
     * @return accFeeShort new group acc borrowing fee on short side (1e10 precision)
     */
    function _setGroupPendingAccFees(
        uint8 _collateralIndex,
        uint16 _groupIndex,
        uint256 _currentBlock
    ) internal returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getBorrowingGroupPendingAccFees(_collateralIndex, _groupIndex, _currentBlock);

        IBorrowingFees.BorrowingData storage group = _getStorage().groups[_collateralIndex][_groupIndex];

        (group.accFeeLong, group.accFeeShort) = (accFeeLong, accFeeShort);
        group.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(_currentBlock);

        emit IBorrowingFeesUtils.BorrowingGroupAccFeesUpdated(
            _collateralIndex,
            _groupIndex,
            _currentBlock,
            group.accFeeLong,
            group.accFeeShort
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IArbSys.sol";
import "../interfaces/mock/IBlockManager_Mock.sol";

/**
 * @custom:version 8
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

/**
 * @custom:version 8
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