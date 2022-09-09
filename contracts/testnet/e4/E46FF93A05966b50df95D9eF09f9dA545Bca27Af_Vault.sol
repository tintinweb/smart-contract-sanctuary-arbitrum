// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IVUSD.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/IVaultPriceFeed.sol";

contract Vault is ReentrancyGuard, Ownable, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    enum Type1  { MARKET, TP, SL, TP_SL}
    struct UserInfo {
        uint256 amount;
        uint256 lastFeeReserves;
    }

    struct Position {
        address refer;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        Type1 postionType;
        uint256 slPrice;
        uint256 tpPrice;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;

    bool public override isInitialized;
    bool public override isLeverageEnabled = true;

    IVaultUtils public vaultUtils;

    address public override router;
    address public override priceFeed;

    address public vlp;
    address public vusd;
    address public feeManager;
    uint256 public cooldownDuration;

    uint256 public override whitelistedTokenCount;

    uint256 public override maxLeverage = 50 * 10000; // 50x

    uint256 public override liquidationFeeUsd;
    uint256 public override taxBasisPoints = 50; // 0.5%
    uint256 public override stableTaxBasisPoints = 20; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public lastFeeReserves;
    uint256 public liquidityFeeBasisPoints = 30; // 0.3%
    uint256 public override feeRewardBasisPoints = 7000; // 70%
    uint256 public override marginFeeBasisPoints = 10; // 0.1%
    uint256 public vlpRate = 1e12; // 1
    uint256 public override minProfitTime;
    bool public override hasDynamicFees = false;

    uint256 public override fundingInterval = 8 hours;
    uint256 public override fundingRateFactor;
    uint256 public override stableFundingRateFactor;

    bool public includeAmmPrice = true;
    bool public useSwapPricing = false;

    bool public override inManagerMode = false;
    bool public override inPrivateLiquidationMode = false;
    // feeReserves tracks the amount of fees per token
    uint256 public override feeReserves;
    uint256 public override maxGasPrice;
    address[] public override allWhitelistedTokens;
    uint256 public totalVLP;
    mapping (address => mapping (address => UserInfo)) public userInfo;
    mapping (address => mapping (address => bool)) public override approvedRouters;
    mapping (address => bool) public override isLiquidator;
    mapping (address => bool) public override isManager;
    mapping (address => bool) public override whitelistedTokens;
    mapping (address => uint256) public override tokenDecimals;
    mapping (address => uint256) public override minProfitBasisPoints;
    mapping (address => bool) public override stableTokens;
    mapping (address => bool) public override shortableTokens;
    mapping (address => mapping (address => uint256)) public liquidityAmount;
    // tokenBalances is used only to determine _transferIn values
    mapping (address => uint256) public override tokenBalances;
    mapping (address => bool) public isCustomFees;
    mapping (address => uint256) public customFeePoints;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    uint256 public override poolAmounts;
   // reservedAmounts tracks the number of tokens reserved for open leverage positions
    uint256 public override reservedAmounts;

    mapping (address => uint256) public collateralAmounts;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of USD
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    // mapping (address => uint256) public override guaranteedUsd;

    // cumulativeFundingRates tracks the funding rates based on utilization
    uint256 public override cumulativeFundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    uint256 public override lastFundingTimes;
    // positions tracks all open positions
    mapping (bytes32 => Position) public positions;
    mapping (address => uint256) public lastAddedAt;

    event IncreasePosition(
        bytes32 key,
        address account,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        Type1 positionType,
        uint256 slPrice,
        uint256 tpPrice,
        uint256 fee
    );

    event LiquidatePosition(
        bytes32 key,
        address account,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );

    event DecreasePosition(
        bytes32 key,
        address account,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong
    );

    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event AddLiquidity(
        address account,
        address token,
        uint256 amount,
        uint256 mintAmount
    );
    event RemoveLiquidity(
        address account,
        address token,
        uint256 vlpAmount,
        uint256 amountOut
    );
    event UpdateFundingRate(uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);
    event UpdateFeeManager(address feeManager);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(uint256 amount);
    event DecreasePoolAmount(uint256 amount);
    event IncreaseReservedAmount(uint256 amount);
    event DecreaseReservedAmount(uint256 amount);
    event vlpRateUpdated(uint256 _prevRate, uint256 _newRate);
    event StakeEvent(
        address account,
        address token,
        uint256 amount
    );
    // once the parameters are verified to be working correctly,
    // gov should be set to a timelock contract or a governance contract
    constructor(address _vlp, address _feeManager, address _vUSD) public {
        vlp = _vlp;
        feeManager = _feeManager;
        vusd = _vUSD;
    }

    function initialize(
        address _router,
        address _priceFeed,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external onlyOwner {
        require(!isInitialized, "already initialized");
        isInitialized = true;

        router = _router;
        priceFeed = _priceFeed;
        liquidationFeeUsd = _liquidationFeeUsd;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setVLPRate(uint256 _vlpRate) external onlyOwner {
        emit vlpRateUpdated(vlpRate, _vlpRate);
        vlpRate = _vlpRate;
    }

    function setVaultUtils(IVaultUtils _vaultUtils) external onlyOwner {
        vaultUtils = _vaultUtils;
    }

    function setCooldownDuration(uint256 _cooldownDuration) external onlyOwner {
        require(_cooldownDuration <= MAX_COOLDOWN_DURATION, "invalid _cooldownDuration");
        cooldownDuration = _cooldownDuration;
    }

    function allWhitelistedTokensLength() external override view returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function setInManagerMode(bool _inManagerMode) external override onlyOwner {
        inManagerMode = _inManagerMode;
    }

    function setManager(address _manager, bool _isManager) external override onlyOwner {
        isManager[_manager] = _isManager;
    }

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external override onlyOwner {
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setLiquidator(address _liquidator, bool _isActive) external override onlyOwner {
        isLiquidator[_liquidator] = _isActive;
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external override onlyOwner {
        isLeverageEnabled = _isLeverageEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    function setPriceFeed(address _priceFeed) external override onlyOwner {
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external override onlyOwner {
        require(_maxLeverage > MIN_LEVERAGE, "Max Leverage should be greater than Min Leverage");
        maxLeverage = _maxLeverage;
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external override onlyOwner {
        require(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, "taxBasisPoints should smaller than MAX");
        require(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, "stableTaxBasisPoints should be smaller than MAX");
        require(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "minBurnFeeBasisPoints should be smaller than MAX");
        require(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "marginFeeBasisPoints should be smaller than MAX");
        require(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, "liquidationFeeUsd should be smaller than MAX");
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        liquidationFeeUsd = _liquidationFeeUsd;
        minProfitTime = _minProfitTime;
        hasDynamicFees = _hasDynamicFees;
    }

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external override onlyOwner {
        require(_fundingInterval >= MIN_FUNDING_RATE_INTERVAL, "fundingInterval should be greater than MIN");
        require(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, "fundingRateFactor should be smaller than MAX");
        require(_stableFundingRateFactor <= MAX_FUNDING_RATE_FACTOR, "stableFundingRateFactor should be smaller than MAX");
        fundingInterval = _fundingInterval;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setRewardRate(uint256 _feeRewardsBasisPoints) external onlyOwner {
        feeRewardBasisPoints = _feeRewardsBasisPoints;
    }


    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external override onlyOwner {
        // increment token count for the first time
        if (!whitelistedTokens[_token] && _isStable) {
            whitelistedTokens[_token] = true;
            whitelistedTokenCount = whitelistedTokenCount.add(1);
            allWhitelistedTokens.push(_token);
        }
        tokenDecimals[_token] = _tokenDecimals;
        minProfitBasisPoints[_token] = _minProfitBps;
        stableTokens[_token] = _isStable;
        shortableTokens[_token] = _isShortable;

        // validate price feed
        getMaxPrice(_token);
    }

    function clearTokenConfig(address _token) external onlyOwner {
        require(whitelistedTokens[_token], "This token is not whitelisted");
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete minProfitBasisPoints[_token];
        delete stableTokens[_token];
        delete shortableTokens[_token];
        whitelistedTokenCount = whitelistedTokenCount.sub(1);
    }

    function _increaseReservedAmount(uint256 _amount) private {
        reservedAmounts = reservedAmounts.add(_amount);
        emit IncreaseReservedAmount(_amount);
    }

    function _decreaseReservedAmount(uint256 _amount) private {
        reservedAmounts = reservedAmounts.sub(_amount, "Vault: insufficient reserve");
        emit DecreaseReservedAmount(_amount);
    }

    function upgradeVault(address _newVault, address _token, uint256 _amount) external onlyOwner {
        _transferOut(_token, _amount, _newVault);
    }


    function withdrawFees(address _token, address _receiver) external override returns (uint256) {
        uint256 rewardAmount = (BASIS_POINTS_DIVISOR - feeRewardBasisPoints).mul((feeReserves - lastFeeReserves)).div(BASIS_POINTS_DIVISOR);
        lastFeeReserves = feeReserves;
        uint256 rewardTokenAmount = usdToTokenMin(_token, rewardAmount);
        IVUSD(vusd).burn(address(this), rewardAmount);
        _transferOut(_token, rewardTokenAmount, _receiver);
        return rewardAmount;
    }

    function increasePosition(address _account, address _indexToken, uint256 _amountIn, uint256 _sizeDelta, bool _isLong, uint256[] memory triggerPrices, address _refer) external override nonReentrant onlyRouter {
        updateCumulativeFundingRate(_indexToken);
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 price = _isLong ? getMaxPrice(_indexToken) : getMinPrice(_indexToken);
        if (triggerPrices[1] != 0 && triggerPrices[0] > price && price > triggerPrices[1]) {
            position.postionType = Type1.TP_SL;
            position.tpPrice = triggerPrices[0];
            position.slPrice = triggerPrices[1];
        } else if (triggerPrices[0] != 0 && triggerPrices[0] > price) {
            position.postionType = Type1.TP;
            position.tpPrice = triggerPrices[0];
        } else if (triggerPrices[1] != 0 && triggerPrices[1] < price) {
            position.postionType = Type1.SL;
            position.slPrice = triggerPrices[1];
        } else {
            position.postionType = Type1.MARKET;
        }
        
        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(_indexToken, position.size, position.averagePrice, _isLong, price, _sizeDelta, position.lastIncreasedTime);
        }
        position.refer = _refer;
        uint256 fee = _collectMarginFees(_account, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        position.collateral = position.collateral.add(_amountIn);
        position.collateral = position.collateral.sub(fee);
        position.entryFundingRate = cumulativeFundingRates;
        position.size = position.size.add(_sizeDelta);
        position.lastIncreasedTime = block.timestamp;
        vaultUtils.takeVUSDIn(_account, _refer, _amountIn, fee);
        validatePosition(position.size, position.collateral);
        validateLiquidation(_account, _indexToken, _isLong, true);
        // reserve tokens to pay profits on the position
        position.reserveAmount = position.reserveAmount.add(_sizeDelta);
        _increaseReservedAmount(_sizeDelta);

        if (_isLong) {
            // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
            // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
            // since (position.size - position.collateral) would have increased by `fee`
            // treat the deposited collateral as part of the pool
            _increasePoolAmount(_amountIn);
            // fees need to be deducted from the pool since fees are deducted from position.collateral
            // and collateral is treated as part of the pool
            _decreasePoolAmount(fee);
        } 

        emit IncreasePosition(key, _account, _indexToken, _amountIn, _sizeDelta, _isLong, price, position.postionType, triggerPrices[0], triggerPrices[1], fee);
        emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.reserveAmount, position.realisedPnl, price);
    }

    function decreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) external override nonReentrant onlyRouter returns (uint256) {
        return _decreasePosition(_account, _indexToken, _sizeDelta, _isLong);
    }

    function _decreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) private returns (uint256) {
        updateCumulativeFundingRate(_indexToken);
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];
        require(position.size > 0, "position size should be greather than zero");
        {
            uint256 reserveDelta = position.reserveAmount.mul(_sizeDelta).div(position.size);
            position.reserveAmount = position.reserveAmount.sub(reserveDelta);
            _decreaseReservedAmount(reserveDelta);
        }

        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(_account, _indexToken, _sizeDelta, _isLong);
        if (position.size != _sizeDelta) {
            position.entryFundingRate = cumulativeFundingRates;
            position.size = position.size.sub(_sizeDelta);
            validatePosition(position.size, position.collateral);
            validateLiquidation(_account, _indexToken, _isLong, true);
            uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
            emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.reserveAmount, position.realisedPnl, price);
        } else {
            emit ClosePosition(key, position.size, position.collateral, position.averagePrice, position.reserveAmount, position.realisedPnl);
            delete positions[key];
        }

        if (usdOut > 0) {
            if (_isLong) {
                _decreasePoolAmount(usdOut);
            }
            vaultUtils.takeVUSDOut(_account, position.refer, usdOut, usdOut.sub(usdOutAfterFee));

            return usdOutAfterFee;
        }
        return 0;
    }

    function liquidatePosition(address _account, address _indexToken, bool _isLong) external onlyPositionManager nonReentrant {
        includeAmmPrice = false;
        updateCumulativeFundingRate(_indexToken);
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        (uint256 liquidationState, uint256 marginFees) = validateLiquidation(_account, _indexToken, _isLong, false);
        require(liquidationState != 0, 'liquidate state shound be greater than zero');
        if (liquidationState == 2) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(_account, _indexToken, position.size, _isLong);
            includeAmmPrice = true;
            return;
        }
        feeReserves = feeReserves.add(marginFees);
        _decreaseReservedAmount(position.reserveAmount);
        if (_isLong) {
            _decreasePoolAmount(marginFees);
        }
        uint256 markPrice = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        emit LiquidatePosition(key, _account, _indexToken, _isLong, position.size, position.collateral, position.reserveAmount, position.realisedPnl, markPrice);
        if (!_isLong && marginFees < position.collateral) {
            uint256 remainingCollateral = position.collateral.sub(marginFees);
            _increasePoolAmount(remainingCollateral);
        }
        IVUSD(vusd).burn(address(this), position.collateral);
        delete positions[key];
        _decreasePoolAmount(liquidationFeeUsd);
        emit ClosePosition(key, position.size, position.collateral, position.averagePrice, position.reserveAmount, position.realisedPnl);
        // pay the fee receive using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
        feeReserves = feeReserves.add(liquidationFeeUsd);
        includeAmmPrice = true;
    }

    function triggerPosition(address _account, address _indexToken, bool _isLong) external onlyPositionManager nonReentrant {
                includeAmmPrice = false;
        updateCumulativeFundingRate(_indexToken);
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        bool triggerFlag = validateTrigger(_account, _indexToken, _isLong);
        require(triggerFlag, "validate trigger flag");
        _decreasePosition(_account, _indexToken, position.size, _isLong);
    }

    // validateLiquidation returns (state, fees)
    function validateLiquidation(address _account, address _indexToken, bool _isLong, bool _raise) public view returns (uint256, uint256) {
        return vaultUtils.validateLiquidation(_account, _indexToken, _isLong, _raise);
    }

        // validateLiquidation returns (state, fees)
    function validateTrigger(address _account, address _indexToken, bool _isLong) public view returns (bool) {
        return vaultUtils.validateTrigger(_account, _indexToken, _isLong);
    }


    function validatePosition(uint256 _size, uint256 _collateral) pure internal {
        if (_size == 0) {
            require(_collateral == 0, "collateral is not zero");
            return;
        }
        require(_size >= _collateral, "position size should be greater than collateral");
    }

    function getMaxPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, true, includeAmmPrice, useSwapPricing);
    }

    function getMinPrice(address _token) public override view returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, false, includeAmmPrice, useSwapPricing);
    }


    function tokenToUsdMin(address _token, uint256 _tokenAmount) public override view returns (uint256) {
        if (_tokenAmount == 0) { return 0; }
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenDecimals[_token];
        return _tokenAmount.mul(price).div(10 ** decimals);
    }

    function usdToTokenMax(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        return usdToToken(_token, _usdAmount, getMinPrice(_token));
    }

    function usdToTokenMin(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        return usdToToken(_token, _usdAmount, getMaxPrice(_token));
    }

    function usdToToken(address _token, uint256 _usdAmount, uint256 _price) public view returns (uint256) {
        if (_usdAmount == 0) { return 0; }
        uint256 decimals = tokenDecimals[_token];
        return _usdAmount.mul(10 ** decimals).div(_price);
    }

    function getPosition(address _account, address _indexToken, bool _isLong) public override view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0 ? uint256(position.realisedPnl) : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            position.entryFundingRate, // 3
            position.reserveAmount, // 4
            realisedPnl, // 5
            position.realisedPnl >= 0, // 6
            position.lastIncreasedTime // 7
        );
    }

    function getPositionKey(address _account, address _indexToken, bool _isLong) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _account,
            _indexToken,
            _isLong
        ));
    }

    function getPositionLeverage(address _account, address _indexToken, bool _isLong) public view returns (uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        require(position.collateral > 0, "collateral should be greater than zero");
        return position.size.mul(BASIS_POINTS_DIVISOR).div(position.collateral);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextAveragePrice(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _nextPrice, uint256 _sizeDelta, uint256 _lastIncreasedTime) internal view returns (uint256) {
        (bool hasProfit, uint256 delta) = getDelta(_indexToken, _size, _averagePrice, _isLong, _lastIncreasedTime);
        uint256 nextSize = _size.add(_sizeDelta);
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? nextSize.add(delta) : nextSize.sub(delta);
        } else {
            divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);
        }
        return _nextPrice.mul(nextSize).div(divisor);
    }

    function _transferIn(address _token, uint256 _amount) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        IERC20(_token).safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;

        return nextBalance.sub(prevBalance);
    }

    function _transferOut(address _token, uint256 _amount, address _receiver) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
    }

    function getPositionDelta(address _account, address _indexToken, bool _isLong) public view returns (bool, uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        return getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
    }

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) public override view returns (bool, uint256) {
        require(_averagePrice > 0, "average price should be greater than zero");
        uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price ? _averagePrice.sub(price) : price.sub(_averagePrice);
        uint256 delta = _size.mul(priceDelta).div(_averagePrice);

        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function _collectMarginFees(address _account, address _indexToken, bool _isLong, uint256 _sizeDelta, uint256 _size, uint256 _entryFundingRate) private returns (uint256) {
        uint256 feeUsd = getPositionFee(_account, _sizeDelta);

        uint256 fundingFee = getFundingFee(_account, _indexToken, _isLong, _size, _entryFundingRate);
        feeUsd = feeUsd.add(fundingFee);

        feeReserves = feeReserves.add(feeUsd);

        return feeUsd;
    }


    function getFundingFee(address _account, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) public view returns (uint256) {
        return vaultUtils.getFundingFee(_account, _indexToken, _isLong, _size, _entryFundingRate);
    }

    function getPositionFee(address _account, uint256 _sizeDelta) public view returns (uint256) {
        if (_sizeDelta == 0) { return 0; }
        if (isCustomFees[_account])
        {
            return _sizeDelta.mul(customFeePoints[_account]).div(BASIS_POINTS_DIVISOR);
        }
        return _sizeDelta.mul(marginFeeBasisPoints).div(BASIS_POINTS_DIVISOR);
    }

    function decreaseCollateral(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) internal {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];
        uint256 _collateralDelta = position.collateral.mul(_sizeDelta).div(position.size);
        emit DecreasePosition(key, _account, _indexToken, _collateralDelta, _sizeDelta, _isLong);
    }

    function _reduceCollateral(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];
        uint256 fee = _collectMarginFees(_account, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        bool hasProfit;
        uint256 adjustedDelta;

        // scope variables to avoid stack too deep errors
        {
        (bool _hasProfit, uint256 delta) = getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
        hasProfit = _hasProfit;
        // get the proportional change in pnl
        adjustedDelta = _sizeDelta.mul(delta).div(position.size);
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);
            // pay out realised profits from the pool amount for short positions
            if (!_isLong) {
                _decreasePoolAmount(adjustedDelta);
            }
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral.sub(adjustedDelta);

            // transfer realised losses to the pool for short positions
            // realised losses for long positions are not transferred here as
            // _increasePoolAmount was already called in increasePosition for longs
            if (!_isLong) {
                _increasePoolAmount(adjustedDelta);
            }

            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        decreaseCollateral(_account, _indexToken, _sizeDelta, _isLong);
        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut = usdOut.add(position.collateral);
            position.collateral = 0;
        } else {
            // reduce the position's collateral by _collateralDelta
            // transfer _collateralDelta out
            uint256 _collateralDelta = position.collateral.mul(_sizeDelta).div(position.size);
            usdOut = usdOut.add(_collateralDelta);
            position.collateral = position.collateral.sub(_collateralDelta);
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > fee) {
            usdOutAfterFee = usdOut.sub(fee);
        } else {
            position.collateral = position.collateral.sub(fee);
            if (_isLong) {
                _decreasePoolAmount(fee);
            }
        }
        emit UpdatePnl(key, hasProfit, adjustedDelta);
        return (usdOut, usdOutAfterFee);
    }

    function _increasePoolAmount(uint256 _amount) private {
        poolAmounts = poolAmounts.add(_amount);
        emit IncreasePoolAmount(_amount);
    }

    function _decreasePoolAmount(uint256 _amount) private {
        poolAmounts = poolAmounts.sub(_amount, "Vault: poolAmount exceeded");
        emit DecreasePoolAmount(_amount);
    }

    function addLiquidity(address _token, uint256 _amount) external nonReentrant {
        require(_amount > 0, "Vault: invalid _amount");
        uint256 usdAmount = tokenToUsdMin(_token, _amount);
        _transferIn(_token, _amount);
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(liquidityFeeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 liquidityUsdAmount = tokenToUsdMin(_token, afterFeeAmount);
        feeReserves = feeReserves.add(usdAmount.sub(liquidityUsdAmount));
        uint256 mintAmount = vlpRate.mul(liquidityUsdAmount).div(PRICE_PRECISION);
        liquidityAmount[_token][msg.sender] = liquidityAmount[_token][msg.sender].add(afterFeeAmount);
        IMintable(vlp).mint(msg.sender, mintAmount);
        lastAddedAt[msg.sender] = block.timestamp;
        emit AddLiquidity(msg.sender, _token, afterFeeAmount, liquidityUsdAmount);
    }

    function removeLiquidity(address _tokenOut, uint256 _vlpAmount, address _receiver) external nonReentrant {
        require(_vlpAmount > 0, "Vault: invalid _vlpAmount");
        require(lastAddedAt[msg.sender].add(cooldownDuration) <= block.timestamp, "cooldown duration not yet passed");
        IMintable(vlp).burn(msg.sender, _vlpAmount);
        uint256 usdAmount = _vlpAmount.mul(PRICE_PRECISION).div(vlpRate);
        uint256 amountOut = usdToTokenMax(_tokenOut, usdAmount);
        uint256 afterFeeAmount = amountOut.mul(BASIS_POINTS_DIVISOR.sub(liquidityFeeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 liquidityUsdAmount = tokenToUsdMin(_tokenOut, afterFeeAmount);
        feeReserves= feeReserves.add(usdAmount.sub(liquidityUsdAmount));
        liquidityAmount[_tokenOut][msg.sender] = liquidityAmount[_tokenOut][msg.sender].sub(amountOut);
        _transferOut(_tokenOut, afterFeeAmount, _receiver);
        emit RemoveLiquidity(msg.sender, _tokenOut, liquidityUsdAmount, amountOut);
    }

    function deposit(address _token, uint256 _amount) public {
        uint256 collateralDeltaUsd = tokenToUsdMin(_token, _amount);
        _transferIn(_token, _amount);
        _increasePoolAmount(collateralDeltaUsd);
        IVUSD(vusd).mint(address(msg.sender), collateralDeltaUsd);
    }

    function withdraw(address _token, address _account, uint256 _amount) public {
        uint256 collateralDelta = usdToTokenMin(_token, _amount);
        IVUSD(vusd).burn(address(msg.sender), _amount);
        _decreasePoolAmount(_amount);
        _transferOut(_token, collateralDelta, _account);
    }

    function setCustomFeeForUser(address _account, uint256 _feePoints, bool _isEnabled) external _onlyFeeManager() {
        isCustomFees[_account] = _isEnabled;
        customFeePoints[_account] = _feePoints;
    }

    function stake(address _account, address _rewardToken, uint256 _amount) external nonReentrant {
        require(_amount > 0, "invalid amount");
        IERC20(vlp).safeTransferFrom(_account, address(this), _amount);
        UserInfo storage user = userInfo[vlp][_account];
        updateReward(_account, _rewardToken);
        totalVLP = totalVLP.add(_amount);
        user.amount = user.amount.add(_amount);
        user.lastFeeReserves = feeReserves;
        emit StakeEvent(_account, vlp, _amount);
    }

    function unstake(address _account, address _rewardToken, uint256 _amount) external nonReentrant {
        IERC20(vlp).safeTransfer(_account, _amount);
        UserInfo storage user = userInfo[vlp][_account];
        require(user.amount > _amount, "user amount: invalid amount");
        require(totalVLP > _amount, "totalVLP: invalid amount");
        totalVLP = totalVLP.sub(_amount);
        updateReward(_account, _rewardToken);
        user.amount = user.amount.sub(_amount);
        user.lastFeeReserves = feeReserves;
    }

    function updateReward(address _account, address _rewardToken) internal {
        UserInfo memory user = userInfo[vlp][_account];
        if (totalVLP > 0) {
            uint256 rewardAmount = feeRewardBasisPoints.mul(feeReserves.sub(user.lastFeeReserves)).mul(user.amount).div(totalVLP).div(BASIS_POINTS_DIVISOR);
            if (rewardAmount > 0) {
                uint256 rewardTokenAmount = usdToTokenMin(_rewardToken, rewardAmount);
                IVUSD(vusd).burn(address(this), rewardAmount);
                _transferOut(_rewardToken, rewardTokenAmount, _account);
            }
        }
    }

    function updateCumulativeFundingRate(address _indexToken) public {
        bool shouldUpdate = vaultUtils.updateCumulativeFundingRate(_indexToken);
        if (!shouldUpdate) {
            return;
        }

        if (lastFundingTimes == 0) {
            lastFundingTimes = block.timestamp.div(fundingInterval).mul(fundingInterval);
            return;
        }

        if (lastFundingTimes.add(fundingInterval) > block.timestamp) {
            return;
        }

        uint256 fundingRate = getNextFundingRate();
        cumulativeFundingRates = cumulativeFundingRates.add(fundingRate);
        lastFundingTimes = block.timestamp.div(fundingInterval).mul(fundingInterval);

        emit UpdateFundingRate(cumulativeFundingRates);
    }


    function getNextFundingRate() public override view returns (uint256) {
        if (lastFundingTimes.add(fundingInterval) > block.timestamp) { return 0; }

        uint256 intervals = block.timestamp.sub(lastFundingTimes).div(fundingInterval);
        if (poolAmounts == 0) { return 0; }

        return stableFundingRateFactor.mul(reservedAmounts).mul(intervals).div(poolAmounts);
    }



    function setFeeManager(address _feeManager) external _onlyFeeManager() {
        feeManager = _feeManager;
        emit UpdateFeeManager(_feeManager);
    }

    modifier _onlyFeeManager() {
        require(feeManager == _msgSender(), "Ownable: caller is not the feeManager");
        _;
    }

    modifier onlyRouter() {
        require(_msgSender() == router, "Ownable: caller is not the Router");
        _;
    }

    modifier onlyPositionManager() {
        require(isManager[msg.sender], "PositionManager: forbidden");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVUSD {
    function balanceOf(address _account) external view returns (uint256);
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVault {
    function isInitialized() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);
    function router() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
     function getNextFundingRate() external view returns (uint256);
    function lastFundingTimes() external view returns (uint256);
    function reservedAmounts() external view returns (uint256);
    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external;
    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function increasePosition(address _account, address _indexToken, uint256 _amountIn, uint256 _sizeDelta, bool _isLong, uint256[] memory triggerPrices, address _refer) external;
    function decreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) external returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates() external view returns (uint256);
    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function feeRewardBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves() external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function poolAmounts() external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateTrigger(address _account, address _indexToken, bool _isLong) external view returns (bool);
    function validateLiquidation(address _account, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getPositionFee(address _account, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function takeVUSDIn(address _account, address _refer, uint256 _amount, uint256 _fee) external;
    function takeVUSDOut(address _account, address _refer, uint256 _amount, uint256 _fee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external;
    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external;
    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;
    function setPriceSampleSpace(uint256 _priceSampleSpace) external;
    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external;
    function getPrice(address _token, bool _maximise, bool _includeAmmPrice, bool _useSwapPricing) external view returns (uint256);
    function getAmmPrice(address _token) external view returns (uint256);
    function getPrimaryPrice(address _token, bool _maximise) external view returns (uint256);
    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}