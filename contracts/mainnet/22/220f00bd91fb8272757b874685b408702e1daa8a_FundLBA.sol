// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

error FundLBA__NotAuthorized();
error FundLBA__invalidTokenAddress();
error FundLBA__TransactionFailed();
error FundLBA__NotEnoughRewards();
error FundLBA__AllowanceFailed();
error FundLBA__NotEnoughTokens();
error FundLBA__LBANotExpired();
error FundLBA__LBANotOpen();
error FundLBA__CanNotClaimRewards();

contract FundLBA {
    struct UserTokenBalances {
        bool exists;
        uint256 usdcBalance;
        uint256 ethosBalance;
        uint256 ethosRewards;
        uint256 lpTokenBalance;
        uint256 lastWithdrawTimeStamp;
    }

    enum Token {
        USDC,
        ETHOS
    }
    enum LBAState {
        NOT_STARTED,
        OPEN,
        FAILED,
        CLOSED
    }

    event Deposit(address indexed user, Token token, uint256 amount);
    event ethosToUSDCRatio(uint256 ratio);
    event lbaState(LBAState state);
    event rewardClaimed(address indexed user, uint256 amount);
    event refund(address indexed user, Token token, uint256 amount);
    event totalVolume(uint256 volume);

    uint256 private constant LBA_DURATION = 7 days;
    uint256 private constant ETHOS_PARTICIPATION_DURATION = 4 days;
    uint256 private constant USDC_PARTICIPATION_DURATION = 5 days;

    uint256 private immutable i_ethosRewards;
    uint256 private immutable i_ethosClaimRewardAfter;
    address private immutable i_owner;
    address private immutable i_usdcAddress;
    address private immutable i_ethosAddress;
    address private immutable i_uniswapRouterAddress;

    uint256 private s_timestamp;
    uint256 private s_totalUSDC = 0;
    uint256 private s_totalETHOS = 0;
    uint256 private s_totalVolume = 0;
    uint256 private s_interval;

    uint256 private s_ethosToUSDCRatio = 0;
    //  limit of token balance
    uint256 private s_ethosMinimumTokenBalance;
    uint256 private s_usdcMinimumTokenBalance;
    uint256 private s_lpTokenBalance;
    uint256 private s_lbaCloseTime;
    address private s_uniswapPoolAddress;
    LBAState private s_lbaState = LBAState.NOT_STARTED;
    address[] private s_users;
    mapping(address => UserTokenBalances) private s_userBalances;

    modifier isOwner() {
        if (msg.sender != i_owner) {
            revert FundLBA__NotAuthorized();
        }
        _;
    }

    modifier isNotStarted() {
        if (s_lbaState != LBAState.NOT_STARTED) {
            revert FundLBA__NotAuthorized();
        }
        _;
    }

    modifier isLBAOpen() {
        if (s_lbaState != LBAState.OPEN || block.timestamp > (s_timestamp + LBA_DURATION)) {
            revert FundLBA__LBANotOpen();
        }
        _;
    }

    modifier isLBAExpired() {
        if (block.timestamp < (s_timestamp + LBA_DURATION) && s_lbaState != LBAState.CLOSED) {
            revert FundLBA__LBANotExpired();
        }
        _;
    }

    modifier isLBAClosed() {
        if (s_lbaState != LBAState.CLOSED) {
            revert FundLBA__NotAuthorized();
        }
        _;
    }

    modifier canCLaimRewards() {
        if (s_lbaState != LBAState.CLOSED || block.timestamp < (s_lbaCloseTime + i_ethosClaimRewardAfter)) {
            revert FundLBA__CanNotClaimRewards();
        }
        _;
    }

    modifier isFailed() {
        if (s_lbaState != LBAState.FAILED) {
            revert FundLBA__NotAuthorized();
        }
        _;
    }

    constructor(
        address usdcAddress,
        address ethosAddress,
        address uniswapRouterAddress,
        uint256 ethosRewards,
        uint256 ethosMinimumTokenBalance,
        uint256 usdcMinimumTokenBalance,
        uint256 ethosClaimRewardAfter
    ) {
        i_usdcAddress = usdcAddress;
        i_ethosAddress = ethosAddress;
        i_ethosRewards = ethosRewards;
        s_ethosMinimumTokenBalance = ethosMinimumTokenBalance;
        s_usdcMinimumTokenBalance = usdcMinimumTokenBalance;
        i_uniswapRouterAddress = uniswapRouterAddress;
        i_ethosClaimRewardAfter = ethosClaimRewardAfter;
        i_owner = msg.sender;
        emit lbaState(s_lbaState);
    }

    // start the lba, can be started by anyone as long as
    // they transfer the expected ethos amount set when they deployed the contract
    // the user has to pre approve the transfer before calling this function

    function startLBA() public isNotStarted {
        s_timestamp = block.timestamp;
        IERC20 token = IERC20(i_ethosAddress);
        bool transferSuccess = token.transferFrom(msg.sender, address(this), i_ethosRewards);
        if (!transferSuccess) {
            revert FundLBA__NotEnoughRewards();
        }
        s_lbaState = LBAState.OPEN;
        emit lbaState(s_lbaState);
    }

    function depositToken(address tokenAddress, uint256 amount) public isLBAOpen {
        IERC20 token = IERC20(tokenAddress);
        bool canDepositUSDC = block.timestamp < (s_timestamp + USDC_PARTICIPATION_DURATION);
        bool canDepositETHOS = block.timestamp < (s_timestamp + ETHOS_PARTICIPATION_DURATION);

        // update the total amount of USDC and ETHOS in the contract
        // this will be used later to know which one to use for the pool
        // we want to also update the user balance in the contract.
        // user has to pre approve the transfer before calling this function
        if (tokenAddress == i_usdcAddress) {
            if (!canDepositUSDC) {
                revert FundLBA__NotAuthorized();
            }
            if (amount < s_usdcMinimumTokenBalance) {
                revert FundLBA__NotEnoughTokens();
            }
            s_totalUSDC += amount;
            if (s_userBalances[msg.sender].exists) {
                s_userBalances[msg.sender].usdcBalance += amount;
            } else {
                s_userBalances[msg.sender] = UserTokenBalances(true, amount, 0, 0, 0, 0);
                s_users.push(msg.sender);
            }
        } else if (tokenAddress == i_ethosAddress) {
            if (!canDepositETHOS) {
                revert FundLBA__NotAuthorized();
            }
            if (amount < s_ethosMinimumTokenBalance) {
                revert FundLBA__NotEnoughTokens();
            }
            s_totalETHOS += amount;
            if (s_userBalances[msg.sender].exists) {
                s_userBalances[msg.sender].ethosBalance += amount;
            } else {
                s_userBalances[msg.sender] = UserTokenBalances(true, 0, amount, 0, 0, 0);
                s_users.push(msg.sender);
            }
        } else {
            revert FundLBA__invalidTokenAddress();
        }
        // calculate ratio of ETHOS to USDC
        // this will be used to calculate the rewards for each user
        calculateEthostoUsdcRation();
        calculateTotalVolume();
        bool transferSuccess = token.transferFrom(msg.sender, address(this), amount);
        if (!transferSuccess) {
            revert FundLBA__TransactionFailed();
        }

        // emit a new event when a new position has been entered.
        emit Deposit(msg.sender, tokenAddress == i_usdcAddress ? Token.USDC : Token.ETHOS, amount);
        emit ethosToUSDCRatio(s_ethosToUSDCRatio);
        emit totalVolume(s_totalVolume);
    }

    function withdrawContribution(uint256 amount) public isLBAOpen {
        uint256 maxWithdrawAmount = getUserMaxUSDCWithDrawAllowed();
        if (amount > maxWithdrawAmount || amount > s_userBalances[msg.sender].usdcBalance) {
            revert FundLBA__NotEnoughTokens();
        }
        IERC20 token = IERC20(i_usdcAddress);
        s_userBalances[msg.sender].usdcBalance -= amount;
        uint256 day6 = s_timestamp + USDC_PARTICIPATION_DURATION + 1 days;

        if (block.timestamp >= day6) {
            s_userBalances[msg.sender].lastWithdrawTimeStamp = block.timestamp;
        }
        s_totalUSDC -= amount;
        calculateEthostoUsdcRation();
        calculateTotalVolume();
        bool transferSuccess = token.transfer(msg.sender, amount);
        if (!transferSuccess) {
            revert FundLBA__TransactionFailed();
        }
        emit refund(msg.sender, Token.USDC, amount);
        emit ethosToUSDCRatio(s_ethosToUSDCRatio);
        emit totalVolume(s_totalVolume);
    }
    // after the lba has expired, the owner can close the lba
    // this would trigger the creation of the pool and the distribution of the rewards
    // the user can then claim their rewards by calling the claimReward function
    // and receive their rewards in the form of ETHOS tokens and LP tokens

    function closeLBA() public isOwner isLBAExpired {
        s_lbaState = LBAState.CLOSED;
        s_lbaCloseTime = block.timestamp;
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(i_uniswapRouterAddress);
        address factoryAddress = uniswapRouter.factory();
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(factoryAddress);
        address pairAddress = uniswapFactory.getPair(i_usdcAddress, i_ethosAddress);
        // create a new pair if it does not exist
        // this is an edge case that probably won't happen
        // but it makes sense to check first
        if (pairAddress == address(0)) {
            s_uniswapPoolAddress = uniswapFactory.createPair(i_usdcAddress, i_ethosAddress);
        } else {
            s_uniswapPoolAddress = pairAddress;
        }

        IERC20 usdcToken = IERC20(i_usdcAddress);
        IERC20 ethosToken = IERC20(i_ethosAddress);
        // approve the contract to spend the tokens
        bool usdcApproved = usdcToken.approve(i_uniswapRouterAddress, s_totalUSDC + 10_000);
        bool ethosApproved = ethosToken.approve(i_uniswapRouterAddress, s_totalETHOS + 10_000);
        if (!usdcApproved || !ethosApproved) {
            revert FundLBA__AllowanceFailed();
        }

        // the lp tokens will be distrubuted to the contract
        // the users can claim their rewards by calling the claimReward function afterwards
        (,, uint256 liquidity) = uniswapRouter.addLiquidity(
            i_usdcAddress,
            i_ethosAddress,
            s_totalUSDC,
            s_totalETHOS,
            s_totalUSDC,
            s_totalETHOS,
            address(this),
            block.timestamp + 10_000
        );
        s_lpTokenBalance = liquidity;

        // after the pool has been created and the liquidity has been added
        // we can now calculate the rewards for each user
        // this will be the final amount per user
        for (uint256 i = 0; i < s_users.length; i++) {
            address user = s_users[i];
            (uint256 userRewrads, uint256 userRatioInPool) = getUserExpectedRewards(user);
            s_userBalances[user].ethosRewards = userRewrads;
            s_userBalances[user].lpTokenBalance = liquidity * userRatioInPool / 1e18;
        }
        emit lbaState(s_lbaState);
    }

    // user can claim their rewards after the lba has been closed
    // the lba closes when the owner calls the closeLBA function
    // the user can claim their rewards after the i_ethosClaimRewardAfter time has passed
    function claimReward() public canCLaimRewards {
        IERC20 token = IERC20(i_ethosAddress);
        IERC20 lpToken = IERC20(s_uniswapPoolAddress);
        uint256 rewards = s_userBalances[msg.sender].ethosRewards;
        uint256 lpTokenBalance = s_userBalances[msg.sender].lpTokenBalance;
        s_userBalances[msg.sender].ethosRewards = 0;
        s_userBalances[msg.sender].lpTokenBalance = 0;
        bool tokenTransferred = token.transfer(msg.sender, rewards);
        bool lpTokenTransferred = lpToken.transfer(msg.sender, lpTokenBalance);
        if (!tokenTransferred || !lpTokenTransferred) {
            revert FundLBA__TransactionFailed();
        }
        emit rewardClaimed(msg.sender, rewards);
    }
    // if something goes wrong for any reason, the owner can call this function
    // to mark the lba as failed
    // and the users can claim their refunds

    function lbaFailed() public isOwner isLBAExpired {
        s_lbaState = LBAState.FAILED;
        emit lbaState(s_lbaState);
    }

    // claim the refund for the usdc and ethos used on the lba
    function claimRefund() public isFailed {
        IERC20 usdcToken = IERC20(i_usdcAddress);
        IERC20 ethosToken = IERC20(i_ethosAddress);
        uint256 usdcBalance = s_userBalances[msg.sender].usdcBalance;
        uint256 ethosBalance = s_userBalances[msg.sender].ethosBalance;
        s_userBalances[msg.sender].usdcBalance = 0;
        s_userBalances[msg.sender].ethosBalance = 0;
        bool usdcTransferred = usdcToken.transfer(msg.sender, usdcBalance);
        bool ethosTransferred = ethosToken.transfer(msg.sender, ethosBalance);
        if (!usdcTransferred || !ethosTransferred) {
            revert FundLBA__TransactionFailed();
        }
        emit refund(msg.sender, Token.USDC, usdcBalance);
        emit refund(msg.sender, Token.ETHOS, ethosBalance);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getUSDCAddress() public view returns (address) {
        return i_usdcAddress;
    }

    function getETHOSAddress() public view returns (address) {
        return i_ethosAddress;
    }

    function getTotalUSDC() public view returns (uint256) {
        return s_totalUSDC;
    }

    function getTotalETHOS() public view returns (uint256) {
        return s_totalETHOS;
    }

    function getETHOSToUSDCRatio() public view returns (uint256) {
        return s_ethosToUSDCRatio;
    }

    function getETHOSRewards() public view returns (uint256) {
        return i_ethosRewards;
    }

    function getUserBalances(address user) public view returns (uint256, uint256) {
        return (s_userBalances[user].usdcBalance, s_userBalances[user].ethosBalance);
    }

    // get the expected rewards for a user
    // this would change over the lba period and is not final
    // this will be finalized once closeLBA is called.
    function getUserExpectedRewards(address user) public view returns (uint256, uint256) {
        if (s_ethosToUSDCRatio == 0) {
            return (0, 0);
        }

        // calculate the total pool in USDC like.
        // use both the total pool value and user total value to calculate the expected rewards.
        uint256 userTotalUsdcValue =
            (s_userBalances[user].ethosBalance * s_ethosToUSDCRatio) + s_userBalances[user].usdcBalance * 1e18;
        uint256 totalUsdcValueInPool = (s_totalETHOS * s_ethosToUSDCRatio) + s_totalUSDC * 1e18;
        // convert to whole number
        uint256 userPositionInPool = (userTotalUsdcValue * 1e18) / totalUsdcValueInPool;
        return ((userPositionInPool * i_ethosRewards) / 1e18, userPositionInPool);
    }

    function getLBAState() public view returns (LBAState) {
        return s_lbaState;
    }

    function getUSDCMinimumTokenBalance() public view returns (uint256) {
        return s_usdcMinimumTokenBalance;
    }

    function getETHOSMinimumTokenBalance() public view returns (uint256) {
        return s_ethosMinimumTokenBalance;
    }

    function setUSDCMinimumTokenBalance(uint256 amount) public isOwner {
        s_usdcMinimumTokenBalance = amount;
    }

    function setETHOSMinimumTokenBalance(uint256 amount) public isOwner {
        s_ethosMinimumTokenBalance = amount;
    }

    function getEthosTokenAddress() public view returns (address) {
        return i_ethosAddress;
    }

    function getUsdcTokenAddress() public view returns (address) {
        return i_usdcAddress;
    }

    function getUserEthosRewards(address user) public view isLBAClosed returns (uint256) {
        return s_userBalances[user].ethosRewards;
    }

    function getLBAEndTime() public view returns (uint256) {
        return s_timestamp + LBA_DURATION;
    }

    function getLBAStartTime() public view returns (uint256) {
        return s_timestamp;
    }

    function getClaimRewardTime() public view isLBAClosed returns (uint256) {
        return s_lbaCloseTime + i_ethosClaimRewardAfter;
    }

    function getUniSwapRouterAddress() public view returns (address) {
        return i_uniswapRouterAddress;
    }

    function getUniSwapPoolAddress() public view returns (address) {
        return s_uniswapPoolAddress;
    }

    function getLPTokenBalance() public view returns (uint256) {
        return s_lpTokenBalance;
    }

    function getLBAUsers() public view returns (address[] memory) {
        return s_users;
    }

    function getLBAUsersTokenBalances(address user) public view returns (uint256, uint256, uint256, uint256, uint256) {
        UserTokenBalances memory userBalances = s_userBalances[user];
        return (
            userBalances.usdcBalance,
            userBalances.ethosBalance,
            userBalances.ethosRewards,
            userBalances.lpTokenBalance,
            userBalances.lastWithdrawTimeStamp
        );
    }

    function calculateEthostoUsdcRation() private {
        if (s_totalETHOS != 0) {
            s_ethosToUSDCRatio = (s_totalUSDC * 1e18) / s_totalETHOS;
        }
    }

    // The user can withdraw all his usdc contribution by day 5
    // after day 5 to day 6, the user can withdraw half of his usdc contribution
    // after day 6 till the end of the lba, the amount the user can withdraw will drop by 2% every hour starting at 50%
    // after day 5 they can on withdraw once till the end of the lba
    function getUserMaxUSDCWithDrawAllowed() public view isLBAOpen returns (uint256) {
        if (s_lbaState != LBAState.OPEN) {
            return 0;
        }
        UserTokenBalances memory user = s_userBalances[msg.sender];
        uint256 timePassed = block.timestamp - s_timestamp;
        if (timePassed <= USDC_PARTICIPATION_DURATION) {
            return user.usdcBalance;
        } else if (timePassed <= USDC_PARTICIPATION_DURATION + 1 days) {
            return user.usdcBalance / 2;
        } else {
            // this only gets populated if they trigger a withdraw after day 6.
            // as after day 6 they can only withdraw once.
            if (user.lastWithdrawTimeStamp != 0) {
                return 0;
            }
            timePassed = timePassed - USDC_PARTICIPATION_DURATION - 1 days;
            uint256 timePassedInHours = timePassed / 3600 + 1;
            uint256 percentage = 50 - timePassedInHours * 2;
            return user.usdcBalance * percentage / 100;
        }
    }

    function getLbaEndTime() public view returns (uint256) {
        return s_timestamp + LBA_DURATION;
    }

    function getLbaCloseTime() public view returns (uint256) {
        return s_lbaCloseTime;
    }

    function getLBADuration() public pure returns (uint256) {
        return LBA_DURATION;
    }

    function getUSDCParticipationDuration() public pure returns (uint256) {
        return USDC_PARTICIPATION_DURATION;
    }

    function getEthosParticipationDuration() public pure returns (uint256) {
        return ETHOS_PARTICIPATION_DURATION;
    }

    function getTimeLeftToParticipateWithEthosToken() public view isLBAOpen returns (uint256) {
        uint256 timeleft = ETHOS_PARTICIPATION_DURATION + s_timestamp - block.timestamp;
        if (timeleft > 0) {
            return timeleft;
        }
        return 0;
    }

    function getTimeLeftToParticipateWithUSDC() public view isLBAOpen returns (uint256) {
        uint256 timeleft = USDC_PARTICIPATION_DURATION + s_timestamp - block.timestamp;
        if (timeleft > 0) {
            return timeleft;
        }
        return 0;
    }

    function getTimeLeftToClaimRewards() public view isLBAClosed returns (uint256) {
        uint256 timeleft = i_ethosClaimRewardAfter + s_lbaCloseTime - block.timestamp;
        if (timeleft > 0) {
            return timeleft;
        }
        return 0;
    }

    function getTimeLeftInTheLba() public view isLBAOpen returns (uint256) {
        uint256 timeleft = LBA_DURATION + s_lbaCloseTime - block.timestamp;
        if (timeleft > 0) {
            return timeleft;
        }
        return 0;
    }

    function getTimeToClaimRewards() public view isLBAClosed returns (uint256) {
        return s_lbaCloseTime + i_ethosClaimRewardAfter;
    }

    function getUsdcParticipationEndTime() public view returns (uint256) {
        return USDC_PARTICIPATION_DURATION + s_timestamp;
    }

    function getEthosParticipationEndTime() public view returns (uint256) {
        return ETHOS_PARTICIPATION_DURATION + s_timestamp;
    }

    function getTotalVolume() public view returns (uint256) {
        return s_totalVolume;
    }

    function calculateTotalVolume() private {
        uint256 newVolume = s_totalUSDC + s_totalETHOS * s_ethosToUSDCRatio;
        if (newVolume > s_totalVolume) {
            s_totalVolume += newVolume - s_totalVolume;
        } else {
            s_totalVolume += s_totalVolume - newVolume;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}