// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Llama Executor
/// @author Llama ([email protected])
/// @notice The exit point of a Llama instance. It calls the target contract during action execution.
contract LlamaExecutor {
  /// @dev Only callable by a Llama instance's core contract.
  error OnlyLlamaCore();

  /// @notice The core contract for this Llama instance.
  address public immutable LLAMA_CORE;

  /// @dev This contract is deployed from the core's `initialize` function.
  constructor() {
    LLAMA_CORE = msg.sender;
  }

  /// @notice Called by `executeAction` in the core contract to make the call described by the action.
  /// @dev Using a separate executor contract ensures `target` being delegatecalled cannot write to `LlamaCore`'s
  /// storage. By using a sole executor for calls and delegatecalls,
  /// a Llama instance is represented by one contract address.
  /// @param target The contract called when the action is executed.
  /// @param isScript A boolean that determines if the target is a script and should be delegatecalled.
  /// @param data Data to be called on the `target` when the action is executed.
  /// @return success A boolean that indicates if the call succeeded.
  /// @return result The data returned by the function being called.
  function execute(address target, bool isScript, bytes calldata data)
    external
    payable
    returns (bool success, bytes memory result)
  {
    if (msg.sender != LLAMA_CORE) revert OnlyLlamaCore();
    (success, result) = isScript ? target.delegatecall(data) : target.call{value: msg.value}(data);
  }
}