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

// File: contracts\PoolRewardHook.sol

pragma solidity 0.8.10;
/*
    A Hook contract that pools call to perform extra actions when updating rewards
    (Example: claiming extra rewards from an outside contract)
*/
contract PoolRewardHook is IRewardHook{

    address public immutable booster;
    mapping(address => address[]) public poolRewardList;

    event PoolRewardAdded(address indexed pool, address rewardContract);
    event PoolRewardReset(address indexed pool);

    constructor(address _booster) {
        booster = _booster;
    }

    //get reward manager role from booster to use as admin
    function rewardManager() public view returns(address){
        return IBooster(booster).rewardManager();
    }

    //get reward contract list count for given pool/account
    function poolRewardLength(address _pool) external view returns(uint256){
        return poolRewardList[_pool].length;
    }

    //clear reward contract list for given pool/account
    function clearPoolRewardList(address _pool) external{
        require(msg.sender == rewardManager(), "!rmanager");

        delete poolRewardList[_pool];
        emit PoolRewardReset(_pool);
    }

    //add a reward contract to the list of contracts for a given pool/account
    function addPoolReward(address _pool, address _rewardContract) external{
        require(msg.sender == rewardManager(), "!rmanager");

        poolRewardList[_pool].push(_rewardContract);
        emit PoolRewardAdded(_pool, _rewardContract);
    }

    //call all reward contracts to claim. (unguarded)
    function onRewardClaim() external{
        uint256 rewardLength = poolRewardList[msg.sender].length;
        for(uint256 i = 0; i < rewardLength; i++){
            //use try-catch as this could be a 3rd party contract
            try IRewards(poolRewardList[msg.sender][i]).getReward(msg.sender){
            }catch{}
        }
    }

}