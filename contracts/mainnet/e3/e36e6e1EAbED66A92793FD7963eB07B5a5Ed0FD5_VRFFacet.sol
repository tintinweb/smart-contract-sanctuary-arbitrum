// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/LibVRF.sol";

contract VRFFacet {
    /// @notice Verifies a VRF proof
    /// @param _publicKey public key in the VRF
    /// @param _proof VRF proof
    /// @param _message message that was used to generate the VRF
    /// @return bool indicating whether the proof is valid
    function verify(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof, //pi
        bytes memory _message //alpha
    ) external pure returns (bool) {
        return LibVRF.verify(_publicKey, _proof, _message);
    }

    /// @notice Fast verification of a VRF proof
    /// @param _publicKey public key in the VRF
    /// @param _proof VRF proof
    /// @param _message message that was used to generate the VRF
    /// @param _uPoint point on the elliptic curve used for fast verification
    /// @param _vComponents components of the point used for fast verification
    /// @return bool indicating whether the proof is valid
    function fastVerify(
        uint256[2] memory _publicKey, //Y-x, Y-y
        uint256[4] memory _proof, //pi, which is D, a.k.a. gamma-x, gamma-y, c, s
        bytes memory _message, //alpha string
        uint256[2] memory _uPoint, //U-x, U-y
        uint256[4] memory _vComponents //s*H -x, s*H -y, c*Gamma -x, c*Gamma -y
    ) external pure returns (bool) {
        return LibVRF.fastVerify(_publicKey, _proof, _message, _uPoint, _vComponents);
    }

    /// @notice Converts the gamma point in the VRF to a bytes32 hash
    /// @param _gammaX x-coordinate of the gamma point
    /// @param _gammaY y-coordinate of the gamma point
    /// @return bytes32 hash of the gamma point
    function gammaToHash(uint256 _gammaX, uint256 _gammaY) external pure returns (bytes32) {
        return LibVRF.gammaToHash(_gammaX, _gammaY);
    }

    /// @notice Computes the parameters needed for fast verification of a VRF proof
    /// @param _publicKey public key in the VRF
    /// @param _proof VRF proof
    /// @param _message message that was used to generate the VRF
    /// @return point on the elliptic curve and components of the point used for fast verification
    function computeFastVerifyParams(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof,
        bytes memory _message
    ) external pure returns (uint256[2] memory, uint256[4] memory) {
        return LibVRF.computeFastVerifyParams(_publicKey, _proof, _message);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * Modified for Randomizer by deanpress
 * @author Witnet Foundation
 */
library EllipticCurve {
    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // Constant `a` of EC equation
    uint256 public constant AA = 0;
    // Constant `b` of EC equation
    uint256 public constant BB = 7;
    // Prime number of the curve
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @dev Modular euclidean inverse of a number (mod p).
    /// @param _x The number
    /// @return q such that x*q = 1 (mod PP)
    function invMod(uint256 _x) internal pure returns (uint256) {
        require(_x != 0 && _x != PP, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = PP;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (PP - mulmod(t, newT, PP)), PP));
            (r, _x) = (_x, r - t * _x);
        }

        return q;
    }

    /// @dev Modular exponentiation, b^e % PP.
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @return r such that r = b**e (mod PP)
    function expMod(uint256 _base, uint256 _exp) internal pure returns (uint256) {
        require(PP != 0, "Modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, bit)))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), PP)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z);
        uint256 zInv2 = mulmod(zInv, zInv, PP);
        uint256 x2 = mulmod(_x, zInv2, PP);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, PP), PP);

        return (x2, y2);
    }

    /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
    /// @param _prefix parity byte (0x02 even, 0x03 odd)
    /// @param _x coordinate x
    /// @return y coordinate y
    function deriveY(uint8 _prefix, uint256 _x) internal pure returns (uint256) {
        require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

        // x^3 + ax + b
        uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, PP), PP), addmod(mulmod(_x, AA, PP), BB, PP), PP);
        y2 = expMod(y2, (PP + 1) / 4);
        // uint256 cmp = yBit ^ y_ & 1;
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : PP - y2;

        return y;
    }

    /// @dev Check whether point (x,y) is on curve defined by a, b, and PP.
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return true if x,y in the curve, false else
    function isOnCurve(uint256 _x, uint256 _y) internal pure returns (bool) {
        if (0 == _x || _x >= PP || 0 == _y || _y >= PP) {
            return false;
        }
        // y^2
        uint256 lhs = mulmod(_y, _y, PP);
        // x^3
        uint256 rhs = mulmod(mulmod(_x, _x, PP), _x, PP);
        if (AA != 0) {
            // x^3 + a*x
            rhs = addmod(rhs, mulmod(_x, AA, PP), PP);
        }
        if (BB != 0) {
            // x^3 + a*x + b
            rhs = addmod(rhs, BB, PP);
        }

        return lhs == rhs;
    }

    /// @dev Calculate inverse (x, -y) of point (x, y).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return (x, -y)
    function ecInv(uint256 _x, uint256 _y) internal pure returns (uint256, uint256) {
        return (_x, (PP - _y) % PP);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, PP) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, 1);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, 1, _x2, _y2, 1);
        }
        // Get back to affine
        return toAffine(x, y, z);
    }

    /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @return (qx, qy) = P1-P2 in affine coordinates
    function ecSub(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2
    ) internal pure returns (uint256, uint256) {
        // invert square
        (uint256 x, uint256 y) = ecInv(_x2, _y2);
        // P1-square
        return ecAdd(_x1, _y1, x, y);
    }

    /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
    /// @param _k scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @return (qx, qy) = d*P in affine coordinates
    function ecMul(
        uint256 _k,
        uint256 _x,
        uint256 _y
    ) internal pure returns (uint256, uint256) {
        // Jacobian multiplication
        (uint256 x1, uint256 y1, uint256 z1) = jacMul(_k, _x, _y, 1);
        // Get back to affine
        return toAffine(x1, y1, z1);
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        uint256[4] memory zs;
        // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, PP);
        zs[1] = mulmod(_z1, zs[0], PP);
        zs[2] = mulmod(_z2, _z2, PP);
        zs[3] = mulmod(_z2, zs[2], PP);

        // u1, s1, u2, s2
        zs = [mulmod(_x1, zs[2], PP), mulmod(_y1, zs[3], PP), mulmod(_x2, zs[0], PP), mulmod(_y2, zs[1], PP)];

        // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
        require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

        uint256[4] memory hr;
        //h
        hr[0] = addmod(zs[2], PP - zs[0], PP);
        //r
        hr[1] = addmod(zs[3], PP - zs[1], PP);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], PP);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], PP);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], PP), PP - hr[3], PP);
        qx = addmod(qx, PP - mulmod(2, mulmod(zs[0], hr[2], PP), PP), PP);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], PP), PP - qx, PP), PP);
        qy = addmod(qy, PP - mulmod(zs[1], hr[3], PP), PP);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, PP), PP);
        return (qx, qy, qz);
    }

    /// @dev Doubles a points (x, y, z).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        // x, y, z at this point represent the squares of _x, _y, _z
        uint256 x = mulmod(_x, _x, PP);
        //x1^2
        uint256 y = mulmod(_y, _y, PP);
        //y1^2
        uint256 z = mulmod(_z, _z, PP);
        //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, PP), PP);
        // m
        uint256 m = addmod(mulmod(3, x, PP), mulmod(AA, mulmod(z, z, PP), PP), PP);

        // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
        // This allows to reduce the gas cost and stack footprint of the algorithm
        // qx
        x = addmod(mulmod(m, m, PP), PP - addmod(s, s, PP), PP);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(mulmod(m, addmod(s, PP - x, PP), PP), PP - mulmod(8, mulmod(y, y, PP), PP), PP);
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, PP), PP);

        return (x, y, z);
    }

    /// @dev Multiply point (x, y, z) times d.
    /// @param _d scalar to multiply
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @return (qx, qy, qz) d*P1 in Jacobian
    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // Early return in case that `_d == 0`
        if (_d == 0) {
            return (_x, _y, _z);
        }

        uint256 remaining = _d;
        uint256 qx = 0;
        uint256 qy = 0;
        uint256 qz = 1;

        // Double and add algorithm
        while (remaining != 0) {
            if ((remaining & 1) != 0) {
                (qx, qy, qz) = jacAdd(qx, qy, qz, _x, _y, _z);
            }
            remaining = remaining / 2;
            (_x, _y, _z) = jacDouble(_x, _y, _z);
        }
        return (qx, qy, qz);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../libraries/EllipticCurve.sol";

