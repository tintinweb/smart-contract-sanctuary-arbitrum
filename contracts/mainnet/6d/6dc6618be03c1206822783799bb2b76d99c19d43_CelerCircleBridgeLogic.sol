// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseContract} from "../../../libraries/BaseContract.sol";

import {ICelerCircleBridge} from "../../../interfaces/external/ICelerCircleBridge.sol";
import {ICelerCircleBridgeLogic} from "../../../interfaces/ourLogic/bridges/ICelerCircleBridgeLogic.sol";

import {AccessControlLib} from "../../../libraries/AccessControlLib.sol";

contract CelerCircleBridgeLogic is ICelerCircleBridgeLogic, BaseContract {
    // =========================
    // Constructor
    // =========================

    ICelerCircleBridge private immutable celerCircleProxy;
    IERC20 private immutable usdc;

    constructor(address _celerCircleProxy, address _usdc) {
        celerCircleProxy = ICelerCircleBridge(_celerCircleProxy);
        usdc = IERC20(_usdc);
    }

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc ICelerCircleBridgeLogic
    function sendCelerCircleMessage(
        uint64 dstChainId,
        uint256 exactAmount,
        address recipient
    ) external onlyVaultItself {
        usdc.approve(address(celerCircleProxy), exactAmount);

        _sendCelerCircle(dstChainId, exactAmount, recipient);
    }

    /// @inheritdoc ICelerCircleBridgeLogic
    function sendBatchCelerCircleMessage(
        uint64 dstChainId,
        uint256[] calldata exactAmounts,
        address[] calldata recipient
    ) external onlyVaultItself {
        if (exactAmounts.length != recipient.length) {
            revert CelerCircleBridgeLogic_MultisenderArgsNotValid();
        }

        // approve total amount to celerCircleProxy contract
        uint256 totalAmount;
        for (uint256 i; i < exactAmounts.length; ) {
            unchecked {
                totalAmount += exactAmounts[i];
                ++i;
            }
        }

        usdc.approve(address(celerCircleProxy), totalAmount);

        for (uint i; i < recipient.length; ) {
            _sendCelerCircle(dstChainId, exactAmounts[i], recipient[i]);

            unchecked {
                ++i;
            }
        }
    }

    // =========================
    // Private functions
    // =========================

    /// @dev Handles the deposit process for burning tokens via the CelerCircle bridge.
    /// @dev This is a helper function to interact with the CelerCircle bridge's depositForBurn method.
    /// @param dstChainId The destination chain ID where the tokens will be burned.
    /// @param exactAmount The exact amount of tokens to be sent for burning.
    /// @param recipient The recipient address on the destination chain.
    function _sendCelerCircle(
        uint64 dstChainId,
        uint256 exactAmount,
        address recipient
    ) private {
        celerCircleProxy.depositForBurn(
            exactAmount,
            dstChainId,
            bytes32(uint256(uint160(recipient))),
            address(usdc)
        );
    }
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
pragma solidity ^0.8.0;

/// @title ICelerCircleBridge - Interface for the Celer Circle Bridge operations.
/// @dev This interface provides a method for bridging them.
interface ICelerCircleBridge {
    /// @notice Deposits a specified amount of tokens for burning.
    /// @dev This function prepares tokens to be burned and sends them to a destination chain.
    /// @param amount The amount of tokens to deposit.
    /// @param dstChid The destination chain ID where the tokens will be sent.
    /// @param mintRecipient The address or identifier of the recipient on the destination chain.
    /// @param burnToken The address of the token to be burned.
    function depositForBurn(
        uint256 amount,
        uint64 dstChid,
        bytes32 mintRecipient,
        address burnToken
    ) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ICelerCircleBridgeLogic - CelerCircleBridgeLogic interface.
/// @dev Provides the main functionality for the CelerCircleBridgeLogic.
interface ICelerCircleBridgeLogic {
    // =========================
    // Errors
    // =========================

    /// @notice Indicates that the vault cannot use cross chain logic.
    error CelerCircleBridgeLogic_VaultCannotUseCrossChainLogic();

    /// @notice Indicates that the arguments provided to the multisender are not valid.
    error CelerCircleBridgeLogic_MultisenderArgsNotValid();

    // =========================
    // Main functions
    // =========================

    /// @notice Sends a CelerCircle USDC transfer to a specified chain.
    /// @dev Allows for cross-chain communication with the specified chain.
    /// @param dstChainId The destination chain ID where the USDC transfer will be sent.
    /// @param exactAmount The exact amount to be sent.
    /// @param recipient The address of the recipient on the destination chain.
    function sendCelerCircleMessage(
        uint64 dstChainId,
        uint256 exactAmount,
        address recipient
    ) external;

    /// @notice Sends a batch of CelerCircle USDC transfers to a specified chain.
    /// @dev Allows for sending multiple USDC transfers in a single transaction.
    /// @param dstChainId The destination chain ID where the USDC transfers will be sent.
    /// @param exactAmount Array of exact amounts to be sent.
    /// @param recipient Array of recipient addresses on the destination chain.
    function sendBatchCelerCircleMessage(
        uint64 dstChainId,
        uint256[] calldata exactAmount,
        address[] calldata recipient
    ) external;
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