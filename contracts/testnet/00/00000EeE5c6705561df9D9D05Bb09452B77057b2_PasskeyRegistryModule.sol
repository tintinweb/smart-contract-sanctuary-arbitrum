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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";

// interface for modules to verify singatures signed over userOpHash
interface IAuthorizationModule {
    /**
     * @dev validates userOperation. Expects userOp.callData to be an executeBatch
     * or executeBatch_y6U call. If something goes wrong, reverts.
     * @param userOp User Operation to be validated.
     * @param userOpHash Hash of the User Operation to be validated.
     * @return validationData SIG_VALIDATION_FAILED or packed validation result.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

// bytes4(keccak256("isValidSignature(bytes32,bytes)")
bytes4 constant EIP1271_MAGIC_VALUE = 0x1626ba7e;

interface ISignatureValidator {
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
    ) external view returns (bytes4);

    /**
     * @dev Validates an EIP-1271 signature
     * @dev Expects the data Hash to already include smart account address information
     * @param dataHash hash of the data which includes smart account address
     * @param moduleSignature Signature to be validated.
     * @return EIP1271_MAGIC_VALUE if signature is valid, 0xffffffff otherwise.
     */
    function isValidSignatureUnsafe(
        bytes32 dataHash,
        bytes memory moduleSignature
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAuthorizationModule} from "../../interfaces/IAuthorizationModule.sol";
import {ISignatureValidator} from "../../interfaces/ISignatureValidator.sol";

/* solhint-disable no-empty-blocks */
interface IBaseAuthorizationModule is
    IAuthorizationModule,
    ISignatureValidator
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Passkey ownership Authorization module for Biconomy Smart Accounts.
 * @dev Compatible with Biconomy Modular Interface v 0.2
 *         - It allows to validate user operations signed by passkeys.
 *         - One owner per Smart Account.
 *         For Smart Contract Owners check SmartContractOwnership module instead
 * @author Aman Raj - <[email protected]>
 */
interface IPasskeyRegistryModule {
    error NoPassKeyRegisteredForSmartAccount(address smartAccount);
    error AlreadyInitedForSmartAccount(address smartAccount);

    /**
     * @dev Initializes the module for a Smart Account.
     * Should be used at a time of first enabling the module for a Smart Account.
     * @param _pubKeyX The x coordinate of the public key.
     * @param _pubKeyY The y coordinate of the public key.
     * @param _keyId The keyId of the Smart Account.
     * @return address of the module.
     */
    function initForSmartAccount(
        uint256 _pubKeyX,
        uint256 _pubKeyY,
        string calldata _keyId
    ) external returns (address);

