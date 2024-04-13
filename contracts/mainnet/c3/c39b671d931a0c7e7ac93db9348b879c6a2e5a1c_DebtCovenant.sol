// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {AutomationCompatibleInterface} from "chainlink/src/v0.8/automation/AutomationCompatible.sol";
import {ILiquidityWarehouse} from "../interfaces/ILiquidityWarehouse.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {LiquidityWarehouseAccessControl} from "../utils/LiquidityWarehouseAccessControl.sol";
import {IEmergencyPausable} from "../interfaces/IEmergencyPausable.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {ICopraRegistry} from "../interfaces/ICopraRegistry.sol";

contract DebtCovenant is AutomationCompatibleInterface, Ownable2Step {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice This error is thrown whenever withdrawals from the liquidity warehouse fails
    /// @param liquidityWarehouse The liquidity warehouse that the automation job fails
    /// to withdraw from
    error WithdrawalFailed(address liquidityWarehouse);

    /// @notice This error is thrown when a caller calls a function without the
    /// proper access controls
    error AccessForbidden();

    /// @notice This error is thrown when the performUpkeep function is called by an
    /// address other than the forwarder
    error InvalidForwarder();

    /// @notice This event is emitted when the forwarder address is set
    event ForwarderSet(address indexed forwarder);

    /// @notice Action for executing a debt covenant condition
    struct DebtCovenantAction {
        /// @notice True if should pause the liquidity warehouse
        bool shouldActivate;
        /// @notice True if should unpause the liquidity warehouse
        bool shouldDeactivate;
        /// @notice True if should withdraw from the liquidity warehouse
        bool shouldWithdraw;
        /// @notice The address of the liquidity warehouse
        address liquidityWarehouse;
    }

    /// @notice The Copra registry
    ICopraRegistry internal immutable i_copraRegistry;

    /// @notice The forwarder address
    address internal s_forwarder;

    constructor(address copraRegistry) {
        i_copraRegistry = ICopraRegistry(copraRegistry);
    }

    /// @notice Sets the forwarder address
    /// @param forwarder The forwarder address
    function setForwarder(address forwarder) external onlyOwner {
        if (forwarder == address(0)) revert InvalidForwarder();
        s_forwarder = forwarder;
        emit ForwarderSet(forwarder);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function performUpkeep(bytes calldata performData) external override {
        if (msg.sender != s_forwarder) revert AccessForbidden();

        (uint256 numWarehousesToWithdrawFrom, DebtCovenantAction[] memory debtCovenantActions) =
            abi.decode(performData, (uint256, DebtCovenantAction[]));

        for (uint256 i; i < numWarehousesToWithdrawFrom; ++i) {
            DebtCovenantAction memory debtCovenantAction = debtCovenantActions[i];
            address[] memory withdrawTargets =
                ILiquidityWarehouse(debtCovenantAction.liquidityWarehouse).getWithdrawTargets();
            if (debtCovenantAction.shouldActivate) {
                ILiquidityWarehouse(debtCovenantAction.liquidityWarehouse).activate();
            }
            if (debtCovenantAction.shouldDeactivate) {
                ILiquidityWarehouse(debtCovenantAction.liquidityWarehouse).deactivate(withdrawTargets, bytes(""));
            }
            if (debtCovenantAction.shouldWithdraw) {
                ILiquidityWarehouse(debtCovenantAction.liquidityWarehouse).liquidate(withdrawTargets, bytes(""));
            }
        }
    }

    //############//
    //    View    //
    //############//

    /// @notice Returns the forwarder address
    /// @return address The forwarder address
    function getForwarder() external view returns (address) {
        return s_forwarder;
    }

    /// @notice Returns the Copra Registry
    /// @return address The Copra Registry address
    function getCopraRegistry() external view returns (address) {
        return address(i_copraRegistry);
    }

    /// @inheritdoc AutomationCompatibleInterface
    function checkUpkeep(bytes calldata) external view override returns (bool, bytes memory) {
        address[] memory liquidityWarehouses = i_copraRegistry.getLiquidityWarehouses();
        DebtCovenantAction[] memory debtCovenantActions = new DebtCovenantAction[](liquidityWarehouses.length);

        uint256 idx;
        for (uint256 i; i < debtCovenantActions.length; ++i) {
            ILiquidityWarehouse liquidityWarehouse = ILiquidityWarehouse(liquidityWarehouses[i]);
            address[] memory withdrawTargets = liquidityWarehouse.getWithdrawTargets();

            // Only populate the resultant array with actions to update the state of liquidity
            // warehouses that need an update.  We want to exclude having to make calls to liquidity
            // warehouses that do not require an update.  This is so that we do not call the
            // performUpkeep function unnecessarily.
            if (_shouldNotUpdateLiquidityWarehouse(liquidityWarehouse)) continue;

            bool isLiquidationThresholdFulfilled = liquidityWarehouse.isLiquidationThresholdFulfilled();

            if (liquidityWarehouse.isActive()) {
                debtCovenantActions[idx] = DebtCovenantAction({
                    liquidityWarehouse: address(liquidityWarehouse),
                    shouldActivate: false,
                    shouldDeactivate: !isLiquidationThresholdFulfilled,
                    shouldWithdraw: false
                });
            } else {
                debtCovenantActions[idx] = DebtCovenantAction({
                    liquidityWarehouse: address(liquidityWarehouse),
                    shouldActivate: isLiquidationThresholdFulfilled,
                    shouldDeactivate: false,
                    shouldWithdraw: !isLiquidationThresholdFulfilled && _hasLPBalance(liquidityWarehouse, withdrawTargets)
                });
            }

            idx++;
        }
        return (idx > 0, abi.encode(idx, debtCovenantActions));
    }

    //################//
    //    Internal    //
    //################//

    /// @notice Determines whether or not a liquidity warehouse should be updated
    /// @param liquidityWarehouse The liquidity warehouse to check
    /// @return bool True if the liquidity warehouse does NOT need to be updated
    /// @dev The liquidity warehouse does not need to be updated when either
    ///   - The liquidity warehouse is NOT active AND the liquidation threshold is fulfilled
    ///   - The liquidity warehouse IS active AND it has no remaining LP balance from any
    ///     of it's whitelisted pools AND the liquidation threshold is not fulfilled yet
    function _shouldNotUpdateLiquidityWarehouse(ILiquidityWarehouse liquidityWarehouse) internal view returns (bool) {
        bool isLiquidityWarehouseHealthy =
            liquidityWarehouse.isActive() && liquidityWarehouse.isLiquidationThresholdFulfilled();

        bool isWithdrawNotRequired = !liquidityWarehouse.isActive()
            && !liquidityWarehouse.isLiquidationThresholdFulfilled()
            && !_hasLPBalance(liquidityWarehouse, liquidityWarehouse.getWithdrawTargets());

        return isLiquidityWarehouseHealthy || isWithdrawNotRequired;
    }

    /// @notice Helper function to determine whether or not the liquidity warehouse
    /// has a remaining LP balance
    /// @param liquidityWarehouse The liquidity warehouse to check
    /// @param withdrawTargets The target addresses to withdraw from
    /// @return bool True if the debt covenant contract should withdraw from the liquidity warehouse
    function _hasLPBalance(ILiquidityWarehouse liquidityWarehouse, address[] memory withdrawTargets)
        internal
        view
        returns (bool)
    {
        uint256 totalLPBalance;
        for (uint256 i; i < withdrawTargets.length; ++i) {
            totalLPBalance += IERC20(withdrawTargets[i]).balanceOf(address(liquidityWarehouse));
        }
        return totalLPBalance > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AutomationBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {LiquidityWarehouseAccessControl} from "../utils/LiquidityWarehouseAccessControl.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface ILiquidityWarehouse {
    /// @notice The data for an asset
    struct Asset {
        /// @notice The lender's total balance
        uint216 lenderBalance;
        /// @notice The last time the asset's lender balance was updated with interest
        uint40 interestLastUpdatedAt;
    }

    /// @notice The terms of the liquidity warehouse
    struct Terms {
        /// @notice The asset the loans in the liquidity
        /// warehouse is denominated in
        IERC20 asset;
        /// @notice The address that will receive fees
        address feeRecipient;
        /// @notice The liquidation threshold of the liquidity warehouse
        uint64 liquidationThreshold;
        /// @notice The capacity threshold of the liquidity warehouse
        uint64 capacityThreshold;
        /// @notice The interest rate of the liquidity warehouse
        uint64 interestRate;
        /// @notice The fee taken from compounded interest of the liquidity warehouse
        uint64 interestFee;
        /// @notice The fee taken from withdrawals
        uint64 withdrawalFee;
    }

    //################//
    //     Errors     //
    //################//

    /// @notice This error is thrown when an address attempts to execute
    /// a transaction that it does not have permissions for
    error AccessForbidden();

    /// @notice This error is thrown when the liquidity warehouse is active
    error Active();

    /// @notice This error is thrown whenever the amount of shares minted
    /// from a deposit is zero
    error ZeroShareAmt();

    /// @notice This error is thrown when the liquidity warehouse is inactive
    error Inactive();

    /// @notice This error is thrown when there is insufficient liquidity in all
    /// whitelisted targets to cover a withdrawal
    /// @param missingAmount The missing amount of liquidity
    error InsufficientLiquidity(uint256 missingAmount);

    /// @notice This error is thrown when the zero address
    /// is passed in as the asset's address
    error InvalidAsset();

    /// @notice This error is thrown when there is an insufficient
    /// amount of assets that can be withdrawn
    error InsufficientBalance();

    /// @notice This error is thrown when the liquidation threshold
    /// is set to 0
    error InvalidLiquidationThreshold();

    /// @notice This error is thrown when the capacity threshold
    /// is set to 0
    error InvalidCapacityThreshold();

    /// @notice This error is thrown when the fee recipient is set
    /// to the zero address
    error InvalidFeeRecipient();

    /// @notice This error is thrown when the capacity threshold is
    /// breached
    error CapacityThresholdBreached();

    /// @notice This error is thrown when the liquidation threshold
    /// is  breached
    error LiquidationThresholdBreached();

    /// @notice This error is thrown when the liquidation threshold
    /// is not breached
    error LiquidationThresholdNotBreached();

    //################//
    //     Events     //
    //################//

    /// @notice This event is emitted when the is active flag is
    /// set
    /// @param isActive True if the liquidity warehouse has been
    /// set to active
    event IsActiveSet(bool isActive);

    /// @notice This event is emitted when an asset is deposited
    /// @param depositAmount The amount of assets that was deposited
    /// @param isBorrower True if deposited into the borrower pool
    event AssetDeposited(uint256 depositAmount, bool isBorrower);

    /// @notice This event is emitted when an asset is withdrawn
    /// @param withdrawAmount The amount of assets that was withdrawn
    /// @param isBorrower True if withdrawn into the borrower pool
    event AssetWithdrawn(uint256 withdrawAmount, bool isBorrower);

    /// @notice This event is emitted when the liquidation threshold is set
    /// @param oldLiquidationThreshold The old liquidation threshold
    /// @param newLiquidationThreshold The new liquidation threshold
    event LiquidationThresholdSet(uint256 oldLiquidationThreshold, uint256 newLiquidationThreshold);

    /// @notice This event is emitted when the capacity threshold is set
    /// @param oldCapacityThreshold The old capacity threshold
    /// @param newCapacityThreshold The new capacity threshold
    event CapacityThresholdSet(uint256 oldCapacityThreshold, uint256 newCapacityThreshold);

    /// @notice This event is emitted when the interest rate is set
    /// @param oldInterestRate The old interest rate
    /// @param newInterestRate The new interest rate
    event InterestRateSet(uint256 oldInterestRate, uint256 newInterestRate);

    /// @notice This event is emitted when the interest fee is set
    /// @param oldFee The old interest fee
    /// @param newFee The new interest fee
    event InterestFeeSet(uint256 oldFee, uint256 newFee);

    /// @notice This event is emitted when the withdrawal fee is set
    /// @param oldFee The old withdrawal fee
    /// @param newFee The new withdrawal fee
    event WithdrawalFeeSet(uint256 oldFee, uint256 newFee);

    /// @notice This event is emitted when the fee recipient is set
    /// @param oldFeeRecipient The old fee recipient
    /// @param newFeeRecipient The new fee recipient
    event FeeRecipientSet(address indexed oldFeeRecipient, address indexed newFeeRecipient);

    /// @notice This event is emitted when the liquidity warehouse is activated
    event Activated();

    /// @notice This event is emitted when the liquidity warehouse is deactivated
    event Deactivated();

    //################//
    //     Write      //
    //################//

    /// @notice Deactivates pool
    /// @param withdrawTargets The list of targets to withdraw liquidity from
    /// @param data Arbitrary data that can be used when withdrawing
    function deactivate(address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Activates pool
    function activate() external;

    /// @notice Withdraws from all whitelisted pools
    /// @param withdrawTargets The list of targets to withdraw liquidity from
    /// @param data Arbitrary data that can be used when withdrawing
    function liquidate(address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Deposits ERC20 tokens as a lender
    /// @param depositedAmount The amount of assets to deposit
    function depositLender(uint256 depositedAmount) external;

    /// @notice Deposits ERC20 tokens as a borrower
    /// @param depositedAmount The amount of assets to deposit
    function depositBorrower(uint256 depositedAmount) external;

    /// @notice Withdraws ERC20 tokens as a lender
    /// @param shareAmount The amount of shares to burn
    /// @param withdrawTargets The list of addresses to withdraw from in case
    /// there is insufficient liquidity in the warehouse
    /// @param data Arbitrary data that can be used by the underlying implementation
    function withdrawLender(uint256 shareAmount, address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Withdraws lender fees
    /// @param withdrawTargets The list of addresses to withdraw from in case
    /// there is insufficient liquidity in the warehouse
    /// @param data Arbitrary data that can be used by the underlying implementation
    function withdrawLenderFees(address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Withdraws ERC20 tokens as a borrower
    /// @param shareAmount The amount of shares to burn
    /// @param withdrawTargets The list of addresses to withdraw from in case
    /// there is insufficient liquidity in the warehouse
    /// @param data Arbitrary data that can be used by the underlying implementation
    function withdrawBorrower(uint256 shareAmount, address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Withdraws lender fees
    /// @param withdrawTargets The list of addresses to withdraw from in case
    /// there is insufficient liquidity in the warehouse
    /// @param data Arbitrary data that can be used by the underlying implementation
    function withdrawBorrowerFees(address[] calldata withdrawTargets, bytes calldata data) external;

    /// @notice Updates the liquidation threshold
    /// @param liquidationThreshold The new liquidation threshold
    function setLiquidationThreshold(uint256 liquidationThreshold) external;

    /// @notice Updates the capacity threshold
    /// @param capacityThreshold The new capacity threshold
    function setCapacityThreshold(uint256 capacityThreshold) external;

    /// @notice Updates the fees taken from interest
    /// @param fee The new fee taken from interest
    function setInterestFee(uint256 fee) external;

    /// @notice Updates the fee taken from withdrawals
    /// @param fee The new withdrawal fee
    function setWithdrawalFee(uint256 fee) external;

    /// @notice Updates the fee recipient
    /// @param feeRecipient The new fee recipient
    function setFeeRecipient(address feeRecipient) external;

    /// @notice Updates the interest rate
    /// @param interestRate The new interest rate
    function setInterestRate(uint256 interestRate) external;

    /// @notice Toggles a set of actions to either whitelist or unwhitelist them
    /// @param actions The set of actions to toggle whitelisting for
    function toggleWhitelist(LiquidityWarehouseAccessControl.Action[] calldata actions) external;

    /// @notice Executes a set of actions as the liquidity warehouse
    /// @param executeActions The set of actions to execute
    function execute(LiquidityWarehouseAccessControl.ExecuteAction[] calldata executeActions) external payable;

    //#############//
    //     Read     //
    //##############//

    /// @notice Returns true if an action is callable by a caller at a target
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bool True if the caller is able to call the function at the target
    function isWhitelisted(address target, address caller, bytes4 fnSelector) external view returns (bool);

    /// @notice Converts an asset amount to shares
    /// @param isBorrower True if converting borrower assets
    /// @param assetAmount The amount of assets to convert
    /// @return uint256 The amount of shares
    function convertToShares(bool isBorrower, uint256 assetAmount) external view returns (uint256);

    /// @notice Converts a share amount to asset amount
    /// @param isBorrower True if converting borrower shares
    /// @param shareAmount The amount of shares to convert
    /// @return uint256 The amount of assets
    function convertToAssets(bool isBorrower, uint256 shareAmount) external view returns (uint256);

    /// @notice Fetches the lender balance for an asset
    /// @return uint256 The lender balance
    function getLenderBalance() external view returns (uint256);

    /// @notice Fetches the lender withdrawable amount
    /// @return uint256 The lender withdrawable amount
    function getLenderNetAssetValue() external view returns (uint256);

    /// @notice Fetches the borrower withdrawable amount
    /// @return uint256 The borrower withdrawable amount
    function getBorrowerNetAssetValue() external view returns (uint256);

    /// @notice The current terms for the liquidity warehouse
    /// @return Terms The current liquidity warehouse terms
    function getTerms() external view returns (Terms memory);

    /// @notice Fetches the current net asset value of an asset
    /// @return uint256 The net asset value of the asset
    function getNetAssetValue() external view returns (uint256);

    /// @notice Fetches the asset data for an asset
    /// @return Asset The asset's asset data
    function getAssetData() external view returns (Asset memory);

    /// @notice Determines if the liquidation threshold is fulfilled
    /// @return bool True if the liquidation threshold is fulfilled
    function isLiquidationThresholdFulfilled() external view returns (bool);

    /// @notice Determines if the capacity threshold is fulfilled
    /// @return bool True if the capacity threshold is fulfilled
    function isCapacityThresholdFulfilled() external view returns (bool);

    /// @notice Retrieves the list of addresses that the warehouse can withdraw from
    /// @return address[] The list of addresses that the warehouse can withdraw from
    function getWithdrawTargets() external view returns (address[] memory);

    /// @notice Returns whether or not the liquidity warehouse is paused
    /// @return bool True if the liquidity warehouse is paused
    function isPaused() external view returns (bool);

    /// @notice Returns whether or not the liquidity warehouse is active
    /// @return bool True if the liquidity warehouse is active
    function isActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

abstract contract LiquidityWarehouseAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Parameters for an action that
    /// requires access control
    struct Action {
        /// @notice The caller of the action
        address caller;
        /// @notice The target of the action
        address target;
        /// @notice The function that the action
        /// will call
        bytes4 fnSelector;
        /// @notice True if the action is whitelisted
        bool isWhitelisted;
        /// @notice True if this is the withdraw function
        bool isWithdraw;
    }

    /// @notice Parameters for executing an action
    struct ExecuteAction {
        /// @notice The target address the action will call
        address target;
        /// @notice The action's calldata
        bytes data;
        /// @notice The amount of wei to send when executing
        /// the action
        uint256 value;
    }

    //################//
    //     Errors     //
    //################//

    /// @notice This error is thrown whenever an invalid withdraw target is called
    /// @param withdrawTarget The invalid withdraw target address
    error InvalidWithdrawTarget(address withdrawTarget);

    /// @notice This error is thrown whenever a caller tries to execute an action
    /// that they do not have authorization to do
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    error AccessToCallForbidden(address target, address caller, bytes4 fnSelector);

    /// @notice This error is thrown whenever the action being executed fails
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    error ExecutionFailed(address target, address caller, bytes4 fnSelector);

    //################//
    //     Events     //
    //################//

    /// @notice This event is emitted whenever an action is whitelisted or unwhitelisted
    /// @param target The target address the action is calling
    /// @param caller The address trying to execute the action
    /// @param fnSelector The function the action is trying to execute
    /// @param isWhitelisted True if the action is whitelisted
    event WhitelistedActionChanged(
        address indexed target, address indexed caller, bytes4 fnSelector, bool isWhitelisted
    );

    //###########################//
    //     Storage Variables     //
    //###########################//

    /// @notice Tracks the list of whitelisted function calls
    mapping(bytes32 => bool) internal s_isWhitelisted;

    /// @notice Tracks the list of whitelisted addresses that have a withdraw function
    EnumerableSet.AddressSet internal s_withdrawTargets;

    //################//
    //    Internal    //
    //################//

    /// @notice Toggles a set of actions to either whitelist or unwhitelist them
    /// @param actions The set of actions to toggle whitelisting for
    function _toggleWhitelist(Action[] calldata actions) internal {
        for (uint256 i; i < actions.length; ++i) {
            Action memory action = actions[i];
            bytes32 actionId = _generateActionId(action.target, action.caller, action.fnSelector);
            s_isWhitelisted[actionId] = action.isWhitelisted;

            if (action.isWithdraw && action.isWhitelisted) {
                s_withdrawTargets.add(action.target);
            } else if (action.isWithdraw && !action.isWhitelisted) {
                s_withdrawTargets.remove(action.target);
            }

            emit WhitelistedActionChanged(action.target, action.caller, action.fnSelector, action.isWhitelisted);
        }
    }

    /// @notice Executes a set of actions as the liquidity warehouse
    /// @param executeActions The set of actions to execute
    /// @param isOwner True if the caller is the liquidity warehouse's owner
    function _execute(ExecuteAction[] calldata executeActions, bool isOwner) internal {
        for (uint256 i; i < executeActions.length; ++i) {
            ExecuteAction memory executeAction = executeActions[i];
            bytes4 fnSelector = bytes4(executeAction.data);
            bytes32 actionId = _generateActionId(executeAction.target, msg.sender, fnSelector);
            if (!isOwner && !s_isWhitelisted[actionId]) {
                revert AccessToCallForbidden(executeAction.target, msg.sender, fnSelector);
            }
            (bool success,) = executeAction.target.call{value: executeAction.value}(executeAction.data);
            if (!success) revert ExecutionFailed(executeAction.target, msg.sender, fnSelector);
        }
    }

    /// @notice Returns true if an action is callable by a caller at a target
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bool True if the caller is able to call the function at the target
    function _isWhitelisted(address target, address caller, bytes4 fnSelector) internal view returns (bool) {
        return s_isWhitelisted[_generateActionId(target, caller, fnSelector)];
    }

    /// @notice Generates an action ID for an action given it's parameters
    /// @param target The target being called
    /// @param caller The caller calling the action on the target
    /// @param fnSelector The action's function selector
    /// @return bytes32 The keccak256 hash of the action's parameters
    function _generateActionId(address target, address caller, bytes4 fnSelector) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, caller, fnSelector));
    }

    /// @notice Returns the list of target addresses that are withdrawable
    /// @return address[] The list of withdrawable targets
    function _getWithdrawableTargets() internal view returns (address[] memory) {
        return s_withdrawTargets.values();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IEmergencyPausable {
    /// @notice Pauses the contract
    function emergencyPause() external;

    /// @notice Unpauses the contract
    function emergencyUnpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ICopraRegistry {
    /// @notice This event is emitted when a new address is registered as a
    /// liquidity warehouse
    event LiquidityWarehouseAdded(address indexed liquidityWarehouse);

    /// @notice This event is emitted when an address is removed from the list
    /// of registered liquidity warehouses
    event LiquidityWarehouseRemoved(address indexed liquidityWarehouse);

    /// @notice This error is thrown when trying to add the zero address as a
    /// registered liquidity warehouse or trying to remove the zero address
    /// from the liquidity warehouse
    error InvalidLiquidityWarehouse();

    /// @notice Adds a list of liquidity warehouses to the copra registry
    /// @param liquidityWarehouses The list of liquidity warehouses to add
    function addLiquidityWarehouses(address[] calldata liquidityWarehouses) external;

    /// @notice Removes a list of liquidity warehouses from the copra registry
    /// @param liquidityWarehouses The list of liquidity warehouses to remove
    function removeLiquidityWarehouses(address[] calldata liquidityWarehouses) external;

    /// @notice Returns the list of registered liquidity warehouses
    /// @return address[] The list of registered liquidity warehouses
    function getLiquidityWarehouses() external view returns (address[] memory);

    /// @notice Returns whether or not an address is a registered liquidity
    /// warehouse
    /// @param liquidityWarehouse The liquidity warehouse to check registration
    /// @return bool True if the address is a registered liquidity warehouse
    function isRegisteredLiquidityWarehouse(address liquidityWarehouse) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function _preventExecution() internal view {
    // solhint-disable-next-line avoid-tx-origin
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    _preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}