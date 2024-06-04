/**
 *Submitted for verification at Arbiscan.io on 2024-06-04
*/

// SPDX-License-Identifier: LGPL-3.0-only
/* solhint-disable one-contract-per-file */
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SafeStorage - Storage layout of the Safe Smart Account contracts to be used in libraries.
 * @dev Should be always the first base contract of a library that is used with a Safe.
 * @author Richard Meissner - @rmeissner
 */
contract SafeStorage {
    // From /common/Singleton.sol
    address internal singleton;
    // From /common/ModuleManager.sol
    mapping(address => address) internal modules;
    // From /common/OwnerManager.sol
    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    // From /Safe.sol
    uint256 internal nonce;
    bytes32 internal _deprecatedDomainSeparator;
    mapping(bytes32 => uint256) internal signedMessages;
    mapping(address => mapping(bytes32 => uint256)) internal approvedHashes;
}

/**
 * @title Enum - Collection of enums used in Safe Smart Account contracts.
 * @author @safe-global/safe-protocol
 */
library Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}


interface IModuleManager {
event EnabledModule(address indexed module);
event DisabledModule(address indexed module);
event ExecutionFromModuleSuccess(address indexed module);
event ExecutionFromModuleFailure(address indexed module);
event ChangedModuleGuard(address indexed moduleGuard);

/**
 * @notice Enables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param module Module to be whitelisted.
     */
function enableModule(address module) external;

/**
 * @notice Disables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param prevModule Previous module in the modules linked list.
     * @param module Module to be removed.
     */
function disableModule(address prevModule, address module) external;

/**
 * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token)
     * @dev Function is virtual to allow overriding for L2 singleton to emit an event for indexing.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     */
function execTransactionFromModule(
address to,
uint256 value,
bytes memory data,
Enum.Operation operation
) external returns (bool success);

/**
 * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
function execTransactionFromModuleReturnData(
address to,
uint256 value,
bytes memory data,
Enum.Operation operation
) external returns (bool success, bytes memory returnData);

/**
 * @notice Returns if an module is enabled
     * @return True if the module is enabled
     */
function isModuleEnabled(address module) external view returns (bool);

/**
 * @notice Returns an array of modules.
     *         If all entries fit into a single page, the next pointer will be 0x1.
     *         If another page is present, next will be the last element of the returned array.
     * @param start Start of the page. Has to be a module or start pointer (0x1 address)
     * @param pageSize Maximum number of modules that should be returned. Has to be > 0
     * @return array Array of modules.
     * @return next Start of the next page.
     */
function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next);

/**
 * @dev Set a module guard that checks transactions initiated by the module before execution
     *      This can only be done via a Safe transaction.
     *      ⚠️ IMPORTANT: Since a module guard has full power to block Safe transaction execution initiatied via a module,
     *        a broken module guard can cause a denial of service for the Safe modules. Make sure to carefully
     *        audit the module guard code and design recovery mechanisms.
     * @notice Set Module Guard `moduleGuard` for the Safe. Make sure you trust the module guard.
     * @param moduleGuard The address of the module guard to be used or the zero address to disable the module guard.
     */
function setModuleGuard(address moduleGuard) external;
}
/**
 * @title IOwnerManager - Interface for contract which manages Safe owners and a threshold to authorize transactions.
 * @author @safe-global/safe-protocol
 */
interface IOwnerManager {
    event AddedOwner(address indexed owner);
    event RemovedOwner(address indexed owner);
    event ChangedThreshold(uint256 threshold);

    /**
     * @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param owner New owner address.
     * @param _threshold New threshold.
     */
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    /**
     * @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be removed in the linked list
     * @param owner Owner address to be removed.
     * @param _threshold New threshold.
     */
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;

    /**
     * @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be replaced in the linked list
     * @param oldOwner Owner address to be replaced.
     * @param newOwner New owner address.
     */
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;

    /**
     * @notice Changes the threshold of the Safe to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param _threshold New threshold.
     */
    function changeThreshold(uint256 _threshold) external;

    /**
     * @notice Returns the number of required confirmations for a Safe transaction aka the threshold.
     * @return Threshold number.
     */
    function getThreshold() external view returns (uint256);

