// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-empty-blocks */

import "../interfaces/IAccount.sol";
import "../interfaces/IEntryPoint.sol";
import "./Helpers.sol";

/**
 * Basic account implementation.
 * this contract provides the basic logic for implementing the IAccount interface  - validateUserOp
 * specific account implementation should inherit it and provide the account-specific logic
 */
abstract contract BaseAccount is IAccount {
    using UserOperationLib for UserOperation;

    //return value in case of signature failure, with no time-range.
    // equivalent to _packValidationData(true,0,0);
    uint256 constant internal SIG_VALIDATION_FAILED = 1;

    /**
     * Return the account nonce.
     * This method returns the next sequential nonce.
     * For a nonce of a specific key, use `entrypoint.getNonce(account, key)`
     */
    function getNonce() public view virtual returns (uint256) {
        return entryPoint().getNonce(address(this), 0);
    }

    /**
     * return the entryPoint used by this account.
     * subclass should return the current entryPoint used by this account.
     */
    function entryPoint() public view virtual returns (IEntryPoint);

    /**
     * Validate user's signature and nonce.
     * subclass doesn't need to override this method. Instead, it should override the specific internal validation methods.
     */
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external override virtual returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        _validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal virtual view {
        require(msg.sender == address(entryPoint()), "account: not from EntryPoint");
    }

    /**
     * validate the signature is valid for this message.
     * @param userOp validate the userOp.signature field
     * @param userOpHash convenient field: the hash of the request, to check the signature against
     *          (also hashes the entrypoint and chain id)
     * @return validationData signature and time-range of this operation
     *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *         otherwise, an address of an "authorizer" contract.
     *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *      <6-byte> validAfter - first timestamp this operation is valid
     *      If the account doesn't use time-range, it is enough to return SIG_VALIDATION_FAILED value (1) for signature failure.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal virtual returns (uint256 validationData);

    /**
     * Validate the nonce of the UserOperation.
     * This method may validate the nonce requirement of this account.
     * e.g.
     * To limit the nonce to use sequenced UserOps only (no "out of order" UserOps):
     *      `require(nonce < type(uint64).max)`
     * For a hypothetical account that *requires* the nonce to be out-of-order:
     *      `require(nonce & type(uint64).max == 0)`
     *
     * The actual nonce uniqueness is managed by the EntryPoint, and thus no other
     * action is needed by the account itself.
     *
     * @param nonce to validate
     *
     * solhint-disable-next-line no-empty-blocks
     */
    function _validateNonce(uint256 nonce) internal view virtual {
    }

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
            (bool success,) = payable(msg.sender).call{value : missingAccountFunds, gas : type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/// @title ECDSA is a library that contains useful methods for working with ECDSA signatures
library BytesExtractSignature {
    /// @notice Extracts the r, s, and v components from the `sigData` field starting from the `offset`
    /// @dev Note: does not do any bounds checking on the arguments!
    /// @param sigData the signature data; could be 1 or more packed signatures.
    /// @param offset the offset in sigData from which to start unpacking the signature components.
    function extractSignature(bytes memory sigData, uint256 offset)
        internal
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let dataPointer := add(sigData, offset)
            r := mload(add(dataPointer, 0x20))
            s := mload(add(dataPointer, 0x40))
            v := byte(0, mload(add(dataPointer, 0x60)))
        }

        return (r, s, v);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable no-empty-blocks */

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * Token callback handler.
 *   Handles supported tokens' callbacks, allowing account receiving these tokens.
 */
contract TokenCallbackHandler is IERC777Recipient, IERC721Receiver, IERC1155Receiver {
    function tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata)
        external
        pure
        override
    {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@account-abstraction/contracts/core/BaseAccount.sol";

import "../utils/TokenCallbackHandler.sol";
import "./CoreWallet.sol";

/**
 * Blocto account.
 *  compatibility for EIP-4337 and smart contract wallet with cosigner functionality (CoreWallet)
 */
contract BloctoAccount is UUPSUpgradeable, TokenCallbackHandler, CoreWallet, BaseAccount {
    /**
     *  This is the version of this contract.
     */
    string public constant VERSION = "1.5.2";

    /// @notice entrypoint from 4337 official
    IEntryPoint private immutable _entryPoint;

    /// @notice initialized _IMPLEMENTATION_SLOT
    bool public initializedImplementation = false;

    /**
     * constructor for BloctoAccount
     * @param anEntryPoint entrypoint address
     */
    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
    }

    /**
     * override from UUPSUpgradeable
     * @notice onlyInvoked modifier for only this account owner can enter this function, and (newImplementation) for compiler and it extends from UUPSUpgradeable, so it shoule be here
     * @param newImplementation implementation address
     */
    function _authorizeUpgrade(address newImplementation) internal view override onlyInvoked {
        (newImplementation);
    }

    /**
     * return entrypoint
     */
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /**
     * execute a transaction (called directly by entryPoint)
     * @param dest dest call address
     * @param value value to send
     * @param func the func containing the transaction to be called
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions (called directly by entryPoint)
     * @param dest sequence of dest call address
     * @param value sequence of value to send
     * @param func sequence of the func containing transactions to be called
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        _requireFromEntryPoint();
        require(dest.length == value.length, "wrong array lengths");
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], value[i], func[i]);
        }
    }

    /**
     * internal call for execute and executeBatch
     * @param target target call address
     * @param value value to send
     * @param data the data containing the transaction to be called
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * implement validate signature method of BaseAccount from entrypoint
     * @param userOp user operation including signature for validating
     * @param userOpHash user operation hash
     */
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes4 result = this.isValidSignature(userOpHash, userOp.signature);
        if (result != IERC1271.isValidSignature.selector) {
            return SIG_VALIDATION_FAILED;
        }

        return 0;
    }

    /**
     * check current account deposit in the entryPoint StakeManager
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint StakeManager
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw deposit to withdrawAddress from entryPoint StakeManager
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) external onlyInvoked {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /// @notice only once for initialized initializedImplementation
    modifier onlyOnceInitImplementation() {
        require(!initializedImplementation, "must not already be initialized");
        initializedImplementation = true;
        _;
    }

    /// @notice initialize BloctoAccountProxy for adding the implementation address
    /// @param implementation implementation address
    function initImplementation(address implementation) public onlyOnceInitImplementation {
        require(Address.isContract(implementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./BloctoAccount.sol";

/// @title BloctoAccountCloneableWallet Wallet
/// @notice This contract represents a complete but non working wallet.
contract BloctoAccountCloneableWallet is BloctoAccount {
    /// @notice  constructor that deploys a NON-FUNCTIONAL version of `BloctoAccount`
    /// @param anEntryPoint entrypoint address
    constructor(IEntryPoint anEntryPoint) BloctoAccount(anEntryPoint) {
        initialized = true;
        initializedImplementation = true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/BytesExtractSignature.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Core Wallet
/// @notice A basic smart contract wallet with cosigner functionality. The notion of "cosigner" is
///  the simplest possible multisig solution, a two-of-two signature scheme. It devolves nicely
///  to "one-of-one" (i.e. singlesig) by simply having the cosigner set to the same value as
///  the main signer.
///
///  Most "advanced" functionality (deadman's switch, multiday recovery flows, blacklisting, etc)
///  can be implemented externally to this smart contract, either as an additional smart contract
///  (which can be tracked as a signer without cosigner, or as a cosigner) or as an off-chain flow
///  using a public/private key pair as cosigner. Of course, the basic cosigning functionality could
///  also be implemented in this way, but (A) the complexity and gas cost of two-of-two multisig (as
///  implemented here) is negligable even if you don't need the cosigner functionality, and
///  (B) two-of-two multisig (as implemented here) handles a lot of really common use cases, most
///  notably third-party gas payment and off-chain blacklisting and fraud detection.
contract CoreWallet is IERC1271 {
    using BytesExtractSignature for bytes;
    using ECDSA for bytes;

    /// @notice We require that presigned transactions use the EIP-191 signing format.
    ///  See that EIP for more info: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-191.md
    bytes1 public constant EIP191_VERSION_DATA = bytes1(0);
    bytes1 public constant EIP191_PREFIX = bytes1(0x19);

    /// @notice This is a sentinel value used to determine when a delegate is set to expose
    ///  support for an interface containing more than a single function. See `delegates` and
    ///  `setDelegate` for more information.
    address public constant COMPOSITE_PLACEHOLDER = address(1);

    /// @notice A pre-shifted "1", used to increment the authVersion, so we can "prepend"
    ///  the authVersion to an address (for lookups in the authorizations mapping)
    ///  by using the '+' operator (which is cheaper than a shift and a mask). See the
    ///  comment on the `authorizations` variable for how this is used.
    uint256 public constant AUTH_VERSION_INCREMENTOR = (1 << 160);

    /// @notice Q constant for schnorr signature verify
    uint256 internal constant Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    /// @notice s of signature must be less than S_MAX refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/f29307cfe08c7d76d96a38bf94bab5fec223c943/contracts/utils/cryptography/ECDSA.sol#L156
    bytes32 internal constant S_MAX = bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0);

    /// @notice The pre-shifted authVersion (to get the current authVersion as an integer,
    ///  shift this value right by 160 bits). Starts as `1 << 160` (`AUTH_VERSION_INCREMENTOR`)
    ///  See the comment on the `authorizations` variable for how this is used.
    uint256 public authVersion;

    /// @notice A mapping containing all of the addresses that are currently authorized to manage
    ///  the assets owned by this wallet.
    ///
    ///  The keys in this mapping are authorized addresses with a version number prepended,
    ///  like so: (authVersion,96)(address,160). The current authVersion MUST BE included
    ///  for each look-up; this allows us to effectively clear the entire mapping of its
    ///  contents merely by incrementing the authVersion variable. (This is important for
    ///  the emergencyRecovery() method.) Inspired by https://ethereum.stackexchange.com/a/42540
    ///
    ///  The values in this mapping are 256bit words, whose lower 20 bytes constitute "cosigners"
    ///  for each address. If an address maps to itself, then that address is said to have no cosigner.
    ///
    ///  Addresses that map to a non-zero cosigner in the current authVersion are called
    ///  "authorized addresses".
    mapping(uint256 => uint256) public authorizations;

    // (authVersion,96)(padding_0,152)(isSchnorr,1) (authKeyIdx,6)(parity,1) -> merged_ec_pubkey_x (256)
    // isSchnorr: 1 -> schnorr, 0 -> not schnorr
    mapping(uint256 => bytes32) public mergedKeys;

    /// @notice A per-key nonce value, incremented each time a transaction is processed with that key.
    ///  Used for replay prevention. The nonce value in the transaction must exactly equal the current
    ///  nonce value in the wallet for that key. (This mirrors the way Ethereum's transaction nonce works.)
    uint256 public nonce;

    /// @notice A mapping tracking dynamically supported interfaces and their corresponding
    ///  implementation contracts. Keys are interface IDs and values are addresses of
    ///  contracts that are responsible for implementing the function corresponding to the
    ///  interface.
    ///
    ///  Delegates are added (or removed) via the `setDelegate` method after the contract is
    ///  deployed, allowing support for new interfaces to be dynamically added after deployment.
    ///  When a delegate is added, its interface ID is considered "supported" under EIP165.
    ///
    ///  For cases where an interface composed of more than a single function must be
    ///  supported, it is necessary to manually add the composite interface ID with
    ///  `setDelegate(interfaceId, COMPOSITE_PLACEHOLDER)`. Interface IDs added with the
    ///  COMPOSITE_PLACEHOLDER address are ignored when called and are only used to specify
    ///  supported interfaces.
    mapping(bytes4 => address) public delegates;

    /// @notice A special address that is authorized to call `emergencyRecovery()`. That function
    ///  resets ALL authorization for this wallet, and must therefore be treated with utmost security.
    ///  Reasonable choices for recoveryAddress include:
    ///       - the address of a private key in cold storage
    ///       - a physically secured hardware wallet
    ///       - a multisig smart contract, possibly with a time-delayed challenge period
    ///       - the zero address, if you like performing without a safety net ;-)
    address public recoveryAddress;

    /// @notice Used to track whether or not this contract instance has been initialized. This
    ///  is necessary since it is common for this wallet smart contract to be used as the "library
    ///  code" for an clone contract. See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    ///  for more information about clone contracts.
    bool public initialized;

    error ExecutionResult(bool targetSuccess);

    /// @notice Used to decorate methods that can only be called directly by the recovery address.
    modifier onlyRecoveryAddress() {
        require(msg.sender == recoveryAddress, "sender must be recovery address");
        _;
    }

    /// @notice Used to decorate the `init` function so this can only be called one time. Necessary
    ///  since this contract will often be used as a "clone". (See above.)
    modifier onlyOnce() {
        require(!initialized, "must not already be initialized");
        initialized = true;
        _;
    }

    /// @notice Used to decorate methods that can only be called indirectly via an `invoke()` method.
    ///  In practice, it means that those methods can only be called by a signer/cosigner
    ///  pair that is currently authorized. Theoretically, we could factor out the
    ///  signer/cosigner verification code and use it explicitly in this modifier, but that
    ///  would either result in duplicated code, or additional overhead in the invoke()
    ///  calls (due to the stack manipulation for calling into the shared verification function).
    ///  Doing it this way makes calling the administration functions more expensive (since they
    ///  go through a explicit call() instead of just branching within the contract), but it
    ///  makes invoke() more efficient. We assume that invoke() will be used much, much more often
    ///  than any of the administration functions.
    modifier onlyInvoked() {
        require(msg.sender == address(this), "must be called from `invoke()`");
        _;
    }

    /// @notice Emitted when an authorized address is added, removed, or modified. When an
    ///  authorized address is removed ("deauthorized"), cosigner will be address(0) in
    ///  this event.
    ///
    ///  NOTE: When emergencyRecovery() is called, all existing addresses are deauthorized
    ///  WITHOUT Authorized(addr, 0) being emitted. If you are keeping an off-chain mirror of
    ///  authorized addresses, you must also watch for EmergencyRecovery events.
    /// @dev hash is 0xf5a7f4fb8a92356e8c8c4ae7ac3589908381450500a7e2fd08c95600021ee889
    /// @param authorizedAddress the address to authorize or unauthorize
    /// @param cosigner the 2-of-2 signatory (optional).
    event Authorized(address authorizedAddress, uint256 cosigner);

    event AuthorizedMergedKey(uint8 mergedKeyIndexWithParity, bytes32 mergedKey);

    /// @notice Emitted when an emergency recovery has been performed. If this event is fired,
    ///  ALL previously authorized addresses have been deauthorized and the only authorized
    ///  address is the authorizedAddress indicated in this event.
    /// @dev hash is 0xe12d0bbeb1d06d7a728031056557140afac35616f594ef4be227b5b172a604b5
    /// @param authorizedAddress the new authorized address
    /// @param cosigner the cosigning address for `authorizedAddress`
    event EmergencyRecovery(address authorizedAddress, uint256 cosigner);

    /// @notice Emitted when the recovery address changes. Either (but not both) of the
    ///  parameters may be zero.
    /// @dev hash is 0x568ab3dedd6121f0385e007e641e74e1f49d0fa69cab2957b0b07c4c7de5abb6
    /// @param previousRecoveryAddress the previous recovery address
    /// @param newRecoveryAddress the new recovery address
    event RecoveryAddressChanged(address previousRecoveryAddress, address newRecoveryAddress);

    /// @dev Emitted when this contract receives a non-zero amount ether via the fallback function
    ///  (i.e. This event is not fired if the contract receives ether as part of a method invocation)
    /// @param from the address which sent you ether
    /// @param value the amount of ether sent
    event Received(address from, uint256 value);

    /// @notice Emitted whenever a transaction is processed successfully from this wallet. Includes
    ///  both simple send ether transactions, as well as other smart contract invocations.
    /// @dev hash is 0x101214446435ebbb29893f3348e3aae5ea070b63037a3df346d09d3396a34aee
    /// @param hash The hash of the entire operation set. 0 is returned when emitted from `invoke0()`.
    /// @param result A bitfield of the results of the operations. A bit of 0 means success, and 1 means failure.
    /// @param numOperations A count of the number of operations processed
    event InvocationSuccess(bytes32 hash, uint256 result, uint256 numOperations);

    /// @notice Emitted when a delegate is added or removed.
    /// @param interfaceId The interface ID as specified by EIP165
    /// @param delegate The address of the contract implementing the given function. If this is
    ///  COMPOSITE_PLACEHOLDER, we are indicating support for a composite interface.
    event DelegateUpdated(bytes4 interfaceId, address delegate);

    /// @notice The shared initialization code used to setup the contract state regardless of whether or
    ///  not the clone pattern is being used.
    /// @param _authorizedAddress the initial authorized address, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _mergedKeyIndexWithParity the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKey the corresponding mergedKey (using Schnorr merged key)
    function init(
        address _authorizedAddress,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) public onlyOnce {
        require(_authorizedAddress != address(0), "authorized addresses must not be zero");
        require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");
        require(address(uint160(_cosigner)) != address(0), "cosigner address must not be zero");

        recoveryAddress = _recoveryAddress;
        // set initial authorization value
        authVersion = AUTH_VERSION_INCREMENTOR;
        // add initial authorized address
        authorizations[AUTH_VERSION_INCREMENTOR + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[AUTH_VERSION_INCREMENTOR + _mergedKeyIndexWithParity] = _mergedKey;
        emit Authorized(_authorizedAddress, _cosigner);
    }

    /// @notice The shared initialization code used to setup the contract state regardless of whether or
    ///  not the clone pattern is being used.
    /// @param _authorizedAddresses the initial authorized addresses, must not be zero!
    /// @param _cosigner the initial cosigning address for `_authorizedAddress`, can be equal to `_authorizedAddress`
    /// @param _recoveryAddress the initial recovery address for the wallet, can be address(0)
    /// @param _mergedKeyIndexWithParitys the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKeys the corresponding mergedKey
    function init2(
        address[] calldata _authorizedAddresses,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8[] calldata _mergedKeyIndexWithParitys,
        bytes32[] calldata _mergedKeys
    ) public onlyOnce {
        require(_authorizedAddresses.length != 0, "invalid authorizedAddresses array");
        require(_authorizedAddresses.length == _mergedKeyIndexWithParitys.length, "array length not match");
        require(_authorizedAddresses.length == _mergedKeys.length, "array length not match");
        require(address(uint160(_cosigner)) != address(0), "cosigner address must not be zero");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");
        recoveryAddress = _recoveryAddress;
        // set initial authorization value
        authVersion = AUTH_VERSION_INCREMENTOR;
        for (uint256 i = 0; i < _authorizedAddresses.length; i++) {
            address _authorizedAddress = _authorizedAddresses[i];
            require(_authorizedAddress != address(0), "authorized addresses must not be zero");
            require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
            authorizations[AUTH_VERSION_INCREMENTOR + uint256(uint160(_authorizedAddress))] = _cosigner;
            mergedKeys[AUTH_VERSION_INCREMENTOR + _mergedKeyIndexWithParitys[i]] = _mergedKeys[i];

            emit Authorized(_authorizedAddress, _cosigner);
        }
    }

    /// @notice The fallback function, invoked whenever we receive a transaction that doesn't call any of our
    ///  named functions. In particular, this method is called when we are the target of a simple send
    ///  transaction, when someone calls a method we have dynamically added a delegate for, or when someone
    ///  tries to call a function we don't implement, either statically or dynamically.
    ///
    ///  A correct invocation of this method occurs in following case:
    ///  - someone calls a delegated function (`msg.data.length` is greater than 0 and
    ///    `delegates[msg.sig]` is set)
    ///  In all other cases, this function will revert.
    ///
    ///  NOTE: Some smart contracts send 0 eth as part of a more complex operation
    ///  (-cough- CryptoKitties -cough-); ideally, we'd `require(msg.value > 0)` here when
    ///  `msg.data.length == 0`, but to work with those kinds of smart contracts, we accept zero sends
    ///  and just skip logging in that case.
    fallback() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }

        address delegate = delegates[msg.sig];
        require(delegate > COMPOSITE_PLACEHOLDER, "invalid transaction");

        // We have found a delegate contract that is responsible for the method signature of
        // this call. Now, pass along the calldata of this CALL to the delegate contract.
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := staticcall(gas(), delegate, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            // If the delegate reverts, we revert. If the delegate does not revert, we return the data
            // returned by the delegate to the original caller.
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        if (msg.value > 0) {
            emit Received(msg.sender, msg.value);
        }
    }

    /// @notice Adds or removes dynamic support for an interface. Can be used in 3 ways:
    ///   - Add a contract "delegate" that implements a single function
    ///   - Remove delegate for a function
    ///   - Specify that an interface ID is "supported", without adding a delegate. This is
    ///     used for composite interfaces when the interface ID is not a single method ID.
    /// @dev Must be called through `invoke`
    /// @param _interfaceId The ID of the interface we are adding support for
    /// @param _delegate Either:
    ///    - the address of a contract that implements the function specified by `_interfaceId`
    ///      for adding an implementation for a single function
    ///    - 0 for removing an existing delegate
    ///    - COMPOSITE_PLACEHOLDER for specifying support for a composite interface
    function setDelegate(bytes4 _interfaceId, address _delegate) external onlyInvoked {
        delegates[_interfaceId] = _delegate;
        emit DelegateUpdated(_interfaceId, _delegate);
    }

    /// @notice Configures an authorizable address. Can be used in four ways:
    ///   - Add a new signer/cosigner pair (cosigner must be non-zero)
    ///   - Set or change the cosigner for an existing signer (if authorizedAddress != cosigner)
    ///   - Remove the cosigning requirement for a signer (if authorizedAddress == cosigner)
    ///   - Remove a signer (if cosigner == address(0))
    /// @dev Must be called through `invoke()`
    /// @param _authorizedAddress the address to configure authorization
    /// @param _cosigner the corresponding cosigning address
    /// @param _mergedIndexWithParity the corresponding index of mergedKeys = authVersion + _mergedIndex
    /// @param _mergedKey the corresponding mergedKey
    function setAuthorized(
        address _authorizedAddress,
        uint256 _cosigner,
        uint8 _mergedIndexWithParity,
        bytes32 _mergedKey
    ) external onlyInvoked {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != recoveryAddress, "do not use the recovery address as an authorized address");
        require(
            (address(uint160(_cosigner)) == address(0) && _mergedKey == 0)
                || address(uint160(_cosigner)) != recoveryAddress,
            "do not use the recovery address as a cosigner"
        );

        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedIndexWithParity] = _mergedKey;

        emit Authorized(_authorizedAddress, _cosigner);
    }

    /// @notice Configures an authorizable address to use a merged key.
    /// @dev Must be called through `invoke()`
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function setMergedKey(uint8 _mergedKeyIndexWithParity, bytes32 _mergedKey) external onlyInvoked {
        require((_mergedKeyIndexWithParity & 0x80) > 0, "invalid merged key index");
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        emit AuthorizedMergedKey(_mergedKeyIndexWithParity, _mergedKey);
    }

    /// @notice Performs an emergency recovery operation, removing all existing authorizations and setting
    ///  a sole new authorized address with optional cosigner. THIS IS A SCORCHED EARTH SOLUTION, and great
    ///  care should be taken to ensure that this method is never called unless it is a last resort. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this method
    ///  is not trivially abused.
    /// @param _authorizedAddress the new and sole authorized address
    /// @param _cosigner the corresponding cosigner address, can be equal to _authorizedAddress
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function emergencyRecovery(
        address _authorizedAddress,
        uint256 _cosigner,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) external onlyRecoveryAddress {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != address(0), "cosigner must not be zero");

        // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
        // on the authorizations variable (above) for more information.
        authVersion += AUTH_VERSION_INCREMENTOR;

        // Store the new signer/cosigner pair as the only remaining authorized address
        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        emit EmergencyRecovery(_authorizedAddress, _cosigner);
    }

    /// @notice same as emergencyRecovery, but with a recovery address
    /// @param _authorizedAddress the new and sole authorized address
    /// @param _cosigner the corresponding cosigner address, can be equal to _authorizedAddress
    /// @param _recoveryAddress recovery address
    /// @param _mergedKeyIndexWithParity the merged key index
    /// @param _mergedKey the corresponding merged authorized key & cosigner key by Schnorr
    function emergencyRecovery2(
        address _authorizedAddress,
        uint256 _cosigner,
        address _recoveryAddress,
        uint8 _mergedKeyIndexWithParity,
        bytes32 _mergedKey
    ) external onlyRecoveryAddress {
        require(_authorizedAddress != address(0), "authorized address must not be zero");
        require(_authorizedAddress != _recoveryAddress, "do not use the recovery address as an authorized address");
        require(address(uint160(_cosigner)) != address(0), "cosigner must not be zero");
        require(_recoveryAddress != address(0), "recovery address must not be zero");
        require(address(uint160(_cosigner)) != _recoveryAddress, "do not use the recovery address as a cosigner");

        // Incrementing the authVersion number effectively erases the authorizations mapping. See the comments
        // on the authorizations variable (above) for more information.
        authVersion += AUTH_VERSION_INCREMENTOR;

        // Store the new signer/cosigner pair as the only remaining authorized address
        authorizations[authVersion + uint256(uint160(_authorizedAddress))] = _cosigner;
        mergedKeys[authVersion + _mergedKeyIndexWithParity] = _mergedKey;
        // set new recovery address
        address previous = recoveryAddress;
        recoveryAddress = _recoveryAddress;

        emit RecoveryAddressChanged(previous, recoveryAddress);
        emit EmergencyRecovery(_authorizedAddress, _cosigner);
    }

    /// @notice Sets the recovery address, which can be zero (indicating that no recovery is possible)
    ///  Can be updated by any authorized address. This address should be set with GREAT CARE. See the
    ///  comments above about the proper kinds of addresses to use as the recoveryAddress to ensure this
    ///  mechanism is not trivially abused.
    /// @dev Must be called through `invoke()`
    /// @param _recoveryAddress the new recovery address
    function setRecoveryAddress(address _recoveryAddress) external onlyInvoked {
        require(
            address(uint160(authorizations[authVersion + uint256(uint160(_recoveryAddress))])) == address(0),
            "do not use an authorized address as the recovery address"
        );
        require(_recoveryAddress != address(0), "recovery address must not be zero");

        address previous = recoveryAddress;
        recoveryAddress = _recoveryAddress;

        emit RecoveryAddressChanged(previous, recoveryAddress);
    }

    /// @notice Allows ANY caller to recover gas by way of deleting old authorization keys after
    ///  a recovery operation. Anyone can call this method to delete the old unused storage and
    ///  get themselves a bit of gas refund in the bargin.
    /// @dev keys must be known to caller or else nothing is refunded
    /// @param _version the version of the mapping which you want to delete (unshifted)
    /// @param _keys the authorization keys to delete
    function recoverGas(uint256 _version, address[] calldata _keys) external {
        require(_version < 0xffffffffffffffffffffffff, "invalid version number");

        uint256 shiftedVersion = _version << 160;

        require(shiftedVersion < authVersion, "only recover gas from expired authVersions");

        for (uint256 i = 0; i < _keys.length; ++i) {
            delete(authorizations[shiftedVersion + uint256(uint160(_keys[i]))]);
        }
    }

    function verifySchnorr(bytes32 hash, bytes memory sig) internal view returns (bool) {
        // px := public key x-coord
        // e := schnorr signature challenge
        // s := schnorr signature
        // parity := public key y-coord parity (27 or 28)
        (bytes32 e, bytes32 s, uint8 keyIndexWithParity) = sig.extractSignature(0);
        // require(s <= S_MAX, "s of signature is too large");
        bytes32 px = mergedKeys[authVersion + uint256(keyIndexWithParity)];
        uint8 parity = (keyIndexWithParity & 0x1) + 27;

        bytes32 sp = bytes32(Q - mulmod(uint256(s), uint256(px), Q));
        bytes32 ep = bytes32(Q - mulmod(uint256(e), uint256(px), Q));

        require(sp != 0);
        // the ecrecover precompile implementation checks that the `r` and `s`
        // inputs are non-zero (in this case, `px` and `ep`), thus we don't need to
        // check if they're zero.
        address R = ecrecover(sp, parity, px, ep);
        require(R != address(0), "ecrecover failed");
        return e == keccak256(abi.encodePacked(R, parity, px, hash));
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    ///  See https://github.com/ethereum/EIPs/issues/1271
    /// @dev This function meets the following conditions as per the EIP:
    ///  MUST return the bytes4 magic value `0x1626ba7e` when function passes.
    ///  MUST NOT modify state (using `STATICCALL` for solc < 0.5, `view` modifier for solc > 0.5)
    ///  MUST allow external calls
    /// @param _hash A 32 byte hash of the signed data.  The actual hash that is hashed however is the
    ///  the following tightly packed arguments: `0x19,0x0,wallet_address,hash`
    /// @param _signature Signature byte array associated with `_data`
    /// @return Magic value `0x1626ba7e` upon success, 0 otherwise.
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4) {
        // We 'hash the hash' for the following reasons:
        // 1. `hash` is not the hash of an Ethereum transaction
        // 2. signature must target this wallet to avoid replaying the signature for another wallet
        // with the same key
        // 3. Gnosis does something similar:
        // https://github.com/gnosis/safe-contracts/blob/102e632d051650b7c4b0a822123f449beaf95aed/contracts/GnosisSafe.sol
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _hash));

        return _isValidSignature(operationHash, _signature);
    }

    /// @notice Should return whether the signature provided is valid for the provided data
    ///  See https://github.com/ethereum/EIPs/issues/1271
    /// @dev This function meets the following conditions as per the EIP:
    ///  MUST return the bytes4 magic value `0x1626ba7e` when function passes.
    /// @param _operationHash A 32 byte hash of the signed data.  For internal usage, the _operationHash shoule be hash with EIP191V0 first
    /// @param _signature Signature byte array associated with `_data`
    /// @return Magic value `0x1626ba7e` upon success, 0 otherwise.
    function _isValidSignature(bytes32 _operationHash, bytes calldata _signature) private view returns (bytes4) {
        if (_signature.length == 65 && (_signature[64] & 0x80) > 0) {
            return verifySchnorr(_operationHash, _signature) ? IERC1271.isValidSignature.selector : bytes4(0);
        }

        bytes32[2] memory r;
        bytes32[2] memory s;
        uint8[2] memory v;
        address signer;
        address cosigner;

        // extract 1 or 2 signatures depending on length
        if (_signature.length == 65) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            require(s[0] <= S_MAX, "s of signature[0] is too large");
            signer = ecrecover(_operationHash, v[0], r[0], s[0]);
            cosigner = signer;
        } else if (_signature.length == 130) {
            (r[0], s[0], v[0]) = _signature.extractSignature(0);
            require(s[0] <= S_MAX, "s of signature[0] is too large");
            (r[1], s[1], v[1]) = _signature.extractSignature(65);
            require(s[1] <= S_MAX, "s of signature[1] is too large");
            signer = ecrecover(_operationHash, v[0], r[0], s[0]);
            cosigner = ecrecover(_operationHash, v[1], r[1], s[1]);
        } else {
            return 0;
        }

        // check for valid signature
        if (signer == address(0)) {
            return 0;
        }

        // check for valid signature
        if (cosigner == address(0)) {
            return 0;
        }

        // check to see if this is an authorized key
        if (address(uint160(authorizations[authVersion + uint256(uint160(signer))])) != cosigner) {
            return 0;
        }

        return IERC1271.isValidSignature.selector;
    }

    /// @notice A version of `invoke()` that has no explicit signatures, and uses msg.sender
    ///  as both the signer and cosigner. Will only succeed if `msg.sender` is an authorized
    ///  signer for this wallet, with no cosigner, saving transaction size and gas in that case.
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke0(bytes calldata data) external {
        // The nonce doesn't need to be incremented for transactions that don't include explicit signatures;
        // the built-in nonce of the native ethereum transaction will protect against replay attacks, and we
        // can save the gas that would be spent updating the nonce variable

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner)
        require(
            address(uint160(authorizations[authVersion + uint256(uint160(msg.sender))])) == msg.sender,
            "invalid authorization"
        );

        internalInvoke(0, data);
    }

    /// @notice A version of `invoke()` that has one explicit signature which is used to derive the authorized
    ///  address. Uses `msg.sender` as the cosigner.
    /// @param v the v value for the signature; see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
    /// @param r the r value for the signature
    /// @param s the s value for the signature
    /// @param inonce the nonce value for the signature
    /// @param authorizedAddress the address of the authorization key; this is used here so that cosigner signatures are interchangeable
    ///  between this function and `invoke2()`
    /// @param data The data containing the transactions to be invoked; see internalInvoke for details.
    function invoke1CosignerSends(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 inonce,
        address authorizedAddress,
        bytes calldata data
    ) external {
        // check signature version
        require(v == 27 || v == 28, "invalid signature version");
        require(s <= S_MAX, "s of signature is too large");
        // calculate hash
        bytes32 operationHash = keccak256(
            abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, inonce, authorizedAddress, data)
        );

        // recover signer
        address signer = ecrecover(operationHash, v, r, s);

        // check for valid signature
        require(signer != address(0), "invalid signature");

        // check nonce
        require(inonce > nonce && (inonce < (nonce + 10)), "must use valid nonce for signer");

        // check signer
        require(signer == authorizedAddress, "authorized addresses must be equal");

        // Get cosigner
        address requiredCosigner = address(uint160(authorizations[authVersion + uint256(uint160(signer))]));

        // The operation should be approved if the signer address has no cosigner (i.e. signer == cosigner) or
        // if the actual cosigner matches the required cosigner.
        require(requiredCosigner == signer || requiredCosigner == msg.sender, "invalid authorization");

        // set nonce
        nonce = inonce;

        // call internal function
        internalInvoke(operationHash, data);
    }

    /// @notice A version of `invoke()` that use isValidSignature to check the authorization of signers
    /// @param _nonce the nonce value for the signature
    /// @param _data The data containing the transactions to be invoked; see internalInvoke for details.
    /// @param _signature Signature byte array associated with `_nonce, _data`
    function invoke2(uint256 _nonce, bytes calldata _data, bytes calldata _signature) external {
        // calculate hash
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _nonce, _data));

        // valid signature
        bytes4 result = _isValidSignature(operationHash, _signature);
        require(result == IERC1271.isValidSignature.selector, "invalid signature");

        // check nonce
        require(_nonce > nonce && (_nonce < (nonce + 10)), "must use valid nonce");

        // set nonce
        nonce = _nonce;

        // call internal function
        internalInvoke(operationHash, _data);
    }

    /// @notice simulate invoke2 result off-chain
    /// @dev this function will revert always
    /// @param _nonce the nonce value for the signature
    /// @param _data The data containing the transactions to be invoked; see internalInvoke for details.
    /// @param _signature Signature byte array associated with `_nonce, _data`
    function simulateInvoke2(uint256 _nonce, bytes calldata _data, bytes calldata _signature) external {
        // calculate hash
        bytes32 operationHash =
            keccak256(abi.encodePacked(EIP191_PREFIX, EIP191_VERSION_DATA, this, block.chainid, _nonce, _data));

        // valid signature
        bytes4 result = _isValidSignature(operationHash, _signature);
        // always pass
        require(result >= 0, "invalid signature");

        // check nonce
        require(_nonce > nonce && (_nonce < type(uint256).max), "must use valid nonce");

        // set nonce
        nonce = _nonce;

        // call internal function
        internalInvoke(operationHash, _data);

        // always revert
        revert ExecutionResult(true);
    }

    /// @dev Internal invoke call,
    /// @param operationHash The hash of the operation
    /// @param data The data to send to the `call()` operation
    ///  The data is prefixed with a global 1 byte revert flag
    ///  If revert is 1, then any revert from a `call()` operation is rethrown.
    ///  Otherwise, the error is recorded in the `result` field of the `InvocationSuccess` event.
    ///  Immediately following the revert byte (no padding), the data format is then is a series
    ///  of 1 or more tightly packed tuples:
    ///  `<target(20),amount(32),datalength(32),data>`
    ///  If `datalength == 0`, the data field must be omitted
    function internalInvoke(bytes32 operationHash, bytes memory data) internal {
        // keep track of the number of operations processed
        uint256 numOps;
        // keep track of the result of each operation as a bit
        uint256 result;

        // We need to store a reference to this string as a variable so we can use it as an argument to
        // the revert call from assembly.
        string memory invalidLengthMessage = "data field too short";
        string memory callFailed = "call failed";

        // At an absolute minimum, the data field must be at least 85 bytes
        // <revert(1), to_address(20), value(32), data_length(32)>
        require(data.length >= 85, invalidLengthMessage);

        // Forward the call onto its actual target. Note that the target address can be `self` here, which is
        // actually the required flow for modifying the configuration of the authorized keys and recovery address.
        //
        // The assembly code below loads data directly from memory, so the enclosing function must be marked `internal`
        assembly {
            // A cursor pointing to the revert flag, starts after the length field of the data object
            let memPtr := add(data, 32)

            // The revert flag is the leftmost byte from memPtr
            let revertFlag := byte(0, mload(memPtr))

            // A pointer to the end of the data object
            let endPtr := add(memPtr, mload(data))

            // Now, memPtr is a cursor pointing to the beginning of the current sub-operation
            memPtr := add(memPtr, 1)

            // Loop through data, parsing out the various sub-operations
            for {} lt(memPtr, endPtr) {} {
                // Load the length of the call data of the current operation
                // 52 = to(20) + value(32)
                let len := mload(add(memPtr, 52))

                // Compute a pointer to the end of the current operation
                // 84 = to(20) + value(32) + size(32)
                let opEnd := add(len, add(memPtr, 84))

                // Bail if the current operation's data overruns the end of the enclosing data buffer
                // NOTE: Comment out this bit of code and uncomment the next section if you want
                // the solidity-coverage tool to work.
                // See https://github.com/sc-forks/solidity-coverage/issues/287
                if gt(opEnd, endPtr) {
                    // The computed end of this operation goes past the end of the data buffer. Not good!
                    revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                }
                // NOTE: Code that is compatible with solidity-coverage
                // switch gt(opEnd, endPtr)
                // case 1 {
                //     revert(add(invalidLengthMessage, 32), mload(invalidLengthMessage))
                // }

                // This line of code packs in a lot of functionality!
                //  - load the target address from memPtr, the address is only 20-bytes but mload always grabs 32-bytes,
                //    so we have to shr by 12 bytes.
                //  - load the value field, stored at memPtr+20
                //  - pass a pointer to the call data, stored at memPtr+84
                //  - use the previously loaded len field as the size of the call data
                //  - make the call (passing all remaining gas to the child call)
                //  - check the result (0 == reverted)
                if eq(0, call(gas(), shr(96, mload(memPtr)), mload(add(memPtr, 20)), add(memPtr, 84), len, 0, 0)) {
                    switch revertFlag
                    case 1 { revert(add(callFailed, 32), mload(callFailed)) }
                    default {
                        // mark this operation as failed
                        // create the appropriate bit, 'or' with previous
                        result := or(result, exp(2, numOps))
                    }
                }

                // increment our counter
                numOps := add(numOps, 1)

                // Update mem pointer to point to the next sub-operation
                memPtr := opEnd
            }
        }

        // emit single event upon success
        emit InvocationSuccess(operationHash, result, numOps);
    }
}