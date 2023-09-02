pragma solidity ^0.8.7;

import { IEmitter } from "./interface/IEmitter.sol";
import { IBoostableStaking } from "./interface/IBoostableStaking.sol";
import { IGaugesManager } from "./interface/IGaugesManager.sol";

import { TokenTransferrer } from "vesta-core/token/TokenTransferrer.sol";
import { BaseVesta } from "vesta-core/BaseVesta.sol";
import { Math } from "vesta-core/math/Math.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

import { Clones } from "openzeppelin/proxy/Clones.sol";

contract GaugesManager is TokenTransferrer, BaseVesta, IGaugesManager {
  uint256 public constant WEEKLY_PERIOD_DURATION = 1 weeks;

  address public vsta;
  address public bVSTA;
  address public ownerProxy;

  uint256 public totalActiveBoostsInSystem;
  uint256 public lastDistributionTime;
  address[] private boostableGauges;
  address[] private deletedGauges;

  mapping(address gauge => bool) private isGauges;
  mapping(address gauge => bool) private isDisabledGauges;
  mapping(address gauge => bool) private isGaugesRemoved;
  mapping(address user => uint256) private totalUserBoostAllocations;
  mapping(address user => mapping(address gauge => uint256)) private
    boostAllocatedToGauges;
  mapping(address user => mapping(address gauge => uint256)) private userLastActiveBoosts;

  mapping(address gauge => uint256) private totalBoostsByGauge;

  function setUp(
    address _owner,
    address _vsta,
    address _bVsta,
    address _vstLp,
    address _gaugeImplementation
  ) external initializer {
    __BASE_VESTA_INIT();
    vsta = _vsta;
    bVSTA = _bVsta;

    _createNewGauge(_vstLp, _gaugeImplementation);
    _transferOwnership(_owner);
  }

  modifier ensureValidGauge(address _gauge) {
    if (!isGauges[_gauge]) revert GaugeNotFound();
    _;
  }

  modifier ensureGaugeNotRemoved(address _gauge) {
    if (isGaugesRemoved[_gauge]) revert GaugeNotFound();
    _;
  }

  function stakeAndSetBoostGauge(
    address _gauge,
    uint256 _stakeAmount,
    uint256 _boostAmount
  ) external override ensureValidGauge(_gauge) ensureGaugeNotRemoved(_gauge) {
    _updateBoost(_gauge, _boostAmount);
    IBoostableStaking(_gauge).stake(msg.sender, _stakeAmount, _boostAmount);
  }

  function stakeInGauge(address _gauge, uint256 _amount)
    external
    override
    ensureValidGauge(_gauge)
    ensureGaugeNotRemoved(_gauge)
  {
    IBoostableStaking(_gauge).stake(
      msg.sender, _amount, boostAllocatedToGauges[msg.sender][_gauge]
    );
  }

  function withdrawFromGauge(address _gauge, uint256 _amount)
    external
    override
    ensureValidGauge(_gauge)
  {
    IBoostableStaking(_gauge).withdrawViaGaugeManager(msg.sender, _amount);
  }

  function exitFromGauge(address _gauge) external ensureValidGauge(_gauge) {
    IBoostableStaking(_gauge).exit(msg.sender);
  }

  function boostGauge(address _gauge, uint256 _boostAmount)
    external
    ensureValidGauge(_gauge)
    ensureGaugeNotRemoved(_gauge)
  {
    _updateBoost(_gauge, boostAllocatedToGauges[msg.sender][_gauge] + _boostAmount);
  }

  function unboostGauge(address _gauge, uint256 _amount)
    external
    ensureValidGauge(_gauge)
  {
    _updateBoost(_gauge, boostAllocatedToGauges[msg.sender][_gauge] - _amount);
  }

  function _updateBoost(address _gauge, uint256 _boostValue) private {
    totalUserBoostAllocations[msg.sender] = totalUserBoostAllocations[msg.sender]
      - boostAllocatedToGauges[msg.sender][_gauge] + _boostValue;

    boostAllocatedToGauges[msg.sender][_gauge] = _boostValue;

    if (totalUserBoostAllocations[msg.sender] > IERC20(bVSTA).balanceOf(msg.sender)) {
      revert InsufficientBVsta();
    }

    uint256 ratio = _getActiveBoostRatio(msg.sender);
    _applyBoostToGauge(msg.sender, _gauge, ratio);

    emit UserGaugeBoostChanged(msg.sender, _gauge, _boostValue);
  }

  function updateUserBoosts(address _user) external override {
    uint256 ratio = _getActiveBoostRatio(_user);

    uint256 length = boostableGauges.length;
    address currentGauge;
    uint256 currentVoteAmount;

    for (uint256 i = 0; i < length;) {
      currentGauge = boostableGauges[i];

      if (
        !isDisabledGauges[currentGauge] && boostAllocatedToGauges[_user][currentGauge] > 0
      ) {
        currentVoteAmount = totalBoostsByGauge[currentGauge];
        _applyBoostToGauge(_user, currentGauge, ratio);
      }

      unchecked {
        ++i;
      }
    }
  }

  function _getActiveBoostRatio(address _user) private view returns (uint256) {
    (uint256 activeBVsta,) = IEmitter(bVSTA).getPenaltyDetails(_user);
    return
      Math.min(1e18, Math.mulDiv(activeBVsta, 1e18, totalUserBoostAllocations[_user]));
  }

  function _applyBoostToGauge(address _user, address _gauge, uint256 _activeRatio)
    internal
  {
    uint256 lastActive = userLastActiveBoosts[_user][_gauge];

    uint256 adjustedBoostAmount =
      Math.mulDiv(boostAllocatedToGauges[msg.sender][_gauge], _activeRatio, 1e18);

    totalBoostsByGauge[_gauge] =
      totalBoostsByGauge[_gauge] - lastActive + adjustedBoostAmount;

    if (!isDisabledGauges[_gauge]) {
      totalActiveBoostsInSystem =
        totalActiveBoostsInSystem - lastActive + adjustedBoostAmount;
    }

    if (lastActive == adjustedBoostAmount) return;

    userLastActiveBoosts[_user][_gauge] = adjustedBoostAmount;
    IBoostableStaking(_gauge).setUserBoost(_user, adjustedBoostAmount);
    emit UserActiveBoostChanged(msg.sender, _gauge, adjustedBoostAmount);
  }

  function distributeRewardToGauges(address[] memory _tokens, uint256[] memory _amounts)
    external
    onlyOwner
  {
    if (block.timestamp < lastDistributionTime + WEEKLY_PERIOD_DURATION) {
      revert DistributionNotFinished();
    }
    lastDistributionTime = block.timestamp;

    uint256 length = boostableGauges.length;
    uint256 totalVotes = totalActiveBoostsInSystem;
    address currentGauge;
    uint256 currentVoteAmount;
    uint256 usedAmount;
    uint128 sendingAmount;

    uint256 tokenLength = _tokens.length;
    address currentToken;
    uint256 currentRewardAmount;

    for (uint256 i = 0; i < tokenLength;) {
      currentToken = _tokens[i];
      currentRewardAmount = _amounts[i];

      _performTokenTransferFrom(
        currentToken, msg.sender, address(this), currentRewardAmount
      );

      for (uint256 x = 0; x < length;) {
        currentGauge = boostableGauges[x];
        currentVoteAmount = totalBoostsByGauge[currentGauge];

        if (!isDisabledGauges[currentGauge] && currentVoteAmount != 0) {
          sendingAmount =
            uint128(Math.mulDiv(currentRewardAmount, currentVoteAmount, totalVotes));

          _tryPerformMaxApprove(currentToken, currentGauge);

          IBoostableStaking(currentGauge).notifyRewardAmount(currentToken, sendingAmount);

          usedAmount += sendingAmount;
        }

        unchecked {
          ++x;
        }
      }

      emit RewardsDistributed(currentToken, currentRewardAmount);

      unchecked {
        ++i;
      }
    }

    if (usedAmount == 0) revert NoActiveOrBoostedGauge();
  }

  function createNewGauge(address _depositToken, address _gaugeImplementation)
    external
    onlyOwner
    returns (address)
  {
    return _createNewGauge(_depositToken, _gaugeImplementation);
  }

  function _createNewGauge(address _depositToken, address _gaugeImplementation)
    private
    returns (address gauge_)
  {
    bytes memory setupFunc = abi.encodeWithSignature(
      "setUp(address,address,address,uint64,address)",
      msg.sender, // owner
      _depositToken, // depositToken
      vsta, // rewardtoken
      WEEKLY_PERIOD_DURATION, // rewardsDuration
      address(this) // gaugeManager
    );

    gauge_ = Clones.clone(_gaugeImplementation);
    (bool success,) = gauge_.call(setupFunc);

    if (!success) revert FailedToDeployGauge();

    boostableGauges.push(gauge_);
    isGauges[gauge_] = true;

    emit DeployedGauge(gauge_);

    return gauge_;
  }

  function removeGauge(address _gauge) external onlyOwner ensureValidGauge(_gauge) {
    if (isGaugesRemoved[_gauge]) revert GaugeNotFound();

    uint256 length = boostableGauges.length;

    for (uint256 i = 0; i < length; ++i) {
      if (boostableGauges[i] != _gauge) continue;

      _changeGaugeStatus(_gauge, true);

      isGaugesRemoved[_gauge] = true;
      boostableGauges[i] = boostableGauges[length - 1];
      boostableGauges.pop();
      deletedGauges.push(_gauge);
      break;
    }

    emit GaugeDeleted(_gauge);
  }

  function changeGaugeStatus(address _gauge, bool _disable) external onlyOwner {
    _changeGaugeStatus(_gauge, _disable);
  }

  function _changeGaugeStatus(address _gauge, bool _disable)
    private
    ensureValidGauge(_gauge)
  {
    if (isGaugesRemoved[_gauge]) revert GaugeNotFound();
    if (isDisabledGauges[_gauge] == _disable) revert NoStatusChange();

    isDisabledGauges[_gauge] = _disable;

    if (_disable) {
      totalActiveBoostsInSystem -= totalBoostsByGauge[_gauge];
    } else {
      totalActiveBoostsInSystem += totalBoostsByGauge[_gauge];
    }

    emit GaugeStatusChanged(_gauge, _disable);
  }

  function isGauge(address _gauge) external view override returns (bool) {
    return isGauges[_gauge];
  }

  function isGaugeDisabled(address _gauge) external view override returns (bool) {
    return isDisabledGauges[_gauge];
  }

  function isGaugeDeleted(address _gauge) external view override returns (bool) {
    return isGaugesRemoved[_gauge];
  }

  function getUserAllocationToGauge(address _user, address _gauge)
    external
    view
    override
    returns (uint256)
  {
    return boostAllocatedToGauges[_user][_gauge];
  }

  function getTotalBoostByGauge(address _gauge) external view returns (uint256) {
    return totalBoostsByGauge[_gauge];
  }

  function getAllocatedAmount(address _user) external view override returns (uint256) {
    return totalUserBoostAllocations[_user];
  }

  function getGauges() external view returns (address[] memory) {
    return boostableGauges;
  }

  function getDeletedGauges() external view returns (address[] memory) {
    return deletedGauges;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEmitter {
  /**
   * onVest is called when the user claims, we have to update the penalty system so we do not count them anymore
   * @param _user address of the user
   * @param _vestedAmount amount vesting by the user
   * @dev only bVSTA contract can call this function
   */
  function onVest(address _user, uint256 _vestedAmount) external;

  /**
   *
   * @param _user address of the user
   * @return activeBVsta_ total active from this emitter
   * @return totalEmitted_ total emitted by this emitter to the user
   */
  function getPenaltyDetails(address _user)
    external
    view
    returns (uint256 activeBVsta_, uint256 totalEmitted_);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Reward } from "../model/BoostableStakingModel.sol";
import { EBoostableStaking } from "../event/EBoostableStaking.sol";

interface IBoostableStaking is EBoostableStaking {
  /**
   * @notice stake token into the system to receive rewards
   * @param _user address of the user
   * @param _stakingAmount amount staking by the user
   * @param _setBoost  boost value of the user
   * @dev This function can only be called by the GaugeManager
   */
  function stake(address _user, uint256 _stakingAmount, uint256 _setBoost) external;

  /**
   * @notice setUserBoost modify the user's boost power
   * @param _user address of the user
   * @param _amount boost value of the user
   * @dev This function can only be called by the GaugeManager
   */
  function setUserBoost(address _user, uint256 _amount) external;

  /**
   * @notice withdrawViaGaugeManager withdraw `_amount` of token of the user from the pool
   * @param _user  address of the user
   * @param _amount  amount to withdraw
   * @dev this function can only be called by the GaugeManager
   * @dev Since most of the logic is to interact with GaugeManager (to handle boosting),
   * we added this function so F-E implementor can only uses GaugeManager's ABI
   */
  function withdrawViaGaugeManager(address _user, uint256 _amount) external;

  /**
   * @notice withdraw `_amount` of user's token
   * @param _amount amount to withdraw
   */
  function withdraw(uint256 _amount) external;

  /**
   * @notice exit leave comletely the system
   * @param _user address of the user
   * @dev This function can only be called by the GaugeManager
   */
  function exit(address _user) external;

  /**
   * @notice claimRewards claims pending rewards
   * @param _user address of the user
   * @dev Everyone can call this function, the rewards will still be sent to `_user`
   */
  function claimRewards(address _user) external;

  /**
   * @notice notifyRewardAmount refill the rewards of the pool
   * @param _rewardToken address of the reward token
   * @param _reward amount of reward for the next distribution period
   * @dev This function can only be called by GaugeManager
   */
  function notifyRewardAmount(address _rewardToken, uint128 _reward) external;

  /**
   * @notice earned get the amount of rewards the user haven't claimed yet.
   * @param _token address of the user
   * @param _account address of the user
   */
  function earned(address _token, address _account) external view returns (uint256);

  /**
   * @notice earnedTotal get the amount of rewards the user haven't claimed yet from all tokens.
   * @param _account address of the user
   * @return tokens_ an array of reward tokens
   * @return rewards_ an array of each reward per token
   */
  function earnedTotal(address _account)
    external
    view
    returns (address[] memory tokens_, uint256[] memory rewards_);

  /**
   * @notice getUserDeposit get user's stake balance
   * @param _user address of the user
   */
  function getUserDeposit(address _user) external view returns (uint256);

  /**
   * @notice rewardPerToken gets the rewardPerToken value for each streaming for the new distributed rewards
   * @param _token address of the reward token
   * @return rewardPerStaking_ reward per stakes
   * @return rewardPerBoostingWeight_ reward per boosting weight
   */
  function rewardPerToken(address _token)
    external
    view
    returns (uint256 rewardPerStaking_, uint256 rewardPerBoostingWeight_);

  /**
   * @notice getBoostAmount get user's boost raw value (Not the boost weight)
   * @param _account address of the user
   */
  function getBoostAmount(address _account) external view returns (uint256);

  /**
   * @notice getBoostWeight get the weight of the user's boost
   * @param _user address of the user
   */
  function getBoostWeight(address _user) external view returns (uint256);

  /**
   * @notice totalBoosts get total raw boosts on the pool (Not the total boost weight)
   */
  function totalBoosts() external view returns (uint256);

  /**
   * @notice getRewardStreamings returns the two streaming rewards on the pool
   * @param _token address of the reward token
   * @return stakingStreaming_ Anyone who is staked into the contract can receive this
   * @return boostingStreaming_ Anyone who is staked AND are boosting can receive this
   */
  function getRewardStreamings(address _token)
    external
    view
    returns (Reward memory stakingStreaming_, Reward memory boostingStreaming_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { EGaugesManager } from "../event/EGaugesManager.sol";

interface IGaugesManager is EGaugesManager {
  /**
   * stakeAndSetBoostGauge Stake And Boost a gauge
   * @param _gauge address of the gauge
   * @param _stakeAmount amount to stake
   * @param _boostAmount amount to boost
   */
  function stakeAndSetBoostGauge(
    address _gauge,
    uint256 _stakeAmount,
    uint256 _boostAmount
  ) external;

  /**
   * Stake in a gauge
   * @param _gauge adress of the gauge
   * @param _amount amount to stake
   * @dev The user needs to give approval to the `_gauge` otherwise the transfer will fail
   */
  function stakeInGauge(address _gauge, uint256 _amount) external;

  /**
   * withdrawFromGauge unstake from a gauge
   * @param _gauge address of the gauge
   * @param _amount amount to unstake
   */
  function withdrawFromGauge(address _gauge, uint256 _amount) external;

  /**
   * exitFromGauge exit from a gauge
   * @param _gauge address of the gauge
   */
  function exitFromGauge(address _gauge) external;

  /**
   * boostGauge allows the user to boost the reward of a specific gauge
   * @param _gauge address of the gauge
   * @param _amount amount to boost
   */
  function boostGauge(address _gauge, uint256 _amount) external;

  /**
   * unboostGauge allows the user to unboost a specific gauge
   * @param _gauge address of the gauge
   * @param _amount amount to withdraw
   */
  function unboostGauge(address _gauge, uint256 _amount) external;

  /**
   * updateUserBoosts triggers a refresh on the user's boost after a withdraw or deposit.
   * @param _user address of the user
   * @dev There is no point for a user to call this function, this is mainly for the protocol logic
   */
  function updateUserBoosts(address _user) external;

  /**
   * distributeRewardToGauges start a new distribution period on all gauges
   * @param _tokens addresses of reward tokens
   * @param _amounts amounts by token to give as reward
   * @dev can only be called by the distributor
   */
  function distributeRewardToGauges(address[] memory _tokens, uint256[] memory _amounts)
    external;

  /**
   * isGauge Check if the address is a vesta gauge
   * @param _gauge address of gauge
   */
  function isGauge(address _gauge) external view returns (bool);

  /**
   * isGaugeDisabled check if the gauge is enabled or disabled. A disabled gauge will stop receive reward from `distributeRewardToGauges`
   * @param _gauge address of gauge
   */
  function isGaugeDisabled(address _gauge) external view returns (bool);

  /**
   * isGaugeDeleted check if the gauge has been deleted
   * @param _gauge address of gauge
   */
  function isGaugeDeleted(address _gauge) external view returns (bool);

  /**
   * getUserAllocationToGauge get how much a user is allocating their boosting to a gauge
   * @param _user address of the user
   * @param _gauge address of the gauge
   * @return boost_ amount of bVSTA allocated to the gauge
   */
  function getUserAllocationToGauge(address _user, address _gauge)
    external
    view
    returns (uint256);

  /**
   * getAllocatedAmount returns how much user's bVSTA is allocated in the boosting system
   * @param _user address of the user
   */
  function getAllocatedAmount(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenTransferrerConstants.sol";
import { TokenTransferrerErrors } from "./TokenTransferrerErrors.sol";
import { IERC20 } from "./interface/IERC20.sol";
import { IERC20Callback } from "./interface/IERC20Callback.sol";

/**
 * @title TokenTransferrer
 * @custom:source https://github.com/ProjectOpenSea/seaport
 * @dev Modified version of Seaport.
 */
abstract contract TokenTransferrer is TokenTransferrerErrors {
    function _performTokenTransfer(address token, address to, uint256 amount)
        internal
        returns (bool)
    {
        if (token == address(0)) {
            (bool success,) = to.call{ value: amount }(new bytes(0));

            return success;
        }

        address from = address(this);

        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transfer_sig_ptr, ERC20_transfer_signature)
            mstore(ERC20_transfer_to_ptr, to)
            mstore(ERC20_transfer_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus :=
                call(
                    gas(), token, 0, ERC20_transfer_sig_ptr, ERC20_transfer_length, 0, OneWord
                )

            // Determine whether transfer was successful using status & result.
            let success :=
                and(
                    // Set success to whether the call reverted, if not check it
                    // either returned exactly 1 (can't just be non-zero data), or
                    // had no return data.
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    callStatus
                )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords :=
                                    div(add(returndatasize(), AlmostOneWord), OneWord)

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost :=
                                        add(
                                            cost,
                                            add(
                                                mul(
                                                    sub(returnDataWords, msizeWords),
                                                    CostPerWord
                                                ),
                                                div(
                                                    sub(
                                                        mul(returnDataWords, returnDataWords),
                                                        mul(msizeWords, msizeWords)
                                                    ),
                                                    MemoryExpansionCoefficient
                                                )
                                            )
                                        )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(TokenTransferGenericFailure_error_token_ptr, token)
                            mstore(TokenTransferGenericFailure_error_from_ptr, from)
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
                        mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
                        mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
                        mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }

        return true;
    }

    function _performTokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus :=
                call(
                    gas(),
                    token,
                    0,
                    ERC20_transferFrom_sig_ptr,
                    ERC20_transferFrom_length,
                    0,
                    OneWord
                )

            // Determine whether transfer was successful using status & result.
            let success :=
                and(
                    // Set success to whether the call reverted, if not check it
                    // either returned exactly 1 (can't just be non-zero data), or
                    // had no return data.
                    or(
                        and(eq(mload(0), 1), gt(returndatasize(), 31)),
                        iszero(returndatasize())
                    ),
                    callStatus
                )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords :=
                                    div(add(returndatasize(), AlmostOneWord), OneWord)

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost :=
                                        add(
                                            cost,
                                            add(
                                                mul(
                                                    sub(returnDataWords, msizeWords),
                                                    CostPerWord
                                                ),
                                                div(
                                                    sub(
                                                        mul(returnDataWords, returnDataWords),
                                                        mul(msizeWords, msizeWords)
                                                    ),
                                                    MemoryExpansionCoefficient
                                                )
                                            )
                                        )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(TokenTransferGenericFailure_error_token_ptr, token)
                            mstore(TokenTransferGenericFailure_error_from_ptr, from)
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(BadReturnValueFromERC20OnTransfer_error_token_ptr, token)
                        mstore(BadReturnValueFromERC20OnTransfer_error_from_ptr, from)
                        mstore(BadReturnValueFromERC20OnTransfer_error_to_ptr, to)
                        mstore(BadReturnValueFromERC20OnTransfer_error_amount_ptr, amount)
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @notice SanitizeAmount allows to convert an 1e18 value to the token decimals
     * 		@dev only supports 18 and lower
     * 		@param token The contract address of the token
     * 		@param value The value you want to sanitize
     */
    function _sanitizeValue(address token, uint256 value)
        internal
        view
        returns (uint256)
    {
        if (token == address(0) || value == 0) return value;

        (bool success, bytes memory data) =
            token.staticcall(abi.encodeWithSignature("decimals()"));

        if (!success) return value;

        uint8 decimals = abi.decode(data, (uint8));

        if (decimals < 18) {
            return value / (10 ** (18 - decimals));
        }

        return value;
    }

    function _tryPerformMaxApprove(address _token, address _to) internal {
        if (IERC20(_token).allowance(address(this), _to) == type(uint256).max) {
            return;
        }

        _performApprove(_token, _to, type(uint256).max);
    }

    function _performApprove(address _token, address _spender, uint256 _value) internal {
        IERC20(_token).approve(_spender, _value);
    }

    function _balanceOf(address _token, address _of) internal view returns (uint256) {
        return IERC20(_token).balanceOf(_of);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBaseVesta.sol";
import "./vendor/OwnableUpgradeable.sol";

/**
 * @title BaseVesta
 * @notice Inherited by most of our contracts. It has a permission system & reentrency protection inside it.
 * @dev Binary Roles Recommended Slots
 * 0x01  |  0x10
 * 0x02  |  0x20
 * 0x04  |  0x40
 * 0x08  |  0x80
 *
 * Don't use other slots unless you are familiar with bitewise operations
 */

abstract contract BaseVesta is IBaseVesta, OwnableUpgradeable {
    address internal constant RESERVED_ETH_ADDRESS = address(0);
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint256 internal constant DECIMAL_PRECISION = 1e18;
    address internal SELF;

    bool private reentrencyStatus;

    mapping(address => bytes1) internal permissions;

    uint256[49] private __gap;

    modifier onlyContract(address _address) {
        if (_address.code.length == 0) revert InvalidContract();
        _;
    }

    modifier onlyContracts(address _address, address _address2) {
        if (_address.code.length == 0 || _address2.code.length == 0) {
            revert InvalidContract();
        }
        _;
    }

    modifier onlyValidAddress(address _address) {
        if (_address == address(0)) {
            revert InvalidAddress();
        }

        _;
    }

    modifier nonReentrant() {
        if (reentrencyStatus) revert NonReentrancy();
        reentrencyStatus = true;
        _;
        reentrencyStatus = false;
    }

    modifier hasPermission(bytes1 access) {
        if (permissions[msg.sender] & access == 0) revert InvalidPermission();
        _;
    }

    modifier hasPermissionOrOwner(bytes1 access) {
        if (permissions[msg.sender] & access == 0 && msg.sender != owner()) {
            revert InvalidPermission();
        }

        _;
    }

    modifier notZero(uint256 _amount) {
        if (_amount == 0) revert NumberIsZero();
        _;
    }

    function __BASE_VESTA_INIT() internal onlyInitializing {
        __Ownable_init();
        SELF = address(this);
    }

    function setPermission(address _address, bytes1 _permission)
        external
        override
        onlyOwner
    {
        _setPermission(_address, _permission);
    }

    function _clearPermission(address _address) internal virtual {
        _setPermission(_address, 0x00);
    }

    function _setPermission(address _address, bytes1 _permission) internal virtual {
        permissions[_address] = _permission;
        emit PermissionChanged(_address, _permission);
    }

    function getPermissionLevel(address _address)
        external
        view
        override
        returns (bytes1)
    {
        return permissions[_address];
    }

    function hasPermissionLevel(address _address, bytes1 accessLevel)
        public
        view
        override
        returns (bool)
    {
        return permissions[_address] & accessLevel != 0;
    }

    /**
     * @notice _sanitizeMsgValueWithParam is for multi-token payable function.
     * 	@dev msg.value should be set to zero if the token used isn't a native token.
     * 		address(0) is reserved for Native Chain Token.
     * 		if fails, it will reverts with SanitizeMsgValueFailed
     * 	@return sanitizeValue which is the sanitize value you should use in your code.
     */
    function _sanitizeMsgValueWithParam(address _token, uint256 _paramValue)
        internal
        view
        returns (uint256)
    {
        if (RESERVED_ETH_ADDRESS == _token) {
            return msg.value;
        } else if (msg.value == 0) {
            return _paramValue;
        }

        revert SanitizeMsgValueFailed();
    }

    function isContract(address _address) internal view returns (bool) {
        return _address.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library Math {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    function getAbsoluteDifference(uint256 _a, uint256 _b)
        internal
        pure
        returns (uint256)
    {
        return (_a >= _b) ? (_a - _b) : (_b - _a);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y - 1)) / y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD) / y;
    }

    function wdivup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = divup((x * WAD), y);
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y) / RAY;
    }

    function rmulup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = divup((x * y), RAY);
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mulDiv(x, RAY, y);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.20;

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
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

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
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
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
        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
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
pragma solidity >=0.8.0;

struct BoostableRewards {
  uint256 baseWeightPercentage;
  uint256 boostedWeightPercentage;
  uint128 endPeriod;
  uint128 lastUpdate;
  Reward stakingReward;
  Reward boostingReward;
  mapping(address => uint256) userRewardPerTokenPaid;
  mapping(address => uint256) userRewardPerBoost;
  mapping(address => uint256) rewards;
}

struct RewardSystemReadable {
  uint256 baseWeightPercentage;
  uint256 boostedWeightPercentage;
  uint128 endPeriod;
  uint128 lastUpdate;
  Reward stakingReward;
  Reward boostingReward;
}

struct Reward {
  uint256 rewardRatePerSecond;
  uint256 rewardPerTokenStored;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface EBoostableStaking {
  error BoostWeightPercentagesMustAddTo100();
  error StakeBalanceEmpty();
  error UseExitFunction();
  error MismatchLength();

  event Stake(address indexed user, uint256 amount);
  event AdjustBoost(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardAdded(address indexed rewardToken, uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface EGaugesManager {
  error InsufficientBVsta();
  error DistributionNotFinished();
  error GaugeNotFound();
  error NoStatusChange();
  error NoActiveOrBoostedGauge();
  error FailedToDeployGauge();

  event UserActiveBoostChanged(
    address indexed user, address indexed gauge, uint256 activeBoost
  );
  event DeployedGauge(address indexed gauge);
  event UserGaugeBoostChanged(
    address indexed user, address indexed gauge, uint256 boostValue
  );
  event RewardsDistributed(address indexed token, uint256 amount);
  event GaugeDeleted(address indexed gauge);
  event GaugeStatusChanged(address indexed gauge, bool isDisabled);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature =
    (0x23b872dd00000000000000000000000000000000000000000000000000000000);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("transfer(address,uint256)")
uint256 constant ERC20_transfer_signature =
    (0xa9059cbb00000000000000000000000000000000000000000000000000000000);

uint256 constant ERC20_transfer_sig_ptr = 0x0;
uint256 constant ERC20_transfer_to_ptr = 0x04;
uint256 constant ERC20_transfer_amount_ptr = 0x24;
uint256 constant ERC20_transfer_length = 0x44; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature =
    (0x5f15d67200000000000000000000000000000000000000000000000000000000);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature =
    (0xf486bc8700000000000000000000000000000000000000000000000000000000);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature =
    (0x9889192300000000000000000000000000000000000000000000000000000000);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
    error ErrorTransferETH(address caller, address to, uint256 value);

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token, address from, address to, uint256 identifier, uint256 amount
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token, address from, address to, uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert if the {_to} callback is the same as the souce (address(this))
     */
    error SelfCallbackTransfer();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20Callback {
    /// @notice receiveERC20 should be used as the "receive" callback of native token but for erc20
    /// @dev Be sure to limit the access of this call.
    /// @param _token transfered token
    /// @param _value The value of the transfer
    function receiveERC20(address _token, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBaseVesta {
    error NonReentrancy();
    error InvalidPermission();
    error InvalidAddress();
    error CannotBeNativeChainToken();
    error InvalidContract();
    error NumberIsZero();
    error SanitizeMsgValueFailed();

    event PermissionChanged(address indexed _address, bytes1 newPermission);

    /**
     * @notice setPermission to an address so they have access to specific functions.
     * 	@dev can add multiple permission by using | between them
     * 	@param _address the address that will receive the permissions
     * 	@param _permission the bytes permission(s)
     */
    function setPermission(address _address, bytes1 _permission) external;

    /**
     * @notice get the permission level on an address
     * 	@param _address the address you want to check the permission on
     * 	@return accessLevel the bytes code of the address permission
     */
    function getPermissionLevel(address _address) external view returns (bytes1);

    /**
     * @notice Verify if an address has specific permissions
     * 	@param _address the address you want to check
     * 	@param _accessLevel the access level you want to verify on
     * 	@return hasAccess return true if the address has access
     */
    function hasPermissionLevel(address _address, bytes1 _accessLevel)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing { }

    function __Context_init_unchained() internal onlyInitializing { }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1)
                || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}