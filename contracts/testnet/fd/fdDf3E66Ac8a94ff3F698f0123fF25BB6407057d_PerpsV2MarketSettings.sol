/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

/* Tribeone: PerpsV2MarketSettings.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/PerpsV2MarketSettings.sol
* Docs: https://docs.tribeone.io/contracts/PerpsV2MarketSettings
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IPerpsV2MarketSettings
*	- MixinPerpsV2MarketSettings
*	- MixinResolver
*	- Owned
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2023 Tribeone
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity ^0.5.16;

// https://docs.tribeone.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) public {
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

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.tribeone.io/contracts/source/interfaces/itribe
interface ITribe {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableTribes(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Tribeone
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iissuer
interface IIssuer {
    // Views

    function allNetworksDebtInfo()
        external
        view
        returns (
            uint256 debt,
            uint256 sharesSupply,
            bool isStale
        );

    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function canBurnTribes(address account) external view returns (bool);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint debtBalance);

    function issuanceRatio() external view returns (uint);

    function lastIssueEvent(address account) external view returns (uint);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function minimumStakeTime() external view returns (uint);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function getTribes(bytes32[] calldata currencyKeys) external view returns (ITribe[] memory);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey, bool excludeOtherCollateral) external view returns (uint);

    function transferableTribeoneAndAnyRateIsInvalid(address account, uint balance)
        external
        view
        returns (uint transferable, bool anyRateIsInvalid);

    function liquidationAmounts(address account, bool isSelfLiquidation)
        external
        view
        returns (
            uint totalRedeemed,
            uint debtToRemove,
            uint escrowToLiquidate,
            uint initialDebtBalance
        );

    // Restricted: used internally to Tribeone
    function addTribes(ITribe[] calldata tribesToAdd) external;

    function issueTribes(address from, uint amount) external;

    function issueTribesOnBehalf(
        address issueFor,
        address from,
        uint amount
    ) external;

    function issueMaxTribes(address from) external;

    function issueMaxTribesOnBehalf(address issueFor, address from) external;

    function burnTribes(address from, uint amount) external;

    function burnTribesOnBehalf(
        address burnForAddress,
        address from,
        uint amount
    ) external;

    function burnTribesToTarget(address from) external;

    function burnTribesToTargetOnBehalf(address burnForAddress, address from) external;

    function burnForRedemption(
        address deprecatedTribeProxy,
        address account,
        uint balance
    ) external;

    function setCurrentPeriodId(uint128 periodId) external;

    function liquidateAccount(address account, bool isSelfLiquidation)
        external
        returns (
            uint totalRedeemed,
            uint debtRemoved,
            uint escrowToLiquidate
        );

    function issueTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function burnTribesWithoutDebt(
        bytes32 currencyKey,
        address to,
        uint amount
    ) external returns (bool rateInvalid);

    function modifyDebtSharesForMigration(address account, uint amount) external;
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/addressresolver
contract AddressResolver is Owned, IAddressResolver {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned(_owner) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function importAddresses(bytes32[] calldata names, address[] calldata destinations) external onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            bytes32 name = names[i];
            address destination = destinations[i];
            repository[name] = destination;
            emit AddressImported(name, destination);
        }
    }

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
    }

    /* ========== VIEWS ========== */

    function areAddressesImported(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
        for (uint i = 0; i < names.length; i++) {
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

    function getTribe(bytes32 key) external view returns (address) {
        IIssuer issuer = IIssuer(repository["Issuer"]);
        require(address(issuer) != address(0), "Cannot find Issuer address");
        return address(issuer.tribes(key));
    }

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
}


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/mixinresolver
contract MixinResolver {
    AddressResolver public resolver;

    mapping(bytes32 => address) private addressCache;

    constructor(address _resolver) internal {
        resolver = AddressResolver(_resolver);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function combineArrays(bytes32[] memory first, bytes32[] memory second)
        internal
        pure
        returns (bytes32[] memory combination)
    {
        combination = new bytes32[](first.length + second.length);

        for (uint i = 0; i < first.length; i++) {
            combination[i] = first[i];
        }

        for (uint j = 0; j < second.length; j++) {
            combination[first.length + j] = second[j];
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // Note: this function is public not external in order for it to be overridden and invoked via super in subclasses
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {}

    function rebuildCache() public {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        // The resolver must call this function whenver it updates its state
        for (uint i = 0; i < requiredAddresses.length; i++) {
            bytes32 name = requiredAddresses[i];
            // Note: can only be invoked once the resolver has all the targets needed added
            address destination =
                resolver.requireAndGetAddress(name, string(abi.encodePacked("Resolver missing target: ", name)));
            addressCache[name] = destination;
            emit CacheUpdated(name, destination);
        }
    }

    /* ========== VIEWS ========== */

    function isResolverCached() external view returns (bool) {
        bytes32[] memory requiredAddresses = resolverAddressesRequired();
        for (uint i = 0; i < requiredAddresses.length; i++) {
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


// https://docs.tribeone.io/contracts/source/interfaces/iflexiblestorage
interface IFlexibleStorage {
    // Views
    function getUIntValue(bytes32 contractName, bytes32 record) external view returns (uint);

    function getUIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (uint[] memory);

    function getIntValue(bytes32 contractName, bytes32 record) external view returns (int);

    function getIntValues(bytes32 contractName, bytes32[] calldata records) external view returns (int[] memory);

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

    function setUIntValue(
        bytes32 contractName,
        bytes32 record,
        uint value
    ) external;

    function setUIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        uint[] calldata values
    ) external;

    function setIntValue(
        bytes32 contractName,
        bytes32 record,
        int value
    ) external;

    function setIntValues(
        bytes32 contractName,
        bytes32[] calldata records,
        int[] calldata values
    ) external;

    function setAddressValue(
        bytes32 contractName,
        bytes32 record,
        address value
    ) external;

    function setAddressValues(
        bytes32 contractName,
        bytes32[] calldata records,
        address[] calldata values
    ) external;

    function setBoolValue(
        bytes32 contractName,
        bytes32 record,
        bool value
    ) external;

    function setBoolValues(
        bytes32 contractName,
        bytes32[] calldata records,
        bool[] calldata values
    ) external;

    function setBytes32Value(
        bytes32 contractName,
        bytes32 record,
        bytes32 value
    ) external;

    function setBytes32Values(
        bytes32 contractName,
        bytes32[] calldata records,
        bytes32[] calldata values
    ) external;
}


pragma experimental ABIEncoderV2;


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/MixinPerpsV2MarketSettings
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

    constructor(address _resolver) internal MixinResolver(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](1);
        addresses[0] = CONTRACT_FLEXIBLESTORAGE;
    }

    function _flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }

    /* ---------- Internals ---------- */

    function _parameter(bytes32 _marketKey, bytes32 key) internal view returns (uint value) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)));
    }

    function _takerFee(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE);
    }

    function _makerFee(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE);
    }

    function _takerFeeDelayedOrder(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE_DELAYED_ORDER);
    }

    function _makerFeeDelayedOrder(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE_DELAYED_ORDER);
    }

    function _takerFeeOffchainDelayedOrder(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_TAKER_FEE_OFFCHAIN_DELAYED_ORDER);
    }

    function _makerFeeOffchainDelayedOrder(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAKER_FEE_OFFCHAIN_DELAYED_ORDER);
    }

    function _nextPriceConfirmWindow(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW);
    }

    function _delayedOrderConfirmWindow(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_DELAYED_ORDER_CONFIRM_WINDOW);
    }

    function _offchainDelayedOrderMinAge(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MIN_AGE);
    }

    function _offchainDelayedOrderMaxAge(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MAX_AGE);
    }

    function _maxLeverage(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_LEVERAGE);
    }

    function _maxMarketValue(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_MARKET_VALUE);
    }

    function _skewScale(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MIN_SKEW_SCALE);
    }

    function _maxFundingVelocity(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_FUNDING_VELOCITY);
    }

    function _minDelayTimeDelta(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MIN_DELAY_TIME_DELTA);
    }

    function _maxDelayTimeDelta(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_DELAY_TIME_DELTA);
    }

    function _offchainMarketKey(bytes32 _marketKey) internal view returns (bytes32) {
        return
            _flexibleStorage().getBytes32Value(
                SETTING_CONTRACT_NAME,
                keccak256(abi.encodePacked(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY))
            );
    }

    function _offchainPriceDivergence(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_OFFCHAIN_PRICE_DIVERGENCE);
    }

    function _liquidationPremiumMultiplier(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_LIQUIDATION_PREMIUM_MULTIPLIER);
    }

    function _maxLiquidationDelta(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_LIQUIDAION_DELTA);
    }

    function _maxPD(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_MAX_LIQUIDATION_PD);
    }

    function _liquidationBufferRatio(bytes32 _marketKey) internal view returns (uint) {
        return _parameter(_marketKey, PARAMETER_LIQUIDATION_BUFFER_RATIO);
    }

    function _minKeeperFee() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE);
    }

    function _maxKeeperFee() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MAX_KEEPER_FEE);
    }

    function _liquidationFeeRatio() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO);
    }

    function _minInitialMargin() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN);
    }

    function _keeperLiquidationFee() internal view returns (uint) {
        return _flexibleStorage().getUIntValue(SETTING_CONTRACT_NAME, SETTING_KEEPER_LIQUIRATION_FEE);
    }
}


