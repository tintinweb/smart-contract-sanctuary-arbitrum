// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                              #@@@@@@@@@@@@&,                               //
//                      [email protected]@@@@   [email protected]@@@@@@@@@@@@@@@@@@*                        //
//                  %@@@,    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    //
//               @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                 //
//             @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@               //
//           *@@@#    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//          *@@@%    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            //
//          @@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//                                                                            //
//          (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,           //
//          (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,           //
//                                                                            //
//               @@   @@     @   @      @       @   @       @                 //
//               @@   @@    @@@ @@@    @[email protected]     @@@ @@@     @@@                //
//                &@@@@   @@  @@  @@ @@ ^ @@  @@  @@  @@   @@@                //
//                                                                            //
//          @@@@@      @@@%    *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          @@@@@      @@@@    %@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           //
//          [email protected]@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@            //
//            @@@@@  &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@             //
//                (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&(                 //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { VaultStorage } from "../storage/VaultStorage.sol";
import { BaseVault } from "../base/BaseVault.sol";
import { ISwapRouter } from "../interfaces/ISwapRouter.sol";
import { IStakingRewards } from "../interfaces/IStakingRewards.sol";
import { IPoolCommitter } from "../interfaces/IPoolCommitter.sol";
import { IGlpManager } from "../interfaces/IGlpManager.sol";
import { IRewardRouterV2 } from "../interfaces/IRewardRouterV2.sol";
import { IGlpPricing } from "../interfaces/IGlpPricing.sol";
import { ITcrPricing } from "../interfaces/ITcrPricing.sol";
import { ITcrStrategy } from "../interfaces/ITcrStrategy.sol";
import { IChainlinkWrapper } from "../interfaces/IChainlinkWrapper.sol";
import { Vault } from "../libraries/Vault.sol";
import { ShareMath } from "../libraries/ShareMath.sol";
import { L2Encoder } from "../lib/L2Encoder.sol";

