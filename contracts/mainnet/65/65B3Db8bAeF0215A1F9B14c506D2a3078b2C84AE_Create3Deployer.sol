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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Create3.sol";

contract Create3Deployer is Ownable {
    function deploy(bytes32 salt, bytes calldata code) external onlyOwner returns (address) {
        return Create3.create3(salt, code);
    }

    function addressOf(bytes32 salt) external view returns (address) {
        return Create3.addressOf(salt);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f0ff3d5260086017f3:
      0x00  0x68  0x68XXXXXXXXXXXXXXXXXX  PUSH9 bytecode  0x363d3d37363d34f0ff
      0x01  0x3d  0x3d                    RETURNDATASIZE  0 0x363d3d37363d34f0ff
      0x02  0x52  0x52                    MSTORE
      0x03  0x60  0x6009                  PUSH1 09        9
      0x04  0x60  0x6017                  PUSH1 17        23 9
      0x05  0xf3  0xf3                    RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                    CALLDATASIZE    cds
      0x01  0x3d  0x3d                    RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                    RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                    CALLDATACOPY
      0x04  0x36  0x36                    CALLDATASIZE    cds
      0x05  0x3d  0x3d                    RETURNDATASIZE  0 cds
      0x06  0x34  0x34                    CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                    CREATE          addr
      0x08  0xff  0xff                    SELFDESTRUCT
  */

  bytes private constant _PROXY_CHILD_BYTECODE = hex"68_36_3d_3d_37_36_3d_34_f0_ff_3d_52_60_09_60_17_f3";

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 private constant _KECCAK256_PROXY_CHILD_BYTECODE = keccak256(_PROXY_CHILD_BYTECODE); // 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = _PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (addr.code.length != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    // solhint-disable-next-line no-inline-assembly
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    // solhint-disable-next-line avoid-low-level-calls
    (bool success,) = proxy.call(_creationCode);
    if (!success || addr.code.length == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              _KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
  }
}