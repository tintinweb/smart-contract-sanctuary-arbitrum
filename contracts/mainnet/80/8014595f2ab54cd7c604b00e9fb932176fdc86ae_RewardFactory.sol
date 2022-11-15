/**
 *Submitted for verification at Arbiscan on 2022-11-15
*/

// File: contracts\interfaces\IBooster.sol

// SPDX-License-Identifier: MIT
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

// File: contracts\interfaces\IProxyFactory.sol

pragma solidity 0.8.10;

interface IProxyFactory {
    function clone(address _target) external returns(address);
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

// File: contracts\RewardFactory.sol

pragma solidity 0.8.10;
//factory to create reward pools
contract RewardFactory {

    address public immutable proxyFactory;
    address public immutable staker;

    address public operator;
    address public mainImplementation;

    constructor(address _operator, address _staker, address _proxyFactory) {
        operator = _operator;
        staker = _staker;
        proxyFactory = _proxyFactory;
    }

    function setImplementation(address _imp) external{
        require(msg.sender == IBooster(operator).owner(),"!auth");

        mainImplementation = _imp;
    }

    //Create a reward pool for a given pool
    function CreateMainRewards(address _crv, address _gauge, address _depositToken, uint256 _pid) external returns (address) {
        require(msg.sender == operator, "!auth");

        address rewardPool = IProxyFactory(proxyFactory).clone(mainImplementation);
        IConvexRewardPool(rewardPool).initialize(_crv, _gauge, staker, operator,_depositToken, _pid);
        
        return rewardPool;
    }
}