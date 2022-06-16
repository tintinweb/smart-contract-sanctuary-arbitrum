// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IApeXPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../interfaces/IERC20.sol";
import "../utils/Reentrant.sol";

contract ApeXPool is IApeXPool, Reentrant {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_TIME_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public immutable override poolToken;
    IStakingPoolFactory public immutable factory;
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;
    uint256 public immutable initTime;
    uint256 public immutable endTime;

    modifier onlyInTimePeriod () {
        require(initTime <= block.timestamp && block.timestamp <= endTime, "sp: ONLY_IN_TIME_PERIOD");
        _;
    }

    constructor(address _factory, address _poolToken, uint256 _initTime, uint256 _endTime) {
        require(_factory != address(0), "ap: INVALID_FACTORY");
        require(_poolToken != address(0), "ap: INVALID_POOL_TOKEN");

        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
        initTime = _initTime;
        endTime = _endTime;
    }

    function stake(uint256 _amount, uint256 _lockDuration) external override nonReentrant onlyInTimePeriod {
        _stake(_amount, _lockDuration, false);
        IERC20(poolToken).transferFrom(msg.sender, address(this), _amount);
    }

    function stakeEsApeX(uint256 _amount, uint256 _lockDuration) external override {
        _stake(_amount, _lockDuration, true);
        factory.transferEsApeXFrom(msg.sender, address(factory), _amount);
    }

    function _stake(
        uint256 _amount,
        uint256 _lockDuration,
        bool _isEsApeX
    ) internal {
        require(_amount > 0, "ap.stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        uint256 lockTime = factory.lockTime();
        require(
            _lockDuration == 0 || (_lockDuration > 0 && _lockDuration <= lockTime),
            "ap._stake: INVALID_LOCK_INTERVAL"
        );

        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        //if 0, not lock
        uint256 lockFrom = _lockDuration > 0 ? now256 : 0;
        uint256 stakeWeight = ((_lockDuration * WEIGHT_MULTIPLIER) / lockTime + WEIGHT_MULTIPLIER) * _amount;
        uint256 depositId = user.deposits.length;
        Deposit memory deposit = Deposit({
        amount : _amount,
        weight : stakeWeight,
        lockFrom : lockFrom,
        lockDuration : _lockDuration
        });

        if (_isEsApeX) {
            user.esDeposits.push(deposit);
        } else {
            user.deposits.push(deposit);
        }

        factory.mintVeApeX(_staker, stakeWeight / WEIGHT_MULTIPLIER);
        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight += stakeWeight;

        emit Staked(_staker, depositId, _isEsApeX, _amount, lockFrom, lockFrom + _lockDuration);
    }

    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts,
        uint256[] memory esDepositIds,
        uint256[] memory esDepositAmounts
    ) external override {
        require(depositIds.length == depositAmounts.length, "ap.batchWithdraw: INVALID_DEPOSITS_AMOUNTS");
        require(yieldIds.length == yieldAmounts.length, "ap.batchWithdraw: INVALID_YIELDS_AMOUNTS");
        require(esDepositIds.length == esDepositAmounts.length, "ap.batchWithdraw: INVALID_ESDEPOSITS_AMOUNTS");

        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);
        emit BatchWithdraw(
            msg.sender,
            depositIds,
            depositAmounts,
            yieldIds,
            yieldAmounts,
            esDepositIds,
            esDepositAmounts
        );
        uint256 lockTime = factory.lockTime();

        uint256 _amount;
        uint256 _id;
        uint256 stakeAmount;
        uint256 newWeight;
        uint256 deltaUsersLockingWeight;
        Deposit memory stakeDeposit;
        for (uint256 i = 0; i < depositIds.length; i++) {
            _amount = depositAmounts[i];
            _id = depositIds[i];
            require(_amount != 0, "ap.batchWithdraw: INVALID_DEPOSIT_AMOUNT");
            stakeDeposit = user.deposits[_id];
            require(
                stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockFrom + stakeDeposit.lockDuration,
                "ap.batchWithdraw: DEPOSIT_LOCKED"
            );
            require(stakeDeposit.amount >= _amount, "ap.batchWithdraw: EXCEED_DEPOSIT_STAKED");

            newWeight =
            ((stakeDeposit.lockDuration * WEIGHT_MULTIPLIER) /
            lockTime +
            WEIGHT_MULTIPLIER) *
            (stakeDeposit.amount - _amount);

            stakeAmount += _amount;
            deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

            if (stakeDeposit.amount == _amount) {
                delete user.deposits[_id];
            } else {
                stakeDeposit.amount -= _amount;
                stakeDeposit.weight = newWeight;
                user.deposits[_id] = stakeDeposit;
            }
        }
        {
            uint256 esStakeAmount;
            for (uint256 i = 0; i < esDepositIds.length; i++) {
                _amount = esDepositAmounts[i];
                _id = esDepositIds[i];
                require(_amount != 0, "ap.batchWithdraw: INVALID_ESDEPOSIT_AMOUNT");
                stakeDeposit = user.esDeposits[_id];
                require(
                    stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockFrom + stakeDeposit.lockDuration,
                    "ap.batchWithdraw: ESDEPOSIT_LOCKED"
                );
                require(stakeDeposit.amount >= _amount, "ap.batchWithdraw: EXCEED_ESDEPOSIT_STAKED");

                newWeight =
                ((stakeDeposit.lockDuration * WEIGHT_MULTIPLIER) /
                lockTime +
                WEIGHT_MULTIPLIER) *
                (stakeDeposit.amount - _amount);

                esStakeAmount += _amount;
                deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

                if (stakeDeposit.amount == _amount) {
                    delete user.esDeposits[_id];
                } else {
                    stakeDeposit.amount -= _amount;
                    stakeDeposit.weight = newWeight;
                    user.esDeposits[_id] = stakeDeposit;
                }
            }
            if (esStakeAmount > 0) {
                user.tokenAmount -= esStakeAmount;
                factory.transferEsApeXTo(msg.sender, esStakeAmount);
            }
        }

        factory.burnVeApeX(msg.sender, deltaUsersLockingWeight / WEIGHT_MULTIPLIER);
        user.totalWeight -= deltaUsersLockingWeight;
        usersLockingWeight -= deltaUsersLockingWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        {
            uint256 yieldAmount;
            Yield memory stakeYield;
            for (uint256 i = 0; i < yieldIds.length; i++) {
                _amount = yieldAmounts[i];
                _id = yieldIds[i];
                require(_amount != 0, "ap.batchWithdraw: INVALID_YIELD_AMOUNT");
                stakeYield = user.yields[_id];
                require(block.timestamp > stakeYield.lockUntil, "ap.batchWithdraw: YIELD_LOCKED");
                require(stakeYield.amount >= _amount, "ap.batchWithdraw: EXCEED_YIELD_STAKED");

                yieldAmount += _amount;

                if (stakeYield.amount == _amount) {
                    delete user.yields[_id];
                } else {
                    stakeYield.amount -= _amount;
                    user.yields[_id] = stakeYield;
                }
            }

            if (yieldAmount > 0) {
                user.tokenAmount -= yieldAmount;
                factory.transferYieldTo(msg.sender, yieldAmount);
            }
        }

        if (stakeAmount > 0) {
            user.tokenAmount -= stakeAmount;
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function forceWithdraw(uint256[] memory _yieldIds) external override {
        uint256 minRemainRatio = factory.minRemainRatioAfterBurn();
        address _staker = msg.sender;
        uint256 now256 = block.timestamp;

        User storage user = users[_staker];

        uint256 deltaTotalAmount;
        uint256 yieldAmount;

        //force withdraw vesting or vested rewards
        Yield memory yield;
        for (uint256 i = 0; i < _yieldIds.length; i++) {
            yield = user.yields[_yieldIds[i]];
            deltaTotalAmount += yield.amount;

            if (now256 >= yield.lockUntil) {
                yieldAmount += yield.amount;
            } else {
                yieldAmount +=
                (yield.amount *
                (minRemainRatio +
                ((10000 - minRemainRatio) * (now256 - yield.lockFrom)) /
                factory.lockTime())) /
                10000;
            }
            delete user.yields[_yieldIds[i]];
        }

        uint256 remainApeX = deltaTotalAmount - yieldAmount;

        //half of remaining esApeX to boost remain vester
        uint256 remainForOtherVest = factory.remainForOtherVest();
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight +
        ((remainApeX * REWARD_PER_WEIGHT_MULTIPLIER) * remainForOtherVest) /
        100 /
        usersLockingWeight;
        yieldRewardsPerWeight = newYieldRewardsPerWeight;

        //half of remaining esApeX to transfer to treasury in apeX
        factory.transferYieldToTreasury(remainApeX - (remainApeX * remainForOtherVest) / 100);

        user.tokenAmount -= deltaTotalAmount;
        factory.burnEsApeX(address(this), deltaTotalAmount);
        if (yieldAmount > 0) {
            factory.transferYieldTo(_staker, yieldAmount);
        }

        emit ForceWithdraw(_staker, _yieldIds);
    }

    //only can extend lock time
    function updateStakeLock(
        uint256 _id,
        uint256 _lockDuration,
        bool _isEsApeX
    ) external override {
        uint256 now256 = block.timestamp;
        require(_lockDuration > 0, "ap.updateStakeLock: INVALID_LOCK_DURATION");

        uint256 lockTime = factory.lockTime();
        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        Deposit storage stakeDeposit;
        if (_isEsApeX) {
            stakeDeposit = user.esDeposits[_id];
        } else {
            stakeDeposit = user.deposits[_id];
        }
        require(_lockDuration > stakeDeposit.lockDuration, "ap.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockDuration <= lockTime, "ap.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockDuration <= lockTime, "ap.updateStakeLock: EXCEED_MAX_LOCK");
        }

        uint256 oldWeight = stakeDeposit.weight;
        uint256 newWeight = ((_lockDuration * WEIGHT_MULTIPLIER) /
        lockTime +
        WEIGHT_MULTIPLIER) * stakeDeposit.amount;

        factory.mintVeApeX(_staker, (newWeight - oldWeight) / WEIGHT_MULTIPLIER);
        stakeDeposit.lockDuration = _lockDuration;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - oldWeight + newWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight = usersLockingWeight - oldWeight + newWeight;

        emit UpdateStakeLock(_staker, _id, _isEsApeX, stakeDeposit.lockFrom, stakeDeposit.lockFrom + _lockDuration);
    }

    function processRewards() external override {
        address staker = msg.sender;
        User storage user = users[staker];

        _processRewards(staker, user);
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApeXPerSec();
        }

        uint256 apeXReward = factory.syncYieldPriceOfWeight();
        if (usersLockingWeight == 0) {
            return;
        }
        yieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        emit Synchronized(msg.sender, yieldRewardsPerWeight);
    }

    //update weight price, then if apeX, add deposits; if not, stake as pool.
    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.totalWeight == 0) return;
        uint256 yieldAmount = (user.totalWeight * yieldRewardsPerWeight) /
        REWARD_PER_WEIGHT_MULTIPLIER -
        user.subYieldRewards;
        if (yieldAmount == 0) return;

        //mint esApeX to _staker
        factory.mintEsApeX(_staker, yieldAmount);
        emit MintEsApeX(_staker, yieldAmount);
    }

    function vest(uint256 vestAmount) external override {
        User storage user = users[msg.sender];

        uint256 now256 = block.timestamp;
        uint256 lockUntil = now256 + factory.lockTime();
        emit YieldClaimed(msg.sender, user.yields.length, vestAmount, now256, lockUntil);

        user.yields.push(Yield({amount : vestAmount, lockFrom : now256, lockUntil : lockUntil}));
        user.tokenAmount += vestAmount;

        factory.transferEsApeXFrom(msg.sender, address(this), vestAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (usersLockingWeight != 0) {
            (uint256 apeXReward,) = factory.calStakingPoolApeXReward(poolToken);
            newYieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        }

        User memory user = users[_staker];
        pending = (user.totalWeight * newYieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER - user.subYieldRewards;
    }

    function getStakeInfo(address _user)
    external
    view
    override
    returns (
        uint256 tokenAmount,
        uint256 totalWeight,
        uint256 subYieldRewards
    )
    {
        User memory user = users[_user];
        return (user.tokenAmount, user.totalWeight, user.subYieldRewards);
    }

    function getDeposit(address _user, uint256 _id) external view override returns (Deposit memory) {
        return users[_user].deposits[_id];
    }

    function getDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].deposits.length;
    }

    function getYield(address _user, uint256 _yieldId) external view override returns (Yield memory) {
        return users[_user].yields[_yieldId];
    }

    function getYieldsLength(address _user) external view override returns (uint256) {
        return users[_user].yields.length;
    }

    function getEsDeposit(address _user, uint256 _id) external view override returns (Deposit memory) {
        return users[_user].esDeposits[_id];
    }

    function getEsDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].esDeposits.length;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IApeXPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockDuration;
    }

    struct Yield {
        uint256 amount;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake ApeX
        Yield[] yields; //vest esApeX
        Deposit[] esDeposits; //stake esApeX
    }

    event BatchWithdraw(
        address indexed by,
        uint256[] _depositIds,
        uint256[] _depositAmounts,
        uint256[] _yieldIds,
        uint256[] _yieldAmounts,
        uint256[] _esDepositIds,
        uint256[] _esDepositAmounts
    );

    event ForceWithdraw(address indexed by, uint256[] yieldIds);

    event Staked(
        address indexed to,
        uint256 depositId,
        bool isEsApeX,
        uint256 amount,
        uint256 lockFrom,
        uint256 lockUntil
    );

    event YieldClaimed(address indexed by, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, bool isEsApeX, uint256 lockFrom, uint256 lockUntil);

    event MintEsApeX(address to, uint256 amount);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    function getStakeInfo(address _user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        );

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function getYield(address _user, uint256 _yieldId) external view returns (Yield memory);

    function getYieldsLength(address _user) external view returns (uint256);

    function getEsDeposit(address _user, uint256 _esDepositId) external view returns (Deposit memory);

    function getEsDepositsLength(address _user) external view returns (uint256);

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake apeX
    /// @param amount apeX's amount to stake.
    /// @param _lockDuration time to lock.
    function stake(uint256 amount, uint256 _lockDuration) external;

    function stakeEsApeX(uint256 amount, uint256 _lockDuration) external;

    function vest(uint256 amount) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts,
        uint256[] memory esDepositIds,
        uint256[] memory esDepositAmounts
    ) external;

    /// @notice force withdraw locked reward
    /// @param depositIds the deposit index of locked reward.
    function forceWithdraw(uint256[] memory depositIds) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockDuration`
    /// @param depositId the deposit index.
    /// @param lockDuration new lock duration.
    /// @param isEsApeX update esApeX or apeX stake.
    function updateStakeLock(
        uint256 depositId,
        uint256 lockDuration,
        bool isEsApeX
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPoolFactory {
    
    struct PoolWeight {
        uint256 weight;
        uint256 lastYieldPriceOfWeight; //multiplied by 10000
        uint256 exitYieldPriceOfWeight;
    }

    event WeightUpdated(address indexed by, address indexed pool, uint256 weight);

    event PoolRegistered(address indexed by, address indexed poolToken, address indexed pool, uint256 weight);

    event PoolUnRegistered(address indexed by, address indexed pool);

    event SetYieldLockTime(uint256 yieldLockTime);

    event UpdateApeXPerSec(uint256 apeXPerSec);

    event TransferYieldTo(address by, address to, uint256 amount);

    event TransferYieldToTreasury(address by, address to, uint256 amount);

    event TransferEsApeXTo(address by, address to, uint256 amount);

    event TransferEsApeXFrom(address from, address to, uint256 amount);

    event SetEsApeX(address esApeX);

    event SetVeApeX(address veApeX);

    event SetStakingPoolTemplate(address oldTemplate, address newTemplate);

    event SyncYieldPriceOfWeight(uint256 oldYieldPriceOfWeight, uint256 newYieldPriceOfWeight);

    event WithdrawApeX(address to, uint256 amount);

    event SetRemainForOtherVest(uint256);

    event SetMinRemainRatioAfterBurn(uint256);

    function apeX() external view returns (address);

    function esApeX() external view returns (address);

    function veApeX() external view returns (address);

    function treasury() external view returns (address);

    function lastUpdateTimestamp() external view returns (uint256);

    function secSpanPerUpdate() external view returns (uint256);

    function apeXPerSec() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function stakingPoolTemplate() external view returns (address);

    /// @notice get the end timestamp to yield, after this, no yield reward
    function endTimestamp() external view returns (uint256);

    function lockTime() external view returns (uint256);

    /// @notice get minimum remain ratio after force withdraw
    function minRemainRatioAfterBurn() external view returns (uint256);

    function remainForOtherVest() external view returns (uint256);

    /// @notice check if can update reward ratio
    function shouldUpdateRatio() external view returns (bool);

    /// @notice calculate yield reward of poolToken since lastYieldPriceOfWeight
    function calStakingPoolApeXReward(address token) external view returns (uint256 reward, uint256 newPriceOfWeight);

    function calPendingFactoryReward() external view returns (uint256 reward);

    function calLatestPriceOfWeight() external view returns (uint256);

    function syncYieldPriceOfWeight() external returns (uint256 reward);

    /// @notice update yield reward rate
    function updateApeXPerSec() external;

    function setStakingPoolTemplate(address _template) external;

    /// @notice create a new stakingPool
    /// @param poolToken stakingPool staked token.
    /// @param weight new pool's weight between all other stakingPools.
    function createPool(address poolToken, uint256 weight) external;

    /// @notice register apeX pool to factory
    /// @param pool the exist pool.
    /// @param weight pool's weight between all other stakingPools.
    function registerApeXPool(address pool, uint256 weight) external;

    /// @notice unregister an exist pool
    function unregisterPool(address pool) external;

    /// @notice mint apex to staker
    /// @param to the staker.
    /// @param amount apex amount.
    function transferYieldTo(address to, uint256 amount) external;

    function transferYieldToTreasury(uint256 amount) external;

    function withdrawApeX(address to, uint256 amount) external;

    /// @notice change a pool's weight
    /// @param poolAddr the pool.
    /// @param weight new weight.
    function changePoolWeight(address poolAddr, uint256 weight) external;

    /// @notice set minimum reward ratio when force withdraw locked rewards
    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external;

    function setRemainForOtherVest(uint256 _remainForOtherVest) external;

    function mintEsApeX(address to, uint256 amount) external;

    function burnEsApeX(address from, uint256 amount) external;

    function transferEsApeXTo(address to, uint256 amount) external;

    function transferEsApeXFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function mintVeApeX(address to, uint256 amount) external;

    function burnVeApeX(address from, uint256 amount) external;

    function setEsApeX(address _esApeX) external;

    function setVeApeX(address _veApeX) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}