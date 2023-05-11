// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/ITradePair.sol";
import "../interfaces/ITradePairHelper.sol";

contract TradePairHelper is ITradePairHelper {
    /**
     * @notice Returns the current prices (min and max) of the given TradePairs
     * @param tradePairs_ The TradePairs to get the current prices of
     * @return prices PricePairy[] of min and max prices
     */
    function pricesOf(ITradePair[] calldata tradePairs_) external view override returns (PricePair[] memory prices) {
        prices = new PricePair[](tradePairs_.length);
        for (uint256 i; i < tradePairs_.length; ++i) {
            (int256 minPrice, int256 maxPrice) = tradePairs_[i].getCurrentPrices();

            prices[i] = PricePair(minPrice, maxPrice);
        }
    }

    function detailsOfPositions(address[] calldata tradePairs_, uint256[][] calldata positionIds_)
        external
        view
        returns (PositionDetails[][] memory positionDetails)
    {
        require(
            tradePairs_.length == positionIds_.length,
            "TradePairHelper::batchPositionDetails: TradePair and PositionId arrays must be of same length"
        );

        positionDetails = new PositionDetails[][](positionIds_.length);

        for (uint256 t; t < tradePairs_.length; ++t) {
            positionDetails[t] = new PositionDetails[](positionIds_[t].length);

            for (uint256 i; i < positionIds_[t].length; ++i) {
                positionDetails[t][i] = ITradePair(tradePairs_[t]).detailsOfPosition(positionIds_[t][i]);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IFeeManager.sol";
import "./ILiquidityPoolAdapter.sol";
import "./IPriceFeedAdapter.sol";
import "./ITradeManager.sol";
import "./IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Struct with details of a position, returned by the detailsOfPosition function
 * @custom:member id the position id
 * @custom:member margin the margin of the position
 * @custom:member volume the entry volume of the position
 * @custom:member size the size of the position
 * @custom:member leverage the size of the position
 * @custom:member isShort bool if the position is short
 * @custom:member entryPrice The entry price of the position
 * @custom:member markPrice The (current) mark price of the position
 * @custom:member bankruptcyPrice the bankruptcy price of the position
 * @custom:member equity the current net equity of the position
 * @custom:member PnL the current net PnL of the position
 * @custom:member totalFeeAmount the totalFeeAmount of the position
 * @custom:member currentVolume the current volume of the position
 */
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 liquidationPrice;
    int256 currentBorrowFeeAmount;
    int256 currentFundingFeeAmount;
}

/**
 * @notice Struct with a minimum and maximum price
 * @custom:member minPrice the minimum price
 * @custom:member maxPrice the maximum price
 */
struct PricePair {
    int256 minPrice;
    int256 maxPrice;
}

interface ITradePair {
    /* ========== ENUMS ========== */

    enum PositionAlterationType {
        partiallyClose,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);

    event ClosedPosition(uint256 id, int256 closePrice);

    event LiquidatedPosition(uint256 indexed id, address indexed liquidator);

    event AlteredPosition(
        PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
    );

    event UpdatedFeesOfPosition(uint256 id, int256 totalFeeAmount, uint256 lastNetMargin);

    event DepositedOpenFees(address user, uint256 amount, uint256 positionId);

    event DepositedCloseFees(address user, uint256 amount, uint256 positionId);

    event FeeOvercollected(int256 amount);

    event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);

    event LiquidityGapWarning(uint256 amount);

    event RealizedPnL(
        address indexed maker,
        uint256 indexed positionId,
        int256 realizedPnL,
        int256 realizedBorrowFeeAmount,
        int256 realizedFundingFeeAmount
    );

    event UpdatedFeeIntegrals(int256 borrowFeeIntegral, int256 longFundingFeeIntegral, int256 shortFundingFeeIntegral);

    event SetTotalVolumeLimit(uint256 totalVolumeLimit);

    event DepositedBorrowFees(uint256 amount);

    event RegisteredProtocolPnL(int256 protocolPnL, uint256 payout);

    event SetBorrowFeeRate(int256 borrowFeeRate);

    event SetMaxFundingFeeRate(int256 maxFundingFeeRate);

    event SetMaxExcessRatio(int256 maxExcessRatio);

    event SetLiquidatorReward(uint256 liquidatorReward);

    event SetMinLeverage(uint128 minLeverage);

    event SetMaxLeverage(uint128 maxLeverage);

    event SetMinMargin(uint256 minMargin);

    event SetVolumeLimit(uint256 volumeLimit);

    event SetFeeBufferFactor(int256 feeBufferFactor);

    event SetTotalAssetAmountLimit(uint256 totalAssetAmountLimit);

    event SetPriceFeedAdapter(address priceFeedAdapter);

    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function collateral() external view returns (IERC20);

    function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);

    function priceFeedAdapter() external view returns (IPriceFeedAdapter);

    function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);

    function userManager() external view returns (IUserManager);

    function feeManager() external view returns (IFeeManager);

    function tradeManager() external view returns (ITradeManager);

    function positionIsLiquidatable(uint256 positionId) external view returns (bool);

    function positionIsLiquidatableAtPrice(uint256 positionId, int256 price) external view returns (bool);

    function getCurrentFundingFeeRates() external view returns (int256, int256);

    function getCurrentPrices() external view returns (int256, int256);

    function positionIsShort(uint256) external view returns (bool);

    function collateralToPriceMultiplier() external view returns (uint256);

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);

    function liquidatorReward() external view returns (uint256);

    function maxLeverage() external view returns (uint128);

    function minLeverage() external view returns (uint128);

    function minMargin() external view returns (uint256);

    function volumeLimit() external view returns (uint256);

    function totalVolumeLimit() external view returns (uint256);

    function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function overcollectedFees() external view returns (int256);

    function feeBuffer() external view returns (int256, int256);

    function positionIdToWhiteLabel(uint256) external view returns (address);

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
        external
        returns (uint256 positionId);

    function closePosition(address maker, uint256 positionId) external;

    function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;

    function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;

    function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;

    function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;

    function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;

    function liquidatePosition(address liquidator, uint256 positionId) external;

    /* ========== CORE FUNCTIONS - FEES ========== */

    function syncPositionFees() external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        string memory name,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) external;

    function setBorrowFeeRate(int256 borrowFeeRate) external;

    function setMaxFundingFeeRate(int256 fee) external;

    function setMaxExcessRatio(int256 maxExcessRatio) external;

    function setLiquidatorReward(uint256 liquidatorReward) external;

    function setMinLeverage(uint128 minLeverage) external;

    function setMaxLeverage(uint128 maxLeverage) external;

    function setMinMargin(uint256 minMargin) external;

    function setVolumeLimit(uint256 volumeLimit) external;

    function setFeeBufferFactor(int256 feeBufferAmount) external;

    function setTotalVolumeLimit(uint256 totalVolumeLimit) external;

    function setPriceFeedAdapter(IPriceFeedAdapter priceFeedAdapter) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ITradePair.sol";

