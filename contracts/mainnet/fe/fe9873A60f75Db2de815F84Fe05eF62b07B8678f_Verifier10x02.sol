// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input,
        uint256 verifierId
    ) view external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVerifier10 {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[19] memory input
  ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./types/IVerifier.sol";
import "./types/IVerifier10.sol";

contract Verifier10x02 is IVerifier {
    IVerifier10 public immutable verifier10;
    uint16 constant inputAmount = 19;

    constructor(address verifier10Instance) {
        verifier10 = IVerifier10(verifier10Instance);
    }

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input,
        uint256
    ) external view returns (bool) {
        uint256[inputAmount] memory fixedInput;
        for (uint16 i = 0; i < input.length; i++) {
            fixedInput[i] = input[i];
        }
        return verifier10.verifyProof(a, b, c, fixedInput);
    }
}