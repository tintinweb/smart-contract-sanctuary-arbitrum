/**
 *Submitted for verification at Arbiscan on 2023-06-22
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.0;

interface DIA {
    function getValue(string memory key)
        external
        view
        returns (uint128, uint128);
}

contract DIATwoAssetAdapter {
    address public diaOracleAddress;
    address public owner;
    string public assetA;
    string public assetB;

    constructor (
        address _diaOracleAddress,
        string memory _assetA,
        string memory _assetB
    ) {
        diaOracleAddress = _diaOracleAddress;
        assetA = _assetA;
        assetB = _assetB;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function updateDIAOracleAddress(address newDIAOracleAddress) external onlyOwner {
        diaOracleAddress = newDIAOracleAddress;
    }

    function updateAssetA(string memory newQuery) external onlyOwner {
        assetA = newQuery;
    }

    function updateAssetB(string memory newQuery) external onlyOwner {
        assetA = newQuery;
    }

    // retrieves A price in B with 8 decimals and both timestamps of last update
    function getAPriceInB() public view returns (uint256, uint256, uint256) {
        (uint256 priceinusdA, uint256 timestampA) = getPriceInUsd(assetA);
        (uint256 priceinusdB, uint256 timestampB) = getPriceInUsd(assetB);
        return ((priceinusdA * 1e8) / priceinusdB, timestampA, timestampB);
    }

    // retrieves price in USD with 8 decimals
    function getPriceInUsd(string memory query) public view returns (uint256, uint256) {
        (uint256 priceinusd, uint256 timestamp) = DIA(diaOracleAddress).getValue(query);
        return (priceinusd, timestamp);
    }
}