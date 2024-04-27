// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable no-inline-assembly */


 /*
  * For simulation purposes, validateUserOp (and validatePaymasterUserOp)
  * must return this value in case of signature failure, instead of revert.
  */
uint256 constant SIG_VALIDATION_FAILED = 1;


/*
 * For simulation purposes, validateUserOp (and validatePaymasterUserOp)
 * return this value on success.
 */
uint256 constant SIG_VALIDATION_SUCCESS = 0;


/**
 * Returned data from validateUserOp.
 * validateUserOp returns a uint256, which is created by `_packedValidationData` and
 * parsed by `_parseValidationData`.
 * @param aggregator  - address(0) - The account validated the signature by itself.
 *                      address(1) - The account failed to validate the signature.
 *                      otherwise - This is an address of a signature aggregator that must
 *                                  be used to validate the signature.
 * @param validAfter  - This UserOp is valid only after this timestamp.
 * @param validaUntil - This UserOp is valid only up to this timestamp.
 */
struct ValidationData {
    address aggregator;
    uint48 validAfter;
    uint48 validUntil;
}

/**
 * Extract sigFailed, validAfter, validUntil.
 * Also convert zero validUntil to type(uint48).max.
 * @param validationData - The packed validation data.
 */
function _parseValidationData(
    uint256 validationData
) pure returns (ValidationData memory data) {
    address aggregator = address(uint160(validationData));
    uint48 validUntil = uint48(validationData >> 160);
    if (validUntil == 0) {
        validUntil = type(uint48).max;
    }
    uint48 validAfter = uint48(validationData >> (48 + 160));
    return ValidationData(aggregator, validAfter, validUntil);
}

/**
 * Helper to pack the return value for validateUserOp.
 * @param data - The ValidationData to pack.
 */
function _packValidationData(
    ValidationData memory data
) pure returns (uint256) {
    return
        uint160(data.aggregator) |
        (uint256(data.validUntil) << 160) |
        (uint256(data.validAfter) << (160 + 48));
}

/**
 * Helper to pack the return value for validateUserOp, when not using an aggregator.
 * @param sigFailed  - True for signature failure, false for success.
 * @param validUntil - Last timestamp this UserOperation is valid (or zero for infinite).
 * @param validAfter - First timestamp this UserOperation is valid.
 */
function _packValidationData(
    bool sigFailed,
    uint48 validUntil,
    uint48 validAfter
) pure returns (uint256) {
    return
        (sigFailed ? 1 : 0) |
        (uint256(validUntil) << 160) |
        (uint256(validAfter) << (160 + 48));
}

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly ("memory-safe") {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }


