// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { ISwapCallbackRelayer } from "../interfaces/ISwapCallbackRelayer.sol";
import { Pricing } from "./Pricing.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";

/**
 * @title SwapCallbackLogic
 * @author GoldLink
 * @dev Library for handling swap callback functions.
 */
library SwapCallbackLogic {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;

    // ============ External Functions ============

    /**
     * @notice Handle the accounting for an atomic asset swap, used for selling off spot assets.
     * @param asset              The asset being swapped. If the asset does not have a valid oracle, the call will revert.
     * @param amount             The amount of `asset` that should be sent to the `tokenReciever`.
     * @param maxSlippagePercent The maximum slippage percent allowed during the callback's execution.
     * @param callback           The callback that will be called to handle the swap. This must implement the `ISwapCallbackHandler` interface and return the expected USDC amount
     * after execution finishes.
     * @param tokenReceiever    The address that should recieve the `asset` being swapped.
     * @param data              Data passed through to the callback contract.
     * @return usdcAmountIn     The amount of USDC received back after the callback.
     */
    function handleSwapCallback(
        IGmxFrfStrategyManager manager,
        address asset,
        uint256 amount,
        uint256 maxSlippagePercent,
        address callback,
        address tokenReceiever,
        bytes memory data
    ) public returns (uint256 usdcAmountIn) {
        IERC20 usdc = manager.USDC();

        // Cannot swap from USDC, as this is our target asset.
        require(
            asset != address(usdc),
            GmxFrfStrategyErrors.SWAP_CALLBACK_LOGIC_CANNOT_SWAP_USDC
        );

        // Get the value of the tokens being swapped. This is important so we can evaluate the equivalent in terms of USDC.
        uint256 valueToken = Pricing.getTokenValueUSD(manager, asset, amount);

        // Get the value of the tokens being swapped in terms of USDC.
        // Accounts for cases where USDC depegs, possibly resulting in it being impossible to fill an order assuming the price is $1.
        uint256 valueInUsdc = Pricing.getTokenAmountForUSD(
            manager,
            address(usdc),
            valueToken
        );

        // Account for slippage to determine the minimum amount of USDC that should be recieved after the callback function's
        // execution is complete.
        uint256 minimumUSDCRecieved = valueInUsdc -
            valueInUsdc.percentToFraction(maxSlippagePercent);

        // Expected USDC must be greater than zero, otherwise this would allow stealing assets from the contract when rounding down.
        require(
            minimumUSDCRecieved > 0,
            GmxFrfStrategyErrors
                .SWAP_CALLBACK_LOGIC_NO_BALANCE_AFTER_SLIPPAGE_APPLIED
        );

        // Get the balance of USDC before the swap. This is used to determine the change in the balance of USDC to check if at least `expectedUSDC` was paid back.
        uint256 balanceUSDCBefore = usdc.balanceOf(address(this));

        // Transfer the tokens to the specified reciever.
        IERC20(asset).safeTransfer(tokenReceiever, amount);

        // Enter the callback, handing over execution the callback through the `SWAP_CALLBACK_RELAYER`.
        manager.SWAP_CALLBACK_RELAYER().relaySwapCallback(
            callback,
            amount,
            minimumUSDCRecieved,
            data
        );

        usdcAmountIn = usdc.balanceOf(address(this)) - balanceUSDCBefore;

        // Check to make sure the minimum amount of assets, which was calculated above using the `maxSlippagePercent`,
        // was returned to the contract.
        require(
            usdcAmountIn >= minimumUSDCRecieved,
            GmxFrfStrategyErrors.SWAP_CALLBACK_LOGIC_INSUFFICIENT_USDC_RETURNED
        );

        return usdcAmountIn;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title GmxFrfStrategyErrors
 * @author GoldLink
 *
 * @dev Gmx Delta Neutral Errors library for GMX related interactions.
 */
library GmxFrfStrategyErrors {
    //
    // COMMON
    //
    string internal constant ZERO_ADDRESS_IS_NOT_ALLOWED =
        "Zero address is not allowed.";
    string
        internal constant TOO_MUCH_NATIVE_TOKEN_SPENT_IN_MULTICALL_EXECUTION =
        "Too much native token spent in multicall transaction.";
    string internal constant MSG_VALUE_LESS_THAN_PROVIDED_EXECUTION_FEE =
        "Msg value less than provided execution fee.";
    string internal constant NESTED_MULTICALLS_ARE_NOT_ALLOWED =
        "Nested multicalls are not allowed.";

    //
    // Deployment Configuration Manager
    //
    string
        internal constant DEPLOYMENT_CONFIGURATION_MANAGER_INVALID_DEPLOYMENT_ADDRESS =
        "DeploymentConfigurationManager: Invalid deployment address.";

    //
    // GMX Delta Neutral Funding Rate Farming Manager
    //
    string internal constant CANNOT_ADD_SEPERATE_MARKET_WITH_SAME_LONG_TOKEN =
        "GmxFrfStrategyManager: Cannot add seperate market with same long token.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_LONG_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Long token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyManager: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Short token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_MUST_BE_USDC =
        "GmxFrfStrategyManager: Short token for market must be usdc.";
    string internal constant LONG_TOKEN_CANT_BE_USDC =
        "GmxFrfStrategyManager: Long token can't be usdc.";
    string internal constant MARKET_CAN_ONLY_BE_DISABLED_IN_DECREASE_ONLY_MODE =
        "GmxFrfStrategyManager: Market can only be disabled in decrease only mode.";
    string internal constant MARKETS_COUNT_CANNOT_EXCEED_MAXIMUM =
        "GmxFrfStrategyManager: Market count cannot exceed maximum.";
    string internal constant MARKET_INCREASES_ARE_ALREADY_DISABLED =
        "GmxFrfStrategyManager: Market increases are already disabled.";
    string internal constant MARKET_IS_NOT_ENABLED =
        "GmxFrfStrategyManager: Market is not enabled.";

    //
    // GMX V2 Adapter
    //
    string
        internal constant GMX_V2_ADAPTER_MAX_SLIPPAGE_MUST_BE_LT_100_PERCENT =
        "GmxV2Adapter: Maximum slippage must be less than 100%.";
    string internal constant GMX_V2_ADAPTER_MINIMUM_SLIPPAGE_MUST_BE_LT_MAX =
        "GmxV2Adapter: Minimum slippage must be less than maximum slippage.";

    //
    // Liquidation Management
    //
    string
        internal constant LIQUIDATION_MANAGEMENT_AVAILABLE_TOKEN_BALANCE_MUST_BE_CLEARED_BEFORE_REBALANCING =
        "LiquidationManagement: Available token balance must be cleared before rebalancing.";
    string
        internal constant LIQUIDATION_MANAGEMENT_NO_ASSETS_EXIST_IN_THIS_MARKET_TO_REBALANCE =
        "LiquidationManagement: No assets exist in this market to rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_DELTA_IS_NOT_SUFFICIENT_FOR_SWAP_REBALANCE =
        "LiquidationManagement: Position delta is not sufficient for swap rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_DEVIATION =
        "LiquidationManagement: Position is within max deviation.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_LEVERAGE =
        "LiquidationManagement: Position is within max leverage.";
    string
        internal constant LIQUIDATION_MANAGEMENT_REBALANCE_AMOUNT_LEAVE_TOO_LITTLE_REMAINING_ASSETS =
        "LiquidationManagement: Rebalance amount leaves too little remaining assets.";

    //
    // Swap Callback Logic
    //
    string
        internal constant SWAP_CALLBACK_LOGIC_CALLBACK_ADDRESS_MUST_NOT_HAVE_GMX_CONTROLLER_ROLE =
        "SwapCallbackLogic: Callback address must not have GMX controller role.";
    string internal constant SWAP_CALLBACK_LOGIC_CANNOT_SWAP_USDC =
        "SwapCallbackLogic: Cannot swap USDC.";
    string internal constant SWAP_CALLBACK_LOGIC_INSUFFICIENT_USDC_RETURNED =
        "SwapCallbackLogic: Insufficient USDC returned.";
    string
        internal constant SWAP_CALLBACK_LOGIC_NO_BALANCE_AFTER_SLIPPAGE_APPLIED =
        "SwapCallbackLogic: No balance after slippage applied.";

    //
    // Order Management
    //
    string internal constant ORDER_MANAGEMENT_INVALID_FEE_REFUND_RECIPIENT =
        "OrderManagement: Invalid fee refund recipient.";
    string
        internal constant ORDER_MANAGEMENT_LIQUIDATION_ORDER_CANNOT_BE_CANCELLED_YET =
        "OrderManagement: Liquidation order cannot be cancelled yet.";
    string internal constant ORDER_MANAGEMENT_ORDER_MUST_BE_FOR_THIS_ACCOUNT =
        "OrderManagement: Order must be for this account.";

    //
    // Order Validation
    //
    string
        internal constant ORDER_VALIDATION_ACCEPTABLE_PRICE_IS_NOT_WITHIN_SLIPPAGE_BOUNDS =
        "OrderValidation: Acceptable price is not within slippage bounds.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_CANNOT_BE_ZERO =
        "OrderValidation: Decrease amount cannot be zero.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_IS_TOO_LARGE =
        "OrderValidation: Decrease amount is too large.";
    string
        internal constant ORDER_VALIDATION_EXECUTION_PRICE_NOT_WITHIN_SLIPPAGE_RANGE =
        "OrderValidation: Execution price not within slippage range.";
    string
        internal constant ORDER_VALIDATION_INITIAL_COLLATERAL_BALANCE_IS_TOO_LOW =
        "OrderValidation: Initial collateral balance is too low.";
    string internal constant ORDER_VALIDATION_MARKET_HAS_PENDING_ORDERS =
        "OrderValidation: Market has pending orders.";
    string internal constant ORDER_VALIDATION_ORDER_TYPE_IS_DISABLED =
        "OrderValidation: Order type is disabled.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_LARGE =
        "OrderValidation: Order size is too large.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_SMALL =
        "OrderValidation: Order size is too small.";
    string internal constant ORDER_VALIDATION_POSITION_DOES_NOT_EXIST =
        "OrderValidation: Position does not exist.";
    string
        internal constant ORDER_VALIDATION_POSITION_NOT_OWNED_BY_THIS_ACCOUNT =
        "OrderValidation: Position not owned by this account.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_LARGE =
        "OrderValidation: Position size is too large.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_SMALL =
        "OrderValidation: Position size is too small.";
    string
        internal constant ORDER_VALIDATION_PROVIDED_EXECUTION_FEE_IS_TOO_LOW =
        "OrderValidation: Provided execution fee is too low.";
    string internal constant ORDER_VALIDATION_SWAP_SLIPPAGE_IS_TOO_HGIH =
        "OrderValidation: Swap slippage is too high.";

    //
    // Gmx Funding Rate Farming
    //
    string internal constant GMX_FRF_STRATEGY_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyAccount: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxFrfStrategyAccount: Caller must have controller role.";

    //
    // Gmx V2 Order Callback Receiver
    //
    string
        internal constant GMX_V2_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxV2OrderCallbackReceiver: Caller must have controller role.";

    //
    // Market Configuration Manager
    //
    string
        internal constant ASSET_LIQUIDATION_FEE_CANNOT_BE_GREATER_THAN_MAXIMUM =
        "MarketConfigurationManager: Asset liquidation fee cannot be greater than maximum.";
    string internal constant ASSET_ORACLE_COUNT_CANNOT_EXCEED_MAXIMUM =
        "MarketConfigurationManager: Asset oracle count cannot exceed maximum.";
    string
        internal constant CANNOT_SET_MAX_POSITION_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxPositionSlippagePercent below the minimum value.";
    string
        internal constant CANNOT_SET_THE_CALLBACK_GAS_LIMIT_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the callback gas limit above the maximum.";
    string internal constant CANNOT_SET_MAX_SWAP_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxSwapSlippagePercent below minimum value.";
    string
        internal constant CANNOT_SET_THE_EXECUTION_FEE_BUFFER_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the execution fee buffer above the maximum.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_ORDER_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_ORDER_SIZE =
        "MarketConfigurationManager: Min order size must be less than or equal to max order size.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_POSITION_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_POSITION_SIZE =
        "MarketConfigurationManager: Min position size must be less than or equal to max position size.";
    string
        internal constant MAX_DELTA_PROPORTION_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxDeltaProportion is below the minimum required value.";
    string
        internal constant MAX_POSITION_LEVERAGE_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxPositionLeverage is below the minimum required value.";
    string internal constant UNWIND_FEE_IS_ABOVE_THE_MAXIMUM_ALLOWED_VALUE =
        "MarketConfigurationManager: UnwindFee is above the maximum allowed value.";
    string
        internal constant WITHDRAWAL_BUFFER_PERCENTAGE_MUST_BE_GREATER_THAN_THE_MINIMUM =
        "MarketConfigurationManager: WithdrawalBufferPercentage must be greater than the minimum.";
    //
    // Withdrawal Logic Errors
    //
    string
        internal constant CANNOT_WITHDRAW_BELOW_THE_ACCOUNTS_LOAN_VALUE_WITH_BUFFER_APPLIED =
        "WithdrawalLogic: Cannot withdraw to below the account's loan value with buffer applied.";
    string
        internal constant CANNOT_WITHDRAW_FROM_MARKET_IF_ACCOUNT_MARKET_DELTA_IS_SHORT =
        "WithdrawalLogic: Cannot withdraw from market if account's market delta is short.";
    string internal constant CANNOT_WITHDRAW_MORE_TOKENS_THAN_ACCOUNT_BALANCE =
        "WithdrawalLogic: Cannot withdraw more tokens than account balance.";
    string
        internal constant REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_CURRENT_DELTA_DIFFERENCE =
        "WithdrawalLogic: Requested amount exceeds current delta difference.";
    string
        internal constant WITHDRAWAL_BRINGS_ACCOUNT_BELOW_MINIMUM_OPEN_HEALTH_SCORE =
        "WithdrawalLogic: Withdrawal brings account below minimum open health score.";
    string internal constant WITHDRAWAL_VALUE_CANNOT_BE_GTE_ACCOUNT_VALUE =
        "WithdrawalLogic: Withdrawal value cannot be gte to account value.";
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IMarketConfiguration } from "./IMarketConfiguration.sol";
import { IDeploymentConfiguration } from "./IDeploymentConfiguration.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IGmxFrfStrategyManager
 * @author GoldLink
 *
 * @dev Interface for manager contract for configuration vars.
 */
interface IGmxFrfStrategyManager is
    IMarketConfiguration,
    IDeploymentConfiguration,
    IChainlinkAdapter
{}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { ISwapCallbackHandler } from "./ISwapCallbackHandler.sol";

/**
 * @title ISwapCallbackRelayer
 * @author GoldLink
 *
 * @dev Serves as a middle man for executing the swapCallback function in order to
 * prevent any issues that arise due to signature collisions and the msg.sender context
 * of a strategyAccount.
 */
interface ISwapCallbackRelayer {
    // ============ External Functions ============

    /// @dev Relay a swap callback on behalf of another address.
    function relaySwapCallback(
        address callbackHandler,
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";

/**
 * @title Pricing
 * @author GoldLink
 *
 * @dev Library for price conversion for getting the GMX price and USDC price.
 * The internal GMX account system uses 30 decimals to represent USD prices per unit of the underlying token.
 * Example from the GMX documentation:
 * The price of ETH is 5000, and ETH has 18 decimals.
 * The price of one unit of ETH is 5000 / (10 ^ 18), 5 * (10 ^ -15).
 * To handle the decimals, multiply the value by (10 ^ 30).
 * Price would be stored as 5000 / (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12).
 * To read more, see GMX's documentation on oracle prices: https://github.com/gmx-io/gmx-synthetics?tab=readme-ov-file#oracle-prices
 */
library Pricing {
    // ============ Constants ============

    /// @dev The number of decimals used to represent USD within GMX.
    uint256 internal constant USD_DECIMALS = 30;

    // ============ Internal Functions ============

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param oracle      The `IGmxFrfStrategyManager` to use for the valuation.
     * @param asset       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @param tokenAmount The token amount to get the valuation for.
     * @return assetValue The value of the token amount in USD.
     */
    function getTokenValueUSD(
        IGmxFrfStrategyManager oracle,
        address asset,
        uint256 tokenAmount
    ) internal view returns (uint256 assetValue) {
        // Exit early if the token amount is 0.
        if (tokenAmount == 0) {
            return 0;
        }

        // Query the oracle for the price of the asset.
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, asset);

        return getTokenValueUSD(tokenAmount, assetPrice);
    }

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param  tokenAmount The token amount to get the valuation for.
     * @param  price       The price of the token in USD. (1 USD = 1e30).
     * @return assetValue  The value of the token amount in USD.
     * @dev The provided  `IChainlinkAdapter` MUST have a price precision of 30.
     */
    function getTokenValueUSD(
        uint256 tokenAmount,
        uint256 price
    ) internal pure returns (uint256 assetValue) {
        // Per the GMX documentation, the value of a token in terms of USD is simply calculated via multiplication.
        // This is because the USD price already inherently accounts for the decimals of the token.
        return price * tokenAmount;
    }

    /**
     * @notice Gets the price of a given token per unit in USD. USD is represented with 30 decimals of precision.
     * @param oracle      The `IChainlinkAdapter` to use for pricing this token.
     * @param token       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @return assetValue The value of the token amount in USD.
     */
    function getUnitTokenPriceUSD(
        IGmxFrfStrategyManager oracle,
        address token
    ) internal view returns (uint256) {
        (uint256 price, uint256 oracleDecimals) = oracle.getAssetPrice(token);

        // The total decimals that the price is represented with, which includes both the oracle's
        // decimals and the token's decimals.
        uint256 totalPriceDecimals = oracleDecimals + getAssetDecimals(token);

        // The offset in decimals between the USD price and the the both the oracle's decimals and the token's decimals.
        uint256 decimalOffset = Math.max(USD_DECIMALS, totalPriceDecimals) -
            Math.min(USD_DECIMALS, totalPriceDecimals);

        return
            (USD_DECIMALS >= totalPriceDecimals)
                ? price * (10 ** decimalOffset)
                : price / (10 ** decimalOffset);
    }

    /**
     * @notice Get the amount of a token that is equivalent to a given USD amount based on `token's` current oracle price.
     * @param oracle       The `IChainlinkAdapter` to use for querying the oracle price for this token.
     * @param token        The token address for the token to quote `usdAmount` in.
     * @param usdAmount    The amount in USD to convert to tokens. (1 usd = 1^30)
     * @return tokenAmount The amount of `token` equivalent to `usdAmount` based on the current `oracle` price.
     */
    function getTokenAmountForUSD(
        IGmxFrfStrategyManager oracle,
        address token,
        uint256 usdAmount
    ) internal view returns (uint256) {
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, token);

        // As defined per the GMX documentation, the value of a token in terms of USD is simply calculated via division.
        return usdAmount / assetPrice;
    }

    /**
     * @notice Fetch decimals for an asset.
     * @param token     The token to get the decimals for.
     * @return decimals The decimals of the token.
     */
    function getAssetDecimals(
        address token
    ) internal view returns (uint256 decimals) {
        return IERC20Metadata(token).decimals();
    }
}

// SPDX-License-Identifier: AGPL-3.0

import { Constants } from "./Constants.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

pragma solidity 0.8.20;

/**
 * @title PercentMath
 * @author GoldLink
 *
 * @dev Library for calculating percentages and fractions from percentages.
 * Meant to handle getting fractions in WAD and fraction values from percentages.
 */
library PercentMath {
    using Math for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Implements percent to fraction, deriving a fraction from a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds down.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFraction(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return whole.mulDiv(percentage, Constants.ONE_HUNDRED_PERCENT);
    }

    /**
     * @notice Implements percent to fraction ceil, deriving a fraction from
     * the ceiling of a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds up.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFractionCeil(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return
            whole.mulDiv(
                percentage,
                Constants.ONE_HUNDRED_PERCENT,
                Math.Rounding.Ceil
            );
    }

    /**
     * @notice Implements fraction to percent, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds down.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercent(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return fraction.mulDiv(Constants.ONE_HUNDRED_PERCENT, whole);
    }

    /**
     * @notice Implements fraction to percent ceil, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds up.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercentCeil(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return
            fraction.mulDiv(
                Constants.ONE_HUNDRED_PERCENT,
                whole,
                Math.Rounding.Ceil
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IMarketConfiguration
 * @author GoldLink
 *
 * @dev Manages the configuration of markets for the GmxV2 funding rate farming strategy.
 */
interface IMarketConfiguration {
    // ============ Structs ============

    /// @dev Parameters for pricing an order.
    struct OrderPricingParameters {
        // The maximum swap slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxSwapSlippagePercent;
        // The maximum slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxPositionSlippagePercent;
        // The minimum order size in USD for this market.
        uint256 minOrderSizeUsd;
        // The maximum order size in USD for this market.
        uint256 maxOrderSizeUsd;
        // Whether or not increase orders are enabled.
        bool increaseEnabled;
    }

    /// @dev Parameters for unwinding an order.
    struct UnwindParameters {
        // The minimum amount of delta the position is allowed to have before it can be rebalanced.
        uint256 maxDeltaProportion;
        // The minimum size of a token sale rebalance required. This is used to prevent dust orders from preventing rebalancing of a position via unwinding a position from occuring.
        uint256 minSwapRebalanceSize;
        // The maximum amount of leverage a position is allowed to have.
        uint256 maxPositionLeverage;
        // The fee rate that pays rebalancers for purchasing additional assets to match the short position.
        uint256 unwindFee;
    }

    /// @dev Parameters shared across order types for a market.
    struct SharedOrderParameters {
        // The callback gas limit for all orders.
        uint256 callbackGasLimit;
        // The execution fee buffer percentage required for placing an order.
        uint256 executionFeeBufferPercent;
        // The referral code to use for all orders.
        bytes32 referralCode;
        // The ui fee receiver used for all orders.
        address uiFeeReceiver;
        // The `withdrawalBufferPercentage` for all accounts.
        uint256 withdrawalBufferPercentage;
    }

    /// @dev Parameters for a position established on GMX through the strategy.
    struct PositionParameters {
        // The minimum position size in USD for this market, in order to prevent
        // dust orders from needing to be liquidated. This implies that if a position is partially closed,
        // the value of the position after the partial close must be greater than this value.
        uint256 minPositionSizeUsd;
        // The maximum position size in USD for this market.
        uint256 maxPositionSizeUsd;
    }

    /// @dev Object containing all parameters for a market.
    struct MarketConfiguration {
        // The order pricing parameters for the market.
        OrderPricingParameters orderPricingParameters;
        // The shared order parameters for the market.
        SharedOrderParameters sharedOrderParameters;
        // The position parameters for the market.
        PositionParameters positionParameters;
        // The unwind parameters for the market.
        UnwindParameters unwindParameters;
    }

    // ============ Events ============

    /// @notice Emitted when setting the configuration for a market.
    /// @param market             The address of the market whose configuration is being updated.
    /// @param marketParameters   The updated market parameters for the market.
    /// @param positionParameters The updated position parameters for the market.
    /// @param unwindParameters   The updated unwind parameters for the market.
    event MarketConfigurationSet(
        address indexed market,
        OrderPricingParameters marketParameters,
        PositionParameters positionParameters,
        UnwindParameters unwindParameters
    );

    /// @notice Emitted when setting the asset liquidation fee.
    /// @param asset                    The asset whose liquidation fee percent is being set.
    /// @param newLiquidationFeePercent The new liquidation fee percent for the asset.
    event AssetLiquidationFeeSet(
        address indexed asset,
        uint256 newLiquidationFeePercent
    );

    /// @notice Emitted when setting the liquidation order timeout deadline.
    /// @param newLiquidationOrderTimeoutDeadline The window after which a liquidation order
    /// can be canceled.
    event LiquidationOrderTimeoutDeadlineSet(
        uint256 newLiquidationOrderTimeoutDeadline
    );

    /// @notice Emitted when setting the callback gas limit.
    /// @param newCallbackGasLimit The gas limit on any callback made from the strategy.
    event CallbackGasLimitSet(uint256 newCallbackGasLimit);

    /// @notice Emitted when setting the execution fee buffer percent.
    /// @param newExecutionFeeBufferPercent The percentage of the initially calculated execution fee that needs to be provided additionally
    /// to prevent orders from failing execution.
    event ExecutionFeeBufferPercentSet(uint256 newExecutionFeeBufferPercent);

    /// @notice Emitted when setting the referral code.
    /// @param newReferralCode The code applied to all orders for the strategy, tying orders back to
    /// this protocol.
    event ReferralCodeSet(bytes32 newReferralCode);

    /// @notice Emitted when setting the ui fee receiver.
    /// @param newUiFeeReceiver The fee paid to the UI, this protocol for placing orders.
    event UiFeeReceiverSet(address newUiFeeReceiver);

    /// @notice Emitted when setting the withdrawal buffer percentage.
    /// @param newWithdrawalBufferPercentage The new withdrawal buffer percentage that was set.
    event WithdrawalBufferPercentageSet(uint256 newWithdrawalBufferPercentage);

    // ============ External Functions ============

    /// @dev Set a market for the GMX FRF strategy.
    function setMarket(
        address market,
        IChainlinkAdapter.OracleConfiguration memory oracleConfig,
        OrderPricingParameters memory marketParameters,
        PositionParameters memory positionParameters,
        UnwindParameters memory unwindParameters,
        uint256 longTokenLiquidationFeePercent
    ) external;

    /// @dev Update the oracle for USDC.
    function updateUsdcOracle(
        IChainlinkAdapter.OracleConfiguration calldata strategyAssetOracleConfig
    ) external;

    /// @dev Disable increase orders in a market.
    function disableMarketIncreases(address marketAddress) external;

    /// @dev Set the asset liquidation fee percentage for an asset.
    function setAssetLiquidationFee(
        address asset,
        uint256 newLiquidationFeePercent
    ) external;

    /// @dev Set the asset liquidation timeout for an asset. The time that must
    /// pass before a liquidated order can be cancelled.
    function setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) external;

    /// @dev Set the callback gas limit.
    function setCallbackGasLimit(uint256 newCallbackGasLimit) external;

    /// @dev Set the execution fee buffer percent.
    function setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) external;

    /// @dev Set the referral code for all trades made through the GMX Frf strategy.
    function setReferralCode(bytes32 newReferralCode) external;

    /// @dev Set the address of the UI fee receiver.
    function setUiFeeReceiver(address newUiFeeReceiver) external;

    /// @dev Set the buffer on the account value that must be maintained to withdraw profit
    /// with an active loan.
    function setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) external;

    /// @dev Get if a market is approved for the GMX FRF strategy.
    function isApprovedMarket(address market) external view returns (bool);

    /// @dev Get the config that dictates parameters for unwinding an order.
    function getMarketUnwindConfiguration(
        address market
    ) external view returns (UnwindParameters memory);

    /// @dev Get the config for a specific market.
    function getMarketConfiguration(
        address market
    ) external view returns (MarketConfiguration memory);

    /// @dev Get the list of available markets for the GMX FRF strategy.
    function getAvailableMarkets() external view returns (address[] memory);

    /// @dev Get the asset liquidation fee percent.
    function getAssetLiquidationFeePercent(
        address asset
    ) external view returns (uint256);

    /// @dev Get the liquidation order timeout deadline.
    function getLiquidationOrderTimeoutDeadline()
        external
        view
        returns (uint256);

    /// @dev Get the callback gas limit.
    function getCallbackGasLimit() external view returns (uint256);

    /// @dev Get the execution fee buffer percent.
    function getExecutionFeeBufferPercent() external view returns (uint256);

    /// @dev Get the referral code.
    function getReferralCode() external view returns (bytes32);

    /// @dev Get the UI fee receiver
    function getUiFeeReceiver() external view returns (address);

    /// @dev Get profit withdraw buffer percent.
    function getProfitWithdrawalBufferPercent() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IGmxV2ExchangeRouter
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import { ISwapCallbackRelayer } from "./ISwapCallbackRelayer.sol";

/**
 * @title IDeploymentConfiguration
 * @author GoldLink
 *
 * @dev Actions that can be performed by the GMX V2 Adapter Controller.
 */
interface IDeploymentConfiguration {
    // ============ Structs ============

    struct Deployments {
        IGmxV2ExchangeRouter exchangeRouter;
        address orderVault;
        IGmxV2Reader reader;
        IGmxV2DataStore dataStore;
        IGmxV2RoleStore roleStore;
        IGmxV2ReferralStorage referralStorage;
    }

    // ============ Events ============

    /// @notice Emitted when setting the exchange router.
    /// @param exchangeRouter The address of the exhcange router being set.
    event ExchangeRouterSet(address exchangeRouter);

    /// @notice Emitted when setting the order vault.
    /// @param orderVault The address of the order vault being set.
    event OrderVaultSet(address orderVault);

    /// @notice Emitted when setting the reader.
    /// @param reader The address of the reader being set.
    event ReaderSet(address reader);

    /// @notice Emitted when setting the data store.
    /// @param dataStore The address of the data store being set.
    event DataStoreSet(address dataStore);

    /// @notice Emitted when setting the role store.
    /// @param roleStore The address of the role store being set.
    event RoleStoreSet(address roleStore);

    /// @notice Emitted when setting the referral storage.
    /// @param referralStorage The address of the referral storage being set.
    event ReferralStorageSet(address referralStorage);

    // ============ External Functions ============

    /// @dev Set the exchange router for the strategy.
    function setExchangeRouter(IGmxV2ExchangeRouter exchangeRouter) external;

    /// @dev Set the order vault for the strategy.
    function setOrderVault(address orderVault) external;

    /// @dev Set the reader for the strategy.
    function setReader(IGmxV2Reader reader) external;

    /// @dev Set the data store for the strategy.
    function setDataStore(IGmxV2DataStore dataStore) external;

    /// @dev Set the role store for the strategy.
    function setRoleStore(IGmxV2RoleStore roleStore) external;

    /// @dev Set the referral storage for the strategy.
    function setReferralStorage(IGmxV2ReferralStorage referralStorage) external;

    /// @dev Get the configured Gmx V2 `ExchangeRouter` deployment address.
    function gmxV2ExchangeRouter() external view returns (IGmxV2ExchangeRouter);

    /// @dev Get the configured Gmx V2 `OrderVault` deployment address.
    function gmxV2OrderVault() external view returns (address);

    /// @dev Get the configured Gmx V2 `Reader` deployment address.
    function gmxV2Reader() external view returns (IGmxV2Reader);

    /// @dev Get the configured Gmx V2 `DataStore` deployment address.
    function gmxV2DataStore() external view returns (IGmxV2DataStore);

    /// @dev Get the configured Gmx V2 `RoleStore` deployment address.
    function gmxV2RoleStore() external view returns (IGmxV2RoleStore);

    /// @dev Get the configured Gmx V2 `ReferralStorage` deployment address.
    function gmxV2ReferralStorage()
        external
        view
        returns (IGmxV2ReferralStorage);

    /// @dev Get the usdc deployment address.
    function USDC() external view returns (IERC20);

    /// @dev Get the wrapped native token deployment address.
    function WRAPPED_NATIVE_TOKEN() external view returns (IWrappedNativeToken);

    /// @dev The collateral claim distributor.
    function COLLATERAL_CLAIM_DISTRIBUTOR() external view returns (address);

    /// @dev Get the wrapped native token deployment address.
    function SWAP_CALLBACK_RELAYER()
        external
        view
        returns (ISwapCallbackRelayer);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IChainlinkAggregatorV3 } from "./external/IChainlinkAggregatorV3.sol";

/**
 * @title IChainlinkAdapter
 * @author GoldLink
 *
 * @dev Oracle registry interface for registering and retrieving price feeds for assets using chainlink oracles.
 */
interface IChainlinkAdapter {
    // ============ Structs ============

    /// @dev Struct to hold the configuration for an oracle.
    struct OracleConfiguration {
        // The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
        uint256 validPriceDuration;
        // The address of the chainlink oracle to fetch prices from.
        IChainlinkAggregatorV3 oracle;
    }

    // ============ Events ============

    /// @notice Emitted when registering an oracle for an asset.
    /// @param asset              The address of the asset whose price oracle is beig set.
    /// @param oracle             The address of the price oracle for the asset.
    /// @param validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
    event AssetOracleRegistered(
        address indexed asset,
        IChainlinkAggregatorV3 indexed oracle,
        uint256 validPriceDuration
    );

    /// @notice Emitted when removing a price oracle for an asset.
    /// @param asset The asset whose price oracle is being removed.
    event AssetOracleRemoved(address indexed asset);

    // ============ External Functions ============

    /// @dev Get the price of an asset.
    function getAssetPrice(
        address asset
    ) external view returns (uint256 price, uint256 oracleDecimals);

    /// @dev Get the oracle registered for a specific asset.
    function getAssetOracle(
        address asset
    ) external view returns (IChainlinkAggregatorV3 oracle);

    /// @dev Get the oracle configuration for a specific asset.
    function getAssetOracleConfiguration(
        address asset
    )
        external
        view
        returns (IChainlinkAggregatorV3 oracle, uint256 validPriceDuration);

    /// @dev Get all assets registered with oracles in this adapter.
    function getRegisteredAssets()
        external
        view
        returns (address[] memory registeredAssets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title ISwapCallbackHandler
 * @author GoldLink
 *
 * @dev Interfaces that implents the `handleSwapCallback` function, which allows
 * atomic swaps of spot assets for the purpose of liquidations and user profit swaps.
 */
interface ISwapCallbackHandler {
    // ============ External Functions ============

    /// @dev Handle a swap callback.
    function handleSwapCallback(
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Constants
 * @author GoldLink
 *
 * @dev Core constants for the GoldLink Protocol.
 */
library Constants {
    ///
    /// COMMON
    ///
    /// @dev ONE_HUNDRED_PERCENT is one WAD.
    uint256 internal constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWrappedNativeToken
 * @author GoldLink
 *
 * @dev Interface for wrapping native network tokens.
 */
interface IWrappedNativeToken is IERC20 {
    // ============ External Functions ============

    /// @dev Deposit ETH into contract for wrapped tokens.
    function deposit() external payable;

    /// @dev Withdraw ETH by burning wrapped tokens.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IGmxV2OrderTypes
} from "../../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's ExchangeRouter.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/router/ExchangeRouter.sol
 */
interface IGmxV2ExchangeRouter {
    struct SimulatePricesParams {
        address[] primaryTokens;
        IGmxV2PriceTypes.Props[] primaryPrices;
    }

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external payable;

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function setSavedCallbackContract(
        address market,
        address callbackContract
    ) external payable;

    function cancelWithdrawal(bytes32 key) external payable;

    function createOrder(
        IGmxV2OrderTypes.CreateOrderParams calldata params
    ) external payable returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    function cancelOrder(bytes32 key) external payable;

    function simulateExecuteOrder(
        bytes32 key,
        SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    function setUiFeeFactor(uint256 uiFeeFactor) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/Reader.sol
// Modified as follows:
// - Using GoldLink types

pragma solidity ^0.8.0;

import {
    IGmxV2MarketTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { IGmxV2OrderTypes } from "./IGmxV2OrderTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2DataStore
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";

interface IGmxV2Reader {
    function getMarket(
        IGmxV2DataStore dataStore,
        address key
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getMarketBySalt(
        IGmxV2DataStore dataStore,
        bytes32 salt
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getPosition(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2PositionTypes.Props memory);

    function getOrder(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2OrderTypes.Props memory);

    function getPositionPnlUsd(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2PositionTypes.Props[] memory);

    function getAccountPositionInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32[] memory positionKeys,
        IGmxV2MarketTypes.MarketPrices[] memory prices,
        address uiFeeReceiver
    ) external view returns (IGmxV2PositionTypes.PositionInfo[] memory);

    function getPositionInfo(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32 positionKey,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (IGmxV2PositionTypes.PositionInfo memory);

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2OrderTypes.Props[] memory);

    function getMarkets(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.Props[] memory);

    function getMarketInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices[] memory marketPricesList,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.MarketInfo[] memory);

    function getMarketInfo(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address marketKey
    ) external view returns (IGmxV2MarketTypes.MarketInfo memory);

    function getMarketTokenPrice(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        IGmxV2PriceTypes.Props memory longTokenPrice,
        IGmxV2PriceTypes.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IGmxV2MarketTypes.PoolValueInfo memory);

    function getNetPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnlToPoolFactor(
        IGmxV2DataStore dataStore,
        address marketAddress,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getSwapAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address tokenIn,
        uint256 amountIn,
        address uiFeeReceiver
    )
        external
        view
        returns (uint256, int256, IGmxV2PriceTypes.SwapFees memory fees);

    function getExecutionPrice(
        IGmxV2DataStore dataStore,
        address marketKey,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        uint256 positionSizeInUsd,
        uint256 positionSizeInTokens,
        int256 sizeDeltaUsd,
        bool isLong
    ) external view returns (IGmxV2PriceTypes.ExecutionPriceResult memory);

    function getSwapPriceImpact(
        IGmxV2DataStore dataStore,
        address marketKey,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        IGmxV2PriceTypes.Props memory tokenInPrice,
        IGmxV2PriceTypes.Props memory tokenOutPrice
    ) external view returns (int256, int256);

    function getAdlState(
        IGmxV2DataStore dataStore,
        address market,
        bool isLong,
        IGmxV2MarketTypes.MarketPrices memory prices
    ) external view returns (uint256, bool, int256, uint256);

    function getDepositAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 longTokenAmount,
        uint256 shortTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256);

    function getWithdrawalAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2DataStore
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Datastore.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/DataStore.sol
 */
interface IGmxV2DataStore {
    // ============ External Functions ============

    function getAddress(bytes32 key) external view returns (address);

    function getUint(bytes32 key) external view returns (uint256);

    function getBool(bytes32 key) external view returns (bool);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsBytes32(
        bytes32 setKey,
        bytes32 value
    ) external view returns (bool);

    function getAddressArray(
        bytes32 key
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2RoleStore
 * @author GoldLink
 *
 * @dev Interface for the GMX role store.
 * Adapted from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/role/RoleStore.sol
 */
interface IGmxV2RoleStore {
    function hasRole(
        address account,
        bytes32 roleKey
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

interface IGmxV2ReferralStorage {}

// SPDX-License-Identifier: MIT
//
// Adapted from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.20;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified from: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/Order.sol
// Modified as follows:
// - Removed all logic
// - Added additional order structs

pragma solidity ^0.8.0;

interface IGmxV2OrderTypes {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation
    }

    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PositionTypes } from "./IGmxV2PositionTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PriceTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Prices, removes all logic from GMX contract and adds additional
 * structs.
 * The structs here come from three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/price/Price.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderPricingUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/SwapPricingUtils.sol
 */
interface IGmxV2PriceTypes {
    struct Props {
        uint256 min;
        uint256 max;
    }

    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        IGmxV2PositionTypes.PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionInfoCache {
        IGmxV2MarketTypes.Props market;
        Props collateralTokenPrice;
        uint256 pendingBorrowingFeeUsd;
        int256 latestLongTokenFundingAmountPerSize;
        int256 latestShortTokenFundingAmountPerSize;
    }

    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 amountAfterFees;
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Types used by Gmx V2 for market information.
 * Adapted from these four files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/Market.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketPoolValueInfo.sol
 */
interface IGmxV2MarketTypes {
    // ============ Enums ============

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct MarketPrices {
        IGmxV2PriceTypes.Props indexTokenPrice;
        IGmxV2PriceTypes.Props longTokenPrice;
        IGmxV2PriceTypes.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        IGmxV2MarketTypes.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }

    struct BaseFundingValues {
        PositionType fundingFeeAmountPerSize;
        PositionType claimableFundingAmountPerSize;
    }

    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct PoolValueInfo {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PositionTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's position types. A few structs are the same as GMX but a number are
 * added.
 * Adapted from these three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/PositionPricingUtils.sol
 */
interface IGmxV2PositionTypes {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        PositionFees fees;
        IGmxV2PriceTypes.ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionFeesParams {
        address dataStore;
        address referralStorage;
        IGmxV2PositionTypes.Props position;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        bool forPositiveImpact;
        address longToken;
        address shortToken;
        uint256 sizeDeltaUsd;
        address uiFeeReceiver;
    }

    struct GetPriceImpactUsdParams {
        address dataStore;
        IGmxV2MarketTypes.Props market;
        int256 usdDelta;
        bool isLong;
    }

    struct OpenInterestParams {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }

    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}