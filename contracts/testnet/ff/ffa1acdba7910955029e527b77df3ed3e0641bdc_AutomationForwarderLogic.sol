// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAutomationRegistryConsumer} from "./interfaces/IAutomationRegistryConsumer.sol";
import {ITypeAndVersion} from "../../../shared/interfaces/ITypeAndVersion.sol";

contract AutomationForwarderLogic is ITypeAndVersion {
  IAutomationRegistryConsumer private s_registry;

  string public constant example = "";
  string public constant typeAndVersion = "AutomationForwarder 1.0.0";

  /**
   * @notice updateRegistry is called by the registry during migrations
   * @param newRegistry is the registry that this forwarder is being migrated to
   */
  function updateRegistry(address newRegistry) external {
    if (msg.sender != address(s_registry)) revert();
    s_registry = IAutomationRegistryConsumer(newRegistry);
  }

  function getRegistry() external view returns (IAutomationRegistryConsumer) {
    return s_registry;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice IAutomationRegistryConsumer defines the LTS user-facing interface that we intend to maintain for
 * across upgrades. As long as users use functions from within this interface, their upkeeps will retain
 * backwards compatability across migrations.
 * @dev Functions can be added to this interface, but not removed.
 */
interface IAutomationRegistryConsumer {
  function getBalance(uint256 id) external view returns (uint96 balance);

  function getMinBalance(uint256 id) external view returns (uint96 minBalance);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function withdrawFunds(uint256 id, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITypeAndVersion {
  function typeAndVersion() external pure returns (string memory);
}