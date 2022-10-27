/**
 *Submitted for verification at Arbiscan on 2022-10-26
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPositionRouter {
    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePosition(
        bytes32 key,
        address payable _executionFeeReceiver
    ) external;

    function executeIncreasePosition(
        bytes32 key,
        address payable _executionFeeReceiver
    ) external;

    // AKA open position /  add to position
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable;

    // AKA close position /  remove from position
    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable;

    function decreasePositionsIndex(address) external view returns (uint256);

    function increasePositionsIndex(address) external view returns (uint256);

    function getRequestKey(address, uint256) external view returns (bytes32);

    function minExecutionFee() external view returns (uint256);
}

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;
}

interface IVault {
    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    function updateCumulativeFundingRate(
        address _collateralToken,
        address _indexToken
    ) external;

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) external view returns (uint256);

    function positions(bytes32) external view returns (Position memory);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(address _token)
        external
        view
        returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router)
        external
        view
        returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token)
        external
        view
        returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode)
        external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

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

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _token, address _receiver)
        external
        returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function sellUSDG(address _token, address _receiver)
        external
        returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount)
        external
        view
        returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token)
        external
        view
        returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token)
        external
        view
        returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount)
        external
        view
        returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

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

    function getPositionFee(
        address, /* _account */
        address, /* _collateralToken */
        address, /* _indexToken */
        bool, /* _isLong */
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address, /* _account */
        address _collateralToken,
        address, /* _indexToken */
        bool, /* _isLong */
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(address _token, uint256 _usdAmount)
        external
        view
        returns (uint256);

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);
}

interface IReader {
    function getMaxAmountIn(
        IVault _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        IVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);
}

struct Addresses {
    address quoteToken;
    address baseToken;
    address feeDistributor;
    address feeStrategy;
    address optionPricing;
    address priceOracle;
    address volatilityOracle;
}

struct VaultState {
    // Settlement price set on expiry
    uint256 settlementPrice;
    // Timestamp at which the epoch expires
    uint256 expiryTime;
    // Start timestamp of the epoch
    uint256 startTime;
    // Whether vault has been bootstrapped
    bool isVaultReady;
    // Whether vault is expired
    bool isVaultExpired;
}

struct VaultConfiguration {
    // Weights influencing collateral utilization rate
    uint256 collateralUtilizationWeight;
    // Base funding rate
    uint256 baseFundingRate;
    // Intervals to increase funding
    uint256 fundingInterval;
    // Rate of funding increment
    uint256 fundingRateIncrement;
    // Delay tolerance for edge cases
    uint256 expireDelayTolerance;
}

struct Checkpoint {
    uint256 startTime;
    uint256 totalLiquidity;
    uint256 totalLiquidityBalance;
    uint256 activeCollateral;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 fundingAccrued;
    uint256 underlyingAccrued;
}

struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 fundingRate;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    address user;
}

struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 timestamp;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
}

interface IAtlanticPutsPool {
    function addresses() external view returns (Addresses memory);

    // Deposits collateral as a writer with a specified max strike for the next epoch
    function deposit(uint256 maxStrike, address user)
        external
        payable
        returns (bool);

    // Purchases an atlantic for a specified strike
    function purchase(
        uint256 strike,
        uint256 amount,
        address user
    ) external returns (uint256);

    // Unlocks collateral from an atlantic by depositing underlying. Callable by dopex managed contract integrations.
    function unlockCollateral(uint256, address to) external returns (uint256);

    // Gracefully exercises an atlantic, sends collateral to integrated protocol,
    // underlying to writer and charges an unwind fee as well as remaining funding fees
    // to the option holder/protocol
    function unwind(uint256) external returns (uint256);

    // Re-locks collateral into an atlatic option. Withdraws underlying back to user, sends collateral back
    // from dopex managed contract to option, deducts remainder of funding fees.
    // Handles exceptions where collateral may get stuck due to failures in other protocols.
    function relockCollateral(uint256)
        external
        returns (uint256 collateralCollected);

    function calculatePnl(
        uint256 price,
        uint256 strike,
        uint256 amount
    ) external returns (uint256);

    function calculatePremium(uint256, uint256) external view returns (uint256);

    function calculatePurchaseFees(uint256, uint256)
        external
        view
        returns (uint256);

