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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2023 VALK
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.18;

interface ISmartWallet {
  function exec(
    bytes20 target, // name or address of target script 
    bytes memory data
  ) external payable returns (bytes memory response);

  event SW_Exec(address indexed sender, bytes4 indexed selector, address indexed dispatchedTarget, bytes20 target, uint value);
  event SW_ExecDirect(address indexed sender, bytes4 indexed selector, address indexed dispatchedTarget, uint value);
  event SW_Fallback(address indexed sender, bytes4 indexed selector, uint value);
  event SW_SetOwner(address indexed owner);
  event SW_SetDispatcher(address indexed dispatcher);

  function owner() external view returns (address);
  function dispatcher() external view returns (address);
  function setDispatcher(address _dispatcher) external;
  function registry() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2023 VALK
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.18;

interface ISmartWalletFactory {
  function smartWalletImplementation() external view returns (address);
  function dispatcher() external view returns (address);

  function findNewSmartWalletAddress(address user, uint96 initialSeed) external view returns (address smartWallet, uint96 seed);
  function build(address creator, uint96 seed) external returns (address smartWallet);
  function buildAndExec(address creator, uint96 seed, bytes20 target, bytes calldata data) external payable returns (bytes memory response);
  
  // new implementations of ISmartWalletFactory should be able to return implementation of old wallets
  function getWalletImplementation(address smartWallet) external view returns (address impl);

    event SmartWalletCreated(address indexed smartWallet, address indexed creator, uint96 indexed seed);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2023 VALK
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.18;

import "./ISmartWalletFactory.sol";

interface ISmartWalletRegistry {
  event SetSmartWalletFactory(ISmartWalletFactory indexed oldFactory, ISmartWalletFactory indexed newFactory);
  event SmartWalletClaimed(address indexed smartWallet, address indexed owner, address indexed oldSmartWallet);

  function getUserWallet(address user) external view returns (address smartWallet, uint96 seed);
  function dispatcher() external view returns (address);

  function build(address user) external returns (address smartWallet);
  function buildAndExec(bytes20 target, bytes calldata data) external payable returns (bytes memory response);
  function claim(address smartWallet, bool allowReplacing) external returns (address oldWallet);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2022 Dai Foundation
// Copyright (C) 2023 VALK
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.18;

import "./ISmartWallet.sol";
import "./ISmartWalletFactory.sol";
import "./ISmartWalletRegistry.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartWalletRegistry is Ownable, ISmartWalletRegistry {
	ISmartWalletFactory public smartWalletFactory;

  struct UserProfile {
    address smartWallet;
    uint96 seed;
  }

  mapping( /* user */ address => UserProfile) public userProfiles;
  // linked list of historical smart wallet implementations. Last element refers to itself.
  mapping( /* implementation */ address => /* prevImplementation */ address) public prevImplementations; 

	function setSmartWalletFactory(ISmartWalletFactory newFactory) public onlyOwner {
		require(address(newFactory) != address(0), "SWR: implementation required");
    address newImplementation = newFactory.smartWalletImplementation();
    
    ISmartWalletFactory oldFactory = smartWalletFactory;
    address oldImplementation;

    if (address(oldFactory) != address(0)) {
      oldImplementation = oldFactory.smartWalletImplementation();
      if (newImplementation != oldImplementation) {
        prevImplementations[newImplementation] = oldImplementation;
      }
    } else {
      prevImplementations[newImplementation] = newImplementation;
    }

    smartWalletFactory = newFactory;
    emit SetSmartWalletFactory(oldFactory, newFactory);
	}

  function getUserWallet(address user) public view returns (address, uint96) {
    UserProfile memory profile = userProfiles[user];

		if (profile.smartWallet != address(0)) {
      try ISmartWallet(profile.smartWallet).owner() returns (address owner) {
        if (owner == user) {
          return (profile.smartWallet, 0);
        }
      } catch {
        // the wallet was selfdestructed
      }
    }

    return smartWalletFactory.findNewSmartWalletAddress(user, profile.seed);
  }

	function build(address user) external returns (address) {
		(address smartWallet, uint96 seed) = getUserWallet(user);
    require(seed != 0, "SWR: already registered to user"); 
    userProfiles[user] = UserProfile(smartWallet, seed);
    return ISmartWalletFactory(smartWalletFactory).build(user, seed);
	}

	function buildAndExec(bytes20 target, bytes calldata data) external payable returns (bytes memory response) {
    // Prevent pre-creating non-empty wallets for other users for security reasons
		address user = msg.sender;
		// We want to avoid creating a wallet for a contract address that might not be able to handle wallets, then losing the funds
		require(tx.origin == msg.sender, "SWR: usr is a contract"); // solhint-disable-line avoid-tx-origin

    (address smartWallet, uint96 seed) = getUserWallet(user);
    require(seed != 0, "SWR: already registered to user"); 
    userProfiles[user] = UserProfile(smartWallet, seed);
    response = smartWalletFactory.buildAndExec{ value: msg.value }(user, seed, target, data);
	}

  function getWalletImplementation(address smartWallet) external view returns (address) {
		return smartWalletFactory.getWalletImplementation(smartWallet);
	}

	// This function needs to be used carefully, you should only claim a smart wallet you trust on.
	// A smart wallet might be set up with a dispatcher or just simple allowances that might make an
	// attacker to take funds that are sitting in the smart wallet.
	function claim(address smartWallet, bool allowReplacing) external returns (address) {
    require(smartWallet != address(0), "SWR: smartWallet required");
    address walletImplementation = smartWalletFactory.getWalletImplementation(smartWallet);
		require(prevImplementations[walletImplementation] != address(0), "SWR: not acc from this registry");
		address walletOwner = ISmartWallet(payable(smartWallet)).owner();
		require(msg.sender == smartWallet || msg.sender == walletOwner, "SWR: unauthorized claim");

    (address oldWallet, uint seed) = getUserWallet(walletOwner);
    userProfiles[walletOwner].smartWallet = smartWallet;
    
    if (seed == 0) {
      require(allowReplacing, "SWR: already registered to user");
    } else {
      oldWallet = address(0);
    }

    emit SmartWalletClaimed(smartWallet, walletOwner, oldWallet);
    return oldWallet;
  }

  function dispatcher() external view returns (address) {
    return smartWalletFactory.dispatcher();
  }

  function smartWalletImplementation() external view returns (address) {
    return smartWalletFactory.smartWalletImplementation();
  }
}