pragma solidity 0.8.21;

import {FCL_WebAuthn} from "@FreshCryptoLib/FCL_Webauthn.sol";
import {Initializable} from "@openzeppelin/proxy/utils/Initializable.sol";
import {EIP1271} from "./EIP1271.sol";

library SignerErrors {
    error InvalidSignature();
}

/**
 * @title Signer
 * @dev A contract that implements the EIP1271 interface and is initialized using Initializable.
 */
contract Signer is EIP1271, Initializable {
    address private _empty_slot_ = address(0);
    uint256 public x;
    uint256 public y;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the signer contract with the given x and y coordinates.
     * @param _x The x coordinate of the signer's public key.
     * @param _y The y coordinate of the signer's public key.
     */
    function initialize(uint256 _x, uint256 _y) external initializer {
        x = _x;
        y = _y;
    }

    // Returns the public key coordinates.
    // @return uint256[2] memory: Array containing the x and y coordinates.
    function getPublicKey() internal view returns (uint256[2] memory key) {
        return [x, y];
    }

    // @inheritdoc EIP1271
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view override returns (bytes4) {
        _validate(abi.encode(_hash), _signature);
        return EIP1271_MAGICVALUE_BYTES32;
    }

    // @inheritdoc EIP1271
    function isValidSignature(bytes memory _hash, bytes memory _signature) external view override returns (bytes4) {
        _validate(_hash, _signature);
        return EIP1271_MAGICVALUE_BYTES;
    }

    function checkSignature(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256[2] calldata Q
    ) external view returns (bool) {
        return FCL_WebAuthn.checkSignature(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs, Q
        );
    }

    // Internal function to validate a signature.
    // @param _hash: The hash to validate against.
    // @param _signature: The signature to validate.
    // Throws InvalidSignature if the signature is invalid.
    function _validate(bytes memory _hash, bytes memory _signature) private view {
        (bytes memory authenticatorData, bytes memory clientData, uint256 challengeOffset, uint256[2] memory rs) =
            abi.decode(_signature, (bytes, bytes, uint256, uint256[2]));
        if (
            !this.checkSignature(
                authenticatorData, 0x01, clientData, keccak256(_hash), challengeOffset, rs, getPublicKey()
            )
        ) revert SignerErrors.InvalidSignature();
    }
}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_elliptic.sol
///*
///*
///* DESCRIPTION: Implementation of the WebAuthn Authentication mechanism
///* https://www.w3.org/TR/webauthn-2/#sctn-intro
///* Original code extracted from https://github.com/btchip/Webauthn.sol
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import {Base64Url} from "./utils/Base64Url.sol";
import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";
import {FCL_ecdsa} from "./FCL_ecdsa.sol";

import {FCL_ecdsa_utils} from "./FCL_ecdsa_utils.sol";

library FCL_WebAuthn {
    error InvalidAuthenticatorData();
    error InvalidClientData();
    error InvalidSignature();

    function WebAuthn_format(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata // rs
    ) internal pure returns (bytes32 result) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set
        {
            if ((authenticatorData[32] & authenticatorDataFlagMask) != authenticatorDataFlagMask) {
                revert InvalidAuthenticatorData();
            }
            // Verify that clientData commits to the expected client challenge
            // Use the Base64Url encoding which omits padding characters to match WebAuthn Specification
            string memory challengeEncoded = Base64Url.encode(abi.encodePacked(clientChallenge));
            bytes memory challengeExtracted = new bytes(
            bytes(challengeEncoded).length
        );

            assembly {
                calldatacopy(
                    add(challengeExtracted, 32),
                    add(clientData.offset, clientChallengeDataOffset),
                    mload(challengeExtracted)
                )
            }

            bytes32 moreData; //=keccak256(abi.encodePacked(challengeExtracted));
            assembly {
                moreData := keccak256(add(challengeExtracted, 32), mload(challengeExtracted))
            }

            if (keccak256(abi.encodePacked(bytes(challengeEncoded))) != moreData) {
                revert InvalidClientData();
            }
        } //avoid stack full

        // Verify the signature over sha256(authenticatorData || sha256(clientData))
        bytes memory verifyData = new bytes(authenticatorData.length + 32);

        assembly {
            calldatacopy(add(verifyData, 32), authenticatorData.offset, authenticatorData.length)
        }

        bytes32 more = sha256(clientData);
        assembly {
            mstore(add(verifyData, add(authenticatorData.length, 32)), more)
        }

        return sha256(verifyData);
    }

    function  checkSignature (
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256[2] calldata Q
    ) internal view returns (bool) {
        return checkSignature(authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs, Q[0], Q[1]);
    }

    function  checkSignature (
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256 Qx,
        uint256 Qy
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_ecdsa_utils.ecdsa_verify(message, rs, Qx, Qy);

        return result;
    }

    function checkSignature_prec(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        address dataPointer
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_ecdsa.ecdsa_precomputed_verify(message, rs, dataPointer);

        return result;
    }

    //beware that this implementation will not be compliant with EOF
    function checkSignature_hackmem(
        bytes calldata authenticatorData,
        bytes1 authenticatorDataFlagMask,
        bytes calldata clientData,
        bytes32 clientChallenge,
        uint256 clientChallengeDataOffset,
        uint256[2] calldata rs,
        uint256 dataPointer
    ) internal view returns (bool) {
        // Let the caller check if User Presence (0x01) or User Verification (0x04) are set

        bytes32 message = FCL_WebAuthn.WebAuthn_format(
            authenticatorData, authenticatorDataFlagMask, clientData, clientChallenge, clientChallengeDataOffset, rs
        );

        bool result = FCL_Elliptic_ZZ.ecdsa_precomputed_hackmem(message, rs, dataPointer);

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

pragma solidity 0.8.21;

/**
 * @title EIP1271
 * @dev Abstract contract for the EIP1271 standard.
 */
abstract contract EIP1271 {
    bytes4 internal constant EIP1271_MAGICVALUE_BYTES32 = 0x1626ba7e;
    bytes4 internal constant EIP1271_MAGICVALUE_BYTES = 0x20c13b0b;

    /**
     * @dev Verifies the validity of a signature for a given hash.
     * @param _hash The hash to be verified.
     * @param _signature The signature to be checked.
     * @return magicValue A boolean indicating whether the signature is valid or not.
     */
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        virtual
        returns (bytes4 magicValue);

    /**
     * @dev Verifies the validity of a signature.
     * @param _data The data to be verified.
     * @param _signature The signature to be verified.
     * @return magicValue A boolean indicating whether the signature is valid or not.
     */
    function isValidSignature(bytes memory _data, bytes memory _signature)
        external
        view
        virtual
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @dev Encode (without '=' padding) 
 * @author evmbrahmin, adapted from hiromin's Base64URL libraries
 */
library Base64Url {
    /**
     * @dev Base64Url Encoding Table
     */
    string internal constant ENCODING_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the table into memory
        string memory table = ENCODING_TABLE;

        string memory result = new string(4 * ((data.length + 2) / 3));

        // @solidity memory-safe-assembly
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // Remove the padding adjustment logic
            switch mod(mload(data), 3)
            case 1 {
                // Adjust for the last byte of data
                resultPtr := sub(resultPtr, 2)
            }
            case 2 {
                // Adjust for the last two bytes of data
                resultPtr := sub(resultPtr, 1)
            }
            
            // Set the correct length of the result string
            mstore(result, sub(resultPtr, add(result, 32)))
        }

        return result;  
    }
}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_elliptic.sol
///*
///*
///* DESCRIPTION: modified XYZZ system coordinates for EVM elliptic point multiplication
///*  optimization
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

