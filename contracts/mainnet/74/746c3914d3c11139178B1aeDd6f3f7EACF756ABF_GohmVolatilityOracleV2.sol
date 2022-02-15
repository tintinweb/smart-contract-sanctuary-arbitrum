// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IVolatilityOracle} from '../../interfaces/IVolatilityOracle.sol';

contract GohmVolatilityOracleV2 {
    /*==== PUBLIC VARS ====*/

    IVolatilityOracle public constant oracle =
        IVolatilityOracle(0xbf91446115f3E3eaF5079A88E078F876C0d7A6A8);

    /*==== VIEWS ====*/

    /**
     * @notice Gets the volatility of gOHM
     * @return volatility
     */
    function getVolatility(uint256) external view returns (uint256) {
        return oracle.getVolatility();
    }
}