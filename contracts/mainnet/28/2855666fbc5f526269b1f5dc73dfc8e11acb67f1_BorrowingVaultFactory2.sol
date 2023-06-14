// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title BorrowingVaultFactory
 *
 * @author Fujidao Labs
 *
 * @notice A factory contract through which new borrowing vaults are created.
 * The BorrowingVault contract is quite big in size. Creating new instances of it with
 * `new BorrowingVault()` makes the factory contract exceed the 24K limit. That's why
 * we use an approach found at Fraxlend. We split and store the BorrowingVault bytecode
 * in two different locations and when used they get concatanated and deployed by using assembly.
 * ref: https://github.com/FraxFinance/fraxlend/blob/main/src/contracts/FraxlendPairDeployer.sol
 */

import {VaultDeployer} from "../../abstracts/VaultDeployer.sol";
import {LibSSTORE2} from "../../libraries/LibSSTORE2.sol";
import {LibBytes} from "../../libraries/LibBytes.sol";
import {IERC20Metadata} from
  "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract BorrowingVaultFactory2 is VaultDeployer {
  struct BVaultData {
    bytes bytecode;
    address asset;
    address debtAsset;
    string name;
    string symbol;
    bytes32 salt;
  }

  /// @dev Custom Errors
  error BorrowingVaultFactory__deployVault_failed();
  error BorrowingVaultFactory__deployVault_noContractCode();

  event DeployBorrowingVault(
    address indexed vault,
    address indexed asset,
    address indexed debtAsset,
    string name,
    string symbol,
    bytes32 salt
  );

  uint256 public nonce;

  address private _creationAddress1;
  address private _creationAddress2;

  /**
   * @notice Constructor of a new {BorrowingVaultFactory}.
   *
   * @param chief_ address of {Chief}
   *
   * @dev Requirements:
   * - Must comply with {VaultDeployer} requirements.
   */
  constructor(address chief_) VaultDeployer(chief_) {}

  /**
   * @notice Deploys a new {BorrowingVault}.
   *
   * @param deployData The encoded data containing asset, debtAsset, oracle and providers
   *
   * @dev Requirements:
   * - Must be called from {Chief} contract only.
   */
  function deployVault(bytes memory deployData) external onlyChief returns (address vault) {
    BVaultData memory vdata;
    ///@dev Scoped section created to avoid stack too big error.
    {
      (address asset, address debtAsset) = abi.decode(deployData, (address, address));

      vdata.asset = asset;
      vdata.debtAsset = debtAsset;

      string memory assetSymbol = IERC20Metadata(asset).symbol();
      string memory debtSymbol = IERC20Metadata(debtAsset).symbol();

      // Example of `name_`: "Fuji-V2 WETH-DAI BorrowingVault".
      vdata.name =
        string(abi.encodePacked("Fuji-V2 ", assetSymbol, "-", debtSymbol, " BorrowingVault"));
      // Example of `symbol_`: "fbvWETHDAI".
      vdata.symbol = string(abi.encodePacked("fbv", assetSymbol, debtSymbol));

      vdata.salt = keccak256(abi.encode(deployData, nonce));
      nonce++;

      bytes memory creationCode =
        LibBytes.concat(LibSSTORE2.read(_creationAddress1), LibSSTORE2.read(_creationAddress2));

      if (creationCode.length == 0) revert BorrowingVaultFactory__deployVault_noContractCode();

      vdata.bytecode = abi.encodePacked(
        creationCode, abi.encode(asset, debtAsset, chief, vdata.name, vdata.symbol)
      );
    }

    bytes32 salt_ = vdata.salt;
    bytes memory bytecode_ = vdata.bytecode;

    assembly {
      vault := create2(0, add(bytecode_, 32), mload(bytecode_), salt_)
    }
    if (vault == address(0)) revert BorrowingVaultFactory__deployVault_failed();

    _registerVault(vault, vdata.asset, vdata.salt);

    emit DeployBorrowingVault(
      vault, vdata.asset, vdata.debtAsset, vdata.name, vdata.symbol, vdata.salt
    );
  }

  /**
   * @notice Gets the bytecode for the BorrowingVault.
   *
   */
  function getContractCode() external view returns (bytes memory creationCode) {
    creationCode =
      LibBytes.concat(LibSSTORE2.read(_creationAddress1), LibSSTORE2.read(_creationAddress2));
  }

  /**
   * @notice Sets the bytecode for the BorrowingVault.
   *
   * @param creationCode The creationCode for the vault contracts
   *
   * @dev Requirements:
   * - Must be called from a timelock.
   */
  function setContractCode(bytes calldata creationCode) external onlyTimelock {
    bytes memory firstHalf = LibBytes.slice(creationCode, 0, 13000);
    _creationAddress1 = LibSSTORE2.write(firstHalf);
    if (creationCode.length > 13000) {
      bytes memory secondHalf = LibBytes.slice(creationCode, 13000, creationCode.length - 13000);
      _creationAddress2 = LibSSTORE2.write(secondHalf);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title VaultDeployer
 *
 * @author Fujidao Labs
 *
 * @notice Abstract contract to be inherited by vault deployers
 * for whitelisted template factories.
 * This contract provides methods that facilitate information for
 * front-end applications.
 */

import {IChief} from "../interfaces/IChief.sol";

abstract contract VaultDeployer {
  /// @dev Custom Errors
  error VaultDeployer__onlyChief_notAuthorized();
  error VaultDeployer__onlyTimelock_notAuthorized();
  error VaultDeployer__zeroAddress();

  /**
   * @dev Emit when a vault is registered.
   *
   * @param vault address
   * @param asset address
   * @param salt used for address generation
   */
  event VaultRegistered(address vault, address asset, bytes32 salt);

  address public immutable chief;

  address[] public allVaults;
  mapping(address => address[]) public vaultsByAsset;
  mapping(bytes32 => address) public configAddress;

  modifier onlyChief() {
    if (msg.sender != chief) {
      revert VaultDeployer__onlyChief_notAuthorized();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != IChief(chief).timelock()) {
      revert VaultDeployer__onlyTimelock_notAuthorized();
    }
    _;
  }

  /**
   * @notice Abstract constructor of a new {VaultDeployer}.
   *
   * @param chief_ address
   *
   * @dev Requirements:
   * - Must pass non-zero {Chief} address, that could be checked at child contract.
   */
  constructor(address chief_) {
    if (chief_ == address(0)) {
      revert VaultDeployer__zeroAddress();
    }
    chief = chief_;
  }

  /**
   * @notice Returns the historic number of vaults of an `asset` type
   * deployed by this deployer.
   *
   * @param asset address
   */
  function vaultsCount(address asset) external view returns (uint256 count) {
    count = vaultsByAsset[asset].length;
  }

  /**
   * @notice Returns an array of vaults based on their `asset` type.
   *
   * @param asset address
   * @param startIndex number to start loop in vaults[] array
   * @param count number to end loop in vaults[] array
   */
  function getVaults(
    address asset,
    uint256 startIndex,
    uint256 count
  )
    external
    view
    returns (address[] memory vaults)
  {
    vaults = new address[](count);
    for (uint256 i = 0; i < count; i++) {
      vaults[i] = vaultsByAsset[asset][startIndex + i];
    }
  }

  /**
   * @dev Registers a record of `vault` based on vault's `asset`.
   *
   * @param vault address
   * @param asset address of the vault
   */
  function _registerVault(address vault, address asset, bytes32 salt) internal onlyChief {
    // Store the address of the deployed contract.
    configAddress[salt] = vault;
    vaultsByAsset[asset].push(vault);
    allVaults.push(vault);
    emit VaultRegistered(vault, asset, salt);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title LibSSTORE2
 *
 * @author Solmate, modified from 0xSequence
 *
 * @notice Read and write to persistent storage at a fraction of the cost.
 * Refer to (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol),
 * and (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol).
 */

library LibSSTORE2 {
  // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.
  uint256 internal constant DATA_OFFSET = 1;

  /*////////////////
     WRITE LOGIC
  ////////////////*/

  function write(bytes memory data) internal returns (address pointer) {
    // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
    bytes memory runtimeCode = abi.encodePacked(hex"00", data);

    bytes memory creationCode = abi.encodePacked(
      /**
       * @dev
       * //---------------------------------------------------------------------------------------------------------------//
       * // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
       * //---------------------------------------------------------------------------------------------------------------//
       * // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
       * // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
       * // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
       * // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
       * // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
       * // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
       * // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
       * // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
       * // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
       * // 0xf3    |  0xf3               | RETURN       |                                                                //
       * //---------------------------------------------------------------------------------------------------------------//
       */
      hex"600B5981380380925939F3",
      // Returns all code in the contract except for the first 11 (0B in hex) bytes.
      runtimeCode
    );

    /// @solidity memory-safe-assembly
    assembly {
      // Deploy a new contract with the generated creation code. We start 32 bytes into the code to avoid copying the byte length.
      pointer := create(0, add(creationCode, 32), mload(creationCode))
    }

    require(pointer != address(0), "DEPLOYMENT_FAILED");
  }

  /*////////////////
     READ LOGIC
  ////////////////*/

  function read(address pointer) internal view returns (bytes memory) {
    return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
  }

  function read(address pointer, uint256 start) internal view returns (bytes memory) {
    start += DATA_OFFSET;

    return readBytecode(pointer, start, pointer.code.length - start);
  }

  function read(address pointer, uint256 start, uint256 end) internal view returns (bytes memory) {
    start += DATA_OFFSET;
    end += DATA_OFFSET;

    require(pointer.code.length >= end, "OUT_OF_BOUNDS");

    return readBytecode(pointer, start, end - start);
  }

  /*//////////////////////////
     INTERNAL HELPER LOGIC
  //////////////////////////*/

  function readBytecode(
    address pointer,
    uint256 start,
    uint256 size
  )
    private
    view
    returns (bytes memory data)
  {
    /// @solidity memory-safe-assembly
    assembly {
      // Get a pointer to some free memory.
      data := mload(0x40)

      /**
       * @dev Update the free memory pointer to prevent overriding our data.
       * We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
       * Adding 31 to size and running the result through the logic above ensures
       * he memory pointer remains word-aligned, following the Solidity convention.
       */
      mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

      // Store the size of the data in the first 32 byte chunk of free memory.
      mstore(data, size)

      // Copy the code into memory right after the 32 bytes we used to store the size.
      extcodecopy(pointer, add(data, 32), start, size)
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/*
 * @title LibBytes

 * @author Gonçalo Sá <[email protected]>
 *
 * @notice Utility library for ethereum contracts written in Solidity.
 * The library lets you concatenate, slice and type cast bytes arrays 
 * both in memory and storage. Taken from:
 * https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol.
 */
library LibBytes {
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
      /**
       * @dev Get a location of some free memory and store it in tempBytes as
       * Solidity does for memory variables.
       */
      tempBytes := mload(0x40)

      /**
       * @dev Store the length of the first bytes array at the beginning of
       * the memory for tempBytes.
       */
      let length := mload(_preBytes)
      mstore(tempBytes, length)

      /**
       * @dev Maintain a memory counter for the current write location in the
       * temp bytes array by adding the 32 bytes for the array length to
       * the starting location.
       */
      let mc := add(tempBytes, 0x20)
      // Stop copying when the memory counter reaches the length of the first bytes array.
      let end := add(mc, length)

      for {
        // Initialize a copy counter to the start of the _preBytes data, 32 bytes into its memory.
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        // Increase both counters by 32 bytes each iteration.
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        // Write the _preBytes data into the tempBytes memory 32 bytes at a time.
        mstore(mc, mload(cc))
      }

      /**
       * @dev Add the length of _postBytes to the current length of tempBytes
       * and store it as the new length in the first 32 bytes of the
       * tempBytes memory.
       */
      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      // Move the memory counter back from a multiple of 0x20 to the  actual end of the _preBytes data.
      mc := end
      // Stop copying when the memory counter reaches the new combined length of the arrays.
      end := add(mc, length)

      for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } { mstore(mc, mload(cc)) }

      /**
       * @dev Update the free-memory pointer by padding our last write location
       * to 32 bytes: add 31 bytes to the end of tempBytes to move to the
       * next 32 byte block, then round down to the nearest multiple of
       * 32. If the sum of the length of the two arrays is zero then add
       * one before rounding down to leave a blank 32 bytes (the length block with 0).
       */
      mstore(
        0x40,
        and(
          add(add(end, iszero(add(length, mload(_preBytes)))), 31),
          // Round down to the nearest 32 bytes.
          not(31)
        )
      )
    }

    return tempBytes;
  }

  function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
    assembly {
      /**
       * @dev Read the first 32 bytes of _preBytes storage, which is the length
       * of the array. (We don't need to use the offset into the slot
       * because arrays use the entire slot.)
       */
      let fslot := sload(_preBytes.slot)
      /**
       * @dev Arrays of 31 bytes or less have an even value in their slot,
       * while longer arrays have an odd value. The actual length is
       * the slot divided by two for odd values, and the lowest order
       * byte divided by two for even values.
       * If the slot is even, bitwise and the slot with 255 and divide by
       * two to get the length. If the slot is odd, bitwise and the slot
       * with -1 and divide by two.
       */
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)
      let newlength := add(slength, mlength)

      /**
       * @dev // slength can contain both the length and contents of the array
       * if length < 32 bytes so let's prepare for that
       * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
       */
      switch add(lt(slength, 32), lt(newlength, 32))
      case 2 {
        /**
         * @dev Since the new array still fits in the slot, we just need to
         * update the contents of the slot.
         * uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
         */
        sstore(
          _preBytes.slot,
          // All the modifications to the slot are inside this next block
          add(
            // we can just add to the slot contents because the bytes we want to change are the LSBs
            fslot,
            add(
              mul(
                div(
                  // load the bytes from memory.
                  mload(add(_postBytes, 0x20)),
                  // Zero all bytes to the right.
                  exp(0x100, sub(32, mlength))
                ),
                // Now shift left the number of bytes to leave space for the length in the slot.
                exp(0x100, sub(32, newlength))
              ),
              // Increase length by the double of the memory bytes length.
              mul(mlength, 2)
            )
          )
        )
      }
      case 1 {
        /**
         * @dev The stored value fits in the slot, but the combined value
         * will exceed it. Get the keccak hash to get the contents of the array.
         */
        mstore(0x0, _preBytes.slot)
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        /**
         * @dev The contents of the _postBytes array start 32 bytes into
         * the structure. Our first read should obtain the `submod`
         * bytes that can fit into the unused space in the last word
         * of the stored array. To get this, we read 32 bytes starting
         * from `submod`, so the data we read overlaps with the array
         * contents by `submod` bytes. Masking the lowest-order
         * `submod` bytes allows us to add that value directly to the
         * stored value.
         */
        let submod := sub(32, slength)
        let mc := add(_postBytes, submod)
        let end := add(_postBytes, mlength)
        let mask := sub(exp(0x100, submod), 1)

        sstore(
          sc,
          add(
            and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
            and(mload(mc), mask)
          )
        )

        for {
          mc := add(mc, 0x20)
          sc := add(sc, 1)
        } lt(mc, end) {
          sc := add(sc, 1)
          mc := add(mc, 0x20)
        } { sstore(sc, mload(mc)) }

        mask := exp(0x100, sub(mc, end))

        sstore(sc, mul(div(mload(mc), mask), mask))
      }
      default {
        // Get the keccak hash to get the contents of the array.
        mstore(0x0, _preBytes.slot)
        // Start copying to the last used word of the stored array.
        let sc := add(keccak256(0x0, 0x20), div(slength, 32))

        // Save new length.
        sstore(_preBytes.slot, add(mul(newlength, 2), 1))

        // Copy over the first `submod` bytes of the new data as in case 1 above.
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
        } { sstore(sc, mload(mc)) }

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
        // Get a location of some free memory and store it in tempBytes as Solidity does for memory variables.
        tempBytes := mload(0x40)

        /**
         * @dev The first word of the slice result is potentially a partial
         * word read from the original array. To read it, we calculate
         * the length of that partial word and start copying that many
         * bytes into the array. The first word we copy will start with
         * data we don't care about, but the last `lengthmod` bytes will
         * land at the beginning of the contents of the new array. When
         * we're done copying, we overwrite the full first word with
         * the actual length of the slice.
         */
        let lengthmod := and(_length, 31)

        /**
         * @dev The multiplication in the next line is necessary
         * because when slicing multiples of 32 bytes (lengthmod == 0)
         * the following copy loop was copying the origin's length
         * and then ending prematurely not copying everything it should.
         */
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } { mstore(mc, mload(cc)) }

        mstore(tempBytes, _length)

        // Update free-memory pointer allocating the array padded to 32 bytes like the compiler does now.
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      // If we want a zero-length slice let's just return a zero-length array.
      default {
        tempBytes := mload(0x40)
        // Zero out the 32 bytes slice we are about to return we need to do it because Solidity does not garbage collect
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
    require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
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

      // If lengths don't match the arrays are not equal
      switch eq(length, mload(_postBytes))
      case 1 {
        /**
         * @dev cb is a circuit breaker in the for loop since there's
         * no said feature for inline assembly loops
         * cb = 1 - don't breaker
         * cb = 0 - break
         */
        let cb := 1

        let mc := add(_preBytes, 0x20)
        let end := add(mc, length)

        for { let cc := add(_postBytes, 0x20) }
        // The next line is the loop condition: while(uint256(mc < end) + cb == 2).
        eq(add(lt(mc, end), cb), 2) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          // If any of these checks fails then arrays are not equal.
          if iszero(eq(mload(mc), mload(cc))) {
            // Unsuccess:
            success := 0
            cb := 0
          }
        }
      }
      default {
        // Unsuccess:
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
      // We know _preBytes_offset is 0.
      let fslot := sload(_preBytes.slot)
      // Decode the length of the stored array like in concatStorage().
      let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
      let mlength := mload(_postBytes)

      // If lengths don't match the arrays are not equal.
      switch eq(slength, mlength)
      case 1 {
        /**
         * @dev Slength can contain both the length and contents of the array
         * if length < 32 bytes so let's prepare for that
         * v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
         */
        if iszero(iszero(slength)) {
          switch lt(slength, 32)
          case 1 {
            // Blank the last byte which is the length.
            fslot := mul(div(fslot, 0x100), 0x100)

            if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
              // Unsuccess:
              success := 0
            }
          }
          default {
            /**
             * @dev cb is a circuit breaker in the for loop since there's
             * no said feature for inline assembly loops
             * cb = 1 - don't breaker
             * cb = 0 - break
             */
            let cb := 1

            // Get the keccak hash to get the contents of the array.
            mstore(0x0, _preBytes.slot)
            let sc := keccak256(0x0, 0x20)

            let mc := add(_postBytes, 0x20)
            let end := add(mc, mlength)

            // The next line is the loop condition: while(uint256(mc < end) + cb == 2)
            for {} eq(add(lt(mc, end), cb), 2) {
              sc := add(sc, 1)
              mc := add(mc, 0x20)
            } {
              if iszero(eq(sload(sc), mload(mc))) {
                // Unsuccess:
                success := 0
                cb := 0
              }
            }
          }
        }
      }
      default {
        // Unsuccess:
        success := 0
      }
    }

    return success;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IChief
 *
 * @author Fujidao Labs
 *
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  /// @notice Returns the timelock address of the FujiV2 system.
  function timelock() external view returns (address);

  /// @notice Returns the address mapper contract address of the FujiV2 system.
  function addrMapper() external view returns (address);

  /**
   * @notice Returns true if `vault` is active.
   *
   * @param vault to check status
   */
  function isVaultActive(address vault) external view returns (bool);

  /**
   * @notice Returns true if `flasher` is an allowed {IFlasher}.
   *
   * @param flasher address to check
   */
  function allowedFlasher(address flasher) external view returns (bool);

  /**
   * @notice Returns true if `swapper` is an allowed {ISwapper}.
   *
   * @param swapper address to check
   */
  function allowedSwapper(address swapper) external view returns (bool);
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