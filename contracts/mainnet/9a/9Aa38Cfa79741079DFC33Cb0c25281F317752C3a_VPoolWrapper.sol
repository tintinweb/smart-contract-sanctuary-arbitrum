// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.14;

import { Initializable } from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';
import { IUniswapV3MintCallback } from '@uniswap/v3-core-0.8-support/contracts/interfaces/callback/IUniswapV3MintCallback.sol';
import { IUniswapV3SwapCallback } from '@uniswap/v3-core-0.8-support/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { IVPoolWrapper } from '../../interfaces/IVPoolWrapper.sol';
import { IVQuote } from '../../interfaces/IVQuote.sol';
import { IVToken } from '../../interfaces/IVToken.sol';
import { IVToken } from '../../interfaces/IVToken.sol';
import { IClearingHouse } from '../../interfaces/IClearingHouse.sol';
import { IClearingHouseStructures } from '../../interfaces/clearinghouse/IClearingHouseStructures.sol';

import { AddressHelper } from '../../libraries/AddressHelper.sol';
import { FundingPayment } from '../../libraries/FundingPayment.sol';
import { SimulateSwap } from '../../libraries/SimulateSwap.sol';
import { TickExtended } from '../../libraries/TickExtended.sol';
import { PriceMath } from '../../libraries/PriceMath.sol';
import { SafeCast } from '../../libraries/SafeCast.sol';
import { SignedMath } from '../../libraries/SignedMath.sol';
import { SignedFullMath } from '../../libraries/SignedFullMath.sol';
import { SwapMath } from '../../libraries/SwapMath.sol';
import { UniswapV3PoolHelper } from '../../libraries/UniswapV3PoolHelper.sol';

import { Extsload } from '../../utils/Extsload.sol';

import { UNISWAP_V3_DEFAULT_TICKSPACING, UNISWAP_V3_DEFAULT_FEE_TIER } from '../../utils/constants.sol';

