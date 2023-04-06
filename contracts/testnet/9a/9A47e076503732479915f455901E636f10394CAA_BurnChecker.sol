// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { INFT } from "./interfaces/INFT.sol";

contract BurnChecker {

    INFT public alpha = INFT(0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60);
    INFT public genesis = INFT(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5);
    INFT public rats = INFT(0x0b21144dbf11feb286d24cD42A7c3B0f90c32aC8);
    INFT public council = INFT(0x34b0D1C36512A22b53D4D5435D823DB5FAeB14A6);
    address public dead = 0x000000000000000000000000000000000000dEaD;
    
    function migrateToL2(
        uint256[] calldata ownedAlph,
        uint256[] calldata ownedGen,
        uint256[] calldata ownedRats,
        uint256[] calldata ownedCC
    ) external {
        uint256 length;

        length = ownedAlph.length;
        for (uint a = 0; a < length; a++) {
            alpha.safeTransferFrom(msg.sender, dead, ownedAlph[a]);
        }

        length = ownedGen.length;
        for (uint g = 0; g < length; g++) {
            genesis.safeTransferFrom(msg.sender, dead, ownedGen[g]);
        }

        length = ownedRats.length;
        for (uint r = 0; r < length; r++) {
            rats.safeTransferFrom(msg.sender, dead, ownedRats[r]);
        }

        length = ownedCC.length;
        for (uint c = 0; c < length; c++) {
            council.safeTransferFrom(msg.sender, dead, ownedCC[c]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
      
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}