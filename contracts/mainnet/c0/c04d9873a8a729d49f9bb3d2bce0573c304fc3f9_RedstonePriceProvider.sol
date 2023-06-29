// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVaultFactoryV2} from "../interfaces/IVaultFactoryV2.sol";
import {IConditionProvider} from "../interfaces/IConditionProvider.sol";
import {IPriceFeedAdapter} from "../interfaces/IPriceFeedAdapter.sol";

contract RedstonePriceProvider is IConditionProvider {
    uint256 public immutable timeOut;
    IVaultFactoryV2 public immutable vaultFactory;
    IPriceFeedAdapter public priceFeedAdapter;
    bytes32 public immutable dataFeedId;
    uint256 public immutable decimals;
    string public description;

    constructor(
        address _factory,
        address _priceFeed,
        string memory _dataFeedSymbol,
        uint256 _timeOut
    ) {
        if (_factory == address(0)) revert ZeroAddress();
        if (_priceFeed == address(0)) revert ZeroAddress();
        if (keccak256(bytes(_dataFeedSymbol)) == keccak256(bytes(string(""))))
            revert InvalidInput();
        if (_timeOut == 0) revert InvalidInput();
        vaultFactory = IVaultFactoryV2(_factory);
        priceFeedAdapter = IPriceFeedAdapter(_priceFeed);
        description = _dataFeedSymbol;
        dataFeedId = stringToBytes32(_dataFeedSymbol);
        timeOut = _timeOut;
        decimals = priceFeedAdapter.decimals();
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (
            roundId,
            price,
            startedAt,
            updatedAt,
            answeredInRound
        ) = priceFeedAdapter.latestRoundData();
    }

    /** @notice Fetch token price from priceFeedAdapter (Redston oracle address)
     * @return int256 Current token price
     */
    function getLatestPrice() public view virtual returns (int256) {
        (
            uint80 roundId,
            int256 price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = latestRoundData();
        if (price <= 0) revert OraclePriceZero();
        if (answeredInRound < roundId) revert RoundIdOutdated();
        if ((block.timestamp - updatedAt) > timeOut) revert PriceTimedOut();

        if (decimals < 18) {
            uint256 calcDecimals = 10 ** (18 - (decimals));
            price = price * int256(calcDecimals);
        } else if (decimals > 18) {
            uint256 calcDecimals = 10 ** ((decimals - 18));
            price = price / int256(calcDecimals);
        }

        return price;
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
        return (int256(_strike) > price, price);
    }

    /** @notice Convert string to bytes32
     * @param _symbol Symbol for token
     * @return result Bytes32 representation of string
     */
    function stringToBytes32(
        string memory _symbol
    ) public pure returns (bytes32 result) {
        if (bytes(_symbol).length > 32) revert InvalidInput();
        assembly {
            result := mload(add(_symbol, 32))
        }
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

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPriceFeedAdapter {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint256);
}