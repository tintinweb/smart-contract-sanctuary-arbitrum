// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "./IIdeaTokenNameVerifier.sol";

/**
 * @title URLNameVerifier
 * @author Kelton Madden
 *
 * Verifies a string to be a a valid https:// url
 */
contract URLNameVerifier is IIdeaTokenNameVerifier {
    /**
     * Verifies whether a string matches the required format
     *
     * @param name The input string (domain name)
     *
     * @return Bool; True=matches, False=does not match
     */
    function verifyTokenName(string calldata name) external pure override returns (bool) {
        bytes memory b = bytes(name);
        bool hasHTTPS = false;
        if (b.length <= 7) {
            return false;
        }
        
        if (b[0] == 0x68 && b[1] == 0x74 && b[2] == 0x74 && b[3] == 0x70 && b[4] == 0x73 && b[5] == 0x3a && b[6] == 0x2f && b[7] == 0x2f) {
            hasHTTPS = true;
        } 

        //uint i = 7;
        /*
        if (b[0] == 0x68 && b[1] == 0x74 && b[2] == 0x74 && b[3] == 0x70 && b[4] == 0x3a && b[5] == 0x2f && b[6] == 0x2f) {
            hasHTTP = true;
        }
        else if (b[0] == 0x69 && b[1] == 0x70 && b[2] == 0x66 && b[3] == 0x73 && b[4] == 0x3a && b[5] == 0x2f && b[6] == 0x2f) {
            hasIPFS = true;
        }
        */
        if (!hasHTTPS) {
            return false;
        }
        bool hasDot = false;
        bool hasTLD = false;
        bool hasDomain = false;
        bytes1 lastChar = 0x00;

        for (uint i = 8; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x61 && char <= 0x7a) && //a-z
                !(char == 0x2d) && //-
                !(char == 0x2e) && //.
                !(char == 0x2f) && // /
                !(char == 0x5f)) {//_
                    return false;
                }

            if (char == 0x2E) { // .
                if (lastChar == 0x2e) {
                    return false;
                }
                hasDot = true;
            } else {
                if(hasDot) {
                    hasTLD = true;
                } else {
                    hasDomain = true;
                }
            }

            if (char == 0x2f) {
                if (i == 8) {
                    return false;
                }
                for (uint j = i; j < b.length - 1; j++) {
                    if ((b[j] ==  0x2f && b[j + 1] == 0x2f) || 
                        (b[j] == 0x2e && b[j + 1] == 0x2e)) {
                        return false;
                    }
                }
                break;
            }
            lastChar = char;
        }

        return hasDomain && hasDot && hasTLD;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

/**
 * @title IIdeaTokenNameVerifier
 * @author Alexander Schlindwein
 *
 * Interface for token name verifiers
 */
interface IIdeaTokenNameVerifier {
    function verifyTokenName(string calldata name) external pure returns (bool);
}