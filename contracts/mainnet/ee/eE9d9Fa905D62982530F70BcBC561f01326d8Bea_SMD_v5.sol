// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import {Context} from "lib/openzeppelin-contracts/contracts/utils/Context.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/**
 * @title Farming
 * @notice Seedify's farming contract: stake LP token and earn rewards.
 * @custom:audit This contract is NOT made to be used with deflationary tokens at all.
 */
contract SMD_v5 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_PER_HOUR = 3600; // 60 * 60

    /// @notice LP token address to deposit to earn rewards.
    address public tokenAddress;
    /// @notice token address to in which rewards will be paid in.
    address public rewardTokenAddress;
    /// @notice total amount of {tokenAddress} staked in the contract over its whole existence.
    uint256 public totalStaked;
    /**
     * @notice current amount of {tokenAddress} staked in the contract accross all periods. Use to
     *         calculate lost LP tokens.
     */
    uint256 public currentStakedBalance;
    /// @notice amount of {tokenAddress} staked in the contract for the current period.
    uint256 public stakedBalanceCurrPeriod;
    /// @notice should be the amount of rewards available in the contract accross all periods.
    uint256 public rewardBalance;
    /// @notice should be the amount of rewards for current period.
    uint256 public totalReward;

    /**
     * @notice start date of current period.
     * @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
     */
    uint256 public startingDate;
    /**
     * @notice end date of current period.
     * @dev expressed in UNIX timestamp. Will be compareed to block.timestamp.
     */
    uint256 public endingDate;
    /**
     * @notice periodCounter is used to keep track of the farming periods, which allow participants to
     *         earn a certain amount of rewards by staking their LP for a certain period of time. Then,
     *         a new period can be opened with a different or equal amount to earn.
     * @dev counts the amount of farming periods.
     */
    uint256 public periodCounter;
    /**
     * @notice should be the amount of rewards per wei of deposited LP token {tokenAddress} for current
     *         period.
     */
    uint256 public accShare;
    /// @notice timestamp of at which shares have been updated at last, expressed in UNIX timestamp.
    uint256 public lastSharesUpdateTime;
    /**
     * @notice amount of participant in current period.
     * @dev {setNewPeriod} will reset this value to 0.
     */
    uint256 public totalParticipants;
    /// @dev expressed in hours, e.g. 7 days = 24 * 7 = 168.
    uint256 public lockDuration;
    /**
     * @notice whether prevent or not, wallets from staking, renewing staking, viewing old rewards,
     *         claiming rewards (old and current period) and withdrawing. Only admin functions are allowed.
     */
    bool public isPaused;

    /// @notice should be the last transfered token which is either {tokenAddress} or {rewardTokenAddress}.
    IERC20 internal _erc20Interface;

    /**
     * @notice struct which represent deposits made by a wallet based on a specific period. Each period has
     *         its own deposit data.
     *
     * @param amount amount of LP {tokenAddress} deposited accross all period.
     * @param latestStakeAt timestamp at which the latest stake has been made by the wallet for current
     *        period. Maturity date will be re-calculated from this timestamp which means each time the
     *        wallet stakes a new amount it has to wait for `lockDuration` before being able to withdraw.
     * @param latestClaimAt latest timestamp at which the wallet claimed their rewards.
     * @param userAccShare should be the amount of rewards per wei of deposited LP token {tokenAddress}
     *        accross all periods.
     * @param currentPeriod should be the lastest periodCounter at which the wallet participated.
     */
    struct Deposits {
        uint256 amount;
        uint256 latestStakeAt;
        uint256 latestClaimAt;
        uint256 userAccShare;
        uint256 currentPeriod;
    }

    /**
     * @notice struct which should represent the details of ended periods.
     * @dev period 0 should contain nullish values.
     *
     * @param periodCounter counter to track the period id.
     * @param accShare should be the amount of rewards per wei of deposited LP token {tokenAddress} for
                       this ended period.
     * @param rewPerSecond should be the amount of rewards per second for this ended period.
     * @param startingDate should be the start date of this ended period.
     * @param endingDate should be the end date of this ended period.
     * @param rewards should be the total amount of rewards left until this ended period, which might
     *        include previous rewards from previous closed periods.
     */
    struct PeriodDetails {
        uint256 periodCounter;
        uint256 accShare;
        uint256 rewPerSecond;
        uint256 startingDate;
        uint256 endingDate;
        uint256 rewards;
    }

    /// @notice should be the deposit data made by a wallet for accorss period if the wallet called {renew}.
    mapping(address => Deposits) private deposits;

    /// @notice whether a wallet has staked or not.
    mapping(address => bool) public isPaid;
    /// @notice whether a wallet has staked some LP {tokenAddress} or not.
    mapping(address => bool) public hasStaked;
    /// @notice should be the details of ended periods.
    mapping(uint256 => PeriodDetails) public endAccShare;

    event NewPeriodSet(
        uint256 periodCounter,
        uint256 startDate,
        uint256 endDate,
        uint256 lockDuration,
        uint256 rewardAmount
    );
    event Paused(
        uint256 indexed periodCounter,
        uint256 indexed totalParticipants,
        uint256 indexed currentStakedBalance,
        uint256 totalReward
    );
    event UnPaused(
        uint256 indexed periodCounter,
        uint256 indexed totalParticipants,
        uint256 indexed currentStakedBalance,
        uint256 totalReward
    );
    event PeriodExtended(
        uint256 periodCounter,
        uint256 endDate,
        uint256 rewards
    );
    event Staked(
        address indexed token,
        address indexed staker_,
        uint256 stakedAmount_
    );
    event PaidOut(
        address indexed token,
        address indexed rewardToken,
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    /**
     * @notice by default the contract is paused, so the owner can set the first period without anyone
     *         staking before it opens.
     * @param _tokenAddress LP token address to deposit to earn rewards.
     * @param _rewardTokenAddress token address into which rewards will be paid in.
     */
    constructor(address _tokenAddress, address _rewardTokenAddress) Ownable() {
        require(_tokenAddress != address(0), "Zero token address");
        tokenAddress = _tokenAddress;
        require(
            _rewardTokenAddress != address(0),
            "Zero reward token address"
        );
        rewardTokenAddress = _rewardTokenAddress;
        isPaused = true;
    }

    /**
     * @notice Config new period details according to {setNewPeriod} parameters.
     *
     * @param _start Seconds at which the period starts - in UNIX timestamp.
     * @param _end Seconds at which the period ends - in UNIX timestamp.
     * @param _lockDuration Duration in hours to wait before being able to withdraw staked LP.
     */
    function __configNewPeriod(
        uint256 _start,
        uint256 _end,
        uint256 _lockDuration
    ) private {
        require(totalReward > 0, "Add rewards for this periodCounter");
        startingDate = _start;
        endingDate = _end;
        lockDuration = _lockDuration;
        periodCounter++;
        lastSharesUpdateTime = _start;
    }

    /// @notice Add rewards to the contract and transfer them in it.
    function __addReward(
        uint256 _rewardAmount
    )
        private
        hasAllowance(msg.sender, _rewardAmount, rewardTokenAddress)
        returns (bool)
    {
        totalReward = totalReward.add(_rewardAmount);
        rewardBalance = rewardBalance.add(_rewardAmount);
        if (!__payMe(msg.sender, _rewardAmount, rewardTokenAddress)) {
            return false;
        }
        return true;
    }

    /// save the details of the last ended period.
    function __saveOldPeriod() private {
        // only save old period if it has not been saved before
        if (endAccShare[periodCounter].startingDate == 0) {
            endAccShare[periodCounter] = PeriodDetails(
                periodCounter,
                accShare,
                rewPerSecond(),
                startingDate,
                endingDate,
                rewardBalance
            );
        }
    }

    /// reset contracts's deposit data at the end of period and pause it.
    function __reset() private {
        totalReward = 0;
        stakedBalanceCurrPeriod = 0;
        totalParticipants = 0;
    }

    /**
     * @notice set the start and end timestamp for the new period and add rewards to be
     *         earned within this period. Previous period must have ended, otherwise use
     *         {extendCurrentPeriod} to update current period.
     *         also calls {__addReward} to add rewards to this contract so be sure to approve this contract
     *         to spend your ERC20 before calling this function.
     *
     * @param _rewardAmount Amount of rewards to be earned within this period.
     * @param _start Seconds at which the period starts - in UNIX timestamp.
     * @param _end Seconds at which the period ends - in UNIX timestamp.
     * @param _lockDuration Duration in hours to wait before being able to withdraw staked LP.
     */
    function setNewPeriod(
        uint256 _rewardAmount,
        uint256 _start,
        uint256 _end,
        uint256 _lockDuration
    ) external onlyOwner returns (bool) {
        require(
            _start > block.timestamp,
            "Start should be more than block.timestamp"
        );
        require(_end > _start, "End block should be greater than start");
        require(_rewardAmount > 0, "Reward must be positive");
        require(block.timestamp > endingDate, "Wait till end of this period");

        __updateShare();
        __saveOldPeriod();

        __reset();
        bool rewardAdded = __addReward(_rewardAmount);

        require(rewardAdded, "Rewards error");

        __configNewPeriod(_start, _end, _lockDuration);

        emit NewPeriodSet(
            periodCounter,
            _start,
            _end,
            _lockDuration,
            _rewardAmount
        );

        isPaused = false;

        return true;
    }

    function pause() external onlyOwner {
        isPaused = true;

        emit Paused(
            periodCounter,
            totalParticipants,
            currentStakedBalance,
            totalReward
        );
    }

    function unPause() external onlyOwner {
        isPaused = false;

        emit UnPaused(
            periodCounter,
            totalParticipants,
            currentStakedBalance,
            totalReward
        );
    }

    /// @notice update {accShare} and {lastSharesUpdateTime} for current period.
    function __updateShare() private {
        if (block.timestamp <= lastSharesUpdateTime) {
            return;
        }
        if (stakedBalanceCurrPeriod == 0) {
            lastSharesUpdateTime = block.timestamp;
            return;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastSharesUpdateTime);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastSharesUpdateTime);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        accShare = accShare.add(
            (rewards.mul(1e6).div(stakedBalanceCurrPeriod))
        );
        if (block.timestamp >= endingDate) {
            lastSharesUpdateTime = endingDate;
        } else {
            lastSharesUpdateTime = block.timestamp;
        }
    }

    /// @notice calculate rewards to get per second for current period.
    function rewPerSecond() public view returns (uint256) {
        if (totalReward == 0 || rewardBalance == 0) return 0;
        uint256 rewardPerSecond = totalReward.div(
            (endingDate.sub(startingDate))
        );
        return (rewardPerSecond);
    }

    function stake(
        uint256 amount
    ) external hasAllowance(msg.sender, amount, tokenAddress) returns (bool) {
        require(!isPaused, "Contract is paused");
        require(
            block.timestamp >= startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(amount > 0, "Can't stake 0 amount");
        return (__stake(msg.sender, amount));
    }

    function __stake(address from, uint256 amount) private returns (bool) {
        __updateShare();
        // if never staked, create new deposit
        if (!hasStaked[from]) {
            deposits[from] = Deposits({
                amount: amount,
                latestStakeAt: block.timestamp,
                latestClaimAt: block.timestamp,
                userAccShare: accShare,
                currentPeriod: periodCounter
            });
            totalParticipants = totalParticipants.add(1);
            hasStaked[from] = true;
        }
        // otherwise update deposit details and claim pending rewards
        else {
            // if user has staked in previous period, renew and claim rewards from previous period
            if (deposits[from].currentPeriod != periodCounter) {
                bool renew_ = __renew(from);
                require(renew_, "Error renewing");
            }
            // otherwise on each new stake claim pending rewards of current period
            else {
                bool claim = __claimRewards(from);
                require(claim, "Error paying rewards");
            }

            uint256 userAmount = deposits[from].amount;

            deposits[from] = Deposits({
                amount: userAmount.add(amount),
                latestStakeAt: block.timestamp,
                latestClaimAt: block.timestamp,
                userAccShare: accShare,
                currentPeriod: periodCounter
            });
        }
        stakedBalanceCurrPeriod = stakedBalanceCurrPeriod.add(amount);
        totalStaked = totalStaked.add(amount);
        currentStakedBalance += amount;
        if (!__payMe(from, amount, tokenAddress)) {
            return false;
        }
        emit Staked(tokenAddress, from, amount);
        return true;
    }

    /// @notice get user deposit details
    function userDeposits(
        address from
    ) external view returns (Deposits memory deposit) {
        return deposits[from];
    }

    /// @custom:audit seems like a duplicate of {hasStaked}.
    function fetchUserShare(address from) public view returns (uint256) {
        require(hasStaked[from], "No stakes found for user");
        if (stakedBalanceCurrPeriod == 0) {
            return 0;
        }
        require(
            deposits[from].currentPeriod == periodCounter,
            "Please renew in the active valid periodCounter"
        );
        uint256 userAmount = deposits[from].amount;
        require(userAmount > 0, "No stakes available for user"); //extra check
        return 1;
    }

    /// @dev claim pending rewards of current period.
    function claimRewards() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(fetchUserShare(msg.sender) > 0, "No stakes found for user");
        return (__claimRewards(msg.sender));
    }

    function __claimRewards(address from) private returns (bool) {
        uint256 userAccShare = deposits[from].userAccShare;
        __updateShare();
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare).div(1e6)).sub(rewDebt);
        require(rew > 0, "No rewards generated");
        require(rew <= rewardBalance, "Not enough rewards in the contract");
        deposits[from].userAccShare = accShare;
        deposits[from].latestClaimAt = block.timestamp;
        rewardBalance = rewardBalance.sub(rew);
        bool payRewards = __payDirect(from, rew, rewardTokenAddress);
        require(payRewards, "Rewards transfer failed");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, rew);
        return true;
    }

    /**
     * @notice Should take into account farming rewards and LP staked from previous periods into the new
     *         current period.
     */
    function renew() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(hasStaked[msg.sender], "No stakings found, please stake");
        require(
            deposits[msg.sender].currentPeriod != periodCounter,
            "Already renewed"
        );
        require(
            block.timestamp > startingDate && block.timestamp < endingDate,
            "Wrong time"
        );
        return (__renew(msg.sender));
    }

    function __renew(address from) private returns (bool) {
        __updateShare();
        if (_viewOldRewards(from) > 0) {
            bool claimed = claimOldRewards();
            require(claimed, "Error paying old rewards");
        }
        deposits[from].currentPeriod = periodCounter;
        deposits[from].latestStakeAt = block.timestamp;
        deposits[from].latestClaimAt = block.timestamp;
        deposits[from].userAccShare = accShare;
        stakedBalanceCurrPeriod = stakedBalanceCurrPeriod.add(
            deposits[from].amount
        );
        totalParticipants = totalParticipants.add(1);
        return true;
    }

    /// @notice get rewards from previous periods for `from` wallet.
    function viewOldRewards(address from) public view returns (uint256) {
        require(!isPaused, "Contract paused");
        require(hasStaked[from], "No stakings found, please stake");

        return _viewOldRewards(from);
    }

    function _viewOldRewards(address from) internal view returns (uint256) {
        if (deposits[from].currentPeriod == periodCounter) {
            return 0;
        }

        uint256 userPeriod = deposits[from].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[from].userAccShare;

        if (deposits[from].latestClaimAt >= endAccShare[userPeriod].endingDate)
            return 0;
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");

        return (rew);
    }

    /// @notice save old period details and claim pending rewards from previous periods.
    function claimOldRewards() public returns (bool) {
        require(!isPaused, "Contract paused");
        require(hasStaked[msg.sender], "No stakings found, please stake");
        require(
            deposits[msg.sender].currentPeriod != periodCounter,
            "Already renewed"
        );

        __saveOldPeriod();

        uint256 userPeriod = deposits[msg.sender].currentPeriod;

        uint256 accShare1 = endAccShare[userPeriod].accShare;
        uint256 userAccShare = deposits[msg.sender].userAccShare;

        require(
            deposits[msg.sender].latestClaimAt <
                endAccShare[userPeriod].endingDate,
            "Already claimed old rewards"
        );
        uint256 amount = deposits[msg.sender].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(accShare1).div(1e6)).sub(rewDebt);

        require(rew <= rewardBalance, "Not enough rewards");
        deposits[msg.sender].latestClaimAt = endAccShare[userPeriod]
            .endingDate;
        rewardBalance = rewardBalance.sub(rew);
        bool paidOldRewards = __payDirect(msg.sender, rew, rewardTokenAddress);
        require(paidOldRewards, "Error paying");
        emit PaidOut(
            tokenAddress,
            rewardTokenAddress,
            msg.sender,
            amount,
            rew
        );
        return true;
    }

    /// @notice should calculate current pending rewards for `from` wallet for current period.
    function calculate(address from) public view returns (uint256) {
        if (fetchUserShare(from) == 0) return 0;
        return (__calculate(from));
    }

    function __calculate(address from) private view returns (uint256) {
        uint256 userAccShare = deposits[from].userAccShare;
        uint256 currentAccShare = accShare;
        //Simulating __updateShare() to calculate rewards
        if (block.timestamp <= lastSharesUpdateTime) {
            return 0;
        }
        if (stakedBalanceCurrPeriod == 0) {
            return 0;
        }

        uint256 secSinceLastPeriod;

        if (block.timestamp >= endingDate) {
            secSinceLastPeriod = endingDate.sub(lastSharesUpdateTime);
        } else {
            secSinceLastPeriod = block.timestamp.sub(lastSharesUpdateTime);
        }

        uint256 rewards = secSinceLastPeriod.mul(rewPerSecond());

        uint256 newAccShare = currentAccShare.add(
            (rewards.mul(1e6).div(stakedBalanceCurrPeriod))
        );
        uint256 amount = deposits[from].amount;
        uint256 rewDebt = amount.mul(userAccShare).div(1e6);
        uint256 rew = (amount.mul(newAccShare).div(1e6)).sub(rewDebt);
        return (rew);
    }

    function emergencyWithdraw() external returns (bool) {
        require(
            block.timestamp >
                deposits[msg.sender].latestStakeAt.add(
                    lockDuration.mul(SECONDS_PER_HOUR)
                ),
            "Can't withdraw before lock duration"
        );
        require(hasStaked[msg.sender], "No stakes available for user");
        require(!isPaid[msg.sender], "Already Paid");
        return (__withdraw(msg.sender, deposits[msg.sender].amount));
    }

    function __withdraw(address from, uint256 amount) private returns (bool) {
        __updateShare();
        deposits[from].amount = deposits[from].amount.sub(amount);
        if (deposits[from].currentPeriod == periodCounter) {
            stakedBalanceCurrPeriod -= amount;
        }
        bool paid = __payDirect(from, amount, tokenAddress);
        require(paid, "Error during withdraw");
        if (deposits[from].amount == 0) {
            isPaid[from] = true;
            hasStaked[from] = false;
            if (deposits[from].currentPeriod == periodCounter) {
                totalParticipants = totalParticipants.sub(1);
            }
            delete deposits[from];
        }

        currentStakedBalance -= amount;

        return true;
    }

    /// Withdraw `amount` deposited LP token after lock duration.
    function withdraw(uint256 amount) external returns (bool) {
        require(!isPaused, "Contract paused");
        require(
            block.timestamp >
                deposits[msg.sender].latestStakeAt.add(
                    lockDuration.mul(SECONDS_PER_HOUR)
                ),
            "Can't withdraw before lock duration"
        );
        require(amount <= deposits[msg.sender].amount, "Wrong value");
        if (deposits[msg.sender].currentPeriod == periodCounter) {
            if (calculate(msg.sender) > 0) {
                bool rewardsPaid = claimRewards();
                require(rewardsPaid, "Error paying rewards");
            }
        }

        if (_viewOldRewards(msg.sender) > 0) {
            bool oldRewardsPaid = claimOldRewards();
            require(oldRewardsPaid, "Error paying old rewards");
        }
        return (__withdraw(msg.sender, amount));
    }

    /**
     * @notice add rewards to current period and extend its runing time.
     * @dev running should be updated based on the amount of rewards added and current rewards per second,
     *      e.g.: 1000 rewards per second, then if we add 1000 rewards then we increase running time by
     *      1 second.
     */
    function extendCurrentPeriod(
        uint256 rewardsToBeAdded
    ) external onlyOwner returns (bool) {
        require(
            block.timestamp > startingDate && block.timestamp < endingDate,
            "No active pool (time)"
        );
        require(rewardsToBeAdded > 0, "Zero rewards");
        bool addedRewards = __payMe(
            msg.sender,
            rewardsToBeAdded,
            rewardTokenAddress
        );
        require(addedRewards, "Error adding rewards");
        endingDate = endingDate.add(rewardsToBeAdded.div(rewPerSecond()));
        totalReward = totalReward.add(rewardsToBeAdded);
        rewardBalance = rewardBalance.add(rewardsToBeAdded);
        emit PeriodExtended(periodCounter, endingDate, rewardsToBeAdded);
        return true;
    }

    /// @notice deposit rewards to this farming contract.
    function __payMe(
        address payer,
        uint256 amount,
        address token
    ) private returns (bool) {
        return __payTo(payer, address(this), amount, token);
    }

    /// @notice should transfer rewards to farming contract.
    function __payTo(
        address allower,
        address receiver,
        uint256 amount,
        address token
    ) private returns (bool) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        _erc20Interface = IERC20(token);
        _erc20Interface.safeTransferFrom(allower, receiver, amount);
        return true;
    }

    /// @notice should pay rewards to `to` wallet and in certain case withdraw deposited LP token.
    function __payDirect(
        address to,
        uint256 amount,
        address token
    ) private returns (bool) {
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        _erc20Interface = IERC20(token);
        _erc20Interface.safeTransfer(to, amount);
        return true;
    }

    /// @notice check whether `allower` has approved this contract to spend at least `amount` of `token`.
    modifier hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        require(
            token == tokenAddress || token == rewardTokenAddress,
            "Invalid token address"
        );
        _erc20Interface = IERC20(token);
        uint256 ourAllowance = _erc20Interface.allowance(
            allower,
            address(this)
        );
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }

    function recoverLostERC20(address token, address to) external onlyOwner {
        if (token == address(0)) revert("Token_Zero_Address");
        if (to == address(0)) revert("To_Zero_Address");

        uint256 amount = IERC20(token).balanceOf(address(this));

        // only retrieve lost {rewardTokenAddress}
        if (token == rewardTokenAddress) amount -= rewardBalance;
        // only retrieve lost LP tokens
        if (token == tokenAddress) amount -= currentStakedBalance;

        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token_Mock is ERC20 {
    constructor() ERC20("MockToken", "MCKT") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}