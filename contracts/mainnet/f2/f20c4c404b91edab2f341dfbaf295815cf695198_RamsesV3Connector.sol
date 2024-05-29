// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILiquidityConnector.sol";
import "../interfaces/IFarmConnector.sol";
import "../interfaces/external/ramses/IRamsesNonfungiblePositionManager.sol";
import "../interfaces/external/uniswap/ISwapRouter.sol";

struct NewPositionParams {
    int24 tickLower;
    int24 tickUpper;
    uint24 fee;
}

struct RamsesV3AddLiquidityExtraData {
    uint256 tokenId;
    bool isIncrease;
    NewPositionParams newPositionParams;
}

struct RamsesV3RemoveLiquidityExtraData {
    uint256 tokenId;
    uint128 liquidity;
    uint128 amount0Max;
    uint128 amount1Max;
}

struct RamsesV3SwapExtraData {
    address pool;
    bytes path;
}

struct RamsesV3ClaimExtraData {
    uint256 tokenId;
    address[] tokens;
    uint128 maxAmount0;
    uint128 maxAmount1;
}

contract RamsesV3Connector is ILiquidityConnector, IFarmConnector {
    constructor() { }

    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable
        override
    {
        RamsesV3AddLiquidityExtraData memory extra = abi.decode(
            addLiquidityData.extraData, (RamsesV3AddLiquidityExtraData)
        );

        if (extra.isIncrease) {
            IRamsesNonfungiblePositionManager.IncreaseLiquidityParams memory
                params = IRamsesNonfungiblePositionManager
                    .IncreaseLiquidityParams({
                    tokenId: extra.tokenId,
                    amount0Desired: addLiquidityData.desiredAmounts[0],
                    amount1Desired: addLiquidityData.desiredAmounts[1],
                    amount0Min: addLiquidityData.minAmounts[0],
                    amount1Min: addLiquidityData.minAmounts[1],
                    deadline: block.timestamp + 1
                });

            IRamsesNonfungiblePositionManager(addLiquidityData.router)
                .increaseLiquidity(params);
        } else {
            IRamsesNonfungiblePositionManager.MintParams memory params =
            IRamsesNonfungiblePositionManager.MintParams({
                token0: addLiquidityData.tokens[0],
                token1: addLiquidityData.tokens[1],
                fee: extra.newPositionParams.fee,
                tickLower: extra.newPositionParams.tickLower,
                tickUpper: extra.newPositionParams.tickUpper,
                amount0Desired: addLiquidityData.desiredAmounts[0],
                amount1Desired: addLiquidityData.desiredAmounts[1],
                amount0Min: addLiquidityData.minAmounts[0],
                amount1Min: addLiquidityData.minAmounts[1],
                recipient: address(this),
                deadline: block.timestamp + 1,
                veRamTokenId: 0
            });

            IRamsesNonfungiblePositionManager(addLiquidityData.router).mint(
                params
            );
        }
    }

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external
        override
    {
        RamsesV3RemoveLiquidityExtraData memory extra = abi.decode(
            removeLiquidityData.extraData, (RamsesV3RemoveLiquidityExtraData)
        );

        if (extra.liquidity == type(uint128).max) {
            (,,,,,,, uint128 liquidity,,,,) = IRamsesNonfungiblePositionManager(
                removeLiquidityData.router
            ).positions(extra.tokenId);
            extra.liquidity = liquidity;
        }

        IRamsesNonfungiblePositionManager.DecreaseLiquidityParams memory params =
        IRamsesNonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: extra.tokenId,
            liquidity: extra.liquidity,
            amount0Min: removeLiquidityData.minAmountsOut[0],
            amount1Min: removeLiquidityData.minAmountsOut[1],
            deadline: block.timestamp + 1
        });

        IRamsesNonfungiblePositionManager(removeLiquidityData.router)
            .decreaseLiquidity(params);

        IRamsesNonfungiblePositionManager(removeLiquidityData.router).collect(
            IRamsesNonfungiblePositionManager.CollectParams({
                tokenId: extra.tokenId,
                recipient: address(this),
                amount0Max: extra.amount0Max,
                amount1Max: extra.amount1Max
            })
        );

        (,,,,,,, uint128 liquidityAfter,,,,) = IRamsesNonfungiblePositionManager(
            removeLiquidityData.router
        ).positions(extra.tokenId);

        if (liquidityAfter == 0) {
            IRamsesNonfungiblePositionManager(removeLiquidityData.router).burn(
                extra.tokenId
            );
        }
    }

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable
        override
    {
        RamsesV3SwapExtraData memory extraData =
            abi.decode(swapData.extraData, (RamsesV3SwapExtraData));

        IERC20(swapData.tokenIn).approve(extraData.pool, swapData.amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
            path: extraData.path,
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: swapData.amountIn,
            amountOutMinimum: swapData.minAmountOut
        });

        ISwapRouter(swapData.router).exactInput(params);
    }

    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable override { }

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external override { }

    function claim(address target, bytes memory extraData) external override {
        RamsesV3ClaimExtraData memory data =
            abi.decode(extraData, (RamsesV3ClaimExtraData));
        IRamsesNonfungiblePositionManager(target).getReward(
            data.tokenId, data.tokens
        );
        if (data.maxAmount0 > 0 || data.maxAmount1 > 0) {
            IRamsesNonfungiblePositionManager.CollectParams memory params =
            IRamsesNonfungiblePositionManager.CollectParams({
                tokenId: data.tokenId,
                recipient: address(this),
                amount0Max: data.maxAmount0,
                amount1Max: data.maxAmount1
            });
            IRamsesNonfungiblePositionManager(target).collect(params);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AddLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256[] desiredAmounts;
    uint256[] minAmounts;
    bytes extraData;
}

struct RemoveLiquidityData {
    address router;
    address lpToken;
    address[] tokens;
    uint256 lpAmountIn;
    uint256[] minAmountsOut;
    bytes extraData;
}

struct SwapData {
    address router;
    uint256 amountIn;
    uint256 minAmountOut;
    address tokenIn;
    bytes extraData;
}

interface ILiquidityConnector {
    function addLiquidity(AddLiquidityData memory addLiquidityData)
        external
        payable;

    function removeLiquidity(RemoveLiquidityData memory removeLiquidityData)
        external;

    function swapExactTokensForTokens(SwapData memory swapData)
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmConnector {
    function deposit(
        address target,
        address token,
        bytes memory extraData
    ) external payable;

    function withdraw(
        address target,
        uint256 amount,
        bytes memory extraData
    ) external;

    function claim(address target, bytes memory extraData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Non-fungible token for positions
/// @notice Wraps Ramses V2 positions in a non-fungible token interface which
/// allows for them to be transferred
/// and authorized.
interface IRamsesNonfungiblePositionManager {
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was
    /// increased
    /// @param amount0 The amount of token0 that was paid for the increase in
    /// liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in
    /// liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was
    /// decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease
    /// in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease
    /// in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts
    /// transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were
    /// collected
    /// @param recipient The address of the account that received the collected
    /// tokens
    /// @param amount0 The amount of token0 owed to the position that was
    /// collected
    /// @param amount1 The amount of token1 owed to the position that was
    /// collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when the attachment of an NFP is switched to a different
    /// veRam NFT.
    /// @param tokenId The identifier of the NFP for which the attachment is
    /// switched.
    /// @param oldVeRamTokenId The identifier of the previous veRam NFT to which
    /// the NFP was attached.
    /// @param newVeRamTokenId The identifier of the new veRam NFT to which the
    /// NFP was attached.
    event SwitchAttachment(
        uint256 indexed tokenId,
        uint256 oldVeRamTokenId,
        uint256 newVeRamTokenId
    );

    /// @notice The address of the veRam NFTs
    function veRam() external view returns (address);

    /// @notice Returns the position information associated with a given token
    /// ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last
    /// action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last
    /// action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the
    /// position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the
    /// position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
        uint256 veRamTokenId;
    }

    // details about the Ramses position
    struct Position {
        // the nonce for permits
        uint96 nonce;
        // the address that is approved for spending this token
        address operator;
        // the ID of the pool with which this token is connected
        uint80 poolId;
        // the tick range of the position
        int24 tickLower;
        int24 tickUpper;
        // the liquidity of the position
        uint128 liquidity;
        // the fee growth of the aggregate position as of the last action on the
        // individual position
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // how many uncollected tokens are owed to the position, as of the last
        // computation
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        // the veRam tokenId attached
        uint256 veRamTokenId;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if
    /// the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as
    /// `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens
    /// paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being
    /// increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a
    /// slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a
    /// slippage check,
    /// deadline The time by which the transaction must be included to effect
    /// the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it
    /// to the position
    /// @param params tokenId The ID of the token for which liquidity is being
    /// decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the
    /// burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the
    /// burned liquidity,
    /// deadline The time by which the transaction must be included to effect
    /// the change
    /// @return amount0 The amount of token0 accounted to the position's tokens
    /// owed
    /// @return amount1 The amount of token1 accounted to the position's tokens
    /// owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Switches the attachment of a token to a different veRam NFT.
    /// @param tokenId The identifier of the NFP to switch attachment.
    /// @param veRamTokenId The identifier of the veRam NFT to attach.
    function switchAttachment(uint256 tokenId, uint256 veRamTokenId) external;

    /// @notice Collects up to a maximum amount of fees owed to a specific
    /// position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being
    /// collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The
    /// token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    function getReward(uint256 tokenId, address[] memory tokens) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another
    /// token
    /// @param params The parameters necessary for the swap, encoded as
    /// `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another
    /// along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded
    /// as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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

    /// @notice Swaps as little as possible of one token for `amountOut` of
    /// another token
    /// @param params The parameters necessary for the swap, encoded as
    /// `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of
    /// another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded
    /// as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}