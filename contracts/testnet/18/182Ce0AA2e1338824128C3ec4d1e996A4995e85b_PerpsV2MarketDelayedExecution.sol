/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

/* Tribeone: PerpsV2MarketDelayedExecution.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/PerpsV2MarketDelayedExecution.sol
* Docs: https://docs.tribeone.io/contracts/PerpsV2MarketDelayedExecution
*
* Contract Dependencies: 
*	- IAddressResolver
*	- IPerpsV2MarketBaseTypes
*	- IPerpsV2MarketDelayedExecution
*	- MixinPerpsV2MarketSettings
*	- MixinResolver
*	- Owned
*	- PerpsV2MarketBase
*	- PerpsV2MarketProxyable
*	- Proxyable
* Libraries: 
*	- SafeDecimalMath
*	- SafeMath
*	- SignedSafeDecimalMath
*	- SignedSafeMath
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


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxy
contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) public Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
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
    function() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall
        target.setMessageSender(msg.sender);

        assembly {
            let free_ptr := mload(0x40)
            calldatacopy(free_ptr, 0, calldatasize)

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas, sload(target_slot), callvalue, free_ptr, calldatasize, 0, 0)
            returndatacopy(free_ptr, 0, returndatasize)

            if iszero(result) {
                revert(free_ptr, returndatasize)
            }
            return(free_ptr, returndatasize)
        }
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}


// Inheritance


// Internal references


// https://docs.tribeone.io/contracts/source/contracts/proxyable
contract Proxyable is Owned {
    // This contract should be treated like an abstract contract

    /* The proxy this contract exists behind. */
    Proxy public proxy;

    /* The caller of the proxy, passed through to this contract.
     * Note that every function using this member must apply the onlyProxy or
     * optionalProxy modifiers, otherwise their invocations can use stale values. */
    address public messageSender;

    constructor(address payable _proxy) internal {
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

    modifier onlyProxy {
        _onlyProxy();
        _;
    }

    function _onlyProxy() private view {
        require(Proxy(msg.sender) == proxy, "Only the proxy can call");
    }

    modifier optionalProxy {
        _optionalProxy();
        _;
    }

    function _optionalProxy() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
    }

    modifier optionalProxy_onlyOwner {
        _optionalProxy_onlyOwner();
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function _optionalProxy_onlyOwner() private {
        if (Proxy(msg.sender) != proxy && messageSender != msg.sender) {
            messageSender = msg.sender;
        }
        require(messageSender == owner, "Owner only function");
    }

    event ProxyUpdated(address proxyAddress);
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


/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 private constant _INT256_MIN = -2**255;

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


// TODO: Test suite

// https://docs.tribeone.io/contracts/SignedSafeDecimalMath
library SignedSafeDecimalMath {
    using SignedSafeMath for int;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    int public constant UNIT = int(10**uint(decimals));

    /* The number representing 1.0 for higher fidelity numbers. */
    int public constant PRECISE_UNIT = int(10**uint(highPrecisionDecimals));
    int private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = int(10**uint(highPrecisionDecimals - decimals));

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (int) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (int) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Rounds an input with an extra zero of precision, returning the result without the extra zero.
     * Half increments round away from zero; positive numbers at a half increment are rounded up,
     * while negative such numbers are rounded down. This behaviour is designed to be consistent with the
     * unsigned version of this library (SafeDecimalMath).
     */
    function _roundDividingByTen(int valueTimesTen) private pure returns (int) {
        int increment;
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
    function multiplyDecimal(int x, int y) internal pure returns (int) {
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
    function _multiplyDecimalRound(
        int x,
        int y,
        int precisionUnit
    ) private pure returns (int) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        int quotientTimesTen = x.mul(y) / (precisionUnit / 10);
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
    function multiplyDecimalRoundPrecise(int x, int y) internal pure returns (int) {
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
    function multiplyDecimalRound(int x, int y) internal pure returns (int) {
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
    function divideDecimal(int x, int y) internal pure returns (int) {
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
    function _divideDecimalRound(
        int x,
        int y,
        int precisionUnit
    ) private pure returns (int) {
        int resultTimesTen = x.mul(precisionUnit * 10).div(y);
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
    function divideDecimalRound(int x, int y) internal pure returns (int) {
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
    function divideDecimalRoundPrecise(int x, int y) internal pure returns (int) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(int i) internal pure returns (int) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(int i) internal pure returns (int) {
        int quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);
        return _roundDividingByTen(quotientTimesTen);
    }
}


// Libraries


// https://docs.tribeone.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
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
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
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
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

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
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
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
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
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
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

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
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
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
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
}


// https://docs.tribeone.io/contracts/source/interfaces/IDirectIntegration
interface IDirectIntegrationManager {
    struct ParameterIntegrationSettings {
        bytes32 currencyKey;
        address dexPriceAggregator;
        address atomicEquivalentForDexPricing;
        uint atomicExchangeFeeRate;
        uint atomicTwapWindow;
        uint atomicMaxVolumePerBlock;
        uint atomicVolatilityConsiderationWindow;
        uint atomicVolatilityUpdateThreshold;
        uint exchangeFeeRate;
        uint exchangeMaxDynamicFee;
        uint exchangeDynamicFeeRounds;
        uint exchangeDynamicFeeThreshold;
        uint exchangeDynamicFeeWeightDecay;
    }

    function getExchangeParameters(address integration, bytes32 key)
        external
        view
        returns (ParameterIntegrationSettings memory settings);

    function setExchangeParameters(
        address integration,
        bytes32[] calldata currencyKeys,
        ParameterIntegrationSettings calldata params
    ) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iexchangerates
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

    function anyRateIsInvalidAtRound(bytes32[] calldata currencyKeys, uint[] calldata roundIds) external view returns (bool);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function effectiveAtomicValueAndRates(
        IDirectIntegrationManager.ParameterIntegrationSettings calldata sourceSettings,
        uint sourceAmount,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata destinationSettings,
        IDirectIntegrationManager.ParameterIntegrationSettings calldata usdSettings
    )
        external
        view
        returns (
            uint value,
            uint systemValue,
            uint systemSourceRate,
            uint systemDestinationRate
        );

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(
        bytes32 currencyKey,
        uint numRounds,
        uint roundId
    ) external view returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    function tribeTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function tribeTooVolatileForAtomicExchange(IDirectIntegrationManager.ParameterIntegrationSettings calldata settings)
        external
        view
        returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey)
        external
        returns (
            uint rate,
            bool broken,
            bool invalid
        );
}


interface IVirtualTribe {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function tribe() external view returns (ITribe);

    // Mutative functions
    function settle(address account) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/iexchanger
interface IExchanger {
    struct ExchangeEntrySettlement {
        bytes32 src;
        uint amount;
        bytes32 dest;
        uint reclaim;
        uint rebate;
        uint srcRoundIdAtPeriodEnd;
        uint destRoundIdAtPeriodEnd;
        uint timestamp;
    }

    struct ExchangeEntry {
        uint sourceRate;
        uint destinationRate;
        uint destinationAmount;
        uint exchangeFeeRate;
        uint exchangeDynamicFeeRate;
        uint roundIdForSrc;
        uint roundIdForDest;
        uint sourceAmountAfterSettlement;
    }

    // Views
    function calculateAmountAfterSettlement(
        address from,
        bytes32 currencyKey,
        uint amount,
        uint refunded
    ) external view returns (uint amountAfterSettlement);

    function isTribeRateInvalid(bytes32 currencyKey) external view returns (bool);

    function maxSecsLeftInWaitingPeriod(address account, bytes32 currencyKey) external view returns (uint);

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint reclaimAmount,
            uint rebateAmount,
            uint numEntries
        );

    function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        );

    function priceDeviationThresholdFactor() external view returns (uint);

    function waitingPeriodSecs() external view returns (uint);

    function lastExchangeRate(bytes32 currencyKey) external view returns (uint);

    // Mutative functions
    function exchange(
        address exchangeForAddress,
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bool virtualTribe,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualTribe vTribe);

    function exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );
}

// Used to have strongly-typed access to internal mutative functions in Tribeone
interface ITribeoneInternal {
    function emitExchangeTracking(
        bytes32 trackingCode,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        uint256 fee
    ) external;

    function emitTribeExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint fromAmount,
        bytes32 toCurrencyKey,
        uint toAmount,
        address toAddress
    ) external;

    function emitAtomicTribeExchange(
        address account,
        bytes32 fromCurrencyKey,
        uint fromAmount,
        bytes32 toCurrencyKey,
        uint toAmount,
        address toAddress
    ) external;

    function emitExchangeReclaim(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;

    function emitExchangeRebate(
        address account,
        bytes32 currencyKey,
        uint amount
    ) external;
}

interface IExchangerInternalDebtCache {
    function updateCachedTribeDebtsWithRates(bytes32[] calldata currencyKeys, uint[] calldata currencyRates) external;

    function updateCachedTribeDebts(bytes32[] calldata currencyKeys) external;
}


// https://docs.tribeone.io/contracts/source/interfaces/isystemstatus
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

    function requireExchangeBetweenTribesAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireTribeActive(bytes32 currencyKey) external view;

    function tribeSuspended(bytes32 currencyKey) external view returns (bool);

    function requireTribesActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function futuresSuspension() external view returns (bool suspended, uint248 reason);

    function tribeExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function tribeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function futuresMarketSuspension(bytes32 marketKey) external view returns (bool suspended, uint248 reason);

    function getTribeExchangeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getTribeSuspensions(bytes32[] calldata tribes)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendTribe(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
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


// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketState
interface IPerpsV2MarketState {
    function marketKey() external view returns (bytes32);

    function baseAsset() external view returns (bytes32);

    function marketSize() external view returns (uint128);

    function marketSkew() external view returns (int128);

    function fundingLastRecomputed() external view returns (uint32);

    function fundingSequence(uint) external view returns (int128);

    function fundingRateLastRecomputed() external view returns (int128);

    function positions(address) external view returns (IPerpsV2MarketBaseTypes.Position memory);

    function delayedOrders(address) external view returns (IPerpsV2MarketBaseTypes.DelayedOrder memory);

    function positionFlagger(address) external view returns (address);

    function entryDebtCorrection() external view returns (int128);

    function nextPositionId() external view returns (uint64);

    function fundingSequenceLength() external view returns (uint);

    function isFlagged(address) external view returns (bool);

    function getPositionAddressesPage(uint, uint) external view returns (address[] memory);

    function getPositionAddressesLength() external view returns (uint);

    function getDelayedOrderAddressesPage(uint, uint) external view returns (address[] memory);

    function getDelayedOrderAddressesLength() external view returns (uint);

    function getFlaggedAddressesPage(uint, uint) external view returns (address[] memory);

    function getFlaggedAddressesLength() external view returns (uint);

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


// Inheritance


// Libraries


// Internal references


// Internal references


// Use internal interface (external functions not present in IFuturesMarketManager)
interface IFuturesMarketManagerInternal {
    function issueHUSD(address account, uint amount) external;

    function burnHUSD(address account, uint amount) external returns (uint postReclamationAmount);

    function payFee(uint amount) external;

    function isEndorsed(address account) external view returns (bool);
}

// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketBase
contract PerpsV2MarketBase is Owned, MixinPerpsV2MarketSettings, IPerpsV2MarketBaseTypes {
    /* ========== LIBRARIES ========== */

    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SignedSafeMath for int;
    using SignedSafeDecimalMath for int;

    /* ========== CONSTANTS ========== */

    // This is the same unit as used inside `SignedSafeDecimalMath`.
    int private constant _UNIT = int(10**uint(18));

    //slither-disable-next-line naming-convention
    bytes32 internal constant hUSD = "hUSD";

    /* ========== STATE VARIABLES ========== */

    IPerpsV2MarketState public marketState;

    /* ---------- Address Resolver Configuration ---------- */

    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 internal constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 internal constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    bytes32 internal constant CONTRACT_PERPSV2MARKETSETTINGS = "PerpsV2MarketSettings";
    bytes32 internal constant CONTRACT_PERPSV2EXCHANGERATE = "PerpsV2ExchangeRate";
    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";

    // Holds the revert message for each type of error.
    mapping(uint8 => string) internal _errorMessages;

    // convenience struct for passing params between position modification helper functions
    struct TradeParams {
        int sizeDelta;
        uint oraclePrice;
        uint fillPrice;
        uint desiredFillPrice;
        uint takerFee;
        uint makerFee;
        bytes32 trackingCode; // optional tracking code for volume source fee sharing
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _marketState,
        address _owner,
        address _resolver
    ) public MixinPerpsV2MarketSettings(_resolver) Owned(_owner) {
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

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinPerpsV2MarketSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](7);
        newAddresses[0] = CONTRACT_EXCHANGER;
        newAddresses[1] = CONTRACT_EXRATES;
        newAddresses[2] = CONTRACT_SYSTEMSTATUS;
        newAddresses[3] = CONTRACT_FUTURESMARKETMANAGER;
        newAddresses[4] = CONTRACT_PERPSV2MARKETSETTINGS;
        newAddresses[5] = CONTRACT_PERPSV2EXCHANGERATE;
        newAddresses[6] = CONTRACT_FLEXIBLESTORAGE;
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
    function _proportionalSkew() internal view returns (int) {
        int pSkew = int(marketState.marketSkew()).divideDecimal(int(_skewScale(_marketKey())));

        // Ensures the proportionalSkew is between -1 and 1.
        return _min(_max(-_UNIT, pSkew), _UNIT);
    }

    function _proportionalElapsed() internal view returns (int) {
        return int(block.timestamp.sub(marketState.fundingLastRecomputed())).divideDecimal(1 days);
    }

    function _currentFundingVelocity() internal view returns (int) {
        int maxFundingVelocity = int(_maxFundingVelocity(_marketKey()));
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
    function _currentFundingRate() internal view returns (int) {
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
            int(marketState.fundingRateLastRecomputed()).add(
                _currentFundingVelocity().multiplyDecimal(_proportionalElapsed())
            );
    }

    function _unrecordedFunding(uint price) internal view returns (int) {
        int nextFundingRate = _currentFundingRate();
        // note the minus sign: funding flows in the opposite direction to the skew.
        int avgFundingRate = -(int(marketState.fundingRateLastRecomputed()).add(nextFundingRate)).divideDecimal(_UNIT * 2);
        return avgFundingRate.multiplyDecimal(_proportionalElapsed()).multiplyDecimal(int(price));
    }

    /*
     * The new entry in the funding sequence, appended when funding is recomputed. It is the sum of the
     * last entry and the unrecorded funding, so the sequence accumulates running total over the market's lifetime.
     */
    function _nextFundingEntry(uint price) internal view returns (int) {
        return int(marketState.fundingSequence(_latestFundingIndex())).add(_unrecordedFunding(price));
    }

    function _netFundingPerUnit(uint startIndex, uint price) internal view returns (int) {
        // Compute the net difference between start and end indices.
        return _nextFundingEntry(price).sub(marketState.fundingSequence(startIndex));
    }

    /* ---------- Position Details ---------- */

    /*
     * Determines whether a change in a position's size would violate the max market value constraint.
     */
    function _orderSizeTooLarge(
        uint maxSize,
        int oldSize,
        int newSize
    ) internal view returns (bool) {
        // Allow users to reduce an order no matter the market conditions.
        if (_sameSide(oldSize, newSize) && _abs(newSize) <= _abs(oldSize)) {
            return false;
        }

        // Either the user is flipping sides, or they are increasing an order on the same side they're already on;
        // we check that the side of the market their order is on would not break the limit.
        int newSkew = int(marketState.marketSkew()).sub(oldSize).add(newSize);
        int newMarketSize = int(marketState.marketSize()).sub(_signedAbs(oldSize)).add(_signedAbs(newSize));

        int newSideSize;
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

    function _notionalValue(int positionSize, uint price) internal pure returns (int value) {
        return positionSize.multiplyDecimal(int(price));
    }

    function _profitLoss(Position memory position, uint price) internal pure returns (int pnl) {
        int priceShift = int(price).sub(int(position.lastPrice));
        return int(position.size).multiplyDecimal(priceShift);
    }

    function _accruedFunding(Position memory position, uint price) internal view returns (int funding) {
        uint lastModifiedIndex = position.lastFundingIndex;
        if (lastModifiedIndex == 0) {
            return 0; // The position does not exist -- no funding.
        }
        int net = _netFundingPerUnit(lastModifiedIndex, price);
        return int(position.size).multiplyDecimal(net);
    }

    /*
     * The initial margin of a position, plus any PnL and funding it has accrued. The resulting value may be negative.
     */
    function _marginPlusProfitFunding(Position memory position, uint price) internal view returns (int) {
        int funding = _accruedFunding(position, price);
        return int(position.margin).add(_profitLoss(position, price)).add(funding);
    }

    /*
     * The value in a position's margin after a deposit or withdrawal, accounting for funding and profit.
     * If the resulting margin would be negative or below the liquidation threshold, an appropriate error is returned.
     * If the result is not an error, callers of this function that use it to update a position's margin
     * must ensure that this is accompanied by a corresponding debt correction update, as per `_applyDebtCorrection`.
     */
    function _recomputeMarginWithDelta(
        Position memory position,
        uint price,
        int marginDelta
    ) internal view returns (uint margin, Status statusCode) {
        int newMargin = _marginPlusProfitFunding(position, price).add(marginDelta);
        if (newMargin < 0) {
            return (0, Status.InsufficientMargin);
        }

        uint uMargin = uint(newMargin);
        int positionSize = int(position.size);
        // minimum margin beyond which position can be liquidated
        uint lMargin = _liquidationMargin(positionSize, price);
        if (positionSize != 0 && uMargin <= lMargin) {
            return (uMargin, Status.CanLiquidate);
        }

        return (uMargin, Status.Ok);
    }

    function _remainingMargin(Position memory position, uint price) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, price);

        // If the margin went past zero, the position should have been liquidated - return zero remaining margin.
        return uint(_max(0, remaining));
    }

    /*
     * @dev Similar to _remainingMargin except it accounts for the premium and fees to be paid upon liquidation.
     */
    function _remainingLiquidatableMargin(Position memory position, uint price) internal view returns (uint) {
        int remaining = _marginPlusProfitFunding(position, price).sub(int(_liquidationPremium(position.size, price)));
        return uint(_max(0, remaining));
    }

    function _accessibleMargin(Position memory position, uint price) internal view returns (uint) {
        // Ugly solution to rounding safety: leave up to an extra tenth of a cent in the account/leverage
        // This should guarantee that the value returned here can always be withdrawn, but there may be
        // a little extra actually-accessible value left over, depending on the position size and margin.
        uint milli = uint(_UNIT / 1000);
        int maxLeverage = int(_maxLeverage(_marketKey()).sub(milli));
        uint inaccessible = _abs(_notionalValue(position.size, price).divideDecimal(maxLeverage));

        // If the user has a position open, we'll enforce a min initial margin requirement.
        if (0 < inaccessible) {
            uint minInitialMargin = _minInitialMargin();
            if (inaccessible < minInitialMargin) {
                inaccessible = minInitialMargin;
            }
            inaccessible = inaccessible.add(milli);
        }

        uint remaining = _remainingMargin(position, price);
        if (remaining <= inaccessible) {
            return 0;
        }

        return remaining.sub(inaccessible);
    }

    /**
     * The fee charged from the margin during liquidation. Fee is proportional to position size
     * but is between _minKeeperFee() and _maxKeeperFee() expressed in hUSD to prevent underincentivising
     * liquidations of small positions, or overpaying.
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in hUSD fixed point decimal units
     * @return lFee liquidation fee to be paid to liquidator in hUSD fixed point decimal units
     */
    function _liquidationFee(int positionSize, uint price) internal view returns (uint lFee) {
        // size * price * fee-ratio
        uint proportionalFee = _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationFeeRatio());
        uint maxFee = _maxKeeperFee();
        uint cappedProportionalFee = proportionalFee > maxFee ? maxFee : proportionalFee;
        uint minFee = _minKeeperFee();

        // max(proportionalFee, minFee) - to prevent not incentivising liquidations enough
        return cappedProportionalFee > minFee ? cappedProportionalFee : minFee; // not using _max() helper because it's for signed ints
    }

    /**
     * The minimal margin at which liquidation can happen.
     * Is the sum of liquidationBuffer, liquidationFee (for flagger) and keeperLiquidationFee (for liquidator)
     * @param positionSize size of position in fixed point decimal baseAsset units
     * @param price price of single baseAsset unit in hUSD fixed point decimal units
     * @return lMargin liquidation margin to maintain in hUSD fixed point decimal units
     * @dev The liquidation margin contains a buffer that is proportional to the position
     * size. The buffer should prevent liquidation happening at negative margin (due to next price being worse)
     * so that stakers would not leak value to liquidators through minting rewards that are not from the
     * account's margin.
     */
    function _liquidationMargin(int positionSize, uint price) internal view returns (uint lMargin) {
        uint liquidationBuffer =
            _abs(positionSize).multiplyDecimal(price).multiplyDecimal(_liquidationBufferRatio(_marketKey()));
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
     * @return The premium to be paid upon liquidation in hUSD
     */
    function _liquidationPremium(int positionSize, uint currentPrice) internal view returns (uint) {
        if (positionSize == 0) {
            return 0;
        }

        // note: this is the same as fillPrice() where the skew is 0.
        uint notional = _abs(_notionalValue(positionSize, currentPrice));

        return
            _abs(positionSize).divideDecimal(_skewScale(_marketKey())).multiplyDecimal(notional).multiplyDecimal(
                _liquidationPremiumMultiplier(_marketKey())
            );
    }

    function _canLiquidate(Position memory position, uint price) internal view returns (bool) {
        // No liquidating empty positions.
        if (position.size == 0) {
            return false;
        }

        return _remainingLiquidatableMargin(position, price) <= _liquidationMargin(int(position.size), price);
    }

    function _currentLeverage(
        Position memory position,
        uint price,
        uint remainingMargin_
    ) internal pure returns (int leverage) {
        // No position is open, or it is ready to be liquidated; leverage goes to nil
        if (remainingMargin_ == 0) {
            return 0;
        }

        return _notionalValue(position.size, price).divideDecimal(int(remainingMargin_));
    }

    function _orderFee(TradeParams memory params, uint dynamicFeeRate) internal view returns (uint fee) {
        // usd value of the difference in position (using the p/d-adjusted price).
        int marketSkew = marketState.marketSkew();
        int notionalDiff = params.sizeDelta.multiplyDecimal(int(params.fillPrice));

        // minimum fee to pay regardless (due to dynamic fees).
        uint baseFee = _abs(notionalDiff).multiplyDecimal(dynamicFeeRate);

        // does this trade keep the skew on one side?
        if (_sameSide(marketSkew + params.sizeDelta, marketSkew)) {
            // use a flat maker/taker fee for the entire size depending on whether the skew is increased or reduced.
            //
            // if the order is submitted on the same side as the skew (increasing it) - the taker fee is charged.
            // otherwise if the order is opposite to the skew, the maker fee is charged.
            uint staticRate = _sameSide(notionalDiff, marketState.marketSkew()) ? params.takerFee : params.makerFee;
            return baseFee + _abs(notionalDiff.multiplyDecimal(int(staticRate)));
        }

        // this trade flips the skew.
        //
        // the proportion of size that moves in the direction after the flip should not be considered
        // as a maker (reducing skew) as it's now taking (increasing skew) in the opposite direction. hence,
        // a different fee is applied on the proportion increasing the skew.

        // proportion of size that's on the other direction
        uint takerSize = _abs((marketSkew + params.sizeDelta).divideDecimal(params.sizeDelta));
        uint makerSize = uint(_UNIT) - takerSize;
        uint takerFee = _abs(notionalDiff).multiplyDecimal(takerSize).multiplyDecimal(params.takerFee);
        uint makerFee = _abs(notionalDiff).multiplyDecimal(makerSize).multiplyDecimal(params.makerFee);

        return baseFee + takerFee + makerFee;
    }

    /// Uses the exchanger to get the dynamic fee (SIP-184) for trading from hUSD to baseAsset
    /// this assumes dynamic fee is symmetric in direction of trade.
    /// @dev this is a pretty expensive action in terms of execution gas as it queries a lot
    ///   of past rates from oracle. Shouldn't be much of an issue on a rollup though.
    function _dynamicFeeRate() internal view returns (uint feeRate, bool tooVolatile) {
        return _exchanger().dynamicFeeRateForExchange(hUSD, _baseAsset());
    }

    function _latestFundingIndex() internal view returns (uint) {
        return marketState.fundingSequenceLength().sub(1); // at least one element is pushed in constructor
    }

    function _postTradeDetails(Position memory oldPos, TradeParams memory params)
        internal
        view
        returns (
            Position memory newPosition,
            uint fee,
            Status tradeStatus
        )
    {
        // Reverts if the user is trying to submit a size-zero order.
        if (params.sizeDelta == 0) {
            return (oldPos, 0, Status.NilOrder);
        }

        // The order is not submitted if the user's existing position needs to be liquidated.
        if (_canLiquidate(oldPos, params.oraclePrice)) {
            return (oldPos, 0, Status.CanLiquidate);
        }

        // get the dynamic fee rate SIP-184
        (uint dynamicFeeRate, bool tooVolatile) = _dynamicFeeRate();
        if (tooVolatile) {
            return (oldPos, 0, Status.PriceTooVolatile);
        }

        // calculate the total fee for exchange
        fee = _orderFee(params, dynamicFeeRate);

        // Deduct the fee.
        // It is an error if the realised margin minus the fee is negative or subject to liquidation.
        (uint newMargin, Status status) = _recomputeMarginWithDelta(oldPos, params.fillPrice, -int(fee));
        if (_isError(status)) {
            return (oldPos, 0, status);
        }

        // construct new position
        Position memory newPos =
            Position({
                id: oldPos.id,
                lastFundingIndex: uint64(_latestFundingIndex()),
                margin: uint128(newMargin),
                lastPrice: uint128(params.fillPrice),
                size: int128(int(oldPos.size).add(params.sizeDelta))
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
            if (uint(newPos.margin).add(fee) < _minInitialMargin()) {
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
        uint liqPremium = _liquidationPremium(newPos.size, params.oraclePrice);
        uint liqMargin = _liquidationMargin(newPos.size, params.oraclePrice).add(liqPremium);
        if (newMargin <= liqMargin) {
            return (newPos, 0, Status.CanLiquidate);
        }

        // Check that the maximum leverage is not exceeded when considering new margin including the paid fee.
        // The paid fee is considered for the benefit of UX of allowed max leverage, otherwise, the actual
        // max leverage is always below the max leverage parameter since the fee paid for a trade reduces the margin.
        // We'll allow a little extra headroom for rounding errors.
        {
            // stack too deep
            int leverage = int(newPos.size).multiplyDecimal(int(params.fillPrice)).divideDecimal(int(newMargin.add(fee)));
            if (_maxLeverage(_marketKey()).add(uint(_UNIT) / 100) < _abs(leverage)) {
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
    function _assetPrice() internal view returns (uint price, bool invalid) {
        (price, invalid) = _exchangeRates().rateAndInvalid(_baseAsset());
        // Ensure we catch uninitialised rates or suspended state / tribe
        invalid = invalid || price == 0 || _systemStatus().tribeSuspended(_baseAsset());
        return (price, invalid);
    }

    /*
     * @dev SIP-279 fillPrice price at which a trade is executed against accounting for how this position's
     * size impacts the skew. If the size contracts the skew (reduces) then a discount is applied on the price
     * whereas expanding the skew incurs an additional premium.
     */
    function _fillPrice(int size, uint price) internal view returns (uint) {
        int skew = marketState.marketSkew();
        int skewScale = int(_skewScale(_marketKey()));

        int pdBefore = skew.divideDecimal(skewScale);
        int pdAfter = skew.add(size).divideDecimal(skewScale);
        int priceBefore = int(price).add(int(price).multiplyDecimal(pdBefore));
        int priceAfter = int(price).add(int(price).multiplyDecimal(pdAfter));

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
        return uint(priceBefore.add(priceAfter).divideDecimal(_UNIT * 2));
    }

    /*
     * Absolute value of the input, returned as a signed number.
     */
    function _signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function _abs(int x) internal pure returns (uint) {
        return uint(_signedAbs(x));
    }

    function _max(int x, int y) internal pure returns (int) {
        return x < y ? y : x;
    }

    function _min(int x, int y) internal pure returns (int) {
        return x < y ? x : y;
    }

    /*
     * True if and only if two positions a and b are on the same side of the market; that is, if they have the same
     * sign, or either of them is zero.
     */
    function _sameSide(int a, int b) internal pure returns (bool) {
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


// Inheritance


// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketProxyable
contract PerpsV2MarketProxyable is PerpsV2MarketBase, Proxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketBase(_marketState, _owner, _resolver) Proxyable(_proxy) {}

    /* ---------- Market Operations ---------- */

    /*
     * Alter the debt correction to account for the net result of altering a position.
     */
    function _applyDebtCorrection(Position memory newPosition, Position memory oldPosition) internal {
        int newCorrection = _positionDebtCorrection(newPosition);
        int oldCorrection = _positionDebtCorrection(oldPosition);
        marketState.setEntryDebtCorrection(
            int128(int(marketState.entryDebtCorrection()).add(newCorrection).sub(oldCorrection))
        );
    }

    /*
     * The impact of a given position on the debt correction.
     */
    function _positionDebtCorrection(Position memory position) internal view returns (int) {
        /**
        This method only returns the correction term for the debt calculation of the position, and not it's 
        debt. This is needed for keeping track of the marketDebt() in an efficient manner to allow O(1) marketDebt
        calculation in marketDebt().

        Explanation of the full market debt calculation from the SIP https://sips.tribeone.io/sips/sip-80/:

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
            int(position.margin).sub(
                int(position.size).multiplyDecimal(
                    int(position.lastPrice).add(marketState.fundingSequence(position.lastFundingIndex))
                )
            );
    }

    /*
     * The current base price, reverting if it is invalid, or if system or tribe is suspended.
     * This is mutative because the circuit breaker stores the last price on every invocation.
     */
    function _assetPriceRequireSystemChecks(bool checkOffchainMarket) internal returns (uint) {
        // check that futures market isn't suspended, revert with appropriate message
        _systemStatus().requireFuturesMarketActive(_marketKey()); // asset and market may be different
        // check that tribe is active, and wasn't suspended, revert with appropriate message
        _systemStatus().requireTribeActive(_baseAsset());

        if (checkOffchainMarket) {
            // offchain PerpsV2 virtual market
            _systemStatus().requireFuturesMarketActive(_offchainMarketKey(_marketKey()));
        }
        // check if circuit breaker if price is within deviation tolerance and system & tribe is active
        // note: rateWithBreakCircuit (mutative) is used here instead of rateWithInvalid (view). This is
        //  despite reverting immediately after if circuit is broken, which may seem silly.
        //  This is in order to persist last-rate in exchangeCircuitBreaker in the happy case
        //  because last-rate is what used for measuring the deviation for subsequent trades.
        (uint price, bool circuitBroken, bool staleOrInvalid) = _exchangeRates().rateWithSafetyChecks(_baseAsset());
        // revert if price is invalid or circuit was broken
        // note: we revert here, which means that circuit is not really broken (is not persisted), this is
        //  because the futures methods and interface are designed for reverts, and do not support no-op
        //  return values.
        _revertIfError(circuitBroken || staleOrInvalid, Status.InvalidPrice);
        return price;
    }

    /** TODO: Docs */
    function _assertFillPrice(
        uint fillPrice,
        uint desiredFillPrice,
        int sizeDelta
    ) internal view returns (uint) {
        _revertIfError(
            sizeDelta > 0 ? fillPrice > desiredFillPrice : fillPrice < desiredFillPrice,
            Status.PriceImpactToleranceExceeded
        );
        return fillPrice;
    }

    function _recomputeFunding(uint price) internal returns (uint lastIndex) {
        uint sequenceLengthBefore = marketState.fundingSequenceLength();

        int fundingRate = _currentFundingRate();
        int funding = _nextFundingEntry(price);
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
        int orderSizeDelta,
        uint price,
        int marginDelta
    ) internal {
        Position memory oldPosition = position;
        // Determine new margin, ensuring that the result is positive.
        (uint margin, Status status) = _recomputeMarginWithDelta(oldPosition, price, marginDelta);
        _revertIfError(status);

        // Update the debt correction.
        uint fundingIndex = _latestFundingIndex();
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
                uint liqPremium = _liquidationPremium(position.size, price);
                uint liqMargin = _liquidationMargin(position.size, price).add(liqPremium);

                _revertIfError(margin <= liqMargin, Status.InsufficientMargin);

                // `marginDelta` can be decreasing (due to e.g. fees). However, price could also have moved in the
                // opposite direction resulting in a loss. A reduced remainingMargin to calc currentLeverage can
                // put the position above maxLeverage.
                //
                // To account for this, a check on `positionDecreasing` ensures that we can always perform this action
                // so long as we're reducing the position size and not liquidatable.
                int newPositionSize = int(position.size).add(orderSizeDelta);
                bool positionDecreasing =
                    _sameSide(position.size, newPositionSize) && _abs(newPositionSize) < _abs(position.size);

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

    function _trade(address sender, TradeParams memory params) internal notFlagged(sender) {
        Position memory position = marketState.positions(sender);
        Position memory oldPosition =
            Position({
                id: position.id,
                lastFundingIndex: position.lastFundingIndex,
                margin: position.margin,
                lastPrice: position.lastPrice,
                size: position.size
            });

        // Compute the new position after performing the trade
        (Position memory newPosition, uint fee, Status status) = _postTradeDetails(oldPosition, params);
        _revertIfError(status);

        _assertFillPrice(params.fillPrice, params.desiredFillPrice, params.sizeDelta);

        // Update the aggregated market size and skew with the new order size
        marketState.setMarketSkew(int128(int(marketState.marketSkew()).add(newPosition.size).sub(oldPosition.size)));
        marketState.setMarketSize(
            uint128(uint(marketState.marketSize()).add(_abs(newPosition.size)).sub(_abs(oldPosition.size)))
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
        uint fundingIndex = _latestFundingIndex();
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
    }

    /* ========== EVENTS ========== */

    function addressToBytes32(address input) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(input)));
    }

    event PositionModified(
        uint indexed id,
        address indexed account,
        uint margin,
        int size,
        int tradeSize,
        uint lastPrice,
        uint fundingIndex,
        uint fee,
        int skew
    );
    bytes32 internal constant POSITIONMODIFIED_SIG =
        keccak256("PositionModified(uint256,address,uint256,int256,int256,uint256,uint256,uint256,int256)");

    function emitPositionModified(
        uint id,
        address account,
        uint margin,
        int size,
        int tradeSize,
        uint lastPrice,
        uint fundingIndex,
        uint fee,
        int skew
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

    event FundingRecomputed(int funding, int fundingRate, uint index, uint timestamp);
    bytes32 internal constant FUNDINGRECOMPUTED_SIG = keccak256("FundingRecomputed(int256,int256,uint256,uint256)");

    function emitFundingRecomputed(
        int funding,
        int fundingRate,
        uint index,
        uint timestamp
    ) internal {
        proxy._emit(abi.encode(funding, fundingRate, index, timestamp), 1, FUNDINGRECOMPUTED_SIG, 0, 0, 0);
    }

    event PerpsTracking(bytes32 indexed trackingCode, bytes32 baseAsset, bytes32 marketKey, int sizeDelta, uint fee);
    bytes32 internal constant PERPSTRACKING_SIG = keccak256("PerpsTracking(bytes32,bytes32,bytes32,int256,uint256)");

    function emitPerpsTracking(
        bytes32 trackingCode,
        bytes32 baseAsset,
        bytes32 marketKey,
        int sizeDelta,
        uint fee
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


interface IPerpsV2MarketDelayedExecution {
    function executeDelayedOrder(address account) external;

    function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable;

    function cancelDelayedOrder(address account) external;

    function cancelOffchainDelayedOrder(address account) external;
}


// import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}


// import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}


// https://docs.tribeone.io/contracts/source/contracts/IPerpsV2ExchangeRate
interface IPerpsV2ExchangeRate {
    function setOffchainOracle(IPyth _offchainOracle) external;

    function setOffchainPriceFeedId(bytes32 assetId, bytes32 priceFeedId) external;

    /* ========== VIEWS ========== */

    function offchainOracle() external view returns (IPyth);

    function offchainPriceFeedId(bytes32 assetId) external view returns (bytes32);

    /* ---------- priceFeeds mutation ---------- */

    function updatePythPrice(address sender, bytes[] calldata priceUpdateData) external payable;

    // it is a view but it can revert
    function resolveAndGetPrice(bytes32 assetId, uint maxAge) external view returns (uint price, uint publishTime);

    // it is a view but it can revert
    function resolveAndGetLatestPrice(bytes32 assetId) external view returns (uint price, uint publishTime);
}


// Inheritance


// Reference


/**
 Contract that implements DelayedOrders (offchain) mechanism for the PerpsV2 market.
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
// https://docs.tribeone.io/contracts/source/contracts/PerpsV2MarketDelayedExecution
contract PerpsV2MarketDelayedExecution is IPerpsV2MarketDelayedExecution, PerpsV2MarketProxyable {
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address payable _proxy,
        address _marketState,
        address _owner,
        address _resolver
    ) public PerpsV2MarketProxyable(_proxy, _marketState, _owner, _resolver) {}

    function _perpsV2ExchangeRate() internal view returns (IPerpsV2ExchangeRate) {
        return IPerpsV2ExchangeRate(requireAndGetAddress(CONTRACT_PERPSV2EXCHANGERATE));
    }

    ///// Mutative methods

    /**
     * @notice Tries to execute a previously submitted delayed order.
     * Reverts if:
     * - There is no order
     * - Target roundId wasn't reached yet
     * - Order is stale (target roundId is too low compared to current roundId).
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * - Time delay and target round has not yet been reached
     * If order reverts, it has to be removed by calling cancelDelayedOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a delayed order
     */
    function executeDelayedOrder(address account) external onlyProxy {
        // important!: order of the account, not the sender!
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(!order.isOffchain, "use offchain method");

        uint currentRoundId = _exchangeRates().getCurrentRoundId(_baseAsset());
        require(
            block.timestamp >= order.executableAtTime || order.targetRoundId <= currentRoundId,
            "executability not reached"
        );

        // check order is not too old to execute
        // we cannot allow executing old orders because otherwise future knowledge
        // can be used to trigger failures of orders that are more profitable
        // then the commitFee that was charged, or can be used to confirm
        // orders that are more profitable than known then (which makes this into a "cheap option").
        require(
            !_confirmationWindowOver(order.executableAtTime, currentRoundId, order.targetRoundId),
            "order too old, use cancel"
        );

        // price depends on whether the delay or price update has reached/occurred first
        _executeDelayedOrder(
            account,
            order,
            _assetPriceRequireSystemChecks(false),
            currentRoundId,
            _takerFeeDelayedOrder(_marketKey()),
            _makerFeeDelayedOrder(_marketKey())
        );
    }

    /**
     * @notice Tries to execute a previously submitted delayed order.
     * Reverts if:
     * - There is no order
     * - Target roundId wasn't reached yet
     * - Order is stale (target roundId is too low compared to current roundId).
     * - Order fails for accounting reason (e.g. margin was removed, leverage exceeded, etc)
     * - Time delay and target round has not yet been reached
     * If order reverts, it has to be removed by calling cancelDelayedOrder().
     * Anyone can call this method for any account.
     * If this is called by the account holder - the keeperFee is refunded into margin,
     *  otherwise it sent to the msg.sender.
     * @param account address of the account for which to try to execute a delayed order
     */
    function executeOffchainDelayedOrder(address account, bytes[] calldata priceUpdateData) external payable onlyProxy {
        // important!: order of the account, not the sender!
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(order.isOffchain, "use onchain method");

        // update price feed (this is payable)
        _perpsV2ExchangeRate().updatePythPrice.value(msg.value)(messageSender, priceUpdateData);

        // get latest price for asset
        uint maxAge = _offchainDelayedOrderMaxAge(_marketKey());
        uint minAge = _offchainDelayedOrderMinAge(_marketKey());

        (uint currentPrice, uint executionTimestamp) = _offchainAssetPriceRequireSystemChecks(maxAge);

        require((executionTimestamp > order.intentionTime), "price not updated");
        require((executionTimestamp - order.intentionTime > minAge), "executability not reached");
        require((block.timestamp - order.intentionTime < maxAge), "order too old, use cancel");

        _executeDelayedOrder(
            account,
            order,
            currentPrice,
            0,
            _takerFeeOffchainDelayedOrder(_marketKey()),
            _makerFeeOffchainDelayedOrder(_marketKey())
        );
    }

    /**
     * @notice Cancels an existing order for an account.
     * Anyone can call this method for any account, but only the account owner
     *  can cancel their own order during the period when it can still potentially be executed (before it becomes stale).
     *  Only after the order becomes stale, can anyone else (e.g. a keeper) cancel the order for the keeperFee.
     * Cancelling the order:
     * - Removes the stored order.
     * - commitFee (deducted during submission) is sent to the fee pool.
     * - keeperFee (deducted during submission) is refunded into margin if it's the account holder,
     *  or send to the msg.sender if it's not the account holder.
     * @param account the account for which the stored order should be cancelled
     */
    function cancelDelayedOrder(address account) external onlyProxy {
        // important!! order of the account, not the msg.sender
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(!order.isOffchain, "use offchain method");

        _cancelDelayedOrder(account, order);
    }

    /**
     * @notice Cancels an existing order for an account.
     * Anyone can call this method for any account after the order becomes stale for the keeperFee.
     * Cancelling the order:
     * - Removes the stored order.
     * - commitFee (deducted during submission) is sent to the fee pool.
     * - keeperFee (deducted during submission) is refunded into margin if it's the account holder,
     *  or send to the msg.sender if it's not the account holder.
     * @param account the account for which the stored order should be cancelled
     */
    function cancelOffchainDelayedOrder(address account) external onlyProxy {
        // important!! order of the account, not the msg.sender
        DelayedOrder memory order = marketState.delayedOrders(account);
        // check that a previous order exists
        require(order.sizeDelta != 0, "no previous order");

        require(order.isOffchain, "use onchain method");

        _cancelDelayedOrder(account, order);
    }

    function _confirmCanCancel(DelayedOrder memory order, uint currentRoundId) internal {
        if (order.isOffchain) {
            require(block.timestamp - order.intentionTime > _offchainDelayedOrderMaxAge(_marketKey()), "cannot cancel yet");
        } else {
            require(
                _confirmationWindowOver(order.executableAtTime, currentRoundId, order.targetRoundId),
                "cannot be cancelled by keeper yet"
            );
        }
    }

    ///// Internal

    /// confirmation window is over when:
    ///  1. current roundId is more than nextPriceConfirmWindow rounds after target roundId
    ///  2. or executableAtTime - block.timestamp is more than delayedOrderConfirmWindow
    ///
    /// if either conditions are met, an order is considered to have exceeded the window.
    function _confirmationWindowOver(
        uint executableAtTime,
        uint currentRoundId,
        uint targetRoundId
    ) internal view returns (bool) {
        bytes32 marketKey = _marketKey();
        return
            (block.timestamp > executableAtTime &&
                (block.timestamp - executableAtTime) > _delayedOrderConfirmWindow(marketKey)) ||
            ((currentRoundId > targetRoundId) && (currentRoundId - targetRoundId > _nextPriceConfirmWindow(marketKey))); // don't underflow
    }

    /*
     * The current base price, reverting if it is invalid, or if system or tribe is suspended.
     */
    function _offchainAssetPriceRequireSystemChecks(uint maxAge) internal returns (uint price, uint publishTime) {
        // Onchain oracle asset price
        uint onchainPrice = _assetPriceRequireSystemChecks(true);
        (price, publishTime) = _perpsV2ExchangeRate().resolveAndGetPrice(_baseAsset(), maxAge);

        require(onchainPrice > 0 && price > 0, "invalid, price is 0");

        uint delta =
            (onchainPrice > price)
                ? onchainPrice.divideDecimal(price).sub(SafeDecimalMath.unit())
                : price.divideDecimal(onchainPrice).sub(SafeDecimalMath.unit());
        require(_offchainPriceDivergence(_marketKey()) > delta, "price divergence too high");

        return (price, publishTime);
    }

    function _cancelDelayedOrder(address account, DelayedOrder memory order) internal {
        uint currentRoundId = _exchangeRates().getCurrentRoundId(_baseAsset());

        _confirmCanCancel(order, currentRoundId);

        if (account == messageSender) {
            // this is account owner - refund keeper fee to margin
            Position memory position = marketState.positions(account);

            // cancelling an order does not induce a fillPrice as no skew has moved.
            uint price = _assetPriceRequireSystemChecks(false);
            uint fundingIndex = _recomputeFunding(price);
            _updatePositionMargin(account, position, order.sizeDelta, price, int(order.keeperDeposit));

            // emit event for modifying the position (add the fee to margin)
            emitPositionModified(
                position.id,
                account,
                position.margin,
                position.size,
                0,
                price,
                fundingIndex,
                0,
                marketState.marketSkew()
            );
        } else {
            // send keeper fee to keeper
            _manager().issueHUSD(messageSender, order.keeperDeposit);
        }

        // note: pay debt pool in the event there is any commitFee
        //
        // this should never occur but may during release as there may be lingering orders to be cancelled
        // which was submitted with a commitFee either before or during the upgrade.
        if (order.commitDeposit > 0) {
            _manager().payFee(order.commitDeposit);
        }

        // important!! position of the account, not the msg.sender
        marketState.deleteDelayedOrder(account);
        emitDelayedOrderRemoved(account, currentRoundId, order);
    }

    function _executeDelayedOrder(
        address account,
        DelayedOrder memory order,
        uint currentPrice,
        uint currentRoundId,
        uint takerFee,
        uint makerFee
    ) internal {
        // handle the fees and refunds according to the mechanism rules
        //
        // note: commitDeposit will always be 0 as we no longer charge a commitDeposit on submit. however,
        // during upgrade there may be pending orders for execution with a commitDeposit.
        uint toRefund = order.commitDeposit; // refund the commitment deposit

        // refund keeperFee to margin if it's the account holder
        if (messageSender == account) {
            toRefund += order.keeperDeposit;
        } else {
            _manager().issueHUSD(messageSender, order.keeperDeposit);
        }

        Position memory position = marketState.positions(account);

        uint fundingIndex = _recomputeFunding(currentPrice);

        // we need to grab the fillPrice for events and margin updates.
        uint fillPrice = _fillPrice(order.sizeDelta, currentPrice);

        // refund the commitFee (and possibly the keeperFee) to the margin before executing the order
        // if the order later fails this is reverted of course
        if (toRefund > 0) {
            _updatePositionMargin(account, position, order.sizeDelta, fillPrice, int(toRefund));
            // emit event for modifying the position (refunding fee/s)
            emitPositionModified(
                position.id,
                account,
                position.margin,
                position.size,
                0,
                fillPrice,
                fundingIndex,
                0,
                marketState.marketSkew()
            );
        }

        // execute or revert
        _trade(
            account,
            TradeParams({
                sizeDelta: order.sizeDelta, // using the pastPrice from the target roundId
                oraclePrice: currentPrice, // the funding is applied only from order confirmation time
                fillPrice: fillPrice,
                takerFee: takerFee, //_takerFeeDelayedOrder(_marketKey()),
                makerFee: makerFee, //_makerFeeDelayedOrder(_marketKey()),
                desiredFillPrice: order.desiredFillPrice,
                trackingCode: order.trackingCode
            })
        );

        // remove stored order
        marketState.deleteDelayedOrder(account);
        // emit event
        emitDelayedOrderRemoved(account, currentRoundId, order);
    }

    event DelayedOrderRemoved(
        address indexed account,
        bool isOffchain,
        uint currentRoundId,
        int sizeDelta,
        uint targetRoundId,
        uint commitDeposit,
        uint keeperDeposit,
        bytes32 trackingCode
    );
    bytes32 internal constant DELAYEDORDERREMOVED_SIG =
        keccak256("DelayedOrderRemoved(address,bool,uint256,int256,uint256,uint256,uint256,bytes32)");

    function emitDelayedOrderRemoved(
        address account,
        uint currentRoundId,
        DelayedOrder memory order
    ) internal {
        proxy._emit(
            abi.encode(
                order.isOffchain,
                currentRoundId,
                order.sizeDelta,
                order.targetRoundId,
                order.commitDeposit,
                order.keeperDeposit,
                order.trackingCode
            ),
            2,
            DELAYEDORDERREMOVED_SIG,
            addressToBytes32(account),
            0,
            0
        );
    }
}