interface ITradePairHelper {
    /* ========== VIEW FUNCTIONS ========== */

    function pricesOf(ITradePair[] calldata tradePairs) external view returns (PricePair[] memory prices);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFeeManager {
    /* ========== EVENTS ============ */

    event ReferrerFeesPaid(address indexed referrer, address indexed asset, uint256 amount, address user);

    event WhiteLabelFeesPaid(address indexed whitelabel, address indexed asset, uint256 amount, address user);

    event UpdatedReferralFee(uint256 newReferrerFee);

    event UpdatedStakersFeeAddress(address stakersFeeAddress);

    event UpdatedDevFeeAddress(address devFeeAddress);

    event UpdatedInsuranceFundFeeAddress(address insuranceFundFeeAddress);

    event SetWhitelabelFee(address indexed whitelabelAddress, uint256 feeSize);

    event SetCustomReferralFee(address indexed referrer, uint256 feeSize);

    event SpreadFees(
        address asset,
        uint256 stakersFeeAmount,
        uint256 devFeeAmount,
        uint256 insuranceFundFeeAmount,
        uint256 liquidityPoolFeeAmount,
        address user
    );

    /* ========== CORE FUNCTIONS ========== */

    function depositOpenFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositCloseFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositBorrowFees(address asset, uint256 amount) external;

    /* ========== VIEW FUNCTIONS ========== */

    function calculateUserOpenFeeAmount(address user, uint256 amount) external view returns (uint256);

    function calculateUserOpenFeeAmount(address user, uint256 amount, uint256 leverage)
        external
        view
        returns (uint256);

    function calculateUserExtendToLeverageFeeAmount(
        address user,
        uint256 margin,
        uint256 volume,
        uint256 targetLeverage
    ) external view returns (uint256);

    function calculateUserCloseFeeAmount(address user, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct LiquidityPoolConfig {
    address poolAddress;
    uint96 percentage;
}

interface ILiquidityPoolAdapter {
    /* ========== EVENTS ========== */

    event PayedOutLoss(address indexed tradePair, uint256 loss);

    event DepositedProfit(address indexed tradePair, uint256 profit);

    event UpdatedMaxPayoutProportion(uint256 maxPayoutProportion);

    event UpdatedLiquidityPools(LiquidityPoolConfig[] liquidityPools);

    /* ========== CORE FUNCTIONS ========== */

    function requestLossPayout(uint256 profit) external returns (uint256);

    function depositProfit(uint256 profit) external;

    function depositFees(uint256 fee) external;

    /* ========== VIEW FUNCTIONS ========== */

    function availableLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeedAggregator.sol";

/**
 * @title IPriceFeedAdapter
 * @notice Provides a way to convert an asset amount to a collateral amount and vice versa
 * Needs two PriceFeedAggregators: One for asset and one for collateral
 */
interface IPriceFeedAdapter {
    function name() external view returns (string memory);

    /* ============ DECIMALS ============ */

    function collateralDecimals() external view returns (uint256);

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);

    /* ============ USD Conversion ============ */

    function assetToUsdMin(uint256 assetAmount) external view returns (uint256);

    function assetToUsdMax(uint256 assetAmount) external view returns (uint256);

    function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);

    /* ============ PRICE ============ */

    function markPriceMin() external view returns (int256);

    function markPriceMax() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IController.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Parameters for opening a position
 * @custom:member tradePair The trade pair to open the position on
 * @custom:member margin The amount of margin to use for the position
 * @custom:member leverage The leverage to open the position with
 * @custom:member isShort Whether the position is a short position
 * @custom:member referrer The address of the referrer or zero
 * @custom:member whitelabelAddress The address of the whitelabel or zero
 */
struct OpenPositionParams {
    address tradePair;
    uint256 margin;
    uint256 leverage;
    bool isShort;
    address referrer;
    address whitelabelAddress;
}

/**
 * @notice Parameters for closing a position
 * @custom:member tradePair The trade pair to close the position on
 * @custom:member positionId The id of the position to close
 */
struct ClosePositionParams {
    address tradePair;
    uint256 positionId;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member proportion the proportion of the position to close
 * @custom:member leaveLeverageFactor the leaveLeverage / takeProfit factor
 */
struct PartiallyClosePositionParams {
    address tradePair;
    uint256 positionId;
    uint256 proportion;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member removedMargin The amount of margin to remove
 */
struct RemoveMarginFromPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 removedMargin;
}

/**
 * @notice Parameters for adding margin to a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 */
struct AddMarginToPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
}

/**
 * @notice Parameters for extending a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 * @custom:member addedLeverage The leverage used on the addedMargin
 */
struct ExtendPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
    uint256 addedLeverage;
}

/**
 * @notice Parameters for extending a position to a target leverage
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member targetLeverage the target leverage to close to
 */
struct ExtendPositionToLeverageParams {
    address tradePair;
    uint256 positionId;
    uint256 targetLeverage;
}

/**
 * @notice Constraints to constraint the opening, alteration or closing of a position
 * @custom:member deadline The deadline for the transaction
 * @custom:member minPrice a minimum price for the transaction
 * @custom:member maxPrice a maximum price for the transaction
 */
struct Constraints {
    uint256 deadline;
    int256 minPrice;
    int256 maxPrice;
}

/**
 * @notice Parameters for opening a position
 * @custom:member params The parameters for opening a position
 * @custom:member constraints The constraints for opening a position
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct OpenPositionOrder {
    OpenPositionParams params;
    Constraints constraints;
    uint256 salt;
}

/**
 * @notice Parameters for closing a position
 * @custom:member params The parameters for closing a position
 * @custom:member constraints The constraints for closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ClosePositionOrder {
    ClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member params The parameters for partially closing a position
 * @custom:member constraints The constraints for partially closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct PartiallyClosePositionOrder {
    PartiallyClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position
 * @custom:member params The parameters for extending a position
 * @custom:member constraints The constraints for extending a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionOrder {
    ExtendPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position to leverage
 * @custom:member params The parameters for extending a position to leverage
 * @custom:member constraints The constraints for extending a position to leverage
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionToLeverageOrder {
    ExtendPositionToLeverageParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters foradding margin to a position
 * @custom:member params The parameters foradding margin to a position
 * @custom:member constraints The constraints foradding margin to a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct AddMarginToPositionOrder {
    AddMarginToPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member params The parameters for removing margin from a position
 * @custom:member constraints The constraints for removing margin from a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct RemoveMarginFromPositionOrder {
    RemoveMarginFromPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice UpdateData for updatable contracts like the UnlimitedPriceFeed
 * @custom:member updatableContract The address of the updatable contract
 * @custom:member data The data to update the contract with
 */
struct UpdateData {
    address updatableContract;
    bytes data;
}

/**
 * @notice Struct to store tradePair and positionId together.
 * @custom:member tradePair the address of the tradePair
 * @custom:member positionId the positionId of the position
 */
struct TradeId {
    address tradePair;
    uint96 positionId;
}

interface ITradeManager {
    /* ========== EVENTS ========== */

    event PositionOpened(address indexed tradePair, uint256 indexed id);

    event PositionClosed(address indexed tradePair, uint256 indexed id);

    event PositionPartiallyClosed(address indexed tradePair, uint256 indexed id, uint256 proportion);

    event PositionLiquidated(address indexed tradePair, uint256 indexed id);

    event PositionExtended(address indexed tradePair, uint256 indexed id, uint256 addedMargin, uint256 addedLeverage);

    event PositionExtendedToLeverage(address indexed tradePair, uint256 indexed id, uint256 targetLeverage);

    event MarginAddedToPosition(address indexed tradePair, uint256 indexed id, uint256 addedMargin);

    event MarginRemovedFromPosition(address indexed tradePair, uint256 indexed id, uint256 removedMargin);

    /* ========== CORE FUNCTIONS - LIQUIDATIONS ========== */

    function liquidatePosition(address tradePair, uint256 positionId, UpdateData[] calldata updateData) external;

    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData
    ) external returns (bool[][] memory didLiquidate);

    /* =========== VIEW FUNCTIONS ========== */

    function detailsOfPosition(address tradePair, uint256 positionId) external view returns (PositionDetails memory);

    function positionIsLiquidatable(address tradePair, uint256 positionId) external view returns (bool);

    function canLiquidatePositions(address[] calldata tradePairs, uint256[][] calldata positionIds)
        external
        view
        returns (bool[][] memory canLiquidate);

    function canLiquidatePositionsAtPrices(
        address[] calldata tradePairs_,
        uint256[][] calldata positionIds_,
        int256[] calldata prices_
    ) external view returns (bool[][] memory canLiquidate);

    function getCurrentFundingFeeRates(address tradePair) external view returns (int256, int256);

    function totalVolumeLimitOfTradePair(address tradePair_) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/// @notice Enum for the different fee tiers
enum Tier {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX
}

interface IUserManager {
    /* ========== EVENTS ========== */

    event FeeSizeUpdated(uint256 indexed feeIndex, uint256 feeSize);

    event FeeVolumeUpdated(uint256 indexed feeIndex, uint256 feeVolume);

    event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);

    event UserManualTierUpdated(address indexed user, Tier tier, uint256 validUntil);

    event UserReferrerAdded(address indexed user, address referrer);

    /* =========== CORE FUNCTIONS =========== */

    function addUserVolume(address user, uint40 volume) external;

    function setUserReferrer(address user, address referrer) external;

    function setUserManualTier(address user, Tier tier, uint32 validUntil) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external;

    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external;

    /* ========== VIEW FUNCTIONS ========== */

    function getUserFee(address user) external view returns (uint256);

    function getUserReferrer(address user) external view returns (address referrer);
}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";

/**
 * @title IPriceFeedAggregator
 * @notice Aggreates two or more price feeds into min and max prices
 */
interface IPriceFeedAggregator {
    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function minPrice() external view returns (int256);

