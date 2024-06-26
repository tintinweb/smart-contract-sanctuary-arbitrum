//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "src/interfaces/IRamsesRouter.sol";
import "src/interfaces/IDexWrapper.sol";

/**
 * @title RamsesWrapper
 * @dev A smart-contract that implements Ramses functions.
 */
contract RamsesWrapper is IDexWrapper {
    /**
     * @notice Swaps tokens using Ramses.
     * @param router An address of a router.
     * @param amountIn An amount of a token to swap.
     * @param amountOutMin A min amount of a token to receive.
     * @param routes An array of routes.
     * @return amounts An array of amounts of a tokens to receive.
     */
    function swapAny(address router, uint256 amountIn, uint256 amountOutMin, route[] calldata routes)
        external
        payable
        returns (uint256[] memory amounts)
    {
        return IRamsesRouter(router).swapExactTokensForTokens(
            amountIn, amountOutMin, routes, msg.sender, block.timestamp + 1000
        );
    }

    /**
     * @notice Gets an amount of a token to receive for spe
     *  cified amount of a token to swap.
     * @param amountIn An amount of a token to swap.
     * @param routes An array of routes.
     * @return amounts An array of amounts of a tokens to receive.
     */
    function getAmountsOut(address router, uint256 amountIn, route[] calldata routes)
        public
        view
        returns (uint256[] memory amounts)
    {
        return IRamsesRouter(router).getAmountsOut(amountIn, routes);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { IDexWrapper } from "./IDexWrapper.sol";

interface IRamsesRouter {
    function getAmountsOut(uint256 amountIn, IDexWrapper.route[] memory routes)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IDexWrapper.route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IDexWrapper {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function swapAny(address router, uint256 amountIn, uint256 amountOutMin, route[] calldata routes)
        external
        payable
        returns (uint256[] memory amounts);

    function getAmountsOut(address router, uint256 amountIn, route[] calldata routes)
        external
        view
        returns (uint256[] memory amounts);
}