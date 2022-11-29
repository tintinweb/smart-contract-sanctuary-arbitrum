/**
 *Submitted for verification at Arbiscan on 2022-11-29
*/

// File: contracts\interfaces\IGauge.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IGauge {
    function deposit(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function working_balances(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function working_supply() external view returns (uint256);
    function withdraw(uint256) external;
    function claim_rewards() external;
    function claim_rewards(address _account) external;
    function lp_token() external view returns(address);
    function set_rewards_receiver(address _receiver) external;
    function reward_count() external view returns(uint256);
    function reward_tokens(uint256 _rid) external view returns(address _rewardToken);
    function reward_data(address _reward) external view returns(address distributor, uint256 period_finish, uint256 rate, uint256 last_update, uint256 integral);
    function claimed_reward(address _account, address _token) external view returns(uint256);
    function claimable_reward(address _account, address _token) external view returns(uint256);
    function claimable_tokens(address _account) external returns(uint256);
    function inflation_rate(uint256 _week) external view returns(uint256);
    function period() external view returns(uint256);
    function period_timestamp(uint256 _period) external view returns(uint256);
    // function claimable_reward_write(address _account, address _token) external returns(uint256);
    function add_reward(address _reward, address _distributor) external;
    function set_reward_distributor(address _reward, address _distributor) external;
    function deposit_reward_token(address _reward, uint256 _amount) external;
    function manager() external view returns(address _manager);
}

// File: contracts\interfaces\IBooster.sol

pragma solidity 0.8.10;

interface IBooster {
   function isShutdown() external view returns(bool);
   function withdrawTo(uint256,uint256,address) external;
   function claimCrv(uint256 _pid, address _gauge) external;
   function setGaugeRedirect(uint256 _pid) external returns(bool);
   function owner() external view returns(address);
   function rewardManager() external view returns(address);
   function feeDeposit() external view returns(address);
   function factoryCrv(address _factory) external view returns(address _crv);
   function calculatePlatformFees(uint256 _amount) external view returns(uint256);
   function addPool(address _lptoken, address _gauge, address _factory) external returns(bool);
   function shutdownPool(uint256 _pid) external returns(bool);
   function poolInfo(uint256) external view returns(address _lptoken, address _gauge, address _rewards,bool _shutdown, address _factory);
   function poolLength() external view returns (uint256);
   function activeMap(address) external view returns(bool);
   function fees() external view returns(uint256);
   function setPoolManager(address _poolM) external;
}

// File: contracts\interfaces\IConvexRewardPool.sol

pragma solidity 0.8.10;

interface IConvexRewardPool{
    struct EarnedData {
        address token;
        uint256 amount;
    }

    struct RewardType {
        address reward_token;
        uint128 reward_integral;
        uint128 reward_remaining;
    }

    function initialize(
        address _crv,
        address _curveGauge,
        address _convexStaker,
        address _convexBooster,
        address _convexToken,
        uint256 _poolId) external;
    function setExtraReward(address) external;
    function setRewardHook(address) external;
    function rewardHook() external view returns(address _hook);
    function getReward(address) external;
    function user_checkpoint(address) external;
    function rewardLength() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address) external view returns(uint256);
    function rewards(uint256 _rewardIndex) external view returns(RewardType memory);
    function earnedView(address _account) external view returns(EarnedData[] memory claimable);
    function earned(address _account) external returns(EarnedData[] memory claimable);
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
}

// File: contracts\interfaces\IRewardHook.sol

pragma solidity 0.8.10;

interface IRewardHook {
    function onRewardClaim() external;
    function rewardManager() external view returns(address);
    function poolRewardLength(address _pool) external view returns(uint256);
    // function poolRewardList(address _pool) external view returns(address[] memory _rewardContractList);
    function poolRewardList(address _pool, uint256 _index) external view returns(address _rewardContract);
    function clearPoolRewardList(address _pool) external;
    function addPoolReward(address _pool, address _rewardContract) external;
}

// File: contracts\interfaces\IExtraRewardPool.sol

pragma solidity 0.8.10;