    function settle(uint256 purchaseId, address receiver)
        external
        returns (uint256 pnl);

    function epochTickSize(uint256 epoch) external view returns (uint256);

    function calculateFundingTillExpiry(uint256 totalCollateral)
        external
        view
        returns (uint256);

    function eligiblePutPurchaseStrike(
        uint256 liquidationPrice,
        uint256 optionStrikeOffset
    ) external pure returns (uint256);

    function checkpointIntervalTime() external view returns (uint256);

    function getEpochHighestMaxStrike(uint256 _epoch)
        external
        view
        returns (uint256 _highestMaxStrike);

    function calculateFunding(uint256 totalCollateral)
        external
        view
        returns (uint256 funding);

    function calculateFunding(uint256 totalCollateral, uint256 epoch)
        external
        view
        returns (uint256 funding);

    function calculateUnwindFees(uint256 underlyingAmount)
        external
        view
        returns (uint256);

    function calculateSettlementFees(
        uint256 settlementPrice,
        uint256 pnl,
        uint256 amount
    ) external view returns (uint256);

    function getUsdPrice() external view returns (uint256);

    function getEpochSettlementPrice(uint256 _epoch)
        external
        view
        returns (uint256 _settlementPrice);

    function currentEpoch() external view returns (uint256);

    function getOptionsPurchase(uint256 _tokenId)
        external
        view
        returns (OptionsPurchase memory);

    function getDepositPosition(uint256 _tokenId)
        external
        view
        returns (DepositPosition memory);

    function depositIdCount() external view returns (uint256);

    function purchaseIdCount() external view returns (uint256);

    function getEpochCheckpoints(uint256, uint256)
        external
        view
        returns (Checkpoint[] memory);

    function epochVaultStates(uint256 _epoch)
        external
        view
        returns (VaultState memory);

    function vaultConfiguration()
        external
        view
        returns (VaultConfiguration memory);

    function getEpochStrikes(uint256 _epoch)
        external
        view
        returns (uint256[] memory _strike_s);

    function getUnwindAmount(uint256 _optionsAmount, uint256 _optionStrike)
        external
        view
        returns (uint256 unwindAmount);

    function strikeMulAmount(uint256 _strike, uint256 _amount)
        external
        view
        returns (uint256);

    function isWithinExerciseWindow() external view returns (bool);

    function setPrivateMode(bool _mode) external;

    function getNextFundingRate() external view returns (uint256);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract DopexInsuredLongsUtils {
    address public owner;

    IVault public vault;
    IPositionRouter public positionRouter;
    IReader public reader;

    uint256 private constant USDG_DECIMALS = 30;
    uint256 private constant STRIKE_DECIMALS = 8;
    uint256 private constant OPTIONS_TOKEN_DECIMALS = 18;
    uint256 private constant BPS_PRECISION = 100000;
    uint256 private constant SWAP_BPS_PRECISION = 10000;
    uint256 public feebufferBps = 5;

    event NewOwnerSet(address _newOwner, address _olderOwner);

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit NewOwnerSet(_newOwner, msg.sender);
    }

    function setAddresses(
        address _vault,
        address _positionRouter,
        address _reader
    ) external onlyOwner {
        vault = IVault(_vault);
        positionRouter = IPositionRouter(_positionRouter);
        reader = IReader(_reader);
    }

    function getPositionLeverage(address _positionManager, address _indexToken)
        public
        view
        returns (uint256)
    {
        return
            vault.getPositionLeverage(
                _positionManager,
                _indexToken,
                _indexToken,
                true
            );
    }