/**
 * @title Verifiable Random Functions (VRF)
 * @notice Library verifying VRF proofs using the `Secp256k1` curve and the `SHA256` hash function.
 * @dev This library follows the algorithms described in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04) and [RFC6979](https://tools.ietf.org/html/rfc6979).
 * It supports the _SECP256K1_SHA256_TAI_ cipher suite, i.e. the aforementioned algorithms using `SHA256` and the `Secp256k1` curve.
 * @author Witnet Foundation (with changes by @deanpress)
 */

library LibVRF {
    /**
     * Secp256k1 parameters
     */

    // Generator coordinate `x` of the EC curve
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // Generator coordinate `y` of the EC curve
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    // Order of the curve
    uint256 public constant NN = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    /// @dev Public key derivation from private key.
    /// Warning: this function should not be used to derive your public key as it would expose the private key.
    /// @param _d The scalar
    /// @param _x The coordinate x
    /// @param _y The coordinate y
    /// @return (qx, qy) The derived point
    function derivePoint(
        uint256 _d,
        uint256 _x,
        uint256 _y
    ) internal pure returns (uint256, uint256) {
        return EllipticCurve.ecMul(_d, _x, _y);
    }

    /// @dev Function to derive the `y` coordinate given the `x` coordinate and the parity byte (`0x03` for odd `y` and `0x04` for even `y`).
    /// @param _yByte The parity byte following the ec point compressed format
    /// @param _x The coordinate `x` of the point
    /// @return The coordinate `y` of the point
    function deriveY(uint8 _yByte, uint256 _x) internal pure returns (uint256) {
        return EllipticCurve.deriveY(_yByte, _x);
    }

    /// @dev Computes the VRF hash output as result of the digest of a ciphersuite-dependent prefix
    /// concatenated with the gamma point
    /// @param _gammaX The x-coordinate of the gamma EC point
    /// @param _gammaY The y-coordinate of the gamma EC point
    /// @return The VRF hash ouput as shas256 digest
    function gammaToHash(uint256 _gammaX, uint256 _gammaY) internal pure returns (bytes32) {
        bytes memory c = abi.encodePacked(
            // Cipher suite code (SECP256K1-SHA256-TAI is 0xFE)
            uint8(0xFE),
            // 0x03
            uint8(0x03),
            // Compressed Gamma Point
            encodePoint(_gammaX, _gammaY)
        );

        return sha256(c);
    }

    /// @dev VRF verification by providing the public key, the message and the VRF proof.
    /// This function computes several elliptic curve operations which may lead to extensive gas consumption.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @return true, if VRF proof is valid
    function verify(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof, //pi
        bytes memory _message //alpha
    ) internal pure returns (bool) {
        // Step 2: Hash to try and increment (outputs a hashed value, a finite EC point in G)
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);

        // Step 3: U = s*B - c*Y (where B is the generator)
        (uint256 uPointX, uint256 uPointY) = ecMulSubMul(
            _proof[3],
            GX,
            GY,
            _proof[2],
            _publicKey[0],
            _publicKey[1]
        );

        // Step 4: V = s*H - c*Gamma
        (uint256 vPointX, uint256 vPointY) = ecMulSubMul(
            _proof[3],
            hPointX,
            hPointY,
            _proof[2],
            _proof[0],
            _proof[1]
        );

        // Step 5: derived c from hash points(...)
        bytes16 derivedC = hashPoints(
            hPointX,
            hPointY,
            _proof[0],
            _proof[1],
            uPointX,
            uPointY,
            vPointX,
            vPointY
        );

        // Step 6: Check validity c == c'
        return uint128(derivedC) == _proof[2];
    }

    /// @dev VRF fast verification by providing the public key, the message, the VRF proof and several intermediate elliptic curve points that enable the verification shortcut.
    /// This function leverages the EVM's `ecrecover` precompile to verify elliptic curve multiplications by decreasing the security from 32 to 20 bytes.
    /// Based on the original idea of Vitalik Buterin: https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @param _uPoint The `u` EC point defined as `U = s*B - c*Y`
    /// @param _vComponents The components required to compute `v` as `V = s*H - c*Gamma`
    /// @return true, if VRF proof is valid
    function fastVerify(
        uint256[2] memory _publicKey, //Y-x, Y-y
        uint256[4] memory _proof, //pi, which is D, a.k.a. gamma-x, gamma-y, c, s
        bytes memory _message, //alpha string
        uint256[2] memory _uPoint, //U-x, U-y
        uint256[4] memory _vComponents //s*H -x, s*H -y, c*Gamma -x, c*Gamma -y
    ) internal pure returns (bool) {
        // Step 2: Hash to try and increment -> hashed value, a finite EC point in G
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);

        // Step 3 & Step 4:
        // U = s*B - c*Y (where B is the generator)
        // V = s*H - c*Gamma
        if (
            !ecMulSubMulVerify(
                _proof[3], //s
                _proof[2], //c
                _publicKey[0], //Y-x
                _publicKey[1], //Y-y
                _uPoint[0], //U-x
                _uPoint[1]
            ) || //U-y
            !ecMulVerify(
                _proof[3], //s
                hPointX, //H-x
                hPointY, //H-y
                _vComponents[0], //s*H -x
                _vComponents[1]
            ) || //s*H -y
            !ecMulVerify(
                _proof[2], //c
                _proof[0], //gamma-x
                _proof[1], //gamma-y
                _vComponents[2], //c*Gamma -x
                _vComponents[3]
            ) //c*Gamma -y
        ) {
            return false;
        }

        (uint256 vPointX, uint256 vPointY) = EllipticCurve.ecSub(
            _vComponents[0], //s*H -x
            _vComponents[1], //s*H -y
            _vComponents[2], //c*Gamma -x
            _vComponents[3] //c*Gamma -y
        );

        // Step 5: derived c from hash points(...)
        bytes16 derivedC = hashPoints(
            hPointX,
            hPointY,
            _proof[0],
            _proof[1],
            _uPoint[0],
            _uPoint[1],
            vPointX,
            vPointY
        );

        // Step 6: Check validity c == c'
        return uint128(derivedC) == _proof[2];
    }

    /// @dev Decode VRF proof from bytes
    /// @param _proof The VRF proof as bytes
    /// @return The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    function decodeProof(bytes memory _proof) internal pure returns (uint256[4] memory) {
        require(_proof.length == 81, "Malformed VRF proof");
        uint8 gammaSign;
        uint256 gammaX;
        uint128 c;
        uint256 s;
        assembly {
            gammaSign := mload(add(_proof, 1))
            gammaX := mload(add(_proof, 33))
            c := mload(add(_proof, 49))
            s := mload(add(_proof, 81))
        }
        uint256 gammaY = deriveY(gammaSign, gammaX);

        return [gammaX, gammaY, c, s];
    }

    /// @dev Decode EC point from bytes
    /// @param _point The EC point as bytes
    /// @return The point as `[point-x, point-y]`
    function decodePoint(bytes memory _point) internal pure returns (uint256[2] memory) {
        require(_point.length == 33, "Malformed compressed EC point");
        uint8 sign;
        uint256 x;
        assembly {
            sign := mload(add(_point, 1))
            x := mload(add(_point, 33))
        }
        uint256 y = deriveY(sign, x);

        return [x, y];
    }

    /// @dev Compute the parameters (EC points) required for the VRF fast verification function.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`
    /// @param _message The message (in bytes) used for computing the VRF
    /// @return The fast verify required parameters as the tuple `([uPointX, uPointY], [sHX, sHY, cGammaX, cGammaY])`
    function computeFastVerifyParams(
        uint256[2] memory _publicKey,
        uint256[4] memory _proof,
        bytes memory _message
    ) internal pure returns (uint256[2] memory, uint256[4] memory) {
        // Requirements for Step 3: U = s*B - c*Y (where B is the generator)
        (uint256 hPointX, uint256 hPointY) = hashToTryAndIncrement(_publicKey, _message);
        (uint256 uPointX, uint256 uPointY) = ecMulSubMul(
            _proof[3],
            GX,
            GY,
            _proof[2],
            _publicKey[0],
            _publicKey[1]
        );
        // Requirements for Step 4: V = s*H - c*Gamma
        (uint256 sHX, uint256 sHY) = derivePoint(_proof[3], hPointX, hPointY);
        (uint256 cGammaX, uint256 cGammaY) = derivePoint(_proof[2], _proof[0], _proof[1]);

        return ([uPointX, uPointY], [sHX, sHY, cGammaX, cGammaY]);
    }

    /// @dev Function to convert a `Hash(PK|DATA)` to a point in the curve as defined in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04).
    /// Used in Step 2 of VRF verification function.
    /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`
    /// @param _message The message used for computing the VRF
    /// @return The hash point in affine cooridnates
    function hashToTryAndIncrement(uint256[2] memory _publicKey, bytes memory _message)
        internal
        pure
        returns (uint256, uint256)
    {
        // Step 1: public key to bytes
        // Step 2: V = cipher_suite | 0x01 | public_key_bytes | message | ctr
        bytes memory c = abi.encodePacked(
            // Cipher suite code (SECP256K1-SHA256-TAI is 0xFE)
            uint8(254),
            // 0x01
            uint8(1),
            // Public Key
            encodePoint(_publicKey[0], _publicKey[1]),
            // Message
            _message
        );

        // Step 3: find a valid EC point
        // Loop over counter ctr starting at 0x00 and do hash
        uint8 ctr = 0;
        do {
            // Counter update
            // c[cLength-1] = byte(ctr);
            bytes32 sha = sha256(abi.encodePacked(c, ctr));
            // Step 4: arbitraty string to point and check if it is on curve
            uint256 hPointX = uint256(sha);
            uint256 hPointY = deriveY(2, hPointX);
            if (EllipticCurve.isOnCurve(hPointX, hPointY)) {
                // Step 5 (omitted): calculate H (cofactor is 1 on secp256k1)
                // If H is not "INVALID" and cofactor > 1, set H = cofactor * H
                return (hPointX, hPointY);
            }
            unchecked {
                ++ctr;
            }
        } while (ctr < 256);
        revert("No valid point was found");
    }

    /// @dev Function to hash a certain set of points as specified in [VRF-draft-04](https://tools.ietf.org/pdf/draft-irtf-cfrg-vrf-04).
    /// Used in Step 5 of VRF verification function.
    /// @param _hPointX The coordinate `x` of point `H`
    /// @param _hPointY The coordinate `y` of point `H`
    /// @param _gammaX The coordinate `x` of the point `Gamma`
    /// @param _gammaX The coordinate `y` of the point `Gamma`
    /// @param _uPointX The coordinate `x` of point `U`
    /// @param _uPointY The coordinate `y` of point `U`
    /// @param _vPointX The coordinate `x` of point `V`
    /// @param _vPointY The coordinate `y` of point `V`
    /// @return The first half of the digest of the points using SHA256
    function hashPoints(
        uint256 _hPointX,
        uint256 _hPointY,
        uint256 _gammaX,
        uint256 _gammaY,
        uint256 _uPointX,
        uint256 _uPointY,
        uint256 _vPointX,
        uint256 _vPointY
    ) internal pure returns (bytes16) {
        bytes memory c = abi.encodePacked(
            // Ciphersuite 0xFE
            uint8(254),
            // Prefix 0x02
            uint8(2),
            // Points to Bytes
            encodePoint(_hPointX, _hPointY),
            encodePoint(_gammaX, _gammaY),
            encodePoint(_uPointX, _uPointY),
            encodePoint(_vPointX, _vPointY)
        );
        // Hash bytes and truncate
        bytes32 sha = sha256(c);
        bytes16 half1;
        assembly {
            let freemem_pointer := mload(0x40)
            mstore(add(freemem_pointer, 0x00), sha)
            half1 := mload(add(freemem_pointer, 0x00))
        }

        return half1;
    }

    /// @dev Encode an EC point to bytes
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @return The point coordinates as bytes
    function encodePoint(uint256 _x, uint256 _y) internal pure returns (bytes memory) {
        uint8 prefix = uint8(2 + (_y % 2));

        return abi.encodePacked(prefix, _x);
    }

    /// @dev Substracts two key derivation functionsas `s1*A - s2*B`.
    /// @param _scalar1 The scalar `s1`
    /// @param _a1 The `x` coordinate of point `A`
    /// @param _a2 The `y` coordinate of point `A`
    /// @param _scalar2 The scalar `s2`
    /// @param _b1 The `x` coordinate of point `B`
    /// @param _b2 The `y` coordinate of point `B`
    /// @return The derived point in affine cooridnates
    function ecMulSubMul(
        uint256 _scalar1,
        uint256 _a1,
        uint256 _a2,
        uint256 _scalar2,
        uint256 _b1,
        uint256 _b2
    ) internal pure returns (uint256, uint256) {
        (uint256 m1, uint256 m2) = derivePoint(_scalar1, _a1, _a2);
        (uint256 n1, uint256 n2) = derivePoint(_scalar2, _b1, _b2);
        (uint256 r1, uint256 r2) = EllipticCurve.ecSub(m1, m2, n1, n2);

        return (r1, r2);
    }

    /// @dev Verify an Elliptic Curve multiplication of the form `(qx,qy) = scalar*(x,y)` by using the precompiled `ecrecover` function.
    /// The usage of the precompiled `ecrecover` function decreases the security from 32 to 20 bytes.
    /// Based on the original idea of Vitalik Buterin: https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    /// @param _scalar The scalar of the point multiplication
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @param _qx The coordinate `x` of the multiplication result
    /// @param _qy The coordinate `y` of the multiplication result
    /// @return true, if first 20 bytes match
    function ecMulVerify(
        uint256 _scalar,
        uint256 _x,
        uint256 _y,
        uint256 _qx,
        uint256 _qy
    ) internal pure returns (bool) {
        address result = ecrecover(0, _y % 2 != 0 ? 28 : 27, bytes32(_x), bytes32(mulmod(_scalar, _x, NN)));

        return pointToAddress(_qx, _qy) == result;
    }

    /// @dev Verify an Elliptic Curve operation of the form `Q = scalar1*(gx,gy) - scalar2*(x,y)` by using the precompiled `ecrecover` function, where `(gx,gy)` is the generator of the EC.
    /// The usage of the precompiled `ecrecover` function decreases the security from 32 to 20 bytes.
    /// Based on SolCrypto library: https://github.com/HarryR/solcrypto
    /// @param _scalar1 The scalar of the multiplication of `(gx,gy)`
    /// @param _scalar2 The scalar of the multiplication of `(x,y)`
    /// @param _x The coordinate `x` of the point to be mutiply by `scalar2`
    /// @param _y The coordinate `y` of the point to be mutiply by `scalar2`
    /// @param _qx The coordinate `x` of the equation result
    /// @param _qy The coordinate `y` of the equation result
    /// @return true, if first 20 bytes match
    function ecMulSubMulVerify(
        uint256 _scalar1,
        uint256 _scalar2,
        uint256 _x,
        uint256 _y,
        uint256 _qx,
        uint256 _qy
    ) internal pure returns (bool) {
        uint256 scalar1 = (NN - _scalar1) % NN;
        scalar1 = mulmod(scalar1, _x, NN);
        uint256 scalar2 = (NN - _scalar2) % NN;

        address result = ecrecover(
            bytes32(scalar1),
            _y % 2 != 0 ? 28 : 27,
            bytes32(_x),
            bytes32(mulmod(scalar2, _x, NN))
        );

        return pointToAddress(_qx, _qy) == result;
    }

    /// @dev Gets the address corresponding to the EC point digest (keccak256), i.e. the first 20 bytes of the digest.
    /// This function is used for performing a fast EC multiplication verification.
    /// @param _x The coordinate `x` of the point
    /// @param _y The coordinate `y` of the point
    /// @return The address of the EC point digest (keccak256)
    function pointToAddress(uint256 _x, uint256 _y) internal pure returns (address) {
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(_x, _y)))) &
                    0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            );
    }
}