interface IExtraRewardPool{
    enum PoolType{
        Single,
        Multi
    }
    function rewardToken() external view returns(address);
    function pid() external view returns(uint256);
    function periodFinish() external view returns(uint256);
    function rewardRate() external view returns(uint256);
    function totalSupply() external view returns(uint256);
    function balanceOf(address _account) external view returns(uint256);
    function poolType() external view returns(PoolType);
    function poolVersion() external view returns(uint256);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol


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

// File: contracts\PoolUtilities.sol

pragma solidity 0.8.10;
/*
This is a utility library which is mainly used for off chain calculations
*/
contract PoolUtilities{

    uint256 private constant WEEK = 7 * 86400;

    address public constant convexProxy = address(0x989AEb4d175e16225E39E87d0D97A3360524AD80);
    address public immutable crv;
    address public immutable booster;

    constructor(address _booster, address _crv){
        booster = _booster;
        crv = _crv;
    }


    //get boosted reward rate of user at a specific staking contract
    //returns amount user receives per second based on weight/liq ratio
    //%return = userBoostedRewardRate * timeFrame * price of reward / price of LP / 1e18
    function gaugeRewardRates(uint256 _pid, uint256 _week) public view returns (address[] memory tokens, uint256[] memory boostedRates) {
        //get pool info
        (, address gauge, , ,) = IBooster(booster).poolInfo(_pid);

        uint256 week = _week;

        if(week == 0){
            //get current period -> timestamp from period
            uint256 period = IGauge(gauge).period();
            uint256 periodTime = IGauge(gauge).period_timestamp(period);

            //get week from last checkpointed period
            week = periodTime / WEEK;
        }

        //get inflation rate
        uint256 infRate = IGauge(gauge).inflation_rate(week);

        //if inflation is 0, there might be tokens on the gauge and not checkpointed yet
        if(infRate == 0){
            infRate = IERC20(crv).balanceOf(gauge) / WEEK;
        }

        //if inflation is still 0... might have not bridged yet, or lost gauge weight


        //reduce by fees
        infRate -= (infRate * IBooster(booster).fees() / 10000);
        

        //get working supply
        uint256 wsupply = IGauge(gauge).working_supply();

        if(wsupply > 0){
            infRate = infRate * 1e18 / wsupply;
        }

        //get convex working balance
        uint256 wbalance = IGauge(gauge).working_balances(convexProxy);
        //get convex deposited balance
        uint256 dbalance = IGauge(gauge).balanceOf(convexProxy);

        //convex inflation rate
        uint256 cvxInfRate = infRate;
        //if no balance, just return a full boosted rate
        if(wbalance > 0){
            //wbalance and dbalance will cancel out if full boost
            cvxInfRate = infRate * wbalance / dbalance;
        }

        //number of gauge rewards
        uint256 gaugeRewards = IGauge(gauge).reward_count();

        //make list of reward rates
        tokens = new address[](gaugeRewards + 1);
        boostedRates = new uint256[](gaugeRewards + 1);

        //index 0 will be crv
        tokens[0] = crv;
        boostedRates[0] = cvxInfRate;

        //use total supply for rewards since no boost
        uint256 tSupply = IGauge(gauge).totalSupply();
        //loop through rewards
        for(uint256 i = 0; i < gaugeRewards; i++){
            address rt = IGauge(gauge).reward_tokens(i);
            (,, uint256 rrate,,) = IGauge(gauge).reward_data(rt);

            //get rate per total supply
            if(tSupply > 0){
                rrate = rrate * 1e18 / tSupply;
            }

            //set rate (no boost for extra rewards)
            boostedRates[i+1] = rrate;
            tokens[i+1] = rt;
        }
    }

     function externalRewardContracts(uint256 _pid) public view returns (address[] memory rewardContracts) {
        //get pool info
        (, , address rewards, ,) = IBooster(booster).poolInfo(_pid);

        //get reward hook
        address hook = IConvexRewardPool(rewards).rewardHook();

        uint256 rewardCount = IRewardHook(hook).poolRewardLength(rewards);
        rewardContracts = new address[](rewardCount);

        for(uint256 i = 0; i < rewardCount; i++){
            rewardContracts[i] = IRewardHook(hook).poolRewardList(rewards, i);
        }
    }

    function aggregateExtraRewardRates(uint256 _pid) external view returns(address[] memory tokens, uint256[] memory rates){
        address[] memory rewardContracts = externalRewardContracts(_pid);

        tokens = new address[](rewardContracts.length);
        rates = new uint256[](rewardContracts.length);

        for(uint256 i = 0; i < rewardContracts.length; i++){
            IExtraRewardPool.PoolType pt = IExtraRewardPool(rewardContracts[i]).poolType();
            if(pt == IExtraRewardPool.PoolType.Single){
                (address t, uint256 r) = singleRewardRate(_pid, rewardContracts[i]);
                tokens[i] = t;
                rates[i] = r;
            }
        }
    }

    function singleRewardRate(uint256 _pid, address _rewardContract) public view returns (address token, uint256 rate) {
        
        //set token
        token = IExtraRewardPool(_rewardContract).rewardToken();

        //check period finish
        if(IExtraRewardPool(_rewardContract).periodFinish() < block.timestamp ){
            //return early as rate is 0
            return (token,0);
        }

        //get global rate and supply
        uint256 globalRate = IExtraRewardPool(_rewardContract).rewardRate();
        uint256 totalSupply = IExtraRewardPool(_rewardContract).totalSupply();
        

        if(totalSupply > 0){
            //get pool info
            (, , address rewards, ,) = IBooster(booster).poolInfo(_pid);

            //get rate for whole pool (vs other pools)
            rate = globalRate * IExtraRewardPool(_rewardContract).balanceOf(rewards) / totalSupply;

            //get pool total supply
            uint256 poolSupply = IConvexRewardPool(rewards).totalSupply();
            if(poolSupply > 0){
                //rate per deposit
                rate = rate * 1e18 / poolSupply;
            }
        }
    }
}