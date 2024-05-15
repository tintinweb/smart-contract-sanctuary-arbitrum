// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IAllocationProvider.sol";
import "../interfaces/IRiskManager.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IStrategyRegistry.sol";
import "../interfaces/Constants.sol";
import "../access/SpoolAccessControllable.sol";
import "../libraries/uint16a16Lib.sol";

contract RiskManager is IRiskManager, SpoolAccessControllable {
    using uint16a16Lib for uint16a16;

    /* ========== STATE VARIABLES ========== */

    /// @notice Association of a risk provider to a strategy and finally to a risk score [1, 100]
    mapping(address => mapping(address => uint8)) private _riskScores;

    /// @notice Smart Vault risk providers
    mapping(address => address) private _smartVaultRiskProviders;

    /// @notice Smart Vault risk appetite
    mapping(address => int8) private _smartVaultRiskTolerance;

    /// @notice Smart Vault allocation providers
    mapping(address => address) private _smartVaultAllocationProviders;

    address private immutable _ghostStrategy;

    /// @notice Strategy registry address
    IStrategyRegistry private immutable _strategyRegistry;

    constructor(ISpoolAccessControl accessControl, IStrategyRegistry strategyRegistry_, address ghostStrategy)
        SpoolAccessControllable(accessControl)
    {
        if (address(strategyRegistry_) == address(0)) revert ConfigurationAddressZero();
        if (address(ghostStrategy) == address(0)) revert ConfigurationAddressZero();

        _ghostStrategy = ghostStrategy;
        _strategyRegistry = strategyRegistry_;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function calculateAllocation(address smartVault, address[] calldata strategies)
        public
        view
        returns (uint16a16 allocations)
    {
        // Strategies that are not ghost strategies, their risk scores, and indexes to map to original arrays
        address[] memory validStrategies;
        uint256[] memory indexes;
        (validStrategies, indexes) = _getValidStrategies(strategies);

        uint8[] memory riskScores = getRiskScores(_smartVaultRiskProviders[smartVault], validStrategies);

        int256[] memory apyList = _strategyRegistry.strategyAPYs(validStrategies);
        uint256[] memory allocations_ = IAllocationProvider(_smartVaultAllocationProviders[smartVault])
            .calculateAllocation(
            AllocationCalculationInput({
                strategies: validStrategies,
                apys: apyList,
                riskScores: riskScores,
                riskTolerance: _smartVaultRiskTolerance[smartVault]
            })
        );

        uint256 allocationsSum;
        // allocations_ array might have less values than the number of incoming strategies due to ghost strategies
        for (uint256 i; i < strategies.length; ++i) {
            if (strategies[i] != _ghostStrategy) {
                allocations = allocations.set(i, allocations_[indexes[i]]);
                allocationsSum += allocations_[indexes[i]];
            }
        }

        // Allocations should sum up to FULL_PERCENT
        if (allocationsSum != FULL_PERCENT) {
            revert InvalidAllocationSum(allocationsSum);
        }

        return allocations;
    }

    function getRiskScores(address riskProvider, address[] memory strategies) public view returns (uint8[] memory) {
        uint8[] memory riskScores = new uint8[](strategies.length);
        for (uint256 i; i < strategies.length; ++i) {
            riskScores[i] =
                riskProvider == STATIC_RISK_PROVIDER ? STATIC_RISK_SCORE : _riskScores[riskProvider][strategies[i]];

            if (strategies[i] != _ghostStrategy && riskScores[i] == 0) {
                revert InvalidRiskScores(riskProvider, strategies[i]);
            }
        }

        return riskScores;
    }

    function getRiskProvider(address smartVault) external view returns (address) {
        return _smartVaultRiskProviders[smartVault];
    }

    function getAllocationProvider(address smartVault) external view returns (address) {
        return _smartVaultAllocationProviders[smartVault];
    }

    function getRiskTolerance(address smartVault) external view returns (int8) {
        return _smartVaultRiskTolerance[smartVault];
    }

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    function setRiskTolerance(address smartVault, int8 riskTolerance)
        external
        onlyRole(ROLE_SMART_VAULT_INTEGRATOR, msg.sender)
    {
        if (riskTolerance > MAX_RISK_TOLERANCE || riskTolerance < MIN_RISK_TOLERANCE) {
            revert RiskToleranceValueOutOfBounds(riskTolerance);
        }

        _smartVaultRiskTolerance[smartVault] = riskTolerance;
        emit RiskToleranceSet(smartVault, riskTolerance);
    }

    function setRiskProvider(address smartVault, address riskProvider)
        external
        onlyRole(ROLE_RISK_PROVIDER, riskProvider)
        onlyRole(ROLE_SMART_VAULT_INTEGRATOR, msg.sender)
    {
        _smartVaultRiskProviders[smartVault] = riskProvider;
        emit RiskProviderSet(smartVault, riskProvider);
    }

    function setAllocationProvider(address smartVault, address allocationProvider)
        external
        onlyRole(ROLE_ALLOCATION_PROVIDER, allocationProvider)
        onlyRole(ROLE_SMART_VAULT_INTEGRATOR, msg.sender)
    {
        _smartVaultAllocationProviders[smartVault] = allocationProvider;
        emit AllocationProviderSet(smartVault, allocationProvider);
    }

    function setRiskScores(uint8[] calldata riskScores, address[] calldata strategies)
        external
        onlyRole(ROLE_RISK_PROVIDER, msg.sender)
    {
        if (strategies.length != riskScores.length) {
            revert InvalidRiskInputLength();
        }

        for (uint256 i; i < riskScores.length; ++i) {
            // Risk scores have to be within boundaries, except for ghost strategies, where they should be set to 0
            if (riskScores[i] > MAX_RISK_SCORE || riskScores[i] < MIN_RISK_SCORE && strategies[i] != _ghostStrategy) {
                revert RiskScoreValueOutOfBounds(riskScores[i]);
            }

            // Ghost strategy risk score should be set to 0
            if (strategies[i] == _ghostStrategy && riskScores[i] > 0) {
                revert CannotSetRiskScoreForGhostStrategy(riskScores[i]);
            }

            _riskScores[msg.sender][strategies[i]] = riskScores[i];
        }

        emit RiskScoresUpdated(msg.sender, strategies, riskScores);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Filter strategies and their risk scores to exclude ghost strategies
     */
    function _getValidStrategies(address[] calldata strategies)
        private
        view
        returns (address[] memory strategies_, uint256[] memory indexes)
    {
        uint256 validStrategies;
        for (uint256 i; i < strategies.length; ++i) {
            if (strategies[i] != _ghostStrategy) {
                validStrategies += 1;
            }
        }

        strategies_ = new address[](validStrategies);
        indexes = new uint256[](strategies.length);

        uint256 j;
        for (uint256 i; i < strategies.length; ++i) {
            if (strategies[i] != _ghostStrategy) {
                strategies_[j] = strategies[i];
                indexes[i] = j;
                ++j;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when number of provided APYs or risk scores does not match number of provided strategies.
 */
error ApysOrRiskScoresLengthMismatch(uint256, uint256);

/**
 * @notice Input for calculating allocation.
 * @custom:member strategies Strategies to allocate.
 * @custom:member apys APYs for each strategy.
 * @custom:member riskScores Risk scores for each strategy.
 * @custom:member riskTolerance Risk tolerance of the smart vault.
 */
struct AllocationCalculationInput {
    address[] strategies;
    int256[] apys;
    uint8[] riskScores;
    int8 riskTolerance;
}

interface IAllocationProvider {
    /**
     * @notice Calculates allocation between strategies based on input parameters.
     * @param data Input data for allocation calculation.
     * @return allocation Calculated allocation.
     */
    function calculateAllocation(AllocationCalculationInput calldata data)
        external
        view
        returns (uint256[] memory allocation);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/uint16a16Lib.sol";

error InvalidRiskInputLength();
error RiskScoreValueOutOfBounds(uint8 value);
error RiskToleranceValueOutOfBounds(int8 value);
error CannotSetRiskScoreForGhostStrategy(uint8 riskScore);
error InvalidAllocationSum(uint256 allocationsSum);
error InvalidRiskScores(address riskProvider, address strategy);

interface IRiskManager {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Calculates allocation between strategies based on
     * - risk scores of strategies
     * - risk appetite
     * @param smartVault Smart vault address.
     * @param strategies Strategies.
     * @return allocation Calculated allocation.
     */
    function calculateAllocation(address smartVault, address[] calldata strategies)
        external
        view
        returns (uint16a16 allocation);

    /**
     * @notice Gets risk scores for strategies.
     * @param riskProvider Requested risk provider.
     * @param strategy Strategies.
     * @return riskScores Risk scores for strategies.
     */
    function getRiskScores(address riskProvider, address[] memory strategy)
        external
        view
        returns (uint8[] memory riskScores);

    /**
     * @notice Gets configured risk provider for a smart vault.
     * @param smartVault Smart vault.
     * @return riskProvider Risk provider for the smart vault.
     */
    function getRiskProvider(address smartVault) external view returns (address riskProvider);

    /**
     * @notice Gets configured allocation provider for a smart vault.
     * @param smartVault Smart vault.
     * @return allocationProvider Allocation provider for the smart vault.
     */
    function getAllocationProvider(address smartVault) external view returns (address allocationProvider);

    /**
     * @notice Gets configured risk tolerance for a smart vault.
     * @param smartVault Smart vault.
     * @return riskTolerance Risk tolerance for the smart vault.
     */
    function getRiskTolerance(address smartVault) external view returns (int8 riskTolerance);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Sets risk provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk provider must have role ROLE_RISK_PROVIDER
     * @param smartVault Smart vault.
     * @param riskProvider_ Risk provider to set.
     */
    function setRiskProvider(address smartVault, address riskProvider_) external;

    /**
     * @notice Sets allocation provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - allocation provider must have role ROLE_ALLOCATION_PROVIDER
     * @param smartVault Smart vault.
     * @param allocationProvider Allocation provider to set.
     */
    function setAllocationProvider(address smartVault, address allocationProvider) external;

    /**
     * @notice Sets risk scores for strategies.
     * @dev Requirements:
     * - caller must have role ROLE_RISK_PROVIDER
     * @param riskScores Risk scores to set for strategies.
     * @param strategies Strategies for which to set risk scores.
     */
    function setRiskScores(uint8[] calldata riskScores, address[] calldata strategies) external;

    /**
     * @notice Sets risk tolerance for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk tolerance must be within valid bounds
     * @param smartVault Smart vault.
     * @param riskTolerance Risk tolerance to set.
     */
    function setRiskTolerance(address smartVault, int8 riskTolerance) external;

    /**
     * @notice Risk scores updated
     * @param riskProvider risk provider address
     * @param strategies strategy addresses
     * @param riskScores risk score values
     */
    event RiskScoresUpdated(address indexed riskProvider, address[] strategies, uint8[] riskScores);

    /**
     * @notice Smart vault risk provider set
     * @param smartVault Smart vault address
     * @param riskProvider New risk provider address
     */
    event RiskProviderSet(address indexed smartVault, address indexed riskProvider);

    /**
     * @notice Smart vault allocation provider set
     * @param smartVault Smart vault address
     * @param allocationProvider New allocation provider address
     */
    event AllocationProviderSet(address indexed smartVault, address indexed allocationProvider);

    /**
     * @notice Smart vault risk appetite
     * @param smartVault Smart vault address
     * @param riskTolerance risk appetite value
     */
    event RiskToleranceSet(address indexed smartVault, int8 riskTolerance);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {PlatformFees} from "./IStrategyRegistry.sol";
import "./ISwapper.sol";
import "./IUsdPriceFeedManager.sol";

/**
 * @notice Struct holding information how to swap the assets.
 * @custom:member slippage minumum output amount
 * @custom:member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path
}

/**
 * @notice Parameters for calling do hard work on strategy.
 * @custom:member swapInfo Information for swapping assets before depositing into the protocol.
 * @custom:member swapInfo Information for swapping rewards before depositing them back into the protocol.
 * @custom:member slippages Slippages used to constrain depositing and withdrawing from the protocol.
 * @custom:member assetGroup Asset group of the strategy.
 * @custom:member exchangeRates Exchange rates for assets.
 * @custom:member withdrawnShares Strategy shares withdrawn by smart vault.
 * @custom:member masterWallet Master wallet.
 * @custom:member priceFeedManager Price feed manager.
 * @custom:member baseYield Base yield value, manual input for specific strategies.
 * @custom:member platformFees Platform fees info.
 */
struct StrategyDhwParameterBag {
    SwapInfo[] swapInfo;
    SwapInfo[] compoundSwapInfo;
    uint256[] slippages;
    address[] assetGroup;
    uint256[] exchangeRates;
    uint256 withdrawnShares;
    address masterWallet;
    IUsdPriceFeedManager priceFeedManager;
    int256 baseYield;
    PlatformFees platformFees;
}

/**
 * @notice Information about results of the do hard work.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member assetsWithdrawn Amount of assets withdrawn.
 * @custom:member yieldPercentage Yield percentage from the previous DHW.
 * @custom:member valueAtDhw Value of the strategy at the end of DHW.
 * @custom:member totalSstsAtDhw Total SSTs at the end of DHW.
 */
struct DhwInfo {
    uint256 sharesMinted;
    uint256[] assetsWithdrawn;
    int256 yieldPercentage;
    uint256 valueAtDhw;
    uint256 totalSstsAtDhw;
}

/**
 * @notice Used when ghost strategy is called.
 */
error IsGhostStrategy();

/**
 * @notice Used when user is not allowed to redeem fast.
 * @param user User that tried to redeem fast.
 */
error NotFastRedeemer(address user);

/**
 * @notice Used when asset group ID is not correctly initialized.
 */
error InvalidAssetGroupIdInitialization();

interface IStrategy is IERC20Upgradeable {
    /* ========== EVENTS ========== */

    event Deposited(
        uint256 mintedShares, uint256 usdWorthDeposited, uint256[] assetsBeforeSwap, uint256[] assetsDeposited
    );

    event Withdrawn(uint256 withdrawnShares, uint256 usdWorthWithdrawn, uint256[] withdrawnAssets);

    event PlatformFeesCollected(address indexed strategy, uint256 sharesMinted);

    event Slippages(bool isDeposit, uint256 slippage, bytes data);

    event BeforeDepositCheckSlippages(uint256[] amounts);

    event BeforeRedeemalCheckSlippages(uint256 ssts);

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets strategy name.
     * @return name Name of the strategy.
     */
    function strategyName() external view returns (string memory name);

    /**
     * @notice Gets required ratio between underlying assets.
     * @return ratio Required asset ratio for the strategy.
     */
    function assetRatio() external view returns (uint256[] memory ratio);

    /**
     * @notice Gets asset group used by the strategy.
     * @return id ID of the asset group.
     */
    function assetGroupId() external view returns (uint256 id);

    /**
     * @notice Gets underlying assets for the strategy.
     * @return assets Addresses of the underlying assets.
     */
    function assets() external view returns (address[] memory assets);

    /**
     * @notice Gets underlying asset amounts for the strategy.
     * @return amounts Amounts of the underlying assets.
     */
    function getUnderlyingAssetAmounts() external view returns (uint256[] memory amounts);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @dev Performs slippages check before depositing.
     * @param amounts Amounts to be deposited.
     * @param slippages Slippages to check against.
     */
    function beforeDepositCheck(uint256[] memory amounts, uint256[] calldata slippages) external;

    /**
     * @dev Performs slippages check before redeemal.
     * @param ssts Amount of strategy tokens to be redeemed.
     * @param slippages Slippages to check against.
     */
    function beforeRedeemalCheck(uint256 ssts, uint256[] calldata slippages) external;

    /**
     * @notice Does hard work:
     * - compounds rewards
     * - deposits into the protocol
     * - withdraws from the protocol
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param dhwParams Parameters for the do hard work.
     * @return info Information about do the performed hard work.
     */
    function doHardWork(StrategyDhwParameterBag calldata dhwParams) external returns (DhwInfo memory info);

    /**
     * @notice Claims strategy shares after do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault claiming shares.
     * @param amount Amount of strategy shares to claim.
     */
    function claimShares(address smartVault, uint256 amount) external;

    /**
     * @notice Releases shares back to strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param smartVault Smart vault releasing shares.
     * @param amount Amount of strategy shares to release.
     */
    function releaseShares(address smartVault, uint256 amount) external;

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have either role ROLE_SMART_VAULT_MANAGER or role ROLE_STRATEGY_REGISTRY
     * @param shares Amount of shares to redeem.
     * @param masterWallet Address of the master wallet.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemFast(
        uint256 shares,
        address masterWallet,
        address[] calldata assetGroup,
        uint256[] calldata slippages
    ) external returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @param shares Amount of shares to redeem.
     * @param redeemer Address of he redeemer, owner of SSTs.
     * @param assetGroup Asset group of the strategy.
     * @param slippages Slippages to guard redeeming.
     * @return assetsWithdrawn Amount of assets withdrawn.
     */
    function redeemShares(uint256 shares, address redeemer, address[] calldata assetGroup, uint256[] calldata slippages)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Instantly deposits into the protocol.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param assetGroup Asset group of the strategy.
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     * @param slippages Slippages to guard depositing.
     * @param swapInfo Information for swapping assets before depositing into the protocol.
     * @return sstsMinted Amount of SSTs minted.
     */
    function depositFast(
        address[] calldata assetGroup,
        uint256[] calldata exchangeRates,
        IUsdPriceFeedManager priceFeedManager,
        uint256[] calldata slippages,
        SwapInfo[] calldata swapInfo
    ) external returns (uint256 sstsMinted);

    /**
     * @notice Instantly withdraws assets, bypassing shares mechanism.
     * Transfers withdrawn assets to the emergency withdrawal wallet.
     * @dev Requirements:
     * - caller must have role ROLE_STRATEGY_REGISTRY
     * @param slippages Slippages to guard redeeming.
     * @param recipient Recipient address
     */
    function emergencyWithdraw(uint256[] calldata slippages, address recipient) external;

    /**
     * @notice Gets USD worth of the strategy.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param exchangeRates Asset to USD exchange rates.
     * @param priceFeedManager Price feed manager contract.
     */
    function getUsdWorth(uint256[] memory exchangeRates, IUsdPriceFeedManager priceFeedManager)
        external
        returns (uint256 usdWorth);

    /**
     * @notice Gets protocol rewards.
     * @dev Requirements:
     * - can only be called in view-execution mode.
     * @return tokens Addresses of reward tokens.
     * @return amounts Amount of reward tokens available.
     */
    function getProtocolRewards() external returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./ISwapper.sol";
import {DhwInfo} from "./IStrategy.sol";
import "../libraries/uint16a16Lib.sol";

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to register an already registered strategy.
 * @param address_ Address of already registered strategy.
 */
error StrategyAlreadyRegistered(address address_);

/**
 * @notice Used when DHW was not run yet for a strategy index.
 * @param strategy Address of the strategy.
 * @param strategyIndex Index of the strategy.
 */
error DhwNotRunYetForIndex(address strategy, uint256 strategyIndex);

/**
 * @notice Used when provided token list is invalid.
 */
error InvalidTokenList();

/**
 * @notice Used when ghost strategy is used.
 */
error GhostStrategyUsed();

/**
 * @notice Used when syncing vault that is already fully synced.
 */
error NothingToSync();

/**
 * @notice Used when system tries to configure a too large ecosystem fee.
 * @param ecosystemFeePct Requested ecosystem fee.
 */
error EcosystemFeeTooLarge(uint256 ecosystemFeePct);

/**
 * @notice Used when system tries to configure a too large treasury fee.
 * @param treasuryFeePct Requested treasury fee.
 */
error TreasuryFeeTooLarge(uint256 treasuryFeePct);

/**
 * @notice Used when user tries to re-add a strategy that was previously removed from the system.
 * @param strategy Strategy address
 */
error StrategyPreviouslyRemoved(address strategy);

/**
 * @notice Represents change of state for a strategy during a DHW.
 * @custom:member exchangeRates Exchange rates between assets and USD.
 * @custom:member assetsDeposited Amount of assets deposited into the strategy.
 * @custom:member sharesMinted Amount of strategy shares minted.
 * @custom:member totalSSTs Amount of strategy shares at the end of the DHW.
 * @custom:member totalStrategyValue Total strategy value at the end of the DHW.
 * @custom:member dhwYields DHW yield percentage from the previous DHW.
 */
struct StrategyAtIndex {
    uint256[] exchangeRates;
    uint256[] assetsDeposited;
    uint256 sharesMinted;
    uint256 totalSSTs;
    uint256 totalStrategyValue;
    int256 dhwYields;
}

/**
 * @notice Parameters for calling do hard work.
 * @custom:member strategies Strategies to do-hard-worked upon, grouped by their asset group.
 * @custom:member swapInfo Information for swapping assets before depositing into protocol. SwapInfo[] per each strategy.
 * @custom:member compoundSwapInfo Information for swapping rewards before depositing them back into the protocol. SwapInfo[] per each strategy.
 * @custom:member strategySlippages Slippages used to constrain depositing into and withdrawing from the protocol. uint256[] per strategy.
 * @custom:member baseYields Base yield percentage the strategy created in the DHW period (applicable only for some strategies).
 * @custom:member tokens List of all asset tokens involved in the do hard work.
 * @custom:member exchangeRateSlippages Slippages used to constrain exchange rates for asset tokens. uint256[2] for each token.
 * @custom:member validUntil Sets the maximum timestamp the user is willing to wait to start executing 'do hard work'.
 */
struct DoHardWorkParameterBag {
    address[][] strategies;
    SwapInfo[][][] swapInfo;
    SwapInfo[][][] compoundSwapInfo;
    uint256[][][] strategySlippages;
    int256[][] baseYields;
    address[] tokens;
    uint256[2][] exchangeRateSlippages;
    uint256 validUntil;
}

/**
 * @notice Parameters for calling redeem fast.
 * @custom:member strategies Addresses of strategies.
 * @custom:member strategyShares Amount of shares to redeem.
 * @custom:member assetGroup Asset group of the smart vault.
 * @custom:member slippages Slippages to guard withdrawal.
 */
struct RedeemFastParameterBag {
    address[] strategies;
    uint256[] strategyShares;
    address[] assetGroup;
    uint256[][] withdrawalSlippages;
}

/**
 * @notice Group of platform fees.
 * @custom:member ecosystemFeeReciever Receiver of the ecosystem fees.
 * @custom:member ecosystemFeePct Ecosystem fees. Expressed in FULL_PERCENT.
 * @custom:member treasuryFeeReciever Receiver of the treasury fees.
 * @custom:member treasuryFeePct Treasury fees. Expressed in FULL_PERCENT.
 */
struct PlatformFees {
    address ecosystemFeeReceiver;
    uint96 ecosystemFeePct;
    address treasuryFeeReceiver;
    uint96 treasuryFeePct;
}

/* ========== INTERFACES ========== */

interface IStrategyRegistry {
    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns address of emergency withdrawal wallet.
     * @return emergencyWithdrawalWallet Address of the emergency withdrawal wallet.
     */
    function emergencyWithdrawalWallet() external view returns (address emergencyWithdrawalWallet);

    /**
     * @notice Returns current do-hard-work indexes for strategies.
     * @param strategies Strategies.
     * @return dhwIndexes Current do-hard-work indexes for strategies.
     */
    function currentIndex(address[] calldata strategies) external view returns (uint256[] memory dhwIndexes);

    /**
     * @notice Returns current strategy APYs.
     * @param strategies Strategies.
     */
    function strategyAPYs(address[] calldata strategies) external view returns (int256[] memory apys);

    /**
     * @notice Returns assets deposited into a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return assets Assets deposited into the do-hard-work index for the strategy.
     */
    function depositedAssets(address strategy, uint256 dhwIndex) external view returns (uint256[] memory assets);

    /**
     * @notice Returns shares redeemed in a do-hard-work index for a strategy.
     * @param strategy Strategy.
     * @param dhwIndex Do-hard-work index.
     * @return shares Shares redeemed in a do-hard-work index for the strategy.
     */
    function sharesRedeemed(address strategy, uint256 dhwIndex) external view returns (uint256 shares);

    /**
     * @notice Gets timestamps when do-hard-works were performed.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return timestamps Timestamp for each pair of strategies and do-hard-work indexes.
     */
    function dhwTimestamps(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (uint256[] memory timestamps);

    function getDhwYield(address[] calldata strategies, uint16a16 dhwIndexes)
        external
        view
        returns (int256[] memory yields);

    /**
     * @notice Returns state of strategies at do-hard-work indexes.
     * @param strategies Strategies.
     * @param dhwIndexes Do-hard-work indexes.
     * @return states State of each strategy at corresponding do-hard-work index.
     */
    function strategyAtIndexBatch(address[] calldata strategies, uint16a16 dhwIndexes, uint256 assetGroupLength)
        external
        view
        returns (StrategyAtIndex[] memory states);

    /**
     * @notice Gets required asset ratio for strategy at last DHW.
     * @param strategy Address of the strategy.
     * @return assetRatio Asset ratio.
     */
    function assetRatioAtLastDhw(address strategy) external view returns (uint256[] memory assetRatio);

    /**
     * @notice Gets set platform fees.
     * @return fees Set platform fees.
     */
    function platformFees() external view returns (PlatformFees memory fees);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Registers a strategy into the system.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param strategy Address of strategy to register.
     * @param apy Apy of the strategy at the time of the registration.
     */
    function registerStrategy(address strategy, int256 apy) external;

    /**
     * @notice Removes strategy from the system.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategy Strategy to remove.
     */
    function removeStrategy(address strategy) external;

    /**
     * @notice Sets ecosystem fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeePct Ecosystem fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setEcosystemFee(uint96 ecosystemFeePct) external;

    /**
     * @notice Sets receiver of the ecosystem fees.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param ecosystemFeeReceiver Receiver to set.
     */
    function setEcosystemFeeReceiver(address ecosystemFeeReceiver) external;

    /**
     * @notice Sets treasury fee.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeePct Treasury fee to set. Expressed in terms of FULL_PERCENT.
     */
    function setTreasuryFee(uint96 treasuryFeePct) external;

    /**
     * @notice Sets treasury fee receiver.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param treasuryFeeReceiver Receiver to set.
     */
    function setTreasuryFeeReceiver(address treasuryFeeReceiver) external;

    /**
     * @notice Does hard work on multiple strategies.
     * @dev Requirements:
     * - caller must have role ROLE_DO_HARD_WORKER
     * @param dhwParams Parameters for do hard work.
     */
    function doHardWork(DoHardWorkParameterBag calldata dhwParams) external;

    /**
     * @notice Adds deposits to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add deposit.
     * @param amounts Amounts of assets to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addDeposits(address[] calldata strategies, uint256[][] calldata amounts)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Adds withdrawals to strategies to be processed at next do-hard-work.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param strategies Strategies to which to add withdrawal.
     * @param strategyShares Amounts of strategy shares to add to each strategy.
     * @return strategyIndexes Current do-hard-work indexes for the strategies.
     */
    function addWithdrawals(address[] calldata strategies, uint256[] calldata strategyShares)
        external
        returns (uint16a16 strategyIndexes);

    /**
     * @notice Instantly redeems strategy shares for assets.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * @param redeemFastParams Parameters for fast redeem.
     * @return withdrawnAssets Amount of assets withdrawn.
     */
    function redeemFast(RedeemFastParameterBag calldata redeemFastParams)
        external
        returns (uint256[] memory withdrawnAssets);

    /**
     * @notice Claims withdrawals from the strategies.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_MANAGER
     * - DHWs must be run for withdrawal indexes.
     * @param strategies Addresses if strategies from which to claim withdrawal.
     * @param dhwIndexes Indexes of strategies when withdrawal was made.
     * @param strategyShares Amount of strategy shares that was withdrawn.
     * @return assetsWithdrawn Amount of assets withdrawn from strategies.
     */
    function claimWithdrawals(address[] calldata strategies, uint16a16 dhwIndexes, uint256[] calldata strategyShares)
        external
        returns (uint256[] memory assetsWithdrawn);

    /**
     * @notice Redeems strategy shares.
     * Used by recipients of platform fees.
     * @param strategies Strategies from which to redeem.
     * @param shares Amount of shares to redeem from each strategy.
     * @param withdrawalSlippages Slippages to guard redeemal process.
     */
    function redeemStrategyShares(
        address[] calldata strategies,
        uint256[] calldata shares,
        uint256[][] calldata withdrawalSlippages
    ) external;

    /**
     * @notice Strategy was registered
     * @param strategy Strategy address
     */
    event StrategyRegistered(address indexed strategy);

    /**
     * @notice Strategy was removed
     * @param strategy Strategy address
     */
    event StrategyRemoved(address indexed strategy);

    /**
     * @notice Strategy DHW was executed
     * @param strategy Strategy address
     * @param dhwIndex DHW index
     * @param dhwInfo DHW info
     */
    event StrategyDhw(address indexed strategy, uint256 dhwIndex, DhwInfo dhwInfo);

    /**
     * @notice Ecosystem fee configuration was changed
     * @param feePct Fee percentage value
     */
    event EcosystemFeeSet(uint256 feePct);

    /**
     * @notice Ecosystem fee receiver was changed
     * @param ecosystemFeeReceiver Receiver address
     */
    event EcosystemFeeReceiverSet(address indexed ecosystemFeeReceiver);

    /**
     * @notice Treasury fee configuration was changed
     * @param feePct Fee percentage value
     */
    event TreasuryFeeSet(uint256 feePct);

    /**
     * @notice Treasury fee receiver was changed
     * @param treasuryFeeReceiver Receiver address
     */
    event TreasuryFeeReceiverSet(address indexed treasuryFeeReceiver);

    /**
     * @notice Emergency withdrawal wallet changed
     * @param wallet Emergency withdrawal wallet address
     */
    event EmergencyWithdrawalWalletSet(address indexed wallet);

    /**
     * @notice Strategy shares have been redeemed
     * @param strategy Strategy address
     * @param owner Address that owns the shares
     * @param recipient Address that received the withdrawn funds
     * @param shares Amount of shares that were redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesRedeemed(
        address indexed strategy,
        address indexed owner,
        address indexed recipient,
        uint256 shares,
        uint256[] assetsWithdrawn
    );

    /**
     * @notice Strategy shares were fast redeemed
     * @param strategy Strategy address
     * @param shares Amount of shares redeemed
     * @param assetsWithdrawn Amounts of withdrawn assets
     */
    event StrategySharesFastRedeemed(address indexed strategy, uint256 shares, uint256[] assetsWithdrawn);

    /**
     * @notice Strategy APY value was updated
     * @param strategy Strategy address
     * @param apy New APY value
     */
    event StrategyApyUpdated(address indexed strategy, int256 apy);
}

interface IEmergencyWithdrawal {
    /**
     * @notice Emitted when a strategy is emergency withdrawn from.
     * @param strategy Strategy that was emergency withdrawn from.
     */
    event StrategyEmergencyWithdrawn(address indexed strategy);

    /**
     * @notice Set a new address that will receive assets withdrawn if emergency withdrawal is executed.
     * @dev Requirements:
     * - caller must have role ROLE_SPOOL_ADMIN
     * @param wallet Address to set as the emergency withdrawal wallet.
     */
    function setEmergencyWithdrawalWallet(address wallet) external;

    /**
     * @notice Instantly withdraws assets from a strategy, bypassing shares mechanism.
     * @dev Requirements:
     * - caller must have role ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR
     * @param strategies Addresses of strategies.
     * @param withdrawalSlippages Slippages to guard withdrawal.
     * @param removeStrategies Whether to remove strategies from the system after withdrawal.
     */
    function emergencyWithdraw(
        address[] calldata strategies,
        uint256[][] calldata withdrawalSlippages,
        bool removeStrategies
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of seconds in an average year.
uint256 constant SECONDS_IN_YEAR = 31_556_926;

/// @dev Number of seconds in an average year.
int256 constant SECONDS_IN_YEAR_INT = 31_556_926;

/// @dev Represents 100%.
uint256 constant FULL_PERCENT = 100_00;

/// @dev Represents 100%.
int256 constant FULL_PERCENT_INT = 100_00;

/// @dev Represents 100% for yield.
int256 constant YIELD_FULL_PERCENT_INT = 10 ** 12;

/// @dev Represents 100% for yield.
uint256 constant YIELD_FULL_PERCENT = uint256(YIELD_FULL_PERCENT_INT);

/// @dev Maximal management fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant MANAGEMENT_FEE_MAX = 5_00;

/// @dev Maximal deposit fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant DEPOSIT_FEE_MAX = 5_00;

/// @dev Maximal smart vault performance fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant SV_PERFORMANCE_FEE_MAX = 20_00;

/// @dev Maximal ecosystem fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant ECOSYSTEM_FEE_MAX = 20_00;

/// @dev Maximal treasury fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant TREASURY_FEE_MAX = 10_00;

/// @dev Maximal risk score a strategy can be assigned.
uint8 constant MAX_RISK_SCORE = 10_0;

/// @dev Minimal risk score a strategy can be assigned.
uint8 constant MIN_RISK_SCORE = 1;

/// @dev Maximal value for risk tolerance a smart vautl can have.
int8 constant MAX_RISK_TOLERANCE = 10;

/// @dev Minimal value for risk tolerance a smart vault can have.
int8 constant MIN_RISK_TOLERANCE = -10;

/// @dev If set as risk provider, system will return fixed risk score values
address constant STATIC_RISK_PROVIDER = address(0xaaa);

/// @dev Fixed values to use if risk provider is set to STATIC_RISK_PROVIDER
uint8 constant STATIC_RISK_SCORE = 1;

/// @dev Maximal value of deposit NFT ID.
uint256 constant MAXIMAL_DEPOSIT_ID = 2 ** 255;

/// @dev Maximal value of withdrawal NFT ID.
uint256 constant MAXIMAL_WITHDRAWAL_ID = 2 ** 256 - 1;

/// @dev How many shares will be minted with a NFT
uint256 constant NFT_MINTED_SHARES = 10 ** 6;

/// @dev Each smart vault can have up to STRATEGY_COUNT_CAP strategies.
uint256 constant STRATEGY_COUNT_CAP = 16;

/// @dev Maximal DHW base yield. Expressed in terms of FULL_PERCENT.
uint256 constant MAX_DHW_BASE_YIELD_LIMIT = 10_00;

/// @dev Smart vault and strategy share multiplier at first deposit.
uint256 constant INITIAL_SHARE_MULTIPLIER = 1000;

/// @dev Strategy initial locked shares. These shares will never be unlocked.
uint256 constant INITIAL_LOCKED_SHARES = 10 ** 12;

/// @dev Strategy initial locked shares address.
address constant INITIAL_LOCKED_SHARES_ADDRESS = address(0xdead);

/// @dev Maximum number of guards a smart vault can be configured with
uint256 constant MAX_GUARD_COUNT = 10;

/// @dev Maximum number of actions a smart vault can be configured with
uint256 constant MAX_ACTION_COUNT = 10;

/// @dev ID of null asset group. Should not be used by any strategy or smart vault.
uint256 constant NULL_ASSET_GROUP_ID = 0;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/ISpoolAccessControl.sol";
import "../interfaces/CommonErrors.sol";
import "./Roles.sol";

/**
 * @notice Account access role verification middleware
 */
abstract contract SpoolAccessControllable {
    /* ========== CONSTANTS ========== */

    /**
     * @dev Spool access control manager.
     */
    ISpoolAccessControl internal immutable _accessControl;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param accessControl_ Spool access control manager.
     */
    constructor(ISpoolAccessControl accessControl_) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();

        _accessControl = accessControl_;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Reverts if an account is missing a role.\
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_accessControl.hasRole(role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Revert if an account is missing a role for a smartVault.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkSmartVaultRole(address smartVault, bytes32 role, address account) internal view {
        if (!_accessControl.hasSmartVaultRole(smartVault, role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (_accessControl.paused()) {
            revert SystemPaused();
        }
    }

    function _checkNonReentrant() internal view {
        _accessControl.checkNonReentrant();
    }

    function _nonReentrantBefore() internal {
        _accessControl.nonReentrantBefore();
    }

    function _nonReentrantAfter() internal {
        _accessControl.nonReentrantAfter();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Only allows accounts with granted role.
     * @dev Reverts when the account fails check.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    /**
     * @notice Only allows accounts with granted role for a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlySmartVaultRole(address smartVault, bytes32 role, address account) {
        _checkSmartVaultRole(smartVault, role, account);
        _;
    }

    /**
     * @notice Only allows accounts that are Spool admins or admins of a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param account Account to check.
     */
    modifier onlyAdminOrVaultAdmin(address smartVault, address account) {
        _accessControl.checkIsAdminOrVaultAdmin(smartVault, account);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, or other contracts using this modifier.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev Check if a system has already entered in the non-reentrant state.
     */
    modifier checkNonReentrant() {
        _checkNonReentrant();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/* ========== STRUCTS ========== */

/**
 * @notice Information needed to make a swap of assets.
 * @custom:member swapTarget Contract executing the swap.
 * @custom:member token Token to be swapped.
 * @custom:member swapCallData Calldata describing the swap itself.
 */
struct SwapInfo {
    address swapTarget;
    address token;
    bytes swapCallData;
}

/* ========== ERRORS ========== */

/**
 * @notice Used when trying to do a swap via an exchange that is not allowed to execute a swap.
 * @param exchange Exchange used.
 */
error ExchangeNotAllowed(address exchange);

/**
 * @notice Used when trying to execute a swap but are not authorized.
 * @param caller Caller of the swap method.
 */
error NotSwapper(address caller);

/* ========== INTERFACES ========== */

interface ISwapper {
    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when the exchange allowlist is updated.
     * @param exchange Exchange that was updated.
     * @param isAllowed Whether the exchange is allowed to be used in a swap or not after the update.
     */
    event ExchangeAllowlistUpdated(address indexed exchange, bool isAllowed);

    event Swapped(
        address indexed receiver, address[] tokensIn, address[] tokensOut, uint256[] amountsIn, uint256[] amountsOut
    );

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Performs a swap of tokens with external contracts.
     * - deposit tokens into the swapper contract
     * - swapper will swap tokens based on swap info provided
     * - swapper will return unswapped tokens to the receiver
     * @param tokensIn Addresses of tokens available for the swap.
     * @param swapInfo Information needed to perform the swap.
     * @param tokensOut Addresses of tokens to swap to.
     * @param receiver Receiver of unswapped tokens.
     * @return amountsOut Amounts of `tokensOut` sent from the swapper to the receiver.
     */
    function swap(
        address[] calldata tokensIn,
        SwapInfo[] calldata swapInfo,
        address[] calldata tokensOut,
        address receiver
    ) external returns (uint256[] memory amountsOut);

    /**
     * @notice Updates list of exchanges that can be used in a swap.
     * @dev Requirements:
     *   - can only be called by user granted ROLE_SPOOL_ADMIN
     *   - exchanges and allowed arrays need to be of same length
     * @param exchanges Addresses of exchanges.
     * @param allowed Whether an exchange is allowed to be used in a swap.
     */
    function updateExchangeAllowlist(address[] calldata exchanges, bool[] calldata allowed) external;

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Checks if an exchange is allowed to be used in a swap.
     * @param exchange Exchange to check.
     * @return isAllowed True if the exchange is allowed to be used in a swap, false otherwise.
     */
    function isExchangeAllowed(address exchange) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of decimals used for USD values.
uint256 constant USD_DECIMALS = 18;

/**
 * @notice Emitted when asset is invalid.
 * @param asset Invalid asset.
 */
error InvalidAsset(address asset);

/**
 * @notice Emitted when price returned by price aggregator is negative or zero.
 * @param price Actual price returned by price aggregator.
 */
error NonPositivePrice(int256 price);

/**
 * @notice Emitted when pricing data returned by price aggregator is not from the current
 * round or the round hasn't finished.
 */
error StalePriceData();

interface IUsdPriceFeedManager {
    /**
     * @notice Gets number of decimals for an asset.
     * @param asset Address of the asset.
     * @return assetDecimals Number of decimals for the asset.
     */
    function assetDecimals(address asset) external view returns (uint256 assetDecimals);

    /**
     * @notice Gets number of decimals for USD.
     * @return usdDecimals Number of decimals for USD.
     */
    function usdDecimals() external view returns (uint256 usdDecimals);

    /**
     * @notice Calculates asset value in USD using current price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsd(address asset, uint256 assetAmount) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using current price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAsset(address asset, uint256 usdAmount) external view returns (uint256 assetValue);

    /**
     * @notice Calculates asset value in USD using provided price.
     * @param asset Address of asset.
     * @param assetAmount Amount of asset in asset decimals.
     * @param price Price of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPrice(address asset, uint256 assetAmount, uint256 price)
        external
        view
        returns (uint256 usdValue);

    /**
     * @notice Calculates assets value in USD using provided prices.
     * @param assets Addresses of assets.
     * @param assetAmounts Amounts of assets in asset decimals.
     * @param prices Prices of asset in USD.
     * @return usdValue Value in USD in USD decimals.
     */
    function assetToUsdCustomPriceBulk(
        address[] calldata assets,
        uint256[] calldata assetAmounts,
        uint256[] calldata prices
    ) external view returns (uint256 usdValue);

    /**
     * @notice Calculates USD value in asset using provided price.
     * @param asset Address of asset.
     * @param usdAmount Amount of USD in USD decimals.
     * @param price Price of asset in USD.
     * @return assetValue Value in asset in asset decimals.
     */
    function usdToAssetCustomPrice(address asset, uint256 usdAmount, uint256 price)
        external
        view
        returns (uint256 assetValue);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @notice Used when an account is missing a required role.
 * @param role Required role.
 * @param account Account missing the required role.
 */
error MissingRole(bytes32 role, address account);

/**
 * @notice Used when interacting with Spool when the system is paused.
 */
error SystemPaused();

/**
 * @notice Used when setting smart vault owner
 */
error SmartVaultOwnerAlreadySet(address smartVault);

/**
 * @notice Used when a contract tries to enter in a non-reentrant state.
 */
error ReentrantCall();

/**
 * @notice Used when a contract tries to call in a non-reentrant function and doesn't have the correct role.
 */
error NoReentrantRole();

interface ISpoolAccessControl is IAccessControlUpgradeable {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets owner of a smart vault.
     * @param smartVault Smart vault.
     * @return owner Owner of the smart vault.
     */
    function smartVaultOwner(address smartVault) external view returns (address owner);

    /**
     * @notice Looks if an account has a role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to look for.
     * @param account Account to check.
     * @return hasRole True if account has the role for the smart vault, false otherwise.
     */
    function hasSmartVaultRole(address smartVault, bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /**
     * @notice Checks if an account is either Spool admin or admin for a smart vault.
     * @dev The function reverts if account is neither.
     * @param smartVault Address of the smart vault.
     * @param account to check.
     */
    function checkIsAdminOrVaultAdmin(address smartVault, address account) external view;

    /**
     * @notice Checks if system is paused or not.
     * @return isPaused True if system is paused, false otherwise.
     */
    function paused() external view returns (bool isPaused);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Pauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_PAUSER
     */
    function pause() external;

    /**
     * @notice Unpauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_UNPAUSER
     */
    function unpause() external;

    /**
     * @notice Grants role to an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to grant.
     * @param account Account to grant the role to.
     */
    function grantSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Revokes role from an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to revoke.
     * @param account Account to revoke the role from.
     */
    function revokeSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Renounce role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to renounce.
     */
    function renounceSmartVaultRole(address smartVault, bytes32 role) external;

    /**
     * @notice Grant ownership to smart vault and assigns admin role.
     * @dev Ownership can only be granted once and it should be done at vault creation time.
     * @param smartVault Address of the smart vault.
     * @param owner address to which grant ownership to
     */
    function grantSmartVaultOwnership(address smartVault, address owner) external;

    /**
     * @notice Checks and reverts if a system has already entered in the non-reentrant state.
     */
    function checkNonReentrant() external view;

    /**
     * @notice Sets the entered flag to true when entering for the first time.
     * @dev Reverts if a system has already entered before.
     */
    function nonReentrantBefore() external;

    /**
     * @notice Resets the entered flag after the call is finished.
     */
    function nonReentrantAfter() external;

    /**
     * @notice Emitted when ownership of a smart vault is granted to an address
     * @param smartVault Smart vault address
     * @param address_ Address of the new smart vault owner
     */
    event SmartVaultOwnershipGranted(address indexed smartVault, address indexed address_);

    /**
     * @notice Smart vault specific role was granted
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account to which the role was granted
     */
    event SmartVaultRoleGranted(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was revoked
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account for which the role was revoked
     */
    event SmartVaultRoleRevoked(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was renounced
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account that renounced the role
     */
    event SmartVaultRoleRenounced(address indexed smartVault, bytes32 indexed role, address indexed account);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @dev Grants permission to:
 * - acts as a default admin for other roles,
 * - can whitelist an action with action manager,
 * - can manage asset group registry.
 *
 * Is granted to the deployer of the SpoolAccessControl contract.
 *
 * Equals to the DEFAULT_ADMIN_ROLE of the OpenZeppelin AccessControl.
 */
bytes32 constant ROLE_SPOOL_ADMIN = 0x00;

/**
 * @dev Grants permission to integrate a new smart vault into the Spool ecosystem.
 *
 * Should be granted to smart vault factory contracts.
 */
bytes32 constant ROLE_SMART_VAULT_INTEGRATOR = keccak256("SMART_VAULT_INTEGRATOR");

/**
 * @dev Grants permission to
 * - manage rewards on smart vaults,
 * - manage roles on smart vaults,
 * - redeem for another user of a smart vault.
 */
bytes32 constant ROLE_SMART_VAULT_ADMIN = keccak256("SMART_VAULT_ADMIN");

/**
 * @dev Grants permission to manage allowlists with AllowlistGuard for a smart vault.
 *
 * Should be granted to whoever is in charge of maintaining allowlists with AllowlistGuard for a smart vault.
 */
bytes32 constant ROLE_GUARD_ALLOWLIST_MANAGER = keccak256("GUARD_ALLOWLIST_MANAGER");

/**
 * @dev Grants permission to manage assets on master wallet.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the StrategyRegistry contract,
 * - the DepositManager contract,
 * - the WithdrawalManager contract.
 */
bytes32 constant ROLE_MASTER_WALLET_MANAGER = keccak256("MASTER_WALLET_MANAGER");

/**
 * @dev Marks a contract as a smart vault manager.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the DepositManager contract.
 */
bytes32 constant ROLE_SMART_VAULT_MANAGER = keccak256("SMART_VAULT_MANAGER");

/**
 * @dev Marks a contract as a strategy registry.
 *
 * Should be granted to the StrategyRegistry contract.
 */
bytes32 constant ROLE_STRATEGY_REGISTRY = keccak256("STRATEGY_REGISTRY");

/**
 * @dev Grants permission to act as a risk provider.
 *
 * Should be granted to whoever is allowed to provide risk scores.
 */
bytes32 constant ROLE_RISK_PROVIDER = keccak256("RISK_PROVIDER");

/**
 * @dev Grants permission to act as an allocation provider.
 *
 * Should be granted to contracts that are allowed to calculate allocations.
 */
bytes32 constant ROLE_ALLOCATION_PROVIDER = keccak256("ALLOCATION_PROVIDER");

/**
 * @dev Grants permission to pause the system.
 */
bytes32 constant ROLE_PAUSER = keccak256("SYSTEM_PAUSER");

/**
 * @dev Grants permission to unpause the system.
 */
bytes32 constant ROLE_UNPAUSER = keccak256("SYSTEM_UNPAUSER");

/**
 * @dev Grants permission to manage rewards payment pool.
 */
bytes32 constant ROLE_REWARD_POOL_ADMIN = keccak256("REWARD_POOL_ADMIN");

/**
 * @dev Grants permission to reallocate smart vaults.
 */
bytes32 constant ROLE_REALLOCATOR = keccak256("REALLOCATOR");

/**
 * @dev Grants permission to be used as a strategy.
 */
bytes32 constant ROLE_STRATEGY = keccak256("STRATEGY");

/**
 * @dev Grants permission to manually set strategy apy.
 */
bytes32 constant ROLE_STRATEGY_APY_SETTER = keccak256("STRATEGY_APY_SETTER");

/**
 * @dev Grants permission to manage role ROLE_STRATEGY.
 */
bytes32 constant ADMIN_ROLE_STRATEGY = keccak256("ADMIN_STRATEGY");

/**
 * @dev Grants permission vault admins to allow redeem on behalf of other users.
 */
bytes32 constant ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to manage role ROLE_SMART_VAULT_ALLOW_REDEEM.
 */
bytes32 constant ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("ADMIN_SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to run do hard work.
 */
bytes32 constant ROLE_DO_HARD_WORKER = keccak256("DO_HARD_WORKER");

/**
 * @dev Grants permission to immediately withdraw assets in case of emergency.
 */
bytes32 constant ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR = keccak256("EMERGENCY_WITHDRAWAL_EXECUTOR");

/**
 * @dev Grants permission to swap with swapper.
 *
 * Should be granted to the DepositSwap contract.
 */
bytes32 constant ROLE_SWAPPER = keccak256("SWAPPER");

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}