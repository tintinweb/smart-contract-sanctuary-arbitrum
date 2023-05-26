// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // AdlUtils errors
    error InvalidSizeDeltaForAdl(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error AdlNotEnabled();

    // Bank errors
    error SelfTransferNotSupported(address receiver);
    error InvalidNativeTokenSender(address msgSender);

    // CallbackUtils errors
    error MaxCallbackGasLimitExceeded(uint256 callbackGasLimit, uint256 maxCallbackGasLimit);

    // Config errors
    error InvalidBaseKey(bytes32 baseKey);
    error InvalidFeeFactor(bytes32 baseKey, uint256 value);

    // Timelock errors
    error ActionAlreadySignalled();
    error ActionNotSignalled();
    error SignalTimeNotYetPassed(uint256 signalTime);
    error InvalidTimelockDelay(uint256 timelockDelay);
    error MaxTimelockDelayExceeded(uint256 timelockDelay);
    error InvalidFeeReceiver(address receiver);
    error InvalidOracleSigner(address receiver);

    // DepositStoreUtils errors
    error DepositNotFound(bytes32 key);

    // DepositUtils errors
    error EmptyDeposit();
    error EmptyDepositAmounts();

    // ExecuteDepositUtils errors
    error MinMarketTokens(uint256 received, uint256 expected);
    error EmptyDepositAmountsAfterSwap();
    error InvalidPoolValueForDeposit(int256 poolValue);
    error InvalidSwapOutputToken(address outputToken, address expectedOutputToken);

    // AdlHandler errors
    error AdlNotRequired(int256 pnlToPoolFactor, uint256 maxPnlFactorForAdl);
    error InvalidAdl(int256 nextPnlToPoolFactor, int256 pnlToPoolFactor);
    error PnlOvercorrected(int256 nextPnlToPoolFactor, uint256 minPnlFactorForAdl);

    // ExchangeUtils errors
    error RequestNotYetCancellable(uint256 requestAge, uint256 requestExpirationAge, string requestType);

    // OrderHandler errors
    error OrderNotUpdatable(uint256 orderType);
    error InvalidKeeperForFrozenOrder(address keeper);

    // FeatureUtils errors
    error DisabledFeature(bytes32 key);

    // FeeHandler errors
    error InvalidClaimFeesInput(uint256 marketsLength, uint256 tokensLength);

    // GasUtils errors
    error InsufficientExecutionFee(uint256 minExecutionFee, uint256 executionFee);
    error InsufficientWntAmountForExecutionFee(uint256 wntAmount, uint256 executionFee);
    error InsufficientExecutionGas(uint256 startingGas, uint256 minHandleErrorGas);

    // MarketFactory errors
    error MarketAlreadyExists(bytes32 salt, address existingMarketAddress);

    // MarketStoreUtils errors
    error MarketNotFound(address key);

    // MarketUtils errors
    error EmptyMarket();
    error DisabledMarket(address market);
    error MaxSwapPathLengthExceeded(uint256 swapPathLengh, uint256 maxSwapPathLength);
    error InsufficientPoolAmount(uint256 poolAmount, uint256 amount);
    error InsufficientReserve(uint256 reservedUsd, uint256 maxReservedUsd);
    error UnexpectedPoolValueForTokenPriceCalculation(int256 poolValue);
    error UnexpectedSupplyForTokenPriceCalculation();
    error UnableToGetOppositeToken(address inputToken, address market);
    error InvalidSwapMarket(address market);
    error UnableToGetCachedTokenPrice(address token, address market);
    error CollateralAlreadyClaimed(uint256 adjustedClaimableAmount, uint256 claimedAmount);
    error OpenInterestCannotBeUpdatedForSwapOnlyMarket(address market);
    error MaxOpenInterestExceeded(uint256 openInterest, uint256 maxOpenInterest);
    error MaxPoolAmountExceeded(uint256 poolAmount, uint256 maxPoolAmount);
    error UnexpectedBorrowingFactor(uint256 positionBorrowingFactor, uint256 cumulativeBorrowingFactor);
    error UnableToGetBorrowingFactorEmptyPoolUsd();
    error UnableToGetFundingFactorEmptyOpenInterest();
    error InvalidPositionMarket(address market);
    error InvalidCollateralTokenForMarket(address market, address token);
    error PnlFactorExceededForLongs(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error PnlFactorExceededForShorts(int256 pnlToPoolFactor, uint256 maxPnlFactor);
    error InvalidUiFeeFactor(uint256 uiFeeFactor, uint256 maxUiFeeFactor);
    error EmptyAddressInMarketTokenBalanceValidation(address market, address token);
    error InvalidMarketTokenBalance(address market, address token, uint256 balance, uint256 expectedMinBalance);
    error InvalidMarketTokenBalanceForCollateralAmount(address market, address token, uint256 balance, uint256 collateralAmount);
    error InvalidMarketTokenBalanceForClaimableFunding(address market, address token, uint256 balance, uint256 claimableFundingFeeAmount);
    error UnexpectedPoolValue(int256 poolValue);

    // Oracle errors
    error EmptySigner(uint256 signerIndex);
    error InvalidBlockNumber(uint256 blockNumber);
    error InvalidMinMaxBlockNumber(uint256 minOracleBlockNumber, uint256 maxOracleBlockNumber);
    error MaxPriceAgeExceeded(uint256 oracleTimestamp);
    error MinOracleSigners(uint256 oracleSigners, uint256 minOracleSigners);
    error MaxOracleSigners(uint256 oracleSigners, uint256 maxOracleSigners);
    error BlockNumbersNotSorted(uint256 minOracleBlockNumber, uint256 prevMinOracleBlockNumber);
    error MinPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error MaxPricesNotSorted(address token, uint256 price, uint256 prevPrice);
    error EmptyPriceFeedMultiplier(address token);
    error InvalidFeedPrice(address token, int256 price);
    error PriceFeedNotUpdated(address token, uint256 timestamp, uint256 heartbeatDuration);
    error MaxSignerIndex(uint256 signerIndex, uint256 maxSignerIndex);
    error InvalidOraclePrice(address token);
    error InvalidSignerMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error InvalidMedianMinMaxPrice(uint256 minPrice, uint256 maxPrice);
    error DuplicateTokenPrice(address token);
    error NonEmptyTokensWithPrices(uint256 tokensWithPricesLength);
    error EmptyPriceFeed(address token);
    error PriceAlreadySet(address token, uint256 minPrice, uint256 maxPrice);
    error MaxRefPriceDeviationExceeded(
        address token,
        uint256 price,
        uint256 refPrice,
        uint256 maxRefPriceDeviationFactor
    );

    // OracleModule errors
    error InvalidPrimaryPricesForSimulation(uint256 primaryTokensLength, uint256 primaryPricesLength);
    error EndOfOracleSimulation();

    // OracleUtils errors
    error EmptyCompactedPrice(uint256 index);
    error EmptyCompactedBlockNumber(uint256 index);
    error EmptyCompactedTimestamp(uint256 index);
    error InvalidSignature(address recoveredSigner, address expectedSigner);

    error EmptyPrimaryPrice(address token);

    error OracleBlockNumbersAreSmallerThanRequired(uint256[] oracleBlockNumbers, uint256 expectedBlockNumber);
    error OracleBlockNumberNotWithinRange(
        uint256[] minOracleBlockNumbers,
        uint256[] maxOracleBlockNumbers,
        uint256 blockNumber
    );

    // BaseOrderUtils errors
    error EmptyOrder();
    error UnsupportedOrderType();
    error InvalidOrderPrices(
        uint256 primaryPriceMin,
        uint256 primaryPriceMax,
        uint256 triggerPrice,
        uint256 orderType
    );
    error PriceImpactLargerThanOrderSize(int256 priceImpactUsdForPriceAdjustment, uint256 sizeDeltaUsd);
    error OrderNotFulfillableDueToPriceImpact(uint256 price, uint256 acceptablePrice);

    // IncreaseOrderUtils errors
    error UnexpectedPositionState();

    // OrderUtils errors
    error OrderTypeCannotBeCreated(uint256 orderType);
    error OrderAlreadyFrozen();

    // OrderStoreUtils errors
    error OrderNotFound(bytes32 key);

    // SwapOrderUtils errors
    error UnexpectedMarket();

    // DecreasePositionCollateralUtils errors
    error InsufficientCollateral(uint256 collateralAmount, uint256 pendingCollateralDeduction);
    error InvalidOutputToken(address tokenOut, address expectedTokenOut);

    // DecreasePositionUtils errors
    error InvalidDecreaseOrderSize(uint256 sizeDeltaUsd, uint256 positionSizeInUsd);
    error UnableToWithdrawCollateral(int256 estimatedRemainingCollateralUsd);
    error InvalidDecreasePositionSwapType(uint256 decreasePositionSwapType);
    error PositionShouldNotBeLiquidated();

    // IncreasePositionUtils errors
    error InsufficientCollateralAmount(uint256 collateralAmount, int256 collateralDeltaAmount);
    error InsufficientCollateralUsd(int256 remainingCollateralUsd);

    // PositionStoreUtils errors
    error PositionNotFound(bytes32 key);

    // PositionUtils errors
    error LiquidatablePosition(string reason);
    error EmptyPosition();
    error InvalidPositionSizeValues(uint256 sizeInUsd, uint256 sizeInTokens);
    error MinPositionSize(uint256 positionSizeInUsd, uint256 minPositionSizeUsd);

    // PositionPricingUtils errors
    error UsdDeltaExceedsLongOpenInterest(int256 usdDelta, uint256 longOpenInterest);
    error UsdDeltaExceedsShortOpenInterest(int256 usdDelta, uint256 shortOpenInterest);

    // SwapPricingUtils errors
    error UsdDeltaExceedsPoolValue(int256 usdDelta, uint256 poolUsd);
    error InvalidPoolAdjustment(address token, uint256 poolUsdForToken, int256 poolUsdAdjustmentForToken);

    // RoleModule errors
    error Unauthorized(address msgSender, string role);

    // RoleStore errors
    error ThereMustBeAtLeastOneRoleAdmin();
    error ThereMustBeAtLeastOneTimelockMultiSig();

    // ExchangeRouter errors
    error InvalidClaimFundingFeesInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimCollateralInput(uint256 marketsLength, uint256 tokensLength, uint256 timeKeysLength);
    error InvalidClaimAffiliateRewardsInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidClaimUiFeesInput(uint256 marketsLength, uint256 tokensLength);

    // SwapUtils errors
    error InvalidTokenIn(address tokenIn, address market);
    error InsufficientOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error InsufficientSwapOutputAmount(uint256 outputAmount, uint256 minOutputAmount);
    error DuplicatedMarketInSwapPath(address market);
    error SwapPriceImpactExceedsAmountIn(uint256 amountAfterFees, int256 negativeImpactAmount);

    // TokenUtils errors
    error EmptyTokenTranferGasLimit(address token);
    error TokenTransferError(address token, address receiver, uint256 amount);
    error EmptyHoldingAddress();

    // AccountUtils errors
    error EmptyAccount();
    error EmptyReceiver();

    // Array errors
    error CompactedArrayOutOfBounds(
        uint256[] compactedValues,
        uint256 index,
        uint256 slotIndex,
        string label
    );

    error ArrayOutOfBoundsUint256(
        uint256[] values,
        uint256 index,
        string label
    );

    error ArrayOutOfBoundsBytes(
        bytes[] values,
        uint256 index,
        string label
    );

    // WithdrawalStoreUtils errors
    error WithdrawalNotFound(bytes32 key);

    // WithdrawalUtils errors
    error EmptyWithdrawal();
    error EmptyWithdrawalAmount();
    error MinLongTokens(uint256 received, uint256 expected);
    error MinShortTokens(uint256 received, uint256 expected);
    error InsufficientMarketTokens(uint256 balance, uint256 expected);
    error InsufficientWntAmount(uint256 wntAmount, uint256 executionFee);
    error InvalidPoolValueForWithdrawal(int256 poolValue);

    // Uint256Mask errors
    error MaskIndexOutOfBounds(uint256 index, string label);
    error DuplicatedIndex(uint256 index, string label);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../error/Errors.sol";

// @title Governable
// @dev Contract to allow for governance restricted functions
contract Governable {
    address public gov;
    address public pendingGov;

    event SetGov(address prevGov, address nextGov);

    constructor() {
        _setGov(msg.sender);
    }

    modifier onlyGov() {
        if (msg.sender != gov) {
            revert Errors.Unauthorized(msg.sender, "GOV");
        }
        _;
    }

    function transferOwnership(address _newGov) external onlyGov {
        pendingGov = _newGov;
    }

    function acceptOwnership() external {
        if (msg.sender != pendingGov) {
            revert Errors.Unauthorized(msg.sender, "PendingGov");
        }

        _setGov(msg.sender);
    }

    // @dev updates the gov value to the input _gov value
    // @param _gov the value to update to
    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;

        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../referral/IReferralStorage.sol";
import "./Governable.sol";

// @title ReferralStorage
// @dev Mock referral storage for testing and testnets
contract ReferralStorage is IReferralStorage, Governable {
    uint256 public constant BASIS_POINTS = 10000;

    // @dev mapping of affiliate to discount share for trader
    // this overrides the default value in the affiliate's tier
    mapping (address => uint256) public override referrerDiscountShares;
    // @dev mapping of affiliate to tier
    mapping (address => uint256) public override referrerTiers;
    // @dev mapping tier level to tier values
    mapping (uint256 => ReferralTier.Props) public override tiers;

    // @dev handlers for access control
    mapping (address => bool) public isHandler;

    // @dev mapping of referral code to affiliate
    mapping (bytes32 => address) public override codeOwners;
    // @dev mapping of trader to referral code
    mapping (address => bytes32) public override traderReferralCodes;

    // @param handler the handler being set
    // @param isActive whether the handler is being set to active or inactive
    event SetHandler(address handler, bool isActive);
    // @param account address of the trader
    // @param code the referral code
    event SetTraderReferralCode(address account, bytes32 code);
    // @param tierId the tier level
    // @param totalRebate the total rebate for the tier (affiliate reward + trader discount)
    // @param discountShare the share of the totalRebate for traders
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    // @param referrer the affiliate
    // @param tierId the new tier level
    event SetReferrerTier(address referrer, uint256 tierId);
    // @param referrer the affiliate
    // @param discountShare the share of the totalRebate for traders
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    // @param account the address of the affiliate
    // @param code the referral code
    event RegisterCode(address account, bytes32 code);
    // @param account the previous owner of the referral code
    // @param newAccount the new owner of the referral code
    // @param code the referral code
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    // @param newAccount the new owner of the referral code
    // @param code the referral code
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        _;
    }

    // @dev set an address as a handler
    // @param _handler address of the handler
    // @param _isActive whether to set the handler as active or inactive
    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    // @dev set values for a tier
    // @param _tierId the ID of the tier to set
    // @param _totalRebate the total rebate
    // @param _discountShare the discount share
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external override onlyGov {
        require(_totalRebate <= BASIS_POINTS, "ReferralStorage: invalid totalRebate");
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        ReferralTier.Props memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    // @dev set the tier for an affiliate
    // @param _referrer the address of the affiliate
    // @param _tierId the tier to set to
    function setReferrerTier(address _referrer, uint256 _tierId) external override onlyGov {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    // @dev set the discount share for an affiliate
    // @param _discountShare the discount share to set to
    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    // @dev set the referral code for a trader
    // @param _account the address of the trader
    // @param _code the referral code to set to
    function setTraderReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    // @dev set the referral code for a trader
    // @param _code the referral code to set to
    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    // @dev register a referral code
    // @param _code the referral code to register
    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    // @dev for affiliates to set a new owner for a referral code they own
    // @param _code the referral code
    // @param _newAccount the new owner
    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    // @dev set the owner of a referral code
    // @param _code the referral code
    // @param _newAccount the new owner
    function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlyGov {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    // @dev get the referral info for a trader
    // @param _account the address of the trader
    function getTraderReferralInfo(address _account) external override view returns (bytes32, address) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    // @dev set the referral code for a trader
    // @param _account the address of the trader
    // @param _code the referral code
    function _setTraderReferralCode(address _account, bytes32 _code) private {
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./ReferralTier.sol";

// @title IReferralStorage
// @dev Interface for ReferralStorage
interface IReferralStorage {
    // @dev get the owner of a referral code
    // @param _code the referral code
    // @return the owner of the referral code
    function codeOwners(bytes32 _code) external view returns (address);
    // @dev get the referral code of a trader
    // @param _account the address of the trader
    // @return the referral code
    function traderReferralCodes(address _account) external view returns (bytes32);
    // @dev get the trader discount share for an affiliate
    // @param _account the address of the affiliate
    // @return the trader discount share
    function referrerDiscountShares(address _account) external view returns (uint256);
    // @dev get the tier level of an affiliate
    // @param _account the address of the affiliate
    // @return the tier level of the affiliate
    function referrerTiers(address _account) external view returns (uint256);
    // @dev get the referral info for a trader
    // @param _account the address of the trader
    // @return (referral code, affiliate)
    function getTraderReferralInfo(address _account) external view returns (bytes32, address);
    // @dev set the referral code for a trader
    // @param _account the address of the trader
    // @param _code the referral code
    function setTraderReferralCode(address _account, bytes32 _code) external;
    // @dev set the values for a tier
    // @param _tierId the tier level
    // @param _totalRebate the total rebate for the tier (affiliate reward + trader discount)
    // @param _discountShare the share of the totalRebate for traders
    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external;
    // @dev set the tier for an affiliate
    // @param _tierId the tier level
    function setReferrerTier(address _referrer, uint256 _tierId) external;
    // @dev set the owner for a referral code
    // @param _code the referral code
    // @param _newAccount the new owner
    function govSetCodeOwner(bytes32 _code, address _newAccount) external;

    // @dev get the tier values for a tier level
    // @param _tierLevel the tier level
    // @return (totalRebate, discountShare)
    function tiers(uint256 _tierLevel) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title ReferralTier
// @dev Struct for referral tiers
library ReferralTier {
    // @param totalRebate the total rebate for the tier (affiliate reward + trader discount)
    // @param discountShare the share of the totalRebate for traders
    struct Props {
        uint256 totalRebate;
        uint256 discountShare;
    }
}