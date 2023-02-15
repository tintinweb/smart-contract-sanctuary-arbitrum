//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
// 2021 Remco Bloemen
//       cleaned up code
//       added InvalidProve() error
//       always revert with InvalidProof() on invalid proof
//       make DecryptPairing strict
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4 || ^0.8.17;

library DecryptPairing {
  error InvalidProof();

  // The prime q in the base field F_q for G1
  uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  // The prime moludus of the scalar field of G1.
  uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  struct G1Point {
    uint256 X;
    uint256 Y;
  }

  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  /// @return the generator of G1
  function P1() internal pure returns (G1Point memory) {
    return G1Point(1, 2);
  }

  /// @return the generator of G2
  function P2() internal pure returns (G2Point memory) {
    return
      G2Point(
        [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]
      );
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    // Validate input or revert
    if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) revert InvalidProof();
    // We know p.Y > 0 and p.Y < BASE_MODULUS.
    return G1Point(p.X, BASE_MODULUS - p.Y);
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
    // on the curve.
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
    // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
    if (s >= SCALAR_MODULUS) revert InvalidProof();
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// Asserts the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
  function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) internal view {
    // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
    // respective groups of the right order.
    if (p1.length != p2.length) revert InvalidProof();
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[0];
      input[i * 6 + 3] = p2[i].X[1];
      input[i * 6 + 4] = p2[i].Y[0];
      input[i * 6 + 5] = p2[i].Y[1];
    }
    uint256[1] memory out;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
    }
    if (!success || out[0] != 1) revert InvalidProof();
  }
}

contract DecryptVerifier {
  using DecryptPairing for *;

  struct VerifyingKey {
    DecryptPairing.G1Point alfa1;
    DecryptPairing.G2Point beta2;
    DecryptPairing.G2Point gamma2;
    DecryptPairing.G2Point delta2;
    DecryptPairing.G1Point[] IC;
  }

  struct Proof {
    DecryptPairing.G1Point A;
    DecryptPairing.G2Point B;
    DecryptPairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = DecryptPairing.G1Point(
      14378794661994809316668936077887579852844330409586136188493910229510707683568,
      19007180918058273234125706522281291487787880146734549337345180962710738215208
    );

    vk.beta2 = DecryptPairing.G2Point(
      [5920706861016946300912146506670818945013737603659177373891149557636543490740, 12055325713222300848813253111985210672218263044214498326157766255150057128762],
      [9700420230412290932994502491200547761155381189822684608735830492099336040170, 14277278647337675353039880797101698215986155900184787257566473040310971051502]
    );

    vk.gamma2 = DecryptPairing.G2Point(
      [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
      [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
    );

    vk.delta2 = DecryptPairing.G2Point(
      [15785893523396951181177254604054774614805105770898488733428886575688651348925, 16323955561733349237282980847928857160487715121082282770487384866165124388166],
      [3661438214810646436731793928574238156015373719910210145493771810956817069286, 18059439050688824494217094704558682809700840244025422059661809127248310292782]
    );

    vk.IC = new DecryptPairing.G1Point[](9);

    
      vk.IC[0] = DecryptPairing.G1Point(
        5932026459382860604309440879316683197022918149003360191294155741233703232289,
        10190564836545696514491179333959855931734797168140754412925505292086287456157
      );
    
      vk.IC[1] = DecryptPairing.G1Point(
        18867335583493634013472831141177954825293424828688421198228525342030670068104,
        15381268465466397414659863328587624695240059970282915771760871594047824107403
      );
    
      vk.IC[2] = DecryptPairing.G1Point(
        11286506025338942578952255893420408569906554872704554862467620266108132264197,
        2491405715760472509167562261482717498704059700756396771077313263264637414832
      );
    
      vk.IC[3] = DecryptPairing.G1Point(
        3287473577425372258045407890427028857264800329136703662219819676329065521491,
        8621055055780158700687294516025314839109090879823278356759396109602531212398
      );
    
      vk.IC[4] = DecryptPairing.G1Point(
        13486231092071464017060066625879173946215137105871834475708368644662546379148,
        21121436964731053158654352717071962384336756797046584661227286306159111031971
      );
    
      vk.IC[5] = DecryptPairing.G1Point(
        14109275663321771783314980339181158967602422131270775459802129831737860909306,
        16924660254912023791796764707642347850615242421495467769065197379355986460351
      );
    
      vk.IC[6] = DecryptPairing.G1Point(
        3419883549205188749055793320564337243174009629574444717611782109291182659583,
        4382834526475882549762033295157581547532804093976887401310358307095345650082
      );
    
      vk.IC[7] = DecryptPairing.G1Point(
        3223962897746138668639029759885991824463607401137866309854517055540083501524,
        16082885970618257756451494366838606402295679026944717495804110892597399020825
      );
    
      vk.IC[8] = DecryptPairing.G1Point(
        8913096594893157129832389718939680598171595295898154761061549479290918885343,
        743871532215761266358119443417771343521019768458421024672232959183096442227
      );
    
  }

  /// @dev Verifies a Semaphore proof. Reverts with InvalidProof if the proof is invalid.
  function verifyProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[8] memory input
  ) public view {
    // If the values are not in the correct range, the DecryptPairing contract will revert.
    Proof memory proof;
    proof.A = DecryptPairing.G1Point(a[0], a[1]);
    proof.B = DecryptPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = DecryptPairing.G1Point(c[0], c[1]);

    VerifyingKey memory vk = verifyingKey();

    // Compute the linear combination vk_x of inputs times IC
    if (input.length + 1 != vk.IC.length) revert DecryptPairing.InvalidProof();
    DecryptPairing.G1Point memory vk_x = vk.IC[0];
    for (uint i = 0; i < input.length; i++) {
      vk_x = DecryptPairing.addition(vk_x, DecryptPairing.scalar_mul(vk.IC[i+1], input[i]));
    }

    // Check pairing
    DecryptPairing.G1Point[] memory p1 = new DecryptPairing.G1Point[](4);
    DecryptPairing.G2Point[] memory p2 = new DecryptPairing.G2Point[](4);
    p1[0] = DecryptPairing.negate(proof.A);
    p2[0] = proof.B;
    p1[1] = vk.alfa1;
    p2[1] = vk.beta2;
    p1[2] = vk_x;
    p2[2] = vk.gamma2;
    p1[3] = proof.C;
    p2[3] = vk.delta2;
    DecryptPairing.pairingCheck(p1, p2);
  }
}