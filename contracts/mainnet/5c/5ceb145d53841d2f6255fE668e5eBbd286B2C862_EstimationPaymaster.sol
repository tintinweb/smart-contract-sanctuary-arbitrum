// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

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
	function validateUserOpSignature(UserOperation calldata userOp) external view returns (bytes memory sigForUserOp);

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
pragma solidity 0.8.17;

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
	event UserOperationEvent(
		bytes32 indexed userOpHash,
		address indexed sender,
		address indexed paymaster,
		uint256 nonce,
		bool success,
		uint256 actualGasCost,
		uint256 actualGasUsed
	);

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
	error ValidationResult(ReturnInfo returnInfo, StakeInfo senderInfo, StakeInfo factoryInfo, StakeInfo paymasterInfo);

	/**
	 * Successful result from simulateValidation, if the account returns a signature aggregator
	 * @param returnInfo gas and time-range returned values
	 * @param senderInfo stake information about the sender
	 * @param factoryInfo stake information about the factory (if any)
	 * @param paymasterInfo stake information about the paymaster (if any)
	 * @param aggregatorInfo signature aggregation info (if the account requires signature aggregator)
	 *      bundler MUST use it to verify the signature, or reject the UserOperation
	 */
	error ValidationResultWithAggregation(
		ReturnInfo returnInfo,
		StakeInfo senderInfo,
		StakeInfo factoryInfo,
		StakeInfo paymasterInfo,
		AggregatorStakeInfo aggregatorInfo
	);

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
	function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external;

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
pragma solidity 0.8.17;

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
	function getNonce(address sender, uint192 key) external view returns (uint256 nonce);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./UserOperation.sol";

/**
 * the interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * a paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {
	enum PostOpMode {
		opSucceeded, // user op succeeded
		opReverted, // user op reverted. still has to pay for gas.
		postOpReverted //user op succeeded, but caused postOp to revert. Now it's a 2nd call, after user's op was deliberately reverted.
	}

	/**
	 * payment validation: check if paymaster agrees to pay.
	 * Must verify sender is the entryPoint.
	 * Revert to reject this request.
	 * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
	 * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
	 * @param userOp the user operation
	 * @param userOpHash hash of the user's request data.
	 * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
	 * @return context value to send to a postOp
	 *      zero length to signify postOp is not required.
	 * @return validationData signature and time-range of this operation, encoded the same as the return value of validateUserOperation
	 *      <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
	 *         otherwise, an address of an "authorizer" contract.
	 *      <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
	 *      <6-byte> validAfter - first timestamp this operation is valid
	 *      Note that the validation code cannot use block.timestamp (or block.number) directly.
	 */
	function validatePaymasterUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 maxCost
	) external returns (bytes memory context, uint256 validationData);

	/**
	 * post-operation handler.
	 * Must verify sender is the entryPoint
	 * @param mode enum with the following options:
	 *      opSucceeded - user operation succeeded.
	 *      opReverted  - user op reverted. still has to pay for gas.
	 *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
	 *                       Now this is the 2nd call, after user's op was deliberately reverted.
	 * @param context - the context value returned by validatePaymasterUserOp
	 * @param actualGasCost - actual gas used so far (without this postOp call).
	 */
	function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
	event Deposited(address indexed account, uint256 totalDeposit);

	event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);

	/// Emitted when stake or unstake delay are modified
	event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec);

	/// Emitted once a stake is scheduled for withdrawal
	event StakeUnlocked(address indexed account, uint256 withdrawTime);

	event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount);

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
pragma solidity 0.8.17;

/* solhint-disable no-inline-assembly */

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
		assembly {
			data := calldataload(userOp)
		}
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
		//lighter signature scheme. must match UserOp.ts#packUserOp
		bytes calldata sig = userOp.signature;
		// copy directly the userOp from calldata up to (but not including) the signature.
		// this encoding depends on the ABI encoding of calldata, but is much lighter to copy
		// than referencing each field separately.
		assembly {
			let ofs := userOp
			let len := sub(sub(sig.offset, ofs), 32)
			ret := mload(0x40)
			mstore(0x40, add(ret, add(len, 32)))
			mstore(ret, len)
			calldatacopy(add(ret, 32), ofs, len)
		}
	}

	function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
		return keccak256(pack(userOp));
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/* solhint-disable reason-string */


