//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceOracle {
    function getCollateralPrice() external view returns (uint256);

    function getUnderlyingPrice() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IPriceOracle} from "../../interfaces/IPriceOracle.sol";

interface ICustomPriceOracle {
    function getPriceInUSD() external view returns (uint256);
}

contract DpxCallPriceOracle is IPriceOracle {
    /// @dev DPX Price Oracle
    ICustomPriceOracle public constant DPX_PRICE_ORACLE =
        ICustomPriceOracle(0x252C07E0356d3B1a8cE273E39885b094053137b9);

    /// @notice Returns the collateral price
    function getCollateralPrice() external view returns (uint256) {
        return getUnderlyingPrice();
    }

    /// @notice Returns the underlying price
    function getUnderlyingPrice() public view returns (uint256) {
        return DPX_PRICE_ORACLE.getPriceInUSD();
    }
}