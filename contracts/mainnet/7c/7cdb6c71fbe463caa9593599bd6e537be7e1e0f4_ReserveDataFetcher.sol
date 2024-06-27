/**
 *Submitted for verification at Arbiscan.io on 2024-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }
}

interface IPool {
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}

contract ReserveDataFetcher {

    function fetchReserveData(address poolAddress, address[] calldata assetAddresses) 
        external 
        view 
        returns (uint128[] memory liquidityIndexes, uint128[] memory variableBorrowIndexes) 
    {
        IPool pool = IPool(poolAddress);
        uint256 length = assetAddresses.length;
        liquidityIndexes = new uint128[](length);
        variableBorrowIndexes = new uint128[](length);

        for (uint256 i = 0; i < length; i++) {
            DataTypes.ReserveData memory reserveData = pool.getReserveData(assetAddresses[i]);
            liquidityIndexes[i] = reserveData.liquidityIndex;
            variableBorrowIndexes[i] = reserveData.variableBorrowIndex;
        }

        return (liquidityIndexes, variableBorrowIndexes);
    }
}