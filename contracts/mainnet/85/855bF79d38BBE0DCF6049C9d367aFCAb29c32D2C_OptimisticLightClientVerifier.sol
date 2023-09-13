// SPDX-License-Identifier: AML
// 
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

pragma solidity ^0.8.0;

library PairingLightClient {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero. 
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingLightClient-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingLightClient-mul-failed");
    }

    /* @return The result of computing the PairingLightClient check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingLightClient([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingLightClient-opcode-failed");

        return out[0] != 0;
    }
}

contract OptimisticLightClientVerifier {

    using PairingLightClient for *;

    uint256 constant SNARK_SCALAR_FIELD_LIGHTCLIENT = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_LIGHTCLIENT = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyLightClient {
        PairingLightClient.G1Point alfa1;
        PairingLightClient.G2Point beta2;
        PairingLightClient.G2Point gamma2;
        PairingLightClient.G2Point delta2;
        PairingLightClient.G1Point[2] IC;
    }

    struct ProofLightClient {
        PairingLightClient.G1Point A;
        PairingLightClient.G2Point B;
        PairingLightClient.G1Point C;
    }

    function verifyingKeyLightClient() internal pure returns (VerifyingKeyLightClient memory vk) {
        vk.alfa1 = PairingLightClient.G1Point(uint256(6031475046781756289708703650610555645935631767599384370027715621997631807493), uint256(18161476451781692918621063160745662505803537154656403779438002086644629034579));
        vk.beta2 = PairingLightClient.G2Point([uint256(14445134740415896490146369046541479940713698046737542107824674570269010877440), uint256(13248391919240610504885424821304254790596603795215628924245484783351805524496)], [uint256(9535836592145183507581712143790027056103635742248615934152591398496594024473), uint256(2978619003053534116969583553534298385895254914683198475160689818811004900933)]);
        vk.gamma2 = PairingLightClient.G2Point([uint256(9548265994462970135317285957455608287778511256695420081106926546273210916654), uint256(5640872424717602318528415720466297436743047601274375455097638531741382374363)], [uint256(5609673239470596730457564516569225978670469011020169497240637718161473469073), uint256(5285114041630347450419684060273845401034757592290105334077025059458545647803)]);
        vk.delta2 = PairingLightClient.G2Point([uint256(2018962836192090669946620965273036790708729332093371541079763814268976848877), uint256(5292959126713328019457608777688886111414591618283165747471117541978887505441)], [uint256(9752750916524982246405888203194831706798661236000120141612913532808304656337), uint256(5067248939950301738392542998534497710260194841816131810647797811050841036103)]);   
        vk.IC[0] = PairingLightClient.G1Point(uint256(0), uint256(0));   
        vk.IC[1] = PairingLightClient.G1Point(uint256(0), uint256(0));
    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofLightClient memory proof;
        proof.A = PairingLightClient.G1Point(a[0], a[1]);
        proof.B = PairingLightClient.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingLightClient.G1Point(c[0], c[1]);

        VerifyingKeyLightClient memory vk = verifyingKeyLightClient();

        // Compute the linear combination vk_x
        PairingLightClient.G1Point memory vk_x = PairingLightClient.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_LIGHTCLIENT, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_LIGHTCLIENT, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_LIGHTCLIENT, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_LIGHTCLIENT, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_LIGHTCLIENT, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_LIGHTCLIENT, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_LIGHTCLIENT, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_LIGHTCLIENT, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_LIGHTCLIENT,"verifier-gte-snark-scalar-field");
            vk_x = PairingLightClient.plus(vk_x, PairingLightClient.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingLightClient.plus(vk_x, vk.IC[0]);

        return PairingLightClient.pairing(
            PairingLightClient.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}