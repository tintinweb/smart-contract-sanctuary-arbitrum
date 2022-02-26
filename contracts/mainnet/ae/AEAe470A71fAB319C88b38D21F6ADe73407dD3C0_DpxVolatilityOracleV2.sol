// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IVolatilityOracle} from '../../interfaces/IVolatilityOracle.sol';

contract DpxVolatilityOracleV2 {
    /*==== PUBLIC VARS ====*/

    IVolatilityOracle public constant oracle =
        IVolatilityOracle(0xb6645813567bB5beEa8f62e793D075fE6d3Be0B1);

    /*==== VIEWS ====*/

    /**
     * @notice Gets the volatility
     * @return volatility
     */
    function getVolatility(uint256) external view returns (uint256) {
        return oracle.getVolatility();
    }
}