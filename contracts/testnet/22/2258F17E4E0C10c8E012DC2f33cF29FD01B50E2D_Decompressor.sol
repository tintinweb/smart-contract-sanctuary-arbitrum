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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Decompressor
 * @dev A contract used to decompress calldata
 */
contract Decompressor is Ownable {
  /// @dev Emitted when an too small offset is used.
  /// @param offset The invalid offset used in the function call.
  error TooSmallOffset(uint256 offset);

  /// @dev Emitted when an too big offset is used.
  /// @param offset The invalid offset used in the function call.
  error TooBigOffset(uint256 offset);

  /// @dev The dictionary mapping storage slots to their associated compressed data.
  bytes32[16_384] private _dict;

  modifier validOffset(uint256 begin, uint256 end) {
    if (begin < 2) revert TooSmallOffset(begin);
    if (end >= 16_384) revert TooBigOffset(end);
    _;
  }

  constructor() Ownable() {}

  /// @dev Returns the data stored in the dictionary in the specified range.
  /// @param begin The starting index of the data range to return. First 2 positions are reserved, so it should be greater than 1.
  /// @param end The ending index of the data range to return.
  /// @return res An array of bytes32 values containing the data in the specified range.
  function getData(uint256 begin, uint256 end) external view validOffset(begin, end) returns (bytes32[] memory res) {
    unchecked {
      if (begin < end) {
        res = new bytes32[](end - begin + 1);
        for (uint256 i = begin; i <= end; i++) {
          res[i - begin] = _dict[i];
        }
      }
    }
  }

  /// @dev Sets the data at the specified dictionary offset.
  /// @param offset The starting index of the data range to return. First 2 positions are reserved, so it should be greater than 1.
  /// @param data The data to be stored at the specified offset.
  function setData(uint256 offset, bytes32 data) external validOffset(offset, offset) onlyOwner {
    unchecked {
      _dict[offset] = data;
    }
  }

  /// @dev Sets an array of data starting at the specified dictionary offset.
  /// @param offset The starting index of the data range to return. First 2 positions are reserved, so it should be greater than 1.
  /// @param dataArray The array of data to be stored starting at the specified offset.
  function setDataArray(uint256 offset, bytes32[] calldata dataArray) external validOffset(offset, offset + dataArray.length) onlyOwner {
    unchecked {
      for (uint256 i = 0; i < dataArray.length; i++) {
        _dict[offset + i] = dataArray[i];
      }
    }
  }

  /// @dev Calculates and returns the decompressed data from the compressed calldata. Slices the function selector from the data.
  function decompressCalldata() public view returns (bytes memory) {
    return decompress(msg.data[4:]);
  }

  function decompress(bytes calldata cd) public view returns (bytes memory raw) {
    assembly ("memory-safe") {
      raw := mload(0x40)
      let outptr := add(raw, 0x20)
      let endptr := add(cd.offset, cd.length)
      for {let inptr := cd.offset} lt(inptr, endptr) {} {
        let data := calldataload(inptr)

        // case 00:
        // 00XXXXXX bits
        // XXXXXX - amount of zeros to put - 32 at a time, up to 63
        // 
        // case 01:
        // 01ZZZZZZ - ZXXXXXXX bits
        // ZZZZZZZ - amount of zeros to pad, up to 128
        // XXXXXXX - number of followng data to use, up to 128
        // 
        // case 10:
        // 10XXXXXX - XXXXXXXX bits
        // XXXXXXXXXXXXXX - number to insert - padded to 14 byte, up to 16384
        // 
        // case 11:
        // 11XXXXXX - XXXXXXXX bits
        // XXXXXXXXXXXXXX - dict to read, up to 16384
        switch shr(254, data)
        case 0 {
          let zeroChunks := byte(0, data)

          // update outptr before modifying zeroChunks
          outptr := add(outptr, mul(zeroChunks, 32))

          for {} gt(zeroChunks, 0) {zeroChunks := sub(zeroChunks, 1)} {
            mstore(outptr, 0)
          }

          inptr := add(inptr, 1)
        }
        case 1 {
          let zeroBytes := and(shr(247, data), 0x7F)
          let copyBytes := and(shr(240, data), 0x7F)
 
          // update outptr before modifying zeroBytes
          outptr := add(outptr, zeroBytes)
          
          // set zeroBytes to zero
          for {} gt(zeroBytes, 32) {zeroBytes := sub(zeroBytes, 32)} {
            mstore(outptr, 0)
          }
          mstore(outptr, 0)

          // move inptr to copy byts and copy copyBytes to outptr
          inptr := add(inptr, 2)
          calldatacopy(outptr, inptr, copyBytes)

          inptr := add(inptr, copyBytes)
          outptr := add(outptr, copyBytes)
        }
        case 2 {
          let value := and(shr(240, data), 0x3FFF)
          mstore(outptr, value)

          inptr := add(inptr, 2)
          outptr := add(outptr, 32)
        }
        case 3 {
          let key := and(shr(240, data), 0x3FFF)

          switch key
          case 0 {
            mstore(outptr, caller())
          }
          case 1 {
            mstore(outptr, address())
          }
          default {
            let value := sload(add(_dict.slot, key))
            mstore(outptr, value)
          }

          inptr := add(inptr, 2)
          outptr := add(outptr, 32)
        }
      }

      mstore(raw, sub(sub(outptr, raw), 0x20))
      mstore(0x40, outptr)
    }
  }
}