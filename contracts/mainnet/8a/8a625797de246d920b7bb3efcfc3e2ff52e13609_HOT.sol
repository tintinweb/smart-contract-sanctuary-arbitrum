// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { SwapMath } from '../lib/v3-core/contracts/libraries/SwapMath.sol';
import { LiquidityAmounts } from '../lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

import { IERC20 } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol';
import { EIP712 } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol';
import { Math } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/Math.sol';
import { SafeCast } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol';
import {
    SignatureChecker
} from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol';
import {
    ISovereignALM,
    ALMLiquidityQuote,
    ALMLiquidityQuoteInput
} from '../lib/valantis-core/src/ALM/interfaces/ISovereignALM.sol';
import { ISovereignPool } from '../lib/valantis-core/src/pools/interfaces/ISovereignPool.sol';
import {
    ISwapFeeModuleMinimal,
    SwapFeeModuleData
} from '../lib/valantis-core/src/swap-fee-modules/interfaces/ISwapFeeModule.sol';

import { ReserveMath } from './libraries/ReserveMath.sol';
import { HOTParams } from './libraries/HOTParams.sol';
import { TightPack } from './libraries/utils/TightPack.sol';
import { AlternatingNonceBitmap } from './libraries/AlternatingNonceBitmap.sol';
import { HOTConstants } from './libraries/HOTConstants.sol';
import { HybridOrderType, HotWriteSlot, HotReadSlot, HOTConstructorArgs, AMMState } from './structs/HOTStructs.sol';
import { HOTOracle } from './HOTOracle.sol';
import { IHOT } from './interfaces/IHOT.sol';

/**
    @title Hybrid Order Type.
    @notice Valantis Sovereign Liquidity Module.
 */