library FCL_Elliptic_ZZ {
    // Set parameters for curve sec256r1.

    // address of the ModExp precompiled contract (Arbitrary-precision exponentiation under modulo)
    address constant MODEXP_PRECOMPILE = 0x0000000000000000000000000000000000000005;
    //curve prime field modulus
    uint256 constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    //short weierstrass first coefficient
    uint256 constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    //short weierstrass second coefficient
    uint256 constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    //generating point affine coordinates
    uint256 constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint256 constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    //curve order (number of points)
    uint256 constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
    /* -2 mod p constant, used to speed up inversion and doubling (avoid negation)*/
    uint256 constant minus_2 = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFD;
    /* -2 mod n constant, used to speed up inversion*/
    uint256 constant minus_2modn = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC63254F;

    uint256 constant minus_1 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    //P+1 div 4
    uint256 constant pp1div4=0x3fffffffc0000000400000000000000000000000400000000000000000000000;
    //arbitrary constant to express no quadratic residuosity
    uint256 constant _NOTSQUARE=0xFFFFFFFF00000002000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 constant _NOTONCURVE=0xFFFFFFFF00000003000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * /* inversion mod n via a^(n-2), use of precompiled using little Fermat theorem
     */
    function FCL_nModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2modn)
            mstore(add(pointer, 0xa0), n)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }
    /**
     * /* @dev inversion mod nusing little Fermat theorem via a^(n-2), use of precompiled
     */

    function FCL_pModInv(uint256 u) internal view returns (uint256 result) {
        assembly {
            let pointer := mload(0x40)
            // Define length of base, exponent and modulus. 0x20 == 32 bytes
            mstore(pointer, 0x20)
            mstore(add(pointer, 0x20), 0x20)
            mstore(add(pointer, 0x40), 0x20)
            // Define variables base, exponent and modulus
            mstore(add(pointer, 0x60), u)
            mstore(add(pointer, 0x80), minus_2)
            mstore(add(pointer, 0xa0), p)

            // Call the precompiled contract 0x05 = ModExp
            if iszero(staticcall(not(0), 0x05, pointer, 0xc0, pointer, 0x20)) { revert(0, 0) }
            result := mload(pointer)
        }
    }

    //Coron projective shuffling, take as input alpha as blinding factor
   function ecZZ_Coronize(uint256 alpha, uint256 x, uint256 y,  uint256 zz, uint256 zzz) internal pure  returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
   {
       
        uint256 alpha2=mulmod(alpha,alpha,p);
       
        x3=mulmod(alpha2, x,p); //alpha^-2.x
        y3=mulmod(mulmod(alpha, alpha2,p), y,p);

        zz3=mulmod(zz,alpha2,p);//alpha^2 zz
        zzz3=mulmod(zzz,mulmod(alpha, alpha2,p),p);//alpha^3 zzz
        
        return (x3, y3, zz3, zzz3);
   }


 function ecZZ_Add(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2, uint256 zz2, uint256 zzz2) internal pure  returns (uint256 x3, uint256 y3, uint256 zz3, uint256 zzz3)
  {
    uint256 u1=mulmod(x1,zz2,p); // U1 = X1*ZZ2
    uint256 u2=mulmod(x2, zz1,p);               //  U2 = X2*ZZ1
    u2=addmod(u2, p-u1, p);//  P = U2-U1
    x1=mulmod(u2, u2, p);//PP
    x2=mulmod(x1, u2, p);//PPP
    
    zz3=mulmod(x1, mulmod(zz1, zz2, p),p);//ZZ3 = ZZ1*ZZ2*PP  
    zzz3=mulmod(zzz1, mulmod(zzz2, x2, p),p);//ZZZ3 = ZZZ1*ZZZ2*PPP

    zz1=mulmod(y1, zzz2,p);  // S1 = Y1*ZZZ2
    zz2=mulmod(y2, zzz1, p);    // S2 = Y2*ZZZ1 
    zz2=addmod(zz2, p-zz1, p);//R = S2-S1
    zzz1=mulmod(u1, x1,p); //Q = U1*PP
    x3= addmod(addmod(mulmod(zz2, zz2, p), p-x2,p), mulmod(minus_2, zzz1,p),p); //X3 = R2-PPP-2*Q
    y3=addmod( mulmod(zz2, addmod(zzz1, p-x3, p),p), p-mulmod(zz1, x2, p),p);//R*(Q-X3)-S1*PPP

    return (x3, y3, zz3, zzz3);
  }