    /**
     * @notice Returns if `owner` is an owner of the Safe.
     * @return Boolean if owner is an owner of the Safe.
     */
    function isOwner(address owner) external view returns (bool);

    /**
     * @notice Returns a list of Safe owners.
     * @return Array of Safe owners.
     */
    function getOwners() external view returns (address[] memory);
}

/**
 * @title IFallbackManager - A contract interface managing fallback calls made to this contract.
 * @author @safe-global/safe-protocol
 */
interface IFallbackManager {
    event ChangedFallbackHandler(address indexed handler);

    /**
     * @notice Set Fallback Handler to `handler` for the Safe.
     * @dev Only fallback calls without value and with data will be forwarded.
     *      This can only be done via a Safe transaction.
     *      Cannot be set to the Safe itself.
     * @param handler contract to handle fallback calls.
     */
    function setFallbackHandler(address handler) external;
}

/**
 * @title IGuardManager - A contract interface managing transaction guards which perform pre and post-checks on Safe transactions.
 * @author @safe-global/safe-protocol
 */
interface IGuardManager {
    event ChangedGuard(address indexed guard);

    /**
     * @dev Set a guard that checks transactions before execution
     *      This can only be done via a Safe transaction.
     *      ⚠️ IMPORTANT: Since a guard has full power to block Safe transaction execution,
     *        a broken guard can cause a denial of service for the Safe. Make sure to carefully
     *        audit the guard code and design recovery mechanisms.
     * @notice Set Transaction Guard `guard` for the Safe. Make sure you trust the guard.
     * @param guard The address of the guard to be used or the 0 address to disable the guard
     */
    function setGuard(address guard) external;
}

/**
 * @title ISafe - A multisignature wallet interface with support for confirmations using signed messages based on EIP-712.
 * @author @safe-global/safe-protocol
 */
interface ISafe is IModuleManager, IGuardManager, IOwnerManager, IFallbackManager {
event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
event SignMsg(bytes32 indexed msgHash);
event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);

/**
 * @notice Sets an initial storage of the Safe contract.
     * @dev This method can only be called once.
     *      If a proxy was created without setting up, anyone can call setup and claim the proxy.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @param fallbackHandler Handler for fallback calls to this contract
     * @param paymentToken Token that should be used for the payment (0 is ETH)
     * @param payment Value that should be paid
     * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
     */
function setup(
address[] calldata _owners,
uint256 _threshold,
address to,
bytes calldata data,
address fallbackHandler,
address paymentToken,
uint256 payment,
address payable paymentReceiver
) external;

/** @notice Executes a `operation` {0: Call, 1: DelegateCall}} transaction to `to` with `value` (Native Currency)
     *          and pays `gasPrice` * `gasLimit` in `gasToken` token to `refundReceiver`.
     * @dev The fees are always transferred, even if the user transaction fails.
     *      This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      - if the `gasToken` is a contract or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address of Safe transaction.
     * @param value Ether value of Safe transaction.
     * @param data Data payload of Safe transaction.
     * @param operation Operation type of Safe transaction.
     * @param safeTxGas Gas that should be used for the Safe transaction.
     * @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * @param gasPrice Gas price that should be used for the payment calculation.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @return success Boolean indicating transaction's success.
     */
function execTransaction(
address to,
uint256 value,
bytes calldata data,
Enum.Operation operation,
uint256 safeTxGas,
uint256 baseGas,
uint256 gasPrice,
address gasToken,
address payable refundReceiver,
bytes memory signatures
) external payable returns (bool success);

/**
 * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     */
function checkSignatures(bytes32 dataHash, bytes memory signatures) external view;

/**
 * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
     * @param executor Address that executing the transaction.
     *        ⚠️⚠️⚠️ Make sure that the executor address is a legitmate executor.
     *        Incorrectly passed the executor might reduce the threshold by 1 signature. ⚠️⚠️⚠️
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
function checkNSignatures(address executor, bytes32 dataHash, bytes memory signatures, uint256 requiredSignatures) external view;

/**
 * @notice Marks hash `hashToApprove` as approved.
     * @dev This can be used with a pre-approved hash transaction signature.
     *      IMPORTANT: The approved hash stays approved forever. There's no revocation mechanism, so it behaves similarly to ECDSA signatures
     * @param hashToApprove The hash to mark as approved for signatures that are verified by this contract.
     */