/**
 * The minimum of two numbers.
 * @param a - First number.
 * @param b - Second number.
 */
    function min(uint256 a, uint256 b) pure returns (uint256) {
        return a < b ? a : b;
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";

interface IAccount {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp              - The operation that is about to be executed.
     * @param userOpHash          - Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds - Missing funds on the account's deposit in the entrypoint.
     *                              This is the minimum amount to transfer to the sender(entryPoint) to be
     *                              able to make the call. The excess is left as a deposit in the entrypoint
     *                              for future calls. Can be withdrawn anytime using "entryPoint.withdrawTo()".
     *                              In case there is a paymaster in the request (or the current deposit is high
     *                              enough), this value will be zero.
     * @return validationData       - Packaged ValidationData structure. use `_packValidationData` and
     *                              `_unpackValidationData` to encode and decode.
     *                              <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *                                 otherwise, an address of an "authorizer" contract.
     *                              <6-byte> validUntil - Last timestamp this operation is valid. 0 for "indefinite"
     *                              <6-byte> validAfter - First timestamp this operation is valid
     *                                                    If an account doesn't use time-range, it is enough to
     *                                                    return SIG_VALIDATION_FAILED value (1) for signature failure.
     *                              Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param gasFees               - packed gas fields maxPriorityFeePerGas and maxFeePerGas - Same as EIP-1559 gas parameters.
 * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SafeStorage - Storage layout of the Safe contracts to be used in libraries.
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {_packValidationData} from "@account-abstraction/contracts/core/Helpers.sol";
import {SafeStorage} from "@safe-global/safe-contracts/contracts/libraries/SafeStorage.sol";

import {ISafeSignerFactory, P256} from "../interfaces/ISafeSignerFactory.sol";
import {ISafe} from "../interfaces/ISafe.sol";
import {ERC1271} from "../libraries/ERC1271.sol";

/**
 * @title Safe Launchpad for Custom ECDSA Signing Schemes.
 * @dev A launchpad account implementation that enables the creation of Safes that use custom ECDSA signing schemes that
 * require additional contract deployments over ERC-4337. Note that it is not safe to rely on this launchpad for
 * deploying Safes that has an initial threshold greater than 1. This is because the first user operation (which can
 * freely change the owner structure) will only ever require a single signature to execute, so effectively the initial
 * owner will always have ultimate control over the Safe during the first user operation and can undo any changes to the
 * `threshold` during the `setup` phase.
 * @custom:security-contact [email protected]
 */
contract SafeSignerLaunchpad is IAccount, SafeStorage {
    /**
     * @notice The EIP-712 type-hash for the domain separator used for verifying Safe initialization signatures.
     * @custom:computed-as keccak256("EIP712Domain(uint256 chainId,address verifyingContract)")
     */
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    /**
     * @notice The storage slot used for the initialization hash of account.
     * @custom:computed-as keccak256("SafeSignerLaunchpad.initHash") - 1
     * @dev This value is intentionally computed to be a hash -1 as a precaution to avoid any potential issues from
     * unintended hash collisions.
     */
    uint256 private constant INIT_HASH_SLOT = 0xf69b06f613646416443af565ceba6ea1636a94376678b14dc8481b819746897f;

    /**
     * @notice The keccak256 hash of the EIP-712 SafeInit struct, representing the structure of a ERC-4337 compatible deferred Safe initialization.
     *  {address} singleton - The singleton to evolve into during the setup.
     *  {address} signerFactory - The custom ECDSA signer factory to use for creating an owner.
     *  {uint256} signerX - The X coordinate of the public key of the custom ECDSA signing scheme.
     *  {uint256} signerY - The Y coordinate of the public key of the custom ECDSA signing scheme.
     *  {uint256} signerVerifiers - The P-256 verifiers to use for signature validation.
     *  {address} setupTo - The contract to `DELEGATECALL` during setup.
     *  {bytes} setupData - The calldata for the setup `DELEGATECALL`.
     *  {address} fallbackHandler - The fallback handler to initialize the Safe with.
     * @custom:computed-as keccak256("SafeInit(address singleton,address signerFactory,uint256 signerX,uint256 signerY,uint192 signerVerifiers,address setupTo,bytes setupData,address fallbackHandler)")
     */
    bytes32 private constant SAFE_INIT_TYPEHASH = 0xb8b5d6678d8c3ed815330874b6c0a30142f64104b7f6d1361d6775a7dbc5318b;

    /**
     * @notice The keccak256 hash of the EIP-712 SafeInitOp struct, representing the user operation to execute alongside initialization.
     *  {bytes32} userOpHash - The user operation hash being executed.
     *  {uint48} validAfter - A timestamp representing from when the user operation is valid.
     *  {uint48} validUntil - A timestamp representing until when the user operation is valid, or 0 to indicated "forever".
     *  {address} entryPoint - The address of the entry point that will execute the user operation.
     * @custom:computed-as keccak256("SafeInitOp(bytes32 userOpHash,uint48 validAfter,uint48 validUntil,address entryPoint)")
     */
    bytes32 private constant SAFE_INIT_OP_TYPEHASH = 0x25838d3914a61e3531f21f12b8cd3110a5f9d478292d07dd197859a5c4eaacb2;

    /**
     * @dev Address of the launchpad contract itself. it is used for determining whether or not the contract is being
     * `DELEGATECALL`-ed from a proxy.
     */
    address private immutable SELF;

    /**
     * @notice The address of the ERC-4337 entry point contract that this launchpad supports.
     */
    address public immutable SUPPORTED_ENTRYPOINT;

    /**
     * @notice Create a new launchpad contract instance.
     * @param entryPoint The address of the ERC-4337 entry point contract that this launchpad supports.
     */
    constructor(address entryPoint) {
        require(entryPoint != address(0), "Invalid entry point");

        SELF = address(this);
        SUPPORTED_ENTRYPOINT = entryPoint;
    }

    /**
     * @notice Validates the call is done via a proxy contract via `DELEGATECALL`, and that the launchpad is not being
     * called directly.
     */
    modifier onlyProxy() {
        require(singleton == SELF, "Not called from proxy");
        _;
    }

    /**
     * @notice Validates the call is initiated by the supported entry point.
     */
    modifier onlySupportedEntryPoint() {
        require(msg.sender == SUPPORTED_ENTRYPOINT, "Unsupported entry point");
        _;
    }

    /**
     * @notice Accept transfers.
     * @dev The launchpad accepts transfers to allow funding of the account in case it was deployed and initialized
     * without pre-funding.
     */
    receive() external payable {}

    /**
     * @notice Performs pre-validation setup by storing the hash of the {SafeInit} and optionally `DELEGATECALL`s to a
     * `preInitializer` contract to perform some initial setup.
     * @dev Requirements:
     * - The function can only be called by a proxy contract.
     * - The `DELEGATECALL` to the `preInitializer` address must succeed.
     * @param initHash The initialization hash.
     * @param preInitializer The address to `DELEGATECALL`.
     * @param preInitializerData The pre-initialization call data.
     */
    function preValidationSetup(bytes32 initHash, address preInitializer, bytes calldata preInitializerData) external onlyProxy {
        _setInitHash(initHash);
        if (preInitializer != address(0)) {
            (bool success, ) = preInitializer.delegatecall(preInitializerData);
            require(success, "Pre-initialization failed");
        }
    }

    /**
     * @notice Compute an {SafeInit} hash that uniquely identifies a Safe configuration.
     * @dev The hash is generated using the keccak256 hash function and the EIP-712 standard. It includes setup
     * parameters to ensure that deployments with the Safe proxy factory have a unique and deterministic address for a
     * given configuration.
     * @param singleton The singleton to evolve into during the setup.
     * @param signerFactory The custom ECDSA signer factory to use for creating an owner.
     * @param signerX The X coordinate of the signer's public key.
     * @param signerY The Y coordinate of the signer's public key.
     * @param signerVerifiers The P-256 verifiers to use for signature validation.
     * @param setupTo The contract to `DELEGATECALL` during setup.
     * @param setupData The calldata for the setup `DELEGATECALL`.
     * @param fallbackHandler The fallback handler to initialize the Safe with.
     * @return initHash The unique initialization hash for the Safe.
     */
    function getInitHash(
        address singleton,
        address signerFactory,
        uint256 signerX,
        uint256 signerY,
        P256.Verifiers signerVerifiers,
        address setupTo,
        bytes memory setupData,
        address fallbackHandler
    ) public view returns (bytes32 initHash) {
        initHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator(),
                keccak256(
                    abi.encode(
                        SAFE_INIT_TYPEHASH,
                        singleton,
                        signerFactory,
                        signerX,
                        signerY,
                        signerVerifiers,
                        setupTo,
                        keccak256(setupData),
                        fallbackHandler
                    )
                )
            )
        );
    }

    /**
     * @notice Compute the {SafeInitOp} hash of the first user operation that initializes the Safe.
     * @dev The hash is generated using the keccak256 hash function and the EIP-712 standard. It is signed by the Safe
     * owner that is specified as part of the {SafeInit}. Using a completely separate hash from the {SafeInit} allows
     * the account address to remain the same regardless of the first user operation that gets executed by the account.
     * @param userOpHash The ERC-4337 user operation hash.
     * @param validAfter The timestamp the user operation is valid from.
     * @param validUntil The timestamp the user operation is valid until.
     * @return operationHash The Safe initialization user operation hash.
     */
    function getOperationHash(bytes32 userOpHash, uint48 validAfter, uint48 validUntil) public view returns (bytes32 operationHash) {
        operationHash = keccak256(
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator(),
                keccak256(abi.encode(SAFE_INIT_OP_TYPEHASH, userOpHash, validAfter, validUntil, SUPPORTED_ENTRYPOINT))
            )
        );
    }

    /**
     * @notice Validates a user operation provided by the entry point.
     * @inheritdoc IAccount
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override onlyProxy onlySupportedEntryPoint returns (uint256 validationData) {
        address signerFactory;
        uint256 signerX;
        uint256 signerY;
        P256.Verifiers signerVerifiers;
        {
            require(this.initializeThenUserOp.selector == bytes4(userOp.callData[:4]), "invalid user operation data");

            address singleton;
            address setupTo;
            bytes memory setupData;
            address fallbackHandler;
            (singleton, signerFactory, signerX, signerY, signerVerifiers, setupTo, setupData, fallbackHandler, ) = abi.decode(
                userOp.callData[4:],
                (address, address, uint256, uint256, P256.Verifiers, address, bytes, address, bytes)
            );
            bytes32 initHash = getInitHash(
                singleton,
                signerFactory,
                signerX,
                signerY,
                signerVerifiers,
                setupTo,
                setupData,
                fallbackHandler
            );

            require(initHash == _initHash(), "invalid init hash");
        }

        validationData = _validateSignatures(userOp, userOpHash, signerFactory, signerX, signerY, signerVerifiers);
        if (missingAccountFunds > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly ("memory-safe") {
                // The `pop` is necessary here because solidity 0.5.0 enforces "strict" assembly blocks and "statements
                // (elements of a block) are disallowed if they return something onto the stack at the end". This is not
                // well documented, the quote is taken from <https://github.com/ethereum/solidity/issues/1820>. The
                // compiler will throw an error if we keep the success value on the stack
                pop(call(gas(), caller(), missingAccountFunds, 0, 0, 0, 0))
            }
        }
    }

    /**
     * @notice Completes the account initialization and then executes a user operation.
     * @dev This function is only ever called by the entry point as part of the execution phase of the user operation.
     * It is responsible for promoting the account into a Safe. Validation of the parameters, that they match the
     * {SafeInit} hash that was specified at account construction, is done by {validateUserOp} as part of the the
     * ERC-4337 user operation validation phase.
     * @param singleton The Safe singleton address to promote the account into.
     * @param signerFactory The custom ECDSA signer factory to use for creating an owner.
     * @param signerX The X coordinate of the signer's public key.
     * @param signerY The Y coordinate of the signer's public key.
     * @param signerVerifiers The P-256 verifiers to use for signature validation.
     * @param setupTo The contract to `DELEGATECALL` during setup.
     * @param setupData The calldata for the setup `DELEGATECALL`.
     * @param fallbackHandler The fallback handler to initialize the Safe with.
     * @param callData The calldata to `DELEGATECALL` self with in order to actually execute the user operation.
     */
    function initializeThenUserOp(
        address singleton,
        address signerFactory,
        uint256 signerX,
        uint256 signerY,
        P256.Verifiers signerVerifiers,
        address setupTo,
        bytes calldata setupData,
        address fallbackHandler,
        bytes memory callData
    ) external onlySupportedEntryPoint {
        SafeStorage.singleton = singleton;
        {
            address[] memory owners = new address[](1);
            owners[0] = ISafeSignerFactory(signerFactory).createSigner(signerX, signerY, signerVerifiers);

            ISafe(address(this)).setup(owners, 1, setupTo, setupData, fallbackHandler, address(0), 0, payable(address(0)));
        }

        (bool success, bytes memory returnData) = address(this).delegatecall(callData);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly ("memory-safe") {
                revert(add(returnData, 0x20), mload(returnData))
            }
        }

        _setInitHash(0);
    }

    /**
     * @notice Computes the EIP-712 domain separator for Safe launchpad operations.
     * @return domainSeparatorHash The EIP-712 domain separator hash for this contract.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, block.chainid, SELF));
    }

    /**
     * @dev Validates that the user operation is correctly signed and returns an ERC-4337 packed validation data
     * of `validAfter || validUntil || authorizer`:
     *  - `authorizer`: 20-byte address, 0 for valid signature or 1 to mark signature failure (this module does not make use of signature aggregators).
     *  - `validUntil`: 6-byte timestamp value, or zero for "infinite". The user operation is valid only up to this time.
     *  - `validAfter`: 6-byte timestamp. The user operation is valid only after this time.
     * @param userOp User operation struct.
     * @param userOpHash User operation hash.
     * @param signerFactory The custom ECDSA signer factory to use for creating an owner.
     * @param signerX The X coordinate of the signer's public key.
     * @param signerY The Y coordinate of the signer's public key.
     * @param signerVerifiers The P-256 verifiers to use for signature validation.
     * @return validationData An integer indicating the result of the validation.
     */
    function _validateSignatures(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        address signerFactory,
        uint256 signerX,
        uint256 signerY,
        P256.Verifiers signerVerifiers
    ) internal view returns (uint256 validationData) {
        uint48 validAfter;
        uint48 validUntil;
        bytes calldata signature;
        {
            bytes calldata sig = userOp.signature;
            validAfter = uint48(bytes6(sig[0:6]));
            validUntil = uint48(bytes6(sig[6:12]));
            signature = sig[12:];
        }

        bytes32 operationHash = getOperationHash(userOpHash, validAfter, validUntil);
        try
            ISafeSignerFactory(signerFactory).isValidSignatureForSigner(operationHash, signature, signerX, signerY, signerVerifiers)
        returns (bytes4 magicValue) {
            // The timestamps are validated by the entry point, therefore we will not check them again
            validationData = _packValidationData(magicValue != ERC1271.MAGIC_VALUE, validUntil, validAfter);
        } catch {
            validationData = _packValidationData(true, validUntil, validAfter);
        }
    }

    /**
     * @notice Reads the configured initialization hash from storage.
     * @return value The value of the init hash read from storage.
     */
    function _initHash() public view returns (bytes32 value) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            value := sload(INIT_HASH_SLOT)
        }
    }

    /**
     * @notice Sets an initialization hash in storage.
     * @param value The value of the init hash to set in storage.
     */
    function _setInitHash(bytes32 value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            sstore(INIT_HASH_SLOT, value)
        }
    }

    /**
     * @notice Returns whether or not an account is a contract.
     * @dev The current implementation the accounts code size is non-zero to determine whether or not the account is a
     * contract.
     * @param account The account to check.
     * @return isContract Whether or not the account is a contract.
     */
    function _isContract(address account) internal view returns (bool isContract) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            size := extcodesize(account)
        }
        isContract = size > 0;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