/// @title Delta Minimised GLP-USDC Vault
/// @author 0xtoki
contract GlpUSDCVault is BaseVault, VaultStorage {
    using SafeERC20 for IERC20;

    /************************************************
     *  STORAGE
     ***********************************************/

    /// @notice the timestamp migration window
    uint256 public migrationTimestamp;

    /// @notice slippage amount for closing a glp position
    uint256 public glpCloseSlippage;

    /// @notice tcr staking active
    bool public hedgeStakingActive;

    /// @notice contract library used for pricing glp
    address public glpPricing;

    /// @notice contract library address used for pricing the tcr hedges
    address public hedgePricing;

    /// @notice tcr emission strategy
    address public tcrStrategy;

    /// @notice glp reward router
    uint256 public swapSlippage;

    /// @notice GLP_MANAGER is used for managing GMX Liquidity
    /// https://github.com/gmx-io/gmx-contracts/blob/master/contracts/core/GlpManager.sol
    address public GLP_MANAGER;

    /// @notice GLP_REWARD_ROUTER is used for minting, burning and handling GLP and rewards earnt
    /// https://github.com/gmx-io/gmx-contracts/blob/master/contracts/staking/RewardRouterV2.sol
    address public GLP_REWARD_ROUTER;

    /// @notice tcr token
    address public TCR = 0xA72159FC390f0E3C6D415e658264c7c4051E9b87;

    /// @notice wrapper for the chainlink oracle used for swap pricing
    IChainlinkWrapper public chainlinkOracle;

    /// @notice shortMint commit type for minting shorts in Tracer Finance
    IPoolCommitter.CommitType public shortMint = IPoolCommitter.CommitType.ShortMint;

    /// @notice shortBurn commit type for burning shorts in Tracer Finance
    IPoolCommitter.CommitType public shortBurn = IPoolCommitter.CommitType.ShortBurn;

    /// @notice Tracer Finance encoder used for encoding paramsfor short burns/mints
    /// https://github.com/tracer-protocol/perpetual-pools-contracts/blob/pools-v2/contracts/implementation/L2Encoder.sol
    L2Encoder public encoder;

    /// @notice UniV3 router for calling swaps
    /// https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
    ISwapRouter public router;

    /// @notice hedge actions for rebalancing
    enum HedgeAction {
        increase,
        decrease,
        flat
    }

    /// @dev MAX INT
    uint256 public constant MAX_INT = 2**256 - 1;

    /************************************************
     *  EVENTS
     ***********************************************/

    event UpdatePricePerShare(uint104 _round, uint256 _pricePerShare);

    event CommitAndClose(
        uint104 _round,
        uint256 _timestamp,
        uint256 _profitAmount,
        uint256 _glpAllocation,
        uint256 _sbtcAllocation,
        uint256 _sethAllocation
    );

    event RollToNextPosition(uint256 _lockedInStrategy, uint256 _queuedWithdrawAmount);

    event TracerOpen(uint256 _sbtcAllocation, uint256 _sethAllocation);

    event TracerClose(uint256 _sbtcAllocation, uint256 _sethAllocation);

    event InitiateVaultMigration(uint256 _timestamp, uint256 _migrationActiveTimestamp);

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    /**
     * @notice Consttuctor
     * @param _asset is the underlying asset deposited to the vault
     * @param _feeRecipient is the recipient of the fees generated by the vault
     * @param _keeper the vault keeper
     * @param _managementFee vault management fee
     * @param _performanceFee performance fee
     * @param _depositFee deposit fee
     * @param _vaultParams vault params
     * @param _glpRouter glp reward router
     * @param _glpManager glp manager
     * @param _uniswapRouter uniV3 router
     */
    constructor(
        address _asset,
        address _feeRecipient,
        address _keeper,
        uint256 _managementFee,
        uint256 _performanceFee,
        uint256 _depositFee,
        uint104 _vaultRound,
        Vault.VaultParams memory _vaultParams,
        address _glpRouter,
        address _glpManager,
        address _uniswapRouter
    )
        BaseVault(
            _asset,
            _feeRecipient,
            _keeper,
            _managementFee,
            _performanceFee,
            _depositFee,
            _vaultRound,
            _vaultParams,
            "glpUSDC",
            "glpUSDC"
        )
    {
        require(_glpManager != address(0), "!_glpManager");
        require(_glpRouter != address(0), "!_glpRouter");
        require(_uniswapRouter != address(0), "!_uniswapRouter");
        require(_vaultParams.hedgePricing != address(0), "!hedgePricing");
        require(_vaultParams.glpPricing != address(0), "!glpPricing");

        encoder = new L2Encoder();
        roundPricePerShare[_vaultRound] = ShareMath.pricePerShare(
            totalSupply(),
            IERC20(_vaultParams.asset).balanceOf(address(this)),
            _vaultParams.decimals
        );

        GLP_MANAGER = _glpManager;
        GLP_REWARD_ROUTER = _glpRouter;
        router = ISwapRouter(_uniswapRouter);
        hedgePricing = _vaultParams.hedgePricing;
        glpPricing = _vaultParams.glpPricing;
        hedgeStakingActive = false;
        swapSlippage = 100; // 10%
        glpCloseSlippage = 3; // 0.3%
        migrationTimestamp = MAX_INT;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(uint256(lastQueuedWithdrawAmount) - withdrawAmount);
    }

    /**
     * @notice Marks the close of the existing vault round and sets the allocations for the next round.
     * This function will, if required to accomadate the new hedge sizing, close some of the GLP position to USDC.
     * @param nextSbtcAllocation the allocation to sbtc for the next epoch in usdc
     * @param nextSethAllocation the allocation to seth for the next epoch in usdc
     * @param nextGlpAllocation the allocation to glp for the next epoch in usdc
     * @param _settlePositions whether the vault should settle positions this epoch
     * @param _handleTcrEmissions whether the vault should handle the tcr emissions this epoch
     * @return profit the profit amount made from claiming rewards
     */
    function commitAndClose(
        uint112 nextSbtcAllocation,
        uint112 nextSethAllocation,
        uint112 nextGlpAllocation,
        bool _settlePositions,
        bool _handleTcrEmissions
    ) external nonReentrant onlyKeeper returns (uint256) {
        // get the existing glp balance and allocation in USDC
        uint256 glpBal = IERC20(vaultParams.stakedGlp).balanceOf(address(this));
        uint256 existingGlpAllocation = IGlpPricing(glpPricing).glpToUsd(glpBal, false);

        // set next allocations
        strategyState.nextSbtcAllocation = nextSbtcAllocation;
        strategyState.nextSethAllocation = nextSethAllocation;
        strategyState.nextGlpAllocation = nextGlpAllocation;

        vaultState.lastLockedAmount = uint104(lockedInStrategy);
        uint256 profitAmount = 0;

        // unstake tracer hedges and handle emissions
        if (
            (strategyState.activeSbtcAllocation > 0 || strategyState.activeSethAllocation > 0) &&
            hedgeStakingActive &&
            _handleTcrEmissions
        ) {
            profitAmount += collectTcrEmissions();
        }

        // start late withdrawal period
        lateWithdrawPeriod = true;

        // settle glp
        if (_settlePositions) {
            if (existingGlpAllocation > nextGlpAllocation) {
                profitAmount += settleGlpPosition(existingGlpAllocation - nextGlpAllocation);
                strategyState.activeGlpAllocation = nextGlpAllocation;
            } else {
                profitAmount += handleGlpRewards();
            }
        }
        uint256 sEthVal = ITcrPricing(hedgePricing).sEthToUsd(totalSethBalance());
        uint256 sBtcVal = ITcrPricing(hedgePricing).sBtcToUsd(totalSbtcBalance());

        emit CommitAndClose(
            vaultState.round,
            block.timestamp,
            profitAmount,
            IGlpPricing(glpPricing).glpToUsd(glpBal, false),
            sBtcVal,
            sEthVal
        );
        return profitAmount;
    }

    /**
     * @notice Rolls the vault's funds into a new strategy position.
     * Same decimals as `asset` this function should be called immediatly after the short positions have been committed and minted
     */
    function rollToNextPosition() external onlyKeeper nonReentrant {
        // claim short tokens
        claimShorts();
        // stake tracer hedge
        if (hedgeStakingActive) stakeHedges();
        // get the next glp allocation
        uint256 nextGlpAllocation = strategyState.nextGlpAllocation;

        // get the vaults next round params
        (uint256 lockedBalance, uint256 queuedWithdrawAmount) = _rollToNextEpoch(
            uint256(lastQueuedWithdrawAmount),
            uint256(roundQueuedWithdrawalShares[vaultState.round]),
            totalAssets()
        );

        // get new queued withdrawal shares before rollover
        uint256 newQueuedWithdrawShares = uint256(vaultState.queuedWithdrawShares) +
            roundQueuedWithdrawalShares[vaultState.round - 1];

        ShareMath.assertUint128(newQueuedWithdrawShares);

        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        // set globals
        lastQueuedWithdrawAmount = uint128(queuedWithdrawAmount);
        lockedInStrategy = lockedBalance;

        uint256 sbtcAllocation = strategyState.activeSbtcAllocation;
        uint256 sethAllocation = strategyState.activeSethAllocation;
        uint256 existingGlpPosition = IGlpPricing(glpPricing).glpToUsd(
            IERC20(vaultParams.stakedGlp).balanceOf(address(this)),
            false
        );

        uint256 totalUtilised = sbtcAllocation + sethAllocation + nextGlpAllocation + lastQueuedWithdrawAmount;
        require(totalUtilised <= totalAssets(), "TCRGMX: !allocation");

        if (nextGlpAllocation > existingGlpPosition) openGlpPosition(nextGlpAllocation - existingGlpPosition);

        emit RollToNextPosition(lockedInStrategy, lastQueuedWithdrawAmount);
    }

    /**
     * @notice withdraws funds from GMX in GLP, claiming the rewards and executing any swaps. 
     * This is done in the case some capital is needed to open new hedges or cover next round withdrawals.
     * @param glpAllocation value in usdc to be settled in glp
     * @return amount of asset received in profit at the end of the epoch
     */
    function settleGlpPosition(uint256 glpAllocation) internal returns (uint256) {
        // usd to glp at current price
        uint256 glpAmount = IGlpPricing(glpPricing).usdToGlp(glpAllocation, false);

        // subtract 0.3% buffer for onchain mispricing
        glpAmount -= (glpAmount * glpCloseSlippage) / SCALE;

        // burn glp amount
        IRewardRouterV2(GLP_REWARD_ROUTER).unstakeAndRedeemGlp(vaultParams.asset, glpAmount, 0, address(this));

        // handle glp rewards and return profit in usdc, add tcr yield when built
        return handleGlpRewards();
    }

    /**
     * @notice deposits and stakes glpAllocation in GLP
     * @param glpAllocation value in usdc to mint GLP
     */
    function openGlpPosition(uint256 glpAllocation) public onlyKeeper {
        IERC20(vaultParams.asset).safeIncreaseAllowance(GLP_MANAGER, glpAllocation);
        uint256 amountWithSlippage = getSlippageAdjustedAmount(glpAllocation, 10);
        IRewardRouterV2(GLP_REWARD_ROUTER).mintAndStakeGlp(vaultParams.asset, glpAllocation, amountWithSlippage, 0);
    }

    /**
     * @notice uses the allocations passed in or the vault state to queue a rebalance of the tracer hedges
     * @param sbtcAllocation usdc allocation for sbtc
     * @param sethAllocation usdc allocation for seth
     * @param sethAction action to rebalance seth
     * @param sbtcAction action to rebalance sbtc
     */
    function queueHedgeRebalance(
        uint256 sbtcAllocation,
        uint256 sethAllocation,
        HedgeAction sethAction,
        HedgeAction sbtcAction
    ) external onlyKeeper nonReentrant {
        uint256 sEthChange;
        uint256 sBtcChange;
        (, uint256 queuedWithdrawAmount) = getNextLockedQueued();
        uint256 availableBal = IERC20(vaultParams.asset).balanceOf(address(this)) - queuedWithdrawAmount;

        uint256 sEthVal = ITcrPricing(hedgePricing).sEthToUsd(totalSethBalance());
        uint256 sBtcVal = ITcrPricing(hedgePricing).sBtcToUsd(totalSbtcBalance());

        if (sethAction == HedgeAction.increase) {
            require(sethAllocation >= sEthVal, "TCRGMX: !allocation");
            sEthChange = sethAllocation - sEthVal;
            require(availableBal > sEthChange, "TCRGMX: Over allocation");
            strategyState.activeSethAllocation = sethAllocation;
            queueTracerOpen(0, sEthChange);
        } else if (sethAction == HedgeAction.decrease) {
            require(sethAllocation <= sEthVal, "TCRGMX: !allocation");
            sEthChange = sEthVal - sethAllocation;
            uint256 sEthAmount = ITcrPricing(hedgePricing).usdToSeth(sEthChange);
            strategyState.activeSethAllocation = sethAllocation;
            if (hedgeStakingActive) unstakePartialHedges(0, sEthAmount);
            queueTracerClose(0, sEthAmount);
        }

        if (sbtcAction == HedgeAction.increase) {
            require(sbtcAllocation >= sBtcVal, "TCRGMX: !allocation");
            sBtcChange = sbtcAllocation - sBtcVal;
            availableBal = IERC20(vaultParams.asset).balanceOf(address(this)) - queuedWithdrawAmount;
            require(availableBal > sBtcChange, "TCRGMX: Over allocation");
            strategyState.activeSbtcAllocation = sbtcAllocation;
            queueTracerOpen(sBtcChange, 0);
        } else if (sbtcAction == HedgeAction.decrease) {
            require(sbtcAllocation <= sBtcVal, "TCRGMX: !allocation");
            sBtcChange = sBtcVal - sbtcAllocation;
            uint256 sBtcAmount = ITcrPricing(hedgePricing).usdToSbtc(sBtcChange);
            strategyState.activeSbtcAllocation = sbtcAllocation;
            if (hedgeStakingActive) unstakePartialHedges(sBtcAmount, 0);
            queueTracerClose(sBtcAmount, 0);
        }
    }

    /**
     * @notice This function withdraws tracer shorts from staking and queues them for closing on the next rebalance
     * @param sbtcAllocation amount of sbtc tokens to burn
     * @param sethAllocation amount of seth tokens to burn
     */
    function queueTracerClose(uint256 sbtcAllocation, uint256 sethAllocation) public onlyKeeper {
        uint256 ethLeverageindex = strategyState.activeEthLeverageIndex;
        uint256 btcLeverageIndex = strategyState.activeBtcLeverageIndex;
        uint256 sEthBal = IERC20(ethLeverageSets[ethLeverageindex].token).balanceOf(address(this));
        uint256 sBtcBal = IERC20(btcLeverageSets[btcLeverageIndex].token).balanceOf(address(this));
        require(sBtcBal >= sbtcAllocation, "TCRGMX: !available sbtc balance");
        require(sEthBal >= sethAllocation, "TCRGMX: !available seth balance");

        if (sbtcAllocation != 0) {
            IERC20(btcLeverageSets[btcLeverageIndex].token).safeIncreaseAllowance(
                btcLeverageSets[btcLeverageIndex].leveragePool,
                sbtcAllocation
            );
            IPoolCommitter(btcLeverageSets[btcLeverageIndex].poolCommitter).commit(
                encoder.encodeCommitParams(sbtcAllocation, shortBurn, false, false)
            );
        }
        if (sethAllocation != 0) {
            IERC20(ethLeverageSets[ethLeverageindex].token).safeIncreaseAllowance(
                ethLeverageSets[ethLeverageindex].leveragePool,
                sethAllocation
            );
            IPoolCommitter(ethLeverageSets[ethLeverageindex].poolCommitter).commit(
                encoder.encodeCommitParams(sethAllocation, shortBurn, false, false)
            );
        }

        emit TracerClose(sbtcAllocation, sethAllocation);
    }

    /**
     * @notice This function withdraws tracer shorts from staking and queues them for closing on the next rebalance
     * @param sbtcAllocation usdc amount to open in sbtc
     * @param sethAllocation usdc amount to open in seth
     */
    function queueTracerOpen(uint256 sbtcAllocation, uint256 sethAllocation) public onlyKeeper {
        uint256 usdcBal = IERC20(vaultParams.asset).balanceOf(address(this)) - lastQueuedWithdrawAmount;
        require(sethAllocation + sbtcAllocation <= usdcBal, "TCRGMX: !available balance");
        uint256 ethLeverageindex = strategyState.activeEthLeverageIndex;
        uint256 btcLeverageIndex = strategyState.activeBtcLeverageIndex;

        // mint hedges
        if (sbtcAllocation != 0) {
            IERC20(vaultParams.asset).safeIncreaseAllowance(btcLeverageSets[btcLeverageIndex].leveragePool, sbtcAllocation);
            IPoolCommitter(btcLeverageSets[btcLeverageIndex].poolCommitter).commit(
                encoder.encodeCommitParams(sbtcAllocation, shortMint, false, false)
            );
        }
        if (sethAllocation != 0) {
            IERC20(vaultParams.asset).safeIncreaseAllowance(ethLeverageSets[ethLeverageindex].leveragePool, sethAllocation);
            IPoolCommitter(ethLeverageSets[ethLeverageindex].poolCommitter).commit(
                encoder.encodeCommitParams(sethAllocation, shortMint, false, false)
            );
        }
        emit TracerOpen(sbtcAllocation, sethAllocation);
    }

    /**
     * @notice Handle the GLP rewards according to the strategy. Claim esGMX + multiplier points and stake.
     * Claim WETH and swap to USDC paid as profit to the vault
     * @return profit the amount of USDC recieved in exchange for the WETH claimed
     */
    function handleGlpRewards() internal returns (uint256) {
        IRewardRouterV2(GLP_REWARD_ROUTER).handleRewards(true, true, true, true, true, true, false);
        return swapToStable();
    }

    /**
     * @notice Swaps the WETH claimed from the strategy to USDC
     * @return recieved amount of USDC recieved
     */
    function swapToStable() internal returns (uint256) {
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        if (wethBalance > 0) {
            uint256 ethPrice = chainlinkOracle.getCurrentPrice(WETH);
            uint256 minOut = (ethPrice * wethBalance) / 1e30; // USDC decimals convertion
            IERC20(WETH).safeIncreaseAllowance(address(router), wethBalance);
            uint24 poolFee = 500;
            bytes memory route = abi.encodePacked(WETH, poolFee, vaultParams.asset);
            ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
                path: route,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: wethBalance,
                amountOutMinimum: getSlippageAdjustedAmount(minOut, swapSlippage)
            });
            return router.exactInput(params);
        }
        return 0;
    }

    /**
     * @notice Total asset value in the vault. Valued in USDC. This call will under report assets held in the vault
     * when commits to Tracer Finance are pending
     * @return totalBal the total balance of the assets held
     */
    function totalAssets() public view returns (uint256 totalBal) {
        uint256 usdcBal = IERC20(vaultParams.asset).balanceOf(address(this));
        uint256 glpBal = IERC20(vaultParams.stakedGlp).balanceOf(address(this));
        uint256 sEthBal = totalSethBalance();
        uint256 sBtcBal = totalSbtcBalance();
        totalBal =
            usdcBal +
            IGlpPricing(glpPricing).glpToUsd(glpBal, false) +
            ITcrPricing(hedgePricing).sEthToUsd(sEthBal) +
            ITcrPricing(hedgePricing).sBtcToUsd(sBtcBal);
    }

    /**
     * @notice Returns the total balance of seth held by the vault
     * @return balance of seth
     */
    function totalSethBalance() public view returns (uint256) {
        uint256 sEthBal = IERC20(ethLeverageSets[strategyState.activeEthLeverageIndex].token).balanceOf(address(this));
        if (hedgeStakingActive) {
            return sEthBal + IStakingRewards(vaultParams.sethStake).balanceOf(address(this));
        }
        return sEthBal;
    }

    /**
     * @notice Returns the total balance of sbtc held by the vault
     * @return balance of sbtc
     */
    function totalSbtcBalance() public view returns (uint256) {
        uint256 sBtcBal = IERC20(btcLeverageSets[strategyState.activeBtcLeverageIndex].token).balanceOf(address(this));
        if (hedgeStakingActive) {
            return sBtcBal + IStakingRewards(vaultParams.sbtcStake).balanceOf(address(this));
        }
        return sBtcBal;
    }

    /**
     * @notice Returns a slippage adjusted amount for calculations where slippage is accounted
     * @param amount of the asset
     * @param slippage %
     * @return value of the slippage adjusted amount
     */
    function getSlippageAdjustedAmount(uint256 amount, uint256 slippage) internal view returns (uint256) {
        return (amount * (1 * SCALE - slippage)) / SCALE;
    }

    /**
     * @notice Returns the next locked and withdrawal amount queued
     * @return lockedBalance that is available for use in the strategy next epoch
     * @return queuedWithdrawAmount next withdrawal amount queued
     */
    function getNextLockedQueued() public view returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        (lockedBalance, queuedWithdrawAmount) = previewNextBalances(
            uint256(lastQueuedWithdrawAmount),
            roundQueuedWithdrawalShares[vaultState.round],
            totalAssets()
        );
    }

    /**
     * @notice Sets the active leverage index to be used if configured for a different leverage multiplier
     * @param _btcLeverageSet the index for btc leverage set
     * @param _ethLeverageSet the index for eth leverage set
     */
    function setLeverageSetIndex(uint256 _btcLeverageSet, uint256 _ethLeverageSet) external onlyAdmin {
        require(btcLeverageSets[_btcLeverageSet].poolCommitter != address(0), "TCRGMX: btc leverage set");
        require(ethLeverageSets[_ethLeverageSet].poolCommitter != address(0), "TCRGMX: eth leverage set");
        strategyState.activeBtcLeverageIndex = _btcLeverageSet;
        strategyState.activeEthLeverageIndex = _ethLeverageSet;
    }

    /**
     * @notice Updates the slippage tolerance for swapping rewards to USDC
     * @param _newSlippage the new slippage tolerance
     */
    function updateSwapSlippage(uint256 _newSlippage) external onlyAdmin {
        require(_newSlippage != 0, "TCRGMX: ! _newSlippage is zero");
        swapSlippage = _newSlippage;
    }

    /**
     * @notice Updates the chainlink oracle wrapper implementation
     * @param _chainlinkWrapper the address of the new implementation
     */
    function updateChainlinkWrapper(address _chainlinkWrapper) external onlyAdmin {
        require(_chainlinkWrapper != address(0), "TCRGMX: ! chainlinkWrapper address");
        chainlinkOracle = IChainlinkWrapper(_chainlinkWrapper);
    }

    /**
     * @notice Updates the hedge pricing implementation for Tracer Finance
     * @param _hedgePricing the address of the new implementation
     */
    function updateHedgePricing(address _hedgePricing) external onlyAdmin {
        require(_hedgePricing != address(0), "TCRGMX: ! hedgePricing address");
        hedgePricing = _hedgePricing;
    }

    /**
     * @notice Updates the GLP pricing implementation
     * @param _glpPricing the address of the new implementation
     */
    function updateGlpPricing(address _glpPricing) external onlyAdmin {
        require(_glpPricing != address(0), "TCRGMX: ! glpPricing address");
        glpPricing = _glpPricing;
    }

    /**
     * @notice Updates the seth staking contract address for TCR emissions
     * @param _sethStaking the new staking contract
     */
    function updateSethStaking(address _sethStaking) external onlyAdmin {
        require(_sethStaking != address(0), "TCRGMX: ! seth address");
        vaultParams.sethStake = _sethStaking;
    }

    /**
     * @notice Updates the sbtc staking contract address for TCR emissions
     * @param _sbtcStaking the new staking contract
     */
    function updateSbtcStaking(address _sbtcStaking) external onlyAdmin {
        require(_sbtcStaking != address(0), "TCRGMX: ! sbtc address");
        vaultParams.sbtcStake = _sbtcStaking;
    }

    /**
     * @notice Updates the TCR emissions token strategy for how the vault should handle emissions
     * @param _tcrStrategy the new strategy address
     */
    function setTcrStrategy(address _tcrStrategy) external onlyAdmin {
        tcrStrategy = _tcrStrategy;
    }

    /**
     * @notice Sets the Tracer Finance hedge staking
     * @param _stakingActive the value to set it to
     */
    function setHedgeStakingActive(bool _stakingActive) external onlyAdmin {
        hedgeStakingActive = _stakingActive;
    }

    /**
     * @notice Claims the short tokens from Tracer Finance
     */
    function claimShorts() public onlyKeeper {
        uint256 ethLeverageindex = strategyState.activeEthLeverageIndex;
        uint256 btcLeverageindex = strategyState.activeBtcLeverageIndex;
        IPoolCommitter(ethLeverageSets[ethLeverageindex].poolCommitter).claim(address(this));
        IPoolCommitter(btcLeverageSets[btcLeverageindex].poolCommitter).claim(address(this));
    }

    /**
     * @notice Stakes the short tokens in the emissions contract
     */
    function stakeHedges() internal {
        uint256 ethLeverageindex = strategyState.activeEthLeverageIndex;
        uint256 btcLeverageindex = strategyState.activeBtcLeverageIndex;
        uint256 sEthBal = IERC20(ethLeverageSets[ethLeverageindex].token).balanceOf(address(this));
        uint256 sBtcBal = IERC20(btcLeverageSets[btcLeverageindex].token).balanceOf(address(this));

        if (sEthBal > 0) {
            IERC20(ethLeverageSets[ethLeverageindex].token).safeIncreaseAllowance(vaultParams.sethStake, sEthBal);
            IStakingRewards(vaultParams.sethStake).stake(sEthBal);
        }
        if (sBtcBal > 0) {
            IERC20(btcLeverageSets[btcLeverageindex].token).safeIncreaseAllowance(vaultParams.sbtcStake, sBtcBal);
            IStakingRewards(vaultParams.sbtcStake).stake(sBtcBal);
        }
    }

    /**
     * @notice Collect Tcr emissions from the staking contract
     * @return profit in USDC recieved from TCR emissions
     */
    function collectTcrEmissions() internal returns (uint256) {
        IStakingRewards(vaultParams.sbtcStake).getReward();
        IStakingRewards(vaultParams.sethStake).getReward();
        uint256 tcrBalance = IERC20(TCR).balanceOf(address(this));
        if (tcrStrategy != address(0) && tcrBalance > 0) {
            IERC20(TCR).safeIncreaseAllowance(tcrStrategy, tcrBalance);
            return ITcrStrategy(tcrStrategy).handleTcr(tcrBalance);
        }
        return 0;
    }

    /**
     * @notice Unstakes the short tokens from the emissions contract
     */
    function unstakePartialHedges(uint256 _sbtcAmount, uint256 _sethAmount) public onlyKeeper {
        if (_sbtcAmount > 0) IStakingRewards(vaultParams.sbtcStake).withdraw(_sbtcAmount);
        if (_sethAmount > 0) IStakingRewards(vaultParams.sethStake).withdraw(_sethAmount);
    }

    /**
     * @notice Unstakes the short tokens from the emissions contract
     */
    function unstakeAllHedges() public onlyKeeper {
        IStakingRewards(vaultParams.sbtcStake).exit();
        IStakingRewards(vaultParams.sethStake).exit();
    }

    /**
     * @notice Initiates the vault migration of multiplier points and esGMX to a new vault
     * a 14 day grace period is given to warn users this has been triggered
     */
    function initiateMigration() public onlyAdmin {
        require(migrationTimestamp == MAX_INT, "already initiated");
        migrationTimestamp = block.timestamp + 14 days;
        emit InitiateVaultMigration(block.timestamp, migrationTimestamp);
    }

    /**
     * @notice Calls the migration of the esGMX and multiplier points to a new vault
     * @param _receiver the address to migrate to
     */
    function migrateVault(address _receiver) public onlyAdmin {
        require(tx.origin == msg.sender, "onlyEOA");
        require(block.timestamp > migrationTimestamp, "migration not ready");
        IRewardRouterV2(GLP_REWARD_ROUTER).signalTransfer(_receiver);
    }

    /**
     * @notice Revoke allowances to all external contracts
     */
    function revokeAllowances() public onlyAdmin {
        uint256 ethLeverageindex = strategyState.activeEthLeverageIndex;
        uint256 btcLeverageindex = strategyState.activeBtcLeverageIndex;
        IERC20(ethLeverageSets[ethLeverageindex].token).approve(vaultParams.sethStake, 0);
        IERC20(btcLeverageSets[btcLeverageindex].token).approve(vaultParams.sbtcStake, 0);
        IERC20(vaultParams.asset).approve(btcLeverageSets[btcLeverageindex].leveragePool, 0);
        IERC20(vaultParams.asset).approve(ethLeverageSets[ethLeverageindex].leveragePool, 0);
        IERC20(WETH).approve(address(router), 0);
        IERC20(vaultParams.asset).approve(GLP_MANAGER, 0);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { Vault } from "../libraries/Vault.sol";

abstract contract VaultStorage {
    // usdc value locked in delta neutral strategy
    uint256 public lockedInStrategy;
    // Amount locked for scheduled withdrawals last week;
    uint128 public lastQueuedWithdrawAmount;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Vault } from "../libraries/Vault.sol";
import { ShareMath } from "../libraries/ShareMath.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";
import { VaultLifecycle } from "../libraries/VaultLifecycle.sol";

contract BaseVault is AccessControl, ERC20, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /************************************************
     *  STORAGE
     ***********************************************/

    /// @notice On every round's close, the pricePerShare value of a vault token is stored
    /// This is used to determine the number of shares to be returned
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Stores the eth leverage set
    mapping(uint256 => Vault.LeverageSet) public ethLeverageSets;

    /// @notice Stores the btc leverage set
    mapping(uint256 => Vault.LeverageSet) public btcLeverageSets;

    /// @notice Stores the current round queued withdrawal share amount
    mapping(uint256 => uint128) public roundQueuedWithdrawalShares;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the hedges deployed and glp allocation
    Vault.StrategyState public strategyState;

    /// @notice Asset used in the vault
    address public asset;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice Role for vault operations such as rollToNextPosition.
    address public keeper;

    /// @notice Whitelist implimentation
    address public whitelistLibrary;

    /// @notice Performance fee collected on premiums earned in rollToNextPosition. Only when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee collected on roll to next. This fee is collected each epoch
    uint256 public managementFee;

    /// @notice Deposit fee charged on entering of the vault
    uint256 public depositFee;

    /// @notice Withdrawal fee charged on exit of the vault
    uint256 public withdrawalFee;

    /// @notice If the vault is in a late withdrawal period while rebalancing
    bool public lateWithdrawPeriod;

    /// @notice The expected duration of each epoch
    uint256 public epochDuration;

    /// @notice Scale for slippage
    uint256 public SCALE = 1000;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9
    address public immutable WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    /// @notice admin role hash
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice keeper role hash
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    /// @notice Day in seconds
    uint32 public constant DAY = 86400;

    /************************************************
     *  EVENTS
     ***********************************************/

    event DepositRound(address indexed account, uint256 amount, uint256 round);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event InitiateWithdraw(address indexed account, uint256 shares, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event DepositFeeSet(uint256 depositFee, uint256 newDepositFee);

    event WithdrawalFeeSet(uint256 withdrawalFee, uint256 newWithdrawalFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(uint256 performanceFee, uint256 vaultFee, uint256 round, address indexed feeRecipient);

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/
    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor(
        address _asset,
        address _feeRecipient,
        address _keeper,
        uint256 _managementFee,
        uint256 _performanceFee,
        uint256 _depositFee,
        uint104 _vaultRound,
        Vault.VaultParams memory _vaultParams,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_asset != address(0), "!_asset");
        require(_feeRecipient != address(0), "!_feeRecipient");
        require(_keeper != address(0), "!_keeper");
        require(_performanceFee < 100 * Vault.FEE_MULTIPLIER, "_performanceFee >= 100%");
        require(_managementFee < 100 * Vault.FEE_MULTIPLIER, "_managementFee >= 100%");
        require(_depositFee < 100 * Vault.FEE_MULTIPLIER, "_depositFee >= 100%");
        require(_vaultParams.minimumSupply > 0, "!_minimumSupply");
        require(_vaultParams.cap > 0, "!_cap");
        require(_vaultParams.cap > _vaultParams.minimumSupply, "_cap <= _minimumSupply");
        require(bytes(_name).length > 0, "!_name");
        require(bytes(_symbol).length > 0, "!_symbol");

        asset = _asset;
        feeRecipient = _feeRecipient;
        keeper = _keeper;
        performanceFee = _performanceFee;
        managementFee = _managementFee;
        depositFee = _depositFee;
        withdrawalFee = 0;
        vaultParams = _vaultParams;
        vaultState.round = _vaultRound;
        whitelistLibrary = address(0);
        lateWithdrawPeriod = false;
        epochDuration = DAY;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(KEEPER_ROLE, _keeper);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /************************************************
     *  MODIFIERS
     ***********************************************/

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(hasRole(KEEPER_ROLE, msg.sender), "!keeper");
        _;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the whitelist implementation
     * @param _newWhitelistLibrary address to the whitelist implementation
     */
    function setWhitelistLibrary(address _newWhitelistLibrary) external onlyAdmin {
        whitelistLibrary = _newWhitelistLibrary;
    }

    /**
     * @notice Sets the epoch duration
     * @param _newEpochDuration new epoch duration
     */
    function setEpochDuration(uint256 _newEpochDuration) external onlyAdmin {
        epochDuration = _newEpochDuration;
    }

    /**
     * @notice Sets the SCALE value for resolution of calcs
     * @param _newScale epoch duration
     */
    function setScale(uint256 _newScale) external onlyAdmin {
        SCALE = _newScale;
    }

    /**
     * @notice Sets a new eth leverage pool
     * @param _leverageSet the leverage set to be set
     * @param _index the index to set it at
     */
    function setEthLeveragePool(Vault.LeverageSet memory _leverageSet, uint256 _index) external onlyAdmin {
        require(_leverageSet.poolCommitter != address(0), "!addNewLeveragePool");
        require(_leverageSet.leveragePool != address(0), "!addNewLeveragePool");
        ethLeverageSets[_index] = _leverageSet;
    }

    /**
     * @notice Sets a new btc leverage pool
     * @param _leverageSet the leverage set to be set
     * @param _index the index to set it at
     */
    function setBtcLeveragePool(Vault.LeverageSet memory _leverageSet, uint256 _index) external onlyAdmin {
        require(_leverageSet.poolCommitter != address(0), "!addNewLeveragePool");
        require(_leverageSet.leveragePool != address(0), "!addNewLeveragePool");
        btcLeverageSets[_index] = _leverageSet;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyAdmin {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyAdmin {
        require(newManagementFee < 10 * Vault.FEE_MULTIPLIER, "Invalid management fee");
        uint256 hourlyRate = newManagementFee / 8760; // hours per year
        uint256 epochRate = (hourlyRate * epochDuration) / 3600;
        emit ManagementFeeSet(managementFee, newManagementFee);
        managementFee = epochRate; // % per epoch
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyAdmin {
        require(newPerformanceFee < 100 * Vault.FEE_MULTIPLIER, "Invalid performance fee");
        emit PerformanceFeeSet(performanceFee, newPerformanceFee);
        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets the deposit fee for the vault
     * @param newDepositFee is the deposit fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setDepositFee(uint256 newDepositFee) external onlyAdmin {
        require(newDepositFee < 20 * Vault.FEE_MULTIPLIER, "Invalid deposit fee");
        emit DepositFeeSet(depositFee, newDepositFee);
        depositFee = newDepositFee;
    }

    /**
     * @notice Sets the withdrawal fee for the vault
     * @param newWithdrawalFee is the withdrawal fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setWithdrawalFee(uint256 newWithdrawalFee) external onlyAdmin {
        require(newWithdrawalFee < 20 * Vault.FEE_MULTIPLIER, "Invalid withdrawal fee");
        emit WithdrawalFeeSet(withdrawalFee, newWithdrawalFee);
        withdrawalFee = newWithdrawalFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyAdmin {
        require(newCap >= 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Pauses deposits for the vault
     */
    function pauseDeposits() external onlyAdmin {
        _pause();
    }

    /**
     * @notice unpauses deposits for the vault
     */
    function unpauseDeposits() external onlyAdmin {
        _unpause();
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");
        require(whitelistLibrary == address(0), "whitelist enabled");
        _depositFor(amount, msg.sender);
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function deposit(uint256 amount, address creditor) external nonReentrant returns (uint256 mintShares) {
        require(amount > 0, "!amount");
        require(creditor != address(0), "!creditor");
        require(whitelistLibrary == address(0), "whitelist enabled");
        mintShares = _depositFor(amount, creditor);
    }

    /**
     * @notice Deposits the `asset` from msg.sender. Whitelist must be enabled
     * @param amount is the amount of `asset` to deposit
     */
    function whitelistDeposit(uint256 amount, bytes32[] calldata merkleproof) external nonReentrant {
        require(amount > 0, "!amount");
        require(whitelistLibrary != address(0), "whitelist not enabled");
        uint256 checkpointBalance = checkpointTotalBalance();
        require(IWhitelist(whitelistLibrary).isWhitelisted(msg.sender, checkpointBalance, amount, merkleproof), "!whitelist");
        _depositFor(amount, msg.sender);
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     * @return mintShares the shares minted
     */
    function _depositFor(uint256 amount, address creditor) private whenNotPaused returns (uint256 mintShares) {
        uint256 checkpointBalance = checkpointTotalBalance();

        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = checkpointBalance + amount;

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(totalWithDepositedAmount >= vaultParams.minimumSupply, "Insufficient balance");

        emit DepositRound(creditor, amount, currentRound);

        uint256 depositFeeAmount = (amount * depositFee) / (100 * Vault.FEE_MULTIPLIER);
        uint256 depositAmount = amount - depositFeeAmount;

        uint256 newTotalPending = uint256(vaultState.totalPending) + depositAmount;

        vaultState.totalPending = uint128(newTotalPending);

        uint256 assetPerShare = roundPricePerShare[currentRound];

        mintShares = ShareMath.assetToShares(depositAmount, assetPerShare, vaultParams.decimals);

        emit Deposit(msg.sender, creditor, depositAmount, mintShares);

        IERC20(vaultParams.asset).safeTransferFrom(msg.sender, address(this), amount);
        transferAsset(feeRecipient, depositFeeAmount);

        _mint(creditor, mintShares);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        if (lateWithdrawPeriod) {
            _initiateWithdraw(numShares, vaultState.round + 1);
        } else {
            _initiateWithdraw(numShares, vaultState.round);
        }
    }

    /**
     * @notice Initiates a withdrawal queued for the specified round
     * @param _numShares is the number of shares to withdraw
     * @param _round is the round to queue the withdrawal for
     */
    function _initiateWithdraw(uint256 _numShares, uint256 _round) internal {
        require(_numShares > 0, "!_numShares");

        // This caches the `round` variable used in shareBalances
        uint256 withdrawalRound = _round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round >= withdrawalRound;

        emit InitiateWithdraw(msg.sender, _numShares, withdrawalRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares + _numShares;
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = _numShares;
            withdrawals[msg.sender].round = uint16(withdrawalRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        uint256 newQueuedWithdrawShares = uint256(roundQueuedWithdrawalShares[withdrawalRound]) + _numShares;
        ShareMath.assertUint128(newQueuedWithdrawShares);
        roundQueuedWithdrawalShares[withdrawalRound] = uint128(newQueuedWithdrawShares);

        _transfer(msg.sender, address(this), _numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(uint256(vaultState.queuedWithdrawShares) - withdrawalShares);

        uint256 withdrawAmount = ShareMath.sharesToAsset(
            withdrawalShares,
            roundPricePerShare[withdrawalRound],
            vaultParams.decimals
        );

        if (withdrawalFee > 0) {
            uint256 withdrawFeeAmount = (withdrawAmount * withdrawalFee) / (100 * Vault.FEE_MULTIPLIER);
            withdrawAmount -= withdrawFeeAmount;
        }

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);
        require(withdrawAmount > 0, "!withdrawAmount");

        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Mints a number of shares to the receiver
     * @param _shares is the number of shares to mint
     * @param _receiver is account recieving the shares
     */
    function mint(uint256 _shares, address _receiver) external nonReentrant {
        require(_shares > 0, "!_shares");
        require(_receiver != address(0), "!_receiver");

        uint256 currentRound = vaultState.round;
        uint256 assetPerShare = roundPricePerShare[currentRound];
        uint256 assetAmount = ShareMath.sharesToAsset(_shares, assetPerShare, vaultParams.decimals);

        _depositFor(assetAmount, _receiver);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /*
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    function initRounds(uint256 numRounds) external nonReentrant {
        require(numRounds > 0, "!numRounds");

        uint256 _round = vaultState.round;
        for (uint256 i = 0; i < numRounds; i++) {
            uint256 index = _round + i;
            require(roundPricePerShare[index] == 0, "Initialized"); // AVOID OVERWRITING ACTUAL VALUES
            roundPricePerShare[index] = ShareMath.PLACEHOLDER_UINT;
        }
    }

    /*
     * @notice Helper function that performs most administrative tasks
     * such as setting next strategy params, depositing to tracer and GMX, getting vault fees, etc.
     */
    function _rollToNextEpoch(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawalShares,
        uint256 totalAssetValue
    ) internal returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        uint256 newSbtcAllocation = strategyState.nextSbtcAllocation;
        uint256 newSethAllocation = strategyState.nextSethAllocation;
        uint256 newGlpAllocation = strategyState.nextGlpAllocation;

        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;
            (lockedBalance, queuedWithdrawAmount, newPricePerShare, performanceFeeInAsset, totalVaultFee) = VaultLifecycle
                .rollover(
                    vaultState,
                    VaultLifecycle.RolloverParams(
                        vaultParams.decimals,
                        totalAssetValue,
                        totalSupply(),
                        lastQueuedWithdrawAmount,
                        currentQueuedWithdrawalShares,
                        performanceFee,
                        managementFee,
                        (block.timestamp - vaultState.epochStart) / epochDuration
                    )
                );

            strategyState.activeSbtcAllocation = newSbtcAllocation;
            strategyState.activeSethAllocation = newSethAllocation;
            strategyState.activeGlpAllocation = newGlpAllocation;

            strategyState.nextSbtcAllocation = 0;
            strategyState.nextSethAllocation = 0;
            strategyState.nextGlpAllocation = 0;

            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            // close the late withdrawal period for rebalancing
            lateWithdrawPeriod = false;

            emit CollectVaultFees(performanceFeeInAsset, totalVaultFee, currentRound, feeRecipient);

            vaultState.totalPending = 0;
            vaultState.round = uint104(currentRound + 1);
            vaultState.epochStart = block.timestamp;
            vaultState.epochEnd = vaultState.epochStart + epochDuration;
            roundPricePerShare[vaultState.round] = newPricePerShare;
        }

        if (totalVaultFee > 0) {
            transferAsset(payable(feeRecipient), totalVaultFee);
        }
        return (lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{ value: amount }("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account) external view returns (uint256) {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare = roundPricePerShare[vaultState.round];
        return ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance
     * @param _account is the account to lookup share balance for
     * @return heldByAccount share balance
     */
    function shares(address _account) public view returns (uint256) {
        uint256 heldByAccount = balanceOf(_account);
        return heldByAccount;
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     * @return
     */
    function pricePerShare() external view returns (uint256) {
        return roundPricePerShare[vaultState.round];
    }

    /**
     * @notice Returns the vault's balance with realtime deposits and the locked value at the start of the epoch
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function checkpointTotalBalance() public view returns (uint256) {
        return uint256(vaultState.lockedAmount) + IERC20(vaultParams.asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the token decimals
     * @return
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    /**
     * @notice Returns the vault cap
     * @return
     */
    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    /**
     * @notice Returns the value of deposits not yet used in the strategy
     * @return
     */
    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }

    /**
     * @notice Converts the vault asset to shares at the current rate for this epoch
     * @param _assets the amount of the vault asset to convert
     * @return shares amount of shares for the asset
     */
    function convertToShares(uint256 _assets) public view virtual returns (uint256) {
        uint256 assetPerShare = roundPricePerShare[vaultState.round];
        return ShareMath.assetToShares(_assets, assetPerShare, vaultParams.decimals);
    }

    /**
     * @notice Converts the vault shares to assets at the current rate for this epoch
     * @param _shares the amount of vault shares to convert
     * @return asset amount of asset for the shares
     */
    function convertToAssets(uint256 _shares) public view virtual returns (uint256) {
        uint256 assetPerShare = roundPricePerShare[vaultState.round];
        return ShareMath.sharesToAsset(_shares, assetPerShare, vaultParams.decimals);
    }

    /**
     * @notice Previews a deposit to the vault for the number of assets
     * @param _assets to be deposited
     * @return shares amount of shares recieved after fees
     */
    function previewDeposit(uint256 _assets) public view virtual returns (uint256) {
        uint256 amountLessDepositFee = _assets - ((_assets * depositFee) / (100 * Vault.FEE_MULTIPLIER));
        return convertToShares(amountLessDepositFee);
    }

    /**
     * @notice Previews a mint of vault shares
     * @param _shares amount of shares to be minted
     * @return asset amount of asset required to mint the shares after fees
     */
    function previewMint(uint256 _shares) public view virtual returns (uint256) {
        uint256 amountLessDepositFee = _shares - ((_shares * depositFee) / (100 * Vault.FEE_MULTIPLIER));
        return convertToAssets(amountLessDepositFee);
    }

    /**
     * @notice Previews a withdrawal from the vault at the current price per share
     * @param _shares the amount of shares to withdraw
     * @return asset the amount of asset recieved after fees
     */
    function previewWithdraw(uint256 _shares) public view virtual returns (uint256) {
        uint256 amountLessWithdrawalFee = _shares - ((_shares * withdrawalFee) / (100 * Vault.FEE_MULTIPLIER));
        return convertToAssets(amountLessWithdrawalFee);
    }

    /**
     * @notice Previews the next balances for the epoch with queued withdrawals
     * @param lastQueuedWithdrawAmount the amount last queued for withdrawal
     * @param currentQueuedWithdrawalShares the amount queued for withdrawal this round
     * @param totalAssetValue total asset value of the vault
     * @return lockedBalance balance locked for the next strategy epoch
     * @return queuedWithdrawAmount next queued withdrawal amount to be set aside for withdrawals
     */
    function previewNextBalances(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawalShares,
        uint256 totalAssetValue
    ) internal view virtual returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        uint256 epochSeconds = (block.timestamp - vaultState.epochStart) / epochDuration;

        (lockedBalance, queuedWithdrawAmount, , , ) = VaultLifecycle.rollover(
            vaultState,
            VaultLifecycle.RolloverParams(
                vaultParams.decimals,
                totalAssetValue,
                totalSupply(),
                lastQueuedWithdrawAmount,
                currentQueuedWithdrawalShares,
                performanceFee,
                managementFee,
                epochSeconds
            )
        );
    }

    /**
     * @notice recover eth
     */
    function recoverEth() external onlyAdmin {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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
pragma solidity 0.8.7;

interface IStakingRewards {
    // Views
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative
    function exit() external;

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

/// @title The interface for the contract that handles pool commitments
interface IPoolCommitter {
    /// Type of commit
    enum CommitType {
        ShortMint, // Mint short tokens
        ShortBurn, // Burn short tokens
        LongMint, // Mint long tokens
        LongBurn, // Burn long tokens
        LongBurnShortMint, // Burn Long tokens, then instantly mint in same upkeep
        ShortBurnLongMint // Burn Short tokens, then instantly mint in same upkeep
    }

    function isMint(CommitType t) external pure returns (bool);

    function isBurn(CommitType t) external pure returns (bool);

    function isLong(CommitType t) external pure returns (bool);

    function isShort(CommitType t) external pure returns (bool);

    // Pool balances and supplies
    struct BalancesAndSupplies {
        uint256 newShortBalance;
        uint256 newLongBalance;
        uint256 longMintPoolTokens;
        uint256 shortMintPoolTokens;
        uint256 longBurnInstantMintSettlement;
        uint256 shortBurnInstantMintSettlement;
        uint256 totalLongBurnPoolTokens;
        uint256 totalShortBurnPoolTokens;
    }

    // User aggregate balance
    struct Balance {
        uint256 longTokens;
        uint256 shortTokens;
        uint256 settlementTokens;
    }

    // Token Prices
    struct Prices {
        bytes16 longPrice;
        bytes16 shortPrice;
    }

    // Commit information
    struct Commit {
        uint256 amount;
        CommitType commitType;
        uint40 created;
        address owner;
    }

    // Commit information
    struct TotalCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
    }

    // User updated aggregate balance
    struct BalanceUpdate {
        uint256 _updateIntervalId;
        uint256 _newLongTokensSum;
        uint256 _newShortTokensSum;
        uint256 _newSettlementTokensSum;
        uint256 _longSettlementFee;
        uint256 _shortSettlementFee;
        uint8 _maxIterations;
    }

    // Track how much of a user's commitments are being done from their aggregate balance
    struct UserCommitment {
        uint256 longMintSettlement;
        uint256 longBurnPoolTokens;
        uint256 shortMintSettlement;
        uint256 shortBurnPoolTokens;
        uint256 shortBurnLongMintPoolTokens;
        uint256 longBurnShortMintPoolTokens;
        uint256 updateIntervalId;
    }

    // Track the relevant data when executing a range of update interval's commitments (stack too deep)
    struct CommitmentExecutionTracking {
        uint256 longTotalSupply;
        uint256 shortTotalSupply;
        uint256 longTotalSupplyBefore;
        uint256 shortTotalSupplyBefore;
        uint256 _updateIntervalId;
    }

    /**
     * @notice Creates a notification when a commit is created
     * @param user The user making the commitment
     * @param amount Amount of the commit
     * @param commitType Type of the commit (Short v Long, Mint v Burn)
     * @param appropriateUpdateIntervalId Id of update interval where this commit can be executed as part of upkeep
     * @param fromAggregateBalance whether or not to commit from aggregate (unclaimed) balance
     * @param payForClaim whether or not to request this commit be claimed automatically
     * @param mintingFee Minting fee at time of commit creation
     */
    event CreateCommit(
        address indexed user,
        uint256 indexed amount,
        CommitType indexed commitType,
        uint256 appropriateUpdateIntervalId,
        bool fromAggregateBalance,
        bool payForClaim,
        bytes16 mintingFee
    );

    /**
     * @notice Creates a notification when a user's aggregate balance is updated
     */
    event AggregateBalanceUpdated(address indexed user);

    /**
     * @notice Creates a notification when the PoolCommitter's leveragedPool address has been updated.
     * @param newPool the address of the new leveraged pool
     */
    event PoolChanged(address indexed newPool);

    /**
     * @notice Creates a notification when commits for a given update interval are executed
     * @param updateIntervalId Unique identifier for the relevant update interval
     * @param burningFee Burning fee at the time of commit execution
     */
    event ExecutedCommitsForInterval(uint256 indexed updateIntervalId, bytes16 burningFee);

    /**
     * @notice Creates a notification when a claim is made, depositing pool tokens in user's wallet
     */
    event Claim(address indexed user);

    /*
     * @notice Creates a notification when the burningFee is updated
     */
    event BurningFeeSet(uint256 indexed _burningFee);

    /**
     * @notice Creates a notification when the mintingFee is updated
     */
    event MintingFeeSet(uint256 indexed _mintingFee);

    /**
     * @notice Creates a notification when the changeInterval is updated
     */
    event ChangeIntervalSet(uint256 indexed _changeInterval);

    /**
     * @notice Creates a notification when the feeController is updated
     */
    event FeeControllerSet(address indexed _feeController);

    // #### Functions

    function initialize(
        address _factory,
        address _autoClaim,
        address _factoryOwner,
        address _feeController,
        address _invariantCheck,
        uint256 mintingFee,
        uint256 burningFee,
        uint256 _changeInterval
    ) external;

    function commit(bytes32 args) external payable;

    function updateIntervalId() external view returns (uint128);

    function pendingMintSettlementAmount() external view returns (uint256);

    function pendingShortBurnPoolTokens() external view returns (uint256);

    function pendingLongBurnPoolTokens() external view returns (uint256);

    function claim(address user) external;

    function executeCommitments(
        uint256 lastPriceTimestamp,
        uint256 updateInterval,
        uint256 longBalance,
        uint256 shortBalance
    )
        external
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function updateAggregateBalance(address user) external;

    function getAggregateBalance(address user) external view returns (Balance memory _balance);

    function getAppropriateUpdateIntervalId() external view returns (uint128);

    function setPool(address _leveragedPool) external;

    function setBurningFee(uint256 _burningFee) external;

    function setMintingFee(uint256 _mintingFee) external;

    function setChangeInterval(uint256 _changeInterval) external;

    function setFeeController(address _feeController) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IGlpManager {
    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function getAum(bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IRewardRouterV2 {
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function claimEsGmx() external;

    function signalTransfer(address _receiver) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IGlpPricing {
    function setPrice(uint256 _glpPrice) external;

    function glpPrice(bool _buy) external view returns (uint256);

    function usdToGlp(uint256 usdAmount, bool maximise) external view returns (uint256);

    function glpToUsd(uint256 glpAmount, bool maximise) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ITcrPricing {
    function setSEthPrice(uint256 _price) external;

    function setSbtcPrice(uint256 _price) external;

    function sEthPrice() external view returns (uint256);

    function sBtcPrice() external view returns (uint256);

    function sEthToUsd(uint256 sethAmount) external view returns (uint256);

    function sBtcToUsd(uint256 sbtcAmount) external view returns (uint256);

    function usdToSeth(uint256 usd) external view returns (uint256);

    function usdToSbtc(uint256 usd) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ITcrStrategy {
    function handleTcr(uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IChainlinkWrapper {
    function getExternalPrice(address _token) external view returns (uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getCurrentPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

library Vault {
    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Token decimals for vault shares
        uint8 decimals;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
        // Vault asset
        address asset;
        // staked glp
        address stakedGlp;
        // esGMX
        address esGMX;
        // glp pricing library
        address glpPricing;
        // tracer hedge pricing library
        address hedgePricing;
        // sbtc tcr emissions staking
        address sbtcStake;
        // seth tcr emissions staking
        address sethStake;
    }

    struct StrategyState {
        // the allocation of sbtc this epoch
        uint256 activeSbtcAllocation;
        // the allocation of seth this epoch
        uint256 activeSethAllocation;
        // the allocation of glp this epoch
        uint256 activeGlpAllocation;
        // The index of the leverage for btc shorts
        uint256 activeBtcLeverageIndex;
        // The index of the leverage for eth shorts
        uint256 activeEthLeverageIndex;
        // the allocation of sbtc next epoch
        uint256 nextSbtcAllocation;
        // the allocation of seth next epoch
        uint256 nextSethAllocation;
        // the allocation of glp next epoch
        uint256 nextGlpAllocation;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint104 round;
        // Amount that is currently locked for the strategy
        uint104 lockedAmount;
        // Amount that was locked for the strategy
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds not including the current round
        uint128 queuedWithdrawShares;
        // Start time of the last epoch
        uint256 epochStart;
        // Epoch end time
        uint256 epochEnd;
    }

    struct LeverageSet {
        // The tokenised leverage position
        address token;
        // The committer for the leverage position
        address poolCommitter;
        // Leverage pool holding the deposit tokens
        address leveragePool;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { Vault } from "./Vault.sol";

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * 10**decimals) / assetPerShare;
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * assetPerShare) / 10**decimals;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return totalSupply > 0 ? (singleShare * totalBalance) / totalSupply : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity 0.8.7;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IPoolCommitter.sol";

/**
 * @title L2Encoder
 * @notice Helper contract to encode calldata, used to optimize calldata size
 * only indented to help generate calldata for uses/frontends.
 */
contract L2Encoder {
    using SafeCast for uint256;

    /**
     * @notice Encodes an array of addresses to compact representation as a bytes array
     * @param args The array of LeveragedPool addresses to perform upkeep on
     * @return compact bytes array of addresses
     */
    function encodeAddressArray(address[] calldata args) external pure returns (bytes memory) {
        bytes memory encoded;
        uint256 len = args.length;
        for (uint256 i = 0; i < len; i++) {
            encoded = bytes.concat(encoded, abi.encodePacked(args[i]));
        }
        return encoded;
    }

    /**
     * @notice Encodes commit parameters from standard input to compact representation of 1 bytes32
     * @param amount Amount of settlement tokens you want to commit to minting; OR amount of pool
     *               tokens you want to burn
     * @param commitType Type of commit you're doing (Long vs Short, Mint vs Burn)
     * @param fromAggregateBalance If minting, burning, or rebalancing into a delta neutral position,
     *                             will tokens be taken from user's aggregate balance?
     * @param payForClaim True if user wants to pay for the commit to be claimed
     * @return compact representation of commit parameters
     */
    function encodeCommitParams(
        uint256 amount,
        IPoolCommitter.CommitType commitType,
        bool fromAggregateBalance,
        bool payForClaim
    ) external pure returns (bytes32) {
        uint128 shortenedAmount = amount.toUint128();

        bytes32 res;

        assembly {
            res := add(shortenedAmount, add(shl(128, commitType), add(shl(136, fromAggregateBalance), shl(144, payForClaim))))
        }
        return res;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IWhitelist {
    function isWhitelisted(
        address _account,
        uint256 _currentAssets,
        uint256 _amount,
        bytes32[] calldata _merkleproof
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";

library VaultLifecycle {
    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the total value held by the vault priced in USDC
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from all rounds excluding the last
     * @param currentQueuedWithdrawShares is the amount queued for withdrawals from last round
     * @param performanceFee is the performance fee percent
     * @param managementFee is the management fee percent
     * @param epochsElapsed is the number of epochs elapsed measured by the duration
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 currentQueuedWithdrawShares;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 epochsElapsed;
    }

    /**
     * @notice Calculate the new price per share and
      amount of funds to re-allocate as collateral for the new epoch
     * @param vaultState is the storage variable vaultState
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(Vault.VaultState storage vaultState, RolloverParams calldata params)
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;
        uint256 epochManagementFee = params.epochsElapsed > 0 ? params.managementFee * params.epochsElapsed : params.managementFee;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees = currentBalance - params.lastQueuedWithdrawAmount;

        {
            // no performance fee on first round
            balanceForVaultFees = vaultState.round == 1 ? vaultState.totalPending : balanceForVaultFees;

            (performanceFeeInAsset, , totalVaultFee) = VaultLifecycle.getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                epochManagementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance - totalVaultFee;

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply - lastQueuedWithdrawShares,
                currentBalance - params.lastQueuedWithdrawAmount,
                params.decimals
            );

            queuedWithdrawAmount =
                params.lastQueuedWithdrawAmount +
                ShareMath.sharesToAsset(params.currentQueuedWithdrawShares, newPricePerShare, params.decimals);
        }

        return (
            currentBalance - queuedWithdrawAmount, // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending = currentBalance > pendingAmount ? currentBalance - pendingAmount : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee ONLY if difference between
        // last epoch and this epoch's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last round
        // was not profitable and the vault took a loss on assets
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? ((lockedBalanceSansPending - lastLockedAmount) * performanceFeePercent) / (100 * Vault.FEE_MULTIPLIER)
                : 0;
        }
        // Take management fee on each epoch
        _managementFeeInAsset = managementFeePercent > 0
            ? (lockedBalanceSansPending * managementFeePercent) / (100 * Vault.FEE_MULTIPLIER)
            : 0;

        _vaultFee = _performanceFeeInAsset + _managementFeeInAsset;

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}