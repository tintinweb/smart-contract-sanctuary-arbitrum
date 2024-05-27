// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    BeaconProxy
} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

import {
    IGmxFrfStrategyDeployer
} from "./interfaces/IGmxFrfStrategyDeployer.sol";
import { IStrategyAccount } from "../../interfaces/IStrategyAccount.sol";
import { IStrategyController } from "../../interfaces/IStrategyController.sol";
import { GmxFrfStrategyErrors } from "./GmxFrfStrategyErrors.sol";

/**
 * @title GmxFrfStrategyDeployer
 * @author GoldLink
 *
 * @notice Contract that deploys new strategy accounts for the GMX funding rate farming strategy.
 */
contract GmxFrfStrategyDeployer is IGmxFrfStrategyDeployer {
    // ============ Constants ============

    /// @notice The upgradeable beacon specifying the implementation code for strategy accounts
    /// managed by this strategy manager.
    address public immutable ACCOUNT_BEACON;

    // ============ Modifiers ============

    /// @dev Require address is not zero.
    modifier onlyNonZeroAddress(address addressToCheck) {
        require(
            addressToCheck != address(0),
            GmxFrfStrategyErrors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        _;
    }

    // ============ Initializer ============

    constructor(address accountBeacon) onlyNonZeroAddress(accountBeacon) {
        ACCOUNT_BEACON = accountBeacon;
    }

    // ============ External Functions ============

    /**
     * @notice Deploy account, a new strategy account able to deploy funds into the GMX
     * delta neutral funding rate farming strategy. Since the deployed account does not have any special permissions throughout the protocol,
     * there is no reason to restrict verify the caller.
     * @param owner    The owner of the newly deployed account.
     * @return account The newly deployed account.
     */
    function deployAccount(
        address owner,
        IStrategyController strategyController
    )
        external
        override
        onlyNonZeroAddress(owner)
        onlyNonZeroAddress(address(strategyController))
        returns (address account)
    {
        bytes memory initializeCalldata = abi.encodeCall(
            IStrategyAccount.initialize,
            (owner, strategyController)
        );
        account = address(new BeaconProxy(ACCOUNT_BEACON, initializeCalldata));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "./IBeacon.sol";
import {Proxy} from "../Proxy.sol";
import {ERC1967Utils} from "../ERC1967/ERC1967Utils.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address can only be set once during construction, and cannot be changed afterwards. It is stored in an
 * immutable variable to avoid unnecessary storage reads, and also in the beacon storage slot specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] so that it can be accessed externally.
 *
 * CAUTION: Since the beacon address can never be changed, you must ensure that you either control the beacon, or trust
 * the beacon to not upgrade the implementation maliciously.
 *
 * IMPORTANT: Do not use the implementation logic to modify the beacon storage slot. Doing so would leave the proxy in
 * an inconsistent state where the beacon storage slot does not match the beacon address.
 */
contract BeaconProxy is Proxy {
    // An immutable address for the beacon to avoid unnecessary SLOADs before each delegate call.
    address private immutable _beacon;

    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     * - If `data` is empty, `msg.value` must be zero.
     */
    constructor(address beacon, bytes memory data) payable {
        ERC1967Utils.upgradeBeaconToAndCall(beacon, data);
        _beacon = beacon;
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Returns the beacon.
     */
    function _getBeacon() internal view virtual returns (address) {
        return _beacon;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IStrategyAccountDeployer
} from "../../../interfaces/IStrategyAccountDeployer.sol";
import { IMarketConfiguration } from "./IMarketConfiguration.sol";
import { IDeploymentConfiguration } from "./IDeploymentConfiguration.sol";

/**
 * @title IGmxFrfStrategyDeployer
 * @author GoldLink
 *
 * @dev Strategy account deployer for the GMX FRF strategy.
 */
interface IGmxFrfStrategyDeployer is IStrategyAccountDeployer {
    // ============ External Functions ============

    /// @dev Get the address of the account beacon.
    function ACCOUNT_BEACON() external view returns (address beacon);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyBank } from "./IStrategyBank.sol";
import { IStrategyController } from "./IStrategyController.sol";

/**
 * @title IStrategyAccount
 * @author GoldLink
 *
 * @dev Base interface for the strategy account.
 */
interface IStrategyAccount {
    // ============ Enums ============

    /// @dev The liquidation status of an account, if a multi-step liquidation is actively
    /// occurring or not.
    enum LiquidationStatus {
        // The account is not actively in a multi-step liquidation state.
        INACTIVE,
        // The account is actively in a multi-step liquidation state.
        ACTIVE
    }

    // ============ Events ============

    /// @notice Emitted when a liquidation is initiated.
    /// @param accountValue The value of the account, in terms of the `strategyAsset`, that was
    /// used to determine if the account was liquidatable.
    event InitiateLiquidation(uint256 accountValue);

    /// @notice Emitted when a liquidation is processed, which can occur once an account has been fully liquidated.
    /// @param executor The address of the executor that processed the liquidation, and the reciever of the execution premium.
    /// @param strategyAssetsBeforeLiquidation The amount of `strategyAsset` in the account before liquidation.
    /// @param strategyAssetsAfterLiquidation The amount of `strategyAsset` in the account after liquidation.
    event ProcessLiquidation(
        address indexed executor,
        uint256 strategyAssetsBeforeLiquidation,
        uint256 strategyAssetsAfterLiquidation
    );

    /// @notice Emitted when native assets are withdrawn.
    /// @param receiver The address the assets were sent to.
    /// @param amount   The amount of tokens sent.
    event WithdrawNativeAsset(address indexed receiver, uint256 amount);

    /// @notice Emitted when ERC-20 assets are withdrawn.
    /// @param receiver The address the assets were sent to.
    /// @param token    The ERC-20 token that was withdrawn.
    /// @param amount   The amount of tokens sent.
    event WithdrawErc20Asset(
        address indexed receiver,
        IERC20 indexed token,
        uint256 amount
    );

    // ============ External Functions ============

    /// @dev Initialize the account.
    function initialize(
        address owner,
        IStrategyController strategyController
    ) external;

    /// @dev Execute a borrow against the `strategyBank`.
    function executeBorrow(uint256 loan) external returns (uint256 loanNow);

    /// @dev Execute repaying a loan for an existing strategy bank.
    function executeRepayLoan(
        uint256 repayAmount
    ) external returns (uint256 loanNow);

    /// @dev Execute withdrawing collateral for an existing strategy bank.
    function executeWithdrawCollateral(
        address onBehalfOf,
        uint256 collateral,
        bool useSoftWithdrawal
    ) external returns (uint256 collateralNow);

    /// @dev Execute add collateral for the strategy account.
    function executeAddCollateral(
        uint256 collateral
    ) external returns (uint256 collateralNow);

    /// @dev Initiates an account liquidation, checking to make sure that the account's health score puts it in the liquidable range.
    function executeInitiateLiquidation() external;

    /// @dev Processes a liquidation, checking to make sure that all assets have been liquidated, and then notifying the `StrategyBank` of the liquidated asset's for accounting purposes.
    function executeProcessLiquidation()
        external
        returns (uint256 premium, uint256 loanLoss);

    /// @dev Get the positional value of the strategy account.
    function getAccountValue() external view returns (uint256);

    /// @dev Get the owner of this strategy account.
    function getOwner() external view returns (address owner);

    /// @dev Get the liquidation status of the account.
    function getAccountLiquidationStatus()
        external
        view
        returns (LiquidationStatus status);

    /// @dev Get address of strategy bank.
    function STRATEGY_BANK() external view returns (IStrategyBank strategyBank);

    /// @dev Get the GoldLink protocol asset.
    function STRATEGY_ASSET() external view returns (IERC20 strategyAsset);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyAccountDeployer } from "./IStrategyAccountDeployer.sol";
import { IStrategyBank } from "./IStrategyBank.sol";
import { IStrategyReserve } from "./IStrategyReserve.sol";

/**
 * @title IStrategyController
 * @author GoldLink
 *
 * @dev Interface for the `StrategyController`, which manages strategy-wide pausing, reentrancy and acts as a registry for the core strategy contracts.
 */
interface IStrategyController {
    // ============ External Functions ============

    /// @dev Aquire a strategy wide lock, preventing reentrancy across the entire strategy. Callers must unlock after.
    function acquireStrategyLock() external;

    /// @dev Release a strategy lock.
    function releaseStrategyLock() external;

    /// @dev Pauses the strategy, preventing it from taking any new actions. Only callable by the owner.
    function pause() external;

    /// @dev Unpauses the strategy. Only callable by the owner.
    function unpause() external;

    /// @dev Get the address of the `StrategyAccountDeployer` associated with this strategy.
    function STRATEGY_ACCOUNT_DEPLOYER()
        external
        view
        returns (IStrategyAccountDeployer deployer);

    /// @dev Get the address of the `StrategyAsset` associated with this strategy.
    function STRATEGY_ASSET() external view returns (IERC20 asset);

    /// @dev Get the address of the `StrategyBank` associated with this strategy.
    function STRATEGY_BANK() external view returns (IStrategyBank bank);

    /// @dev Get the address of the `StrategyReserve` associated with this strategy.
    function STRATEGY_RESERVE()
        external
        view
        returns (IStrategyReserve reserve);

    /// @dev Return if paused.
    function isPaused() external view returns (bool currentlyPaused);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/Proxy.sol)

pragma solidity ^0.8.20;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback
     * function and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
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

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IStrategyController } from "./IStrategyController.sol";

/**
 * @title IStrategyAccountDeployer
 * @author GoldLink
 *
 * @dev Interface for deploying strategy accounts.
 */
interface IStrategyAccountDeployer {
    // ============ External Functions ============

    /// @dev Deploy a new strategy account for the `owner`.
    function deployAccount(
        address owner,
        IStrategyController strategyController
    ) external returns (address);
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IStrategyReserve } from "./IStrategyReserve.sol";
import { IStrategyAccountDeployer } from "./IStrategyAccountDeployer.sol";

/**
 * @title IStrategyBank
 * @author GoldLink
 *
 * @dev Base interface for the strategy bank.
 */
interface IStrategyBank {
    // ============ Structs ============

    /// @dev Parameters for the strategy bank being created.
    struct BankParameters {
        // The minimum health score a strategy account can actively take on.
        uint256 minimumOpenHealthScore;
        // The health score at which point a strategy account becomes liquidatable.
        uint256 liquidatableHealthScore;
        // The executor premium for executing a completed liquidation.
        uint256 executorPremium;
        // The insurance premium for repaying a loan.
        uint256 insurancePremium;
        // The insurance premium for liquidations, slightly higher than the
        // `INSURANCE_PREMIUM`.
        uint256 liquidationInsurancePremium;
        // The minimum active balance of collateral a strategy account can have.
        uint256 minimumCollateralBalance;
        // The strategy account deployer that deploys new strategy accounts for borrowers.
        IStrategyAccountDeployer strategyAccountDeployer;
    }

    /// @dev Strategy account assets and liabilities representing value in the strategy.
    struct StrategyAccountHoldings {
        // Collateral funds.
        uint256 collateral;
        // Loan capital outstanding.
        uint256 loan;
        // Last interest index for the strategy account.
        uint256 interestIndexLast;
    }

    // ============ Events ============

    /// @notice Emitted when updating the minimum open health score.
    /// @param newMinimumOpenHealthScore The new minimum open health score.
    event UpdateMinimumOpenHealthScore(uint256 newMinimumOpenHealthScore);

    /// @notice Emitted when getting interest and taking insurance before any
    /// reserve state-changing action.
    /// @param totalRequested       The total requested by the strategy reserve and insurance.
    /// @param fromCollateral       The amount of the request that was taken from collateral.
    /// @param interestAndInsurance The interest and insurance paid by this bank. Will be less
    /// than requested if there is not enough collateral + insurance to pay.
    event GetInterestAndTakeInsurance(
        uint256 totalRequested,
        uint256 fromCollateral,
        uint256 interestAndInsurance
    );

    /// @notice Emitted when liquidating a loan.
    /// @param liquidator      The address that performed the liquidation and is
    /// receiving the premium.
    /// @param strategyAccount The address of the strategy account.
    /// @param loanLoss        The loss being sent to lenders.
    /// @param premium         The amount of funds paid to the liquidator from the strategy.
    event LiquidateLoan(
        address indexed liquidator,
        address indexed strategyAccount,
        uint256 loanLoss,
        uint256 premium
    );

    /// @notice Emitted when adding collateral for a strategy account.
    /// @param sender          The address adding collateral.
    /// @param strategyAccount The strategy account address the collateral is for.
    /// @param collateral      The amount of collateral being put up for the loan.
    event AddCollateral(
        address indexed sender,
        address indexed strategyAccount,
        uint256 collateral
    );

    /// @notice Emitted when borrowing funds for a strategy account.
    /// @param strategyAccount The address of the strategy account borrowing funds.
    /// @param loan            The size of the loan to borrow.
    event BorrowFunds(address indexed strategyAccount, uint256 loan);

    /// @notice Emitted when repaying a loan for a strategy account.
    /// @param strategyAccount The address of the strategy account paying back
    /// the loan.
    /// @param repayAmount     The loan assets being repaid.
    /// @param collateralUsed  The collateral used to repay part of the loan if loss occured.
    event RepayLoan(
        address indexed strategyAccount,
        uint256 repayAmount,
        uint256 collateralUsed
    );

    /// @notice Emitted when withdrawing collateral.
    /// @param strategyAccount The address maintaining the strategy account's holdings.
    /// @param onBehalfOf      The address receiving the collateral.
    /// @param collateral      The collateral being withdrawn from the strategy bank.
    event WithdrawCollateral(
        address indexed strategyAccount,
        address indexed onBehalfOf,
        uint256 collateral
    );

    /// @notice Emitted when a strategy account is opened.
    /// @param strategyAccount The address of the strategy account.
    /// @param owner           The address of the strategy account owner.
    event OpenAccount(address indexed strategyAccount, address indexed owner);

    // ============ External Functions ============

    /// @dev Update the minimum open health score for the strategy bank.
    function updateMinimumOpenHealthScore(
        uint256 newMinimumOpenHealthScore
    ) external;

    /// @dev Delegates reentrancy locking to the bank, only callable by valid strategy accounts.
    function acquireLock() external;

    /// @dev Delegates reentrancy unlocking to the bank, only callable by valid strategy accounts.
    function releaseLock() external;

    /// @dev Get interest from this contract for `msg.sender` which must
    /// be the `StrategyReserve` to then transfer out of this contract.
    function getInterestAndTakeInsurance(
        uint256 totalRequested
    ) external returns (uint256 interestToPay);

    /// @dev Processes a strategy account liquidation.
    function processLiquidation(
        address liquidator,
        uint256 availableAccountAssets
    ) external returns (uint256 premium, uint256 loanLoss);

    /// @dev Add collateral for a strategy account into the strategy bank.
    function addCollateral(
        address provider,
        uint256 collateral
    ) external returns (uint256 collateralNow);

    /// @dev Borrow funds from the `StrategyReserve` into the strategy bank.
    function borrowFunds(uint256 loan) external returns (uint256 loanNow);

    /// @dev Repay loaned funds for a holdings.
    function repayLoan(
        uint256 repayAmount,
        uint256 accountValue
    ) external returns (uint256 loanNow);

    /// @dev Withdraw collateral from the strategy bank.
    function withdrawCollateral(
        address onBehalfOf,
        uint256 requestedWithdraw,
        bool useSoftWithdrawal
    ) external returns (uint256 collateralNow);

    /// @dev Open a new strategy account associated with `owner`.
    function executeOpenAccount(
        address owner
    ) external returns (address strategyAccount);

    /// @dev The strategy account deployer that deploys new strategy accounts for borrowers.
    function STRATEGY_ACCOUNT_DEPLOYER()
        external
        view
        returns (IStrategyAccountDeployer strategyAccountDeployer);

    /// @dev Strategy reserve address.
    function STRATEGY_RESERVE()
        external
        view
        returns (IStrategyReserve strategyReserve);

    /// @dev The asset that this strategy uses for lending accounting.
    function STRATEGY_ASSET() external view returns (IERC20 strategyAsset);

    /// @dev Get the minimum open health score.
    function minimumOpenHealthScore_()
        external
        view
        returns (uint256 minimumOpenHealthScore);

    /// @dev Get the liquidatable health score.
    function LIQUIDATABLE_HEALTH_SCORE()
        external
        view
        returns (uint256 liquidatableHealthScore);

    /// @dev Get the executor premium.
    function EXECUTOR_PREMIUM() external view returns (uint256 executorPremium);

    /// @dev Get the liquidation premium.
    function LIQUIDATION_INSURANCE_PREMIUM()
        external
        view
        returns (uint256 liquidationInsurancePremium);

    /// @dev Get the insurance premium.
    function INSURANCE_PREMIUM()
        external
        view
        returns (uint256 insurancePremium);

    /// @dev Get the total collateral deposited.
    function totalCollateral_() external view returns (uint256 totalCollateral);

    /// @dev Get a strategy account's holdings.
    function getStrategyAccountHoldings(
        address strategyAccount
    )
        external
        view
        returns (StrategyAccountHoldings memory strategyAccountHoldings);

    /// @dev Get withdrawable collateral such that it can be taken out while
    /// `minimumOpenHealthScore_` is still respected.
    function getWithdrawableCollateral(
        address strategyAccount
    ) external view returns (uint256 withdrawableCollateral);

    /// @dev Check if a position is liquidatable.
    function isAccountLiquidatable(
        address strategyAccount,
        uint256 positionValue
    ) external view returns (bool isLiquidatable);

    /// @dev Get strategy account's holdings after interest is paid.
    function getStrategyAccountHoldingsAfterPayingInterest(
        address strategyAccount
    ) external view returns (StrategyAccountHoldings memory holdings);

    /// @dev Get list of strategy accounts within two provided indicies.
    function getStrategyAccounts(
        uint256 startIndex,
        uint256 stopIndex
    ) external view returns (address[] memory accounts);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import { IInterestRateModel } from "./IInterestRateModel.sol";
import { IStrategyBank } from "./IStrategyBank.sol";

/**
 * @title IStrategyReserve
 * @author GoldLink
 *
 * @dev Interface for the strategy reserve, GoldLink custom ERC4626.
 */
interface IStrategyReserve is IERC4626, IInterestRateModel {
    // ============ Structs ============

    // @dev Parameters for the reserve to create.
    struct ReserveParameters {
        // The maximum total value allowed in the reserve to be lent.
        uint256 totalValueLockedCap;
        // The reserve's interest rate model.
        InterestRateModelParameters interestRateModel;
        // The name of the ERC20 minted by this vault.
        string erc20Name;
        // The symbol for the ERC20 minted by this vault.
        string erc20Symbol;
    }

    // ============ Events ============

    /// @notice Emitted when the TVL cap is updated. This the maximum
    /// capital lenders can deposit in the reserve.
    /// @param newTotalValueLockedCap The new TVL cap for the reserve.
    event TotalValueLockedCapUpdated(uint256 newTotalValueLockedCap);

    /// @notice Emitted when the balance of the `StrategyReserve` is synced.
    /// @param newBalance The new balance of the reserve after syncing.
    event BalanceSynced(uint256 newBalance);

    /// @notice Emitted when assets are borrowed from the reserve.
    /// @param borrowAmount The amount of assets borrowed by the strategy bank.
    event BorrowAssets(uint256 borrowAmount);

    /// @notice Emitted when assets are repaid to the reserve.
    /// @param initialLoan  The repay amount expected from the strategy bank.
    /// @param returnedLoan The repay amount provided by the strategy bank.
    event Repay(uint256 initialLoan, uint256 returnedLoan);

    // ============ External Functions ============

    /// @dev Update the reserve TVL cap, modifying how many assets can be lent.
    function updateReserveTVLCap(uint256 newTotalValueLockedCap) external;

    /// @dev Borrow assets from the reserve.
    function borrowAssets(
        address strategyAccount,
        uint256 borrowAmount
    ) external;

    /// @dev Register that borrowed funds were repaid.
    function repay(uint256 initialLoan, uint256 returnedLoan) external;

    /// @dev Settle global lender interest and calculate new interest owed
    ///  by a borrower, given their previous loan amount and cached index.
    function settleInterest(
        uint256 loanBefore,
        uint256 interestIndexLast
    ) external returns (uint256 interestOwed, uint256 interestIndexNow);

    /// @dev The strategy bank that can borrow form this reserve.
    function STRATEGY_BANK() external view returns (IStrategyBank strategyBank);

    /// @dev Get the TVL cap for the `StrategyReserve`.
    function tvlCap_() external view returns (uint256 totalValueLockedCap);

    /// @dev Get the utilized assets in the `StrategyReserve`.
    function utilizedAssets_() external view returns (uint256 utilizedAssets);

    /// @dev Calculate new interest owed by a borrower, given their previous
    ///  loan amount and cached index. Does not modify state.
    function settleInterestView(
        uint256 loanBefore,
        uint256 interestIndexLast
    ) external view returns (uint256 interestOwed, uint256 interestIndexNow);

    /// @dev The amount of assets currently available to borrow.
    function availableToBorrow() external view returns (uint256 assets);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

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
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IInterestRateModel
 * @author GoldLink
 *
 * @dev Interface for an interest rate model, responsible for maintaining the
 * cumulative interest index over time.
 */
interface IInterestRateModel {
    // ============ Structs ============

    /// @dev Parameters for an interest rate model.
    struct InterestRateModelParameters {
        // Optimal utilization as a fraction of one WAD (representing 100%).
        uint256 optimalUtilization;
        // Base (i.e. minimum) interest rate a the simple (non-compounded) APR,
        // denominated in WAD.
        uint256 baseInterestRate;
        // The slope at which the interest rate increases with utilization
        // below the optimal point. Denominated in units of:
        // rate per 100% utilization, as WAD.
        uint256 rateSlope1;
        // The slope at which the interest rate increases with utilization
        // after the optimal point. Denominated in units of:
        // rate per 100% utilization, as WAD.
        uint256 rateSlope2;
    }

    // ============ Events ============

    /// @notice Emitted when updating the interest rate model.
    /// @param optimalUtilization The optimal utilization after updating the model.
    /// @param baseInterestRate   The base interest rate after updating the model.
    /// @param rateSlope1         The rate slope one after updating the model.
    /// @param rateSlope2         The rate slope two after updating the model.
    event ModelUpdated(
        uint256 optimalUtilization,
        uint256 baseInterestRate,
        uint256 rateSlope1,
        uint256 rateSlope2
    );

    /// @notice Emitted when interest is settled, updating the cumulative
    ///  interest index and/or the associated timestamp.
    /// @param timestamp               The block timestamp of the index update.
    /// @param cumulativeInterestIndex The new cumulative interest index after updating.
    event InterestSettled(uint256 timestamp, uint256 cumulativeInterestIndex);
}

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