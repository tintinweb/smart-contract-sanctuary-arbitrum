pragma solidity ^0.8.23;

import "./EntryPointSimulations.sol";
import "account-abstraction/utils/Exec.sol";

contract PimlicoEntryPointSimulations {
    EntryPointSimulations internal eps = new EntryPointSimulations();

    uint256 private constant REVERT_REASON_MAX_LEN =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bytes4 private constant selector =
        bytes4(keccak256("delegateAndRevert(address,bytes)"));

    constructor() {}

    function simulateEntryPoint(
        address payable ep,
        bytes[] memory data
    ) public returns (bytes[] memory) {
        bytes[] memory returnDataArray = new bytes[](data.length);

        for (uint i = 0; i < data.length; i++) {
            bytes memory returnData;
            bytes memory callData = abi.encodeWithSelector(
                selector,
                address(eps),
                data[i]
            );
            bool success = Exec.call(ep, 0, callData, gasleft());
            if (!success) {
                returnData = Exec.getReturnData(REVERT_REASON_MAX_LEN);
            }
            returnDataArray[i] = returnData;
        }

        return returnDataArray;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */

import "./EntryPoint.sol";
import "./IEntryPointSimulations.sol";

/*
 * This contract inherits the EntryPoint and extends it with the view-only methods that are executed by
 * the bundler in order to check UserOperation validity and estimate its gas consumption.
 * This contract should never be deployed on-chain and is only used as a parameter for the "eth_call" request.
 */
contract EntryPointSimulations is EntryPoint, IEntryPointSimulations {
    // solhint-disable-next-line var-name-mixedcase
    AggregatorStakeInfo private NOT_AGGREGATED =
        AggregatorStakeInfo(address(0), StakeInfo(0, 0));

    SenderCreator private _senderCreator;

    function initSenderCreator() internal virtual {
        //this is the address of the first contract created with CREATE by this address.
        address createdObj = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"d694", address(this), hex"01")
                    )
                )
            )
        );
        _senderCreator = SenderCreator(createdObj);
    }

    function senderCreator()
        internal
        view
        virtual
        override
        returns (SenderCreator)
    {
        // return the same senderCreator as real EntryPoint.
        // this call is slightly (100) more expensive than EntryPoint's access to immutable member
        return _senderCreator;
    }

    /**
     * simulation contract should not be deployed, and specifically, accounts should not trust
     * it as entrypoint, since the simulation functions don't check the signatures
     */
    constructor() {
        // require(block.number < 100, "should not be deployed");
    }

    /// @inheritdoc IEntryPointSimulations
    function simulateValidation(
        PackedUserOperation calldata userOp
    ) external returns (ValidationResult memory) {
        UserOpInfo memory outOpInfo;

        _simulationOnlyValidations(userOp);
        (
            uint256 validationData,
            uint256 paymasterValidationData,
            uint256 paymasterVerificationGasLimit
        ) = _validatePrepayment(0, userOp, outOpInfo);

        _validateAccountAndPaymasterValidationData(
            0,
            validationData,
            paymasterValidationData,
            address(0)
        );

        StakeInfo memory paymasterInfo = _getStakeInfo(
            outOpInfo.mUserOp.paymaster
        );
        StakeInfo memory senderInfo = _getStakeInfo(outOpInfo.mUserOp.sender);
        StakeInfo memory factoryInfo;
        {
            bytes calldata initCode = userOp.initCode;
            address factory = initCode.length >= 20
                ? address(bytes20(initCode[0:20]))
                : address(0);
            factoryInfo = _getStakeInfo(factory);
        }

        address aggregator = address(uint160(validationData));
        ReturnInfo memory returnInfo = ReturnInfo(
            outOpInfo.preOpGas,
            outOpInfo.prefund,
            validationData,
            paymasterValidationData,
            getMemoryBytesFromOffset(outOpInfo.contextOffset)
        );

        AggregatorStakeInfo memory aggregatorInfo = NOT_AGGREGATED;
        if (
            uint160(aggregator) != SIG_VALIDATION_SUCCESS &&
            uint160(aggregator) != SIG_VALIDATION_FAILED
        ) {
            aggregatorInfo = AggregatorStakeInfo(
                aggregator,
                _getStakeInfo(aggregator)
            );
        }
        return
            ValidationResult(
                returnInfo,
                senderInfo,
                factoryInfo,
                paymasterInfo,
                aggregatorInfo
            );
    }

    function simulateCallData(
        PackedUserOperation calldata op,
        address target,
        bytes calldata targetCallData
    ) external returns (TargetCallResult memory) {
        UserOpInfo memory opInfo;
        _simulationOnlyValidations(op);
        _validatePrepayment(0, op, opInfo);

        bool targetSuccess;
        bytes memory targetResult;
        uint256 usedGas;
        if (target != address(0)) {
            uint256 remainingGas = gasleft();
            (targetSuccess, targetResult) = target.call(targetCallData);
            usedGas = remainingGas - gasleft();
        }
        return TargetCallResult(usedGas, targetSuccess, targetResult);
    }

    /// @inheritdoc IEntryPointSimulations
    function simulateHandleOp(
        PackedUserOperation calldata op
    ) external nonReentrant returns (ExecutionResult memory) {
        UserOpInfo memory opInfo;
        _simulationOnlyValidations(op);
        (
            uint256 validationData,
            uint256 paymasterValidationData,
            uint256 paymasterVerificationGasLimit
        ) = _validatePrepayment(0, op, opInfo);

        (uint256 paid, uint256 paymasterPostOpGasLimit) = _executeUserOp(
            op,
            opInfo
        );

        return
            ExecutionResult(
                opInfo.preOpGas,
                paid,
                validationData,
                paymasterValidationData,
                paymasterVerificationGasLimit,
                paymasterPostOpGasLimit,
                false,
                "0x"
            );
    }

    function _simulationOnlyValidations(
        PackedUserOperation calldata userOp
    ) internal {
        //initialize senderCreator(). we can't rely on constructor
        initSenderCreator();

        string memory revertReason = _validateSenderAndPaymaster(
            userOp.initCode,
            userOp.sender,
            userOp.paymasterAndData
        );
        // solhint-disable-next-line no-empty-blocks
        if (bytes(revertReason).length != 0) {
            revert FailedOp(0, revertReason);
        }
    }

    /**
     * Called only during simulation.
     * This function always reverts to prevent warm/cold storage differentiation in simulation vs execution.
     * @param initCode         - The smart account constructor code.
     * @param sender           - The sender address.
     * @param paymasterAndData - The paymaster address (followed by other params, ignored by this method)
     */
    function _validateSenderAndPaymaster(
        bytes calldata initCode,
        address sender,
        bytes calldata paymasterAndData
    ) internal view returns (string memory) {
        if (initCode.length == 0 && sender.code.length == 0) {
            // it would revert anyway. but give a meaningful message
            return ("AA20 account not deployed");
        }
        if (paymasterAndData.length >= 20) {
            address paymaster = address(bytes20(paymasterAndData[0:20]));
            if (paymaster.code.length == 0) {
                // It would revert anyway. but give a meaningful message.
                return ("AA30 paymaster not deployed");
            }
        }
        // always revert
        return ("");
    }

    //make sure depositTo cost is more than normal EntryPoint's cost,
    // to mitigate DoS vector on the bundler
    // empiric test showed that without this wrapper, simulation depositTo costs less..
    function depositTo(
        address account
    ) public payable override(IStakeManager, StakeManager) {
        unchecked {
            // silly code, to waste some gas to make sure depositTo is always little more
            // expensive than on-chain call
            uint256 x = 1;
            while (x < 5) {
                x++;
            }
            StakeManager.depositTo(account);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.23;

// solhint-disable no-inline-assembly

/**
 * Utility functions helpful when making different kinds of contract calls in Solidity.
 */
library Exec {

    function call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly ("memory-safe") {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function staticcall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bool success) {
        assembly ("memory-safe") {
            success := staticcall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function delegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly ("memory-safe") {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    // get returned data from last call or calldelegate
    function getReturnData(uint256 maxLen) internal pure returns (bytes memory returnData) {
        assembly ("memory-safe") {
            let len := returndatasize()
            if gt(len, maxLen) {
                len := maxLen
            }
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(len, 0x20)))
            mstore(ptr, len)
            returndatacopy(add(ptr, 0x20), 0, len)
            returnData := ptr
        }
    }

    // revert with explicit byte array (probably reverted info from call)
    function revertWithData(bytes memory returnData) internal pure {
        assembly ("memory-safe") {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    function callAndRevert(address to, bytes memory data, uint256 maxLen) internal {
        bool success = call(to,0,data,gasleft());
        if (!success) {
            revertWithData(getReturnData(maxLen));
        }
    }
}

pragma solidity ^0.8.23;
/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */

import "account-abstraction/interfaces/IAccount.sol";
import "account-abstraction/interfaces/IAccountExecute.sol";
import "account-abstraction/interfaces/IPaymaster.sol";
import "./IEntryPoint.sol";

import "account-abstraction/utils/Exec.sol";
import "account-abstraction/core/StakeManager.sol";
import "account-abstraction/core/SenderCreator.sol";
import "account-abstraction/core/Helpers.sol";
import "account-abstraction/core/NonceManager.sol";
import "account-abstraction/core/UserOperationLib.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/*
 * Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 * Only one instance required on each chain.
 */

/// @custom:security-contact https://bounty.ethereum.org
contract EntryPoint is IEntryPoint, StakeManager, NonceManager, ReentrancyGuard {
    // ERC165

    using UserOperationLib for PackedUserOperation;

    SenderCreator private immutable _senderCreator = new SenderCreator();

    function senderCreator() internal view virtual returns (SenderCreator) {
        return _senderCreator;
    }

    //compensate for innerHandleOps' emit message and deposit refund.
    // allow some slack for future gas price changes.
    uint256 private constant INNER_GAS_OVERHEAD = 10000;

    // Marker for inner call revert on out of gas
    bytes32 private constant INNER_OUT_OF_GAS = hex"deaddead";
    bytes32 private constant INNER_REVERT_LOW_PREFUND = hex"deadaa51";

    uint256 private constant REVERT_REASON_MAX_LEN = 2048;
    uint256 private constant PENALTY_PERCENT = 10;

    /// @inheritdoc IERC165
    // function supportsInterface(
    //     bytes4 interfaceId
    // ) public view virtual override returns (bool) {
    //     // note: solidity "type(IEntryPoint).interfaceId" is without inherited methods but we want to check everything
    //     return
    //         interfaceId ==
    //         (type(IEntryPoint).interfaceId ^
    //             type(IStakeManager).interfaceId ^
    //             type(INonceManager).interfaceId) ||
    //         interfaceId == type(IEntryPoint).interfaceId ||
    //         interfaceId == type(IStakeManager).interfaceId ||
    //         interfaceId == type(INonceManager).interfaceId ||
    //         super.supportsInterface(interfaceId);
    // }

    /**
     * Compensate the caller's beneficiary address with the collected fees of all UserOperations.
     * @param beneficiary - The address to receive the fees.
     * @param amount      - Amount to transfer.
     */
    function _compensate(address payable beneficiary, uint256 amount) internal {
        require(beneficiary != address(0), "AA90 invalid beneficiary");
        (bool success,) = beneficiary.call{value: amount}("");
        require(success, "AA91 failed send to beneficiary");
    }

    /**
     * Execute a user operation.
     * @param userOp     - The userOp to execute.
     * @param opInfo     - The opInfo filled by validatePrepayment for this userOp.
     * @return collected - The total amount this userOp paid.
     */
    function _executeUserOp(PackedUserOperation calldata userOp, UserOpInfo memory opInfo)
        internal
        returns (uint256 collected, uint256 paymasterPostOpGasLimit)
    {
        uint256 preGas = gasleft();
        bytes memory context = getMemoryBytesFromOffset(opInfo.contextOffset);
        {
            uint256 saveFreePtr;
            assembly ("memory-safe") {
                saveFreePtr := mload(0x40)
            }
            bytes calldata callData = userOp.callData;
            bytes4 methodSig;
            assembly {
                let len := callData.length
                if gt(len, 3) { methodSig := calldataload(callData.offset) }
            }
            if (methodSig == IAccountExecute.executeUserOp.selector) {
                bytes memory executeUserOp = abi.encodeCall(IAccountExecute.executeUserOp, (userOp, opInfo.userOpHash));
                (collected, paymasterPostOpGasLimit) = innerHandleOp(executeUserOp, opInfo, context, preGas);
            } else {
                (collected, paymasterPostOpGasLimit) = innerHandleOp(callData, opInfo, context, preGas);
            }
        }
    }

    function emitUserOperationEvent(UserOpInfo memory opInfo, bool success, uint256 actualGasCost, uint256 actualGas)
        internal
        virtual
    {
        emit UserOperationEvent(
            opInfo.userOpHash,
            opInfo.mUserOp.sender,
            opInfo.mUserOp.paymaster,
            opInfo.mUserOp.nonce,
            success,
            actualGasCost,
            actualGas
        );
    }

    function emitPrefundTooLow(UserOpInfo memory opInfo) internal virtual {
        emit UserOperationPrefundTooLow(opInfo.userOpHash, opInfo.mUserOp.sender, opInfo.mUserOp.nonce);
    }

    /// @inheritdoc IEntryPoint
    // function handleOps(
    //     PackedUserOperation[] calldata ops,
    //     address payable beneficiary
    // ) public nonReentrant {
    //     uint256 opslen = ops.length;
    //     UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);
    //
    //     unchecked {
    //         for (uint256 i = 0; i < opslen; i++) {
    //             UserOpInfo memory opInfo = opInfos[i];
    //             (
    //                 uint256 validationData,
    //                 uint256 pmValidationData,
    //                 uint256 paymasterVerificationGasLimit
    //             ) = _validatePrepayment(i, ops[i], opInfo);
    //             _validateAccountAndPaymasterValidationData(
    //                 i,
    //                 validationData,
    //                 pmValidationData,
    //                 address(0)
    //             );
    //         }
    //
    //         uint256 collected = 0;
    //         emit BeforeExecution();
    //
    //         for (uint256 i = 0; i < opslen; i++) {
    //             (
    //                 uint256 collectedAmount,
    //                 uint256 paymasterVerificationGasLimit
    //             ) = _executeUserOp(i, ops[i], opInfos[i]);
    //             collected += collectedAmount;
    //         }
    //
    //         _compensate(beneficiary, collected);
    //     }
    // }

    /// @inheritdoc IEntryPoint
    // function handleAggregatedOps(
    //     UserOpsPerAggregator[] calldata opsPerAggregator,
    //     address payable beneficiary
    // ) public nonReentrant {
    //     uint256 opasLen = opsPerAggregator.length;
    //     uint256 totalOps = 0;
    //     for (uint256 i = 0; i < opasLen; i++) {
    //         UserOpsPerAggregator calldata opa = opsPerAggregator[i];
    //         PackedUserOperation[] calldata ops = opa.userOps;
    //         IAggregator aggregator = opa.aggregator;
    //
    //         //address(1) is special marker of "signature error"
    //         require(
    //             address(aggregator) != address(1),
    //             "AA96 invalid aggregator"
    //         );
    //
    //         if (address(aggregator) != address(0)) {
    //             // solhint-disable-next-line no-empty-blocks
    //             try aggregator.validateSignatures(ops, opa.signature) {} catch {
    //                 revert SignatureValidationFailed(address(aggregator));
    //             }
    //         }
    //
    //         totalOps += ops.length;
    //     }
    //
    //     UserOpInfo[] memory opInfos = new UserOpInfo[](totalOps);
    //
    //     uint256 opIndex = 0;
    //     for (uint256 a = 0; a < opasLen; a++) {
    //         UserOpsPerAggregator calldata opa = opsPerAggregator[a];
    //         PackedUserOperation[] calldata ops = opa.userOps;
    //         IAggregator aggregator = opa.aggregator;
    //
    //         uint256 opslen = ops.length;
    //         for (uint256 i = 0; i < opslen; i++) {
    //             UserOpInfo memory opInfo = opInfos[opIndex];
    //             (
    //                 uint256 validationData,
    //                 uint256 paymasterValidationData,
    //                 uint256 paymasterVerificationGasLimit
    //             ) = _validatePrepayment(opIndex, ops[i], opInfo);
    //             _validateAccountAndPaymasterValidationData(
    //                 i,
    //                 validationData,
    //                 paymasterValidationData,
    //                 address(aggregator)
    //             );
    //             opIndex++;
    //         }
    //     }
    //
    //     emit BeforeExecution();
    //
    //     uint256 collected = 0;
    //     opIndex = 0;
    //     for (uint256 a = 0; a < opasLen; a++) {
    //         UserOpsPerAggregator calldata opa = opsPerAggregator[a];
    //         emit SignatureAggregatorChanged(address(opa.aggregator));
    //         PackedUserOperation[] calldata ops = opa.userOps;
    //         uint256 opslen = ops.length;
    //
    //         for (uint256 i = 0; i < opslen; i++) {
    //             (
    //                 uint256 collectedAmount,
    //                 uint256 paymasterVerificationGasLimit
    //             ) = _executeUserOp(i, ops[i], opInfos[i]);
    //             collected += collectedAmount;
    //
    //             opIndex++;
    //         }
    //     }
    //     emit SignatureAggregatorChanged(address(0));
    //
    //     _compensate(beneficiary, collected);
    // }

    /**
     * A memory copy of UserOp static fields only.
     * Excluding: callData, initCode and signature. Replacing paymasterAndData with paymaster.
     */
    struct MemoryUserOp {
        address sender;
        uint256 nonce;
        uint256 verificationGasLimit;
        uint256 callGasLimit;
        uint256 paymasterVerificationGasLimit;
        uint256 paymasterPostOpGasLimit;
        uint256 preVerificationGas;
        address paymaster;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
    }

    struct UserOpInfo {
        MemoryUserOp mUserOp;
        bytes32 userOpHash;
        uint256 prefund;
        uint256 contextOffset;
        uint256 preOpGas;
    }

    /**
     * Inner function to handle a UserOperation.
     * Must be declared "external" to open a call context, but it can only be called by handleOps.
     * @param callData - The callData to execute.
     * @param opInfo   - The UserOpInfo struct.
     * @param context  - The context bytes.
     * @return actualGasCost - the actual cost in eth this UserOperation paid for gas
     */
    function innerHandleOp(bytes memory callData, UserOpInfo memory opInfo, bytes memory context, uint256 preGas)
        public
        returns (uint256 actualGasCost, uint256 paymasterPostOpGasLimit)
    {
        MemoryUserOp memory mUserOp = opInfo.mUserOp;

        uint256 callGasLimit = mUserOp.callGasLimit;
        //unchecked {
        //    // handleOps was called with gas limit too low. abort entire bundle.
        //    if (
        //        (gasleft() * 63) / 64 <
        //        callGasLimit +
        //            mUserOp.paymasterPostOpGasLimit +
        //            INNER_GAS_OVERHEAD
        //    ) {
        //        revert FailedOp(0, "AA95 out of gas");
        //    }
        //}

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (callData.length > 0) {
            bool success = Exec.call(mUserOp.sender, 0, callData, callGasLimit);
            if (!success) {
                bytes memory result = Exec.getReturnData(REVERT_REASON_MAX_LEN);
                if (result.length > 0) {
                    emit UserOperationRevertReason(opInfo.userOpHash, mUserOp.sender, mUserOp.nonce, result);
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

        unchecked {
            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            return _postExecution(mode, opInfo, context, actualGas);
        }
    }

    /// @inheritdoc IEntryPoint
    function getUserOpHash(PackedUserOperation calldata userOp) public view returns (bytes32) {
        return keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /**
     * Copy general fields from userOp into the memory opInfo structure.
     * @param userOp  - The user operation.
     * @param mUserOp - The memory user operation.
     */
    function _copyUserOpToMemory(PackedUserOperation calldata userOp, MemoryUserOp memory mUserOp) internal pure {
        mUserOp.sender = userOp.sender;
        mUserOp.nonce = userOp.nonce;
        (mUserOp.verificationGasLimit, mUserOp.callGasLimit) = UserOperationLib.unpackUints(userOp.accountGasLimits);
        mUserOp.preVerificationGas = userOp.preVerificationGas;
        (mUserOp.maxPriorityFeePerGas, mUserOp.maxFeePerGas) = UserOperationLib.unpackUints(userOp.gasFees);
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        if (paymasterAndData.length > 0) {
            require(paymasterAndData.length >= UserOperationLib.PAYMASTER_DATA_OFFSET, "AA93 invalid paymasterAndData");
            (mUserOp.paymaster, mUserOp.paymasterVerificationGasLimit, mUserOp.paymasterPostOpGasLimit) =
                UserOperationLib.unpackPaymasterStaticFields(paymasterAndData);
        } else {
            mUserOp.paymaster = address(0);
            mUserOp.paymasterVerificationGasLimit = 0;
            mUserOp.paymasterPostOpGasLimit = 0;
        }
    }

    /**
     * Get the required prefunded gas fee amount for an operation.
     * @param mUserOp - The user operation in memory.
     */
    function _getRequiredPrefund(MemoryUserOp memory mUserOp) internal pure returns (uint256 requiredPrefund) {
        unchecked {
            uint256 requiredGas = mUserOp.verificationGasLimit + mUserOp.callGasLimit
                + mUserOp.paymasterVerificationGasLimit + mUserOp.paymasterPostOpGasLimit + mUserOp.preVerificationGas;

            requiredPrefund = requiredGas * mUserOp.maxFeePerGas;
        }
    }

    /**
     * Create sender smart contract account if init code is provided.
     * @param opIndex  - The operation index.
     * @param opInfo   - The operation info.
     * @param initCode - The init code for the smart contract account.
     */
    function _createSenderIfNeeded(uint256 opIndex, UserOpInfo memory opInfo, bytes calldata initCode) internal {
        if (initCode.length != 0) {
            address sender = opInfo.mUserOp.sender;
            if (sender.code.length != 0) {
                revert FailedOp(opIndex, "AA10 sender already constructed");
            }
            address sender1 = senderCreator().createSender{gas: opInfo.mUserOp.verificationGasLimit}(initCode);
            if (sender1 == address(0)) {
                revert FailedOp(opIndex, "AA13 initCode failed or OOG");
            }
            if (sender1 != sender) {
                revert FailedOp(opIndex, "AA14 initCode must return sender");
            }
            if (sender1.code.length == 0) {
                revert FailedOp(opIndex, "AA15 initCode must create sender");
            }
            address factory = address(bytes20(initCode[0:20]));
            emit AccountDeployed(opInfo.userOpHash, sender, factory, opInfo.mUserOp.paymaster);
        }
    }

    /// @inheritdoc IEntryPoint
    // function getSenderAddress(bytes calldata initCode) public {
    //     address sender = senderCreator().createSender(initCode);
    //     revert SenderAddressResult(sender);
    // }

    /**
     * Call account.validateUserOp.
     * Revert (with FailedOp) in case validateUserOp reverts, or account didn't send required prefund.
     * Decrement account's deposit if needed.
     * @param opIndex         - The operation index.
     * @param op              - The user operation.
     * @param opInfo          - The operation info.
     * @param requiredPrefund - The required prefund amount.
     */
    function _validateAccountPrepayment(
        uint256 opIndex,
        PackedUserOperation calldata op,
        UserOpInfo memory opInfo,
        uint256 requiredPrefund,
        uint256 verificationGasLimit
    ) internal returns (uint256 validationData) {
        unchecked {
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            address sender = mUserOp.sender;
            _createSenderIfNeeded(opIndex, opInfo, op.initCode);
            address paymaster = mUserOp.paymaster;
            uint256 missingAccountFunds = 0;
            if (paymaster == address(0)) {
                uint256 bal = balanceOf(sender);
                missingAccountFunds = bal > requiredPrefund ? 0 : requiredPrefund - bal;
            }
            try IAccount(sender).validateUserOp{gas: verificationGasLimit}(op, opInfo.userOpHash, missingAccountFunds)
            returns (uint256 _validationData) {
                validationData = _validationData;
            } catch {
                revert FailedOpWithRevert(opIndex, "AA23 reverted", Exec.getReturnData(REVERT_REASON_MAX_LEN));
            }
            if (paymaster == address(0)) {
                DepositInfo storage senderInfo = deposits[sender];
                uint256 deposit = senderInfo.deposit;
                if (requiredPrefund > deposit) {
                    revert FailedOp(opIndex, "AA21 didn't pay prefund");
                }
                senderInfo.deposit = deposit - requiredPrefund;
            }
        }
    }

    /**
     * In case the request has a paymaster:
     *  - Validate paymaster has enough deposit.
     *  - Call paymaster.validatePaymasterUserOp.
     *  - Revert with proper FailedOp in case paymaster reverts.
     *  - Decrement paymaster's deposit.
     * @param opIndex                            - The operation index.
     * @param op                                 - The user operation.
     * @param opInfo                             - The operation info.
     * @param requiredPreFund                    - The required prefund amount.
     */
    function _validatePaymasterPrepayment(
        uint256 opIndex,
        PackedUserOperation calldata op,
        UserOpInfo memory opInfo,
        uint256 requiredPreFund
    ) internal returns (bytes memory context, uint256 validationData) {
        unchecked {
            uint256 preGas = gasleft();
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            address paymaster = mUserOp.paymaster;
            DepositInfo storage paymasterInfo = deposits[paymaster];
            uint256 deposit = paymasterInfo.deposit;
            if (deposit < requiredPreFund) {
                revert FailedOp(opIndex, "AA31 paymaster deposit too low");
            }
            paymasterInfo.deposit = deposit - requiredPreFund;
            uint256 pmVerificationGasLimit = mUserOp.paymasterVerificationGasLimit;
            try IPaymaster(paymaster).validatePaymasterUserOp{gas: pmVerificationGasLimit}(
                op, opInfo.userOpHash, requiredPreFund
            ) returns (bytes memory _context, uint256 _validationData) {
                context = _context;
                validationData = _validationData;
            } catch {
                revert FailedOpWithRevert(opIndex, "AA33 reverted", Exec.getReturnData(REVERT_REASON_MAX_LEN));
            }
            if (preGas - gasleft() > pmVerificationGasLimit) {
                revert FailedOp(opIndex, "AA36 over paymasterVerificationGasLimit");
            }
        }
    }

    /**
     * Revert if either account validationData or paymaster validationData is expired.
     * @param opIndex                 - The operation index.
     * @param validationData          - The account validationData.
     * @param paymasterValidationData - The paymaster validationData.
     * @param expectedAggregator      - The expected aggregator.
     */
    function _validateAccountAndPaymasterValidationData(
        uint256 opIndex,
        uint256 validationData,
        uint256 paymasterValidationData,
        address expectedAggregator
    ) internal view {
        (address aggregator, bool outOfTimeRange) = _getValidationData(validationData);
        if (expectedAggregator != aggregator) {
            revert FailedOp(opIndex, "AA24 signature error");
        }
        if (outOfTimeRange) {
            revert FailedOp(opIndex, "AA22 expired or not due");
        }
        // pmAggregator is not a real signature aggregator: we don't have logic to handle it as address.
        // Non-zero address means that the paymaster fails due to some signature check (which is ok only during estimation).
        address pmAggregator;
        (pmAggregator, outOfTimeRange) = _getValidationData(paymasterValidationData);
        if (pmAggregator != address(0)) {
            revert FailedOp(opIndex, "AA34 signature error");
        }
        if (outOfTimeRange) {
            revert FailedOp(opIndex, "AA32 paymaster expired or not due");
        }
    }

    /**
     * Parse validationData into its components.
     * @param validationData - The packed validation data (sigFailed, validAfter, validUntil).
     * @return aggregator the aggregator of the validationData
     * @return outOfTimeRange true if current time is outside the time range of this validationData.
     */
    function _getValidationData(uint256 validationData)
        internal
        view
        returns (address aggregator, bool outOfTimeRange)
    {
        if (validationData == 0) {
            return (address(0), false);
        }
        ValidationData memory data = _parseValidationData(validationData);
        // solhint-disable-next-line not-rely-on-time
        outOfTimeRange = block.timestamp > data.validUntil || block.timestamp < data.validAfter;
        aggregator = data.aggregator;
    }

    /**
     * Validate account and paymaster (if defined) and
     * also make sure total validation doesn't exceed verificationGasLimit.
     * This method is called off-chain (simulateValidation()) and on-chain (from handleOps)
     * @param opIndex - The index of this userOp into the "opInfos" array.
     * @param userOp  - The userOp to validate.
     */
    function _validatePrepayment(uint256 opIndex, PackedUserOperation calldata userOp, UserOpInfo memory outOpInfo)
        internal
        returns (uint256 validationData, uint256 paymasterValidationData, uint256 paymasterVerificationGasLimit)
    {
        uint256 preGas = gasleft();
        MemoryUserOp memory mUserOp = outOpInfo.mUserOp;
        _copyUserOpToMemory(userOp, mUserOp);
        outOpInfo.userOpHash = getUserOpHash(userOp);

        // Validate all numeric values in userOp are well below 128 bit, so they can safely be added
        // and multiplied without causing overflow.
        uint256 verificationGasLimit = mUserOp.verificationGasLimit;
        uint256 maxGasValues = mUserOp.preVerificationGas | verificationGasLimit | mUserOp.callGasLimit
            | mUserOp.paymasterVerificationGasLimit | mUserOp.paymasterPostOpGasLimit | mUserOp.maxFeePerGas
            | mUserOp.maxPriorityFeePerGas;
        require(maxGasValues <= type(uint120).max, "AA94 gas values overflow");

        uint256 requiredPreFund = _getRequiredPrefund(mUserOp);
        validationData = _validateAccountPrepayment(opIndex, userOp, outOpInfo, requiredPreFund, verificationGasLimit);

        if (!_validateAndUpdateNonce(mUserOp.sender, mUserOp.nonce)) {
            revert FailedOp(opIndex, "AA25 invalid account nonce");
        }

        unchecked {
            if (preGas - gasleft() > verificationGasLimit) {
                revert FailedOp(opIndex, "AA26 over verificationGasLimit");
            }
        }

        bytes memory context;
        uint256 remainingGas = gasleft();
        if (mUserOp.paymaster != address(0)) {
            (context, paymasterValidationData) =
                _validatePaymasterPrepayment(opIndex, userOp, outOpInfo, requiredPreFund);
        }
        unchecked {
            outOpInfo.prefund = requiredPreFund;
            outOpInfo.contextOffset = getOffsetOfMemoryBytes(context);
            outOpInfo.preOpGas = preGas - gasleft() + userOp.preVerificationGas;
        }
        paymasterVerificationGasLimit = ((remainingGas - gasleft()) * 115) / 100;
    }

    /**
     * Process post-operation, called just after the callData is executed.
     * If a paymaster is defined and its validation returned a non-empty context, its postOp is called.
     * The excess amount is refunded to the account (or paymaster - if it was used in the request).
     * @param mode      - Whether is called from innerHandleOp, or outside (postOpReverted).
     * @param opInfo    - UserOp fields and info collected during validation.
     * @param context   - The context returned in validatePaymasterUserOp.
     * @param actualGas - The gas used so far by this user operation.
     */
    function _postExecution(
        IPaymaster.PostOpMode mode,
        UserOpInfo memory opInfo,
        bytes memory context,
        uint256 actualGas
    ) private returns (uint256 actualGasCost, uint256 paymasterPostOpGasLimit) {
        uint256 preGas = gasleft();
        unchecked {
            address refundAddress;
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            uint256 gasPrice = getUserOpGasPrice(mUserOp);

            address paymaster = mUserOp.paymaster;
            if (paymaster == address(0)) {
                refundAddress = mUserOp.sender;
            } else {
                refundAddress = paymaster;
                if (context.length > 0) {
                    actualGasCost = actualGas * gasPrice;
                    if (mode != IPaymaster.PostOpMode.postOpReverted) {
                        uint256 remainingGas = gasleft();
                        try IPaymaster(paymaster).postOp{gas: mUserOp.paymasterPostOpGasLimit}(
                            mode, context, actualGasCost, gasPrice
                        ) {
                            // solhint-disable-next-line no-empty-blocks
                        } catch {
                            emit PostOpRevertReason(
                                opInfo.userOpHash,
                                opInfo.mUserOp.sender,
                                opInfo.mUserOp.nonce,
                                Exec.getReturnData(REVERT_REASON_MAX_LEN)
                            );
                            actualGas = preGas - gasleft() + opInfo.preOpGas;
                            (actualGasCost, paymasterPostOpGasLimit) =
                                _postExecution(IPaymaster.PostOpMode.postOpReverted, opInfo, context, actualGas);
                        }
                        paymasterPostOpGasLimit = remainingGas - gasleft();
                    }
                }
            }
            actualGas += preGas - gasleft();

            // Calculating a penalty for unused execution gas
            {
                uint256 executionGasLimit = mUserOp.callGasLimit + mUserOp.paymasterPostOpGasLimit;
                uint256 executionGasUsed = actualGas - opInfo.preOpGas;
                // this check is required for the gas used within EntryPoint and not covered by explicit gas limits
                if (executionGasLimit > executionGasUsed) {
                    uint256 unusedGas = executionGasLimit - executionGasUsed;
                    uint256 unusedGasPenalty = (unusedGas * PENALTY_PERCENT) / 100;
                    actualGas += unusedGasPenalty;
                }
            }

            actualGasCost = actualGas * gasPrice;
            uint256 prefund = opInfo.prefund;
            if (prefund < actualGasCost) {
                if (mode == IPaymaster.PostOpMode.postOpReverted) {
                    actualGasCost = prefund;
                    emitPrefundTooLow(opInfo);
                    emitUserOperationEvent(opInfo, false, actualGasCost, actualGas);
                } else {
                    actualGas = preGas - gasleft() + opInfo.preOpGas;
                    actualGasCost = opInfo.prefund;
                    emitPrefundTooLow(opInfo);
                    emitUserOperationEvent(opInfo, false, actualGasCost, actualGas);
                }
            } else {
                uint256 refund = prefund - actualGasCost;
                _incrementDeposit(refundAddress, refund);
                bool success = mode == IPaymaster.PostOpMode.opSucceeded;
                emitUserOperationEvent(opInfo, success, actualGasCost, actualGas);
            }
        } // unchecked
    }

    /**
     * The gas price this UserOp agrees to pay.
     * Relayer/block builder might submit the TX with higher priorityFee, but the user should not.
     * @param mUserOp - The userOp to get the gas price from.
     */
    function getUserOpGasPrice(MemoryUserOp memory mUserOp) internal view returns (uint256) {
        unchecked {
            uint256 maxFeePerGas = mUserOp.maxFeePerGas;
            uint256 maxPriorityFeePerGas = mUserOp.maxPriorityFeePerGas;
            if (maxFeePerGas == maxPriorityFeePerGas) {
                //legacy mode (for networks that don't support basefee opcode)
                return maxFeePerGas;
            }
            return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    /**
     * The offset of the given bytes in memory.
     * @param data - The bytes to get the offset of.
     */
    function getOffsetOfMemoryBytes(bytes memory data) internal pure returns (uint256 offset) {
        assembly {
            offset := data
        }
    }

    /**
     * The bytes in memory at the given offset.
     * @param offset - The offset to get the bytes from.
     */
    function getMemoryBytesFromOffset(uint256 offset) internal pure returns (bytes memory data) {
        assembly ("memory-safe") {
            data := offset
        }
    }

    /// @inheritdoc IEntryPoint
    // function delegateAndRevert(address target, bytes calldata data) external {
    //     (bool success, bytes memory ret) = target.delegatecall(data);
    //     revert DelegateAndRevert(success, ret);
    // }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "account-abstraction/interfaces/PackedUserOperation.sol";
import "./IEntryPoint.sol";

interface IEntryPointSimulations is IEntryPoint {
    struct TargetCallResult {
        uint256 gasUsed;
        bool success;
        bytes returnData;
    }

    struct PaymasterDataResult {
        uint256 paymasterVerificationGasLimit;
        uint256 paymasterPostOpGasLimit;
    }

    // Return value of simulateHandleOp.
    struct ExecutionResult {
        uint256 preOpGas;
        uint256 paid;
        uint256 accountValidationData;
        uint256 paymasterValidationData;
        uint256 paymasterVerificationGasLimit;
        uint256 paymasterPostOpGasLimit;
        bool targetSuccess;
        bytes targetResult;
    }

    /**
     * Successful result from simulateValidation.
     * If the account returns a signature aggregator the "aggregatorInfo" struct is filled in as well.
     * @param returnInfo     Gas and time-range returned values
     * @param senderInfo     Stake information about the sender
     * @param factoryInfo    Stake information about the factory (if any)
     * @param paymasterInfo  Stake information about the paymaster (if any)
     * @param aggregatorInfo Signature aggregation info (if the account requires signature aggregator)
     *                       Bundler MUST use it to verify the signature, or reject the UserOperation.
     */
    struct ValidationResult {
        ReturnInfo returnInfo;
        StakeInfo senderInfo;
        StakeInfo factoryInfo;
        StakeInfo paymasterInfo;
        AggregatorStakeInfo aggregatorInfo;
    }

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage
     *      outside the account's data.
     * @param userOp - The user operation to validate.
     * @return the validation result structure
     */
    function simulateValidation(
        PackedUserOperation calldata userOp
    ) external returns (ValidationResult memory);

    /**
     * Simulate full execution of a UserOperation (including both validation and target execution)
     * It performs full validation of the UserOperation, but ignores signature error.
     * An optional target address is called after the userop succeeds,
     * and its value is returned (before the entire call is reverted).
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     * @param op The UserOperation to simulate.
     * @return the execution result structure
     */
    function simulateHandleOp(
        PackedUserOperation calldata op
    ) external returns (ExecutionResult memory);
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

import "./PackedUserOperation.sol";

interface IAccountExecute {
    /**
     * Account may implement this execute method.
     * passing this methodSig at the beginning of callData will cause the entryPoint to pass the full UserOp (and hash)
     * to the account.
     * The account should skip the methodSig, and use the callData (and optionally, other UserOp fields)
     *
     * @param userOp              - The operation that was just validated.
     * @param userOpHash          - Hash of the user's request data.
     */
    function executeUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";

/**
 * The interface exposed by a paymaster contract, who agrees to pay the gas for user's operations.
 * A paymaster must hold a stake to cover the required entrypoint stake and also the gas for the transaction.
 */
interface IPaymaster {
    enum PostOpMode {
        // User op succeeded.
        opSucceeded,
        // User op reverted. Still has to pay for gas.
        opReverted,
        // Only used internally in the EntryPoint (cleanup after postOp reverts). Never calling paymaster with this value
        postOpReverted
    }

    /**
     * Payment validation: check if paymaster agrees to pay.
     * Must verify sender is the entryPoint.
     * Revert to reject this request.
     * Note that bundlers will reject this method if it changes the state, unless the paymaster is trusted (whitelisted).
     * The paymaster pre-pays using its deposit, and receive back a refund after the postOp method returns.
     * @param userOp          - The user operation.
     * @param userOpHash      - Hash of the user's request data.
     * @param maxCost         - The maximum cost of this transaction (based on maximum gas and gas price from userOp).
     * @return context        - Value to send to a postOp. Zero length to signify postOp is not required.
     * @return validationData - Signature and time-range of this operation, encoded the same as the return
     *                          value of validateUserOperation.
     *                          <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *                                                    other values are invalid for paymaster.
     *                          <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *                          <6-byte> validAfter - first timestamp this operation is valid
     *                          Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    /**
     * Post-operation handler.
     * Must verify sender is the entryPoint.
     * @param mode          - Enum with the following options:
     *                        opSucceeded - User operation succeeded.
     *                        opReverted  - User op reverted. The paymaster still has to pay for gas.
     *                        postOpReverted - never passed in a call to postOp().
     * @param context       - The context value returned by validatePaymasterUserOp
     * @param actualGasCost - Actual gas used so far (without this postOp call).
     * @param actualUserOpFeePerGas - the gas price this UserOp pays. This value is based on the UserOp's maxFeePerGas
     *                        and maxPriorityFee (and basefee)
     *                        It is not the same as tx.gasprice, which is what the bundler pays.
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external;
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "account-abstraction/interfaces/PackedUserOperation.sol";
import "account-abstraction/interfaces/IStakeManager.sol";
import "account-abstraction/interfaces/IAggregator.sol";
import "account-abstraction/interfaces/INonceManager.sol";

interface IEntryPoint is IStakeManager, INonceManager {
    /***
     * An event emitted after each successful request.
     * @param userOpHash    - Unique identifier for the request (hash its entire content, except signature).
     * @param sender        - The account that generates this request.
     * @param paymaster     - If non-null, the paymaster that pays for this request.
     * @param nonce         - The nonce value from the request.
     * @param success       - True if the sender transaction succeeded, false if reverted.
     * @param actualGasCost - Actual amount paid (by account or paymaster) for this UserOperation.
     * @param actualGasUsed - Total gas used by this UserOperation (including preVerification, creation,
     *                        validation and execution).
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
     * Account "sender" was deployed.
     * @param userOpHash - The userOp that deployed this account. UserOperationEvent will follow.
     * @param sender     - The account that is deployed
     * @param factory    - The factory used to deploy this account (in the initCode)
     * @param paymaster  - The paymaster used by this UserOp
     */
    event AccountDeployed(
        bytes32 indexed userOpHash,
        address indexed sender,
        address factory,
        address paymaster
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce,
        bytes revertReason
    );

    /**
     * An event emitted if the UserOperation Paymaster's "postOp" call reverted with non-zero length.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     * @param revertReason - The return bytes from the (reverted) call to "callData".
     */
    event PostOpRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce,
        bytes revertReason
    );

    /**
     * UserOp consumed more than prefund. The UserOperation is reverted, and no refund is made.
     * @param userOpHash   - The request unique identifier.
     * @param sender       - The sender of this request.
     * @param nonce        - The nonce used in the request.
     */
    event UserOperationPrefundTooLow(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce
    );

    /**
     * An event emitted by handleOps(), before starting the execution loop.
     * Any event emitted before this event, is part of the validation.
     */
    event BeforeExecution();

    /**
     * Signature aggregator used by the following UserOperationEvents within this bundle.
     * @param aggregator - The aggregator used for the following UserOperationEvents.
     */
    event SignatureAggregatorChanged(address indexed aggregator);

    /**
     * A custom revert error of handleOps, to identify the offending op.
     * Should be caught in off-chain handleOps simulation and not happen on-chain.
     * Useful for mitigating DoS attempts against batchers or for troubleshooting of factory/account/paymaster reverts.
     * NOTE: If simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
     * @param reason  - Revert reason. The string starts with a unique code "AAmn",
     *                  where "m" is "1" for factory, "2" for account and "3" for paymaster issues,
     *                  so a failure can be attributed to the correct entity.
     */
    error FailedOp(uint256 opIndex, string reason);

    /**
     * A custom revert error of handleOps, to report a revert by account or paymaster.
     * @param opIndex - Index into the array of ops to the failed one (in simulateValidation, this is always zero).
     * @param reason  - Revert reason. see FailedOp(uint256,string), above
     * @param inner   - data from inner cought revert reason
     * @dev note that inner is truncated to 2048 bytes
     */
    error FailedOpWithRevert(uint256 opIndex, string reason, bytes inner);

    error PostOpReverted(bytes returnData);

    /**
     * Error case when a signature aggregator fails to verify the aggregated signature it had created.
     * @param aggregator The aggregator that failed to verify the signature
     */
    error SignatureValidationFailed(address aggregator);

    // Return value of getSenderAddress.
    error SenderAddressResult(address sender);

    // UserOps handled, per aggregator.
    struct UserOpsPerAggregator {
        PackedUserOperation[] userOps;
        // Aggregator address
        IAggregator aggregator;
        // Aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperations.
     * No signature aggregator is used.
     * If any account requires an aggregator (that is, it returned an aggregator when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops         - The operations to execute.
     * @param beneficiary - The address to receive the fees.
     */
    // function handleOps(
    //     PackedUserOperation[] calldata ops,
    //     address payable beneficiary
    // ) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator - The operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts).
     * @param beneficiary      - The address to receive the fees.
     */
    // function handleAggregatedOps(
    //     UserOpsPerAggregator[] calldata opsPerAggregator,
    //     address payable beneficiary
    // ) external;

    /**
     * Generate a request Id - unique identifier for this request.
     * The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     * @param userOp - The user operation to generate the request ID for.
     * @return hash the hash of this UserOperation
     */
    function getUserOpHash(
        PackedUserOperation calldata userOp
    ) external view returns (bytes32);

    /**
     * Gas and return values during simulation.
     * @param preOpGas         - The gas used for validation (including preValidationGas)
     * @param prefund          - The required prefund for this operation
     * @param accountValidationData   - returned validationData from account.
     * @param paymasterValidationData - return validationData from paymaster.
     * @param paymasterContext - Returned by validatePaymasterUserOp (to be passed into postOp)
     */
    struct ReturnInfo {
        uint256 preOpGas;
        uint256 prefund;
        uint256 accountValidationData;
        uint256 paymasterValidationData;
        bytes paymasterContext;
    }

    /**
     * Returned aggregated signature info:
     * The aggregator returned by the account, and its current stake.
     */
    struct AggregatorStakeInfo {
        address aggregator;
        StakeInfo stakeInfo;
    }

    /**
     * Get counterfactual sender address.
     * Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * This method always revert, and returns the address in SenderAddressResult error
     * @param initCode - The constructor code to be passed into the UserOperation.
     */
    // function getSenderAddress(bytes memory initCode) external;

    // error DelegateAndRevert(bool success, bytes ret);

    /**
     * Helper method for dry-run testing.
     * @dev calling this method, the EntryPoint will make a delegatecall to the given data, and report (via revert) the result.
     *  The method always revert, so is only useful off-chain for dry run calls, in cases where state-override to replace
     *  actual EntryPoint code is less convenient.
     * @param target a target contract to make a delegatecall from entrypoint
     * @param data data to pass to target in a delegatecall
     */
    // function delegateAndRevert(address target, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.23;

import "../interfaces/IStakeManager.sol";

/* solhint-disable avoid-low-level-calls */
/* solhint-disable not-rely-on-time */

/**
 * Manage deposits and stakes.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 * Stake is value locked for at least "unstakeDelay" by a paymaster.
 */
abstract contract StakeManager is IStakeManager {
    /// maps paymaster to their deposits and stakes
    mapping(address => DepositInfo) public deposits;

    /// @inheritdoc IStakeManager
    function getDepositInfo(
        address account
    ) public view returns (DepositInfo memory info) {
        return deposits[account];
    }

    /**
     * Internal method to return just the stake info.
     * @param addr - The account to query.
     */
    function _getStakeInfo(
        address addr
    ) internal view returns (StakeInfo memory info) {
        DepositInfo storage depositInfo = deposits[addr];
        info.stake = depositInfo.stake;
        info.unstakeDelaySec = depositInfo.unstakeDelaySec;
    }

    /// @inheritdoc IStakeManager
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account].deposit;
    }

    receive() external payable {
        depositTo(msg.sender);
    }

    /**
     * Increments an account's deposit.
     * @param account - The account to increment.
     * @param amount  - The amount to increment by.
     * @return the updated deposit of this account
     */
    function _incrementDeposit(address account, uint256 amount) internal returns (uint256) {
        DepositInfo storage info = deposits[account];
        uint256 newAmount = info.deposit + amount;
        info.deposit = newAmount;
        return newAmount;
    }

    /**
     * Add to the deposit of the given account.
     * @param account - The account to add to.
     */
    function depositTo(address account) public virtual payable {
        uint256 newDeposit = _incrementDeposit(account, msg.value);
        emit Deposited(account, newDeposit);
    }

    /**
     * Add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param unstakeDelaySec The new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 unstakeDelaySec) public payable {
        DepositInfo storage info = deposits[msg.sender];
        require(unstakeDelaySec > 0, "must specify unstake delay");
        require(
            unstakeDelaySec >= info.unstakeDelaySec,
            "cannot decrease unstake time"
        );
        uint256 stake = info.stake + msg.value;
        require(stake > 0, "no stake specified");
        require(stake <= type(uint112).max, "stake overflow");
        deposits[msg.sender] = DepositInfo(
            info.deposit,
            true,
            uint112(stake),
            unstakeDelaySec,
            0
        );
        emit StakeLocked(msg.sender, stake, unstakeDelaySec);
    }

    /**
     * Attempt to unlock the stake.
     * The value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external {
        DepositInfo storage info = deposits[msg.sender];
        require(info.unstakeDelaySec != 0, "not staked");
        require(info.staked, "already unstaking");
        uint48 withdrawTime = uint48(block.timestamp) + info.unstakeDelaySec;
        info.withdrawTime = withdrawTime;
        info.staked = false;
        emit StakeUnlocked(msg.sender, withdrawTime);
    }

    /**
     * Withdraw from the (unlocked) stake.
     * Must first call unlockStake and wait for the unstakeDelay to pass.
     * @param withdrawAddress - The address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external {
        DepositInfo storage info = deposits[msg.sender];
        uint256 stake = info.stake;
        require(stake > 0, "No stake to withdraw");
        require(info.withdrawTime > 0, "must call unlockStake() first");
        require(
            info.withdrawTime <= block.timestamp,
            "Stake withdrawal is not due"
        );
        info.unstakeDelaySec = 0;
        info.withdrawTime = 0;
        info.stake = 0;
        emit StakeWithdrawn(msg.sender, withdrawAddress, stake);
        (bool success,) = withdrawAddress.call{value: stake}("");
        require(success, "failed to withdraw stake");
    }

    /**
     * Withdraw from the deposit.
     * @param withdrawAddress - The address to send withdrawn value.
     * @param withdrawAmount  - The amount to withdraw.
     */
    function withdrawTo(
        address payable withdrawAddress,
        uint256 withdrawAmount
    ) external {
        DepositInfo storage info = deposits[msg.sender];
        require(withdrawAmount <= info.deposit, "Withdraw amount too large");
        info.deposit = info.deposit - withdrawAmount;
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
        (bool success,) = withdrawAddress.call{value: withdrawAmount}("");
        require(success, "failed to withdraw");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/**
 * Helper contract for EntryPoint, to call userOp.initCode from a "neutral" address,
 * which is explicitly not the entryPoint itself.
 */
contract SenderCreator {
    /**
     * Call the "initCode" factory to create and return the sender account address.
     * @param initCode - The initCode value from a UserOp. contains 20 bytes of factory address,
     *                   followed by calldata.
     * @return sender  - The returned address of the created account, or zero address on failure.
     */
    function createSender(
        bytes calldata initCode
    ) external returns (address sender) {
        address factory = address(bytes20(initCode[0:20]));
        bytes memory initCallData = initCode[20:];
        bool success;
        /* solhint-disable no-inline-assembly */
        assembly ("memory-safe") {
            success := call(
                gas(),
                factory,
                0,
                add(initCallData, 0x20),
                mload(initCallData),
                0,
                32
            )
            sender := mload(0)
        }
        if (!success) {
            sender = address(0);
        }
    }
}

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
pragma solidity ^0.8.23;

import "../interfaces/INonceManager.sol";

/**
 * nonce management functionality
 */
abstract contract NonceManager is INonceManager {

    /**
     * The next valid sequence number for a given nonce key.
     */
    mapping(address => mapping(uint192 => uint256)) public nonceSequenceNumber;

    /// @inheritdoc INonceManager
    function getNonce(address sender, uint192 key)
    public view override returns (uint256 nonce) {
        return nonceSequenceNumber[sender][key] | (uint256(key) << 64);
    }

    // allow an account to manually increment its own nonce.
    // (mainly so that during construction nonce can be made non-zero,
    // to "absorb" the gas cost of first nonce increment to 1st transaction (construction),
    // not to 2nd transaction)
    function incrementNonce(uint192 key) public override {
        nonceSequenceNumber[msg.sender][key]++;
    }

    /**
     * validate nonce uniqueness for this account.
     * called just after validateUserOp()
     * @return true if the nonce was incremented successfully.
     *         false if the current nonce doesn't match the given one.
     */
    function _validateAndUpdateNonce(address sender, uint256 nonce) internal returns (bool) {

        uint192 key = uint192(nonce >> 64);
        uint64 seq = uint64(nonce);
        return nonceSequenceNumber[sender][key]++ == seq;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable no-inline-assembly */

import "../interfaces/PackedUserOperation.sol";
import {calldataKeccak, min} from "./Helpers.sol";

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    uint256 public constant PAYMASTER_VALIDATION_GAS_OFFSET = 20;
    uint256 public constant PAYMASTER_POSTOP_GAS_OFFSET = 36;
    uint256 public constant PAYMASTER_DATA_OFFSET = 52;
    /**
     * Get sender from user operation data.
     * @param userOp - The user operation data.
     */
    function getSender(
        PackedUserOperation calldata userOp
    ) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    /**
     * Relayer/block builder might submit the TX with higher priorityFee,
     * but the user should not pay above what he signed for.
     * @param userOp - The user operation data.
     */
    function gasPrice(
        PackedUserOperation calldata userOp
    ) internal view returns (uint256) {
        unchecked {
            (uint256 maxPriorityFeePerGas, uint256 maxFeePerGas) = unpackUints(userOp.gasFees);
            if (maxFeePerGas == maxPriorityFeePerGas) {
                //legacy mode (for networks that don't support basefee opcode)
                return maxFeePerGas;
            }
            return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    /**
     * Pack the user operation data into bytes for hashing.
     * @param userOp - The user operation data.
     */
    function encode(
        PackedUserOperation calldata userOp
    ) internal pure returns (bytes memory ret) {
        address sender = getSender(userOp);
        uint256 nonce = userOp.nonce;
        bytes32 hashInitCode = calldataKeccak(userOp.initCode);
        bytes32 hashCallData = calldataKeccak(userOp.callData);
        bytes32 accountGasLimits = userOp.accountGasLimits;
        uint256 preVerificationGas = userOp.preVerificationGas;
        bytes32 gasFees = userOp.gasFees;
        bytes32 hashPaymasterAndData = calldataKeccak(userOp.paymasterAndData);

        return abi.encode(
            sender, nonce,
            hashInitCode, hashCallData,
            accountGasLimits, preVerificationGas, gasFees,
            hashPaymasterAndData
        );
    }

    function unpackUints(
        bytes32 packed
    ) internal pure returns (uint256 high128, uint256 low128) {
        return (uint128(bytes16(packed)), uint128(uint256(packed)));
    }

    //unpack just the high 128-bits from a packed value
    function unpackHigh128(bytes32 packed) internal pure returns (uint256) {
        return uint256(packed) >> 128;
    }

    // unpack just the low 128-bits from a packed value
    function unpackLow128(bytes32 packed) internal pure returns (uint256) {
        return uint128(uint256(packed));
    }

    function unpackMaxPriorityFeePerGas(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return unpackHigh128(userOp.gasFees);
    }

    function unpackMaxFeePerGas(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return unpackLow128(userOp.gasFees);
    }

    function unpackVerificationGasLimit(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return unpackHigh128(userOp.accountGasLimits);
    }

    function unpackCallGasLimit(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return unpackLow128(userOp.accountGasLimits);
    }

    function unpackPaymasterVerificationGasLimit(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return uint128(bytes16(userOp.paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET : PAYMASTER_POSTOP_GAS_OFFSET]));
    }

    function unpackPostOpGasLimit(PackedUserOperation calldata userOp)
    internal pure returns (uint256) {
        return uint128(bytes16(userOp.paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET : PAYMASTER_DATA_OFFSET]));
    }

    function unpackPaymasterStaticFields(
        bytes calldata paymasterAndData
    ) internal pure returns (address paymaster, uint256 validationGasLimit, uint256 postOpGasLimit) {
        return (
            address(bytes20(paymasterAndData[: PAYMASTER_VALIDATION_GAS_OFFSET])),
            uint128(bytes16(paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET : PAYMASTER_POSTOP_GAS_OFFSET])),
            uint128(bytes16(paymasterAndData[PAYMASTER_POSTOP_GAS_OFFSET : PAYMASTER_DATA_OFFSET]))
        );
    }

    /**
     * Hash the user operation data.
     * @param userOp - The user operation data.
     */
    function hash(
        PackedUserOperation calldata userOp
    ) internal pure returns (bytes32) {
        return keccak256(encode(userOp));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.5;

/**
 * Manage deposits and stakes.
 * Deposit is just a balance used to pay for UserOperations (either by a paymaster or an account).
 * Stake is value locked for at least "unstakeDelay" by the staked entity.
 */
interface IStakeManager {
    event Deposited(address indexed account, uint256 totalDeposit);

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    // Emitted when stake or unstake delay are modified.
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 unstakeDelaySec
    );

    // Emitted once a stake is scheduled for withdrawal.
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit         - The entity's deposit.
     * @param staked          - True if this entity is staked.
     * @param stake           - Actual amount of ether staked for this entity.
     * @param unstakeDelaySec - Minimum delay to withdraw the stake.
     * @param withdrawTime    - First block timestamp where 'withdrawStake' will be callable, or zero if already locked.
     * @dev Sizes were chosen so that deposit fits into one cell (used during handleOp)
     *      and the rest fit into a 2nd cell (used during stake/unstake)
     *      - 112 bit allows for 10^15 eth
     *      - 48 bit for full timestamp
     *      - 32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint256 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint48 withdrawTime;
    }

    // API struct used by getStakeInfo and simulateValidation.
    struct StakeInfo {
        uint256 stake;
        uint256 unstakeDelaySec;
    }

    /**
     * Get deposit info.
     * @param account - The account to query.
     * @return info   - Full deposit information of given account.
     */
    function getDepositInfo(
        address account
    ) external view returns (DepositInfo memory info);

    /**
     * Get account balance.
     * @param account - The account to query.
     * @return        - The deposit (for gas payment) of the account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Add to the deposit of the given account.
     * @param account - The account to add to.
     */
    function depositTo(address account) external payable;

    /**
     * Add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec - The new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * Attempt to unlock the stake.
     * The value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * Withdraw from the (unlocked) stake.
     * Must first call unlockStake and wait for the unstakeDelay to pass.
     * @param withdrawAddress - The address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * Withdraw from the deposit.
     * @param withdrawAddress - The address to send withdrawn value.
     * @param withdrawAmount  - The amount to withdraw.
     */
    function withdrawTo(
        address payable withdrawAddress,
        uint256 withdrawAmount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

import "./PackedUserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
    /**
     * Validate aggregated signature.
     * Revert if the aggregated signature does not match the given list of operations.
     * @param userOps   - Array of UserOperations to validate the signature for.
     * @param signature - The aggregated signature.
     */
    function validateSignatures(
        PackedUserOperation[] calldata userOps,
        bytes calldata signature
    ) external view;

    /**
     * Validate signature of a single userOp.
     * This method should be called by bundler after EntryPointSimulation.simulateValidation() returns
     * the aggregator this account uses.
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp        - The userOperation received from the user.
     * @return sigForUserOp - The value to put into the signature field of the userOp when calling handleOps.
     *                        (usually empty, unless account and aggregator support some kind of "multisig".
     */
    function validateUserOpSignature(
        PackedUserOperation calldata userOp
    ) external view returns (bytes memory sigForUserOp);

    /**
     * Aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation.
     * @param userOps              - Array of UserOperations to collect the signatures from.
     * @return aggregatedSignature - The aggregated signature.
     */
    function aggregateSignatures(
        PackedUserOperation[] calldata userOps
    ) external view returns (bytes memory aggregatedSignature);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.5;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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