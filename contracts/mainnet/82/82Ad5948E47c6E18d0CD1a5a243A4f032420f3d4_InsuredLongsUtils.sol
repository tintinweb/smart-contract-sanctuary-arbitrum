//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

enum OptionsState {
    Settled,
    Active,
    Unlocked
}

enum EpochState {
    InActive,
    BootStrapped,
    Expired,
    Paused
}

enum Contracts {
    QuoteToken,
    BaseToken,
    FeeDistributor,
    FeeStrategy,
    OptionPricing,
    PriceOracle,
    VolatilityOracle,
    Gov
}

enum VaultConfig {
    IvBoost,
    BlackoutWindow,
    FundingInterval,
    BaseFundingRate,
    UseDiscount
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {OptionsState, EpochState} from "./AtlanticPutsPoolEnums.sol";

struct EpochData {
    uint256 startTime;
    uint256 expiryTime;
    uint256 totalLiquidity;
    uint256 totalActiveCollateral;
    uint256 fundingRate;
    uint256 tickSize;
    MaxStrikesRange maxStrikesRange;
    EpochState state;
}

struct MaxStrikesRange {
    uint256 highest;
    uint256 lowest;
}

struct Checkpoint {
    uint256 startTime;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 borrowFeesAccrued;
    uint256 underlyingAccrued;
    uint256 totalLiquidity;
    uint256 liquidityBalance;
    uint256 activeCollateral;
}

struct EpochRewards {
    address[] rewardTokens;
    uint256[] amounts;
}

struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 unlockEntryTimestamp;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    OptionsState state;
    address user;
    address delegate;
}

struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
}

struct MaxStrike {
    uint256 maxStrike;
    uint256 activeCollateral;
    uint256[] rewardRates;
    mapping(uint256 => Checkpoint) checkpoints;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Contracts, VaultConfig, OptionsState} from "../AtlanticPutsPoolEnums.sol";

import {DepositPosition, OptionsPurchase, Checkpoint} from "../AtlanticPutsPoolStructs.sol";

interface IAtlanticPutsPool {
    function purchasePositionsCounter() external view returns (uint256);

    function currentEpoch() external view returns (uint256);

    function getOptionsPurchase(
        uint256 positionId
    ) external view returns (OptionsPurchase memory);

    function getEpochTickSize(uint256 _epoch) external view returns (uint256);

    function addresses(Contracts _contractType) external view returns (address);

    function getOptionsState(
        uint256 _purchaseId
    ) external view returns (OptionsState);

    function purchase(
        uint256 _strike,
        uint256 _amount,
        address _delegate,
        address _account
    ) external returns (uint256 purchaseId);

    function calculateFundingFees(
        uint256 _collateralAccess,
        uint256 _entryTimestamp
    ) external view returns (uint256 fees);

    function relockCollateral(
        uint256 purchaseId,
        uint256 relockAmount
    ) external;

    function unwind(uint256 purchaseId, uint256 unwindAmount) external;

