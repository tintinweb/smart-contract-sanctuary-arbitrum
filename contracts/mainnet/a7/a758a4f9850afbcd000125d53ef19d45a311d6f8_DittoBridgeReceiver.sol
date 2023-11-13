// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IStargateReceiver} from "./vault/interfaces/external/stargate/IStargateReceiver.sol";
import {ILayerZeroReceiver} from "./vault/interfaces/external/layerZero/ILayerZeroReceiver.sol";

import {IVaultFactory} from "./IVaultFactory.sol";
import {IAccessControlLogic} from "./vault/interfaces/IAccessControlLogic.sol";

import {Ownable} from "./external/Ownable.sol";

import {TransferHelper} from "./vault/libraries/utils/TransferHelper.sol";

/// @title DittoBridgeReceiver
contract DittoBridgeReceiver is Ownable, IStargateReceiver, ILayerZeroReceiver {
    // =========================
    // Constructor
    // =========================

    address public stargateComposer;
    address public layerZeroEndpoint;

    IVaultFactory public immutable vaultFactory;

    constructor(address _vaultFactory, address _owner) {
        vaultFactory = IVaultFactory(_vaultFactory);
        _transferOwnership(_owner);
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when a cross-chain call reverts
    /// @param vaultAddress: address where the revert occurred
    /// @param reason: message about the cause of the revert
    event DittoBridgeReceiverRevertData(
        address indexed vaultAddress,
        bytes payload,
        bytes reason
    );

    /// @notice Emits when src and dst vault addresses not matching
    /// @param srcVaultAddress: src chain address
    /// @param dstVaultAddress: dst chain address
    event LayerZeroWrongRecipient(
        address srcVaultAddress,
        address dstVaultAddress
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when anyone other than the StargateComposer tries to call lzRecieve
    error DittoBridgeReciever_OnlyLayerZeroEndpointCanCallThisMethod();

    /// @notice Thrown when anyone other than the StargateComposer tries to call sgRecieve
    error DittoBridgeReciever_OnlyStargateComposerCanCallThisMethod();

    // =========================
    // Admin methods
    // =========================

    /// @notice Sets address of the bridges once
    /// @param _stargateComposer: the address of the stargate composer
    /// @param _layerZeroEndpoint: the address of the layerZero endpoint
    /// @dev only callable by contract owner
    function setBridgeContracts(
        address _stargateComposer,
        address _layerZeroEndpoint
    ) external onlyOwner {
        if (stargateComposer == address(0) && layerZeroEndpoint == address(0)) {
            stargateComposer = _stargateComposer;
            layerZeroEndpoint = _layerZeroEndpoint;
        }
    }

    /// @notice Withdraws any tokens from contract
    /// @param token: the address of the token or address(0) if native currency
    /// @dev only callable by contract owner
    function withdrawToken(address token) external onlyOwner {
        if (token == address(0)) {
            TransferHelper.safeTransferNative(
                msg.sender,
                address(this).balance
            );
        } else {
            TransferHelper.safeTransfer(
                token,
                msg.sender,
                TransferHelper.safeGetBalance(token, address(this))
            );
        }
    }

    // =========================
    // Main functions
    // =========================

    struct BridgePayload {
        // params for vault validation and creation
        address srcChainVaultOwner;
        uint256 vaultVersion;
        uint16 srcChainVaultId;
        // calldata for vault call
        bytes payload;
    }

    /// @inheritdoc IStargateReceiver
    function sgReceive(
        uint16,
        bytes memory _srcChainVaultAddress,
        uint256,
        address token,
        uint256 amountLD,
        bytes calldata payload
    ) external payable override {
        address srcChainVaultAddress = _validateSender(
            stargateComposer,
            _srcChainVaultAddress,
            DittoBridgeReciever_OnlyStargateComposerCanCallThisMethod.selector
        );

        BridgePayload calldata stargatePayload = _decodePayload(payload);

        // gets the vault address for the destination chain
        address dstChainVaultAddress = vaultFactory
            .predictDeterministicVaultAddress(
                stargatePayload.srcChainVaultOwner,
                stargatePayload.srcChainVaultId
            );

        // if addresses from src and dst are the same, we can just transfer the tokens
        if (srcChainVaultAddress == dstChainVaultAddress) {
            // if the vault doesn't exist yet, create it
            if (dstChainVaultAddress.code.length == 0) {
                vaultFactory.crossChainDeploy(
                    stargatePayload.srcChainVaultOwner,
                    stargatePayload.vaultVersion,
                    stargatePayload.srcChainVaultId
                );
            }

            // optimistically send tokens to vault address
            // if the vault owner is not eq the creator -> just transfer the tokens
            // (no need to call the vault, cause in this case we cant asure
            // that the src vault has not been compromised)
            TransferHelper.safeTransfer(token, dstChainVaultAddress, amountLD);

            bytes memory callData = stargatePayload.payload;
            assembly ("memory-safe") {
                mstore(add(callData, 36), amountLD)
            }

            (bool success, bytes memory revertReason) = dstChainVaultAddress
                .call(callData);

            // if revert -> emit the reason and stop tx execution
            if (!success) {
                emit DittoBridgeReceiverRevertData(
                    dstChainVaultAddress,
                    stargatePayload.payload,
                    revertReason
                );
            }
        } else {
            // if addresses are different, we need to transfer the tokens to the srcChainVaultOwner
            // Main sg call cannot reach this condition. Only manual execution via `execute` method!
            TransferHelper.safeTransfer(
                token,
                stargatePayload.srcChainVaultOwner,
                amountLD
            );
        }
    }

    /// @inheritdoc ILayerZeroReceiver
    function lzReceive(
        uint16,
        bytes memory _srcChainVaultAddress,
        uint64,
        bytes calldata payload
    ) external override {
        address srcChainVaultAddress = _validateSender(
            layerZeroEndpoint,
            _srcChainVaultAddress,
            DittoBridgeReciever_OnlyLayerZeroEndpointCanCallThisMethod.selector
        );

        BridgePayload calldata layerZeroPayload = _decodePayload(payload);

        // gets the vault address for the destination chain
        address dstChainVaultAddress = vaultFactory
            .predictDeterministicVaultAddress(
                layerZeroPayload.srcChainVaultOwner,
                layerZeroPayload.srcChainVaultId
            );

        // if addresses from src and dst are the same, we can just transfer the tokens
        if (srcChainVaultAddress == dstChainVaultAddress) {
            // if the vault doesn't exist yet, create it
            if (dstChainVaultAddress.code.length == 0) {
                vaultFactory.crossChainDeploy(
                    layerZeroPayload.srcChainVaultOwner,
                    layerZeroPayload.vaultVersion,
                    layerZeroPayload.srcChainVaultId
                );
            }

            (bool success, bytes memory revertReason) = dstChainVaultAddress
                .call(layerZeroPayload.payload);

            // if revert -> emit the reason and stop tx execution
            if (!success) {
                emit DittoBridgeReceiverRevertData(
                    dstChainVaultAddress,
                    layerZeroPayload.payload,
                    revertReason
                );
            }
        } else {
            // if addresses are different, we emit event
            emit LayerZeroWrongRecipient(
                srcChainVaultAddress,
                dstChainVaultAddress
            );
        }
    }

    // =========================
    // Private functions
    // =========================

    /// @dev Validates that the caller is the expected bridge contract and decodes the source chain vault address.
    /// @param bridgeContract The address of the bridge contract expected to be the message sender.
    /// @param _srcChainVaultAddress The encoded address of the source chain vault.
    /// @param errorSelector A bytes4 error code to revert with if validation fails.
    /// @return srcChainVaultAddress The decoded source chain vault address.
    function _validateSender(
        address bridgeContract,
        bytes memory _srcChainVaultAddress,
        bytes4 errorSelector
    ) internal view returns (address srcChainVaultAddress) {
        if (msg.sender != bridgeContract) {
            assembly ("memory-safe") {
                mstore(0, errorSelector)
                revert(0, 4)
            }
        }

        assembly ("memory-safe") {
            srcChainVaultAddress := shr(
                96,
                mload(add(_srcChainVaultAddress, 32))
            )
        }
    }

    /// @dev Decodes the payload to extract the BridgePayload data structure.
    /// @param payload The calldata bytes containing the encoded BridgePayload.
    /// @return bridgePayload The decoded BridgePayload as a calldata pointer.
    function _decodePayload(
        bytes calldata payload
    ) internal pure returns (BridgePayload calldata bridgePayload) {
        assembly ("memory-safe") {
            bridgePayload := payload.offset
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IStargateReceiver - StargateReceiver interface
interface IStargateReceiver {
    /// @notice Function to receive a cross-chain message via StargateComposer
    /// @param chainId: id of source chain
    /// @param srcAddress: source chain msg.sender
    /// @param nonce: nonce of the msg.sender
    /// @param token: address of the token that was received by StargateReceiver
    /// @param amountLD: the exact amount of the `token` received by StargateReceiver
    /// @param payload: byte array for optional StargateReceiver contract call
    function sgReceive(
        uint16 chainId,
        bytes memory srcAddress,
        uint256 nonce,
        address token,
        uint256 amountLD,
        bytes memory payload
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    /// @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    /// @param _srcChainId - the source endpoint identifier
    /// @param _srcAddress - the source sending contract address from the source chain
    /// @param _nonce - the ordered message nonce
    /// @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOwnable} from "./external/IOwnable.sol";

/// @title IVaultFactory - VaultFactory Interface
/// @notice This contract is a vault factory that implements methods for creating new vaults
/// and updating them via the UpgradeLogic contract.
interface IVaultFactory is IOwnable {
    // =========================
    // Storage
    // =========================

    /// @notice The address of the immutable contract to which the `vault` call will be
    /// delegated if the call is made from `ProxyAdmin's` address.
    function upgradeLogic() external view returns (address);

    /// @notice The address from which the call to `vault` will delegate it to the `updateLogic`.
    function vaultProxyAdmin() external view returns (address);

    // =========================
    // Events
    // =========================

    /// @notice Emits when the new `vault` has been created.
    /// @param creator The creator of the created vault
    /// @param vault The address of the created vault
    /// @param vaultId The unique identifier for the vault (for `creator` address)
    event VaultCreated(
        address indexed creator,
        address indexed vault,
        uint16 vaultId
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown if an attempt is made to initialize the contract a second time.
    error VaultFactory_AlreadyInitialized();

    /// @notice Thrown when a `creator` attempts to create a vault using
    /// a version of the implementation that doesn't exist.
    error VaultFactory_VersionDoesNotExist();

    /// @notice Thrown when a `creator` tries to create a vault with an `vaultId`
    /// that's already in use.
    /// @param creator The address which tries to create the vault.
    /// @param vaultId The id that is already used.
    error VaultFactory_IdAlreadyUsed(address creator, uint16 vaultId);

    /// @notice Thrown when a `creator` attempts to create a vault with an vaultId == `0`
    /// or when the `creator` address is the same as the `proxyAdmin`.
    error VaultFactory_InvalidDeployArguments();

    /// @dev Error to be thrown when an unauthorized operation is attempted.
    error VaultFactory_NotAuthorized();

    // =========================
    // Admin methods
    // =========================

    /// @notice Sets the address of the Ditto Bridge Receiver contract.
    /// @dev This function can only be called by an authorized admin.
    /// @param _dittoBridgeReceiver The address of the new Ditto Bridge Receiver contract.
    function setBridgeReceiverContract(address _dittoBridgeReceiver) external;

    // =========================
    // Vault implementation logic
    // =========================

    /// @notice Adds a `newImplemetation` address to the list of implementations.
    /// @param newImplemetation The address of the new implementation to be added.
    ///
    /// @dev Only callable by the owner of the contract.
    /// @dev After adding, the new implementation will be at the last index
    /// (i.e., version is `_implementations.length`).
    function addNewImplementation(address newImplemetation) external;

    /// @notice Retrieves the implementation address for a given `version`.
    /// @param version The version number of the desired implementation.
    /// @return impl_ The address of the specified implementation version.
    ///
    /// @dev If the `version` number is greater than the length of the `_implementations` array
    /// or the array is empty, `VaultFactory_VersionDoesNotExist` error is thrown.
    function implementation(uint256 version) external view returns (address);

    /// @notice Returns the total number of available implementation versions.
    /// @return The total count of versions in the `_implementations` array.
    function versions() external view returns (uint256);

    // =========================
    // Main functions
    // =========================

    /// @notice Computes the address of a `vault` deployed using `deploy` method.
    /// @param creator The address of the creator of the vault.
    /// @param vaultId The id of the vault.
    /// @dev `creator` and `id` are part of the salt for the `create2` opcode.
    function predictDeterministicVaultAddress(
        address creator,
        uint16 vaultId
    ) external view returns (address predicted);

    /// @notice Deploys a new `vault` based on a specified `version`.
    /// @param version The version number of the vault implementation to which
    ///        the new vault will delegate.
    /// @param vaultId A unique identifier for deterministic vault creation.
    ///        Used in combination with `msg.sender` for `create2` salt.
    /// @return The address of the newly deployed `vault`.
    ///
    /// @dev Uses the `create2` opcode for deterministic address generation based on a salt that
    /// combines the `msg.sender` and `vaultId`.
    /// @dev If the given `version` number is greater than the length of  the `_implementations`
    /// array or if the array is empty, it reverts with `VaultFactory_VersionDoesNotExist`.
    /// @dev If `vaultId` is zero, it reverts with`VaultFactory_InvalidDeployArguments`.
    /// @dev If the `vaultId` has already been used for the `msg.sender`, it reverts with
    /// `VaultFactory_IdAlreadyUsed`.
    function deploy(uint256 version, uint16 vaultId) external returns (address);

    function crossChainDeploy(
        address creator,
        uint256 version,
        uint16 vaultId
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IAccessControlLogic - AccessControlLogic interface
interface IAccessControlLogic {
    // =========================
    // Events
    // =========================

    /// @dev Emitted when ownership of a vault is transferred.
    /// @param oldOwner Address of the previous owner.
    /// @param newOwner Address of the new owner.
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /// @dev Emitted when a new `role` is granted to an `account`.
    /// @param role Identifier for the role.
    /// @param account Address of the account.
    /// @param sender Address of the sender granting the role.
    event RoleGranted(bytes32 role, address account, address sender);

    /// @dev Emitted when a `role` is revoked from an `account`.
    /// @param role Identifier for the role.
    /// @param account Address of the account.
    /// @param sender Address of the sender revoking the role.
    event RoleRevoked(bytes32 role, address account, address sender);

    /// @dev Emitted when a cross chain logic flag is setted.
    /// @param flag Cross chain flag new value.
    event CrossChainLogicInactiveFlagSet(bool flag);

    // =========================
    // Main functions
    // =========================

    /// @notice Initializes the `creator` and `vaultId`.
    /// @param creator Address of the vault creator.
    /// @param vaultId ID of the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) external;

    /// @notice Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function creatorAndId() external view returns (address, uint16);

    /// @notice Returns the owner's address of the vault.
    /// @return Address of the vault owner.
    function owner() external view returns (address);

    /// @notice Retrieves the address of the Vault proxyAdmin.
    /// @return Address of the Vault proxyAdmin.
    function getVaultProxyAdminAddress() external view returns (address);

    /// @notice Transfers ownership of the proxy vault to a `newOwner`.
    /// @param newOwner Address of the new owner.
    function transferOwnership(address newOwner) external;

    /// @notice Updates the activation status of the cross-chain logic.
    /// @dev Can only be called by an authorized admin to enable or disable the cross-chain logic.
    /// @param newValue The new activation status to be set; `true` to activate, `false` to deactivate.
    function setCrossChainLogicInactiveStatus(bool newValue) external;

    /// @notice Checks whether the cross-chain logic is currently active.
    /// @dev Returns true if the cross-chain logic is active, false otherwise.
    /// @return isActive The current activation status of the cross-chain logic.
    function crossChainLogicIsActive() external view returns (bool isActive);

    /// @notice Checks if an `account` has been granted a particular `role`.
    /// @param role Role identifier to check.
    /// @param account Address of the account to check against.
    /// @return True if the account has the role, otherwise false.
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /// @notice Grants a specified `role` to an `account`.
    /// @dev The caller must be the owner of the vault.
    /// @dev Emits a {RoleGranted} event if the account hadn't been granted the role.
    /// @param role Role identifier to grant.
    /// @param account Address of the account to grant the role to.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes a specified `role` from an `account`.
    /// @dev The caller must be the owner of the vault.
    /// @dev Emits a {RoleRevoked} event if the account had the role.
    /// @param role Role identifier to revoke.
    /// @param account Address of the account to revoke the role from.
    function revokeRole(bytes32 role, address account) external;

    /// @notice An account can use this to renounce a `role`, effectively losing its privileges.
    /// @dev Useful in scenarios where an account might be compromised.
    /// @dev Emits a {RoleRevoked} event if the account had the role.
    /// @param role Role identifier to renounce.
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IOwnable} from "./IOwnable.sol";

/// @title Ownable
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract Ownable is IOwnable {
    // =========================
    // Storage
    // =========================

    /// @dev Private variable to store the owner's address.
    address private _owner;

    // =========================
    // Main functions
    // =========================

    /// @notice Initializes the contract, setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /// @inheritdoc IOwnable
    function owner() external view returns (address) {
        return _owner;
    }

    /// @inheritdoc IOwnable
    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    /// @inheritdoc IOwnable
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert Ownable_NewOwnerCannotBeAddressZero();
        }

        _transferOwnership(newOwner);
    }

    // =========================
    // Internal functions
    // =========================

    /// @dev Internal function to verify if the caller is the owner of the contract.
    /// Errors:
    /// - Thrown `Ownable_SenderIsNotOwner` if the caller is not the owner.
    function _checkOwner() internal view {
        if (_owner != msg.sender) {
            revert Ownable_SenderIsNotOwner(msg.sender);
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @dev Emits an {OwnershipTransferred} event.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
pragma solidity 0.8.19;

/// @title IOwnable - Ownable Interface
/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
interface IOwnable {
    // =========================
    // Events
    // =========================

    /// @notice Emits when ownership of the contract is transferred from `previousOwner`
    /// to `newOwner`.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when the caller is not authorized to perform an operation.
    /// @param sender The address of the sender trying to access a restricted function.
    error Ownable_SenderIsNotOwner(address sender);

    /// @notice Thrown when the new owner is not a valid owner account.
    error Ownable_NewOwnerCannotBeAddressZero();

    // =========================
    // Main functions
    // =========================

    /// @notice Returns the address of the current owner.
    /// @return The address of the current owner.
    function owner() external view returns (address);

    /// @notice Leaves the contract without an owner. It will not be possible to call
    /// `onlyOwner` functions anymore.
    /// @dev Can only be called by the current owner.
    function renounceOwnership() external;

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// @param newOwner The address of the new owner.
    /// @dev Can only be called by the current owner.
    function transferOwnership(address newOwner) external;
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