// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {

    /**
        @notice Fetches price of a given token in terms of ETH
        @param token Address of token
        @return price Price of token in terms of ETH
    */
    function getPrice(address token) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOracle} from "../core/IOracle.sol";

interface IGauge {
    function lp_token() external view returns (address);
}

/**
    @title Stable 2 curve gauge oracle
    @notice Price Oracle for 2 curve stable gauge
*/
contract Stable2CurveGaugeOracle is IOracle {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Oracle Facade
    IOracle immutable oracleFacade;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param _oracle Address of oracleFacade
    */
    constructor(IOracle _oracle) {
        oracleFacade = _oracle;
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IOracle
    function getPrice(address token) external returns (uint) {
        return oracleFacade.getPrice(IGauge(token).lp_token());
    }
}