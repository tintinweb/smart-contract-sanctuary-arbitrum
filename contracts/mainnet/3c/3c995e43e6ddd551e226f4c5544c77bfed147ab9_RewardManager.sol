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

// File: contracts\interfaces\IRewards.sol

pragma solidity 0.8.10;

interface IRewards{
    function stake(address, uint256) external;
    function stakeFor(address, uint256) external;
    function withdraw(address, uint256) external;
    function setWeight(address _pool, uint256 _amount) external returns(bool);
    function setWeights(address[] calldata _account, uint256[] calldata _amount) external;
    function setDistributor(address _distro, bool _valid) external;
    function getReward(address) external;
    function queueNewRewards(uint256) external;
    function addExtraReward(address) external;
    function setRewardHook(address) external;
    function user_checkpoint(address _account) external returns(bool);
    function rewardToken() external view returns(address);
    function rewardMap(address) external view returns(bool);
    function earned(address account) external view returns (uint256);
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

// File: contracts\RewardManager.sol

pragma solidity 0.8.10;
/*
    Basic manager for extra rewards
    
    Use booster owner for operations for now. Can be replaced when weighting
    can be handled on chain
*/
contract RewardManager{

    address public immutable booster;


    address public rewardHook;
    address public immutable cvx;

    event PoolWeight(address indexed rewardContract, address indexed pool, uint256 weight);
    event PoolWeights(address indexed rewardContract, address[] pool, uint256[] weight);
    event PoolRewardToken(address indexed pool, address token);
    event PoolRewardContract(address indexed pool, address indexed hook, address rcontract);
    event PoolRewardContractClear(address indexed pool, address indexed hook);
    event DefaultHookSet(address hook);
    event HookSet(address indexed pool, address hook);
    event AddDistributor(address indexed rewardContract, address indexed _distro, bool _valid);

    constructor(address _booster, address _cvx) {
        booster = _booster;
        cvx = _cvx;
    }

    function owner() public view returns(address){
        return IBooster(booster).owner();
    }

    //set default pool hook
    function setPoolHook(address _hook) external{
        require(msg.sender == owner(), "!auth");

        rewardHook = _hook;
        emit DefaultHookSet(_hook);
    }

    //add reward token type to a given pool
    function setPoolRewardToken(address _pool, address _rewardToken) external{
        require(msg.sender == owner(), "!auth");

        IRewards(_pool).addExtraReward(_rewardToken);
        emit PoolRewardToken(_pool, _rewardToken);
    }

    //add contracts to pool's hook list
    function setPoolRewardContract(address _pool, address _hook, address _rewardContract) external{
        require(msg.sender == owner(), "!auth");

        IRewardHook(_hook).addPoolReward(_pool, _rewardContract);
        emit PoolRewardContract(_pool, _hook, _rewardContract);
    }

    //clear all contracts for pool on given hook
    function clearPoolRewardContractList(address _pool, address _hook) external{
        require(msg.sender == owner(), "!auth");

        IRewardHook(_hook).clearPoolRewardList(_pool);
        emit PoolRewardContractClear(_pool, _hook);
    }

    //set pool weight on a given extra reward contract
    function setPoolWeight(address _rewardContract, address _pool, uint256 _weight) external{
        require(msg.sender == owner(), "!auth");

        IRewards(_rewardContract).setWeight(_pool, _weight);
        emit PoolWeight(_rewardContract, _pool, _weight);
    }

    //set pool weights on a given extra reward contracts
    function setPoolWeights(address _rewardContract, address[] calldata _pools, uint256[] calldata _weights) external{
        require(msg.sender == owner(), "!auth");

        IRewards(_rewardContract).setWeights(_pools, _weights);
        emit PoolWeights(_rewardContract, _pools, _weights);
    }

    //update a pool's reward hook
    function setPoolRewardHook(address _pool, address _hook) external{
        require(msg.sender == owner(), "!auth");

        IRewards(_pool).setRewardHook(_hook);
        emit HookSet(_pool, _hook);
    }

    //set a reward contract distributor
    function setRewardDistributor(address _rewardContract, address _distro, bool _isValid) external{
        require(msg.sender == owner(), "!auth");

        IRewards(_rewardContract).setDistributor(_distro, _isValid);
    }

}