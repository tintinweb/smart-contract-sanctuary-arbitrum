// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IMassSmartAccount} from "src/interfaces/IMassSmartAccount.sol";
import {ISmartAccountFactory} from "src/interfaces/ISmartAccountFactory.sol";
import {AddressNotContract} from "src/Errors.sol";

/// @title SmartAccountFactoryUtils
/// @notice Utilities for SmartAccountFactory contract.
contract SmartAccountFactoryUtils {
    /// @notice The address of the SmartAccountFactory.
    ISmartAccountFactory public immutable smartAccountFactory;

    constructor(address smartAccountFactory_) {
        if (smartAccountFactory_.code.length == 0) {
            revert AddressNotContract(smartAccountFactory_);
        }
        smartAccountFactory = ISmartAccountFactory(smartAccountFactory_);
    }

    /// @notice Creates a smart account and executes an EIP712 signature on behalf
    ///         of a user in the same transaction.
    /// @param salt The salt used to create the smart account.
    /// @param smartAccountOwner The owner of the smart account.
    /// @param to The address of the contract to call.
    /// @param data The data of the transaction to execute.
    /// @param value The value of the transaction to execute.
    /// @param expiration The expiration of the transaction to execute.
    /// @param n The nonce of the transaction to execute.
    /// @param v The v of the transaction to execute.
    /// @param r The r of the transaction to execute.
    /// @param s The s of the transaction to execute.
    /// @return The return data of the transaction.
    function createOnBehalfOfAndExecuteSignature(
        bytes32 salt,
        address smartAccountOwner,
        address to,
        bytes calldata data,
        uint256 value,
        uint256 expiration,
        uint256 n,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory) {
        address massSmartAccount = smartAccountFactory.create(salt, smartAccountOwner);
        return IMassSmartAccount(massSmartAccount).executeSignature712{value: msg.value}(
            to, data, value, expiration, n, v, r, s
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";

/// @author MassMoney
/// @notice Interface for the MassSmartAccount contract.
/// @custom:version V1
interface IMassSmartAccount is IERC1271 {
    /// @dev Information to call a contract function.
    /// @param payload Payload to forward to contract, function with params
    ///                encoded.
    /// @param target Contract address to call.
    /// @param value The value to pass to the call.
    struct Call {
        bytes payload;
        address target;
        uint256 value;
    }

    /// @notice Execute a Call to a contract.
    /// @param call A Call to execute.
    /// @return data The returned data from the underlying call.
    function executeCall(Call calldata call) external payable returns (bytes memory data);

    /// @notice Execute a delegatecall to the HyVM.
    /// @dev This function is a shortcut to save gas, since the HyVM address
    ///      is immutable.
    ///      Any ETH sent to this function will be wrapped to WETH to avoid having
    ///      ETH in the smart account in case it is not used in the delegatecall.
    /// @param bytecode The data to delegatecall the HyVM.
    /// @return data The returned data from the underlying HyVM call.
    function executeHyVMCall(bytes calldata bytecode)
        external
        payable
        returns (bytes memory data);

    /// @notice Activate the ERC2771 feature.
    function activateERC2771() external;

    /// @notice Deactivate the ERC2771 feature.
    function deactivateERC2771() external;

    /// @notice Check if the ERC2771 feature is activated.
    /// @return activated True if activated, false if not.
    function isERC2771Activated() external view returns (bool activated);

    /// @notice Should return whether the signature provided is valid for the
    ///         provided hashed data.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with data.
    /// @return Function selector of the function or bytes4(0).
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);

    /// @notice Execute a transaction through an EIP712 signature.
    /// @dev If the target is the HyVM, any ETH sent to this function will be
    ///      wrapped to WETH to avoid having ETH in the smart account in case it
    ///      is not used in the delegatecall.
    /// @param to The target address.
    /// @param payload The payload to send.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param n The nonce.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeSignature712(
        address to,
        bytes memory payload,
        uint256 value,
        uint256 expiration,
        uint256 n,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData);

    /// @notice Execute one of the transactions through the HyVM in a merkle tree which root was signed
    ///         by EIP712 signature.
    /// @dev Any ETH sent to this function will be wrapped to WETH to avoid having ETH in the
    ///      smart account in case it is not used in the delegatecall as the target is the HyVM.
    ///      Dynamic payload is appended to the signed payload when needed (e.g. pyth data).
    ///      Use cases of this function: TP and SL orders in the same bundle or creating multiple
    ///      limit orders in the same bundle.
    ///      It allows to require only one signature for multiple transactions from a user.
    ///      Merkle trees should be created with the Merkle tree OZ library.
    ///      https://github.com/OpenZeppelin/merkle-tree
    ///
    ///      !!! No jump should be done from the reentrantData to the dynamic data.
    ///          Only calldataload should be used to read the dynamic data else it
    ///          could lead to malicious data being executed.
    ///          By using the SDK, this issue will be avoided as it will ensure
    ///          only read of dynamic data will be done. !!!
    ///
    ///      !!! A particular attention is needed to be sure about what is signed as order
    ///          of transactions execution could have an impact. It is also the responsibility of the
    ///          user / SDK to check there are no 2 transactions with the same data in one merkle tree
    ///          else the second one will be rejected !!!
    ///
    /// @param root Merkle root of the tree that contains all signed transactions.
    /// @param proof Merkle proof of the transaction to execute.
    /// @param txPayload The transaction payload included in the merkle tree.
    /// @param dynamicPayload Dynamic payload to append to the txPayload.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeTransactionFromBundleSignature(
        bytes32 root,
        bytes32[] calldata proof,
        bytes memory txPayload,
        bytes memory dynamicPayload,
        uint256 value,
        uint256 expiration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData);

    /// @notice Revoke a transaction bundled in a merkle tree EIP712 execution bundle.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root of the tree.
    /// @param bundledTransaction The transaction to revoke.
    function revokeBundledTransactionExecution(bytes32 root, bytes32 bundledTransaction) external;

    /// @notice Revoke a merkle tree root. All transactions bundled in this merkle tree
    ///         will be revoked.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root to revoke.
    function revokeMerkleRootBundledTransactions(bytes32 root) external;

    /// @notice Build the domain separator for the EIP712 signature.
    /// @return The domain separator.
    function buildDomainSeparator() external view returns (bytes32);

    /// @notice Increment the nonce.
    /// @dev Only the owner can execute this function. It allows to cancel a
    ///      signature.
    function incrementNonce() external;

    /// @notice Return the owner of the current Mass Smart Account.
    /// @return Address of the owner.
    function smartAccountOwner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @author MassMoney
/// @notice Interface for the SmartAccountFactory contract.
/// @custom:version V1
interface ISmartAccountFactory {
    /// @notice Creates MassSmartAccount with create2 for a given smartAccountOwner.
    /// @dev The smart account owner is set by calling the smartAccountOwnerResolver.
    /// @param salt Salt provided to create2.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount The new MassSmartAccount address.
    function create(bytes32 salt, address smartAccountOwner)
        external
        returns (address massSmartAccount);

    /// @notice Compute predicted Mass Smart Account address from salt and smartAccountOwner.
    /// @param salt salt provided by user to smartAccountFactory functions.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount Predicted address of the Mass Smart Account.
    function computePredictedAddressSmartAccount(bytes32 salt, address smartAccountOwner)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

error AddressNotContract(address notContract);

error AlreadyInitialized();

error CannotInitializeImpl();

error CannotRecreateSmartAccount(address massSmartAccount);

error EmptyByteCode();

error Expired();

error FailedDeployment();

error InvalidMerkleProof();

error InvalidMerkleRoot(bytes32 root);

error InvalidInitiator(address notInitiator);

error PoolMismatch();

error OwnerAlreadySet();

error OnlySelfCall();

error OnlySmartAccountFactory(address);

error InvalidReentrantData();

error InvalidValue();

error InvalidNonce();

error OnlyLendingPool();

error OnlyLiquidityPool();

error Reentrancy();

error SenderNotInitializer(address sender);

error RequesterNotMSA();

error SenderNotSmartAccountOwner(address sender);

error SenderNotSmartAccountOwnerOrMSAItself(address sender);

error SenderNotWeth(address sender);

error TransactionAlreadyProcessed(bytes32 txDataHash);

error TokensAndAmountsLengthMismatch();

error WrongFlashloanRequester(address requester);

error WrongSigner(address signer);

error WrongImplementation(address implementation);

error ZeroAddress();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}