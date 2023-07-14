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