contract HOT is ISovereignALM, ISwapFeeModuleMinimal, IHOT, EIP712, HOTOracle {
    using Math for uint256;
    using SafeCast for uint256;
    using SignatureChecker for address;
    using HOTParams for HybridOrderType;
    using SafeERC20 for IERC20;
    using TightPack for AMMState;
    using AlternatingNonceBitmap for uint56;

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error HOT__onlyPool();
    error HOT__onlyManager();
    error HOT__onlyLiquidityProvider();
    error HOT__onlyUnpaused();
    error HOT__poolReentrant();
    error HOT__constructor_invalidFeeGrowthBounds();
    error HOT__constructor_invalidLiquidityProvider();
    error HOT__constructor_invalidMinAMMFee();
    error HOT__constructor_invalidManager();
    error HOT__constructor_invalidOraclePriceMaxDiffBips();
    error HOT__constructor_invalidSigner();
    error HOT__constructor_invalidHotMaxDiscountBips();
    error HOT__constructor_invalidSovereignPoolConfig();
    error HOT__depositLiquidity_spotPriceAndOracleDeviation();
    error HOT__getLiquidityQuote_invalidFeePath();
    error HOT__getLiquidityQuote_zeroAmountOut();
    error HOT__proposedFeeds_proposedFeedsAlreadySet();
    error HOT__setMaxAllowedQuotes_invalidMaxAllowedQuotes();
    error HOT__setMaxOracleDeviationBips_exceedsMaxDeviationBounds();
    error HOT__setPriceBounds_spotPriceAndOracleDeviation();
    error HOT__setHotFeeInBips_invalidHotFee();
    error HOT___checkSpotPriceRange_invalidBounds();
    error HOT___checkSpotPriceRange_invalidSqrtSpotPriceX96(uint160 sqrtSpotPriceX96);
    error HOT___ammSwap_invalidSpotPriceAfterSwap();
    error HOT___hotSwap_invalidSignature();
    error HOT___hotSwap_maxHotQuotesExceeded();

    /************************************************
     *  IMMUTABLES
     ***********************************************/

    /**
	    @notice Sovereign Pool to which this Liquidity Module is bound.
    */
    address internal immutable _pool;

    /**
	    @notice Address of account which is meant to deposit & withdraw liquidity.
     */
    address internal immutable _liquidityProvider;

    /**
	    @notice Maximum delay, in seconds, for acceptance of HOT quotes.
    */
    uint32 internal immutable _maxDelay;

    /**
	    @notice Maximum price discount allowed for HOT quotes,
                expressed in basis-points.
    */
    uint16 internal immutable _hotMaxDiscountBipsLower;
    uint16 internal immutable _hotMaxDiscountBipsUpper;

    /**
	    @notice Maximum allowed relative deviation
                between sqrt spot price and sqrt oracle price,
                expressed in basis-points.
     */
    uint16 internal immutable _maxOracleDeviationBound;

    /**
	    @notice Bounds the growth rate, in basis-points, of the AMM fee 
					as time increases between last processed quote.
        Min Value: 0 %
        Max Value: 6.5535 % per second
        @dev 1 unit of feeGrowthE6 = 1/100th of 1 BIPS = 1/10000 of 1%.
        @dev HOT reverts if feeGrowthE6 exceeds these bounds.
     */
    uint16 internal immutable _minAMMFeeGrowthE6;
    uint16 internal immutable _maxAMMFeeGrowthE6;

    /**
	    @notice Minimum allowed AMM fee, in basis-points.
	    @dev HOT reverts if feeMinToken{0,1} is below this value.
     */
    uint16 internal immutable _minAMMFee;

    /************************************************
     *  STORAGE
     ***********************************************/
    /**
        @notice Active AMM Liquidity (which gets utilized during AMM swaps).
     */
    uint128 private _effectiveAMMLiquidity;

    /**
        @notice Tightly packed storage slots for:
            * sqrtSpotPriceX96 (a): AMM square-root spot price, in Q64.96 format.
            * sqrtPriceLowX96 (b): square-root lower price bound, in Q64.96 format.
            * sqrtPriceHighX96 (c): square-root upper price bound, in Q64.96 format.
        
        @dev sqrtSpotPriceX96, sqrtPriceLowX96, and sqrtPriceHighX96 values are packed into 2 slots.
            *slot1:
                <<  32 free bits | upper 64 bits of sqrtPriceLowX96 | 160 bits of sqrtSpotPriceX96 >>
            *slot2:
                << lower 96 bits  of sqrtPriceLowX96 | 160 bits of sqrtPriceHighX96 >>
 

        @dev sqrtSpotPriceX96 can only be updated on AMM swaps or after processing a valid HOT quote.
     */
    AMMState private _ammState;

    /**
        @notice Contains state variables which get updated on swaps. 
     */
    HotWriteSlot public hotWriteSlot;

    /**
	    @notice Address of account which is meant to validate HOT quote signatures.
        @dev Can be updated by `manager`.
     */
    HotReadSlot public hotReadSlot;

    /**
		@notice Account that manages all access controls to this liquidity module.
     */
    address public manager;

    /**
	    @notice Maximum amount of token{0,1} to quote to solvers on each HOT.
        @dev Can be updated by `manager`.
     */
    uint256 internal _maxToken0VolumeToQuote;
    uint256 internal _maxToken1VolumeToQuote;

    /**
	    @notice If feeds are not set during deployment, then manager can propose feeds, once after deployment.
        @dev Can be updated by `manager`.
     */
    address public proposedFeedToken0;
    address public proposedFeedToken1;

    /************************************************
     *  MODIFIERS
     ***********************************************/

    modifier onlyPool() {
        _onlyPool();
        _;
    }

    modifier onlyManager() {
        _onlyManager();
        _;
    }

    modifier onlyLiquidityProvider() {
        _onlyLiquidityProvider();
        _;
    }

    modifier onlyUnpaused() {
        _onlyUnpaused();
        _;
    }

    modifier poolNonReentrant() {
        _poolNonReentrant();
        _;
    }

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor(
        HOTConstructorArgs memory _args
    )
        EIP712('Valantis HOT', '1')
        HOTOracle(
            ISovereignPool(_args.pool).token0(),
            ISovereignPool(_args.pool).token1(),
            _args.feedToken0,
            _args.feedToken1,
            _args.maxOracleUpdateDurationFeed0,
            _args.maxOracleUpdateDurationFeed1
        )
    {
        // Sovereign Pool cannot have an external sovereignVault, nor a verifierModule
        bool isValidPoolConfig = (ISovereignPool(_args.pool).sovereignVault() == _args.pool) &&
            (ISovereignPool(_args.pool).verifierModule() == address(0));
        if (!isValidPoolConfig) {
            revert HOT__constructor_invalidSovereignPoolConfig();
        }

        _pool = _args.pool;

        if (_args.manager == address(0)) {
            revert HOT__constructor_invalidManager();
        }

        manager = _args.manager;

        if (_args.signer == address(0)) {
            revert HOT__constructor_invalidSigner();
        }

        hotReadSlot.signer = _args.signer;

        if (_args.liquidityProvider == address(0)) {
            revert HOT__constructor_invalidLiquidityProvider();
        }

        _liquidityProvider = _args.liquidityProvider;

        _maxDelay = _args.maxDelay;

        if (
            _args.hotMaxDiscountBipsLower > _args.maxOracleDeviationBound ||
            _args.hotMaxDiscountBipsUpper > _args.maxOracleDeviationBound
        ) {
            revert HOT__constructor_invalidHotMaxDiscountBips();
        }

        _hotMaxDiscountBipsLower = _args.hotMaxDiscountBipsLower;
        _hotMaxDiscountBipsUpper = _args.hotMaxDiscountBipsUpper;

        if (_args.maxOracleDeviationBound > HOTConstants.BIPS) {
            revert HOT__constructor_invalidOraclePriceMaxDiffBips();
        }

        _maxOracleDeviationBound = _args.maxOracleDeviationBound;

        if (_args.minAMMFeeGrowthE6 > _args.maxAMMFeeGrowthE6) {
            revert HOT__constructor_invalidFeeGrowthBounds();
        }
        _minAMMFeeGrowthE6 = _args.minAMMFeeGrowthE6;

        _maxAMMFeeGrowthE6 = _args.maxAMMFeeGrowthE6;

        if (_args.minAMMFee > HOTConstants.BIPS) {
            revert HOT__constructor_invalidMinAMMFee();
        }

        _minAMMFee = _args.minAMMFee;

        HOTParams.validatePriceBounds(_args.sqrtSpotPriceX96, _args.sqrtPriceLowX96, _args.sqrtPriceHighX96);

        _ammState.setState(_args.sqrtSpotPriceX96, _args.sqrtPriceLowX96, _args.sqrtPriceHighX96);

        emit ALMDeployed('HOT V1', address(this), address(_pool));

        // AMM State is initialized as unpaused
    }

    /************************************************
     *  GETTER FUNCTIONS
     ***********************************************/

    /**
        @notice Returns all immutable values of the HOT.
        @return pool Sovereign Pool address.
        @return liquidityProvider Liquidity provider address.
        @return maxDelay Maximum delay, in seconds, for acceptance of HOT quotes.
        @return hotMaxDiscountBipsLower Maximum discount allowed for HOT quotes.
        @return hotMaxDiscountBipsUpper Maximum discount allowed for HOT quotes.
        @return maxOracleDeviationBound Maximum allowed deviation between AMM and oracle price.
        @return minAMMFeeGrowthE6 Minimum AMM fee growth rate.
        @return maxAMMFeeGrowthE6 Maximum AMM fee growth rate.
        @return minAMMFee Minimum AMM fee.
     */
    function immutables()
        external
        view
        returns (
            address pool,
            address liquidityProvider,
            uint32 maxDelay,
            uint16 hotMaxDiscountBipsLower,
            uint16 hotMaxDiscountBipsUpper,
            uint16 maxOracleDeviationBound,
            uint16 minAMMFeeGrowthE6,
            uint16 maxAMMFeeGrowthE6,
            uint16 minAMMFee
        )
    {
        return (
            _pool,
            _liquidityProvider,
            _maxDelay,
            _hotMaxDiscountBipsLower,
            _hotMaxDiscountBipsUpper,
            _maxOracleDeviationBound,
            _minAMMFeeGrowthE6,
            _maxAMMFeeGrowthE6,
            _minAMMFee
        );
    }

    /**
        @notice Returns active AMM liquidity (which gets utilized during AMM swaps).
     */
    function effectiveAMMLiquidity() external view poolNonReentrant returns (uint128) {
        return _effectiveAMMLiquidity;
    }

    /**
        @notice Returns square-root spot price, lower and upper bounds of the AMM position. 
     */
    function getAMMState()
        external
        view
        poolNonReentrant
        returns (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96)
    {
        (sqrtSpotPriceX96, sqrtPriceLowX96, sqrtPriceHighX96) = _getAMMState();
    }

    /**
        @notice Returns the AMM reserves assuming some AMM spot price.
        @param sqrtSpotPriceX96New square-root price to query AMM reserves for, in Q96 format.
        @return reserve0 Reserves of token0 at `sqrtSpotPriceX96New`.
        @return reserve1 Reserves of token1 at `sqrtSpotPriceX96New`.
     */
    function getReservesAtPrice(uint160 sqrtSpotPriceX96New) external view poolNonReentrant returns (uint256, uint256) {
        uint128 effectiveAMMLiquidityCache = _effectiveAMMLiquidity;

        uint128 calculatedLiquidity = _calculateAMMLiquidity();

        if (calculatedLiquidity < effectiveAMMLiquidityCache) {
            effectiveAMMLiquidityCache = calculatedLiquidity;
        }

        return ReserveMath.getReservesAtPrice(_ammState, _pool, effectiveAMMLiquidityCache, sqrtSpotPriceX96New);
    }

    /**
        @notice Returns the maximum token volumes allowed to be swapped in a single HOT quote.
        @return maxToken0VolumeToQuote Maximum token0 volume.
        @return maxToken1VolumeToQuote Maximum token1 volume.
     */
    function maxTokenVolumes() external view override returns (uint256, uint256) {
        return (_maxToken0VolumeToQuote, _maxToken1VolumeToQuote);
    }

    /************************************************
     *  SETTER FUNCTIONS
     ***********************************************/

    /**
        @notice Changes the `manager` of this contract.
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
     */
    function setManager(address _manager) external onlyManager {
        manager = _manager;

        emit ManagerUpdate(_manager);
    }

    /**
        @notice Changes the signer of the pool.
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
     */
    function setSigner(address _signer) external onlyManager {
        hotReadSlot.signer = _signer;

        emit SignerUpdate(_signer);
    }

    /**
        @notice Propose the feeds for token{0,1}.
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
        @dev Feeds can only be set once, and both should have non-zero values.
     */
    function proposeFeeds(address _feedToken0, address _feedToken1) external onlyManager {
        if (proposedFeedToken0 != address(0) || proposedFeedToken1 != address(0)) {
            revert HOT__proposedFeeds_proposedFeedsAlreadySet();
        }

        proposedFeedToken0 = _feedToken0;
        proposedFeedToken1 = _feedToken1;

        emit OracleFeedsProposed(_feedToken0, _feedToken1);
    }

    /**
        @notice Changes the maximum token volumes available for a single HOT quote.
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
     */
    function setMaxTokenVolumes(uint256 maxToken0VolumeToQuote, uint256 maxToken1VolumeToQuote) external onlyManager {
        _maxToken0VolumeToQuote = maxToken0VolumeToQuote;
        _maxToken1VolumeToQuote = maxToken1VolumeToQuote;

        emit MaxTokenVolumeSet(maxToken0VolumeToQuote, maxToken1VolumeToQuote);
    }

    /**
        @notice Changes the standard fee charged on all hot swaps.
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
     */
    function setHotFeeInBips(uint16 _hotFeeBipsToken0, uint16 _hotFeeBipsToken1) external onlyManager {
        if (
            _hotFeeBipsToken0 > HOTConstants.MAX_HOT_FEE_IN_BIPS || _hotFeeBipsToken1 > HOTConstants.MAX_HOT_FEE_IN_BIPS
        ) {
            revert HOT__setHotFeeInBips_invalidHotFee();
        }

        hotReadSlot.hotFeeBipsToken0 = _hotFeeBipsToken0;
        hotReadSlot.hotFeeBipsToken1 = _hotFeeBipsToken1;

        emit HotFeeSet(_hotFeeBipsToken0, _hotFeeBipsToken1);
    }

    /**
        @notice Updates the maximum number of HOT quotes allowed on a single block. 
        @dev Only callable by `manager`.
        @dev It assumes that `manager` implements a timelock when calling this function.
     */
    function setMaxAllowedQuotes(uint8 _maxAllowedQuotes) external onlyManager {
        if (_maxAllowedQuotes > HOTConstants.MAX_HOT_QUOTES_IN_BLOCK) {
            revert HOT__setMaxAllowedQuotes_invalidMaxAllowedQuotes();
        }

        hotReadSlot.maxAllowedQuotes = _maxAllowedQuotes;

        emit MaxAllowedQuoteSet(_maxAllowedQuotes);
    }

    /**
        @notice Sets the maximum allowed deviation between AMM and oracle price.
        @param _maxOracleDeviationBipsLower New maximum deviation in basis-points when sqrtSpotPrice < sqrtOraclePrice.
        @param _maxOracleDeviationBipsUpper New maximum deviation in basis-points when sqrtSpotPrice >= sqrtOraclePrice.
        @dev Only callable by `liquidityProvider`.
        @dev It assumes that `liquidityProvider` implements a timelock when calling this function.
     */
    function setMaxOracleDeviationBips(
        uint16 _maxOracleDeviationBipsLower,
        uint16 _maxOracleDeviationBipsUpper
    ) external onlyManager {
        if (
            _maxOracleDeviationBipsLower > _maxOracleDeviationBound ||
            _maxOracleDeviationBipsUpper > _maxOracleDeviationBound
        ) {
            revert HOT__setMaxOracleDeviationBips_exceedsMaxDeviationBounds();
        }

        hotReadSlot.maxOracleDeviationBipsLower = _maxOracleDeviationBipsLower;
        hotReadSlot.maxOracleDeviationBipsUpper = _maxOracleDeviationBipsUpper;

        emit MaxOracleDeviationBipsSet(_maxOracleDeviationBipsLower, _maxOracleDeviationBipsUpper);
    }

    /**
        @notice Updates the pause flag, which instantly pauses all critical functions except withdrawals.
        @dev Only callable by `manager`.
     */
    function setPause(bool _value) external onlyManager {
        hotReadSlot.isPaused = _value;

        emit PauseSet(_value);
    }

    /**
        @notice Sets the oracle feeds for token{0,1} to the proposed feeds set by manager.
        The oracle feeds should be set to 0, and the manager should have proposed valid non zero fields.
        @dev Only callable by `liquidityProvider`.
     */
    function setFeeds() external onlyLiquidityProvider {
        _setFeeds(proposedFeedToken0, proposedFeedToken1);

        emit OracleFeedsSet();
    }

    /**
        @notice Sets the AMM position's square-root upper and lower price bounds.
        @param _sqrtPriceLowX96 New square-root lower price bound.
        @param _sqrtPriceHighX96 New square-root upper price bound.
        @param _expectedSqrtSpotPriceLowerX96 Lower limit for expected spot price (inclusive).
        @param _expectedSqrtSpotPriceUpperX96 Upper limit for expected spot price (inclusive).
        @dev Can be used to utilize disproportionate token liquidity by tuning price bounds offchain.
        @dev Only callable by `liquidityProvider`.
        @dev It is recommended that `liquidityProvider` implements a timelock when calling this function.
        @dev It assumes that `liquidityProvider` implements sufficient internal protection against
             sandwich attacks, slippage checks or other types of spot price manipulation.
     */
    function setPriceBounds(
        uint160 _sqrtPriceLowX96,
        uint160 _sqrtPriceHighX96,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external poolNonReentrant onlyLiquidityProvider {
        // Allow `liquidityProvider` to cross-check sqrt spot price against expected bounds,
        // to protect against its manipulation
        uint160 sqrtSpotPriceX96Cache = _checkSpotPriceRange(
            _expectedSqrtSpotPriceLowerX96,
            _expectedSqrtSpotPriceUpperX96
        );

        HotReadSlot memory hotReadSlotCache = hotReadSlot;

        // It is sufficient to check only feedToken0, because either both of the feeds are set, or both are null.
        if (address(feedToken0) != address(0)) {
            // Feeds have been set, oracle deviation should be checked.
            // If feeds are not set, then HOT is in AMM-only mode, and oracle deviation check is not required.
            if (
                !HOTParams.checkPriceDeviation(
                    sqrtSpotPriceX96Cache,
                    getSqrtOraclePriceX96(),
                    hotReadSlotCache.maxOracleDeviationBipsLower,
                    hotReadSlotCache.maxOracleDeviationBipsUpper
                )
            ) {
                revert HOT__setPriceBounds_spotPriceAndOracleDeviation();
            }
        }

        // Check that new bounds are valid,
        // and do not exclude current spot price
        HOTParams.validatePriceBounds(sqrtSpotPriceX96Cache, _sqrtPriceLowX96, _sqrtPriceHighX96);

        // Update AMM sqrt spot price, sqrt price low and sqrt price high
        _ammState.setState(sqrtSpotPriceX96Cache, _sqrtPriceLowX96, _sqrtPriceHighX96);

        // Update AMM liquidity
        _updateAMMLiquidity(_calculateAMMLiquidity());

        emit PriceBoundSet(_sqrtPriceLowX96, _sqrtPriceHighX96);
    }

    /** 
        @notice Sets the AMM fee parameters directly.
        @param _feeMinToken0 Minimum fee for token0.
        @param _feeMaxToken0 Maximum fee for token0.
        @param _feeGrowthE6Token0 Fee growth rate for token0.
        @param _feeMinToken1 Minimum fee for token1.
        @param _feeMaxToken1 Maximum fee for token1.
        @param _feeGrowthE6Token1 Fee growth rate for token1.
        @dev Only callable by `liquidityProvider`. Can allow liquidity provider to override fees.
        @dev It is recommended that `liquidityProvider` implements a timelock when calling this function.
     */
    function setAMMFees(
        uint16 _feeMinToken0,
        uint16 _feeMaxToken0,
        uint16 _feeGrowthE6Token0,
        uint16 _feeMinToken1,
        uint16 _feeMaxToken1,
        uint16 _feeGrowthE6Token1
    ) public onlyUnpaused onlyLiquidityProvider {
        HOTParams.validateFeeParams(
            _feeMinToken0,
            _feeMaxToken0,
            _feeGrowthE6Token0,
            _feeMinToken1,
            _feeMaxToken1,
            _feeGrowthE6Token1,
            _minAMMFee,
            _minAMMFeeGrowthE6,
            _maxAMMFeeGrowthE6
        );

        HotWriteSlot memory hotWriteSlotCache = hotWriteSlot;

        hotWriteSlotCache.feeMinToken0 = _feeMinToken0;
        hotWriteSlotCache.feeMaxToken0 = _feeMaxToken0;
        hotWriteSlotCache.feeGrowthE6Token0 = _feeGrowthE6Token0;
        hotWriteSlotCache.feeMinToken1 = _feeMinToken1;
        hotWriteSlotCache.feeMaxToken1 = _feeMaxToken1;
        hotWriteSlotCache.feeGrowthE6Token1 = _feeGrowthE6Token1;

        hotWriteSlot = hotWriteSlotCache;

        emit AMMFeeSet(_feeMaxToken0, _feeMaxToken1);
    }

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Sovereign ALM function to be called on every swap.
        @param _almLiquidityQuoteInput Contains fundamental information about the swap and `pool`.
        @param _externalContext Bytes encoded calldata, containing required off-chain data. 
        @return liquidityQuote Returns a quote to authorize `pool` to execute the swap.
     */
    function getLiquidityQuote(
        ALMLiquidityQuoteInput memory _almLiquidityQuoteInput,
        bytes calldata _externalContext,
        bytes calldata /*_verifierData*/
    ) external override onlyPool onlyUnpaused returns (ALMLiquidityQuote memory liquidityQuote) {
        if (_externalContext.length == 0) {
            // AMM Swap
            _ammSwap(_almLiquidityQuoteInput, liquidityQuote);
        } else {
            // Hot Swap
            _hotSwap(_almLiquidityQuoteInput, _externalContext, liquidityQuote);

            // Hot swap needs a swap callback, to update AMM liquidity correctly
            liquidityQuote.isCallbackOnSwap = true;
        }

        if (liquidityQuote.amountOut == 0) {
            revert HOT__getLiquidityQuote_zeroAmountOut();
        }
    }

    /**
        @notice Sovereign ALM function to deposit reserves into `pool`.
        @param _amount0 Amount of token0 to deposit.
        @param _amount1 Amount of token1 to deposit.
        @param _expectedSqrtSpotPriceLowerX96 Minimum expected sqrt spot price, to mitigate against its manipulation.
        @param _expectedSqrtSpotPriceUpperX96 Maximum expected sqrt spot price, to mitigate against its manipulation.
        @return amount0Deposited Amount of token0 deposited (it can differ from `_amount0` in case of rebase tokens).
        @return amount1Deposited Amount of token1 deposited (it can differ from `_amount1` in case of rebase tokens).
        @dev Only callable by `liquidityProvider`.
        @dev It assumes that `liquidityProvider` implements sufficient internal protection against
             sandwich attacks or other types of spot price manipulation attacks. 
     */
    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external onlyLiquidityProvider onlyUnpaused returns (uint256 amount0Deposited, uint256 amount1Deposited) {
        // Allow `liquidityProvider` to cross-check sqrt spot price against expected bounds,
        // to protect against its manipulation
        uint160 sqrtSpotPriceX96Cache = _checkSpotPriceRange(
            _expectedSqrtSpotPriceLowerX96,
            _expectedSqrtSpotPriceUpperX96
        );

        // It is sufficient to check only feedToken0, because either both of the feeds are set, or both are null.
        if (address(feedToken0) != address(0)) {
            // Feeds have been set, oracle deviation should be checked.
            // If feeds are not set, then HOT is in AMM-only mode, and oracle deviation check is not required.
            if (
                !HOTParams.checkPriceDeviation(
                    sqrtSpotPriceX96Cache,
                    getSqrtOraclePriceX96(),
                    hotReadSlot.maxOracleDeviationBipsLower,
                    hotReadSlot.maxOracleDeviationBipsUpper
                )
            ) {
                revert HOT__depositLiquidity_spotPriceAndOracleDeviation();
            }
        }

        // Deposit amount(s) into pool
        (amount0Deposited, amount1Deposited) = ISovereignPool(_pool).depositLiquidity(
            _amount0,
            _amount1,
            _liquidityProvider,
            '',
            ''
        );

        // Update AMM liquidity with post-deposit reserves
        _updateAMMLiquidity(_calculateAMMLiquidity());
    }

    /**
        @notice Sovereign ALM function to withdraw reserves from `pool`.
        @param _amount0 Amount of token0 to withdraw.
        @param _amount1 Amount of token1 to withdraw.
        @param _recipient Address of recipient.
        @param _expectedSqrtSpotPriceLowerX96 Minimum expected sqrt spot price, to mitigate against its manipulation.
        @param _expectedSqrtSpotPriceUpperX96 Maximum expected sqrt spot price, to mitigate against its manipulation.
        @dev Only callable by `liquidityProvider`.
        @dev It assumes that `liquidityProvider` implements sufficient internal protection against
             sandwich attacks or other types of spot price manipulation attacks. 
     */
    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _recipient,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external onlyLiquidityProvider {
        // Allow `liquidityProvider` to cross-check sqrt spot price against expected bounds,
        // to protect against its manipulation
        uint160 sqrtSpotPriceX96Cache = _checkSpotPriceRange(
            _expectedSqrtSpotPriceLowerX96,
            _expectedSqrtSpotPriceUpperX96
        );

        uint128 preWithdrawalLiquidity = _effectiveAMMLiquidity;

        ISovereignPool(_pool).withdrawLiquidity(_amount0, _amount1, _liquidityProvider, _recipient, '');

        // Update AMM liquidity with post-withdrawal reserves
        uint128 postWithdrawalLiquidity = _calculateAMMLiquidity();

        // Liquidity can never increase after a withdrawal, even if some passive reserves are added.
        if (postWithdrawalLiquidity < preWithdrawalLiquidity) {
            _updateAMMLiquidity(postWithdrawalLiquidity);
        } else {
            emit PostWithdrawalLiquidityCapped(sqrtSpotPriceX96Cache, preWithdrawalLiquidity, postWithdrawalLiquidity);
        }
    }

    /**
        @notice Swap Fee Module function to calculate swap fee multiplier, in basis-points (see docs).
        @param _tokenIn Address of token to swap from.
        @param _swapFeeModuleContext Bytes encoded calldata. Only needs to be non-empty for HOT swaps.
        @return swapFeeModuleData Struct containing `feeInBips` as the resulting swap fee.
     */
    function getSwapFeeInBips(
        address _tokenIn,
        address,
        uint256,
        address,
        bytes memory _swapFeeModuleContext
    ) external view returns (SwapFeeModuleData memory swapFeeModuleData) {
        bool isZeroToOne = (_token0 == _tokenIn);

        // Verification of branches is done during `getLiquidityQuote`
        if (_swapFeeModuleContext.length != 0) {
            // Hot Branch
            swapFeeModuleData.feeInBips = isZeroToOne ? hotReadSlot.hotFeeBipsToken0 : hotReadSlot.hotFeeBipsToken1;
        } else {
            // AMM Branch
            swapFeeModuleData.feeInBips = _getAMMFeeInBips(isZeroToOne);
        }
    }

    /**
        @notice Sovereign Pool callback on `depositLiquidity`.
        @dev This callback is used to transfer funds from `liquidityProvider` to `pool`.
        @dev Only callable by `pool`. 
     */
    function onDepositLiquidityCallback(
        uint256 _amount0,
        uint256 _amount1,
        bytes memory /*_data*/
    ) external override onlyPool {
        if (_amount0 > 0) {
            // Transfer token0 amount from `liquidityProvider` to `pool`
            address token0 = ISovereignPool(_pool).token0();
            IERC20(token0).safeTransferFrom(_liquidityProvider, msg.sender, _amount0);
        }

        if (_amount1 > 0) {
            // Transfer token1 amount from `_liquidityProvider` to `pool`
            address token1 = ISovereignPool(_pool).token1();
            IERC20(token1).safeTransferFrom(_liquidityProvider, msg.sender, _amount1);
        }
    }

    /**
        @notice Sovereign Pool callback on `swap`.
        @dev This is called at the end of each swap, to allow HOT to perform
             relevant state updates.
        @dev Only callable by `pool`.
     */
    function onSwapCallback(
        bool /*_isZeroToOne*/,
        uint256 /*_amountIn*/,
        uint256 /*_amountOut*/
    ) external override onlyPool {
        // Update AMM liquidity at the end of the swap
        _updateAMMLiquidity(_calculateAMMLiquidity());
    }

    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Helper function to calculate AMM dynamic swap fees.
     */
    function _getAMMFeeInBips(bool isZeroToOne) internal view returns (uint32 feeInBips) {
        HotWriteSlot memory hotWriteSlotCache = hotWriteSlot;

        // Determine min, max and growth rate (in pips per second),
        // depending on the requested input token
        uint16 feeMin = isZeroToOne ? hotWriteSlotCache.feeMinToken0 : hotWriteSlotCache.feeMinToken1;
        uint16 feeMax = isZeroToOne ? hotWriteSlotCache.feeMaxToken0 : hotWriteSlotCache.feeMaxToken1;
        uint16 feeGrowthE6 = isZeroToOne ? hotWriteSlotCache.feeGrowthE6Token0 : hotWriteSlotCache.feeGrowthE6Token1;

        // Calculate dynamic fee, linearly increasing over time
        uint256 feeInBipsTemp = uint256(feeMin) +
            Math.mulDiv(feeGrowthE6, (block.timestamp - hotWriteSlotCache.lastProcessedSignatureTimestamp), 100);

        // Cap fee to maximum value, if necessary
        if (feeInBipsTemp > feeMax) {
            feeInBipsTemp = feeMax;
        }

        feeInBips = uint32(feeInBipsTemp);
    }

    /**
        @notice Helper function to execute AMM swap. 
     */
    function _ammSwap(
        ALMLiquidityQuoteInput memory almLiquidityQuoteInput,
        ALMLiquidityQuote memory liquidityQuote
    ) internal {
        uint128 newLiquidity = _calculateAMMLiquidity();

        if (newLiquidity < _effectiveAMMLiquidity) {
            _updateAMMLiquidity(newLiquidity);
        }

        // Check that the fee path was chosen correctly
        if (almLiquidityQuoteInput.feeInBips != _getAMMFeeInBips(almLiquidityQuoteInput.isZeroToOne)) {
            revert HOT__getLiquidityQuote_invalidFeePath();
        }

        // Cache sqrt spot price, lower bound, and upper bound
        (uint160 sqrtSpotPriceX96Cache, uint160 sqrtPriceLowX96Cache, uint160 sqrtPriceHighX96Cache) = _getAMMState();

        // Calculate amountOut according to CPMM math
        uint160 sqrtSpotPriceX96New;
        (sqrtSpotPriceX96New, liquidityQuote.amountInFilled, liquidityQuote.amountOut, ) = SwapMath.computeSwapStep(
            sqrtSpotPriceX96Cache,
            almLiquidityQuoteInput.isZeroToOne ? sqrtPriceLowX96Cache : sqrtPriceHighX96Cache,
            _effectiveAMMLiquidity,
            almLiquidityQuoteInput.amountInMinusFee.toInt256(), // always exact input swap
            0 // fees have already been deducted
        );

        // New spot price cannot be at the edge of the price range, otherwise LiquidityAmounts library reverts.
        if (sqrtSpotPriceX96New == sqrtPriceLowX96Cache || sqrtSpotPriceX96New == sqrtPriceHighX96Cache) {
            revert HOT___ammSwap_invalidSpotPriceAfterSwap();
        }

        // Update AMM sqrt spot price
        _ammState.setSqrtSpotPriceX96(sqrtSpotPriceX96New);
    }

    /**
        @notice Helper function to execute HOT swap. 
     */
    function _hotSwap(
        ALMLiquidityQuoteInput memory almLiquidityQuoteInput,
        bytes memory externalContext,
        ALMLiquidityQuote memory liquidityQuote
    ) internal {
        (HybridOrderType memory hot, bytes memory signature) = abi.decode(externalContext, (HybridOrderType, bytes));

        // Execute HOT swap
        HotWriteSlot memory hotWriteSlotCache = hotWriteSlot;
        HotReadSlot memory hotReadSlotCache = hotReadSlot;

        // Check that the fee path was chosen correctly
        if (
            almLiquidityQuoteInput.feeInBips !=
            (almLiquidityQuoteInput.isZeroToOne ? hotReadSlotCache.hotFeeBipsToken0 : hotReadSlotCache.hotFeeBipsToken1)
        ) {
            revert HOT__getLiquidityQuote_invalidFeePath();
        }

        uint32 blockTimestamp = block.timestamp.toUint32();

        // An HOT only updates state if:
        // 1. It is the first HOT that updates state in the block.
        // 2. It was signed after the last processed signature timestamp.
        bool isDiscountedHot = blockTimestamp > hotWriteSlotCache.lastStateUpdateTimestamp &&
            hotWriteSlotCache.lastProcessedSignatureTimestamp < hot.signatureTimestamp;

        // Ensure that the number of HOT swaps per block does not exceed its maximum bound
        uint8 quotesInCurrentBlock = blockTimestamp > hotWriteSlotCache.lastProcessedQuoteTimestamp
            ? 1
            : hotWriteSlotCache.lastProcessedBlockQuoteCount + 1;

        if (quotesInCurrentBlock > hotReadSlotCache.maxAllowedQuotes) {
            revert HOT___hotSwap_maxHotQuotesExceeded();
        }

        // Pick the discounted or base price, depending on eligibility criteria set above
        // No need to check one against the other at this stage
        uint160 sqrtHotPriceX96 = isDiscountedHot ? hot.sqrtHotPriceX96Discounted : hot.sqrtHotPriceX96Base;

        // Calculate the amountOut according to the quoted price
        liquidityQuote.amountOut = almLiquidityQuoteInput.isZeroToOne
            ? (
                Math.mulDiv(
                    almLiquidityQuoteInput.amountInMinusFee * sqrtHotPriceX96,
                    sqrtHotPriceX96,
                    HOTConstants.Q192
                )
            )
            : (Math.mulDiv(almLiquidityQuoteInput.amountInMinusFee, HOTConstants.Q192, sqrtHotPriceX96) /
                sqrtHotPriceX96);

        // Fill tokenIn amount requested, excluding fees
        liquidityQuote.amountInFilled = almLiquidityQuoteInput.amountInMinusFee;

        // Check validity of new AMM dynamic fee parameters
        HOTParams.validateFeeParams(
            hot.feeMinToken0,
            hot.feeMaxToken0,
            hot.feeGrowthE6Token0,
            hot.feeMinToken1,
            hot.feeMaxToken1,
            hot.feeGrowthE6Token1,
            _minAMMFee,
            _minAMMFeeGrowthE6,
            _maxAMMFeeGrowthE6
        );

        hot.validateBasicParams(
            almLiquidityQuoteInput,
            liquidityQuote.amountOut,
            almLiquidityQuoteInput.isZeroToOne ? _maxToken1VolumeToQuote : _maxToken0VolumeToQuote,
            _maxDelay,
            hotWriteSlotCache.alternatingNonceBitmap
        );

        HOTParams.validatePriceConsistency(
            _ammState,
            sqrtHotPriceX96,
            hot.sqrtSpotPriceX96New,
            getSqrtOraclePriceX96(),
            hotReadSlot.maxOracleDeviationBipsLower,
            hotReadSlot.maxOracleDeviationBipsUpper,
            _hotMaxDiscountBipsLower,
            _hotMaxDiscountBipsUpper
        );

        // Verify HOT quote signature
        bytes32 hotHash = hot.hashParams();
        if (!hotReadSlotCache.signer.isValidSignatureNow(_hashTypedDataV4(hotHash), signature)) {
            revert HOT___hotSwap_invalidSignature();
        }

        // Only update the pool state, if this is a discounted hot quote
        if (isDiscountedHot) {
            // Update `hotWriteSlot`

            hotWriteSlotCache.feeGrowthE6Token0 = hot.feeGrowthE6Token0;
            hotWriteSlotCache.feeMaxToken0 = hot.feeMaxToken0;
            hotWriteSlotCache.feeMinToken0 = hot.feeMinToken0;
            hotWriteSlotCache.feeGrowthE6Token1 = hot.feeGrowthE6Token1;
            hotWriteSlotCache.feeMaxToken1 = hot.feeMaxToken1;
            hotWriteSlotCache.feeMinToken1 = hot.feeMinToken1;

            hotWriteSlotCache.lastProcessedSignatureTimestamp = hot.signatureTimestamp;
            hotWriteSlotCache.lastStateUpdateTimestamp = blockTimestamp;

            // Update AMM sqrt spot price
            _ammState.setSqrtSpotPriceX96(hot.sqrtSpotPriceX96New);
        }

        hotWriteSlotCache.lastProcessedBlockQuoteCount = quotesInCurrentBlock;
        hotWriteSlotCache.lastProcessedQuoteTimestamp = blockTimestamp;
        hotWriteSlotCache.alternatingNonceBitmap = hotWriteSlotCache.alternatingNonceBitmap.flipNonce(hot.nonce);

        // Update `hotWriteSlot`
        hotWriteSlot = hotWriteSlotCache;

        emit HotSwap(hotHash);
    }

    /************************************************
     *  PRIVATE FUNCTIONS
     ***********************************************/

    /**
        @notice Helper function to calculate AMM's effective liquidity. 
     */
    function _calculateAMMLiquidity() private view returns (uint128 updatedLiquidity) {
        (uint160 sqrtSpotPriceX96Cache, uint160 sqrtPriceLowX96Cache, uint160 sqrtPriceHighX96Cache) = _getAMMState();

        // Query current pool reserves
        (uint256 reserve0, uint256 reserve1) = ISovereignPool(_pool).getReserves();

        // Calculate liquidity corresponding to each of token's reserves and respective price ranges
        uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
            sqrtSpotPriceX96Cache,
            sqrtPriceHighX96Cache,
            reserve0
        );
        uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
            sqrtPriceLowX96Cache,
            sqrtSpotPriceX96Cache,
            reserve1
        );

        if (liquidity0 < liquidity1) {
            updatedLiquidity = liquidity0;
        } else {
            updatedLiquidity = liquidity1;
        }
    }

    /**
        @notice Helper function to update AMM's effective liquidity
     */
    function _updateAMMLiquidity(uint128 updatedLiquidity) internal {
        // Update effective AMM liquidity
        _effectiveAMMLiquidity = updatedLiquidity;
    }

    /**
        @notice Helper function to view AMM's prices
     */
    function _getAMMState()
        private
        view
        returns (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96)
    {
        (sqrtSpotPriceX96, sqrtPriceLowX96, sqrtPriceHighX96) = _ammState.getState();
    }

    /**
        @notice Checks that the current AMM spot price is within the expected range.
        @param _expectedSqrtSpotPriceLowerX96 Lower limit for expected spot price. ( inclusive )
        @param _expectedSqrtSpotPriceUpperX96 Upper limit for expected spot price. ( inclusive )
        @dev If both `_expectedSqrtSpotPriceLowerX96` and `_expectedSqrtSpotPriceUpperX96` are 0,
             then no check is performed.
      */
    function _checkSpotPriceRange(
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) private view returns (uint160 sqrtSpotPriceX96Cache) {
        sqrtSpotPriceX96Cache = _ammState.getSqrtSpotPriceX96();
        bool checkSqrtSpotPriceAbsDiff = _expectedSqrtSpotPriceUpperX96 != 0 || _expectedSqrtSpotPriceLowerX96 != 0;
        bool isZero = _expectedSqrtSpotPriceUpperX96 == 0 || _expectedSqrtSpotPriceLowerX96 == 0;

        if (checkSqrtSpotPriceAbsDiff && !isZero) {
            // Check that spot price has not been manipulated
            if (
                sqrtSpotPriceX96Cache > _expectedSqrtSpotPriceUpperX96 ||
                sqrtSpotPriceX96Cache < _expectedSqrtSpotPriceLowerX96
            ) {
                revert HOT___checkSpotPriceRange_invalidSqrtSpotPriceX96(sqrtSpotPriceX96Cache);
            }
        } else if (checkSqrtSpotPriceAbsDiff && isZero) {
            revert HOT___checkSpotPriceRange_invalidBounds();
        }
    }

    function _onlyPool() private view {
        if (msg.sender != _pool) {
            revert HOT__onlyPool();
        }
    }

    function _onlyManager() private view {
        if (msg.sender != manager) {
            revert HOT__onlyManager();
        }
    }

    function _onlyUnpaused() private view {
        if (hotReadSlot.isPaused) {
            revert HOT__onlyUnpaused();
        }
    }

    function _onlyLiquidityProvider() private view {
        if (msg.sender != _liquidityProvider) {
            revert HOT__onlyLiquidityProvider();
        }
    }

    function _poolNonReentrant() private view {
        if (ISovereignPool(_pool).isLocked()) {
            revert HOT__poolReentrant();
        }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ALMLiquidityQuoteInput, ALMLiquidityQuote } from '../structs/SovereignALMStructs.sol';

