// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxGlpManager {
    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 mintAmount
    );
    event RemoveLiquidity(
        address account,
        address token,
        uint256 glpAmount,
        uint256 aumInUsdg,
        uint256 glpSupply,
        uint256 usdgAmount,
        uint256 amountOut
    );

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function GLP_PRECISION() external view returns (uint256);

    function MAX_COOLDOWN_DURATION() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

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

    function aumAddition() external view returns (uint256);

    function aumDeduction() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function getGlobalShortAveragePrice(address _token)
        external
        view
        returns (uint256);

    function getGlobalShortDelta(
        address _token,
        uint256 _price,
        uint256 _size
    ) external view returns (uint256, bool);

    function getPrice(bool _maximise) external view returns (uint256);

    function glp() external view returns (address);

    function gov() external view returns (address);

    function inPrivateMode() external view returns (bool);

    function isHandler(address) external view returns (bool);

    function lastAddedAt(address) external view returns (uint256);

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

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction)
        external;

    function setCooldownDuration(uint256 _cooldownDuration) external;

    function setGov(address _gov) external;

    function setHandler(address _handler, bool _isActive) external;

    function setInPrivateMode(bool _inPrivateMode) external;

    function setShortsTracker(address _shortsTracker) external;

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function shortsTracker() external view returns (address);

    function shortsTrackerAveragePriceWeight() external view returns (uint256);

    function usdg() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGmxVault {
    event BuyUSDG(
        address account,
        address token,
        uint256 tokenAmount,
        uint256 usdgAmount,
        uint256 feeBasisPoints
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event DecreaseGuaranteedUsd(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreaseReservedAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event DirectPoolDeposit(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event IncreaseReservedAmount(address token, uint256 amount);
    event IncreaseUsdgAmount(address token, uint256 amount);
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event SellUSDG(
        address account,
        address token,
        uint256 usdgAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );
    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function FUNDING_RATE_PRECISION() external view returns (uint256);

    function MAX_FEE_BASIS_POINTS() external view returns (uint256);

    function MAX_FUNDING_RATE_FACTOR() external view returns (uint256);

    function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);

    function MIN_FUNDING_RATE_INTERVAL() external view returns (uint256);

    function MIN_LEVERAGE() external view returns (uint256);

    function PRICE_PRECISION() external view returns (uint256);

    function USDG_DECIMALS() external view returns (uint256);

    function addRouter(address _router) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function allWhitelistedTokensLength() external view returns (uint256);

    function approvedRouters(address, address) external view returns (bool);

    function bufferAmounts(address) external view returns (uint256);

    function buyUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function clearTokenConfig(address _token) external;

    function cumulativeFundingRates(address) external view returns (uint256);

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function errorController() external view returns (address);

    function errors(uint256) external view returns (string memory);

    function feeReserves(address) external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor() external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getGlobalShortDelta(address _token)
        external
        view
        returns (bool, uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getNextGlobalShortAveragePrice(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external pure returns (bytes32);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount)
        external
        view
        returns (uint256);

    function getRedemptionCollateral(address _token)
        external
        view
        returns (uint256);

    function getRedemptionCollateralUsd(address _token)
        external
        view
        returns (uint256);

    function getTargetUsdgAmount(address _token)
        external
        view
        returns (uint256);

    function getUtilisation(address _token) external view returns (uint256);

    function globalShortAveragePrices(address) external view returns (uint256);

    function globalShortSizes(address) external view returns (uint256);

    function gov() external view returns (address);

    function guaranteedUsd(address) external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function includeAmmPrice() external view returns (bool);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function initialize(
        address _router,
        address _usdg,
        address _priceFeed,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function isInitialized() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function isLiquidator(address) external view returns (bool);

    function isManager(address) external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function lastFundingTimes(address) external view returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function liquidationFeeUsd() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function maxGasPrice() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function maxUsdgAmounts(address) external view returns (uint256);

    function minProfitBasisPoints(address) external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function poolAmounts(address) external view returns (uint256);

    function positions(bytes32)
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            int256 realisedPnl,
            uint256 lastIncreasedTime
        );

    function priceFeed() external view returns (address);

    function removeRouter(address _router) external;

    function reservedAmounts(address) external view returns (uint256);

    function router() external view returns (address);

    function sellUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function setBufferAmount(address _token, uint256 _amount) external;

    function setError(uint256 _errorCode, string memory _error) external;

    function setErrorController(address _errorController) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setGov(address _gov) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode)
        external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setManager(address _manager, bool _isManager) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setPriceFeed(address _priceFeed) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function shortableTokens(address) external view returns (bool);

    function stableFundingRateFactor() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function stableTokens(address) external view returns (bool);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function tokenBalances(address) external view returns (uint256);

    function tokenDecimals(address) external view returns (uint256);

    function tokenToUsdMin(address _token, uint256 _tokenAmount)
        external
        view
        returns (uint256);

    function tokenWeights(address) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function updateCumulativeFundingRate(address _token) external;

    function upgradeVault(
        address _newVault,
        address _token,
        uint256 _amount
    ) external;

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) external view returns (uint256);

    function usdToTokenMax(address _token, uint256 _usdAmount)
        external
        view
        returns (uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount)
        external
        view
        returns (uint256);

    function usdg() external view returns (address);

    function usdgAmounts(address) external view returns (uint256);

    function useSwapPricing() external view returns (bool);

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function whitelistedTokenCount() external view returns (uint256);

    function whitelistedTokens(address) external view returns (bool);

    function withdrawFees(address _token, address _receiver)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "interfaces/IGmxVault.sol";
import "interfaces/IGmxGlpManager.sol";
import "interfaces/IGmxVaultPriceFeed.sol";

contract GmxLens {
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant PRICE_PRECISION = 10 ** 30;
    uint256 private constant USDG_DECIMALS = 18;
    uint256 private constant PRECISION = 10 ** 18;

    struct TokenFee {
        address token;
        uint256 fee;
    }

    IGmxGlpManager public immutable manager;
    IGmxVault public immutable vault;

    IERC20 private immutable glp;
    IERC20 private immutable usdg;

    constructor(IGmxGlpManager _manager, IGmxVault _vault) {
        manager = _manager;
        vault = _vault;
        glp = IERC20(manager.glp());
        usdg = IERC20(manager.usdg());
    }

    function getGlpPrice() public view returns (uint256) {
        return (manager.getAumInUsdg(false) * PRICE_PRECISION) / glp.totalSupply();
    }

    function getTokenOutFromBurningGlp(address tokenOut, uint256 glpAmount) public view returns (uint256 amount, uint256 feeBasisPoints) {
        uint256 usdgAmount = (glpAmount * getGlpPrice()) / PRICE_PRECISION;

        feeBasisPoints = _getFeeBasisPoints(
            tokenOut,
            vault.usdgAmounts(tokenOut) - usdgAmount,
            usdgAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            false
        );

        uint256 redemptionAmount = _getRedemptionAmount(tokenOut, usdgAmount);
        amount = _collectSwapFees(redemptionAmount, feeBasisPoints);
    }

    function getMaxAmountOut(address tokenOut) public view returns (uint256 amount) {
        amount = vault.maxUsdgAmounts(tokenOut) - vault.usdgAmounts(tokenOut);
    }

    function getMintedGlpFromTokenIn(
        address tokenIn,
        uint256 amount
    ) external view returns (uint256 amountOut, uint256 feeBasisPoints, uint256 maxAmountOut) {
        uint256 aumInUsdg = manager.getAumInUsdg(true);
        uint256 usdgAmount;
        (usdgAmount, feeBasisPoints) = _simulateBuyUSDG(tokenIn, amount);

        amountOut = (aumInUsdg == 0 ? usdgAmount : ((usdgAmount * PRICE_PRECISION) / getGlpPrice()));
        maxAmountOut = getMaxAmountOut(tokenIn);
    }

    function getUsdgAmountFromTokenIn(address tokenIn, uint256 tokenAmount) public view returns (uint256 usdgAmount) {
        uint256 price = vault.getMinPrice(tokenIn);
        uint256 rawUsdgAmount = (tokenAmount * price) / PRICE_PRECISION;
        return vault.adjustForDecimals(rawUsdgAmount, tokenIn, address(usdg));
    }

    function _simulateBuyUSDG(address tokenIn, uint256 tokenAmount) private view returns (uint256 mintAmount, uint256 feeBasisPoints) {
        uint256 usdgAmount = getUsdgAmountFromTokenIn(tokenIn, tokenAmount);

        feeBasisPoints = _getFeeBasisPoints(
            tokenIn,
            vault.usdgAmounts(tokenIn),
            usdgAmount,
            vault.mintBurnFeeBasisPoints(),
            vault.taxBasisPoints(),
            true
        );

        uint256 amountAfterFees = _collectSwapFees(tokenAmount, feeBasisPoints);
        mintAmount = getUsdgAmountFromTokenIn(tokenIn, amountAfterFees);
    }

    function _collectSwapFees(uint256 _amount, uint256 _feeBasisPoints) private pure returns (uint256) {
        return (_amount * (BASIS_POINTS_DIVISOR - _feeBasisPoints)) / BASIS_POINTS_DIVISOR;
    }

    function _getFeeBasisPoints(
        address _token,
        uint256 tokenUsdgAmount,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) private view returns (uint256) {
        if (!vault.hasDynamicFees()) {
            return _feeBasisPoints;
        }

        uint256 initialAmount = tokenUsdgAmount;
        uint256 nextAmount = initialAmount + _usdgDelta;
        if (!_increment) {
            nextAmount = _usdgDelta > initialAmount ? 0 : initialAmount - _usdgDelta;
        }

        uint256 targetAmount = _getTargetUsdgAmount(_token);
        if (targetAmount == 0) {
            return _feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount - targetAmount : targetAmount - initialAmount;
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount - targetAmount : targetAmount - nextAmount;

        if (nextDiff < initialDiff) {
            uint256 rebateBps = (_taxBasisPoints * initialDiff) / targetAmount;
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints - rebateBps;
        }

        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = (_taxBasisPoints * averageDiff) / targetAmount;
        return _feeBasisPoints + taxBps;
    }

    function _getTargetUsdgAmount(address _token) private view returns (uint256) {
        uint256 supply = IERC20(usdg).totalSupply();

        if (supply == 0) {
            return 0;
        }
        uint256 weight = vault.tokenWeights(_token);
        return (weight * supply) / vault.totalTokenWeights();
    }

    function _decreaseUsdgAmount(address _token, uint256 _amount) private view returns (uint256) {
        uint256 value = vault.usdgAmounts(_token);
        if (value <= _amount) {
            return 0;
        }
        return value - _amount;
    }

    function _getRedemptionAmount(address _token, uint256 _usdgAmount) private view returns (uint256) {
        uint256 price = _getMaxPrice(_token);
        uint256 redemptionAmount = (_usdgAmount * PRICE_PRECISION) / price;

        return _adjustForDecimals(redemptionAmount, address(usdg), _token);
    }

    function _adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) private view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == address(usdg) ? USDG_DECIMALS : vault.tokenDecimals(_tokenDiv);
        uint256 decimalsMul = _tokenMul == address(usdg) ? USDG_DECIMALS : vault.tokenDecimals(_tokenMul);

        return (_amount * 10 ** decimalsMul) / 10 ** decimalsDiv;
    }

    function _getMaxPrice(address _token) private view returns (uint256) {
        return IVaultPriceFeed(vault.priceFeed()).getPrice(_token, true, false, true);
    }
}