/// @notice Calculate one modular square root of a given integer. Assume that p=3 mod 4.
/// @dev Uses the ModExp precompiled contract at address 0x05 for fast computation using little Fermat theorem
/// @param self The integer of which to find the modular inverse
/// @return result The modular inverse of the input integer. If the modular inverse doesn't exist, it revert the tx

function SqrtMod(uint256 self) internal view returns (uint256 result){
 assembly ("memory-safe") {
        // load the free memory pointer value
        let pointer := mload(0x40)

        // Define length of base (Bsize)
        mstore(pointer, 0x20)
        // Define the exponent size (Esize)
        mstore(add(pointer, 0x20), 0x20)
        // Define the modulus size (Msize)
        mstore(add(pointer, 0x40), 0x20)
        // Define variables base (B)
        mstore(add(pointer, 0x60), self)
        // Define the exponent (E)
        mstore(add(pointer, 0x80), pp1div4)
        // We save the point of the last argument, it will be override by the result
        // of the precompile call in order to avoid paying for the memory expansion properly
        let _result := add(pointer, 0xa0)
        // Define the modulus (M)
        mstore(_result, p)

        // Call the precompiled ModExp (0x05) https://www.evm.codes/precompiled#0x05
        if iszero(
            staticcall(
                not(0), // amount of gas to send
                MODEXP_PRECOMPILE, // target
                pointer, // argsOffset
                0xc0, // argsSize (6 * 32 bytes)
                _result, // retOffset (we override M to avoid paying for the memory expansion)
                0x20 // retSize (32 bytes)
            )
        ) { revert(0, 0) }

  result := mload(_result)
//  result :=addmod(result,0,p)
 }
   if(mulmod(result,result,p)!=self){
     result=_NOTSQUARE;
   }
  
   return result;
}
    /**
     * /* @dev Convert from affine rep to XYZZ rep
     */
    function ecAff_SetZZ(uint256 x0, uint256 y0) internal pure returns (uint256[4] memory P) {
        unchecked {
            P[2] = 1; //ZZ
            P[3] = 1; //ZZZ
            P[0] = x0;
            P[1] = y0;
        }
    }

    function ec_Decompress(uint256 x, uint256 parity) internal view returns(uint256 y){ 

        uint256 y2=mulmod(x,mulmod(x,x,p),p);//x3
        y2=addmod(b,addmod(y2,mulmod(x,a,p),p),p);//x3+ax+b

        y=SqrtMod(y2);
        if(y==_NOTSQUARE){
           return _NOTONCURVE;
        }
        if((y&1)!=(parity&1)){
            y=p-y;
        }
    }

    /**
     * /* @dev Convert from XYZZ rep to affine rep
     */
    /*    https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-add-2008-s*/
    function ecZZ_SetAff(uint256 x, uint256 y, uint256 zz, uint256 zzz) internal view returns (uint256 x1, uint256 y1) {
        uint256 zzzInv = FCL_pModInv(zzz); //1/zzz
        y1 = mulmod(y, zzzInv, p); //Y/zzz
        uint256 _b = mulmod(zz, zzzInv, p); //1/z
        zzzInv = mulmod(_b, _b, p); //1/zz
        x1 = mulmod(x, zzzInv, p); //X/zz
    }

    /**
     * /* @dev Sutherland2008 doubling
     */
    /* The "dbl-2008-s-1" doubling formulas */

    function ecZZ_Dbl(uint256 x, uint256 y, uint256 zz, uint256 zzz)
        internal
        pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            assembly {
                P0 := mulmod(2, y, p) //U = 2*Y1
                P2 := mulmod(P0, P0, p) // V=U^2
                P3 := mulmod(x, P2, p) // S = X1*V
                P1 := mulmod(P0, P2, p) // W=UV
                P2 := mulmod(P2, zz, p) //zz3=V*ZZ1
                zz := mulmod(3, mulmod(addmod(x, sub(p, zz), p), addmod(x, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                P0 := addmod(mulmod(zz, zz, p), mulmod(minus_2, P3, p), p) //X3=M^2-2S
                x := mulmod(zz, addmod(P3, sub(p, P0), p), p) //M(S-X3)
                P3 := mulmod(P1, zzz, p) //zzz3=W*zzz1
                P1 := addmod(x, sub(p, mulmod(P1, y, p)), p) //Y3= M(S-X3)-W*Y1
            }
        }
        return (P0, P1, P2, P3);
    }

    /**
     * @dev Sutherland2008 add a ZZ point with a normalized point and greedy formulae
     * warning: assume that P1(x1,y1)!=P2(x2,y2), true in multiplication loop with prime order (cofactor 1)
     */

    function ecZZ_AddN(uint256 x1, uint256 y1, uint256 zz1, uint256 zzz1, uint256 x2, uint256 y2)
        internal
        pure
        returns (uint256 P0, uint256 P1, uint256 P2, uint256 P3)
    {
        unchecked {
            if (y1 == 0) {
                return (x2, y2, 1, 1);
            }

            assembly {
                y1 := sub(p, y1)
                y2 := addmod(mulmod(y2, zzz1, p), y1, p)
                x2 := addmod(mulmod(x2, zz1, p), sub(p, x1), p)
                P0 := mulmod(x2, x2, p) //PP = P^2
                P1 := mulmod(P0, x2, p) //PPP = P*PP
                P2 := mulmod(zz1, P0, p) ////ZZ3 = ZZ1*PP
                P3 := mulmod(zzz1, P1, p) ////ZZZ3 = ZZZ1*PPP
                zz1 := mulmod(x1, P0, p) //Q = X1*PP
                P0 := addmod(addmod(mulmod(y2, y2, p), sub(p, P1), p), mulmod(minus_2, zz1, p), p) //R^2-PPP-2*Q
                P1 := addmod(mulmod(addmod(zz1, sub(p, P0), p), y2, p), mulmod(y1, P1, p), p) //R*(Q-X3)
            }
            //end assembly
        } //end unchecked
        return (P0, P1, P2, P3);
    }

    /**
     * @dev Return the zero curve in XYZZ coordinates.
     */
    function ecZZ_SetZero() internal pure returns (uint256 x, uint256 y, uint256 zz, uint256 zzz) {
        return (0, 0, 0, 0);
    }
    /**
     * @dev Check if point is the neutral of the curve
     */

    // uint256 x0, uint256 y0, uint256 zz0, uint256 zzz0
    function ecZZ_IsZero(uint256, uint256 y0, uint256, uint256) internal pure returns (bool) {
        return y0 == 0;
    }
    /**
     * @dev Return the zero curve in affine coordinates. Compatible with the double formulae (no special case)
     */

    function ecAff_SetZero() internal pure returns (uint256 x, uint256 y) {
        return (0, 0);
    }

    /**
     * @dev Check if the curve is the zero curve in affine rep.
     */
    // uint256 x, uint256 y)
    function ecAff_IsZero(uint256, uint256 y) internal pure returns (bool flag) {
        return (y == 0);
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve (reject Neutral that is indeed on the curve).
     */
    function ecAff_isOnCurve(uint256 x, uint256 y) internal pure returns (bool) {
        if ( ((0 == x)&&( 0 == y)) || x == p ||   y == p) {
            return false;
        }
        unchecked {
            uint256 LHS = mulmod(y, y, p); // y^2
            uint256 RHS = addmod(mulmod(mulmod(x, x, p), x, p), mulmod(x, a, p), p); // x^3+ax
            RHS = addmod(RHS, b, p); // x^3 + a*x + b

            return LHS == RHS;
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates. Deal with P=Q
     */

    function ecAff_add(uint256 x0, uint256 y0, uint256 x1, uint256 y1) internal view returns (uint256, uint256) {
        uint256 zz0;
        uint256 zzz0;

        if (ecAff_IsZero(x0, y0)) return (x1, y1);
        if (ecAff_IsZero(x1, y1)) return (x0, y0);
        if((x0==x1)&&(y0==y1)) {
            (x0, y0, zz0, zzz0) = ecZZ_Dbl(x0, y0,1,1);
        }
        else{
            (x0, y0, zz0, zzz0) = ecZZ_AddN(x0, y0, 1, 1, x1, y1);
        }

        return ecZZ_SetAff(x0, y0, zz0, zzz0);
    }

    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns only x for ECDSA use            
     *      */
    function ecZZ_mulmuladd_S_asm(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X) {
        uint256 zz;
        uint256 zzz;
        uint256 Y;
        uint256 index = 255;
        uint256 H0;
        uint256 H1;

        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return 0;

            (H0, H1) = ecAff_add(gx, gy, Q0, Q1); 
            if((H0==0)&&(H1==0))//handling Q=-G
            {
                scalar_u=addmod(scalar_u, n-scalar_v, n);
                scalar_v=0;

            }
            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                if eq(zz, 1) {
                    X := gx
                    Y := gy
                }
                if eq(zz, 2) {
                    X := Q0
                    Y := Q1
                }
                if eq(zz, 3) {
                    X := H0
                    Y := H1
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        if eq(T4, 1) {
                            T1 := gx
                            T2 := gy
                        }
                        if eq(T4, 2) {
                            T1 := Q0
                            T2 := Q1
                        }
                        if eq(T4, 3) {
                            T1 := H0
                            T2 := H1
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := mulmod(addmod(X, zz, p), addmod(X, sub(p, zz), p), p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M=3*(X-ZZ)(X+ZZ)

                                zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                let T := mload(0x40)
                mstore(add(T, 0x60), zz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                //Y:=mulmod(Y,zzz,p)//Y/zzz
                //zz :=mulmod(zz, mload(T),p) //1/z
                //zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, mload(T), p) //X/zz
            } //end assembly
        } //end unchecked

        return X;
    }


    /**
     * @dev Computation of uG+vQ using Strauss-Shamir's trick, G basepoint, Q public key
     *       Returns affine representation of point (normalized)       
     *      */
    function ecZZ_mulmuladd(
        uint256 Q0,
        uint256 Q1, //affine rep for input point Q
        uint256 scalar_u,
        uint256 scalar_v
    ) internal view returns (uint256 X, uint256 Y) {
        uint256 zz;
        uint256 zzz;
        uint256 index = 255;
        uint256[6] memory T;
        uint256[2] memory H;
 
        unchecked {
            if (scalar_u == 0 && scalar_v == 0) return (0,0);

            (H[0], H[1]) = ecAff_add(gx, gy, Q0, Q1); //will not work if Q=P, obvious forbidden private key

            assembly {
                for { let T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1)) } eq(T4, 0) {
                    index := sub(index, 1)
                    T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))
                } {}
                zz := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                if eq(zz, 1) {
                    X := gx
                    Y := gy
                }
                if eq(zz, 2) {
                    X := Q0
                    Y := Q1
                }
                if eq(zz, 3) {
                    Y := mload(add(H,32))
                    X := mload(H)
                }

                index := sub(index, 1)
                zz := 1
                zzz := 1

                for {} gt(minus_1, index) { index := sub(index, 1) } {
                    // inlined EcZZ_Dbl
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    {
                        //value of dibit
                        T4 := add(shl(1, and(shr(index, scalar_v), 1)), and(shr(index, scalar_u), 1))

                        if iszero(T4) {
                            Y := sub(p, Y) //restore the -Y inversion
                            continue
                        } // if T4!=0

                        if eq(T4, 1) {
                            T1 := gx
                            T2 := gy
                        }
                        if eq(T4, 2) {
                            T1 := Q0
                            T2 := Q1
                        }
                        if eq(T4, 3) {
                            T1 := mload(H)
                            T2 := mload(add(H,32))
                        }
                        if iszero(zz) {
                            X := T1
                            Y := T2
                            zz := 1
                            zzz := 1
                            continue
                        }
                        // inlined EcZZ_AddN

                        //T3:=sub(p, Y)
                        //T3:=Y
                        let y2 := addmod(mulmod(T2, zzz, p), Y, p) //R
                        T2 := addmod(mulmod(T1, zz, p), sub(p, X), p) //P

                        //special extremely rare case accumulator where EcAdd is replaced by EcDbl, no need to optimize this
                        //todo : construct edge vector case
                        if iszero(y2) {
                            if iszero(T2) {
                                T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        T4 := mulmod(T2, T2, p) //PP
                        let TT1 := mulmod(T4, T2, p) //PPP, this one could be spared, but adding this register spare gas
                        zz := mulmod(zz, T4, p)
                        zzz := mulmod(zzz, TT1, p) //zz3=V*ZZ1
                        let TT2 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, TT1), p), mulmod(minus_2, TT2, p), p)
                        Y := addmod(mulmod(addmod(TT2, sub(p, T4), p), y2, p), mulmod(Y, TT1, p), p)

                        X := T4
                    }
                } //end loop
                mstore(add(T, 0x60), zzz)
                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                Y:=mulmod(Y,mload(T),p)//Y/zzz
                zz :=mulmod(zz, mload(T),p) //1/z
                zz:= mulmod(zz,zz,p) //1/zz
                X := mulmod(X, zz, p) //X/zz
            } //end assembly
        } //end unchecked

        return (X,Y);
    }

    //8 dimensions Shamir's trick, using precomputations stored in Shamir8,  stored as Bytecode of an external
    //contract at given address dataPointer
    //(thx to Lakhdar https://github.com/Kelvyne for EVM storage explanations and tricks)
    // the external tool to generate tables from public key is in the /sage directory
    function ecZZ_mulmuladd_S8_extcode(uint256 scalar_u, uint256 scalar_v, address dataPointer)
        internal view
        returns (uint256 X /*, uint Y*/ )
    {
        unchecked {
            uint256 zz; // third and  coordinates of the point

            uint256[6] memory T;
            zz = 256; //start index

            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                extcodecopy(dataPointer, T, mload(T), 64)
                let index := sub(zz, 1)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for {} gt(index, 191) { index := add(index, 191) } {
                    //inline Double
                    {
                        let TT1 := mulmod(2, Y, p) //U = 2*Y1, y free
                        let T2 := mulmod(TT1, TT1, p) // V=U^2
                        let T3 := mulmod(X, T2, p) // S = X1*V
                        let T1 := mulmod(TT1, T2, p) // W=UV
                        let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                        zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                        zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                        X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                        //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                        let T5 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                        //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                        Y := addmod(mulmod(T1, Y, p), T5, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                        /* compute element to access in precomputed table */
                    }
                    {
                        let T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                        let index2 := sub(index, 64)
                        let T3 :=
                            add(T4, add(shl(12, and(shr(index2, scalar_v), 1)), shl(8, and(shr(index2, scalar_u), 1))))
                        let index3 := sub(index2, 64)
                        let T2 :=
                            add(T3, add(shl(11, and(shr(index3, scalar_v), 1)), shl(7, and(shr(index3, scalar_u), 1))))
                        index := sub(index3, 64)
                        let T1 :=
                            add(T2, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))

                        //tbd: check validity of formulae with (0,1) to remove conditional jump
                        if iszero(T1) {
                            Y := sub(p, Y)

                            continue
                        }
                        extcodecopy(dataPointer, T, T1, 64)
                    }

                    {
                        /* Access to precomputed table using extcodecopy hack */

                        // inlined EcZZ_AddN
                        if iszero(zz) {
                            X := mload(T)
                            Y := mload(add(T, 32))
                            zz := 1
                            zzz := 1

                            continue
                        }

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        let T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)

                        //special case ecAdd(P,P)=EcDbl
                        if iszero(y2) {
                            if iszero(T2) {
                                let T1 := mulmod(minus_2, Y, p) //U = 2*Y1, y free
                                T2 := mulmod(T1, T1, p) // V=U^2
                                let T3 := mulmod(X, T2, p) // S = X1*V

                                T1 := mulmod(T1, T2, p) // W=UV
                                y2 := addmod(X, zz, p) //X+ZZ
                                let TT1 := addmod(X, sub(p, zz), p) //X-ZZ
                                y2 := mulmod(y2, TT1, p) //(X-ZZ)(X+ZZ)
                                let T4 := mulmod(3, y2, p) //M

                                zzz := mulmod(TT1, zzz, p) //zzz3=W*zzz1
                                zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                                X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                                T2 := mulmod(T4, addmod(T3, sub(p, X), p), p) //M(S-X3)

                                Y := addmod(T2, mulmod(T1, Y, p), p) //Y3= M(S-X3)-W*Y1

                                continue
                            }
                        }

                        let T4 := mulmod(T2, T2, p)
                        let T1 := mulmod(T4, T2, p) //
                        zz := mulmod(zz, T4, p)
                        //zzz3=V*ZZ1
                        zzz := mulmod(zzz, T1, p) // W=UV/
                        let zz1 := mulmod(X, T4, p)
                        X := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(minus_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, X), p), y2, p), mulmod(Y, T1, p), p)
                    }
                } //end loop
                mstore(add(T, 0x60), zz)

                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }

   

    // improving the extcodecopy trick : append array at end of contract
    function ecZZ_mulmuladd_S8_hackmem(uint256 scalar_u, uint256 scalar_v, uint256 dataPointer)
        internal view
        returns (uint256 X /*, uint Y*/ )
    {
        uint256 zz; // third and  coordinates of the point

        uint256[6] memory T;
        zz = 256; //start index

        unchecked {
            while (T[0] == 0) {
                zz = zz - 1;
                //tbd case of msb octobit is null
                T[0] = 64
                    * (
                        128 * ((scalar_v >> zz) & 1) + 64 * ((scalar_v >> (zz - 64)) & 1)
                            + 32 * ((scalar_v >> (zz - 128)) & 1) + 16 * ((scalar_v >> (zz - 192)) & 1)
                            + 8 * ((scalar_u >> zz) & 1) + 4 * ((scalar_u >> (zz - 64)) & 1)
                            + 2 * ((scalar_u >> (zz - 128)) & 1) + ((scalar_u >> (zz - 192)) & 1)
                    );
            }
            assembly {
                codecopy(T, add(mload(T), dataPointer), 64)
                X := mload(T)
                let Y := mload(add(T, 32))
                let zzz := 1
                zz := 1

                //loop over 1/4 of scalars thx to Shamir's trick over 8 points
                for { let index := 254 } gt(index, 191) { index := add(index, 191) } {
                    let T1 := mulmod(2, Y, p) //U = 2*Y1, y free
                    let T2 := mulmod(T1, T1, p) // V=U^2
                    let T3 := mulmod(X, T2, p) // S = X1*V
                    T1 := mulmod(T1, T2, p) // W=UV
                    let T4 := mulmod(3, mulmod(addmod(X, sub(p, zz), p), addmod(X, zz, p), p), p) //M=3*(X1-ZZ1)*(X1+ZZ1)
                    zzz := mulmod(T1, zzz, p) //zzz3=W*zzz1
                    zz := mulmod(T2, zz, p) //zz3=V*ZZ1, V free

                    X := addmod(mulmod(T4, T4, p), mulmod(minus_2, T3, p), p) //X3=M^2-2S
                    //T2:=mulmod(T4,addmod(T3, sub(p, X),p),p)//M(S-X3)
                    T2 := mulmod(T4, addmod(X, sub(p, T3), p), p) //-M(S-X3)=M(X3-S)

                    //Y:= addmod(T2, sub(p, mulmod(T1, Y ,p)),p  )//Y3= M(S-X3)-W*Y1
                    Y := addmod(mulmod(T1, Y, p), T2, p) //-Y3= W*Y1-M(S-X3), we replace Y by -Y to avoid a sub in ecAdd

                    /* compute element to access in precomputed table */
                    T4 := add(shl(13, and(shr(index, scalar_v), 1)), shl(9, and(shr(index, scalar_u), 1)))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(12, and(shr(index, scalar_v), 1)), shl(8, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(11, and(shr(index, scalar_v), 1)), shl(7, and(shr(index, scalar_u), 1))))
                    index := sub(index, 64)
                    T4 := add(T4, add(shl(10, and(shr(index, scalar_v), 1)), shl(6, and(shr(index, scalar_u), 1))))
                    //index:=add(index,192), restore index, interleaved with loop

                    //tbd: check validity of formulae with (0,1) to remove conditional jump
                    if iszero(T4) {
                        Y := sub(p, Y)

                        continue
                    }
                    {
                        /* Access to precomputed table using extcodecopy hack */
                        codecopy(T, add(T4, dataPointer), 64)

                        // inlined EcZZ_AddN

                        let y2 := addmod(mulmod(mload(add(T, 32)), zzz, p), Y, p)
                        T2 := addmod(mulmod(mload(T), zz, p), sub(p, X), p)
                        T4 := mulmod(T2, T2, p)
                        T1 := mulmod(T4, T2, p)
                        T2 := mulmod(zz, T4, p) // W=UV
                        zzz := mulmod(zzz, T1, p) //zz3=V*ZZ1
                        let zz1 := mulmod(X, T4, p)
                        T4 := addmod(addmod(mulmod(y2, y2, p), sub(p, T1), p), mulmod(minus_2, zz1, p), p)
                        Y := addmod(mulmod(addmod(zz1, sub(p, T4), p), y2, p), mulmod(Y, T1, p), p)
                        zz := T2
                        X := T4
                    }
                } //end loop
                mstore(add(T, 0x60), zz)

                //(X,Y)=ecZZ_SetAff(X,Y,zz, zzz);
                //T[0] = inverseModp_Hard(T[0], p); //1/zzz, inline modular inversion using precompile:
                // Define length of base, exponent and modulus. 0x20 == 32 bytes
                mstore(T, 0x20)
                mstore(add(T, 0x20), 0x20)
                mstore(add(T, 0x40), 0x20)
                // Define variables base, exponent and modulus
                //mstore(add(pointer, 0x60), u)
                mstore(add(T, 0x80), minus_2)
                mstore(add(T, 0xa0), p)

                // Call the precompiled contract 0x05 = ModExp
                if iszero(staticcall(not(0), 0x05, T, 0xc0, T, 0x20)) { revert(0, 0) }

                zz := mload(T)
                X := mulmod(X, zz, p) //X/zz
            }
        } //end unchecked
    }


    /**
     * @dev ECDSA verification using a precomputed table of multiples of P and Q stored in contract at address Shamir8
     *     generation of contract bytecode for precomputations is done using sagemath code
     *     (see sage directory, WebAuthn_precompute.sage)
     */

    /**
     * @dev ECDSA verification using a precomputed table of multiples of P and Q appended at end of contract at address endcontract
     *     generation of contract bytecode for precomputations is done using sagemath code
     *     (see sage directory, WebAuthn_precompute.sage)
     */

    function ecdsa_precomputed_hackmem(bytes32 message, uint256[2] calldata rs, uint256 endcontract)
        internal view
        returns (bool)
    {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via bytecode assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_nModInv(s);
        uint256 X;

        //Shamir 8 dimensions
        X = ecZZ_mulmuladd_S8_hackmem(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), endcontract);

        assembly {
            X := addmod(X, sub(n, r), n)
        }
        return X == 0;
    } //end  ecdsa_precomputed_verify()



} //EOF

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_ecdsa.sol
///*
///*
///* DESCRIPTION: ecdsa verification implementation
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";



