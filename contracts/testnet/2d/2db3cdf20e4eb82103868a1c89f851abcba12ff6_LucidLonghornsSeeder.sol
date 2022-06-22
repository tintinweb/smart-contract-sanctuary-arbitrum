// SPDX-License-Identifier: GPL-3.0

/// @title The LucidLonghornsToken pseudo-random seed generator

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { ILucidLonghornsSeeder } from './ILucidLonghornsSeeder.sol';
import { ILucidLonghornsDescriptor } from './ILucidLonghornsDescriptor.sol';

contract LucidLonghornsSeeder is ILucidLonghornsSeeder {
    /**
     * @notice Generate a pseudo-random Lucid Longhorn seed using the previous blockhash and lucid longhorn ID.
     */
    // prettier-ignore
    function generateSeed(uint256 lucidLonghornId, ILucidLonghornsDescriptor descriptor) external view override returns (Seed memory) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), lucidLonghornId))
        );

        uint256 backgroundCount = descriptor.backgroundCount();
        uint256 hideCount = descriptor.hideCount();
        uint256 outfitCount = descriptor.outfitCount();
        uint256 headCount = descriptor.headCount();
        uint256 eyesCount = descriptor.eyesCount();
        uint256 hornsCount = descriptor.hornsCount();
        uint256 snoutCount = descriptor.snoutCount();

        return Seed({
            background: uint48(
                uint48(pseudorandomness) % backgroundCount
            ),
            hide: uint48(
                uint48(pseudorandomness >> 48) % hideCount
            ),
            horns: uint48(
                uint48(pseudorandomness >> 240) % hornsCount
            ),
            outfit: uint48(
                uint48(pseudorandomness >> 96) % outfitCount
            ),
            head: uint48(
                uint48(pseudorandomness >> 144) % headCount
            ),
            eyes: uint48(
                uint48(pseudorandomness >> 192) % eyesCount
            ),
            snout: uint48(
                uint48(pseudorandomness >> 288) % snoutCount
            )
        });
    }
}