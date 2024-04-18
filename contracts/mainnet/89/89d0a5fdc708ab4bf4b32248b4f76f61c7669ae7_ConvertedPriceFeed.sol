/**
 *Submitted for verification at Arbiscan.io on 2024-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IPriceFeed {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);
}

contract ConvertedPriceFeed is IPriceFeed {
    /****************************************/
    /* Contract Variables */
    /****************************************/

    string public description_;

    /****************************************/
    /* Constructor */
    /****************************************/

    IPriceFeed public exchangeRatePriceFeed;
    IPriceFeed public denominatorPriceFeed;

    /****************************************/
    /* Constructor */
    /****************************************/

    constructor(
        address _exchangeRatePriceFeed,
        address _denominatorPriceFeed,
        string memory _description
    ) {
        exchangeRatePriceFeed = IPriceFeed(_exchangeRatePriceFeed);
        denominatorPriceFeed = IPriceFeed(_denominatorPriceFeed);
        description_ = _description;
    }

    /****************************************/
    /* View Functions */
    /****************************************/

    function description() external view returns (string memory) {
        return description_;
    }

    function decimals() external view returns (uint8) {
        return denominatorPriceFeed.decimals();
    }

    function latestAnswer() external view returns (int256) {
        return
            (denominatorPriceFeed.latestAnswer() *
                exchangeRatePriceFeed.latestAnswer()) /
            int256(10 ** exchangeRatePriceFeed.decimals());
    }

    function latestRound() external view returns (uint256) {
        return exchangeRatePriceFeed.latestRound();
    }

    function latestTimestamp() external view returns (uint256) {
        return exchangeRatePriceFeed.latestTimestamp();
    }
}