library FCL_ecdsa {
    // Set parameters for curve sec256r1.public
      //curve order (number of points)
    uint256 constant n = FCL_Elliptic_ZZ.n;
  
    /**
     * @dev ECDSA verification, given , signature, and public key.
     */

    /**
     * @dev ECDSA verification, given , signature, and public key, no calldata version
     */
    function ecdsa_verify(bytes32 message, uint256 r, uint256 s, uint256 Qx, uint256 Qy)  internal view returns (bool){

        if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return false;
        }
        
        if (!FCL_Elliptic_ZZ.ecAff_isOnCurve(Qx, Qy)) {
            return false;
        }

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 scalar_u = mulmod(uint256(message), sInv, FCL_Elliptic_ZZ.n);
        uint256 scalar_v = mulmod(r, sInv, FCL_Elliptic_ZZ.n);
        uint256 x1;

        x1 = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(Qx, Qy, scalar_u, scalar_v);

        x1= addmod(x1, n-r,n );
    
        return x1 == 0;
    }

    function ec_recover_r1(uint256 h, uint256 v, uint256 r, uint256 s) internal view returns (address)
    {
         if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return address(0);
        }
        uint256 y=FCL_Elliptic_ZZ.ec_Decompress(r, v-27);
        uint256 rinv=FCL_Elliptic_ZZ.FCL_nModInv(r);
        uint256 u1=mulmod(FCL_Elliptic_ZZ.n-addmod(0,h,FCL_Elliptic_ZZ.n), rinv,FCL_Elliptic_ZZ.n);//-hr^-1
        uint256 u2=mulmod(s, rinv,FCL_Elliptic_ZZ.n);//sr^-1

        uint256 Qx;
        uint256 Qy;
        (Qx,Qy)=FCL_Elliptic_ZZ.ecZZ_mulmuladd(r,y, u1, u2);

        return address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
    }

    function ecdsa_precomputed_verify(bytes32 message, uint256 r, uint256 s, address Shamir8)
        internal view
        returns (bool)
    {
       
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via the contract at address Shamir8 assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 X;

        //Shamir 8 dimensions
        X = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S8_extcode(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), Shamir8);

        X= addmod(X, n-r,n );

        return X == 0;
    } //end  ecdsa_precomputed_verify()

     function ecdsa_precomputed_verify(bytes32 message, uint256[2] calldata rs, address Shamir8)
        internal view
        returns (bool)
    {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= n || s == 0 || s >= n) {
            return false;
        }
        /* Q is pushed via the contract at address Shamir8 assumed to be correct
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }*/

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 X;

        //Shamir 8 dimensions
        X = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S8_extcode(mulmod(uint256(message), sInv, n), mulmod(r, sInv, n), Shamir8);

        X= addmod(X, n-r,n );

        return X == 0;
    } //end  ecdsa_precomputed_verify()

}

