pragma solidity ^0.8.0;

import {ECDSA} from "solady/utils/ECDSA.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";

import {IKernelValidator} from "../interfaces/IKernelValidator.sol";
import {UserOperation} from "I4337/interfaces/UserOperation.sol";

import {SIG_VALIDATION_FAILED} from "../common/Constants.sol";
import {ParamCondition, Operation} from "../common/Enums.sol";
import {ParamRule, SessionData, Permission, Call, ExecutionRule, ExecutionStatus, Nonces} from "../common/Structs.sol";
import "../common/Types.sol";

import {Kernel} from "../Kernel.sol";

contract SessionKeyValidator is IKernelValidator {
    mapping(address kernel => Nonces) public nonces;
    mapping(address sessionKey => mapping(address kernel => SessionData)) public sessionData;
    mapping(bytes32 permissionKey => mapping(address kernel => ExecutionStatus)) public executionStatus;

    function enable(bytes calldata _data) external payable {
        address sessionKey = address(bytes20(_data[0:20]));
        bytes32 merkleRoot = bytes32(_data[20:52]);
        ValidAfter validAfter = ValidAfter.wrap(uint48(bytes6(_data[52:58])));
        ValidUntil validUntil = ValidUntil.wrap(uint48(bytes6(_data[58:64])));
        address paymaster = address(bytes20(_data[64:84]));
        uint256 nonce = uint256(bytes32(_data[84:116]));
        sessionData[sessionKey][msg.sender] = SessionData(merkleRoot, validAfter, validUntil, paymaster, nonce);
        require(nonce == ++nonces[msg.sender].lastNonce, "SessionKeyValidator: invalid nonce");
    }

    function invalidateNonce(uint128 nonce) public {
        require(nonce > nonces[msg.sender].invalidNonce, "SessionKeyValidator: invalid nonce");
        nonces[msg.sender].invalidNonce = nonce;
        nonces[msg.sender].lastNonce = nonce;
    }

    function disable(bytes calldata _data) external payable {
        // invalidate specific sessionKey
        if (_data.length == 20) {
            address sessionKey = address(bytes20(_data[0:20]));
            delete sessionData[sessionKey][msg.sender];
        } else if (_data.length == 16) {
            // invalidate all sessionKeys before specific nonce
            invalidateNonce(uint128(bytes16(_data[0:16])));
        } else {
            // invalidate all sessionKeys
            invalidateNonce(nonces[msg.sender].lastNonce);
        }
    }

    function _verifyPaymaster(UserOperation calldata userOp, SessionData storage session) internal view {
        // to make this fully work with paymaster service, prepack the address of paymaster up front
        if (session.paymaster == address(1)) {
            // any paymaster
            require(userOp.paymasterAndData.length != 0, "SessionKeyValidator: paymaster not set");
        } else if (session.paymaster != address(0)) {
            // specific paymaster
            require(
                address(bytes20(userOp.paymasterAndData[0:20])) == session.paymaster,
                "SessionKeyValidator: paymaster mismatch"
            );
        }
    }

    function _verifyUserOpHash(address _sessionKey, ValidAfter validAfter, ValidUntil validUntil)
        internal
        view
        returns (ValidationData)
    {
        bytes32 userOpHash;
        assembly {
            // 0x00 ~ 0x04 : sig
            // 0x04 ~ 0x24 : userOp.offset
            // 0x24 ~ 0x44 : userOpHash
            userOpHash := calldataload(0x24)
        }
        bytes calldata signature;
        assembly {
            //0x00 ~ 0x04 : selector
            //0x04 ~ 0x24 : userOp.offset
            //0x24 ~ 0x44 : userOpHash
            //0x44 ~ 0x64 : missingAccountFund
            //[userOp.offset + 0x04]
            //0x00 ~ 0x20 : sender
            //0x20 ~ 0x40 : nonce
            //0x40 ~ 0x60 : initCode
            //0x60 ~ 0x80 : callData
            //0x80 ~ 0xa0 : callGasLimit
            //0xa0 ~ 0xc0 : verificationGasLimit
            //0xc0 ~ 0xe0 : preVerificationGas
            //0xe0 ~ 0x100 : maxFeePerGas
            //0x100 ~ 0x120 : maxPriorityFeePerGas
            //0x120 ~ 0x140 : paymasterAndData
            //0x140 ~ 0x160 : signatureOffset
            //[signatureOffset + userOp.offset + 0x04]
            //[0x00 ~ 0x20] : length
            //[0x20 ~]      : signature
            let userOpOffset := add(calldataload(0x04), 0x04)
            let signatureOffset := add(calldataload(add(userOpOffset, 0x140)), add(userOpOffset, 0x34))
            signature.offset := signatureOffset
            signature.length := 0x41
        }
        if (_sessionKey != ECDSA.recover(ECDSA.toEthSignedMessageHash(userOpHash), signature)) {
            return SIG_VALIDATION_FAILED;
        }
        return packValidationData(validAfter, validUntil);
    }

    // to parse batch execute permissions
    function _getPermissions(bytes calldata _sig) internal pure returns (Permission[] calldata permissions) {
        assembly {
            permissions.offset := add(add(_sig.offset, 0x20), calldataload(_sig.offset))
            permissions.length := calldataload(add(_sig.offset, calldataload(_sig.offset)))
        }
    }

    function _getProofs(bytes calldata _sig) internal pure returns (bytes32[][] calldata proofs) {
        assembly {
            proofs.length := calldataload(add(_sig.offset, calldataload(add(_sig.offset, 0x20))))
            proofs.offset := add(add(_sig.offset, 0x20), calldataload(add(_sig.offset, 0x20)))
        }
    }

    // to parse single execute permission
    function _getPermission(bytes calldata _sig)
        internal
        pure
        returns (Permission calldata permission, bytes32[] calldata merkleProof)
    {
        assembly {
            permission := add(_sig.offset, calldataload(_sig.offset))
            merkleProof.length := calldataload(add(_sig.offset, calldataload(add(_sig.offset, 0x20))))
            merkleProof.offset := add(add(_sig.offset, 0x20), calldataload(add(_sig.offset, 0x20)))
        }
    }

    function validateUserOp(UserOperation calldata userOp, bytes32, uint256)
        external
        payable
        returns (ValidationData)
    {
        // userOp.signature = signer + signature + permission + merkleProof
        address sessionKey = address(bytes20(userOp.signature[0:20]));
        SessionData storage session = sessionData[sessionKey][msg.sender];
        // nonce starts from 1
        require(session.nonce > nonces[msg.sender].invalidNonce, "SessionKeyValidator: session key not enabled");
        _verifyPaymaster(userOp, session);

        // NOTE: although this is allowed in smart contract, it is guided not to use this feature in most usecases
        // instead of setting sudo approval to sessionKey, please set specific permission to sessionKey
        if (session.merkleRoot == bytes32(0)) {
            return _verifyUserOpHash(sessionKey, session.validAfter, session.validUntil);
        }

        bytes calldata callData = userOp.callData;
        if (
            bytes4(callData[0:4]) == Kernel.execute.selector
                || bytes4(callData[0:4]) == Kernel.executeDelegateCall.selector
        ) {
            (Permission calldata permission, bytes32[] calldata merkleProof) = _getPermission(userOp.signature[85:]);
            (ValidAfter validAfter, bool verifyFailed) = _verifyParam(sessionKey, callData, permission, merkleProof);
            if (verifyFailed) {
                return SIG_VALIDATION_FAILED;
            }
            return _verifyUserOpHash(sessionKey, validAfter, session.validUntil);
        } else if (bytes4(callData[0:4]) == Kernel.executeBatch.selector) {
            Permission[] calldata permissions = _getPermissions(userOp.signature[85:]);
            bytes32[][] calldata merkleProof = _getProofs(userOp.signature[85:]);
            (ValidAfter validAfter, bool verifyFailed) = _verifyParams(sessionKey, callData, permissions, merkleProof);
            if (verifyFailed) {
                return SIG_VALIDATION_FAILED;
            }
            return _verifyUserOpHash(sessionKey, validAfter, session.validUntil);
        } else {
            return SIG_VALIDATION_FAILED;
        }
    }

    function _updateValidAfter(Permission calldata permission, bytes32 permissionKey)
        internal
        returns (ValidAfter validAfter)
    {
        if (permission.executionRule.interval == 0) {
            // no need to update validAfter
            validAfter = permission.executionRule.validAfter;
        } else {
            require(
                ValidAfter.unwrap(permission.executionRule.validAfter) != 0,
                "SessionKeyValidator: invalid execution rule"
            );
            // should update validAfter for executionStatus
            ExecutionStatus storage status = executionStatus[permissionKey][msg.sender];
            if (ValidAfter.unwrap(status.validAfter) != 0) {
                validAfter = ValidAfter.wrap(ValidAfter.unwrap(status.validAfter) + permission.executionRule.interval);
            } else {
                validAfter = permission.executionRule.validAfter;
            }
            status.validAfter = validAfter;
        }
        // update runs
        if (permission.executionRule.runs != 0) {
            ExecutionStatus storage status = executionStatus[permissionKey][msg.sender];
            status.runs += 1;
            require(status.runs <= permission.executionRule.runs, "SessionKeyValidator: runs exceeded");
        }
        return validAfter;
    }

    function _verifyParams(
        address sessionKey,
        bytes calldata callData,
        Permission[] calldata _permissions,
        bytes32[][] calldata _merkleProof
    ) internal returns (ValidAfter maxValidAfter, bool verifyFailed) {
        Call[] calldata calls;
        assembly {
            calls.offset := add(add(callData.offset, 0x24), calldataload(add(callData.offset, 4)))
            calls.length := calldataload(add(add(callData.offset, 4), calldataload(add(callData.offset, 4))))
        }
        uint256 i = 0;
        SessionData storage session = sessionData[sessionKey][msg.sender];
        maxValidAfter = session.validAfter;
        for (i = 0; i < calls.length; i++) {
            Call calldata call = calls[i];
            Permission calldata permission = _permissions[i];
            require(
                permission.target == address(0) || call.to == permission.target, "SessionKeyValidator: target mismatch"
            );
            require(uint256(bytes32(call.value)) <= permission.valueLimit, "SessionKeyValidator: value limit exceeded");
            require(verifyPermission(call.data, permission), "SessionKeyValidator: permission verification failed");
            ValidAfter validAfter =
                _updateValidAfter(permission, keccak256(abi.encodePacked(session.nonce, permission.index)));
            if (ValidAfter.unwrap(validAfter) > ValidAfter.unwrap(maxValidAfter)) {
                maxValidAfter = validAfter;
            }
            if (!MerkleProofLib.verify(_merkleProof[i], session.merkleRoot, keccak256(abi.encode(permission)))) {
                return (maxValidAfter, true);
            }
        }
    }

    function _verifyParam(
        address sessionKey,
        bytes calldata callData,
        Permission calldata _permission,
        bytes32[] calldata _merkleProof
    ) internal returns (ValidAfter validAfter, bool verifyFailed) {
        SessionData storage session = sessionData[sessionKey][msg.sender];
        bool isExecute = bytes4(callData[0:4]) == Kernel.execute.selector;
        require(
            _permission.target == address(0) || address(bytes20(callData[16:36])) == _permission.target,
            "SessionKeyValidator: target mismatch"
        );
        if (isExecute) {
            require(
                uint256(bytes32(callData[36:68])) <= _permission.valueLimit, "SessionKeyValidator: value limit exceeded"
            );
        } else {
            require(_permission.operation == Operation.DelegateCall, "SessionKeyValidator: operation mismatch");
        }
        bytes calldata data;
        uint8 dataParamOffset = isExecute ? 0x44 : 0x24;
        assembly {
            let dataOffset := add(add(callData.offset, 0x04), calldataload(add(callData.offset, dataParamOffset)))
            let length := calldataload(dataOffset)
            data.offset := add(dataOffset, 32)
            data.length := length
        }
        require(verifyPermission(data, _permission), "SessionKeyValidator: permission verification failed");
        validAfter = _updateValidAfter(_permission, keccak256(abi.encodePacked(session.nonce, _permission.index)));
        if (ValidAfter.unwrap(validAfter) < ValidAfter.unwrap(session.validAfter)) {
            validAfter = session.validAfter;
        }
        if (!MerkleProofLib.verify(_merkleProof, session.merkleRoot, keccak256(abi.encode(_permission)))) {
            return (validAfter, true);
        }
    }

    function verifyPermission(bytes calldata data, Permission calldata permission) internal pure returns (bool) {
        if (bytes4(data[0:4]) != permission.sig) return false;
        for (uint256 i = 0; i < permission.rules.length; i++) {
            ParamRule calldata rule = permission.rules[i];
            bytes32 param = bytes32(data[4 + rule.offset:4 + rule.offset + 32]);
            if (rule.condition == ParamCondition.EQUAL && param != rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.GREATER_THAN && param <= rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.LESS_THAN && param >= rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.GREATER_THAN_OR_EQUAL && param < rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.LESS_THAN_OR_EQUAL && param > rule.param) {
                return false;
            } else if (rule.condition == ParamCondition.NOT_EQUAL && param == rule.param) {
                return false;
            }
        }
        return true;
    }

    function validCaller(address, bytes calldata) external pure returns (bool) {
        revert NotImplemented();
    }

    function validateSignature(bytes32, bytes calldata) external pure returns (ValidationData) {
        revert NotImplemented();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
///
/// @dev Note:
/// - The recovery functions use the ecrecover precompile (0x1).
/// - As of Solady version 0.0.68, the `recover` variants will revert upon recovery failure.
///   This is for more safety by default.
///   Use the `tryRecover` variants if you need to get the zero address back
///   upon recovery failure instead.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The signature is invalid.
    error InvalidSignature();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recover(bytes32 hash, bytes memory signature) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function recoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        result, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            result :=
                mload(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                )
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TRY-RECOVER OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // WARNING!
    // These functions will NOT revert upon recovery failure.
    // Instead, they will return the zero address upon recovery failure.
    // It is critical that the returned address is NEVER compared against
    // a zero address (e.g. an uninitialized address variable).

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecover(bytes32 hash, bytes memory signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            for {} 1 {} {
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`, and the `signature`.
    function tryRecoverCalldata(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            for {} 1 {} {
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    break
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // Copy `r` and `s`.
                    break
                }
                result := 0
                break
            }
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    result, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, add(shr(255, vs), 27)) // `v`.
            mstore(0x40, r)
            mstore(0x60, shr(1, shl(1, vs))) // `s`.
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    1, // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x40, // Start of output.
                    0x20 // Size of output.
                )
            )
            mstore(0x60, 0) // Restore the zero slot.
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            result := mload(xor(0x60, returndatasize()))
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            MERKLE PROOF VERIFICATION OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(proof) {
                // Initialize `offset` to the offset of `proof` elements in memory.
                let offset := add(proof, 0x20)
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(offset, shl(5, mload(proof)))
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, mload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), mload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    ///
    /// Note:
    /// - Breaking the invariant `flags.length == (leaves.length - 1) + proof.length`
    ///   will always return false.
    /// - The sum of the lengths of `proof` and `leaves` must never overflow.
    /// - Any non-zero word in the `flags` array is treated as true.
    /// - The memory offset of `proof` must be non-zero
    ///   (i.e. `proof` is not pointing to the scratch space).
    function verifyMultiProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32[] memory leaves,
        bool[] memory flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the lengths of the arrays.
            let leavesLength := mload(leaves)
            let proofLength := mload(proof)
            let flagsLength := mload(flags)

            // Advance the pointers of the arrays to point to the data.
            leaves := add(0x20, leaves)
            proof := add(0x20, proof)
            flags := add(0x20, flags)

            // If the number of flags is correct.
            for {} eq(add(leavesLength, proofLength), add(flagsLength, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flagsLength) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    isValid := eq(mload(xor(leaves, mul(xor(proof, leaves), proofLength))), root)
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := add(proof, shl(5, proofLength))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                leavesLength := shl(5, leavesLength)
                for { let i := 0 } iszero(eq(i, leavesLength)) { i := add(i, 0x20) } {
                    mstore(add(hashesFront, i), mload(add(leaves, i)))
                }
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, leavesLength)
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flagsLength := add(hashesBack, shl(5, flagsLength))

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(mload(flags)) {
                        // Loads the next proof.
                        b := mload(proof)
                        proof := add(proof, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag.
                    flags := add(flags, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flagsLength)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required.
                        eq(proofEnd, proof)
                    )
                break
            }
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    ///
    /// Note:
    /// - Breaking the invariant `flags.length == (leaves.length - 1) + proof.length`
    ///   will always return false.
    /// - Any non-zero word in the `flags` array is treated as true.
    /// - The calldata offset of `proof` must be non-zero
    ///   (i.e. `proof` is from a regular Solidity function with a 4-byte selector).
    function verifyMultiProofCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leaves.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leaves.offset, mul(xor(proof.offset, leaves.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := add(proof.offset, shl(5, proof.length))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                calldatacopy(hashesFront, leaves.offset, shl(5, leaves.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leaves.length))
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required.
                        eq(proofEnd, proof.offset)
                    )
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes32 array.
    function emptyProof() internal pure returns (bytes32[] calldata proof) {
        /// @solidity memory-safe-assembly
        assembly {
            proof.length := 0
        }
    }

    /// @dev Returns an empty calldata bytes32 array.
    function emptyLeaves() internal pure returns (bytes32[] calldata leaves) {
        /// @solidity memory-safe-assembly
        assembly {
            leaves.length := 0
        }
    }

    /// @dev Returns an empty calldata bool array.
    function emptyFlags() internal pure returns (bool[] calldata flags) {
        /// @solidity memory-safe-assembly
        assembly {
            flags.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UserOperation} from "I4337/interfaces/UserOperation.sol";
import "../common/Types.sol";

interface IKernelValidator {
    error NotImplemented();

    function enable(bytes calldata _data) external payable;

    function disable(bytes calldata _data) external payable;

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingFunds)
        external
        payable
        returns (ValidationData);

    function validateSignature(bytes32 hash, bytes calldata signature) external view returns (ValidationData);

    function validCaller(address caller, bytes calldata data) external view returns (bool);
}

// 3 modes
// 1. default mode, use preset validator for the kernel
// 2. enable mode, enable a new validator for given action and use it for current userOp
// 3. sudo mode, use default plugin for current userOp

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

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

pragma solidity ^0.8.0;

import {ValidationData} from "./Types.sol";

// Constants for kernel metadata
string constant KERNEL_NAME = "Kernel";
string constant KERNEL_VERSION = "0.2.3";

// ERC4337 constants
uint256 constant SIG_VALIDATION_FAILED_UINT = 1;
ValidationData constant SIG_VALIDATION_FAILED = ValidationData.wrap(SIG_VALIDATION_FAILED_UINT);

// STRUCT_HASH

/// @dev Struct hash for the ValidatorApproved struct -> keccak256("ValidatorApproved(bytes4 sig,uint256 validatorData,address executor,bytes enableData)")
bytes32 constant VALIDATOR_APPROVED_STRUCT_HASH = 0x3ce406685c1b3551d706d85a68afdaa49ac4e07b451ad9b8ff8b58c3ee964176;

/* -------------------------------------------------------------------------- */
/*                                Storage slots                               */
/* -------------------------------------------------------------------------- */

/// @dev Storage slot for the kernel storage
bytes32 constant KERNEL_STORAGE_SLOT = 0x439ffe7df606b78489639bc0b827913bd09e1246fa6802968a5b3694c53e0dd8;
/// @dev Storage pointer inside the kernel storage, with 1 offset, to access directly disblaedMode, disabled date and default validator
bytes32 constant KERNEL_STORAGE_SLOT_1 = 0x439ffe7df606b78489639bc0b827913bd09e1246fa6802968a5b3694c53e0dd9;
/// @dev Storage slot for the logic implementation address
bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

pragma solidity ^0.8.0;

enum Operation {
    Call,
    DelegateCall
}

enum ParamCondition {
    EQUAL,
    GREATER_THAN,
    LESS_THAN,
    GREATER_THAN_OR_EQUAL,
    LESS_THAN_OR_EQUAL,
    NOT_EQUAL
}

pragma solidity ^0.8.0;

import {IKernelValidator} from "../interfaces/IKernelValidator.sol";
import {ParamCondition, Operation} from "./Enums.sol";
import {ValidAfter, ValidUntil} from "./Types.sol";

// Defining a struct for execution details
struct ExecutionDetail {
    ValidAfter validAfter; // Until what time is this execution valid
    ValidUntil validUntil; // After what time is this execution valid
    address executor; // Who is the executor of this execution
    IKernelValidator validator; // The validator for this execution
}

struct Call {
    address to;
    uint256 value;
    bytes data;
}

// Defining a struct for wallet kernel storage
struct WalletKernelStorage {
    bytes32 __deprecated; // A deprecated field
    bytes4 disabledMode; // Mode which is currently disabled
    uint48 lastDisabledTime; // Last time when a mode was disabled
    IKernelValidator defaultValidator; // Default validator for the wallet
    mapping(bytes4 => ExecutionDetail) execution; // Mapping of function selectors to execution details
}

// Param Rule for session key
struct Nonces {
    uint128 lastNonce;
    uint128 invalidNonce;
}

struct ParamRule {
    uint256 offset;
    ParamCondition condition;
    bytes32 param;
}

struct ExecutionRule {
    ValidAfter validAfter; // 48 bits
    uint48 interval; // 48 bits
    uint48 runs; // 48 bits
}

struct ExecutionStatus {
    ValidAfter validAfter; // 48 bits
    uint48 runs; // 48 bits
}

struct Permission {
    uint32 index;
    address target;
    bytes4 sig;
    uint256 valueLimit;
    ParamRule[] rules;
    ExecutionRule executionRule;
    Operation operation;
}

struct SessionData {
    bytes32 merkleRoot;
    ValidAfter validAfter;
    ValidUntil validUntil;
    address paymaster; // address(0) means accept userOp without paymaster, address(1) means reject userOp with paymaster, other address means accept userOp with paymaster with the address
    uint256 nonce;
}

pragma solidity ^0.8.9;

type ValidAfter is uint48;

type ValidUntil is uint48;

type ValidationData is uint256;

function packValidationData(ValidAfter validAfter, ValidUntil validUntil) pure returns (ValidationData) {
    return ValidationData.wrap(
        uint256(ValidAfter.unwrap(validAfter)) << 208 | uint256(ValidUntil.unwrap(validUntil)) << 160
    );
}

function parseValidationData(ValidationData validationData)
    pure
    returns (ValidAfter validAfter, ValidUntil validUntil, address result)
{
    assembly {
        result := validationData
        validUntil := and(shr(160, validationData), 0xffffffffffff)
        switch iszero(validUntil)
        case 1 { validUntil := 0xffffffffffff }
        validAfter := shr(208, validationData)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing external libraries and contracts
import {EIP712} from "solady/utils/EIP712.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {IEntryPoint} from "I4337/interfaces/IEntryPoint.sol";
import {UserOperation} from "I4337/interfaces/UserOperation.sol";
import {Compatibility} from "./abstract/Compatibility.sol";
import {KernelStorage} from "./abstract/KernelStorage.sol";
import {_intersectValidationData} from "./utils/KernelHelper.sol";
import {IKernelValidator} from "./interfaces/IKernelValidator.sol";

import {
    KERNEL_NAME,
    KERNEL_VERSION,
    VALIDATOR_APPROVED_STRUCT_HASH,
    KERNEL_STORAGE_SLOT_1,
    SIG_VALIDATION_FAILED
} from "./common/Constants.sol";
import {Operation} from "./common/Enums.sol";
import {WalletKernelStorage, Call, ExecutionDetail} from "./common/Structs.sol";
import {ValidationData, ValidAfter, ValidUntil, parseValidationData, packValidationData} from "./common/Types.sol";

/// @title Kernel
/// @author taek<[email protected]>
/// @notice wallet kernel for extensible wallet functionality
contract Kernel is EIP712, Compatibility, KernelStorage {
    /// @dev Selector of the `DisabledMode()` error, to be used in assembly, 'bytes4(keccak256(bytes("DisabledMode()")))', same as DisabledMode.selector()
    uint256 private constant _DISABLED_MODE_SELECTOR = 0xfc2f51c5;

    /// @dev Current kernel name and version, todo: Need to expose getter for this variables?
    string public constant name = KERNEL_NAME;
    string public constant version = KERNEL_VERSION;

    /// @dev Sets up the EIP712 and KernelStorage with the provided entry point
    constructor(IEntryPoint _entryPoint) KernelStorage(_entryPoint) {}

    /// @notice Accepts incoming Ether transactions and calls from the EntryPoint contract
    /// @dev This function will delegate any call to the appropriate executor based on the function signature.
    fallback() external payable {
        bytes4 sig = msg.sig;
        address executor = getKernelStorage().execution[sig].executor;
        if (msg.sender != address(entryPoint) && !_checkCaller()) {
            revert NotAuthorizedCaller();
        }
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), executor, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Executes a function call to an external contract
    /// @param to The address of the target contract
    /// @param value The amount of Ether to send
    /// @param data The call data to be sent
    /// @dev operation is deprecated param, use executeBatch for batched transaction
    function execute(address to, uint256 value, bytes memory data, Operation _operation) external payable {
        if (msg.sender != address(entryPoint) && msg.sender != address(this) && !_checkCaller()) {
            revert NotAuthorizedCaller();
        }
        if (_operation != Operation.Call) {
            revert DeprecatedOperation();
        }
        assembly {
            let success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Executes a function call to an external contract with delegatecall
    /// @param to The address of the target contract
    /// @param data The call data to be sent
    function executeDelegateCall(address to, bytes memory data) external payable {
        if (msg.sender != address(entryPoint) && msg.sender != address(this) && !_checkCaller()) {
            revert NotAuthorizedCaller();
        }
        assembly {
            let success := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice Executes a function call to an external contract batched
    /// @param calls The calls to be executed, in order
    /// @dev operation deprecated param, use executeBatch for batched transaction
    function executeBatch(Call[] memory calls) external payable {
        if (msg.sender != address(entryPoint) && !_checkCaller()) {
            revert NotAuthorizedCaller();
        }
        uint256 len = calls.length;
        for (uint256 i = 0; i < len;) {
            Call memory call = calls[i];
            address to = call.to;
            uint256 value = call.value;
            bytes memory data = call.data;
            assembly {
                let success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch success
                case 0 { revert(0, returndatasize()) }
                default { i := add(i, 1) }
            }
        }
    }

    /// @notice Validates a user operation based on its mode
    /// @dev This function will validate user operation and be called by EntryPoint
    /// @param _userOp The user operation to be validated
    /// @param userOpHash The hash of the user operation
    /// @param missingAccountFunds The funds needed to be reimbursed
    /// @return validationData The data used for validation
    function validateUserOp(UserOperation calldata _userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        virtual
        returns (ValidationData validationData)
    {
        if (msg.sender != address(entryPoint)) {
            revert NotEntryPoint();
        }
        bytes calldata userOpSignature;
        uint256 userOpEndOffset;
        assembly {
            // Store the userOpSignature offset
            userOpEndOffset := add(calldataload(0x04), 0x24)
            // Extract the user op signature from the calldata (but keep it in the calldata, just extract offset & length)
            userOpSignature.offset := add(calldataload(add(userOpEndOffset, 0x120)), userOpEndOffset)
            userOpSignature.length := calldataload(sub(userOpSignature.offset, 0x20))
        }
        // mode based signature
        bytes4 mode = bytes4(userOpSignature[0:4]); // mode == 00..00 use validators
        // mode == 0x00000000 use sudo validator
        if (mode == 0x00000000) {
            assembly {
                if missingAccountFunds {
                    pop(call(gas(), caller(), missingAccountFunds, callvalue(), callvalue(), callvalue(), callvalue()))
                    //ignore failure (its EntryPoint's job to verify, not account.)
                }
            }
            // short circuit here for default validator
            return _validateUserOp(_userOp, userOpHash, missingAccountFunds);
        }

        // Check if the kernel is disabled, if that's the case, it's only accepting userOperation with sudo mode
        assembly ("memory-safe") {
            // Extract the disabled mode from the storage slot
            let isKernelDisabled := shl(224, sload(KERNEL_STORAGE_SLOT_1))
            // If we got a non-zero disabled mode, and non zero mode, then revert
            if and(isKernelDisabled, mode) {
                mstore(0x00, _DISABLED_MODE_SELECTOR)
                revert(0x1c, 0x04)
            }
        }

        // The validator that will be used
        IKernelValidator validator;

        // mode == 0x00000001 use given validator
        // mode == 0x00000002 enable validator
        if (mode == 0x00000001) {
            bytes calldata userOpCallData;
            assembly {
                userOpCallData.offset := add(calldataload(add(userOpEndOffset, 0x40)), userOpEndOffset)
                userOpCallData.length := calldataload(sub(userOpCallData.offset, 0x20))
            }
            ExecutionDetail storage detail = getKernelStorage().execution[bytes4(userOpCallData[0:4])];
            validator = detail.validator;
            userOpSignature = userOpSignature[4:];
            validationData = packValidationData(detail.validAfter, detail.validUntil);
        } else if (mode == 0x00000002) {
            bytes calldata userOpCallData;
            assembly {
                userOpCallData.offset := add(calldataload(add(userOpEndOffset, 0x40)), userOpEndOffset)
                userOpCallData.length := calldataload(sub(userOpCallData.offset, 0x20))
            }
            // use given validator
            // userOpSignature[4:10] = validAfter,
            // userOpSignature[10:16] = validUntil,
            // userOpSignature[16:36] = validator address,
            (validator, validationData, userOpSignature) =
                _approveValidator(bytes4(userOpCallData[0:4]), userOpSignature);
        } else {
            return SIG_VALIDATION_FAILED;
        }

        assembly {
            if missingAccountFunds {
                pop(call(gas(), caller(), missingAccountFunds, callvalue(), callvalue(), callvalue(), callvalue()))
                //ignore failure (its EntryPoint's job to verify, not account.)
            }
        }

        // Replicate the userOp from memory to calldata, to update it's signature (since with mode 1 & 2 the signatre can be updated)
        UserOperation memory userOp = _userOp;
        userOp.signature = userOpSignature;

        // Get the validator data from the designated signer
        validationData =
            _intersectValidationData(validationData, validator.validateUserOp(userOp, userOpHash, missingAccountFunds));
        return validationData;
    }

    /// @dev This function will approve a new validator for the current kernel
    /// @param sig The signature of the userOp asking for a validator approval
    /// @param signature The signature of the userOp asking for a validator approval
    function _approveValidator(bytes4 sig, bytes calldata signature)
        internal
        returns (IKernelValidator validator, ValidationData validationData, bytes calldata validationSig)
    {
        unchecked {
            validator = IKernelValidator(address(bytes20(signature[16:36])));
            uint256 cursor = 88;
            uint256 length = uint256(bytes32(signature[56:88])); // this is enableDataLength
            bytes calldata enableData;
            assembly {
                enableData.offset := add(signature.offset, cursor)
                enableData.length := length
                cursor := add(cursor, length) // 88 + enableDataLength
            }
            length = uint256(bytes32(signature[cursor:cursor + 32])); // this is enableSigLength
            assembly {
                cursor := add(cursor, 32)
            }
            bytes32 enableDigest = _hashTypedData(
                keccak256(
                    abi.encode(
                        VALIDATOR_APPROVED_STRUCT_HASH,
                        bytes4(sig),
                        uint256(bytes32(signature[4:36])),
                        address(bytes20(signature[36:56])),
                        keccak256(enableData)
                    )
                )
            );
            validationData = _intersectValidationData(
                _validateSignature(enableDigest, signature[cursor:cursor + length]),
                ValidationData.wrap(
                    uint256(bytes32(signature[4:36]))
                        & 0xffffffffffffffffffffffff0000000000000000000000000000000000000000
                )
            );
            assembly {
                cursor := add(cursor, length)
                validationSig.offset := add(signature.offset, cursor)
                validationSig.length := sub(signature.length, cursor)
            }
            getKernelStorage().execution[sig] = ExecutionDetail({
                validAfter: ValidAfter.wrap(uint48(bytes6(signature[4:10]))),
                validUntil: ValidUntil.wrap(uint48(bytes6(signature[10:16]))),
                executor: address(bytes20(signature[36:56])),
                validator: IKernelValidator(address(bytes20(signature[16:36])))
            });
            validator.enable(enableData);
        }
    }

    /// @dev Validates a signature for the given kernel
    /// @param hash The hash of the data that was signed
    /// @param signature The signature to be validated
    function validateSignature(bytes32 hash, bytes calldata signature) public view returns (ValidationData) {
        return _validateSignature(hash, signature);
    }

    /// @dev Get the current name & version of the kernel, used for the EIP-712 domain separator
    function _domainNameAndVersion() internal pure override returns (string memory, string memory) {
        return (name, version);
    }

    /// @dev Get an EIP-712 compliant domain separator
    function _domainSeparator() internal view override returns (bytes32) {
        // Obtain the name and version from the _domainNameAndVersion function.
        (string memory _name, string memory _version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(_name));
        bytes32 versionHash = keccak256(bytes(_version));

        // Use the proxy address for the EIP-712 domain separator.
        address proxyAddress = address(this);

        // Construct the domain separator with name, version, chainId, and proxy address.
        bytes32 typeHash =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, proxyAddress));
    }

    /// @notice Checks if a signature is valid
    /// @dev This function checks if a signature is valid based on the hash of the data signed.
    /// @param hash The hash of the data that was signed
    /// @param signature The signature to be validated
    /// @return The magic value 0x1626ba7e if the signature is valid, otherwise returns 0xffffffff.
    function isValidSignature(bytes32 hash, bytes calldata signature) public view returns (bytes4) {
        // Include the proxy address in the domain separator
        bytes32 domainSeparator = _domainSeparator();

        // Recreate the signed message hash with the correct domain separator
        bytes32 signedMessageHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));

        ValidationData validationData = validateSignature(signedMessageHash, signature);
        (ValidAfter validAfter, ValidUntil validUntil, address result) = parseValidationData(validationData);

        // Check if the signature is valid within the specified time frame and the result is successful
        if (
            ValidAfter.unwrap(validAfter) <= block.timestamp && ValidUntil.unwrap(validUntil) >= block.timestamp
                && result == address(0)
        ) {
            // If all checks pass, return the ERC1271 magic value for a valid signature
            return 0x1626ba7e;
        } else {
            // If any check fails, return the failure magic value
            return 0xffffffff;
        }
    }

    /// @dev Check if the current caller is authorized or no to perform the call
    /// @return True if the caller is authorized, otherwise false
    function _checkCaller() internal view returns (bool) {
        if (_validCaller(msg.sender, msg.data)) {
            return true;
        }
        bytes4 sig = msg.sig;
        ExecutionDetail storage detail = getKernelStorage().execution[sig];
        if (
            address(detail.validator) == address(0)
                || (ValidUntil.unwrap(detail.validUntil) != 0 && ValidUntil.unwrap(detail.validUntil) < block.timestamp)
                || ValidAfter.unwrap(detail.validAfter) > block.timestamp
        ) {
            return false;
        } else {
            return detail.validator.validCaller(msg.sender, msg.data);
        }
    }

    /// @dev This function will validate user operation and be called by EntryPoint
    /// @param _op The user operation to be validated
    /// @param _opHash The hash of the user operation
    /// @param _missingFunds The funds needed to be reimbursed
    function _validateUserOp(UserOperation calldata _op, bytes32 _opHash, uint256 _missingFunds)
        internal
        virtual
        returns (ValidationData)
    {
        // Replace the user op in memory to update the signature
        UserOperation memory op = _op;
        // Remove the validation mode flag from the signature
        op.signature = _op.signature[4:];

        IKernelValidator validator;
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
        return IKernelValidator(validator).validateUserOp(op, _opHash, _missingFunds);
    }

    /// @dev This function will validate a signature for the given kernel
    /// @param _hash The hash of the data that was signed
    /// @param _signature The signature to be validated
    /// @return The magic value 0x1626ba7e if the signature is valid, otherwise returns 0xffffffff.
    function _validateSignature(bytes32 _hash, bytes calldata _signature)
        internal
        view
        virtual
        returns (ValidationData)
    {
        address validator;
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
        return IKernelValidator(validator).validateSignature(_hash, _signature);
    }

    /// @dev Check if the given caller is valid for the given data
    /// @param _caller The caller to be checked
    /// @param _data The data to be checked
    /// @return True if the caller is valid, otherwise false
    function _validCaller(address _caller, bytes calldata _data) internal view virtual returns (bool) {
        address validator;
        assembly {
            // Load the validator from the storage slot
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
        return IKernelValidator(validator).validCaller(_caller, _data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
///
/// @dev Note, this implementation:
/// - Uses `address(this)` for the `verifyingContract` field.
/// - Does NOT use the optional EIP-712 salt.
/// - Does NOT use any EIP-712 extensions.
/// This is for simplicity and to save gas.
/// If you need to customize, please fork / modify accordingly.
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    uint256 private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedNameHash;
    bytes32 private immutable _cachedVersionHash;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() {
        _cachedThis = uint256(uint160(address(this)));
        _cachedChainId = block.chainid;

        string memory name;
        string memory version;
        if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
        bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
        bytes32 versionHash =
            _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        if (!_domainNameAndVersionMayChange()) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40) // Load the free memory pointer.
                mstore(m, _DOMAIN_TYPEHASH)
                mstore(add(m, 0x20), nameHash)
                mstore(add(m, 0x40), versionHash)
                mstore(add(m, 0x60), chainid())
                mstore(add(m, 0x80), address())
                separator := keccak256(m, 0xa0)
            }
        }
        _cachedDomainSeparator = separator;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the domain name and version.
    /// ```
    ///     function _domainNameAndVersion()
    ///         internal
    ///         pure
    ///         virtual
    ///         returns (string memory name, string memory version)
    ///     {
    ///         name = "Solady";
    ///         version = "1";
    ///     }
    /// ```
    ///
    /// Note: If the returned result may change after the contract has been deployed,
    /// you must override `_domainNameAndVersionMayChange()` to return true.
    function _domainNameAndVersion()
        internal
        view
        virtual
        returns (string memory name, string memory version);

    /// @dev Returns if `_domainNameAndVersion()` may change
    /// after the contract has been deployed (i.e. after the constructor).
    /// Default: false.
    function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        if (_domainNameAndVersionMayChange()) {
            separator = _buildDomainSeparator();
        } else {
            separator = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        if (_domainNameAndVersionMayChange()) {
            digest = _buildDomainSeparator();
        } else {
            digest = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-5267 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator() private view returns (bytes32 separator) {
        // We will use `separator` to store the name hash to save a bit of gas.
        bytes32 versionHash;
        if (_domainNameAndVersionMayChange()) {
            (string memory name, string memory version) = _domainNameAndVersion();
            separator = keccak256(bytes(name));
            versionHash = keccak256(bytes(version));
        } else {
            separator = _cachedNameHash;
            versionHash = _cachedVersionHash;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), separator) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        uint256 cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
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

    // Return value of getSenderAddress.
    error SenderAddressResult(address sender);

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

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Compatibility {
    event Received(address sender, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary interfaces
import {IEntryPoint} from "I4337/interfaces/IEntryPoint.sol";
import {IKernelValidator} from "../interfaces/IKernelValidator.sol";
import {IKernel} from "../interfaces/IKernel.sol";
import {KERNEL_STORAGE_SLOT, KERNEL_STORAGE_SLOT_1, IMPLEMENTATION_SLOT} from "../common/Constants.sol";
import {ExecutionDetail, WalletKernelStorage} from "../common/Structs.sol";
import {ValidUntil, ValidAfter} from "../common/Types.sol";

/// @title Kernel Storage Contract
/// @author taek<[email protected]>
/// @notice This contract serves as the storage module for the Kernel contract.
/// @dev This contract should only be used by the main Kernel contract.
abstract contract KernelStorage is IKernel {
    IEntryPoint public immutable entryPoint; // The entry point of the contract

    // Modifier to check if the function is called by the entry point, the contract itself or the owner
    modifier onlyFromEntryPointOrSelf() {
        if (msg.sender != address(entryPoint) && msg.sender != address(this)) {
            revert NotAuthorizedCaller();
        }
        _;
    }

    /// @param _entryPoint The address of the EntryPoint contract
    /// @dev Sets up the EntryPoint contract address
    constructor(IEntryPoint _entryPoint) {
        entryPoint = _entryPoint;
        getKernelStorage().defaultValidator = IKernelValidator(address(1));
    }

    // Function to initialize the wallet kernel
    function initialize(IKernelValidator _defaultValidator, bytes calldata _data) external payable override {
        _setInitialData(_defaultValidator, _data);
    }

    // Function to get the wallet kernel storage
    function getKernelStorage() internal pure returns (WalletKernelStorage storage ws) {
        assembly {
            ws.slot := KERNEL_STORAGE_SLOT
        }
    }

    // Function to upgrade the contract to a new implementation
    function upgradeTo(address _newImplementation) external payable override onlyFromEntryPointOrSelf {
        assembly {
            sstore(IMPLEMENTATION_SLOT, _newImplementation)
        }
        emit Upgraded(_newImplementation);
    }

    // Functions to get the nonce from the entry point
    function getNonce() external view virtual returns (uint256) {
        return entryPoint.getNonce(address(this), 0);
    }

    function getNonce(uint192 key) external view virtual returns (uint256) {
        return entryPoint.getNonce(address(this), key);
    }

    // query storage
    function getDefaultValidator() external view override returns (IKernelValidator validator) {
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
    }

    function getDisabledMode() external view override returns (bytes4 disabled) {
        assembly {
            disabled := shl(224, sload(KERNEL_STORAGE_SLOT_1))
        }
    }

    function getLastDisabledTime() external view override returns (uint48) {
        return getKernelStorage().lastDisabledTime;
    }

    function getExecution(bytes4 _selector) external view override returns (ExecutionDetail memory) {
        return getKernelStorage().execution[_selector];
    }

    function setExecution(
        bytes4 _selector,
        address _executor,
        IKernelValidator _validator,
        ValidUntil _validUntil,
        ValidAfter _validAfter,
        bytes calldata _enableData
    ) external payable override onlyFromEntryPointOrSelf {
        getKernelStorage().execution[_selector] = ExecutionDetail({
            executor: _executor,
            validator: _validator,
            validUntil: _validUntil,
            validAfter: _validAfter
        });
        _validator.enable(_enableData);
        emit ExecutionChanged(_selector, _executor, address(_validator));
    }

    function setDefaultValidator(IKernelValidator _defaultValidator, bytes calldata _data)
        external
        payable
        virtual
        onlyFromEntryPointOrSelf
    {
        IKernelValidator oldValidator = getKernelStorage().defaultValidator;
        getKernelStorage().defaultValidator = _defaultValidator;
        emit DefaultValidatorChanged(address(oldValidator), address(_defaultValidator));
        _defaultValidator.enable(_data);
    }

    function disableMode(bytes4 _disableFlag) external payable override onlyFromEntryPointOrSelf {
        getKernelStorage().disabledMode = _disableFlag;
        getKernelStorage().lastDisabledTime = uint48(block.timestamp);
    }

    function _setInitialData(IKernelValidator _defaultValidator, bytes calldata _data) internal virtual {
        address validator;
        assembly {
            validator := shr(80, sload(KERNEL_STORAGE_SLOT_1))
        }
        if (address(validator) != address(0)) {
            revert AlreadyInitialized();
        }
        getKernelStorage().defaultValidator = _defaultValidator;
        _defaultValidator.enable(_data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SIG_VALIDATION_FAILED_UINT} from "../common/Constants.sol";
import {ValidationData} from "../common/Types.sol";

function _intersectValidationData(ValidationData a, ValidationData b) pure returns (ValidationData validationData) {
    assembly {
        // xor(a,b) == shows only matching bits
        // and(xor(a,b), 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff) == filters out the validAfter and validUntil bits
        // if the result is not zero, then aggregator part is not matching
        switch iszero(and(xor(a, b), 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff))
        case 1 {
            // validAfter
            let a_vd := and(0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff, a)
            let b_vd := and(0xffffffffffff000000000000ffffffffffffffffffffffffffffffffffffffff, b)
            validationData := xor(a_vd, mul(xor(a_vd, b_vd), gt(b_vd, a_vd)))
            // validUntil
            a_vd := and(0x000000000000ffffffffffff0000000000000000000000000000000000000000, a)
            if iszero(a_vd) { a_vd := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            b_vd := and(0x000000000000ffffffffffff0000000000000000000000000000000000000000, b)
            if iszero(b_vd) { b_vd := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            let until := xor(a_vd, mul(xor(a_vd, b_vd), lt(b_vd, a_vd)))
            if iszero(until) { until := 0x000000000000ffffffffffff0000000000000000000000000000000000000000 }
            validationData := or(validationData, until)
        }
        default { validationData := SIG_VALIDATION_FAILED_UINT }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IKernelValidator} from "./IKernelValidator.sol";
import {ExecutionDetail, Call} from "../common/Structs.sol";
import {ValidationData, ValidUntil, ValidAfter} from "../common/Types.sol";
import {Operation} from "../common/Enums.sol";
import {UserOperation} from "I4337/interfaces/UserOperation.sol";

interface IKernel {
    // Event declarations
    event Upgraded(address indexed newImplementation);

    event DefaultValidatorChanged(address indexed oldValidator, address indexed newValidator);

    event ExecutionChanged(bytes4 indexed selector, address indexed executor, address indexed validator);

    // Error declarations
    error NotAuthorizedCaller();

    error AlreadyInitialized();

    error NotEntryPoint();

    error DisabledMode();

    error DeprecatedOperation();

    function initialize(IKernelValidator _validator, bytes calldata _data) external payable;

    function upgradeTo(address _newImplementation) external payable;

    function getNonce() external view returns (uint256);

    function getNonce(uint192 key) external view returns (uint256);

    function getDefaultValidator() external view returns (IKernelValidator);

    function getDisabledMode() external view returns (bytes4 disabled);

    function getLastDisabledTime() external view returns (uint48);

    /// @notice Returns the execution details for a specific function signature
    /// @dev This function can be used to get execution details for a specific function signature
    /// @param _selector The function signature
    /// @return ExecutionDetail struct containing the execution details
    function getExecution(bytes4 _selector) external view returns (ExecutionDetail memory);

    /// @notice Changes the execution details for a specific function selector
    /// @dev This function can only be called from the EntryPoint contract, the contract owner, or itself
    /// @param _selector The selector of the function for which execution details are being set
    /// @param _executor The executor to be associated with the function selector
    /// @param _validator The validator contract that will be responsible for validating operations associated with this function selector
    /// @param _validUntil The timestamp until which the execution details are valid
    /// @param _validAfter The timestamp after which the execution details are valid
    function setExecution(
        bytes4 _selector,
        address _executor,
        IKernelValidator _validator,
        ValidUntil _validUntil,
        ValidAfter _validAfter,
        bytes calldata _enableData
    ) external payable;

    function setDefaultValidator(IKernelValidator _defaultValidator, bytes calldata _data) external payable;

    /// @notice Updates the disabled mode
    /// @dev This function can be used to update the disabled mode
    /// @param _disableFlag The new disabled mode
    function disableMode(bytes4 _disableFlag) external payable;

    /// @notice Executes a function call to an external contract
    /// @dev The type of operation (call or delegatecall) is specified as an argument.
    /// @param to The address of the target contract
    /// @param value The amount of Ether to send
    /// @param data The call data to be sent
    /// operation deprecated operation type, usere executeBatch for batch operation
    function execute(address to, uint256 value, bytes memory data, Operation) external payable;

    function executeBatch(Call[] memory calls) external payable;

    function executeDelegateCall(address to, bytes memory data) external payable;

    /// @notice Validates a user operation based on its mode
    /// @dev This function will validate user operation and be called by EntryPoint
    /// @param userOp The user operation to be validated
    /// @param userOpHash The hash of the user operation
    /// @param missingAccountFunds The funds needed to be reimbursed
    /// @return validationData The data used for validation
    function validateUserOp(UserOperation memory userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        payable
        returns (ValidationData validationData);
}