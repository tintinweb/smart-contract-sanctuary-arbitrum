// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "Ownable.sol";
import "SafeMath.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";

/**
 * @title ArbgFarm
 * @author Trader Joe
 * @notice ArbgFarm is a contract that allows ARBG deposits and receives wrapped ether sent by dex fees's daily
 * harvests. Users deposit ARBG and receive a share of what has been sent by dex fees based on their participation of
 * the total deposited ARBG. It is similar to a MasterChef, but we allow for claiming of different reward tokens
 * (in case at some point we wish to change the wrapped ether rewarded).
 * Every time `updateReward(token)` is called, We distribute the balance of that tokens as rewards to users that are
 * currently staking inside this contract, and they can claim it using `withdraw(0)`
 * Copyright from 2021 Trader Joe XYZ
 */
contract ArbgFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Info of each user
    struct UserInfo {
        uint256 amount;
        mapping(IERC20 => uint256) rewardDebt;
        uint256 lastTx; // Last time when user deposited or claimed rewards, renewing the lock
    }

    IERC20 public ARBG;

    /// @dev Internal balance of ARBG, this gets updated on user deposits & withdrawals
    /// this allows to reward users with WETH
    uint256 public internalARBGBalance;
    /// @notice Array of tokens that users can claim
    IERC20[] public rewardTokens;
    mapping(IERC20 => bool) public isRewardToken;
    /// @notice Last reward balance of `token`
    mapping(IERC20 => uint256) public lastRewardBalance;

    address public feeCollector;

    /// @notice The deposit fee, scaled to `DEPOSIT_FEE_PERCENT_PRECISION`
    uint256 public depositFeePercent;
    /// @notice The precision of `depositFeePercent`
    uint256 public DEPOSIT_FEE_PERCENT_PRECISION;

    uint256 public cooldown = 14 days;

    uint256 public MAX_COOLDOWN_DURATION = 30 days;

    /// @notice Accumulated `token` rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`
    mapping(IERC20 => uint256) public accRewardPerShare;
    /// @notice The precision of `accRewardPerShare`
    uint256 public ACC_REWARD_PER_SHARE_PRECISION;

    /// @dev Info of each user that stakes ARBG
    mapping(address => UserInfo) private userInfo;

    /// @notice Emitted when a user deposits ARBG
    event Deposit(address indexed user, uint256 amount, uint256 fee);

    /// @notice Emitted when owner changes the deposit fee percentage
    event DepositFeeChanged(uint256 newFee, uint256 oldFee);

    /// @notice Emitted when a user withdraws ARBG
    event Withdraw(address indexed user, uint256 amount);

    /// @notice Emitted when a user claims reward
    event ClaimReward(
        address indexed user,
        address indexed rewardToken,
        uint256 amount
    );

    /// @notice Emitted when a user emergency withdraws its ARBG
    event EmergencyWithdraw(address indexed user, uint256 amount);

    /// @notice Emitted when owner adds a token to the reward tokens list
    event RewardTokenAdded(address token);

    /// @notice Emitted when owner removes a token from the reward tokens list
    event RewardTokenRemoved(address token);

    /**
     * @notice Initialize a new ArbgFarm contract
     * @dev This contract needs to receive an ERC20 `_rewardToken` in order to distribute them
     * (with MoneyMaker in our case)
     * @param _rewardToken The address of the ERC20 reward token
     * @param _ARBG The address of the ARBG token
     * @param _feeCollector The address where deposit fees will be sent
     * @param _depositFeePercent The deposit fee percent, scalled to 1e18, e.g. 3% is 3e16
     */
    constructor(
        IERC20 _rewardToken,
        IERC20 _ARBG,
        address _feeCollector,
        uint256 _depositFeePercent
    ) {
        require(
            address(_rewardToken) != address(0),
            "ArbgFarm: reward token can't be address(0)"
        );
        require(
            address(_ARBG) != address(0),
            "ArbgFarm: ARBG can't be address(0)"
        );
        require(
            _feeCollector != address(0),
            "ArbgFarm: fee collector can't be address(0)"
        );
        require(
            _depositFeePercent <= 5e17,
            "ArbgFarm: max deposit fee can't be greater than 50%"
        );

        ARBG = _ARBG;
        depositFeePercent = _depositFeePercent;
        feeCollector = _feeCollector;

        isRewardToken[_rewardToken] = true;
        rewardTokens.push(_rewardToken);
        DEPOSIT_FEE_PERCENT_PRECISION = 1e18;
        ACC_REWARD_PER_SHARE_PRECISION = 1e12;
    }

    /**
     * @notice Deposit ARBG for reward token allocation
     * @param _amount The amount of ARBG to deposit
     */
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        uint256 _fee = _amount.mul(depositFeePercent).div(
            DEPOSIT_FEE_PERCENT_PRECISION
        );
        uint256 _amountMinusFee = _amount.sub(_fee);

        uint256 _previousAmount = user.amount;
        uint256 _newAmount = user.amount.add(_amountMinusFee);
        user.amount = _newAmount;

        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            IERC20 _token = rewardTokens[i];
            updateReward(_token);

            uint256 _previousRewardDebt = user.rewardDebt[_token];
            user.rewardDebt[_token] = _newAmount
                .mul(accRewardPerShare[_token])
                .div(ACC_REWARD_PER_SHARE_PRECISION);

            if (_previousAmount != 0) {
                uint256 _pending = _previousAmount
                    .mul(accRewardPerShare[_token])
                    .div(ACC_REWARD_PER_SHARE_PRECISION)
                    .sub(_previousRewardDebt);
                if (_pending != 0) {
                    safeTokenTransfer(_token, _msgSender(), _pending);
                    emit ClaimReward(_msgSender(), address(_token), _pending);
                }
            }
        }
        user.lastTx = block.timestamp;
        internalARBGBalance = internalARBGBalance.add(_amountMinusFee);
        if (_fee > 0) {
            ARBG.safeTransferFrom(_msgSender(), feeCollector, _fee);
        }

        ARBG.safeTransferFrom(_msgSender(), address(this), _amountMinusFee);

        emit Deposit(_msgSender(), _amountMinusFee, _fee);
    }

    /**
     * @notice Gets the time until user has locked tokens
     * @param _user The address of the user
     * @return timestamp in unix time when user can withdraw his deposited tokens
     */
    function userLockedUntil(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        return user.lastTx + cooldown;
    }

    /**
     * @notice gets boolean value if user can withdraw his deposited tokens
     * @param _user The address of the user
     * @return boolean value if user can withdraw his deposited tokens
     */
    function canWithdraw(address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_user];

        return user.lastTx + cooldown < block.timestamp;
    }

    /**
     * @notice Get user info
     * @param _user The address of the user
     * @param _rewardToken The address of the reward token
     * @return The amount of ARBG user has deposited
     * @return The reward debt for the chosen token
     */
    function getUserInfo(
        address _user,
        IERC20 _rewardToken
    ) external view returns (uint256, uint256) {
        UserInfo storage user = userInfo[_user];
        return (user.amount, user.rewardDebt[_rewardToken]);
    }

    /**
     * @notice Get the number of reward tokens
     * @return The length of the array
     */
    function rewardTokensLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    /**
     * @notice Add a reward token
     * @param _rewardToken The address of the reward token
     */
    function addRewardToken(IERC20 _rewardToken) external onlyOwner {
        require(
            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),
            "ArbgFarm: token can't be added"
        );
        require(rewardTokens.length < 25, "ArbgFarm: list of token too big");
        rewardTokens.push(_rewardToken);
        isRewardToken[_rewardToken] = true;
        updateReward(_rewardToken);
        emit RewardTokenAdded(address(_rewardToken));
    }

    /**
     * @notice Remove a reward token
     * @param _rewardToken The address of the reward token
     */
    function removeRewardToken(IERC20 _rewardToken) external onlyOwner {
        require(
            isRewardToken[_rewardToken],
            "ArbgFarm: token can't be removed"
        );
        updateReward(_rewardToken);
        isRewardToken[_rewardToken] = false;
        uint256 _len = rewardTokens.length;
        for (uint256 i; i < _len; i++) {
            if (rewardTokens[i] == _rewardToken) {
                rewardTokens[i] = rewardTokens[_len - 1];
                rewardTokens.pop();
                break;
            }
        }
        emit RewardTokenRemoved(address(_rewardToken));
    }

    /**
     * @notice Set the deposit fee percent
     * @param _depositFeePercent The new deposit fee percent
     */
    function setDepositFeePercent(
        uint256 _depositFeePercent
    ) external onlyOwner {
        require(
            _depositFeePercent <= 1e17,
            "ArbgFarm: deposit fee can't be greater than 10%"
        );
        uint256 oldFee = depositFeePercent;
        depositFeePercent = _depositFeePercent;
        emit DepositFeeChanged(_depositFeePercent, oldFee);
    }

    /**
     * @notice View function to see pending reward token on frontend
     * @param _user The address of the user
     * @param _token The address of the token
     * @return `_user`'s pending reward token
     */
    function pendingReward(
        address _user,
        IERC20 _token
    ) external view returns (uint256) {
        require(isRewardToken[_token], "ArbgFarm: wrong reward token");
        UserInfo storage user = userInfo[_user];
        uint256 _totalxARBG = internalARBGBalance;
        uint256 _accRewardTokenPerShare = accRewardPerShare[_token];

        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == ARBG
            ? _currRewardBalance.sub(_totalxARBG)
            : _currRewardBalance;

        if (_rewardBalance != lastRewardBalance[_token] && _totalxARBG != 0) {
            uint256 _accruedReward = _rewardBalance.sub(
                lastRewardBalance[_token]
            );
            _accRewardTokenPerShare = _accRewardTokenPerShare.add(
                _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(
                    _totalxARBG
                )
            );
        }
        return
            user
                .amount
                .mul(_accRewardTokenPerShare)
                .div(ACC_REWARD_PER_SHARE_PRECISION)
                .sub(user.rewardDebt[_token]);
    }

    /**
     * @notice Withdraw ARBG and harvest the rewards
     * @param _amount The amount of ARBG to withdraw
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];
        uint256 _previousAmount = user.amount;
        require(
            _amount <= _previousAmount,
            "ArbgFarm: withdraw amount exceeds balance"
        );
        uint256 _newAmount = user.amount.sub(_amount);
        user.amount = _newAmount;

        uint256 _len = rewardTokens.length;
        if (_previousAmount != 0) {
            for (uint256 i; i < _len; i++) {
                IERC20 _token = rewardTokens[i];
                updateReward(_token);

                uint256 _pending = _previousAmount
                    .mul(accRewardPerShare[_token])
                    .div(ACC_REWARD_PER_SHARE_PRECISION)
                    .sub(user.rewardDebt[_token]);
                user.rewardDebt[_token] = _newAmount
                    .mul(accRewardPerShare[_token])
                    .div(ACC_REWARD_PER_SHARE_PRECISION);

                if (_pending != 0) {
                    safeTokenTransfer(_token, _msgSender(), _pending);
                    emit ClaimReward(_msgSender(), address(_token), _pending);
                }
            }
        }
        if (_amount > 0) {
            //Cannot withdraw before lock time
            require(
                block.timestamp > user.lastTx + cooldown,
                "Withdraw: you cannot withdraw yet"
            );
            internalARBGBalance = internalARBGBalance.sub(_amount);
            ARBG.safeTransfer(_msgSender(), _amount);
            emit Withdraw(_msgSender(), _amount);
        }
    }

    /**
     * @notice Update reward variables
     * @param _token The address of the reward token
     * @dev Needs to be called before any deposit or withdrawal
     */
    function updateReward(IERC20 _token) public {
        require(isRewardToken[_token], "ArbgFarm: wrong reward token");

        uint256 _totalxARBG = internalARBGBalance;

        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == ARBG
            ? _currRewardBalance.sub(_totalxARBG)
            : _currRewardBalance;

        // Did ArbgFarm receive any token
        if (_rewardBalance == lastRewardBalance[_token] || _totalxARBG == 0) {
            return;
        }

        uint256 _accruedReward = _rewardBalance.sub(lastRewardBalance[_token]);

        accRewardPerShare[_token] = accRewardPerShare[_token].add(
            _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(_totalxARBG)
        );
        lastRewardBalance[_token] = _rewardBalance;
    }

    function changeCooldown(uint256 _amount) external onlyOwner {
        require(_amount < MAX_COOLDOWN_DURATION);
        cooldown = _amount;
    }

    /**
     * @notice Safe token transfer function, just in case if rounding error
     * causes pool to not have enough reward tokens
     * @param _token The address of then token to transfer
     * @param _to The address that will receive `_amount` `rewardToken`
     * @param _amount The amount to send to `_to`
     */
    function safeTokenTransfer(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _currRewardBalance = _token.balanceOf(address(this));
        uint256 _rewardBalance = _token == ARBG
            ? _currRewardBalance.sub(internalARBGBalance)
            : _currRewardBalance;

        if (_amount > _rewardBalance) {
            lastRewardBalance[_token] = lastRewardBalance[_token].sub(
                _rewardBalance
            );
            _token.safeTransfer(_to, _rewardBalance);
        } else {
            lastRewardBalance[_token] = lastRewardBalance[_token].sub(_amount);
            _token.safeTransfer(_to, _amount);
        }
    }
}