// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Vault } from "./Vault.sol";
import { ShareMath } from "./ShareMath.sol";

library VaultLifecycle {
    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the total value held by the vault priced in USDC
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from all rounds excluding the last
     * @param currentQueuedWithdrawShares is the amount queued for withdrawals from last round
     * @param performanceFee is the performance fee percent
     * @param managementFee is the management fee percent
     * @param epochsElapsed is the number of epochs elapsed measured by the duration
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 currentQueuedWithdrawShares;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 epochsElapsed;
    }

    /**
     * @notice Calculate the new price per share and
      amount of funds to re-allocate as collateral for the new epoch
     * @param vaultState is the storage variable vaultState
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(Vault.VaultState storage vaultState, RolloverParams calldata params)
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;
        uint256 epochManagementFee = params.epochsElapsed > 0 ? params.managementFee * params.epochsElapsed : params.managementFee;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees = currentBalance - params.lastQueuedWithdrawAmount;

        {
            // no performance fee on first round
            balanceForVaultFees = vaultState.round == 1 ? vaultState.totalPending : balanceForVaultFees;

            (performanceFeeInAsset, , totalVaultFee) = VaultLifecycle.getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                epochManagementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance - totalVaultFee;

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply - lastQueuedWithdrawShares,
                currentBalance - params.lastQueuedWithdrawAmount,
                params.decimals
            );

            queuedWithdrawAmount =
                params.lastQueuedWithdrawAmount +
                ShareMath.sharesToAsset(params.currentQueuedWithdrawShares, newPricePerShare, params.decimals);
        }

        return (
            currentBalance - queuedWithdrawAmount, // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending = currentBalance > pendingAmount ? currentBalance - pendingAmount : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee ONLY if difference between
        // last epoch and this epoch's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last round
        // was not profitable and the vault took a loss on assets
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? ((lockedBalanceSansPending - lastLockedAmount) * performanceFeePercent) / (100 * Vault.FEE_MULTIPLIER)
                : 0;
        }
        // Take management fee on each epoch
        _managementFeeInAsset = managementFeePercent > 0
            ? (lockedBalanceSansPending * managementFeePercent) / (100 * Vault.FEE_MULTIPLIER)
            : 0;

        _vaultFee = _performanceFeeInAsset + _managementFeeInAsset;

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

library Vault {
    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Token decimals for vault shares
        uint8 decimals;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
        // Vault asset
        address asset;
        // staked glp
        address stakedGlp;
        // esGMX
        address esGMX;
        // glp pricing library
        address glpPricing;
        // tracer hedge pricing library
        address hedgePricing;
        // sbtc tcr emissions staking
        address sbtcStake;
        // seth tcr emissions staking
        address sethStake;
    }

    struct StrategyState {
        // the allocation of sbtc this epoch
        uint256 activeSbtcAllocation;
        // the allocation of seth this epoch
        uint256 activeSethAllocation;
        // the allocation of glp this epoch
        uint256 activeGlpAllocation;
        // The index of the leverage for btc shorts
        uint256 activeBtcLeverageIndex;
        // The index of the leverage for eth shorts
        uint256 activeEthLeverageIndex;
        // the allocation of sbtc next epoch
        uint256 nextSbtcAllocation;
        // the allocation of seth next epoch
        uint256 nextSethAllocation;
        // the allocation of glp next epoch
        uint256 nextGlpAllocation;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint104 round;
        // Amount that is currently locked for the strategy
        uint104 lockedAmount;
        // Amount that was locked for the strategy
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds not including the current round
        uint128 queuedWithdrawShares;
        // Start time of the last epoch
        uint256 epochStart;
        // Epoch end time
        uint256 epochEnd;
    }

    struct LeverageSet {
        // The tokenised leverage position
        address token;
        // The committer for the leverage position
        address poolCommitter;
        // Leverage pool holding the deposit tokens
        address leveragePool;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import { Vault } from "./Vault.sol";

library ShareMath {
    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (assetAmount * 10**decimals) / assetPerShare;
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return (shares * assetPerShare) / 10**decimals;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return totalSupply > 0 ? (singleShare * totalBalance) / totalSupply : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}