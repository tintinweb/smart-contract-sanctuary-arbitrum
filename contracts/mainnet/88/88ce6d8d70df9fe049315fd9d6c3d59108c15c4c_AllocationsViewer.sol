// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/IGatewayRegistry.sol";
import "./interfaces/IGatewayStrategy.sol";

contract AllocationsViewer {
  IGatewayRegistry public gatewayRegistry;

  constructor(IGatewayRegistry _gatewayRegistry) {
    gatewayRegistry = _gatewayRegistry;
  }

  struct Allocation {
    bytes gatewayId;
    uint256 allocated;
    address operator;
  }

  function getAllocations(uint256 workerId, uint256 pageNumber, uint256 perPage)
    external
    view
    returns (Allocation[] memory)
  {
    bytes[] memory gateways = gatewayRegistry.getActiveGateways(pageNumber, perPage);
    Allocation[] memory allocs = new Allocation[](gateways.length);
    for (uint256 i = 0; i < gateways.length; i++) {
      IGatewayStrategy strategy = IGatewayStrategy(gatewayRegistry.getUsedStrategy(gateways[i]));
      if (address(strategy) != address(0)) {
        uint256 cus = strategy.computationUnitsPerEpoch(gateways[i], workerId);
        address operator = gatewayRegistry.getGateway(gateways[i]).operator;
        allocs[i] = Allocation(gateways[i], cus, operator);
      }
    }
    return allocs;
  }

  function getGatewayCount() external view returns (uint256) {
    return gatewayRegistry.getActiveGatewaysCount();
  }
}

pragma solidity 0.8.20;

interface IGatewayRegistry {
  struct Stake {
    uint256 amount;
    uint128 lockStart;
    uint128 lockEnd;
    uint128 duration;
    bool autoExtension;
    uint256 oldCUs;
  }

  struct Gateway {
    address operator;
    address ownAddress;
    bytes peerId;
    string metadata;
  }

  event Registered(address indexed gatewayOperator, bytes32 indexed id, bytes peerId);
  event Staked(
    address indexed gatewayOperator, uint256 amount, uint128 lockStart, uint128 lockEnd, uint256 computationUnits
  );
  event Unstaked(address indexed gatewayOperator, uint256 amount);
  event Unregistered(address indexed gatewayOperator, bytes peerId);

  event AllocatedCUs(address indexed gateway, bytes peerId, uint256[] workerIds, uint256[] shares);

  event StrategyAllowed(address indexed strategy, bool isAllowed);
  event DefaultStrategyChanged(address indexed strategy);
  event ManaChanged(uint256 newCuPerSQD);
  event MaxGatewaysPerClusterChanged(uint256 newAmount);
  event MinStakeChanged(uint256 newAmount);

  event MetadataChanged(address indexed gatewayOperator, bytes peerId, string metadata);
  event GatewayAddressChanged(address indexed gatewayOperator, bytes peerId, address newAddress);
  event UsedStrategyChanged(address indexed gatewayOperator, address strategy);
  event AutoextensionEnabled(address indexed gatewayOperator);
  event AutoextensionDisabled(address indexed gatewayOperator, uint128 lockEnd);

  event AverageBlockTimeChanged(uint256 newBlockTime);

  function computationUnitsAvailable(bytes calldata gateway) external view returns (uint256);
  function getUsedStrategy(bytes calldata peerId) external view returns (address);
  function getActiveGateways(uint256 pageNumber, uint256 perPage) external view returns (bytes[] memory);
  function getGateway(bytes calldata peerId) external view returns (Gateway memory);
  function getActiveGatewaysCount() external view returns (uint256);
}

pragma solidity 0.8.20;

interface IGatewayStrategy {
  function computationUnitsPerEpoch(bytes calldata gatewayId, uint256 workerId) external view returns (uint256);
}