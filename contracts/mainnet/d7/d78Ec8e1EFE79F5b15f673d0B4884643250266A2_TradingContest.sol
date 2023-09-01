// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IDaoStaking} from "src/interfaces/IDaoStaking.sol";
import {IOmniStaking} from "src/interfaces/IOmniStaking.sol";
import {
    LeaderInfo, ContestResult, LeaderInfoView, BatchInfo, ITradingContest
} from "src/interfaces/ITradingContest.sol";

contract TradingContest is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ITradingContest {
    /*================= VARIABLES ================*/
    using SafeERC20 for IERC20;

    IERC20 public constant LVL = IERC20(0xB64E280e9D1B5DbEc4AcceDb2257A87b400DB149);
    IERC20 public constant PRE_LVL = IERC20(0x964d582dA16B37F8d16DF3A66e6BF0E7fd44ac3a);

    uint64 public constant START_BATCH_USING_PRE_LVL = 11;

    uint64 public constant MAX_BATCH_DURATION = 30 days;
    uint64 public constant MAX_VESTING_DURATION = 7 days;
    uint128 public constant TOKEN_PRECISION = 1e18;
    uint128 public constant BONUS_PRECISION = 1e10;
    uint128 public constant BONUS_PER_TOKEN = 1e5;

    uint128 public constant TOTAL_WEIGHT = 35200;
    /// @notice number of allocation for each batch to be close
    uint128 public constant N_ALLOCATION = 7;

    uint64 public currentBatch;
    uint64 public vestingDuration;
    uint64 public batchDuration;

    address public poolHook;
    address public updater;
    address public admin;
    address public controller;

    bool public enableNextBatch;

    IOmniStaking public lvlStaking;
    IDaoStaking public daoStaking;

    mapping(uint64 => BatchInfo) public batches;
    mapping(uint64 => mapping(address => LeaderInfo)) public leaders;
    mapping(uint64 => address[]) private leaderAddresses;

    // rank => weight
    mapping(uint8 => uint64) public rewardWeights;
    /// @notice count number of allocation for each batch
    mapping(uint64 => uint256) public allocateCounter;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _poolHook) external initializer {
        require(_poolHook != address(0), "Invalid address");
        __Ownable_init();
        __ReentrancyGuard_init();
        poolHook = _poolHook;

        vestingDuration = 1 days;
        batchDuration = 1 days;

        rewardWeights[0] = 10000;
        rewardWeights[1] = 6000;
        rewardWeights[2] = 4000;
        rewardWeights[3] = 3000;
        rewardWeights[4] = 2500;
        rewardWeights[5] = 2000;
        rewardWeights[6] = 1700;
        rewardWeights[7] = 1400;
        rewardWeights[8] = 1100;
        rewardWeights[9] = 800;
        rewardWeights[10] = 600;
        rewardWeights[11] = 500;
        rewardWeights[12] = 400;
        rewardWeights[13] = 300;
        rewardWeights[14] = 200;
        rewardWeights[15] = 180;
        rewardWeights[16] = 160;
        rewardWeights[17] = 140;
        rewardWeights[18] = 120;
        rewardWeights[19] = 100;
    }

    /*================= VIEWS ======================*/

    function getNextBatch() public view returns (uint64 _nextBatchTimestamp, uint64 _vestingDuration) {
        _nextBatchTimestamp = batches[currentBatch].startTime + batchDuration;
        _vestingDuration = vestingDuration;
    }

    function getLeaders(uint64 _batchId) public view returns (LeaderInfoView[] memory _leaders) {
        address[] memory _addresses = leaderAddresses[_batchId];
        if (_addresses.length > 0) {
            _leaders = new LeaderInfoView[](_addresses.length);
            BatchInfo memory _batchInfo = batches[_batchId];
            uint128 _totalWeight = _batchInfo.totalWeight == 0 ? TOTAL_WEIGHT : _batchInfo.totalWeight;
            for (uint256 index = 0; index < _addresses.length; index++) {
                address _addr = _addresses[index];
                LeaderInfo memory _info = leaders[_batchId][_addr];
                _leaders[index] = LeaderInfoView({
                    trader: _addr,
                    index: _info.index,
                    totalPoint: _info.totalPoint,
                    rewardTokens: uint128(uint256(_batchInfo.rewardTokens) * uint256(_info.weight) / _totalWeight),
                    claimed: _info.claimed
                });
            }
        }
    }

    function getClaimableRewards(uint64 _batchId, address _user) public view returns (uint256 _claimableRewards) {
        BatchInfo memory _batchInfo = batches[_batchId];
        if (_batchInfo.startVestingTime > 0) {
            LeaderInfo memory _leader = leaders[_batchId][_user];
            uint128 _totalWeight = _batchInfo.totalWeight == 0 ? TOTAL_WEIGHT : _batchInfo.totalWeight;
            if (_leader.weight > 0) {
                if (block.timestamp >= _batchInfo.startVestingTime + _batchInfo.vestingDuration) {
                    _claimableRewards =
                        uint256(_batchInfo.rewardTokens) * uint256(_leader.weight) / _totalWeight - _leader.claimed;
                } else {
                    uint256 _time = block.timestamp - _batchInfo.startVestingTime;
                    _claimableRewards = (
                        _time * uint256(_batchInfo.rewardTokens) * uint256(_leader.weight) / _totalWeight
                            / _batchInfo.vestingDuration
                    ) - _leader.claimed;
                }
            }
        }
    }

    /*=================== MULTITATIVE =====================*/

    function claimRewards(uint64 _batchId, address _to) external nonReentrant {
        uint256 _claimableRewards = getClaimableRewards(_batchId, msg.sender);
        if (_claimableRewards > 0) {
            leaders[_batchId][msg.sender].claimed += uint128(_claimableRewards);
            IERC20 _rewardToken = _getRewardToken(_batchId);
            _rewardToken.safeTransfer(_to, _claimableRewards);
            emit Claimed(msg.sender, _to, _batchId, _claimableRewards);
        }
    }

    function claimMultiple(uint64[] memory _batchIds, address _to) external nonReentrant {
        uint256 _totalLVLClaimable = 0;
        uint256 _totalPreLVLClaimable = 0;
        for (uint64 index = 0; index < _batchIds.length; index++) {
            uint64 _batchId = _batchIds[index];
            BatchInfo memory _batchInfo = batches[_batchId];

            if (_batchInfo.startVestingTime > 0) {
                uint256 _claimableRewards = getClaimableRewards(_batchId, msg.sender);
                if (_claimableRewards > 0) {
                    leaders[_batchId][msg.sender].claimed += uint128(_claimableRewards);
                    if (_batchId >= START_BATCH_USING_PRE_LVL) {
                        _totalPreLVLClaimable += _claimableRewards;
                    } else {
                        _totalLVLClaimable += _claimableRewards;
                    }
                    emit Claimed(msg.sender, _to, _batchId, _claimableRewards);
                }
            }
        }
        if (_totalLVLClaimable > 0) {
            LVL.safeTransfer(_to, _totalLVLClaimable);
        }

        if (_totalPreLVLClaimable > 0) {
            PRE_LVL.safeTransfer(_to, _totalPreLVLClaimable);
        }
    }

    function record(address _user, uint256 _value) external {
        require(msg.sender == poolHook, "Only poolHook");
        if (
            currentBatch > 0 && block.timestamp >= batches[currentBatch].startTime && batches[currentBatch].endTime == 0
        ) {
            uint256 _lvlAmount;
            uint256 _lvlDAOAmount;

            if (lvlStaking != IOmniStaking(address(0))) {
                _lvlAmount = lvlStaking.stakedAmounts(_user);
            }
            if (daoStaking != IDaoStaking(address(0))) {
                (_lvlDAOAmount,,) = daoStaking.userInfo(_user);
            }

            uint256 _bonusRatio = (_lvlAmount + _lvlDAOAmount) * uint256(BONUS_PER_TOKEN) / TOKEN_PRECISION;
            uint256 _bonusPoint = _value * _bonusRatio / BONUS_PRECISION;
            uint256 _point = _value + _bonusPoint;
            emit RecordAdded(_user, _value, _lvlDAOAmount, _lvlAmount, _point, currentBatch);
        }
    }

    function addReward(uint256 _rewardTokens) external nonReentrant {
        require(msg.sender == controller, "!Controller");
        require(batches[currentBatch].startTime > 0, "Not exists");
        require(batches[currentBatch].startVestingTime == 0, "Finalized");
        if (_rewardTokens > 0) {
            IERC20 _rewardToken = _getRewardToken(currentBatch);
            _rewardToken.safeTransferFrom(msg.sender, address(this), _rewardTokens);
        }
        batches[currentBatch].rewardTokens += uint128(_rewardTokens);
        allocateCounter[currentBatch]++;
        emit RewardAdded(currentBatch, _rewardTokens);
    }

    function increaseReward(uint64 _batchId, uint256 _rewardTokens) external nonReentrant {
        require(msg.sender == admin, "!admin");
        require(batches[_batchId].startTime > 0, "Not exists");
        require(batches[_batchId].startVestingTime == 0, "Finalized");
        IERC20 _rewardToken = _getRewardToken(_batchId);
        _rewardToken.safeTransferFrom(msg.sender, address(this), _rewardTokens);
        batches[_batchId].rewardTokens += uint128(_rewardTokens);
        emit RewardIncreased(_batchId, _rewardTokens);
    }

    function decreaseReward(uint64 _batchId, uint256 _amount) external nonReentrant {
        require(msg.sender == admin, "!admin");
        require(batches[_batchId].startTime > 0, "Not exists");
        require(batches[_batchId].startVestingTime == 0, "Finalized");
        batches[_batchId].rewardTokens -= uint128(_amount);
        emit RewardDecreased(_batchId, _amount);
    }

    function forceNextBatch() external {
        require(msg.sender == admin, "!Admin");
        require(enableNextBatch, "!enableNextBatch");
        require(currentBatch > 0, "Not start");
        (uint64 _nextBatchTimestamp,) = getNextBatch();
        require(block.timestamp >= _nextBatchTimestamp, "now < trigger time");
        _nextBatch(_nextBatchTimestamp);
    }

    function nextBatch() external {
        require(enableNextBatch, "!enableNextBatch");
        require(currentBatch > 0, "Not start");
        require(allocateCounter[currentBatch] >= N_ALLOCATION, "notAllocated");
        (uint64 _nextBatchTimestamp,) = getNextBatch();
        require(block.timestamp >= _nextBatchTimestamp, "now < trigger time");
        require(batches[currentBatch].rewardTokens > 0, "Reward = 0");
        _nextBatch(_nextBatchTimestamp);
    }

    function updateLeaders(uint64 _batchId, ContestResult[] memory _leaders) external {
        require(msg.sender == updater || msg.sender == admin, "Only updater or admin");
        BatchInfo memory _batchInfo = batches[_batchId];
        require(_batchInfo.endTime > 0, "!Ended");
        require(_batchInfo.startVestingTime == 0, "Finalized");
        require(_leaders.length <= 20, "Invalid leaders");

        address[] memory _leaderAddresses = leaderAddresses[_batchId];
        for (uint256 index = 0; index < _leaderAddresses.length; index++) {
            delete leaders[_batchId][_leaderAddresses[index]];
        }
        delete leaderAddresses[_batchId];

        for (uint256 index = 0; index < _leaders.length; index++) {
            ContestResult memory _leader = _leaders[index];
            leaders[_batchId][_leader.trader] = LeaderInfo({
                weight: rewardWeights[_leader.index - 1],
                index: _leader.index,
                totalPoint: _leader.totalPoint,
                claimed: 0
            });
            leaderAddresses[_batchId].push(_leader.trader);
        }
        _batchInfo.leaderUpdated = true;
        batches[_batchId] = _batchInfo;
        emit LeaderUpdated(_batchId);
    }

    function finalize(uint64 _batchId) external {
        require(msg.sender == admin, "!Admin");
        BatchInfo memory _batchInfo = batches[_batchId];
        require(allocateCounter[_batchId] >= N_ALLOCATION, "notAllocated");
        require(_batchInfo.startVestingTime == 0, "Finalized");
        require(_batchInfo.leaderUpdated, "Leaders has not been updated yet");
        _batchInfo.startVestingTime = uint64(block.timestamp);
        if (_batchId < START_BATCH_USING_PRE_LVL) {
            _batchInfo.vestingDuration = vestingDuration;
        }
        _batchInfo.totalWeight = TOTAL_WEIGHT;

        batches[_batchId] = _batchInfo;
        emit Finalized(_batchId);
    }

    /*================ ADMIN ===================*/
    /**
     *  @notice allow admin to manual add rewards to current batch
     *  @param _rewardTokens amount to allocate
     */
    function addRewardManual(uint256 _rewardTokens) external {
        require(msg.sender == admin || msg.sender == owner(), "notAllowed");
        IERC20 _rewardToken = _getRewardToken(currentBatch);
        _rewardToken.safeTransferFrom(msg.sender, address(this), _rewardTokens);
        batches[currentBatch].rewardTokens += uint128(_rewardTokens);
        allocateCounter[currentBatch]++;
        emit RewardAdded(currentBatch, _rewardTokens);
    }

    function setPoolHook(address _poolHook) external onlyOwner {
        require(_poolHook != address(0), "Invalid address");
        poolHook = _poolHook;
        emit PoolHookSet(_poolHook);
    }

    function start(uint256 _startTime) external {
        require(_startTime >= block.timestamp, "start time < current time");
        require(currentBatch == 0, "Started");
        currentBatch = 1;
        batches[currentBatch].startTime = uint64(_startTime);
        emit BatchStarted(currentBatch);
    }

    function withdrawLVL(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        LVL.safeTransfer(_to, _amount);
        emit LVLWithdrawn(_to, _amount);
    }

    function withdrawPreLVL(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address");
        PRE_LVL.safeTransfer(_to, _amount);
        emit PreLVLWithdrawn(_to, _amount);
    }

    function setBatchDuration(uint64 _duration) external onlyOwner {
        require(_duration > 0, "Invalid batch duration");
        require(_duration <= MAX_BATCH_DURATION, "!MAX_BATCH_DURATION");
        batchDuration = _duration;
        emit BatchDurationSet(_duration);
    }

    function setVestingDuration(uint64 _duration) external onlyOwner {
        require(_duration <= MAX_VESTING_DURATION, "!MAX_VESTING_DURATION");
        vestingDuration = _duration;
        emit VestingDurationSet(_duration);
    }

    function setDaoStaking(address _daoStaking) external onlyOwner {
        require(_daoStaking != address(0), "Invalid address");
        daoStaking = IDaoStaking(_daoStaking);
        emit DaoStakingSet(_daoStaking);
    }

    function setLvlStaking(address _lvlStaking) external onlyOwner {
        require(_lvlStaking != address(0), "Invalid address");
        lvlStaking = IOmniStaking(_lvlStaking);
        emit LvlStakingSet(_lvlStaking);
    }

    function setEnableNextBatch(bool _enable) external {
        require(msg.sender == admin, "!Admin");
        enableNextBatch = _enable;
        emit EnableNextBatchSet(_enable);
    }

    function setUpdater(address _updater) external onlyOwner {
        require(_updater != address(0), "Invalid address");
        updater = _updater;
        emit UpdaterSet(_updater);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid address");
        admin = _admin;
        emit AdminSet(_admin);
    }

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "Invalid address");
        controller = _controller;
        emit ControllerSet(_controller);
    }

    /*================ INTERNAL =============== */

    function _nextBatch(uint64 _nextBatchTimestamp) internal {
        batches[currentBatch].endTime = _nextBatchTimestamp;
        emit BatchEnded(currentBatch);

        currentBatch++;
        batches[currentBatch].startTime = _nextBatchTimestamp;
        emit BatchStarted(currentBatch);
    }

    function _getRewardToken(uint64 _batchId) internal pure returns (IERC20) {
        return _batchId >= START_BATCH_USING_PRE_LVL ? PRE_LVL : LVL;
    }
    /*================ EVENTS ===================*/

    event LvlStakingSet(address _lvlStaking);
    event LvlOmniStakingSet(address _lvlOmniStaking);
    event DaoStakingSet(address _daoStaking);
    event BatchStarted(uint64 _currentBatch);
    event PoolHookSet(address _poolHook);
    event BatchDurationSet(uint64 _duration);
    event VestingDurationSet(uint64 _duration);
    event Finalized(uint64 _batchId);
    event RecordAdded(
        address _user, uint256 _value, uint256 _daoStaking, uint256 _lvlStaking, uint256 _point, uint64 _batchId
    );
    event EnableNextBatchSet(bool _enable);
    event Claimed(address _user, address _to, uint128 _batchId, uint256 _amount);
    event LVLWithdrawn(address _to, uint256 _amount);
    event LeaderUpdated(uint64 _batchId);
    event UpdaterSet(address _addr);
    event AdminSet(address _addr);
    event BatchEnded(uint64 _batchId);
    event RewardAdded(uint64 _batchId, uint256 _rewardTokens);
    event RewardIncreased(uint64 _batchId, uint256 _amount);
    event RewardDecreased(uint64 _batchId, uint256 _amount);
    event ControllerSet(address _controller);
    event PreLVLWithdrawn(address _to, uint256 _amount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

pragma solidity >=0.8.0;

interface IDaoStaking {
    function userInfo(address _user) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IOmniStaking {
    function stakedAmounts(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

struct BatchInfo {
    uint128 rewardTokens;
    uint64 startTime;
    uint64 endTime;
    uint64 startVestingTime;
    uint64 vestingDuration;
    uint128 totalWeight;
    bool leaderUpdated;
}

struct LeaderInfo {
    uint128 weight;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct LeaderInfoView {
    address trader;
    uint128 rewardTokens;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct ContestResult {
    address trader;
    uint8 index;
    uint256 totalPoint;
}

interface ITradingContest {
    function batchDuration() external returns (uint64);

    /**
     * @notice record trading point for trader
     * @param _user address of trader
     * @param _value fee collected in this trade
     */
    function record(address _user, uint256 _value) external;

    /**
     * @notice accept reward send from IncentiveController
     */
    function addReward(uint256 _rewardTokens) external;

    /**
     * @notice start a new batch and close current batch. Waiting for leaders to be set
     */
    function nextBatch() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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