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

// import "hardhat/console.sol";

import "./DecompressorExtension.sol";

interface ForwarderInterface {
  struct ForwardRequest {
    address from;
    address to;
    address feeToken;
    uint256 value;
    uint256 gas;
    uint256 nonce;
    uint256 validUntilTime;
    bytes data;
  }

  function getFeeSetting() external view returns (uint256, uint256, uint256, uint256);
  function execute(ForwardRequest calldata req, bytes calldata sig) external payable returns (bool success, bytes memory returnData);
}

contract BatchInbox is DecompressorExtension {

  ForwarderInterface forwarder;

  uint256 minGasUsed;

  // events
  event ForwarderReverted(address indexed from, address to, uint256 nonce, string errorMsg);

  constructor(address _forwarder) {
    forwarder = ForwarderInterface(_forwarder);
    (, , , minGasUsed) = forwarder.getFeeSetting();
  }

  fallback() external {
    bytes1 selector = bytes1(msg.data[0:1]);
    bytes memory data = _decompressed(msg.data[1:]);

    // executeBatch
    if (selector == 0x01) {
      (ForwarderInterface.ForwardRequest[] memory reqs, bytes[] memory sigs) = abi.decode(data, (ForwarderInterface.ForwardRequest[], bytes[]));
      executeBatch(reqs, sigs);
    }
  }

  function executeBatch(
    ForwarderInterface.ForwardRequest[] memory reqs,
    bytes[] memory sigs
  ) public payable {
    require(reqs.length == sigs.length, "BatchInbox: number of requests does not match number of signatures");

    uint256 count = reqs.length;
    for (uint i = 0; i < count; i++) {
      try forwarder.execute{gas: reqs[i].gas + minGasUsed, value: reqs[i].value}(reqs[i], sigs[i]) returns (bool success, bytes memory returnData) {
        if (!success) emit ForwarderReverted(reqs[i].from, reqs[i].to, reqs[i].nonce, string(returnData));
      } catch Error(string memory reason) {
        emit ForwarderReverted(reqs[i].from, reqs[i].to, reqs[i].nonce, reason);
      }
    }
  }
  
  function setForwarder(address _forwarder) external onlyOwner {
    forwarder = ForwarderInterface(_forwarder);
    (, , , minGasUsed) = forwarder.getFeeSetting();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecompressorExtension
 * @dev A contract that implements a decompression algorithm to be used in conjunction with compressed data.
 */
abstract contract DecompressorExtension is Ownable {
    /**
     * @dev Emitted when an invalid offset is used.
     * @param offset The invalid offset used in the function call.
     */
    error TooSmallOffset(uint256 offset);

    /**
     * @dev The dictionary mapping storage slots to their associated compressed data.
     */
    bytes32[1_048_576] private _dict; // 20 bits

    /**
     * @dev Modifier to check that the offset used in a function call is valid. Offsets less 2 are reserved with `msg.sender`and `address(this)`
     * @param offset The offset value to be checked.
     */
    modifier validOffset(uint256 offset) {
        if (offset < 2) revert TooSmallOffset(offset);
        _;
    }

    /**
     * @dev Returns the data stored in the dictionary in the specified range.
     * @param begin The starting index of the data range to return. First 2 positions are reserved, so it should be greater than 1.
     * @param end The ending index of the data range to return.
     * @return res An array of bytes32 values containing the data in the specified range.
     */
    function getData(
        uint256 begin,
        uint256 end
    ) external view validOffset(begin) returns (bytes32[] memory res) {
        unchecked {
            if (begin < end) {
                res = new bytes32[](end - begin);
                for (uint256 i = begin; i < end; i++) {
                    res[i - begin] = _dict[i];
                }
            }
        }
    }

    /**
     * @dev Sets the data at the specified dictionary offset.
     * @param offset The dictionary offset to set the data at. First 2 positions are reserved, sdecompresso it should be greater than 1.
     * @param data The data to be stored at the specified offset.
     */
    function setData(
        uint256 offset,
        bytes32 data
    ) external validOffset(offset) onlyOwner {
        unchecked {
            _dict[offset] = data;
        }
    }

    /**
     * @dev Sets an array of data starting at the specified dictionary offset.
     * @param offset The starting dictionary offset to set the data at. First 2 positions are reserved, so it should be greater than 1.
     * @param dataArray The array of data to be stored starting at the specified offset.
     */
    function setDataArray(
        uint256 offset,
        bytes32[] calldata dataArray
    ) external validOffset(offset) onlyOwner {
        unchecked {
            for (uint256 i = 0; i < dataArray.length; i++) {
                _dict[offset + i] = dataArray[i];
            }
        }
    }

    /**
     * @dev Decompresses the compressed data (N bytes) passed to the function using the _delegatecall function.
     */
    function decompress() external payable {
        _delegatecall(decompressed());
    }

    /**
     * @dev Calculates and returns the decompressed data from the compressed calldata.
     * @return raw The decompressed raw data.
     */
    function decompressed() public view returns (bytes memory raw) {
        return _decompressed(msg.data[4:]);
    }

    /**
     * @dev Calculates and returns the decompressed raw data from the compressed data passed as an argument.
     * @param cd The compressed data to be decompressed.
     * @return raw The decompressed raw data.
     */
    function _decompressed(
        bytes calldata cd
    ) internal view returns (bytes memory raw) {
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            raw := mload(0x40)
            let outptr := add(raw, 0x20)
            let end := add(cd.offset, cd.length)
            for {
                let inptr := cd.offset
            } lt(inptr, end) {

            } {
                // solhint-disable-line no-empty-blocks
                let data := calldataload(inptr)

                let key

                // 00XXXXXX - insert X+1 zero bytes
                // 01PXXXXX - copy X+1 bytes calldata (P means padding to 32 bytes or not)
                // 10BBXXXX XXXXXXXX - use 12 bits as key for [32,20,4,31][B] bytes from storage X
                // 11BBXXXX XXXXXXXX XXXXXXXX - use 20 bits as [32,20,4,31][B] bytes from storage X
                switch shr(254, data)
                case 0 {
                    let size := add(byte(0, data), 1)
                    calldatacopy(outptr, calldatasize(), size)
                    inptr := add(inptr, 1)
                    outptr := add(outptr, size)
                    continue
                }
                case 1 {
                    let size := add(and(0x1F, byte(0, data)), 1)
                    if and(
                        data,
                        0x2000000000000000000000000000000000000000000000000000000000000000
                    ) {
                        mstore(outptr, 0)
                        outptr := add(outptr, sub(32, size))
                    }
                    calldatacopy(outptr, add(inptr, 1), size)
                    inptr := add(inptr, add(1, size))
                    outptr := add(outptr, size)
                    continue
                }
                case 2 {
                    key := shr(244, shl(4, data))
                    inptr := add(inptr, 2)
                    // fallthrough
                }
                case 3 {
                    key := shr(236, shl(4, data))
                    inptr := add(inptr, 3)
                    // fallthrough
                }

                // TODO: check sload argument
                let value
                switch key
                case 0 {
                    value := caller()
                }
                case 1 {
                    value := address()
                }
                default {
                    value := sload(add(_dict.slot, key))
                }

                switch shr(254, shl(2, data))
                case 0 {
                    mstore(outptr, value)
                    outptr := add(outptr, 32)
                }
                case 1 {
                    mstore(outptr, shl(96, value))
                    outptr := add(outptr, 20)
                }
                case 2 {
                    mstore(outptr, shl(224, value))
                    outptr := add(outptr, 4)
                }
                default {
                    mstore(outptr, shl(8, value))
                    outptr := add(outptr, 31)
                }
            }
            mstore(raw, sub(sub(outptr, raw), 0x20))
            mstore(0x40, outptr)
        }
    }

    /**
     * @dev Executes a delegate call to the raw data calculated by the _decompressed function.
     * @param raw The raw data to execute the delegate call with.
     */
    function _delegatecall(bytes memory raw) internal {
        assembly ("memory-safe") {
            // solhint-disable-line no-inline-assembly
            let success := delegatecall(
                gas(),
                address(),
                add(raw, 0x20),
                mload(raw),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            if success {
                return(0, returndatasize())
            }
            revert(0, returndatasize())
        }
    }
}