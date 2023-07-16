pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./PlonkCore.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {

    uint256 constant VK_TREE_ROOT = 0x175161c7eb22ac7582ace00443b1ebcda1ad614db26e7aa24522c028ef033a7e;
    uint8 constant VK_MAX_INDEX = 2;

    function getVkAggregated(uint32 _proofs) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(36)) { return getVkAggregated36(); }
    }

    
    function getVkAggregated36() internal pure returns(VerificationKey memory vk) {
        vk.domain_size = 67108864;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1dba8b5bdd64ef6ce29a9039aca3c0e524395c43b9227b96c75090cc6cc7ec97);
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x0f8b227a5da7ba4ea89c48f80e007c8ef3baf2046f1c70d08117f014d3562b11,
            0x029d905c0222cd7dba8b7058be29e3c9e27d46569ef6e767b2b68aed94ca28a9
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x0692d6f81047f33e794b51f0dba543440ff8edf791de4ef8e44dc07b5caaebe9,
            0x1a3512fbae7189831eb1fa97df18914accd3c6ba1ed12f07c1ee7aca4b9569df
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x1925ded902019bdf78a0cc175969098d468f6f710aae3efc33c573fc04d570ed,
            0x121d43a79f3694088ed4284cc55bd14084f345d7413d57ee4d24ca2f5a05b325
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x09ae8147948bcf4e68df41c0d97ec18022090fcd47e6977162b01df46f94a789,
            0x0eb3002e71052c33aeac2d434b9205e3d0df49fc7b9b10eb5ddf4fe78b8fb2bc
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x28a2d952f64c5e2ff4413b66d39f792e155570acf24a5d87d41ecb405e897005,
            0x222d7eb19a8a91eaedad5ecffacd36fa22bfb8a169b59978af6bfdd4949587d6
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x30164a64d9afb271f1c3588cd08f1df70cefed9451b14dd878b04110f98ed688,
            0x267e525295668cf05e3639cb0175dcf0ced15c0d304461674c0e071984d61362
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x07b5f013828927c63adc77b34c253c89750aa0eed6edacbcc9bcfd7faf96636b,
            0x0e494577844feb77dcb7f629de1c3d270318a6624914e36a0df02a82055c0faf
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1b1c983d52616dbf85c89d91956df529d5b6889466d64c887c46d5bcc5f313f3,
            0x0df990c408dc7fd48a6701f339b215049d7cbe3140a924ea9694854b1a8c0bc2
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x0c36170de45e0ca8b5eb40e0057bf7a49251f69053c1d0577bb2c0f47ea38121,
            0x07727b3f5cecf9bc46a1729821d16455e7d83cd11c2e6679b8bbc4ea88c80d17
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x22c588597bbf905285f8d7ef632d37466902cc85c2dede27c7112c375177b0a6,
            0x1eecbaa1568668aac833258a61eb753e162b34b017f9e64cca2d2852f8639921
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x248441946460d343823f14d62f4d79220b4b85e28df6ea090e5da3756cd2cc6a,
            0x1978e132d816af8d06d532d3f2326902e7b93ff432c007bbeef250e87a18ed8d
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x1410ba9f1a7521551eda450dbbe43c05c6d3ffc169ed6983a1531a5e99a6aaef,
            0x1bb07710b27539fd34925d1ae1c34ed55157dbbc4ea581020943166dc92246b1
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x0484ef7dded821fd523e349d14dd69411fd1ea9f91f01c53e5ef09deee390fd6,
            0x2112b9319c459091b6e21c8b8b3193d32054d1be6414d37a2b00ff4a57186d8c
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    

}

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifierOld is VerifierWithDeserializeOld {

    
    function getVkExit() internal pure returns(VerificationKeyOld memory vk) {
        vk.domain_size = 8388608;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(0x1283ba6f4b7b1a76ba2008fe823128bea4adb9269cbfd7c41c223be65bc60863);
        vk.selector_commitments[0] = PairingsBn254.new_g1(
            0x3008cf85ebac871ab89a36302f4bbd761f9684f84e95ac98527e1adb194792c5,
            0x291a109fc66c4174c17d1de24831f3b335eb11dfe81a0a1d71d0fd40c547d2d8
        );
        vk.selector_commitments[1] = PairingsBn254.new_g1(
            0x287adbf1e6e1b03c46beca322ccbd719245c37ea8fbfe6e869ed32e9e034b50c,
            0x137529cf0e0252f8e16aa96976ce5cf7297c688060b3d095a0e6c63ad0aec761
        );
        vk.selector_commitments[2] = PairingsBn254.new_g1(
            0x2aa527278f0772f73ccdc726e48a5676605b9a54b66b0690ef16893167e633ad,
            0x0db4e23439138b957ea8d9149a8e44e6d86abc562b9eb170508341f7241d492e
        );
        vk.selector_commitments[3] = PairingsBn254.new_g1(
            0x07f7036d3e7b787a51fab25347d29087e291aa40d47a7ce48ee3fc3a898adf63,
            0x15b187b6b5d190c08a9540c630e78d230905a0def16f05ad9d81cc0229661ebc
        );
        vk.selector_commitments[4] = PairingsBn254.new_g1(
            0x0cac78bd72e4a765d0323ef9a46bfc4049f1afaa7f81d3bd0e5178e9b2958b33,
            0x24ac57bc5525dc0c75d2c4e24999bee9170346960454457df118da57145912cc
        );
        vk.selector_commitments[5] = PairingsBn254.new_g1(
            0x198e4480a4aa93c4085054ad681df348fd574814ddac7c97e1bc81ac705dd7c0,
            0x186fbf8382f9e305b831b0bf9169134c7a49becff4f292d2dd207ef28a4084e1
        );

        // we only have access to value of the d(x) witness polynomial on the next
        // trace step, so we only need one element here and deal with it in other places
        // by having this in mind
        vk.next_step_selector_commitments[0] = PairingsBn254.new_g1(
            0x1beb80feebc8e72f9a5cf2e96270ffb6a481918984ce04e58ed708f26b84f93e,
            0x14577c2fc6d1c57c6f2d3240d042b2208f964661c4b7ca24b021f66a72dc0ffd
        );

        vk.permutation_commitments[0] = PairingsBn254.new_g1(
            0x2601f4885bc6843bc137c878b1eb82803502ea01dcbc815541bb7a243b40562f,
            0x2c98930cc7f6249fc692590d06e1f3172f8cfe928c4200b88eecf5267a34c304
        );
        vk.permutation_commitments[1] = PairingsBn254.new_g1(
            0x03f08ef0c60e55baf78af5944e43474915f9d4b4dafdffb95c986c1a375acce3,
            0x2a8dd06b3a859bf43978ca45c6a18876074a9defeb153e6441f4243deee83acb
        );
        vk.permutation_commitments[2] = PairingsBn254.new_g1(
            0x011bfe23a0aa76f02b37570af162172dfed5c0da108f890b458670d6662bca63,
            0x181fccff301b4c86188862578d8811f7c6ec47cb92a5015081f76fa054739fa4
        );
        vk.permutation_commitments[3] = PairingsBn254.new_g1(
            0x29038ff88d21d41377caca58f8b00ae9cd5143b6dfbe4e6cb15843e0e74df9a3,
            0x28da7400cfeaaf5d42275220f73bdc3a4556eeff27b62777696e7a607d945ccc
        );

        vk.permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1, 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],
            [0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4, 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]
        );
    }
    
}

