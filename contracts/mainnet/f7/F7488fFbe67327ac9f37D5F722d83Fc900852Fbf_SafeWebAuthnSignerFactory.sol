// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import {ISafeSignerFactory} from "./interfaces/ISafeSignerFactory.sol";
import {SafeWebAuthnSignerProxy} from "./SafeWebAuthnSignerProxy.sol";
import {SafeWebAuthnSignerSingleton} from "./SafeWebAuthnSignerSingleton.sol";
import {P256} from "./libraries/P256.sol";

/**
 * @title Safe WebAuthn Signer Factory
 * @dev A factory contract for creating WebAuthn signers. Additionally, the factory supports
 * signature verification without deploying a signer proxies.
 * @custom:security-contact [email protected]
 */
contract SafeWebAuthnSignerFactory is ISafeSignerFactory {
    /**
     * @notice The {SafeWebAuthnSignerSingleton} implementation to that is used for signature
     * verification by this contract and any proxies it deploys.
     */
    SafeWebAuthnSignerSingleton public immutable SINGLETON;

    /**
     * @notice Creates a new WebAuthn Safe signer factory contract.
     * @dev The {SafeWebAuthnSignerSingleton} singleton implementation is created with as part of
     * this constructor. This ensures that the singleton contract is known, and lets us make certain
     * assumptions about how it works.
     */
    constructor() {
        SINGLETON = new SafeWebAuthnSignerSingleton();
    }

    /**
     * @inheritdoc ISafeSignerFactory
     */
    function getSigner(uint256 x, uint256 y, P256.Verifiers verifiers) public view override returns (address signer) {
        bytes32 codeHash = keccak256(
            abi.encodePacked(
                type(SafeWebAuthnSignerProxy).creationCode,
                uint256(uint160(address(SINGLETON))),
                x,
                y,
                uint256(P256.Verifiers.unwrap(verifiers))
            )
        );
        signer = address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(this), bytes32(0), codeHash)))));
    }

    /**
     * @inheritdoc ISafeSignerFactory
     */
    function createSigner(uint256 x, uint256 y, P256.Verifiers verifiers) external returns (address signer) {
        signer = getSigner(x, y, verifiers);

        if (_hasNoCode(signer)) {
            SafeWebAuthnSignerProxy created = new SafeWebAuthnSignerProxy{salt: bytes32(0)}(address(SINGLETON), x, y, verifiers);
            assert(address(created) == signer);
            emit Created(signer, x, y, verifiers);
        }
    }

    /**
     * @inheritdoc ISafeSignerFactory
     */
    function isValidSignatureForSigner(
        bytes32 message,
        bytes calldata signature,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) external view override returns (bytes4 magicValue) {
        address singleton = address(SINGLETON);
        bytes memory data = abi.encodePacked(
            abi.encodeWithSignature("isValidSignature(bytes32,bytes)", message, signature),
            x,
            y,
            verifiers
        );

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // staticcall to the singleton contract with return size given as 32 bytes. The
            // singleton contract is known and immutable so it is safe to specify return size.
            if staticcall(gas(), singleton, add(data, 0x20), mload(data), 0, 32) {
                magicValue := mload(0)
            }
        }
    }

    /**
     * @dev Checks if the provided account has no code.
     * @param account The address of the account to check.
     * @return result True if the account has no code, false otherwise.
     */
    function _hasNoCode(address account) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            result := iszero(extcodesize(account))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
/* solhint-disable no-complex-fallback */
pragma solidity >=0.8.0;

import {P256} from "./libraries/WebAuthn.sol";

/**
 * @title Safe WebAuthn Signer Proxy
 * @dev A specialized proxy to a {SafeWebAuthnSignerSingleton} signature validator implementation
 * for Safe accounts. Using a proxy pattern for the signature validator greatly reduces deployment
 * gas costs.
 * @custom:security-contact [email protected]
 */
