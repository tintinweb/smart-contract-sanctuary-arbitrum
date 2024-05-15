// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IStrategy.sol";

contract GhostStrategy is IERC20Upgradeable, IStrategy {
    constructor() {}

    function strategyName() external pure returns (string memory) {
        return "Ghost strategy";
    }

    function assetRatio() external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function assetGroupId() external pure returns (uint256) {
        return 0;
    }

    function assets() external pure returns (address[] memory) {
        return new address[](0);
    }

    function doHardWork(StrategyDhwParameterBag calldata) external pure returns (DhwInfo memory) {
        revert IsGhostStrategy();
    }

    function claimShares(address, uint256) external pure {
        revert IsGhostStrategy();
    }

    function releaseShares(address, uint256) external pure {
        revert IsGhostStrategy();
    }

    function redeemFast(uint256, address, address[] calldata, uint256[] calldata)
        external
        pure
        returns (uint256[] memory)
    {
        revert IsGhostStrategy();
    }

    function redeemShares(uint256, address, address[] calldata, uint256[] calldata)
        external
        pure
        returns (uint256[] memory)
    {
        revert IsGhostStrategy();
    }

    function depositFast(
        address[] calldata,
        uint256[] calldata,
        IUsdPriceFeedManager,
        uint256[] calldata,
        SwapInfo[] calldata
    ) external pure returns (uint256) {
        revert IsGhostStrategy();
    }

    function totalSupply() external pure returns (uint256) {
        return 0;
    }

    function balanceOf(address) external pure returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert IsGhostStrategy();
    }

    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure returns (bool) {
        revert IsGhostStrategy();
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert IsGhostStrategy();
    }

    function beforeDepositCheck(uint256[] memory, uint256[] calldata) external pure {
        revert IsGhostStrategy();
    }

    function beforeRedeemalCheck(uint256, uint256[] calldata) external pure {
        revert IsGhostStrategy();
    }

    function emergencyWithdraw(uint256[] calldata, address) external pure {
        revert IsGhostStrategy();
    }

    function getUsdWorth(uint256[] memory, IUsdPriceFeedManager) external pure returns (uint256) {
        revert IsGhostStrategy();
    }

    function getUnderlyingAssetAmounts() external pure returns (uint256[] memory) {
        revert IsGhostStrategy();
    }

    function getProtocolRewards() external pure returns (address[] memory, uint256[] memory) {
        revert IsGhostStrategy();
    }
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