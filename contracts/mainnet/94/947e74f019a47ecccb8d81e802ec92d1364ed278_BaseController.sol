// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";

/**
    @title Base Controller
    @notice Base controller with no interactions
*/
contract BaseController is IController {

    /// @inheritdoc IController
    function canCall(address, bool, bytes calldata)
        external
        pure
        returns (bool, address[] memory, address[] memory)
    {
        return (false, new address[](0), new address[](0));
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