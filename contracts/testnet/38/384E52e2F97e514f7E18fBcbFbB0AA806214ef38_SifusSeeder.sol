// SPDX-License-Identifier: MIT

/// @title Interface for SifusDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISifusSeeder } from './ISifusSeeder.sol';

interface ISifusDescriptor {

    event PartsLocked();

    function arePartsLocked() external returns (bool);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);
    function part1s(uint256 index) external view returns (bytes memory);
    function part2s(uint256 index) external view returns (bytes memory);
    function part3s(uint256 index) external view returns (bytes memory);
    function part4s(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);
    function part1Count() external view returns (uint256);
    function part2Count() external view returns (uint256);
    function part3Count() external view returns (uint256);
    function part4Count() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;
    function addManyBackgrounds(string[] calldata backgrounds) external;
    function addManyPart1s(bytes[] calldata part1s) external;
    function addManyPart2s(bytes[] calldata part2s) external;
    function addManyPart3s(bytes[] calldata part3s) external;
    function addManyPart4s(bytes[] calldata part4s) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;
    function addBackground(string calldata background) external;
    function addPart1(bytes calldata part1) external;
    function addPart2(bytes calldata part2) external;
    function addPart3(bytes calldata part3) external;
    function addPart4(bytes calldata part4) external;

    function lockParts() external;

    function generateSVGImage(ISifusSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for SifusSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISifusDescriptor } from './ISifusDescriptor.sol';

interface ISifusSeeder {
    struct Seed {
        uint48 background;
        uint48 part1;
        uint48 part2;
        uint48 part3;
        uint48 part4;
    }

    function generateSeed(uint256 sifuId, ISifusDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: MIT

/// @title The SifusToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░█████████░░█████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░████████████████████░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ISifusSeeder } from './interfaces/ISifusSeeder.sol';
import { ISifusDescriptor } from './interfaces/ISifusDescriptor.sol';

contract SifusSeeder is ISifusSeeder {
    /**
     * @notice Generate a pseudo-random Sifu seed using the previous blockhash and sifu ID.
     */
    // prettier-ignore
    function generateSeed(uint256 sifuId, ISifusDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), sifuId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 part1Count = descriptor.part1Count();
        uint256 part2Count = descriptor.part2Count();
        uint256 part3Count = descriptor.part3Count();
        uint256 part4Count = descriptor.part4Count();

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            part1: uint48(
                uint48(pseudorandomness >> 48) % part1Count
            ),
            part2: uint48(
                uint48(pseudorandomness >> 96) % part2Count
            ),
            part3: uint48(
                uint48(pseudorandomness >> 144) % part3Count
            ),
            part4: uint48(
                uint48(pseudorandomness >> 192) % part4Count
            )
        });
    }
}