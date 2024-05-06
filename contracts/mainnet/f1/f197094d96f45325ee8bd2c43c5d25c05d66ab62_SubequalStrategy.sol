/**
                                             .::.
                                          .=***#*+:
                                        .=*********+.
                                      .=++++*********=.
                                    .=++=++++++++******-
                                  .=++=++++++++++++******-
                                .=++==+++++++++++==+******+:
                              .=+===+++++++++++++===+*******=
                            .=+===+++++++++++++++===-=*******=
                           .=====++++++++++++++++====-=*****#*.
                           :-===++++++++++++++++++====--+*###=
                          :==+++++++++++++++++++++====---=+*-
                        :=++***************++++++++====--:-
                      .-+*########*************++++++===-:
                     .=##%%##################*****++++===-.
                     =#%%%%%%###########%%#######***+++==--
                     +%@@#****************##%%%#####**++==-.
                     -%#==*##**********##*****#%%%####**+==:
                      *-=*%+##*******##%@@#******#%%###**+=-
                      :=+%%#@%******#%=*@@%*********#%##*++-
                      :=*%@@@**####*#@@@@@%********++*###*+.
                      =+**##*#######*#@@@%#####****++++**+-
                +*-  .+**#**#########*****######****+++=+-
               -#**+:-**++**########***###%%%%##**+++++=.
             ::-**+-=*#*=+**#######***#*###%%%##**++++*+=         :=-
            -###****##%==+**######*******#######**+===*#*+-::::-=*##*
            .#%#******==+***##%%%#********######**++==+%%%##**#####%*
              +#%##******###%%%####****+++*#%%%##*********#%%%%%%%%*.
               :%%%%%%%#%%%%###=.+##**********##########%%##%%%###=
                 #%#%%%%%##**=.  :########%%#:-**#%%%%%##*+++*+-:
                  ::+#**#+=-.     =#%%%%#%%#*.  :=*****=:
                                   :+##*##+=       ..
                                     :-.::

*/
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "../interfaces/IGatewayStrategy.sol";
import "../interfaces/IGatewayRegistry.sol";
import "../interfaces/IRouter.sol";

contract SubequalStrategy is IGatewayStrategy {
  IRouter public router;
  IGatewayRegistry public gatewayRegistry;

  mapping(address gatewayOperator => mapping(uint256 workerId => bool)) public isWorkerSupported;
  mapping(address gatewayOperator => uint256) public workerCount;

  event WorkerSupported(address gatewayOperator, uint256 workerId);
  event WorkerUnsupported(address gatewayOperator, uint256 workerId);

  constructor(IRouter _router, IGatewayRegistry _gatewayRegistry) {
    router = _router;
    gatewayRegistry = _gatewayRegistry;
  }

  function supportWorkers(uint256[] calldata workerIds) external {
    for (uint256 i = 0; i < workerIds.length; i++) {
      isWorkerSupported[msg.sender][workerIds[i]] = true;
      emit WorkerSupported(msg.sender, workerIds[i]);
    }
    workerCount[msg.sender] += workerIds.length;
  }

  function unsupportWorkers(uint256[] calldata workerIds) external {
    for (uint256 i = 0; i < workerIds.length; i++) {
      isWorkerSupported[msg.sender][workerIds[i]] = false;
      emit WorkerUnsupported(msg.sender, workerIds[i]);
    }
    workerCount[msg.sender] -= workerIds.length;
  }

  function computationUnitsPerEpoch(bytes calldata gatewayId, uint256 workerId) external view returns (uint256) {
    address operator = gatewayRegistry.getGateway(gatewayId).operator;
    if (!isWorkerSupported[operator][workerId]) {
      return 0;
    }
    return gatewayRegistry.computationUnitsAvailable(gatewayId) / workerCount[operator];
  }
}

pragma solidity 0.8.20;

