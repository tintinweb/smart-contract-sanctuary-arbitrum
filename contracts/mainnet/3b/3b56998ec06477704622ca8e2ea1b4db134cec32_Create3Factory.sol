// SPDX-License-Identifier: MIT
// Modified from https://github.com/lifinance/create3-factory/blob/main/src/CREATE3Factory.sol
pragma solidity ^0.8.0;

import {Create3} from './Create3.sol';
import {Ownable} from '../oz-common/Ownable.sol';
import {ICreate3Factory} from './interfaces/ICreate3Factory.sol';

/**
  * @title Factory for deploying contracts to deterministic addresses via Create3
  * @author BGD Labs
  * @notice Enables deploying contracts using CREATE3. Each deployer (msg.sender) has its own namespace for deployed addresses.
  */
contract Create3Factory is ICreate3Factory {
  /// @inheritdoc	ICreate3Factory
  function create(
    bytes32 salt,
    bytes memory creationCode
  ) external payable returns (address) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(msg.sender, salt));
    return Create3.create3(salt, creationCode, msg.value);
  }

  /// @inheritdoc	ICreate3Factory
  function predictAddress(
    address deployer,
    bytes32 salt
  ) external view returns (address) {
    // hash salt with the deployer address to give each deployer its own namespace
    salt = keccak256(abi.encodePacked(deployer, salt));
    return Create3.addressOf(salt);
  }
}

//SPDX-License-Identifier: Unlicense
// Modified from https://github.com/0xsequence/create3/blob/5a4a152e6be4e0ecfbbbe546992a5aaa43a4c1b0/contracts/Create3.sol by Agustin Aguilar <[email protected]>
pragma solidity ^0.8.0;

/**
 * @title A library for deploying contracts EIP-3171 style.
 * @author BGD Labs
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN

      <--- CODE --->

      0x00    0x36         0x36      CALLDATASIZE      cds
      0x01    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x02    0x80         0x80      DUP1              0 0 cds
      0x03    0x37         0x37      CALLDATACOPY
      0x04    0x36         0x36      CALLDATASIZE      cds
      0x05    0x3d         0x3d      RETURNDATASIZE    0 cds
      0x06    0x34         0x34      CALLVALUE         val 0 cds
      0x07    0xf0         0xf0      CREATE            addr
      0x08    0xff         0xff      SELFDESTRUCT
  */
  bytes internal constant PROXY_CHILD_BYTECODE =
    hex'63_00_00_00_09_80_60_0E_60_00_39_60_00_F3_36_3d_80_37_36_3d_34_f0_ff';

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE =
    0x68afe50fe78ae96feb6ec11f21f31fdd467c9fcc7add426282cfa3913daf04e9;

  /**
   * @notice Returns the size of the code on a given address
   * @param addr Address that may or may not contain code
   * @return size of the code on the given `_addr`
   */
  function codeSize(address addr) internal view returns (uint256 size) {
    assembly {
      size := extcodesize(addr)
    }
  }

  /**
   * @notice Creates a new contract with given `_creationCode` and `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
   * @return address of the deployed contract, reverts on error
   */
  function create3(
    bytes32 salt,
    bytes memory creationCode
  ) internal returns (address) {
    return create3(salt, creationCode, 0);
  }

  /**
   * @notice Creates a new contract with given `_creationCode` and `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
   * @param value In WEI of ETH to be forwarded to child contract
   * @return addr of the deployed contract, reverts on error
   */
  function create3(
    bytes32 salt,
    bytes memory creationCode,
    uint256 value
  ) internal returns (address) {
    // Creation code
    bytes memory proxyCreationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    address deployedContract = addressOf(salt);
    if (codeSize(deployedContract) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy;
    assembly {
      proxy := create2(
        value,
        add(proxyCreationCode, 32),
        mload(proxyCreationCode),
        salt
      )
    }
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success, ) = proxy.call(creationCode);
    if (!success || codeSize(deployedContract) == 0) revert ErrorCreatingContract();
    return deployedContract;
  }

  /**
   * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @return address of the deployed contract, reverts on error
   * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
   */
  function addressOf(bytes32 salt) internal view returns (address) {
    return addressOfWithPreDeployedFactory(salt, address(this));
  }

  /**
   * @notice Computes the resulting address of a contract deployed using address of pre-deployed factory and the given `_salt`
   * @param salt Salt of the contract creation, resulting address will be derivated from this value only
   * @param preDeployedFactory address of a pre deployed create 3 factory (its the address that will be used to create the proxy)
   * @return address of the deployed contract, reverts on error
   * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(preDeployedFactory) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
   */
  function addressOfWithPreDeployedFactory(
    bytes32 salt,
    address preDeployedFactory
  ) internal pure returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              preDeployedFactory,
              salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return
      address(
        uint160(
          uint256(keccak256(abi.encodePacked(hex'd6_94', proxy, hex'01')))
        )
      );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

// SPDX-License-Identifier: AGPL-3.0
// Modified from https://github.com/lifinance/create3-factory/blob/main/src/ICREATE3Factory.sol
pragma solidity >=0.6.0;

/**
 * @title Factory for deploying contracts to deterministic addresses via Create3
 * @author BGD Labs
 * @notice Defines the methods implemented on Create3Factory contract
 */
interface ICreate3Factory {
  /**
   * @notice Deploys a contract using Create3
   * @dev The provided salt is hashed together with msg.sender to generate the final salt
   * @param salt The deployer-specific salt for determining the deployed contract's address
   * @param creationCode The creation code of the contract to deploy
   * @return The address of the deployed contract
   */
  function create(
    bytes32 salt,
    bytes memory creationCode
  ) external payable returns (address);

  /**
   * @notice Predicts the address of a deployed contract
   * @dev The provided salt is hashed together with the deployer address to generate the final salt
   * @param deployer The deployer account that will call deploy()
   * @param salt The deployer-specific salt for determining the deployed contract's address
   * @return The address of the contract that will be deployed
   */
  function predictAddress(
    address deployer,
    bytes32 salt
  ) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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