// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IWorkerRegistration.sol";
import "./interfaces/INetworkController.sol";

contract RewardCalculation {
  uint256 internal constant year = 365 days;

  IWorkerRegistration public immutable workerRegistration;
  INetworkController public immutable networkController;

  constructor(IWorkerRegistration _workerRegistration, INetworkController _networkController) {
    workerRegistration = _workerRegistration;
    networkController = _networkController;
  }

  function apy(uint256 target, uint256 actual) public pure returns (uint256) {
    int256 def = (int256(target) - int256(actual)) * 10000 / int256(target);
    if (def >= 9000) {
      return 7000;
    }
    if (def >= 0) {
      return 2500 + uint256(def) / 2;
    }
    int256 resultApy = 2000 + def / 20;
    if (resultApy < 0) {
      return 0;
    }
    return uint256(resultApy);
  }

  function currentApy(uint256 targetGb) public view returns (uint256) {
    return apy(targetGb, workerRegistration.getActiveWorkerCount() * networkController.storagePerWorkerInGb());
  }

  function epochReward(uint256 targetGb, uint256 epochLengthInSeconds) public view returns (uint256) {
    return currentApy(targetGb) * workerRegistration.effectiveTVL() * epochLengthInSeconds / year / 10000;
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

interface IWorkerRegistration {
  function getActiveWorkerCount() external view returns (uint256);
  function effectiveTVL() external view returns (uint256);
  function getOwnedWorkers(address who) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface INetworkController {
  event EpochLengthUpdated(uint128 epochLength);
  event BondAmountUpdated(uint256 bondAmount);
  event StoragePerWorkerInGbUpdated(uint128 storagePerWorkerInGb);

  function epochLength() external view returns (uint128);

  function bondAmount() external view returns (uint256);

  function nextEpoch() external view returns (uint128);

  function epochNumber() external view returns (uint128);

  function storagePerWorkerInGb() external view returns (uint128);
}