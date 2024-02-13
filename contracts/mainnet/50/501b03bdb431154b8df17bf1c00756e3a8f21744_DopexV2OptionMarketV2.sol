// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import {IDopexV2PositionManager} from "./interfaces/IDopexV2PositionManager.sol";

import {IOptionPricingV2} from "./pricing/IOptionPricingV2.sol";
import {IHandler} from "./interfaces/IHandler.sol";
import {IDopexV2ClammFeeStrategyV2} from "./pricing/fees/IDopexV2ClammFeeStrategyV2.sol";
import {ISwapper} from "./interfaces/ISwapper.sol";
import {ITokenURIFetcher} from "./interfaces/ITokenURIFetcher.sol";

import {ERC721} from "./libraries/tokens/ERC721.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Multicall} from "openzeppelin-contracts/contracts/utils/Multicall.sol";

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {LiquidityAmounts} from "v3-periphery/libraries/LiquidityAmounts.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

/**
 * @title DopexV2OptionMarketV2
 * @author 0xcarrot
 * @dev Allow traders to buy CALL and PUT options using CLAMM liquidity, which can be
 * exercised at any time ITM. Supports Hooks for additional functionality.
 */
contract DopexV2OptionMarketV2 is ReentrancyGuard, Multicall, Ownable, ERC721 {
    using TickMath for int24;

    struct OptionData {
        uint256 opTickArrayLen;
        int24 tickLower;
        int24 tickUpper;
        uint256 expiry;
        bool isCall;
    }

    struct OptionTicks {
        IHandler _handler;
        IUniswapV3Pool pool;
        address hook;
        int24 tickLower;
        int24 tickUpper;
        uint256 liquidityToUse;
    }

    struct OptionParams {
        OptionTicks[] optionTicks;
        int24 tickLower;
        int24 tickUpper;
        uint256 ttl;
        bool isCall;
        uint256 maxCostAllowance;
    }

    struct ExerciseOptionParams {
        uint256 optionId;
        ISwapper[] swapper;
        bytes[] swapData;
        uint256[] liquidityToExercise;
    }

    struct SettleOptionParams {
        uint256 optionId;
        ISwapper[] swapper;
        bytes[] swapData;
        uint256[] liquidityToSettle;
    }

    struct PositionSplitterParams {
        uint256 optionId;
        address to;
        uint256[] liquidityToSplit;
    }

    // events
    event LogMintOption(
        address user,
        uint256 tokenId,
        bool isCall,
        uint256 premiumAmount,
        uint256 totalAssetWithdrawn,
        uint256 protocolFees
    );
    event LogExerciseOption(
        address user,
        uint256 tokenId,
        uint256 totalProfit,
        uint256 totalAssetRelocked
    );
    event LogSettleOption(address user, uint256 tokenId);
    event LogSplitOption(
        address user,
        uint256 tokenId,
        uint256 newTokenId,
        address to
    );

    event LogUpdateExerciseDelegate(
        address owner,
        address delegate,
        bool status
    );
    event LogOptionsMarketInitialized(
        address primePool,
        address optionPricing,
        address dpFee,
        address callAsset,
        address putAsset
    );
    event LogUpdateAddress(
        address tokeURIFetcher,
        address dpFee,
        address optionPricing
    );

    // errors
    error DopexV2OptionMarket__MaxOptionBuyReached();
    error DopexV2OptionMarket__IVNotSet();
    error DopexV2OptionMarket__NotValidStrikeTick();
    error DopexV2OptionMarket__PoolNotApproved();
    error DopexV2OptionMarket__MaxCostAllowanceExceeded();
    error DopexV2OptionMarket__NotOwnerOrDelegator();
    error DopexV2OptionMarket__EmptyOption();
    error DopexV2OptionMarket__ArrayLenMismatch();
    error DopexV2OptionMarket__OptionExpired();
    error DopexV2OptionMarket__OptionNotExpired();
    error DopexV2OptionMarket__NotEnoughAfterSwap();
    error DopexV2OptionMarket__NotApprovedSettler();
    error DopexV2OptionMarket__NotIVSetter();
    error DopexV2OptionMarket__InvalidPool();

    IDopexV2ClammFeeStrategyV2 public dpFee;
    IOptionPricingV2 public optionPricing;

    IDopexV2PositionManager public immutable positionManager;
    IUniswapV3Pool public immutable primePool;
    address public immutable callAsset;
    address public immutable putAsset;
    uint8 public immutable callAssetDecimals;
    uint8 public immutable putAssetDecimals;

    address public feeTo;
    address public tokenURIFetcher;

    mapping(uint256 => OptionData) public opData;
    mapping(uint256 => OptionTicks[]) public opTickMap;
    mapping(address => mapping(address => bool)) public exerciseDelegator;
    mapping(address => bool) public approvedPools;
    mapping(address => bool) public settlers;

    uint256 public optionIds;

    constructor(
        address _pm,
        address _optionPricing,
        address _dpFee,
        address _callAsset,
        address _putAsset,
        address _primePool
    ) {
        positionManager = IDopexV2PositionManager(_pm);
        callAsset = _callAsset;
        putAsset = _putAsset;

        dpFee = IDopexV2ClammFeeStrategyV2(_dpFee);

        optionPricing = IOptionPricingV2(_optionPricing);

        primePool = IUniswapV3Pool(_primePool);

        if (
            primePool.token0() != _callAsset && primePool.token1() != _callAsset
        ) revert DopexV2OptionMarket__InvalidPool();
        if (primePool.token0() != _putAsset && primePool.token1() != _putAsset)
            revert DopexV2OptionMarket__InvalidPool();

        callAssetDecimals = ERC20(_callAsset).decimals();
        putAssetDecimals = ERC20(_putAsset).decimals();

        emit LogOptionsMarketInitialized(
            _primePool,
            _optionPricing,
            _dpFee,
            _callAsset,
            _putAsset
        );
    }

    /**
     * @notice Provides the name of the token
     * @return The name of the token
     */
    function name() public view override returns (string memory) {
        return "Dopex V2 Option Market V2";
    }

    /**
     * @notice Provides the symbol of the token
     * @return The symbol of the token
     */
    function symbol() public view override returns (string memory) {
        return "DPX-V2-OM-V2";
    }

    /**
     * @notice Provides the tokenURI for each token
     * @param id The token Id.
     * @return The tokenURI string data
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return ITokenURIFetcher(tokenURIFetcher).onFetchTokenURIData(id);
    }

    /**
     * @notice Mints an option for the given strike and expiry.
     * @param _params The option  parameters.
     */
    function mintOption(OptionParams calldata _params) external nonReentrant {
        optionIds += 1;

        if (_params.optionTicks.length > 20)
            revert DopexV2OptionMarket__MaxOptionBuyReached();

        uint256[] memory amountsPerOptionTicks = new uint256[](
            _params.optionTicks.length
        );
        uint256 totalAssetWithdrawn;

        bool isAmount0;

        address assetToUse = _params.isCall ? callAsset : putAsset;

        OptionTicks memory opTick;

        for (uint256 i; i < _params.optionTicks.length; i++) {
            opTick = _params.optionTicks[i];
            if (
                _params.isCall
                    ? _params.tickUpper != opTick.tickUpper
                    : _params.tickLower != opTick.tickLower
            ) revert DopexV2OptionMarket__NotValidStrikeTick();

            opTickMap[optionIds].push(
                OptionTicks({
                    _handler: opTick._handler,
                    pool: opTick.pool,
                    hook: opTick.hook,
                    tickLower: opTick.tickLower,
                    tickUpper: opTick.tickUpper,
                    liquidityToUse: opTick.liquidityToUse
                })
            );

            if (!approvedPools[address(opTick.pool)])
                revert DopexV2OptionMarket__PoolNotApproved();

            bytes memory usePositionData = abi.encode(
                opTick.pool,
                opTick.hook,
                opTick.tickLower,
                opTick.tickUpper,
                opTick.liquidityToUse,
                abi.encode(
                    address(this),
                    _params.ttl,
                    _params.isCall,
                    opTick.pool,
                    opTick.tickLower,
                    opTick.tickUpper
                )
            );

            (
                address[] memory tokens,
                uint256[] memory amounts,

            ) = positionManager.usePosition(opTick._handler, usePositionData);

            if (tokens[0] == assetToUse) {
                require(amounts[0] > 0 && amounts[1] == 0);
                amountsPerOptionTicks[i] = (amounts[0]);
                totalAssetWithdrawn += amounts[0];
                isAmount0 = true;
            } else {
                require(amounts[1] > 0 && amounts[0] == 0);
                amountsPerOptionTicks[i] = (amounts[1]);
                totalAssetWithdrawn += amounts[1];
                isAmount0 = false;
            }
        }

        uint256 strike = getPricePerCallAssetViaTick(
            primePool,
            _params.isCall ? _params.tickUpper : _params.tickLower
        );

        uint256 premiumAmount = _getPremiumAmount(
            _params.isCall ? false : true, // isPut
            block.timestamp + _params.ttl, // expiry
            strike, // Strike
            getCurrentPricePerCallAsset(primePool), // Current price
            _params.isCall
                ? totalAssetWithdrawn
                : (totalAssetWithdrawn * (10 ** putAssetDecimals)) / strike
        );

        if (premiumAmount == 0) revert DopexV2OptionMarket__IVNotSet();

        uint256 protocolFees;
        if (feeTo != address(0)) {
            protocolFees = getFee(totalAssetWithdrawn, premiumAmount);
            ERC20(assetToUse).transferFrom(msg.sender, feeTo, protocolFees);
        }

        if (premiumAmount + protocolFees > _params.maxCostAllowance)
            revert DopexV2OptionMarket__MaxCostAllowanceExceeded();

        ERC20(assetToUse).transferFrom(
            msg.sender,
            address(this),
            premiumAmount
        );
        ERC20(assetToUse).approve(address(positionManager), premiumAmount);

        for (uint i; i < _params.optionTicks.length; i++) {
            opTick = _params.optionTicks[i];
            uint256 premiumAmountEarned = (amountsPerOptionTicks[i] *
                premiumAmount) / totalAssetWithdrawn;

            uint128 liquidityToDonate = LiquidityAmounts.getLiquidityForAmounts(
                _getCurrentSqrtPriceX96(opTick.pool),
                opTick.tickLower.getSqrtRatioAtTick(),
                opTick.tickUpper.getSqrtRatioAtTick(),
                isAmount0 ? premiumAmountEarned : 0,
                isAmount0 ? 0 : premiumAmountEarned
            );

            bytes memory donatePositionData = abi.encode(
                opTick.pool,
                opTick.hook,
                opTick.tickLower,
                opTick.tickUpper,
                liquidityToDonate
            );
            positionManager.donateToPosition(
                opTick._handler,
                donatePositionData
            );
        }

        opData[optionIds] = OptionData({
            opTickArrayLen: _params.optionTicks.length,
            tickLower: _params.tickLower,
            tickUpper: _params.tickUpper,
            expiry: block.timestamp + _params.ttl,
            isCall: _params.isCall
        });

        _safeMint(msg.sender, optionIds);

        emit LogMintOption(
            msg.sender,
            optionIds,
            _params.isCall,
            premiumAmount,
            totalAssetWithdrawn,
            protocolFees
        );
    }

    struct AssetsCache {
        ERC20 assetToUse;
        ERC20 assetToGet;
        uint256 totalProfit;
        uint256 totalAssetRelocked;
    }

    /**
     * @notice Exercises the given option .
     * @param _params The exercise option  parameters.
     */
    function exerciseOption(
        ExerciseOptionParams calldata _params
    ) external nonReentrant returns (AssetsCache memory ac) {
        if (
            ownerOf(_params.optionId) != msg.sender &&
            exerciseDelegator[ownerOf(_params.optionId)][msg.sender] == false
        ) revert DopexV2OptionMarket__NotOwnerOrDelegator();

        OptionData memory oData = opData[_params.optionId];

        if (oData.opTickArrayLen != _params.liquidityToExercise.length)
            revert DopexV2OptionMarket__ArrayLenMismatch();

        if (oData.expiry < block.timestamp)
            revert DopexV2OptionMarket__OptionExpired();

        bool isAmount0 = oData.isCall
            ? primePool.token0() == callAsset
            : primePool.token0() == putAsset;

        ac.assetToUse = ERC20(oData.isCall ? callAsset : putAsset);
        ac.assetToGet = ERC20(oData.isCall ? putAsset : callAsset);

        for (uint256 i; i < oData.opTickArrayLen; i++) {
            if (_params.liquidityToExercise[i] == 0) continue;

            OptionTicks storage opTick = opTickMap[_params.optionId][i];

            uint256 amountToSwap = isAmount0
                ? LiquidityAmounts.getAmount0ForLiquidity(
                    opTick.tickLower.getSqrtRatioAtTick(),
                    opTick.tickUpper.getSqrtRatioAtTick(),
                    uint128(_params.liquidityToExercise[i])
                )
                : LiquidityAmounts.getAmount1ForLiquidity(
                    opTick.tickLower.getSqrtRatioAtTick(),
                    opTick.tickUpper.getSqrtRatioAtTick(),
                    uint128(_params.liquidityToExercise[i])
                );

            ac.totalAssetRelocked += amountToSwap;

            uint256 prevBalance = ac.assetToGet.balanceOf(address(this));

            ac.assetToUse.transfer(address(_params.swapper[i]), amountToSwap);

            _params.swapper[i].onSwapReceived(
                address(ac.assetToUse),
                address(ac.assetToGet),
                amountToSwap,
                _params.swapData[i]
            );

            uint256 amountReq = isAmount0
                ? LiquidityAmounts.getAmount1ForLiquidity(
                    opTick.tickLower.getSqrtRatioAtTick(),
                    opTick.tickUpper.getSqrtRatioAtTick(),
                    uint128(_params.liquidityToExercise[i])
                )
                : LiquidityAmounts.getAmount0ForLiquidity(
                    opTick.tickLower.getSqrtRatioAtTick(),
                    opTick.tickUpper.getSqrtRatioAtTick(),
                    uint128(_params.liquidityToExercise[i])
                );

            uint256 currentBalance = ac.assetToGet.balanceOf(address(this));

            if (currentBalance < prevBalance + amountReq)
                revert DopexV2OptionMarket__NotEnoughAfterSwap();

            ac.assetToGet.approve(address(positionManager), amountReq);

            bytes memory unusePositionData = abi.encode(
                opTick.pool,
                opTick.hook,
                opTick.tickLower,
                opTick.tickUpper,
                _params.liquidityToExercise[i],
                abi.encode("")
            );

            positionManager.unusePosition(opTick._handler, unusePositionData);

            opTick.liquidityToUse -= _params.liquidityToExercise[i];

            ac.totalProfit += currentBalance - (prevBalance + amountReq);
        }

        ac.assetToGet.transfer(msg.sender, ac.totalProfit);

        emit LogExerciseOption(
            ownerOf(_params.optionId),
            _params.optionId,
            ac.totalProfit,
            ac.totalAssetRelocked
        );
    }

    /**
     * @notice Settles the given option .
     * @param _params The settle option  parameters.
     */
    function settleOption(
        SettleOptionParams calldata _params
    ) external nonReentrant {
        if (!settlers[msg.sender])
            revert DopexV2OptionMarket__NotApprovedSettler();
        OptionData memory oData = opData[_params.optionId];

        if (oData.opTickArrayLen != _params.liquidityToSettle.length)
            revert DopexV2OptionMarket__ArrayLenMismatch();

        if (block.timestamp <= oData.expiry)
            revert DopexV2OptionMarket__OptionNotExpired();

        bool isAmount0 = oData.isCall
            ? primePool.token0() == callAsset
            : primePool.token0() == putAsset;

        AssetsCache memory ac;

        ac.assetToUse = ERC20(oData.isCall ? callAsset : putAsset);
        ac.assetToGet = ERC20(oData.isCall ? putAsset : callAsset);

        for (uint256 i; i < oData.opTickArrayLen; i++) {
            if (_params.liquidityToSettle[i] == 0) continue;

            OptionTicks storage opTick = opTickMap[_params.optionId][i];

            uint256 liquidityToSettle = _params.liquidityToSettle[i];

            (uint256 amount0, uint256 amount1) = LiquidityAmounts
                .getAmountsForLiquidity(
                    _getCurrentSqrtPriceX96(opTick.pool),
                    opTick.tickLower.getSqrtRatioAtTick(),
                    opTick.tickUpper.getSqrtRatioAtTick(),
                    uint128(liquidityToSettle)
                );

            if (
                (amount0 > 0 && amount1 == 0) || (amount1 > 0 && amount0 == 0)
            ) {
                if (isAmount0 && amount0 > 0) {
                    ac.assetToUse.approve(address(positionManager), amount0);
                } else if (!isAmount0 && amount1 > 0) {
                    ac.assetToUse.approve(address(positionManager), amount1);
                } else {
                    uint256 amountToSwap = isAmount0
                        ? LiquidityAmounts.getAmount0ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        )
                        : LiquidityAmounts.getAmount1ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        );

                    uint256 prevBalance = ac.assetToGet.balanceOf(
                        address(this)
                    );

                    ac.assetToUse.transfer(
                        address(_params.swapper[i]),
                        amountToSwap
                    );

                    _params.swapper[i].onSwapReceived(
                        address(ac.assetToUse),
                        address(ac.assetToGet),
                        amountToSwap,
                        _params.swapData[i]
                    );

                    uint256 amountReq = isAmount0
                        ? LiquidityAmounts.getAmount1ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        )
                        : LiquidityAmounts.getAmount0ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        );

                    uint256 currentBalance = ac.assetToGet.balanceOf(
                        address(this)
                    );

                    if (currentBalance < prevBalance + amountReq)
                        revert DopexV2OptionMarket__NotEnoughAfterSwap();

                    ac.assetToGet.approve(address(positionManager), amountReq);

                    ac.assetToGet.transfer(
                        msg.sender,
                        currentBalance - (prevBalance + amountReq)
                    );
                }
            } else {
                if (isAmount0) {
                    ac.assetToUse.approve(address(positionManager), amount0);
                    ac.assetToGet.approve(address(positionManager), amount1);

                    uint256 actualAmount0 = LiquidityAmounts
                        .getAmount0ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        );

                    ac.assetToGet.transferFrom(
                        msg.sender,
                        address(this),
                        amount1
                    );

                    ac.assetToUse.transfer(msg.sender, actualAmount0 - amount0);
                } else {
                    ac.assetToUse.approve(address(positionManager), amount1);
                    ac.assetToGet.approve(address(positionManager), amount0);

                    uint256 actualAmount1 = LiquidityAmounts
                        .getAmount1ForLiquidity(
                            opTick.tickLower.getSqrtRatioAtTick(),
                            opTick.tickUpper.getSqrtRatioAtTick(),
                            uint128(liquidityToSettle)
                        );

                    ac.assetToGet.transferFrom(
                        msg.sender,
                        address(this),
                        amount0
                    );

                    ac.assetToUse.transfer(msg.sender, actualAmount1 - amount1);
                }
            }

            bytes memory unusePositionData = abi.encode(
                opTick.pool,
                opTick.hook,
                opTick.tickLower,
                opTick.tickUpper,
                liquidityToSettle,
                abi.encode("")
            );

            positionManager.unusePosition(opTick._handler, unusePositionData);

            opTick.liquidityToUse -= liquidityToSettle;
        }

        emit LogSettleOption(ownerOf(_params.optionId), _params.optionId);
    }

    /**
     * @notice Splits the given option into a new option.
     * @param _params The position splitter parameters.
     */
    function positionSplitter(
        PositionSplitterParams calldata _params
    ) external nonReentrant {
        optionIds += 1;

        if (ownerOf(_params.optionId) != msg.sender)
            revert DopexV2OptionMarket__NotOwnerOrDelegator();
        OptionData memory oData = opData[_params.optionId];

        if (oData.opTickArrayLen != _params.liquidityToSplit.length)
            revert DopexV2OptionMarket__ArrayLenMismatch();

        for (uint256 i; i < _params.liquidityToSplit.length; i++) {
            if (_params.liquidityToSplit[i] == 0)
                revert DopexV2OptionMarket__EmptyOption();
            OptionTicks storage opTick = opTickMap[_params.optionId][i];
            opTick.liquidityToUse -= _params.liquidityToSplit[i];

            opTickMap[optionIds].push(
                OptionTicks({
                    _handler: opTick._handler,
                    pool: opTick.pool,
                    hook: opTick.hook,
                    tickLower: opTick.tickLower,
                    tickUpper: opTick.tickUpper,
                    liquidityToUse: _params.liquidityToSplit[i]
                })
            );
        }

        opData[optionIds] = OptionData({
            opTickArrayLen: _params.liquidityToSplit.length,
            tickLower: oData.tickLower,
            tickUpper: oData.tickUpper,
            expiry: oData.expiry,
            isCall: oData.isCall
        });

        _safeMint(_params.to, optionIds);

        emit LogSplitOption(
            ownerOf(_params.optionId),
            _params.optionId,
            optionIds,
            _params.to
        );
    }

    /**
     * @notice Updates the exercise delegate for the caller's option.
     * @param _delegateTo The address of the new exercise delegate.
     * @param _status The status of the exercise delegate (true to enable, false to disable).
     */
    function updateExerciseDelegate(
        address _delegateTo,
        bool _status
    ) external {
        exerciseDelegator[msg.sender][_delegateTo] = _status;
        emit LogUpdateExerciseDelegate(msg.sender, _delegateTo, _status);
    }

    // internal
    /**
     * @notice Calculates the price per call asset for the given tick.
     * @param _pool The UniswapV3 pool.
     * @param _tick The tick.
     * @return The price per call asset.
     */
    function getPricePerCallAssetViaTick(
        IUniswapV3Pool _pool,
        int24 _tick
    ) public view returns (uint256) {
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(_tick);
        return _getPrice(_pool, sqrtPriceX96);
    }

    /**
     * @notice Calculates the current price per call asset.
     * @param _pool The UniswapV3 pool.
     * @return The current price per call asset.
     */
    function getCurrentPricePerCallAsset(
        IUniswapV3Pool _pool
    ) public view returns (uint256) {
        (, bytes memory result) = address(_pool).staticcall(
            abi.encodeWithSignature("slot0()")
        );
        uint160 sqrtPriceX96 = abi.decode(result, (uint160));
        return _getPrice(_pool, sqrtPriceX96);
    }

    /**
     * @notice Calculates the premium amount for the given option parameters.
     * @param isPut Whether the option is a put or call.
     * @param expiry The expiry of the option.
     * @param strike The strike price of the option.
     * @param lastPrice The last price of the underlying asset.
     * @param amount The amount of the underlying asset.
     * @return The premium amount.
     */
    function getPremiumAmount(
        bool isPut,
        uint expiry,
        uint strike,
        uint lastPrice,
        uint amount
    ) external view returns (uint256) {
        return _getPremiumAmount(isPut, expiry, strike, lastPrice, amount);
    }

    /**
     * @notice Gets the current sqrt price.
     * @param pool The UniswapV3 pool.
     * @return sqrtPriceX96 The current sqrt price.
     */
    function _getCurrentSqrtPriceX96(
        IUniswapV3Pool pool
    ) internal view returns (uint160 sqrtPriceX96) {
        (, bytes memory result) = address(pool).staticcall(
            abi.encodeWithSignature("slot0()")
        );
        sqrtPriceX96 = abi.decode(result, (uint160));
    }

    /**
     * @notice Calculates the premium amount for the given option parameters.
     * @param isPut Whether the option is a put or call.
     * @param expiry The expiry of the option.
     * @param strike The strike price of the option.
     * @param lastPrice The last price of the underlying asset.
     * @param amount The amount of the underlying asset.
     * @return premiumAmount The premium amount.
     */
    function _getPremiumAmount(
        bool isPut,
        uint expiry,
        uint strike,
        uint lastPrice,
        uint amount
    ) internal view returns (uint256 premiumAmount) {
        uint premiumInQuote = (amount *
            optionPricing.getOptionPrice(isPut, expiry, strike, lastPrice)) /
            (isPut ? 10 ** putAssetDecimals : 10 ** callAssetDecimals);

        if (isPut) {
            return premiumInQuote;
        }
        return (premiumInQuote * (10 ** callAssetDecimals)) / lastPrice;
    }

    /**
     * @notice Gets the price per call asset in quote asset units.
     * @param _pool The UniswapV3 pool instance.
     * @param sqrtPriceX96 The sqrt price of the pool.
     * @return price The price per call asset in quote asset units.
     */
    function _getPrice(
        IUniswapV3Pool _pool,
        uint160 sqrtPriceX96
    ) internal view returns (uint256 price) {
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 priceX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            price = callAsset == _pool.token0()
                ? FullMath.mulDiv(priceX192, 10 ** callAssetDecimals, 1 << 192)
                : FullMath.mulDiv(1 << 192, 10 ** callAssetDecimals, priceX192);
        } else {
            uint256 priceX128 = FullMath.mulDiv(
                sqrtPriceX96,
                sqrtPriceX96,
                1 << 64
            );

            price = callAsset == _pool.token0()
                ? FullMath.mulDiv(priceX128, 10 ** callAssetDecimals, 1 << 128)
                : FullMath.mulDiv(1 << 128, 10 ** callAssetDecimals, priceX128);
        }
    }

    /**
     * @notice Gets the fee for the option
     * @param amount Amount being withdrawn
     * @param premium Premium being paid for the position
     * @return fee for the option
     */
    function getFee(
        uint256 amount,
        uint256 premium
    ) public view returns (uint256) {
        return dpFee.onFeeReqReceive(address(this), amount, premium);
    }

    // admin

    /**
     * @notice Updates the addresses of the various components of the contract.
     * @param _feeTo The address of the fee recipient.
     * @param _tokeURIFetcher The address of the token URI fetcher.
     * @param _dpFee The address of the Dopex fee contract.
     * @param _optionPricing The address of the option pricing contract.
     * @param _settler The address of the settler.
     * @param _statusSettler Whether the settler is enabled.
     * @param _pool The address of the UniswapV3 pool.
     * @param _statusPools Whether the UniswapV3 pool is enabled.
     * @dev Only the owner can call this function.
     */
    function updateAddress(
        address _feeTo,
        address _tokeURIFetcher,
        address _dpFee,
        address _optionPricing,
        address _settler,
        bool _statusSettler,
        address _pool,
        bool _statusPools
    ) external onlyOwner {
        feeTo = _feeTo;
        tokenURIFetcher = _tokeURIFetcher;
        dpFee = IDopexV2ClammFeeStrategyV2(_dpFee);
        optionPricing = IOptionPricingV2(_optionPricing);
        settlers[_settler] = _statusSettler;
        approvedPools[_pool] = _statusPools;

        IUniswapV3Pool pool = IUniswapV3Pool(_pool);
        if (pool.token0() != callAsset && pool.token1() != callAsset)
            revert DopexV2OptionMarket__InvalidPool();
        if (pool.token0() != putAsset && pool.token1() != putAsset)
            revert DopexV2OptionMarket__InvalidPool();

        emit LogUpdateAddress(_tokeURIFetcher, _dpFee, _optionPricing);
    }

    // SOS admin functions
    /**
     * @notice Performs an emergency withdraw of all tokens from the contract.
     * @param token The address of the token to withdraw.
     * @dev Only the owner can call this function.
     */
    function emergencyWithdraw(address token) external onlyOwner {
        ERC20(token).transfer(
            msg.sender,
            ERC20(token).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IHandler} from "./IHandler.sol";

interface IDopexV2PositionManager {
    function mintPosition(
        IHandler _handler,
        bytes calldata _mintPositionData
    ) external returns (uint256 sharesMinted);

    function burnPosition(
        IHandler _handler,
        bytes calldata _burnPositionData
    ) external returns (uint256 sharesBurned);

    function usePosition(
        IHandler _handler,
        bytes calldata _usePositionData
    )
        external
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256 liquidityUsed
        );

    function unusePosition(
        IHandler _handler,
        bytes calldata _unusePositionData
    ) external returns (uint256[] memory amounts, uint256 liquidity);

    function donateToPosition(
        IHandler _handler,
        bytes calldata _donatePosition
    ) external returns (uint256[] memory amounts, uint256 liquidity);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IOptionPricingV2 {
    function getOptionPrice(
        bool isPut,
        uint256 expiry,
        uint256 strike,
        uint256 lastPrice
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IHandler {
    function getHandlerIdentifier(
        bytes calldata _data
    ) external view returns (uint256 handlerIdentifierId);

    function tokensToPullForMint(
        bytes calldata _mintPositionData
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    function mintPositionHandler(
        address context,
        bytes calldata _mintPositionData
    ) external returns (uint256 sharesMinted);

    function burnPositionHandler(
        address context,
        bytes calldata _burnPositionData
    ) external returns (uint256 sharesBurned);

    function usePositionHandler(
        bytes calldata _usePositionData
    )
        external
        returns (
            address[] memory tokens,
            uint256[] memory amounts,
            uint256 liquidityUsed
        );

    function tokensToPullForUnUse(
        bytes calldata _unusePositionData
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    function unusePositionHandler(
        bytes calldata _unusePositionData
    ) external returns (uint256[] memory amounts, uint256 liquidity);

    function donateToPosition(
        bytes calldata _donatePosition
    ) external returns (uint256[] memory amounts, uint256 liquidity);

    function tokensToPullForDonate(
        bytes calldata _donatePosition
    ) external view returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDopexV2ClammFeeStrategyV2 {
    /// @notice Computes the fee for an option purchase on Dopex V2 CLAMM
    /// @param _optionMarket Address of the option market
    /// @param _amount Notional Amount
    /// @param _premium Total premium being charged for the option purchase
    /// @return fee the computed fee
    function onFeeReqReceive(
        address _optionMarket,
        uint256 _amount,
        uint256 _premium
    ) external view returns (uint256 fee);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISwapper {
    function onSwapReceived(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata _swapData
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenURIFetcher {
    function onFetchTokenURIData(
        uint256 id
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @notice Simple ERC721 implementation with storage hitchhiking.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol)
///
/// @dev Note:
/// - The ERC721 standard allows for self-approvals.
///   For performance, this implementation WILL NOT revert for such actions.
///   Please add any checks with overrides if desired.
/// - For performance, methods are made payable where permitted by the ERC721 standard.
/// - The `safeTransfer` functions use the identity precompile (0x4)
///   to copy memory internally.
///
/// If you are overriding:
/// - NEVER violate the ERC721 invariant:
///   the balance of an owner MUST always be equal to their number of ownership slots.
///   The transfer functions do not have an underflow guard for user token balances.
/// - Make sure all variables written to storage are properly cleaned
//    (e.g. the bool value for `isApprovedForAll` MUST be either 1 or 0 under the hood).
/// - Check that the overridden function is actually used in the function you want to
///   change the behavior of. Much of the code has been manually inlined for performance.
abstract contract ERC721 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev An account can hold up to 4294967295 tokens.
    uint256 internal constant _MAX_ACCOUNT_BALANCE = 0xffffffff;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Only the token owner or an approved account can manage the token.
    error NotOwnerNorApproved();

    /// @dev The token does not exist.
    error TokenDoesNotExist();

    /// @dev The token already exists.
    error TokenAlreadyExists();

    /// @dev Cannot query the balance for the zero address.
    error BalanceQueryForZeroAddress();

    /// @dev Cannot mint or transfer to the zero address.
    error TransferToZeroAddress();

    /// @dev The token must be owned by `from`.
    error TransferFromIncorrectOwner();

    /// @dev The recipient's balance has overflowed.
    error AccountBalanceOverflow();

    /// @dev Cannot safely transfer to a contract that does not implement
    /// the ERC721Receiver interface.
    error TransferToNonERC721ReceiverImplementer();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when token `id` is transferred from `from` to `to`.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    /// @dev Emitted when `owner` enables `account` to manage the `id` token.
    event Approval(
        address indexed owner,
        address indexed account,
        uint256 indexed id
    );

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool isApproved
    );

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    uint256 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership data slot of `id` is given by:
    /// ```
    ///     mstore(0x00, id)
    ///     mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
    ///     let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
    /// ```
    /// Bits Layout:
    /// - [0..159]   `addr`
    /// - [160..255] `extraData`
    ///
    /// The approved address slot is given by: `add(1, ownershipSlot)`.
    ///
    /// See: https://notes.ethereum.org/%40vbuterin/verkle_tree_eip
    ///
    /// The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x1c)
    /// ```
    /// Bits Layout:
    /// - [0..31]   `balance`
    /// - [32..255] `aux`
    ///
    /// The `operator` approval slot of `owner` is given by:
    /// ```
    ///     mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, operator))
    ///     mstore(0x00, owner)
    ///     let operatorApprovalSlot := keccak256(0x0c, 0x30)
    /// ```
    uint256 private constant _ERC721_MASTER_SLOT_SEED =
        0x7d8825530a5a2e7a << 192;

    /// @dev Pre-shifted and pre-masked constant.
    uint256 private constant _ERC721_MASTER_SLOT_SEED_MASKED =
        0x0a5a2e7a00000000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the token collection name.
    function name() public view virtual returns (string memory);

    /// @dev Returns the token collection symbol.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the Uniform Resource Identifier (URI) for token `id`.
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC721                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of token `id`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function ownerOf(uint256 id) public view virtual returns (address result) {
        result = _ownerOf(id);
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(result) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the number of tokens owned by `owner`.
    ///
    /// Requirements:
    /// - `owner` must not be the zero address.
    function balanceOf(
        address owner
    ) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Revert if the `owner` is the zero address.
            if iszero(owner) {
                mstore(0x00, 0x8f4eb604) // `BalanceQueryForZeroAddress()`.
                revert(0x1c, 0x04)
            }
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner)
            result := and(sload(keccak256(0x0c, 0x1c)), _MAX_ACCOUNT_BALANCE)
        }
    }

    /// @dev Returns the account approved to manage token `id`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function getApproved(
        uint256 id
    ) public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            if iszero(shl(96, sload(ownershipSlot))) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            result := sload(add(1, ownershipSlot))
        }
    }

    /// @dev Sets `account` as the approved account to manage token `id`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    /// - The caller must be the owner of the token,
    ///   or an approved operator for the token owner.
    ///
    /// Emits an {Approval} event.
    function approve(address account, uint256 id) public payable virtual {
        _approve(msg.sender, account, id);
    }

    /// @dev Returns whether `operator` is approved to manage the tokens of `owner`.
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1c, operator)
            mstore(0x08, _ERC721_MASTER_SLOT_SEED_MASKED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x30))
        }
    }

    /// @dev Sets whether `operator` is approved to manage the tokens of the caller.
    ///
    /// Emits an {ApprovalForAll} event.
    function setApprovalForAll(
        address operator,
        bool isApproved
    ) public virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Convert to 0 or 1.
            isApproved := iszero(iszero(isApproved))
            // Update the `isApproved` for (`msg.sender`, `operator`).
            mstore(0x1c, operator)
            mstore(0x08, _ERC721_MASTER_SLOT_SEED_MASKED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x30), isApproved)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, isApproved)
            // forgefmt: disable-next-item
            log3(
                0x00,
                0x20,
                _APPROVAL_FOR_ALL_EVENT_SIGNATURE,
                caller(),
                shr(96, shl(96, operator))
            )
        }
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        _beforeTokenTransfer(from, to, id);
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            let bitmaskAddress := shr(96, not(0))
            from := and(bitmaskAddress, from)
            to := and(bitmaskAddress, to)
            // Load the ownership data.
            mstore(0x00, id)
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, caller()))
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let ownershipPacked := sload(ownershipSlot)
            let owner := and(bitmaskAddress, ownershipPacked)
            // Revert if `from` is not the owner, or does not exist.
            if iszero(mul(owner, eq(owner, from))) {
                if iszero(owner) {
                    mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                    revert(0x1c, 0x04)
                }
                mstore(0x00, 0xa1148100) // `TransferFromIncorrectOwner()`.
                revert(0x1c, 0x04)
            }
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load, check, and update the token approval.
            {
                mstore(0x00, from)
                let approvedAddress := sload(add(1, ownershipSlot))
                // Revert if the caller is not the owner, nor approved.
                if iszero(
                    or(eq(caller(), from), eq(caller(), approvedAddress))
                ) {
                    if iszero(sload(keccak256(0x0c, 0x30))) {
                        mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                        revert(0x1c, 0x04)
                    }
                }
                // Delete the approved address if any.
                if approvedAddress {
                    sstore(add(1, ownershipSlot), 0)
                }
            }
            // Update with the new owner.
            sstore(ownershipSlot, xor(ownershipPacked, xor(from, to)))
            // Decrement the balance of `from`.
            {
                let fromBalanceSlot := keccak256(0x0c, 0x1c)
                sstore(fromBalanceSlot, sub(sload(fromBalanceSlot), 1))
            }
            // Increment the balance of `to`.
            {
                mstore(0x00, to)
                let toBalanceSlot := keccak256(0x0c, 0x1c)
                let toBalanceSlotPacked := add(sload(toBalanceSlot), 1)
                if iszero(and(toBalanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(toBalanceSlot, toBalanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, id)
        }
        _afterTokenTransfer(from, to, id);
    }

    /// @dev Equivalent to `safeTransferFrom(from, to, id, "")`.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public payable virtual {
        transferFrom(from, to, id);
        if (_hasCode(to)) _checkOnERC721Received(from, to, id, "");
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    /// - If `to` refers to a smart contract, it must implement
    ///   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    ///
    /// Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public payable virtual {
        transferFrom(from, to, id);
        if (_hasCode(to)) _checkOnERC721Received(from, to, id, data);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    /// See: https://eips.ethereum.org/EIPS/eip-165
    /// This function call must use less than 30000 gas.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC721: 0x80ac58cd, ERC721Metadata: 0x5b5e139f.
            result := or(
                or(eq(s, 0x01ffc9a7), eq(s, 0x80ac58cd)),
                eq(s, 0x5b5e139f)
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL QUERY FUNCTIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if token `id` exists.
    function _exists(uint256 id) internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            result := iszero(
                iszero(shl(96, sload(add(id, add(id, keccak256(0x00, 0x20))))))
            )
        }
    }

    /// @dev Returns the owner of token `id`.
    /// Returns the zero address instead of reverting if the token does not exist.
    function _ownerOf(
        uint256 id
    ) internal view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            result := shr(
                96,
                shl(96, sload(add(id, add(id, keccak256(0x00, 0x20)))))
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            INTERNAL DATA HITCHHIKING FUNCTIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance, no events are emitted for the hitchhiking setters.
    // Please emit your own events if required.

    /// @dev Returns the auxiliary data for `owner`.
    /// Minting, transferring, burning the tokens of `owner` will not change the auxiliary data.
    /// Auxiliary data can be set for any address, even if it does not have any tokens.
    function _getAux(
        address owner
    ) internal view virtual returns (uint224 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner)
            result := shr(32, sload(keccak256(0x0c, 0x1c)))
        }
    }

    /// @dev Set the auxiliary data for `owner` to `value`.
    /// Minting, transferring, burning the tokens of `owner` will not change the auxiliary data.
    /// Auxiliary data can be set for any address, even if it does not have any tokens.
    function _setAux(address owner, uint224 value) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            mstore(0x00, owner)
            let balanceSlot := keccak256(0x0c, 0x1c)
            let packed := sload(balanceSlot)
            sstore(
                balanceSlot,
                xor(packed, shl(32, xor(value, shr(32, packed))))
            )
        }
    }

    /// @dev Returns the extra data for token `id`.
    /// Minting, transferring, burning a token will not change the extra data.
    /// The extra data can be set on a non-existent token.
    function _getExtraData(
        uint256 id
    ) internal view virtual returns (uint96 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            result := shr(160, sload(add(id, add(id, keccak256(0x00, 0x20)))))
        }
    }

    /// @dev Sets the extra data for token `id` to `value`.
    /// Minting, transferring, burning a token will not change the extra data.
    /// The extra data can be set on a non-existent token.
    function _setExtraData(uint256 id, uint96 value) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let packed := sload(ownershipSlot)
            sstore(
                ownershipSlot,
                xor(packed, shl(160, xor(value, shr(160, packed))))
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints token `id` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must not exist.
    /// - `to` cannot be the zero address.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 id) internal virtual {
        _beforeTokenTransfer(address(0), to, id);
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            to := shr(96, shl(96, to))
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load the ownership data.
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let ownershipPacked := sload(ownershipSlot)
            // Revert if the token already exists.
            if shl(96, ownershipPacked) {
                mstore(0x00, 0xc991cbb1) // `TokenAlreadyExists()`.
                revert(0x1c, 0x04)
            }
            // Update with the owner.
            sstore(ownershipSlot, or(ownershipPacked, to))
            // Increment the balance of the owner.
            {
                mstore(0x00, to)
                let balanceSlot := keccak256(0x0c, 0x1c)
                let balanceSlotPacked := add(sload(balanceSlot), 1)
                if iszero(and(balanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(balanceSlot, balanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, 0, to, id)
        }
        _afterTokenTransfer(address(0), to, id);
    }

    /// @dev Equivalent to `_safeMint(to, id, "")`.
    function _safeMint(address to, uint256 id) internal virtual {
        _safeMint(to, id, "");
    }

    /// @dev Mints token `id` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must not exist.
    /// - `to` cannot be the zero address.
    /// - If `to` refers to a smart contract, it must implement
    ///   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    ///
    /// Emits a {Transfer} event.
    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);
        if (_hasCode(to)) _checkOnERC721Received(address(0), to, id, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `_burn(address(0), id)`.
    function _burn(uint256 id) internal virtual {
        _burn(address(0), id);
    }

    /// @dev Destroys token `id`, using `by`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - If `by` is not the zero address,
    ///   it must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function _burn(address by, uint256 id) internal virtual {
        address owner = ownerOf(id);
        _beforeTokenTransfer(owner, address(0), id);
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            by := shr(96, shl(96, by))
            // Load the ownership data.
            mstore(0x00, id)
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, by))
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let ownershipPacked := sload(ownershipSlot)
            // Reload the owner in case it is changed in `_beforeTokenTransfer`.
            owner := shr(96, shl(96, ownershipPacked))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Load and check the token approval.
            {
                mstore(0x00, owner)
                let approvedAddress := sload(add(1, ownershipSlot))
                // If `by` is not the zero address, do the authorization check.
                // Revert if the `by` is not the owner, nor approved.
                if iszero(
                    or(iszero(by), or(eq(by, owner), eq(by, approvedAddress)))
                ) {
                    if iszero(sload(keccak256(0x0c, 0x30))) {
                        mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                        revert(0x1c, 0x04)
                    }
                }
                // Delete the approved address if any.
                if approvedAddress {
                    sstore(add(1, ownershipSlot), 0)
                }
            }
            // Clear the owner.
            sstore(ownershipSlot, xor(ownershipPacked, owner))
            // Decrement the balance of `owner`.
            {
                let balanceSlot := keccak256(0x0c, 0x1c)
                sstore(balanceSlot, sub(sload(balanceSlot), 1))
            }
            // Emit the {Transfer} event.
            log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, owner, 0, id)
        }
        _afterTokenTransfer(owner, address(0), id);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL APPROVAL FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `account` is the owner of token `id`, or is approved to manage it.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function _isApprovedOrOwner(
        address account,
        uint256 id
    ) internal view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            // Clear the upper 96 bits.
            account := shr(96, shl(96, account))
            // Load the ownership data.
            mstore(0x00, id)
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, account))
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let owner := shr(96, shl(96, sload(ownershipSlot)))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // Check if `account` is the `owner`.
            if iszero(eq(account, owner)) {
                mstore(0x00, owner)
                // Check if `account` is approved to manage the token.
                if iszero(sload(keccak256(0x0c, 0x30))) {
                    result := eq(account, sload(add(1, ownershipSlot)))
                }
            }
        }
    }

    /// @dev Returns the account approved to manage token `id`.
    /// Returns the zero address instead of reverting if the token does not exist.
    function _getApproved(
        uint256 id
    ) internal view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, id)
            mstore(0x1c, _ERC721_MASTER_SLOT_SEED)
            result := sload(add(1, add(id, add(id, keccak256(0x00, 0x20)))))
        }
    }

    /// @dev Equivalent to `_approve(address(0), account, id)`.
    function _approve(address account, uint256 id) internal virtual {
        _approve(address(0), account, id);
    }

    /// @dev Sets `account` as the approved account to manage token `id`, using `by`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    /// - If `by` is not the zero address, `by` must be the owner
    ///   or an approved operator for the token owner.
    ///
    /// Emits a {Transfer} event.
    function _approve(
        address by,
        address account,
        uint256 id
    ) internal virtual {
        assembly {
            // Clear the upper 96 bits.
            let bitmaskAddress := shr(96, not(0))
            account := and(bitmaskAddress, account)
            by := and(bitmaskAddress, by)
            // Load the owner of the token.
            mstore(0x00, id)
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, by))
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let owner := and(bitmaskAddress, sload(ownershipSlot))
            // Revert if the token does not exist.
            if iszero(owner) {
                mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                revert(0x1c, 0x04)
            }
            // If `by` is not the zero address, do the authorization check.
            // Revert if `by` is not the owner, nor approved.
            if iszero(or(iszero(by), eq(by, owner))) {
                mstore(0x00, owner)
                if iszero(sload(keccak256(0x0c, 0x30))) {
                    mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                    revert(0x1c, 0x04)
                }
            }
            // Sets `account` as the approved account to manage `id`.
            sstore(add(1, ownershipSlot), account)
            // Emit the {Approval} event.
            log4(
                codesize(),
                0x00,
                _APPROVAL_EVENT_SIGNATURE,
                owner,
                account,
                id
            )
        }
    }

    /// @dev Approve or remove the `operator` as an operator for `by`,
    /// without authorization checks.
    ///
    /// Emits an {ApprovalForAll} event.
    function _setApprovalForAll(
        address by,
        address operator,
        bool isApproved
    ) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            by := shr(96, shl(96, by))
            operator := shr(96, shl(96, operator))
            // Convert to 0 or 1.
            isApproved := iszero(iszero(isApproved))
            // Update the `isApproved` for (`by`, `operator`).
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, operator))
            mstore(0x00, by)
            sstore(keccak256(0x0c, 0x30), isApproved)
            // Emit the {ApprovalForAll} event.
            mstore(0x00, isApproved)
            log3(0x00, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, by, operator)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `_transfer(address(0), from, to, id)`.
    function _transfer(address from, address to, uint256 id) internal virtual {
        _transfer(address(0), from, to, id);
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - If `by` is not the zero address,
    ///   it must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function _transfer(
        address by,
        address from,
        address to,
        uint256 id
    ) internal virtual {
        _beforeTokenTransfer(from, to, id);
        /// @solidity memory-safe-assembly
        assembly {
            // Clear the upper 96 bits.
            let bitmaskAddress := shr(96, not(0))
            from := and(bitmaskAddress, from)
            to := and(bitmaskAddress, to)
            by := and(bitmaskAddress, by)
            // Load the ownership data.
            mstore(0x00, id)
            mstore(0x1c, or(_ERC721_MASTER_SLOT_SEED, by))
            let ownershipSlot := add(id, add(id, keccak256(0x00, 0x20)))
            let ownershipPacked := sload(ownershipSlot)
            let owner := and(bitmaskAddress, ownershipPacked)
            // Revert if `from` is not the owner, or does not exist.
            if iszero(mul(owner, eq(owner, from))) {
                if iszero(owner) {
                    mstore(0x00, 0xceea21b6) // `TokenDoesNotExist()`.
                    revert(0x1c, 0x04)
                }
                mstore(0x00, 0xa1148100) // `TransferFromIncorrectOwner()`.
                revert(0x1c, 0x04)
            }
            // Revert if `to` is the zero address.
            if iszero(to) {
                mstore(0x00, 0xea553b34) // `TransferToZeroAddress()`.
                revert(0x1c, 0x04)
            }
            // Load, check, and update the token approval.
            {
                mstore(0x00, from)
                let approvedAddress := sload(add(1, ownershipSlot))
                // If `by` is not the zero address, do the authorization check.
                // Revert if the `by` is not the owner, nor approved.
                if iszero(
                    or(iszero(by), or(eq(by, from), eq(by, approvedAddress)))
                ) {
                    if iszero(sload(keccak256(0x0c, 0x30))) {
                        mstore(0x00, 0x4b6e7f18) // `NotOwnerNorApproved()`.
                        revert(0x1c, 0x04)
                    }
                }
                // Delete the approved address if any.
                if approvedAddress {
                    sstore(add(1, ownershipSlot), 0)
                }
            }
            // Update with the new owner.
            sstore(ownershipSlot, xor(ownershipPacked, xor(from, to)))
            // Decrement the balance of `from`.
            {
                let fromBalanceSlot := keccak256(0x0c, 0x1c)
                sstore(fromBalanceSlot, sub(sload(fromBalanceSlot), 1))
            }
            // Increment the balance of `to`.
            {
                mstore(0x00, to)
                let toBalanceSlot := keccak256(0x0c, 0x1c)
                let toBalanceSlotPacked := add(sload(toBalanceSlot), 1)
                if iszero(and(toBalanceSlotPacked, _MAX_ACCOUNT_BALANCE)) {
                    mstore(0x00, 0x01336cea) // `AccountBalanceOverflow()`.
                    revert(0x1c, 0x04)
                }
                sstore(toBalanceSlot, toBalanceSlotPacked)
            }
            // Emit the {Transfer} event.
            log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, id)
        }
        _afterTokenTransfer(from, to, id);
    }

    /// @dev Equivalent to `_safeTransfer(from, to, id, "")`.
    function _safeTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {
        _safeTransfer(from, to, id, "");
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    /// - If `to` refers to a smart contract, it must implement
    ///   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    ///
    /// Emits a {Transfer} event.
    function _safeTransfer(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _transfer(address(0), from, to, id);
        if (_hasCode(to)) _checkOnERC721Received(from, to, id, data);
    }

    /// @dev Equivalent to `_safeTransfer(by, from, to, id, "")`.
    function _safeTransfer(
        address by,
        address from,
        address to,
        uint256 id
    ) internal virtual {
        _safeTransfer(by, from, to, id, "");
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - If `by` is not the zero address,
    ///   it must be the owner of the token, or be approved to manage the token.
    /// - If `to` refers to a smart contract, it must implement
    ///   {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    ///
    /// Emits a {Transfer} event.
    function _safeTransfer(
        address by,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _transfer(by, from, to, id);
        if (_hasCode(to)) _checkOnERC721Received(from, to, id, data);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    HOOKS FOR OVERRIDING                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any token transfers, including minting and burning.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {}

    /// @dev Hook that is called after any token transfers, including minting and burning.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns if `a` has bytecode of non-zero length.
    function _hasCode(address a) private view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := extcodesize(a) // Can handle dirty upper bits.
        }
    }

    /// @dev Perform a call to invoke {IERC721Receiver-onERC721Received} on `to`.
    /// Reverts if the target does not support the function correctly.
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private {
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the calldata.
            let m := mload(0x40)
            let onERC721ReceivedSelector := 0x150b7a02
            mstore(m, onERC721ReceivedSelector)
            mstore(add(m, 0x20), caller()) // The `operator`, which is always `msg.sender`.
            mstore(add(m, 0x40), shr(96, shl(96, from)))
            mstore(add(m, 0x60), id)
            mstore(add(m, 0x80), 0x80)
            let n := mload(data)
            mstore(add(m, 0xa0), n)
            if n {
                pop(staticcall(gas(), 4, add(data, 0x20), n, add(m, 0xc0), n))
            }
            // Revert if the call reverts.
            if iszero(call(gas(), to, 0, add(m, 0x1c), add(n, 0xa4), m, 0x20)) {
                if returndatasize() {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
            }
            // Load the returndata and compare it.
            if iszero(eq(mload(m), shl(224, onERC721ReceivedSelector))) {
                mstore(0x00, 0xd1a57ed6) // `TransferToNonERC721ReceiverImplementer()`.
                revert(0x1c, 0x04)
            }
        }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}