interface IGatewayStrategy {
  function computationUnitsPerEpoch(bytes calldata gatewayId, uint256 workerId) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "./IWorkerRegistration.sol";
import "./IStaking.sol";
import "./INetworkController.sol";
import "./IRewardCalculation.sol";

interface IRouter {
  function workerRegistration() external view returns (IWorkerRegistration);
  function staking() external view returns (IStaking);
  function rewardTreasury() external view returns (address);
  function networkController() external view returns (INetworkController);
  function rewardCalculation() external view returns (IRewardCalculation);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IWorkerRegistration {
  /// @dev Emitted when a worker is registered
  event WorkerRegistered(
    uint256 indexed workerId, bytes peerId, address indexed registrar, uint256 registeredAt, string metadata
  );

  /// @dev Emitted when a worker is deregistered
  event WorkerDeregistered(uint256 indexed workerId, address indexed account, uint256 deregistedAt);

  /// @dev Emitted when the bond is withdrawn
  event WorkerWithdrawn(uint256 indexed workerId, address indexed account);

  /// @dev Emitted when a excessive bond is withdrawn
  event ExcessiveBondReturned(uint256 indexed workerId, uint256 amount);

  /// @dev Emitted when metadata is updated
  event MetadataUpdated(uint256 indexed workerId, string metadata);

  function register(bytes calldata peerId, string calldata metadata) external;

  /// @return The number of active workers.
  function getActiveWorkerCount() external view returns (uint256);
  function getActiveWorkerIds() external view returns (uint256[] memory);

  /// @return The ids of all worker created by the owner account
  function getOwnedWorkers(address who) external view returns (uint256[] memory);

  function nextWorkerId() external view returns (uint256);

  function isWorkerActive(uint256 workerId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IStaking {
  struct StakerRewards {
    /// @dev the sum of (amount_i / totalStaked_i) for each distribution of amount_i when totalStaked_i was staked
    uint256 cumulatedRewardsPerShare;
    /// @dev the value of cumulatedRewardsPerShare when the user's last action was performed (deposit or withdraw)
    mapping(address staker => uint256) checkpoint;
    /// @dev the amount of tokens staked by the user
    mapping(address staker => uint256) depositAmount;
    /// @dev block from which withdraw is allowed for staker
    mapping(address staker => uint128) withdrawAllowed;
    /// @dev the total amount of tokens staked
    uint256 totalStaked;
  }

  /// @dev Emitted when rewards where distributed by the distributor
  event Distributed(uint256 epoch);
  /// @dev Emitted when a staker delegates amount to the worker
  event Deposited(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker undelegates amount to the worker
  event Withdrawn(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when new claimable reward arrives
  event Rewarded(uint256 indexed workerId, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker claims rewards
  event Claimed(address indexed staker, uint256 amount, uint256[] workerIds);
  /// @dev Emitted when max delegations is changed
  event EpochsLockChanged(uint128 epochsLock);

  event MaxDelegationsChanged(uint256 maxDelegations);

  /// @dev Deposit amount of tokens in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to deposit
  function deposit(uint256 worker, uint256 amount) external;

  /// @dev Withdraw amount of tokens staked in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to withdraw
  function withdraw(uint256 worker, uint256 amount) external;

  /// @dev Claim rewards for a staker
  /// @return amount of tokens claimed
  function claim(address staker) external returns (uint256);

  /// @return claimable amount
  /// MUST return same value as claim(address staker) but without modifying state
  function claimable(address staker) external view returns (uint256);

  /// @dev total staked amount for the worker
  function delegated(uint256 worker) external view returns (uint256);

  /// @dev Distribute tokens to stakers in favour of a worker
  /// @param workers array of workerIds in WorkerRegistration contract
  /// @param amounts array of amounts of tokens to distribute for i-th worker
  function distribute(uint256[] calldata workers, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface INetworkController {
  /// @dev Emitted when epoch length is updated
  event EpochLengthUpdated(uint128 epochLength);
  /// @dev Emitted when bond amount is updated
  event BondAmountUpdated(uint256 bondAmount);
  /// @dev Emitted when storage per worker is updated
  event StoragePerWorkerInGbUpdated(uint128 storagePerWorkerInGb);
  event StakingDeadlockUpdated(uint256 stakingDeadlock);
  event AllowedVestedTargetUpdated(address target, bool isAllowed);
  event TargetCapacityUpdated(uint256 target);
  event RewardCoefficientUpdated(uint256 coefficient);

  /// @dev Amount of blocks in one epoch
  function epochLength() external view returns (uint128);

  /// @dev Amount of tokens required to register a worker
  function bondAmount() external view returns (uint256);

  /// @dev Block when next epoch starts
  function nextEpoch() external view returns (uint128);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function epochNumber() external view returns (uint128);

  /// @dev Number of unrewarded epochs after which staking will be blocked
  function stakingDeadlock() external view returns (uint256);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function targetCapacityGb() external view returns (uint256);

  /// @dev Amount of storage in GB each worker is expected to provide
  function storagePerWorkerInGb() external view returns (uint128);

  /// @dev Can the `target` be used as a called by the vesting contract
  function isAllowedVestedTarget(address target) external view returns (bool);

  /// @dev Max part of initial reward pool that can be allocated during a year, in basis points
  /// example: 3000 will mean that on each epoch, max 30% of the initial pool * epoch length / 1 year can be allocated
  function yearlyRewardCapCoefficient() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IRewardCalculation {
  function currentApy() external view returns (uint256);

  function boostFactor(uint256 duration) external pure returns (uint256);
}