contract VPoolWrapper is IVPoolWrapper, IUniswapV3MintCallback, IUniswapV3SwapCallback, Initializable, Extsload {
    using AddressHelper for IVToken;
    using FullMath for uint256;
    using FundingPayment for FundingPayment.Info;
    using SignedMath for int256;
    using SignedFullMath for int256;
    using PriceMath for uint160;
    using SafeCast for uint256;
    using SafeCast for uint128;
    using SimulateSwap for IUniswapV3Pool;
    using TickExtended for IUniswapV3Pool;
    using TickExtended for mapping(int24 => TickExtended.Info);
    using UniswapV3PoolHelper for IUniswapV3Pool;

    IClearingHouse public clearingHouse;
    IVToken public vToken;
    IVQuote public vQuote;
    IUniswapV3Pool public vPool;

    uint24 constant PERC_10_1E6 = 100000;

    // fee paid to liquidity providers, in 1e6
    uint24 public liquidityFeePips;
    // fee paid to DAO treasury
    uint24 public protocolFeePips;

    uint256 public accruedProtocolFee;

    FundingPayment.Info public fpGlobal;
    uint256 public sumFeeGlobalX128;

    int256 constant FUNDING_RATE_OVERRIDE_NULL_VALUE = type(int256).max;
    int256 public fundingRateOverrideX128;

    mapping(int24 => TickExtended.Info) public ticksExtended;

    error NotClearingHouse();
    error NotGovernance();
    error NotGovernanceOrTeamMultisig();
    error NotUniswapV3Pool();
    error InvalidTicks(int24 tickLower, int24 tickUpper);
    error InvalidSetting(uint256 errorCode);

    modifier onlyClearingHouse() {
        if (msg.sender != address(clearingHouse)) {
            revert NotClearingHouse();
        }
        _;
    }

    modifier onlyGovernance() {
        if (msg.sender != clearingHouse.governance()) {
            revert NotGovernance();
        }
        _;
    }

    modifier onlyGovernanceOrTeamMultisig() {
        if (msg.sender != clearingHouse.governance() && msg.sender != clearingHouse.teamMultisig()) {
            revert NotGovernanceOrTeamMultisig();
        }
        _;
    }

    modifier onlyUniswapV3Pool() {
        if (msg.sender != address(vPool)) {
            revert NotUniswapV3Pool();
        }
        _;
    }

    modifier checkTicks(int24 tickLower, int24 tickUpper) {
        if (
            tickLower >= tickUpper ||
            tickLower < TickMath.MIN_TICK ||
            tickUpper > TickMath.MAX_TICK ||
            tickLower % UNISWAP_V3_DEFAULT_TICKSPACING != 0 ||
            tickUpper % UNISWAP_V3_DEFAULT_TICKSPACING != 0
        ) revert InvalidTicks(tickLower, tickUpper);
        _;
    }

    /**
        PLATFORM FUNCTIONS
     */

    function initialize(InitializeVPoolWrapperParams calldata params) external initializer {
        clearingHouse = IClearingHouse(params.clearingHouse);
        vToken = params.vToken;
        vQuote = params.vQuote;
        vPool = params.vPool;

        liquidityFeePips = params.liquidityFeePips;
        protocolFeePips = params.protocolFeePips;

        fundingRateOverrideX128 = type(int256).max;

        // initializes the funding payment state by zeroing the funding payment for time 0 to blockTimestamp
        fpGlobal.update({
            vTokenAmount: 0,
            liquidity: 1,
            blockTimestamp: _blockTimestamp(),
            virtualPriceX128: 1,
            fundingRateX128: 0 // causes zero funding payment
        });
    }

    function collectAccruedProtocolFee() external onlyClearingHouse returns (uint256 accruedProtocolFeeLast) {
        // check for underflow (to skip if accruedProtocolFee is 0)
        if (accruedProtocolFee != 0) {
            accruedProtocolFeeLast = accruedProtocolFee - 1;
            accruedProtocolFee = 1;
        }
        emit AccruedProtocolFeeCollected(accruedProtocolFeeLast);
    }

    /// @notice Update the global funding state, from clearing house
    /// @dev Done when clearing house is paused or unpaused, to prevent funding payments from being received
    ///     or paid when clearing house is in paused mode.
    function updateGlobalFundingState(bool useZeroFundingRate) public onlyClearingHouse {
        (int256 fundingRateX128, uint256 virtualPriceX128) = getFundingRateAndVirtualPrice();
        fpGlobal.update({
            vTokenAmount: 0,
            liquidity: 1,
            blockTimestamp: _blockTimestamp(),
            virtualPriceX128: virtualPriceX128,
            fundingRateX128: useZeroFundingRate ? int256(0) : fundingRateX128
        });
    }

    /**
        ADMIN FUNCTIONS
     */

    function setLiquidityFee(uint24 liquidityFeePips_) external onlyGovernance {
        if (liquidityFeePips_ > PERC_10_1E6) revert InvalidSetting(0x10);
        liquidityFeePips = liquidityFeePips_;
        emit LiquidityFeeUpdated(liquidityFeePips_);
    }

    function setProtocolFee(uint24 protocolFeePips_) external onlyGovernance {
        if (protocolFeePips_ > PERC_10_1E6) revert InvalidSetting(0x20);
        protocolFeePips = protocolFeePips_;
        emit ProtocolFeeUpdated(protocolFeePips_);
    }

    function setFundingRateOverride(int256 fundingRateOverrideX128_) external onlyGovernanceOrTeamMultisig {
        uint256 fundingRateOverrideX128Abs = fundingRateOverrideX128_.absUint();
        // ensure that funding rate magnitude is < 100% APR
        if (
            fundingRateOverrideX128_ != FUNDING_RATE_OVERRIDE_NULL_VALUE &&
            fundingRateOverrideX128Abs > FixedPoint128.Q128 / (365 days)
        ) revert InvalidSetting(0x30);
        fundingRateOverrideX128 = fundingRateOverrideX128_;
        emit FundingRateOverrideUpdated(fundingRateOverrideX128_);
    }

    /**
        EXTERNAL UTILITY METHODS
     */

    /// @notice Swap vToken for vQuote, or vQuote for vToken
    /// @param swapVTokenForVQuote: The direction of the swap, true for vToken to vQuote, false for vQuote to vToken
    /// @param amountSpecified: The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96: The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap.
    /// @return swapResult swap return values, which contain the execution details of the swap
    function swap(
        bool swapVTokenForVQuote, // zeroForOne
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) public onlyClearingHouse returns (SwapResult memory swapResult) {
        bool exactIn = amountSpecified >= 0;

        if (sqrtPriceLimitX96 == 0) {
            sqrtPriceLimitX96 = swapVTokenForVQuote ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
        }

        swapResult.amountSpecified = amountSpecified;

        SwapMath.beforeSwap(
            exactIn,
            swapVTokenForVQuote,
            UNISWAP_V3_DEFAULT_FEE_TIER,
            liquidityFeePips,
            protocolFeePips,
            swapResult
        );

        {
            SimulateSwap.Cache memory cache;
            cache.tickSpacing = UNISWAP_V3_DEFAULT_TICKSPACING;
            cache.fee = UNISWAP_V3_DEFAULT_FEE_TIER;
            (int256 fundingRateX128, uint256 virtualPriceX128) = getFundingRateAndVirtualPrice();
            _writeCacheExtraValues(cache, virtualPriceX128, fundingRateX128);

            // simulate swap and update our tick states
            (int256 vTokenIn_simulated, int256 vQuoteIn_simulated, SimulateSwap.State memory state) = vPool
                .simulateSwap(swapVTokenForVQuote, swapResult.amountSpecified, sqrtPriceLimitX96, cache, _onSwapStep);

            // store prices for the simulated swap in the swap result
            swapResult.sqrtPriceX96Start = cache.sqrtPriceX96Start;
            swapResult.sqrtPriceX96End = state.sqrtPriceX96;

            // execute actual swap on uniswap
            (swapResult.vTokenIn, swapResult.vQuoteIn) = vPool.swap(
                address(this),
                swapVTokenForVQuote,
                swapResult.amountSpecified,
                sqrtPriceLimitX96,
                ''
            );

            // simulated swap should be identical to actual swap
            assert(vTokenIn_simulated == swapResult.vTokenIn && vQuoteIn_simulated == swapResult.vQuoteIn);
        }

        SwapMath.afterSwap(
            exactIn,
            swapVTokenForVQuote,
            UNISWAP_V3_DEFAULT_FEE_TIER,
            liquidityFeePips,
            protocolFeePips,
            swapResult
        );

        // record the protocol fee, for withdrawal in future
        accruedProtocolFee += swapResult.protocolFees;

        // burn the tokens received from the swap
        _vBurn();

        emit Swap(swapResult);
    }

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        onlyClearingHouse
        checkTicks(tickLower, tickUpper)
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        )
    {
        // records the funding payment for last updated timestamp to blockTimestamp using current price difference
        _updateGlobalFundingState();

        wrapperValuesInside = _updateTicks(tickLower, tickUpper, liquidity.toInt128(), vPool.tickCurrent());

        (uint256 _amount0, uint256 _amount1) = vPool.mint({
            recipient: address(this),
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount: liquidity,
            data: ''
        });

        vTokenPrincipal = _amount0;
        vQuotePrincipal = _amount1;
    }

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        onlyClearingHouse
        checkTicks(tickLower, tickUpper)
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        )
    {
        // records the funding payment for last updated timestamp to blockTimestamp using current price difference
        _updateGlobalFundingState();

        wrapperValuesInside = _updateTicks(tickLower, tickUpper, -liquidity.toInt128(), vPool.tickCurrent());

        (uint256 _amount0, uint256 _amount1) = vPool.burn({
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount: liquidity
        });

        vTokenPrincipal = _amount0;
        vQuotePrincipal = _amount1;
        _collect(tickLower, tickUpper);
    }

    /**
        UNISWAP V3 POOL CALLBACkS
     */

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external virtual onlyUniswapV3Pool {
        if (amount0Delta > 0) {
            // uniswap v3 pool token0 is always vToken (ensured in RageTradeFactory._isIVTokenAddressGood)
            IVToken(vPool.token0()).mint(address(vPool), uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            // uniswap v3 pool token1 is always vQuote (ensured in RageTradeFactory._isIVTokenAddressGood)
            IVQuote(vPool.token1()).mint(address(vPool), uint256(amount1Delta));
        }
    }

    function uniswapV3MintCallback(
        uint256 vTokenAmount,
        uint256 vQuoteAmount,
        bytes calldata
    ) external override onlyUniswapV3Pool {
        if (vQuoteAmount > 0) vQuote.mint(msg.sender, vQuoteAmount);
        if (vTokenAmount > 0) vToken.mint(msg.sender, vTokenAmount);
    }

    /**
        VIEW METHODS
     */

    function getFundingRateAndVirtualPrice() public view returns (int256 fundingRateX128, uint256 virtualPriceX128) {
        int256 _fundingRateOverrideX128 = fundingRateOverrideX128;
        bool shouldUseActualPrices = _fundingRateOverrideX128 == FUNDING_RATE_OVERRIDE_NULL_VALUE;

        uint32 poolId = vToken.truncate();
        virtualPriceX128 = clearingHouse.getVirtualTwapPriceX128(poolId);

        if (shouldUseActualPrices) {
            // uses actual price to calculate funding rate
            uint256 realPriceX128 = clearingHouse.getRealTwapPriceX128(poolId);
            fundingRateX128 = FundingPayment.getFundingRate(realPriceX128, virtualPriceX128);
        } else {
            // uses funding rate override
            fundingRateX128 = _fundingRateOverrideX128;
        }
    }

    function getSumAX128() external view returns (int256) {
        return fpGlobal.sumAX128;
    }

    function getExtrapolatedSumAX128() public view returns (int256) {
        (int256 fundingRateX128, uint256 virtualPriceX128) = getFundingRateAndVirtualPrice();
        return
            FundingPayment.extrapolatedSumAX128(
                fpGlobal.sumAX128,
                fpGlobal.timestampLast,
                _blockTimestamp(),
                fundingRateX128,
                virtualPriceX128
            );
    }

    function getValuesInside(int24 tickLower, int24 tickUpper)
        public
        view
        checkTicks(tickLower, tickUpper)
        returns (WrapperValuesInside memory wrapperValuesInside)
    {
        (, int24 currentTick, , , , , ) = vPool.slot0();
        FundingPayment.Info memory _fpGlobal = fpGlobal;
        wrapperValuesInside.sumAX128 = _fpGlobal.sumAX128;
        (
            wrapperValuesInside.sumBInsideX128,
            wrapperValuesInside.sumFpInsideX128,
            wrapperValuesInside.sumFeeInsideX128
        ) = ticksExtended.getTickExtendedStateInside(tickLower, tickUpper, currentTick, _fpGlobal, sumFeeGlobalX128);
    }

    function getExtrapolatedValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside)
    {
        (, int24 currentTick, , , , , ) = vPool.slot0();
        FundingPayment.Info memory _fpGlobal = fpGlobal;

        ///@dev update sumA and sumFP to extrapolated values according to current timestamp
        _fpGlobal.sumAX128 = getExtrapolatedSumAX128();
        _fpGlobal.sumFpX128 = FundingPayment.extrapolatedSumFpX128(
            fpGlobal.sumAX128,
            fpGlobal.sumBX128,
            fpGlobal.sumFpX128,
            _fpGlobal.sumAX128
        );

        wrapperValuesInside.sumAX128 = _fpGlobal.sumAX128;
        (
            wrapperValuesInside.sumBInsideX128,
            wrapperValuesInside.sumFpInsideX128,
            wrapperValuesInside.sumFeeInsideX128
        ) = ticksExtended.getTickExtendedStateInside(tickLower, tickUpper, currentTick, _fpGlobal, sumFeeGlobalX128);
    }

    /**
        INTERNAL HELPERS
     */

    function _collect(int24 tickLower, int24 tickUpper) internal {
        // (uint256 amount0, uint256 amount1) =
        vPool.collect({
            recipient: address(this),
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Requested: type(uint128).max,
            amount1Requested: type(uint128).max
        });

        _vBurn();
    }

    function _readCacheExtraValues(SimulateSwap.Cache memory cache)
        private
        pure
        returns (uint256 virtualPriceX128, int256 fundingRateX128)
    {
        uint256 value1 = cache.value1;
        uint256 value2 = cache.value2;
        assembly {
            virtualPriceX128 := value1
            fundingRateX128 := value2
        }
    }

    function _writeCacheExtraValues(
        SimulateSwap.Cache memory cache,
        uint256 virtualPriceX128,
        int256 fundingRateX128
    ) private pure {
        uint256 value1;
        uint256 value2;
        assembly {
            value1 := virtualPriceX128
            value2 := fundingRateX128
        }
        cache.value1 = value1;
        cache.value2 = value2;
    }

    function _onSwapStep(
        bool swapVTokenForVQuote,
        SimulateSwap.Cache memory cache,
        SimulateSwap.State memory state,
        SimulateSwap.Step memory step
    ) internal {
        // these vQuote and vToken amounts are zero fee swap amounts (fee collected by uniswaop is ignored and burned later)
        (uint256 vTokenAmount, uint256 vQuoteAmount) = swapVTokenForVQuote
            ? (step.amountIn, step.amountOut)
            : (step.amountOut, step.amountIn);

        // here, vQuoteAmount == swap amount
        (uint256 liquidityFees, ) = SwapMath.calculateFees(
            vQuoteAmount.toInt256(),
            SwapMath.AmountTypeEnum.ZERO_FEE_VQUOTE_AMOUNT,
            liquidityFeePips,
            protocolFeePips
        );

        // vQuote amount with fees
        // vQuoteAmount = _includeFees(
        //     vQuoteAmount,
        //     liquidityFees + protocolFees,
        //     swapVTokenForVQuote ? IncludeFeeEnum.SUBTRACT_FEE : IncludeFeeEnum.ADD_FEE
        // );

        if (state.liquidity > 0 && vTokenAmount > 0) {
            (uint256 virtualPriceX128, int256 fundingRateX128) = _readCacheExtraValues(cache);
            fpGlobal.update({
                vTokenAmount: swapVTokenForVQuote ? vTokenAmount.toInt256() : -vTokenAmount.toInt256(), // when trader goes long, LP goes short
                liquidity: state.liquidity,
                blockTimestamp: _blockTimestamp(),
                virtualPriceX128: virtualPriceX128,
                fundingRateX128: fundingRateX128
            });

            sumFeeGlobalX128 += liquidityFees.mulDiv(FixedPoint128.Q128, state.liquidity);
        }

        // if we have reached the end price of tick
        if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
            // if the tick is initialized, run the tick transition
            if (step.initialized) {
                ticksExtended.cross(step.tickNext, fpGlobal, sumFeeGlobalX128);
            }
        }
    }

    /// @notice Update global funding payment, by getting prices from Clearing House
    function _updateGlobalFundingState() internal {
        (int256 fundingRateX128, uint256 virtualPriceX128) = getFundingRateAndVirtualPrice();
        fpGlobal.update({
            vTokenAmount: 0,
            liquidity: 1,
            blockTimestamp: _blockTimestamp(),
            virtualPriceX128: virtualPriceX128,
            fundingRateX128: fundingRateX128
        });
    }

    function _updateTicks(
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tickCurrent
    ) private returns (WrapperValuesInside memory wrapperValuesInside) {
        FundingPayment.Info memory _fpGlobal = fpGlobal; // SLOAD
        uint256 _sumFeeGlobalX128 = sumFeeGlobalX128;

        // if we need to update the ticks, do it
        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            flippedLower = ticksExtended.update(
                tickLower,
                tickCurrent,
                liquidityDelta,
                _fpGlobal.sumAX128,
                _fpGlobal.sumBX128,
                _fpGlobal.sumFpX128,
                _sumFeeGlobalX128,
                vPool
            );
            flippedUpper = ticksExtended.update(
                tickUpper,
                tickCurrent,
                liquidityDelta,
                _fpGlobal.sumAX128,
                _fpGlobal.sumBX128,
                _fpGlobal.sumFpX128,
                _sumFeeGlobalX128,
                vPool
            );
        }

        wrapperValuesInside = getValuesInside(tickLower, tickUpper);

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedLower) {
                ticksExtended.clear(tickLower);
            }
            if (flippedUpper) {
                ticksExtended.clear(tickUpper);
            }
        }
    }

    function _vBurn() internal {
        uint256 vQuoteBal = vQuote.balanceOf(address(this));
        if (vQuoteBal > 0) {
            vQuote.burn(vQuoteBal);
        }
        uint256 vTokenBal = vToken.balanceOf(address(this));
        if (vTokenBal > 0) {
            vToken.burn(vTokenBal);
        }
    }

    // used to set time in tests
    function _blockTimestamp() internal view virtual returns (uint48) {
        return uint48(block.timestamp);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

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
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IVQuote } from './IVQuote.sol';
import { IVToken } from './IVToken.sol';