pragma solidity >=0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable




library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod);
        require(y < q_mod);
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs);

        return G1Point(x, y);
    }

    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
        G2Point(
            [
            0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
            0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
            0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
            0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_sub_assign(G1Point memory p1, G1Point memory p2) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
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
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value) internal pure {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(abi.encodePacked(DST_0, old_state_0, self.state_1, value));
        self.state_1 = keccak256(abi.encodePacked(DST_1, old_state_0, self.state_1, value));
    }

    function update_with_fr(Transcript memory self, PairingsBn254.Fr memory value) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(Transcript memory self, PairingsBn254.G1Point memory p) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self) internal pure returns (PairingsBn254.Fr memory challenge) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state_0, self.state_1, self.challenge_counter));
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

contract Plonk4VerifierWithAccessToDNext {
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant ZERO = 0;
    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant THREE = 3;
    uint256 constant FOUR = 4;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant NUM_DIFFERENT_GATES = 2;
    uint256 constant NUM_SETUP_POLYS_FOR_MAIN_GATE = 7;
    uint256 constant NUM_SETUP_POLYS_RANGE_CHECK_GATE = 0;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;
    uint256 constant NUM_GATE_SELECTORS_OPENED_EXPLICITLY = 1;

    uint256 constant RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK =
    0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant LIMB_WIDTH = 68;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[NUM_SETUP_POLYS_FOR_MAIN_GATE + NUM_SETUP_POLYS_RANGE_CHECK_GATE] gate_setup_commitments;
        PairingsBn254.G1Point[NUM_DIFFERENT_GATES] gate_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] copy_permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH - 1] copy_permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr[NUM_GATE_SELECTORS_OPENED_EXPLICITLY] gate_selector_values_at_z;
        PairingsBn254.Fr copy_grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(uint256 domain_size, PairingsBn254.Fr memory at)
    internal
    view
    returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(tmp);
        }

        inputs_term.mul_assign(proof.gate_selector_values_at_z[0]);
        rhs.add_assign(inputs_term);

        // now we need 5th power
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.copy_grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function add_contribution_from_range_constraint_gates(
        PartialVerifierState memory state,
        Proof memory proof,
        PairingsBn254.Fr memory current_alpha
    ) internal pure returns (PairingsBn254.Fr memory res) {
        // now add contribution from range constraint gate
        // we multiply selector commitment by all the factors (alpha*(c - 4d)(c - 4d - 1)(..-2)(..-3) + alpha^2 * (4b - c)()()() + {} + {})

        PairingsBn254.Fr memory one_fr = PairingsBn254.new_fr(ONE);
        PairingsBn254.Fr memory two_fr = PairingsBn254.new_fr(TWO);
        PairingsBn254.Fr memory three_fr = PairingsBn254.new_fr(THREE);
        PairingsBn254.Fr memory four_fr = PairingsBn254.new_fr(FOUR);

        res = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t0 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t2 = PairingsBn254.new_fr(0);

        for (uint256 i = 0; i < 3; i++) {
            current_alpha.mul_assign(state.alpha);

            // high - 4*low

            // this is 4*low
            t0 = PairingsBn254.copy(proof.wire_values_at_z[3 - i]);
            t0.mul_assign(four_fr);

            // high
            t1 = PairingsBn254.copy(proof.wire_values_at_z[2 - i]);
            t1.sub_assign(t0);

            // t0 is now t1 - {0,1,2,3}

            // first unroll manually for -0;
            t2 = PairingsBn254.copy(t1);

            // -1
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(one_fr);
            t2.mul_assign(t0);

            // -2
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(two_fr);
            t2.mul_assign(t0);

            // -3
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(three_fr);
            t2.mul_assign(t0);

            t2.mul_assign(current_alpha);

            res.add_assign(t2);
        }

        // now also d_next - 4a

        current_alpha.mul_assign(state.alpha);

        // high - 4*low

        // this is 4*low
        t0 = PairingsBn254.copy(proof.wire_values_at_z[0]);
        t0.mul_assign(four_fr);

        // high
        t1 = PairingsBn254.copy(proof.wire_values_at_z_omega[0]);
        t1.sub_assign(t0);

        // t0 is now t1 - {0,1,2,3}

        // first unroll manually for -0;
        t2 = PairingsBn254.copy(t1);

        // -1
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(one_fr);
        t2.mul_assign(t0);

        // -2
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(two_fr);
        t2.mul_assign(t0);

        // -3
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(three_fr);
        t2.mul_assign(t0);

        t2.mul_assign(current_alpha);

        res.add_assign(t2);

        return res;
    }

    function reconstruct_linearization_commitment(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^{6} * (selector(x) - selector(z))
        // + v^{7..9} * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^10 (z(x) - z(z*omega)) <- we need this power
        // + v^11 * (d(x) - d(z*omega))
        // ]
        //

        // we reconstruct linearization polynomial virtual selector
        // for that purpose we first linearize over main gate (over all it's selectors)
        // and multiply them by value(!) of the corresponding main gate selector
        res = PairingsBn254.copy_g1(vk.gate_setup_commitments[STATE_WIDTH + 1]); // index of q_const(x)

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.gate_setup_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH + 2].point_mul(proof.wire_values_at_z_omega[0]); // index of q_d_next(x)
        res.point_add_assign(tmp_g1);

        // multiply by main gate selector(z)
        res.point_mul_assign(proof.gate_selector_values_at_z[0]); // these is only one explicitly opened selector

        PairingsBn254.Fr memory current_alpha = PairingsBn254.new_fr(ONE);

        // calculate scalar contribution from the range check gate
        tmp_fr = add_contribution_from_range_constraint_gates(state, proof, current_alpha);
        tmp_g1 = vk.gate_selector_commitments[1].point_mul(tmp_fr); // selector commitment for range constraint gate * scalar
        res.point_add_assign(tmp_g1);

        // proceed as normal to copy permutation
        current_alpha.mul_assign(state.alpha); // alpha^5

        PairingsBn254.Fr memory alpha_for_grand_product = PairingsBn254.copy(current_alpha);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.copy_permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.copy_permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(alpha_for_grand_product);

        // alpha^n & L_{0}(z), and we bump current_alpha
        current_alpha.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(current_alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        // prefactor for grand_product(x) is complete

        // add to the linearization a part from the term
        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.copy_grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(alpha_for_grand_product); // we multiply by the power of alpha from the argument

        // actually multiply prefactors by z(x) and perm_d(x) and combine them
        tmp_g1 = proof.copy_permutation_grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.copy_permutation_commitments[STATE_WIDTH - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        // multiply them by v immedately as linearization has a factor of v^1
        res.point_mul_assign(state.v);
        // res now contains contribution from the gates linearization and
        // copy permutation part

        // now we need to add a part that is the rest
        // for z(x*omega):
        // - (a(z) + beta*perm_a + gamma)*()*()*(d(z) + gamma) * z(x*omega)
    }

    function aggregate_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point[2] memory res) {
        PairingsBn254.G1Point memory d = reconstruct_linearization_commitment(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < NUM_GATE_SELECTORS_OPENED_EXPLICITLY; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.gate_selector_commitments[0].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.copy_permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.copy_permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        // now do prefactor for grand_product(x*omega)
        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        commitment_aggregation.point_add_assign(proof.copy_permutation_grand_product_commitment.point_mul(tmp_fr));

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_fr.assign(proof.gate_selector_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.copy_grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        res[0] = pair_with_generator;
        res[1] = pair_with_x;

        return res;
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.copy_permutation_grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        transcript.update_with_fr(proof.gate_selector_values_at_z[0]);

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.copy_grand_product_at_z_omega);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function aggregate_for_verification(Proof memory proof, VerificationKey memory vk)
    internal
    view
    returns (bool valid, PairingsBn254.G1Point[2] memory part)
    {
        PartialVerifierState memory state;

        valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return (valid, part);
        }

        part = aggregate_commitments(state, proof, vk);

        (valid, part);
    }

    function verify(Proof memory proof, VerificationKey memory vk) internal view returns (bool) {
        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        valid = PairingsBn254.pairingProd2(
            recursive_proof_part[0],
            PairingsBn254.P2(),
            recursive_proof_part[1],
            vk.g2_x
        );

        return valid;
    }

    function verify_recursive(
        Proof memory proof,
        VerificationKey memory vk,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs
    ) internal view returns (bool) {
        (uint256 recursive_input, PairingsBn254.G1Point[2] memory aggregated_g1s) = reconstruct_recursive_public_input(
            recursive_vks_root,
            max_valid_index,
            recursive_vks_indexes,
            individual_vks_inputs,
            subproofs_limbs
        );

        assert(recursive_input == proof.input_values[0]);

        (bool valid, PairingsBn254.G1Point[2] memory recursive_proof_part) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        // aggregated_g1s = inner
        // recursive_proof_part = outer
        PairingsBn254.G1Point[2] memory combined = combine_inner_and_outer(aggregated_g1s, recursive_proof_part);

        valid = PairingsBn254.pairingProd2(combined[0], PairingsBn254.P2(), combined[1], vk.g2_x);

        return valid;
    }

    function combine_inner_and_outer(PairingsBn254.G1Point[2] memory inner, PairingsBn254.G1Point[2] memory outer)
    internal
    view
    returns (PairingsBn254.G1Point[2] memory result)
    {
        // reuse the transcript primitive
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        transcript.update_with_g1(inner[0]);
        transcript.update_with_g1(inner[1]);
        transcript.update_with_g1(outer[0]);
        transcript.update_with_g1(outer[1]);
        PairingsBn254.Fr memory challenge = transcript.get_challenge();
        // 1 * inner + challenge * outer
        result[0] = PairingsBn254.copy_g1(inner[0]);
        result[1] = PairingsBn254.copy_g1(inner[1]);
        PairingsBn254.G1Point memory tmp = outer[0].point_mul(challenge);
        result[0].point_add_assign(tmp);
        tmp = outer[1].point_mul(challenge);
        result[1].point_add_assign(tmp);

        return result;
    }

    function reconstruct_recursive_public_input(
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_aggregated
    ) internal pure returns (uint256 recursive_input, PairingsBn254.G1Point[2] memory reconstructed_g1s) {
        assert(recursive_vks_indexes.length == individual_vks_inputs.length);
        bytes memory concatenated = abi.encodePacked(recursive_vks_root);
        uint8 index;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            index = recursive_vks_indexes[i];
            assert(index <= max_valid_index);
            concatenated = abi.encodePacked(concatenated, index);
        }
        uint256 input;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            input = individual_vks_inputs[i];
            assert(input < r_mod);
            concatenated = abi.encodePacked(concatenated, input);
        }

        concatenated = abi.encodePacked(concatenated, subproofs_aggregated);

        bytes32 commitment = sha256(concatenated);
        recursive_input = uint256(commitment) & RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK;

        reconstructed_g1s[0] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[0] +
            (subproofs_aggregated[1] << LIMB_WIDTH) +
            (subproofs_aggregated[2] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[3] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[4] +
            (subproofs_aggregated[5] << LIMB_WIDTH) +
            (subproofs_aggregated[6] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[7] << (3 * LIMB_WIDTH))
        );

        reconstructed_g1s[1] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[8] +
            (subproofs_aggregated[9] << LIMB_WIDTH) +
            (subproofs_aggregated[10] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[11] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[12] +
            (subproofs_aggregated[13] << LIMB_WIDTH) +
            (subproofs_aggregated[14] << (2 * LIMB_WIDTH)) +
            (subproofs_aggregated[15] << (3 * LIMB_WIDTH))
        );

        return (recursive_input, reconstructed_g1s);
    }
}

