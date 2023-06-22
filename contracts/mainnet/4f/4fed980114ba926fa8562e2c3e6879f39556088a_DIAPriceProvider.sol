/******************************************************* 
NOTE: Development in progress by JG. Reached functional milestone; Live VST data is accessible. 
***/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IDIAPriceFeed} from "../interfaces/IDIAPriceFeed.sol";

contract DIAPriceProvider is IConditionProvider {
    string public constant PAIR_NAME = "BTC/USD";
    IDIAPriceFeed public diaPriceFeed;

    constructor(address _priceFeed) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        diaPriceFeed = IDIAPriceFeed(_priceFeed);
    }

    function _getLatestPrice() private view returns (uint256 price) {
        (price, ) = diaPriceFeed.getValue(PAIR_NAME);
        return price;
    }

    /** @notice Fetch token price from priceFeedAdapter (Using string name)
     * @return int256 Current token price
     */
    function getLatestPrice() public view override returns (int256) {
        return int256(_getLatestPrice());
    }

    /** @notice Fetch price and return condition
     * @dev The strike is hashed as an int256 to enable comparison vs. price for earthquake
        and conditional check vs. strike to ensure vaidity
     * @param _strike Strike price
     * @return condition boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool condition, int256) {
        uint256 price = _getLatestPrice();
        return (_strike > price, int256(price));
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IConditionProvider {
    function getLatestPrice() external view returns (int256);

    function conditionMet(
        uint256 _value
    ) external view returns (bool, int256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDIAPriceFeed {
    function getValue(
        string memory key
    ) external view returns (uint128, uint128);
}