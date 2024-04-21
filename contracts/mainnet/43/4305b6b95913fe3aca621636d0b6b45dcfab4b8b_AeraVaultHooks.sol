// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";
import "@openzeppelin/ERC165.sol";
import "@openzeppelin/SafeERC20.sol";
import "@openzeppelin/IERC20IncreaseAllowance.sol";
import "./interfaces/IHooks.sol";
import "./interfaces/IAeraVaultHooksEvents.sol";
import "./interfaces/IVault.sol";
import "./Sweepable.sol";
import "./TargetSighashLib.sol";
import "./Types.sol";
import {ONE} from "./Constants.sol";

/// @title AeraVaultHooks
/// @notice Default hooks contract which implements several safeguards.
/// @dev Connected vault MUST only call submit with tokens that can increase allowances with approve and increaseAllowance.
contract AeraVaultHooks is IHooks, IAeraVaultHooksEvents, Sweepable, ERC165 {
    using SafeERC20 for IERC20;

    /// @notice Min bound on minimum fraction of vault value that the vault has to retain
    ///         between submissions during a single day.
    /// @dev    Loose bound to mitigate initialization error.
    uint256 private constant _LOWEST_MIN_DAILY_VALUE = ONE / 2;

    /// @notice The minimum fraction of vault value that the vault has to
    ///         retain per day during submit transactions.
    ///         e.g. 0.9 (in 18-decimal form) allows the vault to lose up to
    ///         10% in value across consecutive submissions.
    uint256 public immutable minDailyValue;

    /// STORAGE ///

    /// @notice The address of the vault.
    address public vault;

    /// @notice Current day (UTC).
    uint256 public currentDay;

    /// @notice Accumulated value multiplier during submit transactions.
    uint256 public cumulativeDailyMultiplier;

    /// @notice Allowed target contract and sighash combinations.
    mapping(TargetSighash => bool) internal _targetSighashAllowed;

    /// @notice Total value of assets in vault before submission.
    /// @dev Assigned in `beforeSubmit` and used in `afterSubmit`.
    uint256 internal _beforeValue;

    /// ERRORS ///

    error Aera__CallerIsNotVault();
    error Aera__VaultIsZeroAddress();
    error Aera__HooksOwnerIsGuardian();
    error Aera__HooksOwnerIsVault();
    error Aera__MinDailyValueTooLow();
    error Aera__MinDailyValueIsNotLessThanOne();
    error Aera__NoCodeAtTarget(address target);
    error Aera__CallIsNotAllowed(Operation operation);
    error Aera__VaultValueBelowMinDailyValue();
    error Aera__AllowanceIsNotZero(address asset, address spender);
    error Aera__HooksInitialOwnerIsZeroAddress();
    error Aera__RemovingNonexistentTargetSighash(TargetSighash targetSighash);
    error Aera__AddingDuplicateTargetSighash(TargetSighash targetSighash);

    /// MODIFIERS ///

    /// @dev Throws if called by any account other than the vault.
    modifier onlyVault() {
        if (msg.sender != vault) {
            revert Aera__CallerIsNotVault();
        }
        _;
    }

    /// FUNCTIONS ///

    /// @param owner_ Initial owner address.
    /// @param vault_ Vault address.
    /// @param minDailyValue_ The minimum fraction of value that the vault has to retain
    ///                       during the day in the course of submissions.
    /// @param targetSighashAllowlist Array of target contract and sighash combinations to allow.
    constructor(
        address owner_,
        address vault_,
        uint256 minDailyValue_,
        TargetSighashData[] memory targetSighashAllowlist
    ) Ownable() {
        // Requirements: validate vault.
        if (vault_ == address(0)) {
            revert Aera__VaultIsZeroAddress();
        }
        if (owner_ == address(0)) {
            revert Aera__HooksInitialOwnerIsZeroAddress();
        }

        // Requirements: check that hooks initial owner is disaffiliated.
        if (owner_ == vault_) {
            revert Aera__HooksOwnerIsVault();
        }
        // Only check vault if it has been deployed already.
        // This will happen if we are deploying a new Hooks contract for an existing vault.
        if (vault_.code.length > 0) {
            address guardian = IVault(vault_).guardian();
            if (owner_ == guardian) {
                revert Aera__HooksOwnerIsGuardian();
            }
        }

        // Requirements: check that minimum daily value doesn't mandate vault growth.
        if (minDailyValue_ >= ONE) {
            revert Aera__MinDailyValueIsNotLessThanOne();
        }

        // Requirements: check that minimum daily value enforces a lower bound.
        if (minDailyValue_ < _LOWEST_MIN_DAILY_VALUE) {
            revert Aera__MinDailyValueTooLow();
        }

        uint256 numTargetSighashAllowlist = targetSighashAllowlist.length;

        // Effects: initialize target sighash allowlist.
        for (uint256 i = 0; i < numTargetSighashAllowlist;) {
            _addTargetSighash(
                targetSighashAllowlist[i].target,
                targetSighashAllowlist[i].selector
            );

            unchecked {
                i++; // gas savings
            }
        }

        // Effects: initialize state variables.
        vault = vault_;
        minDailyValue = minDailyValue_;
        currentDay = block.timestamp / 1 days;
        cumulativeDailyMultiplier = ONE;

        // Effects: set new owner.
        _transferOwnership(owner_);
    }

    /// @notice Add targetSighash pair to allowlist.
    /// @param target Address of target.
    /// @param selector Selector of function.
    function addTargetSighash(
        address target,
        bytes4 selector
    ) external onlyOwner {
        _addTargetSighash(target, selector);
    }

    /// @notice Remove targetSighash pair from allowlist.
    /// @param target Address of target.
    /// @param selector Selector of function.
    function removeTargetSighash(
        address target,
        bytes4 selector
    ) external onlyOwner {
        TargetSighash targetSighash =
            TargetSighashLib.toTargetSighash(target, selector);

        // Requirements: check that current target sighash is set.
        if (!_targetSighashAllowed[targetSighash]) {
            revert Aera__RemovingNonexistentTargetSighash(targetSighash);
        }

        // Effects: remove target sighash combination from the allowlist.
        delete _targetSighashAllowed[targetSighash];

        // Log the removal.
        emit TargetSighashRemoved(target, selector);
    }

    /// @inheritdoc IHooks
    function beforeDeposit(AssetValue[] memory amounts)
        external
        override
        onlyVault
    {}

    /// @inheritdoc IHooks
    function afterDeposit(AssetValue[] memory amounts)
        external
        override
        onlyVault
    {}

    /// @inheritdoc IHooks
    function beforeWithdraw(AssetValue[] memory amounts)
        external
        override
        onlyVault
    {}

    /// @inheritdoc IHooks
    function afterWithdraw(AssetValue[] memory amounts)
        external
        override
        onlyVault
    {}

    /// @inheritdoc IHooks
    function beforeSubmit(Operation[] calldata operations)
        external
        override
        onlyVault
    {
        uint256 numOperations = operations.length;
        bytes4 selector;

        // Requirements: validate that all operations are allowed.
        for (uint256 i = 0; i < numOperations;) {
            selector = bytes4(operations[i].data[0:4]);

            TargetSighash sigHash = TargetSighashLib.toTargetSighash(
                operations[i].target, selector
            );

            // Requirements: validate that the target sighash combination is allowed.
            if (!_targetSighashAllowed[sigHash]) {
                revert Aera__CallIsNotAllowed(operations[i]);
            }

            unchecked {
                i++;
            } // gas savings
        }

        // Effects: remember current vault value and ETH balance for use in afterSubmit.
        _beforeValue = IVault(vault).value();
    }

    /// @inheritdoc IHooks
    function afterSubmit(Operation[] calldata operations)
        external
        override
        onlyVault
    {
        uint256 newMultiplier;
        uint256 currentMultiplier = cumulativeDailyMultiplier;
        uint256 day = block.timestamp / 1 days;

        if (_beforeValue > 0) {
            // Initialize new cumulative multiplier with the current submit multiplier.
            newMultiplier = currentDay == day ? currentMultiplier : ONE;
            newMultiplier =
                (newMultiplier * IVault(vault).value()) / _beforeValue;

            // Requirements: check that daily execution loss is within bounds.
            if (newMultiplier < minDailyValue) {
                revert Aera__VaultValueBelowMinDailyValue();
            }

            // Effects: update the daily multiplier.
            if (currentMultiplier != newMultiplier) {
                cumulativeDailyMultiplier = newMultiplier;
            }
        }

        // Effects: reset current day for the next submission.
        if (currentDay != day) {
            currentDay = day;
        }

        // Effects: reset prior vault value for the next submission.
        _beforeValue = 0;

        uint256 numOperations = operations.length;
        bytes4 selector;
        address spender;
        uint256 amount;
        IERC20 token;

        // Requirements: check that there are no outgoing allowances that were introduced.
        for (uint256 i = 0; i < numOperations;) {
            selector = bytes4(operations[i].data[0:4]);
            if (_isAllowanceSelector(selector)) {
                // Extract spender and amount from the allowance transaction.
                (spender, amount) =
                    abi.decode(operations[i].data[4:], (address, uint256));

                // If amount is 0 then allowance hasn't been increased.
                if (amount == 0) {
                    unchecked {
                        i++;
                    } // gas savings
                    continue;
                }

                token = IERC20(operations[i].target);

                // Requirements: check that the current outgoing allowance for this token is zero.
                if (token.allowance(vault, spender) > 0) {
                    revert Aera__AllowanceIsNotZero(address(token), spender);
                }
            }
            unchecked {
                i++;
            } // gas savings
        }
    }

    /// @inheritdoc IHooks
    function beforeFinalize() external override onlyVault {}

    /// @inheritdoc IHooks
    function afterFinalize() external override onlyVault {
        // Effects: release storage
        currentDay = 0;
        cumulativeDailyMultiplier = 0;
    }

    /// @inheritdoc IHooks
    function decommission() external override onlyVault {
        // Effects: reset vault address.
        vault = address(0);

        // Effects: release storage
        currentDay = 0;
        cumulativeDailyMultiplier = 0;

        // Log decommissioning.
        emit Decommissioned();
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IHooks).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /// @notice Check whether target and sighash combination is allowed.
    /// @param target Address of target.
    /// @param selector Selector of function.
    function targetSighashAllowed(
        address target,
        bytes4 selector
    ) external view returns (bool) {
        return _targetSighashAllowed[TargetSighashLib.toTargetSighash(
            target, selector
        )];
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Add targetSighash pair to allowlist.
    /// @param target Address of target.
    /// @param selector Selector of function.
    function _addTargetSighash(address target, bytes4 selector) internal {
        // Requirements: check there is code at target.
        if (target.code.length == 0) {
            revert Aera__NoCodeAtTarget(target);
        }

        TargetSighash targetSighash =
            TargetSighashLib.toTargetSighash(target, selector);

        // Requirements: check that current target sighash is not set.
        if (_targetSighashAllowed[targetSighash]) {
            revert Aera__AddingDuplicateTargetSighash(targetSighash);
        }

        // Effects: add target sighash combination to the allowlist.
        _targetSighashAllowed[targetSighash] = true;

        // Log the addition.
        emit TargetSighashAdded(target, selector);
    }

    /// @notice Check whether selector is allowance related selector or not.
    /// @param selector Selector of calldata to check.
    /// @return isAllowanceSelector True if selector is allowance related selector.
    function _isAllowanceSelector(bytes4 selector)
        internal
        pure
        returns (bool isAllowanceSelector)
    {
        return selector == IERC20.approve.selector
            || selector == IERC20IncreaseAllowance.increaseAllowance.selector;
    }

    /// @notice Check that owner is not the vault or the guardian.
    /// @param owner_ Hooks owner address.
    /// @param vault_ Vault address.
    function _checkHooksOwner(address owner_, address vault_) internal view {
        if (owner_ == vault_) {
            revert Aera__HooksOwnerIsVault();
        }

        address guardian = IVault(vault_).guardian();
        if (owner_ == guardian) {
            revert Aera__HooksOwnerIsGuardian();
        }
    }

    /// @inheritdoc Ownable2Step
    function transferOwnership(address newOwner) public override onlyOwner {
        // Requirements: check that new owner is disaffiliated from existing roles.
        _checkHooksOwner(newOwner, vault);

        // Effects: initiate ownership transfer.
        super.transferOwnership(newOwner);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./Address.sol";

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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

pragma solidity ^0.8.0;

/**
 * @dev ERC20 but not IERC20 defines increaseAllowance
 */
interface IERC20IncreaseAllowance {
    /** 
     *  Atomically increases the allowance granted to spender by the caller. 
     *  This is an alternative to approve that can be used as a mitigation for 
     *  problems described in IERC20.approve. 
     *  Emits an Approval event indicating the updated allowance.
     *  Requirements: 
     *  spender cannot be the zero address.
     */ 
    function increaseAllowance(address spender, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {AssetValue, Operation} from "../Types.sol";

/// @title IHooks
/// @notice Interface for the hooks module.
interface IHooks {
    /// @notice Get address of vault.
    /// @return vault Vault address.
    function vault() external view returns (address vault);

    /// @notice Hook that runs before deposit.
    /// @param amounts Struct details for assets and amounts to deposit.
    /// @dev MUST revert if not called by vault.
    function beforeDeposit(AssetValue[] memory amounts) external;

    /// @notice Hook that runs after deposit.
    /// @param amounts Struct details for assets and amounts to deposit.
    /// @dev MUST revert if not called by vault.
    function afterDeposit(AssetValue[] memory amounts) external;

    /// @notice Hook that runs before withdraw.
    /// @param amounts Struct details for assets and amounts to withdraw.
    /// @dev MUST revert if not called by vault.
    function beforeWithdraw(AssetValue[] memory amounts) external;

    /// @notice Hook that runs after withdraw.
    /// @param amounts Struct details for assets and amounts to withdraw.
    /// @dev MUST revert if not called by vault.
    function afterWithdraw(AssetValue[] memory amounts) external;

    /// @notice Hook that runs before submit.
    /// @param operations Array of struct details for target and calldata to submit.
    /// @dev MUST revert if not called by vault.
    function beforeSubmit(Operation[] memory operations) external;

    /// @notice Hook that runs after submit.
    /// @param operations Array of struct details for target and calldata to submit.
    /// @dev MUST revert if not called by vault.
    function afterSubmit(Operation[] memory operations) external;

    /// @notice Hook that runs before finalize.
    /// @dev MUST revert if not called by vault.
    function beforeFinalize() external;

    /// @notice Hook that runs after finalize.
    /// @dev MUST revert if not called by vault.
    function afterFinalize() external;

    /// @notice Take hooks out of use.
    function decommission() external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TargetSighash} from "../Types.sol";

/// @title Events emitted by AeraVaultHooks implementation.
interface IAeraVaultHooksEvents {
    /// @notice Emitted when targetSighash is added to allowlist.
    /// @param target Address of target.
    /// @param selector Selector of function.
    event TargetSighashAdded(address indexed target, bytes4 indexed selector);

    /// @notice Emitted when targetSighash is removed from allowlist.
    /// @param target Address of target.
    /// @param selector Selector of function.
    event TargetSighashRemoved(
        address indexed target, bytes4 indexed selector
    );

    /// @notice Emitted when hooks contract is decommissioned.
    event Decommissioned();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";
import "./IAssetRegistry.sol";
import "./IVaultEvents.sol";
import "./IHooks.sol";

/// @title IVault
/// @notice Interface for the vault.
/// @dev Any implementation MUST also implement Ownable2Step.
interface IVault is IVaultEvents {
    /// ERRORS ///

    error Aera__AssetRegistryIsZeroAddress();
    error Aera__AssetRegistryIsNotValid(address assetRegistry);
    error Aera__AssetRegistryHasInvalidVault();
    error Aera__HooksIsZeroAddress();
    error Aera__HooksIsNotValid(address hooks);
    error Aera__HooksHasInvalidVault();
    error Aera__GuardianIsZeroAddress();
    error Aera__GuardianIsOwner();
    error Aera__InitialOwnerIsZeroAddress();
    error Aera__FeeRecipientIsZeroAddress();
    error Aera__ExecuteTargetIsHooksAddress();
    error Aera__ExecuteTargetIsVaultAddress();
    error Aera__SubmitTransfersAssetFromOwner();
    error Aera__SubmitRedeemERC4626AssetFromOwner();
    error Aera__SubmitTargetIsVaultAddress();
    error Aera__SubmitTargetIsHooksAddress(uint256 index);
    error Aera__FeeRecipientIsOwner();
    error Aera__FeeIsAboveMax(uint256 actual, uint256 max);
    error Aera__CallerIsNotOwnerAndGuardian();
    error Aera__CallerIsNotGuardian();
    error Aera__AssetIsNotRegistered(IERC20 asset);
    error Aera__AmountExceedsAvailable(
        IERC20 asset, uint256 amount, uint256 available
    );
    error Aera__ExecutionFailed(bytes result);
    error Aera__VaultIsFinalized();
    error Aera__SubmissionFailed(uint256 index, bytes result);
    error Aera__CannotUseReservedFees();
    error Aera__SpotPricesReverted();
    error Aera__AmountsOrderIsIncorrect(uint256 index);
    error Aera__NoAvailableFeesForCaller(address caller);
    error Aera__NoClaimableFeesForCaller(address caller);
    error Aera__NotWrappedNativeTokenContract();
    error Aera__CannotRenounceOwnership();

    /// FUNCTIONS ///

    /// @notice Deposit assets.
    /// @param amounts Assets and amounts to deposit.
    /// @dev MUST revert if not called by owner.
    function deposit(AssetValue[] memory amounts) external;

    /// @notice Withdraw assets.
    /// @param amounts Assets and amounts to withdraw.
    /// @dev MUST revert if not called by owner.
    function withdraw(AssetValue[] memory amounts) external;

    /// @notice Set current guardian and fee recipient.
    /// @param guardian New guardian address.
    /// @param feeRecipient New fee recipient address.
    /// @dev MUST revert if not called by owner.
    function setGuardianAndFeeRecipient(
        address guardian,
        address feeRecipient
    ) external;

    /// @notice Sets the current hooks module.
    /// @param hooks New hooks module address.
    /// @dev MUST revert if not called by owner.
    function setHooks(address hooks) external;

    /// @notice Execute a transaction via the vault.
    /// @dev Execution still should work when vault is finalized.
    /// @param operation Struct details for target and calldata to execute.
    /// @dev MUST revert if not called by owner.
    function execute(Operation memory operation) external;

    /// @notice Terminate the vault and return all funds to owner.
    /// @dev MUST revert if not called by owner.
    function finalize() external;

    /// @notice Stops the guardian from submission and halts fee accrual.
    /// @dev MUST revert if not called by owner or guardian.
    function pause() external;

    /// @notice Resume fee accrual and guardian submissions.
    /// @dev MUST revert if not called by owner.
    function resume() external;

    /// @notice Submit a series of transactions for execution via the vault.
    /// @param operations Sequence of operations to execute.
    /// @dev MUST revert if not called by guardian.
    function submit(Operation[] memory operations) external;

    /// @notice Claim fees on behalf of a current or previous fee recipient.
    function claim() external;

    /// @notice Get the current guardian.
    /// @return guardian Address of guardian.
    function guardian() external view returns (address guardian);

    /// @notice Get the current fee recipient.
    /// @return feeRecipient Address of fee recipient.
    function feeRecipient() external view returns (address feeRecipient);

    /// @notice Get the current asset registry.
    /// @return assetRegistry Address of asset registry.
    function assetRegistry()
        external
        view
        returns (IAssetRegistry assetRegistry);

    /// @notice Get the current hooks module address.
    /// @return hooks Address of hooks module.
    function hooks() external view returns (IHooks hooks);

    /// @notice Get fee per second.
    /// @return fee Fee per second in 18 decimal fixed point format.
    function fee() external view returns (uint256 fee);

    /// @notice Get current balances of all assets.
    /// @return assetAmounts Amounts of registered assets.
    function holdings()
        external
        view
        returns (AssetValue[] memory assetAmounts);

    /// @notice Get current total value of assets in vault.
    /// @return value Current total value.
    function value() external view returns (uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/Ownable2Step.sol";
import "@openzeppelin/SafeERC20.sol";
import "./interfaces/ISweepable.sol";

/// @title Sweepable.
/// @notice Aera Sweepable contract.
/// @dev Allows owner of the contract to restore accidentally send tokens
//       and the chain's native token.
contract Sweepable is ISweepable, Ownable2Step {
    using SafeERC20 for IERC20;

    /// @inheritdoc ISweepable
    function sweep(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            msg.sender.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }

        emit Sweep(token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import {TargetSighash} from "./Types.sol";

/// @title TargetSighashLib
/// @notice Conversion operations for the TargetSighash compound type.
library TargetSighashLib {
    /// @notice Get sighash from target and selector.
    /// @param target Target contract address.
    /// @param selector Function selector.
    /// @return targetSighash Packed value of target and selector.
    function toTargetSighash(
        address target,
        bytes4 selector
    ) internal pure returns (TargetSighash targetSighash) {
        targetSighash = TargetSighash.wrap(
            bytes20(target) | (bytes32(selector) >> (20 * 8))
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";
import "./interfaces/IAssetRegistry.sol";

// Types.sol
//
// This file defines the types used in V2.

/// @notice Combination of contract address and sighash to be used in allowlist.
/// @dev It's packed as follows:
///      [target 160 bits] [selector 32 bits] [<empty> 64 bits]
type TargetSighash is bytes32;

/// @notice Struct encapulating an asset and an associated value.
/// @param asset Asset address.
/// @param value The associated value for this asset (e.g., amount or price).
struct AssetValue {
    IERC20 asset;
    uint256 value;
}

/// @notice Execution details for a vault operation.
/// @param target Target contract address.
/// @param value Native token amount.
/// @param data Calldata.
struct Operation {
    address target;
    uint256 value;
    bytes data;
}

/// @notice Contract address and sighash struct to be used in the public interface.
struct TargetSighashData {
    address target;
    bytes4 selector;
}

/// @notice Parameters for vault deployment.
/// @param owner Initial owner address.
/// @param assetRegistry Asset registry address.
/// @param hooks Hooks address.
/// @param guardian Guardian address.
/// @param feeRecipient Fee recipient address.
/// @param fee Fees accrued per second, denoted in 18 decimal fixed point format.
struct Parameters {
    address owner;
    address assetRegistry;
    address hooks;
    address guardian;
    address feeRecipient;
    uint256 fee;
}

/// @notice Vault parameters for vault deployment.
/// @param owner Initial owner address.
/// @param guardian Guardian address.
/// @param feeRecipient Fee recipient address.
/// @param fee Fees accrued per second, denoted in 18 decimal fixed point format.
struct VaultParameters {
    address owner;
    address guardian;
    address feeRecipient;
    uint256 fee;
}

/// @notice Asset registry parameters for asset registry deployment.
/// @param factory Asset registry factory address.
/// @param owner Initial owner address.
/// @param assets Initial list of registered assets.
/// @param numeraireToken Numeraire token address.
/// @param feeToken Fee token address.
/// @param sequencer Sequencer Uptime Feed address for L2.
struct AssetRegistryParameters {
    address factory;
    address owner;
    IAssetRegistry.AssetInformation[] assets;
    IERC20 numeraireToken;
    IERC20 feeToken;
    AggregatorV2V3Interface sequencer;
}

/// @notice Hooks parameters for hooks deployment.
/// @param factory Hooks factory address.
/// @param owner Initial owner address.
/// @param minDailyValue The fraction of value that the vault has to retain per day
///                      in the course of submissions.
/// @param targetSighashAllowlist Array of target contract and sighash combinations to allow.
struct HooksParameters {
    address factory;
    address owner;
    uint256 minDailyValue;
    TargetSighashData[] targetSighashAllowlist;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

// Constants.sol
//
// This file defines the constants used across several contracts in V2.

/// @dev Fixed point multiplier.
uint256 constant ONE = 1e18;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/IERC20.sol";

/// @title IAssetRegistry
/// @notice Asset registry interface.
/// @dev Any implementation MUST also implement Ownable2Step and ERC165.
interface IAssetRegistry {
    /// @param asset Asset address.
    /// @param heartbeat Frequency of oracle price updates.
    /// @param isERC4626 True if yield-bearing asset, false if just an ERC20 asset.
    /// @param oracle If applicable, oracle address for asset.
    struct AssetInformation {
        IERC20 asset;
        uint256 heartbeat;
        bool isERC4626;
        AggregatorV2V3Interface oracle;
    }

    /// @param asset Asset address.
    /// @param spotPrice Spot price of an asset in Numeraire token terms.
    struct AssetPriceReading {
        IERC20 asset;
        uint256 spotPrice;
    }

    /// @notice Get address of vault.
    /// @return vault Address of vault.
    function vault() external view returns (address vault);

    /// @notice Get a list of all registered assets.
    /// @return assets List of assets.
    /// @dev MUST return assets in an order sorted by address.
    function assets()
        external
        view
        returns (AssetInformation[] memory assets);

    /// @notice Get address of fee token.
    /// @return feeToken Address of fee token.
    /// @dev Represented as an address for efficiency reasons.
    /// @dev MUST be present in assets array.
    function feeToken() external view returns (IERC20 feeToken);

    /// @notice Get the index of the Numeraire token in the assets array.
    /// @return numeraireToken Numeraire token address.
    /// @dev Represented as an index for efficiency reasons.
    /// @dev MUST be a number between 0 (inclusive) and the length of assets array (exclusive).
    function numeraireToken() external view returns (IERC20 numeraireToken);

    /// @notice Calculate spot prices of non-ERC4626 assets.
    /// @return spotPrices Spot prices of non-ERC4626 assets in 18 decimals.
    /// @dev MUST return assets in the same order as in assets but with ERC4626 assets filtered out.
    /// @dev MUST also include Numeraire token (spot price = 1).
    /// @dev MAY revert if oracle prices for any asset are unreliable at the time.
    function spotPrices()
        external
        view
        returns (AssetPriceReading[] memory spotPrices);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@openzeppelin/IERC20.sol";

import {AssetValue, Operation} from "../Types.sol";

/// @title Interface for vault events.
interface IVaultEvents {
    /// @notice Emitted when deposit is called.
    /// @param owner Owner address.
    /// @param asset Deposited asset.
    /// @param amount Deposited asset amount.
    event Deposit(address indexed owner, IERC20 indexed asset, uint256 amount);

    /// @notice Emitted when withdraw is called.
    /// @param owner Owner address.
    /// @param asset Withdrawn asset.
    /// @param amount Withdrawn asset amount.
    event Withdraw(
        address indexed owner, IERC20 indexed asset, uint256 amount
    );

    /// @notice Emitted when guardian is set.
    /// @param guardian Address of new guardian.
    /// @param feeRecipient Address of new fee recipient.
    event SetGuardianAndFeeRecipient(
        address indexed guardian, address indexed feeRecipient
    );

    /// @notice Emitted when asset registry is set.
    /// @param assetRegistry Address of new asset registry.
    event SetAssetRegistry(address assetRegistry);

    /// @notice Emitted when hooks is set.
    /// @param hooks Address of new hooks.
    event SetHooks(address hooks);

    /// @notice Emitted when execute is called.
    /// @param owner Owner address.
    /// @param operation Struct details for target and calldata.
    event Executed(address indexed owner, Operation operation);

    /// @notice Emitted when vault is finalized.
    /// @param owner Owner address.
    /// @param withdrawnAmounts Struct details for withdrawn assets and amounts (sent to owner).
    event Finalized(address indexed owner, AssetValue[] withdrawnAmounts);

    /// @notice Emitted when submit is called.
    /// @param guardian Guardian address.
    /// @param operations Array of struct details for targets and calldatas.
    event Submitted(address indexed guardian, Operation[] operations);

    /// @notice Emitted when guardian fees are claimed.
    /// @param feeRecipient Fee recipient address.
    /// @param claimedFee Claimed amount of fee token.
    /// @param unclaimedFee Unclaimed amount of fee token (unclaimed because Vault does not have enough balance of feeToken).
    /// @param feeTotal New total reserved fee value.
    event Claimed(
        address indexed feeRecipient,
        uint256 claimedFee,
        uint256 unclaimedFee,
        uint256 feeTotal
    );

    /// @notice Emitted when new fees are reserved for recipient.
    /// @param feeRecipient Fee recipient address.
    /// @param newFee Fee amount reserved.
    /// @param lastFeeCheckpoint Updated fee checkpoint.
    /// @param lastValue Last registered vault value.
    /// @param lastFeeTokenPrice Last registered fee token price.
    /// @param feeTotal New total reserved fee value.
    event FeesReserved(
        address indexed feeRecipient,
        uint256 newFee,
        uint256 lastFeeCheckpoint,
        uint256 lastValue,
        uint256 lastFeeTokenPrice,
        uint256 feeTotal
    );

    /// @notice Emitted when no fees are reserved.
    /// @param lastFeeCheckpoint Updated fee checkpoint.
    /// @param lastValue Last registered vault value.
    /// @param feeTotal New total reserved fee value.
    event NoFeesReserved(
        uint256 lastFeeCheckpoint,
        uint256 lastValue,
        uint256 feeTotal
    );

    /// @notice Emitted when the call to get spot prices from the asset registry reverts.
    /// @param reason Revert reason.
    event SpotPricesReverted(bytes reason);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

/// @title Interface for sweepable module.
interface ISweepable {
    /// @notice Emitted when sweep is called.
    /// @param token Token address or zero address if recovering the chain's native token.
    /// @param amount Withdrawn amount of token.
    event Sweep(address token, uint256 amount);

    /// @notice Withdraw any tokens accidentally sent to contract.
    /// @param token Token address to withdraw or zero address for the chain's native token.
    /// @param amount Amount to withdraw.
    function sweep(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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