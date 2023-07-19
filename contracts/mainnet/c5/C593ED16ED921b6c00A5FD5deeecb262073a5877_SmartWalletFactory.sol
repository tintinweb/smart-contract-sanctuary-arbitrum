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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
import { Account, OWNED_SMART_WALLET_ACCOUNT, END_USER_ACCOUNT } from '../utils/Account.sol';

interface IDispatcher {
	function dispatch(
		address source,
		address wallet,
		Account calldata executor,
		bytes20 target,
		bytes4 selector
	) external returns (address dispatchedTarget);
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

import {IDispatcher} from "../dispatchers/IDispatcher.sol";
import { Account, END_USER_ACCOUNT } from '../utils/Account.sol';
import "./ErrorsLib.sol";

library DispatchLib {
  function dispatch(
    address dispatcher,
		address source,
		address wallet,
		Account memory executor,
		bytes20 target,
		bytes4 selector
	) internal returns (address dispatchedTarget) {
    require(source != address(0), "DL: source required");
    require(wallet != address(0), "DL: wallet required");
    require(executor.accountType != END_USER_ACCOUNT, "DL: executor contract required");
    require(executor.accountAddress != address(0), "DL: executor required");
    require(target != bytes20(0), "DL: target required");
    require(selector != bytes4(0), "DL: selector required");

    // gas saving
    if (source == wallet) {
      source = address(0);
    }
    if (address(executor.accountAddress) == wallet) {
      executor.accountAddress = address(0);
    }
    if (address(target) == wallet) {
      target = bytes20(0);
    }

    dispatchedTarget = IDispatcher(dispatcher).dispatch(source, wallet, executor, target, selector);
    if (dispatchedTarget == address(0)) {
      revert ErrorsLib.NotDispatched(dispatcher, source, wallet, executor, target, selector);
    }
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

import { Account } from '../utils/Account.sol';

library ErrorsLib {
  error NotDispatched(
    address dispatcher,
    address source,
    address wallet,
    Account executor,
    bytes20 target,
    bytes4 selector
  );
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
// Copyright (C) 2017 DappHub, LLC
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
import "./SmartWalletStorage.sol";
import { Account, OWNED_SMART_WALLET_ACCOUNT } from "../utils/Account.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../libs/DispatchLib.sol";

contract SmartWallet is ISmartWallet, SmartWalletStorage {
	address public immutable registry;

	constructor(address _registry) {
		registry = _registry;
	}

	function init(
		address _owner,
		address _dispatcher,
		bytes20 target,
		bytes calldata data
	) external payable returns (bytes memory response) {
		require($owner == address(0), "SW: already initialized");

		$owner = _owner;
		emit SW_SetOwner(_owner);
    
		$dispatcher = _dispatcher;
		emit SW_SetDispatcher(_dispatcher);

		if (target == bytes20(0)) {
			return new bytes(0);
		}

		return _exec(_owner, _dispatcher, target, data);
	}

	function owner() external view returns (address) {
		return $owner;
	}

	function dispatcher() external view returns (address) {
		return $dispatcher;
	}

	function setOwner(address _owner) external {
		require(msg.sender == $owner, "SW: set owner not by owner");
		$owner = _owner;
		emit SW_SetOwner(_owner);
	}

	function setDispatcher(address _dispatcher) external {
		require(msg.sender == $owner, "SW: set dispatcher not by owner");
		$dispatcher = _dispatcher;
		emit SW_SetDispatcher(_dispatcher);
	}

	function delegatecall(address target, bytes memory data) internal returns (bytes memory response) {
		assembly {
			let succeeded := delegatecall(gas(), target, add(data, 0x20), mload(data), 0, 0)
			let size := returndatasize()

			response := mload(0x40)
			mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
			mstore(response, size)
			returndatacopy(add(response, 0x20), 0, size)

			switch succeeded
			case 0 {
				revert(add(response, 0x20), size)
			}
		}
	}

  function _exec(address sender, address _dispatcher, bytes20 target, bytes calldata data) internal returns (bytes memory response) {
		require(address(target) != address(this), "SW: cannot exec self");
    require(target != bytes20(0), "SW: target required");
    bytes4 selector = bytes4(data[0:4]);
    address dispatchedTarget = address(target);

		if (_dispatcher == address(0)) {
			require(sender == $owner || sender == address(this), "SW: exec not authorized");
		} else {
			dispatchedTarget = DispatchLib.dispatch({
        dispatcher: _dispatcher,
				source: sender,
        wallet: address(this),
				executor: Account(address(this), OWNED_SMART_WALLET_ACCOUNT),
				target: target,
				selector: selector
      });
		}
    
    emit SW_Exec(sender, selector, dispatchedTarget, target, msg.value);
		return delegatecall(dispatchedTarget, data);
	}

	function exec(bytes20 target, bytes calldata data) external payable returns (bytes memory response) {
		return _exec(msg.sender, $dispatcher, target, data);
	}

	receive() external payable {
		emit SW_Fallback(msg.sender, msg.sig, msg.value);
	}

	fallback(bytes calldata data) external payable returns (bytes memory result) {
		address target;
		if (msg.sig != 0x00000000) {
			address _dispatcher = $dispatcher;

			if (_dispatcher != address(0)) {
				target = DispatchLib.dispatch({
          dispatcher: _dispatcher,
					source: msg.sender,
          wallet: address(this),
					executor: Account(address(this), OWNED_SMART_WALLET_ACCOUNT),
					target: bytes20(address(this)),
					selector: msg.sig
        });
        emit SW_ExecDirect(msg.sender, msg.sig, target, msg.value);
        return delegatecall(target, data);
			}
		}
		
    emit SW_Fallback(msg.sender, msg.sig, msg.value);
    return bytes.concat(bytes32(msg.sig)); // answer to onERCXXXReceived and similar
	}
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

import "./SmartWallet.sol";
import "./ISmartWalletFactory.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartWalletFactory is ISmartWalletFactory {
	address public immutable smartWalletImplementation;
	address public immutable dispatcher;
  
  constructor(address _smartWalletImplementation, address _dispatcher) {    
    smartWalletImplementation = _smartWalletImplementation;
    dispatcher = _dispatcher;
  }

  function _build(address creator, uint96 seed) internal returns (address smartWallet) {
		bytes32 salt = keccak256(abi.encode(creator, seed));
    address implementation = smartWalletImplementation;
    assembly {
        // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
        // of the `implementation` address with the bytecode before the address.
        mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
        // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
        mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
        smartWallet := create2(0, 0x09, 0x37, salt)
    }
    if (smartWallet != address(0)) {
      emit SmartWalletCreated(smartWallet, creator, seed);
    }
	}

	function build(address creator, uint96 seed) external returns (address smartWallet) {
    smartWallet = _build(creator, seed);
    if (smartWallet == address(0)) {
      smartWallet = getSmartWalletAddress(creator, seed);
      // EXTCODELENGTH may not access address with no code for eip-4337 validation
      // but wallet never exist on initCode validation, so this code will be never executed in that case
      require(walletExists(smartWallet), "ERC1167: create2 failed");
    } else {
      SmartWallet(payable(smartWallet)).init(creator, dispatcher, bytes20(0), new bytes(0));
    }
	}

	function buildAndExec(address creator, uint96 seed, bytes20 target, bytes calldata data) external payable returns (bytes memory response) {
		SmartWallet smartWallet = SmartWallet(payable(_build(creator, seed)));
    require(address(smartWallet) != address(0), "ERC1167: create2 failed");
		response = smartWallet.init{ value: msg.value }(creator, dispatcher, target, data);
	}

	function getSmartWalletAddress(address usr, uint96 seed) public view returns (address) {
		bytes32 salt = keccak256(abi.encode(usr, seed));
		return Clones.predictDeterministicAddress(smartWalletImplementation, salt);
	}

  function walletExists(address smartWallet) private view returns (bool) {
    return smartWallet.code.length > 2;
  }

  function findNewSmartWalletAddress(address user, uint96 initialSeed) external view returns (address smartWallet, uint96 seed) {
		seed = initialSeed;
    do {
      seed = seed + 1;
      smartWallet = getSmartWalletAddress(user,  seed);
    } while(walletExists(smartWallet));
	}

  function getWalletImplementation(address smartWallet) external view returns (address impl) {
    bytes memory code = smartWallet.code;
    require(code.length == 45, "ERC1167: wrong clone codesize");
    // pad code to 64 bytes and position implementation address at lower 20 bytes of word 0
    code = bytes.concat(new bytes(2), code, new bytes(17));
    (uint word0, uint word1) = abi.decode(code, (uint, uint));
    impl = address(uint160(word0));
    uint otherBytes = (word0 >> 160) | word1;
    // check that rest of the code matches ERC-1167 standart
    require(otherBytes == 0x5af43d82803e903d91602b57fd5bf300000000000000363d3d373d3d3d363d73, 
      "ERC1167: wrong clone bytes");
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

abstract contract SmartWalletStorage {
  address internal $dispatcher;
  address internal $owner;
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

uint8 constant END_USER_ACCOUNT = 0;
uint8 constant OWNED_SMART_WALLET_ACCOUNT = 1;
uint8 constant OWNED_DS_PROXY_ACCOUNT = 2;
uint8 constant OWNED_INSTA_DAPP_ACCOUNT = 3;
uint8 constant ANY_ACCOUNT = type(uint8).max;

struct Account {
	address accountAddress;
	uint8 accountType;
}