/**
    @title Sovereign ALM interface
    @notice All ALMs bound to a Sovereign Pool must implement it.
 */
interface ISovereignALM {
    /** 
        @notice Called by the Sovereign pool to request a liquidity quote from the ALM.
        @param _almLiquidityQuoteInput Contains fundamental data about the swap.
        @param _externalContext Data received by the pool from the user.
        @param _verifierData Verification data received by the pool from the verifier module
        @return almLiquidityQuote Liquidity quote containing tokenIn and tokenOut amounts filled.
    */
    function getLiquidityQuote(
        ALMLiquidityQuoteInput memory _almLiquidityQuoteInput,
        bytes calldata _externalContext,
        bytes calldata _verifierData
    ) external returns (ALMLiquidityQuote memory);

    /**
        @notice Callback function for `depositLiquidity` .
        @param _amount0 Amount of token0 being deposited.
        @param _amount1 Amount of token1 being deposited.
        @param _data Context data passed by the ALM, while calling `depositLiquidity`.
    */
    function onDepositLiquidityCallback(uint256 _amount0, uint256 _amount1, bytes memory _data) external;

    /**
        @notice Callback to ALM after swap into liquidity pool.
        @dev Only callable by pool.
        @param _isZeroToOne Direction of swap.
        @param _amountIn Amount of tokenIn in swap.
        @param _amountOut Amount of tokenOut in swap. 
     */
    function onSwapCallback(bool _isZeroToOne, uint256 _amountIn, uint256 _amountOut) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IValantisPool } from '../interfaces/IValantisPool.sol';