function approveHash(bytes32 hashToApprove) external;

/**
 * @dev Returns the domain separator for this contract, as defined in the EIP-712 standard.
     * @return bytes32 The domain separator hash.
     */
function domainSeparator() external view returns (bytes32);

/**
 * @notice Returns transaction hash to be signed by owners.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @param safeTxGas Gas that should be used for the safe transaction.
     * @param baseGas Gas costs for data used to trigger the safe transaction.
     * @param gasPrice Maximum gas price that should be used for this transaction.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param _nonce Transaction nonce.
     * @return Transaction hash.
     */
function getTransactionHash(
address to,
uint256 value,
bytes calldata data,
Enum.Operation operation,
uint256 safeTxGas,
uint256 baseGas,
uint256 gasPrice,
address gasToken,
address refundReceiver,
uint256 _nonce
) external view returns (bytes32);

/**
 * External getter function for state variables.
 */

/**
 * @notice Returns the version of the Safe contract.
     * @return Version string.
     */
// solhint-disable-next-line
function VERSION() external view returns (string memory);

/**
 * @notice Returns the nonce of the Safe contract.
     * @return Nonce.
     */
function nonce() external view returns (uint256);

/**
 * @notice Returns a uint if the messageHash is signed by the owner.
     * @param messageHash Hash of message that should be checked.
     * @return Number denoting if an owner signed the hash.
     */
function signedMessages(bytes32 messageHash) external view returns (uint256);

/**
 * @notice Returns a uint if the messageHash is approved by the owner.
     * @param owner Owner address that should be checked.
     * @param messageHash Hash of message that should be checked.
     * @return Number denoting if an owner approved the hash.
     */
function approvedHashes(address owner, bytes32 messageHash) external view returns (uint256);
}


/**
 * @title Migration Contract for updating a Safe from 1.1.1/1.3.0/1.4.1 versions to a L2 version. Useful when replaying a Safe from a non L2 network in a L2 network.
 * @notice This contract facilitates the migration of a Safe contract from version 1.1.1 to 1.3.0/1.4.1 L2, 1.3.0 to 1.3.0L2 or from 1.4.1 to 1.4.1L2
 *         Other versions are not supported
 * @dev IMPORTANT: The migration will only work with proxies that store the implementation address in the storage slot 0.
 */
