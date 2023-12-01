// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ====================== IncentivizerAmoV2 ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance
// This Contract will be used for STIP Grant distribution 
// Whats new? tier based incentive calculation model  

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Dennis: https://github.com/denett

import "./interfaces/IFrax.sol";
import "./interfaces/IFxs.sol";
import "./interfaces/IIncentivizationHandler.sol";
import "./Uniswap/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IncentivizerAmoV2 is Ownable {
/* ============================================= STATE VARIABLES ==================================================== */

    // Addresses Config
    address public operatorAddress;
    address public targetTokenAddress; // Token that AMO incentivize
    address public incentiveTokenAddress; // Token that AMO uses as an incentive

    // Pools related
    address[] public poolArray; // List of pool addresses
    struct LiquidityPool {
        // Pool Addresses
        address poolAddress; // Where the actual tokens are in the pool
        address lpTokenAddress; // Pool LP token address
        address incentivePoolAddress; // Contract that handle incentive distribution e.g. Bribe contract
        address incentivizationHandlerAddress; // Incentive handler contract e.g. votemarket handler
        address gaugeAddress; // Gauge address
        uint256 incentivizationId; // Votemarket Bounty ID
        bool isPaused;
        uint lastIncentivizationTimestamp; // timestamp of last time this pool was incentivized
        uint lastIncentivizationAmount; // Max amount of incentives
        uint firstIncentivizationTimestamp; // timestamp of the first incentivization
        uint poolCycleLength; // length of the cycle for this pool in sec (e.g. one week)
    }
    mapping(address => bool) public poolInitialized;
    mapping(address => LiquidityPool) private poolInfo;

    // Constant Incentivization can be set (e.g. DAO Deal)
    mapping(address => bool) public poolHasFixedIncent; 
    mapping(address => uint256) public poolFixedIncentAmount; // Constant Incentivization amount

    // Pool tiers  
    struct IncentiveTier {
        uint256 tokenMaxBudgetPerUnit; // Max incentive per unit of target token per cycle for pools within this tier
        uint256 kickstartPeriodLength; // Kickstart period length for pools within this tier in secs
        uint256 kickstartPeriodBudget; // Kickstart period budget per cycle for pools within this tier 
    }
    IncentiveTier[] public tierArray;
    mapping(address => uint) public poolTier;

    // Configurations
    uint256 public minTvl; // Min TVL of pool for being considered for incentivization
    uint256 public cycleStart; // timestamp of cycle start
    uint256 public cycleLength; // length of the cycle in sec (e.g. one week)

/* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param _operatorAddress Address of AMO Operator
    /// @param _targetTokenAddress Address of Token that AMO incentivize (e.g. crvFRAX)
    /// @param _incentiveTokenAddress Address of Token that AMO uses as an incentive (e.g. FXS)
    /// @param _minTvl Min TVL of pool for being considered for incentivization
    /// @param _cycleStart timestamp of cycle start
    /// @param _cycleLength length of the cycle (e.g. one week)
    constructor(
        address _operatorAddress,
        address _targetTokenAddress,
        address _incentiveTokenAddress,
        uint256 _minTvl,
        uint256 _cycleStart,
        uint256 _cycleLength
    ) Ownable() {
        operatorAddress = _operatorAddress;
        targetTokenAddress = _targetTokenAddress;
        incentiveTokenAddress = _incentiveTokenAddress;
        minTvl = _minTvl;
        require(_cycleStart < block.timestamp, "Cycle start time error");
        cycleStart = _cycleStart;
        cycleLength = _cycleLength;
        addTier(0, 0, 0);
        emit StartAMO(_operatorAddress, _targetTokenAddress, _incentiveTokenAddress);
    }

/* ================================================ MODIFIERS ======================================================= */

    modifier onlyByOwnerOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not owner or operator");
        _;
    }

    modifier activePool(address _poolAddress) {
        require(poolInitialized[_poolAddress] && !poolInfo[_poolAddress].isPaused, "Pool is not active");
        require(showPoolTvl(_poolAddress) > minTvl, "Pool is small");
        _;
    }

