// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategyInfo {
    /// @dev Uniswap-Transaction-related Variable
    function transactionDeadlineDuration() external view returns (uint256);

    /// @dev get Liquidity-NFT-related Variable
    function liquidityNftId() external view returns (uint256);

    function tickSpacing() external view returns (int24);

    /// @dev get Pool-related Variable
    function poolAddress() external view returns (address);

    function poolFee() external view returns (uint24);

    function token0Address() external view returns (address);

    function token1Address() external view returns (address);

    /// @dev get Tracker-Token-related Variable
    function trackerTokenAddress() external view returns (address);

    /// @dev get User-Management-related Variable
    function isInUserList(address userAddress) external view returns (bool);

    function userIndex(address userAddress) external view returns (uint256);

    function getAllUsersInUserList() external view returns (address[] memory);

    /// @dev get User-Share-Management-related Variable
    function userShare(address userAddress) external view returns (uint256);

    function totalUserShare() external view returns (uint256);

    /// @dev get Reward-Management-related Variable
    function rewardToken0Amount() external view returns (uint256);

    function rewardToken1Amount() external view returns (uint256);

    function rewardWbtcAmount() external view returns (uint256);

    /// @dev get User-Reward-Management-related Variable
    function userWbtcReward(
        address userAddress
    ) external view returns (uint256);

    function totalUserWbtcReward() external view returns (uint256);

    /// @dev get Buyback-related Variable
    function buyBackToken() external view returns (address);

    function buyBackNumerator() external view returns (uint24);

    /// @dev get Fund-Manager-related Variable
    struct FundManagerVault {
        address fundManagerVaultAddress;
        uint256 fundManagerProfitVaultNumerator;
    }

    function getAllFundManagerVaults()
        external
        view
        returns (FundManagerVault[3] memory);

    /// @dev get Earn-Loop-Control-related Variable
    function earnLoopSegmentSize() external view returns (uint256);

    function earnLoopDistributedAmount() external view returns (uint256);

    function earnLoopStartIndex() external view returns (uint256);

    function isEarning() external view returns (bool);

    /// @dev get Rescale-related Variable
    function dustToken0Amount() external view returns (uint256);

    function dustToken1Amount() external view returns (uint256);

    /// @dev get Constant Variable
    function getBuyBackDenominator() external pure returns (uint24);

    function getFundManagerProfitVaultDenominator()
        external
        pure
        returns (uint24);

    function getFarmAddress() external pure returns (address);

    function getControllerAddress() external pure returns (address);

    function getSwapAmountCalculatorAddress() external pure returns (address);

    function getZapAddress() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwapAmountCalculator {
    /*
    embedded in User Deposit Liquidity flow

    When increasing liquidity, users can choose token 0 or token 1 to increase liquidity.
    This calculator would take into account the liquidity ratio, price ratio, and pool fee.
    It returns the maximum swap amount for the input token to the other token.
    */
    function calculateMaximumSwapAmountForSingleTokenLiquidityIncrease(
        uint256 liquidityNftId,
        address inputToken,
        uint256 inputAmount
    ) external view returns (uint256 swapAmountWithTradeFee);

    /*
    embedded in Operator/Backend Rescale flow

    When rescaling, a new liquidity NFT can nearly equalize the upper and lower boundaries.
    Thus, it allows for maximum liquidity increase by equal value of token0 and token1.

    When rescaling, there are available two token – dustToken0Amount, dustToken1Amount.
    This calculator would take into account the price ratio, and pool fee.
    It returns the maximum swap amount and direction to equalize the token value.
    */
    function calculateValueEqualizationSwapAmount(
        address poolAddress,
        uint256 token0Amount,
        uint256 token1Amount
    ) external view returns (address swapToken, uint256 swapAmountWithTradeFee);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IZap {
    /// @dev get zap data
    function slippageToleranceNumerator() external view returns (uint24);

    function getSwapInfo(
        address inputToken,
        address outputToken
    )
        external
        view
        returns (
            bool isPathDefined,
            address[] memory swapPathArray,
            uint24[] memory swapTradeFeeArray
        );

    function getTokenExchangeRate(
        address inputToken,
        address outputToken
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint256 tokenPriceWith18Decimals
        );

    function getMinimumSwapOutAmount(
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) external view returns (uint256 minimumSwapOutAmount);

    /// @dev swapToken
    function swapToken(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        address recipient
    ) external payable returns (uint256 outputAmount);

    function swapTokenWithMinimumOutput(
        bool isETH,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 minimumSwapOutAmount,
        address recipient
    ) external payable returns (uint256 outputAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ISwapAmountCalculator.sol";
import "./interfaces/IZap.sol";
import "./interfaces/IStrategyInfo.sol";

/// @dev verified, public contract
contract MinimumSwapOutAmountCalculator {
    address public constant WBTC =
        address(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);

    function getDepositMinimumSwapOutAmount(
        address strategyAddress,
        address inputToken,
        uint256 inputAmount
    ) public view returns (uint256 swapInAmount, uint256 minimumSwapOutAmount) {
        require(inputAmount > 0, "inputAmount invalid");

        address token0 = IStrategyInfo(strategyAddress).token0Address();
        address token1 = IStrategyInfo(strategyAddress).token1Address();

        require(
            inputToken == token0 || inputToken == token1,
            "inputToken invalid"
        );

        swapInAmount = ISwapAmountCalculator(
            IStrategyInfo(strategyAddress).getSwapAmountCalculatorAddress()
        ).calculateMaximumSwapAmountForSingleTokenLiquidityIncrease(
                IStrategyInfo(strategyAddress).liquidityNftId(),
                inputToken,
                inputAmount
            );

        if (swapInAmount == 0) {
            return (0, 0);
        } else {
            address outputToken = (inputToken == token0) ? token1 : token0;

            minimumSwapOutAmount = IZap(
                IStrategyInfo(strategyAddress).getZapAddress()
            ).getMinimumSwapOutAmount(inputToken, outputToken, swapInAmount);
        }
    }

    function getEarnMinimumSwapOutAmount(
        address strategyAddress
    )
        public
        view
        returns (
            uint256 minimumToken0SwapOutAmount,
            uint256 minimumToken1SwapOutAmount,
            uint256 minimumBuybackSwapOutAmount
        )
    {
        address token0 = IStrategyInfo(strategyAddress).token0Address();
        minimumToken0SwapOutAmount = getMinimumSwapOutWbtcAmount(
            strategyAddress,
            token0,
            IStrategyInfo(strategyAddress).rewardToken0Amount()
        );

        address token1 = IStrategyInfo(strategyAddress).token1Address();
        minimumToken1SwapOutAmount = getMinimumSwapOutWbtcAmount(
            strategyAddress,
            token1,
            IStrategyInfo(strategyAddress).rewardToken1Amount()
        );

        minimumBuybackSwapOutAmount = getMinimumBuybackAmount(
            strategyAddress,
            (minimumToken0SwapOutAmount + minimumToken1SwapOutAmount)
        );
    }

    function getMinimumSwapOutWbtcAmount(
        address strategyAddress,
        address inputToken,
        uint256 inputAmount
    ) internal view returns (uint256 minimumSwapOutAmount) {
        if (inputToken == WBTC) {
            minimumSwapOutAmount = inputAmount;
        } else if (inputAmount == 0) {
            minimumSwapOutAmount = 0;
        } else {
            minimumSwapOutAmount = IZap(
                IStrategyInfo(strategyAddress).getZapAddress()
            ).getMinimumSwapOutAmount(inputToken, WBTC, inputAmount);
        }
    }

    function getMinimumBuybackAmount(
        address strategyAddress,
        uint256 totalMinimumSwapOutWbtcAmount
    ) internal view returns (uint256 minimumBuybackAmount) {
        uint256 rewardWbtcAmount = IStrategyInfo(strategyAddress)
            .rewardWbtcAmount();

        uint24 buyBackNumerator = IStrategyInfo(strategyAddress)
            .buyBackNumerator();
        uint24 buyBackDenominator = IStrategyInfo(strategyAddress)
            .getBuyBackDenominator();

        uint256 buyBackWbtcAmount = ((rewardWbtcAmount +
            totalMinimumSwapOutWbtcAmount) * buyBackNumerator) /
            buyBackDenominator;

        if (buyBackNumerator == 0 || buyBackWbtcAmount == 0) {
            minimumBuybackAmount = 0;
        } else {
            address buyBackToken = IStrategyInfo(strategyAddress)
                .buyBackToken();

            minimumBuybackAmount = IZap(
                IStrategyInfo(strategyAddress).getZapAddress()
            ).getMinimumSwapOutAmount(WBTC, buyBackToken, buyBackWbtcAmount);
        }
    }
}