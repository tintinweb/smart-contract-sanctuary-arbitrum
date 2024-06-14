// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./IPool.sol";

contract UniV3Buyer {
    address constant UNIV3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    ISwapRouter internal router;

    constructor() {
        router = ISwapRouter(UNIV3_ROUTER);
    }

    function approveForRouter(address token, uint256 amount) public {
        IERC20 tokenErc = IERC20(token);
        tokenErc.approve(UNIV3_ROUTER, amount);
    }

    function resetAllowance(address token) public {
        IERC20 tokenErc = IERC20(token);
        tokenErc.approve(UNIV3_ROUTER, 0);
    }

    function readPool(address poolAddress)
        public
        view
        returns (
            uint256 sqrtPriceX96,
            uint256 liquidity,
            int24 tickSpacing
        )
    {
        IPool pool = IPool(poolAddress);
        IPool.Slot0 memory slot0 = pool.slot0();

        sqrtPriceX96 = slot0.sqrtPriceX96;
        liquidity = pool.liquidity();
        tickSpacing = pool.tickSpacing();
    }

    function exactOutputSingle(
        ISwapRouter.ExactOutputSingleParams calldata params
    )
        public
        returns (
            // payable
            uint256 amountIn
        )
    {
        IERC20(params.tokenIn).transferFrom(
            msg.sender,
            address(this),
            params.amountInMaximum
        );

        approveForRouter(params.tokenIn, params.amountInMaximum);
        amountIn = router.exactOutputSingle(params);

        if (amountIn < params.amountInMaximum) {
            IERC20(params.tokenIn).transfer(
                msg.sender,
                params.amountInMaximum - amountIn
            );
        }

        resetAllowance(params.tokenIn);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface IPool {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }

    function slot0() external view returns (Slot0 memory);

    function liquidity() external view returns (uint256);

    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISwapRouter {
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}