interface IVPoolWrapper {
    struct InitializeVPoolWrapperParams {
        address clearingHouse; // address of clearing house contract (proxy)
        IVToken vToken; // address of vToken contract
        IVQuote vQuote; // address of vQuote contract
        IUniswapV3Pool vPool; // address of Uniswap V3 Pool contract, created using vToken and vQuote
        uint24 liquidityFeePips; // liquidity fee fraction (in 1e6)
        uint24 protocolFeePips; // protocol fee fraction (in 1e6)
    }

    struct SwapResult {
        int256 amountSpecified; // amount of tokens/vQuote which were specified in the swap request
        int256 vTokenIn; // actual amount of vTokens paid by account to the Pool
        int256 vQuoteIn; // actual amount of vQuotes paid by account to the Pool
        uint256 liquidityFees; // actual amount of fees paid by account to the Pool
        uint256 protocolFees; // actual amount of fees paid by account to the Protocol
        uint160 sqrtPriceX96Start; // sqrt price at the beginning of the swap
        uint160 sqrtPriceX96End; // sqrt price at the end of the swap
    }

    struct WrapperValuesInside {
        int256 sumAX128; // sum of all the A terms in the pool
        int256 sumBInsideX128; // sum of all the B terms in side the tick range in the pool
        int256 sumFpInsideX128; // sum of all the Fp terms in side the tick range in the pool
        uint256 sumFeeInsideX128; // sum of all the fee terms in side the tick range in the pool
    }

    /// @notice Emitted whenever a swap takes place
    /// @param swapResult the swap result values
    event Swap(SwapResult swapResult);