import { PoolLocks } from '../structs/ReentrancyGuardStructs.sol';
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from '../structs/SovereignPoolStructs.sol';

interface ISovereignPool is IValantisPool {
    event SwapFeeModuleSet(address swapFeeModule);
    event ALMSet(address alm);
    event GaugeSet(address gauge);
    event PoolManagerSet(address poolManager);
    event PoolManagerFeeSet(uint256 poolManagerFeeBips);
    event SovereignOracleSet(address sovereignOracle);
    event PoolManagerFeesClaimed(uint256 amount0, uint256 amount1);
    event DepositLiquidity(uint256 amount0, uint256 amount1);
    event WithdrawLiquidity(address indexed recipient, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, bool isZeroToOne, uint256 amountIn, uint256 fee, uint256 amountOut);

    function getTokens() external view returns (address[] memory tokens);

    function sovereignVault() external view returns (address);

    function protocolFactory() external view returns (address);

    function gauge() external view returns (address);

    function poolManager() external view returns (address);

    function sovereignOracleModule() external view returns (address);

    function swapFeeModule() external view returns (address);

    function verifierModule() external view returns (address);

    function isLocked() external view returns (bool);

    function isRebaseTokenPool() external view returns (bool);

    function poolManagerFeeBips() external view returns (uint256);

