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

    /* ========= PUBLIC FUNCTIONS ========== */

    function rebuildCaches(MixinResolver[] calldata destinations) external {
        for (uint256 i = 0; i < destinations.length; i++) {
            destinations[i].rebuildCache();
        }
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

    /* ========== EVENTS ========== */

    event AddressImported(bytes32 name, address destination);
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

interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getSynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDexAggregator {
    function swapSynthToNativeOn0X(
        address _account,
        bytes32 _destKey,
        uint256 _destAmount,
        address _target,
        bytes memory _data
    ) external returns (uint256);

    function swapNativeToSynthOn0X(
        address _account,
        bytes32 _nativeKey,
        uint256 _nativeAmount,
        bytes32 _destKey,
        address _target,
        bytes memory _data
    ) external payable returns (uint256);

    function refundSynth(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    // Mutative functions
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveValueAndRatesAtRound(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey,
        uint256 roundIdForSrc,
        uint256 roundIdForDest
    )
        external
        view
        returns (
            uint256 value,
            uint256 sourceRate,
            uint256 destinationRate
        );

    function effectiveAtomicValueAndRates(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 value,
            uint256 systemValue,
            uint256 systemSourceRate,
            uint256 systemDestinationRate
        );

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

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint256[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint256[] memory);

    function synthTooVolatileForAtomicExchange(bytes32 currencyKey) external view returns (bool);

    function rateWithSafetyChecks(bytes32 currencyKey)
        external
        returns (
            uint256 rate,
            bool broken,
            bool invalid
        );
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

    function settlementOwing(address account, bytes32 currencyKey)
        external
        view
        returns (
            uint256 reclaimAmount,
            uint256 rebateAmount,
            uint256 numEntries
        );

    // function hasWaitingPeriodOrSettlementOwing(address account, bytes32 currencyKey) external view returns (bool);

    function feeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view returns (uint256);

    function dynamicFeeRateForExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint256 feeRate, bool tooVolatile);

    function getAmountsForExchange(
        uint256 sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint256 amountReceived,
            uint256 fee,
            uint256 exchangeFeeRate
        );

    // function priceDeviationThresholdFactor() external view returns (uint256);

    // function waitingPeriodSecs() external view returns (uint256);

    // function lastExchangeRate(bytes32 currencyKey) external view returns (uint256);

    // Mutative functions
    function exchange(ExchangeArgs calldata args) external payable returns (uint256 amountReceived);

    function exchangeAtomically(uint256 minAmount, ExchangeArgs calldata args) external payable returns (uint256 amountReceived);

    function settle(address from, bytes32 currencyKey)
        external
        returns (
            uint256 reclaimed,
            uint256 refunded,
            uint256 numEntries
        );

    function suspendSynthWithInvalidRate(bytes32 currencyKey) external;

    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint256 destinationAmount
    ) external;
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

    function collateralisationRatioAndAnyRatesInvalid(address _issuer)
        external
        view
        returns (uint256 cratio, bool anyRateIsInvalid);

    function debtBalanceOf(address issuer) external view returns (uint256 debtBalance);

    function issuanceRatio() external view returns (uint256);

    function lastIssueEvent(address account) external view returns (uint256);

    function maxIssuableSynths(address issuer) external view returns (uint256 maxIssuable);

    function minimumStakeTime() external view returns (uint256);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint256 maxIssuable,
            uint256 alreadyIssued,
            uint256 totalSystemDebt
        );

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
    )
        external
        returns (
            uint256 synthAmount,
            uint256 debtShare,
            uint256 reclaimed,
            uint256 refunded
        );

    function burnSynthsToTarget(address from, bytes32 synthKey)
        external
        returns (
            uint256 synthAmount,
            uint256 debtShare,
            uint256 reclaimed,
            uint256 refunded
        );

    function burnForRedemption(
        address deprecatedSynthProxy,
        address account,
        uint256 balance
    ) external;

    function synthIssueFromSynthrSwap(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function synthBurnFromSynthrSwap(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function liquidateAccount(
        address account,
        bytes32 collateralKey,
        uint16 chainId,
        bool isSelfLiquidation
    )
        external
        returns (
            uint256 totalRedeemed,
            uint256 amountToLiquidate,
            uint256 sharesToRemove
        );

    function destIssue(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external;

    function destBurn(
        address _account,
        bytes32 _synthKey,
        uint256 _synthAmount
    ) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function setCurrentPeriodId(uint128 periodId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface IOffChainExchanger {
    // Views
    function offchainPriceMaxAge(bytes32 _currencyKey) external view returns (uint256);

    function offchainPriceMinAge(bytes32 _currencyKey) external view returns (uint256);

    function offchainPriceDivergence(bytes32 _currencyKey) external view returns (uint256);

    function feeRateForOffChainExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint256);

    function getAmountsForOffChainExchangeMinusFees(
        bytes32 _sourceKey,
        bytes32 _destKey,
        uint256 _destAmount
    ) external view returns (uint256 amountReceived, uint256 fee);

    // Mutative functions
    function exchange(IExchanger.ExchangeArgs calldata args, bytes[] calldata priceUpdateData)
        external
        payable
        returns (uint256 amountReceived);

    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint256 destinationAmount
    ) external;

    function exchangeForDexAggregation(
        address _account,
        bytes32 _sourceKey,
        bytes32 _destKey,
        uint256 _sourceAmount,
        bytes[] memory _priceUpdateData
    ) external payable returns (uint256 destAmount, uint256 fee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPyth.sol";

// https://docs.synthetix.io/contracts/source/contracts/IPerpsV2ExchangeRate
interface IPerpsV2ExchangeRate {
    function setOffchainOracle(IPyth _offchainOracle) external;

    function setOffchainPriceFeedId(bytes32 assetId, bytes32 priceFeedId) external;

    /* ========== VIEWS ========== */

    function offchainOracle() external view returns (IPyth);

    function offchainPriceFeedId(bytes32 assetId) external view returns (bytes32);

    function getExchangeAmount(
        bytes32 _sourceKey,
        uint256 _sourceAmount,
        bytes32 _destKey
    )
        external
        view
        returns (
            uint256 destAmount,
            uint256 sourceRate,
            uint256 destRate
        );

    function calculateExchangeRate(
        uint256 _sourceRate,
        uint256 _sourceAmount,
        uint256 _destRate
    ) external pure returns (uint256);

    function getUpdateFee(bytes[] calldata priceUpdateData) external view returns (uint256);

    /* ---------- priceFeeds mutation ---------- */

    function updatePythPrice(address sender, bytes[] calldata priceUpdateData) external payable;

    // it is a view but it can revert
    function resolveAndGetPrice(bytes32 assetId, uint256 maxAge) external view returns (uint256 price, uint256 publishTime);

    // it is a view but it can revert
    function resolveAndGetLatestPrice(bytes32 assetId) external view returns (uint256 price, uint256 publishTime);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PythStructs.sol";

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
    function getValidTimePeriod() external view returns (uint256 validTimePeriod);

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
    function getPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

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
    function getEmaPriceNoOlderThan(bytes32 id, uint256 age) external view returns (PythStructs.Price memory price);

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
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint256 feeAmount);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISynth {
    // Views
    function balanceOf(address _account) external view returns (uint256);

    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint256);

    // Mutative functions
    function transferAndSettle(address to, uint256 value) external payable returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint256 value
    ) external payable returns (bool);

    function burn(address account, uint256 amount) external;

    function issue(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExchanger.sol";

interface ISynthrBridge {
    /* ========== MUTATIVE FUNCTIONS ========== */
    function sendDepositCollateral(
        address account,
        bytes32 collateralKey,
        uint256 amount
    ) external;

    function sendMint(
        address account,
        bytes32 synthKey,
        uint256 synthAmount,
        uint16 destChainId
    ) external payable;

    function sendWithdraw(
        address account,
        bytes32 collateralKey,
        uint256 amount,
        uint16 destChainId
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
        uint16 destChainId
    ) external payable;

    function sendLiquidate(
        address account,
        bytes32 collateralKey,
        uint256 collateralAmount,
        uint16 destChainId
    ) external payable;

    function sendBridgeSyToken(
        address account,
        bytes32 synthKey,
        uint256 amount,
        uint16 dstChainId
    ) external payable;

    function sendTransferMargin(address account, uint256 amount) external;

    function sendWithdrawMargin(
        address account,
        uint256 amount,
        uint16 destChainId
    ) external payable;

    function sendCrossSwapSyAssetToNative(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        address dexAddress,
        uint256 fee,
        bytes calldata dexPayload
    ) external payable;

    function sendCrossSwapNativeToSyAsset(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee
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
        bytes calldata dexPayload
    ) external payable;

    function sendCrossSwapSyAssetToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee
    ) external payable;

    function sendCrossSwapNativeToNativeWithDex(
        address account,
        bytes32 srcKey,
        uint256 srcAmount,
        bytes32 dstKey,
        uint256 dstAmount,
        uint16 dstChainId,
        uint256 fee
    ) external payable;

    function calcLZFee(
        bytes memory lzPayload,
        uint16 packetType,
        uint16 dstChainId
    ) external view returns (uint256 lzFee);
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

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    function getFuturesMarketSuspensions(bytes32[] calldata marketKeys)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendIssuance(uint256 reason) external;

    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function suspendFuturesMarket(bytes32 marketKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        uint256 publishTime;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// from Uniswap TransferHelper library
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeApprove: approve failed");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::safeTransfer: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper::transferFrom: transferFrom failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// Inheritance
import "../interfaces/IERC20.sol";
import "../MixinResolver.sol";
import "../Owned.sol";
// Internal references
import "../interfaces/ISynth.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IOffChainExchanger.sol";
import "../interfaces/IPerpsV2ExchangeRate.sol";
import "../interfaces/IIssuer.sol";
import "../interfaces/IDexAggregator.sol";
import "../interfaces/ISynthrBridge.sol";
import "../libraries/TransferHelper.sol";

contract SynthrSwap is MixinResolver, Owned {
    bytes32 public constant CONTRACT_NAME = "SynthrSwap";

    struct SwapData {
        uint256 sourceNativeAmount;
        uint256 sourceSynthAmount;
        uint256 destNativeAmount;
        uint256 destSynthAmount;
        bytes32 sourceNativeKey;
        bytes32 sourceSynthKey;
        bytes32 destNativeKey;
        bytes32 destSynthKey;
        bytes[] callData;
        address[] targets;
        uint16 destChainId;
    }

    mapping(uint16 => bytes32) public nativeSynthPerChain; // 10121 => syETH key
    mapping(bytes32 => bytes32) public equivalentSynthKey; // ETH key => syETH key
    mapping(bytes32 => bytes32) public equivalentCurrencyKey; // syETH key => ETH key

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_DEX_AGGREGATOR = "DexAggregator";
    bytes32 private constant CONTRACT_SYNTHR_BRIDGE = "SynthrBridge";
    bytes32 private constant CONTRACT_OFF_CHAIN_EXCHANGER = "OffChainExchanger";
    bytes32 private constant CONTRACT_PERPSV2EXCHANGERATE = "PerpsV2ExchangeRate";

    uint16 private constant PT_CROSS_SWAP_CASE_1 = 11;
    uint16 private constant PT_CROSS_SWAP_CASE_2 = 12;
    uint16 private constant PT_CROSS_SWAP_CASE_3 = 13;

    event SetNativeAssetByChain(uint16 indexed _chainId, bytes32 _nativeCurrencyKey, bytes32 _nativeSynth);
    event RemoveNativeAssetByChain(uint16 indexed _chainId, bytes32 _originalCurrencyKey, bytes32 _originalSynthKey);
    event SwapSynthToNativeOn0x(
        address indexed _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destSynthKey,
        uint256 _destSynthAmount,
        bytes32 _destNativeKey,
        uint256 _swappedNativeAmount
    );
    event SwapSynthToNativeFailedOn0x(address indexed _account, string reason);

    event SwapNativeToSynthOn0x(
        address indexed _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceAmount,
        bytes32 _destSynthKey,
        uint256 _swappedSynthAmount
    );

    event SwapNativeToNativeOn0x(
        address indexed _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destSynthKey,
        uint256 _destSynthAmount,
        bytes32 _destNativeKey,
        uint256 _swappedNativeAmount
    );

    event SwapNativeToNativeFailedOn0x(address indexed _account, string reason);

    event SwapSourceSynthToNativeOn0x(
        address indexed _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destNativeKey,
        uint16 _destChainId
    );

    event SwapSourceNativeToSynthOn0x(
        address indexed _account,
        bytes32 _sourceNativeKey,
        uint256 _sourceNativeAmount,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destSynthKey,
        uint16 _destChainId
    );

    event SwapSourceNativeToNativeOn0x(
        address indexed _account,
        bytes32 _sourceNativeKey,
        uint256 _sourceNativeAmount,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destNativeKey,
        uint16 _destChainId
    );

    // ========== CONSTRUCTOR ==========
    constructor(address _owner, address _resolver) MixinResolver(_resolver) Owned(_owner) {}

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public pure override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](7);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXRATES;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_DEX_AGGREGATOR;
        addresses[4] = CONTRACT_SYNTHR_BRIDGE;
        addresses[5] = CONTRACT_OFF_CHAIN_EXCHANGER;
        addresses[6] = CONTRACT_PERPSV2EXCHANGERATE;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function offChainExchanger() internal view returns (IOffChainExchanger) {
        return IOffChainExchanger(requireAndGetAddress(CONTRACT_OFF_CHAIN_EXCHANGER));
    }

    function perpsV2ExchangeRate() internal view returns (IPerpsV2ExchangeRate) {
        return IPerpsV2ExchangeRate(requireAndGetAddress(CONTRACT_PERPSV2EXCHANGERATE));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function synthrBridge() internal view returns (ISynthrBridge) {
        return ISynthrBridge(requireAndGetAddress(CONTRACT_SYNTHR_BRIDGE));
    }

    function dexAggregator() internal view returns (IDexAggregator) {
        return IDexAggregator(requireAndGetAddress(CONTRACT_DEX_AGGREGATOR));
    }

    function getSwapSynthToNativeLZFee(
        address _account,
        uint256 _sourceAmount,
        bytes32 _sourceKey,
        bytes32 _destKey,
        address _target,
        bytes memory _data,
        uint16 _chainId
    ) external view returns (uint256) {
        uint256 destSynthAmount = exchangeRates().effectiveValue(_sourceKey, _sourceAmount, equivalentSynthKey[_destKey]);
        bytes memory lzPayload = abi.encode(
            PT_CROSS_SWAP_CASE_1,
            abi.encodePacked(_account),
            _sourceKey,
            _sourceAmount,
            equivalentSynthKey[_destKey],
            destSynthAmount,
            _chainId,
            _data,
            abi.encodePacked(_target)
        );
        return synthrBridge().calcLZFee(lzPayload, PT_CROSS_SWAP_CASE_1, _chainId);
    }

    function getSwapNativeToSynthLZFee(
        address _account,
        uint256 _sourceNativeAmount,
        bytes32 _sourceNativeKey,
        bytes32 _destSynthKey,
        address _target,
        bytes memory _data,
        uint16 _chainId
    ) external view returns (uint256) {
        uint256 destSynthAmount = exchangeRates().effectiveValue(
            equivalentSynthKey[_sourceNativeKey],
            _sourceNativeAmount,
            _destSynthKey
        );
        bytes memory lzPayload = abi.encode(
            PT_CROSS_SWAP_CASE_2,
            abi.encodePacked(_account),
            equivalentSynthKey[_sourceNativeKey],
            _sourceNativeAmount,
            _destSynthKey,
            destSynthAmount,
            _chainId,
            _data,
            abi.encodePacked(_target)
        );
        return synthrBridge().calcLZFee(lzPayload, PT_CROSS_SWAP_CASE_2, _chainId);
    }

    function getSwapNativeToNativeLZFee(
        address _account,
        uint256 _sourceNativeAmount,
        bytes32 _sourceNativeKey,
        bytes32 _destNativeKey,
        address _target,
        bytes memory _data,
        uint16 _chainId
    ) external view returns (uint256) {
        uint256 destSynthAmount = exchangeRates().effectiveValue(
            equivalentSynthKey[_sourceNativeKey],
            _sourceNativeAmount,
            equivalentSynthKey[_destNativeKey]
        );
        bytes memory lzPayload = abi.encode(
            PT_CROSS_SWAP_CASE_3,
            abi.encodePacked(_account),
            equivalentSynthKey[_sourceNativeKey],
            _sourceNativeAmount,
            equivalentSynthKey[_destNativeKey],
            destSynthAmount,
            _chainId,
            _data,
            abi.encodePacked(_target)
        );
        return synthrBridge().calcLZFee(lzPayload, PT_CROSS_SWAP_CASE_3, _chainId);
    }

    function setNativeAsset(
        uint16 _chainId,
        bytes32 _nativeKey,
        bytes32 _nativeSynth
    ) external onlyOwner {
        require(_nativeKey != bytes32(0), "Asset Key must not be zero bytes.");
        nativeSynthPerChain[_chainId] = _nativeKey;
        equivalentSynthKey[_nativeKey] = _nativeSynth;
        equivalentCurrencyKey[_nativeSynth] = _nativeKey;

        emit SetNativeAssetByChain(_chainId, _nativeKey, _nativeSynth);
    }

    function removeNativeAsset(uint16 _chainId) external onlyOwner {
        require(nativeSynthPerChain[_chainId] != bytes32(0), "The key wasn't set yet.");
        bytes32 originalSynthKey = nativeSynthPerChain[_chainId];
        delete nativeSynthPerChain[_chainId];

        require(equivalentCurrencyKey[originalSynthKey] != bytes32(0), "The key wasn't set yet.");
        bytes32 originalCurrencyKey = equivalentCurrencyKey[originalSynthKey];
        delete equivalentCurrencyKey[originalSynthKey];

        require(equivalentSynthKey[originalCurrencyKey] != bytes32(0), "The key wasn't set yet.");
        delete equivalentSynthKey[originalCurrencyKey];

        emit RemoveNativeAssetByChain(_chainId, originalCurrencyKey, originalSynthKey);
    }

    function swapSynthToNative(
        uint256 _sourceSynthAmount,
        bytes32 _sourceSynthKey,
        bytes32 _destNativeKey,
        address[] memory _targets,
        bytes[] memory _data,
        bytes[] memory _priceUpdateData,
        uint16 _destChainId
    ) external payable systemActive {
        SwapData memory _swapData = SwapData({
            sourceNativeAmount: 0,
            sourceSynthAmount: _sourceSynthAmount,
            destNativeAmount: 0,
            destSynthAmount: 0,
            sourceNativeKey: bytes32(0),
            sourceSynthKey: _sourceSynthKey,
            destNativeKey: _destNativeKey,
            destSynthKey: equivalentSynthKey[_destNativeKey],
            callData: _data,
            targets: _targets,
            destChainId: _destChainId
        });

        require(_swapData.destChainId != 0, "Not allowed swap on self chain");
        require(
            issuer().synths(_swapData.sourceSynthKey).balanceOf(msg.sender) >= _swapData.sourceSynthAmount,
            "Insufficient synth balance."
        );
        require(_swapData.destSynthKey != bytes32(0), "The key wasn't set yet.");

        uint256 priceUpdateFee = perpsV2ExchangeRate().getUpdateFee(_priceUpdateData);
        require(msg.value > priceUpdateFee, "Insufficient msg value for swap");

        uint256 fee;
        (_swapData.destSynthAmount, fee) = offChainExchanger().exchangeForDexAggregation{value: priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            _swapData.destSynthKey,
            _swapData.sourceSynthAmount,
            _priceUpdateData
        );
        synthrBridge().sendCrossSwapSyAssetToNative{value: msg.value - priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            _swapData.sourceSynthAmount,
            _swapData.destSynthKey,
            _swapData.destSynthAmount,
            _swapData.destChainId,
            _swapData.targets[0],
            fee,
            _swapData.callData[0]
        );
        emit SwapSourceSynthToNativeOn0x(
            msg.sender,
            _swapData.sourceSynthKey,
            _swapData.sourceSynthAmount,
            _swapData.destNativeKey,
            _swapData.destChainId
        );
    }

    function destSwapSynthToNative(
        address _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destSynthKey,
        uint256 _destSynthAmount,
        address _target,
        bytes memory _data
    ) external systemActive onlySynthrBridge returns (bool) {
        require(_account != address(0), "Zero account.");
        require(_target != address(0), "Zero target account.");
        require(_destSynthAmount > 0, "Not allowed swap with zero amount");
        require(equivalentCurrencyKey[_destSynthKey] != bytes32(0), "The equivalent currency key wasn't set yet.");

        issuer().synthIssueFromSynthrSwap(address(dexAggregator()), _destSynthKey, _destSynthAmount);

        try dexAggregator().swapSynthToNativeOn0X(_account, _destSynthKey, _destSynthAmount, _target, _data) returns (
            uint256 result
        ) {
            emit SwapSynthToNativeOn0x(
                _account,
                _sourceSynthKey,
                _sourceSynthAmount,
                _destSynthKey,
                _destSynthAmount,
                equivalentCurrencyKey[_destSynthKey],
                result
            );
            return true;
        } catch Error(string memory reason) {
            dexAggregator().refundSynth(_account, _destSynthKey, _destSynthAmount);
            emit SwapSynthToNativeFailedOn0x(_account, reason);
            return false;
        }
    }

    function swapNativeToSynth(
        uint256 _sourceNativeAmount,
        bytes32 _sourceNativeKey,
        bytes32 _destSynthKey,
        address[] memory _targets,
        bytes[] memory _data,
        bytes[] memory _priceUpdateData,
        uint16 _destChainId
    ) external payable systemActive {
        SwapData memory _swapData = SwapData({
            sourceNativeAmount: _sourceNativeAmount,
            sourceSynthAmount: 0,
            destNativeAmount: 0,
            destSynthAmount: 0,
            sourceNativeKey: _sourceNativeKey,
            sourceSynthKey: equivalentSynthKey[_sourceNativeKey],
            destNativeKey: bytes32(0),
            destSynthKey: _destSynthKey,
            callData: _data,
            targets: _targets,
            destChainId: _destChainId
        });

        require(_swapData.destChainId != 0, "Not allowed swap on self chain");
        require(_swapData.sourceSynthKey != bytes32(0), "The source key wasn't set yet.");

        uint256 priceUpdateFee = perpsV2ExchangeRate().getUpdateFee(_priceUpdateData);
        require(msg.value > _swapData.sourceNativeAmount + priceUpdateFee, "Inssuficient msg value in source native to swap.");

        uint256 swappedAmount = dexAggregator().swapNativeToSynthOn0X{value: _swapData.sourceNativeAmount}(
            msg.sender,
            _swapData.sourceNativeKey,
            _swapData.sourceNativeAmount,
            _swapData.sourceSynthKey,
            _swapData.targets[0],
            _swapData.callData[0]
        );
        require(swappedAmount > 0, "Swap action failed on 0x.");

        uint256 fee;
        (_swapData.destSynthAmount, fee) = offChainExchanger().exchangeForDexAggregation{value: priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            _swapData.destSynthKey,
            swappedAmount,
            _priceUpdateData
        );

        synthrBridge().sendCrossSwapNativeToSyAsset{value: msg.value - _swapData.sourceNativeAmount - priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            swappedAmount,
            _swapData.destSynthKey,
            _swapData.destSynthAmount,
            _swapData.destChainId,
            fee
        );
        emit SwapSourceNativeToSynthOn0x(
            msg.sender,
            _swapData.sourceNativeKey,
            _swapData.sourceNativeAmount,
            _swapData.sourceSynthKey,
            swappedAmount,
            _swapData.destSynthKey,
            _swapData.destChainId
        );
    }

    function destSwapNativeToSynth(
        address _account,
        bytes32 _sourceKey,
        uint256 _sourceAmount,
        bytes32 _destKey,
        uint256 _destAmount
    ) external systemActive onlySynthrBridge {
        require(_account != address(0), "Zero account.");
        require(_destAmount > 0, "Not allowed swap with zero amount");
        issuer().synthIssueFromSynthrSwap(_account, _destKey, _destAmount);

        emit SwapNativeToSynthOn0x(_account, _sourceKey, _sourceAmount, _destKey, _destAmount);
    }

    function swapNativeToNative(
        uint256 _sourceNativeAmount,
        bytes32 _sourceNativeKey,
        bytes32 _destNativeKey,
        address[] memory _targets,
        bytes[] memory _callData,
        bytes[] memory _priceUpdateData,
        uint16 _destChainId
    ) external payable systemActive {
        SwapData memory _swapData = SwapData({
            sourceNativeAmount: _sourceNativeAmount,
            sourceSynthAmount: 0,
            destNativeAmount: 0,
            destSynthAmount: 0,
            sourceNativeKey: _sourceNativeKey,
            sourceSynthKey: equivalentSynthKey[_sourceNativeKey],
            destNativeKey: _destNativeKey,
            destSynthKey: equivalentSynthKey[_destNativeKey],
            callData: _callData,
            targets: _targets,
            destChainId: _destChainId
        });

        require(_swapData.sourceSynthKey != bytes32(0), "The source native key was not set yet.");
        require(_swapData.destSynthKey != bytes32(0), "The dest native key was not set yet.");
        require(_targets.length == 2, "Invalid target address list.");
        require(_callData.length == 2, "Invalid call data list.");

        uint256 priceUpdateFee = perpsV2ExchangeRate().getUpdateFee(_priceUpdateData);
        require(msg.value > _swapData.sourceNativeAmount + priceUpdateFee, "Inssuficient msg value in source native to swap.");

        // swap source native currency to corresponding source native synth
        uint256 swappedAmount = dexAggregator().swapNativeToSynthOn0X{value: _swapData.sourceNativeAmount}(
            msg.sender,
            _swapData.sourceNativeKey,
            _swapData.sourceNativeAmount,
            _swapData.sourceSynthKey,
            _swapData.targets[0],
            _swapData.callData[0]
        );
        require(swappedAmount > 0, "Native to Synth Swap action failed on 0x.");

        uint256 fee;
        (_swapData.destSynthAmount, fee) = offChainExchanger().exchangeForDexAggregation{value: priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            _swapData.destSynthKey,
            _swapData.sourceNativeAmount,
            _priceUpdateData
        );

        synthrBridge().sendCrossSwapNativeToNative{value: msg.value - _swapData.sourceNativeAmount - priceUpdateFee}(
            msg.sender,
            _swapData.sourceSynthKey,
            swappedAmount,
            _swapData.destSynthKey,
            _swapData.destSynthAmount,
            _swapData.destChainId,
            _swapData.targets[1],
            fee,
            _swapData.callData[1]
        );
        emit SwapSourceNativeToNativeOn0x(
            msg.sender,
            _swapData.sourceNativeKey,
            _swapData.sourceNativeAmount,
            _swapData.sourceSynthKey,
            swappedAmount,
            _swapData.destNativeKey,
            _swapData.destChainId
        );
    }

    function destSwapNativeToNative(
        address _account,
        bytes32 _sourceSynthKey,
        uint256 _sourceSynthAmount,
        bytes32 _destSynthKey,
        uint256 _destSynthAmount,
        address _target,
        bytes memory _data
    ) external systemActive onlySynthrBridge returns (bool) {
        require(_account != address(0), "Zero account.");
        require(_target != address(0), "Zero target account.");
        require(_destSynthAmount > 0, "Not allowed swap with zero amount");
        require(equivalentCurrencyKey[_destSynthKey] != bytes32(0), "The equivalent currency key wasn't set yet.");
        issuer().synthIssueFromSynthrSwap(address(dexAggregator()), _destSynthKey, _destSynthAmount);

        try dexAggregator().swapSynthToNativeOn0X(_account, _destSynthKey, _destSynthAmount, _target, _data) returns (
            uint256 result
        ) {
            emit SwapNativeToNativeOn0x(
                _account,
                _sourceSynthKey,
                _sourceSynthAmount,
                _destSynthKey,
                _destSynthAmount,
                equivalentCurrencyKey[_destSynthKey],
                result
            );
            return true;
        } catch Error(string memory reason) {
            dexAggregator().refundSynth(_account, _destSynthKey, _destSynthAmount);
            emit SwapNativeToNativeFailedOn0x(_account, reason);
            return false;
        }
    }

    // ========== MODIFIERS ==========

    modifier systemActive() {
        _systemActive();
        _;
    }

    function _systemActive() private view {
        systemStatus().requireSystemActive();
    }

    modifier onlySynthrBridge() {
        require(msg.sender == address(synthrBridge()), "SynthrSwap: Only the SynthrBridge contract can perform this action");
        _;
    }

    receive() external payable {}
}