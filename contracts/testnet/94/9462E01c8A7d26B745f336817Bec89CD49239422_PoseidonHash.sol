/**
 *Submitted for verification at Arbiscan on 2022-09-22
*/

library PoseidonT2 {
    function poseidon(uint256[1] memory input) public pure returns (uint256) {}
}

library PoseidonT3 {
    function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

library PoseidonT4 {
    function poseidon(uint256[3] memory input) public pure returns (uint256) {}
}

library PoseidonT5 {
    function poseidon(uint256[4] memory input) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}

contract PoseidonHash {
    function hash1(uint256[1] memory array) public pure returns (uint256) {
        return PoseidonT2.poseidon(array);
    }

    function hash2(uint256[2] memory array) public pure returns (uint256) {
        return PoseidonT3.poseidon(array);
    }

    function hash3(uint256[3] memory array) public pure returns (uint256) {
        return PoseidonT4.poseidon(array);
    }

    function hash4(uint256[4] memory array) public pure returns (uint256) {
        return PoseidonT5.poseidon(array);
    }

    function hash5(uint256[5] memory array) public pure returns (uint256) {
        return PoseidonT6.poseidon(array);
    }
}