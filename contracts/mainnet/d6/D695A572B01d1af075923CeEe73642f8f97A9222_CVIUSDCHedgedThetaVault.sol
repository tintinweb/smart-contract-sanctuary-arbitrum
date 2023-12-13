// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

interface INonfungiblePositionManager is IERC721Metadata
{
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

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function burn(uint256 tokenId) external payable;

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0
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

// SPDX-License-Identifier: GPL-3.0
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IHedgedThetaVault.sol";
import "./interfaces/IHedgedThetaVaultManagement.sol";
import "./interfaces/IPlatform.sol";
import "./interfaces/IMegaThetaVault.sol";
import "./interfaces/IComputedCVIOracle.sol";

contract HedgedThetaVault is Initializable, IHedgedThetaVault, IHedgedThetaVaultManagement, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    uint32 internal constant MAX_PERCENTAGE = 1000000;

    address public fulfiller;
    address public hedgeAdjuster;

    IERC20 internal token;
    IPlatform internal inversePlatform;
    IMegaThetaVault internal megaThetaVault;
    IRewardRouter public rewardRouter;
    address public thetaRewardTracker;

    uint256 public initialTokenToHedgedThetaTokenRate;
    uint32 public depositHoldingsPercentage;
    uint32 public withdrawFeePercentage;

