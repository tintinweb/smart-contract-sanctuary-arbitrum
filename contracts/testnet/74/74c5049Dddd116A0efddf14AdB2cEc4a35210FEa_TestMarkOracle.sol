/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


interface IPerpetualOracle {
    struct IndexObservation {
        uint256 timestamp;
        uint256 underlyingPrice;
        bytes32 proofHash;
    }
    struct LastPriceObservation {
        uint256 timestamp;
        uint256 lastPrice;
    }
    struct PriceEpochs {
        uint256 price;
        uint256 timestamp;
        uint256 cardinality; // number of elements in current epoch
    }

    event ObservationAdderSet(address indexed matchingEngine);
    event IndexObservationAdded(uint256[] index, uint256[] underlyingPrice, uint256 timestamp);
    event MarkObservationAdded(uint256 indexed index, uint256 lastPrice, uint256 markPrice, uint256 timestamp);

    function __PerpetualOracle_init(
        address[2] calldata _baseToken,
        uint256[2] calldata _markPrices,
        uint256[2] calldata _indexPrices,
        bytes32[2] calldata _proofHashes,
        address _admin
    ) external;

    function setMarkObservationAdder(address _adder) external;

    function setIndexObservationAdder(address _adder) external;

    function grantFundingPeriodRole(address _account) external;

    function grantSmaIntervalRole(address _positioningConfig) external;

    function setFundingPeriod(uint256 _period) external;

    function setMarkSmInterval(uint256 _markSmInterval) external;

    function addMarkObservation(uint256 _index, uint256 _price) external;

    function addIndexObservations(
        uint256[] memory _indexes,
        uint256[] memory _prices,
        bytes32[] memory _proofHashes
    ) external;

    function latestIndexPrice(uint256 _index) external view returns (uint256 latestIndexPrice);

    function latestMarkPrice(uint256 index) external view returns (uint256 latestMarkPrice);

    function latestLastPrice(uint256 _index) external view returns (uint256 latestLastPrice);

    function getIndexEpochSMA(
        uint256 _index,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external view returns (uint256 price);

    function latestIndexSMA(uint256 _smInterval, uint256 _index) external view returns (uint256 answer, uint256 lastUpdateTimestamp);

    function lastestTimestamp(uint256 _index, bool isMark) external view returns (uint256 lastUpdatedTimestamp);

    function lastestLastPriceSMA(uint256 _index, uint256 _smInterval) external view returns (uint256 priceCumulative);

    function getMarkEpochSMA(
        uint256 _index,
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) external view returns (uint256 price);

    function indexByBaseToken(address _baseToken) external view returns (uint256 index);
}


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}

contract TestMarkOracle {
    uint256 public value= 10;

    function getMark() external {
        value = IPerpetualOracle(address(0x0905537ca2Ab05Ae028C523AdE74Ce53EAE5d952)).getMarkEpochSMA(0, 1683293333, 1683293336);
    }
}