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

contract RdpxCallPriceOracle is IPriceOracle {
    /// @dev RDPX Price Oracle
    ICustomPriceOracle public constant RDPX_PRICE_ORACLE =
        ICustomPriceOracle(0xa70bF62578AaDb37032c73f01873bCC7Dcef1B9c);

    /// @notice Returns the collateral price
    function getCollateralPrice() external view returns (uint256) {
        return getUnderlyingPrice();
    }

    /// @notice Returns the underlying price
    function getUnderlyingPrice() public view returns (uint256) {
        return RDPX_PRICE_ORACLE.getPriceInUSD();
    }
}