/* ================================================= EVENTS ========================================================= */

    /// @notice The ```StartAMO``` event fires when the AMO deploys
    /// @param _operatorAddress Address of operator
    /// @param _targetTokenAddress Address of Token that AMO incentivize (e.g. crvFRAX)
    /// @param _incentiveTokenAddress Address of Token that AMO uses as an incentive (e.g. FXS)
    event StartAMO(address _operatorAddress, address _targetTokenAddress, address _incentiveTokenAddress);

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress);

    /// @notice The ```AddOrSetPool``` event fires when a pool is added or modified
    /// @param _poolAddress The pool address
    /// @param _lpTokenAddress The pool LP token address
    /// @param _gaugeAddress The gauge address
    /// @param _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @param _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @param _indexId indexID in Votium or Votemarket
    /// @param _poolCycleLength length of the cycle for this pool in sec (e.g. one week)
    event AddOrSetPool(
        address _poolAddress,
        address _lpTokenAddress,
        address _gaugeAddress,
        address _incentivePoolAddress,
        address _incentivizationHandlerAddress,
        uint256 _indexId,
        uint256 _poolCycleLength
    );

    /// @notice The ```AddOrSetTier``` event fires when a pool is added or modified
    /// @param _tierId Index of the incentivization tier
    /// @param _tokenMaxBudgetPerUnit  Max incentive per unit of target token per cycle for pools within this tier
    /// @param _kickstartPeriodLength Kickstart period length for pools within this tier in sec
    /// @param _kickstartPeriodBudget Kickstart period budget per cycle for pools within this tier
    event AddOrSetTier(uint256 _tierId,uint256 _tokenMaxBudgetPerUnit,uint256 _kickstartPeriodLength,uint256 _kickstartPeriodBudget);

    /// @notice The ```ChangePauseStatusPool``` event fires when a pool is added or modified
    /// @param _poolAddress The pool address
    /// @param _isPaused Pool Pause Status
    event ChangePauseStatusPool(address _poolAddress, bool _isPaused);

    /// @notice The ```SetPoolFixedIncent``` event fires when a pool's constant incentivization is updated 
    /// @param _poolAddress The pool address
    /// @param _hasFixedIncent Pool Deal Status
    /// @param _amountPerCycle Pool Deal Amount
    event SetPoolFixedIncent(address _poolAddress, bool _hasFixedIncent, uint256 _amountPerCycle);

    /// @notice The ```SetPoolTier``` event fires when a pool's incentivization tier change
    /// @param _poolAddress The pool address
    /// @param _tierId Index of the incentivization tier
    event SetPoolTier(address _poolAddress, uint256 _tierId);

    /// @notice The ```IncentivizePool``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _amount Incentive amount
    event IncentivizePool(address _poolAddress, uint256 _amount);