contract SafeToL2Migration is SafeStorage {
    // Address of this contract
    address public immutable MIGRATION_SINGLETON;

    /**
     * @notice Constructor
     * @dev Initializes the migrationSingleton with the contract's own address.
     */
    constructor() {
        MIGRATION_SINGLETON = address(this);
    }

    /**
     * @notice Event indicating a change of master copy address.
     * @param singleton New master copy address
     */
    event ChangedMasterCopy(address singleton);

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);

    event SafeMultiSigTransaction(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes signatures,
        // We combine nonce, sender and threshold into one to avoid stack too deep
        // Dev note: additionalInfo should not contain `bytes`, as this complicates decoding
        bytes additionalInfo
    );

    /**
     * @notice Modifier to make a function callable via delegatecall only.
     * If the function is called via a regular call, it will revert.
     */
    modifier onlyDelegateCall() {
        require(address(this) != MIGRATION_SINGLETON, "Migration should only be called via delegatecall");
        _;
    }

    /**
     * @notice Modifier to prevent using initialized Safes.
     * If Safe has a nonce higher than 0, it will revert
     */
    modifier onlyNonceZero() {
        // Nonce is increased before executing a tx, so first executed tx will have nonce=1
        require(nonce == 1, "Safe must have not executed any tx");
        _;
    }

    /**
     * @dev Internal function with common migration steps, changes the singleton and emits SafeMultiSigTransaction event
     */
    function migrate(address l2Singleton, bytes memory functionData) private {
        singleton = l2Singleton;

        // Encode nonce, sender, threshold
        bytes memory additionalInfo = abi.encode(0, msg.sender, threshold);

        // Simulate a L2 transaction so Safe Tx Service indexer picks up the Safe
        emit SafeMultiSigTransaction(
            MIGRATION_SINGLETON,
            0,
            functionData,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            "", // We cannot detect signatures
            additionalInfo
        );
        emit ChangedMasterCopy(singleton);
    }

    /**
     * @notice Migrate from Safe 1.3.0/1.4.1 Singleton (L1) to the same version provided L2 singleton
     * Safe is required to have nonce 0 so backend can support it after the migration
     * @dev This function should only be called via a delegatecall to perform the upgrade.
     * Singletons versions will be compared, so it implies that contracts exist
     */
    function migrateToL2(address l2Singleton) public onlyDelegateCall onlyNonceZero {
        require(address(singleton) != l2Singleton, "Safe is already using the singleton");
        bytes32 oldSingletonVersion = keccak256(abi.encodePacked(ISafe(singleton).VERSION()));
        bytes32 newSingletonVersion = keccak256(abi.encodePacked(ISafe(l2Singleton).VERSION()));

        require(oldSingletonVersion == newSingletonVersion, "L2 singleton must match current version singleton");
        // There's no way to make sure if address is a valid singleton, unless we configure the contract for every chain
        require(
            newSingletonVersion == keccak256(abi.encodePacked("1.3.0")) || newSingletonVersion == keccak256(abi.encodePacked("1.4.1")),
            "Provided singleton version is not supported"
        );

        // 0xef2624ae - keccak("migrateToL2(address)")
        bytes memory functionData = abi.encodeWithSelector(0xef2624ae, l2Singleton);
        migrate(l2Singleton, functionData);
    }

    /**
     * @notice Migrate from Safe 1.1.1 Singleton to 1.3.0 or 1.4.1 L2
     * Safe is required to have nonce 0 so backend can support it after the migration
     * @dev This function should only be called via a delegatecall to perform the upgrade.
     * Singletons version will be checked, so it implies that contracts exist.
     * A valid and compatible fallbackHandler needs to be provided, only existance will be checked.
     */
    function migrateFromV111(address l2Singleton, address fallbackHandler) public onlyDelegateCall onlyNonceZero {
        require(isContract(fallbackHandler), "fallbackHandler is not a contract");

        bytes32 oldSingletonVersion = keccak256(abi.encodePacked(ISafe(singleton).VERSION()));
        require(oldSingletonVersion == keccak256(abi.encodePacked("1.1.1")), "Provided singleton version is not supported");

        bytes32 newSingletonVersion = keccak256(abi.encodePacked(ISafe(l2Singleton).VERSION()));
        require(
            newSingletonVersion == keccak256(abi.encodePacked("1.3.0")) || newSingletonVersion == keccak256(abi.encodePacked("1.4.1")),
            "Provided singleton version is not supported"
        );

        ISafe safe = ISafe(address(this));
        safe.setFallbackHandler(fallbackHandler);

        // Safes < 1.3.0 did not emit SafeSetup, so Safe Tx Service backend needs the event to index the Safe
        emit SafeSetup(MIGRATION_SINGLETON, safe.getOwners(), safe.getThreshold(), address(0), fallbackHandler);

        // 0xd9a20812 - keccak("migrateFromV111(address,address)")
        bytes memory functionData = abi.encodeWithSelector(0xd9a20812, l2Singleton, fallbackHandler);
        migrate(l2Singleton, functionData);
    }

    /**
     * @notice Checks whether an Ethereum address corresponds to a contract or an externally owned account (EOA).
     * @param account The Ethereum address to be checked.
     * @return A boolean value indicating whether the address is associated with a contract (true) or an EOA (false).
     * @dev This function relies on the `extcodesize` assembly opcode to determine whether an address is a contract.
     * It may return incorrect results in some edge cases (see documentation for details).
     * Developers should use caution when relying on the results of this function for critical decision-making.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            size := extcodesize(account)
        }
        /* solhint-enable no-inline-assembly */

        // If the code size is greater than 0, it is a contract; otherwise, it is an EOA.
        return size > 0;
    }
}