    uint32 public minCVIDiffAllowedPercentage; // Obsolete

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _initialTokenToHedgedThetaTokenRate, IPlatform _inversePlatform, IMegaThetaVault _megaThetaVault, 
            IERC20 _token, string memory _lpTokenName, string memory _lpTokenSymbolName) public initializer {

        require(address(_inversePlatform) != address(0));
        require(address(_megaThetaVault) != address(0));
        require(address(_token) != address(0));
        require(_initialTokenToHedgedThetaTokenRate > 0);

        initialTokenToHedgedThetaTokenRate = _initialTokenToHedgedThetaTokenRate;
        depositHoldingsPercentage = 250000;
        withdrawFeePercentage = 1000;

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init(_lpTokenName, _lpTokenSymbolName);

        token = _token;
        inversePlatform = _inversePlatform;
        megaThetaVault = _megaThetaVault;

        token.safeApprove(address(megaThetaVault), type(uint256).max);
        IERC20(address(megaThetaVault)).safeApprove(address(megaThetaVault), type(uint256).max);
        token.safeApprove(address(inversePlatform), type(uint256).max);
    }

    function depositForOwner(address _owner, uint168 _tokenAmount, uint32 _realTimeCVIValue, bool _shouldStake) external override returns (uint256 hedgedThetaTokensMinted) {
        require(msg.sender == fulfiller);
        require(_tokenAmount > 0, "Zero amount");

        uint168 holdings = _tokenAmount * depositHoldingsPercentage / MAX_PERCENTAGE;

        uint256 supply = totalSupply();

        (uint32 cviValue,,) = megaThetaVault.thetaVault().volToken().platform().cviOracle().getCVILatestRoundData();

        uint32 megaThetaVaultBalanceCVI = cviValue;
        if (_realTimeCVIValue < megaThetaVaultBalanceCVI) {
            megaThetaVaultBalanceCVI = _realTimeCVIValue;
        }

        uint32 reversePlatformBalanceCVI = cviValue;
        if (_realTimeCVIValue > reversePlatformBalanceCVI) {
            reversePlatformBalanceCVI = _realTimeCVIValue;
        }

        // Using min cvi for the mega theta vault balance (as it makes the platform balance larger), and max cvi for the inverse balance (that makes the inverse platform balance larger),
        // so that the total balance will be higher, and user's share smaller, not allowing front run
        (uint256 balance,,,) = totalBalance(megaThetaVaultBalanceCVI, reversePlatformBalanceCVI);
    
        if (supply > 0 && balance > 0) {
            hedgedThetaTokensMinted = _tokenAmount * supply / balance;
        } else {
            hedgedThetaTokensMinted = _tokenAmount * initialTokenToHedgedThetaTokenRate;
        }

        _mint(_shouldStake ? address(this) : _owner, hedgedThetaTokensMinted);

        token.safeTransferFrom(_owner, address(this), _tokenAmount);
        megaThetaVault.deposit(_tokenAmount - holdings, cviValue);

        if (_shouldStake) {
            rewardRouter.stakeForAccount(StakedTokenName.HEDGED_VAULT, _owner, hedgedThetaTokensMinted);
        }

        emit HedgedDeposit(_owner, _tokenAmount, holdings, hedgedThetaTokensMinted);
    }

    function withdrawForOwner(address _owner, uint168 _hedgedThetaTokenAmount, uint32 _realTimeCVIValue) external override returns (uint256 tokensReceived) {
        require(_hedgedThetaTokenAmount > 0, "Zero amount");
        
        uint256 totalHoldings = token.balanceOf(address(this));
        uint256 holdingsToWithdraw = totalHoldings * _hedgedThetaTokenAmount / totalSupply();
        uint256 lpTokensToWithdraw = IERC20(address(inversePlatform)).balanceOf(address(this)) * _hedgedThetaTokenAmount / totalSupply();
        uint168 thetaTokensToWithdraw = uint168(IERC20(address(megaThetaVault)).balanceOf(address(this)) * _hedgedThetaTokenAmount / totalSupply());

        (uint32 cviValue,,) = megaThetaVault.thetaVault().volToken().platform().cviOracle().getCVILatestRoundData();

        if (lpTokensToWithdraw > 0) {
            uint32 inversePlatformBalanceCVI = cviValue;
            if (_realTimeCVIValue < inversePlatformBalanceCVI) {
                inversePlatformBalanceCVI = _realTimeCVIValue;
            }

            // We use maximum cvi for the inverse platform balance, so that the balance is minimal (positions are short and worth more),
            // thus not allowing front run
            (uint256 inversePlatformBalance,) = inversePlatform.totalBalance(true, inversePlatformBalanceCVI);
            uint256 amountExpectedToWithdraw = lpTokensToWithdraw * 
                inversePlatformBalance / IERC20(address(inversePlatform)).totalSupply();

            // Check if withdrawing is possible, and if not, try to compensate from holdings, otherwise revert
            (bool canWithdrawEnough, uint256 maxLPTokensWithdrawPossible) = inversePlatform.canWithdraw(amountExpectedToWithdraw, inversePlatformBalanceCVI);
            if (!canWithdrawEnough) {
                lpTokensToWithdraw = maxLPTokensWithdrawPossible;
            }

            // Need to withdraw so that outcome is smallest, so inverse cvi should be lowest, so cvi should be max
            (, tokensReceived) = inversePlatform.withdrawLPTokens(lpTokensToWithdraw, inversePlatformBalanceCVI);

            if (!canWithdrawEnough) {
                holdingsToWithdraw += (amountExpectedToWithdraw - tokensReceived);
                require(holdingsToWithdraw < totalHoldings, "Not enough holdings");
            }
        }

        tokensReceived += holdingsToWithdraw;

        {
            uint32 burnCVIValue = cviValue;
            uint32 withdrawCVIValue = cviValue;

            if (_realTimeCVIValue > withdrawCVIValue) {
                withdrawCVIValue = _realTimeCVIValue;
            }

            if (_realTimeCVIValue < burnCVIValue) {
                burnCVIValue = _realTimeCVIValue;
            }

            // Need to minimize amounts when withdrawing, so for burning, 
            // cvi should be minimum, and for withdrawing from platform, it should be maximum (making the total balance smaller),
            // so to not allow front run
            tokensReceived += megaThetaVault.withdraw(thetaTokensToWithdraw, burnCVIValue, withdrawCVIValue);
        }

        _burn(_owner, _hedgedThetaTokenAmount);

        uint256 withdrawFee = tokensReceived * withdrawFeePercentage / MAX_PERCENTAGE;
        tokensReceived -= withdrawFee;

        // Note: approving just before sending to support updating the feesCollector via setter in Platform
        IFeesCollector feesCollector = megaThetaVault.thetaVault().platform().feesCollector();
        token.safeApprove(address(feesCollector), withdrawFee);
        feesCollector.sendProfit(withdrawFee, IERC20(address(token)));
        token.safeTransfer(_owner, tokensReceived);

        emit HedgedWithdraw(_owner, tokensReceived, _hedgedThetaTokenAmount);
    }

    function adjustHedge(bool _withdrawFromVault) external override {
        require(msg.sender == hedgeAdjuster, 'Not Allowed');
        (uint32 cviValue,,) = megaThetaVault.thetaVault().volToken().platform().cviOracle().getCVILatestRoundData();

        uint256 totalOIBalance = megaThetaVault.calculateOIBalance();
        uint256 targetExtraLiquidityNeeded = totalOIBalance * 
            (uint256(cviValue) - inversePlatform.minCVIValue()) * inversePlatform.maxPositionProfitPercentageCovered() / MAX_PERCENTAGE / cviValue;

        uint256 currentExtraLiquidity = inversePlatform.totalLeveragedTokensAmount() - inversePlatform.totalPositionsOriginalAmount();

        if (targetExtraLiquidityNeeded > currentExtraLiquidity) {
            uint256 amountToDeposit = targetExtraLiquidityNeeded - currentExtraLiquidity;
            uint256 totalHoldings = token.balanceOf(address(this));
            if (amountToDeposit > totalHoldings) {
                if (_withdrawFromVault) {
                    // Note: in this case, the holdings are not enough, so attempt to withdraw from mega theta vault to
                    // compenstate. If such withdraw reverts, the adjustHedge will revert, waiting for its next run hoping that
                    // withdraw will be possible. The theta vault's cap should increase greatly the chances of the withdraw
                    // succeeding unless in rare edge cases
                    uint256 amountToWithdraw = amountToDeposit - totalHoldings;
                    (uint256 megaThetaBalance,,) = megaThetaVault.totalBalance(cviValue);
                    uint256 thetaTokensToWithdraw = amountToWithdraw * 
                        IERC20(address(megaThetaVault)).balanceOf(address(this)) / megaThetaBalance;
                    require(uint168(thetaTokensToWithdraw) == thetaTokensToWithdraw);
                    uint256 withdrawTokens = megaThetaVault.withdraw(uint168(thetaTokensToWithdraw), cviValue, cviValue);

                    amountToDeposit = totalHoldings + withdrawTokens;
                } else {
                    amountToDeposit = totalHoldings;   
                }
            }

            inversePlatform.deposit(amountToDeposit, 0, cviValue);
        } else {
            uint256 amountToWithdraw = currentExtraLiquidity - targetExtraLiquidityNeeded;
            (bool canWithdraw, uint256 maxLPTokensToWithdraw) = inversePlatform.canWithdraw(amountToWithdraw, cviValue);

            if (canWithdraw) {
                inversePlatform.withdraw(amountToWithdraw, type(uint256).max, cviValue);
            } else {
                inversePlatform.withdrawLPTokens(maxLPTokensToWithdraw, cviValue);
            }

            uint256 currHoldings = token.balanceOf(address(this));
            (uint256 currBalance,,,) = totalBalance(cviValue, cviValue);
            uint256 maxHoldings = currBalance * depositHoldingsPercentage / MAX_PERCENTAGE;
            if (currHoldings >= maxHoldings) {
                require(uint168(currHoldings - maxHoldings) == currHoldings - maxHoldings);
                megaThetaVault.deposit(uint168(currHoldings - maxHoldings), cviValue);
            }
        }
    }

    function setFulfiller(address _newFulfiller) external override onlyOwner {
        fulfiller = _newFulfiller;

        emit FulfillerSet(_newFulfiller);
    }

    function setHedgeAdjuster(address _newHedgeAdjuster) external override onlyOwner {
        hedgeAdjuster = _newHedgeAdjuster;

        emit HedgeAdjusterSet(_newHedgeAdjuster);
    }

    function setRewardRouter(IRewardRouter _rewardRouter, address _thetaRewardTracker) external override onlyOwner {
        if (thetaRewardTracker != address(0)) {
            IERC20(address(this)).safeApprove(thetaRewardTracker, 0);
        }

        rewardRouter = _rewardRouter;
        thetaRewardTracker = _thetaRewardTracker;

        IERC20(address(this)).safeApprove(_thetaRewardTracker, type(uint256).max);

        emit RewardRouterSet(address(_rewardRouter), _thetaRewardTracker);
    }

    function setDepositHoldingsPercentage(uint32 _newHoldingsPercentage) external override onlyOwner {
        depositHoldingsPercentage = _newHoldingsPercentage;

        emit DepositHoldingsPercentageSet(_newHoldingsPercentage);
    }

    function setWithdrawFeePercentage(uint32 _newWithdarwFeePercentage) external override onlyOwner {
        withdrawFeePercentage = _newWithdarwFeePercentage;

        emit WithdrawFeePercentageSet(_newWithdarwFeePercentage);
    }

    function totalBalance(uint32 _megaThetaVaultBalanceCVI, uint32 _reversePlatformBalanceCVI) public override view returns (uint256 balance, uint256 inversePlatformLiquidity, uint256 holdings, uint256 megaThetaVaultBalance) {
        holdings = token.balanceOf(address(this));

        (uint256 totalMegaThetaVaultBalance,,) = megaThetaVault.totalBalance(_megaThetaVaultBalanceCVI);
        megaThetaVaultBalance = IERC20(address(megaThetaVault)).totalSupply() == 0 ? 0 : 
            totalMegaThetaVaultBalance * IERC20(address(megaThetaVault)).balanceOf(address(this)) / IERC20(address(megaThetaVault)).totalSupply();

        (uint256 inversePlatformBalance,) = inversePlatform.totalBalance(true, _reversePlatformBalanceCVI);
        inversePlatformLiquidity = IERC20(address(inversePlatform)).totalSupply() == 0 ? 0 : 
            inversePlatformBalance * IERC20(address(inversePlatform)).balanceOf(address(this)) / IERC20(address(inversePlatform)).totalSupply();

        balance = holdings + megaThetaVaultBalance + inversePlatformLiquidity;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IComputedCVIOracle {
    function getComputedCVIValue(uint32 cviTruncatedOracleValue) external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface ICVIOracle {
    function getCVIRoundData(uint80 roundId) external view returns (uint32 cviValue, uint256 cviTimestamp);
    function getCVILatestRoundData() external view returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
    function getTruncatedCVIValue(int256 cviOracleValue) external view returns (uint32);
    function getTruncatedMaxCVIValue() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";
import "./IFundingFeeAdjuster.sol";

interface IFeesCalculator {

    struct CVIValue {
        uint256 period;
        uint32 positionCVIValue;
        uint32 fundingFeeCVIValue;
    }

    struct SnapshotUpdate {
        uint256 latestSnapshot;
        uint256 singleUnitFundingFee;
        uint256 cviValueTimestamp;
        uint80 newLatestRoundId;
        uint32 cviValue;
        bool updatedSnapshot;
        bool updatedLatestRoundId;
        bool updatedLatestTimestamp;
    }

    function calculateBuyingPremiumFee(uint168 tokenAmount, uint8 leverage, uint32 openPositionLPFeePercentDeduction, uint256 lastTotalLeveragedTokens, uint256 lastTotalPositionUnits, uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint168 buyingPremiumFee, uint32 combinedPremiumFeePercentage);

    function calculateSingleUnitFundingFee(CVIValue[] memory cviValues) external view returns (uint256 fundingFee);
    function calculateSingleUnitPeriodFundingFee(CVIValue memory cviValue) external view returns (uint256 fundingFee, uint256 fundingFeeRatePercents);
    function updateSnapshots(uint256 latestTimestamp, uint256 blockTimestampSnapshot, uint256 latestTimestampSnapshot, uint80 latestOracleRoundId) external view returns (SnapshotUpdate memory snapshotUpdate);

    function calculateWithdrawFeePercent(uint256 lastDepositTimestamp) external view returns (uint32);

    function calculateCollateralRatio(uint256 totalLeveragedTokens, uint256 totalPositionUnits) external view returns (uint256 collateralRatio);

    function depositFeePercent() external view returns (uint32);
    function withdrawFeePercent() external view returns (uint32);
    function openPositionFeePercent() external view returns (uint32);
    function closePositionFeePercent() external view returns (uint32);
    function openPositionLPFeePercent() external view returns (uint32);
    function closePositionLPFeePercent() external view returns (uint32);
    function buyingPremiumFeeMaxPercent() external view returns (uint32);

    function openPositionFees(bytes32 referralCode) external view returns (uint32 openPositionFeePercentResult, address affiliate, uint32 affiliatePositionFeePercent, uint32 openPositionLPFeeReductionPercent);
    function closePositionFees(bytes32 referralCode) external view returns (uint32 closePositionFeePercentResult, uint32 closePremiumFeePercentResult, address affiliate, uint32 affiliatePositionFeePercent);
    function setTraderReferralCode(bytes32 referralCode, address trader) external;

    function getCollateralToBuyingPremiumMapping() external view returns (uint32[] memory);
    function feesCVIOracle() external view returns (ICVIOracle);
    function fundingFeeAdjuster() external view returns (IFundingFeeAdjuster);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFeesCollector {
    function sendProfit(uint256 amount, IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IFundingFeeAdjuster {

    function calculateFundingFeePercentage(uint32 cviValue, bool isReverse, uint32 fundingFeeMultiplier) external view returns (uint256 fundingFeeRatePercents);
    function calculateFundingFeePercentage(uint32 cviValue, uint32 fundingFeeMultiplier, uint32 multiplier) external view returns (uint256 fundingFeeRatePercents);
    function getFundingFeeCoefficients() external view returns(uint32[] memory);

    function fundingFeeMaxRate() external view returns (uint32);

    function fundingFeeLongMultiplier() external view returns (uint32);
    function fundingFeeShortMultiplier() external view returns (uint32);

    function fundingFeeMinShortRate() external view returns (uint32);
    function fundingFeeShortRange() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IHedgedThetaVault {

    event HedgedDeposit(address indexed account, uint168 totalUSDCAmount, uint168 holdingsAmount, uint256 mintedHedgedThetaTokens);
    event HedgedWithdraw(address indexed account, uint256 totalUSDCAmount, uint256 burnedHedgedThetaTokens);

    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue, bool shouldStake) external returns (uint256 hedgedThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 hedgedThetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);

    function totalBalance(uint32 megaThetaVaultBalanceCVI, uint32 reversePlatformBalanceCVI) external view returns (uint256 balance, uint256 inversePlatformLiquidity, uint256 holdings, uint256 megaThetaVaultBalance);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import '@coti-cvi/contracts-staking/contracts/interfaces/IRewardRouter.sol';

interface IHedgedThetaVaultManagement {

	event FulfillerSet(address newFulfiller);
	event HedgeAdjusterSet(address newHedgeAdjuster);
	event RewardRouterSet(address rewardRouter, address thetaRewardTracker);
	event DepositHoldingsPercentageSet(uint32 newHoldingsPercentage);
	event WithdrawFeePercentageSet(uint32 newWithdarwFeePercentage);

    function adjustHedge(bool withdrawFromVault) external;

    function setFulfiller(address newFulfiller) external;
    function setHedgeAdjuster(address newHedgeAdjuster) external;
    function setRewardRouter(IRewardRouter rewardRouter, address thetaRewardTracker) external;

    function setDepositHoldingsPercentage(uint32 newHoldingsPercentage) external;
    function setWithdrawFeePercentage(uint32 newWithdarwFeePercentage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import './IThetaVault.sol';

interface IMegaThetaVault {

    event Deposit(address indexed account, uint256 totalUSDCAmount, uint256 mintedCVIThetaTokens, uint256 mintedUCVIThetaTokens, uint256 mintedMegaThetaTokens);
    event Withdraw(address indexed account, uint256 totalUSDCAmount,  uint256 burnedCVIThetaTokens,  uint256 burnedUCVIThetaTokens,  uint256 burnedMegaThetaTokens);

    function depositForOwner(address owner, uint168 tokenAmount, uint32 realTimeCVIValue) external returns (uint256 megaThetaTokensMinted);
    function withdrawForOwner(address owner, uint168 thetaTokenAmount, uint32 realTimeCVIValue) external returns (uint256 tokenWithdrawnAmount);

    function deposit(uint168 tokenAmount, uint32 balanceCVIValue) external returns (uint256 megaThetaTokensMinted);
    function withdraw(uint168 thetaTokenAmount, uint32 burnCVIValue, uint32 withdrawCVIValue) external returns (uint256 tokenWithdrawnAmount);

    function totalBalance(uint32 balanceCVIValue) external view returns (uint256 balance, uint256 cviBalance, uint256 ucviBalance);
    function calculateOIBalance() external view returns (uint256 oiBalance);
    function calculateMaxOIBalance() external view returns (uint256 maxOIBalance);

    function thetaVault() external view returns (IThetaVault);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import './IThetaVault.sol';

interface IMegaThetaVaultManagement {

	event FulfillerSet(address newFulfiller);
	event DepositorSet(address newDepositor);
	event MinAmountsSet(uint256 newMinDepositAmount, uint256 newMinWithdrawAmount);
	event DepositCapSet(uint256 newDepositCap);
	event MinRebalanceDiffSet(uint256 newMinRebalanceDiff);

    function rebalance(uint16 cviThetaVaultPercentage) external;

    function setFulfiller(address newFulfiller) external;
    function setDepositor(address newDepositor) external;
    function setDepositCap(uint256 newDepositCap) external;
    function setMinRebalanceDiff(uint256 newMinRebalanceDiff) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IOldPlatformMinimal {
    function totalPositionUnitsAmount() external view returns (uint256);
    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint32 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
    
    function closePosition(uint168 positionUnitsAmount, uint32 minCVI) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import '@coti-cvi/contracts-staking/contracts/interfaces/IRewardRouter.sol';

import "./IOldVolTokenMinimal.sol";

import './IUniswapHelper.sol';

import '../external/ISwapRouter.sol';
import '../external/INonfungiblePositionManager.sol';

interface IOldThetaVaultMinimal {

    event SubmitRequest(uint256 requestId, uint8 requestType, uint256 tokenAmount, uint32 targetTimestamp, address indexed account, uint256 totalUSDCBalance, uint256 totalSupply);
    event FulfillDeposit(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenUSDCAmount, uint256 dexVolTokenAmount, uint256 dexUSDCAmount, uint256 mintedThetaTokens);
    event FulfillWithdraw(uint256 requestId, address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenAmount, uint256 dexUSDCVolTokenAmount, uint256 dexUSDCAmount, uint256 burnedThetaTokens);
    event LiquidateRequest(uint256 requestId, uint8 requestType, address indexed account, address indexed liquidator, uint256 tokenAmount);

    function submitDepositRequest(uint168 tokenAmount/* , bool shouldStake */) external returns (uint256 requestId);
    function submitWithdrawRequest(uint168 thetaTokenAmount) external returns (uint256 requestId);

    function fulfillDepositRequest(uint256 requestId) external returns (uint256 thetaTokensMinted);
    function fulfillWithdrawRequest(uint256 requestId) external returns (uint256 tokenWithdrawnAmount);

    function liquidateRequest(uint256 requestId) external;

    function rebalance() external;

    function setRewardRouter(IRewardRouter rewardRouter, IRewardTracker rewardTracker) external;
    function setFulfiller(address newFulfiller) external;
    function setMinPoolSkew(uint16 newMinPoolSkewPercentage) external;
    function setLiquidityPercentages(uint16 newExtraLiquidityPercentage, uint16 minDexPercentageAllowed) external;
    function setRequestDelay(uint256 newRequestDelay) external;
    function setDepositCap(uint256 newDepositCap) external;
    function setPeriods(uint256 newLockupPeriod, uint256 newLiquidationPeriod) external;
    function setMinAmounts(uint256 newMinDepositAmount, uint256 newMinWithdrawAmount) external;
    function setDepositHoldings(uint16 newDepositHoldingsPercentage) external;
    
    function volToken() external view returns (IOldVolTokenMinimal);

    function totalBalance() external view returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount);
    function requests(uint256 requestId) external view returns (uint8 requestType, uint168 tokenAmount, uint32 targetTimestamp, address owner, bool shouldStake);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IOldVolTokenMinimal {
    function mintTokens(uint168 tokenAmount) external returns (uint256 tokensMinted);
    function burnTokens(uint168 burnAmount) external returns (uint256 tokensReceived);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";
import "./IFeesCalculator.sol";
import "./IFeesCollector.sol";

interface IPlatform {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint32 openCVIValue;
        uint32 creationTimestamp;
        uint256 originalCreationBlock;
        bytes32 referralCode;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue, bytes32 referralCode, address indexed affiliate, uint32 affiliatePositionFeePercent, uint256 affiliateRebateAmount);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 fundingFeesAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue, bytes32 referralCode, address indexed affiliate, uint32 affiliatePositionFeePercent, uint256 affiliateRebateAmount);
    event MergePosition(address indexed account, uint256 tokenAmount, uint256 fundingFeesAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, uint256 fundingFeesAmount, bool isBalancePositive, uint256 positionUnitsAmount, uint256 openCVIValue, uint8 leverage, uint256 liquidationCVIValue);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount, uint32 cviValue) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount, uint32 cviValue) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount, uint32 cviValue) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function openPositionForOwner(address owner, bytes32 referralCode, uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage, uint32 realTimeCVIValue) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function openPosition(uint168 tokenAmount, uint32 maxCVI, uint32 maxBuyingPremiumFeePercentage, uint8 leverage, bool chargeFees, uint32 closeCVIValue, uint32 cviValue) external returns (uint168 positionUnitsAmount, uint168 positionedTokenAmount, uint168 openPositionFee, uint168 buyingPremiumFee);
    function closePositionForOwner(address owner, uint168 positionUnitsAmount, uint32 minCVI, uint32 realTimeCVIValue) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);
    function closePosition(uint168 positionUnitsAmount, uint32 minCVI, bool chargeFees, uint32 cviValue) external returns (uint256 tokenAmount, uint256 closePositionFee, uint256 closingPremiumFee);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionBalanceWithIndex(address positionAddress, uint32 cviValue) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance(bool withAddendum, uint32 cviValue) external view returns (uint256 balance, uint256 positionsBalance);

    function canWithdraw(uint256 tokenAmount, uint32 cviValue) external view returns (bool canWithdraw, uint256 maxLPTokensWithdrawAmount);

    function cviOracle() external view returns (ICVIOracle);
    function feesCalculator() external view returns (IFeesCalculator);
    function feesCollector() external view returns (IFeesCollector);

    function PRECISION_DECIMALS() external view returns (uint256);

    function totalPositionUnitsAmount() external view returns (uint256);
    function totalPositionsOriginalAmount() external view returns (uint256);
    function totalLeveragedTokensAmount() external view returns (uint256);
    function totalFundingFeesAmount() external view returns (uint256);
    function latestFundingFees() external view returns (uint256);
    function isReverse() external view returns (bool);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint32 openCVIValue, uint32 creationTimestamp, uint256 originalCreationBlock, bytes32 referralCode);
    function maxCVIValue() external view returns (uint32);
    function minCVIValue() external view returns (uint32);
    function maxPositionProfitPercentageCovered() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

interface IRequestManager {

	function nextRequestId() external view returns (uint256);
    function minRequestId() external view returns (uint256);
    function maxMinRequestIncrements() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IThetaVaultInfo.sol";
import "./IVolatilityToken.sol";
import "./IPlatform.sol";
import "./IUniswapV3LiquidityManager.sol";

import "../external/ISwapRouter.sol";
import "../external/INonfungiblePositionManager.sol";

interface IThetaVault is IThetaVaultInfo {

    event Deposit(address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenUSDCAmount, uint256 dexVolTokenAmount, uint256 dexUSDCAmount, uint256 mintedThetaTokens);
    event Withdraw(address indexed account, uint256 totalUSDCAmount, uint256 platformLiquidityAmount, uint256 dexVolTokenAmount, uint256 dexUSDCVolTokenAmount, uint256 dexUSDCAmount, uint256 burnedThetaTokens);

    function deposit(uint168 tokenAmount, uint32 balanceCVIValue) external returns (uint256 thetaTokensMinted);
    function withdraw(uint168 thetaTokenAmount, uint32 burnCVIValue, uint32 withdrawCVIValue) external returns (uint256 tokenWithdrawnAmount);

    function volToken() external view returns (IVolatilityToken);
    function platform() external view returns (IPlatform);
    function liquidityManager() external view returns (IUniswapV3LiquidityManager);
    function totalBalance(uint32 cviValue) external view returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount);
    function calculateOIBalance() external view returns (uint256 oiBalance);
    function calculateMaxOIBalance() external view returns (uint256 maxOIBalance);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./ICVIOracle.sol";

interface IThetaVaultInfo {
    function platformPositionUnits() external view returns (uint256);
    function vaultPositionUnits() external view returns (uint256);
    function extraLiquidityPercentage() external view returns (uint32);
    function minDexPercentageAllowed() external view returns (uint16);

    function oracle() external view returns (ICVIOracle);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IUniswapV3LiquidityManager.sol";
import "../external/ISwapRouter.sol";

interface IThetaVaultManagement {

    event RangeSet(uint160 minPriceSqrtX96, uint160 maxPriceSqrtX96);
    event SwapRouterSet(address newSwapRouter);
    event LiquidityManagerSet(address newLiquidityManager);
    event ManagerSet(address newManager);
    event RebaserSet(address newRebaser);
    event DepositorSet(address newDepositor);
    event MinPoolSkewSet(uint16 newMinPoolSkewPercentage);
    event LiquidityPercentagesSet(uint32 newExtraLiquidityPercentage, uint16 minDexPercentageAllowed);
    event MinRebalanceDiffSet(uint256 newMinRebalanceDiff);
    event DepositHoldingsSet(uint16 newDepositHoldingsPercentage);

    function rebalance(uint32 cviValue) external;
    function rebaseCVI() external;

    function setRange(uint160 minPriceSqrtX96, uint160 maxPriceSqrtX96) external;

    function setSwapRouter(ISwapRouter newSwapRouter) external;
    function setLiquidityManager(IUniswapV3LiquidityManager newLiquidityManager) external;
    function setManager(address newManager) external;
    function setRebaser(address newRebaser) external;
    function setDepositor(address newDepositor) external;
    function setMinPoolSkew(uint16 newMinPoolSkewPercentage) external;
    function setLiquidityPercentages(uint32 newExtraLiquidityPercentage, uint16 minDexPercentageAllowed) external;
    function setMinRebalanceDiff(uint256 newMinRebalanceDiff) external;
    function setDepositHoldings(uint16 newDepositHoldingsPercentage) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.6;

pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IUniswapHelper {

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external view returns (int24 tick);
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96);
    function getSpotPrice(IUniswapV3Pool pool, bool isVolTokenToken0) external view returns (uint256 price);
    function getTWAPPriceDelta(IUniswapV3Pool pool, uint32 interval) external view returns (uint256 priceChange, uint256 fromPrice);

    function getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0) external pure returns (uint128 liquidity);
    function getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount1) external pure returns (uint128 liquidity);
    function getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) external pure returns (uint256 amount0);
    function getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity) external pure returns (uint256 amount1);
    function uint256ToX96(uint256 number) external pure returns (uint160 result);

    function PRECISION_DECIMALS() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IUniswapV3LiquidityManager {

    function addDEXLiquidity(uint256 mintedVolTokenAmount, uint256 usdcAmount) external returns (uint256 addedUDSCAmount, uint256 addedVolTokenAmount);
    function removeDEXLiquidity(uint256 partOfAmount, uint256 totalAmount) external returns (uint256 removedVolTokensAmount, uint256 dexRemovedUSDC);
    function burnPosition() external;
    function setRange(uint160 minPriceSqrtX96, uint160 maxPriceSqrtX96) external;
    function collectFees() external returns (uint256 volTokenAmount, uint256 usdcAmount);
    function updatePoolPrice(uint256 volTokenPositionBalance) external;
    function hasPosition() external view returns (bool);
    function calculateDEXLiquidityUSDCAmount(uint256 tokenAmount) external view returns (uint256 usdcDEXAmount);
    function calculateArbitrageAmount(uint256 volTokenBalance) external view returns (uint256 usdcAmount);

    struct CalculateDepositParams {
        uint256 depositAmount;
        uint256 cviValue;
        uint256 intrinsicVolTokenPrice;
        uint256 maxCVIValue;
        uint256 extraLiquidityPercentage;
    }

    function calculateDepositMintVolTokensUSDCAmount(CalculateDepositParams calldata params) external view returns (uint256 mintVolTokenUDSCAmount);
    function getReserves() external view returns (uint256 volTokenAmount, uint256 dexUSDCByVolToken, uint256 usdcAmount);
    function getVaultDEXVolTokens() external view returns (uint256 vaultDEXVolTokens);
    function getVaultDEXBalance(uint256 intrinsicDEXVolTokenBalance, uint256 dexUSDCAmount) external view returns (uint256 vaultIntrinsicDEXVolTokenBalance, uint256 vaultDEXUSDCAmount);
    function getDexPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "./IPlatform.sol";

interface IVolatilityToken {

    event Mint(uint256 requestId, address indexed account, uint256 tokenAmount, uint256 positionedTokenAmount, uint256 mintedTokens, uint256 openPositionFee, uint256 buyingPremiumFee);
    event Burn(uint256 requestId, address indexed account, uint256 tokenAmountBeforeFees, uint256 tokenAmount, uint256 burnedTokens, uint256 closePositionFee, uint256 closingPremiumFee);

    function mintTokensForOwner(address owner, uint168 tokenAmount, uint32 maxBuyingPremiumFeePercentage, uint32 realTimeCVIValue) external returns (uint256 tokensMinted);
    function burnTokensForOwner(address owner, uint168 burnAmount, uint32 realTimeCVIValue) external returns (uint256 tokensReceived);
    function mintTokens(uint168 tokenAmount, uint32 closeCVIValue, uint32 cviValue) external returns (uint256 tokensMinted);
    function burnTokens(uint168 burnAmount, uint32 cviValue) external returns (uint256 tokensReceived);

    function platform() external view returns (IPlatform);
    function leverage() external view returns (uint8);
    function initialTokenToLPTokenRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IPlatform.sol";
import "./IFeesCollector.sol";
import "./IFeesCalculator.sol";
import "./ICVIOracle.sol";
import "./IThetaVault.sol";

interface IVolatilityTokenManagement {

    event MinterSet(address minter);
    event PlatformSet(address newPlatform, address newToken, address swapRouter);
    event FeesCalculatorSet(address newFeesCalculator);
    event FeesCollectorSet(address newCollector);
    event CVIOracleSet(address newCVIOracle);
    event DeviationParametersSet(uint16 newDeviationPercentagePerSingleRebaseLag, uint16 newMinDeviationPercentage, uint16 newMaxDeviationPercentage);
    event CappedRebaseSet(bool newCappedRebase);
    event ThetaVaultSet(address newThetaVault);
    event PositionManagerSet(address newPositionManagerAddress);
    event FulfillerSet(address newFulfiller);
    event PostLiquidationMaxMintAmountSet(uint256 newPostLiquidationMaxMintAmount);

    function rebaseCVI() external;

    function setMinter(address minter) external;
    function setPlatform(IPlatform newPlatform, IERC20Upgradeable newToken, ISwapRouter swapRouter) external;
    function setFeesCalculator(IFeesCalculator newFeesCalculator) external;
    function setFeesCollector(IFeesCollector newCollector) external;
    function setCVIOracle(ICVIOracle newCVIOracle) external;
    function setDeviationParameters(uint16 newDeviationPercentagePerSingleRebaseLag, uint16 newMinDeviationPercentage, uint16 newMaxDeviationPercentage) external;
    function setCappedRebase(bool newCappedRebase) external;
    function setThetaVault(IThetaVault newThetaVault) external;
    function setPositionManager(address newPositionManagerAddress) external;

    function setFulfiller(address newFulfiller) external;

    function setPostLiquidationMaxMintAmount(uint256 newPostLiquidationMaxMintAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IMegaThetaVault.sol';
import './interfaces/IMegaThetaVaultManagement.sol';
import './interfaces/IComputedCVIOracle.sol';

contract MegaThetaVault is Initializable, IMegaThetaVault, IMegaThetaVaultManagement, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    uint256 public constant MAX_PERCENTAGE = 10000;

    address public fulfiller;
    address public depositor;

    IThetaVault public override thetaVault;
    IThetaVault public ucviThetaVault;
    IERC20 internal token;

    uint256 public initialTokenToThetaTokenRate;

    uint256 public minRebalanceDiff;
    uint256 public depositCap;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _initialTokenToThetaTokenRate, IThetaVault _thetaVault, IThetaVault _ucviThetaVault, 
            IERC20 _token, string memory _lpTokenName, string memory _lpTokenSymbolName) public initializer {
        require(address(_thetaVault) != address(0));
        require(address(_ucviThetaVault) != address(0));
        require(address(_token) != address(0));
        require(_initialTokenToThetaTokenRate > 0);

        initialTokenToThetaTokenRate = _initialTokenToThetaTokenRate;

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init(_lpTokenName, _lpTokenSymbolName);

        thetaVault = _thetaVault;
        ucviThetaVault = _ucviThetaVault;
        token = _token;
        minRebalanceDiff = 100000000; // 100 USD
        depositCap = type(uint256).max;

        token.safeApprove(address(thetaVault), type(uint256).max);
        token.safeApprove(address(ucviThetaVault), type(uint256).max);
        IERC20(address(thetaVault)).safeApprove(address(thetaVault), type(uint256).max);
        IERC20(address(ucviThetaVault)).safeApprove(address(ucviThetaVault), type(uint256).max);
    }

    function depositForOwner(address _owner, uint168 _tokenAmount, uint32 _realTimeCVIValue) external override returns (uint256 thetaTokensMinted) {
        require(msg.sender == fulfiller);

        (uint32 cviValue,,) = thetaVault.volToken().platform().cviOracle().getCVILatestRoundData();
        uint32 balanceCVIValue = cviValue;
        if (_realTimeCVIValue < balanceCVIValue) {
            balanceCVIValue = _realTimeCVIValue;
        }

        // Using minimum cvi value, so balance will be highest (as it makes platform balance larger), not allowing users to frontrun
        return _deposit(_owner, _tokenAmount, balanceCVIValue);
    }

    function deposit(uint168 _tokenAmount, uint32 _balanceCVIValue) external override returns (uint256 thetaTokensMinted) {
        require(msg.sender == depositor);
        return _deposit(msg.sender, _tokenAmount, _balanceCVIValue);
    }

    function withdrawForOwner(address _owner, uint168 _thetaTokenAmount, uint32 _realTimeCVIValue) external override returns (uint256 tokenWithdrawnAmount) {
        require(msg.sender == fulfiller);

        (uint32 cviValue,,) = thetaVault.volToken().platform().cviOracle().getCVILatestRoundData();
        uint32 burnCVIValue = cviValue;
        uint32 withdrawCVIValue = cviValue;

        if (_realTimeCVIValue < burnCVIValue) {
            burnCVIValue = _realTimeCVIValue;
        }

        if (_realTimeCVIValue > withdrawCVIValue) {
            withdrawCVIValue = _realTimeCVIValue;
        }

        // Using minimum cvi to burn tokens (so they yield less tokens in total worth), 
        // and maximum cvi for platform balance when withdrawing (as it makes platform balance smaller),
        // to have less total balance and not allow frontrun
        return _withdraw(_owner, _thetaTokenAmount, burnCVIValue, withdrawCVIValue);
    }

    function withdraw(uint168 _thetaTokenAmount, uint32 _burnCVIValue, uint32 _withdrawCVIValue) external override returns (uint256 tokenWithdrawnAmount) {
        require(msg.sender == depositor);
        return _withdraw(msg.sender, _thetaTokenAmount, _burnCVIValue, _withdrawCVIValue);
    }

    function setFulfiller(address _newFulfiller) external override onlyOwner {
        fulfiller = _newFulfiller;

        emit FulfillerSet(_newFulfiller);
    }

    function setDepositor(address _newDepositor) external override onlyOwner {
        depositor = _newDepositor;

        emit DepositorSet(_newDepositor);
    }

    function setDepositCap(uint256 _newDepositCap) external override onlyOwner {
        depositCap = _newDepositCap;

        emit DepositCapSet(_newDepositCap);
    }

    function setMinRebalanceDiff(uint256 _newMinRebalanceDiff) external override onlyOwner {
        minRebalanceDiff = _newMinRebalanceDiff;

        emit MinRebalanceDiffSet(_newMinRebalanceDiff);
    }

    function totalBalance(uint32 _balanceCVIValue) public view returns (uint256 balance, uint256 cviBalance, uint256 ucviBalance) {
        (cviBalance,,,,,) = thetaVault.totalBalance(_balanceCVIValue);
        uint32 balanceUCVIValue = IComputedCVIOracle(address(ucviThetaVault.platform().cviOracle())).getComputedCVIValue(_balanceCVIValue);
        (ucviBalance,,,,,) = ucviThetaVault.totalBalance(balanceUCVIValue);
        balance = cviBalance + ucviBalance;
    }

    function calculateOIBalance() external view override returns (uint256 oiBalance) {
        // Note: it's an estimation that because of using ucvi, the OI balance is worth about 3 times more than regular cvi OI
        // i.e. it needs three times as much hedge to cover for potential tripled gain
        oiBalance = thetaVault.calculateOIBalance() + ucviThetaVault.calculateOIBalance() * 3;
    }

    function calculateMaxOIBalance() external view override returns (uint256 maxOIBalance) {
        maxOIBalance = thetaVault.calculateMaxOIBalance() + ucviThetaVault.calculateMaxOIBalance() * 3;
    }

    function rebalance(uint16 _cviThetaVaultPercentage) external override onlyOwner {
        (uint32 cviValue,,) = thetaVault.volToken().platform().cviOracle().getCVILatestRoundData();
        (uint256 balance, uint256 cviBalance, uint256 ucviBalance) = totalBalance(cviValue);

        uint256 destinationCVIBalance = balance * _cviThetaVaultPercentage / MAX_PERCENTAGE;

        if (destinationCVIBalance > cviBalance && destinationCVIBalance - cviBalance >= minRebalanceDiff) {
            transferBetweenVaults(destinationCVIBalance - cviBalance, ucviThetaVault, thetaVault, cviBalance, cviValue);
        } else if (cviBalance > destinationCVIBalance && cviBalance - destinationCVIBalance >= minRebalanceDiff) {
            transferBetweenVaults(cviBalance - destinationCVIBalance, thetaVault, ucviThetaVault, ucviBalance, cviValue);
        }
    }

    function toUint168(uint256 x) private pure returns (uint168 y) {
        require((y = uint168(x)) == x);
    }

    function transferBetweenVaults(uint256 amount, IThetaVault fromThetaVault, IThetaVault toThetaVault, uint256 fromBalance, uint32 cviValue) private {
        uint168 thetaWithdrawTokens = toUint168(IERC20(address(fromThetaVault)).balanceOf(address(this)) * amount / fromBalance);
        uint168 withdrawnAmount = toUint168(fromThetaVault.withdraw(thetaWithdrawTokens, cviValue, cviValue));

        toThetaVault.deposit(withdrawnAmount, cviValue);
    }

    function _deposit(address _owner, uint168 _tokenAmount, uint32 _balanceCVIValue) private returns (uint256 megaThetaTokensMinted) {
        require(_tokenAmount > 0);

        (uint256 balance,,) = totalBalance(_balanceCVIValue);

        require(balance + _tokenAmount <= depositCap, "Cap exceeded");

        // Mint theta lp tokens
        if (totalSupply() > 0 && balance > 0) {
            megaThetaTokensMinted = (_tokenAmount * totalSupply()) / balance;
        } else {
            megaThetaTokensMinted = _tokenAmount * initialTokenToThetaTokenRate;
        }

        require(megaThetaTokensMinted > 0); // "Too few tokens"
        _mint(_owner, megaThetaTokensMinted);

        token.safeTransferFrom(_owner, address(this), _tokenAmount);

        (uint32 cviValue,,) = thetaVault.volToken().platform().cviOracle().getCVILatestRoundData();
        (uint32 ucviValue,,) = ucviThetaVault.volToken().platform().cviOracle().getCVILatestRoundData();

        uint256 thetaTokensMinted = thetaVault.deposit(_tokenAmount / 2, cviValue);
        uint256 ucviThetaTokensMinted = ucviThetaVault.deposit(_tokenAmount - _tokenAmount / 2, ucviValue);

        emit Deposit(_owner, _tokenAmount, thetaTokensMinted, ucviThetaTokensMinted, megaThetaTokensMinted);
    }

    function _withdraw(address _owner, uint168 _megaThetaTokenAmount, uint32 _burnCVIValue, uint32 _withdrawCVIValue) private returns (uint256 tokenWithdrawnAmount) {
        require(_megaThetaTokenAmount > 0);

        require(balanceOf(_owner) >= _megaThetaTokenAmount, "Not enough tokens");
        IERC20(address(this)).safeTransferFrom(_owner, address(this), _megaThetaTokenAmount);

        uint168 thetaTokensToRemove = toUint168((_megaThetaTokenAmount * IERC20(address(thetaVault)).balanceOf(address(this))) / totalSupply());
        uint168 ucviThetaTokensToRemove = toUint168((_megaThetaTokenAmount * IERC20(address(ucviThetaVault)).balanceOf(address(this))) / totalSupply());

        tokenWithdrawnAmount = thetaVault.withdraw(thetaTokensToRemove, _burnCVIValue, _withdrawCVIValue);
        tokenWithdrawnAmount += ucviThetaVault.withdraw(ucviThetaTokensToRemove,
            IComputedCVIOracle(address(ucviThetaVault.platform().cviOracle())).getComputedCVIValue(_burnCVIValue), 
            IComputedCVIOracle(address(ucviThetaVault.platform().cviOracle())).getComputedCVIValue(_withdrawCVIValue));

        _burn(address(this), _megaThetaTokenAmount);
        token.safeTransfer(_owner, tokenWithdrawnAmount);

        emit Withdraw(_owner, tokenWithdrawnAmount, thetaTokensToRemove, ucviThetaTokensToRemove, _megaThetaTokenAmount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IThetaVault.sol";
import "./interfaces/IThetaVaultManagement.sol";
import "./interfaces/IVolatilityTokenManagement.sol";
import "./interfaces/IUniswapHelper.sol";

contract ThetaVault is Initializable, IThetaVault, IThetaVaultManagement, OwnableUpgradeable, ERC20Upgradeable, ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    uint256 internal constant PRECISION_DECIMALS = 18;
    uint16 internal constant MAX_PERCENTAGE = 10000;
    uint24 private constant POOL_FEE = 3000;

    address public depositor;

    IERC20 internal token;
    IPlatform public override platform;
    IVolatilityToken public override volToken;
    ISwapRouter public swapRouter;
    IUniswapV3LiquidityManager public override liquidityManager;

    address public manager;
    address public rebaser;

    uint256 public initialTokenToThetaTokenRate;

    uint16 public minPoolSkewPercentage;
    uint32 public override extraLiquidityPercentage;

    uint16 public depositHoldingsPercentage;
    uint16 public override minDexPercentageAllowed;

    uint256 public totalHoldingsAmount;

    uint256 public minRebalanceDiff;

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _initialTokenToThetaTokenRate, IPlatform _platform, IVolatilityToken _volToken,
            IERC20 _token, string memory _lpTokenName, string memory _lpTokenSymbolName, ISwapRouter _swapRouter,
            IUniswapV3LiquidityManager _liquidityManager) public initializer {
        require(address(_platform) != address(0));
        require(address(_volToken) != address(0));
        require(address(_token) != address(0));
        require(address(_swapRouter) != address(0));
        require(address(_liquidityManager) != address(0));
        require(_initialTokenToThetaTokenRate > 0);

        initialTokenToThetaTokenRate = _initialTokenToThetaTokenRate;
        minPoolSkewPercentage = 300;
        extraLiquidityPercentage = 1500;
        minRebalanceDiff = 100000;
        depositHoldingsPercentage = 1500;
        minDexPercentageAllowed = 3000;

        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        ERC20Upgradeable.__ERC20_init(_lpTokenName, _lpTokenSymbolName);

        platform = _platform;
        token = _token;
        volToken = _volToken;

        setSwapRouter(_swapRouter);
        setLiquidityManager(_liquidityManager);

        token.safeApprove(address(platform), type(uint256).max);
        token.safeApprove(address(volToken), type(uint256).max);
        IERC20(address(volToken)).safeApprove(address(volToken), type(uint256).max);
    }

    struct DepositLocals {
        uint256 mintVolTokenUSDCAmount;
        uint256 addedLiquidityUSDCAmount;
        uint256 mintedVolTokenAmount;
        uint256 platformLiquidityAmount;
        uint256 holdingsAmount;
    }

    function deposit(uint168 _tokenAmount, uint32 _balanceCVIValue) external returns (uint256 thetaTokensMinted) {
        require(msg.sender == depositor);
        require(_tokenAmount > 0);

        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        // Note: reverts if pool is skewed after arbitrage, as intended
        (uint256 balance, uint256 volTokenPositionBalance) = _rebalance(_tokenAmount, _balanceCVIValue);

        // Mint theta lp tokens
        if (totalSupply() > 0 && balance > 0) {
            thetaTokensMinted = (_tokenAmount * totalSupply()) / balance;
        } else {
            thetaTokensMinted = _tokenAmount * initialTokenToThetaTokenRate;
        }

        require(thetaTokensMinted > 0); // 'Too few tokens'
        _mint(msg.sender, thetaTokensMinted);

        DepositLocals memory locals = _deposit(_tokenAmount, volTokenPositionBalance, true);

        emit Deposit(msg.sender, _tokenAmount, locals.platformLiquidityAmount, locals.mintVolTokenUSDCAmount, locals.mintedVolTokenAmount, 
            locals.addedLiquidityUSDCAmount, thetaTokensMinted);
    }

    struct WithdrawLocals {
        uint256 withdrawnLiquidity;
        uint256 platformLPTokensToRemove;
        uint256 removedVolTokensAmount;
        uint256 dexRemovedUSDC;
        uint256 burnedVolTokensUSDCAmount;
    }

    function withdraw(uint168 _thetaTokenAmount, uint32 _burnCVIValue, uint32 _withdrawCVIValue) external override returns (uint256 tokenWithdrawnAmount) {
        require(msg.sender == depositor);
        require(_thetaTokenAmount > 0);

        require(balanceOf(msg.sender) >= _thetaTokenAmount, 'Not enough tokens');
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), _thetaTokenAmount);

        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        _rebalance(0, cviValue);

        WithdrawLocals memory locals;

        locals.platformLPTokensToRemove = (_thetaTokenAmount * IERC20(address(platform)).balanceOf(address(this))) / totalSupply();
        (locals.removedVolTokensAmount, locals.dexRemovedUSDC) = liquidityManager.removeDEXLiquidity(_thetaTokenAmount, totalSupply());

        locals.burnedVolTokensUSDCAmount = burnVolTokens(locals.removedVolTokensAmount, _burnCVIValue);

        (, locals.withdrawnLiquidity) = platform.withdrawLPTokens(locals.platformLPTokensToRemove, _withdrawCVIValue);

        uint256 withdrawHoldings = totalHoldingsAmount * _thetaTokenAmount / totalSupply();
        tokenWithdrawnAmount = withdrawHoldings + locals.withdrawnLiquidity + locals.dexRemovedUSDC + locals.burnedVolTokensUSDCAmount;
        totalHoldingsAmount -= withdrawHoldings;

        _burn(address(this), _thetaTokenAmount);

        token.safeTransfer(msg.sender, tokenWithdrawnAmount);

        emit Withdraw(msg.sender, tokenWithdrawnAmount, locals.withdrawnLiquidity, locals.removedVolTokensAmount, locals.burnedVolTokensUSDCAmount, locals.dexRemovedUSDC, _thetaTokenAmount);
    }

    function rebalance(uint32 _cviValue) external override onlyOwner {
        _rebalance(0, _cviValue);
    }

    function oracle() external view override returns (ICVIOracle) {
        return platform.cviOracle();
    }

    function platformPositionUnits() external view override returns (uint256) {
        return platform.totalPositionUnitsAmount();
    }

    function vaultPositionUnits() public view override returns (uint256) {
        (uint256 dexVolTokensAmount,, uint256 dexUSDCAmount) = liquidityManager.getReserves();
        if (IERC20(address(volToken)).totalSupply() == 0 || (dexVolTokensAmount == 0 && dexUSDCAmount == 0)) {
            return 0;
        }

        (uint256 totalPositionUnits,,,,,) = platform.positions(address(volToken));
        return totalPositionUnits * liquidityManager.getVaultDEXVolTokens() / IERC20(address(volToken)).totalSupply();
    }

    function setSwapRouter(ISwapRouter _newSwapRouter) public override onlyOwner {
        if (address(swapRouter) != address(0)) {
            token.safeApprove(address(swapRouter), 0);
            IERC20(address(volToken)).safeApprove(address(swapRouter), 0);
        }

        swapRouter = _newSwapRouter;

        token.safeApprove(address(swapRouter), type(uint256).max);
        IERC20(address(volToken)).safeApprove(address(swapRouter), type(uint256).max);

        emit SwapRouterSet(address(_newSwapRouter));
    }

    function setLiquidityManager(IUniswapV3LiquidityManager _newLiquidityManager) public override onlyOwner {
        if (address(liquidityManager) != address(0)) {
            token.safeApprove(address(liquidityManager), 0);
            IERC20(address(volToken)).safeApprove(address(liquidityManager), 0);
        }

        liquidityManager = _newLiquidityManager;

        token.safeApprove(address(liquidityManager), type(uint256).max);
        IERC20(address(volToken)).safeApprove(address(liquidityManager), type(uint256).max);

        emit LiquidityManagerSet(address(_newLiquidityManager));
    }

    function setRange(uint160 _minPriceSqrtX96, uint160 _maxPriceSqrtX96) public override {
        require(msg.sender == manager);
        _setRange(_minPriceSqrtX96, _maxPriceSqrtX96, false);

        emit RangeSet(_minPriceSqrtX96, _maxPriceSqrtX96);
    }

    function setInitialPrices(uint160 _minPriceSqrtX96, uint160 _maxPriceSqrtX96) public onlyOwner {
        _setRange(_minPriceSqrtX96, _maxPriceSqrtX96, false);
    }

    function rebaseCVI() external override {
        require(msg.sender == rebaser);
        _setRange(0, 0, true);
    }

    function setManager(address _newManager) external override onlyOwner {
        manager = _newManager;

        emit ManagerSet(_newManager);
    }

    function setRebaser(address _newRebaser) external override onlyOwner {
        rebaser = _newRebaser;

        emit RebaserSet(_newRebaser);
    }

    function setDepositor(address _newDepositor) external override onlyOwner {
        depositor = _newDepositor;

        emit DepositorSet(_newDepositor);
    }

    function setDepositHoldings(uint16 _newDepositHoldingsPercentage) external override onlyOwner {
        depositHoldingsPercentage = _newDepositHoldingsPercentage;


        emit DepositHoldingsSet(_newDepositHoldingsPercentage);
    }

    function setMinPoolSkew(uint16 _newMinPoolSkewPercentage) external override onlyOwner {
        minPoolSkewPercentage = _newMinPoolSkewPercentage;

        emit MinPoolSkewSet(_newMinPoolSkewPercentage);
    }

    function setLiquidityPercentages(uint32 _newExtraLiquidityPercentage, uint16 _minDexPercentageAllowed) external override onlyOwner {
        extraLiquidityPercentage = _newExtraLiquidityPercentage;
        minDexPercentageAllowed = _minDexPercentageAllowed;

        emit LiquidityPercentagesSet(_newExtraLiquidityPercentage, _minDexPercentageAllowed);
    }

    function setMinRebalanceDiff(uint256 _newMinRebalanceDiff) external override onlyOwner {
        minRebalanceDiff = _newMinRebalanceDiff;

        emit MinRebalanceDiffSet(_newMinRebalanceDiff);
    }

    function totalBalance(uint32 cviValue) public view override returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount, uint256 dexVolTokensAmount) {
        (intrinsicDEXVolTokenBalance, volTokenPositionBalance,, dexUSDCAmount, dexVolTokensAmount,) = calculatePoolValue();
        (balance, usdcPlatformLiquidity) = _totalBalance(intrinsicDEXVolTokenBalance, dexUSDCAmount, cviValue);
    }

    function calculateOIBalance() external view override returns (uint256 oiBalance) {
        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        (, uint256 totalPositionsBalance) = platform.totalBalance(true, cviValue);
        oiBalance = totalPositionsBalance - vaultPositionBalance();
    }

    function calculateMaxOIBalance() external view override returns (uint256 maxOIBalance) {
        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        (, uint256 oiBalance) = platform.totalBalance(true, cviValue);

        uint256 freeLiquidity = platform.totalLeveragedTokensAmount() - platform.totalPositionUnitsAmount();

        // FreeLiquidity = (MaxCVI - CurrCVI) / CurrCVI * MaxOI
        // MaxOI = FreeLiquidity * CurrCVI / (MaxCVI - CurrCVI)
        maxOIBalance = freeLiquidity * cviValue / (platform.maxCVIValue() - cviValue) + (oiBalance - vaultPositionBalance());
    }

    function _rebalance(uint256 _arbitrageAmount, uint32 _balanceCVIValue) internal returns (uint256 balance, uint256 volTokenPositionBalance) {
        preRebalance();

        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();

        // Note: reverts if pool is skewed, as intended
        uint256 intrinsicDEXVolTokenBalance;
        uint256 usdcPlatformLiquidity;
        uint256 dexUSDCAmount;

        (balance, usdcPlatformLiquidity, intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount) = totalBalanceWithArbitrage(_arbitrageAmount, cviValue);

        uint256 adjustedPositionUnits = platform.totalPositionUnitsAmount() * (MAX_PERCENTAGE + extraLiquidityPercentage) / MAX_PERCENTAGE;
        uint256 totalLeveragedTokensAmount = platform.totalLeveragedTokensAmount();

        // No need to rebalance if no position units for vault (i.e. dex not initialized yet)
        if (dexUSDCAmount > 0) {
            if (totalLeveragedTokensAmount > adjustedPositionUnits + minRebalanceDiff) {
                uint256 extraLiquidityAmount = totalLeveragedTokensAmount - adjustedPositionUnits;

                (, uint256 withdrawnAmount) = platform.withdraw(extraLiquidityAmount, type(uint256).max, cviValue);

                _deposit(withdrawnAmount, volTokenPositionBalance, false);
            } else if (totalLeveragedTokensAmount + minRebalanceDiff < adjustedPositionUnits) {
                uint256 liquidityMissing = adjustedPositionUnits - totalLeveragedTokensAmount;

                if (intrinsicDEXVolTokenBalance + dexUSDCAmount > liquidityMissing && 
                    (intrinsicDEXVolTokenBalance + dexUSDCAmount - liquidityMissing) * MAX_PERCENTAGE / balance >= minDexPercentageAllowed) {

                    (uint256 removedVolTokensAmount, uint256 dexRemovedUSDC) = liquidityManager.removeDEXLiquidity(liquidityMissing, intrinsicDEXVolTokenBalance + dexUSDCAmount);
                    uint256 totalUSDC = burnVolTokens(removedVolTokensAmount, cviValue) + dexRemovedUSDC;

                    platform.deposit(totalUSDC, 0, cviValue);
                }
            }

            (balance,, intrinsicDEXVolTokenBalance, volTokenPositionBalance, dexUSDCAmount,) = totalBalance(_balanceCVIValue);
        }
    }

    function totalBalanceWithArbitrage(uint256 _usdcArbitrageAmount, uint32 _balanceCVIValue) private returns (uint256 balance, uint256 usdcPlatformLiquidity, uint256 intrinsicDEXVolTokenBalance, uint256 volTokenPositionBalance, uint256 dexUSDCAmount) {
        (intrinsicDEXVolTokenBalance, volTokenPositionBalance,, dexUSDCAmount) = 
            calculatePoolValueWithArbitrage(_usdcArbitrageAmount);
        (balance, usdcPlatformLiquidity) = _totalBalance(intrinsicDEXVolTokenBalance, dexUSDCAmount, _balanceCVIValue);
    }

    function _totalBalance(uint256 _intrinsicDEXVolTokenBalance, uint256 _dexUSDCAmount, uint32 _cviValue) private view returns (uint256 balance, uint256 usdcPlatformLiquidity)
    {
        (uint256 vaultIntrinsicDEXVolTokenBalance, uint256 vaultDEXUSDCAmount) = liquidityManager.getVaultDEXBalance(_intrinsicDEXVolTokenBalance, _dexUSDCAmount);

        usdcPlatformLiquidity = getUSDCPlatformLiquidity(_cviValue);
        balance = totalHoldingsAmount + usdcPlatformLiquidity + vaultIntrinsicDEXVolTokenBalance + vaultDEXUSDCAmount;
    }

    function _deposit(uint256 _tokenAmount, uint256 _volTokenPositionBalance, bool _takeHoldings) internal returns (DepositLocals memory locals)
    {
        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();

        uint256 intrinsicVolTokenPrice;
        
        if (IERC20(address(volToken)).totalSupply() > 0) {
            intrinsicVolTokenPrice =
                _volTokenPositionBalance * (10 ** PRECISION_DECIMALS) /
                    IERC20(address(volToken)).totalSupply();
        } else {
            intrinsicVolTokenPrice = liquidityManager.getDexPrice() * (10 ** PRECISION_DECIMALS) / 
                (10 ** ERC20Upgradeable(address(volToken)).decimals());
        }

        (locals.mintVolTokenUSDCAmount, locals.platformLiquidityAmount, locals.holdingsAmount) = calculateDepositAmounts(
            _tokenAmount,
            intrinsicVolTokenPrice,
            _takeHoldings
        );

        if (_takeHoldings) {
            totalHoldingsAmount += locals.holdingsAmount;
        }

        platform.deposit(locals.platformLiquidityAmount, 0, cviValue);

        uint256 mintedVolTokenAmount = mintVolTokens(locals.mintVolTokenUSDCAmount);
        uint256 addDexUSDCAmount = liquidityManager.calculateDEXLiquidityUSDCAmount(mintedVolTokenAmount);

        (locals.addedLiquidityUSDCAmount, locals.mintedVolTokenAmount) = addDEXLiquidity(mintedVolTokenAmount, addDexUSDCAmount);
    }

    function calculatePoolValue() internal view returns (uint256 intrinsicDEXVolTokenBalance, uint256 volTokenBalance, uint256 dexUSDCAmountByVolToken, uint256 dexUSDCAmount, uint256 dexVolTokensAmount, bool isPoolSkewed) {
        (dexVolTokensAmount, dexUSDCAmountByVolToken, dexUSDCAmount) = liquidityManager.getReserves();

        bool isPositive = true;
        (uint256 currPositionUnits,,,,,) = platform.positions(address(volToken));
        if (currPositionUnits != 0) {
            (volTokenBalance, isPositive,,,,) = platform.calculatePositionBalance(address(volToken));
        }
        require(isPositive); // 'Negative balance'

        // No need to check skew if pool is still empty
        if (dexVolTokensAmount > 0 && dexUSDCAmountByVolToken > 0) {
            // Multiply by vol token decimals to get intrinsic worth in USDC
            intrinsicDEXVolTokenBalance =
                (dexVolTokensAmount * volTokenBalance) /
                IERC20(address(volToken)).totalSupply();
            uint256 delta = intrinsicDEXVolTokenBalance > dexUSDCAmountByVolToken ? intrinsicDEXVolTokenBalance - dexUSDCAmountByVolToken : dexUSDCAmountByVolToken - intrinsicDEXVolTokenBalance;

            if (delta > (intrinsicDEXVolTokenBalance * minPoolSkewPercentage) / MAX_PERCENTAGE) {
                isPoolSkewed = true;
            }
        }
    }

    function calculatePoolValueWithArbitrage(uint256 _usdcArbitrageAmount) private returns (uint256 intrinsicDEXVolTokenBalance, uint256 volTokenBalance, uint256 dexUSDCAmountByVolToken, uint256 dexUSDCAmount) {
        bool isPoolSkewed;
        (intrinsicDEXVolTokenBalance, volTokenBalance, dexUSDCAmountByVolToken, dexUSDCAmount,, isPoolSkewed) = calculatePoolValue();

        if (isPoolSkewed) {
            attemptArbitrage(_usdcArbitrageAmount + totalHoldingsAmount, intrinsicDEXVolTokenBalance, dexUSDCAmountByVolToken, volTokenBalance);
            (intrinsicDEXVolTokenBalance, volTokenBalance, dexUSDCAmountByVolToken, dexUSDCAmount,, isPoolSkewed) = calculatePoolValue();
            require(!isPoolSkewed, 'Too skewed');
        }
    }

    function attemptArbitrage(uint256 _usdcAmount, uint256 _intrinsicDEXVolTokenBalance, uint256 _dexUSDCAmount, uint256 _volTokenBalance) private {
        uint256 usdcAmountNeeded = liquidityManager.calculateArbitrageAmount(_volTokenBalance);
        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();

        uint256 withdrawnLiquidity = 0;
        if (_usdcAmount < usdcAmountNeeded) {
            uint256 leftAmount = usdcAmountNeeded - _usdcAmount;

            // Get rest of amount needed from platform liquidity (will revert if not enough collateral)
            // Revert is ok here, befcause in that case, there is no way to arbitrage and resolve the skew,
            // and no requests will fulfill anyway
            (uint256 platformBalance,) = platform.totalBalance(true, cviValue);
            (, withdrawnLiquidity) = platform.withdrawLPTokens(
                (leftAmount * IERC20(address(platform)).totalSupply()) / platformBalance, cviValue);

            usdcAmountNeeded = withdrawnLiquidity + _usdcAmount;
        }

        uint256 updatedUSDCAmount;
        uint256 beforeBalance = IERC20(address(volToken)).balanceOf(address(this));
        if (_dexUSDCAmount > _intrinsicDEXVolTokenBalance) {
            // Price is higher than intrinsic value, mint at lower price, then buy on dex
            uint256 mintedVolTokenAmount = mintVolTokens(usdcAmountNeeded);
            updatedUSDCAmount = sellVolTokens(mintedVolTokenAmount);
        } else {
            // Price is lower than intrinsic value, buy on dex, then burn at higher price
            uint256 volTokens = buyVolTokens(usdcAmountNeeded);
            updatedUSDCAmount = burnVolTokens(volTokens, cviValue);
        }

        // Make sure no vol tokens where left accidently by arbitrage (for example, if corssing range in buy/sell)
        require(IERC20(address(volToken)).balanceOf(address(this)) == beforeBalance);

        // Make sure we didn't lose by doing arbitrage (for example, mint/burn fees exceeds arbitrage gain)
        require(updatedUSDCAmount > usdcAmountNeeded); // 'Arbitrage failed'

        // Deposit arbitrage gains back to vault as platform liquidity as well
        platform.deposit(updatedUSDCAmount - usdcAmountNeeded + withdrawnLiquidity, 0, cviValue);
    }

    function vaultPositionBalance() private view returns (uint256 balance) {
        (uint256 volTokenBalance, bool isPositive,,,,) = platform.calculatePositionBalance(address(volToken));
        
        require(isPositive); // 'Negative balance'

        balance = volTokenBalance * liquidityManager.getVaultDEXVolTokens() / IERC20(address(volToken)).totalSupply();
    }

    function calculateDepositAmounts(uint256 _totalAmount, uint256 _intrinsicVolTokenPrice, bool _takeHoldings) private view returns (uint256 mintVolTokenUSDCAmount, uint256 platformLiquidityAmount, uint256 holdingsAmount) {
        holdingsAmount = _takeHoldings ? _totalAmount * depositHoldingsPercentage / MAX_PERCENTAGE : 0;

        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        mintVolTokenUSDCAmount = 
            liquidityManager.calculateDepositMintVolTokensUSDCAmount(IUniswapV3LiquidityManager.CalculateDepositParams(
                _totalAmount - holdingsAmount, cviValue, _intrinsicVolTokenPrice, platform.maxCVIValue(), extraLiquidityPercentage));

        // Simulate mint calculation for first (proportionally by balance) or non-first mint (by dex price)
        uint256 expectedMintedVolTokensAmount;
        if (IERC20(address(volToken)).totalSupply() > 0) {
            (uint256 currentBalance,,,,,) = platform.calculatePositionBalance(address(volToken));
            expectedMintedVolTokensAmount = (mintVolTokenUSDCAmount *
                IERC20(address(volToken)).totalSupply()) / currentBalance;
        } else {
            expectedMintedVolTokensAmount = 
                mintVolTokenUSDCAmount * (10 ** ERC20Upgradeable(address(volToken)).decimals()) / liquidityManager.getDexPrice();
        }

        uint256 usdcDEXAmount = liquidityManager.calculateDEXLiquidityUSDCAmount(expectedMintedVolTokensAmount);
        platformLiquidityAmount = _totalAmount - holdingsAmount - mintVolTokenUSDCAmount - usdcDEXAmount;
    }

    function burnVolTokens(uint256 _tokensToBurn, uint32 _cviValue) internal returns (uint256 burnedVolTokensUSDCAmount) {
        uint168 __tokensToBurn = uint168(_tokensToBurn);
        require(__tokensToBurn == _tokensToBurn); // Sanity, should very rarely fail

        burnedVolTokensUSDCAmount = volToken.burnTokens(__tokensToBurn, _cviValue);
    }

    function mintVolTokens(uint256 _usdcAmount) private returns (uint256 mintedVolTokenAmount) {
        uint168 __usdcAmount = uint168(_usdcAmount);
        require(__usdcAmount == _usdcAmount); // Sanity, should very rarely fail

        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        mintedVolTokenAmount = volToken.mintTokens(__usdcAmount, cviValue, cviValue);
    }

    function _setRange(uint160 _minPriceSqrtX96, uint160 _maxPriceSqrtX96, bool shouldRebase) private {
        // Sanity check there is no vol token stuck in contract before rebasing (precaution)
        require(IERC20(address(volToken)).balanceOf(address(this)) == 0);

        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        uint256 usdcBeforeBalance = IERC20(address(token)).balanceOf(address(this));
        (,,, uint256 volTokenPositionBalance,,) = totalBalance(cviValue);

        bool hasPosition = liquidityManager.hasPosition();
        if (hasPosition) {
            liquidityManager.collectFees();
            liquidityManager.removeDEXLiquidity(1, 1);
            liquidityManager.burnPosition();

            if (shouldRebase) {
                IVolatilityTokenManagement(address(volToken)).rebaseCVI();
            }
            liquidityManager.updatePoolPrice(volTokenPositionBalance);

            burnVolTokens(IERC20(address(volToken)).balanceOf(address(this)), cviValue);
        }

        if (!shouldRebase) {
            liquidityManager.setRange(_minPriceSqrtX96, _maxPriceSqrtX96);
        }

        if (hasPosition) {
            uint256 usdcAfterBalance = IERC20(address(token)).balanceOf(address(this));
            require(usdcAfterBalance > usdcBeforeBalance);

            // Deposit all cash creating new position
             (,,, volTokenPositionBalance,,) = totalBalance(cviValue);
            _deposit(usdcAfterBalance - usdcBeforeBalance, volTokenPositionBalance, false);
        }

        _rebalance(0, cviValue);
    }

    function depositLeftOvers(uint256 volTokenAmount, uint256 usdcAmount) private {
        (uint32 cviValue,,) = platform.cviOracle().getCVILatestRoundData();
        uint256 totalUSDC = usdcAmount;
        if (volTokenAmount > 0) {
            uint256 tokensToBurn = IERC20(address(volToken)).balanceOf(address(this));
            if (tokensToBurn > volTokenAmount) {
                tokensToBurn = volTokenAmount;
            }
            totalUSDC += burnVolTokens(tokensToBurn, cviValue);
        }

        if (totalUSDC > 0) {
            platform.deposit(totalUSDC, 0, cviValue);
        }
    }

    function getUSDCPlatformLiquidity(uint32 _cviValue) private view returns (uint256 usdcPlatformLiquidity) {
        uint256 platformLPTokensAmount = IERC20(address(platform)).balanceOf(address(this));

        if (platformLPTokensAmount > 0) {
            (uint256 platformBalance,) = platform.totalBalance(true, _cviValue);
            usdcPlatformLiquidity = (platformLPTokensAmount * platformBalance) / IERC20(address(platform)).totalSupply();
        }
    }

    function preRebalance() private {
        // Collect fees and add to platform liquidity
        if (liquidityManager.hasPosition()) {
            (uint256 volTokenAmount, uint256 usdcAmount) = liquidityManager.collectFees();
            depositLeftOvers(volTokenAmount, usdcAmount);
        }
    }

    function addDEXLiquidity(uint256 _mintedVolTokenAmount, uint256 _usdcAmount) private returns (uint256 addedUDSCAmount, uint256 addedVolTokenAmount) {
        (addedUDSCAmount, addedVolTokenAmount) = liquidityManager.addDEXLiquidity(_mintedVolTokenAmount, _usdcAmount);
        depositLeftOvers(_mintedVolTokenAmount - addedVolTokenAmount, _usdcAmount - addedUDSCAmount);
    }

    function sellVolTokens(uint256 volTokenAmount) private returns (uint256 usdcAmount) {
        return swapRouter.exactInput(ISwapRouter.ExactInputParams(abi.encodePacked(volToken, POOL_FEE, token), address(this), block.timestamp, volTokenAmount, 0));
    }

    function buyVolTokens(uint256 usdcAmount) private returns (uint256 volTokenAmount) {
        return swapRouter.exactInput(ISwapRouter.ExactInputParams(abi.encodePacked(token, POOL_FEE, volToken), address(this), block.timestamp, usdcAmount, 0));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';
import './IVester.sol';

enum StakedTokenName {
  THETA_VAULT,
  ES_GOVI,
  GOVI,
  HEDGED_VAULT,
  LENGTH
}

interface IRewardRouter {
  event StakeToken(address indexed account, address indexed tokenName, uint256 amount);
  event UnstakeToken(address indexed account, address indexed tokenName, uint256 amount);

  function stake(StakedTokenName _token, uint256 _amount) external;

  function stakeForAccount(
    StakedTokenName _token,
    address _account,
    uint256 _amount
  ) external;

  function batchStakeForAccount(
    StakedTokenName _tokenName,
    address[] memory _accounts,
    uint256[] memory _amounts
  ) external;

  function unstake(StakedTokenName _token, uint256 _amount) external;

  function claim(StakedTokenName _token) external;

  function compound(StakedTokenName _tokenName) external;

  function compoundForAccount(address _account, StakedTokenName _tokenName) external;

  function batchCompoundForAccounts(address[] memory _accounts, StakedTokenName _tokenName) external;

  function setRewardTrackers(StakedTokenName[] calldata _tokenNames, IRewardTracker[] calldata _rewardTrackers)
    external;

  function setVesters(StakedTokenName[] calldata _tokenNames, IVester[] calldata _vesters) external;

  function setTokens(StakedTokenName[] calldata _tokenNames, address[] calldata _tokens) external;

  function rewardTrackers(StakedTokenName _token) external view returns (IRewardTracker);

  function vesters(StakedTokenName _token) external view returns (IVester);

  function tokens(StakedTokenName _token) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

interface IRewardTracker {
  event Claim(address indexed receiver, uint256 amount);

  function stake(address _depositToken, uint256 _amount) external;

  function stakeForAccount(
    address _fundingAccount,
    address _account,
    address _depositToken,
    uint256 _amount
  ) external;

  function unstake(address _depositToken, uint256 _amount) external;

  function unstakeForAccount(
    address _account,
    address _depositToken,
    uint256 _amount,
    address _receiver
  ) external;

  function claim(address _receiver) external returns (uint256);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function updateRewards() external;

  function depositBalances(address _account, address _depositToken) external view returns (uint256);

  function stakedAmounts(address _account) external view returns (uint256);

  function averageStakedAmounts(address _account) external view returns (uint256);

  function cumulativeRewards(address _account) external view returns (uint256);

  function claimable(address _account) external view returns (uint256);

  function tokensPerInterval() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

import './IRewardTracker.sol';

interface IVester {
  event Claim(address indexed receiver, uint256 amount);
  event Deposit(address indexed account, uint256 amount);
  event Withdraw(address indexed account, uint256 claimedAmount, uint256 balance);
  event PairTransfer(address indexed from, address indexed to, uint256 value);

  function claimForAccount(address _account, address _receiver) external returns (uint256);

  function transferStakeValues(address _sender, address _receiver) external;

  function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

  function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

  function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

  function setBonusRewards(address _account, uint256 _amount) external;

  function rewardTracker() external view returns (IRewardTracker);

  function claimable(address _account) external view returns (uint256);

  function cumulativeClaimAmounts(address _account) external view returns (uint256);

  function claimedAmounts(address _account) external view returns (uint256);

  function pairAmounts(address _account) external view returns (uint256);

  function getVestedAmount(address _account) external view returns (uint256);

  function transferredAverageStakedAmounts(address _account) external view returns (uint256);

  function transferredCumulativeRewards(address _account) external view returns (uint256);

  function cumulativeRewardDeductions(address _account) external view returns (uint256);

  function bonusRewards(address _account) external view returns (uint256);

  function getMaxVestableAmount(address _account) external view returns (uint256);

  function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@coti-cvi/contracts-cvi/contracts/interfaces/IOldPlatformMinimal.sol';
import '@coti-cvi/contracts-cvi/contracts/interfaces/IOldThetaVaultMinimal.sol';
import '@coti-cvi/contracts-cvi/contracts/interfaces/IRequestManager.sol';
import '@coti-cvi/contracts-cvi/contracts/external/IUniswapV2Router02.sol';
import '@coti-cvi/contracts-cvi/contracts/external/IUniswapV2Pair.sol';
import '@coti-cvi/contracts-cvi/contracts/external/IUniswapV2Factory.sol';

contract DisabledThetaVault is
  Initializable,
  IOldThetaVaultMinimal,
  IRequestManager,
  OwnableUpgradeable,
  ERC20Upgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20 for IERC20;

  struct Request {
    uint8 requestType; // 1 => deposit, 2 => withdraw
    uint168 tokenAmount;
    uint32 targetTimestamp;
    address owner;
    bool shouldStake;
  }

  uint8 private constant DEPOSIT_REQUEST_TYPE = 1;
  uint8 private constant WITHDRAW_REQUEST_TYPE = 2;

  uint256 internal constant PRECISION_DECIMALS = 18;
  uint16 internal constant MAX_PERCENTAGE = 10000;

  uint16 public constant UNISWAP_REMOVE_MAX_FEE_PERCENTAGE = 5;

  address public fulfiller;

  IERC20 internal token;
  IOldPlatformMinimal internal platform;
  IOldVolTokenMinimal public override volToken;
  IUniswapV2Router02 public router;

  uint256 public override nextRequestId;
  mapping(uint256 => Request) public override requests;
  mapping(address => uint256) public lastDepositTimestamp;

  uint256 public initialTokenToThetaTokenRate;

  uint256 public totalDepositRequestsAmount;
  uint256 public totalVaultLeveragedAmount; // Obsolete

  uint16 public minPoolSkewPercentage;
  uint16 public extraLiquidityPercentage;
  uint256 public depositCap;
  uint256 public requestDelay;
  uint256 public lockupPeriod;
  uint256 public liquidationPeriod;

  uint256 public override minRequestId;
  uint256 public override maxMinRequestIncrements;
  uint256 public minDepositAmount;
  uint256 public minWithdrawAmount;

  uint256 public totalHoldingsAmount;
  uint16 public depositHoldingsPercentage;

  uint16 public minDexPercentageAllowed;

  IRewardRouter public rewardRouter;
  bool public isDisabled;

  function initialize() public onlyInitializing {}

  function disable() external onlyOwner {
    require(!isDisabled, 'Theta vault is already disabled');

    // remove liquidity
    IERC20Upgradeable poolPair = IERC20Upgradeable(address(getPair()));
    router.removeLiquidity(
      address(volToken),
      address(token),
      poolPair.balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );
    uint256 toBurn = IERC20Upgradeable(address(volToken)).balanceOf(address(this));
    burnVolTokens(toBurn);

    // withdraw platform liquidity
    uint256 lpTokenToWithdraw = IERC20Upgradeable(address(platform)).balanceOf(address(this));
    platform.withdrawLPTokens(lpTokenToWithdraw);

    isDisabled = true;
  }

  function exit() public nonReentrant {
    uint256 amountToWithdraw = IERC20Upgradeable(address(this)).balanceOf(msg.sender);
    submitWithdrawRequest(uint168(amountToWithdraw));
  }

  function submitDepositRequest(uint168 _tokenAmount) external override returns (uint256 requestId) {
    revert('Disabled');
  }

  function submitWithdrawRequest(uint168 _thetaTokenAmount) public override returns (uint256 requestId) {
    require(isDisabled, 'Theta vault must be disabled');

    _burn(msg.sender, _thetaTokenAmount);

    uint256 tokensToSend = (_thetaTokenAmount * token.balanceOf(address(this))) / totalSupply();
    token.safeTransfer(msg.sender, tokensToSend);

    requestId = nextRequestId;
    nextRequestId += 1; // Overflow allowed to keep id cycling
    emit SubmitRequest(
      requestId,
      WITHDRAW_REQUEST_TYPE,
      _thetaTokenAmount,
      uint32(block.timestamp),
      msg.sender,
      token.balanceOf(address(this)),
      totalSupply()
    );
    emit FulfillWithdraw(requestId, msg.sender, tokensToSend, 0, 0, 0, 0, _thetaTokenAmount);
  }

  function fulfillDepositRequest(uint256 _requestId) external override returns (uint256 thetaTokensMinted) {
    revert('Disabled');
  }

  function fulfillWithdrawRequest(uint256 _requestId) external override returns (uint256 tokenWithdrawnAmount) {
    revert('Disabled');
  }

  function liquidateRequest(uint256 _requestId) external override nonReentrant {
    Request memory request = requests[_requestId];
    require(request.requestType != 0); // 'Request id not found'
    require(isLiquidable(_requestId), 'Not liquidable');

    _liquidateRequest(_requestId);
  }

  function rebalance() external override onlyOwner {
    revert('Disabled');
  }

  function platformPositionUnits() external view returns (uint256) {
    return platform.totalPositionUnitsAmount();
  }

  function vaultPositionUnits() external view returns (uint256) {
    (, uint256 dexVolTokensAmount, , uint256 dexUSDCAmount) = getReserves();
    if (IERC20(address(volToken)).totalSupply() == 0 || (dexVolTokensAmount == 0 && dexUSDCAmount == 0)) {
      return 0;
    }

    (uint256 totalPositionUnits, , , , ) = platform.positions(address(volToken));
    return (totalPositionUnits * getVaultDEXVolTokens()) / IERC20(address(volToken)).totalSupply();
  }

  function setRewardRouter(IRewardRouter _rewardRouter, IRewardTracker _rewardTracker) external override onlyOwner {
    rewardRouter = _rewardRouter;
  }

  function setFulfiller(address _newFulfiller) external override onlyOwner {
    fulfiller = _newFulfiller;
  }

  function setMinAmounts(uint256 _newMinDepositAmount, uint256 _newMinWithdrawAmount) external override onlyOwner {
    minDepositAmount = _newMinDepositAmount;
    minWithdrawAmount = _newMinWithdrawAmount;
  }

  function setDepositHoldings(uint16 _newDepositHoldingsPercentage) external override onlyOwner {
    depositHoldingsPercentage = _newDepositHoldingsPercentage;
  }

  function setMinPoolSkew(uint16 _newMinPoolSkewPercentage) external override onlyOwner {
    minPoolSkewPercentage = _newMinPoolSkewPercentage;
  }

  function setLiquidityPercentages(uint16 _newExtraLiquidityPercentage, uint16 _minDexPercentageAllowed)
    external
    override
    onlyOwner
  {
    extraLiquidityPercentage = _newExtraLiquidityPercentage;
    minDexPercentageAllowed = _minDexPercentageAllowed;
  }

  function setRequestDelay(uint256 _newRequestDelay) external override onlyOwner {
    requestDelay = _newRequestDelay;
  }

  function setDepositCap(uint256 _newDepositCap) external override onlyOwner {
    depositCap = _newDepositCap;
  }

  function setPeriods(uint256 _newLockupPeriod, uint256 _newLiquidationPeriod) external override onlyOwner {
    lockupPeriod = _newLockupPeriod;
    liquidationPeriod = _newLiquidationPeriod;
  }

  function totalBalance()
    public
    view
    override
    returns (
      uint256 balance,
      uint256 usdcPlatformLiquidity,
      uint256 intrinsicDEXVolTokenBalance,
      uint256 volTokenPositionBalance,
      uint256 dexUSDCAmount,
      uint256 dexVolTokensAmount
    )
  {
    balance = token.balanceOf(address(this));
    return (balance, 0, 0, 0, 0, 0);
  }

  function burnVolTokens(uint256 _tokensToBurn) internal returns (uint256 burnedVolTokensUSDCAmount) {
    uint168 __tokensToBurn = uint168(_tokensToBurn);
    require(__tokensToBurn == _tokensToBurn); // Sanity, should very rarely fail
    burnedVolTokensUSDCAmount = volToken.burnTokens(__tokensToBurn);
  }

  function isLiquidable(uint256 _requestId) private view returns (bool) {
    return (requests[_requestId].targetTimestamp + liquidationPeriod < block.timestamp);
  }

  function _liquidateRequest(uint256 _requestId) private {
    Request memory request = requests[_requestId];

    if (request.requestType == DEPOSIT_REQUEST_TYPE) {
      totalDepositRequestsAmount -= request.tokenAmount;
    }

    deleteRequest(_requestId);

    if (request.requestType == WITHDRAW_REQUEST_TYPE) {
      IERC20(address(this)).safeTransfer(request.owner, request.tokenAmount);
    } else {
      token.safeTransfer(request.owner, request.tokenAmount);
    }

    emit LiquidateRequest(_requestId, request.requestType, request.owner, msg.sender, request.tokenAmount);
  }

  function deleteRequest(uint256 _requestId) private {
    delete requests[_requestId];

    uint256 currMinRequestId = minRequestId;
    uint256 increments = 0;
    bool didIncrement = false;

    while (
      currMinRequestId < nextRequestId &&
      increments < maxMinRequestIncrements &&
      requests[currMinRequestId].owner == address(0)
    ) {
      increments++;
      currMinRequestId++;
      didIncrement = true;
    }

    if (didIncrement) {
      minRequestId = currMinRequestId;
    }
  }

  function getReserves()
    public
    view
    returns (
      bool canAddLiquidity,
      uint256 volTokenAmount,
      uint256 dexUSDCAmountByVolToken,
      uint256 usdcAmount
    )
  {
    return (false, 0, 0, 0);
  }

  function getVaultDEXVolTokens() internal view returns (uint256 vaultDEXVolTokens) {
    (, uint256 dexVolTokensAmount, , ) = getReserves();

    IERC20 poolPair = IERC20(address(getPair()));
    vaultDEXVolTokens = (dexVolTokensAmount * poolPair.balanceOf(address(this))) / poolPair.totalSupply();
  }

  function getPair() private view returns (IUniswapV2Pair pair) {
    return IUniswapV2Pair(IUniswapV2Factory(router.factory()).getPair(address(volToken), address(token)));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

import '@coti-cvi/contracts-cvi/contracts/ThetaVault.sol';
import '@coti-cvi/contracts-cvi/contracts/MegaThetaVault.sol';
import '@coti-cvi/contracts-cvi/contracts/HedgedThetaVault.sol';
import './DisabledThetaVault.sol';

contract CVIUSDCThetaVault is DisabledThetaVault {
  constructor() DisabledThetaVault() {}
}

contract CVIUSDCThetaVaultV3 is ThetaVault {
  constructor() ThetaVault() {}
}

contract UCVIUSDCThetaVaultV3 is ThetaVault {
  constructor() ThetaVault() {}
}

contract CVIUSDCMegaThetaVault is MegaThetaVault {
  constructor() MegaThetaVault() {}
}

contract CVIUSDCHedgedThetaVault is HedgedThetaVault {
  constructor() HedgedThetaVault() {}
}