// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { AddressAliasHelper } from "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

import "../interfaces/ICrossChainExecutor.sol";
import "../libraries/CallLib.sol";

/**
 * @title CrossChainExecutorArbitrum contract
 * @notice The CrossChainExecutorArbitrum contract executes calls from the Ethereum chain.
 *         These calls are sent by the `CrossChainRelayerArbitrum` contract which lives on the Ethereum chain.
 */
contract CrossChainExecutorArbitrum is ICrossChainExecutor {
  /* ============ Variables ============ */

  /// @notice Address of the relayer contract on the Ethereum chain.
  ICrossChainRelayer public relayer;

  /**
   * @notice Nonce to uniquely identify the batch of calls that were executed.
   *         nonce => boolean
   * @dev Ensure that batch of calls cannot be replayed once they have been executed.
   */
  mapping(uint256 => bool) public executed;

  /* ============ External Functions ============ */

  /// @inheritdoc ICrossChainExecutor
  function executeCalls(
    uint256 _nonce,
    address _sender,
    CallLib.Call[] calldata _calls
  ) external {
    ICrossChainRelayer _relayer = relayer;
    _isAuthorized(_relayer);

    bool _executedNonce = executed[_nonce];
    executed[_nonce] = true;

    CallLib.executeCalls(_nonce, _sender, _calls, _executedNonce);

    emit ExecutedCalls(_relayer, _nonce);
  }

  /**
   * @notice Set relayer contract address.
   * @dev Will revert if it has already been set.
   * @param _relayer Address of the relayer contract on the Ethereum chain
   */
  function setRelayer(ICrossChainRelayer _relayer) external {
    require(address(relayer) == address(0), "Executor/relayer-already-set");
    relayer = _relayer;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Check that the message came from the `relayer` on the Ethereum chain.
   * @dev We check that the sender is the L1 contract's L2 alias.
   * @param _relayer Address of the relayer on the Ethereum chain
   */
  function _isAuthorized(ICrossChainRelayer _relayer) internal view {
    require(
      msg.sender == AddressAliasHelper.applyL1ToL2Alias(address(_relayer)),
      "Executor/sender-unauthorized"
    );
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./ICrossChainRelayer.sol";

import "../libraries/CallLib.sol";

/**
 * @title CrossChainExecutor interface
 * @notice CrossChainExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface ICrossChainExecutor {
  /**
   * @notice Emitted when calls have successfully been executed.
   * @param relayer Address of the contract that relayed the calls on the origin chain
   * @param nonce Nonce to uniquely identify the batch of calls
   */
  event ExecutedCalls(ICrossChainRelayer indexed relayer, uint256 indexed nonce);

  /**
   * @notice Execute calls from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must emit the `ExecutedCalls` event once calls have been executed.
   * @param nonce Nonce to uniquely idenfity the batch of calls
   * @param sender Address of the sender on the origin chain
   * @param calls Array of calls being executed
   */
  function executeCalls(
    uint256 nonce,
    address sender,
    CallLib.Call[] calldata calls
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "../libraries/CallLib.sol";

/**
 * @title CrossChainRelayer interface
 * @notice CrossChainRelayer interface of the ERC-5164 standard as defined in the EIP.
 */
interface ICrossChainRelayer {
  /**
   * @notice Custom error emitted if the `gasLimit` passed to `relayCalls`
   *         is greater than the one provided for free on the receiving chain.
   * @param gasLimit Gas limit passed to `relayCalls`
   * @param maxGasLimit Gas limit provided for free on the receiving chain
   */
  error GasLimitTooHigh(uint256 gasLimit, uint256 maxGasLimit);

  /**
   * @notice Emitted when calls have successfully been relayed to the executor chain.
   * @param nonce Nonce to uniquely idenfity the batch of calls
   * @param sender Address of the sender
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   */
  event RelayedCalls(
    uint256 indexed nonce,
    address indexed sender,
    CallLib.Call[] calls,
    uint256 gasLimit
  );

  /**
   * @notice Relay the calls to the receiving chain.
   * @dev Must increment a `nonce` so that the batch of calls can be uniquely identified.
   * @dev Must emit the `RelayedCalls` event when successfully called.
   * @dev May require payment. Some bridges may require payment in the native currency, so the function is payable.
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   * @return uint256 Nonce to uniquely idenfity the batch of calls
   */
  function relayCalls(CallLib.Call[] calldata calls, uint256 gasLimit)
    external
    payable
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

/**
 * @title CallLib
 * @notice Library to declare and manipulate Call(s).
 */
library CallLib {
  /* ============ Structs ============ */

  /**
   * @notice Call data structure
   * @param target Address that will be called on the receiving chain
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }

  /* ============ Custom Errors ============ */

  /**
   * @notice Custom error emitted if a call to a target contract fails.
   * @param callIndex Index of the failed call
   * @param errorData Error data returned by the failed call
   */
  error CallFailure(uint256 callIndex, bytes errorData);

  /**
   * @notice Emitted when a batch of calls has already been executed.
   * @param nonce Nonce to uniquely identify the batch of calls that were re-executed
   */
  error CallsAlreadyExecuted(uint256 nonce);

  /* ============ Internal Functions ============ */

  /**
   * @notice Execute calls from the origin chain.
   * @dev Will revert if `_calls` have already been executed.
   * @dev Will revert if a call fails.
   * @dev Must emit the `ExecutedCalls` event once calls have been executed.
   * @param _nonce Nonce to uniquely idenfity the batch of calls
   * @param _sender Address of the sender on the origin chain
   * @param _calls Array of calls being executed
   * @param _executedNonce Whether `_calls` have already been executed or not
   */
  function executeCalls(
    uint256 _nonce,
    address _sender,
    Call[] memory _calls,
    bool _executedNonce
  ) internal {
    if (_executedNonce) {
      revert CallsAlreadyExecuted(_nonce);
    }

    uint256 _callsLength = _calls.length;

    for (uint256 _callIndex; _callIndex < _callsLength; _callIndex++) {
      Call memory _call = _calls[_callIndex];

      (bool _success, bytes memory _returnData) = _call.target.call(
        abi.encodePacked(_call.data, _nonce, _sender)
      );

      if (!_success) {
        revert CallFailure(_callIndex, _returnData);
      }
    }
  }
}