    function maxPrice() external view returns (int256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addPriceFeed(IPriceFeed) external;

    function removePriceFeed(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IController {
    /* ========== EVENTS ========== */

    event TradePairAdded(address indexed tradePair);

    event LiquidityPoolAdded(address indexed liquidityPool);

    event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);

    event PriceFeedAdded(address indexed priceFeed);

    event UpdatableAdded(address indexed updatable);

    event TradePairRemoved(address indexed tradePair);

    event LiquidityPoolRemoved(address indexed liquidityPool);

    event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);

    event PriceFeedRemoved(address indexed priceFeed);

    event UpdatableRemoved(address indexed updatable);

    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event OrderExecutorAdded(address indexed orderExecutor);

    event OrderExecutorRemoved(address indexed orderExecutor);

    event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Is trade pair registered
    function isTradePair(address tradePair) external view returns (bool);

    /// @notice Is liquidity pool registered
    function isLiquidityPool(address liquidityPool) external view returns (bool);

    /// @notice Is liquidity pool adapter registered
    function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);

    /// @notice Is price fee adapter registered
    function isPriceFeed(address priceFeed) external view returns (bool);

    /// @notice Is contract updatable
    function isUpdatable(address contractAddress) external view returns (bool);

    /// @notice Is Signer registered
    function isSigner(address signer) external view returns (bool);

