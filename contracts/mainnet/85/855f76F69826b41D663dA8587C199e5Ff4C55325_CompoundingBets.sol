// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../VariableRewardsStrategyForSAV2.sol";

import "./interfaces/ISingleStaking.sol";

contract CompoundingBets is VariableRewardsStrategyForSAV2 {
    ISingleStaking public stakingContract;

    constructor(
        address _stakingContract,
        address _swapPairDepositToken,
        uint256 _swapFeeBips,
        VariableRewardsStrategySettings memory _settings,
        StrategySettings memory _strategySettings
    ) VariableRewardsStrategyForSAV2(_swapPairDepositToken, _swapFeeBips, _settings, _strategySettings) {
        stakingContract = ISingleStaking(_stakingContract);
    }

    function _depositToStakingContract(uint256 _amount, uint256) internal override {
        depositToken.approve(address(stakingContract), _amount);
        stakingContract.stake(_amount);
    }

    function _withdrawFromStakingContract(uint256 _amount) internal override returns (uint256 withdrawAmount) {
        stakingContract.withdraw(_amount);
        return _amount;
    }

    function _emergencyWithdraw() internal override {
        stakingContract.withdraw(totalDeposits());
        depositToken.approve(address(stakingContract), 0);
    }

    function _pendingRewards() internal view override returns (Reward[] memory) {
        Reward[] memory pendingRewards = new Reward[](rewardCount);
        for (uint256 i = 0; i < pendingRewards.length; i++) {
            address rewardToken = supportedRewards[i];
            uint256 amount = stakingContract.earned(address(this), rewardToken);
            pendingRewards[i] = Reward({reward: rewardToken, amount: amount});
        }
        return pendingRewards;
    }

    function _getRewards() internal override {
        stakingContract.getReward();
    }

    function totalDeposits() public view override returns (uint256) {
        return stakingContract.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IPair.sol";
import "../lib/DexLibrary.sol";
import "./VariableRewardsStrategy.sol";

/**
 * @notice Adapter strategy for VariableRewardsStrategy with SA deposit.
 */
abstract contract VariableRewardsStrategyForSAV2 is VariableRewardsStrategy {
    address public immutable swapPairDepositToken;
    uint256 public swapFeeBips;

    constructor(
        address _swapPairDepositToken,
        uint256 _swapFeeBips,
        VariableRewardsStrategySettings memory _settings,
        StrategySettings memory _strategySettings
    ) VariableRewardsStrategy(_settings, _strategySettings) {
        swapPairDepositToken = _swapPairDepositToken;
        assignSwapPairSafely(_swapPairDepositToken);
        swapFeeBips = _swapFeeBips;
    }

    function updateSwapFee(uint256 _swapFeeBips) external onlyDev {
        swapFeeBips = _swapFeeBips;
    }

    function assignSwapPairSafely(address _swapPairDepositToken) internal virtual {
        if (address(rewardToken) != address(depositToken)) {
            require(
                DexLibrary.checkSwapPairCompatibility(
                    IPair(_swapPairDepositToken), address(depositToken), address(rewardToken)
                ),
                "VariableRewardsStrategyForSA::swapPairDepositToken does not match deposit and reward token"
            );
        }
    }

    function _convertRewardTokenToDepositToken(uint256 fromAmount)
        internal
        virtual
        override
        returns (uint256 toAmount)
    {
        if (address(rewardToken) == address(depositToken)) {
            return fromAmount;
        }
        return DexLibrary.swap(
            fromAmount, address(rewardToken), address(depositToken), IPair(swapPairDepositToken), swapFeeBips
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ISingleStaking {
    function balanceOf(address account) external view returns (uint256);
    function earned(address account, address _rewardsToken) external view returns (uint256);
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint256 liquidity);

    function sync() external;

    function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./SafeERC20.sol";
import "../interfaces/IPair.sol";

library DexLibrary {
    using SafeERC20 for IERC20;

    bytes private constant zeroBytes = new bytes(0);
    uint256 public constant DEFAULT_SWAP_FEE = 30;
    uint public constant BIPS_DIVISOR = 10000;

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair pair
    ) internal returns (uint256) {
        return DexLibrary.swap(amountIn, fromToken, toToken, pair, DEFAULT_SWAP_FEE);
    }

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair pair,
        uint256 swapFee
    ) internal returns (uint256) {
        (address token0, ) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        uint256 amountOut1 = 0;
        uint256 amountOut2 = getAmountOut(amountIn, reserve0, reserve1, swapFee);
        if (token0 != fromToken) (amountOut1, amountOut2) = (amountOut2, amountOut1);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        pair.swap(amountOut1, amountOut2, address(this), zeroBytes);
        return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
    }

    function checkSwapPairCompatibility(
        IPair pair,
        address tokenA,
        address tokenB
    ) internal pure returns (bool) {
        return
            (tokenA == pair.token0() || tokenA == pair.token1()) &&
            (tokenB == pair.token0() || tokenB == pair.token1()) &&
            tokenA != tokenB;
    }

    function estimateConversionThroughPair(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair swapPair
    ) internal view returns (uint256) {
        return DexLibrary.estimateConversionThroughPair(amountIn, fromToken, toToken, swapPair, DEFAULT_SWAP_FEE);
    }

    function estimateConversionThroughPair(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair swapPair,
        uint256 swapFee
    ) internal view returns (uint256) {
        (address token0, ) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1, ) = swapPair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        return getAmountOut(amountIn, reserve0, reserve1, swapFee);
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(
        uint256 amount,
        address rewardToken,
        address depositToken,
        IPair swapPairToken0,
        IPair swapPairToken1
    ) internal returns (uint256) {
        return
            DexLibrary.convertRewardTokensToDepositTokens(
                amount,
                rewardToken,
                depositToken,
                swapPairToken0,
                DEFAULT_SWAP_FEE,
                swapPairToken1,
                DEFAULT_SWAP_FEE
            );
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(
        uint256 amount,
        address rewardToken,
        address depositToken,
        IPair swapPairToken0,
        uint256 swapFeeToken0,
        IPair swapPairToken1,
        uint256 swapFeeToken1
    ) internal returns (uint256) {
        uint256 amountIn = amount / 2;
        require(amountIn > 0, "DexLibrary::_convertRewardTokensToDepositTokens");

        address token0 = IPair(depositToken).token0();
        uint256 amountOutToken0 = amountIn;
        if (rewardToken != token0) {
            amountOutToken0 = DexLibrary.swap(amountIn, rewardToken, token0, swapPairToken0, swapFeeToken0);
        }

        address token1 = IPair(depositToken).token1();
        uint256 amountOutToken1 = amountIn;
        if (rewardToken != token1) {
            amountOutToken1 = DexLibrary.swap(amountIn, rewardToken, token1, swapPairToken1, swapFeeToken1);
        }

        return DexLibrary.addLiquidity(depositToken, amountOutToken0, amountOutToken1);
    }

    /**
     * @notice Add liquidity directly through a Pair
     * @dev Checks adding the max of each token amount
     * @param depositToken address
     * @param maxAmountIn0 amount token0
     * @param maxAmountIn1 amount token1
     * @return liquidity tokens
     */
    function addLiquidity(
        address depositToken,
        uint256 maxAmountIn0,
        uint256 maxAmountIn1
    ) internal returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IPair(address(depositToken)).getReserves();
        uint256 amountIn1 = _quoteLiquidityAmountOut(maxAmountIn0, reserve0, reserve1);
        if (amountIn1 > maxAmountIn1) {
            amountIn1 = maxAmountIn1;
            maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
        }

        IERC20(IPair(depositToken).token0()).safeTransfer(depositToken, maxAmountIn0);
        IERC20(IPair(depositToken).token1()).safeTransfer(depositToken, amountIn1);
        return IPair(depositToken).mint(address(this));
    }

    /**
     * @notice Quote liquidity amount out
     * @param amountIn input tokens
     * @param reserve0 size of input asset reserve
     * @param reserve1 size of output asset reserve
     * @return liquidity tokens
     */
    function _quoteLiquidityAmountOut(
        uint256 amountIn,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256) {
        return (amountIn * reserve1) / reserve0;
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
     * @param amountIn input asset
     * @param reserveIn size of input asset reserve
     * @param reserveOut size of output asset reserve
     * @return maximum output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFee
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * (BIPS_DIVISOR - swapFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * BIPS_DIVISOR + amountInWithFee;
        return numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../YakStrategyV2.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IWAVAX.sol";
import "../lib/DexLibrary.sol";
import "../lib/SafeERC20.sol";

/**
 * @notice VariableRewardsStrategy
 */
abstract contract VariableRewardsStrategy is YakStrategyV2 {
    using SafeERC20 for IERC20;

    IWAVAX internal immutable WAVAX;

    struct VariableRewardsStrategySettings {
        string name;
        address platformToken;
        RewardSwapPair[] rewardSwapPairs;
        address timelock;
    }

    struct Reward {
        address reward;
        uint256 amount;
    }

    struct RewardSwapPair {
        address reward;
        address swapPair;
        uint256 swapFee;
    }

    // reward -> swapPair
    mapping(address => RewardSwapPair) public rewardSwapPairs;
    address[] public supportedRewards;
    uint256 public rewardCount;

    event AddReward(address rewardToken, address swapPair);
    event RemoveReward(address rewardToken);

    constructor(VariableRewardsStrategySettings memory _settings, StrategySettings memory _strategySettings)
        YakStrategyV2(_strategySettings)
    {
        name = _settings.name;
        WAVAX = IWAVAX(_settings.platformToken);
        devAddr = 0xDcEDF06Fd33E1D7b6eb4b309f779a0e9D3172e44;

        for (uint256 i = 0; i < _settings.rewardSwapPairs.length; i++) {
            _addReward(
                _settings.rewardSwapPairs[i].reward,
                _settings.rewardSwapPairs[i].swapPair,
                _settings.rewardSwapPairs[i].swapFee
            );
        }

        updateDepositsEnabled(true);
        transferOwnership(_settings.timelock);
        emit Reinvest(0, 0);
    }

    function addReward(address _rewardToken, address _swapPair) public onlyDev {
        _addReward(_rewardToken, _swapPair, DexLibrary.DEFAULT_SWAP_FEE);
    }

    function addReward(
        address _rewardToken,
        address _swapPair,
        uint256 _swapFee
    ) public onlyDev {
        _addReward(_rewardToken, _swapPair, _swapFee);
    }

    function _addReward(
        address _rewardToken,
        address _swapPair,
        uint256 _swapFee
    ) internal {
        if (_rewardToken != address(rewardToken)) {
            require(
                DexLibrary.checkSwapPairCompatibility(IPair(_swapPair), _rewardToken, address(rewardToken)),
                "VariableRewardsStrategy::Swap pair does not contain reward token"
            );
        }
        rewardSwapPairs[_rewardToken] = RewardSwapPair({reward: _rewardToken, swapPair: _swapPair, swapFee: _swapFee});
        supportedRewards.push(_rewardToken);
        rewardCount = rewardCount + 1;
        emit AddReward(_rewardToken, _swapPair);
    }

    function removeReward(address _rewardToken) public onlyDev {
        delete rewardSwapPairs[_rewardToken];
        bool found = false;
        for (uint256 i = 0; i < supportedRewards.length; i++) {
            if (_rewardToken == supportedRewards[i]) {
                found = true;
                supportedRewards[i] = supportedRewards[supportedRewards.length - 1];
            }
        }
        require(found, "VariableRewardsStrategy::Reward to delete not found!");
        supportedRewards.pop();
        rewardCount = rewardCount - 1;
        emit RemoveReward(_rewardToken);
    }

    function calculateDepositFee(uint256 _amount) public view returns (uint256) {
        return _calculateDepositFee(_amount);
    }

    function calculateWithdrawFee(uint256 _amount) public view returns (uint256) {
        return _calculateWithdrawFee(_amount);
    }

    /**
     * @notice Deposit tokens to receive receipt tokens
     * @param _amount Amount of tokens to deposit
     */
    function deposit(uint256 _amount) external override {
        _deposit(msg.sender, _amount);
    }

    /**
     * @notice Deposit using Permit
     * @param _amount Amount of tokens to deposit
     * @param _deadline The time at which to expire the signature
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        depositToken.permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        _deposit(msg.sender, _amount);
    }

    function depositFor(address _account, uint256 _amount) external override {
        _deposit(_account, _amount);
    }

    function _deposit(address _account, uint256 _amount) internal {
        require(DEPOSITS_ENABLED == true, "VariableRewardsStrategy::Deposits disabled");
        uint256 maxPendingRewards = MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
        if (maxPendingRewards > 0) {
            uint256 estimatedTotalReward = checkReward();
            if (estimatedTotalReward > maxPendingRewards) {
                _reinvest(true);
            }
        }
        require(
            depositToken.transferFrom(msg.sender, address(this), _amount),
            "VariableRewardsStrategy::Deposit token transfer failed"
        );
        uint256 depositFee = _calculateDepositFee(_amount);
        _mint(_account, getSharesForDepositTokens(_amount - depositFee));
        _stakeDepositTokens(_amount, depositFee);
        emit Deposit(_account, _amount);
    }

    /**
     * @notice Withdraw fee bips from underlying farm
     */
    function _getDepositFeeBips() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @notice Calculate deposit fee of underlying farm
     * @dev Override if deposit fee is calculated dynamically
     */
    function _calculateDepositFee(uint256 _amount) internal view virtual returns (uint256) {
        uint256 depositFeeBips = _getDepositFeeBips();
        return (_amount * depositFeeBips) / _bip();
    }

    function withdraw(uint256 _amount) external override {
        uint256 depositTokenAmount = getDepositTokensForShares(_amount);
        require(depositTokenAmount > 0, "VariableRewardsStrategy::Withdraw amount too low");
        uint256 withdrawAmount = _withdrawFromStakingContract(depositTokenAmount);
        uint256 withdrawFee = _calculateWithdrawFee(depositTokenAmount);
        depositToken.safeTransfer(msg.sender, withdrawAmount - withdrawFee);
        _burn(msg.sender, _amount);
        emit Withdraw(msg.sender, depositTokenAmount);
    }

    /**
     * @notice Withdraw fee bips from underlying farm
     * @dev Important: Do not override if withdraw fee is deducted from the amount returned by _withdrawFromStakingContract
     */
    function _getWithdrawFeeBips() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @notice Calculate withdraw fee of underlying farm
     * @dev Override if withdraw fee is calculated dynamically
     * @dev Important: Do not override if withdraw fee is deducted from the amount returned by _withdrawFromStakingContract
     */
    function _calculateWithdrawFee(uint256 _amount) internal view virtual returns (uint256) {
        uint256 withdrawFeeBips = _getWithdrawFeeBips();
        return (_amount * withdrawFeeBips) / _bip();
    }

    function reinvest() external override onlyEOA {
        _reinvest(false);
    }

    function _convertPoolRewardsToRewardToken() private returns (uint256) {
        uint256 rewardTokenAmount = rewardToken.balanceOf(address(this));
        uint256 count = supportedRewards.length;
        for (uint256 i = 0; i < count; i++) {
            address reward = supportedRewards[i];
            if (reward == address(WAVAX)) {
                uint256 balance = address(this).balance;
                if (balance > 0) {
                    WAVAX.deposit{value: balance}();
                }
                if (address(rewardToken) == address(WAVAX)) {
                    rewardTokenAmount += balance;
                    continue;
                }
            }
            uint256 amount = IERC20(reward).balanceOf(address(this));
            if (amount > 0) {
                address swapPair = rewardSwapPairs[reward].swapPair;
                if (swapPair > address(0)) {
                    rewardTokenAmount += DexLibrary.swap(
                        amount,
                        reward,
                        address(rewardToken),
                        IPair(swapPair),
                        rewardSwapPairs[reward].swapFee
                    );
                }
            }
        }
        return rewardTokenAmount;
    }

    /**
     * @notice Reinvest rewards from staking contract to deposit tokens
     * @dev Reverts if the expected amount of tokens are not returned from the staking contract
     */
    function _reinvest(bool userDeposit) private {
        _getRewards();
        uint256 amount = _convertPoolRewardsToRewardToken();
        if (!userDeposit) {
            require(amount >= MIN_TOKENS_TO_REINVEST, "VariableRewardsStrategy::Reinvest amount too low");
        }

        uint256 devFee = (amount * DEV_FEE_BIPS) / BIPS_DIVISOR;
        if (devFee > 0) {
            rewardToken.safeTransfer(devAddr, devFee);
        }

        uint256 reinvestFee = (amount * REINVEST_REWARD_BIPS) / BIPS_DIVISOR;
        if (reinvestFee > 0) {
            rewardToken.safeTransfer(msg.sender, reinvestFee);
        }

        uint256 depositTokenAmount = _convertRewardTokenToDepositToken(amount - devFee - reinvestFee);

        uint256 depositFee = _calculateDepositFee(depositTokenAmount);
        _stakeDepositTokens(depositTokenAmount, depositFee);
        emit Reinvest(totalDeposits(), totalSupply);
    }

    function _stakeDepositTokens(uint256 _amount, uint256 _depositFee) private {
        require(_amount > 0, "VariableRewardsStrategy::Stake amount too low");
        _depositToStakingContract(_amount, _depositFee);
    }

    function checkReward() public view override returns (uint256) {
        Reward[] memory rewards = _pendingRewards();
        uint256 estimatedTotalReward = rewardToken.balanceOf(address(this));
        if (address(rewardToken) == address(WAVAX)) {
            estimatedTotalReward += address(this).balance;
        }
        for (uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i].reward;
            if (reward == address(rewardToken)) {
                estimatedTotalReward += rewards[i].amount;
            } else if (reward > address(0)) {
                uint256 balance = IERC20(reward).balanceOf(address(this));
                uint256 amount = balance + rewards[i].amount;
                address swapPair = rewardSwapPairs[rewards[i].reward].swapPair;
                if (amount > 0 && swapPair > address(0)) {
                    estimatedTotalReward += DexLibrary.estimateConversionThroughPair(
                        amount,
                        reward,
                        address(rewardToken),
                        IPair(swapPair),
                        rewardSwapPairs[rewards[i].reward].swapFee
                    );
                }
            }
        }
        return estimatedTotalReward;
    }

    /**
     * @notice Estimate recoverable balance after withdraw fee
     * @return deposit tokens after withdraw fee
     */
    function estimateDeployedBalance() external view override returns (uint256) {
        uint256 depositBalance = totalDeposits();
        uint256 withdrawFee = _calculateWithdrawFee(depositBalance);
        return depositBalance - withdrawFee;
    }

    function rescueDeployedFunds(
        uint256 _minReturnAmountAccepted,
        bool /*_disableDeposits*/
    ) external override onlyOwner {
        uint256 balanceBefore = depositToken.balanceOf(address(this));
        _emergencyWithdraw();
        uint256 balanceAfter = depositToken.balanceOf(address(this));
        require(
            balanceAfter - balanceBefore >= _minReturnAmountAccepted,
            "VariableRewardsStrategy::Emergency withdraw minimum return amount not reached"
        );
        emit Reinvest(totalDeposits(), totalSupply);
        if (DEPOSITS_ENABLED == true) {
            updateDepositsEnabled(false);
        }
    }

    function _bip() internal view virtual returns (uint256) {
        return 10000;
    }

    /* VIRTUAL */
    function _convertRewardTokenToDepositToken(uint256 _fromAmount) internal virtual returns (uint256 toAmount);

    function _depositToStakingContract(uint256 _amount, uint256 _depositFee) internal virtual;

    function _withdrawFromStakingContract(uint256 _amount) internal virtual returns (uint256 withdrawAmount);

    function _emergencyWithdraw() internal virtual;

    function _getRewards() internal virtual;

    function _pendingRewards() internal view virtual returns (Reward[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.13;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.13;

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
pragma solidity 0.8.13;

import "./lib/Ownable.sol";
import "./lib/Permissioned.sol";
import "./interfaces/IERC20.sol";
import "./YakERC20.sol";
import "./lib/SafeERC20.sol";

/**
 * @notice YakStrategy should be inherited by new strategies
 */
abstract contract YakStrategyV2 is YakERC20, Ownable, Permissioned {
    using SafeERC20 for IERC20;

    struct StrategySettings {
        address depositToken;
        address rewardToken;
        uint256 minTokensToReinvest;
        uint256 devFeeBips;
        uint256 reinvestRewardBips;
    }

    IERC20 public immutable depositToken;
    IERC20 public immutable rewardToken;
    address public devAddr;

    uint256 public MIN_TOKENS_TO_REINVEST;
    uint256 public MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST;
    bool public DEPOSITS_ENABLED;

    uint256 public ADMIN_FEE_BIPS;
    uint256 public REINVEST_REWARD_BIPS;
    uint256 public DEV_FEE_BIPS;

    uint256 internal constant BIPS_DIVISOR = 10000;
    uint256 internal constant MAX_UINT = type(uint256).max;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Reinvest(uint256 newTotalDeposits, uint256 newTotalSupply);
    event Recovered(address token, uint256 amount);
    event UpdateAdminFee(uint256 oldValue, uint256 newValue);
    event UpdateDevFee(uint256 oldValue, uint256 newValue);
    event UpdateReinvestReward(uint256 oldValue, uint256 newValue);
    event UpdateMinTokensToReinvest(uint256 oldValue, uint256 newValue);
    event UpdateMaxTokensToDepositWithoutReinvest(uint256 oldValue, uint256 newValue);
    event UpdateDevAddr(address oldValue, address newValue);
    event DepositsEnabled(bool newValue);

    /**
     * @notice Throws if called by smart contract
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "YakStrategy::onlyEOA");
        _;
    }

    /**
     * @notice Only called by dev
     */
    modifier onlyDev() {
        require(msg.sender == devAddr, "YakStrategy::onlyDev");
        _;
    }

    constructor(StrategySettings memory _strategySettings) {
        depositToken = IERC20(_strategySettings.depositToken);
        rewardToken = IERC20(_strategySettings.rewardToken);
        updateMinTokensToReinvest(_strategySettings.minTokensToReinvest);
        updateDevFee(_strategySettings.devFeeBips);
        updateReinvestReward(_strategySettings.reinvestRewardBips);
    }

    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0));
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(uint256 amount) external virtual;

    /**
     * @notice Deposit using Permit
     * @dev Should revert for tokens without Permit
     * @param amount Amount of tokens to deposit
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;

    /**
     * @notice Deposit on behalf of another account
     * @dev Must mint receipt tokens to `account`
     * @param account address to receive receipt tokens
     * @param amount deposit tokens
     */
    function depositFor(address account, uint256 amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(uint256 amount) external virtual;

    /**
     * @notice Reinvest reward tokens into deposit tokens
     */
    function reinvest() external virtual;

    /**
     * @notice Estimate reinvest reward
     * @return reward tokens
     */
    function estimateReinvestReward() external view returns (uint256) {
        uint256 unclaimedRewards = checkReward();
        if (unclaimedRewards >= MIN_TOKENS_TO_REINVEST) {
            return (unclaimedRewards * REINVEST_REWARD_BIPS) / BIPS_DIVISOR;
        }
        return 0;
    }

    /**
     * @notice Reward tokens available to strategy, including balance
     * @return reward tokens
     */
    function checkReward() public view virtual returns (uint256);

    /**
     * @notice Estimated deposit token balance deployed by strategy, excluding balance
     * @return deposit tokens
     */
    function estimateDeployedBalance() external view virtual returns (uint256);

    /**
     * @notice Rescue all available deployed deposit tokens back to Strategy
     * @param minReturnAmountAccepted min deposit tokens to receive
     * @param disableDeposits bool
     */
    function rescueDeployedFunds(uint256 minReturnAmountAccepted, bool disableDeposits) external virtual;

    /**
     * @notice This function returns a snapshot of last available quotes
     * @return total deposits available on the contract
     */
    function totalDeposits() public view virtual returns (uint256);

    /**
     * @notice Calculate receipt tokens for a given amount of deposit tokens
     * @dev If contract is empty, use 1:1 ratio
     * @dev Could return zero shares for very low amounts of deposit tokens
     * @param amount deposit tokens
     * @return receipt tokens
     */
    function getSharesForDepositTokens(uint256 amount) public view returns (uint256) {
        if (totalSupply == 0 || totalDeposits() == 0) {
            return amount;
        }
        return (amount * totalSupply) / totalDeposits();
    }

    /**
     * @notice Calculate deposit tokens for a given amount of receipt tokens
     * @param amount receipt tokens
     * @return deposit tokens
     */
    function getDepositTokensForShares(uint256 amount) public view returns (uint256) {
        if (totalSupply == 0 || totalDeposits() == 0) {
            return 0;
        }
        return (amount * totalDeposits()) / totalSupply;
    }

    /**
     * @notice Update reinvest min threshold
     * @param newValue threshold
     */
    function updateMinTokensToReinvest(uint256 newValue) public onlyOwner {
        emit UpdateMinTokensToReinvest(MIN_TOKENS_TO_REINVEST, newValue);
        MIN_TOKENS_TO_REINVEST = newValue;
    }

    /**
     * @notice Update reinvest max threshold before a deposit
     * @param newValue threshold
     */
    function updateMaxTokensToDepositWithoutReinvest(uint256 newValue) public onlyOwner {
        emit UpdateMaxTokensToDepositWithoutReinvest(MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST, newValue);
        MAX_TOKENS_TO_DEPOSIT_WITHOUT_REINVEST = newValue;
    }

    /**
     * @notice Update admin fee
     * @dev Deprecated; Kept for compatibility
     * @param newValue fee in BIPS; required to be 0
     */
    function updateAdminFee(uint256 newValue) public onlyOwner {
        require(newValue == 0);
        emit UpdateAdminFee(ADMIN_FEE_BIPS, newValue);
        ADMIN_FEE_BIPS = newValue;
    }

    /**
     * @notice Update developer fee
     * @param newValue fee in BIPS
     */
    function updateDevFee(uint256 newValue) public onlyOwner {
        require(newValue + REINVEST_REWARD_BIPS <= BIPS_DIVISOR);
        emit UpdateDevFee(DEV_FEE_BIPS, newValue);
        DEV_FEE_BIPS = newValue;
    }

    /**
     * @notice Update reinvest reward
     * @param newValue fee in BIPS
     */
    function updateReinvestReward(uint256 newValue) public onlyOwner {
        require(newValue + DEV_FEE_BIPS <= BIPS_DIVISOR);
        emit UpdateReinvestReward(REINVEST_REWARD_BIPS, newValue);
        REINVEST_REWARD_BIPS = newValue;
    }

    /**
     * @notice Enable/disable deposits
     * @param newValue bool
     */
    function updateDepositsEnabled(bool newValue) public onlyOwner {
        require(DEPOSITS_ENABLED != newValue);
        DEPOSITS_ENABLED = newValue;
        emit DepositsEnabled(newValue);
    }

    /**
     * @notice Update devAddr
     * @param newValue address
     */
    function updateDevAddr(address newValue) public onlyDev {
        emit UpdateDevAddr(devAddr, newValue);
        devAddr = newValue;
    }

    /**
     * @notice Recover ERC20 from contract
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0);
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Recover AVAX from contract
     * @param amount amount
     */
    function recoverAVAX(uint256 amount) external onlyOwner {
        require(amount > 0);
        payable(msg.sender).transfer(amount);
        emit Recovered(address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function withdraw(uint256) external;

    function approve(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Context.sol";

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

abstract contract Permissioned is Ownable {
    uint256 public numberOfAllowedDepositors;
    mapping(address => bool) public allowedDepositors;

    event AllowDepositor(address indexed account);
    event RemoveDepositor(address indexed account);

    modifier onlyAllowedDeposits() {
        if (numberOfAllowedDepositors > 0) {
            require(allowedDepositors[msg.sender] == true, "Permissioned::onlyAllowedDeposits, not allowed");
        }
        _;
    }

    /**
     * @notice Add an allowed depositor
     * @param depositor address
     */
    function allowDepositor(address depositor) external onlyOwner {
        require(allowedDepositors[depositor] == false, "Permissioned::allowDepositor");
        allowedDepositors[depositor] = true;
        numberOfAllowedDepositors = numberOfAllowedDepositors + 1;
        emit AllowDepositor(depositor);
    }

    /**
     * @notice Remove an allowed depositor
     * @param depositor address
     */
    function removeDepositor(address depositor) external onlyOwner {
        require(numberOfAllowedDepositors > 0, "Permissioned::removeDepositor, no allowed depositors");
        require(allowedDepositors[depositor] == true, "Permissioned::removeDepositor, not allowed");
        allowedDepositors[depositor] = false;
        numberOfAllowedDepositors = numberOfAllowedDepositors - 1;
        emit RemoveDepositor(depositor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";

abstract contract YakERC20 {
    string public name = "Yield Yak";
    string public symbol = "YRT";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) internal allowances;
    mapping(address => uint256) internal balances;

    /// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev keccak256("1");
    bytes32 public constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {}

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * It is recommended to use increaseAllowance and decreaseAllowance instead
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Approval implementation
     * @param owner The address of the account which owns tokens
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "_approve::owner zero address");
        require(spender != address(0), "_approve::spender zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer implementation
     * @param from The address of the account which owns tokens
     * @param to The address of the account which is receiving tokens
     * @param value The number of tokens that are being transferred
     */
    function _transferTokens(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0), "_transferTokens: cannot transfer to the zero address");

        balances[from] = balances[from] - value;
        balances[to] = balances[to] + value;
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        require(value > 0, "_mint::zero shares");
        totalSupply = totalSupply + value;
        balances[to] = balances[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balances[from] = balances[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    /**
     * @notice Triggers an approval from owner to spender
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param value The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "permit::expired");

        bytes32 encodeData = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        _validateSignedData(owner, encodeData, v, r, s);

        _approve(owner, spender, value);
    }

    /**
     * @notice Recovers address from signed data and validates the signature
     * @param signer Address that signed the data
     * @param encodeData Data signed by the address
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function _validateSignedData(
        address signer,
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "Arch::validateSig: invalid signature");
    }

    /**
     * @notice EIP-712 Domain separator
     * @return Separator
     */
    function getDomainSeparator() public view returns (bytes32) {
        return
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), VERSION_HASH, _getChainId(), address(this)));
    }

    /**
     * @notice Current id of the chain where this contract is deployed
     * @return Chain id
     */
    function _getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}