//********************************************************************************************/
//  ___           _       ___               _         _    _ _
// | __| _ ___ __| |_    / __|_ _ _  _ _ __| |_ ___  | |  (_) |__
// | _| '_/ -_|_-< ' \  | (__| '_| || | '_ \  _/ _ \ | |__| | '_ \
// |_||_| \___/__/_||_|  \___|_|  \_, | .__/\__\___/ |____|_|_.__/
//                                |__/|_|
///* Copyright (C) 2022 - Renaud Dubois - This file is part of FCL (Fresh CryptoLib) project
///* License: This software is licensed under MIT License
///* This Code may be reused including license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: FCL_ecdsa.sol
///*
///*
///* DESCRIPTION: ecdsa verification implementation
///*
//**************************************************************************************/
//* WARNING: this code SHALL not be used for non prime order curves for security reasons.
// Code is optimized for a=-3 only curves with prime order, constant like -1, -2 shall be replaced
// if ever used for other curve than sec256R1
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;


import {FCL_Elliptic_ZZ} from "./FCL_elliptic.sol";



library FCL_ecdsa_utils {
    // Set parameters for curve sec256r1.public
      //curve order (number of points)
    uint256 constant n = FCL_Elliptic_ZZ.n;
  
    /**
     * @dev ECDSA verification, given , signature, and public key.
     */

    function ecdsa_verify(bytes32 message, uint256[2] calldata rs, uint256 Qx, uint256 Qy) internal view returns (bool) {
        uint256 r = rs[0];
        uint256 s = rs[1];
        if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return false;
        }
        if (!FCL_Elliptic_ZZ.ecAff_isOnCurve(Qx, Qy)) {
            return false;
        }

        uint256 sInv = FCL_Elliptic_ZZ.FCL_nModInv(s);

        uint256 scalar_u = mulmod(uint256(message), sInv, FCL_Elliptic_ZZ.n);
        uint256 scalar_v = mulmod(r, sInv, FCL_Elliptic_ZZ.n);
        uint256 x1;

        x1 = FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(Qx, Qy, scalar_u, scalar_v);
        x1= addmod(x1, n-r,n );
        
       
        return x1 == 0;
    }

    function ecdsa_verify(bytes32 message, uint256[2] calldata rs, uint256[2] calldata Q) internal view returns (bool) {
        return ecdsa_verify(message, rs, Q[0], Q[1]);
    }

    function ec_recover_r1(uint256 h, uint256 v, uint256 r, uint256 s) internal view returns (address)
    {
         if (r == 0 || r >= FCL_Elliptic_ZZ.n || s == 0 || s >= FCL_Elliptic_ZZ.n) {
            return address(0);
        }
        uint256 y=FCL_Elliptic_ZZ.ec_Decompress(r, v-27);
        uint256 rinv=FCL_Elliptic_ZZ.FCL_nModInv(r);
        uint256 u1=mulmod(FCL_Elliptic_ZZ.n-addmod(0,h,FCL_Elliptic_ZZ.n), rinv,FCL_Elliptic_ZZ.n);//-hr^-1
        uint256 u2=mulmod(s, rinv,FCL_Elliptic_ZZ.n);//sr^-1

        uint256 Qx;
        uint256 Qy;
        (Qx,Qy)=FCL_Elliptic_ZZ.ecZZ_mulmuladd(r,y, u1, u2);

        return address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
    }


    //ecdsa signature for test purpose only (who would like to have a private key onchain anyway ?)
    //K is nonce, kpriv is private key
    function ecdsa_sign(bytes32 message, uint256 k , uint256 kpriv) internal view returns(uint256 r, uint256 s)
    {
        r=FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(0,0, k, 0) ;//Calculate the curve point k.G (abuse ecmulmul add with v=0)
        r=addmod(0,r, FCL_Elliptic_ZZ.n); 
        s=mulmod(FCL_Elliptic_ZZ.FCL_nModInv(k), addmod(uint256(message), mulmod(r, kpriv, FCL_Elliptic_ZZ.n),FCL_Elliptic_ZZ.n),FCL_Elliptic_ZZ.n);//s=k^-1.(h+r.kpriv)

        
        if(r==0||s==0){
            revert();
        }


    }

    //ecdsa key derivation
    //kpriv is private key return (x,y) coordinates of associated Pubkey
    function ecdsa_derivKpub(uint256 kpriv) internal view returns(uint256 x, uint256 y)
    {
        
        x=FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(0,0, kpriv, 0) ;//Calculate the curve point k.G (abuse ecmulmul add with v=0)
        y=FCL_Elliptic_ZZ.ec_Decompress(x, 1);
       
        if (FCL_Elliptic_ZZ.ecZZ_mulmuladd_S_asm(x, y, kpriv, FCL_Elliptic_ZZ.n - 1) != 0) //extract correct y value
        {
            y=FCL_Elliptic_ZZ.p-y;
        }        

    }
 
    //precomputations for 8 dimensional trick
    function Precalc_8dim( uint256 Qx, uint256 Qy) internal view returns( uint[2][256] memory Prec)
    {
    
     uint[2][8] memory Pow64_PQ; //store P, 64P, 128P, 192P, Q, 64Q, 128Q, 192Q
     
     //the trivial private keys 1 and -1 are forbidden
     if(Qx==FCL_Elliptic_ZZ.gx)
     {
        revert();
     }
     Pow64_PQ[0][0]=FCL_Elliptic_ZZ.gx;
     Pow64_PQ[0][1]=FCL_Elliptic_ZZ.gy;
    
     Pow64_PQ[4][0]=Qx;
     Pow64_PQ[4][1]=Qy;
     
     /* raise to multiplication by 64 by 6 consecutive doubling*/
     for(uint j=1;j<4;j++){
        uint256 x;
        uint256 y;
        uint256 zz;
        uint256 zzz;
        
      	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j-1][0],   Pow64_PQ[j-1][1], 1, 1);
      	(Pow64_PQ[j][0],   Pow64_PQ[j][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
        (x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j+3][0],   Pow64_PQ[j+3][1], 1, 1);
     	(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);

     	for(uint i=0;i<63;i++){
     	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j][0],   Pow64_PQ[j][1],1,1);
        (Pow64_PQ[j][0],   Pow64_PQ[j][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
     	(x,y,zz,zzz)=FCL_Elliptic_ZZ.ecZZ_Dbl(Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1],1,1);
        (Pow64_PQ[j+4][0],   Pow64_PQ[j+4][1])=FCL_Elliptic_ZZ.ecZZ_SetAff(x,y,zz,zzz);
     	}
     }
     
     /* neutral point */
     Prec[0][0]=0;
     Prec[0][1]=0;
     
     	
     for(uint i=1;i<256;i++)
     {       
        Prec[i][0]=0;
        Prec[i][1]=0;
        
        for(uint j=0;j<8;j++)
        {
        	if( (i&(1<<j))!=0){
        		(Prec[i][0], Prec[i][1])=FCL_Elliptic_ZZ.ecAff_add(Pow64_PQ[j][0], Pow64_PQ[j][1], Prec[i][0], Prec[i][1]);
        	}
        }
         
     }
     return Prec;
    }

}