interface IPerpsV2MarketSettings {
    struct Parameters {
        uint takerFee;
        uint makerFee;
        uint takerFeeDelayedOrder;
        uint makerFeeDelayedOrder;
        uint takerFeeOffchainDelayedOrder;
        uint makerFeeOffchainDelayedOrder;
        uint maxLeverage;
        uint maxMarketValue;
        uint maxFundingVelocity;
        uint skewScale;
        uint nextPriceConfirmWindow;
        uint delayedOrderConfirmWindow;
        uint minDelayTimeDelta;
        uint maxDelayTimeDelta;
        uint offchainDelayedOrderMinAge;
        uint offchainDelayedOrderMaxAge;
        bytes32 offchainMarketKey;
        uint offchainPriceDivergence;
        uint liquidationPremiumMultiplier;
        uint liquidationBufferRatio;
        uint maxLiquidationDelta;
        uint maxPD;
    }

    function takerFee(bytes32 _marketKey) external view returns (uint);

    function makerFee(bytes32 _marketKey) external view returns (uint);

    function takerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function makerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function makerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint);

    function nextPriceConfirmWindow(bytes32 _marketKey) external view returns (uint);

    function delayedOrderConfirmWindow(bytes32 _marketKey) external view returns (uint);

    function offchainDelayedOrderMinAge(bytes32 _marketKey) external view returns (uint);

    function offchainDelayedOrderMaxAge(bytes32 _marketKey) external view returns (uint);

    function maxLeverage(bytes32 _marketKey) external view returns (uint);

    function maxMarketValue(bytes32 _marketKey) external view returns (uint);

    function maxFundingVelocity(bytes32 _marketKey) external view returns (uint);

    function skewScale(bytes32 _marketKey) external view returns (uint);

    function minDelayTimeDelta(bytes32 _marketKey) external view returns (uint);

    function maxDelayTimeDelta(bytes32 _marketKey) external view returns (uint);

    function offchainMarketKey(bytes32 _marketKey) external view returns (bytes32);

    function offchainPriceDivergence(bytes32 _marketKey) external view returns (uint);

    function liquidationPremiumMultiplier(bytes32 _marketKey) external view returns (uint);

    function maxPD(bytes32 _marketKey) external view returns (uint);

    function maxLiquidationDelta(bytes32 _marketKey) external view returns (uint);

    function liquidationBufferRatio(bytes32 _marketKey) external view returns (uint);

    function parameters(bytes32 _marketKey) external view returns (Parameters memory);

    function minKeeperFee() external view returns (uint);

    function maxKeeperFee() external view returns (uint);

    function liquidationFeeRatio() external view returns (uint);

    function minInitialMargin() external view returns (uint);

    function keeperLiquidationFee() external view returns (uint);
}