contract SafeWebAuthnSignerProxy {
    /**
     * @notice The {SafeWebAuthnSignerSingleton} implementation to proxy to.
     */
    address internal immutable _SINGLETON;

    /**
     * @notice The x coordinate of the P-256 public key of the WebAuthn credential.
     */
    uint256 internal immutable _X;

    /**
     * @notice The y coordinate of the P-256 public key of the WebAuthn credential.
     */
    uint256 internal immutable _Y;

    /**
     * @notice The P-256 verifiers used for ECDSA signature verification.
     */
    P256.Verifiers internal immutable _VERIFIERS;

    /**
     * @notice Creates a new WebAuthn Safe Signer Proxy.
     * @param singleton The {SafeWebAuthnSignerSingleton} implementation to proxy to.
     * @param x The x coordinate of the P-256 public key of the WebAuthn credential.
     * @param y The y coordinate of the P-256 public key of the WebAuthn credential.
     * @param verifiers The P-256 verifiers used for ECDSA signature verification.
     */
    constructor(address singleton, uint256 x, uint256 y, P256.Verifiers verifiers) {
        _SINGLETON = singleton;
        _X = x;
        _Y = y;
        _VERIFIERS = verifiers;
    }

    /**
     * @dev Fallback function forwards all transactions and returns all received return data.
     */
    fallback() external payable {
        address singleton = _SINGLETON;
        uint256 x = _X;
        uint256 y = _Y;
        P256.Verifiers verifiers = _VERIFIERS;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Forward the call to the singleton implementation. We append the configuration to the
            // calldata instead of having the singleton implementation read it from storage. This is
            // both more gas efficient and required for ERC-4337 compatibility. Note that we append
            // the configuration fields in reverse order since the fields are packed, and this makes
            // it so we don't need to mask any bits from the `verifiers` value. This computes `data`
            // to be `abi.encodePacked(msg.data, x, y, verifiers)`.
            let data := mload(0x40)
            mstore(add(data, add(calldatasize(), 0x36)), verifiers)
            mstore(add(data, add(calldatasize(), 0x20)), y)
            mstore(add(data, calldatasize()), x)
            calldatacopy(data, 0x00, calldatasize())

            let success := delegatecall(gas(), singleton, data, add(calldatasize(), 0x56), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import {SignatureValidator} from "./base/SignatureValidator.sol";
import {P256, WebAuthn} from "./libraries/WebAuthn.sol";

/**
 * @title Safe WebAuthn Signer Singleton
 * @dev A singleton contract that implements WebAuthn signature verification. This singleton
 * contract must be used with the specialized proxy {SafeWebAuthnSignerProxy}, as it encodes the
 * credential configuration (public key coordinates and P-256 verifier to use) in calldata, which is
 * required by this implementation.
 * @custom:security-contact [email protected]
 */
contract SafeWebAuthnSignerSingleton is SignatureValidator {
    /**
     * @inheritdoc SignatureValidator
     */
    function _verifySignature(bytes32 message, bytes calldata signature) internal view virtual override returns (bool success) {
        (uint256 x, uint256 y, P256.Verifiers verifiers) = getConfiguration();
        success = WebAuthn.verifySignature(message, signature, WebAuthn.USER_VERIFICATION, x, y, verifiers);
    }

    /**
     * @notice Returns the x coordinate, y coordinate, and P-256 verifiers used for ECDSA signature
     * validation. The values are expected to appended to calldata by the caller. See the
     * {SafeWebAuthnSignerProxy} contract implementation.
     * @return x The x coordinate of the P-256 public key.
     * @return y The y coordinate of the P-256 public key.
     * @return verifiers The P-256 verifiers.
     */
    function getConfiguration() public pure returns (uint256 x, uint256 y, P256.Verifiers verifiers) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            x := calldataload(sub(calldatasize(), 86))
            y := calldataload(sub(calldatasize(), 54))
            verifiers := shr(80, calldataload(sub(calldatasize(), 22)))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC1271} from "../libraries/ERC1271.sol";

/**
 * @title Signature Validator Base Contract
 * @dev A interface for smart contract Safe owners that supports multiple ERC-1271 `isValidSignature` versions.
 * @custom:security-contact [email protected]
 */
abstract contract SignatureValidator {
    /**
     * @dev Validates the signature for the given data.
     * @param data The signed data bytes.
     * @param signature The signature to be validated.
     * @return magicValue The magic value indicating the validity of the signature.
     */
    function isValidSignature(bytes memory data, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (_verifySignature(keccak256(data), signature)) {
            magicValue = ERC1271.LEGACY_MAGIC_VALUE;
        }
    }

    /**
     * @dev Validates the signature for a given data hash.
     * @param message The signed message.
     * @param signature The signature to be validated.
     * @return magicValue The magic value indicating the validity of the signature.
     */
    function isValidSignature(bytes32 message, bytes calldata signature) external view returns (bytes4 magicValue) {
        if (_verifySignature(message, signature)) {
            magicValue = ERC1271.MAGIC_VALUE;
        }
    }

    /**
     * @dev Verifies a signature.
     * @param message The signed message.
     * @param signature The signature to be validated.
     * @return success Whether the signature is valid.
     */
    function _verifySignature(bytes32 message, bytes calldata signature) internal view virtual returns (bool success);
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

import {P256} from "../libraries/P256.sol";

/**
 * @title Signer Factory for Custom P-256 Signing Schemes
 * @dev Interface for a factory contract that can create ERC-1271 compatible signers, and verify
 * signatures for custom P-256 signing schemes.
 * @custom:security-contact [email protected]
 */
interface ISafeSignerFactory {
    /**
     * @notice Emitted when a new signer is created.
     * @param signer The signer address.
     * @param x The x-coordinate of the public key.
     * @param y The y-coordinate of the public key.
     * @param verifiers The P-256 verifiers to use.
     */
    event Created(address signer, uint256 x, uint256 y, P256.Verifiers verifiers);

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
     * @dev This is the packed `uint16(precompile) | uint160(fallback)` addresses to use for the
     * verifiers. This allows both a precompile and a fallback Solidity implementation of the P-256
     * curve to be specified. For networks where the P-256 precompile is planned to be enabled but
     * not yet available, this allows for a verifier to seamlessly start using the precompile once
     * it becomes available.
     */
    type Verifiers is uint176;

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {P256} from "./P256.sol";

/**
 * @title WebAuthn Signature Verification
 * @dev Library for verifying WebAuthn signatures for public key credentials using the ES256
 * algorithm with the P-256 curve.
 * @custom:security-contact [email protected]
 */
library WebAuthn {
    using P256 for P256.Verifiers;

    /**
     * @notice The WebAuthn signature data format.
     * @dev WebAuthn signatures are expected to be the ABI-encoded bytes of the following structure.
     * @param authenticatorData The authenticator data from the WebAuthn credential assertion.
     * @param clientDataFields The additional fields from the client data JSON. This is the comma
     * separated fields as they appear in the client data JSON from the WebAuthn credential
     * assertion after the leading {type} and {challenge} fields.
     * @param r The ECDSA signature's R component.
     * @param s The ECDSA signature's S component.
     */
    struct Signature {
        bytes authenticatorData;
        string clientDataFields;
        uint256 r;
        uint256 s;
    }

    /**
     * @notice A WebAuthn authenticator bit-flags
     * @dev Represents flags that are included in a WebAuthn assertion's authenticator data and can
     * be used to check on-chain how the user was authorized by the device when signing.
     */
    type AuthenticatorFlags is bytes1;

    /**
     * @notice Authenticator data flag indicating user presence (UP).
     * @dev A test of user presence is a simple form of authorization gesture and technical process
     * where a user interacts with an authenticator by (typically) simply touching it (other
     * modalities may also exist), yielding a Boolean result. Note that this does not constitute
     * user verification because a user presence test, by definition, is not capable of biometric
     * recognition, nor does it involve the presentation of a shared secret such as a password or
     * PIN.
     *
     * See <https://www.w3.org/TR/webauthn-2/#test-of-user-presence>.
     */
    AuthenticatorFlags internal constant USER_PRESENCE = AuthenticatorFlags.wrap(0x01);

    /**
     * @notice Authenticator data flag indicating user verification (UV).
     * @dev The technical process by which an authenticator locally authorizes the invocation of the
     * authenticatorMakeCredential and authenticatorGetAssertion operations. User verification MAY
     * be instigated through various authorization gesture modalities; for example, through a touch
     * plus pin code, password entry, or biometric recognition (e.g., presenting a fingerprint). The
     * intent is to distinguish individual users.
     *
     * Note that user verification does not give the Relying Party a concrete identification of the
     * user, but when 2 or more ceremonies with user verification have been done with that
     * credential it expresses that it was the same user that performed all of them. The same user
     * might not always be the same natural person, however, if multiple natural persons share
     * access to the same authenticator.
     *
     * See <https://www.w3.org/TR/webauthn-2/#user-verification>.
     */
    AuthenticatorFlags internal constant USER_VERIFICATION = AuthenticatorFlags.wrap(0x04);

    /**
     * @notice Casts calldata bytes to a WebAuthn signature data structure.
     * @param signature The calldata bytes of the WebAuthn signature.
     * @return isValid Whether or not the encoded signature bytes is valid.
     * @return data A pointer to the signature data in calldata.
     * @dev This method casts the dynamic bytes array to a signature calldata pointer with some
     * additional verification. Specifically, we ensure that the signature bytes encoding is no
     * larger than standard ABI encoding form, to prevent attacks where valid signatures are padded
     * with 0s in order to increase signature verifications the costs for ERC-4337 user operations.
     */
    function castSignature(bytes calldata signature) internal pure returns (bool isValid, Signature calldata data) {
        uint256 authenticatorDataLength;
        uint256 clientDataFieldsLength;

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            data := signature.offset

            // Read the lengths of the dynamic byte arrays in assembly. This is done because
            // Solidity generates calldata bounds checks which aren't required for the security of
            // the signature verification, as it can only lead to _shorter_ signatures which are
            // are less gas expensive anyway.
            authenticatorDataLength := calldataload(add(data, calldataload(data)))
            clientDataFieldsLength := calldataload(add(data, calldataload(add(data, 0x20))))
        }

        // Use of unchecked math as any overflows in dynamic length computations would cause
        // out-of-gas reverts when computing the WebAuthn signing message.
        unchecked {
            // Allow for signature encodings where the dynamic bytes are aligned to 32-byte
            // boundaries. This allows for high interoperability (as this is how Solidity and most
            // tools `abi.encode`s the `Signature` struct) while setting a strict upper bound to how
            // many additional padding bytes can be added to the signature, increasing gas costs.
            // Note that we compute the aligned lengths with the formula: `l + 0x1f & ~0x1f`, which
            // rounds `l` up to the next 32-byte boundary.
            uint256 alignmentMask = ~uint256(0x1f);
            uint256 authenticatorDataAlignedLength = (authenticatorDataLength + 0x1f) & alignmentMask;
            uint256 clientDataFieldsAlignedLength = (clientDataFieldsLength + 0x1f) & alignmentMask;

            // The fixed parts of the signature length are 6 32-byte words for a total of 192 bytes:
            // - offset of the `authenticatorData` bytes
            // - offset of the `clientDataFields` string
            // - signature `r` value
            // - signature `s` value
            // - length of the `authenticatorData` bytes
            // - length of the `clientDataFields` string
            //
            // This implies that the signature length must be less than or equal to:
            //      192 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength
            // which is equivalent to strictly less than:
            //      193 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength
            isValid = signature.length < 193 + authenticatorDataAlignedLength + clientDataFieldsAlignedLength;
        }
    }

    /**
     * @notice Encodes the client data JSON string from the specified challenge, and additional
     * client data fields.
     * @dev The client data JSON follows a very specific encoding process outlined in the Web
     * Authentication standard. See <https://w3c.github.io/webauthn/#clientdatajson-serialization>.
     * @param challenge The WebAuthn challenge used for the credential assertion.
     * @param clientDataFields Client data fields.
     * @return clientDataJson The encoded client data JSON.
     */
    function encodeClientDataJson(
        bytes32 challenge,
        string calldata clientDataFields
    ) internal pure returns (string memory clientDataJson) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The length of the encoded JSON string. This is always 82 plus the length of the
            // additional client data fields:
            // - 36 bytes for: `{"type":"webauthn.get","challenge":"`
            // - 43 bytes for base-64 encoding of 32 bytes of data
            // - 2 bytes for: `",`
            // - `clientDataFields.length` bytes for the additional client data JSON fields
            // - 1 byte for: `}`
            let encodedLength := add(82, clientDataFields.length)

            // Set `clientDataJson` return parameter to point to the start of the free memory.
            // This is where the encoded JSON will be stored.
            clientDataJson := mload(0x40)

            // Write the constant bytes of the encoded client data JSON string as per the JSON
            // serialization specification. Note that we write the data backwards, this is to avoid
            // overwriting previously written data with zeros. Offsets are computed to account for
            // both the leading 32-byte length and leading zeros from the constants.
            mstore(add(clientDataJson, encodedLength), 0x7d) // }
            mstore(add(clientDataJson, 81), 0x222c) // ",
            mstore(add(clientDataJson, 36), 0x2c226368616c6c656e6765223a22) // ,"challenge":"
            mstore(add(clientDataJson, 22), 0x7b2274797065223a22776562617574686e2e67657422) // {"type":"webauthn.get"
            mstore(clientDataJson, encodedLength)

            // Copy the client data fields from calldata to their reserved space in memory.
            calldatacopy(add(clientDataJson, 113), clientDataFields.offset, clientDataFields.length)

            // Store the base-64 URL character lookup table into the scratch and free memory pointer
            // space in memory [^1]. The table is split into two 32-byte parts and stored in memory
            // from address 0x1f to 0x5e. Note that the offset is chosen in such a way that the
            // least significant byte of `mload(x)` is the base-64 ASCII character for the 6-bit
            // value `x`. We will write the free memory pointer at address `0x40` before leaving the
            // assembly block accounting for the allocation of `clientDataJson`.
            //
            // - [^1](https://docs.soliditylang.org/en/stable/internals/layout_in_memory.html).
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789-_")

            // Initialize a pointer for writing the base-64 encoded challenge.
            let ptr := add(clientDataJson, 68)

            // Base-64 encode the challenge to its reserved space in memory.
            //
            // To minimize stack and jump operations, we partially unroll the loop. With full 6
            // iterations of the loop, we need to encode seven 6-bit groups and one 4-bit group. In
            // total, it encodes 6 iterations * 7 groups * 6 bits = 252 bits. The remaining 4-bit
            // group is encoded after the loop. `i` is initialized to 250, which is the number of
            // bits by which we need to shift the data to get the first 6-bit group, and then we
            // subtract 6 to get the next 6-bit group.
            //
            // We want to exit when all full 6 bits groups are encoded. After 6 iterations, `i` will
            // be -2 and the **signed** comparison with 0 will break the loop.
            for {
                let i := 250
            } sgt(i, 0) {
                // Advance the pointer by the number of bytes written (7 bytes in this case).
                ptr := add(ptr, 7)
                // Move `i` by 42 = 6 bits * 7 (groups processed in each iteration).
                i := sub(i, 42)
            } {
                // Encode 6-bit groups into characters by looking them up in the character table.
                // 0x3f is a mask to get the last 6 bits so that we can index directly to the
                // base-64 lookup table.
                mstore8(ptr, mload(and(shr(i, challenge), 0x3f)))
                mstore8(add(ptr, 1), mload(and(shr(sub(i, 6), challenge), 0x3f)))
                mstore8(add(ptr, 2), mload(and(shr(sub(i, 12), challenge), 0x3f)))
                mstore8(add(ptr, 3), mload(and(shr(sub(i, 18), challenge), 0x3f)))
                mstore8(add(ptr, 4), mload(and(shr(sub(i, 24), challenge), 0x3f)))
                mstore8(add(ptr, 5), mload(and(shr(sub(i, 30), challenge), 0x3f)))
                mstore8(add(ptr, 6), mload(and(shr(sub(i, 36), challenge), 0x3f)))
            }

            // Encode the final 4-bit group, where 0x0f is a mask to get the last 4 bits.
            mstore8(ptr, mload(shl(2, and(challenge, 0x0f))))

            // Update the free memory pointer to point to the end of the encoded string.
            // Store the length of the encoded string at the beginning of `result`.
            mstore(0x40, and(add(clientDataJson, add(encodedLength, 0x3f)), not(0x1f)))
        }
    }

    /**
     * @notice Encodes the message that is signed in a WebAuthn assertion.
     * @dev The signing message is defined to be the concatenation of the authenticator data bytes
     * with the 32-byte SHA-256 digest of the client data JSON. The hashing algorithm used on the
     * signing message itself depends on the public key algorithm that was selected on WebAuthn
     * credential creation.
     * @param challenge The WebAuthn challenge used for the credential assertion.
     * @param authenticatorData Authenticator data.
     * @param clientDataFields Client data fields.
     * @return message Signing message bytes.
     */
    function encodeSigningMessage(
        bytes32 challenge,
        bytes calldata authenticatorData,
        string calldata clientDataFields
    ) internal view returns (bytes memory message) {
        string memory clientDataJson = encodeClientDataJson(challenge, clientDataFields);
        bytes32 clientDataHash = _sha256(bytes(clientDataJson));

        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The length of the signing message, this is the length of the authenticator data plus
            // the 32-byte hash of the client data JSON.
            let messageLength := add(authenticatorData.length, 32)

            // Allocate the encoded signing `message` at the start of the free memory. Note that we
            // pad the allocation to 32-byte boundary as Solidity typically does.
            message := mload(0x40)
            mstore(0x40, and(add(message, add(messageLength, 0x3f)), not(0x1f)))
            mstore(message, messageLength)

            // The actual message data is written to 32 bytes past the start of the allocation, as
            // the first 32 bytes contains the length of the byte array.
            let messagePtr := add(message, 32)

            // Copy the authenticator from calldata to the start of the `message` buffer that was
            // allocated. Note that we start copying 32 bytes after the start of the allocation to
            // account for the length.
            calldatacopy(messagePtr, authenticatorData.offset, authenticatorData.length)

            // Finally, write the client data JSON hash to the end of the `message`.
            mstore(add(messagePtr, authenticatorData.length), clientDataHash)
        }
    }

    /**
     * @notice Checks that the required authenticator data flags are set.
     * @param authenticatorData The authenticator data.
     * @param authenticatorFlags The authenticator flags to check for.
     * @return success Whether the authenticator data flags are set.
     */
    function checkAuthenticatorFlags(
        bytes calldata authenticatorData,
        AuthenticatorFlags authenticatorFlags
    ) internal pure returns (bool success) {
        success = authenticatorData[32] & AuthenticatorFlags.unwrap(authenticatorFlags) == AuthenticatorFlags.unwrap(authenticatorFlags);
    }

    /**
     * @notice Verifies a WebAuthn signature.
     * @param challenge The WebAuthn challenge used in the credential assertion.
     * @param signature The encoded WebAuthn signature bytes.
     * @param authenticatorFlags The authenticator data flags that must be set.
     * @param x The x-coordinate of the credential's public key.
     * @param y The y-coordinate of the credential's public key.
     * @param verifiers The P-256 verifier configuration to use.
     * @return success Whether the signature is valid.
     */
    function verifySignature(
        bytes32 challenge,
        bytes calldata signature,
        AuthenticatorFlags authenticatorFlags,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) internal view returns (bool success) {
        Signature calldata signatureStruct;
        (success, signatureStruct) = castSignature(signature);
        if (success) {
            success = verifySignature(challenge, signatureStruct, authenticatorFlags, x, y, verifiers);
        }
    }

    /**
     * @notice Verifies a WebAuthn signature.
     * @param challenge The WebAuthn challenge used in the credential assertion.
     * @param signature The WebAuthn signature data.
     * @param authenticatorFlags The authenticator data flags that must be set.
     * @param x The x-coordinate of the credential's public key.
     * @param y The y-coordinate of the credential's public key.
     * @param verifiers The P-256 verifier configuration to use.
     * @return success Whether the signature is valid.
     */
    function verifySignature(
        bytes32 challenge,
        Signature calldata signature,
        AuthenticatorFlags authenticatorFlags,
        uint256 x,
        uint256 y,
        P256.Verifiers verifiers
    ) internal view returns (bool success) {
        // The order of operations here is slightly counter-intuitive (in particular, you do not
        // need to encode the signing message if the expected authenticator flags are missing).
        // However, ordering things this way helps the Solidity compiler generate meaningfully more
        // optimal code for the "happy path" when Yul optimizations are turned on.
        bytes memory message = encodeSigningMessage(challenge, signature.authenticatorData, signature.clientDataFields);
        if (checkAuthenticatorFlags(signature.authenticatorData, authenticatorFlags)) {
            success = verifiers.verifySignatureAllowMalleability(_sha256(message), signature.r, signature.s, x, y);
        }
    }

    /**
     * @notice Compute the SHA-256 hash of the input bytes.
     * @dev The Solidity compiler sometimes generates a memory copy loop for the call to the SHA-256
     * precompile, even if the input is already in memory. Force this not to happen by manually
     * implementing the call to the SHA-256 precompile.
     * @param input The input bytes to hash.
     * @return digest The SHA-256 digest of the input bytes.
     */
    function _sha256(bytes memory input) private view returns (bytes32 digest) {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // The SHA-256 precompile is at address 0x0002. Note that we don't check the whether or
            // not the precompile reverted or if the return data size is 32 bytes, which is a
            // reasonable assumption for the precompile, as it is specified to always return the
            // SHA-256 of its input bytes.
            pop(staticcall(gas(), 0x0002, add(input, 0x20), mload(input), 0, 32))
            digest := mload(0)
        }
    }
}