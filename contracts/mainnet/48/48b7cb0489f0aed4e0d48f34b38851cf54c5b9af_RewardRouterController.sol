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
 * @title Reward Router Controller for claiming and compounding rewards
 *     @dev arbi:0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1
 */
contract RewardRouterController is IController {
    /* -------------------------------------------------------------------------- */
    /*                              STORAGE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice compound()
    bytes4 constant compound = 0xf69e2046;

    /// @notice claimFees()
    bytes4 constant claimFees = 0xd294f093;

    /// @notice WETH
    address[] WETH;

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(address _WETH) {
        WETH.push(_WETH);
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function canCall(address, bool, bytes calldata data)
        external
        view
        returns (bool, address[] memory, address[] memory)
    {
        bytes4 sig = bytes4(data);

        if (sig == compound) return canCallCompound();
        if (sig == claimFees) return canCallClaimFees();

        return (false, new address[](0), new address[](0));
    }

    /* -------------------------------------------------------------------------- */
    /*                             INTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    function canCallClaimFees() internal view returns (bool, address[] memory, address[] memory) {
        return (true, WETH, new address[](0));
    }

    function canCallCompound() internal pure returns (bool, address[] memory, address[] memory) {
        return (true, new address[](0), new address[](0));
    }
}