interface IFuturesMarketManager {
    function markets(uint index, uint pageSize) external view returns (address[] memory);

    function markets(
        uint index,
        uint pageSize,
        bool proxiedMarkets
    ) external view returns (address[] memory);

    function numMarkets() external view returns (uint);

    function numMarkets(bool proxiedMarkets) external view returns (uint);

    function allMarkets() external view returns (address[] memory);

    function allMarkets(bool proxiedMarkets) external view returns (address[] memory);

    function marketForKey(bytes32 marketKey) external view returns (address);

    function marketsForKeys(bytes32[] calldata marketKeys) external view returns (address[] memory);

    function totalDebt() external view returns (uint debt, bool isInvalid);

    function isEndorsed(address account) external view returns (bool);

    function allEndorsedAddresses() external view returns (address[] memory);

    function addEndorsedAddresses(address[] calldata addresses) external;

    function removeEndorsedAddresses(address[] calldata addresses) external;
}


interface IPerpsV2MarketBaseTypes {
    /* ========== TYPES ========== */

    enum OrderType {Atomic, Delayed, Offchain}

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


interface IPerpsV2MarketViews {
    /* ---------- Market Details ---------- */

    function marketKey() external view returns (bytes32 key);

    function baseAsset() external view returns (bytes32 key);

