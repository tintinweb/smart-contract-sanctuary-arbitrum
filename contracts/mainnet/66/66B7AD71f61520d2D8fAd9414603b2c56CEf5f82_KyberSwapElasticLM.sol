// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {KSMath} from '../libraries/KSMath.sol';
import {IKyberSwapElasticLM} from '../interfaces/liquidityMining/IKyberSwapElasticLM.sol';
import {IKSElasticLMHelper} from '../interfaces/liquidityMining/IKSElasticLMHelper.sol';
import {IBasePositionManager} from '../interfaces/liquidityMining/IBasePositionManager.sol';
import {IPoolStorage} from '../interfaces/liquidityMining/IPoolStorage.sol';
import {KSAdmin} from './base/KSAdmin.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract KyberSwapElasticLM is IKyberSwapElasticLM, ReentrancyGuard, KSAdmin {
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeERC20 for IERC20Metadata;
  using KSMath for uint256;

  IERC721 public immutable nft;
  IKSElasticLMHelper private helper;
  address public immutable weth;

  uint256 internal constant PRECISION = 1e12;

  uint256 public poolLength;

  // pId => Pool info
  mapping(uint256 => LMPoolInfo) public pools;

  // nftId => Position info
  mapping(uint256 => PositionInfo) public positions;

  // nftId => pId => Stake info
  mapping(uint256 => mapping(uint256 => StakeInfo)) public stakes;

  // nftId => list of joined pools
  mapping(uint256 => EnumerableSet.UintSet) internal joinedPools;

  // user address => set of nft id which user already deposit into LM contract
  mapping(address => EnumerableSet.UintSet) private depositNFTs;

  mapping(uint256 => bool) public isEmergencyWithdrawnNFT;

  bool public emergencyEnabled;

  modifier checkLength(uint256 a, uint256 b) {
    require(a == b, 'invalid length');
    _;
  }

  constructor(IERC721 _nft) {
    nft = _nft;
    weth = IBasePositionManager(address(_nft)).WETH();
  }

  /**
   * EXTERNAL FUNCTIONS *************************
   */

  /**
   * @dev receive native reward token
   */
  receive() external payable {}

  /**
   * @dev Set emergencyEnabled flag to true
   */
  function emergencyEnable() public isAdmin {
    require(!emergencyEnabled, 'Invalid value');
    emergencyEnabled = true;
    emit EmergencyEnabled();
  }

  function updateHelper(IKSElasticLMHelper _helper) external isAdmin {
    helper = _helper;

    emit LMHelperUpdated(_helper);
  }

  /**
   * @dev Add a new LM pool
   * @param poolAddress Pool address
   * @param startTime Start time of the pool
   * @param endTime End time of the pool
   * @param rewardTokens List of ERC20 reward tokens
   * @param rewardAmounts List of total reward amount for each token
   * @param feeTarget Fee target of the pool
   */
  function addPool(
    address poolAddress,
    uint32 startTime,
    uint32 endTime,
    address[] calldata rewardTokens,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external override isOperator checkLength(rewardTokens.length, rewardAmounts.length) {
    require(startTime >= _getBlockTime() && endTime > startTime, 'addPool: invalid times');
    uint256 pId = poolLength; // save gas
    LMPoolInfo storage pool = pools[pId];

    pool.poolAddress = poolAddress;
    pool.startTime = startTime;
    pool.endTime = endTime;
    pool.totalSecondsClaimed = 0;
    pool.feeTarget = feeTarget;

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      pool.rewards.push(RewardData(rewardTokens[i], rewardAmounts[i]));
    }
    poolLength++;
    emit AddPool(pId, poolAddress, startTime, endTime, feeTarget);
  }

  /**
   * @dev Renew a pool to start another LM program
   * @param pId Pool id to be renewed
   * @param startTime Start time of the pool
   * @param endTime End time of the pool
   * @param rewardAmounts List of total reward amount for each token
   * @param feeTarget Fee target of the pool
   */
  function renewPool(
    uint256 pId,
    uint32 startTime,
    uint32 endTime,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external override isOperator {
    LMPoolInfo storage pool = pools[pId];

    // check if pool has not started or already ended
    require(
      pool.startTime > _getBlockTime() || pool.endTime < _getBlockTime(),
      'renew: invalid pool state'
    );
    require(pool.rewards.length == rewardAmounts.length, 'renew: invalid length');
    // check input startTime and endTime
    require(startTime > _getBlockTime() && endTime > startTime, 'renew: invalid times');
    // check pool has stakes
    require(pool.numStakes == 0, 'renew: pool has stakes');

    pool.startTime = startTime;
    pool.endTime = endTime;
    pool.totalSecondsClaimed = 0;
    pool.feeTarget = feeTarget;

    for (uint256 i = 0; i < rewardAmounts.length; ++i) {
      pool.rewards[i].rewardUnclaimed = rewardAmounts[i];
    }
    emit RenewPool(pId, startTime, endTime, feeTarget);
  }

  /**
   * @dev Deposit NFTs into the pool
   * @param nftIds List of NFT ids from BasePositionManager
   *
   */
  function deposit(uint256[] calldata nftIds) external override nonReentrant {
    address sender = msg.sender;
    // save gas
    bool _emergencyEnabled = emergencyEnabled;
    // save gas

    for (uint256 i = 0; i < nftIds.length; i++) {
      require(!_emergencyEnabled || !isEmergencyWithdrawnNFT[nftIds[i]], 'Not allowed to deposit');
      positions[nftIds[i]].owner = sender;
      require(depositNFTs[sender].add(nftIds[i]), 'Fail to add depositNFTs');
      nft.transferFrom(sender, address(this), nftIds[i]);
      emit Deposit(sender, nftIds[i]);
    }
  }

  /**
   * @dev Withdraw NFTs, must exit all pools before call
   * @param nftIds List of NFT ids from BasePositionManager
   */
  function withdraw(uint256[] calldata nftIds) external override nonReentrant {
    address sender = msg.sender;
    for (uint256 i = 0; i < nftIds.length; ++i) {
      require(positions[nftIds[i]].owner == sender, 'withdraw: not owner');
      require(joinedPools[nftIds[i]].length() == 0, 'withdraw: not exited yet');
      delete positions[nftIds[i]];
      require(depositNFTs[sender].remove(nftIds[i]), 'Fail to remove depositNFTs');
      nft.transferFrom(address(this), sender, nftIds[i]);
      emit Withdraw(sender, nftIds[i]);
    }
  }

  /**
   * @dev Emergency withdraw NFT position, will not receive any reward
   * @param nftIds NFT id from BasePositionManager
   */
  function emergencyWithdraw(uint256[] calldata nftIds) external nonReentrant {
    address sender = msg.sender;
    // save gas
    bool _emergencyEnabled = emergencyEnabled;

    for (uint256 i = 0; i < nftIds.length; ++i) {
      require(positions[nftIds[i]].owner == sender, 'withdraw: not owner');

      isEmergencyWithdrawnNFT[nftIds[i]] = true;
      uint256[] memory values = joinedPools[nftIds[i]].values();
      for (uint256 j = 0; j < values.length; ++j) {
        uint256 poolId = values[j];
        unchecked {
          pools[poolId].numStakes--;
        }
        delete stakes[nftIds[i]][poolId];
      }
      delete positions[nftIds[i]];

      if (!_emergencyEnabled) {
        require(depositNFTs[sender].remove(nftIds[i]), 'Fail to remove depositNFTs');
        for (uint256 j = 0; j < values.length; ++j) {
          uint256 poolId = values[j];
          require(joinedPools[nftIds[i]].remove(poolId), 'Fail to remove joinedPools');
        }
      }

      nft.transferFrom(address(this), sender, nftIds[i]);
      emit EmergencyWithdraw(sender, nftIds[i]);
    }
  }

  /**
   * @dev Emergency withdraw funds from contract, only admin can call this function
   * @param rewards List of ERC20 tokens
   * @param amounts List of amounts to be withdrawn
   */
  function emergencyWithdrawForOwner(
    address[] calldata rewards,
    uint256[] calldata amounts
  ) external override isAdmin checkLength(rewards.length, amounts.length) {
    for (uint256 i = 0; i < rewards.length; ++i) {
      _transferReward(rewards[i], msg.sender, amounts[i]);
      emit EmergencyWithdrawForOwner(rewards[i], amounts[i]);
    }
  }

  /**
   * @dev Join pools
   * @param pId pool id to join
   * @param nftIds nfts to join
   * @param liqs list liquidity value to join each nft
   *
   */
  function join(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external nonReentrant checkLength(nftIds.length, liqs.length) {
    require(poolLength > pId, 'Pool not exists');
    LMPoolInfo storage pool = pools[pId];
    require(pool.startTime <= _getBlockTime() && _getBlockTime() < pool.endTime, 'Invalid time');
    for (uint256 i = 0; i < nftIds.length; ++i) {
      require(positions[nftIds[i]].owner == msg.sender, 'Not owner');
      positions[nftIds[i]].liquidity = helper.getLiq(address(nft), nftIds[i]);
      StakeInfo storage stake = stakes[nftIds[i]][pId];
      if (stake.liquidity == 0) {
        _join(nftIds[i], pId, liqs[i], pool);
      } else {
        _sync(nftIds[i], pId, liqs[i], pool);
      }
    }
  }

  /**
   * @dev Exit from pools
   * @param pId pool ids to exit
   * @param nftIds list nfts id
   * @param liqs list liquidity value to exit from each nft
   *
   */
  function exit(
    uint256 pId,
    uint256[] calldata nftIds,
    uint256[] calldata liqs
  ) external nonReentrant checkLength(nftIds.length, liqs.length) {
    require(poolLength > pId, 'Pool not exists');
    for (uint256 i = 0; i < nftIds.length; ++i) {
      _exit(nftIds[i], pId, liqs[i], true);
    }
  }

  /**
   * @dev Claim rewards for a list of pools for a list of nft positions
   * @param nftIds List of NFT ids to harvest
   * @param datas List of pool ids to harvest for each nftId, encoded into bytes
   */
  function harvestMultiplePools(
    uint256[] calldata nftIds,
    bytes[] calldata datas
  ) external nonReentrant checkLength(nftIds.length, datas.length) {
    for (uint256 i; i < nftIds.length; ++i) {
      require(positions[nftIds[i]].owner == msg.sender, 'harvest: not owner');
      HarvestData memory data = abi.decode(datas[i], (HarvestData));
      for (uint256 j; j < data.pIds.length; ++j) {
        _harvest(nftIds[i], data.pIds[j]);
      }
    }
  }

  /**
   * @dev remove liquidity from elastic for a list of nft position, also update on farm
   * @param nftId to remove
   * @param liquidity liquidity amount to remove from nft
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param deadline deadline of this tx
   * @param isReceiveNative should unwrap native or not
   * @param claimFeeAndRewards also claim LP Fee and farm rewards
   */
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative,
    bool[2] calldata claimFeeAndRewards
  ) external nonReentrant {
    require(!emergencyEnabled, 'removeLiquidity: not allowed');

    require(block.timestamp <= deadline, 'removeLiquidity: expired');
    require(positions[nftId].owner == msg.sender, 'removeLiquidity: not owner');

    uint256 posLiquidity = positions[nftId].liquidity;
    require(liquidity > 0 && liquidity <= posLiquidity, 'removeLiquidity: invalid liquidity');

    posLiquidity -= liquidity;
    positions[nftId].liquidity = posLiquidity;

    uint256[] memory poolIds = joinedPools[nftId].values();
    for (uint256 i; i < poolIds.length; ) {
      uint256 stakedLiquidity = stakes[nftId][poolIds[i]].liquidity;
      uint256 deltaLiq = stakedLiquidity > posLiquidity ? stakedLiquidity - posLiquidity : 0;

      if (deltaLiq > 0) _exit(nftId, poolIds[i], deltaLiq, claimFeeAndRewards[1]);

      unchecked {
        ++i;
      }
    }

    (address token0, address token1) = helper.getPair(address(nft), nftId);
    _removeLiquidity(nftId, liquidity, deadline);
    if (claimFeeAndRewards[0]) _claimFee(nftId, deadline, false);
    _transferTokens(token0, token1, amount0Min, amount1Min, msg.sender, isReceiveNative);
  }

  /**
   * @dev Claim fee from elastic for a list of nft positions
   * @param nftIds List of NFT ids to claim
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param poolAddress address of Elastic pool of those token
   * @param isReceiveNative should unwrap native or not
   * @param deadline deadline of this tx
   */
  function claimFee(
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    address poolAddress,
    bool isReceiveNative,
    uint256 deadline
  ) external nonReentrant {
    require(!emergencyEnabled, 'claimFee: not allowed');
    require(block.timestamp <= deadline, 'claimFee: expired');

    uint256 length = nftIds.length;
    (address token0, address token1) = (
      address(IPoolStorage(poolAddress).token0()),
      address(IPoolStorage(poolAddress).token1())
    );

    for (uint256 i; i < length; ) {
      require(positions[nftIds[i]].owner == msg.sender, 'claimFee: not owner');

      (address nftToken0, address nftToken1) = helper.getPair(address(nft), nftIds[i]);
      require(nftToken0 == token0 && nftToken1 == token1, 'claimFee: token pair not match');

      _claimFee(nftIds[i], deadline, true);

      unchecked {
        ++i;
      }
    }

    _transferTokens(token0, token1, amount0Min, amount1Min, msg.sender, isReceiveNative);
  }

  function getJoinedPools(uint256 nftId) external view returns (uint256[] memory poolIds) {
    uint256 length = joinedPools[nftId].length();
    poolIds = new uint256[](length);
    for (uint256 i = 0; i < length; ++i) {
      poolIds[i] = joinedPools[nftId].at(i);
    }
  }

  function getJoinedPoolsInRange(
    uint256 nftId,
    uint256 fromIndex,
    uint256 toIndex
  ) external view returns (uint256[] memory poolIds) {
    require(fromIndex <= toIndex, 'fromIndex > toIndex');
    require(toIndex < joinedPools[nftId].length(), 'toIndex >= length');
    poolIds = new uint256[](toIndex - fromIndex + 1);
    for (uint256 index = fromIndex; index <= toIndex; ++index) {
      poolIds[index - fromIndex] = joinedPools[nftId].at(index);
    }
  }

  function getUserInfo(
    uint256 nftId,
    uint256 pId
  )
    external
    view
    returns (uint256 liquidity, uint256[] memory rewardPending, uint256[] memory rewardLast)
  {
    LMPoolInfo storage pool = pools[pId];
    StakeInfo storage stake = stakes[nftId][pId];

    require(stake.liquidity > 0, 'getUserInfo: not joined yet');

    rewardPending = new uint256[](pool.rewards.length);
    rewardLast = new uint256[](pool.rewards.length);

    RewardCalculationData memory data = getRewardCalculationData(nftId, pId);
    for (uint256 i = 0; i < pool.rewards.length; ++i) {
      uint256 rewardHarvest = _calculateRewardHarvest(
        stake.liquidity,
        pool.rewards[i].rewardUnclaimed,
        data.totalSecondsUnclaimed,
        data.secondsPerLiquidity
      );
      uint256 rewardCollected = _calculateRewardCollected(
        stake.rewardHarvested[i] + rewardHarvest,
        data.vestingVolume,
        stake.rewardLast[i]
      );
      rewardPending[i] = stake.rewardPending[i] + rewardCollected;
      rewardLast[i] = stake.rewardLast[i];
    }
    liquidity = stake.liquidity;
  }

  function getPoolInfo(
    uint256 pId
  )
    external
    view
    returns (
      address poolAddress,
      uint32 startTime,
      uint32 endTime,
      uint256 totalSecondsClaimed,
      uint256 feeTarget,
      uint256 numStakes,
      //index reward => reward data
      address[] memory rewardTokens,
      uint256[] memory rewardUnclaimeds
    )
  {
    LMPoolInfo storage pool = pools[pId];

    poolAddress = pool.poolAddress;
    startTime = pool.startTime;
    endTime = pool.endTime;
    totalSecondsClaimed = pool.totalSecondsClaimed;
    feeTarget = pool.feeTarget;
    numStakes = pool.numStakes;

    uint256 length = pool.rewards.length;
    rewardTokens = new address[](length);
    rewardUnclaimeds = new uint256[](length);
    for (uint256 i = 0; i < length; ++i) {
      rewardTokens[i] = pool.rewards[i].rewardToken;
      rewardUnclaimeds[i] = pool.rewards[i].rewardUnclaimed;
    }
  }

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs) {
    listNFTs = depositNFTs[user].values();
  }

  /**
   * INTERNAL FUNCTIONS *************************
   */
  /**
   * @dev join pool first time
   * @param nftId NFT id to join
   * @param pId pool id to join
   * @param liq liquidity amount to join
   * @param pool LM pool
   */
  function _join(uint256 nftId, uint256 pId, uint256 liq, LMPoolInfo storage pool) internal {
    PositionInfo storage position = positions[nftId];
    StakeInfo storage stake = stakes[nftId][pId];
    require(helper.checkPool(pool.poolAddress, address(nft), nftId), 'join: invalid pool');
    require(liq != 0 && liq <= position.liquidity, 'join: invalid liq');

    stake.secondsPerLiquidityLast = helper.getActiveTime(pool.poolAddress, address(nft), nftId);
    stake.rewardLast = new uint256[](pool.rewards.length);
    stake.rewardPending = new uint256[](pool.rewards.length);
    stake.rewardHarvested = new uint256[](pool.rewards.length);
    if (pool.feeTarget != 0) {
      stake.feeFirst = helper.getSignedFee(address(nft), nftId);
    }
    stake.liquidity = liq;
    pool.numStakes++;

    require(joinedPools[nftId].add(pId), 'Fail to add joinedPools');

    emit Join(nftId, pId, liq);
  }

  /**
   * @dev Increase liquidity in pool
   * @param nftId NFT id to sync
   * @param pId pool id to sync
   * @param liq liquidity amount to increase
   * @param pool LM pool
   */
  function _sync(uint256 nftId, uint256 pId, uint256 liq, LMPoolInfo storage pool) internal {
    PositionInfo storage position = positions[nftId];
    StakeInfo storage stake = stakes[nftId][pId];

    require(liq != 0 && liq + stake.liquidity <= position.liquidity, 'sync: invalid liq');

    RewardCalculationData memory data = getRewardCalculationData(nftId, pId);

    for (uint256 i = 0; i < pool.rewards.length; ++i) {
      uint256 rewardHarvest = _calculateRewardHarvest(
        stake.liquidity,
        pool.rewards[i].rewardUnclaimed,
        data.totalSecondsUnclaimed,
        data.secondsPerLiquidity
      );

      if (rewardHarvest != 0) {
        stake.rewardHarvested[i] += rewardHarvest;
        pool.rewards[i].rewardUnclaimed -= rewardHarvest;
      }

      uint256 rewardCollected = _calculateRewardCollected(
        stake.rewardHarvested[i],
        data.vestingVolume,
        stake.rewardLast[i]
      );

      if (rewardCollected != 0) {
        stake.rewardLast[i] += rewardCollected;
        stake.rewardPending[i] += rewardCollected;
      }
    }

    pool.totalSecondsClaimed += data.secondsClaim;
    stake.secondsPerLiquidityLast = data.secondsPerLiquidityNow;
    stake.feeFirst = _calculateFeeFirstAfterJoin(
      stake.feeFirst,
      data.feeNow,
      pool.feeTarget,
      stake.liquidity,
      liq,
      nftId
    );
    stake.liquidity += liq;
    emit SyncLiq(nftId, pId, liq);
  }

  /**
   * @dev Exit pool
   * @param nftId NFT id to exit
   * @param pId pool id to exit
   * @param liq liquidity amount to exit
   * @param claimReward transfer reward or not
   */
  function _exit(uint256 nftId, uint256 pId, uint256 liq, bool claimReward) internal {
    LMPoolInfo storage pool = pools[pId];
    address pOwner = positions[nftId].owner;
    StakeInfo storage stake = stakes[nftId][pId];

    require(
      pOwner == msg.sender || (_getBlockTime() > pool.endTime && operators[msg.sender]),
      'exit: not owner or pool not ended'
    );

    uint256 liquidityOld = stake.liquidity;
    require(liq != 0 && liq <= liquidityOld, 'exit: invalid liq');

    uint256 liquidityNew = liquidityOld - liq;
    RewardCalculationData memory data = getRewardCalculationData(nftId, pId);

    pool.totalSecondsClaimed += data.secondsClaim;
    stake.secondsPerLiquidityLast = data.secondsPerLiquidityNow;
    stake.liquidity = liquidityNew;
    for (uint256 i = 0; i < pool.rewards.length; ++i) {
      uint256 rewardHarvest = _calculateRewardHarvest(
        liquidityOld,
        pool.rewards[i].rewardUnclaimed,
        data.totalSecondsUnclaimed,
        data.secondsPerLiquidity
      );

      if (rewardHarvest != 0) {
        stake.rewardHarvested[i] += rewardHarvest;
        pool.rewards[i].rewardUnclaimed -= rewardHarvest;
      }

      uint256 rewardCollected = _calculateRewardCollected(
        stake.rewardHarvested[i],
        data.vestingVolume,
        stake.rewardLast[i]
      );

      uint256 rewardPending = stake.rewardPending[i];
      if (rewardCollected != 0) {
        stake.rewardLast[i] += rewardCollected;
        rewardPending += rewardCollected;
      }

      if (rewardPending != 0) {
        if (claimReward) {
          stake.rewardPending[i] = 0;
          _transferReward(pool.rewards[i].rewardToken, pOwner, rewardPending);
          emit Harvest(nftId, pOwner, pool.rewards[i].rewardToken, rewardPending);
        } else {
          stake.rewardPending[i] = rewardPending;
        }
      }
    }
    if (liquidityNew == 0) {
      delete stakes[nftId][pId];
      pool.numStakes--;

      require(joinedPools[nftId].remove(pId), 'Fail to remove joinedPools');
    }
    emit Exit(msg.sender, nftId, pId, liq);
  }

  /**
   * @dev Harvest reward
   * @param nftId NFT id to harvest
   * @param pId pool id to harvest
   */
  function _harvest(uint256 nftId, uint256 pId) internal {
    require(poolLength > pId, 'Pool not exists');
    LMPoolInfo storage pool = pools[pId];
    address pOwner = positions[nftId].owner;
    StakeInfo storage stake = stakes[nftId][pId];

    require(stake.liquidity > 0, 'harvest: not joined yet');

    RewardCalculationData memory data = getRewardCalculationData(nftId, pId);

    pool.totalSecondsClaimed += data.secondsClaim;
    stake.secondsPerLiquidityLast = data.secondsPerLiquidityNow;
    for (uint256 i = 0; i < pool.rewards.length; ++i) {
      uint256 rewardHarvest = _calculateRewardHarvest(
        stake.liquidity,
        pool.rewards[i].rewardUnclaimed,
        data.totalSecondsUnclaimed,
        data.secondsPerLiquidity
      );

      if (rewardHarvest != 0) {
        stake.rewardHarvested[i] += rewardHarvest;
        pool.rewards[i].rewardUnclaimed -= rewardHarvest;
      }

      uint256 rewardCollected = _calculateRewardCollected(
        stake.rewardHarvested[i],
        data.vestingVolume,
        stake.rewardLast[i]
      );

      uint256 rewardPending = stake.rewardPending[i] + rewardCollected;
      if (rewardPending != 0) {
        if (rewardCollected != 0) {
          stake.rewardLast[i] += rewardCollected;
        }
        stake.rewardPending[i] = 0;
        _transferReward(pool.rewards[i].rewardToken, pOwner, rewardPending);
        emit Harvest(nftId, pOwner, pool.rewards[i].rewardToken, rewardPending);
      }
    }
  }

  /**
   * @dev transfer reward
   */
  function _transferReward(address _token, address _account, uint256 _amount) internal {
    if (_token == address(0)) {
      (bool success, ) = payable(_account).call{value: _amount}('');
      require(success, 'transfer reward token failed');
    } else {
      IERC20Metadata(_token).safeTransfer(_account, _amount);
    }
  }

  /// @dev remove liquidiy of nft from posManager
  /// @param nftId nft's id
  /// @param liquidity liquidity amount to remove
  /// @param deadline removeLiquidity deadline
  function _removeLiquidity(uint256 nftId, uint128 liquidity, uint256 deadline) internal {
    IBasePositionManager.RemoveLiquidityParams memory removeLiq = IBasePositionManager
      .RemoveLiquidityParams({
        tokenId: nftId,
        liquidity: liquidity,
        amount0Min: 0,
        amount1Min: 0,
        deadline: deadline
      });

    IBasePositionManager(address(nft)).removeLiquidity(removeLiq);
  }

  /// @dev claim fee of nft from posManager
  /// @param nftId nft's id
  /// @param deadline claimFee deadline
  /// @param syncFee is need to sync new fee or not
  function _claimFee(uint256 nftId, uint256 deadline, bool syncFee) internal {
    if (syncFee) {
      IBasePositionManager(address(nft)).syncFeeGrowth(nftId);
    }

    IBasePositionManager.BurnRTokenParams memory burnRToken = IBasePositionManager
      .BurnRTokenParams({tokenId: nftId, amount0Min: 0, amount1Min: 0, deadline: deadline});

    IBasePositionManager(address(nft)).burnRTokens(burnRToken);
  }

  /// @dev transfer tokens from removeLiquidity (and burnRToken if any) to receiver
  /// @param token0 address of token0
  /// @param token1 address of token1
  /// @param amount0Min minimum amount of token0 should receive
  /// @param amount1Min minimum amount of token1 should receive
  /// @param receiver receiver of tokens
  /// @param isReceiveNative should unwrap wrapped native or not
  function _transferTokens(
    address token0,
    address token1,
    uint256 amount0Min,
    uint256 amount1Min,
    address receiver,
    bool isReceiveNative
  ) internal {
    IBasePositionManager posManager = IBasePositionManager(address(nft));

    if (isReceiveNative) {
      // expect to receive in native token
      if (weth == token0) {
        // receive in native for token0
        posManager.unwrapWeth(amount0Min, receiver);
        posManager.transferAllTokens(token1, amount1Min, receiver);
        return;
      }
      if (weth == token1) {
        // receive in native for token1
        posManager.transferAllTokens(token0, amount0Min, receiver);
        posManager.unwrapWeth(amount1Min, receiver);
        return;
      }
    }

    posManager.transferAllTokens(token0, amount0Min, receiver);
    posManager.transferAllTokens(token1, amount1Min, receiver);
  }

  /**
   * HELPER MATH FUNCTIONS *************************
   */
  function getRewardCalculationData(
    uint256 nftId,
    uint256 pId
  ) public view returns (RewardCalculationData memory data) {
    LMPoolInfo storage pool = pools[pId];
    StakeInfo storage stake = stakes[nftId][pId];

    data.secondsPerLiquidityNow = helper.getActiveTime(pool.poolAddress, address(nft), nftId);
    data.feeNow = helper.getSignedFeePool(pool.poolAddress, address(nft), nftId);
    data.vestingVolume = _calculateVestingVolume(data.feeNow, stake.feeFirst, pool.feeTarget);
    data.totalSecondsUnclaimed = _calculateSecondsUnclaimed(
      pool.startTime,
      pool.endTime,
      pool.totalSecondsClaimed
    );
    unchecked {
      data.secondsPerLiquidity = data.secondsPerLiquidityNow - stake.secondsPerLiquidityLast;
    }
    data.secondsClaim = stake.liquidity * data.secondsPerLiquidity;
  }

  /**
   * @dev feeFirst = (liq * max(feeNow - feeTarget, feeFirst) + liqAdd * feeNow) / liqNew
   */
  function _calculateFeeFirstAfterJoin(
    int256 feeFirst,
    int256 feeNow,
    uint256 feeTarget,
    uint256 liquidity,
    uint256 liquidityAdd,
    uint256 nftId
  ) internal view returns (int256) {
    if (feeTarget == 0) {
      return 0;
    }
    int256 feeFirstCurrent = feeNow - int256(feeTarget) < feeFirst
      ? feeFirst
      : feeNow - int256(feeTarget);
    int256 numerator = int256(liquidity) *
      feeFirstCurrent +
      int256(liquidityAdd) *
      helper.getSignedFee(address(nft), nftId);
    int256 denominator = int256(liquidity + liquidityAdd);
    return numerator / denominator;
  }

  /**
   * @dev vesting = min((feeNow - feeFirst) / feeTarget, 1)
   */
  function _calculateVestingVolume(
    int256 feeNow,
    int256 feeFirst,
    uint256 feeTarget
  ) internal pure returns (uint256) {
    if (feeTarget == 0) {
      return PRECISION;
    }
    uint256 feeInside = uint256(feeNow - feeFirst);
    return KSMath.min((feeInside * PRECISION) / feeTarget, PRECISION);
  }

  /**
   * @dev secondsUnclaimed = (max(currentTime, endTime) - startTime) - secondsClaimed
   */
  function _calculateSecondsUnclaimed(
    uint256 startTime,
    uint256 endTime,
    uint256 totalSecondsClaimed
  ) internal view returns (uint256) {
    uint256 totalSeconds = KSMath.max(_getBlockTime(), endTime) - startTime;
    uint256 totalSecondsScaled = totalSeconds * (1 << 96);
    return totalSecondsScaled > totalSecondsClaimed ? totalSecondsScaled - totalSecondsClaimed : 0;
  }

  /**
   * @dev rewardHarvested = L * rewardRate * secondsPerLiquidity
   */
  function _calculateRewardHarvest(
    uint256 liquidity,
    uint256 rewardUnclaimed,
    uint256 totalSecondsUnclaimed,
    uint256 secondsPerLiquidity
  ) internal pure returns (uint256) {
    return (liquidity * rewardUnclaimed * secondsPerLiquidity) / totalSecondsUnclaimed;
  }

  /**
   * @dev rewardCollected = Max(rewardHarvested * vestingVolume - rewardLast, 0);
   */
  function _calculateRewardCollected(
    uint256 rewardHarvested,
    uint256 vestingVolume,
    uint256 rewardLast
  ) internal pure returns (uint256) {
    uint256 rewardNow = (rewardHarvested * vestingVolume) / PRECISION;
    return rewardNow > rewardLast ? rewardNow - rewardLast : 0;
  }

  function _getBlockTime() internal view virtual returns (uint32) {
    return uint32(block.timestamp);
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library KSMath {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? b : a;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IKyberSwapElasticLMEvents} from './IKyberSwapElasticLMEvents.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IKyberSwapElasticLM is IKyberSwapElasticLMEvents {
  struct RewardData {
    address rewardToken;
    uint256 rewardUnclaimed;
  }

  struct LMPoolInfo {
    address poolAddress;
    uint32 startTime;
    uint32 endTime;
    uint256 totalSecondsClaimed; // scaled by (1 << 96)
    RewardData[] rewards;
    uint256 feeTarget;
    uint256 numStakes;
  }

  struct PositionInfo {
    address owner;
    uint256 liquidity;
  }

  struct StakeInfo {
    uint128 secondsPerLiquidityLast;
    uint256[] rewardLast;
    uint256[] rewardPending;
    uint256[] rewardHarvested;
    int256 feeFirst;
    uint256 liquidity;
  }

  // input data in harvestMultiplePools function
  struct HarvestData {
    uint256[] pIds;
  }

  // avoid stack too deep error
  struct RewardCalculationData {
    uint128 secondsPerLiquidityNow;
    int256 feeNow;
    uint256 vestingVolume;
    uint256 totalSecondsUnclaimed;
    uint256 secondsPerLiquidity;
    uint256 secondsClaim; // scaled by (1 << 96)
  }

  /**
   * @dev Add new pool to LM
   * @param poolAddr pool address
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param rewardTokens reward token list for pool
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function addPool(
    address poolAddr,
    uint32 startTime,
    uint32 endTime,
    address[] calldata rewardTokens,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Renew a pool to start another LM program
   * @param pId pool id to update
   * @param startTime start time of liquidity mining
   * @param endTime end time of liquidity mining
   * @param rewardAmounts reward amount of list token
   * @param feeTarget fee target for pool
   *
   */
  function renewPool(
    uint256 pId,
    uint32 startTime,
    uint32 endTime,
    uint256[] calldata rewardAmounts,
    uint256 feeTarget
  ) external;

  /**
   * @dev Deposit NFT
   * @param nftIds list nft id
   *
   */
  function deposit(uint256[] calldata nftIds) external;

  /**
   * @dev Withdraw NFT, must exit all pool before call.
   * @param nftIds list nft id
   *
   */
  function withdraw(uint256[] calldata nftIds) external;

  /**
   * @dev Join pools
   * @param pId pool id to join
   * @param nftIds nfts to join
   * @param liqs list liquidity value to join each nft
   *
   */
  function join(uint256 pId, uint256[] calldata nftIds, uint256[] calldata liqs) external;

  /**
   * @dev Exit from pools
   * @param pId pool ids to exit
   * @param nftIds list nfts id
   * @param liqs list liquidity value to exit from each nft
   *
   */
  function exit(uint256 pId, uint256[] calldata nftIds, uint256[] calldata liqs) external;

  /**
   * @dev remove liquidity from elastic for a list of nft position, also update on farm
   * @param nftId to remove
   * @param liquidity liquidity amount to remove from nft
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param deadline deadline of this tx
   * @param isReceiveNative should unwrap native or not
   * @param claimFeeAndRewards also claim LP Fee and farm rewards
   */
  function removeLiquidity(
    uint256 nftId,
    uint128 liquidity,
    uint256 amount0Min,
    uint256 amount1Min,
    uint256 deadline,
    bool isReceiveNative,
    bool[2] calldata claimFeeAndRewards
  ) external;

  /**
   * @dev Claim fee from elastic for a list of nft positions
   * @param nftIds List of NFT ids to claim
   * @param amount0Min expected min amount of token0 should receive
   * @param amount1Min expected min amount of token1 should receive
   * @param poolAddress address of Elastic pool of those nfts
   * @param isReceiveNative should unwrap native or not
   * @param deadline deadline of this tx
   */
  function claimFee(
    uint256[] calldata nftIds,
    uint256 amount0Min,
    uint256 amount1Min,
    address poolAddress,
    bool isReceiveNative,
    uint256 deadline
  ) external;

  /**
   * @dev Operator only. Call to withdraw all reward from list pools.
   * @param rewards list reward address erc20 token
   * @param amounts amount to withdraw
   *
   */
  function emergencyWithdrawForOwner(
    address[] calldata rewards,
    uint256[] calldata amounts
  ) external;

  /**
   * @dev Withdraw NFT, can call any time, reward will be reset. Must enable this func by operator
   * @param pIds list pool to withdraw
   *
   */
  function emergencyWithdraw(uint256[] calldata pIds) external;

  function nft() external view returns (IERC721);

  function poolLength() external view returns (uint256);

  function getUserInfo(
    uint256 nftId,
    uint256 pId
  )
    external
    view
    returns (uint256 liquidity, uint256[] memory rewardPending, uint256[] memory rewardLast);

  function getPoolInfo(
    uint256 pId
  )
    external
    view
    returns (
      address poolAddress,
      uint32 startTime,
      uint32 endTime,
      uint256 totalSecondsClaimed,
      uint256 feeTarget,
      uint256 numStakes,
      //index reward => reward data
      address[] memory rewardTokens,
      uint256[] memory rewardUnclaimeds
    );

  function getDepositedNFTs(address user) external view returns (uint256[] memory listNFTs);

  function getRewardCalculationData(
    uint256 nftId,
    uint256 pId
  ) external view returns (RewardCalculationData memory data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKSElasticLMHelper {
  function checkPool(
    address pAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (bool);

  /// @dev use virtual to be overrided to mock data for fuzz tests
  function getActiveTime(
    address pAddr,
    address nftContract,
    uint256 nftId
  ) external view returns (uint128);

  function getSignedFee(address nftContract, uint256 nftId) external view returns (int256);

  function getSignedFeePool(
    address poolAddress,
    address nftContract,
    uint256 nftId
  ) external view returns (int256);

  function getLiq(address nftContract, uint256 nftId) external view returns (uint128);

  function getPair(address nftContract, uint256 nftId) external view returns (address, address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface IBasePositionManager {
  struct Position {
    // the nonce for permits
    uint96 nonce;
    // the address that is approved for spending this token
    address operator;
    // the ID of the pool with which this token is connected
    uint80 poolId;
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
    // the liquidity of the position
    uint128 liquidity;
    // the current rToken that the position owed
    uint256 rTokenOwed;
    // fee growth per unit of liquidity as of the last update to liquidity
    uint256 feeGrowthInsideLast;
  }

  struct PoolInfo {
    address token0;
    uint16 fee;
    address token1;
  }

  struct IncreaseLiquidityParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct RemoveLiquidityParams {
    uint256 tokenId;
    uint128 liquidity;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  struct BurnRTokenParams {
    uint256 tokenId;
    uint256 amount0Min;
    uint256 amount1Min;
    uint256 deadline;
  }

  function positions(
    uint256 tokenId
  ) external view returns (Position memory pos, PoolInfo memory info);

  function addressToPoolId(address pool) external view returns (uint80);

  function WETH() external view returns (address);

  function removeLiquidity(
    RemoveLiquidityParams calldata params
  ) external returns (uint256 amount0, uint256 amount1, uint256 additionalRTokenOwed);

  function syncFeeGrowth(uint256 tokenId) external returns (uint256 additionalRTokenOwed);

  function burnRTokens(
    BurnRTokenParams calldata params
  ) external returns (uint256 rTokenQty, uint256 amount0, uint256 amount1);

  function transferAllTokens(address token, uint256 minAmount, address recipient) external payable;

  function unwrapWeth(uint256 minAmount, address recipient) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IFactory} from './IFactory.sol';

interface IPoolStorage {
  struct PoolData {
    uint160 sqrtP;
    int24 nearestCurrentTick;
    int24 currentTick;
    bool locked;
    uint128 baseL;
    uint128 reinvestL;
    uint128 reinvestLLast;
    uint256 feeGrowthGlobal;
    uint128 secondsPerLiquidityGlobal;
    uint32 secondsPerLiquidityUpdateTime;
  }

  // data stored for each initialized individual tick
  struct TickData {
    // gross liquidity of all positions in tick
    uint128 liquidityGross;
    // liquidity quantity to be added | removed when tick is crossed up | down
    int128 liquidityNet;
    // fee growth per unit of liquidity on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 feeGrowthOutside;
    // seconds spent on the other side of this tick (relative to current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint128 secondsPerLiquidityOutside;
  }

  /// @notice The contract that deployed the pool, which must adhere to the IFactory interface
  /// @return The contract address
  function factory() external view returns (IFactory);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (IERC20);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (IERC20);

  /// @notice The fee to be charged for a swap in basis points
  /// @return The swap fee in basis points
  function swapFeeBps() external view returns (uint16);

  /// @notice The pool tick distance
  /// @dev Ticks can only be initialized and used at multiples of this value
  /// It remains an int24 to avoid casting even though it is >= 1.
  /// e.g: a tickDistance of 5 means ticks can be initialized every 5th tick, i.e., ..., -10, -5, 0, 5, 10, ...
  /// @return The tick distance
  function tickDistance() external view returns (int24);

  /// @notice Maximum gross liquidity that an initialized tick can have
  /// @dev This is to prevent overflow the pool's active base liquidity (uint128)
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxTickLiquidity() external view returns (uint128);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityGross total liquidity amount from positions that uses this tick as a lower or upper tick
  /// liquidityNet how much liquidity changes when the pool tick crosses above the tick
  /// feeGrowthOutside the fee growth on the other side of the tick relative to the current tick
  /// secondsPerLiquidityOutside the seconds spent on the other side of the tick relative to the current tick
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityGross,
      int128 liquidityNet,
      uint256 feeGrowthOutside,
      uint128 secondsPerLiquidityOutside
    );

  /// @notice Returns the previous and next initialized ticks of a specific tick
  /// @dev If specified tick is uninitialized, the returned values are zero.
  /// @param tick The tick to look up
  function initializedTicks(int24 tick) external view returns (int24 previous, int24 next);

  /// @notice Returns the information about a position by the position's key
  /// @return liquidity the liquidity quantity of the position
  /// @return feeGrowthInsideLast fee growth inside the tick range as of the last mint / burn action performed
  function getPositions(
    address owner,
    int24 tickLower,
    int24 tickUpper
  ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

  /// @notice Fetches the pool's prices, ticks and lock status
  /// @return sqrtP sqrt of current price: sqrt(token1/token0)
  /// @return currentTick pool's current tick
  /// @return nearestCurrentTick pool's nearest initialized tick that is <= currentTick
  /// @return locked true if pool is locked, false otherwise
  function getPoolState()
    external
    view
    returns (
      uint160 sqrtP,
      int24 currentTick,
      int24 nearestCurrentTick,
      bool locked
    );

  /// @notice Fetches the pool's liquidity values
  /// @return baseL pool's base liquidity without reinvest liqudity
  /// @return reinvestL the liquidity is reinvested into the pool
  /// @return reinvestLLast last cached value of reinvestL, used for calculating reinvestment token qty
  function getLiquidityState()
    external
    view
    returns (
      uint128 baseL,
      uint128 reinvestL,
      uint128 reinvestLLast
    );

  /// @return feeGrowthGlobal All-time fee growth per unit of liquidity of the pool
  function getFeeGrowthGlobal() external view returns (uint256);

  /// @return secondsPerLiquidityGlobal All-time seconds per unit of liquidity of the pool
  /// @return lastUpdateTime The timestamp in which secondsPerLiquidityGlobal was last updated
  function getSecondsPerLiquidityData()
    external
    view
    returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

  /// @notice Calculates and returns the active time per unit of liquidity until current block.timestamp
  /// @param tickLower The lower tick (of a position)
  /// @param tickUpper The upper tick (of a position)
  /// @return secondsPerLiquidityInside active time (multiplied by 2^96)
  /// between the 2 ticks, per unit of liquidity.
  function getSecondsPerLiquidityInside(int24 tickLower, int24 tickUpper)
    external
    view
    returns (uint128 secondsPerLiquidityInside);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

abstract contract KSAdmin {
  address public admin;
  mapping(address => bool) public operators; // address => bool

  event TransferAdmin(address indexed admin);
  event UpdateOperator(address indexed user, bool grantOrRevoke);

  modifier isAdmin() {
    require(msg.sender == admin, 'forbidden');
    _;
  }

  modifier isOperator() {
    require(operators[msg.sender], 'forbidden');
    _;
  }

  constructor() {
    admin = msg.sender;
    operators[msg.sender] = true;
  }

  function transferAdmin(address _admin) external virtual isAdmin {
    admin = _admin;

    emit TransferAdmin(_admin);
  }

  function updateOperator(address user, bool grantOrRevoke) external isAdmin {
    operators[user] = grantOrRevoke;

    emit UpdateOperator(user, grantOrRevoke);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IKSElasticLMHelper} from './IKSElasticLMHelper.sol';

interface IKyberSwapElasticLMEvents {
  event AddPool(
    uint256 indexed pId,
    address poolAddress,
    uint32 startTime,
    uint32 endTime,
    uint256 feeTarget
  );

  event RenewPool(uint256 indexed pid, uint32 startTime, uint32 endTime, uint256 feeTarget);

  event Deposit(address sender, uint256 indexed nftId);

  event Withdraw(address sender, uint256 indexed nftId);

  event Join(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Exit(address to, uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event SyncLiq(uint256 indexed nftId, uint256 indexed pId, uint256 indexed liq);

  event Harvest(uint256 indexed nftId, address to, address reward, uint256 indexed amount);

  event EmergencyEnabled();

  event EmergencyWithdrawForOwner(address reward, uint256 indexed amount);

  event EmergencyWithdraw(address sender, uint256 indexed nftId);

  event LMHelperUpdated(IKSElasticLMHelper helper);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

/// @title KyberSwap v2 factory
/// @notice Deploys KyberSwap v2 pools and manages control over government fees
interface IFactory {
  /// @notice Emitted when a pool is created
  /// @param token0 First pool token by address sort order
  /// @param token1 Second pool token by address sort order
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks
  /// @param pool The address of the created pool
  event PoolCreated(
    address indexed token0,
    address indexed token1,
    uint16 indexed swapFeeBps,
    int24 tickDistance,
    address pool
  );

  /// @notice Emitted when a new fee is enabled for pool creation via the factory
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @param tickDistance Minimum number of ticks between initialized ticks for pools created with the given fee
  event SwapFeeEnabled(uint16 indexed swapFeeBps, int24 indexed tickDistance);

  /// @notice Emitted when vesting period changes
  /// @param vestingPeriod The maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  event VestingPeriodUpdated(uint32 vestingPeriod);

  /// @notice Emitted when configMaster changes
  /// @param oldConfigMaster configMaster before the update
  /// @param newConfigMaster configMaster after the update
  event ConfigMasterUpdated(address oldConfigMaster, address newConfigMaster);

  /// @notice Emitted when fee configuration changes
  /// @param feeTo Recipient of government fees
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  event FeeConfigurationUpdated(address feeTo, uint16 governmentFeeBps);

  /// @notice Emitted when whitelist feature is enabled
  event WhitelistEnabled();

  /// @notice Emitted when whitelist feature is disabled
  event WhitelistDisabled();

  /// @notice Returns the maximum time duration for which LP fees
  /// are proportionally burnt upon LP removals
  function vestingPeriod() external view returns (uint32);

  /// @notice Returns the tick distance for a specified fee.
  /// @dev Once added, cannot be updated or removed.
  /// @param swapFeeBps Swap fee, in basis points.
  /// @return The tick distance. Returns 0 if fee has not been added.
  function feeAmountTickDistance(uint16 swapFeeBps) external view returns (int24);

  /// @notice Returns the address which can update the fee configuration
  function configMaster() external view returns (address);

  /// @notice Returns the keccak256 hash of the Pool creation code
  /// This is used for pre-computation of pool addresses
  function poolInitHash() external view returns (bytes32);

  /// @notice Fetches the recipient of government fees
  /// and current government fee charged in basis points
  function feeConfiguration() external view returns (address _feeTo, uint16 _governmentFeeBps);

  /// @notice Returns the status of whitelisting feature of NFT managers
  /// If true, anyone can mint liquidity tokens
  /// Otherwise, only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function whitelistDisabled() external view returns (bool);

  //// @notice Returns all whitelisted NFT managers
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  function getWhitelistedNFTManagers() external view returns (address[] memory);

  /// @notice Checks if sender is a whitelisted NFT manager
  /// If the whitelisting feature is turned on,
  /// only whitelisted NFT manager(s) are allowed to mint liquidity tokens
  /// @param sender address to be checked
  /// @return true if sender is a whistelisted NFT manager, false otherwise
  function isWhitelistedNFTManager(address sender) external view returns (bool);

  /// @notice Returns the pool address for a given pair of tokens and a swap fee
  /// @dev Token order does not matter
  /// @param tokenA Contract address of either token0 or token1
  /// @param tokenB Contract address of the other token
  /// @param swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return pool The pool address. Returns null address if it does not exist
  function getPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external view returns (address pool);

  /// @notice Fetch parameters to be used for pool creation
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return factory The factory address
  /// @return token0 First pool token by address sort order
  /// @return token1 Second pool token by address sort order
  /// @return swapFeeBps Fee to be collected upon every swap in the pool, in basis points
  /// @return tickDistance Minimum number of ticks between initialized ticks
  function parameters()
    external
    view
    returns (
      address factory,
      address token0,
      address token1,
      uint16 swapFeeBps,
      int24 tickDistance
    );

  /// @notice Creates a pool for the given two tokens and fee
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @param swapFeeBps Desired swap fee for the pool, in basis points
  /// @dev Token order does not matter. tickDistance is determined from the fee.
  /// Call will revert under any of these conditions:
  ///     1) pool already exists
  ///     2) invalid swap fee
  ///     3) invalid token arguments
  /// @return pool The address of the newly created pool
  function createPool(
    address tokenA,
    address tokenB,
    uint16 swapFeeBps
  ) external returns (address pool);

  /// @notice Enables a fee amount with the given tickDistance
  /// @dev Fee amounts may never be removed once enabled
  /// @param swapFeeBps The fee amount to enable, in basis points
  /// @param tickDistance The distance between ticks to be enforced for all pools created with the given fee amount
  function enableSwapFee(uint16 swapFeeBps, int24 tickDistance) external;

  /// @notice Updates the address which can update the fee configuration
  /// @dev Must be called by the current configMaster
  function updateConfigMaster(address) external;

  /// @notice Updates the vesting period
  /// @dev Must be called by the current configMaster
  function updateVestingPeriod(uint32) external;

  /// @notice Updates the address receiving government fees and fee quantity
  /// @dev Only configMaster is able to perform the update
  /// @param feeTo Address to receive government fees collected from pools
  /// @param governmentFeeBps Fee amount, in basis points,
  /// to be collected out of the fee charged for a pool swap
  function updateFeeConfiguration(address feeTo, uint16 governmentFeeBps) external;

  /// @notice Enables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function enableWhitelist() external;

  /// @notice Disables the whitelisting feature
  /// @dev Only configMaster is able to perform the update
  function disableWhitelist() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}