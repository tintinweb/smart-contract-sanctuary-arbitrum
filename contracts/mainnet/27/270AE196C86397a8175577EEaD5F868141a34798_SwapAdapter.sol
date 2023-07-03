// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotPair {
    function stableSwap() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ICamelotRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosFactory {
    function getFee(bool isStable) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosPair {
    function isStable() external view returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        );

    function getAmountOut(uint256 amountIn, address tokenIn)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IChronosRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Pair {
    function tokenX() external view returns (address);

    function tokenY() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ITraderJoeV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getSwapIn(
        address lbPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        address lbPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";

library CamelotLibrary {
    function swapExactTokensForTokens(
        ICamelotRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        amountOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
    }

    function swapTokensForExactTokens(
        ICamelotRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        uint256 tokenOutBalanceBefore = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountInMax,
            amountOut,
            path,
            address(this),
            address(0),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        uint256 tokenOutBalanceAfter = IERC20Upgradeable(path[path.length - 1])
            .balanceOf(address(this));

        uint256 amountOutReceived = tokenOutBalanceAfter -
            tokenOutBalanceBefore;

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        ICamelotRouter,
        ICamelotPair pair,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.stableSwap();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0FeePercent,
            uint16 token1FeePercent
        ) = pair.getReserves();

        address token1 = pair.token1();

        (uint112 reserveIn, uint112 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint16 feePercent = (tokenOut == token1)
            ? token0FeePercent
            : token1FeePercent;

        amountIn =
            (reserveIn * amountOut * 100000) /
            (reserveOut - amountOut) /
            (100000 - feePercent) +
            1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";

library ChronosLibrary {
    function swapExactTokensForTokens(
        IChronosRouter router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IChronosRouter router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        // Note: In current algorithm, `swapTokensForExactTokens` is called
        // only when `amountInMax` equals to actual amount in. Under this assumption,
        // `swapExactTokensForTokens` is used instead of `swapTokensForExactTokens`
        // because Solidly forks doesn't support `swapTokensForExactTokens`.
        IChronosRouter.Route[] memory routes = new IChronosRouter.Route[](1);
        routes[0] = IChronosRouter.Route(path[0], path[path.length - 1], false);

        uint256 amountOutReceived = router.swapExactTokensForTokens(
            amountInMax,
            amountOut,
            routes,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];

        if (amountOutReceived < amountOut) {
            revert Errors.Index_WrongSwapAmount();
        }

        amountIn = amountInMax;
    }

    function getAmountOut(
        IChronosRouter,
        IChronosPair pair,
        uint256 amountIn,
        address tokenIn
    ) internal view returns (uint256 amountOut) {
        amountOut = pair.getAmountOut(amountIn, tokenIn);
    }

    function getAmountIn(
        IChronosRouter,
        IChronosPair pair,
        IChronosFactory factory,
        uint256 amountOut,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        bool isStable = pair.isStable();

        if (isStable) {
            revert Errors.Index_SolidlyStableSwapNotSupported();
        }

        uint256 fee = factory.getFee(isStable);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        address token1 = pair.token1();

        (uint256 reserveIn, uint256 reserveOut) = (tokenOut == token1)
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        amountIn =
            (reserveIn * amountOut * 10000) /
            (reserveOut - amountOut) /
            (10000 - fee) +
            1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // IndexStrategyUpgradeable errors.
    error Index_ComponentAlreadyExists(address component);
    error Index_ComponentHasNonZeroWeight(address component);
    error Index_NotWhitelistedToken(address token);
    error Index_ExceedEquityValuationLimit();
    error Index_AboveMaxAmount();
    error Index_BelowMinAmount();
    error Index_ZeroAddress();
    error Index_SolidlyStableSwapNotSupported();
    error Index_WrongSwapAmount();
    error Index_WrongPair(address tokenIn, address tokenOut);
    error Index_WrongTargetWeightsLength();
    error Index_WrongTargetWeights();

    // SwapAdapter errors.
    error SwapAdapter_WrongDEX(uint8 dex);
    error SwapAdapter_WrongPair(address tokenIn, address tokenOut);

    // IndexOracle errors.
    error Oracle_TokenNotSupported(address token);
    error Oracle_ZeroAddress();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ICamelotPair } from "../dependencies/ICamelotPair.sol";
import { ICamelotRouter } from "../dependencies/ICamelotRouter.sol";
import { IChronosFactory } from "../dependencies/IChronosFactory.sol";
import { IChronosPair } from "../dependencies/IChronosPair.sol";
import { IChronosRouter } from "../dependencies/IChronosRouter.sol";
import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";
import { CamelotLibrary } from "./CamelotLibrary.sol";
import { ChronosLibrary } from "./ChronosLibrary.sol";
import { TraderJoeV2Library } from "./TraderJoeV2Library.sol";
import { UniswapV2Library } from "./UniswapV2Library.sol";

import { Errors } from "./Errors.sol";

library SwapAdapter {
    using CamelotLibrary for ICamelotRouter;
    using ChronosLibrary for IChronosRouter;
    using UniswapV2Library for IUniswapV2Router;
    using TraderJoeV2Library for ITraderJoeV2Router;

    enum DEX {
        None,
        UniswapV2,
        TraderJoeV2,
        Camelot,
        Chronos
    }

    struct PairData {
        address pair;
        bytes data; // Pair specific data such as bin step of TraderJoeV2, pool fee of Uniswap V3, etc.
    }

    struct Setup {
        DEX dex;
        address router;
        PairData pairData;
    }

    function swapExactTokensForTokens(
        Setup memory setup,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) external returns (uint256 amountOut) {
        if (path[0] == path[path.length - 1]) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function swapTokensForExactTokens(
        Setup memory setup,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) external returns (uint256 amountIn) {
        if (path[0] == path[path.length - 1]) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            uint256[] memory binSteps = new uint256[](1);
            binSteps[0] = abi.decode(setup.pairData.data, (uint256));

            return
                ITraderJoeV2Router(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    binSteps,
                    path
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).swapTokensForExactTokens(
                    amountOut,
                    amountInMax,
                    path
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountOut(
        Setup memory setup,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            return amountIn;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountOut(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountOut(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountIn,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountOut(
                    ICamelotPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        if (setup.dex == DEX.Chronos) {
            return
                IChronosRouter(setup.router).getAmountOut(
                    IChronosPair(setup.pairData.pair),
                    amountIn,
                    tokenIn
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }

    function getAmountIn(
        Setup memory setup,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn) {
        if (tokenIn == tokenOut) {
            return amountOut;
        }

        if (setup.dex == DEX.UniswapV2) {
            return
                IUniswapV2Router(setup.router).getAmountIn(
                    IUniswapV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.TraderJoeV2) {
            return
                ITraderJoeV2Router(setup.router).getAmountIn(
                    ITraderJoeV2Pair(setup.pairData.pair),
                    amountOut,
                    tokenIn,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Camelot) {
            return
                ICamelotRouter(setup.router).getAmountIn(
                    ICamelotPair(setup.pairData.pair),
                    amountOut,
                    tokenOut
                );
        }

        if (setup.dex == DEX.Chronos) {
            address factory = abi.decode(setup.pairData.data, (address));

            return
                IChronosRouter(setup.router).getAmountIn(
                    IChronosPair(setup.pairData.pair),
                    IChronosFactory(factory),
                    amountOut,
                    tokenOut
                );
        }

        revert Errors.SwapAdapter_WrongDEX(uint8(setup.dex));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { ITraderJoeV2Pair } from "../dependencies/ITraderJoeV2Pair.sol";
import { ITraderJoeV2Router } from "../dependencies/ITraderJoeV2Router.sol";

library TraderJoeV2Library {
    function swapExactTokensForTokens(
        ITraderJoeV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    function swapTokensForExactTokens(
        ITraderJoeV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory binSteps,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            binSteps,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountIn,
        address,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (amountOut, ) = router.getSwapOut(
            address(pair),
            amountIn,
            tokenOut == address(pair.tokenY())
        );
    }

    function getAmountIn(
        ITraderJoeV2Router router,
        ITraderJoeV2Pair pair,
        uint256 amountOut,
        address,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (amountIn, ) = router.getSwapIn(
            address(pair),
            amountOut,
            tokenOut == address(pair.tokenY())
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { Errors } from "./Errors.sol";
import { IUniswapV2Pair } from "../dependencies/IUniswapV2Pair.sol";
import { IUniswapV2Router } from "../dependencies/IUniswapV2Router.sol";

library UniswapV2Library {
    function swapExactTokensForTokens(
        IUniswapV2Router router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) internal returns (uint256 amountOut) {
        IERC20Upgradeable(path[0]).approve(address(router), amountIn);

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[path.length - 1];
    }

    function swapTokensForExactTokens(
        IUniswapV2Router router,
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path
    ) internal returns (uint256 amountIn) {
        IERC20Upgradeable(path[0]).approve(address(router), amountInMax);

        amountIn = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        )[0];
    }

    function getAmountOut(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountOut = router.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        IUniswapV2Router router,
        IUniswapV2Pair pair,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) = _getReserveInAndOut(
            pair,
            tokenIn,
            tokenOut
        );

        amountIn = router.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function _getReserveInAndOut(
        IUniswapV2Pair pair,
        address tokenIn,
        address tokenOut
    ) private view returns (uint256 reserveIn, uint256 reserveOut) {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        (address token0, address token1) = (pair.token0(), pair.token1());

        if (tokenIn == token0 && tokenOut == token1) {
            (reserveIn, reserveOut) = (reserve0, reserve1);
        } else if (tokenIn == token1 && tokenOut == token0) {
            (reserveIn, reserveOut) = (reserve1, reserve0);
        } else {
            revert Errors.SwapAdapter_WrongPair(tokenIn, tokenOut);
        }
    }
}