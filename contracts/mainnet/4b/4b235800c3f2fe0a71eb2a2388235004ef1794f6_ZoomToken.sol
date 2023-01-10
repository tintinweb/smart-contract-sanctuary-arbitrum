/**
 *Submitted for verification at Arbiscan on 2023-01-10
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract ZoomToken {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public stakedBalanceOf;
    mapping(address => uint256) public stakingStartTime;
    mapping(address => uint256) public stakingEndTime;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Staked(address indexed _owner, uint256 _value, uint256 _startTime, uint256 _endTime);
    event Unstaked(address indexed _owner, uint256 _value);
    address public deployer;
    uint256 public inflationRate = 5;

    function init() public {
        totalSupply = 100000000;
        balanceOf[msg.sender] = totalSupply;
        deployer = 0x3Da5844750eADe70740C8A0e877d69156Fa73D36;
    }

    function getBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

        function stake(uint256 _value, uint256 _stakingPeriod) public {
        require(balanceOf[msg.sender] >= _value && _value > 0);
        require(_stakingPeriod >= 1 days && _stakingPeriod <= 30 days);
        balanceOf[msg.sender] -= _value;
        stakedBalanceOf[msg.sender] += _value;
        stakingStartTime[msg.sender] = block.timestamp;
        stakingEndTime[msg.sender] = block.timestamp + _stakingPeriod;
        emit Staked(msg.sender, _value, stakingStartTime[msg.sender], stakingEndTime[msg.sender]);
    }

    function unstake() public {
        require(stakingEndTime[msg.sender] <= block.timestamp);
        balanceOf[msg.sender] += stakedBalanceOf[msg.sender];
        stakedBalanceOf[msg.sender] = 0;
        stakingStartTime[msg.sender] = 0;
        stakingEndTime[msg.sender] = 0;
        emit Unstaked(msg.sender, stakedBalanceOf[msg.sender]);
    }

    function calculateStakingInterest() public view returns(uint256) {
        uint256 currentTime = block.timestamp;
        require(stakingEndTime[msg.sender] > currentTime);
        uint256 interest = stakedBalanceOf[msg.sender] * (1+ (inflationRate/100) ) ** ( (currentTime - stakingStartTime[msg.sender])/(stakingEndTime[msg.sender]-stakingStartTime[msg.sender]) );
        return interest;
    }

    function mint(address _to, uint256 _value) internal {
        totalSupply += _value;
        balanceOf[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }
}