// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IController} from "../core/IController.sol";
import {ITransformERC20Feature} from "./ITransform.sol";

/**
 * @title 0x V4 Controller
 *     @notice 0x v4 controller for transformERC20
 */
contract TransformController is IController {
    /* -------------------------------------------------------------------------- */
    /*                             CONSTANT VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice transformERC20(address, address, uint256, uint256, (uint32,bytes)[])
    bytes4 constant TRANSFORMERC20 = 0x415565b0;

    /// @notice ETH address
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* -------------------------------------------------------------------------- */
    /*                              EXTERNAL FUNCTIONS                            */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IController
    function canCall(address, bool, bytes calldata data)
        external
        pure
        returns (bool, address[] memory tokensIn, address[] memory tokensOut)
    {
        bytes4 sig = bytes4(data);

        if (sig != TRANSFORMERC20) {
            return (false, new address[](0), new address[](0));
        }

        (address tokenOut, address tokenIn) =
            abi.decode(data[4:], (address, address));

        if (tokenIn == ETH) {
            tokensOut = new address[](1);
            tokensOut[0] = tokenOut;
            return (true, new address[](0), tokensOut);
        }

        if (tokenOut == ETH) {
            tokensIn = new address[](1);
            tokensIn[0] = tokenIn;
            return (true, tokensIn, new address[](0));
        }

        tokensIn = new address[](1);
        tokensOut = new address[](1);

        tokensIn[0] = tokenIn;
        tokensOut[0] = tokenOut;

        return (true, tokensIn, tokensOut);
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

interface ITransformERC20Feature {
    struct Transformation {
        uint32 deploymentNonce;
        bytes data;
    }

    function transformERC20(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    ) external payable returns (uint256 outputTokenAmount);
}