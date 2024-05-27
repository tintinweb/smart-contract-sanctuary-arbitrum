// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { GoldLinkOwnable } from "../utils/GoldLinkOwnable.sol";
import { Errors } from "../libraries/Errors.sol";
import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import {
    IStrategyAccountDeployer
} from "../interfaces/IStrategyAccountDeployer.sol";
import { IStrategyController } from "../interfaces/IStrategyController.sol";
import { IStrategyReserve } from "../interfaces/IStrategyReserve.sol";
import { StrategyReserve } from "../core/StrategyReserve.sol";

/**
 * @title StrategyController
 * @author GoldLink
 *
 * @notice Contract that manages essential strategy-wide functions, including global strategy reentrancy and pausing.
 */
contract StrategyController is GoldLinkOwnable, Pausable, IStrategyController {
    // ============ Constants ============

    /// @notice The `IERC20` asset associated with lending and borrowing in the strategy.
    IERC20 public immutable STRATEGY_ASSET;

    /// @notice The `StrategyBank` associated with this strategy.
    IStrategyBank public immutable STRATEGY_BANK;

    /// @notice The `StrategyReserve` associated with this strategy.
    IStrategyReserve public immutable STRATEGY_RESERVE;

    /// @notice The `StrategyAccountDeployer` associated with this strategy.
    IStrategyAccountDeployer public immutable STRATEGY_ACCOUNT_DEPLOYER;

    /// @dev The lock states.
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    // Taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/3def8f9d15871160a146353b975ad7adf4c2bf67/contracts/utils/ReentrancyGuard.sol
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    // ============ Storage Variables ============

    /// @dev Whether the status of the strategy is locked from reentrancy.
    uint256 private reentrancyStatus_;

    // ============ Modifiers ============

    /// @dev Modifier to allow only the strategy core contracts to call the function.
    modifier onlyStrategyCore() {
        require(
            msg.sender == address(STRATEGY_BANK) ||
                msg.sender == address(STRATEGY_RESERVE),
            Errors.STRATEGY_CONTROLLER_CALLER_IS_NOT_STRATEGY_CORE
        );
        _;
    }

    // ============ Constructor ============

    constructor(
        address strategyOwner,
        IERC20 strategyAsset,
        IStrategyReserve.ReserveParameters memory reserveParameters,
        IStrategyBank.BankParameters memory bankParameters
    ) Ownable(strategyOwner) {
        STRATEGY_ASSET = strategyAsset;

        // Create the strategy reserve. The reserve will create the bank.
        STRATEGY_RESERVE = new StrategyReserve(
            strategyOwner,
            strategyAsset,
            this,
            reserveParameters,
            bankParameters
        );
        STRATEGY_BANK = STRATEGY_RESERVE.STRATEGY_BANK();

        STRATEGY_ACCOUNT_DEPLOYER = bankParameters.strategyAccountDeployer;

        // Set initial reentrancy status to not entered.
        reentrancyStatus_ = NOT_ENTERED;
    }

    // ============ External Functions ============

    /**
     * @notice Pause the strategy, preventing it's contracts from taking any new actions.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the strategy.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Acquire a strategy wide lock, preventing reentrancy across the entire strategy.
     * @dev IMPORTANT: The acquire and release functions are intended to be used as part of a
     * modifier to guarantee that the release function is always called at the end of a transaction
     * in which acquire has been called. This ensures that the value of `reentrancyStatus_` must be
     * `NOT_ENTERED` in between transactions.
     */
    function acquireStrategyLock() external override onlyStrategyCore {
        require(
            reentrancyStatus_ == NOT_ENTERED,
            Errors.STRATEGY_CONTROLLER_LOCK_ALREADY_ACQUIRED
        );
        reentrancyStatus_ = ENTERED;
    }

    /**
     * @notice Release a strategy lock.
     * @dev IMPORTANT: The acquire and release functions are intended to be used as part of a
     * modifier to guarantee that the release function is always called at the end of a transaction
     * in which acquire has been called. This ensures that the value of `reentrancyStatus_` must be
     * `NOT_ENTERED` in between transactions.
     */
    function releaseStrategyLock() external override onlyStrategyCore {
        require(
            reentrancyStatus_ == ENTERED,
            Errors.STRATEGY_CONTROLLER_LOCK_NOT_ACQUIRED
        );
        reentrancyStatus_ = NOT_ENTERED;
    }

    /**
     * @notice Return whether or not the strategy is paused.
     */
    function isPaused() external view override returns (bool) {
        return paused();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
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
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { Errors } from "../libraries/Errors.sol";

/**
 * @title GoldLinkOwnable
 * @author GoldLink
 *
 * @dev Ownable contract that requires new owner to accept, and disallows renouncing ownership.
 */
abstract contract GoldLinkOwnable is Ownable2Step {
    // ============ Public Functions ============

    function renounceOwnership() public view override onlyOwner {
        revert(Errors.CANNOT_RENOUNCE_OWNERSHIP);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Errors
 * @author GoldLink
 *
 * @dev The core GoldLink Protocol errors library.
 */
library Errors {
    //
    // COMMON
    //
    string internal constant ADDRESS_CANNOT_BE_RESET =
        "Address cannot be reset.";
    string internal constant CALLER_MUST_BE_VALID_STRATEGY_BANK =
        "Caller must be valid strategy bank.";
    string internal constant CANNOT_CALL_FUNCTION_WHEN_PAUSED =
        "Cannot call function when paused.";
    string internal constant ZERO_ADDRESS_IS_NOT_ALLOWED =
        "Zero address is not allowed.";
    string internal constant ZERO_AMOUNT_IS_NOT_VALID =
        "Zero amount is not valid.";

    //
    // UTILS
    //
    string internal constant CANNOT_RENOUNCE_OWNERSHIP =
        "GoldLinkOwnable: Cannot renounce ownership";

    //
    // STRATEGY ACCOUNT
    //
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_IS_NOT_LIQUIDATABLE =
        "StrategyAccount: Account is not liquidatable.";
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_HAS_AN_ACTIVE_LOAN =
        "StrategyAccount: Account has an active loan.";
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_HAS_NO_LOAN =
        "StrategyAccount: Account has no loan.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_CALL_WHILE_LIQUIDATION_ACTIVE =
        "StrategyAccount: Cannot call while liquidation active.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_CALL_WHILE_LIQUIDATION_INACTIVE =
        "StrategyAccount: Cannot call while liquidation inactive.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_PROCESS_LIQUIDATION_WHEN_NOT_COMPLETE =
        "StrategyAccount: Cannot process liquidation when not complete.";
    string internal constant STRATEGY_ACCOUNT_PARAMETERS_LENGTH_MISMATCH =
        "StrategyAccount: Parameters length mismatch.";
    string internal constant STRATEGY_ACCOUNT_SENDER_IS_NOT_OWNER =
        "StrategyAccount: Sender is not owner.";

    //
    // STRATEGY BANK
    //
    string
        internal constant STRATEGY_BANK_CALLER_IS_NOT_VALID_STRATEGY_ACCOUNT =
        "StrategyBank: Caller is not valid strategy account.";
    string internal constant STRATEGY_BANK_CALLER_MUST_BE_STRATEGY_RESERVE =
        "StrategyBank: Caller must be strategy reserve.";
    string
        internal constant STRATEGY_BANK_CANNOT_DECREASE_COLLATERAL_BELOW_ZERO =
        "StrategyBank: Cannot decrease collateral below zero.";
    string internal constant STRATEGY_BANK_CANNOT_REPAY_LOAN_WHEN_LIQUIDATABLE =
        "StrategyBank: Cannot repay loan when liquidatable.";
    string
        internal constant STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_IS_IN_STRATEGY_ACCOUNT =
        "StrategyBank: Cannot repay more than is in strategy account.";
    string internal constant STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_TOTAL_LOAN =
        "StrategyBank: Cannot repay more than total loan.";
    string
        internal constant STRATEGY_BANK_COLLATERAL_WOULD_BE_LESS_THAN_MINIMUM =
        "StrategyBank: Collateral would be less than minimum.";
    string
        internal constant STRATEGY_BANK_EXECUTOR_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Executor premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_HEALTH_SCORE_WOULD_FALL_BELOW_MINIMUM_OPEN_HEALTH_SCORE =
        "StrategyBank: Health score would fall below minimum open health score.";
    string
        internal constant STRATEGY_BANK_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Insurance premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_GREATER_THAN_ZERO =
        "StrategyBank: Liquidatable health score must be greater than zero.";
    string
        internal constant STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Liquidatable health score must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_LIQUIDATION_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Liquidation insurance premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_MINIMUM_OPEN_HEALTH_SCORE_CANNOT_BE_AT_OR_BELOW_LIQUIDATABLE_HEALTH_SCORE =
        "StrategyBank: Minimum open health score cannot be at or below liquidatable health score.";
    string
        internal constant STRATEGY_BANK_REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE_COLLATERAL =
        "StrategyBank: Requested withdrawal amount exceeds available collateral.";

    //
    // STRATEGY RESERVE
    //
    string internal constant STRATEGY_RESERVE_CALLER_MUST_BE_THE_STRATEGY_BANK =
        "StrategyReserve: Caller must be the strategy bank.";
    string internal constant STRATEGY_RESERVE_INSUFFICIENT_AVAILABLE_TO_BORROW =
        "StrategyReserve: Insufficient available to borrow.";
    string
        internal constant STRATEGY_RESERVE_OPTIMAL_UTILIZATION_MUST_BE_LESS_THAN_OR_EQUAL_TO_ONE_HUNDRED_PERCENT =
        "StrategyReserve: Optimal utilization must be less than or equal to one hundred percent.";
    string
        internal constant STRATEGY_RESERVE_STRATEGY_ASSET_DOES_NOT_HAVE_ASSET_DECIMALS_SET =
        "StrategyReserve: Strategy asset does not have asset decimals set.";

    //
    // STRATEGY CONTROLLER
    //
    string internal constant STRATEGY_CONTROLLER_CALLER_IS_NOT_STRATEGY_CORE =
        "StrategyController: Caller is not strategy core.";
    string internal constant STRATEGY_CONTROLLER_LOCK_ALREADY_ACQUIRED =
        "StrategyController: Lock already acquired.";
    string internal constant STRATEGY_CONTROLLER_LOCK_NOT_ACQUIRED =
        "StrategyController: Lock not acquired.";
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ERC20,
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC4626
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { GoldLinkOwnable } from "../utils/GoldLinkOwnable.sol";
import { InterestRateModel } from "./InterestRateModel.sol";
import { StrategyBank } from "./StrategyBank.sol";
import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import { IStrategyReserve } from "../interfaces/IStrategyReserve.sol";
import { Errors } from "../libraries/Errors.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Constants } from "../libraries/Constants.sol";
import { ControllerHelpers } from "./ControllerHelpers.sol";
import { IStrategyController } from "../interfaces/IStrategyController.sol";

/**
 * @title StrategyReserve
 * @author GoldLink
 *
 * @notice Manages all lender actions and state for a single strategy.
 */
contract StrategyReserve is
    IStrategyReserve,
    GoldLinkOwnable,
    ERC4626,
    InterestRateModel,
    ControllerHelpers
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Constants ============

    /// @notice The strategy bank permissioned to borrow from the reserve.
    IStrategyBank public immutable STRATEGY_BANK;

    /// @notice The asset used for lending in this strategy.
    IERC20 public immutable STRATEGY_ASSET;

    // ============ Storage Variables ============

    /// @notice The net balance of borrowed assets, utilized in active loans.
    uint256 public utilizedAssets_;

    /// @notice The maximum TVL (total value locked), limiting the total net
    /// funds deposited in the reserve.
    ///
    /// Is is possible for the ERC-20 balance or reserveBalance_ to exceed this
    /// in some cases, such as due to received interest. In this case, borrows
    /// will still be limited to prevent utilizedAssets_ exceeding tvlCap_.
    uint256 public tvlCap_;

    /// @notice The asset balance of the contract. Extraneous ERC-20 transfers
    /// not made through function calls on the reserve are excluded and ignored.
    uint256 public reserveBalance_;

    // ============ Modifiers ============

    /// @dev Require address is not zero.
    modifier onlyNonZeroAddress(address addressToCheck) {
        require(
            addressToCheck != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        _;
    }

    /// @dev Only callable by the strategy bank.
    modifier onlyStrategyBank() {
        require(
            msg.sender == address(STRATEGY_BANK),
            Errors.STRATEGY_RESERVE_CALLER_MUST_BE_THE_STRATEGY_BANK
        );
        _;
    }

    /// @dev Sync balance and accrue interest before executing a function.
    ///
    /// The interest rate is a function of utilization, so the cumulative
    /// interest must be settled before any transaction that affects
    /// utilization.
    modifier syncAndAccrue() {
        // Get the used and total asset amounts.
        uint256 used = utilizedAssets_;
        uint256 total = used + reserveBalance_; // equal to totalAssets()

        // Settle interest that has accrued since the last settlement,
        // and get the new amount owed on the utilized asset balance.
        uint256 interestOwed = _accrueInterest(used, total);

        // Take interest from `StrategyBank`.
        //
        // Note that in rare cases it is possible for the bank to underpay,
        // if it has insufficient collateral available to satisfy the payment.
        // In this case, the reserve will simply receive less interest than
        // expected.
        uint256 interestToPay = STRATEGY_BANK.getInterestAndTakeInsurance(
            interestOwed
        );

        // Update reserve balance with interest to be paid.
        reserveBalance_ += interestToPay;

        // Transfer interest from the strategy bank. We use the amount
        // returned by getInterestAndTakeInsurance() which is guaranteed to
        // be less than or equal to the bank's ERC-20 asset balance.
        if (interestToPay > 0) {
            STRATEGY_ASSET.safeTransferFrom(
                address(STRATEGY_BANK),
                address(this),
                interestToPay
            );
        }

        // Run the function.
        _;
    }

    // ============ Constructor ============

    constructor(
        address strategyOwner,
        IERC20 strategyAsset,
        IStrategyController strategyController,
        IStrategyReserve.ReserveParameters memory reserveParameters,
        IStrategyBank.BankParameters memory bankParameters
    )
        Ownable(strategyOwner)
        onlyNonZeroAddress(address(strategyAsset))
        ERC20(reserveParameters.erc20Name, reserveParameters.erc20Symbol)
        ERC4626(strategyAsset)
        ControllerHelpers(strategyController)
        InterestRateModel(reserveParameters.interestRateModel)
    {
        // Verify `strategyAsset` has decimals.
        require(
            _checkHasDecimals(strategyAsset),
            Errors
                .STRATEGY_RESERVE_STRATEGY_ASSET_DOES_NOT_HAVE_ASSET_DECIMALS_SET
        );

        STRATEGY_ASSET = strategyAsset;

        // Create the strategy bank.
        STRATEGY_BANK = new StrategyBank(
            strategyOwner,
            strategyAsset,
            strategyController,
            this,
            bankParameters
        );

        // Set TVL cap for this reserve.
        tvlCap_ = reserveParameters.totalValueLockedCap;
    }

    // ============ External Functions ============

    /**
     * @notice Updates the total value locked cap for `reserveId`.
     * @dev Emits the `TotalValueLockedCapUpdated()` event.
     * @param newTotalValueLockedCap The new TVL cap to enforce. Will not effect preexisting positions.
     */
    function updateReserveTVLCap(
        uint256 newTotalValueLockedCap
    ) external override onlyOwner {
        // Set new TVL cap.
        tvlCap_ = newTotalValueLockedCap;

        emit TotalValueLockedCapUpdated(newTotalValueLockedCap);
    }

    /**
     * @notice Update the model for the interest rate.
     * @dev Syncs interest model, updating interest owed and then sets the new model. Therefore,
     * no borrower is penalized retroactively for a new interest rate model.
     * @param model The new model for the interest rate.
     */
    function updateModel(
        InterestRateModelParameters calldata model
    ) external onlyOwner syncAndAccrue {
        _updateModel(model);
    }

    /**
     * @notice Borrow assets from the reserve pool.
     * Only callable by the strategy bank.
     * @dev Emits the `BorrowAssets()` event.
     * @param borrower     The account borrowing funds from this reserve.
     * @param borrowAmount The amount of assets that have been borrowed and are
     * now utilized.
     */
    function borrowAssets(
        address borrower,
        uint256 borrowAmount
    ) external override onlyStrategyBank syncAndAccrue {
        // Verify that the amount is available to be borrowed.
        require(
            availableToBorrow() >= borrowAmount,
            Errors.STRATEGY_RESERVE_INSUFFICIENT_AVAILABLE_TO_BORROW
        );

        // Increase utilized assets and decrease reserve balance.
        utilizedAssets_ += borrowAmount;
        reserveBalance_ -= borrowAmount;

        // Transfer borrowed assets to the borrower.
        if (borrowAmount > 0) {
            STRATEGY_ASSET.safeTransfer(borrower, borrowAmount);
        }

        emit BorrowAssets(borrowAmount);
    }

    /**
     * @notice Deduct `initialLoan` from the utilized balance while receiving
     * asset amount `returnedLoan` from the strategy bank. If the returned
     * amount is less, the difference represents a loss in the borrower's
     * position that will not be repaid and will be assumed by the lenders.
     * @dev Emits the `Repay()` event.
     * @param initialLoan  Assets previously borrowed that are no longer utilized.
     * @param returnedLoan Loan assets that are being returned, net of loan loss.
     */
    function repay(
        uint256 initialLoan,
        uint256 returnedLoan
    ) external onlyStrategyBank syncAndAccrue {
        // Reduce utilized assets by assets no longer borrowed and increase
        // reserve balance by the amount being returned, net of loan loss.
        utilizedAssets_ -= initialLoan;
        reserveBalance_ += returnedLoan;

        // Effectuate the transfer of the returned amount.
        if (returnedLoan > 0) {
            STRATEGY_ASSET.safeTransferFrom(
                address(STRATEGY_BANK),
                address(this),
                returnedLoan
            );
        }

        emit Repay(initialLoan, returnedLoan);
    }

    /**
     * @notice Settle global lender interest and calculate new interest owed
     * by a borrower, given their previous loan amount and cached index.
     * @param loanBefore        The loan's value before any state updates have been made.
     * @param interestIndexLast The last interest index corresponding to the borrower's loan.
     * @return interestOwed     The interest owed since the last time the borrow updated their position.
     * @return interestIndexNow The current interest index corresponding to the borrower's loan.
     */
    function settleInterest(
        uint256 loanBefore,
        uint256 interestIndexLast
    )
        external
        override
        onlyStrategyBank
        syncAndAccrue
        returns (uint256 interestOwed, uint256 interestIndexNow)
    {
        // Get the current interest index.
        interestIndexNow = cumulativeInterestIndex();

        // Calculate the interest owed since the last time the borrower's
        // interest was settled.
        interestOwed = _calculateInterestOwed(
            loanBefore,
            interestIndexLast,
            interestIndexNow
        );

        return (interestOwed, interestIndexNow);
    }

    /**
     * @notice Calculate new interest owed by a borrower, given their previous
     * loan amount and cached index. Does not modify state.
     * @param loanBefore        The loan's value before any state updates have been made.
     * @param interestIndexLast The last interest index corresponding to the borrower's loan.
     * @return interestOwed     The interest owed since the last time the borrow updated their position.
     * @return interestIndexNow The current interest index corresponding to the borrower's loan.
     */
    function settleInterestView(
        uint256 loanBefore,
        uint256 interestIndexLast
    ) external view returns (uint256 interestOwed, uint256 interestIndexNow) {
        // Calculate the updated cumulative interest index (without updating storage).
        interestIndexNow = _getNextCumulativeInterestIndex(
            utilizedAssets_,
            totalAssets()
        );

        // Calculate the interest owed since the last time the borrower's
        // interest was settled.
        interestOwed = _calculateInterestOwed(
            loanBefore,
            interestIndexLast,
            interestIndexNow
        );

        return (interestOwed, interestIndexNow);
    }

    // ============ Public Functions ============

    /**
     * @notice Implements deposit, adding funds to the reserve and receiving LP tokens in return.
     * @dev Emits the `Deposit()` event via `_deposit`.
     * @param assets   The assets deposited into the reserve to be lent out to borrowers.
     * @param receiver The address receiving shares.
     * @return shares  The shares minted for the assets deposited.
     */
    function deposit(
        uint256 assets,
        address receiver
    )
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        strategyNonReentrant
        syncAndAccrue
        returns (uint256 shares)
    {
        shares = super.deposit(assets, receiver);
        reserveBalance_ += assets;

        return shares;
    }

    /**
     * @notice Implements mint, adding funds to the reserve and receiving LP tokens in return.
     * Unlike `deposit`, specifies target shares to mint rather than assets deposited.
     * @dev Emits the `Deposit()` event via `_deposit`.
     * @param shares   The shares to mint.
     * @param receiver The address receiving shares.
     * @return assets  The assets deposited into the reserve to be lent out to borrowers.
     */
    function mint(
        uint256 shares,
        address receiver
    )
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        strategyNonReentrant
        syncAndAccrue
        returns (uint256 assets)
    {
        assets = super.mint(shares, receiver);
        reserveBalance_ += assets;

        return assets;
    }

    /**
     * @notice Implements withdraw, removing assets from the reserve and burning shares worth
     * assets value.
     * @dev Emits the `Withdraw()` event via `_withdraw`.
     * @param assets   The assets being withdrawn.
     * @param receiver The address receiving withdrawn assets.
     * @param lender   The owner of the shares that will be burned. If the caller is not
     * the owner, must have a spend allowance.
     * @return shares  The shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address lender
    )
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        strategyNonReentrant
        syncAndAccrue
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, receiver, lender);
        reserveBalance_ -= assets;

        return shares;
    }

    /**
     * @notice Implements redeem, burning shares and receiving assets worth share value.
     * @dev Emits the `Withdraw()` event via `_withdraw`.
     * @param shares   The shares being burned.
     * @param receiver The address receiving withdrawn assets.
     * @param lender   The owner of the shares that will be burned. If the caller is not
     * the owner, must have a spend allowance.
     * @return assets  The assets received worth the shares burned.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address lender
    )
        public
        override(ERC4626, IERC4626)
        whenNotPaused
        strategyNonReentrant
        syncAndAccrue
        returns (uint256 assets)
    {
        assets = super.redeem(shares, receiver, lender);
        reserveBalance_ -= assets;

        return assets;
    }

    /**
     * @notice Implements total assets, the balance of assets in the reserve and utilized by
     * the strategy bank.
     * @return reserveTotalAssets The total assets belonging to the reserve.
     */
    function totalAssets()
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256 reserveTotalAssets)
    {
        return reserveBalance_ + utilizedAssets_;
    }

    /**
     * @notice Implements max deposit, the maximum deposit viable given remaining TVL capacity.
     * @return allowedDeposit The maximum allowed deposit.
     */
    function maxDeposit(
        address
    ) public view override(ERC4626, IERC4626) returns (uint256 allowedDeposit) {
        if (isStrategyPaused()) {
            return 0;
        }
        return _remainingAssetCapacity();
    }

    /**
     * @notice Implements max mint, the maximum mint viable given remaining TVL capacity.
     * @return allowedMint The maximum allowed mint.
     */
    function maxMint(
        address
    ) public view override(ERC4626, IERC4626) returns (uint256 allowedMint) {
        if (isStrategyPaused()) {
            return 0;
        }
        return _convertToShares(_remainingAssetCapacity(), Math.Rounding.Floor);
    }

    /**
     * @notice Implements max withdraw, the maximum assets withdrawable from the reserve.
     * @param lender          The owner of the balance being withdrawn.
     * @return viableWithdraw The maximum viable withdawal.
     */
    function maxWithdraw(
        address lender
    ) public view override(ERC4626, IERC4626) returns (uint256 viableWithdraw) {
        if (isStrategyPaused()) {
            return 0;
        }

        // The lender's assets.
        uint256 ownerAssets = _convertToAssets(
            balanceOf(lender),
            Math.Rounding.Floor
        );

        // Get the available assets in the reserve to withdraw.
        uint256 contractAssetBalance = reserveBalance_;

        // Return the minimum of the owner's assets and the available withdrawable
        // assets in the reserve.
        return Math.min(ownerAssets, contractAssetBalance);
    }

    /**
     * @notice Implements max redeem, the maximum shares redeemable from the reserve.
     * @param lender            The owner of the balance being withdrawn.
     * @return viableRedemption The maximum viable redemption.
     */
    function maxRedeem(
        address lender
    )
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256 viableRedemption)
    {
        if (isStrategyPaused()) {
            return 0;
        }

        // Get share value of all withdrawable assets in the reserve.
        uint256 availableToRedeem = _convertToShares(
            reserveBalance_,
            Math.Rounding.Floor
        );

        // Get lender's shares.
        uint256 ownerShares = balanceOf(lender);

        // Return the minimum of the owner's shares and the available redeemable
        // shares in the reserve.
        return Math.min(ownerShares, availableToRedeem);
    }

    /**
     * @notice The amount of assets currently available to borrow.
     * @return assets The amount of assets currently available to borrow.
     */
    function availableToBorrow() public view override returns (uint256 assets) {
        uint256 availableBalance = reserveBalance_;
        uint256 borrowedBalance = utilizedAssets_;

        // Disallow borrows that would result in the utilized balance
        // exceeding the TVL cap.
        uint256 borrowableUpToCap = tvlCap_ > borrowedBalance
            ? tvlCap_ - borrowedBalance
            : 0;
        return Math.min(availableBalance, borrowableUpToCap);
    }

    // ============ Internal Functions ============

    /**
     * @notice Implements remaining asset capacity, fetching the remaining
     * capacity in the reserve given the TVL cap.
     * @return remainingAssets Amount of assets that can still be deposited.
     */
    function _remainingAssetCapacity()
        internal
        view
        returns (uint256 remainingAssets)
    {
        // Get the total assets available in the reserve or utilized by the strategy bank.
        uint256 loanAssets = totalAssets();

        // Get the TVL cap for the strategy.
        uint256 tvlCap = tvlCap_;

        // Return assets that can still be enrolled in the strategy.
        return tvlCap > loanAssets ? tvlCap - loanAssets : 0;
    }

    // ============ Private Functions ============

    /**
     * @notice Checks if `asset` has decimals. Necessary for this `StrategyReserve` to fetch
     * vault asset decimals.
     * @param asset    The asset being checked for decimals.
     * @return success If the asset has decimals.
     */
    function _checkHasDecimals(
        IERC20 asset
    ) private view returns (bool success) {
        (success, ) = address(asset).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
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
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "../ERC20.sol";
import {SafeERC20} from "../utils/SafeERC20.sol";
import {IERC4626} from "../../../interfaces/IERC4626.sol";
import {Math} from "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * [CAUTION]
 * ====
 * In empty (or nearly empty) ERC-4626 vaults, deposits are at high risk of being stolen through frontrunning
 * with a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well as unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * Since v4.9, this implementation uses virtual assets and shares to mitigate that risk. The `_decimalsOffset()`
 * corresponds to an offset in the decimal representation between the underlying asset's decimals and the vault
 * decimals. This offset also determines the rate of virtual shares to virtual assets in the vault, which itself
 * determines the initial exchange rate. While not fully preventing the attack, analysis shows that the default offset
 * (0) makes it non-profitable, as a result of the value being captured by the virtual shares (out of the attacker's
 * donation) matching the attacker's expected gains. With a larger offset, the attack becomes orders of magnitude more
 * expensive than it is profitable. More details about the underlying math can be found
 * xref:erc4626.adoc#inflation-attack[here].
 *
 * The drawback of this approach is that the virtual shares do capture (a very small) part of the value being accrued
 * to the vault. Also, if the vault experiences losses, the users try to exit the vault, the virtual shares and assets
 * will cause the first user to exit to experience reduced losses in detriment to the last users that will experience
 * bigger losses. Developers willing to revert back to the pre-v4.9 behavior just need to override the
 * `_convertToShares` and `_convertToAssets` functions.
 *
 * To learn more, check out our xref:ROOT:erc4626.adoc[ERC-4626 guide].
 * ====
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _underlyingDecimals;

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _decimalsOffset() internal view virtual returns (uint8) {
        return 0;
    }
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

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Constants } from "../libraries/Constants.sol";
import { PercentMath } from "../libraries/PercentMath.sol";
import { IInterestRateModel } from "../interfaces/IInterestRateModel.sol";
import { Errors } from "../libraries/Errors.sol";

/**
 * @title InterestRateModel
 * @author GoldLink
 *
 * @dev Interest Rate Model is responsible for calculating and storing borrower's APR and accrued
 * interest. Utilizes a kinked rate slope model for calculating interest rates.
 */
abstract contract InterestRateModel is IInterestRateModel {
    using Math for uint256;
    using PercentMath for uint256;

    // ============ Storage Variables ============

    /// @notice The model, made up of all of the interest rate parameters.
    InterestRateModelParameters public model_;

    /// @dev The cumulative interest index for the interest rate model.
    uint256 private cumulativeInterestIndex_;

    /// @dev The timestamp of last update.
    uint256 private lastUpdateTimestamp_;

    // ============ Constructor ============

    constructor(InterestRateModelParameters memory model) {
        // Set the model for the interest rate.
        _updateModel(model);
    }

    // ============ Public Functions ============
    /**
     * @notice Implements cumulative interest index, returning the cumulative
     * interest index
     * @return currentCumulativeInterestIndex The current cumulative interest
     * index value.
     */
    function cumulativeInterestIndex()
        public
        view
        returns (uint256 currentCumulativeInterestIndex)
    {
        return cumulativeInterestIndex_;
    }

    // ============ Internal Functions ============

    /**
     * @notice Update the model for the interest rate.
     * @dev Emits the `ModelUpdated()` event.
     * @param model The new model for the interest rate.
     */
    function _updateModel(InterestRateModelParameters memory model) internal {
        require(
            model.optimalUtilization <= Constants.ONE_HUNDRED_PERCENT,
            Errors
                .STRATEGY_RESERVE_OPTIMAL_UTILIZATION_MUST_BE_LESS_THAN_OR_EQUAL_TO_ONE_HUNDRED_PERCENT
        );

        model_ = model;

        emit ModelUpdated(
            model.optimalUtilization,
            model.baseInterestRate,
            model.rateSlope1,
            model.rateSlope2
        );
    }

    /**
     * @notice Settle the value of the cumulative interest index by accuring
     *  interest that has accumulated over the time period since the index was
     *  last settled.
     * @dev Emits the `InterestSettled()` event.
     * @param used          The amount of assets being used.
     * @param total         The total amount of assets, from used and available amounts.
     * @return interestOwed The interest owed since last update.
     */
    function _accrueInterest(
        uint256 used,
        uint256 total
    ) internal returns (uint256 interestOwed) {
        // Get seconds elapsed since last update.
        uint256 secondsElapsed = block.timestamp - lastUpdateTimestamp_;

        // Exit early if no time passed.
        if (secondsElapsed == 0) {
            return 0;
        }

        uint256 cumulativeIndexNext = _getNextCumulativeInterestIndex(
            used,
            total
        );

        // Get interest owed for the used amount given the change in cumulative interest index.
        interestOwed = _calculateInterestOwed(
            used,
            cumulativeInterestIndex_,
            cumulativeIndexNext
        );

        // Store the update index and timestamp.
        cumulativeInterestIndex_ = cumulativeIndexNext;
        lastUpdateTimestamp_ = block.timestamp;

        emit InterestSettled(block.timestamp, cumulativeIndexNext);

        return interestOwed;
    }

    /**
     * @notice Calculate the next cumulative interest index without writing to the state.
     * @param used               The amount of assets being used.
     * @param total              The total amount of assets in the pool.
     * @return interestIndexNext The next interest index.
     */
    function _getNextCumulativeInterestIndex(
        uint256 used,
        uint256 total
    ) internal view returns (uint256 interestIndexNext) {
        // Get seconds elapsed since last update.
        uint256 secondsElapsed = block.timestamp - lastUpdateTimestamp_;

        // Return if not time passed or no assets were used.
        if (used == 0 || secondsElapsed == 0) {
            return cumulativeInterestIndex_;
        }

        // Get the interest rate as an APR, according to utilization.
        uint256 apr = _getInterestRate(used, total);

        // Get the accrued interest rate for the time period by applying
        // the APR as a simple (non-compounding) interest rate.
        uint256 accruedInterestRateForPeriod = apr.mulDiv(
            secondsElapsed,
            Constants.SECONDS_PER_YEAR,
            Math.Rounding.Floor
        );

        // Calculate the new index, representing cumulative accrued interest.
        return cumulativeInterestIndex_ + accruedInterestRateForPeriod;
    }

    /**
     * @notice Calculate the interest owed given the borrow amount, the last interest index and the current interest index.
     * @param borrowAmount      The individual amount borrowed. This is used as a basis for calculating the interest owed.
     * @param interestIndexLast The last interest index that was stored.
     * @param interestIndexNow  The current interest index.
     * @return interestOwed     The interest owed, calculated from the different of the two points on the interest curve.
     */
    function _calculateInterestOwed(
        uint256 borrowAmount,
        uint256 interestIndexLast,
        uint256 interestIndexNow
    ) internal pure returns (uint256 interestOwed) {
        // If the interest index is equal to the last interest index,
        // then the interest owed since the last update is zero.
        if (interestIndexLast == interestIndexNow) {
            return 0;
        }

        // Calculate the percentage change of the current index versus the last updated index.
        // Uses `(curveNow / curveBefore) - 100%` to derive the owed interest.
        uint256 indexDiff = interestIndexNow - interestIndexLast;

        // Calculate the interest owed by taking a percent of the borrow amount.
        return borrowAmount.percentToFractionCeil(indexDiff);
    }

    // ============ Private Functions ============

    /**
     * @notice Calculate interest rate according to the model, from used and available amounts.
     * @param used          The amount of assets being used.
     * @param total         The total amount of assets in the pool.
     * @return interestRate The calculated interest rate as a simple APR. Denominated in units of:
     * rate per 100% utilization, as WAD.
     */
    function _getInterestRate(
        uint256 used,
        uint256 total
    ) private view returns (uint256 interestRate) {
        // Read the model parameters from storage.
        InterestRateModelParameters memory model = model_;

        // Compute the percentage of available assets that are currently used.
        // Note that utilization is represented as a fraction of one WAD (representing 100%).
        uint256 utilization = used.fractionToPercent(total);

        // Split utilization into the parts above and below the optimal point.
        uint256 utilizationAboveOptimal = utilization > model.optimalUtilization
            ? utilization - model.optimalUtilization
            : 0;
        uint256 utilizationBelowOptimal = utilization - utilizationAboveOptimal;

        // Multiply each part by the corresponding slope parameter.
        uint256 rateBelowOptimal = utilizationBelowOptimal.mulDiv(
            model.rateSlope1,
            Constants.ONE_HUNDRED_PERCENT
        );
        uint256 rateAboveOptimal = utilizationAboveOptimal.mulDiv(
            model.rateSlope2,
            Constants.ONE_HUNDRED_PERCENT
        );

        // Return the sum rate from the different parts.
        return model.baseInterestRate + rateBelowOptimal + rateAboveOptimal;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Errors } from "../libraries/Errors.sol";
import { Constants } from "../libraries/Constants.sol";
import { PercentMath } from "../libraries/PercentMath.sol";
import { StrategyBankHelpers } from "../libraries/StrategyBankHelpers.sol";
import { IStrategyAccount } from "../interfaces/IStrategyAccount.sol";
import {
    IStrategyAccountDeployer
} from "../interfaces/IStrategyAccountDeployer.sol";
import { GoldLinkOwnable } from "../utils/GoldLinkOwnable.sol";
import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import { IStrategyReserve } from "../interfaces/IStrategyReserve.sol";
import { IStrategyController } from "../interfaces/IStrategyController.sol";
import { ControllerHelpers } from "./ControllerHelpers.sol";
import { StrategyController } from "../core/StrategyController.sol";

/**
 * @title StrategyBank
 * @author GoldLink
 *
 * @notice Holds strategy account collateral, manages loan accounting for
 * strategy accounts, manages liquidations, and pays interest on loan
 * balances to the strategy reserve.
 */
contract StrategyBank is IStrategyBank, GoldLinkOwnable, ControllerHelpers {
    using PercentMath for uint256;
    using SafeERC20 for IERC20;
    using StrategyBankHelpers for StrategyAccountHoldings;
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Constants ============

    /// @notice The associated reserve where funds are borrowed from.
    IStrategyReserve public immutable STRATEGY_RESERVE;

    /// @notice The asset that is lent and borrowed for use with the strategy.
    IERC20 public immutable STRATEGY_ASSET;

    /// @notice The contract that deploys borrower accounts for this strategy.
    IStrategyAccountDeployer public immutable STRATEGY_ACCOUNT_DEPLOYER;

    /// @notice The portion of interest paid as a fee to the insurance fund
    /// (denoted in WAD).
    uint256 public immutable INSURANCE_PREMIUM;

    /// @notice The additional premium taken from remaining collateral when a
    /// liquidation occurs and set aside for insurance (denoted in WAD).
    uint256 public immutable LIQUIDATION_INSURANCE_PREMIUM;

    /// @notice The percent of the liquidation premium that goes to the
    /// executor who called `processLiquidation` (denoted in WAD).
    uint256 public immutable EXECUTOR_PREMIUM;

    /// @notice The health score at which point a strategy account becomes
    /// liquidatable. Health scores are denoted in WAD.
    uint256 public immutable LIQUIDATABLE_HEALTH_SCORE;

    /// @notice The minimum collateral amount that should be held by any
    /// account with an active loan. Operations may be blocked if they would
    /// violate this constraint.
    ///
    /// Note that the collateral in an account can still drop below this value
    /// due to accrued interest or account liquidation.
    uint256 public immutable MINIMUM_COLLATERAL_BALANCE;

    // ============ Storage Variables ============

    /// @notice The total collateral deposited in this contract. Any assets in
    /// this contract beyond `totalCollateral_` are treated as part of the
    /// insurance fund.
    ///
    /// It is possible for total collateral to deviate from the sum of borrower
    /// collateral in certain cases:
    ///  - Rounding errors
    ///  - Underwater borrower accounts
    uint256 public totalCollateral_;

    /// @notice The minimum health score a strategy account can actively take
    /// on. Operations may be blocked if they would violate this constraint.
    /// Health scores are denoted in WAD.
    uint256 public minimumOpenHealthScore_;

    /// @dev Set of all strategy accounts deployed by this bank.
    EnumerableSet.AddressSet internal strategyAccountsSet_;

    /// @dev Mapping of strategy accounts to their holdings in the strategy.
    mapping(address => StrategyAccountHoldings) internal strategyAccounts_;

    // ============ Modifiers ============

    /// @dev Require caller is a recognized strategy account deployed by the bank.
    modifier onlyValidStrategyAccount() {
        require(
            strategyAccountsSet_.contains(msg.sender),
            Errors.STRATEGY_BANK_CALLER_IS_NOT_VALID_STRATEGY_ACCOUNT
        );
        _;
    }

    /// @dev Require caller is the strategy reserve associated with this bank.
    modifier onlyStrategyReserve() {
        require(
            msg.sender == address(STRATEGY_RESERVE),
            Errors.STRATEGY_BANK_CALLER_MUST_BE_STRATEGY_RESERVE
        );
        _;
    }

    // ============ Constructor ============

    constructor(
        address strategyOwner,
        IERC20 strategyAsset,
        IStrategyController strategyController,
        IStrategyReserve strategyReserve,
        BankParameters memory parameters
    ) Ownable(strategyOwner) ControllerHelpers(strategyController) {
        // Strategy Account deployer cannot be zero address.
        require(
            address(parameters.strategyAccountDeployer) != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        // Validate liquidatable health score is within valid range.
        require(
            parameters.liquidatableHealthScore > 0,
            Errors
                .STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_GREATER_THAN_ZERO
        );
        require(
            parameters.liquidatableHealthScore < Constants.ONE_HUNDRED_PERCENT,
            Errors
                .STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT
        );

        // Cannot set `minimumOpenHealthScore` at or below `liquidatableHealthScore`.
        // There is no concern with an upper bounds as the protocol may want to lock out new engagement in a strategy with
        // a very high minimum open health score.
        require(
            parameters.minimumOpenHealthScore >
                parameters.liquidatableHealthScore,
            Errors
                .STRATEGY_BANK_MINIMUM_OPEN_HEALTH_SCORE_CANNOT_BE_AT_OR_BELOW_LIQUIDATABLE_HEALTH_SCORE
        );

        // All premiums must be less than one hundred percent.
        require(
            parameters.executorPremium < Constants.ONE_HUNDRED_PERCENT,
            Errors
                .STRATEGY_BANK_EXECUTOR_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT
        );
        require(
            parameters.insurancePremium < Constants.ONE_HUNDRED_PERCENT,
            Errors
                .STRATEGY_BANK_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT
        );
        require(
            parameters.liquidationInsurancePremium <
                Constants.ONE_HUNDRED_PERCENT,
            Errors
                .STRATEGY_BANK_LIQUIDATION_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT
        );

        // Set immutable parameters.
        STRATEGY_ASSET = strategyAsset;
        STRATEGY_RESERVE = strategyReserve;
        INSURANCE_PREMIUM = parameters.insurancePremium;
        LIQUIDATION_INSURANCE_PREMIUM = parameters.liquidationInsurancePremium;
        EXECUTOR_PREMIUM = parameters.executorPremium;
        LIQUIDATABLE_HEALTH_SCORE = parameters.liquidatableHealthScore;
        MINIMUM_COLLATERAL_BALANCE = parameters.minimumCollateralBalance;
        STRATEGY_ACCOUNT_DEPLOYER = parameters.strategyAccountDeployer;

        // Set mutable parameters.
        minimumOpenHealthScore_ = parameters.minimumOpenHealthScore;

        // Set allowance for the `STRATEGY_RESERVE` to take allowed assets when repaying
        // loans.
        STRATEGY_ASSET.approve(address(STRATEGY_RESERVE), type(uint256).max);
    }

    // ============ External Functions ============

    /**
     * @notice Implements update minimum health score, modifying the minimum health
     * score a strategy account can actively take on.
     * @dev If `newMinimumOpenHealthScore = uint256.max` then the strategy has effectively
     * been paused.
     * @dev Emits the `UpdateMinimumOpenHealthScore()` event.
     * @param newMinimumOpenHealthScore The new minimum open health score.
     */
    function updateMinimumOpenHealthScore(
        uint256 newMinimumOpenHealthScore
    ) external onlyOwner {
        // Cannot set `minimumOpenHealthScore_` at or below the liquidation threshold.
        require(
            newMinimumOpenHealthScore > LIQUIDATABLE_HEALTH_SCORE,
            Errors
                .STRATEGY_BANK_MINIMUM_OPEN_HEALTH_SCORE_CANNOT_BE_AT_OR_BELOW_LIQUIDATABLE_HEALTH_SCORE
        );

        // Set new minimum open health score for this strategy bank.
        minimumOpenHealthScore_ = newMinimumOpenHealthScore;

        emit UpdateMinimumOpenHealthScore(newMinimumOpenHealthScore);
    }

    /**
     * @notice Implements acquire lock, acquiring the reentrancy lock for the strategy.
     * @dev IMPORTANT: The acquire and release functions are intended to be used as part of a
     * modifier to guarantee that the release function is always called at the end of a transaction
     * in which acquire has been called. This ensures that the value of `reentrancyStatus_` must be
     * `NOT_ENTERED` in between transactions.
     */
    function acquireLock() external onlyValidStrategyAccount {
        STRATEGY_CONTROLLER.acquireStrategyLock();
    }

    /**
     * @notice Implements release lock, releasing the reentrancy lock for the strategy.
     * @dev IMPORTANT: The acquire and release functions are intended to be used as part of a
     * modifier to guarantee that the release function is always called at the end of a transaction
     * in which acquire has been called. This ensures that the value of `reentrancyStatus_` must be
     * `NOT_ENTERED` in between transactions.
     */
    function releaseLock() external onlyValidStrategyAccount {
        STRATEGY_CONTROLLER.releaseStrategyLock();
    }

    /**
     * @notice Attempts to get interest for the reserve and take a haircut of insurance for the bank. Will potentially
     * be less than `totalRequested` if loan-loss occurred and the bank cannot send the full amount.
     * Will also attempt to withhold a haircut to grow the insurance fund.
     * @dev Insurance fund will attempt to offset lost interest in the case of insufficient collateral.
     * @dev Emits the `GetInterestAndTakeInsurance()` event.
     * @param totalRequested The interest requested by the `StrategyReserve` and insurance haircut.
     * @return interestToPay The interest to be paid to the strategy reserve after taking the insurance haircut.
     */
    function getInterestAndTakeInsurance(
        uint256 totalRequested
    ) external onlyStrategyReserve returns (uint256 interestToPay) {
        // Get bank balances.
        // The ERC-20 balance will always be at least `totalCollateral_`.
        uint256 erc20Balance = STRATEGY_ASSET.balanceOf(address(this));
        uint256 collateral = totalCollateral_;

        // Split interest into the portion for the reserve and for insurance.
        uint256 toInsurance = totalRequested.percentToFraction(
            INSURANCE_PREMIUM
        );
        uint256 toReserve = totalRequested - toInsurance;

        // Deduct from collateral first before insurance.
        // Determine the amount deducted from collateral.
        uint256 fromCollateral = Math.min(collateral, totalRequested);

        // Update total collateral in storage.
        totalCollateral_ = collateral - fromCollateral;

        // Pay the reserve, as much as is possible with collateral and insurance.
        interestToPay = Math.min(toReserve, erc20Balance);

        // Get for emit and return how much of the request was fulfilled.
        // Could potentially mean that insurance fund simply did not grow.
        uint256 interestAndInsurance = Math.min(totalRequested, erc20Balance);

        // If total requested does not equal `interestAndInsurance`, it means
        // insufficient collateral was available to pay interest due to the
        // borrow side of the protocol being underwater.
        //
        // This can only occur if at least one borrower is liquidatable due to
        // accumulated interest and not liquidated during the window of time
        // where the account's `collateral > interestOwed`.
        emit GetInterestAndTakeInsurance(
            totalRequested,
            fromCollateral,
            interestAndInsurance
        );

        return interestToPay;
    }

    /**
     * @notice Processes the completed liquidation of a strategy account.
     * Each strategy should ensure that this function is only callable once a
     * liquidation has been fully completed. The account should pass in the
     * quantity of `strategyAsset` that can be pulled from the account's
     * balance in order to repay liabilities.
     * @dev Emits the `LiquidateLoan()` event.
     * @param liquidator             The address performing the liquidation, who will receive the executor's premium
     * @param availableAccountAssets The amount of assets available to repay the account's liabilities.
     * @return executorPremium       The premium paid to the `liquidator`.
     * @return loanLoss              The loan loss passed on to lenders as a result of the liquidated account being underwater.
     */
    function processLiquidation(
        address liquidator,
        uint256 availableAccountAssets
    )
        external
        onlyValidStrategyAccount
        whenNotPaused
        returns (uint256 executorPremium, uint256 loanLoss)
    {
        address strategyAccount = msg.sender;

        // Get strategy account's holdings.
        StrategyAccountHoldings storage holdings = strategyAccounts_[
            strategyAccount
        ];

        // Update the strategy account's interest.
        _updateBorrowerInterest(holdings);

        // Process the liquidation by netting out the account's remaining
        // assets and liabilities and applying liquidation premiums.
        uint256 oldCollateral = holdings.collateral;
        uint256 updatedCollateral;
        (executorPremium, loanLoss, updatedCollateral) = _liquidate(
            strategyAccount,
            holdings,
            availableAccountAssets
        );

        // Reduce total collateral based on the change in collateral.
        // The updated collateral will always be at most the old collateral.
        totalCollateral_ -= oldCollateral - updatedCollateral;

        // Reduce collateral in holdings and clear loan and interest index.
        strategyAccounts_[strategyAccount] = StrategyAccountHoldings({
            collateral: updatedCollateral,
            loan: 0,
            interestIndexLast: 0
        });

        // Transfer executor premium to liquidator if nonzero.
        if (executorPremium > 0) {
            STRATEGY_ASSET.safeTransfer(liquidator, executorPremium);
        }

        emit LiquidateLoan(
            liquidator,
            strategyAccount,
            loanLoss,
            executorPremium
        );

        return (executorPremium, loanLoss);
    }

    /**
     * @notice Implements add collateral, adding collateral to a strategy account holdings.
     * @dev Emits the `AddCollateral()` event.
     * @param provider   The address providing the collateral.
     * @param collateral The collateral being added to the strategy account holdings.
     */
    function addCollateral(
        address provider,
        uint256 collateral
    )
        external
        onlyValidStrategyAccount
        whenNotPaused
        returns (uint256 collateralNow)
    {
        address strategyAccount = msg.sender;

        // Get old holdings.
        StrategyAccountHoldings storage holdings = strategyAccounts_[
            strategyAccount
        ];

        // If attempting to deposit zero assets, return early.
        if (collateral == 0) {
            return holdings.collateral;
        }

        // Update the strategy account's interest before doing anything else.
        _updateBorrowerInterest(holdings);

        // Calculate and validate the updated collateral balance.
        uint256 updatedCollateral = holdings.collateral + collateral;
        require(
            updatedCollateral >= MINIMUM_COLLATERAL_BALANCE,
            Errors.STRATEGY_BANK_COLLATERAL_WOULD_BE_LESS_THAN_MINIMUM
        );

        // Update account collateral.
        holdings.collateral = updatedCollateral;

        // Increase total collateral with new assets.
        totalCollateral_ += collateral;

        // Transfer collateral to strategy bank.
        STRATEGY_ASSET.safeTransferFrom(provider, address(this), collateral);

        emit AddCollateral(provider, strategyAccount, collateral);

        return updatedCollateral;
    }

    /**
     * @notice Implements borrow funds, sending funds from the `STRATEGY_RESERVE` to the `msg.sender` who is a
     * strategy account and updating utilization in the reserve associated with this strategy bank.
     * @dev Emits the `BorrowFunds()` event.
     * @param loan     The increase in the strategy account loan assets.
     * @return loanNow The total value of the account's full loan after borrowing.
     */
    function borrowFunds(
        uint256 loan
    )
        external
        onlyValidStrategyAccount
        whenNotPaused
        returns (uint256 loanNow)
    {
        address strategyAccount = msg.sender;

        // Get old holdings.
        StrategyAccountHoldings storage holdings = strategyAccounts_[
            strategyAccount
        ];

        // Update the strategy account's interest owed and interest index first.
        _updateBorrowerInterest(holdings);

        // Update the strategy account's loan amount.
        holdings.loan += loan;

        // Verify minimum health score would be respected.
        require(
            holdings.getHealthScore(
                IStrategyAccount(strategyAccount).getAccountValue() + loan
            ) >= minimumOpenHealthScore_,
            Errors
                .STRATEGY_BANK_HEALTH_SCORE_WOULD_FALL_BELOW_MINIMUM_OPEN_HEALTH_SCORE
        );

        // Borrow the loan amount from the strategy reserve.
        // Will revert if attempting to borrow beyond the available amount.
        STRATEGY_RESERVE.borrowAssets(strategyAccount, loan);

        emit BorrowFunds(strategyAccount, loan);

        return holdings.loan;
    }

    /**
     * @notice Implements repay loan, called when a strategy account repays a portion
     * of their loan. Will either address profit or loss. For profit, pay `STRATEGY_RESERVE`.
     * For loss, will take loss out of collateral before repaying. A strategy account is
     * incentivized to avoid liquidations as they will be paying a premium to liquidators.
     * @dev Will revert if the holdings are liquidatable. To avoid reverting when liquidatable,
     * add collateral before repaying.
     * @dev Emits the `RepayLoan()` event.
     * @param repayAmount  The loan assets being repaid.
     * @param accountValue The current value of the account.
     * @return loanNow     The new loan amount after repayment.
     */
    function repayLoan(
        uint256 repayAmount,
        uint256 accountValue
    ) external onlyValidStrategyAccount returns (uint256 loanNow) {
        address strategyAccount = msg.sender;

        // Get strategy account holdings.
        StrategyAccountHoldings storage holdings = strategyAccounts_[
            strategyAccount
        ];

        // Cannot reduce loan below zero.
        require(
            repayAmount <= holdings.loan,
            Errors.STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_TOTAL_LOAN
        );

        // Update the strategy account's interest.
        _updateBorrowerInterest(holdings);

        // Repayments are not allowed while a strategy account is liquidatable.
        require(
            !isAccountLiquidatable(strategyAccount, accountValue),
            Errors.STRATEGY_BANK_CANNOT_REPAY_LOAN_WHEN_LIQUIDATABLE
        );

        // Get the portion of the repayment (if any) coming from collateral.
        // If nonzero, it means that collateral is being used to offset losses
        // incurred by the strategy account.
        uint256 collateralRepayment = repayAmount -
            Math.min(repayAmount, accountValue);

        if (collateralRepayment != 0) {
            // We know there is enough collateral because otherwise the
            // account would be underwater and liquidatable.
            holdings.collateral -= collateralRepayment;
            totalCollateral_ -= collateralRepayment;
        }

        // Reduce loan in holdings by total `repayAmount` as the portion of the strategy account
        // and potentially a portion of collateral are being transferred to the strategy reserve.
        // Since the account is not liquidatable, there is no concern that the `repayAmount`
        // will not be fully paid.
        holdings.loan -= repayAmount;

        // Repay loan portion (`repayAmount`) to strategy reserve.
        _repayAssets(
            repayAmount,
            repayAmount,
            strategyAccount,
            collateralRepayment
        );

        emit RepayLoan(strategyAccount, repayAmount, collateralRepayment);

        return holdings.loan;
    }

    /**
     * @notice Implements withdraw collateral, allowing a strategy account to withdraw
     * collateral from the strategy bank.
     * @dev Emits the `WithdrawCollateral()` event.
     * @param onBehalfOf        The address receiving the collateral.
     * @param requestedWithdraw The collateral the borrower wants withdrawn from the strategy bank.
     * @param useSoftWithdrawal If withdrawing should be skipped or revert if withdrawing is not possible.
     * Verified after handling loss, if withdrawing collateral would raise health score above maximum
     * open for the strategy account.
     */
    function withdrawCollateral(
        address onBehalfOf,
        uint256 requestedWithdraw,
        bool useSoftWithdrawal
    )
        external
        onlyValidStrategyAccount
        whenNotPaused
        returns (uint256 collateralNow)
    {
        address strategyAccount = msg.sender;

        // Get strategy account's holdings.
        StrategyAccountHoldings storage holdings = strategyAccounts_[
            strategyAccount
        ];

        // If attempting to withdraw zero assets, return early.
        if (requestedWithdraw == 0) {
            return holdings.collateral;
        }

        // Cannot reduce collateral below zero.
        require(
            holdings.collateral >= requestedWithdraw,
            Errors.STRATEGY_BANK_CANNOT_DECREASE_COLLATERAL_BELOW_ZERO
        );

        // Update the strategy account's interest before doing anything else.
        _updateBorrowerInterest(holdings);

        // This calculation intentionally does not take profit into account.
        uint256 withdrawableCollateral = getWithdrawableCollateral(
            strategyAccount
        );

        // If not using soft withdrawal, revert if collateral withdrawn would be
        // less than requested.
        require(
            useSoftWithdrawal || requestedWithdraw <= withdrawableCollateral,
            Errors
                .STRATEGY_BANK_REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE_COLLATERAL
        );

        // Only withdraw up to amount that will respect health factor of the account.
        uint256 collateralToWithdraw = Math.min(
            requestedWithdraw,
            withdrawableCollateral
        );

        // Get the value of the collateral after the withdrawal would be completed.
        uint256 updatedCollateral = holdings.collateral - collateralToWithdraw;

        // If the new account collateral would be non-zero, make sure that
        // the collateral balance would remain above the minimum threshold.
        if (collateralToWithdraw != holdings.collateral) {
            require(
                updatedCollateral >= MINIMUM_COLLATERAL_BALANCE,
                Errors.STRATEGY_BANK_COLLATERAL_WOULD_BE_LESS_THAN_MINIMUM
            );
        }

        // If collateral is being withdraw, update storage and execute transfer.
        if (collateralToWithdraw > 0) {
            holdings.collateral = updatedCollateral;
            totalCollateral_ -= collateralToWithdraw;
            STRATEGY_ASSET.safeTransfer(onBehalfOf, collateralToWithdraw);
        }

        emit WithdrawCollateral(
            strategyAccount,
            onBehalfOf,
            collateralToWithdraw
        );

        return updatedCollateral;
    }

    /**
     * @notice Implements execute open account, deploying a new account for `onBehalfOf` to use the strategy.
     * @dev Emits the `OpenAccount()` event.
     * @param onBehalfOf       The address owning the new strategy account.
     * @return strategyAccount The address of the new strategy account.
     */
    function executeOpenAccount(
        address onBehalfOf
    ) external strategyNonReentrant returns (address strategyAccount) {
        // Deploy strategy account.
        strategyAccount = STRATEGY_ACCOUNT_DEPLOYER.deployAccount(
            onBehalfOf,
            STRATEGY_CONTROLLER
        );

        // Add strategy account to set of strategy accounts.
        strategyAccountsSet_.add(strategyAccount);

        emit OpenAccount(strategyAccount, onBehalfOf);

        return strategyAccount;
    }

    /**
     * @notice Implements get strategy account holdings.
     * @param strategyAccount The address of the strategy account.
     * @return holdings       The strategy account's holdings.
     */
    function getStrategyAccountHoldings(
        address strategyAccount
    ) external view returns (StrategyAccountHoldings memory holdings) {
        return strategyAccounts_[strategyAccount];
    }

    // ============ Public Functions ============

    /**
     * @notice Checks if an account is liquidatable.
     * @param strategyAccount The account being evaluated to see if it is liquidatable.
     * @param accountValue    The current value of the account positions.
     * @return isLiquidatable If the account is liquidatable.
     */
    function isAccountLiquidatable(
        address strategyAccount,
        uint256 accountValue
    ) public view returns (bool isLiquidatable) {
        // Get strategy account's holdings after paying interest.
        StrategyAccountHoldings
            memory holdings = getStrategyAccountHoldingsAfterPayingInterest(
                strategyAccount
            );

        // Return if the strategy account is liquidatable.
        return
            holdings.getHealthScore(accountValue) <= LIQUIDATABLE_HEALTH_SCORE;
    }

    /**
     * @notice Implements get withdrawable collateral, the collateral that can
     * be taken out such that `minimumOpenHealthScore_` is still respected.
     * @param strategyAccount         The address associated with the strategy account holdings.
     * @return withdrawableCollateral The amount of collateral withdrawable.
     */
    function getWithdrawableCollateral(
        address strategyAccount
    ) public view returns (uint256 withdrawableCollateral) {
        StrategyAccountHoldings memory holdings = strategyAccounts_[
            strategyAccount
        ];

        // After accounting for potential loss due to any reduction in the value of the account.
        uint256 adjustedCollateral = holdings.getAdjustedCollateral(
            IStrategyAccount(strategyAccount).getAccountValue()
        );

        // Get the minimum collateral supported by this loan and given `minimumOpenHealthScore_`.
        uint256 minimumCollateral = holdings.loan.percentToFraction(
            minimumOpenHealthScore_
        );

        // If adjusted collateral is less than minimum collateral, no collateral can be withdrawn.
        if (adjustedCollateral < minimumCollateral) {
            return 0;
        }

        // Return how much collateral can be withdrawn such that `minimumOpenHealthScore_`
        // is respected.
        return adjustedCollateral - minimumCollateral;
    }

    /**
     * @notice Get a strategy account's holdings after collateral is impacted by interest.
     * @param strategyAccount The strategy account whose holdings are being queried.
     * @return holdings       The current value of the holdings with collateral deducted by interest owed.
     */
    function getStrategyAccountHoldingsAfterPayingInterest(
        address strategyAccount
    ) public view returns (StrategyAccountHoldings memory holdings) {
        // Get strategy account's holdings.
        holdings = strategyAccounts_[strategyAccount];

        // Get interest owed and update local holdings object with impact of interest owed being accounted for.
        (uint256 interestOwed, uint256 interestIndexNow) = STRATEGY_RESERVE
            .settleInterestView(holdings.loan, holdings.interestIndexLast);
        holdings.collateral -= Math.min(holdings.collateral, interestOwed);
        holdings.interestIndexLast = interestIndexNow;

        return holdings;
    }

    /**
     * @notice Get all strategy accounts from (inclusive) index `startIndex` to index (exlusive) `stopIndex`.
     * @param startIndex The starting index of the strategy account list.
     * @param stopIndex  The ending index of the strategy account list. If `stop` is either `0` or greater than the number of accounts, will return all remaining accounts.
     * @return accounts  List of strategy accounts within the bounds of the provided `startIndex` and `stopIndex` indicies.
     */
    function getStrategyAccounts(
        uint256 startIndex,
        uint256 stopIndex
    ) external view returns (address[] memory accounts) {
        // Cap the stop index to the distance between start and stop.
        uint256 len = strategyAccountsSet_.length();
        uint256 stopIndexActual = stopIndex;
        if (stopIndex == 0 || stopIndex > len) {
            stopIndexActual = len;
        }

        accounts = new address[](stopIndexActual - startIndex);
        for (uint256 i = startIndex; i < stopIndexActual; i++) {
            accounts[i - startIndex] = strategyAccountsSet_.at(i);
        }

        return accounts;
    }

    // ============ Internal Functions ============

    /**
     * @notice Finish processing a liquidation by netting out the account's
     * remaining assets and liabilities and applying liquidation premiums.
     * @param strategyAccount    The liquidated account.
     * @param holdings           The loan position of the account.
     * @param availableAssets    The assets available in the liquidated account.
     * @return executorPremium   The premium to be paid to the liquidator.
     * @return loanLoss          The loan loss that will be incurred by lenders.
     * @return updatedCollateral The remaining collateral after processing the liquidation.
     */
    function _liquidate(
        address strategyAccount,
        StrategyAccountHoldings memory holdings,
        uint256 availableAssets
    )
        internal
        returns (
            uint256 executorPremium,
            uint256 loanLoss,
            uint256 updatedCollateral
        )
    {
        // Calculate the loan loss that will be incurred either by lenders
        // or by the insurance fund.
        //
        // Loan loss is zero if the account's total assets exceeded liabilities.
        // Otherwise, the loss is the difference between assets and liabilities.
        loanLoss =
            holdings.loan -
            Math.min(holdings.loan, availableAssets + holdings.collateral);

        // If loan loss is non-zero, it implies liquidated assets + collateral
        // have been fully consumed to pay off the borrower's liabilities.
        // Therefore, the updated collateral will be zero. Otherwise,
        // collateral should be reduced by the difference in value between the
        // strategy account assets and liabilities.
        updatedCollateral = holdings.collateral;
        updatedCollateral -= (loanLoss != 0)
            ? updatedCollateral
            : holdings.loan - Math.min(holdings.loan, availableAssets);

        // Pay premiums out of collateral.
        // This is a no-op if collateral is zero.
        (updatedCollateral, executorPremium) = _getPremiums(
            updatedCollateral,
            availableAssets
        );

        // If loan loss occurred, use available insurance to offset it.
        if (loanLoss != 0) {
            uint256 totalBalance = STRATEGY_ASSET.balanceOf(address(this));
            uint256 availableInsurance = totalBalance -
                Math.min(totalBalance, totalCollateral_);

            // Offset loan loss with the insurance fund.
            loanLoss -= Math.min(loanLoss, availableInsurance);
        }

        // Subtract the insurance-adjusted loan loss from the loan amount to
        // get the net amount that will be paid back to lenders.
        uint256 amountToRepay = holdings.loan -
            Math.min(holdings.loan, loanLoss);

        // Calculate the portion of repayment coming out of collateral.
        uint256 fromCollateral = amountToRepay -
            Math.min(amountToRepay, availableAssets);

        // Update strategy reserve to reflect loss.
        _repayAssets(
            holdings.loan,
            amountToRepay,
            strategyAccount,
            fromCollateral
        );

        return (executorPremium, loanLoss, updatedCollateral);
    }

    /**
     * @notice Settle interest for a borrower by reducing collateral by the
     * owed amount.
     * @param holdings A storage ref to the strategy accounts holdings, which will
     * be written to with updated interest.
     */
    function _updateBorrowerInterest(
        StrategyAccountHoldings storage holdings
    ) internal {
        // Settle interest associated with the account, getting the unpaid
        // accrued amount due since the last settlement.
        (uint256 interestOwed, uint256 interestIndexNext) = STRATEGY_RESERVE
            .settleInterest(holdings.loan, holdings.interestIndexLast);

        // Cannot reduce collateral below zero. If there is insufficient
        // collateral to pay interest owed, it means that the account was not
        // liquidated in time.
        uint256 collateralToReduce = Math.min(
            holdings.collateral,
            interestOwed
        );

        // Write the updated collateral and interest index to the strategy account.
        //
        // Note that the corresponding update to totalCollateral_ occurs
        // separately, in getInterestAndTakeInsurance().
        holdings.collateral -= collateralToReduce;
        holdings.interestIndexLast = interestIndexNext;
    }

    /**
     * @notice Repay a loan to the reserve by calling its repay() function.
     * The `fromCollateral` represents the amount paid out of collateral
     * (or the insurance fund) and may be zero. The rest of the funds will be
     * taken out of the strategy account before executing repayment.
     * @param initialLoan     The size of the loan being repaid.
     * @param returnedLoan    The amount of the loan that will be returned, net of loan loss.
     * @param strategyAccount The strategy account repaying the loan.
     * @param fromCollateral  The amount taken out of collateral to pay toward the loan.
     */
    function _repayAssets(
        uint256 initialLoan,
        uint256 returnedLoan,
        address strategyAccount,
        uint256 fromCollateral
    ) internal {
        if (returnedLoan > fromCollateral) {
            uint256 accountAssetBalance = returnedLoan - fromCollateral;

            require(
                STRATEGY_ASSET.balanceOf(msg.sender) >= accountAssetBalance,
                Errors
                    .STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_IS_IN_STRATEGY_ACCOUNT
            );

            STRATEGY_ASSET.safeTransferFrom(
                strategyAccount,
                address(this),
                accountAssetBalance
            );
        }

        STRATEGY_RESERVE.repay(initialLoan, returnedLoan);
    }

    /**
     * @notice Get liquidation/insurance premiums as well as collateral after paying premiums.
     * @dev Collateral is assumed to be already impacted by paying off loss.
     * @dev Both premiums can be zero if there is not enough remaining collateral, with
     * a preference on paying the liquidator.
     * @param collateral         The remaining collateral for the liquidated position.
     * @param availableAssets    The remaining assets in the loan associated with the liquidation.
     * @return updatedCollateral The collateral after paying premiums.
     * @return executorPremium   The premium paid to the executor.
     */
    function _getPremiums(
        uint256 collateral,
        uint256 availableAssets
    )
        internal
        view
        returns (uint256 updatedCollateral, uint256 executorPremium)
    {
        // Apply the executor premium: the fee earned by the liquidator,
        // calculated as a portion of the liquidated account value.
        //
        // Note that the premiums cannot exceed the collateral that is
        // available in the account.
        executorPremium = Math.min(
            availableAssets.percentToFraction(EXECUTOR_PREMIUM),
            collateral
        );
        updatedCollateral = collateral - executorPremium;

        // Apply the insurance premium: the fee accrued to the insurance fund,
        // calculated as a portion of the liquidated account value.
        updatedCollateral -= Math.min(
            availableAssets.percentToFraction(LIQUIDATION_INSURANCE_PREMIUM),
            updatedCollateral
        );

        return (updatedCollateral, executorPremium);
    }
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

import { Errors } from "../libraries/Errors.sol";
import { IStrategyController } from "../interfaces/IStrategyController.sol";
import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import { IStrategyReserve } from "../interfaces/IStrategyReserve.sol";

/**
 * @title ControllerHelpers
 * @author GoldLink
 *
 * @dev Abstract contract that contains logic for strategy contracts to access their controller.
 */
abstract contract ControllerHelpers {
    // ============ Constants ============

    /// @notice The `StrategyController` that manages this strategy.
    IStrategyController public immutable STRATEGY_CONTROLLER;

    // ============ Modifiers ============

    /// @dev Lock the strategy from reentrancy via the controller.
    modifier strategyNonReentrant() {
        STRATEGY_CONTROLLER.acquireStrategyLock();
        _;
        STRATEGY_CONTROLLER.releaseStrategyLock();
    }

    /// @dev Require the strategy to be unpaused.
    modifier whenNotPaused() {
        require(
            !STRATEGY_CONTROLLER.isPaused(),
            Errors.CANNOT_CALL_FUNCTION_WHEN_PAUSED
        );
        _;
    }

    // ============ Constructor ============

    constructor(IStrategyController controller) {
        require(
            address(controller) != address(0),
            Errors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        STRATEGY_CONTROLLER = controller;
    }

    // ============ Public Functions ============

    function isStrategyPaused() public view returns (bool isPaused) {
        return STRATEGY_CONTROLLER.isPaused();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IStrategyBank } from "../interfaces/IStrategyBank.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Constants } from "./Constants.sol";
import { PercentMath } from "./PercentMath.sol";

/**
 * @title StrategyBankHelpers
 * @author GoldLink
 *
 * @dev Library for strategy bank helpers.
 */
library StrategyBankHelpers {
    using PercentMath for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Implements get adjusted collateral, decreasing for loss and interest owed.
     * @param holdings            The holdings being evaluated.
     * @param loanValue           The value of the loan assets at present.
     * @return adjustedCollateral The value of the collateral after adjustments.
     */
    function getAdjustedCollateral(
        IStrategyBank.StrategyAccountHoldings memory holdings,
        uint256 loanValue
    ) internal pure returns (uint256 adjustedCollateral) {
        uint256 loss = holdings.loan - Math.min(holdings.loan, loanValue);

        // Adjust collateral for loss, either down for `assetChange` or to zero.
        return holdings.collateral - Math.min(holdings.collateral, loss);
    }

    /**
     * @notice Implements get health score, calculating the current health score
     * for a strategy account's holdings.
     * @param holdings     The strategy account holdings to get health score of.
     * @param loanValue    The value of the loan assets at present.
     * @return healthScore The health score of the provided holdings.
     */
    function getHealthScore(
        IStrategyBank.StrategyAccountHoldings memory holdings,
        uint256 loanValue
    ) internal pure returns (uint256 healthScore) {
        // Handle case where loan is 0 and health score is necessarily 1e18.
        if (holdings.loan == 0) {
            return Constants.ONE_HUNDRED_PERCENT;
        }

        // Get the adjusted collateral after profit, loss and interest.
        uint256 adjustedCollateral = getAdjustedCollateral(holdings, loanValue);

        // Return health score as a ratio of `(collateral - loss - interest)`
        // to loan. This is then multiplied by 1e18.
        return adjustedCollateral.fractionToPercentCeil(holdings.loan);
    }
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