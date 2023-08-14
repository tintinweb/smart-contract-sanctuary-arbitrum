pragma solidity 0.8.7;

import "IERC721Receiver.sol";
import "SafeERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import {INonfungiblePositionManager as INFPM, IUniswapV3Factory} from "UniswapV3.sol";

contract SPA_USDs_Farm is Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeERC20 for IERC20;

    // Defines the reward funds for the farm
    // totalLiquidity - amount of liquidity sharing the rewards in the fund
    // rewardsPerSec - the emision rate of the fund
    // accRewardPerShare - the accumulated reward per share
    struct RewardFund {
        uint256 totalLiquidity;
        uint256 rewardsPerSec;
        uint256 accRewardPerShare;
    }

    // Keeps track of a deposit's share in a reward fund.
    // fund id - id of the subscribed reward fund
    // rewardDebt - rewards claimed for a deposit corresponding to
    //              latest accRewardPerShare value of the budget
    // rewardCalimed - rewards claimed for a deposit from the reward fund
    struct Subscription {
        uint8 fundId;
        uint256 rewardDebt;
        uint256 rewardClaimed;
    }

    // Deposit information
    // locked - determines if the deposit is locked or not
    // liquidity - amount of liquidity in the deposit
    // tokenId - maps to uniswap NFT token id
    // startTime - time of deposit
    // expiryDate - expiry time (if deposit is locked)
    // totalRewardsClaimed - total rewards claimed for the deposit
    struct Deposit {
        bool locked;
        uint256 liquidity;
        uint256 tokenId;
        uint256 startTime;
        uint256 expiryDate;
        uint256 totalRewardsClaimed;
    }

    int24 public tickLowerAllowed;
    int24 public tickUpperAllowed;
    bool public isPaused;
    bool public inEmergency;

    // @todo Update the addresses
    address public constant NFPM = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant UNIV3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;

    address public immutable SPAUSDsPool;
    address public immutable SPA;

    // Emergency address
    address public immutable emergencyReturn;
    uint256 public cooldownPeriod;

    /// Reward settings
    RewardFund[] public rewardFunds;
    uint256 public lastFundUpdateTime;
    uint256 public constant PREC = 1e18;
    uint8 public constant COMMON_FUND_ID = 0;
    uint8 public constant LOCKUP_FUND_ID = 1;

    // Keep track of user deposits
    mapping(address => Deposit[]) public deposits;

    // Keep track of reward subscriptions for each
    // @dev A deposit can subscribe to at max 2 reward funds
    // Deposit subscribes to common reward fund by default.
    // Deposit subscribes to lockup reward fund only if user locks the deposit.
    // The key is the tokenId.
    mapping(uint256 => Subscription[]) public subscriptions;

    event Deposited(
        address indexed account,
        bool locked,
        uint256 tokenId,
        uint256 liquidity
    );
    event CooldownInitiated(
        address indexed account,
        uint256 tokenId,
        uint256 expiryDate
    );
    event DepositWithdrawn(
        address indexed account,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 liquidity,
        uint256 totalRewardsClaimed
    );
    event RewardRateUpdated(
        uint8 fundId,
        uint256 oldRewardRate,
        uint256 newRewardRate
    );
    event CooldownPeriodUpdated(
        uint256 oldCooldownPeriod,
        uint256 newCooldownPeriod
    );

    event RewardsClaimed(
        address indexed account,
        uint8 fundId,
        uint256 tokenId,
        uint256 liquidity,
        uint256 fundLiquidity,
        uint256 rewardAmount
    );

    event FundsRecovered(address indexed account, uint256 amount);
    event DepositPaused(bool paused);
    event EmergencyClaim(address indexed account);
    event PoolUnsubscribed(
        address indexed account,
        uint256 depositId,
        uint8 fundId,
        uint256 startTime,
        uint256 endTime,
        uint256 totalRewardsClaimed
    );

    modifier notPaused() {
        require(!isPaused, "Farm is paused");
        _;
    }

    modifier notInEmergency() {
        require(!inEmergency, "Emergency, Please withdraw");
        _;
    }

    /// @dev The _nolockupRewardsPerSec, _lockuprewardsPerSec
    ///     includes the precision.
    constructor(
        address _SPA,
        address _USDs,
        address _emergencyReturn,
        int24 _tickLowerAllowed,
        int24 _tickUpperAllowed,
        uint24 _feeTier,
        uint256 _nolockupRewardsPerSec,
        uint256 _lockuprewardsPerSec
    ) public {
        SPA = _SPA;
        tickLowerAllowed = _tickLowerAllowed;
        tickUpperAllowed = _tickUpperAllowed;
        cooldownPeriod = 21 days;
        emergencyReturn = _emergencyReturn;
        SPAUSDsPool = IUniswapV3Factory(UNIV3_FACTORY).getPool(
            _SPA,
            _USDs,
            _feeTier
        );

        /// Setup common reward fund
        rewardFunds.push(
            RewardFund({
                totalLiquidity: 0,
                rewardsPerSec: _nolockupRewardsPerSec,
                accRewardPerShare: 0
            })
        );

        /// Setup lockup reward fund
        rewardFunds.push(
            RewardFund({
                totalLiquidity: 0,
                rewardsPerSec: _lockuprewardsPerSec,
                accRewardPerShare: 0
            })
        );

        lastFundUpdateTime = block.timestamp;
    }

    /// @notice Function is called when user transfers the NFT to the contract.
    /// @param from The address of the owner.
    /// @param tokenId nft Id generated by uniswap v3.
    /// @param data The data should be the lockup flag (bool).
    function onERC721Received(
        address, // unused variable. not named
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override notPaused returns (bytes4) {
        require(
            _msgSender() == NFPM,
            "UniswapV3Staker::onERC721Received: not a univ3 nft"
        );

        require(data.length > 0, "UniswapV3Staker::onERC721Received: no data");

        bool lockup = abi.decode(data, (bool));

        // update the reward funds
        _updateFarmRewardData();

        // Validate the position and get the liquidity
        uint256 liquidity = _getLiquidity(tokenId);

        // Prepare data to be stored.
        Deposit memory userDeposit = Deposit({
            locked: lockup,
            tokenId: tokenId,
            startTime: block.timestamp,
            expiryDate: 0,
            totalRewardsClaimed: 0,
            liquidity: liquidity
        });

        // @dev Add the deposit to the user's deposit list
        deposits[from].push(userDeposit);
        // Add common fund subscription to the user's deposit
        _subscribeRewardFund(COMMON_FUND_ID, userDeposit.tokenId, liquidity);

        if (lockup) {
            // Add lockup fund subscription to the user's deposit
            _subscribeRewardFund(
                LOCKUP_FUND_ID,
                userDeposit.tokenId,
                liquidity
            );
        }

        emit Deposited(from, lockup, tokenId, liquidity);
        return this.onERC721Received.selector;
    }

    /// @notice Function to lock a staked deposit
    /// @param depositId The id of the deposit to be locked
    /// @dev depositId is corresponding to the user's deposit
    function initiateCooldown(uint256 depositId)
        external
        notInEmergency
        nonReentrant
    {
        address account = _msgSender();
        require(deposits[account].length > depositId, "Deposit does not exist");
        Deposit storage userDeposit = deposits[account][depositId];

        // validate if the deposit is in locked state
        require(userDeposit.locked, "Can not initiate cooldown");

        // update the deposit expiry time & lock status
        userDeposit.expiryDate = block.timestamp + cooldownPeriod;
        userDeposit.locked = false;

        // claim the pending rewards for the user
        _claimRewards(account, depositId);

        // Unsubscribe the deposit from the lockup reward fund
        _unsubscribeRewardFund(LOCKUP_FUND_ID, account, depositId);

        emit CooldownInitiated(
            account,
            userDeposit.tokenId,
            userDeposit.expiryDate
        );
    }

    /// @notice Function to withdraw a deposit from the farm.
    /// @param depositId The id of the deposit to be withdrawn
    function withdraw(uint256 depositId) external nonReentrant {
        address account = _msgSender();
        require(deposits[account].length > depositId, "Deposit does not exist");
        Deposit memory userDeposit = deposits[account][depositId];

        // Check for the withdrawal criteria
        // Note: In case of emergency, skip the cooldown check
        if (!inEmergency) {
            require(!userDeposit.locked, "Please initiate cooldown");
            if (userDeposit.expiryDate > 0) {
                // Cooldown is initiated for the user
                require(
                    userDeposit.expiryDate <= block.timestamp,
                    "Deposit is in cooldown"
                );
            }
        }

        // Compute the user's unclaimed rewards
        _claimRewards(account, depositId);

        // Store the total rewards earned
        uint256 totalRewards = deposits[account][depositId].totalRewardsClaimed;

        // unsubscribe the user from the common reward fund
        _unsubscribeRewardFund(COMMON_FUND_ID, account, depositId);

        // Update the user's deposit list
        deposits[account][depositId] = deposits[account][
            deposits[account].length - 1
        ];
        deposits[account].pop();

        // Transfer the nft back to the user.
        INFPM(NFPM).safeTransferFrom(
            address(this),
            account,
            userDeposit.tokenId
        );

        emit DepositWithdrawn(
            account,
            userDeposit.tokenId,
            userDeposit.startTime,
            block.timestamp,
            userDeposit.liquidity,
            totalRewards
        );
    }

    /// @notice Claim rewards for the user.
    /// @param account The user's address
    /// @param depositId The id of the deposit
    /// @dev Anyone can call this function to claim rewards for the user
    function claimRewards(address account, uint256 depositId)
        external
        notInEmergency
        nonReentrant
    {
        require(deposits[account].length > depositId, "Deposit does not exist");
        _claimRewards(account, depositId);
    }

    /// @notice Claim rewards for the user.
    /// @param depositId The id of the deposit
    function claimRewards(uint256 depositId)
        external
        notInEmergency
        nonReentrant
    {
        address account = _msgSender();
        require(deposits[account].length > depositId, "Deposit does not exist");
        _claimRewards(account, depositId);
    }

    /// @notice Function to compute the total accrued rewards for a deposit
    /// @param account The user's address
    /// @param depositId The id of the deposit
    /// @return The total accrued rewards for the deposit (uint256)
    function computeRewards(address account, uint256 depositId)
        external
        view
        returns (uint256)
    {
        require(deposits[account].length > depositId, "Deposit does not exist");
        Deposit storage userDeposit = deposits[account][depositId];
        Subscription[] storage depositSubs = subscriptions[userDeposit.tokenId];
        RewardFund[] memory funds = rewardFunds;
        uint256 numRewards = depositSubs.length;
        uint256 rewards = 0;

        // In case the reward is not updated
        uint256 time = block.timestamp - lastFundUpdateTime;
        // Update the two reward funds.
        for (uint8 i = 0; i < depositSubs.length; ++i) {
            uint8 fundId = depositSubs[i].fundId;
            funds[fundId].accRewardPerShare +=
                (funds[fundId].rewardsPerSec * time * PREC) /
                funds[fundId].totalLiquidity;

            rewards +=
                ((userDeposit.liquidity * funds[fundId].accRewardPerShare) /
                    PREC) -
                depositSubs[i].rewardDebt;
        }
        return rewards;
    }

    /// @notice get number of deposits for an account
    /// @param account The user's address
    function getNumDeposits(address account) external view returns (uint256) {
        return deposits[account].length;
    }

    /// @notice get number of deposits for an account
    /// @param tokenId The token's id
    function getNumSubscriptions(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return subscriptions[tokenId].length;
    }

    // --------------------- Admin  Functions ---------------------
    /// @notice Recover SPA from the farm in case of EMERGENCY
    /// @dev Shuts down the farm completely
    function declareEmergency() public onlyOwner {
        setRewardsPerSec(COMMON_FUND_ID, 0);
        setRewardsPerSec(LOCKUP_FUND_ID, 0);
        updateCooldownPeriod(0);
        toggleDepositPause();
        inEmergency = true;
        uint256 amount = IERC20(SPA).balanceOf(address(this));
        IERC20(SPA).safeTransfer(emergencyReturn, amount);
        emit FundsRecovered(emergencyReturn, amount);
    }

    /// @notice Function to update reward params for a fund.
    /// @param fundId The id of the reward fund to be updated
    /// @param newRewardRate The new reward rate for the fund (includes the precision)
    function setRewardsPerSec(uint8 fundId, uint256 newRewardRate)
        public
        onlyOwner
    {
        // Update the total spa accumulated rewards here
        _updateFarmRewardData();

        // Update the reward rate
        uint256 oldRewardRate = rewardFunds[fundId].rewardsPerSec;
        rewardFunds[fundId].rewardsPerSec = newRewardRate;

        emit RewardRateUpdated(fundId, oldRewardRate, newRewardRate);
    }

    /// @notice Update the cooldown period
    /// @param newCooldownPeriod The new cooldown period (in seconds)
    function updateCooldownPeriod(uint256 newCooldownPeriod) public onlyOwner {
        uint256 oldCooldownPeriod = cooldownPeriod;
        cooldownPeriod = newCooldownPeriod;
        emit CooldownPeriodUpdated(oldCooldownPeriod, cooldownPeriod);
    }

    /// @notice Pause / UnPause the deposit
    function toggleDepositPause() public onlyOwner {
        isPaused = !isPaused;
        emit DepositPaused(isPaused);
    }

    // -------------------------------------------------------------------

    /// @notice Claim rewards for the user.
    /// @param account The user's address
    /// @param depositId The id of the deposit
    /// @dev NOTE: any function calling this internal
    ///     function should be marked as non-reentrant
    function _claimRewards(address account, uint256 depositId) internal {
        _updateFarmRewardData();

        Deposit storage userDeposit = deposits[account][depositId];
        Subscription[] storage depositSubs = subscriptions[userDeposit.tokenId];

        uint256 totalRewards = 0;
        uint256 numRewards = depositSubs.length;
        uint256[] memory rewards = new uint256[](numRewards);
        // Compute the rewards for each subscription.
        for (uint8 i = 0; i < numRewards; ++i) {
            // rewards = (liquidity * accRewardPerShare) / PREC - rewardDebt
            uint256 accRewards = (userDeposit.liquidity *
                rewardFunds[depositSubs[i].fundId].accRewardPerShare) / PREC;
            rewards[i] = accRewards - depositSubs[i].rewardDebt;
            depositSubs[i].rewardClaimed += rewards[i];
            totalRewards += rewards[i];

            // Update userRewardDebt for the subscritption
            // rewardDebt = liquidity * accRewardPerShare
            depositSubs[i].rewardDebt = accRewards;

            emit RewardsClaimed(
                account,
                depositSubs[i].fundId,
                userDeposit.tokenId,
                userDeposit.liquidity,
                rewardFunds[depositSubs[i].fundId].totalLiquidity,
                rewards[i]
            );
        }

        // Update the total rewards earned for the deposit
        userDeposit.totalRewardsClaimed += totalRewards;

        if (inEmergency) {
            // Record event in case of emergency
            emit EmergencyClaim(account);
        } else {
            // Transfer the rewards to the user
            IERC20(SPA).safeTransfer(account, totalRewards);
        }
    }

    /// @notice Add subscription to the reward fund for a deposit
    /// @param tokenId The tokenId of the deposit
    /// @param fundId The reward fund id
    /// @param liquidity The liquidity of the deposit
    function _subscribeRewardFund(
        uint8 fundId,
        uint256 tokenId,
        uint256 liquidity
    ) internal {
        require(fundId < rewardFunds.length, "Invalid fund id");
        // Subscribe to the reward fund
        // initialize user's reward debt
        require(
            subscriptions[tokenId].length < 2,
            "Can't subscribe more than 2 funds"
        );
        subscriptions[tokenId].push(
            Subscription({
                fundId: fundId,
                rewardDebt: (liquidity *
                    rewardFunds[fundId].accRewardPerShare) / PREC,
                rewardClaimed: 0
            })
        );

        rewardFunds[fundId].totalLiquidity += liquidity;
    }

    /// @notice Unsubscribe a reward fund from a deposit
    /// @param fundId The reward fund id
    /// @param account The user's address
    /// @param depositId The deposit id corresponding to the user
    /// @dev The rewards claimed from the reward fund is persisted in the event
    function _unsubscribeRewardFund(
        uint8 fundId,
        address account,
        uint256 depositId
    ) internal {
        require(fundId < rewardFunds.length, "Invalid fund id");
        Deposit storage userDeposit = deposits[account][depositId];

        // Unsubscribe from the reward fund
        Subscription[] storage depositSubs = subscriptions[userDeposit.tokenId];
        uint256 numFunds = depositSubs.length;
        for (uint256 i = 0; i < numFunds; ++i) {
            if (depositSubs[i].fundId == fundId) {
                // Persist the reward information
                uint256 rewardClaimed = depositSubs[i].rewardClaimed;

                // Delete the subscription from the list
                depositSubs[i] = depositSubs[numFunds - 1];
                depositSubs.pop();

                // Remove the liquidity from the reward fund
                rewardFunds[fundId].totalLiquidity -= userDeposit.liquidity;

                emit PoolUnsubscribed(
                    account,
                    userDeposit.tokenId,
                    fundId,
                    userDeposit.startTime,
                    block.timestamp,
                    rewardClaimed
                );

                break;
            }
        }
    }

    /// @notice Function to update the FarmRewardData for all funds
    function _updateFarmRewardData() internal {
        if (block.timestamp > lastFundUpdateTime) {
            uint256 time = block.timestamp - lastFundUpdateTime;
            // Update the two reward funds.
            for (uint8 i = 0; i < rewardFunds.length; ++i) {
                RewardFund storage fund = rewardFunds[i];
                if (fund.totalLiquidity > 0) {
                    fund.accRewardPerShare +=
                        (fund.rewardsPerSec * time * PREC) /
                        fund.totalLiquidity;
                }
            }
            lastFundUpdateTime = block.timestamp;
        }
    }

    /// @notice Validate the position for the pool and get Liquidity
    /// @param tokenId The tokenId of the position
    /// @dev the position must adhere to the price ranges
    /// @dev Only allow SPAUSDs pool to be staked.
    function _getLiquidity(uint256 tokenId) internal view returns (uint256) {
        /// @dev Get the info of the required token
        (
            ,
            ,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = INFPM(NFPM).positions(tokenId);

        /// @dev Check if the token belongs to correct pool
        require(
            SPAUSDsPool ==
                IUniswapV3Factory(UNIV3_FACTORY).getPool(token0, token1, fee),
            "Incorrect pool token"
        );

        /// @dev Check if the token adheres to the tick range
        require(
            tickLower == tickLowerAllowed && tickUpper == tickUpperAllowed,
            "Incorrect tick range"
        );

        return uint256(liquidity);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCall(target, data, "Address: low-level call failed");
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.7;

import "IERC721.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.

interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

interface INonfungiblePositionManager is IPoolInitializer, IERC721 {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}