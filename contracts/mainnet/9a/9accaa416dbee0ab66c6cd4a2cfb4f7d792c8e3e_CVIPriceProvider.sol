// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {ICVIPriceFeed} from "../interfaces/ICVIPriceFeed.sol";

contract CVIPriceProvider is IConditionProvider {
    uint256 public immutable timeOut;
    ICVIPriceFeed public priceFeedAdapter;

    constructor(address _priceFeed, uint256 _timeOut) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (_timeOut == 0) revert InvalidInput();
        priceFeedAdapter = ICVIPriceFeed(_priceFeed);
        timeOut = _timeOut;
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        (uint256 price, , uint256 updatedAt) = priceFeedAdapter
            .getCVILatestRoundData();
        if (price == 0) revert OraclePriceZero();

        // TODO: What is a suitable timeframe to set timeout as based on this info? Update at always timestamp?
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        return int256(price);
    }

    // NOTE: _marketId unused but receiving marketId makes Generic controller composabile for future
    /** @notice Fetch price and return condition
     * @param _strike Strike price
     * @return boolean If condition is met i.e. strike > price
     * @return price Current price for token
     */
    function conditionMet(
        uint256 _strike
    ) public view virtual returns (bool, int256 price) {
        price = getLatestPrice();
        return (int256(_strike) < price, price);
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZeroAddress();
    error InvalidInput();
    error OraclePriceZero();
    error RoundIdOutdated();
    error PriceTimedOut();
}

pragma solidity 0.8.17;

interface IVaultFactoryV2 {
    function createNewMarket(
        uint256 fee,
        address token,
        address depeg,
        uint256 beginEpoch,
        uint256 endEpoch,
        address oracle,
        string memory name
    ) external returns (address);

    function treasury() external view returns (address);

    function getVaults(uint256) external view returns (address[2] memory);

    function getEpochFee(uint256) external view returns (uint16);

    function marketToOracle(uint256 _marketId) external view returns (address);

    function transferOwnership(address newOwner) external;

    function changeTimelocker(address newTimelocker) external;

    function marketIdToVaults(uint256 _marketId)
        external
        view
        returns (address[2] memory);
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

interface ICVIPriceFeed {
    function getCVILatestRoundData()
        external
        view
        returns (uint32 cviValue, uint80 cviRoundId, uint256 cviTimestamp);
}