// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOracle} from "../core/IOracle.sol";

interface IGauge {
    function lp_token() external view returns (address);
}

interface IRewardPool {
    function curveGauge() external view returns (address);
}

/**
    @title Convex reward pool oracle
    @notice Price Oracle for convex reward pool
*/
contract ConvexRewardPoolOracle is IOracle {

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
    function getPrice(address token) external view returns (uint) {
        return oracleFacade.getPrice(
            IGauge(IRewardPool(token).curveGauge()
        ).lp_token());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {

    /**
        @notice Fetches price of a given token in terms of ETH
        @param token Address of token
        @return price Price of token in terms of ETH
    */
    function getPrice(address token) external view returns (uint);
}