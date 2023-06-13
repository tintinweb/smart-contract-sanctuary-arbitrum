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

interface IVerifier2 {
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[11] memory input
  ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./types/IVerifier.sol";
import "./types/IVerifier2.sol";

contract Verifier02x02 is IVerifier {
    IVerifier2 public immutable verifier2;
    uint16 constant inputAmount = 11;

    constructor(address verifier2Instance) {
        verifier2 = IVerifier2(verifier2Instance);
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
        return verifier2.verifyProof(a, b, c, fixedInput);
    }
}