/* ================================================== VIEWS ========================================================= */

    /// @notice Returns the total number of pools added
    /// @return _length uint256 Number of pools added
    function allPoolsLength() public view returns (uint256 _length) {
        return poolArray.length;
    }

    /// @notice Returns the total number of tiers added
    /// @return _length uint256 Number of tiers added
    function allTiersLength() public view returns (uint256 _length) {
        return tierArray.length;
    }
    
    /// @notice Show TVL of targeted token in all active pools
    /// @return TVL of targeted token in all active pools
    function showActivePoolsTvl() public view returns (uint256) {
        uint tvl = 0;
        for (uint i = 0; i < poolArray.length; i++) {
            if (!poolInfo[poolArray[i]].isPaused) {
                tvl += showPoolTvl(poolArray[i]);
            }
        }
        return tvl;
    }

    /// @notice Show TVL of targeted token in liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @return TVL of targeted token in liquidity pool
    function showPoolTvl(address _poolAddress) public view returns (uint256) {
        ERC20 targetToken = ERC20(targetTokenAddress);
        return targetToken.balanceOf(_poolAddress);
    }

    /// @notice Show Pool parameters
    /// @param _poolAddress Address of liquidity pool
    /// @return _gaugeAddress Gauge Contract Address
    /// @return _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @return _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @return _incentivizationId Pool General Incentivization ID (e.g. in Votemarket it is BountyID)
    /// @return _poolCycleLength length of the cycle for this pool in sec (e.g. one week)
    function showPoolInfo(
        address _poolAddress
    )
        external
        view
        returns (
            address _gaugeAddress,
            address _incentivePoolAddress,
            address _incentivizationHandlerAddress,
            uint256 _incentivizationId,
            uint256 _poolCycleLength
        )
    {
        _incentivePoolAddress = poolInfo[_poolAddress].incentivePoolAddress;
        _incentivizationHandlerAddress = poolInfo[_poolAddress].incentivizationHandlerAddress;
        _gaugeAddress = poolInfo[_poolAddress].gaugeAddress;
        _incentivizationId = poolInfo[_poolAddress].incentivizationId;
        _poolCycleLength = poolInfo[_poolAddress].poolCycleLength;
    }

    /// @notice Show Pool status
    /// @param _poolAddress Address of liquidity pool
    /// @return _isInitialized Pool registered or not
    /// @return _lastIncentivizationTimestamp timestamp of last time this pool was incentivized
    /// @return _lastIncentivizationAmount last cycle incentive amount
    /// @return _isPaused puased or not
    function showPoolStatus(
        address _poolAddress
    )
        external
        view
        returns (
            bool _isInitialized,
            uint _lastIncentivizationTimestamp,
            uint _lastIncentivizationAmount,
            bool _isPaused
        )
    {
        _isInitialized = poolInitialized[_poolAddress];
        _lastIncentivizationTimestamp = poolInfo[_poolAddress].lastIncentivizationTimestamp;
        _lastIncentivizationAmount = poolInfo[_poolAddress].lastIncentivizationAmount;
        _isPaused = poolInfo[_poolAddress].isPaused;
    }

    /// @notice Show Tier Info
    /// @param _tierId Tier Index
    /// @return _tokenMaxBudgetPerUnit  Max incentive per unit of target token per cycle for pools within this tier
    /// @return _kickstartPeriodLength Kickstart period length for pools within this tier in secs
    /// @return _kickstartPeriodBudget Kickstart period budget per cycle for pools within this tier 
    /// @return _numberOfPools Number of pools in this tier
    function showTierInfo(
        uint256 _tierId
    )
        external
        view
        returns (
            uint256 _tokenMaxBudgetPerUnit,
            uint256 _kickstartPeriodLength,
            uint256 _kickstartPeriodBudget,
            uint256 _numberOfPools 
        )
    {
        _tokenMaxBudgetPerUnit = tierArray[_tierId].tokenMaxBudgetPerUnit;
        _kickstartPeriodLength = tierArray[_tierId].kickstartPeriodLength;
        _kickstartPeriodBudget = tierArray[_tierId].kickstartPeriodBudget;
        uint numberOfPools = 0;
        for (uint i = 0; i < poolArray.length; i++) {
            if (!poolInfo[poolArray[i]].isPaused) {
                if (poolTier[poolArray[i]] == _tierId) {
                    numberOfPools += 1;
                }
            }
        }
        _numberOfPools = numberOfPools;
    }

    /// @notice Show Pool Kickstart Period status
    /// @param _poolAddress Address of liquidity pool
    /// @return _isInKickstartPeriod Pool registered or not
    function isPoolInKickstartPeriod(
        address _poolAddress
    )
        public
        view
        returns (
            bool _isInKickstartPeriod
        )
    {
        if (poolInfo[_poolAddress].firstIncentivizationTimestamp == 0){
            _isInKickstartPeriod = true;
        } else {
            uint256 tier = poolTier[_poolAddress];
            uint256 firstIncentiveCycleBegin = cycleStart + (((poolInfo[_poolAddress].firstIncentivizationTimestamp - cycleStart) / cycleLength) * cycleLength);
            uint256 delta = (block.timestamp - firstIncentiveCycleBegin);
            if (delta > tierArray[tier].kickstartPeriodLength) {
                _isInKickstartPeriod = false;
            } else {
                _isInKickstartPeriod = true;
            }
        }
    }

    /// @notice Show if Pool incentivized within the current cycle 
    /// @param _poolAddress Address of liquidity pool
    /// @return _isIncentivized Pool incentivized or not
    function isPoolIncentivizedAtCycle(
        address _poolAddress
    )
        public
        view
        returns (
            bool _isIncentivized
        )
    {
        if (poolInfo[_poolAddress].lastIncentivizationTimestamp == 0) {
            _isIncentivized = false;
        } else {
            uint256 currentCycle = ((block.timestamp - cycleStart) / poolInfo[_poolAddress].poolCycleLength) + 1;
            uint256 lastIncentiveCycle = ((poolInfo[_poolAddress].lastIncentivizationTimestamp - cycleStart) / poolInfo[_poolAddress].poolCycleLength) + 1;
            if (lastIncentiveCycle < currentCycle){
                _isIncentivized = false;
            } else {
                _isIncentivized = true;
            }
        }
        
    }

    /// @notice Function to calculate max incentive budget for one pool (based on tier budgets)
    /// @param _poolAddress Address of liquidity pool
    /// @return _amount max incentive budget for the pool in target token
    function maxBudgetForPoolByTier(address _poolAddress) public view returns (uint256 _amount) {
        uint256 _poolTvl = showPoolTvl(_poolAddress);
        uint256 _tierId = poolTier[_poolAddress];
        uint256 _cycleRatio = (poolInfo[_poolAddress].poolCycleLength * 100_000) / cycleLength ;
        uint256 _kickstartPeriodBudget = 0;
        uint256 _maxUintBasedBudget = (tierArray[_tierId].tokenMaxBudgetPerUnit * _poolTvl) / (10 ** ERC20(targetTokenAddress).decimals());
        if(isPoolInKickstartPeriod(_poolAddress)){
            _kickstartPeriodBudget = tierArray[_tierId].kickstartPeriodBudget;
        }
        if(isPoolIncentivizedAtCycle(_poolAddress)) {
            _amount = 0;
        } else if(_kickstartPeriodBudget > _maxUintBasedBudget) {
            _amount = _kickstartPeriodBudget * _cycleRatio / 100_000;
        } else {
            _amount = _maxUintBasedBudget * _cycleRatio / 100_000;
        }        
    }

    /// @notice Function to calculate max incentive budget for all pools (based on tier budgets)
    /// @return _totalMaxBudget max incentive budget for all pools in target token
    function maxBudgetForAllPoolsByTier() public view returns (uint256 _totalMaxBudget) {
        _totalMaxBudget = 0;
        for (uint256 i = 0; i < poolArray.length; i++) {
            _totalMaxBudget += maxBudgetForPoolByTier(poolArray[i]);
        }
    }

    /// @notice Function to calculate adjusted incentive budget for one pool (based on tier budgets)
    /// @param _poolAddress Address of liquidity pool
    /// @param _totalIncentAmount Total Incentive budget in incetive token
    /// @param _totalMaxIncentiveAmount Total max Incentive budget in target token
    /// @param _priceRatio (Target Token Price / Incentive Token Price) * 100_000
    /// @return _amount adjusted incentive budget for one pool in incentive token 
    function adjustedBudgetForPoolByTier(address _poolAddress, uint256 _totalIncentAmount, uint256 _totalMaxIncentiveAmount, uint256 _priceRatio) public view returns (uint256 _amount) {
        uint256 _poolMaxBudget = maxBudgetForPoolByTier(_poolAddress) * _priceRatio / 100_000;
        uint256 _totalMaxIncentive = _totalMaxIncentiveAmount * _priceRatio / 100_000;
        if (_totalIncentAmount > _totalMaxIncentive) {
            _amount = _poolMaxBudget;
        } else if (_totalMaxIncentive > 0){
            _amount = (_poolMaxBudget * _totalIncentAmount) / _totalMaxIncentive;
        } else {
            _amount = 0;
        }
    }