/* solhint-disable payable-fallback */
pragma solidity ^0.8.0;

/**
 * @title P-256 Elliptic Curve Verifier.
 * @dev P-256 verifier contract that follows the EIP-7212 EC verify precompile interface. For more
 * details, refer to the EIP-7212 specification: <https://eips.ethereum.org/EIPS/eip-7212>
 * @custom:security-contact [email protected]
 */
interface IP256Verifier {
    /**
     * @notice  A fallback function that takes the following input format and returns a result
     * indicating whether the signature is valid or not:
     * - `input[  0: 32]`: message
     * - `input[ 32: 64]`: signature r
     * - `input[ 64: 96]`: signature s
     * - `input[ 96:128]`: public key x
     * - `input[128:160]`: public key y
     *
     * The output is either:
     * - `abi.encode(1)` bytes for a valid signature.
     * - `""` empty bytes for an invalid signature or error.
     *
     * Note that this function does not follow the Solidity ABI format (in particular, it does not
     * have a 4-byte selector), which is why it requires a fallback function and not regular
     * Solidity function. Additionally, it has `view` function semantics, and is expected to be
     * called with `STATICCALL` opcode.
     *
     * @param input The encoded input parameters.
     * @return output The encoded signature verification result.
     */
    fallback(bytes calldata input) external returns (bytes memory output);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

interface ISafe {
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
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

import {P256} from "../libraries/P256.sol";

/**
 * @title Signer Factory for Custom P-256 Signing Schemes
 * @dev Interface for a factory contract that can create ERC-1271 compatible signers, and verify
 * signatures for custom P-256 signing schemes.
 * @custom:security-contact [email protected]
 */
interface ISafeSignerFactory {
    /**
     * @notice Gets the unique signer address for the specified data.
     * @dev The unique signer address must be unique for some given data. The signer is not
     * guaranteed to be created yet.
     * @param x The x-coordinate of the public key.
     * @param y The y-coordinate of the public key.
     * @param verifiers The P-256 verifiers to use.
     * @return signer The signer address.
     */
    function getSigner(uint256 x, uint256 y, P256.Verifiers verifiers) external view returns (address signer);

