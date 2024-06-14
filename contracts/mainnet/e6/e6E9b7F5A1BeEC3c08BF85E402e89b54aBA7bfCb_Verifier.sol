// SPDX-License-Identifier: MIT
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.20;

/// @title Pairing
/// @notice A library implementing the alt_bn128 elliptic curve operations.
library Pairing {
  uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  struct G1Point {
    uint256 x;
    uint256 y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] x;
    uint256[2] y;
  }

  /// @notice custom errors
  error PairingAddFailed();
  error PairingMulFailed();
  error PairingOpcodeFailed();

  /// @notice The negation of p, i.e. p.plus(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
    // The prime q in the base field F_q for G1
    if (p.x == 0 && p.y == 0) {
      return G1Point(0, 0);
    } else {
      return G1Point(p.x, PRIME_Q - (p.y % PRIME_Q));
    }
  }

  /// @notice r Returns the sum of two points of G1.
  function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    uint256[4] memory input;
    input[0] = p1.x;
    input[1] = p1.y;
    input[2] = p2.x;
    input[3] = p2.y;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingAddFailed();
    }
  }

  /// @notice r Return the product of a point on G1 and a scalar, i.e.
  ///         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
  ///         points p.
  function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    uint256[3] memory input;
    input[0] = p.x;
    input[1] = p.y;
    input[2] = s;
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingMulFailed();
    }
  }

  /// @return isValid The result of computing the pairing check
  ///         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  ///        For example,
  ///        pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
  function pairing(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool isValid) {
    G1Point[4] memory p1;
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;

    G2Point[4] memory p2;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;

    uint256 inputSize = 24;
    uint256[] memory input = new uint256[](inputSize);

    for (uint8 i = 0; i < 4; ) {
      uint8 j = i * 6;
      input[j + 0] = p1[i].x;
      input[j + 1] = p1[i].y;
      input[j + 2] = p2[i].x[0];
      input[j + 3] = p2[i].x[1];
      input[j + 4] = p2[i].y[0];
      input[j + 5] = p2[i].y[1];

      unchecked {
        i++;
      }
    }

    uint256[1] memory out;
    bool success;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }

    if (!success) {
      revert PairingOpcodeFailed();
    }

    isValid = out[0] != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { Pairing } from "./Pairing.sol";

/// @title SnarkCommon
/// @notice a Contract which holds a struct
/// representing a Groth16 verifying key
contract SnarkCommon {
  /// @notice a struct representing a Groth16 verifying key
  struct VerifyingKey {
    Pairing.G1Point alpha1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] ic;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SnarkConstants
/// @notice This contract contains constants related to the SNARK
/// components of MACI.
contract SnarkConstants {
  /// @notice The scalar field
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;

  /// @notice The public key here is the first Pedersen base
  /// point from iden3's circomlib implementation of the Pedersen hash.
  /// Since it is generated using a hash-to-curve function, we are
  /// confident that no-one knows the private key associated with this
  /// public key. See:
  /// https://github.com/iden3/circomlib/blob/d5ed1c3ce4ca137a6b3ca48bec4ac12c1b38957a/src/pedersen_printbases.js
  /// Its hash should equal
  /// 6769006970205099520508948723718471724660867171122235270773600567925038008762.
  uint256 internal constant PAD_PUBKEY_X =
    10457101036533406547632367118273992217979173478358440826365724437999023779287;
  uint256 internal constant PAD_PUBKEY_Y =
    19824078218392094440610104313265183977899662750282163392862422243483260492317;

  /// @notice The Keccack256 hash of 'Maci'
  uint256 internal constant NOTHING_UP_MY_SLEEVE =
    8370432830353022751713833565135785980866757267633941821328460903436894336785;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Pairing } from "./Pairing.sol";
import { SnarkConstants } from "./SnarkConstants.sol";
import { SnarkCommon } from "./SnarkCommon.sol";
import { IVerifier } from "../interfaces/IVerifier.sol";

/// @title Verifier
/// @notice a Groth16 verifier contract
contract Verifier is IVerifier, SnarkConstants, SnarkCommon {
  struct Proof {
    Pairing.G1Point a;
    Pairing.G2Point b;
    Pairing.G1Point c;
  }

  using Pairing for *;

  uint256 public constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  /// @notice custom errors
  error InvalidProofQ();
  error InvalidInputVal();

  /// @notice Verify a zk-SNARK proof
  /// @param _proof The proof
  /// @param vk The verifying key
  /// @param input The public inputs to the circuit
  /// @return isValid Whether the proof is valid given the verifying key and public
  ///          input. Note that this function only supports one public input.
  ///          Refer to the Semaphore source code for a verifier that supports
  ///          multiple public inputs.
  function verify(
    uint256[8] memory _proof,
    VerifyingKey memory vk,
    uint256 input
  ) public view override returns (bool isValid) {
    Proof memory proof;
    proof.a = Pairing.G1Point(_proof[0], _proof[1]);
    proof.b = Pairing.G2Point([_proof[2], _proof[3]], [_proof[4], _proof[5]]);
    proof.c = Pairing.G1Point(_proof[6], _proof[7]);

    // Make sure that proof.A, B, and C are each less than the prime q
    checkPoint(proof.a.x);
    checkPoint(proof.a.y);
    checkPoint(proof.b.x[0]);
    checkPoint(proof.b.y[0]);
    checkPoint(proof.b.x[1]);
    checkPoint(proof.b.y[1]);
    checkPoint(proof.c.x);
    checkPoint(proof.c.y);

    // Make sure that the input is less than the snark scalar field
    if (input >= SNARK_SCALAR_FIELD) {
      revert InvalidInputVal();
    }

    // Compute the linear combination vk_x
    Pairing.G1Point memory vkX = Pairing.G1Point(0, 0);

    vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.ic[1], input));

    vkX = Pairing.plus(vkX, vk.ic[0]);

    isValid = Pairing.pairing(
      Pairing.negate(proof.a),
      proof.b,
      vk.alpha1,
      vk.beta2,
      vkX,
      vk.gamma2,
      proof.c,
      vk.delta2
    );
  }

  function checkPoint(uint256 point) internal pure {
    if (point >= PRIME_Q) {
      revert InvalidProofQ();
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { SnarkCommon } from "../crypto/SnarkCommon.sol";

/// @title IVerifier
/// @notice an interface for a Groth16 verifier contract
interface IVerifier {
  /// @notice Verify a zk-SNARK proof
  /// @param _proof The proof
  /// @param vk The verifying key
  /// @param input The public inputs to the circuit
  /// @return Whether the proof is valid given the verifying key and public
  ///          input. Note that this function only supports one public input.
  ///          Refer to the Semaphore source code for a verifier that supports
  ///          multiple public inputs.
  function verify(
    uint256[8] memory _proof,
    SnarkCommon.VerifyingKey memory vk,
    uint256 input
  ) external view returns (bool);
}