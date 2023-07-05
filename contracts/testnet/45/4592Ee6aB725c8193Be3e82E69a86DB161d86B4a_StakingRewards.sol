// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract StakingRewards {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardToken1;
    IERC20 public immutable rewardToken2;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second (rewardToken1 and rewardToken2)
    uint public rewardRate1;
    uint public rewardRate2;
    // Sum of (reward rate * dt * 1e18 / total supply) (rewardToken1 and rewardToken2)
    uint public rewardPerTokenStored1;
    uint public rewardPerTokenStored2;
    // User address => (rewardPerTokenStored1 and rewardPerTokenStored2)
    mapping(address => uint) public userRewardPerTokenPaid1;
    mapping(address => uint) public userRewardPerTokenPaid2;
    // User address => rewards to be claimed (rewardToken1 and rewardToken2)
    mapping(address => uint) public rewards1;
    mapping(address => uint) public rewards2;

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    constructor(address _stakingToken, address _rewardToken1, address _rewardToken2) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardToken1 = IERC20(_rewardToken1);
        rewardToken2 = IERC20(_rewardToken2);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored1 = rewardPerToken1();
        rewardPerTokenStored2 = rewardPerToken2();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards1[_account] = earned1(_account);
            rewards2[_account] = earned2(_account);
            userRewardPerTokenPaid1[_account] = rewardPerTokenStored1;
            userRewardPerTokenPaid2[_account] = rewardPerTokenStored2;
        }

        _;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken1() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored1;
        }

        return
            rewardPerTokenStored1 +
            (rewardRate1 * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function rewardPerToken2() public view returns (uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored2;
        }

        return
            rewardPerTokenStored2 +
            (rewardRate2 * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function withdraw(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function earned1(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken1() - userRewardPerTokenPaid1[_account])) / 1e18) +
            rewards1[_account];
    }

    function earned2(address _account) public view returns (uint) {
        return
            ((balanceOf[_account] *
                (rewardPerToken2() - userRewardPerTokenPaid2[_account])) / 1e18) +
            rewards2[_account];
    }

    function getReward() external updateReward(msg.sender) {
        uint reward1 = rewards1[msg.sender];
        uint reward2 = rewards2[msg.sender];

        if (reward1 > 0) {
            rewards1[msg.sender] = 0;
            rewardToken1.transfer(msg.sender, reward1);
        }

        if (reward2 > 0) {
            rewards2[msg.sender] = 0;
            rewardToken2.transfer(msg.sender, reward2);
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmounts(
        uint _amount1,
        uint _amount2
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate1 = _amount1 / duration;
            rewardRate2 = _amount2 / duration;
        } else {
            uint remainingRewards1 = (finishAt - block.timestamp) * rewardRate1;
            uint remainingRewards2 = (finishAt - block.timestamp) * rewardRate2;
            rewardRate1 = (_amount1 + remainingRewards1) / duration;
            rewardRate2 = (_amount2 + remainingRewards2) / duration;
        }

        require(rewardRate1 > 0, "reward rate 1 = 0");
        require(rewardRate2 > 0, "reward rate 2 = 0");
        require(
            rewardRate1 * duration <= rewardToken1.balanceOf(address(this)),
            "reward amount 1 > balance"
        );
        require(
            rewardRate2 * duration <= rewardToken2.balanceOf(address(this)),
            "reward amount 2 > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}