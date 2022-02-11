pragma solidity 0.8.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract StakingTest is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // 30 day (1 minute), 6% APR. 60 days (2 minutes), 12% APR
    uint256[] public lockupPeriods = [1 minutes, 2 minutes];
    uint256[] public multipliers = [100, 200];
    uint256 public constant BASE_APR = 6; // represent in percent
    bool allowStaking = true;

    address public immutable SPA;
    address public immutable rewardAccount;

    uint256 public totalStakedSPA;
    mapping(address => bool) public isRewardFrozen; // track if a user's reward is frozen due to malicious attempts

    struct DepositProof {
        uint256 amount;
        uint256 liability;
        uint256 startTime;
        uint256 expiryTime;
    }
    mapping(address => DepositProof[]) balances;

    /// Events
    event Staked(address account, uint256 amount);
    event Withdrawn(address account, uint256 amount);
    event WithdrawnWithPenalty(address account, uint256 amount);
    event RewardFrozen(address account, bool status);
    event StakingDisabled();
    event StakingEnabled();

    constructor(address _SPA, address _rewardAccount) {
        assert(lockupPeriods.length == multipliers.length);
        require(_SPA != address(0), "_SPA is zero address");
        require(_rewardAccount != address(0), "_rewardAccount is zero address");
        SPA = _SPA;
        rewardAccount = _rewardAccount;
    }

    /**
     * @dev get number of deposits for an account
     */
    function getNumDeposits(address account) external view returns (uint256) {
        return balances[account].length;
    }

    /**
     * @dev get N-th deposit for an account
     */
    function getDeposits(address account, uint256 index)
        external
        view
        returns (DepositProof memory)
    {
        return balances[account][index];
    }

    function getLiability(
        uint256 deposit,
        uint256 multiplier,
        uint256 lockupPeriod
    ) public view returns (uint256) {
        // calc liability
        return
            (deposit * BASE_APR * multiplier * lockupPeriod) /
            (1 minutes) /
            (100 * 100 * 365); // remember to div by 100 // remember to div by 100
    }

    function setRewardFrozen(address account, bool status) external onlyOwner {
        isRewardFrozen[account] = status;
        emit RewardFrozen(account, status);
    }

    /**
     * @dev allow owner to enable and disable staking.
     */
    function toggleStaking(bool val) external onlyOwner {
        allowStaking = val;
        if (val) {
            emit StakingEnabled();
            return;
        }
        emit StakingDisabled();
    }

    function stake(uint256 amount, uint256 lockPeriod) external nonReentrant {
        require(amount > 0, "cannot stake 0"); // don't allow staking 0

        // Check is staking is enabled
        require(allowStaking, "staking is disabled");

        address account = _msgSender();
        bool isLockPeriodValid = false;
        uint256 multiplier = 1;
        for (uint256 i = 0; i < lockupPeriods.length; i++) {
            if (lockPeriod == lockupPeriods[i]) {
                isLockPeriodValid = true;
                multiplier = multipliers[i];
                break;
            }
        }
        require(isLockPeriodValid, "invalid lock period");
        uint256 liability = getLiability(amount, multiplier, lockPeriod);
        require(
            IERC20(SPA).balanceOf(rewardAccount) >= liability,
            "insufficient budget"
        );

        DepositProof memory deposit = DepositProof({
            amount: amount,
            liability: liability,
            startTime: block.timestamp,
            expiryTime: block.timestamp + lockPeriod
        });
        balances[account].push(deposit);

        totalStakedSPA = totalStakedSPA + deposit.amount;

        IERC20(SPA).safeTransferFrom(account, address(this), amount);
        IERC20(SPA).safeTransferFrom(rewardAccount, address(this), liability);

        emit Staked(account, amount);
    }

    function withdraw(uint256 index) external nonReentrant {
        address account = _msgSender();
        require(index < balances[account].length, "invalid account or index");
        DepositProof memory deposit = balances[account][index];
        require(deposit.expiryTime <= block.timestamp, "not expired");

        // destroy deposit by:
        // replacing index with last one, and pop out the last element
        uint256 last = balances[account].length;
        balances[account][index] = balances[account][last - 1];
        balances[account].pop();

        uint256 withdrawAmount = deposit.liability + deposit.amount;

        if (!isRewardFrozen[account]) {
            IERC20(SPA).safeTransfer(account, withdrawAmount);
            emit Withdrawn(account, withdrawAmount);
        } else {
            IERC20(SPA).safeTransfer(rewardAccount, deposit.liability); // user forfeits reward and reward is sent to reward pool
            IERC20(SPA).safeTransfer(account, deposit.amount);
            emit WithdrawnWithPenalty(account, deposit.amount);
        }
    }
}