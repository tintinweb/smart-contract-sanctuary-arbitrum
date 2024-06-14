// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import './libs/SignatureValidator.sol';
import './ExternalSigValidator.sol';
import './libs/erc4337/PackedUserOperation.sol';
import './libs/erc4337/UserOpHelper.sol';
import './deployless/IAmbireAccount.sol';

/**
 * @notice  A validator that performs DKIM signature recovery
 * @dev     All external/public functions (that are not view/pure) use `payable` because AmbireAccount
 * is a wallet contract, and any ETH sent to it is not lost, but on the other hand not having `payable`
 * makes the Solidity compiler add an extra check for `msg.value`, which in this case is wasted gas
 */
contract AmbireAccount is IAmbireAccount {
	// @dev We do not have a constructor. This contract cannot be initialized with any valid `privileges` by itself!
	// The intended use case is to deploy one base implementation contract, and create a minimal proxy for each user wallet, by
	// using our own code generation to insert SSTOREs to initialize `privileges` (it was previously called IdentityProxyDeploy.js, now src/libs/proxyDeploy/deploy.ts)
	address private constant FALLBACK_HANDLER_SLOT = address(0x6969);

	// @dev This is how we understand if msg.sender is the entry point
	bytes32 private constant ENTRY_POINT_MARKER = 0x0000000000000000000000000000000000000000000000000000000000007171;

	// Externally validated signatures
	uint8 private constant SIGMODE_EXTERNALLY_VALIDATED = 255;

	// Variables
	mapping(address => bytes32) public privileges;
	uint256 public nonce;

	// Events
	event LogPrivilegeChanged(address indexed addr, bytes32 priv);
	event LogErr(address indexed to, uint256 value, bytes data, bytes returnData); // only used in tryCatch

	// This contract can accept ETH without calldata
	receive() external payable {}

	/**
	 * @dev     To support EIP 721 and EIP 1155, we need to respond to those methods with their own method signature
	 * @return  bytes4  onERC721Received function selector
	 */
	function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
		return this.onERC721Received.selector;
	}

	/**
	 * @dev     To support EIP 721 and EIP 1155, we need to respond to those methods with their own method signature
	 * @return  bytes4  onERC1155Received function selector
	 */
	function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
		return this.onERC1155Received.selector;
	}

	/**
	 * @dev     To support EIP 721 and EIP 1155, we need to respond to those methods with their own method signature
	 * @return  bytes4  onERC1155Received function selector
	 */
	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return this.onERC1155BatchReceived.selector;
	}

	/**
	 * @notice  fallback method: currently used to call the fallback handler
	 * which is set by the user and can be changed
	 * @dev     this contract can accept ETH with calldata, hence payable
	 */
	fallback() external payable {
		// We store the fallback handler at this magic slot
		address fallbackHandler = address(uint160(uint(privileges[FALLBACK_HANDLER_SLOT])));
		if (fallbackHandler == address(0)) return;
		assembly {
			// we can use addr 0 because logic is taking full control of the
			// execution making sure it returns itself and does not
			// rely on any further Solidity code.
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), fallbackHandler, 0, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(0, 0, size)
			if eq(result, 0) {
				revert(0, size)
			}
			return(0, size)
		}
	}

	/**
	 * @notice  used to set the privilege of a key (by `addr`)
	 * @dev     normal signatures will be considered valid if the
	 * `addr` they are signed with has non-zero (not 0x000..000) privilege set; we can set the privilege to
	 * a hash of the recovery keys and timelock (see `RecoveryInfo`) to enable recovery signatures
	 * @param   addr  the address to give privs to
	 * @param   priv  the privs to give
	 */
	function setAddrPrivilege(address addr, bytes32 priv) external payable {
		require(msg.sender == address(this), 'ONLY_ACCOUNT_CAN_CALL');
		privileges[addr] = priv;
		emit LogPrivilegeChanged(addr, priv);
	}

	/**
	 * @notice  Useful when we need to do multiple operations but ignore failures in some of them
	 * @param   to  address we're sending value to
	 * @param   value  the amount
	 * @param   data  callData
	 */
	function tryCatch(address to, uint256 value, bytes calldata data) external payable {
		require(msg.sender == address(this), 'ONLY_ACCOUNT_CAN_CALL');
		uint256 gasBefore = gasleft();
		(bool success, bytes memory returnData) = to.call{ value: value, gas: gasBefore }(data);
		require(gasleft() > gasBefore / 64, 'TRYCATCH_OOG');
		if (!success) emit LogErr(to, value, data, returnData);
	}

	/**
	 * @notice  same as `tryCatch` but with a gas limit
	 * @param   to  address we're sending value to
	 * @param   value  the amount
	 * @param   data  callData
	 * @param   gasLimit  how much gas is allowed
	 */
	function tryCatchLimit(address to, uint256 value, bytes calldata data, uint256 gasLimit) external payable {
		require(msg.sender == address(this), 'ONLY_ACCOUNT_CAN_CALL');
		uint256 gasBefore = gasleft();
		(bool success, bytes memory returnData) = to.call{ value: value, gas: gasLimit }(data);
		require(gasleft() > gasBefore / 64, 'TRYCATCH_OOG');
		if (!success) emit LogErr(to, value, data, returnData);
	}

	/**
	 * @notice  execute: this method is used to execute a single bundle of calls that are signed with a key
	 * that is authorized to execute on this account (in `privileges`)
	 * @dev     WARNING: if the signature of this is changed, we have to change AmbireAccountFactory
	 * @param   calls  the transaction we're executing. They may not execute
	 * if specific cases. One such is when setting a timelock
	 * @param   signature  the signature for the transactions
	 */
	function execute(Transaction[] calldata calls, bytes calldata signature) public payable {
		address signerKey;
		uint8 sigMode = uint8(signature[signature.length - 1]);
		uint256 currentNonce = nonce;
		// we increment the nonce here (not using `nonce++` to save some gas)
		nonce = currentNonce + 1;

		if (sigMode == SIGMODE_EXTERNALLY_VALIDATED) {
			bool isValidSig;
			uint256 timestampValidAfter;
			(signerKey, isValidSig, timestampValidAfter) = validateExternalSig(calls, signature);
			if (!isValidSig) {
				require(block.timestamp >= timestampValidAfter, 'SIGNATURE_VALIDATION_TIMELOCK');
				revert('SIGNATURE_VALIDATION_FAIL');
			}
		} else {
			signerKey = SignatureValidator.recoverAddr(
				keccak256(abi.encode(address(this), block.chainid, currentNonce, calls)),
				signature,
				true
			);
			require(privileges[signerKey] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		}

		executeBatch(calls);

		// The actual anti-bricking mechanism - do not allow a signerKey to drop their own privileges
		require(privileges[signerKey] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	/**
	 * @notice  allows executing multiple bundles of calls (batch together multiple executes)
	 * @param   toExec  an array of execute function parameters
	 */
	function executeMultiple(ExecuteArgs[] calldata toExec) external payable {
		for (uint256 i = 0; i != toExec.length; i++) execute(toExec[i].calls, toExec[i].signature);
	}

	/**
	 * @notice  Allows executing calls if the caller itself is authorized
	 * @dev     no need for nonce management here cause we're not dealing with sigs
	 * @param   calls  the transaction we're executing
	 */
	function executeBySender(Transaction[] calldata calls) external payable {
		require(privileges[msg.sender] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		executeBatch(calls);
		// again, anti-bricking
		require(privileges[msg.sender] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	/**
	 * @notice  allows the contract itself to execute a batch of calls
	 * self-calling is useful in cases like wanting to do multiple things in a tryCatchLimit
	 * @param   calls  the calls we're executing
	 */
	function executeBySelf(Transaction[] calldata calls) external payable {
		require(msg.sender == address(this), 'ONLY_ACCOUNT_CAN_CALL');
		executeBatch(calls);
	}

	/**
	 * @notice  allows the contract itself to execute a single calls
	 * self-calling is useful when you want to workaround the executeBatch()
	 * protection of not being able to call address(0)
	 * @param   call  the call we're executing
	 */
	function executeBySelfSingle(Transaction calldata call) external payable {
		require(msg.sender == address(this), 'ONLY_ACCOUNT_CAN_CALL');
		executeCall(call.to, call.value, call.data);
	}

	/**
	 * @notice  Execute a batch of transactions
	 * @param   calls  the transaction we're executing
	 */
	function executeBatch(Transaction[] memory calls) internal {
		uint256 len = calls.length;
		for (uint256 i = 0; i < len; i++) {
			Transaction memory call = calls[i];
			if (call.to != address(0)) executeCall(call.to, call.value, call.data);
		}
	}

	/**
	 * @notice  Execute a signle transaction
	 * @dev     we shouldn't use address.call(), cause: https://github.com/ethereum/solidity/issues/2884
	 * @param   to  the address we're sending to
	 * @param   value  the amount we're sending
	 * @param   data  callData
	 */
	function executeCall(address to, uint256 value, bytes memory data) internal {
		assembly {
			let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)

			if eq(result, 0) {
				let size := returndatasize()
				let ptr := mload(0x40)
				returndatacopy(ptr, 0, size)
				revert(ptr, size)
			}
		}
	}

	/**
	 * @notice  EIP-1271 implementation
	 * @dev     see https://eips.ethereum.org/EIPS/eip-1271
	 * @param   hash  the signed hash
	 * @param   signature  the signature for the signed hash
	 * @return  bytes4  is it a success or a failure
	 */
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
		(address recovered, bool usedUnprotected) = SignatureValidator.recoverAddrAllowUnprotected(hash, signature, false);
		if (uint256(privileges[recovered]) > (usedUnprotected ? 1 : 0)) {
			// bytes4(keccak256("isValidSignature(bytes32,bytes)")
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}

	/**
	 * @notice  EIP-1155 implementation
	 * we pretty much only need to signal that we support the interface for 165, but for 1155 we also need the fallback function
	 * @param   interfaceID  the interface we're signaling support for
	 * @return  bool  do we support the interface or not
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool) {
		bool supported = interfaceID == 0x01ffc9a7 || // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
			interfaceID == 0x150b7a02 || // ERC721TokenReceiver
			interfaceID == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
			interfaceID == 0x0a417632; // used for checking whether the account is v2 or not
		if (supported) return true;
		address payable fallbackHandler = payable(address(uint160(uint256(privileges[FALLBACK_HANDLER_SLOT]))));
		if (fallbackHandler == address(0)) return false;
		return AmbireAccount(fallbackHandler).supportsInterface(interfaceID);
	}

	//
	// EIP-4337 implementation
	//
	// return value in case of signature failure, with no time-range.
	// equivalent to packSigTimeRange(true,0,0);
	uint256 constant internal SIG_VALIDATION_FAILED = 1;
	// equivalent to packSigTimeRange(false,0,0);
	uint256 constant internal SIG_VALIDATION_SUCCESS = 0;

	/**
	 * @notice  EIP-4337 implementation
	 * @dev     We have an edge case for enabling ERC-4337 in the first if statement.
	 * If the function call is to execute, we do not perform an userOp sig validation.
	 * We require a one time hash nonce commitment from the paymaster for the given
	 * req. We use this to give permissions to the entry point on the fly
	 * and enable ERC-4337
	 * @param   op  the PackedUserOperation we're executing
	 * @param   userOpHash  the hash we've committed to
	 * @param   missingAccountFunds  the funds the account needs to pay
	 * @return  uint256  0 for success, 1 for signature failure, and a uint256
	 * packed timestamp for a future valid signature:
	 * address aggregator, uint48 validUntil, uint48 validAfter
	 */
	function validateUserOp(PackedUserOperation calldata op, bytes32 userOpHash, uint256 missingAccountFunds)
	external payable returns (uint256)
	{
		// enable running executeMultiple operation through the entryPoint if
		// a paymaster sponsors it with a commitment one-time nonce.
		// two use cases:
		// 1) enable 4337 on a network by giving privileges to the entryPoint
		// 2) key recovery. If the key is lost, we cannot sign the userOp,
		// so we have to go to `execute` to trigger the recovery logic
		// Why executeMultiple but not execute?
		// executeMultiple allows us to combine recovery + fee payment calls.
		// The fee payment call will be with a signature from the new key
		if (op.callData.length >= 4 && bytes4(op.callData[0:4]) == this.executeMultiple.selector) {
			// Require a paymaster, otherwise this mode can be used by anyone to get the user to spend their deposit
			// @estimation-no-revert
			if (op.signature.length != 0) return SIG_VALIDATION_FAILED;

			require(
				op.paymasterAndData.length >= UserOpHelper.PAYMASTER_DATA_OFFSET &&
				bytes20(op.paymasterAndData[:UserOpHelper.PAYMASTER_ADDR_OFFSET]) != bytes20(0),
				'validateUserOp: paymaster required in execute() mode'
			);

			// hashing in everything except sender (nonces are scoped by sender anyway), nonce, signature
			uint256 targetNonce = uint256(keccak256(
				abi.encode(op.initCode, op.callData, op.accountGasLimits, op.preVerificationGas, op.gasFees, op.paymasterAndData)
			)) << 64;

			// @estimation-no-revert
			if (op.nonce != targetNonce) return SIG_VALIDATION_FAILED;

			return SIG_VALIDATION_SUCCESS;
		}

		require(privileges[msg.sender] == ENTRY_POINT_MARKER, 'validateUserOp: not from entryPoint');

		// @estimation
		// paying should happen even if signature validation fails
		if (missingAccountFunds > 0) {
			// NOTE: MAY pay more than the minimum, to deposit for future transactions
			(bool success,) = msg.sender.call{value : missingAccountFunds}('');
			// ignore failure (its EntryPoint's job to verify, not account.)
			(success);
		}

		// this is replay-safe because userOpHash is retrieved like this: keccak256(abi.encode(userOp.hash(), address(this), block.chainid))
		address signer = SignatureValidator.recoverAddr(userOpHash, op.signature, true);
		if (privileges[signer] == bytes32(0)) return SIG_VALIDATION_FAILED;

		return SIG_VALIDATION_SUCCESS;
	}

	function validateExternalSig(Transaction[] memory calls, bytes calldata signature)
	internal returns(address signerKey, bool isValidSig, uint256 timestampValidAfter) {
		(bytes memory sig, ) = SignatureValidator.splitSignature(signature);
		// the address of the validator we're using for this validation
		address validatorAddr;
		// all the data needed by the validator to execute the validation.
		// In the case of DKIMRecoverySigValidator, this is AccInfo:
		// abi.encode {string emailFrom; string emailTo; string domainName;
		// bytes dkimPubKeyModulus; bytes dkimPubKeyExponent; address secondaryKey;
		// bool acceptUnknownSelectors; uint32 waitUntilAcceptAdded;
		// uint32 waitUntilAcceptRemoved; bool acceptEmptyDKIMSig;
		// bool acceptEmptySecondSig;uint32 onlyOneSigTimelock;}
		// The struct is declared in DKIMRecoverySigValidator
		bytes memory validatorData;
		// the signature data needed by the external validator.
		// In the case of DKIMRecoverySigValidator, this is abi.encode(
		// SignatureMeta memory sigMeta, bytes memory dkimSig, bytes memory secondSig
		// ).
		bytes memory innerSig;
		// the signerKey in this case is an arbitrary value that does
		// not have any specific purpose other than representing
		// the privileges key
		(signerKey, validatorAddr, validatorData, innerSig) = abi.decode(sig, (address, address, bytes, bytes));
		require(
			privileges[signerKey] == keccak256(abi.encode(validatorAddr, validatorData)),
			'EXTERNAL_VALIDATION_NOT_SET'
		);

		// The sig validator itself should throw when a signature isn't validated successfully
		// the return value just indicates whether we want to execute the current calls
		(isValidSig, timestampValidAfter) = ExternalSigValidator(validatorAddr).validateSig(validatorData, innerSig, calls);
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import './deployless/IAmbireAccount.sol';
import './libs/Transaction.sol';

/**
 * @notice  A contract used for deploying AmbireAccount.sol
 * @dev     We use create2 to get the AmbireAccount address. It's deterministic:
 * if the same data is passed to it, the same address will pop out.
 */
contract AmbireFactory {
	event LogDeployed(address addr, uint256 salt);

	address public immutable allowedToDrain;

	constructor(address allowed) {
		allowedToDrain = allowed;
	}

	/**
	 * @notice  Allows anyone to deploy any contracft with a specific code/salt
	 * @dev     This is safe because it's CREATE2 deployment
	 * @param   code  the code to be deployed
	 * @param   salt  the salt to shuffle the computed address
	 * @return  address  the deployed address
	 */
	function deploy(bytes calldata code, uint256 salt) external returns(address) {
		return deploySafe(code, salt);
	}

	
	/**
	 * @notice  Call this when you want to deploy the contract and execute calls
	 * @dev     When the relayer needs to act upon an /identity/:addr/submit call, it'll either call execute on the AmbireAccount directly
	 * if it's already deployed, or call `deployAndExecute` if the account is still counterfactual
	 * we can't have deployAndExecuteBySender, because the sender will be the factory
	 * @param   code  the code to be deployed
	 * @param   salt  the salt to shuffle the computed address
	 * @param   txns  the txns the are going to be executed
	 * @param   signature  the signature for the txns
	 * @return  address  the deployed address
	 */
	function deployAndExecute(
		bytes calldata code,
		uint256 salt,
		Transaction[] calldata txns,
		bytes calldata signature
	) external returns (address){
		address payable addr = payable(deploySafe(code, salt));
		IAmbireAccount(addr).execute(txns, signature);
		return addr;
	}

	
	/**
	 * @notice  Call this when you want to deploy the contract and call executeMultiple
	 * @dev     when the relayer needs to act upon an /identity/:addr/submit call, 
	 * it'll either call execute on the AmbireAccount directly. If it's already
	 * deployed, or call `deployAndExecuteMultiple` if the account is still
	 * counterfactual but there are multiple accountOps to send
	 * @param   code  the code to be deployed
	 * @param   salt  the salt to shuffle the computed address
	 * @param   toExec  [txns, signature] execute parameters
	 * @return  address  the deployed address
	 */
	function deployAndExecuteMultiple(
		bytes calldata code,
		uint256 salt,
		IAmbireAccount.ExecuteArgs[] calldata toExec
	) external returns (address){
		address payable addr = payable(deploySafe(code, salt));
		IAmbireAccount(addr).executeMultiple(toExec);
		return addr;
	}

	/**
	 * @notice  This method can be used to withdraw stuck tokens or airdrops
	 * @dev     Only allowedToDrain can do the call
	 * @param   to  receiver
	 * @param   value  how much to be sent
	 * @param   data  if a token has airdropped, code to send it
	 * @param   gas  maximum gas willing to spend
	 */
	function call(address to, uint256 value, bytes calldata data, uint256 gas) external {
		require(msg.sender == allowedToDrain, 'ONLY_AUTHORIZED');
		(bool success, bytes memory err) = to.call{ gas: gas, value: value }(data);
		require(success, string(err));
	}
	
	/**
	 * @dev     This is done to mitigate possible frontruns where, for example,
	 * where deploying the same code/salt via deploy() would make a pending
	 * deployAndExecute fail. The way we mitigate that is by checking if the
	 * contract is already deployed and if so, we continue execution
	 * @param   code  the code to be deployed
	 * @param   salt  the salt to shuffle the computed address
	 * @return  address  the deployed address
	 */
	function deploySafe(bytes memory code, uint256 salt) internal returns (address) {
		address expectedAddr = address(
			uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(code)))))
		);
		uint256 size;
		assembly {
			size := extcodesize(expectedAddr)
		}
		// If there is code at that address, we can assume it's the one we were about to deploy,
		// because of how CREATE2 and keccak256 works
		if (size == 0) {
			address addr;
			assembly {
				addr := create2(0, add(code, 0x20), mload(code), salt)
			}
			require(addr != address(0), 'FAILED_DEPLOYING');
			require(addr == expectedAddr, 'FAILED_MATCH');
			emit LogDeployed(addr, salt);
		}
		return expectedAddr;
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import './deployless/IAmbireAccount.sol';
import './libs/erc4337/IPaymaster.sol';
import './libs/SignatureValidator.sol';
import './libs/erc4337/UserOpHelper.sol';

contract AmbirePaymaster is IPaymaster {

	address immutable public relayer;

	constructor(address _relayer) {
		relayer = _relayer;
	}

	/**
	 * @notice  This method can be used to withdraw stuck tokens or airdrops
	 *
	 * @param   to  The address we're calling
	 * @param   value  The value in the call
	 * @param	data	the call data
	 * @param	gas	the call gas
	 */
	function call(address to, uint256 value, bytes calldata data, uint256 gas) external payable {
		require(msg.sender == relayer, 'call: not relayer');
		(bool success, bytes memory err) = to.call{ gas: gas, value: value }(data);
		require(success, string(err));
	}

	/**
	 * @notice  Validate user operations the paymaster has signed
	 * We do not need to send funds to the EntryPoint because we rely on pre-existing deposit.
	 * Requests are chain specific to prevent signature reuse.
	 * @dev     We have two use cases for the paymaster:
	 * - normal erc-4337. Everything is per ERC-4337 standard, the nonce is sequential.
	 * - an executeMultiple call. If the calldata is executeMultiple, we've hardcoded
	 * a 0 nonce. That's what's called a one-time hash nonce and its key is actually
	 * the commitment. Check EntryPoint -> NonceManager for more information.
	 *
	 * @param   userOp  the UserOperation we're executing
	 * @return  context  context is returned in the postOp and called by the
	 * EntryPoint. But we're not using postOp is context is always emtpy
	 * @return  validationData  This consists of:
	 * - an aggregator address: address(uint160(validationData)). This is used
	 * when you want an outer contract to determine whether the signature is valid.
	 * In our case, this is always 0 (address 0) for valid signatures and
	 * 1 (address 1) for invalid. This is what the entry point expects and
	 * in those two cases, an outer contract is obviously not called.
	 * - a uint48 validUntil: uint48(validationData >> 160)
	 * A Paymaster signature can be signed at time "x" but delayed intentionally
	 * until time "y" when a fee payment's price has dropped significantly or
	 * some other issue. validUntil sets a time validity for the signature
     * - a uint48 validAfter: uint48(validationData >> (48 + 160))
	 * If the signature should be valid only after a period of time,
	 * we tweak the validAfter property.
	 * For more information, check EntryPoint -> _getValidationData()
	 */
	function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32, uint256)
		external
		view
		returns (bytes memory context, uint256 validationData)
	{
		(uint48 validUntil, uint48 validAfter, bytes memory signature) = abi.decode(
			userOp.paymasterAndData[UserOpHelper.PAYMASTER_DATA_OFFSET:],
			(uint48, uint48, bytes)
		);

		bytes memory callData = userOp.callData;
		bytes32 hash = keccak256(abi.encode(
			block.chainid,
			address(this),
			// entry point
			msg.sender,
			validUntil,
			validAfter,
			// everything except paymasterAndData and signature
			userOp.sender,
			// for the nonce we have an exception case: one-time nonces depend on paymasterAndData, which is generated by the relayer
			// we can't have this as part of the sig cuz we create a cyclical dep
			// the nonce can only be used once, so one cannot replay the gas payment
			callData.length >= 4 && bytes4(userOp.callData[0:4]) == IAmbireAccount.executeMultiple.selector ? 0 : userOp.nonce,
			userOp.initCode,
			callData,
			userOp.accountGasLimits,
			userOp.preVerificationGas,
			userOp.gasFees
		));
		(address recovered, ) = SignatureValidator.recoverAddrAllowUnprotected(hash, signature, true);
		bool isValidSig = recovered == relayer;
		// see _packValidationData: https://github.com/eth-infinitism/account-abstraction/blob/f2b09e60a92d5b3177c68d9f382912ccac19e8db/contracts/core/Helpers.sol#L73-L80
		return ("", uint160(isValidSig ? 0 : 1) | (uint256(validUntil) << 160) | (uint256(validAfter) << 208));
	}

	/**
	 * @notice  No-op, won't be used because we don't return a context
	 * @param   mode  .
	 * @param   context  .
	 * @param   actualGasCost  .
	 */
	function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) external {
		// No-op, won't be used because we don't return a context
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import './libs/Transaction.sol';

/**
 * @title   ExternalSigValidator
 * @notice  A way to add custom recovery to AmbireAccount.
 * address accountAddr is the Ambire account address
 * bytes calldata data is all the data needed by the ExternalSigValidator.
 * It could be anything and it's validator specific.
 * bytes calldata sig is the signature we're validating. Notice its not
 * bytes32 so there could be cases where its not only the signature. It's
 * validator specific
 * uint256 nonce - the Ambire account nonce
 * Transaction[] calldata calls - the txns that are going to be executed
 * if the validation is successful
 * @dev     Not all passed properties necessarily need to be used.
 */
abstract contract ExternalSigValidator {
	function validateSig(
		bytes calldata data,
		bytes calldata sig,
		Transaction[] calldata calls
	) external virtual returns (bool isValidSignature, uint256 timestampValidAfter);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.7;

import '../libs/Transaction.sol';

interface IAmbireAccount {
	function privileges(address addr) external returns (bytes32);
	function nonce() external returns (uint);

	struct RecoveryInfo {
		address[] keys;
		uint timelock;
	}
	struct ExecuteArgs {
		Transaction[] calls;
		bytes signature;
	}

	function setAddrPrivilege(address addr, bytes32 priv) external payable;
	function tryCatch(address to, uint value, bytes calldata data) external payable;
	function tryCatchLimit(address to, uint value, bytes calldata data, uint gasLimit) external payable;

	function execute(Transaction[] calldata txns, bytes calldata signature) external payable;
	function executeBySender(Transaction[] calldata txns) external payable;
	function executeBySelf(Transaction[] calldata txns) external payable;
	function executeMultiple(ExecuteArgs[] calldata toExec) external payable;

	// EIP 1271 implementation
	// see https://eips.ethereum.org/EIPS/eip-1271
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4);
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Bytes {
	function trimToSize(bytes memory b, uint256 newLen) internal pure {
		require(b.length > newLen, 'BytesLib: only shrinking');
		assembly {
			mstore(b, newLen)
		}
	}

	/***********************************|
	|        Read Bytes Functions       |
	|__________________________________*/

	/**
	 * @dev Reads a bytes32 value from a position in a byte array.
	 * @param b Byte array containing a bytes32 value.
	 * @param index Index in byte array of bytes32 value.
	 * @return result bytes32 value from byte array.
	 */
	function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
		// Arrays are prefixed by a 256 bit length parameter
		index += 32;

		require(b.length >= index, 'BytesLib: length');

		// Read the bytes32 from array memory
		assembly {
			result := mload(add(b, index))
		}
		return result;
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import './Bytes.sol';

interface IERC1271Wallet {
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

library SignatureValidator {
	using Bytes for bytes;

	enum SignatureMode {
		// the first mode Unprotected is used in combination with EIP-1271 signature verification to do
		// EIP-712 verifications, as well as "Ethereum signed message:" message verifications
		// The caveat with this is that we need to ensure that the signer key used for it isn't reused, or the message body
		// itself contains context about the wallet (such as it's address)
		// We do this, rather than applying the prefix on-chain, because if we do you won't be able to see the message
		// when signing on a hardware wallet (you'll only see the hash) - since `isValidSignature` can only receive the hash -
		// if the prefix is applied on-chain you can never match it - it's hash(prefix+hash(msg)) vs hash(prefix+msg)
		// As for transactions (`execute()`), those can be signed with any of the modes
		// Otherwise, if it's reused, we MUST use `Standard` mode which always wraps the final digest hash, but unfortnately this means
		// you can't preview the full message when signing on a HW wallet
		Unprotected,
		Standard,
		SmartWallet,
		Spoof,
		Schnorr,
		Multisig,
		// WARNING: Signature modes should not be more than 26 as the "v"
		// value for standard ecrecover is 27/28
		// WARNING: must always be last
		LastUnused
	}

	// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
	bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;
	// secp256k1 group order
	uint256 internal constant Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

	function splitSignature(bytes memory sig) internal pure returns (bytes memory, uint8) {
		uint8 modeRaw;
		unchecked {
			modeRaw = uint8(sig[sig.length - 1]);
		}
		sig.trimToSize(sig.length - 1);
		return (sig, modeRaw);
	}

	function recoverAddr(bytes32 hash, bytes memory sig, bool allowSpoofing) internal view returns (address) {
		(address recovered, bool usedUnprotected) = recoverAddrAllowUnprotected(hash, sig, allowSpoofing);
		require(!usedUnprotected, 'SV_USED_UNBOUND');
		return recovered;
	}

	function recoverAddrAllowUnprotected(bytes32 hash, bytes memory sig, bool allowSpoofing) internal view returns (address, bool) {
		require(sig.length != 0, 'SV_SIGLEN');

		uint8 modeRaw;
		unchecked {
			modeRaw = uint8(sig[sig.length - 1]);
		}
		// Ensure we're in bounds for mode; Solidity does this as well but it will just silently blow up rather than showing a decent error
		if (modeRaw >= uint8(SignatureMode.LastUnused)) {
			if (sig.length == 65) modeRaw = uint8(SignatureMode.Unprotected);
			else revert('SV_SIGMODE');
		}
		SignatureMode mode = SignatureMode(modeRaw);

		// the address of the key we are gonna be returning
		address signerKey;

		// wrap in the EIP712 wrapping if it's not unbound
		// multisig gets an exception because each inner sig will have to apply this logic
		// @TODO should spoofing be removed from this?
		bool isUnprotected = mode == SignatureMode.Unprotected || mode == SignatureMode.Multisig;
		if (!isUnprotected) {
			bytes32 DOMAIN_SEPARATOR = keccak256(abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)'),
				keccak256(bytes('Ambire')),
				keccak256(bytes('1')),
				block.chainid,
				address(this),
				bytes32(0)
			));
			hash = keccak256(abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR,
				keccak256(abi.encode(
					keccak256(bytes('AmbireOperation(address account,bytes32 hash)')),
					address(this),
					hash
				))
			));
		}

		// {r}{s}{v}{mode}
		if (mode == SignatureMode.Unprotected || mode == SignatureMode.Standard) {
			require(sig.length == 65 || sig.length == 66, 'SV_LEN');
			bytes32 r = sig.readBytes32(0);
			bytes32 s = sig.readBytes32(32);
			uint8 v = uint8(sig[64]);
			signerKey = ecrecover(hash, v, r, s);
		// {sig}{verifier}{mode}
		} else if (mode == SignatureMode.Schnorr) {
			// Based on https://hackmd.io/@nZ-twauPRISEa6G9zg3XRw/SyjJzSLt9
			// You can use this library to produce signatures: https://github.com/borislav-itskov/schnorrkel.js
			// px := public key x-coord
			// e := schnorr signature challenge
			// s := schnorr signature
			// parity := public key y-coord parity (27 or 28)
			// last uint8 is for the Ambire sig mode - it's ignored
			sig.trimToSize(sig.length - 1);
			(bytes32 px, bytes32 e, bytes32 s, uint8 parity) = abi.decode(sig, (bytes32, bytes32, bytes32, uint8));
			// ecrecover = (m, v, r, s);
			bytes32 sp = bytes32(Q - mulmod(uint256(s), uint256(px), Q));
			bytes32 ep = bytes32(Q - mulmod(uint256(e), uint256(px), Q));

			require(sp != bytes32(Q));
			// the ecrecover precompile implementation checks that the `r` and `s`
			// inputs are non-zero (in this case, `px` and `ep`), thus we don't need to
			// check if they're zero.
			address R = ecrecover(sp, parity, px, ep);
			require(R != address(0), 'SV_ZERO_SIG');
			require(e == keccak256(abi.encodePacked(R, uint8(parity), px, hash)), 'SV_SCHNORR_FAILED');
			signerKey = address(uint160(uint256(keccak256(abi.encodePacked('SCHNORR', px)))));
		} else if (mode == SignatureMode.Multisig) {
			sig.trimToSize(sig.length - 1);
			bytes[] memory signatures = abi.decode(sig, (bytes[]));
			// since we're in a multisig, we care if any of the inner sigs are unbound
			isUnprotected = false;
			for (uint256 i = 0; i != signatures.length; i++) {
				(address inner, bool isInnerUnprotected) = recoverAddrAllowUnprotected(hash, signatures[i], false);
				if (isInnerUnprotected) isUnprotected = true;
				signerKey = address(
					uint160(uint256(keccak256(abi.encodePacked(signerKey, inner))))
				);
			}
		} else if (mode == SignatureMode.SmartWallet) {
			// 32 bytes for the addr, 1 byte for the type = 33
			require(sig.length > 33, 'SV_LEN_WALLET');
			uint256 newLen;
			unchecked {
				newLen = sig.length - 33;
			}
			IERC1271Wallet wallet = IERC1271Wallet(address(uint160(uint256(sig.readBytes32(newLen)))));
			sig.trimToSize(newLen);
			require(ERC1271_MAGICVALUE_BYTES32 == wallet.isValidSignature(hash, sig), 'SV_WALLET_INVALID');
			signerKey = address(wallet);
		// {address}{mode}; the spoof mode is used when simulating calls
		} else if (mode == SignatureMode.Spoof && allowSpoofing) {
			// This is safe cause it's specifically intended for spoofing sigs in simulation conditions, where tx.origin can be controlled
			// We did not choose 0x00..00 because in future network upgrades tx.origin may be nerfed or there may be edge cases in which
			// it is zero, such as native account abstraction
			// slither-disable-next-line tx-origin
			require(tx.origin == address(1) || tx.origin == address(6969), 'SV_SPOOF_ORIGIN');
			require(sig.length == 33, 'SV_SPOOF_LEN');
			sig.trimToSize(32);
			// To simulate the gas usage; check is just to silence unused warning
			require(ecrecover(0, 0, 0, 0) != address(6969));
			signerKey = abi.decode(sig, (address));
		} else {
			revert('SV_TYPE');
		}
		require(signerKey != address(0), 'SV_ZERO_SIG');
		return (signerKey, isUnprotected);
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

// Transaction structure
// we handle replay protection separately by requiring (address(this), chainID, nonce) as part of the sig
// @dev a better name for this would be `Call`, but we are keeping `Transaction` for backwards compatibility
struct Transaction {
    address to;
    uint256 value;
    bytes data;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./PackedUserOperation.sol";

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
    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
    external returns (bytes memory context, uint256 validationData);

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

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
  // callGasLimit + verificationGasLimit
  bytes32 accountGasLimits;
  uint256 preVerificationGas;
  // maxFeePerGas + maxPriorityFeePerGas
  bytes32 gasFees;
  bytes paymasterAndData;
  bytes signature;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library UserOpHelper {
	uint256 public constant PAYMASTER_ADDR_OFFSET = 20;

  // 52 = 20 address + 16 paymasterVerificationGasLimit + 16 paymasterPostOpGasLimit
	uint256 public constant PAYMASTER_DATA_OFFSET = 52;
}