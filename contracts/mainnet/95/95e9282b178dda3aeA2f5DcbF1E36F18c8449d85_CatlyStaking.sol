/**
 *Submitted for verification at Arbiscan.io on 2023-09-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract CatlyStaking {
    using SafeMath for uint256;

    struct User {
        uint256 stakedAmount;
        uint256 lastUpdateTime;
        uint256 rewards;
    }

    mapping(address => User) public users;
    address public owner;
    address public stakingToken;
    uint256 public totalStaked;
    uint256 public stakingRatePerSecond;
    uint256 public reductionFactor = 24000000; 

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        address _stakingToken,
        uint256 _stakingRatePerSecond
    ) {
        owner = msg.sender;
        stakingToken = _stakingToken;
        stakingRatePerSecond = _stakingRatePerSecond;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        User storage user = users[msg.sender];
        if (user.stakedAmount > 0) {
            uint256 pendingRewards = calculatePendingRewards(msg.sender);
            user.rewards += pendingRewards;
        }

        user.stakedAmount += amount;
        user.lastUpdateTime = block.timestamp;
        totalStaked += amount;
    }

    function claimRewards() external {
    User storage user = users[msg.sender];
    require(user.stakedAmount > 0, "No staked amount");

    uint256 pendingRewards = calculatePendingRewards(msg.sender);
    require(pendingRewards > 0, "No rewards to claim");

    user.rewards += pendingRewards;
    user.lastUpdateTime = block.timestamp;

    require(IERC20(stakingToken).transfer(msg.sender, pendingRewards), "Token transfer failed");

    user.rewards = 0; 
}


        function calculatePendingRewards(address user) public view returns (uint256) {
        User storage staker = users[user];
        uint256 stakingDuration = block.timestamp - staker.lastUpdateTime;

      
        uint256 baseReward = staker.stakedAmount.mul(stakingRatePerSecond).mul(stakingDuration);

        
        uint256 reducedReward = baseReward.mul(3).div(reductionFactor); 

        return reducedReward;
    }

    function updateStakingRatePerSecond(uint256 newRate) external onlyOwner {
        stakingRatePerSecond = newRate;
    }
    function updateReductionFactor(uint256 newFactor) external onlyOwner {
        reductionFactor = newFactor;
    }

    function setStakingToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Invalid token address");
        stakingToken = newToken;
    }
}