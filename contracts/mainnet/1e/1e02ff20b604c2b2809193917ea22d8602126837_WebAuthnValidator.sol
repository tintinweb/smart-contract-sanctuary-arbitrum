// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {UserOperation} from "I4337/interfaces/UserOperation.sol";
import {IKernelValidator} from "kernel/src/interfaces/IKernelValidator.sol";
import {ValidationData} from "kernel/src/common/Types.sol";
import {SIG_VALIDATION_FAILED} from "kernel/src/common/Constants.sol";
import {WebAuthn} from "./WebAuthn.sol";

struct WebAuthnValidatorData {
    uint256 pubKeyX;
    uint256 pubKeyY;
}

/**
 * @title WebAuthnValidator
 * @notice This validator uses the P256 curve to validate signatures.
 */
contract WebAuthnValidator is IKernelValidator {
    uint256 constant CHALLENGE_LOCATION = 23;

    // Emitted when a bad key is provided.
    error InvalidPublicKey();

    // Emitted when the public key of a kernel is changed.
    event WebAuthnPublicKeyChanged(
        address indexed kernel, bytes32 indexed authenticatorIdHash, uint256 pubKeyX, uint256 pubKeyY
    );

    // The P256 public keys of a kernel.
    mapping(address kernel => WebAuthnValidatorData WebAuthnValidatorData) public webAuthnValidatorStorage;

    /**
     * @notice Enable WebAuthn validator for a kernel account.
     * @dev The kernel account need to be the `msg.sender`.
     * @dev The public key is encoded as `abi.encode(WebAuthnValidatorData)` inside the data, so (uint256,uint256).
     */
    function enable(bytes calldata _data) external payable override {
        // check validity of the public key
        (WebAuthnValidatorData memory webAuthnData, bytes32 authenticatorIdHash) =
            abi.decode(_data, (WebAuthnValidatorData, bytes32));
        if (webAuthnData.pubKeyX == 0 || webAuthnData.pubKeyY == 0) {
            revert InvalidPublicKey();
        }
        // Update the key (so a sstore)
        webAuthnValidatorStorage[msg.sender] = webAuthnData;
        // And emit the event
        emit WebAuthnPublicKeyChanged(msg.sender, authenticatorIdHash, webAuthnData.pubKeyX, webAuthnData.pubKeyY);
    }

    /**
     * @notice Disable WebAuthn validator for a kernel account.
     * @dev The kernel account need to be the `msg.sender`.
     */
    function disable(bytes calldata) external payable override {
        delete webAuthnValidatorStorage[msg.sender];
    }

    /**
     * @notice Validate a user operation.
     */
    function validateUserOp(UserOperation calldata _userOp, bytes32 _userOpHash, uint256)
        external
        payable
        override
        returns (ValidationData)
    {
        return _verifySignature(_userOp.sender, _userOpHash, _userOp.signature);
    }

    /**
     * @notice Validate a signature.
     */
    function validateSignature(bytes32 hash, bytes calldata signature)
        external
        view
        override
        returns (ValidationData)
    {
        return _verifySignature(msg.sender, hash, signature);
    }

    /**
     * @notice Verify a signature.
     */
    function _verifySignature(address sender, bytes32 hash, bytes calldata signature)
        private
        view
        returns (ValidationData)
    {
        // decode the signature
        (
            bytes memory authenticatorData,
            string memory clientDataJSON,
            uint256 responseTypeLocation,
            uint256 r,
            uint256 s,
            bool usePrecompiled
        ) = abi.decode(signature, (bytes, string, uint256, uint256, uint256, bool));

        // get the public key from storage
        WebAuthnValidatorData memory webAuthnData = webAuthnValidatorStorage[sender];

        // verify the signature using the signature and the public key
        bool isValid = WebAuthn.verifySignature(
            abi.encodePacked(hash),
            authenticatorData,
            true,
            clientDataJSON,
            CHALLENGE_LOCATION,
            responseTypeLocation,
            r,
            s,
            webAuthnData.pubKeyX,
            webAuthnData.pubKeyY,
            usePrecompiled
        );

        // return the validation data
        if (isValid) {
            return ValidationData.wrap(0);
        }

        return SIG_VALIDATION_FAILED;
    }

    function validCaller(address, bytes calldata) external pure override returns (bool) {
        revert NotImplemented();
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/Base64URL.sol";
import "./P256.sol";

/**
 * Helper library for external contracts to verify WebAuthn signatures.
 *
 */
library WebAuthn {
    /// Checks whether substr occurs in str starting at a given byte offset.
    function contains(string memory substr, string memory str, uint256 location) internal pure returns (bool) {
        bytes memory substrBytes = bytes(substr);
        bytes memory strBytes = bytes(str);

        uint256 substrLen = substrBytes.length;
        uint256 strLen = strBytes.length;

        for (uint256 i = 0; i < substrLen; i++) {
            if (location + i >= strLen) {
                return false;
            }

            if (substrBytes[i] != strBytes[location + i]) {
                return false;
            }
        }

        return true;
    }

    bytes1 constant AUTH_DATA_FLAGS_UP = 0x01; // Bit 0
    bytes1 constant AUTH_DATA_FLAGS_UV = 0x04; // Bit 2
    bytes1 constant AUTH_DATA_FLAGS_BE = 0x08; // Bit 3
    bytes1 constant AUTH_DATA_FLAGS_BS = 0x10; // Bit 4

    /// Verifies the authFlags in authenticatorData. Numbers in inline comment
    /// correspond to the same numbered bullets in
    /// https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion.
    function checkAuthFlags(bytes1 flags, bool requireUserVerification) internal pure returns (bool) {
        // 17. Verify that the UP bit of the flags in authData is set.
        if (flags & AUTH_DATA_FLAGS_UP != AUTH_DATA_FLAGS_UP) {
            return false;
        }

        // 18. If user verification was determined to be required, verify that
        // the UV bit of the flags in authData is set. Otherwise, ignore the
        // value of the UV flag.
        if (requireUserVerification && (flags & AUTH_DATA_FLAGS_UV) != AUTH_DATA_FLAGS_UV) {
            return false;
        }

        // 19. If the BE bit of the flags in authData is not set, verify that
        // the BS bit is not set.
        if (flags & AUTH_DATA_FLAGS_BE != AUTH_DATA_FLAGS_BE) {
            if (flags & AUTH_DATA_FLAGS_BS == AUTH_DATA_FLAGS_BS) {
                return false;
            }
        }

        return true;
    }

    /**
     * Verifies a Webauthn P256 signature (Authentication Assertion) as described
     * in https://www.w3.org/TR/webauthn-2/#sctn-verifying-assertion. We do not
     * verify all the steps as described in the specification, only ones relevant
     * to our context. Please carefully read through this list before usage.
     * Specifically, we do verify the following:
     * - Verify that authenticatorData (which comes from the authenticator,
     *   such as iCloud Keychain) indicates a well-formed assertion. If
     *   requireUserVerification is set, checks that the authenticator enforced
     *   user verification. User verification should be required if,
     *   and only if, options.userVerification is set to required in the request
     * - Verifies that the client JSON is of type "webauthn.get", i.e. the client
     *   was responding to a request to assert authentication.
     * - Verifies that the client JSON contains the requested challenge.
     * - Finally, verifies that (r, s) constitute a valid signature over both
     *   the authenicatorData and client JSON, for public key (x, y).
     *
     * We make some assumptions about the particular use case of this verifier,
     * so we do NOT verify the following:
     * - Does NOT verify that the origin in the clientDataJSON matches the
     *   Relying Party's origin: It is considered the authenticator's
     *   responsibility to ensure that the user is interacting with the correct
     *   RP. This is enforced by most high quality authenticators properly,
     *   particularly the iCloud Keychain and Google Password Manager were
     *   tested.
     * - Does NOT verify That c.topOrigin is well-formed: We assume c.topOrigin
     *   would never be present, i.e. the credentials are never used in a
     *   cross-origin/iframe context. The website/app set up should disallow
     *   cross-origin usage of the credentials. This is the default behaviour for
     *   created credentials in common settings.
     * - Does NOT verify that the rpIdHash in authData is the SHA-256 hash of an
     *   RP ID expected by the Relying Party: This means that we rely on the
     *   authenticator to properly enforce credentials to be used only by the
     *   correct RP. This is generally enforced with features like Apple App Site
     *   Association and Google Asset Links. To protect from edge cases in which
     *   a previously-linked RP ID is removed from the authorised RP IDs,
     *   we recommend that messages signed by the authenticator include some
     *   expiry mechanism.
     * - Does NOT verify the credential backup state: This assumes the credential
     *   backup state is NOT used as part of Relying Party business logic or
     *   policy.
     * - Does NOT verify the values of the client extension outputs: This assumes
     *   that the Relying Party does not use client extension outputs.
     * - Does NOT verify the signature counter: Signature counters are intended
     *   to enable risk scoring for the Relying Party. This assumes risk scoring
     *   is not used as part of Relying Party business logic or policy.
     * - Does NOT verify the attestation object: This assumes that
     *   response.attestationObject is NOT present in the response, i.e. the
     *   RP does not intend to verify an attestation.
     */
    function verifySignature(
        bytes memory challenge,
        bytes memory authenticatorData,
        bool requireUserVerification,
        string memory clientDataJSON,
        uint256 challengeLocation,
        uint256 responseTypeLocation,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y,
        bool usePrecompiled
    ) internal view returns (bool) {
        /// @notice defer the result to the end so dummy signature can go through all verification process including p256.verifySignature
        bool deferredResult = true;

        // Check that authenticatorData has good flags
        if (authenticatorData.length < 37 || !checkAuthFlags(authenticatorData[32], requireUserVerification)) {
            deferredResult = false;
        }

        // Check that response is for an authentication assertion
        string memory responseType = '"type":"webauthn.get"';
        if (!contains(responseType, clientDataJSON, responseTypeLocation)) {
            deferredResult = false;
        }

        // Check that challenge is in the clientDataJSON
        string memory challengeB64url = Base64URL.encode(challenge);
        string memory challengeProperty = string.concat('"challenge":"', challengeB64url, '"');

        if (!contains(challengeProperty, clientDataJSON, challengeLocation)) {
            deferredResult = false;
        }

        // Check that the public key signed sha256(authenticatorData || sha256(clientDataJSON))
        bytes32 clientDataJSONHash = sha256(bytes(clientDataJSON));
        bytes32 messageHash = sha256(abi.encodePacked(authenticatorData, clientDataJSONHash));

        bool verified = P256.verifySignature(messageHash, r, s, x, y, usePrecompiled);

        if (verified && deferredResult) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/Base64.sol";

library Base64URL {
    function encode(bytes memory data) internal pure returns (string memory) {
        string memory strb64 = Base64.encode(data);
        bytes memory b64 = bytes(strb64);

        // Base64 can end with "=" or "=="; Base64URL has no padding.
        uint256 equalsCount = 0;
        if (b64.length > 2 && b64[b64.length - 2] == "=") equalsCount = 2;
        else if (b64.length > 1 && b64[b64.length - 1] == "=") equalsCount = 1;

        uint256 len = b64.length - equalsCount;
        bytes memory result = new bytes(len);

        for (uint256 i = 0; i < len; i++) {
            if (b64[i] == "+") {
                result[i] = "-";
            } else if (b64[i] == "/") {
                result[i] = "_";
            } else {
                result[i] = b64[i];
            }
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Helper library for external contracts to verify P256 signatures.
 *
 */
library P256 {
    address constant DAIMO_VERIFIER = 0xc2b78104907F722DABAc4C69f826a522B2754De4;
    address constant PRECOMPILED_VERIFIER = 0x0000000000000000000000000000000000000100;

    function verifySignatureAllowMalleability(
        bytes32 message_hash,
        uint256 r,
        uint256 s,
        uint256 x,
        uint256 y,
        bool usePrecompiled
    ) internal view returns (bool) {
        bytes memory args = abi.encode(message_hash, r, s, x, y);

        if (usePrecompiled) {
            (bool success, bytes memory ret) = PRECOMPILED_VERIFIER.staticcall(args);
            if (success == false || ret.length == 0) {
                return false;
            }
            return abi.decode(ret, (uint256)) == 1;
        } else {
            (bool success, bytes memory ret) = DAIMO_VERIFIER.staticcall(args);
            assert(success); // never reverts, always returns 0 or 1
            return abi.decode(ret, (uint256)) == 1;
        }
    }

    /// P256 curve order n/2 for malleability check
    uint256 constant P256_N_DIV_2 = 57896044605178124381348723474703786764998477612067880171211129530534256022184;

    function verifySignature(bytes32 message_hash, uint256 r, uint256 s, uint256 x, uint256 y, bool usePrecompiled)
        internal
        view
        returns (bool)
    {
        // check for signature malleability
        if (s > P256_N_DIV_2) {
            return false;
        }

        return verifySignatureAllowMalleability(message_hash, r, s, x, y, usePrecompiled);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Base64.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
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