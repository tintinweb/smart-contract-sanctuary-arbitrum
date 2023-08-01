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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import './IRegistry.sol';

/**
 * @dev Registry interface
 */
interface IRegistry {
    /**
     * @dev The implementation address is zero
     */
    error RegistryImplementationAddressZero();

    /**
     * @dev The implementation is already registered
     */
    error RegistryImplementationRegistered(address implementation);

    /**
     * @dev The implementation is not registered
     */
    error RegistryImplementationNotRegistered(address implementation);

    /**
     * @dev The implementation is already deprecated
     */
    error RegistryImplementationDeprecated(address implementation);

    /**
     * @dev Emitted every time an implementation is registered
     */
    event Registered(address indexed implementation, string name, bool stateless);

    /**
     * @dev Emitted every time an implementation is deprecated
     */
    event Deprecated(address indexed implementation);

    /**
     * @dev Tells whether an implementation is registered
     * @param implementation Address of the implementation being queried
     */
    function isRegistered(address implementation) external view returns (bool);

    /**
     * @dev Tells whether an implementation is stateless or not
     * @param implementation Address of the implementation being queried
     */
    function isStateless(address implementation) external view returns (bool);

    /**
     * @dev Tells whether an implementation is deprecated
     * @param implementation Address of the implementation being queried
     */
    function isDeprecated(address implementation) external view returns (bool);

    /**
     * @dev Creates and registers an implementation
     * @param name Name of the implementation
     * @param code Code of the implementation to create and register
     * @param stateless Whether the new implementation is considered stateless or not
     */
    function create(string memory name, bytes memory code, bool stateless) external;

    /**
     * @dev Registers an implementation
     * @param name Name of the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the given implementation is considered stateless or not
     */
    function register(string memory name, address implementation, bool stateless) external;

    /**
     * @dev Deprecates an implementation
     * @param implementation Address of the implementation to be deprecated
     */
    function deprecate(address implementation) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import 'solmate/src/utils/CREATE3.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import './interfaces/IRegistry.sol';

/**
 * @title Registry
 * @dev Curated list of Mimic implementations
 */
contract Registry is IRegistry, Ownable {
    // List of registered implementations
    mapping (address => bool) public override isRegistered;

    // List of stateless implementations
    mapping (address => bool) public override isStateless;

    // List of deprecated implementations
    mapping (address => bool) public override isDeprecated;

    /**
     * @dev Creates a new Registry contract
     * @param owner Address that will own the registry
     */
    constructor(address owner) {
        _transferOwnership(owner);
    }

    /**
     * @dev Creates and registers an implementation
     * @param name Name of the implementation
     * @param code Code of the implementation to create and register
     * @param stateless Whether the new implementation is considered stateless or not
     */
    function create(string memory name, bytes memory code, bool stateless) external override onlyOwner {
        address implementation = CREATE3.deploy(keccak256(abi.encode(name)), code, 0);
        _register(name, implementation, stateless);
    }

    /**
     * @dev Registers an implementation
     * @param name Name logged for the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the given implementation is considered stateless or not
     */
    function register(string memory name, address implementation, bool stateless) external override onlyOwner {
        _register(name, implementation, stateless);
    }

    /**
     * @dev Deprecates an implementation
     * @param implementation Address of the implementation to be deprecated
     */
    function deprecate(address implementation) external override onlyOwner {
        if (implementation == address(0)) revert RegistryImplementationAddressZero();
        if (!isRegistered[implementation]) revert RegistryImplementationNotRegistered(implementation);
        if (isDeprecated[implementation]) revert RegistryImplementationDeprecated(implementation);

        isDeprecated[implementation] = true;
        emit Deprecated(implementation);
    }

    /**
     * @dev Registers an implementation
     * @param name Name of the implementation
     * @param implementation Address of the implementation to be registered
     * @param stateless Whether the given implementation is considered stateless or not
     */
    function _register(string memory name, address implementation, bool stateless) internal {
        if (implementation == address(0)) revert RegistryImplementationAddressZero();
        if (isRegistered[implementation]) revert RegistryImplementationRegistered(implementation);

        isRegistered[implementation] = true;
        isStateless[implementation] = stateless;
        emit Registered(implementation, name, stateless);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}