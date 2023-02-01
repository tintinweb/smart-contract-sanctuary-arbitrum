/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

interface Gmx {
    function getPositions(
        address _vault, address _account, address[] memory _collateralTokens, address[] memory _indexTokens, bool[] memory _isLong
    ) external view returns(uint256[] memory);
}

interface ChainlinkOracle {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

contract GmxInfo {
    
    address depolyer;
    address wbtcAddress;
    address wethAddress;
    address usdcAddress;
    address btcOracleAddress;
    address ethOracleAddress;
    address gmxReaderAddress;
    address gmxVaultAddress;

    constructor(
        address _wbtcAddress, address _wethAddress, address _usdcAddress, address _btcOracleAddress, address _ethOracleAddress, address _gmxReaderAddress, address _gmxVaultAddress
    ) {
        depolyer = msg.sender;
        setAddresses(_wbtcAddress, _wethAddress, _usdcAddress, _btcOracleAddress, _ethOracleAddress, _gmxReaderAddress, _gmxVaultAddress);
    }

    function setAddresses(
        address _wbtcAddress, address _wethAddress, address _usdcAddress, address _btcOracleAddress, address _ethOracleAddress, address _gmxReaderAddress, address _gmxVaultAddress
    ) public {
        if (msg.sender != depolyer) {
            revert("only owner");
        }

        wbtcAddress = _wbtcAddress;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;
        btcOracleAddress = _btcOracleAddress;
        ethOracleAddress = _ethOracleAddress;
        gmxReaderAddress = _gmxReaderAddress;
        gmxVaultAddress = _gmxVaultAddress;
    }

    function getPositions(address _teavaultAddress) external view returns (
        uint256 blockNumber,
        uint256 blockTimestamp,
        int256[2] memory prices,
        uint8[2] memory priceDecimals,
        uint256[2] memory priceTimestamps,
        uint256[] memory positions
    ) {
        blockNumber = block.number;
        blockTimestamp = block.timestamp;

        Gmx gmxReader = Gmx(gmxReaderAddress);
        ChainlinkOracle btcOracle = ChainlinkOracle(btcOracleAddress);
        ChainlinkOracle ethOracle = ChainlinkOracle(ethOracleAddress);

        prices[0] = btcOracle.latestAnswer();
        priceDecimals[0] = btcOracle.decimals();
        priceTimestamps[0] = btcOracle.latestTimestamp();

        prices[1] = ethOracle.latestAnswer();
        priceDecimals[1] = ethOracle.decimals();
        priceTimestamps[1] = ethOracle.latestTimestamp();

        address[] memory collateralTokens = new address[](4);
        address[] memory indexTokens = new address[](4);
        bool[] memory isLong = new bool[](4);

        collateralTokens[0] = wbtcAddress;
        collateralTokens[1] = usdcAddress;
        collateralTokens[2] = wethAddress;
        collateralTokens[3] = usdcAddress;

        indexTokens[0] = wbtcAddress;
        indexTokens[1] = wbtcAddress;
        indexTokens[2] = wethAddress;
        indexTokens[3] = wethAddress;

        isLong[0] = true;
        isLong[1] = false;
        isLong[2] = true;
        isLong[3] = false;

        positions = gmxReader.getPositions(
            gmxVaultAddress,
            _teavaultAddress,
            collateralTokens,
            indexTokens,
            isLong
        );
    }
}