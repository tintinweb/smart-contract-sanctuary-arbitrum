// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVolatilityOracle {
    function getVolatility() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Interfaces
import {IVolatilityOracle} from '../../interfaces/IVolatilityOracle.sol';

contract RdpxVolatilityOracleV2 {
    /*==== PUBLIC VARS ====*/

    IVolatilityOracle public constant oracle =
        IVolatilityOracle(0x3E0215c1D639280e13B46e3aF94Fb5630d1b3212);

    /*==== VIEWS ====*/

    /**
     * @notice Gets the volatility of rdpx
     * @return volatility
     */
    function getVolatility(uint256) external view returns (uint256) {
        return oracle.getVolatility();
    }
}