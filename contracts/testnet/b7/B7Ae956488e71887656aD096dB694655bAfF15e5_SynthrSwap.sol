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
    function swapSynthToNativeOn0X(address _account, bytes32 _destKey, uint256 _destAmount, address _target, bytes memory _data) external returns (uint256);
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

    function rateWithSafetyChecks(bytes32 currencyKey) external returns (uint rate, bool broken, bool invalid);
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
    ) external returns (uint256 totalRedeemed, uint256 amountToLiquidate, uint256 sharesToRemove);

    function destIssue(address _account, bytes32 _synthKey, uint256 _synthAmount) external;

    function destBurn(address _account, bytes32 _synthKey, uint256 _synthAmount) external returns (uint256);

    function transferMargin(address account, uint256 marginDelta) external returns (uint256);

    function setCurrentPeriodId(uint128 periodId) external;
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
    function sendDepositCollateral(address account, bytes32 collateralKey, uint256 amount) external;

    function sendMint(address account, bytes32 synthKey, uint256 synthAmount, uint16 destChainId) external payable;

    function sendWithdraw(address account, bytes32 collateralKey, uint256 amount, uint16 destChainId) external payable;

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

    function sendLiquidate(address account, bytes32 collateralKey, uint256 collateralAmount, uint16 destChainId) external payable;

    function sendBridgeSyToken(address account, bytes32 synthKey, uint256 amount, uint16 dstChainId) external payable;

    function sendTransferMargin(address account, uint256 amount) external;

    function sendWithdrawMargin(address account, uint256 amount, uint16 destChainId) external payable;

    function sendCrossSwapSyAssetToNative(
        address account,
        bytes32 srcKey,
        uint srcAmount,
        bytes32 dstKey,
        uint dstAmount,
        uint16 dstChainId,
        address dexAddress,
        bytes calldata dexPayload
    ) external payable;

    function calcLZFee(bytes memory lzPayload, uint16 packetType, uint16 dstChainId) external view returns (uint256 lzFee);
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
// Inheritance
import "../interfaces/IERC20.sol";
import "../MixinResolver.sol";
import "../Owned.sol";
// Internal references
import "../interfaces/ISynth.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IExchangeRates.sol";
import "../interfaces/IIssuer.sol";
import "../interfaces/IDexAggregator.sol";
import "../interfaces/ISynthrBridge.sol";

contract SynthrSwap is MixinResolver, Owned {
    bytes32 public constant CONTRACT_NAME = "SynthrSwap";

    mapping (uint16 => bytes32) public nativeSynthPerChain; // 10121 => syETH key
    mapping (bytes32 => bytes32) public equivalentSynthKey; // ETH key => syETH key
    mapping (bytes32 => bytes32) public equivalentCurrencyKey; // syETH key => ETH key

    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_DEX_AGGREGATOR = "DexAggregator";
    bytes32 private constant CONTRACT_SYNTHR_BRIDGE = "SynthrBridge";

    uint16 private constant PT_CROSS_SWAP_CASE_1 = 11;

    event SetNativeAssetByChain(uint16 indexed _chainId, bytes32 _nativeCurrencyKey, bytes32 _nativeSynth);
    event RemoveNativeAssetByChain(uint16 indexed _chainId, bytes32 _originalCurrencyKey, bytes32 _originalSynthKey);
    event SwapSynthToNative(address indexed _account, bytes32 _sourceSynthKey, uint256 _sourceAmount, bytes32 _destKey, uint256 _swappedAmount);
    event SwapSynthToNativeFailed(address indexed _account, string reason);

    // ========== CONSTRUCTOR ==========
    constructor(
        address _owner,
        address _resolver
    ) MixinResolver(_resolver) Owned(_owner) {}

    // ========== VIEWS ==========

    // Note: use public visibility so that it can be invoked in a subclass
    function resolverAddressesRequired() public pure override returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXRATES;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_DEX_AGGREGATOR;
        addresses[4] = CONTRACT_SYNTHR_BRIDGE;
    }

    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
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

    function getSwapSynthToNativeLZFee(address _account, bytes32 _sourceKey, uint256 _sourceAmount, bytes32 _destKey, uint16 _chainId, address _target, bytes memory _data) external view returns (uint256) {
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

    function setNativeAsset(uint16 _chainId, bytes32 _nativeKey, bytes32 _nativeSynth) external onlyOwner {
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

    function swapSynthToNative(uint256 _sourceAmount, bytes32 _sourceKey, bytes32 _destKey, address _target, bytes memory _data, uint16 _chainId) external payable systemActive {
        require(_chainId != 0, "Not allowed swap on self chain");
        require(issuer().synths(_sourceKey).balanceOf(msg.sender) >= _sourceAmount, "Insufficient synth balance.");
        require(nativeSynthPerChain[_chainId] != bytes32(0), "The key wasn't set yet.");
        require(equivalentSynthKey[_destKey] != bytes32(0), "The key wasn't set yet.");

        issuer().synthBurnFromSynthrSwap(msg.sender, _sourceKey, _sourceAmount);
        uint256 destSynthAmount = exchangeRates().effectiveValue(_sourceKey, _sourceAmount, equivalentSynthKey[_destKey]);
        synthrBridge().sendCrossSwapSyAssetToNative{value: msg.value}(msg.sender, _sourceKey, _sourceAmount, equivalentSynthKey[_destKey], destSynthAmount, _chainId, _target, _data);
    }

    function destSwapSynthToNative(address _account, bytes32 _sourceKey, uint256 _sourceAmount, bytes32 _destKey, uint256 _destAmount, address _target, bytes memory _data) external systemActive onlySynthrBridge returns (bool) {
        require(_account != address(0), "Zero account.");
        require(_target != address(0), "Zero target account.");
        require(_destAmount > 0, "Not allowed swap with zero amount");
        require(equivalentCurrencyKey[_destKey] != bytes32(0), "The equivalent currency key wasn't set yet.");
        issuer().synthIssueFromSynthrSwap(address(dexAggregator()), _destKey, _destAmount);

        try dexAggregator().swapSynthToNativeOn0X(_account, _destKey, _destAmount, _target, _data) returns (uint256 result) {
            emit SwapSynthToNative(_account, _sourceKey, _sourceAmount, equivalentCurrencyKey[_destKey], result);
            return true;
        } catch Error(string memory reason) {
            emit SwapSynthToNativeFailed(_account, reason);
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