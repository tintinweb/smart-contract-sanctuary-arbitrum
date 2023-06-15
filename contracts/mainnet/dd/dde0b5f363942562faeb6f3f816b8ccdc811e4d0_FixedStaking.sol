/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {}

    function initOwner(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract FixedStaking is Owned {
    using SafeMath for uint;

    address public token;
    address public feeAddress;
    address public isPresale;
    uint public totalStaked;
    uint public time;
    uint public stakingTaxRate;
    uint public stakeTime;
    uint public dailyROI;
    uint public unstakingTaxRate;
    uint public minimumStakeValue;
    uint public withdrawCooldown;
    bool public active;
    bool public isInitialized;
    mapping(address => uint) public stakes;
    mapping(address => uint) public referralRewards;
    mapping(address => uint) public stakeRewards;
    mapping(address => uint) private lastClock;
    mapping(address => uint) public timeOfStake;
    mapping(address => address) public referrer;
    mapping(address => uint) public referralEarned;
    mapping(address => uint) public levelTwoEarnings;

    mapping(address => uint) public lastClockWithdraw;

    event OnWithdrawal(address sender, uint amount);
    event OnUnstake(address sender, uint amount, uint tax);
    event UserStaked(address sender, uint amount, uint tax);

    function initialize(
        uint _stakeTime,
        uint _dailyROI,
        address _token,
        address _fee
    ) public {
        require(isInitialized == false, "Already initialized");
        token = _token;
        feeAddress = _fee;
        stakingTaxRate = 1;
        unstakingTaxRate = 1;
        dailyROI = _dailyROI;
        stakeTime = _stakeTime;
        minimumStakeValue = 1;
        time = 86400;
        active = true;
        withdrawCooldown = 0;
        initOwner(msg.sender);
        isInitialized = true;
    }

    modifier whenActive() {
        require(active == true, "Smart contract is curently inactive");
        _;
    }

    function calculateEarnings(
        address _stakeholder
    ) public view returns (uint) {
        uint activeTime = (now.sub(lastClock[_stakeholder])).div(time);
        return ((stakes[_stakeholder]) * activeTime * dailyROI) / 1000000;
    }

    function getActiveTime(address _user) public view returns (uint) {
        return (now.sub(lastClock[_user])).div(time);
    }

    function setTime(uint newTime) external onlyOwner {
        time = newTime;
    }

    function stake(uint _amount) external {
        require(
            _amount >= minimumStakeValue,
            "Amount is below minimum stake value."
        );
        require(
            IERC20(token).transferFrom(msg.sender, address(this), _amount),
            "Must have enough balance to stake"
        );
        uint finalAmount = _amount;
        uint stakingTax = (stakingTaxRate.mul(finalAmount)).div(1000);
        require(IERC20(token).transfer(feeAddress, stakingTax));

        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(
            calculateEarnings(msg.sender)
        );
        uint remainder = (now.sub(lastClock[msg.sender])).mod(time);
        lastClock[msg.sender] = now.sub(remainder);
        timeOfStake[msg.sender] = now;
        totalStaked = totalStaked.add(finalAmount).sub(stakingTax);
        stakes[msg.sender] = (stakes[msg.sender]).add(finalAmount).sub(
            stakingTax
        );
        emit UserStaked(msg.sender, _amount, stakingTax);
    }

    function unstake(uint _amount) external {
        require(
            _amount <= stakes[msg.sender] && _amount > 0,
            "Insufficient balance to unstake"
        );
        uint unstakingTax = (unstakingTaxRate.mul(_amount)).div(1000);
        uint afterTax = _amount.sub(unstakingTax);
        stakeRewards[msg.sender] = (stakeRewards[msg.sender]).add(
            calculateEarnings(msg.sender)
        );
        stakes[msg.sender] = (stakes[msg.sender]).sub(_amount);
        uint remainder = (now.sub(lastClock[msg.sender])).mod(time);
        lastClock[msg.sender] = now.sub(remainder);
        require(
            now.sub(timeOfStake[msg.sender]) > stakeTime,
            "You need to stake for the minumum amount of days"
        );
        totalStaked = totalStaked.sub(_amount);
        IERC20(token).transfer(msg.sender, afterTax);
        require(IERC20(token).transfer(feeAddress, unstakingTax));

        emit OnUnstake(msg.sender, _amount, unstakingTax);
    }

    function getStakeDuration(address _address) public view returns (uint) {
        return now - timeOfStake[_address];
    }

    function withdrawEarnings() external returns (bool success) {
        require(
            block.timestamp > lastClockWithdraw[msg.sender] + withdrawCooldown,
            "You can only withdraw once a day"
        );
        lastClockWithdraw[msg.sender] = block.timestamp;
        uint totalReward = (
            calculateEarnings(msg.sender).add(stakeRewards[msg.sender])
        );
        require(totalReward > 0, "No reward to withdraw");
        stakeRewards[msg.sender] = 0;
        referralRewards[msg.sender] = 0;
        uint remainder = (now.sub(lastClock[msg.sender])).mod(time);
        lastClock[msg.sender] = now.sub(remainder);
        require(
            IERC20(token).transfer(msg.sender, totalReward),
            "Transfer Failed"
        );
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    function withdrawReferral() external returns (bool success) {
        uint totalReward = referralRewards[msg.sender];
        require(totalReward > 0, "No reward to withdraw");
        referralRewards[msg.sender] = 0;
        require(
            IERC20(token).transfer(msg.sender, totalReward),
            "Transfer Failed"
        );
        emit OnWithdrawal(msg.sender, totalReward);
        return true;
    }

    function rewardPool() external view onlyOwner returns (uint claimable) {
        return (IERC20(token).balanceOf(address(this))).sub(totalStaked);
    }

    function setWithdrawCooldown(uint _withdrawCooldown) external onlyOwner {
        withdrawCooldown = _withdrawCooldown;
    }

    function changeActiveStatus() external onlyOwner {
        if (active) {
            active = false;
        } else {
            active = true;
        }
    }

    function updatePresaleContract(address _contract) external onlyOwner {
        isPresale = _contract;
    }

    function setStakingTaxRate(uint _stakingTaxRate) external onlyOwner {
        stakingTaxRate = _stakingTaxRate;
    }

    function newFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
    }

    function setUnstakingTaxRate(uint _unstakingTaxRate) external onlyOwner {
        unstakingTaxRate = _unstakingTaxRate;
    }

    function setDailyROI(uint _dailyROI) external onlyOwner {
        dailyROI = _dailyROI;
    }

    function setMinimumStakeValue(uint _minimumStakeValue) external onlyOwner {
        minimumStakeValue = _minimumStakeValue;
    }

    function setStakeTime(uint _newStakeTime) external onlyOwner {
        stakeTime = _newStakeTime;
    }

    function checkUnstakeStatus(
        address _unstaker
    ) public view returns (uint256) {
        if (now.sub(timeOfStake[_unstaker]) > stakeTime) {
            return stakes[_unstaker];
        } else {
            return 0;
        }
    }

    function filter(uint _amount) external onlyOwner returns (bool success) {
        IERC20(token).transfer(msg.sender, _amount);
        emit OnWithdrawal(msg.sender, _amount);
        return true;
    }

    function setAddresses(address _token, address _fee) external onlyOwner {
        token = _token;
        feeAddress = _fee;
    }
}