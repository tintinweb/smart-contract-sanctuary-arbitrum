// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title   IPriceFeed
 * @author  maneki.finance
 * @notice  Defines the interface for a PriceFeed contract
 */

interface IPriceFeed {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../interfaces/IPriceFeed.sol";

/**
 * @title   ConvertedPriceFeed
 * @author  maneki.finance
 * @notice  Price Feed contract that calculate the price of an asset with given exchange rate
 *          price feed and denominator price feed
 */

contract ConvertedPriceFeed is IPriceFeed {
    /****************************************/
    /* Contract Variables */
    /****************************************/

    string public description_;
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