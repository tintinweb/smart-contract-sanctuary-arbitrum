// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IVolatilityOracle} from '../../interfaces/IVolatilityOracle.sol';

contract GmxVolatilityOracleV2 {
    /*==== PUBLIC VARS ====*/

    IVolatilityOracle public constant oracle =
        IVolatilityOracle(0x83A5b587Ae36F342d405A7e5971941168E0adB5d);

    /*==== VIEWS ====*/

    /**
     * @notice Gets the volatility of GMX
     * @return volatility
     */
    function getVolatility(uint256) external view returns (uint256) {
        return oracle.getVolatility();
    }
}