import "../utils/Ownable2StepNoRenounce.sol";
import "../interfaces/eip-4337/IPaymaster.sol";
import "../interfaces/eip-4337/IEntryPoint.sol";

/**
 * @title BasePaymaster
 * @author fun.xyz eth-infinitism
 * @notice Helper class for creating a paymaster.
 * provides helper methods for staking.
 * validates that the postOp is called only by the entryPoint
 */
abstract contract BasePaymaster is IPaymaster, Ownable2StepNoRenounce {
	IEntryPoint public immutable entryPoint;

	constructor(IEntryPoint _entryPoint) {
		require(address(_entryPoint) != address(0), "FW300");
		entryPoint = _entryPoint;
		emit PaymasterCreated(_entryPoint);
	}

	/**
	 * payment validation: check if paymaster agrees to pay.
	 * Must verify sender is the entryPoint.
	 * Revert to reject this request.
	 * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
	 * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
	 * @param userOp the user operation
	 * @param userOpHash hash of the user's request data.
	 * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
	 * @return context value to send to a postOp
	 *      zero length to signify postOp is not required.
	 * @return sigTimeRange Note: we do not currently support validUntil and validAfter
	 */
	function validatePaymasterUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 maxCost
	) external override returns (bytes memory context, uint256 sigTimeRange) {
		_requireFromEntryPoint();
		return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
	}

	/**
	 * payment validation: check if paymaster agrees to pay.
	 * Must verify sender is the entryPoint.
	 * Revert to reject this request.
	 * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted)
	 * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
	 * @param userOp the user operation
	 * @param userOpHash hash of the user's request data.
	 * @param maxCost the maximum cost of this transaction (based on maximum gas and gas price from userOp)
	 * @return context value to send to a postOp
	 *      zero length to signify postOp is not required.
	 * @return sigTimeRange Note: we do not currently support validUntil and validAfter
	 */
	function _validatePaymasterUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 maxCost
	) internal virtual returns (bytes memory context, uint256 sigTimeRange);

	/**
	 * post-operation handler.
	 * Must verify sender is the entryPoint
	 * @param mode enum with the following options:
	 *      opSucceeded - user operation succeeded.
	 *      opReverted  - user op reverted. still has to pay for gas.
	 *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
	 *                       Now this is the 2nd call, after user's op was deliberately reverted.
	 * @param context - the context value returned by validatePaymasterUserOp
	 * @param actualGasCost - actual gas used so far (without this postOp call).
	 */
	function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external override {
		_requireFromEntryPoint();
		_postOp(mode, context, actualGasCost);
	}

	/**
	 * post-operation handler.
	 * (verified to be called only through the entryPoint)
	 * @dev if subclass returns a non-empty context from validatePaymasterUserOp, it must also implement this method.
	 * @param mode enum with the following options:
	 *      opSucceeded - user operation succeeded.
	 *      opReverted  - user op reverted. still has to pay for gas.
	 *      postOpReverted - user op succeeded, but caused postOp (in mode=opSucceeded) to revert.
	 *                       Now this is the 2nd call, after user's op was deliberately reverted.
	 * @param context - the context value returned by validatePaymasterUserOp
	 * @param actualGasCost - actual gas used so far (without this postOp call).
	 */
	function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal virtual {
		(mode, context, actualGasCost); // unused params
		// subclass must override this method if validatePaymasterUserOp returns a context
		revert("must override");
	}

	/**
	 * add stake for this paymaster.
	 * This method can also carry eth value to add to the current stake.
	 * @param unstakeDelaySec - the unstake delay for this paymaster. Can only be increased.
	 */
	function addStakeToEntryPoint(uint32 unstakeDelaySec) external payable onlyOwner {
		entryPoint.addStake{value: msg.value}(unstakeDelaySec);
	}

	/**
	 * unlock the stake, in order to withdraw it.
	 * The paymaster can't serve requests once unlocked, until it calls addStake again
	 */
	function unlockStakeFromEntryPoint() external onlyOwner {
		entryPoint.unlockStake();
	}

	/**
	 * withdraw the entire paymaster's stake.
	 * stake must be unlocked first (and then wait for the unstakeDelay to be over)
	 * @param withdrawAddress the address to send withdrawn value.
	 */
	function withdrawStakeFromEntryPoint(address payable withdrawAddress) external onlyOwner {
		require(withdrawAddress != address(0), "FW351");
		entryPoint.withdrawStake(withdrawAddress);
	}

	/// validate the call is made from a valid entrypoint
	function _requireFromEntryPoint() internal virtual {
		require(msg.sender == address(entryPoint), "FW301");
	}

	event PaymasterCreated(IEntryPoint entryPoint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

/* solhint-disable reason-string */

import "./BasePaymaster.sol";
import "../utils/HashLib.sol";

/**
 * @title Estimation paymaster Contract
 * @author fun.xyz
 * @notice A contract that extends the BasePaymaster contract. This allows sponsors to estimate the gas of useroperations without a prefund.
 */
contract EstimationPaymaster is BasePaymaster {
	using UserOperationLib for UserOperation;

	mapping(address => uint256) public balances;

	constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

	receive() external payable {
		addDepositTo(msg.sender);
	}

	/**
	 * @notice Adds the specified deposit amount to the deposit balance of the given sponsor address.
	 * @param sponsor The address of the sponsor whose deposit balance will be increased.
	 * @dev msg.value: The amount of the deposit to be added.
	 * @dev Deposits were added so that fun.xyz doesn't control the ability to get estimates.
	 */
	function addDepositTo(address sponsor) public payable {
		balances[sponsor] += msg.value;
		entryPoint.depositTo{value: msg.value}(address(this));
	}

	/**
	 * @notice Withdraws the specified deposit amount from the deposit balance of the calling sender and transfers it to the target address.
	 * @param target The address to which the deposit amount will be transferred.
	 * @param amount The amount of the deposit to be withdrawn and transferred.
	 */
	function withdrawDepositTo(uint256 amount, address payable target) external {
		require(balances[msg.sender] >= amount, "Insufficient balance");
		balances[msg.sender] -= amount;
		entryPoint.withdrawTo(target, amount);
	}

	/**
	 * @notice Bypasses paymaster step in validation so additional gas isn't added. 
	 	We must return context information so the postop can be executed. 
		Return signature failed so estimation works.
	 */
	function _validatePaymasterUserOp(
		UserOperation calldata,
		bytes32,
		uint256
	) internal view override returns (bytes memory context, uint256 sigTimeRange) {
		return ("fun.xyz", 1);
	}

	/**
	 * @notice Always revert so the gas estimation passes but execution is stopped.
	 */
	function _postOp(PostOpMode, bytes calldata, uint256) internal override {
		return;
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

library HashLib {
	/**
	 * Keccak256 all parameters together
	 * @param a bytes32
	 */
	function hash1(bytes32 a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash1(address a) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			_hash := keccak256(0x00, 0x20)
		}
	}

	function hash2(bytes32 a, bytes32 b) internal pure returns (bytes32 _hash) {
		assembly {
			mstore(0x0, a)
			mstore(0x20, b)
			_hash := keccak256(0x00, 0x40)
		}
	}

	function hash2(bytes32 a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, a)
			mstore(0x20, _b)
			_hash := keccak256(0x00, 0x34)
		}
	}

	function hash2(address a, address b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		assembly {
			mstore(0x0, _a)
			mstore(0x14, _b)
			_hash := keccak256(0x00, 0x28)
		}
	}

	function hash2(address a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes1 _b = bytes1(b);

		assembly {
			mstore(0x0, _b)
			mstore(0x1, _a)
			_hash := keccak256(0x00, 0x15)
		}
	}

	function hash2(bytes32 a, uint8 b) internal pure returns (bytes32 _hash) {
		bytes1 _b = bytes1(b);
		assembly {
			mstore(0x0, _b)
			mstore(0x1, a)
			_hash := keccak256(0x00, 0x21)
		}
	}

	function hash3(address a, address b, uint8 c) internal pure returns (bytes32 _hash) {
		bytes20 _a = bytes20(a);
		bytes20 _b = bytes20(b);
		bytes1 _c = bytes1(c);
		assembly {
			mstore(0x00, _c)
			mstore(0x01, _a)
			mstore(0x15, _b)
			_hash := keccak256(0x00, 0x29)
		}
	}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Ownable2StepNoRenounce is Ownable2Step {
	function renounceOwnership() public override onlyOwner {
		revert("FW601");
	}
}