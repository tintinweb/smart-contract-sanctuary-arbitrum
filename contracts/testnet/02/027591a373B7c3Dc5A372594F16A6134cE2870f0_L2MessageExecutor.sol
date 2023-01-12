// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2019-2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.7.5;

library AddressAliasHelper {
  uint160 constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

  /// @notice Utility function that converts the address in the L1 that submitted a tx to
  /// the inbox to the msg.sender viewed in the L2
  /// @param l1Address the address in the L1 that triggered the tx to L2
  /// @return l2Address L2 address as viewed in msg.sender
  function applyL1ToL2Alias(address l1Address)
    internal
    pure
    returns (address l2Address)
  {
    l2Address = address(uint160(l1Address) + OFFSET);
  }

  /// @notice Utility function that converts the msg.sender viewed in the L2 to the
  /// address in the L1 that submitted a tx to the inbox
  /// @param l2Address L2 address as viewed in msg.sender
  /// @return l1Address the address in the L1 that triggered the tx to L2
  function undoL1ToL2Alias(address l2Address)
    internal
    pure
    returns (address l1Address)
  {
    l1Address = address(uint160(l2Address) - OFFSET);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AddressAliasHelper} from "./AddressAliasHelper.sol";

/**
 * @dev This contract executes messages received from layer1 governance on arbitrum.
 * This meant to be an upgradeable contract and it should only be used with TransparentUpgradeableProxy.
 */
contract L2MessageExecutor is ReentrancyGuard {
  /// @notice Address of the L1MessageRelayer contract on mainnet.
  address public l1MessageRelayer;

  /// @dev flag to make sure that the initialize function is only called once
  bool private isInitialized = false;

  function initialize(address _l1MessageRelayer) external {
    require(!isInitialized, "Contract is already initialized!");
    isInitialized = true;
    require(
      _l1MessageRelayer != address(0),
      "_l1MessageRelayer can't be the zero address"
    );
    l1MessageRelayer = _l1MessageRelayer;
  }

  /**
   * @notice Throws if called by any account other than this contract.
   **/
  modifier onlyThis() {
    require(
      msg.sender == address(this),
      "L2MessageExecutor: Unauthorized message sender"
    );
    _;
  }

  /**
   * @notice executes message received from L1.
   * @param payLoad message received from L1 that needs to be executed.
   **/
  function executeMessage(bytes calldata payLoad) external nonReentrant {
    // To check that message came from L1, we check that the sender is the L1 contract's L2 alias.
    require(
      msg.sender == AddressAliasHelper.applyL1ToL2Alias(l1MessageRelayer),
      "L2MessageExecutor::executeMessage: Unauthorized message sender"
    );

    (address target, bytes memory callData) = abi.decode(
      payLoad,
      (address, bytes)
    );
    require(target != address(0), "target can't be the zero address");
    (bool success, ) = target.call(callData);
    require(
      success,
      "L2MessageExecutor::executeMessage: Message execution reverted."
    );
  }
}