    function defaultSwapFeeBips() external view returns (uint256);

    function swapFeeModuleUpdateTimestamp() external view returns (uint256);

    function alm() external view returns (address);

    function getPoolManagerFees() external view returns (uint256 poolManagerFee0, uint256 poolManagerFee1);

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);

    function setPoolManager(address _manager) external;

    function setGauge(address _gauge) external;

    function setPoolManagerFeeBips(uint256 _poolManagerFeeBips) external;

    function setSovereignOracle(address sovereignOracle) external;

    function setSwapFeeModule(address _swapFeeModule) external;

    function setALM(address _alm) external;

    function swap(SovereignPoolSwapParams calldata _swapParams) external returns (uint256, uint256);

    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        bytes calldata _verificationContext,
        bytes calldata _depositData
    ) external returns (uint256 amount0Deposited, uint256 amount1Deposited);

    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _sender,
        address _recipient,
        bytes calldata _verificationContext
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    @notice Struct returned by the swapFeeModule during the getSwapFeeInBips call.
    * feeInBips: The swap fee in bips.
    * internalContext: Arbitrary bytes context data.
 */
struct SwapFeeModuleData {
    uint256 feeInBips;
    bytes internalContext;
}

interface ISwapFeeModuleMinimal {
    /**
        @notice Returns the swap fee in bips for both Universal & Sovereign Pools.
        @param _tokenIn The address of the token that the user wants to swap.
        @param _tokenOut The address of the token that the user wants to receive.
        @param _amountIn The amount of tokenIn being swapped.
        @param _user The address of the user.
        @param _swapFeeModuleContext Arbitrary bytes data which can be sent to the swap fee module.
        @return swapFeeModuleData A struct containing the swap fee in bips, and internal context data.
     */
    function getSwapFeeInBips(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _user,
        bytes memory _swapFeeModuleContext
    ) external returns (SwapFeeModuleData memory swapFeeModuleData);
}

