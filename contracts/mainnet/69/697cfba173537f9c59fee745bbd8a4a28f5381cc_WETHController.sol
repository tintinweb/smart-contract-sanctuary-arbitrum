// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IController {

    /**
        @notice General function that evaluates whether the target contract can
        be interacted with using the specified calldata
        @param target Address of external protocol/interaction
        @param useEth Specifies if Eth is being sent to the target
        @param data Calldata of the call made to target
        @return canCall Specifies if the interaction is accepted
        @return tokensIn List of tokens that the account will receive after the
        interactions
        @return tokensOut List of tokens that will be removed from the account
        after the interaction
    */
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";

/**
    @title WETH Controller
    @notice Controller for Interacting with Wrapped Ether contract
    arbi:0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
*/
contract WETHController is IController {

    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice deposit() function signature
    bytes4 constant DEPOSIT = 0xd0e30db0;

    /// @notice withdraw(uint256) function signature
    bytes4 constant WITHDRAW = 0x2e1a7d4d;

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// @notice List of tokens
    /// @dev Will always have one token WETH
    address[] public weth;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract constructor
        @param wEth address of WETH
    */
    constructor(address wEth) {
        weth.push(wEth);
    }

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(
        address,
        bool,
        bytes calldata data
    ) external view returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);
        if(sig == DEPOSIT) return (true, weth, new address[](0));
        if(sig == WITHDRAW) return (true, new address[](0), weth);
        return (false, new address[](0), new address[](0));
    }
}