// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ITroveStreetPunksMetadata.sol";

contract TroveStreetPunksHiddenMetadata is ITroveStreetPunksMetadata {

    function metadataOf(uint256) external pure override returns (string memory) {
        return "ipfs://Qma57uaWE17Mh6qSDu6gbXM7A9H4oJa68iCpzDHykG87jN";
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITroveStreetPunksMetadata {

    function metadataOf(uint256 tokenId) external view returns (string memory);

}