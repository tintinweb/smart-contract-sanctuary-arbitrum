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
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
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
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
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
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract ExtensionVerifier10 {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [20398690200787941044872588482318950580334790320964482000591954527336383754922,
             2243016503323515226549028999351438810938097002970337236035333986173816957567],
            [12148683767844316243284889260818420800050480514583452738400924779238433982815,
             13224183947039775061180594515029707317801871893425245806358872162436656181739]
        );
        vk.IC = new Pairing.G1Point[](23);

        vk.IC[0] = Pairing.G1Point(
            5944086266486999470962641951109334738305383501477452680202137221419532336032,
            2284193396405192641008929151568016205532088523468504888088084032224516351390
        );

        vk.IC[1] = Pairing.G1Point(
            8353675218313145149480270425597685452969751708281836156491170448442624244659,
            14739165711002216945116759558004114905312299839001674385525616690089678008109
        );

        vk.IC[2] = Pairing.G1Point(
            16805797459290542754452819269561250755642593070071680003094895845956950954132,
            1375883533706041875062561530329056095533095131181409308370383839289573540598
        );

        vk.IC[3] = Pairing.G1Point(
            18228301006054048107194240143194607895745733032672517812855847816913225087268,
            9026294893096416971569790769846215907025613536195147925382206196932781384381
        );

        vk.IC[4] = Pairing.G1Point(
            18465660432507129374057700798529957517277183468044770505014800474639052046384,
            16155157381384234190154718174577912104043782631528482817055071821246688572554
        );

        vk.IC[5] = Pairing.G1Point(
            15864727764985695291227545391585051283635054120092725475563861286037213133758,
            12744999233839951767888154734117078133608577315049839120793586271048511917063
        );

        vk.IC[6] = Pairing.G1Point(
            6112588027108983887202434612287893350430998893600616784131320427568165821121,
            16448773223188335595758024934722129138992303449021649574512267110795822196979
        );

        vk.IC[7] = Pairing.G1Point(
            1488982508955121410544327336462867817321240772838699512268550641548137510667,
            16411169622208116895928199498152125719348834500841255507914628764509315483200
        );

        vk.IC[8] = Pairing.G1Point(
            4678648327078249136094326145105717094493665766230579138140368966472551014490,
            19422991260327766607480167760238403487070967892332569053055223028595851666671
        );

        vk.IC[9] = Pairing.G1Point(
            17308261795744409832115235015164544542848346772033804203640126380836358490202,
            4665527060894275197341227957239031069388477503208894325031974967244333597867
        );

        vk.IC[10] = Pairing.G1Point(
            6239780937864850548355794412314844262473970736502394767863857600725901172675,
            21166565242937672727240350444167383609740334402103153923504559835349105913280
        );

        vk.IC[11] = Pairing.G1Point(
            19119083096170597455127879520901784388370105793246215858874900788059791914184,
            3896413871302783503166402929311610954079211391946273476555997971407006210804
        );

        vk.IC[12] = Pairing.G1Point(
            610393895428355018199747422299953797428259340408148413052013724256286536953,
            12381533330109219029915190464378423006552485190561517811318509907091551357754
        );

        vk.IC[13] = Pairing.G1Point(
            7059141033236091219239202195710095164600094495747954369824300715165632850521,
            10787910119486668522010131285000853047864998241523690406062854362651869863704
        );

        vk.IC[14] = Pairing.G1Point(
            6892582378256982502722209970079986953978404571077584224409908744694432916034,
            15886117717774415360812050204533675872101217110482708813452916884381097352961
        );

        vk.IC[15] = Pairing.G1Point(
            6621143374001024149784232319466973868283894222179825976788385729031111119652,
            7392956539913629765233299210981319197295468014458949491239174659619529254695
        );

        vk.IC[16] = Pairing.G1Point(
            7516174936556181232567445602608970427836512761678275180366985211100850497781,
            5029654369342207910013174220370746059436220177925371001411077643406638323615
        );

        vk.IC[17] = Pairing.G1Point(
            17411235574068252088544708763859819776695125270725973477218246383924512183772,
            21425161106610301670386833642925323611487593480787199783953747943639605901149
        );

        vk.IC[18] = Pairing.G1Point(
            8605774506321027068687694075356720945429658819898526160403446449327229539159,
            20182242140580276051876321375373699426220893384940616839988437772078447499534
        );

        vk.IC[19] = Pairing.G1Point(
            3861491314242102294654077016543754112110944584035652463330769224377662430301,
            20942089950737856231991328468015992265608428426022792907807628640807588269945
        );

        vk.IC[20] = Pairing.G1Point(
            4831221241338878650053276016274533464085501023438114653099348848232033536334,
            20289942206855230639178108254013945376790798658021095864197495429032791449541
        );

        vk.IC[21] = Pairing.G1Point(
            4854617341299675149015854554125280040408300139566721851681413326710495854858,
            11547787817230452440625040924050514542151391982430700386146764901518829077959
        );

        vk.IC[22] = Pairing.G1Point(
            15478033334907787013018882591308304320168493123652676273758212452630036410897,
            2796978426684752290854293342596188552582541769883864393191001346376358744802
        );

    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[22] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}