    function isValidSignatureForAddress(
        bytes32 signedDataHash,
        bytes memory moduleSignature
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev Contract containing constants related to authorization module results.
contract AuthorizationModulesConstants {
    uint256 internal constant VALIDATION_SUCCESS = 0;
    uint256 internal constant SIG_VALIDATION_FAILED = 1;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* solhint-disable no-empty-blocks */

import {IBaseAuthorizationModule} from "../interfaces/modules/IBaseAuthorizationModule.sol";
import {AuthorizationModulesConstants} from "./AuthorizationModulesConstants.sol";

/// @dev Base contract for authorization modules
abstract contract BaseAuthorizationModule is
    IBaseAuthorizationModule,
    AuthorizationModulesConstants
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BaseAuthorizationModule} from "./BaseAuthorizationModule.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Secp256r1, PassKeyId} from "./PasskeyValidationModules/Secp256r1.sol";
import {EIP1271_MAGIC_VALUE} from "contracts/smart-account/interfaces/ISignatureValidator.sol";
import {IPasskeyRegistryModule} from "../interfaces/modules/IPasskeyRegistryModule.sol";
import {ISignatureValidator} from "../interfaces/ISignatureValidator.sol";
import {IAuthorizationModule} from "../interfaces/IAuthorizationModule.sol";

/**
 * @title Passkey ownership Authorization module for Biconomy Smart Accounts.
 * @dev Compatible with Biconomy Modular Interface v 0.2
 *         - It allows to validate user operations signed by passkeys.
 *         - One owner per Smart Account.
 *         For Smart Contract Owners check SmartContractOwnership module instead
 * @author Aman Raj - <[email protected]>
 */
contract PasskeyRegistryModule is
    BaseAuthorizationModule,
    IPasskeyRegistryModule
{
    string public constant NAME = "PassKeys Ownership Registry Module";
    string public constant VERSION = "0.2.0";

    mapping(address => PassKeyId) public smartAccountPassKeys;

    /// @inheritdoc IPasskeyRegistryModule
    function initForSmartAccount(
        uint256 _pubKeyX,
        uint256 _pubKeyY,
        string calldata _keyId
    ) external override returns (address) {
        PassKeyId storage passKeyId = smartAccountPassKeys[msg.sender];

        if (passKeyId.pubKeyX != 0 && passKeyId.pubKeyY != 0)
            revert AlreadyInitedForSmartAccount(msg.sender);

        smartAccountPassKeys[msg.sender] = PassKeyId(
            _pubKeyX,
            _pubKeyY,
            _keyId
        );

        return address(this);
    }

    /// @inheritdoc IAuthorizationModule
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external view virtual returns (uint256) {
        (bytes memory passkeySignature, ) = abi.decode(
            userOp.signature,
            (bytes, address)
        );
        if (_verifySignature(userOpHash, passkeySignature)) {
            return VALIDATION_SUCCESS;
        }
        return SIG_VALIDATION_FAILED;
    }

    /// @inheritdoc ISignatureValidator
    function isValidSignature(
        bytes32 signedDataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        // TODO: @amanraj1608 make it safe
        return isValidSignatureForAddress(signedDataHash, moduleSignature);
    }

    /// @inheritdoc ISignatureValidator
    function isValidSignatureUnsafe(
        bytes32 signedDataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        return isValidSignatureForAddress(signedDataHash, moduleSignature);
    }

    /// @inheritdoc IPasskeyRegistryModule
    function isValidSignatureForAddress(
        bytes32 signedDataHash,
        bytes memory moduleSignature
    ) public view virtual override returns (bytes4) {
        if (_verifySignature(signedDataHash, moduleSignature)) {
            return EIP1271_MAGIC_VALUE;
        }
        return bytes4(0xffffffff);
    }

    /**
     * @dev Internal utility function to verify a signature.
     * @param userOpDataHash The hash of the user operation data.
     * @param moduleSignature The signature provided by the module.
     * @return True if the signature is valid, false otherwise.
     */
    function _verifySignature(
        bytes32 userOpDataHash,
        bytes memory moduleSignature
    ) internal view returns (bool) {
        (
            bytes32 keyHash,
            uint256 sigx,
            uint256 sigy,
            bytes memory authenticatorData,
            string memory clientDataJSONPre,
            string memory clientDataJSONPost
        ) = abi.decode(
                moduleSignature,
                (bytes32, uint256, uint256, bytes, string, string)
            );
        (keyHash);
        string memory opHashBase64 = Base64.encode(
            bytes.concat(userOpDataHash)
        );
        string memory clientDataJSON = string.concat(
            clientDataJSONPre,
            opHashBase64,
            clientDataJSONPost
        );
        bytes32 clientHash = sha256(bytes(clientDataJSON));
        bytes32 sigHash = sha256(bytes.concat(authenticatorData, clientHash));

        PassKeyId memory passKey = smartAccountPassKeys[msg.sender];
        if (passKey.pubKeyX == 0 && passKey.pubKeyY == 0) {
            revert NoPassKeyRegisteredForSmartAccount(msg.sender);
        }
        return Secp256r1.verify(passKey, sigx, sigy, uint256(sigHash));
    }

    /**
     * @dev Internal function to validate a user operation signature.
     * @param userOp The user operation to validate.
     * @param userOpHash The hash of the user operation.
     * @return sigValidationResult Returns 0 if the signature is valid, and SIG_VALIDATION_FAILED otherwise.
     */
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view virtual returns (uint256 sigValidationResult) {
        if (_verifySignature(userOpHash, userOp.signature)) {
            return 0;
        }
        return SIG_VALIDATION_FAILED;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
//
// Initial Implementation by
// https://github.com/itsobvioustech/aa-passkeys-wallet/blob/main/src/Secp256r1.sol
// Heavily inspired from
// https://github.com/maxrobot/elliptic-solidity/blob/master/contracts/Secp256r1.sol
// https://github.com/tdrerup/elliptic-curve-solidity/blob/master/contracts/curves/EllipticCurve.sol
// modified to use precompile 0x05 modexp
// and modified jacobian double
// optimisations to avoid to an from from affine and jacobian coordinates
//
struct PassKeyId {
    uint256 pubKeyX;
    uint256 pubKeyY;
    string keyId;
}

struct JPoint {
    uint256 x;
    uint256 y;
    uint256 z;
}

library Secp256r1 {
    uint256 private constant GX =
        0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 private constant GY =
        0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    uint256 private constant PP =
        0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 private constant NN =
        0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    uint256 private constant A =
        0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    uint256 private constant B =
        0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    uint256 private constant MOST_SIGNIFICANT =
        0xc000000000000000000000000000000000000000000000000000000000000000;

    /*
     * verify
     * @description - verifies that a public key has signed a given message
     * @param X - public key coordinate X
     * @param Y - public key coordinate Y
     * @param R - signature half R
     * @param S - signature half S
     * @param input - hashed message
     */
    function verify(
        PassKeyId memory passKey,
        uint256 r,
        uint256 s,
        uint256 e
    ) internal view returns (bool) {
        if (r == 0 || s == 0 || r >= NN || s >= NN) {
            return false;
        }
        // Verify that the public key is not the point at infinity and lies on the secp256r1 curve.
        if (!isValidPublicKey(passKey.pubKeyX, passKey.pubKeyY)) {
            return false;
        }

        JPoint[16] memory points = preComputeJacobianPoints(passKey);
        return verifyWithPrecompute(points, r, s, e);
    }

    function verifyWithPrecompute(
        JPoint[16] memory points,
        uint256 r,
        uint256 s,
        uint256 e
    ) internal view returns (bool) {
        uint256 w = primemod(s, NN);

        uint256 u1 = mulmod(e, w, NN);
        uint256 u2 = mulmod(r, w, NN);

        uint256 x;
        uint256 y;

        (x, y) = shamirMultJacobian(points, u1, u2);
        return ((x % NN) == r);
    }

    /*
     * Strauss Shamir trick for EC multiplication
     * https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method
     * we optimise on this a bit to do with 2 bits at a time rather than a single bit
     * the individual points for a single pass are precomputed
     * overall this reduces the number of additions while keeping the same number of doublings
     */
    function shamirMultJacobian(
        JPoint[16] memory points,
        uint256 u1,
        uint256 u2
    ) internal view returns (uint256, uint256) {
        uint256 x = 1;
        uint256 y = 1;
        uint256 z = 0;
        uint256 bits = 128;
        uint256 index = 0;

        while (bits > 0) {
            if (z > 0) {
                (x, y, z) = modifiedJacobianDouble(x, y, z);
                (x, y, z) = modifiedJacobianDouble(x, y, z);
            }
            index =
                ((u1 & MOST_SIGNIFICANT) >> 252) |
                ((u2 & MOST_SIGNIFICANT) >> 254);
            if (index > 0) {
                (x, y, z) = jAdd(
                    x,
                    y,
                    z,
                    points[index].x,
                    points[index].y,
                    points[index].z
                );
            }
            u1 <<= 2;
            u2 <<= 2;
            bits--;
        }
        (x, y) = affineFromJacobian(x, y, z);
        return (x, y);
    }

    /**
     * @notice Returns affine coordinates from a jacobian input. Follows the golang elliptic/crypto library convention.
     */
    function affineFromJacobian(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal view returns (uint256 ax, uint256 ay) {
        if (z == 0) {
            return (0, 0);
        }

        uint256 zinv = primemod(z, PP);
        uint256 zinvsq = mulmod(zinv, zinv, PP);

        ax = mulmod(x, zinvsq, PP);
        ay = mulmod(y, mulmod(zinvsq, zinv, PP), PP);
    }

    /**
     * @notice Computes a^(-1) mod p using Fermat's Little Theorem
     * https://en.wikipedia.org/wiki/Fermat%27s_little_theorem
     * - a^(p-1) = 1 mod p
     * - a^(-1) ≅ a^(p-2) (mod p)
     * Uses the precompiled bigModExp to compute a^(-1).
     */
    function primemod(
        uint256 value,
        uint256 p
    ) internal view returns (uint256 ret) {
        ret = modexp(value, p - 2, p);
        return ret;
    }

    /**
     * @notice Wrapper function for built-in BigNumber_modexp (contract 0x5) as described here:
     * - https://github.com/ethereum/EIPs/pull/198
     */
    function modexp(
        uint256 _base,
        uint256 _exp,
        uint256 _mod
    ) internal view returns (uint256 ret) {
        // bigModExp(_base, _exp, _mod);
        assembly {
            if gt(_base, _mod) {
                _base := mod(_base, _mod)
            }
            // Free memory pointer is always stored at 0x40
            let freemem := mload(0x40)

            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)

            mstore(add(freemem, 0x60), _base)
            mstore(add(freemem, 0x80), _exp)
            mstore(add(freemem, 0xa0), _mod)

            let success := staticcall(not(0), 0x5, freemem, 0xc0, freemem, 0x20)
            switch success
            case 0 {
                revert(0x0, 0x0)
            }
            default {
                ret := mload(freemem)
            }
        }
    }

    function isValidPublicKey(
        uint256 x,
        uint256 y
    ) internal pure returns (bool) {
        if (x >= PP || y >= PP) {
            return false; // (x, y) coordinates should satisfy, 0 <= x,y < p
        }
        uint256 lhs = mulmod(y, y, PP); // y^2 mod p
        uint256 rhs = addmod(
            mulmod(addmod(mulmod(x, x, PP), A, PP), x, PP),
            B,
            PP
        ); // (((x^2 + A) * x) + B) mod p https://en.wikipedia.org/wiki/Horner%27s_method

        return lhs == rhs; // y^2 = x^3 + ax + b (mod p)
    }

    function preComputeJacobianPoints(
        PassKeyId memory passKey
    ) internal pure returns (JPoint[16] memory points) {
        // JPoint[] memory u1Points = new JPoint[](4);
        // u1Points[0] = JPoint(1, 1, 0); // point of infinity in jacobian coordinates
        // u1Points[1] = JPoint(GX, GY, 1); // u1
        // u1Points[2] = jPointDouble(u1Points[1]);
        // u1Points[3] = jPointAdd(u1Points[1], u1Points[2]);
        // avoiding this intermediate step by using it in a single array below
        // these are pre computed points for u1

        // JPoint[16] memory points;
        points[0] = JPoint(1, 1, 0);
        points[1] = JPoint(passKey.pubKeyX, passKey.pubKeyY, 1); // u2
        points[2] = jPointDouble(points[1]);
        points[3] = jPointAdd(points[1], points[2]);

        points[4] = JPoint(GX, GY, 1); // u1Points[1]
        points[5] = jPointAdd(points[4], points[1]);
        points[6] = jPointAdd(points[4], points[2]);
        points[7] = jPointAdd(points[4], points[3]);

        points[8] = jPointDouble(points[4]); // u1Points[2]
        points[9] = jPointAdd(points[8], points[1]);
        points[10] = jPointAdd(points[8], points[2]);
        points[11] = jPointAdd(points[8], points[3]);

        points[12] = jPointAdd(points[4], points[8]); // u1Points[3]
        points[13] = jPointAdd(points[12], points[1]);
        points[14] = jPointAdd(points[12], points[2]);
        points[15] = jPointAdd(points[12], points[3]);
    }

    function jPointAdd(
        JPoint memory p1,
        JPoint memory p2
    ) internal pure returns (JPoint memory) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = jAdd(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
        return JPoint(x, y, z);
    }

    function jPointDouble(
        JPoint memory p
    ) internal pure returns (JPoint memory) {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = modifiedJacobianDouble(p.x, p.y, p.z);
        return JPoint(x, y, z);
    }

    /*
     * jAdd
     * @description performs double Jacobian as defined below:
     * https://hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-add-1998-cmo-2
     */
    function jAdd(
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 q1,
        uint256 q2,
        uint256 q3
    ) internal pure returns (uint256 r1, uint256 r2, uint256 r3) {
        if (p3 == 0) {
            return (q1, q2, q3);
        } else if (q3 == 0) {
            return (p1, p2, p3);
        }

        uint256 u1;
        uint256 u2;
        uint256 s1;
        uint256 s2;
        assembly {
            let
                pd
            := 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
            let z1z1 := mulmod(p3, p3, pd) // Z1Z1 = Z1^2
            let z2z2 := mulmod(q3, q3, pd) // Z2Z2 = Z2^2

            u1 := mulmod(p1, z2z2, pd) // U1 = X1*Z2Z2
            u2 := mulmod(q1, z1z1, pd) // U2 = X2*Z1Z1

            s1 := mulmod(p2, mulmod(z2z2, q3, pd), pd) // S1 = Y1*Z2*Z2Z2
            s2 := mulmod(q2, mulmod(z1z1, p3, pd), pd) // S2 = Y2*Z1*Z1Z1

            if lt(u2, u1) {
                u2 := add(pd, u2) // u2 = u2+pd
            }
            let h := sub(u2, u1) // H = U2-U1

            let i := mulmod(h, h, pd) // I = H^2

            let j := mulmod(h, i, pd) // J = H^3
            if lt(s2, s1) {
                s2 := add(pd, s2) // u2 = u2+pd
            }
            let rr := sub(s2, s1) // R = (S2-S1)
            r1 := mulmod(rr, rr, pd) // r1 = R^2

            let v := mulmod(u1, i, pd) // V = U1*I = U1*H^2
            let j2v := addmod(j, mulmod(0x02, v, pd), pd) // j2v = H^3 + 2*U1*H^2

            if lt(r1, j2v) {
                r1 := add(pd, r1) // X3 = X3+pd
            }
            r1 := sub(r1, j2v)

            let s12j := mulmod(s1, j, pd) // s12j = S1*H^3

            if lt(v, r1) {
                v := add(pd, v)
            }
            r2 := mulmod(rr, sub(v, r1), pd) // (U1*H^2 - r1)*R

            if lt(r2, s12j) {
                r2 := add(pd, r2)
            }
            r2 := sub(r2, s12j)

            r3 := mulmod(mulmod(p3, q3, pd), h, pd)
        }
        if ((u1 == u2) && (s1 == s2)) {
            (r1, r2, r3) = modifiedJacobianDouble(p1, p2, p3);
            return (r1, r2, r3);
        }
        return (r1, r2, r3);
    }

    // Point doubling on the modified jacobian coordinates
    // http://point-at-infinity.org/ecc/Prime_Curve_Modified_Jacobian_Coordinates.html
    function modifiedJacobianDouble(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256 x3, uint256 y3, uint256 z3) {
        assembly {
            let
                pd
            := 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF
            let z2 := mulmod(z, z, pd)
            let az4 := mulmod(
                0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC,
                mulmod(z2, z2, pd),
                pd
            )
            let y2 := mulmod(y, y, pd)
            let s := mulmod(0x04, mulmod(x, y2, pd), pd)
            let u := mulmod(0x08, mulmod(y2, y2, pd), pd)
            let m := addmod(mulmod(0x03, mulmod(x, x, pd), pd), az4, pd)
            let twos := mulmod(0x02, s, pd)
            let m2 := mulmod(m, m, pd)
            if lt(m2, twos) {
                m2 := add(pd, m2)
            }
            x3 := sub(m2, twos)
            if lt(s, x3) {
                s := add(pd, s)
            }
            y3 := mulmod(m, sub(s, x3), pd)
            if lt(y3, u) {
                y3 := add(pd, y3)
            }
            y3 := sub(y3, u)
            z3 := mulmod(0x02, mulmod(y, z, pd), pd)
        }
    }
}