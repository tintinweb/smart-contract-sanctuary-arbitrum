// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and parsed by `_parseValidationData`
 * @param aggregator - address(0) - the account validated the signature by itself.
 *              address(1) - the account failed to validate the signature.
 *              otherwise - this is an address of a signature aggregator that must be used to validate the signature.
 * @param validAfter - this UserOp is valid only after this timestamp.
 * @param validaUntil - this UserOp is valid only up to this timestamp.
 */
    struct ValidationData {
        address aggregator;
        uint48 validAfter;
        uint48 validUntil;
    }

//extract sigFailed, validAfter, validUntil.
// also convert zero validUntil to type(uint48).max
    function _parseValidationData(uint validationData) pure returns (ValidationData memory data) {
        address aggregator = address(uint160(validationData));
        uint48 validUntil = uint48(validationData >> 160);
        if (validUntil == 0) {
            validUntil = type(uint48).max;
        }
        uint48 validAfter = uint48(validationData >> (48 + 160));
        return ValidationData(aggregator, validAfter, validUntil);
    }

// intersect account and paymaster ranges.
    function _intersectTimeRange(uint256 validationData, uint256 paymasterValidationData) pure returns (ValidationData memory) {
        ValidationData memory accountValidationData = _parseValidationData(validationData);
        ValidationData memory pmValidationData = _parseValidationData(paymasterValidationData);
        address aggregator = accountValidationData.aggregator;
        if (aggregator == address(0)) {
            aggregator = pmValidationData.aggregator;
        }
        uint48 validAfter = accountValidationData.validAfter;
        uint48 validUntil = accountValidationData.validUntil;
        uint48 pmValidAfter = pmValidationData.validAfter;
        uint48 pmValidUntil = pmValidationData.validUntil;

        if (validAfter < pmValidAfter) validAfter = pmValidAfter;
        if (validUntil > pmValidUntil) validUntil = pmValidUntil;
        return ValidationData(aggregator, validAfter, validUntil);
    }

/**
 * helper to pack the return value for validateUserOp
 * @param data - the ValidationData to pack
 */
    function _packValidationData(ValidationData memory data) pure returns (uint256) {
        return uint160(data.aggregator) | (uint256(data.validUntil) << 160) | (uint256(data.validAfter) << (160 + 48));
    }

/**
 * helper to pack the return value for validateUserOp, when not using an aggregator
 * @param sigFailed - true for signature failure, false for success
 * @param validUntil last timestamp this UserOperation is valid (or zero for infinite)
 * @param validAfter first timestamp this UserOperation is valid
 */
    function _packValidationData(bool sigFailed, uint48 validUntil, uint48 validAfter) pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << (160 + 48));
    }

