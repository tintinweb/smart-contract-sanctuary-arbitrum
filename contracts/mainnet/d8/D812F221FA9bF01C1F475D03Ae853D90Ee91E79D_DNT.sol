// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IDNTStrategy {
    function getMakerPayoff(uint256[2] memory anchorPrices, uint256[2] memory settlePrices, uint256 maxPayoff) external pure returns (uint256);
    function getMinterPayoff(uint256[2] memory anchorPrices, uint256[2] memory settlePrices, uint256 maxPayoff) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../interfaces/IDNTStrategy.sol";


contract DNT is IDNTStrategy {
    function getMakerPayoff(uint256[2] memory anchorPrices, uint256[2] memory settlePrices, uint256 maxPayoff) public pure returns (uint256) {
        if (settlePrices[0] <= anchorPrices[0] || settlePrices[1] >= anchorPrices[1])
            return maxPayoff;
        else
            return 0;
    }

    function getMinterPayoff(uint256[2] memory anchorPrices, uint256[2] memory settlePrices, uint256 maxPayoff) external pure returns (uint256) {
        return maxPayoff - getMakerPayoff(anchorPrices, settlePrices, maxPayoff);
    }
}