/* ======================================== INCENTIVIZATION FUNCTIONS =============================================== */

    /// @notice Function to deposit incentives to one pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _amount Amount of incentives to be deposited
    function incentivizePoolByAmount(
        address _poolAddress,
        uint256 _amount
    ) public activePool(_poolAddress) onlyByOwnerOperator {
        ERC20 _incentiveToken = ERC20(incentiveTokenAddress);
        _incentiveToken.approve(poolInfo[_poolAddress].incentivePoolAddress, _amount);

        (bool success, ) = poolInfo[_poolAddress].incentivizationHandlerAddress.delegatecall(
            abi.encodeWithSignature(
                "incentivizePool(address,address,address,address,uint256,uint256)",
                _poolAddress,
                poolInfo[_poolAddress].gaugeAddress,
                poolInfo[_poolAddress].incentivePoolAddress,
                incentiveTokenAddress,
                poolInfo[_poolAddress].incentivizationId,
                _amount
            )
        );
        require(success, "delegatecall failed");
        if (poolInfo[_poolAddress].lastIncentivizationTimestamp == 0){
            poolInfo[_poolAddress].firstIncentivizationTimestamp = block.timestamp;
        }
        poolInfo[_poolAddress].lastIncentivizationTimestamp = block.timestamp;
        poolInfo[_poolAddress].lastIncentivizationAmount = _amount;
        emit IncentivizePool(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on ratio)
    /// @param _poolAddress Address of liquidity pool
    /// @param _totalIncentAmount Total budget for incentivization
    /// @param _totalTvl Total active pools TVL
    function incentivizePoolByTvl(
        address _poolAddress,
        uint256 _totalIncentAmount,
        uint256 _totalTvl
    ) public onlyByOwnerOperator {
        uint256 _poolTvl = showPoolTvl(_poolAddress);
        uint256 _amount = (_totalIncentAmount * _poolTvl) / _totalTvl;
        incentivizePoolByAmount(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on budget per unit)
    /// @param _poolAddress Address of liquidity pool
    /// @param _unitIncentAmount Incentive per single unit of target Token
    function incentivizePoolByUnitBudget(
        address _poolAddress,
        uint256 _unitIncentAmount
    ) public onlyByOwnerOperator {
        uint256 _poolTvl = showPoolTvl(_poolAddress);
        uint256 _amount = (_unitIncentAmount * _poolTvl) / (10 ** ERC20(targetTokenAddress).decimals());
        incentivizePoolByAmount(_poolAddress, _amount);
    }

    /// @notice Function to deposit incentives to one pool (based on Constant Incentivization)
    /// @param _poolAddress Address of liquidity pool
    function incentivizePoolByFixedIncent(
        address _poolAddress
    ) public onlyByOwnerOperator {
        if (poolHasFixedIncent[_poolAddress]){
            uint256 _amount = poolFixedIncentAmount[_poolAddress];
            incentivizePoolByAmount(_poolAddress, _amount);
        }
    }

    /// Functions For depositing incentives to all active pools

    /// @notice Function to deposit incentives to all active pools (based on TVL ratio)
    /// @param _totalIncentAmount Total Incentive budget
    /// @param _FixedIncent Incentivize considering FixedIncent
    function incentivizeAllPoolsByTvl(uint256 _totalIncentAmount, bool _FixedIncent) public onlyByOwnerOperator {
        uint256 _totalTvl = showActivePoolsTvl();
        for (uint i = 0; i < poolArray.length; i++) {
            if (_FixedIncent && poolHasFixedIncent[poolArray[i]]) {
                incentivizePoolByFixedIncent(poolArray[i]);
            } else if (!poolInfo[poolArray[i]].isPaused && showPoolTvl(poolArray[i]) > minTvl) {
                incentivizePoolByTvl(poolArray[i], _totalIncentAmount, _totalTvl);
            }
        }
    }
    
    /// @notice Function to deposit incentives to all active pools (based on budget per unit of target Token)
    /// @param _unitIncentAmount Incentive per single unit of target Token
    /// @param _FixedIncent Incentivize considering FixedIncent
    function incentivizeAllPoolsByUnitBudget(uint256 _unitIncentAmount, bool _FixedIncent) public onlyByOwnerOperator {
        for (uint i = 0; i < poolArray.length; i++) {
            if (_FixedIncent && poolHasFixedIncent[poolArray[i]]) {
                incentivizePoolByFixedIncent(poolArray[i]);
            } else if (!poolInfo[poolArray[i]].isPaused && showPoolTvl(poolArray[i]) > minTvl) {
                incentivizePoolByUnitBudget(poolArray[i], _unitIncentAmount);
            }
        }
    }

    /// @notice Add/Set liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _incentivePoolAddress Contract that handle incentive distribution e.g. Bribe contract
    /// @param _incentivizationHandlerAddress Incentive handler contract e.g. votemarket handler
    /// @param _gaugeAddress Address of liquidity pool gauge
    /// @param _lpTokenAddress Address of liquidity pool lp token
    /// @param _incentivizationId Pool General Incentivization ID (e.g. in Votemarket it is BountyID)
    /// @param _poolCycleLength length of the cycle for this pool in sec (e.g. one week)
    function addOrSetPool(
        address _poolAddress,
        address _incentivePoolAddress,
        address _incentivizationHandlerAddress,
        address _gaugeAddress,
        address _lpTokenAddress,
        uint256 _incentivizationId,
        uint256 _poolCycleLength
    ) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolInfo[_poolAddress].incentivePoolAddress = _incentivePoolAddress;
            poolInfo[_poolAddress].incentivizationHandlerAddress = _incentivizationHandlerAddress;
            poolInfo[_poolAddress].gaugeAddress = _gaugeAddress;
            poolInfo[_poolAddress].incentivizationId = _incentivizationId;
            poolInfo[_poolAddress].lpTokenAddress = _lpTokenAddress;
            poolInfo[_poolAddress].poolCycleLength = _poolCycleLength;
        } else {
            poolInitialized[_poolAddress] = true;
            poolArray.push(_poolAddress);
            poolInfo[_poolAddress] = LiquidityPool({
                poolAddress: _poolAddress,
                lpTokenAddress: _lpTokenAddress,
                incentivePoolAddress: _incentivePoolAddress,
                incentivizationHandlerAddress: _incentivizationHandlerAddress,
                gaugeAddress: _gaugeAddress,
                lastIncentivizationTimestamp: 0,
                lastIncentivizationAmount: 0,
                firstIncentivizationTimestamp: 0,
                isPaused: false,
                incentivizationId: _incentivizationId,
                poolCycleLength: _poolCycleLength
            });
            setPoolTier(_poolAddress, 0);
        }

        emit AddOrSetPool(
            _poolAddress,
            _lpTokenAddress,
            _gaugeAddress,
            _incentivePoolAddress,
            _incentivizationHandlerAddress,
            _incentivizationId,
            _poolCycleLength
        );
    }

    /// @notice Pause/Unpause liquidity pool
    /// @param _poolAddress Address of liquidity pool
    /// @param _isPaused bool
    function pausePool(address _poolAddress, bool _isPaused) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolInfo[_poolAddress].isPaused = _isPaused;
            emit ChangePauseStatusPool(_poolAddress, _isPaused);
        }
    }

    /// @notice Add/Change/Remove Constant Incentivization can be set (e.g. DAO Deal)
    /// @param _poolAddress Address of liquidity pool
    /// @param _hasFixedIncent bool
    /// @param _amountPerCycle Amount of constant incentives
    function setFixedIncent(address _poolAddress, bool _hasFixedIncent, uint256 _amountPerCycle) external onlyByOwnerOperator {
        if (poolInitialized[_poolAddress]) {
            poolHasFixedIncent[_poolAddress] = _hasFixedIncent;
            poolFixedIncentAmount[_poolAddress] = _amountPerCycle;
            emit SetPoolFixedIncent(_poolAddress, _hasFixedIncent, _amountPerCycle);
        }
    }

