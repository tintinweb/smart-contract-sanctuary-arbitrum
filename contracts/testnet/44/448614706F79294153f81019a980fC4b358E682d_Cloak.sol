// SPDX-License-Identifier: UNLICENSED
// Author: @stevieraykatz
// https://github.com/coinlander/Coinlander

pragma solidity ^0.8.10;

import "../interfaces/ICloak.sol";

library Cloak {

    /// @notice Generate a random 16-bit pattern based on input params 
    function getDethscales(
        uint16 minDethscales,
        uint16 maxDethscales,
        uint16 seed,
        uint16 salt
    ) public pure returns (uint16) {
        uint16 dethscales;
        uint16 move;
        uint16 range = maxDethscales - minDethscales + 1;
        bool reroll;
        if(seed > 0) {
            reroll = true;
        }
        uint16 rand = reroll
            ? seed // use defined seed if non-zero
            : salt; // generate new pattern if not
        uint16 segBits = _getRandomNumber16(range, salt, rand) + minDethscales;

        for (uint16 i = 0; i < segBits; i++) {
            move = _getRandomNumber16(16, i, rand);
            dethscales = (uint16(2)**move) | dethscales;
        }

        return dethscales;
    }

    /// @notice Generates a 32x32 array of bits
    /// @dev Because solidity doesn't have a native way to handle 4-bit values,
    // we construct an entire row out of each primitive
    //
    // EXAMPLE
    // uint16 _dethscale = 1001 0110 1100 0001
    //
    //  Primitives:
    //   r1'  r2'  r3'  r4'
    //  1001 0110 1100 0001
    //
    //  Full Rows:
    // uint32 r1 = 1001 1001 ,,, 1001
    // uint32 r2 = 0110 0110 ,,, 0110
    // uint32 r3 = 1100 1100 ,,, 1100
    // uint32 r4 = 0001 0001 ,,, 0001

    function getFullCloak(
        uint16 minNoiseBits,
        uint16 maxNoiseBits,
        uint16 _dethscales
    ) public pure returns (uint32[32] memory) {
        uint32[32] memory fullCloak;
        uint32 input = uint32(_dethscales);
        uint32[4] memory rows;

        // r1
        rows[0] =
            (input >> 12) |
            ((input >> 12) << 4) |
            ((input >> 12) << 8) |
            ((input >> 12) << 12) |
            ((input >> 12) << 16) |
            ((input >> 12) << 20) |
            ((input >> 12) << 24) |
            ((input >> 12) << 28);

        // r2
        rows[1] =
            (0xF & (input >> 8)) |
            ((0xF & (input >> 8)) << 4) |
            ((0xF & (input >> 8)) << 8) |
            ((0xF & (input >> 8)) << 12) |
            ((0xF & (input >> 8)) << 16) |
            ((0xF & (input >> 8)) << 20) |
            ((0xF & (input >> 8)) << 24) |
            ((0xF & (input >> 8)) << 28);

        // r3
        rows[2] =
            (0xF & (input >> 4)) |
            ((0xF & (input >> 4)) << 4) |
            ((0xF & (input >> 4)) << 8) |
            ((0xF & (input >> 4)) << 12) |
            ((0xF & (input >> 4)) << 16) |
            ((0xF & (input >> 4)) << 20) |
            ((0xF & (input >> 4)) << 24) |
            ((0xF & (input >> 4)) << 28);

        // r4
        rows[3] =
            (0xF & input) |
            ((0xF & input) << 4) |
            ((0xF & input) << 8) |
            ((0xF & input) << 12) |
            ((0xF & input) << 16) |
            ((0xF & input) << 20) |
            ((0xF & input) << 24) |
            ((0xF & input) << 28);

        // Build full cloak from rows
        for (uint16 i = 0; i < fullCloak.length; i++) {
            fullCloak[i] = rows[i % 4];
        }
        // Deterministically add noise
        uint16 noiseBits = _getRandomNumber16(
            (maxNoiseBits - minNoiseBits + 1),
            _dethscales,
            maxNoiseBits
        ) + minNoiseBits;
        for (uint16 i = 0; i < noiseBits; i++) {
            uint16 noiseCol = _getRandomNumber16(32, _dethscales, i);
            uint16 noiseRow = _getRandomNumber16(32, noiseCol, i);
            fullCloak[noiseRow] = (uint32(2)**noiseCol) ^ fullCloak[noiseRow];
        }
        return fullCloak;
    }

    // Deterministic "random" number picker - used for generating full cloak artwork the same every time
    // while still enabling the injection of randomly assigned noise.
    function _getRandomNumber16(
        uint16 mod,
        uint16 r1,
        uint16 r2
    ) private pure returns (uint16) {
        uint16 seed = uint16(bytes2(keccak256(abi.encodePacked(r1, r2))));
        return seed % mod;
    }

    // Thanks Manny - entropy is a bitch
    function _getRandomNumber(uint256 mod, uint256 r)
        private
        view
        returns (uint256)
    {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    mod,
                    r
                )
            )
        );

        return random % mod;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Author: @stevieraykatz
// https://github.com/coinlander/Coinlander

pragma solidity ^0.8.10;

interface ICloak {
    function getDethscales(
        uint16 minDethscales,
        uint16 maxDethscales,
        uint16 seed,
        uint16 salt
    ) external pure returns (uint16);

    function getFullCloak(
        uint16 minNoiseBits,
        uint16 maxNoiseBits,
        uint16 _dethscales
    ) external pure returns (uint32[32] memory);
}