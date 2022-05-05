// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IApeXPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../utils/Initializable.sol";
import "../utils/Ownable.sol";
import "./StakingPool.sol";
import "./interfaces/IERC20Extend.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

//this is a stakingPool factory to create and register stakingPool, distribute esApeX token according to pools' weight
contract StakingPoolFactory is IStakingPoolFactory, Ownable, Initializable {
    uint256 constant tenK = 10000;
    address public override apeX;
    address public override esApeX;
    address public override veApeX;
    address public override treasury;
    uint256 public override lastUpdateTimestamp;
    uint256 public override secSpanPerUpdate;
    uint256 public override apeXPerSec;
    uint256 public override totalWeight;
    uint256 public override endTimestamp;
    uint256 public override lockTime;
    uint256 public override minRemainRatioAfterBurn; //10k-based
    uint256 public override remainForOtherVest; //100-based, 50 means half of remain to other vest, half to treasury
    uint256 public priceOfWeight; //multiplied by 10k
    uint256 public lastTimeUpdatePriceOfWeight;
    address public override stakingPoolTemplate;

    mapping(address => address) public tokenPoolMap; //token->pool, only for relationships in use
    mapping(address => PoolWeight) public poolWeightMap; //pool->weight, historical pools are also stored

    function initialize(
        address _apeX,
        address _treasury,
        uint256 _apeXPerSec,
        uint256 _secSpanPerUpdate,
        uint256 _initTimestamp,
        uint256 _endTimestamp,
        uint256 _lockTime
    ) public initializer {
        require(_apeX != address(0), "spf.initialize: INVALID_APEX");
        require(_treasury != address(0), "spf.initialize: INVALID_TREASURY");
        require(_apeXPerSec > 0, "spf.initialize: INVALID_PER_SEC");
        require(_secSpanPerUpdate > 0, "spf.initialize: INVALID_UPDATE_SPAN");
        require(_initTimestamp > 0, "spf.initialize: INVALID_INIT_TIMESTAMP");
        require(_endTimestamp > _initTimestamp, "spf.initialize: INVALID_END_TIMESTAMP");
        require(_lockTime > 0, "spf.initialize: INVALID_LOCK_TIME");

        owner = msg.sender;
        apeX = _apeX;
        treasury = _treasury;
        apeXPerSec = _apeXPerSec;
        secSpanPerUpdate = _secSpanPerUpdate;
        lastUpdateTimestamp = _initTimestamp;
        endTimestamp = _endTimestamp;
        lockTime = _lockTime;
        lastTimeUpdatePriceOfWeight = _initTimestamp;
    }

    function setStakingPoolTemplate(address _template) external override onlyOwner {
        require(_template != address(0), "spf.setStakingPoolTemplate: ZERO_ADDRESS");

        emit SetStakingPoolTemplate(stakingPoolTemplate, _template);
        stakingPoolTemplate = _template;
    }

    function createPool(address _poolToken, uint256 _weight) external override onlyOwner {
        require(_poolToken != address(0), "spf.createPool: ZERO_ADDRESS");
        require(_poolToken != apeX, "spf.createPool: CANT_APEX");
        require(stakingPoolTemplate != address(0), "spf.createPool: ZERO_TEMPLATE");

        address pool = Clones.clone(stakingPoolTemplate);
        IStakingPool(pool).initialize(address(this), _poolToken);

        _registerPool(pool, _poolToken, _weight);
    }

    function registerApeXPool(address _pool, uint256 _weight) external override onlyOwner {
        address poolToken = IApeXPool(_pool).poolToken();
        require(poolToken == apeX, "spf.registerApeXPool: MUST_APEX");

        _registerPool(_pool, poolToken, _weight);
    }

    function unregisterPool(address _pool) external override onlyOwner {
        require(poolWeightMap[_pool].weight != 0, "spf.unregisterPool: POOL_NOT_REGISTERED");
        require(poolWeightMap[_pool].exitYieldPriceOfWeight == 0, "spf.unregisterPool: POOL_HAS_UNREGISTERED");

        priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
        lastTimeUpdatePriceOfWeight = block.timestamp;

        totalWeight -= poolWeightMap[_pool].weight;
        poolWeightMap[_pool].exitYieldPriceOfWeight = priceOfWeight;
        delete tokenPoolMap[IStakingPool(_pool).poolToken()];

        emit PoolUnRegistered(msg.sender, _pool);
    }

    function changePoolWeight(address _pool, uint256 _weight) external override onlyOwner {
        require(poolWeightMap[_pool].weight > 0, "spf.changePoolWeight: POOL_NOT_EXIST");
        require(poolWeightMap[_pool].exitYieldPriceOfWeight == 0, "spf.changePoolWeight: POOL_INVALID");
        require(_weight != 0, "spf.changePoolWeight: CANT_CHANGE_TO_ZERO_WEIGHT");

        if (totalWeight != 0) {
            priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
            lastTimeUpdatePriceOfWeight = block.timestamp;
        }

        totalWeight = totalWeight + _weight - poolWeightMap[_pool].weight;
        poolWeightMap[_pool].weight = _weight;
        poolWeightMap[_pool].lastYieldPriceOfWeight = priceOfWeight;

        emit WeightUpdated(msg.sender, _pool, _weight);
    }

    function updateApeXPerSec() external override {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate, "spf.updateApeXPerSec: TOO_FREQUENT");
        require(currentTimestamp <= endTimestamp, "spf.updateApeXPerSec: END");

        apeXPerSec = (apeXPerSec * 97) / 100;
        lastUpdateTimestamp = currentTimestamp;

        emit UpdateApeXPerSec(apeXPerSec);
    }

    function syncYieldPriceOfWeight() external override returns (uint256) {
        (uint256 reward, uint256 newPriceOfWeight) = _calStakingPoolApeXReward(msg.sender);
        emit SyncYieldPriceOfWeight(poolWeightMap[msg.sender].lastYieldPriceOfWeight, newPriceOfWeight);

        poolWeightMap[msg.sender].lastYieldPriceOfWeight = newPriceOfWeight;
        return reward;
    }

    function transferYieldTo(address _to, uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferYieldTo: ACCESS_DENIED");

        emit TransferYieldTo(msg.sender, _to, _amount);
        IERC20(apeX).transfer(_to, _amount);
    }

    function transferYieldToTreasury(uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferYieldToTreasury: ACCESS_DENIED");

        address _treasury = treasury;
        emit TransferYieldToTreasury(msg.sender, _treasury, _amount);
        IERC20(apeX).transfer(_treasury, _amount);
    }

    function withdrawApeX(address to, uint256 amount) external override onlyOwner {
        require(amount <= IERC20(apeX).balanceOf(address(this)), "spf.withdrawApeX: NO_ENOUGH_APEX");
        IERC20(apeX).transfer(to, amount);
        emit WithdrawApeX(to, amount);
    }

    function transferEsApeXTo(address _to, uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferEsApeXTo: ACCESS_DENIED");

        emit TransferEsApeXTo(msg.sender, _to, _amount);
        IERC20(esApeX).transfer(_to, _amount);
    }

    function transferEsApeXFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferEsApeXFrom: ACCESS_DENIED");

        emit TransferEsApeXFrom(_from, _to, _amount);
        IERC20(esApeX).transferFrom(_from, _to, _amount);
    }

    function burnEsApeX(address from, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.burnEsApeX: ACCESS_DENIED");
        IERC20Extend(esApeX).burn(from, amount);
    }

    function mintEsApeX(address to, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.mintEsApeX: ACCESS_DENIED");
        IERC20Extend(esApeX).mint(to, amount);
    }

    function burnVeApeX(address from, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.burnVeApeX: ACCESS_DENIED");
        IERC20Extend(veApeX).burn(from, amount);
    }

    function mintVeApeX(address to, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.mintVeApeX: ACCESS_DENIED");
        IERC20Extend(veApeX).mint(to, amount);
    }

    function calPendingFactoryReward() external view override returns (uint256 reward) {
        return _calPendingFactoryReward();
    }

    function calLatestPriceOfWeight() external view override returns (uint256) {
        return priceOfWeight + ((_calPendingFactoryReward() * tenK) / totalWeight);
    }

    function calStakingPoolApeXReward(address token)
        external
        view
        override
        returns (uint256 reward, uint256 newPriceOfWeight)
    {
        address pool = tokenPoolMap[token];
        return _calStakingPoolApeXReward(pool);
    }

    function shouldUpdateRatio() external view override returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return currentTimestamp > endTimestamp ? false : currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate;
    }

    function _registerPool(
        address _pool,
        address _poolToken,
        uint256 _weight
    ) internal {
        require(poolWeightMap[_pool].weight == 0, "spf.registerPool: POOL_REGISTERED");
        require(tokenPoolMap[_poolToken] == address(0), "spf.registerPool: POOL_TOKEN_REGISTERED");

        if (totalWeight != 0) {
            priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
            lastTimeUpdatePriceOfWeight = block.timestamp;
        }

        tokenPoolMap[_poolToken] = _pool;
        poolWeightMap[_pool] = PoolWeight({
            weight: _weight,
            lastYieldPriceOfWeight: priceOfWeight,
            exitYieldPriceOfWeight: 0
        });
        totalWeight += _weight;

        emit PoolRegistered(msg.sender, _poolToken, _pool, _weight);
    }

    function _calPendingFactoryReward() internal view returns (uint256 reward) {
        uint256 currentTimestamp = block.timestamp;
        uint256 secPassed = currentTimestamp > endTimestamp
            ? endTimestamp - lastTimeUpdatePriceOfWeight
            : currentTimestamp - lastTimeUpdatePriceOfWeight;
        reward = secPassed * apeXPerSec;
    }

    function _calStakingPoolApeXReward(address pool) internal view returns (uint256 reward, uint256 newPriceOfWeight) {
        require(pool != address(0), "spf._calStakingPoolApeXReward: INVALID_TOKEN");
        PoolWeight memory pw = poolWeightMap[pool];
        if (pw.exitYieldPriceOfWeight > 0) {
            newPriceOfWeight = pw.exitYieldPriceOfWeight;
            reward = (pw.weight * (pw.exitYieldPriceOfWeight - pw.lastYieldPriceOfWeight)) / tenK;
            return (reward, newPriceOfWeight);
        }
        newPriceOfWeight = priceOfWeight;
        if (totalWeight > 0) {
            newPriceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
        }

        reward = (pw.weight * (newPriceOfWeight - pw.lastYieldPriceOfWeight)) / tenK;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;

        emit SetYieldLockTime(_lockTime);
    }

    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external override onlyOwner {
        require(_minRemainRatioAfterBurn <= tenK, "spf.setMinRemainRatioAfterBurn: INVALID_VALUE");
        minRemainRatioAfterBurn = _minRemainRatioAfterBurn;

        emit SetMinRemainRatioAfterBurn(_minRemainRatioAfterBurn);
    }

    function setRemainForOtherVest(uint256 _remainForOtherVest) external override onlyOwner {
        require(_remainForOtherVest <= 100, "spf.setRemainForOtherVest: INVALID_VALUE");
        remainForOtherVest = _remainForOtherVest;

        emit SetRemainForOtherVest(_remainForOtherVest);
    }

    function setEsApeX(address _esApeX) external override onlyOwner {
        require(esApeX == address(0), "spf.setEsApeX: HAS_SET");
        esApeX = _esApeX;

        emit SetEsApeX(_esApeX);
    }

    function setVeApeX(address _veApeX) external override onlyOwner {
        require(veApeX == address(0), "spf.setVeApeX: HAS_SET");
        veApeX = _veApeX;

        emit SetVeApeX(_veApeX);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockDuration;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake slp/alp
    }

    event BatchWithdraw(address indexed by, uint256[] _depositIds, uint256[] _depositAmounts);

    event Staked(address indexed to, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, uint256 lockFrom, uint256 lockUntil);

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

    function initialize(address _factory, address _poolToken) external;

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake poolToken
    /// @param amount poolToken's amount to stake.
    /// @param _lockDuration time to lock.
    function stake(uint256 amount, uint256 _lockDuration) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(uint256[] memory depositIds, uint256[] memory depositAmounts) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockDuration`
    /// @param depositId the deposit index.
    /// @param _lockDuration new lock time.
    function updateStakeLock(uint256 depositId, uint256 _lockDuration) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";
import "../utils/Initializable.sol";

contract StakingPool is IStakingPool, Reentrant, Initializable {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_TIME_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public override poolToken;
    IStakingPoolFactory public factory;
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;

    function initialize(address _factory, address _poolToken) external override initializer {
        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
    }

    function stake(uint256 _amount, uint256 _lockDuration) external override nonReentrant {
        require(_amount > 0, "sp.stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        uint256 lockTime = factory.lockTime();
        require(
            _lockDuration == 0 || (_lockDuration > 0 && _lockDuration <= lockTime),
            "sp._stake: INVALID_LOCK_INTERVAL"
        );

        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        //if 0, not lock
        uint256 lockFrom = _lockDuration > 0 ? now256 : 0;
        uint256 stakeWeight = ((_lockDuration * WEIGHT_MULTIPLIER) / lockTime + WEIGHT_MULTIPLIER) * _amount;
        uint256 depositId = user.deposits.length;
        Deposit memory deposit = Deposit({
            amount: _amount,
            weight: stakeWeight,
            lockFrom: lockFrom,
            lockDuration: _lockDuration
        });

        user.deposits.push(deposit);
        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight += stakeWeight;

        emit Staked(_staker, depositId, _amount, lockFrom, lockFrom + _lockDuration);
        IERC20(poolToken).transferFrom(msg.sender, address(this), _amount);
    }

    function batchWithdraw(uint256[] memory depositIds, uint256[] memory depositAmounts) external override {
        require(depositIds.length == depositAmounts.length, "sp.batchWithdraw: INVALID_DEPOSITS_AMOUNTS");

        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);
        emit BatchWithdraw(msg.sender, depositIds, depositAmounts);
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
            require(_amount != 0, "sp.batchWithdraw: INVALID_DEPOSIT_AMOUNT");
            stakeDeposit = user.deposits[_id];
            require(
                stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockFrom + stakeDeposit.lockDuration,
                "sp.batchWithdraw: DEPOSIT_LOCKED"
            );
            require(stakeDeposit.amount >= _amount, "sp.batchWithdraw: EXCEED_DEPOSIT_STAKED");

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

        user.totalWeight -= deltaUsersLockingWeight;
        usersLockingWeight -= deltaUsersLockingWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        if (stakeAmount > 0) {
            user.tokenAmount -= stakeAmount;
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function updateStakeLock(uint256 _id, uint256 _lockDuration) external override {
        uint256 now256 = block.timestamp;
        require(_lockDuration > 0, "sp.updateStakeLock: INVALID_LOCK_DURATION");

        uint256 lockTime = factory.lockTime();
        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        Deposit storage stakeDeposit;

        stakeDeposit = user.deposits[_id];

        require(_lockDuration > stakeDeposit.lockDuration, "sp.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockDuration <= lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockDuration <= lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK");
        }

        uint256 oldWeight = stakeDeposit.weight;
        uint256 newWeight = ((_lockDuration * WEIGHT_MULTIPLIER) /
            lockTime +
            WEIGHT_MULTIPLIER) * stakeDeposit.amount;

        stakeDeposit.lockDuration = _lockDuration;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - oldWeight + newWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight = usersLockingWeight - oldWeight + newWeight;

        emit UpdateStakeLock(_staker, _id, stakeDeposit.lockFrom, stakeDeposit.lockFrom + _lockDuration);
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

    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.totalWeight == 0) return;
        uint256 yieldAmount = (user.totalWeight * yieldRewardsPerWeight) /
            REWARD_PER_WEIGHT_MULTIPLIER -
            user.subYieldRewards;
        if (yieldAmount == 0) return;

        factory.mintEsApeX(_staker, yieldAmount);
        emit MintEsApeX(_staker, yieldAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (usersLockingWeight != 0) {
            (uint256 apeXReward, ) = factory.calStakingPoolApeXReward(poolToken);
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../core/interfaces/IERC20.sol";

interface IERC20Extend is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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