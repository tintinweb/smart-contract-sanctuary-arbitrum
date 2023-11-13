// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ArbGasInfo} from "./ArbGasInfo.sol";

import {ExecutionLogic, IExecutionLogic, IProtocolFees} from "../ExecutionLogic.sol";

/// @title ExecutionLogicArbitrum
/// @notice This contract holds the logic for executing any transactions
/// to the target contract or batch txs in multicall
contract ExecutionLogicArbitrum is ExecutionLogic {
    /// @dev A special arbitrum contract used to calculate the gas that
    /// will be sent to the L1 network
    ArbGasInfo private constant ARB_GAS_ORACLE =
        ArbGasInfo(0x000000000000000000000000000000000000006C);

    constructor(IProtocolFees protocolFees) ExecutionLogic(protocolFees) {}

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IExecutionLogic
    function taxedMulticall(
        bytes[] calldata data
    ) external payable override onlyOwner {
        uint256 gasUsed = gasleft();

        _multicall(data);

        uint256 l1GasFees = ARB_GAS_ORACLE.getCurrentTxL1GasFees();

        unchecked {
            gasUsed -= gasleft();
        }

        _transferDittoFee(gasUsed, l1GasFees, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {DittoFeeBase, IProtocolFees} from "../libraries/DittoFeeBase.sol";
import {BaseContract} from "../libraries/BaseContract.sol";
import {MulticallBase} from "../libraries/MulticallBase.sol";

import {IExecutionLogic} from "../interfaces/IExecutionLogic.sol";

/// @title ExecutionLogic
/// @notice This contract holds the logic for executing any transactions
/// to the target contract or batch txs in multicall
contract ExecutionLogic is
    IExecutionLogic,
    BaseContract,
    IERC721Receiver,
    MulticallBase,
    DittoFeeBase
{
    // =========================
    // Constructor
    // =========================

    constructor(IProtocolFees protocolFees) DittoFeeBase(protocolFees) {}

    // =========================
    // Main functions
    // =========================

    /// @notice Allows a contract to handle receiving ERC721 tokens.
    /// @dev Returns the magic value to signal a successful receipt.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc IExecutionLogic
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable onlyVaultItself returns (bytes memory) {
        if (target == address(this)) {
            revert ExecutionLogic_ExecuteTargetCannotBeAddressThis();
        }

        // If `vault` does not have enough value on baalnce -> revert
        (bool success, bytes memory returnData) = target.call{value: value}(
            data
        );

        // If unsuccess occured -> revert with target address and calldata for it
        // to make it easier to understand the cause of the error
        if (!success) {
            revert ExecutionLogic_ExecuteCallReverted(target, data);
        }

        emit DittoExecute(target, data);

        return returnData;
    }

    /// @inheritdoc IExecutionLogic
    function multicall(
        bytes[] calldata data
    ) external payable onlyOwnerOrVaultItself {
        _multicall(data);
    }

    /// @inheritdoc IExecutionLogic
    function taxedMulticall(
        bytes[] calldata data
    ) external payable virtual onlyOwner {
        uint256 gasUsed = gasleft();

        _multicall(data);

        unchecked {
            gasUsed -= gasleft();
        }

        _transferDittoFee(gasUsed, 0, true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IProtocolFees} from "../../IProtocolFees.sol";
import {TransferHelper} from "./utils/TransferHelper.sol";

/// @title DittoFeeBase
contract DittoFeeBase {
    // =========================
    // Constructor
    // =========================

    IProtocolFees internal immutable _protocolFees;

    uint256 internal constant E18 = 1e18;

    /// @notice Sets the addresses of the `automate` and `gelato` upon deployment.
    /// @param protocolFees:
    constructor(IProtocolFees protocolFees) {
        _protocolFees = protocolFees;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when ditto fee is transferred.
    /// @param dittoFee The amount of Ditto fee transferred.
    event DittoFeeTransfer(uint256 dittoFee);

    // =========================
    // Helpers
    // =========================

    /// @dev Transfers the specified `dittoFee` amount to the `treasury`.
    /// @param dittoFee Amount of value to transfer.
    /// @param rollupFee Amount of roll up fee.
    /// @param isInstant Bool to indicate if the fee to be paid for instant action:
    function _transferDittoFee(
        uint256 dittoFee,
        uint256 rollupFee,
        bool isInstant
    ) internal {
        address treasury;
        uint256 feeGasBps;
        uint256 feeFix;

        if (isInstant) {
            (treasury, feeGasBps, feeFix) = _protocolFees
                .getInstantFeesAndTreasury();
        } else {
            (treasury, feeGasBps, feeFix) = _protocolFees
                .getAutomationFeesAndTreasury();
        }

        // if treasury is setted
        if (treasury != address(0)) {
            unchecked {
                // take percent of gasUsed + fixed fee
                dittoFee =
                    (((dittoFee + rollupFee) * feeGasBps) / E18) +
                    feeFix;
            }

            if (dittoFee > 0) {
                TransferHelper.safeTransferNative(treasury, dittoFee);

                emit DittoFeeTransfer(dittoFee);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlLib} from "./AccessControlLib.sol";
import {Constants} from "./Constants.sol";

/// @title BaseContract
/// @notice A base contract that provides common access control features.
/// @dev This contract integrates with AccessControlLib to provide role-based access
/// control and ownership checks. Contracts inheriting from this can use its modifiers
/// for common access restrictions.
contract BaseContract {
    // =========================
    // Error
    // =========================

    /// @notice Thrown when an account is not authorized to perform a specific action.
    error UnauthorizedAccount(address account);

    // =========================
    // Modifiers
    // =========================

    /// @dev Modifier that checks if an account has a specific `role`
    /// or is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if the conditions are not met.
    modifier onlyRoleOrOwner(bytes32 role) {
        _checkRole(role, msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwner() {
        _checkOnlyOwner(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyVaultItself() {
        _checkOnlyVaultItself(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner
    /// or the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwnerOrVaultItself() {
        _checkOnlyOwnerOrVaultItself(msg.sender);

        _;
    }

    // =========================
    // Internal function
    // =========================

    /// @dev Checks if the given `account` possesses the specified `role` or is the owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    function _checkRole(bytes32 role, address account) internal view virtual {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (
            !((msg.sender == AccessControlLib.getOwner()) ||
                _hasRole(s, role, account))
        ) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyVaultItself(address account) internal view virtual {
        if (account != address(this)) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwnerOrVaultItself(
        address account
    ) internal view virtual {
        if (account == address(this)) {
            return;
        }

        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwner(address account) internal view virtual {
        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    /// @param s The storage reference for roles from AccessControlLib.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    /// @return True if the account possesses the role, false otherwise.
    function _hasRole(
        AccessControlLib.RolesStorage storage s,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return s.roles[role][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title MulticallBase
/// @dev Contract that provides a base functionality for making multiple calls in a single transaction.
contract MulticallBase {
    /// @notice Executes multiple calls in a single transaction.
    /// @dev Iterates through an array of call data and executes each call.
    /// If any call fails, the function reverts with the original error message.
    /// @param data An array of call data to be executed.
    function _multicall(bytes[] calldata data) internal {
        uint256 length = data.length;

        bool success;

        for (uint256 i; i < length; ) {
            (success, ) = address(this).call(data[i]);

            // If unsuccess occured -> revert with original error message
            if (!success) {
                assembly ("memory-safe") {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            unchecked {
                // increment loop counter
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IExecutionLogic - ExecutionLogic interface
/// @notice This interface defines the structure for an ExecutionLogic contract.
interface IExecutionLogic {
    // =========================
    // Events
    // =========================

    /// @notice Emits when an execute action is performed.
    /// @param target The address of the contract where the call was made.
    /// @param data The calldata that was executed to `target`.
    event DittoExecute(address indexed target, bytes data);

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when target address for `execute` function is equal vault's address.
    error ExecutionLogic_ExecuteTargetCannotBeAddressThis();

    /// @notice Thrown when the `execute` call has reverted.
    /// @param target The address of the contract where the call was made.
    /// @param data The calldata that caused the revert.
    error ExecutionLogic_ExecuteCallReverted(address target, bytes data);

    // =========================
    // Main functions
    // =========================

    /// @notice Executes a transaction on a `target` contract.
    /// @dev The `target` cannot be the address of this contract.
    /// @param target The address of the contract on which the transaction will be executed.
    /// @param value The amount of Ether to send along with the transaction.
    /// @param data The call data for the transaction.
    /// @return returnData The raw return data from the function call.
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice Executes multiple transactions in a single batch.
    /// @dev All transactions are executed on this contract's address.
    /// @dev If a transaction within the batch fails, it will revert.
    /// @param data An array of transaction data.
    function multicall(bytes[] calldata data) external payable;

    /// @notice Executes multiple transactions in a single batch with transfer of Ditto fee.
    /// @dev All transactions are executed on this contract's address.
    /// @dev If a transaction within the batch fails, it will revert.
    /// @param data An array of transaction data.
    function taxedMulticall(bytes[] calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IProtocolFees - ProtocolFees interface
interface IProtocolFees {
    // =========================
    // Events
    // =========================

    /// @notice Emits when instant fees are changed.
    event InstantFeesChanged(uint64 instantFeeGasBps, uint192 instantFeeFix);

    /// @notice Emits when automation fees are changed.
    event AutomationFeesChanged(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    );

    /// @notice Emits when treasury address are changed.
    event TreasuryChanged(address treasury);

    // =========================
    // Getters
    // =========================

    /// @notice Gets instant fees.
    /// @return treasury address of the ditto treasury
    /// @return instantFeeGasBps instant fee in gas bps
    /// @return instantFeeFix fixed fee for instant calls
    function getInstantFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 instantFeeGasBps,
            uint256 instantFeeFix
        );

    /// @notice Gets automation fees.
    /// @return treasury address of the ditto treasury
    /// @return automationFeeGasBps automation fee in gas bps
    /// @return automationFeeFix fixed fee for automation calls
    function getAutomationFeesAndTreasury()
        external
        view
        returns (
            address treasury,
            uint256 automationFeeGasBps,
            uint256 automationFeeFix
        );

    // =========================
    // Setters
    // =========================

    /// @notice Sets instant fees.
    /// @param instantFeeGasBps: instant fee in gas bps
    /// @param instantFeeFix: fixed fee for instant calls
    function setInstantFees(
        uint64 instantFeeGasBps,
        uint192 instantFeeFix
    ) external;

    /// @notice Sets automation fees.
    /// @param automationFeeGasBps: automation fee in gas bps
    /// @param automationFeeFix: fixed fee for automation calls
    function setAutomationFee(
        uint64 automationFeeGasBps,
        uint192 automationFeeFix
    ) external;

    /// @notice Sets the ditto treasury address.
    /// @param treasury: address of the ditto treasury
    function setTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TransferHelper
/// @notice A helper library for safe transfers, approvals, and balance checks.
/// @dev Provides safe functions for ERC20 token and native currency transfers.
library TransferHelper {
    // =========================
    // Event
    // =========================

    /// @notice Emits when a transfer is successfully executed.
    /// @param token The address of the token (address(0) for native currency).
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param value The number of tokens (or native currency) transferred.
    event TransferHelperTransfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 value
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when `safeTransferFrom` fails.
    error TransferHelper_SafeTransferFromError();

    /// @notice Thrown when `safeTransfer` fails.
    error TransferHelper_SafeTransferError();

    /// @notice Thrown when `safeApprove` fails.
    error TransferHelper_SafeApproveError();

    /// @notice Thrown when `safeGetBalance` fails.
    error TransferHelper_SafeGetBalanceError();

    /// @notice Thrown when `safeTransferNative` fails.
    error TransferHelper_SafeTransferNativeError();

    // =========================
    // Functions
    // =========================

    /// @notice Executes a safe transfer from one address to another.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param from Address of the sender.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (
            !_makeCall(
                token,
                abi.encodeCall(IERC20.transferFrom, (from, to, value))
            )
        ) {
            revert TransferHelper_SafeTransferFromError();
        }

        emit TransferHelperTransfer(token, from, to, value);
    }

    /// @notice Executes a safe transfer.
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param token Address of the ERC20 token to transfer.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransfer(address token, address to, uint256 value) internal {
        if (!_makeCall(token, abi.encodeCall(IERC20.transfer, (to, value)))) {
            revert TransferHelper_SafeTransferError();
        }

        emit TransferHelperTransfer(token, address(this), to, value);
    }

    /// @notice Executes a safe approval.
    /// @dev Uses low-level calls to handle cases where allowance is not zero
    /// and tokens which are not supports approve with non-zero allowance.
    /// @param token Address of the ERC20 token to approve.
    /// @param spender Address of the account that gets the approval.
    /// @param value Amount to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            IERC20.approve,
            (spender, value)
        );

        if (!_makeCall(token, approvalCall)) {
            if (
                !_makeCall(
                    token,
                    abi.encodeCall(IERC20.approve, (spender, 0))
                ) || !_makeCall(token, approvalCall)
            ) {
                revert TransferHelper_SafeApproveError();
            }
        }
    }

    /// @notice Retrieves the balance of an account safely.
    /// @dev Uses low-level staticcall to ensure proper error handling.
    /// @param token Address of the ERC20 token.
    /// @param account Address of the account to fetch balance for.
    /// @return The balance of the account.
    function safeGetBalance(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );
        if (!success || data.length == 0) {
            revert TransferHelper_SafeGetBalanceError();
        }
        return abi.decode(data, (uint256));
    }

    /// @notice Executes a safe transfer of native currency (e.g., ETH).
    /// @dev Uses low-level call to ensure proper error handling.
    /// @param to Address of the recipient.
    /// @param value Amount to transfer.
    function safeTransferNative(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            revert TransferHelper_SafeTransferNativeError();
        }

        emit TransferHelperTransfer(address(0), address(this), to, value);
    }

    // =========================
    // Private function
    // =========================

    /// @dev Helper function to make a low-level call for token methods.
    /// @dev Ensures correct return value and decodes it.
    ///
    /// @param token Address to make the call on.
    /// @param data Calldata for the low-level call.
    /// @return True if the call succeeded, false otherwise.
    function _makeCall(
        address token,
        bytes memory data
    ) private returns (bool) {
        (bool success, bytes memory returndata) = token.call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AccessControlLib
/// @notice A library for managing access controls with roles and ownership.
/// @dev Provides the structures and functions needed to manage roles and determine ownership.
library AccessControlLib {
    // =========================
    // Errors
    // =========================

    /// @notice Thrown when attempting to initialize an already initialized vault.
    error AccessControlLib_AlreadyInitialized();

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the access control struct, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 constant ROLES_STORAGE_POSITION = keccak256("vault.roles.storage");

    /// @notice Struct to store roles and ownership details.
    struct RolesStorage {
        // Role-based access mapping
        mapping(bytes32 role => mapping(address account => bool)) roles;
        // Address that created the entity
        address creator;
        // Identifier for the vault
        uint16 vaultId;
        // Flag to decide if cross chain logic is not allowed
        bool crossChainLogicInactive;
        // Owner address
        address owner;
        // Flag to decide if `owner` or `creator` is used
        bool useOwner;
    }

    // =========================
    // Main library logic
    // =========================

    /// @dev Retrieve the storage location for roles.
    /// @return s Reference to the roles storage struct in the storage.
    function rolesStorage() internal pure returns (RolesStorage storage s) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly ("memory-safe") {
            s.slot := position
        }
    }

    /// @dev Fetch the owner of the vault.
    /// @dev Determines whether to use the `creator` or the `owner` based on the `useOwner` flag.
    /// @return Address of the owner.
    function getOwner() internal view returns (address) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (s.useOwner) {
            return s.owner;
        } else {
            return s.creator;
        }
    }

    /// @dev Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function getCreatorAndId() internal view returns (address, uint16) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        return (s.creator, s.vaultId);
    }

    /// @dev Initializes the `creator` and `vaultId` for a new vault.
    /// @dev Should only be used once. Reverts if already set.
    /// @param creator Address of the vault creator.
    /// @param vaultId Identifier for the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) internal {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        // check if vault never existed before
        if (s.vaultId != 0) {
            revert AccessControlLib_AlreadyInitialized();
        }

        s.creator = creator;
        s.vaultId = vaultId;
    }

    /// @dev Fetches cross chain logic flag.
    /// @return True if cross chain logic is active.
    function crossChainLogicIsActive() internal view returns (bool) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        return !s.crossChainLogicInactive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Constants
/// @dev These constants can be imported and used by other contracts for consistency.
library Constants {
    /// @dev A keccak256 hash representing the executor role.
    bytes32 internal constant EXECUTOR_ROLE =
        keccak256("DITTO_WORKFLOW_EXECUTOR_ROLE");

    /// @dev A constant representing the native token in any network.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}