contract VerifierWithDeserialize is Plonk4VerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 34;

    function deserialize_proof(uint256[] memory public_inputs, uint256[] memory serialized_proof)
    internal
    pure
    returns (Proof memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.copy_permutation_grand_product_commitment = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j + 1]
        );
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            proof.gate_selector_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.copy_grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }

    function verify_serialized_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify(proof, vk);

        return valid;
    }

    function verify_serialized_proof_with_recursion(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(vk.num_inputs == public_inputs.length);

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify_recursive(
            proof,
            vk,
            recursive_vks_root,
            max_valid_index,
            recursive_vks_indexes,
            individual_vks_inputs,
            subproofs_limbs
        );

        return valid;
    }
}

contract Plonk4VerifierWithAccessToDNextOld {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant STATE_WIDTH_OLD = 4;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD = 1;

    struct VerificationKeyOld {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[STATE_WIDTH_OLD + 2] selector_commitments; // STATE_WIDTH for witness + multiplication + constant
        PairingsBn254.G1Point[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] next_step_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct ProofOld {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] wire_commitments;
        PairingsBn254.G1Point grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH_OLD] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH_OLD] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP_OLD] wire_values_at_z_omega;
        PairingsBn254.Fr grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH_OLD - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierStateOld {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain_old(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size);
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain_old(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0);
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](poly_nums.length);
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](poly_nums.length);
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](poly_nums.length);
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length - 1; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(dens[i]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            dens[i].assign(tmp_2); // all inversed
            dens[i].mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing_old(uint256 domain_size, PairingsBn254.Fr memory at)
    internal
    view
    returns (PairingsBn254.Fr memory res)
    {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing_old(vk.domain_size, state.z);
        require(lhs.value != 0); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(proof.linearization_polynomial_at_z);

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            rhs.add_assign(tmp);
        }

        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(proof.grand_product_at_z_omega);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH_OLD - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function reconstruct_d(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^(6..8) * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^9 (z(x) - z(z*omega)) <- we need this power
        // + v^10 * (d(x) - d(z*omega))
        // ]
        //
        // we pay a little for a few arithmetic operations to not introduce another constant
        uint256 power_for_z_omega_opening = 1 + 1 + STATE_WIDTH_OLD + STATE_WIDTH_OLD - 1;
        res = PairingsBn254.copy_g1(vk.selector_commitments[STATE_WIDTH_OLD + 1]);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            tmp_g1 = vk.selector_commitments[i].point_mul(proof.wire_values_at_z[i]);
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.selector_commitments[STATE_WIDTH_OLD].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.next_step_selector_commitments[0].point_mul(proof.wire_values_at_z_omega[0]);
        res.point_add_assign(tmp_g1);

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(state.z);
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(state.alpha);
        tmp_fr.mul_assign(state.alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        PairingsBn254.Fr memory grand_product_part_at_z_omega = state.v.pow(power_for_z_omega_opening);
        grand_product_part_at_z_omega.mul_assign(state.u);

        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254.new_fr(1);
        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(proof.grand_product_at_z_omega);
        last_permutation_part_at_z.mul_assign(state.alpha);

        // add to the linearization
        tmp_g1 = proof.grand_product_commitment.point_mul(grand_product_part_at_z);
        tmp_g1.point_sub_assign(vk.permutation_commitments[STATE_WIDTH_OLD - 1].point_mul(last_permutation_part_at_z));

        res.point_add_assign(tmp_g1);
        res.point_mul_assign(state.v);

        res.point_add_assign(proof.grand_product_commitment.point_mul(grand_product_part_at_z_omega));
    }

    function verify_commitments(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        PairingsBn254.G1Point memory d = reconstruct_d(state, proof, vk);

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254.copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < vk.permutation_commitments.length - 1; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.permutation_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH_OLD - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(proof.quotient_polynomial_at_z);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(PairingsBn254.P1().point_mul(aggregated_value));

        PairingsBn254.G1Point memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(proof.opening_at_z_proof.point_mul(state.z));

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(proof.opening_at_z_omega_proof.point_mul(tmp_fr));

        PairingsBn254.G1Point memory pair_with_x = proof.opening_at_z_omega_proof.point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        return PairingsBn254.pairingProd2(pair_with_generator, PairingsBn254.P2(), pair_with_x, vk.g2_x);
    }

    function verify_initial(
        PartialVerifierStateOld memory state,
        ProofOld memory proof,
        VerificationKeyOld memory vk
    ) internal view returns (bool) {
        require(proof.input_values.length == vk.num_inputs);
        require(vk.num_inputs >= 1);
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary.new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(proof.grand_product_commitment);
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state.cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain_old(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);
        transcript.update_with_fr(proof.grand_product_at_z_omega);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function verify_old(ProofOld memory proof, VerificationKeyOld memory vk) internal view returns (bool) {
        PartialVerifierStateOld memory state;

        bool valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return false;
        }

        valid = verify_commitments(state, proof, vk);

        return valid;
    }
}

contract VerifierWithDeserializeOld is Plonk4VerifierWithAccessToDNextOld {
    uint256 constant SERIALIZED_PROOF_LENGTH_OLD = 33;

    function deserialize_proof_old(uint256[] memory public_inputs, uint256[] memory serialized_proof)
    internal
    pure
    returns (ProofOld memory proof)
    {
        require(serialized_proof.length == SERIALIZED_PROOF_LENGTH_OLD);
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);

            j += 2;
        }

        proof.grand_product_commitment = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH_OLD; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.grand_product_at_z_omega = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(serialized_proof[j]);

        j += 1;

        for (uint256 i = 0; i < proof.permutation_polynomials_at_z.length; i++) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(serialized_proof[j]);

            j += 1;
        }

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./KeysWithPlonkVerifier.sol";