/* ================================== TIER BASED INCENTIVIZATION FUNCTIONS ========================================== */

    /// @notice Add/Set a Incentivization Tier
    /// @param _tokenMaxBudgetPerUnit  Max incentive per unit of target token per cycle for pools within this tier
    /// @param _kickstartPeriodLength Kickstart period length for pools within this tier in secs
    /// @param _kickstartPeriodBudget Kickstart period budget per cycle for pools within this tier 
    function addTier(
        uint256 _tokenMaxBudgetPerUnit,
        uint256 _kickstartPeriodLength,
        uint256 _kickstartPeriodBudget
    ) public onlyByOwnerOperator returns (uint256 _tierId) {
        _tierId = allTiersLength();
        tierArray.push(IncentiveTier({
            tokenMaxBudgetPerUnit: _tokenMaxBudgetPerUnit,
            kickstartPeriodLength: _kickstartPeriodLength,
            kickstartPeriodBudget: _kickstartPeriodBudget
        }));
        emit AddOrSetTier(_tierId, _tokenMaxBudgetPerUnit, _kickstartPeriodLength, _kickstartPeriodBudget);
    }

    /// @notice Set liquidity pool incentivization tier
    /// @param _poolAddress Address of liquidity pool
    /// @param _tierId uint256
    function setPoolTier(address _poolAddress, uint256 _tierId) public onlyByOwnerOperator {
        if (poolInitialized[_poolAddress] && (_tierId < allTiersLength())) {
            poolTier[_poolAddress] = _tierId;
            emit SetPoolTier(_poolAddress, _tierId);
        }
    }

    /// @notice Function to deposit incentives to all pools (based on tier budgets)
    /// @param _totalIncentAmount Total Incentive budget in incentive token
    /// @param _priceRatio (Target Token Price / Incentive Token Price) * 100_000  
    function incentivizeAllPoolsByTier(uint256 _totalIncentAmount, uint256 _priceRatio) public onlyByOwnerOperator {
        uint256 _totalMaxIncentiveAmount = maxBudgetForAllPoolsByTier();
        for (uint i = 0; i < poolArray.length; i++) {
            uint256 _amount = adjustedBudgetForPoolByTier(poolArray[i], _totalIncentAmount, _totalMaxIncentiveAmount, _priceRatio);
            incentivizePoolByAmount(poolArray[i], _amount);
        }
    }


/* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);
        operatorAddress = _newOperatorAddress;
    }

    /// @notice Change the Cycle Length for incentivization
    /// @param _cycleLength Cycle Length for being considered for incentivization
    function setCycleLength(uint256 _cycleLength) external onlyOwner {
        cycleLength = _cycleLength;
    }

    /// @notice Change the Min TVL for incentivization
    /// @param _minTvl Min TVL of pool for being considered for incentivization
    function setMinTvl(uint256 _minTvl) external onlyOwner {
        minTvl = _minTvl;
    }

    /// @notice Recover ERC20 tokens
    /// @param tokenAddress address of ERC20 token
    /// @param tokenAmount amount to be withdrawn
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Can only be triggered by owner
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{ value: _value }(_data);
        return (success, result);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IFxs {
  function DEFAULT_ADMIN_ROLE() external view returns(bytes32);
  function FRAXStablecoinAdd() external view returns(address);
  function FXS_DAO_min() external view returns(uint256);
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
  function balanceOf(address account) external view returns(uint256);
  function burn(uint256 amount) external;
  function burnFrom(address account, uint256 amount) external;
  function checkpoints(address, uint32) external view returns(uint32 fromBlock, uint96 votes);
  function decimals() external view returns(uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
  function genesis_supply() external view returns(uint256);
  function getCurrentVotes(address account) external view returns(uint96);
  function getPriorVotes(address account, uint256 blockNumber) external view returns(uint96);
  function getRoleAdmin(bytes32 role) external view returns(bytes32);
  function getRoleMember(bytes32 role, uint256 index) external view returns(address);
  function getRoleMemberCount(bytes32 role) external view returns(uint256);
  function grantRole(bytes32 role, address account) external;
  function hasRole(bytes32 role, address account) external view returns(bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns(bool);
  function mint(address to, uint256 amount) external;
  function name() external view returns(string memory);
  function numCheckpoints(address) external view returns(uint32);
  function oracle_address() external view returns(address);
  function owner_address() external view returns(address);
  function pool_burn_from(address b_address, uint256 b_amount) external;
  function pool_mint(address m_address, uint256 m_amount) external;
  function renounceRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function setFRAXAddress(address frax_contract_address) external;
  function setFXSMinDAO(uint256 min_FXS) external;
  function setOracle(address new_oracle) external;
  function setOwner(address _owner_address) external;
  function setTimelock(address new_timelock) external;
  function symbol() external view returns(string memory);
  function timelock_address() external view returns(address);
  function toggleVotes() external;
  function totalSupply() external view returns(uint256);
  function trackingVotes() external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IIncentivizationHandler {
  function incentivizePool(
    address poolAddress, 
    address gaugeAddress,
    address incentivePoolAdderss, 
    address incentiveTokenAddress,
    uint256 indexId, 
    uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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