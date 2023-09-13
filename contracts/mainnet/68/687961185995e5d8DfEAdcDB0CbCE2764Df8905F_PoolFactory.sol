// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

struct Config {
    address FETCHER;
    bytes32 ORACLE; // 1bit QTI, 31bit reserve, 32bit WINDOW, ... PAIR ADDRESS
    address TOKEN_R;
    uint256 K;
    uint256 MARK;
    uint256 INTEREST_HL;
    uint256 PREMIUM_HL;
    uint256 MATURITY;
    uint256 MATURITY_VEST;
    uint256 MATURITY_RATE; // x128
    uint256 OPEN_RATE;
}

struct Param {
    uint256 sideIn;
    uint256 sideOut;
    address helper;
    bytes payload;
}

struct Payment {
    address utr;
    bytes payer;
    address recipient;
}

// represent a single pool state
struct State {
    uint256 R; // pool reserve
    uint256 a; // LONG coefficient
    uint256 b; // SHORT coefficient
}

// anything that can be changed between tx construction and confirmation
struct Slippable {
    uint256 xk; // (price/MARK)^K
    uint256 R; // pool reserve
    uint256 rA; // LONG reserve
    uint256 rB; // SHORT reserve
}

interface IPool {
    function init(State memory state, Payment memory payment) external;

    function swap(
        Param memory param,
        Payment memory payment
    ) external returns (uint256 amountIn, uint256 amountOut, uint256 price);

    function loadConfig() external view returns (Config memory);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

import "./IPool.sol";

interface IPoolFactory {
    function createPool(Config memory config) external returns (address pool);

    function LOGIC() external view returns (address);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.20;

library MetaProxyFactory {
  /// @dev Creates a proxy for `targetContract` with metadata from `metadata`.
  /// @return A non-zero address if successful.
  function metaProxyFromBytes (address targetContract, bytes memory metadata) internal returns (address) {
    uint256 ptr;
    assembly {
      ptr := add(metadata, 32)
    }
    return metaProxyFromMemory(targetContract, ptr, metadata.length);
  }

  /// @dev Creates a new proxy for `targetContract` with metadata from memory starting at `offset` and `length` bytes.
  /// @return addr A non-zero address if successful.
  function metaProxyFromMemory (
    address targetContract, uint256 offset, uint256 length
  ) internal returns (address addr) {
    // the following assembly code (init code + contract code) constructs a metaproxy.
    assembly {
      // load free memory pointer as per solidity convention
      let start := mload(64)
      // keep a copy
      let ptr := start
      // deploy code (11 bytes) + first part of the proxy (21 bytes)
      mstore(ptr, 0x600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73)
      ptr := add(ptr, 32)

      // store the address of the contract to be called
      mstore(ptr, shl(96, targetContract))
      // 20 bytes
      ptr := add(ptr, 20)

      // the remaining proxy code...
      mstore(ptr, 0x5af43d3d93803e603457fd5bf300000000000000000000000000000000000000)
      // ...13 bytes
      ptr := add(ptr, 13)

      // copy the metadata
      {
        for { let i := 0 } lt(i, length) { i := add(i, 32) } {
          mstore(add(ptr, i), mload(add(offset, i)))
        }
      }
      ptr := add(ptr, length)
      // store the size of the metadata at the end of the bytecode
      mstore(ptr, length)
      ptr := add(ptr, 32)

      // The size is deploy code + contract code + calldatasize - 4 + 32.
      addr := create2(0, start, sub(ptr, start), 0)
    }
  }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./libs/MetaProxyFactory.sol";
import "./interfaces/IPoolFactory.sol";

/// @title Factory contract to deploy Derivable pool using ERC-3448.
/// @author Derivable Labs
contract PoolFactory is IPoolFactory {
    bytes32 constant internal ORACLE_MASK = bytes32((1 << 255) | type(uint160).max);

    /// @notice PoolLogic contract
    address immutable public LOGIC;

    // events
    event Derivable(
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        bytes32 indexed topic3,
        bytes data
    );

    /// @param logic PoolLogic contract address
    constructor(address logic) {
        require(logic != address(0), "PoolFactory: ZERO_ADDRESS");
        LOGIC = logic;
    }

    /// deploy a new Pool using MetaProxy
    /// @param config immutable configs for the pool
    function createPool(
        Config memory config
    ) external returns (address pool) {
        bytes memory input = abi.encode(config);
        pool = MetaProxyFactory.metaProxyFromBytes(LOGIC, input);
        require(pool != address(0), "PoolFactory: CREATE2_FAILED");
        emit Derivable(
            'PoolCreated',                          // topic1: event name
            config.ORACLE & ORACLE_MASK,            // topic2: price index
            bytes32(uint256(uint160(config.TOKEN_R))), // topic3: reserve token
            abi.encode(
                config.FETCHER,
                config.ORACLE,
                config.K,
                config.MARK,
                config.INTEREST_HL,
                config.PREMIUM_HL,
                config.MATURITY,
                config.MATURITY_VEST,
                config.MATURITY_RATE,
                config.OPEN_RATE,
                uint256(uint160(pool))
            )
        );
    }
}