// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */

import "../interfaces/IAccount.sol";
import "../interfaces/IPaymaster.sol";
import "../interfaces/IEntryPoint.sol";

import "../utils/Exec.sol";
import "./StakeManager.sol";
import "./SenderCreator.sol";
import "./Helpers.sol";
import "./NonceManager.sol";

// we also require '@gnosis.pm/safe-contracts' and both libraries have 'IERC165.sol', leading to conflicts
import "@openzeppelin/contracts/utils/introspection/ERC165.sol" as OpenZeppelin;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
 * Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 * Only one instance required on each chain.
 */
contract EntryPoint is IEntryPoint, StakeManager, NonceManager, ReentrancyGuard, OpenZeppelin.ERC165 {

    using UserOperationLib for UserOperation;

    SenderCreator private immutable senderCreator = new SenderCreator();

    // Internal value used during simulation: need to query aggregator.
    address private constant SIMULATE_FIND_AGGREGATOR = address(1);

    // Marker for inner call revert on out of gas
    bytes32 private constant INNER_OUT_OF_GAS = hex"deaddead";

    uint256 private constant REVERT_REASON_MAX_LEN = 2048;

    /**
     * For simulation purposes, validateUserOp (and validatePaymasterUserOp)
     * must return this value in case of signature failure, instead of revert.
     */
    uint256 public constant SIG_VALIDATION_FAILED = 1;

    /// @inheritdoc OpenZeppelin.IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // note: solidity "type(IEntryPoint).interfaceId" is without inherited methods but we want to check everything
        return interfaceId == (type(IEntryPoint).interfaceId ^ type(IStakeManager).interfaceId ^ type(INonceManager).interfaceId) ||
            interfaceId == type(IEntryPoint).interfaceId ||
            interfaceId == type(IStakeManager).interfaceId ||
            interfaceId == type(INonceManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * Compensate the caller's beneficiary address with the collected fees of all UserOperations.
     * @param beneficiary - The address to receive the fees.
     * @param amount      - Amount to transfer.
     */
    function _compensate(address payable beneficiary, uint256 amount) internal {
        require(beneficiary != address(0), "AA90 invalid beneficiary");
        (bool success, ) = beneficiary.call{value: amount}("");
        require(success, "AA91 failed send to beneficiary");
    }

    /**
     * Execute a user operation.
     * @param opIndex    - Index into the opInfo array.
     * @param userOp     - The userOp to execute.
     * @param opInfo     - The opInfo filled by validatePrepayment for this userOp.
     * @return collected - The total amount this userOp paid.
     */
    function _executeUserOp(
        uint256 opIndex,
        UserOperation calldata userOp,
        UserOpInfo memory opInfo
    ) private returns (uint256 collected) {
        uint256 preGas = gasleft();
        bytes memory context = getMemoryBytesFromOffset(opInfo.contextOffset);

        try this.innerHandleOp(userOp.callData, opInfo, context) returns (
            uint256 _actualGasCost
        ) {
            collected = _actualGasCost;
        } catch {
            bytes32 innerRevertCode;
            assembly {
                let len := returndatasize()
                if eq(32,len) {
                    returndatacopy(0, 0, 32)
                    innerRevertCode := mload(0)
                }
            }
            // handleOps was called with gas limit too low. abort entire bundle.
            if (innerRevertCode == INNER_OUT_OF_GAS) {
                //report paymaster, since if it is not deliberately caused by the bundler,
                // it must be a revert caused by paymaster.
                revert FailedOp(opIndex, "AA95 out of gas");
            }

            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            collected = _handlePostOp(
                opIndex,
                IPaymaster.PostOpMode.postOpReverted,
                opInfo,
                context,
                actualGas
            );
        }
    }

    /// @inheritdoc IEntryPoint
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) public nonReentrant {
        uint256 opslen = ops.length;
        UserOpInfo[] memory opInfos = new UserOpInfo[](opslen);

        unchecked {
            for (uint256 i = 0; i < opslen; i++) {
                UserOpInfo memory opInfo = opInfos[i];
                (
                    uint256 validationData,
                    uint256 pmValidationData
                ) = _validatePrepayment(i, ops[i], opInfo);
                _validateAccountAndPaymasterValidationData(
                    i,
                    validationData,
                    pmValidationData,
                    address(0)
                );
            }

            uint256 collected = 0;
            emit BeforeExecution();

            for (uint256 i = 0; i < opslen; i++) {
                collected += _executeUserOp(i, ops[i], opInfos[i]);
            }

            _compensate(beneficiary, collected);
        }
    }

    /// @inheritdoc IEntryPoint
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) public nonReentrant {

        uint256 opasLen = opsPerAggregator.length;
        uint256 totalOps = 0;
        for (uint256 i = 0; i < opasLen; i++) {
            UserOpsPerAggregator calldata opa = opsPerAggregator[i];
            UserOperation[] calldata ops = opa.userOps;
            IAggregator aggregator = opa.aggregator;

            //address(1) is special marker of "signature error"
            require(
                address(aggregator) != address(1),
                "AA96 invalid aggregator"
            );

            if (address(aggregator) != address(0)) {
                // solhint-disable-next-line no-empty-blocks
                try aggregator.validateSignatures(ops, opa.signature) {} catch {
                    revert SignatureValidationFailed(address(aggregator));
                }
            }

            totalOps += ops.length;
        }

        UserOpInfo[] memory opInfos = new UserOpInfo[](totalOps);

        emit BeforeExecution();

        uint256 opIndex = 0;
        for (uint256 a = 0; a < opasLen; a++) {
            UserOpsPerAggregator calldata opa = opsPerAggregator[a];
            UserOperation[] calldata ops = opa.userOps;
            IAggregator aggregator = opa.aggregator;

            uint256 opslen = ops.length;
            for (uint256 i = 0; i < opslen; i++) {
                UserOpInfo memory opInfo = opInfos[opIndex];
                (
                    uint256 validationData,
                    uint256 paymasterValidationData
                ) = _validatePrepayment(opIndex, ops[i], opInfo);
                _validateAccountAndPaymasterValidationData(
                    i,
                    validationData,
                    paymasterValidationData,
                    address(aggregator)
                );
                opIndex++;
            }
        }

        uint256 collected = 0;
        opIndex = 0;
        for (uint256 a = 0; a < opasLen; a++) {
            UserOpsPerAggregator calldata opa = opsPerAggregator[a];
            emit SignatureAggregatorChanged(address(opa.aggregator));
            UserOperation[] calldata ops = opa.userOps;
            uint256 opslen = ops.length;

            for (uint256 i = 0; i < opslen; i++) {
                collected += _executeUserOp(opIndex, ops[i], opInfos[opIndex]);
                opIndex++;
            }
        }
        emit SignatureAggregatorChanged(address(0));

        _compensate(beneficiary, collected);
    }

    /// @inheritdoc IEntryPoint
    function simulateHandleOp(
        UserOperation calldata op,
        address target,
        bytes calldata targetCallData
    ) external override {
        UserOpInfo memory opInfo;
        _simulationOnlyValidations(op);
        (
            uint256 validationData,
            uint256 paymasterValidationData
        ) = _validatePrepayment(0, op, opInfo);
        ValidationData memory data = _intersectTimeRange(
            validationData,
            paymasterValidationData
        );

        numberMarker();
        uint256 paid = _executeUserOp(0, op, opInfo);
        numberMarker();
        bool targetSuccess;
        bytes memory targetResult;
        if (target != address(0)) {
            (targetSuccess, targetResult) = target.call(targetCallData);
        }
        revert ExecutionResult(
            opInfo.preOpGas,
            paid,
            data.validAfter,
            data.validUntil,
            targetSuccess,
            targetResult
        );
    }

    /**
     * A memory copy of UserOp static fields only.
     * Excluding: callData, initCode and signature. Replacing paymasterAndData with paymaster.
     */
    struct MemoryUserOp {
        address sender;
        uint256 nonce;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
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
     */
    function innerHandleOp(
        bytes memory callData,
        UserOpInfo memory opInfo,
        bytes calldata context
    ) external returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        require(msg.sender == address(this), "AA92 internal call only");
        MemoryUserOp memory mUserOp = opInfo.mUserOp;

        uint callGasLimit = mUserOp.callGasLimit;
        unchecked {
            // handleOps was called with gas limit too low. abort entire bundle.
            if (
                gasleft() < callGasLimit + mUserOp.verificationGasLimit + 5000
            ) {
                assembly {
                    mstore(0, INNER_OUT_OF_GAS)
                    revert(0, 32)
                }
            }
        }

        IPaymaster.PostOpMode mode = IPaymaster.PostOpMode.opSucceeded;
        if (callData.length > 0) {
            bool success = Exec.call(mUserOp.sender, 0, callData, callGasLimit);
            if (!success) {
                bytes memory result = Exec.getReturnData(REVERT_REASON_MAX_LEN);
                if (result.length > 0) {
                    emit UserOperationRevertReason(
                        opInfo.userOpHash,
                        mUserOp.sender,
                        mUserOp.nonce,
                        result
                    );
                }
                mode = IPaymaster.PostOpMode.opReverted;
            }
        }

        unchecked {
            uint256 actualGas = preGas - gasleft() + opInfo.preOpGas;
            // Note: opIndex is ignored (relevant only if mode==postOpReverted, which is only possible outside of innerHandleOp)
            return _handlePostOp(0, mode, opInfo, context, actualGas);
        }
    }

    /// @inheritdoc IEntryPoint
    function getUserOpHash(
        UserOperation calldata userOp
    ) public view returns (bytes32) {
        return
            keccak256(abi.encode(userOp.hash(), address(this), block.chainid));
    }

    /**
     * Copy general fields from userOp into the memory opInfo structure.
     * @param userOp  - The user operation.
     * @param mUserOp - The memory user operation.
     */
    function _copyUserOpToMemory(
        UserOperation calldata userOp,
        MemoryUserOp memory mUserOp
    ) internal pure {
        mUserOp.sender = userOp.sender;
        mUserOp.nonce = userOp.nonce;
        mUserOp.callGasLimit = userOp.callGasLimit;
        mUserOp.verificationGasLimit = userOp.verificationGasLimit;
        mUserOp.preVerificationGas = userOp.preVerificationGas;
        mUserOp.maxFeePerGas = userOp.maxFeePerGas;
        mUserOp.maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        if (paymasterAndData.length > 0) {
            require(
                paymasterAndData.length >= 20,
                "AA93 invalid paymasterAndData"
            );
            mUserOp.paymaster = address(bytes20(paymasterAndData[:20]));
        } else {
            mUserOp.paymaster = address(0);
        }
    }

    /// @inheritdoc IEntryPoint
    function simulateValidation(UserOperation calldata userOp) external {
        UserOpInfo memory outOpInfo;

        _simulationOnlyValidations(userOp);
        (
            uint256 validationData,
            uint256 paymasterValidationData
        ) = _validatePrepayment(0, userOp, outOpInfo);
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

        ValidationData memory data = _intersectTimeRange(
            validationData,
            paymasterValidationData
        );
        address aggregator = data.aggregator;
        bool sigFailed = aggregator == address(1);
        ReturnInfo memory returnInfo = ReturnInfo(
            outOpInfo.preOpGas,
            outOpInfo.prefund,
            sigFailed,
            data.validAfter,
            data.validUntil,
            getMemoryBytesFromOffset(outOpInfo.contextOffset)
        );

        if (aggregator != address(0) && aggregator != address(1)) {
            AggregatorStakeInfo memory aggregatorInfo = AggregatorStakeInfo(
                aggregator,
                _getStakeInfo(aggregator)
            );
            revert ValidationResultWithAggregation(
                returnInfo,
                senderInfo,
                factoryInfo,
                paymasterInfo,
                aggregatorInfo
            );
        }
        revert ValidationResult(
            returnInfo,
            senderInfo,
            factoryInfo,
            paymasterInfo
        );
    }

    /**
     * Get the required prefunded gas fee amount for an operation.
     * @param mUserOp - The user operation in memory.
     */
    function _getRequiredPrefund(
        MemoryUserOp memory mUserOp
    ) internal pure returns (uint256 requiredPrefund) {
        unchecked {
            // When using a Paymaster, the verificationGasLimit is used also to as a limit for the postOp call.
            // Our security model might call postOp eventually twice.
            uint256 mul = mUserOp.paymaster != address(0) ? 3 : 1;
            uint256 requiredGas = mUserOp.callGasLimit +
                mUserOp.verificationGasLimit *
                mul +
                mUserOp.preVerificationGas;

            requiredPrefund = requiredGas * mUserOp.maxFeePerGas;
        }
    }

    /**
     * Create sender smart contract account if init code is provided.
     * @param opIndex  - The operation index.
     * @param opInfo   - The operation info.
     * @param initCode - The init code for the smart contract account.
     */
    function _createSenderIfNeeded(
        uint256 opIndex,
        UserOpInfo memory opInfo,
        bytes calldata initCode
    ) internal {
        if (initCode.length != 0) {
            address sender = opInfo.mUserOp.sender;
            if (sender.code.length != 0)
                revert FailedOp(opIndex, "AA10 sender already constructed");
            address sender1 = senderCreator.createSender{
                gas: opInfo.mUserOp.verificationGasLimit
            }(initCode);
            if (sender1 == address(0))
                revert FailedOp(opIndex, "AA13 initCode failed or OOG");
            if (sender1 != sender)
                revert FailedOp(opIndex, "AA14 initCode must return sender");
            if (sender1.code.length == 0)
                revert FailedOp(opIndex, "AA15 initCode must create sender");
            address factory = address(bytes20(initCode[0:20]));
            emit AccountDeployed(
                opInfo.userOpHash,
                sender,
                factory,
                opInfo.mUserOp.paymaster
            );
        }
    }

    /// @inheritdoc IEntryPoint
    function getSenderAddress(bytes calldata initCode) public {
        address sender = senderCreator.createSender(initCode);
        revert SenderAddressResult(sender);
    }

    function _simulationOnlyValidations(
        UserOperation calldata userOp
    ) internal view {
        try
            this._validateSenderAndPaymaster(
                userOp.initCode,
                userOp.sender,
                userOp.paymasterAndData
            )
        // solhint-disable-next-line no-empty-blocks
        {} catch Error(string memory revertReason) {
            if (bytes(revertReason).length != 0) {
                revert FailedOp(0, revertReason);
            }
        }
    }

    /**
     * Called only during simulation.
     * This function always reverts to prevent warm/cold storage differentiation in simulation vs execution.
     * @param initCode         - The smart account constructor code.
     * @param sender           - The sender address.
     * @param paymasterAndData - The paymaster address followed by the token address to use.
     */
    function _validateSenderAndPaymaster(
        bytes calldata initCode,
        address sender,
        bytes calldata paymasterAndData
    ) external view {
        if (initCode.length == 0 && sender.code.length == 0) {
            // it would revert anyway. but give a meaningful message
            revert("AA20 account not deployed");
        }
        if (paymasterAndData.length >= 20) {
            address paymaster = address(bytes20(paymasterAndData[0:20]));
            if (paymaster.code.length == 0) {
                // It would revert anyway. but give a meaningful message.
                revert("AA30 paymaster not deployed");
            }
        }
        // always revert
        revert("");
    }

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
        UserOperation calldata op,
        UserOpInfo memory opInfo,
        uint256 requiredPrefund
    )
        internal
        returns (
            uint256 gasUsedByValidateAccountPrepayment,
            uint256 validationData
        )
    {
        unchecked {
            uint256 preGas = gasleft();
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            address sender = mUserOp.sender;
            _createSenderIfNeeded(opIndex, opInfo, op.initCode);
            address paymaster = mUserOp.paymaster;
            numberMarker();
            uint256 missingAccountFunds = 0;
            if (paymaster == address(0)) {
                uint256 bal = balanceOf(sender);
                missingAccountFunds = bal > requiredPrefund
                    ? 0
                    : requiredPrefund - bal;
            }
            try
                IAccount(sender).validateUserOp{
                    gas: mUserOp.verificationGasLimit
                }(op, opInfo.userOpHash, missingAccountFunds)
            returns (uint256 _validationData) {
                validationData = _validationData;
            } catch Error(string memory revertReason) {
                revert FailedOp(
                    opIndex,
                    string.concat("AA23 reverted: ", revertReason)
                );
            } catch {
                revert FailedOp(opIndex, "AA23 reverted (or OOG)");
            }
            if (paymaster == address(0)) {
                DepositInfo storage senderInfo = deposits[sender];
                uint256 deposit = senderInfo.deposit;
                if (requiredPrefund > deposit) {
                    revert FailedOp(opIndex, "AA21 didn't pay prefund");
                }
                senderInfo.deposit = uint112(deposit - requiredPrefund);
            }
            gasUsedByValidateAccountPrepayment = preGas - gasleft();
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
     * @param gasUsedByValidateAccountPrepayment - The gas used by _validateAccountPrepayment.
     */
    function _validatePaymasterPrepayment(
        uint256 opIndex,
        UserOperation calldata op,
        UserOpInfo memory opInfo,
        uint256 requiredPreFund,
        uint256 gasUsedByValidateAccountPrepayment
    ) internal returns (bytes memory context, uint256 validationData) {
        unchecked {
            MemoryUserOp memory mUserOp = opInfo.mUserOp;
            uint256 verificationGasLimit = mUserOp.verificationGasLimit;
            require(
                verificationGasLimit > gasUsedByValidateAccountPrepayment,
                "AA41 too little verificationGas"
            );
            uint256 gas = verificationGasLimit -
                gasUsedByValidateAccountPrepayment;

            address paymaster = mUserOp.paymaster;
            DepositInfo storage paymasterInfo = deposits[paymaster];
            uint256 deposit = paymasterInfo.deposit;
            if (deposit < requiredPreFund) {
                revert FailedOp(opIndex, "AA31 paymaster deposit too low");
            }
            paymasterInfo.deposit = uint112(deposit - requiredPreFund);
            try
                IPaymaster(paymaster).validatePaymasterUserOp{gas: gas}(
                    op,
                    opInfo.userOpHash,
                    requiredPreFund
                )
            returns (bytes memory _context, uint256 _validationData) {
                context = _context;
                validationData = _validationData;
            } catch Error(string memory revertReason) {
                revert FailedOp(
                    opIndex,
                    string.concat("AA33 reverted: ", revertReason)
                );
            } catch {
                revert FailedOp(opIndex, "AA33 reverted (or OOG)");
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
        (address aggregator, bool outOfTimeRange) = _getValidationData(
            validationData
        );
        if (expectedAggregator != aggregator) {
            revert FailedOp(opIndex, "AA24 signature error");
        }
        if (outOfTimeRange) {
            revert FailedOp(opIndex, "AA22 expired or not due");
        }
        // pmAggregator is not a real signature aggregator: we don't have logic to handle it as address.
        // Non-zero address means that the paymaster fails due to some signature check (which is ok only during estimation).
        address pmAggregator;
        (pmAggregator, outOfTimeRange) = _getValidationData(
            paymasterValidationData
        );
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
     */
    function _getValidationData(
        uint256 validationData
    ) internal view returns (address aggregator, bool outOfTimeRange) {
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
    function _validatePrepayment(
        uint256 opIndex,
        UserOperation calldata userOp,
        UserOpInfo memory outOpInfo
    )
        private
        returns (uint256 validationData, uint256 paymasterValidationData)
    {
        uint256 preGas = gasleft();
        MemoryUserOp memory mUserOp = outOpInfo.mUserOp;
        _copyUserOpToMemory(userOp, mUserOp);
        outOpInfo.userOpHash = getUserOpHash(userOp);

        // Validate all numeric values in userOp are well below 128 bit, so they can safely be added
        // and multiplied without causing overflow.
        uint256 maxGasValues = mUserOp.preVerificationGas |
            mUserOp.verificationGasLimit |
            mUserOp.callGasLimit |
            userOp.maxFeePerGas |
            userOp.maxPriorityFeePerGas;
        require(maxGasValues <= type(uint120).max, "AA94 gas values overflow");

        uint256 gasUsedByValidateAccountPrepayment;
        uint256 requiredPreFund = _getRequiredPrefund(mUserOp);
        (
            gasUsedByValidateAccountPrepayment,
            validationData
        ) = _validateAccountPrepayment(
            opIndex,
            userOp,
            outOpInfo,
            requiredPreFund
        );
        
        if (!_validateAndUpdateNonce(mUserOp.sender, mUserOp.nonce)) {
            revert FailedOp(opIndex, "AA25 invalid account nonce");
        }
        
        // A "marker" where account opcode validation is done and paymaster opcode validation
        // is about to start (used only by off-chain simulateValidation).
        numberMarker();

        bytes memory context;
        if (mUserOp.paymaster != address(0)) {
            (context, paymasterValidationData) = _validatePaymasterPrepayment(
                opIndex,
                userOp,
                outOpInfo,
                requiredPreFund,
                gasUsedByValidateAccountPrepayment
            );
        }
        unchecked {
            uint256 gasUsed = preGas - gasleft();

            if (userOp.verificationGasLimit < gasUsed) {
                revert FailedOp(opIndex, "AA40 over verificationGasLimit");
            }
            outOpInfo.prefund = requiredPreFund;
            outOpInfo.contextOffset = getOffsetOfMemoryBytes(context);
            outOpInfo.preOpGas = preGas - gasleft() + userOp.preVerificationGas;
        }
    }

    /**
     * Process post-operation, called just after the callData is executed.
     * If a paymaster is defined and its validation returned a non-empty context, its postOp is called.
     * The excess amount is refunded to the account (or paymaster - if it was used in the request).
     * @param opIndex   - Index in the batch.
     * @param mode      - Whether is called from innerHandleOp, or outside (postOpReverted).
     * @param opInfo    - UserOp fields and info collected during validation.
     * @param context   - The context returned in validatePaymasterUserOp.
     * @param actualGas - The gas used so far by this user operation.
     */
    function _handlePostOp(
        uint256 opIndex,
        IPaymaster.PostOpMode mode,
        UserOpInfo memory opInfo,
        bytes memory context,
        uint256 actualGas
    ) private returns (uint256 actualGasCost) {
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
                        IPaymaster(paymaster).postOp{
                            gas: mUserOp.verificationGasLimit
                        }(mode, context, actualGasCost);
                    } else {
                        try
                            IPaymaster(paymaster).postOp{
                                gas: mUserOp.verificationGasLimit
                            }(mode, context, actualGasCost)
                        // solhint-disable-next-line no-empty-blocks
                        {} catch Error(string memory reason) {
                            revert FailedOp(
                                opIndex,
                                string.concat("AA50 postOp reverted: ", reason)
                            );
                        } catch {
                            revert FailedOp(opIndex, "AA50 postOp revert");
                        }
                    }
                }
            }
            actualGas += preGas - gasleft();
            actualGasCost = actualGas * gasPrice;
            if (opInfo.prefund < actualGasCost) {
                revert FailedOp(opIndex, "AA51 prefund below actualGasCost");
            }
            uint256 refund = opInfo.prefund - actualGasCost;
            _incrementDeposit(refundAddress, refund);
            bool success = mode == IPaymaster.PostOpMode.opSucceeded;
            emit UserOperationEvent(
                opInfo.userOpHash,
                mUserOp.sender,
                mUserOp.paymaster,
                mUserOp.nonce,
                success,
                actualGasCost,
                actualGas
            );
        } // unchecked
    }

    /**
     * The gas price this UserOp agrees to pay.
     * Relayer/block builder might submit the TX with higher priorityFee, but the user should not.
     * @param mUserOp - The userOp to get the gas price from.
     */
    function getUserOpGasPrice(
        MemoryUserOp memory mUserOp
    ) internal view returns (uint256) {
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
     * The minimum of two numbers.
     * @param a - First number.
     * @param b - Second number.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * The offset of the given bytes in memory.
     * @param data - The bytes to get the offset of.
     */
    function getOffsetOfMemoryBytes(
        bytes memory data
    ) internal pure returns (uint256 offset) {
        assembly {
            offset := data
        }
    }

    /**
     * The bytes in memory at the given offset.
     * @param offset - The offset to get the bytes from.
     */
    function getMemoryBytesFromOffset(
        uint256 offset
    ) internal pure returns (bytes memory data) {
        assembly {
            data := offset
        }
    }

    /**
     * Places the NUMBER opcode in the code.
     * This is used as a marker during simulation, as this OP is completely banned from the simulated code of the
     * account and paymaster.
     */
    function numberMarker() internal view {
        assembly {
            mstore(0, number())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * Returned data from validateUserOp.
 * validateUserOp returns a uint256, with is created by `_packedValidationData` and
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
    uint validationData
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
 * Intersect account and paymaster ranges.
 * @param validationData          - The packed validation data of the account.
 * @param paymasterValidationData - The packed validation data of the paymaster.
 */
function _intersectTimeRange(
    uint256 validationData,
    uint256 paymasterValidationData
) pure returns (ValidationData memory) {
    ValidationData memory accountValidationData = _parseValidationData(
        validationData
    );
    ValidationData memory pmValidationData = _parseValidationData(
        paymasterValidationData
    );
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
        assembly {
            let mem := mload(0x40)
            let len := data.length
            calldatacopy(mem, data.offset, len)
            ret := keccak256(mem, len)
        }
    }

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../interfaces/IEntryPoint.sol";

/**
 * nonce management functionality
 */
contract NonceManager is INonceManager {

    /**
     * The next valid sequence number for a given nonce key.
     */
    mapping(address => mapping(uint192 => uint256)) public nonceSequenceNumber;

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
     */
    function _validateAndUpdateNonce(address sender, uint256 nonce) internal returns (bool) {

        uint192 key = uint192(nonce >> 64);
        uint64 seq = uint64(nonce);
        return nonceSequenceNumber[sender][key]++ == seq;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

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
        assembly {
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

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

    /**
     * Return the deposit (for gas payment) of the account.
     * @param account - The account to query.
     */
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
     */
    function _incrementDeposit(address account, uint256 amount) internal {
        DepositInfo storage info = deposits[account];
        uint256 newAmount = info.deposit + amount;
        require(newAmount <= type(uint112).max, "deposit overflow");
        info.deposit = uint112(newAmount);
    }

    /**
     * Add to the deposit of the given account.
     * @param account - The account to add to.
     */
    function depositTo(address account) public payable {
        _incrementDeposit(account, msg.value);
        DepositInfo storage info = deposits[account];
        emit Deposited(account, info.deposit);
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
        (bool success, ) = withdrawAddress.call{value: stake}("");
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
        info.deposit = uint112(info.deposit - withdrawAmount);
        emit Withdrawn(msg.sender, withdrawAddress, withdrawAmount);
        (bool success, ) = withdrawAddress.call{value: withdrawAmount}("");
        require(success, "failed to withdraw");
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
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

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
        UserOperation[] calldata userOps,
        bytes calldata signature
    ) external view;

    /**
     * Validate signature of a single userOp.
     * This method is should be called by bundler after EntryPoint.simulateValidation() returns (reverts) with ValidationResultWithAggregation
     * First it validates the signature over the userOp. Then it returns data to be used when creating the handleOps.
     * @param userOp        - The userOperation received from the user.
     * @return sigForUserOp - The value to put into the signature field of the userOp when calling handleOps.
     *                        (usually empty, unless account and aggregator support some kind of "multisig".
     */
    function validateUserOpSignature(
        UserOperation calldata userOp
    ) external view returns (bytes memory sigForUserOp);

    /**
     * Aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation.
     * @param userOps              - Array of UserOperations to collect the signatures from.
     * @return aggregatedSignature - The aggregated signature.
     */
    function aggregateSignatures(
        UserOperation[] calldata userOps
    ) external view returns (bytes memory aggregatedSignature);
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
     * Error case when a signature aggregator fails to verify the aggregated signature it had created.
     * @param aggregator The aggregator that failed to verify the signature
     */
    error SignatureValidationFailed(address aggregator);

    /**
     * Successful result from simulateValidation.
     * @param returnInfo    - Gas and time-range returned values.
     * @param senderInfo    - Stake information about the sender.
     * @param factoryInfo   - Stake information about the factory (if any).
     * @param paymasterInfo - Stake information about the paymaster (if any).
     */
    error ValidationResult(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo
    );

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator.
     * @param returnInfo     Gas and time-range returned values
     * @param senderInfo     Stake information about the sender
     * @param factoryInfo    Stake information about the factory (if any)
     * @param paymasterInfo  Stake information about the paymaster (if any)
     * @param aggregatorInfo Signature aggregation info (if the account requires signature aggregator)
     *                       Bundler MUST use it to verify the signature, or reject the UserOperation.
     */
    error ValidationResultWithAggregation(
        ReturnInfo returnInfo,
        StakeInfo senderInfo,
        StakeInfo factoryInfo,
        StakeInfo paymasterInfo,
        AggregatorStakeInfo aggregatorInfo
    );

    // Return value of getSenderAddress.
    error SenderAddressResult(address sender);

    // Return value of simulateHandleOp.
    error ExecutionResult(
        uint256 preOpGas,
        uint256 paid,
        uint48 validAfter,
        uint48 validUntil,
        bool targetSuccess,
        bytes targetResult
    );

    // UserOps handled, per aggregator.
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
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
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator - The operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts).
     * @param beneficiary      - The address to receive the fees.
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * Generate a request Id - unique identifier for this request.
     * The request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     * @param userOp - The user operation to generate the request ID for.
     */
    function getUserOpHash(
        UserOperation calldata userOp
    ) external view returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev This method always reverts. Successful result is ValidationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage
     *      outside the account's data.
     * @param userOp - The user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * Gas and return values during simulation.
     * @param preOpGas         - The gas used for validation (including preValidationGas)
     * @param prefund          - The required prefund for this operation
     * @param sigFailed        - ValidateUserOp's (or paymaster's) signature check failed
     * @param validAfter       - First timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param validUntil       - Last timestamp this UserOp is valid (merging account and paymaster time-range)
     * @param paymasterContext - Returned by validatePaymasterUserOp (to be passed into postOp)
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
    function getSenderAddress(bytes memory initCode) external;

    /**
     * Simulate full execution of a UserOperation (including both validation and target execution)
     * This method will always revert with "ExecutionResult".
     * It performs full validation of the UserOperation, but ignores signature error.
     * An optional target address is called after the userop succeeds,
     * and its value is returned (before the entire call is reverted).
     * Note that in order to collect the the success/failure of the target call, it must be executed
     * with trace enabled to track the emitted events.
     * @param op The UserOperation to simulate.
     * @param target         - If nonzero, a target address to call after userop simulation. If called,
     *                         the targetSuccess and targetResult are set to the return from that call.
     * @param targetCallData - CallData to pass to target address.
     */
    function simulateHandleOp(
        UserOperation calldata op,
        address target,
        bytes calldata targetCallData
    ) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

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
        // User op succeeded, but caused postOp to revert.
        // Now it's a 2nd call, after user's op was deliberately reverted.
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
     *                                                    otherwise, an address of an "authorizer" contract.
     *                          <6-byte> validUntil - last timestamp this operation is valid. 0 for "indefinite"
     *                          <6-byte> validAfter - first timestamp this operation is valid
     *                          Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external returns (bytes memory context, uint256 validationData);

    /**
     * Post-operation handler.
     * Must verify sender is the entryPoint.
     * @param mode          - Enum with the following options:
     *                        opSucceeded - User operation succeeded.
     *                        opReverted  - User op reverted. still has to pay for gas.
     *                        postOpReverted - User op succeeded, but caused postOp (in mode=opSucceeded) to revert.
     *                                         Now this is the 2nd call, after user's op was deliberately reverted.
     * @param context       - The context value returned by validatePaymasterUserOp
     * @param actualGasCost - Actual gas used so far (without this postOp call).
     */
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

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
     * @dev Sizes were chosen so that (deposit,staked, stake) fit into one cell (used during handleOps)
     *      and the rest fit into a 2nd cell.
     *      - 112 bit allows for 10^15 eth
     *      - 48 bit for full timestamp
     *      - 32 bit allows 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
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
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param callGasLimit          - The gas limit passed to the callData method call.
 * @param verificationGasLimit  - Gas used for validateUserOp and validatePaymasterUserOp.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param maxFeePerGas          - Same as EIP-1559 gas parameter.
 * @param maxPriorityFeePerGas  - Same as EIP-1559 gas parameter.
 * @param paymasterAndData      - If set, this field holds the paymaster address and paymaster-specific data.
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
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
    /**
     * Get sender from user operation data.
     * @param userOp - The user operation data.
     */
    function getSender(
        UserOperation calldata userOp
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
        UserOperation calldata userOp
    ) internal view returns (uint256) {
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

    /**
     * Pack the user operation data into bytes for hashing.
     * @param userOp - The user operation data.
     */
    function pack(
        UserOperation calldata userOp
    ) internal pure returns (bytes memory ret) {
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

    /**
     * Hash the user operation data.
     * @param userOp - The user operation data.
     */
    function hash(
        UserOperation calldata userOp
    ) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    /**
     * The minimum of two numbers.
     * @param a - First number.
     * @param b - Second number.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.5 <0.9.0;

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
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function staticcall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bool success) {
        assembly {
            success := staticcall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function delegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    // get returned data from last call or calldelegate
    function getReturnData(uint256 maxLen) internal pure returns (bytes memory returnData) {
        assembly {
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
        assembly {
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