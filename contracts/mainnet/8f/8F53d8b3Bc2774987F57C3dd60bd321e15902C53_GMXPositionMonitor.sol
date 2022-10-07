/**
 *Submitted for verification at Arbiscan on 2022-10-07
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract GMXPositionMonitor {

    struct Positions {
        uint256 shortSize;
        uint256 shortCollateral;
        uint256 shortRealisedPnl;
        uint256 shortDelta;
        uint256 longSize;
        uint256 longCollateral;
        uint256 longRealisedPnl;
        uint256 longDelta;
    }

    address owner;
    address public defaultReader;
    address public defaultVault;
    address public defaultCollateral;
    address public defaultIndex;


    constructor (address _defaultReader, address _defaultVault, address _defaultCollateral, address _defaultIndex) {
        owner = msg.sender;
        defaultReader = _defaultReader;
        defaultVault = _defaultVault;
        defaultCollateral = _defaultCollateral;
        defaultIndex = _defaultIndex;
    }

    function setDefaultReader(address _defaultReader) external onlyOwner {
        defaultReader = _defaultReader;
    }

    function setDefaultVault(address _defaultVault) external onlyOwner {
        defaultVault = _defaultVault;
    }

    function setDefaultCollateral(address _defaultCollateral) external onlyOwner {
        defaultCollateral = _defaultCollateral;
    }

    function setDefaultIndex(address _defaultIndex) external onlyOwner {
        defaultIndex = _defaultIndex;
    }

    function getPositions(address _queryAddress) external view returns (Positions memory positions) {
        return getPositions(defaultReader, defaultVault, defaultCollateral, defaultIndex, _queryAddress);
    }

    function getPositions(
        address _reader, address _vault, address _collateral, address _index, address _queryAddress
    ) public view returns (Positions memory positions) {
        // all values are in USDC
        // human-readable value: div 10^30
        // raw value: div 10^24

        address[] memory collaterals = new address[](1);
        address[] memory indice = new address[](1);
        bool[] memory isLong = new bool[](1);

        collaterals[0] = _collateral;
        indice[0] = _index;
        isLong[0] = false;

        bytes memory lowLevelCallResult;
        (, lowLevelCallResult) = _reader.staticcall(abi.encodeWithSignature(
            "getPositions(address,address,address[],address[],bool[])",
            _vault, _queryAddress, collaterals, indice, isLong
        ));
        uint256[] memory shortPosition = abi.decode(lowLevelCallResult, (uint256[]));

        isLong[0] = true;
        (, lowLevelCallResult) = _reader.staticcall(abi.encodeWithSignature(
            "getPositions(address,address,address[],address[],bool[])",
            _vault, _queryAddress, collaterals, indice, isLong
        ));
        uint256[] memory longPosition = abi.decode(lowLevelCallResult, (uint256[]));

        positions.shortSize = shortPosition[0];
        positions.shortCollateral = shortPosition[1];
        positions.shortRealisedPnl = shortPosition[5];
        positions.shortDelta = shortPosition[8];
        positions.longSize = longPosition[0];
        positions.longCollateral = longPosition[1];
        positions.longRealisedPnl = longPosition[5];
        positions.longDelta = longPosition[8];
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }
}