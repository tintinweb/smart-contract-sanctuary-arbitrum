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

import {IOracle} from "./IOracle.sol";
import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";

/**
    @title Oracle Facade
    @notice This contract acts as a single interface for the client to fetch
    price of a given token in terms of eth
*/
contract OracleFacade is Ownable {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Mapping of token to Price Oracle for the token
    mapping(address => IOracle) public oracle;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Contract Constructor
    constructor() Ownable(msg.sender) {}

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event UpdateOracle(address indexed token, address indexed feed);

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function getPrice(address token) external returns (uint) {
        if(address(oracle[token]) == address(0)) revert Errors.PriceUnavailable();
        return oracle[token].getPrice(token);
    }

    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function setOracle(address token, IOracle _oracle) external adminOnly {
        oracle[token] = _oracle;
        emit UpdateOracle(token, address(_oracle));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Errors {
    error AdminOnly();
    error ZeroAddress();
    error PriceUnavailable();
    error IncorrectDecimals();
    error L2SequencerUnavailable();
    error InactivePriceFeed(address feed);
    error StalePrice(address token, address feed);
    error NegativePrice(address token, address feed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";

abstract contract Ownable {
    address public admin;

    event OwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);

    constructor(address _admin) {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        if (newAdmin == address(0)) revert Errors.ZeroAddress();
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}