    /**
     * @notice Create a new unique signer for the specified data.
     * @dev The unique signer address must be unique for some given data. This must not revert if
     * the unique owner already exists.
     * @param x The x-coordinate of the public key.
     * @param y The y-coordinate of the public key.
     * @param verifiers The P-256 verifiers to use.
     * @return signer The signer address.
     */
    function createSigner(uint256 x, uint256 y, P256.Verifiers verifiers) external returns (address signer);

    /**
     * @notice Verifies a signature for the specified address without deploying it.
     * @dev This must be equivalent to first deploying the signer with the factory, and then
     * verifying the signature with it directly:
     * `factory.createSigner(signerData).isValidSignature(message, signature)`
     * @param message The signed message.
     * @param signature The signature bytes.
     * @param x The x-coordinate of the public key.
     * @param y The y-coordinate of the public key.
     * @param verifiers The P-256 verifiers to use.
     * @return magicValue Returns the ERC-1271 magic value when the signature is valid. Reverting or
     * returning any other value implies an invalid signature.
     */
    function isValidSignatureForSigner(
        bytes32 message,
        bytes calldata signature,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title ERC-1271 Magic Values
 * @dev Library that defines constants for ERC-1271 related magic values.
 * @custom:security-contact [email protected]
 */
library ERC1271 {
    /**
     * @notice ERC-1271 magic value returned on valid signatures.
     * @dev Value is derived from `bytes4(keccak256("isValidSignature(bytes32,bytes)")`.
     */
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    /**
     * @notice Legacy EIP-1271 magic value returned on valid signatures.
     * @dev This value was used in previous drafts of the EIP-1271 standard, but replaced by
     * {MAGIC_VALUE} in the final version.
     *
     * Value is derived from `bytes4(keccak256("isValidSignature(bytes,bytes)")`.
     */
    bytes4 internal constant LEGACY_MAGIC_VALUE = 0x20c13b0b;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {IP256Verifier} from "../interfaces/IP256Verifier.sol";

/**
 * @title P-256 Elliptic Curve Verification Library.
 * @dev Library P-256 verification with contracts that follows the EIP-7212 EC verify precompile
 * interface. See <https://eips.ethereum.org/EIPS/eip-7212>.
 * @custom:security-contact [email protected]
 */
library P256 {
    /**
     * @notice P-256 curve order n divided by 2 for the signature malleability check.
     * @dev By convention, non-malleable signatures must have an `s` value that is less than half of
     * the curve order.
     */
    uint256 internal constant _N_DIV_2 = 57896044605178124381348723474703786764998477612067880171211129530534256022184;

    /**
     * @notice P-256 precompile and fallback verifiers.
     * @dev This is the packed `uint32(precompile) | uint160(fallback)` addresses to use for the
     * verifiers. This allows both a precompile and a fallback Solidity implementation of the P-256
     * curve to be specified. For networks where the P-256 precompile is planned to be enabled but
     * not yet available, this allows for a verifier to seamlessly start using the precompile once
     * it becomes available.
     */
    type Verifiers is uint192;

    /**
     * @notice Verifies the signature of a message using the P256 elliptic curve with signature
     * malleability check.
     * @dev Note that a signature is valid for both `+s` and `-s`, making it trivial to, given a
     * signature, generate another valid signature by flipping the sign of the `s` value in the
     * prime field defined by the P-256 curve order `n`. This signature verification method checks
     * that `1 <= s <= n/2` to prevent malleability, such that there is a unique `s` value that is
     * accepted for a given signature. Note that for many protocols, signature malleability is not
     * an issue, so the use of {verifySignatureAllowMalleability} as long as only that the signature
     * is valid is important, and not its actual value.
     * @param verifier The P-256 verifier.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignature(
        IP256Verifier verifier,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        if (s > _N_DIV_2) {
            return false;
        }

        success = verifySignatureAllowMalleability(verifier, message, r, s, x, y);
    }

    /**
     * @notice Verifies the signature of a message using the P256 elliptic curve with signature
     * malleability check.
     * @param verifiers The P-256 verifiers to use.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignature(
        Verifiers verifiers,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        if (s > _N_DIV_2) {
            return false;
        }

        success = verifySignatureAllowMalleability(verifiers, message, r, s, x, y);
    }

    /**
     * @notice Verifies the signature of a message using P256 elliptic curve, without signature
     * malleability check.
     * @param verifier The P-256 verifier.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignatureAllowMalleability(
        IP256Verifier verifier,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // Prepare input for staticcall
            let input := mload(0x40) // Free memory pointer
            mstore(input, message)
            mstore(add(input, 32), r)
            mstore(add(input, 64), s)
            mstore(add(input, 96), x)
            mstore(add(input, 128), y)

            // Perform staticcall and check result, note that Yul evaluates expressions from right
            // to left. See <https://docs.soliditylang.org/en/v0.8.24/yul.html#function-calls>.
            mstore(0, 0)
            success := and(
                and(
                    // Return data is exactly 32-bytes long
                    eq(returndatasize(), 32),
                    // Return data is exactly the value 0x00..01
                    eq(mload(0), 1)
                ),
                // Call does not revert
                staticcall(gas(), verifier, input, 160, 0, 32)
            )
        }
    }

    /**
     * @notice Verifies the signature of a message using P256 elliptic curve, without signature
     * malleability check.
     * @param verifiers The P-256 verifiers to use.
     * @param message The signed message.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @param x The x coordinate of the public key.
     * @param y The y coordinate of the public key.
     * @return success A boolean indicating whether the signature is valid or not.
     */
    function verifySignatureAllowMalleability(
        Verifiers verifiers,
        bytes32 message,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y
    ) internal view returns (bool success) {
        address precompileVerifier = address(uint160(uint256(Verifiers.unwrap(verifiers)) >> 160));
        address fallbackVerifier = address(uint160(Verifiers.unwrap(verifiers)));
        if (precompileVerifier != address(0)) {
            success = verifySignatureAllowMalleability(IP256Verifier(precompileVerifier), message, r, s, x, y);
        }

        // If the precompile verification was not successful, fallback to a configured Solidity {IP256Verifier}
        // implementation. Note that this means that invalid signatures are potentially checked twice, once with the
        // precompile and once with the fallback verifier. This is intentional as there is no reliable way to
        // distinguish between the precompile being unavailable and the signature being invalid, as in both cases the
        // `STATICCALL` to the precompile contract will return empty bytes.
        if (!success && fallbackVerifier != address(0)) {
            success = verifySignatureAllowMalleability(IP256Verifier(fallbackVerifier), message, r, s, x, y);
        }
    }
}