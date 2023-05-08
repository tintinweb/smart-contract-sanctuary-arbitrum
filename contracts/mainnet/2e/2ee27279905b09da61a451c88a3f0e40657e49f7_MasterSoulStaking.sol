/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function requestSupply(address to, uint256 amount) external returns (bool);
  function manualerbase() external returns (bool);
}


contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

contract MasterSoulStaking is permission {

    struct userInfo {
        uint256 amount;
        uint256 rewards;
        uint256 rewardDebt;
    }

    address public soulToken;
    address public lpToken;
    address public _owner;

    uint256 public rewardPerBlock;
    uint256 public totalSupply;
    uint256 public latestBlock;
    uint256 public accumulated;
    uint256 public deleyedcooldown;

    mapping(address => userInfo) public user;
    mapping(address => uint256) public unlockedBlock;

    constructor(address _soulToken,address _lpToken,uint256 _rewardPerBlock) {
        rewardPerBlock = _rewardPerBlock;
        soulToken = _soulToken;
        lpToken = _lpToken;
        _owner = msg.sender;
        newpermit(_owner,"owner");
    }

    function updateRewardPerBlock(uint256 amount) external {
        rewardPerBlock = amount;
        harvestRewards(address(0));
    }

    function deposit(address addr,uint256 amount) external {
        require(amount > 0, "Deposit amount can't be zero");
        harvestRewards(addr);
        user[addr].amount = user[addr].amount + amount;
        user[addr].rewardDebt = user[addr].amount * accumulated / 1e12;
        totalSupply = totalSupply + amount;
        unlockedBlock[addr] = block.timestamp + deleyedcooldown;
        IERC20(lpToken).transferFrom(msg.sender,address(this),amount);
        IERC20(soulToken).manualerbase();
    }

    function withdraw() external {
        address addr = msg.sender;
        uint256 amount = user[addr].amount;
        require(amount > 0, "Withdraw amount can't be zero");
        require(unlockedBlock[msg.sender]<block.timestamp,"Withdraw Is In Coutdown");
        harvestRewards(addr);
        user[addr].amount = 0;
        user[addr].rewardDebt = user[addr].amount * accumulated / 1e12;
        totalSupply = totalSupply - amount;
        IERC20(lpToken).transfer(addr,amount);
        IERC20(soulToken).manualerbase();
    }

    function harvestRewards(address addr) public {
        updatePoolRewards();
        uint256 rewardsToHarvest = (user[addr].amount * accumulated / 1e12) - user[addr].rewardDebt;
        if (rewardsToHarvest == 0) {
            user[addr].rewardDebt = user[addr].amount * accumulated / 1e12;
            return;
        }
        user[addr].rewards = 0;
        user[addr].rewardDebt = user[addr].amount * accumulated / 1e12;
        if(rewardsToHarvest>0){
            IERC20(soulToken).requestSupply(addr,rewardsToHarvest);
            IERC20(soulToken).manualerbase();
        }
    }

    function updatePoolRewards() private {
        if (totalSupply == 0) {
            latestBlock = block.timestamp;
            return;
        }
        uint256 period = block.timestamp - latestBlock;
        uint256 rewards = period * rewardPerBlock;
        accumulated = accumulated + (rewards * 1e12 / totalSupply);
        latestBlock = block.timestamp;
    }

    function settingDeleyedcooldown(uint256 _cooldown) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        deleyedcooldown = _cooldown;
        return true;
    }

    function nowBlock() public view returns (uint256) {
        return block.timestamp;
    }

    function pendingReward(address addr) external view returns (uint256) {
        uint256 period = block.timestamp - latestBlock;
        uint256 rewards = period * rewardPerBlock;
        uint256 t_accumulated = accumulated + (rewards * 1e12 / totalSupply);
        return (user[addr].amount * t_accumulated / 1e12) - user[addr].rewardDebt;
    }

    function grantRole(address adr,string memory role) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        _owner = adr;
        return true;
    }

}