    function calculatePurchaseFees(
        address account,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256 finalFee);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 premium);

    function unlockCollateral(
        uint256 purchaseId,
        address to
    ) external returns (uint256 unlockedCollateral);

    function getDepositPosition(
        uint256 positionId
    ) external view returns (DepositPosition memory);

    function strikeMulAmount(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 result);

    function totalSupply() external view returns (uint256);

    function getEpochStrikes(
        uint256 epoch
    ) external view returns (uint256[] memory maxStrikes);

    function getEpochCheckpoints(
        uint256 _epoch,
        uint256 _maxStrike
    ) external view returns (Checkpoint[] memory _checkpoints);

    function isWithinBlackoutWindow() external view returns (bool);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPositionRouter {
  function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

  function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

  function executeDecreasePosition(bytes32 key, address payable _executionFeeReceiver) external;

  function executeIncreasePosition(bytes32 key, address payable _executionFeeReceiver) external;

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { IVault } from "./IVault.sol";

interface IReader {
  function getMaxAmountIn(
    IVault _vault,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256);

  function getAmountOut(IVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256, uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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

    function updateCumulativeFundingRate(address _indexToken) external;

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

    function getTargetUsdgAmount(
        address _token
    ) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

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

    function setInPrivateLiquidationMode(
        bool _inPrivateLiquidationMode
    ) external;

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

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

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

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

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

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

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
        address /* _account */,
        address /* _collateralToken */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address /* _account */,
        address _collateralToken,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

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

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token) external view returns (uint256);
    function isAdjustmentAdditive(address _token) external view returns (bool);
    function setAdjustment(address _token, bool _isAdditive, uint256 _adjustmentBps) external;
    function setUseV2Pricing(bool _useV2Pricing) external;
    function setIsAmmEnabled(bool _isEnabled) external;
    function setIsSecondaryPriceEnabled(bool _isEnabled) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * NOTE: Modified to include symbols and decimals.
 */
interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IPositionRouter} from "../../external/gmx/interfaces-modified/IPositionRouter.sol";
import {IVaultPriceFeed} from "../../external/gmx/interfaces-modified/IVaultPriceFeed.sol";
import {IReader} from "../../external/gmx/interfaces-modified/IReader.sol";
import {IVault} from "../../external/gmx/interfaces-modified/IVault.sol";
import {IAtlanticPutsPool} from "../../atlantic-pools/interfaces/IAtlanticPutsPool.sol";
import {IInsuredLongsStrategy} from "./interfaces/IInsuredLongsStrategy.sol";
import {IDopexPositionManager} from "./interfaces/IDopexPositionManager.sol";
import {IERC20} from "../../interfaces/IERC20.sol";

import {OptionsPurchase} from "../../atlantic-pools/AtlanticPutsPoolStructs.sol";

import {Contracts} from "../../atlantic-pools/AtlanticPutsPoolEnums.sol";

contract InsuredLongsUtils {
    address private owner;

    IVault public vault;
    IPositionRouter public positionRouter;
    IReader public reader;

    uint256 private constant USDG_DECIMALS = 30;
    uint256 private constant STRIKE_DECIMALS = 8;
    uint256 private constant OPTIONS_TOKEN_DECIMALS = 18;
    uint256 private constant BPS_PRECISION = 100000;
    uint256 private constant SWAP_BPS_PRECISION = 10000;
    uint256 private feebufferBps = 5;

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

    /**
     * @notice Get leverage of a existing position on GMX.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @return _positionLeverage
     */
    function getPositionLeverage(
        address _positionManager,
        address _indexToken
    ) public view returns (uint256 _positionLeverage) {
        return
            vault.getPositionLeverage(
                _positionManager,
                _indexToken,
                _indexToken,
                true
            );
    }

    /**
     * @notice Calculate leverage from collateral and size.
     * @param _collateralToken Address of the collateral token or input
     *                         token.
     * @param _indexToken      Address of the index token longing on.
     * @param _collateralDelta  Amount of collateral in collateral token decimals.
     * @param _sizeDelta        Size of the position usd in 1e30 decimals.
     * @return _positionLeverage
     */
    function getPositionLeverage(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) public view returns (uint256 _positionLeverage) {
        _positionLeverage =
            ((_sizeDelta * 1e30) /
                calculateCollateral(
                    _collateralToken,
                    _indexToken,
                    _collateralDelta,
                    _sizeDelta
                )) /
            1e26;
    }

    /**
     * @notice Calculate leverage using collateral and size.
     *         Note that this is an approximate amount and does
     *         not consider fees.
     * @param _size            Size of the position in 1e30 usd decimals
     * @param _collateral      Collateral amount of the position in its own
     *                         token decimals.
     * @param _collateralToken Address of the collateral token.
     * @return _leverage
     */
    function calculateLeverage(
        uint256 _size,
        uint256 _collateral,
        address _collateralToken
    ) external view returns (uint256 _leverage) {
        return
            ((_size * 10 ** (USDG_DECIMALS)) /
                vault.tokenToUsdMin(_collateralToken, _collateral)) /
            10 ** (USDG_DECIMALS - 4);
    }

    /**
     * @notice Gets the liquidation price of a existing GMX position.
     *         Sums up the usd value of the collateral, position fee,
     *         funding fee and liquidation fee that needs to be depleted
     *         first to get liquidated. Note that this is an slightly
     *         approximate value as GMX looks for other different conditions
     *         before liquidating a position but this return fn ensures it
     *         returns a safer value considering all fees.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @return liquidationPrice
     */
    function getLiquidationPrice(
        address _positionManager,
        address _indexToken
    ) public view returns (uint256 liquidationPrice) {
        (uint256 size, uint256 collateral, uint256 entryPrice, , , , , ) = vault
            .getPosition(_positionManager, _indexToken, _indexToken, true);

        uint256 fees = getFundingFee(
            _indexToken,
            _positionManager,
            address(0)
        ) +
            getPositionFee(size) +
            vault.liquidationFeeUsd();

        uint256 priceDelta = ((collateral - fees) * entryPrice) / size;
        liquidationPrice = entryPrice - priceDelta;
    }

    /**
     * @notice Calculate liquidation price from collateral delta
     *         and size delta. considers position fee and liquidation
     *         fee. note that this does not consider funding fees
     *         and should be used to fetch a pre-determined liquidation
     *         price.
     * @param _collateralToken  Address of the input token or collateral token.
     * @param _indexToken       Address of the index token to long for.
     * @param _collateralDelta  Amount of collateral in collateral token decimals.
     * @param _sizeDelta        Size of the position usd in 1e30 decimals.
     * @return liquidationPrice
     */
    function getLiquidationPrice(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) public view returns (uint256 liquidationPrice) {
        uint256 entryPrice = vault.getMaxPrice(_indexToken);
        _collateralDelta = calculateCollateral(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta
        );
        uint256 fees = (getPositionFee(_sizeDelta) + vault.liquidationFeeUsd());
        uint256 priceDelta = ((_collateralDelta - fees) * entryPrice) /
            _sizeDelta;
        liquidationPrice = entryPrice - priceDelta;
    }

    /**
     * @notice Calculate collateral amount in 1e30 usd decimal
     *         given the input amount of token in its own decimals.
     *         considers position fee and swap fees before calculating
     *         output amount.
     * @param _collateralToken  Address of the input token or collateral token.
     * @param _indexToken       Address of the index token to long for.
     * @param _collateralAmount Amount of collateral in collateral token decimals.
     * @param _size             Size of the position usd in 1e30 decimals.
     * @return collateral
     */
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

    /**
     * @notice Get size of GMX position amount in usd 1e30 decimals.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @return size
     */
    function getPositionSize(
        address _positionManager,
        address _indexToken
    ) public view returns (uint256 size) {
        (size, , , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
    }

    /**
     * @notice Get collateral of GMX position in usd 1e30 decimals.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @return collateral
     */
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

    /**
     * @notice Get funding fee charge-able to a position on GMX.
     * @param _indexToken      Address of the index token of the position.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _convertTo       Address of the token to convert to.
     *                         input zero address to get return value
     *                         in usd 1e30 decimal amount.
     * @return fundingFee
     */
    function getFundingFee(
        address _indexToken,
        address _positionManager,
        address _convertTo
    ) public view returns (uint256 fundingFee) {
        (uint256 size, , , uint256 entryFundingRate, , , , ) = vault
            .getPosition(_positionManager, _indexToken, _indexToken, true);

        uint256 fundingRate = (vault.cumulativeFundingRates(_indexToken) +
            vault.getNextFundingRate(_indexToken)) - entryFundingRate;

        fundingFee = (size * fundingRate) / 1000000;

        if (_convertTo != address(0)) {
            fundingFee = vault.usdToTokenMin(_convertTo, fundingFee);
        }
    }

    /**
     * @notice Get a put strike above liquidation to purchase for insuring
     *         a GMX long position.
     * @param _atlanticPool       Address of the atlantic pool options are
     *                            expected to be purchased from.
     * @param _liquidationPrice   Liquidation price of the GMX position.
     */
    function getEligiblePutStrike(
        address _atlanticPool,
        uint256 _liquidationPrice
    ) public view returns (uint256 eligiblePutStrike) {
        IAtlanticPutsPool atlanticPool = IAtlanticPutsPool(_atlanticPool);

        uint256 epoch = atlanticPool.currentEpoch();
        uint256 tickSize = atlanticPool.getEpochTickSize(epoch);
        uint256 noise = _liquidationPrice % tickSize;

        eligiblePutStrike = _liquidationPrice - noise;

        if (eligiblePutStrike <= _liquidationPrice) {
            eligiblePutStrike = eligiblePutStrike + tickSize;
        }
    }

    /**
     * @notice Get a put strike above liquidation to purchase for insuring
     *         a GMX long position.
     * @param _atlanticPool       Address of the atlantic pool options are
     *                            expected to be purchased from.
     * @param _collateralToken    Address of the input token or collateral
     *                            token used when opening a position.
     * @param _indexToken         Address of the index token of.
     * @param _collateralDelta    Amount of the collateral in collateral to-
     *                            ken decimals.
     * @param _sizeDelta          Size of the position in usd 1e30 decimals.
     * @return eligiblePutStrike
     */
    function getEligiblePutStrike(
        address _atlanticPool,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external view returns (uint256 eligiblePutStrike) {
        IAtlanticPutsPool atlanticPool = IAtlanticPutsPool(_atlanticPool);

        uint256 epoch = atlanticPool.currentEpoch();
        uint256 tickSize = atlanticPool.getEpochTickSize(epoch);

        uint256 liquidationPrice = getLiquidationPrice(
            _collateralToken,
            _indexToken,
            _collateralDelta,
            _sizeDelta
        ) / 1e22;

        uint256 noise = liquidationPrice % tickSize;

        eligiblePutStrike = liquidationPrice - noise;

        if (eligiblePutStrike < liquidationPrice) {
            eligiblePutStrike = eligiblePutStrike + tickSize;
        }
    }

    /**
     * @notice Get amount of underlying tokens required to unwind an option
     *         purchased from an atlantic pool.
     * @param _atlanticPool Address of the atlantic pool.
     * @param _purchaseId   ID of the options purchase.
     * @return _cost
     */
    function getAtlanticUnwindCosts(
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (uint256 _cost) {
        (, _cost) = getOptionsPurchase(_atlanticPool, _purchaseId);
    }

    /**
     * @notice Get amount of _outToken tokens received when a position
     *         is closed.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the GMX position's index token.
     * @param _outToken        Address of the token to convert the receiva-
     *                         able amount to.
     * @return amountOut
     */
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
            if (adjustDelta > usdOut) {
                return 0;
            }
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

    /**
     * @notice Check if collateral amount is sufficient
     *         to open a long position.
     * @param _collateralSize  Amount of collateral in its own decimals
     * @param _size            Total Size of the position in usd 1e30
     *                         decimals.
     * @param _collateralToken Address of the collateral token or input
     *                         token.
     * @param _indexToken      Address of the index token longing on.
     */
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
        return
            vault.tokenToUsdMin(_indexToken, _collateralSize) <
            getPositionFee(_size) + vault.liquidationFeeUsd();
    }

    /**
     * @notice Check if a position has enough collateral to
     *         unwind options.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @param _atlanticPool    Address of the atlantic pool.
     * @param _purchaseId      ID of the options purchase.
     */
    function validateUnwind(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (bool) {
        return
            getUsdOutForUnwindWithFee(
                _positionManager,
                _indexToken,
                _atlanticPool,
                _purchaseId
            ) < getPositionCollateral(_positionManager, _indexToken);
    }

    /**
     * @notice Get usd 30 decimal amount required to remove
     *         from a gmx position to receive required
     *         unwind amount for options.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @param _atlanticPool    Address of the atlantic pool.
     * @param _purchaseId      ID of the options purchase.
     * @return _usdOut
     */
    function getUsdOutForUnwindWithFee(
        address _positionManager,
        address _indexToken,
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (uint256 _usdOut) {
        _usdOut =
            vault.tokenToUsdMin(
                _indexToken,
                getAtlanticUnwindCosts(_atlanticPool, _purchaseId)
            ) +
            vault.usdToTokenMin(
                _indexToken,
                getFundingFee(_indexToken, _positionManager, address(0)) +
                    getPositionFee(
                        getPositionSize(_positionManager, _indexToken)
                    )
            );
    }

    /**
     * @notice Get the swap path on exiting strategy based on spot
     *         price and put strike of the option purchased.
     * @param _atlanticPool Address of the atlantic pool.
     * @param _purchaseId   ID of the options purchase.
     * @return path
     */
    function getStrategyExitSwapPath(
        address _atlanticPool,
        address _indexToken,
        address _positionManager,
        uint256 _purchaseId
    ) external view returns (address[] memory path) {
        (uint256 strike, ) = getOptionsPurchase(_atlanticPool, _purchaseId);
        IAtlanticPutsPool pool = IAtlanticPutsPool(_atlanticPool);
        address indexToken = pool.addresses(Contracts.BaseToken);

        uint256 fees = (getFundingFee(
            _indexToken,
            _positionManager,
            address(0)
        ) + getPositionFee(getPositionSize(_positionManager, _indexToken))) /
            10 ** (USDG_DECIMALS - STRIKE_DECIMALS);

        strike =
            ((strike + fees) *
                (BPS_PRECISION +
                    IDopexPositionManager(_positionManager).minSlippageBps())) /
            BPS_PRECISION;

        if (strike >= getPrice(pool.addresses(Contracts.BaseToken))) {
            path = get1TokenSwapPath(indexToken);
        } else {
            path = get2TokenSwapPath(
                indexToken,
                pool.addresses(Contracts.QuoteToken)
            );
        }
    }

    /**
     * @notice Gets amount of options of a strike required
     *         to insure a collateral amount in 1e30 decimals
     * @param _putStrike          Strike of atlantic put option.
     * @param _sizeCollateralDiff difference of size and collateral
     *                            of the GMX position.
     * @param _quoteToken          Quote token of the atlantic pool
     *                            or address of the collateral token.
     */
    function getRequiredAmountOfOptionsForInsurance(
        uint256 _putStrike,
        uint256 _sizeCollateralDiff,
        address _quoteToken
    ) public view returns (uint256 optionsAmount) {
        require(_sizeCollateralDiff != 0, "Utils: GMX Invalid Position");
        require(_putStrike != 0);
        uint256 multiplierForDecimals = 10 **
            (OPTIONS_TOKEN_DECIMALS - IERC20(_quoteToken).decimals());
        optionsAmount =
            ((vault.usdToTokenMin(_quoteToken, _sizeCollateralDiff) *
                10 ** (STRIKE_DECIMALS)) / _putStrike) *
            multiplierForDecimals;
    }

    /**
     * @notice Get required amount of options for insuring
     *         a long position on gmx based on size and collateral
     *         delta.
     * @param _putStrike Strike of atlantic put option.
     * @param _positionManager Address of the position manager
     *                         delegating the user.
     * @param _indexToken      Address of the index token of
     *                         the long position.
     * @param _quoteToken      Quote token of the atlantic pool
     *                         or address of the collateral token.
     * @return optionsAmount
     */
    function getRequiredAmountOfOptionsForInsurance(
        uint256 _putStrike,
        address _positionManager,
        address _indexToken,
        address _quoteToken
    ) external view returns (uint256 optionsAmount) {
        (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );
        optionsAmount = getRequiredAmountOfOptionsForInsurance(
            _putStrike,
            size - collateral,
            _quoteToken
        );
    }

    /**
     * @notice Get amount of collateral that can be accessed or unlocked
     *         from atlantic options.
     * @param _atlanticPool      Address of the atlantic pool.
     * @param _purchaseId        ID of the options purchase.
     * @return _collateralAccess Amount of collateral in quote token
     *                           decimals of the atlantic pool.
     */
    function getCollateralAccess(
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (uint256 _collateralAccess) {
        (uint256 strike, uint256 amount) = getOptionsPurchase(
            _atlanticPool,
            _purchaseId
        );
        _collateralAccess = IAtlanticPutsPool(_atlanticPool).strikeMulAmount(
            strike,
            amount
        );
    }

    function getMarginFees(
        address _positionManager,
        address _indexToken,
        address _convertTo
    ) external view returns (uint256 fees) {
        fees = vault.usdToTokenMin(
            _convertTo,
            getFundingFee(_indexToken, _positionManager, address(0)) +
                getPositionFee(getPositionSize(_positionManager, _indexToken))
        );
    }

    /**
     * @notice Get amount required to swap from one get an expected amount
     *         of another token on GMX vault.
     * @param _amountOut Expected amount out.
     * @param _slippage  Bps of slippage in 1e5 decimals to consider.
     * @param _tokenOut  Address of the token to swap to.
     * @param _tokenIn   Address of the token to swap from.
     */

    function getAmountIn(
        uint256 _amountOut,
        uint256 _slippage,
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
        ) + (_slippage / 10);

        uint256 amountInWithFees = (amountIn * SWAP_BPS_PRECISION) /
            (SWAP_BPS_PRECISION - feeBps);
        _amountIn = vault.adjustForDecimals(
            amountInWithFees,
            _tokenOut,
            _tokenIn
        );
    }

    /**
     * @notice Calculate the swap fee basis points to be used to calculate
     *         swap fees on GMX vault.
     * @param _usdgAmount USDG amount of the token in 1e18 decimals.
     * @param _tokenIn    Input token or token to be swapped.
     * @param _tokenOut   Output token or token to be swapped to.
     * @return feeBasisPoints
     */
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

    /**
     * @notice Fetch reciept like data type of an active option purchased
     *         from an atlantic pool.
     * @param _atlanticPool Address of the atlantic pool the option was
     *                      purchased from.
     * @param _purchaseId   ID of the option purchase.
     */
    function getOptionsPurchase(
        address _atlanticPool,
        uint256 _purchaseId
    ) public view returns (uint256, uint256) {
        OptionsPurchase memory options = IAtlanticPutsPool(_atlanticPool)
            .getOptionsPurchase(_purchaseId);
        return (options.optionStrike, options.optionsAmount);
    }

    /**
     * @notice Fetch the unique key created when a position manager
     *         calls GMX position router contract to create an order
     *         the return key is directly linked to the order in the GMX
     *         position router contract.
     * @param  _positionManager Address of the position manager
     * @param  _isIncrease      Whether to create an order to increase
     *                          collateral size of a position or decrease
     *                          it.
     * @return key
     */
    function getPositionKey(
        address _positionManager,
        bool _isIncrease
    ) public view returns (bytes32 key) {
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

    /**
     * @notice Create and return an array of 1 item.
     * @param _token Address of the token.
     * @return path
     */
    function get1TokenSwapPath(
        address _token
    ) public pure returns (address[] memory path) {
        path = new address[](1);
        path[0] = _token;
    }

    /**
     * @notice Create and return an 2 item array of addresses used for
     *         swapping.
     * @param _token1 Token in or input token.
     * @param _token2 Token out or output token.
     * @return path
     */
    function get2TokenSwapPath(
        address _token1,
        address _token2
    ) public pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;
    }

    /**
     * @notice Fetch price of a token from GMX's pricefeed contract.
     * @param _token  Address of the token to fetch price for.
     * @return _price Price of the token in 1e8 decimals.
     */
    function getPrice(address _token) public view returns (uint256 _price) {
        return
            IVaultPriceFeed(vault.priceFeed()).getPrice(
                _token,
                false,
                false,
                false
            ) / 10 ** (USDG_DECIMALS - STRIKE_DECIMALS);
    }

    /**
     * @notice Get fee charged on opening and closing a position on gmx.
     * @param  _size  Total size of the position in 30 decimal usd precision value.
     * @return feeUsd Fee in 30 decimal usd precision value.
     */
    function getPositionFee(
        uint256 _size
    ) public view returns (uint256 feeUsd) {
        address gov = vault.gov();
        uint256 marginFeeBps = IVault(gov).marginFeeBasisPoints();
        feeUsd = _size - ((_size * (10000 - marginFeeBps)) / 10000);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Utils: Forbidden");
        _;
    }

    function validateDecreaseCollateralDelta(
        address _positionManager,
        address _indexToken,
        uint256 _collateralDelta
    ) external view returns (bool valid) {
        (uint256 size, uint256 collateral, , , , , , ) = vault.getPosition(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );

        (bool hasProfit, uint256 delta) = vault.getPositionDelta(
            _positionManager,
            _indexToken,
            _indexToken,
            true
        );

        uint256 feeUsd = getFundingFee(
            _indexToken,
            _positionManager,
            address(0)
        ) + getPositionFee(size);

        collateral -= _collateralDelta;
        delta += feeUsd;

        uint256 newLeverage = (size * 10000) / collateral;

        valid = true;

        if (vault.maxLeverage() < newLeverage) {
            valid = false;
        }

        if (!hasProfit && delta > collateral) {
            valid = false;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Structs
struct IncreaseOrderParams {
    address[] path;
    address indexToken;
    uint256 collateralDelta;
    uint256 positionSizeDelta;
    uint256 acceptablePrice;
    bool isLong;
}

struct DecreaseOrderParams {
    IncreaseOrderParams orderParams;
    address receiver;
    bool withdrawETH;
}

interface IDopexPositionManager {
    function enableAndCreateIncreaseOrder(
        IncreaseOrderParams calldata params,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _user
    ) external payable;

    function increaseOrder(IncreaseOrderParams memory _increaseOrderParams) external payable;

    function decreaseOrder(DecreaseOrderParams calldata _decreaseorderParams) external payable;

    function release() external;

    function minSlippageBps() external view returns (uint256);

    function setStrategyController(address _strategy) external;

    function withdrawTokens(
        address[] calldata _tokens,
        address _receiver
    ) external returns (uint256[] memory _amounts);

    function strategyControllerTransfer(
        address _token,
        address _to,
        uint256 amount
    ) external;

    function lock() external;

    function slippage() external view returns (uint256);

    event IncreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event DecreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );
    event ReferralCodeSet(bytes32 _newReferralCode);
    event Released();
    event Locked();
    event TokensWithdrawn(address[] tokens, uint256[] amounts);
    event SlippageSet(uint256 _slippage);
    event CallbackSet(address _callback);
    event FactorySet(address _factory);
    event StrategyControllerSet(address _strategy);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IInsuredLongsStrategy {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool
    ) external payable;

    function positionsCount() external view returns (uint256);

    function getStrategyPosition(
        uint256 _positionId
    )
        external
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            address,
            bool,
            ActionState
        );

    function createExitStrategyOrder(
        uint256 _positionId,
        bool _exitLongPosition
    ) external payable;

    function createIncreaseManagedPositionOrder(
        uint256 _positionId
    ) external payable;

    event StrategyEnabled(
        uint256 positionId,
        uint256 putstrike,
        uint256 optionsAmount
    );
    event OrderCreated(uint256 positionId, ActionState _newState);
    event StrategyFeesCollected(uint256 fees);
    event MaxLeverageSet(uint256 _maxLeverage);
    event KeeperHandleWindowSet(uint256 _window);
    event KeeperSet(address _keeper, bool setAs);
    event AddressesSet(
        address _feeDistributor,
        address _utils,
        address _positionManagerFactory,
        address _gov,
        address _feeStrategy
    );

    error InsuredLongsStrategyError(uint256 _errorCode);

    enum ActionState {
        None, // 0
        Settled, // 1
        Active, // 2
        IncreasePending, // 3
        Increased, // 4
        EnablePending, // 5
        ExitPending // 6
    }

    struct StrategyPosition {
        uint256 expiry;
        uint256 atlanticsPurchaseId;
        address indexToken;
        address collateralToken;
        address user;
        bool keepCollateral;
        ActionState state;
    }
}