// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {IController} from "./IController.sol";
import {IControllerFacade} from "./IControllerFacade.sol";

/**
    @title Controller Facade
    @notice This contract acts as a single interface for the client to determine
    if a given interactions is acceptable
*/
contract ControllerFacade is Ownable, IControllerFacade {

    /* -------------------------------------------------------------------------- */
    /*                               STATE VARIABLES                              */
    /* -------------------------------------------------------------------------- */

    /// Mapping that returns if a given token is supported by the protocol
    mapping(address => bool) public isTokenAllowed;

    /// Mapping of external interaction with respective controller
    mapping(address => IController) public controllerFor;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event UpdateController(address indexed target, address indexed controller);

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract Constructor
    */
    constructor() Ownable(msg.sender) {}

    /* -------------------------------------------------------------------------- */
    /*                              PUBLIC FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IControllerFacade
    function canCall(
        address target,
        bool useEth,
        bytes calldata data
    )
        external
        view
        returns (bool isValid, address[] memory tokensIn, address[] memory tokensOut)
    {
        (isValid, tokensIn, tokensOut) = controllerFor[target].canCall(target, useEth, data);
        if (isValid) isValid = validateTokensIn(tokensIn);
    }

    /* -------------------------------------------------------------------------- */
    /*                              INTERNAL FUNCTIONS                            */
    /* -------------------------------------------------------------------------- */

    function validateTokensIn(address[] memory tokensIn)
        internal
        view
        returns (bool)
    {
        for (uint i; i < tokensIn.length; i++)
            if (!isTokenAllowed[tokensIn[i]]) return false;
        return true;
    }


    /* -------------------------------------------------------------------------- */
    /*                               ADMIN FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function updateController(address target, IController controller)
        external
        adminOnly
    {
        controllerFor[target] = controller;
        emit UpdateController(target, address(controller));
    }

    function toggleTokenAllowance(address token) external adminOnly {
        isTokenAllowed[token] = !isTokenAllowed[token];
    }
}

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

import {IController} from "./IController.sol";

interface IControllerFacade {
    function isTokenAllowed(address token) external view returns (bool);
    function controllerFor(address target) external view returns (IController);

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

interface Errors {
    error AdminOnly();
    error ZeroAddress();
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