interface ISwapFeeModule is ISwapFeeModuleMinimal {
    /**
        @notice Callback function called by the pool after the swap has finished. ( Universal Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _spotPriceTick The spot price tick after the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        int24 _spotPriceTick,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;

    /**
        @notice Callback function called by the pool after the swap has finished. ( Sovereign Pools )
        @param _effectiveFee The effective fee charged for the swap.
        @param _amountInUsed The amount of tokenIn used for the swap.
        @param _amountOut The amount of the tokenOut transferred to the user.
        @param _swapFeeModuleData The context data returned by getSwapFeeInBips.
     */
    function callbackOnSwapEnd(
        uint256 _effectiveFee,
        uint256 _amountInUsed,
        uint256 _amountOut,
        SwapFeeModuleData memory _swapFeeModuleData
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { LiquidityAmounts } from '../../lib/v3-periphery/contracts/libraries/LiquidityAmounts.sol';

import { ISovereignPool } from '../../lib/valantis-core/src/pools/interfaces/ISovereignPool.sol';

import { TightPack } from '../libraries/utils/TightPack.sol';
import { AMMState } from '../structs/HOTStructs.sol';

library ReserveMath {
    using TightPack for AMMState;

    /**
        @notice Returns the AMM reserves assuming some AMM spot price.
        @param sqrtSpotPriceX96New square-root price to query AMM reserves for, in Q96 format.
        @return reserve0 Reserves of token0 at `sqrtSpotPriceX96New`.
        @return reserve1 Reserves of token1 at `sqrtSpotPriceX96New`.
     */
    function getReservesAtPrice(
        AMMState storage _ammState,
        address _pool,
        uint128 _effectiveAMMLiquidity,
        uint160 sqrtSpotPriceX96New
    ) external view returns (uint256 reserve0, uint256 reserve1) {
        (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96) = _ammState.getState();

        (reserve0, reserve1) = ISovereignPool(_pool).getReserves();

        uint128 effectiveAMMLiquidityCache = _effectiveAMMLiquidity;

        (uint256 activeReserve0, uint256 activeReserve1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtSpotPriceX96,
            sqrtPriceLowX96,
            sqrtPriceHighX96,
            effectiveAMMLiquidityCache
        );

        uint256 passiveReserve0 = reserve0 - activeReserve0;
        uint256 passiveReserve1 = reserve1 - activeReserve1;

        (activeReserve0, activeReserve1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtSpotPriceX96New,
            sqrtPriceLowX96,
            sqrtPriceHighX96,
            effectiveAMMLiquidityCache
        );

        reserve0 = passiveReserve0 + activeReserve0;
        reserve1 = passiveReserve1 + activeReserve1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { Math } from '../../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/Math.sol';
import { ALMLiquidityQuoteInput } from '../../lib/valantis-core/src/ALM/interfaces/ISovereignALM.sol';

import { HybridOrderType, AMMState } from '../structs/HOTStructs.sol';
import { TightPack } from '../libraries/utils/TightPack.sol';
import { AlternatingNonceBitmap } from '../libraries/AlternatingNonceBitmap.sol';
import { HOTConstants } from '../libraries/HOTConstants.sol';

/**
    @notice Library for validating all parameters of a signed Hybrid Order Type (HOT) quote.
 */
library HOTParams {
    using TightPack for AMMState;
    using AlternatingNonceBitmap for uint56;

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error HOTParams__validateBasicParams_excessiveTokenInAmount();
    error HOTParams__validateBasicParams_excessiveTokenOutAmountRequested();
    error HOTParams__validateBasicParams_excessiveExpiryTime();
    error HOTParams__validateBasicParams_incorrectSwapDirection();
    error HOTParams__validateBasicParams_replayedQuote();
    error HOTParams__validateBasicParams_quoteExpired();
    error HOTParams__validateBasicParams_unauthorizedSender();
    error HOTParams__validateBasicParams_unauthorizedRecipient();
    error HOTParams__validateBasicParams_invalidSignatureTimestamp();
    error HOTParams__validateFeeParams_insufficientFee();
    error HOTParams__validateFeeParams_invalidfeeGrowthE6();
    error HOTParams__validateFeeParams_invalidFeeMax();
    error HOTParams__validateFeeParams_invalidFeeMin();
    error HOTParams__validatePriceBounds_invalidPriceBounds();
    error HOTParams__validatePriceBounds_newSpotPriceOutOfBounds();
    error HOTParams__validatePriceConsistency_newSpotAndOraclePricesExcessiveDeviation();
    error HOTParams__validatePriceConsistency_hotAndSpotPriceNewExcessiveDeviation();
    error HOTParams__validatePriceConsistency_spotAndOraclePricesExcessiveDeviation();

    /************************************************
     *  FUNCTIONS
     ***********************************************/

    function validateBasicParams(
        HybridOrderType memory hot,
        ALMLiquidityQuoteInput memory almLiquidityQuoteInput,
        uint256 amountOut,
        uint256 tokenOutMaxBound,
        uint32 maxDelay,
        uint56 alternatingNonceBitmap
    ) internal view {
        if (hot.isZeroToOne != almLiquidityQuoteInput.isZeroToOne)
            revert HOTParams__validateBasicParams_incorrectSwapDirection();

        if (hot.authorizedSender != almLiquidityQuoteInput.sender)
            revert HOTParams__validateBasicParams_unauthorizedSender();

        if (hot.authorizedRecipient != almLiquidityQuoteInput.recipient)
            revert HOTParams__validateBasicParams_unauthorizedRecipient();

        if (almLiquidityQuoteInput.amountInMinusFee > hot.amountInMax)
            revert HOTParams__validateBasicParams_excessiveTokenInAmount();

        if (hot.expiry > maxDelay) revert HOTParams__validateBasicParams_excessiveExpiryTime();

        if (hot.signatureTimestamp > block.timestamp) revert HOTParams__validateBasicParams_invalidSignatureTimestamp();

        // Also equivalent to: signatureTimestamp >= block.timestamp - maxDelay
        // So, block.timestamp - maxDelay <= signatureTimestamp <= block.timestamp
        if (block.timestamp > hot.signatureTimestamp + hot.expiry) revert HOTParams__validateBasicParams_quoteExpired();

        if (amountOut > tokenOutMaxBound) revert HOTParams__validateBasicParams_excessiveTokenOutAmountRequested();

        if (!alternatingNonceBitmap.checkNonce(hot.nonce, hot.expectedFlag)) {
            revert HOTParams__validateBasicParams_replayedQuote();
        }
    }

    function validateFeeParams(
        uint16 feeMinToken0,
        uint16 feeMaxToken0,
        uint16 feeGrowthE6Token0,
        uint16 feeMinToken1,
        uint16 feeMaxToken1,
        uint16 feeGrowthE6Token1,
        uint16 feeMinBound,
        uint16 feeGrowthE6MinBound,
        uint16 feeGrowthE6MaxBound
    ) internal pure {
        if (feeMinToken0 < feeMinBound || feeMinToken1 < feeMinBound)
            revert HOTParams__validateFeeParams_insufficientFee();

        if (
            feeGrowthE6Token0 < feeGrowthE6MinBound ||
            feeGrowthE6Token1 < feeGrowthE6MinBound ||
            feeGrowthE6Token0 > feeGrowthE6MaxBound ||
            feeGrowthE6Token1 > feeGrowthE6MaxBound
        ) {
            revert HOTParams__validateFeeParams_invalidfeeGrowthE6();
        }

        // feeMax should be strictly less than 50% of total amountIn.
        // Note: A fee of 10_000 bips represents that for X amountIn swapped, we will charge X fee.
        // So, if amountIn = A, and feeBips = 100%, then amountInMinusFee = A/2, and effectiveFee = A/2.
        if (feeMaxToken0 >= HOTConstants.BIPS || feeMaxToken1 >= HOTConstants.BIPS)
            revert HOTParams__validateFeeParams_invalidFeeMax();

        if (feeMinToken0 > feeMaxToken0 || feeMinToken1 > feeMaxToken1)
            revert HOTParams__validateFeeParams_invalidFeeMin();
    }

    function validatePriceConsistency(
        AMMState storage ammState,
        uint160 sqrtHotPriceX96,
        uint160 sqrtSpotPriceNewX96,
        uint160 sqrtOraclePriceX96,
        uint256 maxOracleDeviationBipsLower,
        uint256 maxOracleDeviationBipsUpper,
        uint256 hotMaxDiscountBipsLower,
        uint256 hotMaxDiscountBipsUpper
    ) internal view {
        // Cache sqrt spot price, lower bound, and upper bound
        (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96) = ammState.getState();

        // sqrt hot and new AMM spot price cannot differ beyond allowed bounds
        if (
            !checkPriceDeviation(sqrtHotPriceX96, sqrtSpotPriceNewX96, hotMaxDiscountBipsLower, hotMaxDiscountBipsUpper)
        ) {
            revert HOTParams__validatePriceConsistency_hotAndSpotPriceNewExcessiveDeviation();
        }

        // Current AMM sqrt spot price and oracle sqrt price cannot differ beyond allowed bounds
        if (
            !checkPriceDeviation(
                sqrtSpotPriceX96,
                sqrtOraclePriceX96,
                maxOracleDeviationBipsLower,
                maxOracleDeviationBipsUpper
            )
        ) {
            revert HOTParams__validatePriceConsistency_spotAndOraclePricesExcessiveDeviation();
        }

        // New AMM sqrt spot price (provided by HOT quote) and oracle sqrt price cannot differ
        // beyond allowed bounds
        if (
            !checkPriceDeviation(
                sqrtSpotPriceNewX96,
                sqrtOraclePriceX96,
                maxOracleDeviationBipsLower,
                maxOracleDeviationBipsUpper
            )
        ) {
            revert HOTParams__validatePriceConsistency_newSpotAndOraclePricesExcessiveDeviation();
        }

        validatePriceBounds(sqrtSpotPriceNewX96, sqrtPriceLowX96, sqrtPriceHighX96);
    }

    function validatePriceBounds(
        uint160 sqrtSpotPriceX96,
        uint160 sqrtPriceLowX96,
        uint160 sqrtPriceHighX96
    ) internal pure {
        // Check that lower bound is smaller than upper bound,
        // and price bounds are within the MAX and MIN sqrt prices
        if (
            sqrtPriceLowX96 >= sqrtPriceHighX96 ||
            sqrtPriceLowX96 < HOTConstants.MIN_SQRT_PRICE ||
            sqrtPriceHighX96 > HOTConstants.MAX_SQRT_PRICE
        ) {
            revert HOTParams__validatePriceBounds_invalidPriceBounds();
        }

        // sqrt spot price cannot exceed or equal lower/upper AMM position's bounds
        if (sqrtSpotPriceX96 <= sqrtPriceLowX96 || sqrtSpotPriceX96 >= sqrtPriceHighX96) {
            revert HOTParams__validatePriceBounds_newSpotPriceOutOfBounds();
        }
    }

    function checkPriceDeviation(
        uint256 sqrtPriceAX96,
        uint256 sqrtPriceBX96,
        uint256 maxDeviationInBipsLower,
        uint256 maxDeviationInBipsUpper
    ) internal pure returns (bool) {
        uint256 diff = sqrtPriceAX96 > sqrtPriceBX96 ? sqrtPriceAX96 - sqrtPriceBX96 : sqrtPriceBX96 - sqrtPriceAX96;
        uint256 maxDeviationInBips = sqrtPriceAX96 < sqrtPriceBX96 ? maxDeviationInBipsLower : maxDeviationInBipsUpper;

        if (diff * HOTConstants.BIPS > maxDeviationInBips * sqrtPriceBX96) {
            return false;
        }
        return true;
    }

    function hashParams(HybridOrderType memory hot) internal pure returns (bytes32) {
        return keccak256(abi.encode(HOTConstants.HOT_TYPEHASH, hot));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { AMMState } from '../../structs/HOTStructs.sol';

/**
    @notice Helper library for tight packing multiple uint160 values into minimum amount of uint256 slots.
 */
library TightPack {
    uint256 constant LOWER_160_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 constant UPPER_96_MASK = 0xffffffffffffffffffffffff0000000000000000000000000000000000000000;

    /************************************************
     *  FUNCTIONS
     ***********************************************/

    /**
        @notice Packs 3 uint160 values into 2 uint256 slots.
        @param a uint160 value to pack into slot1.
        @param b uint160 value to pack into slot1 and slot2.
        @param c uint160 value to pack into slot2.
        @dev slot1: << 32 free bits | upper 64 bits of b | all 160 bits of a >>
             slot2: << lower 96 bits of b | all 160 bits of c >>
     */
    function setState(AMMState storage state, uint160 a, uint160 b, uint160 c) internal {
        uint256 slot1;
        uint256 slot2;
        assembly {
            slot1 := or(shl(160, shr(96, b)), a)
            slot2 := or(shl(160, b), c)
        }

        state.slot1 = slot1;
        state.slot2 = slot2;
    }

    /**
        @notice Unpacks 2 uint256 slots into 3 uint160 values.
        @param state AMMState struct containing slot1 and slot2.
        @return a uint160 value unpacked from slot1.
        @return b uint160 value unpacked from slot1 and slot2.
        @return c uint160 value unpacked from slot2.
        @dev slot1: << 32 empty bits | upper 64 bits of b | all 160 bits of a >>
             slot2: << lower 96 bits of b | all 160 bits of c >>
     */
    function getState(AMMState storage state) internal view returns (uint160 a, uint160 b, uint160 c) {
        uint256 slot1 = state.slot1;
        uint256 slot2 = state.slot2;

        assembly {
            a := and(slot1, LOWER_160_MASK)
            c := and(slot2, LOWER_160_MASK)
            b := or(shl(96, shr(160, slot1)), shr(160, slot2))
        }
    }

    function getSqrtSpotPriceX96(AMMState storage state) internal view returns (uint160 a) {
        uint256 slot1 = state.slot1;
        assembly {
            a := and(slot1, LOWER_160_MASK)
        }
    }

    function setSqrtSpotPriceX96(AMMState storage state, uint160 a) internal {
        uint256 slot1 = state.slot1;
        assembly {
            slot1 := or(and(slot1, UPPER_96_MASK), a)
        }
        state.slot1 = slot1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { SafeCast } from '../../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

/**
    @notice Helper library for creating an alternate nonce mechanism.
        * Each nonce is represented by a single bit in a 56-bit bitmap.
        * The user can check if the nonce is consumed or not using the expectedFlag parameter.
        If current nonce state == expectedFlag, then the nonce is not consumed, otherwise this is a replay.
    
    @dev The entity signing the nonce has to keep a track of the state of the bitmap, 
        if the expected flag is set incorrectly, then replay is possible.
        
    @dev It is the responsibility of the caller to ensure they use checkNonce and flipNonce correctly.
 */
library AlternatingNonceBitmap {
    using SafeCast for uint256;

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error AlternatingNonceBitmap__checkNonce_nonceOutOfBounds();
    error AlternatingNonceBitmap__checkNonce_expectedFlagInvalid();
    error AlternatingNonceBitmap__flipNonce_nonceOutOfBounds();

    /************************************************
     *  FUNCTIONS
     ***********************************************/

    /**
        @notice Checks if the nonce is consumed or not.
        @param bitmap 56-bit bitmap representing the state of the nonces.
        @param nonce Nonce to check.
        @param expectedFlag Expected flag for the nonce.
        @return True if the nonce is in expected state, otherwise false.
     */
    function checkNonce(uint56 bitmap, uint8 nonce, uint8 expectedFlag) internal pure returns (bool) {
        if (nonce >= 56) revert AlternatingNonceBitmap__checkNonce_nonceOutOfBounds();
        if (expectedFlag > 1) revert AlternatingNonceBitmap__checkNonce_expectedFlagInvalid();

        return ((bitmap & (1 << nonce)) >> nonce) == expectedFlag;
    }

    /**
        @notice Flips the state of the nonce.
        @param bitmap 56-bit bitmap representing the state of the nonces.
        @param nonce Nonce to flip.
        @return New bitmap with the nonce state flipped.
     */
    function flipNonce(uint56 bitmap, uint8 nonce) internal pure returns (uint56) {
        if (nonce >= 56) revert AlternatingNonceBitmap__flipNonce_nonceOutOfBounds();

        return (bitmap ^ (1 << nonce)).toUint56();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
    @notice Stores all constants used in the family of HOT Contracts.
 */
library HOTConstants {
    /**
        @notice Maximum allowed hot fee, in basis-points.
      */
    uint16 internal constant MAX_HOT_FEE_IN_BIPS = 100;

    /**
        @notice Min and max sqrt price bounds.
        @dev Same bounds as in https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol.
     */
    uint160 internal constant MIN_SQRT_PRICE = 4295128739;
    uint160 internal constant MAX_SQRT_PRICE = 1461446703485210103287273052203988822378723970342;

    /**
        @notice The typehash for the HybridOrderType struct for EIP-712 signatures.
     */
    bytes32 internal constant HOT_TYPEHASH =
        keccak256(
            // solhint-disable-next-line max-line-length
            'HybridOrderType(uint256 amountInMax,uint160 sqrtHotPriceX96Discounted,uint160 sqrtHotPriceX96Base,uint160 sqrtSpotPriceX96New,address authorizedSender,address authorizedRecipient,uint32 signatureTimestamp,uint32 expiry,uint16 feeMinToken0,uint16 feeMaxToken0,uint16 feeGrowthE6Token0,uint16 feeMinToken1,uint16 feeMaxToken1,uint16 feeGrowthE6Token1,uint8 nonce,uint8 expectedFlag,bool isZeroToOne)'
        );

    /**
        @notice The constant value 2**96
     */
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    /**
        @notice The constant value 2**192
     */
    uint256 internal constant Q192 = 0x1000000000000000000000000000000000000000000000000;

    /**
        @notice The constant value 10_000
     */
    uint256 internal constant BIPS = 10_000;

    /**
        @notice The constant value 1_000_000
     */
    uint256 internal constant E6 = 1_000_000;

    /**
        @notice The maximum number of HOT quotes that can be processed in a single block.
     */
    uint256 internal constant MAX_HOT_QUOTES_IN_BLOCK = 56;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/**
    @notice The struct with all the information for a HOT swap. 

    This struct is signed by `signer`, and put onchain via HOT swaps.

    * amountInMax: Maximum amount of input token which `authorizedSender` is allowed to swap.
    * sqrtHotPriceX96Discounted: sqrtPriceX96 to quote if the HOT is eligible to update AMM state (see HOT).
    * sqrtHotPriceX96Base: sqrtPriceX96 to quote if the HOT isn't eligible to update AMM (can be same as above).
    * sqrtSpotPriceX96New: New sqrt spot price of the AMM, in Q96 format.
    * authorizedSender: Address of authorized msg.sender in `pool`.
    * authorizedRecipient: Address of authorized recipient of tokenOut amounts.
    * signatureTimestamp: Offchain UNIX timestamp that determines when this HOT intent has been signed.
    * expiry: Duration, in seconds, for the validity of this HOT intent.
    * feeMinToken0: Minimum AMM swap fee for token0.
    * feeMaxToken0: Maximum AMM swap fee for token0.
    * feeGrowthE6Token0: Fee growth in pips, per second, of AMM swap fee for token0.
    * feeMinToken1: Minimum AMM swap fee for token1.
    * feeMaxToken1: Maximum AMM swap fee for token1.
    * feeGrowthE6Token1: Fee growth in pips, per second, of AMM swap fee for token1.
    * nonce: Nonce in bitmap format (see AlternatingNonceBitmap library and docs).
    * expectedFlag: Expected flag (0 or 1) for nonce (see AlternatingNonceBitmap library and docs).
    * isZeroToOne: Direction of the swap for which the HOT is valid.
 */
struct HybridOrderType {
    uint256 amountInMax;
    uint160 sqrtHotPriceX96Discounted;
    uint160 sqrtHotPriceX96Base;
    uint160 sqrtSpotPriceX96New;
    address authorizedSender;
    address authorizedRecipient;
    uint32 signatureTimestamp;
    uint32 expiry;
    uint16 feeMinToken0;
    uint16 feeMaxToken0;
    uint16 feeGrowthE6Token0;
    uint16 feeMinToken1;
    uint16 feeMaxToken1;
    uint16 feeGrowthE6Token1;
    uint8 nonce;
    uint8 expectedFlag;
    bool isZeroToOne;
}

/**
    @notice Packed struct containing state variables which get updated on HOT swaps.

    * lastProcessedBlockQuoteCount: Number of HOT swaps processed in the last block.
    * feeGrowthE6Token0: Fee growth in pips, per second, of AMM swap fee for token0.
    * feeMaxToken0: Maximum AMM swap fee for token0.
    * feeMinToken0: Minimum AMM swap fee for token0.
    * feeGrowthE6Token1: Fee growth in pips, per second, of AMM swap fee for token1.
    * feeMaxToken1: Maximum AMM swap fee for token1.
    * feeMinToken1: Minimum AMM swap fee for token1.
    * lastStateUpdateTimestamp: Block timestamp of the last AMM state update from an HOT swap.
    * lastProcessedQuoteTimestamp: Block timestamp of the last processed HOT swap (not all HOT swaps update AMM state).
    * lastProcessedSignatureTimestamp: Signature timestamp of the last HOT swap which has been successfully processed.
    * alternatingNonceBitmap: Nonce bitmap (see AlternatingNonceBitmap library and docs).
 */
struct HotWriteSlot {
    uint8 lastProcessedBlockQuoteCount;
    uint16 feeGrowthE6Token0;
    uint16 feeMaxToken0;
    uint16 feeMinToken0;
    uint16 feeGrowthE6Token1;
    uint16 feeMaxToken1;
    uint16 feeMinToken1;
    uint32 lastStateUpdateTimestamp;
    uint32 lastProcessedQuoteTimestamp;
    uint32 lastProcessedSignatureTimestamp;
    uint56 alternatingNonceBitmap;
}

/**
    @notice Contains read-only variables required during execution of an HOT swap.
    * isPaused: Indicates whether the contract is paused or not.     
    * maxAllowedQuotes: Maximum number of quotes that can be processed in a single block.
    * maxOracleDeviationBipsLower: Maximum deviation in bips allowed when, sqrtSpotPrice < sqrtOraclePrice
    * maxOracleDeviationBipsUpper: Maximum deviation in bips allowed when, sqrtSpotPrice >= sqrtOraclePrice
    * hotFeeBipsToken0: Fee in basis points for all subsequent hot for token0.
    * hotFeeBipsToken1: Fee in basis points for all subsequent hot for token1.
    * signer: Address of the signer of the HOT.
 */
struct HotReadSlot {
    bool isPaused;
    uint8 maxAllowedQuotes;
    uint16 maxOracleDeviationBipsLower;
    uint16 maxOracleDeviationBipsUpper;
    uint16 hotFeeBipsToken0;
    uint16 hotFeeBipsToken1;
    address signer;
}

/**
    @notice Contains all the arguments passed to the constructor of the HOT.
 */
struct HOTConstructorArgs {
    address pool;
    address manager;
    address signer;
    address liquidityProvider;
    address feedToken0;
    address feedToken1;
    uint160 sqrtSpotPriceX96;
    uint160 sqrtPriceLowX96;
    uint160 sqrtPriceHighX96;
    uint32 maxDelay;
    uint32 maxOracleUpdateDurationFeed0;
    uint32 maxOracleUpdateDurationFeed1;
    uint16 hotMaxDiscountBipsLower;
    uint16 hotMaxDiscountBipsUpper;
    uint16 maxOracleDeviationBound;
    uint16 minAMMFeeGrowthE6;
    uint16 maxAMMFeeGrowthE6;
    uint16 minAMMFee;
}

/**
    @notice Packed struct that contains all variables relevant to the state of the AMM.
    
    * a: sqrtSpotPriceX96
    * b: sqrtPriceLowX96
    * c: sqrtPriceHighX96
        
    This arrangement saves 1 storage slot by packing the variables at the bit level.
    
    @dev Should never be used directly without the help of the TightPack library.

    @dev slot1: << 32 free bits | upper 64 bits of b | all 160 bits of a >>
         slot2: << lower 96 bits of b | all 160 bits of c >>
 */
struct AMMState {
    uint256 slot1;
    uint256 slot2;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {
    IERC20Metadata
} from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { Math } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/Math.sol';
import { SafeCast } from '../lib/valantis-core/lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol';

import { AggregatorV3Interface } from './vendor/chainlink/AggregatorV3Interface.sol';
import { HOTParams } from './libraries/HOTParams.sol';
import { HOTConstants } from './libraries/HOTConstants.sol';

import { IHOTOracle } from './interfaces/IHOTOracle.sol';

contract HOTOracle is IHOTOracle {
    using SafeCast for int256;
    using SafeCast for uint256;

    /************************************************
     *  CUSTOM ERRORS
     ***********************************************/

    error HOTOracle___getOraclePriceUSD_stalePrice();
    error HOTOracle___getSqrtOraclePriceX96_sqrtOraclePriceOutOfBounds();
    error HOTOracle___setFeeds_feedsAlreadySet();
    error HOTOracle___setFeeds_newFeedsCannotBeZero();

    /************************************************
     *  IMMUTABLES
     ***********************************************/

    /**
	    @notice Address of token0 of the Sovereign Pool.
    */
    address internal immutable _token0;

    /**
	    @notice Address of token1 of the Sovereign Pool.
    */
    address internal immutable _token1;

    /**
	    @notice Base unit for token{0,1}.
          For example: _token0Base = 10 ** token0Decimals;
        @dev `token0` and `token1` must be the same as this module's Sovereign Pool.
     */
    uint256 private immutable _token0Base;
    uint256 private immutable _token1Base;

    /**
	    @notice Maximum allowed duration for each oracle update, in seconds.
        @dev Oracle prices are considered stale beyond this threshold,
             meaning that all swaps should revert.
     */
    uint32 public immutable override maxOracleUpdateDurationFeed0;
    uint32 public immutable override maxOracleUpdateDurationFeed1;

    /**
	    @notice Price feeds for token{0,1}, denominated in USD.
	    @dev These must be valid Chainlink Price Feeds.
     */
    AggregatorV3Interface public override feedToken0;
    AggregatorV3Interface public override feedToken1;

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor(
        address _token0Pool,
        address _token1Pool,
        address _feedToken0,
        address _feedToken1,
        uint32 _maxOracleUpdateDurationFeed0,
        uint32 _maxOracleUpdateDurationFeed1
    ) {
        _token0 = _token0Pool;
        _token1 = _token1Pool;

        _token0Base = 10 ** IERC20Metadata(_token0Pool).decimals();
        _token1Base = 10 ** IERC20Metadata(_token1Pool).decimals();

        maxOracleUpdateDurationFeed0 = _maxOracleUpdateDurationFeed0;
        maxOracleUpdateDurationFeed1 = _maxOracleUpdateDurationFeed1;

        // Feeds can be 0 during deployment, but once feeds are set, they cannot be changed.
        feedToken0 = AggregatorV3Interface(_feedToken0);
        feedToken1 = AggregatorV3Interface(_feedToken1);
    }

    /************************************************
     *  PUBLIC FUNCTIONS
     ***********************************************/

    /**
        @notice Calculates sqrt oracle price, in Q96 format, by querying both price feeds. 
     */
    function getSqrtOraclePriceX96() public view returns (uint160 sqrtOraclePriceX96) {
        uint256 oraclePrice0USD = _getOraclePriceUSD(feedToken0, maxOracleUpdateDurationFeed0);
        uint256 oraclePrice1USD = _getOraclePriceUSD(feedToken1, maxOracleUpdateDurationFeed1);

        sqrtOraclePriceX96 = _calculateSqrtOraclePriceX96(
            oraclePrice0USD,
            oraclePrice1USD,
            10 ** feedToken0.decimals(),
            10 ** feedToken1.decimals()
        );

        if (sqrtOraclePriceX96 < HOTConstants.MIN_SQRT_PRICE || sqrtOraclePriceX96 > HOTConstants.MAX_SQRT_PRICE) {
            revert HOTOracle___getSqrtOraclePriceX96_sqrtOraclePriceOutOfBounds();
        }
    }

    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Sets price feeds for token{0,1} to a non-zero value. Can only be called once.
        @param _feedToken0 Address of token0's price feed.
        @param _feedToken1 Address of token1's price feed.
        @dev This is a critical function and should only be called by trusted sources, with appropriate permissions.
     */
    function _setFeeds(address _feedToken0, address _feedToken1) internal {
        if (address(feedToken0) != address(0) || address(feedToken1) != address(0)) {
            revert HOTOracle___setFeeds_feedsAlreadySet();
        }

        if (_feedToken0 == address(0) || _feedToken1 == address(0)) {
            revert HOTOracle___setFeeds_newFeedsCannotBeZero();
        }

        feedToken0 = AggregatorV3Interface(_feedToken0);
        feedToken1 = AggregatorV3Interface(_feedToken1);
    }

    function _getOraclePriceUSD(
        AggregatorV3Interface feed,
        uint32 maxOracleUpdateDuration
    ) internal view returns (uint256 oraclePriceUSD) {
        (, int256 oraclePriceUSDInt, , uint256 updatedAt, ) = feed.latestRoundData();

        if (block.timestamp - updatedAt > maxOracleUpdateDuration) {
            revert HOTOracle___getOraclePriceUSD_stalePrice();
        }

        oraclePriceUSD = oraclePriceUSDInt.toUint256();
    }

    function _calculateSqrtOraclePriceX96(
        uint256 oraclePrice0USD,
        uint256 oraclePrice1USD,
        uint256 oracle0Base,
        uint256 oracle1Base
    ) internal view returns (uint160) {
        // Source: https://github.com/timeless-fi/bunni-oracle/blob/main/src/BunniOracle.sol

        // We are given two price feeds: token0 / USD and token1 / USD.
        // In order to compare token0 and token1 amounts, we need to convert
        // them both into USD:
        //
        // amount1USD = _token1Base / (oraclePrice1USD / oracle1Base)
        // amount0USD = _token0Base / (oraclePrice0USD / oracle0Base)
        //
        // Following HOT and sqrt spot price definition:
        //
        // sqrtOraclePriceX96 = sqrt(amount1USD / amount0USD) * 2 ** 96
        // solhint-disable-next-line max-line-length
        // = sqrt(oraclePrice0USD * _token1Base * oracle1Base) * 2 ** 96 / (oraclePrice1USD * _token0Base * oracle0Base)) * 2 ** 48

        uint256 oraclePriceX96 = Math.mulDiv(
            oraclePrice0USD * oracle1Base * _token1Base,
            HOTConstants.Q96,
            oraclePrice1USD * oracle0Base * _token0Base
        );
        return (Math.sqrt(oraclePriceX96) << 48).toUint160();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { IHOTOracle } from './IHOTOracle.sol';
import { AggregatorV3Interface } from '../vendor/chainlink/AggregatorV3Interface.sol';

import { SwapFeeModuleData } from '../../lib/valantis-core/src/swap-fee-modules/interfaces/ISwapFeeModule.sol';
import {
    ALMLiquidityQuote,
    ALMLiquidityQuoteInput
} from '../../lib/valantis-core/src/ALM/interfaces/ISovereignALM.sol';

interface IHOT is IHOTOracle {
    /************************************************
     *  EVENTS
     ***********************************************/

    event ALMDeployed(string indexed name, address alm, address pool);
    event AMMFeeSet(uint16 feeMaxToken0, uint16 feeMaxToken1);
    event OracleFeedsSet();
    event ManagerUpdate(address indexed manager);
    event MaxAllowedQuoteSet(uint8 maxQuotes);
    event MaxOracleDeviationBipsSet(uint16 maxOracleDeviationBipsLower, uint16 maxOracleDeviationBipsUpper);
    event MaxTokenVolumeSet(uint256 amount0, uint256 amount1);
    event OracleFeedsProposed(address feed0, address feed1);
    event PauseSet(bool pause);
    event PostWithdrawalLiquidityCapped(
        uint160 sqrtSpotPriceX96,
        uint128 preWithdrawalLiquidity,
        uint128 postWithdrawalLiquidity
    );
    event PriceBoundSet(uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96);
    event SignerUpdate(address indexed signer);
    event HotFeeSet(uint16 fee0Bips, uint16 fee1Bips);
    event HotSwap(bytes32 hotHash);

    /************************************************
     *  VIEW FUNCTIONS
     ***********************************************/
    function effectiveAMMLiquidity() external view returns (uint128);

    function getAMMState()
        external
        view
        returns (uint160 sqrtSpotPriceX96, uint160 sqrtPriceLowX96, uint160 sqrtPriceHighX96);

    function getReservesAtPrice(uint160 sqrtSpotPriceX96New) external view returns (uint256 reserve0, uint256 reserve1);

    function manager() external view returns (address);

    function maxTokenVolumes() external view returns (uint256, uint256);

    function proposedFeedToken0() external view returns (address);
    function proposedFeedToken1() external view returns (address);

    function hotReadSlot()
        external
        view
        returns (
            bool isPaused,
            uint8 maxAllowedQuotes,
            uint16 maxOracleDeviationBipsLower,
            uint16 maxOracleDeviationBipsUpper,
            uint16 solverFeeBipsToken0,
            uint16 solverFeeBipsToken1,
            address signer
        );

    function hotWriteSlot()
        external
        view
        returns (
            uint8 lastProcessedBlockQuoteCount,
            uint16 feeGrowthE6Token0,
            uint16 feeMaxToken0,
            uint16 feeMinToken0,
            uint16 feeGrowthE6Token1,
            uint16 feeMaxToken1,
            uint16 feeMinToken1,
            uint32 lastStateUpdateTimestamp,
            uint32 lastProcessedQuoteTimestamp,
            uint32 lastProcessedSignatureTimestamp,
            uint56 alternatingNonceBitmap
        );

    /************************************************
     *   FUNCTIONS
     ***********************************************/

    function proposeFeeds(address _feedToken0, address _feedToken1) external;

    function setFeeds() external;

    function setManager(address _manager) external;

    function setMaxAllowedQuotes(uint8 _maxAllowedQuotes) external;

    function setMaxOracleDeviationBips(
        uint16 _maxOracleDeviationBipsLower,
        uint16 _maxOracleDeviationBipsUpper
    ) external;

    function setMaxTokenVolumes(uint256 _maxToken0VolumeToQuote, uint256 _maxToken1VolumeToQuote) external;

    function setPause(bool _value) external;

    function setPriceBounds(
        uint160 _sqrtPriceLowX96,
        uint160 _sqrtPriceHighX96,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external;

    function setSigner(address _signer) external;

    function setHotFeeInBips(uint16 _hotFeeBipsToken0, uint16 _hotFeeBipsToken1) external;

    function depositLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external returns (uint256 amount0Deposited, uint256 amount1Deposited);

    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        address _recipient,
        uint160 _expectedSqrtSpotPriceLowerX96,
        uint160 _expectedSqrtSpotPriceUpperX96
    ) external;
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
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct ALMLiquidityQuoteInput {
    bool isZeroToOne;
    uint256 amountInMinusFee;
    uint256 feeInBips;
    address sender;
    address recipient;
    address tokenOutSwap;
}

struct ALMLiquidityQuote {
    bool isCallbackOnSwap;
    uint256 amountOut;
    uint256 amountInFilled;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IFlashBorrower } from './IFlashBorrower.sol';

interface IValantisPool {
    /************************************************
     *  EVENTS
     ***********************************************/

    event Flashloan(address indexed initiator, address indexed receiver, uint256 amount, address token);

    /************************************************
     *  ERRORS
     ***********************************************/

    error ValantisPool__flashloan_callbackFailed();
    error ValantisPool__flashLoan_flashLoanDisabled();
    error ValantisPool__flashLoan_flashLoanNotRepaid();
    error ValantisPool__flashLoan_rebaseTokenNotAllowed();

    /************************************************
     *  VIEW FUNCTIONS
     ***********************************************/

    /**
        @notice Address of ERC20 token0 of the pool.
     */
    function token0() external view returns (address);

    /**
        @notice Address of ERC20 token1 of the pool.
     */
    function token1() external view returns (address);

    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    /**
        @notice Claim share of protocol fees accrued by this pool.
        @dev Can only be claimed by `gauge` of the pool. 
     */
    function claimProtocolFees() external returns (uint256, uint256);

    /**
        @notice Claim share of fees accrued by this pool
                And optionally share some with the protocol.
        @dev Only callable by `poolManager`.
        @param _feeProtocol0Bips Percent of `token0` fees to be shared with protocol.
        @param _feeProtocol1Bips Percent of `token1` fees to be shared with protocol.
     */
    function claimPoolManagerFees(
        uint256 _feeProtocol0Bips,
        uint256 _feeProtocol1Bips
    ) external returns (uint256 feePoolManager0Received, uint256 feePoolManager1Received);

    /**
        @notice Sets the gauge contract address for the pool.
        @dev Only callable by `protocolFactory`.
        @dev Once a gauge is set it cannot be changed again.
        @param _gauge address of the gauge.
     */
    function setGauge(address _gauge) external;

    /**
        @notice Allows anyone to flash loan any amount of tokens from the pool.
        @param _isTokenZero True if token0 is being flash loaned, False otherwise.
        @param _receiver Address of the flash loan receiver.
        @param _amount Amount of tokens to be flash loaned.
        @param _data Bytes encoded data for flash loan callback.
     */
    function flashLoan(bool _isTokenZero, IFlashBorrower _receiver, uint256 _amount, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum Lock {
    WITHDRAWAL,
    DEPOSIT,
    SWAP,
    SPOT_PRICE_TICK
}

struct PoolLocks {
    /**
        @notice Locks all functions that require any withdrawal of funds from the pool
                This involves the following functions -
                * withdrawLiquidity
                * claimProtocolFees
                * claimPoolManagerFees
     */
    uint8 withdrawals;
    /**
        @notice Only locks the deposit function
    */
    uint8 deposit;
    /**
        @notice Only locks the swap function
    */
    uint8 swap;
    /**
        @notice Only locks the spotPriceTick function
    */
    uint8 spotPriceTick;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from '../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';

import { ISwapFeeModule } from '../../swap-fee-modules/interfaces/ISwapFeeModule.sol';

struct SovereignPoolConstructorArgs {
    address token0;
    address token1;
    address protocolFactory;
    address poolManager;
    address sovereignVault;
    address verifierModule;
    bool isToken0Rebase;
    bool isToken1Rebase;
    uint256 token0AbsErrorTolerance;
    uint256 token1AbsErrorTolerance;
    uint256 defaultSwapFeeBips;
}

struct SovereignPoolSwapContextData {
    bytes externalContext;
    bytes verifierContext;
    bytes swapCallbackContext;
    bytes swapFeeModuleContext;
}

struct SwapCache {
    ISwapFeeModule swapFeeModule;
    IERC20 tokenInPool;
    IERC20 tokenOutPool;
    uint256 amountInWithoutFee;
}

struct SovereignPoolSwapParams {
    bool isSwapCallback;
    bool isZeroToOne;
    uint256 amountIn;
    uint256 amountOutMin;
    uint256 deadline;
    address recipient;
    address swapTokenOut;
    SovereignPoolSwapContextData swapContext;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import { AggregatorV3Interface } from '../vendor/chainlink/AggregatorV3Interface.sol';

interface IHOTOracle {
    /**
	    @notice Price feeds for token{0,1}, denominated in USD.
	    @dev These must be valid Chainlink Price Feeds.
     */
    function feedToken0() external view returns (AggregatorV3Interface);
    function feedToken1() external view returns (AggregatorV3Interface);

    /**
	    @notice Maximum allowed duration for each oracle update, in seconds.
        @dev Oracle prices are considered stale beyond this threshold,
             meaning that all swaps should revert.
     */
    function maxOracleUpdateDurationFeed0() external view returns (uint32);
    function maxOracleUpdateDurationFeed1() external view returns (uint32);

    /**
        @notice Calculates sqrt oracle price, in Q96 format, by querying both price feeds. 
     */
    function getSqrtOraclePriceX96() external view returns (uint160 sqrtOraclePriceX96);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFlashBorrower {
    /**
        @dev Receive a flash loan.
        @param initiator The initiator of the loan.
        @param token The loan currency.
        @param amount The amount of tokens lent.
        @param data Arbitrary data structure, intended to contain user-defined parameters.
        @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}