/**
 * keccak function over calldata.
 * @dev copy calldata into memory, do keccak and drop allocated memory. Strangely, this is more efficient than letting solidity do it.
 */
    function calldataKeccak(bytes calldata data) pure returns (bytes32 ret) {
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

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
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return validationData packaged ValidationData structure. use `_packValidationData` and `_unpackValidationData` to encode and decode
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If an account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {

    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(UserOperation[] calldata userOps, bytes calldata signature) external view;

    /**
     * validate signature of a single userOp
     * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
    external view returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatedSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature);
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";
import "./INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {

    /***
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request.
     * @param success - true if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - total gas used by this UserOperation (including preVerification, creation, validation and execution).
     */
    event UserOperationEvent(bytes32 indexed userOpHash, address indexed sender, address indexed paymaster, uint256 nonce, bool success, uint256 actualGasCost, uint256 actualGasUsed);

    /**
     * account "sender" was deployed.
     * @param userOpHash the userOp that deployed this account. UserOperationEvent will follow.
     * @param sender the account that is deployed
     * @param factory the factory used to deploy this account (in the initCode)
     * @param paymaster the paymaster used by this UserOp
     */
    event AccountDeployed(bytes32 indexed userOpHash, address indexed sender, address factory, address paymaster);

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

    /**
     * an event emitted by handleOps(), before starting the execution loop.
     * any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();

    /**
     * signature aggregator used by the following UserOperationEvents within this bundle.
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param reason - revert reason
     *      The string starts with a unique code "AAmn", where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
     *      so a failure can be attributed to the correct entity.
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    /**
     * Successful result from simulateValidation.
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error ValidationResult(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param returnInfo gas and time-range returned values
     * @param senderInfo stake information about the sender
     * @param factoryInfo stake information about the factory (if any)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error ValidationResultWithAggregation(ReturnInfo returnInfo,
        StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo);

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);

    /**
     * return value of simulateHandleOp
     */
    error ExecutionResult(uint256 preOpGas, uint256 paid, uint48 validAfter, uint48 validUntil, bool targetSuccess, bytes targetResult);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;

        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(UserOperation[] calldata ops, address payable beneficiary) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(UserOperation calldata userOp) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is ValidationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * gas and return values during simulation
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param sigFailed validateUserOp's (or paymaster's) signature check failed
     * @param validAfter - first timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param validUntil - last timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param paymasterContext returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        bool sigFailed;
        uint48 validAfter;
        uint48 validUntil;
        bytes paymasterContext;
    }

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address aggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;


    /**
     * simulate full execution of a UserOperation (including both validation and target execution)
     * this method will always revert with "ExecutionResult".
     * it performs full validation of the UserOperation, but ignores signature error.
     * an optional target address is called after the userop succeeds, and its value is returned
     * (before the entire call is reverted)
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     * @param op the UserOperation to simulate
     * @param target if nonzero, a target address to call after userop simulation. If called, the targetSuccess and targetResult
     *        are set to the return from that call.
     * @param targetCallData callData to pass to target address
     */
    function simulateHandleOp(UserOperation calldata op, address target, bytes calldata targetCallData) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface INonceManager {

    /**
     * Return the next nonce for this sender.
     * Within a given key, the nonce values are sequenced (starting with zero, and incremented by one on each userop)
     * But UserOp with different keys can come with arbitrary order.
     *
     * @param sender the account address
     * @param key the high 192 bit of the nonce
     * @return nonce a full nonce to pass for next UserOp with this sender.
     */
    function getNonce(address sender, uint192 key)
    external view returns (uint256 nonce);

    /**
     * Manually increment the nonce of the sender.
     * This method is exposed just for completeness..
     * Account does NOT need to call it, neither during validation, nor elsewhere,
     * as the EntryPoint will update the nonce regardless.
     * Possible use-case is call it with various keys to "initialize" their nonces to one, so that future
     * UserOperations will not pay extra for the first transaction with a given key.
     */
    function incrementNonce(uint192 key) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {

    event Deposited(
        address indexed account,
        uint256 totalDeposit
    );

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// Emitted when stake or unstake delay are modified
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 unstakeDelaySec
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(
        address indexed account,
        uint256 withdrawTime
    );

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the entity's deposit
     * @param staked true if this entity is staked.
     * @param stake actual amount of ether staked for this entity.
     * @param unstakeDelaySec minimum delay to withdraw the stake.
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 10^15 eth
     *    48 bit for full timestamp
     *    32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    //API struct used by getStakeInfo and simulateValidation
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    /// @return info - full deposit information of given account
    function getDepositInfo(address account) external view returns (DepositInfo memory info);

    /// @return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        uint256 callGasLimit = userOp.callGasLimit;
        uint256 verificationGasLimit = userOp.verificationGasLimit;
        uint256 preVerificationGas = userOp.preVerificationGas;
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            callGasLimit, verificationGasLimit, preVerificationGas,
            maxFeePerGas, maxPriorityFeePerGas,
            hashPaymasterAndData
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {Enum} from "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
abstract contract Executor {
    // Could add a flag fromEntryPoint for AA txn
    event ExecutionFailure(
        address indexed to,
        uint256 indexed value,
        bytes indexed data,
        Enum.Operation operation,
        uint256 txGas
    );
    event ExecutionSuccess(
        address indexed to,
        uint256 indexed value,
        bytes indexed data,
        Enum.Operation operation,
        uint256 txGas
    );

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            assembly {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        } else {
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
        }
        if (success) emit ExecutionSuccess(to, value, data, operation, txGas);
        else emit ExecutionFailure(to, value, data, operation, txGas);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {SelfAuthorized} from "../common/SelfAuthorized.sol";
import {FallbackManagerErrors} from "../common/Errors.sol";

/**
 *   @title Fallback Manager - A contract that manages fallback calls made to the Smart Account
 *   @dev Fallback calls are handled by a `handler` contract that is stored at FALLBACK_HANDLER_STORAGE_SLOT
 *        fallback calls are not delegated to the `handler` so they can not directly change Smart Account storage
 */
abstract contract FallbackManager is SelfAuthorized, FallbackManagerErrors {
    // keccak-256 hash of "fallback_manager.handler.address" subtracted by 1
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d4;

    event ChangedFallbackHandler(
        address indexed previousHandler,
        address indexed handler
    );

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;

        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(
                gas(),
                handler,
                0,
                0,
                add(calldatasize(), 20),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    function getFallbackHandler() public view returns (address _handler) {
        assembly {
            _handler := sload(FALLBACK_HANDLER_STORAGE_SLOT)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) external virtual;

    function _setFallbackHandler(address handler) internal {
        if (handler == address(0)) revert HandlerCannotBeZero();
        address previousHandler;

        assembly {
            previousHandler := sload(FALLBACK_HANDLER_STORAGE_SLOT)
            //}
            //bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;

            //assembly {
            sstore(FALLBACK_HANDLER_STORAGE_SLOT, handler)
        }
        emit ChangedFallbackHandler(previousHandler, handler);
    }

    uint256[24] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {SelfAuthorized} from "../common/SelfAuthorized.sol";
import {Executor, Enum} from "./Executor.sol";
import {ModuleManagerErrors} from "../common/Errors.sol";

/**
 * @title Module Manager - A contract that manages modules that can execute transactions
 *        on behalf of the Smart Account via this contract.
 */
abstract contract ModuleManager is
    SelfAuthorized,
    Executor,
    ModuleManagerErrors
{
    address internal constant SENTINEL_MODULES = address(0x1);
    mapping(address => address) internal _modules;
    uint256[24] private __gap;

    // Events
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);
    event ModuleTransaction(
        address module,
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation
    );

    /**
     * @dev Adds a module to the allowlist.
     * @notice This SHOULD only be done via userOp or a selfcall.
     */
    function enableModule(address module) external virtual;

    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This SHOULD only be done via userOp or a selfcall.
     */
    function setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) external virtual returns (address);

    /**
     * @dev Returns array of modules. Useful for a widget
     * @param start Start of the page.
     * @param pageSize Maximum number of modules that should be returned.
     * @return array Array of modules.
     * @return next Start of the next page.
     */
    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount;
        address currentModule = _modules[start];
        while (
            currentModule != address(0x0) &&
            currentModule != SENTINEL_MODULES &&
            moduleCount < pageSize
        ) {
            array[moduleCount] = currentModule;
            currentModule = _modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array

        assembly {
            mstore(array, moduleCount)
        }
    }

    /**
     * @dev Allows a Module to execute a Smart Account transaction without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        if (
            msg.sender == SENTINEL_MODULES || _modules[msg.sender] == address(0)
        ) revert ModuleNotEnabled(msg.sender);
        // Execute transaction without further confirmations.
        // Can add guards here to allow delegatecalls for selected modules (msg.senders) only
        success = execute(
            to,
            value,
            data,
            operation,
            txGas == 0 ? gasleft() : txGas
        );
    }

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool) {
        return execTransactionFromModule(to, value, data, operation, 0);
    }

    /**
     * @dev Allows a Module to execute a wallet transaction without any further confirmations and returns data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);

        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /**
     * @dev Allows a Module to execute a batch of Smart Account transactions without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operations Operation type of module transaction.
     */
    function execBatchTransactionFromModule(
        address[] calldata to,
        uint256[] calldata value,
        bytes[] calldata data,
        Enum.Operation[] calldata operations
    ) public virtual returns (bool success) {
        if (
            to.length == 0 ||
            to.length != value.length ||
            value.length != data.length ||
            data.length != operations.length
        )
            revert WrongBatchProvided(
                to.length,
                value.length,
                data.length,
                operations.length
            );

        // Only whitelisted modules are allowed.
        if (
            msg.sender == SENTINEL_MODULES || _modules[msg.sender] == address(0)
        ) revert ModuleNotEnabled(msg.sender);

        for (uint256 i; i < to.length; ) {
            // Execute transaction without further confirmations.
            success = _executeFromModule(
                to[i],
                value[i],
                data[i],
                operations[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns if a module is enabled
     * @return True if the module is enabled
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && _modules[module] != address(0);
    }

    /**
     * @dev Adds a module to the allowlist.
     * @notice This can only be done via a userOp or a selfcall.
     * @notice Enables the module `module` for the wallet.
     * @param module Module to be allow-listed.
     */
    function _enableModule(address module) internal virtual {
        // Module address cannot be null or sentinel.
        if (module == address(0) || module == SENTINEL_MODULES)
            revert ModuleCannotBeZeroOrSentinel(module);
        // Module cannot be added twice.
        if (_modules[module] != address(0)) revert ModuleAlreadyEnabled(module);

        _modules[module] = _modules[SENTINEL_MODULES];
        _modules[SENTINEL_MODULES] = module;

        emit EnabledModule(module);
    }

    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This can only be done via userOp or a selfcall.
     */
    function _setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) internal virtual returns (address) {
        address module = _setupModule(setupContract, setupData);
        _enableModule(module);
        return module;
    }

    /**
     * @dev Removes a module from the allowlist.
     * @notice This can only be done via a wallet transaction.
     * @notice Disables the module `module` for the wallet.
     * @param prevModule Module that pointed to the module to be removed in the linked list
     * @param module Module to be removed.
     */
    function _disableModule(
        address prevModule,
        address module
    ) internal virtual {
        // Validate module address and check that it corresponds to module index.
        if (module == address(0) || module == SENTINEL_MODULES)
            revert ModuleCannotBeZeroOrSentinel(module);
        if (_modules[prevModule] != module)
            revert ModuleAndPrevModuleMismatch(
                module,
                _modules[prevModule],
                prevModule
            );
        _modules[prevModule] = _modules[module];
        delete _modules[module];
        emit DisabledModule(module);
    }

    // TODO: can use not executor.execute, but SmartAccount._call for the unification

    function _executeFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        success = execute(to, value, data, operation, gasleft());
        if (success) {
            emit ModuleTransaction(msg.sender, to, value, data, operation);
            emit ExecutionFromModuleSuccess(msg.sender);
        } else emit ExecutionFromModuleFailure(msg.sender);
    }

    /**
     * @notice Setup function sets the initial storage of the contract.
     * @param setupContract Contract, that setups initial auth module for this smart account. It can be a module factory or
     *                            a registry module that serves several smart accounts
     * @param setupData modules setup data (a standard calldata for the module setup contract)
     */
    function _initialSetupModules(
        address setupContract,
        bytes memory setupData
    ) internal virtual returns (address) {
        address initialAuthorizationModule = _setupModule(
            setupContract,
            setupData
        );

        // Module address cannot be null or sentinel.
        if (
            initialAuthorizationModule == address(0) ||
            initialAuthorizationModule == SENTINEL_MODULES
        ) revert ModuleCannotBeZeroOrSentinel(initialAuthorizationModule);

        _modules[initialAuthorizationModule] = SENTINEL_MODULES;
        _modules[SENTINEL_MODULES] = initialAuthorizationModule;
        return initialAuthorizationModule;
    }

    function _setupModule(
        address setupContract,
        bytes memory setupData
    ) internal returns (address module) {
        if (setupContract == address(0)) revert("Wrong Module Setup Address");
        assembly {
            let success := call(
                gas(),
                setupContract,
                0,
                add(setupData, 0x20),
                mload(setupData),
                0,
                0
            )
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
            module := mload(ptr)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UserOperationLib, UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {BaseSmartAccountErrors} from "./common/Errors.sol";
import "@account-abstraction/contracts/core/Helpers.sol";

/**
 * Basic account implementation.
 * This contract provides the basic logic for implementing the IAccount interface: validateUserOp function
 * Specific account implementation should inherit it and provide the account-specific logic
 */
abstract contract BaseSmartAccount is IAccount, BaseSmartAccountErrors {
    using UserOperationLib for UserOperation;

    //return value in case of signature failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    /**
     * @dev Initialize the Smart Account with required states
     * @param handler Default fallback handler provided in Smart Account
     * @param moduleSetupContract Contract, that setups initial auth module for this smart account. It can be a module factory or
     *                            a registry module that serves several smart accounts.
     * @param moduleSetupData data containing address of the Setup Contract and a setup data
     * @notice devs need to make sure it is only callable once (use initializer modifier or state check restrictions)
     */
    function init(
        address handler,
        address moduleSetupContract,
        bytes calldata moduleSetupData
    ) external virtual returns (address);

    /**
     * Validates the userOp.
     * @param userOp validate the userOp.signature field
     * @param userOpHash convenient field: the hash of the request, to check the signature against
     *          (also hashes the entrypoint and chain id)
     * @param missingAccountFunds the amount of funds required to pay to EntryPoint to pay for the userOp execution.
     * @return validationData signature and time-range of this operation
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If the account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override returns (uint256);

    /**
     * @return nonce the account nonce.
     * @dev This method returns the next sequential nonce.
     * @notice Provides 2D nonce functionality by allowing to use a nonce of a specific key.
     */
    function nonce(uint192 _key) public view virtual returns (uint256) {
        return entryPoint().getNonce(address(this), _key);
    }

    /**
     * return the entryPoint used by this account.
     * subclass should return the current entryPoint used by this account.
     */
    function entryPoint() public view virtual returns (IEntryPoint);

    /**
     * sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * subclass MAY override this method for better funds management
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again)
     * @param missingAccountFunds the minimum value this method should send the entrypoint.
     *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if (missingAccountFunds != 0) {
            payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/// @title Enum - Collection of enums
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

contract BaseSmartAccountErrors {
    /**
     * @notice Throws at onlyEntryPoint when msg.sender is not an EntryPoint set for this Smart Account
     * @param caller address that tried to call onlyEntryPoint-protected method
     */
    error CallerIsNotAnEntryPoint(address caller);
}

contract FallbackManagerErrors {
    /**
     * @notice Throws if zero address has been provided as Fallback Handler address
     */
    error HandlerCannotBeZero();
}

contract ModuleManagerErrors {
    /**
     * @notice Throws when trying to initialize module manager that already been initialized
     */
    error ModulesAlreadyInitialized();

    /**
     * @notice Throws when a delegatecall in course of module manager initialization has failed
     */
    error ModulesSetupExecutionFailed();

    /**
     * @notice Throws when address(0) or SENTINEL_MODULES constant has been provided as a module address
     * @param module Module address provided
     */
    error ModuleCannotBeZeroOrSentinel(address module);

    /**
     * @notice Throws when trying to enable module that has already been enabled
     * @param module Module address provided
     */
    error ModuleAlreadyEnabled(address module);

    /**
     * @notice Throws when module and previous module mismatch
     * @param expectedModule expected module at modules[prevModule]
     * @param returnedModule the module that has been found at modules[prevModule]
     * @param prevModule previous module address provided at call
     */
    error ModuleAndPrevModuleMismatch(
        address expectedModule,
        address returnedModule,
        address prevModule
    );

    /**
     * @notice Throws when trying to execute transaction from module that is not enabled
     * @param module Module address provided
     */
    error ModuleNotEnabled(address module);

    /**
     * @notice Throws when data for executeBatchCall provided in wrong format (i.e. empty array or lengths mismatch)
     * @param destLength length of destination contracts array
     * @param valueLength length of txn values array
     * @param funcLength length of function signatures array
     * @param operationLength length of operation types array. 0 if there's no operations
     */
    error WrongBatchProvided(
        uint256 destLength,
        uint256 valueLength,
        uint256 funcLength,
        uint256 operationLength
    );
}

contract SmartAccountErrors is BaseSmartAccountErrors, ModuleManagerErrors {
    /**
     * @notice Throws if zero address has been provided as Entry Point address
     */
    error EntryPointCannotBeZero();

    /**
     * @notice Throws at mixedAuth when msg.sender is not an owner neither _self
     * @param caller address that tried to call mixedAuth-protected method
     */
    error MixedAuthFail(address caller);

    /**
     * @notice Throws if trying to change an owner of a SmartAccount to the zero address
     */
    error OwnerCannotBeZero();

    /**
     * @notice Throws if zero address has been provided as Base Implementation address
     */
    error BaseImplementationCannotBeZero();

    /**
     * @notice Throws if there is no code at implementationAddress
     * @param implementationAddress implementation address provided
     */
    error InvalidImplementation(address implementationAddress);

    /**
     * @notice Throws at onlyOwner when msg.sender is not an owner
     * @param caller address that tried to call onlyOwner method
     */
    error CallerIsNotOwner(address caller);

    /**
     * @notice Throws at _requireFromEntryPointOrOwner when msg.sender is not an EntryPoint neither an owner
     * @param caller address that tried to call _requireFromEntryPointOrOwner-protected method
     */
    error CallerIsNotEntryPointOrOwner(address caller);

    /**
     * @notice Throws at _requireFromEntryPointOrSelf when msg.sender is not an EntryPoint neither self
     * @param caller address that tried to call _requireFromEntryPointOrSelf-protected method
     */
    error CallerIsNotEntryPointOrSelf(address caller);

    /**
     * @notice Throws at _requireFromEntryPoint when msg.sender is not an EntryPoint
     * @param caller address that tried to call _requireFromEntryPoint-protected method
     */
    error CallerIsNotEntryPoint(address caller);

    /**
     * @notice Throws if trying to initialize a Smart Account that has already been initialized
     */
    error AlreadyInitialized();

    /**
     * @notice Throws if contract signature is provided in frong format
     * @param uintS s converted to uint256
     * @param contractSignatureLength length of a contract signature
     * @param signatureLength the whole signature length
     */
    error WrongContractSignatureFormat(
        uint256 uintS,
        uint256 contractSignatureLength,
        uint256 signatureLength
    );

    /**
     * @notice Throws if isValidSignature for the conrtact signature and data hash differs from EIP1271 Magic Value
     * @param contractSignature the contract signature that has been verified
     */
    error WrongContractSignature(bytes contractSignature);

    /**
     * @notice Throws when if trying to transfer to zero address
     */
    error TransferToZeroAddressAttempt();

    /**
     * @notice Throws when module address taken from signature is not enabled
     * @param moduleAddressProvided module address taken from signature
     */
    error WrongValidationModule(address moduleAddressProvided);

    /**
     * @notice Thrown when the function that must be called only via delegatecall is called directly
     */
    error DelegateCallsOnly();

    /**
     * @notice Thrown when trying to use address of the Smart Account as an owner for itself
     */
    error OwnerCanNotBeSelf();

    /**
     * @notice Thrown when trying to use current owner as a new owner in a _setOwner() call
     */
    error OwnerProvidedIsSame();
}

contract SmartAccountFactoryErrors is SmartAccountErrors {
    /**
     * @notice Throws when the new Proxy deployment fails
     * @param owner Owner of a Proxy (Smart Account)
     * @param index Deployment index
     */
    error ProxyDeploymentFailed(address owner, uint256 index);
}

contract SelfAuthorizedErrors {
    /**
     * @notice Throws when the caller is not address(this)
     * @param caller Caller address
     */
    error CallerIsNotSelf(address caller);
}

contract SingletonPaymasterErrors {
    /**
     * @notice Throws when the Entrypoint address provided is address(0)
     */
    error EntryPointCannotBeZero();

    /**
     * @notice Throws when the verifiying signer address provided is address(0)
     */
    error VerifyingSignerCannotBeZero();

    /**
     * @notice Throws when the paymaster address provided is address(0)
     */
    error PaymasterIdCannotBeZero();

    /**
     * @notice Throws when the 0 has been provided as deposit
     */
    error DepositCanNotBeZero();

    /**
     * @notice Throws when trying to withdraw to address(0)
     */
    error CanNotWithdrawToZeroAddress();

    /**
     * @notice Throws when trying to withdraw more than balance available
     * @param amountRequired required balance
     * @param currentBalance available balance
     */
    error InsufficientBalance(uint256 amountRequired, uint256 currentBalance);

    /**
     * @notice Throws when signature provided has invalid length
     * @param sigLength length oif the signature provided
     */
    error InvalidPaymasterSignatureLength(uint256 sigLength);
}

//

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import {SelfAuthorizedErrors} from "../common/Errors.sol";

/// @title SelfAuthorized - authorizes current contract to perform actions
contract SelfAuthorized is SelfAuthorizedErrors {
    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        _requireSelfCall();
        _;
    }

    function _requireSelfCall() private view {
        if (msg.sender != address(this)) revert CallerIsNotSelf(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

// interface for modules to verify singatures signed over userOpHash
interface IAuthorizationModule {
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x1626ba7e;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _dataHash Arbitrary length data signed on behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(
        bytes32 _dataHash,
        bytes memory _signature
    ) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibAddress {
    /**
     * @notice Will return true if provided address is a contract
     * @param account Address to verify if contract or not
     * @dev This contract will return false if called within the constructor of
     *      a contract's deployment, as the code is not yet stored on-chain.
     */
    function isContract(address account) internal view returns (bool) {
        uint256 csize;

        assembly {
            csize := extcodesize(account)
        }
        return csize != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BaseSmartAccount, IEntryPoint, UserOperation} from "./BaseSmartAccount.sol";
import {ModuleManager} from "./base/ModuleManager.sol";
import {FallbackManager} from "./base/FallbackManager.sol";
import {LibAddress} from "./libs/LibAddress.sol";
import {ISignatureValidator} from "./interfaces/ISignatureValidator.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {SmartAccountErrors} from "./common/Errors.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IAuthorizationModule} from "./interfaces/IAuthorizationModule.sol";

/**
 * @title SmartAccount - EIP-4337 compatible smart contract wallet.
 * @dev This contract is the base for the Smart Account functionality.
 *         - It is modular by nature. UserOp and txns validation happens in Authorization Modules.
 *         - It provides the functionality to execute AA (EIP-4337) userOps. Gnosis style txns removed to a module.
 *         - It allows to receive and manage assets.
 *         - It is responsible for managing the modules and fallbacks.
 *         - The Smart Account can be extended with modules, such as Social Recovery, Session Key and others.
 * @author Chirag Titiya - <[email protected]>, Filipp Makarov - <[email protected]>
 */
contract SmartAccount is
    BaseSmartAccount,
    ModuleManager,
    FallbackManager,
    IERC165,
    SmartAccountErrors,
    ISignatureValidator
{
    using ECDSA for bytes32;
    using LibAddress for address;

    // Storage Version
    string public constant VERSION = "2.0.0";

    // Owner storage. Deprecated. Left for storage layout compatibility
    address public ownerDeprecated;

    // changed to 2D nonce below
    // @notice there is no _nonce
    // Deprecated. Left for storage layout compatibility
    mapping(uint256 => uint256) public noncesDeprecated;

    // AA immutable storage
    IEntryPoint private immutable _entryPoint;
    address private immutable _self;

    // Events
    event ImplementationUpdated(
        address indexed oldImplementation,
        address indexed newImplementation
    );
    event SmartAccountReceivedNativeToken(
        address indexed sender,
        uint256 indexed value
    );

    /**
     * @dev Constructor that sets the entry point contract.
     *      _modules[SENTINEL_MODULES] = SENTINEL_MODULES protects implementation from initialization
     * @param anEntryPoint The address of the entry point contract.
     */
    constructor(IEntryPoint anEntryPoint) {
        _self = address(this);
        if (address(anEntryPoint) == address(0))
            revert EntryPointCannotBeZero();
        _entryPoint = anEntryPoint;
        _modules[SENTINEL_MODULES] = SENTINEL_MODULES;
    }

    /**
     * @dev This function is a special fallback function that is triggered when the contract receives Ether.
     * It logs an event indicating the amount of Ether received and the sender's address.
     * @notice This function is marked as external and payable, meaning it can be called from external
     * sources and accepts Ether as payment.
     */
    receive() external payable {
        if (address(this) == _self) revert DelegateCallsOnly();
        emit SmartAccountReceivedNativeToken(msg.sender, msg.value);
    }

    /**
     * @dev Initialize the Smart Account with required states
     * @param handler Default fallback handler provided in Smart Account
     * @param moduleSetupContract Contract, that setups initial auth module for this smart account.
     * It can be a module factory or a registry module that serves several smart accounts
     * @param moduleSetupData modules setup data (a standard calldata for the module setup contract)
     * @notice devs need to make sure it is only callable once by initializer or state check restrictions
     * @notice any further implementations that introduces a new state must have a reinit method
     * @notice reinitialization is not possible, as _initialSetupModules reverts if the account is already initialized
     *         which is when there is at least one enabled module
     */
    function init(
        address handler,
        address moduleSetupContract,
        bytes calldata moduleSetupData
    ) external virtual override returns (address) {
        if (
            _modules[SENTINEL_MODULES] != address(0) ||
            getFallbackHandler() != address(0)
        ) revert AlreadyInitialized();
        _setFallbackHandler(handler);
        return _initialSetupModules(moduleSetupContract, moduleSetupData);
    }

    /**
     * @dev Interface function with the standard name for execute_ncC
     * @param dest Address of the contract to call
     * @param value Amount of native tokens to send along with the transaction
     * @param func Data of the transaction
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        execute_ncC(dest, value, func);
    }

    /**
     * @dev Interface function with the standard name for executeBatch_y6U
     * @param dest Addresses of the contracts to call
     * @param value Amounts of native tokens to send along with the transactions
     * @param func Data of the transactions
     */
    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external {
        executeBatch_y6U(dest, value, func);
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override returns (uint256 validationData) {
        if (msg.sender != address(entryPoint()))
            revert CallerIsNotAnEntryPoint(msg.sender);

        (, address validationModule) = abi.decode(
            userOp.signature,
            (bytes, address)
        );
        if (address(_modules[validationModule]) != address(0)) {
            validationData = IAuthorizationModule(validationModule)
                .validateUserOp(userOp, userOpHash);
        } else {
            revert WrongValidationModule(validationModule);
        }
        // Check nonce requirement if any
        _payPrefund(missingAccountFunds);
    }

    /**
     * @dev Adds a module to the allowlist.
     * @notice This can only be done via a userOp or a selfcall.
     * @notice Enables the module `module` for the wallet.
     * @param module Module to be allow-listed.
     */
    function enableModule(address module) external virtual override {
        _requireFromEntryPointOrSelf();
        _enableModule(module);
    }

    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This can only be done via userOp or a selfcall.
     * @notice Enables the module `module` for the wallet.
     */
    function setupAndEnableModule(
        address setupContract,
        bytes memory setupData
    ) external virtual override returns (address) {
        _requireFromEntryPointOrSelf();
        return _setupAndEnableModule(setupContract, setupData);
    }

    /**
     * @dev Sets the fallback handler.
     * @notice This can only be done via a UserOp sent by EntryPoint.
     * @param handler Handler to be set.
     */
    function setFallbackHandler(address handler) external virtual override {
        _requireFromEntryPointOrSelf();
        _setFallbackHandler(handler);
    }

    /**
     * @dev Returns the address of the implementation contract associated with this contract.
     * @notice The implementation address is stored in the contract's storage slot with index 0.
     */
    function getImplementation()
        external
        view
        returns (address _implementation)
    {
        assembly {
            _implementation := sload(address())
        }
    }

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC165
     * @return `true` if the contract implements `_interfaceID`
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view virtual override returns (bool) {
        return _interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /**
     * @notice All the new implementations MUST have this method!
     * @notice Updates the implementation of the base wallet
     * @param _implementation New wallet implementation
     */
    function updateImplementation(address _implementation) public virtual {
        _requireFromEntryPointOrSelf();
        require(_implementation != address(0), "Address cannot be zero");
        if (!_implementation.isContract())
            revert InvalidImplementation(_implementation);
        address oldImplementation;

        assembly {
            oldImplementation := sload(address())
            sstore(address(), _implementation)
        }
        emit ImplementationUpdated(oldImplementation, _implementation);
    }

    /**
     * @dev Execute a transaction (called by entryPoint)
     * @notice Name is optimized for this method to be cheaper to be called
     * @param dest Address of the contract to call
     * @param value Amount of native tokens to send along with the transaction
     * @param func Data of the transaction
     */
    function execute_ncC(
        address dest,
        uint256 value,
        bytes calldata func
    ) public {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * @dev Execute a sequence of transactions
     * @notice Name is optimized for this method to be cheaper to be called
     * @param dest Addresses of the contracts to call
     * @param value Amounts of native tokens to send along with the transactions
     * @param func Data of the transactions
     */
    function executeBatch_y6U(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) public {
        _requireFromEntryPoint();
        if (
            dest.length == 0 ||
            dest.length != value.length ||
            value.length != func.length
        ) revert WrongBatchProvided(dest.length, value.length, func.length, 0);
        for (uint256 i; i < dest.length; ) {
            _call(dest[i], value[i], func[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * @dev Withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public payable {
        _requireFromEntryPointOrSelf();
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /**
     * @dev Removes a module from the allowlist.
     * @notice This can only be done via a wallet transaction.
     * @notice Disables the module `module` for the wallet.
     * @param prevModule Module that pointed to the module to be removed in the linked list
     * @param module Module to be removed.
     */
    function disableModule(address prevModule, address module) public virtual {
        _requireFromEntryPointOrSelf();
        _disableModule(prevModule, module);
    }

    /**
     * @dev Returns the current entry point used by this account.
     * @return EntryPoint as an `IEntryPoint` interface.
     * @dev This function should be implemented by the subclass to return the current entry point used by this account.
     */
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * @dev Check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * Implementation of ISignatureValidator (see `interfaces/ISignatureValidator.sol`)
     * @dev Forwards the validation to the module specified in the signature
     * @param dataHash 32 bytes hash of the data signed on the behalf of address(msg.sender)
     * @param signature Signature byte array associated with dataHash
     * @return bytes4 value.
     */
    function isValidSignature(
        bytes32 dataHash,
        bytes memory signature
    ) public view override returns (bytes4) {
        (bytes memory moduleSignature, address validationModule) = abi.decode(
            signature,
            (bytes, address)
        );
        if (address(_modules[validationModule]) != address(0)) {
            return
                ISignatureValidator(validationModule).isValidSignature(
                    dataHash,
                    moduleSignature
                );
        } else {
            revert WrongValidationModule(validationModule);
        }
    }

    /**
     * @dev internal method that fecilitates the extenral calls from SmartAccount
     * @dev similar to execute() of Executor.sol
     * @param target destination address contract/non-contract
     * @param value amount of native tokens
     * @param data function singature of destination
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        assembly {
            let success := call(
                gas(),
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, returndatasize())
            if iszero(success) {
                revert(ptr, returndatasize())
            }
        }
    }

    /**
     * @dev This function allows entry point or SA itself to execute certain actions.
     * If the caller is not authorized, the function will revert with an error message.
     * @notice This function acts as modifier and is marked as internal to be be called
     * within the contract itself only.
     */
    function _requireFromEntryPointOrSelf() internal view {
        if (msg.sender != address(entryPoint()) && msg.sender != address(this))
            revert CallerIsNotEntryPointOrSelf(msg.sender);
    }

    /**
     * @dev This function allows entry point to execute certain actions.
     * If the caller is not authorized, the function will revert with an error message.
     * @notice This function acts as modifier and is marked as internal to be be called
     * within the contract itself only.
     */
    function _requireFromEntryPoint() internal view {
        if (msg.sender != address(entryPoint()))
            revert CallerIsNotEntryPoint(msg.sender);
    }
}