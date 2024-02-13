/**
 *Submitted for verification at Arbiscan.io on 2024-02-10
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

/// @title Interface of the AmmPoolsLensStEth contract.
interface IAmmPoolsLensStEth {
    /// @notice Retrieves the exchange rate between stEth and ipstEth using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of stEth in the AMM Treasury and the total supply of ipstEth.
    /// @dev This function acts as a wrapper around the `getExchangeRate` function in the AmmLibEth library.
    function getIpstEthExchangeRate() external view returns (uint256);
}

/// @title Interface of the AmmPoolsLensWstEth contract.
interface IAmmPoolsLensWstEth {
    /// @notice Retrieves the exchange rate between stEth and ipwstEth using the AmmLibEth library.
    /// @return The exchange rate calculated based on the balance of stEth in the AMM Treasury and the total supply of ipwstEth.
    /// @dev This function acts as a wrapper around the `getExchangeRate` function in the AmmLibEth library.
    function getIpwstEthExchangeRate() external view returns (uint256);
}

/// @title Interface of the AmmPoolsServiceWstEth contract.
interface IAmmPoolsServiceWstEth {

    function provideLiquidityWstEth(address beneficiary, uint256 stEthAmount) external payable;

    function redeemFromAmmPoolWstEth(address beneficiary, uint256 ipTokenAmount) external;

    event ProvideLiquidityWstEth(
        address indexed from,
        address indexed beneficiary,
        address indexed to,
        uint256 exchangeRate,
        uint256 assetAmount,
        uint256 ipTokenAmount
    );

    event RedeemWstEth(
        address indexed ammTreasuryEth,
        address indexed from,
        address indexed beneficiary,
        uint256 exchangeRate,
        uint256 amountStEth,
        uint256 redeemedAmountStEth,
        uint256 ipTokenAmount
    );
}

/// @title Interface for interacting with AmmGovernanceLens. Interface responsible for reading data from AMM Governance.
interface IAmmGovernanceLens {
    /// @notice Structure of common params described AMM Pool configuration
    struct AmmGovernancePoolConfiguration {
        /// @notice address of asset which represents specific pool
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of AMM Storage
        address ammStorage;
        /// @notice address of AMM Treasury
        address ammTreasury;
        /// @notice address of AMM Pools Treasury Wallet
        address ammPoolsTreasury;
        /// @notice address of user which is allowed to manage AMM Pools Treasury Wallet
        address ammPoolsTreasuryManager;
        /// @notice address of AMM Charlie Treasury Wallet
        address ammCharlieTreasury;
        /// @notice address of user which is allowed to manage AMM Charlie Treasury Wallet
        address ammCharlieTreasuryManager;
    }

    /// @dev A struct to represent a pool's parameters configuration.
    struct AmmPoolsParamsConfiguration {
        /// @dev max liquidity pool balance in the asset pool, represented in 18 decimals
        uint256 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// @dev Supported in USDT, USDC, DAI pool, not supported in stETH pool.
        /// Value represents multiplication of 1000.
        uint256 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        /// @dev Supported in USDT, USDC, DAI pool, not supported in stETH pool.
        uint256 ammTreasuryAndAssetManagementRatio;
    }

    /// @notice Gets the structure or common params described AMM Pool configuration
    /// @param asset Address of asset which represents specific pool
    /// @return poolConfiguration Structure of common params described AMM Pool configuration
    function getAmmGovernancePoolConfiguration(
        address asset
    ) external view returns (AmmGovernancePoolConfiguration memory);

    /// @notice Flag which indicates if given account is an liquidator for given asset
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is checked if is an liquidator
    /// @return isSwapLiquidator Flag which indicates if given account is an liquidator for given asset
    function isSwapLiquidator(address asset, address account) external view returns (bool);

    /// @notice Flag which indicates if given account is an appointed to rebalance in AMM for given asset
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is checked if is an appointed to rebalance in AMM
    /// @return isAppointedToRebalanceInAmm Flag which indicates if given account is an appointed to rebalance in AMM for given asset
    function isAppointedToRebalanceInAmm(address asset, address account) external view returns (bool);

    /// @notice Gets the structure or common params described AMM Pool configuration
    /// @param asset Address of asset which represents specific pool
    /// @return ammPoolsParams Structure of common params described AMM Pool configuration
    function getAmmPoolsParams(address asset) external view returns (AmmPoolsParamsConfiguration memory);
}

/// @title Interface for interacting with the AmmGovernanceService. Interface responsible for managing AMM Pools.
interface IAmmGovernanceService {
    /// @notice Transfers the asset amount from the AmmTreasury to the AssetManagement. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function depositToAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from the AssetManagement to the AmmTreasury. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function withdrawFromAssetManagement(address asset, uint256 assetAmount) external;

    /// @notice Transfers all of the asset from the AssetManagement to the AmmTreasury. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of the asset representing specific pool
    function withdrawAllFromAssetManagement(address asset) external;

    /// @notice Transfers the asset amount from the AmmTreasury to the Treasury Wallet. Action available only to the AMM Treasury Manager.
    /// @dev The AMM collects a part of swap's opening fee adn accounts it towards the "treasury".
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToTreasury(address asset, uint256 assetAmount) external;

    /// @notice Transfers the asset amount from the AmmTreasury to Oracle Treasury Wallet. Action available only to the  AMM Charlie Treasury Manager.
    /// @dev A specific balance known as "iporPublicationFee" exists in AmmTreasury, which is used to collect IPOR publication fees from traders when they initiate swaps.
    /// @dev Within the AmmTreasury, there exists a distinct balance known as "iporPublicationFee," which is utilized by the AMM to accumulate IPOR publication fees from traders as they open swaps.
    /// @param asset Address of asset representing specific pool
    /// @param assetAmount Amount of asset to transfer
    function transferToCharlieTreasury(address asset, uint256 assetAmount) external;

    /// @notice Adds an account to the list of swap liquidators for a given asset. Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account added to the list of swap liquidators
    function addSwapLiquidator(address asset, address account) external;

    /// @notice Removes an account from the list of swap liquidators for a given asset. Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account removed to the list of swap liquidators
    function removeSwapLiquidator(address asset, address account) external;

    /// @notice Add an account to the list of addresses appointed to rebalance AMM for given asset. Action available only to the IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param account Address of an account added to the list of addresses appointed to rebalance in AMM
    /// @dev Rebalancing the AMM is a process of moving liquidity between the AMM and the AssetManagement in the amount defined in param called "ammTreasuryAndAssetManagementRatio".
    function addAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Remove account from the list of appointed to rebalance in AMM for given asset.
    /// @param asset Address of asset which represents specific pool
    /// @param account Address of account which is removed from the list of appointed to rebalance in AMM
    /// @dev Rebalancing the AMM is a process of moving liquidity between the AMM and the AssetManagement in the amount defined in param called "ammTreasuryAndAssetManagementRatio".
    function removeAppointedToRebalanceInAmm(address asset, address account) external;

    /// @notice Sets AMM Pools params for a given asset (pool). Action available only to IPOR Protocol Owner.
    /// @param asset Address of asset representing specific pool
    /// @param newMaxLiquidityPoolBalance New max liquidity pool balance threshold. Value represented WITHOUT 18 decimals.
    /// @param newAutoRebalanceThresholdInThousands New auto rebalance threshold (for USDT,USDC,DAI in thousands). Value represented WITHOUT 18 decimals. For USDT,USDC,DAI value represents multiplication of 1000.
    /// @param newAmmTreasuryAndAssetManagementRatio New AMM Treasury and Asset Management ratio, represented WITHOUT 18 decimals, value represents percentage with 2 decimals. Example: 65% = 6500, 99,99% = 9999
    function setAmmPoolsParams(
        address asset,
        uint32 newMaxLiquidityPoolBalance,
        uint32 newAutoRebalanceThresholdInThousands,
        uint16 newAmmTreasuryAndAssetManagementRatio
    ) external;
}

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapLens {
    /// @notice Structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    struct AmmOpenSwapServicePoolConfiguration {
        /// @notice address of the asset
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice address of the AMM Storage
        address ammStorage;
        /// @notice address of the AMM Treasury
        address ammTreasury;
        /// @notice ipor publication fee, fee used when opening swap, represented in 18 decimals.
        uint256 iporPublicationFee;
        /// @notice maximum swap collateral amount, represented in 18 decimals.
        uint256 maxSwapCollateralAmount;
        /// @notice liquidation deposit amount, represented WITHOUT 18 decimals. Example 25 = 25 USDT.
        uint256 liquidationDepositAmount;
        /// @notice minimum leverage, represented in 18 decimals.
        uint256 minLeverage;
        /// @notice swap's opening fee rate, represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeRate;
        /// @notice swap's opening fee rate, portion of the rate which is allocated to "treasury" balance
        /// @dev Value describes what percentage of opening fee amount is allocated to "treasury" balance. Value represented in 18 decimals. 1e18 = 100%
        uint256 openingFeeTreasuryPortionRate;
    }

    /// @notice Returns configuration of the AmmOpenSwapServicePool for specific asset (pool).
    /// @param asset address of the asset
    /// @return AmmOpenSwapServicePoolConfiguration structure representing configuration of the AmmOpenSwapServicePool for specific asset (pool).
    function getAmmOpenSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmOpenSwapServicePoolConfiguration memory);
}

/// @title LiquidityMiningLens interface responsible for reading data from LiquidityMining.
interface ILiquidityMiningLens {

    /// @title Struct pair representing delegated pwToken balance
    struct DelegatedPwTokenBalance {
        /// @notice lpToken address
        address lpToken;
        /// @notice The amount of Power Token delegated to lpToken staking pool
        /// @dev value represented in 18 decimals
        uint256 pwTokenAmount;
    }

    /// @title Global indicators used in rewards calculation.
    struct GlobalRewardsIndicators {
        /// @notice powerUp indicator aggregated
        /// @dev It can be changed many times during transaction, represented with 18 decimals
        uint256 aggregatedPowerUp;
        /// @notice composite multiplier in a block described in field blockNumber
        /// @dev It can be changed many times during transaction, represented with 27 decimals
        uint128 compositeMultiplierInTheBlock;
        /// @notice Composite multiplier updated in block {blockNumber} but calculated for PREVIOUS (!) block.
        /// @dev It can be changed once per block, represented with 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @dev It can be changed once per block. Block number in which all other params of this structure are updated
        uint32 blockNumber;
        /// @notice value describing amount of rewards issued per block,
        /// @dev It can be changed at most once per block, represented with 8 decimals
        uint32 rewardsPerBlock;
        /// @notice amount of accrued rewards since inception
        /// @dev It can be changed at most once per block, represented with 18 decimals
        uint88 accruedRewards;
    }

    /// @title Params recorded for a given account. These params are used by the algorithm responsible for rewards distribution.
    /// @dev The structure in storage is updated when account interacts with the LiquidityMining smart contract (stake, unstake, delegate, undelegate, claim)
    struct AccountRewardsIndicators {
        /// @notice `composite multiplier cumulative` is calculated for previous block
        /// @dev represented in 27 decimals
        uint128 compositeMultiplierCumulativePrevBlock;
        /// @notice lpToken account's balance
        uint128 lpTokenBalance;
        /// @notive PowerUp is a result of logarithmic equastion,
        /// @dev  powerUp < 100 *10^18
        uint72 powerUp;
        /// @notice balance of Power Tokens delegated to LiquidityMining
        /// @dev delegatedPwTokenBalance < 10^26 < 2^87
        uint96 delegatedPwTokenBalance;
    }

    struct UpdateLpToken {
        address beneficiary;
        address lpToken;
        uint256 lpTokenAmount;
    }

    struct UpdatePwToken {
        address beneficiary;
        address lpToken;
        uint256 pwTokenAmount;
    }

    struct AccruedRewardsResult {
        address lpToken;
        uint256 rewardsAmount;
    }

    struct AccountRewardResult {
        address lpToken;
        uint256 rewardsAmount;
        uint256 allocatedPwTokens;
    }

    struct AccountIndicatorsResult {
        address lpToken;
        AccountRewardsIndicators indicators;
    }

    struct GlobalIndicatorsResult {
        address lpToken;
        GlobalRewardsIndicators indicators;
    }

    /// @notice Returns the balance of LP tokens staked by the specified account in the Liquidity Mining contract.
    /// @param account The address of the account for which the LP token balance is queried.
    /// @param lpToken The address of the LP token for which the balance is queried.
    /// @return The balance of LP tokens staked by the specified account.
    function balanceOfLpTokensStakedInLiquidityMining(address account, address lpToken) external view returns (uint256);

    /// @notice It returns the balance of delegated Power Tokens for a given `account` and the list of lpToken addresses.
    /// @param account address for which to fetch the information about balance of delegated Power Tokens
    /// @param lpTokens list of lpTokens addresses(lpTokens)
    /// @return balances list of {LiquidityMiningTypes.DelegatedPwTokenBalance} structure, with information how much Power Token is delegated per lpToken address.
    function balanceOfPowerTokensDelegatedToLiquidityMining(
        address account,
        address[] memory lpTokens
    ) external view returns (DelegatedPwTokenBalance[] memory balances);

    /// @notice Calculates the accrued rewards for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the accrued rewards are to be calculated.
    /// @return result An array of `AccruedRewardsResult` structs containing the accrued rewards information for each LP token.
    function getAccruedRewardsInLiquidityMining(
        address[] calldata lpTokens
    ) external view returns (AccruedRewardsResult[] memory result);

    /// @notice Calculates the rewards for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the rewards are to be calculated.
    /// @param lpTokens An array of LP tokens for which the rewards are to be calculated.
    /// @return An array of `AccountRewardResult` structs containing the rewards information for each LP token.
    function getAccountRewardsInLiquidityMining(
        address account,
        address[] calldata lpTokens
    ) external view returns (AccountRewardResult[] memory);

    /// @notice Retrieves the global indicators for the specified LP tokens in the Liquidity Mining contract.
    /// @param lpTokens An array of LP tokens for which the global indicators are to be retrieved.
    /// @return An array of `GlobalIndicatorsResult` structs containing the global indicators information for each LP token.
    function getGlobalIndicatorsFromLiquidityMining(
        address[] memory lpTokens
    ) external view returns (GlobalIndicatorsResult[] memory);

    /// @notice Retrieves the account indicators for the specified account and LP tokens in the Liquidity Mining contract.
    /// @param account The address of the account for which the account indicators are to be retrieved.
    /// @param lpTokens An array of LP tokens for which the account indicators are to be retrieved.
    /// @return An array of `AccountIndicatorsResult` structs containing the account indicators information for each LP token.
    function getAccountIndicatorsFromLiquidityMining(
        address account,
        address[] memory lpTokens
    ) external view returns (AccountIndicatorsResult[] memory);
}

/// @title Interface for interaction with PowerToken and LiquidityMining contracts.
interface IPowerTokenFlowsService {
    /// @notice Claims rewards for the caller by transferring them from the LiquidityMining contract to the PowerToken contract.
    /// @param lpTokens An array of LP tokens for which the rewards are to be claimed.
    /// @dev This function calls the `claim` function of the `ILiquidityMiningV2` contract to retrieve the rewards amount to transfer.
    /// It then adds the staked tokens to the `powerToken` contract and transfers the rewards from the `liquidityMining` contract to the `powerToken` contract.
    /// @dev Reverts if the `lpTokens` array is empty.
    /// @dev Reverts if there are no rewards to claim.
    function claimRewardsFromLiquidityMining(address[] calldata lpTokens) external;

    /// @notice Updates the indicators for a given account and LP tokens.
    /// @param account The account address for which the indicators are to be updated.
    /// @param lpTokens An array of LP tokens for which the indicators are to be updated.
    /// @dev This function calls the `updateIndicators` function of the `ILiquidityMiningV2` contract to update the indicators.
    /// @dev Reverts if the `lpTokens` array is empty.
    function updateIndicatorsInLiquidityMining(address account, address[] calldata lpTokens) external;

    /// @notice Delegates staked tokens by providing LP tokens and corresponding amounts.
    /// @param lpTokens An array of LP tokens to delegate.
    /// @param lpTokenAmounts An array of corresponding amounts of LP tokens to delegate.
    /// @dev This function allows the caller to delegate their staked tokens by providing the LP tokens and their corresponding amounts.
    /// @dev It requires that the length of `lpTokens` is equal to the length of `lpTokenAmounts`.
    /// @dev It reverts if either `lpTokens` or `lpTokenAmounts` arrays are empty.
    function delegatePwTokensToLiquidityMining(address[] calldata lpTokens, uint256[] calldata lpTokenAmounts) external;

    /// @notice Undelegates staked tokens by providing LP tokens and corresponding amounts.
    /// @param lpTokens An array of LP tokens to undelegate.
    /// @param lpTokenAmounts An array of corresponding amounts of LP tokens to undelegate.
    /// @dev This function allows the caller to undelegate their staked tokens by providing the LP tokens and their corresponding amounts.
    /// @dev It requires that the length of `lpTokens` is equal to the length of `lpTokenAmounts`.
    /// @dev It reverts if either `lpTokens` or `lpTokenAmounts` arrays are empty.
    /// @dev It reverts if the total staked token amount to undelegate is not greater than zero.
    function undelegatePwTokensFromLiquidityMining(
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external;
}

/// @title Interface responsible for viewing data from PowerToken smart contract.
interface IPowerTokenLens {

    struct PwTokenCooldown {
        // @dev The timestamp when the account can redeem Power Tokens
        uint256 endTimestamp;
        // @dev The amount of Power Tokens which can be redeemed without fee when the cooldown reaches `endTimestamp`
        uint256 pwTokenAmount;
    }

    struct UpdateStakedToken {
        address beneficiary;
        uint256 stakedTokenAmount;
    }

    /// @notice Gets the total supply of the Power Token.
    /// @dev Value is calculated in runtime using baseTotalSupply and internal exchange rate.
    /// @return Total supply of Power tokens, represented with 18 decimals
    function totalSupplyOfPwToken() external view returns (uint256);

    /// @notice Gets the balance of Power Tokens for a given account
    /// @param account account address for which the balance of Power Tokens is fetched
    /// @return Returns the amount of the Power Tokens owned by the `account`.
    function balanceOfPwToken(address account) external view returns (uint256);

    /// @notice Gets the delegated balance of the Power Tokens for a given account.
    /// Tokens are delegated from PowerToken to LiquidityMining smart contract (reponsible for rewards distribution).
    /// @param account account address for which the balance of delegated Power Tokens is checked
    /// @return  Returns the amount of the Power Tokens owned by the `account` and delegated to the LiquidityMining contracts.
    function balanceOfPwTokenDelegatedToLiquidityMining(address account) external view returns (uint256);

    /// @notice Gets the rate of the fee from the configuration. This fee is applied when the owner of Power Tokens wants to unstake them immediately.
    /// @dev Fee value represented in as a percentage with 18 decimals
    /// @return value, a percentage represented with 18 decimal
    function getPwTokenUnstakeFee() external view returns (uint256);

    /// @notice Gets the state of the active cooldown for the sender.
    /// @dev If PowerTokenCoolDown contains only zeros it represents no active cool down.
    /// Struct containing information on when the cooldown end and what is the quantity of the Power Tokens locked.
    /// @param account account address that owns Power Tokens in the cooldown
    /// @return Object PowerTokenCoolDown represents active cool down
    function getPwTokensInCooldown(address account) external view returns (PwTokenCooldown memory);

    /// @notice Gets the power token cool down time in seconds.
    /// @return uint256 cool down time in seconds
    function getPwTokenCooldownTime() external view returns (uint256);

    /// @notice Calculates the internal exchange rate between the Staked Token and total supply of a base amount
    /// @return Current exchange rate between the Staked Token and the total supply of a base amount, represented with 18 decimals.
    function getPwTokenExchangeRate() external view returns (uint256);

    /// @notice Gets the total supply base amount
    /// @return total supply base amount, represented with 18 decimals
    function getPwTokenTotalSupplyBase() external view returns (uint256);
}

/// @title Interface for interaction with PowerToken and LiquidityMining contracts.
interface IPowerTokenStakeService {
    /// @notice Stakes the specified amounts of LP tokens into the LiquidityMining contract.
    /// @dev This function allows the caller to stake their LP tokens on behalf of another address (`beneficiary`).
    /// @param beneficiary The address on behalf of which the LP tokens are being staked.
    /// @param lpTokens An array of LP token addresses to be staked.
    /// @param lpTokenAmounts An array of corresponding LP token amounts to be staked, represented with 18 decimals.
    /// @dev Both `lpTokens` and `lpTokenAmounts` arrays must have the same length.
    /// @dev The `beneficiary` address must not be the zero address.
    /// @dev The function ensures that the provided LP token addresses are valid and the amounts to be staked are greater than zero.
    /// @dev The function transfers the LP tokens from the caller's address to the LiquidityMining contract.
    /// @dev Finally, the function calls the `addLpTokens` function of the LiquidityMining contract to update the staked LP tokens.
    /// @dev Reverts if any of the requirements is not met or if the transfer of LP tokens fails.
    function stakeLpTokensToLiquidityMining(
        address beneficiary,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external;

    /// @notice Unstakes the specified amounts of LP tokens from the LiquidityMining contract and transfers them to the specified address.
    /// @param transferTo The address to which the unstaked LP tokens will be transferred.
    /// @param lpTokens An array of LP token addresses to be unstaked.
    /// @param lpTokenAmounts An array of corresponding LP token amounts to be unstaked, represented with 18 decimals.
    /// @dev Both `lpTokens` and `lpTokenAmounts` arrays must have the same length.
    /// @dev The function ensures that the provided LP token addresses are valid and the amounts to be unstaked are greater than zero.
    /// @dev The function calls the `removeLpTokens` function of the LiquidityMining contract to update the unstaked LP tokens.
    /// @dev Finally, the function transfers the unstaked LP tokens from the LiquidityMining contract to the specified address.
    /// @dev Reverts if any of the requirements is not met or if the transfer of LP tokens fails.
    function unstakeLpTokensFromLiquidityMining(
        address transferTo,
        address[] calldata lpTokens,
        uint256[] calldata lpTokenAmounts
    ) external;

    /// @notice Stakes the specified amount of IPOR tokens on behalf of the specified address.
    /// @param beneficiary The address on whose behalf the IPOR tokens will be staked.
    /// @param iporTokenAmount The amount of IPOR tokens to be staked, represented with 18 decimals.
    /// @dev The function ensures that the provided `beneficiary` address is valid and the `iporTokenAmount` is greater than zero.
    /// @dev The function calls the `addStakedToken` function of the PowerToken contract to update the staked IPOR tokens.
    /// @dev Finally, the function transfers the IPOR tokens from the sender to the PowerToken contract for staking.
    /// @dev Reverts if any of the requirements is not met or if the transfer of IPOR tokens fails.
    function stakeGovernanceTokenToPowerToken(address beneficiary, uint256 iporTokenAmount) external;

    /// @notice Stakes a specified amount of governance tokens and delegates power tokens to a specific beneficiary.
    /// @param beneficiary The address on whose behalf the governance tokens will be staked and power tokens will be delegated.
    /// @param governanceTokenAmount The amount of governance tokens to be staked, represented with 18 decimals.
    /// @param lpTokens An array of addresses representing the liquidity pool tokens.
    /// @param pwTokenAmounts An array of amounts of power tokens to be delegated corresponding to each liquidity pool token.
    /// @dev The function ensures that the `beneficiary` address is valid and the `governanceTokenAmount` is greater than zero.
    /// @dev The function also requires that the length of the `lpTokens` array is equal to the length of the `pwTokenAmounts` array.
    /// @dev For each liquidity pool token in `lpTokens`, the function creates an `UpdatePwToken` structure to be used for updating the power tokens in the Liquidity Mining contract.
    /// @dev The function checks if the total amount of power tokens to be delegated is less or equal to the amount of staked governance tokens.
    /// @dev The function calls the `addGovernanceTokenInternal` function of the PowerToken contract to update the staked governance tokens for the `beneficiary`.
    /// @dev The function transfers the governance tokens from the sender to the PowerToken contract for staking.
    /// @dev The function calls the `delegateInternal` function of the PowerToken contract to delegate power tokens to the `beneficiary`.
    /// @dev Finally, the function calls the `addPwTokensInternal` function of the Liquidity Mining contract to update the staked power tokens.
    /// @dev Reverts if any of the requirements is not met or if the transfer of governance tokens fails.
    function stakeGovernanceTokenToPowerTokenAndDelegate(
        address beneficiary,
        uint256 governanceTokenAmount,
        address[] calldata lpTokens,
        uint256[] calldata pwTokenAmounts
    ) external;

    /// @notice Unstakes the specified amount of IPOR tokens and transfers them to the specified address.
    /// @param transferTo The address to which the unstaked IPOR tokens will be transferred.
    /// @param iporTokenAmount The amount of IPOR tokens to be unstaked, represented with 18 decimals.
    /// @dev The function ensures that the `iporTokenAmount` is greater than zero.
    /// @dev The function calls the `removeStakedTokenWithFee` function of the PowerToken contract to remove the staked IPOR tokens.
    /// @dev Finally, the function transfers the corresponding staked token amount to the `transferTo` address.
    /// @dev Reverts if the `iporTokenAmount` is not greater than zero, or if the transfer of staked tokens fails.
    function unstakeGovernanceTokenFromPowerToken(address transferTo, uint256 iporTokenAmount) external;

    /// @notice Initiates a cooldown period for the specified amount of Power Tokens.
    /// @param pwTokenAmount The amount of Power Tokens to be put into cooldown, represented with 18 decimals.
    /// @dev The function ensures that the `pwTokenAmount` is greater than zero.
    /// @dev The function calls the `cooldown` function of the PowerToken contract to initiate the cooldown.
    /// @dev Reverts if the `pwTokenAmount` is not greater than zero.
    function pwTokenCooldown(uint256 pwTokenAmount) external;

    /// @notice Cancels the active cooldown for the sender.
    /// @dev The function calls the `cancelCooldown` function of the PowerToken contract to cancel the cooldown.
    function pwTokenCancelCooldown() external;

    /// @notice Redeems Power Tokens and transfers the corresponding Staked Tokens to the specified address.
    /// @dev The function calls the `redeem` function of the PowerToken contract to redeem Power Tokens.
    /// @param transferTo The address to which the Staked Tokens will be transferred.
    function redeemPwToken(address transferTo) external;
}

/// @title Technical interface for reading data related to the UUPS proxy pattern in Ipor Protocol.
interface IProxyImplementation {
    /// @notice Retrieves the address of the implementation contract for UUPS proxy.
    /// @return The address of the implementation contract.
    /// @dev The function returns the value stored in the implementation storage slot.
    function getImplementation() external view returns (address);
}

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

/// @title Storage ID's associated with the IPOR Protocol Router.
library StorageLib {
    uint256 constant STORAGE_SLOT_BASE = 1_000_000;

    // append only
    enum StorageId {
        /// @dev The address of the contract owner.
        Owner,
        AppointedOwner,
        Paused,
        PauseGuardian,
        ReentrancyStatus,
        RouterFunctionPaused,
        AmmSwapsLiquidators,
        AmmPoolsAppointedToRebalance,
        AmmPoolsParams
    }

    /// @notice Struct which contains owner address of IPOR Protocol Router.
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains appointed owner address of IPOR Protocol Router.
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Struct which contains reentrancy status of IPOR Protocol Router.
    struct ReentrancyStatusStorage {
        uint256 value;
    }

    /// @notice Struct which contains information about swap liquidators.
    /// @dev First key is an asset (pool), second key is an liquidator address in the asset pool,
    /// value is a flag to indicate whether account is a liquidator.
    /// True - account is a liquidator, False - account is not a liquidator.
    struct AmmSwapsLiquidatorsStorage {
        mapping(address => mapping(address => bool)) value;
    }

    /// @notice Struct which contains information about accounts appointed to rebalance.
    /// @dev first key - asset address, second key - account address which is allowed to rebalance in the asset pool,
    /// value - flag to indicate whether account is allowed to rebalance. True - allowed, False - not allowed.
    struct AmmPoolsAppointedToRebalanceStorage {
        mapping(address => mapping(address => bool)) value;
    }

    struct AmmPoolsParamsValue {
        /// @dev max liquidity pool balance in the asset pool, represented without 18 decimals
        uint32 maxLiquidityPoolBalance;
        /// @dev The threshold for auto-rebalancing the pool. Value represented without 18 decimals.
        /// Value represents multiplication of 1000.
        uint32 autoRebalanceThresholdInThousands;
        /// @dev asset management ratio, represented without 18 decimals, value represents percentage with 2 decimals
        /// 65% = 6500, 99,99% = 9999, this is a percentage which stay in Amm Treasury in opposite to Asset Management
        /// based on AMM Treasury balance (100%).
        uint16 ammTreasuryAndAssetManagementRatio;
    }

    /// @dev key - asset address, value - struct AmmOpenSwapParamsValue
    struct AmmPoolsParamsStorage {
        mapping(address => AmmPoolsParamsValue) value;
    }

    /// @dev key - function sig, value - 1 if function is paused, 0 if not
    struct RouterFunctionPausedStorage {
        mapping(bytes4 => uint256) value;
    }

    /// @notice Gets Ipor Protocol Router owner address.
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slot = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router appointed owner address.
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slot = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slot
        }
    }

    /// @notice Gets Ipor Protocol Router reentrancy status.
    function getReentrancyStatus() internal pure returns (ReentrancyStatusStorage storage reentrancyStatus) {
        uint256 slot = _getStorageSlot(StorageId.ReentrancyStatus);
        assembly {
            reentrancyStatus.slot := slot
        }
    }

    /// @notice Gets information if function is paused in Ipor Protocol Router.
    function getRouterFunctionPaused() internal pure returns (RouterFunctionPausedStorage storage paused) {
        uint256 slot = _getStorageSlot(StorageId.RouterFunctionPaused);
        assembly {
            paused.slot := slot
        }
    }

    /// @notice Gets point to pause guardian storage.
    function getPauseGuardianStorage() internal pure returns (mapping(address => bool) storage store) {
        uint256 slot = _getStorageSlot(StorageId.PauseGuardian);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to liquidators storage.
    /// @return store - point to liquidators storage.
    function getAmmSwapsLiquidatorsStorage() internal pure returns (AmmSwapsLiquidatorsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmSwapsLiquidators);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to accounts appointed to rebalance storage.
    /// @return store - point to accounts appointed to rebalance storage.
    function getAmmPoolsAppointedToRebalanceStorage()
        internal
        pure
        returns (AmmPoolsAppointedToRebalanceStorage storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsAppointedToRebalance);
        assembly {
            store.slot := slot
        }
    }

    /// @notice Gets point to amm pools params storage.
    /// @return store - point to amm pools params storage.
    function getAmmPoolsParamsStorage() internal pure returns (AmmPoolsParamsStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.AmmPoolsParams);
        assembly {
            store.slot := slot
        }
    }

    function _getStorageSlot(StorageId storageId) private pure returns (uint256 slot) {
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

library IporErrors {
    /// @notice Error when address is wrong
    error WrongAddress(string errorCode, address wrongAddress, string message);

    /// @notice Error when amount is wrong
    error WrongAmount(string errorCode, uint256 value);

    /// @notice Error when caller is not an ipor protocol router
    error CallerNotIporProtocolRouter(string errorCode, address caller);

    /// @notice Error when caller is not a pause guardian
    error CallerNotPauseGuardian(string errorCode, address caller);

    /// @notice Error when caller is not a AmmTreasury contract
    error CallerNotAmmTreasury(string errorCode, address caller);

    /// @notice Error when given direction is not supported
    error UnsupportedDirection(string errorCode, uint256 direction);

    /// @notice Error when given asset is not supported
    error UnsupportedAsset(string errorCode, address asset);

    /// @notice Error when given module is not supported
    error UnsupportedModule(string errorCode, address asset);

    /// @notice Error when given tenor is not supported
    error UnsupportedTenor(string errorCode, uint256 tenor);

    /// @notice Error when Input Asset total amount is too low
    error InputAssetTotalAmountTooLow(string errorCode, uint256 value);

    /// @dev Error appears if user/account doesn't have enough balance to open a swap with a specific totalAmount
    error InputAssetBalanceTooLow(string errorCode, address inputAsset, uint256 inputAssetBalance, uint256 totalAmount);

    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a pause guardian
    string public constant CALLER_NOT_PAUSE_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";

    /// @notice Risk indicators are expired
    string public constant RISK_INDICATORS_EXPIRED = "IPOR_019";

    /// @notice Signature is invalid for risk indicators
    string public constant RISK_INDICATORS_SIGNATURE_INVALID = "IPOR_020";

    /// @notice Input Asset used by user is not supported
    string public constant INPUT_ASSET_NOT_SUPPORTED = "IPOR_021";

    /// @notice Module Asset Management is not supported
    string public constant UNSUPPORTED_MODULE_ASSET_MANAGEMENT = "IPOR_022";
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

/// @title Interface responsible for reading the AMM Pools state and configuration.
interface IAmmPoolsLens {
    /// @dev A struct to represent a pool configuration.
    /// @param asset The address of the asset.
    /// @param decimals The number of decimal places the asset uses.
    /// @param ipToken The address of the ipToken associated with the asset.
    /// @param ammStorage The address of the AMM's storage contract.
    /// @param ammTreasury The address of the AMM's treasury contract.
    /// @param assetManagement The address of the asset management contract.
    struct AmmPoolsLensPoolConfiguration {
        address asset;
        uint256 decimals;
        address ipToken;
        address ammStorage;
        address ammTreasury;
        address assetManagement;
    }

    /// @notice Gets Ipor Orale address
    function iporOracle() external view returns (address);

    /// @notice Retrieves the configuration of a specific asset's pool.
    /// @param asset The address of the asset.
    /// @return PoolConfiguration The pool's configuration.
    function getAmmPoolsLensConfiguration(address asset) external view returns (AmmPoolsLensPoolConfiguration memory);

    /// @notice Calculates the ipToken exchange rate.
    /// @dev The exchange rate is a ratio between the Liquidity Pool Balance and the ipToken's total supply.
    /// @param asset The address of the asset.
    /// @return uint256 The ipToken exchange rate for the specific asset, represented in 18 decimals.
    function getIpTokenExchangeRate(address asset) external view returns (uint256);

    /// @notice Retrieves the AmmTreasury balance for a given asset.
    /// @param asset The address of the asset.
    /// @return IporTypes.AmmBalancesMemory The balance of the AMM Treasury.
    function getAmmBalance(address asset) external view returns (IporTypes.AmmBalancesMemory memory);
}

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

/// @title Ipor Protocol Router Pause Manager library
library PauseManager {
    /// @notice Emitted when new pause guardian is added
    /// @param guardians List of addresses of guardian
    event PauseGuardiansAdded(address[] indexed guardians);

    /// @notice Emitted when pause guardian is removed
    /// @param guardians List of addresses of guardian
    event PauseGuardiansRemoved(address[] indexed guardians);

    /// @notice Checks if account is Ipor Protocol Router pause guardian
    /// @param account Address of guardian
    /// @return true if account is Ipor Protocol Router pause guardian
    function isPauseGuardian(address account) internal view returns (bool) {
        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();
        return pauseGuardians[account];
    }

    /// @notice Adds Ipor Protocol Router pause guardian
    /// @param newGuardians Addresses of guardians
    function addPauseGuardians(address[] calldata newGuardians) internal {
        uint256 length = newGuardians.length;
        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[newGuardians[i]] = true;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansAdded(newGuardians);
    }

    /// @notice Removes Ipor Protocol Router pause guardian
    /// @param guardians Addresses of guardians
    function removePauseGuardians(address[] calldata guardians) internal {
        uint256 length = guardians.length;

        if (length == 0) {
            return;
        }

        mapping(address => bool) storage pauseGuardians = StorageLib.getPauseGuardianStorage();

        for (uint256 i; i < length; ) {
            pauseGuardians[guardians[i]] = false;
            unchecked {
                i++;
            }
        }
        emit PauseGuardiansRemoved(guardians);
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

/// @title Interface of the CloseSwap Lens.
interface IAmmCloseSwapLens {
    /// @notice Structure representing the configuration of the AmmCloseSwapService for a given pool (asset).
    struct AmmCloseSwapServicePoolConfiguration {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 decimals;
        /// @notice Amm Storage contract address
        address ammStorage;
        /// @notice Amm Treasury contract address
        address ammTreasury;
        /// @notice Asset Management contract address, for stETH is empty, because stETH doesn't have asset management module
        address assetManagement;
        /// @notice Spread address, for USDT, USDC, DAI is a spread router address, for stETH is a spread address
        address spread;
        /// @notice Unwinding Fee Rate for unwinding the swap, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeRate;
        /// @notice Unwinding Fee Rate for unwinding the swap, part earmarked for the treasury, represented in 18 decimals, 1e18 = 100%
        uint256 unwindingFeeTreasuryPortionRate;
        /// @notice Max number of swaps (per leg) that can be liquidated in one call, represented without decimals
        uint256 maxLengthOfLiquidatedSwapsPerLeg;
        /// @notice Time before maturity when the community is allowed to close the swap, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByCommunity;
        /// @notice Time before maturity then the swap owner can close it, for tenor 28 days, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyerTenor28days;
        /// @notice Time before maturity then the swap owner can close it, for tenor 60 days, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyerTenor60days;
        /// @notice Time before maturity then the swap owner can close it, for tenor 90 days, represented in seconds
        uint256 timeBeforeMaturityAllowedToCloseSwapByBuyerTenor90days;
        /// @notice Min liquidation threshold allowing community to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByCommunity;
        /// @notice Min liquidation threshold allowing the owner to close the swap ahead of maturity, represented in 18 decimals
        uint256 minLiquidationThresholdToCloseBeforeMaturityByBuyer;
        /// @notice Min leverage of the virtual swap used in unwinding, represented in 18 decimals
        uint256 minLeverage;
        /// @notice Time after open swap when it is allowed to close swap with unwinding, for tenor 28 days, represented in seconds
        uint256 timeAfterOpenAllowedToCloseSwapWithUnwindingTenor28days;
        /// @notice Time after open swap when it is allowed to close swap with unwinding, for tenor 60 days, represented in seconds
        uint256 timeAfterOpenAllowedToCloseSwapWithUnwindingTenor60days;
        /// @notice Time after open swap when it is allowed to close swap with unwinding, for tenor 90 days, represented in seconds
        uint256 timeAfterOpenAllowedToCloseSwapWithUnwindingTenor90days;
    }

    /// @notice Returns the configuration of the AmmCloseSwapService for a given pool (asset).
    /// @param asset asset address
    /// @return AmmCloseSwapServicePoolConfiguration struct representing the configuration of the AmmCloseSwapService for a given pool (asset).
    function getAmmCloseSwapServicePoolConfiguration(
        address asset
    ) external view returns (AmmCloseSwapServicePoolConfiguration memory);

    /// @notice Returns the closing swap details for a given swap and closing timestamp.
    /// @param asset asset address
    /// @param account account address for which are returned closing swap details, for example closableStatus depends on the account
    /// @param direction swap direction
    /// @param swapId swap id
    /// @param closeTimestamp closing timestamp
    /// @param riskIndicatorsInput risk indicators input
    /// @return closingSwapDetails struct representing the closing swap details for a given swap and closing timestamp.
    function getClosingSwapDetails(
        address asset,
        address account,
        AmmTypes.SwapDirection direction,
        uint256 swapId,
        uint256 closeTimestamp,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    ) external view returns (AmmTypes.ClosingSwapDetails memory closingSwapDetails);
}

/// @title Types used in interfaces strictly related to AMM (Automated Market Maker).
/// @dev Used by IAmmTreasury and IAmmStorage interfaces.
library AmmTypes {
    /// @notice Struct describing AMM Pool's core addresses.
    struct AmmPoolCoreModel {
        /// @notice asset address
        address asset;
        /// @notice asset decimals
        uint256 assetDecimals;
        /// @notice ipToken address associated to the asset
        address ipToken;
        /// @notice AMM Storage address
        address ammStorage;
        /// @notice AMM Treasury address
        address ammTreasury;
        /// @notice Asset Management address
        address assetManagement;
        /// @notice IPOR Oracle address
        address iporOracle;
    }

    /// @notice Structure which represents Swap's data that will be saved in the storage.
    /// Refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps for more information.
    struct NewSwap {
        /// @notice Account / trader who opens the Swap
        address buyer;
        /// @notice Epoch timestamp of when position was opened by the trader.
        uint256 openTimestamp;
        /// @notice Swap's collateral amount.
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount.
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Quantity of Interest Bearing Token (IBT) at moment when position was opened.
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened.
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit is retained when the swap is opened. It is then paid back to agent who closes the derivative at maturity.
        /// It can be both trader or community member. Trader receives the deposit back when he chooses to close the derivative before maturity.
        /// @dev value represented WITHOUT 18 decimals for USDT, USDC, DAI pool. Notice! Value represented in 6 decimals for stETH pool.
        /// @dev Example value in 6 decimals: 25000000 (in 6 decimals) = 25 stETH = 25.000000
        uint256 liquidationDepositAmount;
        /// @notice Opening fee amount part which is allocated in Liquidity Pool Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeLPAmount;
        /// @notice Opening fee amount part which is allocated in Treasury Balance. This fee is calculated as a rate of the swap's collateral.
        /// @dev value represented in 18 decimals
        uint256 openingFeeTreasuryAmount;
        /// @notice Swap's tenor, 0 - 28 days, 1 - 60 days or 2 - 90 days
        IporTypes.SwapTenor tenor;
    }

    /// @notice Struct representing swap item, used for listing and in internal calculations
    struct Swap {
        /// @notice Swap's unique ID
        uint256 id;
        /// @notice Swap's buyer
        address buyer;
        /// @notice Swap opening epoch timestamp
        uint256 openTimestamp;
        /// @notice Swap's tenor
        IporTypes.SwapTenor tenor;
        /// @notice Index position of this Swap in an array of swaps' identification associated to swap buyer
        /// @dev Field used for gas optimization purposes, it allows for quick removal by id in the array.
        /// During removal the last item in the array is switched with the one that just has been removed.
        uint256 idsIndex;
        /// @notice Swap's collateral
        /// @dev value represented in 18 decimals
        uint256 collateral;
        /// @notice Swap's notional amount
        /// @dev value represented in 18 decimals
        uint256 notional;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened
        /// @dev value represented in 18 decimals
        uint256 fixedInterestRate;
        /// @notice Liquidation deposit amount
        /// @dev value represented in 18 decimals
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        IporTypes.SwapState state;
    }

    /// @notice Struct representing amounts related to Swap that is presently being opened.
    /// @dev all values represented in 18 decimals
    struct OpenSwapAmount {
        /// @notice Total Amount of asset that is sent from buyer to AmmTreasury when opening swap.
        uint256 totalAmount;
        /// @notice Swap's collateral
        uint256 collateral;
        /// @notice Swap's notional
        uint256 notional;
        /// @notice Opening Fee - part allocated as a profit of the Liquidity Pool
        uint256 openingFeeLPAmount;
        /// @notice  Part of the fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        /// @notice Opening Fee - part allocated in Treasury balance. Part of the fee set asside for subsidising the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 openingFeeTreasuryAmount;
        /// @notice Fee set aside for subsidizing the oracle that publishes IPOR rate. Flat fee set by the DAO.
        uint256 iporPublicationFee;
        /// @notice Liquidation deposit is retained when the swap is opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
    }

    /// @notice Structure describes one swap processed by closeSwaps method, information about swap ID and flag if this swap was closed during execution closeSwaps method.
    struct IporSwapClosingResult {
        /// @notice Swap ID
        uint256 swapId;
        /// @notice Flag describe if swap was closed during this execution
        bool closed;
    }

    /// @notice Technical structure used for storing information about amounts used during redeeming assets from liquidity pool.
    struct RedeemAmount {
        /// @notice Asset amount represented in 18 decimals
        /// @dev Asset amount is a sum of wadRedeemFee and wadRedeemAmount
        uint256 wadAssetAmount;
        /// @notice Redeemed amount represented in decimals of asset
        uint256 redeemAmount;
        /// @notice Redeem fee value represented in 18 decimals
        uint256 wadRedeemFee;
        /// @notice Redeem amount represented in 18 decimals
        uint256 wadRedeemAmount;
    }

    struct UnwindParams {
        /// @notice Risk Indicators Inputs signer
        address messageSigner;
        /// @notice Spread Router contract address
        address spreadRouter;
        address ammStorage;
        address ammTreasury;
        SwapDirection direction;
        uint256 closeTimestamp;
        int256 swapPnlValueToDate;
        uint256 indexValue;
        Swap swap;
        IAmmCloseSwapLens.AmmCloseSwapServicePoolConfiguration poolCfg;
        CloseSwapRiskIndicatorsInput riskIndicatorsInputs;
    }

    /// @notice Swap direction (long = Pay Fixed and Receive a Floating or short = receive fixed and pay a floating)
    enum SwapDirection {
        /// @notice When taking the "long" position the trader will pay a fixed rate and receive a floating rate.
        /// for more information refer to the documentation https://ipor-labs.gitbook.io/ipor-labs/automated-market-maker/ipor-swaps
        PAY_FIXED_RECEIVE_FLOATING,
        /// @notice When taking the "short" position the trader will pay a floating rate and receive a fixed rate.
        PAY_FLOATING_RECEIVE_FIXED
    }
    /// @notice List of closable statuses for a given swap
    /// @dev Closable status is a one of the following values:
    /// 0 - Swap is closable
    /// 1 - Swap is already closed
    /// 2 - Swap state required Buyer or Liquidator to close. Sender is not Buyer nor Liquidator.
    /// 3 - Cannot close swap, closing is too early for Community
    /// 4 - Cannot close swap with unwind because action is too early from the moment when swap was opened, validation based on Close Service configuration
    enum SwapClosableStatus {
        SWAP_IS_CLOSABLE,
        SWAP_ALREADY_CLOSED,
        SWAP_REQUIRED_BUYER_OR_LIQUIDATOR_TO_CLOSE,
        SWAP_CANNOT_CLOSE_CLOSING_TOO_EARLY_FOR_COMMUNITY,
        SWAP_CANNOT_CLOSE_WITH_UNWIND_ACTION_IS_TOO_EARLY
    }

    /// @notice Collection of swap attributes connected with IPOR Index and swap itself.
    /// @dev all values are in 18 decimals
    struct IporSwapIndicator {
        /// @notice IPOR Index value at the time of swap opening
        uint256 iporIndexValue;
        /// @notice IPOR Interest Bearing Token (IBT) price at the time of swap opening
        uint256 ibtPrice;
        /// @notice Swap's notional denominated in IBT
        uint256 ibtQuantity;
        /// @notice Fixed interest rate at which the position has been opened,
        /// it is quote from spread documentation
        uint256 fixedInterestRate;
    }

    /// @notice Risk indicators calculated for swap opening
    struct OpenSwapRiskIndicators {
        /// @notice Maximum collateral ratio in general
        uint256 maxCollateralRatio;
        /// @notice Maximum collateral ratio for a given leg
        uint256 maxCollateralRatioPerLeg;
        /// @notice Maximum leverage for a given leg
        uint256 maxLeveragePerLeg;
        /// @notice Base Spread for a given leg (without demand part)
        int256 baseSpreadPerLeg;
        /// @notice Fixed rate cap
        uint256 fixedRateCapPerLeg;
        /// @notice Demand spread factor used to calculate demand spread
        uint256 demandSpreadFactor;
    }

    /// @notice Risk indicators calculated for swap opening
    struct RiskIndicatorsInputs {
        /// @notice Maximum collateral ratio in general
        uint256 maxCollateralRatio;
        /// @notice Maximum collateral ratio for a given leg
        uint256 maxCollateralRatioPerLeg;
        /// @notice Maximum leverage for a given leg
        uint256 maxLeveragePerLeg;
        /// @notice Base Spread for a given leg (without demand part)
        int256 baseSpreadPerLeg;
        /// @notice Fixed rate cap
        uint256 fixedRateCapPerLeg;
        /// @notice Demand spread factor used to calculate demand spread
        uint256 demandSpreadFactor;
        /// @notice expiration date in seconds
        uint256 expiration;
        /// @notice signature of data (maxCollateralRatio, maxCollateralRatioPerLeg,maxLeveragePerLeg,baseSpreadPerLeg,fixedRateCapPerLeg,demandSpreadFactor,expiration,asset,tenor,direction)
        /// asset - address
        /// tenor - uint256
        /// direction - uint256
        bytes signature;
    }

    struct CloseSwapRiskIndicatorsInput {
        RiskIndicatorsInputs payFixed;
        RiskIndicatorsInputs receiveFixed;
    }

    /// @notice Structure containing information about swap's closing status, unwind values and PnL for a given swap and time.
    struct ClosingSwapDetails {
        /// @notice Swap's closing status
        AmmTypes.SwapClosableStatus closableStatus;
        /// @notice Flag indicating if swap unwind is required
        bool swapUnwindRequired;
        /// @notice Swap's unwind PnL Value, part of PnL corresponded to virtual swap (unwinded swap), represented in 18 decimals
        int256 swapUnwindPnlValue;
        /// @notice Unwind opening fee amount it is a sum of `swapUnwindFeeLPAmount` and `swapUnwindFeeTreasuryAmount`
        uint256 swapUnwindOpeningFeeAmount;
        /// @notice Part of unwind opening fee allocated as a profit of the Liquidity Pool
        uint256 swapUnwindFeeLPAmount;
        /// @notice Part of unwind opening fee allocated in Treasury Balance
        uint256 swapUnwindFeeTreasuryAmount;
        /// @notice Final Profit and Loss which takes into account the swap unwind and limits the PnL to the collateral amount. Represented in 18 decimals.
        int256 pnlValue;
    }
}

/// @title Ipor Protocol Router Owner Manager library
library OwnerManager {
    /// @notice Emitted when account is appointed to transfer ownership
    /// @param appointedOwner Address of appointed owner
    event AppointedToTransferOwnership(address indexed appointedOwner);

    /// @notice Emitted when ownership is transferred
    /// @param previousOwner Address of previous owner
    /// @param newOwner Address of new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Gets the current owner of Ipor Protocol Router
    function getOwner() internal view returns (address) {
        return StorageLib.getOwner().owner;
    }

    /// @notice Oppoint account to transfer ownership
    /// @param newAppointedOwner Address of appointed owner
    function appointToOwnership(address newAppointedOwner) internal {
        require(newAppointedOwner != address(0), IporErrors.WRONG_ADDRESS);
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = newAppointedOwner;
        emit AppointedToTransferOwnership(newAppointedOwner);
    }

    /// @notice Confirm appointment to ownership
    /// @dev This is real transfer ownership in second step by appointed account
    function confirmAppointmentToOwnership() internal {
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
        transferOwnership(msg.sender);
    }

    /// @notice Renounce ownership
    function renounceOwnership() internal {
        transferOwnership(address(0));
        StorageLib.AppointedOwnerStorage storage appointedOwnerStorage = StorageLib.getAppointedOwner();
        appointedOwnerStorage.appointedOwner = address(0);
    }

    /// @notice Immediately transfers ownership
    function transferOwnership(address newOwner) internal {
        StorageLib.OwnerStorage storage ownerStorage = StorageLib.getOwner();
        address oldOwner = ownerStorage.owner;
        ownerStorage.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title Interface of the service allowing to close swaps in stETH AMM.
interface IAmmCloseSwapServiceWstEth {
    /// @notice Closes batch of wstETH swaps on both legs.
    /// @param beneficiary account - receiver of liquidation deposit.
    /// @param payFixedSwapIds array of pay fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive fixed swap IDs.
    /// @dev Swap PnL is always transferred to the swaps's owner.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function closeSwapsWstEth(
        address beneficiary,
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );

    /// @notice Closes batch of wstETH swaps on both legs in emergency mode by Owner of Ipor Protocol Router.
    /// @param payFixedSwapIds array of pay-fixed swap IDs.
    /// @param receiveFixedSwapIds array of receive-fixed swap IDs.
    /// @return closedPayFixedSwaps array of closed pay-fixed swaps.
    /// @return closedReceiveFixedSwaps array of closed receive-fixed swaps.
    function emergencyCloseSwapsWstEth(
        uint256[] memory payFixedSwapIds,
        uint256[] memory receiveFixedSwapIds,
        AmmTypes.CloseSwapRiskIndicatorsInput calldata riskIndicatorsInput
    )
        external
        returns (
            AmmTypes.IporSwapClosingResult[] memory closedPayFixedSwaps,
            AmmTypes.IporSwapClosingResult[] memory closedReceiveFixedSwaps
        );
}

/// @title Interface of the service allowing to open new swaps.
interface IAmmOpenSwapServiceWstEth {
    /// @notice It opens a swap for wstETH pay-fixed receive-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed28daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for wstETH pay-fixed receive-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed60daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for wstETH pay-fixed receive-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapPayFixed90daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for wstETH receive-fixed pay-floating with a tenor of 28 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed28daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for stETH receive-fixed pay-floating with a tenor of 60 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed60daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);

    /// @notice It opens a swap for wstETH receive-fixed pay-floating with a tenor of 90 days.
    /// @param beneficiary address of the owner of the swap.
    /// @param inputAsset address of the entered asset used by sender to open the swap which is accounted in underlying asset.
    /// @param inputAssetTotalAmount total amount of input asset used by sender to open the swap, represented in decimals of the input asset.
    /// @param acceptableFixedInterestRate acceptable fixed interest rate, represented in 18 decimals.
    /// @param leverage swap leverage, represented in 18 decimals.
    /// @return swapId ID of the opened swap.
    /// @dev The address `beneficiary` is the swap's owner. Sender pays for the swap.
    function openSwapReceiveFixed90daysWstEth(
        address beneficiary,
        address inputAsset,
        uint256 inputAssetTotalAmount,
        uint256 acceptableFixedInterestRate,
        uint256 leverage,
        AmmTypes.RiskIndicatorsInputs calldata riskIndicatorsInputs
    ) external returns (uint256);
}

/// @title AmmSwapsLens interface responsible for reading data related with swaps.
interface IAmmSwapsLens {
    /// @notice IPOR Swap structure.
    struct IporSwap {
        /// @notice Swap's ID.
        uint256 id;
        /// @notice Swap's asset (stablecoin / underlying token)
        address asset;
        /// @notice Swap's buyer address
        address buyer;
        /// @notice Swap's collateral, represented in 18 decimals.
        uint256 collateral;
        /// @notice Notional amount, represented in 18 decimals.
        uint256 notional;
        /// @notice Swap's leverage, represented in 18 decimals.
        uint256 leverage;
        /// @notice Swap's direction
        /// @dev 0 - Pay Fixed-Receive Floating, 1 - Receive Fixed - Pay Floading
        uint256 direction;
        /// @notice Swap's notional amount denominated in the Interest Bearing Token (IBT)
        /// @dev value represented in 18 decimals
        uint256 ibtQuantity;
        /// @notice Fixed interest rate.
        uint256 fixedInterestRate;
        /// @notice Current PnL value (Profit and Loss Value), represented in 18 decimals.
        int256 pnlValue;
        /// @notice Moment when swap was opened.
        uint256 openTimestamp;
        /// @notice Moment when swap achieve its maturity.
        uint256 endTimestamp;
        /// @notice Liquidation deposit value on day when swap was opened. Value represented in 18 decimals.
        uint256 liquidationDepositAmount;
        /// @notice State of the swap
        /// @dev 0 - INACTIVE, 1 - ACTIVE
        uint256 state;
    }

    /// @notice Lens Configuration structure for AmmSwapsLens for a given asset (ppol)
    struct SwapLensPoolConfiguration {
        /// @notice Asset address
        address asset;
        /// @notice Address of the AMM (Automated Market Maker) storage contract
        address ammStorage;
        /// @notice Address of the AMM Treasury contract
        address ammTreasury;
        /// @notice Spread module
        address spread;
    }

    /// @notice Gets pool configuration for AmmSwapsLens
    /// @param asset asset address
    /// @return SwapLensPoolConfiguration pool configuration
    function getSwapLensPoolConfiguration(address asset) external view returns (SwapLensPoolConfiguration memory);

    /// @notice Gets active swaps for a given asset sender address (aka buyer).
    /// @param asset asset address
    /// @param offset offset for paging
    /// @param chunkSize page size for paging
    /// @return totalCount total number of sender's active swaps in AmmTreasury
    /// @return swaps list of active sender's swaps
    function getSwaps(
        address asset,
        address account,
        uint256 offset,
        uint256 chunkSize
    ) external view returns (uint256 totalCount, IporSwap[] memory swaps);

    /// @notice Gets the swap's PnL (Profit and Loss) for a pay-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return pnlValue PnL for a pay fixed swap
    function getPnlPayFixed(address asset, uint256 swapId) external view returns (int256 pnlValue);

    /// @notice Gets the swap's PnL (Profit and Loss) for a receive-fixed, given asset and swap ID.
    /// @param asset asset address
    /// @param swapId swap ID
    /// @return pnlValue PnL for a receive fixed swap
    function getPnlReceiveFixed(address asset, uint256 swapId) external view returns (int256 pnlValue);

    /// @notice Gets the balances structure required to open a swap.
    /// @param asset The address of the asset.
    /// @return AmmBalancesForOpenSwapMemory The balances required for opening a swap.
    function getBalancesForOpenSwap(
        address asset
    ) external view returns (IporTypes.AmmBalancesForOpenSwapMemory memory);

    /// @notice Gets the SOAP value for a given asset.
    /// @param asset The address of the asset.
    /// @return soapPayFixed SOAP value for pay fixed swaps.
    /// @return soapReceiveFixed SOAP value for receive fixed swaps.
    /// @return soap SOAP value which is a sum of soapPayFixed and soapReceiveFixed.
    function getSoap(address asset) external view returns (int256 soapPayFixed, int256 soapReceiveFixed, int256 soap);

    /// @notice Gets the offered rate value for a given asset, tenor and notional.
    /// @param asset The address of the asset.
    /// @param tenor The duration of the swap.
    /// @param notional The notional amount of the swap, represented in 18 decimals.
    /// @param payFixedRiskIndicatorsInputs The risk indicators inputs for pay fixed swaps.
    /// @param receiveFixedRiskIndicatorsInputs The risk indicators inputs for receive fixed swaps.
    /// @return offeredRatePayFixed The offered rate for pay fixed swaps.
    /// @return offeredRateReceiveFixed The offered rate for receive fixed swaps.
    function getOfferedRate(
        address asset,
        IporTypes.SwapTenor tenor,
        uint256 notional,
        AmmTypes.RiskIndicatorsInputs calldata payFixedRiskIndicatorsInputs,
        AmmTypes.RiskIndicatorsInputs calldata receiveFixedRiskIndicatorsInputs
    ) external view returns (uint256 offeredRatePayFixed, uint256 offeredRateReceiveFixed);
}

/// @title Smart contract responsible for managing access to administrative functions in IporProtocolRouter
contract AccessControl {
    /// @dev Reentrancy - flag when thread is left method
    uint256 internal constant _NOT_ENTERED = 1;
    /// @dev Reentrancy - flag when thread is entered to method
    uint256 internal constant _ENTERED = 2;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Checks if sender is owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @notice Checks if sender is appointed owner
    modifier onlyAppointedOwner() {
        require(StorageLib.getAppointedOwner().appointedOwner == msg.sender, IporErrors.SENDER_NOT_APPOINTED_OWNER);
        _;
    }

    /// @notice Checks if sender is pause guardian
    modifier onlyPauseGuardian() {
        require(PauseManager.isPauseGuardian(msg.sender), IporErrors.CALLER_NOT_PAUSE_GUARDIAN);
        _;
    }

    /// @notice Steps before and after method execution to prevent reentrancy
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /// @notice Gets IPOR Protocol Owner on Router
    /// @return IPOR Protocol Owner address
    function owner() external view returns (address) {
        return OwnerManager.getOwner();
    }

    /// @notice Appoint new account to ownership
    /// @param appointedOwner New appointed owner address
    function appointToOwnership(address appointedOwner) public onlyOwner {
        OwnerManager.appointToOwnership(appointedOwner);
    }

    /// @notice Confirm appointed ownership
    function confirmAppointmentToOwnership() public onlyAppointedOwner {
        OwnerManager.confirmAppointmentToOwnership();
    }

    /// @notice Renounce ownership
    function renounceOwnership() public virtual onlyOwner {
        OwnerManager.renounceOwnership();
    }

    /// @notice Checks if function is paused
    /// @param functionSig Function signature
    /// @return 1 if function is paused, 0 otherwise
    function paused(bytes4 functionSig) external view returns (uint256) {
        return StorageLib.getRouterFunctionPaused().value[functionSig];
    }

    /// @notice Pauses list of functions in IporProtocolRouter
    /// @dev Can be called only by pause guardian
    function pause(bytes4[] calldata functionSigs) external onlyPauseGuardian {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 1;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Unpauses list of functions in IporProtocolRouter
    /// @dev Can be called only by Owner of Ipor Protocol Router
    function unpause(bytes4[] calldata functionSigs) external onlyOwner {
        uint256 len = functionSigs.length;
        for (uint256 i; i < len; ) {
            StorageLib.getRouterFunctionPaused().value[functionSigs[i]] = 0;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Checks if address is pause guardian
    /// @param account Pause guardian address
    /// @return true if address is pause guardian, false otherwise
    function isPauseGuardian(address account) external view returns (bool) {
        return PauseManager.isPauseGuardian(account);
    }

    /// @notice Adds new pause guardians
    /// @param guardians List of new pause guardians addresses
    function addPauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.addPauseGuardians(guardians);
    }

    /// @notice Removes pause guardian
    /// @param guardians List of pause guardians addresses
    function removePauseGuardians(address[] calldata guardians) external onlyOwner {
        PauseManager.removePauseGuardians(guardians);
    }

    function _checkFunctionSigAndIsNotPause(bytes4 functionSig, bytes4 expectedSig) internal view returns (bool) {
        if (functionSig == expectedSig) {
            require(StorageLib.getRouterFunctionPaused().value[functionSig] == 0, IporErrors.METHOD_PAUSED);
            return true;
        }
        return false;
    }

    function _onlyOwner() internal view {
        require(StorageLib.getOwner().owner == msg.sender, IporErrors.CALLER_NOT_OWNER);
    }

    function _nonReentrantBefore() internal {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(StorageLib.getReentrancyStatus().value != _ENTERED, IporErrors.REENTRANCY);

        // Any calls to nonReentrant after this point will fail
        StorageLib.getReentrancyStatus().value = _ENTERED;
    }

    function _nonReentrantAfter() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        if (StorageLib.getReentrancyStatus().value == _ENTERED) {
            StorageLib.getReentrancyStatus().value = _NOT_ENTERED;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// @title Entry point for IPOR protocol
abstract contract IporProtocolRouterAbstract is UUPSUpgradeable, AccessControl, IProxyImplementation {
    using Address for address;
    using IporContractValidator for address;

    uint256 private constant SINGLE_OPERATION = 0;
    uint256 private constant BATCH_OPERATION = 1;

    fallback(bytes calldata input) external payable returns (bytes memory) {
        return _delegate(_getRouterImplementation(msg.sig, SINGLE_OPERATION));
    }

    function initialize(bool pausedInput) external initializer {
        __UUPSUpgradeable_init();
        OwnerManager.transferOwnership(msg.sender);
        StorageLib.getReentrancyStatus().value = _NOT_ENTERED;
    }

    /// @notice Gets the implementation of the router
    /// @return implementation address
    function getImplementation() external view override returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @notice Allows to execute batch of calls in one transaction using IPOR protocol business methods
    /// @param calls array of encoded calls
    function batchExecutor(bytes[] calldata calls) external payable nonReentrant returns (bytes[] memory) {
        uint256 length = calls.length;
        address implementation;
        bytes[] memory returnData = new bytes[](length);

        for (uint256 i; i != length; ) {
            implementation = _getRouterImplementation(bytes4(calls[i][:4]), BATCH_OPERATION);
            returnData[i] = implementation.functionDelegateCall(calls[i]);
            unchecked {
                ++i;
            }
        }

        _returnBackRemainingEth();

        return returnData;
    }

    receive() external payable {}

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal virtual returns (address);

    function _delegate(address implementation) private returns (bytes memory) {
        bytes memory returnData = implementation.functionDelegateCall(msg.data);
        _returnBackRemainingEth();
        _nonReentrantAfter();
        return returnData;
    }

    function _returnBackRemainingEth() private {
        uint256 routerEthBalance = address(this).balance;

        if (routerEthBalance > 0) {
            /// @dev if view method then return back ETH is skipped
            if (StorageLib.getReentrancyStatus().value == _ENTERED) {
                (bool success, ) = msg.sender.call{value: routerEthBalance}("");

                if (!success) {
                    revert(IporErrors.ROUTER_RETURN_BACK_ETH_FAILED);
                }
            }
        }
    }

    //solhint-disable no-empty-blocks
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}

/// @title Entry point for IPOR protocol
contract IporProtocolRouterArbitrum is IporProtocolRouterAbstract {
    using Address for address;
    using IporContractValidator for address;

    address public immutable ammSwapsLens;
    address public immutable ammOpenSwapServiceWstEth;
    address public immutable ammCloseSwapServiceWstEth;
    address public immutable ammCloseSwapLens;
    address public immutable ammGovernanceService;
    address public immutable liquidityMiningLens;
    address public immutable powerTokenLens;
    address public immutable flowService;
    address public immutable stakeService;
    address public immutable ammPoolsServiceWstEth;
    address public immutable ammPoolsLensWstEth;

    struct DeployedContractsArbitrum {
        address ammSwapsLens;
        address ammOpenSwapServiceWstEth;
        address ammCloseSwapServiceWstEth;
        address ammCloseSwapLens;
        address ammGovernanceService;
        address liquidityMiningLens;
        address powerTokenLens;
        address flowService;
        address stakeService;
        address ammPoolsServiceWstEth;
        address ammPoolsLensWstEth;
    }

    constructor(DeployedContractsArbitrum memory deployedContracts) {
        ammSwapsLens = deployedContracts.ammSwapsLens.checkAddress();
        ammOpenSwapServiceWstEth = deployedContracts.ammOpenSwapServiceWstEth.checkAddress();
        ammCloseSwapServiceWstEth = deployedContracts.ammCloseSwapServiceWstEth.checkAddress();
        ammCloseSwapLens = deployedContracts.ammCloseSwapLens.checkAddress();
        ammGovernanceService = deployedContracts.ammGovernanceService.checkAddress();
        liquidityMiningLens = deployedContracts.liquidityMiningLens.checkAddress();
        powerTokenLens = deployedContracts.powerTokenLens.checkAddress();
        flowService = deployedContracts.flowService.checkAddress();
        stakeService = deployedContracts.stakeService.checkAddress();
        ammPoolsServiceWstEth = deployedContracts.ammPoolsServiceWstEth.checkAddress();
        ammPoolsLensWstEth = deployedContracts.ammPoolsLensWstEth.checkAddress();

        _disableInitializers();
    }

    /// @notice Gets the Router configuration
    /// @return DeployedContracts struct
    function getConfiguration() external view returns (DeployedContractsArbitrum memory) {
        return
            DeployedContractsArbitrum({
                ammSwapsLens: ammSwapsLens,
                ammOpenSwapServiceWstEth: ammOpenSwapServiceWstEth,
                ammCloseSwapLens: ammCloseSwapLens,
                ammCloseSwapServiceWstEth: ammCloseSwapServiceWstEth,
                ammGovernanceService: ammGovernanceService,
                liquidityMiningLens: liquidityMiningLens,
                powerTokenLens: powerTokenLens,
                flowService: flowService,
                stakeService: stakeService,
                ammPoolsServiceWstEth: ammPoolsServiceWstEth,
                ammPoolsLensWstEth: ammPoolsLensWstEth
            });
    }

    function _getRouterImplementation(bytes4 sig, uint256 batchOperation) internal override returns (address) {
        if (
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed28daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed60daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapPayFixed90daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed28daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed60daysWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmOpenSwapServiceWstEth.openSwapReceiveFixed90daysWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammOpenSwapServiceWstEth;
        } else if (_checkFunctionSigAndIsNotPause(sig, IAmmCloseSwapServiceWstEth.closeSwapsWstEth.selector)) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammCloseSwapServiceWstEth;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.provideLiquidityWstEth.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IAmmPoolsServiceWstEth.redeemFromAmmPoolWstEth.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammPoolsServiceWstEth;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeLpTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.unstakeLpTokensFromLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.stakeGovernanceTokenToPowerToken.selector) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenStakeService.stakeGovernanceTokenToPowerTokenAndDelegate.selector
            ) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenStakeService.unstakeGovernanceTokenFromPowerToken.selector
            ) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.pwTokenCancelCooldown.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenStakeService.redeemPwToken.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return stakeService;
        } else if (
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.delegatePwTokensToLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.updateIndicatorsInLiquidityMining.selector) ||
            _checkFunctionSigAndIsNotPause(
                sig,
                IPowerTokenFlowsService.undelegatePwTokensFromLiquidityMining.selector
            ) ||
            _checkFunctionSigAndIsNotPause(sig, IPowerTokenFlowsService.claimRewardsFromLiquidityMining.selector)
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return flowService;
        } else if (
            sig == IAmmGovernanceService.transferToTreasury.selector ||
            sig == IAmmGovernanceService.transferToCharlieTreasury.selector
        ) {
            if (batchOperation == 0) {
                _nonReentrantBefore();
            }
            return ammGovernanceService;
        } else if (
            sig == IAmmGovernanceService.addSwapLiquidator.selector ||
            sig == IAmmGovernanceService.removeSwapLiquidator.selector ||
            sig == IAmmGovernanceService.addAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.removeAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceService.depositToAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawFromAssetManagement.selector ||
            sig == IAmmGovernanceService.withdrawAllFromAssetManagement.selector ||
            sig == IAmmGovernanceService.setAmmPoolsParams.selector
        ) {
            _onlyOwner();
            return ammGovernanceService;
        } else if (sig == IAmmCloseSwapServiceWstEth.emergencyCloseSwapsWstEth.selector) {
            _onlyOwner();
            return ammCloseSwapServiceWstEth;
        } else if (
            sig == IAmmGovernanceLens.isSwapLiquidator.selector ||
            sig == IAmmGovernanceLens.isAppointedToRebalanceInAmm.selector ||
            sig == IAmmGovernanceLens.getAmmPoolsParams.selector ||
            sig == IAmmGovernanceLens.getAmmGovernancePoolConfiguration.selector
        ) {
            return ammGovernanceService;
        } else if (
            sig == IAmmSwapsLens.getSwaps.selector ||
            sig == IAmmSwapsLens.getPnlPayFixed.selector ||
            sig == IAmmSwapsLens.getPnlReceiveFixed.selector ||
            sig == IAmmSwapsLens.getBalancesForOpenSwap.selector ||
            sig == IAmmSwapsLens.getSoap.selector ||
            sig == IAmmSwapsLens.getOfferedRate.selector ||
            sig == IAmmSwapsLens.getSwapLensPoolConfiguration.selector
        ) {
            return ammSwapsLens;
        } else if (
            sig == ILiquidityMiningLens.balanceOfLpTokensStakedInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.balanceOfPowerTokensDelegatedToLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccruedRewardsInLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getGlobalIndicatorsFromLiquidityMining.selector ||
            sig == ILiquidityMiningLens.getAccountRewardsInLiquidityMining.selector
        ) {
            return liquidityMiningLens;
        } else if (
            sig == IPowerTokenLens.totalSupplyOfPwToken.selector ||
            sig == IPowerTokenLens.balanceOfPwToken.selector ||
            sig == IPowerTokenLens.balanceOfPwTokenDelegatedToLiquidityMining.selector ||
            sig == IPowerTokenLens.getPwTokensInCooldown.selector ||
            sig == IPowerTokenLens.getPwTokenUnstakeFee.selector ||
            sig == IPowerTokenLens.getPwTokenCooldownTime.selector ||
            sig == IPowerTokenLens.getPwTokenExchangeRate.selector ||
            sig == IPowerTokenLens.getPwTokenTotalSupplyBase.selector
        ) {
            return powerTokenLens;
        } else if (
            sig == IAmmCloseSwapLens.getAmmCloseSwapServicePoolConfiguration.selector ||
            sig == IAmmCloseSwapLens.getClosingSwapDetails.selector
        ) {
            return ammCloseSwapLens;
        } else if (sig == IAmmPoolsLensWstEth.getIpwstEthExchangeRate.selector) {
            return ammPoolsLensWstEth;
        }

        revert(IporErrors.ROUTER_INVALID_SIGNATURE);
    }
}