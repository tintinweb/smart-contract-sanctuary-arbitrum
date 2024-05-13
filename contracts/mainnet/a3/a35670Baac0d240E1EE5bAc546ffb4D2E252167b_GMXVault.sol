// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/AccessManaged.sol)

pragma solidity ^0.8.20;

import {IAuthority} from "./IAuthority.sol";
import {AuthorityUtils} from "./AuthorityUtils.sol";
import {IAccessManager} from "./IAccessManager.sol";
import {IAccessManaged} from "./IAccessManaged.sol";
import {Context} from "../../utils/Context.sol";

/**
 * @dev This contract module makes available a {restricted} modifier. Functions decorated with this modifier will be
 * permissioned according to an "authority": a contract like {AccessManager} that follows the {IAuthority} interface,
 * implementing a policy that allows certain callers to access certain functions.
 *
 * IMPORTANT: The `restricted` modifier should never be used on `internal` functions, judiciously used in `public`
 * functions, and ideally only used in `external` functions. See {restricted}.
 */
abstract contract AccessManaged is Context, IAccessManaged {
    address private _authority;

    bool private _consumingSchedule;

    /**
     * @dev Initializes the contract connected to an initial authority.
     */
    constructor(address initialAuthority) {
        _setAuthority(initialAuthority);
    }

    /**
     * @dev Restricts access to a function as defined by the connected Authority for this contract and the
     * caller and selector of the function that entered the contract.
     *
     * [IMPORTANT]
     * ====
     * In general, this modifier should only be used on `external` functions. It is okay to use it on `public`
     * functions that are used as external entry points and are not called internally. Unless you know what you're
     * doing, it should never be used on `internal` functions. Failure to follow these rules can have critical security
     * implications! This is because the permissions are determined by the function that entered the contract, i.e. the
     * function at the bottom of the call stack, and not the function where the modifier is visible in the source code.
     * ====
     *
     * [WARNING]
     * ====
     * Avoid adding this modifier to the https://docs.soliditylang.org/en/v0.8.20/contracts.html#receive-ether-function[`receive()`]
     * function or the https://docs.soliditylang.org/en/v0.8.20/contracts.html#fallback-function[`fallback()`]. These
     * functions are the only execution paths where a function selector cannot be unambiguosly determined from the calldata
     * since the selector defaults to `0x00000000` in the `receive()` function and similarly in the `fallback()` function
     * if no calldata is provided. (See {_checkCanCall}).
     *
     * The `receive()` function will always panic whereas the `fallback()` may panic depending on the calldata length.
     * ====
     */
    modifier restricted() {
        _checkCanCall(_msgSender(), _msgData());
        _;
    }

    /// @inheritdoc IAccessManaged
    function authority() public view virtual returns (address) {
        return _authority;
    }

    /// @inheritdoc IAccessManaged
    function setAuthority(address newAuthority) public virtual {
        address caller = _msgSender();
        if (caller != authority()) {
            revert AccessManagedUnauthorized(caller);
        }
        if (newAuthority.code.length == 0) {
            revert AccessManagedInvalidAuthority(newAuthority);
        }
        _setAuthority(newAuthority);
    }

    /// @inheritdoc IAccessManaged
    function isConsumingScheduledOp() public view returns (bytes4) {
        return _consumingSchedule ? this.isConsumingScheduledOp.selector : bytes4(0);
    }

    /**
     * @dev Transfers control to a new authority. Internal function with no access restriction. Allows bypassing the
     * permissions set by the current authority.
     */
    function _setAuthority(address newAuthority) internal virtual {
        _authority = newAuthority;
        emit AuthorityUpdated(newAuthority);
    }

    /**
     * @dev Reverts if the caller is not allowed to call the function identified by a selector. Panics if the calldata
     * is less than 4 bytes long.
     */
    function _checkCanCall(address caller, bytes calldata data) internal virtual {
        (bool immediate, uint32 delay) = AuthorityUtils.canCallWithDelay(
            authority(),
            caller,
            address(this),
            bytes4(data[0:4])
        );
        if (!immediate) {
            if (delay > 0) {
                _consumingSchedule = true;
                IAccessManager(authority()).consumeScheduledOp(caller, data);
                _consumingSchedule = false;
            } else {
                revert AccessManagedUnauthorized(caller);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/AuthorityUtils.sol)

pragma solidity ^0.8.20;

import {IAuthority} from "./IAuthority.sol";

library AuthorityUtils {
    /**
     * @dev Since `AccessManager` implements an extended IAuthority interface, invoking `canCall` with backwards compatibility
     * for the preexisting `IAuthority` interface requires special care to avoid reverting on insufficient return data.
     * This helper function takes care of invoking `canCall` in a backwards compatible way without reverting.
     */
    function canCallWithDelay(
        address authority,
        address caller,
        address target,
        bytes4 selector
    ) internal view returns (bool immediate, uint32 delay) {
        (bool success, bytes memory data) = authority.staticcall(
            abi.encodeCall(IAuthority.canCall, (caller, target, selector))
        );
        if (success) {
            if (data.length >= 0x40) {
                (immediate, delay) = abi.decode(data, (bool, uint32));
            } else if (data.length >= 0x20) {
                immediate = abi.decode(data, (bool));
            }
        }
        return (immediate, delay);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAccessManaged.sol)

pragma solidity ^0.8.20;

interface IAccessManaged {
    /**
     * @dev Authority that manages this contract was updated.
     */
    event AuthorityUpdated(address authority);

    error AccessManagedUnauthorized(address caller);
    error AccessManagedRequiredDelay(address caller, uint32 delay);
    error AccessManagedInvalidAuthority(address authority);

    /**
     * @dev Returns the current authority.
     */
    function authority() external view returns (address);

    /**
     * @dev Transfers control to a new authority. The caller must be the current authority.
     */
    function setAuthority(address) external;

    /**
     * @dev Returns true only in the context of a delayed restricted call, at the moment that the scheduled operation is
     * being consumed. Prevents denial of service for delayed restricted calls in the case that the contract performs
     * attacker controlled calls.
     */
    function isConsumingScheduledOp() external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAccessManager.sol)

pragma solidity ^0.8.20;

import {IAccessManaged} from "./IAccessManaged.sol";
import {Time} from "../../utils/types/Time.sol";

interface IAccessManager {
    /**
     * @dev A delayed operation was scheduled.
     */
    event OperationScheduled(
        bytes32 indexed operationId,
        uint32 indexed nonce,
        uint48 schedule,
        address caller,
        address target,
        bytes data
    );

    /**
     * @dev A scheduled operation was executed.
     */
    event OperationExecuted(bytes32 indexed operationId, uint32 indexed nonce);

    /**
     * @dev A scheduled operation was canceled.
     */
    event OperationCanceled(bytes32 indexed operationId, uint32 indexed nonce);

    /**
     * @dev Informational labelling for a roleId.
     */
    event RoleLabel(uint64 indexed roleId, string label);

    /**
     * @dev Emitted when `account` is granted `roleId`.
     *
     * NOTE: The meaning of the `since` argument depends on the `newMember` argument.
     * If the role is granted to a new member, the `since` argument indicates when the account becomes a member of the role,
     * otherwise it indicates the execution delay for this account and roleId is updated.
     */
    event RoleGranted(uint64 indexed roleId, address indexed account, uint32 delay, uint48 since, bool newMember);

    /**
     * @dev Emitted when `account` membership or `roleId` is revoked. Unlike granting, revoking is instantaneous.
     */
    event RoleRevoked(uint64 indexed roleId, address indexed account);

    /**
     * @dev Role acting as admin over a given `roleId` is updated.
     */
    event RoleAdminChanged(uint64 indexed roleId, uint64 indexed admin);

    /**
     * @dev Role acting as guardian over a given `roleId` is updated.
     */
    event RoleGuardianChanged(uint64 indexed roleId, uint64 indexed guardian);

    /**
     * @dev Grant delay for a given `roleId` will be updated to `delay` when `since` is reached.
     */
    event RoleGrantDelayChanged(uint64 indexed roleId, uint32 delay, uint48 since);

    /**
     * @dev Target mode is updated (true = closed, false = open).
     */
    event TargetClosed(address indexed target, bool closed);

    /**
     * @dev Role required to invoke `selector` on `target` is updated to `roleId`.
     */
    event TargetFunctionRoleUpdated(address indexed target, bytes4 selector, uint64 indexed roleId);

    /**
     * @dev Admin delay for a given `target` will be updated to `delay` when `since` is reached.
     */
    event TargetAdminDelayUpdated(address indexed target, uint32 delay, uint48 since);

    error AccessManagerAlreadyScheduled(bytes32 operationId);
    error AccessManagerNotScheduled(bytes32 operationId);
    error AccessManagerNotReady(bytes32 operationId);
    error AccessManagerExpired(bytes32 operationId);
    error AccessManagerLockedAccount(address account);
    error AccessManagerLockedRole(uint64 roleId);
    error AccessManagerBadConfirmation();
    error AccessManagerUnauthorizedAccount(address msgsender, uint64 roleId);
    error AccessManagerUnauthorizedCall(address caller, address target, bytes4 selector);
    error AccessManagerUnauthorizedConsume(address target);
    error AccessManagerUnauthorizedCancel(address msgsender, address caller, address target, bytes4 selector);
    error AccessManagerInvalidInitialAdmin(address initialAdmin);

    /**
     * @dev Check if an address (`caller`) is authorised to call a given function on a given contract directly (with
     * no restriction). Additionally, it returns the delay needed to perform the call indirectly through the {schedule}
     * & {execute} workflow.
     *
     * This function is usually called by the targeted contract to control immediate execution of restricted functions.
     * Therefore we only return true if the call can be performed without any delay. If the call is subject to a
     * previously set delay (not zero), then the function should return false and the caller should schedule the operation
     * for future execution.
     *
     * If `immediate` is true, the delay can be disregarded and the operation can be immediately executed, otherwise
     * the operation can be executed if and only if delay is greater than 0.
     *
     * NOTE: The IAuthority interface does not include the `uint32` delay. This is an extension of that interface that
     * is backward compatible. Some contracts may thus ignore the second return argument. In that case they will fail
     * to identify the indirect workflow, and will consider calls that require a delay to be forbidden.
     *
     * NOTE: This function does not report the permissions of this manager itself. These are defined by the
     * {_canCallSelf} function instead.
     */
    function canCall(
        address caller,
        address target,
        bytes4 selector
    ) external view returns (bool allowed, uint32 delay);

    /**
     * @dev Expiration delay for scheduled proposals. Defaults to 1 week.
     *
     * IMPORTANT: Avoid overriding the expiration with 0. Otherwise every contract proposal will be expired immediately,
     * disabling any scheduling usage.
     */
    function expiration() external view returns (uint32);

    /**
     * @dev Minimum setback for all delay updates, with the exception of execution delays. It
     * can be increased without setback (and reset via {revokeRole} in the case event of an
     * accidental increase). Defaults to 5 days.
     */
    function minSetback() external view returns (uint32);

    /**
     * @dev Get whether the contract is closed disabling any access. Otherwise role permissions are applied.
     */
    function isTargetClosed(address target) external view returns (bool);

    /**
     * @dev Get the role required to call a function.
     */
    function getTargetFunctionRole(address target, bytes4 selector) external view returns (uint64);

    /**
     * @dev Get the admin delay for a target contract. Changes to contract configuration are subject to this delay.
     */
    function getTargetAdminDelay(address target) external view returns (uint32);

    /**
     * @dev Get the id of the role that acts as an admin for the given role.
     *
     * The admin permission is required to grant the role, revoke the role and update the execution delay to execute
     * an operation that is restricted to this role.
     */
    function getRoleAdmin(uint64 roleId) external view returns (uint64);

    /**
     * @dev Get the role that acts as a guardian for a given role.
     *
     * The guardian permission allows canceling operations that have been scheduled under the role.
     */
    function getRoleGuardian(uint64 roleId) external view returns (uint64);

    /**
     * @dev Get the role current grant delay.
     *
     * Its value may change at any point without an event emitted following a call to {setGrantDelay}.
     * Changes to this value, including effect timepoint are notified in advance by the {RoleGrantDelayChanged} event.
     */
    function getRoleGrantDelay(uint64 roleId) external view returns (uint32);

    /**
     * @dev Get the access details for a given account for a given role. These details include the timepoint at which
     * membership becomes active, and the delay applied to all operation by this user that requires this permission
     * level.
     *
     * Returns:
     * [0] Timestamp at which the account membership becomes valid. 0 means role is not granted.
     * [1] Current execution delay for the account.
     * [2] Pending execution delay for the account.
     * [3] Timestamp at which the pending execution delay will become active. 0 means no delay update is scheduled.
     */
    function getAccess(uint64 roleId, address account) external view returns (uint48, uint32, uint32, uint48);

    /**
     * @dev Check if a given account currently has the permission level corresponding to a given role. Note that this
     * permission might be associated with an execution delay. {getAccess} can provide more details.
     */
    function hasRole(uint64 roleId, address account) external view returns (bool, uint32);

    /**
     * @dev Give a label to a role, for improved role discoverability by UIs.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleLabel} event.
     */
    function labelRole(uint64 roleId, string calldata label) external;

    /**
     * @dev Add `account` to `roleId`, or change its execution delay.
     *
     * This gives the account the authorization to call any function that is restricted to this role. An optional
     * execution delay (in seconds) can be set. If that delay is non 0, the user is required to schedule any operation
     * that is restricted to members of this role. The user will only be able to execute the operation after the delay has
     * passed, before it has expired. During this period, admin and guardians can cancel the operation (see {cancel}).
     *
     * If the account has already been granted this role, the execution delay will be updated. This update is not
     * immediate and follows the delay rules. For example, if a user currently has a delay of 3 hours, and this is
     * called to reduce that delay to 1 hour, the new delay will take some time to take effect, enforcing that any
     * operation executed in the 3 hours that follows this update was indeed scheduled before this update.
     *
     * Requirements:
     *
     * - the caller must be an admin for the role (see {getRoleAdmin})
     * - granted role must not be the `PUBLIC_ROLE`
     *
     * Emits a {RoleGranted} event.
     */
    function grantRole(uint64 roleId, address account, uint32 executionDelay) external;

    /**
     * @dev Remove an account from a role, with immediate effect. If the account does not have the role, this call has
     * no effect.
     *
     * Requirements:
     *
     * - the caller must be an admin for the role (see {getRoleAdmin})
     * - revoked role must not be the `PUBLIC_ROLE`
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function revokeRole(uint64 roleId, address account) external;

    /**
     * @dev Renounce role permissions for the calling account with immediate effect. If the sender is not in
     * the role this call has no effect.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * Emits a {RoleRevoked} event if the account had the role.
     */
    function renounceRole(uint64 roleId, address callerConfirmation) external;

    /**
     * @dev Change admin role for a given role.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleAdminChanged} event
     */
    function setRoleAdmin(uint64 roleId, uint64 admin) external;

    /**
     * @dev Change guardian role for a given role.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleGuardianChanged} event
     */
    function setRoleGuardian(uint64 roleId, uint64 guardian) external;

    /**
     * @dev Update the delay for granting a `roleId`.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {RoleGrantDelayChanged} event.
     */
    function setGrantDelay(uint64 roleId, uint32 newDelay) external;

    /**
     * @dev Set the role required to call functions identified by the `selectors` in the `target` contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetFunctionRoleUpdated} event per selector.
     */
    function setTargetFunctionRole(address target, bytes4[] calldata selectors, uint64 roleId) external;

    /**
     * @dev Set the delay for changing the configuration of a given target contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetAdminDelayUpdated} event.
     */
    function setTargetAdminDelay(address target, uint32 newDelay) external;

    /**
     * @dev Set the closed flag for a contract.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     *
     * Emits a {TargetClosed} event.
     */
    function setTargetClosed(address target, bool closed) external;

    /**
     * @dev Return the timepoint at which a scheduled operation will be ready for execution. This returns 0 if the
     * operation is not yet scheduled, has expired, was executed, or was canceled.
     */
    function getSchedule(bytes32 id) external view returns (uint48);

    /**
     * @dev Return the nonce for the latest scheduled operation with a given id. Returns 0 if the operation has never
     * been scheduled.
     */
    function getNonce(bytes32 id) external view returns (uint32);

    /**
     * @dev Schedule a delayed operation for future execution, and return the operation identifier. It is possible to
     * choose the timestamp at which the operation becomes executable as long as it satisfies the execution delays
     * required for the caller. The special value zero will automatically set the earliest possible time.
     *
     * Returns the `operationId` that was scheduled. Since this value is a hash of the parameters, it can reoccur when
     * the same parameters are used; if this is relevant, the returned `nonce` can be used to uniquely identify this
     * scheduled operation from other occurrences of the same `operationId` in invocations of {execute} and {cancel}.
     *
     * Emits a {OperationScheduled} event.
     *
     * NOTE: It is not possible to concurrently schedule more than one operation with the same `target` and `data`. If
     * this is necessary, a random byte can be appended to `data` to act as a salt that will be ignored by the target
     * contract if it is using standard Solidity ABI encoding.
     */
    function schedule(address target, bytes calldata data, uint48 when) external returns (bytes32, uint32);

    /**
     * @dev Execute a function that is delay restricted, provided it was properly scheduled beforehand, or the
     * execution delay is 0.
     *
     * Returns the nonce that identifies the previously scheduled operation that is executed, or 0 if the
     * operation wasn't previously scheduled (if the caller doesn't have an execution delay).
     *
     * Emits an {OperationExecuted} event only if the call was scheduled and delayed.
     */
    function execute(address target, bytes calldata data) external payable returns (uint32);

    /**
     * @dev Cancel a scheduled (delayed) operation. Returns the nonce that identifies the previously scheduled
     * operation that is cancelled.
     *
     * Requirements:
     *
     * - the caller must be the proposer, a guardian of the targeted function, or a global admin
     *
     * Emits a {OperationCanceled} event.
     */
    function cancel(address caller, address target, bytes calldata data) external returns (uint32);

    /**
     * @dev Consume a scheduled operation targeting the caller. If such an operation exists, mark it as consumed
     * (emit an {OperationExecuted} event and clean the state). Otherwise, throw an error.
     *
     * This is useful for contract that want to enforce that calls targeting them were scheduled on the manager,
     * with all the verifications that it implies.
     *
     * Emit a {OperationExecuted} event.
     */
    function consumeScheduledOp(address caller, bytes calldata data) external;

    /**
     * @dev Hashing function for delayed operations.
     */
    function hashOperation(address caller, address target, bytes calldata data) external view returns (bytes32);

    /**
     * @dev Changes the authority of a target managed by this manager instance.
     *
     * Requirements:
     *
     * - the caller must be a global admin
     */
    function updateAuthority(address target, address newAuthority) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/manager/IAuthority.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard interface for permissioning originally defined in Dappsys.
 */
interface IAuthority {
    /**
     * @dev Returns true if the caller can invoke on a target the function identified by a function selector.
     */
    function canCall(address caller, address target, bytes4 selector) external view returns (bool allowed);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/types/Time.sol)

pragma solidity ^0.8.20;

import {Math} from "../math/Math.sol";
import {SafeCast} from "../math/SafeCast.sol";

/**
 * @dev This library provides helpers for manipulating time-related objects.
 *
 * It uses the following types:
 * - `uint48` for timepoints
 * - `uint32` for durations
 *
 * While the library doesn't provide specific types for timepoints and duration, it does provide:
 * - a `Delay` type to represent duration that can be programmed to change value automatically at a given point
 * - additional helper functions
 */
library Time {
    using Time for *;

    /**
     * @dev Get the block timestamp as a Timepoint.
     */
    function timestamp() internal view returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /**
     * @dev Get the block number as a Timepoint.
     */
    function blockNumber() internal view returns (uint48) {
        return SafeCast.toUint48(block.number);
    }

    // ==================================================== Delay =====================================================
    /**
     * @dev A `Delay` is a uint32 duration that can be programmed to change value automatically at a given point in the
     * future. The "effect" timepoint describes when the transitions happens from the "old" value to the "new" value.
     * This allows updating the delay applied to some operation while keeping some guarantees.
     *
     * In particular, the {update} function guarantees that if the delay is reduced, the old delay still applies for
     * some time. For example if the delay is currently 7 days to do an upgrade, the admin should not be able to set
     * the delay to 0 and upgrade immediately. If the admin wants to reduce the delay, the old delay (7 days) should
     * still apply for some time.
     *
     *
     * The `Delay` type is 112 bits long, and packs the following:
     *
     * ```
     *   | [uint48]: effect date (timepoint)
     *   |           | [uint32]: value before (duration)
     *   ↓           ↓       ↓ [uint32]: value after (duration)
     * 0xAAAAAAAAAAAABBBBBBBBCCCCCCCC
     * ```
     *
     * NOTE: The {get} and {withUpdate} functions operate using timestamps. Block number based delays are not currently
     * supported.
     */
    type Delay is uint112;

    /**
     * @dev Wrap a duration into a Delay to add the one-step "update in the future" feature
     */
    function toDelay(uint32 duration) internal pure returns (Delay) {
        return Delay.wrap(duration);
    }

    /**
     * @dev Get the value at a given timepoint plus the pending value and effect timepoint if there is a scheduled
     * change after this timepoint. If the effect timepoint is 0, then the pending value should not be considered.
     */
    function _getFullAt(Delay self, uint48 timepoint) private pure returns (uint32, uint32, uint48) {
        (uint32 valueBefore, uint32 valueAfter, uint48 effect) = self.unpack();
        return effect <= timepoint ? (valueAfter, 0, 0) : (valueBefore, valueAfter, effect);
    }

    /**
     * @dev Get the current value plus the pending value and effect timepoint if there is a scheduled change. If the
     * effect timepoint is 0, then the pending value should not be considered.
     */
    function getFull(Delay self) internal view returns (uint32, uint32, uint48) {
        return _getFullAt(self, timestamp());
    }

    /**
     * @dev Get the current value.
     */
    function get(Delay self) internal view returns (uint32) {
        (uint32 delay, , ) = self.getFull();
        return delay;
    }

    /**
     * @dev Update a Delay object so that it takes a new duration after a timepoint that is automatically computed to
     * enforce the old delay at the moment of the update. Returns the updated Delay object and the timestamp when the
     * new delay becomes effective.
     */
    function withUpdate(
        Delay self,
        uint32 newValue,
        uint32 minSetback
    ) internal view returns (Delay updatedDelay, uint48 effect) {
        uint32 value = self.get();
        uint32 setback = uint32(Math.max(minSetback, value > newValue ? value - newValue : 0));
        effect = timestamp() + setback;
        return (pack(value, newValue, effect), effect);
    }

    /**
     * @dev Split a delay into its components: valueBefore, valueAfter and effect (transition timepoint).
     */
    function unpack(Delay self) internal pure returns (uint32 valueBefore, uint32 valueAfter, uint48 effect) {
        uint112 raw = Delay.unwrap(self);

        valueAfter = uint32(raw);
        valueBefore = uint32(raw >> 32);
        effect = uint48(raw >> 64);

        return (valueBefore, valueAfter, effect);
    }

    /**
     * @dev pack the components into a Delay object.
     */
    function pack(uint32 valueBefore, uint32 valueAfter, uint48 effect) internal pure returns (Delay) {
        return Delay.wrap((uint112(effect) << 64) | (uint112(valueBefore) << 32) | uint112(valueAfter));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ======================= STRUCTS ========================= */

  struct Borrower {
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalBorrows() external view returns (uint256);
  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPRPerBorrower(address borrower) external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function approvedBorrower(address borrower) external view returns (bool);
  function approvedBorrowers() external view returns (address[] memory);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(
    address borrower,
    InterestRate memory newInterestRate
  ) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyPause() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateMaxInterestRate(
    address borrower,
    InterestRate memory newMaxInterestRate
  ) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function updateTokenToDenominatorToken(address token, address dt) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXOracle {
  struct MarketPoolValueInfoProps {
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

  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) external view returns (uint256);

  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) external view returns (uint256);

  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (
    int256,
    MarketPoolValueInfoProps memory
  );

  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDeposit {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account depositing liquidity
  // @param receiver the address to send the liquidity tokens to
  // @param callbackContract the callback contract
  // @param uiFeeReceiver the ui fee receiver
  // @param market the market to deposit to
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param initialLongTokenAmount the amount of long tokens to deposit
  // @param initialShortTokenAmount the amount of short tokens to deposit
  // @param minMarketTokens the minimum acceptable number of liquidity tokens
  // @param updatedAtBlock the block that the deposit was last updated at
  // sending funds back to the user in case the deposit gets cancelled
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  struct Numbers {
    uint256 initialLongTokenAmount;
    uint256 initialShortTokenAmount;
    uint256 minMarketTokens;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IEvent {
  struct Props {
    AddressItems addressItems;
    UintItems uintItems;
    IntItems intItems;
    BoolItems boolItems;
    Bytes32Items bytes32Items;
    BytesItems bytesItems;
    StringItems stringItems;
  }

  struct AddressItems {
    AddressKeyValue[] items;
    AddressArrayKeyValue[] arrayItems;
  }

  struct UintItems {
    UintKeyValue[] items;
    UintArrayKeyValue[] arrayItems;
  }

  struct IntItems {
    IntKeyValue[] items;
    IntArrayKeyValue[] arrayItems;
  }

  struct BoolItems {
    BoolKeyValue[] items;
    BoolArrayKeyValue[] arrayItems;
  }

  struct Bytes32Items {
    Bytes32KeyValue[] items;
    Bytes32ArrayKeyValue[] arrayItems;
  }

  struct BytesItems {
    BytesKeyValue[] items;
    BytesArrayKeyValue[] arrayItems;
  }

  struct StringItems {
    StringKeyValue[] items;
    StringArrayKeyValue[] arrayItems;
  }

  struct AddressKeyValue {
    string key;
    address value;
  }

  struct AddressArrayKeyValue {
    string key;
    address[] value;
  }

  struct UintKeyValue {
    string key;
    uint256 value;
  }

  struct UintArrayKeyValue {
    string key;
    uint256[] value;
  }

  struct IntKeyValue {
    string key;
    int256 value;
  }

  struct IntArrayKeyValue {
    string key;
    int256[] value;
  }

  struct BoolKeyValue {
    string key;
    bool value;
  }

  struct BoolArrayKeyValue {
    string key;
    bool[] value;
  }

  struct Bytes32KeyValue {
    string key;
    bytes32 value;
  }

  struct Bytes32ArrayKeyValue {
    string key;
    bytes32[] value;
  }

  struct BytesKeyValue {
    string key;
    bytes value;
  }

  struct BytesArrayKeyValue {
    string key;
    bytes[] value;
  }

  struct StringKeyValue {
    string key;
    string value;
  }

  struct StringArrayKeyValue {
    string key;
    string[] value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IExchangeRouter {
  struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
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

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(
    address token,
    address receiver,
    uint256 amount
  ) external payable;

  function createDeposit(
    CreateDepositParams calldata params
  ) external payable returns (bytes32);

  function createWithdrawal(
    CreateWithdrawalParams calldata params
  ) external payable returns (bytes32);

  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);

  // function cancelDeposit(bytes32 key) external payable;

  // function cancelWithdrawal(bytes32 key) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IOrder {
  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
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

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWithdrawal {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account The account to withdraw for.
  // @param receiver The address that will receive the withdrawn tokens.
  // @param callbackContract The contract that will be called back.
  // @param uiFeeReceiver The ui fee receiver.
  // @param market The market on which the withdrawal will be executed.
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
  }

  // @param marketTokenAmount The amount of market tokens that will be withdrawn.
  // @param minLongTokenAmount The minimum amount of long tokens that must be withdrawn.
  // @param minShortTokenAmount The minimum amount of short tokens that must be withdrawn.
  // @param updatedAtBlock The block at which the withdrawal was last updated.
  // @param executionFee The execution fee for the withdrawal.
  // @param callbackGasLimit The gas limit for calling the callback contract.
  struct Numbers {
    uint256 marketTokenAmount;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    uint256 updatedAtBlock;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  // @param shouldUnwrapNativeToken whether to unwrap the native token when
  struct Flags {
    bool shouldUnwrapNativeToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from  "../../../strategy/gmx/GMXTypes.sol";

interface IGMXVault {
  function store() external view returns (GMXTypes.Store memory);
  function deposit(GMXTypes.DepositParams memory dp) external payable;
  function depositNative(GMXTypes.DepositParams memory dp) external payable;
  function processDeposit(uint256 lpAmtReceived) external;
  function processDepositCancellation() external;
  function processDepositFailure(uint256 executionFee) external payable;
  function processDepositFailureLiquidityWithdrawal(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;

  function withdraw(GMXTypes.WithdrawParams memory wp) external payable;
  function processWithdraw(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
  function processWithdrawCancellation() external;
  function processWithdrawFailure(uint256 executionFee) external payable;
  function processWithdrawFailureLiquidityAdded(uint256 lpAmtReceived) external;

  function rebalanceAdd(
    GMXTypes.RebalanceAddParams memory rap
  ) external payable;
  function processRebalanceAdd(uint256 lpAmtReceived) external;
  function processRebalanceAddCancellation() external;

  function rebalanceRemove(
    GMXTypes.RebalanceRemoveParams memory rrp
  ) external payable;
  function processRebalanceRemove(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
  function processRebalanceRemoveCancellation() external;

  function compound(GMXTypes.CompoundParams memory cp) external payable;
  function processCompound(uint256 lpAmtReceived) external;
  function processCompoundCancellation() external;

  function emergencyPause() external;
  function emergencyRepay() external payable;
  function processEmergencyRepay(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
  function emergencyBorrow() external;
  function emergencyResume() external payable;
  function processEmergencyResume(uint256 lpAmtReceived) external;
  function processEmergencyResumeCancellation() external;
  function emergencyClose() external;
  function emergencyWithdraw(uint256 shareAmt) external;
  function emergencyStatusChange(GMXTypes.Status status) external;

  function updateTreasury(address treasury) external;
  function updateSwapRouter(address swapRouter) external;
  function updateLendingVaults(
    address newTokenALendingVault,
    address newTokenBLendingVault
  ) external;
  function updateCallback(address callback) external;
  function updateFeePerSecond(uint256 feePerSecond) external;
  function updateParameterLimits(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;
  function updateMinVaultSlippage(uint256 minVaultSlippage) external;
  function updateLiquiditySlippage(uint256 liquiditySlippage) external;
  function updateSwapSlippage(uint256 swapSlippage) external;
  function updateCallbackGasLimit(uint256 callbackGasLimit) external;
  function updateChainlinkOracle(address addr) external;
  function updateGMXOracle(address addr) external;
  function updateGMXExchangeRouter(address addr) external;
  function updateGMXRouter(address addr) external;
  function updateGMXDepositVault(address addr) external;
  function updateGMXWithdrawalVault(address addr) external;
  function updateGMXRoleStore(address addr) external;
  function updateMinAssetValue(uint256 value) external;
  function updateMaxAssetValue(uint256 value) external;

  function mintFee() external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;

  function emitProcessEvent(
    GMXTypes.CallbackType callbackType,
    bytes32 depositKey,
    bytes32 withdrawKey,
    uint256 lpAmtReceived,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXVaultEvents {

  /* ======================== EVENTS ========================= */

  event FeeMinted(uint256 fee);
  event BlocklistUpdated(address addr, bool blocked);
  event TreasuryUpdated(address treasury);
  event SwapRouterUpdated(address router);
  event RewardTokenUpdated(address rewardToken);
  event LendingVaultsUpdated(
    address newTokenALendingVault,
    address newTokenBLendingVault
  );
  event CallbackUpdated(address callback);
  event FeePerSecondUpdated(uint256 feePerSecond);
  event ParameterLimitsUpdated(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  );
  event MinVaultSlippageUpdated(uint256 minVaultSlippage);
  event LiquiditySlippageUpdated(uint256 liquiditySlippage);
  event SwapSlippageUpdated(uint256 swapSlippage);
  event CallbackGasLimitUpdated(uint256 callbackGasLimit);
  event ChainlinkOracleUpdated(address addr);
  event GMXOracleUpdated(address addr);
  event GMXExchangeRouterUpdated(address addr);
  event GMXRouterUpdated(address addr);
  event GMXDepositVaultUpdated(address addr);
  event GMXWithdrawalVaultUpdated(address addr);
  event GMXRoleStoreUpdated(address addr);
  event MinAssetValueUpdated(uint256 value);
  event MaxAssetValueUpdated(uint256 value);

  event DepositCreated(
    address indexed user,
    address asset,
    uint256 assetAmt
  );
  event DepositCompleted(
    address indexed user,
    uint256 shareAmt,
    uint256 equityBefore,
    uint256 equityAfter
  );
  event DepositCancelled(
    address indexed user
  );
  event DepositFailed(bytes reason);
  event DepositFailureProcessed();
  event DepositFailureLiquidityWithdrawalProcessed();

  event WithdrawCreated(address indexed user, uint256 shareAmt);
  event WithdrawCompleted(
    address indexed user,
    address token,
    uint256 tokenAmt
  );
  event WithdrawCancelled(address indexed user);
  event WithdrawFailed(bytes reason);
  event WithdrawFailureProcessed();
  event WithdrawFailureLiquidityAddedProcessed();

  event BorrowSuccess(uint256 borrowTokenAAmt, uint256 borrowTokenBAmt);
  event RepaySuccess(uint256 repayTokenAAmt, uint256 repayTokenBAmt);

  event RebalanceAdded(
    uint rebalanceType,
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  );
  event RebalanceAddProcessed();
  event RebalanceRemoved(
    uint rebalanceType,
    uint256 lpAmtToRemove
  );
  event RebalanceRemoveProcessed();
  event RebalanceSuccess(
    uint256 svTokenValueBefore,
    uint256 svTokenValueAfter
  );
  event RebalanceOpen(
    bytes reason,
    uint256 svTokenValueBefore,
    uint256 svTokenValueAfter
  );
  event RebalanceCancelled();

  event CompoundCompleted();
  event CompoundCancelled();

  event LiquidityAdded(uint256 tokenAAmt, uint256 tokenBAmt);
  event LiquidityRemoved(uint256 lpAmt);
  event ExactTokensForTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );
  event TokensForExactTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );

  event EmergencyPaused();
  event EmergencyRepaid(
    uint256 repayTokenAAmt,
    uint256 repayTokenBAmt
  );
  event EmergencyBorrowed(
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  );
  event EmergencyResumed();
  event EmergencyResumedCancelled();
  event EmergencyClosed();
  event EmergencyWithdraw(
    address indexed user,
    uint256 sharesAmt,
    address assetA,
    uint256 assetAAmt,
    address assetB,
    uint256 assetBAmt,
    address rewardToken,
    uint256 rewardTokenAmt
  );
  event EmergencyStatusChanged(uint256 status);

  /* ==================== CALLBACK EVENTS ==================== */

  event ProcessDeposit(
    bytes32 depositKey,
    uint256 lpAmtReceived
  );
  event ProcessRebalanceAdd(
    bytes32 depositKey,
    uint256 lpAmtReceived
  );
  event ProcessCompound(
    bytes32 depositKey,
    uint256 lpAmtReceived
  );
  event ProcessWithdrawFailureLiquidityAdded(
    bytes32 depositKey,
    uint256 lpAmtReceived
  );
  event ProcessEmergencyResume(
    bytes32 depositKey,
    uint256 lpAmtReceived
  );
  event ProcessDepositCancellation(bytes32 depositKey);
  event ProcessRebalanceAddCancellation(bytes32 depositKey);
  event ProcessCompoundCancellation(bytes32 depositKey);
  event ProcessEmergencyResumeCancellation(bytes32 depositKey);

  event ProcessWithdraw(
    bytes32 withdrawKey,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  );
  event ProcessRebalanceRemove(
    bytes32 withdrawKey,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  );
  event ProcessDepositFailureLiquidityWithdrawal(
    bytes32 withdrawKey,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  );
  event ProcessEmergencyRepay(
    bytes32 withdrawKey,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  );
  event ProcessWithdrawCancellation(bytes32 withdrawKey);
  event ProcessRebalanceRemoveCancellation(bytes32 withdrawKey);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISwap {
  struct SwapParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in; in token decimals
    uint256 amountIn;
    // Amount of token out; in token decimals
    uint256 amountOut;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // Swap deadline timestamp
    uint256 deadline;
  }

  function swapExactTokensForTokens(
    SwapParams memory sp
  ) external returns (uint256);

  function swapTokensForExactTokens(
    SwapParams memory sp
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { Errors } from "../../utils/Errors.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";

/**
  * @title GMXChecks
  * @author Steadefi
  * @notice Re-usable library functions for require function checks for Steadefi leveraged vaults
*/
library GMXChecks {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Checks before native token deposit
    * @param self GMXTypes.Store
    * @param dp GMXTypes.DepositParams
  */
  function beforeNativeDepositChecks(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp
  ) external view {
    if (dp.token != address(self.WNT))
      revert Errors.InvalidNativeTokenAddress();

    if (
      address(self.tokenA) != address(self.WNT) &&
      address(self.tokenB) != address(self.WNT)
    ) revert Errors.OnlyNonNativeDepositToken();

    if (dp.amt == 0) revert Errors.EmptyDepositAmount();

    if (dp.amt + dp.executionFee != msg.value)
      revert Errors.DepositAndExecutionFeeDoesNotMatchMsgValue();
  }

  /**
    * @notice Checks before token deposit
    * @param self GMXTypes.Store
    * @param depositValue USD value in 1e18
  */
  function beforeDepositChecks(
    GMXTypes.Store storage self,
    uint256 depositValue
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      self.depositCache.depositParams.token != address(self.tokenA) &&
      self.depositCache.depositParams.token != address(self.tokenB) &&
      self.depositCache.depositParams.token != address(self.lpToken)
    ) {
      revert Errors.InvalidDepositToken();
    }

    if (self.depositCache.depositParams.amt == 0)
      revert Errors.InsufficientDepositAmount();

    if (self.depositCache.depositParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();

    if (depositValue == 0)
      revert Errors.InsufficientDepositValue();

    if (depositValue < self.minAssetValue)
      revert Errors.InsufficientDepositValue();

    if (depositValue > self.maxAssetValue)
      revert Errors.ExcessiveDepositValue();

    if (depositValue > GMXReader.additionalCapacity(self))
      revert Errors.InsufficientLendingLiquidity();

    if (GMXReader.equityValue(self) == 0 && IERC20(address(self.vault)).totalSupply() > 0)
      revert Errors.DepositNotAllowedWhenEquityIsZero();
  }

  /**
    * @notice Checks before processing deposit
    * @param self GMXTypes.Store
  */
  function beforeProcessDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after deposit
    * @param self GMXTypes.Store
  */
  function afterDepositChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: revert if lpAmt did not increase at all
    if (GMXReader.lpAmt(self) <= self.depositCache.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensMinted();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.depositCache.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Slippage: Check whether user received enough shares as expected
    if (self.depositCache.sharesToUser < self.depositCache.minSharesAmt)
      revert Errors.InsufficientSharesMinted();
  }

  /**
    * @notice Checks before processing deposit cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessDepositCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit check failure
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after deposit failure's liquidity withdrawn
    * @param self GMXTypes.Store
  */
  function beforeProcessAfterDepositFailureLiquidityWithdrawal(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Deposit_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before vault withdrawal
    * @param self GMXTypes.Store

  */
  function beforeWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    // TODO: how to handle tokens to withdraw
    if (
      self.withdrawCache.withdrawParams.token != address(self.tokenA) &&
      self.withdrawCache.withdrawParams.token != address(self.tokenB)
    ) {
      revert Errors.InvalidWithdrawToken();
    }

    if (self.withdrawCache.withdrawParams.shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (
      self.withdrawCache.withdrawParams.shareAmt >
      IERC20(address(self.vault)).balanceOf(self.withdrawCache.user)
    ) revert Errors.InsufficientWithdrawBalance();

    if (self.withdrawCache.withdrawValue > self.maxAssetValue)
      revert Errors.ExcessiveWithdrawValue();

    if (self.withdrawCache.withdrawParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();

    if (self.withdrawCache.withdrawParams.executionFee != msg.value)
      revert Errors.InvalidExecutionFeeAmount();
  }

  /**
    * @notice Checks before processing vault withdrawal
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after token withdrawal
    * @param self GMXTypes.Store
  */
  function afterWithdrawChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: revert if lpAmt did not decrease at all
    if (GMXReader.lpAmt(self) >= self.withdrawCache.healthParams.lpAmtBefore)
      revert Errors.InsufficientLPTokensBurned();

    // Guards: revert if equity did not decrease at all
    if (
      self.withdrawCache.healthParams.equityAfter >=
      self.withdrawCache.healthParams.equityBefore
    ) revert Errors.InvalidEquityAfterWithdraw();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.withdrawCache.healthParams.debtRatioBefore,
      GMXReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Check that user received enough assets as expected
    if (self.withdrawCache.assetsToUser < self.withdrawCache.minAssetsAmt)
      revert Errors.InsufficientAssetsReceived();
  }

  /**
    * @notice Checks before processing withdrawal cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after withdrawal failure
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawFailureChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing after withdraw failure's liquidity added
    * @param self GMXTypes.Store
  */
  function beforeProcessWithdrawFailureLiquidityAdded(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Withdraw_Failed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before rebalancing
    * @param self GMXTypes.Store
    * @param rebalanceType GMXTypes.RebalanceType
  */
  function beforeRebalanceChecks(
    GMXTypes.Store storage self,
    GMXTypes.RebalanceType rebalanceType
  ) external view {
    if (
      self.status != GMXTypes.Status.Open &&
      self.status != GMXTypes.Status.Rebalance_Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    // Check that rebalance type is Delta or Debt
    // And then check that rebalance conditions are met
    // Note that Delta rebalancing requires vault's delta strategy to be Neutral as well
    if (rebalanceType == GMXTypes.RebalanceType.Delta && self.delta == GMXTypes.Delta.Neutral) {
      if (
        self.rebalanceCache.healthParams.deltaBefore <= self.deltaUpperLimit &&
        self.rebalanceCache.healthParams.deltaBefore >= self.deltaLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else if (rebalanceType == GMXTypes.RebalanceType.Debt) {
      if (
        self.rebalanceCache.healthParams.debtRatioBefore <= self.debtRatioUpperLimit &&
        self.rebalanceCache.healthParams.debtRatioBefore >= self.debtRatioLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else {
       revert Errors.InvalidRebalanceParameters();
    }
  }

  /**
    * @notice Checks before processing of rebalancing add or remove
    * @param self GMXTypes.Store
  */
  function beforeProcessRebalanceChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status != GMXTypes.Status.Rebalance_Add &&
      self.status != GMXTypes.Status.Rebalance_Remove
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks after rebalancing add or remove
    * @param self GMXTypes.Store
  */
  function afterRebalanceChecks(
    GMXTypes.Store storage self
  ) external view {
    // Guards: check that delta is within limits for Neutral strategy
    if (self.delta == GMXTypes.Delta.Neutral) {
      int256 _delta = GMXReader.delta(self);

      if (
        _delta > self.deltaUpperLimit ||
        _delta < self.deltaLowerLimit
      ) revert Errors.InvalidDelta();
    }

    // Guards: check that debt is within limits for Long/Neutral strategy
    uint256 _debtRatio = GMXReader.debtRatio(self);

    if (
      _debtRatio > self.debtRatioUpperLimit ||
      _debtRatio < self.debtRatioLowerLimit
    ) revert Errors.InvalidDebtRatio();
  }

  /**
    * @notice Checks before compound
    * @param self GMXTypes.Store
  */
  function beforeCompoundChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status != GMXTypes.Status.Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    if (self.compoundCache.depositValue == 0)
      revert Errors.InsufficientDepositAmount();
  }

  /**
    * @notice Checks before processing compound
    * @param self GMXTypes.Store
  */
  function beforeProcessCompoundChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Compound)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing compound cancellation
    * @param self GMXTypes.Store
  */
  function beforeProcessCompoundCancellationChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Compound)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency pausing of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyPauseChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status == GMXTypes.Status.Paused ||
      self.status == GMXTypes.Status.Resume ||
      self.status == GMXTypes.Status.Repaid ||
      self.status == GMXTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency repaying of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyRepayChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing emergency pausing of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyRepayChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repay)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency re-borrowing assets of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyBorrowChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before resuming vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyResumeChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing resuming of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyResumeChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Resume)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before processing resume cancellation of vault
    * @param self GMXTypes.Store
  */
  function beforeProcessEmergencyResumeCancellationChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Resume)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency closure of vault
    * @param self GMXTypes.Store
  */
  function beforeEmergencyCloseChecks (
    GMXTypes.Store storage self
  ) external view {
    if (self.status != GMXTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before a withdrawal during emergency closure
    * @param self GMXTypes.Store
    * @param shareAmt Amount of shares to burn
  */
  function beforeEmergencyWithdrawChecks(
    GMXTypes.Store storage self,
    uint256 shareAmt
  ) external view {
    if (self.status != GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (shareAmt > IERC20(address(self.vault)).balanceOf(msg.sender))
      revert Errors.InsufficientWithdrawBalance();
  }

  /**
    * @notice Checks before emergency status change
    * @param self GMXTypes.Store
  */
  function beforeEmergencyStatusChangeChecks(
    GMXTypes.Store storage self
  ) external view {
    if (
      self.status == GMXTypes.Status.Open ||
      self.status == GMXTypes.Status.Deposit ||
      self.status == GMXTypes.Status.Withdraw ||
      self.status == GMXTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before shares are minted
    * @param self GMXTypes.Store
  */
  function beforeMintFeeChecks(
    GMXTypes.Store storage self
  ) external view {
    if (self.status == GMXTypes.Status.Paused || self.status == GMXTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Check if values are within threshold range
    * @param valueBefore Previous value
    * @param valueAfter New value
    * @param threshold Tolerance threshold; 100 = 1%
    * @return boolean Whether value after is within threshold range
  */
  function _isWithinStepChange(
    uint256 valueBefore,
    uint256 valueAfter,
    uint256 threshold
  ) internal pure returns (bool) {
    // To bypass initial vault deposit
    if (valueBefore == 0)
      return true;

    return (
      valueAfter >= valueBefore * (10000 - threshold) / 10000 &&
      valueAfter <= valueBefore * (10000 + threshold) / 10000
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXEmergency } from "./GMXEmergency.sol";

/**
  * @title GMXCompound
  * @author Steadefi
  * @notice Re-usable library functions for compound operations for Steadefi leveraged vaults
*/
library GMXCompound {
  using SafeERC20 for IERC20;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event CompoundCompleted();
  event CompoundCancelled();

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function compound(
    GMXTypes.Store storage self,
    GMXTypes.CompoundParams memory cp
  ) external {
    self.refundee = payable(msg.sender);

    self.compoundCache.compoundParams = cp;

    ISwap.SwapParams memory _sp;

    _sp.tokenIn = cp.tokenIn;
    _sp.tokenOut = cp.tokenOut;
    _sp.amountIn = cp.amtIn;
    _sp.amountOut = 0; // amount out minimum calculated in Swap
    _sp.slippage = self.swapSlippage;
    _sp.deadline = cp.deadline;

    uint256 _amountOut = GMXManager.swapExactTokensForTokens(self, _sp);

    GMXTypes.AddLiquidityParams memory _alp;

    if (cp.tokenOut == address(self.tokenA)) {
      _alp.tokenAAmt = _amountOut;
    } else if (cp.tokenOut == address(self.tokenB)) {
      _alp.tokenBAmt = _amountOut;
    }

    // Only add liquidity if tokenA/B is more than 0
    if (_alp.tokenAAmt > 0 || _alp.tokenBAmt > 0) {
      if (_alp.tokenAAmt > 0) {
        self.compoundCache.depositValue = GMXReader.convertToUsdValue(
          self,
          address(self.tokenA),
          _alp.tokenAAmt
        );
      } else if (_alp.tokenBAmt > 0) {
        self.compoundCache.depositValue = GMXReader.convertToUsdValue(
          self,
          address(self.tokenB),
          _alp.tokenBAmt
        );
      }

      GMXChecks.beforeCompoundChecks(self);

      self.status = GMXTypes.Status.Compound;

      _alp.minMarketTokenAmt = GMXManager.calcMinMarketSlippageAmt(
        self,
        self.compoundCache.depositValue,
        self.liquiditySlippage
      );

      _alp.executionFee = cp.executionFee;

      self.compoundCache.depositKey = GMXManager.addLiquidity(
        self,
        _alp
      );
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processCompound(
    GMXTypes.Store storage self,
    uint256 lpAmtReceived
  ) external {
    GMXChecks.beforeProcessCompoundChecks(self);

    self.lpAmt += lpAmtReceived;

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit CompoundCompleted();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processCompoundCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessCompoundCancellationChecks(self);

    self.status = GMXTypes.Status.Open;

    emit CompoundCancelled();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IDeposit } from "../../interfaces/protocols/gmx/IDeposit.sol";
import { IWithdrawal } from "../../interfaces/protocols/gmx/IWithdrawal.sol";
import { IEvent } from "../../interfaces/protocols/gmx/IEvent.sol";
import { IOrder } from "../../interfaces/protocols/gmx/IOrder.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";
import { GMXProcessDeposit } from "./GMXProcessDeposit.sol";
import { GMXEmergency } from "./GMXEmergency.sol";

/**
  * @title GMXDeposit
  * @author Steadefi
  * @notice Re-usable library functions for deposit operations for Steadefi leveraged vaults
*/
library GMXDeposit {

  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  /* ======================= CONSTANTS ======================= */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event DepositCreated(
    address indexed user,
    address asset,
    uint256 assetAmt
  );
  event DepositCompleted(
    address indexed user,
    uint256 shareAmt,
    uint256 equityBefore,
    uint256 equityAfter
  );
  event DepositCancelled(
    address indexed user
  );
  event DepositFailed(bytes reason);
  event DepositFailureProcessed();
  event DepositFailureLiquidityWithdrawalProcessed();

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
    * @param isNative Boolean as to whether user is depositing native asset (e.g. ETH, AVAX, etc.)
  */
  function deposit(
    GMXTypes.Store storage self,
    GMXTypes.DepositParams memory dp,
    bool isNative
  ) external {
    self.refundee = payable(msg.sender);

    // Capture vault parameters before deposit
    GMXTypes.HealthParams memory _hp;

    _hp.lpAmtBefore = GMXReader.lpAmt(self);
    (_hp.tokenAAssetAmtBefore, _hp.tokenBAssetAmtBefore) = GMXReader.assetAmt(self);

    // Transfer assets from user to vault
    if (isNative) {
      GMXChecks.beforeNativeDepositChecks(self, dp);

      self.WNT.deposit{ value: dp.amt }();
    } else {
      IERC20(dp.token).safeTransferFrom(msg.sender, address(this), dp.amt);
    }

    GMXTypes.DepositCache memory _dc;

    _dc.user = payable(msg.sender);

    if (dp.token == address(self.lpToken)) {
      // If LP token deposited
      _dc.depositValue = self.gmxOracle.getLpTokenValue(
        address(self.lpToken),
        address(self.tokenA),
        address(self.tokenA),
        address(self.tokenB),
        true,
        false
      )
      * dp.amt
      / SAFE_MULTIPLIER;
    } else {
      // If tokenA or tokenB deposited
      _dc.depositValue = GMXReader.convertToUsdValue(
        self,
        address(dp.token),
        dp.amt
      );
    }
    _dc.depositParams = dp;
    _dc.healthParams = _hp;

    self.depositCache = _dc;

    GMXChecks.beforeDepositChecks(self, _dc.depositValue);

    // Calculate minimum amount of shares expected based on deposit value
    // and vault slippage value passed in and current equityValue.
    // We calculate this after `beforeDepositChecks()`
    // to ensure the vault slippage passed in meets the `minVaultSlippage`
    _dc.minSharesAmt = GMXReader.valueToShares(
      self,
      _dc.depositValue,
      GMXReader.equityValue(self)
    ) * (10000 - dp.slippage) / 10000;

    self.status = GMXTypes.Status.Deposit;

    // Borrow assets and create deposit in GMX
    (
      uint256 _borrowTokenAAmt,
      uint256 _borrowTokenBAmt
    ) = GMXManager.calcBorrow(self, _dc.depositValue);

    _dc.borrowParams.borrowTokenAAmt = _borrowTokenAAmt;
    _dc.borrowParams.borrowTokenBAmt = _borrowTokenBAmt;

    GMXManager.borrow(self, _borrowTokenAAmt, _borrowTokenBAmt);

    GMXTypes.AddLiquidityParams memory _alp;

    if (dp.token == address(self.tokenA)) {
      _alp.tokenAAmt = dp.amt + _borrowTokenAAmt;
    } else {
      _alp.tokenAAmt = _borrowTokenAAmt;
    }
    if (dp.token == address(self.tokenB)) {
      _alp.tokenBAmt = dp.amt + _borrowTokenBAmt;
    } else {
      _alp.tokenBAmt = _borrowTokenBAmt;
    }

    // Get deposit value of all tokenA/B in vault that will be added to GMX as liquidity
    // Note that this is slightly different from the user's depositValue calculated above, as
    // the user may have deposited LP tokens, which are NOT re-deposited to GMX, and as such
    // we should not include that as part of this deposit value as slippage
    uint256 _depositValueForAddingLiquidity = GMXReader.convertToUsdValue(
      self,
      address(self.tokenA),
      _alp.tokenAAmt
    ) + GMXReader.convertToUsdValue(
      self,
      address(self.tokenB),
      _alp.tokenBAmt
    );

    _alp.minMarketTokenAmt = GMXManager.calcMinMarketSlippageAmt(
      self,
      _depositValueForAddingLiquidity,
      self.liquiditySlippage
    );
    _alp.executionFee = dp.executionFee;

    _dc.depositKey = GMXManager.addLiquidity(
      self,
      _alp
    );

    self.depositCache = _dc;

    emit DepositCreated(
      _dc.user,
      _dc.depositParams.token,
      _dc.depositParams.amt
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processDeposit(
    GMXTypes.Store storage self,
    uint256 lpAmtReceived
  ) external {
    GMXChecks.beforeProcessDepositChecks(self);

    GMXTypes.DepositCache memory _dc = self.depositCache;
    GMXTypes.HealthParams memory _hp = _dc.healthParams;

    // Compute asset value of vault before deposit
    uint256 _assetValueBefore = _hp.lpAmtBefore
      * self.gmxOracle.getLpTokenValue(
        address(self.lpToken),
        address(self.tokenA),
        address(self.tokenA),
        address(self.tokenB),
        true,
        false
      ) / SAFE_MULTIPLIER;

    // Compute equity, debtRatio and delta of vault before deposit
    if (_assetValueBefore > 0) {
      // Use existing tokens debt amount subtracting borrowed tokens amt
      // to properly account for accrued interest of past borrows
      (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = GMXReader.debtAmt(self);

      _hp.tokenADebtAmtBefore = _tokenADebtAmt - _dc.borrowParams.borrowTokenAAmt;
      _hp.tokenBDebtAmtBefore = _tokenBDebtAmt - _dc.borrowParams.borrowTokenBAmt;

      uint256 _debtValueBefore = GMXReader.convertToUsdValue(
        self,
        address(self.tokenA),
        _hp.tokenADebtAmtBefore
      )
      + GMXReader.convertToUsdValue(
        self,
        address(self.tokenB),
        _hp.tokenBDebtAmtBefore
      );

      _hp.equityBefore = _assetValueBefore - _debtValueBefore;

      _hp.debtRatioBefore = _debtValueBefore
        * SAFE_MULTIPLIER
        / _assetValueBefore;

      if (_hp.tokenAAssetAmtBefore == 0 &&  _hp.tokenADebtAmtBefore == 0) {
        _hp.deltaBefore = 0;
      } else {
        bool _isPositive = _hp.tokenAAssetAmtBefore >= _hp.tokenADebtAmtBefore;

        uint256 _unsignedDelta = _isPositive ?
          _hp.tokenAAssetAmtBefore - _hp.tokenADebtAmtBefore :
          _hp.tokenADebtAmtBefore - _hp.tokenAAssetAmtBefore;

        int256 signedDelta = (_unsignedDelta
          * self.chainlinkOracle.consultIn18Decimals(address(self.tokenA))
          / _hp.equityBefore).toInt256();

        _hp.deltaBefore = _isPositive ? signedDelta : -signedDelta;
      }
    } else {
      _hp.equityBefore = 0;
      _hp.debtRatioBefore = 0;
      _hp.deltaBefore = 0;
    }

    self.depositCache.healthParams = _hp;

    // Process deposit with new LP toens received
    self.depositCache.lpAmtReceived = lpAmtReceived;

    // Account LP tokens received to vault
    self.lpAmt += lpAmtReceived;

    if (self.depositCache.depositParams.token == address(self.lpToken))
      self.lpAmt += self.depositCache.depositParams.amt;

    // Store equityAfter and shareToUser values in DepositCache
    self.depositCache.healthParams.equityAfter = GMXReader.equityValue(self);

    // Compute how many svTokens to mint to depositor
    self.depositCache.sharesToUser = GMXReader.valueToShares(
      self,
      self.depositCache.healthParams.equityAfter - _hp.equityBefore,
      _hp.equityBefore
    );

    // We transfer the logic of afterDepositChecks to GMXProcessDeposit.processDeposit()
    // to allow try/catch here to catch for afterDepositChecks() failing.
    // If there are any issues, a DepositFailed event will be emitted and
    // processDepositFailure() should be triggered.
    try GMXProcessDeposit.processDeposit(self) {
      self.vault.mintFee();
      // Mint shares to depositor
      self.vault.mint(self.depositCache.user, self.depositCache.sharesToUser);

      self.status = GMXTypes.Status.Open;

      // Check if there is an emergency pause queued
      if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

      emit DepositCompleted(
        self.depositCache.user,
        self.depositCache.sharesToUser,
        self.depositCache.healthParams.equityBefore,
        self.depositCache.healthParams.equityAfter
      );
    } catch (bytes memory reason) {
      self.status = GMXTypes.Status.Deposit_Failed;

      emit DepositFailed(reason);
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processDepositCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessDepositCancellationChecks(self);

    // Repay borrowed assets
    GMXManager.repay(
      self,
      self.depositCache.borrowParams.borrowTokenAAmt,
      self.depositCache.borrowParams.borrowTokenBAmt
    );

    // Return user's deposited asset
    // If native token is being withdrawn, we convert wrapped to native
    if (self.depositCache.depositParams.token == address(self.WNT)) {
      self.WNT.withdraw(self.depositCache.depositParams.amt);
      (bool success, ) = self.depositCache.user.call{
        value: self.depositCache.depositParams.amt
      }("");
      // if native transfer unsuccessful, send WNT back to user
      if (!success) {
        self.WNT.deposit{value: self.depositCache.depositParams.amt}();
        IERC20(address(self.WNT)).safeTransfer(
          self.withdrawCache.user,
          self.depositCache.depositParams.amt
        );
      }
    } else {
      // Transfer requested withdraw asset to user
      IERC20(self.depositCache.depositParams.token).safeTransfer(
        self.depositCache.user,
        self.depositCache.depositParams.amt
      );
    }

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit DepositCancelled(self.depositCache.user);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processDepositFailure(
    GMXTypes.Store storage self,
    uint256 executionFee
  ) external {
    GMXChecks.beforeProcessAfterDepositFailureChecks(self);

    self.refundee = payable(msg.sender);

    GMXTypes.RemoveLiquidityParams memory _rlp;

    // Remove amount of LP that was received
    _rlp.lpAmt = self.depositCache.lpAmtReceived;

    // Account for the vault's LP tokens
    self.lpAmt -= self.depositCache.lpAmtReceived;

    // If user deposited LP tokens as well, to standardize the flow, we will also add it
    // to the LP amount to be withdrawn and account for vault's LP tokens
    if (self.depositCache.depositParams.token == address(self.lpToken)) {
      _rlp.lpAmt += self.depositCache.depositParams.amt;
      self.lpAmt -= self.depositCache.depositParams.amt;
    }

    if (self.delta == GMXTypes.Delta.Long) {
      // If delta strategy is Long, remove all in tokenB to make it more
      // efficent to repay tokenB debt as Long strategy only borrows tokenB
      address[] memory _tokenASwapPath = new address[](1);
      _tokenASwapPath[0] = address(self.lpToken);
      _rlp.tokenASwapPath = _tokenASwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenB),
        address(self.tokenB),
        self.liquiditySlippage
      );
    } else if (self.delta == GMXTypes.Delta.Short) {
      // If delta strategy is Short, remove all in tokenA to make it more
      // efficent to repay tokenA debt as Short strategy only borrows tokenA
      address[] memory _tokenBSwapPath = new address[](1);
      _tokenBSwapPath[0] = address(self.lpToken);
      _rlp.tokenBSwapPath = _tokenBSwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenA),
        address(self.tokenA),
        self.liquiditySlippage
      );
    } else {
      // If delta strategy is Neutral, withdraw in both tokenA/B
      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenA),
        address(self.tokenB),
        self.liquiditySlippage
      );
    }

    _rlp.executionFee = executionFee;

    // Remove liquidity
    self.depositCache.withdrawKey = GMXManager.removeLiquidity(
      self,
      _rlp
    );

    emit DepositFailureProcessed();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processDepositFailureLiquidityWithdrawal(
    GMXTypes.Store storage self,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) public {
    GMXChecks.beforeProcessAfterDepositFailureLiquidityWithdrawal(self);

    uint256 _tokenAAmtInVault = tokenAReceived;
    uint256 _tokenBAmtInVault = tokenBReceived;

    if (self.delta == GMXTypes.Delta.Long) {
      // We withdraw assets all in tokenB
      _tokenAAmtInVault = 0;
      _tokenBAmtInVault = tokenAReceived + tokenBReceived;
    } else if (self.delta == GMXTypes.Delta.Short) {
      // We withdraw assets all in tokenA
      _tokenAAmtInVault = tokenAReceived + tokenBReceived;
      _tokenBAmtInVault = 0;
    } else {
      // Both tokenA/B amount received are "correct" for their respective tokens
      _tokenAAmtInVault = tokenAReceived;
      _tokenBAmtInVault = tokenBReceived;
    }

    GMXTypes.RepayParams memory _rp;

    _rp.repayTokenAAmt = self.depositCache.borrowParams.borrowTokenAAmt;
    _rp.repayTokenBAmt = self.depositCache.borrowParams.borrowTokenBAmt;

    // Check if swap between assets are needed for repayment based on previous borrow
    (
      bool _swapNeeded,
      address _tokenFrom,
      address _tokenTo,
      uint256 _tokenToAmt
    ) = GMXManager.calcSwapForRepay(
      self,
      _rp,
      _tokenAAmtInVault,
      _tokenBAmtInVault
    );

    if (_swapNeeded) {
      ISwap.SwapParams memory _sp;

      _sp.tokenIn = _tokenFrom;
      _sp.tokenOut = _tokenTo;
      _sp.amountIn = GMXManager.calcAmountInMaximum(
        self,
        _tokenFrom,
        _tokenTo,
        _tokenToAmt
      );
      _sp.amountOut = _tokenToAmt;
      _sp.slippage = self.swapSlippage;
      _sp.deadline = block.timestamp;
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // We allow deadline to be set as the current block timestamp whenever this function
      // is called because this function is triggered as a follow up function (by a callback/keeper)
      // and not directly by a user/keeper. If this follow on function flow reverts due to this tx
      // being processed after a set deadline, this will cause the vault to be in a "stuck" state.
      // To resolve this, this function will have to be called again with an updated deadline until it
      // succeeds/a miner processes the tx.

      uint256 _amountIn = GMXManager.swapTokensForExactTokens(self, _sp);
      if (_tokenFrom == address(self.tokenA)) {
        _tokenAAmtInVault -= _amountIn;
        _tokenBAmtInVault += _tokenToAmt;
      } else if (_tokenFrom == address(self.tokenB)) {
        _tokenBAmtInVault -= _amountIn;
        _tokenAAmtInVault += _tokenToAmt;
      }
    }

    // Adjust amount to repay for both tokens due to slight differences
    // from liqudiity withdrawal and swaps. If the amount to repay based on previous borrow
    // is more than the available balance vault has, we simply repay what the vault has
    uint256 _repayTokenAAmt;
    uint256 _repayTokenBAmt;

    if (self.depositCache.borrowParams.borrowTokenAAmt > _tokenAAmtInVault) {
      _repayTokenAAmt = _tokenAAmtInVault;
    } else {
      _repayTokenAAmt = self.depositCache.borrowParams.borrowTokenAAmt;
    }

    if (self.depositCache.borrowParams.borrowTokenBAmt > _tokenBAmtInVault) {
      _repayTokenBAmt = _tokenBAmtInVault;
    } else {
      _repayTokenBAmt = self.depositCache.borrowParams.borrowTokenBAmt;
    }

    // Repay borrowed assets
    GMXManager.repay(
      self,
      _repayTokenAAmt,
      _repayTokenBAmt
    );

    _tokenAAmtInVault -= _repayTokenAAmt;
    _tokenBAmtInVault -= _repayTokenBAmt;

    // Refund user the rest of the remaining withdrawn assets after repayment
    // Will be in tokenA/tokenB only; so if user deposited LP tokens
    // they will still be refunded in tokenA/tokenB
    self.tokenA.safeTransfer(self.depositCache.user, _tokenAAmtInVault);
    self.tokenB.safeTransfer(self.depositCache.user, _tokenBAmtInVault);

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit DepositFailureLiquidityWithdrawalProcessed();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";

/**
  * @title GMXEmergency
  * @author Steadefi
  * @notice Re-usable library functions for emergency operations for Steadefi leveraged vaults
*/
library GMXEmergency {

  using SafeERC20 for IERC20;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant DUST_AMOUNT = 1e17;

  /* ======================== EVENTS ========================= */

  event EmergencyPaused();
  event EmergencyRepaid(
    uint256 repayTokenAAmt,
    uint256 repayTokenBAmt
  );
  event EmergencyBorrowed(
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  );
  event EmergencyResumed();
  event EmergencyResumedCancelled();
  event EmergencyClosed();
  event EmergencyWithdraw(
    address indexed user,
    uint256 sharesAmt,
    address assetA,
    uint256 assetAAmt,
    address assetB,
    uint256 assetBAmt,
    address rewardToken,
    uint256 rewardTokenAmt
  );
  event EmergencyStatusChanged(uint256 status);

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyPause(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeEmergencyPauseChecks(self);

    if (self.status != GMXTypes.Status.Open) {
      // If vault is processing a tx, set flag to pause after tx is processed
      self.shouldEmergencyPause = true;
    } else {
      self.status = GMXTypes.Status.Paused;

      emit EmergencyPaused();
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyRepay(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeEmergencyRepayChecks(self);

    self.refundee = payable(msg.sender);

    // In most cases, the lpAmt and lpToken balance should be equal
    if (self.lpAmt >= self.lpToken.balanceOf(address(this))) {
      self.lpAmt -= self.lpToken.balanceOf(address(this));
    } else {
      // But in the event that there is more lpTokens added, we set self.lpAmt to 0
      self.lpAmt = 0;
    }

    GMXTypes.RemoveLiquidityParams memory _rlp;

    // Remove all of the vault's LP tokens
    _rlp.lpAmt = self.lpToken.balanceOf(address(this));

    if (self.delta == GMXTypes.Delta.Long) {
      // If delta strategy is Long, remove all in tokenB to make it more
      // efficent to repay tokenB debt as Long strategy only borrows tokenB
      address[] memory _tokenASwapPath = new address[](1);
      _tokenASwapPath[0] = address(self.lpToken);
      _rlp.tokenASwapPath = _tokenASwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenB),
        address(self.tokenB),
        self.liquiditySlippage
      );
    } else if (self.delta == GMXTypes.Delta.Short) {
      // If delta strategy is Short, remove all in tokenA to make it more
      // efficent to repay tokenA debt as Short strategy only borrows tokenA
      address[] memory _tokenBSwapPath = new address[](1);
      _tokenBSwapPath[0] = address(self.lpToken);
      _rlp.tokenBSwapPath = _tokenBSwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenA),
        address(self.tokenA),
        self.liquiditySlippage
      );
    } else {
      // If delta strategy is Neutral, withdraw in both tokenA/B
      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenA),
        address(self.tokenB),
        self.liquiditySlippage
      );
    }

    _rlp.executionFee = msg.value;

    GMXManager.removeLiquidity(
      self,
      _rlp
    );

    self.status = GMXTypes.Status.Repay;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processEmergencyRepay(
    GMXTypes.Store storage self,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external {
    GMXChecks.beforeProcessEmergencyRepayChecks(self);

    uint256 _tokenAAmtInVault = tokenAReceived;
    uint256 _tokenBAmtInVault = tokenBReceived;

    if (self.delta == GMXTypes.Delta.Long) {
      // We withdraw assets all in tokenB
      _tokenAAmtInVault = 0;
      _tokenBAmtInVault = tokenAReceived + tokenBReceived;
    } else if (self.delta == GMXTypes.Delta.Short) {
      // We withdraw assets all in tokenA
      _tokenAAmtInVault = tokenAReceived + tokenBReceived;
      _tokenBAmtInVault = 0;
    } else {
      // Both tokenA/B amount received are "correct" for their respective tokens
      _tokenAAmtInVault = tokenAReceived;
      _tokenBAmtInVault = tokenBReceived;
    }

    // Repay all borrowed assets; 1e18 == 100% shareRatio to repay
    GMXTypes.RepayParams memory _rp;
    (
      _rp.repayTokenAAmt,
      _rp.repayTokenBAmt
    ) = GMXManager.calcRepay(self, 1e18);

    (
      bool _swapNeeded,
      address _tokenFrom,
      address _tokenTo,
      uint256 _tokenToAmt
    ) = GMXManager.calcSwapForRepay(
      self,
      _rp,
      _tokenAAmtInVault,
      _tokenBAmtInVault
    );

    if (_swapNeeded) {
      ISwap.SwapParams memory _sp;

      _sp.tokenIn = _tokenFrom;
      _sp.tokenOut = _tokenTo;
      _sp.amountIn = GMXManager.calcAmountInMaximum(
        self,
        _tokenFrom,
        _tokenTo,
        _tokenToAmt
      );
      _sp.amountOut = _tokenToAmt;
      _sp.slippage = self.swapSlippage;
      _sp.deadline = block.timestamp;
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // We allow deadline to be set as the current block timestamp whenever this function
      // is called because this function is triggered as a follow up function (by a callback/keeper)
      // and not directly by a user/keeper. If this follow on function flow reverts due to this tx
      // being processed after a set deadline, this will cause the vault to be in a "stuck" state.
      // To resolve this, this function will have to be called again with an updated deadline until it
      // succeeds/a miner processes the tx.

      GMXManager.swapTokensForExactTokens(self, _sp);
    }

    // Check for sufficient balance to repay, if not repay balance
    uint256 _tokenABalance = IERC20(self.tokenA).balanceOf(address(self.vault));
    uint256 _tokenBBalance = IERC20(self.tokenB).balanceOf(address(self.vault));

    _rp.repayTokenAAmt = _rp.repayTokenAAmt > _tokenABalance ? _tokenABalance : _rp.repayTokenAAmt;
    _rp.repayTokenBAmt = _rp.repayTokenBAmt > _tokenBBalance ? _tokenBBalance : _rp.repayTokenBAmt;

    GMXManager.repay(
      self,
      _rp.repayTokenAAmt,
      _rp.repayTokenBAmt
    );

    self.status = GMXTypes.Status.Repaid;

    emit EmergencyRepaid(_rp.repayTokenAAmt, _rp.repayTokenBAmt);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyBorrow(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeEmergencyBorrowChecks(self);

    // Re-borrow assets
    uint256 _depositValue = GMXReader.convertToUsdValue(
      self,
      address(self.tokenA),
      self.tokenA.balanceOf(address(this))
    )
    + GMXReader.convertToUsdValue(
      self,
      address(self.tokenB),
      self.tokenB.balanceOf(address(this))
    );

    (
      uint256 _borrowTokenAAmt,
      uint256 _borrowTokenBAmt
    ) = GMXManager.calcBorrow(self, _depositValue);

    GMXManager.borrow(self, _borrowTokenAAmt, _borrowTokenBAmt);

    self.status = GMXTypes.Status.Paused;

    emit EmergencyBorrowed(_borrowTokenAAmt, _borrowTokenBAmt);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyResume(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeEmergencyResumeChecks(self);

    self.shouldEmergencyPause = false;
    self.status = GMXTypes.Status.Resume;
    self.refundee = payable(msg.sender);

    // Add liquidity
    GMXTypes.AddLiquidityParams memory _alp;

    _alp.tokenAAmt = self.tokenA.balanceOf(address(this));
    _alp.tokenBAmt = self.tokenB.balanceOf(address(this));

    // Get deposit value of all tokens in vault
    uint256 _depositValueForAddingLiquidity = GMXReader.convertToUsdValue(
      self,
      address(self.tokenA),
      _alp.tokenAAmt
    ) + GMXReader.convertToUsdValue(
      self,
      address(self.tokenB),
      _alp.tokenBAmt
    );

    _alp.minMarketTokenAmt = GMXManager.calcMinMarketSlippageAmt(
      self,
      _depositValueForAddingLiquidity,
      self.liquiditySlippage
    );
    _alp.executionFee = msg.value;

    // reset lastFeeCollected to block.timestamp to avoid having users pay for
    // fees while vault was paused
    self.lastFeeCollected = block.timestamp;

    GMXManager.addLiquidity(
      self,
      _alp
    );

    self.status = GMXTypes.Status.Resume;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processEmergencyResume(
    GMXTypes.Store storage self,
    uint256 lpAmtReceived
  ) external {
    GMXChecks.beforeProcessEmergencyResumeChecks(self);

    self.lpAmt += lpAmtReceived;

    self.status = GMXTypes.Status.Open;

    emit EmergencyResumed();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processEmergencyResumeCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessEmergencyResumeCancellationChecks(self);

    self.status = GMXTypes.Status.Paused;

    emit EmergencyResumedCancelled();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyClose(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeEmergencyCloseChecks(self);

    self.status = GMXTypes.Status.Closed;

    emit EmergencyClosed();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyWithdraw(
    GMXTypes.Store storage self,
    uint256 shareAmt
  ) external {
    // check to ensure shares withdrawn does not exceed user's balance
    uint256 _userShareBalance = IERC20(address(self.vault)).balanceOf(msg.sender);

    // to avoid leaving dust behind
    unchecked {
      if (_userShareBalance - shareAmt < DUST_AMOUNT) {
        shareAmt = _userShareBalance;
      }
    }

    GMXChecks.beforeEmergencyWithdrawChecks(self, shareAmt);

    // share ratio calculation must be before burn()
    uint256 _shareRatio = shareAmt
      * SAFE_MULTIPLIER
      / IERC20(address(self.vault)).totalSupply();

    self.vault.burn(msg.sender, shareAmt);

    uint256 _withdrawAmtTokenA = _shareRatio
      * self.tokenA.balanceOf(address(this))
      / SAFE_MULTIPLIER;
    uint256 _withdrawAmtTokenB = _shareRatio
      * self.tokenB.balanceOf(address(this))
      / SAFE_MULTIPLIER;

    self.tokenA.safeTransfer(msg.sender, _withdrawAmtTokenA);
    self.tokenB.safeTransfer(msg.sender, _withdrawAmtTokenB);

    // Proportionately distribute reward tokens based on share ratio
    uint256 _withdrawAmtRewardToken;
    if (address(self.rewardToken) != address(0)) {
      _withdrawAmtRewardToken = _shareRatio
        * self.rewardToken.balanceOf(address(this))
        / SAFE_MULTIPLIER;

      self.rewardToken.safeTransfer(msg.sender, _withdrawAmtRewardToken);
    }

    emit EmergencyWithdraw(
      msg.sender,
      shareAmt,
      address(self.tokenA),
      _withdrawAmtTokenA,
      address(self.tokenB),
      _withdrawAmtTokenB,
      address(self.rewardToken),
      _withdrawAmtRewardToken
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function emergencyStatusChange(
    GMXTypes.Store storage self,
    GMXTypes.Status status
  ) external {
    GMXChecks.beforeEmergencyStatusChangeChecks(self);

    self.status = status;

    emit EmergencyStatusChanged(uint256(status));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXWorker } from "./GMXWorker.sol";

/**
  * @title GMXManager
  * @author Steadefi
  * @notice Re-usable library functions for calculations and operations of borrows, repays, swaps
  * adding and removal of liquidity to yield source
*/
library GMXManager {
  using SafeERC20 for IERC20;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event BorrowSuccess(uint256 borrowTokenAAmt, uint256 borrowTokenBAmt);
  event RepaySuccess(uint256 repayTokenAAmt, uint256 repayTokenBAmt);

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Calculate if token swap is needed to ensure enough repayment for both tokenA and tokenB
    * @notice Assume that after swapping one token for the other, there is still enough to repay both tokens
    * @param self GMXTypes.Store
    * @param rp GMXTypes.RepayParams
    * @param tokenAAmt Amount of tokenA
    * @param tokenBAmt Amount of tokenB
    * @return swapNeeded boolean if swap is needed
    * @return tokenFrom address of token to swap from
    * @return tokenTo address of token to swap to
    * @return tokenToAmt amount of tokenFrom to swap in token decimals
  */
  function calcSwapForRepay(
    GMXTypes.Store storage self,
    GMXTypes.RepayParams memory rp,
    uint256 tokenAAmt,
    uint256 tokenBAmt
  ) external view returns (bool, address, address, uint256) {
    address _tokenFrom;
    address _tokenTo;
    uint256 _tokenToAmt;

    if (rp.repayTokenAAmt > tokenAAmt) {
      // If more tokenA is needed for repayment
      _tokenToAmt = rp.repayTokenAAmt - tokenAAmt;
      _tokenFrom = address(self.tokenB);
      _tokenTo = address(self.tokenA);

      return (true, _tokenFrom, _tokenTo, _tokenToAmt);
    } else if (rp.repayTokenBAmt > tokenBAmt) {
      // If more tokenB is needed for repayment
      _tokenToAmt = rp.repayTokenBAmt - tokenBAmt;
      _tokenFrom = address(self.tokenA);
      _tokenTo = address(self.tokenB);

      return (true, _tokenFrom, _tokenTo, _tokenToAmt);
    } else {
      // If more there is enough to repay both tokens
      return (false, address(0), address(0), 0);
    }
  }

  /**
    * @notice Calculate amount of tokenA and tokenB to borrow
    * @param self GMXTypes.Store
    * @param depositValue USD value in 1e18
  */
  function calcBorrow(
    GMXTypes.Store storage self,
    uint256 depositValue
  ) external view returns (uint256, uint256) {
    // Calculate final position value based on deposit value
    uint256 _positionValue = depositValue * self.leverage / SAFE_MULTIPLIER;

    // Obtain the value to borrow
    uint256 _borrowValue = _positionValue - depositValue;

    uint256 _tokenADecimals = IERC20Metadata(address(self.tokenA)).decimals();
    uint256 _tokenBDecimals = IERC20Metadata(address(self.tokenB)).decimals();
    uint256 _borrowLongTokenAmt;
    uint256 _borrowShortTokenAmt;

    // If delta is long, borrow all in short token
    if (self.delta == GMXTypes.Delta.Long) {
      _borrowShortTokenAmt = _borrowValue * SAFE_MULTIPLIER
                             / GMXReader.convertToUsdValue(self, address(self.tokenB), 10**(_tokenBDecimals))
                             / (10 ** (18 - _tokenBDecimals));
    }

    // If delta is neutral, borrow appropriate amount in long token to hedge, and the rest in short token
    if (self.delta == GMXTypes.Delta.Neutral) {
      // Get token weights in LP, e.g. 50% = 5e17
      (uint256 _tokenAWeight,) = GMXReader.tokenWeights(self);

      // Get value of long token (typically tokenA)
      uint256 _longTokenWeightedValue = _tokenAWeight * _positionValue / SAFE_MULTIPLIER;

      // Borrow appropriate amount in long token to hedge
      _borrowLongTokenAmt = _longTokenWeightedValue * SAFE_MULTIPLIER
                            / GMXReader.convertToUsdValue(self, address(self.tokenA), 10**(_tokenADecimals))
                            / (10 ** (18 - _tokenADecimals));

      // Borrow the shortfall value in short token
      _borrowShortTokenAmt = (_borrowValue - _longTokenWeightedValue) * SAFE_MULTIPLIER
                             / GMXReader.convertToUsdValue(self, address(self.tokenB), 10**(_tokenBDecimals))
                             / (10 ** (18 - _tokenBDecimals));
    }

    // If delta is short, borrow all in long token
    if (self.delta == GMXTypes.Delta.Short) {
      _borrowLongTokenAmt = _borrowValue * SAFE_MULTIPLIER
                             / GMXReader.convertToUsdValue(self, address(self.tokenA), 10**(_tokenADecimals))
                             / (10 ** (18 - _tokenADecimals));
    }

    return (_borrowLongTokenAmt, _borrowShortTokenAmt);
  }

  /**
    * @notice Calculate amount of tokenA and tokenB to repay based on token shares ratio being withdrawn
    * @param self GMXTypes.Store
    * @param shareRatio Amount of vault token shares relative to total supply in 1e18
  */
  function calcRepay(
    GMXTypes.Store storage self,
    uint256 shareRatio
  ) external view returns (uint256, uint256) {
    (uint256 tokenADebtAmt, uint256 tokenBDebtAmt) = GMXReader.debtAmt(self);

    uint256 _repayTokenAAmt = shareRatio * tokenADebtAmt / SAFE_MULTIPLIER;
    uint256 _repayTokenBAmt = shareRatio * tokenBDebtAmt / SAFE_MULTIPLIER;

    return (_repayTokenAAmt, _repayTokenBAmt);
  }

  /**
    * @notice Calculate minimum market (GM LP) tokens to receive when adding liquidity
    * @param self GMXTypes.Store
    * @param depositValue USD value in 1e18
    * @param slippage Slippage value in 1e4
    * @return minMarketTokenAmt in 1e18
  */
  function calcMinMarketSlippageAmt(
    GMXTypes.Store storage self,
    uint256 depositValue,
    uint256 slippage
  ) external view returns (uint256) {
    uint256 _lpTokenValue = self.gmxOracle.getLpTokenValue(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB),
      true,
      false
    );

    return depositValue
      * SAFE_MULTIPLIER
      / _lpTokenValue
      * (10000 - slippage) / 10000;
  }

  /**
    * @notice Calculate minimum tokens to receive when removing liquidity
    * @dev minLongToken and minShortToken should be the token which we want to receive
    * after liquidity withdrawal and swap
    * @param self GMXTypes.Store
    * @param lpAmt Amt of lp tokens to remove liquidity in 1e18
    * @param minLongToken Address of token to receive longToken in
    * @param minShortToken Address of token to receive shortToken in
    * @param slippage Slippage value in 1e4
    * @return minTokenAAmt in 1e18
    * @return minTokenBAmt in 1e18
  */
  function calcMinTokensSlippageAmt(
    GMXTypes.Store storage self,
    uint256 lpAmt,
    address minLongToken,
    address minShortToken,
    uint256 slippage
  ) external view returns (uint256, uint256) {
    uint256 _withdrawValue = lpAmt
      * self.gmxOracle.getLpTokenValue(
        address(self.lpToken),
        address(self.tokenA),
        address(self.tokenA),
        address(self.tokenB),
        true,
        false
      )
      / SAFE_MULTIPLIER;

    (uint256 _tokenAWeight, uint256 _tokenBWeight) = GMXReader.tokenWeights(self);

    uint256 _minLongTokenAmt = _withdrawValue
      * _tokenAWeight / SAFE_MULTIPLIER
      * SAFE_MULTIPLIER
      / GMXReader.convertToUsdValue(
        self,
        minLongToken,
        10**(IERC20Metadata(minLongToken).decimals())
      )
      / (10 ** (18 - IERC20Metadata(minLongToken).decimals()));

    uint256 _minShortTokenAmt = _withdrawValue
      * _tokenBWeight / SAFE_MULTIPLIER
      * SAFE_MULTIPLIER
      / GMXReader.convertToUsdValue(
        self,
        minShortToken,
        10**(IERC20Metadata(minShortToken).decimals())
      )
      / (10 ** (18 - IERC20Metadata(minShortToken).decimals()));

    return (
      _minLongTokenAmt * (10000 - slippage) / 10000,
      _minShortTokenAmt * (10000 - slippage) / 10000
    );
  }

  /**
    * @notice Calculate maximum amount of tokenIn allowed when swapping for an exact
    * amount of tokenOut as a form of slippage protection
    * @dev We slightly buffer amountOut here with swapSlippage to account for fees, etc.
    * @param self GMXTypes.Store
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param amountOut Amt of tokenOut wanted
    * @return amountInMaximum in 1e18
  */
  function calcAmountInMaximum(
    GMXTypes.Store storage self,
    address tokenIn,
    address tokenOut,
    uint256 amountOut
  ) external view returns (uint256) {
    // Value of token out wanted in 1e18
    uint256 _tokenOutValue = amountOut
      * self.chainlinkOracle.consultIn18Decimals(tokenOut)
      / (10 ** IERC20Metadata(tokenOut).decimals());

    // Maximum amount in in 1e18
    uint256 _amountInMaximum = _tokenOutValue
      * SAFE_MULTIPLIER
      / self.chainlinkOracle.consultIn18Decimals(tokenIn)
      * (10000 + self.swapSlippage) / 10000;

    // If tokenIn asset decimals is less than 18, e.g. USDC,
    // we need to normalize the decimals of _amountInMaximum
    if (IERC20Metadata(tokenIn).decimals() < 18)
      _amountInMaximum /= 10 ** (18 - IERC20Metadata(tokenIn).decimals());

    return _amountInMaximum;
  }

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice Borrow tokens from lending vaults
    * @param self GMXTypes.Store
    * @param borrowTokenAAmt Amount of tokenA to borrow in token decimals
    * @param borrowTokenBAmt Amount of tokenB to borrow in token decimals
  */
  function borrow(
    GMXTypes.Store storage self,
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  ) public {
    if (borrowTokenAAmt > 0) {
      self.tokenALendingVault.borrow(borrowTokenAAmt);
    }
    if (borrowTokenBAmt > 0) {
      self.tokenBLendingVault.borrow(borrowTokenBAmt);
    }

    emit BorrowSuccess(borrowTokenAAmt, borrowTokenBAmt);
  }

  /**
    * @notice Repay tokens to lending vaults
    * @param self GMXTypes.Store
    * @param repayTokenAAmt Amount of tokenA to repay in token decimals
    * @param repayTokenBAmt Amount of tokenB to repay in token decimals
  */
  function repay(
    GMXTypes.Store storage self,
    uint256 repayTokenAAmt,
    uint256 repayTokenBAmt
  ) public {
    if (repayTokenAAmt > 0) {
      self.tokenALendingVault.repay(repayTokenAAmt);
    }
    if (repayTokenBAmt > 0) {
      self.tokenBLendingVault.repay(repayTokenBAmt);
    }

    emit RepaySuccess(repayTokenAAmt, repayTokenBAmt);
  }

  /**
    * @notice Add liquidity to yield source
    * @param self GMXTypes.Store
    * @param alp GMXTypes.AddLiquidityParams
    * @return depositKey
  */
  function addLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.AddLiquidityParams memory alp
  ) public returns (bytes32) {
    return GMXWorker.addLiquidity(self, alp);
  }

  /**
    * @notice Remove liquidity from yield source
    * @param self GMXTypes.Store
    * @param rlp GMXTypes.RemoveLiquidityParams
    * @return withdrawKey
  */
  function removeLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.RemoveLiquidityParams memory rlp
  ) public returns (bytes32) {
    return GMXWorker.removeLiquidity(self, rlp);
  }

  /**
    * @notice Swap exact amount of tokenIn for as many possible amount of tokenOut
    * @param self GMXTypes.Store
    * @param sp ISwap.SwapParams
    * @return amountOut in token decimals
  */
  function swapExactTokensForTokens(
    GMXTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    if (sp.amountIn > 0) {
      return GMXWorker.swapExactTokensForTokens(self, sp);
    } else {
      return 0;
    }
  }

  /**
    * @notice Swap as little posible tokenIn for exact amount of tokenOut
    * @param self GMXTypes.Store
    * @param sp ISwap.SwapParams
    * @return amountIn in token decimals
  */
  function swapTokensForExactTokens(
    GMXTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    if (sp.amountIn > 0) {
      return GMXWorker.swapTokensForExactTokens(self, sp);
    } else {
      return 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from "./GMXTypes.sol";
import { GMXChecks } from "./GMXChecks.sol";

/**
  * @title GMXProcessDeposit
  * @author Steadefi
  * @notice Re-usable library functions for process deposit operations for Steadefi leveraged vaults
*/
library GMXProcessDeposit {

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processDeposit(
    GMXTypes.Store storage self
  ) external view {
    GMXChecks.afterDepositChecks(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";

/**
  * @title GMXProcessWithdraw
  * @author Steadefi
  * @notice Re-usable library functions for process withdraw operations for Steadefi leveraged vaults
*/
library GMXProcessWithdraw {

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processWithdraw(
    GMXTypes.Store storage self
  ) external {
    // Check if swap between assets are needed for repayment
    (
      bool _swapNeeded,
      address _tokenFrom,
      address _tokenTo,
      uint256 _tokenToAmt
    ) = GMXManager.calcSwapForRepay(
      self,
      self.withdrawCache.repayParams,
      self.withdrawCache.tokenAReceived,
      self.withdrawCache.tokenBReceived
    );

    // Swap likely only needed if vault strategy is Neutral as we borrow both tokenA and tokenB
    if (_swapNeeded) {
      ISwap.SwapParams memory _sp;

      _sp.tokenIn = _tokenFrom;
      _sp.tokenOut = _tokenTo;
      _sp.amountIn = GMXManager.calcAmountInMaximum(
        self,
        _tokenFrom,
        _tokenTo,
        _tokenToAmt
      );
      _sp.amountOut = _tokenToAmt;
      _sp.slippage = self.swapSlippage;
      _sp.deadline = block.timestamp;
      // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // We allow deadline to be set as the current block timestamp whenever this function
      // is called because this function is triggered as a follow up function (by a callback/keeper)
      // and not directly by a user/keeper. If this follow on function flow reverts due to this tx
      // being processed after a set deadline, this will cause the vault to be in a "stuck" state.
      // To resolve this, this function will have to be called again with an updated deadline until it
      // succeeds/a miner processes the tx.

      uint256 _amountIn = GMXManager.swapTokensForExactTokens(self, _sp);

      if (_tokenFrom == address(self.tokenA)) {
        self.withdrawCache.tokenAReceived -= _amountIn;
        self.withdrawCache.tokenBReceived += _tokenToAmt;
      } else if (_tokenFrom == address(self.tokenB)) {
        self.withdrawCache.tokenBReceived -= _amountIn;
        self.withdrawCache.tokenAReceived += _tokenToAmt;
      }
    }

    // Repay debt
    GMXManager.repay(
      self,
      self.withdrawCache.repayParams.repayTokenAAmt,
      self.withdrawCache.repayParams.repayTokenBAmt
    );

    self.withdrawCache.tokenAReceived -= self.withdrawCache.repayParams.repayTokenAAmt;
    self.withdrawCache.tokenBReceived -= self.withdrawCache.repayParams.repayTokenBAmt;

    // At this point, the LP has been accounted to be removed for withdrawal so
    // equityValue should be less than before
    self.withdrawCache.healthParams.equityAfter = GMXReader.equityValue(self);

    if (self.withdrawCache.withdrawParams.token == address(self.tokenA)) {
      if (self.withdrawCache.tokenBReceived > 0) {
        ISwap.SwapParams memory _sp;

        _sp.tokenIn = address(self.tokenB);
        _sp.tokenOut = address(self.tokenA);
        _sp.amountIn = self.withdrawCache.tokenBReceived;
        _sp.slippage = self.swapSlippage;
        _sp.deadline = block.timestamp;
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // We allow deadline to be set as the current block timestamp whenever this function
        // is called because this function is triggered as a follow up function (by a callback/keeper)
        // and not directly by a user/keeper. If this follow on function flow reverts due to this tx
        // being processed after a set deadline, this will cause the vault to be in a "stuck" state.
        // To resolve this, this function will have to be called again with an updated deadline until it
        // succeeds/a miner processes the tx.

        uint256 _amountOut = GMXManager.swapExactTokensForTokens(self, _sp);

        self.withdrawCache.tokenAReceived += _amountOut;
      }

      self.withdrawCache.assetsToUser = self.withdrawCache.tokenAReceived;
    }

    if (self.withdrawCache.withdrawParams.token == address(self.tokenB)) {
      if (self.withdrawCache.tokenAReceived > 0) {
        ISwap.SwapParams memory _sp;

        _sp.tokenIn = address(self.tokenA);
        _sp.tokenOut = address(self.tokenB);
        _sp.amountIn = self.withdrawCache.tokenAReceived;
        _sp.slippage = self.swapSlippage;
        _sp.deadline = block.timestamp;
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // We allow deadline to be set as the current block timestamp whenever this function
        // is called because this function is triggered as a follow up function (by a callback/keeper)
        // and not directly by a user/keeper. If this follow on function flow reverts due to this tx
        // being processed after a set deadline, this will cause the vault to be in a "stuck" state.
        // To resolve this, this function will have to be called again with an updated deadline until it
        // succeeds/a miner processes the tx.

        uint256 _amountOut = GMXManager.swapExactTokensForTokens(self, _sp);

        self.withdrawCache.tokenBReceived += _amountOut;
      }

      self.withdrawCache.assetsToUser = self.withdrawCache.tokenBReceived;
    }

    // After withdraws checks to be done outside of if block to also cover for LP withdrawal flow
    GMXChecks.afterWithdrawChecks(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { GMXTypes } from "./GMXTypes.sol";

/**
  * @title GMXReader
  * @author Steadefi
  * @notice Re-usable library functions for reading data and values for Steadefi leveraged vaults
*/
library GMXReader {
  using SafeCast for uint256;

  /* =================== CONSTANTS FUNCTIONS ================= */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function svTokenValue(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 equityValue_ = equityValue(self);
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    return equityValue_ * SAFE_MULTIPLIER / (totalSupply_ + pendingFee(self));
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function pendingFee(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    uint256 _secondsFromLastCollection = block.timestamp - self.lastFeeCollected;
    return (totalSupply_ * self.feePerSecond * _secondsFromLastCollection) / SAFE_MULTIPLIER;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function valueToShares(
    GMXTypes.Store storage self,
    uint256 value,
    uint256 currentEquity
  ) public view returns (uint256) {
    uint256 _sharesSupply = IERC20(address(self.vault)).totalSupply() + pendingFee(self);
    if (_sharesSupply == 0 || currentEquity == 0) return value;
    return value * _sharesSupply / currentEquity;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function convertToUsdValue(
    GMXTypes.Store storage self,
    address token,
    uint256 amt
  ) public view returns (uint256) {
    return (amt * self.chainlinkOracle.consultIn18Decimals(token))
      / (10 ** IERC20Metadata(token).decimals());
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function tokenWeights(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    // Get amounts of tokenA and tokenB in liquidity pool in token decimals
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    // Get value of tokenA and tokenB in 1e18
    uint256 _tokenAValue = convertToUsdValue(self, address(self.tokenA), _reserveA);
    uint256 _tokenBValue = convertToUsdValue(self, address(self.tokenB), _reserveB);

    uint256 _totalLpValue = _tokenAValue + _tokenBValue;

    return (
      _tokenAValue * SAFE_MULTIPLIER / _totalLpValue,
      _tokenBValue * SAFE_MULTIPLIER / _totalLpValue
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function assetValue(GMXTypes.Store storage self) public view returns (uint256) {
    return lpAmt(self) * self.gmxOracle.getLpTokenValue(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB),
      true,
      false
    ) / SAFE_MULTIPLIER;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function debtValue(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);
    return (
      convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt),
      convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt)
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function equityValue(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtAmt, uint256 _tokenBDebtAmt) = debtAmt(self);

    uint256 assetValue_ = assetValue(self);

    uint256 _debtValue = convertToUsdValue(self, address(self.tokenA), _tokenADebtAmt)
                         + convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt);

    // in underflow condition return 0
    unchecked {
      if (assetValue_ < _debtValue) return 0;
      return assetValue_ - _debtValue;
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function assetAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    (uint256 _reserveA, uint256 _reserveB) = self.gmxOracle.getLpTokenReserves(
      address(self.lpToken),
      address(self.tokenA),
      address(self.tokenA),
      address(self.tokenB)
    );

    return (
      _reserveA * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER,
      _reserveB * SAFE_MULTIPLIER * lpAmt(self) / self.lpToken.totalSupply() / SAFE_MULTIPLIER
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function debtAmt(GMXTypes.Store storage self) public view returns (uint256, uint256) {
    return (
      self.tokenALendingVault.maxRepay(address(self.vault)),
      self.tokenBLendingVault.maxRepay(address(self.vault))
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function lpAmt(GMXTypes.Store storage self) public view returns (uint256) {
    return self.lpAmt;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function leverage(GMXTypes.Store storage self) public view returns (uint256) {
    if (assetValue(self) == 0 || equityValue(self) == 0) return 0;
    return assetValue(self) * SAFE_MULTIPLIER / equityValue(self);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function delta(GMXTypes.Store storage self) public view returns (int256) {
    (uint256 _tokenAAmt,) = assetAmt(self);
    (uint256 _tokenADebtAmt,) = debtAmt(self);
    uint256 equityValue_ = equityValue(self);

    if (_tokenAAmt == 0 && _tokenADebtAmt == 0) return 0;
    if (equityValue_ == 0) return 0;

    bool _isPositive = _tokenAAmt >= _tokenADebtAmt;

    uint256 _unsignedDelta = _isPositive ?
      _tokenAAmt - _tokenADebtAmt :
      _tokenADebtAmt - _tokenAAmt;

    int256 signedDelta = (_unsignedDelta
      * self.chainlinkOracle.consultIn18Decimals(address(self.tokenA))
      / equityValue_).toInt256();

    if (_isPositive) return signedDelta;
    else return -signedDelta;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function debtRatio(GMXTypes.Store storage self) public view returns (uint256) {
    (uint256 _tokenADebtValue, uint256 _tokenBDebtValue) = debtValue(self);
    if (assetValue(self) == 0) return 0;
    return (_tokenADebtValue + _tokenBDebtValue) * SAFE_MULTIPLIER / assetValue(self);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function additionalCapacity(GMXTypes.Store storage self) public view returns (uint256) {
    uint256 _additionalCapacity;

    // Long strategy only borrows short token (typically stablecoin)
    if (self.delta == GMXTypes.Delta.Long) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER / (self.leverage - 1e18);
    }

    // Short strategy only borrows long token
    if (self.delta == GMXTypes.Delta.Short) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenA),
        self.tokenALendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER / (self.leverage - 1e18);
    }

    // Neutral strategy borrows both long (typical volatile) and short token (typically stablecoin)
    // Amount of long token to borrow is equivalent to deposited value x leverage x longTokenWeight
    // Amount of short token to borrow is remaining borrow value AFTER borrowing long token
    // ---------------------------------------------------------------------------------------------
    // E.g: 3x Neutral ETH-USDC with weight of ETH being 55%, USDC 45%
    // A $1 equity deposit should result in a $2 borrow for a total of $3 assets
    // Amount of ETH to borrow would be $3 x 55% = $1.65 worth of ETH
    // Amount of USDC to borrow would be $3 (asset) - $1.65 (ETH borrowed) - $1 (equity) = $0.35
    // ---------------------------------------------------------------------------------------------
    // Note that for Neutral strategies, vault's leverage has to be 3x and above.
    // A 2x leverage neutral strategy may not work to correctly to borrow enough long token to hedge
    // while still adhering to the correct leverage factor.
    // Note also that tokenBWeight and leverage factor may result in a negative _maxTokenBLending
    // For e.g. if tokenBWeight drops to 33% with leverage being 3x, _maxTokenBLending would be less
    // than 1.0 and based on the code logic below it will underflow. The proper way to resolve
    // this issue is to increase the leverage factor so that we can properly borrow enough to hedge
    // tokenA while also adhering to the correct leverage factor.
    if (self.delta == GMXTypes.Delta.Neutral) {
      (uint256 _tokenAWeight, uint256 _tokenBWeight) = tokenWeights(self);

      uint256 _maxTokenALending = convertToUsdValue(
        self,
        address(self.tokenA),
        self.tokenALendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (self.leverage * _tokenAWeight / SAFE_MULTIPLIER);

      uint256 _maxTokenBLending = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER
        / (self.leverage * _tokenBWeight / SAFE_MULTIPLIER - 1e18);

      _additionalCapacity = _maxTokenALending > _maxTokenBLending ? _maxTokenBLending : _maxTokenALending;
    }

    return _additionalCapacity;
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function capacity(GMXTypes.Store storage self) public view returns (uint256) {
    return additionalCapacity(self) + equityValue(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";
import { GMXEmergency } from "./GMXEmergency.sol";

/**
  * @title GMXRebalance
  * @author Steadefi
  * @notice Re-usable library functions for rebalancing operations for Steadefi leveraged vaults
*/
library GMXRebalance {

  /* ======================== EVENTS ========================= */

  event RebalanceAdded(
    uint rebalanceType,
    uint256 borrowTokenAAmt,
    uint256 borrowTokenBAmt
  );
  event RebalanceAddProcessed();
  event RebalanceRemoved(
    uint rebalanceType,
    uint256 lpAmtToRemove
  );
  event RebalanceRemoveProcessed();
  event RebalanceSuccess(
    uint256 svTokenValueBefore,
    uint256 svTokenValueAfter
  );
  event RebalanceOpen(
    bytes reason,
    uint256 svTokenValueBefore,
    uint256 svTokenValueAfter
  );
  event RebalanceCancelled();

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function rebalanceAdd(
    GMXTypes.Store storage self,
    GMXTypes.RebalanceAddParams memory rap
  ) external {
    self.refundee = payable(msg.sender);

    GMXTypes.HealthParams memory _hp;

    _hp.lpAmtBefore = GMXReader.lpAmt(self);
    _hp.debtRatioBefore = GMXReader.debtRatio(self);
    _hp.deltaBefore = GMXReader.delta(self);
    _hp.svTokenValueBefore = GMXReader.svTokenValue(self);

    GMXTypes.RebalanceCache memory _rc;

    _rc.rebalanceType = rap.rebalanceType;
    _rc.borrowParams = rap.borrowParams;
    _rc.healthParams = _hp;

    self.rebalanceCache = _rc;

    GMXChecks.beforeRebalanceChecks(self, rap.rebalanceType);

    self.status = GMXTypes.Status.Rebalance_Add;

    GMXManager.borrow(
      self,
      rap.borrowParams.borrowTokenAAmt,
      rap.borrowParams.borrowTokenBAmt
    );

    GMXTypes.AddLiquidityParams memory _alp;

    _alp.tokenAAmt = rap.borrowParams.borrowTokenAAmt;
    _alp.tokenBAmt = rap.borrowParams.borrowTokenBAmt;

    // Calculate deposit value after borrows and repays
    // Rebalance will only deal with tokenA and tokenB and not LP tokens
    uint256 _depositValue = GMXReader.convertToUsdValue(
      self,
      address(self.tokenA),
      _alp.tokenAAmt
    )
    + GMXReader.convertToUsdValue(
      self,
      address(self.tokenB),
      _alp.tokenBAmt
    );

    _alp.minMarketTokenAmt = GMXManager.calcMinMarketSlippageAmt(
      self,
      _depositValue,
      self.liquiditySlippage
    );

    _alp.executionFee = rap.executionFee;

    self.rebalanceCache.depositKey = GMXManager.addLiquidity(
      self,
      _alp
    );

    emit RebalanceAdded(
      uint(rap.rebalanceType),
      rap.borrowParams.borrowTokenAAmt,
      rap.borrowParams.borrowTokenBAmt
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processRebalanceAdd(
    GMXTypes.Store storage self,
    uint256 lpAmtReceived
  ) external {
    GMXChecks.beforeProcessRebalanceChecks(self);

    self.lpAmt += lpAmtReceived;

    try GMXChecks.afterRebalanceChecks(self) {
      self.status = GMXTypes.Status.Open;

      emit RebalanceSuccess(
        self.rebalanceCache.healthParams.svTokenValueBefore,
        GMXReader.svTokenValue(self)
      );
    } catch (bytes memory reason) {
      self.status = GMXTypes.Status.Rebalance_Open;

      emit RebalanceOpen(
        reason,
        self.rebalanceCache.healthParams.svTokenValueBefore,
        GMXReader.svTokenValue(self)
      );
    }

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit RebalanceAddProcessed();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processRebalanceAddCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessRebalanceChecks(self);

    GMXManager.repay(
      self,
      self.rebalanceCache.borrowParams.borrowTokenAAmt,
      self.rebalanceCache.borrowParams.borrowTokenBAmt
    );

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit RebalanceCancelled();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function rebalanceRemove(
    GMXTypes.Store storage self,
    GMXTypes.RebalanceRemoveParams memory rrp
  ) external {
    self.refundee = payable(msg.sender);

    GMXTypes.HealthParams memory _hp;

    _hp.lpAmtBefore = GMXReader.lpAmt(self);
    _hp.debtRatioBefore = GMXReader.debtRatio(self);
    _hp.deltaBefore = GMXReader.delta(self);
    _hp.svTokenValueBefore = GMXReader.svTokenValue(self);

    GMXTypes.RebalanceCache memory _rc;

    _rc.rebalanceType = rrp.rebalanceType;
    _rc.lpAmtToRemove = rrp.lpAmtToRemove;
    _rc.healthParams = _hp;

    self.rebalanceCache = _rc;

    GMXChecks.beforeRebalanceChecks(self, rrp.rebalanceType);

    self.status = GMXTypes.Status.Rebalance_Remove;

    self.lpAmt -= rrp.lpAmtToRemove;

    GMXTypes.RemoveLiquidityParams memory _rlp;

    if (rrp.rebalanceType == GMXTypes.RebalanceType.Delta) {
      // When rebalancing delta, repay only tokenA so withdraw liquidity only in tokenA
      address[] memory _tokenBSwapPath = new address[](1);
      _tokenBSwapPath[0] = address(self.lpToken);
      _rlp.tokenBSwapPath = _tokenBSwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        rrp.lpAmtToRemove,
        address(self.tokenA),
        address(self.tokenA),
        self.liquiditySlippage
      );
    } else if (rrp.rebalanceType == GMXTypes.RebalanceType.Debt) {
      // When rebalancing debt, repay only tokenB so withdraw liquidity only in tokenB
      address[] memory _tokenASwapPath = new address[](1);
      _tokenASwapPath[0] = address(self.lpToken);
      _rlp.tokenASwapPath = _tokenASwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        rrp.lpAmtToRemove,
        address(self.tokenB),
        address(self.tokenB),
        self.liquiditySlippage
      );
    }

    _rlp.lpAmt = rrp.lpAmtToRemove;
    _rlp.executionFee = rrp.executionFee;

    self.rebalanceCache.withdrawKey = GMXManager.removeLiquidity(
      self,
      _rlp
    );

    emit RebalanceRemoved(
      uint(rrp.rebalanceType),
      rrp.lpAmtToRemove
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processRebalanceRemove(
    GMXTypes.Store storage self,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external {
    GMXChecks.beforeProcessRebalanceChecks(self);

    // As we convert LP tokens in rebalanceRemove() to receive assets in as:
    // Delta: 100% tokenA
    // Debt: 100% tokenB
    // The tokenAReceived/tokenBReceived values could both be amounts of the same token.
    // As such we look to "sanitise" the data here such that for e.g., if we had wanted only
    // tokenA from withdrawal of the LP tokens, we will add tokenBReceived to tokenAReceived and
    // clear out tokenBReceived to 0.
    if (self.rebalanceCache.rebalanceType == GMXTypes.RebalanceType.Delta) {
      // We withdraw assets all in tokenA
      self.withdrawCache.tokenAReceived = tokenAReceived + tokenBReceived;
      self.withdrawCache.tokenBReceived = 0;
    } else if (self.rebalanceCache.rebalanceType == GMXTypes.RebalanceType.Debt) {
      // We withdraw assets all in tokenB
      self.withdrawCache.tokenAReceived = 0;
      self.withdrawCache.tokenBReceived = tokenAReceived + tokenBReceived;
    }

    GMXManager.repay(
      self,
      self.withdrawCache.tokenAReceived,
      self.withdrawCache.tokenBReceived
    );

    try GMXChecks.afterRebalanceChecks(self) {
      self.status = GMXTypes.Status.Open;

      emit RebalanceSuccess(
        self.rebalanceCache.healthParams.svTokenValueBefore,
        GMXReader.svTokenValue(self)
      );
    } catch (bytes memory reason) {
      self.status = GMXTypes.Status.Rebalance_Open;

      emit RebalanceOpen(
        reason,
        self.rebalanceCache.healthParams.svTokenValueBefore,
        GMXReader.svTokenValue(self)
      );
    }

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit RebalanceRemoveProcessed();
  }

  /**
    * @dev Process cancellation after processRebalanceRemoveCancellation()
    * @param self Vault store data
  **/
  function processRebalanceRemoveCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessRebalanceChecks(self);

    self.lpAmt += self.rebalanceCache.lpAmtToRemove;

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit RebalanceCancelled();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from "../../interfaces/oracles/IGMXOracle.sol";
import { IExchangeRouter } from "../../interfaces/protocols/gmx/IExchangeRouter.sol";
import { ISwap } from "../../interfaces/swap/ISwap.sol";

/**
  * @title GMXTypes
  * @author Steadefi
  * @notice Re-usable library of Types struct definitions for Steadefi leveraged vaults
*/
library GMXTypes {

  /* ======================= STRUCTS ========================= */

  struct Store {
    // Status of the vault
    Status status;
    // Should emergency pause as soon as possible
    bool shouldEmergencyPause;
    // Should deposit LP tokens for additional yield LP tokens
    bool shouldDepositLPTokens;

    // Amount of LP tokens that vault accounts for as total assets
    uint256 lpAmt;
    // Amount of additional yield LP tokens from depositing LP tokens
    uint256 ylpAmt;

    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;
    // Address to refund execution fees to
    address payable refundee;

    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 feePerSecond;
    // Treasury address
    address treasury;

    // Guards: change threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Guards: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e18; 69e16 = 0.69 = 69%
    // Guards: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e18; 61e16 = 0.61 = 61%
    // Guards: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e18; 15e16 = 0.15 = +15%
    // Guards: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e18; -15e16 = -0.15 = -15%
    // Guards: Minimum vault slippage for vault shares/assets in 1e4; e.g. 100 = 1%
    uint256 minVaultSlippage;
    // Slippage for adding/removing liquidity in 1e4; e.g. 100 = 1%
    uint256 liquiditySlippage;
    // Slippage for swaps in 1e4; e.g. 100 = 1%
    uint256 swapSlippage;
    // GMX callback gas limit setting
    uint256 callbackGasLimit;
    // Minimum asset value per vault deposit/withdrawal
    uint256 minAssetValue;
    // Maximum asset value per vault deposit/withdrawal
    uint256 maxAssetValue;

    // Token A in this strategy; long token + index token
    IERC20 tokenA;
    // Token B in this strategy; short token
    IERC20 tokenB;
    // LP token of this strategy; market token
    IERC20 lpToken;
    // Native token for this chain (e.g. WETH, WAVAX, WBNB, etc.)
    IWNT WNT;
    // Reward token (e.g. ARB)
    IERC20 rewardToken;
    // Additional yield LP token (e.g. AALP)
    IERC20 ylpToken;

    // Token A lending vault
    ILendingVault tokenALendingVault;
    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IGMXVault vault;
    // Callback contract address
    address callback;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;
    // GMX Oracle contract address
    IGMXOracle gmxOracle;

    // GMX exchange router contract address
    IExchangeRouter exchangeRouter;
    // GMX router contract address
    address router;
    // GMX deposit vault address
    address depositVault;
    // GMX withdrawal vault address
    address withdrawalVault;
    // GMX role store address
    address roleStore;

    // AALP Master Router
    address masterRouter;
    // AALP LP Router
    address lpRouter;
    // AALP LP Manager
    address lpManager;

    // Swap router for this vault
    ISwap swapRouter;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceCache
    RebalanceCache rebalanceCache;
    // CompoundCache
    CompoundCache compoundCache;
  }

  struct DepositCache {
    // Address of user
    address payable user;
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Minimum amount of shares expected in 1e18
    uint256 minSharesAmt;
    // Actual amount of shares minted in 1e18
    uint256 sharesToUser;
    // Amount of LP tokens that vault received in 1e18
    uint256 lpAmtReceived;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // Withdraw key from GMX in bytes32; filled by deposit failure event occurs
    bytes32 withdrawKey;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user
    address payable user;
    // Ratio of shares out of total supply of shares to burn
    uint256 shareRatio;
    // Amount of LP to remove liquidity from
    uint256 lpAmt;
    // Withdrawal value in 1e18
    uint256 withdrawValue;
    // Minimum amount of assets that user receives
    uint256 minAssetsAmt;
    // Actual amount of assets that user receives
    uint256 assetsToUser;
    // Amount of tokenA that vault received in 1e18
    uint256 tokenAReceived;
    // Amount of tokenB that vault received in 1e18
    uint256 tokenBReceived;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // Deposit key from GMX in bytes32; filled by withdrawal failure event occurs
    bytes32 depositKey;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct RebalanceCache {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // BorrowParams
    BorrowParams borrowParams;
    // LP amount to remove in 1e18
    uint256 lpAmtToRemove;
    // HealthParams
    HealthParams healthParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lpToken
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Address of token to withdraw to; could be tokenA, tokenB
    address token;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  struct CompoundParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in
    uint256 amtIn;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct RebalanceAddParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RebalanceRemoveParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // LP amount to remove in 1e18
    uint256 lpAmtToRemove;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct BorrowParams {
    // Amount of tokenA to borrow in tokenA decimals
    uint256 borrowTokenAAmt;
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenA to repay in tokenA decimals
    uint256 repayTokenAAmt;
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct HealthParams {
    // LP token balance in 1e18
    uint256 lpAmtBefore;
    // Token A asset amount before in 1e18
    uint256 tokenAAssetAmtBefore;
    // Token B asset amount before in 1e18
    uint256 tokenBAssetAmtBefore;
    // Token A debt amount before in 1e18
    uint256 tokenADebtAmtBefore;
    // Token B debt amount before in 1e18
    uint256 tokenBDebtAmtBefore;
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  struct AddLiquidityParams {
    // Amount of tokenA to add liquidity
    uint256 tokenAAmt;
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
    // Minimum market tokens to receive in 1e18
    uint256 minMarketTokenAmt;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RemoveLiquidityParams {
    // Amount of lpToken to remove liquidity
    uint256 lpAmt;
    // Array of market token in array to swap tokenA to other token in market
    address[] tokenASwapPath;
    // Array of market token in array to swap tokenB to other token in market
    address[] tokenBSwapPath;
    // Minimum amount of tokenA to receive in token decimals
    uint256 minTokenAAmt;
    // Minimum amount of tokenB to receive in token decimals
    uint256 minTokenBAmt;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  /* ========== ENUM ========== */

  enum Status {
    // 0) Vault is open
    Open,
    // 1) User is depositing to vault
    Deposit,
    // 2) User deposit to vault failure
    Deposit_Failed,
    // 3) User is withdrawing from vault
    Withdraw,
    // 4) User withdrawal from vault failure
    Withdraw_Failed,
    // 5) Vault is rebalancing delta or debt  with more hedging
    Rebalance_Add,
    // 6) Vault is rebalancing delta or debt with less hedging
    Rebalance_Remove,
    // 7) Vault has rebalanced but still requires more rebalancing
    Rebalance_Open,
    // 8) Vault is compounding
    Compound,
    // 9) Vault is paused
    Paused,
    // 10) Vault is repaying
    Repay,
    // 11) Vault has repaid all debt after pausing
    Repaid,
    // 12) Vault is resuming
    Resume,
    // 13) Vault is closed after repaying debt
    Closed
  }

  enum Delta {
    // Neutral delta strategy; aims to hedge tokenA exposure
    Neutral,
    // Long delta strategy; aims to correlate with tokenA exposure
    Long,
    // Short delta strategy; aims to overhedge tokenA exposure
    Short
  }

  enum RebalanceType {
    // Rebalance delta; mostly borrowing/repay tokenA
    Delta,
    // Rebalance debt ratio; mostly borrowing/repay tokenB
    Debt
  }

  enum CallbackType {
    // 0
    ProcessDeposit,
    // 1
    ProcessRebalanceAdd,
    // 2
    ProcessCompound,
    // 3
    ProcessWithdrawFailureLiquidityAdded,
    // 4
    ProcessEmergencyResume,
    // 5
    ProcessDepositCancellation,
    // 6
    ProcessRebalanceAddCancellation,
    // 7
    ProcessCompoundCancellation,
    // 8
    ProcessEmergencyResumeCancellation,
    // 9
    ProcessWithdraw,
    // 10
    ProcessRebalanceRemove,
    // 11
    ProcessDepositFailureLiquidityWithdrawal,
    // 12
    ProcessEmergencyRepay,
    // 13
    ProcessWithdrawCancellation,
    // 14
    ProcessRebalanceRemoveCancellation
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessManaged } from "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IWNT } from  "../../interfaces/tokens/IWNT.sol";
import { IGMXVault } from  "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IGMXVaultEvents } from  "../../interfaces/strategy/gmx/IGMXVaultEvents.sol";
import { ILendingVault } from  "../../interfaces/lending/ILendingVault.sol";
import { IChainlinkOracle } from  "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from  "../../interfaces/oracles/IGMXOracle.sol";
import { IExchangeRouter } from "../../interfaces/protocols/gmx/IExchangeRouter.sol";
import { ISwap } from "../../interfaces/swap/ISwap.sol";
import { Errors } from  "../../utils/Errors.sol";
import { GMXTypes } from  "./GMXTypes.sol";
import { GMXDeposit } from  "./GMXDeposit.sol";
import { GMXWithdraw } from  "./GMXWithdraw.sol";
import { GMXRebalance } from  "./GMXRebalance.sol";
import { GMXCompound } from  "./GMXCompound.sol";
import { GMXEmergency } from  "./GMXEmergency.sol";
import { GMXReader } from  "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";

/**
  * @title GMXVault
  * @author Steadefi
  * @notice Main point of interaction with a Steadefi leveraged strategy vault
*/
contract GMXVault is ERC20, AccessManaged, ReentrancyGuard, IGMXVault, IGMXVaultEvents {

  using SafeERC20 for IERC20;

  /* ==================== STATE VARIABLES ==================== */

  // GMXTypes.Store
  GMXTypes.Store internal _store;

  /* ======================= MODIFIERS ======================= */

  // Allow only vault modifier
  modifier onlyVault() {
    _onlyVault();
    _;
  }

  // Allow only vault's callback contract
  modifier onlyCallback() {
    _onlyCallback();
    _;
  }

  /* ====================== CONSTRUCTOR ====================== */

  /**
    * @notice Initialize and configure vault's store, token approvals and whitelists
    * @param _name Name of vault
    * @param _symbol Symbol for vault token
    * @param _accessManager Address of access manager
    * @param store_ GMXTypes.Store
  */
  constructor (
    string memory _name,
    string memory _symbol,
    address _accessManager,
    GMXTypes.Store memory store_
  ) ERC20(_name, _symbol) AccessManaged(_accessManager) {
    _store.status = GMXTypes.Status.Open;
    _store.shouldEmergencyPause = false;
    _store.shouldDepositLPTokens = false;

    _store.lpAmt = uint256(0);
    _store.ylpAmt = uint256(0);

    _store.lastFeeCollected = block.timestamp;
    _store.refundee = payable(address(0));

    _store.leverage = uint256(store_.leverage);
    _store.delta = store_.delta;
    _store.feePerSecond = uint256(store_.feePerSecond);
    _store.treasury = address(store_.treasury);

    _store.debtRatioStepThreshold = uint256(store_.debtRatioStepThreshold);
    _store.debtRatioUpperLimit = uint256(store_.debtRatioUpperLimit);
    _store.debtRatioLowerLimit = uint256(store_.debtRatioLowerLimit);
    _store.deltaUpperLimit = int256(store_.deltaUpperLimit);
    _store.deltaLowerLimit = int256(store_.deltaLowerLimit);
    _store.minVaultSlippage = uint256(store_.minVaultSlippage);
    _store.liquiditySlippage = uint256(store_.liquiditySlippage);
    _store.swapSlippage = uint256(store_.swapSlippage);
    _store.callbackGasLimit = uint256(store_.callbackGasLimit);
    _store.minAssetValue = uint256(store_.minAssetValue);
    _store.maxAssetValue = uint256(store_.maxAssetValue);

    _store.tokenA = IERC20(store_.tokenA);
    _store.tokenB = IERC20(store_.tokenB);
    _store.lpToken = IERC20(store_.lpToken);
    _store.WNT = IWNT(store_.WNT);
    _store.rewardToken = IERC20(store_.rewardToken);
    _store.ylpToken = IERC20(store_.ylpToken);

    _store.tokenALendingVault = ILendingVault(store_.tokenALendingVault);
    _store.tokenBLendingVault = ILendingVault(store_.tokenBLendingVault);

    _store.vault = IGMXVault(address(this));
    _store.callback = store_.callback;

    _store.chainlinkOracle = IChainlinkOracle(store_.chainlinkOracle);
    _store.gmxOracle = IGMXOracle(store_.gmxOracle);

    _store.exchangeRouter = IExchangeRouter(store_.exchangeRouter);
    _store.router = store_.router;
    _store.depositVault = store_.depositVault;
    _store.withdrawalVault = store_.withdrawalVault;
    _store.roleStore = store_.roleStore;

    _store.masterRouter = store_.masterRouter;
    _store.lpRouter = store_.lpRouter;
    _store.lpManager = store_.lpManager;

    _store.swapRouter = ISwap(store_.swapRouter);

    // Set token approvals for this vault
    _store.tokenA.approve(address(_store.router), type(uint256).max);
    _store.tokenB.approve(address(_store.router), type(uint256).max);
    _store.lpToken.approve(address(_store.router), type(uint256).max);

    _store.tokenA.approve(address(_store.depositVault), type(uint256).max);
    _store.tokenB.approve(address(_store.depositVault), type(uint256).max);

    _store.lpToken.approve(address(_store.withdrawalVault), type(uint256).max);

    _store.tokenA.approve(address(_store.tokenALendingVault), type(uint256).max);
    _store.tokenB.approve(address(_store.tokenBLendingVault), type(uint256).max);

    // TODO set token approvals for additional yield source
  }

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice View vault store data
    * @return GMXTypes.Store
  */
  function store() public view returns (GMXTypes.Store memory) {
    return _store;
  }

  /**
    * @notice Returns the value of each strategy vault share token; equityValue / totalSupply()
    * @return svTokenValue  USD value of each share token in 1e18
  */
  function svTokenValue() public view returns (uint256) {
    return GMXReader.svTokenValue(_store);
  }

  /**
    * @notice Amount of share pending for minting as a form of management fee
    * @return pendingFee in 1e18
  */
  function pendingFee() public view returns (uint256) {
    return GMXReader.pendingFee(_store);
  }

  /**
    * @notice Conversion of equity value to svToken shares
    * @param value Equity value change after deposit in 1e18
    * @param currentEquity Current equity value of vault in 1e18
    * @return sharesAmt in 1e18
  */
  function valueToShares(uint256 value, uint256 currentEquity) public view returns (uint256) {
    return GMXReader.valueToShares(_store, value, currentEquity);
  }

  /**
    * @notice Convert token amount to USD value using price from oracle
    * @param token Token address
    * @param amt Amount in token decimals
    @ @return tokenValue USD value in 1e18
  */
  function convertToUsdValue(address token, uint256 amt) public view returns (uint256) {
    return GMXReader.convertToUsdValue(_store, token, amt);
  }

  /**
    * @notice Return token weights (%) in LP
    @ @return tokenAWeight in 1e18; e.g. 50% = 5e17
    @ @return tokenBWeight in 1e18; e.g. 50% = 5e17
  */
  function tokenWeights() public view returns (uint256, uint256) {
    return GMXReader.tokenWeights(_store);
  }

  /**
    * @notice Returns the total USD value of tokenA & tokenB assets held by the vault
    * @notice Asset = Debt + Equity
    * @return assetValue USD value of total assets in 1e18
  */
  function assetValue() public view returns (uint256) {
    return GMXReader.assetValue(_store);
  }

  /**
    * @notice Returns the USD value of tokenA & tokenB debt held by the vault
    * @notice Asset = Debt + Equity
    * @return tokenADebtValue USD value of tokenA debt in 1e18
    * @return tokenBDebtValue USD value of tokenB debt in 1e18
  */
  function debtValue() public view returns (uint256, uint256) {
    return GMXReader.debtValue(_store);
  }

  /**
    * @notice Returns the USD value of tokenA & tokenB equity held by the vault;
    * @notice Asset = Debt + Equity
    * @return equityValue USD value of total equity in 1e18
  */
  function equityValue() public view returns (uint256) {
    return GMXReader.equityValue(_store);
  }

  /**
    * @notice Returns the amt of tokenA & tokenB assets held by vault
    * @return tokenAAssetAmt in tokenA decimals
    * @return tokenBAssetAmt in tokenB decimals
  */
  function assetAmt() public view returns (uint256, uint256) {
    return GMXReader.assetAmt(_store);
  }

  /**
    * @notice Returns the amt of tokenA & tokenB debt held by vault
    * @return tokenADebtAmt in tokenA decimals
    * @return tokenBDebtAmt in tokenB decimals
  */
  function debtAmt() public view returns (uint256, uint256) {
    return GMXReader.debtAmt(_store);
  }

  /**
    * @notice Returns the amt of LP tokens held by vault
    * @return lpAmt in 1e18
  */
  function lpAmt() public view returns (uint256) {
    return GMXReader.lpAmt(_store);
  }

  /**
    * @notice Returns the current leverage (asset / equity)
    * @return leverage Current leverage in 1e18
  */
  function leverage() public view returns (uint256) {
    return GMXReader.leverage(_store);
  }

  /**
    * @notice Returns the current delta (tokenA equityValue / vault equityValue)
    * @notice Delta refers to the position exposure of this vault's strategy to the
    * underlying volatile asset. Delta can be a negative value
    * @return delta in 1e18 (0 = Neutral, > 0 = Long, < 0 = Short)
  */
  function delta() public view returns (int256) {
    return GMXReader.delta(_store);
  }

  /**
    * @notice Returns the debt ratio (tokenA and tokenB debtValue) / (total assetValue)
    * @notice When assetValue is 0, we assume the debt ratio to also be 0
    * @return debtRatio % in 1e18
  */
  function debtRatio() public view returns (uint256) {
    return GMXReader.debtRatio(_store);
  }

  /**
    * @notice Additional capacity vault that can be deposited to vault based on available lending liquidity
    @ @return additionalCapacity USD value in 1e18
  */
  function additionalCapacity() public view returns (uint256) {
    return GMXReader.additionalCapacity(_store);
  }

  /**
    * @notice Total capacity of vault; additionalCapacity + equityValue
    @ @return capacity USD value in 1e18
  */
  function capacity() public view returns (uint256) {
    return GMXReader.capacity(_store);
  }

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice Deposit asset into vault and mint strategy vault share tokens to user
    * @param dp GMXTypes.DepositParams
  */
  function deposit(GMXTypes.DepositParams memory dp) external payable nonReentrant {
    GMXDeposit.deposit(_store, dp, false);
  }

  /**
    * @notice Deposit native asset (e.g. ETH) into vault and mint strategy vault share tokens to user
    * @notice This function is only function if vault accepts native token
    * @param dp GMXTypes.DepositParams
  */
  function depositNative(GMXTypes.DepositParams memory dp) external payable nonReentrant {
    GMXDeposit.deposit(_store, dp, true);
  }

  /**
    * @notice Withdraws asset from vault and burns strategy vault share tokens from user
    * @param wp GMXTypes.WithdrawParams
  */
  function withdraw(GMXTypes.WithdrawParams memory wp) external payable nonReentrant {
    GMXWithdraw.withdraw(_store, wp);
  }

  /**
    * @notice Emergency withdraw function, enabled only when vault status is Closed, burns
    svToken from user while withdrawing assets from vault to user
    * @param shareAmt Amount of vault token shares to withdraw in 1e18
  */
  function emergencyWithdraw(uint256 shareAmt) external nonReentrant {
    GMXEmergency.emergencyWithdraw(_store, shareAmt);
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Allow only vault
  */
  function _onlyVault() internal view {
    if (msg.sender != address(_store.vault)) revert Errors.OnlyVaultAllowed();
  }

  /**
    * @notice Allow only vault callback contract
  */
  function _onlyCallback() internal view {
    if (msg.sender != address(_store.callback)) revert Errors.OnlyCallbackAllowed();
  }

  /* ================= RESTRICTED FUNCTIONS ================== */

  /**
    * @notice Post deposit operations if adding liquidity is successful to GMX
    * @dev Should be called only after deposit() / depositNative() is called
    * @dev Should be called by approved vault's Callback
    * @param lpAmtReceived Amount of LP tokens received
  */
  function processDeposit(uint256 lpAmtReceived) external nonReentrant restricted {
    GMXDeposit.processDeposit(_store, lpAmtReceived);
  }

  /**
    * @notice Post deposit operations if adding liquidity has been cancelled by GMX
    * @dev To be called only after deposit()/depositNative() is called
    * @dev Should be called by approved vault's Callback
  */
  function processDepositCancellation() external nonReentrant restricted {
    GMXDeposit.processDepositCancellation(_store);
  }

  /**
    * @notice Post deposit operations if after deposit checks failed by GMXChecks.afterDepositChecks()
    * @dev Should be called by approved Keeper after error event is picked up
    * @param executionFee Execution fee passed in to remove liquidity
  */
  function processDepositFailure(
    uint256 executionFee
  ) external payable nonReentrant restricted {
    GMXDeposit.processDepositFailure(_store, executionFee);
  }

  /**
    * @notice Post deposit failure operations
    * @dev To be called after processDepositFailure()
    * @dev Should be called by approved vault's Callback
    * @param tokenAReceived Amount of tokenA received
    * @param tokenBReceived Amount of tokenB received
  */
  function processDepositFailureLiquidityWithdrawal(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external nonReentrant restricted {
    GMXDeposit.processDepositFailureLiquidityWithdrawal(_store, tokenAReceived, tokenBReceived);
  }

  /**
    * @notice Post withdraw operations if removing liquidity is successful from GMX
    * @dev Should be called only after withdraw() is called
    * @dev Should be called by approved vault's Callback
    * @param tokenAReceived Amount of tokenA received
    * @param tokenBReceived Amount of tokenB received
  */
  function processWithdraw(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external nonReentrant restricted {
    GMXWithdraw.processWithdraw(_store, tokenAReceived, tokenBReceived);
  }

  /**
    * @notice Post withdraw operations if removing liquidity has been cancelled by GMX
    * @dev To be called only after withdraw() is called
    * @dev Should be called by approved vault's Callback
  */
  function processWithdrawCancellation() external nonReentrant restricted {
    GMXWithdraw.processWithdrawCancellation(_store);
  }

  /**
    * @notice Post withdraw operations if after withdraw checks failed by GMXChecks.afterWithdrawChecks()
    * @dev Should be called by approved Keeper after error event is picked up
    * @param executionFee Execution fee passed in for adding liquidity
  */
  function processWithdrawFailure(
    uint256 executionFee
  ) external payable nonReentrant restricted {
    GMXWithdraw.processWithdrawFailure(_store, executionFee);
  }

  /**
    * @notice Post withdraw failure operations
    * @dev To be called after processWithdrawFailure()
    * @dev Should be called by approved vault's Callback
    * @param lpAmtReceived Amount of LP tokens received
  */
  function processWithdrawFailureLiquidityAdded(
    uint256 lpAmtReceived
  ) external nonReentrant restricted {
    GMXWithdraw.processWithdrawFailureLiquidityAdded(_store, lpAmtReceived);
  }

  /**
    * @notice Rebalance vault's delta and/or debt ratio by adding liquidity
    * @dev Should be called by approved Keeper
    * @param rap GMXTypes.RebalanceAddParams
  */
  function rebalanceAdd(
    GMXTypes.RebalanceAddParams memory rap
  ) external payable nonReentrant restricted {
    GMXRebalance.rebalanceAdd(_store, rap);
  }

  /**
    * @notice Post rebalance add operations if adding liquidity is successful to GMX
    * @dev To be called after rebalanceAdd()
    * @dev Should be called by approved vault's Callback
    * @param lpAmtReceived Amount of LP tokens received
  */
  function processRebalanceAdd(uint256 lpAmtReceived) external nonReentrant restricted {
    GMXRebalance.processRebalanceAdd(_store, lpAmtReceived);
  }

  /**
    * @notice Post rebalance add operations if adding liquidity has been cancelled by GMX
    * @dev To be called only after rebalanceAdd() is called
    * @dev Should be called by approved vault's Callback
  */
  function processRebalanceAddCancellation() external nonReentrant restricted {
    GMXRebalance.processRebalanceAddCancellation(_store);
  }

  /**
    * @notice Rebalance vault's delta and/or debt ratio by removing liquidity
    * @dev Should be called by approved Keeper
    * @param rrp GMXTypes.RebalanceRemoveParams
  */
  function rebalanceRemove(
    GMXTypes.RebalanceRemoveParams memory rrp
  ) external payable nonReentrant restricted {
    GMXRebalance.rebalanceRemove(_store, rrp);
  }

  /**
    * @notice Post rebalance remove operations if removing liquidity is successful to GMX
    * @dev To be called after rebalanceRemove()
    * @dev Should be called by approved vault's Callback
    * @param tokenAReceived Amount of tokenA received
    * @param tokenBReceived Amount of tokenB received
  */
  function processRebalanceRemove(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external nonReentrant restricted {
    GMXRebalance.processRebalanceRemove(_store, tokenAReceived, tokenBReceived);
  }

  /**
    * @notice Post rebalance remove operations if removing liquidity has been cancelled by GMX
    * @dev To be called only after rebalanceRemove() is called
    * @dev Should be called by approved vault's Callback
  */
  function processRebalanceRemoveCancellation() external nonReentrant restricted {
    GMXRebalance.processRebalanceRemoveCancellation(_store);
  }

  /**
    * @notice Compounds ERC20 token rewards and convert to more LP
    * @dev Assumes that reward tokens are already in vault
    * @dev Always assume that we will do a swap
    * @dev Should be called by approved Keeper
    * @param cp GMXTypes.CompoundParams
  */
  function compound(
    GMXTypes.CompoundParams memory cp
  ) external payable nonReentrant restricted {
    GMXCompound.compound(_store, cp);
  }

  /**
    * @notice Post compound operations if adding liquidity is successful to GMX
    * @dev To be called after processCompound()
    * @dev Should be called by approved vault's Callback
    * @param lpAmtReceived Amount of LP tokens received
  */
  function processCompound(uint256 lpAmtReceived) external nonReentrant restricted {
    GMXCompound.processCompound(_store, lpAmtReceived);
  }

  /**
    * @notice Post compound operations if adding liquidity has been cancelled by GMX
    * @dev To be called after processCompound()
    * @dev Should be called by approved vault's Callback
  */
  function processCompoundCancellation() external nonReentrant restricted {
    GMXCompound.processCompoundCancellation(_store);
  }

  /**
    * @notice Set vault status to Paused
    * @dev To be called only in an emergency situation. Paused will be queued if vault is
    * in any status besides Open
    * @dev Cannot be called if vault status is already in Paused, Resume, Repaid or Closed
    * @dev Should be called by approved Keeper
  */
  function emergencyPause() external nonReentrant restricted {
    GMXEmergency.emergencyPause(_store);
  }

  /**
    * @notice Withdraws LP for all underlying assets to vault, repays all debt owed by vault
    * and set vault status to Repaid
    * @dev To be called only in an emergency situation and when vault status is Paused
    * @dev Can only be called if vault status is Paused
    * @dev Should be called by approved Keeper
  */
  function emergencyRepay() external payable nonReentrant restricted {
    GMXEmergency.emergencyRepay(_store);
  }

  /**
    * @notice Post emergency repay operations to swap if needed and repay debt
    * @dev To be called after emergencyRepay()
    * @dev Should be called by approved vault's Callback
    * @param tokenAReceived Amount of tokenA received
    * @param tokenBReceived Amount of tokenB received
  */
  function processEmergencyRepay(
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external nonReentrant restricted {
    GMXEmergency.processEmergencyRepay(_store, tokenAReceived, tokenBReceived);
  }

  /**
    * @notice Re-borrow assets to vault's strategy based on value of assets in vault and
    * set status of vault back to Paused
    * @dev Can only be called if vault status is Repaid
    * @dev Should be called by approved Keeper
  */
  function emergencyBorrow() external nonReentrant restricted {
    GMXEmergency.emergencyBorrow(_store);
  }

  /**
    * @notice Re-add all assets for liquidity for LP in anticipation of vault resuming
    * @dev Can only be called if vault status is Paused
    * @dev Should be called by approved Owner (Timelock + MultiSig)
  */
  function emergencyResume() external payable nonReentrant restricted {
    GMXEmergency.emergencyResume(_store);
  }

  /**
    * @notice Post emergency resume operations if re-adding liquidity is successful
    * @dev To be called after emergencyResume()
    * @dev Should be called by approved vault's Callback
    * @param lpAmtReceived Amount of LP tokens received
  */
  function processEmergencyResume(uint256 lpAmtReceived) external nonReentrant restricted {
    GMXEmergency.processEmergencyResume(_store, lpAmtReceived);
  }

  /**
    * @notice Post emergency resume operations if re-adding liquidity has been cancelled by GMX
    * @dev To be called after emergencyResume()
    * @dev Should be called by approved vault's Callback
  */
  function processEmergencyResumeCancellation() external nonReentrant restricted {
    GMXEmergency.processEmergencyResumeCancellation(_store);
  }

  /**
    * @notice Permanently shut down vault, allowing emergency withdrawals and sets vault
    * status to Closed
    * @dev Can only be called if vault status is Repaid
    * @dev Note that this is a one-way irreversible action
    * @dev Should be called by approved Owner (Timelock + MultiSig)
  */
  function emergencyClose() external nonReentrant restricted {
    GMXEmergency.emergencyClose(_store);
  }

    /**
    * @notice Emergency update of vault status
    * @dev Can only be called if emergency pause is triggered but vault status is not Paused
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param status GMXTypes.Status
  */
  function emergencyStatusChange(GMXTypes.Status status) external restricted {
    GMXEmergency.emergencyStatusChange(_store, status);
  }

  /**
    * @notice Update treasury address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param treasury Treasury address
  */
  function updateTreasury(address treasury) external restricted {
    _store.treasury = treasury;
    emit TreasuryUpdated(treasury);
  }

  /**
    * @notice Update swap router address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param swapRouter Swap router address
  */
  function updateSwapRouter(address swapRouter) external restricted {
    _store.swapRouter = ISwap(swapRouter);
    emit SwapRouterUpdated(swapRouter);
  }

  /**
    * @notice Update reward token address
    * @dev Should only be called when reward token has changed
    * @param rewardToken Reward token address
  */
  function updateRewardToken(address rewardToken) external restricted {
    _store.rewardToken = IERC20(rewardToken);
    emit RewardTokenUpdated(rewardToken);
  }

  /**
    * @notice Update lending vaults addresses
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param newTokenALendingVault TokenA lending vault address
    * @param newTokenBLendingVault TokenB lending vault address
  */
  function updateLendingVaults(
    address newTokenALendingVault,
    address newTokenBLendingVault
  ) external restricted {
    _store.tokenALendingVault = ILendingVault(newTokenALendingVault);
    _store.tokenBLendingVault = ILendingVault(newTokenBLendingVault);

    _store.tokenA.approve(address(_store.tokenALendingVault), type(uint256).max);
    _store.tokenB.approve(address(_store.tokenBLendingVault), type(uint256).max);

    emit LendingVaultsUpdated(newTokenALendingVault, newTokenBLendingVault);
  }

  /**
    * @notice Update callback address
    * @dev Should only be called once on vault initialization
    * @param callback Callback address
  */
  function updateCallback(address callback) external restricted {
    _store.callback = callback;
    emit CallbackUpdated(callback);
  }

  /**
    * @notice Update management fee per second
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param feePerSecond Fee per second in 1e18
  */
  function updateFeePerSecond(uint256 feePerSecond) external restricted {
    _store.vault.mintFee();
    _store.feePerSecond = feePerSecond;
    emit FeePerSecondUpdated(feePerSecond);
  }

  /**
    * @notice Update strategy leverage, parameter limits and guard checks
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param newLeverage Strategy's leverage in 1e18
    * @param debtRatioStepThreshold Threshold change for debt ratio allowed in 1e4
    * @param debtRatioUpperLimit Upper limit of debt ratio in 1e18
    * @param debtRatioLowerLimit Lower limit of debt ratio in 1e18
    * @param deltaUpperLimit Upper limit of delta in 1e18
    * @param deltaLowerLimit Lower limit of delta in 1e18
  */
  function updateParameterLimits(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external restricted {
    _store.leverage = newLeverage;
    _store.debtRatioStepThreshold = debtRatioStepThreshold;
    _store.debtRatioUpperLimit = debtRatioUpperLimit;
    _store.debtRatioLowerLimit = debtRatioLowerLimit;
    _store.deltaUpperLimit = deltaUpperLimit;
    _store.deltaLowerLimit = deltaLowerLimit;

    emit ParameterLimitsUpdated(
      newLeverage,
      debtRatioStepThreshold,
      debtRatioUpperLimit,
      debtRatioLowerLimit,
      deltaUpperLimit,
      deltaLowerLimit
    );
  }

  /**
    * @notice Update minimum vault slippage
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param minVaultSlippage Minimum slippage value in 1e4
  */
  function updateMinVaultSlippage(uint256 minVaultSlippage) external restricted {
    _store.minVaultSlippage = minVaultSlippage;
    emit MinVaultSlippageUpdated(minVaultSlippage);
  }

  /**
    * @notice Update vault's liquidity slippage
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param liquiditySlippage Minimum slippage value in 1e4
  */
  function updateLiquiditySlippage(uint256 liquiditySlippage) external restricted {
    _store.liquiditySlippage = liquiditySlippage;
    emit LiquiditySlippageUpdated(liquiditySlippage);
  }

  /**
    * @notice Update vault's swap slippage
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param swapSlippage Minimum slippage value in 1e4
  */
  function updateSwapSlippage(uint256 swapSlippage) external restricted {
    _store.swapSlippage = swapSlippage;
    emit SwapSlippageUpdated(swapSlippage);
  }

  /**
    * @notice Update callback gas limit
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param callbackGasLimit Minimum slippage value in 1e4
  */
  function updateCallbackGasLimit(uint256 callbackGasLimit) external restricted {
    _store.callbackGasLimit = callbackGasLimit;
    emit CallbackGasLimitUpdated(callbackGasLimit);
  }

  /**
    * @notice Update Chainlink oracle contract address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of chainlink oracle
  */
  function updateChainlinkOracle(address addr) external restricted {
    _store.chainlinkOracle = IChainlinkOracle(addr);
    emit ChainlinkOracleUpdated(addr);
  }

  /**
    * @notice Update GMX oracle contract address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of GMX oracle
  */
  function updateGMXOracle(address addr) external restricted {
    _store.gmxOracle = IGMXOracle(addr);
    emit GMXOracleUpdated(addr);
  }

  /**
    * @notice Update GMX exchange router contract address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of exchange router
  */
  function updateGMXExchangeRouter(address addr) external restricted {
    _store.exchangeRouter = IExchangeRouter(addr);
    emit GMXExchangeRouterUpdated(addr);
  }

  /**
    * @notice Update GMX router contract address and approve it for token transfers
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of router
  */
  function updateGMXRouter(address addr) external restricted {
    _store.router = addr;

    _store.tokenA.approve(address(_store.router), type(uint256).max);
    _store.tokenB.approve(address(_store.router), type(uint256).max);
    _store.lpToken.approve(address(_store.router), type(uint256).max);

    emit GMXRouterUpdated(addr);
  }

  /**
    * @notice Update GMX deposit vault contract address and approve it for token transfers
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of deposit vault
  */
  function updateGMXDepositVault(address addr) external restricted {
    _store.depositVault = addr;

    _store.tokenA.approve(address(_store.depositVault), type(uint256).max);
    _store.tokenB.approve(address(_store.depositVault), type(uint256).max);

    emit GMXDepositVaultUpdated(addr);
  }

  /**
    * @notice Update GMX withdrawal vault contract address and approve it for token transfers
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of withdrawal vault
  */
  function updateGMXWithdrawalVault(address addr) external restricted {
    _store.withdrawalVault = addr;

    _store.lpToken.approve(address(_store.router), type(uint256).max);

    emit GMXWithdrawalVaultUpdated(addr);
  }

  /**
    * @notice Update GMX role store contract address
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param addr Address of role store
  */
  function updateGMXRoleStore(address addr) external restricted {
    _store.roleStore = addr;

    emit GMXRoleStoreUpdated(addr);
  }

  // TODO
  // Logic for additional yield
  // To add in GMXWorker logic to deposit/withdraw for additional yield
  // To include tracking of YLPAmt as well if depositing for additional yield
  // function updateShouldDepositLPTokens()
  // function updateYlpToken()
  // function updateMasterRouter()
  // function updateLpRouter()
  // function updateLpManager()

  /**
    * @notice Update minimum asset value per vault deposit/withdrawal
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param value Minimum value
  */
  function updateMinAssetValue(uint256 value) external restricted {
    _store.minAssetValue = value;

    emit MinAssetValueUpdated(value);
  }

  /**
    * @notice Update maximum asset value per vault deposit/withdrawal
    * @dev Should be called by approved Owner (Timelock + MultiSig)
    * @param value Maximum value
  */
  function updateMaxAssetValue(uint256 value) external restricted {
    _store.maxAssetValue = value;

    emit MaxAssetValueUpdated(value);
  }

  /**
    * @notice Mint vault token shares as management fees to protocol treasury
  */
  function mintFee() public onlyVault {
    GMXChecks.beforeMintFeeChecks(_store);

    _mint(_store.treasury, GMXReader.pendingFee(_store));
    _store.lastFeeCollected = block.timestamp;

    emit FeeMinted(GMXReader.pendingFee(_store));
  }

  /**
    * @notice Mints vault token shares to user
    * @dev Should only be called by vault
    * @param to Receiver of the minted vault tokens
    * @param amt Amount of minted vault tokens
  */
  function mint(address to, uint256 amt) external onlyVault {
    _mint(to, amt);
  }

  /**
    * @notice Burns vault token shares from user
    * @dev Should only be called by vault
    * @param to Address's vault tokens to burn
    * @param amt Amount of vault tokens to burn
  */
  function burn(address to, uint256 amt) external onlyVault {
    _burn(to, amt);
  }

  /**
    * @notice Emit a callback event
    * @dev Should only be called by vault's callback contract
    * @param callbackType GMXTypes.CallbackType
    * @param depositKey bytes32 deposit key from GMX
    * @param withdrawKey bytes32 withdraw key from GMX
    * @param lpAmtReceived LP amount received in uint256
    * @param tokenAReceived LP amount received in uint256
    * @param tokenBReceived LP amount received in uint256
  */
  function emitProcessEvent(
    GMXTypes.CallbackType callbackType,
    bytes32 depositKey,
    bytes32 withdrawKey,
    uint256 lpAmtReceived,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external onlyCallback {
    if (callbackType == GMXTypes.CallbackType.ProcessDeposit)
      emit ProcessDeposit(depositKey, lpAmtReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessRebalanceAdd)
      emit ProcessRebalanceAdd(depositKey, lpAmtReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessCompound)
      emit ProcessCompound(depositKey, lpAmtReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessWithdrawFailureLiquidityAdded)
      emit ProcessWithdrawFailureLiquidityAdded(depositKey, lpAmtReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessEmergencyResume)
      emit ProcessEmergencyResume(depositKey, lpAmtReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessDepositCancellation)
      emit ProcessDepositCancellation(depositKey);
    if (callbackType == GMXTypes.CallbackType.ProcessRebalanceAddCancellation)
      emit ProcessRebalanceAddCancellation(depositKey);
    if (callbackType == GMXTypes.CallbackType.ProcessCompoundCancellation)
      emit ProcessCompoundCancellation(depositKey);
    if (callbackType == GMXTypes.CallbackType.ProcessEmergencyResumeCancellation)
      emit ProcessEmergencyResumeCancellation(depositKey);
    if (callbackType == GMXTypes.CallbackType.ProcessWithdraw)
      emit ProcessWithdraw(withdrawKey, tokenAReceived, tokenBReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessRebalanceRemove)
      emit ProcessRebalanceRemove(withdrawKey, tokenAReceived, tokenBReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessDepositFailureLiquidityWithdrawal)
      emit ProcessDepositFailureLiquidityWithdrawal(withdrawKey, tokenAReceived, tokenBReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessEmergencyRepay)
      emit ProcessEmergencyRepay(withdrawKey, tokenAReceived, tokenBReceived);
    if (callbackType == GMXTypes.CallbackType.ProcessWithdrawCancellation)
      emit ProcessWithdrawCancellation(withdrawKey);
    if (callbackType == GMXTypes.CallbackType.ProcessRebalanceRemoveCancellation)
      emit ProcessRebalanceRemoveCancellation(withdrawKey);
  }

  /* ================== FALLBACK FUNCTIONS =================== */

  /**
    * @notice Fallback function to receive native token sent to this contract
    * @dev To refund refundee any ETH received from GMX for unused execution fees
  */
  receive() external payable {
    if (msg.sender == _store.depositVault || msg.sender == _store.withdrawalVault) {
      uint256 _balance = address(this).balance;
      (bool success, ) = _store.refundee.call{value: _balance}("");
      if (!success) {
        _store.WNT.deposit{value: _balance}();
        IERC20(address(_store.WNT)).safeTransfer(_store.refundee, _balance);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { GMXTypes } from "./GMXTypes.sol";
import { GMXReader } from "./GMXReader.sol";
import { GMXChecks } from "./GMXChecks.sol";
import { GMXManager } from "./GMXManager.sol";
import { GMXProcessWithdraw } from "./GMXProcessWithdraw.sol";
import { GMXEmergency } from "./GMXEmergency.sol";

/**
  * @title GMXWithdraw
  * @author Steadefi
  * @notice Re-usable library functions for withdraw operations for Steadefi leveraged vaults
*/
library GMXWithdraw {

  using SafeERC20 for IERC20;
  using SafeCast for uint256;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event WithdrawCreated(address indexed user, uint256 shareAmt);
  event WithdrawCompleted(
    address indexed user,
    address token,
    uint256 tokenAmt
  );
  event WithdrawCancelled(address indexed user);
  event WithdrawFailed(bytes reason);
  event WithdrawFailureProcessed();
  event WithdrawFailureLiquidityAddedProcessed();

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function withdraw(
    GMXTypes.Store storage self,
    GMXTypes.WithdrawParams memory wp
  ) external {
    self.refundee = payable(msg.sender);

    GMXTypes.HealthParams memory _hp;

    _hp.lpAmtBefore = GMXReader.lpAmt(self);
    (_hp.tokenAAssetAmtBefore, _hp.tokenBAssetAmtBefore) = GMXReader.assetAmt(self);

    GMXTypes.WithdrawCache memory _wc;

    _wc.user = payable(msg.sender);

    // Mint fee before calculating shareRatio for correct totalSupply
    self.vault.mintFee();

    // Calculate user share ratio
    _wc.shareRatio = wp.shareAmt
      * SAFE_MULTIPLIER
      / IERC20(address(self.vault)).totalSupply();
    _wc.lpAmt = _wc.shareRatio
      * GMXReader.lpAmt(self)
      / SAFE_MULTIPLIER;
    _wc.withdrawValue = _wc.lpAmt
      * self.gmxOracle.getLpTokenValue(
        address(self.lpToken),
        address(self.tokenA),
        address(self.tokenA),
        address(self.tokenB),
        true,
        false
      )
      / SAFE_MULTIPLIER;

    _wc.withdrawParams = wp;
    _wc.healthParams = _hp;

    (
      uint256 _repayTokenAAmt,
      uint256 _repayTokenBAmt
    ) = GMXManager.calcRepay(self, _wc.shareRatio);

    _wc.repayParams.repayTokenAAmt = _repayTokenAAmt;
    _wc.repayParams.repayTokenBAmt = _repayTokenBAmt;

    self.withdrawCache = _wc;

    GMXChecks.beforeWithdrawChecks(self);

    // Calculate minimum amount of assets expected based on shares to burn
    // and vault slippage value passed in. We calculate this after `beforeWithdrawChecks()`
    // to ensure the vault slippage passed in meets the `minVaultSlippage`.
    // minAssetsAmt = userVaultSharesAmt * vaultSvTokenValue / assetToReceiveValue x slippage
    _wc.minAssetsAmt = wp.shareAmt
      * GMXReader.svTokenValue(self)
      / self.chainlinkOracle.consultIn18Decimals(address(wp.token))
      * (10000 - wp.slippage) / 10000;

    // minAssetsAmt is in 1e18. If asset decimals is less than 18, e.g. USDC,
    // we need to normalize the decimals of minAssetsAmt
    if (IERC20Metadata(wp.token).decimals() < 18)
      _wc.minAssetsAmt /= 10 ** (18 - IERC20Metadata(wp.token).decimals());

    // Burn user shares
    self.vault.burn(self.withdrawCache.user, self.withdrawCache.withdrawParams.shareAmt);

    self.status = GMXTypes.Status.Withdraw;

    // Account LP tokens removed from vault
    self.lpAmt -= _wc.lpAmt;

    GMXTypes.RemoveLiquidityParams memory _rlp;

    if (self.delta == GMXTypes.Delta.Long) {
      // If delta strategy is Long, remove all in tokenB to make it more
      // efficent to repay tokenB debt as Long strategy only borrows tokenB
      address[] memory _tokenASwapPath = new address[](1);
      _tokenASwapPath[0] = address(self.lpToken);
      _rlp.tokenASwapPath = _tokenASwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _wc.lpAmt,
        address(self.tokenB),
        address(self.tokenB),
        self.liquiditySlippage
      );
    } else if (self.delta == GMXTypes.Delta.Short) {
      // If delta strategy is Short, remove all in tokenA to make it more
      // efficent to repay tokenA debt as Short strategy only borrows tokenA
      address[] memory _tokenBSwapPath = new address[](1);
      _tokenBSwapPath[0] = address(self.lpToken);
      _rlp.tokenBSwapPath = _tokenBSwapPath;

      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _rlp.lpAmt,
        address(self.tokenA),
        address(self.tokenA),
        self.liquiditySlippage
      );
    } else {
      // If delta strategy is Neutral, withdraw in both tokenA/B
      (_rlp.minTokenAAmt, _rlp.minTokenBAmt) = GMXManager.calcMinTokensSlippageAmt(
        self,
        _wc.lpAmt,
        address(self.tokenA),
        address(self.tokenB),
        self.liquiditySlippage
      );
    }

    _rlp.lpAmt = _wc.lpAmt;
    _rlp.executionFee = wp.executionFee;

    _wc.withdrawKey = GMXManager.removeLiquidity(
      self,
      _rlp
    );

    // Add withdrawKey to store
    self.withdrawCache = _wc;

    emit WithdrawCreated(
      _wc.user,
      _wc.withdrawParams.shareAmt
    );
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processWithdraw(
    GMXTypes.Store storage self,
    uint256 tokenAReceived,
    uint256 tokenBReceived
  ) external {
    GMXChecks.beforeProcessWithdrawChecks(self);

    // As we convert LP tokens in withdraw() to receive assets in as:
    // Delta Long: 100% tokenB
    // Delta Short: 100% tokenA
    // Delta Neutral: tokenA/B in tokenWeights in GM pool
    // The tokenAReceived/tokenBReceived values could both be amounts of the same token.
    // As such we look to "sanitise" the data here such that for e.g., if we had wanted only
    // tokenA from withdrawal of the LP tokens, we will add tokenBReceived to tokenAReceived and
    // clear out tokenBReceived to 0.
    GMXTypes.WithdrawCache memory _wc = self.withdrawCache;

    if (self.delta == GMXTypes.Delta.Long) {
      // We withdraw assets all in tokenB
      _wc.tokenAReceived = 0;
      _wc.tokenBReceived = tokenAReceived + tokenBReceived;
    } else if (self.delta == GMXTypes.Delta.Short) {
      // We withdraw assets all in tokenA
      _wc.tokenAReceived = tokenAReceived + tokenBReceived;
      _wc.tokenBReceived = 0;
    } else {
      // Both tokenA/B amount received are "correct" for their respective tokens
      _wc.tokenAReceived = tokenAReceived;
      _wc.tokenBReceived = tokenBReceived;
    }

    self.withdrawCache = _wc;

    GMXTypes.HealthParams memory _hp = _wc.healthParams;

    // Compute asset value of vault before withdrawal
    uint256 _assetValueBefore = _hp.lpAmtBefore
      * self.gmxOracle.getLpTokenValue(
        address(self.lpToken),
        address(self.tokenA),
        address(self.tokenA),
        address(self.tokenB),
        true,
        false
      ) / SAFE_MULTIPLIER;

    // Compute equity, debtRatio and delta of vault before withdrawal
    if (_assetValueBefore > 0) {
      // As vault has not repayed debt at this stage yet, the debt amount
      // and value are still "before" withdrawal event is complete
      (uint256 _tokenADebtValue, uint256 _tokenBDebtValue) = GMXReader.debtValue(self);
      uint256 _debtValueBefore = _tokenADebtValue + _tokenBDebtValue;

      _hp.equityBefore = _assetValueBefore - _debtValueBefore;

      _hp.debtRatioBefore = _debtValueBefore
        * SAFE_MULTIPLIER
        / _assetValueBefore;

      (_hp.tokenADebtAmtBefore,) = GMXReader.debtAmt(self);

      if (_hp.tokenAAssetAmtBefore == 0 &&  _hp.tokenADebtAmtBefore == 0) {
        _hp.deltaBefore = 0;
      } else {
        bool _isPositive = _hp.tokenAAssetAmtBefore >= _hp.tokenADebtAmtBefore;

        uint256 _unsignedDelta = _isPositive ?
          _hp.tokenAAssetAmtBefore - _hp.tokenADebtAmtBefore :
          _hp.tokenADebtAmtBefore - _hp.tokenAAssetAmtBefore;

        int256 signedDelta = (_unsignedDelta
          * self.chainlinkOracle.consultIn18Decimals(address(self.tokenA))
          / _hp.equityBefore).toInt256();

        _hp.deltaBefore = _isPositive ? signedDelta : -signedDelta;
      }
    } else {
      _hp.equityBefore = 0;
      _hp.debtRatioBefore = 0;
      _hp.deltaBefore = 0;
    }

    self.withdrawCache.healthParams = _hp;

    // We transfer the core logic of this function to GMXProcessWithdraw.processWithdraw()
    // to allow try/catch here to catch for any issues such as any token swaps failing or
    // debt repayment failing, or any checks in afterWithdrawChecks() failing.
    // If there are any issues, a WithdrawFailed event will be emitted and processWithdrawFailure()
    // should be triggered to refund assets accordingly and reset the vault status to Open again.
    try GMXProcessWithdraw.processWithdraw(self) {
      // If native token is being withdrawn, we convert wrapped to native
      if (self.withdrawCache.withdrawParams.token == address(self.WNT)) {
        self.WNT.withdraw(self.withdrawCache.assetsToUser);
        (bool success, ) = self.withdrawCache.user.call{
          value: self.withdrawCache.assetsToUser
        }("");
        // if native transfer unsuccessful, send WNT back to user
        if (!success) {
          self.WNT.deposit{value: self.withdrawCache.assetsToUser}();
          IERC20(address(self.WNT)).safeTransfer(
            self.withdrawCache.user,
            self.withdrawCache.assetsToUser
          );
        }
      } else {
        // Transfer requested withdraw asset to user
        IERC20(self.withdrawCache.withdrawParams.token).safeTransfer(
          self.withdrawCache.user,
          self.withdrawCache.assetsToUser
        );
      }

      self.status = GMXTypes.Status.Open;

      // Check if there is an emergency pause queued
      if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

      emit WithdrawCompleted(
        self.withdrawCache.user,
        self.withdrawCache.withdrawParams.token,
        self.withdrawCache.assetsToUser
      );
    } catch (bytes memory reason) {
      self.status = GMXTypes.Status.Withdraw_Failed;

      emit WithdrawFailed(reason);
    }
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processWithdrawCancellation(
    GMXTypes.Store storage self
  ) external {
    GMXChecks.beforeProcessWithdrawCancellationChecks(self);

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit WithdrawCancelled(self.withdrawCache.user);
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processWithdrawFailure(
    GMXTypes.Store storage self,
    uint256 executionFee
  ) external {
    GMXChecks.beforeProcessWithdrawFailureChecks(self);

    self.refundee = payable(msg.sender);

    // Refund users their burnt shares
    self.vault.mint(self.withdrawCache.user, self.withdrawCache.withdrawParams.shareAmt);

    // Re-add liquidity using all available tokenA/B in vault
    GMXTypes.AddLiquidityParams memory _alp;

    _alp.tokenAAmt = self.withdrawCache.tokenAReceived;
    _alp.tokenBAmt = self.withdrawCache.tokenBReceived;

    // Calculate slippage
    uint256 _depositValue = GMXReader.convertToUsdValue(
      self,
      address(self.tokenA),
      self.withdrawCache.tokenAReceived
    )
    + GMXReader.convertToUsdValue(
      self,
      address(self.tokenB),
      self.withdrawCache.tokenBReceived
    );

    _alp.minMarketTokenAmt = GMXManager.calcMinMarketSlippageAmt(
      self,
      _depositValue,
      self.liquiditySlippage
    );
    _alp.executionFee = executionFee;

    // Re-add liquidity with all tokenA/tokenB in vault
    self.withdrawCache.depositKey = GMXManager.addLiquidity(
      self,
      _alp
    );

    emit WithdrawFailureProcessed();
  }

  /**
    * @notice @inheritdoc GMXVault
    * @param self GMXTypes.Store
  */
  function processWithdrawFailureLiquidityAdded(
    GMXTypes.Store storage self,
    uint256 lpAmtReceived
  ) external {
    GMXChecks.beforeProcessWithdrawFailureLiquidityAdded(self);

    self.lpAmt += lpAmtReceived;

    self.status = GMXTypes.Status.Open;

    // Check if there is an emergency pause queued
    if (self.shouldEmergencyPause) GMXEmergency.emergencyPause(self);

    emit WithdrawFailureLiquidityAddedProcessed();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IExchangeRouter } from  "../../interfaces/protocols/gmx/IExchangeRouter.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { GMXTypes } from "./GMXTypes.sol";

library GMXWorker {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event LiquidityAdded(uint256 tokenAAmt, uint256 tokenBAmt);
  event LiquidityRemoved(uint256 lpAmt);
  event ExactTokensForTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );
  event TokensForExactTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @dev Add strategy's tokens for liquidity and receive LP tokens
    * @param self Vault store data
    * @param alp GMXTypes.AddLiquidityParams
    * @return depositKey Hashed key of created deposit in bytes32
  */
  function addLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.AddLiquidityParams memory alp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{ value: alp.executionFee }(
      self.depositVault,
      alp.executionFee
    );

    // Send tokens
    self.exchangeRouter.sendTokens(
      address(self.tokenA),
      self.depositVault,
      alp.tokenAAmt
    );

    self.exchangeRouter.sendTokens(
      address(self.tokenB),
      self.depositVault,
      alp.tokenBAmt
    );

    // Create deposit
    IExchangeRouter.CreateDepositParams memory _cdp =
      IExchangeRouter.CreateDepositParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0),
        market: address(self.lpToken),
        initialLongToken: address(self.tokenA),
        initialShortToken: address(self.tokenB),
        longTokenSwapPath: new address[](0),
        shortTokenSwapPath: new address[](0),
        minMarketTokens: alp.minMarketTokenAmt,
        shouldUnwrapNativeToken: false,
        executionFee: alp.executionFee,
        callbackGasLimit: self.callbackGasLimit
      });

    emit LiquidityAdded(alp.tokenAAmt, alp.tokenBAmt);

    return self.exchangeRouter.createDeposit(_cdp);
  }

  /**
    * @dev Remove liquidity of strategy's LP token and receive underlying tokens
    * @param self Vault store data
    * @param rlp GMXTypes.RemoveLiquidityParams
    * @return withdrawKey Hashed key of created withdraw in bytes32
  */
  function removeLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.RemoveLiquidityParams memory rlp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{value: rlp.executionFee }(
      self.withdrawalVault,
      rlp.executionFee
    );

    // Send GM LP tokens
    self.exchangeRouter.sendTokens(
      address(self.lpToken),
      self.withdrawalVault,
      rlp.lpAmt
    );

    // Create withdrawal
    IExchangeRouter.CreateWithdrawalParams memory _cwp =
      IExchangeRouter.CreateWithdrawalParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0),
        market: address(self.lpToken),
        longTokenSwapPath: rlp.tokenASwapPath,
        shortTokenSwapPath: rlp.tokenBSwapPath,
        minLongTokenAmount: rlp.minTokenAAmt,
        minShortTokenAmount: rlp.minTokenBAmt,
        shouldUnwrapNativeToken: false,
        executionFee: rlp.executionFee,
        callbackGasLimit: self.callbackGasLimit
      });

    emit LiquidityRemoved(rlp.lpAmt);

    return self.exchangeRouter.createWithdrawal(_cwp);
  }

  /**
    * @dev Swap exact amount of tokenIn for as many amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountOut Amount of tokens out in token decimals
  */
  function swapExactTokensForTokens(
    GMXTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit ExactTokensForTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapExactTokensForTokens(sp);
  }

  /**
    * @dev Swap as little tokenIn for exact amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountIn Amount of tokens in in token decimals
  */
  function swapTokensForExactTokens(
    GMXTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit TokensForExactTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapTokensForExactTokens(sp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ===================== AUTHORIZATION ===================== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyCallbackAllowed();
  error OnlyBorrowerAllowed();
  error OnlyYieldBoosterAllowed();
  error OnlyMinterAllowed();
  error OnlyTokenManagerAllowed();

  /* ======================== GENERAL ======================== */

  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
  error ReceiverNotApproved();

  /* ========================= ORACLE ======================== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ======================== LENDING ======================== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InvalidInterestRateModel();
  error InterestRateModelExceeded();
  error ApprovedBorrowersExceededMaximum();
  error PerformanceFeeExceeded();
  error ApproveBorrowerFailure();
  error RevokeBorrowerFailure();

  /* ===================== VAULT GENERAL ===================== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientVaultSlippageAmount();
  error NotAllowedInCurrentVaultStatus();
  error AddressIsBlocked();

  /* ===================== VAULT DEPOSIT ===================== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositValue();
  error ExcessiveDepositValue();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositNotAllowedWhenEquityIsZero();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error DepositCancellationCallback();

  /* ===================== VAULT WITHDRAW ==================== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error ExcessiveWithdrawValue();
  error InsufficientWithdrawBalance();
  error InvalidEquityAfterWithdraw();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error WithdrawalCancellationCallback();
  error NoAssetsToEmergencyRefund();

  /* ==================== VAULT REBALANCE ==================== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceParameters();

  /* ==================== VAULT CALLBACKS ==================== */

  error InvalidCallbackHandler();

  /* ========================= FARMS ========================== */

  error FarmDoesNotExist();
  error FarmNotActive();
  error EndTimeMustBeGreaterThanCurrentTime();
  error MaxMultiplierMustBeGreaterThan1x();
  error InsufficientRewardsBalance();
  error InvalidRate();
  error InvalidEsSDYSplit();

  /* ========================= TOKENS ========================= */

  error RedeemEntryDoesNotExist();
  error InvalidRedeemAmount();
  error InvalidRedeemDuration();
  error VestingPeriodNotOver();
  error InvalidAmount();
  error UnauthorisedAllocateAmount();
  error InvalidRatioValues();
  error DeallocationFeeTooHigh();
  error TransferNotAllowed();
  error InvalidUpdateTransferWhitelistAddress();

  /* ========================= BRIDGE ========================= */

  error OnlyNetworkAllowed();
  error InvalidFeeToken();
  error InsufficientFeeTokenBalance();

  /* ========================= CLAIMS ========================= */

  error AddressAlreadyClaimed();
  error MerkleVerificationFailed();
  error EpochNotFound();

  /* ========================= DISITRBUTOR ========================= */

  error InvalidNumberOfVaults();
}