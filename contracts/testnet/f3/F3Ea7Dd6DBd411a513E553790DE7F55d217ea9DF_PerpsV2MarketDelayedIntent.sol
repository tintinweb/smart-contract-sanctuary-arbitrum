// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";

// Internal references
import "./interfaces/IIssuer.sol";
import "./MixinResolver.sol";

contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;
    mapping(bytes32 => address) public availableBridge;
    mapping(address => bool) public isBridge;

    bytes32[] public bridgeList;

    constructor(address _owner) Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint256 i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    function addAvailableBridge(bytes32 bridgeName, address bridgeAddress) external onlyOwner {
        _addAvailableBridge(bridgeName, bridgeAddress);
    }

    function removeAvailableBridge(bytes32 bridgeName) external onlyOwner {
        _removeAvailableBridge(bridgeName);
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    function _addAvailableBridge(bytes32 bridgeName, address bridgeAddress) private {
        if (availableBridge[bridgeName] != address(0)) {
            _removeAvailableBridge(bridgeName);
        }
        availableBridge[bridgeName] = bridgeAddress;
        isBridge[bridgeAddress] = true;
        bridgeList.push(bridgeName);
        emit AddBridge(bridgeName, bridgeAddress);
    }

    function _removeAvailableBridge(bytes32 bridgeName) private {
        require(availableBridge[bridgeName] != address(0), "The bridge no exist.");
        uint lastBridgeNumber = bridgeList.length - 1;
        for (uint ii = 0; ii <= lastBridgeNumber; ii++) {
            if (bridgeList[ii] == bridgeName) {
                bridgeList[ii] = bridgeList[lastBridgeNumber];
                bridgeList.pop();
                break;
            }
        }
        address bridgeToRemove = availableBridge[bridgeName];
        delete availableBridge[bridgeName];
        delete isBridge[bridgeToRemove];
        emit RemoveBridge(bridgeName, bridgeToRemove);
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint256 i = 0; i < names.length; i++) {
            if (repository[names[i]] != destinations[i]) {
                return false;
            }
        }
        return true;
    }

    function getAddress(bytes32 name) external view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }

    function getSynth(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.synths(key));
    }

    function getAvailableBridge(bytes32 bridgeName) external view returns (address) {
        return availableBridge[bridgeName];
    }

    function getBridgeList() external view returns (bytes32[] memory) {
        return bridgeList;
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
    event AddBridge(bytes32 indexed bridgeName, address bridgeAddress);
    event RemoveBridge(bytes32 indexed bridgeName, address bridgeAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MixinResolver.sol";

// Internal references
import "./interfaces/IFlexibleStorage.sol";

contract MixinPerpsV2MarketSettings is MixinResolver {
    /* ========== CONSTANTS ========== */

    bytes32 internal constant SETTING_CONTRACT_NAME = "PerpsV2MarketSettings";

    /* ---------- Parameter Names ---------- */

    // Per-market settings
    bytes32 internal constant PARAMETER_TAKER_FEE = "takerFee";
    bytes32 internal constant PARAMETER_MAKER_FEE = "makerFee";
    bytes32 internal constant PARAMETER_TAKER_FEE_DELAYED_ORDER = "takerFeeDelayedOrder";
    bytes32 internal constant PARAMETER_MAKER_FEE_DELAYED_ORDER = "makerFeeDelayedOrder";
    bytes32 internal constant PARAMETER_TAKER_FEE_OFFCHAIN_DELAYED_ORDER = "takerFeeOffchainDelayedOrder";
    bytes32 internal constant PARAMETER_MAKER_FEE_OFFCHAIN_DELAYED_ORDER = "makerFeeOffchainDelayedOrder";
    bytes32 internal constant PARAMETER_NEXT_PRICE_CONFIRM_WINDOW = "nextPriceConfirmWindow";
    bytes32 internal constant PARAMETER_DELAYED_ORDER_CONFIRM_WINDOW = "delayedOrderConfirmWindow";
    bytes32 internal constant PARAMETER_OFFCHAIN_DELAYED_ORDER_MIN_AGE = "offchainDelayedOrderMinAge";
    bytes32 internal constant PARAMETER_OFFCHAIN_DELAYED_ORDER_MAX_AGE = "offchainDelayedOrderMaxAge";
    bytes32 internal constant PARAMETER_MAX_LEVERAGE = "maxLeverage";
    bytes32 internal constant PARAMETER_MAX_MARKET_VALUE = "maxMarketValue";
    bytes32 internal constant PARAMETER_MAX_FUNDING_VELOCITY = "maxFundingVelocity";
    bytes32 internal constant PARAMETER_MIN_SKEW_SCALE = "skewScale";
    bytes32 internal constant PARAMETER_MIN_DELAY_TIME_DELTA = "minDelayTimeDelta";
    bytes32 internal constant PARAMETER_MAX_DELAY_TIME_DELTA = "maxDelayTimeDelta";
    bytes32 internal constant PARAMETER_OFFCHAIN_MARKET_KEY = "offchainMarketKey";
    bytes32 internal constant PARAMETER_OFFCHAIN_PRICE_DIVERGENCE = "offchainPriceDivergence";
    bytes32 internal constant PARAMETER_LIQUIDATION_PREMIUM_MULTIPLIER = "liquidationPremiumMultiplier";
    bytes32 internal constant PARAMETER_MAX_LIQUIDAION_DELTA = "maxLiquidationDelta";
    bytes32 internal constant PARAMETER_MAX_LIQUIDATION_PD = "maxPD";
    // liquidation buffer to prevent negative margin upon liquidation
    bytes32 internal constant PARAMETER_LIQUIDATION_BUFFER_RATIO = "liquidationBufferRatio";

    // Global settings
    // minimum liquidation fee payable to liquidator
    bytes32 internal constant SETTING_MIN_KEEPER_FEE = "perpsV2MinKeeperFee";
    // maximum liquidation fee payable to liquidator
    bytes32 internal constant SETTING_MAX_KEEPER_FEE = "perpsV2MaxKeeperFee";
    // liquidation fee basis points payed to liquidator
    bytes32 internal constant SETTING_LIQUIDATION_FEE_RATIO = "perpsV2LiquidationFeeRatio";
    // minimum initial margin
    bytes32 internal constant SETTING_MIN_INITIAL_MARGIN = "perpsV2MinInitialMargin";
    // fixed liquidation fee to be paid to liquidator keeper (not flagger)
    bytes32 internal constant SETTING_KEEPER_LIQUIRATION_FEE = "keeperLiquidationFee";

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _resolver) MixinResolver(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view virtual override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function _flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    /* ---------- Internals ---------- */

    function _parameter(bytes32 _marketKey, bytes32 key) internal view returns (uint256 value) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)));
    }

    function _takerFee(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE);
    }

    function _makerFee(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE);
    }

    function _takerFeeDelayedOrder(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE_DELAYED_ORDER);
    }

    function _makerFeeDelayedOrder(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE_DELAYED_ORDER);
    }

    function _takerFeeOffchainDelayedOrder(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE_OFFCHAIN_DELAYED_ORDER);
    }

    function _makerFeeOffchainDelayedOrder(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE_OFFCHAIN_DELAYED_ORDER);
    }

    function _nextPriceConfirmWindow(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW);
    }

    function _delayedOrderConfirmWindow(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_DELAYED_ORDER_CONFIRM_WINDOW);
    }

    function _offchainDelayedOrderMinAge(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MIN_AGE);
    }

    function _offchainDelayedOrderMaxAge(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MAX_AGE);
    }

    function _maxLeverage(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_LEVERAGE);
    }

    function _maxMarketValue(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_MARKET_VALUE);
    }

    function _skewScale(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MIN_SKEW_SCALE);
    }

    function _maxFundingVelocity(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_FUNDING_VELOCITY);
    }

    function _minDelayTimeDelta(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MIN_DELAY_TIME_DELTA);
    }

    function _maxDelayTimeDelta(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_DELAY_TIME_DELTA);
    }

    function _offchainMarketKey(bytes32 _marketKey) internal view returns (bytes32) {
        return
            _flexibleStorage().getBytes32Value(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY))
            );
    }

    function _offchainPriceDivergence(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_PRICE_DIVERGENCE);
    }

    function _liquidationPremiumMultiplier(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_LIQUIDATION_PREMIUM_MULTIPLIER);
    }

    function _maxLiquidationDelta(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_LIQUIDAION_DELTA);
    }

    function _maxPD(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_MAX_LIQUIDATION_PD);
    }

    function _liquidationBufferRatio(bytes32 _marketKey) internal view returns (uint256) {
        return _parameter(_marketKey, PARAMETER_LIQUIDATION_BUFFER_RATIO);
    }

    function _minKeeperFee() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE);
    }

    function _maxKeeperFee() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MAX_KEEPER_FEE);
    }

    function _liquidationFeeRatio() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO);
    }

    function _minInitialMargin() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN);
    }

    function _keeperLiquidationFee() internal view returns (uint256) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_KEEPER_LIQUIRATION_FEE);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Internal references
import "./AddressResolver.sol";

contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second) internal pure returns (bytes32[] memory combination) {
        combination = new bytes32[](first.length + second.length);

        for (uint256 i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint256 j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view virtual returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination = resolver.requireAndGetAddress(
                name,
                string(abi.encodePacked("Resolver missing target: ", name))
            );
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint256 i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // false if our cache is invalid or if the resolver doesn't have the required address
            if (resolver.getAddress(name) != addressCache[name] || addressCache[name] == address(0)) {
                return false;
            }
        }

        return true;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function requireAndGetAddress(bytes32 name) internal view returns (address) {
        address _foundAddress = addressCache[name];
        require(_foundAddress != address(0), string(abi.encodePacked("Missing address: ", name)));
        return _foundAddress;
    }

    /* ========== EVENTS ========== */

    event CacheUpdated(bytes32 name, address destination);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Owned.sol";

// Inheritance
import "./MixinPerpsV2MarketSettings.sol";
import "./interfaces/IPerpsV2MarketBaseTypes.sol";

// Libraries
import "./externals/openzeppelin/SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SignedSafeDecimalMath.sol";
import "./SafeDecimalMath.sol";
import "./SafeCast.sol";

// Internal references
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IFuturesMarketManager.sol";
import "./interfaces/ISynthrBridge.sol";
import "./interfaces/IPerpsV2MarketState.sol";

// Use internal interface (external functions not present in IFuturesMarketManager)
interface IFuturesMarketManagerInternal {
    function issueSUSD(address account, uint256 amount) external;

    function burnSUSD(address account, uint256 amount) external returns (uint256 postReclamationAmount);

    function payFee(uint256 amount) external;

    function isEndorsed(address account) external view returns (bool);

    function sendIncreaseSynth(bytes32 bridgeKey, bytes32 synthKey, uint256 synthAmount) external;
}

contract PerpsV2MarketBase is MixinPerpsV2MarketSettings, IPerpsV2MarketBaseTypes {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeDecimalMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeDecimalMath for int256;

    /* ========== CONSTANTS ========== */

    // This is the same unit as used inside `SignedSafeDecimalMath`.
    int256 private constant _UNIT = int256(10 ** uint256(18));

    //slither-disable-next-line naming-convention
    bytes32 internal constant sUSD = "sUSD";

    /* ========== STATE VARIABLES ========== */

    IPerpsV2MarketState public marketState;

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 internal constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    bytes32 internal constant CONTRACT_PERPSV2MARKETSETTINGS = "PerpsV2MarketSettings";
    bytes32 internal constant CONTRACT_PERPSV2EXCHANGERATE = "PerpsV2ExchangeRate";
    // bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    // Holds the revert message for each type of error.
    mapping(uint8 => string) internal _errorMessages;

    // convenience struct for passing params between position modification helper functions
    struct TradeParams {
        int256 sizeDelta;
        uint256 oraclePrice;
        uint256 fillPrice;
        uint256 desiredFillPrice;
        uint256 takerFee;
        uint256 makerFee;
        bytes32 trackingCode; // optional tracking code for volume source fee sharing
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _marketState, address _resolver) MixinPerpsV2MarketSettings(_resolver) {
        marketState = IPerpsV2MarketState(_marketState);

        // Set up the mapping between error codes and their revert messages.
        _errorMessages[uint8(Status.InvalidPrice)] = "Invalid price";
        _errorMessages[uint8(Status.InvalidOrderType)] = "Invalid order type";
        _errorMessages[uint8(Status.PriceOutOfBounds)] = "Price out of acceptable range";
        _errorMessages[uint8(Status.CanLiquidate)] = "Position can be liquidated";
        _errorMessages[uint8(Status.CannotLiquidate)] = "Position cannot be liquidated";
        _errorMessages[uint8(Status.MaxMarketSizeExceeded)] = "Max market size exceeded";
        _errorMessages[uint8(Status.MaxLeverageExceeded)] = "Max leverage exceeded";
        _errorMessages[uint8(Status.InsufficientMargin)] = "Insufficient margin";
        _errorMessages[uint8(Status.NotPermitted)] = "Not permitted by this address";
        _errorMessages[uint8(Status.NilOrder)] = "Cannot submit empty order";
        _errorMessages[uint8(Status.NoPositionOpen)] = "No position open";
        _errorMessages[uint8(Status.PriceTooVolatile)] = "Price too volatile";
        _errorMessages[uint8(Status.PriceImpactToleranceExceeded)] = "Price impact exceeded";
        _errorMessages[uint8(Status.PositionFlagged)] = "Position flagged";
        _errorMessages[uint8(Status.PositionNotFlagged)] = "Position not flagged";
    }

    /* ---------- External Contracts ---------- */

    function resolverAddressesRequired() public view override returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinPerpsV2MarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](6);
        newAddresses[0] = CONTRACT_EXCHANGER;
        newAddresses[1] = CONTRACT_EXRATES;
        newAddresses[2] = CONTRACT_SYSTEMSTATUS;
        newAddresses[3] = CONTRACT_FUTURESMARKETMANAGER;
        newAddresses[4] = CONTRACT_PERPSV2MARKETSETTINGS;
        newAddresses[5] = CONTRACT_PERPSV2EXCHANGERATE;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function _exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }

    function _systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function _synthrBridge(bytes32 bridgeName) internal view returns (ISynthrBridge) {
        return ISynthrBridge(resolver.getAvailableBridge(bridgeName));
    }

    function _manager() internal view returns (IFuturesMarketManagerInternal) {
        return IFuturesMarketManagerInternal(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }

    function _settings() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_PERPSV2MARKETSETTINGS);
    }

    /* ---------- Market Details ---------- */
    function _baseAsset() internal view returns (bytes32) {
        return marketState.baseAsset();
    }

    function _marketKey() internal view returns (bytes32) {
        return marketState.marketKey();
    }

    /*
     * Returns the pSkew = skew / skewScale capping the pSkew between [-1, 1].
     */
    function _proportionalSkew() internal view returns (int256) {
        int256 pSkew = int256(marketState.marketSkew()).divideDecimal(int256(_skewScale(_marketKey())));

        // Ensures the proportionalSkew is between -1 and 1.
        return _min(_max(-_UNIT, pSkew), _UNIT);
    }

    function _proportionalElapsed() internal view returns (int256) {
        return int256(block.timestamp.sub(marketState.fundingLastRecomputed())).divideDecimal(1 days);
    }

    function _currentFundingVelocity() internal view returns (int256) {
        int256 maxFundingVelocity = int256(_maxFundingVelocity(_marketKey()));
        return _proportionalSkew().multiplyDecimal(maxFundingVelocity);
    }

    /*
     * @dev Retrieves the _current_ funding rate given the current market conditions.
     *
     * This is used during funding computation _before_ the market is modified (e.g. closing or
     * opening a position). However, called via the `currentFundingRate` view, will return the
     * 'instantaneous' funding rate. It's similar but subtle in that velocity now includes the most
     * recent skew modification.
     *
     * There is no variance in computation but will be affected based on outside modifications to
     * the market skew, max funding velocity, price, and time delta.
     */
    function _currentFundingRate() internal view returns (int256) {
        // calculations:
        //  - velocity          = proportional_skew * max_funding_velocity
        //  - proportional_skew = skew / skew_scale
        //
        // example:
        //  - prev_funding_rate     = 0
        //  - prev_velocity         = 0.0025
        //  - time_delta            = 29,000s
        //  - max_funding_velocity  = 0.025 (2.5%)
        //  - skew                  = 300
        //  - skew_scale            = 10,000
        //
        // note: prev_velocity just refs to the velocity _before_ modifying the market skew.
        //
        // funding_rate = prev_funding_rate + prev_velocity * (time_delta / seconds_in_day)
        // funding_rate = 0 + 0.0025 * (29,000 / 86,400)
        //              = 0 + 0.0025 * 0.33564815
        //              = 0.00083912
        return
            int256(marketState.fundingRateLastRecomputed()).add(
                _currentFundingVelocity().multiplyDecimal(_proportionalElapsed())
            );
    }

    function _unrecordedFunding(uint256 price) internal view returns (int256) {
        int256 nextFundingRate = _currentFundingRate();
        // note the minus sign: funding flows in the opposite direction to the skew.
        int256 avgFundingRate = -(int256(marketState.fundingRateLastRecomputed()).add(nextFundingRate)).divideDecimal(_UNIT * 2);
        return avgFundingRate.multiplyDecimal(_proportionalElapsed()).multiplyDecimal(int256(price));
    }

    /*
     * The new entry in the funding sequence, appended when funding is recomputed. It is the sum of the
     * last entry and the unrecorded funding, so the sequence accumulates running total over the market's lifetime.
     */
    function _nextFundingEntry(uint256 price) internal view returns (int256) {
        return int256(marketState.fundingSequence(_latestFundingIndex())).add(_unrecordedFunding(price));
    }

    function _netFundingPerUnit(uint256 startIndex, uint256 price) internal view returns (int256) {
        // Compute the net difference between start and end indices.
        return _nextFundingEntry(price).sub(marketState.fundingSequence(startIndex));
    }

    /* ---------- Position Details ---------- */

    /*
     * Determines whether a change in a position's size would violate the max market value constraint.
     */
    function _orderSizeTooLarge(uint256 maxSize, int256 oldSize, int256 newSize) internal view returns (bool) {
        // Allow users to reduce an order no matter the market conditions.
        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }

        // Either the user is flipping sides, or they are increasing an order on the same side they're already on;
        // we check that the side of the market their order is on would not break the limit.
        int256 newSkew = int256(marketState.marketSkew()).sub(oldSize).add(newSize);
        int256 newMarketSize = int256(int128(marketState.marketSize())).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));

        int256 newSideSize;
        if (0 < newSize) {
            // long case: marketSize + skew
            //            = (|longSize| + |shortSize|) + (longSize + shortSize)
            //            = 2 * longSize
            newSideSize = newMarketSize.add(newSkew);
        } else {
            // short case: marketSize - skew
            //            = (|longSize| + |shortSize|) - (longSize + shortSize)
            //            = 2 * -shortSize
            newSideSize = newMarketSize.sub(newSkew);
        }

        // newSideSize still includes an extra factor of 2 here, so we will divide by 2 in the actual condition
        if (maxSize < _abs(newSideSize.div(2))) {
            return true;
        }

        return false;
    }

    function _notionalValue(int256 positionSize, uint256 price) internal pure returns (int256 value) {
        return positionSize.multiplyDecimal(int256(price));
    }

    function _profitLoss(Position memory position, uint256 price) internal pure returns (int256 pnl) {
        int256 priceShift = int256(price).sub(int256(int128(position.lastPrice)));
        return int256(position.size).multiplyDecimal(priceShift);
    }

    function _accruedFunding(Position memory position, uint256 price) internal view returns (int256 funding) {
        uint256 lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0; // The position does not exist -- no funding.
        }
        int256 net = _netFundingPerUnit(lastModifiedIndex, price);
        return int256(position.size).multiplyDecimal(net);
    }

    /*
     * The initial margin of a position, plus any PnL and funding it has accrued. The resulting value may be negative.
     */
    function _marginPlusProfitFunding(Position memory position, uint256 price) internal view returns (int256) {
        int256 funding = _accruedFunding(position, price);
        return int256(int128(position.margin)).add(_profitLoss(position, price)).add(funding);
    }

    /*
     * The value in a position's margin after a deposit or withdrawal, accounting for funding and profit.
     * If the resulting margin would be negative or below the liquidation threshold, an appropriate error is returned.
     * If the result is not an error, callers of this function that use it to update a position's margin
     * must ensure that this is accompanied by a corresponding debt correction update, as per `_applyDebtCorrection`.
     */
    function _recomputeMarginWithDelta(
        Position memory position,
        uint256 price,
        int256 marginDelta
    ) internal view returns (uint256 margin, Status statusCode) {
        int256 newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }

        uint256 uMargin = uint256(newMargin);
        int256 positionSize = int256(position.size);
        // minimum margin beyond which position can be liquidated
        uint256 lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }

        return (uMargin, Status.Ok);
    }

    function _remainingMargin(Position memory position, uint256 price) internal view returns (uint256) {
        int256 remaining = _marginPlusProfitFunding(position, price);

        // If the margin went past zero, the position should have been liquidated - return zero remaining margin.
        return uint256(_max(0, remaining));
    }

    /*
     * @dev Similar to _remainingMargin except it accounts for the premium and fees to be paid upon liquidation.
     */
    function _remainingLiquidatableMargin(Position memory position, uint256 price) internal view returns (uint256) {
        int256 remaining = _marginPlusProfitFunding(position, price).sub(int256(_liquidationPremium(position.size, price)));
        return uint256(_max(0, remaining));
    }

    function _accessibleMargin(Position memory position, uint256 price) internal view returns (uint256) {
        // Ugly solution to rounding safety: leave up to an extra tenth of a cent in the account/leverage
        // This should guarantee that the value returned here can always be withdrawn, but there may be
        // a little extra actually-accessible value left over, depending on the position size and margin.
        uint256 milli = uint256(_UNIT / 1000);
        int256 maxLeverage = int256(_maxLeverage(_marketKey()).sub(milli));
        uint256 inaccessible = _abs(_notionalValue(position.size, price).divideDecimal(maxLeverage));

        // If the user has a position open, we'll enforce a min initial margin requirement.
        if (0 < inaccessible) {
            uint256 minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }

        uint256 remaining = _remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining.sub(inaccessible);
    }

    /**
     * The fee charged from the margin during liquidation. Fee is proportional to position size
     * but is between _minKeeperFee() and _maxKeeperFee() expressed in sUSD to prevent underincentivising
     * liquidations of small positions, or overpaying.
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lFee liquidation fee to be paid to liquidator in sUSD fixed point decimal units
     */
    function _liquidationFee(int256 positionSize, uint256 price) internal view returns (uint256 lFee) {
        // size * price * fee-ratio
        uint256 proportionalFee = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationFeeRatio());
        uint256 maxFee = _maxKeeperFee();
        uint256 cappedProportionalFee = proportionalFee > maxFee ? maxFee : proportionalFee;
        uint256 minFee = _minKeeperFee();

        // max(proportionalFee, minFee) - to prevent not incentivising liquidations enough
        return cappedProportionalFee > minFee ? cappedProportionalFee : minFee; // not using _max() helper because it's for signed ints
    }

    /**
     * The minimal margin at which liquidation can happen.
     * Is the sum of liquidationBuffer, liquidationFee (for flagger) and keeperLiquidationFee (for liquidator)
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in sUSD fixed point decimal units
     * @return lMargin liquidation margin to maintain in sUSD fixed point decimal units
     * @dev The liquidation margin contains a buffer that is proportional to the position
     * size. The buffer should prevent liquidation happening at negative margin (due to next price being worse)
     * so that stakers would not leak value to liquidators through minting rewards that are not from the
     * account's margin.
     */
    function _liquidationMargin(int256 positionSize, uint256 price) internal view returns (uint256 lMargin) {
        uint256 liquidationBuffer = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(
            _liquidationBufferRatio(_marketKey())
        );
        return liquidationBuffer.add(_liquidationFee(positionSize, price)).add(_keeperLiquidationFee());
    }

    /**
     * @dev This is the additional premium we charge upon liquidation.
     *
     * Similar to fillPrice, but we disregard the skew (by assuming it's zero). Which is basically the calculation
     * when we compute as if taking the position from 0 to x. In practice, the premium component of the
     * liquidation will just be (size / skewScale) * (size * price).
     *
     * It adds a configurable multiplier that can be used to increase the margin that goes to feePool.
     *
     * For instance, if size of the liquidation position is 100, oracle price is 1200 and skewScale is 1M then,
     *
     *  size    = abs(-100)
     *          = 100
     *  premium = 100 / 1000000 * (100 * 1200) * multiplier
     *          = 12 * multiplier
     *  if multiplier is set to 1
     *          = 12 * 1 = 12
     *
     * @param positionSize Size of the position we want to liquidate
     * @param currentPrice The current oracle price (not fillPrice)
     * @return The premium to be paid upon liquidation in sUSD
     */
    function _liquidationPremium(int256 positionSize, uint256 currentPrice) internal view returns (uint256) {
        if (positionSize == 0) {
            return 0;
        }

        // note: this is the same as fillPrice() where the skew is 0.
        uint256 notional = _abs(_notionalValue(positionSize, currentPrice));

        return
            _abs(positionSize).divideDecimal(_skewScale(_marketKey())).multiplyDecimal(notional).multiplyDecimal(
                _liquidationPremiumMultiplier(_marketKey())
            );
    }

    function _canLiquidate(Position memory position, uint256 price) internal view returns (bool) {
        // No liquidating empty positions.
        if (position.size == 0) {
            return false;
        }

        return _remainingLiquidatableMargin(position, price) <= _liquidationMargin(int256(position.size), price);
    }

    function _currentLeverage(
        Position memory position,
        uint256 price,
        uint256 remainingMargin_
    ) internal pure returns (int256 leverage) {
        // No position is open, or it is ready to be liquidated; leverage goes to nil
        if (remainingMargin_ == 0) {
            return 0;
        }

        return _notionalValue(position.size, price).divideDecimal(int256(remainingMargin_));
    }

    function _orderFee(TradeParams memory params, uint256 dynamicFeeRate) internal view returns (uint256 fee) {
        // usd value of the difference in position (using the p/d-adjusted price).
        int256 marketSkew = marketState.marketSkew();
        int256 notionalDiff = params.sizeDelta.multiplyDecimal(int256(params.fillPrice));

        // minimum fee to pay regardless (due to dynamic fees).
        uint256 baseFee = _abs(notionalDiff).multiplyDecimal(dynamicFeeRate);

        // does this trade keep the skew on one side?
        if (_sameSide(marketSkew + params.sizeDelta, marketSkew)) {
            // use a flat maker/taker fee for the entire size depending on whether the skew is increased or reduced.
            //
            // if the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
            // otherwise if the order is opposite to the skew, the maker fee is charged.
            uint256 staticRate = _sameSide(notionalDiff, marketState.marketSkew()) ? params.takerFee : params.makerFee;
            return baseFee + _abs(notionalDiff.multiplyDecimal(int256(staticRate)));
        }

        // this trade flips the skew.
        //
        // the proportion of size that moves in the direction after the flip should not be considered
        // as a maker (reducing skew) as it's now taking (increasing skew) in the opposite direction. hence,
        // a different fee is applied on the proportion increasing the skew.

        // proportion of size that's on the other direction
        uint256 takerSize = _abs((marketSkew + params.sizeDelta).divideDecimal(params.sizeDelta));
        uint256 makerSize = uint256(_UNIT) - takerSize;
        uint256 takerFee = _abs(notionalDiff).multiplyDecimal(takerSize).multiplyDecimal(params.takerFee);
        uint256 makerFee = _abs(notionalDiff).multiplyDecimal(makerSize).multiplyDecimal(params.makerFee);

        return baseFee + takerFee + makerFee;
    }

    /// Uses the exchanger to get the dynamic fee (SIP-184) for trading from sUSD to baseAsset
    /// this assumes dynamic fee is symmetric in direction of trade.
    /// @dev this is a pretty expensive action in terms of execution gas as it queries a lot
    ///   of past rates from oracle. Shouldn't be much of an issue on a rollup though.
    function _dynamicFeeRate() internal view returns (uint256 feeRate, bool tooVolatile) {
        return _exchanger().dynamicFeeRateForExchange(sUSD, _baseAsset());
    }

    function _latestFundingIndex() internal view returns (uint256) {
        return marketState.fundingSequenceLength().sub(1); // at least one element is pushed in constructor
    }

    function _postTradeDetails(
        Position memory oldPos,
        TradeParams memory params
    ) internal view returns (Position memory newPosition, uint256 fee, Status tradeStatus) {
        // Reverts if the user is trying to submit a size-zero order.
        if (params.sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }

        // The order is not submitted if the user's existing position needs to be liquidated.
        if (_canLiquidate(oldPos, params.oraclePrice)) {
            return (oldPos, 0, Status.CanLiquidate);
        }

        // get the dynamic fee rate SIP-184
        (uint256 dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        if (tooVolatile) {
            return (oldPos, 0, Status.PriceTooVolatile);
        }

        // calculate the total fee for exchange
        fee = _orderFee(params, dynamicFeeRate);
        // Deduct the fee.
        // It is an error if the realised margin minus the fee is negative or subject to liquidation.
        (uint256 newMargin, Status status) = _recomputeMarginWithDelta(oldPos, params.fillPrice, -int256(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }

        // construct new position
        Position memory newPos = Position({
            id: oldPos.id,
            lastFundingIndex: uint64(_latestFundingIndex()),
            margin: uint128(newMargin),
            lastPrice: uint128(params.fillPrice),
            size: int128(int256(oldPos.size).add(params.sizeDelta))
        });

        // always allow to decrease a position, otherwise a margin of minInitialMargin can never
        // decrease a position as the price goes against them.
        // we also add the paid out fee for the minInitialMargin because otherwise minInitialMargin
        // is never the actual minMargin, because the first trade will always deduct
        // a fee (so the margin that otherwise would need to be transferred would have to include the future
        // fee as well, making the UX and definition of min-margin confusing).
        bool positionDecreasing = _sameSide(oldPos.size, newPos.size) && _abs(newPos.size) < _abs(oldPos.size);
        if (!positionDecreasing) {
            // minMargin + fee <= margin is equivalent to minMargin <= margin - fee
            // except that we get a nicer error message if fee > margin, rather than arithmetic overflow.
            if (uint256(newPos.margin).add(fee) < _minInitialMargin()) {
                return (oldPos, 0, Status.InsufficientMargin);
            }
        }

        // check that new position margin is above liquidation margin
        // (above, in _recomputeMarginWithDelta() we checked the old position, here we check the new one)
        //
        // Liquidation margin is considered without a fee (but including premium), because it wouldn't make sense to allow
        // a trade that will make the position liquidatable.
        //
        // note: we use `oraclePrice` here as `liquidationPremium` calcs premium based not current skew.
        uint256 liqPremium = _liquidationPremium(newPos.size, params.oraclePrice);
        uint256 liqMargin = _liquidationMargin(newPos.size, params.oraclePrice).add(liqPremium);
        if (newMargin <= liqMargin) {
            return (newPos, 0, Status.CanLiquidate);
        }

        // Check that the maximum leverage is not exceeded when considering new margin including the paid fee.
        // The paid fee is considered for the benefit of UX of allowed max leverage, otherwise, the actual
        // max leverage is always below the max leverage parameter since the fee paid for a trade reduces the margin.
        // We'll allow a little extra headroom for rounding errors.
        {
            // stack too deep
            int256 leverage = int256(newPos.size).multiplyDecimal(int256(params.fillPrice)).divideDecimal(
                int256(newMargin.add(fee))
            );
            if (_maxLeverage(_marketKey()).add(uint256(_UNIT) / 100) < _abs(leverage)) {
                return (oldPos, 0, Status.MaxLeverageExceeded);
            }
        }

        // Check that the order isn't too large for the markets.
        if (_orderSizeTooLarge(_maxMarketValue(_marketKey()), oldPos.size, newPos.size)) {
            return (oldPos, 0, Status.MaxMarketSizeExceeded);
        }

        return (newPos, fee, Status.Ok);
    }

    /* ---------- Utilities ---------- */

    /*
     * The current base price from the oracle, and whether that price was invalid. Zero prices count as invalid.
     * Public because used both externally and internally
     */
    function _assetPrice() internal view returns (uint256 price, bool invalid) {
        (price, invalid) = _exchangeRates().rateAndInvalid(_baseAsset());
        // Ensure we catch uninitialised rates or suspended state / synth
        invalid = invalid || price == 0 || _systemStatus().synthSuspended(_baseAsset());
        return (price, invalid);
    }

    /*
     * @dev SIP-279 fillPrice price at which a trade is executed against accounting for how this position's
     * size impacts the skew. If the size contracts the skew (reduces) then a discount is applied on the price
     * whereas expanding the skew incurs an additional premium.
     */
    function _fillPrice(int256 size, uint256 price) internal view returns (uint256) {
        int256 skew = marketState.marketSkew();
        int256 skewScale = int256(_skewScale(_marketKey()));

        int256 pdBefore = skew.divideDecimal(skewScale);
        int256 pdAfter = skew.add(size).divideDecimal(skewScale);
        int256 priceBefore = int256(price).add(int256(price).multiplyDecimal(pdBefore));
        int256 priceAfter = int256(price).add(int256(price).multiplyDecimal(pdAfter));

        // How is the p/d-adjusted price calculated using an example:
        //
        // price      = $1200 USD (oracle)
        // size       = 100
        // skew       = 0
        // skew_scale = 1,000,000 (1M)
        //
        // Then,
        //
        // pd_before = 0 / 1,000,000
        //           = 0
        // pd_after  = (0 + 100) / 1,000,000
        //           = 100 / 1,000,000
        //           = 0.0001
        //
        // price_before = 1200 * (1 + pd_before)
        //              = 1200 * (1 + 0)
        //              = 1200
        // price_after  = 1200 * (1 + pd_after)
        //              = 1200 * (1 + 0.0001)
        //              = 1200 * (1.0001)
        //              = 1200.12
        // Finally,
        //
        // fill_price = (price_before + price_after) / 2
        //            = (1200 + 1200.12) / 2
        //            = 1200.06
        return uint256(priceBefore.add(priceAfter).divideDecimal(_UNIT * 2));
    }

    /*
     * Absolute value of the input, returned as a signed number.
     */
    function _signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function _abs(int256 x) internal pure returns (uint256) {
        return uint256(_signedAbs(x));
    }

    function _max(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? y : x;
    }

    function _min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    /*
     * True if and only if two positions a and b are on the same side of the market; that is, if they have the same
     * sign, or either of them is zero.
     */
    function _sameSide(int256 a, int256 b) internal pure returns (bool) {
        return (a == 0) || (b == 0) || (a > 0) == (b > 0);
    }

    /*
     * True if and only if the given status indicates an error.
     */
    function _isError(Status status) internal pure returns (bool) {
        return status != Status.Ok;
    }

    /*
     * Revert with an appropriate message if the first argument is true.
     */
    function _revertIfError(bool isError, Status status) internal view {
        if (isError) {
            revert(_errorMessages[uint8(status)]);
        }
    }

    /*
     * Revert with an appropriate message if the input is an error.
     */
    function _revertIfError(Status status) internal view {
        if (_isError(status)) {
            revert(_errorMessages[uint8(status)]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./PerpsV2MarketProxyable.sol";
import "./interfaces/IPerpsV2MarketDelayedIntent.sol";

// Reference
import "./interfaces/IPerpsV2MarketBaseTypes.sol";

/**
 Contract that implements DelayedOrders (on-chain & off-chain) mechanism for the PerpsV2 market.
 The purpose of the mechanism is to allow reduced fees for trades that commit to next price instead
 of current price. Specifically, this should serve funding rate arbitrageurs, such that funding rate
 arb is profitable for smaller skews. This in turn serves the protocol by reducing the skew, and so
 the risk to the debt pool, and funding rate for traders.
 The fees can be reduced when committing to next price, because front-running (MEV and oracle delay)
 is less of a risk when committing to next price.
 The relative complexity of the mechanism is due to having to enforce the "commitment" to the trade
 without either introducing free (or cheap) optionality to cause cancellations, and without large
 sacrifices to the UX / risk of the traders (e.g. blocking all actions, or penalizing failures too much).
 */
contract PerpsV2MarketDelayedIntent is IPerpsV2MarketDelayedIntent, PerpsV2MarketProxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    ///// Mutative methods

    function submitCloseOffchainDelayedOrderWithTracking(
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external onlyProxy notFlagged(messageSender) {
        _submitCloseDelayedOrder(0, desiredFillPrice, trackingCode, IPerpsV2MarketBaseTypes.OrderType.Offchain);
    }

    function submitCloseDelayedOrderWithTracking(
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external onlyProxy notFlagged(messageSender) {
        _submitCloseDelayedOrder(desiredTimeDelta, desiredFillPrice, trackingCode, IPerpsV2MarketBaseTypes.OrderType.Delayed);
    }

    /**
     * @notice submits an order to be filled some time in the future or at a price of the next oracle update.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * Reverts if the order cannot be filled at current price to prevent withholding commitFee for
     * incorrectly submitted orders (that cannot be filled).
     *
     * The order is executable after desiredTimeDelta. However, we also allow execution if the next price update
     * occurs before the desiredTimeDelta.
     * Reverts if the desiredTimeDelta is < minimum required delay.
     *
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     * @param desiredTimeDelta maximum time in seconds to wait before filling this order
     * @param desiredFillPrice an exact upper/lower bound price used on execution
     */
    function submitDelayedOrder(
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice
    ) external onlyProxy notFlagged(messageSender) {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        _submitDelayedOrder(_marketKey(), sizeDelta, desiredTimeDelta, desiredFillPrice, bytes32(0), false);
    }

    /// Same as submitDelayedOrder but emits an event with the tracking code to allow volume source
    /// fee sharing for integrations.
    function submitDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external onlyProxy notFlagged(messageSender) {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        _submitDelayedOrder(_marketKey(), sizeDelta, desiredTimeDelta, desiredFillPrice, trackingCode, false);
    }

    /**
     * @notice submits an order to be filled some time in the future or at a price of the next oracle update.
     * Reverts if a previous order still exists (wasn't executed or cancelled).
     * Reverts if the order cannot be filled at current price to prevent withholding commitFee for
     * incorrectly submitted orders (that cannot be filled).
     *
     * The order is executable after desiredTimeDelta. However, we also allow execution if the next price update
     * occurs before the desiredTimeDelta.
     * Reverts if the desiredTimeDelta is < minimum required delay.
     *
     * @param sizeDelta size in baseAsset (notional terms) of the order, similar to `modifyPosition` interface
     * @param desiredFillPrice an exact upper/lower bound price used on execution
     */
    function submitOffchainDelayedOrder(int256 sizeDelta, uint256 desiredFillPrice) external onlyProxy notFlagged(messageSender) {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        // enforcing desiredTimeDelta to 0 to use default (not needed for offchain delayed order)
        _submitDelayedOrder(_marketKey(), sizeDelta, 0, desiredFillPrice, bytes32(0), true);
    }

    function submitOffchainDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external onlyProxy notFlagged(messageSender) {
        // @dev market key is obtained here and not in internal function to prevent stack too deep there
        // bytes32 marketKey = _marketKey();

        _submitDelayedOrder(_marketKey(), sizeDelta, 0, desiredFillPrice, trackingCode, true);
    }

    ///// Internal

    function _submitCloseDelayedOrder(
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode,
        IPerpsV2MarketBaseTypes.OrderType orderType
    ) internal {
        Position memory position = marketState.positions(messageSender);

        // a position must be present before closing.
        _revertIfError(position.size == 0, Status.NoPositionOpen);

        // we only allow off-chain and delayed orders.
        //
        // note: although this is internal and may _never_ be called incorrectly, just a safety check.
        require(orderType != IPerpsV2MarketBaseTypes.OrderType.Atomic, "invalid order type");

        _submitDelayedOrder(
            _marketKey(),
            -position.size,
            desiredTimeDelta,
            desiredFillPrice,
            trackingCode,
            orderType == IPerpsV2MarketBaseTypes.OrderType.Offchain
        );
    }

    function _submitDelayedOrder(
        bytes32 marketKey,
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode,
        bool isOffchain
    ) internal {
        // check that a previous order doesn't exist
        require(marketState.delayedOrders(messageSender).sizeDelta == 0, "previous order exists");

        // automatically set desiredTimeDelta to min if 0 is specified
        if (desiredTimeDelta == 0) {
            desiredTimeDelta = _minDelayTimeDelta(marketKey);
        }

        // ensure the desiredTimeDelta is above the minimum required delay
        require(
            desiredTimeDelta >= _minDelayTimeDelta(marketKey) && desiredTimeDelta <= _maxDelayTimeDelta(marketKey),
            "delay out of bounds"
        );

        // storage position as it's going to be modified to deduct commitFee and keeperFee
        Position memory position = marketState.positions(messageSender);

        // to prevent submitting bad orders in good faith and being charged commitDeposit for them
        // simulate the order with current price (+ p/d) and market and check that the order doesn't revert
        uint256 price = _assetPriceRequireSystemChecks(isOffchain);
        uint256 fillPrice = _fillPrice(sizeDelta, price);
        uint256 fundingIndex = _recomputeFunding(price);

        TradeParams memory params = TradeParams({
            sizeDelta: sizeDelta,
            oraclePrice: price,
            fillPrice: fillPrice,
            takerFee: isOffchain ? _takerFeeOffchainDelayedOrder(marketKey) : _takerFeeDelayedOrder(marketKey),
            makerFee: isOffchain ? _makerFeeOffchainDelayedOrder(marketKey) : _makerFeeDelayedOrder(marketKey),
            desiredFillPrice: desiredFillPrice,
            trackingCode: trackingCode
        });

        // stack too deep
        {
            (, , Status status) = _postTradeDetails(position, params);
            _revertIfError(status);
        }

        uint256 keeperDeposit = _minKeeperFee();
        _updatePositionMargin(messageSender, position, sizeDelta, fillPrice, -int256(keeperDeposit));
        emitPositionModified(
            position.id,
            messageSender,
            position.margin,
            position.size,
            0,
            fillPrice,
            fundingIndex,
            0,
            marketState.marketSkew()
        );

        uint256 targetRoundId = _exchangeRates().getCurrentRoundId(_baseAsset()) + 1; // next round
        DelayedOrder memory order = DelayedOrder({
            isOffchain: isOffchain,
            sizeDelta: int128(sizeDelta),
            desiredFillPrice: uint128(desiredFillPrice),
            targetRoundId: isOffchain ? 0 : uint128(targetRoundId),
            commitDeposit: 0, // note: legacy as no longer charge a commitFee on submit
            keeperDeposit: uint128(keeperDeposit), // offchain orders do _not_ have an executableAtTime as it's based on price age.
            executableAtTime: isOffchain ? 0 : block.timestamp + desiredTimeDelta, // zero out - not used and minimise confusion.
            intentionTime: block.timestamp,
            trackingCode: trackingCode
        });

        emitDelayedOrderSubmitted(messageSender, order);
        marketState.updateDelayedOrder(
            messageSender,
            order.isOffchain,
            order.sizeDelta,
            order.desiredFillPrice,
            order.targetRoundId,
            order.commitDeposit,
            order.keeperDeposit,
            order.executableAtTime,
            order.intentionTime,
            order.trackingCode
        );
    }

    event DelayedOrderSubmitted(
        address indexed account,
        bool isOffchain,
        int256 sizeDelta,
        uint256 targetRoundId,
        uint256 intentionTime,
        uint256 executableAtTime,
        uint256 commitDeposit,
        uint256 keeperDeposit,
        bytes32 trackingCode
    );
    bytes32 internal constant DELAYEDORDERSUBMITTED_SIG =
        keccak256("DelayedOrderSubmitted(address,bool,int256,uint256,uint256,uint256,uint256,uint256,bytes32)");

    function emitDelayedOrderSubmitted(address account, DelayedOrder memory order) internal {
        proxy._emit(
            abi.encode(
                order.isOffchain,
                order.sizeDelta,
                order.targetRoundId,
                order.intentionTime,
                order.executableAtTime,
                order.commitDeposit,
                order.keeperDeposit,
                order.trackingCode
            ),
            2,
            DELAYEDORDERSUBMITTED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Proxyable.sol";
import "./PerpsV2MarketBase.sol";

contract PerpsV2MarketProxyable is PerpsV2MarketBase, Proxyable {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeDecimalMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeDecimalMath for int256;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) PerpsV2MarketBase(_marketState, _resolver) Proxyable(_owner, _proxy) {}

    /* ---------- Market Operations ---------- */

    /*
     * Alter the debt correction to account for the net result of altering a position.
     */
    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int256 newCorrection = _positionDebtCorrection(newPosition);
        int256 oldCorrection = _positionDebtCorrection(oldPosition);
        marketState.setEntryDebtCorrection(
            int128(int256(marketState.entryDebtCorrection()).add(newCorrection).sub(oldCorrection))
        );
    }

    /*
     * The impact of a given position on the debt correction.
     */
    function _positionDebtCorrection(Position memory position) internal view returns (int256) {
        /**
        This method only returns the correction term for the debt calculation of the position, and not it's 
        debt. This is needed for keeping track of the marketDebt() in an efficient manner to allow O(1) marketDebt
        calculation in marketDebt().

        The overall market debt is the sum of the remaining margin in all positions. The intuition is that
        the debt of a single position is the value withdrawn upon closing that position.

        single position remaining margin = initial-margin + profit-loss + accrued-funding =
            = initial-margin + q * (price - last-price) + q * funding-accrued-per-unit
            = initial-margin + q * price - q * last-price + q * (funding - initial-funding)

        Total debt = sum ( position remaining margins )
            = sum ( initial-margin + q * price - q * last-price + q * (funding - initial-funding) )
            = sum( q * price ) + sum( q * funding ) + sum( initial-margin - q * last-price - q * initial-funding )
            = skew * price + skew * funding + sum( initial-margin - q * ( last-price + initial-funding ) )
            = skew (price + funding) + sum( initial-margin - q * ( last-price + initial-funding ) )

        The last term: sum( initial-margin - q * ( last-price + initial-funding ) ) being the position debt correction
            that is tracked with each position change using this method. 
        
        The first term and the full debt calculation using current skew, price, and funding is calculated globally in marketDebt().
         */
        return
            int256(int128(position.margin)).sub(
                int256(position.size).multiplyDecimal(
                    int256(int128(position.lastPrice)).add(marketState.fundingSequence(position.lastFundingIndex))
                )
            );
    }

    /*
     * The current base price, reverting if it is invalid, or if system or synth is suspended.
     * This is mutative because the circuit breaker stores the last price on every invocation.
     */
    function _assetPriceRequireSystemChecks(bool checkOffchainMarket) internal returns (uint256) {
        // check that futures market isn't suspended, revert with appropriate message
        _systemStatus().requireFuturesMarketActive(_marketKey()); // asset and market may be different
        // check that synth is active, and wasn't suspended, revert with appropriate message
        _systemStatus().requireSynthActive(_baseAsset());

        if (checkOffchainMarket) {
            // offchain PerpsV2 virtual market
            _systemStatus().requireFuturesMarketActive(_offchainMarketKey(_marketKey()));
        }
        // check if circuit breaker if price is within deviation tolerance and system & synth is active
        // note: rateWithBreakCircuit (mutative) is used here instead of rateWithInvalid (view). This is
        //  despite reverting immediately after if circuit is broken, which may seem silly.
        //  This is in order to persist last-rate in exchangeCircuitBreaker in the happy case
        //  because last-rate is what used for measuring the deviation for subsequent trades.
        (uint256 price, bool circuitBroken, bool staleOrInvalid) = _exchangeRates().rateWithSafetyChecks(_baseAsset());
        // revert if price is invalid or circuit was broken
        // note: we revert here, which means that circuit is not really broken (is not persisted), this is
        //  because the futures methods and interface are designed for reverts, and do not support no-op
        //  return values.
        _revertIfError(circuitBroken || staleOrInvalid, Status.InvalidPrice);
        return price;
    }

    /** TODO: Docs */
    function _assertFillPrice(uint256 fillPrice, uint256 desiredFillPrice, int256 sizeDelta) internal view returns (uint256) {
        _revertIfError(
            sizeDelta > 0 ? fillPrice > desiredFillPrice : fillPrice < desiredFillPrice,
            Status.PriceImpactToleranceExceeded
        );
        return fillPrice;
    }

    function _recomputeFunding(uint256 price) internal returns (uint256 lastIndex) {
        uint256 sequenceLengthBefore = marketState.fundingSequenceLength();

        int256 fundingRate = _currentFundingRate();
        int256 funding = _nextFundingEntry(price);
        marketState.pushFundingSequence(int128(funding));
        marketState.setFundingLastRecomputed(uint32(block.timestamp));
        marketState.setFundingRateLastRecomputed(int128(fundingRate));

        emitFundingRecomputed(funding, fundingRate, sequenceLengthBefore, marketState.fundingLastRecomputed());

        return sequenceLengthBefore;
    }

    // updates the stored position margin in place (on the stored position)
    function _updatePositionMargin(
        address account,
        Position memory position,
        int256 orderSizeDelta,
        uint256 price,
        int256 marginDelta
    ) internal {
        Position memory oldPosition = position;
        // Determine new margin, ensuring that the result is positive.
        (uint256 margin, Status status) = _recomputeMarginWithDelta(oldPosition, price, marginDelta);
        _revertIfError(status);

        // Update the debt correction.
        uint256 fundingIndex = _latestFundingIndex();
        _applyDebtCorrection(
            Position(0, uint64(fundingIndex), uint128(margin), uint128(price), int128(position.size)),
            Position(0, position.lastFundingIndex, position.margin, position.lastPrice, int128(position.size))
        );

        // Update the account's position with the realised margin.
        position.margin = uint128(margin);

        // We only need to update their funding/PnL details if they actually have a position open
        if (position.size != 0) {
            position.lastPrice = uint128(price);
            position.lastFundingIndex = uint64(fundingIndex);

            // The user can always decrease their margin if they have no position, or as long as:
            //   * the resulting margin would not be lower than the liquidation margin or min initial margin
            //     * liqMargin accounting for the liqPremium
            if (marginDelta < 0) {
                // note: We .add `liqPremium` to increase the req margin to avoid entering into liquidation
                uint256 liqPremium = _liquidationPremium(position.size, price);
                uint256 liqMargin = _liquidationMargin(position.size, price).add(liqPremium);

                _revertIfError(margin <= liqMargin, Status.InsufficientMargin);

                // `marginDelta` can be decreasing (due to e.g. fees). However, price could also have moved in the
                // opposite direction resulting in a loss. A reduced remainingMargin to calc currentLeverage can
                // put the position above maxLeverage.
                //
                // To account for this, a check on `positionDecreasing` ensures that we can always perform this action
                // so long as we're reducing the position size and not liquidatable.
                int256 newPositionSize = int256(position.size).add(orderSizeDelta);
                bool positionDecreasing = _sameSide(position.size, newPositionSize) &&
                    _abs(newPositionSize) < _abs(position.size);

                if (!positionDecreasing) {
                    _revertIfError(
                        _maxLeverage(_marketKey()) < _abs(_currentLeverage(position, price, margin)),
                        Status.MaxLeverageExceeded
                    );
                    _revertIfError(margin < _minInitialMargin(), Status.InsufficientMargin);
                }
            }
        }

        // persist position changes
        marketState.updatePosition(
            account,
            position.id,
            position.lastFundingIndex,
            position.margin,
            position.lastPrice,
            position.size
        );
    }

    function _trade(address sender, TradeParams memory params) internal notFlagged(sender) returns (uint256) {
        Position memory position = marketState.positions(sender);
        Position memory oldPosition = Position({
            id: position.id,
            lastFundingIndex: position.lastFundingIndex,
            margin: position.margin,
            lastPrice: position.lastPrice,
            size: position.size
        });

        // Compute the new position after performing the trade
        (Position memory newPosition, uint256 fee, Status status) = _postTradeDetails(oldPosition, params);
        _revertIfError(status);

        _assertFillPrice(params.fillPrice, params.desiredFillPrice, params.sizeDelta);

        // Update the aggregated market size and skew with the new order size
        marketState.setMarketSkew(int128(int256(marketState.marketSkew()).add(newPosition.size).sub(oldPosition.size)));
        marketState.setMarketSize(
            uint128(uint256(marketState.marketSize()).add(_abs(newPosition.size)).sub(_abs(oldPosition.size)))
        );

        // Send the fee to the fee pool
        if (0 < fee) {
            _manager().payFee(fee);
        }
        // emit tracking code event
        if (params.trackingCode != bytes32(0)) {
            emitPerpsTracking(params.trackingCode, _baseAsset(), _marketKey(), params.sizeDelta, fee);
        }

        // Update the margin, and apply the resulting debt correction
        position.margin = newPosition.margin;
        _applyDebtCorrection(newPosition, oldPosition);

        // Record the trade
        uint64 id = oldPosition.id;
        uint256 fundingIndex = _latestFundingIndex();
        if (newPosition.size == 0) {
            // If the position is being closed, we no longer need to track these details.
            delete position.id;
            delete position.size;
            delete position.lastPrice;
            delete position.lastFundingIndex;
        } else {
            if (oldPosition.size == 0) {
                // New positions get new ids.
                id = marketState.nextPositionId();
                marketState.setNextPositionId(id + 1);
            }
            position.id = id;
            position.size = newPosition.size;
            position.lastPrice = uint128(params.fillPrice);
            position.lastFundingIndex = uint64(fundingIndex);
        }

        // persist position changes
        marketState.updatePosition(
            sender,
            position.id,
            position.lastFundingIndex,
            position.margin,
            position.lastPrice,
            position.size
        );

        // emit the modification event
        emitPositionModified(
            id,
            sender,
            newPosition.margin,
            newPosition.size,
            params.sizeDelta,
            params.fillPrice,
            fundingIndex,
            fee,
            marketState.marketSkew()
        );
        return fee;
    }

    /* ========== EVENTS ========== */

    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event PositionModified(
        uint256 indexed id,
        address indexed account,
        uint256 margin,
        int256 size,
        int256 tradeSize,
        uint256 lastPrice,
        uint256 fundingIndex,
        uint256 fee,
        int256 skew
    );
    bytes32 internal constant POSITIONMODIFIED_SIG =
        keccak256("PositionModified(uint256,address,uint256,int256,int256,uint256,uint256,uint256,int256)");

    function emitPositionModified(
        uint256 id,
        address account,
        uint256 margin,
        int256 size,
        int256 tradeSize,
        uint256 lastPrice,
        uint256 fundingIndex,
        uint256 fee,
        int256 skew
    ) internal {
        proxy._emit(
            abi.encode(margin, size, tradeSize, lastPrice, fundingIndex, fee, skew),
            3,
            POSITIONMODIFIED_SIG,
            bytes32(id),
            addressToBytes32(account),
            0
        );
    }

    event FundingRecomputed(int256 funding, int256 fundingRate, uint256 indexed index, uint256 timestamp);
    bytes32 internal constant FUNDINGRECOMPUTED_SIG = keccak256("FundingRecomputed(int256,int256,uint256,uint256)");

    function emitFundingRecomputed(int256 funding, int256 fundingRate, uint256 index, uint256 timestamp) internal {
        proxy._emit(abi.encode(funding, fundingRate, index, timestamp), 1, FUNDINGRECOMPUTED_SIG, 0, 0, 0);
    }

    event PerpsTracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int256 sizeDelta, uint256 fee);
    bytes32 internal constant PERPSTRACKING_SIG = keccak256("PerpsTracking(bytes32,bytes32,bytes32,int256,uint256)");

    function emitPerpsTracking(
        bytes32 trackingCode,
        bytes32 baseAsset,
        bytes32 marketKey,
        int256 sizeDelta,
        uint256 fee
    ) internal {
        proxy._emit(abi.encode(baseAsset, marketKey, sizeDelta, fee), 2, PERPSTRACKING_SIG, trackingCode, 0, 0);
    }

    /* ========== MODIFIERS ========== */

    modifier flagged(address account) {
        if (!marketState.isFlagged(account)) {
            revert(_errorMessages[uint8(Status.PositionNotFlagged)]);
        }
        _;
    }

    modifier notFlagged(address account) {
        if (marketState.isFlagged(account)) {
            revert(_errorMessages[uint8(Status.PositionFlagged)]);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxyable.sol";

contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint256 numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint256 size = callData.length;
        bytes memory _callData = callData;
        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
            case 0 {
                log0(add(_callData, 32), size)
            }
            case 1 {
                log1(add(_callData, 32), size, topic1)
            }
            case 2 {
                log2(add(_callData, 32), size, topic1, topic2)
            }
            case 3 {
                log3(add(_callData, 32), size, topic1, topic2, topic3)
            }
            case 4 {
                log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
            }
        }
    }

    // solhint-disable no-complex-fallback
    fallback() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize())

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas(), sload(target.slot), callvalue(), free_ptr, calldatasize(), 0, 0)
            returndatacopy(free_ptr, 0, returndatasize())

            if iszero(result) {
                revert(free_ptr, returndatasize())
            }
            return(free_ptr, returndatasize())
        }
    }

    modifier onlyTarget() {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxy.sol";

contract Proxyable is Owned {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address _owned, address payable _proxy) Owned(_owned) {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");

        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setProxy(address payable _proxy) external onlyOwner {
        proxy = Proxy(_proxy);
        emit ProxyUpdated(_proxy);
    }

    function setMessageSender(address sender) external onlyProxy {
        messageSender = sender;
    }

    modifier onlyProxy() {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(payable(msg.sender)) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy() {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(payable(msg.sender)) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner() {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(payable(msg.sender)) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {
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
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
        require(value < 2 ** 64, "SafeCast: value doesn't fit in 64 bits");
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
        require(value < 2 ** 32, "SafeCast: value doesn't fit in 32 bits");
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
        require(value < 2 ** 16, "SafeCast: value doesn't fit in 16 bits");
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
        require(value < 2 ** 8, "SafeCast: value doesn't fit in 8 bits");
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
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
// import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./externals/openzeppelin/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10 ** uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10 ** uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint256 x, uint256 y, uint256 precisionUnit) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint256 a, uint256 b) internal pure returns (uint256) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int256 x) internal pure returns (uint256) {
        return uint256(signedAbs(x));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignedSafeMath.sol";

// TODO: Test suite

library SignedSafeDecimalMath {
    using SignedSafeMath for int256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    int256 public constant UNIT = int256(10 ** uint256(decimals));

    /* The number representing 1.0 for higher fidelity numbers. */
    int256 public constant PRECISE_UNIT = int256(10 ** uint256(highPrecisionDecimals));
    int256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = int256(10 ** uint256(highPrecisionDecimals - decimals));

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (int256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (int256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Rounds an input with an extra zero of precision, returning the result without the extra zero.
     * Half increments round away from zero; positive numbers at a half increment are rounded up,
     * while negative such numbers are rounded down. This behaviour is designed to be consistent with the
     * unsigned version of this library (SafeDecimalMath).
     */
    function _roundDividingByTen(int256 valueTimesTen) private pure returns (int256) {
        int256 increment;
        if (valueTimesTen % 10 >= 5) {
            increment = 10;
        } else if (valueTimesTen % 10 <= -5) {
            increment = -10;
        }
        return (valueTimesTen + increment) / 10;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(int256 x, int256 y) internal pure returns (int256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(int256 x, int256 y, int256 precisionUnit) private pure returns (int256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        int256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);
        return _roundDividingByTen(quotientTimesTen);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(int256 x, int256 y) internal pure returns (int256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(int256 x, int256 y) internal pure returns (int256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(int256 x, int256 y) internal pure returns (int256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(int256 x, int256 y, int256 precisionUnit) private pure returns (int256) {
        int256 resultTimesTen = x.mul(precisionUnit * 10).div(y);
        return _roundDividingByTen(resultTimesTen);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(int256 x, int256 y) internal pure returns (int256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(int256 x, int256 y) internal pure returns (int256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(int256 i) internal pure returns (int256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(int256 i) internal pure returns (int256) {
        int256 quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
        return _roundDividingByTen(quotientTimesTen);
    }
}

// SPDX-License-Identifier: MIT

/*
The MIT License (MIT)

Copyright (c) 2016-2020 zOS Global Limited

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
 * When we upgrade to solidity v0.6.0 or above, we should be able to
 * just do import `"openzeppelin-solidity-3.0.0/contracts/math/SignedSafeMath.sol";`
 * wherever this is used.
 */

pragma solidity ^0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function getAvailableBridge(bytes32 bridgeName) external view returns (address);

    function getBridgeList() external view returns (bytes32[] memory);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint256[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value, uint256 sourceRate, uint256 destinationRate);

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    ) external view returns (uint256 value, uint256 sourceRate, uint256 destinationRate);

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 value, uint256 systemValue, uint256 systemSourceRate, uint256 systemDestinationRate);

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint256);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint256 startingRoundId,
        uint256 startingTimestamp,
        uint256 timediff
    ) external view returns (uint256);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint256 roundId) external view returns (uint256 rate, uint256 time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint256 rate, uint256 time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint256 rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint256);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint256);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint256 numRounds,
        uint256 roundId
    ) external view returns (uint256[] memory rates, uint256[] memory times);

    function ratesAndInvalidForCurrencies(
        bytes32[] calldata currencyKeys
    ) external view returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint256[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey) external returns (uint256 rate, bool broken, bool invalid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint256 amount;
        bytes32 dest;
        uint256 reclaim;
        uint256 rebate;
        uint256 srcRoundIdAtPeriodEnd;
        uint256 destRoundIdAtPeriodEnd;
        uint256 timestamp;
    }

    struct ExchangeEntry {
        uint256 sourceRate;
        uint256 destinationRate;
        uint256 destinationAmount;
        uint256 exchangeFeeRate;
        uint256 exchangeDynamicFeeRate;
        uint256 roundIdForSrc;
        uint256 roundIdForDest;
    }

    struct ExchangeArgs {
        address fromAccount;
        address destAccount;
        bytes32 sourceCurrencyKey;
        bytes32 destCurrencyKey;
        uint256 sourceAmount;
        uint256 destAmount;
        uint256 fee;
        uint256 reclaimed;
        uint256 refunded;
        uint16 destChainId;
        bool erc20Payment;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint256 amount,
        uint256 refunded
    ) external view returns (uint256 amountAfterSettlement);

    function isSynthRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint256);

    function settlementOwing(
        address account,
        bytes32 currencyKey
    ) external view returns (uint256 reclaimAmount, uint256 rebateAmount, uint256 numEntries);

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256);

    function dynamicFeeRateForExchange(
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) external view returns (uint256 amountReceived, uint256 fee, uint256 exchangeFeeRate);

    // function priceDeviationThresholdFactor() external view returns (uint256);

    // function waitingPeriodSecs() external view returns (uint256);

    // function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(ExchangeArgs calldata args, bytes32 bridgeName) external payable returns (uint256 amountReceived);

    function exchangeAtomically(
        uint256 minAmount,
        ExchangeArgs calldata args,
        bytes32 bridgeName
    ) external payable returns (uint256 amountReceived);

    function settle(address from, bytes32 currencyKey) external returns (uint256 reclaimed, uint256 refunded, uint256 numEntries);

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;

    function updateDestinationForExchange(address recipient, bytes32 destinationKey, uint256 destinationAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint256);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint256[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int256);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int256[] memory);

    function getAddressValue(bytes32 contractName, bytes32 record) external view returns (address);

    function getAddressValues(bytes32 contractName, bytes32[] calldata records) external view returns (address[] memory);

    function getBoolValue(bytes32 contractName, bytes32 record) external view returns (bool);

    function getBoolValues(bytes32 contractName, bytes32[] calldata records) external view returns (bool[] memory);

    function getBytes32Value(bytes32 contractName, bytes32 record) external view returns (bytes32);

    function getBytes32Values(bytes32 contractName, bytes32[] calldata records) external view returns (bytes32[] memory);

    // Mutative functions
    function deleteUIntValue(bytes32 contractName, bytes32 record) external;

    function deleteIntValue(bytes32 contractName, bytes32 record) external;

    function deleteAddressValue(bytes32 contractName, bytes32 record) external;

    function deleteBoolValue(bytes32 contractName, bytes32 record) external;

    function deleteBytes32Value(bytes32 contractName, bytes32 record) external;

    function setUIntValue(bytes32 contractName, bytes32 record, uint256 value) external;

    function setUIntValues(bytes32 contractName, bytes32[] calldata records, uint256[] calldata values) external;

    function setIntValue(bytes32 contractName, bytes32 record, int256 value) external;

    function setIntValues(bytes32 contractName, bytes32[] calldata records, int256[] calldata values) external;

    function setAddressValue(bytes32 contractName, bytes32 record, address value) external;

    function setAddressValues(bytes32 contractName, bytes32[] calldata records, address[] calldata values) external;

    function setBoolValue(bytes32 contractName, bytes32 record, bool value) external;

    function setBoolValues(bytes32 contractName, bytes32[] calldata records, bool[] calldata values) external;

    function setBytes32Value(bytes32 contractName, bytes32 record, bytes32 value) external;

    function setBytes32Values(bytes32 contractName, bytes32[] calldata records, bytes32[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFuturesMarketManager {
    function markets(uint256 index, uint256 pageSize) external view returns (address[] memory);

    function numMarkets() external view returns (uint256);

    function allMarkets() external view returns (address[] memory);

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint256 debt, bool isInvalid);

    function isMarketImplementation(address _account) external view returns (bool);

    function sendIncreaseSynth(bytes32 bridgeKey, bytes32 synthKey, uint256 synthAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ISynth.sol";

interface IIssuer {
    // Views

    function allNetworksDebtInfo() external view returns (uint256 debt, uint256 sharesSupply);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint256);

    function availableSynths(uint256 index) external view returns (ISynth);

    function canBurnSynths(address account) external view returns (bool);

    function collateral(address account) external view returns (uint256);

    function collateralisationRatio(address issuer) external view returns (uint256);

    function collateralisationRatioAndAnyRatesInvalid(
        address _issuer
    ) external view returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(
        address issuer
    ) external view returns (uint256 maxIssuable, uint256 alreadyIssued, uint256 totalSystemDebt);

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function getSynths(bytes32[] calldata currencyKeys) external view returns (ISynth[] memory);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint256);

    function checkFreeCollateral(
        address _issuer,
        bytes32 _collateralKey,
        uint16 _chainId
    ) external view returns (uint256 withdrawableSynthr);

    function issueSynths(
        address from,
        uint256 amount,
        uint256 destChainId
    ) external returns (uint256 synthAmount, uint256 debtShare);

    function issueMaxSynths(address from, uint256 destChainId) external returns (uint256 synthAmount, uint256 debtShare);

    function burnSynths(
        address from,
        bytes32 synthKey,
        uint256 amount
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnSynthsToTarget(
        address from,
        bytes32 synthKey
    ) external returns (uint256 synthAmount, uint256 debtShare, uint256 reclaimed, uint256 refunded);

    function burnForRedemption(address deprecatedSynthProxy, address account, uint256 balance) external;

    function burnSynthsWithoutDebt(bytes32 currencyKey, address from, uint amount) external returns (uint256 burnAmount);

    function synthIssueFromSynthrSwap(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        uint16 chainId,
        bool isSelfLiquidation
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate, uint256 sharesToRemove);

    function destIssue(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function destBurn(address _account, bytes32 _synthKey, uint256 _synthAmount) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function destTransferMargin(address _account, uint256 _marginDelta, bytes32 _marketKey) external returns (bool);

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPerpsV2MarketBaseTypes {
    /* ========== TYPES ========== */

    enum OrderType {
        Atomic,
        Delayed,
        Offchain
    }

    enum Status {
        Ok,
        InvalidPrice,
        InvalidOrderType,
        PriceOutOfBounds,
        CanLiquidate,
        CannotLiquidate,
        MaxMarketSizeExceeded,
        MaxLeverageExceeded,
        InsufficientMargin,
        NotPermitted,
        NilOrder,
        NoPositionOpen,
        PriceTooVolatile,
        PriceImpactToleranceExceeded,
        PositionFlagged,
        PositionNotFlagged
    }

    // If margin/size are positive, the position is long; if negative then it is short.
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    // Delayed order storage
    struct DelayedOrder {
        bool isOffchain; // flag indicating the delayed order is offchain
        int128 sizeDelta; // difference in position to pass to modifyPosition
        uint128 desiredFillPrice; // desired fill price as usd used on fillPrice at execution
        uint128 targetRoundId; // price oracle roundId using which price this order needs to executed
        uint128 commitDeposit; // the commitDeposit paid upon submitting that needs to be refunded if order succeeds
        uint128 keeperDeposit; // the keeperDeposit paid upon submitting that needs to be paid / refunded on tx confirmation
        uint256 executableAtTime; // The timestamp at which this order is executable at
        uint256 intentionTime; // The block timestamp of submission
        bytes32 trackingCode; // tracking code to emit on execution for volume source fee sharing
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPerpsV2MarketBaseTypes.sol";

interface IPerpsV2MarketDelayedIntent {
    function submitCloseOffchainDelayedOrderWithTracking(uint256 desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseDelayedOrderWithTracking(
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitDelayedOrder(int256 sizeDelta, uint256 desiredTimeDelta, uint256 desiredFillPrice) external;

    function submitDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitOffchainDelayedOrder(int256 sizeDelta, uint256 desiredFillPrice) external;

    function submitOffchainDelayedOrderWithTracking(int256 sizeDelta, uint256 desiredFillPrice, bytes32 trackingCode) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPerpsV2MarketBaseTypes.sol";

// https://docs.synthetix.io/contracts/source/contracts/PerpsV2MarketState
interface IPerpsV2MarketState {
    function marketKey() external view returns (bytes32);

    function baseAsset() external view returns (bytes32);

    function marketSize() external view returns (uint128);

    function marketSkew() external view returns (int128);

    function fundingLastRecomputed() external view returns (uint32);

    function fundingSequence(uint256) external view returns (int128);

    function fundingRateLastRecomputed() external view returns (int128);

    function positions(address) external view returns (IPerpsV2MarketBaseTypes.Position memory);

    function delayedOrders(address) external view returns (IPerpsV2MarketBaseTypes.DelayedOrder memory);

    function positionFlagger(address) external view returns (address);

    function entryDebtCorrection() external view returns (int128);

    function nextPositionId() external view returns (uint64);

    function fundingSequenceLength() external view returns (uint256);

    function isFlagged(address) external view returns (bool);

    function getPositionAddressesPage(uint256, uint256) external view returns (address[] memory);

    function getPositionAddressesLength() external view returns (uint256);

    function getDelayedOrderAddressesPage(uint256, uint256) external view returns (address[] memory);

    function getDelayedOrderAddressesLength() external view returns (uint256);

    function getFlaggedAddressesPage(uint256, uint256) external view returns (address[] memory);

    function getFlaggedAddressesLength() external view returns (uint256);

    function setMarketKey(bytes32) external;

    function setBaseAsset(bytes32) external;

    function setMarketSize(uint128) external;

    function setEntryDebtCorrection(int128) external;

    function setNextPositionId(uint64) external;

    function setMarketSkew(int128) external;

    function setFundingLastRecomputed(uint32) external;

    function setFundingRateLastRecomputed(int128 _fundingRateLastRecomputed) external;

    function pushFundingSequence(int128) external;

    function updatePosition(
        address account,
        uint64 id,
        uint64 lastFundingIndex,
        uint128 margin,
        uint128 lastPrice,
        int128 size
    ) external;

    function updateDelayedOrder(
        address account,
        bool isOffchain,
        int128 sizeDelta,
        uint128 desiredFillPrice,
        uint128 targetRoundId,
        uint128 commitDeposit,
        uint128 keeperDeposit,
        uint256 executableAtTime,
        uint256 intentionTime,
        bytes32 trackingCode
    ) external;

    function deletePosition(address) external;

    function deleteDelayedOrder(address) external;

    function flag(address account, address flagger) external;

    function unflag(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynth {
    // Views
    function balanceOf(address _account) external view returns (uint256);

    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(address from, address to, uint256 value) external payable returns (bool);

    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface ISynthrBridge {
    /* ========== MUTATIVE FUNCTIONS ========== */
    function sendDepositCollateral(address account, bytes32 collateralKey, uint256 amount) external;

    function sendMint(
        address account,
        bytes32 synthKey,
        uint256 synthAmount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint256 amount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    // should call destBurn function of source contract(SynthrGateway.sol) on the dest chains while broadcasting message
    // note: should update entry for liquidatorRewards whenever calling this function.
    function sendBurn(
        address accountForSynth,
        bytes32 synthKey,
        uint256 synthAmount,
        uint256 reclaimed,
        uint256 refunded
    ) external;

    // function sendExchange(IExchanger.ExchangeArgs calldata args) external payable;

    function sendExchange(
        address account,
        bytes32 sourceCurrencyKey,
        bytes32 destCurrencyKey,
        uint256 sourceAmount,
        uint256 destAmount,
        uint256 reclaimed,
        uint256 refund,
        uint256 fee,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint256 collateralAmount,
        uint16 destChainId,
        bool erc20Payment
    ) external payable;

    function sendBridgeSyToken(
        address account,
        bytes32 synthKey,
        uint256 amount,
        uint16 dstChainId,
        bool erc20Payment
    ) external payable;

    function sendTransferMargin(address account, uint256 amount) external;

    function sendWithdrawMargin(address account, uint256 amount, uint16 destChainId, bool erc20Payment) external payable;

    function sendCrossSwapSyAssetToNative(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        address dexAddress,
        uint256 fee,
        bytes calldata dexPayload,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToSyAsset(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToNative(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        address dexAddress,
        uint256 fee,
        bytes calldata dexPayload,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapSyAssetToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendCrossSwapNativeToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee,
        bool erc20Payment
    ) external payable;

    function sendBurnFeePool(uint amount) external;

    function sendIncreaseSynth(bytes32 synthKey, uint256 synthAmount) external;

    function calcFee(bytes memory lzPayload, uint16 packetType, uint16 dstChainId) external view returns (uint256 lzFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function systemSuspended() external view returns (bool);

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireFuturesActive() external view;

    function requireFuturesMarketActive(bytes32 marketKey) external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function synthSuspended(bytes32 currencyKey) external view returns (bool);

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(
        bytes32[] calldata synths
    ) external view returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(
        bytes32[] calldata synths
    ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(
        bytes32[] calldata marketKeys
    ) external view returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(bytes32 section, address account, bool canSuspend, bool canResume) external;
}