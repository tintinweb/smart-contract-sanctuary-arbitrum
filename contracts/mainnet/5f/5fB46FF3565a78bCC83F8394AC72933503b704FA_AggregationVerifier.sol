// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Groth16 verifier template.
/// @author Remco Bloemen
/// @notice Supports verifying Groth16 proofs. Proofs can be in uncompressed
/// (256 bytes) and compressed (128 bytes) format. A view function is provided
/// to compress proofs.
/// @notice See <https://2π.com/23/bn254-compression> for further explanation.
contract AggregationVerifier {
    /// Some of the provided public input values are larger than the field modulus.
    /// @dev Public input elements are not automatically reduced, as this is can be
    /// a dangerous source of bugs.
    error PublicInputNotInField();

    /// The proof is invalid.
    /// @dev This can mean that provided Groth16 proof points are not on their
    /// curves, that pairing equation fails, or that the proof is not for the
    /// provided public input.
    error ProofInvalid();

    // Addresses of precompiles
    uint256 constant PRECOMPILE_MODEXP = 0x05;
    uint256 constant PRECOMPILE_ADD = 0x06;
    uint256 constant PRECOMPILE_MUL = 0x07;
    uint256 constant PRECOMPILE_VERIFY = 0x08;

    // Base field Fp order P and scalar field Fr order R.
    // For BN254 these are computed as follows:
    //     t = 4965661367192848881
    //     P = 36⋅t⁴ + 36⋅t³ + 24⋅t² + 6⋅t + 1
    //     R = 36⋅t⁴ + 36⋅t³ + 18⋅t² + 6⋅t + 1
    uint256 constant P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 constant R = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    // Extension field Fp2 = Fp[i] / (i² + 1)
    // Note: This is the complex extension field of Fp with i² = -1.
    //       Values in Fp2 are represented as a pair of Fp elements (a₀, a₁) as a₀ + a₁⋅i.
    // Note: The order of Fp2 elements is *opposite* that of the pairing contract, which
    //       expects Fp2 elements in order (a₁, a₀). This is also the order in which
    //       Fp2 elements are encoded in the public interface as this became convention.

    // Constants in Fp
    uint256 constant FRACTION_1_2_FP = 0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea4;
    uint256 constant FRACTION_27_82_FP = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 constant FRACTION_3_82_FP = 0x2fcd3ac2a640a154eb23960892a85a68f031ca0c8344b23a577dcf1052b9e775;

    // Exponents for inversions and square roots mod P
    uint256 constant EXP_INVERSE_FP = 0x30644E72E131A029B85045B68181585D97816A916871CA8D3C208C16D87CFD45; // P - 2
    uint256 constant EXP_SQRT_FP = 0xC19139CB84C680A6E14116DA060561765E05AA45A1C72A34F082305B61F3F52; // (P + 1) / 4;

    // Groth16 alpha point in G1
    uint256 constant ALPHA_X = 12687226338041254036256354793976018101551950541498519737723469310988110076375;
    uint256 constant ALPHA_Y = 10256096744067903796312426895717444912307333887269693700471886675863901884202;

    // Groth16 beta point in G2 in powers of i
    uint256 constant BETA_NEG_X_0 = 14568434424400989500134218686860260673044913626154307815038415359477876138326;
    uint256 constant BETA_NEG_X_1 = 17693675125505927051254156984291616972594985825456963090951676229850221483155;
    uint256 constant BETA_NEG_Y_0 = 383177844654040981020264750209583593321791666251217431567253973719249786217;
    uint256 constant BETA_NEG_Y_1 = 4702609992532524160989377295099704709194662140646545418724680051209738439519;

    // Groth16 gamma point in G2 in powers of i
    uint256 constant GAMMA_NEG_X_0 = 14815051514326228068908385609792966191592029825009679736329726616038382980218;
    uint256 constant GAMMA_NEG_X_1 = 8489924782037803931858936554558907678042032007085687571584766050148524131882;
    uint256 constant GAMMA_NEG_Y_0 = 6391315949514971922112169675129858004679832006305666954533871914124224506469;
    uint256 constant GAMMA_NEG_Y_1 = 9697432153854106105017721526895571905909380451908975271046420491866280067319;

    // Groth16 delta point in G2 in powers of i
    uint256 constant DELTA_NEG_X_0 = 11969087011014935233415460302004973927131871436793824839620612262784709776287;
    uint256 constant DELTA_NEG_X_1 = 17745678986402717031649917444808681783377938238076091849249985349810291047890;
    uint256 constant DELTA_NEG_Y_0 = 14493379635216869400631410091008330854226934252257944886907081303740461442501;
    uint256 constant DELTA_NEG_Y_1 = 10971546432814995027058402624573736138393459536613541815883849635155919667270;

    // VK CommitmentKey pedersen G
    uint256 constant VK_PEDERSEN_G_X_0 = 14057299646988463495206519058519537185638704662797820033598363672599992650089;
    uint256 constant VK_PEDERSEN_G_X_1 = 1804161595266085226246183082044496306049360414285214534924891118605265023103;
    uint256 constant VK_PEDERSEN_G_Y_0 = 11766923715944210670288440569225426103940007632318040679616901977081523796491;
    uint256 constant VK_PEDERSEN_G_Y_1 = 834977644800539851243602822366909668747653955574809155046777611984277771776;

    // VK CommitmentKey pedersen GRootSigmaNeg
    uint256 constant VK_PEDERSEN_G_ROOT_SIGMA_NEG_X_0 =
        2200585081879595640584858710253685932171753361453491594146898213239013911282;
    uint256 constant VK_PEDERSEN_G_ROOT_SIGMA_NEG_X_1 =
        18049108820983202804944453697657571551769488507736702873053007083714948165248;
    uint256 constant VK_PEDERSEN_G_ROOT_SIGMA_NEG_Y_0 =
        133313209624682832535108325381034698477936306159075009510964451507662397140;
    uint256 constant VK_PEDERSEN_G_ROOT_SIGMA_NEG_Y_1 =
        7284716207005576333081510645859571066483492723588236030807110008433085609567;

    // Constant and public input points
    uint256 constant CONSTANT_X = 6007902370513106954063927857306896407269873771373783576471927701052459218140;
    uint256 constant CONSTANT_Y = 9615488245380845401381011374843992919723531171351287827859567387072925056152;
    uint256 constant PUB_0_X = 10697034632820275527487335132055183663961098637923488185566513151087951331578;
    uint256 constant PUB_0_Y = 14276118394759667935635656171580811097043009027735537350675614402636858982615;
    uint256 constant PUB_1_X = 7026431637307244687706934400969067696388921806356794816186026757716175351296;
    uint256 constant PUB_1_Y = 15436622150387751729183576709564380175448586470600525414550154039689560853286;
    uint256 constant PUB_2_X = 18789213879714084532301970527052850153634971040007583328313831819609333025628;
    uint256 constant PUB_2_Y = 12644985434441667947447298284069253818568865377627482526916716224437437683639;
    uint256 constant PUB_3_X = 2352523767545466303288228559467558894402028212416744747545968119601089283141;
    uint256 constant PUB_3_Y = 13695257071455071229016443207102451389133989738511645181261569528680096215705;
    uint256 constant PUB_4_X = 20294954283864109304508611151182683038973874045536261521739495438667174243353;
    uint256 constant PUB_4_Y = 20599106385940094055754850903485462352879182423018525029540748703501947756104;
    uint256 constant PUB_5_X = 1845649746371440289698233659575725525425691003210786644913564503473335851532;
    uint256 constant PUB_5_Y = 12410812710630094231961965483501933756332459400648886332512582920985597061403;
    uint256 constant PUB_6_X = 16196196859808012507702203754447245107636768273531678830180174087039554724360;
    uint256 constant PUB_6_Y = 10381950988710522321182538243355705405734349204185742223036700166915070642227;
    uint256 constant PUB_7_X = 20794308775100483820552941792995687094020363291744746281004205162259496215606;
    uint256 constant PUB_7_Y = 9409923316084098672988588998632362167730859696984939162226776086593377522865;

    uint256 constant MOD_R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// Compute the public input linear combination.
    /// @notice Reverts with PublicInputNotInField if the input is not in the field.
    /// @notice Computes the multi-scalar-multiplication of the public input
    /// elements and the verification key including the constant term.
    /// @param input The public inputs. These are elements of the scalar field Fr.
    /// @return x The X coordinate of the resulting G1 point.
    /// @return y The Y coordinate of the resulting G1 point.
    function publicInputMSM(
        uint256[7] memory input,
        uint256 publicCommit,
        uint256[2] memory commit
    ) internal view returns (uint256 x, uint256 y) {
        // Note: The ECMUL precompile does not reject unreduced values, so we check this.
        // Note: Unrolling this loop does not cost much extra in code-size, the bulk of the
        //       code-size is in the PUB_ constants.
        // ECMUL has input (x, y, scalar) and output (x', y').
        // ECADD has input (x1, y1, x2, y2) and output (x', y').
        // We call them such that ecmul output is already in the second point
        // argument to ECADD so we can have a tight loop.
        bool success = true;
        assembly ("memory-safe") {
            let f := mload(0x40)
            let g := add(f, 0x40)
            let s
            mstore(f, CONSTANT_X)
            mstore(add(f, 0x20), CONSTANT_Y)
            mstore(g, PUB_0_X)
            mstore(add(g, 0x20), PUB_0_Y)
            s := mload(input)
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_1_X)
            mstore(add(g, 0x20), PUB_1_Y)
            s := mload(add(input, 32))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_2_X)
            mstore(add(g, 0x20), PUB_2_Y)
            s := mload(add(input, 64))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_3_X)
            mstore(add(g, 0x20), PUB_3_Y)
            s := mload(add(input, 96))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_4_X)
            mstore(add(g, 0x20), PUB_4_Y)
            s := mload(add(input, 128))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_5_X)
            mstore(add(g, 0x20), PUB_5_Y)
            s := mload(add(input, 160))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_6_X)
            mstore(add(g, 0x20), PUB_6_Y)
            s := mload(add(input, 192))
            mstore(add(g, 0x40), s)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))
            mstore(g, PUB_7_X)
            mstore(add(g, 0x20), PUB_7_Y)

            s := mload(add(input, 224))
            mstore(add(g, 0x40), publicCommit)
            success := and(success, lt(s, R))
            success := and(success, staticcall(gas(), PRECOMPILE_MUL, g, 0x60, g, 0x40))
            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))

            s := mload(commit)
            mstore(g, s) // save commit[0]
            s := mload(add(commit, 32))
            mstore(add(g, 0x20), s) // save commit[1]

            success := and(success, staticcall(gas(), PRECOMPILE_ADD, f, 0x80, f, 0x40))

            x := mload(f)
            y := mload(add(f, 0x20))
        }
        if (!success) {
            // Either Public input not in field, or verification key invalid.
            // We assume the contract is correctly generated, so the verification key is valid.
            revert PublicInputNotInField();
        }
    }

    /// Verify an uncompressed Groth16 proof.
    /// @notice Reverts with InvalidProof if the proof is invalid or
    /// with PublicInputNotInField the public input is not reduced.
    /// @notice There is no return value. If the function does not revert, the
    /// proof was successfully verified.
    /// @param proof the points (A, B, C) in EIP-197 format matching the output
    /// of compressProof.
    /// @param input the public input field elements in the scalar field Fr.
    /// Elements must be reduced.
    function verifyProof(
        uint256[8] memory proof,
        uint256[2] memory commitment,
        uint256[2] memory commitmentPOK,
        uint256[7] memory input
    ) public view returns (bool) {
        uint256 inputFr = uint256(keccak256(abi.encodePacked(commitment[0], commitment[1]))) % MOD_R;
        (uint256 x, uint256 y) = publicInputMSM(input, inputFr, commitment);

        // Note: The precompile expects the F2 coefficients in big-endian order.
        // Note: The pairing precompile rejects unreduced values, so we won't check that here.

        bool success;

        uint256 a0 = proof[0];
        uint256 a1 = proof[1];
        uint256 b00 = proof[2];
        uint256 b01 = proof[3];
        uint256 b10 = proof[4];
        uint256 b11 = proof[5];
        uint256 c0 = proof[6];
        uint256 c1 = proof[7];

        assembly ("memory-safe") {
            let f := mload(0x40) // Free memory pointer.

            // Copy points (A, B, C) to memory. They are already in correct encoding.
            // This is pairing e(A, B) and G1 of e(C, -δ).
            mstore(f, a0)
            mstore(add(f, 0x20), a1)
            mstore(add(f, 0x40), b00)
            mstore(add(f, 0x60), b01)
            mstore(add(f, 0x80), b10)
            mstore(add(f, 0xa0), b11)
            mstore(add(f, 0xc0), c0)
            mstore(add(f, 0xe0), c1)

            // Complete e(C, -δ) and write e(α, -β), e(L_pub, -γ) to memory.
            // OPT: This could be better done using a single codecopy, but
            //      Solidity (unlike standalone Yul) doesn't provide a way to
            //      to do this.
            mstore(add(f, 0x100), DELTA_NEG_X_1)
            mstore(add(f, 0x120), DELTA_NEG_X_0)
            mstore(add(f, 0x140), DELTA_NEG_Y_1)
            mstore(add(f, 0x160), DELTA_NEG_Y_0)
            mstore(add(f, 0x180), ALPHA_X)
            mstore(add(f, 0x1a0), ALPHA_Y)
            mstore(add(f, 0x1c0), BETA_NEG_X_1)
            mstore(add(f, 0x1e0), BETA_NEG_X_0)
            mstore(add(f, 0x200), BETA_NEG_Y_1)
            mstore(add(f, 0x220), BETA_NEG_Y_0)
            mstore(add(f, 0x240), x)
            mstore(add(f, 0x260), y)
            mstore(add(f, 0x280), GAMMA_NEG_X_1)
            mstore(add(f, 0x2a0), GAMMA_NEG_X_0)
            mstore(add(f, 0x2c0), GAMMA_NEG_Y_1)
            mstore(add(f, 0x2e0), GAMMA_NEG_Y_0)

            let c
            c := mload(commitment)
            mstore(add(f, 0x300), c) // save commitment[0]
            c := mload(add(commitment, 32))
            mstore(add(f, 0x320), c) // save commitment[1]

            mstore(add(f, 0x340), VK_PEDERSEN_G_X_1)
            mstore(add(f, 0x360), VK_PEDERSEN_G_X_0)
            mstore(add(f, 0x380), VK_PEDERSEN_G_Y_1)
            mstore(add(f, 0x3a0), VK_PEDERSEN_G_Y_0)

            c := mload(commitmentPOK)
            mstore(add(f, 0x3c0), c) // save knowledgeProof[0]
            c := mload(add(commitmentPOK, 32))
            mstore(add(f, 0x3e0), c) // save knowledgeProof[1]

            mstore(add(f, 0x400), VK_PEDERSEN_G_ROOT_SIGMA_NEG_X_1)
            mstore(add(f, 0x420), VK_PEDERSEN_G_ROOT_SIGMA_NEG_X_0)
            mstore(add(f, 0x440), VK_PEDERSEN_G_ROOT_SIGMA_NEG_Y_1)
            mstore(add(f, 0x460), VK_PEDERSEN_G_ROOT_SIGMA_NEG_Y_0)

            // Check pairing equation.
            success := staticcall(gas(), PRECOMPILE_VERIFY, f, 0x480, f, 0x20)
            // Also check returned value (both are either 1 or 0).
            success := and(success, mload(f))
        }
        if (!success) {
            // Either proof or verification key invalid.
            // We assume the contract is correctly generated, so the verification key is valid.
            revert ProofInvalid();
        }
        return success;
    }

    function verifyRaw(bytes calldata proofData) external view returns (bool) {
        uint256[8] memory proof;
        proof[0] = uint256(bytes32(proofData[:32]));
        proof[1] = uint256(bytes32(proofData[32:64]));
        proof[2] = uint256(bytes32(proofData[64:96]));
        proof[3] = uint256(bytes32(proofData[96:128]));
        proof[4] = uint256(bytes32(proofData[128:160]));
        proof[5] = uint256(bytes32(proofData[160:192]));
        proof[6] = uint256(bytes32(proofData[192:224]));
        proof[7] = uint256(bytes32(proofData[224:256]));

        uint256[2] memory commitment;
        commitment[0] = uint256(bytes32(proofData[256:288]));
        commitment[1] = uint256(bytes32(proofData[288:320]));

        uint256[2] memory commitmentPOK;
        commitmentPOK[0] = uint256(bytes32(proofData[320:352]));
        commitmentPOK[1] = uint256(bytes32(proofData[352:384]));

        uint256[7] memory input;
        input[0] = uint256(bytes32(proofData[384:416]));
        input[1] = uint256(uint128(bytes16(proofData[416:432])));
        input[2] = uint256(uint128(bytes16(proofData[432:448])));
        input[3] = uint256(bytes32(proofData[448:480]));
        input[4] = uint256(uint128(bytes16(proofData[480:496])));
        input[5] = uint256(uint128(bytes16(proofData[496:512])));
        input[6] = uint256(bytes32(proofData[512:544]));

        return verifyProof(proof, commitment, commitmentPOK, input);
    }
}