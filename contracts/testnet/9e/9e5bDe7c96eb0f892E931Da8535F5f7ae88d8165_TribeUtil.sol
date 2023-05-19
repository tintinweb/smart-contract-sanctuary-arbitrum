/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

/* Tribeone: TribeUtil.sol
* Latest source (may be newer): https://github.com/TribeOneDefi/tribeone-v3-contracts/blob/master/contracts/TribeUtil.sol
* Docs: https://docs.tribeone.io/contracts/TribeUtil
*
* Contract Dependencies: (none)
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



pragma solidity >=0.4.24;

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


// https://docs.tribeone.io/contracts/source/interfaces/itribeetix
interface ITribeone {
    // Views
    function anyTribeOrHAKARateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableTribeCount() external view returns (uint);

    function availableTribes(uint index) external view returns (ITribe);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableTribes(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableTribes(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function tribes(bytes32 currencyKey) external view returns (ITribe);

    function tribesByAddress(address tribeAddress) external view returns (bytes32);

    function totalIssuedTribes(bytes32 currencyKey) external view returns (uint);

    function totalIssuedTribesExcludeOtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableTribeone(address account) external view returns (uint transferable);

    function getFirstNonZeroEscrowIndex(address account) external view returns (uint);

    // Mutative Functions
    function burnTribes(uint amount) external;

    function burnTribesOnBehalf(address burnForAddress, uint amount) external;

    function burnTribesToTarget() external;

    function burnTribesToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithTrackingForInitiator(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address rewardAddress,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualTribe vTribe);

    function exchangeAtomically(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode,
        uint minAmount
    ) external returns (uint amountReceived);

    function issueMaxTribes() external;

    function issueMaxTribesOnBehalf(address issueForAddress) external;

    function issueTribes(uint amount) external;

    function issueTribesOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account) external returns (bool);

    function liquidateDelinquentAccountEscrowIndex(address account, uint escrowStartIndex) external returns (bool);

    function liquidateSelf() external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;

    function revokeAllEscrow(address account) external;

    function migrateAccountBalances(address account) external returns (uint totalEscrowRevoked, uint totalLiquidBalance);
}


pragma experimental ABIEncoderV2;

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


// https://docs.tribeone.io/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getTribe(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.tribeone.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}


// Inheritance


// https://docs.tribeone.io/contracts/source/contracts/tribeutil
contract TribeUtil {
    IAddressResolver public addressResolverProxy;

    bytes32 internal constant CONTRACT_TRIBEONEETIX = "Tribeone";
    bytes32 internal constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant HUSD = "hUSD";

    constructor(address resolver) public {
        addressResolverProxy = IAddressResolver(resolver);
    }

    function _tribeetix() internal view returns (ITribeone) {
        return ITribeone(addressResolverProxy.requireAndGetAddress(CONTRACT_TRIBEONEETIX, "Missing Tribeone address"));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(addressResolverProxy.requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
    }

    function totalTribesInKey(address account, bytes32 currencyKey) external view returns (uint total) {
        ITribeone tribeone = _tribeetix();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numTribes = tribeone.availableTribeCount();
        for (uint i = 0; i < numTribes; i++) {
            ITribe tribe = tribeone.availableTribes(i);
            total += exchangeRates.effectiveValue(
                tribe.currencyKey(),
                IERC20(address(tribe)).balanceOf(account),
                currencyKey
            );
        }
        return total;
    }

    function tribesBalances(address account)
        external
        view
        returns (
            bytes32[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        ITribeone tribeone = _tribeetix();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numTribes = tribeone.availableTribeCount();
        bytes32[] memory currencyKeys = new bytes32[](numTribes);
        uint[] memory balances = new uint[](numTribes);
        uint[] memory hUSDBalances = new uint[](numTribes);
        for (uint i = 0; i < numTribes; i++) {
            ITribe tribe = tribeone.availableTribes(i);
            currencyKeys[i] = tribe.currencyKey();
            balances[i] = IERC20(address(tribe)).balanceOf(account);
            hUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], HUSD);
        }
        return (currencyKeys, balances, hUSDBalances);
    }

    function tribesRates() external view returns (bytes32[] memory, uint[] memory) {
        bytes32[] memory currencyKeys = _tribeetix().availableCurrencyKeys();
        return (currencyKeys, _exchangeRates().ratesForCurrencies(currencyKeys));
    }

    function tribesTotalSupplies()
        external
        view
        returns (
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        ITribeone tribeone = _tribeetix();
        IExchangeRates exchangeRates = _exchangeRates();

        uint256 numTribes = tribeone.availableTribeCount();
        bytes32[] memory currencyKeys = new bytes32[](numTribes);
        uint256[] memory balances = new uint256[](numTribes);
        uint256[] memory hUSDBalances = new uint256[](numTribes);
        for (uint256 i = 0; i < numTribes; i++) {
            ITribe tribe = tribeone.availableTribes(i);
            currencyKeys[i] = tribe.currencyKey();
            balances[i] = IERC20(address(tribe)).totalSupply();
            hUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], HUSD);
        }
        return (currencyKeys, balances, hUSDBalances);
    }
}