    function marketSize() external view returns (uint128 size);

    function marketSkew() external view returns (int128 skew);

    function fundingLastRecomputed() external view returns (uint32 timestamp);

    function fundingRateLastRecomputed() external view returns (int128 fundingRate);

    function fundingSequence(uint index) external view returns (int128 netFunding);

    function positions(address account) external view returns (IPerpsV2MarketBaseTypes.Position memory);

    function delayedOrders(address account) external view returns (IPerpsV2MarketBaseTypes.DelayedOrder memory);

    function assetPrice() external view returns (uint price, bool invalid);

    function fillPrice(int sizeDelta) external view returns (uint price, bool invalid);

    function marketSizes() external view returns (uint long, uint short);

    function marketDebt() external view returns (uint debt, bool isInvalid);

    function currentFundingRate() external view returns (int fundingRate);

    function currentFundingVelocity() external view returns (int fundingVelocity);

    function unrecordedFunding() external view returns (int funding, bool invalid);

    function fundingSequenceLength() external view returns (uint length);

    /* ---------- Position Details ---------- */

    function notionalValue(address account) external view returns (int value, bool invalid);

    function profitLoss(address account) external view returns (int pnl, bool invalid);

    function accruedFunding(address account) external view returns (int funding, bool invalid);

    function remainingMargin(address account) external view returns (uint marginRemaining, bool invalid);

    function accessibleMargin(address account) external view returns (uint marginAccessible, bool invalid);

    function liquidationPrice(address account) external view returns (uint price, bool invalid);

    function liquidationFee(address account) external view returns (uint);

    function isFlagged(address account) external view returns (bool);

    function canLiquidate(address account) external view returns (bool);

    function orderFee(int sizeDelta, IPerpsV2MarketBaseTypes.OrderType orderType)
        external
        view
        returns (uint fee, bool invalid);

    function postTradeDetails(
        int sizeDelta,
        uint tradePrice,
        IPerpsV2MarketBaseTypes.OrderType orderType,
        address sender
    )
        external
        view
        returns (
            uint margin,
            int size,
            uint price,
            uint liqPrice,
            uint fee,
            IPerpsV2MarketBaseTypes.Status status
        );
}


interface IPerpsV2Market {
    /* ========== FUNCTION INTERFACE ========== */

    /* ---------- Market Operations ---------- */

    function recomputeFunding() external returns (uint lastIndex);

    function transferMargin(int marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPosition(int sizeDelta, uint desiredFillPrice) external;

    function modifyPositionWithTracking(
        int sizeDelta,
        uint desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function closePosition(uint desiredFillPrice) external;

    function closePositionWithTracking(uint desiredFillPrice, bytes32 trackingCode) external;
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketSettings
contract PerpsV2MarketSettings is Owned, MixinPerpsV2MarketSettings, IPerpsV2MarketSettings {
    /* ========== CONSTANTS ========== */

    /* ---------- Address Resolver Configuration ---------- */
    bytes32 public constant CONTRACT_NAME = "PerpsV2MarketSettings";

    bytes32 internal constant CONTRACT_FUTURES_MARKET_MANAGER = "FuturesMarketManager";

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _resolver) public Owned(_owner) MixinPerpsV2MarketSettings(_resolver) {}

    /* ========== VIEWS ========== */

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinPerpsV2MarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_FUTURES_MARKET_MANAGER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function _futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURES_MARKET_MANAGER));
    }

