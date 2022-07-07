// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';

import { AddressHelper } from './AddressHelper.sol';
import { CollateralDeposit } from './CollateralDeposit.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { SignedMath } from './SignedMath.sol';
import { LiquidityPositionSet } from './LiquidityPositionSet.sol';
import { LiquidityPosition } from './LiquidityPosition.sol';
import { Protocol } from './Protocol.sol';
import { VTokenPosition } from './VTokenPosition.sol';
import { VTokenPositionSet } from './VTokenPositionSet.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';
import { IClearingHouseEnums } from '../interfaces/clearinghouse/IClearingHouseEnums.sol';
import { IVQuote } from '../interfaces/IVQuote.sol';
import { IVToken } from '../interfaces/IVToken.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Cross margined account functions
/// @dev This library is deployed and used as an external library by ClearingHouse contract.
library Account {
    using AddressHelper for address;
    using FullMath for uint256;
    using SafeCast for uint256;
    using SignedFullMath for int256;
    using SignedMath for int256;

    using Account for Account.Info;
    using CollateralDeposit for CollateralDeposit.Set;
    using LiquidityPositionSet for LiquidityPosition.Set;
    using Protocol for Protocol.Info;
    using VTokenPosition for VTokenPosition.Info;
    using VTokenPositionSet for VTokenPosition.Set;

    /// @notice account info for user
    /// @param owner specifies the account owner
    /// @param tokenPositions is set of all open token positions
    /// @param collateralDeposits is set of all deposits
    struct Info {
        uint96 id;
        address owner;
        VTokenPosition.Set tokenPositions;
        CollateralDeposit.Set collateralDeposits;
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    /**
     *  Errors
     */

    /// @notice error to denote that there is not enough margin for the transaction to go through
    /// @param accountMarketValue shows the account market value after the transaction is executed
    /// @param totalRequiredMargin shows the total required margin after the transaction is executed
    error InvalidTransactionNotEnoughMargin(int256 accountMarketValue, int256 totalRequiredMargin);

    /// @notice error to denote that there is not enough profit during profit withdrawal
    /// @param totalProfit shows the value of positions at the time of execution after removing amount specified
    error InvalidTransactionNotEnoughProfit(int256 totalProfit);

    /// @notice error to denote that there is enough margin, hence the liquidation is invalid
    /// @param accountMarketValue shows the account market value before liquidation
    /// @param totalRequiredMargin shows the total required margin before liquidation
    error InvalidLiquidationAccountAboveWater(int256 accountMarketValue, int256 totalRequiredMargin);

    /// @notice error to denote that there are active ranges present during token liquidation, hence the liquidation is invalid
    /// @param poolId shows the poolId for which range is active
    error InvalidLiquidationActiveRangePresent(uint32 poolId);

    /// @notice denotes withdrawal of profit in settlement token
    /// @param accountId serial number of the account
    /// @param amount amount of profit withdrawn
    event ProfitUpdated(uint256 indexed accountId, int256 amount);

    /**
     *  Events
     */

    /// @notice denotes add or remove of margin
    /// @param accountId serial number of the account
    /// @param collateralId token in which margin is deposited
    /// @param amount amount of tokens deposited
    event MarginUpdated(uint256 indexed accountId, uint32 indexed collateralId, int256 amount, bool isSettleProfit);

    /// @notice denotes range position liquidation event
    /// @dev all range positions are liquidated and the current tokens inside the range are added in as token positions to the account
    /// @param accountId serial number of the account
    /// @param keeperAddress address of keeper who performed the liquidation
    /// @param liquidationFee total liquidation fee charged to the account
    /// @param keeperFee total liquidaiton fee paid to the keeper (positive only)
    /// @param insuranceFundFee total liquidaiton fee paid to the insurance fund (can be negative in case the account is not enought to cover the fee)
    event LiquidityPositionsLiquidated(
        uint256 indexed accountId,
        address indexed keeperAddress,
        int256 liquidationFee,
        int256 keeperFee,
        int256 insuranceFundFee,
        int256 accountMarketValueFinal
    );

    /// @notice denotes token position liquidation event
    /// @dev the selected token position is take from the current account and moved to liquidatorAccount at a discounted prive to current pool price
    /// @param accountId serial number of the account
    /// @param poolId id of the rage trade pool for whose position was liquidated
    /// @param keeperFee total liquidaiton fee paid to keeper
    /// @param insuranceFundFee total liquidaiton fee paid to the insurance fund (can be negative in case the account is not enough to cover the fee)
    event TokenPositionLiquidated(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int256 keeperFee,
        int256 insuranceFundFee,
        int256 accountMarketValueFinal
    );

    /**
     *  External methods
     */

    /// @notice changes deposit balance of 'vToken' by 'amount'
    /// @param account account to deposit balance into
    /// @param collateralId collateral id of the token
    /// @param amount amount of token to deposit or withdraw
    /// @param protocol set of all constants and token addresses
    /// @param checkMargin true to check if margin is available else false
    function updateMargin(
        Account.Info storage account,
        uint32 collateralId,
        int256 amount,
        Protocol.Info storage protocol,
        bool checkMargin
    ) external {
        _updateMargin(account, collateralId, amount, protocol, checkMargin, false);
    }

    /// @notice updates 'amount' of profit generated in settlement token
    /// @param account account to remove profit from
    /// @param amount amount of profit(settlement token) to add/remove
    /// @param protocol set of all constants and token addresses
    /// @param checkMargin true to check if margin is available else false
    function updateProfit(
        Account.Info storage account,
        int256 amount,
        Protocol.Info storage protocol,
        bool checkMargin
    ) external {
        _updateProfit(account, amount, protocol, checkMargin);
    }

    function settleProfit(Account.Info storage account, Protocol.Info storage protocol) external {
        _settleProfit(account, protocol);
    }

    /// @notice swaps 'vToken' of token amount equal to 'swapParams.amount'
    /// @notice if vTokenAmount>0 then the swap is a long or close short and if vTokenAmount<0 then swap is a short or close long
    /// @notice isNotional specifies whether the amount represents token amount (false) or vQuote amount(true)
    /// @notice isPartialAllowed specifies whether to revert (false) or to execute a partial swap (true)
    /// @notice sqrtPriceLimit threshold sqrt price which if crossed then revert or execute partial swap
    /// @param account account to swap tokens for
    /// @param poolId id of the pool to swap tokens for
    /// @param swapParams parameters for the swap (Includes - amount, sqrtPriceLimit, isNotional, isPartialAllowed)
    /// @param protocol set of all constants and token addresses
    /// @param checkMargin true to check if margin is available else false
    /// @return vTokenAmountOut amount of vToken after swap (user receiving then +ve, user paying then -ve)
    /// @return vQuoteAmountOut amount of vQuote after swap (user receiving then +ve, user paying then -ve)
    function swapToken(
        Account.Info storage account,
        uint32 poolId,
        IClearingHouseStructures.SwapParams memory swapParams,
        Protocol.Info storage protocol,
        bool checkMargin
    ) external returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        // make a swap. vQuoteIn and vTokenAmountOut (in and out wrt uniswap).
        // mints erc20 tokens in callback and send to the pool
        (vTokenAmountOut, vQuoteAmountOut) = account.tokenPositions.swapToken(account.id, poolId, swapParams, protocol);

        if (swapParams.settleProfit) {
            account._settleProfit(protocol);
        }
        // after all the stuff, account should be above water
        if (checkMargin) account._checkIfMarginAvailable(true, protocol);
    }

    /// @notice changes range liquidity 'vToken' of market value equal to 'vTokenNotional'
    /// @notice if 'liquidityDelta'>0 then liquidity is added and if 'liquidityChange'<0 then liquidity is removed
    /// @notice the liquidity change is reverted if the sqrt price at the time of execution is beyond 'slippageToleranceBps' of 'sqrtPriceCurrent' supplied
    /// @notice whenever liquidity change is done the external token position is taken out. If 'closeTokenPosition' is true this is swapped out else it is added to the current token position
    /// @param account account to change liquidity
    /// @param poolId id of the rage trade pool
    /// @param liquidityChangeParams parameters including lower tick, upper tick, liquidity delta, sqrtPriceCurrent, slippageToleranceBps, closeTokenPosition, limit order type
    /// @param protocol set of all constants and token addresses
    function liquidityChange(
        Account.Info storage account,
        uint32 poolId,
        IClearingHouseStructures.LiquidityChangeParams memory liquidityChangeParams,
        Protocol.Info storage protocol,
        bool checkMargin
    )
        external
        returns (
            int256 vTokenAmountOut,
            int256 vQuoteAmountOut,
            uint256 notionalValueAbs
        )
    {
        // mint/burn tokens + fee + funding payment
        (vTokenAmountOut, vQuoteAmountOut) = account.tokenPositions.liquidityChange(
            account.id,
            poolId,
            liquidityChangeParams,
            protocol
        );

        if (liquidityChangeParams.settleProfit) {
            account._settleProfit(protocol);
        }
        // after all the stuff, account should be above water
        if (checkMargin) account._checkIfMarginAvailable(true, protocol);

        notionalValueAbs = protocol.getNotionalValue(poolId, vTokenAmountOut, vQuoteAmountOut);
    }

    /// @notice liquidates all range positions in case the account is under water
    ///     charges a liquidation fee to the account and pays partially to the insurance fund and rest to the keeper.
    /// @dev insurance fund covers the remaining fee if the account market value is not enough
    /// @param account account to liquidate
    /// @param protocol set of all constants and token addresses
    /// @return keeperFee amount of liquidation fee paid to keeper
    /// @return insuranceFundFee amount of liquidation fee paid to insurance fund
    /// @return accountMarketValue account market value before liquidation
    function liquidateLiquidityPositions(Account.Info storage account, Protocol.Info storage protocol)
        external
        returns (
            int256 keeperFee,
            int256 insuranceFundFee,
            int256 accountMarketValue
        )
    {
        // check basis maintanace margin
        int256 totalRequiredMargin;
        uint256 notionalAmountClosed;

        (accountMarketValue, totalRequiredMargin) = account._getAccountValueAndRequiredMargin(false, protocol);

        // check and revert if account is above water
        if (accountMarketValue > totalRequiredMargin) {
            revert InvalidLiquidationAccountAboveWater(accountMarketValue, totalRequiredMargin);
        }
        // liquidate all liquidity positions
        notionalAmountClosed = account.tokenPositions.liquidateLiquidityPositions(account.id, protocol);

        // compute liquidation fees
        (keeperFee, insuranceFundFee) = _computeLiquidationFees(
            accountMarketValue,
            notionalAmountClosed,
            true,
            protocol.liquidationParams
        );

        account._updateVQuoteBalance(-(keeperFee + insuranceFundFee));
    }

    /// @notice liquidates token position specified by 'poolId' in case account is underwater
    ///     charges a liquidation fee to the account and pays partially to the insurance fund and rest to the keeper.
    /// @dev closes position uptil a specified slippage threshold in protocol.liquidationParams
    /// @dev insurance fund covers the remaining fee if the account market value is not enough
    /// @dev if there is range position this reverts (liquidators are supposed to liquidate range positions first)
    /// @param account account to liquidate
    /// @param poolId id of the pool to liquidate
    /// @param protocol set of all constants and token addresses
    /// @return keeperFee amount of liquidation fee paid to keeper
    /// @return insuranceFundFee amount of liquidation fee paid to insurance fund
    function liquidateTokenPosition(
        Account.Info storage account,
        uint32 poolId,
        Protocol.Info storage protocol
    ) external returns (int256 keeperFee, int256 insuranceFundFee) {
        bool isPartialLiquidation;

        // check if there is range position and revert
        if (account.tokenPositions.isTokenRangeActive(poolId)) revert InvalidLiquidationActiveRangePresent(poolId);

        {
            (int256 accountMarketValue, int256 totalRequiredMargin) = account._getAccountValueAndRequiredMargin(
                false,
                protocol
            );

            // check and revert if account is above water
            if (accountMarketValue > totalRequiredMargin) {
                revert InvalidLiquidationAccountAboveWater(accountMarketValue, totalRequiredMargin);
            } else if (
                // check if account is underwater but within partial liquidation threshold
                accountMarketValue >
                totalRequiredMargin.mulDiv(protocol.liquidationParams.closeFactorMMThresholdBps, 1e4)
            ) {
                isPartialLiquidation = true;
            }
        }

        int256 tokensToTrade;
        {
            // get the net token position and tokensToTrade = -tokenPosition
            // since no ranges are supposed to be there so only tokenPosition is in vTokenPositionSet
            VTokenPosition.Info storage vTokenPosition = account.tokenPositions.getTokenPosition(poolId, false);
            tokensToTrade = -vTokenPosition.balance;
            uint256 tokenNotionalValue = tokensToTrade.absUint().mulDiv(
                protocol.getCachedVirtualTwapPriceX128(poolId),
                FixedPoint128.Q128
            );

            // check if the token position is less than a certain notional value
            // if so then liquidate the whole position even if partial liquidation is allowed
            // otherwise do partial liquidation
            if (isPartialLiquidation && tokenNotionalValue > protocol.liquidationParams.minNotionalLiquidatable) {
                tokensToTrade = tokensToTrade.mulDiv(protocol.liquidationParams.partialLiquidationCloseFactorBps, 1e4);
            }
        }

        int256 accountMarketValueFinal;
        {
            uint160 sqrtPriceLimit;
            {
                // calculate sqrt price limit based on slippage threshold
                uint160 sqrtTwapPrice = protocol.getVirtualTwapSqrtPriceX96(poolId);
                if (tokensToTrade > 0) {
                    sqrtPriceLimit = uint256(sqrtTwapPrice)
                        .mulDiv(1e4 + protocol.liquidationParams.liquidationSlippageSqrtToleranceBps, 1e4)
                        .toUint160();
                } else {
                    sqrtPriceLimit = uint256(sqrtTwapPrice)
                        .mulDiv(1e4 - protocol.liquidationParams.liquidationSlippageSqrtToleranceBps, 1e4)
                        .toUint160();
                }
            }

            // close position uptil sqrt price limit
            (, int256 vQuoteAmountSwapped) = account.tokenPositions.swapToken(
                account.id,
                poolId,
                IClearingHouseStructures.SwapParams({
                    amount: tokensToTrade,
                    sqrtPriceLimit: sqrtPriceLimit,
                    isNotional: false,
                    isPartialAllowed: true,
                    settleProfit: false
                }),
                protocol
            );

            // get the account market value after closing the position
            accountMarketValueFinal = account._getAccountValue(protocol);

            // compute liquidation fees
            (keeperFee, insuranceFundFee) = _computeLiquidationFees(
                accountMarketValueFinal,
                vQuoteAmountSwapped.absUint(),
                false,
                protocol.liquidationParams
            );
        }

        // deduct liquidation fees from account
        account._updateVQuoteBalance(-(keeperFee + insuranceFundFee));

        emit TokenPositionLiquidated(account.id, poolId, keeperFee, insuranceFundFee, accountMarketValueFinal);
    }

    /// @notice removes limit order based on the current price position (keeper call)
    /// @param account account to liquidate
    /// @param poolId id of the pool for the range
    /// @param tickLower lower tick index for the range
    /// @param tickUpper upper tick index for the range
    /// @param protocol platform constants
    function removeLimitOrder(
        Account.Info storage account,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper,
        uint256 limitOrderFee,
        Protocol.Info storage protocol
    ) external {
        account.tokenPositions.removeLimitOrder(account.id, poolId, tickLower, tickUpper, protocol);

        account._updateVQuoteBalance(-int256(limitOrderFee));
    }

    /**
     *  External view methods
     */

    /// @notice returns market value for the account positions based on current market conditions
    /// @param account account to check
    /// @param protocol set of all constants and token addresses
    /// @return accountPositionProfits total market value of all the positions (token ) and deposits
    function getAccountPositionProfits(Account.Info storage account, Protocol.Info storage protocol)
        external
        view
        returns (int256 accountPositionProfits)
    {
        return account._getAccountPositionProfits(protocol);
    }

    /// @notice returns market value and required margin for the account based on current market conditions
    /// @dev (In case requiredMargin < minRequiredMargin then requiredMargin = minRequiredMargin)
    /// @param account account to check
    /// @param isInitialMargin true to use initial margin factor and false to use maintainance margin factor for calcualtion of required margin
    /// @param protocol set of all constants and token addresses
    /// @return accountMarketValue total market value of all the positions (token ) and deposits
    /// @return totalRequiredMargin total margin required to keep the account above selected margin requirement (intial/maintainance)
    function getAccountValueAndRequiredMargin(
        Account.Info storage account,
        bool isInitialMargin,
        Protocol.Info storage protocol
    ) external view returns (int256 accountMarketValue, int256 totalRequiredMargin) {
        return account._getAccountValueAndRequiredMargin(isInitialMargin, protocol);
    }

    /// @notice checks if market value > required margin else revert with InvalidTransactionNotEnoughMargin
    /// @param account account to check
    /// @param isInitialMargin true to use initialMarginFactor and false to use maintainance margin factor for calcualtion of required margin
    /// @param protocol set of all constants and token addresses
    function checkIfMarginAvailable(
        Account.Info storage account,
        bool isInitialMargin,
        Protocol.Info storage protocol
    ) external view {
        (int256 accountMarketValue, int256 totalRequiredMargin) = account._getAccountValueAndRequiredMargin(
            isInitialMargin,
            protocol
        );
        if (accountMarketValue < totalRequiredMargin)
            revert InvalidTransactionNotEnoughMargin(accountMarketValue, totalRequiredMargin);
    }

    /// @notice checks if profit is available to withdraw settlement token (token value of all positions > 0) else revert with InvalidTransactionNotEnoughProfit
    /// @param account account to check
    /// @param protocol set of all constants and token addresses
    function checkIfProfitAvailable(Account.Info storage account, Protocol.Info storage protocol) external view {
        _checkIfProfitAvailable(account, protocol);
    }

    /// @notice gets information about all the collateral and positions in the account
    /// @param account ref to the account state
    /// @param protocol ref to the protocol state
    /// @return owner of the account
    /// @return vQuoteBalance amount of vQuote in the account
    /// @return collateralDeposits list of all the collateral amounts
    /// @return tokenPositions list of all the token and liquidity positions
    function getInfo(Account.Info storage account, Protocol.Info storage protocol)
        external
        view
        returns (
            address owner,
            int256 vQuoteBalance,
            IClearingHouseStructures.CollateralDepositView[] memory collateralDeposits,
            IClearingHouseStructures.VTokenPositionView[] memory tokenPositions
        )
    {
        owner = account.owner;
        collateralDeposits = account.collateralDeposits.getInfo(protocol);
        (vQuoteBalance, tokenPositions) = account.tokenPositions.getInfo();
    }

    /// @notice gets the net position of the account for a given pool
    /// @param account ref to the account state
    /// @param poolId id of the pool
    /// @param protocol ref to the protocol state
    /// @return netPosition net position of the account for the pool
    function getNetPosition(
        Account.Info storage account,
        uint32 poolId,
        Protocol.Info storage protocol
    ) external view returns (int256 netPosition) {
        return account.tokenPositions.getNetPosition(poolId, protocol);
    }

    /**
     *  Internal methods
     */

    function updateAccountPoolPrices(Account.Info storage account, Protocol.Info storage protocol) internal {
        account.tokenPositions.updateOpenPoolPrices(protocol);
    }

    /// @notice settles profit or loss for the account
    /// @param account ref to the account state
    /// @param protocol ref to the protocol state
    function _settleProfit(Account.Info storage account, Protocol.Info storage protocol) internal {
        int256 profits = account._getAccountPositionProfits(protocol);
        uint32 settlementCollateralId = AddressHelper.truncate(protocol.settlementToken);
        if (profits > 0) {
            account._updateProfit(-profits, protocol, false);
            account._updateMargin({
                collateralId: settlementCollateralId,
                amount: profits,
                protocol: protocol,
                checkMargin: false,
                isSettleProfit: true
            });
        } else if (profits < 0) {
            uint256 balance = account.collateralDeposits.getBalance(settlementCollateralId);
            uint256 profitAbsUint = uint256(-profits);
            uint256 balanceToUpdate = balance > profitAbsUint ? profitAbsUint : balance;
            if (balanceToUpdate > 0) {
                account._updateMargin({
                    collateralId: settlementCollateralId,
                    amount: -balanceToUpdate.toInt256(),
                    protocol: protocol,
                    checkMargin: false,
                    isSettleProfit: true
                });
                account._updateProfit(balanceToUpdate.toInt256(), protocol, false);
            }
        }
    }

    /// @notice updates 'amount' of profit generated in settlement token
    /// @param account account to remove profit from
    /// @param amount amount of profit(settlement token) to add/remove
    /// @param protocol set of all constants and token addresses
    /// @param checkMargin true to check if margin is available else false
    function _updateProfit(
        Account.Info storage account,
        int256 amount,
        Protocol.Info storage protocol,
        bool checkMargin
    ) internal {
        account._updateVQuoteBalance(amount);

        if (checkMargin && amount < 0) {
            account._checkIfProfitAvailable(protocol);
            account._checkIfMarginAvailable(true, protocol);
        }

        emit ProfitUpdated(account.id, amount);
    }

    /// @notice changes deposit balance of 'vToken' by 'amount'
    /// @param account account to deposit balance into
    /// @param collateralId collateral id of the token
    /// @param amount amount of token to deposit or withdraw
    /// @param protocol set of all constants and token addresses
    /// @param checkMargin true to check if margin is available else false
    function _updateMargin(
        Account.Info storage account,
        uint32 collateralId,
        int256 amount,
        Protocol.Info storage protocol,
        bool checkMargin,
        bool isSettleProfit
    ) internal {
        if (amount > 0) {
            account.collateralDeposits.increaseBalance(collateralId, uint256(amount));
        } else {
            account.collateralDeposits.decreaseBalance(collateralId, uint256(-amount));
            if (checkMargin) account._checkIfMarginAvailable(true, protocol);
        }

        emit MarginUpdated(account.id, collateralId, amount, isSettleProfit);
    }

    /// @notice updates the vQuote balance for 'account' by 'amount'
    /// @param account pointer to 'account' struct
    /// @param amount amount of balance to update
    /// @return balanceAdjustments vToken and vQuote balance changes of the account
    function _updateVQuoteBalance(Account.Info storage account, int256 amount)
        internal
        returns (IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments)
    {
        balanceAdjustments = IClearingHouseStructures.BalanceAdjustments(amount, 0, 0);
        account.tokenPositions.vQuoteBalance += balanceAdjustments.vQuoteIncrease;
    }

    /**
     *  Internal view methods
     */

    /// @notice ensures that the account has enough margin to cover the required margin
    /// @param account ref to the account state
    /// @param protocol ref to the protocol state
    function _checkIfMarginAvailable(
        Account.Info storage account,
        bool isInitialMargin,
        Protocol.Info storage protocol
    ) internal view {
        (int256 accountMarketValue, int256 totalRequiredMargin) = account._getAccountValueAndRequiredMargin(
            isInitialMargin,
            protocol
        );
        if (accountMarketValue < totalRequiredMargin)
            revert InvalidTransactionNotEnoughMargin(accountMarketValue, totalRequiredMargin);
    }

    /// @notice ensures that the account has non negative profit
    /// @param account ref to the account state
    /// @param protocol ref to the protocol state
    function _checkIfProfitAvailable(Account.Info storage account, Protocol.Info storage protocol) internal view {
        int256 totalPositionValue = account._getAccountPositionProfits(protocol);
        if (totalPositionValue < 0) revert InvalidTransactionNotEnoughProfit(totalPositionValue);
    }

    /// @notice gets the amount of account's position profits
    /// @param account ref to the account state
    /// @param protocol ref to the protocol state
    function _getAccountPositionProfits(Account.Info storage account, Protocol.Info storage protocol)
        internal
        view
        returns (int256 accountPositionProfits)
    {
        accountPositionProfits = account.tokenPositions.getAccountMarketValue(protocol);
    }

    /// @notice gets market value for the account based on current market conditions
    /// @param account ref to the account state
    /// @param protocol set of all constants and token addresses
    /// @return accountMarketValue total market value of all the positions (token ) and deposits
    function _getAccountValue(Account.Info storage account, Protocol.Info storage protocol)
        internal
        view
        returns (int256 accountMarketValue)
    {
        accountMarketValue = account._getAccountPositionProfits(protocol);
        accountMarketValue += account.collateralDeposits.marketValue(protocol);
        return (accountMarketValue);
    }

    /// @notice gets market value and req margin for the account based on current market conditions
    /// @param account ref to the account state
    /// @param isInitialMargin true to use initialMarginFactor and false to use maintainance margin factor for calcualtion of required margin
    /// @param protocol set of all constants and token addresses
    /// @return accountMarketValue total market value of all the positions (token) and deposits
    /// @return totalRequiredMargin total required margin for the account
    function _getAccountValueAndRequiredMargin(
        Account.Info storage account,
        bool isInitialMargin,
        Protocol.Info storage protocol
    ) internal view returns (int256 accountMarketValue, int256 totalRequiredMargin) {
        accountMarketValue = account._getAccountValue(protocol);

        totalRequiredMargin = account.tokenPositions.getRequiredMargin(isInitialMargin, protocol);
        if (!account.tokenPositions.isEmpty()) {
            totalRequiredMargin = totalRequiredMargin < int256(protocol.minRequiredMargin)
                ? int256(protocol.minRequiredMargin)
                : totalRequiredMargin;
        }
        return (accountMarketValue, totalRequiredMargin);
    }

    /// @notice checks if 'account' is initialized
    /// @param account pointer to 'account' struct
    function _isInitialized(Account.Info storage account) internal view returns (bool) {
        return !account.owner.isZero();
    }

    /**
     *  Internal pure methods
     */

    /// @notice computes keeper fee and insurance fund fee in case of liquidity position liquidation
    /// @dev keeperFee = liquidationFee*(1-insuranceFundFeeShare)
    /// @dev insuranceFundFee = accountMarketValue - keeperFee (if accountMarketValue is not enough to cover the fees) else insurancFundFee = liquidationFee - keeperFee
    /// @param accountMarketValue market value of account
    /// @param notionalAmountClosed notional value of position closed
    /// @param isRangeLiquidation - true for range liquidation and false for token liquidation
    /// @param liquidationParams parameters including insuranceFundFeeShareBps
    /// @return keeperFee map of vTokens allowed on the platform
    /// @return insuranceFundFee poolwrapper for token
    function _computeLiquidationFees(
        int256 accountMarketValue,
        uint256 notionalAmountClosed,
        bool isRangeLiquidation,
        IClearingHouseStructures.LiquidationParams memory liquidationParams
    ) internal pure returns (int256 keeperFee, int256 insuranceFundFee) {
        uint256 liquidationFee;

        if (isRangeLiquidation) {
            liquidationFee = notionalAmountClosed.mulDiv(liquidationParams.rangeLiquidationFeeFraction, 1e5);
            if (liquidationParams.maxRangeLiquidationFees < liquidationFee)
                liquidationFee = liquidationParams.maxRangeLiquidationFees;
        } else {
            liquidationFee = notionalAmountClosed.mulDiv(liquidationParams.tokenLiquidationFeeFraction, 1e5);
        }

        int256 liquidationFeeInt = liquidationFee.toInt256();

        keeperFee = liquidationFeeInt.mulDiv(1e4 - liquidationParams.insuranceFundFeeShareBps, 1e4);
        if (accountMarketValue - liquidationFeeInt < 0) {
            insuranceFundFee = accountMarketValue - keeperFee;
        } else {
            insuranceFundFee = liquidationFeeInt - keeperFee;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import { IVToken } from '../interfaces/IVToken.sol';

/// @title Address helper functions
library AddressHelper {
    /// @notice converts address to uint32, using the least significant 32 bits
    /// @param addr Address to convert
    /// @return truncated last 4 bytes of the address
    function truncate(address addr) internal pure returns (uint32 truncated) {
        assembly {
            truncated := and(addr, 0xffffffff)
        }
    }

    /// @notice converts IERC20 contract to uint32
    /// @param addr contract
    /// @return truncated last 4 bytes of the address
    function truncate(IERC20 addr) internal pure returns (uint32 truncated) {
        return truncate(address(addr));
    }

    /// @notice checks if two addresses are equal
    /// @param a first address
    /// @param b second address
    /// @return true if addresses are equal
    function eq(address a, address b) internal pure returns (bool) {
        return a == b;
    }

    /// @notice checks if addresses of two IERC20 contracts are equal
    /// @param a first contract
    /// @param b second contract
    /// @return true if addresses are equal
    function eq(IERC20 a, IERC20 b) internal pure returns (bool) {
        return eq(address(a), address(b));
    }

    /// @notice checks if an address is zero
    /// @param a address to check
    /// @return true if address is zero
    function isZero(address a) internal pure returns (bool) {
        return a == address(0);
    }

    /// @notice checks if address of an IERC20 contract is zero
    /// @param a contract to check
    /// @return true if address is zero
    function isZero(IERC20 a) internal pure returns (bool) {
        return isZero(address(a));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';

import { Protocol } from './Protocol.sol';
import { AddressHelper } from './AddressHelper.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { Uint32L8ArrayLib } from './Uint32L8Array.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';

/// @title Collateral deposit set functions
library CollateralDeposit {
    using AddressHelper for address;
    using SafeCast for uint256;
    using SignedFullMath for int256;
    using Uint32L8ArrayLib for uint32[8];

    error InsufficientCollateralBalance();

    struct Set {
        // Fixed length array of collateralId = collateralAddress.truncate()
        // Supports upto 8 different collaterals in an account.
        // Collision is possible, i.e. collateralAddress1.truncate() == collateralAddress2.truncate()
        // However the possibility is 1/2**32, which is negligible.
        // There are checks that prevent use of a different collateralAddress for a given collateralId.
        // If there is a geniune collision, a wrapper for the ERC20 token can deployed such that
        // there are no collisions with wrapper and the wrapped ERC20 can be used as collateral.
        uint32[8] active; // array of collateralIds
        mapping(uint32 => uint256) deposits; // collateralId => deposit amount
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    function getBalance(CollateralDeposit.Set storage set, uint32 collateralId) internal view returns (uint256) {
        return set.deposits[collateralId];
    }

    /// @notice Increase the deposit amount of a given collateralId
    /// @param set CollateralDepositSet of the account
    /// @param collateralId The collateralId of the collateral to increase the deposit amount of
    /// @param amount The amount to increase the deposit amount of the collateral by
    function increaseBalance(
        CollateralDeposit.Set storage set,
        uint32 collateralId,
        uint256 amount
    ) internal {
        set.active.include(collateralId);

        set.deposits[collateralId] += amount;
    }

    /// @notice Decrease the deposit amount of a given collateralId
    /// @param set CollateralDepositSet of the account
    /// @param collateralId The collateralId of the collateral to decrease the deposit amount of
    /// @param amount The amount to decrease the deposit amount of the collateral by
    function decreaseBalance(
        CollateralDeposit.Set storage set,
        uint32 collateralId,
        uint256 amount
    ) internal {
        if (set.deposits[collateralId] < amount) revert InsufficientCollateralBalance();
        set.deposits[collateralId] -= amount;

        if (set.deposits[collateralId] == 0) {
            set.active.exclude(collateralId);
        }
    }

    /// @notice Get the market value of all the collateral deposits in settlementToken denomination
    /// @param set CollateralDepositSet of the account
    /// @param protocol Global protocol state
    /// @return The market value of all the collateral deposits in settlementToken denomination
    function marketValue(CollateralDeposit.Set storage set, Protocol.Info storage protocol)
        internal
        view
        returns (int256)
    {
        int256 accountMarketValue;
        for (uint8 i = 0; i < set.active.length; i++) {
            uint32 collateralId = set.active[i];

            if (collateralId == 0) break;
            IClearingHouseStructures.Collateral storage collateral = protocol.collaterals[collateralId];

            accountMarketValue += set.deposits[collateralId].toInt256().mulDiv(
                collateral.settings.oracle.getTwapPriceX128(collateral.settings.twapDuration),
                FixedPoint128.Q128
            );
        }
        return accountMarketValue;
    }

    /// @notice Get information about all the collateral deposits
    /// @param set CollateralDepositSet of the account
    /// @param protocol Global protocol state
    /// @return collateralDeposits Information about all the collateral deposits
    function getInfo(CollateralDeposit.Set storage set, Protocol.Info storage protocol)
        internal
        view
        returns (IClearingHouseStructures.CollateralDepositView[] memory collateralDeposits)
    {
        uint256 numberOfTokenPositions = set.active.numberOfNonZeroElements();
        collateralDeposits = new IClearingHouseStructures.CollateralDepositView[](numberOfTokenPositions);

        for (uint256 i = 0; i < numberOfTokenPositions; i++) {
            collateralDeposits[i].collateral = protocol.collaterals[set.active[i]].token;
            collateralDeposits[i].balance = set.deposits[set.active[i]];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';

import { SignedMath } from './SignedMath.sol';

/// @title Signed full math functions
library SignedFullMath {
    using SafeCast for uint256;
    using SignedMath for int256;

    /// @notice uses full math on signed int and two unsigned ints
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = FullMath.mulDiv(a < 0 ? uint256(-1 * a) : uint256(a), b, denominator).toInt256();
        if (a < 0) {
            result = -result;
        }
    }

    /// @notice uses full math on three signed ints
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator
    function mulDiv(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        bool resultPositive = true;
        uint256 _a;
        uint256 _b;
        uint256 _denominator;

        (_a, resultPositive) = a.extractSign(resultPositive);
        (_b, resultPositive) = b.extractSign(resultPositive);
        (_denominator, resultPositive) = denominator.extractSign(resultPositive);

        result = FullMath.mulDiv(_a, _b, _denominator).toInt256();
        if (!resultPositive) {
            result = -result;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: unsigned int to be multiplied by
    /// @param denominator: unsigned int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b, denominator)) {
            result += -1;
        }
    }

    /// @notice rounds down towards negative infinity
    /// @dev in Solidity -3/2 is -1. But this method result is -2
    /// @param a: signed int
    /// @param b: signed int to be multiplied by
    /// @param denominator: signed int to be divided by
    /// @return result of a * b / denominator rounded towards negative infinity
    function mulDivRoundingDown(
        int256 a,
        int256 b,
        int256 denominator
    ) internal pure returns (int256 result) {
        result = mulDiv(a, b, denominator);
        if (result < 0 && _hasRemainder(a.absUint(), b.absUint(), denominator.absUint())) {
            result += -1;
        }
    }

    /// @notice checks if full multiplication of a & b would have a remainder if divided by denominator
    /// @param a: multiplicand
    /// @param b: multiplier
    /// @param denominator: divisor
    /// @return hasRemainder true if there is a remainder, false otherwise
    function _hasRemainder(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) private pure returns (bool hasRemainder) {
        assembly {
            let remainder := mulmod(a, b, denominator)
            if gt(remainder, 0) {
                hasRemainder := 1
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

int256 constant ONE = 1;

/// @title Signed math functions
library SignedMath {
    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int
    function abs(int256 value) internal pure returns (int256) {
        return value > 0 ? value : -value;
    }

    /// @notice gives the absolute value of a signed int
    /// @param value signed int
    /// @return absolute value of signed int as unsigned int
    function absUint(int256 value) internal pure returns (uint256) {
        return uint256(abs(value));
    }

    /// @notice gives the sign of a signed int
    /// @param value signed int
    /// @return -1 if negative, 1 if non-negative
    function sign(int256 value) internal pure returns (int256) {
        return value >= 0 ? ONE : -ONE;
    }

    /// @notice converts a signed integer into an unsigned integer and inverts positive bool if negative
    /// @param a signed int
    /// @param positive initial value of positive bool
    /// @return _a absolute value of int provided
    /// @return bool xor of the positive boolean and sign of the provided int
    function extractSign(int256 a, bool positive) internal pure returns (uint256 _a, bool) {
        if (a < 0) {
            positive = !positive;
            _a = uint256(-a);
        } else {
            _a = uint256(a);
        }
        return (_a, positive);
    }

    /// @notice extracts the sign of a signed int
    /// @param a signed int
    /// @return _a unsigned int
    /// @return bool sign of the provided int
    function extractSign(int256 a) internal pure returns (uint256 _a, bool) {
        return extractSign(a, true);
    }

    /// @notice returns the max of two int256 numbers
    /// @param a first number
    /// @param b second number
    /// @return c = max of a and b
    function max(int256 a, int256 b) internal pure returns (int256 c) {
        if (a > b) c = a;
        else c = b;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { LiquidityPosition } from './LiquidityPosition.sol';
import { Protocol } from './Protocol.sol';
import { Uint48Lib } from './Uint48.sol';
import { Uint48L5ArrayLib } from './Uint48L5Array.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';

/// @title Liquidity position set functions
library LiquidityPositionSet {
    using LiquidityPosition for LiquidityPosition.Info;
    using LiquidityPositionSet for LiquidityPosition.Set;
    using Protocol for Protocol.Info;
    using Uint48Lib for int24;
    using Uint48Lib for uint48;
    using Uint48L5ArrayLib for uint48[5];

    error LPS_IllegalTicks(int24 tickLower, int24 tickUpper);
    error LPS_DeactivationFailed(int24 tickLower, int24 tickUpper, uint256 liquidity);
    error LPS_InactiveRange();

    /// @notice denotes token position change due to liquidity add/remove
    /// @param accountId serial number of the account
    /// @param poolId address of token whose position was taken
    /// @param tickLower lower tick of the range updated
    /// @param tickUpper upper tick of the range updated
    /// @param vTokenAmountOut amount of tokens that account received (positive) or paid (negative)
    event TokenPositionChangedDueToLiquidityChanged(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int24 tickLower,
        int24 tickUpper,
        int256 vTokenAmountOut
    );

    /**
     *  Internal methods
     */

    /// @notice activates a position by initializing it and adding it to the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param tickLower lower tick of the range to be activated
    /// @param tickUpper upper tick of the range to be activated
    /// @return position storage ref of the activated position
    function activate(
        LiquidityPosition.Set storage set,
        int24 tickLower,
        int24 tickUpper
    ) internal returns (LiquidityPosition.Info storage position) {
        if (tickLower > tickUpper) {
            revert LPS_IllegalTicks(tickLower, tickUpper);
        }

        uint48 positionId;
        set.active.include(positionId = tickLower.concat(tickUpper));
        position = set.positions[positionId];

        if (!position.isInitialized()) {
            position.initialize(tickLower, tickUpper);
        }
    }

    /// @notice deactivates a position by removing it from the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param position storage ref to the position to be deactivated
    function deactivate(LiquidityPosition.Set storage set, LiquidityPosition.Info storage position) internal {
        if (position.liquidity != 0) {
            revert LPS_DeactivationFailed(position.tickLower, position.tickUpper, position.liquidity);
        }

        set.active.exclude(position.tickLower.concat(position.tickUpper));
    }

    /// @notice changes liquidity of a position in the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vToken
    /// @param liquidityChangeParams parameters of the liquidity change
    /// @param balanceAdjustments adjustments to made to the account's balance later
    /// @param protocol ref to the state of the protocol
    function liquidityChange(
        LiquidityPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IClearingHouseStructures.LiquidityChangeParams memory liquidityChangeParams,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        LiquidityPosition.Info storage position = set.activate(
            liquidityChangeParams.tickLower,
            liquidityChangeParams.tickUpper
        );

        position.limitOrderType = liquidityChangeParams.limitOrderType;

        set.liquidityChange(
            accountId,
            poolId,
            position,
            liquidityChangeParams.liquidityDelta,
            balanceAdjustments,
            protocol
        );
    }

    /// @notice changes liquidity of a position in the set
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vToken
    /// @param position storage ref to the position to be changed
    /// @param liquidityDelta amount of liquidity to be added or removed
    /// @param balanceAdjustments adjustments to made to the account's balance later
    /// @param protocol ref to the state of the protocol
    function liquidityChange(
        LiquidityPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        LiquidityPosition.Info storage position,
        int128 liquidityDelta,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        position.liquidityChange(accountId, poolId, liquidityDelta, balanceAdjustments, protocol);

        emit TokenPositionChangedDueToLiquidityChanged(
            accountId,
            poolId,
            position.tickLower,
            position.tickUpper,
            balanceAdjustments.vTokenIncrease
        );

        if (position.liquidity == 0) {
            set.deactivate(position);
        }
    }

    /// @notice removes liquidity from a position in the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vToken
    /// @param position storage ref to the position to be closed
    /// @param balanceAdjustments adjustments to made to the account's balance later
    /// @param protocol ref to the state of the protocol
    function closeLiquidityPosition(
        LiquidityPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        LiquidityPosition.Info storage position,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        set.liquidityChange(accountId, poolId, position, -int128(position.liquidity), balanceAdjustments, protocol);
    }

    /// @notice removes liquidity from a position in the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vToken
    /// @param currentTick current tick of the pool
    /// @param tickLower lower tick of the range to be closed
    /// @param tickUpper upper tick of the range to be closed
    /// @param balanceAdjustments adjustments to made to the account's balance later
    /// @param protocol ref to the state of the protocol
    function removeLimitOrder(
        LiquidityPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        int24 currentTick,
        int24 tickLower,
        int24 tickUpper,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        LiquidityPosition.Info storage position = set.getLiquidityPosition(tickLower, tickUpper);
        position.checkValidLimitOrderRemoval(currentTick);
        set.closeLiquidityPosition(accountId, poolId, position, balanceAdjustments, protocol);
    }

    /// @notice removes liquidity from all the positions in the set
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vToken
    /// @param balanceAdjustments adjustments to made to the account's balance later
    /// @param protocol ref to the state of the protocol
    function closeAllLiquidityPositions(
        LiquidityPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        LiquidityPosition.Info storage position;

        while (set.active[0] != 0) {
            IClearingHouseStructures.BalanceAdjustments memory balanceAdjustmentsCurrent;

            position = set.positions[set.active[0]];

            set.closeLiquidityPosition(accountId, poolId, position, balanceAdjustmentsCurrent, protocol);

            balanceAdjustments.vQuoteIncrease += balanceAdjustmentsCurrent.vQuoteIncrease;
            balanceAdjustments.vTokenIncrease += balanceAdjustmentsCurrent.vTokenIncrease;
            balanceAdjustments.traderPositionIncrease += balanceAdjustmentsCurrent.traderPositionIncrease;
        }
    }

    /**
     *  Internal view methods
     */

    /// @notice gets the liquidity position of a tick range
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param tickLower lower tick of the range to be closed
    /// @param tickUpper upper tick of the range to be closed
    /// @return position liquidity position of the tick range
    function getLiquidityPosition(
        LiquidityPosition.Set storage set,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (LiquidityPosition.Info storage position) {
        if (tickLower > tickUpper) {
            revert LPS_IllegalTicks(tickLower, tickUpper);
        }

        uint48 positionId = Uint48Lib.concat(tickLower, tickUpper);
        position = set.positions[positionId];

        if (!position.isInitialized()) revert LPS_InactiveRange();
        return position;
    }

    /// @notice gets information about all the liquidity position
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @return liquidityPositions Information about all the liquidity position for the pool
    function getInfo(LiquidityPosition.Set storage set)
        internal
        view
        returns (IClearingHouseStructures.LiquidityPositionView[] memory liquidityPositions)
    {
        uint256 numberOfTokenPositions = set.active.numberOfNonZeroElements();
        liquidityPositions = new IClearingHouseStructures.LiquidityPositionView[](numberOfTokenPositions);

        for (uint256 i = 0; i < numberOfTokenPositions; i++) {
            liquidityPositions[i].limitOrderType = set.positions[set.active[i]].limitOrderType;
            liquidityPositions[i].tickLower = set.positions[set.active[i]].tickLower;
            liquidityPositions[i].tickUpper = set.positions[set.active[i]].tickUpper;
            liquidityPositions[i].liquidity = set.positions[set.active[i]].liquidity;
            liquidityPositions[i].vTokenAmountIn = set.positions[set.active[i]].vTokenAmountIn;
            liquidityPositions[i].sumALastX128 = set.positions[set.active[i]].sumALastX128;
            liquidityPositions[i].sumBInsideLastX128 = set.positions[set.active[i]].sumBInsideLastX128;
            liquidityPositions[i].sumFpInsideLastX128 = set.positions[set.active[i]].sumFpInsideLastX128;
            liquidityPositions[i].sumFeeInsideLastX128 = set.positions[set.active[i]].sumFeeInsideLastX128;
        }
    }

    /// @notice gets the net position due to all the liquidity positions
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param sqrtPriceCurrent current sqrt price of the pool
    /// @return netPosition due to all the liquidity positions
    function getNetPosition(LiquidityPosition.Set storage set, uint160 sqrtPriceCurrent)
        internal
        view
        returns (int256 netPosition)
    {
        uint256 numberOfTokenPositions = set.active.numberOfNonZeroElements();

        for (uint256 i = 0; i < numberOfTokenPositions; i++) {
            netPosition += set.positions[set.active[i]].netPosition(sqrtPriceCurrent);
        }
    }

    /// @notice checks whether the liquidity position set is empty
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @return true if the liquidity position set is empty
    function isEmpty(LiquidityPosition.Set storage set) internal view returns (bool) {
        return set.active.isEmpty();
    }

    /// @notice checks whether for given ticks, a liquidity position is active
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param tickLower lower tick of the range
    /// @param tickUpper upper tick of the range
    /// @return true if the liquidity position is active
    function isPositionActive(
        LiquidityPosition.Set storage set,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (bool) {
        return set.active.exists(tickLower.concat(tickUpper));
    }

    /// @notice gets the total long side risk for all the active liquidity positions
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param valuationPriceX96 price used to value the vToken asset
    /// @return risk the net long side risk for all the active liquidity positions
    function longSideRisk(LiquidityPosition.Set storage set, uint160 valuationPriceX96)
        internal
        view
        returns (uint256 risk)
    {
        for (uint256 i = 0; i < set.active.length; i++) {
            uint48 id = set.active[i];
            if (id == 0) break;
            risk += set.positions[id].longSideRisk(valuationPriceX96);
        }
    }

    /// @notice gets the total market value of all the active liquidity positions
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @param sqrtPriceCurrent price used to value the vToken asset
    /// @param poolId the id of the pool
    /// @param protocol ref to the state of the protocol
    /// @return marketValue_ the total market value of all the active liquidity positions
    function marketValue(
        LiquidityPosition.Set storage set,
        uint160 sqrtPriceCurrent,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal view returns (int256 marketValue_) {
        marketValue_ = set.marketValue(sqrtPriceCurrent, protocol.vPoolWrapper(poolId));
    }

    /// @notice Get the total market value of all active liquidity positions in the set.
    /// @param set: Collection of active liquidity positions
    /// @param sqrtPriceCurrent: Current price of the virtual asset
    /// @param wrapper: address of the wrapper contract, passed once to avoid multiple sloads for wrapper
    function marketValue(
        LiquidityPosition.Set storage set,
        uint160 sqrtPriceCurrent,
        IVPoolWrapper wrapper
    ) internal view returns (int256 marketValue_) {
        for (uint256 i = 0; i < set.active.length; i++) {
            uint48 id = set.active[i];
            if (id == 0) break;
            marketValue_ += set.positions[id].marketValue(sqrtPriceCurrent, wrapper);
        }
    }

    /// @notice gets the max net position possible due to all the liquidity positions
    /// @param set storage ref to the account's set of liquidity positions of a pool
    /// @return risk the max net position possible due to all the liquidity positions
    function maxNetPosition(LiquidityPosition.Set storage set) internal view returns (uint256 risk) {
        for (uint256 i = 0; i < set.active.length; i++) {
            uint48 id = set.active[i];
            if (id == 0) break;
            risk += set.positions[id].maxNetPosition();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { SqrtPriceMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/SqrtPriceMath.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';
import { FixedPoint96 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint96.sol';

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { PriceMath } from './PriceMath.sol';
import { Protocol } from './Protocol.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { UniswapV3PoolHelper } from './UniswapV3PoolHelper.sol';
import { FundingPayment } from './FundingPayment.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';
import { IClearingHouseEnums } from '../interfaces/clearinghouse/IClearingHouseEnums.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';

/// @title Liquidity position functions
library LiquidityPosition {
    using FullMath for uint256;
    using PriceMath for uint160;
    using SafeCast for uint256;
    using SignedFullMath for int256;
    using UniswapV3PoolHelper for IUniswapV3Pool;

    using LiquidityPosition for LiquidityPosition.Info;
    using Protocol for Protocol.Info;

    struct Set {
        // multiple per pool because it's non-fungible, allows for 4 billion LP positions lifetime
        uint48[5] active;
        // concat(tickLow,tickHigh)
        mapping(uint48 => LiquidityPosition.Info) positions;
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    struct Info {
        //Extra boolean to check if it is limit order and uint to track limit price.
        IClearingHouseEnums.LimitOrderType limitOrderType;
        // the tick range of the position;
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        int256 vTokenAmountIn;
        // funding payment checkpoints
        int256 sumALastX128;
        int256 sumBInsideLastX128;
        int256 sumFpInsideLastX128;
        // fee growth inside
        uint256 sumFeeInsideLastX128;
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    error LP_AlreadyInitialized();
    error LP_IneligibleLimitOrderRemoval();

    /// @notice denotes liquidity add/remove
    /// @param accountId serial number of the account
    /// @param poolId address of token whose position was taken
    /// @param tickLower lower tick of the range updated
    /// @param tickUpper upper tick of the range updated
    /// @param liquidityDelta change in liquidity value
    /// @param limitOrderType the type of range position
    /// @param vTokenAmountOut amount of tokens that account received (positive) or paid (negative)
    /// @param vQuoteAmountOut amount of vQuote tokens that account received (positive) or paid (negative)
    event LiquidityChanged(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        IClearingHouseEnums.LimitOrderType limitOrderType,
        int256 vTokenAmountOut,
        int256 vQuoteAmountOut,
        uint160 sqrtPriceX96
    );

    /// @param accountId serial number of the account
    /// @param poolId address of token for which funding was paid
    /// @param tickLower lower tick of the range for which funding was paid
    /// @param tickUpper upper tick of the range for which funding was paid
    /// @param amount amount of funding paid (negative) or received (positive)
    /// @param sumALastX128 val of sum of the term A in funding payment math, when op took place
    /// @param sumBInsideLastX128 val of sum of the term B in funding payment math, when op took place
    /// @param sumFpInsideLastX128 val of sum of the term Fp in funding payment math, when op took place
    /// @param sumFeeInsideLastX128 val of sum of the term Fee in wrapper, when op took place
    event LiquidityPositionFundingPaymentRealized(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int24 tickLower,
        int24 tickUpper,
        int256 amount,
        int256 sumALastX128,
        int256 sumBInsideLastX128,
        int256 sumFpInsideLastX128,
        uint256 sumFeeInsideLastX128
    );

    /// @notice denotes fee payment for a range / token position
    /// @dev for a token position tickLower = tickUpper = 0
    /// @param accountId serial number of the account
    /// @param poolId address of token for which fee was paid
    /// @param tickLower lower tick of the range for which fee was paid
    /// @param tickUpper upper tick of the range for which fee was paid
    /// @param amount amount of fee paid (negative) or received (positive)
    event LiquidityPositionEarningsRealized(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int24 tickLower,
        int24 tickUpper,
        int256 amount
    );

    /**
     *  Internal methods
     */

    /// @notice initializes a new LiquidityPosition.Info struct
    /// @dev Reverts if the position is already initialized
    /// @param position storage pointer of the position to initialize
    /// @param tickLower lower tick of the range
    /// @param tickUpper upper tick of the range
    function initialize(
        LiquidityPosition.Info storage position,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        if (position.isInitialized()) {
            revert LP_AlreadyInitialized();
        }

        position.tickLower = tickLower;
        position.tickUpper = tickUpper;
    }

    /// @notice changes liquidity for a position, informs pool wrapper and does necessary bookkeeping
    /// @param position storage ref of the position to update
    /// @param accountId serial number of the account, used to emit event
    /// @param poolId id of the pool for which position was updated
    /// @param liquidityDelta change in liquidity value
    /// @param balanceAdjustments memory ref to the balance adjustments struct
    /// @param protocol ref to the protocol state
    function liquidityChange(
        LiquidityPosition.Info storage position,
        uint256 accountId,
        uint32 poolId,
        int128 liquidityDelta,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        Protocol.Info storage protocol
    ) internal {
        int256 vTokenPrincipal;
        int256 vQuotePrincipal;

        IVPoolWrapper wrapper = protocol.vPoolWrapper(poolId);
        IVPoolWrapper.WrapperValuesInside memory wrapperValuesInside;

        // calls wrapper to mint/burn liquidity
        if (liquidityDelta > 0) {
            uint256 vTokenPrincipal_;
            uint256 vQuotePrincipal_;
            (vTokenPrincipal_, vQuotePrincipal_, wrapperValuesInside) = wrapper.mint(
                position.tickLower,
                position.tickUpper,
                uint128(liquidityDelta)
            );
            vTokenPrincipal = vTokenPrincipal_.toInt256();
            vQuotePrincipal = vQuotePrincipal_.toInt256();
        } else {
            uint256 vTokenPrincipal_;
            uint256 vQuotePrincipal_;
            (vTokenPrincipal_, vQuotePrincipal_, wrapperValuesInside) = wrapper.burn(
                position.tickLower,
                position.tickUpper,
                uint128(-liquidityDelta)
            );
            vTokenPrincipal = -vTokenPrincipal_.toInt256();
            vQuotePrincipal = -vQuotePrincipal_.toInt256();
        }

        // calculate funding payment and liquidity fees then update checkpoints
        position.update(accountId, poolId, wrapperValuesInside, balanceAdjustments);

        // adjust in the token acounts
        balanceAdjustments.vQuoteIncrease -= vQuotePrincipal;
        balanceAdjustments.vTokenIncrease -= vTokenPrincipal;

        // emit the event
        uint160 sqrtPriceCurrent = protocol.vPool(poolId).sqrtPriceCurrent();
        emitLiquidityChangeEvent(
            position,
            accountId,
            poolId,
            liquidityDelta,
            sqrtPriceCurrent,
            -vTokenPrincipal,
            -vQuotePrincipal
        );

        // update trader position increase
        int256 vTokenAmountCurrent;
        {
            (vTokenAmountCurrent, ) = position.vTokenAmountsInRange(sqrtPriceCurrent, false);
            balanceAdjustments.traderPositionIncrease += (vTokenAmountCurrent - position.vTokenAmountIn);
        }

        uint128 liquidityNew = position.liquidity;
        if (liquidityDelta > 0) {
            liquidityNew += uint128(liquidityDelta);
        } else if (liquidityDelta < 0) {
            liquidityNew -= uint128(-liquidityDelta);
        }

        if (liquidityNew != 0) {
            // update state
            position.liquidity = liquidityNew;
            position.vTokenAmountIn = vTokenAmountCurrent + vTokenPrincipal;
        } else {
            // clear all the state
            position.liquidity = 0;
            position.vTokenAmountIn = 0;
            position.sumALastX128 = 0;
            position.sumBInsideLastX128 = 0;
            position.sumFpInsideLastX128 = 0;
            position.sumFeeInsideLastX128 = 0;
        }
    }

    /// @notice updates the position with latest checkpoints, and realises fees and fp
    /// @dev fees and funding payment are not immediately adjusted in token balance state,
    ///     balanceAdjustments struct is used to pass the necessary values to caller.
    /// @param position storage ref of the position to update
    /// @param accountId serial number of the account, used to emit event
    /// @param poolId id of the pool for which position was updated
    /// @param wrapperValuesInside range checkpoint values from the wrapper
    /// @param balanceAdjustments memory ref to the balance adjustments struct
    function update(
        LiquidityPosition.Info storage position,
        uint256 accountId,
        uint32 poolId,
        IVPoolWrapper.WrapperValuesInside memory wrapperValuesInside,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments
    ) internal {
        int256 fundingPayment = position.unrealizedFundingPayment(
            wrapperValuesInside.sumAX128,
            wrapperValuesInside.sumFpInsideX128
        );
        balanceAdjustments.vQuoteIncrease += fundingPayment;

        int256 unrealizedLiquidityFee = position.unrealizedFees(wrapperValuesInside.sumFeeInsideX128).toInt256();
        balanceAdjustments.vQuoteIncrease += unrealizedLiquidityFee;

        // updating checkpoints
        position.sumALastX128 = wrapperValuesInside.sumAX128;
        position.sumBInsideLastX128 = wrapperValuesInside.sumBInsideX128;
        position.sumFpInsideLastX128 = wrapperValuesInside.sumFpInsideX128;
        position.sumFeeInsideLastX128 = wrapperValuesInside.sumFeeInsideX128;

        emit LiquidityPositionFundingPaymentRealized(
            accountId,
            poolId,
            position.tickLower,
            position.tickUpper,
            fundingPayment,
            wrapperValuesInside.sumAX128,
            wrapperValuesInside.sumBInsideX128,
            wrapperValuesInside.sumFpInsideX128,
            wrapperValuesInside.sumFeeInsideX128
        );

        emit LiquidityPositionEarningsRealized(
            accountId,
            poolId,
            position.tickLower,
            position.tickUpper,
            unrealizedLiquidityFee
        );
    }

    /**
     *  Internal view methods
     */

    /// @notice ensures that limit order removal is valid, else reverts
    /// @param info storage ref of the position to check
    /// @param currentTick current tick in the pool
    function checkValidLimitOrderRemoval(LiquidityPosition.Info storage info, int24 currentTick) internal view {
        if (
            !((currentTick >= info.tickUpper &&
                info.limitOrderType == IClearingHouseEnums.LimitOrderType.UPPER_LIMIT) ||
                (currentTick <= info.tickLower &&
                    info.limitOrderType == IClearingHouseEnums.LimitOrderType.LOWER_LIMIT))
        ) {
            revert LP_IneligibleLimitOrderRemoval();
        }
    }

    /// @notice checks if the position is initialized
    /// @param info storage ref of the position to check
    /// @return true if the position is initialized
    function isInitialized(LiquidityPosition.Info storage info) internal view returns (bool) {
        return info.tickLower != 0 || info.tickUpper != 0;
    }

    /// @notice calculates the long side risk for the position
    /// @param position storage ref of the position to check
    /// @param valuationSqrtPriceX96 valuation sqrt price in x96
    /// @return long side risk
    function longSideRisk(LiquidityPosition.Info storage position, uint160 valuationSqrtPriceX96)
        internal
        view
        returns (uint256)
    {
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);
        uint256 longPositionExecutionPriceX128;
        {
            uint160 sqrtPriceUpperMinX96 = valuationSqrtPriceX96 <= sqrtPriceUpperX96
                ? valuationSqrtPriceX96
                : sqrtPriceUpperX96;
            uint160 sqrtPriceLowerMinX96 = valuationSqrtPriceX96 <= sqrtPriceLowerX96
                ? valuationSqrtPriceX96
                : sqrtPriceLowerX96;
            longPositionExecutionPriceX128 = uint256(sqrtPriceLowerMinX96).mulDiv(sqrtPriceUpperMinX96, 1 << 64);
        }

        uint256 maxNetLongPosition;
        {
            uint256 maxLongTokens = SqrtPriceMath.getAmount0Delta(
                sqrtPriceLowerX96,
                sqrtPriceUpperX96,
                position.liquidity,
                true
            );
            //
            if (position.vTokenAmountIn >= 0) {
                //maxLongTokens in range should always be >= amount that got added to range, equality occurs when range was added at pCurrent = pHigh
                assert(maxLongTokens >= uint256(position.vTokenAmountIn));
                maxNetLongPosition = maxLongTokens - uint256(position.vTokenAmountIn);
            } else maxNetLongPosition = maxLongTokens + uint256(-1 * position.vTokenAmountIn);
        }

        return maxNetLongPosition.mulDiv(longPositionExecutionPriceX128, FixedPoint128.Q128);
    }

    /// @notice calculates the market value for the position using a provided price
    /// @param position storage ref of the position to check
    /// @param valuationSqrtPriceX96 valuation sqrt price to be used
    /// @param wrapper address of the pool wrapper
    /// @return marketValue_ the market value of the position
    function marketValue(
        LiquidityPosition.Info storage position,
        uint160 valuationSqrtPriceX96,
        IVPoolWrapper wrapper
    ) internal view returns (int256 marketValue_) {
        {
            (int256 vTokenAmount, int256 vQuoteAmount) = position.vTokenAmountsInRange(valuationSqrtPriceX96, false);
            uint256 priceX128 = valuationSqrtPriceX96.toPriceX128();
            marketValue_ = vTokenAmount.mulDiv(priceX128, FixedPoint128.Q128) + vQuoteAmount;
        }
        // adding fees
        IVPoolWrapper.WrapperValuesInside memory wrapperValuesInside = wrapper.getExtrapolatedValuesInside(
            position.tickLower,
            position.tickUpper
        );
        marketValue_ += position.unrealizedFees(wrapperValuesInside.sumFeeInsideX128).toInt256();
        marketValue_ += position.unrealizedFundingPayment(
            wrapperValuesInside.sumAX128,
            wrapperValuesInside.sumFpInsideX128
        );
    }

    /// @notice calculates the max net position for the position
    /// @param position storage ref of the position to check
    /// @return maxNetPosition the max net position of the position
    function maxNetPosition(LiquidityPosition.Info storage position) internal view returns (uint256) {
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);

        if (position.vTokenAmountIn >= 0)
            return
                SqrtPriceMath.getAmount0Delta(sqrtPriceLowerX96, sqrtPriceUpperX96, position.liquidity, true) -
                uint256(position.vTokenAmountIn);
        else
            return
                SqrtPriceMath.getAmount0Delta(sqrtPriceLowerX96, sqrtPriceUpperX96, position.liquidity, true) +
                uint256(-1 * position.vTokenAmountIn);
    }

    /// @notice calculates the current net position for the position
    /// @param position storage ref of the position to check
    /// @param sqrtPriceCurrent the current sqrt price, used to calculate net position
    /// @return netTokenPosition the current net position of the position
    function netPosition(LiquidityPosition.Info storage position, uint160 sqrtPriceCurrent)
        internal
        view
        returns (int256 netTokenPosition)
    {
        int256 vTokenAmountCurrent;
        (vTokenAmountCurrent, ) = position.vTokenAmountsInRange(sqrtPriceCurrent, false);
        netTokenPosition = (vTokenAmountCurrent - position.vTokenAmountIn);
    }

    /// @notice calculates the current virtual token amounts for the position
    /// @param position storage ref of the position to check
    /// @param sqrtPriceCurrent the current sqrt price, used to calculate virtual token amounts
    /// @param roundUp whether to round up the token amounts, purpose to charge user more and give less
    /// @return vTokenAmount the current vToken amount
    /// @return vQuoteAmount the current vQuote amount
    function vTokenAmountsInRange(
        LiquidityPosition.Info storage position,
        uint160 sqrtPriceCurrent,
        bool roundUp
    ) internal view returns (int256 vTokenAmount, int256 vQuoteAmount) {
        uint160 sqrtPriceLowerX96 = TickMath.getSqrtRatioAtTick(position.tickLower);
        uint160 sqrtPriceUpperX96 = TickMath.getSqrtRatioAtTick(position.tickUpper);

        // If price is outside the range, then consider it at the ends
        // for calculation of amounts
        uint160 sqrtPriceMiddleX96 = sqrtPriceCurrent;
        if (sqrtPriceCurrent < sqrtPriceLowerX96) {
            sqrtPriceMiddleX96 = sqrtPriceLowerX96;
        } else if (sqrtPriceCurrent > sqrtPriceUpperX96) {
            sqrtPriceMiddleX96 = sqrtPriceUpperX96;
        }

        vTokenAmount = SqrtPriceMath
            .getAmount0Delta(sqrtPriceMiddleX96, sqrtPriceUpperX96, position.liquidity, roundUp)
            .toInt256();
        vQuoteAmount = SqrtPriceMath
            .getAmount1Delta(sqrtPriceLowerX96, sqrtPriceMiddleX96, position.liquidity, roundUp)
            .toInt256();
    }

    /// @notice returns vQuoteIncrease due to unrealised funding payment for the liquidity position (+ve means receiving and -ve means giving)
    /// @param position storage ref of the position to check
    /// @param sumAX128 the sumA value from the pool wrapper
    /// @param sumFpInsideX128 the sumFp in the position's range from the pool wrapper
    /// @return vQuoteIncrease the amount of vQuote that should be added to the account's vQuote balance
    function unrealizedFundingPayment(
        LiquidityPosition.Info storage position,
        int256 sumAX128,
        int256 sumFpInsideX128
    ) internal view returns (int256 vQuoteIncrease) {
        // subtract the bill from the account's vQuote balance
        vQuoteIncrease = -FundingPayment.bill(
            sumAX128,
            sumFpInsideX128,
            position.sumALastX128,
            position.sumBInsideLastX128,
            position.sumFpInsideLastX128,
            position.liquidity
        );
    }

    /// @notice calculates the unrealised lp fees for the position
    /// @param position storage ref of the position to check
    /// @param sumFeeInsideX128 the global sumFee in the position's range from the pool wrapper
    /// @return vQuoteIncrease the amount of vQuote that should be added to the account's vQuote balance
    function unrealizedFees(LiquidityPosition.Info storage position, uint256 sumFeeInsideX128)
        internal
        view
        returns (uint256 vQuoteIncrease)
    {
        vQuoteIncrease = (sumFeeInsideX128 - position.sumFeeInsideLastX128).mulDiv(
            position.liquidity,
            FixedPoint128.Q128
        );
    }

    function emitLiquidityChangeEvent(
        LiquidityPosition.Info storage position,
        uint256 accountId,
        uint32 poolId,
        int128 liquidityDelta,
        uint160 sqrtPriceX96,
        int256 vTokenAmountOut,
        int256 vQuoteAmountOut
    ) internal {
        emit LiquidityChanged(
            accountId,
            poolId,
            position.tickLower,
            position.tickUpper,
            liquidityDelta,
            position.limitOrderType,
            vTokenAmountOut,
            vQuoteAmountOut,
            sqrtPriceX96
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';
import { IVQuote } from '../interfaces/IVQuote.sol';
import { IVToken } from '../interfaces/IVToken.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';

import { PriceMath } from './PriceMath.sol';
import { SafeCast } from './SafeCast.sol';
import { SignedMath } from './SignedMath.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { UniswapV3PoolHelper } from './UniswapV3PoolHelper.sol';
import { Block } from './Block.sol';
import { SafeCast } from './SafeCast.sol';

/// @title Protocol storage functions
/// @dev This is used as main storage interface containing protocol info
library Protocol {
    using FullMath for uint256;
    using PriceMath for uint160;
    using PriceMath for uint256;
    using SignedMath for int256;
    using SignedFullMath for int256;
    using SafeCast for uint256;
    using UniswapV3PoolHelper for IUniswapV3Pool;
    using SafeCast for uint256;

    using Protocol for Protocol.Info;

    struct PriceCache {
        uint32 updateBlockNumber;
        uint224 virtualPriceX128;
        uint224 realPriceX128;
        bool isDeviationBreached;
    }
    struct Info {
        // poolId => PoolInfo
        mapping(uint32 => IClearingHouseStructures.Pool) pools;
        // collateralId => CollateralInfo
        mapping(uint32 => IClearingHouseStructures.Collateral) collaterals;
        // iterable and increasing list of pools (used for admin functions)
        uint32[] poolIds;
        // settlement token (default collateral)
        IERC20 settlementToken;
        // virtual quote token (sort of fake USDC), is always token1 in uniswap pools
        IVQuote vQuote;
        // accounting settings
        IClearingHouseStructures.LiquidationParams liquidationParams;
        uint256 minRequiredMargin;
        uint256 removeLimitOrderFee;
        uint256 minimumOrderNotional;
        // price cache
        mapping(uint32 => PriceCache) priceCache;
        // reserved for adding slots in future
        uint256[100] _emptySlots;
    }

    function updatePoolPriceCache(Protocol.Info storage protocol, uint32 poolId) internal {
        uint32 blockNumber = Block.number();

        PriceCache storage poolPriceCache = protocol.priceCache[poolId];
        if (poolPriceCache.updateBlockNumber == blockNumber) {
            return;
        }

        uint256 realPriceX128 = protocol.getRealTwapPriceX128(poolId);
        uint256 virtualPriceX128 = protocol.getVirtualTwapPriceX128(poolId);

        // In case the price is breaching the Q224 limit, we do not cache it
        uint256 Q224 = 1 << 224;
        if (realPriceX128 >= Q224 || virtualPriceX128 >= Q224) {
            return;
        }

        uint16 maxDeviationBps = protocol.pools[poolId].settings.maxVirtualPriceDeviationRatioBps;
        if (
            // if virtual price is too off from real price then screw that, we'll just use real price
            (int256(realPriceX128) - int256(virtualPriceX128)).absUint() > realPriceX128.mulDiv(maxDeviationBps, 1e4)
        ) {
            poolPriceCache.isDeviationBreached = true;
        } else {
            poolPriceCache.isDeviationBreached = false;
        }
        poolPriceCache.realPriceX128 = realPriceX128.toUint224();
        poolPriceCache.virtualPriceX128 = virtualPriceX128.toUint224();
        poolPriceCache.updateBlockNumber = blockNumber;
    }

    /// @notice gets the uniswap v3 pool address for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return UniswapV3Pool contract object
    function vPool(Protocol.Info storage protocol, uint32 poolId) internal view returns (IUniswapV3Pool) {
        return protocol.pools[poolId].vPool;
    }

    /// @notice gets the wrapper address for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return VPoolWrapper contract object
    function vPoolWrapper(Protocol.Info storage protocol, uint32 poolId) internal view returns (IVPoolWrapper) {
        return protocol.pools[poolId].vPoolWrapper;
    }

    /// @notice gets the virtual twap sqrt price for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return sqrtPriceX96 virtual twap sqrt price
    function getVirtualTwapSqrtPriceX96(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint160 sqrtPriceX96)
    {
        IClearingHouseStructures.Pool storage pool = protocol.pools[poolId];
        return pool.vPool.twapSqrtPrice(pool.settings.twapDuration);
    }

    /// @notice gets the virtual current sqrt price for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return sqrtPriceX96 virtual current sqrt price
    function getVirtualCurrentSqrtPriceX96(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint160 sqrtPriceX96)
    {
        return protocol.pools[poolId].vPool.sqrtPriceCurrent();
    }

    /// @notice gets the virtual current tick for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return tick virtual current tick
    function getVirtualCurrentTick(Protocol.Info storage protocol, uint32 poolId) internal view returns (int24 tick) {
        return protocol.pools[poolId].vPool.tickCurrent();
    }

    /// @notice gets the virtual twap price for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return priceX128 virtual twap price
    function getVirtualTwapPriceX128(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 priceX128)
    {
        return protocol.getVirtualTwapSqrtPriceX96(poolId).toPriceX128();
    }

    /// @notice gets the virtual current price for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return priceX128 virtual current price
    function getVirtualCurrentPriceX128(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 priceX128)
    {
        return protocol.getVirtualCurrentSqrtPriceX96(poolId).toPriceX128();
    }

    /// @notice gets the real twap price for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return priceX128 virtual twap price
    function getRealTwapPriceX128(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 priceX128)
    {
        IClearingHouseStructures.Pool storage pool = protocol.pools[poolId];
        return pool.settings.oracle.getTwapPriceX128(pool.settings.twapDuration);
    }

    /// @notice gets the twap prices with deviation check for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return realPriceX128 the real price
    /// @return virtualPriceX128 the virtual price if under deviation else real price
    function getTwapPricesWithDeviationCheck(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 realPriceX128, uint256 virtualPriceX128)
    {
        realPriceX128 = protocol.getRealTwapPriceX128(poolId);
        virtualPriceX128 = protocol.getVirtualTwapPriceX128(poolId);

        uint16 maxDeviationBps = protocol.pools[poolId].settings.maxVirtualPriceDeviationRatioBps;
        uint256 priceDeltaX128 = realPriceX128 > virtualPriceX128
            ? realPriceX128 - virtualPriceX128
            : virtualPriceX128 - realPriceX128;
        if (priceDeltaX128 > realPriceX128.mulDiv(maxDeviationBps, 1e4)) {
            // if virtual price is too off from real price then screw that, we'll just use real price
            virtualPriceX128 = realPriceX128;
        }
        return (realPriceX128, virtualPriceX128);
    }

    function getCachedVirtualTwapPriceX128(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 priceX128)
    {
        uint32 blockNumber = Block.number();

        PriceCache storage poolPriceCache = protocol.priceCache[poolId];
        if (poolPriceCache.updateBlockNumber == blockNumber) {
            return poolPriceCache.virtualPriceX128;
        } else {
            return protocol.getVirtualTwapPriceX128(poolId);
        }
    }

    function getCachedTwapPricesWithDeviationCheck(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 realPriceX128, uint256 virtualPriceX128)
    {
        uint32 blockNumber = Block.number();

        PriceCache storage poolPriceCache = protocol.priceCache[poolId];
        if (poolPriceCache.updateBlockNumber == blockNumber) {
            if (poolPriceCache.isDeviationBreached) {
                return (poolPriceCache.realPriceX128, poolPriceCache.realPriceX128);
            } else {
                return (poolPriceCache.realPriceX128, poolPriceCache.virtualPriceX128);
            }
        } else {
            return protocol.getTwapPricesWithDeviationCheck(poolId);
        }
    }

    function getCachedRealTwapPriceX128(Protocol.Info storage protocol, uint32 poolId)
        internal
        view
        returns (uint256 priceX128)
    {
        uint32 blockNumber = Block.number();

        PriceCache storage poolPriceCache = protocol.priceCache[poolId];
        if (poolPriceCache.updateBlockNumber == blockNumber) {
            return poolPriceCache.realPriceX128;
        } else {
            return protocol.getRealTwapPriceX128(poolId);
        }
    }

    /// @notice gets the margin ratio for a poolId
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @param isInitialMargin whether to use initial margin or maintainance margin
    /// @return margin rato in bps
    function getMarginRatioBps(
        Protocol.Info storage protocol,
        uint32 poolId,
        bool isInitialMargin
    ) internal view returns (uint16) {
        if (isInitialMargin) {
            return protocol.pools[poolId].settings.initialMarginRatioBps;
        } else {
            return protocol.pools[poolId].settings.maintainanceMarginRatioBps;
        }
    }

    /// @notice checks if the pool is cross margined
    /// @param protocol ref to the protocol state
    /// @param poolId the poolId of the pool
    /// @return bool whether the pool is cross margined
    function isPoolCrossMargined(Protocol.Info storage protocol, uint32 poolId) internal view returns (bool) {
        return protocol.pools[poolId].settings.isCrossMargined;
    }

    /// @notice Gives notional value of the given vToken and vQuote amounts
    /// @param protocol platform constants
    /// @param poolId id of the rage trade pool
    /// @param vTokenAmount amount of tokens
    /// @param vQuoteAmount amount of base
    /// @return notionalValue for the given token and vQuote amounts
    function getNotionalValue(
        Protocol.Info storage protocol,
        uint32 poolId,
        int256 vTokenAmount,
        int256 vQuoteAmount
    ) internal view returns (uint256 notionalValue) {
        return
            vTokenAmount.absUint().mulDiv(protocol.getCachedVirtualTwapPriceX128(poolId), FixedPoint128.Q128) +
            vQuoteAmount.absUint();
    }

    /// @notice Gives notional value of the given token amount
    /// @param protocol platform constants
    /// @param poolId id of the rage trade pool
    /// @param vTokenAmount amount of tokens
    /// @return notionalValue for the given token and vQuote amounts
    function getNotionalValue(
        Protocol.Info storage protocol,
        uint32 poolId,
        int256 vTokenAmount
    ) internal view returns (uint256 notionalValue) {
        return protocol.getNotionalValue(poolId, vTokenAmount, 0);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { FundingPayment } from './FundingPayment.sol';
import { LiquidityPosition } from './LiquidityPosition.sol';
import { LiquidityPositionSet } from './LiquidityPositionSet.sol';
import { Protocol } from './Protocol.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { UniswapV3PoolHelper } from './UniswapV3PoolHelper.sol';

import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';

/// @title VToken position functions
library VTokenPosition {
    using FullMath for uint256;
    using SignedFullMath for int256;
    using UniswapV3PoolHelper for IUniswapV3Pool;

    using LiquidityPosition for LiquidityPosition.Info;
    using LiquidityPositionSet for LiquidityPosition.Set;
    using Protocol for Protocol.Info;

    enum RISK_SIDE {
        LONG,
        SHORT
    }

    struct Set {
        // Fixed length array of poolId = vTokenAddress.truncate()
        // Open positions in 8 different pairs at same time.
        // Collision between poolId is not possible.
        uint32[8] active; // array of poolIds
        mapping(uint32 => VTokenPosition.Info) positions; // poolId => Position
        int256 vQuoteBalance;
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    struct Info {
        int256 balance; // vTokenLong - vTokenShort
        int256 netTraderPosition;
        int256 sumALastX128;
        // this is moved from accounts to here because of the in margin available check
        // the loop needs to be done over liquidity positions of same token only
        LiquidityPosition.Set liquidityPositions;
        uint256[100] _emptySlots; // reserved for adding variables when upgrading logic
    }

    /// @notice Gives the market value of the supplied token position
    /// @param position token position
    /// @param priceX128 price in Q128
    /// @param wrapper pool wrapper corresponding to position
    /// @return value market value with 6 decimals
    function marketValue(
        VTokenPosition.Info storage position,
        uint256 priceX128,
        IVPoolWrapper wrapper
    ) internal view returns (int256 value) {
        value = position.balance.mulDiv(priceX128, FixedPoint128.Q128);
        value += unrealizedFundingPayment(position, wrapper);
    }

    /// @notice returns the market value of the supplied token position
    /// @param position token position
    /// @param priceX128 price in Q128
    /// @param poolId id of the rage trade pool
    /// @param protocol ref to the protocol state
    function marketValue(
        VTokenPosition.Info storage position,
        uint32 poolId,
        uint256 priceX128,
        Protocol.Info storage protocol
    ) internal view returns (int256 value) {
        return marketValue(position, priceX128, protocol.vPoolWrapper(poolId));
    }

    /// @notice returns the market value of the supplied token position
    /// @param position token position
    /// @param poolId id of the rage trade pool
    /// @param protocol ref to the protocol state
    function marketValue(
        VTokenPosition.Info storage position,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal view returns (int256) {
        uint256 priceX128 = protocol.getCachedVirtualTwapPriceX128(poolId);
        return marketValue(position, poolId, priceX128, protocol);
    }

    function riskSide(VTokenPosition.Info storage position) internal view returns (RISK_SIDE) {
        return position.balance > 0 ? RISK_SIDE.LONG : RISK_SIDE.SHORT;
    }

    /// @notice returns the vQuoteIncrease due to unrealized funding payment for the trader position (+ve means receiving and -ve means paying)
    /// @param position token position
    /// @param wrapper pool wrapper corresponding to position
    /// @return unrealizedFpBill funding to be realized (+ve means receive and -ve means pay)
    function unrealizedFundingPayment(VTokenPosition.Info storage position, IVPoolWrapper wrapper)
        internal
        view
        returns (int256)
    {
        int256 extrapolatedSumAX128 = wrapper.getExtrapolatedSumAX128();
        int256 vQuoteIncrease = -FundingPayment.bill(
            extrapolatedSumAX128,
            position.sumALastX128,
            position.netTraderPosition
        );
        return vQuoteIncrease;
    }

    /// @notice gets the account's net position for a given poolId
    /// @param position token position
    /// @param poolId id of the rage trade pool
    /// @param protocol ref to the protocol state
    /// @return net position
    function getNetPosition(
        VTokenPosition.Info storage position,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal view returns (int256) {
        return
            position.netTraderPosition +
            position.liquidityPositions.getNetPosition(protocol.vPool(poolId).sqrtPriceCurrent());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { SafeCast } from '@uniswap/v3-core-0.8-support/contracts/libraries/SafeCast.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';

import { AddressHelper } from './AddressHelper.sol';
import { LiquidityPosition } from './LiquidityPosition.sol';
import { LiquidityPositionSet } from './LiquidityPositionSet.sol';
import { Protocol } from './Protocol.sol';
import { PriceMath } from './PriceMath.sol';
import { SignedFullMath } from './SignedFullMath.sol';
import { SignedMath } from './SignedMath.sol';
import { VTokenPosition } from './VTokenPosition.sol';
import { Uint32L8ArrayLib } from './Uint32L8Array.sol';

import { IClearingHouseStructures } from '../interfaces/clearinghouse/IClearingHouseStructures.sol';
import { IVPoolWrapper } from '../interfaces/IVPoolWrapper.sol';
import { IVToken } from '../interfaces/IVToken.sol';

/// @title VToken position set functions
library VTokenPositionSet {
    using AddressHelper for address;
    using FullMath for uint256;
    using PriceMath for uint256;
    using SafeCast for uint256;
    using SignedFullMath for int256;
    using SignedMath for int256;
    using Uint32L8ArrayLib for uint32[8];

    using LiquidityPositionSet for LiquidityPosition.Set;
    using Protocol for Protocol.Info;
    using VTokenPosition for VTokenPosition.Info;
    using VTokenPositionSet for VTokenPosition.Set;

    error VPS_IncorrectUpdate();
    error VPS_DeactivationFailed(uint32 poolId);
    error VPS_TokenInactive(uint32 poolId);

    /// @notice denotes token position change
    /// @param accountId serial number of the account
    /// @param poolId truncated address of vtoken whose position was taken
    /// @param vTokenAmountOut amount of tokens that account received (positive) or paid (negative)
    /// @param vQuoteAmountOut amount of vQuote tokens that account received (positive) or paid (negative)
    /// @param sqrtPriceX96Start shows the sqrtPriceX96 at the start of trade execution, can be 0 if not on v3Pool
    /// @param sqrtPriceX96End shows the sqrtPriceX96 at the end of trade execution, can be 0 if not on v3Pool
    event TokenPositionChanged(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int256 vTokenAmountOut,
        int256 vQuoteAmountOut,
        uint160 sqrtPriceX96Start,
        uint160 sqrtPriceX96End
    );

    /// @notice denotes funding payment for a range / token position
    /// @param accountId serial number of the account
    /// @param poolId address of token for which funding was paid
    /// @param amount amount of funding paid (negative) or received (positive)
    /// @param sumALastX128 val of sum of the term A in funding payment math, when op took place
    event TokenPositionFundingPaymentRealized(
        uint256 indexed accountId,
        uint32 indexed poolId,
        int256 amount,
        int256 sumALastX128
    );

    /**
     *  Internal methods
     */

    /// @notice activates token with address 'vToken' if not already active
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    function activate(VTokenPosition.Set storage set, uint32 poolId) internal {
        set.active.include(poolId);
    }

    /// @notice deactivates token with address 'vToken'
    /// @dev ensures that the balance is 0 and there are not range positions active otherwise throws an error
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    function deactivate(VTokenPosition.Set storage set, uint32 poolId) internal {
        if (set.positions[poolId].balance != 0 || !set.positions[poolId].liquidityPositions.isEmpty()) {
            revert VPS_DeactivationFailed(poolId);
        }

        set.active.exclude(poolId);
    }

    /// @notice updates token balance, net trader position and vQuote balance
    /// @dev realizes funding payment to vQuote balance
    /// @dev activates the token if not already active
    /// @dev deactivates the token if the balance = 0 and there are no range positions active
    /// @dev IMP: ensure that the global states are updated using zeroSwap or directly through some interaction with pool wrapper
    /// @param set VTokenPositionSet
    /// @param balanceAdjustments platform constants
    /// @param poolId id of the rage trade pool
    /// @param accountId account identifier, used for emitting event
    /// @param protocol platform constants
    function update(
        VTokenPosition.Set storage set,
        uint256 accountId,
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal {
        set.realizeFundingPayment(accountId, poolId, protocol);
        set.active.include(poolId);

        VTokenPosition.Info storage _VTokenPosition = set.positions[poolId];
        _VTokenPosition.balance += balanceAdjustments.vTokenIncrease;
        _VTokenPosition.netTraderPosition += balanceAdjustments.traderPositionIncrease;

        set.vQuoteBalance += balanceAdjustments.vQuoteIncrease;

        if (_VTokenPosition.balance == 0 && _VTokenPosition.liquidityPositions.active[0] == 0) {
            set.deactivate(poolId);
        }
    }

    /// @notice realizes funding payment to vQuote balance
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    /// @param accountId account identifier, used for emitting event
    /// @param protocol platform constants
    function realizeFundingPayment(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal {
        set.realizeFundingPayment(accountId, poolId, protocol.pools[poolId].vPoolWrapper);
    }

    /// @notice realizes funding payment to vQuote balance
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    /// @param accountId account identifier, used for emitting event
    /// @param wrapper VPoolWrapper to override the set wrapper
    function realizeFundingPayment(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IVPoolWrapper wrapper
    ) internal {
        VTokenPosition.Info storage position = set.positions[poolId];
        int256 extrapolatedSumAX128 = wrapper.getSumAX128();

        int256 fundingPayment = position.unrealizedFundingPayment(wrapper);
        set.vQuoteBalance += fundingPayment;

        position.sumALastX128 = extrapolatedSumAX128;

        emit TokenPositionFundingPaymentRealized(accountId, poolId, fundingPayment, extrapolatedSumAX128);
    }

    /// @notice swaps tokens (Long and Short) with input in token amount / vQuote amount
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param swapParams parameters for swap
    /// @param protocol platform constants
    /// @return vTokenAmountOut - token amount coming out of pool
    /// @return vQuoteAmountOut - vQuote amount coming out of pool
    function swapToken(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IClearingHouseStructures.SwapParams memory swapParams,
        Protocol.Info storage protocol
    ) internal returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        return set.swapToken(accountId, poolId, swapParams, protocol.vPoolWrapper(poolId), protocol);
    }

    /// @notice swaps tokens (Long and Short) with input in token amount
    /// @dev activates inactive vToe
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param vTokenAmount amount of the token
    /// @param protocol platform constants
    /// @return vTokenAmountOut - token amount coming out of pool
    /// @return vQuoteAmountOut - vQuote amount coming out of pool
    function swapTokenAmount(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        int256 vTokenAmount,
        Protocol.Info storage protocol
    ) internal returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        return
            set.swapToken(
                accountId,
                poolId,
                /// @dev 0 means no price limit and false means amount mentioned is token amount
                IClearingHouseStructures.SwapParams({
                    amount: vTokenAmount,
                    sqrtPriceLimit: 0,
                    isNotional: false,
                    isPartialAllowed: false,
                    settleProfit: false
                }),
                protocol.vPoolWrapper(poolId),
                protocol
            );
    }

    /// @notice swaps tokens (Long and Short) with input in token amount / vQuote amount
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param swapParams parameters for swap
    /// @param wrapper VPoolWrapper to override the set wrapper
    /// @param protocol platform constants
    /// @return vTokenAmountOut - token amount coming out of pool
    /// @return vQuoteAmountOut - vQuote amount coming out of pool
    function swapToken(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IClearingHouseStructures.SwapParams memory swapParams,
        IVPoolWrapper wrapper,
        Protocol.Info storage protocol
    ) internal returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        IVPoolWrapper.SwapResult memory swapResult = wrapper.swap(
            swapParams.amount < 0,
            swapParams.isNotional ? swapParams.amount : -swapParams.amount,
            swapParams.sqrtPriceLimit
        );

        // change direction basis uniswap to balance increase
        vTokenAmountOut = -swapResult.vTokenIn;
        vQuoteAmountOut = -swapResult.vQuoteIn;

        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments = IClearingHouseStructures
            .BalanceAdjustments(vQuoteAmountOut, vTokenAmountOut, vTokenAmountOut);

        set.update(accountId, balanceAdjustments, poolId, protocol);

        emit TokenPositionChanged(
            accountId,
            poolId,
            vTokenAmountOut,
            vQuoteAmountOut,
            swapResult.sqrtPriceX96Start,
            swapResult.sqrtPriceX96End
        );
    }

    /// @notice function to liquidate all liquidity positions
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param protocol platform constants
    /// @return notionalAmountClosed - value of net token position coming out (in notional) of all the ranges closed
    function liquidateLiquidityPositions(
        VTokenPosition.Set storage set,
        uint256 accountId,
        Protocol.Info storage protocol
    ) internal returns (uint256 notionalAmountClosed) {
        for (uint8 i = 0; i < set.active.length; i++) {
            uint32 truncated = set.active[i];
            if (truncated == 0) break;

            notionalAmountClosed += set.liquidateLiquidityPositions(accountId, set.active[i], protocol);
        }
    }

    /// @notice function to liquidate liquidity positions for a particular token
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param protocol platform constants
    /// @return notionalAmountClosed - value of net token position coming out (in notional) of all the ranges closed
    function liquidateLiquidityPositions(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal returns (uint256 notionalAmountClosed) {
        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments;

        set.getTokenPosition(poolId, false).liquidityPositions.closeAllLiquidityPositions(
            accountId,
            poolId,
            balanceAdjustments,
            protocol
        );

        set.update(accountId, balanceAdjustments, poolId, protocol);

        // returns notional value of token position closed
        return protocol.getNotionalValue(poolId, balanceAdjustments.traderPositionIncrease);
    }

    /// @notice function for liquidity add/remove
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param liquidityChangeParams includes tickLower, tickUpper, liquidityDelta, limitOrderType
    /// @return vTokenAmountOut amount of tokens that account received (positive) or paid (negative)
    /// @return vQuoteAmountOut amount of vQuote tokens that account received (positive) or paid (negative)
    function liquidityChange(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        IClearingHouseStructures.LiquidityChangeParams memory liquidityChangeParams,
        Protocol.Info storage protocol
    ) internal returns (int256 vTokenAmountOut, int256 vQuoteAmountOut) {
        VTokenPosition.Info storage vTokenPosition = set.getTokenPosition(poolId, true);

        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments;

        vTokenPosition.liquidityPositions.liquidityChange(
            accountId,
            poolId,
            liquidityChangeParams,
            balanceAdjustments,
            protocol
        );

        set.update(accountId, balanceAdjustments, poolId, protocol);

        if (liquidityChangeParams.closeTokenPosition && balanceAdjustments.traderPositionIncrease != 0) {
            set.swapTokenAmount(accountId, poolId, -balanceAdjustments.traderPositionIncrease, protocol);
        }

        return (balanceAdjustments.vTokenIncrease, balanceAdjustments.vQuoteIncrease);
    }

    /// @notice function to remove an eligible limit order
    /// @dev checks whether the current price is on the correct side of the range based on the type of limit order (None, Low, High)
    /// @param set VTokenPositionSet
    /// @param accountId account identifier, used for emitting event
    /// @param poolId id of the rage trade pool
    /// @param tickLower lower tick index for the range
    /// @param tickUpper upper tick index for the range
    /// @param protocol platform constants
    function removeLimitOrder(
        VTokenPosition.Set storage set,
        uint256 accountId,
        uint32 poolId,
        int24 tickLower,
        int24 tickUpper,
        Protocol.Info storage protocol
    ) internal {
        VTokenPosition.Info storage vTokenPosition = set.getTokenPosition(poolId, false);

        IClearingHouseStructures.BalanceAdjustments memory balanceAdjustments;
        int24 currentTick = protocol.getVirtualCurrentTick(poolId);

        vTokenPosition.liquidityPositions.removeLimitOrder(
            accountId,
            poolId,
            currentTick,
            tickLower,
            tickUpper,
            balanceAdjustments,
            protocol
        );

        set.update(accountId, balanceAdjustments, poolId, protocol);
    }

    function updateOpenPoolPrices(VTokenPosition.Set storage set, Protocol.Info storage protocol) internal {
        for (uint8 i = 0; i < set.active.length; i++) {
            uint32 poolId = set.active[i];
            if (poolId == 0) break;
            protocol.updatePoolPriceCache(poolId);
        }
    }

    /**
     *  Internal view methods
     */

    /// @notice returns account market value of active positions
    /// @param set VTokenPositionSet
    /// @param protocol platform constants
    /// @return accountMarketValue - value of all active positions
    function getAccountMarketValue(VTokenPosition.Set storage set, Protocol.Info storage protocol)
        internal
        view
        returns (int256 accountMarketValue)
    {
        for (uint8 i = 0; i < set.active.length; i++) {
            uint32 poolId = set.active[i];
            if (poolId == 0) break;
            // IVToken vToken = protocol[poolId].vToken;
            VTokenPosition.Info storage position = set.positions[poolId];

            (, uint256 virtualPriceX128) = protocol.getCachedTwapPricesWithDeviationCheck(poolId);
            uint160 virtualSqrtPriceX96 = virtualPriceX128.toSqrtPriceX96();
            //Value of token position for current vToken
            accountMarketValue += position.marketValue(poolId, virtualPriceX128, protocol);

            //Value of all active range position for the current vToken
            accountMarketValue += position.liquidityPositions.marketValue(virtualSqrtPriceX96, poolId, protocol);
        }

        // Value of the vQuote token balance
        accountMarketValue += set.vQuoteBalance;
    }

    /// @notice gets information about the token and liquidity positions for all the pools
    /// @param set VTokenPositionSet
    /// @return vQuoteBalance vQuote balance for the token position
    /// @return vTokenPositions array of vToken position
    function getInfo(VTokenPosition.Set storage set)
        internal
        view
        returns (int256 vQuoteBalance, IClearingHouseStructures.VTokenPositionView[] memory vTokenPositions)
    {
        vQuoteBalance = set.vQuoteBalance;

        uint256 numberOfTokenPositions = set.active.numberOfNonZeroElements();
        vTokenPositions = new IClearingHouseStructures.VTokenPositionView[](numberOfTokenPositions);

        for (uint256 i = 0; i < numberOfTokenPositions; i++) {
            vTokenPositions[i].poolId = set.active[i];
            vTokenPositions[i].balance = set.positions[set.active[i]].balance;
            vTokenPositions[i].netTraderPosition = set.positions[set.active[i]].netTraderPosition;
            vTokenPositions[i].sumALastX128 = set.positions[set.active[i]].sumALastX128;
            vTokenPositions[i].liquidityPositions = set.positions[set.active[i]].liquidityPositions.getInfo();
        }
    }

    /// @notice returns the long and short side risk for range positions of a particular token
    /// @param set VTokenPositionSet
    /// @param isInitialMargin specifies to use initial margin factor (true) or maintainance margin factor (false)
    /// @param poolId id of the rage trade pool
    /// @param protocol platform constants
    /// @return longSideRisk - risk if the token price goes down
    /// @return shortSideRisk - risk if the token price goes up
    function getLongShortSideRisk(
        VTokenPosition.Set storage set,
        bool isInitialMargin,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal view returns (int256 longSideRisk, int256 shortSideRisk) {
        VTokenPosition.Info storage position = set.positions[poolId];

        (, uint256 virtualPriceX128) = protocol.getCachedTwapPricesWithDeviationCheck(poolId);
        uint160 virtualSqrtPriceX96 = virtualPriceX128.toSqrtPriceX96();

        uint16 marginRatio = protocol.getMarginRatioBps(poolId, isInitialMargin);

        int256 tokenPosition = position.balance;
        int256 longSideRiskRanges = position.liquidityPositions.longSideRisk(virtualSqrtPriceX96).toInt256();

        longSideRisk = SignedMath
            .max(position.netTraderPosition.mulDiv(virtualPriceX128, FixedPoint128.Q128) + longSideRiskRanges, 0)
            .mulDiv(marginRatio, 1e4);

        shortSideRisk = SignedMath.max(-tokenPosition, 0).mulDiv(virtualPriceX128, FixedPoint128.Q128).mulDiv(
            marginRatio,
            1e4
        );
        return (longSideRisk, shortSideRisk);
    }

    /// @notice gets the net position for the given poolId
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    /// @param protocol platform constants
    /// @return netPosition net position of the account for the pool
    function getNetPosition(
        VTokenPosition.Set storage set,
        uint32 poolId,
        Protocol.Info storage protocol
    ) internal view returns (int256 netPosition) {
        if (!set.active.exists(poolId)) return 0;
        VTokenPosition.Info storage tokenPosition = set.positions[poolId];
        return tokenPosition.getNetPosition(poolId, protocol);
    }

    /// @notice returns the long and short side risk for range positions of a particular token
    /// @param set VTokenPositionSet
    /// @param isInitialMargin specifies to use initial margin factor (true) or maintainance margin factor (false)
    /// @param protocol platform constants
    /// @return requiredMargin - required margin value based on the current active positions
    function getRequiredMargin(
        VTokenPosition.Set storage set,
        bool isInitialMargin,
        Protocol.Info storage protocol
    ) internal view returns (int256 requiredMargin) {
        int256 longSideRiskTotal;
        int256 shortSideRiskTotal;
        int256 longSideRisk;
        int256 shortSideRisk;
        for (uint8 i = 0; i < set.active.length; i++) {
            if (set.active[i] == 0) break;
            uint32 poolId = set.active[i];
            (longSideRisk, shortSideRisk) = set.getLongShortSideRisk(isInitialMargin, poolId, protocol);

            if (protocol.isPoolCrossMargined(poolId)) {
                longSideRiskTotal += longSideRisk;
                shortSideRiskTotal += shortSideRisk;
            } else {
                requiredMargin += SignedMath.max(longSideRisk, shortSideRisk);
            }
        }

        requiredMargin += SignedMath.max(longSideRiskTotal, shortSideRiskTotal);
    }

    /// @notice get or create token position
    /// @dev activates inactive vToken if isCreateNew is true else reverts
    /// @param set VTokenPositionSet
    /// @param poolId id of the rage trade pool
    /// @param createNew if 'vToken' is inactive then activates (true) else reverts with TokenInactive(false)
    /// @return position - VTokenPosition corresponding to 'vToken'
    function getTokenPosition(
        VTokenPosition.Set storage set,
        uint32 poolId,
        bool createNew
    ) internal returns (VTokenPosition.Info storage position) {
        if (createNew) {
            set.activate(poolId);
        } else if (!set.active.exists(poolId)) {
            revert VPS_TokenInactive(poolId);
        }

        position = set.positions[poolId];
    }

    /// @notice returns true if the set does not have any token position active
    /// @param set VTokenPositionSet
    /// @return True if there are no active positions
    function isEmpty(VTokenPosition.Set storage set) internal view returns (bool) {
        return set.active.isEmpty();
    }

    /// @notice returns true if range position is active for 'vToken'
    /// @param set VTokenPositionSet
    /// @param poolId poolId of the vToken
    /// @return isRangeActive - True if the range position is active
    function isTokenRangeActive(VTokenPosition.Set storage set, uint32 poolId) internal returns (bool isRangeActive) {
        VTokenPosition.Info storage vTokenPosition = set.getTokenPosition(poolId, false);
        isRangeActive = !vTokenPosition.liquidityPositions.isEmpty();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IOracle } from '../IOracle.sol';
import { IVToken } from '../IVToken.sol';
import { IVPoolWrapper } from '../IVPoolWrapper.sol';

import { IClearingHouseEnums } from './IClearingHouseEnums.sol';

interface IClearingHouseStructures is IClearingHouseEnums {
    struct BalanceAdjustments {
        int256 vQuoteIncrease; // specifies the increase in vQuote balance
        int256 vTokenIncrease; // specifies the increase in token balance
        int256 traderPositionIncrease; // specifies the increase in trader position
    }

    struct Collateral {
        IERC20 token; // address of the collateral token
        CollateralSettings settings; // collateral settings, changable by governance later
    }

    struct CollateralSettings {
        IOracle oracle; // address of oracle which gives price to be used for collateral
        uint32 twapDuration; // duration of the twap in seconds
        bool isAllowedForDeposit; // whether the collateral is allowed to be deposited at the moment
    }

    struct CollateralDepositView {
        IERC20 collateral; // address of the collateral token
        uint256 balance; // balance of the collateral in the account
    }

    struct LiquidityChangeParams {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        int128 liquidityDelta; // positive to add liquidity, negative to remove liquidity
        uint160 sqrtPriceCurrent; // hint for virtual price, to prevent sandwitch attack
        uint16 slippageToleranceBps; // slippage tolerance in bps, to prevent sandwitch attack
        bool closeTokenPosition; // whether to close the token position generated due to the liquidity change
        LimitOrderType limitOrderType; // limit order type
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct LiquidityPositionView {
        int24 tickLower; // tick lower of the range
        int24 tickUpper; // tick upper of the range
        uint128 liquidity; // liquidity in the range by the account
        int256 vTokenAmountIn; // amount of token supplied by the account, to calculate net position
        int256 sumALastX128; // checkpoint of the term A in funding payment math
        int256 sumBInsideLastX128; // checkpoint of the term B in funding payment math
        int256 sumFpInsideLastX128; // checkpoint of the term Fp in funding payment math
        uint256 sumFeeInsideLastX128; // checkpoint of the trading fees
        LimitOrderType limitOrderType; // limit order type
    }

    struct LiquidationParams {
        uint16 rangeLiquidationFeeFraction; // fraction of net token position rm from the range to be charged as liquidation fees (in 1e5)
        uint16 tokenLiquidationFeeFraction; // fraction of traded amount of vquote to be charged as liquidation fees (in 1e5)
        uint16 closeFactorMMThresholdBps; // fraction the MM threshold for partial liquidation (in 1e4)
        uint16 partialLiquidationCloseFactorBps; // fraction the % of position to be liquidated if partial liquidation should occur (in 1e4)
        uint16 insuranceFundFeeShareBps; // fraction of the fee share for insurance fund out of the total liquidation fee (in 1e4)
        uint16 liquidationSlippageSqrtToleranceBps; // fraction of the max sqrt price slippage threshold (in 1e4) (can be set to - actual price slippage tolerance / 2)
        uint64 maxRangeLiquidationFees; // maximum range liquidation fees (in settlement token amount decimals)
        uint64 minNotionalLiquidatable; // minimum notional value of position for it to be eligible for partial liquidation (in settlement token amount decimals)
    }

    struct MulticallOperation {
        MulticallOperationType operationType; // operation type
        bytes data; // abi encoded data for the operation
    }

    struct Pool {
        IVToken vToken; // address of the vToken, poolId = vToken.truncate()
        IUniswapV3Pool vPool; // address of the UniswapV3Pool(token0=vToken, token1=vQuote, fee=500)
        IVPoolWrapper vPoolWrapper; // wrapper address
        PoolSettings settings; // pool settings, which can be updated by governance later
    }

    struct PoolSettings {
        uint16 initialMarginRatioBps; // margin ratio (1e4) considered for create/update position, removing margin or profit
        uint16 maintainanceMarginRatioBps; // margin ratio (1e4) considered for liquidations by keeper
        uint16 maxVirtualPriceDeviationRatioBps; // maximum deviation (1e4) from the current virtual price
        uint32 twapDuration; // twap duration (seconds) for oracle
        bool isAllowedForTrade; // whether the pool is allowed to be traded at the moment
        bool isCrossMargined; // whether cross margined is done for positions of this pool
        IOracle oracle; // spot price feed twap oracle for this pool
    }

    struct SwapParams {
        int256 amount; // amount of tokens/vQuote to swap
        uint160 sqrtPriceLimit; // threshold sqrt price which should not be crossed
        bool isNotional; // whether the amount represents vQuote amount
        bool isPartialAllowed; // whether to end swap (partial) when sqrtPriceLimit is reached, instead of reverting
        bool settleProfit; // whether to settle profit against USDC margin
    }

    struct TickRange {
        int24 tickLower;
        int24 tickUpper;
    }

    struct VTokenPositionView {
        uint32 poolId; // id of the pool of which this token position is for
        int256 balance; // vTokenLong - vTokenShort
        int256 netTraderPosition; // net position due to trades and liquidity change carries
        int256 sumALastX128; // checkoint of the term A in funding payment math
        LiquidityPositionView[] liquidityPositions; // liquidity positions of the account in the pool
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IClearingHouseEnums {
    enum LimitOrderType {
        NONE,
        LOWER_LIMIT,
        UPPER_LIMIT
    }

    enum MulticallOperationType {
        UPDATE_MARGIN,
        UPDATE_PROFIT,
        SWAP_TOKEN,
        UPDATE_RANGE_ORDER,
        REMOVE_LIMIT_ORDER,
        LIQUIDATE_LIQUIDITY_POSITIONS,
        LIQUIDATE_TOKEN_POSITION
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVQuote is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function authorize(address vPoolWrapper) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(uint256 amount) external;

    function setVPoolWrapper(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Uint32 length 8 array functions
/// @dev Fits in one storage slot
library Uint32L8ArrayLib {
    using Uint32L8ArrayLib for uint32[8];

    uint8 constant LENGTH = 8;

    error U32L8_IllegalElement(uint32 element);
    error U32L8_NoSpaceLeftToInsert(uint32 element);

    /// @notice Inserts an element in the array
    /// @dev Replaces a zero value in the array with element
    /// @param array Array to modify
    /// @param element Element to insert
    function include(uint32[8] storage array, uint32 element) internal {
        if (element == 0) {
            revert U32L8_IllegalElement(0);
        }

        uint256 emptyIndex = LENGTH; // LENGTH is an invalid index
        for (uint256 i; i < LENGTH; i++) {
            if (array[i] == element) {
                // if element already exists in the array, do nothing
                return;
            }
            // if we found an empty slot, remember it
            if (array[i] == uint32(0)) {
                emptyIndex = i;
                break;
            }
        }

        // if empty index is still LENGTH, there is no space left to insert
        if (emptyIndex == LENGTH) {
            revert U32L8_NoSpaceLeftToInsert(element);
        }

        array[emptyIndex] = element;
    }

    /// @notice Excludes the element from the array
    /// @dev If element exists, it swaps with last element and makes last element zero
    /// @param array Array to modify
    /// @param element Element to remove
    function exclude(uint32[8] storage array, uint32 element) internal {
        if (element == 0) {
            revert U32L8_IllegalElement(0);
        }

        uint256 elementIndex = LENGTH; // LENGTH is an invalid index
        uint256 i;

        for (; i < LENGTH; i++) {
            if (array[i] == element) {
                // element index in the array
                elementIndex = i;
            }
            if (array[i] == 0) {
                // last non-zero element
                i = i > 0 ? i - 1 : 0;
                break;
            }
        }

        // if array is full, i == LENGTH
        // hence swapping with element at last index
        i = i == LENGTH ? LENGTH - 1 : i;

        if (elementIndex != LENGTH) {
            if (i == elementIndex) {
                // if element is last element, simply make it zero
                array[elementIndex] = 0;
            } else {
                // move last to element's place and empty lastIndex slot
                (array[elementIndex], array[i]) = (array[i], 0);
            }
        }
    }

    /// @notice Returns the index of the element in the array
    /// @param array Array to perform search on
    /// @param element Element to search
    /// @return index if exists or LENGTH otherwise
    function indexOf(uint32[8] storage array, uint32 element) internal view returns (uint8) {
        for (uint8 i; i < LENGTH; i++) {
            if (array[i] == element) {
                return i;
            }
        }
        return LENGTH; // LENGTH is an invalid index
    }

    /// @notice Checks whether the element exists in the array
    /// @param array Array to perform search on
    /// @param element Element to search
    /// @return True if element is found, false otherwise
    function exists(uint32[8] storage array, uint32 element) internal view returns (bool) {
        return array.indexOf(element) != LENGTH; // LENGTH is an invalid index
    }

    /// @notice Returns length of array (number of non-zero elements)
    /// @param array Array to perform search on
    /// @return Length of array
    function numberOfNonZeroElements(uint32[8] storage array) internal view returns (uint256) {
        for (uint8 i; i < LENGTH; i++) {
            if (array[i] == 0) {
                return i;
            }
        }
        return LENGTH;
    }

    /// @notice Checks whether the array is empty or not
    /// @param array Array to perform search on
    /// @return True if the set does not have any token position active
    function isEmpty(uint32[8] storage array) internal view returns (bool) {
        return array[0] == 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

import { IVQuote } from './IVQuote.sol';
import { IVToken } from './IVToken.sol';

interface IVPoolWrapper {
    struct InitializeVPoolWrapperParams {
        address clearingHouse; // address of clearing house contract (proxy)
        IVToken vToken; // address of vToken contract
        IVQuote vQuote; // address of vQuote contract
        IUniswapV3Pool vPool; // address of Uniswap V3 Pool contract, created using vToken and vQuote
        uint24 liquidityFeePips; // liquidity fee fraction (in 1e6)
        uint24 protocolFeePips; // protocol fee fraction (in 1e6)
    }

    struct SwapResult {
        int256 amountSpecified; // amount of tokens/vQuote which were specified in the swap request
        int256 vTokenIn; // actual amount of vTokens paid by account to the Pool
        int256 vQuoteIn; // actual amount of vQuotes paid by account to the Pool
        uint256 liquidityFees; // actual amount of fees paid by account to the Pool
        uint256 protocolFees; // actual amount of fees paid by account to the Protocol
        uint160 sqrtPriceX96Start; // sqrt price at the beginning of the swap
        uint160 sqrtPriceX96End; // sqrt price at the end of the swap
    }

    struct WrapperValuesInside {
        int256 sumAX128; // sum of all the A terms in the pool
        int256 sumBInsideX128; // sum of all the B terms in side the tick range in the pool
        int256 sumFpInsideX128; // sum of all the Fp terms in side the tick range in the pool
        uint256 sumFeeInsideX128; // sum of all the fee terms in side the tick range in the pool
    }

    /// @notice Emitted whenever a swap takes place
    /// @param swapResult the swap result values
    event Swap(SwapResult swapResult);

    /// @notice Emitted whenever liquidity is added
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was added
    /// @param vTokenPrincipal the amount of vToken that was sent to UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was sent to UniswapV3Pool
    event Mint(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever liquidity is removed
    /// @param tickLower the lower tick of the range
    /// @param tickUpper the upper tick of the range
    /// @param liquidity the amount of liquidity that was removed
    /// @param vTokenPrincipal the amount of vToken that was received from UniswapV3Pool
    /// @param vQuotePrincipal the mount of vQuote charged was received from UniswapV3Pool
    event Burn(int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 vTokenPrincipal, uint256 vQuotePrincipal);

    /// @notice Emitted whenever clearing house enquired about the accrued protocol fees
    /// @param amount the amount of accrued protocol fees
    event AccruedProtocolFeeCollected(uint256 amount);

    /// @notice Emitted when governance updates the liquidity fees
    /// @param liquidityFeePips the new liquidity fee ratio
    event LiquidityFeeUpdated(uint24 liquidityFeePips);

    /// @notice Emitted when governance updates the protocol fees
    /// @param protocolFeePips the new protocol fee ratio
    event ProtocolFeeUpdated(uint24 protocolFeePips);

    /// @notice Emitted when funding rate override is updated
    /// @param fundingRateOverrideX128 the new funding rate override value
    event FundingRateOverrideUpdated(int256 fundingRateOverrideX128);

    function initialize(InitializeVPoolWrapperParams memory params) external;

    function vPool() external view returns (IUniswapV3Pool);

    function getValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function getExtrapolatedValuesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (WrapperValuesInside memory wrapperValuesInside);

    function swap(
        bool swapVTokenForVQuote, // zeroForOne
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) external returns (SwapResult memory swapResult);

    function mint(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        external
        returns (
            uint256 vTokenPrincipal,
            uint256 vQuotePrincipal,
            WrapperValuesInside memory wrapperValuesInside
        );

    function getSumAX128() external view returns (int256);

    function getExtrapolatedSumAX128() external view returns (int256);

    function liquidityFeePips() external view returns (uint24);

    function protocolFeePips() external view returns (uint24);

    /// @notice Used by clearing house to update funding rate when clearing house is paused or unpaused.
    /// @param useZeroFundingRate: used to discount funding payment during the duration ch was paused.
    function updateGlobalFundingState(bool useZeroFundingRate) external;

    /// @notice Used by clearing house to know how much protocol fee was collected.
    /// @return accruedProtocolFeeLast amount of protocol fees accrued since last collection.
    /// @dev Does not do any token transfer, just reduces the state in wrapper by accruedProtocolFeeLast.
    ///     Clearing house already has the amount of settlement tokens to send to treasury.
    function collectAccruedProtocolFee() external returns (uint256 accruedProtocolFeeLast);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';
import { FixedPoint96 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint96.sol';
import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { Bisection } from './Bisection.sol';

/// @title Price math functions
library PriceMath {
    using FullMath for uint256;

    error IllegalSqrtPrice(uint160 sqrtPriceX96);

    /// @notice Computes the square of a sqrtPriceX96 value
    /// @param sqrtPriceX96: the square root of the input price in Q96 format
    /// @return priceX128 : input price in Q128 format
    function toPriceX128(uint160 sqrtPriceX96) internal pure returns (uint256 priceX128) {
        if (sqrtPriceX96 < TickMath.MIN_SQRT_RATIO || sqrtPriceX96 >= TickMath.MAX_SQRT_RATIO) {
            revert IllegalSqrtPrice(sqrtPriceX96);
        }

        priceX128 = _toPriceX128(sqrtPriceX96);
    }

    /// @notice computes the square of a sqrtPriceX96 value
    /// @param sqrtPriceX96: input price in Q128 format
    function _toPriceX128(uint160 sqrtPriceX96) private pure returns (uint256 priceX128) {
        priceX128 = uint256(sqrtPriceX96).mulDiv(sqrtPriceX96, 1 << 64);
    }

    /// @notice computes the square root of a priceX128 value
    /// @param priceX128: input price in Q128 format
    /// @return sqrtPriceX96 : the square root of the input price in Q96 format
    function toSqrtPriceX96(uint256 priceX128) internal pure returns (uint160 sqrtPriceX96) {
        // Uses bisection method to find solution to the equation toPriceX128(x) = priceX128
        sqrtPriceX96 = Bisection.findSolution(
            _toPriceX128,
            priceX128,
            /// @dev sqrtPriceX96 is always bounded by MIN_SQRT_RATIO and MAX_SQRT_RATIO.
            ///     If solution falls outside of these bounds, findSolution method reverts
            TickMath.MIN_SQRT_RATIO,
            TickMath.MAX_SQRT_RATIO - 1
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Safe cast functions
library SafeCast {
    error SafeCast_Int128Overflow(uint128 value);

    function toInt128(uint128 y) internal pure returns (int128 z) {
        unchecked {
            if (y >= 2**127) revert SafeCast_Int128Overflow(y);
            z = int128(y);
        }
    }

    error SafeCast_Int256Overflow(uint256 value);

    function toInt256(uint256 y) internal pure returns (int256 z) {
        unchecked {
            if (y >= 2**255) revert SafeCast_Int256Overflow(y);
            z = int256(y);
        }
    }

    error SafeCast_UInt224Overflow(uint256 value);

    function toUint224(uint256 y) internal pure returns (uint224 z) {
        if (y > 2**224) revert SafeCast_UInt224Overflow(y);
        z = uint224(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { TickMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/TickMath.sol';

import { IUniswapV3Pool } from '@uniswap/v3-core-0.8-support/contracts/interfaces/IUniswapV3Pool.sol';

/// @title UniswapV3Pool helper functions
library UniswapV3PoolHelper {
    using UniswapV3PoolHelper for IUniswapV3Pool;

    error UV3PH_OracleConsultFailed();

    /// @notice Get the pool's current tick
    /// @param v3Pool The uniswap v3 pool contract
    /// @return tick the current tick
    function tickCurrent(IUniswapV3Pool v3Pool) internal view returns (int24 tick) {
        (, tick, , , , , ) = v3Pool.slot0();
    }

    /// @notice Get the pool's current sqrt price
    /// @param v3Pool The uniswap v3 pool contract
    /// @return sqrtPriceX96 the current sqrt price
    function sqrtPriceCurrent(IUniswapV3Pool v3Pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = v3Pool.slot0();
    }

    /// @notice Get twap price for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return sqrtPriceX96 the twap price
    function twapSqrtPrice(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (uint160 sqrtPriceX96) {
        int24 _twapTick = v3Pool.twapTick(twapDuration);
        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(_twapTick);
    }

    /// @notice Get twap tick for uniswap v3 pool
    /// @param v3Pool The uniswap v3 pool contract
    /// @param twapDuration The twap period
    /// @return _twapTick the twap tick
    function twapTick(IUniswapV3Pool v3Pool, uint32 twapDuration) internal view returns (int24 _twapTick) {
        if (twapDuration == 0) {
            return v3Pool.tickCurrent();
        }

        uint32[] memory secondAgos = new uint32[](2);
        secondAgos[0] = twapDuration;
        secondAgos[1] = 0;

        // this call will fail if period is bigger than MaxObservationPeriod
        try v3Pool.observe(secondAgos) returns (int56[] memory tickCumulatives, uint160[] memory) {
            int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
            int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int56(uint56(twapDuration)));

            // Always round to negative infinity
            if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapDuration)) != 0)) {
                timeWeightedAverageTick--;
            }
            return timeWeightedAverageTick;
        } catch {
            // if for some reason v3Pool.observe fails, fallback to the current tick
            (, _twapTick, , , , , ) = v3Pool.slot0();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);
}

/// @title Library for getting block number for the current chain
library Block {
    /// @notice Get block number
    /// @return block number as uint32
    function number() internal view returns (uint32) {
        uint256 chainId = block.chainid;
        if (chainId == 42161 || chainId == 421611 || chainId == 421612) {
            return uint32(ArbSys(address(100)).arbBlockNumber());
        } else {
            return uint32(block.number);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IOracle {
    function getTwapPriceX128(uint32 twapDuration) external view returns (uint256 priceX128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Bisection Method
/// @notice https://en.wikipedia.org/wiki/Bisection_method
library Bisection {
    error SolutionOutOfBounds(uint256 y_target, uint160 x_lower, uint160 x_upper);

    /// @notice Finds the solution to the equation f(x) = y_target using the bisection method
    /// @param f: strictly increasing function f: uint160 -> uint256
    /// @param y_target: the target value of f(x)
    /// @param x_lower: the lower bound for x
    /// @param x_upper: the upper bound for x
    /// @return x_target: the rounded down solution to the equation f(x) = y_target
    function findSolution(
        function(uint160) pure returns (uint256) f,
        uint256 y_target,
        uint160 x_lower,
        uint160 x_upper
    ) internal pure returns (uint160) {
        // compute y at the bounds
        uint256 y_lower = f(x_lower);
        uint256 y_upper = f(x_upper);

        // if y is out of the bounds then revert
        if (y_target < y_lower || y_target > y_upper) revert SolutionOutOfBounds(y_target, x_lower, x_upper);

        // bisect repeatedly until the solution is within an error of 1 unit
        uint256 y_mid;
        uint160 x_mid;
        while (x_upper - x_lower > 1) {
            x_mid = x_lower + (x_upper - x_lower) / 2;
            y_mid = f(x_mid);
            if (y_mid > y_target) {
                x_upper = x_mid;
                y_upper = y_mid;
            } else {
                x_lower = x_mid;
                y_lower = y_mid;
            }
        }

        // at this point, x_upper - x_lower is either 0 or 1
        // if it is 1 then check if x_upper is the solution, else return x_lower as the rounded down solution
        return x_lower != x_upper && f(x_upper) == y_target ? x_upper : x_lower;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/// @title Uint48 concating functions
library Uint48Lib {
    /// @notice Packs two int24 values into uint48
    /// @dev Used for concating two ticks into 48 bits value
    /// @param val1 First 24 bits value
    /// @param val2 Second 24 bits value
    /// @return concatenated value
    function concat(int24 val1, int24 val2) internal pure returns (uint48 concatenated) {
        assembly {
            concatenated := add(shl(24, val1), and(val2, 0x000000ffffff))
        }
    }

    /// @notice Unpacks uint48 into two int24 values
    /// @dev Used for unpacking 48 bits value into two 24 bits values
    /// @param concatenated 48 bits value
    /// @return val1 First 24 bits value
    /// @return val2 Second 24 bits value
    function unconcat(uint48 concatenated) internal pure returns (int24 val1, int24 val2) {
        assembly {
            val2 := concatenated
            val1 := shr(24, concatenated)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title Uint48 length 5 array functions
/// @dev Fits in one storage slot
library Uint48L5ArrayLib {
    using Uint48L5ArrayLib for uint48[5];

    uint8 constant LENGTH = 5;

    error U48L5_IllegalElement(uint48 element);
    error U48L5_NoSpaceLeftToInsert(uint48 element);

    /// @notice Inserts an element in the array
    /// @dev Replaces a zero value in the array with element
    /// @param array Array to modify
    /// @param element Element to insert
    function include(uint48[5] storage array, uint48 element) internal {
        if (element == 0) {
            revert U48L5_IllegalElement(0);
        }

        uint256 emptyIndex = LENGTH; // LENGTH is an invalid index
        for (uint256 i; i < LENGTH; i++) {
            if (array[i] == element) {
                // if element already exists in the array, do nothing
                return;
            }
            // if we found an empty slot, remember it
            if (array[i] == uint48(0)) {
                emptyIndex = i;
                break;
            }
        }

        // if empty index is still LENGTH, there is no space left to insert
        if (emptyIndex == LENGTH) {
            revert U48L5_NoSpaceLeftToInsert(element);
        }

        array[emptyIndex] = element;
    }

    /// @notice Excludes the element from the array
    /// @dev If element exists, it swaps with last element and makes last element zero
    /// @param array Array to modify
    /// @param element Element to remove
    function exclude(uint48[5] storage array, uint48 element) internal {
        if (element == 0) {
            revert U48L5_IllegalElement(0);
        }

        uint256 elementIndex = LENGTH; // LENGTH is an invalid index
        uint256 i;

        for (; i < LENGTH; i++) {
            if (array[i] == element) {
                // element index in the array
                elementIndex = i;
            }
            if (array[i] == 0) {
                // last non-zero element
                i = i > 0 ? i - 1 : 0;
                break;
            }
        }

        // if array is full, i == LENGTH
        // hence swapping with element at last index
        i = i == LENGTH ? LENGTH - 1 : i;

        if (elementIndex != LENGTH) {
            if (i == elementIndex) {
                // if element is last element, simply make it zero
                array[elementIndex] = 0;
            } else {
                // move last to element's place and empty lastIndex slot
                (array[elementIndex], array[i]) = (array[i], 0);
            }
        }
    }

    /// @notice Returns the index of the element in the array
    /// @param array Array to perform search on
    /// @param element Element to search
    /// @return index if exists or LENGTH otherwise
    function indexOf(uint48[5] storage array, uint48 element) internal view returns (uint8) {
        for (uint8 i; i < LENGTH; i++) {
            if (array[i] == element) {
                return i;
            }
        }
        return LENGTH; // LENGTH is an invalid index
    }

    /// @notice Checks whether the element exists in the array
    /// @param array Array to perform search on
    /// @param element Element to search
    /// @return True if element is found, false otherwise
    function exists(uint48[5] storage array, uint48 element) internal view returns (bool) {
        return array.indexOf(element) != LENGTH; // LENGTH is an invalid index
    }

    /// @notice Returns length of array (number of non-zero elements)
    /// @param array Array to perform search on
    /// @return Length of array
    function numberOfNonZeroElements(uint48[5] storage array) internal view returns (uint256) {
        for (uint8 i; i < LENGTH; i++) {
            if (array[i] == 0) {
                return i;
            }
        }
        return LENGTH;
    }

    /// @notice Checks whether the array is empty or not
    /// @param array Array to perform search on
    /// @return True if the set does not have any token position active
    function isEmpty(uint48[5] storage array) internal view returns (bool) {
        return array[0] == 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {SafeCast} from './SafeCast.sol';

import {FullMath} from './FullMath.sol';
import {UnsafeMath} from './UnsafeMath.sol';
import {FixedPoint96} from './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            unchecked {
                uint256 product;
                if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                    uint256 denominator = numerator1 + product;
                    if (denominator >= numerator1)
                        // always fits in 160 bits
                        return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
                }
            }
            // denominator is checked for overflow
            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96) + amount));
        } else {
            unchecked {
                uint256 product;
                // if the product overflows, we know the denominator underflows
                // in addition, we must check that the denominator does not underflow
                require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
                uint256 denominator = numerator1 - product;
                return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
            }
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return (uint256(sqrtPX96) + quotient).toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                    : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
            );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            unchecked {
                return uint160(sqrtPX96 - quotient);
            }
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
            uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

            require(sqrtRatioAX96 > 0);

            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                roundUp
                    ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                    : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        unchecked {
            return
                liquidity < 0
                    ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                    : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import { FixedPoint128 } from '@uniswap/v3-core-0.8-support/contracts/libraries/FixedPoint128.sol';
import { FullMath } from '@uniswap/v3-core-0.8-support/contracts/libraries/FullMath.sol';

import { SafeCast } from './SafeCast.sol';
import { SignedFullMath } from './SignedFullMath.sol';

/// @title Funding payment functions
/// @notice Funding Payment Logic used to distribute the FP bill paid by traders among the LPs in the liquidity range
library FundingPayment {
    using FullMath for uint256;
    using SafeCast for uint256;
    using SignedFullMath for int256;

    struct Info {
        // FR * P * dt
        int256 sumAX128;
        // trade token amount / liquidity
        int256 sumBX128;
        // sum(a * sumB)
        int256 sumFpX128;
        // time when state was last updated
        uint48 timestampLast;
    }

    event FundingPaymentStateUpdated(
        FundingPayment.Info fundingPayment,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    );

    /// @notice Calculates the funding rate based on prices
    /// @param realPriceX128 spot price of token
    /// @param virtualPriceX128 futures price of token
    function getFundingRate(uint256 realPriceX128, uint256 virtualPriceX128)
        internal
        pure
        returns (int256 fundingRateX128)
    {
        int256 priceDeltaX128 = virtualPriceX128.toInt256() - realPriceX128.toInt256();
        return priceDeltaX128.mulDiv(FixedPoint128.Q128, realPriceX128) / 1 days;
    }

    /// @notice Used to update the state of the funding payment whenever a trade takes place
    /// @param info pointer to the funding payment state
    /// @param vTokenAmount trade token amount
    /// @param liquidity active liquidity in the range during the trade (step)
    /// @param blockTimestamp timestamp of current block
    /// @param fundingRateX128 the constant funding rate to apply for the duration between timestampLast and blockTimestamp
    /// @param virtualPriceX128 futures price of token
    function update(
        FundingPayment.Info storage info,
        int256 vTokenAmount,
        uint256 liquidity,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal {
        int256 a = nextAX128(info.timestampLast, blockTimestamp, fundingRateX128, virtualPriceX128);
        info.sumFpX128 += a.mulDivRoundingDown(info.sumBX128, int256(FixedPoint128.Q128));
        info.sumAX128 += a;
        info.sumBX128 += vTokenAmount.mulDiv(int256(FixedPoint128.Q128), int256(liquidity));
        info.timestampLast = blockTimestamp;

        emit FundingPaymentStateUpdated(info, fundingRateX128, virtualPriceX128);
    }

    /// @notice Used to get the rate of funding payment for the duration between last trade and this trade
    /// @dev Positive A value means at this duration, longs pay shorts. Negative means shorts pay longs.
    /// @param timestampLast start timestamp of duration
    /// @param blockTimestamp end timestamp of duration
    /// @param virtualPriceX128 futures price of token
    /// @param fundingRateX128 the constant funding rate to apply for the duration between timestampLast and blockTimestamp
    /// @return aX128 value called "a" (see funding payment math documentation)
    function nextAX128(
        uint48 timestampLast,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal pure returns (int256 aX128) {
        return fundingRateX128.mulDiv(virtualPriceX128, FixedPoint128.Q128) * int48(blockTimestamp - timestampLast);
    }

    function extrapolatedSumAX128(
        int256 sumAX128,
        uint48 timestampLast,
        uint48 blockTimestamp,
        int256 fundingRateX128,
        uint256 virtualPriceX128
    ) internal pure returns (int256) {
        return sumAX128 + nextAX128(timestampLast, blockTimestamp, fundingRateX128, virtualPriceX128);
    }

    /// @notice Extrapolates (updates) the value of sumFp by adding the missing component to it using sumAGlobalX128
    /// @param sumAX128 sumA value that is recorded from global at some point in time
    /// @param sumBX128 sumB value that is recorded from global at same point in time as sumA
    /// @param sumFpX128 sumFp value that is recorded from global at same point in time as sumA and sumB
    /// @param sumAGlobalX128 latest sumA value (taken from global), used to extrapolate the sumFp
    function extrapolatedSumFpX128(
        int256 sumAX128,
        int256 sumBX128,
        int256 sumFpX128,
        int256 sumAGlobalX128
    ) internal pure returns (int256) {
        return sumFpX128 + sumBX128.mulDiv(sumAGlobalX128 - sumAX128, int256(FixedPoint128.Q128));
    }

    /// @notice Positive bill is charged from LPs, Negative bill is rewarded to LPs
    /// @param sumAX128 latest value of sumA (to be taken from global state)
    /// @param sumFpInsideX128 latest value of sumFp inside range (to be computed using global state + tick state)
    /// @param sumALastX128 value of sumA when LP updated their liquidity last time
    /// @param sumBInsideLastX128 value of sumB inside range when LP updated their liquidity last time
    /// @param sumFpInsideLastX128 value of sumFp inside range when LP updated their liquidity last time
    /// @param liquidity amount of liquidity which was constant for LP in the time duration
    /// @return amount of vQuote tokens that should be charged if positive
    function bill(
        int256 sumAX128,
        int256 sumFpInsideX128,
        int256 sumALastX128,
        int256 sumBInsideLastX128,
        int256 sumFpInsideLastX128,
        uint256 liquidity
    ) internal pure returns (int256) {
        return
            (sumFpInsideX128 - extrapolatedSumFpX128(sumALastX128, sumBInsideLastX128, sumFpInsideLastX128, sumAX128))
                .mulDivRoundingDown(liquidity, FixedPoint128.Q128);
    }

    /// @notice Positive bill is charged from Traders, Negative bill is rewarded to Traders
    /// @param sumAX128 latest value of sumA (to be taken from global state)
    /// @param sumALastX128 value of sumA when trader updated their netTraderPosition
    /// @param netTraderPosition oken amount which should be constant for time duration since sumALastX128 was recorded
    /// @return amount of vQuote tokens that should be charged if positive
    function bill(
        int256 sumAX128,
        int256 sumALastX128,
        int256 netTraderPosition
    ) internal pure returns (int256) {
        return netTraderPosition.mulDiv((sumAX128 - sumALastX128), int256(FixedPoint128.Q128));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}