    /// @notice Is order executor registered
    function isOrderExecutor(address orderExecutor) external view returns (bool);

    /// @notice Reverts if trade pair inactive
    function checkTradePairActive(address tradePair) external view;

    /// @notice Returns order reward for collateral token
    function orderRewardOfCollateral(address collateral) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds the trade pair to the registry
     */
    function addTradePair(address tradePair) external;

    /**
     * @notice Adds the liquidity pool to the registry
     */
    function addLiquidityPool(address liquidityPool) external;

    /**
     * @notice Adds the liquidity pool adapter to the registry
     */
    function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Adds the price feed to the registry
     */
    function addPriceFeed(address priceFeed) external;

    /**
     * @notice Adds updatable contract to the registry
     */
    function addUpdatable(address) external;

    /**
     * @notice Adds signer to the registry
     */
    function addSigner(address) external;

    /**
     * @notice Adds order executor to the registry
     */
    function addOrderExecutor(address) external;

    /**
     * @notice Removes the trade pair from the registry
     */
    function removeTradePair(address tradePair) external;

    /**
     * @notice Removes the liquidity pool from the registry
     */
    function removeLiquidityPool(address liquidityPool) external;

    /**
     * @notice Removes the liquidity pool adapter from the registry
     */
    function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Removes the price feed from the registry
     */
    function removePriceFeed(address priceFeed) external;

    /**
     * @notice Removes updatable from the registry
     */
    function removeUpdatable(address) external;

    /**
     * @notice Removes signer from the registry
     */
    function removeSigner(address) external;

    /**
     * @notice Removes order executor from the registry
     */
    function removeOrderExecutor(address) external;

    /**
     * @notice Sets order reward for collateral token
     */
    function setOrderRewardOfCollateral(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IPriceFeed
 * @notice Gets the last and previous price of an asset from a price feed
 * @dev The price must be returned with 8 decimals, following the USD convention
 */
interface IPriceFeed {
    /* ========== VIEW FUNCTIONS ========== */

    function price() external view returns (int256);
}