// Hardcoded constants to avoid accessing store
contract Verifier is KeysWithPlonkVerifier, KeysWithPlonkVerifierOld {
    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    // solhint-disable-next-line no-empty-blocks
    function initialize(bytes calldata) external {}

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    // solhint-disable-next-line no-empty-blocks
    function upgrade(bytes calldata upgradeParameters) external {}

    function verifyAggregatedBlockProof(uint256[] memory _recursiveInput, uint256[] memory _proof, uint8[] memory _vkIndexes, uint256[] memory _individualVksInputs, uint256[16] memory _subProofsLimbs) external virtual view returns (bool) {
        for (uint256 i = 0; i < _individualVksInputs.length; ++i) {
            _individualVksInputs[i] = _individualVksInputs[i] & INPUT_MASK;
        }
        VerificationKey memory vk = getVkAggregated(uint32(_vkIndexes.length));

        return
        verify_serialized_proof_with_recursion(
            _recursiveInput,
            _proof,
            VK_TREE_ROOT,
            VK_MAX_INDEX,
            _vkIndexes,
            _individualVksInputs,
            _subProofsLimbs,
            vk
        );
    }

    function verifyExitProof(bytes32 _rootHash, uint8 _chainId, uint32 _accountId, uint8 _subAccountId, bytes32 _owner, uint16 _tokenId, uint16 _srcTokenId, uint128 _amount, uint256[] calldata _proof) external virtual view returns (bool) {
        bytes32 commitment = sha256(abi.encodePacked(_rootHash, _chainId, _accountId, _subAccountId, _owner, _tokenId, _srcTokenId, _amount));

        uint256[] memory inputs = new uint256[](1);
        inputs[0] = uint256(commitment) & INPUT_MASK;
        ProofOld memory proof = deserialize_proof_old(inputs, _proof);
        VerificationKeyOld memory vk = getVkExit();
        require(vk.num_inputs == inputs.length, "V0");
        return verify_old(proof, vk);
    }
}