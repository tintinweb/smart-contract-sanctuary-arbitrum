// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ISmartTrendStrategy {
    function getMakerPayoff(uint256[2] memory anchorPrices, uint256 settlePrice, uint256 maxPayoff) external pure returns (uint256);
    function getMinterPayoff(uint256[2] memory anchorPrices, uint256 settlePrice, uint256 maxPayoff) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../interfaces/ISmartTrendStrategy.sol";


contract SmartBull is ISmartTrendStrategy {
    function getMakerPayoff(uint256[2] memory anchorPrices, uint256 settlePrice, uint256 maxPayoff) public pure returns (uint256 payoff) {
        if (settlePrice >= anchorPrices[1])
            payoff = 0;
        else if (settlePrice <= anchorPrices[0])
            payoff = maxPayoff;
        else
            payoff = maxPayoff * (anchorPrices[1] - settlePrice) / (anchorPrices[1] - anchorPrices[0]);
    }

    function getMinterPayoff(uint256[2] memory anchorPrices, uint256 settlePrice, uint256 maxPayoff) external pure returns (uint256) {
        return maxPayoff - getMakerPayoff(anchorPrices, settlePrice, maxPayoff);
    }
}