    /* ---------- Getters ---------- */

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market.
     */
    function takerFee(bytes32 _marketKey) external view returns (uint) {
        return _takerFee(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market.
     */
    function makerFee(bytes32 _marketKey) public view returns (uint) {
        return _makerFee(_marketKey);
    }

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market using delayed order mechanism.
     */
    function takerFeeDelayedOrder(bytes32 _marketKey) external view returns (uint) {
        return _takerFeeDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market using delayed order mechanism.
     */
    function makerFeeDelayedOrder(bytes32 _marketKey) public view returns (uint) {
        return _makerFeeDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the heavy side of a perpsV2 market using offchain delayed order mechanism.
     */
    function takerFeeOffchainDelayedOrder(bytes32 _marketKey) external view returns (uint) {
        return _takerFeeOffchainDelayedOrder(_marketKey);
    }

    /*
     * The fee charged when opening a position on the light side of a perpsV2 market using offchain delayed order mechanism.
     */
    function makerFeeOffchainDelayedOrder(bytes32 _marketKey) public view returns (uint) {
        return _makerFeeOffchainDelayedOrder(_marketKey);
    }

    /*
     * The number of price update rounds during which confirming next-price is allowed
     */
    function nextPriceConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _nextPriceConfirmWindow(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function delayedOrderConfirmWindow(bytes32 _marketKey) public view returns (uint) {
        return _delayedOrderConfirmWindow(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function offchainDelayedOrderMinAge(bytes32 _marketKey) public view returns (uint) {
        return _offchainDelayedOrderMinAge(_marketKey);
    }

    /*
     * The amount of time in seconds which confirming delayed orders is allow
     */
    function offchainDelayedOrderMaxAge(bytes32 _marketKey) public view returns (uint) {
        return _offchainDelayedOrderMaxAge(_marketKey);
    }

    /*
     * The maximum allowable leverage in a market.
     */
    function maxLeverage(bytes32 _marketKey) public view returns (uint) {
        return _maxLeverage(_marketKey);
    }

    /*
     * The maximum allowable value (base asset) on each side of a market.
     */
    function maxMarketValue(bytes32 _marketKey) public view returns (uint) {
        return _maxMarketValue(_marketKey);
    }

    /*
     * The skew level at which the max funding velocity will be charged.
     */
    function skewScale(bytes32 _marketKey) public view returns (uint) {
        return _skewScale(_marketKey);
    }

    /*
     * The maximum theoretical funding velocity per day charged by a market.
     */
    function maxFundingVelocity(bytes32 _marketKey) public view returns (uint) {
        return _maxFundingVelocity(_marketKey);
    }

    /*
     * The off-chain delayed order lower bound whereby the desired delta must be greater than or equal to.
     */
    function minDelayTimeDelta(bytes32 _marketKey) public view returns (uint) {
        return _minDelayTimeDelta(_marketKey);
    }

    /*
     * The off-chain delayed order upper bound whereby the desired delta must be greater than or equal to.
     */
    function maxDelayTimeDelta(bytes32 _marketKey) public view returns (uint) {
        return _maxDelayTimeDelta(_marketKey);
    }

    /*
     * The off-chain delayed order market key, used to pause and resume offchain markets.
     */
    function offchainMarketKey(bytes32 _marketKey) public view returns (bytes32) {
        return _offchainMarketKey(_marketKey);
    }

    /*
     * The max divergence between onchain and offchain prices for an offchain delayed order execution.
     */
    function offchainPriceDivergence(bytes32 _marketKey) public view returns (uint) {
        return _offchainPriceDivergence(_marketKey);
    }

    /*
     * The liquidation premium multiplier applied when calculating the liquidation premium margin.
     */
    function liquidationPremiumMultiplier(bytes32 _marketKey) public view returns (uint) {
        return _liquidationPremiumMultiplier(_marketKey);
    }

    /*
     * Liquidation price buffer in basis points to prevent negative margin on liquidation.
     */
    function liquidationBufferRatio(bytes32 _marketKey) external view returns (uint) {
        return _liquidationBufferRatio(_marketKey);
    }

    /*
     * The maximum price impact to allow an instantaneous liquidation.
     */
    function maxLiquidationDelta(bytes32 _marketKey) public view returns (uint) {
        return _maxLiquidationDelta(_marketKey);
    }

    /*
     * The maximum premium/discount to allow an instantaneous liquidation.
     */
    function maxPD(bytes32 _marketKey) public view returns (uint) {
        return _maxPD(_marketKey);
    }

    function parameters(bytes32 _marketKey) external view returns (Parameters memory) {
        return
            Parameters(
                _takerFee(_marketKey),
                _makerFee(_marketKey),
                _takerFeeDelayedOrder(_marketKey),
                _makerFeeDelayedOrder(_marketKey),
                _takerFeeOffchainDelayedOrder(_marketKey),
                _makerFeeOffchainDelayedOrder(_marketKey),
                _maxLeverage(_marketKey),
                _maxMarketValue(_marketKey),
                _maxFundingVelocity(_marketKey),
                _skewScale(_marketKey),
                _nextPriceConfirmWindow(_marketKey),
                _delayedOrderConfirmWindow(_marketKey),
                _minDelayTimeDelta(_marketKey),
                _maxDelayTimeDelta(_marketKey),
                _offchainDelayedOrderMinAge(_marketKey),
                _offchainDelayedOrderMaxAge(_marketKey),
                _offchainMarketKey(_marketKey),
                _offchainPriceDivergence(_marketKey),
                _liquidationPremiumMultiplier(_marketKey),
                _liquidationBufferRatio(_marketKey),
                _maxLiquidationDelta(_marketKey),
                _maxPD(_marketKey)
            );
    }

    /*
     * The minimum amount of hUSD paid to a liquidator when they successfully liquidate a position.
     * This quantity must be no greater than `minInitialMargin`.
     */
    function minKeeperFee() external view returns (uint) {
        return _minKeeperFee();
    }

    /*
     * The maximum amount of hUSD paid to a liquidator when they successfully liquidate a position.
     */
    function maxKeeperFee() external view returns (uint) {
        return _maxKeeperFee();
    }

    /*
     * Liquidation fee basis points paid to liquidator.
     * Use together with minKeeperFee() and maxKeeperFee() to calculate the actual fee paid.
     */
    function liquidationFeeRatio() external view returns (uint) {
        return _liquidationFeeRatio();
    }

    /*
     * The minimum margin required to open a position.
     * This quantity must be no less than `minKeeperFee`.
     */
    function minInitialMargin() external view returns (uint) {
        return _minInitialMargin();
    }

    /*
     * The fixed fee sent to a keeper upon liquidation.
     */
    function keeperLiquidationFee() external view returns (uint) {
        return _keeperLiquidationFee();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /* ---------- Setters --------- */

    function _setParameter(
        bytes32 _marketKey,
        bytes32 key,
        uint value
    ) internal {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, keccak256(abi.encodePacked(_marketKey, key)), value);
        emit ParameterUpdated(_marketKey, key, value);
    }

    function setTakerFee(bytes32 _marketKey, uint _takerFee) public onlyOwner {
        require(_takerFee <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE, _takerFee);
    }

    function setMakerFee(bytes32 _marketKey, uint _makerFee) public onlyOwner {
        require(_makerFee <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE, _makerFee);
    }

    function setTakerFeeDelayedOrder(bytes32 _marketKey, uint _takerFeeDelayedOrder) public onlyOwner {
        require(_takerFeeDelayedOrder <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE_DELAYED_ORDER, _takerFeeDelayedOrder);
    }

    function setMakerFeeDelayedOrder(bytes32 _marketKey, uint _makerFeeDelayedOrder) public onlyOwner {
        require(_makerFeeDelayedOrder <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE_DELAYED_ORDER, _makerFeeDelayedOrder);
    }

    function setTakerFeeOffchainDelayedOrder(bytes32 _marketKey, uint _takerFeeOffchainDelayedOrder) public onlyOwner {
        require(_takerFeeOffchainDelayedOrder <= 1e18, "taker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_TAKER_FEE_OFFCHAIN_DELAYED_ORDER, _takerFeeOffchainDelayedOrder);
    }

    function setMakerFeeOffchainDelayedOrder(bytes32 _marketKey, uint _makerFeeOffchainDelayedOrder) public onlyOwner {
        require(_makerFeeOffchainDelayedOrder <= 1e18, "maker fee greater than 1");
        _setParameter(_marketKey, PARAMETER_MAKER_FEE_OFFCHAIN_DELAYED_ORDER, _makerFeeOffchainDelayedOrder);
    }

    function setNextPriceConfirmWindow(bytes32 _marketKey, uint _nextPriceConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_NEXT_PRICE_CONFIRM_WINDOW, _nextPriceConfirmWindow);
    }

    function setDelayedOrderConfirmWindow(bytes32 _marketKey, uint _delayedOrderConfirmWindow) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_DELAYED_ORDER_CONFIRM_WINDOW, _delayedOrderConfirmWindow);
    }

    function setOffchainDelayedOrderMinAge(bytes32 _marketKey, uint _offchainDelayedOrderMinAge) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MIN_AGE, _offchainDelayedOrderMinAge);
    }

    function setOffchainDelayedOrderMaxAge(bytes32 _marketKey, uint _offchainDelayedOrderMaxAge) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_DELAYED_ORDER_MAX_AGE, _offchainDelayedOrderMaxAge);
    }

    function setMaxLeverage(bytes32 _marketKey, uint _maxLeverage) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LEVERAGE, _maxLeverage);
    }

    function setMaxMarketValue(bytes32 _marketKey, uint _maxMarketValue) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_MARKET_VALUE, _maxMarketValue);
    }

    // Before altering parameters relevant to funding rates, outstanding funding on the underlying market
    // must be recomputed, otherwise already-accrued but unrealised funding in the market can change.

    function _recomputeFunding(bytes32 _marketKey) internal {
        address marketAddress = _futuresMarketManager().marketForKey(_marketKey);

        IPerpsV2MarketViews marketView = IPerpsV2MarketViews(marketAddress);
        if (marketView.marketSize() > 0) {
            IPerpsV2Market market = IPerpsV2Market(marketAddress);
            // only recompute funding when market has positions, this check is important for initial setup
            market.recomputeFunding();
        }
    }

    function setMaxFundingVelocity(bytes32 _marketKey, uint _maxFundingVelocity) public onlyOwner {
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MAX_FUNDING_VELOCITY, _maxFundingVelocity);
    }

    function setSkewScale(bytes32 _marketKey, uint _skewScale) public onlyOwner {
        require(_skewScale > 0, "cannot set skew scale 0");
        _recomputeFunding(_marketKey);
        _setParameter(_marketKey, PARAMETER_MIN_SKEW_SCALE, _skewScale);
    }

    function setMinDelayTimeDelta(bytes32 _marketKey, uint _minDelayTimeDelta) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MIN_DELAY_TIME_DELTA, _minDelayTimeDelta);
    }

    function setMaxDelayTimeDelta(bytes32 _marketKey, uint _maxDelayTimeDelta) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_DELAY_TIME_DELTA, _maxDelayTimeDelta);
    }

    function setOffchainMarketKey(bytes32 _marketKey, bytes32 _offchainMarketKey) public onlyOwner {
        _flexibleStorage().setBytes32Value(
            SETTING_CONTRACT_NAME,
            keccak256(abi.encodePacked(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY)),
            _offchainMarketKey
        );
        emit ParameterUpdatedBytes32(_marketKey, PARAMETER_OFFCHAIN_MARKET_KEY, _offchainMarketKey);
    }

    /*
     * The max divergence between onchain and offchain prices for an offchain delayed order execution.
     */
    function setOffchainPriceDivergence(bytes32 _marketKey, uint _offchainPriceDivergence) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_OFFCHAIN_PRICE_DIVERGENCE, _offchainPriceDivergence);
    }

    function setLiquidationPremiumMultiplier(bytes32 _marketKey, uint _liquidationPremiumMultiplier) public onlyOwner {
        require(_liquidationPremiumMultiplier > 0, "cannot set liquidation premium multiplier 0");
        _setParameter(_marketKey, PARAMETER_LIQUIDATION_PREMIUM_MULTIPLIER, _liquidationPremiumMultiplier);
    }

    function setLiquidationBufferRatio(bytes32 _marketKey, uint _ratio) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_LIQUIDATION_BUFFER_RATIO, _ratio);
    }

    function setMaxLiquidationDelta(bytes32 _marketKey, uint _maxLiquidationDelta) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LIQUIDAION_DELTA, _maxLiquidationDelta);
    }

    function setMaxPD(bytes32 _marketKey, uint _maxPD) public onlyOwner {
        _setParameter(_marketKey, PARAMETER_MAX_LIQUIDATION_PD, _maxPD);
    }

    function setParameters(bytes32 _marketKey, Parameters calldata _parameters) external onlyOwner {
        _recomputeFunding(_marketKey);
        setTakerFee(_marketKey, _parameters.takerFee);
        setMakerFee(_marketKey, _parameters.makerFee);
        setMaxLeverage(_marketKey, _parameters.maxLeverage);
        setMaxMarketValue(_marketKey, _parameters.maxMarketValue);
        setMaxFundingVelocity(_marketKey, _parameters.maxFundingVelocity);
        setSkewScale(_marketKey, _parameters.skewScale);
        setTakerFeeDelayedOrder(_marketKey, _parameters.takerFeeDelayedOrder);
        setMakerFeeDelayedOrder(_marketKey, _parameters.makerFeeDelayedOrder);
        setNextPriceConfirmWindow(_marketKey, _parameters.nextPriceConfirmWindow);
        setDelayedOrderConfirmWindow(_marketKey, _parameters.delayedOrderConfirmWindow);
        setMinDelayTimeDelta(_marketKey, _parameters.minDelayTimeDelta);
        setMaxDelayTimeDelta(_marketKey, _parameters.maxDelayTimeDelta);
        setTakerFeeOffchainDelayedOrder(_marketKey, _parameters.takerFeeOffchainDelayedOrder);
        setMakerFeeOffchainDelayedOrder(_marketKey, _parameters.makerFeeOffchainDelayedOrder);
        setOffchainDelayedOrderMinAge(_marketKey, _parameters.offchainDelayedOrderMinAge);
        setOffchainDelayedOrderMaxAge(_marketKey, _parameters.offchainDelayedOrderMaxAge);
        setOffchainMarketKey(_marketKey, _parameters.offchainMarketKey);
        setOffchainPriceDivergence(_marketKey, _parameters.offchainPriceDivergence);
        setLiquidationPremiumMultiplier(_marketKey, _parameters.liquidationPremiumMultiplier);
        setLiquidationBufferRatio(_marketKey, _parameters.liquidationBufferRatio);
        setMaxLiquidationDelta(_marketKey, _parameters.maxLiquidationDelta);
        setMaxPD(_marketKey, _parameters.maxPD);
    }

    function setMinKeeperFee(uint _hUSD) external onlyOwner {
        require(_hUSD <= _minInitialMargin(), "min margin < liquidation fee");
        if (_maxKeeperFee() > 0) {
            // only check if already set
            require(_hUSD <= _maxKeeperFee(), "max fee < min fee");
        }
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_KEEPER_FEE, _hUSD);
        emit MinKeeperFeeUpdated(_hUSD);
    }

    function setMaxKeeperFee(uint _hUSD) external onlyOwner {
        require(_hUSD >= _minKeeperFee(), "max fee < min fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MAX_KEEPER_FEE, _hUSD);
        emit MaxKeeperFeeUpdated(_hUSD);
    }

    function setLiquidationFeeRatio(uint _ratio) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_LIQUIDATION_FEE_RATIO, _ratio);
        emit LiquidationFeeRatioUpdated(_ratio);
    }

    function setMinInitialMargin(uint _minMargin) external onlyOwner {
        require(_minKeeperFee() <= _minMargin, "min margin < liquidation fee");
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_MIN_INITIAL_MARGIN, _minMargin);
        emit MinInitialMarginUpdated(_minMargin);
    }

    function setKeeperLiquidationFee(uint _keeperFee) external onlyOwner {
        _flexibleStorage().setUIntValue(SETTING_CONTRACT_NAME, SETTING_KEEPER_LIQUIRATION_FEE, _keeperFee);
        emit KeeperLiquidationFeeUpdated(_keeperFee);
    }

    /* ========== EVENTS ========== */

    event ParameterUpdated(bytes32 indexed marketKey, bytes32 indexed parameter, uint value);
    event ParameterUpdatedBytes32(bytes32 indexed marketKey, bytes32 indexed parameter, bytes32 value);
    event MinKeeperFeeUpdated(uint hUSD);
    event MaxKeeperFeeUpdated(uint hUSD);
    event LiquidationFeeRatioUpdated(uint bps);
    event LiquidationBufferRatioUpdated(uint bps);
    event MinInitialMarginUpdated(uint minMargin);
    event KeeperLiquidationFeeUpdated(uint keeperFee);
}