    function getLiquidationPrice(address _positionManager, address _indexToken)
        public
        view
        returns (uint256 liquidationPrice)
    {
        uint256 leverage = getPositionLeverage(_positionManager, _indexToken);

        (uint256 size, , uint256 entryPrice, , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
        uint256 marginFees = getFundingFee(
            _indexToken,
            _positionManager,
            address(0)
        ) + getPositionFee(size);
        liquidationPrice =
            entryPrice -
            (
                ((entryPrice * 10**USDG_DECIMALS) /
                    (leverage * 10**(USDG_DECIMALS - 4)))
            ) +
            marginFees;
    }

    function getLiquidationPrice(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) public view returns (uint256 liquidationPrice) {
        uint256 markPrice = getPrice(_indexToken) * 1e22;
        uint256 marginFees = getPositionFee(_sizeDelta);
        uint256 collateralUsd = calculateCollateral(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta
        );
        uint256 leverage = (_sizeDelta * 1e30) / collateralUsd;
        liquidationPrice =
            (markPrice - ((markPrice * 1e30) / leverage)) +
            marginFees;
        liquidationPrice =
            liquidationPrice /
            10**(USDG_DECIMALS - STRIKE_DECIMALS);
    }

    function calculateCollateral(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _size
    ) public view returns (uint256 collateral) {
        uint256 marginFees = getPositionFee(_size);
        if (_collateralToken != _indexToken) {
            (collateral, ) = reader.getAmountOut(
                vault,
                _collateralToken,
                _indexToken,
                _collateralAmount
            );
            collateral = vault.tokenToUsdMin(_indexToken, collateral);
        } else {
            collateral = vault.tokenToUsdMin(
                _collateralToken,
                _collateralAmount
            );
        }
        require(marginFees < collateral, "Utils: Fees exceed collateral");
        collateral -= marginFees;
    }

    function getPositionSize(address _positionManager, address _indexToken)
        public
        view
        returns (uint256 size)
    {
        (size, , , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
    }

    function getPositionCollateral(
        address _positionManager,
        address _indexToken
    ) public view returns (uint256 collateral) {
        (, collateral, , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
    }

    function getFundingFee(
        address _indexToken,
        address _positionManager,
        address _convertTo
    ) public view returns (uint256 fundingFee) {
        (uint256 size, , , uint256 entryFundingRate, , , , ) = vault
            .getPosition(_positionManager, _indexToken, _indexToken, true);
        uint256 currentCummulativeFundingRate = vault.cumulativeFundingRates(
            _indexToken
        ) + vault.getNextFundingRate(_indexToken);
        if (currentCummulativeFundingRate != 0) {
            fundingFee =
                (size * (currentCummulativeFundingRate - entryFundingRate)) /
                1000000;
        }
        if (fundingFee != 0) {
            if (_convertTo != address(0)) {
                fundingFee = vault.usdToTokenMin(_convertTo, fundingFee);
            }
        }
    }

    function getEligblePutStrike(
        address _atlanticPool,
        uint256 _liquidationPrice
    ) public view returns (uint256 eligiblePutStrike) {
        IAtlanticPutsPool atlanticPool = IAtlanticPutsPool(_atlanticPool);
        uint256 tickSize = atlanticPool.epochTickSize(
            atlanticPool.currentEpoch()
        );
        uint256 noise = _liquidationPrice % tickSize;
        eligiblePutStrike = _liquidationPrice - noise;
        if (_liquidationPrice > eligiblePutStrike) {
            eligiblePutStrike = eligiblePutStrike + tickSize;
        }
    }

    function getAtlanticPutOptionCosts(
        address _atlanticPool,
        uint256 _strike,
        uint256 _amount
    ) public view returns (uint256 _cost) {
        IAtlanticPutsPool pool = IAtlanticPutsPool(_atlanticPool);
        _cost =
            pool.calculatePremium(_strike, _amount) +
            pool.calculatePurchaseFees(_strike, _amount);
    }

    function getAtlanticUnwindCosts(
        address _atlanticPool,
        uint256 _purchaseId,
        bool _unwindable
    ) public view returns (uint256 _cost) {
        (, uint256 strike, uint256 optionsAmount, , ) = getOptionsPurchase(
            _atlanticPool,
            _purchaseId
        );
        IAtlanticPutsPool pool = IAtlanticPutsPool(_atlanticPool);
        uint256 unwindAmount = _unwindable
            ? pool.getUnwindAmount(optionsAmount, strike)
            : optionsAmount;
        _cost = unwindAmount + pool.calculateUnwindFees(optionsAmount);
    }

    function getAmountReceivedOnExitPosition(
        address _positionManager,
        address _indexToken,
        address _outToken
    ) external view returns (uint256 amountOut) {
        (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );

        uint256 usdOut = collateral -
            (getFundingFee(_indexToken, _positionManager, address(0)) +
                getPositionFee(size));

        (bool hasProfit, uint256 delta) = vault.getPositionDelta(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
        uint256 adjustDelta = (size * delta) / size;
        if (hasProfit) {
            usdOut += adjustDelta;
        } else {
            usdOut -= adjustDelta;
        }
        amountOut = vault.usdToTokenMin(_indexToken, usdOut);
        if (_outToken != address(0)) {
            (amountOut, ) = reader.getAmountOut(
                vault,
                _indexToken,
                _outToken,
                amountOut
            );
        }
    }

    function validateIncreaseExecution(
        uint256 _collateralSize,
        uint256 _size,
        address _collateralToken,
        address _indexToken
    ) public view returns (bool) {
        if (_collateralToken != _indexToken) {
            (_collateralSize, ) = reader.getAmountOut(
                vault,
                _collateralToken,
                _indexToken,
                _collateralSize
            );
        }
        uint256 fee = vault.usdToTokenMin(_indexToken, getPositionFee(_size));
        return _collateralSize < fee;
    }

    function validateUnwind(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (bool) {
        uint256 unwindUsd = getUsdOutForUnwindWithFee(
            _positionManager,
            _indexToken,
            _atlanticPool,
            _purchaseId
        );
        uint256 collateralUsd = getPositionCollateral(
            _positionManager,
            _indexToken
        );
        return unwindUsd < collateralUsd;
    }

    function getUsdOutForUnwindWithFee(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (uint256 _usdOut) {
        uint256 size = getPositionSize(_positionManager, _indexToken);
        uint256 unwindCost = getAtlanticUnwindCosts(
            _atlanticPool,
            _purchaseId,
            true
        );
        uint256 fees = vault.usdToTokenMin(
            _indexToken,
            getFundingFee(_indexToken, _positionManager, address(0)) +
                getPositionFee(size)
        );
        _usdOut = vault.tokenToUsdMin(_indexToken, unwindCost) + fees;
    }

    function getStrategyExitSwapPath(address _atlanticPool, uint256 _purchaseId)
        external
        view
        returns (address[] memory path)
    {
        (, uint256 strike, , , ) = getOptionsPurchase(
            _atlanticPool,
            _purchaseId
        );
        IAtlanticPutsPool pool = IAtlanticPutsPool(_atlanticPool);
        address indexToken = pool.addresses().baseToken;
        address collateralToken = pool.addresses().quoteToken;
        uint256 currentPrice = getPrice(pool.addresses().baseToken);

        if (currentPrice <= strike) {
            path = get1TokenSwapPath(indexToken);
        } else {
            path = get2TokenSwapPath(indexToken, collateralToken);
        }
    }

    function calculateInsuranceOptionsAmount(
        address _collateralToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _putStrike
    ) public view returns (uint256 optionsAmount) {
        uint256 leveragedCollateral = vault.usdToTokenMin(
            _collateralToken,
            _sizeDelta - _collateralDelta
        );
        uint256 tokenDecimals = IERC20(_collateralToken).decimals();
        optionsAmount =
            (leveragedCollateral *
                10 **
                    ((STRIKE_DECIMALS + OPTIONS_TOKEN_DECIMALS) -
                        tokenDecimals)) /
            _putStrike;
    }

    function getRequiredAmountOfOptionsForInsurance(
        uint256 _putStrike,
        address _positionManager,
        address _indexToken,
        address _quoteToken
    ) public view returns (uint256 optionsAmount) {
        (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
        require(size > 0, "Utils: GMX Invalid Position");
        uint256 quoteTokenAmount = vault.usdToTokenMin(
            _quoteToken,
            size - collateral
        );
        uint256 multiplierForDecimals = 10 **
            (OPTIONS_TOKEN_DECIMALS - IERC20(_quoteToken).decimals());
        optionsAmount =
            ((quoteTokenAmount * 10**(STRIKE_DECIMALS)) / _putStrike) *
            multiplierForDecimals;
    }

    function getCollateralAccess(address atlanticPool, uint256 _purchaseId)
        public
        view
        returns (uint256 _collateralAccess)
    {
        (, uint256 strike, uint256 amount, , ) = getOptionsPurchase(
            atlanticPool,
            _purchaseId
        );
        _collateralAccess = IAtlanticPutsPool(atlanticPool).strikeMulAmount(
            strike,
            amount
        );
    }

    function calculateLeverage(
        uint256 _size,
        uint256 _collateral,
        address _collateralToken
    ) external view returns (uint256 _leverage) {
        return
            ((_size * 10**(USDG_DECIMALS)) /
                vault.tokenToUsdMin(_collateralToken, _collateral)) /
            10**(USDG_DECIMALS - 4);
    }

    function getRelockAmount(address atlanticPool, uint256 _purchaseId)
        public
        view
        returns (uint256 relockAmount)
    {
        IAtlanticPutsPool pool = IAtlanticPutsPool(atlanticPool);
        (
            ,
            uint256 strike,
            uint256 amount,
            uint256 fundingRate,

        ) = getOptionsPurchase(atlanticPool, _purchaseId);
        uint256 collateralAccess = pool.strikeMulAmount(strike, amount);
        uint256 funding = pool.calculateFunding(collateralAccess, fundingRate);
        relockAmount = collateralAccess + funding;
    }

    function getAmountIn(
        uint256 _amountOut,
        address _tokenOut,
        address _tokenIn
    ) public view returns (uint256 _amountIn) {
        uint256 amountIn = (_amountOut * vault.getMaxPrice(_tokenOut)) /
            vault.getMinPrice(_tokenIn);
        uint256 usdgAmount = (amountIn * vault.getMaxPrice(_tokenOut)) / 1e30;
        usdgAmount = vault.adjustForDecimals(
            usdgAmount,
            _tokenIn,
            vault.usdg()
        );
        uint256 feeBps = _getSwapFeeBasisPoints(
            usdgAmount,
            _tokenIn,
            _tokenOut
        ) + 5;
        uint256 amountInWithFees = (amountIn * SWAP_BPS_PRECISION) /
            (SWAP_BPS_PRECISION - feeBps);
        _amountIn = vault.adjustForDecimals(
            amountInWithFees,
            _tokenOut,
            _tokenIn
        );
    }

    function _getSwapFeeBasisPoints(
        uint256 _usdgAmount,
        address _tokenIn,
        address _tokenOut
    ) private view returns (uint256 feeBasisPoints) {
        uint256 baseBps = vault.swapFeeBasisPoints(); // swapFeeBasisPoints
        uint256 taxBps = vault.taxBasisPoints(); // taxBasisPoints
        uint256 feesBasisPoints0 = vault.getFeeBasisPoints(
            _tokenIn,
            _usdgAmount,
            baseBps,
            taxBps,
            true
        );
        uint256 feesBasisPoints1 = vault.getFeeBasisPoints(
            _tokenOut,
            _usdgAmount,
            baseBps,
            taxBps,
            false
        );
        // use the higher of the two fee basis points
        feeBasisPoints = feesBasisPoints0 > feesBasisPoints1
            ? feesBasisPoints0
            : feesBasisPoints1;
    }

    function getOptionsPurchase(address _atlanticPool, uint256 purchaseId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        OptionsPurchase memory options = IAtlanticPutsPool(_atlanticPool)
            .getOptionsPurchase(purchaseId);
        return (
            options.epoch,
            options.optionStrike,
            options.optionsAmount,
            options.fundingRate,
            options.user
        );
    }

    function getPositionKey(address _positionManager, bool _isIncrease)
        public
        view
        returns (bytes32 key)
    {
        if (_isIncrease) {
            key = positionRouter.getRequestKey(
                _positionManager,
                positionRouter.increasePositionsIndex(_positionManager)
            );
        } else {
            key = positionRouter.getRequestKey(
                _positionManager,
                positionRouter.decreasePositionsIndex(_positionManager)
            );
        }
    }

    function get1TokenSwapPath(address _token)
        public
        pure
        returns (address[] memory path)
    {
        path = new address[](1);
        path[0] = _token;
    }

    function get2TokenSwapPath(address _token1, address _token2)
        public
        pure
        returns (address[] memory path)
    {
        path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
    }

    function getPrice(address _token) public view returns (uint256 _price) {
        return
            IVaultPriceFeed(vault.priceFeed()).getPrice(
                _token,
                false,
                false,
                false
            ) / 10**(USDG_DECIMALS - STRIKE_DECIMALS);
    }

    function getPositionFee(uint256 _size)
        public
        view
        returns (uint256 feeUsd)
    {
        address gov = vault.gov();
        uint256 marginFeeBps = IVault(gov).marginFeeBasisPoints();
        feeUsd = _size - ((_size * (10000 - marginFeeBps)) / 10000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Utils: Forbidden");
        _;
    }
}