    /// @notice Emitted whenever liquidity is added
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was added
    /// @param vTokenPrincipal the amount of vToken that was sent to UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was sent to UniswapV3Pool
    event Mint(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever liquidity is removed
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was removed
    /// @param vTokenPrincipal the amount of vToken that was received from UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was received from UniswapV3Pool
    event Burn(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever clearing house enquired about the accrued protocol fees
    /// @param amount the amount of accrued protocol fees
    event AccruedProtocolFeeCollected(uint256 amount);

    /// @notice Emitted when governance updates the liquidity fees
    /// @param liquidityFeePips the new liquidity fee ratio
    event LiquidityFeeUpdated(uint24 liquidityFeePips);

    /// @notice Emitted when governance updates the protocol fees
    /// @param protocolFeePips the new protocol fee ratio
    event ProtocolFeeUpdated(uint24 protocolFeePips);

    /// @notice Emitted when funding rate override is updated
    /// @param fundingRateOverrideX128 the new funding rate override value
    event FundingRateOverrideUpdated(int256 fundingRateOverrideX128);

    function initialize(InitializeVPoolWrapperParams memory params) external;

    function vPool() external view returns (IUniswapV3Pool);

    function getValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function getExtrapolatedValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function swap(
        bool swapVTokenForVQuote, // zeroForOne
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (SwapResult memory swapResult);

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function getSumAX128() external view returns (int256);

    function getExtrapolatedSumAX128() external view returns (int256);

    function liquidityFeePips() external view returns (uint24);

    function protocolFeePips() external view returns (uint24);

    /// @notice Used by clearing house to update funding rate when clearing house is paused or unpaused.
    /// @param useZeroFundingRate: used to discount funding payment during the duration ch was paused.
    function updateGlobalFundingState(bool useZeroFundingRate) external;

    /// @notice Used by clearing house to know how much protocol fee was collected.
    /// @return accruedProtocolFeeLast amount of protocol fees accrued since last collection.
    /// @dev Does not do any token transfer, just reduces the state in wrapper by accruedProtocolFeeLast.
    ///     Clearing house already has the amount of settlement tokens to send to treasury.
    function collectAccruedProtocolFee() external returns (uint256 accruedProtocolFeeLast);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVQuote is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function authorize(address vPoolWrapper) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function setVPoolWrapper(address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IGovernable } from './IGovernable.sol';

import { IClearingHouseActions } from './clearinghouse/IClearingHouseActions.sol';
import { IClearingHouseCustomErrors } from './clearinghouse/IClearingHouseCustomErrors.sol';
import { IClearingHouseEnums } from './clearinghouse/IClearingHouseEnums.sol';
import { IClearingHouseEvents } from './clearinghouse/IClearingHouseEvents.sol';
import { IClearingHouseOwnerActions } from './clearinghouse/IClearingHouseOwnerActions.sol';
import { IClearingHouseStructures } from './clearinghouse/IClearingHouseStructures.sol';
import { IClearingHouseSystemActions } from './clearinghouse/IClearingHouseSystemActions.sol';
import { IClearingHouseView } from './clearinghouse/IClearingHouseView.sol';

interface IClearingHouse is
    IGovernable,
    IClearingHouseEnums,
    IClearingHouseStructures,
    IClearingHouseActions,
    IClearingHouseCustomErrors,
    IClearingHouseEvents,
    IClearingHouseOwnerActions,
    IClearingHouseSystemActions,
    IClearingHouseView
{}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IOracle } from '../IOracle.sol';
import { IVToken } from '../IVToken.sol';
import { IVPoolWrapper } from '../IVPoolWrapper.sol';

import { IClearingHouseEnums } from './IClearingHouseEnums.sol';

interface IClearingHouseStructures is IClearingHouseEnums {
    struct BalanceAdjustments {
        int256 vQuoteIncrease; // specifies the increase in vQuote balance
        int256 vTokenIncrease; // specifies the increase in token balance
        int256 traderPositionIncrease; // specifies the increase in trader position
    }

    struct Collateral {
        IERC20 token; // address of the collateral token
        CollateralSettings settings; // collateral settings, changable by governance later
    }

    struct CollateralSettings {
        IOracle oracle; // address of oracle which gives price to be used for collateral
        uint32 twapDuration; // duration of the twap in seconds
        bool isAllowedForDeposit; // whether the collateral is allowed to be deposited at the moment
    }

    struct CollateralDepositView {
        IERC20 collateral; // address of the collateral token
        uint256 balance; // balance of the collateral in the account
    }

    struct LiquidityChangeParams {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        int128 liquidityDelta; // positive to add liquidity, negative to remove liquidity
        uint160 sqrtPriceCurrent; // hint for virtual price, to prevent sandwitch attack
        uint16 slippageToleranceBps; // slippage tolerance in bps, to prevent sandwitch attack
        bool closeTokenPosition; // whether to close the token position generated due to the liquidity change
        LimitOrderType limitOrderType; // limit order type
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct LiquidityPositionView {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        uint128 liquidity; // liquidity in the range by the account
        int256 vTokenAmountIn; // amount of token supplied by the account, to calculate net position
        int256 sumALastX128; // checkpoint of the term A in funding payment math
        int256 sumBInsideLastX128; // checkpoint of the term B in funding payment math
        int256 sumFpInsideLastX128; // checkpoint of the term Fp in funding payment math
        uint256 sumFeeInsideLastX128; // checkpoint of the trading fees
        LimitOrderType limitOrderType; // limit order type
    }

    struct LiquidationParams {
        uint16 rangeLiquidationFeeFraction; // fraction of net token position rm from the range to be charged as liquidation fees (in 1e5)
        uint16 tokenLiquidationFeeFraction; // fraction of traded amount of vquote to be charged as liquidation fees (in 1e5)
        uint16 closeFactorMMThresholdBps; // fraction the MM threshold for partial liquidation (in 1e4)
        uint16 partialLiquidationCloseFactorBps; // fraction the % of position to be liquidated if partial liquidation should occur (in 1e4)
        uint16 insuranceFundFeeShareBps; // fraction of the fee share for insurance fund out of the total liquidation fee (in 1e4)
        uint16 liquidationSlippageSqrtToleranceBps; // fraction of the max sqrt price slippage threshold (in 1e4) (can be set to - actual price slippage tolerance / 2)
        uint64 maxRangeLiquidationFees; // maximum range liquidation fees (in settlement token amount decimals)
        uint64 minNotionalLiquidatable; // minimum notional value of position for it to be eligible for partial liquidation (in settlement token amount decimals)
    }

    struct MulticallOperation {
        MulticallOperationType operationType; // operation type
        bytes data; // abi encoded data for the operation
    }

    struct Pool {
        IVToken vToken; // address of the vToken, poolId = vToken.truncate()
        IUniswapV3Pool vPool; // address of the UniswapV3Pool(token0=vToken, token1=vQuote, fee=500)
        IVPoolWrapper vPoolWrapper; // wrapper address
        PoolSettings settings; // pool settings, which can be updated by governance later
    }

    struct PoolSettings {
        uint16 initialMarginRatioBps; // margin ratio (1e4) considered for create/update position, removing margin or profit
        uint16 maintainanceMarginRatioBps; // margin ratio (1e4) considered for liquidations by keeper
        uint16 maxVirtualPriceDeviationRatioBps; // maximum deviation (1e4) from the current virtual price
        uint32 twapDuration; // twap duration (seconds) for oracle
        bool isAllowedForTrade; // whether the pool is allowed to be traded at the moment
        bool isCrossMargined; // whether cross margined is done for positions of this pool
        IOracle oracle; // spot price feed twap oracle for this pool
    }

    struct SwapParams {
        int256 amount; // amount of tokens/vQuote to swap
        uint160 sqrtPriceLimit; // threshold sqrt price which should not be crossed
        bool isNotional; // whether the amount represents vQuote amount
        bool isPartialAllowed; // whether to end swap (partial) when sqrtPriceLimit is reached, instead of reverting
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct TickRange {
        int24 tickLower;
        int24 tickUpper;
    }

    struct VTokenPositionView {
        uint32 poolId; // id of the pool of which this token position is for
        int256 balance; // vTokenLong - vTokenShort
        int256 netTraderPosition; // net position due to trades and liquidity change carries
        int256 sumALastX128; // checkoint of the term A in funding payment math
        LiquidityPositionView[] liquidityPositions; // liquidity positions of the account in the pool
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../interfaces/IVToken.sol';

/// @title Address helper functions
library AddressHelper {
    /// @notice converts address to uint32, using the least significant 32 bits
    /// @param addr Address to convert
    /// @return truncated last 4 bytes of the address
    function truncate(address addr) internal pure returns (uint32 truncated) {
        assembly {
            truncated := and(addr, 0xffffffff)
        }
    }

    /// @notice converts IERC20 contract to uint32
    /// @param addr contract
    /// @return truncated last 4 bytes of the address
    function truncate(IERC20 addr) internal pure returns (uint32 truncated) {
        return truncate(address(addr));
    }

    /// @notice checks if two addresses are equal
    /// @param a first address
    /// @param b second address
    /// @return true if addresses are equal
    function eq(address a, address b) internal pure returns (bool) {
        return a == b;
    }

    /// @notice checks if addresses of two IERC20 contracts are equal
    /// @param a first contract
    /// @param b second contract
    /// @return true if addresses are equal
    function eq(IERC20 a, IERC20 b) internal pure returns (bool) {
        return eq(address(a), address(b));
    }

    /// @notice checks if an address is zero
    /// @param a address to check
    /// @return true if address is zero
    function isZero(address a) internal pure returns (bool) {
        return a == address(0);
    }

    /// @notice checks if address of an IERC20 contract is zero
    /// @param a contract to check
    /// @return true if address is zero
    function isZero(IERC20 a) internal pure returns (bool) {
        return isZero(address(a));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';

import { SafeCast } from './SafeCast.sol';
import { SignedFullMath } from './SignedFullMath.sol';

/// @title Funding payment functions
/// @notice Funding Payment Logic used to distribute the FP bill paid by traders among the LPs in the liquidity range
library FundingPayment {
    using FullMath for uint256;
    using SafeCast for uint256;
    using SignedFullMath for int256;

    struct Info {
        // FR * P * dt
        int256 sumAX128;
        // trade token amount / liquidity
        int256 sumBX128;
        // sum(a * sumB)
        int256 sumFpX128;
        // time when state was last updated
        uint48 timestampLast;
    }

    event FundingPaymentStateUpdated(
        FundingPayment.Info fundingPayment,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    );

    /// @notice Calculates the funding rate based on prices
    /// @param realPriceX128 spot price of token
    /// @param virtualPriceX128 futures price of token
    function getFundingRate(uint256 realPriceX128, uint256 virtualPriceX128)
        internal
        pure
        returns (int256 fundingRateX128)
    {
        int256 priceDeltaX128 = virtualPriceX128.toInt256() - realPriceX128.toInt256();
        return priceDeltaX128.mulDiv(FixedPoint128.Q128, realPriceX128) / 1 days;
    }

    /// @notice Used to update the state of the funding payment whenever a trade takes place
    /// @param info pointer to the funding payment state
    /// @param vTokenAmount trade token amount
    /// @param liquidity active liquidity in the range during the trade (step)
    /// @param blockTimestamp timestamp of current block
    /// @param fundingRateX128 the constant funding rate to apply for the duration between timestampLast and blockTimestamp
    /// @param virtualPriceX128 futures price of token
    function update(
        FundingPayment.Info storage info,
        int256 vTokenAmount,
        uint256 liquidity,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal {
        int256 a = nextAX128(info.timestampLast, blockTimestamp, fundingRateX128, virtualPriceX128);
        info.sumFpX128 += a.mulDivRoundingDown(info.sumBX128, int256(FixedPoint128.Q128));
        info.sumAX128 += a;
        info.sumBX128 += vTokenAmount.mulDiv(int256(FixedPoint128.Q128), int256(liquidity));
        info.timestampLast = blockTimestamp;

        emit FundingPaymentStateUpdated(info, fundingRateX128, virtualPriceX128);
    }

    /// @notice Used to get the rate of funding payment for the duration between last trade and this trade
    /// @dev Positive A value means at this duration, longs pay shorts. Negative means shorts pay longs.
    /// @param timestampLast start timestamp of duration
    /// @param blockTimestamp end timestamp of duration
    /// @param virtualPriceX128 futures price of token
    /// @param fundingRateX128 the constant funding rate to apply for the duration between timestampLast and blockTimestamp
    /// @return aX128 value called "a" (see funding payment math documentation)
    function nextAX128(
        uint48 timestampLast,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal pure returns (int256 aX128) {
        return fundingRateX128.mulDiv(virtualPriceX128, FixedPoint128.Q128) * int48(blockTimestamp - timestampLast);
    }

    function extrapolatedSumAX128(
        int256 sumAX128,
        uint48 timestampLast,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal pure returns (int256) {
        return sumAX128 + nextAX128(timestampLast, blockTimestamp, fundingRateX128, virtualPriceX128);
    }

    /// @notice Extrapolates (updates) the value of sumFp by adding the missing component to it using sumAGlobalX128
    /// @param sumAX128 sumA value that is recorded from global at some point in time
    /// @param sumBX128 sumB value that is recorded from global at same point in time as sumA
    /// @param sumFpX128 sumFp value that is recorded from global at same point in time as sumA and sumB
    /// @param sumAGlobalX128 latest sumA value (taken from global), used to extrapolate the sumFp
    function extrapolatedSumFpX128(
        int256 sumAX128,
        int256 sumBX128,
        int256 sumFpX128,
        int256 sumAGlobalX128
    ) internal pure returns (int256) {
        return sumFpX128 + sumBX128.mulDiv(sumAGlobalX128 - sumAX128, int256(FixedPoint128.Q128));
    }

    /// @notice Positive bill is charged from LPs, Negative bill is rewarded to LPs
    /// @param sumAX128 latest value of sumA (to be taken from global state)
    /// @param sumFpInsideX128 latest value of sumFp inside range (to be computed using global state + tick state)
    /// @param sumALastX128 value of sumA when LP updated their liquidity last time
    /// @param sumBInsideLastX128 value of sumB inside range when LP updated their liquidity last time
    /// @param sumFpInsideLastX128 value of sumFp inside range when LP updated their liquidity last time
    /// @param liquidity amount of liquidity which was constant for LP in the time duration
    /// @return amount of vQuote tokens that should be charged if positive
    function bill(
        int256 sumAX128,
        int256 sumFpInsideX128,
        int256 sumALastX128,
        int256 sumBInsideLastX128,
        int256 sumFpInsideLastX128,
        uint256 liquidity
    ) internal pure returns (int256) {
        return
            (sumFpInsideX128 - extrapolatedSumFpX128(sumALastX128, sumBInsideLastX128, sumFpInsideLastX128, sumAX128))
                .mulDivRoundingDown(liquidity, FixedPoint128.Q128);
    }

    /// @notice Positive bill is charged from Traders, Negative bill is rewarded to Traders
    /// @param sumAX128 latest value of sumA (to be taken from global state)
    /// @param sumALastX128 value of sumA when trader updated their netTraderPosition
    /// @param netTraderPosition oken amount which should be constant for time duration since sumALastX128 was recorded
    /// @return amount of vQuote tokens that should be charged if positive
    function bill(
        int256 sumAX128,
        int256 sumALastX128,
        int256 netTraderPosition
    ) internal pure returns (int256) {
        return netTraderPosition.mulDiv((sumAX128 - sumALastX128), int256(FixedPoint128.Q128));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { SwapMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/SwapMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';
import { TickBitmapExtended } from './TickBitmapExtended.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Simulate Uniswap V3 Swaps
library SimulateSwap {
    using SafeCast for uint256;
    using TickBitmapExtended for function(int16) external view returns (uint256);

    error ZeroAmount();
    error InvalidSqrtPriceLimit(uint160 sqrtPriceLimitX96);

    struct Cache {
        // price at the beginning of the swap
        uint160 sqrtPriceX96Start;
        // tick at the beginning of the swap
        int24 tickStart;
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the tick spacing of the pool
        int24 tickSpacing;
        // the lp fee share of the pool
        uint24 fee;
        // extra values for cache, that may be useful for _onSwapStep
        uint256 value1;
        uint256 value2;
    }

    struct State {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalIncreaseX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct Step {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    /// @notice Simulates a swap over an Uniswap V3 Pool, allowing to handle tick crosses.
    /// @param v3Pool uniswap v3 pool address
    /// @param zeroForOne direction of swap, true means swap zero for one
    /// @param amountSpecified amount to swap in/out
    /// @param sqrtPriceLimitX96 the maximum price to swap to, if this price is reached, then the swap is stopped partially
    /// @param cache the swap cache, can be passed empty or with some values filled in to prevent STATICCALLS to v3Pool
    /// @param onSwapStep function to call for each step of the swap, passing in the swap state and the step computations
    /// @return amount0 token0 amount
    /// @return amount1 token1 amount
    /// @return state swap state at the end of the swap
    function simulateSwap(
        IUniswapV3Pool v3Pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        SimulateSwap.Cache memory cache,
        function(bool, SimulateSwap.Cache memory, SimulateSwap.State memory, SimulateSwap.Step memory) onSwapStep
    )
        internal
        returns (
            int256 amount0,
            int256 amount1,
            SimulateSwap.State memory state
        )
    {
        if (amountSpecified == 0) revert ZeroAmount();

        // if cache.sqrtPriceX96Start is not set, then make a STATICCALL to v3Pool
        if (cache.sqrtPriceX96Start == 0) {
            (cache.sqrtPriceX96Start, cache.tickStart, , , , cache.feeProtocol, ) = v3Pool.slot0();
        }

        // if cache.liquidityStart is not set, then make a STATICCALL to v3Pool
        if (cache.liquidityStart == 0) cache.liquidityStart = v3Pool.liquidity();

        // if cache.tickSpacing is not set, then make a STATICCALL to v3Pool
        if (cache.tickSpacing == 0) {
            cache.fee = v3Pool.fee();
            cache.tickSpacing = v3Pool.tickSpacing();
        }

        // ensure that the sqrtPriceLimitX96 makes sense
        if (
            zeroForOne
                ? sqrtPriceLimitX96 > cache.sqrtPriceX96Start || sqrtPriceLimitX96 < TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 < cache.sqrtPriceX96Start || sqrtPriceLimitX96 > TickMath.MAX_SQRT_RATIO
        ) revert InvalidSqrtPriceLimit(sqrtPriceLimitX96);

        bool exactInput = amountSpecified > 0;

        state = SimulateSwap.State({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: cache.sqrtPriceX96Start,
            tick: cache.tickStart,
            feeGrowthGlobalIncreaseX128: 0,
            protocolFee: 0,
            liquidity: cache.liquidityStart
        });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            SimulateSwap.Step memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = v3Pool.tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                cache.tickSpacing,
                zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                cache.fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated - step.amountOut.toInt256();
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated + (step.amountIn + step.feeAmount).toInt256();
            }

            // update global fee tracker
            if (state.liquidity > 0) {
                state.feeGrowthGlobalIncreaseX128 += FullMath.mulDiv(
                    step.feeAmount,
                    FixedPoint128.Q128,
                    state.liquidity
                );
            }

            // jump to the method that handles the swap step
            onSwapStep(zeroForOne, cache, state, step);

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, adjust the liquidity
                if (step.initialized) {
                    (, int128 liquidityNet, , , , , , ) = v3Pool.ticks(step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) liquidityNet = -liquidityNet;
                    state.liquidity = liquidityNet < 0
                        ? state.liquidity - uint128(-liquidityNet)
                        : state.liquidity + uint128(liquidityNet);
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
    }

    /// @notice Overloads simulate swap to prevent passing a cache input
    /// @param v3Pool uniswap v3 pool address
    /// @param zeroForOne direction of swap, true means swap zero for one
    /// @param amountSpecified amount to swap in/out
    /// @param sqrtPriceLimitX96 the maximum price to swap to, if this price is reached, then the swap is stopped partially
    /// @param onSwapStep function to call for each step of the swap, passing in the swap state and the step computations
    /// @return amount0 token0 amount
    /// @return amount1 token1 amount
    /// @return state swap state at the end of the swap
    /// @return cache swap cache populated with values, can be used for subsequent simulations
    function simulateSwap(
        IUniswapV3Pool v3Pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        function(bool, SimulateSwap.Cache memory, SimulateSwap.State memory, SimulateSwap.Step memory) onSwapStep
    )
        internal
        returns (
            int256 amount0,
            int256 amount1,
            SimulateSwap.State memory state,
            SimulateSwap.Cache memory cache
        )
    {
        (amount0, amount1, state) = simulateSwap(
            v3Pool,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            cache,
            onSwapStep
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { FundingPayment } from './FundingPayment.sol';

import { IVToken } from '../interfaces/IVToken.sol';

/// @title Extended tick state for VPoolWrapper
library TickExtended {
    struct Info {
        int256 sumALastX128;
        int256 sumBOutsideX128;
        int256 sumFpOutsideX128;
        uint256 sumFeeOutsideX128;
    }

    /// @notice Calculates the extended tick state inside a tick range
    /// @param self mapping of tick index to tick extended state
    /// @param tickLower lower tick index
    /// @param tickUpper upper tick index
    /// @param tickCurrent current tick index
    /// @param fpGlobal global funding payment state
    /// @param sumFeeGlobalX128 global sum of fees for liquidity providers
    /// @return sumBInsideX128 sum of all B values for trades that took place inside the tick range
    /// @return sumFpInsideX128 sum of all FP values for trades that took place inside the tick range
    /// @return sumFeeInsideX128 sum of all fee values for trades that took place inside the tick range
    function getTickExtendedStateInside(
        mapping(int24 => TickExtended.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        FundingPayment.Info memory fpGlobal,
        uint256 sumFeeGlobalX128
    )
        internal
        view
        returns (
            int256 sumBInsideX128,
            int256 sumFpInsideX128,
            uint256 sumFeeInsideX128
        )
    {
        Info storage lower = self[tickLower];
        Info storage upper = self[tickUpper];

        int256 sumBBelowX128 = lower.sumBOutsideX128;
        int256 sumFpBelowX128 = FundingPayment.extrapolatedSumFpX128(
            lower.sumALastX128,
            sumBBelowX128, // lower.sumBOutsideX128,
            lower.sumFpOutsideX128,
            fpGlobal.sumAX128
        );
        uint256 sumFeeBelowX128 = lower.sumFeeOutsideX128;
        if (tickLower > tickCurrent) {
            sumBBelowX128 = fpGlobal.sumBX128 - sumBBelowX128;
            sumFpBelowX128 = fpGlobal.sumFpX128 - sumFpBelowX128;
            sumFeeBelowX128 = sumFeeGlobalX128 - sumFeeBelowX128;
        }

        int256 sumBAboveX128 = upper.sumBOutsideX128;
        int256 sumFpAboveX128 = FundingPayment.extrapolatedSumFpX128(
            upper.sumALastX128,
            sumBAboveX128, // upper.sumBOutsideX128,
            upper.sumFpOutsideX128,
            fpGlobal.sumAX128
        );
        uint256 sumFeeAboveX128 = upper.sumFeeOutsideX128;
        if (tickUpper <= tickCurrent) {
            sumBAboveX128 = fpGlobal.sumBX128 - sumBAboveX128;
            sumFpAboveX128 = fpGlobal.sumFpX128 - sumFpAboveX128;
            sumFeeAboveX128 = sumFeeGlobalX128 - sumFeeAboveX128;
        }

        sumBInsideX128 = fpGlobal.sumBX128 - sumBBelowX128 - sumBAboveX128;
        sumFpInsideX128 = fpGlobal.sumFpX128 - sumFpBelowX128 - sumFpAboveX128;
        sumFeeInsideX128 = sumFeeGlobalX128 - sumFeeBelowX128 - sumFeeAboveX128;
    }

    /// @notice Updates the extended tick state whenever liquidity is updated
    /// @param self mapping of tick index to tick extended state
    /// @param tick to update
    /// @param tickCurrent current tick index
    /// @param liquidityDelta delta of liquidity
    /// @param sumAGlobalX128 global funding payment state sumA
    /// @param sumBGlobalX128 global funding payment state sumB
    /// @param sumFpGlobalX128 global funding payment state sumFp
    /// @param sumFeeGlobalX128 global sum of fees for liquidity providers
    /// @param vPool uniswap v3 pool contract
    /// @return flipped whether the tick was flipped or no
    function update(
        mapping(int24 => TickExtended.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        int256 sumAGlobalX128,
        int256 sumBGlobalX128,
        int256 sumFpGlobalX128,
        uint256 sumFeeGlobalX128,
        IUniswapV3Pool vPool
    ) internal returns (bool flipped) {
        TickExtended.Info storage info = self[tick];

        (uint128 liquidityGrossBefore, , , , , , , ) = vPool.ticks(tick);
        uint128 liquidityGrossAfter = liquidityDelta < 0
            ? liquidityGrossBefore - uint128(-liquidityDelta)
            : liquidityGrossBefore + uint128(liquidityDelta);

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.sumALastX128 = sumAGlobalX128;
                info.sumBOutsideX128 = sumBGlobalX128;
                info.sumFpOutsideX128 = sumFpGlobalX128;
                info.sumFeeOutsideX128 = sumFeeGlobalX128;
            }
        }
    }

    /// @notice Updates the extended tick state whenever tick is crossed in a swap
    /// @param self mapping of tick index to tick extended state
    /// @param tick to update
    /// @param fpGlobal global funding payment state
    /// @param sumFeeGlobalX128 global sum of fees for liquidity providers
    function cross(
        mapping(int24 => TickExtended.Info) storage self,
        int24 tick,
        FundingPayment.Info memory fpGlobal,
        uint256 sumFeeGlobalX128
    ) internal {
        TickExtended.Info storage info = self[tick];
        int256 sumFpOutsideX128 = FundingPayment.extrapolatedSumFpX128(
            info.sumALastX128,
            info.sumBOutsideX128,
            info.sumFpOutsideX128,
            fpGlobal.sumAX128
        );
        info.sumALastX128 = fpGlobal.sumAX128;
        info.sumBOutsideX128 = fpGlobal.sumBX128 - info.sumBOutsideX128;
        info.sumFpOutsideX128 = fpGlobal.sumFpX128 - sumFpOutsideX128;
        info.sumFeeOutsideX128 = sumFeeGlobalX128 - info.sumFeeOutsideX128;
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => TickExtended.Info) storage self, int24 tick) internal {
        delete self[tick];
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { FixedPoint96 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint96.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { Bisection } from './Bisection.sol';

/// @title Price math functions
library PriceMath {
    using FullMath for uint256;

    error IllegalSqrtPrice(uint160 sqrtPriceX96);

    /// @notice Computes the square of a sqrtPriceX96 value
    /// @param sqrtPriceX96: the square root of the input price in Q96 format
    /// @return priceX128 : input price in Q128 format
    function toPriceX128(uint160 sqrtPriceX96) internal pure returns (uint256 priceX128) {
        if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 >= TickMath.MAX_SQRT_RATIO) {
            revert IllegalSqrtPrice(sqrtPriceX96);
        }

        priceX128 = _toPriceX128(sqrtPriceX96);
    }

    /// @notice computes the square of a sqrtPriceX96 value
    /// @param sqrtPriceX96: input price in Q128 format
    function _toPriceX128(uint160 sqrtPriceX96) private pure returns (uint256 priceX128) {
        priceX128 = uint256(sqrtPriceX96).mulDiv(sqrtPriceX96, 1 << 64);
    }

    /// @notice computes the square root of a priceX128 value
    /// @param priceX128: input price in Q128 format
    /// @return sqrtPriceX96 : the square root of the input price in Q96 format
    function toSqrtPriceX96(uint256 priceX128) internal pure returns (uint160 sqrtPriceX96) {
        // Uses bisection method to find solution to the equation toPriceX128(x) = priceX128
        sqrtPriceX96 = Bisection.findSolution(
            _toPriceX128,
            priceX128,
            /// @dev sqrtPriceX96 is always bounded by MIN_SQRT_RATIO and MAX_SQRT_RATIO.
            ///     If solution falls outside of these bounds, findSolution method reverts
            TickMath.MIN_SQRT_RATIO,
            TickMath.MAX_SQRT_RATIO - 1
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Safe cast functions
library SafeCast {
    error SafeCast_Int128Overflow(uint128 value);

    function toInt128(uint128 y) internal pure returns (int128 z) {
        unchecked {
            if (y >= 2**127) revert SafeCast_Int128Overflow(y);
            z = int128(y);
        }
    }

    error SafeCast_Int256Overflow(uint256 value);

    function toInt256(uint256 y) internal pure returns (int256 z) {
        unchecked {
            if (y >= 2**255) revert SafeCast_Int256Overflow(y);
            z = int256(y);
        }
    }

    error SafeCast_UInt224Overflow(uint256 value);

    function toUint224(uint256 y) internal pure returns (uint224 z) {
        if (y > 2**224) revert SafeCast_UInt224Overflow(y);
        z = uint224(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

int256 constant ONE = 1;

/// @title Signed math functions
library SignedMath {
    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int
    function abs(int256 value) internal pure returns (int256) {
        return value > 0 ? value : -value;
    }

    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int as unsigned int
    function absUint(int256 value) internal pure returns (uint256) {
        return uint256(abs(value));
    }

    /// @notice gives the sign of a signed int
    /// @param value signed int
    /// @return -1 if negative, 1 if non-negative
    function sign(int256 value) internal pure returns (int256) {
        return value >= 0 ? ONE : -ONE;
    }

    /// @notice converts a signed integer into an unsigned integer and inverts positive bool if negative
    /// @param a signed int
    /// @param positive initial value of positive bool
    /// @return _a absolute value of int provided
    /// @return bool xor of the positive boolean and sign of the provided int
    function extractSign(int256 a, bool positive) internal pure returns (uint256 _a, bool) {
        if (a < 0) {
            positive = !positive;
            _a = uint256(-a);
        } else {
            _a = uint256(a);
        }
        return (_a, positive);
    }

    /// @notice extracts the sign of a signed int
    /// @param a signed int
    /// @return _a unsigned int
    /// @return bool sign of the provided int
    function extractSign(int256 a) internal pure returns (uint256 _a, bool) {
        return extractSign(a, true);
    }

    /// @notice returns the max of two int256 numbers
    /// @param a first number
    /// @param b second number
    /// @return c = max of a and b
    function max(int256 a, int256 b) internal pure returns (int256 c) {
        if (a > b) c = a;
        else c = b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';

import { SignedMath } from './SignedMath.sol';

/// @title Signed full math functions
library SignedFullMath {
    using SafeCast for uint256;
    using SignedMath for int256;

    /// @notice uses full math on signed int and two unsigned ints
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = FullMath.mulDiv(a < 0 ? uint256(-1 * a) : uint256(a), b, denominator).toInt256();
        if (a < 0) {
            result = -result;
        }
    }

    /// @notice uses full math on three signed ints
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        bool resultPositive = true;
        uint256 _a;
        uint256 _b;
        uint256 _denominator;

        (_a, resultPositive) = a.extractSign(resultPositive);
        (_b, resultPositive) = b.extractSign(resultPositive);
        (_denominator, resultPositive) = denominator.extractSign(resultPositive);

        result = FullMath.mulDiv(_a, _b, _denominator).toInt256();
        if (!resultPositive) {
            result = -result;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b, denominator)) {
            result += -1;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b.absUint(), denominator.absUint())) {
            result += -1;
        }
    }

    /// @notice checks if full multiplication of a & b would have a remainder if divided by denominator
    /// @param a: multiplicand
    /// @param b: multiplier
    /// @param denominator: divisor
    /// @return hasRemainder true if there is a remainder, false otherwise
    function _hasRemainder(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) private pure returns (bool hasRemainder) {
        assembly {
            let remainder := mulmod(a, b, denominator)
            if gt(remainder, 0) {
                hasRemainder := 1
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { SignedMath } from './SignedMath.sol';

import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';

/// @title Swap computation functions
library SwapMath {
    using SignedMath for int256;

    /// @notice Executed before swap call to uniswap, to inflate the swap result values
    /// @param exactIn Whether user specified in amount or out amount
    /// @param swapVTokenForVQuote swap direction
    /// @param uniswapFeePips fee ratio that will be collected by uniswap
    /// @param liquidityFeePips fee ratio to be applied in rage trade for paying to liquidity providers
    /// @param protocolFeePips fee ratio to be applied in rage trade for protocol treasury
    /// @param swapResult pointer to the swap result struct
    /// @dev this method mutates the data pointed by swapResult
    function beforeSwap(
        bool exactIn,
        bool swapVTokenForVQuote,
        uint24 uniswapFeePips,
        uint24 liquidityFeePips,
        uint24 protocolFeePips,
        IVPoolWrapper.SwapResult memory swapResult
    ) internal pure {
        // inflate or deinfate to undo uniswap fees if necessary, and account for our fees
        if (exactIn) {
            if (swapVTokenForVQuote) {
                // CASE: exactIn vToken
                // fee: not now, will collect fee in vQuote after swap
                // inflate: for undoing the uniswap fees
                swapResult.amountSpecified = inflate(swapResult.amountSpecified, uniswapFeePips);
            } else {
                // CASE: exactIn vQuote
                // fee: remove fee and do smaller swap, so trader gets less vTokens
                // here, amountSpecified == swap amount + fee
                (swapResult.liquidityFees, swapResult.protocolFees) = calculateFees(
                    swapResult.amountSpecified,
                    AmountTypeEnum.VQUOTE_AMOUNT_PLUS_FEES,
                    liquidityFeePips,
                    protocolFeePips
                );
                swapResult.amountSpecified = includeFees(
                    swapResult.amountSpecified,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.SUBTRACT_FEE
                );
                // inflate: uniswap will collect fee so inflate to undo it
                swapResult.amountSpecified = inflate(swapResult.amountSpecified, uniswapFeePips);
            }
        } else {
            if (!swapVTokenForVQuote) {
                // CASE: exactOut vToken
                // fee: no need to collect fee as we want to collect fee in vQuote later
                // inflate: no need to inflate as uniswap collects fees in tokenIn
            } else {
                // CASE: exactOut vQuote
                // fee: buy more vQuote (short more vToken) so that fee can be removed in vQuote
                // here, amountSpecified + fee == swap amount
                (swapResult.liquidityFees, swapResult.protocolFees) = calculateFees(
                    swapResult.amountSpecified,
                    AmountTypeEnum.VQUOTE_AMOUNT_MINUS_FEES,
                    liquidityFeePips,
                    protocolFeePips
                );
                swapResult.amountSpecified = includeFees(
                    swapResult.amountSpecified,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.ADD_FEE
                );
            }
        }
    }

    /// @notice Executed after swap call to uniswap, to deinflate the swap result values
    /// @param exactIn Whether user specified in amount or out amount
    /// @param swapVTokenForVQuote swap direction
    /// @param uniswapFeePips fee that will be collected by uniswap
    /// @param liquidityFeePips fee ratio to be applied in rage trade for paying to liquidity providers
    /// @param protocolFeePips fee ratio to be applied in rage trade for protocol treasury
    /// @param swapResult pointer to the swap result struct
    /// @dev This method mutates the data pointed by swapResult
    function afterSwap(
        bool exactIn,
        bool swapVTokenForVQuote,
        uint24 uniswapFeePips,
        uint24 liquidityFeePips,
        uint24 protocolFeePips,
        IVPoolWrapper.SwapResult memory swapResult
    ) internal pure {
        // swap is done so now adjusting vTokenIn and vQuoteIn amounts to remove uniswap fees and add our fees
        if (exactIn) {
            if (swapVTokenForVQuote) {
                // CASE: exactIn vToken
                // deinflate: vToken amount was inflated so that uniswap can collect fee
                swapResult.vTokenIn = deinflate(swapResult.vTokenIn, uniswapFeePips);

                // fee: collect the fee, give less vQuote to trader
                // here, vQuoteIn == swap amount
                (swapResult.liquidityFees, swapResult.protocolFees) = calculateFees(
                    swapResult.vQuoteIn,
                    AmountTypeEnum.ZERO_FEE_VQUOTE_AMOUNT,
                    liquidityFeePips,
                    protocolFeePips
                );
                swapResult.vQuoteIn = includeFees(
                    swapResult.vQuoteIn,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.SUBTRACT_FEE
                );
            } else {
                // CASE: exactIn vQuote
                // deinflate: vQuote amount was inflated, hence need to deinflate for generating final statement
                swapResult.vQuoteIn = deinflate(swapResult.vQuoteIn, uniswapFeePips);
                // fee: fee is already removed before swap, lets include it to the final bill, so that trader pays for it
                swapResult.vQuoteIn = includeFees(
                    swapResult.vQuoteIn,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.ADD_FEE
                );
            }
        } else {
            if (!swapVTokenForVQuote) {
                // CASE: exactOut vToken
                // deinflate: uniswap want to collect fee in vQuote and hence ask more, so need to deinflate it
                swapResult.vQuoteIn = deinflate(swapResult.vQuoteIn, uniswapFeePips);
                // fee: collecting fees in vQuote
                // here, vQuoteIn == swap amount
                (swapResult.liquidityFees, swapResult.protocolFees) = calculateFees(
                    swapResult.vQuoteIn,
                    AmountTypeEnum.ZERO_FEE_VQUOTE_AMOUNT,
                    liquidityFeePips,
                    protocolFeePips
                );
                swapResult.vQuoteIn = includeFees(
                    swapResult.vQuoteIn,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.ADD_FEE
                );
            } else {
                // CASE: exactOut vQuote
                // deinflate: uniswap want to collect fee in vToken and hence ask more, so need to deinflate it
                swapResult.vTokenIn = deinflate(swapResult.vTokenIn, uniswapFeePips);
                // fee: already calculated before, subtract now
                swapResult.vQuoteIn = includeFees(
                    swapResult.vQuoteIn,
                    swapResult.liquidityFees + swapResult.protocolFees,
                    IncludeFeeEnum.SUBTRACT_FEE
                );
            }
        }
    }

    /// @notice Inflates the amount such that when uniswap collects the fee, it will get the same amount
    /// @param amount user specified amount
    /// @param uniswapFeePips fee that will be collected by uniswap
    /// @return inflated amount, on which applying uniswap fee gives the user specifed amount
    function inflate(int256 amount, uint24 uniswapFeePips) internal pure returns (int256 inflated) {
        int256 fees = (amount * int256(uint256(uniswapFeePips))) / int24(1e6 - uniswapFeePips) + 1; // round up
        inflated = amount + fees;
    }

    /// @notice Undoes the inflation of the amount
    /// @param inflated amount from uniswap after the swap call
    /// @param uniswapFeePips fee that will be collected by uniswap
    /// @return amount that is deinflated, which can be given to user
    function deinflate(int256 inflated, uint24 uniswapFeePips) internal pure returns (int256 amount) {
        amount = (inflated * int24(1e6 - uniswapFeePips)) / 1e6;
    }

    enum AmountTypeEnum {
        ZERO_FEE_VQUOTE_AMOUNT,
        VQUOTE_AMOUNT_MINUS_FEES,
        VQUOTE_AMOUNT_PLUS_FEES
    }

    /// @notice Calculates the fees to be collected by rage trade protocol
    /// @param amount should be in vQuote denomination, since fees to be collected only in vQuote
    /// @param amountTypeEnum type of amount
    /// @param liquidityFeePips fee ratio to be applied in rage trade for paying to liquidity providers
    /// @param protocolFeePips fee ratio to be applied in rage trade for protocol treasury
    /// @return liquidityFees calculated fees in vQuote, to be given to liquidity providers
    /// @return protocolFees calculated fees in vQuote, to be given to protocol treasury
    function calculateFees(
        int256 amount,
        AmountTypeEnum amountTypeEnum,
        uint24 liquidityFeePips,
        uint24 protocolFeePips
    ) internal pure returns (uint256 liquidityFees, uint256 protocolFees) {
        uint256 amountAbs = uint256(amount.abs());
        if (amountTypeEnum == AmountTypeEnum.VQUOTE_AMOUNT_MINUS_FEES) {
            // when amount is already subtracted by fees, we need to scale it up, so that
            // on calculating and subtracting fees on the scaled up value, we should get same amount
            amountAbs = (amountAbs * 1e6) / uint256(1e6 - liquidityFeePips - protocolFeePips);
        } else if (amountTypeEnum == AmountTypeEnum.VQUOTE_AMOUNT_PLUS_FEES) {
            // when amount is already added with fees, we need to scale it down, so that
            // on calculating and adding fees on the scaled down value, we should get same amount
            amountAbs = (amountAbs * 1e6) / uint256(1e6 + liquidityFeePips + protocolFeePips);
        }
        uint256 fees = (amountAbs * (liquidityFeePips + protocolFeePips)) / 1e6 + 1; // round up
        liquidityFees = (amountAbs * liquidityFeePips) / 1e6 + 1; // round up
        protocolFees = fees - liquidityFees;
    }

    enum IncludeFeeEnum {
        ADD_FEE,
        SUBTRACT_FEE
    }

    /// @notice Applies the fees in the amount, based on sign of the amount
    /// @param amount amount to which fees are to be applied
    /// @param fees fees to be applied
    /// @param includeFeeEnum procedure to apply the fee
    /// @return amountAfterFees amount after applying fees
    function includeFees(
        int256 amount,
        uint256 fees,
        IncludeFeeEnum includeFeeEnum
    ) internal pure returns (int256 amountAfterFees) {
        if ((amount > 0) == (includeFeeEnum == IncludeFeeEnum.ADD_FEE)) {
            amountAfterFees = amount + int256(fees);
        } else {
            amountAfterFees = amount - int256(fees);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

/// @title UniswapV3Pool helper functions
library UniswapV3PoolHelper {
    using UniswapV3PoolHelper for IUniswapV3Pool;

    error UV3PH_OracleConsultFailed();

    /// @notice Get the pool's current tick
    /// @param v3Pool The uniswap v3 pool contract
    /// @return tick the current tick
    function tickCurrent(IUniswapV3Pool v3Pool) internal view returns (int24 tick) {
        (, tick, , , , , ) = v3Pool.slot0();
    }

    /// @notice Get the pool's current sqrt price
    /// @param v3Pool The uniswap v3 pool contract
    /// @return sqrtPriceX96 the current sqrt price
    function sqrtPriceCurrent(IUniswapV3Pool v3Pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = v3Pool.slot0();
    }

    /// @notice Get twap price for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return sqrtPriceX96 the twap price
    function twapSqrtPrice(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (uint160 sqrtPriceX96) {
        int24 _twapTick = v3Pool.twapTick(twapDuration);
        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(_twapTick);
    }

    /// @notice Get twap tick for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return _twapTick the twap tick
    function twapTick(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (int24 _twapTick) {
        if (twapDuration == 0) {
            return v3Pool.tickCurrent();
        }

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = twapDuration;
        secondAgos[1] = 0;

        // this call will fail if period is bigger than MaxObservationPeriod
        try v3Pool.observe(secondAgos) returns (int56[] memory tickCumulatives, uint160[] memory) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int56(uint56(twapDuration)));

            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapDuration)) != 0)) {
                timeWeightedAverageTick--;
            }
            return timeWeightedAverageTick;
        } catch {
            // if for some reason v3Pool.observe fails, fallback to the current tick
            (, _twapTick, , , , , ) = v3Pool.slot0();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import { IExtsload } from '../interfaces/IExtsload.sol';

/// @notice Allows the inheriting contract make it's state accessable to other contracts
/// https://ethereum-magicians.org/t/extsload-opcode-proposal/2410/11
abstract contract Extsload is IExtsload {
    function extsload(bytes32 slot) external view returns (bytes32 val) {
        assembly {
            val := sload(slot)
        }
    }

    function extsload(bytes32[] memory slots) external view returns (bytes32[] memory) {
        assembly {
            let end := add(0x20, add(slots, mul(mload(slots), 0x20)))
            for {
                let pointer := add(slots, 32)
            } lt(pointer, end) {

            } {
                let value := sload(mload(pointer))
                mstore(pointer, value)
                pointer := add(pointer, 0x20)
            }
        }

        return slots;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

// Uniswap V3 Factory address is same across different networks
address constant UNISWAP_V3_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
uint24 constant UNISWAP_V3_DEFAULT_FEE_TIER = 500;
int24 constant UNISWAP_V3_DEFAULT_TICKSPACING = 10;
bytes32 constant UNISWAP_V3_POOL_BYTE_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

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

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
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
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
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
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
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

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
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

pragma solidity >=0.5.0;

interface IGovernable {
    function governance() external view returns (address);

    function governancePending() external view returns (address);

    function teamMultisig() external view returns (address);

    function teamMultisigPending() external view returns (address);

    function initiateGovernanceTransfer(address newGovernancePending) external;

    function acceptGovernanceTransfer() external;

    function initiateTeamMultisigTransfer(address newTeamMultisigPending) external;

    function acceptTeamMultisigTransfer() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseActions is IClearingHouseStructures {
    /// @notice creates a new account and adds it to the accounts map
    /// @return newAccountId - serial number of the new account created
    function createAccount() external returns (uint256 newAccountId);

    /// @notice deposits 'amount' of token associated with 'poolId'
    /// @param accountId account id
    /// @param collateralId truncated address of token to deposit
    /// @param amount amount of token to deposit
    function updateMargin(
        uint256 accountId,
        uint32 collateralId,
        int256 amount
    ) external;

    /// @notice creates a new account and deposits 'amount' of token associated with 'poolId'
    /// @param collateralId truncated address of collateral token to deposit
    /// @param amount amount of token to deposit
    /// @return newAccountId - serial number of the new account created
    function createAccountAndAddMargin(uint32 collateralId, uint256 amount) external returns (uint256 newAccountId);

    /// @notice withdraws 'amount' of settlement token from the profit made
    /// @param accountId account id
    /// @param amount amount of token to withdraw
    function updateProfit(uint256 accountId, int256 amount) external;

    /// @notice settles the profit/loss made with the settlement token collateral deposits
    /// @param accountId account id
    function settleProfit(uint256 accountId) external;

    /// @notice swaps token associated with 'poolId' by 'amount' (Long if amount>0 else Short)
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param swapParams swap parameters
    function swapToken(
        uint256 accountId,
        uint32 poolId,
        SwapParams memory swapParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice updates range order of token associated with 'poolId' by 'liquidityDelta' (Adds if amount>0 else Removes)
    /// @notice also can be used to update limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param liquidityChangeParams liquidity change parameters
    function updateRangeOrder(
        uint256 accountId,
        uint32 poolId,
        LiquidityChangeParams calldata liquidityChangeParams
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut);

    /// @notice keeper call to remove a limit order
    /// @dev checks the position of current price relative to limit order and checks limitOrderType
    /// @param accountId account id
    /// @param poolId truncated address of token to withdraw
    /// @param tickLower liquidity change parameters
    /// @param tickUpper liquidity change parameters
    function removeLimitOrder(
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper
    ) external;

    /// @notice keeper call for liquidation of range position
    /// @dev removes all the active range positions and gives liquidator a percent of notional amount closed + fixedFee
    /// @param accountId account id
    function liquidateLiquidityPositions(uint256 accountId) external;

    /// @notice keeper call for liquidation of token position
    /// @dev transfers the fraction of token position at a discount to current price to liquidators account and gives liquidator some fixedFee
    /// @param targetAccountId account id
    /// @param poolId truncated address of token to withdraw
    /// @return keeperFee - amount of fees transferred to keeper
    function liquidateTokenPosition(uint256 targetAccountId, uint32 poolId) external returns (int256 keeperFee);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseCustomErrors is IClearingHouseStructures {
    /// @notice error to denote invalid account access
    /// @param senderAddress address of msg sender
    error AccessDenied(address senderAddress);

    /// @notice error to denote usage of uninitialized token
    /// @param collateralId address of token
    error CollateralDoesNotExist(uint32 collateralId);

    /// @notice error to denote usage of unsupported collateral token
    /// @param collateralId address of token
    error CollateralNotAllowedForUse(uint32 collateralId);

    /// @notice error to denote unpause is in progress, hence cannot pause
    error CannotPauseIfUnpauseInProgress();

    /// @notice error to denote pause is in progress, hence cannot unpause
    error CannotUnpauseIfPauseInProgress();

    /// @notice error to denote incorrect address is supplied while updating collateral settings
    /// @param incorrectAddress incorrect address of collateral token
    /// @param correctAddress correct address of collateral token
    error IncorrectCollateralAddress(IERC20 incorrectAddress, IERC20 correctAddress);

    /// @notice error to denote invalid address supplied as a collateral token
    /// @param invalidAddress invalid address of collateral token
    error InvalidCollateralAddress(address invalidAddress);

    /// @notice error to denote invalid token liquidation (fraction to liquidate> 1)
    error InvalidTokenLiquidationParameters();

    /// @notice this is errored when the enum (uint8) value is out of bounds
    /// @param multicallOperationType is the value that is out of bounds
    error InvalidMulticallOperationType(MulticallOperationType multicallOperationType);

    /// @notice error to denote that keeper fee is negative or zero
    error KeeperFeeNotPositive(int256 keeperFee);

    /// @notice error to denote low notional value of txn
    /// @param notionalValue notional value of txn
    error LowNotionalValue(uint256 notionalValue);

    /// @notice error to denote that caller is not ragetrade factory
    error NotRageTradeFactory();

    /// @notice error to denote usage of uninitialized pool
    /// @param poolId unitialized truncated address supplied
    error PoolDoesNotExist(uint32 poolId);

    /// @notice error to denote usage of unsupported pool
    /// @param poolId address of token
    error PoolNotAllowedForTrade(uint32 poolId);

    /// @notice error to denote slippage of txn beyond set threshold
    error SlippageBeyondTolerance();

    /// @notice error to denote that zero amount is passed and it's prohibited
    error ZeroAmount();

    /// @notice error to denote an invalid setting for parameters
    error InvalidSetting(uint256 errorCode);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClearingHouseEnums {
    enum LimitOrderType {
        NONE,
        LOWER_LIMIT,
        UPPER_LIMIT
    }

    enum MulticallOperationType {
        UPDATE_MARGIN,
        UPDATE_PROFIT,
        SWAP_TOKEN,
        UPDATE_RANGE_ORDER,
        REMOVE_LIMIT_ORDER,
        LIQUIDATE_LIQUIDITY_POSITIONS,
        LIQUIDATE_TOKEN_POSITION
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseEvents is IClearingHouseStructures {
    /// @notice denotes new account creation
    /// @param ownerAddress wallet address of account owner
    /// @param accountId serial number of the account
    event AccountCreated(address indexed ownerAddress, uint256 accountId);

    /// @notice new collateral supported as margin
    /// @param cTokenInfo collateral token info
    event CollateralSettingsUpdated(IERC20 cToken, CollateralSettings cTokenInfo);

    /// @notice maintainance margin ratio of a pool changed
    /// @param poolId id of the rage trade pool
    /// @param settings new settings
    event PoolSettingsUpdated(uint32 poolId, PoolSettings settings);

    /// @notice protocol settings changed
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    event ProtocolSettingsUpdated(
        LiquidationParams liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    );

    event PausedUpdated(bool paused);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseOwnerActions is IClearingHouseStructures {
    /// @notice updates the collataral settings
    /// @param cToken collateral token
    /// @param collateralSettings settings
    function updateCollateralSettings(IERC20 cToken, CollateralSettings memory collateralSettings) external;

    /// @notice updates the rage trade pool settings
    /// @param poolId rage trade pool id
    /// @param newSettings updated rage trade pool settings
    function updatePoolSettings(uint32 poolId, PoolSettings calldata newSettings) external;

    /// @notice updates the protocol settings
    /// @param liquidationParams liquidation params
    /// @param removeLimitOrderFee fee for remove limit order
    /// @param minimumOrderNotional minimum order notional
    /// @param minRequiredMargin minimum required margin
    function updateProtocolSettings(
        LiquidationParams calldata liquidationParams,
        uint256 removeLimitOrderFee,
        uint256 minimumOrderNotional,
        uint256 minRequiredMargin
    ) external;

    /// @notice withdraws protocol fees collected in the supplied wrappers to team multisig
    /// @param numberOfPoolsToUpdateInThisTx number of pools to collect fees from
    function withdrawProtocolFee(uint256 numberOfPoolsToUpdateInThisTx) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IInsuranceFund } from '../IInsuranceFund.sol';
import { IOracle } from '../IOracle.sol';
import { IVQuote } from '../IVQuote.sol';
import { IVToken } from '../IVToken.sol';

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';

interface IClearingHouseSystemActions is IClearingHouseStructures {
    /// @notice initializes clearing house contract
    /// @param rageTradeFactoryAddress rage trade factory address
    /// @param defaultCollateralToken address of default collateral token
    /// @param defaultCollateralTokenOracle address of default collateral token oracle
    /// @param insuranceFund address of insurance fund
    /// @param vQuote address of vQuote
    function initialize(
        address rageTradeFactoryAddress,
        address initialGovernance,
        address initialTeamMultisig,
        IERC20 defaultCollateralToken,
        IOracle defaultCollateralTokenOracle,
        IInsuranceFund insuranceFund,
        IVQuote vQuote
    ) external;

    function registerPool(Pool calldata poolInfo) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IClearingHouseStructures } from './IClearingHouseStructures.sol';
import { IExtsload } from '../IExtsload.sol';

interface IClearingHouseView is IClearingHouseStructures, IExtsload {
    /// @notice Gets the market value and required margin of an account
    /// @dev This method can be used to check if an account is under water or not.
    ///     If accountMarketValue < requiredMargin then liquidation can take place.
    /// @param accountId the account id
    /// @param isInitialMargin true is initial margin, false is maintainance margin
    /// @return accountMarketValue the market value of the account, due to collateral and positions
    /// @return requiredMargin margin needed due to positions
    function getAccountMarketValueAndRequiredMargin(uint256 accountId, bool isInitialMargin)
        external
        view
        returns (int256 accountMarketValue, int256 requiredMargin);

    /// @notice Gets the net profit of an account
    /// @param accountId the account id
    /// @return accountNetProfit the net profit of the account
    function getAccountNetProfit(uint256 accountId) external view returns (int256 accountNetProfit);

    /// @notice Gets the net position of an account
    /// @param accountId the account id
    /// @param poolId the id of the pool (vETH, ... etc)
    /// @return netPosition the net position of the account
    function getAccountNetTokenPosition(uint256 accountId, uint32 poolId) external view returns (int256 netPosition);

    /// @notice Gets the real twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return realPriceX128 the real price of the pool
    function getRealTwapPriceX128(uint32 poolId) external view returns (uint256 realPriceX128);

    /// @notice Gets the virtual twap price from the respective oracle of the given poolId
    /// @param poolId the id of the pool
    /// @return virtualPriceX128 the virtual price of the pool
    function getVirtualTwapPriceX128(uint32 poolId) external view returns (uint256 virtualPriceX128);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOracle {
    function getTwapPriceX128(uint32 twapDuration) external view returns (uint256 priceX128);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IInsuranceFund {
    function initialize(
        IERC20 settlementToken,
        address clearingHouse,
        string calldata name,
        string calldata symbol
    ) external;

    function claim(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title This is an interface to read contract's state that supports extsload.
interface IExtsload {
    /// @notice Returns a value from the storage.
    /// @param slot to read from.
    /// @return value stored at the slot.
    function extsload(bytes32 slot) external view returns (bytes32 value);

    /// @notice Returns multiple values from storage.
    /// @param slots to read from.
    /// @return values stored at the slots.
    function extsload(bytes32[] memory slots) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {FullMath} from './FullMath.sol';
import {SqrtPriceMath} from './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        unchecked {
            bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
            bool exactIn = amountRemaining >= 0;

            if (exactIn) {
                uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
                amountIn = zeroForOne
                    ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
                if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        amountRemainingLessFee,
                        zeroForOne
                    );
            } else {
                amountOut = zeroForOne
                    ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
                if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
                else
                    sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                        sqrtRatioCurrentX96,
                        liquidity,
                        uint256(-amountRemaining),
                        zeroForOne
                    );
            }

            bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

            // get the input/output amounts
            if (zeroForOne) {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
            } else {
                amountIn = max && exactIn
                    ? amountIn
                    : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
                amountOut = max && !exactIn
                    ? amountOut
                    : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
            }

            // cap the output amount to not exceed the remaining output amount
            if (!exactIn && amountOut > uint256(-amountRemaining)) {
                amountOut = uint256(-amountRemaining);
            }

            if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
                // we didn't reach the target, so take the remainder of the maximum input as fee
                feeAmount = uint256(amountRemaining) - amountIn;
            } else {
                feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import { BitMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/BitMath.sol';

/// @title Tick bitmap extended functions
/// @dev Uses the bitmap from UniswapV3Pool
library TickBitmapExtended {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(uint24(tick % 256));
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        function(int16) external view returns (uint256) self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self(wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(uint24(bitPos - BitMath.mostSignificantBit(masked)))) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self(wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(uint24(BitMath.leastSignificantBit(masked) - bitPos))) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) * tickSpacing;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from './SafeCast.sol';

import {FullMath} from './FullMath.sol';
import {UnsafeMath} from './UnsafeMath.sol';
import {FixedPoint96} from './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            unchecked {
                uint256 product;
                if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }
            }
            // denominator is checked for overflow
            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96) + amount));
        } else {
            unchecked {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
                uint256 denominator = numerator1 - product;
                return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            }
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return (uint256(sqrtPX96) + quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            unchecked {
                return uint160(sqrtPX96 - quotient);
            }
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
            uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

            require(sqrtRatioAX96 > 0);

            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                roundUp
                    ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                    : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                r += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                r += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                r += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                r += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                r += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                r += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                r += 2;
            }
            if (x >= 0x2) r += 1;
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        unchecked {
            r = 255;
            if (x & type(uint128).max > 0) {
                r -= 128;
            } else {
                x >>= 128;
            }
            if (x & type(uint64).max > 0) {
                r -= 64;
            } else {
                x >>= 64;
            }
            if (x & type(uint32).max > 0) {
                r -= 32;
            } else {
                x >>= 32;
            }
            if (x & type(uint16).max > 0) {
                r -= 16;
            } else {
                x >>= 16;
            }
            if (x & type(uint8).max > 0) {
                r -= 8;
            } else {
                x >>= 8;
            }
            if (x & 0xf > 0) {
                r -= 4;
            } else {
                x >>= 4;
            }
            if (x & 0x3 > 0) {
                r -= 2;
            } else {
                x >>= 2;
            }
            if (x & 0x1 > 0) r -= 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Bisection Method
/// @notice https://en.wikipedia.org/wiki/Bisection_method
library Bisection {
    error SolutionOutOfBounds(uint256 y_target, uint160 x_lower, uint160 x_upper);

    /// @notice Finds the solution to the equation f(x) = y_target using the bisection method
    /// @param f: strictly increasing function f: uint160 -> uint256
    /// @param y_target: the target value of f(x)
    /// @param x_lower: the lower bound for x
    /// @param x_upper: the upper bound for x
    /// @return x_target: the rounded down solution to the equation f(x) = y_target
    function findSolution(
        function(uint160) pure returns (uint256) f,
        uint256 y_target,
        uint160 x_lower,
        uint160 x_upper
    ) internal pure returns (uint160) {
        // compute y at the bounds
        uint256 y_lower = f(x_lower);
        uint256 y_upper = f(x_upper);

        // if y is out of the bounds then revert
        if (y_target < y_lower || y_target > y_upper) revert SolutionOutOfBounds(y_target, x_lower, x_upper);

        // bisect repeatedly until the solution is within an error of 1 unit
        uint256 y_mid;
        uint160 x_mid;
        while (x_upper - x_lower > 1) {
            x_mid = x_lower + (x_upper - x_lower) / 2;
            y_mid = f(x_mid);
            if (y_mid > y_target) {
                x_upper = x_mid;
                y_upper = y_mid;
            } else {
                x_lower = x_mid;
                y_lower = y_mid;
            }
        }

        // at this point, x_upper - x_lower is either 0 or 1
        // if it is 1 then check if x_upper is the solution, else return x_lower as the rounded down solution
        return x_lower != x_upper && f(x_upper) == y_target ? x_upper : x_lower;
    }
}